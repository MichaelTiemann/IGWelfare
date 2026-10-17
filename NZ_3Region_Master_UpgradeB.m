%% NEW ZEALAND 3-REGION MASTER SCRIPT WITH UPGRADE B (2-STAGE CHILD EXPERIENCE ASSET)
% Uses VFI Toolkit's experienceasset = 1 to track the child's developing skill stock
% theta_c across Stage 1 (j=3, First 2000 Days) and Stage 2 (j=4, Schooling)
% using Cunha, Heckman & Schennach (2010, Table V, Source 5) CES parameters.

clear; clc; close all;

%% 1. PERMANENT TYPES & DEMOGRAPHICS (RURAL, URBAN, AUCKLAND)
Regions = {'Rural', 'Urban', 'Auckland'};
Names_i = {'HH_Rural', 'HH_Urban', 'HH_Auckland', ...
           'Firm_Rural', 'Firm_Urban', 'Firm_Auckland'};
PTypeDistParamNames = {'PTypeWeights'};
Params.PTypeWeights = [0.180; 0.414; 0.306; 0.020; 0.046; 0.034];

for r_idx = 1:3
    reg = Regions{r_idx};
    N_j.(['HH_', reg])   = 16;  % Ages 20-99 (5-yr periods)
    N_j.(['Firm_', reg]) = Inf; % Infinite-horizon firms (Guvenen et al. Source 7)
end
Params.J = 16; Params.Jr = 10; Params.agej = 1:Params.J;

% Treasury OLG survival & cohort weights (Source 17)
Params.sj = [0.995, 0.994, 0.993, 0.991, 0.988, 0.983, 0.975, 0.962, ...
             0.942, 0.910, 0.860, 0.780, 0.660, 0.500, 0.300, 0.000];
Params.fj = [0.15, 0.65, 0.65, 0.20, zeros(1, 12)];
Params.mig_rate_j = [0.018, -0.012, -0.005, 0.015, 0.010, 0.006, 0.003, zeros(1, 9)];

T_demo = zeros(Params.J, Params.J); T_demo(1, :) = Params.fj * 0.5;
for jj = 1:(Params.J - 1); T_demo(jj+1, jj) = Params.sj(jj); end
N_pop = ones(Params.J, 1) / Params.J;
for iter = 1:200
    N_pop = T_demo * N_pop + Params.mig_rate_j' .* N_pop;
    N_pop = max(0, N_pop) / sum(max(0, N_pop));
end
AgeWeightsParamNames = {'mewj'}; Params.mewj = N_pop';

%% 2. CONFIGURE GRIDS & ENABLE VFI TOOLKIT EXPERIENCE ASSET (theta_c)
for r_idx = 1:3
    hh_type   = ['HH_', Regions{r_idx}];
    firm_type = ['Firm_', Regions{r_idx}];
    
    % Activate experienceasset for Households (tracks theta_c across Stages 1 & 2)
    vfoptions.experienceasset.(hh_type)    = 1;
    simoptions.experienceasset.(hh_type)   = 1;
    vfoptions.experienceasset.(firm_type)  = 0;
    simoptions.experienceasset.(firm_type) = 0;
    
    % Decision variables d: [d1 = ic (Child Inv -> aprimeFn), d2 = l (Labor), d3 = Ih (Ben-Porath)]
    n_d.(hh_type)    = [7, 4, 3];
    d_grid_ic        = linspace(0, 0.50, 7)';
    d_grid_l         = [0; 0.5; 0.8; 1.0];
    d_grid_Ih        = linspace(0, 0.30, 3)';
    d_grid.(hh_type) = [d_grid_ic; d_grid_l; d_grid_Ih];
    
    % Endogenous States a: [a1 = Net Worth (a), a2 = Adult HC (h), a3 = Child Skill Experience Asset (theta_c)]
    n_a.(hh_type)    = [61, 7, 9];
    a_grid_assets    = 25 * (linspace(0, 1, n_a.(hh_type)(1)).^3)';
    a_grid_hc        = [0.45; 0.65; 0.85; 1.00; 1.20; 1.45; 1.80];
    a_grid_thetac    = linspace(0.45, 1.85, n_a.(hh_type)(3))'; % 9-pt continuous child skill grid
    a_grid.(hh_type) = [a_grid_assets; a_grid_hc; a_grid_thetac];
    
    n_z.(hh_type) = 5;
    
    % Attach ChildCES_aprimeFn to vfoptions and simoptions
    vfoptions.aprimeFn.(hh_type) = @(ic, theta_c, G_ece_stage1, G_ece_stage2, gbar_ece, ...
        gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, h_par_mean, agej) ...
        ChildCES_aprimeFn(ic, theta_c, G_ece_stage1, G_ece_stage2, gbar_ece, ...
        gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, h_par_mean, agej);
    simoptions.aprimeFn.(hh_type) = vfoptions.aprimeFn.(hh_type);
    
    % Infinite-Horizon Firm Grids
    n_d.(firm_type) = 0; d_grid.(firm_type) = [];
    n_a.(firm_type) = 81; a_grid.(firm_type) = 30 * (linspace(0.001, 1, 81).^2.5)';
    n_z.(firm_type) = 2;  pi_z.(firm_type)   = [0.85, 0.15; 0.15, 0.85];
end

[z_grid.HH_Rural,    pi_z.HH_Rural]    = discretizeAR1_Tauchen(-0.05, 0.85, 0.11, 5);
[z_grid.HH_Urban,    pi_z.HH_Urban]    = discretizeAR1_Tauchen( 0.04, 0.85, 0.16, 5);
[z_grid.HH_Auckland, pi_z.HH_Auckland] = discretizeAR1_Tauchen( 0.15, 0.85, 0.24, 5);
z_grid.HH_Rural = exp(z_grid.HH_Rural); z_grid.HH_Urban = exp(z_grid.HH_Urban); z_grid.HH_Auckland = exp(z_grid.HH_Auckland);
z_grid.Firm_Rural = [0.70; 1.15]; z_grid.Firm_Urban = [0.80; 1.40]; z_grid.Firm_Auckland = [0.90; 1.75];

%% 3. CUNHA, HECKMAN & SCHENNACH (2010, TABLE V) TWO-STAGE SKILL PARAMETERS
for r_idx = 1:3
    DiscountFactorParamNames.(['HH_', Regions{r_idx}])   = {'beta_hh', 'sj'};
    DiscountFactorParamNames.(['Firm_', Regions{r_idx}]) = {'beta_firm'};
end
Params.beta_hh = 0.96^5; Params.beta_firm = 0.95^5;

% Stage 1 (j=3, First 1000/2000 Days): High Substitutability & High Investment Loading (Source 5 Table V)
Params.gamma1_self  = 0.53; % Self-productivity (Cognitive 0.485, Noncognitive 0.602)
Params.gamma1_inv   = 0.24; % Early investment productivity (Cognitive 0.261, Noncognitive 0.209)
Params.gamma1_par   = 0.23; % Parental skill loading
Params.phi1_ces     = 0.35; % Elasticity of substitution = 1/(1 - 0.35) = 1.54 > 1

% Stage 2 (j=4, School Years): Dynamic Complementarity & High Self-Productivity (Source 5 Table V)
Params.gamma2_self  = 0.87; % Self-productivity jumps (Cognitive 0.884, Noncognitive 0.857)
Params.gamma2_inv   = 0.07; % Late investment loading drops (Cognitive 0.044, Noncognitive 0.104)
Params.gamma2_par   = 0.06; % Direct parental loading fades in adolescence
Params.phi2_ces     = -0.95;% Elasticity of substitution = 1/(1 - (-0.95)) = 0.51 < 1 (Complementarity!)

% Public Investment Split: Stage 1 (First 2000 Days ECE + Whanau) vs Stage 2 (Public Schooling)
% Allows Lee & Seshadri (Source 11, Appendix D) balanced-budget P0/P1 vs P2 reallocation experiments!
Params.G_ece_stage1 = 0.045; % Barnardos First-2000-Days wraparound lever (Source 18)
Params.G_ece_stage2 = 0.065; % Public primary/secondary school expenditure
Params.gbar_ece     = 0.020; % Stone-Geary luxury parameter (Ferriere et al. Source 4)
Params.s_sub        = 0.100; % Private top-up subsidy rate (Source 4)
Params.omega_ic     = 0.420; % Parental altruism weight on completed child skill theta_3
Params.h_par_mean   = 1.000; % Regional mean parental skill (updated in IG loop)

% Regional Housing, Energy, Ben-Porath, & Tax Parameters (Sources 1, 2, 6, 7, 15, 16)
Params.G_reg.HH_Rural = 1.007; Params.G_reg.HH_Urban = 1.015; Params.G_reg.HH_Auckland = 1.025;
Params.Q_reg.HH_Rural = 1.05;  Params.Q_reg.HH_Urban = 1.75;  Params.Q_reg.HH_Auckland = 3.10;
Params.w_reg.HH_Rural = 0.86;  Params.w_reg.Firm_Rural = 0.86;
Params.w_reg.HH_Urban = 1.00;  Params.w_reg.Firm_Urban = 1.00;
Params.w_reg.HH_Auckland = 1.18; Params.w_reg.Firm_Auckland = 1.18;
Params.ebar_energy.HH_Rural = 0.048; Params.ebar_energy.HH_Urban = 0.026; Params.ebar_energy.HH_Auckland = 0.018;
Params.Transfer_Geo.HH_Rural = 0.025; Params.Transfer_Geo.HH_Urban = 0.015; Params.Transfer_Geo.HH_Auckland = 0.012;

Params.phi_nd = 0.80; Params.mu_maint = 0.04; Params.upsilon_h = 0.008; Params.chi_bar = 2.55;
Params.delta_hc = 0.087; Params.alpha_I = 0.090; Params.alpha_H = 0.064; % Source 6 Table E2
Params.p_super = 0.18; Params.c_floor = 0.04; Params.b1_beq = 4.20; Params.b2_beq = 0.45; Params.YouthGrant = 0.03;
Params.r = 0.20; Params.tau_l = 0.22; Params.tau_c = 0.15; Params.tau_k = 0.20; Params.tau_a = 0.005; Params.tau_b = 0.15;
Params.alpha_k = 0.33; Params.lambda_col = 1.80; Params.delta_k = 1 - (1-0.06)^5;
Params.sigma_hc_ig = 0.18;

%% 4. SOLVE VFI & TWO-STAGE INTERGENERATIONAL TRANSITION LOOP
for r_idx = 1:3
    hh_type   = ['HH_', Regions{r_idx}];
    firm_type = ['Firm_', Regions{r_idx}];
    ReturnFn.(hh_type) = @(ic, l, Ih, aprime, hprime, a, h, theta_c, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_b, agej, Jr, sj) ...
        ReturnFn_SpatialHH_UpgradeB(ic, l, Ih, aprime, hprime, a, h, theta_c, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_b, agej, Jr, sj);
    
    ReturnFn.(firm_type) = @(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a) ...
        ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a);
end

vfoptions.verbose = 0; simoptions.verbose = 0;
[V, Policy] = ValueFnIter_PType(n_d, n_a, n_z, N_j, Names_i, ...
              d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, ...
              DiscountFactorParamNames, vfoptions);

for r_idx = 1:3
    hh_type = ['HH_', Regions{r_idx}];
    jequaloneDist.(hh_type) = ones([n_a.(hh_type), n_z.(hh_type)]) / prod([n_a.(hh_type), n_z.(hh_type)]);
end

for ig_iter = 1:12
    StationaryDist = StationaryDist_PType(jequaloneDist, AgeWeightsParamNames, ...
                     PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, Names_i, ...
                     d_grid, a_grid, z_grid, pi_z, Params, simoptions);
                 
    [jequaloneDist_new, IG_Diagnostics] = Build_IntergenTransitionMatrix_UpgradeB( ...
        StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions);
    
    diff_ig = max(abs(jequaloneDist_new.HH_Auckland(:) - jequaloneDist.HH_Auckland(:)));
    jequaloneDist = jequaloneDist_new;
    if diff_ig < 1e-5; break; end
end

fprintf('\n=== UPGRADE B: TWO-STAGE CHILD CES EXPERIENCE ASSET DIAGNOSTICS ===\n');
for r_idx = 1:3
    reg = Regions{r_idx};
    fprintf('Region: %-9s | Stage-1 Skill (theta_2): %.3f | Completed Stage-2 Skill (theta_3): %.3f | Stunted Share: %4.1f%%\n', ...
        reg, IG_Diagnostics.MeanTheta2.(reg), IG_Diagnostics.MeanTheta3.(reg), 100*IG_Diagnostics.StuntedShare.(reg));
end
