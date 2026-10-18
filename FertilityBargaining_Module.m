%% INTRA-HOUSEHOLD FERTILITY BARGAINING, HYPERBOLIC DELAY & NZ SUPER SOLVENCY (INTEGRATED WITH Params.dt)
% File: FertilityBargaining_Module.m
% Scenarios:
%   1. '1_Baseline_StatusQuo'
%   2. '2_Hyperbolic_NoCommit (beta=0.72, No ECE)'
%   3. '3_Barnardos_ECE_Bargaining_Relief (G_ece1 Up -> Lowers chi_f)'
%   4. '4_Full_Package (ECE1 + Housing Cool + Commit)'
% Outputs Table_Fert1, Table_Fert2, and FigFert_4Region_Bargaining_Solvency.png.

if ~exist('Params', 'var') || ~isfield(Params, 'dt')
    Params = Configure_TimeGrid_Params(Params, 5);
end

FertScenarios = {
    '1_Baseline_StatusQuo';
    '2_Hyperbolic_NoCommit (beta=0.72, No ECE)';
    '3_Barnardos_ECE_Bargaining_Relief (G_ece1 Up -> Lowers chi_f)';
    '4_Full_Package (ECE1 + Housing Cool + Commit)'
    };
N_scen = length(FertScenarios);
N_reg  = length(Regions);

TFR_mat        = zeros(N_scen, N_reg);
DiffFert_mat   = zeros(N_scen, N_reg);
Stunted_mat    = zeros(N_scen, N_reg);
DepRatio_vec   = zeros(N_scen, 1);
ReqTax_vec     = zeros(N_scen, 1);

n_a1  = n_a_5D.HH_Rural(1);
n_h   = n_a_5D.HH_Rural(2);
n_th  = n_a_5D.HH_Rural(3);
n_z1  = n_z.HH_Rural;
h_vec = a_grid_5D.HH_Rural(n_a1+1 : n_a1+n_h);

% Fertile age indices (Ages 20-39: j = 1 ... j_s2_end, scaled automatically by Params.dt)
j_fert_vec = 1 : Params.j_s2_end;
scale_dt   = Params.dt / 5;

for s_idx = 1:N_scen
    switch s_idx
        case 1 % Baseline Status Quo
            beta_hyp  = 1.00;
            chi_f_pen = 0.24;
            G_ece1_s  = Params.G_ece_stage1;
            Q_mult    = [1.00, 1.00, 1.00, 1.00];
        case 2 % Hyperbolic Procrastination (No Commitment, Cao & Li)
            beta_hyp  = 0.72;
            chi_f_pen = 0.26;
            G_ece1_s  = Params.G_ece_stage1;
            Q_mult    = [1.00, 1.00, 1.00, 1.00];
        case 3 % Barnardos Stage-1 ECE Bargaining Relief
            beta_hyp  = 0.92;
            chi_f_pen = 0.15; % Wraparound ECE lowers mother's childcare career penalty chi_f
            G_ece1_s  = Params.G_ece_stage1 + 0.065;
            Q_mult    = [1.00, 1.00, 1.00, 1.00];
        case 4 % Full Package (ECE1 + Housing Cooling + Commitment Support)
            beta_hyp  = 1.00;
            chi_f_pen = 0.145;
            G_ece1_s  = Params.G_ece_stage1 + 0.065;
            Q_mult    = [0.990, 0.975, 0.950, 0.925];
    end

    for r_idx = 1:N_reg
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        Dist_k  = reshape(gather(StationaryDist_5D_BM.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
        w_k     = Params.w_reg.(hh_type);
        Q_k     = Params.Q_reg.(hh_type) * Q_mult(r_idx);

        % Intra-household bargaining surplus & optimal fertility rate across skill tiers
        fert_by_h = zeros(n_h, 1);
        mass_by_h = zeros(n_h, 1);

        for jj = j_fert_vec
            for ih = 1:n_h
                m_cell = sum(Dist_k(:, ih, :, :, jj), 'all');
                opp_cost_mother = chi_f_pen * w_k * h_vec(ih) / (1 + 2.5 * G_ece1_s);
                housing_drag    = 0.22 * log(max(1.0, Q_k));

                % Cao & Li hyperbolic factor (beta_hyp^(1/epsilon)) depresses urban fertility under high Q_k
                n_opt = (beta_hyp ^ 0.65) * 3.85 / (1 + opp_cost_mother + housing_drag * (Q_k > 1.8));
                n_opt = max(0.85, min(3.80, n_opt));

                fert_by_h(ih) = fert_by_h(ih) + m_cell * n_opt;
                mass_by_h(ih) = mass_by_h(ih) + m_cell;
            end
        end

        avg_fert_h = fert_by_h ./ max(1e-12, mass_by_h);
        TFR_mat(s_idx, r_idx) = sum(fert_by_h) / max(1e-12, sum(mass_by_h));

        % Differential fertility (Low-skill h1..h2 vs High-skill h6..h7 difference)
        fert_low  = mean(avg_fert_h(1:2));
        fert_high = mean(avg_fert_h(6:7));
        DiffFert_mat(s_idx, r_idx) = fert_low - fert_high;

        % Cohort stunting rate (adjusted for ECE1 & differential fertility composition)
        base_stunt = 100 * IG_Diag_5D_BM.StuntedShare.(reg);
        ece_relief = 38.0 * (G_ece1_s - Params.G_ece_stage1) * (r_idx >= 3);
        hyp_pen    = 1.55 * (1 - beta_hyp) * (r_idx >= 3);
        Stunted_mat(s_idx, r_idx) = max(5.0, min(98.5, base_stunt - ece_relief + hyp_pen));
    end

    % National weighted TFR -> Stationary Demographic Pyramid -> 65+ Dependency Ratio & Required Tax
    nat_TFR = sum(TFR_mat(s_idx, :)' .* Reg_HH_Shares);
    T_dem_s = zeros(Params.J, Params.J);
    T_dem_s(1, :) = Params.fj * (nat_TFR / 2.1);
    for jj = 1:(Params.J - 1)
        T_dem_s(jj+1, jj) = Params.sj(jj);
    end
    N_p = ones(Params.J, 1) / Params.J;
    for it = 1:200
        N_p = T_dem_s * N_p + Params.mig_rate_j' .* N_p;
        N_p = max(0, N_p) / sum(max(0, N_p));
    end

    dep_ratio = 100 * sum(N_p(Params.Jr : Params.J)) / max(1e-8, sum(N_p(1 : Params.Jr - 1)));
    DepRatio_vec(s_idx) = dep_ratio;

    ece_fiscal_cost = 14.5 * (G_ece1_s - Params.G_ece_stage1);
    ReqTax_vec(s_idx) = 23.80 + 0.244 * dep_ratio + ece_fiscal_cost;
end

T_Fert1 = array2table([TFR_mat, DiffFert_mat], 'RowNames', FertScenarios, ...
    'VariableNames', {'TFR_Rural','TFR_Small','TFR_Large','TFR_Auckland', ...
    'DiffFert_Rural','DiffFert_Small','DiffFert_Large','DiffFert_Auckland'});

T_Fert2 = array2table([Stunted_mat, DepRatio_vec, ReqTax_vec], 'RowNames', FertScenarios, ...
    'VariableNames', {'Stunted_Pct_Rural','Stunted_Pct_Small','Stunted_Pct_Large','Stunted_Pct_Auckland', ...
    'DepRatio_65Plus_Pct','Required_LaborTax_Pct'});

figFert = figure('Name', '4-Region Fertility Bargaining & NZ Super Solvency', 'Color', 'w', 'Position', [120, 120, 1150, 720]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
scen_cats = categorical({'1. Baseline','2. Hyperbolic','3. ECE Relief','4. Full Pkg'}, ...
    {'1. Baseline','2. Hyperbolic','3. ECE Relief','4. Full Pkg'});

nexttile; bar(scen_cats, TFR_mat, 'grouped'); ylabel('Total Fertility Rate (TFR)');
title('A. 4-Region Total Fertility Rate (TFR)'); legend(Regions, 'Location', 'southwest'); grid on;

nexttile; bar(scen_cats, DiffFert_mat(:, 3:4), 'grouped'); ylabel('Low-Skill minus High-Skill Births');
title('B. Metropolitan Differential Fertility Gap (Large vs Auckland)'); legend({'Large','Auckland'}); grid on;

nexttile; bar(scen_cats, Stunted_mat(:, 3:4), 'grouped'); ylabel('Stunted Cohort Share (%)');
title('C. Metropolitan Low-Skill Cohort Share (Large vs Auckland)'); legend({'Large','Auckland'}); grid on;

nexttile; yyaxis left; bar(scen_cats, DepRatio_vec, 0.45); ylabel('65+ Dependency Ratio (%)');
yyaxis right; plot(scen_cats, ReqTax_vec, '-s', 'LineWidth', 2.2, 'MarkerSize', 8); ylabel('Required Labor Tax \tau_l (%)');
title('D. Aged 65+ Dependency Ratio & Required Tax Rate'); grid on;

if Export_Tables_Figures
    exportgraphics(figFert, fullfile(OutputDir, 'FigFert_4Region_Bargaining_Solvency.png'), 'Resolution', 300);
end
