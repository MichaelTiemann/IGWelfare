%% MASTER RUNNER: NEW ZEALAND 4-REGION INTERGENERATIONAL WELFARE SUITE (5D TWO-EXPERIENCE-ASSET MODEL)
% File: Run_All_NZ_Intergen_Suite.m
% Regions (N_reg = 4): {'Rural' (16.0%), 'Small' (24.0%), 'Large' (25.9%), 'Auckland' (34.1%)}
% Orchestrates the unified 5D Two-Experience-Asset (h, theta_c) VFI Toolkit Mixed-Horizon pipeline:
%   Step 1: Baseline 4-Region Steady State (NZ_4Region_Master.m)
%   Step 2: Multi-Stage Childhood Counterfactuals (PolicyExperiment_LeeSeshadri_4Region.m)
%   Step 3: Endogenous Fertility & Bargaining Module (FertilityBargaining_Module.m)
%   Step 4: Optional SMM Calibration & In-Kind Imputation Check (Calibrate_NZ_Moments.m)
%   Step 5: 4-Region Welfare Decomposition (WelfareDecomposition_4Region.m)
%   Step 6: 60-Year Non-Linear Transition Path (TransPath_4Region_Master.m)

clear; clc; close all;
suite_timer = tic;

%% 0. CONFIGURATION SWITCHES & OUTPUT DIRECTORY SETUP
Force_Recompute_Cache = false; % true = Ignore cached .mat files and recompute from scratch
Run_SMM_Calibration   = false; % true = Run Sobol global pre-screening + local fminsearch SMM
Run_LeeSeshadri_Exp   = true;  % true = Run P0 vs P1/P2 & Budget-Neutral Front-Loading
Run_Fertility_Module  = true;  % true = Run Intra-Household Bargaining & Differential Fertility
Run_Transition_Path   = true;  % true = Run 60-year shooting algorithm (TransPath_4Region_Master.m)
Export_Tables_Figures = true;  % true = Save all CSV tables, 300-DPI PNGs, .fig, and .mat workspace

OutputDir = fullfile(pwd, 'Output_NZ_4Region_Intergen');
if Export_Tables_Figures && ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end

fprintf('=========================================================================================\n');
fprintf('  STARTING NEW ZEALAND 4-REGION INTERGENERATIONAL WELFARE SUITE (VFI TOOLKIT 5D)\n');
fprintf('  Regions: Rural (16.0%%) | Small (24.0%%) | Large (25.9%%) | Auckland (34.1%%)\n');
fprintf('=========================================================================================\n');

if gpuDeviceCount > 0
    gpu_info = gpuDevice;
    fprintf('GPU Detected: %s (Available Memory: %.2f GB)\n\n', ...
        gpu_info.Name, gpu_info.AvailableMemory / 1e9);
else
    warning('No CUDA GPU detected. VFI Toolkit will fall back to CPU execution.\n');
end

%% STEP 1: SOLVE BASELINE 4-REGION STEADY STATE (SS0)
fprintf('>>> [STEP 1/6] Solving Baseline 4-Region Steady State (NZ_4Region_Master.m)...\n');
step1_timer = tic;
run('NZ_4Region_Master.m');

% Preserve Baseline 5D objects ([a, h, theta_c, z, j]) across all 4 regions
V_BM              = V;
Policy_BM         = Policy;
StationaryDist_BM = StationaryDist;
jequaloneDist_BM  = jequaloneDist;
Params_BM_Master  = Params;
IG_Diag_BM        = IG_Diagnostics;
fprintf('    Step 1 completed in %.2f seconds.\n\n', toc(step1_timer));

%% STEP 2: MULTI-STAGE CHILDHOOD COUNTERFACTUALS (LEE & SESHADRI 2019 / CUNHA ET AL. 2010)
if Run_LeeSeshadri_Exp && exist('PolicyExperiment_LeeSeshadri_4Region.m', 'file')
    fprintf('>>> [STEP 2/6] Running Multi-Stage Childhood Counterfactuals across 4 Regions...\n');
    step2_timer = tic;
    run('PolicyExperiment_LeeSeshadri_4Region.m');
    fprintf('    Step 2 completed in %.2f seconds.\n\n', toc(step2_timer));
end

%% STEP 3: ENDOGENOUS FERTILITY, BARGAINING & DIFFERENTIAL FERTILITY MODULE
if Run_Fertility_Module && exist('FertilityBargaining_Module.m', 'file')
    fprintf('>>> [STEP 3/6] Running Endogenous Fertility & Bargaining Module across 4 Regions...\n');
    step3_timer    = tic;
    V              = V_BM;
    Policy         = Policy_BM;
    StationaryDist = StationaryDist_BM;
    jequaloneDist  = jequaloneDist_BM;
    Params         = Params_BM_Master;
    run('FertilityBargaining_Module.m');
    fprintf('    Step 3 completed in %.2f seconds.\n\n', toc(step3_timer));
end

%% STEP 4: OPTIONAL SMM CALIBRATION & FERRIERE ET AL. IMPUTATION WEIGHTS
V              = V_BM;
Policy         = Policy_BM;
StationaryDist = StationaryDist_BM;
jequaloneDist  = jequaloneDist_BM;
IG_Diagnostics = IG_Diag_BM;

if Run_SMM_Calibration && exist('Calibrate_NZ_Moments.m', 'file')
    fprintf('>>> [STEP 4/6] Running Calibrate_NZ_Moments.m...\n');
    step4_timer = tic;
    run('Calibrate_NZ_Moments.m');
    Params = Params_Calibrated;
    fprintf('    Step 4 completed in %.2f seconds.\n\n', toc(step4_timer));
else
    fprintf('>>> [STEP 4/6] Skipping SMM Re-Calibration.\n\n');
end

%% STEP 5: 4-REGION POLICY REFORM STEADY STATE (SS1) & WELFARE DECOMPOSITION TABLES
if exist('WelfareDecomposition_4Region.m', 'file')
    fprintf('>>> [STEP 5/6] Running 5D WelfareDecomposition_4Region.m...\n');
    step5_timer = tic;
    run('WelfareDecomposition_4Region.m');
    fprintf('    Step 5 completed in %.2f seconds.\n\n', toc(step5_timer));
end

%% STEP 6: 60-YEAR 4-REGION TRANSITION PATH ($1.6T TRANSFER & CHILD WAVE)
if Run_Transition_Path && exist('TransPath_4Region_Master.m', 'file')
    fprintf('>>> [STEP 6/6] Running 5D TransPath_4Region_Master.m (60-Year Transition Path)...\n');
    step6_timer = tic;
    run('TransPath_4Region_Master.m');
    fprintf('    Step 6 completed in %.2f seconds.\n\n', toc(step6_timer));
end

%% 7. EXPORT ALL 4-REGION TABLES (.CSV), FIGURES (.PNG/.FIG), AND WORKSPACE (.MAT)
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
    if exist('T_PopShares', 'var')
        writetable(T_PopShares, fullfile(OutputDir, 'Table9_4Region_Dynamic_Population_Shares.csv'));
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
fprintf('  4-REGION 5D SUITE EXECUTION COMPLETE! Total Runtime: %.2f minutes.\n', toc(suite_timer)/60);
fprintf('=========================================================================================\n');