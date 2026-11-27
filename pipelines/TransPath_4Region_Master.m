%% 60-YEAR NON-LINEAR TRANSITION PATH & DYNAMIC PTYPEWEIGHTS (MULTIPHASE: SS0 -> SS1 -> SS2+)
% File: pipelines/TransPath_4Region_Master.m
% Pipeline orchestration & rendering script delegating transition trajectory math to
% Compute_TransitionPath_4Region.m and rendering Figures 1, 2, and 3.
% Automatically adapts to the active number of reform phases in WelfareResults / Phases:
%   - If 1 Reform Phase (SS0 -> SS1): Reproduces the exact 2-phase Daruich, Kiyotaki, and
%     Brain-Drain / Social Cohesion trajectories.
%   - If >= 2 Reform Phases (SS0 -> SS1 -> SS2+): Incorporates the Phase-2 (2050 Debt-Sinking
%     & Tax-Relief Dividend) transition leg starting at Year T_phase2_yr (default: Year 25),
%     and compares Pre-Announced Full Credibility (lambda_cred = 1) vs Unannounced MIT Shock
%     (lambda_cred = 0 prior to T_phase2_yr).

wb_opts = struct();
if exist('Regions', 'var') && ~isempty(Regions), wb_opts.Regions = Regions; end
if ~exist('Params', 'var'), Params = struct(); end
[Params, Regions] = Ensure_Workbench_Initialized(Params, wb_opts);

tp_opts = struct('Regions', {Regions});
if exist('Phases', 'var'),                   tp_opts.Phases                   = Phases;                   end
if exist('StateMetrics_Trans', 'var'),       tp_opts.StateMetrics_Trans       = StateMetrics_Trans;       end
if exist('T_phase2_yr', 'var'),              tp_opts.T_phase2_yr              = T_phase2_yr;              end
if exist('Phase2_Announcement_Mode', 'var'), tp_opts.Phase2_Announcement_Mode = Phase2_Announcement_Mode; end
if exist('Params_SS1', 'var') && isstruct(Params_SS1), tp_opts.Params_SS1 = Params_SS1; end
if exist('Params_SS2', 'var') && isstruct(Params_SS2), tp_opts.Params_SS2 = Params_SS2; end

if exist('WelfareResults', 'var'), wr_in = WelfareResults; else, wr_in = struct(); end
if exist('T1', 'var'),             t1_in = T1;             else, t1_in = [];       end

%% 1. COMPUTE PURE 60-YEAR TRANSITION TRAJECTORIES & TABLES
TransOut = Compute_TransitionPath_4Region(Params, wr_in, t1_in, tp_opts);

% Unpack canonical workspace variables for downstream plotters & checkpoint exports:
dt                       = TransOut.dt;
T_years                  = TransOut.T_years;
T_trans                  = TransOut.T_trans;
Trans_Years              = TransOut.Trans_Years;
Years_grid               = TransOut.Years_grid;
N_reg                    = numel(Regions);
has_SS2                  = TransOut.has_SS2;
ContingencySpec_Trans    = TransOut.ContingencySpec_Trans;
GateEval_Trans           = TransOut.GateEval_Trans;
T_phase2_yr              = TransOut.T_phase2_yr;
Phase2_Announcement_Mode = TransOut.Phase2_Announcement_Mode;
s_HH_path                = TransOut.s_HH_path;
T1_SS1                   = TransOut.T1_SS1;
T1_SS2                   = TransOut.T1_SS2;
Cohort_Years             = TransOut.Cohort_Years;
CE_Cohort                = TransOut.CE_Cohort;
CE_Cohort_MIT            = TransOut.CE_Cohort_MIT;
Q_path                   = TransOut.Q_path;
w_path                   = TransOut.w_path;
r_path                   = TransOut.r_path;
PricePath                = TransOut.PricePath;
Emig_Rate_Path           = TransOut.Emig_Rate_Path;
Emig_path                = TransOut.Emig_path;
Nat_Emig_path            = TransOut.Nat_Emig_path;
Cohesion_Index           = TransOut.Cohesion_Index;
Cohesion_St              = TransOut.Cohesion_St;
T_BrainDrain_Path        = TransOut.T_BrainDrain_Path;
T_CohortWelfare          = TransOut.T_CohortWelfare;
T_PopShares              = TransOut.T_PopShares;
T_NDC_Path               = TransOut.T_NDC_Path;
Pi_trade_path            = TransOut.Pi_trade_path;
E_NDC_cap_path           = TransOut.E_NDC_cap_path;
E_net_dom_path           = TransOut.E_net_dom_path;
S_pine_path              = TransOut.S_pine_path;
S_native_path            = TransOut.S_native_path;
r_bond_path              = TransOut.r_bond_path;

%% 2. PLOT TRANSITION FIGURES (FIGURES 1, 2, AND 3)
cols = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13; 0.49 0.18 0.56];

% --- FIGURE 1: DARUICH COHORT WELFARE TRAJECTORY ---
fig1 = figure('Name', 'Fig1_Daruich_Cohort_Welfare_4Region', 'Color', 'w', 'Position', [80, 80, 920, 540]);
hold on;
h_lines = gobjects(N_reg, 1);
for r_idx = 1:N_reg
    c_rgb = cols(mod(r_idx - 1, size(cols, 1)) + 1, :);
    h_lines(r_idx) = plot(Cohort_Years, CE_Cohort(:, r_idx), '-o', ...
        'LineWidth', 2.2, 'Color', c_rgb, 'MarkerSize', 5);
    if has_SS2 && ~strcmpi(Phase2_Announcement_Mode, 'Unannounced_MIT')
        % Overlay dashed MIT (unannounced) path to show the Phase-2 Announcement Credibility Wedge
        plot(Cohort_Years, CE_Cohort_MIT(:, r_idx), '--', ...
            'LineWidth', 1.3, 'Color', c_rgb, 'HandleVisibility', 'off');
    end
end
xline(0,  '--k', 'Reform Year 0 (SS1)', 'LineWidth', 1.2, 'HandleVisibility', 'off');
xline(20, ':r',  'Year 20 (First-2000-Days Cohort Enters Workforce)', 'LineWidth', 1.4, 'HandleVisibility', 'off');
if has_SS2
    xline(T_phase2_yr, '-.', 'Color', [0.00, 0.55, 0.25], ...
        'Label', sprintf('Year %d (SS2: 2050 Debt-Sinking & Tax-Relief Dividend)', T_phase2_yr), ...
        'LineWidth', 1.6, 'FontWeight', 'bold', 'HandleVisibility', 'off');
    title(sprintf('Multiphase 4-Region Cohort Welfare Transition Path: SS0 \rightarrow SS1 \rightarrow SS2 (dt = %d yr)', dt));
    h_ann = plot(NaN, NaN, '-ok', 'LineWidth', 1.8, 'MarkerSize', 5);
    h_mit = plot(NaN, NaN, '--k', 'LineWidth', 1.3);
    legend([h_lines; h_ann; h_mit], [Regions(:)', {'Pre-Announced SS2 (\lambda_{cred}=1)', 'Unannounced MIT Shock (\lambda_{cred}=0)'}], 'Location', 'northwest');
else
    title(sprintf('4-Region Cohort Welfare Transition Path (dt = %d yr)', dt));
    legend(h_lines, Regions, 'Location', 'northwest');
end
grid on;
xlabel('Cohort Birth/Entry Year Relative to Reform');
ylabel('Lifetime Consumption Equivalent Welfare (CE %)');

% --- FIGURE 2: KIYOTAKI HOUSING & REGIONAL POPULATION SHARES ---
fig2 = figure('Name', 'Fig2_Kiyotaki_Housing_Estates_4Region', 'Color', 'w', 'Position', [120, 120, 980, 480]);
subplot(1, 2, 1); hold on;
for r_idx = 1:N_reg
    c_rgb = cols(mod(r_idx - 1, size(cols, 1)) + 1, :);
    plot(Trans_Years, Q_path(:, r_idx), '-s', 'LineWidth', 2.0, 'Color', c_rgb, 'MarkerSize', 4);
end
if has_SS2
    xline(T_phase2_yr, '-.', 'Color', [0.00, 0.55, 0.25], 'Label', 'SS2 Infra Dividend', 'LineWidth', 1.3, 'HandleVisibility', 'off');
end
grid on; xlabel('Years Post-Reform'); ylabel('Regional House Price Index (Q_k)');
title('Regional Housing Price Cooling'); legend(Regions, 'Location', 'northeast');

subplot(1, 2, 2); hold on;
for r_idx = 1:N_reg
    c_rgb = cols(mod(r_idx - 1, size(cols, 1)) + 1, :);
    plot(Trans_Years, 100 * s_HH_path(:, r_idx), '-^', 'LineWidth', 2.0, 'Color', c_rgb, 'MarkerSize', 4);
end
if has_SS2
    xline(T_phase2_yr, '-.', 'Color', [0.00, 0.55, 0.25], 'Label', 'SS2 Retention Lift', 'LineWidth', 1.3, 'HandleVisibility', 'off');
end
grid on; xlabel('Years Post-Reform'); ylabel('Share of National Households (%)');
title('Endogenous 4-Region Population Shares'); legend(Regions, 'Location', 'best');

% --- FIGURE 3: BRAIN-DRAIN CLOSURE & SOCIAL COHESION ---
fig3 = figure('Name', 'Fig3_BrainDrain_Cohesion_4Region', 'Color', 'w', 'Position', [160, 160, 980, 480]);
subplot(1, 2, 1); hold on;
for r_idx = 1:N_reg
    c_rgb = cols(mod(r_idx - 1, size(cols, 1)) + 1, :);
    plot(Trans_Years, 100 * Emig_Rate_Path(:, r_idx), '-d', 'LineWidth', 2.0, 'Color', c_rgb, 'MarkerSize', 4);
end
if has_SS2
    xline(T_phase2_yr, '-.', 'Color', [0.00, 0.55, 0.25], 'Label', 'SS2 PAYE Relief', 'LineWidth', 1.3, 'HandleVisibility', 'off');
end
grid on; xlabel('Years Post-Reform'); ylabel('Annual Youth Emigration Rate (%)');
title('Age 20-35 Skilled Brain-Drain Closure'); legend(Regions, 'Location', 'northeast');

subplot(1, 2, 2);
plot(Trans_Years, Cohesion_Index, '-o', 'LineWidth', 2.4, 'Color', [0.15, 0.50, 0.25], 'MarkerSize', 5);
if has_SS2
    xline(T_phase2_yr, '-.', 'Color', [0.00, 0.55, 0.25], 'Label', 'SS2 Dividend', 'LineWidth', 1.3, 'HandleVisibility', 'off');
end
grid on; xlabel('Years Post-Reform'); ylabel('Social Cohesion Index (Base = 100)');
title('Macro Social Cohesion Recovery (S_t)');

%% 3. EXPORT FIGURES 1, 2, AND 3 (HONORING Export_Tables_Figures CONTROLLER)
do_export_tp = ~exist('Export_Tables_Figures', 'var') || logical(Export_Tables_Figures);
if do_export_tp
    explicit_out = '';
    if exist('OutputDir', 'var') && ~isempty(OutputDir), explicit_out = OutputDir; end
    OutputDir = Resolve_IGW_OutputDir(explicit_out, Params.Profile_ID);
    for fh = [fig1, fig2, fig3]
        if isgraphics(fh)
            out_png = fullfile(OutputDir, [get(fh, 'Name'), '.png']);
            exportgraphics(fh, out_png, 'Resolution', 300, 'BackgroundColor', 'white');
            fprintf('  -> Auto-saved: %s\n', out_png);
        end
    end
end
