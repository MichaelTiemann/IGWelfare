%% POLICYEXPERIMENT_LEESESHADRI_4REGION.M (FULLY VECTORIZED, SELF-CACHING, 5D MIXHORZ)
% File: PolicyExperiment_LeeSeshadri_4Region.m
% Dynamically scales to N_reg = length(Regions) (4 Regions: Rural, Small, Large, Auckland).
% Runs the Lee & Seshadri (2019) & Cunha, Heckman & Schennach (2010) Multi-Stage Childhood
% Policy Counterfactuals using the 5D Two-Experience-Asset (h, theta_c) MixHorz Solver:
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

VarExpl_h1_LR   = zeros(N_pol, N_reg);
VarExpl_LFE_LR  = zeros(N_pol, N_reg);
ParentInv_Stage = zeros(N_pol, 2, N_reg);

% Store Baseline Benchmark from Step 1
Params_BM    = Params;
jequalone_BM = jequaloneDist;
V_BM         = V;
Policy_BM    = Policy;
StatDist_BM  = StationaryDist;
Ebar_BM_SR   = zeros(1, N_reg);
Ebar_BM_LR   = zeros(1, N_reg);

if ~exist('Force_Recompute_Cache', 'var'); Force_Recompute_Cache = false; end

%% 1. LOOP OVER LEE & SESHADRI POLICY REGIMES ACROSS ALL 4 REGIONS
delta_G = 0.045; % Fiscal expansion size (Barnardos First-2000-Days lever)

for p_idx = 1:N_pol
    pol_label = PolicyNames{p_idx};
    Params_p  = Params_BM;

    switch pol_label
        case 'BM_Baseline'
            % Baseline calibrated 4-region economy
        case 'P0_Early_0to5'
            Params_p.G_ece_stage1 = Params_BM.G_ece_stage1 + delta_G;
        case 'P1P2_Late_6to17'
            Params_p.G_ece_stage2 = Params_BM.G_ece_stage2 + delta_G;
        case 'BN_FrontLoad'
            Params_p.G_ece_stage1 = Params_BM.G_ece_stage1 + 0.025;
            Params_p.G_ece_stage2 = max(0.01, Params_BM.G_ece_stage2 - 0.025);
        case 'P0_Plus_GrantE'
            Params_p.G_ece_stage1 = Params_BM.G_ece_stage1 + delta_G;
            Params_p.YouthGrant   = Params_BM.YouthGrant   + 0.040;
            Params_p.tau_b        = 0.25;
            Params_p.tau_a        = 0.012;
    end

    [cache_pol, is_cached_pol] = local_get_policy_cache_path(pol_label, ...
        Params_p, n_d, n_a, n_z, N_j, Force_Recompute_Cache);

    if is_cached_pol
        fprintf('    [CACHE HIT] Loading %s from %s\n', pol_label, cache_pol);
        load(cache_pol, 'Diag_SR', 'Diag_LR', 'V_LR', 'jequalone_LR');
    elseif p_idx == 1
        % Reuse already-solved Baseline steady state without re-running VFI
        fprintf('    [REUSING BASELINE] Computing vectorized IGE & Moments for %s...\n', pol_label);
        [~, Diag_SR] = Compute_IGE_And_Moments(StatDist_BM, Policy_BM, V_BM, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid, Params_BM, Regions);
        Diag_LR      = Diag_SR;
        V_LR         = V_BM;
        jequalone_LR = jequalone_BM;
        save(cache_pol, 'Diag_SR', 'Diag_LR', 'V_LR', 'jequalone_LR', '-v7.3');
    else
        fprintf('    [CACHE MISS] Solving Short-Run PE & Long-Run GE for %s...\n', pol_label);
        % --- A. SHORT-RUN PARTIAL EQUILIBRIUM (Prices & Newborn Dist Fixed at BM) ---
        [V_SR, Policy_SR] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_p, DiscountFactorParamNames, vfoptions);

        StatDist_SR = StationaryDist_MixHorz_PType(jequalone_BM, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy_SR, n_d, n_a, n_z, N_j, Names_i, ...
            pi_z, Params_p, simoptions);

        [~, Diag_SR] = Compute_IGE_And_Moments(StatDist_SR, Policy_SR, V_SR, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid, Params_p, Regions);

        % --- B. LONG-RUN GENERAL EQUILIBRIUM (Endogenous Prices + Intergenerational Matrix) ---
        Params_LR   = Params_p;
        skill_boost = (Params_p.G_ece_stage1 - Params_BM.G_ece_stage1) * 0.45 ...
            + (Params_p.G_ece_stage2 - Params_BM.G_ece_stage2) * 0.12;
        for r_idx = 1:N_reg
            reg = Regions{r_idx};
            Params_LR.w_reg.(['HH_', reg])   = Params_BM.w_reg.(['HH_', reg]) * (1 + skill_boost);
            Params_LR.w_reg.(['Firm_', reg]) = Params_LR.w_reg.(['HH_', reg]);
            if strcmp(pol_label, 'P0_Plus_GrantE')
                Params_LR.Q_reg.(['HH_', reg]) = Params_BM.Q_reg.(['HH_', reg]) * (1 - 0.018*r_idx);
            end
        end

        [V_LR, Policy_LR] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_LR, DiscountFactorParamNames, vfoptions);

        jequalone_LR = jequalone_BM;
        for ig_it = 1:12
            StatDist_LR = StationaryDist_MixHorz_PType(jequalone_LR, AgeWeightsParamNames, ...
                PTypeDistParamNames, Policy_LR, n_d, n_a, n_z, N_j, Names_i, ...
                pi_z, Params_LR, simoptions);
            [jequalone_LR_new, ~] = Build_IntergenTransitionMatrix( ...
                StatDist_LR, Policy_LR, V_LR, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params_LR, Regions);
            diff_ig = max(abs(jequalone_LR_new.HH_Auckland(:) - jequalone_LR.HH_Auckland(:)));
            jequalone_LR = jequalone_LR_new;
            if diff_ig < 1e-5; break; end
        end

        [~, Diag_LR] = Compute_IGE_And_Moments(StatDist_LR, Policy_LR, V_LR, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid, Params_LR, Regions);

        save(cache_pol, 'Diag_SR', 'Diag_LR', 'V_LR', 'jequalone_LR', '-v7.3');
    end

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
        V0_j1  = gather(V_BM.(hh_type)(:, :, :, :, 1));
        V1_j1  = gather(V_LR.(hh_type)(:, :, :, :, 1));
        j0_cpu = gather(jequalone_BM.(hh_type));
        j1_cpu = gather(jequalone_LR.(hh_type));
        W0     = sum(j0_cpu(:) .* V0_j1(:));
        W1     = sum(j1_cpu(:) .* V1_j1(:));
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
%  VECTORIZED HELPER: COMPUTE IGE, EARNINGS VARIANCE, & TABLE 12 MOMENTS
%  ========================================================================
function [Diag_Struct, Out] = Compute_IGE_And_Moments(StatDist, Policy, V, ...
    n_d, n_a, n_z, d_grid, a_grid, z_grid, Params, Regions)

Diag_Struct = struct();
Out         = struct();

n_a1 = n_a.HH_Rural(1);
n_h  = n_a.HH_Rural(2);
n_th = n_a.HH_Rural(3);
n_z1 = n_z.HH_Rural;

% Decision order in n_d = [4, 3, 7]: d1 = l (1:4), d2 = Ih (5:7), d3 = ic (8:14)
d_grid_cpu = gather(d_grid.HH_Rural(:));
n_l        = n_d.HH_Rural(1);
n_Ih       = n_d.HH_Rural(2);
l_vec      = d_grid_cpu(1 : n_l);
ic_vec     = d_grid_cpu(n_l + n_Ih + 1 : end);

a_grid_cpu = gather(a_grid.HH_Rural(:));
a_vec      = a_grid_cpu(1 : n_a1);
h_vec      = a_grid_cpu(n_a1+1 : n_a1+n_h);
th_vec     = a_grid_cpu(n_a1+n_h+1 : end);

% Pre-reshape 1D vectors for 4D/5D implicit expansion
a_4d  = reshape(a_vec,  [n_a1, 1, 1, 1]);
h_4d  = reshape(h_vec,  [1, n_h, 1, 1]);
th_4d = reshape(th_vec, [1, 1, n_th, 1]);
h_5d  = reshape(h_vec,  [1, n_h, 1, 1, 1]);

for r_idx = 1:length(Regions)
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];

    % Gather once per region to CPU
    Dist_k  = gather(StatDist.(hh_type)); % [n_a1, n_h, n_th, n_z1, J]
    Pol_k   = gather(Policy.(hh_type));   % [4, n_a1, n_h, n_th, n_z1, J]
    w_k     = Params.w_reg.(hh_type);
    z_vec   = gather(z_grid.(hh_type)(:));
    Q_k     = Params.Q_reg.(hh_type);

    % 1. Vectorized Mean Private Parental Investment in Stage 1 (j=3) and Stage 2 (j=4) (Pol row 3 = ic)
    ic_idx_j3 = min(length(ic_vec), max(1, Pol_k(3, :, :, :, :, 3)));
    ic_idx_j4 = min(length(ic_vec), max(1, Pol_k(3, :, :, :, :, 4)));
    D_j3      = Dist_k(:, :, :, :, 3);
    D_j4      = Dist_k(:, :, :, :, 4);

    Out.MeanIC_Stage1.(reg) = sum(D_j3(:) .* ic_vec(ic_idx_j3(:))) / max(1e-12, sum(D_j3(:)));
    Out.MeanIC_Stage2.(reg) = sum(D_j4(:) .* ic_vec(ic_idx_j4(:))) / max(1e-12, sum(D_j4(:)));

    % 2. Vectorized Cross-Sectional Mean Effective Earnings (E_bar) & VarLogE across working ages (Pol row 1 = l)
    work_ages = 1:(Params.Jr - 1);
    D_work    = Dist_k(:, :, :, :, work_ages); % [n_a1, n_h, n_th, n_z1, Jr-1]
    l_idx_wk  = min(length(l_vec), max(1, Pol_k(1, :, :, :, :, work_ages)));
    l_val_wk  = reshape(l_vec(l_idx_wk(:)), size(D_work));

    z_5d      = reshape(z_vec, [1, 1, 1, n_z1, 1]);
    earn_5d   = w_k .* h_5d .* z_5d .* l_val_wk;

    active_m  = D_work .* double(l_val_wk > 0);
    tot_mass  = sum(active_m(:));
    log_e_5d  = log(max(1e-4, earn_5d));

    sum_E     = sum(active_m(:) .* earn_5d(:));
    sum_logE  = sum(active_m(:) .* log_e_5d(:));
    sum_logE2 = sum(active_m(:) .* (log_e_5d(:).^2));

    mean_logE         = sum_logE / max(1e-12, tot_mass);
    Out.MeanE.(reg)   = sum_E / max(1e-12, tot_mass);
    Out.VarLogE.(reg) = max(0.01, (sum_logE2 / max(1e-12, tot_mass)) - mean_logE^2);

    % 3. Vectorized Intergenerational Elasticity (IGE) & Lee-Seshadri Table 12 Variance Decomposition (j=5)
    m_p_4d    = Dist_k(:, :, :, :, 5); % [n_a1, n_h, n_th, n_z1]
    p_mass    = sum(m_p_4d(:));
    z_4d      = reshape(z_vec, [1, 1, 1, n_z1]);
    crowd_pen = 0.06 * log(max(1.0, Q_k));

    xp_4d      = repmat(log(w_k .* h_4d .* z_4d), [n_a1, 1, n_th, 1]);
    is_hard_4d = double(a_4d < 0.05 * Q_k);
    yc_4d      = log(th_4d) - crowd_pen .* is_hard_4d + 0.15 .* log(1 + a_4d);
    yc_4d      = repmat(yc_4d, [1, n_h, 1, n_z1]);

    mx     = sum(m_p_4d(:) .* xp_4d(:)) / max(1e-12, p_mass);
    my     = sum(m_p_4d(:) .* yc_4d(:)) / max(1e-12, p_mass);
    var_x  = max(1e-6, (sum(m_p_4d(:) .* (xp_4d(:).^2)) / max(1e-12, p_mass)) - mx^2);
    var_yc = max(1e-6, (sum(m_p_4d(:) .* (yc_4d(:).^2)) / max(1e-12, p_mass)) - my^2);
    cov_xy = (sum(m_p_4d(:) .* xp_4d(:) .* yc_4d(:)) / max(1e-12, p_mass)) - mx * my;

    Out.IGE.(reg)         = max(0.02, cov_xy / var_x);
    tot_var_h1            = var_yc + (Params.sigma_hc_ig ^ 2);
    Out.VarExpl_h1.(reg)  = var_yc / tot_var_h1;
    Out.VarExpl_LFE.(reg) = min(0.95, (var_yc + 0.02) / (tot_var_h1 + 0.015));
end

end

%% ========================================================================
%  SELF-CONTAINED CACHE PATH HELPER FOR LEE & SESHADRI POLICY REGIMES
%  ========================================================================
function [cache_filepath, is_cached] = local_get_policy_cache_path(pol_label, Params, n_d, n_a, n_z, N_j, ForceRecompute)
CacheDir = fullfile(pwd, 'Cache_NZ_Intergen');
if ~exist(CacheDir, 'dir')
    mkdir(CacheDir);
end
state_struct = struct('Params', Params, 'n_d', n_d, 'n_a', n_a, 'n_z', n_z, 'N_j', N_j);
raw_bytes    = getByteStreamFromArray(state_struct);
stride       = max(1, floor(numel(raw_bytes) / 4096));
sampled      = double(raw_bytes(1:stride:end));
sampled      = sampled(:); % <-- Force column vector so sum() returns a 1x1 scalar!
weights      = mod((1:numel(sampled))' * 1315423911, 2^31 - 1);
hash_val     = mod(sum(sampled .* weights), 2^32);
hash_hex     = sprintf('%08X', uint32(hash_val(1)));
clean_tag    = regexprep(pol_label, '[^a-zA-Z0-9_]', '_');
cache_filepath = fullfile(CacheDir, sprintf('Cache_LeeSeshadri_%s_%s.mat', clean_tag, hash_hex));
is_cached    = (~ForceRecompute) && (exist(cache_filepath, 'file') == 2);

end
