function Out = Plot_Doc1F_Sortition_Resilience(Params, Opts)
%% PLOT_DOC1F_SORTITION_RESILIENCE (DOCUMENT 1F PART V & DOCUMENT 2B)
% Cross-platform (MATLAB HG2 & GNU Octave) 4-panel sans-serif dashboard:
%   Panel A (NW): Byzantine Breakdown Curve (Privateer Share phi_priv in [0, 60%])
%   Panel B (NE): Assembly Size & Stratification Variance Compression (N_A in [10, 150])
%   Panel C (SW): Volunteer Self-Selection Bias vs Quota-Stratified Replacement (1x..5x)
%   Panel D (SE): Mechanism 3.2 — Captured-Lane Quarantine & 4-of-5 Sub-Lattice Resilience

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Ensure_Workbench_Initialized();
end
if nargin < 2 || isempty(Opts)
    Opts = struct();
end

if isfield(Opts, 'OutputDir') && ~isempty(Opts.OutputDir)
    OutputDir = Opts.OutputDir;
else
    OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
end
AnchorTag = Params.Calibration_Anchor;

SB = Compute_Sortition_Breakdown_Ledger(Params, Opts);
B  = SB.Breakdown;
S  = SB.SizeSweep;
V  = SB.SelectionBias;
Q  = SB.Quarantine;

%% 1. Export Reproducible CSV Ledgers
csv_brk = fullfile(OutputDir, sprintf('Table_Doc1F_Sortition_ByzantineBreakdown_%s.csv', AnchorTag));
fid = fopen(csv_brk, 'w');
fprintf(fid, 'Privateer_Share_Pct,Thick_Strat100_Maj50_Pct,Thick_Strat100_Super67_Pct,Thick_Haircut30_Super67_Pct,Thick_Strat100_Super75_Pct,SmallCommittee12_Super67_Pct,Thin_Viable_Pct\n');
brk_mat = [100 * B.phi_grid, B.Clear_Strat_50, B.Clear_Strat_67, B.Clear_Hair30_67, B.Clear_Strat_75, B.Clear_Small12_67, B.Thin_Viable_Curve];
fprintf(fid, '%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n', brk_mat');
fclose(fid);

csv_bias = fullfile(OutputDir, sprintf('Table_Doc1F_Sortition_SelectionBias_%s.csv', AnchorTag));
fid = fopen(csv_bias, 'w');
fprintf(fid, 'Volunteer_Bias_OR,Raw_SeatShare_Pct,Quota_SeatShare_Pct,Raw_5LaneClear_Pct,Quota_5LaneClear_Pct,Quota_Haircut30_Clear_Pct\n');
bias_mat = [V.OR_grid, V.phi_eff_raw_pct, V.phi_eff_quota_pct, V.Clear_Raw_Vol, V.Clear_Quota_Strat, V.Clear_Quota_H30];
fprintf(fid, '%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n', bias_mat');
fclose(fid);

csv_quar = fullfile(OutputDir, sprintf('Table_Doc1F_Sortition_4of5_Quarantine_%s.csv', AnchorTag));
fid = fopen(csv_quar, 'w');
fprintf(fid, 'Scenario,Realized_CE_pp,Retained_Frontier_Share_Pct,FireSale_Blocked_Pct\n');
for i = 1:numel(Q.Scen_Labels)
    fprintf(fid, '"%s",%.2f,%.2f,%.1f\n', Q.Scen_Labels{i}, Q.Realized_CE_pp(i), Q.Retained_Share_Pct(i), Q.FireSale_Blocked_Pct(i));
end
fclose(fid);

%% 2. Render 4-Panel Sans-Serif Publication Figure
vis_m = IGW_UI_Style('headless_vis');
fig = figure('Visible', vis_m, 'Color', 'w', ...
    'Units', 'pixels', 'Position', [50, 50, 1580, 1020], ...
    'PaperUnits', 'inches', 'PaperSize', [15.8, 10.2], 'PaperPosition', [0, 0, 15.8, 10.2]);

c_teal   = [0.05, 0.43, 0.35]; % Canonical Thick (N_A=100, 67%)
c_emrld  = [0.14, 0.63, 0.50]; % Thick -30% CBAx Haircut / 4-of-5 Quarantine
c_navy   = [0.14, 0.34, 0.62]; % Majority 50%+1 + PBE IFRS 17 Lock
c_plum   = [0.55, 0.25, 0.68]; % 75% Supermajority / Unstratified
c_amber  = [0.86, 0.53, 0.08]; % Small Committee / Raw Volunteer Drift
c_red    = [0.78, 0.19, 0.18]; % Thin Collapse / Omnibus Fire-Sale

pos_NW = [0.068, 0.560, 0.405, 0.370];
pos_NE = [0.555, 0.560, 0.405, 0.370];
pos_SW = [0.068, 0.082, 0.405, 0.375];
pos_SE = [0.565, 0.082, 0.395, 0.375];

%% ========================================================================
%  PANEL A (NW): Byzantine Breakdown Curve (0% -> 60% Privateer Share)
%  ========================================================================
ax1 = axes('Parent', fig, 'Position', pos_NW);
vfi_active_ax(ax1);
hold(ax1, 'on');
set(ax1, 'FontName', 'Helvetica', 'FontSize', 9.5, 'Box', 'on');

px = 100.0 * B.phi_grid;
fill(ax1, [px; flipud(px)], [B.Clear_Strat_67; zeros(size(px))], c_emrld, 'FaceAlpha', 0.10, 'EdgeColor', 'none');

plot(ax1, px, B.Clear_Strat_50,   '-',  'Color', c_navy,  'LineWidth', 2.4);
plot(ax1, px, B.Clear_Strat_67,   '-',  'Color', c_teal,  'LineWidth', 2.9);
plot(ax1, px, B.Clear_Hair30_67,  '-.', 'Color', c_emrld, 'LineWidth', 2.3);
plot(ax1, px, B.Clear_Strat_75,   ':',  'Color', c_plum,  'LineWidth', 2.3);
plot(ax1, px, B.Clear_Small12_67, '--', 'Color', c_amber, 'LineWidth', 2.2);
plot(ax1, px, B.Thin_Viable_Curve,'--', 'Color', c_red,   'LineWidth', 2.6);

plot(ax1, [100*B.phi_star_67, 100*B.phi_star_67], [0, 50], ':', 'Color', c_teal, 'LineWidth', 1.2);
plot(ax1, 100*B.phi_star_67, 50.0, 'o', 'Color', c_teal, 'MarkerFaceColor', c_teal, 'MarkerSize', 5.0);
plot(ax1, [100*B.phi_star_67, 27.6], [50.0, 70.5], '-', 'Color', [0.45, 0.58, 0.54], 'LineWidth', 0.85);
text(ax1, 28.0, 71.5, sprintf('67%% Breakdown = %.1f%%', 100*B.phi_star_67), ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.4, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'Color', c_teal);

xlim(ax1, [0, 58]);
ylim(ax1, [0, 106]);
xlabel(ax1, 'Hostile / Extractive Privateer Share in Population φ_priv (%)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax1, 'All 5 Assemblies Clear Viably (%)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
title(ax1, 'A. Byzantine Breakdown: How Many Privateers Break Sortition?', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 10.6, 'FontWeight', 'bold');

% Explicit middle-right legend box (y = 21..67) so the 50%+1 top downturn (y = 72..100) is 100% visible!
patch(ax1, [30.2, 57.3, 57.3, 30.2], [20.5, 20.5, 67.5, 67.5], [1.0, 1.0, 1.0], ...
    'FaceAlpha', 0.94, 'EdgeColor', [0.64, 0.68, 0.74], 'LineWidth', 0.70);
leg1_y   = [62.8, 55.3, 47.8, 40.3, 32.8, 25.3];
leg1_st  = {'-', '-', '-.', ':', '--', '--'};
leg1_col = {c_navy, c_teal, c_emrld, c_plum, c_amber, c_red};
leg1_txt = { ...
    sprintf('Thick N=100 (50%%+1 + IFRS-17: φ*=%.0f%%)', 100*B.phi_star_50), ...
    sprintf('Thick N=100 (67%% Supermajority: φ*=%.0f%%)', 100*B.phi_star_67), ...
    sprintf('Thick -30%% Haircut (67%% Rule: φ*=%.0f%%)',  100*B.phi_star_hair30), ...
    sprintf('Thick N=100 (75%% Consensus: φ*=%.0f%%)',     100*B.phi_star_75), ...
    'Unstratified 12-Member Committees (67%)', ...
    'Thin Cash Ledger (0% Viable; Fire-Sales)'};
for il = 1:6
    plot(ax1, [31.0, 33.8], [leg1_y(il), leg1_y(il)], leg1_st{il}, 'Color', leg1_col{il}, 'LineWidth', 2.3);
    text(ax1, 34.4, leg1_y(il), leg1_txt{il}, 'Interpreter', 'none', ...
        'FontName', 'Helvetica', 'FontSize', 6.55, 'VerticalAlignment', 'middle', 'Color', [0.14, 0.17, 0.22]);
end
grid(ax1, 'on');

%% ========================================================================
%  PANEL B (NE): Assembly Size (N_A = 10..150) & Stratification Compression
%  ========================================================================
ax2 = axes('Parent', fig, 'Position', pos_NE);
vfi_active_ax(ax2);
hold(ax2, 'on');
set(ax2, 'FontName', 'Helvetica', 'FontSize', 9.5, 'Box', 'on');

plot(ax2, S.N_grid, S.Strat_Phi15_67,   '-',  'Color', c_teal,  'LineWidth', 2.8);
plot(ax2, S.N_grid, S.Unstrat_Phi15_67, '--', 'Color', c_amber, 'LineWidth', 2.2);
plot(ax2, S.N_grid, S.Strat_Phi22_67,   '-.', 'Color', c_navy,  'LineWidth', 2.4);
plot(ax2, S.N_grid, S.Unstrat_Phi22_67, ':',  'Color', c_plum,  'LineWidth', 2.2);

plot(ax2, [100, 100], [0, 105], ':', 'Color', [0.35, 0.40, 0.46], 'LineWidth', 1.2);
text(ax2, 101.5, 46, 'Porirua / Paris Standard (N_A = 100)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.20, 0.25, 0.32]);

xlim(ax2, [10, 150]);
ylim(ax2, [0, 106]);
xlabel(ax2, 'Assembly Panel Size per Lane N_A (Across All 5 Parallel Lanes)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax2, 'Joint 5-Lane Clearance Probability (%)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
title(ax2, 'B. Sample-Size & Stratification Shield Against Bad Lottery Draws', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 10.6, 'FontWeight', 'bold');

Items2 = { ...
    '-',  c_teal,  2.7, 'none', sprintf('Quota-Stratified (φ=15%% Privateers: %.2f%% at N=100)', S.Clear_N100_Phi15_Strat); ...
    '--', c_amber, 2.2, 'none', sprintf('Unstratified SRS (φ=15%%: %.1f%% at N=12 Jury)',       S.Clear_N12_Phi15_Unstrat); ...
    '-.', c_navy,  2.3, 'none', sprintf('Quota-Stratified (φ=22%% Heavy Stress: %.1f%% at N=100)', S.Clear_N100_Phi22_Strat); ...
    ':',  c_plum,  2.2, 'none', 'Unstratified SRS (φ=22% Heavy Stress)'};
igw_smart_incanvas_legend(ax2, Items2, struct('PreferLocs', {{'southeast'}}, 'FontSize', 6.8));
grid(ax2, 'on');

%% ========================================================================
%  PANEL C (SW): Volunteer Response-Rate Tilt (1x..5x) vs Quota Replacement
%  ========================================================================
ax3 = axes('Parent', fig, 'Position', pos_SW);
vfi_active_ax(ax3);
hold(ax3, 'on');
set(ax3, 'FontName', 'Helvetica', 'FontSize', 9.5, 'Box', 'on');

fill(ax3, [V.OR_grid; flipud(V.OR_grid)], [V.Clear_Quota_Strat; flipud(V.Clear_Raw_Vol)], ...
    c_teal, 'FaceAlpha', 0.11, 'EdgeColor', 'none');

plot(ax3, V.OR_grid, V.Clear_Quota_Strat, '-',  'Color', c_teal,  'LineWidth', 2.8);
plot(ax3, V.OR_grid, V.Clear_Quota_H30,   '-.', 'Color', c_emrld, 'LineWidth', 2.3);
plot(ax3, V.OR_grid, V.Clear_Raw_Vol,     '--', 'Color', c_red,   'LineWidth', 2.6);

plot(ax3, V.OR_Raw_Fail50, 50.0, 's', 'Color', c_red, 'MarkerFaceColor', c_red, 'MarkerSize', 5.0);
text(ax3, V.OR_Raw_Fail50 + 0.10, 48.0, sprintf('Raw Self-Selection Fails at %.2fx Skew', V.OR_Raw_Fail50), ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.5, 'FontWeight', 'bold', 'Color', c_red);

xlim(ax3, [1.0, 5.0]);
ylim(ax3, [0, 106]);
xlabel(ax3, 'Privateer / Landlord Invitation Acceptance Bias (Odds Ratio vs Base 12%)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax3, 'Joint 5-Lane Viable Clearance (%)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
title(ax3, 'C. Selection-Bias Shield: Raw Volunteers vs Stats NZ Quota Draws', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 10.6, 'FontWeight', 'bold');

Items3 = { ...
    '-',  c_teal,  2.7, 'none', 'Stats NZ / Roll Quota Replacement (Holds >99% to 5x Bias)'; ...
    '-.', c_emrld, 2.2, 'none', 'Quota Replacement w/ 30% CBAx Synergy Haircut'; ...
    '--', c_red,   2.5, 'none', 'Unweighted Raw Volunteers (Captured Above ~2.8x Bias)'};
igw_smart_incanvas_legend(ax3, Items3, struct('PreferLocs', {{'southwest'}}, 'FontSize', 6.8));
grid(ax3, 'on');

%% ========================================================================
%  PANEL D (SE): Mechanism 3.2 — Captured-Lane Quarantine & 4-of-5 Sub-Lattice
%  ========================================================================
ax4 = axes('Parent', fig, 'Position', pos_SE);
vfi_active_ax(ax4);
hold(ax4, 'on');
set(ax4, 'FontName', 'Helvetica', 'FontSize', 9.0, 'Box', 'on');

n_q = numel(Q.Scen_Labels);
y_q = (1:n_q)';
bar_cols = [c_red; repmat(c_emrld, 5, 1); c_teal];

for i = 1:n_q
    v = Q.Realized_CE_pp(i);
    x0 = min(0.0, v); x1 = max(0.0, v);
    patch(ax4, [x0, x1, x1, x0], [i - 0.34, i - 0.34, i + 0.34, i + 0.34], ...
        bar_cols(i, :), 'FaceAlpha', 0.86, 'EdgeColor', bar_cols(i, :) * 0.72, 'LineWidth', 0.9);
    x_lbl = max(v, 0.0) + 0.45;
    if v >= 0
        lbl_q = sprintf('+%.1f pp (%.0f%%)', v, Q.Retained_Share_Pct(i));
        col_q = [0.08, 0.24, 0.20];
    else
        lbl_q = sprintf('%.1f pp (-NZD 176B Fire-Sale)', v);
        col_q = c_red;
    end
    text(ax4, x_lbl, i, lbl_q, 'Interpreter', 'none', 'FontName', 'Helvetica', ...
        'FontSize', 7.5, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', 'Color', col_q);
end

plot(ax4, [0, 0], [0.3, n_q + 0.7], '-', 'Color', [0.25, 0.30, 0.36], 'LineWidth', 1.1);
set(ax4, 'YTick', y_q, 'YTickLabel', Q.Scen_Labels);
xlim(ax4, [-6.8, 33.2]);
ylim(ax4, [0.35, n_q + 0.65]);
xlabel(ax4, 'Realized National Welfare Gain (+CE pp; IFRS-17 Blocks All Fire-Sales)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.2, 'FontWeight', 'bold');
title(ax4, 'D. Graceful 4-of-5 Sub-Lattice Quarantine If 1 Lane Deadlocks', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 10.5, 'FontWeight', 'bold');
grid(ax4, 'on');

fig_path = fullfile(OutputDir, sprintf('Fig_Doc1F_Sortition_Byzantine_Resilience_%s.png', AnchorTag));
print(fig, fig_path, '-dpng', '-r220');
close(fig);

Out = struct();
Out.SB            = SB;
Out.FigurePNG     = fig_path;
Out.CSV_Breakdown = csv_brk;
Out.CSV_Bias      = csv_bias;
Out.CSV_Quarantine= csv_quar;
end
