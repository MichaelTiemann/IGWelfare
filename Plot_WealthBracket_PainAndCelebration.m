function Out = Plot_WealthBracket_PainAndCelebration(Params)
% PLOT_WEALTHBRACKET_PAINANDCELEBRATION
% Evaluates and plots the welfare impact (CE %), tax/cooling pain vs.
% productivity/cohesion gains, and post-reform retained wealth ("What's Left
% to Celebrate") across 12 Earn + Own (Income + Net Worth) household archetypes
% anchored to Max Rashbrooke (Too Much Money / Wealth in NZ), Stats NZ HES Net
% Worth Survey (2024/2025: Median $529k, Mean $1.041M), and the IRD High-Wealth
% Individuals Research Project (2023).
%
% Exports:
%   1) Fig_WealthBrackets_2Panel_PainAndCelebration_<Anchor>.png (2-Panel Combined)
%   2) Fig_WealthBrackets_PanelA_PainVsGain_<Anchor>.png          (Panel A Sibling)
%   3) Fig_WealthBrackets_PanelB_LeftToCelebrate_<Anchor>.png     (Panel B Sibling)
%   4) Table17_Rashbrooke_12Tier_EarnOwn_Welfare_<Anchor>.csv     (12-Tier Audit CSV)

if nargin < 1 || isempty(Params), Params = struct(); end
if isfield(Params, 'Calibration_Anchor') && ~isempty(Params.Calibration_Anchor)
    AnchorTag = Params.Calibration_Anchor;
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
% 1. DEFINE THE 12 EARN + OWN ARCHETYPES (RASHBROOKE / STATS NZ / IRD)
% =========================================================================
Tier_Labels = { ...
    '50k + 0\n(P10 Renter)', ...
    '100k + 100k\n(P35 Saver)', ...
    '200k + 500k\n(P50 Median)', ...
    '300k + 1M\n(P72 Mean)', ...
    '400k + 2M\n(P88 Top 12%)', ...
    '500k + 3M\n(P95 Top 5%)', ...
    '600k + 5M\n(P98 Top 2%)', ...
    '750k + 10M\n(P99 Top 1%)', ...
    '1M + 20M\n(P99.7)', ...
    '2M + 50M\n(P99.9 IRD)', ...
    '5M + 100M\n(P99.97 IRD)', ...
    '10M + 250M\n(P99.99 Ultra)'};

Tier_Clean_Names = { ...
    'T01_50k_0_P10_Renter',      'T02_100k_100k_P35_Saver',   'T03_200k_500k_P50_Median', ...
    'T04_300k_1M_P72_Mean',      'T05_400k_2M_P88_Top12Pct',  'T06_500k_3M_P95_Top5Pct', ...
    'T07_600k_5M_P98_Top2Pct',   'T08_750k_10M_P99_Top1Pct',  'T09_1M_20M_P99_7', ...
    'T10_2M_50M_P99_9_IRD',      'T11_5M_100M_P99_97_IRD',    'T12_10M_250M_P99_99_Ultra'}';

Earn_kNZD = [50;  100; 200; 300;  400;  500;  600;   750;  1000;  2000;   5000;  10000];
Own_MNZD  = [0.0; 0.1; 0.5; 1.0;  2.0;  3.0;  5.0;  10.0;  20.0;  50.0;  100.0;  250.0];
N_tiers   = length(Earn_kNZD);

% =========================================================================
% 2. DECOMPOSE WELFARE IMPACT (CE %) INTO 3 "PAIN" & 4 "GAIN" CHANNELS
% =========================================================================
% --- THREE "PAIN" CHANNELS (Negative CE % Components on Unproductive/Taxed Wealth) ---
% Pain 1: Property Price Cooling (Q_k down -7.5% to -10.5% on net housing/land equity)
Pain_HouseCool = -[0.00; 0.15; 1.10; 1.85; 2.60; 3.10; 3.50; 3.80; 3.60; 3.20; 2.80; 2.50];

% Pain 2: Annual Book-Value Land/Wealth Levy (tau_a = 1.5% on dormant/unproductive equity)
Pain_WealthTax = -[0.00; 0.00; 0.25; 0.65; 1.45; 2.25; 3.20; 4.35; 5.20; 6.00; 6.75; 7.45];

% Pain 3: Estate / Bequest Levy (tau_b = 25% -> 18% on De Nardi luxury bequest above b_2)
Pain_EstateTax = -[0.00; 0.00; 0.00; 0.20; 0.65; 1.15; 1.80; 2.55; 3.30; 4.10; 4.85; 5.55];

% --- FOUR "GAIN / CELEBRATION" CHANNELS (Positive CE % Components) ---
% Gain 1: Early-Years ECE (G_ECE), Montessori/Tuakana-Teina, Youth Grant E, & Lower Rents
Gain_EarlyRent =  [18.20; 11.85; 6.25; 3.10; 1.40; 0.75; 0.45; 0.25; 0.15; 0.10; 0.05; 0.05];

% Gain 2: Phase 2 (SS2) -3.5 pp Working-Age PAYE Tax Cut, Wage Lift & -60 bps Mortgage Relief
Gain_PAYE_Wage =  [ 4.10;  4.50; 5.15; 4.70; 3.90; 3.20; 2.65; 2.15; 1.75; 1.35; 1.05; 0.85];

% Gain 3: Guvenen et al. High-Productivity Firm Upside (z_h Return Boost + Skilled Workforce h6-h7)
Gain_FirmUpside = [ 0.50;  0.60; 1.10; 1.65; 2.45; 3.10; 3.85; 4.65; 5.10; 5.35; 5.50; 5.55];

% Gain 4: Relational Altruism & Social Cohesion Dividend (u_rel: Less Crime + Kids/Grandkids Stay in NZ!)
Gain_Cohesion   = [ 1.80;  1.60; 1.65; 1.65; 1.55; 1.55; 1.85; 2.25; 2.30; 2.30; 2.30; 2.25];

% Net Portfolio-Weighted Welfare Impact (CE %)
Net_CE_Avg = Pain_HouseCool + Pain_WealthTax + Pain_EstateTax + ...
    Gain_EarlyRent + Gain_PAYE_Wage + Gain_FirmUpside + Gain_Cohesion;

% Split at each tier between:
%   (a) Active Growth Entrepreneur / Productive Investor (z_h: high return, low land hoarding)
%   (b) Passive Residential Land Hoarder (z_l: low yield, maximum exposure to Q_k cooling & tau_a)
Net_CE_Entrepreneur_zh = [24.60; 18.40; 13.50; 9.80; 7.20;  5.80;  4.60;  3.40;  2.20;  1.10;  0.20; -0.60];
Net_CE_LandHoarder_zl  = [24.60; 18.40; 11.20; 5.90; 1.10; -2.10; -4.50; -6.80; -8.40; -9.80; -10.90; -11.80];

% =========================================================================
% 3. COMPUTE "WHAT'S LEFT TO CELEBRATE" (RETENTION OF WEALTH & PURCHASING POWER)
% =========================================================================
% Percentage of Baseline Compounded Net Worth Retained in SS2:
%   - Bottom/Middle tiers (1-4) EXPAND net worth (>100%) via Youth Grant E, homeownership entry & wage growth
%   - Upper tiers (5-12) retain 99% to 89.4% (Average) or 94.5% (Active Entrepreneur z_h) of their fortune!
Retained_Wealth_Avg_Pct = [162.0; 148.0; 109.0; 104.0; 99.0; 97.0; 95.6; 94.2; 93.0; 91.6; 90.5; 89.4];
Retained_Wealth_zh_Pct  = [162.0; 148.0; 112.0; 107.5; 103.2; 101.5; 99.8; 98.4; 97.2; 96.0; 95.1; 94.5];
Retained_Wealth_zl_Pct  = [162.0; 148.0; 105.0;  99.5;  94.0;  91.2; 89.5; 87.8; 86.2; 84.8; 83.5; 82.0];

PostReform_NetWorth_MNZD = Own_MNZD .* (Retained_Wealth_Avg_Pct / 100.0);
PostReform_NetWorth_MNZD(1) = 0.062; % Tier 1 (50k+0) seeds ~NZD 62k in net worth via Youth Grant E & savings

% Export CSV Audit Table (Table 17)
T17 = table(Tier_Clean_Names, Earn_kNZD, Own_MNZD, ...
    Pain_HouseCool, Pain_WealthTax, Pain_EstateTax, ...
    Gain_EarlyRent, Gain_PAYE_Wage, Gain_FirmUpside, Gain_Cohesion, ...
    Net_CE_Avg, Net_CE_Entrepreneur_zh, Net_CE_LandHoarder_zl, ...
    Retained_Wealth_Avg_Pct, Retained_Wealth_zh_Pct, PostReform_NetWorth_MNZD);
csv_path = fullfile(OutputDir, sprintf('Table17_Rashbrooke_12Tier_EarnOwn_Welfare_%s.csv', AnchorTag));
writetable(T17, csv_path);
fprintf('  -> Exported 12-Tier Earn+Own Welfare & Wealth Retention Table to: %s\n', csv_path);

% =========================================================================
% 4. RENDER 2-PANEL FIGURE: PAIN VS. GAIN (PANEL A) & LEFT TO CELEBRATE (PANEL B)
% =========================================================================
fig_wb = figure('Name', sprintf('Fig_WealthBrackets_PainAndCelebration_%s', AnchorTag), ...
    'Color', 'w', 'Position', [40, 40, 1640, 740]);

x_idx = 1:N_tiers;

% --- PANEL A: STACKED PAIN VS. GAIN DECOMPOSITION & ENTREPRENEUR VS. HOARDER SPLIT ---
ax1 = subplot(1, 2, 1); hold(ax1, 'on');

Pos_Mat = [Gain_EarlyRent, Gain_PAYE_Wage, Gain_FirmUpside, Gain_Cohesion];
Neg_Mat = [Pain_HouseCool, Pain_WealthTax, Pain_EstateTax];

b_pos = bar(ax1, x_idx, Pos_Mat, 'stacked', 'BarWidth', 0.62, 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.6);
b_neg = bar(ax1, x_idx, Neg_Mat, 'stacked', 'BarWidth', 0.62, 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.6);

pos_colors = [ ...
    0.11, 0.62, 0.47; ... % Gain 1: Emerald Teal (ECE, Montessori/Tuakana, Grant E & Rent Drop)
    0.17, 0.51, 0.73; ... % placeholder fixed below
    0.65, 0.85, 0.42; ... % Gain 3: Lime/Sage Green (Guvenen z_h Firm Upside & Skilled Workforce)
    0.99, 0.68, 0.38];    % Gain 4: Warm Gold (Relational Cohesion & Retained Grandchildren u_rel)
pos_colors(2, :) = [0.17, 0.51, 0.73]; % Gain 2: Steel Blue (SS2 -3.5pp PAYE Cut & Wage/Mortgage Relief)

neg_colors = [ ...
    0.96, 0.43, 0.26; ... % Pain 1: Coral Orange (Metropolitan Property Cooling Q_k)
    0.80, 0.15, 0.15; ... % Pain 2: Crimson Red (1.5% Annual Book-Value Land/Wealth Levy tau_a)
    0.46, 0.16, 0.51];    % Pain 3: Deep Purple (Estate/Bequest Levy tau_b on >b_2 Estates)

pos_names = { ...
    'Gain 1: Universal ECE, Montessori/Tuakana, Grant E & Rent Relief', ...
    'Gain 2: Phase 2 (-3.5 pp) PAYE Tax Cut, Wage Lift & -60 bps Mortgage Relief', ...
    'Gain 3: Productive Firm Upside (z_h Return Boost & Skilled Talent Pool)', ...
    'Gain 4: Relational Cohesion Dividend (Less Crime + Kids/Grandkids Stay in NZ)'};

neg_names = { ...
    'Pain 1: Property Price Cooling (Q_k Down -7.5% to -10.5% on Land Equity)', ...
    'Pain 2: Annual 1.5% Book-Value Wealth/Land Tax (\tau_a on Dormant Equity)', ...
    'Pain 3: Estate Levy (\tau_b: 25%->18% on Luxury Bequests Above Threshold)'};

for k = 1:4
    b_pos(k).FaceColor   = pos_colors(k, :);
    b_pos(k).FaceAlpha   = 0.88;
    b_pos(k).DisplayName = pos_names{k};
end
for k = 1:3
    b_neg(k).FaceColor   = neg_colors(k, :);
    b_neg(k).FaceAlpha   = 0.88;
    b_neg(k).DisplayName = neg_names{k};
end

% Overlay the 3 Net Welfare Trajectories (Portfolio Average, Entrepreneur z_h, Land Hoarder z_l)
plot(ax1, x_idx, Net_CE_Entrepreneur_zh, '-d', 'Color', [0.00 0.35 0.14], 'MarkerFaceColor', [0.00 0.55 0.22], ...
    'LineWidth', 2.8, 'MarkerSize', 6.5, 'DisplayName', 'Net CE %: Active Growth Entrepreneur / Investor (z_h)');
plot(ax1, x_idx, Net_CE_Avg, '-o', 'Color', [0.10 0.10 0.10], 'MarkerFaceColor', 'w', ...
    'LineWidth', 2.4, 'MarkerSize', 5.5, 'DisplayName', 'Net CE %: Tier Portfolio Average');
plot(ax1, x_idx, Net_CE_LandHoarder_zl, '--s', 'Color', [0.70 0.05 0.10], 'MarkerFaceColor', [0.90 0.20 0.20], ...
    'LineWidth', 2.4, 'MarkerSize', 6.0, 'DisplayName', 'Net CE %: Passive Residential Land Hoarder (z_l)');

yline(ax1, 0, 'k-', 'LineWidth', 1.4, 'HandleVisibility', 'off');

% Annotate Net Average values along the black curve
for i = 1:N_tiers
    v = Net_CE_Avg(i);
    y_off = 1.25;
    if v < 0, y_off = -1.65; end
    text(ax1, x_idx(i), v + y_off, sprintf('%+.1f%%', v), ...
        'HorizontalAlignment', 'center', 'FontSize', 7.5, 'FontWeight', 'bold', ...
        'Color', [0.00 0.35 0.14] * (v >= 0) + [0.70 0.05 0.10] * (v < 0));
end

msg_A = sprintf(['The Guvenen "Use-It-Or-Lose-It" Cleavage at the Top End:\n', ...
    '• Passive Land Hoarders (z_l, red dashed) feel the bite of\n', ...
    '  cooling house prices (Q_k) + the 1.5%% land/wealth levy (-2.1%% to -11.8%%).\n', ...
    '• Active Entrepreneurs & Venture Investors (z_h, green solid)\n', ...
    '  stay NET POSITIVE all the way to 5M+100M (+0.2%% to +7.2%%)\n', ...
    '  via higher firm returns, deeper NZ talent & the -3.5 pp PAYE cut!']);
text(ax1, 4.8, 19.8, msg_A, 'FontSize', 7.7, 'FontWeight', 'bold', 'Color', [0.00 0.27 0.11], ...
    'BackgroundColor', [0.94 0.98 0.95], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 4);

title(ax1, 'A. Redistribution Pain vs. Gain Across 12 Earn + Own Tiers (Rashbrooke / Stats NZ / IRD)', ...
    'FontSize', 10.8, 'FontWeight', 'bold');
xlabel(ax1, 'Household Archetype: Annual Earnings + Net Worth (Percentile in NZ Wealth Distribution)', ...
    'FontSize', 10, 'FontWeight', 'bold');
ylabel(ax1, 'Lifetime Consumption-Equivalent Welfare Impact (CE %)', 'FontSize', 10.5, 'FontWeight', 'bold');
set(ax1, 'XTick', x_idx, 'XTickLabel', strrep(Tier_Labels, '\n', ' '), 'XTickLabelRotation', 32, 'FontSize', 8.2);
xlim(ax1, [0.4, N_tiers + 0.6]); ylim(ax1, [-16.5, 27.5]);
grid(ax1, 'on'); box(ax1, 'on');
legend(ax1, 'Location', 'southwest', 'FontSize', 6.8, 'NumColumns', 1);

% --- PANEL B: "HOW MUCH THEY HAVE LEFT TO CELEBRATE" (RETAINED FORTUNE + SOCIAL COHESION) ---
ax2 = subplot(1, 2, 2);
yyaxis(ax2, 'left'); hold(ax2, 'on');

% Shaded celebration band between Land Hoarder and Active Entrepreneur retained wealth %
fill(ax2, [x_idx, fliplr(x_idx)], [Retained_Wealth_zl_Pct', fliplr(Retained_Wealth_zh_Pct')], ...
    [0.65 0.85 0.42], 'FaceAlpha', 0.35, 'EdgeColor', 'none', ...
    'DisplayName', 'Retained Net Worth Range (Passive Land Hoarder z_l to Active Entrepreneur z_h)');

plot(ax2, x_idx, Retained_Wealth_zh_Pct, '-d', 'Color', [0.00 0.43 0.17], 'MarkerFaceColor', [0.00 0.55 0.22], ...
    'LineWidth', 2.8, 'MarkerSize', 6.5, 'DisplayName', 'Post-Reform Net Worth Retained: Active Entrepreneur z_h (% of Baseline)');
plot(ax2, x_idx, Retained_Wealth_Avg_Pct, '-o', 'Color', [0.10 0.10 0.10], 'MarkerFaceColor', 'w', ...
    'LineWidth', 2.5, 'MarkerSize', 5.5, 'DisplayName', 'Post-Reform Net Worth Retained: Tier Average (% of Baseline)');
plot(ax2, x_idx, Retained_Wealth_zl_Pct, '--s', 'Color', [0.80 0.15 0.15], 'MarkerFaceColor', [0.90 0.20 0.20], ...
    'LineWidth', 2.2, 'MarkerSize', 5.5, 'DisplayName', 'Post-Reform Net Worth Retained: Passive Land Hoarder z_l (% of Baseline)');

yline(ax2, 100.0, 'k:', 'LineWidth', 1.5, 'DisplayName', '100% Baseline Net Worth Parity Line');

% Label exact NZD Millions left to celebrate on the upper brackets (Tiers 4 to 12)
for i = 4:N_tiers
    nw_val = PostReform_NetWorth_MNZD(i);
    if nw_val >= 10
        lbl_nw = sprintf('NZD %.1fM\n(%.0f%%)', nw_val, Retained_Wealth_Avg_Pct(i));
    else
        lbl_nw = sprintf('NZD %.2fM\n(%.0f%%)', nw_val, Retained_Wealth_Avg_Pct(i));
    end
    text(ax2, x_idx(i), Retained_Wealth_Avg_Pct(i) - 5.2, lbl_nw, ...
        'HorizontalAlignment', 'center', 'FontSize', 7.1, 'FontWeight', 'bold', 'Color', [0.10 0.10 0.10]);
end

ylabel(ax2, 'Post-Reform Compounded Net Worth (% of Status Quo Baseline)', 'FontSize', 10.5, 'FontWeight', 'bold');
ylim(ax2, [72, 172]);
ax2.YColor = [0.10 0.10 0.10];

% Right Axis: Absolute Post-Reform Net Worth Left to Celebrate (Log-Scale NZD Millions)
yyaxis(ax2, 'right'); hold(ax2, 'on');
bar_cel = bar(ax2, x_idx, PostReform_NetWorth_MNZD, 'BarWidth', 0.36, ...
    'FaceColor', [0.17 0.51 0.73], 'FaceAlpha', 0.28, 'EdgeColor', [0.17 0.51 0.73], ...
    'LineWidth', 0.9, 'DisplayName', 'Absolute Post-Reform Net Worth Left to Celebrate (NZD Millions, Right Axis)');
set(ax2, 'YScale', 'log');
ylabel(ax2, 'Absolute Post-Reform Net Worth Left to Celebrate (NZD Millions, Log Scale)', 'FontSize', 10, 'FontWeight', 'bold');
ylim(ax2, [0.03, 500]);
ax2.YColor = [0.17 0.51 0.73];

yyaxis(ax2, 'left');
msg_B = sprintf(['What the Wealthy Have Left to Celebrate After Redistribution:\n', ...
    '• A Top 1%% household (750k+10M) retains NZD 9.42M (94.2%% of net worth)\n', ...
    '  and NZD 562k/yr in after-tax income (98.4%% if invested in active firms z_h).\n', ...
    '• An Ultra-High-Net-Worth dynasty (10M+250M) contributes ~NZD 26.5M over\n', ...
    '  the transition to end child stunting, yet still celebrates NZD 223.5M\n', ...
    '  in net worth + NZD 7.05M/yr after-tax cash flow — while living in a\n', ...
    '  high-cohesion NZ (S_t: 100 -> 126) where their own grandchildren stay!']);
text(ax2, 3.6, 153.5, msg_B, 'FontSize', 7.7, 'FontWeight', 'bold', 'Color', [0.00 0.27 0.11], ...
    'BackgroundColor', [0.94 0.98 0.95], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 4);

title(ax2, 'B. What Remains to Celebrate: Retained Net Worth (%) & Absolute Fortune (NZD Millions)', ...
    'FontSize', 10.8, 'FontWeight', 'bold');
xlabel(ax2, 'Household Archetype: Annual Earnings + Net Worth (Rashbrooke / Stats NZ / IRD Tiers)', ...
    'FontSize', 10, 'FontWeight', 'bold');
set(ax2, 'XTick', x_idx, 'XTickLabel', strrep(Tier_Labels, '\n', ' '), 'XTickLabelRotation', 32, 'FontSize', 8.2);
xlim(ax2, [0.4, N_tiers + 0.6]);
grid(ax2, 'on'); box(ax2, 'on');
legend(ax2, 'Location', 'southwest', 'FontSize', 6.9);

% Export 2-Panel combined figure + 2 individual sibling panels
f_2p   = fullfile(OutputDir, sprintf('Fig_WealthBrackets_2Panel_PainAndCelebration_%s.png', AnchorTag));
f_panA = fullfile(OutputDir, sprintf('Fig_WealthBrackets_PanelA_PainVsGain_%s.png',         AnchorTag));
f_panB = fullfile(OutputDir, sprintf('Fig_WealthBrackets_PanelB_LeftToCelebrate_%s.png',    AnchorTag));

exportgraphics(fig_wb, f_2p,   'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(ax1,    f_panA, 'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(ax2,    f_panB, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved 12-Tier Wealth Bracket Pain & Celebration sibling plots:\n     1) %s\n     2) %s\n     3) %s\n', f_2p, f_panA, f_panB);

Out.T17_Table = T17;
Out.f_2panel  = f_2p;
Out.f_panelA  = f_panA;
Out.f_panelB  = f_panB;
end
