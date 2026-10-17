%% MIXED FINITE/INFINITE HORIZON INTERGENERATIONAL MODEL (VFI TOOLKIT)
% Permanent Types:
%   1. 'Household' -> Finite Horizon (N_j = 16): Child investment (Lens 1),
%                     Ben-Porath/Labor/Fertility (Lens 2), Retirement/Bequests (Lens 3)
%   2. 'Firm'      -> Infinite Horizon (N_j = Inf): Guvenen et al. (2023) / 
%                     Ferriere et al. (2025) production, collateral constraints,
%                     and wealth-tax "use-it-or-lose-it" capital reallocation.

clear; clc; close all;

%% 1. DEFINE PERMANENT TYPES & HORIZONS
Names_i = {'Household', 'Firm'};
PTypeDistParamNames = {'PTypeWeights'};
Params.PTypeWeights = [0.90; 0.10]; % 90% Household mass, 10% Entrepreneurial Firm mass

% Horizon distinction: Finite for Households, Infinite for Firms
N_j.Household = 16;  % Ages 20 to 99 (5-yr periods), Retirement at Jr = 10 (Age 65)
N_j.Firm      = Inf; % Infinite horizon dynamic firm problem

%% 2. HOUSEHOLD GRIDS & DEMOGRAPHICS (FINITE HORIZON)
Params.J  = N_j.Household;
Params.Jr = 10;
Params.agej = 1:Params.J;

% Survival probabilities (sj) and cohort demographic weights (mewj)
Params.sj = [0.995, 0.994, 0.993, 0.991, 0.988, 0.983, 0.975, 0.962, ...
             0.942, 0.910, 0.860, 0.780, 0.660, 0.500, 0.300, 0.000];
Params.n_pop = 0.005;
mewj = ones(1, Params.J);
for jj = 2:Params.J
    mewj(jj) = mewj(jj-1) * Params.sj(jj-1) / (1 + Params.n_pop)^5;
end
AgeWeightsParamNames = {'mewj'};
Params.mewj = mewj ./ sum(mewj);

% Household Decisions d: [Labor (l), Ben-Porath Training (I_h), Child Investment (i_c)]
n_d.Household = [4, 4, 6];
d_grid_l  = [0; 0.5; 0.8; 1.0];           % Zero, Part-time, Full-time, Overtime (Source 3)
d_grid_Ih = linspace(0, 0.35, 4)';        % On-the-job skill investment (Source 3)
d_grid_ic = linspace(0, 0.40, 6)';        % Private early-childhood investment (Sources 1, 8)
d_grid.Household = [d_grid_l; d_grid_Ih; d_grid_ic];

% Household Endogenous States a: [Assets (a_h), Human Capital (h)]
n_a.Household = [101, 7];
a_grid_ah = 15 * (linspace(0, 1, n_a.Household(1)).^3)'; % Aiyagari asset grid (a >= 0)
a_grid_hc = linspace(0.5, 2.0, n_a.Household(2))';       % Continuous/tiered human capital grid
a_grid.Household = [a_grid_ah; a_grid_hc];

% Household Exogenous Shock z: Idiosyncratic labor productivity (Aiyagari / Source 1)
n_z.Household = 5;
[z_grid.Household, pi_z.Household] = discretizeAR1_Tauchen(0, 0.85, 0.15, n_z.Household);
z_grid.Household = exp(z_grid.Household);

%% 3. FIRM GRIDS & MARKOV PROCESS (INFINITE HORIZON)
% Firm has no discrete d_grid needed if static k and n are solved inside ReturnFn
n_d.Firm = 0;
d_grid.Firm = [];

% Firm Endogenous State a: [Internal Net Worth / Equity (a_f)]
n_a.Firm = 121;
a_grid.Firm = 25 * (linspace(0.001, 1, n_a.Firm).^2.5)';

% Firm Exogenous State z: Persistent Productivity (z_l vs z_h, Guvenen et al. Source 6)
n_z.Firm = 2;
z_grid.Firm = [0.75; 1.45]; % Low-productivity vs High-productivity firm technology
pi_z.Firm   = [0.85, 0.15; 
               0.15, 0.85]; % First-order Markov transition P(z'|z) (Source 6, App E)

%% 4. CALIBRATED PARAMETERS ACROSS LENSES
% Discount factors
DiscountFactorParamNames.Household = {'beta_hh', 'sj'};
DiscountFactorParamNames.Firm      = {'beta_firm'};
Params.beta_hh   = 0.96^5; % 5-year household discount factor
Params.beta_firm = 0.95^5; % Infinite-horizon firm/entrepreneur discount factor

% Household Preferences & Stone-Geary / Ben-Porath parameters (Sources 1, 2, 3, 8)
Params.eta_c       = 2.0;   % CRRA curvature
Params.psi_l       = 1.2;   % Labor disutility
Params.G_ece       = 0.05;  % Public in-kind child investment (ECE / First 2000 days)
Params.gbar_ece    = 0.02;  % Stone-Geary luxury parameter (Source 1)
Params.s_sub       = 0.10;  % Subsidy rate on private child investment (Source 1)
Params.omega_ic    = 0.35;  % Parental utility/altruism weight on child quality
Params.Ext_child   = 0.02;  % Pro-equality externality X_t from child thriving (Source 1)
Params.delta_hc    = 0.086; % Human capital depreciation rate (Fan, Seshadri, Taber Table 3)
Params.alpha_I     = 0.098; % Ben-Porath I elasticity (Source 3, Table 3)
Params.alpha_H     = 0.051; % Ben-Porath H elasticity (Source 3, Table 3)

% Retirement & Bequest Parameters (Sources 3, 5, 9)
Params.p_super     = 0.18;  % Universal NZ Superannuation
Params.c_floor     = 0.04;  % Retirement consumption floor (Source 3)
Params.b1_beq      = 3.50;  % Warm-glow bequest weight
Params.b2_beq      = 0.40;  % Bequest luxury shifter (De Nardi 2004 / Source 3)
Params.YouthGrant  = 0.03;  % Universal youth endowment E funded by tau_b (Source 9)

% Firm Production & Collateral Constraint Parameters (Guvenen et al. Source 6)
Params.alpha_k     = 0.33;  % Capital share
Params.lambda_col  = 1.80;  % Collateral constraint multiplier (k <= lambda * a_f)
Params.delta_k     = 1 - (1 - 0.06)^5; % 5-year physical capital depreciation

% Tax Policy Levers (Sources 1, 5, 6, 9)
Params.tau_l = 0.22; % Labor income tax
Params.tau_c = 0.15; % NZ GST / Consumption tax (Source 1)
Params.tau_k = 0.20; % Capital / corporate profit tax (Source 6)
Params.tau_a = 0.01; % Book-value wealth tax (5-yr compounded, Source 6)
Params.tau_b = 0.15; % Inheritance / bequest tax (Source 9)

% Initial General Equilibrium Price Guesses
Params.r = 0.20; % 5-year equilibrium bond return
Params.w = 1.00; % Equilibrium wage per efficiency unit of labor

%% 5. DEFINE RETURN FUNCTIONS BY PERMANENT TYPE
ReturnFn.Household = @(l, Ih, ic, aprime, hprime, a, h, z, ...
    w, r, p_super, c_floor, G_ece, gbar_ece, s_sub, omega_ic, Ext_child, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_b, eta_c, psi_l, agej, Jr, sj) ...
    ReturnFn_Household(l, Ih, ic, aprime, hprime, a, h, z, ...
    w, r, p_super, c_floor, G_ece, gbar_ece, s_sub, omega_ic, Ext_child, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_b, eta_c, psi_l, agej, Jr, sj);

ReturnFn.Firm = @(aprime, a, z, w, r, alpha_k, lambda_col, delta_k, tau_k, tau_a) ...
    ReturnFn_Firm(aprime, a, z, w, r, alpha_k, lambda_col, delta_k, tau_k, tau_a);

%% 6. SOLVE VALUE FUNCTIONS (AUTOMATIC FINITE + INFINITE DISPATCH)
vfoptions.verbose = 1;
[V, Policy] = ValueFnIter_PType(n_d, n_a, n_z, N_j, Names_i, ...
              d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, ...
              DiscountFactorParamNames, vfoptions);

%% 7. SOLVE STATIONARY DISTRIBUTIONS ACROSS TYPES
% Initial distribution for newborn Finite-Horizon Households (j=1, Age 20)
jequaloneDist.Household = zeros([n_a.Household, n_z.Household]);
% Place newborns at zero private assets (grant E enters budget at j=1) and distribute across h
h_init_dist = [0.15, 0.20, 0.25, 0.20, 0.10, 0.05, 0.05]; % 15% stunted in lowest tier
z_stat_hh   = ones(n_z.Household, 1) / n_z.Household;
for hh = 1:n_a.Household(2)
    for zz = 1:n_z.Household
        jequaloneDist.Household(1, hh, zz) = h_init_dist(hh) * z_stat_hh(zz);
    end
end

simoptions.verbose = 0;
StationaryDist = StationaryDist_PType(jequaloneDist, AgeWeightsParamNames, ...
                 PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, Names_i, ...
                 d_grid, a_grid, z_grid, pi_z, Params, simoptions);

%% 8. EVALUATE CROSS-SECTOR AGGREGATES & GENERAL EQUILIBRIUM EQUATIONS
% 1. Effective Labor Supply (Households only)
FnsToEvaluate.L_supply.Household = @(l, Ih, ic, aprime, hprime, a, h, z, agej, Jr) ...
    (agej < Jr) * l * max(0, 1 - Ih) * h * z;
FnsToEvaluate.L_supply.Firm = @(aprime, a, z) 0;

% 2. Labor Demand (Firms only, from Guvenen et al. Eq 5 & 7)
FnsToEvaluate.L_demand.Household = @(l, Ih, ic, aprime, hprime, a, h, z) 0;
FnsToEvaluate.L_demand.Firm = @(aprime, a, z, w, r, alpha_k, lambda_col, delta_k) ...
    ((alpha_k * ((1-alpha_k)/w)^((1-alpha_k)/alpha_k) * z > (r + delta_k)) * lambda_col * a) ...
    * (((1-alpha_k)/w)^(1/alpha_k)) * (z^(1/alpha_k));

% 3. Net Bond Market Supply (Household savings minus Firm net borrowing)
FnsToEvaluate.BondNetSupply.Household = @(l, Ih, ic, aprime, hprime, a, h, z) a;
FnsToEvaluate.BondNetSupply.Firm = @(aprime, a, z, w, r, alpha_k, lambda_col, delta_k) ...
    a - ((alpha_k * ((1-alpha_k)/w)^((1-alpha_k)/alpha_k) * z > (r + delta_k)) * lambda_col * a);

AggVars = EvalFnOnAgentDist_AggVars_PType(StationaryDist, Policy, FnsToEvaluate, ...
          Params, n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, z_grid, simoptions);

fprintf('\n=== MIXED FINITE/INFINITE HORIZON DIAGNOSTICS ===\n');
fprintf('Aggregate Household Effective Labor Supply: %.4f\n', AggVars.L_supply.Mean);
fprintf('Aggregate Infinite-Horizon Firm Labor Demand: %.4f\n', AggVars.L_demand.Mean);
fprintf('Net Bond Market Excess Supply:                %.4f\n', AggVars.BondNetSupply.Mean);
