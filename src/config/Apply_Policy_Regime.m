function [Params, z_grid_out, pi_z_out] = Apply_Policy_Regime(Params, RegimeSpec, Opts)
%% TIER D PROVENANCE CONTRACT: SINGLE SOURCE OF TRUTH FOR POLICY & COUNTERFACTUAL REGIMES
% File: src/config/Apply_Policy_Regime.m
% Usage:
%   Params_SS0 = Apply_Policy_Regime(Params, 'SS0');
%   Params_SS1 = Apply_Policy_Regime(Params, 'SS1');
%   Params_P0  = Apply_Policy_Regime(Params, 'P0_Early_0to5');
%   [P_GE, z_grid_m, pi_z_m] = Apply_Policy_Regime(Params_SS0, spec, struct('Stage','GE','z_grid',z_grid,'pi_z',pi_z));
%
% Centralizes all regime perturbations across FertilityBargaining_Module,
% PolicyExperiment_LeeSeshadri_4Region, WelfareDecomposition_4Region, and Build_Phase_Registry.

if nargin < 1 || isempty(Params)
    Params = Configure_Model_Params(struct());
end
if nargin < 2
    RegimeSpec = '';
end
if nargin < 3 || isempty(Opts)
    Opts = struct();
end

z_grid_out = get_opt(Opts, 'z_grid', struct());
pi_z_out   = get_opt(Opts, 'pi_z',   struct());
stage_mode = upper(char(get_opt(Opts, 'Stage', 'SYNC'))); % 'SYNC' | 'PE' | 'GE'

if ~isfield(Params, 'Enable_Duopoly_Kai')
    Params.Enable_Duopoly_Kai = false;
end

Reg_Names = Params.Regions;
N_reg     = numel(Reg_Names);

%% 1. APPLY NAMED OR STRUCT-SPECIFIED REGIME PERTURBATIONS BEFORE REGIONAL EXPANSION
if ischar(RegimeSpec) || isstring(RegimeSpec)
    r_code = strtrim(char(RegimeSpec));
    switch r_code
        case {'', 'Sync', 'SYNC'}
            % Synchronize active PType structs from existing *_base / active_* fields on Params

        case {'SS0', 'BM_Baseline', 'Baseline'}
            Params.G_ece_stage1_base    = Params.G_ece1_sched(1);
            Params.G_ece_stage2_base    = Params.G_ece2_sched(1);
            Params.G_ece_base           = Params.G_ece1_sched(1);
            Params.YouthGrant           = Params.YouthGrant_sched(1);
            Params.active_M_olig_vec    = Params.M_olig_SS0;
            Params.active_mu_monop_vec  = Params.mu_monop_SS0;
            Params.active_phi_local_vec = Params.phi_local_SS0;

        case 'Barnardos_ECE_PE'
            % Fertility Scenario 3: Stage 1 & 2 ECE expansion at SS0 baseline local food/prices
            Params.G_ece_stage1_base    = Params.G_ece1_sched(2);
            Params.G_ece_stage2_base    = Params.G_ece2_sched(2);
            Params.G_ece_base           = Params.G_ece1_sched(2);
            Params.active_M_olig_vec    = Params.M_olig_SS0;
            Params.active_mu_monop_vec  = Params.mu_monop_SS0;
            Params.active_phi_local_vec = Params.phi_local_SS0;

        case 'Austerity_Age70'
            Params.G_ece_stage1_base    = Params.G_ece1_sched(1);
            Params.G_ece_stage2_base    = Params.G_ece2_sched(1);
            Params.G_ece_base           = Params.G_ece1_sched(1);
            Params.active_phi_local_vec = Params.phi_local_SS0;
            Params.super_age            = 70.0;
            Params.Jr                   = 1 + (70.0 - 20.0) / Params.dt;

        case 'P0_Early_0to5'
            Params.G_ece_stage1_base    = Params.G_ece1_sched(2);
            Params.G_ece_base           = Params.G_ece_stage1_base;
            Params.tau_l                = Params.tau_l + 0.008;

        case 'P1P2_Late_6to17'
            Params.G_ece_stage2_base    = Params.G_ece2_sched(1) + 0.065;
            Params.tau_l                = Params.tau_l + 0.008;

        case 'BN_FrontLoad'
            Params.G_ece_stage1_base    = Params.G_ece1_sched(1) + 0.025;
            Params.G_ece_base           = Params.G_ece_stage1_base;
            Params.G_ece_stage2_base    = max(0.010, Params.G_ece2_sched(1) - 0.025);

        case 'P0_Plus_GrantE'
            Params.G_ece_stage1_base    = Params.G_ece1_sched(2);
            Params.G_ece_base           = Params.G_ece_stage1_base;
            Params.YouthGrant           = Params.YouthGrant_sched(2);
            Params.tau_b                = 0.250;
            tau_a_hh = scalar_or_hh(Params.tau_a, Reg_Names{1});
            tau_k_hh = scalar_or_hh(Params.tau_k, Reg_Names{1});
            Params.tau_a = struct();
            Params.tau_k = struct();
            for rr = 1:N_reg
                rn = Reg_Names{rr};
                Params.tau_a.(['HH_', rn])   = tau_a_hh;
                Params.tau_a.(['Firm_', rn]) = 0.015;
                Params.tau_k.(['HH_', rn])   = tau_k_hh;
                Params.tau_k.(['Firm_', rn]) = 0.120;
                Params.w_reg.(['HH_', rn])   = Params.w_reg.(['HH_', rn])   * Params.w_mult_SS1(rr);
                Params.w_reg.(['Firm_', rn]) = Params.w_reg.(['Firm_', rn]) * Params.w_mult_SS1(rr);
                Params.Q_reg.(['HH_', rn])   = Params.Q_reg.(['HH_', rn])   * Params.Q_mult_SS1(rr);
            end

        case 'SS1'
            Params.eta_deliv_vec        = Params.eta_delivery_SS1;
            Params.G_ece_stage1_base    = Params.G_ece1_sched(2);
            Params.G_ece_stage2_base    = Params.G_ece2_sched(2);
            Params.G_ece_base           = Params.G_ece1_sched(2);
            Params.active_M_olig_vec    = Params.M_olig_SS1;
            Params.active_mu_monop_vec  = Params.mu_monop_SS1;
            Params.active_phi_local_vec = Params.phi_local_SS1;
            if strcmp(stage_mode, 'PE') || strcmp(stage_mode, 'GE')
                spec_ss1 = Default_Reform_Phase_Specs(Params, false);
                [Params, z_grid_out, pi_z_out] = apply_phase_spec_internal(Params, spec_ss1(1), 1, stage_mode, z_grid_out, pi_z_out);
                return;
            end

        case 'SS2'
            % Note: Default 'SYNC' mode keeps Params.eta_deliv_vec (matching FertilityBargaining_Module
            % P_SS2 benchmark unless Stage = 'PE' or 'GE' is requested by WelfareDecomposition_4Region)
            Params.G_ece_stage1_base    = Params.G_ece1_sched(3);
            Params.G_ece_stage2_base    = Params.G_ece2_sched(3);
            Params.G_ece_base           = Params.G_ece1_sched(3);
            Params.active_M_olig_vec    = Params.M_olig_SS2;
            Params.active_mu_monop_vec  = Params.mu_monop_SS2;
            Params.active_phi_local_vec = Params.phi_local_SS2;
            if strcmp(stage_mode, 'PE') || strcmp(stage_mode, 'GE')
                specs_all = Default_Reform_Phase_Specs(Params, true);
                [Params, z_grid_out, pi_z_out] = apply_phase_spec_internal(Params, specs_all(2), 2, stage_mode, z_grid_out, pi_z_out);
                return;
            end

        otherwise
            error('IGWelfare:UnknownPolicyRegime', 'Unknown policy regime "%s".', r_code);
    end
elseif isstruct(RegimeSpec) && ~isempty(RegimeSpec)
    phase_idx = get_opt(Opts, 'PhaseIdx', 1);
    if isfield(RegimeSpec, 'Code') && strcmpi(RegimeSpec.Code, 'SS2') && phase_idx < 2
        phase_idx = 2;
    end
    [Params, z_grid_out, pi_z_out] = apply_phase_spec_internal(Params, RegimeSpec, phase_idx, stage_mode, z_grid_out, pi_z_out);
    return;
end

Params = sync_regional_policy_structs(Params);

end

%% ========================================================================
%  INTERNAL HELPERS
%% ========================================================================
function [P_Out, z_grid_m, pi_z_m] = apply_phase_spec_internal(Params_SS0, spec, m_idx, stage_mode, z_grid_in, pi_z_in)
Reg_Names = Params_SS0.Regions;
N_reg     = numel(Reg_Names);
z_grid_m  = z_grid_in;
pi_z_m    = pi_z_in;

% Stage A: Short-Run PE levers
P_PE = Params_SS0;
if m_idx == 1
    P_PE.eta_deliv_vec = Params_SS0.eta_delivery_SS1;
else
    P_PE.eta_deliv_vec = Params_SS0.eta_delivery_SS2;
end
P_PE.G_ece_stage1_base = spec.G_ece_stage1;
if isfield(spec, 'G_ece_stage2') && ~isempty(spec.G_ece_stage2)
    P_PE.G_ece_stage2_base = spec.G_ece_stage2;
else
    P_PE.G_ece_stage2_base = spec.G_ece_stage1;
end
P_PE.G_ece_base = spec.G_ece;
if isfield(spec, 'phi_local_vec') && ~isempty(spec.phi_local_vec)
    P_PE.active_phi_local_vec = spec.phi_local_vec;
else
    P_PE.active_phi_local_vec = Params_SS0.phi_local_SS1;
end
P_PE = sync_regional_policy_structs(P_PE);

mean_eta_m = sum(P_PE.eta_deliv_vec(:) .* Params_SS0.Pop_Weights_4(:));
yg0        = Params_SS0.YouthGrant_sched(1);
if strcmpi(Params_SS0.Rollout_Mode, 'SingleShot') && (m_idx == 1)
    eta_ygr_skill = 0.78 * mean_eta_m;
else
    eta_ygr_skill = 1.00 * mean_eta_m;
end
P_PE.YouthGrant = yg0 + eta_ygr_skill * (spec.YouthGrant - yg0);
P_PE.tau_a      = spec.tau_a;
P_PE.tau_b      = spec.tau_b;
if isfield(spec, 'tau_k') && ~isempty(spec.tau_k)
    P_PE.tau_k = spec.tau_k;
end
if isfield(spec, 'tau_l_delta') && ~isempty(spec.tau_l_delta)
    P_PE.tau_l = max(0.05, P_PE.tau_l + spec.tau_l_delta);
end
% In Stage 3A (Short-Run PE): Keynesian closure features stronger short-run aggregate demand / employment crowding-in
if isfield(spec, 'Frac_struggling') && isfield(P_PE, 'Frac_struggling')
    if isfield(Params_SS0, 'ge_closure') && strcmpi(Params_SS0.ge_closure, 'keynesian')
        P_PE.Frac_struggling = 0.35 * P_PE.Frac_struggling + 0.65 * spec.Frac_struggling;
    else
        P_PE.Frac_struggling = 0.50 * P_PE.Frac_struggling + 0.50 * spec.Frac_struggling;
    end
end
P_PE.Transfer_Geo     = spec.Transfer_Geo;
P_PE.Reform_Intensity = spec.Intensity * mean_eta_m;
P_PE.Phase_Label      = spec.Label;

if isfield(spec, 'super_age') && ~isempty(spec.super_age)
    super_age_m = spec.super_age;
else
    super_age_m = 65.0;
end
P_PE.super_age = super_age_m;
P_PE.Jr        = 1 + (super_age_m - 20.0) / Params_SS0.dt;

if strcmp(stage_mode, 'PE')
    P_Out = P_PE;
    return;
end

% Stage B: Long-Run GE prices, whanau care, electrification, & z_l -> z_h upgrading
P_GE   = P_PE;
P_GE.r = Params_SS0.r + spec.r_delta;
if isfield(spec, 'Frac_struggling')
    P_GE.Frac_struggling = spec.Frac_struggling;
end
if isfield(spec, 'S_cohesion')
    P_GE.S_cohesion = spec.S_cohesion;
end
if super_age_m >= 65
    elder_time_mult = exp(-Params_SS0.eta_elder_whanau * (super_age_m - 65));
else
    elder_time_mult = 1 + 0.16 * tanh((65 - super_age_m) / 1.8);
end

if isfield(spec, 'M_olig_vec') && ~isempty(spec.M_olig_vec)
    P_GE.active_M_olig_vec = spec.M_olig_vec;
elseif m_idx >= 2
    P_GE.active_M_olig_vec = Params_SS0.M_olig_SS2;
else
    P_GE.active_M_olig_vec = Params_SS0.M_olig_SS1;
end
if isfield(spec, 'mu_monop_vec') && ~isempty(spec.mu_monop_vec)
    P_GE.active_mu_monop_vec = spec.mu_monop_vec;
elseif m_idx >= 2
    P_GE.active_mu_monop_vec = Params_SS0.mu_monop_SS2;
else
    P_GE.active_mu_monop_vec = Params_SS0.mu_monop_SS1;
end
if isfield(spec, 'phi_local_vec') && ~isempty(spec.phi_local_vec)
    P_GE.active_phi_local_vec = spec.phi_local_vec;
elseif m_idx >= 2
    P_GE.active_phi_local_vec = Params_SS0.phi_local_SS2;
else
    P_GE.active_phi_local_vec = Params_SS0.phi_local_SS1;
end
P_GE = sync_regional_policy_structs(P_GE);

has_z = isstruct(z_grid_in) && ~isempty(fieldnames(z_grid_in));
has_p = isstruct(pi_z_in)   && ~isempty(fieldnames(pi_z_in));
for r_idx = 1:N_reg
    reg       = Reg_Names{r_idx};
    hh_type   = ['HH_', reg];
    firm_type = ['Firm_', reg];
    P_GE.w_reg.(hh_type)   = Params_SS0.w_reg.(hh_type)   * spec.w_mult_vs_SS0(r_idx);
    P_GE.w_reg.(firm_type) = Params_SS0.w_reg.(firm_type) * spec.w_mult_vs_SS0(r_idx);
    P_GE.Q_reg.(hh_type)   = Params_SS0.Q_reg.(hh_type)   * spec.Q_mult_vs_SS0(r_idx);
    elder_home_mult        = min(1.25, max(0.50, (1.0 / spec.Q_mult_vs_SS0(r_idx)) ^ 0.35));
    P_GE.K_whanau.(hh_type)= Params_SS0.K_whanau_base.(hh_type) * elder_home_mult * elder_time_mult;

    elec_comp = P_GE.s_active_elec_vec(r_idx) * P_GE.eta_deliv_vec(r_idx) * Params_SS0.ebar_elec_relief_share(r_idx);
    P_GE.ebar_energy.(hh_type) = Params_SS0.ebar_energy.(hh_type) * (1.0 - elec_comp);

    if has_z && isfield(z_grid_in, hh_type)
        d_mu_z_r           = P_GE.mu_z_reg_vec(r_idx) - Params_SS0.mu_z_SS0(r_idx);
        z_grid_m.(hh_type) = z_grid_in.(hh_type) * exp(d_mu_z_r);
    end
    if has_p && isfield(pi_z_in, firm_type)
        p_up_m             = P_GE.p_zh_upgrade_vec(r_idx);
        p_dn_m             = P_GE.p_zl_downgrade_v(r_idx);
        pi_z_m.(firm_type) = [1.0 - p_up_m, p_up_m; p_dn_m, 1.0 - p_dn_m];
    end
end
P_Out = P_GE;
end

function Params = sync_regional_policy_structs(Params)
Reg_Names = Params.Regions;
N_reg_ds  = numel(Reg_Names);

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

Params.G_ece_stage1    = struct();
Params.G_ece_stage2    = struct();
Params.G_ece           = struct();
Params.M_olig_reg      = struct();
Params.mu_monop_reg    = struct();
Params.rho_olig_reg    = struct();
Params.rho_farm_reg    = struct();
Params.lambda_col_mult = struct();

duo_on = double(logical(Params.Enable_Duopoly_Kai));
for r_idx = 1:N_reg_ds
    hh_type   = ['HH_', Reg_Names{r_idx}];
    firm_type = ['Firm_', Reg_Names{r_idx}];
    m_k       = Params.active_M_olig_vec(r_idx);
    alpha_f_k = Params.alpha_food_nd_vec(r_idx);
    mu_k      = Params.active_mu_monop_vec(r_idx);
    phi_k     = Params.active_phi_local_vec(r_idx);
    phi_0     = Params.phi_local_SS0(r_idx);

    dG_kai_k = duo_on * Params.G_food_share * Params.nu_kai_quality * sqrt(max(0.0, phi_k - phi_0));
    Params.G_ece_stage1.(hh_type) = Params.G_ece_stage1_base + 1.25 * dG_kai_k;
    Params.G_ece_stage2.(hh_type) = Params.G_ece_stage2_base + 0.85 * dG_kai_k;
    Params.G_ece.(hh_type)        = Params.G_ece_base        + 1.00 * dG_kai_k;

    Params.M_olig_reg.(hh_type)        = 1.0 + duo_on * alpha_f_k * (1.0 - Params.kappa_bypass_olig * phi_k) * (m_k - 1.0);
    Params.mu_monop_reg.(firm_type)    = 1.0 - duo_on * (1.0 - mu_k);
    Params.rho_olig_reg.(firm_type)    = duo_on * Params.rho_olig_vec(r_idx) * max(0.0, (m_k - 1.0) / max(1e-4, Params.M_olig_SS0(r_idx) - 1.0));
    Params.rho_farm_reg.(firm_type)    = duo_on * Params.rho_farm_vec(r_idx) * (phi_k / max(1e-4, phi_0));
    Params.lambda_col_mult.(firm_type) = 1.0 + duo_on * Params.chi_farm_col * phi_k;
end

ref_hh_first = ['HH_', Reg_Names{1}];
g1_scalar    = Params.G_ece_stage1.(ref_hh_first);
g2_scalar    = Params.G_ece_stage2.(ref_hh_first);

ece1_prog = (g1_scalar - Params.G_ece1_sched(1)) / max(1e-4, Params.G_ece1_sched(3) - Params.G_ece1_sched(1));
ece2_prog = (g2_scalar - Params.G_ece2_sched(1)) / max(1e-4, Params.G_ece2_sched(3) - Params.G_ece2_sched(1));
phi_prog  = (Params.active_phi_local_vec(1) - Params.phi_local_SS0(1)) / max(1e-4, Params.phi_local_SS2(1) - Params.phi_local_SS0(1));
Params.kai_upgrade_share = min(1.0, max(0.0, max(0.50 * ece1_prog + 0.50 * ece2_prog, phi_prog)));

Params.mu_z_reg_vec     = Params.mu_z_SS0 + Params.kai_upgrade_share * (Params.mu_z_SS2 - Params.mu_z_SS0);
Params.p_zh_upgrade_vec = [0.15, 0.15, 0.15, 0.15] + Params.kai_upgrade_share * [0.08, 0.06, 0.03, 0.01];
Params.p_zl_downgrade_v = [0.15, 0.15, 0.15, 0.15] - Params.kai_upgrade_share * [0.05, 0.04, 0.02, 0.00];

N_waves_ro = numel(Params.Waves_13);
if isfield(Params, 't_wave_yr') && ~isempty(Params.t_wave_yr) && Params.t_wave_yr >= 1 && Params.t_wave_yr <= N_waves_ro
    w_idx = round(Params.t_wave_yr);
    Params.s_active_ece_vec  = Params.Kahui_ECE_13x5(w_idx, 1:N_reg_ds);
    Params.s_active_ygr_vec  = Params.Kahui_YGr_Tot_13x5(w_idx, 1:N_reg_ds);
    Params.s_active_elec_vec = Params.Kahui_Elc_13x5(w_idx, 1:N_reg_ds);
else
    if ~isfield(Params, 's_active_ece_vec'),  Params.s_active_ece_vec  = ones(1, N_reg_ds); end
    if ~isfield(Params, 's_active_ygr_vec'),  Params.s_active_ygr_vec  = ones(1, N_reg_ds); end
    if ~isfield(Params, 's_active_elec_vec'), Params.s_active_elec_vec = ones(1, N_reg_ds); end
end
if ~isfield(Params, 'eta_deliv_vec'), Params.eta_deliv_vec = Params.eta_delivery_SS1; end

for r_idx = 1:N_reg_ds
    hh_type = ['HH_', Reg_Names{r_idx}];
    eta_k   = Params.eta_deliv_vec(r_idx);
    g1_0    = Params.G_ece1_sched(1);
    g2_0    = Params.G_ece2_sched(1);
    Params.G_ece_stage1.(hh_type) = g1_0 + eta_k * (Params.G_ece_stage1.(hh_type) - g1_0);
    Params.G_ece_stage2.(hh_type) = g2_0 + eta_k * (Params.G_ece_stage2.(hh_type) - g2_0);
    Params.G_ece.(hh_type)        = g1_0 + eta_k * (Params.G_ece.(hh_type)        - g1_0);
    Params.s_active_ece.(hh_type) = Params.s_active_ece_vec(r_idx);
end
end

function v = get_opt(S, fname, def_v)
if isstruct(S) && isfield(S, fname) && ~isempty(S.(fname))
    v = S.(fname);
else
    v = def_v;
end
end

function v = scalar_or_hh(x, first_reg)
if isstruct(x)
    v = x.(['HH_', first_reg]);
else
    v = x;
end
end
