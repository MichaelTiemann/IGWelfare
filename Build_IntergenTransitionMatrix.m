function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions, Params_Mig)
%% CANONICAL 4-REGION + ABROAD INTERGENERATIONAL TRANSITION MATRIX (100% GPU-VECTORIZED)
% File: Build_IntergenTransitionMatrix.m
% Supports both 4D Compact [a, h, z, j] and 5D Experience-Asset [a, h, theta_c, z, j] workspaces.

if nargin < 13 || isempty(Params_Mig)
    Params_Mig.w_Abroad         = 1.32;  % Australia/OECD benchmark skill wage
    Params_Mig.Q_Abroad         = 2.15;  % Australia/OECD house price benchmark
    Params_Mig.kappa_emig       = 0.14;  % Fixed international moving cost
    Params_Mig.tau_home_amenity = 0.85;  % Whanau / native home-attachment amenity
    Params_Mig.varrho_gumbel    = 0.85;  % Gumbel taste shock scale parameter
    Params_Mig.Target_NetMig    = 0.025; % Stats NZ +25k/yr net migration target
    Params_Mig.nu_retention     = 0.40;  % Social cohesion elasticity wrt native retention
    Params_Mig.nu_churn         = 0.35;  % Social cohesion penalty wrt migration churn
    Params_Mig.gamma_proximity  = 0.45;  % Parental utility weight on children staying in NZ
    Params_Mig.gamma_thrive     = 0.35;  % Parental utility weight on children thriving
end

N_reg    = length(Regions);
ref_type = ['HH_', Regions{1}];
n_a_vec  = n_a.(ref_type);
is_5D    = (numel(n_a_vec) == 3);
n_a1     = n_a_vec(1);
n_h      = n_a_vec(2);
if is_5D
    n_th   = n_a_vec(3);
    th_vec = double(gather(a_grid.(ref_type)(n_a1+n_h+1 : end)));
else
    n_th   = 1;
end
n_z1     = prod(n_z.(ref_type));

a_vec  = double(gather(a_grid.(ref_type)(1 : n_a1)));
h_vec  = double(gather(a_grid.(ref_type)(n_a1+1 : n_a1+n_h)));

ic_vec     = double(gather(d_grid.(ref_type)(n_d.(ref_type)(1)+n_d.(ref_type)(2)+1 : end)));
ic_pol_row = 3;

if ~isfield(Params, 'G_ece') && isfield(Params, 'G_ece_stage1')
    Params.G_ece = Params.G_ece_stage1;
end
if ~isfield(Params, 'rho_hc_ig'),   Params.rho_hc_ig   = 0.40; end
if ~isfield(Params, 'gamma_ic'),    Params.gamma_ic    = 0.35; end
if ~isfield(Params, 'sigma_hc_ig'), Params.sigma_hc_ig = 0.24; end

% Extract Regional Extended Family / Whanau Network Intensity K_whanau(k) in [0, 1]
% and Stage-2 Tuakana-Teina / Montessori Mentoring Intensity M_mentor in [0, 1]:
K_base_vec = [0.65, 0.50, 0.30, 0.20]; % Calibrated baseline [Rural, Small, Large, Auckland]
K_reg_vec  = K_base_vec;
if isfield(Params, 'K_whanau')
    if isstruct(Params.K_whanau)
        for r_i = 1:N_reg
            f_name = ['HH_', Regions{r_i}];
            if isfield(Params.K_whanau, f_name)
                K_reg_vec(r_i) = Params.K_whanau.(f_name);
            end
        end
    elseif isnumeric(Params.K_whanau) && isscalar(Params.K_whanau)
        K_reg_vec(:) = Params.K_whanau;
    elseif isnumeric(Params.K_whanau) && numel(Params.K_whanau) == N_reg
        K_reg_vec = reshape(double(Params.K_whanau), 1, N_reg);
    end
end
G_ece2_val = 0.065;
if isfield(Params, 'G_ece_stage2')
    G_ece2_val = Params.G_ece_stage2;
elseif isfield(Params, 'G_ece')
    G_ece2_val = Params.G_ece;
end
M_mentor = min(1.0, max(0.0, (G_ece2_val - 0.045) / (0.085 - 0.045)));

use_gpu = (gpuDeviceCount > 0);
if use_gpu
    a_G       = gpuArray(reshape(a_vec, [n_a1, 1, 1, 1]));
    h_G       = gpuArray(reshape(h_vec, [1, n_h, 1, 1]));
    ic_G      = gpuArray(ic_vec(:));
    log_h_dst = gpuArray(reshape(log(h_vec), [1, 1, 1, 1, n_h]));
else
    a_G       = reshape(a_vec, [n_a1, 1, 1, 1]);
    h_G       = reshape(h_vec, [1, n_h, 1, 1]);
    ic_G      = ic_vec(:);
    log_h_dst = reshape(log(h_vec), [1, 1, 1, 1, n_h]);
end

if isfield(Params, 'j_s1_start') && isfield(Params, 'j_s2_end')
    fertile_j = Params.j_s1_start : Params.j_s2_end;
else
    fertile_j = [3, 4];
end
retire_j = Params.Jr : Params.J;
mort_vec = reshape(1 - double(gather(Params.sj(retire_j))), [1, 1, 1, length(retire_j)]);
if use_gpu, mort_vec = gpuArray(mort_vec); end

NewbornDist_PreMig = struct();
reg_skill_drift = [-0.083, -0.059, -0.024, -0.020]; % Hits [19.8%, 18.2%, 15.6%, 14.3%]

%% STAGE 1 & 2 (100% GPU-VECTORIZED): SKILL FORMATION (Q_h) & PROPERTY BEQUESTS (Q_a)
for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    K_reg   = min(1.0, max(0.0, K_reg_vec(r_idx)));
    dK_reg  = K_reg - K_base_vec(r_idx);

    Dist_raw      = double(gather(StationaryDist.(hh_type)));
    Pol_raw       = double(gather(Policy.(hh_type)));
    Q_house       = Params.Q_reg.(hh_type);
    crowd_pen     = 0.08 * log(max(1.0, Q_house));
    % Stronger extended whanau / papakainga networks cushion severe housing crowding:
    crowd_pen_eff = crowd_pen * max(0.50, 1.0 - 0.30 * dK_reg);

    if is_5D && ndims(Dist_raw) == 5
        Dist_5D   = reshape(Dist_raw, [n_a1, n_h, n_th, n_z1, Params.J]);
        Pol_5D    = reshape(Pol_raw,  [size(Pol_raw, 1), n_a1, n_h, n_th, n_z1, Params.J]);
        j_s1_done = min(Params.J, Params.j_s2_start);
        j_launch  = min(Params.J, Params.j_child_launch);

        D_th2 = squeeze(sum(Dist_5D(:, :, :, :, j_s1_done), [1, 2, 4]));
        D_th2 = D_th2(:) / max(1e-12, sum(D_th2(:)));
        Diag.MeanTheta2.(reg) = sum(D_th2 .* th_vec(:));

        % Extract parent-child joint distribution over (a, theta_c) at child launch j_launch
        Mass_a_th   = reshape(sum(Dist_5D(:, :, :, :, j_launch), [2, 4]), [n_a1, n_th]);
        parent_mass = max(1e-12, sum(Mass_a_th, 'all'));
        Diag.MeanTheta3.(reg) = sum(sum(Mass_a_th, 1)' .* th_vec(:)) / parent_mass;

        % No double-counting of ece_lift or K_whanau in 5D mode (theta_c already evolved via aprimeFn!)
        is_hard_1D = double(a_vec < 0.08 * Q_house); % [n_a1 x 1]
        log_h_mean = 0.68 * log(reshape(th_vec, [1, n_th])) + reg_skill_drift(r_idx) - crowd_pen_eff .* is_hard_1D;

        diff_log = reshape(log(h_vec), [n_h, 1, 1]) - reshape(log_h_mean, [1, n_a1, n_th]);
        trans_p  = exp(-0.5 * (diff_log ./ 0.24).^2);
        trans_p  = trans_p ./ max(1e-12, sum(trans_p, 1));

        Prob_h_child = squeeze(sum(trans_p .* reshape(Mass_a_th, [1, n_a1, n_th]), [2, 3])) / parent_mass;
        Prob_h_child = Prob_h_child(:) / sum(Prob_h_child(:));

        Dist_4D = reshape(sum(Dist_5D, 3), [n_a1, n_h, n_z1, Params.J]);
        mid_th  = ceil(n_th / 2);
        Pol_4D  = reshape(Pol_5D(:, :, :, mid_th, :, :), [size(Pol_5D, 1), n_a1, n_h, n_z1, Params.J]);
        if use_gpu
            Dist_k = gpuArray(Dist_4D); Pol_k = gpuArray(Pol_4D);
        else
            Dist_k = Dist_4D; Pol_k = Pol_4D;
        end
    else
        Dist_4D = reshape(Dist_raw, [n_a1, n_h, n_z1, Params.J]);
        Pol_4D  = reshape(Pol_raw,  [size(Pol_raw, 1), n_a1, n_h, n_z1, Params.J]);
        if use_gpu
            Dist_k = gpuArray(Dist_4D); Pol_k = gpuArray(Pol_4D);
        else
            Dist_k = Dist_4D; Pol_k = Pol_4D;
        end

        Dist_Fert   = Dist_k(:, :, :, fertile_j);
        parent_mass = max(1e-12, sum(Dist_Fert, 'all'));

        d_ic_idx = max(1, min(length(ic_vec), round(Pol_k(ic_pol_row, :, :, :, fertile_j))));
        ic_4D    = reshape(ic_G(d_ic_idx(:)), size(Dist_Fert));

        % 4D Compact Skill Transition: includes extended whanau (K_reg) & mentoring (M_mentor)
        is_hard_4D   = (a_G < 0.08 * Q_house);
        is_stress_4D = double(ic_4D < 0.01);
        stress_pen   = 0.045 * is_stress_4D * (1.0 - 0.80 * M_mentor) * (1.0 - 0.55 * K_reg);
        ece_lift     = 0.85 * (Params.G_ece - 0.045) + 0.06 * (M_mentor - 0.50) + 0.12 * dK_reg;
        hp_eff_4D    = h_G .* (1.0 + 0.15 * dK_reg);

        log_h_mean = Params.rho_hc_ig .* log(hp_eff_4D) ...
            + Params.gamma_ic .* log(1 + 1.2 * (ic_4D + Params.G_ece + 0.020 * dK_reg)) ...
            + ece_lift - stress_pen + reg_skill_drift(r_idx) - crowd_pen_eff .* is_hard_4D;

        pdf_5D = exp(-0.5 .* ((log_h_dst - log_h_mean) ./ 0.24).^2);
        pdf_5D = pdf_5D ./ sum(pdf_5D, 5);

        Prob_h_child = squeeze(gather(sum(Dist_Fert .* pdf_5D, [1, 2, 3, 4]))) / gather(parent_mass);
        Prob_h_child = Prob_h_child(:) / sum(Prob_h_child(:));

        Diag.MeanTheta3.(reg) = sum(Prob_h_child(:) .* h_vec(:));
        Diag.MeanTheta2.(reg) = 0.92 * Diag.MeanTheta3.(reg);
    end

    % --- B. VECTORIZED $1.6T PROPERTY BEQUEST TRANSITION (Dying Retirees j >= Jr) ---
    Dist_Ret   = Dist_k(:, :, :, retire_j) .* mort_vec;                % [n_a1, n_h, n_z1, n_ret]
    beq_mass   = max(1e-12, gather(sum(Dist_Ret, 'all')));
    ap_idx_4D  = max(1, min(n_a1, round(Pol_k(4, :, :, :, retire_j))));
    ap_val_4D  = reshape(a_G(ap_idx_4D(:)), size(Dist_Ret));

    a_exempt   = 1.80; % Homestead/working-farm exemption threshold before progressive estate tax tau_b
    estate_4D  = ap_val_4D - Params.tau_b .* max(0, ap_val_4D - a_exempt) + Params.YouthGrant;
    total_beq_val = gather(sum(Dist_Ret .* estate_4D, 'all'));

    possible_estates = a_vec(:) - Params.tau_b * max(0, a_vec(:) - a_exempt) + Params.YouthGrant;
    [~, map_ap_to_achild] = min(abs(possible_estates - a_vec(:)'), [], 2);
    a_child_idx_flat = map_ap_to_achild(gather(ap_idx_4D(:)));

    Prob_a_child = accumarray(a_child_idx_flat, gather(Dist_Ret(:)), [n_a1, 1]);
    Prob_a_child = Prob_a_child / beq_mass;

    stat_z = (double(gather(pi_z.(hh_type)))^50)';
    stat_z = stat_z(:, 1);

    NewbornDist_PreMig.(reg) = reshape(Prob_a_child, [n_a1, 1, 1]) ...
        .* reshape(Prob_h_child, [1, n_h, 1]) ...
        .* reshape(stat_z,       [1, 1, n_z1]);

    Diag.StuntedShare.(reg)  = sum(Prob_h_child(1:2));
    Diag.ThrivingShare.(reg) = sum(Prob_h_child(max(1, end-1):end));
    Diag.MeanBequest.(reg)   = total_beq_val / beq_mass;
    Diag.K_whanau.(reg)      = K_reg;
end

%% STAGE 3 (100% VECTORIZED): CALIBRATED 4x5 DOMESTIC + ABROAD GUMBEL MIGRATION OPERATOR
% Stack j=1 value functions V_j1_all: [n_a1, n_h, n_z1, N_reg]
V_j1_all  = zeros(n_a1, n_h, n_z1, N_reg);
V_mean_j1 = zeros(N_reg, 1);
for r_d = 1:N_reg
    V_raw = double(gather(V.(['HH_', Regions{r_d}])));
    if is_5D && ndims(V_raw) == 5
        mid_th = ceil(n_th / 2);
        V_slice = reshape(V_raw(:, :, mid_th, :, 1), [n_a1, n_h, n_z1]);
    else
        V_raw_4D = reshape(V_raw, [n_a1, n_h, n_z1, Params.J]);
        V_slice  = V_raw_4D(:, :, :, 1);
    end
    V_j1_all(:, :, :, r_d) = V_slice;
    fin_mask = isfinite(V_slice);
    V_mean_j1(r_d) = sum(V_slice(fin_mask) .* NewbornDist_PreMig.(Regions{r_d})(fin_mask)) ...
        / max(1e-12, sum(NewbornDist_PreMig.(Regions{r_d})(fin_mask)));
end

% Normalize regional j=1 value differences to unit dispersion so Gumbel probabilities
% are invariant to dt (dt=5 vs dt=3) and calibrated to empirical Stats NZ 4x5 sorting
V_scale = max(0.50, std(V_mean_j1));
V_norm  = (V_mean_j1 - mean(V_mean_j1)) / V_scale;

% Ensure immutable SS0 baseline K_whanau_base and active K_whanau exist in Params
if ~isfield(Params, 'K_whanau_base')
    Params.K_whanau_base = struct('HH_Rural', 0.42, 'HH_Small', 0.38, 'HH_Large', 0.32, 'HH_Auckland', 0.28);
end
if ~isfield(Params, 'K_whanau')
    Params.K_whanau = Params.K_whanau_base;
end

% Bilateral migration cost matrix kappa_4x5 [Origin x (Rural, Small, Large, Auckland, Abroad)]
% Reproduces empirical baseline: Rural Emig ~1.8%, Small ~9.1%, Large ~23.4%, Auckland ~7.0%
% and responds endogenously as domestic wages w_k, housing Q_k, YouthGrant, and K_whanau improve!
w_akl_ratio = Params.w_reg.HH_Auckland / 1.180;
Q_akl_ratio = Params.Q_reg.HH_Auckland / 3.100;
reform_pull = 3.20 * (w_akl_ratio - 1.0) - 2.40 * (Q_akl_ratio - 1.0) ...
    + 2.50 * (Params.YouthGrant - 0.030);

u_target_4x5 = [ ...
    2.85,  1.15,  0.65,  0.15, -0.82;   % From Rural    (1.8% Emig)
    0.55,  2.45,  1.05,  0.45,  0.65;   % From Small    (9.1% Emig)
    -0.25,  0.45,  2.15,  1.05,  1.45;   % From Large    (23.4% Emig)
    -0.45,  0.15,  0.65,  2.55,  0.16];  % From Auckland (7.0% Net / 19.3% Gross Emig)

Pi_mig_4x5     = zeros(N_reg, N_reg + 1);
skill_emig_w   = linspace(0.45, 1.65, n_h)'; % Positive selection on skill h_1
Emig_By_Skill_Num = zeros(n_h, 1);
Emig_By_Skill_Den = zeros(n_h, 1);
pop_weights       = double(gather(Params.PTypeWeights(1:N_reg)));
pop_weights       = pop_weights(:) / sum(pop_weights);

for r_orig = 1:N_reg
    orig_hh = ['HH_', Regions{r_orig}];

    % Whanau stay-pull: measures change in extended whanau anchoring relative to SS0 baseline.
    % - Equal to 0.00 in SS0 (preserving exact Stats NZ baseline migration matrix).
    % - Positive in SS1/SS2 as cooler housing & pension security strengthen whanau roots.
    % - Negative when NZ Super age is raised to 67/70 (K_whanau drops -36.2%), accelerating
    %   both domestic drift from Rural/Small and trans-Tasman emigration to Australia!
    dK_whanau        = Params.K_whanau.(orig_hh) - Params.K_whanau_base.(orig_hh);
    whanau_stay_pull = Params_Mig.tau_home_amenity * 1.80 * dK_whanau;

    u_row          = u_target_4x5(r_orig, :);
    u_row(1:N_reg) = u_row(1:N_reg) + 0.18 * (V_norm' - V_norm(r_orig));
    u_row(r_orig)  = u_row(r_orig)  + 0.65 * whanau_stay_pull;           % Anchors youth in home region
    u_row(N_reg+1) = u_row(N_reg+1) - reform_pull - whanau_stay_pull;    % Brain drain closes when pull > 0

    exp_u = exp(u_row - max(u_row));
    Pi_mig_4x5(r_orig, :) = exp_u / sum(exp_u);

    Dist_orig = NewbornDist_PreMig.(Regions{r_orig}); % [n_a1, n_h, n_z1]
    h_marg    = reshape(sum(Dist_orig, [1, 3]), [n_h, 1]);
    emig_h    = h_marg .* Pi_mig_4x5(r_orig, N_reg+1) .* skill_emig_w;
    emig_h    = emig_h * (Pi_mig_4x5(r_orig, N_reg+1) / max(1e-12, sum(emig_h)));

    Emig_By_Skill_Num = Emig_By_Skill_Num + pop_weights(r_orig) * emig_h;
    Emig_By_Skill_Den = Emig_By_Skill_Den + pop_weights(r_orig) * h_marg;
end

Pi_dom = Pi_mig_4x5(:, 1:N_reg) ./ max(1e-12, sum(Pi_mig_4x5(:, 1:N_reg), 2));

jequaloneDist_new = struct();
for r_dest = 1:N_reg
    dest_reg  = Regions{r_dest};
    dest_type = ['HH_', dest_reg];
    dist_3d   = zeros(n_a1, n_h, n_z1);
    for r_orig = 1:N_reg
        dist_3d = dist_3d + Pi_dom(r_orig, r_dest) * NewbornDist_PreMig.(Regions{r_orig});
    end
    dist_3d = dist_3d / max(1e-12, sum(dist_3d(:)));

    if is_5D
        dist_4d = zeros(n_a1, n_h, n_th, n_z1);
        for ih = 1:n_h
            ith_init = min(n_th, max(1, ih + 1));
            dist_4d(:, ih, ith_init, :) = reshape(dist_3d(:, ih, :), [n_a1, 1, 1, n_z1]);
        end
        jequaloneDist_new.(dest_type) = dist_4d / max(1e-12, sum(dist_4d(:)));
    else
        jequaloneDist_new.(dest_type) = dist_3d;
    end
end

%% STORE DIAGNOSTICS
Diag.MigrationMatrix_3x4   = Pi_mig_4x5;
Diag.MigrationMatrix_4x5   = Pi_mig_4x5;
Diag.MigrationMatrix       = Pi_dom;
Diag.Emig_By_Region        = Pi_mig_4x5(:, N_reg + 1)';
for r_i = 1:N_reg
    reg = Regions{r_i};
    Diag.EmigRate.(reg)    = Pi_mig_4x5(r_i, N_reg + 1);
end
Diag.Emig_By_SkillTier     = Emig_By_Skill_Num ./ max(1e-12, Emig_By_Skill_Den);
Diag.EmigRate_Youth        = sum(Emig_By_Skill_Num) / max(1e-12, sum(Emig_By_Skill_Den));
Diag.HighSkill_EmigShare   = sum(Emig_By_Skill_Num(max(1, end-2):end)) / max(1e-12, sum(Emig_By_Skill_Num));

Diag.ReplacementImmig_Rate = Params_Mig.Target_NetMig + 0.35 * Diag.EmigRate_Youth;
Diag.Churn_Rate            = 0.35 * Diag.EmigRate_Youth + Diag.ReplacementImmig_Rate;
raw_S = ((1 - Diag.EmigRate_Youth)^Params_Mig.nu_retention) ...
    * ((1 + Diag.Churn_Rate)^(-Params_Mig.nu_churn));
Diag.SocialCohesion_Index  = 100.0 * (raw_S / 0.885);

nat_stunted = 0;
for r_i = 1:N_reg
    nat_stunted = nat_stunted + pop_weights(r_i) * Diag.StuntedShare.(Regions{r_i});
end
rel_util = Params_Mig.gamma_thrive * log(max(0.01, 1 - nat_stunted)) ...
    + Params_Mig.gamma_proximity * log(max(0.01, 1 - Diag.EmigRate_Youth));
Diag.ParentalRelational_CE = 100 * (exp(rel_util + 0.22) - 1);


end
