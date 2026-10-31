function Params = Configure_TimeGrid_Params(Params, dt)
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
Params.dt  = dt;
scale_dt   = dt / 5; % Ratio relative to the 5-year calibration benchmark

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
if ~isfield(Params, 'beta_hh');   Params.beta_hh   = 0.96^dt; else; Params.beta_hh   = (Params.beta_hh^(1/5))^dt; end
if ~isfield(Params, 'beta_firm'); Params.beta_firm = 0.95^dt; else; Params.beta_firm = (Params.beta_firm^(1/5))^dt; end
if ~isfield(Params, 'r');         Params.r         = (1 + 0.20)^scale_dt - 1; end
if ~isfield(Params, 'delta_hc');  Params.delta_hc  = 1 - (1 - 0.087)^scale_dt; end
if ~isfield(Params, 'delta_k');   Params.delta_k   = 1 - (1 - 0.06)^dt; end

Params.T_trans_years = 60;
Params.T_trans       = round(Params.T_trans_years / dt); % 12 (dt=5), 20 (dt=3), 30 (dt=2)
Params.zeta_cohort   = 1 - (1 - 0.085)^scale_dt;

%% 5. CANONICAL 4-REGION WHANAU, STUNTING, & MIGRATION CALIBRATION (SINGLE SOURCE OF TRUTH)
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

% Canonical regional stunting targets (%) & launch skill drift vector
Params.base_stunt_vec  = [19.8, 18.2, 15.6, 14.3];
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
if ~isfield(Params, 'beta_exits_skill_div'),     Params.beta_exits_skill_div     = 0.145; end % Marginal PAYE tax relief per pp of stunting cut
if ~isfield(Params, 'ss2_harvest_div_base'),     Params.ss2_harvest_div_base     = 2.070; end % SS2 debt-sinking (-60 bps) + GE tax-base dividend (pp)
if ~isfield(Params, 'psi_austerity_tax_drag'),   Params.psi_austerity_tax_drag   = 0.220; end % SS2 harvest erosion coefficient when Super > 65

end
