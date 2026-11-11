function Params = Configure_TimeGrid_Params(Params, dt, n_z_pts)
%% CONFIGURE_TIMEGRID_PARAMS
% Single Source of Truth for Time-Grid, Demographic, Spatial, Whanau, and
% Intergenerational Calibration Parameters across all 5D and 4D scripts.

if nargin < 2 || isempty(dt)
    if isfield(Params, 'dt') && ~isempty(Params.dt)
        dt = Params.dt;
    else
        dt = 5;
    end
end
if nargin < 3 || isempty(n_z_pts)
    if isfield(Params, 'n_z_pts') && ~isempty(Params.n_z_pts)
        n_z_pts = Params.n_z_pts;
    else
        n_z_pts = 7;
    end
end
Params.dt      = dt;
scale_dt       = dt / 5;  % Ratio relative to the 5-year calibration benchmark
Params.n_z_pts = n_z_pts; % N-point Rouwenhorst regional productivity grid

%% 1. LIFE-CYCLE HORIZON (AGES 20-99) & RETIREMENT BOUNDARY (AGE 65)
Params.J    = round(80 / dt);           % 16 (dt=5), 27 (dt=3), 40 (dt=2)
Params.Jr   = 1 + round(45 / dt);       % 10 (dt=5), 16 (dt=3), 23 (dt=2)
Params.agej = 1:Params.J;

%% 2. CHILDHOOD & LIFECYCLE HUMAN CAPITAL WINDOWS
Params.j_s1_start     = 1 + round(10 / dt);               % Age 30: j=3 (dt=5), j=4 (dt=3), j=6 (dt=2)
Params.n_stage1_steps = max(1, round(5 / dt));            % 1 (dt=5), 2 (dt=3), 3 (dt=2)
Params.j_s1_end       = Params.j_s1_start + Params.n_stage1_steps - 1;

Params.j_s2_start     = Params.j_s1_end + 1;              % Age 35: j=4 (dt=5), j=6 (dt=3), j=9 (dt=2)
Params.n_stage2_steps = max(1, round(5 / dt));            % 1 (dt=5), 2 (dt=3), 3 (dt=2)
Params.j_s2_end       = Params.j_s2_start + Params.n_stage2_steps - 1;

Params.j_child_launch = min(Params.J, Params.j_s2_end + 1); % j=5 (dt=5), j=8 (dt=3), j=12 (dt=2)

%% 3. TREASURY OLG SURVIVAL, FERTILITY, & MIGRATION VECTORS (INTERPOLATED TO J)
sj_5yr  = [0.995, 0.994, 0.993, 0.991, 0.988, 0.983, 0.975, 0.962, ...
    0.942, 0.910, 0.860, 0.780, 0.660, 0.500, 0.300, 0.000];
fj_5yr  = [0.15, 0.65, 0.65, 0.20, zeros(1, 12)];
mig_5yr = [0.018, -0.012, -0.005, 0.015, 0.010, 0.006, 0.003, zeros(1, 9)];
Params.sj_5yr_ref = sj_5yr; % Retained for dt-invariant OLG cohort pyramid benchmarks

if dt == 5
    Params.sj         = sj_5yr;
    Params.fj         = fj_5yr;
    Params.mig_rate_j = mig_5yr;
else
    age_5yr_mid = linspace(22.5, 97.5, 16);
    age_dt_mid  = linspace(20 + dt/2, 100 - dt/2, Params.J);

    sj_interp         = interp1(age_5yr_mid, sj_5yr, age_dt_mid, 'pchip');
    Params.sj         = max(0, min(0.999, sj_interp)) .^ scale_dt;
    Params.sj(end)    = 0.0;

    Params.fj         = max(0, interp1(age_5yr_mid, fj_5yr, age_dt_mid, 'linear', 0)) * scale_dt;
    Params.mig_rate_j = interp1(age_5yr_mid, mig_5yr, age_dt_mid, 'linear', 0) * scale_dt;
end

%% 4. COMPOUNDED DISCOUNT, RETURN, DEPRECIATION, & TRANSITION RATES
Params.beta_hh   = 0.985^dt;
Params.beta_firm = 0.9815^dt;
if ~isfield(Params, 'r');         Params.r         = (1 + 0.20)^scale_dt - 1; end
if ~isfield(Params, 'delta_hc');  Params.delta_hc  = 1 - (1 - 0.087)^scale_dt; end
if ~isfield(Params, 'delta_k');   Params.delta_k   = 1 - (1 - 0.06)^dt; end

Params.T_trans_years = 60;
Params.T_trans       = round(Params.T_trans_years / dt); % 12 (dt=5), 20 (dt=3), 30 (dt=2)
Params.zeta_cohort   = 1 - (1 - 0.085)^scale_dt;

%% 5. CANONICAL 4-REGION POPULATION, WHANAU, HARDSHIP, & MIGRATION CALIBRATION (SINGLE SOURCE OF TRUTH)
Params.Reg_Names_4    = {'Rural', 'Small', 'Large', 'Auckland'};
Params.Reg_Names_5    = {'Rural', 'Small', 'Large', 'Auckland', 'National'};
if ~isfield(Params, 'Pop_Weights_4'),  Params.Pop_Weights_4  = [0.160, 0.240, 0.259, 0.341]; end % Stats NZ HH shares [Rural, Small, Large, Auckland]
if ~isfield(Params, 'Firm_Weights_4'), Params.Firm_Weights_4 = [0.150, 0.230, 0.269, 0.351]; end % Stats NZ Firm shares [Rural, Small, Large, Auckland]
Params.Pop_Weights_5  = [Params.Pop_Weights_4, 1.000]; % 5th column = National (100% population weight)
Params.Pop_Weights_3  = [Params.Pop_Weights_4(1) + Params.Pop_Weights_4(2), Params.Pop_Weights_4(3), Params.Pop_Weights_4(4)]; % [Rural+Small, Large, Auckland]
Params.NZD_Per_CE_Nat = 2.38;  % National 1.0% CE equivalent in Real 2025 BNZD/yr
Params.GDP_2026_BNZD  = 430.0; % National 2026 GDP anchor in Real 2025 BNZD/yr

Params.K_whanau_base_vec = [0.42, 0.38, 0.32, 0.28]; % [Rural, Small, Large, Auckland]
if ~isfield(Params, 'K_whanau_base')
    Params.K_whanau_base = struct('HH_Rural', 0.42, 'HH_Small', 0.38, 'HH_Large', 0.32, 'HH_Auckland', 0.28);
end
if ~isfield(Params, 'K_whanau')
    Params.K_whanau = Params.K_whanau_base;
end
if ~isfield(Params, 'Q_reg_base')
    Params.Q_reg_base = struct('HH_Rural', 1.05, 'HH_Small', 1.40, 'HH_Large', 2.05, 'HH_Auckland', 3.10);
end

% Canonical regional early hardship targets (%) & launch skill drift vector
Params.base_struggle_vec  = [19.8, 18.2, 15.6, 14.3];
Params.reg_skill_drift = [-0.083, -0.059, -0.024, -0.020];

% Canonical 4x5 Gumbel migration utility matrix [Rural, Small, Large, Auckland, Abroad]
Params.u_target_4x5 = [ ...
     2.85,  1.15,  0.65,  0.15, -0.82;   % From Rural    (1.8% Emig)
     0.55,  2.45,  1.05,  0.45,  0.65;   % From Small    (9.1% Emig)
    -0.25,  0.45,  2.15,  1.05,  1.45;   % From Large    (23.4% Emig)
    -0.45,  0.15,  0.65,  2.55,  0.16];  % From Auckland (7.0% Net / 19.3% Gross Emig)

% Canonical Daruich (2018) 4-region endogenous intergenerational skill & retention lift
Params.daruich_ig_mult = [5.51, 7.27, 8.00, 9.93];

if ~isfield(Params, 'leak_rate_super_up'), Params.leak_rate_super_up = 0.45; end % 45% disability/hardship leak when age > 65
if ~isfield(Params, 'offset_super_down'),  Params.offset_super_down  = 0.25; end % 25% ACC/Jobseeker savings when age < 65

%% 6. NAMED PARAMETERS FOR NZ SUPER ELIGIBILITY AGE, SENESCENCE, & WHANAU CARE ELASTICITIES
% Literature Anchors:
%   - Rupert & Zanella (2018, J. Labor Econ.) / Compton & Pollak (2014): Grandparent childcare time elasticity
%   - Fan, Seshadri, & Taber (2022) / French (2005, RES): Late-life wage senescence & labor disutility slope
%   - Case & Deaton (2005) / Coe & Van Houtven (2009): Age-morbidity decay & sandwich elder-care labor drag
if ~isfield(Params, 'super_age_base'),           Params.super_age_base           = 65.0;  end % Statutory NZ Super baseline age
if ~isfield(Params, 'super_age_SS1'),            Params.super_age_SS1            = 65.0;  end % Phase 1 (SS1) NZ Super age
if ~isfield(Params, 'super_age_SS2'),            Params.super_age_SS2            = 64.0;  end % Phase 2 (SS2) NZ Super target age
if ~isfield(Params, 'eta_elder_whanau'),         Params.eta_elder_whanau         = 0.090; end % 9%/yr grandparent time loss for Super > 65
if ~isfield(Params, 'kappa_kuia_max'),           Params.kappa_kuia_max           = 0.160; end % +16% max Kuia/Koroua time boost for Super < 65
if ~isfield(Params, 'tau_kuia_sat'),             Params.tau_kuia_sat             = 1.800; end % Concave saturation scale (yrs below 65)
if ~isfield(Params, 'delta_senescence_post65'),  Params.delta_senescence_post65  = 0.080; end % 8%/yr physiological earning decay past 65
if ~isfield(Params, 'psi_wear_post65'),          Params.psi_wear_post65          = 0.140; end % Annual late-life work disutility slope past 65
if ~isfield(Params, 'psi_wear_early_relief'),    Params.psi_wear_early_relief    = 0.380; end % Pre-65 manual wear relief when Super < 65
if ~isfield(Params, 'theta_healthy_wrk_65'),     Params.theta_healthy_wrk_65     = 0.480; end % Healthy full-time work share among displaced 65yo
if ~isfield(Params, 'lambda_health_decay_65'),   Params.lambda_health_decay_65   = 0.180; end % Morbidity decay rate per yr above 65
if ~isfield(Params, 'phi_geriatric_leak_base'),  Params.phi_geriatric_leak_base  = 1.150; end % Base disability/hospital leak mult (>65)
if ~isfield(Params, 'phi_geriatric_leak_slope'), Params.phi_geriatric_leak_slope = 0.085; end % Annual geriatric hospital leak escalation (>65)
if ~isfield(Params, 'psi_sandwich_wrk_drag'),    Params.psi_sandwich_wrk_drag    = 0.350; end % Adult-child caregiver tax-base drag per sick elder
if ~isfield(Params, 'omega_acc_offset_under65'), Params.omega_acc_offset_under65 = 0.280; end % Age-64 ACC/disability offset share (<65)
if ~isfield(Params, 'lambda_offset_decay_u65'),  Params.lambda_offset_decay_u65  = 0.850; end % Decay rate of ACC offset for younger ages 60-63
if ~isfield(Params, 'nu_peak_earn_u65'),         Params.nu_peak_earn_u65         = 1.050; end % Base tax-capacity weight of 60-64 peak earners
if ~isfield(Params, 'nu_peak_earn_slope_u65'),   Params.nu_peak_earn_slope_u65   = 0.040; end % Additional tax-capacity loss per yr below 65
if ~isfield(Params, 'dep_ratio_2026_anchor'),    Params.dep_ratio_2026_anchor    = 24.50; end % 2026 OLG dependency ratio anchor at tau_l = 22%
if ~isfield(Params, 'beta_aging_tax_drift'),     Params.beta_aging_tax_drift     = 0.220; end % Marginal PAYE tax sensitivity to dependency ratio
if ~isfield(Params, 'beta_exits_skill_div'),     Params.beta_exits_skill_div     = 0.145; end % Marginal PAYE tax relief per pp of early hardship cut

%% 7. CANONICAL REGIME SCHEDULES & LOCAL PROCUREMENT / MENTORING (z_l -> z_h) UPGRADING
% Literature & Empirical Anchors:
%   - Jon Duffy (Consumer NZ) / Commerce Commission: Retail duopoly & farm-gate monopsony rent extraction
%     blocking rural/provincial enterprise capital formation and trapping regions in low-wage z_l equilibria.
%   - NC State CEFS Farm to ECE (Cosco et al. 2022; Color Me Healthy RCT): +24% to +33% preschool vegetable
%     intake (d = 1.20), +26.6 pp parent nutrition crowding-in (53.5% -> 80.1%), 46% take-home garden produce.
%   - NC State CEFS 2025-2026 Local Food Purchasing Incentive (LFPI) & Bloom et al. (2022): Directing upfront
%     working capital via regional food hubs yields a 1.60x-2.16x local economic multiplier.
%   - NC State CEFS Food Youth Initiative (FYI) & GrowingChange (Sanford): Paid youth agricultural leadership
%     and food-hub apprenticeships achieve a 92% non-recidivism rate and retain skilled rural youth.
if ~isfield(Params, 'Enable_Duopoly_Kai'), Params.Enable_Duopoly_Kai = false; end

% Canonical National Policy Schedules across [SS0, SS1, SS2]:
Params.G_ece1_sched     = [0.045, 0.110, 0.130]; % Gate 1 (Ages 0-5) national public investment schedule
Params.G_ece2_sched     = [0.065, 0.085, 0.105]; % Gate 2 (Ages 6-17) national public investment schedule
Params.YouthGrant_sched = [0.030, 0.065, 0.080]; % Age-20 Opportunity Endowment schedule
Params.w_mult_SS0       = [1.000, 1.000, 1.000, 1.000];
Params.w_mult_SS1       = [1.032, 1.038, 1.048, 1.055];
Params.w_mult_SS2       = [1.068, 1.075, 1.088, 1.096];
Params.Q_mult_SS0       = [1.000, 1.000, 1.000, 1.000];
Params.Q_mult_SS1       = [0.990, 0.975, 0.950, 0.925];
Params.Q_mult_SS2       = [0.985, 0.955, 0.925, 0.895];

% Regional Duopoly, Monopsony, & Local Food vectors ordered: [Rural, Small, Large, Auckland]
% Retained for full compatibility with FertilityBargaining_Module and suite scripts
Params.M_olig_SS0          = [1.080, 1.070, 1.050, 1.040]; % Status quo grocery duopoly markup
Params.M_olig_SS1          = [1.025, 1.020, 1.015, 1.010]; % Phase-1 Commerce Commission + Co-op reform
Params.M_olig_SS2          = [1.000, 1.000, 1.000, 1.000]; % Phase-2 full competitive convergence
Params.alpha_food_nd_vec   = [0.085, 0.075, 0.045, 0.030]; % Cardinal-calibrated grocery incidence [Rural, Small, Large, Akl]
Params.mu_monop_SS0        = [0.910, 0.930, 0.980, 1.000]; % Farm-gate wholesale monopsony markdown
Params.mu_monop_SS1        = [0.975, 0.980, 0.995, 1.000]; % Grocery supply code + grower bargaining
Params.mu_monop_SS2        = [1.000, 1.000, 1.000, 1.000]; % Full farm-gate price parity
Params.phi_local_SS0       = [0.150, 0.150, 0.100, 0.100]; % SS0 local school/marae food share
Params.phi_local_SS1       = [0.850, 0.800, 0.650, 0.550]; % SS1 Farm-to-School & Farm-to-Marae switch
Params.phi_local_SS2       = [0.950, 0.900, 0.750, 0.650]; % SS2 mature regional food hubs
Params.kappa_olig_schedule = [0.000, 0.700, 1.000];        % [SS0, SS1, SS2] enforcement intensity
Params.G_food_share        = 0.012; % Public school/ECE nutrition procurement budget
Params.chi_farm_col        = 0.120; % Collateral relaxation from bankable local food contracts
Params.kappa_bypass_olig   = 0.250; % Direct Farm-to-Marae/Co-op household bypass of retail markup
Params.nu_kai_quality      = 0.180; % Fresh local kai nutritional efficacy elasticity (Ka Ora, Ka Ako)
Params.psi_retire_T        = 0.850; % Rate at which duopoly/monopsony relief retires Transfer_Geo
Params.T_reg_min_floor     = [0.008, 0.005, 0.000, 0.000]; % Residual remote-geography floor
Params.rho_olig_vec        = [0.008, 0.007, 0.005, 0.004] * scale_dt; % Passive z_l oligopoly rent yield
Params.rho_farm_vec        = [0.002, 0.002, 0.001, 0.001] * scale_dt; % Active z_h local kai contract yield

% If caller passed scalar G_ece_stage1 / G_ece_stage2 / G_ece, promote to *_base and reset to struct()
if isfield(Params, 'G_ece_stage1') && ~isstruct(Params.G_ece_stage1)
    Params.G_ece_stage1_base = Params.G_ece_stage1;
end
if isfield(Params, 'G_ece_stage2') && ~isstruct(Params.G_ece_stage2)
    Params.G_ece_stage2_base = Params.G_ece_stage2;
end
if isfield(Params, 'G_ece') && ~isstruct(Params.G_ece)
    Params.G_ece_base = Params.G_ece;
end

if ~isfield(Params, 'G_ece_stage1_base'),   Params.G_ece_stage1_base   = Params.G_ece1_sched(1); end
if ~isfield(Params, 'G_ece_stage2_base'),   Params.G_ece_stage2_base   = Params.G_ece2_sched(1); end
if ~isfield(Params, 'G_ece_base'),          Params.G_ece_base          = Params.G_ece_stage1_base; end
if ~isfield(Params, 'active_M_olig_vec'),    Params.active_M_olig_vec    = Params.M_olig_SS0;    end
if ~isfield(Params, 'active_mu_monop_vec'),  Params.active_mu_monop_vec  = Params.mu_monop_SS0;  end
if ~isfield(Params, 'active_phi_local_vec'), Params.active_phi_local_vec = Params.phi_local_SS0; end

% Reset to struct() so Octave never errors when converting a double to a regional struct
Params.G_ece_stage1    = struct();
Params.G_ece_stage2    = struct();
Params.G_ece           = struct();
Params.M_olig_reg      = struct();
Params.mu_monop_reg    = struct();
Params.rho_olig_reg    = struct();
Params.rho_farm_reg    = struct();
Params.lambda_col_mult = struct();

% Single-Source-of-Truth Regional Struct Population for PType Solvers
Reg_Names = {'Rural', 'Small', 'Large', 'Auckland'};
duo_on    = double(logical(Params.Enable_Duopoly_Kai));
for r_idx = 1:4
    hh_type   = ['HH_', Reg_Names{r_idx}];
    firm_type = ['Firm_', Reg_Names{r_idx}];
    m_k       = Params.active_M_olig_vec(r_idx);
    alpha_f_k = Params.alpha_food_nd_vec(r_idx);
    mu_k      = Params.active_mu_monop_vec(r_idx);
    phi_k     = Params.active_phi_local_vec(r_idx);
    phi_0     = Params.phi_local_SS0(r_idx);

    % 1. Additive bioavailability/attendance gain on the G_food_share nutrition slice:
    dG_kai_k = duo_on * Params.G_food_share * Params.nu_kai_quality * sqrt(max(0.0, phi_k - phi_0));
    Params.G_ece_stage1.(hh_type) = Params.G_ece_stage1_base + 1.25 * dG_kai_k;
    Params.G_ece_stage2.(hh_type) = Params.G_ece_stage2_base + 0.85 * dG_kai_k;
    Params.G_ece.(hh_type)        = Params.G_ece_base        + 1.00 * dG_kai_k;

    % 2. Composite non-durable price index M_olig_reg weighted by grocery incidence alpha_food_nd_vec(r_idx)
    Params.M_olig_reg.(hh_type)   = 1.0 + duo_on * alpha_f_k * (1.0 - Params.kappa_bypass_olig * phi_k) * (m_k - 1.0);

    % 3. Firm monopsony markdown, passive z_l oligopoly rent, & active z_h local kai contract yield
    Params.mu_monop_reg.(firm_type)    = 1.0 - duo_on * (1.0 - mu_k);
    Params.rho_olig_reg.(firm_type)    = duo_on * Params.rho_olig_vec(r_idx) * max(0.0, (m_k - 1.0) / max(1e-4, Params.M_olig_SS0(r_idx) - 1.0));
    Params.rho_farm_reg.(firm_type)    = duo_on * Params.rho_farm_vec(r_idx) * (phi_k / max(1e-4, phi_0));
    Params.lambda_col_mult.(firm_type) = 1.0 + duo_on * Params.chi_farm_col * phi_k;
end

% 4. Endogenous Regional z_l -> z_h Job & Enterprise Upgrading (Ka Ora, Ka Ako & CEFS LFPI / FYI):
% In SS0, wholesale monopsony extraction & casualization depress Rural (-0.060) and Small (-0.010) job quality (z_l).
% As Gate 1/2 local procurement (1.60x-2.16x LFPI multiplier) & FYI youth career pathways scale up from SS0 to SS2,
% Rural and Small communities bypass rent-seeking intermediaries and upgrade z_l -> z_h:
Params.mu_z_SS0    = [-0.060, -0.010, 0.060, 0.150];
Params.mu_z_SS2    = [-0.020,  0.020, 0.075, 0.155];
Params.sigma_z_vec = [ 0.110,  0.140, 0.180, 0.240];

g1_scalar = Params.G_ece_stage1_base;
if isfield(Params, 'G_ece_stage1')
    if isstruct(Params.G_ece_stage1), g1_scalar = Params.G_ece_stage1.HH_Rural; else, g1_scalar = Params.G_ece_stage1; end
end
g2_scalar = Params.G_ece_stage2_base;
if isfield(Params, 'G_ece_stage2')
    if isstruct(Params.G_ece_stage2), g2_scalar = Params.G_ece_stage2.HH_Rural; else, g2_scalar = Params.G_ece_stage2; end
end

ece1_prog = (g1_scalar - Params.G_ece1_sched(1)) / max(1e-4, Params.G_ece1_sched(3) - Params.G_ece1_sched(1));
ece2_prog = (g2_scalar - Params.G_ece2_sched(1)) / max(1e-4, Params.G_ece2_sched(3) - Params.G_ece2_sched(1));
phi_prog  = (Params.active_phi_local_vec(1) - Params.phi_local_SS0(1)) / max(1e-4, Params.phi_local_SS2(1) - Params.phi_local_SS0(1));
Params.kai_upgrade_share = min(1.0, max(0.0, max(0.50 * ece1_prog + 0.50 * ece2_prog, phi_prog)));

% Active regional log(z) Rouwenhorst mean drift & Firm z_l -> z_h Markov transition probabilities:
Params.mu_z_reg_vec     = Params.mu_z_SS0 + Params.kai_upgrade_share * (Params.mu_z_SS2 - Params.mu_z_SS0);
Params.p_zh_upgrade_vec = [0.15, 0.15, 0.15, 0.15] + Params.kai_upgrade_share * [0.08, 0.06, 0.03, 0.01];
Params.p_zl_downgrade_v = [0.15, 0.15, 0.15, 0.15] - Params.kai_upgrade_share * [0.05, 0.04, 0.02, 0.00];

%% 8. Long-term (SS2) Macro Investment Parameters

if ~isfield(Params, 'ss2_harvest_div_base'),     Params.ss2_harvest_div_base     = 2.070; end % SS2 debt-sinking (-60 bps) + GE tax-base dividend (pp)
if ~isfield(Params, 'psi_austerity_tax_drag'),   Params.psi_austerity_tax_drag   = 0.220; end % SS2 harvest erosion coefficient when Super > 65

end
