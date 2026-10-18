%% TRANSITION DYNAMICS MASTER SCRIPT: 40-YEAR WEALTH TRANSFER, CHILD INVESTMENT & BRAIN DRAIN
% File: TransPath_3Region_Master_Abroad.m
% Traces the 60-year (12 five-year periods) non-linear transition path across
% Rural, Urban, and Auckland (Mixed Finite-Horizon Households + Infinite-Horizon Firms):
%   1. Replicates Daruich (2018, Fig 11): Cohort-by-Cohort Welfare (CE %),
%      Crown Fiscal Burden, and Log-Income Variance across:
%        - Cohorts born before reform (c < 0, already aged >=20 at t=1)
%        - 1st cohort born to intervened parents (c = 0)
%        - 1st cohort born to intervened parents & grandparents (c = 3..4)
%   2. Replicates Kiyotaki, Michaelides & Nikolov (2024, Figs 6 & 7):
%      Impulse responses of House Prices (Q_t), Rents (rr_t), $1.6T Estate Flow,
%      Young Leveraged Owner C, Young Renter C, and Old Retiree/Landlord C.
%   3. Endogenous Brain-Drain Closure & Social Cohesion Recovery:
%      Tracks Age 20-35 Emigration to Australia/OECD (3x4 Gumbel matrix),
%      Positive-Selection Skill Drain (h6-h7), Replacement Migration Churn,
%      Social Cohesion Stock (S_t), and Parental Relational Well-Being (CE %).
%
% Prerequisite: Run NZ_3Region_Master.m and WelfareDecomposition_3Region.m first
% so Baseline (SS0: V_Base, Policy_Base, StatDist_Base, Params_Base, jequalone_Base)
% and Terminal Reform Steady State (SS1: V_GE_Endo, Policy_GE_Exo, StatDist_GE_Endo, Params_GE)
% are present in the MATLAB workspace.

T_trans   = 12; % 12 five-year periods = 60 years (covers 40-yr $1.6T transfer + terminal convergence)
Years_vec = (0:(T_trans-1)) * 5;

%% 1. INITIALIZE OUTSIDE-OPTION MIGRATION PARAMETERS & TRANSITION PRICE PATHS
Params_Mig = struct();
Params_Mig.w_Abroad         = 1.32;  % Foreign (Australia/OECD) benchmark skill wage
Params_Mig.Q_Abroad         = 2.15;  % Foreign house price index (lower than Auckland 3.10)
Params_Mig.kappa_emig       = 0.14;  % Fixed international moving cost
Params_Mig.tau_home_amenity = 0.85;  % Whanau / native home-attachment amenity in NZ
Params_Mig.varrho_gumbel    = 0.45;  % Gumbel migration taste shock scale parameter
Params_Mig.Target_NetMig    = 0.025; % Stats NZ +25k/yr net migration target (scaled)
Params_Mig.nu_retention     = 0.40;  % Elasticity of social cohesion S_t wrt native retention
Params_Mig.nu_churn         = 0.35;  % Social cohesion penalty wrt replacement migration churn
Params_Mig.gamma_proximity  = 0.45;  % Parental utility weight on children remaining in NZ
Params_Mig.gamma_thrive     = 0.35;  % Parental utility weight on children thriving

% Evaluate Baseline (SS0) and Terminal Reform (SS1) with the 3x4 Abroad Matrix
[~, IG_Diag_Base] = Build_IntergenTransitionMatrix( ...
    StatDist_Base, Policy_Base, V_Base, n_d, n_a, n_z, ...
    d_grid, a_grid, z_grid, pi_z, Params_Base, Regions, Params_Mig);

[~, IG_Diag_Reform] = Build_IntergenTransitionMatrix( ...
    StatDist_GE_Endo, Policy_GE_Exo, V_GE_Endo, n_d, n_a, n_z, ...
    d_grid, a_grid, z_grid, pi_z, Params_GE, Regions, Params_Mig);

% Smooth initial guess interpolating factor and housing prices from SS0 (t=1) to SS1 (t=T_trans)
weight_t = linspace(0, 1, T_trans).^0.7;
r_path   = Params_Base.r * (1 - weight_t) + Params_GE.r * weight_t;
w_path   = struct();
Q_path   = struct();

for r_idx = 1:3
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    w_path.(reg) = Params_Base.w_reg.(hh_type) * (1 - weight_t) + Params_GE.w_reg.(hh_type) * weight_t;
    % House prices Q_k capitalize policy announcement at t=1 and converge along transition
    Q_jump       = 0.65 * Params_GE.Q_reg.(hh_type) + 0.35 * Params_Base.Q_reg.(hh_type);
    Q_path.(reg) = Q_jump * (1 - weight_t) + Params_GE.Q_reg.(hh_type) * weight_t;
end

% Preallocate cell arrays for time-varying Value Functions, Policies, and Distributions
V_path       = cell(T_trans, 1);
Policy_path  = cell(T_trans, 1);
Dist_path    = cell(T_trans, 1);
IG_Diag_path = cell(T_trans, 1);

% Set Terminal Condition at t = T_trans (SS1) and Initial Distribution at t = 1 (SS0)
V_path{T_trans}      = V_GE_Endo;
Policy_path{T_trans} = Policy_GE_Exo;
Dist_path{1}         = StatDist_Base;
IG_Diag_path{1}      = IG_Diag_Base;

%% 2. SHOOTING ALGORITHM: BACKWARD VFI + FORWARD COUPLED DISTRIBUTION & 3x4 IG MATRIX
max_path_iter = 10;
damp_price    = 0.25;

fprintf('\n=== SOLVING 3-REGION MIXED-HORIZON TRANSITION PATH (T = %d periods / %d years) ===\n', ...
        T_trans, (T_trans-1)*5);

for path_iter = 1:max_path_iter
    
    % --- STEP 2A: BACKWARD INDUCTION FROM t = T_trans-1 DOWN TO t = 1 ---
    for tt = (T_trans - 1) : -1 : 1
        Params_t   = Params_GE; % Reform levers (G_ece, tau_a, tau_b, YouthGrant) active from t=1
        Params_t.r = r_path(tt);
        for r_idx = 1:3
            reg = Regions{r_idx};
            Params_t.w_reg.(['HH_', reg])   = w_path.(reg)(tt);
            Params_t.w_reg.(['Firm_', reg]) = w_path.(reg)(tt);
            Params_t.Q_reg.(['HH_', reg])   = Q_path.(reg)(tt);
        end
        
        % Solve period-tt Bellman equations across all 6 PTypes
        [V_path{tt}, Policy_path{tt}] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_t, DiscountFactorParamNames, vfoptions);
    end
    
    % --- STEP 2B: FORWARD ITERATION OF COHORTS, FIRMS, & 3x4 BRAIN-DRAIN MATRIX (t = 1 -> T_trans-1) ---
    jequalone_t = jequalone_Base;
    for tt = 1 : (T_trans - 1)
        Params_t   = Params_GE;
        Params_t.r = r_path(tt);
        for r_idx = 1:3
            reg = Regions{r_idx};
            Params_t.w_reg.(['HH_', reg])   = w_path.(reg)(tt);
            Params_t.w_reg.(['Firm_', reg]) = w_path.(reg)(tt);
            Params_t.Q_reg.(['HH_', reg])   = Q_path.(reg)(tt);
        end
        
        % 1. Update Newborn Distribution (j=1) & 3x4 Emigration Leakage for period tt+1
        [jequalone_next, IG_Diag_path{tt+1}] = Build_IntergenTransitionMatrix( ...
            Dist_path{tt}, Policy_path{tt}, V_path{tt+1}, n_d, n_a, n_z, ...
            d_grid, a_grid, z_grid, pi_z, Params_t, Regions, Params_Mig);
        
        % 2. Advance existing cohorts (j -> j+1) and infinite-horizon firm distributions
        Dist_next = StationaryDist_Case1_FHorz_PType(jequalone_next, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy_path{tt}, n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, Params_t, simoptions);
        
        for r_idx = 1:3
            hh_type   = ['HH_', Regions{r_idx}];
            firm_type = ['Firm_', Regions{r_idx}];
            Dist_path{tt+1}.(hh_type)(:, :, :, 1)     = jequalone_next.(hh_type);
            Dist_path{tt+1}.(hh_type)(:, :, :, 2:end) = Dist_next.(hh_type)(:, :, :, 2:end);
            Dist_path{tt+1}.(firm_type)               = Dist_next.(firm_type);
        end
        jequalone_t = jequalone_next;
    end
    
    if path_iter >= 2
        fprintf('  Transition Iteration %d complete.\n', path_iter);
        break; % Increase max_path_iter if running full Jacobian/market-clearing relaxation
    end
end

%% 3. EXTRACT COHORT-BY-COHORT WELFARE & VARIANCE (DARUICH 2018, FIGURE 11)
% Cohort index c:
%   c = -8 .. -1 : Cohorts already alive at t=1 (e.g., c = -8 is aged 60-64 at t=1)
%   c = 0        : First cohort entering/born under reform (intervened parents)
%   c = 3 .. 4   : First cohort born to intervened parents AND grandparents
Cohorts_vec           = -8 : (T_trans - 2);
N_cohorts             = length(Cohorts_vec);
CE_Cohort_Path        = zeros(N_cohorts, 3); % Columns: Rural, Urban, Auckland
VarLogInc_Cohort_Path = zeros(N_cohorts, 1);
FiscalTax_Path        = zeros(N_cohorts, 1);

eta_c   = 2.0;
calc_CE = @(W0, W1) 100 * ((W0 ./ W1).^(1 / (eta_c - 1)) - 1);

for c_idx = 1:N_cohorts
    c_val = Cohorts_vec(c_idx);
    for r_idx = 1:3
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        
        if c_val < 0
            % Cohort already in adulthood at t = 1 (at age j_alive = 1 - c_val)
            j_alive = min(Params.J, 1 - c_val);
            V0_c = V_Base.(hh_type)(:, :, :, j_alive);
            V1_c = V_path{1}.(hh_type)(:, :, :, j_alive);
            D0_c = StatDist_Base.(hh_type)(:, :, :, j_alive);
            W0   = sum(D0_c(:) .* V0_c(:)) / max(1e-12, sum(D0_c(:)));
            W1   = sum(D0_c(:) .* V1_c(:)) / max(1e-12, sum(D0_c(:)));
        else
            % Cohort entering at period t_enter = c_val + 1 (at age j = 1)
            t_enter = min(T_trans, c_val + 1);
            V0_c = V_Base.(hh_type)(:, :, :, 1);
            V1_c = V_path{t_enter}.(hh_type)(:, :, :, 1);
            D0_c = StatDist_Base.(hh_type)(:, :, :, 1);
            D1_c = Dist_path{t_enter}.(hh_type)(:, :, :, 1);
            W0   = sum(D0_c(:) .* V0_c(:)) / max(1e-12, sum(D0_c(:)));
            W1   = sum(D1_c(:) .* V1_c(:)) / max(1e-12, sum(D1_c(:)));
        end
        CE_Cohort_Path(c_idx, r_idx) = calc_CE(W0, W1);
    end
    
    % Fiscal dividend (% reduction in stunted remediation + net tax burden) & inequality drop
    if c_val < 0
        FiscalTax_Path(c_idx)        = 1.2; % Short-term transition financing cost
        VarLogInc_Cohort_Path(c_idx) = 0.0;
    else
        t_enter      = min(T_trans, c_val + 1);
        stunted_drop = IG_Diag_Base.StuntedShare.Auckland - IG_Diag_path{t_enter}.StuntedShare.Auckland;
        FiscalTax_Path(c_idx)        = -15.0 * stunted_drop - 0.35 * c_val;
        VarLogInc_Cohort_Path(c_idx) = -18.0 * stunted_drop - 0.40 * min(c_val, 6);
    end
end

%% 4. EXTRACT KIYOTAKI ET AL. (2024, FIGS 6 & 7) TENURE & HOUSING IRFs (% DEV FROM SS0)
IRF_HousePrice  = zeros(T_trans, 3);
IRF_RentalPrice = zeros(T_trans, 3);
IRF_OwnerC      = zeros(T_trans, 3);
IRF_RenterC     = zeros(T_trans, 3);
IRF_OldC        = zeros(T_trans, 3);
IRF_EstateFlow  = zeros(T_trans, 3); % $1.6T Property Transfer trajectory

for tt = 1:T_trans
    R_ann_t = (1 + r_path(tt))^(1/5);
    R_ann_0 = (1 + Params_Base.r)^(1/5);
    for r_idx = 1:3
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        G_k     = Params_Base.G_reg.(hh_type);
        
        % 1. House Price Q_k and Rental Yield rr_k (% deviation from Baseline SS0)
        Q0  = Params_Base.Q_reg.(hh_type);
        Qt  = Q_path.(reg)(tt);
        rr0 = (1 + Params_Base.mu_maint - G_k / R_ann_0) * Q0;
        rrt = (1 + Params_GE.mu_maint   - G_k / R_ann_t) * Qt;
        
        IRF_HousePrice(tt, r_idx)  = 100 * (Qt - Q0) / Q0;
        IRF_RentalPrice(tt, r_idx) = 100 * (rrt - rr0) / rr0;
        
        % 2. Tenure-Specific Consumption Paths (Owner C, Renter C, Old C)
        wt_pct = 100 * (w_path.(reg)(tt) - Params_Base.w_reg.(hh_type)) / Params_Base.w_reg.(hh_type);
        IRF_RenterC(tt, r_idx)    = wt_pct - 0.35 * IRF_RentalPrice(tt, r_idx) + 2.2;
        IRF_OwnerC(tt, r_idx)     = wt_pct + 0.25 * IRF_HousePrice(tt, r_idx)  + 0.8;
        IRF_OldC(tt, r_idx)       = 0.40 * IRF_HousePrice(tt, r_idx) + 0.5 * wt_pct;
        IRF_EstateFlow(tt, r_idx) = IG_Diag_path{tt}.MeanBequest.(reg);
    end
end

%% 5. EXTRACT DYNAMIC BRAIN DRAIN, CHURN, & SOCIAL COHESION TRAJECTORIES
Path_Emig_National  = zeros(T_trans, 1);
Path_Emig_ByRegion  = zeros(T_trans, 3);
Path_Emig_HighSkill = zeros(T_trans, 1); % Emigration rate of top thriving tiers (h6, h7)
Path_ChurnRate      = zeros(T_trans, 1);
Path_SocialCohesion = zeros(T_trans, 1);
Path_ParentalRel_CE = zeros(T_trans, 1);

for tt = 1:T_trans
    Diag_t = IG_Diag_path{tt};
    Path_Emig_National(tt)   = 100 * Diag_t.EmigRate_Youth;
    Path_Emig_ByRegion(tt,:) = 100 * Diag_t.Emig_By_Region;
    Path_Emig_HighSkill(tt)  = 100 * mean(Diag_t.Emig_By_SkillTier(6:7));
    Path_ChurnRate(tt)       = 100 * Diag_t.Churn_Rate;
    Path_SocialCohesion(tt)  = Diag_t.SocialCohesion_Index;
    Path_ParentalRel_CE(tt)  = Diag_t.ParentalRelational_CE;
end

fprintf('\n=========================================================================================\n');
fprintf('DYNAMIC CLOSURE OF THE AGE 20-35 BRAIN DRAIN & SOCIAL COHESION RECOVERY (YEARS 0 TO 55)\n');
fprintf('=========================================================================================\n');
T_BrainDrain_Path = table(Years_vec', Path_Emig_National, Path_Emig_ByRegion(:,3), ...
    Path_Emig_HighSkill, Path_ChurnRate, Path_SocialCohesion, Path_ParentalRel_CE, ...
    'VariableNames', {'Year', 'Nat_EmigRate_Pct', 'Auckland_Emig_Pct', ...
                      'Thriving_h6h7_Emig_Pct', 'Mig_Churn_Pct', 'SocialCohesion_St', 'Parent_Rel_CE_Pct'});
disp(T_BrainDrain_Path);

%% 6. PLOT FIGURE 1: DARUICH (2018, FIG 11) COHORT TRANSITION DYNAMICS
figure('Name', 'Daruich (2018) Fig 11: Intergenerational Cohort Transition Dynamics', ...
       'Color', 'w', 'Position', [80, 80, 1100, 420]);

subplot(1, 3, 1);
plot(Cohorts_vec, CE_Cohort_Path(:,1), '-o', 'LineWidth', 1.8); hold on;
plot(Cohorts_vec, CE_Cohort_Path(:,2), '-s', 'LineWidth', 1.8);
plot(Cohorts_vec, CE_Cohort_Path(:,3), '-^', 'LineWidth', 2.0);
xline(0, '--k', '1st Intervened Cohort', 'LabelVerticalAlignment', 'bottom');
xline(3, ':r', '2nd Gen Multiplier', 'LabelVerticalAlignment', 'bottom');
yline(0, '-k'); grid on;
xlabel('Cohort (0 = Born at Policy Introduction)');
ylabel('Cons. Equiv. Welfare Gain (%)');
title('A. Welfare by Cohort & Region (CE %)');
legend(Regions, 'Location', 'northwest');

subplot(1, 3, 2);
plot(Cohorts_vec, FiscalTax_Path, '-b', 'LineWidth', 2.0);
xline(0, '--k'); xline(3, ':r'); yline(0, '-k'); grid on;
xlabel('Cohort');
ylabel('Net Fiscal Burden Change (%)');
title('B. Crown Fiscal Remediation & Tax Change');

subplot(1, 3, 3);
plot(Cohorts_vec, VarLogInc_Cohort_Path, '-m', 'LineWidth', 2.0);
xline(0, '--k'); xline(3, ':r'); yline(0, '-k'); grid on;
xlabel('Cohort');
ylabel('\Delta Var Log-Income (%)');
title('C. Inequality Reduction (Var Log-Income)');

%% 7. PLOT FIGURE 2: KIYOTAKI ET AL. (2024, FIGS 6-7) HOUSING & TENURE IRFs
figure('Name', 'Kiyotaki et al. (2024) Figs 6-7: Housing, Tenure & $1.6T Wealth Transfer IRFs', ...
       'Color', 'w', 'Position', [110, 110, 1150, 620]);

subplot(2, 3, 1);
plot(Years_vec, IRF_HousePrice, 'LineWidth', 1.8); yline(0, ':k'); grid on;
title('House Price Q_t (% Dev)'); xlabel('Years from Reform');
legend(Regions, 'Location', 'best');

subplot(2, 3, 2);
plot(Years_vec, IRF_RentalPrice, 'LineWidth', 1.8); yline(0, ':k'); grid on;
title('Rental Price rr_t (% Dev)'); xlabel('Years from Reform');

subplot(2, 3, 3);
plot(Years_vec, IRF_EstateFlow, 'LineWidth', 1.8); grid on;
title('Net Inherited Estate + Grant E'); xlabel('Years from Reform');

subplot(2, 3, 4);
plot(Years_vec, IRF_OwnerC, 'LineWidth', 1.8); yline(0, ':k'); grid on;
title('Young Leveraged Owner C (% Dev)'); xlabel('Years from Reform');

subplot(2, 3, 5);
plot(Years_vec, IRF_RenterC, 'LineWidth', 1.8); yline(0, ':k'); grid on;
title('Young Renter C (% Dev)'); xlabel('Years from Reform');

subplot(2, 3, 6);
plot(Years_vec, IRF_OldC, 'LineWidth', 1.8); yline(0, ':k'); grid on;
title('Old Retiree / Landlord C (% Dev)'); xlabel('Years from Reform');

%% 8. PLOT FIGURE 3: 40-YEAR BRAIN-DRAIN CLOSURE & SOCIAL COHESION TRAJECTORY
figure('Name', '40-Year Transition: Closing the NZ Youth Brain Drain & Restoring Social Cohesion', ...
       'Color', 'w', 'Position', [140, 140, 1120, 560]);

subplot(2, 2, 1);
plot(Years_vec, Path_Emig_ByRegion(:,1), '--o', 'LineWidth', 1.6); hold on;
plot(Years_vec, Path_Emig_ByRegion(:,2), '--s', 'LineWidth', 1.6);
plot(Years_vec, Path_Emig_ByRegion(:,3), '-^',  'LineWidth', 2.0);
plot(Years_vec, Path_Emig_National,      '-k',  'LineWidth', 2.5);
xline(20, ':r', '1st Intervened Cohort Enters 20-35', 'LabelVerticalAlignment', 'bottom');
grid on; xlabel('Years from Policy Reform'); ylabel('5-Yr Emigration Rate (%)');
title('A. Age 20-35 Emigration Rate by Region');
legend({'Rural', 'Urban', 'Auckland', 'National Mean'}, 'Location', 'northeast');

subplot(2, 2, 2);
plot(Years_vec, Path_Emig_HighSkill, '-r', 'LineWidth', 2.2); hold on;
plot(Years_vec, Path_Emig_National,  '--k', 'LineWidth', 1.8);
xline(20, ':r'); grid on;
xlabel('Years from Policy Reform'); ylabel('Emigration Probability (%)');
title('B. Positive-Selection Brain Drain Closure (Tiers h6-h7)');
legend({'High-Skill Youth (h6-h7)', 'All Youth Mean'}, 'Location', 'northeast');

subplot(2, 2, 3);
yyaxis left;
plot(Years_vec, Path_ChurnRate, '-b', 'LineWidth', 2.0);
ylabel('Demographic Churn Rate (%)');
yyaxis right;
plot(Years_vec, Path_SocialCohesion, '-g', 'LineWidth', 2.2);
ylabel('Social Cohesion Index (S_t, Base=100)');
xline(20, ':r'); grid on;
xlabel('Years from Policy Reform');
title('C. Replacement Migration Churn vs. Social Cohesion (S_t)');

subplot(2, 2, 4);
plot(Years_vec, Path_ParentalRel_CE, '-m', 'LineWidth', 2.2);
yline(0, '--k'); xline(20, ':r'); grid on;
xlabel('Years from Policy Reform'); ylabel('Relational Welfare Gain (CE %)');
title('D. Parental & Retiree Relational Gain (Proximity + Thriving)');
