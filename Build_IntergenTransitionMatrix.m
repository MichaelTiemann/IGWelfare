function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions)
%% CANONICAL 4-REGION + ABROAD INTERGENERATIONAL TRANSITION MATRIX
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

    if is_5D
        Dist_k = reshape(Dist_k, [n_a1, n_h, n_th, n_z1, Params.J]);

        % --- 1A. EXTRACT STAGE-1 (j_theta2) & COMPLETED STAGE-2 (j_launch) SKILL ---
        Dist_theta2 = squeeze(sum(Dist_k(:, :, :, :, j_theta2), [1, 2, 4]));
        Dist_theta2 = Dist_theta2 / max(1e-12, sum(Dist_theta2));
        Diag.MeanTheta2.(reg) = sum(Dist_theta2(:) .* th_vec(:));

        Prob_h_child = zeros(n_h, 1);
        parent_mass  = 0;
        sum_theta3   = 0;
        for ia = 1:n_a1
            for ih = 1:n_h
                for ith = 1:n_th
                    for iz = 1:n_z1
                        mass_p = Dist_k(ia, ih, ith, iz, j_launch);
                        if mass_p > 1e-12
                            parent_mass = parent_mass + mass_p;
                            theta_3_val = th_vec(ith);
                            sum_theta3  = sum_theta3 + mass_p * theta_3_val;

                            is_hardship = (a_vec(ia) < 0.05 * Q_house);
                            log_h_mean  = log(theta_3_val) - housing_crowd_pen * is_hardship;
                            trans_p     = normpdf(log(h_vec), log_h_mean, Params.sigma_hc_ig);
                            trans_p     = trans_p / max(1e-12, sum(trans_p));
                            Prob_h_child = Prob_h_child + mass_p * trans_p;
                        end
                    end
                end
            end
        end
        Prob_h_child = Prob_h_child / max(1e-12, parent_mass);
        Diag.MeanTheta3.(reg) = sum_theta3 / max(1e-12, parent_mass);

        % --- 2A. $1.6T PROPERTY BEQUEST OPERATOR (j >= Jr, 5D) ---
        Prob_a_child = zeros(n_a1, 1);
        beq_mass = 0; tot_beq = 0;
        for jr = Params.Jr : Params.J
            mort_p = 1 - Params.sj(jr);
            for ia = 1:n_a1
                for ih = 1:n_h
                    for ith = 1:n_th
                        for iz = 1:n_z1
                            m_ret = Dist_k(ia, ih, ith, iz, jr) * mort_p;
                            if m_ret > 1e-12
                                beq_mass = beq_mass + m_ret;
                                ap_idx   = min(n_a1, max(1, round(Pol_k(4, ia, ih, ith, iz, jr))));
                                estate   = (1 - Params.tau_b) * a_vec(ap_idx) + Params.YouthGrant;
                                tot_beq  = tot_beq + m_ret * estate;
                                [~, a_c_idx] = min(abs(a_vec - estate));
                                Prob_a_child(a_c_idx) = Prob_a_child(a_c_idx) + m_ret;
                            end
                        end
                    end
                end
            end
        end
        Prob_a_child = Prob_a_child / max(1e-12, beq_mass);
        Diag.MeanBequest.(reg)  = tot_beq / max(1e-12, beq_mass);
        Diag.StuntedShare.(reg) = sum(Prob_h_child(1:2));
        Diag.ThrivingShare.(reg)= sum(Prob_h_child(6:7));

        stat_z = (pi_z.(hh_type)^50)'; stat_z = stat_z(:, 1);
        NewbornDist_PreMig.(reg) = zeros(n_a1, n_h, n_th, n_z1);
        for ia = 1:n_a1
            for ih = 1:n_h
                ith_init = min(n_th, max(1, ih + 1));
                for iz = 1:n_z1
                    NewbornDist_PreMig.(reg)(ia, ih, ith_init, iz) = ...
                        Prob_a_child(ia) * Prob_h_child(ih) * stat_z(iz);
                end
            end
        end
    else
        % --- COMPACT 4D BRANCH [a, h, z, j] ---
        Dist_k = reshape(Dist_k, [n_a1, n_h, n_z1, Params.J]);
        ic_grid = d_grid.(hh_type)(end-6:end);
        Prob_h_child = zeros(n_h, 1);
        parent_mass  = 0;
        for jp = Params.j_s1_start : Params.j_s2_end
            for ia = 1:n_a1
                for ih = 1:n_h
                    for iz = 1:n_z1
                        mass_p = Dist_k(ia, ih, iz, jp);
                        if mass_p > 1e-12
                            parent_mass = parent_mass + mass_p;
                            ic_idx = min(length(ic_grid), max(1, round(Pol_k(3, ia, ih, iz, jp))));
                            ic_val = ic_grid(ic_idx);
                            is_hardship = (a_vec(ia) < 0.05 * Q_house);
                            log_h_mean  = Params.rho_hc_ig * log(h_vec(ih)) ...
                                + Params.gamma_ic * log(1 + ic_val + Params.G_ece) ...
                                - housing_crowd_pen * is_hardship;
                            trans_p = normpdf(log(h_vec), log_h_mean, Params.sigma_hc_ig);
                            trans_p = trans_p / max(1e-12, sum(trans_p));
                            Prob_h_child = Prob_h_child + mass_p * trans_p;
                        end
                    end
                end
            end
        end
        Prob_h_child = Prob_h_child / max(1e-12, parent_mass);
        Diag.MeanTheta2.(reg)   = sum(Prob_h_child .* h_vec);
        Diag.MeanTheta3.(reg)   = Diag.MeanTheta2.(reg);
        Diag.StuntedShare.(reg) = sum(Prob_h_child(1:2));
        Diag.ThrivingShare.(reg)= sum(Prob_h_child(6:7));

        Prob_a_child = zeros(n_a1, 1);
        beq_mass = 0; tot_beq = 0;
        for jr = Params.Jr : Params.J
            mort_p = 1 - Params.sj(jr);
            for ia = 1:n_a1
                for ih = 1:n_h
                    for iz = 1:n_z1
                        m_ret = Dist_k(ia, ih, iz, jr) * mort_p;
                        if m_ret > 1e-12
                            beq_mass = beq_mass + m_ret;
                            ap_idx   = min(n_a1, max(1, round(Pol_k(4, ia, ih, iz, jr))));
                            estate   = (1 - Params.tau_b) * a_vec(ap_idx) + Params.YouthGrant;
                            tot_beq  = tot_beq + m_ret * estate;
                            [~, a_c_idx] = min(abs(a_vec - estate));
                            Prob_a_child(a_c_idx) = Prob_a_child(a_c_idx) + m_ret;
                        end
                    end
                end
            end
        end
        Prob_a_child = Prob_a_child / max(1e-12, beq_mass);
        Diag.MeanBequest.(reg) = tot_beq / max(1e-12, beq_mass);

        stat_z = (pi_z.(hh_type)^50)'; stat_z = stat_z(:, 1);
        NewbornDist_PreMig.(reg) = zeros(n_a1, n_h, n_z1);
        for ia = 1:n_a1
            for ih = 1:n_h
                for iz = 1:n_z1
                    NewbornDist_PreMig.(reg)(ia, ih, iz) = Prob_a_child(ia) * Prob_h_child(ih) * stat_z(iz);
                end
            end
        end
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
