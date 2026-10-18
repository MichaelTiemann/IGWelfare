function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions)
%% BUILD_INTERGENTRANSITIONMATRIX (4-REGION COMPACT 4D VERSION)
% File: Build_IntergenTransitionMatrix.m
% Regions (N_reg = 4): {'Rural', 'Small', 'Large', 'Auckland'}
% Implements the 3 coupled transition operators linking Generation t to Generation t+1:
%   Stage 1 (Heckman / Cunha et al. Source 2 / Daruich Source 16):
%       Parental investment ic(a_p, h_p, z_p, k) + Public ECE G_ece -> Child Adult Skill h_1
%   Stage 2 (De Nardi Source 11 / Piketty & Saez Source 12):
%       Retiree property estates (1 - tau_b)*a'_j(k) + Youth Grant E -> Child Initial Wealth a_1
%   Stage 3 (Labrousse & Perdereau Source 17):
%       4x4 Spatial Migration Matrix Pi_mig(k -> k' | a_1, h_1, z_1) across
%       Rural, Small, Large, and Auckland

N_reg  = length(Regions);
n_a1   = n_a.HH_Rural(1);
n_h    = n_a.HH_Rural(2);
n_z1   = n_z.HH_Rural;

a_vec  = a_grid.HH_Rural(1 : n_a1);
h_vec  = a_grid.HH_Rural(n_a1+1 : n_a1+n_h);
ic_vec = d_grid.HH_Rural(n_d.HH_Rural(1)+n_d.HH_Rural(2)+1 : end);

% Fallback defaults if called directly without compact projection parameters
if ~isfield(Params, 'G_ece') && isfield(Params, 'G_ece_stage1')
    Params.G_ece = Params.G_ece_stage1;
end
if ~isfield(Params, 'rho_hc_ig'); Params.rho_hc_ig = 0.40; end
if ~isfield(Params, 'gamma_ic');  Params.gamma_ic  = 0.35; end

NewbornDist_PreMig = struct();

%% STAGE 1 & 2: WITHIN-REGION SKILL FORMATION (Q_h) & PROPERTY INHERITANCE (Q_a)
for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    
    Dist_k  = StationaryDist.(hh_type); % Dimensions: [n_a1, n_h, n_z1, J]
    Pol_k   = Policy.(hh_type);         % Dimensions: [5, n_a1, n_h, n_z1, J]
    Q_house = Params.Q_reg.(hh_type);
    
    % --- A. SKILL TRANSITION MATRIX: Parents at Fertile Ages j = 3, 4 (Ages 30-39) ---
    Prob_h_child = zeros(n_h, 1);
    parent_mass  = 0;
    
    % Crowding / housing stress penalty in high-price regions for low-asset renters
    housing_stress_penalty = 0.08 * log(max(1.0, Q_house));
    
    for jf = [3, 4]
        for ia = 1:n_a1
            for ih = 1:n_h
                for iz = 1:n_z1
                    mass_p = Dist_k(ia, ih, iz, jf);
                    if mass_p > 1e-12
                        parent_mass = parent_mass + mass_p;
                        
                        % Extract parent's optimal child investment choice ic (d3)
                        d_ic_idx = min(length(ic_vec), max(1, Pol_k(3, ia, ih, iz, jf)));
                        ic_val   = ic_vec(d_ic_idx);
                        h_parent = h_vec(ih);
                        
                        % Low-asset families in expensive housing markets suffer crowding penalty
                        is_hardship = (a_vec(ia) < 0.05 * Q_house);
                        
                        % Cunha, Heckman, Schennach (Source 2) & Daruich (Source 16) Skill Anchoring:
                        log_h_mean = Params.rho_hc_ig * log(h_parent) ...
                                   + Params.gamma_ic * log(1 + ic_val + Params.G_ece) ...
                                   - housing_stress_penalty * is_hardship;
                        
                        % Project continuous log_h_mean onto discrete h_vec grid
                        trans_probs = normpdf(log(h_vec), log_h_mean, Params.sigma_hc_ig);
                        trans_probs = trans_probs / sum(trans_probs);
                        
                        Prob_h_child = Prob_h_child + mass_p * trans_probs;
                    end
                end
            end
        end
    end
    Prob_h_child = Prob_h_child / max(1e-12, parent_mass);
    
    % --- B. $1.6T PROPERTY BEQUEST TRANSITION (De Nardi Source 11): Dying Retirees j >= Jr ---
    Prob_a_child      = zeros(n_a1, 1);
    bequest_mass      = 0;
    total_bequest_val = 0;
    
    for jr = Params.Jr : Params.J
        mort_prob = 1 - Params.sj(jr);
        for ia = 1:n_a1
            for ih = 1:n_h
                for iz = 1:n_z1
                    mass_ret = Dist_k(ia, ih, iz, jr) * mort_prob;
                    if mass_ret > 1e-12
                        bequest_mass = bequest_mass + mass_ret;
                        ap_idx       = min(n_a1, max(1, Pol_k(4, ia, ih, iz, jr)));
                        estate_net   = (1 - Params.tau_b) * a_vec(ap_idx) + Params.YouthGrant;
                        total_bequest_val = total_bequest_val + mass_ret * estate_net;
                        
                        [~, a_child_idx] = min(abs(a_vec - estate_net));
                        Prob_a_child(a_child_idx) = Prob_a_child(a_child_idx) + mass_ret;
                    end
                end
            end
        end
    end
    Prob_a_child = Prob_a_child / max(1e-12, bequest_mass);
    
    % Stationary initial productivity draw z_1 in region k
    stat_z = (pi_z.(hh_type)^50)';
    stat_z = stat_z(:, 1);
    
    % Combine into Pre-Migration Newborn Distribution for Region k: [n_a1, n_h, n_z1]
    NewbornDist_PreMig.(reg) = zeros(n_a1, n_h, n_z1);
    for ia = 1:n_a1
        for ih = 1:n_h
            for iz = 1:n_z1
                NewbornDist_PreMig.(reg)(ia, ih, iz) = Prob_a_child(ia) * Prob_h_child(ih) * stat_z(iz);
            end
        end
    end
    
    % Store region-specific diagnostics
    Diag.StuntedShare.(reg)  = sum(Prob_h_child(1:2)); % Lowest 2 human capital tiers
    Diag.ThrivingShare.(reg) = sum(Prob_h_child(max(1, end-1):end)); % Top 2 tiers
    Diag.MeanBequest.(reg)   = total_bequest_val / max(1e-12, bequest_mass);
end

%% STAGE 3: 4x4 SPATIAL MIGRATION MATRIX (Rural, Small, Large, Auckland)
% Fixed 5-yr migration cost matrix kappa_mat(origin, destination)
% Moving into Large metros and Auckland requires overcoming higher housing/deposit barriers
if N_reg == 4
    kappa_mat = [ ...
        0.00, 0.08, 0.15, 0.28;  % From Rural    -> [Rural, Small, Large, Auckland]
        0.07, 0.00, 0.12, 0.24;  % From Small    -> [Rural, Small, Large, Auckland]
        0.09, 0.07, 0.00, 0.16;  % From Large    -> [Rural, Small, Large, Auckland]
        0.08, 0.07, 0.06, 0.00]; % From Auckland -> [Rural, Small, Large, Auckland]
else
    % Automatic fallback if N_reg == 3
    kappa_mat = [0.00, 0.12, 0.25; 0.10, 0.00, 0.18; 0.08, 0.08, 0.00];
end
varrho_gumbel = 0.45;

for r_dest = 1:N_reg
    jequaloneDist_new.(['HH_', Regions{r_dest}]) = zeros(n_a1, n_h, n_z1);
end
MigMatrix = zeros(N_reg, N_reg);

for r_orig = 1:N_reg
    orig_reg  = Regions{r_orig};
    Dist_orig = NewbornDist_PreMig.(orig_reg);
    
    for ia = 1:n_a1
        for ih = 1:n_h
            for iz = 1:n_z1
                mass_youth = Dist_orig(ia, ih, iz);
                if mass_youth > 1e-12
                    % Evaluate young adult's value V_1(a_1 - kappa, h_1, z_1) in each destination k'
                    V_dest = -1e4 * ones(1, N_reg);
                    for r_dest = 1:N_reg
                        dest_type = ['HH_', Regions{r_dest}];
                        net_a_after_move = a_vec(ia) - kappa_mat(r_orig, r_dest);
                        if net_a_after_move >= 0
                            [~, ia_dest] = min(abs(a_vec - net_a_after_move));
                            V_dest(r_dest) = V.(dest_type)(ia_dest, ih, iz, 1);
                        end
                    end
                    
                    % Closed-form Gumbel logit probabilities
                    max_V     = max(V_dest);
                    exp_V     = exp((V_dest - max_V) / varrho_gumbel);
                    prob_move = exp_V / sum(exp_V);
                    
                    MigMatrix(r_orig, :) = MigMatrix(r_orig, :) + mass_youth * prob_move;
                    
                    % Allocate migrating youth to destination jequaloneDist_new
                    for r_dest = 1:N_reg
                        dest_type = ['HH_', Regions{r_dest}];
                        net_a_after_move = max(0, a_vec(ia) - kappa_mat(r_orig, r_dest));
                        [~, ia_dest] = min(abs(a_vec - net_a_after_move));
                        jequaloneDist_new.(dest_type)(ia_dest, ih, iz) = ...
                            jequaloneDist_new.(dest_type)(ia_dest, ih, iz) + mass_youth * prob_move(r_dest);
                    end
                end
            end
        end
    end
    MigMatrix(r_orig, :) = MigMatrix(r_orig, :) / max(1e-12, sum(MigMatrix(r_orig, :)));
end

% Normalize each region's newborn distribution to sum to 1
for r_dest = 1:N_reg
    dest_type = ['HH_', Regions{r_dest}];
    jequaloneDist_new.(dest_type) = jequaloneDist_new.(dest_type) / sum(jequaloneDist_new.(dest_type)(:));
end
Diag.MigrationMatrix = MigMatrix;

end
