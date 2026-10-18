function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix_UpgradeB( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions)
%% VECTORIZED UPGRADE B INTERGENERATIONAL TRANSITION MATRIX (4 REGIONS)
% File: Build_IntergenTransitionMatrix_UpgradeB.m
% Gathers GPU arrays once upfront and uses vectorized tensor contractions across
% [n_a1, n_h, n_th, n_z1] (~500x faster than element-wise gpuArray scalar loops).

N_reg  = length(Regions);
n_a1   = n_a.HH_Rural(1);
n_h    = n_a.HH_Rural(2);
n_th   = n_a.HH_Rural(3);
n_z1   = n_z.HH_Rural;

a_vec  = gather(a_grid.HH_Rural(1 : n_a1));
h_vec  = gather(a_grid.HH_Rural(n_a1+1 : n_a1+n_h));
th_vec = gather(a_grid.HH_Rural(n_a1+n_h+1 : end));

NewbornDist_PreMig = struct();
Diag               = struct();

%% STAGE 1 & 2: VECTORIZED SKILL FORMATION (theta_3 -> h_1) & BEQUEST INHERITANCE
for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    
    % Gather once to CPU to avoid costly element-wise gpuArray indexing
    Dist_k  = gather(StationaryDist.(hh_type)); % [n_a1, n_h, n_th, n_z1, J]
    Pol_k   = gather(Policy.(hh_type));         % [4, n_a1, n_h, n_th, n_z1, J]
    Q_house = Params.Q_reg.(hh_type);
    
    % --- 1. STAGE-1 (j=4) AND COMPLETED STAGE-2 (j=5) EXPERIENCE ASSET DISTRIBUTIONS ---
    Dist_theta2 = squeeze(sum(Dist_k(:, :, :, :, 4), [1, 2, 4]));
    Dist_theta2 = Dist_theta2 / max(1e-12, sum(Dist_theta2));
    Diag.MeanTheta2.(reg) = sum(Dist_theta2(:) .* th_vec(:));
    
    % Vectorized over (ih, iz) at j = 5: marginalize parent mass into [n_a1, n_th]
    Dist_j5_a_th = squeeze(sum(Dist_k(:, :, :, :, 5), [2, 4])); % [n_a1, n_th]
    parent_mass  = sum(Dist_j5_a_th(:));
    
    % Mean completed skill theta_3
    mass_by_th = sum(Dist_j5_a_th, 1)'; % [n_th, 1]
    Diag.MeanTheta3.(reg) = sum(mass_by_th .* th_vec) / max(1e-12, parent_mass);
    
    % Vectorized Gaussian skill transition from (ia, ith) -> child h_vec (n_h x 1)
    housing_crowd_pen = 0.06 * log(max(1.0, Q_house));
    is_hardship_vec   = double(a_vec < 0.05 * Q_house); % [n_a1, 1]
    
    % log_h_mean_mat is [n_a1, n_th]
    log_h_mean_mat = log(th_vec') - housing_crowd_pen * is_hardship_vec;
    
    % Evaluate normal PDF on 3D grid [n_h, n_a1, n_th]
    log_h_grid = reshape(log(h_vec), [n_h, 1, 1]);
    mean_grid  = reshape(log_h_mean_mat, [1, n_a1, n_th]);
    trans_p    = normpdf(log_h_grid, mean_grid, Params.sigma_hc_ig);
    trans_p    = trans_p ./ max(1e-12, sum(trans_p, 1)); % Normalize over n_h
    
    % Weight by Dist_j5_a_th [1, n_a1, n_th] and sum over (ia, ith)
    Prob_h_child = squeeze(sum(trans_p .* reshape(Dist_j5_a_th, [1, n_a1, n_th]), [2, 3]));
    Prob_h_child = Prob_h_child / max(1e-12, parent_mass);
    
    Diag.StuntedShare.(reg)  = sum(Prob_h_child(1:2));
    Diag.ThrivingShare.(reg) = sum(Prob_h_child(max(1, end-1):end));
    
    % --- 2. VECTORIZED $1.6T PROPERTY BEQUEST OPERATOR (j >= Jr) ---
    ret_ages   = Params.Jr : Params.J;
    mort_probs = reshape(1 - Params.sj(ret_ages), [1, 1, 1, 1, length(ret_ages)]);
    
    % Dying retiree mass across all retirement states: [n_a1, n_h, n_th, n_z1, N_ret]
    m_ret_tensor = Dist_k(:, :, :, :, ret_ages) .* mort_probs;
    ap_idx_tensor= min(n_a1, max(1, Pol_k(4, :, :, :, :, ret_ages)));
    ap_idx_flat  = ap_idx_tensor(:);
    m_ret_flat   = m_ret_tensor(:);
    
    beq_mass     = sum(m_ret_flat);
    estates_flat = (1 - Params.tau_b) * a_vec(ap_idx_flat) + Params.YouthGrant;
    tot_beq      = sum(m_ret_flat .* estates_flat);
    
    % Map each unique aprime index (1..n_a1) to nearest child asset grid index once
    possible_estates = (1 - Params.tau_b) * a_vec + Params.YouthGrant;
    [~, map_ap_to_ac] = min(abs(a_vec' - possible_estates), [], 2); % [n_a1, 1]
    child_a_idx_flat  = map_ap_to_ac(ap_idx_flat);
    
    Prob_a_child = accumarray(child_a_idx_flat, m_ret_flat, [n_a1, 1]);
    Prob_a_child = Prob_a_child / max(1e-12, beq_mass);
    Diag.MeanBequest.(reg) = tot_beq / max(1e-12, beq_mass);
    
    % Stationary initial productivity draw z_1 in region k
    pi_z_cpu = gather(pi_z.(hh_type));
    stat_z   = (pi_z_cpu^50)';
    stat_z   = stat_z(:, 1);
    
    % Pre-migration Newborn Distribution [n_a1, n_h, n_th, n_z1]
    NewbornDist_PreMig.(reg) = zeros(n_a1, n_h, n_th, n_z1);
    for ih = 1:n_h
        ith_init = min(n_th, max(1, ih + 1));
        % Outer product of Prob_a_child [n_a1, 1] and stat_z' [1, n_z1] scaled by Prob_h_child(ih)
        NewbornDist_PreMig.(reg)(:, ih, ith_init, :) = ...
            Prob_h_child(ih) * (Prob_a_child * stat_z');
    end
end

%% STAGE 3: VECTORIZED 4x4 SPATIAL YOUTH MIGRATION MATRIX
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

% Gather period-1 value functions V_1 [n_a1, n_h, n_th, n_z1] once per destination
V1_dest_cell = cell(N_reg, 1);
jequaloneDist_new = struct();
for r_dest = 1:N_reg
    dest_type = ['HH_', Regions{r_dest}];
    V1_dest_cell{r_dest}         = gather(V.(dest_type)(:, :, :, :, 1));
    jequaloneDist_new.(dest_type)= zeros(n_a1, n_h, n_th, n_z1);
end

for r_orig = 1:N_reg
    orig_reg  = Regions{r_orig};
    Dist_orig = NewbornDist_PreMig.(orig_reg); % [n_a1, n_h, n_th, n_z1]
    
    % Precompute destination asset indices ia_d(ia, r_dest) and feasibility for all ia = 1..n_a1
    ia_dest_mat = zeros(n_a1, N_reg);
    feas_mat    = false(n_a1, N_reg);
    V_dest_all  = -1e4 * ones(n_a1, n_h, n_th, n_z1, N_reg);
    
    for r_dest = 1:N_reg
        net_a_vec = a_vec - kappa_mat(r_orig, r_dest);
        feas_mat(:, r_dest) = (net_a_vec >= 0);
        [~, ia_dest_mat(:, r_dest)] = min(abs(a_vec' - max(0, net_a_vec)), [], 2);
        
        % Slice V1 at shifted asset indices for feasible ia
        V1_d = V1_dest_cell{r_dest}(ia_dest_mat(:, r_dest), :, :, :);
        feas_mask_4d = repmat(feas_mat(:, r_dest), [1, n_h, n_th, n_z1]);
        V_slice = -1e4 * ones(n_a1, n_h, n_th, n_z1);
        V_slice(feas_mask_4d) = V1_d(feas_mask_4d);
        V_dest_all(:, :, :, :, r_dest) = V_slice;
    end
    
    % Vectorized Gumbel logit probabilities across all states simultaneously
    max_V     = max(V_dest_all, [], 5);
    exp_V     = exp((V_dest_all - max_V) / varrho_gumbel);
    prob_move = exp_V ./ sum(exp_V, 5); % [n_a1, n_h, n_th, n_z1, N_reg]
    
    for r_dest = 1:N_reg
        dest_type = ['HH_', Regions{r_dest}];
        flow_4d   = Dist_orig .* prob_move(:, :, :, :, r_dest);
        MigMatrix(r_orig, r_dest) = sum(flow_4d(:));
        
        % Accumulate migrating youth into destination asset index ia_dest_mat(:, r_dest)
        ia_d_vec = ia_dest_mat(:, r_dest);
        for ia = 1:n_a1
            ia_target = ia_d_vec(ia);
            jequaloneDist_new.(dest_type)(ia_target, :, :, :) = ...
                jequaloneDist_new.(dest_type)(ia_target, :, :, :) + flow_4d(ia, :, :, :);
        end
    end
    MigMatrix(r_orig, :) = MigMatrix(r_orig, :) / max(1e-12, sum(MigMatrix(r_orig, :)));
end

for r_dest = 1:N_reg
    dest_type = ['HH_', Regions{r_dest}];
    jequaloneDist_new.(dest_type) = jequaloneDist_new.(dest_type) / sum(jequaloneDist_new.(dest_type)(:));
end
Diag.MigrationMatrix = MigMatrix;

end