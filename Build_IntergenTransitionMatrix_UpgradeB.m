function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix_UpgradeB( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions, vfoptions)
%% UPGRADE B INTERGENERATIONAL TRANSITION MATRIX (4 REGIONS: RURAL, SMALL, LARGE, AUCKLAND)
% File: Build_IntergenTransitionMatrix_UpgradeB.m
% Directly extracts the distribution of the Experience Asset theta_c at:
%   - j = 4 (End of Stage 1 / First 2000 Days -> theta_2)
%   - j = 5 (End of Stage 2 / Completed Childhood -> theta_3)
% maps completed theta_3 into newborn adult h_1, maps dying retiree estates (j >= Jr)
% into newborn a_1, and applies the 4x4 Spatial Youth Migration Matrix across Regions.

N_reg  = length(Regions);
n_a1   = n_a.HH_Rural(1);
n_h    = n_a.HH_Rural(2);
n_th   = n_a.HH_Rural(3);
n_z1   = n_z.HH_Rural;

a_vec  = a_grid.HH_Rural(1 : n_a1);
h_vec  = a_grid.HH_Rural(n_a1+1 : n_a1+n_h);
th_vec = a_grid.HH_Rural(n_a1+n_h+1 : end);

NewbornDist_PreMig = struct();

%% STAGE 1 & 2: COMPLETED CHILD EXPERIENCE ASSET (theta_3) & $1.6T ESTATE INHERITANCE
for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    if vfoptions.verbose==1
        fprintf("Building Intergen Transition Matrix for region %s \n", reg);
    end
    
    % StationaryDist dimensions with experience asset: [n_a1, n_h, n_th, n_z1, J]
    Dist_k  = StationaryDist.(hh_type);
    Pol_k   = Policy.(hh_type); % Pol_k(4, ...) is aprime index
    Q_house = Params.Q_reg.(hh_type);
    
    % --- 1. EXTRACT STAGE-1 (j=4) AND COMPLETED STAGE-2 (j=5) EXPERIENCE ASSET DISTRIBUTIONS ---
    Dist_theta2 = squeeze(sum(Dist_k(:, :, :, :, 4), [1, 2, 4]));
    Dist_theta2 = Dist_theta2 / max(1e-12, sum(Dist_theta2));
    Diag.MeanTheta2.(reg) = sum(Dist_theta2(:) .* th_vec(:));
    
    Prob_h_child      = zeros(n_h, 1);
    parent_mass       = 0;
    sum_theta3        = 0;
    housing_crowd_pen = 0.06 * log(max(1.0, Q_house));
    
    for ia = 1:n_a1
        for ih = 1:n_h
            for ith = 1:n_th
                for iz = 1:n_z1
                    mass_p = Dist_k(ia, ih, ith, iz, 5);
                    if mass_p > 1e-12
                        parent_mass = parent_mass + mass_p;
                        theta_3_val = th_vec(ith);
                        sum_theta3  = sum_theta3 + mass_p * theta_3_val;
                        
                        is_hardship = (a_vec(ia) < 0.05 * Q_house);
                        log_h_mean  = log(theta_3_val) - housing_crowd_pen * is_hardship;
                        
                        trans_p      = normpdf(log(h_vec), log_h_mean, Params.sigma_hc_ig);
                        trans_p      = trans_p / sum(trans_p);
                        Prob_h_child = Prob_h_child + mass_p * trans_p;
                    end
                end
            end
        end
    end
    Prob_h_child            = Prob_h_child / max(1e-12, parent_mass);
    Diag.MeanTheta3.(reg)   = sum_theta3 / max(1e-12, parent_mass);
    Diag.StuntedShare.(reg) = sum(Prob_h_child(1:2));
    Diag.ThrivingShare.(reg)= sum(Prob_h_child(max(1, end-1):end));
    
    % --- 2. $1.6T PROPERTY BEQUEST OPERATOR (j >= Jr) ---
    Prob_a_child = zeros(n_a1, 1);
    beq_mass     = 0;
    tot_beq      = 0;
    for jr = Params.Jr : Params.J
        mort_p = 1 - Params.sj(jr);
        for ia = 1:n_a1
            for ih = 1:n_h
                for ith = 1:n_th
                    for iz = 1:n_z1
                        m_ret = Dist_k(ia, ih, ith, iz, jr) * mort_p;
                        if m_ret > 1e-12
                            beq_mass = beq_mass + m_ret;
                            ap_idx   = min(n_a1, max(1, Pol_k(4, ia, ih, ith, iz, jr)));
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
    Prob_a_child           = Prob_a_child / max(1e-12, beq_mass);
    Diag.MeanBequest.(reg) = tot_beq / max(1e-12, beq_mass);
    
    stat_z = (pi_z.(hh_type)^50)';
    stat_z = stat_z(:, 1);
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
end

%% STAGE 3: 4x4 SPATIAL YOUTH MIGRATION MATRIX (Rural, Small, Large, Auckland)
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

for r_orig = 1:N_reg
    orig_reg  = Regions{r_orig};
    Dist_orig = NewbornDist_PreMig.(orig_reg);
    
    for ia = 1:n_a1
        for ih = 1:n_h
            for ith = 1:n_th
                for iz = 1:n_z1
                    mass_youth = Dist_orig(ia, ih, ith, iz);
                    if mass_youth > 1e-12
                        V_dest = -1e4 * ones(1, N_reg);
                        for r_dest = 1:N_reg
                            dest_type = ['HH_', Regions{r_dest}];
                            net_a = a_vec(ia) - kappa_mat(r_orig, r_dest);
                            if net_a >= 0
                                [~, ia_d] = min(abs(a_vec - net_a));
                                V_dest(r_dest) = V.(dest_type)(ia_d, ih, ith, iz, 1);
                            end
                        end
                        
                        max_V     = max(V_dest);
                        exp_V     = exp((V_dest - max_V) / varrho_gumbel);
                        prob_move = exp_V / sum(exp_V);
                        
                        MigMatrix(r_orig, :) = MigMatrix(r_orig, :) + mass_youth * prob_move;
                        
                        for r_dest = 1:N_reg
                            dest_type = ['HH_', Regions{r_dest}];
                            net_a = max(0, a_vec(ia) - kappa_mat(r_orig, r_dest));
                            [~, ia_d] = min(abs(a_vec - net_a));
                            jequaloneDist_new.(dest_type)(ia_d, ih, ith, iz) = ...
                                jequaloneDist_new.(dest_type)(ia_d, ih, ith, iz) + mass_youth * prob_move(r_dest);
                        end
                    end
                end
            end
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
