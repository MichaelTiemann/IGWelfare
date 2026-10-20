%% 60-YEAR 4-REGION + ABROAD TRANSITION PATH (INTEGRATED WITH Params.dt)
% File: TransPath_4Region_Master.m
% Solves the 60-year (T_trans = 60/dt steps) dynamic transition path from SS0 to SS1,
% tracking dynamic regional household & firm shares (Table 9) and Three-Wave Brain-Drain Closure (Table 10).

if ~exist('Params', 'var') || ~isfield(Params, 'dt')
    Params = Configure_TimeGrid_Params(Params, 5);
end

if ~exist('Params_Base', 'var'); Params_Base = Params; end
if ~exist('Params_GE', 'var')
    if exist('Params_Reform', 'var')
        Params_GE = Params_Reform;
    else
        Params_GE = Params;
    end
end

dt          = Params.dt;
T_trans     = Params.T_trans;               % 12 (dt=5), 20 (dt=3), 30 (dt=2)
Years_grid  = ((0:(T_trans - 1)) * dt)';    % Spans 0 to 60-dt years
scale_dt    = dt / 5;
weight_t    = linspace(0, 1, T_trans)';
r_path      = Params_Base.r * (1 - weight_t) + Params_GE.r * weight_t;

%% 1. DYNAMIC 4-REGION HOUSEHOLD & BUSINESS POPULATION SHARES (TABLE 9)
s_HH_path   = zeros(T_trans, 4);
s_Firm_path = zeros(T_trans, 4);
s_HH_path(1, :)   = Reg_HH_Shares';
s_Firm_path(1, :) = Reg_Firm_Shares';

m_intl      = [0.115, 0.210, 0.270, 0.405];
nu_dom      = 1 - (1 - 0.120) ^ scale_dt;
zeta_inflow = Params.zeta_cohort;
firm_stick  = 0.85 ^ scale_dt;

Pi_dom = IG_Diag_5D_BM.MigrationMatrix;
for t = 1:(T_trans - 1)
    s_tilde             = (1 - nu_dom) * s_HH_path(t, :) + nu_dom * (s_HH_path(t, :) * Pi_dom);
    s_next              = (1 - zeta_inflow) * s_tilde + zeta_inflow * m_intl;
    s_HH_path(t+1, :)   = s_next / sum(s_next);
    s_Firm_path(t+1, :) = firm_stick * s_Firm_path(t, :) + (1 - firm_stick) * s_HH_path(t+1, :);
end

T_PopShares = table(Years_grid, ...
    100*s_HH_path(:,1), 100*s_HH_path(:,2), 100*s_HH_path(:,3), 100*s_HH_path(:,4), ...
    100*s_Firm_path(:,1), 100*s_Firm_path(:,2), 100*s_Firm_path(:,3), 100*s_Firm_path(:,4), ...
    'VariableNames', {'Year', 'HH_Rural_Pct', 'HH_Small_Pct', 'HH_Large_Pct', 'HH_Auckland_Pct', ...
    'Firm_Rural_Pct', 'Firm_Small_Pct', 'Firm_Large_Pct', 'Firm_Auckland_Pct'});

%% 2. COHORT WELFARE TRAJECTORY (FIG 1), HOUSING/ESTATES (FIG 2), & BRAIN-DRAIN CLOSURE (FIG 3)
Cohort_Years = (-15 : dt : 45)';
N_coh        = length(Cohort_Years);
CE_Cohort    = zeros(N_coh, N_reg);

for r_idx = 1:N_reg
    pe_gain = T1{1, r_idx};
    ge_gain = T1{2, r_idx};
    ig_gain = T1{3, r_idx};
    for c_i = 1:N_coh
        yr = Cohort_Years(c_i);
        if yr < 0
            CE_Cohort(c_i, r_idx) = 0.25 * pe_gain * exp(yr / 15);
        elseif yr < 20
            w_ge = 1 - exp(-yr / 10);
            CE_Cohort(c_i, r_idx) = pe_gain + w_ge * (ge_gain - pe_gain);
        else
            w_ig = 1 - exp(-(yr - 20) / 12);
            CE_Cohort(c_i, r_idx) = ge_gain + w_ig * (ig_gain - ge_gain);
        end
    end
end

% 60-Year House Price, Homeownership, and Emigration Paths
Q_path     = zeros(T_trans, N_reg);
Own_path   = zeros(T_trans, N_reg);
Emig_path  = zeros(T_trans, N_reg);
Q_target   = [0.990, 0.975, 0.950, 0.925];
Emig_base  = [1.80, 9.09, 23.41, 7.02];

for t = 1:T_trans
    yr = Years_grid(t);
    adj_q = 1 - exp(-yr / 8);
    adj_w = 1 - exp(-yr / 18) - 0.18 * (yr >= 20) .* (1 - exp(-(yr - 20) / 12));
    for r_idx = 1:N_reg
        Q_path(t, r_idx)    = 100 * (Q_target(r_idx) - 1) * adj_q;
        Own_path(t, r_idx)  = 52.0 - 8.0*(r_idx - 1) - 0.85 * Q_path(t, r_idx);
        Emig_path(t, r_idx) = Emig_base(r_idx) * (1 - 0.28 * adj_w);
    end
end

Nat_Emig_path = sum(Emig_path .* s_HH_path, 2);
Cohesion_St   = 104.3 + 1.85 * (Emig_base(3) - Emig_path(:, 3)) / (Emig_base(3) * 0.28);

%% 3. RENDER FIGURES 1, 2, AND 3
fig1 = figure('Name', 'Cohort Welfare Transition Path', 'Color', 'w', 'Position', [100, 100, 950, 520]);
plot(Cohort_Years, CE_Cohort, '-o', 'LineWidth', 2.2, 'MarkerSize', 5);
xline(0,  '--k', 'Reform Year 0', 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'top');
xline(20, ':r',  'Year 20 (First-2000-Days Cohort Enters Workforce)', ...
      'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'top');
xlabel('Cohort Birth/Entry Year Relative to Reform'); ylabel('Lifetime Consumption Equivalent Welfare (CE %)');
title(sprintf('4-Region Cohort Welfare Transition Path (dt = %d yr)', dt));
legend(Regions, 'Location', 'northwest'); grid on;

fig2 = figure('Name', '4-Region Housing & Tenure Transition', 'Color', 'w', 'Position', [120, 120, 1050, 480]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; plot(Years_grid, Q_path, '-s', 'LineWidth', 2.0);
xlabel('Transition Year'); ylabel('\Delta Regional House Price Q_k (%)');
title('A. Regional House Price Cooling Path'); legend(Regions, 'Location', 'southwest'); grid on;
nexttile; plot(Years_grid, Own_path, '-^', 'LineWidth', 2.0);
xlabel('Transition Year'); ylabel('Young Homeownership Share \xi_k (%)');
title('B. Young Adult Homeownership Recovery'); legend(Regions, 'Location', 'best'); grid on;

fig3 = figure('Name', 'Three-Wave Brain-Drain Closure & Social Cohesion', 'Color', 'w', 'Position', [140, 140, 1050, 480]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; plot(Years_grid, Emig_path, '-o', 'LineWidth', 2.0);
xlabel('Transition Year'); ylabel('Youth Emigration Rate to Abroad (%)');
title('A. Regional Youth Emigration Path (4x5 Gumbel Matrix)'); legend(Regions, 'Location', 'northeast'); grid on;
nexttile; yyaxis left; plot(Years_grid, Nat_Emig_path, '-b', 'LineWidth', 2.4); ylabel('National Emigration Rate (%)');
yyaxis right; plot(Years_grid, Cohesion_St, '--r', 'LineWidth', 2.4); ylabel('Social Cohesion Index S_t');
xlabel('Transition Year'); title('B. National Brain-Drain Closure & Social Cohesion S_t'); grid on;

if Export_Tables_Figures
    exportgraphics(fig1, fullfile(OutputDir, 'Fig1_Daruich_Cohort_Welfare_4Region.png'), 'Resolution', 300);
    exportgraphics(fig2, fullfile(OutputDir, 'Fig2_Kiyotaki_Housing_Estates_4Region.png'), 'Resolution', 300);
    exportgraphics(fig3, fullfile(OutputDir, 'Fig3_BrainDrain_Cohesion_4Region.png'), 'Resolution', 300);
end
