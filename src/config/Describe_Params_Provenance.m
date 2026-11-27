function [ProvTable, ProvStruct] = Describe_Params_Provenance(Params)
%% EPISTEMIC PROVENANCE INSPECTOR FOR PARAMS ("WHERE DOES EVERY NUMBER COME FROM?")
% File: src/config/Describe_Params_Provenance.m
% Classifies every field of a configured Params struct into its canonical tier:
%   - Tier A ('A_Grid_And_Prefs')     : Configure_Grid_And_Prefs.m
%   - Tier B ('B_Empirical_Data')     : Apply_Empirical_Data.m
%   - Tier C ('C_Calibrated_Params')  : Apply_Calibrated_Params.m
%   - Tier D ('D_Policy_Regime')      : Apply_Policy_Regime.m
%   - Tier W ('W_Workbench_Runtime')  : Caller runtime/execution metadata (e.g. n_workers, Cache_Dir)

if nargin < 1 || isempty(Params)
    Params = Configure_Model_Params(struct());
end

P_A = Configure_Grid_And_Prefs(struct(), Params.dt, Params.n_z_pts);
f_A = fieldnames(P_A);

P_AB = Apply_Empirical_Data(P_A, Params.Profile_ID);
f_B  = setdiff(fieldnames(P_AB), f_A, 'stable');

P_ABC = Apply_Calibrated_Params(P_AB);
f_C   = setdiff(fieldnames(P_ABC), [f_A; f_B], 'stable');

P_ABCD = Apply_Policy_Regime(P_ABC, '');
f_D    = setdiff(fieldnames(P_ABCD), [f_A; f_B; f_C], 'stable');

% Explicit policy/regime knobs that exist in B as baseline anchors but are perturbed in Tier D
policy_knobs = {'G_ece1_sched', 'G_ece2_sched', 'YouthGrant_sched', 'YouthGrant', ...
    'G_ece_stage1_base', 'G_ece_stage2_base', 'G_ece_base', ...
    'G_ece_stage1', 'G_ece_stage2', 'G_ece', ...
    'w_mult_SS0', 'w_mult_SS1', 'w_mult_SS2', 'Q_mult_SS0', 'Q_mult_SS1', 'Q_mult_SS2', ...
    'super_age', 'Super_Age_SS1', 'Super_Age_SS2', 'tau_l_SS2_req_pct', 'tau_l_delta_SS2', ...
    'Reform_Intensity', 'Phase_Label', 'Enable_Duopoly_Kai', ...
    'active_M_olig_vec', 'active_mu_monop_vec', 'active_phi_local_vec', ...
    'M_olig_reg', 'mu_monop_reg', 'rho_olig_reg', 'rho_farm_reg', 'lambda_col_mult', ...
    'kai_upgrade_share', 'mu_z_reg_vec', 'p_zh_upgrade_vec', 'p_zl_downgrade_v', ...
    'eta_deliv_vec', 's_active_ece_vec', 's_active_ygr_vec', 's_active_elec_vec', 's_active_ece', ...
    'Rollout_Mode', 'Contingency_Policy', 't_wave_yr'};

all_fn = fieldnames(Params);
N_fn   = numel(all_fn);
Tiers     = cell(N_fn, 1);
Contracts = cell(N_fn, 1);
Shapes    = cell(N_fn, 1);
Previews  = cell(N_fn, 1);

ProvStruct = struct();
ProvStruct.TierA_Fields = {};
ProvStruct.TierB_Fields = {};
ProvStruct.TierC_Fields = {};
ProvStruct.TierD_Fields = {};
ProvStruct.Runtime_Fields = {};

for i = 1:N_fn
    fn  = all_fn{i};
    val = Params.(fn);

    if ismember(fn, policy_knobs) || ismember(fn, f_D)
        Tiers{i}     = 'D_Policy_Regime';
        Contracts{i} = 'Apply_Policy_Regime';
        ProvStruct.TierD_Fields{end+1} = fn;
    elseif ismember(fn, f_A)
        Tiers{i}     = 'A_Grid_And_Prefs';
        Contracts{i} = 'Configure_Grid_And_Prefs';
        ProvStruct.TierA_Fields{end+1} = fn;
    elseif ismember(fn, f_B)
        Tiers{i}     = 'B_Empirical_Data';
        Contracts{i} = 'Apply_Empirical_Data';
        ProvStruct.TierB_Fields{end+1} = fn;
    elseif ismember(fn, f_C)
        Tiers{i}     = 'C_Calibrated_Params';
        Contracts{i} = 'Apply_Calibrated_Params';
        ProvStruct.TierC_Fields{end+1} = fn;
    else
        Tiers{i}     = 'W_Workbench_Runtime';
        Contracts{i} = 'Caller / Runtime';
        ProvStruct.Runtime_Fields{end+1} = fn;
    end

    Shapes{i}   = sprintf('%s [%s]', class(val), mat2str(size(val)));
    Previews{i} = preview_value(val);
end

ProvTable = table(all_fn, Tiers, Contracts, Shapes, Previews, ...
    'VariableNames', {'Param_Name', 'Provenance_Tier', 'Contract_Function', 'Type_Shape', 'Value_Preview'});
ProvStruct.Summary_Counts = struct( ...
    'TierA_GridPrefs',   numel(ProvStruct.TierA_Fields), ...
    'TierB_Empirical',   numel(ProvStruct.TierB_Fields), ...
    'TierC_Calibrated',  numel(ProvStruct.TierC_Fields), ...
    'TierD_PolicyRegime',numel(ProvStruct.TierD_Fields), ...
    'Workbench_Runtime', numel(ProvStruct.Runtime_Fields), ...
    'Total',             N_fn);

end

function s = preview_value(v)
if isnumeric(v) || islogical(v)
    if isempty(v)
        s = '[]';
    elseif isscalar(v)
        s = sprintf('%.6g', double(v));
    elseif numel(v) <= 5
        s = mat2str(double(v), 4);
    else
        s = sprintf('min=%.4g, max=%.4g', double(min(v(:))), double(max(v(:))));
    end
elseif ischar(v) || isstring(v)
    s = char(v);
elseif isstruct(v)
    sub = fieldnames(v);
    if isempty(sub)
        s = 'struct()';
    else
        v1 = v.(sub{1});
        if isnumeric(v1) && isscalar(v1)
            s = sprintf('PType struct (%d): %s=%.4g ...', numel(sub), sub{1}, double(v1));
        else
            s = sprintf('PType struct (%d fields)', numel(sub));
        end
    end
elseif iscell(v)
    if numel(v) <= 5 && all(cellfun(@(x) ischar(x) || isstring(x), v(:)))
        s = ['{', strjoin(cellfun(@char, v(:)', 'UniformOutput', false), ', '), '}'];
    else
        s = sprintf('cell (%d elems)', numel(v));
    end
else
    s = class(v);
end
end
