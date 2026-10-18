%% MODULAR SPATIAL & HOUSING INTERGENERATIONAL MODEL (VFI TOOLKIT)
% Integrates:
%  - Kiyotaki, Michaelides, & Nikolov (2024): Owner/Renter tenure, user cost, landlord old
%  - Labrousse & Perdereau (2025): Rural vs Urban horizontal types k, housing supply HS(k),
%    subsistence energy/transport costs e_bar(k), and Income x Geography transfers
%  - Hirano & Toda (2025): Unbalanced growth (G_urban > G_rural) & urban land overvaluation
%  - De Nardi (2004) / Piketty & Saez (2013): $1.6T property bequest transfer & taxation

clear; clc; close all;

%% 1. PERMANENT TYPES: 2 GEOGRAPHIC REGIONS x (FINITE HH + INFINITE FIRM)
% Toggle geography: Set K=2 for Rural/Urban divide, or K=1 for National aggregate
Names_i = {'HH_Rural', 'HH_Urban', 'Firm_Rural', 'Firm_Urban'};
PTypeDistParamNames = {'PTypeWeights'};
% Initial population/firm weights (e.g., 30% Rural/Provincial NZ, 70% Urban NZ)
Params.PTypeWeights = [0.27; 0.63; 0.03; 0.07];

% Finite horizon for Households (16 periods = Ages 20-99), Infinite for Firms
N_j.HH_Rural   = 16;
N_j.HH_Urban   = 16;
N_j.Firm_Rural = Inf;
N_j.Firm_Urban = Inf;

Params.J  = 16;
Params.Jr = 10; % Retirement at Age 65
Params.agej = 1:Params.J;

% Demographic survival & cohort weights (NZ Treasury OLG structure, Source 4)
Params.sj = [0.995, 0.994, 0.993, 0.991, 0.988, 0.983, 0.975, 0.962, ...
             0.942, 0.910, 0.860, 0.780, 0.660, 0.500, 0.300, 0.000];
Params.n_pop = 0.005;
mewj = ones(1, Params.J);
for jj = 2:Params.J
    mewj(jj) = mewj(jj-1) * Params.sj(jj-1) / (1 + Params.n_pop)^5;
end
AgeWeightsParamNames = {'mewj'};
Params.mewj = mewj ./ sum(mewj);

%% 2. STATE & DECISION GRIDS (IDENTICAL DIMENSION -> ZERO GRID CURSE!)
% Household Decisions d: [Labor (l), Ben-Porath Training (Ih), Child Investment (ic)]
for k_hh = {'HH_Rural', 'HH_Urban'}
    type = k_hh{1};
    n_d.(type) = [4, 3, 6];
    d_grid.(type) = [[0; 0.5; 0.8; 1.0]; linspace(0, 0.3, 3)'; linspace(0, 0.4, 6)'];
    
    % Endogenous States a: [Consolidated Net Worth a = Q*h - b, Human Capital h]
    n_a.(type) = [101, 5];
    a_grid_networth = 20 * (linspace(0, 1, n_a.(type)(1)).^3)'; % Reaches high property estates
    a_grid_hc       = linspace(0.6, 1.8, n_a.(type)(2))';
    a_grid.(type)   = [a_grid_networth; a_grid_hc];
    
    % Exogenous Productivity Shock z (Region-specific variance per Labrousse & Perdereau)
    n_z.(type) = 5;
end

% Rural vs Urban income distribution moments (Labrousse & Perdereau Figure 5b, Source 2):
% Rural is more compressed in middle quintiles (Q2-Q4); Urban has higher mean & fat tails (Q1, Q5)
[z_grid.HH_Rural, pi_z.HH_Rural] = discretizeAR1_Tauchen(0.00, 0.85, 0.12, n_z.HH_Rural);
[z_grid.HH_Urban, pi_z.HH_Urban] = discretizeAR1_Tauchen(0.12, 0.85, 0.22, n_z.HH_Urban);
z_grid.HH_Rural = exp(z_grid.HH_Rural);
z_grid.HH_Urban = exp(z_grid.HH_Urban);

% Infinite-Horizon Firms (Rural Land-Intensive Sector 1 vs Urban Knowledge Sector 2, Source 3)
for k_f = {'Firm_Rural', 'Firm_Urban'}
    type = k_f{1};
    n_d.(type) = 0; d_grid.(type) = [];
    n_a.(type) = 101;
    a_grid.(type) = 25 * (linspace(0.001, 1, n_a.(type)).^2.5)';
    n_z.(type) = 2;
    pi_z.(type) = [0.85, 0.15; 0.15, 0.85];
end
z_grid.Firm_Rural = [0.70; 1.15]; % Lower productivity growth ceiling (Hirano & Toda Sector 1)
z_grid.Firm_Urban = [0.85; 1.65]; % Higher productivity growth ceiling (Hirano & Toda Sector 2)

%% 3. SPATIAL, HOUSING & INTERGENERATIONAL PARAMETERS
DiscountFactorParamNames.HH_Rural   = {'beta_hh', 'sj'};
DiscountFactorParamNames.HH_Urban   = {'beta_hh', 'sj'};
DiscountFactorParamNames.Firm_Rural = {'beta_firm'};
DiscountFactorParamNames.Firm_Urban = {'beta_firm'};
Params.beta_hh   = 0.96^5;
Params.beta_firm = 0.95^5;

% Kiyotaki, Michaelides & Nikolov (2024, Source 1) Housing Parameters
Params.phi_nd    = 0.82;   % Nondurable consumption share (1 - phi_nd = housing share)
Params.mu_maint  = 0.0406; % Annual housing maintenance & property rates factor (Table 1)
Params.upsilon_h = 0.0082; % Implicit tax subsidy to owner-occupied housing (Table 1)
Params.chi_bar   = 2.5536; % Upper bound on rental preference draw chi (Table 1)
Params.eta_ies   = 0.50;   % Intertemporal elasticity of substitution (Table 1)

% Hirano & Toda (2025, Source 3) Unbalanced Regional Trend Growth Rates (G_k)
% Urban knowledge sector grows faster than rural land sector, driving higher urban P/Rent ratio
Params.G_reg.HH_Rural = 1.008; % Annual trend growth in Rural NZ
Params.G_reg.HH_Urban = 1.022; % Annual trend growth in Urban NZ (drives land overvaluation)

% Labrousse & Perdereau (2025, Source 2) Spatial Housing Supply & Subsistence Transport/Fuel
% Rural households need 2.7x more transport/heating fuel (e_bar) & have higher supply elasticity
Params.ebar_energy.HH_Rural = 0.045; % High mandatory rural car/fuel expenditure
Params.ebar_energy.HH_Urban = 0.016; % Low urban mandatory transport/fuel expenditure
Params.H_scale_Rural        = 1.20;  % Baseline rural land/housing stock scaling
Params.H_scale_Urban        = 0.85;  % Constrained urban land supply scaling
Params.delta_H_Rural        = 0.30;  % More elastic rural housing supply (Source 2, Sec F.1)
Params.delta_H_Urban        = 0.15;  % Inelastic urban housing supply (amplifies wealth gap)

% Regional Transfer Progressivity ("Income x Geography" rule, Labrousse & Perdereau Sec 5)
Params.Transfer_Geo.HH_Rural = 0.025; % Compensates rural middle-income transport/wage burden
Params.Transfer_Geo.HH_Urban = 0.010;

% Child Investment (Lens 1), Ben-Porath (Lens 2), & $1.6T Bequest/Super Parameters (Lens 3)
Params.G_ece      = 0.05;  % Public First-2000-Days wraparound ECE (Ferriere et al. Source 13)
Params.gbar_ece   = 0.02;  % Luxury shifter on child investment (Source 13)
Params.omega_ic   = 0.35;  % Parental weight on child skill
Params.delta_hc   = 0.086; % Adult human capital depreciation (Source 11)
Params.alpha_I    = 0.098; 
Params.alpha_H    = 0.051;
Params.p_super    = 0.18;  % Universal NZ Superannuation
Params.c_floor    = 0.04;  % Retirement consumption floor
Params.b1_beq     = 4.20;  % Strong luxury bequest motive (De Nardi 2004, Source 9)
Params.b2_beq     = 0.45;  % Threshold above which $1.6T property estates are bequeathed
Params.YouthGrant = 0.04;  % Early-adulthood endowment funded by property inheritance tax

% Tax Rates & Firm Parameters
Params.tau_l = 0.22; Params.tau_c = 0.15; Params.tau_k = 0.20;
Params.tau_a = 0.005; % Book-value wealth/land tax (Guvenen et al., Source 5)
Params.tau_b = 0.15;  % Estate / Inheritance tax on the $1.6T transfer (Piketty & Saez, Source 7)
Params.alpha_k = 0.33; Params.lambda_col = 1.80; Params.delta_k = 1 - (1-0.06)^5;

%% 4. INITIAL GUESS FOR REGIONAL GENERAL EQUILIBRIUM PRICES
Params.r = 0.20; % National 5-year real interest rate (~3.7% p.a.)
Params.w_reg.HH_Rural   = 0.88; Params.w_reg.Firm_Rural = 0.88; % Segmented Rural Wage
Params.w_reg.HH_Urban   = 1.12; Params.w_reg.Firm_Urban = 1.12; % Segmented Urban Wage
Params.Q_reg.HH_Rural   = 1.10; % Rural House Price Q(Rural)
Params.Q_reg.HH_Urban   = 2.45; % Overvalued Urban House Price Q(Urban) (Hirano & Toda)

%% 5. ATTACH RETURN FUNCTIONS & SOLVE MIXED-HORIZON VFI ACROSS REGIONS
for k_hh = {'HH_Rural', 'HH_Urban'}
    type = k_hh{1};
    ReturnFn.(type) = @(l, Ih, ic, aprime, hprime, a, h, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, omega_ic, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_b, agej, Jr, sj) ...
        ReturnFn_SpatialHH(l, Ih, ic, aprime, hprime, a, h, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, omega_ic, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_b, agej, Jr, sj);
end

for k_f = {'Firm_Rural', 'Firm_Urban'}
    type = k_f{1};
    ReturnFn.(type) = @(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a) ...
        ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a);
end

vfoptions.verbose = 1;
[V, Policy] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
              d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, ...
              DiscountFactorParamNames, vfoptions);

%% 6. STATIONARY DISTRIBUTION & ENDOGENOUS GUMBEL MIGRATION DIAGNOSTIC
for k_hh = {'HH_Rural', 'HH_Urban'}
    type = k_hh{1};
    jequaloneDist.(type) = zeros([n_a.(type), n_z.(type)]);
    h_init = [0.20, 0.25, 0.25, 0.20, 0.10];
    z_init = ones(n_z.(type), 1) / n_z.(type);
    for hh = 1:n_a.(type)(2)
        for zz = 1:n_z.(type)
            jequaloneDist.(type)(1, hh, zz) = h_init(hh) * z_init(zz);
        end
    end
end

simoptions.verbose = 0;
StationaryDist = StationaryDist_Case1_FHorz_PType(jequaloneDist, AgeWeightsParamNames, ...
                 PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, Names_i, ...
                 d_grid, a_grid, z_grid, pi_z, Params, simoptions);

% Compute Gumbel Migration Pressure between Rural & Urban for Young Cohorts (Source 2, Sec 2.1)
kappa_mig = 0.15; % Fixed moving cost from Rural to Urban
varrho_gumbel = 0.50; % Gumbel taste shock variance parameter
V_young_Rural = mean(V.HH_Rural(1, :, :, 1), 'all');
V_young_Urban = mean(V.HH_Urban(1, :, :, 1), 'all');
Prob_Migrate_RuralToUrban = exp((V_young_Urban - kappa_mig)/varrho_gumbel) / ...
    (exp(V_young_Rural/varrho_gumbel) + exp((V_young_Urban - kappa_mig)/varrho_gumbel));

fprintf('\n=== SPATIAL & HOUSING WEALTH TRANSFER DIAGNOSTICS ===\n');
fprintf('Young Rural-to-Urban Migration Probability: %.2f%%\n', 100 * Prob_Migrate_RuralToUrban);
