function Params = Apply_Calibrated_Params(Params, CalibSpec)
%% TIER C PROVENANCE CONTRACT: SMM-CALIBRATED & BEHAVIORAL ELASTICITIES
% File: src/config/Apply_Calibrated_Params.m
% Consolidates all internally calibrated skill-production, Ben-Porath, housing,
% warm-glow bequest, whanau/senescence, and local-procurement elasticities.
% Preserves caller-supplied fields on Params unless explicitly overridden via CalibSpec.

if nargin < 1 || isempty(Params)
    Params = struct();
end

scale_dt = 1.0;
if isfield(Params, 'dt') && ~isempty(Params.dt)
    scale_dt = Params.dt / 5.0;
end

%% 1. TWO-STAGE CHILD SKILL PRODUCTION (CUNHA-HECKMAN CES) & INTERGENERATIONAL LINKAGE
if ~isfield(Params, 'gamma1_self'), Params.gamma1_self = 0.53;  end
if ~isfield(Params, 'gamma1_inv'),  Params.gamma1_inv  = 0.24;  end
if ~isfield(Params, 'gamma1_par'),  Params.gamma1_par  = 0.23;  end
if ~isfield(Params, 'phi1_ces'),    Params.phi1_ces    = 0.35;  end

if ~isfield(Params, 'gamma2_self'), Params.gamma2_self = 0.87;  end
if ~isfield(Params, 'gamma2_inv'),  Params.gamma2_inv  = 0.07;  end
if ~isfield(Params, 'gamma2_par'),  Params.gamma2_par  = 0.06;  end
if ~isfield(Params, 'phi2_ces'),    Params.phi2_ces    = -0.95; end

if ~isfield(Params, 'gbar_ece'),    Params.gbar_ece    = 0.020; end
if ~isfield(Params, 'omega_ic'),    Params.omega_ic    = 0.420; end
if ~isfield(Params, 'h_par_mean'),  Params.h_par_mean  = 1.000; end
if ~isfield(Params, 'rho_hc_ig'),   Params.rho_hc_ig   = 0.40;  end
if ~isfield(Params, 'gamma_ic'),    Params.gamma_ic    = 0.35;  end
if ~isfield(Params, 'sigma_hc_ig'), Params.sigma_hc_ig = 0.18;  end % Canonical launch skill dispersion

%% 2. BEN-PORATH ADULT TRAINING, HOUSING TENURE, BEQUESTS & FIRM COLLATERAL
if ~isfield(Params, 'alpha_I'),    Params.alpha_I    = 0.090; end
if ~isfield(Params, 'alpha_H'),    Params.alpha_H    = 0.064; end
if ~isfield(Params, 'mu_maint'),   Params.mu_maint   = 0.04;  end
if ~isfield(Params, 'upsilon_h'),  Params.upsilon_h  = 0.008; end
if ~isfield(Params, 'chi_bar'),    Params.chi_bar    = 2.55;  end
if ~isfield(Params, 'b1_beq'),     Params.b1_beq     = 4.20;  end
if ~isfield(Params, 'b2_beq'),     Params.b2_beq     = 0.45;  end
if ~isfield(Params, 'lambda_col'), Params.lambda_col = 1.80;  end

%% 3. WHANAU CARE, SENESCENCE, BARGAINING & FISCAL U-CURVE ELASTICITIES
if ~isfield(Params, 'chi_f_SS0'),               Params.chi_f_SS0               = 0.240; end
if ~isfield(Params, 'chi_f_SS1'),               Params.chi_f_SS1               = 0.145; end
if ~isfield(Params, 'chi_f_SS2'),               Params.chi_f_SS2               = 0.132; end
if ~isfield(Params, 'leak_rate_super_up'),      Params.leak_rate_super_up      = 0.45;  end
if ~isfield(Params, 'offset_super_down'),       Params.offset_super_down       = 0.25;  end
if ~isfield(Params, 'eta_elder_whanau'),        Params.eta_elder_whanau        = 0.090; end
if ~isfield(Params, 'kappa_kuia_max'),          Params.kappa_kuia_max          = 0.160; end
if ~isfield(Params, 'tau_kuia_sat'),            Params.tau_kuia_sat            = 1.800; end
if ~isfield(Params, 'delta_senescence_post65'), Params.delta_senescence_post65 = 0.080; end
if ~isfield(Params, 'psi_wear_post65'),         Params.psi_wear_post65         = 0.140; end
if ~isfield(Params, 'psi_wear_early_relief'),   Params.psi_wear_early_relief   = 0.380; end
if ~isfield(Params, 'theta_healthy_wrk_65'),    Params.theta_healthy_wrk_65    = 0.480; end
if ~isfield(Params, 'lambda_health_decay_65'),  Params.lambda_health_decay_65  = 0.180; end
if ~isfield(Params, 'phi_geriatric_leak_base'), Params.phi_geriatric_leak_base = 1.150; end
if ~isfield(Params, 'phi_geriatric_leak_slope'),Params.phi_geriatric_leak_slope= 0.085; end
if ~isfield(Params, 'psi_sandwich_wrk_drag'),   Params.psi_sandwich_wrk_drag   = 0.350; end
if ~isfield(Params, 'omega_acc_offset_under65'),Params.omega_acc_offset_under65= 0.280; end
if ~isfield(Params, 'lambda_offset_decay_u65'), Params.lambda_offset_decay_u65 = 0.850; end
if ~isfield(Params, 'nu_peak_earn_u65'),        Params.nu_peak_earn_u65        = 1.050; end
if ~isfield(Params, 'nu_peak_earn_slope_u65'),  Params.nu_peak_earn_slope_u65  = 0.040; end
if ~isfield(Params, 'beta_aging_tax_drift'),    Params.beta_aging_tax_drift    = 0.220; end
if ~isfield(Params, 'beta_exits_skill_div'),    Params.beta_exits_skill_div    = 0.145; end
if ~isfield(Params, 'ss2_harvest_div_base'),    Params.ss2_harvest_div_base    = 2.070; end
if ~isfield(Params, 'psi_austerity_tax_drag'),  Params.psi_austerity_tax_drag  = 0.220; end

%% 3B. STATE-CONTINGENT SUB-MANIFOLD & SPATIAL GE ELASTICITIES (DOCUMENT 2A / 2T)
if ~isfield(Params, 'nu_kaiako_spatial'),     Params.nu_kaiako_spatial     = 0.340; end % Cross-regional rent drag exponent (Q_ref = 1.65)
if ~isfield(Params, 'nu_kaiako_cooling'),     Params.nu_kaiako_cooling     = 0.350; end % Intertemporal housing-cooling educator elasticity
if ~isfield(Params, 'psi_evict_transience'),  Params.psi_evict_transience  = 0.040; end % Comonotonic eviction/transience user-cost wedge
if ~isfield(Params, 'psi_sandwich_reversal'), Params.psi_sandwich_reversal = 0.280; end % Super > 65 sandwich care reversal amplitude
if ~isfield(Params, 'delta_theta_fade_base'), Params.delta_theta_fade_base = 0.140; end % Unbanked Stage-2 skill fade-out per step (x w2)
if ~isfield(Params, 'lambda_psy_base'),       Params.lambda_psy_base       = 0.220; end % Adolescent psychosocial hazard base (38% floor = 0.0836)
if ~isfield(Params, 'eta_mort_skill_grad'),   Params.eta_mort_skill_grad   = 0.050; end % Late-life skill-mortality hazard gradient
if ~isfield(Params, 'nu_span'),               Params.nu_span               = 0.150; end % Guvenen entrepreneurial span-of-control parameter
if ~isfield(Params, 'eta_arrow_s2'),          Params.eta_arrow_s2          = 0.140; end % Sector-2 Arrow learning-by-doing spillover elasticity
if ~isfield(Params, 'kappa_land_dH_slope'),   Params.kappa_land_dH_slope   = 2.450; end % Urban land-value share slope wrt supply elasticity delta_H

%% 4. LOCAL KAI / PROCUREMENT & ENTERPRISE UPGRADING ELASTICITIES
Params.kappa_olig_schedule = [0.000, 0.700, 1.000];
Params.G_food_share        = 0.012;
Params.chi_farm_col        = 0.120;
Params.kappa_bypass_olig   = 0.250;
Params.nu_kai_quality      = 0.180;
Params.psi_retire_T        = 0.850;
Params.T_reg_min_floor     = [0.008, 0.005, 0.000, 0.000];
Params.rho_olig_vec        = [0.008, 0.007, 0.005, 0.004] * scale_dt;
Params.rho_farm_vec        = [0.002, 0.002, 0.001, 0.001] * scale_dt;

%% 5. APPLY EXPLICIT SMM CALIBRATION STRUCT OR .MAT FILE OVERRIDES IF SUPPLIED
if nargin >= 2 && ~isempty(CalibSpec)
    if ischar(CalibSpec) || isstring(CalibSpec)
        S_load = load(char(CalibSpec));
        if isfield(S_load, 'CalibParams')
            CalibSpec = S_load.CalibParams;
        elseif isfield(S_load, 'Params_Calibrated')
            CalibSpec = S_load.Params_Calibrated;
        else
            CalibSpec = S_load;
        end
    end
    if isstruct(CalibSpec)
        fn = fieldnames(CalibSpec);
        for k = 1:numel(fn)
            Params.(fn{k}) = CalibSpec.(fn{k});
        end
    end
end

end
