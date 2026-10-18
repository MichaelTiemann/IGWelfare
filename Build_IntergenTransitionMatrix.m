function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions)
%% SELF-CACHING & VECTORIZED INTERGENERATIONAL TRANSITION MATRIX (5D & 4D COMPATIBLE)
% File: Build_IntergenTransitionMatrix.m
% Regions (N_reg = 4): {'Rural', 'Small', 'Large', 'Auckland'}
% Features:
%   1. Two-Tier Caching (Persistent In-Memory + Content-Hashed .mat Disk Cache)
%   2. Automatic 5D (n_a = [a, h, theta_c]) vs 4D (n_a = [a, h]) State-Space Detection
%   3. Fully Vectorized Stage 1 (Skills), Stage 2 ($1.6T Estates), and Stage 3 (4x4 Migration)

persistent mem_cache
if isempty(mem_cache)
    mem_cache = struct('hash', '', 'jequaloneDist_new', [], 'Diag', []);
end

N_reg = length(Regions);
is_5D = (length(n_a.HH_Rural) == 3);
n_a1  = n_a.HH_Rural(1);
n_h   = n_a.HH_Rural(2);
n_z1  = n_z.HH_Rural;

%% 0. GATHER INPUTS ONCE & CHECK IN-MEMORY / DISK CACHE
Dist_cpu = struct();
Pol_cpu  = struct();
V1_cpu   = struct();
fingerprint_vec = zeros(3 * N_reg, 1);

for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    D_tmp   = gather(StationaryDist.(hh_type));
    P_tmp   = gather(Policy.(hh_type));
    V_tmp   = gather(V.(hh_type));

    Dist_cpu.(hh_type) = D_tmp;
    Pol_cpu.(hh_type)  = P_tmp;
    if is_5D
        V1_cpu.(hh_type) = V_tmp(:, :, :, :, 1);
    else
        V1_cpu.(hh_type) = reshape(V_tmp(:, :, :, 1), [n_a1, n_h, 1, n_z1]);
    end

    % Fast scalar numerical fingerprint of the current distribution, policy, and value function
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

% Build deterministic hash from (Params, n_d, n_a, n_z, fingerprint_vec)
[cache_file, hash_hex] = local_get_ig_cache_path(Params, n_d, n_a, n_z, fingerprint_vec, is_5D);

% Tier 1: Check fast in-memory persistent cache
if strcmp(mem_cache.hash, hash_hex) && ~isempty(mem_cache.jequaloneDist_new)
    jequaloneDist_new = mem_cache.jequaloneDist_new;
    Diag              = mem_cache.Diag;
    return;
end

% Tier 2: Check on-disk .mat cache
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

if is_5D
    n_th   = n_a.HH_Rural(3);
    th_vec = a_grid_cpu(n_a1+n_h+1 : end);
else
    n_th   = 1;
    d_cpu  = gather(d_grid.HH_Rural);
    % Support both [l, ic, Ih] ([4,7,3]) and [l, Ih, ic] ([4,3,7]) in 4D compact mode
    if n_d.HH_Rural(2) == 7
        ic_row = 2;
        ic_vec = d_cpu(n_d.HH_Rural(1)+1 : n_d.HH_Rural(1)+n_d.HH_Rural(2));
    else
        ic_row = 3;
        ic_vec = d_cpu(n_d.HH_Rural(1)+n_d.HH_Rural(2)+1 : end);
    end
    if ~isfield(Params, 'G_ece') && isfield(Params, 'G_ece_stage1')
        Params.G_ece = Params.G_ece_stage1;
    end
    if ~isfield(Params, 'rho_hc_ig'); Params.rho_hc_ig = 0.40; end
    if ~isfield(Params, 'gamma_ic');  Params.gamma_ic  = 0.35; end
end

NewbornDist_PreMig = struct();
Diag               = struct();

%% 2. VECTORIZED STAGE 1 (SKILL FORMATION) & STAGE 2 ($1.6T BEQUEST INHERITANCE)
log_h_col = log(h_vec(:)); % [n_h, 1]

for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];

    Dist_k  = Dist_cpu.(hh_type);
    Pol_k   = Pol_cpu.(hh_type);
    Q_house = Params.Q_reg.(hh_type);

    if is_5D
        % --- 5D MODE: OBSERVE COMPLETED EXPERIENCE ASSET theta_c AT j = 4 AND j = 5 ---
        Dist_theta2 = squeeze(sum(Dist_k(:, :, :, :, 4), [1, 2, 4]));
        Dist_theta2 = Dist_theta2 / max(1e-12, sum(Dist_theta2));
        Diag.MeanTheta2.(reg) = sum(Dist_theta2(:) .* th_vec(:));

        % Marginalize over (ih, iz) at j = 5 -> [n_a1, n_th]
        Dist_j5_a_th = squeeze(sum(Dist_k(:, :, :, :, 5), [2, 4]));
        parent_mass  = sum(Dist_j5_a_th(:));
        mass_by_th   = sum(Dist_j5_a_th, 1)';
        Diag.MeanTheta3.(reg) = sum(mass_by_th .* th_vec) / max(1e-12, parent_mass);

        housing_crowd_pen = 0.06 * log(max(1.0, Q_house));
        is_hardship_vec   = double(a_vec < 0.05 * Q_house); % [n_a1, 1]
        log_h_mean_mat    = log(th_vec') - housing_crowd_pen * is_hardship_vec; % [n_a1, n_th]

        % Vectorized Gaussian transition across all (ia, ith) pairs simultaneously
        trans_probs  = normpdf(log_h_col, log_h_mean_mat(:)', Params.sigma_hc_ig); % [n_h, n_a1*n_th]
        trans_probs  = trans_probs ./ max(1e-12, sum(trans_probs, 1));
        Prob_h_child = (trans_probs * Dist_j5_a_th(:)) / max(1e-12, parent_mass);

        ret_ages     = Params.Jr : Params.J;
        mort_probs   = reshape(1 - Params.sj(ret_ages), [1, 1, 1, 1, length(ret_ages)]);
        m_ret_tensor = Dist_k(:, :, :, :, ret_ages) .* mort_probs;
        ap_idx_flat  = min(n_a1, max(1, Pol_k(4, :, :, :, :, ret_ages)));
    else
        % --- 4D MODE: ANCHORED SKILL FORMATION AT j = 3, 4 ---
        Dist_fertile = Dist_k(:, :, :, [3, 4]);
        parent_mass  = sum(Dist_fertile(:));
        ic_idx_fert  = min(length(ic_vec), max(1, Pol_k(ic_row, :, :, :, [3, 4])));
        ic_vals_fert = reshape(ic_vec(ic_idx_fert(:)), size(Dist_fertile));

        housing_stress_penalty = 0.08 * log(max(1.0, Q_house));
        is_hardship_4d = repmat(double(a_vec < 0.05 * Q_house), [1, n_h, n_z1, 2]);
        log_hp_4d      = repmat(reshape(log_h_col, [1, n_h, 1, 1]), [n_a1, 1, n_z1, 2]);

        log_h_mean_4d = Params.rho_hc_ig * log_hp_4d ...
            + Params.gamma_ic * log(1 + ic_vals_fert + Params.G_ece) ...
            - housing_stress_penalty * is_hardship_4d;

        trans_probs  = normpdf(log_h_col, log_h_mean_4d(:)', Params.sigma_hc_ig);
        trans_probs  = trans_probs ./ max(1e-12, sum(trans_probs, 1));
        Prob_h_child = (trans_probs * Dist_fertile(:)) / max(1e-12, parent_mass);

        ret_ages     = Params.Jr : Params.J;
        mort_probs   = reshape(1 - Params.sj(ret_ages), [1, 1, 1, length(ret_ages)]);
        m_ret_tensor = Dist_k(:, :, :, ret_ages) .* mort_probs;
        ap_idx_flat  = min(n_a1, max(1, Pol_k(4, :, :, :, ret_ages)));
    end

    Diag.StuntedShare.(reg)  = sum(Prob_h_child(1:2));
    Diag.ThrivingShare.(reg) = sum(Prob_h_child(max(1, end-1):end));

    % --- VECTORIZED $1.6T PROPERTY BEQUEST OPERATOR (j >= Jr) ---
    ap_idx_flat  = ap_idx_flat(:);
    m_ret_flat   = m_ret_tensor(:);
    beq_mass     = sum(m_ret_flat);

    % Map each of the n_a1 possible aprime grid points to nearest child asset grid point once
    possible_estates  = (1 - Params.tau_b) * a_vec + Params.YouthGrant;
    [~, map_ap_to_ac] = min(abs(a_vec' - possible_estates), [], 2); % [n_a1, 1]

    % First bin dying retiree mass by aprime index (1..n_a1), then map to child asset index
    mass_by_ap   = accumarray(ap_idx_flat, m_ret_flat, [n_a1, 1]);
    Prob_a_child = accumarray(map_ap_to_ac, mass_by_ap, [n_a1, 1]) / max(1e-12, beq_mass);
    Diag.MeanBequest.(reg) = sum(mass_by_ap .* possible_estates) / max(1e-12, beq_mass);

    % Stationary initial productivity draw z_1 in region k
    pi_z_cpu = gather(pi_z.(hh_type));
    stat_z   = (pi_z_cpu^50)';
    stat_z   = stat_z(:, 1);

    % Construct 4D Pre-Migration Newborn Distribution [n_a1, n_h, n_th, n_z1]
    NewbornDist_PreMig.(reg) = zeros(n_a1, n_h, n_th, n_z1);
    az_outer = Prob_a_child * stat_z'; % [n_a1, n_z1]
    for ih = 1:n_h
        ith_init = min(n_th, max(1, ih + is_5D));
        NewbornDist_PreMig.(reg)(:, ih, ith_init, :) = Prob_h_child(ih) * az_outer;
    end
end

%% 3. VECTORIZED STAGE 3: 4x4 SPATIAL YOUTH MIGRATION MATRIX
if N_reg == 4
    kappa_mat = [ ...
        0.00, 0.08, 0.15, 0.28;  % From Rural    -> [Rural, Small, Large, Auckland]
        0.07, 0.00, 0.12, 0.24;  % From Small    -> [Rural, Small, Large, Auckland]
        0.09, 0.07, 0.00, 0.16;  % From Large    -> [Rural, Small, Large, Auckland]
        0.08, 0.07, 0.06, 0.00]; % From Auckland -> [Rural, Small, Large, Auckland]
else
    kappa_mat = [0.00, 0.12, 0.25; 0.10, 0.00, 0.18; 0.08, 0.08, 0.00];
end
varrho_gumbel = 0.45;
MigMatrix     = zeros(N_reg, N_reg);

jequaloneDist_new = struct();
for r_dest = 1:N_reg
    jequaloneDist_new.(['HH_', Regions{r_dest}]) = zeros(n_a1, n_h, n_th, n_z1);
end

N_hthz = n_h * n_th * n_z1;

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
        V_slice(feas_vec, :, :, :) = V1_d(feas_vec, :, :, :);
        V_dest_all(:, :, :, :, r_dest) = V_slice;
    end

    % Closed-form Gumbel logit probabilities across all states at once
    max_V     = max(V_dest_all, [], 5);
    exp_V     = exp((V_dest_all - max_V) / varrho_gumbel);
    prob_move = exp_V ./ sum(exp_V, 5);

    for r_dest = 1:N_reg
        dest_type = ['HH_', Regions{r_dest}];
        flow_4d   = Dist_orig .* prob_move(:, :, :, :, r_dest);
        MigMatrix(r_orig, r_dest) = sum(flow_4d(:));

        % Vectorized accumulation into destination asset indices via sparse/matrix multiply
        ia_d_vec = ia_dest_mat(:, r_dest);
        S_map    = sparse(ia_d_vec, 1:n_a1, 1, n_a1, n_a1);
        flow_2d  = reshape(flow_4d, [n_a1, N_hthz]);
        jequaloneDist_new.(dest_type) = jequaloneDist_new.(dest_type) ...
            + reshape(full(S_map * flow_2d), [n_a1, n_h, n_th, n_z1]);
    end
    MigMatrix(r_orig, :) = MigMatrix(r_orig, :) / max(1e-12, sum(MigMatrix(r_orig, :)));
end

for r_dest = 1:N_reg
    dest_type = ['HH_', Regions{r_dest}];
    dist_out  = jequaloneDist_new.(dest_type) / sum(jequaloneDist_new.(dest_type)(:));
    if ~is_5D
        dist_out = reshape(dist_out, [n_a1, n_h, n_z1]);
    end
    jequaloneDist_new.(dest_type) = dist_out;
end
Diag.MigrationMatrix = MigMatrix;

%% 4. SAVE TO BOTH IN-MEMORY AND ON-DISK CACHES
mem_cache.hash              = hash_hex;
mem_cache.jequaloneDist_new = jequaloneDist_new;
mem_cache.Diag              = Diag;

try
    save(cache_file, 'jequaloneDist_new', 'Diag');
catch
    % Ignore disk write issues if directory is read-only
end

end

%% ========================================================================
%  LOCAL HELPER: FAST CONTENT HASH FOR INTERGENERATIONAL MATRIX CACHE
%  ========================================================================
function [cache_filepath, hash_hex] = local_get_ig_cache_path(Params, n_d, n_a, n_z, fingerprint_vec, is_5D)
CacheDir = fullfile(pwd, 'Cache_NZ_Intergen');
if ~exist(CacheDir, 'dir')
    mkdir(CacheDir);
end

state_struct = struct('Params', Params, 'n_d', n_d, 'n_a', n_a, 'n_z', n_z, ...
    'fp', round(fingerprint_vec, 6), 'is_5D', is_5D);
raw_bytes    = getByteStreamFromArray(state_struct);

stride   = max(1, floor(numel(raw_bytes) / 4096));
sampled  = double(raw_bytes(1:stride:end));
weights  = mod((1:numel(sampled))' * 1315423911, 2^31 - 1);
hash_val = mod(sum(sampled .* weights), 2^32);
hash_hex = sprintf('%08X', uint32(hash_val));

mode_str       = '4D';
if is_5D; mode_str = '5D'; end
cache_filepath = fullfile(CacheDir, sprintf('Cache_IGMat_%s_%s.mat', mode_str, hash_hex));


end
