%% FERTILITYBARGAINING_MODULE.M (4-REGION DYNAMIC & FULLY VECTORIZED 5D VERSION)
% File: FertilityBargaining_Module.m
% Dynamically scales to N_reg = length(Regions) (4 Regions: Rural, Small, Large, Auckland).
% Integrates Endogenous Fertility & Intra-Household Bargaining into the 4-Region NZ OLG Model:
%   1. Doepke, Hannusch, Kindermann & Tertilt (2022, Source 14):
%      Cooperative bargaining with maternal/paternal childcare cost share chi_f, chi_m
%      and commitment vs limited-commitment fertility surplus (nu_m + nu_f >= w_hat * phi)
%   2. Cao & Li (Source 18):
%      Hyperbolic discounting (beta_hyp < 1) -> time-consistent vs commitment fertility
%   3. de la Croix & Doepke (2003, Source 7):
%      Differential fertility by parent human capital h -> composition effect on newborn h_1
%   4. Endogenous Macro Feedback to Treasury Demographic Matrix (Source 10) & NZ Super Tax

N_reg = length(Regions); % Automatically = 4: {'Rural', 'Small', 'Large', 'Auckland'}

%% 1. ADD FERTILITY & BARGAINING PARAMETERS TO PARAMS
Params.nu_m          = 0.42;  % Male partner preference for children (Source 14)
Params.nu_f          = 0.42;  % Female partner preference for children (Source 14)
Params.gender_gap_wf = 0.88;  % Relative female wage wf / wm in couple
Params.chi_f_share   = 0.72;  % Share of unsubsidized childcare time borne by mother (Source 14)
Params.commit_degree = 0.65;  % Degree of intra-household intertemporal commitment (Source 14)
Params.beta_hyp      = 0.82;  % Present-bias hyperbolic factor beta in [0, 1] (Source 18)
Params.eps_fert      = 0.65;  % Curvature epsilon in altruism function Phi(n) (Source 18)
Params.x_time_child  = 0.14;  % Per-child parental time cost fraction x (Source 7 & Source 18)
Params.phi_space_kid = 0.08;  % Additional housing space cost per child

%% 2. COMPARE 4 FERTILITY & CHILDCARE POLICY SCENARIOS ACROSS ALL 4 REGIONS
FertScenarios = {'1_Baseline_StatusQuo', ...
                 '2_Hyperbolic_NoCommit (beta=0.72, No ECE)', ...
                 '3_Barnardos_ECE_Bargaining_Relief (G_ece1 Up -> Lowers chi_f)', ...
                 '4_Full_Package (ECE1 + Housing Cool + Commit)'};
N_scen = length(FertScenarios);

TFR_By_Region         = zeros(N_scen, N_reg);
DiffFert_Q1_minus_Q5  = zeros(N_scen, N_reg);
StuntedShare_EndoFert = zeros(N_scen, N_reg);
DepRatio_65Plus_Endo  = zeros(N_scen, 1);
NZSuper_TaxRate_Req   = zeros(N_scen, 1);

for s_idx = 1:N_scen
    Params_s = Params;
    switch s_idx
        case 1
            % Baseline calibrated 4-region NZ economy
        case 2
            % Stronger present bias (Cao & Li Source 18) + low commitment (Source 14)
            Params_s.beta_hyp      = 0.72;
            Params_s.commit_degree = 0.30;
            Params_s.G_ece_stage1  = 0.025;
        case 3
            % Public Wraparound ECE (Barnardos Source 13 + Luxury In-Kind Source 3)
            % Directly reduces mother's effective childcare cost share chi_f!
            Params_s.G_ece_stage1  = 0.105;
            Params_s.chi_f_share   = 0.52;
        case 4
            % Full Package: Barnardos First-2000-Days ECE + Wealth/Estate Tax cooling land bubbles
            Params_s.G_ece_stage1  = 0.105;
            Params_s.chi_f_share   = 0.50;
            Params_s.commit_degree = 0.90;
            Q_cool = [0.99, 0.97, 0.93, 0.88];
            for r_idx = 1:N_reg
                hh_type = ['HH_', Regions{r_idx}];
                Params_s.Q_reg.(hh_type) = Params.Q_reg.(hh_type) * Q_cool(min(r_idx, 4));
            end
    end

    % Evaluate Endogenous Fertility Distribution, Differential Fertility, & Skill Composition
    [FertDiag] = Evaluate_EndogenousFertility_Equilibrium( ...
        StationaryDist, Policy, n_d, n_a, n_z, d_grid, a_grid, z_grid, Params_s, Regions);

    for r_idx = 1:N_reg
        reg = Regions{r_idx};
        TFR_By_Region(s_idx, r_idx)         = FertDiag.MeanTFR.(reg);
        DiffFert_Q1_minus_Q5(s_idx, r_idx)  = FertDiag.DiffFert_Q1_Q5.(reg);
        StuntedShare_EndoFert(s_idx, r_idx) = 100 * FertDiag.StuntedShare_Weighted.(reg);
    end
    DepRatio_65Plus_Endo(s_idx) = 100 * FertDiag.DepRatio_65Plus;
    NZSuper_TaxRate_Req(s_idx)  = 100 * FertDiag.Required_Tau_L;
end

%% 3. DISPLAY 4-REGION ENDOGENOUS FERTILITY, DIFFERENTIAL FERTILITY, & PENSION TABLES
Vars_Fert1 = [strcat('TFR_', Regions), strcat('DiffFert_', Regions)];
fprintf('\n=========================================================================================\n');
fprintf('TABLE 7: 4-REGION TOTAL FERTILITY RATE (TFR) & DIFFERENTIAL FERTILITY (Q1 - Q5)\n');
fprintf('=========================================================================================\n');
T_Fert1 = array2table([TFR_By_Region, DiffFert_Q1_minus_Q5], ...
    'VariableNames', Vars_Fert1, 'RowNames', FertScenarios);
disp(T_Fert1);

Vars_Fert2 = [strcat('Stunted_Pct_', Regions), {'DepRatio_65Plus_Pct', 'Required_LaborTax_Pct'}];
fprintf('\n=========================================================================================\n');
fprintf('TABLE 8: 4-REGION DIFFERENTIAL FERTILITY IMPACT ON CHILD STUNTING & NZ SUPER TAX\n');
fprintf('=========================================================================================\n');
T_Fert2 = array2table([StuntedShare_EndoFert, DepRatio_65Plus_Endo, NZSuper_TaxRate_Req], ...
    'VariableNames', Vars_Fert2, 'RowNames', FertScenarios);
disp(T_Fert2);

%% ========================================================================
%  VECTORIZED HELPER: EVALUATE ENDOGENOUS FERTILITY, BARGAINING & DEMOGRAPHY
%  ========================================================================
function [Out] = Evaluate_EndogenousFertility_Equilibrium( ...
    StatDist, Policy, n_d, n_a, n_z, d_grid, a_grid, z_grid, Params, Regions)

    Out   = struct();
    N_reg = length(Regions);
    n_a1  = n_a.HH_Rural(1);
    n_h   = n_a.HH_Rural(2);
    n_th  = n_a.HH_Rural(3);
    n_z1  = n_z.HH_Rural;

    % Decision order in n_d = [4, 3, 7]: d1 = l (1:4), d2 = Ih (5:7), d3 = ic (8:14)
    n_l        = n_d.HH_Rural(1);
    n_Ih       = n_d.HH_Rural(2);
    d_grid_cpu = gather(d_grid.HH_Rural(:));
    ic_vec     = d_grid_cpu(n_l + n_Ih + 1 : end);

    a_grid_cpu = gather(a_grid.HH_Rural(:));
    a_vec      = a_grid_cpu(1 : n_a1);
    h_vec      = a_grid_cpu(n_a1+1 : n_a1+n_h);
    th_vec     = a_grid_cpu(n_a1+n_h+1 : end);
    log_h_col  = log(h_vec(:)); % [n_h, 1]

    % Pre-reshape 1D grids for 4D implicit expansion [n_a1, n_h, n_th, n_z1]
    a_4d  = reshape(a_vec,  [n_a1, 1, 1, 1]);
    h_4d  = reshape(h_vec,  [1, n_h, 1, 1]);
    th_4d = reshape(th_vec, [1, 1, n_th, 1]);

    pop_weights   = gather(Params.PTypeWeights(1:N_reg));
    pop_weights   = pop_weights(:) / sum(pop_weights);
    nat_TFR       = 0;
    nat_eff_labor = 0;
    stunted_nat   = 0;

    for r_idx = 1:N_reg
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        Dist_k  = gather(StatDist.(hh_type)); % [n_a1, n_h, n_th, n_z1, J]
        Pol_k   = gather(Policy.(hh_type));   % [4, n_a1, n_h, n_th, n_z1, J]
        w_k     = Params.w_reg.(hh_type);
        Q_k     = Params.Q_reg.(hh_type);
        G_k     = Params.G_reg.(hh_type);
        z_vec   = gather(z_grid.(hh_type)(:));
        z_4d    = reshape(z_vec, [1, 1, 1, n_z1]);

        R_ann  = (1 + Params.r)^(1/5);
        rr_k   = max(0.010, (1 + Params.mu_maint - (G_k / R_ann)) * Q_k);
        rh_k   = max(0.008, (1 + Params.mu_maint - Params.upsilon_h - (G_k / R_ann)) * Q_k);
        xi_own = min(1.0, (1 / Params.chi_bar) * (rr_k / rh_k));
        p_H_k  = xi_own * rh_k + (1 - xi_own) * (rr_k / (0.5 * Params.chi_bar));

        % Extract 4D Stage-1 (j=3) and Stage-2 (j=4) Child Investment Policies (Row 3 of Pol_k)
        m_p_4d    = Dist_k(:, :, :, :, 3); % [n_a1, n_h, n_th, n_z1]
        p_mass    = sum(m_p_4d(:));

        ic_idx_j3 = min(length(ic_vec), max(1, Pol_k(3, :, :, :, :, 3)));
        ic_val_4d = reshape(ic_vec(ic_idx_j3(:)), [n_a1, n_h, n_th, n_z1]);

        ic_idx_j4 = min(length(ic_vec), max(1, Pol_k(3, :, :, :, :, 4)));
        ic_j4_4d  = reshape(ic_vec(ic_idx_j4(:)), [n_a1, n_h, n_th, n_z1]);

        % 1. Vectorized Intra-Household Bargaining Cost Wedge (Source 14)
        wm_4d = w_k .* h_4d .* z_4d; % [1, n_h, 1, n_z1]
        wf_4d = Params.gender_gap_wf .* wm_4d;

        ece_time_relief = min(0.75, 4.5 * Params.G_ece_stage1);
        eff_time_cost   = Params.x_time_child * (1 - ece_time_relief);
        maternal_burden = Params.chi_f_share .* wf_4d .* eff_time_cost;
        coop_cost       = 0.5 .* (wm_4d + wf_4d) .* eff_time_cost;
        w_hat_phi_4d    = Params.commit_degree .* coop_cost ...
                        + (1 - Params.commit_degree) .* (2.0 .* maternal_burden);

        psi_child_4d = max(0.04, w_hat_phi_4d + Params.phi_space_kid * p_H_k ...
                               + (1 - Params.s_sub) .* ic_val_4d);

        % 2. Vectorized Commitment vs Hyperbolic Fertility (Source 18)
        tot_child_pref_4d = Params.nu_m + Params.nu_f + 0.15 .* log(1 + th_4d);
        n_commit_4d       = (tot_child_pref_4d ./ psi_child_4d) .^ (1 / Params.eps_fert);
        n_realized_4d     = n_commit_4d .* (Params.beta_hyp ^ (1 / Params.eps_fert));
        n_realized_4d     = min(3.8, max(0.6, n_realized_4d));

        kids_mass_4d        = m_p_4d .* n_realized_4d;
        total_children_born = sum(kids_mass_4d(:));
        n_by_z              = squeeze(sum(kids_mass_4d, [1, 2, 3]));
        mass_by_z           = squeeze(sum(m_p_4d,       [1, 2, 3]));

        % 3. Vectorized Differential Fertility-Weighted Child Skill (Source 7)
        I_s2_4d = max(0.05, ic_j4_4d + Params.G_ece_stage2 + Params.gbar_ece);
        th_3_4d = (Params.gamma2_self .* (th_4d .^ Params.phi2_ces) ...
                 + Params.gamma2_inv  .* (I_s2_4d .^ Params.phi2_ces) ...
                 + Params.gamma2_par  .* (h_4d .^ Params.phi2_ces)) .^ (1 / Params.phi2_ces);

        is_hard_4d   = double(a_4d < 0.05 * Q_k);
        log_h_m_4d   = log(th_3_4d) - 0.06 * log(max(1.0, Q_k)) .* is_hard_4d; % [n_a1, n_h, n_th, n_z1]

        trans_p_mat  = normpdf(log_h_col, log_h_m_4d(:)', Params.sigma_hc_ig); % [n_h, N_4d]
        trans_p_mat  = trans_p_mat ./ max(1e-12, sum(trans_p_mat, 1));
        Prob_h_child_weighted = (trans_p_mat * kids_mass_4d(:)) / max(1e-12, total_children_born);

        mean_tfr_k                      = total_children_born / max(1e-12, p_mass);
        Out.MeanTFR.(reg)               = mean_tfr_k;
        Out.DiffFert_Q1_Q5.(reg)        = (n_by_z(1) / max(1e-8, mass_by_z(1))) - (n_by_z(end) / max(1e-8, mass_by_z(end)));
        Out.StuntedShare_Weighted.(reg) = sum(Prob_h_child_weighted(1:2));

        nat_TFR       = nat_TFR       + pop_weights(r_idx) * mean_tfr_k;
        nat_eff_labor = nat_eff_labor + pop_weights(r_idx) * w_k * (1 - 0.35 * Out.StuntedShare_Weighted.(reg));
        stunted_nat   = stunted_nat   + pop_weights(r_idx) * Out.StuntedShare_Weighted.(reg);
    end

    % 4. Update Macro Demographic Matrix T_demo (Source 10) with Endogenous National TFR
    scale_fert   = nat_TFR / 1.65;
    T_demo       = zeros(Params.J, Params.J);
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
    fiscal_outlays      = Out.DepRatio_65Plus * Params.p_super + 0.15 * Params.G_ece_stage1 + 0.08 * stunted_nat;
    Out.Required_Tau_L  = fiscal_outlays / max(0.1, 0.45 * nat_eff_labor);
end
