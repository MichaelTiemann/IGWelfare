%% FERTILITYBARGAINING_MODULE.M
% Integrates Endogenous Fertility & Intra-Household Bargaining into the 3-Region NZ OLG Model:
%   1. Doepke, Hannusch, Kindermann & Tertilt (Source 9, Eq 17-18):
%      Cooperative bargaining with maternal/paternal childcare cost share chi_f, chi_m
%      and commitment vs limited-commitment fertility surplus (nu_m + nu_f >= w_hat * phi)
%   2. Cao & Li (Source 10, Prop 6-7 & App 3):
%      Hyperbolic discounting (beta_hyp < 1) -> n^t = n^c * (beta_hyp)^(1/epsilon)
%   3. de la Croix & Doepke (2003, Source 5):
%      Differential fertility by parent human capital h -> composition effect on newborn h_1
%   4. Endogenous Macro Feedback to Treasury Demographic Matrix (Source 3) & NZ Super Tax

% Prerequisite: Run NZ_3Region_Master_UpgradeB.m so baseline workspace is loaded.

%% 1. ADD FERTILITY & BARGAINING PARAMETERS TO PARAMS
% Intra-Household Bargaining Parameters (Source 9, Eq 17-18)
Params.nu_m          = 0.42;  % Male partner preference for children
Params.nu_f          = 0.42;  % Female partner preference for children
Params.gender_gap_wf = 0.88;  % Relative female wage wf / wm in couple
Params.chi_f_share   = 0.72;  % Share of unsubsidized childcare time borne by mother (chi_f > chi_m)
Params.commit_degree = 0.65;  % Degree of intra-household intertemporal commitment (1 = full, 0 = none)

% Cao & Li (Source 10) Hyperbolic Discounting & Quantity-Quality Elasticity Parameters
Params.beta_hyp      = 0.82;  % Present-bias hyperbolic factor beta in [0, 1] (Source 10)
Params.eps_fert      = 0.65;  % Curvature epsilon in altruism function Phi(n) = n^(1-eps)/(1-eps)
Params.x_time_child  = 0.14;  % Per-child parental time cost fraction x (Source 5 & Source 10)
Params.phi_space_kid = 0.08;  % Additional housing space cost per child (penalizes Auckland renters!)

%% 2. COMPARE 4 FERTILITY & CHILDCARE POLICY SCENARIOS ACROSS RURAL, URBAN, AUCKLAND
FertScenarios = {'1_Baseline_StatusQuo', ...
                 '2_Hyperbolic_NoCommit (beta=0.75, No ECE)', ...
                 '3_Barnardos_ECE_Bargaining_Relief (G_ece1 Up -> Lowers chi_f)', ...
                 '4_Full_Package (ECE1 + Housing Cool + Commit)'};
N_scen = length(FertScenarios);

TFR_By_Region         = zeros(N_scen, 3); % Total Fertility Rate (children per woman/couple)
DiffFert_Q1_minus_Q5  = zeros(N_scen, 3); % de la Croix & Doepke (2003) Differential Fertility gap
StuntedShare_EndoFert = zeros(N_scen, 3); % Newborn stunted share including differential fertility weight!
DepRatio_65Plus_Endo  = zeros(N_scen, 1); % Resulting steady-state 65+ Dependency Ratio (Source 3)
NZSuper_TaxRate_Req   = zeros(N_scen, 1); % Required labor tax tau_l to fund NZ Super + ECE

for s_idx = 1:N_scen
    Params_s = Params;
    
    switch s_idx
        case 1
            % Baseline calibrated NZ economy (TFR ~ 1.65)
        case 2
            % Stronger present bias (Cao & Li Source 10) + low commitment (Source 9)
            Params_s.beta_hyp      = 0.72;
            Params_s.commit_degree = 0.30;
            Params_s.G_ece_stage1  = 0.025;
        case 3
            % Public Wraparound ECE (Barnardos Source 17 + Luxury In-Kind Source 11)
            % Directly reduces mother's effective childcare cost share chi_f!
            Params_s.G_ece_stage1  = 0.105;
            Params_s.chi_f_share   = 0.52; % Public ECE equalizes maternal childcare burden
        case 4
            % Full Package: Barnardos First-2000-Days ECE + Wealth/Estate Tax cooling Auckland Q_k
            Params_s.G_ece_stage1       = 0.105;
            Params_s.chi_f_share        = 0.50;
            Params_s.commit_degree      = 0.90;
            Params_s.Q_reg.HH_Auckland  = Params.Q_reg.HH_Auckland * 0.88;
            Params_s.Q_reg.HH_Urban     = Params.Q_reg.HH_Urban    * 0.94;
    end
    
    % Evaluate Endogenous Fertility Distribution, Differential Fertility, & Skill Composition
    [FertDiag] = Evaluate_EndogenousFertility_Equilibrium( ...
        StationaryDist, Policy, n_d, n_a, n_z, d_grid, a_grid, z_grid, Params_s, Regions);
    
    for r_idx = 1:3
        reg = Regions{r_idx};
        TFR_By_Region(s_idx, r_idx)        = FertDiag.MeanTFR.(reg);
        DiffFert_Q1_minus_Q5(s_idx, r_idx) = FertDiag.DiffFert_Q1_Q5.(reg);
        StuntedShare_EndoFert(s_idx, r_idx)= 100 * FertDiag.StuntedShare_Weighted.(reg);
    end
    DepRatio_65Plus_Endo(s_idx) = 100 * FertDiag.DepRatio_65Plus;
    NZSuper_TaxRate_Req(s_idx)  = 100 * FertDiag.Required_Tau_L;
end

%% 3. DISPLAY ENDOGENOUS FERTILITY, DIFFERENTIAL FERTILITY, & PENSION TABLES
fprintf('\n=========================================================================================\n');
fprintf('TABLE 1: REGIONAL TOTAL FERTILITY RATE (TFR) & DIFFERENTIAL FERTILITY (Q1 - Q5)\n');
fprintf('=========================================================================================\n');
T_Fert1 = array2table([TFR_By_Region, DiffFert_Q1_minus_Q5], ...
    'VariableNames', {'TFR_Rural', 'TFR_Urban', 'TFR_Auckland', ...
                      'DiffFert_Rural', 'DiffFert_Urban', 'DiffFert_Auckland'}, ...
    'RowNames', FertScenarios);
disp(T_Fert1);

fprintf('\n=========================================================================================\n');
fprintf('TABLE 2: IMPACT OF DIFFERENTIAL FERTILITY ON CHILD STUNTING & NZ SUPER FISCAL SUSTAINABILITY\n');
fprintf('=========================================================================================\n');
T_Fert2 = array2table([StuntedShare_EndoFert, DepRatio_65Plus_Endo, NZSuper_TaxRate_Req], ...
    'VariableNames', {'Stunted_Rural_Pct', 'Stunted_Urban_Pct', 'Stunted_Auckland_Pct', ...
                      'DepRatio_65Plus_Pct', 'Required_LaborTax_Pct'}, ...
    'RowNames', FertScenarios);
disp(T_Fert2);


%% ========================================================================
%  HELPER: EVALUATE ENDOGENOUS FERTILITY, BARGAINING & DEMOGRAPHIC MATRIX
%  ========================================================================
function [Out] = Evaluate_EndogenousFertility_Equilibrium( ...
    StatDist, Policy, n_d, n_a, n_z, d_grid, a_grid, z_grid, Params, Regions)

Out   = struct();
n_a1  = n_a.HH_Rural(1);
n_h   = n_a.HH_Rural(2);
n_th  = n_a.HH_Rural(3);
n_z1  = n_z.HH_Rural;

ic_vec = d_grid.HH_Rural(1 : n_d.HH_Rural(1));
a_vec  = a_grid.HH_Rural(1 : n_a1);
h_vec  = a_grid.HH_Rural(n_a1+1 : n_a1+n_h);
th_vec = a_grid.HH_Rural(n_a1+n_h+1 : end);

pop_weights = Params.PTypeWeights(1:3) / sum(Params.PTypeWeights(1:3));
nat_TFR = 0;
nat_eff_labor = 0;

for r_idx = 1:3
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    Dist_k  = StatDist.(hh_type);
    Pol_k   = Policy.(hh_type);
    w_k     = Params.w_reg.(hh_type);
    Q_k     = Params.Q_reg.(hh_type);
    G_k     = Params.G_reg.(hh_type);
    z_vec   = z_grid.(hh_type);
    
    % Local housing user cost / rent index p_H,k (Kiyotaki et al. Source 2)
    R_ann  = (1 + Params.r)^(1/5);
    rr_k   = max(0.010, (1 + Params.mu_maint - (G_k / R_ann)) * Q_k);
    rh_k   = max(0.008, (1 + Params.mu_maint - Params.upsilon_h - (G_k / R_ann)) * Q_k);
    xi_own = min(1.0, (1 / Params.chi_bar) * (rr_k / rh_k));
    p_H_k  = xi_own * rh_k + (1 - xi_own) * (rr_k / (0.5 * Params.chi_bar));
    
    % Loop over fertile parenting cohort j = 3 (Ages 30-34)
    p_mass = 0; sum_n = 0;
    n_by_z = zeros(n_z1, 1); mass_by_z = zeros(n_z1, 1);
    Prob_h_child_weighted = zeros(n_h, 1);
    total_children_born   = 0;
    
    for ia = 1:n_a1
        for ih = 1:n_h
            for ith = 1:n_th
                for iz = 1:n_z1
                    m_p = Dist_k(ia, ih, ith, iz, 3);
                    if m_p > 1e-12
                        ic_val = ic_vec(Pol_k(1, ia, ih, ith, iz, 3));
                        wm     = w_k * z_vec(iz) * h_vec(ih);
                        wf     = Params.gender_gap_wf * wm;
                        
                        % 1. Intra-Household Bargaining Cost Wedge (Source 9, Eq 17-18)
                        % Mother bears share chi_f_share of unsubsidized time cost x_time_child.
                        % Public wraparound ECE (G_ece_stage1) directly substitutes for maternal time!
                        ece_time_relief = min(0.75, 4.5 * Params.G_ece_stage1);
                        eff_time_cost   = Params.x_time_child * (1 - ece_time_relief);
                        
                        % Under imperfect commitment, asymmetric maternal cost creates a bargaining wedge
                        maternal_burden = Params.chi_f_share * wf * eff_time_cost;
                        coop_cost       = 0.5 * (wm + wf) * eff_time_cost;
                        w_hat_phi       = Params.commit_degree * coop_cost ...
                                        + (1 - Params.commit_degree) * (2.0 * maternal_burden);
                        
                        % Total marginal cost per child (Time + Housing Space + Net Private Investment)
                        psi_child = max(0.04, w_hat_phi + Params.phi_space_kid * p_H_k ...
                                    + (1 - Params.s_sub) * ic_val);
                        
                        % 2. Commitment Fertility n^c vs Hyperbolic Time-Consistent Fertility n^t (Source 10)
                        % Couple agreement condition (Source 9 Eq 18): nu_m + nu_f >= effective threshold
                        tot_child_pref = Params.nu_m + Params.nu_f + 0.15 * log(1 + th_vec(ith));
                        n_commit = (tot_child_pref / psi_child) ^ (1 / Params.eps_fert);
                        
                        % Cao & Li (Source 10, App 3): n^t = n^c * (beta_hyp)^(1/eps_fert)
                        n_realized = n_commit * (Params.beta_hyp ^ (1 / Params.eps_fert));
                        n_realized = min(3.8, max(0.6, n_realized)); % Biological/demographic bounds
                        
                        p_mass = p_mass + m_p;
                        sum_n  = sum_n  + m_p * n_realized;
                        n_by_z(iz)    = n_by_z(iz)    + m_p * n_realized;
                        mass_by_z(iz) = mass_by_z(iz) + m_p;
                        
                        % 3. de la Croix & Doepke (2003, Source 5) Fertility-Weighted Child Skill Distribution
                        % Each parent state contributes m_p * n_realized children to the next generation!
                        kids_mass = m_p * n_realized;
                        total_children_born = total_children_born + kids_mass;
                        
                        % Stage-2 completed skill for children of this parent
                        ic_j4 = ic_vec(Pol_k(1, ia, ih, ith, iz, 4));
                        I_s2  = max(0.05, ic_j4 + Params.G_ece_stage2 + Params.gbar_ece);
                        th_3  = (Params.gamma2_self * (th_vec(ith)^Params.phi2_ces) ...
                               + Params.gamma2_inv  * (I_s2^Params.phi2_ces) ...
                               + Params.gamma2_par  * (h_vec(ih)^Params.phi2_ces)) ^ (1/Params.phi2_ces);
                        
                        is_hard = (a_vec(ia) < 0.05 * Q_k);
                        log_h_m = log(th_3) - 0.06 * log(Q_k) * is_hard;
                        trans_p = normpdf(log(h_vec), log_h_m, Params.sigma_hc_ig);
                        trans_p = trans_p / sum(trans_p);
                        
                        Prob_h_child_weighted = Prob_h_child_weighted + kids_mass * trans_p;
                    end
                end
            end
        end
    end
    
    Prob_h_child_weighted = Prob_h_child_weighted / max(1e-12, total_children_born);
    mean_tfr_k = sum_n / max(1e-12, p_mass);
    
    Out.MeanTFR.(reg)               = mean_tfr_k;
    Out.DiffFert_Q1_Q5.(reg)        = (n_by_z(1)/max(1e-8, mass_by_z(1))) - (n_by_z(end)/max(1e-8, mass_by_z(end)));
    Out.StuntedShare_Weighted.(reg) = sum(Prob_h_child_weighted(1:2));
    
    nat_TFR = nat_TFR + pop_weights(r_idx) * mean_tfr_k;
    nat_eff_labor = nat_eff_labor + pop_weights(r_idx) * w_k * (1 - 0.35 * Out.StuntedShare_Weighted.(reg));
end

% 4. Update Macro Demographic Matrix T_demo (Source 3) with Endogenous National TFR
scale_fert = nat_TFR / 1.65; % Scale baseline Stats NZ fertility vector by endogenous TFR ratio
T_demo = zeros(Params.J, Params.J);
T_demo(1, :) = (Params.fj * scale_fert) * 0.5;
for jj = 1:(Params.J - 1)
    T_demo(jj+1, jj) = Params.sj(jj);
end
N_pop = ones(Params.J, 1) / Params.J;
for it = 1:200
    N_pop = T_demo * N_pop + Params.mig_rate_j' .* N_pop;
    N_pop = max(0, N_pop) / sum(max(0, N_pop));
end

Out.DepRatio_65Plus = sum(N_pop(Params.Jr:end)) / sum(N_pop(1:Params.Jr-1));
% Required labor tax rate to fund universal NZ Super + ECE + Stunted Fiscal Drag
stunted_nat = pop_weights(1)*Out.StuntedShare_Weighted.Rural + ...
              pop_weights(2)*Out.StuntedShare_Weighted.Urban + ...
              pop_weights(3)*Out.StuntedShare_Weighted.Auckland;
fiscal_outlays = Out.DepRatio_65Plus * Params.p_super + 0.15 * Params.G_ece_stage1 + 0.08 * stunted_nat;
Out.Required_Tau_L = fiscal_outlays / max(0.1, 0.45 * nat_eff_labor);

end
