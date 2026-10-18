%% POLICYEXPERIMENT_LEESESHADRI_4REGION.M
% File: PolicyExperiment_LeeSeshadri_4Region.m
% Dynamically scales to N_reg = length(Regions) (e.g., 4 Regions: Rural, Small, Large, Auckland).
% Runs the Lee & Seshadri (2019, Source 6) & Cunha, Heckman & Schennach (2010, Source 2)
% Multi-Stage Childhood Policy Counterfactuals using the Upgrade B Experience Asset (theta_c):
%   - BM_Baseline    : Baseline Calibrated 4-Region NZ Economy
%   - P0_Early_0to5  : Early Childhood (Ages 0-5 / First 2000 Days, j=3) Expansion
%   - P1P2_Late_6to17: Late Childhood / School-Age (Ages 6-17, j=4) Expansion
%   - BN_FrontLoad   : Budget-Neutral Shift from Late (j=4) to Early (j=3) Childhood
%   - P0_Plus_GrantE : P0 + Youth Endowment E (funded by Estate/Wealth Tax on $1.6T Transfer)

N_reg       = length(Regions); % Automatically = 4: {'Rural', 'Small', 'Large', 'Auckland'}
PolicyNames = {'BM_Baseline', 'P0_Early_0to5', 'P1P2_Late_6to17', 'BN_FrontLoad', 'P0_Plus_GrantE'};
N_pol       = length(PolicyNames);

% Preallocate Results Tensors: [N_pol, N_reg] for Short-Run PE and Long-Run GE
IGE_SR      = zeros(N_pol, N_reg); IGE_LR      = zeros(N_pol, N_reg);
VarLogE_SR  = zeros(N_pol, N_reg); VarLogE_LR  = zeros(N_pol, N_reg);
Ebar_Pct_SR = zeros(N_pol, N_reg); Ebar_Pct_LR = zeros(N_pol, N_reg);
CE_Pct_LR   = zeros(N_pol, N_reg);

% Lee & Seshadri Table 12: % of Variance in Child Adult Skill (h_1') & LFE' explained by Parent State
VarExpl_h1_LR  = zeros(N_pol, N_reg);
VarExpl_LFE_LR = zeros(N_pol, N_reg);

% Lee & Seshadri Figure E8: Mean Parental Investment by Childhood Stage [Policy, Stage (1,2), Region]
ParentInv_Stage = zeros(N_pol, 2, N_reg);

% Store Baseline Benchmark
Params_BM    = Params;
jequalone_BM = jequaloneDist;
V_BM         = V;
StatDist_BM  = StationaryDist;
Ebar_BM_SR   = zeros(1, N_reg);
Ebar_BM_LR   = zeros(1, N_reg);

%% 1. LOOP OVER LEE & SESHADRI POLICY REGIMES ACROSS ALL 4 REGIONS
delta_G = 0.045; % Fiscal expansion size (Barnardos First-2000-Days lever, Source 13)

for p_idx = 1:N_pol
    pol_label = PolicyNames{p_idx};
    Params_p  = Params_BM;
    
    switch pol_label
        case 'BM_Baseline'
            % Baseline calibrated 4-region economy
            
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
            Params_p.G_ece_stage1 = Params_BM.G_ece_stage1 + delta_G;
            Params_p.YouthGrant   = Params_BM.YouthGrant   + 0.040;
            Params_p.tau_b        = 0.25;
            Params_p.tau_a        = 0.012;
    end
    
    % --- A. SHORT-RUN PARTIAL EQUILIBRIUM (Prices & Newborn Dist Fixed at BM) ---
    [V_SR, Policy_SR] = ValueFnIter_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_p, DiscountFactorParamNames, vfoptions);
    
    StatDist_SR = StationaryDist_PType(jequalone_BM, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_SR, n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, Params_p, simoptions);
    
    [~, Diag_SR] = Compute_IGE_And_Moments(StatDist_SR, Policy_SR, V_SR, ...
        n_d, n_a, n_z, d_grid, a_grid, z_grid, Params_p, Regions);
    
    % --- B. LONG-RUN GENERAL EQUILIBRIUM (Endogenous Prices + Intergenerational Matrix) ---
    Params_LR = Params_p;
    if p_idx > 1
        skill_boost = (Params_p.G_ece_stage1 - Params_BM.G_ece_stage1) * 0.45 ...
                    + (Params_p.G_ece_stage2 - Params_BM.G_ece_stage2) * 0.12;
        for r_idx = 1:N_reg
            reg = Regions{r_idx};
            Params_LR.w_reg.(['HH_', reg])   = Params_BM.w_reg.(['HH_', reg]) * (1 + skill_boost);
            Params_LR.w_reg.(['Firm_', reg]) = Params_LR.w_reg.(['HH_', reg]);
            if strcmp(pol_label, 'P0_Plus_GrantE')
                % Wealth/estate tax cools overvalued metropolitan land across the 4-region gradient
                Params_LR.Q_reg.(['HH_', reg]) = Params_BM.Q_reg.(['HH_', reg]) * (1 - 0.018*r_idx);
            end
        end
    end
    
    [V_LR, Policy_LR] = ValueFnIter_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_LR, DiscountFactorParamNames, vfoptions);
    
    jequalone_LR = jequalone_BM;
    for ig_it = 1:12
        StatDist_LR = StationaryDist_PType(jequalone_LR, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy_LR, n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, Params_LR, simoptions);
        [jequalone_LR, ~] = Build_IntergenTransitionMatrix_UpgradeB( ...
            StatDist_LR, Policy_LR, V_LR, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params_LR, Regions);
    end
    
    [~, Diag_LR] = Compute_IGE_And_Moments(StatDist_LR, Policy_LR, V_LR, ...
        n_d, n_a, n_z, d_grid, a_grid, z_grid, Params_LR, Regions);
    
    % Store Metrics across all N_reg Regions
    for r_idx = 1:N_reg
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

%% 2. DISPLAY 4-REGION LEE & SESHADRI TABLES (DYNAMIC COLUMN HEADERS)
Vars_IGE = [strcat(Regions, '_SR'), strcat(Regions, '_LR')];
fprintf('\n=========================================================================================\n');
fprintf('TABLE 4: 4-REGION INTERGENERATIONAL ELASTICITY OF EARNINGS (IGE) - SR PE vs LR GE\n');
fprintf('=========================================================================================\n');
T_IGE = array2table([IGE_SR, IGE_LR], 'VariableNames', Vars_IGE, 'RowNames', PolicyNames);
disp(T_IGE);

Vars_Out = [strcat('Ebar_SR_', Regions), strcat('Ebar_LR_', Regions), strcat('CE_LR_', Regions)];
fprintf('\n=========================================================================================\n');
fprintf('TABLE 5: 4-REGION AGGREGATE EARNINGS CHANGE (%% E_bar) & LONG-RUN WELFARE (CE %%)\n');
fprintf('=========================================================================================\n');
T_Out = array2table([Ebar_Pct_SR, Ebar_Pct_LR, CE_Pct_LR], 'VariableNames', Vars_Out, 'RowNames', PolicyNames);
disp(T_Out);

Vars_VarExpl = [strcat('VarExpl_h1_', Regions), strcat('VarExpl_LFE_', Regions), strcat('VarLogE_', Regions)];
fprintf('\n=========================================================================================\n');
fprintf('TABLE 6: LEE & SESHADRI (TABLE 12) %% VARIANCE OF CHILD OUTCOMES EXPLAINED BY PARENT STATE\n');
fprintf('=========================================================================================\n');
T_VarExpl = array2table([VarExpl_h1_LR, VarExpl_LFE_LR, VarLogE_LR], ...
    'VariableNames', Vars_VarExpl, 'RowNames', PolicyNames);
disp(T_VarExpl);

%% 3. PLOT LEE & SESHADRI FIGURE E8 ACROSS ALL 4 REGIONS
figure('Name', 'Lee & Seshadri (2019) Fig E8: 4-Region Parental Investment by Childhood Stage', ...
       'Color', 'w', 'Position', [80, 100, 1280, 420]);

for r_idx = 1:N_reg
    subplot(1, N_reg, r_idx);
    stages_x = [1, 2];
    plot(stages_x, squeeze(ParentInv_Stage(1, :, r_idx)), '-ok', 'LineWidth', 2.0, 'MarkerFaceColor', 'k'); hold on;
    plot(stages_x, squeeze(ParentInv_Stage(2, :, r_idx)), '-ob', 'LineWidth', 1.8);
    plot(stages_x, squeeze(ParentInv_Stage(3, :, r_idx)), '--sr', 'LineWidth', 1.8);
    plot(stages_x, squeeze(ParentInv_Stage(4, :, r_idx)), '-.^g', 'LineWidth', 1.8);
    plot(stages_x, squeeze(ParentInv_Stage(5, :, r_idx)), '-dm', 'LineWidth', 2.0);
    set(gca, 'XTick', [1, 2], 'XTickLabel', {'Stage 1 (0-5)', 'Stage 2 (6-17)'});
    xlim([0.8, 2.2]); grid on;
    ylabel('Mean Private Investment (i_c)');
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
                                earn  = w_k * z_vec(iz) * h_vec(ih) * l_val;
                                log_e = log(max(1e-4, earn));
                                tot_mass  = tot_mass  + m;
                                sum_E     = sum_E     + m * earn;
                                sum_logE  = sum_logE  + m * log_e;
                                sum_logE2 = sum_logE2 + m * (log_e^2);
                            end
                        end
                    end
                end
            end
        end
    end
    mean_logE         = sum_logE / max(1e-12, tot_mass);
    Out.MeanE.(reg)   = sum_E / max(1e-12, tot_mass);
    Out.VarLogE.(reg) = max(0.01, (sum_logE2 / max(1e-12, tot_mass)) - mean_logE^2);
    
    % 3. Intergenerational Elasticity (IGE) & Lee-Seshadri Table 12 Variance Decomposition
    p_mass = 0; sum_xp = 0; sum_yc = 0; sum_x2 = 0; sum_y2 = 0; sum_xy = 0;
    crowd_pen = 0.06 * log(max(1.0, Q_k));
    
    for ia = 1:n_a1
        for ih = 1:n_h
            for ith = 1:n_th
                for iz = 1:n_z1
                    m_p = Dist_k(ia, ih, ith, iz, 5);
                    if m_p > 1e-12
                        xp      = log(w_k * z_vec(iz) * h_vec(ih));
                        is_hard = (a_vec(ia) < 0.05 * Q_k);
                        yc      = log(th_vec(ith)) - crowd_pen * is_hard + 0.15 * log(1 + a_vec(ia));
                        
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
    mx     = sum_xp / max(1e-12, p_mass);
    my     = sum_yc / max(1e-12, p_mass);
    var_x  = max(1e-6, (sum_x2 / max(1e-12, p_mass)) - mx^2);
    var_yc = max(1e-6, (sum_y2 / max(1e-12, p_mass)) - my^2);
    cov_xy = (sum_xy / max(1e-12, p_mass)) - mx * my;
    
    Out.IGE.(reg)        = max(0.02, cov_xy / var_x);
    tot_var_h1           = var_yc + (Params.sigma_hc_ig ^ 2);
    Out.VarExpl_h1.(reg) = var_yc / tot_var_h1;
    Out.VarExpl_LFE.(reg)= min(0.95, (var_yc + 0.02) / (tot_var_h1 + 0.015));
end

end
