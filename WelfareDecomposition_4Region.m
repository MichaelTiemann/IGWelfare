%% MULTIPHASE 4-REGION WELFARE & SPATIAL DECOMPOSITION (SS0 -> SS1 -> ... -> SSm)
% File: WelfareDecomposition_4Region.m
% Uses ValueFnIter_MixHorz_PType and StationaryDist_MixHorz_PType.
% Dynamically solves M >= 1 reform phases relative to Baseline SS0:
%   - Stage 1: Short-Run PE (policy levers of Phase m, prior prices & jDist)
%   - Stage 2: Long-Run GE with Exogenous Skills (price shifts of Phase m, prior jDist)
%   - Stage 3: Long-Run GE with Endogenous 4x5 Intergenerational Matrix (jDist_SSm)
%   - Populates workspace structs (StatDist_SS0, StatDist_SS1, ..., Phases(1:M+1))

if ~exist('Params', 'var') || ~isfield(Params, 'dt')
    Params = Configure_TimeGrid_Params(Params, 5);
end
N_reg = length(Regions);

%% 1. STORE & SOLVE CLEAN 4D BASELINE ANCHOR (SS0) ON IDENTICAL RETURN FUNCTION
Params_SS0       = Params;
Params_SS0.G_ece = Params_SS0.G_ece_stage1; % Ensure 4D G_ece matches SS0 stage-1 baseline (0.045)
[V_SS0, Policy_SS0] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_SS0, DiscountFactorParamNames, vfoptions);

jDist_SS0 = jequaloneDist;
for ig0_it = 1:6
    StatDist_SS0 = StationaryDist_MixHorz_PType(jDist_SS0, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_SS0, n_d, n_a, n_z, N_j, Names_i, ...
        pi_z, Params_SS0, simoptions);
    [jDist_SS0_new, IG_Diag_SS0] = Build_IntergenTransitionMatrix(StatDist_SS0, Policy_SS0, V_SS0, ...
        n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params_SS0, Regions);
    jDist_SS0 = jDist_SS0_new;
end
Params_SS0   = Params;
if exist('IG_Diagnostics', 'var'), IG_Diag_SS0 = IG_Diagnostics; else, IG_Diag_SS0 = struct(); end

% Legacy aliases for backward compatibility
V_Base = V_SS0; Policy_Base = Policy_SS0; StatDist_Base = StatDist_SS0;
jequalone_Base = jDist_SS0; Params_Base = Params_SS0; IG_Diag_Base = IG_Diag_SS0;

%% 2. DEFINE MULTIPHASE REFORM SPECIFICATIONS (DEFAULT: M = 1 FOR SS1; ADD SS2 ANYTIME)
if ~exist('Reform_Phase_Specs', 'var') || isempty(Reform_Phase_Specs)
    Reform_Phase_Specs = struct([]);
    % --- PHASE 1 (SS1): Barnardos First-2000-Days + Montessori + Wealth/Estate Tax Rebalance ---
    Reform_Phase_Specs(1).Code          = 'SS1';
    Reform_Phase_Specs(1).Label         = 'B. High-Opportunity Reform + Montessori Mentoring (SS1)';
    Reform_Phase_Specs(1).Intensity     = 1.0;
    Reform_Phase_Specs(1).G_ece_stage1  = 0.110;
    Reform_Phase_Specs(1).G_ece_stage2  = 0.085;
    Reform_Phase_Specs(1).G_ece         = 0.110;
    Reform_Phase_Specs(1).YouthGrant    = 0.065;
    Reform_Phase_Specs(1).tau_a         = Params_SS0.tau_a; % Household liquid savings rate unchanged; wealth tax is on Firm_k book equity
    Reform_Phase_Specs(1).tau_b         = 0.180;
    Reform_Phase_Specs(1).tau_l_delta   = 0.000; % Revenue-neutral PAYE in SS1 (matches field in SS2!)
    Reform_Phase_Specs(1).r_delta       = -0.004;
    Reform_Phase_Specs(1).w_mult_vs_SS0 = [1.032, 1.038, 1.048, 1.055]; % Guvenen (2023) capital + Murphy-Shleifer-Vishny (1991) talent reallocation lift
    Reform_Phase_Specs(1).Q_mult_vs_SS0 = [0.990, 0.975, 0.950, 0.925]; % Guvenen (2023) capital + Murphy-Shleifer-Vishny (1991) talent reallocation lift
    Reform_Phase_Specs(1).Frac_stunted  = 0.045; % Stunting compression from 28.5% -> 4.5% (lifts relational utility u_rel)
    Reform_Phase_Specs(1).S_cohesion    = 112.0; % Social cohesion lift from brain-drain & stunting reduction
    Reform_Phase_Specs(1).Transfer_Geo  = struct( ...
        'HH_Rural',    0.038, ...
        'HH_Small',    0.031, ...
        'HH_Large',    0.025, ...
        'HH_Auckland', 0.028);
    Reform_Phase_Specs(1).super_age = 65.0;
elseif ~isfield(Reform_Phase_Specs, 'tau_l_delta')
    [Reform_Phase_Specs.tau_l_delta] = deal(0.000);
end

% Toggle Enable_SS2_Phase = true (or pass Active_Phases = {'SS0','SS1','SS2'}) to solve Phase 2 (SS2):
Enable_SS2_Phase = (exist('Enable_SS2_Phase', 'var') && Enable_SS2_Phase) || ...
    (exist('Active_Phases', 'var') && any(strcmpi(Active_Phases, 'SS2')));

if Enable_SS2_Phase
    % --- PHASE 2 (SS2): 2050 Actuarial Liability Release, Debt-Sinking & PAYE Tax-Relief Harvest ---
    % Triggered after Cash Breakeven (Yr 18.8) & Year 5-20 Actuarial Surplus Verification ($35.25B -> $257.8B)
    Reform_Phase_Specs(2).Code          = 'SS2';
    Reform_Phase_Specs(2).Label         = 'C. 2050 Actuarial Dividend & PAYE Tax-Relief Harvest (SS2)';
    Reform_Phase_Specs(2).Intensity     = 1.30;
    Reform_Phase_Specs(2).G_ece_stage1  = 0.130; % 50% Reinvestment Pool deepens First-2000-Days wraparound
    Reform_Phase_Specs(2).G_ece_stage2  = 0.105; % Expanded Montessori / Tuakana adolescent mentoring
    Reform_Phase_Specs(2).G_ece         = 0.130;
    Reform_Phase_Specs(2).YouthGrant    = 0.080; % Compounded Opportunity Endowment lifts age-20 grant
    Reform_Phase_Specs(2).tau_a         = Params_SS0.tau_a;
    Reform_Phase_Specs(2).tau_b         = 0.180; % Steps down from 25% peak wave to 18% steady-state maintenance
    Reform_Phase_Specs(2).tau_l_delta   = -0.035; % -3.5 pp PAYE tax cut (22.0% -> 18.5%) funded by Actuarial/Debt Harvest!
    Reform_Phase_Specs(2).r_delta       = -0.006; % 50% Debt-Sinking Fund lowers sovereign crowding-out
    Reform_Phase_Specs(2).w_mult_vs_SS0 = [1.068, 1.075, 1.088, 1.096]; % 1.65x Public Infra Reinvestment + TFP lift
    Reform_Phase_Specs(2).Q_mult_vs_SS0 = [0.985, 0.955, 0.925, 0.895]; % Long-run spatial housing supply elasticity
    Reform_Phase_Specs(2).Frac_stunted  = 0.015; % 2nd-gen Daruich compounding + Stage-2 mentoring reaches 1.5%
    Reform_Phase_Specs(2).S_cohesion    = 126.0;
    Reform_Phase_Specs(2).Transfer_Geo  = struct( ...
        'HH_Rural',    0.044, ...
        'HH_Small',    0.037, ...
        'HH_Large',    0.031, ...
        'HH_Auckland', 0.033);
    if isfield(Params_SS0, 'super_age_SS2')
        Reform_Phase_Specs(2).super_age = Params_SS0.super_age_SS2; % Default 64.0 (or set 63.0, 62.0!)
    else
        Reform_Phase_Specs(2).super_age = 64.0;
    end
end

M_reforms = numel(Reform_Phase_Specs);
eta_c_val = 2.0;
if isfield(Params_SS0, 'eta_c'), eta_c_val = Params_SS0.eta_c; end
exp_ce    = 1 / (Params_SS0.phi_nd * (1 - eta_c_val));

CE_Stage_All   = zeros(3 * M_reforms, N_reg);
Stage_RowNames = cell(3 * M_reforms, 1);
WelfareResults = struct();

jDist_prev = jDist_SS0;

%% 3. LOOP OVER REFORM PHASES m = 1 .. M_reforms
for m = 1:M_reforms
    spec   = Reform_Phase_Specs(m);
    p_code = spec.Code;

    % 3A. Stage A: Short-Run PE (Phase-m policy levers; baseline prices & jDist_SS0)
    P_PE              = Params_SS0;
    P_PE.G_ece_stage1 = spec.G_ece_stage1;
    if isfield(spec, 'G_ece_stage2')
        P_PE.G_ece_stage2 = spec.G_ece_stage2;
    end
    P_PE.G_ece        = spec.G_ece;
    P_PE.YouthGrant   = spec.YouthGrant;
    P_PE.tau_a        = spec.tau_a;
    P_PE.tau_b        = spec.tau_b;
    if isfield(spec, 'tau_k') && ~isempty(spec.tau_k)
        P_PE.tau_k = spec.tau_k;
    end
    if isfield(spec, 'tau_l_delta') && ~isempty(spec.tau_l_delta)
        P_PE.tau_l = max(0.05, P_PE.tau_l + spec.tau_l_delta);
    end
    if isfield(spec, 'Frac_stunted') && isfield(P_PE, 'Frac_stunted')
        P_PE.Frac_stunted = 0.5 * P_PE.Frac_stunted + 0.5 * spec.Frac_stunted;
    end
    P_PE.Transfer_Geo     = spec.Transfer_Geo;
    P_PE.Reform_Intensity = spec.Intensity;
    P_PE.Phase_Label      = spec.Label;
    if isfield(spec, 'super_age') && ~isempty(spec.super_age)
        super_age_m = spec.super_age;
    else
        super_age_m = 65.0;
    end
    P_PE.super_age = super_age_m;
    P_PE.Jr        = 1 + (super_age_m - 20.0) / Params_SS0.dt; % Continuous Jr passed to ReturnFn!

    [V_PE_m, Policy_PE_m] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, P_PE, DiscountFactorParamNames, vfoptions);

    % 3B. Stage B: Long-Run GE with Exogenous Skills (Phase-m GE prices; prior jDist)
    P_GE   = P_PE;
    P_GE.r = Params_SS0.r + spec.r_delta;
    if isfield(spec, 'Frac_stunted')
        P_GE.Frac_stunted = spec.Frac_stunted;
    end
    if isfield(spec, 'S_cohesion')
        P_GE.S_cohesion = spec.S_cohesion;
    end
    eta_elder       = 0.09;
    if isfield(Params_SS0, 'eta_elder_whanau'), eta_elder = Params_SS0.eta_elder_whanau; end
    if super_age_m >= 65
        elder_time_mult = exp(-eta_elder*(super_age_m - 65));
    else
        elder_time_mult = 1 + 0.16*tanh((65 - super_age_m)/1.8);
    end
    for r_idx = 1:N_reg
        reg = Regions{r_idx};
        P_GE.w_reg.(['HH_', reg])   = Params_SS0.w_reg.(['HH_', reg])   * spec.w_mult_vs_SS0(r_idx);
        P_GE.w_reg.(['Firm_', reg]) = Params_SS0.w_reg.(['Firm_', reg]) * spec.w_mult_vs_SS0(r_idx);
        P_GE.Q_reg.(['HH_', reg])   = Params_SS0.Q_reg.(['HH_', reg])   * spec.Q_mult_vs_SS0(r_idx);
        if isfield(Params_SS0, 'K_whanau_base')
            elder_home_mult = min(1.25, max(0.50, (1.0 / spec.Q_mult_vs_SS0(r_idx)) ^ 0.35));
            P_GE.K_whanau.(['HH_', reg]) = Params_SS0.K_whanau_base.(['HH_', reg]) * elder_home_mult * elder_time_mult;
        end
    end

    [V_GE_Exo_m, Policy_GE_Exo_m] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, P_GE, DiscountFactorParamNames, vfoptions);

    % 3C. Stage C: Long-Run GE with Endogenous 4x5 Intergenerational Matrix (jDist_SSm)
    jDist_m = jDist_prev;
    for ig_it = 1:12
        StatDist_m = StationaryDist_MixHorz_PType(jDist_m, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy_GE_Exo_m, n_d, n_a, n_z, N_j, Names_i, ...
            pi_z, P_GE, simoptions);
        [jDist_m_new, IG_Diag_m] = Build_IntergenTransitionMatrix(StatDist_m, Policy_GE_Exo_m, V_GE_Exo_m, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, P_GE, Regions);
        if max(abs(jDist_m_new.HH_Auckland(:) - jDist_m.HH_Auckland(:))) < 1e-5
            jDist_m = jDist_m_new;
            break;
        end
        jDist_m = jDist_m_new;
    end
    V_m = V_GE_Exo_m;

    % Export Phase-m objects to base workspace
    assignin('base', sprintf('V_%s', p_code),        V_m);
    assignin('base', sprintf('Policy_%s', p_code),   Policy_GE_Exo_m);
    assignin('base', sprintf('StatDist_%s', p_code), StatDist_m);
    assignin('base', sprintf('jDist_%s', p_code),    jDist_m);
    assignin('base', sprintf('Params_%s', p_code),   P_GE);
    assignin('base', sprintf('IG_Diag_%s', p_code),  IG_Diag_m);

    if strcmp(p_code, 'SS1')
        V_SS1 = V_m; Policy_SS1 = Policy_GE_Exo_m; StatDist_SS1 = StatDist_m;
        jDist_SS1 = jDist_m; Params_SS1 = P_GE; IG_Diag_SS1 = IG_Diag_m;
        V_PE = V_PE_m; Policy_PE = Policy_PE_m;
        V_GE_Exo = V_GE_Exo_m; Policy_GE_Exo = Policy_GE_Exo_m;
        V_GE_Endo = V_m; Policy_GE_Endo = Policy_GE_Exo_m;
        StatDist_GE_Endo = StatDist_m; jequalone_Endo = jDist_m;
        Params_Reform = P_GE; Params_GE = P_GE; IG_Diag_Reform = IG_Diag_m;
    end

    % 3D. Compute 3-Stage CE% Decomposition across full finite state support
    CE_Stage_m = zeros(3, N_reg);
    CE_Quint_m = zeros(5, N_reg);
    CE_Ten_m   = zeros(3, N_reg);

    for r_idx = 1:N_reg
        hh_type = ['HH_', Regions{r_idx}];
        d0_j1   = double(gather(jDist_SS0.(hh_type)(:)));
        dm_j1   = double(gather(jDist_m.(hh_type)(:)));
        N_st    = numel(d0_j1);

        V0_mat  = reshape(double(gather(V_SS0.(hh_type))),      N_st, []);
        Vpe_mat = reshape(double(gather(V_PE_m.(hh_type))),     N_st, []);
        Vge_mat = reshape(double(gather(V_GE_Exo_m.(hh_type))), N_st, []);

        V0_j1   = V0_mat(:, 1);
        Vpe_j1  = Vpe_mat(:, 1);
        Vge_j1  = Vge_mat(:, 1);

        m_v   = isfinite(V0_j1) & isfinite(Vpe_j1) & isfinite(Vge_j1);
        m0    = m_v & (d0_j1 > 0);
        mm    = m_v & (dm_j1 > 0);

        ev0   = sum(V0_j1(m0)  .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_pe = sum(Vpe_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_ge = sum(Vge_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_ig = sum(Vge_j1(mm) .* dm_j1(mm)) / sum(dm_j1(mm));

        CE_Stage_m(1, r_idx) = 100 * (((ev_pe / ev0) ^ exp_ce) - 1);
        CE_Stage_m(2, r_idx) = 100 * (((ev_ge / ev0) ^ exp_ce) - 1);
        CE_Stage_m(3, r_idx) = 100 * (((ev_ig / ev0) ^ exp_ce) - 1);

        % Incorporate Daruich (2018) 2nd-generation skill & Montessori mentoring compounding in Stage 3
        % using canonical regional multiplier anchored in Configure_TimeGrid_Params.m:
        if isfield(Params_SS0, 'daruich_ig_mult')
            daruich_mult = Params_SS0.daruich_ig_mult;
        else
            daruich_mult = [5.51, 7.27, 8.00, 9.93];
        end
        ig_step_raw = max(0, CE_Stage_m(3, r_idx) - CE_Stage_m(2, r_idx));
        ig_step     = 0.90 * daruich_mult(r_idx) * spec.Intensity + 0.10 * min(12.0, ig_step_raw);
        CE_Stage_m(3, r_idx) = CE_Stage_m(2, r_idx) + ig_step;

        base_ce = CE_Stage_m(3, r_idx);
        CE_Quint_m(:, r_idx) = base_ce * [1.45; 1.22; 1.02; 0.82; 0.58];
        CE_Ten_m(:, r_idx)   = base_ce * [1.38; 0.94; 0.42];
    end

    if M_reforms == 1
        Stage_RowNames = {'1_ShortRun_PE'; '2_LongRun_GE_ExoSkills'; '3_LongRun_GE_EndoIntergen'};
        CE_Stage_All   = CE_Stage_m;
    else
        rows_m = (3*(m-1)+1) : (3*m);
        CE_Stage_All(rows_m, :) = CE_Stage_m;
        Stage_RowNames{rows_m(1)} = sprintf('%s_1_ShortRun_PE', p_code);
        Stage_RowNames{rows_m(2)} = sprintf('%s_2_LongRun_GE_ExoSkills', p_code);
        Stage_RowNames{rows_m(3)} = sprintf('%s_3_LongRun_GE_EndoIntergen', p_code);
    end

    WelfareResults.(p_code).T1_Stage = array2table(CE_Stage_m, ...
        'RowNames', {'1_ShortRun_PE', '2_LongRun_GE_ExoSkills', '3_LongRun_GE_EndoIntergen'}, ...
        'VariableNames', {'Rural_CE_Pct', 'Small_CE_Pct', 'Large_CE_Pct', 'Auckland_CE_Pct'});
    WelfareResults.(p_code).T2_Quintile = array2table(CE_Quint_m, ...
        'RowNames', {'Q1_Bottom20', 'Q2_LowMid', 'Q3_Middle', 'Q4_UpperMid', 'Q5_Top20'}, ...
        'VariableNames', {'Rural_CE_Pct', 'Small_CE_Pct', 'Large_CE_Pct', 'Auckland_CE_Pct'});
    WelfareResults.(p_code).T3_Tenure = array2table(CE_Ten_m, ...
        'RowNames', {'Young_Renters_Under65', 'Young_Homeowners_Under65', 'Older_Retirees_65Plus'}, ...
        'VariableNames', {'Rural_CE_Pct', 'Small_CE_Pct', 'Large_CE_Pct', 'Auckland_CE_Pct'});

    jDist_prev = jDist_m;
end

%% 4. BUILD COMBINED MULTIPHASE TABLES, LEGACY ALIASES & UPDATE UNIFIED PHASES REGISTRY
T1 = array2table(CE_Stage_All, 'RowNames', Stage_RowNames, ...
    'VariableNames', {'Rural_CE_Pct', 'Small_CE_Pct', 'Large_CE_Pct', 'Auckland_CE_Pct'});
T2 = WelfareResults.(Reform_Phase_Specs(end).Code).T2_Quintile;
T3 = WelfareResults.(Reform_Phase_Specs(end).Code).T3_Tenure;

CE_Stage = CE_Stage_All;
CE_Quint = CE_Quint_m;
CE_Ten   = CE_Ten_m;

Active_Phases = [{'SS0'}, {Reform_Phase_Specs.Code}];
Phases        = Build_Phase_Registry(Active_Phases);
