%% NEW ZEALAND 4-REGION + ABROAD MASTER SCRIPT (EXPERIENCE-ASSET LIFECYCLE PIPELINE)
% File: NZ_4Region_Master.m
% Regions (k = 1, 2, 3, 4):
%   1. 'Rural'    : Rural & Primary Districts (16.0% HH, 15.0% Firm)
%   2. 'Small'    : Small/Medium Provincial Towns & Cities (24.0% HH, 23.0% Firm)
%   3. 'Large'    : Major Regional Metros - Wgtn, Chch, Hamilton, Tauranga, Dunedin (25.9% HH, 26.9% Firm)
%   4. 'Auckland' : Primate Metropolitan Agglomeration / "Paris" Analog (34.1% HH, 35.1% Firm)
% Horizons:
%   - Households ('HH_Rural', 'HH_Small', 'HH_Large', 'HH_Auckland'): Finite Horizon (J = 80/dt)
%   - Firms ('Firm_Rural', 'Firm_Small', 'Firm_Large', 'Firm_Auckland'): Infinite Horizon (N_j = Inf)

if ~exist('Params', 'var') || ~isfield(Params, 'dt')
    Params = struct();
    Params = Configure_TimeGrid_Params(Params, 5);
else
    Params = Configure_TimeGrid_Params(Params, Params.dt);
end

%% 1. DEFINE 8 PERMANENT TYPES (4 REGIONS x 2 SECTORS)
Regions = {'Rural', 'Small', 'Large', 'Auckland'};
N_reg   = length(Regions);
Names_i = {'HH_Rural',   'HH_Small',   'HH_Large',   'HH_Auckland', ...
    'Firm_Rural', 'Firm_Small', 'Firm_Large', 'Firm_Auckland'};
PTypeDistParamNames = {'PTypeWeights'};

% Stats NZ 2025/2026 Subnational Population & Business Demography Shares
Reg_HH_Shares   = [0.160; 0.240; 0.259; 0.341];
Reg_Firm_Shares = [0.150; 0.230; 0.269; 0.351];
Reg_Pop_Shares  = Reg_HH_Shares;
Params.PTypeWeights = [0.90 * Reg_HH_Shares; ...
    0.10 * Reg_Firm_Shares];

for r_idx = 1:N_reg
    reg = Regions{r_idx};
    N_j.(['HH_', reg])   = Params.J; % Finite horizon: Ages 20-99 (dt-yr periods, Jr at Age 65)
    N_j.(['Firm_', reg]) = Inf;      % Infinite horizon collateral-constrained firms
end

%% 2. TREASURY OLG DEMOGRAPHIC TRANSITION MATRIX (SCALED TO Params.J)
T_demo = zeros(Params.J, Params.J);
T_demo(1, :) = Params.fj * 0.5;
for jj = 1:(Params.J - 1)
    T_demo(jj+1, jj) = Params.sj(jj);
end
N_pop = ones(Params.J, 1) / Params.J;
for iter = 1:200
    N_pop = T_demo * N_pop + Params.mig_rate_j' .* N_pop;
    N_pop = max(0, N_pop) / sum(max(0, N_pop));
end
AgeWeightsParamNames = {'mewj'};
Params.mewj = N_pop';

%% 3. CONFIGURE GRIDS & ENABLE VFI TOOLKIT EXPERIENCE ASSET ACROSS 4 REGIONS
for r_idx = 1:N_reg
    hh_type   = ['HH_', Regions{r_idx}];
    firm_type = ['Firm_', Regions{r_idx}];

    vfoptions.experienceasset.(hh_type)    = 1;
    simoptions.experienceasset.(hh_type)   = 1;
    vfoptions.experienceasset.(firm_type)  = 0;
    simoptions.experienceasset.(firm_type) = 0;

    % Decisions d: [d1 = l (Labor), d2 = Ih (Ben-Porath Training), d3 = ic (Experience Asset Decision LAST)]
    n_d.(hh_type)    = [4, 3, 7];
    d_grid_l         = [0; 0.5; 0.8; 1.0];
    d_grid_Ih        = linspace(0, 0.30, 3)';
    d_grid_ic        = linspace(0, 0.50, 7)';
    d_grid.(hh_type) = [d_grid_l; d_grid_Ih; d_grid_ic];

    % Endogenous States a: [a1 = Net Worth (a), a2 = Adult HC (h), a3 = Skill Experience Asset (theta_c LAST)]
    n_a.(hh_type)    = [61, 7, 9];
    a_grid_assets    = 25 * (linspace(0, 1, n_a.(hh_type)(1)).^3)';
    a_grid_hc        = [0.45; 0.65; 0.85; 1.00; 1.20; 1.45; 1.80];
    a_grid_thetac    = linspace(0.45, 1.85, n_a.(hh_type)(3))';
    a_grid.(hh_type) = [a_grid_assets; a_grid_hc; a_grid_thetac];

    n_z.(hh_type) = 5;

    % VFI Toolkit experienceasset=1 requires: @(d_exp, a_exp, Params...)
    % 1st arg = ic (last decision), 2nd arg = theta_c (last endogenous state), 3rd+ args = Params fields
    vfoptions.aprimeFn.(hh_type) = @(ic, theta_c, agej, ...
        phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
        phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, ...
        gbar_ece, h_par_mean, K_whanau, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps) ...
        HumanCapital_Lifecycle_aprimeFn(ic, theta_c, agej, ...
        phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
        phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, ...
        gbar_ece, h_par_mean, K_whanau, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps);
    simoptions.aprimeFn.(hh_type) = vfoptions.aprimeFn.(hh_type);

    % Infinite-Horizon Firm Grids
    n_d.(firm_type) = 0; d_grid.(firm_type) = [];
    n_a.(firm_type) = 81; a_grid.(firm_type) = 30 * (linspace(0.001, 1, 81).^2.5)';
    n_z.(firm_type) = 2;  pi_z.(firm_type)   = [0.85, 0.15; 0.15, 0.85];
end

% 4-Region Income Process Calibration (Tauchen_q = 3.0 standard deviations)
Tauchen_q = 3.0;
[z_grid.HH_Rural,    pi_z.HH_Rural]    = discretizeAR1_Tauchen(-0.06, 0.85, 0.11, 5, Tauchen_q);
[z_grid.HH_Small,    pi_z.HH_Small]    = discretizeAR1_Tauchen(-0.01, 0.85, 0.14, 5, Tauchen_q);
[z_grid.HH_Large,    pi_z.HH_Large]    = discretizeAR1_Tauchen( 0.06, 0.85, 0.18, 5, Tauchen_q);
[z_grid.HH_Auckland, pi_z.HH_Auckland] = discretizeAR1_Tauchen( 0.15, 0.85, 0.24, 5, Tauchen_q);
for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    z_grid.(hh_type) = exp(z_grid.(hh_type));
end

% 4-Region Firm Productivity Ceilings (z_l vs z_h)
z_grid.Firm_Rural    = [0.70; 1.15];
z_grid.Firm_Small    = [0.75; 1.28];
z_grid.Firm_Large    = [0.83; 1.50];
z_grid.Firm_Auckland = [0.90; 1.75];

%% 4. 4-REGION SPATIAL HOUSING, ENERGY, & INTERGENERATIONAL PARAMETERS
for r_idx = 1:N_reg
    DiscountFactorParamNames.(['HH_', Regions{r_idx}])   = {'beta_hh', 'sj'};
    DiscountFactorParamNames.(['Firm_', Regions{r_idx}]) = {'beta_firm'};
end

% Regional Annual Trend Growth G_reg(k) (Hirano & Toda 2025)
Params.G_reg.HH_Rural    = 1.007;
Params.G_reg.HH_Small    = 1.011;
Params.G_reg.HH_Large    = 1.018;
Params.G_reg.HH_Auckland = 1.025;

% Regional House Prices Q(k) & Housing Supply Elasticities delta_H(k)
Params.Q_reg.HH_Rural    = 1.05; Params.delta_H.HH_Rural    = 0.35;
Params.Q_reg.HH_Small    = 1.40; Params.delta_H.HH_Small    = 0.28;
Params.Q_reg.HH_Large    = 2.05; Params.delta_H.HH_Large    = 0.18;
Params.Q_reg.HH_Auckland = 3.10; Params.delta_H.HH_Auckland = 0.10;

% Regional Wages w(k)
Params.w_reg.HH_Rural    = 0.85; Params.w_reg.Firm_Rural    = 0.85;
Params.w_reg.HH_Small    = 0.93; Params.w_reg.Firm_Small    = 0.93;
Params.w_reg.HH_Large    = 1.05; Params.w_reg.Firm_Large    = 1.05;
Params.w_reg.HH_Auckland = 1.18; Params.w_reg.Firm_Auckland = 1.18;

% Mandatory Transport/Fuel & Energy Subsistence e_bar(k)
Params.ebar_energy.HH_Rural    = 0.048;
Params.ebar_energy.HH_Small    = 0.036;
Params.ebar_energy.HH_Large    = 0.022;
Params.ebar_energy.HH_Auckland = 0.016;

% Regional Extended Family / Whanau Proximity & Alloparental Network Intensity K_whanau(k) in [0, 1]
% Reflects higher multigenerational co-residence / proximity in Rural & Provincial regions
% vs. nuclear-household isolation in high-rent metropolitan Auckland (shockable via papakainga / zoning policy)
Params.K_whanau.HH_Rural    = 0.65;
Params.K_whanau.HH_Small    = 0.50;
Params.K_whanau.HH_Large    = 0.30;
Params.K_whanau.HH_Auckland = 0.20;

% Two-Stage Child Skill (Cunha et al.), Ben-Porath, Housing Tenure, & Tax Parameters
Params.gamma1_self = 0.53; Params.gamma1_inv = 0.24; Params.gamma1_par = 0.23; Params.phi1_ces = 0.35;
Params.gamma2_self = 0.87; Params.gamma2_inv = 0.07; Params.gamma2_par = 0.06; Params.phi2_ces = -0.95;
Params.G_ece_stage1 = 0.045; Params.G_ece_stage2 = 0.065; Params.gbar_ece = 0.020;
Params.s_sub = 0.100; Params.omega_ic = 0.420; Params.h_par_mean = 1.000;

Params.phi_nd = 0.80; Params.mu_maint = 0.04; Params.upsilon_h = 0.008; Params.chi_bar = 2.55;
Params.alpha_I = 0.090; Params.alpha_H = 0.064;
Params.p_super = 0.18; Params.c_floor = 0.04; Params.b1_beq = 4.20; Params.b2_beq = 0.45; Params.YouthGrant = 0.03;
Params.tau_l = 0.22; Params.tau_c = 0.15; Params.tau_k = 0.20; Params.tau_a = 0.005; Params.tau_b = 0.15;
Params.alpha_k = 0.33; Params.lambda_col = 1.80;
Params.sigma_hc_ig = 0.18;

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

%% 5. SOLVE VFI & 4-REGION + ABROAD INTERGENERATIONAL TRANSITION LOOP
for r_idx = 1:N_reg
    hh_type   = ['HH_', Regions{r_idx}];
    firm_type = ['Firm_', Regions{r_idx}];
    ReturnFn.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, theta_c, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps) ...
        ReturnFn_SpatialHH(l, Ih, ic, aprime, hprime, a, h, theta_c, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps);

    ReturnFn.(firm_type) = @(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt) ...
        ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt);
end

vfoptions.verbose = 0; simoptions.verbose = 0;
simoptions.d_grid = d_grid; simoptions.a_grid = a_grid;

[V, Policy] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, ...
    DiscountFactorParamNames, vfoptions);

for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    jequaloneDist.(hh_type) = ones([n_a.(hh_type), n_z.(hh_type)]) / prod([n_a.(hh_type), n_z.(hh_type)]);
end

for ig_iter = 1:12
    StationaryDist = StationaryDist_MixHorz_PType(jequaloneDist, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, Names_i, ...
        pi_z, Params, simoptions);

    [jequaloneDist_new, IG_Diagnostics] = Build_IntergenTransitionMatrix( ...
        StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions);

    diff_ig = max(abs(jequaloneDist_new.HH_Auckland(:) - jequaloneDist.HH_Auckland(:)));
    jequaloneDist = jequaloneDist_new;
    if diff_ig < 1e-5; break; end
end

fprintf('\n=== 4-REGION + ABROAD STEADY-STATE DIAGNOSTICS (dt = %d yr, J = %d) ===\n', Params.dt, Params.J);
for r_idx = 1:N_reg
    reg = Regions{r_idx};
    fprintf('Region: %-9s (Pop %4.1f%%) | Stage-1 Skill: %.3f | Completed Skill: %.3f | Stunted: %4.1f%% | Mean Bequest: %.3f | Emig: %4.1f%%\n', ...
        reg, 100*Reg_HH_Shares(r_idx), IG_Diagnostics.MeanTheta2.(reg), ...
        IG_Diagnostics.MeanTheta3.(reg), 100*IG_Diagnostics.StuntedShare.(reg), ...
        IG_Diagnostics.MeanBequest.(reg), 100*IG_Diagnostics.EmigRate.(reg));
end
