%% MASTER RUNNER: NEW ZEALAND 4-REGION INTERGENERATIONAL WELFARE SUITE (5D TWO-EXPERIENCE-ASSET MODEL)
% File: Run_All_NZ_Intergen_Suite.m
% Regions (N_reg = 4): {'Rural' (16.0%), 'Small' (24.0%), 'Large' (25.9%), 'Auckland' (34.1%)} + Abroad
% Supports arbitrary model period length Params.dt (5-yr, 3-yr, or 2-yr periods).
% Orchestrates the unified 5D Two-Experience-Asset (h, theta_c) VFI Toolkit Mixed-Horizon pipeline:
%   Step 1: Baseline 4-Region Steady State (NZ_4Region_Master.m)
%   Step 2: Multi-Stage Childhood Counterfactuals (PolicyExperiment_LeeSeshadri_4Region.m)
%   Step 3: Endogenous Fertility & Bargaining Module (FertilityBargaining_Module.m)
%   Step 4: Canonical 5D Workspace Restore for Downstream Modules (Compact4D Retired)
%   Step 5: Optional SMM Calibration & In-Kind Imputation Check (Calibrate_NZ_Moments.m)
%   Step 6: 4-Region Welfare Decomposition (WelfareDecomposition_4Region.m)
%   Step 7: 60-Year Non-Linear Transition Path (TransPath_4Region_Master.m) and other trans path plots (Opportunity Index, Actuarial Continuation Valuation)

% Preserve optional command-line overrides across workspace clear:
if exist('Force_Recompute_All', 'var'), cmd_Force_Recompute = Force_Recompute_All; end
if exist('Use_Saved_Cache', 'var'),     cmd_Use_Cache       = Use_Saved_Cache;     end
if exist('Profile_Name', 'var'),        cmd_Profile_Name    = Profile_Name;        end
if exist('Params', 'var') && isstruct(Params)
    if isfield(Params, 'Enable_Duopoly_Kai'), cmd_Enable_Duopoly_Kai = Params.Enable_Duopoly_Kai; end
    if isfield(Params, 'dt'),                 cmd_dt                 = Params.dt;                 end
    if isfield(Params, 'n_workers'),          cmd_n_workers          = Params.n_workers;          end
    if isfield(Params, 'Profile_Name'),       cmd_Profile_Name       = Params.Profile_Name;       end
    if ~exist('cmd_Profile_Name', 'var') && isfield(Params, 'Calibration_Anchor')
        cmd_Profile_Name = Params.Calibration_Anchor;
    end
    if isfield(Params, 'Rollout_Mode'),       cmd_Rollout_Mode       = Params.Rollout_Mode;       end
    if isfield(Params, 'Contingency_Policy'), cmd_Contingency_Policy = Params.Contingency_Policy; end
end

clearvars -except cmd_Force_Recompute cmd_Use_Cache cmd_Enable_Duopoly_Kai cmd_dt cmd_n_workers ...
                  cmd_Profile_Name cmd_Rollout_Mode cmd_Contingency_Policy;
clc; close all;
suite_timer = tic;

% Initialize modular IGWelfare paths regardless of working directory
this_suite_dir = fileparts(mfilename('fullpath'));
if exist(fullfile(this_suite_dir, 'setup_igw_paths.m'), 'file') == 2
    igw_root_dir = setup_igw_paths(true);
elseif exist(fullfile(this_suite_dir, '..', 'setup_igw_paths.m'), 'file') == 2
    addpath(fullfile(this_suite_dir, '..'));
    igw_root_dir = setup_igw_paths(true);
else
    igw_root_dir = pwd;
end

%% 0. THREE-LAYER DATA/POLICY CONFIGURATION, CACHING, & OUTPUT DIRECTORY SETUP
if exist('cmd_Profile_Name', 'var'),       Params.Profile_Name = cmd_Profile_Name;   else, Params.Profile_Name = 'NZ_Dunedin1972'; end
if exist('cmd_Rollout_Mode', 'var'),       Params.Rollout_Mode = cmd_Rollout_Mode;   else, Params.Rollout_Mode = 'TeKahuiWaka';    end
if exist('cmd_Contingency_Policy', 'var'), Params.Contingency_Policy = cmd_Contingency_Policy; else, Params.Contingency_Policy = 'fixed_calendar_2050'; end
if exist('cmd_dt', 'var'),                 Params.dt = cmd_dt;                       else, Params.dt = 3;                          end
if exist('cmd_n_workers', 'var'),          Params.n_workers = cmd_n_workers;         end
if exist('cmd_Enable_Duopoly_Kai', 'var'), Params.Enable_Duopoly_Kai = cmd_Enable_Duopoly_Kai;                                     end
if exist('cmd_Use_Cache', 'var'),          Use_Saved_Cache = cmd_Use_Cache;          else, Use_Saved_Cache = true;                 end
if exist('cmd_Force_Recompute', 'var'),    Force_Recompute_All = cmd_Force_Recompute; else, Force_Recompute_All = false;           end
clear cmd_Force_Recompute cmd_Use_Cache cmd_Enable_Duopoly_Kai cmd_dt cmd_n_workers ...
      cmd_Profile_Name cmd_Rollout_Mode cmd_Contingency_Policy;

Use_ExpAsset_Pipeline  = true;  % true = Full 5D Experience-Asset Lifecycle Human Capital Pipeline
Run_SMM_Calibration    = false; % true = Run Sobol global pre-screening + local fminsearch SMM
Run_LeeSeshadri_Exp    = true;  % true = Run P0 vs P1/P2 & Budget-Neutral Front-Loading (Step 2)
Run_Fertility_Module   = true;  % true = Run Intra-Household Bargaining & Differential Fertility (Step 3)
Run_Transition_Path    = true;  % true = Run 60-year shooting algorithm (TransPath_4Region_Master.m)
Export_Tables_Figures  = true;  % true = Save all CSV tables, 300-DPI PNGs, .fig, and .mat workspace

Active_Phases    = {'SS0', 'SS1', 'SS2'};
Enable_SS2_Phase = true;

Params = Configure_Model_Params(Params, Params.dt);

%% COMPUTE BACKEND & WORKER POOL PROVISIONING (SINGLE-SOURCE CONTRACT)
req_w = [];
if isfield(Params, 'n_workers'), req_w = Params.n_workers; end
SuiteBackend = Resolve_Compute_Backend(struct('EnsureWorkerPool', true, 'n_workers', req_w));
if SuiteBackend.IsOctave
    Params.n_workers = SuiteBackend.n_workers;
end

OutputDir = fullfile(igw_root_dir, 'output', Params.Profile_ID);
if Export_Tables_Figures && ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end
setappdata(0, 'IGW_OUTPUT_DIR', OutputDir);

CacheDir = fullfile(igw_root_dir, 'cache', Params.Profile_ID);
Params.Cache_Dir = CacheDir;
if Use_Saved_Cache && ~exist(CacheDir, 'dir')
    mkdir(CacheDir);
end
if Force_Recompute_All && exist(CacheDir, 'dir')
    delete(fullfile(CacheDir, '*.mat'));
    fprintf('    [CLEAN STATE] Force_Recompute_All = true: Cleared all cached .mat files in %s\n', CacheDir);
end
Force_Recompute_All = false; % Auto-consume one-shot flag so subsequent/resumed runs never re-wipe cache

fprintf('=========================================================================================\n');

% Three-tier cache validity keys (Get_ModelConfigHash + Validate_CacheConfig):
%   - Cache_CfgHash        (SS0_*)     : Steps 1-4 Baseline SS0 (invariant to Rollout_Mode & Contingency_Policy!)
%   - Cache_ReformCfgHash  (SSReform_*): Step 6 Reform SS1/SS2  (invariant to Contingency_Policy & wave timing!)
%   - Cache_TransCfgHash   (Trans_*)   : Step 7+ Transition/VaR (hashes full 3-layer stack)
Cache_CfgHash       = '';
Cache_ReformCfgHash = '';
Cache_TransCfgHash  = '';
if Use_Saved_Cache
    Cache_CfgHash       = regexp(Get_ModelConfigHash('SS0_RunAll_Params',      Params, [], [], [], []), '[0-9a-f]{32}(?=\.mat$)', 'match', 'once');
    Cache_ReformCfgHash = regexp(Get_ModelConfigHash('SSReform_RunAll_Params', Params, [], [], [], []), '[0-9a-f]{32}(?=\.mat$)', 'match', 'once');
    Cache_TransCfgHash  = regexp(Get_ModelConfigHash('Trans_RunAll_Params',    Params, [], [], [], []), '[0-9a-f]{32}(?=\.mat$)', 'match', 'once');
end

reg_summary_parts = arrayfun(@(i) sprintf('%s (%.1f%%)', Params.Regions{i}, 100*Params.Pop_Weights_4(i)), ...
    1:Params.N_reg, 'UniformOutput', false);
fprintf('=========================================================================================\n');
fprintf('  STARTING INTERGENERATIONAL WELFARE SUITE [%s | %s | %s]\n', ...
    Params.Profile_ID, Params.Rollout_Mode, Params.Contingency_Policy_ID);
fprintf('  Regions: %s + %s\n', strjoin(reg_summary_parts, ' | '), Params.External_Dest_Label);
fprintf('  Time Grid: dt = %d yrs | Horizon J = %d (Ages 20-99) | Retirement Jr = %d (Age %.0f)\n', ...
    Params.dt, Params.J, Params.Jr, Params.Super_Age_Base);
fprintf('=========================================================================================\n');

if SuiteBackend.UseGPU
    fprintf('Compute Backend: %s (%s | Available Memory: %.2f GB)\n\n', ...
        SuiteBackend.Mode, SuiteBackend.DeviceName, SuiteBackend.MemoryGB);
else
    fprintf('Compute Backend: %s (%s)\n\n', SuiteBackend.Mode, SuiteBackend.DeviceName);
end

%% STEP 1: SOLVE BASELINE 4-REGION STEADY STATE (SS0) & LIFECYCLE EXPERIENCE ASSET
fprintf('>>> [STEP 1/7] Solving Baseline 4-Region Steady State (NZ_4Region_Master.m)...\n');
step1_timer = tic;
Cache_Step1 = fullfile(CacheDir, sprintf('Cache_Step1_Baseline5D_dt%d_nz%d.mat', Params.dt, Params.n_z_pts));

if Use_Saved_Cache && ~Force_Recompute_All && exist(Cache_Step1, 'file') && Validate_CacheConfig(Cache_Step1, Cache_CfgHash)
    fprintf('    [CACHE HIT] Loading Step 1 Baseline 5D Steady State from %s...\n', Cache_Step1);
    load(Cache_Step1);
else
    run(which('NZ_4Region_Master.m'));
    save(Cache_Step1, 'Regions', 'N_reg', 'Names_i', 'N_j', 'PTypeDistParamNames', ...
        'AgeWeightsParamNames', 'DiscountFactorParamNames', 'Reg_HH_Shares', 'Reg_Firm_Shares', ...
        'Reg_Pop_Shares', 'Params', 'V', 'Policy', 'StationaryDist', 'jequaloneDist', ...
        'n_d', 'n_a', 'n_z', 'd_grid', 'a_grid', 'z_grid', 'pi_z', 'ReturnFn', ...
        'vfoptions', 'simoptions', 'IG_Diagnostics', 'Cache_CfgHash');
    fprintf('    [CACHE SAVED] Saved Step 1 checkpoint to %s\n', Cache_Step1);
end

% Ensure Regional Extended Whanau Network K_whanau(k) and Section 7 structs are synchronized with Single Source of Truth:
Params = Configure_Model_Params(Params, Params.dt);
super_age_eff   = 20 + (Params.Jr - 1) * Params.dt;
elder_time_mult = exp(-0.09 * max(0, super_age_eff - 65)); % -9%/yr loss of grandparent time when Super age > 65
for r_idx = 1:length(Regions)
    hh_type = ['HH_', Regions{r_idx}];
    elder_home_mult = min(1.15, max(0.50, (Params.p_super / 0.18) * ((Params.Q_reg_base.(hh_type) / Params.Q_reg.(hh_type)) ^ 0.35)));
    Params.K_whanau.(hh_type) = Params.K_whanau_base.(hh_type) * elder_time_mult * elder_home_mult;
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
    if Use_Saved_Cache && ~Force_Recompute_All && exist(Cache_Step2, 'file') && Validate_CacheConfig(Cache_Step2, Cache_CfgHash)
        fprintf('    [CACHE HIT] Loading Step 2 Counterfactual Results from %s...\n', Cache_Step2);
        load(Cache_Step2);
        [T_IGE, T_VarExpl, T_Out] = IGW_Restore_Tables(T_IGE, T_VarExpl, T_Out);
    else
        run(which('PolicyExperiment_LeeSeshadri_4Region.m'));
        old_warn = warning('query', 'all');
        warning('off', 'all');
        save(Cache_Step2, 'T_IGE', 'T_VarExpl', 'T_Out', 'IGE_SR', 'IGE_LR', ...
            'VarExpl_h1', 'VarExpl_LFE', 'VarLogE', 'Ebar_SR', 'Ebar_LR', 'CE_LR', 'PolicyNames', 'Cache_CfgHash');
        warning(old_warn);
        fprintf('    [CACHE SAVED] Saved Step 2 checkpoint to %s\n', Cache_Step2);
    end
    fprintf('    Step 2 completed in %.2f seconds.\n\n', toc(step2_timer));
end

%% STEP 3: ENDOGENOUS FERTILITY, BARGAINING & DIFFERENTIAL FERTILITY MODULE
if Use_ExpAsset_Pipeline && Run_Fertility_Module && exist('FertilityBargaining_Module.m', 'file')
    fprintf('>>> [STEP 3/7] Running FertilityBargaining_Module.m across 4 Regions...\n');
    step3_timer = tic;
    Cache_Step3 = fullfile(CacheDir, sprintf('Cache_Step3_Fertility_dt%d.mat', Params.dt));
    if Use_Saved_Cache && ~Force_Recompute_All && exist(Cache_Step3, 'file') && Validate_CacheConfig(Cache_Step3, Cache_CfgHash) ...
            && ~isempty(whos('-file', Cache_Step3, 'FertOut'))
        fprintf('    [CACHE HIT] Loading Step 3 Fertility Results from %s...\n', Cache_Step3);
        load(Cache_Step3);
        [T_Fert1, T_Fert2, T_UCurve] = IGW_Restore_Tables(T_Fert1, T_Fert2, T_UCurve);
        FertOut.T_Fert1  = T_Fert1;
        FertOut.T_Fert2  = T_Fert2;
        FertOut.T_UCurve = T_UCurve;
        Params.tau_l_SS2_req_pct = FertOut.tau_l_SS2_req_pct;
        Params.tau_l_delta_SS2   = FertOut.tau_l_delta_SS2;
    else
        V                    = V_5D_BM;
        Policy               = Policy_5D_BM;
        StationaryDist       = StationaryDist_5D_BM;
        jequaloneDist        = jequaloneDist_5D_BM;
        Defer_Fertility_Plot = true; % Defer Panel D CE% anchoring & PNG/CSV export until Step 6 solves T1
        run(which('FertilityBargaining_Module.m'));
        Defer_Fertility_Plot = false;
        old_warn = warning('query', 'all');
        warning('off', 'all');
        save(Cache_Step3, 'FertOut', 'T_Fert1', 'T_Fert2', 'T_UCurve', 'TFR_mat', 'DiffFert_mat', ...
            'Struggling_mat', 'DepRatio_vec', 'ReqTax_vec', 'Cache_CfgHash');
        warning(old_warn);
        fprintf('    [CACHE SAVED] Saved Step 3 checkpoint to %s\n', Cache_Step3);
    end
    fprintf('    Step 3 completed in %.2f seconds.\n\n', toc(step3_timer));
end

%% STEP 4: RESTORE CANONICAL 5D WORKSPACE FOR DECOMPOSITION & TRANSITION (COMPACT4D RETIRED)
fprintf('>>> [STEP 4/7] Restoring Canonical 5D Experience-Asset State Space across %d Regions...\n\n', N_reg);
V              = V_5D_BM;
Policy         = Policy_5D_BM;
StationaryDist = StationaryDist_5D_BM;
jequaloneDist  = jequaloneDist_5D_BM;
n_d            = n_d_5D;
n_a            = n_a_5D;
d_grid         = d_grid_5D;
a_grid         = a_grid_5D;
ReturnFn       = ReturnFn_5D;
vfoptions      = vfoptions_5D;
simoptions     = simoptions_5D;
IG_Diagnostics = IG_Diag_5D_BM;
Params.G_ece   = Params.G_ece_stage1;

%% STEP 5: OPTIONAL SMM CALIBRATION & FERRIERE ET AL. IMPUTATION WEIGHTS
if Run_SMM_Calibration && exist('Calibrate_NZ_Moments.m', 'file')
    fprintf('>>> [STEP 5/7] Running Calibrate_NZ_Moments.m...\n');
    step5_timer = tic;
    run(which('Calibrate_NZ_Moments.m'));
    Params = Params_Calibrated;
    fprintf('    Step 5 completed in %.2f seconds.\n\n', toc(step5_timer));
else
    fprintf('>>> [STEP 5/7] Skipping SMM Re-Calibration.\n\n');
end

%% STEP 6: 4-REGION POLICY REFORM STEADY STATE (SS1) & WELFARE DECOMPOSITION TABLES
if exist('WelfareDecomposition_4Region.m', 'file')
    fprintf('>>> [STEP 6/7] Running WelfareDecomposition_4Region.m...\n');
    step6_timer = tic;
    Cache_Step6 = fullfile(CacheDir, sprintf('Cache_Step6_Decomposition5D_%s_dt%d.mat', Params.Rollout_Mode, Params.dt));
    if Use_Saved_Cache && ~Force_Recompute_All && exist(Cache_Step6, 'file') && Validate_CacheConfig(Cache_Step6, Cache_ReformCfgHash)
        fprintf('    [CACHE HIT] Loading Step 6 Welfare Decomposition from %s...\n', Cache_Step6);
        load(Cache_Step6);
        Cache_CfgHash = regexp(Get_ModelConfigHash('SS0_RunAll_Params', Params, [], [], [], []), '[0-9a-f]{32}(?=\.mat$)', 'match', 'once');
        [T1, T2, T3, WelfareResults] = IGW_Restore_Tables(T1, T2, T3, WelfareResults);
    else
        run(which('WelfareDecomposition_4Region.m'));
        ss0_hash_keep = Cache_CfgHash;
        Cache_CfgHash = Cache_ReformCfgHash;
        vars_step6 = {'T1', 'T2', 'T3', 'CE_Stage', 'CE_Quint', 'CE_Ten', ...
            'V_SS1', 'Policy_SS1', 'StatDist_SS1', 'jDist_SS1', 'Params_SS1', 'IG_Diag_SS1', ...
            'Phases', 'WelfareResults', 'Reform_Phase_Specs', 'Active_Phases', 'Cache_CfgHash'};
        if exist('V_SS2', 'var')
            vars_step6 = [vars_step6, {'V_SS2', 'Policy_SS2', 'StatDist_SS2', 'jDist_SS2', 'Params_SS2', 'IG_Diag_SS2'}];
        end
        old_warn = warning('query', 'all');
        warning('off', 'all');
        save(Cache_Step6, vars_step6{:});
        Cache_CfgHash = ss0_hash_keep;
        warning(old_warn);
        fprintf('    [CACHE SAVED] Saved Step 6 checkpoint to %s\n', Cache_Step6);
    end
    fprintf('    Step 6 completed in %.2f seconds.\n\n', toc(step6_timer));
end

%% STEP 7: 60-YEAR 4-REGION + ABROAD TRANSITION PATH ($1.6T TRANSFER & CHILD WAVE)
if Run_Transition_Path && exist('TransPath_4Region_Master.m', 'file')
    fprintf('>>> [STEP 7/7] Running TransPath_4Region_Master.m (%d-Year Transition, %d Steps)...\n', ...
        Params.T_trans_years, Params.T_trans);
    step7_timer = tic;
    run(which('TransPath_4Region_Master.m'));
    fprintf('    Step 7 completed in %.2f seconds.\n\n', toc(step7_timer));
end

%% STEP 7B: 4-PANEL & 2-PANEL FERTILITY/SUPER SOLVENCY + 7-FACTOR SS2 STACKED ATTRIBUTION PLOTS
if exist('FertOut', 'var') && isstruct(FertOut)
    reanchor_opts = struct('ReanchorFrom', FertOut, 'Reg_HH_Shares', Reg_HH_Shares);
    if exist('T1', 'var') && istable(T1)
        reanchor_opts.T1 = T1;
    end
    FertOut       = Compute_FiscalSolvency_And_Fertility(Params, [], [], [], [], reanchor_opts);
    CE_UCurve_SS2 = FertOut.CE_UCurve_SS2;
    T_UCurve      = FertOut.T_UCurve;
    figFert       = Plot_FertilityBargaining(FertOut, Params, ...
        struct('Export_Tables_Figures', Export_Tables_Figures, 'OutputDir', OutputDir));
end

Target_Plot_Regions = [{'National'}, fliplr(Regions), {'Urban'}];
if ~exist('Params_SS0', 'var') && exist('Params', 'var'), Params_SS0 = Params; end
Params_SS0.Profile_ID         = Params.Profile_ID;
Params_SS0.Calibration_Anchor = Params.Calibration_Anchor;

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

%% GENERATE 10-TIER EARN + OWN WEALTH BRACKET PAIN & CELEBRATION FIGURE
if ~exist('Params_SS0', 'var') && exist('Params', 'var')
    Params_SS0 = Params;
elseif ~exist('Params_SS0', 'var')
    Params_SS0 = struct('Calibration_Anchor', 'Dunedin_22');
end
Out_WealthBrackets = Plot_WealthBracket_GiveAndGain(Params_SS0);

% Plot Pre-Employment opportunity index
% Decomposes the pre-employment youth cohort across 4 Regions (Status Quo SS0 vs Reform SS1) into:
%   1. Stay in NZ & Attain >= Parents by Age 30 (%)
%   2. Leave NZ (Australia/OECD) & Attain >= Parents by Age 30 (%)
%   3. Stay in NZ & Do Worse Than Parents by Age 30 (%)
%   4. Leave NZ & Do Worse Than Parents by Age 30 (%) [Residual]
% Calibrates Abroad leaver outcomes using OECD / Trans-Tasman opportunity data:
%   - Real PPP wage premium in Australia/OECD at age 30: +32% (dlog_w_Abr = +0.278)
%   - Positive skill selection + deeper metro job ladders -> ~81% conditional upward attainment.
run(which('Plot_PreEmployment_OpportunityIndex.m'));

% 1. Active Profile Actuarial Continuation Valuation (Primate Metro & National):
Out_Primate_Active  = Plot_ActuarialContinuationValuation([], Params, Params.Primate_Region_ID);
Out_National_Active = Plot_ActuarialContinuationValuation([], Params, 'National');

% 2. Cross-Cohort Sensitivity Comparison (GUiNZ 2009 if running Dunedin, or Dunedin 1972 if running GUiNZ):
if strcmpi(Params.Profile_ID, 'NZ_Dunedin1972')
    alt_prof = struct('Profile_Name', 'NZ_GUiNZ2009');
    Out_Auckland_GUiNZ = Plot_ActuarialContinuationValuation([], alt_prof, Params.Primate_Region_ID);
    Out_National_GUiNZ = Plot_ActuarialContinuationValuation([], alt_prof, 'National');
end

DS_active = Load_Empirical_Profile(Params.Profile_ID);
Params.Super_Age_SS2 = DS_active.Institutions.Super_Age_SS2;
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
        Pi_4x5       = 100 * IG_Diag_5D_BM.MigrationMatrix_4x5;
        Struggle_vec = 100 * cellfun(@(r) IG_Diag_5D_BM.StrugglingShare.(r), Regions(:));
        Beq_vec      = cellfun(@(r) IG_Diag_5D_BM.MeanBequest.(r), Regions(:));
        to_reg_cols  = cellfun(@(r) ['To_', r, '_Pct'], Regions, 'UniformOutput', false);
        ext_col_name = ['Emig_', Params.External_Dest_Label, '_Pct'];
        T3B = array2table([Pi_4x5, Struggle_vec, Beq_vec], 'RowNames', Regions, ...
            'VariableNames', [to_reg_cols, {ext_col_name, 'Struggling_Cohort_Pct', 'Mean_Net_Bequest'}]);
        writetable(T3B, fullfile(OutputDir, 'Table3B_4Region_Abroad_SteadyState_Summary.csv'), 'WriteRowNames', true);
    end
    if exist('T_IGE', 'var')
        writetable(T_IGE,     fullfile(OutputDir, 'Table4_4Region_LeeSeshadri_IGE.csv'), 'WriteRowNames', true);
        writetable(T_Out,     fullfile(OutputDir, 'Table5_4Region_LeeSeshadri_Output_Welfare.csv'), 'WriteRowNames', true);
        writetable(T_VarExpl, fullfile(OutputDir, 'Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv'), 'WriteRowNames', true);
    end
    if exist('T_Fert1', 'var')
        writetable(T_Fert1, fullfile(OutputDir, 'Table7_4Region_Fertility_Bargaining_TFR.csv'), 'WriteRowNames', true);
        writetable(T_Fert2, fullfile(OutputDir, 'Table8_4Region_Fertility_Struggling_NZSuperTax.csv'), 'WriteRowNames', true);
    end
    if exist('T_CohortWelfare', 'var')
        writetable(T_CohortWelfare, fullfile(OutputDir, 'Table_Trans1_Daruich_Cohort_Welfare_4Region.csv'));
    end
    if exist('T_PopShares', 'var')
        writetable(T_PopShares, fullfile(OutputDir, 'Table9_4Region_Dynamic_Population_Shares.csv'));
    end
    if exist('Emig_path', 'var') && exist('Years_grid', 'var')
        emig_reg_cols = cellfun(@(r) ['Emig_', r, '_Pct'], Regions, 'UniformOutput', false);
        nat_emig_col  = ['Nat_Emig_', Params.External_Dest_Label, '_Pct'];
        T_BrainDrain  = array2table([Years_grid, Emig_path, Nat_Emig_path, Cohesion_St], ...
            'VariableNames', [{'Year'}, emig_reg_cols, {nat_emig_col, 'Social_Cohesion_Index_St'}]);
        writetable(T_BrainDrain, fullfile(OutputDir, 'Table10_4Region_Abroad_BrainDrain_Cohesion.csv'));
    end
    old_warn = warning('query', 'all');
    warning('off', 'all');
    save(fullfile(OutputDir, 'NZ_4Region_Intergen_Complete_Results.mat'));
    warning(old_warn);
    fprintf('  Saved Full Workspace Checkpoint: NZ_4Region_Intergen_Complete_Results.mat\n');
end

fprintf('\n=========================================================================================\n');
fprintf('  4-REGION + ABROAD SUITE EXECUTION COMPLETE! Total Runtime: %.2f minutes.\n', toc(suite_timer)/60);
fprintf('=========================================================================================\n');
