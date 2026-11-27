function Out = Plot_HelmPhysics_TrimTabs_And_CounterSteering(Params, Opts)
%% 4-PANEL PHASE II HELM PHYSICS: DYNAMIC TRIM-TAB CASCADE & COUNTER-STEERING
% File: plots/Plot_HelmPhysics_TrimTabs_And_CounterSteering.m
% Layout Architecture:
%   Top Row (Shared [-16, 215] NZD B/yr Vertical Scale for Side-by-Side Comparison):
%     Panel A (Top-Left) : Dynamic 3-Stage Trim-Tab Cascade (Seed -> Rudder -> Hull Turn; NW Legend)
%     Panel B (Top-Right): Inside the Panic Window (Counter-Steer Decomposition; Centered North Legend)
%   Bottom Row (Hydrodynamic Phase-Space & Instrument Mechanics):
%     Panel C (Bottom-Left) : Naval Turning Circle (Yrs 0-20; Legend right of OBEGAL=0, centered at Y=75)
%     Panel D (Bottom-Right): Four Individual Trim-Tab J-Curves (SE Legend with polite gap above Y=0)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end
if nargin < 2 || isempty(Opts), Opts = struct(); end

OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
AnchorTag  = Params.Calibration_Anchor;
curr_iso_p = 'NZD'; curr_sym_p = '$';
if isfield(Params, 'Currency_ISO') && ~strncmpi(Params.Profile_ID, 'NZ_', 3)
    curr_iso_p = Params.Currency_ISO;
    curr_sym_p = Params.Currency_Symbol;
end
def_font  = get(0, 'DefaultAxesFontName');

H = Compute_Helm_TrimTab_Ledger(Params, Opts);

vis_mode = IGW_UI_Style('headless_vis');
if isfield(Opts, 'Visible') && strcmpi(Opts.Visible, 'on'), vis_mode = 'on'; end

fig = figure('Name', sprintf('Phase II Naval Helm Physics & Trim-Tab Cascade (%s)', AnchorTag), ...
    'Color', 'w', 'Position', [30, 30, 1840, 1080], 'Visible', vis_mode);

c_teal    = [0.00, 0.52, 0.42];
c_navy    = [0.10, 0.28, 0.58];
c_crimson = [0.78, 0.12, 0.16];
c_amber   = [0.85, 0.46, 0.02];
c_purple  = [0.48, 0.18, 0.62];

posA = [0.062, 0.565, 0.405, 0.365]; % Top-Left
posB = [0.548, 0.565, 0.405, 0.365]; % Top-Right
posC = [0.062, 0.080, 0.405, 0.365]; % Bottom-Left
posD = [0.548, 0.080, 0.405, 0.365]; % Bottom-Right

% Shared 30-year time horizon & common vertical axis for Top Row (Panels A & B):
yr0 = H.Years(1);
m30 = H.t_rel <= 30;
yrB = H.Years(m30);
y_common_bot = floor(min([H.OBEGAL_Reform_t(m30); H.dY_Rem_Shrink_t(m30)]) - 5.0); % ~ -16
y_common_top = ceil(max(H.True_Heading_t(m30)) * 1.14 / 5.0) * 5.0;                % ~ +215
yl_top_shared = [y_common_bot, y_common_top];

% =========================================================================
% PANEL A (TOP-LEFT): 3-STAGE DYNAMIC TRIM-TAB CASCADE (SEED -> RUDDER -> HULL)
% =========================================================================
axA = axes('Parent', fig, 'Position', posA, 'FontName', def_font);
hold(axA, 'on'); grid(axA, 'on'); box(axA, 'on');

plot(axA, [yrB(1), yrB(end)], [0, 0], 'k-', 'LineWidth', 1.0, 'HandleVisibility', 'off');
patch(axA, [yrB; flipud(yrB)], [zeros(size(yrB)); flipud(H.Stage1_TrimTab_Input_t(m30))], ...
    [0.98, 0.84, 0.52], 'EdgeColor', 'none', 'FaceAlpha', 0.55, 'HandleVisibility', 'off');

plot(axA, yrB, H.Stage1_TrimTab_Input_t(m30), '-',  'Color', c_amber,   'LineWidth', 2.4);
plot(axA, yrB, H.Stage2_Rudder_Torque_t(m30), '--', 'Color', c_navy,    'LineWidth', 2.7);
plot(axA, yrB, H.Stage3_Hull_Turn_t(m30),     '-',  'Color', c_teal,    'LineWidth', 3.1);
plot(axA, yrB, H.BruteForce_Stall_t(m30),     ':',  'Color', c_crimson, 'LineWidth', 2.4);

xlim(axA, [yrB(1), yrB(end)]); xticks(axA, 2026:5:2056);
ylim(axA, yl_top_shared);

idx24 = find(H.t_rel == 24, 1);
s1_24 = H.Stage1_TrimTab_Input_t(idx24);
s2_24 = H.Stage2_Rudder_Torque_t(idx24);
s3_24 = H.Stage3_Hull_Turn_t(idx24);
plot(axA, [2050, 2050], [s1_24, s3_24], 'k:', 'LineWidth', 1.3, 'HandleVisibility', 'off');
plot(axA, [2050, 2050], [s1_24, s3_24], 'o', 'MarkerSize', 6.0, ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');

text(axA, 2049.2, 0.5 * (s2_24 + s3_24), sprintf('2050 Amplification:\n%.1fx Seed -> Hull', s3_24 / max(0.1, s1_24)), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.4, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'right', 'Color', [0.02, 0.34, 0.28], ...
    'BackgroundColor', 'w', 'EdgeColor', c_teal, 'Margin', 2.0, 'Clipping', 'on');

itemsA = { ...
    '-',  c_amber,   2.4, 'none', 'Stage 1: Trim-Tab Seed Input (~$2.9B/yr)'; ...
    '--', c_navy,    2.7, 'none', 'Stage 2: Main Rudder Torque (S4A + FX)'; ...
    '-',  c_teal,    3.1, 'none', 'Stage 3: Full Hull Turn (+True Wealth)'; ...
    ':',  c_crimson, 2.4, 'none', 'Un-Trimmed Rudder (Baumol & FX Stall)'};
% Northwest sits in wide-open sky above the early ramp (zero Y-axis expansion, exact shared Y-scale!):
metaA = igw_smart_incanvas_legend(axA, itemsA, struct('FontSize', 6.8, 'PreferLocs', {{'northwest'}}, 'AutoExpandY', false));

xlabel(axA, 'Calendar Year (Trailing-Edge Deflection -> Rudder Swing -> Hull Momentum)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.3, 'FontWeight', 'bold');
ylabel(axA, sprintf('Annualized Macro Swing / Flow (Real %s B/yr)', curr_iso_p), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.3, 'FontWeight', 'bold');
title(axA, 'A. Dynamic Trim-Tab Cascade: Tiny Seed -> Main Rudder Torque -> Full Hull Turn', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.3, 'FontWeight', 'bold');

% =========================================================================
% PANEL B (TOP-RIGHT): WHY RADAR LIES IN YRS 1-8 (SHARED Y-SCALE WITH PANEL A)
% =========================================================================
axB = axes('Parent', fig, 'Position', posB, 'FontName', def_font);
hold(axB, 'on'); grid(axB, 'on'); box(axB, 'on');

patch(axB, [yr0, yr0+8, yr0+8, yr0], [yl_top_shared(1), yl_top_shared(1), yl_top_shared(2), yl_top_shared(2)], ...
    [0.99, 0.95, 0.86], 'EdgeColor', 'none', 'FaceAlpha', 0.65, 'HandleVisibility', 'off');
plot(axB, [yrB(1), yrB(end)], [0, 0], 'k-', 'LineWidth', 1.0, 'HandleVisibility', 'off');

plot(axB, yrB, H.True_Heading_t(m30),  '-',  'Color', c_teal,    'LineWidth', 3.0);
plot(axB, yrB, H.True_Net_Flow_t(m30), '-',  'Color', c_navy,    'LineWidth', 2.4);
plot(axB, yrB, H.OBEGAL_Reform_t(m30), '--', 'Color', c_amber,   'LineWidth', 2.4);
plot(axB, yrB, H.dY_Rem_Shrink_t(m30), ':',  'Color', c_crimson, 'LineWidth', 2.4);

yr_tb = yr0 + H.Yr_True_Breakeven;
yr_cb = yr0 + H.Yr_Cash_Breakeven;
plot(axB, [yr_tb, yr_cb], [0, 0], 'o', 'MarkerSize', 7.0, ...
    'MarkerFaceColor', [0.98, 0.82, 0.12], 'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');

xlim(axB, [yrB(1), yrB(end)]); xticks(axB, 2026:5:2056);
ylim(axB, yl_top_shared);

itemsB = { ...
    '-',  c_teal,    3.0, 'none', 'True Hull Lift (ΔY_AW + FX + Turnaround)'; ...
    '-',  c_navy,    2.4, 'none', 'Net Fiscal + FX + Care Balance'; ...
    '--', c_amber,   2.4, 'none', 'Crown Cash OBEGAL (Lags During Seed)'; ...
    ':',  c_crimson, 2.4, 'none', 'Paid Firefighting ΔY_rem (Damps Raw SNA)'};
% Horizontally centered ('north') clears the rising 2056 green curve on the right AND the Panic Window badge on the left!
metaB = igw_smart_incanvas_legend(axB, itemsB, struct('FontSize', 6.8, 'PreferLocs', {{'north'}}, 'AutoExpandY', false));

text(axB, yr0 + 0.5, yl_top_shared(2) * 0.80, sprintf('PANIC WINDOW\n(Yrs 1-8 Kick)'), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.3, 'FontWeight', 'bold', ...
    'Color', [0.52, 0.28, 0.02], 'BackgroundColor', 'w', 'EdgeColor', c_amber, 'Margin', 2.0, 'Clipping', 'on');

text(axB, 2038.5, 0.36 * yl_top_shared(2), ...
    sprintf('True Solvency: Yr %.1f\nCash OBEGAL: Yr %.1f (%.1f-Yr Lag)', ...
    H.Yr_True_Breakeven, H.Yr_Cash_Breakeven, H.Yr_Cash_Breakeven - H.Yr_True_Breakeven), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.4, 'FontWeight', 'bold', ...
    'Color', [0.10, 0.24, 0.48], 'BackgroundColor', 'w', 'EdgeColor', c_navy, 'Margin', 2.0, 'Clipping', 'on');

xlabel(axB, 'Calendar Year (30-Year Transition Window, 2026-2056)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.3, 'FontWeight', 'bold');
ylabel(axB, sprintf('Annualized Macro Swing / Flow (Real %s B/yr)', curr_iso_p), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.3, 'FontWeight', 'bold');
title(axB, 'B. Inside the Panic Window: Shrinking Firefighting (ΔY_rem) Makes Raw SNA Lag', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.3, 'FontWeight', 'bold');

% =========================================================================
% PANEL C (BOTTOM-LEFT): ZOOMED NAVAL TURNING CIRCLE (YEARS 0..20 MECHANICS)
% =========================================================================
axC = axes('Parent', fig, 'Position', posC, 'FontName', def_font);
hold(axC, 'on'); grid(axC, 'on'); box(axC, 'on');

m20    = H.t_rel <= 20;
yC_bot = -35.0;
yC_top = 155.0;
xC_lo  = -11.0;
xC_hi  = 21.5;

patch(axC, [xC_lo, 0, 0, xC_lo], [0, 0, yC_top, yC_top], [0.92, 0.98, 0.96], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.55, 'HandleVisibility', 'off');
patch(axC, [0, xC_hi, xC_hi, 0], [yC_bot, yC_bot, 0, 0], [1.00, 0.94, 0.93], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.55, 'HandleVisibility', 'off');
plot(axC, [xC_lo, xC_hi], [0, 0], 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
plot(axC, [0, 0], [yC_bot, yC_top], 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');

plot(axC, H.Radar_Reform_t(m20),   H.True_Heading_t(m20),  '-',  'Color', c_teal,    'LineWidth', 3.0);
plot(axC, H.Radar_StopGo_t(m20),   H.True_StopGo_t(m20),   '-.', 'Color', c_amber,   'LineWidth', 2.3);
plot(axC, H.Radar_FireSale_t(m20), H.True_FireSale_t(m20), '--', 'Color', c_crimson, 'LineWidth', 2.5);

wp_t = [1, 4, 10, 21];
plot(axC, H.Radar_Reform_t(wp_t), H.True_Heading_t(wp_t), 'o', ...
    'MarkerSize', 6.5, 'MarkerFaceColor', c_teal, 'MarkerEdgeColor', 'w', 'LineWidth', 1.2, 'HandleVisibility', 'off');

xlim(axC, [xC_lo, xC_hi]); ylim(axC, [yC_bot, yC_top]);

itemsC = { ...
    '-',  c_teal,    3.0, 'o',    'Counter-Steered Trim-Tab Hull'; ...
    '-.', c_amber,   2.3, 'none', '6-Yr Ideologue Panic (Stop-Go)'; ...
    '--', c_crimson, 2.5, 'none', 'Fire-Sale Mirage -> Monopoly Reef'};
% Centered on Y = 75, left edge at X = +1.4 (cleanly right of the X = 0 OBEGAL line, well below +136 terminal!):
metaC = igw_smart_incanvas_legend(axC, itemsC, struct('FontSize', 6.9, ...
    'CustomDataAnchor', struct('XLeft', 1.4, 'YCenter', 75.0), 'AutoExpandY', false));

text(axC, xC_lo + 0.6, 122.0, sprintf('Yr 3 Stern Kick: %.1fB Cash/SNA\nwhile True Wealth Climbs +%.0fB', ...
    H.Radar_Reform_t(4), H.True_Heading_t(4)), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.4, 'FontWeight', 'bold', ...
    'Color', [0.00, 0.38, 0.30], 'BackgroundColor', 'w', 'EdgeColor', c_teal, 'Margin', 2.2, 'Clipping', 'on');

[~, idx_m] = max(H.Radar_FireSale_t(1:6));
plot(axC, H.Radar_FireSale_t(idx_m), H.True_FireSale_t(idx_m), 's', ...
    'MarkerSize', 6.5, 'MarkerFaceColor', c_crimson, 'MarkerEdgeColor', 'w', 'HandleVisibility', 'off');
text(axC, 1.4, yC_bot + 7.5, 'Asset Fire-Sale (+$34.8B Cash -> -24% Markup Reef)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.3, 'FontWeight', 'bold', ...
    'Color', c_crimson, 'Clipping', 'on');

xlabel(axC, sprintf('Short-Term Radar: Cash OBEGAL + Firefighting SNA Impulse (%s B/yr)', curr_iso_p), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.3, 'FontWeight', 'bold');
ylabel(axC, sprintf('True Hull Heading: Waring ΔY_AW + FX (%s B/yr)', curr_iso_p), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.3, 'FontWeight', 'bold');
title(axC, 'C. Naval Turning Circle (Yrs 0-20): Stern Kicks Port Before Starboard Climb', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.3, 'FontWeight', 'bold');

% =========================================================================
% PANEL D (BOTTOM-RIGHT): FOUR INDIVIDUAL TRIM-TAB J-CURVES OVER TIME
% =========================================================================
axD = axes('Parent', fig, 'Position', posD, 'FontName', def_font);
hold(axD, 'on'); grid(axD, 'on'); box(axD, 'on');

JC = H.TT_JCurves_Tx4(m30, :);
TT = H.TrimTabTable;
plot(axD, [yrB(1), yrB(end)], [0, 0], 'k-', 'LineWidth', 1.1, 'HandleVisibility', 'off');
patch(axD, [yrB(1), yrB(9), yrB(9), yrB(1)], [-3.5, -3.5, 0, 0], [0.99, 0.94, 0.85], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.65, 'HandleVisibility', 'off');

plot(axD, yrB, JC(:, 1), '-',  'Color', c_teal,   'LineWidth', 2.8);
plot(axD, yrB, JC(:, 2), '--', 'Color', c_navy,   'LineWidth', 2.8);
plot(axD, yrB, JC(:, 3), '-.', 'Color', c_amber,  'LineWidth', 2.6);
plot(axD, yrB, JC(:, 4), ':',  'Color', c_purple, 'LineWidth', 2.9);

xlim(axD, [yrB(1), yrB(end)]); xticks(axD, 2026:5:2056);
ylim(axD, [-3.0, 13.0]);

itemsD = { ...
    '-',  c_teal,   2.8, 'none', sprintf('TT1 Joiner Mycelium (-$0.33B -> %.1fx)', TT.Gearing_Ratio_x(1)); ...
    '--', c_navy,   2.8, 'none', sprintf('TT2 Clean Exergy (-$1.45B -> %.1fx)',    TT.Gearing_Ratio_x(2)); ...
    '-.', c_amber,  2.6, 'none', sprintf('TT3 Asset Turnaround (-$0.85B -> %.1fx)',TT.Gearing_Ratio_x(3)); ...
    ':',  c_purple, 2.9, 'none', sprintf('TT4 Land->z_h + 2-Key (-$0.25B -> %.1fx)',TT.Gearing_Ratio_x(4))};
% YMinDataFloor = +0.85 lifts the SE legend politely above the Y = 0 axis line (~0.85 B/yr breathing room)
% while keeping its top (~+5.4 B/yr) > 2.6 B/yr below the +8.1 B/yr J-curves!
metaD = igw_smart_incanvas_legend(axD, itemsD, struct('FontSize', 6.8, ...
    'PreferLocs', {{'southeast'}}, 'YMinDataFloor', 0.85, 'AutoExpandY', false));

xlabel(axD, 'Calendar Year (Each Trim-Tab''s J-Curve From Seed Outlay to Harvest)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.3, 'FontWeight', 'bold');
ylabel(axD, sprintf('Net Societal Flow per Trim-Tab (%s B/yr)', curr_iso_p), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.3, 'FontWeight', 'bold');
title(axD, 'D. Four Trim-Tab J-Curves: Sub-$1.5B Seeds Compound Into 8x-46x Returns', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.3, 'FontWeight', 'bold');

png_path = fullfile(OutputDir, sprintf('Fig_Phase2_HelmPhysics_TrimTabs_CounterSteering_%s.png', AnchorTag));
exportgraphics(fig, png_path, 'Resolution', 250, 'BackgroundColor', 'white');
fprintf('  -> Saved Phase II Naval Helm & Trim-Tab Dashboard to: %s\n', png_path);

if strcmpi(vis_mode, 'off') && ishghandle(fig), close(fig); end

Out = H;
Out.FigurePath    = png_path;
Out.TopRowSharedY = yl_top_shared;
Out.LegendMeta    = [metaA, metaB, metaC, metaD];
end
