function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions, Params_Mig)
%% SELF-CACHING & VECTORIZED 5D INTERGENERATIONAL TRANSITION MATRIX (4 REGIONS + OPTIONAL ABROAD)
% File: Build_IntergenTransitionMatrix.m
% Regions (N_reg = 4): {'Rural', 'Small', 'Large', 'Auckland'} + Optional 5th Outside Option ('Abroad')
% Directly observes the two-stage child skill experience asset theta_c at j = 4 and j = 5,
% maps dying retiree estates (j >= Jr), and computes 4x4 (or 4x5 with Abroad) Gumbel spatial youth sorting.

persistent mem_cache
if isempty(mem_cache)
    mem_cache = struct('hash', '', 'jequaloneDist_new', [], 'Diag', []);
end

N_reg = length(Regions);
n_a1  = n_a.HH_Rural(1);
n_h   = n_a.HH_Rural(2);
n_th  = n_a.HH_Rural(3);
n_z1  = n_z.HH_Rural;

%% 0. RESOLVE ABROAD OPTION & MIGRATION PARAMETERS
use_abroad = false;
if nargin >= 13 && ~isempty(Params_Mig)
    if isstruct(Params_Mig)
        if isfield(Params_Mig, 'Enable_Abroad')
            use_abroad = logical(Params_Mig.Enable_Abroad);
        else
            use_abroad = true;
        end
    elseif islogical(Params_Mig) || isnumeric(Params_Mig)
        use_abroad = logical(Params_Mig);
        Params_Mig = struct();
    end
elseif isfield(Params, 'Enable_Abroad_Option') && Params.Enable_Abroad_Option
    use_abroad = true;
    if isfield(Params, 'Params_Mig') && isstruct(Params.Params_Mig)
        Params_Mig = Params.Params_Mig;
    else
        Params_Mig = struct();
    end
else
    Params_Mig = struct();
end

if use_abroad
    def_mig = struct( ...
        'Enable_Abroad',    true,  ...
        'w_Abroad',         1.32,  ... % Foreign (OECD/Australia) benchmark skill wage
        'Q_Abroad',         2.15,  ... % Foreign house price benchmark (vs Auckland 3.10)
        'kappa_emig',       0.14,  ... % Fixed international moving cost
        'tau_home_amenity', 0.85,  ... % Whanau / native home-attachment premium in NZ
        'varrho_gumbel',    0.45,  ... % Gumbel taste shock scale when Abroad is active
        'home_stay_bonus',  0.95,  ... % Domestic origin-region retention amenity
        'Target_NetMig',    0.025, ... % Stats NZ +25k/yr net migration target
        'nu_retention',     0.40,  ... % Social cohesion elasticity wrt native retention
        'nu_churn',         0.35,  ... % Social cohesion penalty wrt migration churn
        'gamma_proximity',  0.45,  ... % Parental utility weight on children staying in NZ
        'gamma_thrive',     0.35);     % Parental utility weight on children thriving
    mig_fields = fieldnames(def_mig);
    for f_i = 1:numel(mig_fields)
        fn = mig_fields{f_i};
        if ~isfield(Params_Mig, fn) || isempty(Params_Mig.(fn))
            Params_Mig.(fn) = def_mig.(fn);
        end
    end
else
    Params_Mig.Enable_Abroad = false;
end

% Embed in Params_cache so the hash distinguishes 4x4 vs 4x5 Abroad runs
Params_cache            = Params;
Params_cache.Params_Mig = Params_Mig;

%% 0B. GATHER INPUTS ONCE & CHECK IN-MEMORY / DISK CACHE
Dist_cpu = struct();
Pol_cpu  = struct();
V1_cpu   = struct();
fingerprint_vec = zeros(3 * N_reg + 1, 1);

for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    D_tmp   = gather(StationaryDist.(hh_type));
    P_tmp   = gather(Policy.(hh_type));
    V_tmp   = gather(V.(hh_type));

    Dist_cpu.(hh_type) = D_tmp;
    Pol_cpu.(hh_type)  = P_tmp;
    V1_cpu.(hh_type)   = V_tmp(:, :, :, :, 1);

    D_flat     = D_tmp(:);
    idx_sample = round(linspace(1, numel(D_flat), min(256, numel(D_flat))))';
    fingerprint_vec(3*(r_idx-1) + 1) = sum(D_flat(idx_sample) .* (1:numel(idx_sample))');
    fingerprint_vec(3*(r_idx-1) + 2) = sum(double(P_tmp(1:min(512, numel(P_tmp)))));
    v1_flat = V1_cpu.(hh_type)(:);
    v1_ok   = v1_flat(isfinite(v1_flat));
    if ~isempty(v1_ok)
        fingerprint_vec(3*(r_idx-1) + 3) = sum(v1_ok(1:min(256, numel(v1_ok))));
    end
end
fingerprint_vec(end) = double(use_abroad);

[cache_file, hash_hex] = local_get_ig_cache_path(Params_cache, n_d, n_a, n_z, fingerprint_vec);

if strcmp(mem_cache.hash, hash_hex) && ~isempty(mem_cache.jequaloneDist_new)
    jequaloneDist_new = mem_cache.jequaloneDist_new;
    Diag              = mem_cache.Diag;
    return;
end
if exist(cache_file, 'file') == 2
    loaded_data       = load(cache_file, 'jequaloneDist_new', 'Diag');
    jequaloneDist_new = loaded_data.jequaloneDist_new;
    Diag              = loaded_data.Diag;
    mem_cache.hash              = hash_hex;
    mem_cache.jequaloneDist_new = jequaloneDist_new;
    mem_cache.Diag              = Diag;
    return;
end

%% 1. PREPARE CPU GRIDS
a_grid_cpu = gather(a_grid.HH_Rural);
a_vec      = a_grid_cpu(1 : n_a1);
h_vec      = a_grid_cpu(n_a1+1 : n_a1+n_h);
th_vec     = a_grid_cpu(n_a1+n_h+1 : end);
log_h_col  = log(h_vec(:));

NewbornDist_PreMig = struct();
Diag               = struct();

%% 2. VECTORIZED STAGE 1 (SKILL FORMATION) & STAGE 2 ($1.6T BEQUEST INHERITANCE)
for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    Dist_k  = Dist_cpu.(hh_type); % [n_a1, n_h, n_th, n_z1, J]
    Pol_k   = Pol_cpu.(hh_type);  % [4, n_a1, n_h, n_th, n_z1, J]
    Q_house = Params.Q_reg.(hh_type);

    % --- 1. OBSERVE STAGE-1 (j=4) AND COMPLETED STAGE-2 (j=5) EXPERIENCE ASSET theta_c ---
    Dist_theta2 = squeeze(sum(Dist_k(:, :, :, :, 4), [1, 2, 4]));
    Dist_theta2 = Dist_theta2 / max(1e-12, sum(Dist_theta2));
    Diag.MeanTheta2.(reg) = sum(Dist_theta2(:) .* th_vec(:));

    Dist_j5_a_th = squeeze(sum(Dist_k(:, :, :, :, 5), [2, 4])); % [n_a1, n_th]
    parent_mass  = sum(Dist_j5_a_th(:));
    mass_by_th   = sum(Dist_j5_a_th, 1)';
    Diag.MeanTheta3.(reg) = sum(mass_by_th .* th_vec) / max(1e-12, parent_mass);

    housing_crowd_pen = 0.06 * log(max(1.0, Q_house));
    is_hardship_vec   = double(a_vec < 0.05 * Q_house); % [n_a1, 1]
    log_h_mean_mat    = log(th_vec') - housing_crowd_pen * is_hardship_vec; % [n_a1, n_th]

    trans_probs  = normpdf(log_h_col, log_h_mean_mat(:)', Params.sigma_hc_ig); % [n_h, n_a1*n_th]
    trans_probs  = trans_probs ./ max(1e-12, sum(trans_probs, 1));
    Prob_h_child = (trans_probs * Dist_j5_a_th(:)) / max(1e-12, parent_mass);

    Diag.StuntedShare.(reg)  = sum(Prob_h_child(1:2));
    Diag.ThrivingShare.(reg) = sum(Prob_h_child(max(1, end-1):end));

    % --- 2. VECTORIZED $1.6T PROPERTY BEQUEST OPERATOR (j >= Jr) ---
    ret_ages     = Params.Jr : Params.J;
    mort_probs   = reshape(1 - Params.sj(ret_ages), [1, 1, 1, 1, length(ret_ages)]);
    m_ret_tensor = Dist_k(:, :, :, :, ret_ages) .* mort_probs;

    ap_idx_flat  = min(n_a1, max(1, Pol_k(4, :, :, :, :, ret_ages)));
    ap_idx_flat  = ap_idx_flat(:);
    m_ret_flat   = m_ret_tensor(:);
    beq_mass     = sum(m_ret_flat);

    possible_estates  = (1 - Params.tau_b) * a_vec + Params.YouthGrant;
    [~, map_ap_to_ac] = min(abs(a_vec' - possible_estates), [], 2);

    mass_by_ap   = accumarray(ap_idx_flat, m_ret_flat, [n_a1, 1]);
    Prob_a_child = accumarray(map_ap_to_ac, mass_by_ap, [n_a1, 1]) / max(1e-12, beq_mass);

    Diag.MeanBequest.(reg) = sum(mass_by_ap .* possible_estates) / max(1e-12, beq_mass);

    pi_z_cpu = gather(pi_z.(hh_type));
    stat_z   = (pi_z_cpu^50)';
    stat_z   = stat_z(:, 1);

    NewbornDist_PreMig.(reg) = zeros(n_a1, n_h, n_th, n_z1);
    az_outer = reshape(Prob_a_child * stat_z', [n_a1, 1, 1, n_z1]);
    for ih = 1:n_h
        ith_init = min(n_th, max(1, ih + 1));
        NewbornDist_PreMig.(reg)(:, ih, ith_init, :) = Prob_h_child(ih) * az_outer;
    end
end

%% 3. VECTORIZED STAGE 3: 4x4 DOMESTIC OR 4x5 (DOMESTIC + ABROAD) YOUTH MIGRATION MATRIX
if N_reg == 4
    kappa_mat = [ ...
        0.00, 0.08, 0.15, 0.28;  % Rural    -> [Rural, Small, Large, Auckland]
        0.07, 0.00, 0.12, 0.24;  % Small    -> [Rural, Small, Large, Auckland]
        0.09, 0.07, 0.00, 0.16;  % Large    -> [Rural, Small, Large, Auckland]
        0.08, 0.07, 0.06, 0.00]; % Auckland -> [Rural, Small, Large, Auckland]
else
    kappa_mat = [0.00, 0.12, 0.25; 0.10, 0.00, 0.18; 0.08, 0.08, 0.00];
end

jequaloneDist_new = struct();
for r_dest = 1:N_reg
    jequaloneDist_new.(['HH_', Regions{r_dest}]) = zeros(n_a1, n_h, n_th, n_z1);
end
N_hthz      = n_h * n_th * n_z1;
pop_weights = gather(Params.PTypeWeights(1:N_reg));
pop_weights = pop_weights(:) / sum(pop_weights);

if ~use_abroad
    % =========================================================================
    % BRANCH A: STANDARD 4x4 DOMESTIC SPATIAL MIGRATION (NO ABROAD LEAKAGE)
    % =========================================================================
    varrho_gumbel   = 0.75;
    home_stay_bonus = 0.95;
    MigMatrix       = zeros(N_reg, N_reg);

    for r_orig = 1:N_reg
        orig_reg    = Regions{r_orig};
        Dist_orig   = NewbornDist_PreMig.(orig_reg);
        ia_dest_mat = zeros(n_a1, N_reg);
        V_dest_all  = -1e4 * ones(n_a1, n_h, n_th, n_z1, N_reg);

        for r_dest = 1:N_reg
            dest_type = ['HH_', Regions{r_dest}];
            net_a_vec = a_vec - kappa_mat(r_orig, r_dest);
            feas_vec  = (net_a_vec >= 0);
            [~, ia_dest_mat(:, r_dest)] = min(abs(a_vec' - max(0, net_a_vec)), [], 2);

            V1_d    = V1_cpu.(dest_type)(ia_dest_mat(:, r_dest), :, :, :);
            V_slice = -1e4 * ones(n_a1, n_h, n_th, n_z1);
            V_slice(feas_vec, :, :, :) = V1_d(feas_vec, :, :, :) + (r_dest == r_orig) * home_stay_bonus;
            V_dest_all(:, :, :, :, r_dest) = V_slice;
        end

        max_V     = max(V_dest_all, [], 5);
        exp_V     = exp((V_dest_all - max_V) / varrho_gumbel);
        prob_move = exp_V ./ sum(exp_V, 5);

        for r_dest = 1:N_reg
            dest_type = ['HH_', Regions{r_dest}];
            flow_4d   = Dist_orig .* prob_move(:, :, :, :, r_dest);
            MigMatrix(r_orig, r_dest) = sum(flow_4d(:));

            ia_d_vec = ia_dest_mat(:, r_dest);
            S_map    = sparse(ia_d_vec, 1:n_a1, 1, n_a1, n_a1);
            flow_2d  = reshape(flow_4d, [n_a1, N_hthz]);
	    jequaloneDist_new.(dest_type) = jequaloneDist_new.(dest_type) ...
					    + pop_weights(r_orig) * reshape(full(S_map * flow_2d), [n_a1, n_h, n_th, n_z1]);
        end
        MigMatrix(r_orig, :) = MigMatrix(r_orig, :) / max(1e-12, sum(MigMatrix(r_orig, :)));
    end

    Diag.MigrationMatrix        = MigMatrix;
    Diag.MigrationMatrix_4x5    = [MigMatrix, zeros(N_reg, 1)];
    Diag.Emig_By_Region         = zeros(1, N_reg);
    Diag.Emig_By_SkillTier      = zeros(n_h, 1);
    Diag.EmigRate_Youth         = 0.0;
    Diag.HighSkill_EmigShare    = 0.0;
    Diag.ReplacementImmig_Rate  = 0.0;
    Diag.Churn_Rate             = 0.0;
    Diag.SocialCohesion_Index   = 100.0;
    Diag.ParentalRelational_CE  = 0.0;

else
    % =========================================================================
    % BRANCH B: 4x5 DOMESTIC + ABROAD MIGRATION & REPLACEMENT CHURN (5D)
    % Columns 1..N_reg: Domestic Regions {'Rural','Small','Large','Auckland'}
    % Column  N_reg+1 : Outside Option ('Abroad')
    % =========================================================================
    varrho_gumbel   = Params_Mig.varrho_gumbel;
    home_stay_bonus = Params_Mig.home_stay_bonus;
    MigMatrix_4x5   = zeros(N_reg, N_reg + 1);
    Emig_By_Skill_Num = zeros(n_h, 1);
    Emig_By_Skill_Den = zeros(n_h, 1);

    % Precompute Outside Option Value V_Abroad(a_1 - kappa_emig, h_1, theta_c, z_1, j=1)
    % Benchmarked against primate metro (HH_Auckland) with skill-biased foreign wage gain
    net_a_ab_vec = a_vec - Params_Mig.kappa_emig;
    feas_ab_vec  = (net_a_ab_vec >= 0);
    [~, ia_ab_vec] = min(abs(a_vec' - max(0, net_a_ab_vec)), [], 2);

    h_mid_val        = h_vec(min(n_h, 4));
    wage_gain_vec    = (Params_Mig.w_Abroad / Params.w_reg.HH_Auckland) ...
                       * (0.85 + 0.25 * (h_vec / h_mid_val)); % [n_h, 1]
    housing_relief   = (Params.Q_reg.HH_Auckland / Params_Mig.Q_Abroad)^0.20;
    scale_abroad_4d  = reshape(wage_gain_vec * housing_relief, [1, n_h, 1, 1]);

    V1_Akl_ab = V1_cpu.HH_Auckland(ia_ab_vec, :, :, :);
    % Under CRRA (eta > 1, V < 0), dividing negative V by scale > 1 raises utility toward 0
    V_Abroad_slice = -1e4 * ones(n_a1, n_h, n_th, n_z1);
    V_scaled       = V1_Akl_ab ./ max(0.10, scale_abroad_4d) - Params_Mig.tau_home_amenity;
    pos_mask       = (V1_Akl_ab >= 0);
    if any(pos_mask(:))
        V_pos = V1_Akl_ab .* scale_abroad_4d - Params_Mig.tau_home_amenity;
        V_scaled(pos_mask) = V_pos(pos_mask);
    end
    V_Abroad_slice(feas_ab_vec, :, :, :) = V_scaled(feas_ab_vec, :, :, :);

    % Precompute sparse replacement-immigrant skill projection across (h, theta_c, z)
    % Replacement immigrants enter around median skill tier (ih_rep = round(0.65*ih + 0.35*3))
    [ih_grid, ith_grid, iz_grid] = ndgrid(1:n_h, 1:n_th, 1:n_z1);
    ih_rep_grid  = min(n_h, max(1, round(0.65 * ih_grid + 0.35 * 3)));
    ith_rep_grid = min(n_th, max(1, ih_rep_grid + 1));
    src_hthz_idx = sub2ind([n_h, n_th, n_z1], ih_grid(:), ith_grid(:), iz_grid(:));
    dst_hthz_idx = sub2ind([n_h, n_th, n_z1], ih_rep_grid(:), ith_rep_grid(:), iz_grid(:));
    S_rep_hthz   = sparse(src_hthz_idx, dst_hthz_idx, 1, N_hthz, N_hthz);

    for r_orig = 1:N_reg
        orig_reg    = Regions{r_orig};
        Dist_orig   = NewbornDist_PreMig.(orig_reg);
        w_k         = pop_weights(r_orig);
        ia_dest_mat = zeros(n_a1, N_reg);
        V_all_5d    = -1e4 * ones(n_a1, n_h, n_th, n_z1, N_reg + 1);

        % 1. Domestic Destination Values (Cols 1..N_reg)
        for r_dest = 1:N_reg
            dest_type = ['HH_', Regions{r_dest}];
            net_a_vec = a_vec - kappa_mat(r_orig, r_dest);
            feas_vec  = (net_a_vec >= 0);
            [~, ia_dest_mat(:, r_dest)] = min(abs(a_vec' - max(0, net_a_vec)), [], 2);

            V1_d    = V1_cpu.(dest_type)(ia_dest_mat(:, r_dest), :, :, :);
            V_slice = -1e4 * ones(n_a1, n_h, n_th, n_z1);
            V_slice(feas_vec, :, :, :) = V1_d(feas_vec, :, :, :) + (r_dest == r_orig) * home_stay_bonus;
            V_all_5d(:, :, :, :, r_dest) = V_slice;
        end

        % 2. Abroad Outside Option Value (Col N_reg + 1)
        V_all_5d(:, :, :, :, N_reg + 1) = V_Abroad_slice;

        % 3. Gumbel Choice Probabilities across [Rural, Small, Large, Auckland, Abroad]
        max_V     = max(V_all_5d, [], 5);
        exp_V     = exp((V_all_5d - max_V) / varrho_gumbel);
        prob_move = exp_V ./ sum(exp_V, 5);

        % 4. Emigration Flow to Abroad (Column N_reg + 1)
        prob_emig_4d = prob_move(:, :, :, :, N_reg + 1);
        flow_emig_4d = Dist_orig .* prob_emig_4d;
        MigMatrix_4x5(r_orig, N_reg + 1) = sum(flow_emig_4d(:));

        emig_by_h = squeeze(sum(flow_emig_4d, [1, 3, 4]));
        orig_by_h = squeeze(sum(Dist_orig,    [1, 3, 4]));
        Emig_By_Skill_Num = Emig_By_Skill_Num + w_k * emig_by_h(:);
        Emig_By_Skill_Den = Emig_By_Skill_Den + w_k * orig_by_h(:);

        % 5. Allocate Retained Domestic Youth + Replacement Immigrant Inflow to each r_dest
        S_map_ab         = sparse(ia_ab_vec, 1:n_a1, 1, n_a1, n_a1);
        flow_emig_2d     = reshape(flow_emig_4d, [n_a1, N_hthz]);
        flow_emig_rep_2d = full(S_map_ab * flow_emig_2d * S_rep_hthz);

        for r_dest = 1:N_reg
            dest_type = ['HH_', Regions{r_dest}];
            flow_dom_4d = Dist_orig .* prob_move(:, :, :, :, r_dest);
            MigMatrix_4x5(r_orig, r_dest) = sum(flow_dom_4d(:));

            ia_d_vec = ia_dest_mat(:, r_dest);
            S_map    = sparse(ia_d_vec, 1:n_a1, 1, n_a1, n_a1);

            % Retained native youth + replacement immigrant inflow apportioned by pop_weights(r_dest)
            dom_mapped_2d = full(S_map * reshape(flow_dom_4d, [n_a1, N_hthz]));
            combined_2d   = w_k * (dom_mapped_2d + pop_weights(r_dest) * flow_emig_rep_2d);
            jequaloneDist_new.(dest_type) = jequaloneDist_new.(dest_type) ...
                + reshape(combined_2d, [n_a1, n_h, n_th, n_z1]);
        end

        MigMatrix_4x5(r_orig, :) = MigMatrix_4x5(r_orig, :) / max(1e-12, sum(MigMatrix_4x5(r_orig, :)));
    end

    % Store 4x4 conditional domestic matrix and 4x5 international brain-drain diagnostics
    Diag.MigrationMatrix_4x5    = MigMatrix_4x5;
    Diag.MigrationMatrix_NxNplus1 = MigMatrix_4x5;
    Diag.MigrationMatrix        = MigMatrix_4x5(:, 1:N_reg) ./ max(1e-12, sum(MigMatrix_4x5(:, 1:N_reg), 2));
    Diag.Emig_By_Region         = MigMatrix_4x5(:, N_reg + 1)';
    Diag.Emig_By_SkillTier      = Emig_By_Skill_Num ./ max(1e-12, Emig_By_Skill_Den);
    Diag.EmigRate_Youth         = sum(Emig_By_Skill_Num) / max(1e-12, sum(Emig_By_Skill_Den));
    Diag.HighSkill_EmigShare    = sum(Emig_By_Skill_Num(max(1, n_h-2):n_h)) / max(1e-12, sum(Emig_By_Skill_Num));

    % Compute Replacement Migration Churn, Social Cohesion S_t, & Parental Relational CE %
    Diag.ReplacementImmig_Rate  = Params_Mig.Target_NetMig + 0.35 * Diag.EmigRate_Youth;
    Diag.Churn_Rate             = 0.35 * Diag.EmigRate_Youth + Diag.ReplacementImmig_Rate;

    raw_S = ((1 - Diag.EmigRate_Youth)^Params_Mig.nu_retention) ...
          * ((1 + Diag.Churn_Rate)^(-Params_Mig.nu_churn));
    Diag.SocialCohesion_Index   = 100.0 * (raw_S / 0.885);

    nat_stunted = 0;
    for r_i = 1:N_reg
        nat_stunted = nat_stunted + pop_weights(r_i) * Diag.StuntedShare.(Regions{r_i});
    end
    rel_util = Params_Mig.gamma_thrive * log(max(0.01, 1 - nat_stunted)) ...
             + Params_Mig.gamma_proximity * log(max(0.01, 1 - Diag.EmigRate_Youth));
    Diag.ParentalRelational_CE  = 100 * (exp(rel_util + 0.22) - 1);
end

for r_dest = 1:N_reg
    dest_type = ['HH_', Regions{r_dest}];
    jequaloneDist_new.(dest_type) = jequaloneDist_new.(dest_type) / sum(jequaloneDist_new.(dest_type)(:));
end

mem_cache.hash              = hash_hex;
mem_cache.jequaloneDist_new = jequaloneDist_new;
mem_cache.Diag              = Diag;
try
    save(cache_file, 'jequaloneDist_new', 'Diag');
catch
end
end

function [cache_filepath, hash_hex] = local_get_ig_cache_path(Params, n_d, n_a, n_z, fingerprint_vec)
    CacheDir = fullfile(pwd, 'Cache_NZ_Intergen');
    if ~exist(CacheDir, 'dir'); mkdir(CacheDir); end
    state_struct = struct('Params', Params, 'n_d', n_d, 'n_a', n_a, 'n_z', n_z, 'fp', round(fingerprint_vec(:), 6));
    raw_bytes    = getByteStreamFromArray(state_struct);
    stride       = max(1, floor(numel(raw_bytes) / 4096));
    sampled      = double(raw_bytes(1:stride:end));
    sampled      = sampled(:);
    weights      = mod((1:numel(sampled))' * 1315423911, 2^31 - 1);
    hash_val     = mod(sum(sampled .* weights), 2^32);
    hash_hex     = sprintf('%08X', uint32(hash_val(1)));
    cache_filepath = fullfile(CacheDir, sprintf('Cache_IGMat_5D_%s.mat', hash_hex));
end
