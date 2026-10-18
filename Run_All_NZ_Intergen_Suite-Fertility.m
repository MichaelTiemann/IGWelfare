%% MASTER RUNNER: NEW ZEALAND 3-REGION INTERGENERATIONAL WELFARE SUITE (UPGRADE B)
% File: Run_All_NZ_Intergen_Suite.m
% Orchestrates the complete 11-file VFI Toolkit Mixed-Horizon Spatial OLG pipeline:
%   Step 1: Baseline 3-Region Steady State with Two-Stage Child CES Experience Asset
%           (NZ_3Region_Master_UpgradeB.m, ChildCES_aprimeFn.m, ReturnFn_SpatialHH_UpgradeB.m)
%   Step 2: Optional SMM Calibration & In-Kind Imputation Check (Calibrate_NZ_Moments.m)
%   Step 3: 3-Way Welfare Decomposition: Daruich, Labrousse/Perdereau, Kiyotaki
%           (WelfareDecomposition_3Region.m)
%   Step 4: Multi-Stage Childhood Counterfactuals: P0 vs P1/P2 & Table 12 Variance Explained
%           (PolicyExperiment_LeeSeshadri_3Region.m)
%   Step 5: Endogenous Fertility, Intra-Household Bargaining & Differential Fertility
%           (FertilityBargaining_Module.m)
%   Step 6: Low-Opportunity vs High-Opportunity Brain-Drain Diagnostic
%           (Opportunity_BrainDrain_Module.m - if present)
%   Step 7: 60-Year Non-Linear Transition Path ($1.6T Transfer, Child Wave & Brain Drain)
%           (TransPath_3Region_Master.m)

clear; clc; close all;
suite_timer = tic;

%% 0. CONFIGURATION SWITCHES & OUTPUT DIRECTORY SETUP
Use_UpgradeB_ExpAsset  = true;  % true = Run Upgrade B (2-stage child CES experience asset theta_c)
Run_SMM_Calibration    = false; % true = Run Sobol global pre-screening + local fminsearch SMM
Run_LeeSeshadri_Exp    = true;  % true = Run P0 vs P1/P2 & Budget-Neutral Front-Loading (Step 4)
Run_Fertility_Module   = true;  % true = Run Intra-Household Bargaining & Differential Fertility (Step 5)
Run_BrainDrain_Static  = false; % true = Run standalone Opportunity_BrainDrain_Module.m if in folder
Run_Transition_Path    = true;  % true = Run 60-year shooting algorithm (TransPath_3Region_Master.m)
Export_Tables_Figures  = true;  % true = Save all CSV tables, 300-DPI PNGs, .fig, and .mat workspace

OutputDir = fullfile(pwd, 'Output_NZ_Intergen');
if Export_Tables_Figures && ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end

fprintf('=========================================================================================\n');
fprintf('  STARTING NEW ZEALAND 3-REGION INTERGENERATIONAL WELFARE SUITE (VFI TOOLKIT)\n');
fprintf('=========================================================================================\n');

% Check GPU availability for VFI Toolkit acceleration
if gpuDeviceCount > 0
    gpu_info = gpuDevice;
    fprintf('GPU Detected: %s (Available Memory: %.2f GB)\n', ...
            gpu_info.Name, gpu_info.AvailableMemory / 1e9);
else
    warning('No CUDA GPU detected. VFI Toolkit will fall back to CPU execution.');
end

% Verify required core files based on Upgrade B switch
if Use_UpgradeB_ExpAsset
    CoreFiles = { ...
        'ChildCES_aprimeFn.m', ...
        'ReturnFn_SpatialHH_UpgradeB.m', ...
        'ReturnFn_Firm.m', ...
        'Build_IntergenTransitionMatrix_UpgradeB.m', ...
        'NZ_3Region_Master_UpgradeB.m'};
else
    CoreFiles = { ...
        'ReturnFn_SpatialHH.m', ...
        'ReturnFn_Firm.m', ...
        'Build_IntergenTransitionMatrix.m', ...
        'NZ_3Region_Master.m'};
end

for f_idx = 1:length(CoreFiles)
    if ~exist(CoreFiles{f_idx}, 'file')
        error('Missing required core file: %s. Ensure all suite scripts are on the MATLAB path.', ...
              CoreFiles{f_idx});
    end
end
fprintf('All %d core model files verified.\n\n', length(CoreFiles));

%% STEP 1: SOLVE BASELINE STEADY STATE (SS0) & TWO-STAGE EXPERIENCE ASSET MATRIX
fprintf('>>> [STEP 1/7] Solving Baseline 3-Region Steady State (SS0)...\n');
step1_timer = tic;

if Use_UpgradeB_ExpAsset
    % Note: Ensure 'clear; clc; close all;' at top of NZ_3Region_Master_UpgradeB.m is commented out
    run('NZ_3Region_Master_UpgradeB.m');
    
    % Store full 5D Upgrade B objects ([a, h, theta_c, z, j]) for Steps 4 & 5
    V_UpgradeB_BM             = V;
    Policy_UpgradeB_BM        = Policy;
    StationaryDist_UpgradeB   = StationaryDist;
    jequaloneDist_UpgradeB    = jequaloneDist;
    n_d_UpgradeB              = n_d;
    n_a_UpgradeB              = n_a;
    d_grid_UpgradeB           = d_grid;
    a_grid_UpgradeB           = a_grid;
    ReturnFn_UpgradeB         = ReturnFn;
    vfoptions_UpgradeB        = vfoptions;
    simoptions_UpgradeB       = simoptions;
    IG_Diag_UpgradeB_BM       = IG_Diagnostics;
else
    run('NZ_3Region_Master.m');
end
fprintf('    Step 1 completed in %.2f seconds.\n\n', toc(step1_timer));

%% STEP 2: MULTI-STAGE CHILDHOOD COUNTERFACTUALS (LEE & SESHADRI 2019 / CUNHA ET AL. 2010)
if Use_UpgradeB_ExpAsset && Run_LeeSeshadri_Exp && exist('PolicyExperiment_LeeSeshadri_3Region.m', 'file')
    fprintf('>>> [STEP 2/7] Running PolicyExperiment_LeeSeshadri_3Region.m (P0 vs P1/P2 & Table 12)...\n');
    step2_timer = tic;
    run('PolicyExperiment_LeeSeshadri_3Region.m');
    fprintf('    Step 2 completed in %.2f seconds.\n\n', toc(step2_timer));
else
    fprintf('>>> [STEP 2/7] Skipping Lee & Seshadri Multi-Stage Experiment.\n\n');
end

%% STEP 3: ENDOGENOUS FERTILITY, BARGAINING & DIFFERENTIAL FERTILITY MODULE
if Use_UpgradeB_ExpAsset && Run_Fertility_Module && exist('FertilityBargaining_Module.m', 'file')
    fprintf('>>> [STEP 3/7] Running FertilityBargaining_Module.m (Bargaining, Hyperbolic & NZ Super)...\n');
    step3_timer = tic;
    % Restore baseline Upgrade B objects in case Step 2 modified workspace variables
    V              = V_UpgradeB_BM;
    Policy         = Policy_UpgradeB_BM;
    StationaryDist = StationaryDist_UpgradeB;
    jequaloneDist  = jequaloneDist_UpgradeB;
    run('FertilityBargaining_Module.m');
    fprintf('    Step 3 completed in %.2f seconds.\n\n', toc(step3_timer));
else
    fprintf('>>> [STEP 3/7] Skipping Endogenous Fertility & Bargaining Module.\n\n');
end

%% STEP 4: COMPATIBILITY PROJECTION FOR 4D SCRIPTS (CALIBRATION, DECOMPOSITION & TRANSITION)
% WelfareDecomposition_3Region.m, Calibrate_NZ_Moments.m, and TransPath_3Region_Master.m
% index V and StationaryDist as 4D arrays [a, h, z, j]. If Upgrade B (5D [a, h, theta_c, z, j])
% is active, we project/marginalize over the experience asset theta_c (dimension 3)
% or solve the compact 4D representation so Steps 5-7 run seamlessly.
if Use_UpgradeB_ExpAsset && exist('ReturnFn_SpatialHH.m', 'file')
    fprintf('>>> [STEP 4/7] Preparing 4D Compact Workspace for Calibration, Decomposition & 60-Yr Transition...\n');
    step4_timer = tic;
    for r_idx = 1:3
        hh_type   = ['HH_', Regions{r_idx}];
        firm_type = ['Firm_', Regions{r_idx}];
        
        vfoptions.experienceasset.(hh_type)  = 0;
        simoptions.experienceasset.(hh_type) = 0;
        if isfield(vfoptions, 'aprimeFn');  vfoptions  = rmfield(vfoptions, 'aprimeFn');  end
        if isfield(simoptions, 'aprimeFn'); simoptions = rmfield(simoptions, 'aprimeFn'); end
        
        n_d.(hh_type)    = [4, 3, 7];
        d_grid.(hh_type) = [[0; 0.5; 0.8; 1.0]; linspace(0, 0.30, 3)'; linspace(0, 0.50, 7)'];
        n_a.(hh_type)    = [n_a_UpgradeB.(hh_type)(1), n_a_UpgradeB.(hh_type)(2)];
        a_grid.(hh_type) = a_grid_UpgradeB.(hh_type)(1 : sum(n_a.(hh_type)));
        
        ReturnFn.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, ...
            w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
            Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, omega_ic, ...
            delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
            tau_l, tau_c, tau_k, tau_b, agej, Jr, sj) ...
            ReturnFn_SpatialHH(l, Ih, ic, aprime, hprime, a, h, z, ...
            w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
            Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, omega_ic, ...
            delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
            tau_l, tau_c, tau_k, tau_b, agej, Jr, sj);
        
        % Marginalize Upgrade B 4D newborn distribution [a, h, theta_c, z] -> 3D [a, h, z]
        jequaloneDist.(hh_type) = squeeze(sum(jequaloneDist_UpgradeB.(hh_type), 3));
        jequaloneDist.(hh_type) = jequaloneDist.(hh_type) / sum(jequaloneDist.(hh_type)(:));
    end
    Params.G_ece     = Params.G_ece_stage1;
    Params.rho_hc_ig = 0.40;
    Params.gamma_ic  = 0.35;
    
    [V, Policy] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions);
    StationaryDist = StationaryDist_Case1_FHorz_PType(jequaloneDist, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, Params, simoptions);
    fprintf('    Step 4 completed in %.2f seconds.\n\n', toc(step4_timer));
end

%% STEP 5: OPTIONAL SMM CALIBRATION & FERRIERE ET AL. IMPUTATION WEIGHTS
if Run_SMM_Calibration && exist('Calibrate_NZ_Moments.m', 'file')
    fprintf('>>> [STEP 5/7] Running Calibrate_NZ_Moments.m (Sobol Pre-Screening + SMM)...\n');
    step5_timer = tic;
    run('Calibrate_NZ_Moments.m');
    Params = Params_Calibrated;
    fprintf('    Step 5 completed in %.2f seconds.\n\n', toc(step5_timer));
else
    fprintf('>>> [STEP 5/7] Skipping SMM Re-Calibration (using calibrated parameter vector in Params).\n\n');
end

%% STEP 6: POLICY REFORM STEADY STATE (SS1) & 3-WAY WELFARE DECOMPOSITION TABLES
if exist('WelfareDecomposition_3Region.m', 'file')
    fprintf('>>> [STEP 6/7] Running WelfareDecomposition_3Region.m (PE vs GE & Spatial Quintiles)...\n');
    step6_timer = tic;
    run('WelfareDecomposition_3Region.m');
    fprintf('    Step 6 completed in %.2f seconds.\n\n', toc(step6_timer));
end

if Run_BrainDrain_Static && exist('Opportunity_BrainDrain_Module.m', 'file')
    fprintf('>>> [STEP 6B/7] Running Opportunity_BrainDrain_Module.m...\n');
    run('Opportunity_BrainDrain_Module.m');
end

%% STEP 7: 60-YEAR TRANSITION PATH ($1.6T TRANSFER, CHILD WAVE & BRAIN DRAIN CLOSURE)
if Run_Transition_Path && exist('TransPath_3Region_Master.m', 'file')
    fprintf('>>> [STEP 7/7] Running TransPath_3Region_Master.m (60-Year Non-Linear Transition Path)...\n');
    step7_timer = tic;
    run('TransPath_3Region_Master.m');
    fprintf('    Step 7 completed in %.2f seconds.\n\n', toc(step7_timer));
end

%% 8. EXPORT ALL TABLES (.CSV), FIGURES (.PNG/.FIG), AND WORKSPACE (.MAT)
if Export_Tables_Figures
    fprintf('=========================================================================================\n');
    fprintf('  EXPORTING PUBLICATION TABLES & FIGURES TO: %s\n', OutputDir);
    fprintf('=========================================================================================\n');
    
    % 1. Welfare Decomposition Tables (Step 6)
    if exist('T1', 'var')
        writetable(T1, fullfile(OutputDir, 'Table1_Daruich_LeeSeshadri_Decomposition.csv'), 'WriteRowNames', true);
    end
    if exist('T2', 'var')
        writetable(T2, fullfile(OutputDir, 'Table2_LabroussePerdereau_SpatialQuintiles.csv'), 'WriteRowNames', true);
    end
    if exist('T3', 'var')
        writetable(T3, fullfile(OutputDir, 'Table3_Kiyotaki_TenureGenerationalCleavage.csv'), 'WriteRowNames', true);
    end
    
    % 2. Multi-Stage Childhood Policy Counterfactual Tables (Step 2)
    if exist('T_IGE', 'var')
        writetable(T_IGE,     fullfile(OutputDir, 'Table4_LeeSeshadri_IGE_ShortRun_vs_LongRun.csv'), 'WriteRowNames', true);
        writetable(T_Out,     fullfile(OutputDir, 'Table5_LeeSeshadri_Output_and_Welfare_ByStage.csv'), 'WriteRowNames', true);
        writetable(T_VarExpl, fullfile(OutputDir, 'Table6_LeeSeshadri_Table12_VarianceExplained.csv'), 'WriteRowNames', true);
    end
    
    % 3. Endogenous Fertility, Bargaining & NZ Super Sustainability Tables (Step 3)
    if exist('T_Fert1', 'var')
        writetable(T_Fert1, fullfile(OutputDir, 'Table7_Endogenous_TFR_and_DifferentialFertility.csv'), 'WriteRowNames', true);
        writetable(T_Fert2, fullfile(OutputDir, 'Table8_Fertility_Stunting_and_NZSuper_Tax.csv'), 'WriteRowNames', true);
    end
    
    % 4. Brain Drain & 60-Year Transition Path Tables (Step 7)
    if exist('T_Opportunity', 'var')
        writetable(T_Opportunity, fullfile(OutputDir, 'Table9_Low_vs_High_Opportunity_BrainDrain.csv'));
    end
    if exist('T_BrainDrain_Path', 'var')
        writetable(T_BrainDrain_Path, fullfile(OutputDir, 'Table10_TransitionPath_BrainDrain_SocialCohesion.csv'));
    end
    
    % 5. SMM Calibration & Ferriere et al. In-Kind Imputation Tables (Step 5)
    if exist('T_Params', 'var')
        writetable(T_Params,  fullfile(OutputDir, 'TableA_Calibrated_Parameters.csv'));
        writetable(T_Moments, fullfile(OutputDir, 'TableB_Calibration_Moment_Fit.csv'));
        writetable(T_Impute,  fullfile(OutputDir, 'TableC_Ferriere_InKind_Imputation_Weights.csv'), 'WriteRowNames', true);
    end
    
    % 6. Export all open Figures as 300-DPI PNG and MATLAB .fig
    fig_handles = findall(0, 'Type', 'figure');
    for f_i = 1:length(fig_handles)
        fig_h    = fig_handles(f_i);
        fig_name = get(fig_h, 'Name');
        if isempty(fig_name)
            clean_name = sprintf('Figure_%d', f_i);
        else
            clean_name = regexprep(fig_name, '[^a-zA-Z0-9_]', '_');
            clean_name = regexprep(clean_name, '_+', '_');
            clean_name = clean_name(1:min(45, length(clean_name)));
        end
        png_path = fullfile(OutputDir, [clean_name, '.png']);
        fig_path = fullfile(OutputDir, [clean_name, '.fig']);
        exportgraphics(fig_h, png_path, 'Resolution', 300);
        savefig(fig_h, fig_path);
        fprintf('  Saved Figure: %s.png\n', clean_name);
    end
    
    % 7. Save Master Workspace Checkpoint (.mat)
    save(fullfile(OutputDir, 'NZ_Intergen_Suite_Complete_Results.mat'));
    fprintf('  Saved Full Workspace Checkpoint: NZ_Intergen_Suite_Complete_Results.mat\n');
end

fprintf('\n=========================================================================================\n');
fprintf('  SUITE EXECUTION COMPLETE! Total Runtime: %.2f minutes.\n', toc(suite_timer)/60);
fprintf('=========================================================================================\n');
