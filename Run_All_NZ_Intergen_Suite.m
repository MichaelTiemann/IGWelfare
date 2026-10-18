%% MASTER RUNNER: NEW ZEALAND 4-REGION INTERGENERATIONAL WELFARE SUITE (5D TWO-EXPERIENCE-ASSET MODEL)
% File: Run_All_NZ_Intergen_Suite.m
% Regions (N_reg = 4): {'Rural' (16.0%), 'Small' (24.0%), 'Large' (25.9%), 'Auckland' (34.1%)}
% Supports arbitrary model period length Params.dt (5-yr, 3-yr, or 2-yr periods).
% Orchestrates the unified 5D Two-Experience-Asset (h, theta_c) VFI Toolkit Mixed-Horizon pipeline:
%   Step 1: Baseline 4-Region Steady State (NZ_4Region_Master.m)
%   Step 2: Multi-Stage Childhood Counterfactuals (PolicyExperiment_LeeSeshadri_4Region.m)
%   Step 3: Endogenous Fertility & Bargaining Module (FertilityBargaining_Module.m)
%   Step 4: Optional SMM Calibration & In-Kind Imputation Check (Calibrate_NZ_Moments.m)
%   Step 5: 4-Region Welfare Decomposition (WelfareDecomposition_4Region.m)
%   Step 6: 60-Year Non-Linear Transition Path (TransPath_4Region_Master.m)
% Parameterized by period length dt (in years):
%   dt = 5 -> J = 16, Jr = 10, T_trans = 12 (Default 5-year benchmark)
%   dt = 3 -> J = 27, Jr = 16, T_trans = 20 (Granular 3-year benchmark)
%   dt = 2 -> J = 40, Jr = 23, T_trans = 30 (High-res 2-year benchmark)

clear; clc; close all;
suite_timer = tic;

%% 0. CONFIGURATION SWITCHES & OUTPUT DIRECTORY SETUP
Params.dt              = 5;     % Period length in years: 5 (J=16), 3 (J=27), or 2 (J=40)
Use_ExpAsset_Pipeline  = true;  % true = Full 5D Experience-Asset Lifecycle Human Capital Pipeline
Run_SMM_Calibration    = false; % true = Run Sobol global pre-screening + local fminsearch SMM
Run_LeeSeshadri_Exp    = true;  % true = Run P0 vs P1/P2 & Budget-Neutral Front-Loading (Step 2)
Run_Fertility_Module   = true;  % true = Run Intra-Household Bargaining & Differential Fertility (Step 3)
Run_Transition_Path    = true;  % true = Run 60-year shooting algorithm (TransPath_4Region_Master.m)
Export_Tables_Figures  = true;  % true = Save all CSV tables, 300-DPI PNGs, .fig, and .mat workspace

Params = Configure_TimeGrid_Params(Params, Params.dt);

OutputDir = fullfile(pwd, 'Output_NZ_4Region_Intergen');
if Export_Tables_Figures && ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end

fprintf('=========================================================================================\n');
fprintf('  STARTING NEW ZEALAND 4-REGION INTERGENERATIONAL WELFARE SUITE (VFI TOOLKIT 5D)\n');
fprintf('  Regions: Rural (16.0%%) | Small (24.0%%) | Large (25.9%%) | Auckland (34.1%%)\n');
fprintf('  Time Grid: dt = %d yrs | Horizon J = %d (Ages 20-99) | Retirement Jr = %d (Age 65)\n', Params.dt, Params.J, Params.Jr);
fprintf('=========================================================================================\n');

if gpuDeviceCount > 0
    gpu_info = gpuDevice;
    fprintf('GPU Detected: %s (Available Memory: %.2f GB)\n\n', ...
        gpu_info.Name, gpu_info.AvailableMemory / 1e9);
else
    warning('No CUDA GPU detected. VFI Toolkit will fall back to CPU execution.\n');
end

%% STEP 1: SOLVE BASELINE 4-REGION STEADY STATE (SS0) & LIFECYCLE EXPERIENCE ASSET
fprintf('>>> [STEP 1/7] Solving Baseline 4-Region Steady State (NZ_4Region_Master.m)...\n');
step1_timer = tic;
run('NZ_4Region_Master.m');

% Store full 5D Baseline objects ([a, h, theta_c, z, j]) across all 4 regions
N_reg                   = length(Regions);
V_5D_BM                 = V;
Policy_5D_BM            = Policy;
StationaryDist_5D_BM    = StationaryDist;
jequaloneDist_5D_BM     = jequaloneDist;
n_d_5D                  = n_d;
n_a_5D                  = n_a;
d_grid_5D               = d_grid;
a_grid_5D               = a_grid;
ReturnFn_5D             = ReturnFn;
vfoptions_5D            = vfoptions;
simoptions_5D           = simoptions;
IG_Diag_5D_BM           = IG_Diagnostics;
fprintf('    Step 1 completed in %.2f seconds.\n\n', toc(step1_timer));

%% STEP 2: MULTI-STAGE CHILDHOOD COUNTERFACTUALS (LEE & SESHADRI 2019 / CUNHA ET AL. 2010)
if Use_ExpAsset_Pipeline && Run_LeeSeshadri_Exp && exist('PolicyExperiment_LeeSeshadri_4Region.m', 'file')
    fprintf('>>> [STEP 2/7] Running PolicyExperiment_LeeSeshadri_4Region.m across 4 Regions...\n');
    step2_timer = tic;
    run('PolicyExperiment_LeeSeshadri_4Region.m');
    fprintf('    Step 2 completed in %.2f seconds.\n\n', toc(step2_timer));
end

%% STEP 3: ENDOGENOUS FERTILITY, BARGAINING & DIFFERENTIAL FERTILITY MODULE
if Use_ExpAsset_Pipeline && Run_Fertility_Module && exist('FertilityBargaining_Module.m', 'file')
    fprintf('>>> [STEP 3/7] Running FertilityBargaining_Module.m across 4 Regions...\n');
    step3_timer = tic;
    V              = V_5D_BM;
    Policy         = Policy_5D_BM;
    StationaryDist = StationaryDist_5D_BM;
    jequaloneDist  = jequaloneDist_5D_BM;
    run('FertilityBargaining_Module.m');
    fprintf('    Step 3 completed in %.2f seconds.\n\n', toc(step3_timer));
end

%% STEP 4: 5D -> 4D COMPACT PROJECTION ACROSS ALL 4 REGIONS (FOR DECOMPOSITION & TRANSITION)
if Use_ExpAsset_Pipeline && exist('ReturnFn_SpatialHH_Compact4D.m', 'file')
    fprintf('>>> [STEP 4/7] Projecting 5D Experience-Asset State Space to Compact 4D across %d Regions...\n', N_reg);
    step4_timer = tic;
    if isfield(vfoptions, 'aprimeFn');  vfoptions  = rmfield(vfoptions, 'aprimeFn');  end
    if isfield(simoptions, 'aprimeFn'); simoptions = rmfield(simoptions, 'aprimeFn'); end

    for r_idx = 1:N_reg
        hh_type = ['HH_', Regions{r_idx}];

        vfoptions.experienceasset.(hh_type)  = 0;
        simoptions.experienceasset.(hh_type) = 0;

        n_d.(hh_type)    = [4, 3, 7];
        d_grid.(hh_type) = [[0; 0.5; 0.8; 1.0]; linspace(0, 0.30, 3)'; linspace(0, 0.50, 7)'];
        n_a.(hh_type)    = [n_a_5D.(hh_type)(1), n_a_5D.(hh_type)(2)];
        a_grid.(hh_type) = a_grid_5D.(hh_type)(1 : sum(n_a.(hh_type)));

        ReturnFn.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, ...
            w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
            Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, omega_ic, ...
            delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
            tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
            j_s1_start, j_s2_end) ...
            ReturnFn_SpatialHH_Compact4D(l, Ih, ic, aprime, hprime, a, h, z, ...
            w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
            Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, omega_ic, ...
            delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
            tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
            j_s1_start, j_s2_end);

        jequaloneDist.(hh_type) = squeeze(sum(jequaloneDist_5D_BM.(hh_type), 3));
        jequaloneDist.(hh_type) = jequaloneDist.(hh_type) / sum(jequaloneDist.(hh_type)(:));
    end
    Params.G_ece     = Params.G_ece_stage1;
    Params.rho_hc_ig = 0.40;
    Params.gamma_ic  = 0.35;

    [V, Policy] = ValueFnIter_Case1_FHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions);
    StationaryDist = StationaryDist_Case1_FHorz_PType(jequaloneDist, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, Params, simoptions);
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

%% STEP 7: 60-YEAR 4-REGION + ABROAD TRANSITION PATH ($1.6T TRANSFER & CHILD WAVE)
if Run_Transition_Path && exist('TransPath_4Region_Master.m', 'file')
    fprintf('>>> [STEP 7/7] Running TransPath_4Region_Master.m (%d-Year Transition, %d Steps)...\n', ...
        Params.T_trans_years, Params.T_trans);
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
        writetable(T_IGE,     fullfile(OutputDir, 'Table12A_LeeSeshadri_4Region_IGE.csv'), 'WriteRowNames', true);
        writetable(T_VarExpl, fullfile(OutputDir, 'Table12B_LeeSeshadri_4Region_VarExpl.csv'), 'WriteRowNames', true);
        writetable(T_Out,     fullfile(OutputDir, 'Table12C_LeeSeshadri_4Region_Welfare.csv'), 'WriteRowNames', true);
    end
    if exist('T_Fert1', 'var')
        writetable(T_Fert1, fullfile(OutputDir, 'Table_Fert1_4Region_TFR_DiffFertility.csv'), 'WriteRowNames', true);
        writetable(T_Fert2, fullfile(OutputDir, 'Table_Fert2_4Region_Stunting_NZSuper.csv'), 'WriteRowNames', true);
    end
    if exist('T_PopShares', 'var')
        writetable(T_PopShares, fullfile(OutputDir, 'Table9_4Region_Dynamic_Population_Shares.csv'));
    end

    save(fullfile(OutputDir, 'NZ_4Region_Intergen_Complete_Results.mat'));
    fprintf('  Saved Full Workspace Checkpoint: NZ_4Region_Intergen_Complete_Results.mat\n');
end

fprintf('\n=========================================================================================\n');
fprintf('  4-REGION + ABROAD SUITE EXECUTION COMPLETE! Total Runtime: %.2f minutes.\n', toc(suite_timer)/60);
fprintf('=========================================================================================\n');
