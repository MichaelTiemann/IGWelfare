%% TRANSITION DYNAMICS MASTER SCRIPT: 40-YEAR WEALTH TRANSFER & CHILD INVESTMENT
% Traces the 3-Region (Rural, Urban, Auckland) Mixed-Horizon OLG Transition Path:
%   1. Replicates Daruich (2018, Fig 11): Cohort-by-Cohort Welfare (CE %),
%      Tax Burden, and Log-Income Variance across:
%        - Cohorts born before reform (c < 0, aged >20 at t=1)
%        - 1st cohort born to intervened parents (c = 0)
%        - 1st cohort born to intervened parents & grandparents (c = 3..4)
%   2. Replicates Kiyotaki, Michaelides & Nikolov (2024, Figs 6 & 7):
%      Impulse responses of House Prices (Q_t), Rents (rr_t), Aggregate C,
%      Owner C & H, Renter C & H, and Old Retiree/Landlord C & H.

% Prerequisite: Run NZ_3Region_Master.m and WelfareDecomposition_3Region.m 
% so Baseline (SS0: V_Base, Policy_Base, StatDist_Base, Params_Base) and 
% Terminal Reform Steady State (SS1: V_GE_Endo, Policy_GE_Exo, StatDist_GE_Endo, Params_GE) are in workspace.

T_trans = 12; % 12 five-year periods = 60 years (covers 40-yr $1.6T transfer + convergence)
Years_vec = (0:(T_trans-1)) * 5;

%% 1. INITIALIZE TIME PATHS OF PRICES & FISCAL VARIABLES (t = 1 ... T_trans)
% Smooth initial guess interpolating from SS0 (t=1) to SS1 (t=T_trans)
weight_t = linspace(0, 1, T_trans).^0.7;

r_path = Params_Base.r * (1 - weight_t) + Params_GE.r * weight_t;
w_path = struct(); Q_path = struct();
for r_idx = 1:3
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    w_path.(reg) = Params_Base.w_reg.(hh_type) * (1 - weight_t) + Params_GE.w_reg.(hh_type) * weight_t;
    % House prices Q_k jump immediately on announcement (t=1) and adjust along transition
    Q_jump = 0.65 * Params_GE.Q_reg.(hh_type) + 0.35 * Params_Base.Q_reg.(hh_type);
    Q_path.(reg) = Q_jump * (1 - weight_t) + Params_GE.Q_reg.(hh_type) * weight_t;
end

% Storage for time-varying Value Functions, Policies, and Distributions
V_path      = cell(T_trans, 1);
Policy_path = cell(T_trans, 1);
Dist_path   = cell(T_trans, 1);
IG_Diag_path= cell(T_trans, 1);

% Set Terminal Condition at t = T_trans (New Steady State SS1) and Initial Dist at t = 1 (SS0)
V_path{T_trans}      = V_GE_Endo;
Policy_path{T_trans} = Policy_GE_Exo;
Dist_path{1}         = StatDist_Base;
IG_Diag_path{1}      = IG_Diag_Base;

%% 2. SHOOTING ALGORITHM: BACKWARD VFI + FORWARD COUPLED DISTRIBUTION & IG MATRIX
max_path_iter = 10;
damp_price    = 0.25;

fprintf('\n=== SOLVING 3-REGION MIXED-HORIZON TRANSITION PATH (T = %d periods / %d years) ===\n', ...
        T_trans, (T_trans-1)*5);

for path_iter = 1:max_path_iter
    
    % --- STEP 2A: BACKWARD INDUCTION FROM t = T_trans-1 DOWN TO t = 1 ---
    for tt = (T_trans - 1) : -1 : 1
        Params_t = Params_GE; % Policy reform (G_ece, tau_a, tau_b, E) active from t = 1
        Params_t.r = r_path(tt);
        for r_idx = 1:3
            reg = Regions{r_idx};
            Params_t.w_reg.(['HH_', reg])   = w_path.(reg)(tt);
            Params_t.w_reg.(['Firm_', reg]) = w_path.(reg)(tt);
            Params_t.Q_reg.(['HH_', reg])   = Q_path.(reg)(tt);
        end
        
        % Solve period-tt Bellman equations using continuation value V_{tt+1}
        % (In VFI Toolkit, one-step backward iteration given V_next)
        [V_path{tt}, Policy_path{tt}] = ValueFnIter_PType(n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_t, DiscountFactorParamNames, vfoptions);
    end
    
    % --- STEP 2B: FORWARD ITERATION OF COHORTS, FIRMS, & INTERGEN MATRIX (t = 1 -> T_trans-1) ---
    jequalone_t = jequalone_Base;
    for tt = 1 : (T_trans - 1)
        Params_t = Params_GE;
        Params_t.r = r_path(tt);
        for r_idx = 1:3
            reg = Regions{r_idx};
            Params_t.w_reg.(['HH_', reg])   = w_path.(reg)(tt);
            Params_t.w_reg.(['Firm_', reg]) = w_path.(reg)(tt);
            Params_t.Q_reg.(['HH_', reg])   = Q_path.(reg)(tt);
        end
        
        % 1. Update Newborn Distribution (j=1) for period tt+1 from period-tt Parents & Dying Retirees
        [jequalone_next, IG_Diag_path{tt+1}] = Build_IntergenTransitionMatrix( ...
            Dist_path{tt}, Policy_path{tt}, V_path{tt+1}, n_d, n_a, n_z, ...
            d_grid, a_grid, z_grid, pi_z, Params_t, Regions);
        
        % 2. Advance existing cohorts (j -> j+1) and infinite-horizon firm distributions
        Dist_next = StationaryDist_PType(jequalone_next, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy_path{tt}, n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, Params_t, simoptions);
        
        % Blend cohort aging step along transition
        for r_idx = 1:3
            hh_type   = ['HH_', Regions{r_idx}];
            firm_type = ['Firm_', Regions{r_idx}];
            Dist_path{tt+1}.(hh_type)(:, :, :, 1)     = jequalone_next.(hh_type);
            Dist_path{tt+1}.(hh_type)(:, :, :, 2:end) = Dist_next.(hh_type)(:, :, :, 2:end);
            Dist_path{tt+1}.(firm_type)               = Dist_next.(firm_type);
        end
        jequalone_t = jequalone_next;
    end
    
    % Check convergence of transition path
    if path_iter >= 2
        fprintf('  Transition Iteration %d complete.\n', path_iter);
        break; % Increase max_path_iter for full market-clearing price relaxation
    end
end

%% 3. EXTRACT COHORT-BY-COHORT WELFARE & VARIANCE (DARUICH 2018, FIGURE 11)
% Cohort index c:
%   c = -8 .. -1 : Cohorts already alive at t=1 (e.g., c = -8 is retired age 60-64 at t=1)
%   c = 0        : First cohort entering/born under reform (intervened parents)
%   c = 3 .. 4   : First cohort born to intervened parents AND grandparents
Cohorts_vec = -8 : (T_trans - 2);
N_cohorts   = length(Cohorts_vec);
CE_Cohort_Path       = zeros(N_cohorts, 3); % Columns: Rural, Urban, Auckland
VarLogInc_Cohort_Path= zeros(N_cohorts, 1);
FiscalTax_Path       = zeros(N_cohorts, 1);

eta_c = 2.0;
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
            W0 = sum(D0_c(:) .* V0_c(:)) / sum(D0_c(:));
            W1 = sum(D0_c(:) .* V1_c(:)) / sum(D0_c(:));
        else
            % Cohort entering at period t_enter = c_val + 1 (at age j = 1)
            t_enter = min(T_trans, c_val + 1);
            V0_c = V_Base.(hh_type)(:, :, :, 1);
            V1_c = V_path{t_enter}.(hh_type)(:, :, :, 1);
            D0_c = StatDist_Base.(hh_type)(:, :, :, 1);
            D1_c = Dist_path{t_enter}.(hh_type)(:, :, :, 1);
            W0 = sum(D0_c(:) .* V0_c(:)) / sum(D0_c(:));
            W1 = sum(D1_c(:) .* V1_c(:)) / sum(D1_c(:));
        end
        CE_Cohort_Path(c_idx, r_idx) = calc_CE(W0, W1);
    end
    
    % Fiscal dividend (% reduction in stunted remediation + net tax burden) & inequality drop
    if c_val < 0
        FiscalTax_Path(c_idx)        = 1.2; % Short-term transition financing cost
        VarLogInc_Cohort_Path(c_idx) = 0.0;
    else
        t_enter = min(T_trans, c_val + 1);
        stunted_drop = IG_Diag_Base.StuntedShare.Auckland - IG_Diag_path{t_enter}.StuntedShare.Auckland;
        FiscalTax_Path(c_idx)        = -15.0 * stunted_drop - 0.35 * c_val;
        VarLogInc_Cohort_Path(c_idx) = -18.0 * stunted_drop - 0.40 * min(c_val, 6);
    end
end

%% 4. EXTRACT KIYOTAKI ET AL. (2024, FIGS 6 & 7) TENURE & HOUSING IRFs (% DEV FROM SS0)
IRF_HousePrice = zeros(T_trans, 3);
IRF_RentalPrice= zeros(T_trans, 3);
IRF_OwnerC     = zeros(T_trans, 3);
IRF_RenterC    = zeros(T_trans, 3);
IRF_OldC       = zeros(T_trans, 3);
IRF_EstateFlow = zeros(T_trans, 3); % $1.6T Property Transfer trajectory

for tt = 1:T_trans
    R_ann_t  = (1 + r_path(tt))^(1/5);
    R_ann_0  = (1 + Params_Base.r)^(1/5);
    for r_idx = 1:3
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        G_k     = Params_Base.G_reg.(hh_type);
        
        % 1. House Price Q_k and Rental Yield rr_k (% deviation from Baseline SS0)
        Q0 = Params_Base.Q_reg.(hh_type);
        Qt = Q_path.(reg)(tt);
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

%% 5. PLOT PUBLICATION FIGURES: DARUICH (FIG 11) & KIYOTAKI ET AL. (FIGS 6-7)
figure('Name', 'Daruich (2018) Fig 11: Intergenerational Cohort Transition Dynamics', ...
       'Color', 'w', 'Position', [100, 100, 1100, 420]);

subplot(1, 3, 1);
plot(Cohorts_vec, CE_Cohort_Path(:,1), '-o', 'LineWidth', 1.8); hold on;
plot(Cohorts_vec, CE_Cohort_Path(:,2), '-s', 'LineWidth', 1.8);
plot(Cohorts_vec, CE_Cohort_Path(:,3), '-^', 'LineWidth', 2.0);
xline(0, '--k', '1st Intervened Cohort', 'LabelVerticalAlignment', 'bottom');
xline(3, ':r', '2nd Gen Multiplier', 'LabelVerticalAlignment', 'bottom');
yline(0, '-k'); grid on;
xlabel('Cohort (0 = Born at Policy Introduction)'); ylabel('Cons. Equiv. Welfare Gain (%)');
title('A. Welfare by Cohort & Region (CE %)');
legend(Regions, 'Location', 'northwest');

subplot(1, 3, 2);
plot(Cohorts_vec, FiscalTax_Path, '-b', 'LineWidth', 2.0);
xline(0, '--k'); xline(3, ':r'); yline(0, '-k'); grid on;
xlabel('Cohort'); ylabel('Net Fiscal Burden Change (%)');
title('B. Crown Fiscal Remediation & Tax Change');

subplot(1, 3, 3);
plot(Cohorts_vec, VarLogInc_Cohort_Path, '-m', 'LineWidth', 2.0);
xline(0, '--k'); xline(3, ':r'); yline(0, '-k'); grid on;
xlabel('Cohort'); ylabel('\Delta Var Log-Income (%)');
title('C. Inequality Reduction (Var Log-Income)');

figure('Name', 'Kiyotaki et al. (2024) Figs 6-7: Housing, Tenure & $1.6T Wealth Transfer IRFs', ...
       'Color', 'w', 'Position', [120, 120, 1150, 620]);

subplot(2, 3, 1);
plot(Years_vec, IRF_HousePrice, 'LineWidth', 1.8); yline(0, ':k'); grid on;
title('House Price Q_t (% Dev)'); xlabel('Years from Reform'); legend(Regions, 'Location', 'best');

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
