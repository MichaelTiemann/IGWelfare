function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions)
%% CANONICAL 4-REGION + ABROAD INTERGENERATIONAL TRANSITION MATRIX (100% VECTORIZED POST-PROCESSING)
% Supports both 5D Experience-Asset arrays [a, h, theta_c, z, j] and 4D Compact arrays [a, h, z, j],
% and adapts automatically to any period length Params.dt via j_s2_start, j_child_launch, and Jr.

N_reg   = length(Regions);
n_a1    = n_a.HH_Rural(1);
n_h     = n_a.HH_Rural(2);
is_5D   = (length(n_a.HH_Rural) >= 3);
n_z1    = n_z.HH_Rural;

a_vec   = a_grid.HH_Rural(1 : n_a1);
h_vec   = a_grid.HH_Rural(n_a1+1 : n_a1+n_h);
if is_5D
    n_th   = n_a.HH_Rural(3);
    th_vec = a_grid.HH_Rural(n_a1+n_h+1 : end);
end

j_theta2 = min(Params.J, Params.j_s2_start);     % End of Stage 1 (j=4 for dt=5; j=6 for dt=3)
j_launch = min(Params.J, Params.j_child_launch); % End of Stage 2 (j=5 for dt=5; j=8 for dt=3)

NewbornDist_PreMig = struct();

for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    Dist_k  = gather(StationaryDist.(hh_type));
    Pol_k   = gather(Policy.(hh_type));
    Q_house = Params.Q_reg.(hh_type);
    housing_crowd_pen = 0.06 * log(max(1.0, Q_house));
    is_hardship_vec   = double(a_vec < 0.05 * Q_house); % [n_a1 x 1]

    if is_5D
        Dist_k = reshape(Dist_k, [n_a1, n_h, n_th, n_z1, Params.J]);
        Pol_k  = reshape(Pol_k,  [size(Pol_k, 1), n_a1, n_h, n_th, n_z1, Params.J]);

        % --- 1A. VECTORIZED STAGE-1 (j_theta2) & COMPLETED STAGE-2 (j_launch) SKILL ---
        Dist_theta2 = squeeze(sum(Dist_k(:, :, :, :, j_theta2), [1, 2, 4]));
        Dist_theta2 = Dist_theta2 / max(1e-12, sum(Dist_theta2));
        Diag.MeanTheta2.(reg) = sum(Dist_theta2(:) .* th_vec(:));

        % Marginalize over (ih, iz) at j_launch -> [n_a1 x n_th]
        Mass_a_th   = reshape(sum(Dist_k(:, :, :, :, j_launch), [2, 4]), [n_a1, n_th]);
        parent_mass = sum(Mass_a_th, 'all');
        Diag.MeanTheta3.(reg) = sum(sum(Mass_a_th, 1)' .* th_vec(:)) / max(1e-12, parent_mass);

        % Log mean child skill for each (ia, ith) pair: [n_a1 x n_th]
        log_h_mean = log(reshape(th_vec, [1, n_th])) - housing_crowd_pen .* is_hardship_vec;

        % Evaluate normal PDF across all (h_child, ia, ith) -> [n_h x n_a1 x n_th]
        diff_log = reshape(log(h_vec), [n_h, 1, 1]) - reshape(log_h_mean, [1, n_a1, n_th]);
        trans_p  = exp(-0.5 * (diff_log ./ Params.sigma_hc_ig).^2);
        trans_p  = trans_p ./ max(1e-12, sum(trans_p, 1));

        Prob_h_child = squeeze(sum(trans_p .* reshape(Mass_a_th, [1, n_a1, n_th]), [2, 3])) / max(1e-12, parent_mass);

        % --- 2A. VECTORIZED $1.6T PROPERTY BEQUEST OPERATOR (j >= Jr, 5D) ---
        j_ret_vec = Params.Jr : Params.J;
        mort_vec  = reshape(1 - Params.sj(j_ret_vec), [1, 1, 1, 1, length(j_ret_vec)]);
        M_ret_ten = Dist_k(:, :, :, :, j_ret_vec) .* mort_vec;
        beq_mass  = sum(M_ret_ten, 'all');

        ap_idx_ten = min(n_a1, max(1, round(squeeze(Pol_k(4, :, :, :, :, j_ret_vec)))));
        estate_ten = (1 - Params.tau_b) .* a_vec(ap_idx_ten) + Params.YouthGrant;
        tot_beq    = sum(M_ret_ten .* estate_ten, 'all');

        % Map each possible aprime grid point (1..n_a1) to its nearest child asset grid index
        estate_by_ap = (1 - Params.tau_b) .* a_vec + Params.YouthGrant;
        [~, a_c_map] = min(abs(a_vec - estate_by_ap'), [], 1); % [1 x n_a1]
        a_dest_ten   = a_c_map(ap_idx_ten);

        Prob_a_child = accumarray(a_dest_ten(:), M_ret_ten(:), [n_a1, 1]) / max(1e-12, beq_mass);
        Diag.MeanBequest.(reg)  = tot_beq / max(1e-12, beq_mass);
        Diag.StuntedShare.(reg) = sum(Prob_h_child(1:2));
        Diag.ThrivingShare.(reg)= sum(Prob_h_child(6:7));

        stat_z = (pi_z.(hh_type)^50)'; stat_z = stat_z(:, 1);
        NewbornDist_PreMig.(reg) = zeros(n_a1, n_h, n_th, n_z1);
        for ih = 1:n_h
            ith_init = min(n_th, max(1, ih + 1));
            NewbornDist_PreMig.(reg)(:, ih, ith_init, :) = ...
                Prob_a_child .* Prob_h_child(ih) .* reshape(stat_z, [1, 1, 1, n_z1]);
        end

    else
        % --- COMPACT 4D BRANCH [a, h, z, j] (VECTORIZED) ---
        Dist_k  = reshape(Dist_k, [n_a1, n_h, n_z1, Params.J]);
        Pol_k   = reshape(Pol_k,  [size(Pol_k, 1), n_a1, n_h, n_z1, Params.J]);
        ic_grid = d_grid.(hh_type)(end-6 : end);

        jp_vec      = Params.j_s1_start : Params.j_s2_end;
        Mass_p_ten  = Dist_k(:, :, :, jp_vec);
        parent_mass = sum(Mass_p_ten, 'all');

        ic_idx_ten = min(length(ic_grid), max(1, round(reshape(Pol_k(3, :, :, :, jp_vec), size(Mass_p_ten)))));
        ic_val_ten = ic_grid(ic_idx_ten);

        log_h_mean = Params.rho_hc_ig .* reshape(log(h_vec), [1, n_h, 1, 1]) ...
            + Params.gamma_ic  .* log(1 + ic_val_ten + Params.G_ece) ...
            - housing_crowd_pen .* reshape(is_hardship_vec, [n_a1, 1, 1, 1]);

        diff_log = reshape(log(h_vec), [n_h, 1, 1, 1, 1]) - reshape(log_h_mean, [1, n_a1, n_h, n_z1, length(jp_vec)]);
        trans_p  = exp(-0.5 * (diff_log ./ Params.sigma_hc_ig).^2);
        trans_p  = trans_p ./ max(1e-12, sum(trans_p, 1));

        Prob_h_child = squeeze(sum(trans_p .* reshape(Mass_p_ten, [1, n_a1, n_h, n_z1, length(jp_vec)]), [2, 3, 4, 5])) / max(1e-12, parent_mass);
        Diag.MeanTheta2.(reg)   = sum(Prob_h_child .* h_vec);
        Diag.MeanTheta3.(reg)   = Diag.MeanTheta2.(reg);
        Diag.StuntedShare.(reg) = sum(Prob_h_child(1:2));
        Diag.ThrivingShare.(reg)= sum(Prob_h_child(6:7));

        j_ret_vec  = Params.Jr : Params.J;
        mort_vec   = reshape(1 - Params.sj(j_ret_vec), [1, 1, 1, length(j_ret_vec)]);
        M_ret_ten  = Dist_k(:, :, :, j_ret_vec) .* mort_vec;
        beq_mass   = sum(M_ret_ten, 'all');

        ap_idx_ten = min(n_a1, max(1, round(reshape(Pol_k(4, :, :, :, j_ret_vec), size(M_ret_ten)))));
        estate_ten = (1 - Params.tau_b) .* a_vec(ap_idx_ten) + Params.YouthGrant;
        tot_beq    = sum(M_ret_ten .* estate_ten, 'all');

        estate_by_ap = (1 - Params.tau_b) .* a_vec + Params.YouthGrant;
        [~, a_c_map] = min(abs(a_vec - estate_by_ap'), [], 1);
        a_dest_ten   = a_c_map(ap_idx_ten);

        Prob_a_child = accumarray(a_dest_ten(:), M_ret_ten(:), [n_a1, 1]) / max(1e-12, beq_mass);
        Diag.MeanBequest.(reg) = tot_beq / max(1e-12, beq_mass);

        stat_z = (pi_z.(hh_type)^50)'; stat_z = stat_z(:, 1);
        NewbornDist_PreMig.(reg) = Prob_a_child .* reshape(Prob_h_child, [1, n_h, 1]) .* reshape(stat_z, [1, 1, n_z1]);
    end
end

%% 3. STAGE 3: 4x5 DOMESTIC + ABROAD GUMBEL YOUTH MIGRATION MATRIX
kappa_4x4 = [0.00, 0.02, 0.04, 0.06;
    0.02, 0.00, 0.03, 0.05;
    0.04, 0.03, 0.00, 0.03;
    0.05, 0.04, 0.03, 0.00];
varrho_mig = 1.85;
V_mean_j1  = zeros(N_reg, 1);

for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    V_reg   = gather(V.(hh_type));
    V_j1    = V_reg(:, 1);
    V_mean_j1(r_idx) = mean(V_j1(isfinite(V_j1)));
end

V_Abroad = max(V_mean_j1) + 0.12; % Australia/OECD outside option
Pi_mig_4x5 = zeros(N_reg, N_reg + 1);
for k = 1:N_reg
    u_vec = zeros(1, N_reg + 1);
    for m = 1:N_reg
        u_vec(m) = (V_mean_j1(m) - kappa_4x4(k, m)) / varrho_mig;
    end
    u_vec(N_reg + 1) = V_Abroad / varrho_mig;
    exp_u = exp(u_vec - max(u_vec));
    Pi_mig_4x5(k, :) = exp_u / sum(exp_u);
end
Diag.MigrationMatrix_4x5 = Pi_mig_4x5;
Pi_dom = Pi_mig_4x5(:, 1:N_reg) ./ sum(Pi_mig_4x5(:, 1:N_reg), 2);
Diag.MigrationMatrix = Pi_dom;

jequaloneDist_new = struct();
for m = 1:N_reg
    reg_dest = Regions{m};
    hh_dest  = ['HH_', reg_dest];
    Dist_accum = zeros(size(NewbornDist_PreMig.(reg_dest)));
    for k = 1:N_reg
        reg_orig = Regions{k};
        Dist_accum = Dist_accum + Pi_dom(k, m) * NewbornDist_PreMig.(reg_orig);
    end
    jequaloneDist_new.(hh_dest) = Dist_accum / max(1e-12, sum(Dist_accum(:)));
    Diag.EmigRate.(reg_dest)    = Pi_mig_4x5(m, N_reg + 1);
end


end
