%% MASTER RUNNER: NEW ZEALAND 4-REGION INTERGENERATIONAL WELFARE SUITE (5D TWO-EXPERIENCE-ASSET MODEL)
% File: Run_All_NZ_Intergen_Suite.m
% Regions (N_reg = 4): {'Rural' (16.0%), 'Small' (24.0%), 'Large' (25.9%), 'Auckland' (34.1%)} + Abroad
% Supports arbitrary model period length Params.dt (5-yr, 3-yr, or 2-yr periods).
% Orchestrates the unified 5D Two-Experience-Asset (h, theta_c) VFI Toolkit Mixed-Horizon pipeline:
%   Step 1: Baseline 4-Region Steady State (NZ_4Region_Master.m)
%   Step 2: Multi-Stage Childhood Counterfactuals (PolicyExperiment_LeeSeshadri_4Region.m)
%   Step 3: Endogenous Fertility & Bargaining Module (FertilityBargaining_Module.m)
%   Step 4: 5D -> 4D Compact Projection across 4 Regions
%   Step 5: Optional SMM Calibration & In-Kind Imputation Check (Calibrate_NZ_Moments.m)
%   Step 6: 4-Region Welfare Decomposition (WelfareDecomposition_4Region.m)
%   Step 7: 60-Year Non-Linear Transition Path (TransPath_4Region_Master.m) and other trans path plots (Opportunity Index, Actuarial Continuation Valuation)

clear; clc; close all;
suite_timer = tic;

%% 0. CONFIGURATION SWITCHES, CACHING, & OUTPUT DIRECTORY SETUP
Params.dt              = 3;     % Period length in years: 5 (J=16), 3 (J=27), or 2 (J=40)
Use_Saved_Cache        = true;  % true = Load/save per-step .mat checkpoints in CacheDir
Force_Recompute_All    = false; % true = Ignore cached .mat checkpoints and recompute all steps
Use_ExpAsset_Pipeline  = true;  % true = Full 5D Experience-Asset Lifecycle Human Capital Pipeline
Run_SMM_Calibration    = false; % true = Run Sobol global pre-screening + local fminsearch SMM
Run_LeeSeshadri_Exp    = true;  % true = Run P0 vs P1/P2 & Budget-Neutral Front-Loading (Step 2)
Run_Fertility_Module   = true;  % true = Run Intra-Household Bargaining & Differential Fertility (Step 3)
Run_Transition_Path    = true;  % true = Run 60-year shooting algorithm (TransPath_4Region_Master.m)
Export_Tables_Figures  = true;  % true = Save all CSV tables, 300-DPI PNGs, .fig, and .mat workspace

Active_Phases    = {'SS0', 'SS1', 'SS2'};
Enable_SS2_Phase = true;

Params = Configure_TimeGrid_Params(Params, Params.dt);

OutputDir = fullfile(pwd, 'Output_NZ_4Region_Intergen');
if Export_Tables_Figures && ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end

CacheDir = fullfile(pwd, 'Cache_NZ_Intergen');
if Use_Saved_Cache && ~exist(CacheDir, 'dir')
    mkdir(CacheDir);
end

fprintf('=========================================================================================\n');
fprintf('  STARTING NEW ZEALAND 4-REGION INTERGENERATIONAL WELFARE SUITE (VFI TOOLKIT 5D)\n');
fprintf('  Regions: Rural (16.0%%) | Small (24.0%%) | Large (25.9%%) | Auckland (34.1%%) + Abroad\n');
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
Cache_Step1 = fullfile(CacheDir, sprintf('Cache_Step1_Baseline5D_dt%d.mat', Params.dt));

if Use_Saved_Cache && ~Force_Recompute_All && exist(Cache_Step1, 'file')
    fprintf('    [CACHE HIT] Loading Step 1 Baseline 5D Steady State from %s...\n', Cache_Step1);
    load(Cache_Step1);
else
    run('NZ_4Region_Master.m');
    save(Cache_Step1, 'Regions', 'N_reg', 'Names_i', 'N_j', 'PTypeDistParamNames', ...
        'AgeWeightsParamNames', 'DiscountFactorParamNames', 'Reg_HH_Shares', 'Reg_Firm_Shares', ...
        'Reg_Pop_Shares', 'Params', 'V', 'Policy', 'StationaryDist', 'jequaloneDist', ...
        'n_d', 'n_a', 'n_z', 'd_grid', 'a_grid', 'z_grid', 'pi_z', 'ReturnFn', ...
        'vfoptions', 'simoptions', 'IG_Diagnostics');
    fprintf('    [CACHE SAVED] Saved Step 1 checkpoint to %s\n', Cache_Step1);
end

% Ensure Regional Extended Whanau Network K_whanau(k) is populated (even if loading older Step 1 cache)
% and connect the dots between NZ Super age (Jr vs 65), pension adequacy (p_super),
% and grandmothers'/aunties' ability to stay in their own homes (Q_reg vs baseline Q_base):
K_whanau_base = struct('HH_Rural', 0.65, 'HH_Small', 0.50, 'HH_Large', 0.30, 'HH_Auckland', 0.20);
Q_reg_base    = struct('HH_Rural', 1.05, 'HH_Small', 1.40, 'HH_Large', 2.05, 'HH_Auckland', 3.10);
super_age_eff = 20 + (Params.Jr - 1) * Params.dt;
elder_time_mult = exp(-0.09 * max(0, super_age_eff - 65)); % -9%/yr loss of grandparent time when Super age > 65
for r_idx = 1:length(Regions)
    hh_type = ['HH_', Regions{r_idx}];
    elder_home_mult = min(1.15, max(0.50, (Params.p_super / 0.18) * ((Q_reg_base.(hh_type) / Params.Q_reg.(hh_type)) ^ 0.35)));
    if ~isfield(Params, 'K_whanau') || ~isfield(Params.K_whanau, hh_type)
        Params.K_whanau.(hh_type) = K_whanau_base.(hh_type) * elder_time_mult * elder_home_mult;
    end
end

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
    Cache_Step2 = fullfile(CacheDir, sprintf('Cache_Step2_LeeSeshadri_dt%d.mat', Params.dt));
    if Use_Saved_Cache && ~Force_Recompute_All && exist(Cache_Step2, 'file')
        fprintf('    [CACHE HIT] Loading Step 2 Counterfactual Results from %s...\n', Cache_Step2);
        load(Cache_Step2);
    else
        run('PolicyExperiment_LeeSeshadri_4Region.m');
        save(Cache_Step2, 'T_IGE', 'T_VarExpl', 'T_Out', 'IGE_SR', 'IGE_LR', ...
            'VarExpl_h1', 'VarExpl_LFE', 'VarLogE', 'Ebar_SR', 'Ebar_LR', 'CE_LR', 'PolicyNames');
        fprintf('    [CACHE SAVED] Saved Step 2 checkpoint to %s\n', Cache_Step2);
    end
    fprintf('    Step 2 completed in %.2f seconds.\n\n', toc(step2_timer));
end

%% STEP 3: ENDOGENOUS FERTILITY, BARGAINING & DIFFERENTIAL FERTILITY MODULE
if Use_ExpAsset_Pipeline && Run_Fertility_Module && exist('FertilityBargaining_Module.m', 'file')
    fprintf('>>> [STEP 3/7] Running FertilityBargaining_Module.m across 4 Regions...\n');
    step3_timer = tic;
    Cache_Step3 = fullfile(CacheDir, sprintf('Cache_Step3_Fertility_dt%d.mat', Params.dt));
    if Use_Saved_Cache && ~Force_Recompute_All && exist(Cache_Step3, 'file')
        fprintf('    [CACHE HIT] Loading Step 3 Fertility Results from %s...\n', Cache_Step3);
        load(Cache_Step3);
    else
        V              = V_5D_BM;
        Policy         = Policy_5D_BM;
        StationaryDist = StationaryDist_5D_BM;
        jequaloneDist  = jequaloneDist_5D_BM;
        run('FertilityBargaining_Module.m');
        save(Cache_Step3, 'T_Fert1', 'T_Fert2', 'TFR_mat', 'DiffFert_mat', 'Stunted_mat', 'DepRatio_vec', 'ReqTax_vec');
        fprintf('    [CACHE SAVED] Saved Step 3 checkpoint to %s\n', Cache_Step3);
    end
    fprintf('    Step 3 completed in %.2f seconds.\n\n', toc(step3_timer));
end

%% STEP 4: 5D -> 4D COMPACT PROJECTION ACROSS ALL 4 REGIONS (FOR DECOMPOSITION & TRANSITION)
if Use_ExpAsset_Pipeline && exist('ReturnFn_SpatialHH_Compact4D.m', 'file')
    fprintf('>>> [STEP 4/7] Projecting 5D Experience-Asset State Space to Compact 4D across %d Regions...\n', N_reg);
    step4_timer = tic;
    Cache_Step4 = fullfile(CacheDir, sprintf('Cache_Step4_Compact4D_dt%d.mat', Params.dt));

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
            Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, K_whanau, omega_ic, ...
            delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
            tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
            j_s1_start, j_s2_end) ...
            ReturnFn_SpatialHH_Compact4D(l, Ih, ic, aprime, hprime, a, h, z, ...
            w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
            Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, K_whanau, omega_ic, ...
            delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
            tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
            j_s1_start, j_s2_end);

        jequaloneDist.(hh_type) = squeeze(sum(jequaloneDist_5D_BM.(hh_type), 3));
        jequaloneDist.(hh_type) = jequaloneDist.(hh_type) / sum(jequaloneDist.(hh_type)(:));
    end

    Params.G_ece     = Params.G_ece_stage1;
    Params.rho_hc_ig = 0.40;
    Params.gamma_ic  = 0.35;

    simoptions.d_grid = d_grid;
    simoptions.a_grid = a_grid;

    if Use_Saved_Cache && ~Force_Recompute_All && exist(Cache_Step4, 'file')
        fprintf('    [CACHE HIT] Loading Step 4 Compact 4D Baseline from %s...\n', Cache_Step4);
        load(Cache_Step4, 'V', 'Policy', 'StationaryDist', 'jequaloneDist', 'IG_Diagnostics');
    else
        [V, Policy] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
            d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions);
        StationaryDist = StationaryDist_MixHorz_PType(jequaloneDist, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, Names_i, ...
            pi_z, Params, simoptions);
        [jequaloneDist, IG_Diagnostics] = Build_IntergenTransitionMatrix( ...
            StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions);
        save(Cache_Step4, 'V', 'Policy', 'StationaryDist', 'jequaloneDist', 'IG_Diagnostics');
        fprintf('    [CACHE SAVED] Saved Step 4 checkpoint to %s\n', Cache_Step4);
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
    Cache_Step6 = fullfile(CacheDir, sprintf('Cache_Step6_Decomposition_dt%d.mat', Params.dt));
    if Use_Saved_Cache && ~Force_Recompute_All && exist(Cache_Step6, 'file')
        fprintf('    [CACHE HIT] Loading Step 6 Welfare Decomposition from %s...\n', Cache_Step6);
        load(Cache_Step6);
    else
        run('WelfareDecomposition_4Region.m');
        vars_step6 = {'T1', 'T2', 'T3', 'CE_Stage', 'CE_Quint', 'CE_Ten', ...
            'V_SS1', 'Policy_SS1', 'StatDist_SS1', 'jDist_SS1', 'Params_SS1', 'IG_Diag_SS1', ...
            'Phases', 'WelfareResults', 'Reform_Phase_Specs', 'Active_Phases'};
        if exist('V_SS2', 'var')
            vars_step6 = [vars_step6, {'V_SS2', 'Policy_SS2', 'StatDist_SS2', 'jDist_SS2', 'Params_SS2', 'IG_Diag_SS2'}];
        end
        save(Cache_Step6, vars_step6{:});
        fprintf('    [CACHE SAVED] Saved Step 6 checkpoint to %s\n', Cache_Step6);
    end
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

%% STEP 7B: 2-PANEL FERTILITY/SUPER SOLVENCY & 7-FACTOR SS2 STACKED ATTRIBUTION PLOTS
Target_Plot_Regions = {'National', 'Auckland', 'Large', 'Small', 'Rural', 'Urban'};
if ~exist('Params_SS0', 'var') && exist('Params', 'var'), Params_SS0 = Params; end
Params_SS0.Calibration_Anchor = 'Dunedin_22'; % Or 'MetroSqueeze_GUiNZ'

if exist('Plot_Fertility_SuperSolvency_2Panel.m', 'file')
    fprintf('>>> [STEP 7B] Generating 2-Panel Fertility & NZ Super Solvency Plots (Age 65 vs 67/70)...\n');
    if ~exist('T_Fert1', 'var')
        if exist('Table7_TFR', 'var'), T_Fert1 = Table7_TFR; else, T_Fert1 = []; end
    end
    if ~exist('T_Fert2', 'var')
        if exist('Table8_Super', 'var'), T_Fert2 = Table8_Super; else, T_Fert2 = []; end
    end
    Out_FertPlot = Plot_Fertility_SuperSolvency_2Panel(Params_SS0, T_Fert1, T_Fert2);
end

if exist('Plot_SS2_7Factor_StackedAttribution.m', 'file') && exist('T1', 'var')
    fprintf('>>> [STEP 7C] Generating 7-Factor SS2 Stacked Attribution Plots across %d Regions...\n', ...
        numel(Target_Plot_Regions));
    Out_AttrPlot = Plot_SS2_7Factor_StackedAttribution(T1, Params_SS0, Target_Plot_Regions);
end

%% GENERATE 10-TIER EARN + OWN WEALTH BRACKET PAIN & CELEBRATION FIGURE
if ~exist('Params_SS0', 'var') && exist('Params', 'var')
    Params_SS0 = Params;
elseif ~exist('Params_SS0', 'var')
    Params_SS0 = struct('Calibration_Anchor', 'Dunedin_22');
end
Out_WealthBrackets = Plot_WealthBracket_PainAndCelebration(Params_SS0);

% Plot Pre-Employment opportunity index
% Decomposes the pre-employment youth cohort across 4 Regions (Status Quo SS0 vs Reform SS1) into:
%   1. Stay in NZ & Attain >= Parents by Age 30 (%)
%   2. Leave NZ (Australia/OECD) & Attain >= Parents by Age 30 (%)
%   3. Stay in NZ & Do Worse Than Parents by Age 30 (%)
%   4. Leave NZ & Do Worse Than Parents by Age 30 (%) [Residual]
% Calibrates Abroad leaver outcomes using OECD / Trans-Tasman opportunity data:
%   - Real PPP wage premium in Australia/OECD at age 30: +32% (dlog_w_Abr = +0.278)
%   - Positive skill selection + deeper metro job ladders -> ~81% conditional upward attainment.
run('Plot_PreEmployment_OpportunityIndex.m');

% 1. Standard Dunedin 22% Anchor (Default):
Out_Auckland_Dunedin = Plot_ActuarialContinuationValuation([], struct('Calibration_Anchor', 'Dunedin_22'), 'Auckland');
Out_National_Dunedin = Plot_ActuarialContinuationValuation([], struct('Calibration_Anchor', 'Dunedin_22'), 'National');

% 2. Growing Up in NZ / Metro Rental Squeeze Sensitivity (~36.6% Metro Stunted):
Out_Auckland_GUiNZ   = Plot_ActuarialContinuationValuation([], struct('Calibration_Anchor', 'MetroSqueeze_GUiNZ'), 'Auckland');
Out_National_GUiNZ   = Plot_ActuarialContinuationValuation([], struct('Calibration_Anchor', 'MetroSqueeze_GUiNZ'), 'National');

Out_National_Counterfactuals = Plot_Counterfactuals_And_MirrorInvestments(Params);

%% 8. EXPORT ALL 4-REGION + ABROAD TABLES (.CSV), FIGURES (.PNG/.FIG), AND WORKSPACE (.MAT)
if Export_Tables_Figures
    fprintf('=========================================================================================\n');
    fprintf('  EXPORTING 4-REGION + ABROAD TABLES & FIGURES TO: %s\n', OutputDir);
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
    if exist('IG_Diag_5D_BM', 'var') && isfield(IG_Diag_5D_BM, 'MigrationMatrix_4x5')
        Pi_4x5    = 100 * IG_Diag_5D_BM.MigrationMatrix_4x5;
        Stunt_vec = 100 * [IG_Diag_5D_BM.StuntedShare.Rural; IG_Diag_5D_BM.StuntedShare.Small; ...
            IG_Diag_5D_BM.StuntedShare.Large; IG_Diag_5D_BM.StuntedShare.Auckland];
        Beq_vec   = [IG_Diag_5D_BM.MeanBequest.Rural; IG_Diag_5D_BM.MeanBequest.Small; ...
            IG_Diag_5D_BM.MeanBequest.Large; IG_Diag_5D_BM.MeanBequest.Auckland];
        T3B = array2table([Pi_4x5, Stunt_vec, Beq_vec], 'RowNames', Regions, ...
            'VariableNames', {'To_Rural_Pct', 'To_Small_Pct', 'To_Large_Pct', 'To_Auckland_Pct', ...
            'Emig_Abroad_Pct', 'Stunted_Cohort_Pct', 'Mean_Net_Bequest'});
        writetable(T3B, fullfile(OutputDir, 'Table3B_4Region_Abroad_SteadyState_Summary.csv'), 'WriteRowNames', true);
    end
    if exist('T_IGE', 'var')
        writetable(T_IGE,     fullfile(OutputDir, 'Table4_4Region_LeeSeshadri_IGE.csv'), 'WriteRowNames', true);
        writetable(T_Out,     fullfile(OutputDir, 'Table5_4Region_LeeSeshadri_Output_Welfare.csv'), 'WriteRowNames', true);
        writetable(T_VarExpl, fullfile(OutputDir, 'Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv'), 'WriteRowNames', true);
        writetable(T_IGE,     fullfile(OutputDir, 'Table12A_LeeSeshadri_4Region_IGE.csv'), 'WriteRowNames', true);
        writetable(T_VarExpl, fullfile(OutputDir, 'Table12B_LeeSeshadri_4Region_VarExpl.csv'), 'WriteRowNames', true);
        writetable(T_Out,     fullfile(OutputDir, 'Table12C_LeeSeshadri_4Region_Welfare.csv'), 'WriteRowNames', true);
    end
    if exist('T_Fert1', 'var')
        writetable(T_Fert1, fullfile(OutputDir, 'Table7_4Region_Endogenous_TFR_DiffFertility.csv'), 'WriteRowNames', true);
        writetable(T_Fert2, fullfile(OutputDir, 'Table8_4Region_Fertility_Stunting_NZSuperTax.csv'), 'WriteRowNames', true);
        writetable(T_Fert1, fullfile(OutputDir, 'Table_Fert1_4Region_TFR_DiffFertility.csv'), 'WriteRowNames', true);
        writetable(T_Fert2, fullfile(OutputDir, 'Table_Fert2_4Region_Stunting_NZSuper.csv'), 'WriteRowNames', true);
    end
    if exist('T_PopShares', 'var')
        writetable(T_PopShares, fullfile(OutputDir, 'Table9_4Region_Dynamic_Population_Shares.csv'));
    end
    if exist('Emig_path', 'var') && exist('Years_grid', 'var')
        T_BrainDrain = table(Years_grid, Emig_path(:,1), Emig_path(:,2), Emig_path(:,3), Emig_path(:,4), ...
            Nat_Emig_path, Cohesion_St, ...
            'VariableNames', {'Year', 'Emig_Rural_Pct', 'Emig_Small_Pct', 'Emig_Large_Pct', ...
            'Emig_Auckland_Pct', 'Nat_Emig_Abroad_Pct', 'Social_Cohesion_Index_St'});
        writetable(T_BrainDrain, fullfile(OutputDir, 'Table10_4Region_Abroad_BrainDrain_Cohesion.csv'));
    end
    save(fullfile(OutputDir, 'NZ_4Region_Intergen_Complete_Results.mat'));
    fprintf('  Saved Full Workspace Checkpoint: NZ_4Region_Intergen_Complete_Results.mat\n');
end

fprintf('\n=========================================================================================\n');
fprintf('  4-REGION + ABROAD SUITE EXECUTION COMPLETE! Total Runtime: %.2f minutes.\n', toc(suite_timer)/60);
fprintf('=========================================================================================\n');
