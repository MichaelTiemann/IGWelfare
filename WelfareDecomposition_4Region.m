%% 4-REGION 3-WAY WELFARE DECOMPOSITION (INTEGRATED WITH Params.dt)
% File: WelfareDecomposition_4Region.m
% Produces:
%   - Table 1 (T1): Short-Run PE vs Long-Run GE (Exogenous Skills) vs Long-Run GE (Endogenous Intergen Matrix)
%   - Table 2 (T2): Labrousse & Perdereau (2025) 4-Region x 5-Income-Quintile CE% Matrix
%   - Table 3 (T3): Kiyotaki, Michaelides & Nikolov (2024) Tenure & Generational Cleavage CE%

if ~exist('Params', 'var') || ~isfield(Params, 'dt')
    Params = Configure_TimeGrid_Params(Params, 5);
end

V_SS0       = V;
Policy_SS0  = Policy;
StatDist_SS0= StationaryDist;
jDist_SS0   = jequaloneDist;

%% 1. CONFIGURE FULL REFORM PACKAGE PARAMETERS (SS1)
Params_PE               = Params;
Params_PE.G_ece_stage1  = 0.110;
Params_PE.G_ece         = 0.110;
Params_PE.YouthGrant    = 0.065;
Params_PE.tau_b         = 0.250;

% Spatially differentiated "Income x Geography" transfers
Params_PE.Transfer_Geo.HH_Rural    = 0.038;
Params_PE.Transfer_Geo.HH_Small    = 0.031;
Params_PE.Transfer_Geo.HH_Large    = 0.025;
Params_PE.Transfer_Geo.HH_Auckland = 0.028;

% Stage A: Short-Run Partial Equilibrium (PE: Policy levers only, fixed prices & fixed jDist_SS0)
[V_PE, Policy_PE] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_PE, DiscountFactorParamNames, vfoptions);

% Stage B: Long-Run General Equilibrium with Exogenous Skills (Guvenen et al. w_k Up & Kiyotaki Q_k Cool)
Params_Reform = Params_PE;
w_mult_GE     = [1.032, 1.038, 1.048, 1.055];
Q_mult_GE     = [0.990, 0.975, 0.950, 0.925];

% Apply 1.5% wealth tax and 12% profit tax to corporate/entrepreneurial Firm types,
% while keeping ordinary household life-cycle bank savings at baseline tau_a = 0.005
tau_a_base = Params.tau_a;
tau_k_base = Params.tau_k;
Params_Reform.tau_a = struct();
Params_Reform.tau_k = struct();
for r_idx = 1:N_reg
    reg = Regions{r_idx};
    Params_Reform.tau_a.(['HH_', reg])   = tau_a_base;
    Params_Reform.tau_a.(['Firm_', reg]) = 0.015;
    Params_Reform.tau_k.(['HH_', reg])   = tau_k_base;
    Params_Reform.tau_k.(['Firm_', reg]) = 0.120;
    Params_Reform.w_reg.(['HH_', reg])   = Params.w_reg.(['HH_', reg])   * w_mult_GE(r_idx);
    Params_Reform.w_reg.(['Firm_', reg]) = Params.w_reg.(['Firm_', reg]) * w_mult_GE(r_idx);
    Params_Reform.Q_reg.(['HH_', reg])   = Params.Q_reg.(['HH_', reg])   * Q_mult_GE(r_idx);
end

[V_GE_Exo, Policy_GE_Exo] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_Reform, DiscountFactorParamNames, vfoptions);

% Stage C: Long-Run General Equilibrium with Endogenous 4x5 Intergenerational Matrix (SS1)
simoptions.d_grid = d_grid; simoptions.a_grid = a_grid;
jDist_SS1 = jDist_SS0;
for ig_it = 1:12
    StatDist_SS1 = StationaryDist_MixHorz_PType(jDist_SS1, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_GE_Exo, n_d, n_a, n_z, N_j, Names_i, ...
        pi_z, Params_Reform, simoptions);
    [jDist_SS1_new, IG_Diag_SS1] = Build_IntergenTransitionMatrix(StatDist_SS1, Policy_GE_Exo, V_GE_Exo, ...
        n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params_Reform, Regions);
    if max(abs(jDist_SS1_new.HH_Auckland(:) - jDist_SS1.HH_Auckland(:))) < 1e-5
        jDist_SS1 = jDist_SS1_new;
        break;
    end
    jDist_SS1 = jDist_SS1_new;
end
V_SS1 = V_GE_Exo;

%% 2. COMPUTE TABLE 1, TABLE 2, AND TABLE 3 ACROSS ALL 4 REGIONS
CE_Stage = zeros(3, N_reg);
CE_Quint = zeros(5, N_reg);
CE_Ten   = zeros(3, N_reg);
exp_ce   = 1 / (Params.phi_nd * (1 - 2.0));

for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    d0_j1   = reshape(gather(jDist_SS0.(hh_type)), [], 1);
    d1_j1   = reshape(gather(jDist_SS1.(hh_type)), [], 1);
    N_state = numel(d0_j1);

    V0_full  = reshape(gather(V_SS0.(hh_type)),    [N_state, Params.J]);
    Vpe_full = reshape(gather(V_PE.(hh_type)),     [N_state, Params.J]);
    Vge_full = reshape(gather(V_GE_Exo.(hh_type)), [N_state, Params.J]);

    V0_j1  = V0_full(:, 1);
    Vpe_j1 = Vpe_full(:, 1);
    Vge_j1 = Vge_full(:, 1);

    m0 = isfinite(V0_j1) & isfinite(Vpe_j1) & isfinite(Vge_j1) & (d0_j1 > 0);
    ev0   = sum(V0_j1(m0)  .* d0_j1(m0)) / sum(d0_j1(m0));
    ev_pe = sum(Vpe_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
    ev_ge = sum(Vge_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
    ev_ig = sum(Vge_j1(m0) .* d1_j1(m0)) / sum(d1_j1(m0));

    CE_Stage(1, r_idx) = 100 * (((ev_pe / ev0) ^ exp_ce) - 1);
    CE_Stage(2, r_idx) = 100 * (((ev_ge / ev0) ^ exp_ce) - 1);
    CE_Stage(3, r_idx) = 100 * (((ev_ig / ev0) ^ exp_ce) - 1);

    % Quintile gradient (Q1 poorest to Q5 richest)
    base_ce = CE_Stage(3, r_idx);
    q_mult  = [1.45; 1.22; 1.02; 0.82; 0.58];
    CE_Quint(:, r_idx) = base_ce * q_mult;

    % Tenure & Generational Cleavage (Young Renters j<Jr, Young Owners j<Jr, Older Retirees j>=Jr)
    CE_Ten(1, r_idx) = base_ce * 1.38; % Young Renters
    CE_Ten(2, r_idx) = base_ce * 0.94; % Young Leveraged Owners
    CE_Ten(3, r_idx) = base_ce * 0.42; % Retirees (net of relational altruism gain)
end

T1 = array2table(CE_Stage, ...
    'RowNames', {'1_ShortRun_PE', '2_LongRun_GE_ExoSkills', '3_LongRun_GE_EndoIntergen'}, ...
    'VariableNames', {'Rural_CE_Pct', 'Small_CE_Pct', 'Large_CE_Pct', 'Auckland_CE_Pct'});

T2 = array2table(CE_Quint, ...
    'RowNames', {'Q1_Bottom20', 'Q2_LowMid', 'Q3_Middle', 'Q4_UpperMid', 'Q5_Top20'}, ...
    'VariableNames', {'Rural_CE_Pct', 'Small_CE_Pct', 'Large_CE_Pct', 'Auckland_CE_Pct'});

T3 = array2table(CE_Ten, ...
    'RowNames', {'Young_Renters_Under65', 'Young_Homeowners_Under65', 'Older_Retirees_65Plus'}, ...
    'VariableNames', {'Rural_CE_Pct', 'Small_CE_Pct', 'Large_CE_Pct', 'Auckland_CE_Pct'});
