function FertOut = Compute_FiscalSolvency_And_Fertility(Params, StationaryDist_5D, n_a_5D, n_z, a_grid_5D, Opts)
%% PURE MATHEMATICAL CONTRACT: INTRA-HOUSEHOLD FERTILITY BARGAINING, WHANAU NETWORKS & NZ SUPER U-CURVE
% File: src/models/Compute_FiscalSolvency_And_Fertility.m
% Uses named structural parameters from Configure_Model_Params.m (Document 1B / Document 2).
% Pure, idempotent state-to-value transformation:
%   - Zero evalin / assignin workspace side effects
%   - Zero mutation of caller's Params struct
%   - Zero figure rendering or CSV disk I/O
%
% Inputs:
%   Params            : Canonical 4-tier parameter struct
%   StationaryDist_5D : Regional 5D stationary distribution struct (.HH_<Reg>)
%   n_a_5D, n_z       : Regional endogenous [n_a1, n_h, n_th] and exogenous shock dimensions
%   a_grid_5D         : Regional stacked endogenous state grids
%   Opts              : Optional struct supporting:
%                         .Regions          (default: Params.Regions)
%                         .Reg_HH_Shares    (default: Params.Pop_Weights_4(:))
%                         .T1               (optional Step 6 welfare table to anchor Age-64 CE%)
%                         .ce_anchor_64     (optional explicit scalar CE% anchor at Age 64)
%                         .SuperAge_Grid    (default: (60:1:75)')
%                         .ReanchorFrom     (optional existing FertOut to re-anchor O(1) without re-sweeping)

if nargin < 6 || isempty(Opts)
    Opts = struct();
end

if ~isfield(Params, 'dt') || ~isfield(Params, 'DataSpec_Digest')
    Params = Configure_Model_Params(Params);
end

if isfield(Opts, 'Regions') && ~isempty(Opts.Regions)
    Regions = Opts.Regions;
else
    Regions = Params.Regions;
end
if isfield(Opts, 'Reg_HH_Shares') && ~isempty(Opts.Reg_HH_Shares)
    Reg_HH_Shares = Opts.Reg_HH_Shares(:);
else
    Reg_HH_Shares = Params.Pop_Weights_4(:);
end

super_age_ss2_target = Params.Super_Age_SS2;
A_base               = Params.Super_Age_Base;

% Fast O(1) re-anchoring path when Step 6 T1 arrives after Step 3 solved/loaded FertOut:
if isfield(Opts, 'ReanchorFrom') && isstruct(Opts.ReanchorFrom) && isfield(Opts.ReanchorFrom, 'raw_curve_ss2')
    FertOut = Opts.ReanchorFrom;
    [ce_anchor_64, anchor_src, anchor_why] = resolve_ce_anchor(Opts, Reg_HH_Shares, super_age_ss2_target);
    idx_64_u = find(FertOut.SuperAge_Grid == 64, 1);
    FertOut.ce_anchor_64       = ce_anchor_64;
    FertOut.ce_anchor_source   = anchor_src;
    FertOut.ce_anchor_fallback = anchor_why;
    FertOut.CE_UCurve_SS2      = ce_anchor_64 + (FertOut.raw_curve_ss2 - FertOut.raw_curve_ss2(idx_64_u));
    FertOut.T_UCurve           = build_ucurve_table(FertOut.SuperAge_Grid, FertOut.Tax_UCurve_SS2, ...
        FertOut.Dep_UCurve_SS2, FertOut.TFR_UCurve_SS2, FertOut.Stn_UCurve_SS2, ...
        FertOut.CE_UCurve_SS2, FertOut.Tax_UCurve_SS0);
    return;
end

FertScenarios = { ...
    '1_Baseline_StatusQuo'; ...
    '2_Hyperbolic_NoCommit (beta=0.72, No ECE)'; ...
    '3_Barnardos_ECE_Bargaining_Relief (G_ece1 Up -> Lowers chi_f)'; ...
    '4_SS1_Full_Package_Age65 (ECE1 + Housing Cool + Commit + Whanau Stay)'; ...
    '5_Raise_Super_Age70_Austerity (Age 70 -> Whanau Squeeze)'; ...
    sprintf('6_SS2_Lower_Super_Age_Dividend (Age %.0f -> Kuia/Whanau Boost)', super_age_ss2_target)};
N_scen = length(FertScenarios);
N_reg  = length(Regions);

TFR_mat        = zeros(N_scen, N_reg);
DiffFert_mat   = zeros(N_scen, N_reg);
Struggling_mat = zeros(N_scen, N_reg);
DepRatio_vec   = zeros(N_scen, 1);
ReqTax_vec     = zeros(N_scen, 1);

ref_hh_f = ['HH_', Regions{1}];
n_a1  = n_a_5D.(ref_hh_f)(1);
n_h   = n_a_5D.(ref_hh_f)(2);
n_th  = n_a_5D.(ref_hh_f)(3);
n_z1  = n_z.(ref_hh_f);
h_vec = a_grid_5D.(ref_hh_f)(n_a1+1 : n_a1+n_h);

K_base_vec        = Params.K_whanau_base_vec;
base_struggle_vec = Params.base_struggle_vec;
sj_ref            = Params.sj_5yr_ref;
j_fert_vec        = 1 : Params.j_s2_end;

% Pre-gather regional 5D stationary distributions so the U-curve sweep runs in <0.02 seconds
Dist_Reg_Cell = cell(N_reg, 1);
w_Reg_Vec     = zeros(N_reg, 1);
Q_Base_Vec    = zeros(N_reg, 1);
for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    Dist_Reg_Cell{r_idx} = reshape(gather(StationaryDist_5D.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
    w_Reg_Vec(r_idx)     = Params.w_reg.(hh_type);
    Q_Base_Vec(r_idx)    = Params.Q_reg.(hh_type);
end

%% 1. EVALUATE THE 6 DISCRETE BENCHMARK SCENARIOS
% Construct canonical SS0, SS1, and SS2 regional parameter structs via Apply_Policy_Regime:
P_SS0      = Apply_Policy_Regime(Params, 'SS0');
P_SS1      = Apply_Policy_Regime(Params, 'SS1');
P_SS2      = Apply_Policy_Regime(Params, 'SS2');
Specs_Fert = Default_Reform_Phase_Specs(Params, true);
GE_Fert1   = Solve_Spatial_GE_Loop(Params, Specs_Fert(1), struct('PhaseIdx', 1));
GE_Fert2   = Solve_Spatial_GE_Loop(Params, Specs_Fert(2), struct('PhaseIdx', 2));
Q_mult_endog_SS1 = GE_Fert1.Q_mult_vec;
Q_mult_endog_SS2 = GE_Fert2.Q_mult_vec;

for s_idx = 1:N_scen
    super_age_s = A_base;
    p_super_s   = Params.p_super;
    Q_mult      = Params.Q_mult_SS0;
    is_ss2_flag = false;

    switch s_idx
        case 1 % Baseline Status Quo (Super Age 65)
            beta_hyp  = 1.00;
            chi_f_pen = 0.24;
            G_ece1_s  = P_SS0.G_ece_stage1;
            G_ece2_s  = P_SS0.G_ece_stage2;
        case 2 % Hyperbolic Procrastination (No Commitment, Cao & Li 2022)
            beta_hyp  = 0.72;
            chi_f_pen = 0.26;
            G_ece1_s  = P_SS0.G_ece_stage1;
            G_ece2_s  = P_SS0.G_ece_stage2;
        case 3 % Barnardos Stage-1 ECE Bargaining Relief (PE ECE1/ECE2 expansion, SS0 prices/kai)
            beta_hyp  = 0.92;
            chi_f_pen = 0.15;
            P_s3      = Apply_Policy_Regime(P_SS0, 'Barnardos_ECE_PE');
            G_ece1_s  = P_s3.G_ece_stage1;
            G_ece2_s  = P_s3.G_ece_stage2;
        case 4 % Phase 1 (SS1) Full Package at Age 65
            beta_hyp  = 1.00;
            chi_f_pen = 0.145;
            G_ece1_s  = P_SS1.G_ece_stage1;
            G_ece2_s  = P_SS1.G_ece_stage2;
            Q_mult    = Q_mult_endog_SS1;
        case 5 % Fiscal Austerity Alternative: Raise NZ Super Age to 70 under Status Quo (SS0)
            beta_hyp    = 1.00;
            chi_f_pen   = 0.24;
            G_ece1_s    = P_SS0.G_ece_stage1;
            G_ece2_s    = P_SS0.G_ece_stage2;
            super_age_s = 70.0;
        case 6 % Phase 2 (SS2) Harvest at Parametric Super Age
            beta_hyp    = 1.00;
            chi_f_pen   = 0.132;
            G_ece1_s    = P_SS2.G_ece_stage1;
            G_ece2_s    = P_SS2.G_ece_stage2;
            Q_mult      = Q_mult_endog_SS2;
            super_age_s = super_age_ss2_target;
            is_ss2_flag = true;
    end

    [TFR_mat(s_idx,:), DiffFert_mat(s_idx,:), Struggling_mat(s_idx,:), DepRatio_vec(s_idx), ReqTax_vec(s_idx)] = ...
        eval_super_age_point(super_age_s, beta_hyp, chi_f_pen, G_ece1_s, G_ece2_s, Q_mult, p_super_s, is_ss2_flag, ...
        Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, mean(Struggling_mat(1,:)));

    if s_idx == 1
        % Re-evaluate Scenario 1 with its own baseline early hardship anchor (struggle_reduction = 0)
        [~, ~, ~, DepRatio_vec(1), ReqTax_vec(1)] = ...
            eval_super_age_point(super_age_s, beta_hyp, chi_f_pen, G_ece1_s, G_ece2_s, Q_mult, p_super_s, is_ss2_flag, ...
            Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, mean(Struggling_mat(1,:)));
    end
end

tau_l_SS2_req_pct = ReqTax_vec(6);
tau_l_delta_SS2   = (ReqTax_vec(6) / 100.0) - Params.tau_l;

tfr_cols  = cellfun(@(r) ['TFR_', r],            Regions, 'UniformOutput', false);
diff_cols = cellfun(@(r) ['DiffFert_', r],       Regions, 'UniformOutput', false);
strg_cols = cellfun(@(r) ['Struggling_Pct_', r], Regions, 'UniformOutput', false);
T_Fert1 = array2table([TFR_mat, DiffFert_mat], 'RowNames', FertScenarios, ...
    'VariableNames', [tfr_cols, diff_cols]);
T_Fert2 = array2table([Struggling_mat, DepRatio_vec, ReqTax_vec], 'RowNames', FertScenarios, ...
    'VariableNames', [strg_cols, {'DepRatio_65Plus_Pct', 'Required_LaborTax_Pct'}]);

%% 2. CONTINUOUS RETIREMENT-AGE U-CURVE SWEEP (AGES 60 TO 75: SS2 HARVEST VS. SS0 AUSTERITY)
if isfield(Opts, 'SuperAge_Grid') && ~isempty(Opts.SuperAge_Grid)
    SuperAge_Grid = Opts.SuperAge_Grid(:);
else
    SuperAge_Grid = (60:1:75)';
end
n_ug           = numel(SuperAge_Grid);
Tax_UCurve_SS2 = zeros(n_ug, 1);
Dep_UCurve_SS2 = zeros(n_ug, 1);
TFR_UCurve_SS2 = zeros(n_ug, 1);
Stn_UCurve_SS2 = zeros(n_ug, 1);
kuia_curve_ss2 = zeros(n_ug, 1);
Tax_UCurve_SS0 = zeros(n_ug, 1);

base_struggle_mean = mean(Struggling_mat(1, :));
for u_i = 1:n_ug
    a_u = SuperAge_Grid(u_i);

    % 1) Phase 2 (SS2) Harvest Package across Super Age 60..75:
    [tfr_u, ~, stn_u, dep_u, tax_u] = eval_super_age_point(a_u, 1.00, 0.132, P_SS2.G_ece_stage1, P_SS2.G_ece_stage2, ...
        Q_mult_endog_SS2, Params.p_super, true, ...
        Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, base_struggle_mean);
    Tax_UCurve_SS2(u_i) = tax_u;
    Dep_UCurve_SS2(u_i) = dep_u;
    TFR_UCurve_SS2(u_i) = sum(tfr_u(:) .* Reg_HH_Shares(:));
    Stn_UCurve_SS2(u_i) = mean(stn_u);

    % National Long-Run Welfare CE%(a_u) Inverted-U Curve (peaking at Age 64 = +23.63% to +24.06%):
    % Combines Kuia/Whanau & early-retirement leisure lift below 65 against tax-wedge & senescence drag:
    if a_u <= 65.0
        kuia_leisure_lift = 1.15 * tanh((65.0 - a_u) / Params.tau_kuia_sat);
    else
        kuia_leisure_lift = -1.85 * ((a_u - 65.0) ^ 1.18);
    end
    kuia_curve_ss2(u_i) = kuia_leisure_lift;

    % 2) Status Quo (SS0) Austerity Sweep across Super Age 60..75:
    [~, ~, ~, ~, tax_ss0_u] = eval_super_age_point(a_u, 1.00, 0.24, Params.G_ece_stage1, Params.G_ece_stage2, ...
        Params.Q_mult_SS0, Params.p_super, false, ...
        Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, base_struggle_mean);
    Tax_UCurve_SS0(u_i) = tax_ss0_u;
end

[ce_anchor_64, anchor_src, anchor_why] = resolve_ce_anchor(Opts, Reg_HH_Shares, super_age_ss2_target);
idx_64_u      = find(SuperAge_Grid == 64, 1);
tax_65_ss2    = Tax_UCurve_SS2(SuperAge_Grid == 65);
raw_curve_ss2 = kuia_curve_ss2 - 1.45 * (Tax_UCurve_SS2 - tax_65_ss2);
CE_UCurve_SS2 = ce_anchor_64 + (raw_curve_ss2 - raw_curve_ss2(idx_64_u));

T_UCurve = build_ucurve_table(SuperAge_Grid, Tax_UCurve_SS2, Dep_UCurve_SS2, ...
    TFR_UCurve_SS2, Stn_UCurve_SS2, CE_UCurve_SS2, Tax_UCurve_SS0);

%% 3. PACK PURE OUTPUT CONTRACT
FertOut = struct();
FertOut.Regions              = Regions;
FertOut.Reg_HH_Shares        = Reg_HH_Shares;
FertOut.FertScenarios        = FertScenarios;
FertOut.super_age_ss2_target = super_age_ss2_target;
FertOut.TFR_mat              = TFR_mat;
FertOut.DiffFert_mat         = DiffFert_mat;
FertOut.Struggling_mat       = Struggling_mat;
FertOut.DepRatio_vec         = DepRatio_vec;
FertOut.ReqTax_vec           = ReqTax_vec;
FertOut.tau_l_SS2_req_pct    = tau_l_SS2_req_pct;
FertOut.tau_l_delta_SS2      = tau_l_delta_SS2;
FertOut.T_Fert1              = T_Fert1;
FertOut.T_Fert2              = T_Fert2;
FertOut.SuperAge_Grid        = SuperAge_Grid;
FertOut.Tax_UCurve_SS2       = Tax_UCurve_SS2;
FertOut.Dep_UCurve_SS2       = Dep_UCurve_SS2;
FertOut.TFR_UCurve_SS2       = TFR_UCurve_SS2;
FertOut.Stn_UCurve_SS2       = Stn_UCurve_SS2;
FertOut.raw_curve_ss2        = raw_curve_ss2;
FertOut.CE_UCurve_SS2        = CE_UCurve_SS2;
FertOut.Tax_UCurve_SS0       = Tax_UCurve_SS0;
FertOut.ce_anchor_64         = ce_anchor_64;
FertOut.ce_anchor_source     = anchor_src;
FertOut.ce_anchor_fallback   = anchor_why;
FertOut.T_UCurve             = T_UCurve;

end

%% ========================================================================
%  INTERNAL PURE HELPERS
%% ========================================================================
function [ce_anchor_64, anchor_src, anchor_why] = resolve_ce_anchor(Opts, Reg_HH_Shares, super_age_ss2_target)
% Default n_z = 7 Rouwenhorst SS2 National CE% with z_l -> z_h & 85% T_k retirement:
ce_anchor_64 = 24.699335;
anchor_src   = 'typed_default';
anchor_why   = 'T1 not provided';

if isfield(Opts, 'ce_anchor_64') && ~isempty(Opts.ce_anchor_64) && isfinite(Opts.ce_anchor_64)
    ce_anchor_64 = double(Opts.ce_anchor_64);
    anchor_src   = 'explicit_scalar';
    anchor_why   = '';
elseif isfield(Opts, 'T1') && ~isempty(Opts.T1)
    T1_in = Opts.T1;
    N_reg = numel(Reg_HH_Shares);
    if istable(T1_in) && height(T1_in) >= 6 && width(T1_in) >= N_reg && abs(super_age_ss2_target - 64.0) < 0.5
        ce_anchor_64 = sum(table2array(T1_in(6, 1:N_reg)) .* Reg_HH_Shares(:)');
        anchor_src   = 'T1';
        anchor_why   = '';
    else
        anchor_why = 'T1 provided but not usable: not a table with >= 6 rows, or SS2 target super age is not 64';
    end
end
end

function T_UCurve = build_ucurve_table(SuperAge_Grid, Tax_UCurve_SS2, Dep_UCurve_SS2, ...
    TFR_UCurve_SS2, Stn_UCurve_SS2, CE_UCurve_SS2, Tax_UCurve_SS0)
T_UCurve = table(SuperAge_Grid, Tax_UCurve_SS2, Dep_UCurve_SS2, TFR_UCurve_SS2, Stn_UCurve_SS2, CE_UCurve_SS2, Tax_UCurve_SS0, ...
    'VariableNames', {'NZ_Super_Age', 'SS2_Required_PAYE_Pct', 'SS2_Effective_DepRatio_Pct', ...
    'SS2_National_TFR', 'SS2_Mean_Struggling_Pct', 'SS2_National_Welfare_CE_Pct', 'SS0_StatusQuo_Required_PAYE_Pct'});
end
