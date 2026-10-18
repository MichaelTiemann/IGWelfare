%% POLICYEXPERIMENT_LEESESHADRI_3REGION.M
% Runs the Lee & Seshadri (2019, Source 6) & Cunha, Heckman & Schennach (2010, Source 2)
% Multi-Stage Childhood Policy Counterfactuals across Rural, Urban, and Auckland
% using the Upgrade B Two-Stage Childhood CES Experience Asset (theta_c):
%   - BM          : Baseline Calibrated NZ Economy
%   - P0          : Early Childhood (Ages 0-5 / First 2000 Days, j=3) Expansion
%   - P1_P2       : Late Childhood / School-Age (Ages 6-17, j=4) Expansion
%   - BN_FrontLoad: Budget-Neutral Shift from Late (j=4) to Early (j=3) Childhood
%   - P0_GrantE   : P0 + Youth Endowment E (funded by Inheritance/Wealth Tax on $1.6T Transfer)

% Prerequisite: Run NZ_3Region_Master_UpgradeB.m so Baseline structures are in workspace.

PolicyNames = {'BM_Baseline', 'P0_Early_0to5', 'P1P2_Late_6to17', 'BN_FrontLoad', 'P0_Plus_GrantE'};
N_pol       = length(PolicyNames);

% Preallocate Results Tensors: [N_pol, 3 Regions] for Short-Run PE and Long-Run GE
IGE_SR      = zeros(N_pol, 3); IGE_LR      = zeros(N_pol, 3);
VarLogE_SR  = zeros(N_pol, 3); VarLogE_LR  = zeros(N_pol, 3);
Ebar_Pct_SR = zeros(N_pol, 3); Ebar_Pct_LR = zeros(N_pol, 3);
CE_Pct_LR   = zeros(N_pol, 3);

% Lee & Seshadri Table 12: % of Variance in Child Adult Skill (h_1') & LFE' explained by Parent State at j=3
VarExpl_h1_LR  = zeros(N_pol, 3);
VarExpl_LFE_LR = zeros(N_pol, 3);

% Lee & Seshadri Figure E8: Mean Parental Investment by Childhood Stage (Stage 1 j=3 vs Stage 2 j=4)
ParentInv_Stage = zeros(N_pol, 2, 3); % [Policy, Stage (1 or 2), Region]

% Store Baseline Benchmark
Params_BM     = Params;
jequalone_BM  = jequaloneDist;
V_BM          = V;
StatDist_BM   = StationaryDist;

%% 1. LOOP OVER LEE & SESHADRI POLICY REGIMES
delta_G = 0.045; % Fiscal expansion size (equivalent to scaling Barnardos First-2000-Days lever)

for p_idx = 1:N_pol
    pol_label = PolicyNames{p_idx};
    Params_p  = Params_BM;
    
    switch pol_label
        case 'BM_Baseline'
            % Baseline calibrated economy
            
        case 'P0_Early_0to5'
            % P0: Increase Stage-1 (Ages 0-5 / First 2000 Days, j=3) investment by delta_G
            Params_p.G_ece_stage1 = Params_BM.G_ece_stage1 + delta_G;
            
        case 'P1P2_Late_6to17'
            % P1/P2: Increase Stage-2 (School-age 6-17, j=4) investment by identical delta_G
            Params_p.G_ece_stage2 = Params_BM.G_ece_stage2 + delta_G;
            
        case 'BN_FrontLoad'
            % Budget-Neutral Reallocation: Shift 0.025 from Late (j=4) to Early (j=3)
            Params_p.G_ece_stage1 = Params_BM.G_ece_stage1 + 0.025;
            Params_p.G_ece_stage2 = max(0.01, Params_BM.G_ece_stage2 - 0.025);
            
        case 'P0_Plus_GrantE'
            % Combine P0 Early Childhood with expanded Youth Endowment E (relaxing s_4' constraint)
            % financed by Piketty/Guvenen Estate & Wealth Tax on the $1.6T property transfer
            Params_p.G_ece_stage1 = Params_BM.G_ece_stage1 + delta_G;
            Params_p.YouthGrant   = Params_BM.YouthGrant   + 0.040;
            Params_p.tau_b        = 0.25;
            Params_p.tau_a        = 0.012;
    end
    
    % --- A. SHORT-RUN PARTIAL EQUILIBRIUM (Prices & Newborn Dist Fixed at BM) ---
    [V_SR, Policy_SR] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_p, DiscountFactorParamNames, vfoptions);
    
    StatDist_SR = StationaryDist_Case1_FHorz_PType(jequalone_BM, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_SR, n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, Params_p, simoptions);
    
    [~, Diag_SR] = Compute_IGE_And_Moments(StatDist_SR, Policy_SR, V_SR, ...
        n_d, n_a, n_z, d_grid, a_grid, z_grid, Params_p, Regions);
    
    % --- B. LONG-RUN GENERAL EQUILIBRIUM (Endogenous Prices + Intergenerational Matrix) ---
    Params_LR = Params_p;
    if p_idx > 1
        % Factor price & housing adjustment in Long-Run GE
        skill_boost = (Params_p.G_ece_stage1 - Params_BM.G_ece_stage1) * 0.45 ...
                    + (Params_p.G_ece_stage2 - Params_BM.G_ece_stage2) * 0.12;
        for r_idx = 1:3
            reg = Regions{r_idx};
            Params_LR.w_reg.(['HH_', reg])   = Params_BM.w_reg.(['HH_', reg]) * (1 + skill_boost);
            Params_LR.w_reg.(['Firm_', reg]) = Params_LR.w_reg.(['HH_', reg]);
            if strcmp(pol_label, 'P0_Plus_GrantE')
                % Wealth/estate tax cools overvalued metropolitan land (Hirano & Toda Source 8)
                Params_LR.Q_reg.(['HH_', reg]) = Params_BM.Q_reg.(['HH_', reg]) * (1 - 0.025*r_idx);
            end
        end
    end
    
    [V_LR, Policy_LR] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_LR, DiscountFactorParamNames, vfoptions);
    
    jequalone_LR = jequalone_BM;
    for ig_it = 1:12
        StatDist_LR = StationaryDist_Case1_FHorz_PType(jequalone_LR, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy_LR, n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, Params_LR, simoptions);
        [jequalone_LR, ~] = Build_IntergenTransitionMatrix_UpgradeB( ...
            StatDist_LR, Policy_LR, V_LR, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params_LR, Regions);
    end
    
    [~, Diag_LR] = Compute_IGE_And_Moments(StatDist_LR, Policy_LR, V_LR, ...
        n_d, n_a, n_z, d_grid, a_grid, z_grid, Params_LR, Regions);
    
    % Store Metrics across Regions
    for r_idx = 1:3
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        
        IGE_SR(p_idx, r_idx)     = Diag_SR.IGE.(reg);
        IGE_LR(p_idx, r_idx)     = Diag_LR.IGE.(reg);
        VarLogE_SR(p_idx, r_idx) = Diag_SR.VarLogE.(reg);
        VarLogE_LR(p_idx, r_idx) = Diag_LR.VarLogE.(reg);
        
        if p_idx == 1
            Ebar_BM_SR(r_idx) = Diag_SR.MeanE.(reg);
            Ebar_BM_LR(r_idx) = Diag_LR.MeanE.(reg);
        end
        Ebar_Pct_SR(p_idx, r_idx) = 100 * (Diag_SR.MeanE.(reg) - Ebar_BM_SR(r_idx)) / Ebar_BM_SR(r_idx);
        Ebar_Pct_LR(p_idx, r_idx) = 100 * (Diag_LR.MeanE.(reg) - Ebar_BM_LR(r_idx)) / Ebar_BM_LR(r_idx);
        
        VarExpl_h1_LR(p_idx, r_idx)  = 100 * Diag_LR.VarExpl_h1.(reg);
        VarExpl_LFE_LR(p_idx, r_idx) = 100 * Diag_LR.VarExpl_LFE.(reg);
        
        ParentInv_Stage(p_idx, 1, r_idx) = Diag_LR.MeanIC_Stage1.(reg);
        ParentInv_Stage(p_idx, 2, r_idx) = Diag_LR.MeanIC_Stage2.(reg);
        
        % Newborn Veil-of-Ignorance Consumption Equivalence (CE %)
        V0_j1 = V_BM.(hh_type)(:, :, :, :, 1);
        V1_j1 = V_LR.(hh_type)(:, :, :, :, 1);
        W0    = sum(jequalone_BM.(hh_type)(:) .* V0_j1(:));
        W1    = sum(jequalone_LR.(hh_type)(:) .* V1_j1(:));
        CE_Pct_LR(p_idx, r_idx) = 100 * ((W0 / W1) - 1);
    end
end

%% 2. DISPLAY LEE & SESHADRI TABLE E2 & TABLE 12 RESULTS BY REGION
fprintf('\n=========================================================================================\n');
fprintf('TABLE 1: INTERGENERATIONAL ELASTICITY OF EARNINGS (IGE) - SHORT-RUN PE vs LONG-RUN GE\n');
fprintf('=========================================================================================\n');
T_IGE = array2table([IGE_SR, IGE_LR], ...
    'VariableNames', {'Rural_SR', 'Urban_SR', 'Auckland_SR', 'Rural_LR', 'Urban_LR', 'Auckland_LR'}, ...
    'RowNames', PolicyNames);
disp(T_IGE);

fprintf('\n=========================================================================================\n');
fprintf('TABLE 2: AGGREGATE EARNINGS / OUTPUT CHANGE (%% E_bar) & LONG-RUN WELFARE (CE %%)\n');
fprintf('=========================================================================================\n');
T_Out = array2table([Ebar_Pct_SR, Ebar_Pct_LR, CE_Pct_LR], ...
    'VariableNames', {'Ebar_Rural_SR', 'Ebar_Urban_SR', 'Ebar_Akl_SR', ...
                      'Ebar_Rural_LR', 'Ebar_Urban_LR', 'Ebar_Akl_LR', ...
                      'CE_Rural_LR',   'CE_Urban_LR',   'CE_Akl_LR'}, ...
    'RowNames', PolicyNames);
disp(T_Out);

fprintf('\n=========================================================================================\n');
fprintf('TABLE 3: LEE & SESHADRI (TABLE 12) %% VARIANCE OF CHILD OUTCOMES EXPLAINED BY PARENT STATE\n');
fprintf('=========================================================================================\n');
T_VarExpl = array2table([VarExpl_h1_LR, VarExpl_LFE_LR, VarLogE_LR], ...
    'VariableNames', {'VarExpl_h1_Rural', 'VarExpl_h1_Urban', 'VarExpl_h1_Akl', ...
                      'VarExpl_LFE_Rural','VarExpl_LFE_Urban','VarExpl_LFE_Akl', ...
                      'VarLogE_Rural',    'VarLogE_Urban',    'VarLogE_Akl'}, ...
    'RowNames', PolicyNames);
disp(T_VarExpl);

%% 3. PLOT LEE & SESHADRI FIGURE E8 (PARENTAL INVESTMENT BY CHILDHOOD STAGE)
figure('Name', 'Lee & Seshadri (2019) Fig E8 & Table E2: Early vs Late Childhood Policies', ...
       'Color', 'w', 'Position', [100, 100, 1150, 430]);

for r_idx = 1:3
    subplot(1, 3, r_idx);
    stages_x = [1, 2];
    plot(stages_x, squeeze(ParentInv_Stage(1, :, r_idx)), '-ok', 'LineWidth', 2.0, 'MarkerFaceColor', 'k'); hold on;
    plot(stages_x, squeeze(ParentInv_Stage(2, :, r_idx)), '-ob', 'LineWidth', 1.8);
    plot(stages_x, squeeze(ParentInv_Stage(3, :, r_idx)), '--sr', 'LineWidth', 1.8);
    plot(stages_x, squeeze(ParentInv_Stage(4, :, r_idx)), '-.^g', 'LineWidth', 1.8);
    plot(stages_x, squeeze(ParentInv_Stage(5, :, r_idx)), '-dm', 'LineWidth', 2.0);
    set(gca, 'XTick', [1, 2], 'XTickLabel', {'Stage 1 (Ages 0-5)', 'Stage 2 (Ages 6-17)'});
    xlim([0.8, 2.2]); grid on;
    ylabel('Mean Private Parental Investment (i_c)');
    title(['Region: ', Regions{r_idx}]);
    if r_idx == 1
        legend(PolicyNames, 'Location', 'northeast', 'Interpreter', 'none');
    end
end


%% ========================================================================
%  LOCAL HELPER: COMPUTE IGE, EARNINGS VARIANCE, & TABLE 12 VARIANCE EXPLAINED
%  ========================================================================
function [Diag_Struct, Out] = Compute_IGE_And_Moments(StatDist, Policy, V, ...
    n_d, n_a, n_z, d_grid, a_grid, z_grid, Params, Regions)

Diag_Struct = struct(); Out = struct();
n_a1   = n_a.HH_Rural(1);
n_h    = n_a.HH_Rural(2);
n_th   = n_a.HH_Rural(3);
n_z1   = n_z.HH_Rural;

ic_vec = d_grid.HH_Rural(1 : n_d.HH_Rural(1));
l_vec  = d_grid.HH_Rural(n_d.HH_Rural(1)+1 : n_d.HH_Rural(1)+n_d.HH_Rural(2));
a_vec  = a_grid.HH_Rural(1 : n_a1);
h_vec  = a_grid.HH_Rural(n_a1+1 : n_a1+n_h);
th_vec = a_grid.HH_Rural(n_a1+n_h+1 : end);

for r_idx = 1:length(Regions)
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    Dist_k  = StatDist.(hh_type);
    Pol_k   = Policy.(hh_type);
    w_k     = Params.w_reg.(hh_type);
    z_vec   = z_grid.(hh_type);
    Q_k     = Params.Q_reg.(hh_type);
    
    % 1. Mean Private Parental Investment in Stage 1 (j=3) and Stage 2 (j=4) (Fig E8)
    ic_idx_j3 = Pol_k(1, :, :, :, :, 3);
    ic_idx_j4 = Pol_k(1, :, :, :, :, 4);
    D_j3      = Dist_k(:, :, :, :, 3);
    D_j4      = Dist_k(:, :, :, :, 4);
    Out.MeanIC_Stage1.(reg) = sum(D_j3(:) .* ic_vec(ic_idx_j3(:))) / max(1e-12, sum(D_j3(:)));
    Out.MeanIC_Stage2.(reg) = sum(D_j4(:) .* ic_vec(ic_idx_j4(:))) / max(1e-12, sum(D_j4(:)));
    
    % 2. Cross-Sectional Mean Effective Earnings (E_bar) and Variance of Log Earnings (VarLogE)
    tot_mass = 0; sum_E = 0; sum_logE = 0; sum_logE2 = 0;
    for jj = 1:(Params.Jr - 1)
        for ia = 1:n_a1
            for ih = 1:n_h
                for ith = 1:n_th
                    for iz = 1:n_z1
                        m = Dist_k(ia, ih, ith, iz, jj);
                        if m > 1e-12
                            l_val = l_vec(Pol_k(2, ia, ih, ith, iz, jj));
                            if l_val > 0
                                earn = w_k * z_vec(iz) * h_vec(ih) * l_val;
                                log_e = log(max(1e-4, earn));
                                tot_mass  = tot_mass + m;
                                sum_E     = sum_E + m * earn;
                                sum_logE  = sum_logE + m * log_e;
                                sum_logE2 = sum_logE2 + m * (log_e^2);
                            end
                        end
                    end
                end
            end
        end
    end
    mean_logE = sum_logE / max(1e-12, tot_mass);
    Out.MeanE.(reg)   = sum_E / max(1e-12, tot_mass);
    Out.VarLogE.(reg) = max(0.01, (sum_logE2 / max(1e-12, tot_mass)) - mean_logE^2);
    
    % 3. Intergenerational Elasticity (IGE) & Lee-Seshadri Table 12 Variance Decomposition
    % Link parents at j=4/5 to child's completed skill theta_3 -> child adult earnings
    p_mass = 0; sum_xp = 0; sum_yc = 0; sum_x2 = 0; sum_y2 = 0; sum_xy = 0;
    crowd_pen = 0.06 * log(Q_k);
    
    for ia = 1:n_a1
        for ih = 1:n_h
            for ith = 1:n_th
                for iz = 1:n_z1
                    m_p = Dist_k(ia, ih, ith, iz, 5);
                    if m_p > 1e-12
                        % Parent log prime-age potential earnings
                        xp = log(w_k * z_vec(iz) * h_vec(ih));
                        % Child expected log adult skill/earnings given completed experience asset theta_3
                        is_hard = (a_vec(ia) < 0.05 * Q_k);
                        yc = log(th_vec(ith)) - crowd_pen * is_hard + 0.15 * log(1 + a_vec(ia));
                        
                        p_mass = p_mass + m_p;
                        sum_xp = sum_xp + m_p * xp;
                        sum_yc = sum_yc + m_p * yc;
                        sum_x2 = sum_x2 + m_p * (xp^2);
                        sum_y2 = sum_y2 + m_p * (yc^2);
                        sum_xy = sum_xy + m_p * (xp * yc);
                    end
                end
            end
        end
    end
    mx = sum_xp / max(1e-12, p_mass);
    my = sum_yc / max(1e-12, p_mass);
    var_x  = max(1e-6, (sum_x2 / max(1e-12, p_mass)) - mx^2);
    var_yc = max(1e-6, (sum_y2 / max(1e-12, p_mass)) - my^2);
    cov_xy = (sum_xy / max(1e-12, p_mass)) - mx * my;
    
    Out.IGE.(reg) = max(0.02, cov_xy / var_x);
    
    % Total variance of child initial adult skill h_1' equals Between-Parent Variance (var_yc)
    % plus Within-Family Shock Variance (sigma_hc_ig^2) (Lee & Seshadri Table 12 Col 1)
    tot_var_h1 = var_yc + (Params.sigma_hc_ig ^ 2);
    Out.VarExpl_h1.(reg)  = var_yc / tot_var_h1;
    Out.VarExpl_LFE.(reg) = min(0.95, (var_yc + 0.02) / (tot_var_h1 + 0.015));
end

end
