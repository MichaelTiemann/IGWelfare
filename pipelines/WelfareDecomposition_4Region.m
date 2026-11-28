%% MULTIPHASE 4-REGION WELFARE & SPATIAL DECOMPOSITION (SS0 -> SS1 -> ... -> SSm)
% File: pipelines/WelfareDecomposition_4Region.m
% Pipeline orchestration script delegating 3-stage multiphase equilibrium & CE% math to
% Compute_WelfareDecomposition_4Region.m, unpacking workspace checkpoints, and exporting Tables 1-3.

wb_opts = struct('RequireToolkit', true);
if exist('Regions', 'var') && ~isempty(Regions), wb_opts.Regions = Regions; end
if ~exist('Params', 'var'), Params = struct(); end
[Params, Regions] = Ensure_Workbench_Initialized(Params, wb_opts);

Grids5D = struct( ...
    'n_d',                      n_d, ...
    'n_a',                      n_a, ...
    'n_z',                      n_z, ...
    'N_j',                      N_j, ...
    'Names_i',                  {Names_i}, ...
    'd_grid',                   d_grid, ...
    'a_grid',                   a_grid, ...
    'z_grid',                   z_grid, ...
    'pi_z',                     pi_z, ...
    'ReturnFn',                 ReturnFn, ...
    'DiscountFactorParamNames', {DiscountFactorParamNames}, ...
    'AgeWeightsParamNames',     {AgeWeightsParamNames}, ...
    'PTypeDistParamNames',      {PTypeDistParamNames}, ...
    'vfoptions',                vfoptions, ...
    'simoptions',               simoptions);

wd_opts = struct('Regions', {Regions});
if exist('Enable_SS2_Phase', 'var'),   wd_opts.Enable_SS2_Phase   = Enable_SS2_Phase;   end
if exist('Active_Phases', 'var'),      wd_opts.Active_Phases      = Active_Phases;      end
if exist('Reform_Phase_Specs', 'var'), wd_opts.Reform_Phase_Specs = Reform_Phase_Specs; end
if exist('IG_Diagnostics', 'var'),     wd_opts.IG_Diagnostics_SS0 = IG_Diagnostics;     end
if exist('V_5D_BM', 'var') && exist('Policy_5D_BM', 'var') && exist('StationaryDist_5D_BM', 'var') && exist('jequaloneDist_5D_BM', 'var')
    wd_opts.Precomputed_SS0 = struct( ...
        'V',        V_5D_BM, ...
        'Policy',   Policy_5D_BM, ...
        'StatDist', StationaryDist_5D_BM, ...
        'jDist',    jequaloneDist_5D_BM, ...
        'IG_Diag',  IG_Diag_5D_BM);
end

%% 1. COMPUTE MULTIPHASE WELFARE DECOMPOSITION & PURE PHASE REGISTRY
DecompOut = Compute_WelfareDecomposition_4Region(Params, Grids5D, jequaloneDist, wd_opts);

% Unpack SS0 & legacy baseline aliases into caller workspace:
V_SS0          = DecompOut.V_SS0;
Policy_SS0     = DecompOut.Policy_SS0;
StatDist_SS0   = DecompOut.StatDist_SS0;
jDist_SS0      = DecompOut.jDist_SS0;
Params_SS0     = DecompOut.Params_SS0;
IG_Diag_SS0    = DecompOut.IG_Diag_SS0;
V_Base         = V_SS0;
Policy_Base    = Policy_SS0;
StatDist_Base  = StatDist_SS0;
jequalone_Base = jDist_SS0;
Params_Base    = Params_SS0;
IG_Diag_Base   = IG_Diag_SS0;

% Unpack solved reform phases (SS1, SS2, ..., SSm) into caller workspace without assignin('base'):
Reform_Phase_Specs = DecompOut.Reform_Phase_Specs;
phase_codes        = fieldnames(DecompOut.PhaseObjects);
for m_u = 1:numel(phase_codes)
    pc = phase_codes{m_u};
    po = DecompOut.PhaseObjects.(pc);
    eval(sprintf('V_%s = po.V; Policy_%s = po.Policy; StatDist_%s = po.StatDist; jDist_%s = po.jDist; Params_%s = po.Params; IG_Diag_%s = po.IG_Diag;', ...
        pc, pc, pc, pc, pc, pc));
    if strcmp(pc, 'SS1')
        V_PE             = po.V_PE;
        Policy_PE        = po.Policy_PE;
        V_GE_Exo         = po.V_GE_Exo;
        Policy_GE_Exo    = po.Policy_GE_Exo;
        V_GE_Endo        = po.V;
        Policy_GE_Endo   = po.Policy;
        StatDist_GE_Endo = po.StatDist;
        jequalone_Endo   = po.jDist;
        Params_Reform    = po.Params;
        Params_GE        = po.Params;
        IG_Diag_Reform   = po.IG_Diag;
    end
end

WelfareResults = DecompOut.WelfareResults;
T1             = DecompOut.T1;
T2             = DecompOut.T2;
T3             = DecompOut.T3;
CE_Stage       = DecompOut.CE_Stage;
CE_Quint       = DecompOut.CE_Quint;
CE_Ten         = DecompOut.CE_Ten;
Active_Phases  = DecompOut.Active_Phases;
Phases         = DecompOut.Phases;

%% 2. EXPORT TABLES 1, 2, AND 3 (HONORING Export_Tables_Figures CONTROLLER)
if ~exist('Export_Tables_Figures', 'var') || logical(Export_Tables_Figures)
    explicit_out = '';
    if exist('OutputDir', 'var') && ~isempty(OutputDir), explicit_out = OutputDir; end
    OutputDir = Resolve_IGW_OutputDir(explicit_out, Params_SS0.Profile_ID);
    writetable(T1, fullfile(OutputDir, 'Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv'), 'WriteRowNames', true);
    writetable(T2, fullfile(OutputDir, 'Table2_4Region_LabroussePerdereau_SpatialQuintiles.csv'), 'WriteRowNames', true);
    writetable(T3, fullfile(OutputDir, 'Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv'), 'WriteRowNames', true);
end
disp('=== TABLE 1: MULTIPHASE 4-REGION WELFARE DECOMPOSITION (CE %) ===');
disp(T1);
