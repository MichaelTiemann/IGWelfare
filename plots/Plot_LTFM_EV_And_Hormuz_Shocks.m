function Out = Plot_LTFM_EV_And_Hormuz_Shocks(Params, Opts)
%% PLOT_LTFM_EV_AND_HORMUZ_SHOCKS
% 3-Panel (3x2 Policy × Shock Natural Experiment + Fossil Price Assumptions) Dashboard:
%   Panel A (Top-Left, 2023-2065): Full LTFM Sinkhole across all 6 trajectories
%            ({Repeal vs. Keep vs. +30%/yr Boosted EV Credit} × {No Shock vs. Hormuz Shocks}).
%   Panel B (Top-Right, 2023-2036): Near-term zoom showing FY23-FY26 Actuals, upfront
%            seed cost of +20%/yr EV credit (2024-27), and post-2028 shock-hedged crossover.
%   Panel C (Bottom Full-Width, 2023-2065): Explicit Fossil-Fuel Price Assumptions
%            (Retail NZD/L Petrol & Diesel on Left Axis; Brent US$/bbl on Right Axis)
%            contrasting Calm-Water Equilibrium vs. Acute Spike (tau=2.4y) + Tail (tau=22y).

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('Profile_Name', 'NZ_Dunedin1972', 'dt', 3));
end
if nargin < 2 || isempty(Opts)
    Opts = struct();
end

OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
AnchorTag = Params.Calibration_Anchor;
def_font  = get(0, 'DefaultAxesFontName');

L = Compute_Hormuz_EV_Counterfactual_Ledger(Params);

vis_mode = IGW_UI_Style('headless_vis');
if isfield(Opts, 'Visible') && strcmpi(Opts.Visible, 'on')
    vis_mode = 'on';
end

fig = figure('Name', sprintf('LTFM Sinkhole, 3x2 EV Credit Counterfactuals & Hormuz Fossil Price Assumptions (%s)', AnchorTag), ...
    'Color', 'w', 'Position', [20, 20, 2160, 1340], 'Visible', vis_mode);

% Paired palette: Solid = With 2026 Hormuz Shocks; Dashed = Calm-Water No Shocks
c_crimson = [0.78, 0.12, 0.16]; % Repeal CCD + Hormuz Shock (Actual path)
c_slate   = [0.34, 0.40, 0.50]; % Repeal CCD + No Shock (Treasury LTFS 2025 Baseline)
c_amber   = [0.85, 0.45, 0.04]; % Keep CCD   + Hormuz Shock
c_teal    = [0.02, 0.55, 0.40]; % Keep CCD   + No Shock
c_navy    = [0.14, 0.30, 0.68]; % Boost +30%/yr CCD + Hormuz Shock
c_emerald = [0.00, 0.42, 0.24]; % Boost +30%/yr CCD + No Shock
c_purple  = [0.46, 0.18, 0.62]; % Brent Crude US$/bbl right-axis color
c_shk_bg  = [1.00, 0.91, 0.82]; % Shaded Strait of Hormuz shock window

% 2-over-1 spacious grid: Top-Left (Panel A), Top-Right (Panel B), Bottom-Wide (Panel C)
posA = [0.055, 0.535, 0.422, 0.405];
posB = [0.535, 0.535, 0.422, 0.405];
posC = [0.055, 0.072, 0.892, 0.372];

yr = L.Years;
w0 = L.Hormuz_Window(1);
w1 = L.Hormuz_Window(2);

% =========================================================================
% PANEL A: FULL LTFM HORIZON (2023-2065) — ALL 6 TRAJECTORIES (3x2 FAN)
% =========================================================================
axA = axes('Parent', fig, 'Position', posA, 'FontName', def_font);
hold(axA, 'on'); grid(axA, 'on'); box(axA, 'on');

yA_min = 30;
yA_max = 278; % Generous headroom for 7-item inside-northwest legend + open 2065 endpoints

h_bandA = patch(axA, [w0, w1, w1, w0], [yA_min, yA_min, yA_max, yA_max], c_shk_bg, ...
    'EdgeColor', [0.90, 0.58, 0.22], 'LineStyle', ':', 'LineWidth', 1.1, 'FaceAlpha', 0.75);
plot(axA, [2024, 2024], [yA_min, 145], 'k:', 'LineWidth', 1.1, 'HandleVisibility', 'off');

% Calm-water trio (dashed):
hA_1 = plot(axA, yr, L.Debt_1_Repeal_NoShock,   '--', 'Color', c_slate,   'LineWidth', 2.3);
hA_2 = plot(axA, yr, L.Debt_2_Keep_NoShock,     '--', 'Color', c_teal,    'LineWidth', 2.3);
hA_5 = plot(axA, yr, L.Debt_5_Boost_NoShock,    '--', 'Color', c_emerald, 'LineWidth', 2.6);

% Hormuz-shocked trio (solid):
hA_6 = plot(axA, yr, L.Debt_6_Boost_WithShock,  '-',  'Color', c_navy,    'LineWidth', 2.8);
hA_4 = plot(axA, yr, L.Debt_4_Keep_WithShock,   '-',  'Color', c_amber,   'LineWidth', 2.7);
hA_3 = plot(axA, yr, L.Debt_3_Repeal_WithShock, '-',  'Color', c_crimson, 'LineWidth', 3.2);

m_act = (yr <= 2026);
plot(axA, yr(m_act), L.Debt_3_Repeal_WithShock(m_act), 'o', 'MarkerSize', 6.2, ...
    'MarkerFaceColor', c_crimson, 'MarkerEdgeColor', 'w', 'LineWidth', 1.1, 'HandleVisibility', 'off');

% Unobstructed 2065 right-hand terminal markers & staggered labels:
d65 = [L.Debt_3_Repeal_WithShock(end); ... % 1: Repeal + Shock (highest)
       L.Debt_4_Keep_WithShock(end);   ... % 2: Keep + Shock
       L.Debt_1_Repeal_NoShock(end);   ... % 3: LTFS No Shock (200.0%)
       L.Debt_6_Boost_WithShock(end);  ... % 4: Boost +30%/yr + Shock! (Beats unshocked LTFS!)
       L.Debt_2_Keep_NoShock(end);     ... % 5: Keep + No Shock
       L.Debt_5_Boost_NoShock(end)];       % 6: Boost +30%/yr + No Shock (lowest)

plot(axA, 2065 * ones(6, 1), d65, 'o', 'MarkerSize', 5.8, ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.3, 'HandleVisibility', 'off');

% Sort terminal labels strictly cleanly by vertical height so zero labels ever touch:
lbl_cols = {c_crimson, c_amber, c_slate, c_navy, c_teal, c_emerald};
lbl_tags = {'Repeal+Shk', 'Keep+Shk', 'LTFS Base', 'Boost+Shk', 'Keep Calm', 'Boost Calm'};
[d65_sort, ord65] = sort(d65, 'descend');
y_lbl65 = d65_sort;
min_gapA = 7.6;
for k = 2:6
    if y_lbl65(k-1) - y_lbl65(k) < min_gapA
        y_lbl65(k) = y_lbl65(k-1) - min_gapA;
    end
end
for k = 1:6
    idx_orig = ord65(k);
    text(axA, 2065.5, y_lbl65(k), sprintf('%.1f%% (%s)', d65(idx_orig), lbl_tags{idx_orig}), ...
        'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.3, 'FontWeight', 'bold', ...
        'Color', lbl_cols{idx_orig}, 'Clipping', 'on');
end

% Key insight callout in mid-plot open pocket:
save_boost_shk = d65(1) - d65(4);
save_keep_shk  = d65(1) - d65(2);
text(axA, 2030.5, 138, sprintf(['2065 Debt Saved vs. Actual Repeal+Hormuz:\n' ...
    '• Keep CCD (Self-Funding): -%.1f pp GDP\n' ...
    '• +30%%/yr Boosted CCD (2.2x in 3y): -%.1f pp GDP\n' ...
    '  (Even WITH Hormuz shocks, Boosted CCD beats\n' ...
    '   Treasury''s unshocked 200%% LTFS baseline!)'], ...
    save_keep_shk, save_boost_shk), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.3, 'FontWeight', 'bold', ...
    'Color', [0.14, 0.20, 0.34], 'BackgroundColor', 'w', 'EdgeColor', c_navy, 'Margin', 2.5);

xlim(axA, [2023, 2075.5]); xticks(axA, 2025:5:2065);
ylim(axA, [yA_min, yA_max]);
xlabel(axA, 'Fiscal Year (Treasury He Tirohanga Mokopuna Horizon: 2023-2065)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.6, 'FontWeight', 'bold');
ylabel(axA, 'Net Core Crown Debt (% of GDP)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.8, 'FontWeight', 'bold');
title(axA, 'A. 3x2 LTFM Sinkhole (2023-2065): Repeal vs. Keep vs. +30%/yr Boosted EV Credit', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.6, 'FontWeight', 'bold');

lgdA = legend(axA, [hA_3, hA_4, hA_6, hA_1, hA_2, hA_5, h_bandA], { ...
    'Actual 2023-26 -> Ended EV Credit + Hormuz Shocks', ...
    'Kept EV Credit + Hormuz Shocks', ...
    '+30%/yr Boosted EV Credit (2.2x in 3y) + Hormuz Shocks', ...
    'Treasury SS0 LTFM Baseline (Ended Credit, No Shocks)', ...
    'Kept EV Credit (No Oil Shocks)', ...
    '+30%/yr Boosted EV Credit (No Oil Shocks)', ...
    '2026-28 Strait of Hormuz Acute Oil Shock Window'}, ...
    'Location', 'northwest', 'FontSize', 6.8);
IGW_UI_Style('legend_alpha', lgdA, 0.94);

% =========================================================================
% PANEL B: NEAR-TERM TACTICAL ZOOM (2023-2036) — SEED COST VS. SHOCK PAYOFF
% =========================================================================
axB = axes('Parent', fig, 'Position', posB, 'FontName', def_font);
hold(axB, 'on'); grid(axB, 'on'); box(axB, 'on');

m_zoom = (yr <= 2036);
yz     = yr(m_zoom);
yB_min = 37.5;
yB_max = 64.5;

h_bandB = patch(axB, [w0, w1, w1, w0], [yB_min, yB_min, yB_max, yB_max], c_shk_bg, ...
    'EdgeColor', [0.90, 0.58, 0.22], 'LineStyle', ':', 'LineWidth', 1.1, 'FaceAlpha', 0.75);
plot(axB, [2023.98, 2023.98], [yB_min, 50.5], 'k:', 'LineWidth', 1.2, 'HandleVisibility', 'off');

hB_1 = plot(axB, yz, L.Debt_1_Repeal_NoShock(m_zoom),   '--', 'Color', c_slate,   'LineWidth', 2.3);
hB_2 = plot(axB, yz, L.Debt_2_Keep_NoShock(m_zoom),     '--', 'Color', c_teal,    'LineWidth', 2.3);
hB_5 = plot(axB, yz, L.Debt_5_Boost_NoShock(m_zoom),    '--', 'Color', c_emerald, 'LineWidth', 2.6);

hB_6 = plot(axB, yz, L.Debt_6_Boost_WithShock(m_zoom),  '-',  'Color', c_navy,    'LineWidth', 2.8);
hB_4 = plot(axB, yz, L.Debt_4_Keep_WithShock(m_zoom),   '-',  'Color', c_amber,   'LineWidth', 2.7);
hB_3 = plot(axB, yz, L.Debt_3_Repeal_WithShock(m_zoom), '-',  'Color', c_crimson, 'LineWidth', 3.2);

m_act_z = (yz <= 2026);
h_act = plot(axB, yz(m_act_z), L.Debt_3_Repeal_WithShock(m_act_z), 'o', 'MarkerSize', 7.0, ...
    'MarkerFaceColor', c_crimson, 'MarkerEdgeColor', 'w', 'LineWidth', 1.2);

% Annotate the upfront 2024-2027 Boosted-Credit seed investment -> 2028 crossover:
text(axB, 2024.10, 38.55, sprintf(['2024-27 Trim-Tab Seed:\n' ...
    '+30%%/yr EV rebate ($7k→$15.4k Yr3)\n' ...
    'adds ~0.35pp upfront debt, then\n' ...
    'crosses BELOW Keep-CCD in 2028!']), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.1, 'FontWeight', 'bold', ...
    'Color', c_navy, 'BackgroundColor', [0.96 0.98 1.00], 'EdgeColor', c_navy, 'Margin', 2.0);

idx28 = find(yz == 2028, 1);
text(axB, 2028.1, L.Debt_3_Repeal_WithShock(idx28) + 1.15, ...
    'PREFU Post-Hormuz Step (~43.9%)', 'Interpreter', 'none', 'FontName', def_font, ...
    'FontSize', 7.3, 'FontWeight', 'bold', 'Color', c_crimson, 'HorizontalAlignment', 'center');

% 2036 Terminal markers & collision-free sorted labels on right:
d36 = [L.Debt_3_Repeal_WithShock(yz==2036); ...
       L.Debt_4_Keep_WithShock(yz==2036);   ...
       L.Debt_1_Repeal_NoShock(yz==2036);   ...
       L.Debt_6_Boost_WithShock(yz==2036);  ...
       L.Debt_2_Keep_NoShock(yz==2036);     ...
       L.Debt_5_Boost_NoShock(yz==2036)];

plot(axB, 2036 * ones(6, 1), d36, 'o', 'MarkerSize', 5.8, ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.3, 'HandleVisibility', 'off');

[d36_sort, ord36] = sort(d36, 'descend');
y_lbl36 = d36_sort;
min_gapB = 0.88;
for k = 2:6
    if y_lbl36(k-1) - y_lbl36(k) < min_gapB
        y_lbl36(k) = y_lbl36(k-1) - min_gapB;
    end
end
for k = 1:6
    idx_orig = ord36(k);
    text(axB, 2036.18, y_lbl36(k), sprintf('%.1f%%', d36(idx_orig)), ...
        'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.5, 'FontWeight', 'bold', ...
        'Color', lbl_cols{idx_orig}, 'Clipping', 'on');
end

% Cumulative 2024-2036 FX Savings comparison in lower-right clear pocket:
cum_fx_keep  = sum(L.Fuel_3_Repeal_WithShock_B(m_zoom) - L.Fuel_4_Keep_WithShock_B(m_zoom));
cum_fx_boost = sum(L.Fuel_3_Repeal_WithShock_B(m_zoom) - L.Fuel_6_Boost_WithShock_B(m_zoom));
text(axB, 2029.8, 39.2, sprintf(['2024-36 Imported Fuel FX Saved (under Shock):\n' ...
    '• Keep CCD vs. Repeal: +NZD %.1fB kept onshore\n' ...
    '• +30%%/yr Boost vs. Repeal: +NZD %.1fB kept onshore'], cum_fx_keep, cum_fx_boost), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.2, 'FontWeight', 'bold', ...
    'Color', [0.02 0.36 0.24], 'BackgroundColor', [0.96 1.00 0.98], 'EdgeColor', c_teal, 'Margin', 2.2);

xlim(axB, [2023, 2037.8]); xticks(axB, 2023:2:2036);
ylim(axB, [yB_min, yB_max]);
xlabel(axB, 'Fiscal Year Zoom (2023-2036: Upfront Rebate Outlay vs. 2026-28 Shock Hedge)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.6, 'FontWeight', 'bold');
ylabel(axB, 'Net Core Crown Debt (% of GDP)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.8, 'FontWeight', 'bold');
title(axB, 'B. 2023-2036 Tactical Zoom: +30%/yr EV Credit Pays Off Inside First Oil Shock', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.6, 'FontWeight', 'bold');

lgdB = legend(axB, [h_act, hB_3, hB_4, hB_6, hB_1, hB_2, hB_5], { ...
    'Actual Treasury Outturn (FY2023-FY2026)', ...
    'Ended Credit + Hormuz Shocks (Actual)', ...
    'Kept Credit + Hormuz Shocks', ...
    '+30%/yr Boosted Credit + Hormuz Shocks', ...
    'Treasury LTFM Baseline (No Shocks)', ...
    'Kept Credit (No Shocks)', ...
    '+30%/yr Boosted Credit (No Shocks)'}, ...
    'Location', 'northwest', 'FontSize', 6.8);
IGW_UI_Style('legend_alpha', lgdB, 0.94);

% =========================================================================
% PANEL C: FOSSIL FUEL PRICE ASSUMPTIONS OVER TIME (SHOCK VS. EQUILIBRIUM)
% =========================================================================
axC = axes('Parent', fig, 'Position', posC, 'FontName', def_font);
yyaxis(axC, 'left'); hold(axC, 'on'); grid(axC, 'on'); box(axC, 'on');

yC_min = 1.65;
yC_max = 4.65; % Generous top headroom so inside-northeast legend never crowds curves or 2065 endpoints!

h_bandC = patch(axC, [w0, w1, w1, w0], [yC_min, yC_min, yC_max, yC_max], c_shk_bg, ...
    'EdgeColor', [0.90, 0.58, 0.22], 'LineStyle', ':', 'LineWidth', 1.1, 'FaceAlpha', 0.72);

% NZ Retail Pump Prices (Left Axis: Real 2026 NZD / Litre):
hC_pEq  = plot(axC, yr, L.Petrol_Eq_NZD,    '--', 'Color', c_slate,   'LineWidth', 2.2);
hC_dEq  = plot(axC, yr, L.Diesel_Eq_NZD,    ':',  'Color', c_teal,    'LineWidth', 2.2);
hC_pShk = plot(axC, yr, L.Petrol_Shock_NZD, '-',  'Color', c_crimson, 'LineWidth', 3.0);
hC_dShk = plot(axC, yr, L.Diesel_Shock_NZD, '-.', 'Color', c_amber,   'LineWidth', 2.8);

% Peak 2026 Shock Markers:
idx26_all = find(yr == 2026, 1);
plot(axC, [2026; 2026], [L.Petrol_Shock_NZD(idx26_all); L.Diesel_Shock_NZD(idx26_all)], 'o', ...
    'MarkerSize', 7.0, 'MarkerFaceColor', c_crimson, 'MarkerEdgeColor', 'w', 'LineWidth', 1.2, 'HandleVisibility', 'off');

text(axC, 2026.55, L.Petrol_Shock_NZD(idx26_all) + 0.16, ...
    sprintf('2026 Hormuz Peak: Petrol NZD %.2f/L (+38%%) | Diesel NZD %.2f/L (+71%% refinery crunch)', ...
    L.Petrol_Shock_NZD(idx26_all), L.Diesel_Shock_NZD(idx26_all)), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 8.0, 'FontWeight', 'bold', 'Color', c_crimson);

% Explicit Parameter Box Explaining Acute Decay vs. Structural Tail vs. Equilibrium:
text(axC, 2033.5, 3.88, sprintf(['Shock vs. Equilibrium Price Structure:\n' ...
    '1. Calm-Water Equilibrium: US$80/bbl (2023) drifting +0.45%%/yr real (extraction + ETS)\n' ...
    '2. Acute Hormuz Blockade & Refinery Spike (2026-29): e-folding tau = %.1f yrs (half-life 1.7 yrs)\n' ...
    '3. Structural Geopolitical / War-Risk & Freight Tail: +13%%-18%% wedge, decaying with tau = %.0f yrs'], ...
    L.Tau_Acute_Yrs, L.Tau_Tail_Yrs), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.7, 'FontWeight', 'bold', ...
    'Color', [0.18 0.20 0.26], 'BackgroundColor', 'w', 'EdgeColor', [0.55 0.58 0.65], 'Margin', 3.0);

ylabel(axC, 'NZ Retail Fuel Price (Real 2026 NZD / Litre)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.8, 'FontWeight', 'bold');
ylim(axC, [yC_min, yC_max]);
set(vfi_active_ax(axC), 'YColor', [0.15 0.15 0.15]);

% Right Axis: World Brent Crude Benchmark (Aligned linearly: NZD/L * 37.5 ~= US$/bbl -> 2.13 NZD/L = US$80/bbl):
yyaxis(axC, 'right'); hold(axC, 'on');
hC_bEq  = plot(axC, yr, L.Brent_Eq_USD,    '--', 'Color', [0.58 0.42 0.72], 'LineWidth', 2.0);
hC_bShk = plot(axC, yr, L.Brent_Shock_USD, '-',  'Color', c_purple,         'LineWidth', 2.6);
ylabel(axC, 'World Brent Crude Benchmark (Real 2026 US$ / bbl)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.8, 'FontWeight', 'bold');
ylim(axC, [yC_min * 37.5, yC_max * 37.5]); % Exact proportional alignment (~US$62 to ~US$174/bbl)
set(vfi_active_ax(axC), 'YColor', c_purple);
yyaxis(axC, 'left');

% Right-hand 2065 terminal price labels (completely clear below legend):
text(axC, 2065.35, L.Petrol_Shock_NZD(end) + 0.08, sprintf('NZD %.2f/L', L.Petrol_Shock_NZD(end)), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.6, 'FontWeight', 'bold', 'Color', c_crimson);
text(axC, 2065.35, L.Petrol_Eq_NZD(end) - 0.08, sprintf('NZD %.2f/L (Eq)', L.Petrol_Eq_NZD(end)), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.5, 'FontWeight', 'bold', 'Color', c_slate);
text(axC, 2065.35, L.Diesel_Shock_NZD(end) + 0.07, sprintf('NZD %.2f/L', L.Diesel_Shock_NZD(end)), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.6, 'FontWeight', 'bold', 'Color', c_amber);
text(axC, 2065.35, L.Diesel_Eq_NZD(end) - 0.07, sprintf('NZD %.2f/L (Eq)', L.Diesel_Eq_NZD(end)), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.5, 'FontWeight', 'bold', 'Color', c_teal);

xlim(axC, [2023, 2068.5]); xticks(axC, 2025:5:2065);
xlabel(axC, 'Calendar Year (2023-2065: Acute 2026-28 Spike, Medium-Run Re-Equilibration & Long-Run Tail)', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 9.8, 'FontWeight', 'bold');
title(axC, 'C. Fossil Fuel Price Assumptions: Calm-Water Equilibrium vs. 2026 Strait of Hormuz Oil & Diesel Shock', ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 10.6, 'FontWeight', 'bold');

lgdC = legend(axC, [hC_pShk, hC_dShk, hC_bShk, hC_pEq, hC_dEq, hC_bEq], { ...
    'Retail Petrol w/ Hormuz Shock (NZD/L, Left)', ...
    'Retail Diesel w/ Hormuz Shock (NZD/L, Left)', ...
    'Brent Crude w/ Hormuz Shock (US$/bbl, Right)', ...
    'Equilibrium Petrol — No Shock (NZD/L, Left)', ...
    'Equilibrium Diesel — No Shock (NZD/L, Left)', ...
    'Equilibrium Brent — No Shock (US$/bbl, Right)'}, ...
    'Location', 'northeast', 'FontSize', 7.0);
IGW_UI_Style('legend_alpha', lgdC, 0.94);

Out_PNG = fullfile(OutputDir, sprintf('Fig_LTFM_EV_Credit_And_Hormuz_OilShocks_%s.png', AnchorTag));
Out_CSV = fullfile(OutputDir, sprintf('Table_LTFM_EV_Credit_And_Hormuz_OilShocks_%s.csv', AnchorTag));

writetable(L.SummaryTable, Out_CSV);
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Exported 3x2 Hormuz & EV Counterfactual CSV to: %s\n', Out_CSV);
fprintf('  -> Saved 3-Panel LTFM × Boosted EV Credit × Fossil Price Figure to: %s\n', Out_PNG);

if strcmpi(vis_mode, 'off')
    close(fig);
end

Out = L;
Out.FigurePath = Out_PNG;
Out.TablePath  = Out_CSV;
end
