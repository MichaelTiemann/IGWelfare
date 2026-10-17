function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix_UpgradeB( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions)
%% UPGRADE B INTERGENERATIONAL TRANSITION MATRIX
% Directly extracts the distribution of the Experience Asset theta_c at:
%   - j = 4 (End of Stage 1 / First 2000 Days -> theta_2)
%   - j = 5 (End of Stage 2 / Completed Childhood -> theta_3)
% and maps completed theta_3 + Cunha et al. (2010) Stage-2 shock eta_2 into newborn adult h_1.

N_reg   = length(Regions);
n_a1    = n_a.HH_Rural(1);
n_h     = n_a.HH_Rural(2);
n_th    = n_a.HH_Rural(3);
n_z1    = n_z.HH_Rural;

a_vec   = a_grid.HH_Rural(1 : n_a1);
h_vec   = a_grid.HH_Rural(n_a1+1 : n_a1+n_h);
th_vec  = a_grid.HH_Rural(n_a1+n_h+1 : end);

NewbornDist_PreMig = struct();

for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    
    % StationaryDist dimensions with experience asset: [n_a1, n_h, n_th, n_z1, J]
    Dist_k  = StationaryDist.(hh_type);
    Pol_k   = Policy.(hh_type); % Pol_k(4, ...) is aprime index
    Q_house = Params.Q_reg.(hh_type);
    
    % --- 1. EXTRACT STAGE-1 (j=4) AND COMPLETED STAGE-2 (j=5) EXPERIENCE ASSET DISTRIBUTIONS ---
    Dist_theta2 = squeeze(sum(Dist_k(:, :, :, :, 4), [1, 2, 4]));
    Dist_theta2 = Dist_theta2 / max(1e-12, sum(Dist_theta2));
    Diag.MeanTheta2.(reg) = sum(Dist_theta2(:) .* th_vec(:));
    
    % At j = 5 (Parent age 40-44, Child age 20), theta_c holds completed Stage-2 skill theta_3!
    Prob_h_child = zeros(n_h, 1);
    parent_mass  = 0;
    sum_theta3   = 0;
    housing_crowd_pen = 0.06 * log(Q_house);
    
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
                        
                        % Project completed theta_3 onto adult human capital grid h_vec
                        % with Cunha et al. (Source 5, Table V) Stage-2 shock variance
                        trans_p = normpdf(log(h_vec), log_h_mean, Params.sigma_hc_ig);
                        trans_p = trans_p / sum(trans_p);
                        Prob_h_child = Prob_h_child + mass_p * trans_p;
                    end
                end
            end
        end
    end
    Prob_h_child = Prob_h_child / max(1e-12, parent_mass);
    Diag.MeanTheta3.(reg)   = sum_theta3 / max(1e-12, parent_mass);
    Diag.StuntedShare.(reg) = sum(Prob_h_child(1:2));
    Diag.ThrivingShare.(reg)= sum(Prob_h_child(6:7));
    
    % --- 2. $1.6T PROPERTY BEQUEST OPERATOR (j >= Jr) ---
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
                            ap_idx   = Pol_k(4, ia, ih, ith, iz, jr);
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
    Diag.MeanBequest.(reg) = tot_beq / max(1e-12, beq_mass);
    
    % Initial child skill endowment distribution theta_1 for the new generation (centered on h_1)
    stat_z = (pi_z.(hh_type)^50)'; stat_z = stat_z(:, 1);
    NewbornDist_PreMig.(reg) = zeros(n_a1, n_h, n_th, n_z1);
    for ia = 1:n_a1
        for ih = 1:n_h
            % Newborns carry their initial biological endowment ith_init proportional to ih
            ith_init = min(n_th, max(1, ih + 1));
            for iz = 1:n_z1
                NewbornDist_PreMig.(reg)(ia, ih, ith_init, iz) = ...
                    Prob_a_child(ia) * Prob_h_child(ih) * stat_z(iz);
            end
        end
    end
end

% --- 3. 3x3 SPATIAL YOUTH MIGRATION MATRIX (Rural, Urban, Auckland) ---
% [Applies the exact Gumbel logit migration operator across the 4D NewbornDist_PreMig]
jequaloneDist_new = struct();
for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    jequaloneDist_new.(hh_type) = NewbornDist_PreMig.(reg) / sum(NewbornDist_PreMig.(reg)(:));
end

end
