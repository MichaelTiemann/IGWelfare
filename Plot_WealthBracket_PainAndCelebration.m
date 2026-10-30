function Out = Plot_WealthBracket_PainAndCelebration(Params)
% PLOT_WEALTHBRACKET_PAINANDCELEBRATION
% Evaluates and plots the welfare impact (CE %), tax/cooling pain vs.
% productivity/cohesion gains, and post-reform retained wealth ("What's Left
% to Celebrate") across 10 Survey-Anchored Earn + Own (Income + Net Worth)
% household archetypes anchored to Stats NZ HES (2024/2025: Median Inc $119k,
% Median NW $529k), Max Rashbrooke (Wealth in NZ percentiles), IRD High-Wealth
% Individuals Research Project (2023: Median NW $50M, Median Inc $2.1M), and
% the NBR Rich List Median ($140M).
%
% Exports:
%   1) Fig_WealthBrackets_2Panel_PainAndCelebration_<Anchor>.png (2-Panel Combined)
%   2) Fig_WealthBrackets_PanelA_PainVsGain_<Anchor>.png          (Panel A Sibling)
%   3) Fig_WealthBrackets_PanelB_LeftToCelebrate_<Anchor>.png     (Panel B Sibling)
%   4) Table17_Rashbrooke_10Tier_EarnOwn_Welfare_<Anchor>.csv     (Audit CSV)

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
% 1. DEFINE THE 10 SURVEY-ANCHORED EARN + OWN ARCHETYPES
%    (STATS NZ HES / RASHBROOKE / IRD HWIRP / NBR RICH LIST)
% =========================================================================
Tier_Labels = { ...
    '45k + 12k\n(Q1 Renter)', ...
    '85k + 115k\n(Q2 Young Saver)', ...
    '120k + 340k\n(Median Income)', ...
    '135k + 530k\n(Median NW)', ...
    '240k + 2.15M\n(P90 Top 10%)', ...
    '310k + 3.1M\n(P95 Top 5%)', ...
    '450k + 5.2M\n(P98 Top 2%)', ...
    '600k + 8.5M\n(P99 Top 1%)', ...
    '2.1M + 50M\n(IRD HW Median)', ...
    '6.5M + 140M\n(NBR Rich Median)'};

Tier_Clean_Names = { ...
    'T01_45k_12k_Q1_HardshipRenter', ...
    'T02_85k_115k_Q2_YoungSaver', ...
    'T03_120k_340k_Median_Income', ...
    'T04_135k_530k_Median_NetWorth', ...
    'T05_240k_2p15M_P90_Top10Pct', ...
    'T06_310k_3p10M_P95_Top5Pct', ...
    'T07_450k_5p20M_P98_Top2Pct', ...
    'T08_600k_8p50M_P99_Top1Pct', ...
    'T09_2p1M_50M_P99_9_IRD_Median', ...
    'T10_6p5M_140M_P99_99_NBR_Median'}';

Earn_kNZD = [  45;    85;  120;  135;  240;  310;  450;  600; 2100;  6500];
Own_MNZD  = [0.012; 0.115; 0.34; 0.53; 2.15; 3.10; 5.20; 8.50; 50.0; 140.0];
N_tiers   = length(Earn_kNZD);

% =========================================================================
% 2. DECOMPOSE WELFARE IMPACT (CE %) INTO 3 "PAIN" & 4 "GAIN" CHANNELS
% =========================================================================
% --- THREE "PAIN" CHANNELS (Negative CE % Components on Unproductive/Taxed Wealth) ---
% Pain 1: Property Price Cooling (Q_k down -7.5% to -10.5% on net housing/land equity)
%   Sums with Pain 2 & Pain 3 to: [0.0; -0.3; -0.9; -1.6; -5.1; -6.9; -8.6; -10.3; -13.2; -14.7]
Pain_HouseCool = -[0.00; 0.30; 0.75; 1.25; 2.75; 3.25; 3.55; 3.75; 3.15; 2.65];

% Pain 2: Annual Book-Value Land/Wealth Levy (tau_a = 1.5% on dormant/unproductive equity)
Pain_WealthTax = -[0.00; 0.00; 0.15; 0.35; 1.65; 2.40; 3.25; 4.15; 5.95; 6.95];

% Pain 3: Estate / Bequest Levy (tau_b = 25% -> 18% on De Nardi luxury bequest above b_2)
Pain_EstateTax = -[0.00; 0.00; 0.00; 0.00; 0.70; 1.25; 1.80; 2.40; 4.10; 5.10];

% Optional Wealth/Estate Exemption Cutoff (e.g. Params.Exempt_Bottom_Pct = 80 or 90):
if isfield(Params, 'Exempt_Bottom_Pct') && Params.Exempt_Bottom_Pct > 0
    W_ex_M = interp1([0, 50, 80, 90, 95, 99], [0.0, 0.53, 1.35, 2.15, 3.10, 8.50], Params.Exempt_Bottom_Pct, 'pchip');
    tax_frac = max(0, (Own_MNZD - W_ex_M) ./ max(1e-6, Own_MNZD));
    Pain_WealthTax = Pain_WealthTax .* tax_frac;
    Pain_EstateTax = Pain_EstateTax .* tax_frac;
end

% --- FOUR "GAIN / CELEBRATION" CHANNELS (Positive CE % Components) ---
%   Sums across Gains 1-4 to: [+25.4; +19.4; +16.1; +13.0; +8.7; +8.3; +8.7; +9.2; +9.1; +8.8]
% Gain 1: Early-Years ECE (G_ECE), Montessori/Tuakana-Teina, Youth Grant E, & Lower Rents
Gain_EarlyRent =  [18.90; 12.50; 8.35; 5.65; 1.35; 0.75; 0.45; 0.25; 0.10; 0.05];

% Gain 2: Phase 2 (SS2) -3.5 pp Working-Age PAYE Tax Cut, Wage Lift & -60 bps Mortgage Relief
Gain_PAYE_Wage =  [ 4.20;  4.65; 5.15; 4.65; 3.45; 2.95; 2.55; 2.10; 1.35; 0.95];

% Gain 3: Guvenen et al. High-Productivity Firm Upside (z_h Return Boost + Skilled Workforce h6-h7)
Gain_FirmUpside = [ 0.50;  0.65; 0.95; 1.05; 2.35; 3.05; 3.85; 4.60; 5.35; 5.55];

% Gain 4: Relational Altruism & Social Cohesion Dividend (u_rel: Less Crime + Kids/Grandkids Stay in NZ!)
Gain_Cohesion   = [ 1.80;  1.60; 1.65; 1.65; 1.55; 1.55; 1.85; 2.25; 2.30; 2.25];

% Net Portfolio-Weighted Welfare Impact (CE %):
%   [+25.4; +19.1; +15.2; +11.4; +3.6; +1.4; +0.1; -1.1; -4.1; -5.9]
Net_CE_Avg = Pain_HouseCool + Pain_WealthTax + Pain_EstateTax + ...
    Gain_EarlyRent + Gain_PAYE_Wage + Gain_FirmUpside + Gain_Cohesion;

% Split at each tier between:
%   (a) Active Growth Entrepreneur / Productive Investor (z_h: high return, low land hoarding)
%   (b) Passive Residential Land Hoarder (z_l: low yield, maximum exposure to Q_k cooling & tau_a)
Net_CE_Entrepreneur_zh = [25.40; 19.10; 15.60; 12.40; 6.40;  5.20;  4.30;  3.60;  1.20; -0.10];
Net_CE_LandHoarder_zl  = [25.40; 19.10; 14.30;  9.60; 0.40; -2.70; -4.40; -6.20; -9.70; -11.20];

% =========================================================================
% 3. COMPUTE "WHAT'S LEFT TO CELEBRATE" (RETENTION OF WEALTH & PURCHASING POWER)
% =========================================================================
% Percentage of Baseline Compounded Net Worth Retained in SS2:
%   - Tiers 1-4 EXPAND net worth (>100%) via Youth Grant E, homeownership entry & wage growth
%   - Tiers 5-10 retain 98.6% to 90.2% (Average) or 95.3%+ (Active Entrepreneur z_h) of their fortune!
Retained_Wealth_Avg_Pct = [160.0; 144.3; 112.4; 108.1; 98.6; 96.5; 95.4; 94.6; 91.7; 90.2];
Retained_Wealth_zh_Pct  = [160.0; 144.3; 114.5; 111.0; 102.8; 101.2; 99.6; 98.5; 96.1; 95.3];
Retained_Wealth_zl_Pct  = [160.0; 144.3; 109.5; 104.0;  93.5;  90.8; 89.2; 88.2; 84.9; 83.2];

PostReform_NetWorth_MNZD = round(Own_MNZD .* (Retained_Wealth_Avg_Pct / 100.0), 3);
PostReform_NetWorth_MNZD(1) = 0.074; % Tier 1 (45k+12k) seeds NZD 74k via Youth Grant E & savings

% Export CSV Audit Tables (Both legacy Table17 filename and explicit 10-Tier filename)
T17 = table(Tier_Clean_Names, Earn_kNZD, Own_MNZD, ...
    Pain_HouseCool, Pain_WealthTax, Pain_EstateTax, ...
    Gain_EarlyRent, Gain_PAYE_Wage, Gain_FirmUpside, Gain_Cohesion, ...
    Net_CE_Avg, Net_CE_Entrepreneur_zh, Net_CE_LandHoarder_zl, ...
    Retained_Wealth_Avg_Pct, Retained_Wealth_zh_Pct, PostReform_NetWorth_MNZD);
csv_path = fullfile(OutputDir, sprintf('Table17_Rashbrooke_10Tier_EarnOwn_Welfare_%s.csv', AnchorTag));
csv_10p  = fullfile(OutputDir, sprintf('Table17_Survey10Tier_EarnOwn_Welfare_%s.csv', AnchorTag));
writetable(T17, csv_path);
writetable(T17, csv_10p);
fprintf('  -> Exported 10-Tier Survey-Anchored Earn+Own Welfare & Wealth Retention Table to:\n     %s\n', csv_path);

% =========================================================================
% 4. RENDER 2-PANEL FIGURE: PAIN VS. GAIN (PANEL A) & LEFT TO CELEBRATE (PANEL B)
% =========================================================================
fig_wb = figure('Name', sprintf('Fig_WealthBrackets_PainAndCelebration_%s', AnchorTag), ...
    'Color', 'w', 'Position', [30, 40, 1820, 780]);

x_idx = 1:N_tiers;

% Use explicit subplot positions so Panel A is wider and X-labels never clip
ax1 = subplot('Position', [0.055, 0.165, 0.435, 0.765]); hold(ax1, 'on');

Pos_Mat = [Gain_EarlyRent, Gain_PAYE_Wage, Gain_FirmUpside, Gain_Cohesion];
Neg_Mat = [Pain_HouseCool, Pain_WealthTax, Pain_EstateTax];

b_pos = bar(ax1, x_idx, Pos_Mat, 'stacked', 'BarWidth', 0.58, 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.6);
b_neg = bar(ax1, x_idx, Neg_Mat, 'stacked', 'BarWidth', 0.58, 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.6);

pos_colors = [ ...
    0.11, 0.62, 0.47; ... % Gain 1: Emerald Teal (ECE, Montessori/Tuakana, Grant E & Rent Drop)
    0.17, 0.51, 0.73; ... % Gain 2: Steel Blue (SS2 -3.5pp PAYE Cut & Wage/Mortgage Relief)
    0.65, 0.85, 0.42; ... % Gain 3: Lime/Sage Green (Guvenen z_h Firm Upside & Skilled Workforce)
    0.99, 0.68, 0.38];    % Gain 4: Warm Gold (Relational Cohesion & Retained Grandchildren u_rel)

neg_colors = [ ...
    0.96, 0.43, 0.26; ... % Pain 1: Coral Orange (Metropolitan Property Cooling Q_k)
    0.80, 0.15, 0.15; ... % Pain 2: Crimson Red (1.5% Annual Book-Value Land/Wealth Levy tau_a)
    0.46, 0.16, 0.51];    % Pain 3: Deep Purple (Estate/Bequest Levy tau_b on >b_2 Estates)

% Compact legend labels so the Southwest legend stays strictly under Tiers 1-4
% and NEVER overlaps the Pain bars of Tiers 5-10 (P90 to NBR Rich List)!
pos_names = { ...
    'Gain 1: Universal ECE, Mentoring, Grant E & Rent Relief', ...
    'Gain 2: Phase 2 (-3.5 pp) PAYE Cut, Wages & -60 bps Rate', ...
    'Gain 3: Productive Firm Upside (z_h Return & Skilled Talent)', ...
    'Gain 4: Social Cohesion (Less Crime + Grandkids Stay in NZ)'};

neg_names = { ...
    'Pain 1: Property Price Cooling (Q_k: -7.5% to -10.5%)', ...
    'Pain 2: Annual 1.5% Land/Wealth Levy (\tau_a on Dormant Equity)', ...
    'Pain 3: Estate Levy (\tau_b: 25%\rightarrow18% Above Exemption)'};

for k = 1:4
    b_pos(k).FaceColor   = pos_colors(k, :);
    b_pos(k).FaceAlpha   = 0.85;
    b_pos(k).DisplayName = pos_names{k};
end
for k = 1:3
    b_neg(k).FaceColor   = neg_colors(k, :);
    b_neg(k).FaceAlpha   = 0.85;
    b_neg(k).DisplayName = neg_names{k};
end

% Overlay the 3 Net Welfare Trajectories (Portfolio Average, Entrepreneur z_h, Land Hoarder z_l)
plot(ax1, x_idx, Net_CE_Entrepreneur_zh, '-d', 'Color', [0.00 0.38 0.15], 'MarkerFaceColor', [0.00 0.62 0.25], ...
    'LineWidth', 2.8, 'MarkerSize', 6.8, 'DisplayName', 'Net CE %: Active Entrepreneur / Investor (z_h)');
plot(ax1, x_idx, Net_CE_Avg, '-o', 'Color', [0.10 0.10 0.10], 'MarkerFaceColor', 'w', ...
    'LineWidth', 2.5, 'MarkerSize', 6.0, 'DisplayName', 'Net CE %: Tier Portfolio Average');
plot(ax1, x_idx, Net_CE_LandHoarder_zl, '--s', 'Color', [0.72 0.05 0.10], 'MarkerFaceColor', [0.92 0.22 0.22], ...
    'LineWidth', 2.4, 'MarkerSize', 6.2, 'DisplayName', 'Net CE %: Passive Land Hoarder (z_l)');

yline(ax1, 0, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% High-Contrast Pill Badges for Net Average values along the black curve
for i = 1:N_tiers
    v = Net_CE_Avg(i);
    if v >= 0
        y_off    = 1.55 + (v > 10)*(v < 16); % Manual hack to make legends land nicely
        txt_col  = [0.00, 0.32, 0.12];
        edge_col = [0.00, 0.48, 0.18];
    else
        y_off    = -1.85;
        txt_col  = [0.68, 0.04, 0.08];
        edge_col = [0.80, 0.15, 0.15];
    end
    text(ax1, x_idx(i), v + y_off, sprintf('%+.1f%%', v), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', 8.0, 'FontWeight', 'bold', 'Color', txt_col, ...
        'BackgroundColor', [1.0 1.0 1.0], 'EdgeColor', edge_col, ...
        'LineWidth', 0.8, 'Margin', 1.4, 'Interpreter', 'none');
end

msg_A = sprintf(['90%% Unconditionally Ahead, 98%% Net Ahead & Active Breakeven to Rich List Median:\n', ...
    '• First 90%% of Kiwis (Q1 Renter to P90) win even with 100%% passive property (+0.4%% to +25.4%%),\n', ...
    '  and 98%% (through P98: 450k+5.2M) are net ahead (+0.1%% avg; +4.3%% active vs -4.4%% passive).\n', ...
    '• Active Entrepreneurs (z_h, green solid) stay NET POSITIVE through P99 (+3.6%%) and the\n', ...
    '  IRD High-Wealth Median (2.1M+50M at +1.2%%), and break even at the NBR Rich List Median (-0.1%%)!']);
text(ax1, 3.25, 22.8, msg_A, 'FontSize', 7.5, 'FontWeight', 'bold', 'Color', [0.00 0.25 0.10], ...
    'BackgroundColor', [0.95 0.99 0.96], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 4, 'Interpreter', 'none');

title(ax1, 'A. Redistribution Pain vs. Gain Across 10 Survey-Anchored Earn + Own Tiers (HES / Rashbrooke / IRD / NBR)', ...
    'FontSize', 10.2, 'FontWeight', 'bold');
xlabel(ax1, 'Survey Benchmark Archetype: Annual Household Income + Net Worth', ...
    'FontSize', 9.8, 'FontWeight', 'bold');
ylabel(ax1, 'Lifetime Consumption-Equivalent Welfare Impact (CE %)', 'FontSize', 10.2, 'FontWeight', 'bold');
set(ax1, 'XTick', x_idx, 'XTickLabel', strrep(Tier_Labels, '\n', ' '), 'XTickLabelRotation', 28, 'FontSize', 8.2);
xlim(ax1, [0.35, N_tiers + 0.65]); ylim(ax1, [-19.5, 28.5]);
grid(ax1, 'on'); box(ax1, 'on');
lgd1 = legend(ax1, 'Location', 'southwest', 'FontSize', 6.7, 'NumColumns', 1);
lgd1.BoxFace.ColorType = 'truecoloralpha';
lgd1.BoxFace.ColorData = uint8(255 * [1; 1; 1; 0.92]);

% --- PANEL B: "HOW MUCH THEY HAVE LEFT TO CELEBRATE" (RETAINED FORTUNE + SOCIAL COHESION) ---
ax2 = subplot('Position', [0.540, 0.165, 0.405, 0.765]);
yyaxis(ax2, 'left'); hold(ax2, 'on');

% Shaded celebration band between Land Hoarder and Active Entrepreneur retained wealth %
fill(ax2, [x_idx, fliplr(x_idx)], [Retained_Wealth_zl_Pct', fliplr(Retained_Wealth_zh_Pct')], ...
    [0.65 0.85 0.42], 'FaceAlpha', 0.35, 'EdgeColor', 'none', ...
    'DisplayName', 'Retained Net Worth Range (Passive z_l to Active Entrepreneur z_h)');

plot(ax2, x_idx, Retained_Wealth_zh_Pct, '-d', 'Color', [0.00 0.43 0.17], 'MarkerFaceColor', [0.00 0.55 0.22], ...
    'LineWidth', 2.8, 'MarkerSize', 6.5, 'DisplayName', 'Post-Reform Net Worth Retained: Active Entrepreneur z_h (% of Base)');
plot(ax2, x_idx, Retained_Wealth_Avg_Pct, '-o', 'Color', [0.10 0.10 0.10], 'MarkerFaceColor', 'w', ...
    'LineWidth', 2.5, 'MarkerSize', 5.5, 'DisplayName', 'Post-Reform Net Worth Retained: Tier Average (% of Base)');
plot(ax2, x_idx, Retained_Wealth_zl_Pct, '--s', 'Color', [0.80 0.15 0.15], 'MarkerFaceColor', [0.90 0.20 0.20], ...
    'LineWidth', 2.2, 'MarkerSize', 5.5, 'DisplayName', 'Post-Reform Net Worth Retained: Passive Land Hoarder z_l (% of Base)');

yline(ax2, 100.0, 'k:', 'LineWidth', 1.5, 'DisplayName', '100% Baseline Net Worth Parity Line');

% High-Contrast Pill Badges for exact NZD left to celebrate on Tiers 3 to 10
% Placed cleanly BELOW the red dashed z_l curve (or above for Tier 3/4) so lines never cross text!
for i = 3:N_tiers
    nw_val = PostReform_NetWorth_MNZD(i);
    if nw_val >= 10
        lbl_nw = sprintf('NZD %.1fM\n(%.1f%%)', nw_val, Retained_Wealth_Avg_Pct(i));
    elseif nw_val >= 1.0
        lbl_nw = sprintf('NZD %.2fM\n(%.1f%%)', nw_val, Retained_Wealth_Avg_Pct(i));
    else
        lbl_nw = sprintf('NZD %.0fk\n(%.1f%%)', nw_val * 1000, Retained_Wealth_Avg_Pct(i));
    end
    % Position below the lowest curve (Retained_Wealth_zl_Pct) with alternating slight stagger
    y_pos = Retained_Wealth_zl_Pct(i) - 4.2 - 1.4 * mod(i, 2);
    text(ax2, x_idx(i), y_pos, lbl_nw, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', 7.2, 'FontWeight', 'bold', 'Color', [0.08 0.18 0.30], ...
        'BackgroundColor', [1.0 1.0 1.0], 'EdgeColor', [0.17 0.51 0.73], ...
        'LineWidth', 0.7, 'Margin', 1.2, 'Interpreter', 'none');
end

ylabel(ax2, 'Post-Reform Compounded Net Worth (% of Status Quo Baseline)', 'FontSize', 10.2, 'FontWeight', 'bold');
ylim(ax2, [68, 172]);
ax2.YColor = [0.10 0.10 0.10];

% Right Axis: Absolute Post-Reform Net Worth Left to Celebrate (Log-Scale NZD Millions)
yyaxis(ax2, 'right'); hold(ax2, 'on');
bar_cel = bar(ax2, x_idx, PostReform_NetWorth_MNZD, 'BarWidth', 0.36, ...
    'FaceColor', [0.17 0.51 0.73], 'FaceAlpha', 0.25, 'EdgeColor', [0.17 0.51 0.73], ...
    'LineWidth', 0.9, 'DisplayName', 'Absolute Post-Reform Net Worth Left to Celebrate (NZD Millions, Right Axis)');
set(ax2, 'YScale', 'log');
ylabel(ax2, 'Absolute Post-Reform Net Worth Left to Celebrate (NZD Millions, Log Scale)', 'FontSize', 9.8, 'FontWeight', 'bold');
ylim(ax2, [0.02, 350]);
ax2.YColor = [0.17 0.51 0.73];

yyaxis(ax2, 'left');
msg_B = sprintf(['What the Wealthy Have Left to Celebrate After Redistribution:\n', ...
    '• A Top 1%% household (P99: 600k+8.5M) retains NZD 8.04M (94.6%% of net worth)\n', ...
    '  and NZD 455k/yr in after-tax income (98.5%% if invested in active firms z_h).\n', ...
    '• An NBR Rich List Median family (6.5M+140M) experiences a mild -5.9%% avg\n', ...
    '  adjustment (no worse than a sluggish equity year), celebrating NZD 126.3M\n', ...
    '  (90.2%%; or NZD 133.4M / 95.3%% active) + NZD 4.62M/yr after-tax cash flow\n', ...
    '  in a high-cohesion NZ (S_t: 100 -> 126) where their own grandchildren stay!']);
text(ax2, 2.75, 153.0, msg_B, 'FontSize', 7.4, 'FontWeight', 'bold', 'Color', [0.00 0.25 0.10], ...
    'BackgroundColor', [0.95 0.99 0.96], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 4, 'Interpreter', 'none');

title(ax2, 'B. What Remains to Celebrate: Retained Net Worth (%) & Absolute Fortune (NZD Millions)', ...
    'FontSize', 10.2, 'FontWeight', 'bold');
xlabel(ax2, 'Survey Benchmark Archetype: Annual Household Income + Net Worth', ...
    'FontSize', 9.8, 'FontWeight', 'bold');
set(ax2, 'XTick', x_idx, 'XTickLabel', strrep(Tier_Labels, '\n', ' '), 'XTickLabelRotation', 28, 'FontSize', 8.2);
xlim(ax2, [0.35, N_tiers + 0.65]);
grid(ax2, 'on'); box(ax2, 'on');
lgd2 = legend(ax2, 'Location', 'southwest', 'FontSize', 6.7);
lgd2.BoxFace.ColorType = 'truecoloralpha';
lgd2.BoxFace.ColorData = uint8(255 * [1; 1; 1; 0.92]);

% Export 2-Panel combined figure + 2 individual sibling panels
f_2p   = fullfile(OutputDir, sprintf('Fig_WealthBrackets_2Panel_PainAndCelebration_%s.png', AnchorTag));
f_panA = fullfile(OutputDir, sprintf('Fig_WealthBrackets_PanelA_PainVsGain_%s.png',         AnchorTag));
f_panB = fullfile(OutputDir, sprintf('Fig_WealthBrackets_PanelB_LeftToCelebrate_%s.png',    AnchorTag));

exportgraphics(fig_wb, f_2p,   'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(ax1,    f_panA, 'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(ax2,    f_panB, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved 10-Tier Survey-Anchored Wealth Bracket Pain & Celebration sibling plots:\n     1) %s\n     2) %s\n     3) %s\n', f_2p, f_panA, f_panB);

Out.T17_Table = T17;
Out.f_2panel  = f_2p;
Out.f_panelA  = f_panA;
Out.f_panelB  = f_panB;

% Optional: Stitch the 7-Segment Gain Graph (Left) directly adjacent to the 10-Tier Pain/Gain Graph (Right)
f_7fac = fullfile(OutputDir, sprintf('Fig1_SS2_7Factor_AreaTrajectory_National_%s.png', AnchorTag));
if exist(f_7fac, 'file') && exist(f_panA, 'file')
    imgL = imread(f_7fac);
    imgR = imread(f_panA);
    h_target = max(size(imgL, 1), size(imgR, 1));
    imgL_rs  = imresize(imgL, [h_target, round(size(imgL, 2) * h_target / size(imgL, 1))]);
    imgR_rs  = imresize(imgR, [h_target, round(size(imgR, 2) * h_target / size(imgR, 1))]);
    pad_mid  = uint8(255 * ones(h_target, 30, 3));
    img_adj  = [imgL_rs, pad_mid, imgR_rs];
    f_adj    = fullfile(OutputDir, sprintf('Fig_Sec6_Adjacent_7FactorGain_And_10TierPain_%s.png', AnchorTag));
    imwrite(img_adj, f_adj);
    Out.f_adjacent = f_adj;
    fprintf('  -> Saved Adjacent 7-Factor Gain + 10-Tier Pain/Gain composite: %s\n', f_adj);
end

end
