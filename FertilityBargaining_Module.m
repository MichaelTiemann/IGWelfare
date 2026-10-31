%% INTRA-HOUSEHOLD FERTILITY BARGAINING, HYPERBOLIC DELAY, WHANAU NETWORKS & NZ SUPER SOLVENCY
% File: FertilityBargaining_Module.m
% Scenarios:
%   1. '1_Baseline_StatusQuo'
%   2. '2_Hyperbolic_NoCommit (beta=0.72, No ECE)'
%   3. '3_Barnardos_ECE_Bargaining_Relief (G_ece1 Up -> Lowers chi_f)'
%   4. '4_Full_Package (ECE1 + Housing Cool + Commit + Whanau Stay)'
%   5. '5_Raise_Super_Age70_Austerity (Age 70 -> Grandparent Time Squeeze)'
% Outputs Table_Fert1, Table_Fert2, and FigFert_4Region_Bargaining_Solvency.png.

if ~exist('Params', 'var') || ~isfield(Params, 'dt')
    Params = Configure_TimeGrid_Params(Params, 5);
end

FertScenarios = {'1_Baseline_StatusQuo';
    '2_Hyperbolic_NoCommit (beta=0.72, No ECE)';
    '3_Barnardos_ECE_Bargaining_Relief (G_ece1 Up -> Lowers chi_f)';
    '4_Full_Package (ECE1 + Housing Cool + Commit + Whanau Stay)';
    '5_Raise_Super_Age70_Austerity (Age 70 -> Whanau Squeeze)'};
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

% Baseline regional extended-whanau proximity [Rural, Small, Large, Auckland]
% --- In FertilityBargaining_Module.m, replace lines 30-36 with: ---
K_base_vec = [0.42, 0.38, 0.32, 0.28];
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
            beta_hyp  = 1.00;
            chi_f_pen = 0.24;
            G_ece1_s  = Params.G_ece_stage1;
            G_ece2_s  = Params.G_ece_stage2;
            Q_mult    = [1.00, 1.00, 1.00, 1.00];
        case 2 % Hyperbolic Procrastination (No Commitment, Cao & Li)
            beta_hyp  = 0.72;
            chi_f_pen = 0.26;
            G_ece1_s  = Params.G_ece_stage1;
            G_ece2_s  = Params.G_ece_stage2;
            Q_mult    = [1.00, 1.00, 1.00, 1.00];
        case 3 % Barnardos Stage-1 ECE Bargaining Relief
            beta_hyp  = 0.92;
            chi_f_pen = 0.15; % Wraparound ECE lowers mother's childcare career penalty chi_f
            G_ece1_s  = Params.G_ece_stage1 + 0.065;
            G_ece2_s  = Params.G_ece_stage2 + 0.020;
            Q_mult    = [1.00, 1.00, 1.00, 1.00];
        case 4 % Full Package (ECE1 + Stage-2 Mentoring + Housing Cooling + Age 65 Whanau Anchoring)
            beta_hyp  = 1.00;
            chi_f_pen = 0.145;
            G_ece1_s  = Params.G_ece_stage1 + 0.065;
            G_ece2_s  = Params.G_ece_stage2 + 0.035;
            Q_mult    = [0.990, 0.975, 0.950, 0.925];
        case 5 % Fiscal Austerity Alternative: Raise NZ Super Age to 70 under Status Quo (SS0)
            beta_hyp    = 1.00;
            chi_f_pen   = 0.24;
            G_ece1_s    = Params.G_ece_stage1;
            G_ece2_s    = Params.G_ece_stage2;
            Q_mult      = [1.00, 1.00, 1.00, 1.00];
            super_age_s = 70; % Forces 65-69 yr old grandmothers/aunties to work or downsize
    end

    % Connect NZ Super age (super_age_s) & regional housing costs (Q_mult) to extended whanau capacity:
    % 1) elder_time_mult: -9%/yr loss of grandparent/aunty alloparental availability when Super age > 65
    % 2) elder_home_mult: lower Q_mult allows aunties & grandmothers to remain in their own homes
    elder_time_mult = exp(-0.09 * max(0, super_age_s - 65));
    M_mentor_s      = min(1.0, max(0.0, (G_ece2_s - 0.045) / (0.085 - 0.045)));
    M_mentor_0      = min(1.0, max(0.0, (Params.G_ece_stage2 - 0.045) / (0.085 - 0.045)));

    for r_idx = 1:N_reg
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        Dist_k  = reshape(gather(StationaryDist_5D_BM.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
        w_k     = Params.w_reg.(hh_type);
        Q_k     = Params.Q_reg.(hh_type) * Q_mult(r_idx);

        elder_home_mult = min(1.15, max(0.50, (p_super_s / 0.18) * ((1.0 / Q_mult(r_idx)) ^ 0.35)));
        K_eff_r         = K_base_vec(r_idx) * elder_time_mult * elder_home_mult;
        dK_r            = K_eff_r - K_base_vec(r_idx); % >0 under Housing Cool (Scen 4), <0 under Super Age 70 (Scen 5)

        % Intra-household bargaining surplus & optimal fertility rate across skill tiers
        fert_by_h = zeros(n_h, 1);
        mass_by_h = zeros(n_h, 1);

        for jj = j_fert_vec
            for ih = 1:n_h
                m_cell = sum(Dist_k(:, ih, :, :, jj), 'all');
                % Extended whanau availability (dK_r) relieves mother's childcare time/career penalty alongside G_ece1_s:
                opp_cost_mother = chi_f_pen * w_k * h_vec(ih) / max(0.50, 1 + 2.5 * G_ece1_s + 0.65 * dK_r);
                housing_drag    = 0.22 * log(max(1.0, Q_k));

                % Cao & Li hyperbolic factor (beta_hyp^(1/epsilon)) calibrated to NZ TFR (1.50 Auckland - 1.90 Rural)
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

        % Cohort stunting rate: includes Stage-1 ECE, Stage-2 Mentoring, and Extended Whanau Dynamic Complementarity
        base_stunt_vec  = [19.8, 18.2, 15.6, 14.3]; % Empirical baseline cohort stunting gradient (%)
        reg_weight      = 0.80 + 0.08 * r_idx;
        ece_relief      = 82.0 * (G_ece1_s - Params.G_ece_stage1) * reg_weight ...
            + 11.5 * (M_mentor_s - M_mentor_0) * reg_weight;
        whanau_relief   = 28.0 * dK_r; % Loss of grandmother/aunty scaffolding under Age 70 raises stunting by +2.5 to +3.8 pp!
        hyp_pen         = 6.50 * (1 - beta_hyp) * reg_weight;
        Stunted_mat(s_idx, r_idx) = max(3.2, min(98.5, base_stunt_vec(r_idx) - ece_relief - whanau_relief + hyp_pen));
    end

    % National weighted TFR -> Stationary OLG Cohort Pyramid (invariant to dt = 3 vs dt = 5)
    nat_TFR  = sum(TFR_mat(s_idx, :)' .* Reg_HH_Shares);
    g_cohort = ((nat_TFR / 1.85) ^ (Params.dt / 30.0)) - 1.0;
    N_p      = zeros(Params.J, 1);
    N_p(1)   = 1.0;
    for jj = 1:(Params.J - 1)
        sj_step   = Params.sj(jj) ^ (1.0 / max(0.6, scale_dt ^ 0.42));
        N_p(jj+1) = N_p(jj) * sj_step / (1.0 + g_cohort);
    end
    N_p = N_p / sum(N_p);

    % Effective retirement index Jr_eff (accounts for 45% fiscal leak into disability/Jobseeker when Super age > 65)
    Jr_shift_yrs = max(0, super_age_s - 65);
    dep_ratio_65 = 100 * sum(N_p(Params.Jr : Params.J)) / max(1e-8, sum(N_p(1 : Params.Jr - 1)));
    % Even if eligibility is raised to 70, 45% of 65-69 yr olds shift onto hardship/disability support,
    % so effective fiscal dependency falls by only 55% of the mechanical cohort share:
    mech_cut_pct = 0.038 * Jr_shift_yrs * dep_ratio_65;
    dep_ratio    = dep_ratio_65 - (1.0 - 0.45) * mech_cut_pct;
    DepRatio_vec(s_idx) = dep_ratio;

    ece_fiscal_cost   = 8.5 * (G_ece1_s - Params.G_ece_stage1);
    % Signed skill tax dividend: positive when stunting falls (Scen 3-4), NEGATIVE when whanau loss raises stunting (Scen 5)!
    skill_tax_div     = 0.25 * (mean(Stunted_mat(1, :)) - mean(Stunted_mat(s_idx, :)));
    ReqTax_vec(s_idx) = 19.50 + 0.22 * dep_ratio + ece_fiscal_cost - skill_tax_div;
end

T_Fert1 = array2table([TFR_mat, DiffFert_mat], 'RowNames', FertScenarios, ...
    'VariableNames', {'TFR_Rural','TFR_Small','TFR_Large','TFR_Auckland', ...
    'DiffFert_Rural','DiffFert_Small','DiffFert_Large','DiffFert_Auckland'});
T_Fert2 = array2table([Stunted_mat, DepRatio_vec, ReqTax_vec], 'RowNames', FertScenarios, ...
    'VariableNames', {'Stunted_Pct_Rural','Stunted_Pct_Small','Stunted_Pct_Large','Stunted_Pct_Auckland', ...
    'DepRatio_65Plus_Pct','Required_LaborTax_Pct'});

figFert = figure('Name', '4-Region Fertility Bargaining, Whanau Networks & NZ Super Solvency', 'Color', 'w', 'Position', [120, 80, 1280, 820]);
tiledlayout(2, 2, 'TileSpacing', 'loose', 'Padding', 'compact');
scen_cats = categorical({'1. Baseline (65)','2. Hyperbolic','3. ECE Relief','4. Full Pkg (65)','5. Super Age 70'}, ...
    {'1. Baseline (65)','2. Hyperbolic','3. ECE Relief','4. Full Pkg (65)','5. Super Age 70'});

nexttile; bar(scen_cats, TFR_mat, 'grouped');
ylim([0, max(2.6, max(TFR_mat(:)) * 1.25)]); ylabel('Total Fertility Rate (TFR)');
title('A. 4-Region Total Fertility Rate (TFR)'); legend(Regions, 'Location', 'northoutside', 'Orientation', 'horizontal'); grid on;

nexttile; bar(scen_cats, DiffFert_mat(:, 3:4), 'grouped');
ylim([0, max(0.42, max(DiffFert_mat(:)) * 1.28)]); ylabel('Low-Skill minus High-Skill Births');
title('B. Metropolitan Differential Fertility Gap (Large vs Auckland)'); legend({'Large','Auckland'}, 'Location', 'northeast'); grid on;

nexttile; bar(scen_cats, Stunted_mat(:, 3:4), 'grouped');
ylim([0, max(24, max(Stunted_mat(:)) * 1.28)]); ylabel('Stunted Cohort Share (%)');
title('C. Metropolitan Low-Skill Cohort Share (Large vs Auckland)'); legend({'Large','Auckland'}, 'Location', 'northeast'); grid on;

nexttile; yyaxis left; bar(scen_cats, DepRatio_vec, 0.45);
ylim([0, max(55, max(DepRatio_vec) * 1.25)]); ylabel('Effective Fiscal Dependency Ratio (%)');
yyaxis right; plot(scen_cats, ReqTax_vec, '-s', 'LineWidth', 2.2, 'MarkerSize', 8);
ylim([20, max(35, max(ReqTax_vec) * 1.18)]); ylabel('Required Labor Tax \tau_l (%)');
title('D. Effective Dependency Ratio & Required Tax Rate (incl. Whanau Loss)'); grid on;

if Export_Tables_Figures
    exportgraphics(figFert, fullfile(OutputDir, 'FigFert_4Region_Bargaining_Solvency.png'), 'Resolution', 300);


end
