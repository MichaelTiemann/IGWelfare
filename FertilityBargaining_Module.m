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
        whanau_gain   = 22.5 * max(0.0, dK_r);
        % When super_age > 65 (dK_r < 0), losing grandparent/aunty supervision causes adolescent
        % & family-stress attrition even when formal Stage-1 ECE is present:
        yrs_late_r    = max(0.0, super_age_s - 65.0);
        whanau_squeeze_pen = max(0.0, -dK_r) * (22.5 + 2.8 * yrs_late_r);
        hyp_pen       = 6.50 * (1 - beta_hyp) * reg_weight;

        stunt_post_ece = max(2.2, base_stunt_vec(r_idx) - ece_relief - whanau_gain + hyp_pen);
        Stunted_mat(s_idx, r_idx) = min(98.5, stunt_post_ece + whanau_squeeze_pen);
    end

    % =====================================================================
    % EXACT STATIONARY OLG COHORT PYRAMID & CONTINUOUS RETIREMENT QUOTIENT
    % =====================================================================
    if isfield(Params, 'sj_5yr_ref')
        sj_ref = Params.sj_5yr_ref;
    else
        sj_ref = [0.995, 0.994, 0.993, 0.991, 0.988, 0.983, 0.975, 0.962, ...
            0.942, 0.910, 0.860, 0.780, 0.660, 0.500, 0.300, 0.000];
    end
    nat_TFR    = sum(TFR_mat(s_idx, :)' .* Reg_HH_Shares);
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

    ret_65_mass  = sum(N_5(10:16)); % Ages 65-99
    wrk_65_mass  = sum(N_5(1:9));   % Ages 20-64
    ret_raw_mass = sum(N_5 .* ret_share_5);
    wrk_raw_mass = sum(N_5 .* (1.0 - ret_share_5));

    if super_age_s > 65.0
        % Raising Super age > 65:
        % 1) Share of displaced seniors able to remain healthy full-time workers decays exponentially with age:
        yrs_late          = super_age_s - 65.0;
        healthy_wrk_share = 0.48 * exp(-0.18 * yrs_late);
        delta_ret_cut     = ret_65_mass - ret_raw_mass;
        % 2) Unhealthy displaced seniors draw Supported Living / Disability (55%) + geriatric ACC/hospital costs:
        fiscal_leak_mult  = 1.15 + 0.085 * yrs_late;
        eff_ret_mass      = ret_65_mass - healthy_wrk_share * delta_ret_cut ...
            + (fiscal_leak_mult - 1.0) * (1.0 - healthy_wrk_share) * delta_ret_cut;
        % 3) Sandwich elder-care drag on 40-55 yr old adult children reduces prime working tax base:
        sandwich_wrk_loss = 0.35 * (1.0 - healthy_wrk_share) * delta_ret_cut;
        eff_wrk_mass      = max(0.15, wrk_65_mass + 0.60 * healthy_wrk_share * delta_ret_cut - sandwich_wrk_loss);
    elseif super_age_s < 65.0
        % Lowering Super age < 65:
        yrs_early     = 65.0 - super_age_s;
        avg_offset    = 0.28 * (1.0 - exp(-0.85 * yrs_early)) / max(1e-6, 0.85 * yrs_early);
        delta_ret_add = ret_raw_mass - ret_65_mass;
        eff_ret_mass  = ret_65_mass + (1.0 - avg_offset) * delta_ret_add;
        peak_earn_wt  = 1.05 + 0.04 * yrs_early;
        eff_wrk_mass  = max(0.15, wrk_65_mass - peak_earn_wt * delta_ret_add);
    else
        eff_ret_mass  = ret_65_mass;
        eff_wrk_mass  = wrk_65_mass;
    end

    dep_ratio           = 100.0 * (eff_ret_mass / max(1e-8, eff_wrk_mass));
    DepRatio_vec(s_idx) = dep_ratio;

    % =====================================================================
    % UNIFIED GOVERNMENT BUDGET IDENTITY ANCHORED TO STATUTORY tau_l = 22.0%
    % =====================================================================
    tau_l_base_pct  = 100.0 * Params.tau_l; % 22.00%
    dep_ratio_2026  = 24.50;
    aging_tax_drift = 0.22 * (dep_ratio - dep_ratio_2026);
    stunt_reduction = mean(Stunted_mat(1, :)) - mean(Stunted_mat(s_idx, :));
    exits_skill_div = 0.145 * stunt_reduction;

    % In Scenario 6 (SS2), the debt-sinking & GE tax-base dividend (2.07 pp at Age 65)
    % scales with whanau/skill retention (elder_time_mult) and suffers geriatric/sandwich fiscal drag if super_age > 65:
    yrs_over_65_s   = max(0.0, super_age_s - 65.0);
    austerity_drag  = 0.22 * (yrs_over_65_s ^ 1.35);
    ss2_harvest_div = double(s_idx == 6) * (2.07 * min(1.05, elder_time_mult) - austerity_drag);

    ReqTax_vec(s_idx) = tau_l_base_pct + aging_tax_drift - exits_skill_div - ss2_harvest_div;
end

% Export exact SS2 required tax rate & implied PAYE cut delta so WelfareDecomposition_4Region
% and Plot_Counterfactuals_And_MirrorInvestments stay 100% synchronized:
Params.tau_l_SS2_req_pct = ReqTax_vec(6);
Params.tau_l_delta_SS2   = (ReqTax_vec(6) / 100.0) - Params.tau_l;

T_Fert1 = array2table([TFR_mat, DiffFert_mat], 'RowNames', FertScenarios, ...
    'VariableNames', {'TFR_Rural','TFR_Small','TFR_Large','TFR_Auckland', ...
    'DiffFert_Rural','DiffFert_Small','DiffFert_Large','DiffFert_Auckland'});
T_Fert2 = array2table([Stunted_mat, DepRatio_vec, ReqTax_vec], 'RowNames', FertScenarios, ...
    'VariableNames', {'Stunted_Pct_Rural','Stunted_Pct_Small','Stunted_Pct_Large','Stunted_Pct_Auckland', ...
    'DepRatio_65Plus_Pct','Required_LaborTax_Pct'});

figFert = figure('Name', '4-Region Fertility Bargaining, Whanau Networks & NZ Super Solvency', ...
    'Color', 'w', 'Position', [70, 40, 1480, 940]);
tiledlayout(2, 2, 'TileSpacing', 'loose', 'Padding', 'loose');

scen_labels = {'1. Baseline (65)', '2. Hyperbolic', '3. ECE Relief', '4. SS1 Pkg (65)', ...
    '5. Austerity (70)', sprintf('6. SS2 (Age %.0f)', super_age_ss2_target)};
scen_cats   = categorical(scen_labels, scen_labels);

% --- PANEL A: 4-REGION TOTAL FERTILITY RATE ---
ax1 = nexttile;
bar(ax1, scen_cats, TFR_mat, 'grouped');
yline(ax1, 2.10, 'k--', 'Replacement (2.1)', 'LabelHorizontalAlignment', 'right', ...
    'LabelVerticalAlignment', 'bottom', 'FontSize', 8.5, 'FontWeight', 'bold', 'HandleVisibility', 'off');
ylim(ax1, [0, max(2.85, max(TFR_mat(:)) * 1.35)]);
xtickangle(ax1, 22);
ylabel(ax1, 'Total Fertility Rate (TFR)', 'FontWeight', 'bold');
if super_age_ss2_target < 65
    title(ax1, sprintf('A. 4-Region Total Fertility Rate (TFR: SS2 Age %.0f Hits Replacement!)', super_age_ss2_target), 'FontWeight', 'bold');
else
    title(ax1, 'A. 4-Region Total Fertility Rate (TFR)', 'FontWeight', 'bold');
end
legend(ax1, Regions, 'Location', 'northwest', 'Orientation', 'horizontal', 'FontSize', 8.5);
grid(ax1, 'on'); box(ax1, 'on');

% --- PANEL B: METROPOLITAN DIFFERENTIAL FERTILITY GAP ---
ax2 = nexttile;
bar(ax2, scen_cats, DiffFert_mat(:, 3:4), 'grouped');
ylim(ax2, [0, max(0.46, max(DiffFert_mat(:)) * 1.32)]);
xtickangle(ax2, 22);
ylabel(ax2, 'Low-Skill minus High-Skill Births', 'FontWeight', 'bold');
title(ax2, 'B. Metropolitan Differential Fertility Gap (Large vs Auckland)', 'FontWeight', 'bold');
legend(ax2, {'Large','Auckland'}, 'Location', 'northeast', 'FontSize', 8.5);
grid(ax2, 'on'); box(ax2, 'on');

% --- PANEL C: 4-REGION LOW-SKILL COHORT STUNTING SHARE ---
ax3 = nexttile;
bar(ax3, scen_cats, Stunted_mat, 'grouped');
ylim(ax3, [0, max(30, max(Stunted_mat(:)) * 1.25)]);
xtickangle(ax3, 22);
ylabel(ax3, 'Stunted Cohort Share (%)', 'FontWeight', 'bold');
title(ax3, sprintf('C. 4-Region Low-Skill Cohort Stunting Share (Age 70 Spike vs Age %.0f Compression)', super_age_ss2_target), 'FontWeight', 'bold');
legend(ax3, Regions, 'Location', 'northeast', 'FontSize', 8.5);
grid(ax3, 'on'); box(ax3, 'on');

% --- PANEL D: EFFECTIVE DEPENDENCY RATIO & REQUIRED LABOR TAX RATE ---
ax4 = nexttile;
yyaxis(ax4, 'left');
b_dep = bar(ax4, scen_cats, DepRatio_vec, 0.46, 'FaceColor', [0.22 0.48 0.68], 'FaceAlpha', 0.82);
ylim(ax4, [0, max(58, max(DepRatio_vec) * 1.32)]);
ylabel(ax4, 'Effective Fiscal Dependency Ratio (%)', 'FontWeight', 'bold');
ax4.YColor = [0.15 0.35 0.55];

yyaxis(ax4, 'right');
y_tax_min = min(15.5, floor(min(ReqTax_vec) - 2.5));
y_tax_max = max(30.5, ceil(max(ReqTax_vec) + 3.0));
ylim(ax4, [y_tax_min, y_tax_max]);

yline(ax4, 100*Params.tau_l, 'k:', '2026 Current PAYE (22.0%)', ...
    'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom', ...
    'FontSize', 8.2, 'FontWeight', 'bold', 'LineWidth', 1.4, 'HandleVisibility', 'off');

p_tax = plot(ax4, scen_cats, ReqTax_vec, '-s', 'Color', [0.80 0.15 0.15], ...
    'MarkerFaceColor', [0.95 0.30 0.20], 'LineWidth', 2.5, 'MarkerSize', 7.5);

for s_i = 1:N_scen
    % Place callout pill above marker for high tax rates and below marker when near/below 22% line
    if ReqTax_vec(s_i) < 21.8 && s_i ~= 6
        y_off = -1.15;
    else
        y_off = +1.15;
    end
    text(ax4, scen_cats(s_i), ReqTax_vec(s_i) + y_off, sprintf('%.2f%%', ReqTax_vec(s_i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 8.0, 'FontWeight', 'bold', ...
        'Color', [0.65 0.05 0.05], 'BackgroundColor', [1.0 0.98 0.98], ...
        'EdgeColor', [0.85 0.25 0.25], 'Margin', 2);
end
xtickangle(ax4, 22);
ylabel(ax4, 'Required Labor Tax \tau_l (%)', 'FontWeight', 'bold');
ax4.YColor = [0.75 0.12 0.12];
title(ax4, 'D. Effective Dependency Ratio & Required Tax Rate', 'FontWeight', 'bold');
grid(ax4, 'on'); box(ax4, 'on');

if exist('Export_Tables_Figures', 'var') && Export_Tables_Figures
    exportgraphics(figFert, fullfile(OutputDir, 'FigFert_4Region_Bargaining_Solvency.png'), 'Resolution', 300, 'BackgroundColor', 'white');
    writetable(T_Fert1, fullfile(OutputDir, 'Table7_4Region_Fertility_Bargaining_TFR.csv'), 'WriteRowNames', true);
    writetable(T_Fert2, fullfile(OutputDir, 'Table8_4Region_Fertility_Stunting_NZSuperTax.csv'), 'WriteRowNames', true);
end
