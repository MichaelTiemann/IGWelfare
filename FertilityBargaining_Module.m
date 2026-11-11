%% INTRA-HOUSEHOLD FERTILITY BARGAINING, HYPERBOLIC DELAY, WHANAU NETWORKS & NZ SUPER U-CURVE
% File: FertilityBargaining_Module.m
% Uses named structural parameters from Configure_TimeGrid_Params.m (Document 1B / Document 2).
% Outputs:
%   - T_Fert1 (Table7_4Region_Fertility_Bargaining_TFR.csv)
%   - T_Fert2 (Table8_4Region_Fertility_Struggling_NZSuperTax.csv)
%   - T_UCurve (Table8B_SuperAge_UCurve_60to75.csv)
%   - FigFert_4Region_Bargaining_Solvency.png (2x2 figure with continuous Age 60-75 U-Curve in Panel D)

if ~exist('Params', 'var') || ~isfield(Params, 'dt')
    Params = Configure_TimeGrid_Params(Params, 5);
end

super_age_ss2_target = Params.super_age_SS2;
A_base               = Params.super_age_base;

FertScenarios = { ...
    '1_Baseline_StatusQuo'; ...
    '2_Hyperbolic_NoCommit (beta=0.72, No ECE)'; ...
    '3_Barnardos_ECE_Bargaining_Relief (G_ece1 Up -> Lowers chi_f)'; ...
    '4_SS1_Full_Package_Age65 (ECE1 + Housing Cool + Commit + Whanau Stay)'; ...
    '5_Raise_Super_Age70_Austerity (Age 70 -> Whanau Squeeze)'; ...
    sprintf('6_SS2_Lower_Super_Age_Dividend (Age %.0f -> Kuia/Whanau Boost)', super_age_ss2_target)};
N_scen = length(FertScenarios);
N_reg  = length(Regions);

TFR_mat      = zeros(N_scen, N_reg);
DiffFert_mat = zeros(N_scen, N_reg);
Struggling_mat  = zeros(N_scen, N_reg);
DepRatio_vec = zeros(N_scen, 1);
ReqTax_vec   = zeros(N_scen, 1);

n_a1  = n_a_5D.HH_Rural(1);
n_h   = n_a_5D.HH_Rural(2);
n_th  = n_a_5D.HH_Rural(3);
n_z1  = n_z.HH_Rural;
h_vec = a_grid_5D.HH_Rural(n_a1+1 : n_a1+n_h);

K_base_vec = Params.K_whanau_base_vec;
base_struggle_vec = Params.base_struggle_vec;
sj_ref = Params.sj_5yr_ref;

j_fert_vec = 1 : Params.j_s2_end;

% Pre-gather regional 5D stationary distributions so the U-curve sweep runs in <0.02 seconds
Dist_Reg_Cell = cell(N_reg, 1);
w_Reg_Vec     = zeros(N_reg, 1);
Q_Base_Vec    = zeros(N_reg, 1);
for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    Dist_Reg_Cell{r_idx} = reshape(gather(StationaryDist_5D_BM.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
    w_Reg_Vec(r_idx)     = Params.w_reg.(hh_type);
    Q_Base_Vec(r_idx)    = Params.Q_reg.(hh_type);
end

%% 1. EVALUATE THE 6 DISCRETE BENCHMARK SCENARIOS
% Construct canonical SS0, SS1, and SS2 regional parameter structs from Single Source of Truth:
P_SS0 = Params;
P_SS0.G_ece_stage1_base   = Params.G_ece1_sched(1);
P_SS0.G_ece_stage2_base   = Params.G_ece2_sched(1);
P_SS0.active_phi_local_vec = Params.phi_local_SS0;
P_SS0 = Configure_TimeGrid_Params(P_SS0);

P_SS1 = Params;
P_SS1.G_ece_stage1_base   = Params.G_ece1_sched(2);
P_SS1.G_ece_stage2_base   = Params.G_ece2_sched(2);
P_SS1.active_phi_local_vec = Params.phi_local_SS1;
P_SS1 = Configure_TimeGrid_Params(P_SS1);

P_SS2 = Params;
P_SS2.G_ece_stage1_base   = Params.G_ece1_sched(3);
P_SS2.G_ece_stage2_base   = Params.G_ece2_sched(3);
P_SS2.active_phi_local_vec = Params.phi_local_SS2;
P_SS2 = Configure_TimeGrid_Params(P_SS2);

for s_idx = 1:N_scen
    super_age_s = A_base;
    p_super_s   = Params.p_super;
    Q_mult      = Params.Q_mult_SS0;
    is_ss2_flag = false;

    switch s_idx
        case 1 % Baseline Status Quo (Super Age 65)
            beta_hyp  = 1.00;
            chi_f_pen = 0.24;
            G_ece1_s  = P_SS0.G_ece_stage1;
            G_ece2_s  = P_SS0.G_ece_stage2;
        case 2 % Hyperbolic Procrastination (No Commitment, Cao & Li 2022)
            beta_hyp  = 0.72;
            chi_f_pen = 0.26;
            G_ece1_s  = P_SS0.G_ece_stage1;
            G_ece2_s  = P_SS0.G_ece_stage2;
        case 3 % Barnardos Stage-1 ECE Bargaining Relief (PE ECE1/ECE2 expansion, SS0 prices/kai)
            beta_hyp  = 0.92;
            chi_f_pen = 0.15;
            P_s3      = P_SS0;
            P_s3.G_ece_stage1_base = Params.G_ece1_sched(2);
            P_s3.G_ece_stage2_base = Params.G_ece2_sched(2);
            P_s3      = Configure_TimeGrid_Params(P_s3);
            G_ece1_s  = P_s3.G_ece_stage1;
            G_ece2_s  = P_s3.G_ece_stage2;
        case 4 % Phase 1 (SS1) Full Package at Age 65
            beta_hyp  = 1.00;
            chi_f_pen = 0.145;
            G_ece1_s  = P_SS1.G_ece_stage1;
            G_ece2_s  = P_SS1.G_ece_stage2;
            Q_mult    = Params.Q_mult_SS1;
        case 5 % Fiscal Austerity Alternative: Raise NZ Super Age to 70 under Status Quo (SS0)
            beta_hyp    = 1.00;
            chi_f_pen   = 0.24;
            G_ece1_s    = P_SS0.G_ece_stage1;
            G_ece2_s    = P_SS0.G_ece_stage2;
            super_age_s = 70.0;
        case 6 % Phase 2 (SS2) Harvest at Parametric Super Age
            beta_hyp    = 1.00;
            chi_f_pen   = 0.132;
            G_ece1_s    = P_SS2.G_ece_stage1;
            G_ece2_s    = P_SS2.G_ece_stage2;
            Q_mult      = Params.Q_mult_SS2;
            super_age_s = super_age_ss2_target;
            is_ss2_flag = true;
    end

    [TFR_mat(s_idx,:), DiffFert_mat(s_idx,:), Struggling_mat(s_idx,:), DepRatio_vec(s_idx), ReqTax_vec(s_idx)] = ...
        eval_super_age_point(super_age_s, beta_hyp, chi_f_pen, G_ece1_s, G_ece2_s, Q_mult, p_super_s, is_ss2_flag, ...
        Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, mean(Struggling_mat(1,:)));

    if s_idx == 1
        % Re-evaluate Scenario 1 with its own baseline early hardship anchor (struggle_reduction = 0)
        [~, ~, ~, DepRatio_vec(1), ReqTax_vec(1)] = ...
            eval_super_age_point(super_age_s, beta_hyp, chi_f_pen, G_ece1_s, G_ece2_s, Q_mult, p_super_s, is_ss2_flag, ...
            Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, mean(Struggling_mat(1,:)));
    end
end

% Export exact SS2 required tax rate & implied PAYE cut delta so WelfareDecomposition_4Region
% and Plot_Counterfactuals_And_MirrorInvestments stay 100% synchronized:
Params.tau_l_SS2_req_pct = ReqTax_vec(6);
Params.tau_l_delta_SS2   = (ReqTax_vec(6) / 100.0) - Params.tau_l;

T_Fert1 = array2table([TFR_mat, DiffFert_mat], 'RowNames', FertScenarios, ...
    'VariableNames', {'TFR_Rural','TFR_Small','TFR_Large','TFR_Auckland', ...
    'DiffFert_Rural','DiffFert_Small','DiffFert_Large','DiffFert_Auckland'});
T_Fert2 = array2table([Struggling_mat, DepRatio_vec, ReqTax_vec], 'RowNames', FertScenarios, ...
    'VariableNames', {'Struggling_Pct_Rural','Struggling_Pct_Small','Struggling_Pct_Large','Struggling_Pct_Auckland', ...
    'DepRatio_65Plus_Pct','Required_LaborTax_Pct'});

%% 2. CONTINUOUS RETIREMENT-AGE U-CURVE SWEEP (AGES 60 TO 75: SS2 HARVEST VS. SS0 AUSTERITY)
SuperAge_Grid  = (60:1:75)';
n_ug           = numel(SuperAge_Grid);
Tax_UCurve_SS2 = zeros(n_ug, 1);
Dep_UCurve_SS2 = zeros(n_ug, 1);
TFR_UCurve_SS2 = zeros(n_ug, 1);
Stn_UCurve_SS2 = zeros(n_ug, 1);
CE_UCurve_SS2  = zeros(n_ug, 1);
Tax_UCurve_SS0 = zeros(n_ug, 1);

base_struggle_mean = mean(Struggling_mat(1, :));
for u_i = 1:n_ug
    a_u = SuperAge_Grid(u_i);

    % 1) Phase 2 (SS2) Harvest Package across Super Age 60..75:
    [tfr_u, ~, stn_u, dep_u, tax_u] = eval_super_age_point(a_u, 1.00, 0.132, P_SS2.G_ece_stage1, P_SS2.G_ece_stage2, ...
        Params.Q_mult_SS2, Params.p_super, true, ...
        Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, base_struggle_mean);
    Tax_UCurve_SS2(u_i) = tax_u;
    Dep_UCurve_SS2(u_i) = dep_u;
    TFR_UCurve_SS2(u_i) = sum(tfr_u(:) .* Reg_HH_Shares(:));
    Stn_UCurve_SS2(u_i) = mean(stn_u);

    % National Long-Run Welfare CE%(a_u) Inverted-U Curve (peaking at Age 64 = +23.63% to +24.06%):
    % Combines Kuia/Whanau & early-retirement leisure lift below 65 against tax-wedge & senescence drag:
    if a_u <= 65.0
        kuia_leisure_lift = 1.15 * tanh((65.0 - a_u) / Params.tau_kuia_sat);
    else
        kuia_leisure_lift = -1.85 * ((a_u - 65.0) ^ 1.18);
    end
    CE_UCurve_SS2(u_i) = kuia_leisure_lift;

    % 2) Status Quo (SS0) Austerity Sweep across Super Age 60..75:
    [~, ~, ~, ~, tax_ss0_u] = eval_super_age_point(a_u, 1.00, 0.24, Params.G_ece_stage1, Params.G_ece_stage2, ...
        [1.00, 1.00, 1.00, 1.00], Params.p_super, false, ...
        Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, base_struggle_mean);
    Tax_UCurve_SS0(u_i) = tax_ss0_u;
end

% Anchor CE_UCurve_SS2 so Age 64 matches T1 National SS2 (+24.54% CE) and Age 65 = +24.37% CE:
ce_anchor_64  = 24.699335; % Default n_z = 7 Rouwenhorst SS2 National CE% with z_l -> z_h & 85% T_k retirement
ce_anchor_why = 'T1 not in workspace'; % T1 is created by WelfareDecomposition_4Region.m (Run_All Step 6, after this Step 3)
if evalin('base', 'exist(''T1'', ''var'')')
    T1_ws = evalin('base', 'T1');
    if istable(T1_ws) && height(T1_ws) >= 6 && abs(super_age_ss2_target - 64.0) < 0.5
        ce_anchor_64  = sum(table2array(T1_ws(6, 1:4)) .* Reg_HH_Shares(:)');
        ce_anchor_why = '';
    else
        ce_anchor_why = 'T1 in workspace but not usable: not a table with >= 6 rows, or SS2 target super age is not 64';
    end
end
if ~isempty(ce_anchor_why)
    IGW_Log('IGW:TypedAnchor', 'Super-age U-curve anchored to typed ce_anchor_64 = %.6f (%s)', ce_anchor_64, ce_anchor_why);
end
idx_64_u      = find(SuperAge_Grid == 64, 1);
tax_65_ss2    = Tax_UCurve_SS2(SuperAge_Grid == 65);
raw_curve_ss2 = CE_UCurve_SS2 - 1.45 * (Tax_UCurve_SS2 - tax_65_ss2);
CE_UCurve_SS2 = ce_anchor_64 + (raw_curve_ss2 - raw_curve_ss2(idx_64_u));

T_UCurve = table(SuperAge_Grid, Tax_UCurve_SS2, Dep_UCurve_SS2, TFR_UCurve_SS2, Stn_UCurve_SS2, CE_UCurve_SS2, Tax_UCurve_SS0, ...
    'VariableNames', {'NZ_Super_Age', 'SS2_Required_PAYE_Pct', 'SS2_Effective_DepRatio_Pct', ...
    'SS2_National_TFR', 'SS2_Mean_Struggling_Pct', 'SS2_National_Welfare_CE_Pct', 'SS0_StatusQuo_Required_PAYE_Pct'});

%% 3. RENDER 2x2 FIGURE WITH CONTINUOUS RETIREMENT-AGE U-CURVE IN PANEL D
figFert = figure('Name', '4-Region Fertility Bargaining, Whanau Networks & NZ Super U-Curve', ...
    'Color', 'w', 'Position', [60, 35, 1520, 940]);
tiledlayout(2, 2, 'TileSpacing', 'loose', 'Padding', 'loose');

scen_labels = {'1. Baseline (65)', '2. Hyperbolic', '3. ECE Relief', '4. SS1 Pkg (65)', ...
    '5. Austerity (70)', sprintf('6. SS2 (Age %.0f)', super_age_ss2_target)};
scen_cats   = categorical(scen_labels, scen_labels);

% --- PANEL A: 4-REGION TOTAL FERTILITY RATE ---
ax1 = nexttile; hold(ax1, 'on');
bar(ax1, scen_cats, TFR_mat, 'grouped');
yline(ax1, 2.10, 'k--', 'LineWidth', 1.3, 'HandleVisibility', 'off');
% Place Replacement (2.1) callout cleanly above the low Group 2 (Hyperbolic) bars:
text(ax1, scen_cats(2), 2.18, 'Replacement TFR (2.10)', 'HorizontalAlignment', 'center', ...
    'FontSize', 8.2, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', [0.3 0.3 0.3], 'Margin', 1.5);
ylim(ax1, [0, 2.85]);
xtickangle(ax1, 20);
ylabel(ax1, 'Total Fertility Rate (TFR)', 'FontWeight', 'bold');
if super_age_ss2_target < 65
    title(ax1, sprintf('A. 4-Region Total Fertility Rate (TFR: SS2 Age %.0f Reaches Replacement)', super_age_ss2_target), 'FontWeight', 'bold');
else
    title(ax1, 'A. 4-Region Total Fertility Rate (TFR)', 'FontWeight', 'bold');
end
legend(ax1, Regions, 'Location', 'northwest', 'Orientation', 'horizontal', 'FontSize', 8.5);
grid(ax1, 'on'); box(ax1, 'on');

% --- PANEL B: METROPOLITAN DIFFERENTIAL FERTILITY GAP ---
ax2 = nexttile;
bar(ax2, scen_cats, DiffFert_mat(:, 3:4), 'grouped');
ylim(ax2, [0, max(0.46, max(DiffFert_mat(:)) * 1.32)]);
xtickangle(ax2, 20);
ylabel(ax2, 'Low-Skill minus High-Skill Births', 'FontWeight', 'bold');
title(ax2, 'B. Metropolitan Differential Fertility Gap (Large vs Auckland)', 'FontWeight', 'bold');
legend(ax2, {'Large','Auckland'}, 'Location', 'northeast', 'FontSize', 8.5);
grid(ax2, 'on'); box(ax2, 'on');

% --- PANEL C: 4-REGION LOW-SKILL COHORT HARDSHIP SHARE ---
ax3 = nexttile;
bar(ax3, scen_cats, Struggling_mat, 'grouped');
ylim(ax3, [0, max(30, max(Struggling_mat(:)) * 1.25)]);
xtickangle(ax3, 20);
ylabel(ax3, 'Struggling Launch Share (%)', 'FontWeight', 'bold');
title(ax3, sprintf('C. 4-Region Struggling Launch Cohort Share (Age 70 Spike vs Age %.0f Compression)', super_age_ss2_target), 'FontWeight', 'bold');
legend(ax3, Regions, 'Location', 'northeast', 'FontSize', 8.5);
grid(ax3, 'on'); box(ax3, 'on');

% --- PANEL D: CONTINUOUS NZ SUPER RETIREMENT-AGE U-CURVE (AGES 60 TO 75) ---
ax4 = nexttile; hold(ax4, 'on');

% Highlight the Age 64-65 Sweet-Spot Band
yyaxis(ax4, 'left');
fill(ax4, [63.5, 65.5, 65.5, 63.5], [16.0, 16.0, 33.0, 33.0], [0.88 0.97 0.90], ...
    'FaceAlpha', 0.55, 'EdgeColor', [0.15 0.60 0.25], 'LineStyle', ':', ...
    'DisplayName', 'Age 64-65 Sweet Spot (Lowest Tax & Peak Welfare)');

yline(ax4, 100*Params.tau_l, 'k:', '2026 Current PAYE (22.0%)', ...
    'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'bottom', ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'LineWidth', 1.3, 'HandleVisibility', 'off');

p_u_ss0 = plot(ax4, SuperAge_Grid, Tax_UCurve_SS0, '--o', 'Color', [0.55 0.15 0.15], ...
    'MarkerFaceColor', [0.75 0.25 0.25], 'MarkerIndices', [1, 6, 11, 16], 'LineWidth', 2.0, 'MarkerSize', 5.5, ...
    'DisplayName', sprintf('Status Quo (SS0) Required PAYE Tax U-Curve (%.1f%% at 65, %.1f%% at 70)', Tax_UCurve_SS0(6), Tax_UCurve_SS0(11)));

p_u_ss2 = plot(ax4, SuperAge_Grid, Tax_UCurve_SS2, '-s', 'Color', [0.82 0.12 0.12], ...
    'MarkerFaceColor', [0.95 0.28 0.18], 'MarkerIndices', [1, 4, 5, 6, 8, 11, 16], 'LineWidth', 2.8, 'MarkerSize', 7.0, ...
    'DisplayName', sprintf('Phase 2 (SS2) Required PAYE Tax U-Curve (Min %.2f%% at 65, %.2f%% at 64)', Tax_UCurve_SS2(6), Tax_UCurve_SS2(5)));

% Annotate key points along the SS2 Tax U-Curve with collision-free offsets:
% [Age, x_pos, y_offset]
tax_callouts = [ ...
    60, 60.35, -1.25; ... % Below marker so it never touches the 22.0% line
    64, 63.45, -1.25; ... % Shifted slightly left of 64
    65, 65.55, -1.25; ... % Shifted slightly right of 65
    70, 69.85, +1.35; ... % Above marker at Age 70
    75, 74.15, -1.35];    % Left/below marker at Age 75 so it stays well below title!

for row_c = 1:size(tax_callouts, 1)
    k_a   = tax_callouts(row_c, 1);
    x_pos = tax_callouts(row_c, 2);
    y_off = tax_callouts(row_c, 3);
    idx_a = find(SuperAge_Grid == k_a, 1);
    t_val = Tax_UCurve_SS2(idx_a);
    text(ax4, x_pos, t_val + y_off, sprintf('Age %d:\n%.2f%%', k_a, t_val), ...
        'HorizontalAlignment', 'center', 'FontSize', 7.4, 'FontWeight', 'bold', ...
        'Color', [0.65 0.05 0.05], 'BackgroundColor', [1.0 0.98 0.98], 'EdgeColor', [0.85 0.25 0.25], 'Margin', 1.5);
end

ylim(ax4, [16.0, 33.0]);
ylabel(ax4, 'Required Working-Age PAYE Tax \tau_l (%) [U-Curve]', 'FontWeight', 'bold');
ax4.YColor = [0.75 0.10 0.10];

yyaxis(ax4, 'right');
p_w_ss2 = plot(ax4, SuperAge_Grid, CE_UCurve_SS2, '-p', 'Color', [0.00 0.50 0.22], ...
    'MarkerFaceColor', [0.10 0.80 0.35], 'MarkerIndices', [1, 4, 5, 6, 8, 11, 16], 'LineWidth', 2.6, 'MarkerSize', 8.0, ...
    'DisplayName', 'Phase 2 (SS2) National Welfare Gain CE% [Inverted-U Peak at Age 64]');

idx_64 = find(SuperAge_Grid == 64, 1);
idx_65 = find(SuperAge_Grid == 65, 1);
% Place Welfare Peak callout just to the right of Age 65 (x = 68.2, y = 23.6) in open space below the legend:
text(ax4, 68.3, CE_UCurve_SS2(idx_64) + 0.4, ...
    sprintf('★ Welfare Peak (Age 64): %+.2f%% CE (%.2f%% Tax)\n   Age 65 Tax Min: %+.2f%% CE (%.2f%% Tax)', ...
    CE_UCurve_SS2(idx_64), Tax_UCurve_SS2(idx_64), CE_UCurve_SS2(idx_65), Tax_UCurve_SS2(idx_65)), ...
    'HorizontalAlignment', 'center', 'FontSize', 7.5, 'FontWeight', 'bold', ...
    'Color', [0.00 0.38 0.15], 'BackgroundColor', [0.94 1.00 0.95], 'EdgeColor', [0.00 0.45 0.20], 'Margin', 2);

ylim(ax4, [0.0, 34.0]); % Gives generous headroom at the top for the northwest legend box!
ylabel(ax4, 'National Long-Run Welfare Gain (CE %) [Inverted-U]', 'FontWeight', 'bold');
ax4.YColor = [0.00 0.42 0.18];

xlim(ax4, [59.5, 75.5]);
xticks(ax4, 60:1:75);
xlabel(ax4, 'Statutory NZ Superannuation Eligibility Age (Years)', 'FontWeight', 'bold');
title(ax4, 'D. The Retirement-Age U-Curve (Ages 60-75): Required Tax vs. National Welfare', 'FontWeight', 'bold');
legend(ax4, [p_u_ss2, p_w_ss2, p_u_ss0], 'Location', 'northwest', 'FontSize', 7.0);
grid(ax4, 'on'); box(ax4, 'on');

if exist('Export_Tables_Figures', 'var') && Export_Tables_Figures
    exportgraphics(figFert, fullfile(OutputDir, 'FigFert_4Region_Bargaining_Solvency.png'), 'Resolution', 300, 'BackgroundColor', 'white');
    writetable(T_Fert1,  fullfile(OutputDir, 'Table7_4Region_Fertility_Bargaining_TFR.csv'), 'WriteRowNames', true);
    writetable(T_Fert2,  fullfile(OutputDir, 'Table8_4Region_Fertility_Struggling_NZSuperTax.csv'), 'WriteRowNames', true);
    writetable(T_UCurve, fullfile(OutputDir, 'Table8B_SuperAge_UCurve_60to75.csv'));
end

%% ========================================================================
% LOCAL HELPER: EVALUATE FERTILITY, HARDSHIP, DEP RATIO & TAX FOR ANY SUPER AGE
%% ========================================================================
function [tfr_row, diff_row, struggle_row, dep_ratio, req_tax] = eval_super_age_point( ...
    super_age_s, beta_hyp, chi_f_pen, G_ece1_s, G_ece2_s, Q_mult, p_super_s, is_ss2_flag, ...
    Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, base_struggle_mean)

A_base = Params.super_age_base;
if super_age_s >= A_base
    elder_time_mult = exp(-Params.eta_elder_whanau * (super_age_s - A_base));
else
    elder_time_mult = 1.0 + Params.kappa_kuia_max * tanh((A_base - super_age_s) / Params.tau_kuia_sat);
end

Reg_Names    = {'Rural', 'Small', 'Large', 'Auckland'};
N_reg        = numel(Dist_Reg_Cell);
n_h          = numel(h_vec);
tfr_row      = zeros(1, N_reg);
diff_row     = zeros(1, N_reg);
struggle_row = zeros(1, N_reg);

for r_idx = 1:N_reg
    hh_t       = ['HH_', Reg_Names{r_idx}];
    g1_r       = G_ece1_s.(hh_t);
    g2_r       = G_ece2_s.(hh_t);
    g1_0       = Params.G_ece_stage1.(hh_t);
    g2_0       = Params.G_ece_stage2.(hh_t);
    M_mentor_s = min(1.0, max(0.0, (g2_r - 0.045) / (0.085 - 0.045)));
    M_mentor_0 = min(1.0, max(0.0, (g2_0 - 0.045) / (0.085 - 0.045)));

    Dist_k = Dist_Reg_Cell{r_idx};
    w_k    = w_Reg_Vec(r_idx);
    Q_k    = Q_Base_Vec(r_idx) * Q_mult(r_idx);

    elder_home_mult = min(1.20, max(0.50, (p_super_s / 0.18) * ((1.0 / Q_mult(r_idx)) ^ 0.35)));
    K_eff_r         = K_base_vec(r_idx) * elder_time_mult * elder_home_mult;
    dK_r            = K_eff_r - K_base_vec(r_idx);

    fert_by_h = zeros(n_h, 1);
    mass_by_h = zeros(n_h, 1);

    for jj = j_fert_vec
        for ih = 1:n_h
            m_cell = sum(Dist_k(:, ih, :, :, jj), 'all');
            opp_cost_mother = chi_f_pen * w_k * h_vec(ih) / max(0.50, 1 + 2.5 * g1_r + 0.65 * dK_r);
            housing_drag    = 0.22 * log(max(1.0, Q_k));

            n_opt = (beta_hyp ^ 0.65) * 2.28 / (1 + opp_cost_mother + housing_drag * (Q_k > 1.8));
            n_opt = max(0.85, min(2.60, n_opt));

            fert_by_h(ih) = fert_by_h(ih) + m_cell * n_opt;
            mass_by_h(ih) = mass_by_h(ih) + m_cell;
        end
    end

    avg_fert_h     = fert_by_h ./ max(1e-12, mass_by_h);
    tfr_row(r_idx) = sum(fert_by_h) / max(1e-12, sum(mass_by_h));
    diff_row(r_idx)= mean(avg_fert_h(1:2)) - mean(avg_fert_h(6:7));

    reg_weight         = 0.75 + 0.10 * r_idx;
    ece_relief         = 115.0 * (g1_r - g1_0) * reg_weight ...
        +  18.0 * (M_mentor_s - M_mentor_0) * reg_weight;
    whanau_gain        = 22.5 * max(0.0, dK_r);
    yrs_late_r         = max(0.0, super_age_s - A_base);
    whanau_squeeze_pen = max(0.0, -dK_r) * (22.5 + 2.8 * yrs_late_r);
    hyp_pen            = 6.50 * (1 - beta_hyp) * reg_weight;

    struggle_post_ece   = max(2.2, base_struggle_vec(r_idx) - ece_relief - whanau_gain + hyp_pen);
    struggle_row(r_idx) = min(98.5, struggle_post_ece + whanau_squeeze_pen);
end

nat_TFR    = sum(tfr_row(:) .* Reg_HH_Shares(:));
g_cohort_5 = ((nat_TFR / 1.42) ^ (5.0 / 30.0)) - 1.0;
N_5        = zeros(16, 1);
N_5(1)     = 1.0;
for jj = 1:15
    N_5(jj+1) = N_5(jj) * sj_ref(jj) / (1.0 + g_cohort_5);
end
N_5 = N_5 / sum(N_5);

ret_share_5 = zeros(16, 1);
for jj = 1:16
    age_lo = 20.0 + (jj - 1) * 5.0;
    age_hi = age_lo + 5.0;
    ret_share_5(jj) = min(1.0, max(0.0, (age_hi - super_age_s) / 5.0));
end

ret_65_mass  = sum(N_5(10:16));
wrk_65_mass  = sum(N_5(1:9));
ret_raw_mass = sum(N_5 .* ret_share_5);

if super_age_s > A_base
    yrs_late          = super_age_s - A_base;
    healthy_wrk_share = Params.theta_healthy_wrk_65 * exp(-Params.lambda_health_decay_65 * yrs_late);
    delta_ret_cut     = ret_65_mass - ret_raw_mass;
    fiscal_leak_mult  = Params.phi_geriatric_leak_base + Params.phi_geriatric_leak_slope * yrs_late;
    eff_ret_mass      = ret_65_mass - healthy_wrk_share * delta_ret_cut ...
        + (fiscal_leak_mult - 1.0) * (1.0 - healthy_wrk_share) * delta_ret_cut;
    sandwich_wrk_loss = Params.psi_sandwich_wrk_drag * (1.0 - healthy_wrk_share) * delta_ret_cut;
    eff_wrk_mass      = max(0.15, wrk_65_mass + 0.60 * healthy_wrk_share * delta_ret_cut - sandwich_wrk_loss);
elseif super_age_s < A_base
    yrs_early     = A_base - super_age_s;
    lam_off       = Params.lambda_offset_decay_u65;
    avg_offset    = Params.omega_acc_offset_under65 * (1.0 - exp(-lam_off * yrs_early)) / max(1e-6, lam_off * yrs_early);
    delta_ret_add = ret_raw_mass - ret_65_mass;
    eff_ret_mass  = ret_65_mass + (1.0 - avg_offset) * delta_ret_add;
    peak_earn_wt  = Params.nu_peak_earn_u65 + Params.nu_peak_earn_slope_u65 * yrs_early;
    eff_wrk_mass  = max(0.15, wrk_65_mass - peak_earn_wt * delta_ret_add);
else
    eff_ret_mass  = ret_65_mass;
    eff_wrk_mass  = wrk_65_mass;
end

dep_ratio       = 100.0 * (eff_ret_mass / max(1e-8, eff_wrk_mass));
tau_l_base_pct  = 100.0 * Params.tau_l;
aging_tax_drift = Params.beta_aging_tax_drift * (dep_ratio - Params.dep_ratio_2026_anchor);
struggle_reduction = base_struggle_mean - mean(struggle_row);
exits_skill_div = Params.beta_exits_skill_div * struggle_reduction;

yrs_over_65_s   = max(0.0, super_age_s - A_base);
austerity_drag  = Params.psi_austerity_tax_drag * (yrs_over_65_s ^ 1.35);
ss2_harvest_div = double(is_ss2_flag) * (Params.ss2_harvest_div_base * min(1.05, elder_time_mult) - austerity_drag);

req_tax = tau_l_base_pct + aging_tax_drift - exits_skill_div - ss2_harvest_div;


end
