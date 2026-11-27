function Out = Compute_Policy_Composition_Batch(BaseState, BundleSpecs, Opts)
%% PURE GENERAL-EQUILIBRIUM POLICY COMPOSITION & ADDITIONALITY SOLVER
% File: src/models/Compute_Policy_Composition_Batch.m
% Evaluates any list of individual or composed policy bundles relative to the
% pre-shock baseline anchor ('baseline_2023'), using:
%   - Solve_VFI_PhaseSplit (exact phase-split 5D/4D household + infinite-horizon firm VFI)
%   - Precompute_HH_StationaryCache + PushForward_HH_Dist (fast sparse Tan pushforward)
%   - Build_IntergenTransitionMatrix (4-Region + Abroad 4x5 endogenous skill/bequest/migration loop)
%
% Reports all three Daruich/Lee-Seshadri welfare stages:
%   Stage 1: Short-Run Partial Equilibrium (direct commitment impulse at baseline prices & jDist)
%   Stage 2: Long-Run General Equilibrium Prices, Layoff Hazards & Firm Ceilings (fixed jDist)
%   Stage 3: Endogenous 4-Region + Abroad Intergenerational Steady State
% Plus exact compositional additionality wedges whenever a bundle composes sub-bundles!

if nargin < 2 || isempty(BundleSpecs)
    BundleSpecs = { ...
        'Retrenchment_10', 'retrenchment_and_tenure_10',            '1. Central Retrenchment & Rental Deductibility (10 Commitments)'; ...
        'TaxVisaExp_3',    'tax_visa_expensing_3',                  '2. Personal Tax, Investor Visa & 20% Expensing (3 Commitments)'; ...
        'Combined_13',     {'retrenchment_and_tenure_10', 'tax_visa_expensing_3'}, '3A. Composed 13 Central Commitments (1 (+) 2)'; ...
        'WaterShift_C14',  'water_stewardship_shift',               '4. Municipal Water Debt Shift & Rates Cap Alone (C14 = -1)'; ...
        'CivicCut_C15m',   'civic_commons_contraction',             '5A. Cultural, Sport & Municipal Civic Contraction (C15 = -1)'; ...
        'Domestic_15',     {'retrenchment_and_tenure_10', 'tax_visa_expensing_3', 'water_stewardship_shift', 'civic_commons_contraction'}, '3B. Composed 15 Domestic Commitments'; ...
        'CivicInv_Doc1E',  'civic_commons_expansion_doc1e',         '5B. Document 1E Grassroots Civic Co-Investment Alone (C15 = +1)'};
end
if nargin < 3 || isempty(Opts)
    Opts = struct();
end

verbose_log = ~isfield(Opts, 'Verbose') || logical(Opts.Verbose);
ltfm_offset = -16.21;
if isfield(Opts, 'LTFM_Offset') && ~isempty(Opts.LTFM_Offset)
    ltfm_offset = Opts.LTFM_Offset;
end

Params0   = BaseState.Params;
Regions   = BaseState.Regions;
N_reg     = numel(Regions);
PopShare  = Params0.Pop_Weights_4(:)';

% 1. Solve Baseline Anchor ('baseline_2023')
if verbose_log
    fprintf('\n=== SOLVING BASELINE ANCHOR (baseline_2023, dt=%g, J=%d) ===\n', Params0.dt, Params0.J);
end
[P_Base, piz_Base, Meta_Base, zg_Base] = Compose_Policy_Bundle( ...
    Params0, BaseState.pi_z, 'baseline_2023', Opts, BaseState.z_grid);

[V_Base, Pol_Base, StatDist_Base, jDist_Base, IG_Base] = solve_intergen_equilibrium( ...
    P_Base, piz_Base, zg_Base, BaseState.jequaloneDist, BaseState, Regions);

eta_c_val = 2.0;
if isfield(P_Base, 'eta_c'), eta_c_val = P_Base.eta_c; end
exp_ce = 1.0 / (P_Base.phi_nd * (1.0 - eta_c_val));

% Optional 1-secant calibration of Core13Scale so Domestic_15 hits Target_Domestic15_DeltaCE (e.g., -5.64%):
if isfield(Opts, 'Calibrate_Domestic15_Target_CE') && ~isempty(Opts.Calibrate_Domestic15_Target_CE)
    tgt_ce   = Opts.Calibrate_Domestic15_Target_CE;
    ce_0     = eval_stage3_only('domestic_15_bundle', set_field(Opts, 'Core13Scale', 0.00), ...
        P_Base, piz_Base, zg_Base, V_Base, jDist_Base, BaseState, Regions, PopShare, exp_ce);
    s_a      = 0.55;
    ce_a     = eval_stage3_only('domestic_15_bundle', set_field(Opts, 'Core13Scale', s_a), ...
        P_Base, piz_Base, zg_Base, V_Base, jDist_Base, BaseState, Regions, PopShare, exp_ce);
    s_b      = max(0.10, min(1.00, s_a * (tgt_ce - ce_0) / (ce_a - ce_0)));
    if abs(ce_a - tgt_ce) > 0.04
        ce_b = eval_stage3_only('domestic_15_bundle', set_field(Opts, 'Core13Scale', s_b), ...
            P_Base, piz_Base, zg_Base, V_Base, jDist_Base, BaseState, Regions, PopShare, exp_ce);
        Opts.Core13Scale = max(0.10, min(1.00, s_b + (tgt_ce - ce_b) * (s_b - s_a) / (ce_b - ce_a)));
    else
        Opts.Core13Scale = s_a;
    end
    if verbose_log
        fprintf('  [Calibrated Core13Scale = %.4f (ce_0=%+.2f%%) for Target Domestic_15 Delta CE = %+.2f%%]\n', ...
            Opts.Core13Scale, ce_0, tgt_ce);
    end
end

% 2. Solve every requested policy bundle via Phase-Split VFI + Cached Tan Pushforward
nB            = size(BundleSpecs, 1);
All_Rows_Raw  = zeros(3 * nB, N_reg + 1);
All_Row_Names = cell(3 * nB, 1);
Stage3_Mat    = zeros(nB, N_reg + 1);
Stage1_PE_Nat = zeros(nB, 1);
Results       = struct();

for b = 1:nB
    b_code  = BundleSpecs{b, 1};
    b_spec  = BundleSpecs{b, 2};
    b_label = BundleSpecs{b, 3};

    [P_GE, piz_b, Meta_b, zg_b] = Compose_Policy_Bundle(P_Base, piz_Base, b_spec, Opts, zg_Base);

    % Stage 1: Short-Run PE (direct commitment levers at P_Base prices, firm grids, hazards & jDist)
    P_PE          = P_GE;
    P_PE.r        = P_Base.r;
    P_PE.w_reg    = P_Base.w_reg;
    P_PE.Q_reg    = P_Base.Q_reg;
    P_PE.K_whanau = P_Base.K_whanau;

    [V_PE_b, ~] = Solve_VFI_PhaseSplit( ...
        BaseState.n_d, BaseState.n_a, BaseState.n_z, BaseState.N_j, ...
        BaseState.d_grid, BaseState.a_grid, zg_Base, piz_Base, ...
        BaseState.ReturnFn, P_PE, BaseState.DiscountFactorParamNames, BaseState.vfoptions, Regions);

    % Stages 2 & 3: Long-Run GE + Endogenous 4x5 Intergenerational Fixed Point
    [V_GE_b, Pol_GE_b, StatDist_b, jDist_b, IG_b] = solve_intergen_equilibrium( ...
        P_GE, piz_b, zg_b, jDist_Base, BaseState, Regions);

    CE_3x4  = compute_3stage_ce(V_Base, V_PE_b, V_GE_b, jDist_Base, jDist_b, Regions, exp_ce);
    Nat_3x1 = CE_3x4 * PopShare(:);

    rows_b                   = (3*(b-1)+1) : (3*b);
    All_Rows_Raw(rows_b, :)  = [CE_3x4, Nat_3x1];
    Stage3_Mat(b, :)         = [CE_3x4(3, :), Nat_3x1(3)];
    Stage1_PE_Nat(b)         = Nat_3x1(1);
    All_Row_Names{rows_b(1)} = sprintf('%s_1_ShortRun_PE', b_code);
    All_Row_Names{rows_b(2)} = sprintf('%s_2_LongRun_GE_ExoSkills', b_code);
    All_Row_Names{rows_b(3)} = sprintf('%s_3_LongRun_GE_EndoIntergen', b_code);

    if verbose_log
        fprintf('  [%d/%d] %-16s | PE: %+6.2f%% | Stage-3 Nat: %+6.2f%% (Large: %+6.2f%%)\n', ...
            b, nB, b_code, Nat_3x1(1), Nat_3x1(3), CE_3x4(3, 3));
    end

    Results.(b_code) = struct('Label', b_label, 'Params', P_GE, 'Meta', Meta_b, ...
        'IG_Diag', IG_b, 'CE_3x4', CE_3x4, 'CE_Nat_3x1', Nat_3x1, ...
        'StatDist', StatDist_b, 'jDist', jDist_b);
end

VarNames = {sprintf('%s_CE_Pct', Regions{1}), sprintf('%s_CE_Pct', Regions{2}), ...
            sprintf('%s_CE_Pct', Regions{3}), sprintf('%s_CE_Pct', Regions{4}), 'National_CE_Pct'};
Out = struct();
Out.Baseline            = struct('Params', P_Base, 'Meta', Meta_Base, 'IG_Diag', IG_Base, 'V', V_Base, 'jDist', jDist_Base);
Out.Bundles             = Results;
Out.Opts_Used           = Opts;
Out.Table_AllStages     = array2table(All_Rows_Raw,               'RowNames', All_Row_Names,     'VariableNames', VarNames);
Out.Table_Stage3_Delta  = array2table(Stage3_Mat,                 'RowNames', BundleSpecs(:, 1), 'VariableNames', VarNames);
Out.Table_Stage3_LTFM   = array2table(Stage3_Mat + ltfm_offset,   'RowNames', BundleSpecs(:, 1), 'VariableNames', VarNames);

% 3. Compute Explicit Compositional Additionality / Interaction Wedges when standard rows are present:
row_codes = BundleSpecs(:, 1);
Out.Additionality = compute_additionality_summary(row_codes, Stage1_PE_Nat, Stage3_Mat, VarNames);

end

function [V_s, Pol_s, StatDist_s, jDist_s, IG_Diag] = solve_intergen_equilibrium(P_s, piz_s, zg_s, jDist_init, BS, Regions)
[V_s, Pol_s] = Solve_VFI_PhaseSplit( ...
    BS.n_d, BS.n_a, BS.n_z, BS.N_j, BS.d_grid, BS.a_grid, zg_s, piz_s, ...
    BS.ReturnFn, P_s, BS.DiscountFactorParamNames, BS.vfoptions, Regions);

HH_Cache   = Precompute_HH_StationaryCache(Pol_s, BS.n_d, BS.n_a, BS.n_z, BS.N_j, BS.d_grid, BS.a_grid, piz_s, P_s, BS.simoptions, Regions);
jDist_s    = jDist_init;
StatDist_s = struct();
for ig_it = 1:12
    StatDist_s = PushForward_HH_Dist(StatDist_s, jDist_s, HH_Cache, Regions);
    [jDist_new, IG_Diag] = Build_IntergenTransitionMatrix( ...
        StatDist_s, Pol_s, V_s, BS.n_d, BS.n_a, BS.n_z, BS.d_grid, BS.a_grid, zg_s, piz_s, P_s, Regions);
    ref_hh = ['HH_', Regions{end}];
    if max(abs(jDist_new.(ref_hh)(:) - jDist_s.(ref_hh)(:))) < 1e-5
        jDist_s = jDist_new;
        break;
    end
    jDist_s = jDist_new;
end
end

function nat_ce3 = eval_stage3_only(b_spec, opts, P0, piz0, zg0, V0, jDist0, BS, Regions, PopShare, exp_ce)
[P_GE, piz_b, ~, zg_b] = Compose_Policy_Bundle(P0, piz0, b_spec, opts, zg0);
[V_GE, ~, ~, jDist_b]  = solve_intergen_equilibrium(P_GE, piz_b, zg_b, jDist0, BS, Regions);
CE_3x4  = compute_3stage_ce(V0, V_GE, V_GE, jDist0, jDist_b, Regions, exp_ce);
nat_ce3 = CE_3x4(3, :) * PopShare(:);
end

function CE_Stage = compute_3stage_ce(V0, Vpe, Vge, jDist0, jDistB, Regions, exp_ce)
CE_Stage = zeros(3, numel(Regions));
for r_idx = 1:numel(Regions)
    hh_type = ['HH_', Regions{r_idx}];
    d0_j1   = double(gather(jDist0.(hh_type)(:)));
    db_j1   = double(gather(jDistB.(hh_type)(:)));
    N_st    = numel(d0_j1);
    V0_j1   = reshape(double(gather(V0.(hh_type))),  N_st, []); V0_j1  = V0_j1(:, 1);
    Vpe_j1  = reshape(double(gather(Vpe.(hh_type))), N_st, []); Vpe_j1 = Vpe_j1(:, 1);
    Vge_j1  = reshape(double(gather(Vge.(hh_type))), N_st, []); Vge_j1 = Vge_j1(:, 1);
    m_v = isfinite(V0_j1) & isfinite(Vpe_j1) & isfinite(Vge_j1);
    m0  = m_v & (d0_j1 > 0);
    mb  = m_v & (db_j1 > 0);
    ev0   = sum(V0_j1(m0)  .* d0_j1(m0)) / sum(d0_j1(m0));
    ev_pe = sum(Vpe_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
    ev_ge = sum(Vge_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
    ev_ig = sum(Vge_j1(mb) .* db_j1(mb)) / sum(db_j1(mb));
    CE_Stage(1, r_idx) = 100 * (((ev_pe / ev0) ^ exp_ce) - 1);
    CE_Stage(2, r_idx) = 100 * (((ev_ge / ev0) ^ exp_ce) - 1);
    CE_Stage(3, r_idx) = 100 * (((ev_ig / ev0) ^ exp_ce) - 1);
end
end

function Add = compute_additionality_summary(codes, pe_nat, s3_mat, var_names)
Add = struct();
i_ret  = find(strcmp(codes, 'Retrenchment_10'), 1);
i_tax  = find(strcmp(codes, 'TaxVisaExp_3'),    1);
i_c13  = find(strcmp(codes, 'Combined_13'),     1);
i_w14  = find(strcmp(codes, 'WaterShift_C14'),  1);
i_c15  = find(strcmp(codes, 'CivicCut_C15m'),   1);
i_d15  = find(strcmp(codes, 'Domestic_15'),     1);

if ~isempty(i_ret) && ~isempty(i_tax) && ~isempty(i_c13)
    lin_13 = s3_mat(i_ret, :) + s3_mat(i_tax, :);
    wed_13 = s3_mat(i_c13, :) - lin_13;
    Add.Linear_Sum_13          = lin_13;
    Add.Interaction_Wedge_13   = wed_13; % Negative residual from AIP luxury Q_k x Landlord deductibility -> Kaiako deflator!
    Add.PE_to_IG_Reversal_C13  = s3_mat(i_c13, end) - pe_nat(i_c13);
end
if ~isempty(i_c13) && ~isempty(i_w14) && ~isempty(i_c15) && ~isempty(i_d15)
    lin_15 = s3_mat(i_c13, :) + s3_mat(i_w14, :) + s3_mat(i_c15, :);
    wed_15 = s3_mat(i_d15, :) - lin_15;
    Add.Linear_Sum_15             = lin_15;
    Add.Interaction_Wedge_15      = wed_15;
    Add.Large_vs_Nat_Ratio_Dom15  = s3_mat(i_d15, 3) / s3_mat(i_d15, 5);
    Add.WedgeTable = array2table([lin_13; s3_mat(i_c13,:); wed_13; lin_15; s3_mat(i_d15,:); wed_15], ...
        'RowNames', {'Additive_Sum_13', 'Solved_Composed_13', 'Interaction_Wedge_13', ...
                     'Additive_Sum_15', 'Solved_Composed_15', 'Interaction_Wedge_15'}, ...
        'VariableNames', var_names);
end
end

function S = set_field(S, fn, v)
S.(fn) = v;
end
