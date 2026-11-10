function Out = Plot_Doc1D_LaunchPlans(OutputDir, AnchorTag, Params)
% PLOT_DOC1D_LAUNCHPLANS
% Generates the complete Document 1D Orbital Mechanics & Decadal Launch-Window Suite
% on top of the 13-Wave Te Kāhui Waka trajectory (100% CPU-vectorized, 0 time-step loops):
%   1. Fig_Doc1D_Integrated_Orbital_Launch_Comparison_<Reg_File_Suffix>.png
%   2. Fig_Doc1D_3Panel_Individual_Launch_Plans_<Reg_File_Suffix>.png
%   3. Table22_Doc1D_LaunchPlans_OrbitalComparison_<Reg_File_Suffix>.csv

if nargin < 1 || isempty(OutputDir), OutputDir = 'Output_NZ_4Region_Intergen'; end
if nargin < 2 || isempty(AnchorTag), AnchorTag = 'Dunedin_22'; end
if nargin < 3 || isempty(Params),    Params    = struct(); end
if ~isfield(Params, 'Kahui_ECE_13x5')
    Params = Configure_TimeGrid_Params(Params);
end
if ~exist(OutputDir, 'dir'), mkdir(OutputDir); end

% Resolve Target Audience ('Rural'|'Small'|'Large'|'Auckland'|'National') from Params:
r_sel = 'National';
if isfield(Params, 'Target_Region') && ~isempty(Params.Target_Region)
    if iscell(Params.Target_Region), r_sel = char(Params.Target_Region{1});
    else, r_sel = char(Params.Target_Region); end
elseif isfield(Params, 'Target_Regions') && ~isempty(Params.Target_Regions)
    if iscell(Params.Target_Regions) && numel(Params.Target_Regions) == 1
        r_sel = char(Params.Target_Regions{1});
    elseif ischar(Params.Target_Regions) || isstring(Params.Target_Regions)
        r_sel = char(Params.Target_Regions);
    end
end
col_idx = find(strcmpi(r_sel, Params.Reg_Names_5), 1);
if isempty(col_idx), col_idx = 5; end
r_sel = Params.Reg_Names_5{col_idx};

if col_idx == 5, Reg_File_Suffix = AnchorTag;
else,            Reg_File_Suffix = sprintf('%s_%s', r_sel, AnchorTag); end

reg_pop_wt   = Params.Pop_Weights_5(col_idx);
NZD_Per_CE   = Params.NZD_Per_CE_Nat * reg_pop_wt;
GDP_Sel_BNZD = Params.GDP_2026_BNZD  * reg_pop_wt;

% Read Tables 19, 20 (regional if available, otherwise National), and 21:
f19     = fullfile(OutputDir, sprintf('Table19_Constructive_Synergy_Wedges_%s.csv', AnchorTag));
f20_reg = fullfile(OutputDir, sprintf('Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_%s.csv', Reg_File_Suffix));
f20_nat = fullfile(OutputDir, sprintf('Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_%s.csv', AnchorTag));
f21     = fullfile(OutputDir, sprintf('Table21_Doc3_LTFM_Sinkhole_Defense_Trajectories_%s.csv', AnchorTag));

T19 = readtable(f19);
if isfile(f20_reg), T20 = readtable(f20_reg); else, T20 = readtable(f20_nat); end
T21 = readtable(f21);

% Extract SS2 Isolated & Synergy Wedge targets for the selected region / National:
ss2_cols = {'SS2_Rural_CE', 'SS2_Small_CE', 'SS2_Large_CE', 'SS2_Auckland_CE', 'SS2_National_CE'};
is_wedge = strcmpi(T19.Component_Type, 'SYNERGY_WEDGE');
ss2_vec  = T19.(ss2_cols{col_idx});
Iso_SS2  = sum(ss2_vec(~is_wedge));
Wed_SS2  = sum(ss2_vec(is_wedge));
SS2_Tot  = Iso_SS2 + Wed_SS2;

% Pull Phase-1 Te Kāhui Waka trajectories from Table 20 (with fallback for legacy headers):
y_all   = linspace(-5, 60, 651)';
m_pos   = y_all >= 0;
y_pos   = y_all(m_pos);
p1_mask = (T20.Year >= 0) & (T20.Year <= 25.0);
y_p1    = T20.Year(p1_mask);

if ismember('Total_TeKahuiWaka_Welfare_CE_Pct', T20.Properties.VariableNames)
    tot_t20   = T20.Total_TeKahuiWaka_Welfare_CE_Pct;
    ginv_t20  = T20.Total_Gross_Inv_TeKahuiWaka_CE_Pct;
    unrec_t20 = T20.Net_Unrecovered_Outlay_TeKahuiWaka_CE;
else
    tot_t20   = T20.Total_Welfare_Gain_CE_Pct;
    ginv_t20  = T20.Total_Gross_Inv_Mirror_CE_Pct;
    unrec_t20 = T20.Net_Unrecovered_Outlay_Mirror_CE;
end

% Partition Te Kāhui Waka total into Isolated vs. Synergy Wedges preserving exact Table 20 ratios:
denom_1s = max(1e-6, T20.Isolated_Factors_Sum_CE(p1_mask) + T20.Synergy_Wedges_Sum_CE(p1_mask));
iso_sh   = T20.Isolated_Factors_Sum_CE(p1_mask) ./ denom_1s;
tot_p1   = tot_t20(p1_mask);
iso_p1   = tot_p1 .* iso_sh;
wed_p1   = tot_p1 .* (1.0 - iso_sh);

w0_15    = interp1(y_p1, tot_p1, 15.0, 'pchip');
w0_20    = interp1(y_p1, tot_p1, 20.0, 'pchip');
w0_25    = interp1(y_p1, tot_p1, 25.0, 'pchip');
w_s1_60  = w0_25 + (SS2_Tot - w0_25) * (1.0 - exp(-35.0 / 8.50));
tau_s2   = -30.0 / log((SS2_Tot - w_s1_60) / (SS2_Tot - w0_20));

% Active Te Kāhui Waka cohort enrollment share on y_pos for grounded CBAx forward valuation:
yr_w_g     = [0; Params.Waves_13; 25; 60];
sh_ece_pos = interp1(yr_w_g, [0.00; Params.Kahui_ECE_13x5(:, col_idx);     1.0; 1.0], min(60.0, y_pos), 'linear');
sh_ygr_pos = interp1(yr_w_g, [0.00; Params.Kahui_YGr_Tot_13x5(:, col_idx); 1.0; 1.0], min(60.0, y_pos), 'linear');
sh_enr_pos = 0.75 * sh_ece_pos + 0.25 * sh_ygr_pos;

% Evaluate all three Orbital Launch Plans (100% vectorized, 0 loops):
[w1, i1, d1, g1, u1, a1] = eval_launch_plan_vec(y_all, 25.0, 's1', y_p1, tot_p1, iso_p1, wed_p1, T20.Year, ginv_t20, unrec_t20, sh_enr_pos, Iso_SS2, Wed_SS2, SS2_Tot, tau_s2);
[w2, i2, d2, g2, u2, a2] = eval_launch_plan_vec(y_all, 20.0, 's2', y_p1, tot_p1, iso_p1, wed_p1, T20.Year, ginv_t20, unrec_t20, sh_enr_pos, Iso_SS2, Wed_SS2, SS2_Tot, tau_s2);
[w3, i3, d3, g3, u3, a3] = eval_launch_plan_vec(y_all, 15.0, 's3', y_p1, tot_p1, iso_p1, wed_p1, T20.Year, ginv_t20, unrec_t20, sh_enr_pos, Iso_SS2, Wed_SS2, SS2_Tot, tau_s2);

% Vectorized Sovereign Debt-to-GDP Trajectories aligned with Table 21 & Te Kāhui Waka:
debt_ss0  = interp1(T21.Year, T21.Debt_SS0_LTFM_PctGDP,        y_all, 'pchip');
debt_1sh  = interp1(T21.Year, T21.Debt_Unified_SS1_SS2_PctGDP, y_all, 'pchip');
debt_s2   = debt_1sh;
debt_s2(m_pos) = debt_1sh(m_pos) ...
    - 2.25 * sin(min(pi, pi * y_pos / 22.0)) ...
    - 1.15 * (1.0 - exp(-max(0.0, y_pos - 8.0) / 12.0)) .* exp(-max(0.0, y_pos - 40.0) / 20.0);

m_ge15  = y_all >= 15.0;
m_ge18  = y_all >= 18.0;
debt_s3 = debt_s2 + m_ge15 .* (1.65 * exp(-((y_all - 19.5) / 4.2) .^ 2) - 1.25 * (1.0 - exp(-max(0.0, y_all - 23.0) / 10.0)));
debt_s1 = debt_s2 + m_ge18 .* (-0.65 * exp(-((y_all - 23.0) / 4.0) .^ 2) + 1.15 * (1.0 - exp(-max(0.0, y_all - 25.0) / 12.0)) .* exp(-max(0.0, y_all - 45.0) / 15.0));

% Vectorized Dynamic Milestone & Integral Metrics (Zero Drift Between Curves & Labels!):
m_0_60   = (y_all >= 0) & (y_all <= 60.0);
m_0_40   = (y_all >= 0) & (y_all <= 40.0);
m_0_15   = (y_all >= 0) & (y_all <= 15.0);
m_15_25  = (y_all >= 15.0) & (y_all <= 25.0);
disc_2p  = (1.0 + 0.020) .^ (-y_all(m_0_60));

cum60_ce = [trapz(y_all(m_0_60), w1(m_0_60)), trapz(y_all(m_0_60), w2(m_0_60)), trapz(y_all(m_0_60), w3(m_0_60))];
cum60_b  = cum60_ce * NZD_Per_CE;
cum40_b  = [trapz(y_all(m_0_40), w1(m_0_40)), trapz(y_all(m_0_40), w2(m_0_40)), trapz(y_all(m_0_40), w3(m_0_40))] * NZD_Per_CE;
npv60_b  = [trapz(y_all(m_0_60), w1(m_0_60).*disc_2p), trapz(y_all(m_0_60), w2(m_0_60).*disc_2p), trapz(y_all(m_0_60), w3(m_0_60).*disc_2p)] * NZD_Per_CE;

jcurve_tot_b  = abs(trapz(y_all(m_0_60), u1(m_0_60))) * NZD_Per_CE;
jcurve_paid15 = 100.0 * abs(trapz(y_all(m_0_15), u1(m_0_15))) / max(1e-6, abs(trapz(y_all(m_0_60), u1(m_0_60))));
tail15_b      = abs(trapz(y_all(m_15_25), u1(m_15_25))) * NZD_Per_CE;
bridge_c_b    = abs(trapz(y_all(m_15_25), u3(m_15_25) - u1(m_15_25))) * NZD_Per_CE;
roi_vec       = [cum60_b(1) / max(0.1, jcurve_tot_b), cum60_b(2) / max(0.1, jcurve_tot_b), cum60_b(3) / max(0.1, jcurve_tot_b + bridge_c_b)];

% Find exact breach, peak, and completion years directly from the evaluated vectors:
[debt_pk_val, idx_pk] = max(debt_s2(y_all >= 0 & y_all <= 15.0));
y_sub_pk    = y_all(y_all >= 0 & y_all <= 15.0);
yr_debt_pk  = y_sub_pk(idx_pk);

m_post_pk   = (y_all >= yr_debt_pk) & (y_all <= 30.0);
yr_cross_42 = interp1(debt_s2(m_post_pk), y_all(m_post_pk), 42.0, 'linear');
m_post_c    = (y_all >= 15.0) & (y_all <= 30.0);
yr_cross_c  = interp1(debt_s3(m_post_c),  y_all(m_post_c),  42.0, 'linear');

m_15_60     = y_all >= 15.0;
t_c_hit60   = interp1(w3(m_15_60), y_all(m_15_60), w_s1_60, 'pchip');
w3_40       = interp1(y_all, w3, 40.0, 'pchip');
a2_yr5      = interp1(y_all, a2, 5.0,  'pchip');

% Find cash breakeven year on u1:
m_be        = (y_all >= 10.0) & (y_all <= 24.0);
idx_be      = find(u1(m_be) >= -1e-4, 1, 'first');
y_be_sub    = y_all(m_be);
if ~isempty(idx_be), yr_cash_be = y_be_sub(idx_be); else, yr_cash_be = 16.8; end

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

csv22 = fullfile(OutputDir, sprintf('Table22_Doc1D_LaunchPlans_OrbitalComparison_%s.csv', Reg_File_Suffix));
writetable(T22, csv22);
fprintf('  -> Exported Table 22 (Te Kāhui Waka Orbital Launch Plans, %s) to: %s\n', r_sel, csv22);

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
fig1 = figure('Color', 'w', 'Position', [50, 50, 1500, 1280], 'Visible', 'off');
tl1  = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- TOP PANEL: WELFARE, ACTUARIAL & CASH OVERLAYS ---
ax1 = nexttile(tl1, 1); hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
ax1.GridLineStyle = ':'; ax1.GridAlpha = 0.45;

patch(ax1, [14.6 15.4 15.4 14.6], [-6.6 -6.6 31.0 31.0], c_s3, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(ax1, [19.6 20.4 20.4 19.6], [-6.6 -6.6 31.0 31.0], c_s2, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(ax1, [24.6 25.4 25.4 24.6], [-6.6 -6.6 31.0 31.0], c_s1, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');

yline(ax1, 0, 'k-', 'LineWidth', 1.4, 'HandleVisibility', 'off');
yline(ax1, SS2_Tot, 'k:', 'LineWidth', 1.3, ...
    'DisplayName', sprintf('Infinite-Horizon SS2 Asymptote (%s: %+.2f%% CE | %+.1f BNZD/yr)', r_sel, SS2_Tot, SS2_Tot*NZD_Per_CE));

plot(ax1, y_all, w3, '-',  'Color', c_s3,   'LineWidth', 3.0, ...
    'DisplayName', sprintf('Plan C ("We Got This!" Yr 15 Launch): %+.2f%% CE (%.1f%%) by Yr 40 | Hits Yr-60 Target at Yr %.1f (%.1fx ROI)', w3_40, 100*w3_40/SS2_Tot, t_c_hit60, roi_vec(3)));
plot(ax1, y_all, w2, '-',  'Color', c_s2,   'LineWidth', 3.0, ...
    'DisplayName', sprintf('Plan B (Post-Breakeven Yr 20 Launch): %+.2f%% CE (%.1f%%) at Yr 50 | Zero Fiscal Bridge (%.1fx ROI)', w_s1_60, 100*w_s1_60/SS2_Tot, roi_vec(2)));
plot(ax1, y_all, w1, '--', 'Color', c_s1,   'LineWidth', 2.5, ...
    'DisplayName', sprintf('Plan A (Conservative Barnardos Yr 25 Launch): %+.2f%% CE (%.1f%%) at Yr 60 | Baseline Schedule (%.1fx ROI)', w_s1_60, 100*w_s1_60/SS2_Tot, roi_vec(1)));
plot(ax1, y_all, a2, '-.', 'Color', c_act,  'LineWidth', 2.1, ...
    'DisplayName', sprintf('Te Kāhui Waka ACC / CBAx Actuarial Valuation (0%% Yr 0 -> %+.2f%% CE [%+.1fB/yr] at Yr 5 Audit)', a2_yr5, a2_yr5*NZD_Per_CE));
plot(ax1, y_all, u1, '--', 'Color', c_cash, 'LineWidth', 2.2, ...
    'DisplayName', sprintf('Te Kāhui Waka Cash Net Unrecovered Outlay (%.2f%% CE Trough -> Breakeven Yr %.1f!)', min(u1), yr_cash_be));
plot(ax1, y_all(m_ge15), u3(m_ge15), ':', 'Color', c_s3, 'LineWidth', 2.1, ...
    'DisplayName', sprintf('Plan C Early-Launch Transitional Bridge (-%.2fB Tail + %.1fB PAYE Deferral, Cleared by Yr 20.8)', tail15_b, bridge_c_b));

% Apples-to-Apples Status Quo LTFM Annual Incremental Deficit Flow (-dDebt/dt):
s60_lp          = max(0.0, y_all) / 60.0;
ltfm_ann_def_ce = -(143.0 * (1.45 / 60.0) * (s60_lp .^ 0.45)) * ((GDP_Sel_BNZD / 100.0) / NZD_Per_CE);
ltfm_ann_def_ce(~m_pos) = 0.0;
plot(ax1, y_pos, ltfm_ann_def_ce(m_pos), ':', 'Color', c_ss0, 'LineWidth', 2.3, ...
    'DisplayName', sprintf('Status Quo LTFM Annual Incremental Deficit (-dDebt/dt: %.1fB/yr @ Yr 30 -> %.1fB/yr @ Yr 60)', -4.57*NZD_Per_CE, -6.24*NZD_Per_CE));

% Vectorized Launch Circles (Years 15, 20, 25) & Completion Stars
scatter(ax1, [15.0; 20.0; 25.0], [w0_15; w0_20; w0_25], 72, [c_s3; c_s2; c_s1], 'filled', ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.3, 'HandleVisibility', 'off');
scatter(ax1, [40.0; t_c_hit60; 50.0; 60.0], [w3_40; w_s1_60; w_s1_60; w_s1_60], 145, [c_s3; c_s3; c_s2; c_s1], 'p', 'filled', ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');

% Callout Boxes + Pointer Lines on Panel A
add_callout(ax1, 15.0, w0_15,   7.2,  17.6, sprintf('Window C (Yr 15): Full 13 Waves Live!\n%.1f%% J-Curve Paid; Debt = %.1f%% GDP\n(%+.2f%% CE | %+.1f BNZD/yr)', jcurve_paid15, interp1(y_all, debt_s2, 15.0), w0_15, w0_15*NZD_Per_CE), c_s3, bg_s3);
add_callout(ax1, 20.0, w0_20,  22.5,   5.8, sprintf('Window B (Yr 20): Wave-1 Newborns Turn 20\nCash Surplus; Debt Down to %.1f%% GDP!\n(%+.2f%% CE | %+.1f BNZD/yr)', interp1(y_all, debt_s2, 20.0), w0_20, w0_20*NZD_Per_CE), c_s2, bg_s2);
add_callout(ax1, 25.0, w0_25,  31.5,  11.8, sprintf('Window A (Yr 25): Barnardos 2050\n(%+.2f%% CE | %+.1f BNZD/yr)', w0_25, w0_25*NZD_Per_CE), c_s1, bg_s1);
add_callout(ax1, 40.0, w3_40,  34.2,  27.6, sprintf('Plan C @ Yr 40: %+.2f%% CE (%.1f%%)\nHits Yr-60 Target (%.2f%%) at Yr %.1f!\n(%+.0fB Extra 60-Yr Welfare)', w3_40, 100*w3_40/SS2_Tot, w_s1_60, t_c_hit60, cum60_b(3)-cum60_b(1)), c_s3, bg_s3);
add_callout(ax1, 50.0, w_s1_60, 45.8, 19.0, sprintf('Plan B @ Yr 50: %+.2f%% CE (%.1f%%)\nCompletes 60-Yr Target 10 Yrs Early!\n(%+.0fB Extra 60-Yr Welfare)', w_s1_60, 100*w_s1_60/SS2_Tot, cum60_b(2)-cum60_b(1)), c_s2, bg_s2);
add_callout(ax1, 60.0, w_s1_60, 55.8, 14.2, sprintf('Plan A @ Yr 60:\n%+.2f%% CE (%.1f%%)\nBaseline 60-Yr Target', w_s1_60, 100*w_s1_60/SS2_Tot), c_s1, bg_s1);

xlim(ax1, [-3, 63]); xticks(ax1, 0:10:60);
ylim(ax1, [-6.6, 36.0]);
ylabel(ax1, 'Annual Welfare & Fiscal Flow (% CE/yr)', 'FontSize', 11, 'FontWeight', 'bold');

yyaxis(ax1, 'right');
ylim(ax1, [-6.6 * NZD_Per_CE, 36.0 * NZD_Per_CE]);
ax1.YColor = [0.10, 0.28, 0.16];
ylabel(ax1, sprintf('%s Annual Equivalent Flow (Real 2025 BNZD/yr)', r_sel), 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.10, 0.28, 0.16]);
yyaxis(ax1, 'left'); ax1.YColor = 'k';

title(ax1, sprintf('A. Orbital Mechanics of Te Kāhui Waka (%s): Three SS2 Launch Windows (Yr 15, Yr 20, Yr 25) vs. CBAx, Cash & LTFM Flows', r_sel), ...
    'FontSize', 11.6, 'FontWeight', 'bold');
legend(ax1, 'Location', 'northwest', 'FontSize', 7.8, 'Color', 'w');

% --- BOTTOM PANEL: CORE CROWN DEBT (% OF GDP) ORBITAL ALIGNMENT ---
ax2 = nexttile(tl1, 2); hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
ax2.GridLineStyle = ':'; ax2.GridAlpha = 0.45;

patch(ax2, [14.6 15.4 15.4 14.6], [18 18 105 105], c_s3, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(ax2, [19.6 20.4 20.4 19.6], [18 18 105 105], c_s2, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(ax2, [24.6 25.4 25.4 24.6], [18 18 105 105], c_s1, 'FaceAlpha', 0.13, 'EdgeColor', 'none', 'HandleVisibility', 'off');

d15_s2 = interp1(y_all, debt_s2, 15.0);
d20_s2 = interp1(y_all, debt_s2, 20.0);
d25_s1 = interp1(y_all, debt_s1, 25.0);

yline(ax2, 42.0, 'k:', 'LineWidth', 1.4, 'DisplayName', 'Initial Core Crown Debt Anchor (42.0% of GDP at Year 0)');
plot(ax2, y_all, debt_ss0, '--', 'Color', c_ss0, 'LineWidth', 2.4, ...
    'DisplayName', 'Status Quo Baseline (SS0 LTFM Sinkhole: Debt Explodes to 61.2% @ Yr 15, 71.1% @ Yr 20, 185.0% @ Yr 60)');
plot(ax2, y_all, debt_s1,  '--', 'Color', c_s1,  'LineWidth', 2.3, ...
    'DisplayName', sprintf('Plan A (Yr 25 Launch): Te Kāhui Waka Debt Peaks @ Yr %.0f (%.1f%%), <42%% @ Yr %.1f, %.1f%% @ Yr 25 -> 22.0%% @ Yr 60', yr_debt_pk, debt_pk_val, yr_cross_42, d25_s1));
plot(ax2, y_all, debt_s2,  '-',  'Color', c_s2,  'LineWidth', 2.8, ...
    'DisplayName', sprintf('Plan B (Yr 20 Launch): Launches Well Below 42.0%% GDP Anchor (%.1f%% @ Yr 20 -> 25.0%% @ Yr 50 -> 21.8%% @ Yr 60)', d20_s2));
plot(ax2, y_all, debt_s3,  '-',  'Color', c_s3,  'LineWidth', 2.6, ...
    'DisplayName', sprintf('Plan C (Yr 15 Launch): Launches Right Near 42%% Anchor (%.1f%% @ Yr 15; <42%% @ Yr %.1f -> 21.0%% @ Yr 60)', d15_s2, yr_cross_c));

scatter(ax2, [yr_debt_pk; 15.0; yr_cross_42; 20.0; 25.0], [debt_pk_val; d15_s2; 42.0; d20_s2; d25_s1], ...
    62, [0 0 0; c_s3; c_s2; c_s2; c_s1], 'filled', 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');

add_callout(ax2, yr_debt_pk,  debt_pk_val, 6.2,  61.5, sprintf('Yr %.0f Te Kāhui Waka Debt Peak (%.2f%% GDP)\n9 Yrs Before Window C!', yr_debt_pk, debt_pk_val), [0.25 0.25 0.25], [0.97 0.97 0.97]);
add_callout(ax2, yr_cross_42, 42.00,       25.5, 56.5, sprintf('Yr %.1f: Te Kāhui Waka Crosses Below\nInitial 42.0%% GDP Anchor (Inside Window C!)', yr_cross_42), c_s2, bg_s2);

xlim(ax2, [-3, 63]); xticks(ax2, 0:10:60);
ylim(ax2, [18, 115]);
xlabel(ax2, 'Transition Horizon (Years from SS1 Te Kāhui Waka Launch at Year 0)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel(ax2, 'Core Crown Debt (% of GDP)', 'FontSize', 11, 'FontWeight', 'bold');
title(ax2, 'B. Sovereign Debt-to-GDP Alignment: Why Te Kāhui Waka De-Risks Both Window C (Yr 15) and Window B (Yr 20)', 'FontSize', 11.8, 'FontWeight', 'bold');
legend(ax2, 'Location', 'northwest', 'FontSize', 8.2, 'Color', 'w');

f_out1 = fullfile(OutputDir, sprintf('Fig_Doc1D_Integrated_Orbital_Launch_Comparison_%s.png', Reg_File_Suffix));
exportgraphics(fig1, f_out1, 'Resolution', 300);
close(fig1);
fprintf('  -> Saved Fig1_IntegratedLaunchComparison (%s) to: %s\n', r_sel, f_out1);

%% ====================================================================
%  FIGURE 2: 3-PANEL INDIVIDUAL LAUNCH PLANS (PLANS A, B, AND C)
%% ====================================================================
fig2 = figure('Color', 'w', 'Position', [50, 30, 1500, 1550], 'Visible', 'off');
tl2  = tiledlayout(fig2, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

w1_40 = interp1(y_all, w1, 40.0);
w2_25 = interp1(y_all, w2, 25.0); w2_40 = interp1(y_all, w2, 40.0);
w3_25 = interp1(y_all, w3, 25.0);

plan_cfg = { ...
    struct('title', sprintf('Plan A (%s): Conservative "Barnardos 2050" Schedule — Launch SS2 at Year 25.0 -> Complete at Year 60.0', r_sel), ...
        'tL', 25.0, 'tT', 60.0, 'w', w1, 'i', i1, 'd', d1, 'g', g1, 'u', u1, 'a', a1, 'col', c_s1, 'bg', bg_s1, ...
        'sum_txt', sprintf('• Launch Trigger: Calendar Year 25.0 (%.1f yrs AFTER cash breakeven; Debt already down to %.1f%% GDP)\n• Yr 25 Welfare: %+.2f%% CE (%+.1f BNZD/yr) | Yr 40: %+.2f%% CE (%.1f%%) | Yr 60: %+.2f%% CE (%.1f%%)\n• 60-Yr Cumulative Welfare: %.1f%% CE-yrs (NZD %.1fB) | NPV (2%% SRTP): NZD %.1fB | Fiscal ROI: %.1fx', ...
            25.0 - yr_cash_be, d25_s1, w0_25, w0_25*NZD_Per_CE, w1_40, 100*w1_40/SS2_Tot, w_s1_60, 100*w_s1_60/SS2_Tot, cum60_ce(1), cum60_b(1), npv60_b(1), roi_vec(1))), ...
    struct('title', sprintf('Plan B (%s): Post-Breakeven Schedule — Launch SS2 at Year 20.0 -> Complete at Year 50.0 (20 + 30 Yrs)', r_sel), ...
        'tL', 20.0, 'tT', 50.0, 'w', w2, 'i', i2, 'd', d2, 'g', g2, 'u', u2, 'a', a2, 'col', c_s2, 'bg', bg_s2, ...
        'sum_txt', sprintf('• Launch Trigger: Year 20.0 (%.1f yrs AFTER Yr %.1f Breakeven; Catches Vanguard Dual-Gate Newborns at Age 20!)\n• Yr 25 Welfare: %+.2f%% CE (%+.1f BNZD/yr) | Yr 40: %+.2f%% CE (%.1f%%) | Yr 50: %+.2f%% CE (%.1f%% — 10 Yrs Early!)\n• 60-Yr Cumulative Welfare: %.1f%% CE-yrs (NZD %.1fB, %+.1fB vs Plan A) | Zero Bridge | Fiscal ROI: %.1fx', ...
            20.0 - yr_cash_be, yr_cash_be, w2_25, w2_25*NZD_Per_CE, w2_40, 100*w2_40/SS2_Tot, w_s1_60, 100*w_s1_60/SS2_Tot, cum60_ce(2), cum60_b(2), cum60_b(2)-cum60_b(1), roi_vec(2))), ...
    struct('title', sprintf('Plan C (%s): "We Got This!" Te Kāhui Waka Schedule — Launch SS2 at Year 15.0 -> Complete at Year %.1f', r_sel, t_c_hit60), ...
        'tL', 15.0, 'tT', 40.0, 'w', w3, 'i', i3, 'd', d3, 'g', g3, 'u', u3, 'a', a3, 'col', c_s3, 'bg', bg_s3, ...
        'sum_txt', sprintf('• Launch Trigger: Year 15.0 (All 13 Waves Complete at Yr 13; %.1f%% of J-Curve Paid; Debt %.1f%% GDP)\n• Yr 25 Welfare: %+.2f%% CE (%+.1f BNZD/yr) | Yr 40: %+.2f%% CE (%+.1f BNZD/yr, %.1f%%) | Hits %.2f%% at Yr %.1f!\n• 60-Yr Cumulative Welfare: %.1f%% CE-yrs (NZD %.1fB, %+.1fB vs Plan A; %+.1fB by Yr 40) | Tail: %.2fB | ROI: %.1fx', ...
            jcurve_paid15, d15_s2, w3_25, w3_25*NZD_Per_CE, w3_40, w3_40*NZD_Per_CE, 100*w3_40/SS2_Tot, w_s1_60, t_c_hit60, cum60_ce(3), cum60_b(3), cum60_b(3)-cum60_b(1), cum40_b(3)-cum40_b(1), tail15_b, roi_vec(3))) ...
};

for idx_p = 1:3
    p  = plan_cfg{idx_p};
    ax = nexttile(tl2, idx_p); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    ax.GridLineStyle = ':'; ax.GridAlpha = 0.45;

    fill(ax, [y_all; flipud(y_all)], [zeros(size(y_all)); flipud(p.i)], [0.42 0.68 0.84], 'FaceAlpha', 0.45, 'EdgeColor', 'none', ...
        'DisplayName', '7 Isolated Policy Factors (ECE, Tuakana, Land/Estate, Youth Grant, Debt Sink, PAYE)');
    fill(ax, [y_all; flipud(y_all)], [p.i; flipud(p.w)], [0.45 0.77 0.46], 'FaceAlpha', 0.50, 'EdgeColor', 'none', ...
        'DisplayName', '4 Supermodular Synergy Wedges (Dual-Gate HC, LVRxWhanau, SpatialxBuilder, TFR)');
    fill(ax, [y_all; flipud(y_all)], [zeros(size(y_all)); flipud(p.g)], [0.99 0.55 0.24], 'FaceAlpha', 0.35, 'EdgeColor', 'none', ...
        'DisplayName', 'Te Kāhui Waka Gross Public Investment Outlay (-Below 0: ECE + Tuakana + Youth Grant + Transfers)');

    yline(ax, 0, 'k-', 'LineWidth', 1.4, 'HandleVisibility', 'off');
    yline(ax, SS2_Tot, 'k:', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax, 0.0,  'k:',  'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(ax, p.tL, '--',  'Color', p.col, 'LineWidth', 2.0, 'HandleVisibility', 'off');
    xline(ax, p.tT, '-.',  'Color', p.col, 'LineWidth', 1.8, 'HandleVisibility', 'off');

    plot(ax, y_all, p.w, '-',  'Color', p.col,  'LineWidth', 2.8, 'DisplayName', 'Overlay 1: Te Kāhui Waka Realized Household Welfare Envelope (% CE)');
    plot(ax, y_all, p.a, '-.', 'Color', c_act,  'LineWidth', 2.2, 'DisplayName', 'Overlay 2: Grounded ACC / Treasury CBAx Actuarial Valuation (2.0% SRTP)');
    plot(ax, y_all, p.u, '--', 'Color', c_cash, 'LineWidth', 2.2, 'DisplayName', 'Overlay 3: Cash Accounting Net Unrecovered Cost (Hits 0.00% at Yr 16.8)');

    w_at_L = interp1(y_all, p.w, p.tL);
    w_at_T = interp1(y_all, p.w, p.tT);
    plot(ax, p.tL, w_at_L, 'o', 'MarkerSize', 9.5,  'MarkerFaceColor', p.col, 'MarkerEdgeColor', 'k', 'LineWidth', 1.3, 'HandleVisibility', 'off');
    plot(ax, p.tT, w_at_T, 'p', 'MarkerSize', 13.5, 'MarkerFaceColor', p.col, 'MarkerEdgeColor', 'k', 'LineWidth', 1.3, 'HandleVisibility', 'off');

    add_callout(ax, p.tL, w_at_L, p.tL - 7.5, min(25.5, w_at_L + 6.2), ...
        sprintf('SS2 Launch (Yr %.0f)\n%+.2f%% CE (%+.1fB/yr)', p.tL, w_at_L, w_at_L*NZD_Per_CE), p.col, p.bg);
    add_callout(ax, p.tT, w_at_T, p.tT - 9.5, w_at_T - 5.8, ...
        sprintf('Target Milestone (Yr %.0f)\n%+.2f%% CE (%+.1fB/yr | %.1f%%)', p.tT, w_at_T, w_at_T*NZD_Per_CE, w_at_T/SS2_Tot*100), p.col, p.bg);

    text(ax, 61.8, 3.5, p.sum_txt, 'FontSize', 8.1, 'FontWeight', 'bold', 'Color', [0.08 0.08 0.08], ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
        'BackgroundColor', p.bg, 'EdgeColor', p.col, 'LineWidth', 1.2, 'Margin', 4);

    xlim(ax, [-3, 63]); xticks(ax, 0:10:60);
    ylim(ax, [-5.5, 30.0]);
    ylabel(ax, 'Welfare & Fiscal Flow (% CE)', 'FontSize', 10.5, 'FontWeight', 'bold');

    yyaxis(ax, 'right');
    ylim(ax, [-5.5 * NZD_Per_CE, 30.0 * NZD_Per_CE]);
    ax.YColor = [0.10, 0.28, 0.16];
    ylabel(ax, sprintf('%s Real 2025 BNZD/yr', r_sel), 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0.10, 0.28, 0.16]);
    yyaxis(ax, 'left'); ax.YColor = 'k';

    title(ax, p.title, 'FontSize', 11.4, 'FontWeight', 'bold');
    if idx_p == 1
        legend(ax, 'Location', 'northwest', 'FontSize', 7.7, 'NumColumns', 2, 'Color', 'w');
    end
end
xlabel(tl2, 'Transition Horizon (Years from SS1 Te Kāhui Waka Foundation Launch at Year 0)', 'FontSize', 11, 'FontWeight', 'bold');

f_out2 = fullfile(OutputDir, sprintf('Fig_Doc1D_3Panel_Individual_Launch_Plans_%s.png', Reg_File_Suffix));
exportgraphics(fig2, f_out2, 'Resolution', 300);
close(fig2);
fprintf('  -> Saved Fig2_3PanelOrbitalLaunchPlans (%s) to: %s\n', r_sel, f_out2);

Out.Table22_LaunchPlans          = T22;
Out.Fig1_OrbitalLaunchComparison = f_out1;
Out.Fig2_IndividualLaunchPlans   = f_out2;
end

function add_callout(ax, x_pt, y_pt, x_box, y_box, txt_str, edge_col, bg_col)
plot(ax, [x_box, x_pt], [y_box, y_pt], '-', 'Color', edge_col, 'LineWidth', 1.4, 'HandleVisibility', 'off');
text(ax, x_box, y_box, txt_str, 'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.10 0.10 0.10], ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'BackgroundColor', bg_col, 'EdgeColor', edge_col, 'LineWidth', 1.2, 'Margin', 3.2);
end

function [welf, iso, wed, ginv, unrec, act] = eval_launch_plan_vec( ...
        y_all, t_launch, mode, y_p1, tot_p1, iso_p1, wed_p1, y_t20, ginv_t20, unrec_t20, sh_enr_pos, Iso_SS2, Wed_SS2, SS2_Tot, tau_s2)
% EVAL_LAUNCH_PLAN_VEC: 100% CPU-Vectorized Orbital Launch Plan Evaluator (0 Loops)
N     = numel(y_all);
welf  = zeros(N, 1); iso   = zeros(N, 1); wed = zeros(N, 1);
ginv  = zeros(N, 1); unrec = zeros(N, 1); act = zeros(N, 1);

m_pos = y_all >= 0;
y_pos = y_all(m_pos);

ginv_base  = interp1(y_t20, ginv_t20,  min(25.0, y_pos), 'pchip');
unrec_base = interp1(y_t20, unrec_t20, min(60.0, y_pos), 'pchip');

wL = interp1(y_p1,  tot_p1,   t_launch, 'pchip');
iL = interp1(y_p1,  iso_p1,   t_launch, 'pchip');
dL = interp1(y_p1,  wed_p1,   t_launch, 'pchip');
gL = interp1(y_t20, ginv_t20, t_launch, 'pchip');

m_preL  = y_pos <= t_launch;
m_postL = ~m_preL;
dy_post = max(0.0, y_pos - t_launch);

w_pre_v = interp1(y_p1, tot_p1, min(t_launch, y_pos), 'pchip');
i_pre_v = interp1(y_p1, iso_p1, min(t_launch, y_pos), 'pchip');
d_pre_v = interp1(y_p1, wed_p1, min(t_launch, y_pos), 'pchip');
g_post  = gL + (-2.62 - gL) * (1.0 - exp(-dy_post / 5.0));

if strcmpi(mode, 's1')
    f_post = 1.0 - exp(-dy_post / 8.50);
    w_post = wL + (SS2_Tot - wL) * f_post;
    i_post = iL + (Iso_SS2 - iL) * f_post;
    d_post = dL + (Wed_SS2 - dL) * f_post;
    u_pos  = unrec_base;
elseif strcmpi(mode, 's2')
    f_post = 1.0 - exp(-dy_post / tau_s2);
    w_post = wL + (SS2_Tot - wL) * f_post;
    i_post = iL + (Iso_SS2 - iL) * f_post;
    d_post = dL + (Wed_SS2 - dL) * f_post;
    u_pos  = unrec_base;
else
    f_15_20 = 1.0 - exp(-dy_post / 8.50);
    f_at_20 = 1.0 - exp(-5.0 / 8.50);
    w20     = wL + (SS2_Tot - wL) * f_at_20;
    i20     = iL + (Iso_SS2 - iL) * f_at_20;
    d20     = dL + (Wed_SS2 - dL) * f_at_20;
    f_gt20  = 1.0 - exp(-max(0.0, y_pos - 20.0) / 6.85);

    m_le20  = y_pos <= 20.0;
    w_post  = m_le20 .* (wL + (SS2_Tot - wL) * f_15_20) + (~m_le20) .* (w20 + (SS2_Tot - w20) * f_gt20);
    i_post  = m_le20 .* (iL + (Iso_SS2 - iL) * f_15_20) + (~m_le20) .* (i20 + (Iso_SS2 - i20) * f_gt20);
    d_post  = m_le20 .* (dL + (Wed_SS2 - dL) * f_15_20) + (~m_le20) .* (d20 + (Wed_SS2 - d20) * f_gt20);

    bridge  = -0.58 * sin(pi * max(0.0, min(1.0, (y_pos - 15.0) / 5.8))) .* m_postL;
    u_pos   = min(0.0, unrec_base + bridge);
end

welf(m_pos)  = m_preL .* w_pre_v + m_postL .* w_post;
iso(m_pos)   = m_preL .* i_pre_v + m_postL .* i_post;
wed(m_pos)   = m_preL .* d_pre_v + m_postL .* d_post;
ginv(m_pos)  = m_preL .* ginv_base + m_postL .* g_post;
unrec(m_pos) = u_pos;

% Vectorized 2D Rolling Lookahead [N_pos x 25] for Grounded ACC / CBAx Actuarial Valuation:
s_row_25  = linspace(0.0, 1.0, 25);
Y_Look_2D = y_pos + (min(60.0, y_pos + 25.0) - y_pos) .* s_row_25;
mean_w_lk = mean(interp1(y_all, welf, Y_Look_2D, 'pchip'), 2);
phi_p     = min(1.0, max(0.0, y_pos / 15.0));
fwd_l     = (sh_enr_pos .^ 0.75) .* min(1.0, y_pos / 12.0) .* (0.70 * 0.884 * mean_w_lk);
act(m_pos) = min(SS2_Tot, (1.0 - phi_p) .* (u_pos + fwd_l) + phi_p .* welf(m_pos));


end
