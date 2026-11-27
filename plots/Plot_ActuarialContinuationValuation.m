function Out = Plot_ActuarialContinuationValuation(Out_Cash, Params, RegionOption)
% PLOT_ACTUARIALCONTINUATIONVALUATION
% Computes and graphs the ACC-Style / Treasury CBAx Conditional Continuation
% Valuation (V_{t0}) at NZ Treasury Circular 2024/15 dual discount rates
% (2.0% Central & 8.0% Sensitivity, net of 30% attribution haircut) with
% full 4-Region decomposition support.
%
% USAGE EXAMPLES:
%   Out = Plot_ActuarialContinuationValuation(Out_Cash, Params, 'National');
%   Out = Plot_ActuarialContinuationValuation(Out_Cash, Params, 'Auckland');
%   Out = Plot_ActuarialContinuationValuation(Out_Cash, Params, 'Large');
%   Out = Plot_ActuarialContinuationValuation(Out_Cash, Params, 'All4');
%   Out = Plot_ActuarialContinuationValuation([], [], 'All4'); % Standalone test mode!

if nargin < 3 || isempty(RegionOption)
    RegionOption = 'National';
end
if nargin < 2 || isempty(Params)
    Params = struct();
end

if exist('Compute_Actuarial_Ledger', 'file') == 0 && exist('setup_igw_paths.m', 'file') == 2
    setup_igw_paths(true);
end

% Delegate all cash-flow & Treasury Circular 2024/15 actuarial math to pure ledger engine:
Out     = Compute_Actuarial_Ledger(Out_Cash, Params, struct('Verbose', true));
regions = Out.Regions;
N_reg   = numel(regions);

% -------------------------------------------------------------------------
% 4. DISPATCH PLOTTING BASED ON RegionOption (DYNAMIC ACROSS DATASPEC.REGIONS)
% -------------------------------------------------------------------------
OutputDir  = Resolve_IGW_OutputDir('', Out.Profile_ID);
AnchorTag  = Out.Calibration_Anchor;
opt_clean  = lower(regexprep(strtrim(char(RegionOption)), '^hh_', ''));
if strcmp(opt_clean, 'akl') && ismember('Auckland', regions)
    opt_clean = 'auckland';
end
reg_match_idx = find(strcmpi(regions, opt_clean), 1, 'first');

if strcmp(opt_clean, 'national')
    plot_two_panel_ledger(Out, sprintf('National Aggregate (All %d Regions)', N_reg), 'National', AnchorTag, OutputDir, Out);
elseif ~isempty(reg_match_idx)
    r_name = regions{reg_match_idx};
    r_pct  = 100 * Out.Pop_Shares(reg_match_idx);
    plot_two_panel_ledger(Out.Reg.(r_name), sprintf('%s Region (%.1f%% Base Pop)', r_name, r_pct), r_name, AnchorTag, OutputDir, Out);
else
    plot_all4_regions_dashboard(Out, regions, AnchorTag, OutputDir);
    plot_year5_regional_bar_breakdown(Out, regions, AnchorTag, OutputDir);
end


end

%% ========================================================================
%  HELPER 1: 2-PANEL & STANDALONE SINGLE-PANEL PUBLICATION PLOTTER
%  ========================================================================
function plot_two_panel_ledger(L, TitleLabel, ShortTag, AnchorTag, OutputDir, MetaCurr)
curr_iso_act = 'NZD'; curr_sym_act = '$'; curr_yr_act = 2025;
if nargin >= 6 && isstruct(MetaCurr) && isfield(MetaCurr, 'Currency_ISO')
    curr_iso_act = MetaCurr.Currency_ISO; curr_sym_act = MetaCurr.Currency_Symbol; curr_yr_act = MetaCurr.Currency_Base_Year;
end
if nargin < 4 || isempty(AnchorTag)
    if isfield(L, 'Calibration_Anchor')
        AnchorTag = L.Calibration_Anchor;
    else
        AnchorTag = 'Dunedin_22';
    end
end
if nargin < 5 || isempty(OutputDir)
    prof_id = 'NZ_Dunedin1972';
    if isstruct(Params) && isfield(Params, 'Profile_ID') && ~isempty(Params.Profile_ID)
        prof_id = Params.Profile_ID;
    elseif isstruct(Params) && isfield(Params, 'Profile_Name') && ~isempty(Params.Profile_Name)
        prof_id = Params.Profile_Name;
    elseif isstruct(Params) && isfield(Params, 'Calibration_Anchor') && ~isempty(Params.Calibration_Anchor)
        ds_act  = Load_Empirical_Profile(Params.Calibration_Anchor);
        prof_id = ds_act.Profile_ID;
    end
    OutputDir = Resolve_IGW_OutputDir('', prof_id);
end
if ~exist(OutputDir, 'dir'), mkdir(OutputDir); end

years = L.years;
idx_y5 = find(years == 5, 1);
if isempty(idx_y5), idx_y5 = 2; end

% Wide 1860 x 720 canvas so each panel has a generous horizontal aspect ratio
fig_2p = figure('Name', ['Actuarial Continuation Valuation: ', TitleLabel, ' (', AnchorTag, ')'], ...
    'Color', 'w', 'Position', [40, 50, 1860, 720]);

% --- PANEL A: CROWN FISCAL LEDGER ---
ax1 = subplot('Position', [0.055, 0.130, 0.420, 0.785]); hold(ax1, 'on');
fill(ax1, [years, fliplr(years)], [L.Booked_Fisc_8pct, fliplr(L.Booked_Fisc_2pct)], ...
    [0.63 0.85 0.61], 'FaceAlpha', 0.35, 'EdgeColor', 'none', ...
    'DisplayName', 'Treasury Dual-Rate Band (8% Sens. to 2% Central)');
plot(ax1, years, L.Cum_Inv, 'r--o', 'LineWidth', 2.4, 'MarkerSize', 5.5, ...
    'DisplayName', 'Cumulative Public Investment Outlay (\Delta G_{ECE} + E)');
plot(ax1, years, L.Cum_Savings, ':', 'Color', [0.12 0.47 0.71], 'Marker', 's', 'LineWidth', 2.0, 'MarkerSize', 4.5, ...
    'DisplayName', 'Cash-Flow Direct Cost Savings (Wait-As-You-Go)');
plot(ax1, years, L.Cum_TotFisc, '-.', 'Color', [0.17 0.63 0.17], 'Marker', '^', 'LineWidth', 2.1, 'MarkerSize', 5.0, ...
    'DisplayName', 'Cash-Flow Total Fiscal Return (Savings + \Delta Tax)');
plot(ax1, years, L.Booked_Fisc_2pct, '-', 'Color', [0.00 0.43 0.17], 'Marker', 'd', 'LineWidth', 2.8, 'MarkerSize', 6.0, ...
    'DisplayName', 'Actuarial Recognised Fiscal Return (2% Real, 30% Haircut)');
plot(ax1, years, L.Booked_Fisc_8pct, '--', 'Color', [0.25 0.67 0.36], 'Marker', 'v', 'LineWidth', 1.9, 'MarkerSize', 4.5, ...
    'DisplayName', 'Actuarial Recognised Fiscal Return (8% Real Sensitivity)');
plot(ax1, years, L.Booked_Sav_2pct, '-', 'Color', [0.03 0.32 0.61], 'Marker', 's', 'LineWidth', 2.3, 'MarkerSize', 5.0, ...
    'DisplayName', 'Actuarial Recognised Direct Cost Avoidance Alone (2% Real)');

xline(ax1, years(idx_y5), '--', 'Color', [0.00 0.43 0.17], 'LineWidth', 1.4, 'HandleVisibility', 'off');

y5_inv  = L.Cum_Inv(idx_y5);
y5_cash = L.Cum_TotFisc(idx_y5);
y5_bk2  = L.Booked_Fisc_2pct(idx_y5);
y5_bk8  = L.Booked_Fisc_8pct(idx_y5);
y5_sav2 = L.Booked_Sav_2pct(idx_y5);

msg_A = sprintf(['Year %d Audit (%s):\n', ...
    '• Outlay: %s%.2fB | Cash Return: %s%.2fB\n', ...
    '• Booked Return (2%%): %s%.2fB (%.2fx Outlay)\n', ...
    '• Booked Return (8%%): %s%.2fB (%.2fx Outlay)\n', ...
    '• Booked Cost Avoidance Alone (2%%): %s%.2fB'], ...
    years(idx_y5), ShortTag, curr_sym_act, y5_inv, curr_sym_act, y5_cash, ...
    curr_sym_act, y5_bk2, y5_bk2/max(1e-6,y5_inv), ...
    curr_sym_act, y5_bk8, y5_bk8/max(1e-6,y5_inv), curr_sym_act, y5_sav2);

y_max_A = max(L.Booked_Fisc_2pct);
xlim(ax1, [-1.5, max(years) + 2.5]);
ylim(ax1, [0, 1.16 * y_max_A]);

text(ax1, years(idx_y5) + 2.0, 0.57 * y_max_A, msg_A, ...
    'FontSize', 8.2, 'FontWeight', 'bold', 'Color', [0.00 0.27 0.11], ...
    'BackgroundColor', [0.94 0.98 0.95], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 5);

grid(ax1, 'on'); box(ax1, 'on');
xlabel(ax1, 'Transition Horizon (Years from Policy Introduction)', 'FontSize', 10.5, 'FontWeight', 'bold');
ylabel(ax1, sprintf('Cumulative / Recognised %s (Billions, Real %d%s)', curr_iso_act, curr_yr_act, curr_sym_act), 'FontSize', 10.5, 'FontWeight', 'bold');
title(ax1, ['A. Fiscal Ledger: ', TitleLabel], 'FontSize', 10.5, 'FontWeight', 'bold');
lgd1 = legend(ax1, 'Location', 'northwest', 'FontSize', 7.8);
IGW_UI_Style('legend_alpha', lgd1, 0.92);

% --- PANEL B: ECONOMY-WIDE GDP LENS / PRIZE ---
ax2 = subplot('Position', [0.535, 0.130, 0.425, 0.785]); hold(ax2, 'on');
fill(ax2, [years, fliplr(years)], [L.Booked_GDP_8pct, fliplr(L.Booked_GDP_2pct)], ...
    [0.78 0.91 0.75], 'FaceAlpha', 0.45, 'EdgeColor', 'none', ...
    'DisplayName', 'Recognised GDP Dual-Rate Band (8% Sens. to 2% Central)');
plot(ax2, years, L.Cum_Inv, 'r--o', 'LineWidth', 2.3, 'MarkerSize', 5.0, ...
    'DisplayName', 'Cumulative Public Investment Outlay (\Delta G_{ECE} + E)');
plot(ax2, years, L.Cum_dGDP, '-.', 'Color', [0.17 0.63 0.17], 'Marker', '^', 'LineWidth', 2.2, 'MarkerSize', 5.0, ...
    'DisplayName', 'Realized Cumulative GDP Gain (Wait-As-You-Go Cash)');
plot(ax2, years, L.Booked_GDP_2pct, '-', 'Color', [0.00 0.43 0.17], 'Marker', 'd', 'LineWidth', 2.8, 'MarkerSize', 6.0, ...
    'DisplayName', 'Recognised Economy-Wide Prize (V_t^{Econ} at 2% Real)');
plot(ax2, years, L.Booked_GDP_8pct, '--', 'Color', [0.25 0.67 0.36], 'Marker', 'v', 'LineWidth', 1.9, 'MarkerSize', 4.5, ...
    'DisplayName', 'Recognised Economy-Wide Prize (V_t^{Econ} at 8% Sensitivity)');

xline(ax2, years(idx_y5), '--', 'Color', [0.00 0.43 0.17], 'LineWidth', 1.4, 'HandleVisibility', 'off');

msg_B = sprintf(['Year %d Recognised GDP Prize (%s):\n', ...
    '• Realized Cash GDP Gain: %s%.2fB\n', ...
    '• Booked 25-Yr GDP Prize (2%%): %s%.2fB\n', ...
    '• Booked 25-Yr GDP Prize (8%%): %s%.2fB'], ...
    years(idx_y5), ShortTag, curr_sym_act, L.Cum_dGDP(idx_y5), ...
    curr_sym_act, L.Booked_GDP_2pct(idx_y5), curr_sym_act, L.Booked_GDP_8pct(idx_y5));

y_max_B = max(L.Booked_GDP_2pct);
% Pad left xlim to -1.5 so the Year-0 marker & Year-5 vertical line have breathing
% room on the left of the legend, and pad right xlim to +2.5 so Year-60 markers aren't clipped
xlim(ax2, [-1.5, max(years) + 2.5]);
ylim(ax2, [0, 1.16 * y_max_B]);

% Placed at x = Year 5 + 1.8 and y = 0.63 * y_max_B so the callout box sits
% cleanly in the open white pocket above the rising 2% curve
text(ax2, years(idx_y5) + 1.8, 0.63 * y_max_B, msg_B, ...
    'FontSize', 8.2, 'FontWeight', 'bold', 'Color', [0.00 0.27 0.11], ...
    'BackgroundColor', [0.94 0.98 0.95], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 5);

grid(ax2, 'on'); box(ax2, 'on');
xlabel(ax2, 'Transition Horizon (Years from Policy Introduction)', 'FontSize', 10.5, 'FontWeight', 'bold');
ylabel(ax2, sprintf('Cumulative / Recognised %s (Billions, Real %d%s)', curr_iso_act, curr_yr_act, curr_sym_act), 'FontSize', 10.5, 'FontWeight', 'bold');
title(ax2, ['B. Economy-Wide GDP Prize: ', TitleLabel], 'FontSize', 10.5, 'FontWeight', 'bold');
lgd2 = legend(ax2, 'Location', 'northwest', 'FontSize', 7.9);
IGW_UI_Style('legend_alpha', lgd2, 0.92);

% Auto-export the 2-Panel combined figure AND the two individual sibling panels
f_2panel = fullfile(OutputDir, sprintf('Fig_Actuarial_2Panel_%s_%s.png',  ShortTag, AnchorTag));
f_fiscal = fullfile(OutputDir, sprintf('Fig_Actuarial_Fiscal_%s_%s.png',  ShortTag, AnchorTag));
f_wide   = fullfile(OutputDir, sprintf('Fig_Actuarial_WideGDP_%s_%s.png', ShortTag, AnchorTag));

exportgraphics(fig_2p, f_2panel, 'Resolution', 300, 'BackgroundColor', 'white');

% Before exporting the standalone single-panel charts (f_fiscal and f_wide),
% give each standalone panel a wider 4:3 aspect ratio so the title, legend,
% and Year-5 callout box have generous horizontal room when viewed by itself!
single_vis = IGW_UI_Style('headless_vis');
fig_single = figure('Visible', single_vis, 'Color', 'w', 'Position', [60, 60, 1020, 680]);
ax2_copy = copyobj([ax2, lgd2], fig_single);
set(ax2_copy(1), 'Position', [0.10, 0.13, 0.85, 0.78]);
exportgraphics(fig_single, f_wide, 'Resolution', 300, 'BackgroundColor', 'white');
clf(fig_single);
ax1_copy = copyobj([ax1, lgd1], fig_single);
set(ax1_copy(1), 'Position', [0.10, 0.13, 0.85, 0.78]);
exportgraphics(fig_single, f_fiscal, 'Resolution', 300, 'BackgroundColor', 'white');
close(fig_single);

fprintf('  -> Saved sibling plots:\n     1) %s\n     2) %s\n     3) %s\n', f_2panel, f_fiscal, f_wide);
end

%% ========================================================================
%  HELPER 3: 4-REGION SIDE-BY-SIDE DASHBOARD ('All4' MODE)
%  ========================================================================
function plot_all4_regions_dashboard(Out, regions, AnchorTag, OutputDir)
if nargin < 3 || isempty(AnchorTag), AnchorTag = Out.Calibration_Anchor; end
if nargin < 4 || isempty(OutputDir), OutputDir = pwd; end

years  = Out.years;
n_r    = numel(regions);
idx_y5 = find(years == 5, 1);
if isempty(idx_y5), idx_y5 = 2; end
if isfield(Out, 'Pop_Shares') && numel(Out.Pop_Shares) == n_r
    pop_labels = arrayfun(@(w) sprintf('%.1f%% Pop', 100*w), Out.Pop_Shares, 'UniformOutput', false);
else
    pop_labels = arrayfun(@(k) sprintf('Reg %d', k), 1:n_r, 'UniformOutput', false);
end

fig_dash = figure('Name', [sprintf('%d-Region Actuarial Continuation Dashboard (', n_r), AnchorTag, ')'], ...
    'Color', 'w', 'Position', [40, 40, 1650, 780]);

for r = 1:n_r
    reg = regions{r};
    L   = Out.Reg.(reg);

    % Top Row: Regional Fiscal Ledger
    subplot(2, n_r, r); hold on;
    fill([years, fliplr(years)], [L.Booked_Fisc_8pct, fliplr(L.Booked_Fisc_2pct)], ...
        [0.63 0.85 0.61], 'FaceAlpha', 0.35, 'EdgeColor', 'none');
    plot(years, L.Cum_Inv, 'r--o', 'LineWidth', 1.8, 'MarkerSize', 3.5);
    plot(years, L.Cum_Savings, ':', 'Color', [0.12 0.47 0.71], 'LineWidth', 1.6);
    plot(years, L.Cum_TotFisc, '-.', 'Color', [0.17 0.63 0.17], 'LineWidth', 1.7);
    plot(years, L.Booked_Sav_2pct, '-', 'Color', [0.03 0.32 0.61], 'LineWidth', 1.8);
    plot(years, L.Booked_Fisc_2pct, '-', 'Color', [0.00 0.43 0.17], 'LineWidth', 2.3);
    xline(years(idx_y5), '--', 'Color', [0.4 0.4 0.4]);

    title(sprintf('%s (%s): Fiscal Ledger', reg, pop_labels{r}), 'FontSize', 10, 'FontWeight', 'bold');
    ylabel(sprintf('%s (%sB, Real)', Out.Currency_ISO, Out.Currency_Symbol)); grid on; box on;
    text(years(idx_y5)+2, 0.62*max(L.Booked_Fisc_2pct), ...
        sprintf('Yr 5 Audit:\nInv: %s%.2fB\nBooked (2%%): %s%.2fB\nCost Avoid: %s%.2fB', ...
        Out.Currency_Symbol, L.Cum_Inv(idx_y5), Out.Currency_Symbol, L.Booked_Fisc_2pct(idx_y5), Out.Currency_Symbol, L.Booked_Sav_2pct(idx_y5)), ...
        'FontSize', 7.5, 'BackgroundColor', [0.95 0.99 0.96], 'EdgeColor', [0.00 0.43 0.17]);
    if r == 1
        legend({'8%-2% Band','Cum Inv','Cash Sav','Cash Fisc','Booked Sav (2%)','Booked Fisc (2%)'}, ...
            'Location', 'northwest', 'FontSize', 6.8);
    end

    % Bottom Row: Regional Economy-Wide GDP Prize
    subplot(2, n_r, r + n_r); hold on;
    fill([years, fliplr(years)], [L.Booked_GDP_8pct, fliplr(L.Booked_GDP_2pct)], ...
        [0.78 0.91 0.75], 'FaceAlpha', 0.45, 'EdgeColor', 'none');
    plot(years, L.Cum_Inv, 'r--o', 'LineWidth', 1.8, 'MarkerSize', 3.5);
    plot(years, L.Cum_dGDP, '-.', 'Color', [0.17 0.63 0.17], 'LineWidth', 1.8);
    plot(years, L.Booked_GDP_2pct, '-', 'Color', [0.00 0.43 0.17], 'LineWidth', 2.3);
    plot(years, L.Booked_GDP_8pct, '--', 'Color', [0.25 0.67 0.36], 'LineWidth', 1.6);
    xline(years(idx_y5), '--', 'Color', [0.4 0.4 0.4]);

    title(sprintf('%s: Economy-Wide GDP Prize', reg), 'FontSize', 10, 'FontWeight', 'bold');
    xlabel('Transition Years'); ylabel(sprintf('%s (%sB, Real)', Out.Currency_ISO, Out.Currency_Symbol)); grid on; box on;
    text(years(idx_y5)+2, 0.65*max(L.Booked_GDP_2pct), ...
        sprintf('Yr 5 GDP Prize:\nCash: %s%.2fB\nBooked (2%%): %s%.2fB\nBooked (8%%): %s%.2fB', ...
        Out.Currency_Symbol, L.Cum_dGDP(idx_y5), Out.Currency_Symbol, L.Booked_GDP_2pct(idx_y5), Out.Currency_Symbol, L.Booked_GDP_8pct(idx_y5)), ...
        'FontSize', 7.5, 'BackgroundColor', [0.95 0.99 0.96], 'EdgeColor', [0.00 0.43 0.17]);
    if r == 1
        legend({'8%-2% Band','Cum Inv','Cash GDP','Booked GDP (2%)','Booked GDP (8%)'}, ...
            'Location', 'northwest', 'FontSize', 6.8);
    end
end

f_dash = fullfile(OutputDir, sprintf('Fig_Actuarial_Dashboard_All4_%s.png', AnchorTag));
exportgraphics(fig_dash, f_dash, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved 4-Region Dashboard: %s\n', f_dash);

end

%% ========================================================================
%  HELPER 4: YEAR 5 REGIONAL BAR BREAKDOWN ('All4' MODE)
%  ========================================================================
function plot_year5_regional_bar_breakdown(Out, regions, AnchorTag, OutputDir)
if nargin < 3 || isempty(AnchorTag), AnchorTag = Out.Calibration_Anchor; end
if nargin < 4 || isempty(OutputDir), OutputDir = pwd; end

idx_y5 = find(Out.years == 5, 1);
if isempty(idx_y5), idx_y5 = 2; end

n_r    = numel(regions);
M_fisc = zeros(n_r, 5);
M_gdp  = zeros(n_r, 4);
for r = 1:n_r
    reg = regions{r};
    L = Out.Reg.(reg);
    M_fisc(r, :) = [L.Cum_Inv(idx_y5), L.Cum_TotFisc(idx_y5), L.Booked_Sav_2pct(idx_y5), ...
        L.Booked_Fisc_8pct(idx_y5), L.Booked_Fisc_2pct(idx_y5)];
    M_gdp(r, :)  = [L.Cum_Inv(idx_y5), L.Cum_dGDP(idx_y5), L.Booked_GDP_8pct(idx_y5), L.Booked_GDP_2pct(idx_y5)];
end

fig_bar = figure('Name', ['Year 5 Parliamentary Audit by Region (', AnchorTag, ')'], ...
    'Color', 'w', 'Position', [120, 120, 1320, 520]);

ax_b1 = subplot(1, 2, 1);
b1 = bar(categorical(regions, regions), M_fisc, 'grouped');
set(b1(1), 'FaceColor', [0.84 0.15 0.16]);
set(b1(2), 'FaceColor', [0.60 0.80 0.60]);
set(b1(3), 'FaceColor', [0.12 0.47 0.71]);
set(b1(4), 'FaceColor', [0.25 0.67 0.36]);
set(b1(5), 'FaceColor', [0.00 0.43 0.17]);
ylabel(Out.Currency_Unit);
title('A. Year 5 Fiscal Audit by Region: Cash vs. Booked Return');
legend({'Cum Outlay', 'Cash Fiscal Return', 'Booked Cost Avoidance Alone (2%)', ...
    'Booked Total Fiscal (8% Sens.)', 'Booked Total Fiscal (2% Central)'}, 'Location', 'northwest', 'FontSize', 8.2);
grid on;

ax_b2 = subplot(1, 2, 2);
b2 = bar(categorical(regions, regions), M_gdp, 'grouped');
set(b2(1), 'FaceColor', [0.84 0.15 0.16]);
set(b2(2), 'FaceColor', [0.60 0.80 0.60]);
set(b2(3), 'FaceColor', [0.25 0.67 0.36]);
set(b2(4), 'FaceColor', [0.00 0.43 0.17]);
ylabel(Out.Currency_Unit);
title('B. Year 5 Economy-Wide GDP Prize by Region');
legend({'Cum Outlay', 'Realized Cash GDP Gain', 'Booked 25-Yr GDP Prize (8% Sens.)', ...
    'Booked 25-Yr GDP Prize (2% Central)'}, 'Location', 'northwest', 'FontSize', 8.5);
grid on;

f_bar_2p   = fullfile(OutputDir, sprintf('Fig_Actuarial_Year5Audit_All4_%s.png',         AnchorTag));
f_bar_fisc = fullfile(OutputDir, sprintf('Fig_Actuarial_Year5Audit_Fiscal_All4_%s.png',  AnchorTag));
f_bar_wide = fullfile(OutputDir, sprintf('Fig_Actuarial_Year5Audit_WideGDP_All4_%s.png', AnchorTag));

exportgraphics(fig_bar, f_bar_2p,   'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(ax_b1,   f_bar_fisc, 'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(ax_b2,   f_bar_wide, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved Year 5 Audit Bar Plots:\n     1) %s\n     2) %s\n     3) %s\n', f_bar_2p, f_bar_fisc, f_bar_wide);

end

