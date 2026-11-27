function Out = Plot_Phase2_5Sector_Dashboard(Params)
%% PLOT_PHASE2_5SECTOR_DASHBOARD (UNIFIED 5-SECTOR SOE, EXERGY, WARING & ASSET SUITE)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end

OutputDir  = Resolve_IGW_OutputDir('', Params.Profile_ID);
AnchorTag  = Params.Calibration_Anchor;
curr_iso_d = 'NZD'; curr_sym_d = '$'; curr_yr_d = 2026;
if isfield(Params, 'Currency_ISO') && ~strncmpi(Params.Profile_ID, 'NZ_', 3)
    curr_iso_d = Params.Currency_ISO;
    curr_sym_d = Params.Currency_Symbol;
end
def_font   = get(0, 'DefaultAxesFontName');

L_3T  = Compute_ThreeTier_NationalAccounts_Ledger(Params);
L_AS  = Compute_Public_Asset_Stewardship_Ledger(Params);
L_NDC = Compute_NDC_Compliance_Ledger(Params);

Eq_SS0 = L_3T.Trajectories.SS0_LTFM;
Eq_Ref = L_3T.Trajectories.Phase2_Reform;
Eq_Def = L_3T.Trajectories.Phase2_Defence_3Pct;

vis_m = IGW_UI_Style('headless_vis');
fig   = figure('Name', sprintf('Unified 5-Sector SOE, Exergy, Waring & Asset Stewardship (%s)', AnchorTag), ...
    'Color', 'w', 'Position', [30, 30, 1840, 1080], 'Visible', vis_m);

pos1 = [0.062, 0.565, 0.405, 0.365];
pos2 = [0.545, 0.565, 0.390, 0.365];
pos3 = [0.062, 0.080, 0.405, 0.365];
pos4 = [0.545, 0.080, 0.390, 0.365];

% --- PANEL A: 5-Sector Paid Workforce & Internal Sector 4A Reactive Release ---
ax1 = axes('Parent', fig, 'Position', pos1, 'FontName', def_font);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');

idx_50  = find(Eq_Ref.Years == 2050, 1);
L_2026  = Eq_Ref.Paid_kFTE_Tx6(1, :);
L_SS050 = Eq_SS0.Paid_kFTE_Tx6(idx_50, :);
L_Ref50 = Eq_Ref.Paid_kFTE_Tx6(idx_50, :);
L_Def50 = Eq_Def.Paid_kFTE_Tx6(idx_50, :);
max_bA  = max([L_2026(:); L_SS050(:); L_Ref50(:); L_Def50(:)]);

bA = bar(ax1, 1:6, [L_2026(:), L_SS050(:), L_Ref50(:), L_Def50(:)], 'grouped', 'BarWidth', 0.82);
cols_A  = {[0.35 0.45 0.58], [0.72 0.16 0.18], [0.06 0.56 0.40], [0.18 0.36 0.72]};
names_A = {sprintf('%d Base (%.0fk FTE)', curr_yr_d, sum(L_2026)), '2050 SS0 Drift', '2050 Phase II Reform', '2050 Reform + 3% Defence'};
for k = 1:4, set(bA(k), 'FaceColor', cols_A{k}); end
xlim(ax1, [0.4, 6.6]); ylim(ax1, [0, ceil(max_bA * 1.09 / 50) * 50]);
set(ax1, 'XTick', 1:6, 'XTickLabel', {'S1 Primary', 'S2 Knowl z_h', 'S3 Mkt NT', 'S4A Care', 'S4B Infra', 'S5 Defence'}, ...
    'TickLabelInterpreter', 'none', 'FontSize', 8.5, 'FontWeight', 'bold');

items1 = { ...
    'bar', cols_A{1}, 1.0, 'none', names_A{1}; ...
    'bar', cols_A{2}, 1.0, 'none', names_A{2}; ...
    'bar', cols_A{3}, 1.0, 'none', names_A{3}; ...
    'bar', cols_A{4}, 1.0, 'none', names_A{4}};
% S4A..S5 on the right are <= 620 FTE while S3 is 1390 -> Northeast sits in natural open space!
meta1 = igw_smart_incanvas_legend(ax1, items1, struct('FontSize', 6.9, 'MarginPt', 4.0, 'PreferLocs', {{'northeast'}}, 'AutoExpandY', false));

ylabel(ax1, 'Paid Employment (Thousand FTEs)', 'FontSize', 9.6, 'FontWeight', 'bold');
title(ax1, sprintf('A. 5-Sector Workforce & Internal S4A Release (+%.0fk Reactive FTE Freed!)', Eq_Ref.L_S4A_Released_kFTE(idx_50)), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.3, 'FontWeight', 'bold');

% --- PANEL B: Exergy Fossil Import Savings Absorbing 3% GDP Defence & Stabilizing NFA/Y ---
ax2 = axes('Parent', fig, 'Position', pos2, 'FontName', def_font);
yyaxis(ax2, 'left'); hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');

plot(ax2, Eq_SS0.Years, Eq_SS0.Fossil_Import_BNZD_t, '--', 'Color', [0.72 0.16 0.18], 'LineWidth', 2.3);
plot(ax2, Eq_Ref.Years, Eq_Ref.Fossil_Import_BNZD_t, '-',  'Color', [0.06 0.56 0.40], 'LineWidth', 2.7);
plot(ax2, Eq_Def.Years, Eq_Def.Def_Imports_BNZD_t,   '-.', 'Color', [0.18 0.36 0.72], 'LineWidth', 2.3);
ylabel(ax2, sprintf('Annual FX Import Outflow (%d %s B/yr)', curr_yr_d, curr_iso_d), 'FontSize', 9.4, 'FontWeight', 'bold');
y2_top = 35.0;
if ~strncmpi(Params.Profile_ID, 'NZ_', 3)
    y2_top = max(12.0, ceil(max([Eq_SS0.Fossil_Import_BCurr_t(:); Eq_Def.Def_Imports_BCurr_t(:)]) * 1.35 / 5.0) * 5.0);
end
ylim(ax2, [0, y2_top]);
set(vfi_active_ax(ax2), 'YColor', [0.15 0.15 0.15]);

yyaxis(ax2, 'right'); hold(ax2, 'on');
plot(ax2, Eq_SS0.Years, 100*Eq_SS0.NFA_to_GDP_t, ':', 'Color', [0.55 0.10 0.12], 'LineWidth', 2.2);
plot(ax2, Eq_Def.Years, 100*Eq_Def.NFA_to_GDP_t, '-', 'Color', [0.42 0.14 0.62], 'LineWidth', 2.6);
ylabel(ax2, 'Net Foreign Assets NFA_t / Y_t (%)', 'FontSize', 9.4, 'FontWeight', 'bold');
ylim(ax2, [-112, 72]);
xlim(vfi_active_ax(ax2), [2026, 2086]);
set(vfi_active_ax(ax2), 'YColor', [0.42 0.14 0.62], 'Color', 'none');
% Keep yyaxis right active above opaque left axes so NFA curves are never masked by ax2's white fill!
xlim(ax2, [2026, 2086]);
items2 = { ...
    '--', [0.72 0.16 0.18], 2.3, 'none', sprintf('SS0 Fossil (~%s%.0fB/yr)', curr_sym_d, Eq_SS0.Fossil_Import_BCurr_t(1)); ...
    '-',  [0.06 0.56 0.40], 2.7, 'none', 'Electrified Fossil (e_N=0.88)'; ...
    '-.', [0.18 0.36 0.72], 2.3, 'none', '3% Defence FX Imports'; ...
    ':',  [0.55 0.10 0.12], 2.2, 'none', 'SS0 NFA/GDP (%) [Right]'; ...
    '-',  [0.42 0.14 0.62], 2.6, 'none', 'Reform+3% Def NFA [Right]'};
meta2 = igw_smart_incanvas_legend(ax2, items2, struct('FontSize', 6.7, 'NumColumns', 2, 'MarginPt', 4.0, 'PreferLocs', {{'northwest'}}, 'AutoExpandY', false));

xlabel(ax2, 'Transition Year (2026-2086)', 'FontSize', 9.6, 'FontWeight', 'bold');
title(ax2, 'B. Keen-Labrousse Exergy Dividend Frees FX to Sustain 3% GDP Defence', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.3, 'FontWeight', 'bold');

% --- PANEL C: Three-Tier National Accounts (SNA GDP vs. Atkinson-Waring Inclusive Output) ---
ax3 = axes('Parent', fig, 'Position', pos3, 'FontName', def_font);
hold(ax3, 'on'); grid(ax3, 'on'); box(ax3, 'on');

ST3   = L_3T.SummaryTable;
max_C = max([ST3.Y_SNA_2050_BNZD(:); ST3.Y_AtkinsonWaring_2050_BNZD(:)]);
bC    = bar(ax3, 1:height(ST3), [ST3.Y_SNA_2050_BNZD, ST3.Y_AtkinsonWaring_2050_BNZD], 'grouped', 'BarWidth', 0.78);
set(bC(1), 'FaceColor', [0.30 0.44 0.62]);
set(bC(2), 'FaceColor', [0.05 0.58 0.38]);
xlim(ax3, [0.4, height(ST3) + 0.6]);
% Bars 1..3 on the left are <= 415 while Bars 4..6 reach 650 -> Northwest needs only 740 top!
ylim(ax3, [0, ceil(max_C * 1.14 / 50) * 50]);
set(ax3, 'XTick', 1:height(ST3), 'XTickLabel', {'SS0 LTFM', 'Dom 15', 'SS0+3%Def', 'Phase II', 'P2+Civic', 'P2+3%Def'}, ...
    'TickLabelInterpreter', 'none', 'FontSize', 8.5, 'FontWeight', 'bold');

items3 = { ...
    'bar', [0.30 0.44 0.62], 1.0, 'none', 'Tier 1: Conventional SNA GDP (Paid Inputs Only)'; ...
    'bar', [0.05 0.58 0.38], 1.0, 'none', 'Tier 2: Atkinson-Waring Output (+Care/Vol - Y_rem)'};
meta3 = igw_smart_incanvas_legend(ax3, items3, struct('FontSize', 6.9, 'MarginPt', 4.0, 'PreferLocs', {{'northwest'}}, 'AutoExpandY', false));

ylabel(ax3, sprintf('2050 Real Annual Output (%d %s B/yr)', curr_yr_d, curr_iso_d), 'FontSize', 9.6, 'FontWeight', 'bold');
title(ax3, 'C. Three-Tier Scorecard: SNA GDP vs. Atkinson-Waring Satellite Account', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.3, 'FontWeight', 'bold');

% --- PANEL D: Public-Asset Privatization Mirage vs. Stewardship Governance Turnaround ---
ax4 = axes('Parent', fig, 'Position', pos4, 'FontName', def_font);
hold(ax4, 'on'); grid(ax4, 'on'); box(ax4, 'on');

yline(ax4, 0, 'k-', 'LineWidth', 1.1, 'HandleVisibility', 'off');
yr_as = L_AS.Years;
Cum4  = L_AS.Cum_Societal_BNZD_Tx4;

plot(ax4, yr_as, Cum4(:, 1), '--', 'Color', [0.55 0.35 0.15], 'LineWidth', 2.3);
plot(ax4, yr_as, Cum4(:, 2), '-v', 'Color', [0.78 0.12 0.16], 'LineWidth', 2.5, 'MarkerIndices', 1:5:numel(yr_as));
plot(ax4, yr_as, Cum4(:, 3), '-.', 'Color', [0.22 0.48 0.72], 'LineWidth', 2.3);
plot(ax4, yr_as, Cum4(:, 4), '-^', 'Color', [0.04 0.56 0.36], 'LineWidth', 2.8, 'MarkerIndices', 1:5:numel(yr_as));

xlim(ax4, [2026, 2061]);
ylim(ax4, [floor(min(Cum4(:)) - 75), ceil(max(Cum4(:)) + 65)]);

items4 = { ...
    '--', [0.55 0.35 0.15], 2.3, 'none', sprintf('1. Mismanaged + Deferred Maint (2%% PV: %+.0fB)', L_AS.SummaryTable.Net_Societal_PV_2pct_BNZD(1)); ...
    '-',  [0.78 0.12 0.16], 2.5, 'v',    sprintf('2. Fire-Sale (+%s%.0fB Cash -> 2%% PV: %+.0fB)', curr_sym_d, L_AS.SummaryTable.Crown_Cash_Yr0to3_BNZD(2), L_AS.SummaryTable.Net_Societal_PV_2pct_BNZD(2)); ...
    '-.', [0.22 0.48 0.72], 2.3, 'none', sprintf('3. Ring-Fenced Maint Only (2%% PV: %+.0fB)', L_AS.SummaryTable.Net_Societal_PV_2pct_BNZD(3)); ...
    '-',  [0.04 0.56 0.36], 2.8, '^',    sprintf('4. Public Stewardship Turnaround (2%% PV: %+.0fB)', L_AS.SummaryTable.Net_Societal_PV_2pct_BNZD(4))};
meta4 = igw_smart_incanvas_legend(ax4, items4, struct('FontSize', 6.8, 'MarginPt', 4.0, 'PreferLocs', {{'southwest'}}, 'AutoExpandY', false));

yl4_cur  = ylim(ax4);
y_txt_d4 = -435;
if ~strncmpi(Params.Profile_ID, 'NZ_', 3)
    y_txt_d4 = yl4_cur(1) + 0.32 * (yl4_cur(2) - yl4_cur(1));
end
text(ax4, 2027.4, y_txt_d4, sprintf('Privatization Loss: -%s %.1fB (2%% SRTP)\nYr-10 Buyback Cost: %s %.1fB', ...
    curr_iso_d, L_AS.Opportunity_Loss_2pct_B, curr_iso_d, L_AS.Buyback_Cost_Yr10_BCurr), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.5, 'FontWeight', 'bold', ...
    'Color', [0.65 0.05 0.10], 'BackgroundColor', [1.0 0.97 0.97], 'EdgeColor', [0.78 0.12 0.16], 'Margin', 2.2, 'Clipping', 'on');

xlabel(ax4, sprintf('Horizon Year (%s %.0fB Network/Grid Asset Block)', curr_iso_d, L_AS.Asset_Book_Value_BCurr), 'FontSize', 9.6, 'FontWeight', 'bold');
ylabel(ax4, sprintf('Cumulative Net Societal Value (%s B)', curr_iso_d), 'FontSize', 9.6, 'FontWeight', 'bold');
title(ax4, 'D. Public Assets on the Block: Privatization Mirage vs. Governance Reform', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.3, 'FontWeight', 'bold');

Out_PNG = fullfile(OutputDir, sprintf('Fig_Phase2_5Sector_Exergy_Waring_Dashboard_%s.png', AnchorTag));
exportgraphics(fig, Out_PNG, 'Resolution', 260, 'BackgroundColor', 'white');
fprintf('  -> Saved Phase II 5-Sector, Exergy, Waring & Asset Dashboard to: %s\n', Out_PNG);

if strcmpi(vis_m, 'off') && ishghandle(fig), close(fig); end
Out = struct('ThreeTier', L_3T, 'AssetStewardship', L_AS, 'NDC', L_NDC, 'Fig_Path', Out_PNG, ...
    'LegendMeta', [meta1, meta2, meta3, meta4]);
end
