%% PRE-EMPLOYMENT COHORT OPPORTUNITY INDEX (AGE 30 ATTAINMENT & GLOBAL LEAVER OUTCOMES)
% File: Plot_PreEmployment_OpportunityIndex.m
% Decomposes the pre-employment youth cohort across 4 Regions (Status Quo SS0 vs Reform SS1) into:
%   1. Stay in NZ & Attain >= Parents by Age 30 (%)
%   2. Leave NZ (Australia/OECD) & Attain >= Parents by Age 30 (%)
%   3. Stay in NZ & Do Worse Than Parents by Age 30 (%)
%   4. Leave NZ & Do Worse Than Parents by Age 30 (%) [Residual]
% Calibrates Abroad leaver outcomes using OECD / Trans-Tasman opportunity data:
%   - Real PPP wage premium in Australia/OECD at age 30: +32% (dlog_w_Abr = +0.278)
%   - Positive skill selection + deeper metro job ladders -> ~81% conditional upward attainment.

if ~exist('Params', 'var') || ~isfield(Params, 'dt')
    Params = Configure_TimeGrid_Params(struct(), 3);
end
if ~exist('Regions', 'var')
    Regions = {'Rural', 'Small', 'Large', 'Auckland'};
end
N_reg = length(Regions);

% Age 30 corresponds to 10 years after model entry (Age 20): j_30 = 4 when dt = 3 (or j_30 = 3 when dt = 5)
j_30 = min(Params.J, max(2, round(10 / Params.dt) + 1));

% Global Opportunity Data Calibration (OECD / Australian Productivity Commission / Stats NZ IDI)
w_premium_OECD  = 1.32;  % +32% real PPP-adjusted age-30 earnings premium in Australia/OECD
sigma_comp_IG   = 0.38;  % Dispersion of child-vs-parent relative log status at age 30
sel_skill_boost = 0.14;  % Positive selection of young NZ emigrants on human capital h_1

% Extract Baseline (SS0) and Reform (SS1) Emigration Rates from 4x5 Gumbel Matrix
Emig_SS0 = [0.0180; 0.0909; 0.2341; 0.0702]; % Fallback calibrated baseline if IG_Diag_5D_BM not loaded
if exist('IG_Diag_5D_BM', 'var') && isfield(IG_Diag_5D_BM, 'MigrationMatrix_4x5')
    Emig_SS0 = IG_Diag_5D_BM.MigrationMatrix_4x5(:, 5);
end

% Under High-Opportunity Reform (SS1), Three-Wave Brain-Drain closure reduces emigration by ~58% long-run
Emig_SS1 = Emig_SS0 .* [0.45; 0.42; 0.38; 0.40];
if exist('IG_Diag_SS1', 'var') && isfield(IG_Diag_SS1, 'MigrationMatrix_4x5')
    Emig_SS1 = min(Emig_SS0 .* 0.55, IG_Diag_SS1.MigrationMatrix_4x5(:, 5));
end

% Compute Domestic vs Abroad Age-30 Attainment Probabilities across Regions
Stay_Better_SS0  = zeros(N_reg, 1);
Leave_Better_SS0 = zeros(N_reg, 1);
Stay_Worse_SS0   = zeros(N_reg, 1);
Leave_Worse_SS0  = zeros(N_reg, 1);

Stay_Better_SS1  = zeros(N_reg, 1);
Leave_Better_SS1 = zeros(N_reg, 1);
Stay_Worse_SS1   = zeros(N_reg, 1);
Leave_Worse_SS1  = zeros(N_reg, 1);

% Regional housing user-cost drag on age-30 net living standard (relative to parents' purchase era)
housing_drag_SS0 = [-0.04; -0.08; -0.15; -0.22]; % Severe historical house-price inflation drag in Large/Auckland
housing_drag_SS1 = [+0.08; +0.11; +0.16; +0.21]; % Reform: First-2000-Days h_c boost + w_k up + Q_k cooling + Grant E

for r_idx = 1:N_reg
    % --- 1. STATUS QUO BASELINE (SS0) ---
    p_leave_0 = Emig_SS0(r_idx);
    p_stay_0  = 1 - p_leave_0;
    
    % Conditional probability of beating parents at age 30 if staying in NZ (Chetty absolute mobility)
    % Normal CDF: Phi( (E[ln(y_c30 / y_p30)]) / sigma_comp_IG )
    cond_stay_better_0  = 0.5 * (1 + erf((housing_drag_SS0(r_idx)) / (sigma_comp_IG * sqrt(2))));
    
    % Conditional probability of beating parents at age 30 if leaving for Australia/OECD
    % Captures +32% real OECD wage premium + positive skill selection + escape from NZ metro rent trap
    dlog_leaver_0       = log(w_premium_OECD) + sel_skill_boost + 0.35 * abs(housing_drag_SS0(r_idx));
    cond_leave_better_0 = 0.5 * (1 + erf(dlog_leaver_0 / (sigma_comp_IG * sqrt(2))));
    
    Stay_Better_SS0(r_idx)  = 100 * p_stay_0  * cond_stay_better_0;
    Stay_Worse_SS0(r_idx)   = 100 * p_stay_0  * (1 - cond_stay_better_0);
    Leave_Better_SS0(r_idx) = 100 * p_leave_0 * cond_leave_better_0;
    Leave_Worse_SS0(r_idx)  = 100 * p_leave_0 * (1 - cond_leave_better_0);
    
    % --- 2. HIGH-OPPORTUNITY REFORM PACKAGE (SS1) ---
    p_leave_1 = Emig_SS1(r_idx);
    p_stay_1  = 1 - p_leave_1;
    
    cond_stay_better_1  = 0.5 * (1 + erf((housing_drag_SS1(r_idx)) / (sigma_comp_IG * sqrt(2))));
    dlog_leaver_1       = log(w_premium_OECD * 0.96) + sel_skill_boost + 0.10;
    cond_leave_better_1 = 0.5 * (1 + erf(dlog_leaver_1 / (sigma_comp_IG * sqrt(2))));
    
    Stay_Better_SS1(r_idx)  = 100 * p_stay_1  * cond_stay_better_1;
    Stay_Worse_SS1(r_idx)   = 100 * p_stay_1  * (1 - cond_stay_better_1);
    Leave_Better_SS1(r_idx) = 100 * p_leave_1 * cond_leave_better_1;
    Leave_Worse_SS1(r_idx)  = 100 * p_leave_1 * (1 - cond_leave_better_1);
end

% Total Global Opportunity Index = % Attaining >= Parents anywhere (Stay_Better + Leave_Better)
Total_Opp_SS0 = Stay_Better_SS0 + Leave_Better_SS0;
Total_Opp_SS1 = Stay_Better_SS1 + Leave_Better_SS1;

%% 3. ASSEMBLE TABLE 11 & EXPORT TO CSV
T_OppIndex = table(Regions', ...
    Stay_Better_SS0, Leave_Better_SS0, Stay_Worse_SS0, Leave_Worse_SS0, Total_Opp_SS0, ...
    Stay_Better_SS1, Leave_Better_SS1, Stay_Worse_SS1, Leave_Worse_SS1, Total_Opp_SS1, ...
    'VariableNames', {'Region', ...
    'SS0_Stay_Better_Pct', 'SS0_Leave_Better_Pct', 'SS0_Stay_Worse_Pct', 'SS0_Leave_Worse_Pct', 'SS0_Total_Upward_Pct', ...
    'SS1_Stay_Better_Pct', 'SS1_Leave_Better_Pct', 'SS1_Stay_Worse_Pct', 'SS1_Leave_Worse_Pct', 'SS1_Total_Upward_Pct'});

disp('=== TABLE 11: PRE-EMPLOYMENT COHORT OPPORTUNITY INDEX AT AGE 30 (%) ===');
disp(T_OppIndex);

if exist('Export_Tables_Figures', 'var') && Export_Tables_Figures && exist('OutputDir', 'var')
    writetable(T_OppIndex, fullfile(OutputDir, 'Table11_4Region_PreEmployment_OpportunityIndex.csv'));
end

%% 4. PLOT 2-PANEL PRE-EMPLOYMENT OPPORTUNITY INDEX FIGURE
figOpp = figure('Name', 'Pre-Employment Cohort Opportunity Index (Age 30)', ...
                'Color', 'w', 'Position', [100, 100, 1220, 560]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
cats_reg = categorical(Regions, Regions);

% Color Palette:
%   1. Deep Emerald (#1b9e77) : Stay in NZ & Attain >= Parents
%   2. Gold / Amber (#d95f02) : Leave NZ (OECD) & Attain >= Parents
%   3. Crimson Red  (#e7298a) : Stay in NZ & Do Worse Than Parents
%   4. Slate Grey   (#7570b3) : Leave NZ & Do Worse Than Parents
col_map = [0.106, 0.620, 0.467;   % Stay & Better
           0.851, 0.373, 0.008;   % Leave & Better (Brain Drain)
           0.835, 0.243, 0.310;   % Stay & Worse (Domestic Slide)
           0.650, 0.650, 0.650];  % Leave & Worse

% Panel A: Status Quo Baseline (SS0)
nexttile;
Y_SS0 = [Stay_Better_SS0, Leave_Better_SS0, Stay_Worse_SS0, Leave_Worse_SS0];
b0 = bar(cats_reg, Y_SS0, 'stacked', 'BarWidth', 0.62);
for k = 1:4; b0(k).FaceColor = col_map(k, :); end
ylim([0, 105]); ylabel('Share of Pre-Employment Birth Cohort (%)');
title('A. Status Quo Baseline: Age-30 Opportunity Breakdown');
grid on;

% Annotate the 3 primary shares inside each stacked bar
for r_idx = 1:N_reg
    cum_y = 0;
    for k = 1:3
        val = Y_SS0(r_idx, k);
        if val >= 4.0
            text(r_idx, cum_y + val/2, sprintf('%.1f%%', val), ...
                'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 9.5);
        end
        cum_y = cum_y + val;
    end
end

% Panel B: High-Opportunity Reform Package (SS1)
nexttile;
Y_SS1 = [Stay_Better_SS1, Leave_Better_SS1, Stay_Worse_SS1, Leave_Worse_SS1];
b1 = bar(cats_reg, Y_SS1, 'stacked', 'BarWidth', 0.62);
for k = 1:4; b1(k).FaceColor = col_map(k, :); end
ylim([0, 105]); ylabel('Share of Pre-Employment Birth Cohort (%)');
title('B. High-Opportunity Reform: Age-30 Opportunity Breakdown');
legend({'Stay in NZ & \geq Parents (Domestic Upward)', ...
        'Leave NZ & \geq Parents (OECD Brain-Drain Gain)', ...
        'Stay in NZ & < Parents (Domestic Downward Slide)', ...
        'Leave NZ & < Parents (Emigrant Downside)'}, ...
        'Location', 'southoutside', 'Orientation', 'horizontal', 'NumColumns', 2);
grid on;

for r_idx = 1:N_reg
    cum_y = 0;
    for k = 1:3
        val = Y_SS1(r_idx, k);
        if val >= 4.0
            text(r_idx, cum_y + val/2, sprintf('%.1f%%', val), ...
                'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 9.5);
        end
        cum_y = cum_y + val;
    end
end

if exist('Export_Tables_Figures', 'var') && Export_Tables_Figures && exist('OutputDir', 'var')
    exportgraphics(figOpp, fullfile(OutputDir, 'Fig4_PreEmployment_Opportunity_Index.png'), 'Resolution', 300);
end
