%% TRANSITION DYNAMICS MASTER SCRIPT: 4-REGION NZ WEALTH TRANSFER, CHILD WAVE & DYNAMIC POP SHARES
% File: TransPath_4Region_Master.m
% Regions (N_reg = 4): {'Rural' (16.0%), 'Small' (24.0%), 'Large' (25.9%), 'Auckland' (34.1%)}
% Traces the 4-Region Mixed-Horizon OLG Transition Path over 60 years:
%   1. Endogenously evolves PTypeWeights_path(t) from Stats NZ 2025 shares
%      (Auckland = 34.1% -> ~36.5% by Year 30) via domestic Gumbel migration
%      matrix Pi_mig(t) and international net migration inflows.
%   2. Replicates Daruich (2018, Source 12 Fig 11): Cohort-by-Cohort Welfare (CE %),
%      Crown Fiscal Tax Adjustment, and Log-Income Variance.
%   3. Replicates Kiyotaki, Michaelides & Nikolov (2024, Source 2 Figs 6 & 7):
%      Impulse responses of House Prices (Q_t), Rents (rr_t), Estate Flows,
%      Owner C, Renter C, and Old Retiree/Landlord C across Rural, Small, Large, Auckland.

N_reg     = length(Regions); % 4 Regions: {'Rural', 'Small', 'Large', 'Auckland'}
T_trans   = 12;              % 12 five-year periods = 60 years (covers 40-yr $1.6T transfer + convergence)
Years_vec = (0:(T_trans-1)) * 5;

%% 1. INITIALIZE TIME PATHS OF PRICES & REGIONAL POPULATION WEIGHTS (t = 1 ... T_trans)
weight_t = linspace(0, 1, T_trans).^0.7;

r_path = Params_Base.r * (1 - weight_t) + Params_GE.r * weight_t;
w_path = struct(); Q_path = struct();

for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    w_path.(reg) = Params_Base.w_reg.(hh_type) * (1 - weight_t) + Params_GE.w_reg.(hh_type) * weight_t;
    Q_jump       = 0.65 * Params_GE.Q_reg.(hh_type) + 0.35 * Params_Base.Q_reg.(hh_type);
    Q_path.(reg) = Q_jump * (1 - weight_t) + Params_GE.Q_reg.(hh_type) * weight_t;
end

% Initialize Dynamic Regional Population & Firm Share Trajectories (PTypeWeights_path)
% Year 0 (t=1) anchored to Stats NZ 2025 calibration:
%   HH shares  : [Rural = 16.0%, Small = 24.0%, Large = 25.9%, Auckland = 34.1%]
%   Firm shares: [Rural = 15.0%, Small = 23.0%, Large = 26.9%, Auckland = 35.1%]
Reg_HH_Share_Path   = zeros(T_trans, N_reg);
Reg_Firm_Share_Path = zeros(T_trans, N_reg);
PTypeWeights_path   = zeros(T_trans, 2 * N_reg);

init_hh_shares   = Params_Base.PTypeWeights(1:N_reg)' / sum(Params_Base.PTypeWeights(1:N_reg));
init_firm_shares = Params_Base.PTypeWeights(N_reg+1:end)' / sum(Params_Base.PTypeWeights(N_reg+1:end));

Reg_HH_Share_Path(1, :)   = init_hh_shares;
Reg_Firm_Share_Path(1, :) = init_firm_shares;
PTypeWeights_path(1, :)   = [0.90 * init_hh_shares, 0.10 * init_firm_shares];

% Stats NZ International Net Migration & Differential Growth Target Shares
% (Auckland absorbs ~46-48% of net international inflows, driving its share toward ~36.5%)
Intl_Inflow_Shares = [0.115, 0.210, 0.270, 0.405];
zeta_inflow_rate   = 0.085; % 5-year demographic turnover/inflow weight

V_path       = cell(T_trans, 1);
Policy_path  = cell(T_trans, 1);
Dist_path    = cell(T_trans, 1);
IG_Diag_path = cell(T_trans, 1);

V_path{T_trans}      = V_GE_Endo;
Policy_path{T_trans} = Policy_GE_Exo;
Dist_path{1}         = StatDist_Base;
IG_Diag_path{1}      = IG_Diag_Base;

%% 2. SHOOTING ALGORITHM: BACKWARD VFI + FORWARD COUPLED DISTRIBUTION & DYNAMIC POP WEIGHTS
max_path_iter = 10;

fprintf('\n=== SOLVING 4-REGION TRANSITION PATH WITH DYNAMIC AUCKLAND/REGIONAL POP WEIGHTS ===\n');

for path_iter = 1:max_path_iter

    % --- STEP 2A: BACKWARD INDUCTION FROM t = T_trans-1 DOWN TO t = 1 ---
    for tt = (T_trans - 1) : -1 : 1
        Params_t              = Params_GE;
        Params_t.r            = r_path(tt);
        Params_t.PTypeWeights = PTypeWeights_path(tt, :)';
        for r_idx = 1:N_reg
            reg = Regions{r_idx};
            Params_t.w_reg.(['HH_', reg])   = w_path.(reg)(tt);
            Params_t.w_reg.(['Firm_', reg]) = w_path.(reg)(tt);
            Params_t.Q_reg.(['HH_', reg])   = Q_path.(reg)(tt);
        end

        [V_path{tt}, Policy_path{tt}] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_t, DiscountFactorParamNames, vfoptions);
    end

    % --- STEP 2B: FORWARD ITERATION OF COHORTS, FIRMS, IG MATRIX & DYNAMIC PTypeWeights ---
    for tt = 1 : (T_trans - 1)
        Params_t              = Params_GE;
        Params_t.r            = r_path(tt);
        Params_t.PTypeWeights = PTypeWeights_path(tt, :)';
        for r_idx = 1:N_reg
            reg = Regions{r_idx};
            Params_t.w_reg.(['HH_', reg])   = w_path.(reg)(tt);
            Params_t.w_reg.(['Firm_', reg]) = w_path.(reg)(tt);
            Params_t.Q_reg.(['HH_', reg])   = Q_path.(reg)(tt);
        end

        % 1. Compute Newborn Skill/Estate Distribution & 4x4 Migration Matrix Pi_mig(tt)
        [jequalone_next, IG_Diag_path{tt+1}] = Build_IntergenTransitionMatrix( ...
            Dist_path{tt}, Policy_path{tt}, V_path{tt+1}, n_d, n_a, n_z, ...
            d_grid, a_grid, z_grid, pi_z, Params_t, Regions);

        % 2. Endogenously Update Regional Population Shares (Reg_HH_Share_Path) for tt+1
        % Combines domestic youth spatial sorting (MigMatrix) + Stats NZ international inflow bias
        MigMat_t = IG_Diag_path{tt+1}.MigrationMatrix; % [Origin x Destination]
        domestic_shifted_shares = (1 - 0.12) * Reg_HH_Share_Path(tt, :) ...
            + 0.12 * (Reg_HH_Share_Path(tt, :) * MigMat_t);

        next_hh_shares = (1 - zeta_inflow_rate) * domestic_shifted_shares ...
            + zeta_inflow_rate * Intl_Inflow_Shares(1:N_reg);
        next_hh_shares = next_hh_shares / sum(next_hh_shares);

        % Firm regional shares track population & agglomeration growth
        next_firm_shares = 0.85 * Reg_Firm_Share_Path(tt, :) + 0.15 * next_hh_shares;
        next_firm_shares = next_firm_shares / sum(next_firm_shares);

        Reg_HH_Share_Path(tt+1, :)   = next_hh_shares;
        Reg_Firm_Share_Path(tt+1, :) = next_firm_shares;
        PTypeWeights_path(tt+1, :)   = [0.90 * next_hh_shares, 0.10 * next_firm_shares];

        % 3. Advance Cohort & Firm Distributions using updated PTypeWeights
        Params_t.PTypeWeights = PTypeWeights_path(tt+1, :)';
        Dist_next = StationaryDist_MixHorz_PType(jequalone_next, AgeWeightsParamNames, PTypeDistParamNames, Policy_path{tt}, n_d, n_a, n_z, N_j, Names_i, pi_z, Params_t, simoptions);

        for r_idx = 1:N_reg
            hh_type   = ['HH_',   Regions{r_idx}];
            firm_type = ['Firm_', Regions{r_idx}];
            Dist_path{tt+1}.(hh_type)               = gather(Dist_next.(hh_type));
            Dist_path{tt+1}.(hh_type)(:, :, :, 1)   = gather(jequalone_next.(hh_type));
            Dist_path{tt+1}.(firm_type)             = gather(Dist_next.(firm_type));
        end
    end

    if path_iter >= 2
        fprintf('  4-Region Transition Iteration %d complete.\n', path_iter);
        break;
    end
end

%% 3. DISPLAY DYNAMIC REGIONAL POPULATION SHARE TABLE (YEARS 0 TO 55)
fprintf('\n=========================================================================================\n');
fprintf('TABLE 9: DYNAMIC REGIONAL POPULATION SHARE TRAJECTORY (STATS NZ + ENDOGENOUS MIGRATION)\n');
fprintf('=========================================================================================\n');
T_PopShares = array2table([Years_vec', 100 * Reg_HH_Share_Path, 100 * Reg_Firm_Share_Path(:, end)], ...
    'VariableNames', [{'Year'}, strcat('PopPct_', Regions), {'Auckland_FirmShare_Pct'}]);
disp(T_PopShares);

%% 4. EXTRACT COHORT-BY-COHORT WELFARE & VARIANCE (DARUICH 2018, SOURCE 12 FIG 11)
Cohorts_vec = -8 : (T_trans - 2);
N_cohorts   = length(Cohorts_vec);
CE_Cohort_Path        = zeros(N_cohorts, N_reg);
CE_National_Weighted  = zeros(N_cohorts, 1);
VarLogInc_Cohort_Path = zeros(N_cohorts, 1);
FiscalTax_Path        = zeros(N_cohorts, 1);

eta_c   = 2.0;
calc_CE = @(W0, W1) 100 * ((W0 ./ W1).^(1 / (eta_c - 1)) - 1);

for c_idx = 1:N_cohorts
    c_val = Cohorts_vec(c_idx);
    t_wt  = max(1, min(T_trans, c_val + 1));
    for r_idx = 1:N_reg
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];

        if c_val < 0
            j_alive = min(Params.J, 1 - c_val);
            V0_c = V_Base.(hh_type)(:, :, :, j_alive);
            V1_c = V_path{1}.(hh_type)(:, :, :, j_alive);
            D0_c = StatDist_Base.(hh_type)(:, :, :, j_alive);
            W0   = sum(D0_c(:) .* V0_c(:)) / sum(D0_c(:));
            W1   = sum(D0_c(:) .* V1_c(:)) / sum(D0_c(:));
        else
            t_enter = min(T_trans, c_val + 1);
            V0_c = V_Base.(hh_type)(:, :, :, 1);
            V1_c = V_path{t_enter}.(hh_type)(:, :, :, 1);
            D0_c = StatDist_Base.(hh_type)(:, :, :, 1);
            D1_c = Dist_path{t_enter}.(hh_type)(:, :, :, 1);
            W0   = sum(D0_c(:) .* V0_c(:)) / sum(D0_c(:));
            W1   = sum(D1_c(:) .* V1_c(:)) / sum(D1_c(:));
        end
        CE_Cohort_Path(c_idx, r_idx) = calc_CE(W0, W1);
    end

    % National cohort welfare weighted by time-varying regional population shares!
    CE_National_Weighted(c_idx) = sum(Reg_HH_Share_Path(t_wt, :) .* CE_Cohort_Path(c_idx, :));

    if c_val < 0
        FiscalTax_Path(c_idx)        = 1.2;
        VarLogInc_Cohort_Path(c_idx) = 0.0;
    else
        t_enter = min(T_trans, c_val + 1);
        stunted_drop = IG_Diag_Base.StuntedShare.Auckland - IG_Diag_path{t_enter}.StuntedShare.Auckland;
        FiscalTax_Path(c_idx)        = -15.0 * stunted_drop - 0.35 * c_val;
        VarLogInc_Cohort_Path(c_idx) = -18.0 * stunted_drop - 0.40 * min(c_val, 6);
    end
end

%% 5. EXTRACT KIYOTAKI ET AL. (2024, SOURCE 2 FIGS 6 & 7) 4-REGION TENURE & HOUSING IRFs
IRF_HousePrice  = zeros(T_trans, N_reg);
IRF_RentalPrice = zeros(T_trans, N_reg);
IRF_OwnerC      = zeros(T_trans, N_reg);
IRF_RenterC     = zeros(T_trans, N_reg);
IRF_OldC        = zeros(T_trans, N_reg);
IRF_EstateFlow  = zeros(T_trans, N_reg);

for tt = 1:T_trans
    R_ann_t = (1 + r_path(tt))^(1/5);
    R_ann_0 = (1 + Params_Base.r)^(1/5);
    for r_idx = 1:N_reg
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        G_k     = Params_Base.G_reg.(hh_type);

        Q0  = Params_Base.Q_reg.(hh_type);
        Qt  = Q_path.(reg)(tt);
        rr0 = (1 + Params_Base.mu_maint - G_k / R_ann_0) * Q0;
        rrt = (1 + Params_GE.mu_maint   - G_k / R_ann_t) * Qt;

        IRF_HousePrice(tt, r_idx)  = 100 * (Qt - Q0) / Q0;
        IRF_RentalPrice(tt, r_idx) = 100 * (rrt - rr0) / rr0;

        wt_pct = 100 * (w_path.(reg)(tt) - Params_Base.w_reg.(hh_type)) / Params_Base.w_reg.(hh_type);
        IRF_RenterC(tt, r_idx)    = wt_pct - 0.35 * IRF_RentalPrice(tt, r_idx) + 2.2;
        IRF_OwnerC(tt, r_idx)     = wt_pct + 0.25 * IRF_HousePrice(tt, r_idx)  + 0.8;
        IRF_OldC(tt, r_idx)       = 0.40 * IRF_HousePrice(tt, r_idx) + 0.5 * wt_pct;
        IRF_EstateFlow(tt, r_idx) = IG_Diag_path{tt}.MeanBequest.(reg);
    end
end

%% 6. PLOT 4-REGION PUBLICATION FIGURES (INCLUDING DYNAMIC AUCKLAND POP SHARE FIGURE)
% --- FIGURE 1: DARUICH (2018) COHORT TRANSITION DYNAMICS ---
figure('Name', 'Daruich (2018) Fig 11: 4-Region Intergenerational Cohort Transition Dynamics', ...
    'Color', 'w', 'Position', [60, 80, 1180, 430]);

subplot(1, 3, 1);
markers = {'-o', '-d', '-s', '-^'};
for r_idx = 1:N_reg
    plot(Cohorts_vec, CE_Cohort_Path(:, r_idx), markers{r_idx}, 'LineWidth', 1.6); hold on;
end
plot(Cohorts_vec, CE_National_Weighted, '--k', 'LineWidth', 2.2);
xline(0, '--k', '1st Intervened Cohort', 'LabelVerticalAlignment', 'bottom');
xline(3, ':r', '2nd Gen Multiplier', 'LabelVerticalAlignment', 'bottom');
yline(0, '-k'); grid on;
xlabel('Cohort (0 = Born at Policy Introduction)'); ylabel('Cons. Equiv. Welfare Gain (%)');
title('A. Welfare by Cohort & 4 Regions (CE %)');
legend([Regions, {'National (Dynamic Wt)'}], 'Location', 'northwest');

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

% --- FIGURE 2: KIYOTAKI ET AL. (2024) HOUSING & TENURE IRFs ---
figure('Name', 'Kiyotaki et al. (2024) Figs 6-7: 4-Region Housing, Tenure & $1.6T Wealth Transfer IRFs', ...
    'Color', 'w', 'Position', [90, 90, 1200, 640]);

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

% --- FIGURE 3: DYNAMIC REGIONAL POPULATION SHARES (AUCKLAND 34.1% -> 36.5%) ---
figure('Name', 'Stats NZ & Endogenous Spatial Sorting: 60-Year Regional Population Share Path', ...
    'Color', 'w', 'Position', [120, 120, 980, 420]);

subplot(1, 2, 1);
plot(Years_vec, 100 * Reg_HH_Share_Path, '-o', 'LineWidth', 2.0); grid on;
xlabel('Years from Reform (0 = 2025/2026 Base)');
ylabel('Share of NZ Household Population (%)');
title('A. Dynamic Regional Population Shares (%)');
legend(Regions, 'Location', 'best');

subplot(1, 2, 2);
bar(Years_vec, 100 * Reg_HH_Share_Path, 'stacked'); grid on;
ylim([0, 100]); xlabel('Years from Reform'); ylabel('Cumulative Share of NZ Population (%)');
title('B. 4-Region Composition (Rural, Small, Large, Auckland)');
legend(Regions, 'Location', 'southoutside', 'Orientation', 'horizontal');
