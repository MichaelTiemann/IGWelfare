%% NEW ZEALAND 4-REGION MASTER SCRIPT WITH UPGRADE B (2-STAGE CHILD EXPERIENCE ASSET)
% File: NZ_4Region_Master.m
% Regions (k = 1, 2, 3, 4):
%   1. 'Rural'    : Rural & Primary Districts (20% pop)
%   2. 'Small'    : Small/Medium Provincial Towns & Cities (23% pop)
%   3. 'Large'    : Major Regional Metros - Wellington, Chch, Hamilton, Tauranga, Dunedin (27% pop)
%   4. 'Auckland' : Primate Metropolitan Agglomeration / "Paris" Analog (30% pop)
% Horizons:
%   - Households ('HH_Rural', 'HH_Small', 'HH_Large', 'HH_Auckland'): Finite Horizon (J = 16)
%   - Firms ('Firm_Rural', 'Firm_Small', 'Firm_Large', 'Firm_Auckland'): Infinite Horizon (N_j = Inf)

% Comment out 'clear; clc; close all;' when called from Run_All_NZ_Intergen_Suite.m
% clear; clc; close all;

%% 1. DEFINE 8 PERMANENT TYPES (4 REGIONS x 2 SECTORS) - STATS NZ 2025/2026 CALIBRATION
Regions = {'Rural', 'Small', 'Large', 'Auckland'};
N_reg   = length(Regions);
Names_i = {'HH_Rural',   'HH_Small',   'HH_Large',   'HH_Auckland', ...
    'Firm_Rural', 'Firm_Small', 'Firm_Large', 'Firm_Auckland'};
PTypeDistParamNames = {'PTypeWeights'};

% Stats NZ Subnational Population Shares (30 June 2025: Auckland = 1.816M / 5.325M = 34.1%)
%   - Rural    : 16.0% (Rural settlements & hinterland)
%   - Small    : 24.0% (Small, medium & provincial urban areas <100k)
%   - Large    : 25.9% (Non-Auckland Major Urban Areas >100k: Chch, Wgtn, Hamilton, Tauranga, Dunedin)
%   - Auckland : 34.1% (Auckland Region primate agglomeration; rises to ~36% by 2043)
Reg_Pop_Shares  = [0.160; 0.240; 0.259; 0.341];

% Stats NZ Business Demography Shares (Feb 2025: Auckland = 229,770 / 654,465 = 35.1% of NZ firms)
Reg_Firm_Shares = [0.150; 0.230; 0.269; 0.351];

Params.PTypeWeights = [0.90 * Reg_Pop_Shares; ...  % HH_Rural, HH_Small, HH_Large, HH_Auckland
    0.10 * Reg_Firm_Shares];    % Firm_Rural, Firm_Small, Firm_Large, Firm_Auckland

for r_idx = 1:N_reg
    reg = Regions{r_idx};
    N_j.(['HH_', reg])   = 16;  % Finite horizon: Ages 20-99 (5-yr periods, Jr = 10 at Age 65)
    N_j.(['Firm_', reg]) = Inf; % Infinite horizon collateral-constrained firms
end
Params.J = 16; Params.Jr = 10; Params.agej = 1:Params.J;

%% 2. TREASURY OLG DEMOGRAPHIC TRANSITION MATRIX (Binning et al. 2024, Source 3)
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

%% 3. CONFIGURE GRIDS & ENABLE TWO EXPERIENCE ASSETS (h, theta_c) ACROSS 4 REGIONS
for r_idx = 1:N_reg
    hh_type   = ['HH_',   Regions{r_idx}];
    firm_type = ['Firm_', Regions{r_idx}];

    % Two Experience Assets (a2_1 = h, a2_2 = theta_c) driven by Two Decisions (d2_1 = Ih, d2_2 = ic)
    vfoptions.experienceasset.(hh_type)      = 2;
    simoptions.experienceasset.(hh_type)     = 2;
    vfoptions.l_dexperienceasset.(hh_type)   = 2;
    simoptions.l_dexperienceasset.(hh_type)  = 2;

    vfoptions.experienceasset.(firm_type)    = 0;
    simoptions.experienceasset.(firm_type)   = 0;

    % Decisions d: [d1 = l (4) | d2_1 = Ih (3), d2_2 = ic (7)]
    n_d.(hh_type)    = [4, 3, 7];
    d_grid_l         = [0; 0.5; 0.8; 1.0];
    d_grid_Ih        = linspace(0, 0.30, 3)';
    d_grid_ic        = linspace(0, 0.50, 7)';
    d_grid.(hh_type) = [d_grid_l; d_grid_Ih; d_grid_ic];

    % Endogenous States a: [a1 = Net Worth (61) | a2_1 = Adult HC h (7), a2_2 = Child Skill theta_c (9)]
    n_a.(hh_type)    = [61, 7, 9];
    a_grid_assets    = 25 * (linspace(0, 1, n_a.(hh_type)(1)).^3)';
    a_grid_hc        = [0.45; 0.65; 0.85; 1.00; 1.20; 1.45; 1.80];
    a_grid_thetac    = linspace(0.45, 1.85, n_a.(hh_type)(3))';
    a_grid.(hh_type) = [a_grid_assets; a_grid_hc; a_grid_thetac];

    n_z.(hh_type) = 5;

    % Dual Experience Asset aprimeFn: (Ih, ic, h, theta_c, whicha, <params>)
    vfoptions.aprimeFn.(hh_type) = @(Ih, ic, h, theta_c, whicha, ...
        delta_hc, alpha_I, alpha_H, ...
        G_ece_stage1, G_ece_stage2, gbar_ece, ...
        gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, agej, Jr) ...
        ChildCES_aprimeFn(Ih, ic, h, theta_c, whicha, ...
        delta_hc, alpha_I, alpha_H, ...
        G_ece_stage1, G_ece_stage2, gbar_ece, ...
        gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, agej, Jr);
    simoptions.aprimeFn.(hh_type) = vfoptions.aprimeFn.(hh_type);
    simoptions.d_grid.(hh_type) = d_grid.(hh_type);
    simoptions.a_grid.(hh_type) = a_grid.(hh_type);
    % simoptions.z_grid.(hh_type) = z_grid.(hh_type);

    % Infinite-Horizon Firm Grids
    n_d.(firm_type) = 0;  d_grid.(firm_type) = [];
    n_a.(firm_type) = 81; a_grid.(firm_type) = 30 * (linspace(0.001, 1, 81).^2.5)';
    n_z.(firm_type) = 2;  pi_z.(firm_type)   = [0.85, 0.15; 0.15, 0.85];
end

% 4-Region Income Process Calibration (Labrousse & Perdereau Source 4: Rural/Small compressed, Large/Auckland wider)
[z_grid.HH_Rural,    pi_z.HH_Rural]    = discretizeAR1_Tauchen(-0.06, 0.85, 0.11, 5, 3.0);
[z_grid.HH_Small,    pi_z.HH_Small]    = discretizeAR1_Tauchen(-0.01, 0.85, 0.14, 5, 3.0);
[z_grid.HH_Large,    pi_z.HH_Large]    = discretizeAR1_Tauchen( 0.06, 0.85, 0.18, 5, 3.0);
[z_grid.HH_Auckland, pi_z.HH_Auckland] = discretizeAR1_Tauchen( 0.15, 0.85, 0.24, 5, 3.0);
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
Params.beta_hh = 0.96^5; Params.beta_firm = 0.95^5;

% Regional Trend Growth G(k) -> Unbalanced growth gradient (Hirano & Toda Source 2)
Params.G_reg.HH_Rural    = 1.007;
Params.G_reg.HH_Small    = 1.011;
Params.G_reg.HH_Large    = 1.018;
Params.G_reg.HH_Auckland = 1.025;

% Regional House Prices Q(k) & Housing Supply Elasticities delta_H(k) (Source 4)
Params.Q_reg.HH_Rural    = 1.05; Params.delta_H.HH_Rural    = 0.35;
Params.Q_reg.HH_Small    = 1.40; Params.delta_H.HH_Small    = 0.28;
Params.Q_reg.HH_Large    = 2.05; Params.delta_H.HH_Large    = 0.18;
Params.Q_reg.HH_Auckland = 3.10; Params.delta_H.HH_Auckland = 0.10;

% Regional Wages w(k)
Params.w_reg.HH_Rural    = 0.85; Params.w_reg.Firm_Rural    = 0.85;
Params.w_reg.HH_Small    = 0.93; Params.w_reg.Firm_Small    = 0.93;
Params.w_reg.HH_Large    = 1.05; Params.w_reg.Firm_Large    = 1.05;
Params.w_reg.HH_Auckland = 1.18; Params.w_reg.Firm_Auckland = 1.18;

% Mandatory Transport/Fuel & Energy Subsistence e_bar(k) (Labrousse & Perdereau Fig 1a, Source 4)
% Matches exact step-down from Rural -> Small -> Large -> Paris/Auckland
Params.ebar_energy.HH_Rural    = 0.048;
Params.ebar_energy.HH_Small    = 0.036;
Params.ebar_energy.HH_Large    = 0.022;
Params.ebar_energy.HH_Auckland = 0.016;

% Regional "Income x Geography" Transfer Calibration (Labrousse & Perdereau Table 2, Source 4)
Params.Transfer_Geo.HH_Rural    = 0.025;
Params.Transfer_Geo.HH_Small    = 0.020;
Params.Transfer_Geo.HH_Large    = 0.016;
Params.Transfer_Geo.HH_Auckland = 0.014;

% Two-Stage Child Skill (Cunha et al.), Ben-Porath, Housing Tenure, & Tax Parameters
Params.gamma1_self = 0.53; Params.gamma1_inv = 0.24; Params.gamma1_par = 0.23; Params.phi1_ces = 0.35;
Params.gamma2_self = 0.87; Params.gamma2_inv = 0.07; Params.gamma2_par = 0.06; Params.phi2_ces = -0.95;
Params.G_ece_stage1 = 0.045; Params.G_ece_stage2 = 0.065; Params.gbar_ece = 0.020;
Params.s_sub = 0.100; Params.omega_ic = 0.850; Params.h_par_mean = 1.000;

Params.phi_nd = 0.80; Params.mu_maint = 0.04; Params.upsilon_h = 0.008; Params.chi_bar = 2.55;
Params.delta_hc = 0.087; Params.alpha_I = 0.090; Params.alpha_H = 0.064;
Params.p_super = 0.18; Params.c_floor = 0.04; Params.b1_beq = 4.20; Params.b2_beq = 0.45; Params.YouthGrant = 0.03;
Params.r = 0.20; Params.tau_l = 0.22; Params.tau_c = 0.15; Params.tau_k = 0.20; Params.tau_a = 0.005; Params.tau_b = 0.15;
Params.alpha_k = 0.33; Params.lambda_col = 1.80; Params.delta_k = 1 - (1-0.06)^5;
Params.sigma_hc_ig = 0.18;
% --- Optional 4+1 Abroad Migration & Brain-Drain Extension ---
if ~exist('Enable_Abroad_Option', 'var')
    Enable_Abroad_Option = false; % Default when running NZ_4Region_Master.m standalone
end
Params.Enable_Abroad_Option       = Enable_Abroad_Option;
Params.Params_Mig                 = struct();
Params.Params_Mig.Enable_Abroad   = Enable_Abroad_Option;
Params.Params_Mig.w_Abroad         = 1.32;  % Foreign (OECD/Australia) benchmark skill wage
Params.Params_Mig.Q_Abroad         = 2.15;  % Foreign house price benchmark (vs Auckland 3.10)
Params.Params_Mig.kappa_emig       = 0.14;  % Fixed international moving cost
Params.Params_Mig.tau_home_amenity = 0.85;  % Whanau / native home-attachment amenity in NZ
Params.Params_Mig.varrho_gumbel    = 0.45;  % Gumbel migration taste shock scale
Params.Params_Mig.home_stay_bonus  = 0.95;  % Domestic origin-region retention amenity
Params.Params_Mig.Target_NetMig    = 0.025; % Stats NZ +25k/yr net migration target
Params.Params_Mig.nu_retention     = 0.40;  % Elasticity of social cohesion S_t wrt native retention
Params.Params_Mig.nu_churn         = 0.35;  % Social cohesion penalty wrt replacement migration churn
Params.Params_Mig.gamma_proximity  = 0.45;  % Parental utility weight on children remaining in NZ
Params.Params_Mig.gamma_thrive     = 0.35;  % Parental utility weight on children thriving

%% 5. SOLVE VFI & 4-REGION INTERGENERATIONAL TRANSITION LOOP
for r_idx = 1:N_reg
    hh_type   = ['HH_',   Regions{r_idx}];
    firm_type = ['Firm_', Regions{r_idx}];

    ReturnFn.(hh_type) = @(l, Ih, ic, aprime, a, h, theta_c, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, s_sub, omega_ic, ...
        b1_beq, b2_beq, YouthGrant, tau_l, tau_c, tau_k, tau_b, agej, Jr, sj) ...
        ReturnFn_SpatialHH(l, Ih, ic, aprime, a, h, theta_c, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, s_sub, omega_ic, ...
        b1_beq, b2_beq, YouthGrant, tau_l, tau_c, tau_k, tau_b, agej, Jr, sj);

    ReturnFn.(firm_type) = @(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a) ...
        ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a);
end

vfoptions.verbose = 0; simoptions.verbose = 0;
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

    [jequaloneDist_new, IG_Diagnostics] = Build_IntergenTransitionMatrix(StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions);

    diff_ig = max(abs(jequaloneDist_new.HH_Auckland(:) - jequaloneDist.HH_Auckland(:)));
    jequaloneDist = jequaloneDist_new;
    if diff_ig < 1e-5; break; end
end

fprintf('\n=== 4-REGION UPGRADE B STEADY-STATE DIAGNOSTICS (Rural, Small, Large, Auckland) ===\n');
for r_idx = 1:N_reg
    reg = Regions{r_idx};
    fprintf('Region: %-9s (Pop %2.0f%%) | Stage-1 Skill: %.3f | Completed Skill: %.3f | Stunted: %4.1f%% | Mean Bequest: %.3f\n', ...
        reg, 100*Reg_Pop_Shares(r_idx), IG_Diagnostics.MeanTheta2.(reg), ...
        IG_Diagnostics.MeanTheta3.(reg), 100*IG_Diagnostics.StuntedShare.(reg), IG_Diagnostics.MeanBequest.(reg));
end

if Params.Enable_Abroad_Option
    fprintf('--- 4+1 ABROAD MIGRATION & SOCIAL COHESION DIAGNOSTICS ---\n');
    fprintf('National Youth Emigration: %4.1f%% | High-Skill (h5-h7) Share: %4.1f%% | Social Cohesion S_t: %5.1f | Parental Rel CE: %+4.2f%%\n', ...
        100*IG_Diagnostics.EmigRate_Youth, 100*IG_Diagnostics.HighSkill_EmigShare, ...
        IG_Diagnostics.SocialCohesion_Index, IG_Diagnostics.ParentalRelational_CE);
    fprintf('Regional Emigration to Abroad: Rural %4.1f%% | Small %4.1f%% | Large %4.1f%% | Auckland %4.1f%%\n', ...
        100*IG_Diagnostics.Emig_By_Region(1), 100*IG_Diagnostics.Emig_By_Region(2), ...
        100*IG_Diagnostics.Emig_By_Region(3), 100*IG_Diagnostics.Emig_By_Region(4));
end
