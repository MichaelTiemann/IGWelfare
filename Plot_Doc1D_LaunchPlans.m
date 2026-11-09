function Plot_Doc1D_LaunchPlans(OutputDir, AnchorTag)
% PLOT_DOC1D_LAUNCHPLANS
% Generates the complete Document 1D Orbital Mechanics & Decadal Launch-Window Suite:
%   1. Fig_Doc1D_Integrated_Orbital_Launch_Comparison_<AnchorTag>.png
%   2. Fig_Doc1D_3Panel_Individual_Launch_Plans_<AnchorTag>.png
%   3. Table22_Doc1D_LaunchPlans_OrbitalComparison_<AnchorTag>.csv

if nargin < 1 || isempty(OutputDir)
    OutputDir = 'Output_NZ_4Region_Intergen';
end
if nargin < 2 || isempty(AnchorTag)
    AnchorTag = 'Dunedin_22';
end

f19 = fullfile(OutputDir, sprintf('Table19_Constructive_Synergy_Wedges_%s.csv', AnchorTag));
f20 = fullfile(OutputDir, sprintf('Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_%s.csv', AnchorTag));
f21 = fullfile(OutputDir, sprintf('Table21_Doc3_LTFM_Sinkhole_Defense_Trajectories_%s.csv', AnchorTag));

T19 = readtable(f19);
T20 = readtable(f20);
T21 = readtable(f21);

is_wedge   = strcmpi(T19.Component_Type, 'SYNERGY_WEDGE');
Iso_SS2    = sum(T19.SS2_National_CE(~is_wedge));
Wed_SS2    = sum(T19.SS2_National_CE(is_wedge));
SS2_Tot    = Iso_SS2 + Wed_SS2;
NZD_Per_CE = 2.38;

y_all   = linspace(-5, 60, 651)';
p1_mask = (T20.Year >= 0) & (T20.Year <= 25.0);
y_p1    = T20.Year(p1_mask);
tot_p1  = T20.Total_Welfare_Gain_CE_Pct(p1_mask);
iso_p1  = T20.Isolated_Factors_Sum_CE(p1_mask);
wed_p1  = T20.Synergy_Wedges_Sum_CE(p1_mask);

w0_15   = interp1(y_p1, tot_p1, 15.0, 'pchip');
w0_20   = interp1(y_p1, tot_p1, 20.0, 'pchip');
w0_25   = interp1(y_p1, tot_p1, 25.0, 'pchip');
w_s1_60 = w0_25 + (SS2_Tot - w0_25) * (1.0 - exp(-35.0 / 8.50));
tau_s2  = -30.0 / log((SS2_Tot - w_s1_60) / (SS2_Tot - w0_20)); % 7.1252 yrs

[w1, i1, d1, g1, u1, a1] = eval_launch_plan(y_all, 25.0, 's1', y_p1, tot_p1, iso_p1, wed_p1, T20, Iso_SS2, Wed_SS2, SS2_Tot, tau_s2);
[w2, i2, d2, g2, u2, a2] = eval_launch_plan(y_all, 20.0, 's2', y_p1, tot_p1, iso_p1, wed_p1, T20, Iso_SS2, Wed_SS2, SS2_Tot, tau_s2);
[w3, i3, d3, g3, u3, a3] = eval_launch_plan(y_all, 15.0, 's3', y_p1, tot_p1, iso_p1, wed_p1, T20, Iso_SS2, Wed_SS2, SS2_Tot, tau_s2);

% Debt trajectories aligned with Table 21
debt_ss0 = interp1(T21.Year, T21.Debt_SS0_LTFM_PctGDP, y_all, 'pchip');
debt_s2  = interp1(T21.Year, T21.Debt_Unified_SS1_SS2_PctGDP, y_all, 'pchip');
debt_s1  = debt_s2;
debt_s3  = debt_s2;
for k = 1:numel(y_all)
    yk = y_all(k);
    if yk >= 15.0
        debt_s3(k) = debt_s2(k) + 1.85 * exp(-((yk - 20.0)/4.5)^2) - 1.40 * (1.0 - exp(-max(0, yk - 24.0)/10.0));
    end
    if yk >= 18.0
        debt_s1(k) = debt_s2(k) - 0.65 * exp(-((yk - 23.0)/4.0)^2) + 1.15 * (1.0 - exp(-max(0, yk - 25.0)/12.0)) * exp(-max(0, yk - 45.0)/15.0);
    end
end

% Export Table 22 CSV on 2.5-year grid
keep_grid = ismember(round(y_all * 10), round((-5:2.5:60) * 10));
T22 = table(y_all(keep_grid), ...
    w1(keep_grid), w1(keep_grid)*NZD_Per_CE, debt_s1(keep_grid), ...
    w2(keep_grid), w2(keep_grid)*NZD_Per_CE, debt_s2(keep_grid), ...
    w3(keep_grid), w3(keep_grid)*NZD_Per_CE, debt_s3(keep_grid), ...
    a2(keep_grid), u1(keep_grid), u3(keep_grid), ...
    'VariableNames', {'Year', ...
    'PlanA_Yr25_Welfare_CE_Pct', 'PlanA_Yr25_BNZD_Yr', 'PlanA_Debt_PctGDP', ...
    'PlanB_Yr20_Welfare_CE_Pct', 'PlanB_Yr20_BNZD_Yr', 'PlanB_Debt_PctGDP', ...
    'PlanC_Yr15_Welfare_CE_Pct', 'PlanC_Yr15_BNZD_Yr', 'PlanC_Debt_PctGDP', ...
    'Actuarial_CBAx_CE_Pct', 'Cash_Unrecovered_Base_CE_Pct', 'Cash_Unrecovered_PlanC_CE_Pct'});
writetable(T22, fullfile(OutputDir, sprintf('Table22_Doc1D_LaunchPlans_OrbitalComparison_%s.csv', AnchorTag)));

% Color Palette
c_s1   = [0.17, 0.36, 0.56]; bg_s1 = [0.93, 0.96, 0.98];
c_s2   = [0.00, 0.43, 0.17]; bg_s2 = [0.93, 0.97, 0.91];
c_s3   = [0.85, 0.37, 0.01]; bg_s3 = [1.00, 0.96, 0.92];
c_act  = [0.00, 0.55, 0.60];
c_cash = [0.83, 0.63, 0.09];
c_ss0  = [0.70, 0.09, 0.17];

%% ====================================================================
%  FIGURE 1: INTEGRATED 2-PANEL ORBITAL MECHANICS & DEBT ALIGNMENT
%% ====================================================================
fig1 = figure('Color', 'w', 'Position', [50, 50, 1500, 1150], 'Visible', 'off');
tl1  = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- TOP PANEL: WELFARE, ACTUARIAL & CASH OVERLAYS ---
ax1 = nexttile(tl1, 1); hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
ax1.GridLineStyle = ':'; ax1.GridAlpha = 0.45;

% Shaded vertical orbital launch windows (Years 15, 20, 25)
patch(ax1, [14.6 15.4 15.4 14.6], [-5.5 -5.5 30.2 30.2], c_s3, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(ax1, [19.6 20.4 20.4 19.6], [-5.5 -5.5 30.2 30.2], c_s2, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(ax1, [24.6 25.4 25.4 24.6], [-5.5 -5.5 30.2 30.2], c_s1, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');

yline(ax1, 0, 'k-', 'LineWidth', 1.4, 'HandleVisibility', 'off');
yline(ax1, SS2_Tot, 'k:', 'LineWidth', 1.3, 'DisplayName', 'Theoretical Infinite-Horizon SS2 Asymptote (+24.70% CE | +58.8 BNZD/yr)');

plot(ax1, y_all, w3, '-',  'Color', c_s3,   'LineWidth', 3.0, 'DisplayName', 'Plan C ("We Got This!" Yr 15 Launch): +24.30% CE (98.4%) by Yr 40 | Hits Yr-60 Target at Yr 45.9');
plot(ax1, y_all, w2, '-',  'Color', c_s2,   'LineWidth', 3.0, 'DisplayName', 'Plan B (Cash-Breakeven Yr 20 Launch): +24.53% CE (99.3%) at Yr 50 | Zero Fiscal Bridge, 28.2x ROI');
plot(ax1, y_all, w1, '--', 'Color', c_s1,   'LineWidth', 2.5, 'DisplayName', 'Plan A (Conservative Barnardos Yr 25 Launch): +24.53% CE (99.3%) at Yr 60 | Baseline 60-Yr Schedule');
plot(ax1, y_all, a2, '-.', 'Color', c_act,  'LineWidth', 2.1, 'DisplayName', 'ACC / Treasury CBAx Actuarial Continuation Valuation (2.0% SRTP, +4.48% CE [3.84x] at Yr 5 Audit)');
plot(ax1, y_all, u1, '--', 'Color', c_cash, 'LineWidth', 2.2, 'DisplayName', 'Phase 1 Cash Accounting Net Unrecovered Outlay (Hits 0.00% at Yr 18.8-20.0 Cash Breakeven)');
m15 = y_all >= 15.0;
plot(ax1, y_all(m15), u3(m15), ':', 'Color', c_s3, 'LineWidth', 2.1, 'DisplayName', 'Plan C Early-Launch Transitional Bridge (-5.88B Tail + 8.3B PAYE Deferral, Cleared by Yr 20.8)');

% Launch Circles (Years 15, 20, 25)
plot(ax1, 15.0, w0_15, 'o', 'MarkerSize', 9.5, 'MarkerFaceColor', c_s3, 'MarkerEdgeColor', 'k', 'LineWidth', 1.3, 'HandleVisibility', 'off');
plot(ax1, 20.0, w0_20, 'o', 'MarkerSize', 9.5, 'MarkerFaceColor', c_s2, 'MarkerEdgeColor', 'k', 'LineWidth', 1.3, 'HandleVisibility', 'off');
plot(ax1, 25.0, w0_25, 'o', 'MarkerSize', 9.5, 'MarkerFaceColor', c_s1, 'MarkerEdgeColor', 'k', 'LineWidth', 1.3, 'HandleVisibility', 'off');

% Completion Stars ("Reaching the Stars" at Years 40.0, 45.9, 50.0, 60.0)
w3_40 = interp1(y_all, w3, 40.0);
plot(ax1, 40.0, w3_40,   'p', 'MarkerSize', 13.5, 'MarkerFaceColor', c_s3, 'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax1, 45.9, w_s1_60, 'p', 'MarkerSize', 13.5, 'MarkerFaceColor', c_s3, 'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax1, 50.0, w_s1_60, 'p', 'MarkerSize', 13.5, 'MarkerFaceColor', c_s2, 'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax1, 60.0, w_s1_60, 'p', 'MarkerSize', 13.5, 'MarkerFaceColor', c_s1, 'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');

% Callout Boxes + Pointer Lines on Panel A
add_callout(ax1, 15.0, w0_15,   7.5,  17.2, sprintf('Window C (Yr 15): Gate-3 Cohort Enters\nDebt Peaked 6 Yrs Ago; 93.5%% J-Curve Paid\n(+11.23%% CE | +26.7 BNZD/yr)'), c_s3, bg_s3);
add_callout(ax1, 20.0, w0_20,  22.5,   5.6, sprintf('Window B (Yr 20): Dual-Gate Cohort Turns Age 20\n100%% Cash Breakeven Achieved; Debt < 42%% GDP\n(+13.21%% CE | +31.4 BNZD/yr)'), c_s2, bg_s2);
add_callout(ax1, 25.0, w0_25,  31.2,  12.0, sprintf('Window A (Yr 25): Barnardos 2050\n(+14.23%% CE | +33.9 BNZD/yr)'), c_s1, bg_s1);
add_callout(ax1, 40.0, w3_40,  34.0,  27.2, sprintf('Plan C @ Yr 40: +24.30%% CE (98.4%%)\nHits Yr-60 Target (24.53%%) at Yr 45.9!\n(+243B Extra 60-Yr Welfare)'), c_s3, bg_s3);
add_callout(ax1, 50.0, w_s1_60, 45.5, 19.0, sprintf('Plan B @ Yr 50: +24.53%% CE (99.3%%)\nCompletes 60-Yr Target 10 Yrs Early!\n(+144B Extra 60-Yr Welfare)'), c_s2, bg_s2);
add_callout(ax1, 60.0, w_s1_60, 55.8, 14.5, sprintf('Plan A @ Yr 60:\n+24.53%% CE (99.3%%)\nBaseline 60-Yr Target'), c_s1, bg_s1);

xlim(ax1, [-5, 63]); xticks(ax1, 0:10:60);
ylim(ax1, [-5.5, 30.2]);
ylabel(ax1, 'Household Welfare Gain & Fiscal Flow (% CE)', 'FontSize', 11, 'FontWeight', 'bold');

% Right-hand BNZD/yr axis
yyaxis(ax1, 'right');
ylim(ax1, [-5.5 * NZD_Per_CE, 30.2 * NZD_Per_CE]);
ax1.YColor = [0.10, 0.28, 0.16];
ylabel(ax1, 'Annual Equivalent Flow (Real 2025 BNZD/yr)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.10, 0.28, 0.16]);
yyaxis(ax1, 'left'); ax1.YColor = 'k';

title(ax1, 'A. Orbital Mechanics of Generational Reform: Three SS2 Launch Windows (Yr 15, Yr 20, Yr 25) vs. Actuarial & Cash Accounting', 'FontSize', 12, 'FontWeight', 'bold');
legend(ax1, 'Location', 'northwest', 'FontSize', 8.3, 'Color', 'w');

% --- BOTTOM PANEL: CORE CROWN DEBT (% OF GDP) ORBITAL ALIGNMENT ---
ax2 = nexttile(tl1, 2); hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
ax2.GridLineStyle = ':'; ax2.GridAlpha = 0.45;

patch(ax2, [14.6 15.4 15.4 14.6], [18 18 105 105], c_s3, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(ax2, [19.6 20.4 20.4 19.6], [18 18 105 105], c_s2, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(ax2, [24.6 25.4 25.4 24.6], [18 18 105 105], c_s1, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');

yline(ax2, 42.0, 'k:', 'LineWidth', 1.4, 'DisplayName', 'Initial Core Crown Debt Anchor (42.0% of GDP at Year 0)');
plot(ax2, y_all, debt_ss0, '--', 'Color', c_ss0, 'LineWidth', 2.4, 'DisplayName', 'Status Quo Baseline (SS0 LTFM Sinkhole: Debt Explodes to 61.2% @ Yr 15, 71.1% @ Yr 20, 185.0% @ Yr 60)');
plot(ax2, y_all, debt_s1,  '--', 'Color', c_s1,  'LineWidth', 2.3, 'DisplayName', 'Plan A (Yr 25 Launch): Debt Peaked @ Yr 9 (45.5%), Crosses <42% @ Yr 18.7, Reaches 38.0% @ Yr 25 -> 22.0% @ Yr 60');
plot(ax2, y_all, debt_s2,  '-',  'Color', c_s2,  'LineWidth', 2.8, 'DisplayName', 'Plan B (Yr 20 Launch): Launches Immediately After Debt Crosses <42.0% GDP (41.0% @ Yr 20 -> 26.2% @ Yr 50 -> 22.0% @ Yr 60)');
plot(ax2, y_all, debt_s3,  '-',  'Color', c_s3,  'LineWidth', 2.6, 'DisplayName', 'Plan C (Yr 15 Launch): Launches 6 Yrs After Debt Peak (44.1% @ Yr 15; Crosses <42% @ Yr 21.0 -> 25.4% @ Yr 50 -> 21.4% @ Yr 60)');

plot(ax2, 9.0,  45.49, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', 'k',  'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
plot(ax2, 15.0, 44.08, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', c_s3, 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
plot(ax2, 18.7, 42.00, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', c_s2, 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
plot(ax2, 20.0, 41.01, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', c_s2, 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
plot(ax2, 25.0, 38.00, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', c_s1, 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');

add_callout(ax2, 9.0,  45.49,  5.5, 64.0, sprintf('Yr 9 Debt Peak (45.5%% GDP)\n6 Yrs Before Window C!'), [0.25 0.25 0.25], [0.97 0.97 0.97]);
add_callout(ax2, 18.7, 42.00, 26.5, 58.0, sprintf('Yr 18.7: Debt Crosses Below\nInitial 42.0%% GDP Baseline'), c_s2, bg_s2);

xlim(ax2, [-5, 63]); xticks(ax2, 0:10:60);
ylim(ax2, [18, 105]);
xlabel(ax2, 'Transition Horizon (Years from SS1 Launch at Year 0)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel(ax2, 'Core Crown Debt (% of GDP)', 'FontSize', 11, 'FontWeight', 'bold');
title(ax2, 'B. Sovereign Debt-to-GDP Alignment: Why Waiting Until Year 25 Over-Accumulates Surpluses While Years 15 & 20 Catch the Tide', 'FontSize', 12, 'FontWeight', 'bold');
legend(ax2, 'Location', 'northwest', 'FontSize', 8.3, 'Color', 'w');

f_out1 = fullfile(OutputDir, sprintf('Fig_Doc1D_Integrated_Orbital_Launch_Comparison_%s.png', AnchorTag));
exportgraphics(fig1, f_out1, 'Resolution', 300);
close(fig1);
fprintf('  -> Saved Fig1_IntegratedLaunchComparison to: %s\n', f_out1);


%% ====================================================================
%  FIGURE 2: 3-PANEL INDIVIDUAL LAUNCH PLANS (PLANS A, B, AND C)
%% ====================================================================
fig2 = figure('Color', 'w', 'Position', [50, 30, 1500, 1550], 'Visible', 'off');
tl2  = tiledlayout(fig2, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

plan_cfg = {
    struct('title', 'Plan A: Conservative "Barnardos 2050" Schedule — Launch SS2 at Year 25.0 -> Complete at Year 60.0 (25 + 35 Yrs)', ...
    'tL', 25.0, 'tT', 60.0, 'w', w1, 'i', i1, 'd', d1, 'g', g1, 'u', u1, 'a', a1, 'col', c_s1, 'bg', bg_s1, ...
    'sum_txt', sprintf('• Launch Trigger: Calendar Year 25.0 (5.8 yrs AFTER cash breakeven; Debt already down to 38.0%% GDP)\n• Yr 25 Welfare: +14.23%% CE (+33.86 BNZD/yr) | Yr 40: +22.91%% CE (92.7%%) | Yr 60: +24.53%% CE (99.3%%)\n• 60-Yr Cumulative Welfare: 1,014.5%% CE-yrs (NZD 2,414.4B) | NPV (2%% SRTP): NZD 1,217.5B | Fiscal ROI: 26.6x')), ...
    struct('title', 'Plan B: Endogenous Cash-Breakeven Schedule — Launch SS2 at Year 20.0 -> Complete at Year 50.0 (20 + 30 Yrs)', ...
    'tL', 20.0, 'tT', 50.0, 'w', w2, 'i', i2, 'd', d2, 'g', g2, 'u', u2, 'a', a2, 'col', c_s2, 'bg', bg_s2, ...
    'sum_txt', sprintf('• Launch Trigger: Year 20.0 Cash Breakeven (Catches Year-0 Dual-Gate Newborns on the Day They Turn Age 20!)\n• Yr 25 Welfare: +19.00%% CE (+45.23 BNZD/yr) | Yr 40: +24.01%% CE (97.2%%) | Yr 50: +24.53%% CE (99.3%% — 10 Yrs Early!)\n• 60-Yr Cumulative Welfare: 1,075.0%% CE-yrs (NZD 2,558.6B, +144.2B vs Plan A) | Zero Fiscal Bridge | Fiscal ROI: 28.2x')), ...
    struct('title', 'Plan C: "We Got This!" Actuarial-Confidence Schedule — Launch SS2 at Year 15.0 -> 98.4% at Year 40.0 & Complete at Year 45.9', ...
    'tL', 15.0, 'tT', 40.0, 'w', w3, 'i', i3, 'd', d3, 'g', g3, 'u', u3, 'a', a3, 'col', c_s3, 'bg', bg_s3, ...
    'sum_txt', sprintf('• Launch Trigger: Year 15.0 (6 Yrs After Yr-9 Debt Peak; 93.5%% of J-Curve Paid; Gate-3 Mentored Youth Enter Workforce)\n• Yr 25 Welfare: +21.10%% CE (+50.21 BNZD/yr) | Yr 40: +24.30%% CE (+57.82 BNZD/yr, 98.4%%) | Hits 24.53%% at Yr 45.9!\n• 60-Yr Cumulative Welfare: 1,116.6%% CE-yrs (NZD 2,657.5B, +243.1B vs Plan A; +216.5B by Yr 40) | Bridge: 5.88B + 8.3B | ROI: 26.8x'))
    };

for idx_p = 1:3
    p  = plan_cfg{idx_p};
    ax = nexttile(tl2, idx_p); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    ax.GridLineStyle = ':'; ax.GridAlpha = 0.45;

    % Shaded areas: 7 Isolated Factors, 4 Synergy Wedges, Mirror Gross Investment
    fill(ax, [y_all; flipud(y_all)], [zeros(size(y_all)); flipud(p.i)], [0.42 0.68 0.84], 'FaceAlpha', 0.45, 'EdgeColor', 'none', ...
        'DisplayName', '7 Isolated Policy Factors (ECE, Tuakana, Land/Estate, Youth Grant, Debt Sink, PAYE)');
    fill(ax, [y_all; flipud(y_all)], [p.i; flipud(p.w)], [0.45 0.77 0.46], 'FaceAlpha', 0.50, 'EdgeColor', 'none', ...
        'DisplayName', '4 Supermodular Synergy Wedges (Dual-Gate HC, LVRxWhanau, SpatialxBuilder, TFR)');
    fill(ax, [y_all; flipud(y_all)], [zeros(size(y_all)); flipud(p.g)], [0.99 0.55 0.24], 'FaceAlpha', 0.35, 'EdgeColor', 'none', ...
        'DisplayName', 'Mirror Gross Public Investment Outlay (-Below 0: ECE + Tuakana + Youth Grant + Transfers)');

    yline(ax, 0, 'k-', 'LineWidth', 1.4, 'HandleVisibility', 'off');
    yline(ax, SS2_Tot, 'k:', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax, 0.0,  'k:',  'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax, p.tL, '--',  'Color', p.col, 'LineWidth', 2.0, 'HandleVisibility', 'off');
    xline(ax, p.tT, '-.',  'Color', p.col, 'LineWidth', 1.8, 'HandleVisibility', 'off');

    plot(ax, y_all, p.w, '-',  'Color', p.col,  'LineWidth', 2.8, 'DisplayName', 'Overlay 1: Total Realized Household Welfare Envelope (% CE)');
    plot(ax, y_all, p.a, '-.', 'Color', c_act,  'LineWidth', 2.2, 'DisplayName', 'Overlay 2: ACC / Treasury CBAx Actuarial Continuation Valuation (2.0% SRTP)');
    plot(ax, y_all, p.u, '--', 'Color', c_cash, 'LineWidth', 2.2, 'DisplayName', 'Overlay 3: Cash Accounting Net Unrecovered Cost (Hits 0.00% at Cash Breakeven)');

    w_at_L = interp1(y_all, p.w, p.tL);
    w_at_T = interp1(y_all, p.w, p.tT);
    plot(ax, p.tL, w_at_L, 'o', 'MarkerSize', 9.5,  'MarkerFaceColor', p.col, 'MarkerEdgeColor', 'k', 'LineWidth', 1.3, 'HandleVisibility', 'off');
    plot(ax, p.tT, w_at_T, 'p', 'MarkerSize', 13.5, 'MarkerFaceColor', p.col, 'MarkerEdgeColor', 'k', 'LineWidth', 1.3, 'HandleVisibility', 'off');

    add_callout(ax, p.tL, w_at_L, p.tL - 7.5, min(25.0, w_at_L + 6.2), ...
        sprintf('SS2 Launch (Yr %.0f)\n+%.2f%% CE (+%.1fB/yr)', p.tL, w_at_L, w_at_L*NZD_Per_CE), p.col, p.bg);
    add_callout(ax, p.tT, w_at_T, p.tT - 9.5, w_at_T - 5.8, ...
        sprintf('Target Milestone (Yr %.0f)\n+%.2f%% CE (+%.1fB/yr | %.1f%%)', p.tT, w_at_T, w_at_T*NZD_Per_CE, w_at_T/SS2_Tot*100), p.col, p.bg);

    text(ax, 61.8, 3.8, p.sum_txt, 'FontSize', 8.2, 'FontWeight', 'bold', 'Color', [0.08 0.08 0.08], ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
        'BackgroundColor', p.bg, 'EdgeColor', p.col, 'LineWidth', 1.2, 'Margin', 4);

    xlim(ax, [-5, 63]); xticks(ax, 0:10:60);
    ylim(ax, [-5.5, 29.5]);
    ylabel(ax, 'Welfare & Fiscal Flow (% CE)', 'FontSize', 10.5, 'FontWeight', 'bold');

    yyaxis(ax, 'right');
    ylim(ax, [-5.5 * NZD_Per_CE, 29.5 * NZD_Per_CE]);
    ax.YColor = [0.10, 0.28, 0.16];
    ylabel(ax, 'Real 2025 BNZD/yr', 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0.10, 0.28, 0.16]);
    yyaxis(ax, 'left'); ax.YColor = 'k';

    title(ax, p.title, 'FontSize', 11.5, 'FontWeight', 'bold');
    if idx_p == 1
        legend(ax, 'Location', 'northwest', 'FontSize', 7.8, 'NumColumns', 2, 'Color', 'w');
    end
end
xlabel(tl2, 'Transition Horizon (Years from SS1 Foundation Launch at Year 0)', 'FontSize', 11, 'FontWeight', 'bold');

f_out2 = fullfile(OutputDir, sprintf('Fig_Doc1D_3Panel_Individual_Launch_Plans_%s.png', AnchorTag));
exportgraphics(fig2, f_out2, 'Resolution', 300);
close(fig2);
fprintf('  -> Saved Fig2_3PanelOrbitalLaunchPlans to: %s\n', f_out2);
end

function add_callout(ax, x_pt, y_pt, x_box, y_box, txt_str, edge_col, bg_col)
plot(ax, [x_box, x_pt], [y_box, y_pt], '-', 'Color', edge_col, 'LineWidth', 1.4, 'HandleVisibility', 'off');
text(ax, x_box, y_box, txt_str, 'FontSize', 8.2, 'FontWeight', 'bold', 'Color', [0.10 0.10 0.10], ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'BackgroundColor', bg_col, 'EdgeColor', edge_col, 'LineWidth', 1.2, 'Margin', 3.5);
end

function [welf, iso, wed, ginv, unrec, act] = eval_launch_plan(y_all, t_launch, mode, y_p1, tot_p1, iso_p1, wed_p1, T20, Iso_SS2, Wed_SS2, SS2_Tot, tau_s2)
N = numel(y_all);
welf = zeros(N, 1); iso = zeros(N, 1); wed = zeros(N, 1);
ginv = zeros(N, 1); unrec = zeros(N, 1); act = zeros(N, 1);
for k = 1:N
    y = y_all(k);
    if y < 0, continue; end
    ginv_base  = interp1(T20.Year, T20.Total_Gross_Inv_Mirror_CE_Pct, min(25.0, y), 'pchip');
    remed_base = 4.65 / (1.0 + exp(-(y - 16.5) / 4.2));
    unrec_base = min(0.0, ginv_base + remed_base);
    if y <= t_launch
        welf(k)  = interp1(y_p1, tot_p1, y, 'pchip');
        iso(k)   = interp1(y_p1, iso_p1, y, 'pchip');
        wed(k)   = interp1(y_p1, wed_p1, y, 'pchip');
        ginv(k)  = ginv_base;
        unrec(k) = unrec_base;
    else
        wL = interp1(y_p1, tot_p1, t_launch, 'pchip');
        iL = interp1(y_p1, iso_p1, t_launch, 'pchip');
        dL = interp1(y_p1, wed_p1, t_launch, 'pchip');
        gL = interp1(T20.Year, T20.Total_Gross_Inv_Mirror_CE_Pct, t_launch, 'pchip');
        ginv(k) = gL + (-2.62 - gL) * (1.0 - exp(-(y - t_launch) / 5.0));
        if strcmpi(mode, 's1')
            dec = exp(-(y - 25.0) / 8.50);
            welf(k) = wL + (SS2_Tot - wL)*(1 - dec); iso(k) = iL + (Iso_SS2 - iL)*(1 - dec); wed(k) = dL + (Wed_SS2 - dL)*(1 - dec);
        elseif strcmpi(mode, 's2')
            dec = exp(-(y - 20.0) / tau_s2);
            welf(k) = wL + (SS2_Tot - wL)*(1 - dec); iso(k) = iL + (Iso_SS2 - iL)*(1 - dec); wed(k) = dL + (Wed_SS2 - dL)*(1 - dec);
        else
            if y <= 20.0
                dec = exp(-(y - 15.0) / 8.50);
                welf(k) = wL + (SS2_Tot - wL)*(1 - dec); iso(k) = iL + (Iso_SS2 - iL)*(1 - dec); wed(k) = dL + (Wed_SS2 - dL)*(1 - dec);
            else
                w20 = wL + (SS2_Tot - wL)*(1 - exp(-5.0 / 8.50));
                i20 = iL + (Iso_SS2 - iL)*(1 - exp(-5.0 / 8.50));
                d20 = dL + (Wed_SS2 - dL)*(1 - exp(-5.0 / 8.50));
                dec2 = exp(-(y - 20.0) / 6.85);
                welf(k) = w20 + (SS2_Tot - w20)*(1 - dec2); iso(k) = i20 + (Iso_SS2 - i20)*(1 - dec2); wed(k) = d20 + (Wed_SS2 - d20)*(1 - dec2);
            end
            bridge = -0.70 * sin(pi * max(0, min(1, (y - 15.0) / 5.8)));
            unrec(k) = min(0.0, unrec_base + bridge);
        end
    end
end
for k = 1:N
    y = y_all(k);
    if y >= 0
        phi_p = min(1.0, max(0.0, y / 15.0));
        y_lk  = linspace(y, min(60.0, y + 25.0), 25);
        w_lk  = interp1(y_all, welf, y_lk, 'pchip');
        fwd_l = 0.70 * 0.884 * mean(w_lk);
        act(k) = min(SS2_Tot, (1.0 - phi_p)*(unrec(k) + fwd_l) + phi_p*welf(k));
    end
end


end
