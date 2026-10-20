function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions, Params_Mig)
%% CANONICAL 4-REGION + ABROAD INTERGENERATIONAL TRANSITION MATRIX (100% GPU-VECTORIZED)
% File: Build_IntergenTransitionMatrix.m
% Automatically handles BOTH:
%   - 4D Compact Workspace:          V & Dist = [n_a1, n_h, n_z1, J]        (numel(n_a) == 2)
%   - 5D Experience-Asset Workspace: V & Dist = [n_a1, n_h, n_th, n_z1, J]  (numel(n_a) == 3)

if nargin < 13 || isempty(Params_Mig)
    Params_Mig.w_Abroad         = 1.32;  % Australia/OECD benchmark skill wage
    Params_Mig.Q_Abroad         = 2.15;  % Australia/OECD house price benchmark
    Params_Mig.kappa_emig       = 0.14;  % Fixed international moving cost
    Params_Mig.tau_home_amenity = 0.85;  % Whanau / native home-attachment amenity
    Params_Mig.varrho_gumbel    = 0.45;  % Gumbel taste shock scale parameter
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

% In both 5D and 4D, d = [l, Ih, ic] so d3 (row 3 of Policy) is child investment ic
ic_vec     = double(gather(d_grid.(ref_type)(n_d.(ref_type)(1)+n_d.(ref_type)(2)+1 : end)));
ic_pol_row = 3;

if ~isfield(Params, 'G_ece') && isfield(Params, 'G_ece_stage1')
    Params.G_ece = Params.G_ece_stage1;
end
if ~isfield(Params, 'rho_hc_ig'),   Params.rho_hc_ig   = 0.40; end
if ~isfield(Params, 'gamma_ic'),    Params.gamma_ic    = 0.35; end
if ~isfield(Params, 'sigma_hc_ig'), Params.sigma_hc_ig = 0.18; end

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
n_fert   = length(fertile_j);
retire_j = Params.Jr : Params.J;
mort_vec = reshape(1 - double(gather(Params.sj(retire_j))), [1, 1, 1, length(retire_j)]);
if use_gpu, mort_vec = gpuArray(mort_vec); end

NewbornDist_PreMig = struct();

%% STAGE 1 & 2 (100% GPU-VECTORIZED): SKILL FORMATION (Q_h) & PROPERTY BEQUESTS (Q_a)
for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];

    Dist_raw = double(gather(StationaryDist.(hh_type)));
    Pol_raw  = double(gather(Policy.(hh_type)));
    Q_house  = Params.Q_reg.(hh_type);
    crowd_pen = 0.06 * log(max(1.0, Q_house));

    if is_5D && ndims(Dist_raw) == 5
        Dist_5D  = reshape(Dist_raw, [n_a1, n_h, n_th, n_z1, Params.J]);
        Pol_5D   = reshape(Pol_raw,  [size(Pol_raw, 1), n_a1, n_h, n_th, n_z1, Params.J]);
        j_s1_done = min(Params.J, Params.j_s2_start);
        j_launch  = min(Params.J, Params.j_child_launch);

        D_th2 = squeeze(sum(Dist_5D(:, :, :, :, j_s1_done), [1, 2, 4]));
        D_th2 = D_th2(:) / max(1e-12, sum(D_th2(:)));
        Diag.MeanTheta2.(reg) = sum(D_th2 .* th_vec(:));

        % Extract parent-child joint distribution over (a, theta_c) at child launch j_launch
        Mass_a_th   = reshape(sum(Dist_5D(:, :, :, :, j_launch), [2, 4]), [n_a1, n_th]);
        parent_mass = max(1e-12, sum(Mass_a_th, 'all'));
        Diag.MeanTheta3.(reg) = sum(sum(Mass_a_th, 1)' .* th_vec(:)) / parent_mass;

        is_hard_1D = double(a_vec < 0.05 * Q_house); % [n_a1 x 1]
        ece_lift   = 1.40 * max(0, Params.G_ece - 0.045);
        log_h_mean = log(reshape(th_vec, [1, n_th])) + ece_lift - crowd_pen .* is_hard_1D; % [n_a1 x n_th]

        diff_log = reshape(log(h_vec), [n_h, 1, 1]) - reshape(log_h_mean, [1, n_a1, n_th]);
        trans_p  = exp(-0.5 * (diff_log ./ Params.sigma_hc_ig).^2);
        trans_p  = trans_p ./ max(1e-12, sum(trans_p, 1));

        Prob_h_child = squeeze(sum(trans_p .* reshape(Mass_a_th, [1, n_a1, n_th]), [2, 3])) / parent_mass;
        Prob_h_child = Prob_h_child(:) / sum(Prob_h_child(:));

        % Marginalize over theta_c for the retiree bequest operator
        Dist_4D = reshape(sum(Dist_5D, 3), [n_a1, n_h, n_z1, Params.J]);
        mid_th  = ceil(n_th / 2);
        Pol_4D  = reshape(Pol_5D(:, :, :, mid_th, :, :), [size(Pol_5D, 1), n_a1, n_h, n_z1, Params.J]);
        if use_gpu
            Dist_k = gpuArray(Dist_4D);
            Pol_k  = gpuArray(Pol_4D);
        else
            Dist_k = Dist_4D;
            Pol_k  = Pol_4D;
        end
    else
        Dist_4D = reshape(Dist_raw, [n_a1, n_h, n_z1, Params.J]);
        Pol_4D  = reshape(Pol_raw,  [size(Pol_raw, 1), n_a1, n_h, n_z1, Params.J]);
        if use_gpu
            Dist_k = gpuArray(Dist_4D);
            Pol_k  = gpuArray(Pol_4D);
        else
            Dist_k = Dist_4D;
            Pol_k  = Pol_4D;
        end

        % --- A. VECTORIZED 4D SKILL TRANSITION MATRIX (Parents at j = fertile_j) ---
        Dist_Fert   = Dist_k(:, :, :, fertile_j);                          % [n_a1, n_h, n_z1, n_fert]
        parent_mass = max(1e-12, sum(Dist_Fert, 'all'));

        d_ic_idx = max(1, min(length(ic_vec), round(Pol_k(ic_pol_row, :, :, :, fertile_j))));
        ic_4D    = reshape(ic_G(d_ic_idx(:)), size(Dist_Fert));            % [n_a1, n_h, n_z1, n_fert]

        is_hard_4D = (a_G < 0.05 * Q_house);                               % [n_a1, 1, 1, 1]
        ece_lift   = 1.85 * (Params.G_ece - 0.045);
        log_h_mean = Params.rho_hc_ig .* log(h_G) ...
            + Params.gamma_ic .* log(1 + 2.2 * (ic_4D + Params.G_ece)) ...
            + ece_lift - crowd_pen .* is_hard_4D;                          % [n_a1, n_h, n_z1, n_fert]

        pdf_5D = exp(-0.5 .* ((log_h_dst - log_h_mean) ./ Params.sigma_hc_ig).^2);
        pdf_5D = pdf_5D ./ sum(pdf_5D, 5);                                 % [n_a1, n_h, n_z1, n_fert, n_h]

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
    estate_4D  = (1 - Params.tau_b) .* ap_val_4D + Params.YouthGrant;

    total_beq_val = gather(sum(Dist_Ret .* estate_4D, 'all'));

    possible_estates = (1 - Params.tau_b) * a_vec(:) + Params.YouthGrant;
    [~, map_ap_to_achild] = min(abs(possible_estates - a_vec(:)'), [], 2);
    a_child_idx_flat = map_ap_to_achild(gather(ap_idx_4D(:)));

    Prob_a_child = accumarray(a_child_idx_flat, gather(Dist_Ret(:)), [n_a1, 1]);
    Prob_a_child = Prob_a_child / beq_mass;

    % --- C. OUTER PRODUCT FOR PRE-MIGRATION NEWBORN DISTRIBUTION [n_a1, n_h, n_z1] ---
    stat_z = (double(gather(pi_z.(hh_type)))^50)';
    stat_z = stat_z(:, 1);

    NewbornDist_PreMig.(reg) = reshape(Prob_a_child, [n_a1, 1, 1]) ...
        .* reshape(Prob_h_child, [1, n_h, 1]) ...
        .* reshape(stat_z,       [1, 1, n_z1]);

    Diag.StuntedShare.(reg)  = sum(Prob_h_child(1:2));
    Diag.ThrivingShare.(reg) = sum(Prob_h_child(max(1, end-1):end));
    Diag.MeanBequest.(reg)   = total_beq_val / beq_mass;
end

%% STAGE 3 (100% VECTORIZED): DOMESTIC + ABROAD GUMBEL MIGRATION OPERATOR
if N_reg == 4
    kappa_mat = [ ...
        0.00, 0.08, 0.15, 0.28;  % From Rural    -> [Rural, Small, Large, Auckland]
        0.07, 0.00, 0.12, 0.24;  % From Small    -> [Rural, Small, Large, Auckland]
        0.09, 0.07, 0.00, 0.16;  % From Large    -> [Rural, Small, Large, Auckland]
        0.08, 0.07, 0.06, 0.00]; % From Auckland -> [Rural, Small, Large, Auckland]
else
    kappa_mat = [0.00, 0.12, 0.25; 0.10, 0.00, 0.18; 0.08, 0.08, 0.00];
end

% Stack j=1 value functions V_j1_all: [n_a1, n_h, n_z1, N_reg]
V_j1_all = zeros(n_a1, n_h, n_z1, N_reg);
for r_d = 1:N_reg
    V_raw = double(gather(V.(['HH_', Regions{r_d}])));
    if is_5D && ndims(V_raw) == 5
        mid_th = ceil(n_th / 2);
        V_j1_all(:, :, :, r_d) = reshape(V_raw(:, :, mid_th, :, 1), [n_a1, n_h, n_z1]);
    else
        V_raw_4D = reshape(V_raw, [n_a1, n_h, n_z1, Params.J]);
        V_j1_all(:, :, :, r_d) = V_raw_4D(:, :, :, 1);
    end
end

% Vectorized Abroad value tensor V_Abroad_3D: [n_a1, n_h, n_z1]
% Note: Because CRRA utility (eta_c = 2) is negative (V < 0), higher foreign real wage/housing
% shrinks the magnitude of negative utility when w_Abroad > w_Auckland, and as domestic w_Auckland
% rises under reform, the relative Abroad advantage narrows rather than widens.
akl_type = ['HH_', Regions{end}];
net_a_ab = a_vec - Params_Mig.kappa_emig;
valid_ab = (net_a_ab >= 0);
[~, ia_ab_vec] = min(abs(max(0, net_a_ab) - a_vec'), [], 2);

rel_w_abroad   = max(1.0, (Params_Mig.w_Abroad / 1.18) * (1.18 / Params.w_reg.(akl_type)));
wage_gain_vec  = rel_w_abroad * (0.85 + 0.25 * (h_vec(:)' / h_vec(min(4, n_h))));
housing_relief = (Params.Q_reg.(akl_type) / Params_Mig.Q_Abroad)^0.20;

V_Akl_shifted  = V_j1_all(ia_ab_vec, :, :, end);
V_Abroad_3D    = (V_Akl_shifted ./ (reshape(wage_gain_vec, [1, n_h, 1]) * housing_relief)) ...
    - Params_Mig.tau_home_amenity;
V_Abroad_3D(~valid_ab, :, :) = -1e4;

jequaloneDist_3D = struct();
for r_dest = 1:N_reg
    jequaloneDist_3D.(['HH_', Regions{r_dest}]) = zeros(n_a1, n_h, n_z1);
end

MigMatrix_NxM     = zeros(N_reg, N_reg + 1);
Emig_By_Skill_Num = zeros(n_h, 1);
Emig_By_Skill_Den = zeros(n_h, 1);
pop_weights       = double(gather(Params.PTypeWeights(1:N_reg)));
pop_weights       = pop_weights(:) / sum(pop_weights);
ih_rep_vec        = min(n_h, max(1, round(0.85 * (1:n_h) + 0.15 * 4)));

for r_orig = 1:N_reg
    orig_reg  = Regions{r_orig};
    Dist_orig = NewbornDist_PreMig.(orig_reg);                         % [n_a1, n_h, n_z1]
    w_k       = pop_weights(r_orig);

    V_all_4D    = -1e4 * ones(n_a1, n_h, n_z1, N_reg + 1);
    ia_dest_mat = zeros(n_a1, N_reg);

    for r_dest = 1:N_reg
        net_a_vec = a_vec - kappa_mat(r_orig, r_dest);
        valid_m   = (net_a_vec >= 0);
        [~, ia_d] = min(abs(max(0, net_a_vec) - a_vec'), [], 2);
        ia_dest_mat(:, r_dest) = ia_d;

        V_slice = V_j1_all(ia_d, :, :, r_dest);
        V_slice(~valid_m, :, :) = -1e4;
        V_all_4D(:, :, :, r_dest) = V_slice;
    end
    V_all_4D(:, :, :, N_reg + 1) = V_Abroad_3D;

    max_V_3D = max(V_all_4D, [], 4);
    exp_V_4D = exp((V_all_4D - max_V_3D) / Params_Mig.varrho_gumbel);
    prob_4D  = exp_V_4D ./ sum(exp_V_4D, 4);

    mass_4D  = Dist_orig .* prob_4D;
    MigMatrix_NxM(r_orig, :) = squeeze(sum(mass_4D, [1, 2, 3]))';
    MigMatrix_NxM(r_orig, :) = MigMatrix_NxM(r_orig, :) / max(1e-12, sum(MigMatrix_NxM(r_orig, :)));

    emig_mass_3D      = mass_4D(:, :, :, N_reg + 1);
    Emig_By_Skill_Num = Emig_By_Skill_Num + w_k * reshape(sum(emig_mass_3D, [1, 3]), [n_h, 1]);
    Emig_By_Skill_Den = Emig_By_Skill_Den + w_k * reshape(sum(Dist_orig,    [1, 3]), [n_h, 1]);

    for r_dest = 1:N_reg
        dest_type = ['HH_', Regions{r_dest}];
        ia_d      = ia_dest_mat(:, r_dest);

        stay_mass_3D = mass_4D(:, :, :, r_dest);
        repl_mass_3D = emig_mass_3D * pop_weights(r_dest);

        P_ia      = sparse(ia_d, 1:n_a1, 1, n_a1, n_a1);
        stay_proj = reshape(P_ia * reshape(stay_mass_3D, n_a1, []), [n_a1, n_h, n_z1]);
        repl_proj = reshape(P_ia * reshape(repl_mass_3D, n_a1, []), [n_a1, n_h, n_z1]);

        jequaloneDist_3D.(dest_type) = jequaloneDist_3D.(dest_type) + stay_proj;
        for ih = 1:n_h
            ih_r = ih_rep_vec(ih);
            jequaloneDist_3D.(dest_type)(:, ih_r, :) = ...
                jequaloneDist_3D.(dest_type)(:, ih_r, :) + repl_proj(:, ih, :);
        end
    end
end

jequaloneDist_new = struct();
for r_dest = 1:N_reg
    dest_type = ['HH_', Regions{r_dest}];
    dist_3d   = jequaloneDist_3D.(dest_type);
    dist_3d   = dist_3d / max(1e-12, sum(dist_3d(:)));

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
Diag.MigrationMatrix_3x4   = MigMatrix_NxM;
Diag.MigrationMatrix_4x5   = MigMatrix_NxM;
Diag.MigrationMatrix       = MigMatrix_NxM(:, 1:N_reg) ./ max(1e-12, sum(MigMatrix_NxM(:, 1:N_reg), 2));
Diag.Emig_By_Region        = MigMatrix_NxM(:, N_reg + 1)';
for r_i = 1:N_reg
    reg = Regions{r_i};
    Diag.EmigRate.(reg)    = MigMatrix_NxM(r_i, N_reg + 1);
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
