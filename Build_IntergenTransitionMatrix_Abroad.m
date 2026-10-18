function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix_Abroad( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions, Params_Mig)
%% BUILD_INTERGENTRANSITIONMATRIX (UPGRADED WITH 3x4 ABROAD BRAIN-DRAIN LEAKAGE)
% Links Generation t to Generation t+1 across Rural, Urban, Auckland, and Abroad:
%   Stage 1: Early-childhood skill formation Q_h (Cunha et al. / Daruich)
%   Stage 2: $1.6T Property bequest & Youth Grant transition Q_a (De Nardi / Piketty)
%   Stage 3: 3x4 Spatial & International Migration Matrix Pi_mig(k -> [Rural, Urban, Akl, Abroad])
%            with selective high-skill emigration depletion, replacement migration churn,
%            and Social Cohesion stock S_t.

if nargin < 13 || isempty(Params_Mig)
    Params_Mig.w_Abroad         = 1.32;  % Australia/OECD benchmark wage
    Params_Mig.Q_Abroad         = 2.15;  % Australia/OECD house price benchmark
    Params_Mig.kappa_emig       = 0.14;  % Fixed international moving cost
    Params_Mig.tau_home_amenity = 0.85;  % Whanau / native home-attachment premium
    Params_Mig.varrho_gumbel    = 0.45;  % Gumbel taste shock scale
    Params_Mig.Target_NetMig    = 0.025; % Stats NZ +25k/yr net migration target
    Params_Mig.nu_retention     = 0.40;  % Social cohesion elasticity wrt native retention
    Params_Mig.nu_churn         = 0.35;  % Social cohesion penalty wrt migration churn
    Params_Mig.gamma_proximity  = 0.45;  % Parental utility weight on children staying in NZ
    Params_Mig.gamma_thrive     = 0.35;  % Parental utility weight on children thriving
end

N_reg = length(Regions);
n_a1  = n_a.HH_Rural(1);
n_h   = n_a.HH_Rural(2);
n_z1  = n_z.HH_Rural;

a_vec  = a_grid.HH_Rural(1:n_a1);
h_vec  = a_grid.HH_Rural(n_a1+1:end);
ic_vec = d_grid.HH_Rural(n_d.HH_Rural(1)+n_d.HH_Rural(2)+1 : end);

NewbornDist_PreMig = struct();

%% STAGE 1 & 2: WITHIN-REGION SKILL FORMATION (Q_h) & PROPERTY INHERITANCE (Q_a)
for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];

    Dist_k  = StationaryDist.(hh_type);
    Pol_k   = Policy.(hh_type);
    Q_house = Params.Q_reg.(hh_type);

    % --- A. SKILL TRANSITION MATRIX (Parents at Fertile Ages j = 3, 4) ---
    Prob_h_child = zeros(n_h, 1);
    parent_mass  = 0;
    housing_stress_penalty = 0.08 * log(max(1.0, Q_house));

    for jf = [3, 4]
        for ia = 1:n_a1
            for ih = 1:n_h
                for iz = 1:n_z1
                    mass_p = Dist_k(ia, ih, iz, jf);
                    if mass_p > 1e-12
                        parent_mass = parent_mass + mass_p;
                        d_ic_idx    = Pol_k(3, ia, ih, iz, jf);
                        ic_val      = ic_vec(d_ic_idx);
                        h_parent    = h_vec(ih);
                        is_hardship = (a_vec(ia) < 0.05 * Q_house);

                        log_h_mean = Params.rho_hc_ig * log(h_parent) ...
                            + Params.gamma_ic * log(1 + ic_val + Params.G_ece) ...
                            - housing_stress_penalty * is_hardship;

                        trans_probs = normpdf(log(h_vec), log_h_mean, Params.sigma_hc_ig);
                        trans_probs = trans_probs / sum(trans_probs);
                        Prob_h_child = Prob_h_child + mass_p * trans_probs;
                    end
                end
            end
        end
    end
    Prob_h_child = Prob_h_child / max(1e-12, parent_mass);

    % --- B. $1.6T PROPERTY BEQUEST TRANSITION (Dying Retirees j >= Jr) ---
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
                        ap_idx       = Pol_k(4, ia, ih, iz, jr);
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

    stat_z = (pi_z.(hh_type)^50)'; stat_z = stat_z(:, 1);
    NewbornDist_PreMig.(reg) = zeros(n_a1, n_h, n_z1);
    for ia = 1:n_a1
        for ih = 1:n_h
            for iz = 1:n_z1
                NewbornDist_PreMig.(reg)(ia, ih, iz) = Prob_a_child(ia) * Prob_h_child(ih) * stat_z(iz);
            end
        end
    end

    Diag.StuntedShare.(reg)  = sum(Prob_h_child(1:2));
    Diag.ThrivingShare.(reg) = sum(Prob_h_child(6:7));
    Diag.MeanBequest.(reg)   = total_bequest_val / max(1e-12, bequest_mass);
end

%% STAGE 3: 3x4 DOMESTIC + ABROAD MIGRATION MATRIX & SELECTIVE SKILL DEPLETION
kappa_mat = [0.00, 0.12, 0.25;  % Rural    -> [Rural, Urban, Auckland]
    0.10, 0.00, 0.18;  % Urban    -> [Rural, Urban, Auckland]
    0.08, 0.08, 0.00]; % Auckland -> [Rural, Urban, Auckland]

for r_dest = 1:N_reg
    jequaloneDist_new.(['HH_', Regions{r_dest}]) = zeros(n_a1, n_h, n_z1);
end

MigMatrix_3x4     = zeros(N_reg, N_reg + 1); % Cols: [Rural, Urban, Auckland, Abroad]
Emig_By_Skill_Num = zeros(n_h, 1);
Emig_By_Skill_Den = zeros(n_h, 1);
pop_weights       = Params.PTypeWeights(1:3) / sum(Params.PTypeWeights(1:3));

for r_orig = 1:N_reg
    orig_reg  = Regions{r_orig};
    Dist_orig = NewbornDist_PreMig.(orig_reg);
    w_k       = pop_weights(r_orig);

    for ia = 1:n_a1
        for ih = 1:n_h
            for iz = 1:n_z1
                mass_youth = Dist_orig(ia, ih, iz);
                if mass_youth > 1e-12
                    % 1. Domestic Destination Values V_{k'}(a_1 - kappa, h_1, z_1, j=1)
                    V_dest = -1e4 * ones(1, N_reg);
                    for r_dest = 1:N_reg
                        dest_type = ['HH_', Regions{r_dest}];
                        net_a_after_move = a_vec(ia) - kappa_mat(r_orig, r_dest);
                        if net_a_after_move >= 0
                            [~, ia_dest] = min(abs(a_vec - net_a_after_move));
                            V_dest(r_dest) = V.(dest_type)(ia_dest, ih, iz, 1);
                        end
                    end

                    % 2. Outside Option Value: Emigrating Abroad (Australia/OECD, Col 4)
                    net_a_abroad = a_vec(ia) - Params_Mig.kappa_emig;
                    if net_a_abroad >= 0
                        [~, ia_ab] = min(abs(a_vec - net_a_abroad));
                        wage_gain_abroad = (Params_Mig.w_Abroad / Params.w_reg.HH_Auckland) ...
                            * (0.85 + 0.25 * (h_vec(ih) / h_vec(4)));
                        housing_relief   = (Params.Q_reg.HH_Auckland / Params_Mig.Q_Abroad)^0.20;
                        V_Akl_ref = V.HH_Auckland(ia_ab, ih, iz, 1);
                        V_Abroad  = (V_Akl_ref / (wage_gain_abroad * housing_relief)) ...
                            - Params_Mig.tau_home_amenity;
                    else
                        V_Abroad = -1e4;
                    end

                    % 3. Gumbel Choice Probabilities across [Rural, Urban, Auckland, Abroad]
                    V_all = [V_dest, V_Abroad];
                    max_V = max(V_all);
                    exp_V = exp((V_all - max_V) / Params_Mig.varrho_gumbel);
                    prob_4 = exp_V / sum(exp_V);

                    MigMatrix_3x4(r_orig, :) = MigMatrix_3x4(r_orig, :) + mass_youth * prob_4;

                    prob_emig = prob_4(4);
                    Emig_By_Skill_Num(ih) = Emig_By_Skill_Num(ih) + w_k * mass_youth * prob_emig;
                    Emig_By_Skill_Den(ih) = Emig_By_Skill_Den(ih) + w_k * mass_youth;

                    % 4. Allocate Retained Domestic Youth + Replacement Migrants to jequaloneDist_new
                    % Retained native youth carry their exact (a_1, h_1, z_1); replacement immigrants
                    % enter around median skill tier (ih_rep = 3..4) with lower local social capital
                    for r_dest = 1:N_reg
                        dest_type = ['HH_', Regions{r_dest}];
                        net_a_after_move = max(0, a_vec(ia) - kappa_mat(r_orig, r_dest));
                        [~, ia_dest] = min(abs(a_vec - net_a_after_move));

                        % Retained native mass moving to r_dest
                        jequaloneDist_new.(dest_type)(ia_dest, ih, iz) = ...
                            jequaloneDist_new.(dest_type)(ia_dest, ih, iz) + mass_youth * prob_4(r_dest);

                        % Replacement immigrant inflow offsetting native brain drain in r_dest
                        ih_rep = min(n_h, max(1, round(0.65 * ih + 0.35 * 3)));
                        jequaloneDist_new.(dest_type)(ia_dest, ih_rep, iz) = ...
                            jequaloneDist_new.(dest_type)(ia_dest, ih_rep, iz) + ...
                            mass_youth * prob_emig * pop_weights(r_dest);
                    end
                end
            end
        end
    end
    MigMatrix_3x4(r_orig, :) = MigMatrix_3x4(r_orig, :) / max(1e-12, sum(MigMatrix_3x4(r_orig, :)));
end

% Normalize each region's post-migration newborn distribution to sum to 1
for r_dest = 1:N_reg
    dest_type = ['HH_', Regions{r_dest}];
    jequaloneDist_new.(dest_type) = jequaloneDist_new.(dest_type) / sum(jequaloneDist_new.(dest_type)(:));
end

% Store 3x3 conditional domestic matrix and 3x4 international leakage diagnostics
Diag.MigrationMatrix_3x4 = MigMatrix_3x4;
Diag.MigrationMatrix     = MigMatrix_3x4(:, 1:3) ./ sum(MigMatrix_3x4(:, 1:3), 2);
Diag.Emig_By_Region      = MigMatrix_3x4(:, 4)';
Diag.Emig_By_SkillTier   = Emig_By_Skill_Num ./ max(1e-12, Emig_By_Skill_Den);
Diag.EmigRate_Youth      = sum(Emig_By_Skill_Num) / max(1e-12, sum(Emig_By_Skill_Den));
Diag.HighSkill_EmigShare = sum(Emig_By_Skill_Num(5:7)) / max(1e-12, sum(Emig_By_Skill_Num));

% Compute Replacement Migration Churn, Social Cohesion S_t, & Parental Relational CE %
Diag.ReplacementImmig_Rate = Params_Mig.Target_NetMig + 0.35 * Diag.EmigRate_Youth;
Diag.Churn_Rate            = 0.35 * Diag.EmigRate_Youth + Diag.ReplacementImmig_Rate;
raw_S = ((1 - Diag.EmigRate_Youth)^Params_Mig.nu_retention) ...
    * ((1 + Diag.Churn_Rate)^(-Params_Mig.nu_churn));
Diag.SocialCohesion_Index  = 100.0 * (raw_S / 0.885);

nat_stunted = pop_weights(1)*Diag.StuntedShare.Rural + ...
    pop_weights(2)*Diag.StuntedShare.Urban + ...
    pop_weights(3)*Diag.StuntedShare.Auckland;
rel_util = Params_Mig.gamma_thrive * log(max(0.01, 1 - nat_stunted)) ...
    + Params_Mig.gamma_proximity * log(max(0.01, 1 - Diag.EmigRate_Youth));
Diag.ParentalRelational_CE = 100 * (exp(rel_util + 0.22) - 1);

end
