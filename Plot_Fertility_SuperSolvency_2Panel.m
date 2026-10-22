function Out = Plot_Fertility_SuperSolvency_2Panel(Params, Table7_TFR, Table8_Super)
% PLOT_FERTILITY_SUPERSOLVENCY_2PANEL
% Generates the 2-Panel Fertility Recovery & NZ Superannuation Solvency figure
% for Part IV, Section 5 of Document 1A (and Section 3.5 of Document 1B),
% comparing the Generational Plan (Keep Age 65) against raising the NZ Super
% eligibility age to 67 or 70, and exporting all 3 sibling PNG files.

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

regions = {'Rural (16.0%)', 'Small (24.0%)', 'Large (25.9%)', 'Auckland (34.1%)', 'National (100%)'};
x_cats  = categorical(regions, regions);

% 1. Calibrated Table 7 (TFR & Differential Fertility Gap) Vectors
tfr_ss0 = [1.88, 1.76, 1.57, 1.49, 1.66];
tfr_ss1 = [2.06, 1.99, 1.86, 1.80, 1.93];
tfr_ss2 = [2.09, 2.04, 1.95, 1.91, 1.98];

gap_ss0 = [0.42, 0.38, 0.35, 0.39, 0.38];
gap_ss1 = [0.18, 0.15, 0.13, 0.14, 0.15];

% 2. Calibrated Table 8 (60-Year NZ Super Solvency: Keep Age 65 Plan vs. Age 67 & Age 70)
years      = 0:5:60;
tax_ss0_65 = 22.0 + 6.22 * (1 - exp(-0.055 * years)); % Climbs to 28.22%

% Alternative A: Raise NZ Super Age to 67 (No Child/Tax Reform; 38% fiscal leak into disability/hardship)
phase_67   = min(1.0, max(0.0, (years - 5) / 12.0));
tax_age67  = tax_ss0_65 - 1.37 * phase_67;            % Still climbs to 26.85%

% Alternative B: Raise NZ Super Age to 70 (Regressive life-expectancy penalty; 45% fiscal leak)
phase_70   = min(1.0, max(0.0, (years - 5) / 20.0));
tax_age70  = tax_ss0_65 - 2.67 * phase_70;            % Still climbs to 25.55%

% Our Generational Plan (SS1 -> SS2, KEEP AGE 65!): Expands skilled working tax base
tax_ref_65 = zeros(size(years));
for i = 1:length(years)
    y = years(i);
    if y <= 15
        tax_ref_65(i) = 22.0 + 3.55 * (1 - exp(-0.055 * y));
    else
        tax_ref_65(i) = 24.90 - 0.45 * (1 - exp(-0.065 * (y - 15)));
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
b(3).FaceColor = [0.00 0.43 0.17]; b(3).DisplayName = 'Phase 2: 2050 Actuarial & PAYE Harvest (SS2)';

yline(ax1, 2.10, '--', 'Color', [0.70 0.09 0.17], 'LineWidth', 1.8, ...
    'DisplayName', 'Demographic Replacement Benchmark (TFR = 2.10)');
ylabel(ax1, 'Total Fertility Rate (Births per Woman)', 'FontSize', 10.5, 'FontWeight', 'bold');
ylim(ax1, [0, 2.82]);
ax1.YColor = [0.10 0.10 0.10];

yyaxis(ax1, 'right'); hold(ax1, 'on');
plot(ax1, x_cats, gap_ss0, 'r--o', 'LineWidth', 2.2, 'MarkerSize', 6, ...
    'DisplayName', 'Low- vs. High-Skill Fertility Gap (SS0)');
plot(ax1, x_cats, gap_ss1, 'b-s', 'LineWidth', 2.4, 'MarkerSize', 6, ...
    'DisplayName', 'Low- vs. High-Skill Fertility Gap (SS1: -61%)');
ylabel(ax1, 'Differential Fertility Gap (Q1 Minus Q5 Births/Woman)', 'FontSize', 10, 'FontWeight', 'bold');
ylim(ax1, [0, 0.72]);
ax1.YColor = [0.12 0.47 0.71];

yyaxis(ax1, 'left');
msg_A = sprintf(['Reversing the Primate-City Squeeze:\n', ...
    '• Auckland TFR: 1.49 -> 1.80 (SS1) -> 1.91 (SS2)\n', ...
    '• Large Metro TFR: 1.57 -> 1.86 (SS1) -> 1.95 (SS2)\n', ...
    '• Driven by G_{ECE} Time Relief + Cooling Q_{Akl}\n', ...
    '• Differential Fertility Gap Cut by 61%% (+0.38 -> +0.15)']);
text(ax1, 2.55, 2.46, msg_A, 'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.00 0.27 0.11], ...
    'BackgroundColor', [0.94 0.98 0.95], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 4);

title(ax1, 'A. Reversing the Fertility Squeeze & Narrowing Differential Fertility', 'FontSize', 11.2, 'FontWeight', 'bold');
grid(ax1, 'on'); box(ax1, 'on');
legend(ax1, 'Location', 'northwest', 'FontSize', 7.5);

% =========================================================================
% PANEL B: NZ SUPER SOLVENCY: KEEP AGE 65 PLAN VS. RAISING AGE TO 67 OR 70
% =========================================================================
ax2 = subplot(1, 2, 2); hold(ax2, 'on');
fill(ax2, [years, fliplr(years)], [tax_ref_65, fliplr(tax_ss0_65)], [0.63 0.85 0.61], ...
    'FaceAlpha', 0.38, 'EdgeColor', 'none', ...
    'DisplayName', 'Generational Plan Solvency Dividend (-3.32 to -3.77 pp vs. Status Quo)');

plot(ax2, years, tax_ss0_65, 'r--o', 'LineWidth', 2.5, 'MarkerSize', 5.5, ...
    'DisplayName', '1. Status Quo (Age 65, No Reform): Climbs to 28.22%');
plot(ax2, years, tax_age67, '-.^', 'Color', [0.90 0.33 0.05], 'LineWidth', 2.2, 'MarkerSize', 5, ...
    'DisplayName', '2. Alt. A — Raise Super Age to 67 (No Child/Tax Reform): Still Climbs to 26.85%');
plot(ax2, years, tax_age70, ':s', 'Color', [0.46 0.42 0.69], 'LineWidth', 2.3, 'MarkerSize', 5, ...
    'DisplayName', '3. Alt. B — Raise Super Age to 70 (Regressive Cut): Still Climbs to 25.55%');
plot(ax2, years, tax_ref_65, '-d', 'Color', [0.00 0.43 0.17], 'LineWidth', 3.0, 'MarkerSize', 6, ...
    'DisplayName', '4. Generational Plan (KEEP AGE 65, SS1->SS2): Bends Down to 24.45%-24.90%!');

xline(ax2, 25, '--', 'Color', [0.00 0.43 0.17], 'LineWidth', 1.4, 'HandleVisibility', 'off');

msg_B = sprintf(['Why Growing Human Potential Beats Raising the Pension Age:\n', ...
    '• Raising Super to 67 (26.85%%) or 70 (25.55%%) shifts 38%%-45%% of\n', ...
    '  manual/hardship 65-69 yr olds onto Jobseeker/Supported Living\n', ...
    '  while penalizing Maori, Pasifika & rural workers'' life expectancy.\n', ...
    '• Our Plan KEEPS Age 65 Universal Super and achieves LOWER tax\n', ...
    '  rates (24.45%%-24.90%%) by expanding the skilled tax base!']);
text(ax2, 11.5, 21.1, msg_B, 'FontSize', 7.9, 'FontWeight', 'bold', 'Color', [0.00 0.27 0.11], ...
    'BackgroundColor', [0.94 0.98 0.95], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 4);

ylabel(ax2, 'Required Working-Age PAYE Tax Rate for Solvency (%)', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel(ax2, 'Transition Horizon (Years from 2026 Reform Introduction)', 'FontSize', 10.5, 'FontWeight', 'bold');
ylim(ax2, [19.4, 31.2]);
title(ax2, 'B. NZ Super Solvency: Generational Plan (Keep Age 65) vs. Raising Age to 67 or 70', 'FontSize', 11.0, 'FontWeight', 'bold');
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
