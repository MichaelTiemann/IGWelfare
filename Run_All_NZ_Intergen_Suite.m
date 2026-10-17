%% MASTER RUNNER: NEW ZEALAND 3-REGION INTERGENERATIONAL WELFARE SUITE
% File: Run_All_NZ_Intergen_Suite.m
% Executes the complete VFI Toolkit Mixed-Horizon Spatial OLG pipeline:
%   Step 1: Baseline 3-Region Steady State & Intergenerational Matrix (NZ_3Region_Master.m)
%   Step 2: SMM Calibration & In-Kind Imputation Check (Calibrate_NZ_Moments.m)
%   Step 3: Policy Reform & 3-Way Welfare Decomposition (WelfareDecomposition_3Region.m)
%   Step 4: Low-Opportunity vs High-Opportunity Brain-Drain Diagnostic (Opportunity_BrainDrain_Module.m)
%   Step 5: 60-Year Non-Linear Transition Path & Figure Export (TransPath_3Region_Master.m)

clear; clc; close all;
suite_timer = tic;

%% 0. CONFIGURATION SWITCHES & OUTPUT DIRECTORY SETUP
Run_SMM_Calibration   = false; % Set true to run full Sobol + fminsearch SMM parameter tuning
Export_Tables_Figures = true;  % Set true to save all CSV tables, PNG figures, and MAT workspace
OutputDir             = fullfile(pwd, 'Output_NZ_Intergen');

if Export_Tables_Figures && ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end

fprintf('=========================================================================================\n');
fprintf('  STARTING NEW ZEALAND 3-REGION INTERGENERATIONAL WELFARE SUITE (VFI TOOLKIT)\n');
fprintf('=========================================================================================\n');

% Check GPU availability for VFI Toolkit acceleration
if gpuDeviceCount > 0
    gpu_info = gpuDevice;
    fprintf('GPU Detected: %s (Memory: %.2f GB)\n', gpu_info.Name, gpu_info.AvailableMemory / 1e9);
else
    warning('No CUDA GPU detected. VFI Toolkit works best with a GPU; falling back to CPU.');
end

% Verify required suite files exist in current directory/path
RequiredFiles = { ...
    'ReturnFn_SpatialHH.m', ...
    'ReturnFn_Firm.m', ...
    'Build_IntergenTransitionMatrix.m', ...
    'NZ_3Region_Master.m', ...
    'Calibrate_NZ_Moments.m', ...
    'WelfareDecomposition_3Region.m', ...
    'Opportunity_BrainDrain_Module.m', ...
    'TransPath_3Region_Master.m'};

for f_idx = 1:length(RequiredFiles)
    if ~exist(RequiredFiles{f_idx}, 'file')
        error('Missing required file: %s. Please ensure all suite scripts are in the working directory.', ...
              RequiredFiles{f_idx});
    end
end
fprintf('All %d modular scripts verified.\n\n', length(RequiredFiles));

%% STEP 1: SOLVE BASELINE STEADY STATE (SS0) & 3x4 INTERGENERATIONAL MATRIX
fprintf('>>> [STEP 1/5] Running NZ_3Region_Master.m (Baseline Steady State SS0)...\n');
step1_timer = tic;
run('NZ_3Region_Master.m');
fprintf('    Step 1 completed in %.2f seconds.\n\n', toc(step1_timer));

%% STEP 2: OPTIONAL SMM CALIBRATION & FERRIERE ET AL. IMPUTATION WEIGHTS
if Run_SMM_Calibration
    fprintf('>>> [STEP 2/5] Running Calibrate_NZ_Moments.m (Sobol Pre-Screening + SMM)...\n');
    step2_timer = tic;
    run('Calibrate_NZ_Moments.m');
    % Update baseline Params with calibrated vector
    Params = Params_Calibrated;
    fprintf('    Step 2 completed in %.2f seconds.\n\n', toc(step2_timer));
else
    fprintf('>>> [STEP 2/5] Skipping full SMM optimization (using pre-calibrated parameters in Params).\n');
    fprintf('               (Set Run_SMM_Calibration = true in Run_All_NZ_Intergen_Suite.m to re-estimate.)\n\n');
end

%% STEP 3: POLICY REFORM STEADY STATE (SS1) & WELFARE DECOMPOSITION TABLES
% Note: BecauseNZ_3Region_Master.m clears workspace at its top if run standalone,
% we ensure config flags persist across scripts.
Export_Tables_Figures = true;
OutputDir             = fullfile(pwd, 'Output_NZ_Intergen');

fprintf('>>> [STEP 3/5] Running WelfareDecomposition_3Region.m (PE vs GE & Spatial Quintiles)...\n');
step3_timer = tic;
run('WelfareDecomposition_3Region.m');
fprintf('    Step 3 completed in %.2f seconds.\n\n', toc(step3_timer));

%% STEP 4: STATIC LOW-OPPORTUNITY vs. HIGH-OPPORTUNITY BRAIN DRAIN COMPARISON
fprintf('>>> [STEP 4/5] Running Opportunity_BrainDrain_Module.m (Brain Drain & Social Cohesion)...\n');
step4_timer = tic;
run('Opportunity_BrainDrain_Module.m');
fprintf('    Step 4 completed in %.2f seconds.\n\n', toc(step4_timer));

%% STEP 5: 60-YEAR TRANSITION PATH ($1.6T TRANSFER, CHILD WAVE & BRAIN DRAIN CLOSURE)
fprintf('>>> [STEP 5/5] Running TransPath_3Region_Master.m (60-Year Transition Path)...\n');
step5_timer = tic;
run('TransPath_3Region_Master.m');
fprintf('    Step 5 completed in %.2f seconds.\n\n', toc(step5_timer));

%% 6. EXPORT ALL TABLES (.CSV), FIGURES (.PNG/.FIG), AND WORKSPACE (.MAT)
if Export_Tables_Figures
    fprintf('=========================================================================================\n');
    fprintf('  EXPORTING PUBLICATION TABLES & FIGURES TO: %s\n', OutputDir);
    fprintf('=========================================================================================\n');
    
    % Export Tables to CSV (including RowNames)
    if exist('T1', 'var')
        writetable(T1, fullfile(OutputDir, 'Table1_Daruich_LeeSeshadri_Decomposition.csv'), 'WriteRowNames', true);
    end
    if exist('T2', 'var')
        writetable(T2, fullfile(OutputDir, 'Table2_LabroussePerdereau_SpatialQuintiles.csv'), 'WriteRowNames', true);
    end
    if exist('T3', 'var')
        writetable(T3, fullfile(OutputDir, 'Table3_Kiyotaki_TenureGenerationalCleavage.csv'), 'WriteRowNames', true);
    end
    if exist('T_Opportunity', 'var')
        writetable(T_Opportunity, fullfile(OutputDir, 'Table4_Low_vs_High_Opportunity_BrainDrain.csv'));
    end
    if exist('T_BrainDrain_Path', 'var')
        writetable(T_BrainDrain_Path, fullfile(OutputDir, 'Table5_TransitionPath_BrainDrain_SocialCohesion.csv'));
    end
    if exist('T_Params', 'var')
        writetable(T_Params, fullfile(OutputDir, 'TableA_Calibrated_Parameters.csv'));
        writetable(T_Moments, fullfile(OutputDir, 'TableB_Calibration_Moment_Fit.csv'));
        writetable(T_Impute, fullfile(OutputDir, 'TableC_Ferriere_InKind_Imputation_Weights.csv'), 'WriteRowNames', true);
    end
    
    % Export all open Figures as high-resolution PNG (300 DPI) and MATLAB .fig
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
    
    % Save converged steady states & transition trajectories to .mat checkpoint
    save(fullfile(OutputDir, 'NZ_Intergen_Suite_Results.mat'), ...
        'Params_Base', 'Params_GE', 'V_Base', 'V_GE_Endo', ...
        'StatDist_Base', 'StatDist_GE_Endo', 'IG_Diag_Base', 'IG_Diag_Reform', ...
        'T1', 'T2', 'T3', 'T_Opportunity', 'T_BrainDrain_Path', ...
        'CE_Cohort_Path', 'IRF_HousePrice', 'IRF_RentalPrice', 'IRF_EstateFlow');
    fprintf('  Saved Workspace Checkpoint: NZ_Intergen_Suite_Results.mat\n');
end

fprintf('\n=========================================================================================\n');
fprintf('  SUITE EXECUTION COMPLETE! Total Runtime: %.2f minutes.\n', toc(suite_timer)/60);
fprintf('=========================================================================================\n');
