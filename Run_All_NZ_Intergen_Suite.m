%% MASTER RUNNER: NEW ZEALAND 4-REGION INTERGENERATIONAL WELFARE SUITE (UPGRADE B)
% File: Run_All_NZ_Intergen_Suite.m
% Regions (N_reg = 4): {'Rural' (20%), 'Small' (23%), 'Large' (27%), 'Auckland' (30%)}
% Orchestrates the complete VFI Toolkit Mixed-Horizon Spatial OLG pipeline:
%   Step 1: Baseline 4-Region Steady State with Two-Stage Child CES Experience Asset
%           (NZ_4Region_Master_UpgradeB.m, ChildCES_aprimeFn.m, ReturnFn_SpatialHH_UpgradeB.m)
%   Step 2: Multi-Stage Childhood Counterfactuals: P0 vs P1/P2 & Table 12 Variance Explained
%           (PolicyExperiment_LeeSeshadri_3Region.m - auto-scales to N_reg = 4)
%   Step 3: Endogenous Fertility, Intra-Household Bargaining & Differential Fertility
%           (FertilityBargaining_Module.m - auto-scales to N_reg = 4)
%   Step 4: 5D -> 4D Compact Workspace Projection across all 4 Regions
%   Step 5: Optional SMM Calibration & In-Kind Imputation Check (Calibrate_NZ_Moments.m)
%   Step 6: 4-Region Welfare Decomposition: Daruich, Labrousse/Perdereau, Kiyotaki
%           (WelfareDecomposition_4Region.m)
%   Step 7: 60-Year Non-Linear Transition Path ($1.6T Transfer & Child Skill Wave)
%           (TransPath_4Region_Master.m)

clear; clc; close all;
suite_timer = tic;

%% 0. CONFIGURATION SWITCHES & OUTPUT DIRECTORY SETUP
Use_UpgradeB_ExpAsset  = true;  % true = Run Upgrade B (2-stage child CES experience asset theta_c)
Run_SMM_Calibration    = false; % true = Run Sobol global pre-screening + local fminsearch SMM
Run_LeeSeshadri_Exp    = true;  % true = Run P0 vs P1/P2 & Budget-Neutral Front-Loading (Step 2)
Run_Fertility_Module   = true;  % true = Run Intra-Household Bargaining & Differential Fertility (Step 3)
Run_Transition_Path    = true;  % true = Run 60-year shooting algorithm (TransPath_4Region_Master.m)
Export_Tables_Figures  = true;  % true = Save all CSV tables, 300-DPI PNGs, .fig, and .mat workspace

OutputDir = fullfile(pwd, 'Output_NZ_4Region_Intergen');
if Export_Tables_Figures && ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end

fprintf('=========================================================================================\n');
fprintf('  STARTING NEW ZEALAND 4-REGION INTERGENERATIONAL WELFARE SUITE (VFI TOOLKIT)\n');
fprintf('  Regions: Rural (20%%) | Small (23%%) | Large (27%%) | Auckland (30%%)\n');
fprintf('=========================================================================================\n');

if gpuDeviceCount > 0
    gpu_info = gpuDevice;
    fprintf('GPU Detected: %s (Available Memory: %.2f GB)\n\n', ...
        gpu_info.Name, gpu_info.AvailableMemory / 1e9);
else
    warning('No CUDA GPU detected. VFI Toolkit will fall back to CPU execution.\n');
end

%% STEP 1: SOLVE BASELINE 4-REGION STEADY STATE (SS0) & EXPERIENCE ASSET MATRIX
fprintf('>>> [STEP 1/7] Solving Baseline 4-Region Steady State (NZ_4Region_Master_UpgradeB.m)...\n');
step1_timer = tic;
run('NZ_4Region_Master_UpgradeB.m');

% Store full 5D Upgrade B objects ([a, h, theta_c, z, j]) across all 4 regions
N_reg                   = length(Regions);
V_UpgradeB_BM           = V;
Policy_UpgradeB_BM      = Policy;
StationaryDist_UpgradeB = StationaryDist;
jequaloneDist_UpgradeB  = jequaloneDist;
n_d_UpgradeB            = n_d;
n_a_UpgradeB            = n_a;
d_grid_UpgradeB         = d_grid;
a_grid_UpgradeB         = a_grid;
ReturnFn_UpgradeB       = ReturnFn;
vfoptions_UpgradeB      = vfoptions;
simoptions_UpgradeB     = simoptions;
IG_Diag_UpgradeB_BM     = IG_Diagnostics;
fprintf('    Step 1 completed in %.2f seconds.\n\n', toc(step1_timer));

%% STEP 2: MULTI-STAGE CHILDHOOD COUNTERFACTUALS (LEE & SESHADRI 2019 / CUNHA ET AL. 2010)
if Use_UpgradeB_ExpAsset && Run_LeeSeshadri_Exp && exist('PolicyExperiment_LeeSeshadri_3Region.m', 'file')
    fprintf('>>> [STEP 2/7] Running Multi-Stage Childhood Counterfactuals across 4 Regions...\n');
    step2_timer = tic;
    run('PolicyExperiment_LeeSeshadri_3Region.m');
    fprintf('    Step 2 completed in %.2f seconds.\n\n', toc(step2_timer));
end

%% STEP 3: ENDOGENOUS FERTILITY, BARGAINING & DIFFERENTIAL FERTILITY MODULE
if Use_UpgradeB_ExpAsset && Run_Fertility_Module && exist('FertilityBargaining_Module.m', 'file')
    fprintf('>>> [STEP 3/7] Running Endogenous Fertility & Bargaining Module across 4 Regions...\n');
    step3_timer = tic;
    V              = V_UpgradeB_BM;
    Policy         = Policy_UpgradeB_BM;
    StationaryDist = StationaryDist_UpgradeB;
    jequaloneDist  = jequaloneDist_UpgradeB;
    run('FertilityBargaining_Module.m');
    fprintf('    Step 3 completed in %.2f seconds.\n\n', toc(step3_timer));
end

%% STEP 4: 5D -> 4D COMPACT PROJECTION ACROSS ALL 4 REGIONS (WITH experienceasset = 1 FOR h)
if Use_UpgradeB_ExpAsset && exist('ReturnFn_SpatialHH.m', 'file')
    fprintf('>>> [STEP 4/7] Projecting 5D State Space to Compact 4D (experienceasset=1 for h) across %d Regions...\n', N_reg);
    step4_timer = tic;

    for r_idx = 1:N_reg
        hh_type = ['HH_', Regions{r_idx}];

        % In 4D compact space [a, h, z, j], Adult HC (h) is 1 Experience Asset driven by 1 decision (Ih)
        vfoptions.experienceasset.(hh_type)     = 1;
        simoptions.experienceasset.(hh_type)    = 1;
        vfoptions.l_dexperienceasset.(hh_type)  = 1;
        simoptions.l_dexperienceasset.(hh_type) = 1;

        % Put Ih LAST in n_d = [4, 7, 3] ([l, ic, Ih]) so Ih drives AdultHC_aprimeFn!
        n_d.(hh_type)    = [4, 7, 3];
        d_grid.(hh_type) = [[0; 0.5; 0.8; 1.0]; linspace(0, 0.50, 7)'; linspace(0, 0.30, 3)'];
        n_a.(hh_type)    = [n_a_UpgradeB.(hh_type)(1), n_a_UpgradeB.(hh_type)(2)]; % [61, 7]
        a_grid.(hh_type) = a_grid_UpgradeB.(hh_type)(1 : sum(n_a.(hh_type)));

        simoptions.d_grid.(hh_type) = d_grid.(hh_type);
        simoptions.a_grid.(hh_type) = a_grid.(hh_type);

        vfoptions.aprimeFn.(hh_type) = @(Ih, h, delta_hc, alpha_I, alpha_H, agej, Jr) ...
            AdultHC_aprimeFn(Ih, h, delta_hc, alpha_I, alpha_H, agej, Jr);
        simoptions.aprimeFn.(hh_type) = vfoptions.aprimeFn.(hh_type);

        ReturnFn.(hh_type) = @(l, ic, Ih, aprime, a, h, z, ...
            w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
            Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, s_sub, omega_ic, ...
            b1_beq, b2_beq, YouthGrant, tau_l, tau_c, tau_k, tau_b, agej, Jr, sj) ...
            ReturnFn_SpatialHH(l, ic, Ih, aprime, a, h, z, ...
            w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
            Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, s_sub, omega_ic, ...
            b1_beq, b2_beq, YouthGrant, tau_l, tau_c, tau_k, tau_b, agej, Jr, sj);

        jequaloneDist.(hh_type) = squeeze(sum(gather(jequaloneDist_UpgradeB.(hh_type)), 3));
        jequaloneDist.(hh_type) = jequaloneDist.(hh_type) / sum(jequaloneDist.(hh_type)(:));
    end
    Params.G_ece     = Params.G_ece_stage1;
    Params.rho_hc_ig = 0.40;
    Params.gamma_ic  = 0.35;

    vfoptions.verbose = 0; simoptions.verbose = 0;
    if ~exist('Force_Recompute_Cache', 'var'); Force_Recompute_Cache = false; end
    [cache_s4, hit_s4] = Get_ModelConfigHash('Step4_Compact4D_SS0', Params, n_d, n_a, n_z, N_j, Force_Recompute_Cache);

    if hit_s4
        fprintf('    [CACHE HIT] Loading Compact 4D Baseline from %s\n', cache_s4);
        load(cache_s4, 'V', 'Policy', 'StationaryDist');
    else
        [V, Policy] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions);
        StationaryDist = StationaryDist_MixHorz_PType(jequaloneDist, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, Names_i, ...
            pi_z, Params, simoptions);
        save(cache_s4, 'V', 'Policy', 'StationaryDist', '-v7.3');
    end
    fprintf('    Step 4 completed in %.2f seconds.\n\n', toc(step4_timer));
end

%% STEP 5: OPTIONAL SMM CALIBRATION & FERRIERE ET AL. IMPUTATION WEIGHTS
if Run_SMM_Calibration && exist('Calibrate_NZ_Moments.m', 'file')
    fprintf('>>> [STEP 5/7] Running Calibrate_NZ_Moments.m...\n');
    step5_timer = tic;
    run('Calibrate_NZ_Moments.m');
    Params = Params_Calibrated;
    fprintf('    Step 5 completed in %.2f seconds.\n\n', toc(step5_timer));
else
    fprintf('>>> [STEP 5/7] Skipping SMM Re-Calibration.\n\n');
end

%% STEP 6: 4-REGION POLICY REFORM STEADY STATE (SS1) & WELFARE DECOMPOSITION TABLES
if exist('WelfareDecomposition_4Region.m', 'file')
    fprintf('>>> [STEP 6/7] Running WelfareDecomposition_4Region.m...\n');
    step6_timer = tic;
    run('WelfareDecomposition_4Region.m');
    fprintf('    Step 6 completed in %.2f seconds.\n\n', toc(step6_timer));
end

%% STEP 7: 60-YEAR 4-REGION TRANSITION PATH ($1.6T TRANSFER & CHILD WAVE)
if Run_Transition_Path && exist('TransPath_4Region_Master.m', 'file')
    fprintf('>>> [STEP 7/7] Running TransPath_4Region_Master.m (60-Year Transition Path)...\n');
    step7_timer = tic;
    run('TransPath_4Region_Master.m');
    fprintf('    Step 7 completed in %.2f seconds.\n\n', toc(step7_timer));
end

%% 8. EXPORT ALL 4-REGION TABLES (.CSV), FIGURES (.PNG/.FIG), AND WORKSPACE (.MAT)
if Export_Tables_Figures
    fprintf('=========================================================================================\n');
    fprintf('  EXPORTING 4-REGION TABLES & FIGURES TO: %s\n', OutputDir);
    fprintf('=========================================================================================\n');

    if exist('T1', 'var')
        writetable(T1, fullfile(OutputDir, 'Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv'), 'WriteRowNames', true);
    end
    if exist('T2', 'var')
        writetable(T2, fullfile(OutputDir, 'Table2_4Region_LabroussePerdereau_SpatialQuintiles.csv'), 'WriteRowNames', true);
    end
    if exist('T3', 'var')
        writetable(T3, fullfile(OutputDir, 'Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv'), 'WriteRowNames', true);
    end
    if exist('T_IGE', 'var')
        writetable(T_IGE,     fullfile(OutputDir, 'Table4_4Region_LeeSeshadri_IGE.csv'), 'WriteRowNames', true);
        writetable(T_Out,     fullfile(OutputDir, 'Table5_4Region_LeeSeshadri_Output_Welfare.csv'), 'WriteRowNames', true);
        writetable(T_VarExpl, fullfile(OutputDir, 'Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv'), 'WriteRowNames', true);
    end
    if exist('T_Fert1', 'var')
        writetable(T_Fert1, fullfile(OutputDir, 'Table7_4Region_Endogenous_TFR_DiffFertility.csv'), 'WriteRowNames', true);
        writetable(T_Fert2, fullfile(OutputDir, 'Table8_4Region_Fertility_Stunting_NZSuperTax.csv'), 'WriteRowNames', true);
    end

    fig_handles = findall(0, 'Type', 'figure');
    for f_i = 1:length(fig_handles)
        fig_h      = fig_handles(f_i);
        fig_name   = get(fig_h, 'Name');
        clean_name = regexprep(fig_name, '[^a-zA-Z0-9_]', '_');
        clean_name = clean_name(1:min(45, length(clean_name)));
        exportgraphics(fig_h, fullfile(OutputDir, [clean_name, '.png']), 'Resolution', 300);
        savefig(fig_h, fullfile(OutputDir, [clean_name, '.fig']));
        fprintf('  Saved Figure: %s.png\n', clean_name);
    end

    save(fullfile(OutputDir, 'NZ_4Region_Intergen_Complete_Results.mat'));
    fprintf('  Saved Full Workspace Checkpoint: NZ_4Region_Intergen_Complete_Results.mat\n');
end

fprintf('\n=========================================================================================\n');
fprintf('  4-REGION SUITE EXECUTION COMPLETE! Total Runtime: %.2f minutes.\n', toc(suite_timer)/60);
fprintf('=========================================================================================\n');
