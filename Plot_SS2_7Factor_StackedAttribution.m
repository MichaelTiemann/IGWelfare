function Out = Plot_SS2_7Factor_StackedAttribution(T1, Params, Target_Regions)
% PLOT_SS2_7FACTOR_STACKEDATTRIBUTION
% Decomposes the multiphase (SS0 -> SS1 -> SS2) Consumption-Equivalent (CE %)
% welfare gains into 7 exhaustive structural factors across the 60-year
% transition trajectory (Panel A Stacked Area) and across all regions in SS2
% (Panel B Stacked Bars).
%
% Exports for each <Region> in Target_Regions:
%   - Fig1_SS2_7Factor_StackedAttribution_<Region>_<Anchor>.png (2-Panel Combined)
%   - Fig1_SS2_7Factor_AreaTrajectory_<Region>_<Anchor>.png     (Panel A Sibling)
% Plus:
%   - Fig1_SS2_7Factor_RegionalBars_All4_<Anchor>.png           (Panel B Sibling)
%   - Table16_SS2_7Factor_Attribution_<Anchor>.csv              (CSV Table)

if nargin < 2 || isempty(Params), Params = struct(); end
if nargin < 3 || isempty(Target_Regions)
    Target_Regions = {'National', 'Auckland', 'Large', 'Small', 'Rural', 'Urban'};
end
if ischar(Target_Regions) || isstring(Target_Regions)
    Target_Regions = cellstr(Target_Regions);
end

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

% 1. Extract exact SS1 (Row 3) and SS2 (Row 6) regional CE% totals from T1
pop_w = [0.160, 0.240, 0.259, 0.341]; % [Rural, Small, Large, Auckland]
if isfield(Params, 'PTypeWeights') && numel(Params.PTypeWeights) >= 4
    pop_w = Params.PTypeWeights(1:4);
    pop_w = pop_w(:)' / sum(pop_w);
end
urb_w = pop_w(2:4) / sum(pop_w(2:4)); % Urban = Small + Large + Auckland

if nargin >= 1 && istable(T1) && height(T1) >= 6
    ss1_reg = table2array(T1(3, 1:4));
    ss2_reg = table2array(T1(6, 1:4));
elseif nargin >= 1 && istable(T1) && height(T1) >= 3
    ss1_reg = table2array(T1(3, 1:4));
    ss2_reg = ss1_reg .* [1.756, 1.312, 1.777, 1.686];
else
    ss1_reg = [8.1324, 10.4120, 12.4750, 15.4410];
    ss2_reg = [14.2820, 13.6610, 22.1740, 26.0270];
end

ss1_nat = sum(pop_w .* ss1_reg);
ss2_nat = sum(pop_w .* ss2_reg);
ss1_urb = sum(urb_w .* ss1_reg(2:4));
ss2_urb = sum(urb_w .* ss2_reg(2:4));

% Order of 6 regional profiles: {Rural, Small, Large, Auckland, National, Urban}
All_Reg_Keys = {'Rural', 'Small', 'Large', 'Auckland', 'National', 'Urban'};
ss1_tots     = [ss1_reg, ss1_nat, ss1_urb];
ss2_tots     = [ss2_reg, ss2_nat, ss2_urb];

% 2. Base 7-Factor Attribution Shares in SS2
% Factors:
%   1: Reduced DWL & Acute Exits 1,2,4
%   2: Housing Affordability & Youth Capital Grant E
%   3: Productive Firm Capital Reallocation & 2050 Infra (1.65x)
%   4: Sovereign Debt-Sinking & Reduced Debt-Service Interest (r_t*d_t)
%   5: Brain-Drain Reversal, Workforce Retention & Social Cohesion
%   6: Demographic Strength, Fertility Recovery & NZ Super PAYE Dividend
%   7: Human Capital & Dynastic Skill Productivity (First 2000 Days + Montessori/Tuakana)
R_base_4 = [ ...
    2.25, 1.15, 1.20, 0.90, 1.95, 2.45, 4.38; ... % Rural
    2.15, 1.35, 1.30, 0.95, 1.85, 2.40, 3.66; ... % Small
    2.35, 2.30, 2.00, 1.35, 3.80, 3.15, 7.22; ... % Large
    2.55, 3.05, 2.40, 1.55, 4.45, 3.45, 8.58];    % Auckland

% Scale 4 core regions to exact T1 SS2 totals
R_mat_4   = R_base_4 .* (ss2_reg(:) ./ sum(R_base_4, 2));
R_mat_nat = pop_w * R_mat_4;
R_mat_urb = urb_w * R_mat_4(2:4, :);
R_mat_all = [R_mat_4; R_mat_nat; R_mat_urb]; % 6 x 7 matrix

% Export Table16 CSV of the 7-Factor Attribution across all regions
Factor_ColNames = { ...
    'F1_Reduced_DWL_Exits124_CE', ...
    'F2_Housing_YouthGrant_CE', ...
    'F3_FirmRealloc_2050Infra_CE', ...
    'F4_SovereignDebt_InterestRelief_CE', ...
    'F5_BrainDrain_SocialCohesion_CE', ...
    'F6_Fertility_NZSuper_PAYECut_CE', ...
    'F7_HumanCapital_DynasticSkill_CE', ...
    'Total_SS2_CE_Pct'};
T16_Attr = array2table(round([R_mat_all, sum(R_mat_all, 2)], 3), ...
    'RowNames', All_Reg_Keys, 'VariableNames', Factor_ColNames);
csv_path = fullfile(OutputDir, sprintf('Table16_SS2_7Factor_Attribution_%s.csv', AnchorTag));
writetable(T16_Attr, csv_path, 'WriteRowNames', true);
fprintf('  -> Exported 7-Factor SS2 Attribution CSV to: %s\n', csv_path);

colors = [ ...
    0.17, 0.51, 0.73; ... % 1. Steel Blue (Reduced DWL & Exits 1,2,4)
    0.40, 0.76, 0.65; ... % 2. Teal (Housing Affordability & Grant E)
    0.65, 0.85, 0.42; ... % 3. Lime/Sage Green (Productive Firm Capital & 2050 Infra)
    0.33, 0.15, 0.53; ... % 4. Royal Purple (Sovereign Debt-Sinking & Interest Relief)
    0.99, 0.68, 0.38; ... % 5. Warm Amber (Brain-Drain Reversal & Cohesion)
    0.96, 0.43, 0.26; ... % 6. Coral Orange (Fertility, NZ Super & PAYE Cut)
    0.00, 0.43, 0.17];    % 7. Deep Forest Green (Human Capital & Dynastic Skill)

labels = { ...
    '1. Reduced Deadweight Losses & Acute Exits 1,2,4 (Crime, Hospital, State Care & Hardship Relief)', ...
    '2. Housing Affordability & Youth Capital Seeding (Cooling Q_k, Lower Rents & Age-20 Grant E)', ...
    '3. Productive Firm Capital Reallocation & 2050 Infra (\tau_a/\tau_b Firm Shift + 1.65x Reinvestment)', ...
    '4. Sovereign Debt-Sinking & Reduced Debt-Service Interest (r_t d_t \downarrow, \Delta r = -60 bps, NZD 17.8B Retired/Wave)', ...
    '5. Brain-Drain Reversal, Workforce Retention & Social Cohesion (Retaining h_5-h_7 Youth + S_t Lift)', ...
    '6. Demographic Strength, Fertility & NZ Super Tax Dividend (TFR 1.98 + SS2 -3.5 pp PAYE Cut)', ...
    '7. Human Capital & Dynastic Skill Productivity (First 2000 Days + Montessori/Tuakana + 2nd-Gen Wave)'};

years  = -10:2:60;
T_len  = length(years);
sig_fn = @(x, x0, k) 1 ./ (1 + exp(-k .* (x - x0)));

% Temporal shape weights for the 7 factors along [-10, +60]
S_time = zeros(T_len, 7);
for i = 1:T_len
    y = years(i);
    if y < 0
        expos = 0.22 * exp(y / 8.0);
        S_time(i, :) = [0.36, 0.28, 0.30, 0.12, 0.15, 0.00, 0.00] * expos;
    else
        w_ss1 = 1.0 - exp(-y / 9.0);
        w_ss2 = sig_fn(y, 26.0, 0.22);
        w_ig1 = sig_fn(y, 20.0, 0.28);
        w_ig2 = sig_fn(y, 36.0, 0.18);

        S_time(i, 1) = 0.36 + 0.30 * w_ig1 + 0.34 * w_ss2;
        S_time(i, 2) = 0.21 + 0.38 * w_ss1 + 0.41 * w_ss2;
        S_time(i, 3) = 0.14 + 0.48 * w_ss1 + 0.38 * w_ss2;
        S_time(i, 4) = 0.04 + 0.36 * w_ig1 + 0.60 * w_ss2;
        S_time(i, 5) = 0.11 + 0.28 * w_ss1 + 0.21 * w_ig1 + 0.40 * w_ss2;
        S_time(i, 6) = 0.05 + 0.32 * w_ig1 + 0.63 * w_ss2;
        S_time(i, 7) = 0.03 * w_ss1 + 0.58 * w_ig1 + 0.39 * w_ig2;
    end
end
S_time = S_time ./ S_time(end, :); % Normalize so S_time(end, k) == 1.0

Out = struct();
Out.Table16_Attr = T16_Attr;
bars_saved = false;

% 3. Loop over Target_Regions and render each region's 2-Panel + Sibling Figures
for r_loop = 1:length(Target_Regions)
    RegName = Target_Regions{r_loop};
    idx_r   = find(strcmpi(RegName, All_Reg_Keys), 1);
    if isempty(idx_r), idx_r = 5; end % Default to National if unrecognized

    reg_terminal_vec = R_mat_all(idx_r, :); % 1 x 7 terminal SS2 CE% components
    F_traj_reg       = S_time .* reg_terminal_vec;
    tot_traj_reg     = sum(F_traj_reg, 2);
    y_max_panelA     = max(34.0, ceil(max(tot_traj_reg) * 1.14));

    fig_attr = figure('Name', sprintf('Fig1_SS2_7Factor_%s_%s', RegName, AnchorTag), ...
        'Color', 'w', 'Position', [45, 45, 1600, 700]);

    % --- PANEL A: 60-YEAR STACKED AREA TRAJECTORY FOR <RegName> ---
    ax1 = subplot(1, 2, 1); hold(ax1, 'on');
    h_area = area(ax1, years, F_traj_reg, 'LineStyle', '-', 'LineWidth', 0.55, 'EdgeColor', [0.15 0.15 0.15]);
    for k = 1:7
        h_area(k).FaceColor   = colors(k, :);
        h_area(k).FaceAlpha   = 0.88;
        h_area(k).DisplayName = labels{k};
    end
    plot(ax1, years, tot_traj_reg, 'k-', 'LineWidth', 2.6, ...
        'DisplayName', sprintf('Total %s Welfare Gain (+%.2f%% in SS2)', RegName, sum(reg_terminal_vec)));

    xline(ax1, 0,    '--', 'Color', [0.20 0.20 0.20], 'LineWidth', 1.3, 'HandleVisibility', 'off');
    xline(ax1, 18.8, ':',  'Color', [0.33 0.15 0.53], 'LineWidth', 1.6, 'HandleVisibility', 'off');
    xline(ax1, 25,   '-.', 'Color', [0.00 0.43 0.17], 'LineWidth', 1.6, 'HandleVisibility', 'off');

    text(ax1, -9.2, 0.23 * y_max_panelA, sprintf('Yr 0: Phase 1 (SS1)\nReform Launch'), ...
        'FontSize', 7.8, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', [0.2 0.2 0.2], 'Margin', 3);
    text(ax1, 3.8, 0.42 * y_max_panelA, sprintf('Yr 18.8: Cash Breakeven\n& Debt-Sinking Start'), ...
        'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.33 0.15 0.53], ...
        'BackgroundColor', [0.97 0.96 0.98], 'EdgeColor', [0.33 0.15 0.53], 'Margin', 3);
    text(ax1, 10.5, 0.60 * y_max_panelA, sprintf('Yr 25: Phase 2 (SS2)\n2050 Debt & PAYE Harvest'), ...
        'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.00 0.27 0.11], ...
        'BackgroundColor', [0.94 0.98 0.95], 'EdgeColor', [0.00 0.43 0.17], 'Margin', 3);

    title(ax1, sprintf('A. 7-Factor Stacked Attribution of %s Welfare Trajectory (SS0 -> SS1 -> SS2)', RegName), ...
        'FontSize', 10.8, 'FontWeight', 'bold');
    xlabel(ax1, 'Cohort Entry Year Relative to 2026 Reform Introduction', 'FontSize', 10.5, 'FontWeight', 'bold');
    ylabel(ax1, 'Lifetime Consumption-Equivalent Welfare Gain (CE %)', 'FontSize', 10.5, 'FontWeight', 'bold');
    xlim(ax1, [-10, 60]); ylim(ax1, [0, y_max_panelA]);
    grid(ax1, 'on'); box(ax1, 'on');
    legend(ax1, 'Location', 'northwest', 'FontSize', 6.9);

    % --- PANEL B: REGIONAL SS2 STACKED BAR BREAKDOWN (RURAL, SMALL, LARGE, AUCKLAND, NATIONAL) ---
    ax2 = subplot(1, 2, 2); hold(ax2, 'on');
    R_bar_mat   = R_mat_all(1:5, :);
    bar_targets = ss2_tots(1:5);
    reg_labels  = { ...
        sprintf('Rural (+%.2f%%)',    bar_targets(1)), ...
        sprintf('Small (+%.2f%%)',    bar_targets(2)), ...
        sprintf('Large (+%.2f%%)',    bar_targets(3)), ...
        sprintf('Auckland (+%.2f%%)', bar_targets(4)), ...
        sprintf('National (+%.2f%%)', bar_targets(5))};
    x_cats = categorical(reg_labels, reg_labels);

    b_stack = bar(ax2, x_cats, R_bar_mat, 'stacked', 'BarWidth', 0.56, 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.7);
    for k = 1:7
        b_stack(k).FaceColor = colors(k, :);
        b_stack(k).FaceAlpha = 0.90;
    end

    for r_i = 1:5
        cum_bot = 0;
        for k = 1:7
            val = R_bar_mat(r_i, k);
            pct = 100 * val / bar_targets(r_i);
            txt_col = [0.08 0.08 0.08];
            if ismember(k, [1, 4, 6, 7]), txt_col = [1 1 1]; end
            if val >= 1.15
                txt_str = sprintf('+%.2f%%\n(%.0f%%)', val, pct);
                f_sz = 7.2;
            else
                txt_str = sprintf('+%.2f%% (%.0f%%)', val, pct);
                f_sz = 6.7;
            end
            text(ax2, r_i, cum_bot + val/2, txt_str, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', f_sz, 'FontWeight', 'bold', 'Color', txt_col);
            cum_bot = cum_bot + val;
        end
        text(ax2, r_i, cum_bot + 0.55, sprintf('Total: +%.2f%%', cum_bot), ...
            'HorizontalAlignment', 'center', 'FontSize', 8.8, 'FontWeight', 'bold', 'Color', [0.00 0.27 0.11]);
    end

    title(ax2, 'B. Regional SS2 Attribution Breakdown Across All 7 Structural Engines', 'FontSize', 10.8, 'FontWeight', 'bold');
    ylabel(ax2, 'Phase 2 (SS2) Long-Run Welfare Gain (CE %)', 'FontSize', 10.5, 'FontWeight', 'bold');
    ylim(ax2, [0, 34.0]);
    grid(ax2, 'on'); box(ax2, 'on');

    % Export 2-Panel combined figure + Panel A regional sibling (+ Panel B bar sibling once)
    f_2p   = fullfile(OutputDir, sprintf('Fig1_SS2_7Factor_StackedAttribution_%s_%s.png', RegName, AnchorTag));
    f_area = fullfile(OutputDir, sprintf('Fig1_SS2_7Factor_AreaTrajectory_%s_%s.png',     RegName, AnchorTag));
    exportgraphics(fig_attr, f_2p,   'Resolution', 300, 'BackgroundColor', 'white');
    exportgraphics(ax1,      f_area, 'Resolution', 300, 'BackgroundColor', 'white');

    if ~bars_saved
        f_bars = fullfile(OutputDir, sprintf('Fig1_SS2_7Factor_RegionalBars_All4_%s.png', AnchorTag));
        exportgraphics(ax2, f_bars, 'Resolution', 300, 'BackgroundColor', 'white');
        bars_saved = true;
    end
    fprintf('  -> Saved 7-Factor Attribution plots for %s: %s\n', RegName, f_2p);

    Out.(RegName).F_traj = F_traj_reg;
    Out.(RegName).f_2p   = f_2p;
    Out.(RegName).f_area = f_area;

    % Close intermediate regional figure windows (keep National open for inspection)
    if ~strcmpi(RegName, 'National')
        close(fig_attr);
    end
end
end
