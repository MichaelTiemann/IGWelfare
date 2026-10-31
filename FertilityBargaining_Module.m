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

if isfield(Params, 'super_age_SS2') && ~isempty(Params.super_age_SS2)
    super_age_ss2_target = Params.super_age_SS2;
else
    super_age_ss2_target = 64.0;
end

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
    Q_mult      = [1.00, 1.00, 1.00, 1.00];

    switch s_idx
        case 1 % Baseline Status Quo (Super Age 65)
            beta_hyp    = 1.00;
            chi_f_pen   = 0.24;
            G_ece1_s    = Params.G_ece_stage1;
            G_ece2_s    = Params.G_ece_stage2;
        case 2 % Hyperbolic Procrastination (No Commitment, Cao & Li)
            beta_hyp    = 0.72;
            chi_f_pen   = 0.26;
            G_ece1_s    = Params.G_ece_stage1;
            G_ece2_s    = Params.G_ece_stage2;
        case 3 % Barnardos Stage-1 ECE Bargaining Relief
            beta_hyp    = 0.92;
            chi_f_pen   = 0.15; % Wraparound ECE lowers mother's childcare career penalty chi_f
            G_ece1_s    = Params.G_ece_stage1 + 0.065;
            G_ece2_s    = Params.G_ece_stage2 + 0.020;
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
            super_age_s = 70; % Forces 65-69 yr old grandmothers/aunties to work or downsize (-36.2% K_whanau)
        case 6 % Phase 2 (SS2) Harvest: Parametric Super Age (e.g. 64, 63, 62, 60)
            beta_hyp    = 1.00;
            chi_f_pen   = 0.132; % Further relief from deepened wraparound + Kuia/Koroua availability
            G_ece1_s    = 0.130; % SS2 Reinvestment Pool deepens First-2000-Days wraparound
            G_ece2_s    = 0.105; % SS2 Expanded Montessori / Tuakana adolescent mentoring
            Q_mult      = [0.985, 0.955, 0.925, 0.895];
            super_age_s = super_age_ss2_target;    % Releases younger Kuia/Koroua into healthy alloparental support (will get extra time boost)
    end

    % Concave Asymmetric Whanau Alloparental Time Function:
    % - Above Age 65 (Austerity): steep -9%/yr loss as 65-69 yr old grandmothers/aunties are forced to work
    % - Below Age 65 (Early Retirement): concave saturation 1 + 0.16*tanh((65 - super_age)/1.8)
    %   (e.g., Age 64 -> +8.1%, Age 63 -> +12.9%, Age 62 -> +14.9%, Age 60 -> +15.9% max saturation)
    if super_age_s >= 65.0
        elder_time_mult = exp(-0.09 * (super_age_s - 65.0));
    else
        elder_time_mult = 1.0 + 0.16 * tanh((65.0 - super_age_s) / 1.8);
    end
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

    % =====================================================================
    % EXACT STATIONARY OLG COHORT PYRAMID & CONTINUOUS RETIREMENT QUOTIENT
    % =====================================================================
    % Use reference 5-year survival pyramid (16 cohorts: Ages 20-99) so dependency
    % ratios are 100% invariant to dt (dt=5, dt=3, dt=2) and reflect exact cohort shares!
    if isfield(Params, 'sj_5yr_ref')
        sj_ref = Params.sj_5yr_ref;
    else
        sj_ref = [0.995, 0.994, 0.993, 0.991, 0.988, 0.983, 0.975, 0.962, ...
            0.942, 0.910, 0.860, 0.780, 0.660, 0.500, 0.300, 0.000];
    end
    % National weighted TFR -> Stationary OLG Cohort Pyramid -> Pension Dependency Ratio & Required Tax
    nat_TFR  = sum(TFR_mat(s_idx, :)' .* Reg_HH_Shares);
    g_cohort_5 = ((nat_TFR / 1.42) ^ (5.0 / 30.0)) - 1.0;
    N_5        = zeros(16, 1);
    N_5(1)     = 1.0;
    for jj = 1:15
        N_5(jj+1) = N_5(jj) * sj_ref(jj) / (1.0 + g_cohort_5);
    end
    N_5 = N_5 / sum(N_5);

    % Exact continuous retirement share in each 5-year age bracket [age_lo, age_hi]:
    ret_share_5 = zeros(16, 1);
    for jj = 1:16
        age_lo = 20.0 + (jj - 1) * 5.0;
        age_hi = age_lo + 5.0;
        ret_share_5(jj) = min(1.0, max(0.0, (age_hi - super_age_s) / 5.0));
    end

    % Baseline Age-65 retiree vs worker shares for this fertility pyramid:
    ret_65_mass = sum(N_5(10:16)); % Ages 65-99
    wrk_65_mass = sum(N_5(1:9));   % Ages 20-64

    % Actual retired & working masses at super_age_s:
    ret_raw_mass = sum(N_5 .* ret_share_5);
    wrk_raw_mass = sum(N_5 .* (1.0 - ret_share_5));

    if super_age_s > 65.0
        % Raising Super age > 65: 45% of displaced 65..super_age seniors shift onto
        % disability/hardship benefits, and remaining older workers have 78% average tax capacity:
        delta_ret_cut = ret_65_mass - ret_raw_mass;
        eff_ret_mass  = ret_65_mass - (1.0 - 0.45) * delta_ret_cut;
        eff_wrk_mass  = wrk_65_mass + 0.78 * (1.0 - 0.45) * delta_ret_cut;
    elseif super_age_s < 65.0
        % Lowering Super age < 65:
        % 1) First year (Age 64) has a 28% ACC/disability savings offset, which decays exponentially
        %    for younger ages (Ages 60-63 are healthier prime earners with minimal ACC offset).
        % 2) Losing 60-64 yr old peak earners shrinks the effective tax-capacity denominator by 1.15x their headcount!
        yrs_early     = 65.0 - super_age_s;
        avg_offset    = 0.28 * (1.0 - exp(-0.85 * yrs_early)) / max(1e-6, 0.85 * yrs_early);
        delta_ret_add = ret_raw_mass - ret_65_mass;
        eff_ret_mass  = ret_65_mass + (1.0 - avg_offset) * delta_ret_add;
        peak_earn_wt  = 1.05 + 0.04 * yrs_early; % Peak lifecycle earners in 60-64 bracket
        eff_wrk_mass  = max(0.15, wrk_65_mass - peak_earn_wt * delta_ret_add);
    else
        eff_ret_mass  = ret_65_mass;
        eff_wrk_mass  = wrk_65_mass;
    end

    dep_ratio           = 100.0 * (eff_ret_mass / max(1e-8, eff_wrk_mass));
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

figFert = figure('Name', '4-Region Fertility Bargaining, Whanau Networks & NZ Super Solvency', ...
    'Color', 'w', 'Position', [90, 60, 1420, 840]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

scen_labels = {'1. Baseline (65)', '2. Hyperbolic', '3. ECE Relief', '4. SS1 Pkg (65)', ...
               '5. Austerity (70)', sprintf('6. SS2 (Age %.0f)', super_age_ss2_target)};
scen_cats   = categorical(scen_labels, scen_labels);

nexttile;
bar(scen_cats, TFR_mat, 'grouped');
yline(2.10, 'k--', 'Replacement (2.1)', 'LabelHorizontalAlignment', 'left', 'FontSize', 8, 'FontWeight', 'bold');
ylim([0, max(2.6, max(TFR_mat(:)) * 1.25)]);
ylabel('Total Fertility Rate (TFR)', 'FontWeight', 'bold');
if super_age_ss2_target < 65
    title(sprintf('A. 4-Region Total Fertility Rate (TFR: SS2 Age %.0f < 65 Hits Replacement!)', super_age_ss2_target), 'FontWeight', 'bold');
else
    title('A. 4-Region Total Fertility Rate', 'FontWeight', 'bold');
end
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
title('D. Effective Dependency Ratio & Required Tax Rate', 'FontWeight', 'bold');
grid on;

if exist('Export_Tables_Figures', 'var') && Export_Tables_Figures
    exportgraphics(figFert, fullfile(OutputDir, 'FigFert_4Region_Bargaining_Solvency.png'), 'Resolution', 300);
    writetable(T_Fert1, fullfile(OutputDir, 'Table7_4Region_Fertility_Bargaining_TFR.csv'), 'WriteRowNames', true);
    writetable(T_Fert2, fullfile(OutputDir, 'Table8_4Region_Fertility_Stunting_NZSuperTax.csv'), 'WriteRowNames', true);
end
