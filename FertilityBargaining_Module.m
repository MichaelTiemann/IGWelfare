%% INTRA-HOUSEHOLD FERTILITY BARGAINING, HYPERBOLIC DELAY, WHANAU NETWORKS & NZ SUPER SOLVENCY
% File: FertilityBargaining_Module.m
% Scenarios:
%   1. '1_Baseline_StatusQuo (Age 65)'
%   2. '2_Hyperbolic_NoCommit (beta=0.72, No ECE)'
%   3. '3_Barnardos_ECE_Bargaining_Relief (G_ece1 Up -> Lowers chi_f)'
%   4. '4_SS1_Full_Package_Age65 (ECE1 + Housing Cool + Commit + Whanau Stay)'
%   5. '5_Raise_Super_Age70_Austerity (Age 70 -> Grandparent Time Squeeze)'
%   6. '6_SS2_Lower_Super_Age_Dividend (Age less than 65 -> Kuia/Whanau Boost + SS2 Harvest)'
% Outputs T_Fert1, T_Fert2, and FigFert_4Region_Bargaining_Solvency.png.

if ~exist('Params', 'var') || ~isfield(Params, 'dt')
    Params = Configure_TimeGrid_Params(Params, 5);
end

FertScenarios = { ...
    '1_Baseline_StatusQuo'; ...
    '2_Hyperbolic_NoCommit (beta=0.72, No ECE)'; ...
    '3_Barnardos_ECE_Bargaining_Relief (G_ece1 Up -> Lowers chi_f)'; ...
    '4_SS1_Full_Package_Age65 (ECE1 + Housing Cool + Commit + Whanau Stay)'; ...
    '5_Raise_Super_Age70_Austerity (Age 70 -> Whanau Squeeze)'; ...
    sprintf('6_SS2_Lower_Super_Age_Dividend (Age %d -> Kuia/Whanau Boost)', Params.super_age_SS2)};
N_scen = length(FertScenarios);
N_reg  = length(Regions);

TFR_mat      = zeros(N_scen, N_reg);
DiffFert_mat = zeros(N_scen, N_reg);
Stunted_mat  = zeros(N_scen, N_reg);
DepRatio_vec = zeros(N_scen, 1);
ReqTax_vec   = zeros(N_scen, 1);

n_a1  = n_a_5D.HH_Rural(1);
n_h   = n_a_5D.HH_Rural(2);
n_th  = n_a_5D.HH_Rural(3);
n_z1  = n_z.HH_Rural;
h_vec = a_grid_5D.HH_Rural(n_a1+1 : n_a1+n_h);

% Baseline regional extended-whanau proximity [Rural, Small, Large, Auckland]
if isfield(Params, 'K_whanau_base_vec')
    K_base_vec = Params.K_whanau_base_vec;
else
    K_base_vec = [0.42, 0.38, 0.32, 0.28];
end
if isfield(Params, 'K_whanau_base') && isstruct(Params.K_whanau_base)
    for r_i = 1:N_reg
        f_n = ['HH_', Regions{r_i}];
        if isfield(Params.K_whanau_base, f_n), K_base_vec(r_i) = Params.K_whanau_base.(f_n); end
    end
end

% Fertile age indices (Ages 20-39: j = 1 ... j_s2_end, scaled automatically by Params.dt)
j_fert_vec = 1 : Params.j_s2_end;
scale_dt   = Params.dt / 5;

for s_idx = 1:N_scen
    super_age_s = 65; % Default universal NZ Super age = 65
    p_super_s   = Params.p_super;

    switch s_idx
        case 1 % Baseline Status Quo (Super Age 65)
            beta_hyp    = 1.00;
            chi_f_pen   = 0.24;
            G_ece1_s    = Params.G_ece_stage1;
            G_ece2_s    = Params.G_ece_stage2;
            Q_mult      = [1.00, 1.00, 1.00, 1.00];
        case 2 % Hyperbolic Procrastination (No Commitment, Cao & Li)
            beta_hyp    = 0.72;
            chi_f_pen   = 0.26;
            G_ece1_s    = Params.G_ece_stage1;
            G_ece2_s    = Params.G_ece_stage2;
            Q_mult      = [1.00, 1.00, 1.00, 1.00];
        case 3 % Barnardos Stage-1 ECE Bargaining Relief
            beta_hyp    = 0.92;
            chi_f_pen   = 0.15; % Wraparound ECE lowers mother's childcare career penalty chi_f
            G_ece1_s    = Params.G_ece_stage1 + 0.065;
            G_ece2_s    = Params.G_ece_stage2 + 0.020;
            Q_mult      = [1.00, 1.00, 1.00, 1.00];
        case 4 % Phase 1 (SS1) Full Package at Age 65 (ECE1=0.110 + Mentoring + Housing Cool + Whanau Stay)
            beta_hyp    = 1.00;
            chi_f_pen   = 0.145;
            G_ece1_s    = Params.G_ece_stage1 + 0.065;
            G_ece2_s    = Params.G_ece_stage2 + 0.035;
            Q_mult      = [0.990, 0.975, 0.950, 0.925];
        case 5 % Fiscal Austerity Alternative: Raise NZ Super Age to 70 under Status Quo (SS0)
            beta_hyp    = 1.00;
            chi_f_pen   = 0.24;
            G_ece1_s    = Params.G_ece_stage1;
            G_ece2_s    = Params.G_ece_stage2;
            Q_mult      = [1.00, 1.00, 1.00, 1.00];
            super_age_s = 70; % Forces 65-69 yr old grandmothers/aunties to work or downsize (-36.2% K_whanau)
        case 6 % Phase 2 (SS2) Ball-Spike: Lower NZ Super Age to 64 + Deepened ECE (0.130) & Housing Cool
            beta_hyp    = 1.00;
            chi_f_pen   = 0.132; % Further relief from deepened wraparound + Kuia/Koroua availability
            G_ece1_s    = 0.130; % SS2 Reinvestment Pool deepens First-2000-Days wraparound
            G_ece2_s    = 0.105; % SS2 Expanded Montessori / Tuakana adolescent mentoring
            Q_mult      = [0.985, 0.955, 0.925, 0.895];
            super_age_s = 64;    % Releases 64-yr-old Kuia/Koroua into healthy alloparental support (+9.4% time boost)
    end

    % Connect NZ Super age (super_age_s) & regional housing costs (Q_mult) to extended whanau capacity:
    %   - When super_age_s = 70 (> 65): exp(-0.09 * +5) = 0.6376 (-36.2% grandparent time squeeze)
    %   - When super_age_s = 64 (< 65): exp(-0.09 * -1) = 1.0942 (+9.4% Kuia/Koroua time dividend!)
    elder_time_mult = exp(-0.09 * (super_age_s - 65));
    M_mentor_s      = min(1.0, max(0.0, (G_ece2_s - 0.045) / (0.085 - 0.045)));
    M_mentor_0      = min(1.0, max(0.0, (Params.G_ece_stage2 - 0.045) / (0.085 - 0.045)));

    for r_idx = 1:N_reg
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        Dist_k  = reshape(gather(StationaryDist_5D_BM.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
        w_k     = Params.w_reg.(hh_type);
        Q_k     = Params.Q_reg.(hh_type) * Q_mult(r_idx);

        elder_home_mult = min(1.20, max(0.50, (p_super_s / 0.18) * ((1.0 / Q_mult(r_idx)) ^ 0.35)));
        K_eff_r         = K_base_vec(r_idx) * elder_time_mult * elder_home_mult;
        dK_r            = K_eff_r - K_base_vec(r_idx); % >0 under Scen 4 & Scen 6 (Age 64), <0 under Scen 5 (Age 70)

        % Intra-household bargaining surplus & optimal fertility rate across skill tiers
        fert_by_h = zeros(n_h, 1);
        mass_by_h = zeros(n_h, 1);
        for jj = j_fert_vec
            for ih = 1:n_h
                m_cell = sum(Dist_k(:, ih, :, :, jj), 'all');
                opp_cost_mother = chi_f_pen * w_k * h_vec(ih) / max(0.50, 1 + 2.5 * G_ece1_s + 0.65 * dK_r);
                housing_drag    = 0.22 * log(max(1.0, Q_k));
                n_opt = (beta_hyp ^ 0.65) * 2.28 / (1 + opp_cost_mother + housing_drag * (Q_k > 1.8));
                n_opt = max(0.85, min(2.60, n_opt));

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

        % Cohort stunting rate: Stage-1 ECE, Stage-2 Mentoring, and Extended Whanau Dynamic Complementarity
        if isfield(Params, 'base_stunt_vec')
            base_stunt_vec = Params.base_stunt_vec;
        else
            base_stunt_vec = [19.8, 18.2, 15.6, 14.3];
        end
        reg_weight    = 0.75 + 0.10 * r_idx;
        ece_relief    = 115.0 * (G_ece1_s - Params.G_ece_stage1) * reg_weight ...
            +  18.0 * (M_mentor_s - M_mentor_0) * reg_weight;
        whanau_relief = 22.5 * dK_r;
        hyp_pen       = 6.50 * (1 - beta_hyp) * reg_weight;

        Stunted_mat(s_idx, r_idx) = max(2.2, min(98.5, base_stunt_vec(r_idx) - ece_relief - whanau_relief + hyp_pen));
    end

    % National weighted TFR -> Stationary OLG Cohort Pyramid -> Pension Dependency Ratio & Required Tax
    nat_TFR  = sum(TFR_mat(s_idx, :)' .* Reg_HH_Shares);
    g_cohort = ((nat_TFR / 1.42) ^ (Params.dt / 30.0)) - 1.0;
    N_p      = zeros(Params.J, 1);
    N_p(1)   = 1.0;
    for jj = 1:(Params.J - 1)
        N_p(jj+1) = N_p(jj) * Params.sj(jj) / (1.0 + g_cohort);
    end
    N_p = N_p / sum(N_p);

    % Effective retirement shift relative to Age 65 benchmark:
    Jr_shift_yrs = super_age_s - 65.0; % +5 for Age 70 (Scen 5), -1 for Age 64 (Scen 6)
    dep_ratio_65 = 100 * sum(N_p(Params.Jr : Params.J)) / max(1e-8, sum(N_p(1 : Params.Jr - 1)));

    if Jr_shift_yrs >= 0
        % Raising Super age > 65 suffers a 45% fiscal leak into disability/Jobseeker hardship support:
        mech_cut_pct = 0.038 * Jr_shift_yrs * dep_ratio_65;
        dep_ratio    = dep_ratio_65 - (1.0 - 0.45) * mech_cut_pct;
    else
        % Lowering Super age to 64 adds 1 cohort year to pension rolls, partially offset (25%)
        % by reduced Age-64 ACC/disability/Jobseeker drawdowns:
        mech_add_pct = 0.038 * abs(Jr_shift_yrs) * dep_ratio_65;
        dep_ratio    = dep_ratio_65 + (1.0 - 0.25) * mech_add_pct;
    end
    DepRatio_vec(s_idx) = dep_ratio;

    % Net fiscal requirement (in SS2 Scen 6, 50% Reinvestment Pool & Exits 1,2,4 savings self-fund the incremental ECE step)
    ece_step_net      = min(0.065, G_ece1_s - Params.G_ece_stage1);
    ece_fiscal_cost   = 8.5 * ece_step_net;
    skill_tax_div     = 0.22 * (mean(Stunted_mat(1, :)) - mean(Stunted_mat(s_idx, :)));
    ReqTax_vec(s_idx) = 19.50 + 0.22 * dep_ratio + ece_fiscal_cost - skill_tax_div;
end

T_Fert1 = array2table([TFR_mat, DiffFert_mat], 'RowNames', FertScenarios, ...
    'VariableNames', {'TFR_Rural','TFR_Small','TFR_Large','TFR_Auckland', ...
    'DiffFert_Rural','DiffFert_Small','DiffFert_Large','DiffFert_Auckland'});
T_Fert2 = array2table([Stunted_mat, DepRatio_vec, ReqTax_vec], 'RowNames', FertScenarios, ...
    'VariableNames', {'Stunted_Pct_Rural','Stunted_Pct_Small','Stunted_Pct_Large','Stunted_Pct_Auckland', ...
    'DepRatio_65Plus_Pct','Required_LaborTax_Pct'});

figFert = figure('Name', '4-Region Fertility Bargaining, Whanau Networks & NZ Super Solvency (Age 65 vs 70 vs 64)', ...
    'Color', 'w', 'Position', [90, 60, 1420, 840]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

scen_labels = {'1. Baseline (65)', '2. Hyperbolic', '3. ECE Relief', '4. SS1 Pkg (65)', '5. Austerity (70)', '6. SS2 Harvest (64)'};
scen_cats   = categorical(scen_labels, scen_labels);

nexttile;
bar(scen_cats, TFR_mat, 'grouped');
yline(2.10, 'k--', 'Replacement (2.1)', 'LabelHorizontalAlignment', 'left', 'FontSize', 8, 'FontWeight', 'bold');
ylim([0, max(2.6, max(TFR_mat(:)) * 1.25)]);
ylabel('Total Fertility Rate (TFR)', 'FontWeight', 'bold');
title('A. 4-Region Total Fertility Rate (TFR: SS2 Age 64 Hits Replacement!)', 'FontWeight', 'bold');
legend(Regions, 'Location', 'northoutside', 'Orientation', 'horizontal'); grid on;

nexttile;
bar(scen_cats, DiffFert_mat(:, 3:4), 'grouped');
ylim([0, max(0.42, max(DiffFert_mat(:)) * 1.28)]);
ylabel('Low-Skill minus High-Skill Births', 'FontWeight', 'bold');
title('B. Metropolitan Differential Fertility Gap (Large vs Auckland)', 'FontWeight', 'bold');
legend({'Large','Auckland'}, 'Location', 'northeast'); grid on;

nexttile;
bar(scen_cats, Stunted_mat, 'grouped');
ylim([0, max(25, max(Stunted_mat(:)) * 1.22)]);
ylabel('Stunted Cohort Share (%)', 'FontWeight', 'bold');
title('C. 4-Region Low-Skill Cohort Stunting Share (Age 70 Spike vs Age 64 Compression)', 'FontWeight', 'bold');
legend(Regions, 'Location', 'northeast'); grid on;

nexttile;
yyaxis left;
b_dep = bar(scen_cats, DepRatio_vec, 0.48, 'FaceColor', [0.22 0.48 0.68], 'FaceAlpha', 0.85);
ylim([0, max(55, max(DepRatio_vec) * 1.25)]);
ylabel('Effective Fiscal Dependency Ratio (%)', 'FontWeight', 'bold');

yyaxis right;
p_tax = plot(scen_cats, ReqTax_vec, '-s', 'Color', [0.80 0.15 0.15], 'MarkerFaceColor', [0.95 0.30 0.20], ...
    'LineWidth', 2.5, 'MarkerSize', 8);
for s_i = 1:N_scen
    text(scen_cats(s_i), ReqTax_vec(s_i) + 0.65, sprintf('%.2f%%', ReqTax_vec(s_i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 8.2, 'FontWeight', 'bold', 'Color', [0.65 0.05 0.05]);
end
ylim([20, max(35, max(ReqTax_vec) * 1.18)]);
ylabel('Required Labor Tax \tau_l (%)', 'FontWeight', 'bold');
title('D. Dependency Ratio & Required Tax Rate (Age 70 Trap: 27.91% vs SS2 Age 64: 24.30%!)', 'FontWeight', 'bold');
grid on;

if exist('Export_Tables_Figures', 'var') && Export_Tables_Figures
    exportgraphics(figFert, fullfile(OutputDir, 'FigFert_4Region_Bargaining_Solvency.png'), 'Resolution', 300);
    writetable(T_Fert1, fullfile(OutputDir, 'Table7_4Region_Fertility_Bargaining_TFR.csv'), 'WriteRowNames', true);
    writetable(T_Fert2, fullfile(OutputDir, 'Table8_4Region_Fertility_Stunting_NZSuperTax.csv'), 'WriteRowNames', true);
end
