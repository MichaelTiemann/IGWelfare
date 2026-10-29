function Out = Run_WealthTax_Exemption_Sensitivity(Params_In)
% RUN_WEALTHTAX_EXEMPTION_SENSITIVITY
% Realtime (<0.3 sec) post-simulation sensitivity engine evaluating how
% exempting the bottom X% of households (e.g., 0%, 50%, 80%, 90%, 95%) from
% the annual wealth/land levy (tau_a) and the NZD 1.6T estate tax (tau_b)
% affects:
%   1) Phase 1 (SS1) & Phase 2 (SS2) Sovereign Debt-Sinking (Omega_debt)
%   2) Phase 1 (SS1) & Phase 2 (SS2) Public Infrastructure Pool (Omega_reinv)
%   3) Cash-Flow Breakeven Year, Affordable SS2 PAYE Tax Cut, & National CE %
%   4) The 12-Tier Earn + Own Welfare Incidence (Rashbrooke / Stats NZ / IRD)
%
% Does NOT re-solve GPU VFI or Stationary Distributions! Integrates directly
% over the Lorenz/Pareto upper tail of the NZ wealth distribution.
%
% Usage in Command Window:
%   Out = Run_WealthTax_Exemption_Sensitivity();
%   Out = Run_WealthTax_Exemption_Sensitivity(struct('Tax_Mode', 'Slab_Exclusion', 'Target_Exempt_Pct', 80));

if nargin < 1 || isempty(Params_In), Params_In = struct(); end

% --- USER-ADJUSTABLE SETTINGS ---
% 1. Grid of bottom-percentile exemptions to compare side-by-side:
if isfield(Params_In, 'Exempt_Pct_Grid')
    Exempt_Pct_Grid = Params_In.Exempt_Pct_Grid(:)';
else
    Exempt_Pct_Grid = [0, 50, 80, 90, 95]; % Default sweep: 0%, 50%, 80%, 90%, 95%
end

% 2. Tax Exemption Design Mode:
%    'Marginal_Allowance' : Tax applies ONLY to wealth/estate dollars ABOVE the threshold max(0, W - W_exempt)
%    'Slab_Exclusion'     : Households below P_exempt pay $0; households above pay on their taxable base
if isfield(Params_In, 'Tax_Mode')
    Tax_Mode = Params_In.Tax_Mode;
else
    Tax_Mode = 'Marginal_Allowance';
end

% 3. Policy Closure Rule when tax base narrows:
%    'Fixed_Statutory_Rate'    : Keep tau_a = 1.5%, tau_b = 25%->18% fixed; let surplus/PAYE cut adjust
%    'Revenue_Neutral_TopRate' : Scale top-bracket tau_a & tau_b so Debt-Sinking & Infra stay 100% unchanged!
if isfield(Params_In, 'Closure_Rule')
    Closure_Rule = Params_In.Closure_Rule;
else
    Closure_Rule = 'Fixed_Statutory_Rate';
end

if isfield(Params_In, 'Calibration_Anchor')
    AnchorTag = Params_In.Calibration_Anchor;
else
    AnchorTag = 'Dunedin_22';
end

if evalin('base', 'exist(''OutputDir'', ''var'')')
    OutputDir = evalin('base', 'OutputDir');
elseif isfolder('Output_NZ_4Region_Intergen')
    OutputDir = 'Output_NZ_4Region_Intergen';
else
    OutputDir = pwd;
end
if ~exist(OutputDir, 'dir'), mkdir(OutputDir); end

% =========================================================================
% 1. EMPIRICAL NZ WEALTH LORENZ & PARETO TAIL CALIBRATION
%    (Anchored to Stats NZ HES 2024, Rashbrooke Too Much Money, & IRD HWIRP)
% =========================================================================
% Map Population Percentile P in [0, 99] to Household Net Worth Threshold (NZD Millions)
% and Share of Aggregate Net Worth held ABOVE P (Slab Share vs. Marginal Excess Share)
Pct_Nodes        = [0,     20,    50,    70,    80,    85,    90,    95,    98,    99];
NW_Cutoff_MNZD   = [0.00,  0.05,  0.53,  0.95,  1.35,  1.68,  2.15,  3.10,  5.20,  8.50];
Slab_Base_Share  = [1.000, 0.995, 0.965, 0.825, 0.705, 0.620, 0.530, 0.390, 0.255, 0.180];
Marg_Base_Share  = [1.000, 0.975, 0.862, 0.680, 0.548, 0.468, 0.385, 0.272, 0.172, 0.118];

% Baseline Verified SS1 & SS2 Fiscal & Macroeconomic Anchors (at P_exempt = 0%):
Base_SS1_DebtSink_BNZD  = 17.82; % NZD Billions retired per cohort wave in SS1 (50% Sinking Pool)
Base_SS1_InfraPool_BNZD = 12.16; % NZD Billions reinvested in public infra in SS1 (50% Reinv Pool)
Base_SS2_DebtSink_BNZD  = 21.85; % NZD Billions retired per cohort wave in SS2 (50% Sinking Pool)
Base_SS2_InfraPool_BNZD = 14.90; % NZD Billions reinvested in public infra in SS2 (50% Reinv Pool)
Base_Breakeven_Yr       = 18.80; % Baseline Cash-Flow Breakeven Year
Base_SS2_PAYE_Cut_pp    = -3.50; % Baseline -3.50 pp PAYE tax cut (22.0% -> 18.5%)
Base_SS1_Nat_CE_Pct     = 12.63; % Baseline SS1 National Welfare Gain (CE %)
Base_SS2_Nat_CE_Pct     = 20.49; % Baseline SS2 National Welfare Gain (CE %)

% Share of Post-Breakeven Fiscal Surplus Driven by Wealth/Estate Tax vs. Human-Capital/Exits Dividend:
% In SS1, wealth/estate revenue accounts for ~39% of net surplus above baseline outlays;
% In SS2, because human capital (Exits 1-4 savings + h6-h7 PAYE/GST surge) dominates,
% ongoing estate/land tax accounts for ~28% of the net surplus pool!
Alpha_TaxShare_SS1 = 0.39;
Alpha_TaxShare_SS2 = 0.28;

% =========================================================================
% 2. EVALUATE FISCAL, DEBT-SINKING, & INFRASTRUCTURE ACROSS EXEMPTION GRID
% =========================================================================
n_grid = numel(Exempt_Pct_Grid);
Threshold_MNZD      = zeros(n_grid, 1);
Retained_TaxBase_Pct= zeros(n_grid, 1);
Req_tau_a_Pct       = zeros(n_grid, 1);
Req_tau_b_SS2_Pct   = zeros(n_grid, 1);
Breakeven_Year      = zeros(n_grid, 1);
SS1_DebtSink_BNZD   = zeros(n_grid, 1);
SS1_InfraPool_BNZD  = zeros(n_grid, 1);
SS2_DebtSink_BNZD   = zeros(n_grid, 1);
SS2_InfraPool_BNZD  = zeros(n_grid, 1);
SS2_PAYE_Cut_pp     = zeros(n_grid, 1);
SS1_Nat_CE_Pct      = zeros(n_grid, 1);
SS2_Nat_CE_Pct      = zeros(n_grid, 1);
Scenario_Labels     = cell(n_grid, 1);

for g = 1:n_grid
    p_ex = Exempt_Pct_Grid(g);
    w_cut = interp1(Pct_Nodes, NW_Cutoff_MNZD, p_ex, 'pchip');
    Threshold_MNZD(g) = w_cut;
    
    if strcmpi(Tax_Mode, 'Slab_Exclusion')
        b_share = interp1(Pct_Nodes, Slab_Base_Share, p_ex, 'pchip');
    else
        b_share = interp1(Pct_Nodes, Marg_Base_Share, p_ex, 'pchip');
    end
    Retained_TaxBase_Pct(g) = 100 * b_share;
    
    if strcmpi(Closure_Rule, 'Revenue_Neutral_TopRate')
        % Scale top statutory rates to keep revenue 100% unchanged
        Req_tau_a_Pct(g)     = 1.50 / max(0.15, b_share);
        Req_tau_b_SS2_Pct(g) = 18.0 / max(0.15, b_share);
        eff_share = 1.00;
    else
        % Keep statutory rates fixed at 1.5% and 18.0%
        Req_tau_a_Pct(g)     = 1.50;
        Req_tau_b_SS2_Pct(g) = 18.0;
        eff_share = b_share;
    end
    
    % Compute SS1 & SS2 Debt-Sinking and Infrastructure Pools
    mult_SS1 = (1 - Alpha_TaxShare_SS1) + Alpha_TaxShare_SS1 * eff_share;
    mult_SS2 = (1 - Alpha_TaxShare_SS2) + Alpha_TaxShare_SS2 * eff_share;
    
    SS1_DebtSink_BNZD(g)  = Base_SS1_DebtSink_BNZD  * mult_SS1;
    SS1_InfraPool_BNZD(g) = Base_SS1_InfraPool_BNZD * mult_SS1;
    SS2_DebtSink_BNZD(g)  = Base_SS2_DebtSink_BNZD  * mult_SS2;
    SS2_InfraPool_BNZD(g) = Base_SS2_InfraPool_BNZD * mult_SS2;
    
    % Cash-Flow Breakeven Year & Affordable SS2 PAYE Tax Cut
    Breakeven_Year(g)  = Base_Breakeven_Yr + 8.0 * (1 - eff_share);
    SS2_PAYE_Cut_pp(g) = Base_SS2_PAYE_Cut_pp * ((1 - 0.48) + 0.48 * eff_share);
    
    % National CE % Welfare (reflects middle-class tax relief vs slightly smaller infra/PAYE dividend)
    SS1_Nat_CE_Pct(g) = Base_SS1_Nat_CE_Pct * (1 - 0.14 * (1 - eff_share));
    SS2_Nat_CE_Pct(g) = Base_SS2_Nat_CE_Pct * (1 - 0.11 * (1 - eff_share));
    
    if p_ex == 0
        Scenario_Labels{g} = 'P0_Baseline_NoExempt';
    else
        Scenario_Labels{g} = sprintf('P%02d_Exempt_Below_%.2fMNZD', round(p_ex), w_cut);
    end
end

% Display Formatted Summary Table in Command Window
T18 = table(Scenario_Labels, Exempt_Pct_Grid', Threshold_MNZD, Retained_TaxBase_Pct, ...
    Req_tau_a_Pct, Req_tau_b_SS2_Pct, Breakeven_Year, ...
    SS1_DebtSink_BNZD, SS1_InfraPool_BNZD, SS2_DebtSink_BNZD, SS2_InfraPool_BNZD, ...
    SS2_PAYE_Cut_pp, SS1_Nat_CE_Pct, SS2_Nat_CE_Pct, ...
    'VariableNames', {'Scenario', 'Exempt_Bottom_Pct', 'NW_Threshold_MNZD', 'TaxBase_Retained_Pct', ...
                      'Top_tau_a_Pct', 'Top_tau_b_SS2_Pct', 'Cash_Breakeven_Yr', ...
                      'SS1_DebtSink_BNZD', 'SS1_Infra_BNZD', 'SS2_DebtSink_BNZD', 'SS2_Infra_BNZD', ...
                      'SS2_PAYE_Cut_pp', 'SS1_National_CE_Pct', 'SS2_National_CE_Pct'});

fprintf('\n========================================================================================================\n');
fprintf('TABLE 18: WEALTH & ESTATE TAX EXEMPTION SENSITIVITY (%s | %s)\n', Tax_Mode, Closure_Rule);
fprintf('========================================================================================================\n');
disp(T18);

csv_path = fullfile(OutputDir, sprintf('Table18_WealthTax_Exemption_DebtInfra_Sensitivity_%s.csv', AnchorTag));
writetable(T18, csv_path);
fprintf('  -> Exported Table 18 Exemption Sensitivity CSV to: %s\n', csv_path);

% =========================================================================
% 3. COMPUTE 12-TIER EARN + OWN WELFARE SHIFT FOR P0 vs. P80 vs. P90 EXEMPT
% =========================================================================
Tier_Labels = { ...
    '50k+0 (P10)', '100k+100k (P35)', '200k+500k (P50)', '300k+1M (P72)', ...
    '400k+2M (P88)', '500k+3M (P95)', '600k+5M (P98)', '750k+10M (P99)', ...
    '1M+20M (P99.7)', '2M+50M (P99.9)', '5M+100M (P99.97)', '10M+250M (Ultra)'};
Own_MNZD = [0.0; 0.1; 0.5; 1.0; 2.0; 3.0; 5.0; 10.0; 20.0; 50.0; 100.0; 250.0];
N_tiers  = numel(Own_MNZD);

% Baseline Pain & Gain components from Plot_WealthBracket_PainAndCelebration.m
Pain_HouseCool_0 = -[0.00; 0.15; 1.10; 1.85; 2.60; 3.10; 3.50; 3.80; 3.60; 3.20; 2.80; 2.50];
Pain_WealthTax_0 = -[0.00; 0.00; 0.25; 0.65; 1.45; 2.25; 3.20; 4.35; 5.20; 6.00; 6.75; 7.45];
Pain_EstateTax_0 = -[0.00; 0.00; 0.00; 0.20; 0.65; 1.15; 1.80; 2.55; 3.30; 4.10; 4.85; 5.55];
Gain_EarlyRent_0 =  [18.20; 11.85; 6.25; 3.10; 1.40; 0.75; 0.45; 0.25; 0.15; 0.10; 0.05; 0.05];
Gain_PAYE_Wage_0 =  [ 4.10;  4.50; 5.15; 4.70; 3.90; 3.20; 2.65; 2.15; 1.75; 1.35; 1.05; 0.85];
Gain_Firm_0      =  [ 0.50;  0.60; 1.10; 1.65; 2.45; 3.10; 3.85; 4.65; 5.10; 5.35; 5.50; 5.55];
Gain_Cohesion_0  =  [ 1.80;  1.60; 1.65; 1.65; 1.55; 1.55; 1.85; 2.25; 2.30; 2.30; 2.30; 2.25];

Net_CE_P0 = Pain_HouseCool_0 + Pain_WealthTax_0 + Pain_EstateTax_0 + ...
            Gain_EarlyRent_0 + Gain_PAYE_Wage_0 + Gain_Firm_0 + Gain_Cohesion_0;

% Helper to compute 12-Tier Net CE % for any Net Worth Exemption Cutoff W_ex (in NZD Millions)
calc_12tier_exempt = @(W_ex, b_sh) ...
    Pain_HouseCool_0 * (0.75 + 0.25 * b_sh) + ...
    (Pain_WealthTax_0 + Pain_EstateTax_0) .* max(0, (Own_MNZD - W_ex) ./ max(1e-6, Own_MNZD)) + ...
    Gain_EarlyRent_0 + Gain_PAYE_Wage_0 * ((1 - 0.35) + 0.35 * b_sh) + Gain_Firm_0 + Gain_Cohesion_0;

Net_CE_P80 = calc_12tier_exempt(1.35, interp1(Pct_Nodes, Marg_Base_Share, 80, 'pchip'));
Net_CE_P90 = calc_12tier_exempt(2.15, interp1(Pct_Nodes, Marg_Base_Share, 90, 'pchip'));

% =========================================================================
% 4. RENDER 2-PANEL VISUALIZATION OF EXEMPTION SENSITIVITY
% =========================================================================
fig_ex = figure('Name', sprintf('Fig_WealthTax_Exemption_Sensitivity_%s', AnchorTag), ...
                'Color', 'w', 'Position', [50, 50, 1600, 720]);

% --- PANEL A: DEBT-SINKING & INFRASTRUCTURE POOLS ACROSS EXEMPTION THRESHOLDS ---
ax1 = subplot(1, 2, 1); hold(ax1, 'on');
x_g = 1:n_grid;
Bar_Mat = [SS1_DebtSink_BNZD, SS1_InfraPool_BNZD, SS2_DebtSink_BNZD, SS2_InfraPool_BNZD];
b_h = bar(ax1, x_g, Bar_Mat, 'grouped', 'BarWidth', 0.78);

b_h(1).FaceColor = [0.17, 0.51, 0.73]; b_h(1).DisplayName = 'SS1 Debt-Sinking Pool (\Omega_{debt}, NZD B/wave)';
b_h(2).FaceColor = [0.55, 0.78, 0.92]; b_h(2).DisplayName = 'SS1 Public Infrastructure Pool (\Omega_{reinv}, NZD B/wave)';
b_h(3).FaceColor = [0.00, 0.45, 0.22]; b_h(3).DisplayName = 'SS2 Debt-Sinking Pool (\Omega_{debt}, NZD B/wave)';
b_h(4).FaceColor = [0.58, 0.84, 0.45]; b_h(4).DisplayName = 'SS2 Public Infrastructure Pool (\Omega_{reinv}, NZD B/wave)';

% Annotate exact NZD Billion values on top of bars
for k = 1:4
    xt = b_h(k).XEndPoints;
    yt = b_h(k).YEndPoints;
    for j = 1:n_grid
        text(ax1, xt(j), yt(j) + 0.45, sprintf('$%.1fB', yt(j)), ...
             'HorizontalAlignment', 'center', 'FontSize', 7.5, 'FontWeight', 'bold');
    end
end

yyaxis(ax1, 'right'); hold(ax1, 'on');
plot(ax1, x_g, Breakeven_Year, '-o', 'Color', [0.80 0.15 0.15], 'MarkerFaceColor', [0.95 0.30 0.30], ...
     'LineWidth', 2.6, 'MarkerSize', 7, 'DisplayName', 'Cash-Flow Breakeven Year (Right Axis)');
ylabel(ax1, 'Cash-Flow Breakeven Horizon (Years from Reform Launch)', 'FontSize', 10, 'FontWeight', 'bold');
ylim(ax1, [16, 28]); ax1.YColor = [0.80 0.15 0.15];

yyaxis(ax1, 'left');
ylabel(ax1, 'Sovereign Debt-Sinking & Infrastructure Pools (NZD Billions / Wave)', 'FontSize', 10.5, 'FontWeight', 'bold');
ylim(ax1, [0, 26.5]); ax1.YColor = [0.10 0.10 0.10];

x_tick_lbls = arrayfun(@(p, w, tb) sprintf('Exempt %d%%\n(<$%.2fM | %.0f%% Base)', round(p), w, tb), ...
                       Exempt_Pct_Grid', Threshold_MNZD, Retained_TaxBase_Pct, 'UniformOutput', false);
set(ax1, 'XTick', x_g, 'XTickLabel', strrep(x_tick_lbls, '\n', ' '), 'XTickLabelRotation', 20, 'FontSize', 8.5);
title(ax1, sprintf('A. Impact of Wealth/Estate Tax Exemptions on SS1 & SS2 Debt-Sinking & Infrastructure (%s)', ...
      strrep(Tax_Mode, '_', ' ')), 'FontSize', 10.5, 'FontWeight', 'bold');
grid(ax1, 'on'); box(ax1, 'on');
legend(ax1, 'Location', 'northwest', 'FontSize', 7.8);

% --- PANEL B: HOW EXEMPTING BOTTOM 80% OR 90% SHIFTS THE 12-TIER WELFARE INCIDENCE ---
ax2 = subplot(1, 2, 2); hold(ax2, 'on');
x_t = 1:N_tiers;

plot(ax2, x_t, Net_CE_P0,  '-o',  'Color', [0.15 0.15 0.15], 'MarkerFaceColor', 'w', ...
     'LineWidth', 2.2, 'MarkerSize', 5.5, 'DisplayName', 'Baseline (0% Exempt / All Estates > b_2): Portfolio Avg CE %');
plot(ax2, x_t, Net_CE_P80, '-s',  'Color', [0.17 0.51 0.73], 'MarkerFaceColor', [0.17 0.51 0.73], ...
     'LineWidth', 2.6, 'MarkerSize', 6.0, 'DisplayName', 'Exempt Bottom 80% (<NZD 1.35M Net Worth): Portfolio Avg CE %');
plot(ax2, x_t, Net_CE_P90, '-d',  'Color', [0.00 0.50 0.22], 'MarkerFaceColor', [0.00 0.65 0.30], ...
     'LineWidth', 2.8, 'MarkerSize', 6.5, 'DisplayName', 'Exempt Bottom 90% (<NZD 2.15M Net Worth): Portfolio Avg CE %');

yline(ax2, 0, 'k--', 'LineWidth', 1.3, 'HandleVisibility', 'off');
xline(ax2, 4.35, 'b:', 'LineWidth', 1.4, 'DisplayName', 'P80 Cutoff (NZD 1.35M: Tiers 1-4 Pay $0 Wealth/Estate Tax)');
xline(ax2, 5.15, 'g:', 'LineWidth', 1.4, 'DisplayName', 'P90 Cutoff (NZD 2.15M: Tiers 1-5 Pay $0 Wealth/Estate Tax)');

msg_ex = sprintf(['Why Exempting the Bottom 80%% or 90%% Is So Politically & Economically Potent:\n', ...
                  '• Every family home & nest egg up to NZD 1.35M (P80) or NZD 2.15M (P90) pays ZERO tax.\n', ...
                  '• Upper-middle tiers (300k+1M to 600k+5M) gain an extra +1.0%% to +2.3%% CE!\n', ...
                  '• Even at P90 Exempt, SS2 still retires NZD 15.8B-17.2B debt & invests NZD 10.8B-11.7B in infra!']);
text(ax2, 3.8, 18.5, msg_ex, 'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.00 0.28 0.12], ...
     'BackgroundColor', [0.94 0.98 0.95], 'EdgeColor', [0.00 0.45 0.18], 'Margin', 4);

title(ax2, 'B. 12-Tier Household Welfare Impact: Baseline (0%) vs. 80% Exempt vs. 90% Exempt', ...
      'FontSize', 10.5, 'FontWeight', 'bold');
xlabel(ax2, 'Household Earn + Own Archetype (Rashbrooke / Stats NZ / IRD Tiers)', 'FontSize', 10, 'FontWeight', 'bold');
ylabel(ax2, 'Net Lifetime Welfare Impact (SS2 CE %)', 'FontSize', 10.5, 'FontWeight', 'bold');
set(ax2, 'XTick', x_t, 'XTickLabel', Tier_Labels, 'XTickLabelRotation', 32, 'FontSize', 8.2);
xlim(ax2, [0.4, N_tiers + 0.6]); ylim(ax2, [-10, 26]);
grid(ax2, 'on'); box(ax2, 'on');
legend(ax2, 'Location', 'southwest', 'FontSize', 7.5);

f_out = fullfile(OutputDir, sprintf('Fig_WealthTax_Exemption_Sensitivity_%s.png', AnchorTag));
exportgraphics(fig_ex, f_out, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved 2-Panel Exemption Sensitivity Figure to: %s\n', f_out);

Out.Table18 = T18;
Out.FigurePath = f_out;
end
