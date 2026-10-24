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

regions = {'Rural', 'Small', 'Large', 'Auckland'};
N_reg   = length(regions);

% -------------------------------------------------------------------------
% 1. ENSURE NATIONAL & 4-REGION FLOWS EXIST (STANDALONE FALLBACK IF NEEDED)
% -------------------------------------------------------------------------
% Resolve Calibration_Anchor ('Dunedin_22' vs. 'MetroSqueeze_GUiNZ')
Calibration_Anchor = get_param_or_default(Params, 'Calibration_Anchor', 'Dunedin_22');
if isempty(Out_Cash) || ~isfield(Out_Cash, 'years')
    Out_Cash = build_default_4region_cash_flows(regions, Calibration_Anchor);
elseif ~isfield(Out_Cash, 'Reg')
    Out_Cash = split_national_into_4regions(Out_Cash, regions, Calibration_Anchor);
end
Out.Calibration_Anchor = Calibration_Anchor;

years = Out_Cash.years;

% -------------------------------------------------------------------------
% 2. TREASURY CIRCULAR 2024/15 & CBAx CONTINUATION PARAMETERS
% -------------------------------------------------------------------------
H_window  = get_param_or_default(Params, 'H_window',  25);    % 25-yr forward recognition window
alpha_att = get_param_or_default(Params, 'alpha_att', 0.30);  % 30% conservative attribution haircut
g_cost    = get_param_or_default(Params, 'g_cost',    0.015); % 1.5% real productivity/cost growth
r_2pct    = get_param_or_default(Params, 'r_2pct',    0.020); % 2.0% NZ Treasury central social rate
r_8pct    = get_param_or_default(Params, 'r_8pct',    0.080); % 8.0% NZ Treasury sensitivity rate

% Region-specific Stage-2-to-Adulthood Markov persistence (psi_persist)
% Reflects higher metropolitan housing/rental stability gains once Q_k cools
psi_base_map = struct('Rural', 0.984, 'Small', 0.984, 'Large', 0.986, 'Auckland', 0.987, 'National', 0.985);

% -------------------------------------------------------------------------
% 3. COMPUTE ACTUARIAL CONTINUATION VALUATION FOR EACH REGION & NATIONAL
% -------------------------------------------------------------------------
for r = 1:N_reg
    reg = regions{r};
    Out.Reg.(reg) = compute_single_ledger(Out_Cash.Reg.(reg), years, H_window, alpha_att, ...
        g_cost, r_2pct, r_8pct, psi_base_map.(reg));
end

% Sum the 4 regions to guarantee exact spatial additivity at the National level
Out.years            = years;
Out.Regions          = regions;
Out.Cum_Inv          = Out_Cash.Cum_Inv;
Out.Cum_Savings      = Out_Cash.Cum_Savings;
Out.Cum_TotFisc      = Out_Cash.Cum_TotFisc;
Out.Cum_dGDP         = Out_Cash.Cum_dGDP;
Out.Booked_Sav_2pct  = zeros(size(years));
Out.Booked_Sav_8pct  = zeros(size(years));
Out.Booked_Fisc_2pct = zeros(size(years));
Out.Booked_Fisc_8pct = zeros(size(years));
Out.Booked_GDP_2pct  = zeros(size(years));
Out.Booked_GDP_8pct  = zeros(size(years));

for r = 1:N_reg
    reg = regions{r};
    Out.Booked_Sav_2pct  = Out.Booked_Sav_2pct  + Out.Reg.(reg).Booked_Sav_2pct;
    Out.Booked_Sav_8pct  = Out.Booked_Sav_8pct  + Out.Reg.(reg).Booked_Sav_8pct;
    Out.Booked_Fisc_2pct = Out.Booked_Fisc_2pct + Out.Reg.(reg).Booked_Fisc_2pct;
    Out.Booked_Fisc_8pct = Out.Booked_Fisc_8pct + Out.Reg.(reg).Booked_Fisc_8pct;
    Out.Booked_GDP_2pct  = Out.Booked_GDP_2pct  + Out.Reg.(reg).Booked_GDP_2pct;
    Out.Booked_GDP_8pct  = Out.Booked_GDP_8pct  + Out.Reg.(reg).Booked_GDP_8pct;
end

% Print Summary Audit Table at Year 5 (t=1) and Year 60 (t=end)
print_regional_audit_summary(Out, regions);

% -------------------------------------------------------------------------
% 4. DISPATCH PLOTTING BASED ON RegionOption
% -------------------------------------------------------------------------
if isfolder('Output_NZ_4Region_Intergen')
    OutputDir = 'Output_NZ_4Region_Intergen';
else
    OutputDir = pwd;
end
AnchorTag = Out.Calibration_Anchor;
opt_clean = lower(strtrim(RegionOption));

switch opt_clean
    case 'national'
        plot_two_panel_ledger(Out, 'National Aggregate (All 4 Regions)', 'National', AnchorTag, OutputDir);
    case {'rural', 'hh_rural'}
        plot_two_panel_ledger(Out.Reg.Rural, 'Rural Districts (16.0% Base Pop)', 'Rural', AnchorTag, OutputDir);
    case {'small', 'hh_small'}
        plot_two_panel_ledger(Out.Reg.Small, 'Small Provincial Towns (24.0% Base Pop)', 'Small', AnchorTag, OutputDir);
    case {'large', 'hh_large'}
        plot_two_panel_ledger(Out.Reg.Large, 'Large Regional Metros (25.9% Base Pop: Wgtn, Chch, Ham, Tau, Dun)', 'Large', AnchorTag, OutputDir);
    case {'auckland', 'hh_auckland', 'akl'}
        plot_two_panel_ledger(Out.Reg.Auckland, 'Auckland Primate Agglomeration (34.1% Base Pop)', 'Auckland', AnchorTag, OutputDir);
    case {'all4', 'all', 'grid', 'compare', 'regions'}
        plot_all4_regions_dashboard(Out, regions, AnchorTag, OutputDir);
        plot_year5_regional_bar_breakdown(Out, regions, AnchorTag, OutputDir);
    otherwise
        plot_all4_regions_dashboard(Out, regions, AnchorTag, OutputDir);
end


end

%% ========================================================================
%  HELPER 1: CORE ACTUARIAL CONTINUATION ENGINE FOR ONE LEDGER
%  ========================================================================
function L = compute_single_ledger(CashStruct, years, H_window, alpha_att, g_cost, r_2pct, r_8pct, psi_ann)
L = CashStruct;
L.years = years;

% Extend annual flows out to Year 100 so rolling 25-year window at Year 60 is exact
dt_step  = years(2) - years(1);
n_ext    = ceil(40 / dt_step);
yr_ext   = [years, years(end) + (1:n_ext)*dt_step];
ann_sav  = [CashStruct.Annual_Savings, repmat(CashStruct.Annual_Savings(end), 1, n_ext)];
ann_fisc = [CashStruct.Annual_TotFisc, repmat(CashStruct.Annual_TotFisc(end), 1, n_ext)];
ann_gdp  = [CashStruct.Annual_dGDP,    repmat(CashStruct.Annual_dGDP(end),    1, n_ext)];

yr_fine   = 0:1:max(yr_ext);
sav_fine  = interp1(yr_ext, ann_sav,  yr_fine, 'pchip');
fisc_fine = interp1(yr_ext, ann_fisc, yr_fine, 'pchip');
gdp_fine  = interp1(yr_ext, ann_gdp,  yr_fine, 'pchip');

s_vec       = 1:H_window;
psi_persist = psi_ann .^ s_vec;
D_2pct      = ((1 + g_cost) ./ (1 + r_2pct)) .^ s_vec;
D_8pct      = ((1 + g_cost) ./ (1 + r_8pct)) .^ s_vec;

N_pts = length(years);
L.Booked_Sav_2pct  = zeros(1, N_pts);
L.Booked_Sav_8pct  = zeros(1, N_pts);
L.Booked_Fisc_2pct = zeros(1, N_pts);
L.Booked_Fisc_8pct = zeros(1, N_pts);
L.Booked_GDP_2pct  = zeros(1, N_pts);
L.Booked_GDP_8pct  = zeros(1, N_pts);

for i = 2:N_pts
    y = years(i);
    idx_fwd = (y + 2) : (y + 1 + H_window);
    pipeline_maturity = min(1.0, y / 15.0); % Full childhood age pipeline active by Year 15
    L.Booked_Sav_2pct(i)  = CashStruct.Cum_Savings(i) + (1 - alpha_att) * sum(D_2pct .* psi_persist .* sav_fine(idx_fwd)  * pipeline_maturity);
    L.Booked_Sav_8pct(i)  = CashStruct.Cum_Savings(i) + (1 - alpha_att) * sum(D_8pct .* psi_persist .* sav_fine(idx_fwd)  * pipeline_maturity);
    L.Booked_Fisc_2pct(i) = CashStruct.Cum_TotFisc(i) + (1 - alpha_att) * sum(D_2pct .* psi_persist .* fisc_fine(idx_fwd) * pipeline_maturity);
    L.Booked_Fisc_8pct(i) = CashStruct.Cum_TotFisc(i) + (1 - alpha_att) * sum(D_8pct .* psi_persist .* fisc_fine(idx_fwd) * pipeline_maturity);
    L.Booked_GDP_2pct(i)  = CashStruct.Cum_dGDP(i)    + (1 - alpha_att) * sum(D_2pct .* psi_persist .* gdp_fine(idx_fwd)  * pipeline_maturity);
    L.Booked_GDP_8pct(i)  = CashStruct.Cum_dGDP(i)    + (1 - alpha_att) * sum(D_8pct .* psi_persist .* gdp_fine(idx_fwd)  * pipeline_maturity);
end
end

%% ========================================================================
%  HELPER 2: 2-PANEL & STANDALONE SINGLE-PANEL PUBLICATION PLOTTER
%  ========================================================================
function plot_two_panel_ledger(L, TitleLabel, ShortTag, AnchorTag, OutputDir)
if nargin < 4 || isempty(AnchorTag)
    if isfield(L, 'Calibration_Anchor')
        AnchorTag = L.Calibration_Anchor;
    else
        AnchorTag = 'Dunedin_22';
    end
end
if nargin < 5 || isempty(OutputDir)
    if isfolder('Output_NZ_4Region_Intergen')
        OutputDir = 'Output_NZ_4Region_Intergen';
    else
        OutputDir = pwd;
    end
end

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
    '• Outlay: $%.2fB | Cash Return: $%.2fB\n', ...
    '• Booked Return (2%%): $%.2fB (%.2fx Outlay)\n', ...
    '• Booked Return (8%%): $%.2fB (%.2fx Outlay)\n', ...
    '• Booked Cost Avoidance Alone (2%%): $%.2fB'], ...
    years(idx_y5), ShortTag, y5_inv, y5_cash, y5_bk2, y5_bk2/max(1e-6,y5_inv), ...
    y5_bk8, y5_bk8/max(1e-6,y5_inv), y5_sav2);

y_max_A = max(L.Booked_Fisc_2pct);
xlim(ax1, [-1.5, max(years) + 2.5]);
ylim(ax1, [0, 1.16 * y_max_A]);

text(ax1, years(idx_y5) + 2.0, 0.57 * y_max_A, msg_A, ...
    'FontSize', 8.2, 'FontWeight', 'bold', 'Color', [0.00 0.27 0.11], ...
    'BackgroundColor', [0.94 0.98 0.95], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 5);

grid(ax1, 'on'); box(ax1, 'on');
xlabel(ax1, 'Transition Horizon (Years from Policy Introduction)', 'FontSize', 10.5, 'FontWeight', 'bold');
ylabel(ax1, 'Cumulative / Recognised NZD (Billions, Real 2025$)', 'FontSize', 10.5, 'FontWeight', 'bold');
title(ax1, ['A. Fiscal Ledger: ', TitleLabel], 'FontSize', 10.5, 'FontWeight', 'bold');
lgd1 = legend(ax1, 'Location', 'northwest', 'FontSize', 7.8);
lgd1.BoxFace.ColorType = 'truecoloralpha';
lgd1.BoxFace.ColorData = uint8(255 * [1; 1; 1; 0.92]);

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
    '• Realized Cash GDP Gain: $%.2fB\n', ...
    '• Booked 25-Yr GDP Prize (2%%): $%.2fB\n', ...
    '• Booked 25-Yr GDP Prize (8%%): $%.2fB'], ...
    years(idx_y5), ShortTag, L.Cum_dGDP(idx_y5), L.Booked_GDP_2pct(idx_y5), L.Booked_GDP_8pct(idx_y5));

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
ylabel(ax2, 'Cumulative / Recognised NZD (Billions, Real 2025$)', 'FontSize', 10.5, 'FontWeight', 'bold');
title(ax2, ['B. Economy-Wide GDP Prize: ', TitleLabel], 'FontSize', 10.5, 'FontWeight', 'bold');
lgd2 = legend(ax2, 'Location', 'northwest', 'FontSize', 7.9);
lgd2.BoxFace.ColorType = 'truecoloralpha';
lgd2.BoxFace.ColorData = uint8(255 * [1; 1; 1; 0.92]);

% Auto-export the 2-Panel combined figure AND the two individual sibling panels
f_2panel = fullfile(OutputDir, sprintf('Fig_Actuarial_2Panel_%s_%s.png',  ShortTag, AnchorTag));
f_fiscal = fullfile(OutputDir, sprintf('Fig_Actuarial_Fiscal_%s_%s.png',  ShortTag, AnchorTag));
f_wide   = fullfile(OutputDir, sprintf('Fig_Actuarial_WideGDP_%s_%s.png', ShortTag, AnchorTag));

exportgraphics(fig_2p, f_2panel, 'Resolution', 300, 'BackgroundColor', 'white');

% Before exporting the standalone single-panel charts (f_fiscal and f_wide),
% give each standalone panel a wider 4:3 aspect ratio so the title, legend,
% and Year-5 callout box have generous horizontal room when viewed by itself!
fig_single = figure('Visible', 'off', 'Color', 'w', 'Position', [60, 60, 1020, 680]);
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

years = Out.years;
idx_y5 = find(years == 5, 1);
if isempty(idx_y5), idx_y5 = 2; end
pop_labels = {'16.0% Pop', '24.0% Pop', '25.9% Pop', '34.1% Pop'};

fig_dash = figure('Name', ['4-Region Actuarial Continuation Dashboard (', AnchorTag, ')'], ...
    'Color', 'w', 'Position', [40, 40, 1650, 780]);

for r = 1:4
    reg = regions{r};
    L   = Out.Reg.(reg);

    % Top Row: Regional Fiscal Ledger
    subplot(2, 4, r); hold on;
    fill([years, fliplr(years)], [L.Booked_Fisc_8pct, fliplr(L.Booked_Fisc_2pct)], ...
        [0.63 0.85 0.61], 'FaceAlpha', 0.35, 'EdgeColor', 'none');
    plot(years, L.Cum_Inv, 'r--o', 'LineWidth', 1.8, 'MarkerSize', 3.5);
    plot(years, L.Cum_Savings, ':', 'Color', [0.12 0.47 0.71], 'LineWidth', 1.6);
    plot(years, L.Cum_TotFisc, '-.', 'Color', [0.17 0.63 0.17], 'LineWidth', 1.7);
    plot(years, L.Booked_Sav_2pct, '-', 'Color', [0.03 0.32 0.61], 'LineWidth', 1.8);
    plot(years, L.Booked_Fisc_2pct, '-', 'Color', [0.00 0.43 0.17], 'LineWidth', 2.3);
    xline(years(idx_y5), '--', 'Color', [0.4 0.4 0.4]);

    title(sprintf('%s (%s): Fiscal Ledger', reg, pop_labels{r}), 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('NZD ($B, Real)'); grid on; box on;
    text(years(idx_y5)+2, 0.62*max(L.Booked_Fisc_2pct), ...
        sprintf('Yr 5 Audit:\nInv: $%.2fB\nBooked (2%%): $%.2fB\nCost Avoid: $%.2fB', ...
        L.Cum_Inv(idx_y5), L.Booked_Fisc_2pct(idx_y5), L.Booked_Sav_2pct(idx_y5)), ...
        'FontSize', 7.5, 'BackgroundColor', [0.95 0.99 0.96], 'EdgeColor', [0.00 0.43 0.17]);
    if r == 1
        legend({'8%-2% Band','Cum Inv','Cash Sav','Cash Fisc','Booked Sav (2%)','Booked Fisc (2%)'}, ...
            'Location', 'northwest', 'FontSize', 6.8);
    end

    % Bottom Row: Regional Economy-Wide GDP Prize
    subplot(2, 4, r + 4); hold on;
    fill([years, fliplr(years)], [L.Booked_GDP_8pct, fliplr(L.Booked_GDP_2pct)], ...
        [0.78 0.91 0.75], 'FaceAlpha', 0.45, 'EdgeColor', 'none');
    plot(years, L.Cum_Inv, 'r--o', 'LineWidth', 1.8, 'MarkerSize', 3.5);
    plot(years, L.Cum_dGDP, '-.', 'Color', [0.17 0.63 0.17], 'LineWidth', 1.8);
    plot(years, L.Booked_GDP_2pct, '-', 'Color', [0.00 0.43 0.17], 'LineWidth', 2.3);
    plot(years, L.Booked_GDP_8pct, '--', 'Color', [0.25 0.67 0.36], 'LineWidth', 1.6);
    xline(years(idx_y5), '--', 'Color', [0.4 0.4 0.4]);

    title(sprintf('%s: Economy-Wide GDP Prize', reg), 'FontSize', 10, 'FontWeight', 'bold');
    xlabel('Transition Years'); ylabel('NZD ($B, Real)'); grid on; box on;
    text(years(idx_y5)+2, 0.65*max(L.Booked_GDP_2pct), ...
        sprintf('Yr 5 GDP Prize:\nCash: $%.2fB\nBooked (2%%): $%.2fB\nBooked (8%%): $%.2fB', ...
        L.Cum_dGDP(idx_y5), L.Booked_GDP_2pct(idx_y5), L.Booked_GDP_8pct(idx_y5)), ...
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

M_fisc = zeros(4, 5);
M_gdp  = zeros(4, 4);
for r = 1:4
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
b1(1).FaceColor = [0.84 0.15 0.16];
b1(2).FaceColor = [0.60 0.80 0.60];
b1(3).FaceColor = [0.12 0.47 0.71];
b1(4).FaceColor = [0.25 0.67 0.36];
b1(5).FaceColor = [0.00 0.43 0.17];
ylabel('NZD (Billions, Real 2025$)');
title('A. Year 5 Fiscal Audit by Region: Cash vs. Booked Return');
legend({'Cum Outlay', 'Cash Fiscal Return', 'Booked Cost Avoidance Alone (2%)', ...
    'Booked Total Fiscal (8% Sens.)', 'Booked Total Fiscal (2% Central)'}, 'Location', 'northwest', 'FontSize', 8.2);
grid on;

ax_b2 = subplot(1, 2, 2);
b2 = bar(categorical(regions, regions), M_gdp, 'grouped');
b2(1).FaceColor = [0.84 0.15 0.16];
b2(2).FaceColor = [0.60 0.80 0.60];
b2(3).FaceColor = [0.25 0.67 0.36];
b2(4).FaceColor = [0.00 0.43 0.17];
ylabel('NZD (Billions, Real 2025$)');
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

%% ========================================================================
%  HELPER 5: CONSOLE AUDIT SUMMARY TABLE
%  ========================================================================
function print_regional_audit_summary(Out, regions)
idx_y5 = find(Out.years == 5, 1);
if isempty(idx_y5), idx_y5 = 2; end

fprintf('\n========================================================================================================\n');
fprintf(' YEAR %d PARLIAMENTARY AUDIT: 4-REGION ACTUARIAL CONTINUATION VALUATION (NZD BILLIONS, REAL 2025$)\n', Out.years(idx_y5));
fprintf('========================================================================================================\n');
fprintf('%-10s | %8s | %9s | %15s | %17s | %17s | %15s\n', ...
    'Region', 'Outlay', 'Cash Fisc', 'Booked Sav (2%)', 'Booked Fisc (2%)', 'Booked Fisc (8%)', 'Booked GDP (2%)');
fprintf('--------------------------------------------------------------------------------------------------------\n');
for r = 1:length(regions)
    reg = regions{r};
    L   = Out.Reg.(reg);
    fprintf('%-10s | %8.2f | %9.2f | %15.2f | %17.2f | %17.2f | %15.2f\n', ...
        reg, L.Cum_Inv(idx_y5), L.Cum_TotFisc(idx_y5), L.Booked_Sav_2pct(idx_y5), ...
        L.Booked_Fisc_2pct(idx_y5), L.Booked_Fisc_8pct(idx_y5), L.Booked_GDP_2pct(idx_y5));
end
fprintf('--------------------------------------------------------------------------------------------------------\n');
fprintf('%-10s | %8.2f | %9.2f | %15.2f | %17.2f | %17.2f | %15.2f\n', ...
    'National', Out.Cum_Inv(idx_y5), Out.Cum_TotFisc(idx_y5), Out.Booked_Sav_2pct(idx_y5), ...
    Out.Booked_Fisc_2pct(idx_y5), Out.Booked_Fisc_8pct(idx_y5), Out.Booked_GDP_2pct(idx_y5));
fprintf('========================================================================================================\n\n');
end

%% ========================================================================
%  HELPER 6: SPATIAL ALLOCATION & STANDALONE FALLBACK CALIBRATION
%  ========================================================================
function Out_Cash = build_default_4region_cash_flows(regions, Calibration_Anchor)
if nargin < 2 || isempty(Calibration_Anchor), Calibration_Anchor = 'Dunedin_22'; end
years = 0:5:60;

% Under 'MetroSqueeze_GUiNZ' (~36.6% metro stunted vs ~22% Dunedin_22), acute h1-h2
% remediation savings and adult human-capital wave scale up in Auckland & Large
is_guin_squeeze = contains(lower(Calibration_Anchor), 'guin') || contains(lower(Calibration_Anchor), 'metro');
sav_mult = 1.0 + 0.28 * is_guin_squeeze; % +28% larger national avoided acute/rental burden
gdp_mult = 1.0 + 0.12 * is_guin_squeeze; % +12% larger human-capital cohort wave (Engine B)

annual_inv = zeros(size(years));
annual_inv(2:end) = 3.6 + 0.3 * (1 - exp(-0.06 * years(2:end)));

annual_sav = zeros(size(years));
annual_gdp = zeros(size(years));
for idx = 2:length(years)
    y = years(idx);
    if y < 20
        annual_sav(idx) = sav_mult * 0.9 * (y / 20.0);
    else
        annual_sav(idx) = sav_mult * (0.9 + 6.8 * (1 - exp(-0.08 * (y - 15))));
    end
    eng_A = 14.5 * (1 - exp(-0.11 * y));
    eng_B = gdp_mult * (y >= 15) * (28.0 / (1 + exp(-0.14 * (y - 32))));
    annual_gdp(idx) = eng_A + eng_B;
end

Out_Cash.years          = years;
Out_Cash.Annual_Inv     = annual_inv;
Out_Cash.Annual_Savings = annual_sav;
Out_Cash.Annual_dGDP    = annual_gdp;
Out_Cash.Annual_dTax    = 0.288 * annual_gdp;
Out_Cash.Annual_TotFisc = annual_sav + Out_Cash.Annual_dTax;
Out_Cash.Cum_Inv        = cumtrapz(years, Out_Cash.Annual_Inv);
Out_Cash.Cum_Savings    = cumtrapz(years, Out_Cash.Annual_Savings);
Out_Cash.Cum_dGDP       = cumtrapz(years, Out_Cash.Annual_dGDP);
Out_Cash.Cum_TotFisc    = Out_Cash.Cum_Savings + cumtrapz(years, Out_Cash.Annual_dTax);

Out_Cash = split_national_into_4regions(Out_Cash, regions, Calibration_Anchor);
end

function Out_Cash = split_national_into_4regions(Out_Cash, regions, Calibration_Anchor)
if nargin < 3 || isempty(Calibration_Anchor), Calibration_Anchor = 'Dunedin_22'; end
years = Out_Cash.years;
is_guin_squeeze = contains(lower(Calibration_Anchor), 'guin') || contains(lower(Calibration_Anchor), 'metro');

w_inv = [0.154, 0.235, 0.259, 0.352];
if is_guin_squeeze
    % 'MetroSqueeze_GUiNZ' (~36.6% metro stunted share concentrated in high-Q Auckland & Large)
    w_sav = [0.115, 0.195, 0.275, 0.415];
    w_gdp = [0.120, 0.195, 0.275, 0.410];
else
    % 'Dunedin_22' (~17.9%-22.0% baseline stunted share)
    w_sav = [0.143, 0.225, 0.260, 0.372];
    w_gdp = [0.130, 0.207, 0.2695, 0.3935];
end

for r = 1:length(regions)
    reg = regions{r};
    Out_Cash.Reg.(reg).Annual_Inv     = w_inv(r) * Out_Cash.Annual_Inv;
    Out_Cash.Reg.(reg).Annual_Savings = w_sav(r) * Out_Cash.Annual_Savings;
    Out_Cash.Reg.(reg).Annual_dGDP    = w_gdp(r) * Out_Cash.Annual_dGDP;
    Out_Cash.Reg.(reg).Annual_dTax    = 0.288    * Out_Cash.Reg.(reg).Annual_dGDP;
    Out_Cash.Reg.(reg).Annual_TotFisc = Out_Cash.Reg.(reg).Annual_Savings + Out_Cash.Reg.(reg).Annual_dTax;

    Out_Cash.Reg.(reg).Cum_Inv        = cumtrapz(years, Out_Cash.Reg.(reg).Annual_Inv);
    Out_Cash.Reg.(reg).Cum_Savings    = cumtrapz(years, Out_Cash.Reg.(reg).Annual_Savings);
    Out_Cash.Reg.(reg).Cum_dGDP       = cumtrapz(years, Out_Cash.Reg.(reg).Annual_dGDP);
    Out_Cash.Reg.(reg).Cum_TotFisc    = Out_Cash.Reg.(reg).Cum_Savings + cumtrapz(years, Out_Cash.Reg.(reg).Annual_dTax);
end
end

function val = get_param_or_default(S, fname, default_val)
if isstruct(S) && isfield(S, fname) && ~isempty(S.(fname))
    val = S.(fname);
else
    val = default_val;
end
end
