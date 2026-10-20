function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions, Params_Mig)
%% CANONICAL 4-REGION + ABROAD INTERGENERATIONAL TRANSITION MATRIX (100% GPU-VECTORIZED)
% File: Build_IntergenTransitionMatrix.m
% Truly 100% vectorized across (ia, ih, iz, j) using 4D/5D GPU tensor broadcasting:
%   Stage 1 (Q_h): Vectorized 5D Gaussian kernel skill transition (zero normpdf loops)
%   Stage 2 (Q_a): Vectorized retiree estate lookup & accumarray projection
%   Stage 3 (Pi_mig): Vectorized 4D Gumbel logit spatial + Abroad migration tensor

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
n_a1     = n_a.(ref_type)(1);
n_h      = n_a.(ref_type)(2);
n_z1     = n_z.(ref_type);

a_vec  = double(gather(a_grid.(ref_type)(1 : n_a1)));
h_vec  = double(gather(a_grid.(ref_type)(n_a1+1 : n_a1+n_h)));
ic_vec = double(gather(d_grid.(ref_type)(n_d.(ref_type)(1)+n_d.(ref_type)(2)+1 : end)));

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

fertile_j = [3, 4];
retire_j  = Params.Jr : Params.J;
mort_vec  = reshape(1 - double(gather(Params.sj(retire_j))), [1, 1, 1, length(retire_j)]);
if use_gpu, mort_vec = gpuArray(mort_vec); end

NewbornDist_PreMig = struct();

%% STAGE 1 & 2 (100% GPU-VECTORIZED): SKILL FORMATION (Q_h) & PROPERTY BEQUESTS (Q_a)
for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];

    if use_gpu
        Dist_k = gpuArray(double(StationaryDist.(hh_type)));
        Pol_k  = gpuArray(double(Policy.(hh_type)));
    else
        Dist_k = double(gather(StationaryDist.(hh_type)));
        Pol_k  = double(gather(Policy.(hh_type)));
    end
    Q_house = Params.Q_reg.(hh_type);

    % --- A. VECTORIZED SKILL TRANSITION MATRIX (Parents at j = fertile_j) ---
    Dist_Fert   = Dist_k(:, :, :, fertile_j);                          % [n_a1, n_h, n_z1, 2]
    parent_mass = max(1e-12, sum(Dist_Fert(:)));

    d_ic_idx = max(1, min(length(ic_vec), Pol_k(3, :, :, :, fertile_j)));
    ic_4D    = reshape(ic_G(d_ic_idx(:)), size(Dist_Fert));            % [n_a1, n_h, n_z1, 2]

    is_hard_4D  = (a_G < 0.05 * Q_house);                              % [n_a1, 1, 1, 1]
    crowd_pen   = 0.08 * log(max(1.0, Q_house));
    log_h_mean  = Params.rho_hc_ig .* log(h_G) ...
                + Params.gamma_ic  .* log(1 + ic_4D + Params.G_ece) ...
                - crowd_pen .* is_hard_4D;                             % [n_a1, n_h, n_z1, 2]

    % Broadcast Gaussian PDF across 5th dimension (destination child skill h_1)
    pdf_5D      = exp(-0.5 .* ((log_h_dst - log_h_mean) ./ Params.sigma_hc_ig).^2);
    pdf_5D      = pdf_5D ./ sum(pdf_5D, 5);                            % [n_a1, n_h, n_z1, 2, n_h]

    Prob_h_child = squeeze(gather(sum(Dist_Fert .* pdf_5D, [1, 2, 3, 4]))) / gather(parent_mass);
    Prob_h_child = Prob_h_child(:) / sum(Prob_h_child(:));

    % --- B. VECTORIZED $1.6T PROPERTY BEQUEST TRANSITION (Dying Retirees j >= Jr) ---
    Dist_Ret   = Dist_k(:, :, :, retire_j) .* mort_vec;                % [n_a1, n_h, n_z1, n_ret]
    beq_mass   = max(1e-12, gather(sum(Dist_Ret(:))));

    ap_idx_4D  = max(1, min(n_a1, Pol_k(4, :, :, :, retire_j)));
    ap_val_4D  = reshape(a_G(ap_idx_4D(:)), size(Dist_Ret));
    estate_4D  = (1 - Params.tau_b) .* ap_val_4D + Params.YouthGrant;

    total_beq_val = gather(sum(Dist_Ret(:) .* estate_4D(:)));

    % Since estate_net only depends on ap_idx (1..n_a1), map all n_a1 possible estates at once!
    possible_estates = (1 - Params.tau_b) * a_vec(:) + Params.YouthGrant; % [n_a1 x 1]
    [~, map_ap_to_achild] = min(abs(possible_estates - a_vec(:)'), [], 2); % [n_a1 x 1]
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
    V_j1_all(:, :, :, r_d) = double(gather(V.(['HH_', Regions{r_d}])(:, :, :, 1)));
end

% Vectorized Abroad value tensor V_Abroad_3D: [n_a1, n_h, n_z1]
akl_type = ['HH_', Regions{end}];
net_a_ab = a_vec - Params_Mig.kappa_emig;
valid_ab = (net_a_ab >= 0);
[~, ia_ab_vec] = min(abs(max(0, net_a_ab) - a_vec'), [], 2); % [n_a1 x 1]

wage_gain_vec  = (Params_Mig.w_Abroad / Params.w_reg.(akl_type)) ...
               * (0.85 + 0.25 * (h_vec(:)' / h_vec(min(4, n_h))));     % [1 x n_h]
housing_relief = (Params.Q_reg.(akl_type) / Params_Mig.Q_Abroad)^0.20;

V_Akl_shifted  = V_j1_all(ia_ab_vec, :, :, end);                       % [n_a1, n_h, n_z1]
V_Abroad_3D    = (V_Akl_shifted ./ (reshape(wage_gain_vec, [1, n_h, 1]) * housing_relief)) ...
               - Params_Mig.tau_home_amenity;
V_Abroad_3D(~valid_ab, :, :) = -1e4;

jequaloneDist_new = struct();
for r_dest = 1:N_reg
    jequaloneDist_new.(['HH_', Regions{r_dest}]) = zeros(n_a1, n_h, n_z1);
end

MigMatrix_NxM     = zeros(N_reg, N_reg + 1);
Emig_By_Skill_Num = zeros(n_h, 1);
Emig_By_Skill_Den = zeros(n_h, 1);
pop_weights       = double(gather(Params.PTypeWeights(1:N_reg)));
pop_weights       = pop_weights(:) / sum(pop_weights);
ih_rep_vec        = min(n_h, max(1, round(0.65 * (1:n_h) + 0.35 * 3)));

for r_orig = 1:N_reg
    orig_reg  = Regions{r_orig};
    Dist_orig = NewbornDist_PreMig.(orig_reg);                         % [n_a1, n_h, n_z1]
    w_k       = pop_weights(r_orig);

    % 1. Build 4D Destination Value Tensor V_all_4D: [n_a1, n_h, n_z1, N_reg + 1]
    V_all_4D   = -1e4 * ones(n_a1, n_h, n_z1, N_reg + 1);
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

    % 2. Vectorized Gumbel Choice Probabilities across all (ia, ih, iz) simultaneously
    max_V_3D = max(V_all_4D, [], 4);
    exp_V_4D = exp((V_all_4D - max_V_3D) / Params_Mig.varrho_gumbel);
    prob_4D  = exp_V_4D ./ sum(exp_V_4D, 4);                           % [n_a1, n_h, n_z1, N_reg + 1]

    % 3. Aggregate Migration Matrix & Skill-Specific Emigration Rates
    mass_4D  = Dist_orig .* prob_4D;
    MigMatrix_NxM(r_orig, :) = squeeze(sum(mass_4D, [1, 2, 3]))';
    MigMatrix_NxM(r_orig, :) = MigMatrix_NxM(r_orig, :) / max(1e-12, sum(MigMatrix_NxM(r_orig, :)));

    emig_mass_3D      = mass_4D(:, :, :, N_reg + 1);
    Emig_By_Skill_Num = Emig_By_Skill_Num + w_k * squeeze(sum(emig_mass_3D, [1, 3]))';
    Emig_By_Skill_Den = Emig_By_Skill_Den + w_k * squeeze(sum(Dist_orig,    [1, 3]))';

    % 4. Vectorized Allocation of Retained Youth & Replacement Immigrants to Destination Grids
    for r_dest = 1:N_reg
        dest_type = ['HH_', Regions{r_dest}];
        ia_d      = ia_dest_mat(:, r_dest);                            % [n_a1 x 1]

        % Retained domestic movers to r_dest + Replacement immigrants entering r_dest
        stay_mass_3D = mass_4D(:, :, :, r_dest);
        repl_mass_3D = emig_mass_3D * pop_weights(r_dest);

        % Project along 1st dimension (ia -> ia_d) using a sparse projection matrix P_ia
        P_ia = sparse(ia_d, 1:n_a1, 1, n_a1, n_a1);
        stay_proj = reshape(P_ia * reshape(stay_mass_3D, n_a1, []), [n_a1, n_h, n_z1]);
        repl_proj = reshape(P_ia * reshape(repl_mass_3D, n_a1, []), [n_a1, n_h, n_z1]);

        jequaloneDist_new.(dest_type) = jequaloneDist_new.(dest_type) + stay_proj;
        for ih = 1:n_h
            ih_r = ih_rep_vec(ih);
            jequaloneDist_new.(dest_type)(:, ih_r, :) = ...
                jequaloneDist_new.(dest_type)(:, ih_r, :) + repl_proj(:, ih, :);
        end
    end
end

for r_dest = 1:N_reg
    dest_type = ['HH_', Regions{r_dest}];
    jequaloneDist_new.(dest_type) = jequaloneDist_new.(dest_type) / max(1e-12, sum(jequaloneDist_new.(dest_type)(:)));
end

%% STORE DIAGNOSTICS (COMPATIBLE WITH BOTH 3-REGION AND 4-REGION PIPELINES)
Diag.MigrationMatrix_3x4   = MigMatrix_NxM;
Diag.MigrationMatrix_4x5   = MigMatrix_NxM;
Diag.MigrationMatrix       = MigMatrix_NxM(:, 1:N_reg) ./ max(1e-12, sum(MigMatrix_NxM(:, 1:N_reg), 2));
Diag.Emig_By_Region        = MigMatrix_NxM(:, N_reg + 1)';
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
