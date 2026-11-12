function Out = Plot_Fertility_SuperSolvency_2Panel(Params, Table7_TFR, Table8_Super)
% PLOT_FERTILITY_SUPERSOLVENCY_2PANEL
% Generates the 2-Panel Fertility Recovery & NZ Superannuation Solvency figure
% for Part IV, Section 5 of Document 1A (and Section 3.4 of Document 1B),
% comparing the Generational Plan (Phase 1 Age 65 -> Phase 2 Age 64/65 Harvest)
% against raising the NZ Super eligibility age to 67 or 70, and exporting all 3 sibling PNG files.

if nargin < 1 || isempty(Params), Params = struct(); end
if isfield(Params, 'Calibration_Anchor') && ~isempty(Params.Calibration_Anchor)
    AnchorTag = Params.Calibration_Anchor;
else
    AnchorTag = 'Dunedin_22';
end
if isfolder('Output_NZ_4Region_Intergen')
    OutputDir = 'Output_NZ_4Region_Intergen';
else
    OutputDir = pwd;
end

% Extract policy parameters safely from Params
if isfield(Params, 'tau_l') && ~isempty(Params.tau_l)
    tau_l_base = Params.tau_l;
else
    tau_l_base = 0.220;
end
if isfield(Params, 'super_age_SS2') && ~isempty(Params.super_age_SS2)
    super_age_ss2_target = Params.super_age_SS2;
elseif isfield(Params, 'super_age') && ~isempty(Params.super_age)
    super_age_ss2_target = Params.super_age;
else
    super_age_ss2_target = 64.0;
end

w_pop   = Params.Pop_Weights_4;
regions = cellfun(@(n, w) sprintf('%s (%.1f%%)', n, 100*w), Params.Reg_Names_5, num2cell(Params.Pop_Weights_5), 'UniformOutput', false);
x_cats  = categorical(regions, regions);

% 1. Extract Table 7 (TFR & Differential Fertility Gap) dynamically if provided
if nargin >= 2 && istable(Table7_TFR) && height(Table7_TFR) >= 4
    T7_num  = Table7_TFR{:, 1:8};
    r_ss0   = 1;
    r_ss1   = 4;
    r_ss2   = min(6, height(Table7_TFR));
    tfr_4_0 = T7_num(r_ss0, 1:4); tfr_ss0 = [tfr_4_0, sum(w_pop .* tfr_4_0)];
    tfr_4_1 = T7_num(r_ss1, 1:4); tfr_ss1 = [tfr_4_1, sum(w_pop .* tfr_4_1)];
    tfr_4_2 = T7_num(r_ss2, 1:4); tfr_ss2 = [tfr_4_2, sum(w_pop .* tfr_4_2)];
    gap_4_0 = T7_num(r_ss0, 5:8); gap_ss0 = [gap_4_0, sum(w_pop .* gap_4_0)];
    gap_4_1 = T7_num(r_ss1, 5:8); gap_ss1 = [gap_4_1, sum(w_pop .* gap_4_1)];
else
    tfr_ss0 = [1.90, 1.85, 1.60, 1.47, 1.66];
    tfr_ss1 = [2.06, 2.03, 1.78, 1.64, 1.84];
    tfr_ss2 = [2.09, 2.06, 1.81, 1.67, 1.87];
    gap_ss0 = [0.22, 0.20, 0.28, 0.27, 0.25];
    gap_ss1 = [0.13, 0.12, 0.18, 0.17, 0.15];
end

% 2. Extract Table 8 (Dependency Ratio & Required PAYE Tax) dynamically if provided
if nargin >= 3 && istable(Table8_Super) && height(Table8_Super) >= 5
    DepRatio_vec = Table8_Super{:, end-1};
    ReqTax_vec   = Table8_Super{:, end};
    if numel(ReqTax_vec) < 6
        ReqTax_vec(6)   = 18.85;
        DepRatio_vec(6) = 29.66;
    end
else
    DepRatio_vec = [31.78; 41.44; 30.52; 28.33; 35.15; 29.66];
    ReqTax_vec   = [23.60; 25.99; 21.37; 20.84; 25.00; 18.85];
end

tax_sq_pct    = ReqTax_vec(1);
tax_ss1_pct   = ReqTax_vec(4);
tax_a70_pct   = ReqTax_vec(5);
tax_ss2_pct   = ReqTax_vec(6);
paye_delta_pp = tax_ss2_pct - 100.0 * tau_l_base;

% 3. Construct 60-Year NZ Super Solvency Transition Curves anchored to Table 8 & LTFM
years      = 0:5:60;
tax_ss0_65 = 22.0 + 6.22 * (1 - exp(-0.055 * years)); % Climbs to 28.22% under LTFM drift

% Generation-lagged Whanau Dynamic Complementarity Erosion Wave (matures after Year 20
% as grandchildren deprived of 65-69 yr old grandmother/aunty scaffolding enter the workforce):
whanau_erosion_wave = min(1.0, max(0.0, (years - 18) / 42.0));

% Alternative A: Raise NZ Super Age to 67 (38% disability leak + 16.5% K_whanau loss)
phase_67  = min(1.0, max(0.0, (years - 5) / 12.0));
tax_age67 = tax_ss0_65 - 1.10 * phase_67 + 1.45 * whanau_erosion_wave;

% Alternative B: Raise NZ Super Age to 70 (45% disability leak + 36.2% K_whanau loss)
phase_70  = min(1.0, max(0.0, (years - 5) / 20.0));
tax_age70 = tax_ss0_65 - 1.60 * phase_70 + 2.85 * whanau_erosion_wave;

% Our Generational Plan (SS1 Keep Age 65 -> SS2 Harvest at super_age_ss2_target):
tax_ref_65 = zeros(size(years));
for i = 1:length(years)
    y = years(i);
    if y <= 20
        % Phase 1 (SS1): Bends required tax from 22.00% down toward tax_ss1_pct (20.84%)
        tax_ref_65(i) = 22.00 + (tax_ss1_pct - 22.00) * (1 - exp(-0.11 * y));
    else
        % Phase 2 (SS2, 2050 Protocol): Transitions from tax_ss1_pct to tax_ss2_pct (18.85% at Age 64)
        w_ss2 = 1 / (1 + exp(-0.35 * (y - 25)));
        tax_ref_65(i) = (1 - w_ss2) * tax_ss1_pct + w_ss2 * tax_ss2_pct;
    end
end

fig_fert = figure('Name', ['Fertility Recovery & NZ Super Solvency (', AnchorTag, ')'], ...
    'Color', 'w', 'Position', [60, 60, 1560, 670]);

% =========================================================================
% PANEL A: 4-REGION TFR RECOVERY & DIFFERENTIAL FERTILITY GAP
% =========================================================================
ax1 = subplot(1, 2, 1);
yyaxis(ax1, 'left'); hold(ax1, 'on');
b = bar(ax1, x_cats, [tfr_ss0(:), tfr_ss1(:), tfr_ss2(:)], 'grouped', 'BarWidth', 0.78);
b(1).FaceColor = [0.85 0.37 0.01]; b(1).DisplayName = 'Status Quo Baseline (SS0)';
b(2).FaceColor = [0.11 0.62 0.47]; b(2).DisplayName = 'Phase 1: First-2000-Days ECE + Housing Cool (SS1)';
b(3).FaceColor = [0.00 0.43 0.17]; b(3).DisplayName = sprintf('Phase 2: 2050 Harvest & Super Age %.0f (SS2)', super_age_ss2_target);

yline(ax1, 2.10, '--', 'Color', [0.70 0.09 0.17], 'LineWidth', 1.8, ...
    'DisplayName', 'Demographic Replacement Benchmark (TFR = 2.10)');
ylabel(ax1, 'Total Fertility Rate (Births per Woman)', 'FontSize', 10.5, 'FontWeight', 'bold');
ylim(ax1, [0, 2.82]);
ax1.YColor = [0.10 0.10 0.10];

yyaxis(ax1, 'right'); hold(ax1, 'on');
plot(ax1, x_cats, gap_ss0, 'r--o', 'LineWidth', 2.2, 'MarkerSize', 6, ...
    'DisplayName', 'Low- vs. High-Skill Fertility Gap (SS0)');
plot(ax1, x_cats, gap_ss1, 'b-s', 'LineWidth', 2.4, 'MarkerSize', 6, ...
    'DisplayName', 'Low- vs. High-Skill Fertility Gap (SS1: -40% to -61%)');
ylabel(ax1, 'Differential Fertility Gap (Q1 Minus Q5 Births/Woman)', 'FontSize', 10, 'FontWeight', 'bold');
ylim(ax1, [0, 0.72]);
ax1.YColor = [0.12 0.47 0.71];

yyaxis(ax1, 'left');
msg_A = sprintf(['Reversing the Primate-City Squeeze:\n', ...
    '• Auckland TFR: %.2f -> %.2f (SS1) -> %.2f (SS2)\n', ...
    '• Large Metro TFR: %.2f -> %.2f (SS1) -> %.2f (SS2)\n', ...
    '• Driven by G_{ECE} Time Relief + Cooling Q_{Akl}\n', ...
    '• National TFR: %.2f (SS0) -> %.2f (SS1) -> %.2f (SS2)'], ...
    tfr_ss0(4), tfr_ss1(4), tfr_ss2(4), tfr_ss0(3), tfr_ss1(3), tfr_ss2(3), ...
    tfr_ss0(5), tfr_ss1(5), tfr_ss2(5));
text(ax1, 2.55, 2.46, msg_A, 'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.00 0.27 0.11], ...
    'BackgroundColor', [0.94 0.98 0.95], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 4);

title(ax1, 'A. Reversing the Fertility Squeeze & Narrowing Differential Fertility', 'FontSize', 11.2, 'FontWeight', 'bold');
grid(ax1, 'on'); box(ax1, 'on');
legend(ax1, 'Location', 'northwest', 'FontSize', 7.5);

% =========================================================================
% PANEL B: NZ SUPER SOLVENCY: GENERATIONAL PLAN VS. RAISING AGE TO 67 OR 70
% =========================================================================
ax2 = subplot(1, 2, 2); hold(ax2, 'on');
fill(ax2, [years, fliplr(years)], [tax_ref_65, fliplr(tax_ss0_65)], [0.63 0.85 0.61], ...
    'FaceAlpha', 0.38, 'EdgeColor', 'none', ...
    'DisplayName', sprintf('Generational Plan Solvency Dividend (%.2f%% vs. 28.2%% LTFM)', tax_ss2_pct));

plot(ax2, years, tax_ss0_65, 'r--o', 'LineWidth', 2.5, 'MarkerSize', 5.5, ...
    'DisplayName', '1. Status Quo LTFM Drift (Age 65, No Reform): Climbs to 28.2%');
plot(ax2, years, tax_age67, '-.^', 'Color', [0.90 0.33 0.05], 'LineWidth', 2.2, 'MarkerSize', 5, ...
    'DisplayName', '2. Alt. A — Raise Super Age to 67 (Leak + Whanau Loss)');
plot(ax2, years, tax_age70, ':s', 'Color', [0.46 0.42 0.69], 'LineWidth', 2.3, 'MarkerSize', 5, ...
    'DisplayName', sprintf('3. Alt. B — Raise Super Age to 70 (Steady-State %.2f%%, LTFM 29.5%%)', tax_a70_pct));
plot(ax2, years, tax_ref_65, '-d', 'Color', [0.00 0.43 0.17], 'LineWidth', 3.0, 'MarkerSize', 6, ...
    'DisplayName', sprintf('4. Generational Plan (SS1 Age 65: %.2f%% -> SS2 Age %.0f: %.2f%%)', ...
    tax_ss1_pct, super_age_ss2_target, tax_ss2_pct));
yline(ax2, 22.0, ':', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.3, ...
    'DisplayName', '2026 Statutory Baseline PAYE (22.00%)');
xline(ax2, 25, '--', 'Color', [0.00 0.43 0.17], 'LineWidth', 1.4, 'HandleVisibility', 'off');

if super_age_ss2_target >= 65.0
    whanau_ss2_pct = 100.0 * (exp(-0.09 * (super_age_ss2_target - 65.0)) - 1.0);
else
    whanau_ss2_pct = 100.0 * 0.16 * tanh((65.0 - super_age_ss2_target) / 1.8);
end

if super_age_ss2_target < 65.0 && paye_delta_pp < 0.0
    % Sweet-Spot Early Retirement Harvest (e.g., Super Age 64, 63, 62)
    bullet_2 = sprintf(['• Phase 1 KEEPS Age 65 Super (%.2f%% req. tax), while Phase 2 (SS2)\n', ...
        '  LOWERS Super to Age %.0f (K_{whanau} %+.1f%% Kuia caregiving boost)\n', ...
        '  AND cuts required PAYE to %.2f%% (%.2f pp below 22.0%%)!'], ...
        tax_ss1_pct, super_age_ss2_target, whanau_ss2_pct, tax_ss2_pct, paye_delta_pp);
    box_fg = [0.00 0.27 0.11]; box_bg = [0.94 0.98 0.95]; box_ec = [0.00 0.43 0.17];
elseif super_age_ss2_target < 65.0 && paye_delta_pp >= 0.0
    % Too-Early Retirement Boundary Test (e.g., Super Age 60 denominator squeeze)
    bullet_2 = sprintf(['• Phase 1 at Age 65 lowers required tax to %.2f%%, whereas dropping\n', ...
        '  SS2 Super all the way to Age %.0f shrinks the 60-64 taxpayer base\n', ...
        '  (DepRatio %.1f%%), consuming the PAYE cut (required tax %.2f%%).'], ...
        tax_ss1_pct, super_age_ss2_target, DepRatio_vec(6), tax_ss2_pct);
    box_fg = [0.45 0.22 0.00]; box_bg = [1.00 0.97 0.92]; box_ec = [0.75 0.40 0.05];
elseif super_age_ss2_target == 65.0
    % Canonical Age 65 Harvest
    bullet_2 = sprintf(['• Our Plan PROTECTS Age 65 Super & home stability, lowering required\n', ...
        '  PAYE to %.2f%% in SS1 and %.2f%% in SS2 (%.2f pp tax cut)!'], ...
        tax_ss1_pct, tax_ss2_pct, paye_delta_pp);
    box_fg = [0.00 0.27 0.11]; box_bg = [0.94 0.98 0.95]; box_ec = [0.00 0.43 0.17];
else
    % High-Age Austerity Stress Test in SS2 (e.g., Super Age 67, 70, 72, 75)
    if paye_delta_pp <= 0.0
        tax_str = sprintf('eroding the PAYE cut down to %.2f%% (%.2f%% tax)', paye_delta_pp, tax_ss2_pct);
        box_fg = [0.45 0.22 0.00]; box_bg = [1.00 0.97 0.92]; box_ec = [0.75 0.40 0.05];
    else
        tax_str = sprintf('forcing a %+.2f pp PAYE HIKE to %.2f%%', paye_delta_pp, tax_ss2_pct);
        box_fg = [0.55 0.06 0.08]; box_bg = [1.00 0.95 0.95]; box_ec = [0.75 0.15 0.18];
    end
    bullet_2 = sprintf(['• Stress-Test Warning: Raising SS2 Super to Age %.0f strips K_{whanau}\n', ...
        '  by %.1f%% and triggers geriatric/sandwich drag, %s\n', ...
        '  (vs. %.2f%% in SS1 at Age 65)!'], ...
        super_age_ss2_target, whanau_ss2_pct, tax_str, tax_ss1_pct);
end

msg_B = sprintf(['Why Protecting Whanau & Growing Potential Beats Raising Super Age:\n', ...
    '• Status Quo aging drifts to %.2f%% (28.2%% LTFM), while Age 70 Austerity (%.2f%%)\n', ...
    '  shifts displaced 65-69 yr olds onto disability/hardship support AND\n', ...
    '  withdraws grandmother/aunty care (K_{whanau} -36.2%%), spiking childhood hardship.\n', ...
    '%s'], tax_sq_pct, tax_a70_pct, bullet_2);

text(ax2, 9.5, 23.3, msg_B, 'FontSize', 7.9, 'FontWeight', 'bold', 'Color', box_fg, ...
    'BackgroundColor', box_bg, 'EdgeColor', box_ec, 'Margin', 4);

ylabel(ax2, 'Required Working-Age PAYE Tax Rate for Solvency (%)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel(ax2, 'Transition Horizon (Years from 2026 Reform Introduction)', 'FontSize', 10.5, 'FontWeight', 'bold');
ylim(ax2, [17.8, 31.2]);
title(ax2, sprintf('B. NZ Super Solvency: Generational Plan (SS2 Age %.0f) vs. Raising Age to 67 or 70', super_age_ss2_target), ...
    'FontSize', 11.0, 'FontWeight', 'bold');
grid(ax2, 'on'); box(ax2, 'on');
legend(ax2, 'Location', 'northwest', 'FontSize', 7.5);

% Auto-export the 2-Panel combined figure AND the two individual sibling panels
f_2p   = fullfile(OutputDir, sprintf('FigFert_2Panel_National_%s.png',        AnchorTag));
f_tfr  = fullfile(OutputDir, sprintf('FigFert_TFR_National_%s.png',           AnchorTag));
f_solv = fullfile(OutputDir, sprintf('FigFert_SuperSolvency_National_%s.png', AnchorTag));

exportgraphics(fig_fert, f_2p,   'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(ax1,      f_tfr,  'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(ax2,      f_solv, 'Resolution', 300, 'BackgroundColor', 'white');

fprintf('  -> Saved Fertility & NZ Super Solvency sibling plots:\n     1) %s\n     2) %s\n     3) %s\n', f_2p, f_tfr, f_solv);

Out.years         = years;
Out.tax_ss0_65    = tax_ss0_65;
Out.tax_age67     = tax_age67;
Out.tax_age70     = tax_age70;
Out.tax_ref_65    = tax_ref_65;
Out.f_2panel      = f_2p;
Out.f_tfr         = f_tfr;
Out.f_solv        = f_solv;


end
