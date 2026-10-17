%% NEW ZEALAND 3-REGION INTERGENERATIONAL OLG MODEL (VFI TOOLKIT)
% Regions (k = 1, 2, 3):
%   1. 'Rural'    : Provincial & Agricultural NZ (~20% pop)
%   2. 'Urban'    : Regional Cities - Wellington, Chch, Hamilton, Tauranga, Dunedin (~47% pop)
%   3. 'Auckland' : Primate Metropolitan Agglomeration / "Paris" Analog (~33-35% pop)
% Horizons:
%   - Households ('HH_Rural', 'HH_Urban', 'HH_Auckland'): Finite Horizon (J = 16, Ages 20-99)
%   - Firms ('Firm_Rural', 'Firm_Urban', 'Firm_Auckland'): Infinite Horizon (N_j = Inf)

clear; clc; close all;

%% 1. DEFINE 6 PERMANENT TYPES (3 REGIONS x 2 SECTORS)
Regions = {'Rural', 'Urban', 'Auckland'};
Names_i = {'HH_Rural', 'HH_Urban', 'HH_Auckland', ...
           'Firm_Rural', 'Firm_Urban', 'Firm_Auckland'};
PTypeDistParamNames = {'PTypeWeights'};

% Initial Population & Firm Shares (90% Household mass, 10% Entrepreneurial Firm mass)
% Within Households: 20% Rural, 46% Urban, 34% Auckland (Stats NZ benchmark)
Params.PTypeWeights = [0.180; 0.414; 0.306; ... % HH_Rural, HH_Urban, HH_Auckland
                       0.020; 0.046; 0.034];    % Firm_Rural, Firm_Urban, Firm_Auckland

for r_idx = 1:3
    reg = Regions{r_idx};
    N_j.(['HH_', reg])   = 16;  % Finite horizon: 5-yr age brackets 20-24 (j=1) to 95-99 (j=16)
    N_j.(['Firm_', reg]) = Inf; % Infinite horizon entrepreneurial firms
end

Params.J    = 16;
Params.Jr   = 10; % Retirement at Age 65 (j=10)
Params.agej = 1:Params.J;

%% 2. TREASURY OLG DEMOGRAPHIC TRANSITION MATRIX (Binning et al. 2024, Source 1)
% Survival probabilities sj and fertility vector fj (Stats NZ 2024-base projections, Sources 1, 5)
Params.sj = [0.995, 0.994, 0.993, 0.991, 0.988, 0.983, 0.975, 0.962, ...
             0.942, 0.910, 0.860, 0.780, 0.660, 0.500, 0.300, 0.000];
% Total Fertility Rate ~ 1.65 (Stats NZ median projection, Source 1 Fig 2), concentrated in j=2,3,4
Params.fj = [0.15, 0.65, 0.65, 0.20, zeros(1, 12)]; 
% Net Migration age-impulse M_j (Stats NZ +25k/yr: positive at j=1 & j>=4, negative brain-drain at j=2,3)
Params.mig_rate_j = [0.018, -0.012, -0.005, 0.015, 0.010, 0.006, 0.003, zeros(1, 9)];

% Build Treasury Demographic Matrix T_demo (Source 1, Appendix Eq 3-4)
T_demo = zeros(Params.J, Params.J);
T_demo(1, :) = Params.fj * 0.5; % Newborn cohort entry per parent
for jj = 1:(Params.J - 1)
    T_demo(jj+1, jj) = Params.sj(jj);
end
% Compute stationary cohort weights mewj including net migration impulse
N_pop = ones(Params.J, 1) / Params.J;
for iter = 1:200
    N_pop = T_demo * N_pop + Params.mig_rate_j' .* N_pop;
    N_pop = max(0, N_pop) / sum(max(0, N_pop));
end
AgeWeightsParamNames = {'mewj'};
Params.mewj = N_pop';

% Check 65+ Dependency Ratio (Ratio of 65+ to working age 20-64, Sources 1, 5, 6)
DepRatio_65plus = sum(Params.mewj(Params.Jr:end)) / sum(Params.mewj(1:Params.Jr-1));
fprintf('Calibrated 65+ Dependency Ratio: %.2f (Workers per 65+: %.2f)\n', ...
        100*DepRatio_65plus, 1/DepRatio_65plus);

%% 3. GRIDS ACROSS ALL 3 REGIONS
for r_idx = 1:3
    hh_type   = ['HH_', Regions{r_idx}];
    firm_type = ['Firm_', Regions{r_idx}];
    
    % Household Decisions d: [Labor (l), Ben-Porath Training (Ih), Child Investment (ic)]
    n_d.(hh_type)    = [4, 3, 7];
    d_grid.(hh_type) = [[0; 0.5; 0.8; 1.0]; linspace(0, 0.30, 3)'; linspace(0, 0.50, 7)'];
    
    % Household Endogenous States a: [Consolidated Net Worth (a), Human Capital Tier (h)]
    % 7 Human Capital tiers: h(1), h(2) = Stunted/Hardship (~22% Dunedin Study cohort, Source 6)
    n_a.(hh_type)    = [81, 7];
    a_grid_assets    = 25 * (linspace(0, 1, n_a.(hh_type)(1)).^3)';
    a_grid_hc        = [0.45; 0.65; 0.85; 1.00; 1.20; 1.45; 1.80];
    a_grid.(hh_type) = [a_grid_assets; a_grid_hc];
    
    % Exogenous Productivity Shock z (Region-specific mean & variance, Labrousse & Perdereau Sec 3.1)
    n_z.(hh_type) = 5;
    
    % Firm Grids
    n_d.(firm_type) = 0; d_grid.(firm_type) = [];
    n_a.(firm_type) = 81;
    a_grid.(firm_type) = 30 * (linspace(0.001, 1, n_a.(firm_type)).^2.5)';
    n_z.(firm_type) = 2;
    pi_z.(firm_type) = [0.85, 0.15; 0.15, 0.85];
end

% Regional Income Process Calibration (Labrousse & Perdereau Fig 5b: Rural compressed, Auckland fat-tailed)
[z_grid.HH_Rural,    pi_z.HH_Rural]    = discretizeAR1_Tauchen(-0.05, 0.85, 0.11, 5);
[z_grid.HH_Urban,    pi_z.HH_Urban]    = discretizeAR1_Tauchen( 0.04, 0.85, 0.16, 5);
[z_grid.HH_Auckland, pi_z.HH_Auckland] = discretizeAR1_Tauchen( 0.15, 0.85, 0.24, 5);
z_grid.HH_Rural    = exp(z_grid.HH_Rural);
z_grid.HH_Urban    = exp(z_grid.HH_Urban);
z_grid.HH_Auckland = exp(z_grid.HH_Auckland);

% Regional Firm Productivity Ceilings (Agriculture/Primary vs Regional vs Auckland Knowledge Hub)
z_grid.Firm_Rural    = [0.70; 1.15];
z_grid.Firm_Urban    = [0.80; 1.40];
z_grid.Firm_Auckland = [0.90; 1.75];

%% 4. REGIONAL HOUSING, ENERGY & INTERGENERATIONAL PARAMETERS
for r_idx = 1:3
    DiscountFactorParamNames.(['HH_', Regions{r_idx}])   = {'beta_hh', 'sj'};
    DiscountFactorParamNames.(['Firm_', Regions{r_idx}]) = {'beta_firm'};
end
Params.beta_hh   = 0.96^5;
Params.beta_firm = 0.95^5;

% Regional Trend Growth G(k) -> Drives Auckland Land Overvaluation (Favilukis et al. Source 12)
Params.G_reg.HH_Rural    = 1.007;
Params.G_reg.HH_Urban    = 1.015;
Params.G_reg.HH_Auckland = 1.025; % High agglomeration growth -> low (R + mu - G) -> high Q_Auckland

% Regional House Prices Q(k) & Supply Elasticities delta_H(k) (Labrousse & Perdereau Source 2)
Params.Q_reg.HH_Rural    = 1.05; Params.delta_H.HH_Rural    = 0.35;
Params.Q_reg.HH_Urban    = 1.75; Params.delta_H.HH_Urban    = 0.22;
Params.Q_reg.HH_Auckland = 3.10; Params.delta_H.HH_Auckland = 0.10; % Severe Auckland land constraint

% Regional Wages w(k)
Params.w_reg.HH_Rural    = 0.86; Params.w_reg.Firm_Rural    = 0.86;
Params.w_reg.HH_Urban    = 1.00; Params.w_reg.Firm_Urban    = 1.00;
Params.w_reg.HH_Auckland = 1.18; Params.w_reg.Firm_Auckland = 1.18;

% Regional Mandatory Transport/Fuel Subsistence Cost e_bar(k) (Labrousse & Perdereau Fig 1a, Source 2)
Params.ebar_energy.HH_Rural    = 0.048; % Rural households spend 2.7x more on fuel than metropolis
Params.ebar_energy.HH_Urban    = 0.026;
Params.ebar_energy.HH_Auckland = 0.018;

% Regional "Geography x Income" Transfer Rule (Labrousse & Perdereau Sec 5, Source 2)
Params.Transfer_Geo.HH_Rural    = 0.025;
Params.Transfer_Geo.HH_Urban    = 0.015;
Params.Transfer_Geo.HH_Auckland = 0.012;

% Housing Tenure & Utility Parameters
Params.phi_nd = 0.80; Params.mu_maint = 0.04; Params.upsilon_h = 0.008; Params.chi_bar = 2.55;

% Lens 1: Heckman / Cunha et al. (Source 4) & Daruich (Source 3) Skill Formation Parameters
Params.G_ece      = 0.05;  % Public First-2000-Days wraparound ECE (Barnardos lever, Source 6)
Params.gbar_ece   = 0.02;  % Luxury shifter on private child investment (Source 10)
Params.omega_ic   = 0.38;  % Parental altruism weight on child human capital
Params.rho_hc_ig  = 0.40;  % Intergenerational persistence of parental human capital (Cunha et al. Source 4)
Params.gamma_ic   = 0.35;  % Productivity of early-childhood investment (ic + G_ece) in child skill
Params.sigma_hc_ig= 0.22;  % Idiosyncratic shock to child skill formation

% Lens 2 & 3: Adult Ben-Porath, NZ Super, & $1.6T Property Bequest Parameters
Params.delta_hc   = 0.086; Params.alpha_I = 0.098; Params.alpha_H = 0.051;
Params.p_super    = 0.18;  Params.c_floor = 0.04;
Params.b1_beq     = 4.20;  Params.b2_beq  = 0.45;  % De Nardi (Source 13) luxury bequest parameters
Params.YouthGrant = 0.03;  % Universal endowment E funded by inheritance tax tau_b

% Tax & Production Parameters
Params.r = 0.20; Params.tau_l = 0.22; Params.tau_c = 0.15; Params.tau_k = 0.20;
Params.tau_a = 0.005; Params.tau_b = 0.15;
Params.alpha_k = 0.33; Params.lambda_col = 1.80; Params.delta_k = 1 - (1-0.06)^5;

%% 5. SOLVE VFI & FIXED-POINT INTERGENERATIONAL TRANSITION MATRIX LOOP
for r_idx = 1:3
    hh_type   = ['HH_', Regions{r_idx}];
    firm_type = ['Firm_', Regions{r_idx}];
    ReturnFn.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, omega_ic, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_b, agej, Jr, sj) ...
        ReturnFn_SpatialHH(l, Ih, ic, aprime, hprime, a, h, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, omega_ic, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_b, agej, Jr, sj);
    
    ReturnFn.(firm_type) = @(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a) ...
        ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a);
end

vfoptions.verbose = 0; simoptions.verbose = 0;
[V, Policy] = ValueFnIter_PType(n_d, n_a, n_z, N_j, Names_i, ...
              d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, ...
              DiscountFactorParamNames, vfoptions);

% Initialize Newborn Distribution (j=1) across Rural, Urban, Auckland
for r_idx = 1:3
    hh_type = ['HH_', Regions{r_idx}];
    jequaloneDist.(hh_type) = ones([n_a.(hh_type), n_z.(hh_type)]) / prod([n_a.(hh_type), n_z.(hh_type)]);
end

% Fixed-Point Iteration on the Intergenerational & Spatial Transition Matrix
fprintf('\nSolving Intergenerational & 3-Region Spatial Transition Fixed Point...\n');
for ig_iter = 1:15
    % 1. Push cohorts forward from j=1 to J=16 given current jequaloneDist
    StationaryDist = StationaryDist_PType(jequaloneDist, AgeWeightsParamNames, ...
                     PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, Names_i, ...
                     d_grid, a_grid, z_grid, pi_z, Params, simoptions);
                 
    % 2. Build Intergenerational Transition Matrix (Parents & Retirees -> Newborns + Migration)
    [jequaloneDist_new, IG_Diagnostics] = Build_IntergenTransitionMatrix( ...
        StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions);
    
    % Check convergence of newborn human capital & inheritance distribution
    diff_ig = max([abs(jequaloneDist_new.HH_Rural(:)    - jequaloneDist.HH_Rural(:)); ...
                   abs(jequaloneDist_new.HH_Urban(:)    - jequaloneDist.HH_Urban(:)); ...
                   abs(jequaloneDist_new.HH_Auckland(:) - jequaloneDist.HH_Auckland(:))]);
    jequaloneDist = jequaloneDist_new;
    if diff_ig < 1e-5; break; end
end

%% 6. REPORT REGIONAL & INTERGENERATIONAL TRANSITION DIAGNOSTICS
fprintf('\n=== 3-REGION INTERGENERATIONAL TRANSITION RESULTS (Iter = %d) ===\n', ig_iter);
for r_idx = 1:3
    reg = Regions{r_idx};
    fprintf('Region: %-10s | Stunted Youth Share (h1+h2): %5.1f%% | Thriving Share (h6+h7): %5.1f%% | Mean Inherited Estate: %.3f\n', ...
        reg, 100*IG_Diagnostics.StuntedShare.(reg), 100*IG_Diagnostics.ThrivingShare.(reg), IG_Diagnostics.MeanBequest.(reg));
end
fprintf('\nInter-Regional 5-Year Youth Migration Matrix (Rows: Origin -> Cols: Rural, Urban, Auckland):\n');
disp(array2table(IG_Diagnostics.MigrationMatrix, 'VariableNames', Regions, 'RowNames', Regions));
