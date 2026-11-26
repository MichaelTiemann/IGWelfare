function [Params_Out, pi_z_Out, BundleMeta, z_grid_Out] = Compose_Policy_Bundle(Params_In, pi_z_In, BundleSpecOrName, Opts, z_grid_In)
%% COMPOSITIONAL POLICY ALGEBRA OVER ONGOING INSTITUTIONAL COMMITMENTS (CONVENTION 2)
% File: src/config/Compose_Policy_Bundle.m
% Maps any named bundle, legacy preset alias, or arbitrary vector/struct of signed
% institutional commitment dials u_i in (-inf, +inf) onto VFI-ready (Params, pi_z, z_grid):
%
%   - Public capability, health, infrastructure & civic commitments (C01..C08, C12..C15):
%       u_i > 0 : Strengthen / invest in commitment (e.g., C15 = +1.0 -> Doc 1E Joiner Passport)
%       u_i < 0 : Retrench / defer commitment       (e.g., C15 = -1.0 -> 2024-26 Arts/WCC pullback)
%   - Tax-relief, investor-visa & expensing levers (C09..C11):
%       u_i > 0 : Enact tax threshold relief / investor inflow / 20% immediate expensing
%       u_i < 0 : Tighten tax/depreciation/screening schedule
%
% Composition property:
%   Compose_Policy_Bundle(P0, pi0, {'retrenchment_and_tenure_10', 'tax_visa_expensing_3'})
%   additively sums the underlying commitment dial vectors u = u_A + u_B and resolves
%   all endogenous cross-gate couplings (Kaiako Q_k deflator, Guvenen w_k MPL pass-through,
%   K_whanau club/elder buffering, & 4x5 Gumbel migration sorting) in one pure pass!

if nargin < 2, pi_z_In = struct(); end
if nargin < 3 || isempty(BundleSpecOrName)
    BundleSpecOrName = 'domestic_15_bundle';
end
if nargin < 4 || isempty(Opts)
    Opts = struct();
end
if nargin < 5
    z_grid_In = struct();
end

if ~isfield(Params_In, 'Pop_Weights_4') || ~isfield(Params_In, 'Profile_ID')
    Params_In = Configure_Model_Params(Params_In);
end

if isfield(Params_In, 'DataSpec') && isstruct(Params_In.DataSpec)
    prof_ref = Params_In.DataSpec;
elseif isfield(Params_In, 'Profile_ID') && ~isempty(Params_In.Profile_ID)
    prof_ref = Params_In.Profile_ID;
elseif isfield(Params_In, 'Profile_Name') && ~isempty(Params_In.Profile_Name)
    prof_ref = Params_In.Profile_Name;
else
    prof_ref = 'NZ_Dunedin1972';
end
Catalog = Load_Commitment_Catalog(prof_ref);
CIDs    = Catalog.Commitment_IDs;
nC      = numel(CIDs);

% 1. Resolve BundleSpecOrName (supports single name, cell array of composed bundles, or custom struct!)
[u_vec, is_reanchor, resolved_label] = resolve_dial_vector(BundleSpecOrName, Catalog, Opts);

% Separate pass-through scales for macro announcement commitments (C01..C13) vs direct statutory rates/civic (C14..C15)
s_direct = get_opt(Opts, 'ShockScale',  get_opt(Opts, 'DirectScale', 1.0000));
s_core13 = get_opt(Opts, 'Core13Scale', Catalog.Default_Core13_PassThrough * s_direct);

is_core13 = false(nC, 1);
is_core13(1:min(13, nC)) = true; % C01..C13 use macro announcement pass-through s_core13; C14+ enter at direct scale s_direct
eff_u = u_vec;
eff_u(is_core13)  = u_vec(is_core13)  * s_core13;
eff_u(~is_core13) = u_vec(~is_core13) * s_direct;

Params_Out = Params_In;
pi_z_Out   = pi_z_In;
z_grid_Out = z_grid_In;
Regions    = Params_Out.Regions;
scale_dt   = Params_Out.dt / 5.0;

Dials = cell2struct(num2cell(u_vec(:)'), CIDs(:)', 2);
Eff   = cell2struct(num2cell(eff_u(:)'), CIDs(:)', 2);

BundleMeta = struct();
BundleMeta.Bundle_Label     = resolved_label;
BundleMeta.Raw_Dials        = Dials;
BundleMeta.Effective_Dials  = Eff;
BundleMeta.Core13Scale      = s_core13;
BundleMeta.DirectScale      = s_direct;
BundleMeta.Catalog_Digest   = Catalog.Digest;

%% ========================================================================
%  ANCHOR MODE: PRE-SHOCK 2023 BASELINE ECONOMY (SS0_2023)
%  ========================================================================
if is_reanchor
    Params_Out.Debt_to_GDP_Init         = 0.405;
    Params_Out.tau_l                    = 0.220;
    Params_Out.tau_k                    = 0.250;
    Params_Out.tau_a                    = 0.000;
    Params_Out.tau_b                    = 0.000;
    Params_Out.lambda_col               = 1.800;
    Params_Out.V_Abroad_SkillPrem_Shift = 0.000;

    Params_Out.upsilon_h                = 0.0095;
    Params_Out.mu_maint_base            = 0.0400;
    Params_Out.mu_rates_wedge_vec       = [0.0, 0.0, 0.0, 0.0];
    Params_Out.Q_k_vec                  = [1.03, 1.37, 2.00, 3.02];
    Params_Out.Q_reg_base_vec           = [1.03, 1.37, 2.00, 3.02];
    Params_Out.w_k_vec                  = [0.85, 0.93, 1.05, 1.18];
    Params_Out.ebar_k_vec               = [0.048, 0.036, 0.022, 0.016];
    Params_Out.sj_base                  = Params_Out.sj;

    Params_Out.G_ECE_1                  = 0.045;
    Params_Out.G_ECE_2                  = 0.065;
    Params_Out.gbar_ece                 = 0.020;
    Params_Out.YouthGrant               = 0.030;
    Params_Out.M_mentor                 = 0.150;
    Params_Out.nu_kaiako                = 0.350;
    Params_Out.alpha_I                  = 0.090;
    Params_Out.delta_hc_mult            = 1.000;

    Params_Out.z_f_Rural                = [0.70, 1.15];
    Params_Out.z_f_Small                = [0.75, 1.28];
    Params_Out.z_f_Large                = [0.83, 1.50];
    Params_Out.z_f_Auckland             = [0.90, 1.75];

    [Params_Out, BundleMeta, z_grid_Out] = sync_and_diagnose(Params_Out, Regions, BundleMeta, z_grid_Out, true);
    return;
end

%% ========================================================================
%  EVALUATE SIGNED COMMITMENT IMPULSES (SYMMETRIC FOR u > 0 AND u < 0!)
%  Note: let q_i = -eff_u(i) for public commitments where 2024-26 was u < 0,
%  so u_i = -1 reproduces the exact calibrated contraction and u_i = +1
%  cleanly reverses the sign into a symmetric institutional strengthening!
%  ========================================================================

% C01: Tenure Tax Neutrality (u > 0 strengthens owner-occupier neutrality & cools Q_k; u < 0 restores landlord deductibility)
u01 = Eff.C01_tenure_tax_neutrality;
if abs(u01) > 0
    Params_Out.upsilon_h         = get_def(Params_Out, 'upsilon_h', 0.0095) + u01 * 0.0035;
    Q_curr                       = get_def(Params_Out, 'Q_k_vec', [1.03, 1.37, 2.00, 3.02]);
    Params_Out.Q_k_vec           = Q_curr .* max(0.50, 1.0 - u01 * [0.025, 0.035, 0.052, 0.068]);
    Params_Out.z_l_subsidy_wedge = get_def(Params_Out, 'z_l_subsidy_wedge', 0.0) - u01 * 0.045;
    Params_Out.Debt_to_GDP_Init  = get_def(Params_Out, 'Debt_to_GDP_Init', 0.405) - u01 * 0.007;
end

% C02: Public R&D & Science Capacity (u > 0 lifts z_h & retains STEM talent; u < 0 winds down Callaghan/Marsden)
u02 = Eff.C02_public_rd_and_science_capacity;
if abs(u02) > 0
    zh_mult_sci = max(0.50, 1.0 + u02 * [0.015, 0.025, 0.075, 0.068]);
    zl_mult_lnd = max(0.50, 1.0 - u02 * [0.020, 0.025, 0.035, 0.045]);
    zf_R = get_def(Params_Out, 'z_f_Rural',    [0.70, 1.15]);
    zf_S = get_def(Params_Out, 'z_f_Small',    [0.75, 1.28]);
    zf_L = get_def(Params_Out, 'z_f_Large',    [0.83, 1.50]);
    zf_A = get_def(Params_Out, 'z_f_Auckland', [0.90, 1.75]);
    Params_Out.z_f_Rural    = [zf_R(1)*zl_mult_lnd(1), zf_R(2)*zh_mult_sci(1)];
    Params_Out.z_f_Small    = [zf_S(1)*zl_mult_lnd(2), zf_S(2)*zh_mult_sci(2)];
    Params_Out.z_f_Large    = [zf_L(1)*zl_mult_lnd(3), zf_L(2)*zh_mult_sci(3)];
    Params_Out.z_f_Auckland = [zf_A(1)*zl_mult_lnd(4), zf_A(2)*zh_mult_sci(4)];
    Params_Out.V_Abroad_SkillPrem_Shift = get_def(Params_Out, 'V_Abroad_SkillPrem_Shift', 0.0) - u02 * 0.085;
end

% C03: Core Public Service Workforce (u > 0 stabilizes metro earnings risk; u < 0 raises downward z hazard in Large/Auckland)
u03 = Eff.C03_core_public_service_workforce;
if abs(u03) > 0
    hazard_shift_vec = (-u03) * [0.004, 0.008, 0.028, 0.015];
    for r_idx = 1:numel(Regions)
        hh_type = ['HH_', Regions{r_idx}];
        if isstruct(pi_z_Out) && isfield(pi_z_Out, hh_type)
            P_mat = pi_z_Out.(hh_type);
            sh    = hazard_shift_vec(r_idx);
            nz_r  = size(P_mat, 2);
            if nz_r >= 4
                P_mat(:, 1)      = max(1e-5, P_mat(:, 1) + 0.45 * sh);
                P_mat(:, 2)      = max(1e-5, P_mat(:, 2) + 0.55 * sh);
                P_mat(:, 3:nz_r) = max(1e-5, P_mat(:, 3:nz_r) - sh / (nz_r - 2));
                P_mat            = P_mat ./ sum(P_mat, 2);
                pi_z_Out.(hh_type) = P_mat;
            end
        end
    end
    Params_Out.psi_unemp_adol = get_def(Params_Out, 'psi_unemp_adol', 0.220) * max(0.40, 1.0 - u03 * 0.15);
end

% C04: Inter-Island Rail-Ferry Corridor (u > 0 lowers freight ebar_k & lifts regional tradable w_k; u < 0 cancels iReX)
u04 = Eff.C04_interisland_rail_ferry_corridor;
if abs(u04) > 0
    Params_Out.Debt_to_GDP_Init = get_def(Params_Out, 'Debt_to_GDP_Init', 0.405) - min(0, u04) * 0.0035;
    ebar_curr                   = get_def(Params_Out, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
    Params_Out.ebar_k_vec       = ebar_curr .* max(0.50, 1.0 - u04 * [0.065, 0.055, 0.040, 0.015]);
    w_curr                      = get_def(Params_Out, 'w_k_vec', [0.85, 0.93, 1.05, 1.18]);
    Params_Out.w_k_vec          = w_curr .* max(0.50, 1.0 + u04 * [0.011, 0.009, 0.008, 0.002]);
end

% C05: Acute Hospital & Clinical Capacity (u > 0 lowers delta_hc & out-of-pocket medical drag; u < 0 defers Dunedin/Health NZ)
u05 = Eff.C05_acute_hospital_and_clinical_capacity;
if abs(u05) > 0
    Params_Out.delta_hc_mult          = get_def(Params_Out, 'delta_hc_mult', 1.000) * max(0.60, 1.0 - u05 * 0.085);
    Params_Out.Exit2_Hosp_Mult        = get_def(Params_Out, 'Exit2_Hosp_Mult', 1.00) * max(0.50, 1.0 - u05 * 0.140);
    Params_Out.G_Health_Regional_Drag = (-u05) * [0.0012, 0.0010, 0.0018, 0.0008];
    ebar_curr                         = get_def(Params_Out, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
    Params_Out.ebar_k_vec             = max(0.004, ebar_curr + Params_Out.G_Health_Regional_Drag);
end

% C06: Early-Years Wraparound, OT Prevention & Care Pay Equity (u > 0 expands G_ECE_1/2 & M_mentor; u < 0 repeals claims/contracts)
u06 = Eff.C06_early_years_and_care_pay_equity;
if abs(u06) > 0
    Params_Out.G_ECE_1  = get_def(Params_Out, 'G_ECE_1', 0.045)  * max(0.25, 1.0 + u06 * 0.220);
    Params_Out.G_ECE_2  = get_def(Params_Out, 'G_ECE_2', 0.065)  * max(0.25, 1.0 + u06 * 0.160);
    Params_Out.gbar_ece = get_def(Params_Out, 'gbar_ece', 0.020) * max(0.20, 1.0 - u06 * 0.200);
    Params_Out.M_mentor = get_def(Params_Out, 'M_mentor', 0.150) * max(0.20, 1.0 + u06 * 0.250);
    w_curr              = get_def(Params_Out, 'w_k_vec', [0.85, 0.93, 1.05, 1.18]);
    Params_Out.w_k_vec  = w_curr .* max(0.50, 1.0 + u06 * [0.006, 0.010, 0.012, 0.008]);
end

% C07: Tertiary Access & Adult Upskilling (u > 0 expands YouthGrant & alpha_I; u < 0 repeals first-year Fees-Free)
u07 = Eff.C07_tertiary_access_and_adult_upskilling;
if abs(u07) > 0
    Params_Out.YouthGrant = get_def(Params_Out, 'YouthGrant', 0.030) * max(0.15, 1.0 + u07 * 0.350);
    Params_Out.alpha_I    = get_def(Params_Out, 'alpha_I', 0.090)    * max(0.30, 1.0 + u07 * 0.075);
end

% C08: Smokefree Public Health Excise (u > 0 lifts retiree survival sj; u < 0 freezes tobacco/halves HTP excise)
u08 = Eff.C08_smokefree_public_health_excise;
if abs(u08) > 0
    Params_Out.Exit2_Hosp_Mult       = get_def(Params_Out, 'Exit2_Hosp_Mult', 1.00) * max(0.50, 1.0 - u08 * 0.045);
    Params_Out.Senescence_Morbid_Add = max(-0.02, get_def(Params_Out, 'Senescence_Morbid_Add', 0.0) - u08 * 0.008);
    sj_ref           = get_def(Params_Out, 'sj_base', Params_Out.sj);
    sj_new           = sj_ref;
    ret_span         = max(1, round(Params_Out.Jr)) : (Params_Out.J - 1);
    sj_new(ret_span) = min(0.995, max(0.05, sj_ref(ret_span) .* (max(0.50, 1.0 + u08 * 0.008) ^ scale_dt)));
    Params_Out.sj    = sj_new;
end

% C09: Working-Age Tax Threshold Relief (Convention 2: u > 0 cuts tau_l by -1.2pp & adds +2.4% GDP debt unless funded)
u09 = Eff.C09_working_age_tax_threshold_relief;
if abs(u09) > 0
    Params_Out.tau_l            = max(0.05, get_def(Params_Out, 'tau_l', 0.220) - u09 * 0.012);
    Params_Out.Debt_to_GDP_Init = get_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + u09 * 0.024;
end

% C10: Investor Visa Capital Inflow (Convention 2: u > 0 lifts lambda_col & metro z_h while bidding up luxury Q_k)
u10 = Eff.C10_investor_visa_capital_inflow;
if abs(u10) > 0
    Params_Out.lambda_col      = max(1.10, get_def(Params_Out, 'lambda_col', 1.800) + u10 * 0.045);
    Q_curr                     = get_def(Params_Out, 'Q_k_vec', [1.03, 1.37, 2.00, 3.02]);
    Params_Out.Q_k_vec         = Q_curr .* max(0.50, 1.0 + u10 * [0.012, 0.010, 0.008, 0.018]);
    zf_L = get_def(Params_Out, 'z_f_Large',    [0.83, 1.50]);
    zf_A = get_def(Params_Out, 'z_f_Auckland', [0.90, 1.75]);
    Params_Out.z_f_Large(2)    = zf_L(2) * max(0.50, 1.0 + u10 * 0.012);
    Params_Out.z_f_Auckland(2) = zf_A(2) * max(0.50, 1.0 + u10 * 0.018);
end

% C11: Accelerated Business Asset Expensing (Convention 2: u > 0 lowers effective corporate tau_k by -2.2pp, +1.1% GDP debt)
u11 = Eff.C11_accelerated_business_asset_expensing;
if abs(u11) > 0
    Params_Out.tau_k            = max(0.05, get_def(Params_Out, 'tau_k', 0.250) - u11 * 0.022);
    Params_Out.Debt_to_GDP_Init = get_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + u11 * 0.011;
end

% C12: Educator Real Remuneration Parity (u > 0 retains kaiako/teachers; u < 0 sub-CPI settlement & trans-Tasman exit)
u12 = Eff.C12_educator_real_remuneration_parity;
if abs(u12) > 0
    Params_Out.G_ECE_1                  = get_def(Params_Out, 'G_ECE_1', 0.045) * max(0.30, 1.0 + u12 * 0.065);
    Params_Out.G_ECE_2                  = get_def(Params_Out, 'G_ECE_2', 0.065) * max(0.30, 1.0 + u12 * 0.080);
    Params_Out.V_Abroad_SkillPrem_Shift = get_def(Params_Out, 'V_Abroad_SkillPrem_Shift', 0.0) - u12 * 0.025;
end

% C13: Retirement Match & Social Rent Buffer (u > 0 protects KiwiSaver match & 25% IRR; u < 0 halves match & lifts IRR to 30%)
u13 = Eff.C13_retirement_match_and_social_rent_buffer;
if abs(u13) > 0
    Params_Out.YouthGrant = get_def(Params_Out, 'YouthGrant', 0.030) * max(0.20, 1.0 + u13 * 0.150);
    Params_Out.gbar_ece   = get_def(Params_Out, 'gbar_ece', 0.020)   * max(0.20, 1.0 - u13 * 0.085);
end

% C14: National Water Balance-Sheet Stewardship (u > 0 relieves municipal pipe rates; u < 0 devolves NZD 7B-10B onto rates)
u14 = Eff.C14_national_water_balance_sheet_stewardship;
if abs(u14) > 0
    wedge_curr = get_def(Params_Out, 'mu_rates_wedge_vec', [0.0, 0.0, 0.0, 0.0]);
    Params_Out.mu_rates_wedge_vec = max(-0.02, wedge_curr - u14 * [0.0022, 0.0030, 0.0042, 0.0026]);
end

% C15: Grassroots Arts, Sport & Civic Commons (TWO-SIDED! u = +1.0 -> Doc 1E Joiner Passport; u = -1.0 -> 2024-26 Civic Squeeze)
u15 = Eff.C15_grassroots_arts_sport_and_civic_commons;
if abs(u15) > 0
    % Notice regional weights flip cleanly from urban/WCC acute squeeze at u < 0 to nationwide Joiner Passport at u > 0:
    if u15 < 0
        q_cut        = -u15;
        reg_civic_wt = [0.75, 0.85, 2.10, 1.35];
        Params_Out.Debt_to_GDP_Init      = get_def(Params_Out, 'Debt_to_GDP_Init', 0.405) - q_cut * 0.0004;
        Params_Out.G_ECE_2               = get_def(Params_Out, 'G_ECE_2', 0.065) * max(0.30, 1.0 - q_cut * 0.038);
        lam_curr                         = get_def(Params_Out, 'lambda_psy_vec', [0.38, 0.38, 0.38, 0.38]);
        Params_Out.lambda_psy_vec        = min(0.65, lam_curr .* (1.0 + q_cut * 0.085 * reg_civic_wt));
        club_curr                        = get_def(Params_Out, 'psi_club_buffer_vec', [1.0, 1.0, 1.0, 1.0]);
        Params_Out.psi_club_buffer_vec   = club_curr .* max(0.50, 1.0 - q_cut * 0.065 * [1.15, 1.10, 1.45, 0.95]);
        zh_curr                          = get_def(Params_Out, 'Z_h_reg_mult', [1.0, 1.0, 1.0, 1.0]);
        Params_Out.Z_h_reg_mult          = zh_curr .* max(0.60, 1.0 - q_cut * 0.011 * reg_civic_wt);
        v_abr_curr                       = get_def(Params_Out, 'V_Abroad_Reg_Shift', [0.0, 0.0, 0.0, 0.0]);
        Params_Out.V_Abroad_Reg_Shift    = v_abr_curr + q_cut * 0.018 * reg_civic_wt;
        Params_Out.Civic_Hysteresis_Mult = 1.08;
        Params_Out.Cohesion_Shock_Pts    = get_def(Params_Out, 'Cohesion_Shock_Pts', 0.0) - q_cut * 4.80;
    else
        % Positive Document 1E Co-Investment (Universal NZD 500/yr Joiner Passport + Creative Tuakana + Meanwhile Space):
        reg_pos_wt   = [1.05, 1.08, 1.18, 1.20];
        Params_Out.Civic_Commitment_Scale = u15;
        Params_Out.Enable_Arts_Civic      = true;
        Params_Out.Debt_to_GDP_Init       = get_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + u15 * 0.00077; % NZD 0.33B/yr seed
        Params_Out.G_ECE_2                = get_def(Params_Out, 'G_ECE_2', 0.065) * (1.0 + u15 * 0.075);
        lam_curr                          = get_def(Params_Out, 'lambda_psy_vec', [0.38, 0.38, 0.38, 0.38]);
        Params_Out.lambda_psy_vec         = max(0.16, lam_curr .* (1.0 - u15 * 0.160 * reg_pos_wt));
        club_curr                         = get_def(Params_Out, 'psi_club_buffer_vec', [1.0, 1.0, 1.0, 1.0]);
        Params_Out.psi_club_buffer_vec    = club_curr .* (1.0 + u15 * 0.125 * [1.22, 1.18, 1.06, 1.02]); % Rural/Small Join-or-Die lift!
        zh_curr                           = get_def(Params_Out, 'Z_h_reg_mult', [1.0, 1.0, 1.0, 1.0]);
        Params_Out.Z_h_reg_mult           = zh_curr .* (1.0 + u15 * 0.020 * [0.85, 0.95, 1.25, 1.28]);   % Metro creative z_h IP lift!
        v_abr_curr                        = get_def(Params_Out, 'V_Abroad_Reg_Shift', [0.0, 0.0, 0.0, 0.0]);
        Params_Out.V_Abroad_Reg_Shift     = v_abr_curr - u15 * 0.032 * [0.80, 0.90, 1.30, 1.25];          % Curbs creative brain drain!
        Params_Out.Cohesion_Shock_Pts     = get_def(Params_Out, 'Cohesion_Shock_Pts', 0.0) + u15 * 8.50;  % 126.0 -> 134.5 lift!
    end
end

% C16: Paris NDC & Clean Exergy Transition (TWO-SIDED! u < 0 = TP 26/01 NDC shortfall + EV repeal; u > 0 = CERF electrification + Clean-Green)
if isfield(Eff, 'C16_paris_ndc_and_clean_energy_transition')
    u16 = Eff.C16_paris_ndc_and_clean_energy_transition;
    if u16 < 0
        q_ndc    = -u16;
        ndc_mode = lower(strtrim(char(get_opt(Opts, 'NDC_Settlement_Mode', 'hybrid'))));
        w_pay    = double(strcmp(ndc_mode, 'offshore_pay')) + 0.5 * double(strcmp(ndc_mode, 'hybrid'));
        w_def    = double(strcmp(ndc_mode, 'default_fta_penalty')) + 0.5 * double(strcmp(ndc_mode, 'hybrid'));

        Params_Out.eps_h_energy            = max(0.15, get_def(Params_Out, 'eps_h_energy', 0.350) - q_ndc * 0.120);
        ebar_curr                          = get_def(Params_Out, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
        Params_Out.ebar_k_vec              = ebar_curr .* (1.0 + q_ndc * [0.065, 0.052, 0.030, 0.022]);
        Params_Out.Debt_to_GDP_Init        = get_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + q_ndc * w_pay * 0.0185;
        Params_Out.Offshore_NDC_Drain_BNZD = get_def(Params_Out, 'Offshore_NDC_Drain_BNZD', 0.0) + q_ndc * w_pay * 1.45;
        zh_curr                            = get_def(Params_Out, 'Z_h_reg_mult', [1.0, 1.0, 1.0, 1.0]);
        Params_Out.Z_h_reg_mult            = zh_curr .* max(0.60, 1.0 - q_ndc * w_def * [0.034, 0.024, 0.008, 0.006]);
        Params_Out.r_sov_spread            = get_def(Params_Out, 'r_sov_spread', 0.0) + q_ndc * w_def * 0.0022;
        Params_Out.tau_l                   = get_def(Params_Out, 'tau_l', 0.220) ...
            + 0.0025 * (Params_Out.Offshore_NDC_Drain_BNZD / 0.725) + 0.80 * Params_Out.r_sov_spread;
    elseif u16 > 0
        % Positive Keen-Labrousse Electrification (e_F=0.30 -> e_N=0.88) + Clean-Green Primary Export Lift:
        Params_Out.eps_h_energy       = min(0.95, get_def(Params_Out, 'eps_h_energy', 0.350) + u16 * 0.300);
        ebar_curr                     = get_def(Params_Out, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
        Params_Out.ebar_k_vec         = ebar_curr .* max(0.45, 1.0 - u16 * [0.220, 0.190, 0.140, 0.110]);
        zh_curr                       = get_def(Params_Out, 'Z_h_reg_mult', [1.0, 1.0, 1.0, 1.0]);
        Params_Out.Z_h_reg_mult       = zh_curr .* (1.0 + u16 * [0.045, 0.030, 0.012, 0.008]);
        Params_Out.r_sov_spread       = max(-0.006, get_def(Params_Out, 'r_sov_spread', 0.0) - u16 * 0.0015);
        Params_Out.Clean_Exergy_Scale = u16;
    end
end

% C17: Public Network & Grid Asset Stewardship (TWO-SIDED! u < 0 = irreversible privatization into monopoly; u > 0 = Ostrom/board turnaround)
if isfield(Eff, 'C17_public_network_asset_stewardship')
    u17 = Eff.C17_public_network_asset_stewardship;
    Params_Out.Asset_Stewardship_Dial = u17;
    if u17 < 0
        q_priv = -u17;
        % One-off fire-sale cash lowers initial net debt slightly (-1.8% GDP), BUT locks in permanent monopoly
        % tariff/electricity markups (+ebar_k, +mu_rates_wedge) and lowers downstream firm z_h competitiveness:
        Params_Out.Debt_to_GDP_Init   = get_def(Params_Out, 'Debt_to_GDP_Init', 0.405) - q_priv * 0.018;
        ebar_curr                     = get_def(Params_Out, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
        Params_Out.ebar_k_vec         = ebar_curr .* (1.0 + q_priv * [0.140, 0.125, 0.105, 0.095]);
        wedge_curr                    = get_def(Params_Out, 'mu_rates_wedge_vec', [0.0, 0.0, 0.0, 0.0]);
        Params_Out.mu_rates_wedge_vec = wedge_curr + q_priv * [0.0028, 0.0032, 0.0038, 0.0034];
        zh_curr                       = get_def(Params_Out, 'Z_h_reg_mult', [1.0, 1.0, 1.0, 1.0]);
        Params_Out.Z_h_reg_mult       = zh_curr .* max(0.65, 1.0 - q_priv * [0.028, 0.026, 0.024, 0.022]);
        Params_Out.Cohesion_Shock_Pts = get_def(Params_Out, 'Cohesion_Shock_Pts', 0.0) - q_priv * 3.20;
    elseif u17 > 0
        % Reforming public network & gentailer governance compresses oligopoly markups & lifts network reliability:
        ebar_curr                     = get_def(Params_Out, 'ebar_k_vec', [0.048, 0.036, 0.022, 0.016]);
        Params_Out.ebar_k_vec         = ebar_curr .* max(0.55, 1.0 - u17 * [0.085, 0.080, 0.070, 0.065]);
        wedge_curr                    = get_def(Params_Out, 'mu_rates_wedge_vec', [0.0, 0.0, 0.0, 0.0]);
        Params_Out.mu_rates_wedge_vec = max(-0.015, wedge_curr - u17 * [0.0018, 0.0020, 0.0024, 0.0020]);
        zh_curr                       = get_def(Params_Out, 'Z_h_reg_mult', [1.0, 1.0, 1.0, 1.0]);
        Params_Out.Z_h_reg_mult       = zh_curr .* (1.0 + u17 * [0.022, 0.020, 0.018, 0.016]);
        Params_Out.Cohesion_Shock_Pts = get_def(Params_Out, 'Cohesion_Shock_Pts', 0.0) + u17 * 2.40;
    end
end

% C18: Sovereign Defence Capability Posture (u = +1.0 -> 1.2% to 3.0% GDP = +NZD 8.0B/yr FX & skill demand)
if isfield(Eff, 'C18_sovereign_defence_capability_posture')
    u18 = Eff.C18_sovereign_defence_capability_posture;
    if abs(u18) > 0
        Params_Out.Defence_Posture_Dial = u18;
        Params_Out.Defence_PctGDP       = max(0.005, 0.012 + u18 * 0.018);
        % Unfunded defence import drain (+62% FX share) widens NFA/sovereign spread & requires PAYE closure unless offset:
        has_clean_offset = get_def(Params_Out, 'Clean_Exergy_Scale', 0.0);
        net_fx_strain    = max(0.0, u18 * (1.0 - 0.65 * has_clean_offset));
        Params_Out.Debt_to_GDP_Init = get_def(Params_Out, 'Debt_to_GDP_Init', 0.405) + net_fx_strain * 0.028;
        Params_Out.r_sov_spread     = get_def(Params_Out, 'r_sov_spread', 0.0) + net_fx_strain * 0.0018;
        Params_Out.tau_l            = max(0.05, get_def(Params_Out, 'tau_l', 0.220) + u18 * 0.0175 - 0.0040 * has_clean_offset);
    end
end

[Params_Out, BundleMeta, z_grid_Out] = sync_and_diagnose(Params_Out, Regions, BundleMeta, z_grid_Out, false);

end

%% ========================================================================
%  DIAL RESOLVER (SUPPORTS COMPOSING ARRAYS OF BUNDLES + CUSTOM STRUCTS)
%  ========================================================================
function [u_vec, is_reanchor, lbl] = resolve_dial_vector(Spec, Catalog, Opts)
CIDs        = Catalog.Commitment_IDs;
nC          = numel(CIDs);
u_vec       = zeros(nC, 1);
is_reanchor = false;

if iscell(Spec)
    parts = cell(1, numel(Spec));
    for k = 1:numel(Spec)
        [uk, rk, lk] = resolve_dial_vector(Spec{k}, Catalog, struct());
        u_vec       = u_vec + uk;
        is_reanchor = is_reanchor || rk;
        parts{k}    = lk;
    end
    lbl = strjoin(parts, ' + ');
elseif isstruct(Spec)
    lbl = 'Custom_Commitment_Vector';
    for i = 1:nC
        cid = CIDs{i};
        if isfield(Spec, cid) && ~isempty(Spec.(cid))
            u_vec(i) = double(Spec.(cid));
        end
    end
else
    name_in = strtrim(char(Spec));
    b_name  = map_alias_to_bundle(name_in, Catalog.Bundles);
    if strcmpi(b_name, 'custom')
        lbl = 'Custom_Legacy_Opts';
        u_vec = map_legacy_bool_opts(Opts, CIDs);
        return;
    end
    cid_idx = find(strcmpi(CIDs, b_name), 1);
    if ~isempty(cid_idx)
        u_vec(cid_idx) = 1.0;
        lbl = CIDs{cid_idx};
        return;
    end
    if ~isfield(Catalog.Bundles, b_name)
        error('IGWelfare:UnknownPolicyBundle', 'Unknown policy bundle or commitment ID: "%s".', name_in);
    end
    B = Catalog.Bundles.(b_name);
    if isfield(B, 'Label'), lbl = B.Label; else, lbl = b_name; end
    if isfield(B, 'Reanchor_2023') && logical(B.Reanchor_2023)
        is_reanchor = true;
        return;
    end
    for i = 1:nC
        cid = CIDs{i};
        if isfield(B, cid) && ~isempty(B.(cid))
            u_vec(i) = double(B.(cid));
        end
    end
end

% Allow explicit per-commitment dial overrides on Opts.Dials:
if isfield(Opts, 'Dials') && isstruct(Opts.Dials)
    for i = 1:nC
        cid = CIDs{i};
        if isfield(Opts.Dials, cid) && ~isempty(Opts.Dials.(cid))
            u_vec(i) = double(Opts.Dials.(cid));
        end
    end
end

% Allow isolating any single shock or subset of a bundle via Opts.ActiveIdx / Opts.ActiveCIDs:
if isfield(Opts, 'ActiveIdx') && ~isempty(Opts.ActiveIdx)
    keep_mask = false(nC, 1);
    keep_mask(Opts.ActiveIdx(:)) = true;
    u_vec(~keep_mask) = 0.0;
    active_tags = regexp(CIDs(keep_mask), '^C\d+', 'match', 'once');
    lbl = sprintf('%s [%s]', lbl, strjoin(active_tags(:)', '+'));
end
end

function b_name = map_alias_to_bundle(name_in, Bundles)
if isfield(Bundles, name_in)
    b_name = name_in;
    return;
end
low = lower(name_in);
switch low
    case {'reanchor_2023', 'ss0_2023'}
        b_name = 'baseline_2023';
    case {'austerity_landlord_only', 'retrenchment_only'}
        b_name = 'retrenchment_and_tenure_10';
    case {'pro_growth_only', 'tax_and_capital_relief'}
        b_name = 'tax_visa_expensing_3';
    case {'first_13_shocks', 'coalition_13_shocks', 'full_13_shocks', 'apply_coalition_shocks'}
        b_name = 'combined_13_commitments';
    case {'rates_cap_3_waters'}
        b_name = 'water_stewardship_shift';
    case {'arts_and_civic_cuts'}
        b_name = 'civic_commons_contraction';
    case {'arts_and_civic_investment', 'doc1e_civic'}
        b_name = 'civic_commons_expansion_doc1e';
    case {'all_but_ndc', 'full_15_shocks'}
        b_name = 'domestic_15_bundle';
    case 'ndc'
        b_name = 'ndc_clean_energy_rollback';
    case {'ndc_clean_green', 'cerf_ndc_upgrade'}
        b_name = 'ndc_clean_exergy_upgrade';
    case 'full_16_shocks'
        b_name = 'full_16_commitments';
    case 'custom'
        b_name = 'custom';
    otherwise
        % Also allow passing a single Commitment_ID directly (defaults to u = +1.0)!
        b_name = name_in;
end
end

function u_vec = map_legacy_bool_opts(Opts, CIDs)
u_vec = zeros(numel(CIDs), 1);
legacy_map = { ...
    'LandlordTaxBreak',        1, -1.0; ...
    'ScienceCallaghanCuts',    2, -1.0; ...
    'PublicSectorLayoffs',     3, -1.0; ...
    'CancelFerriesPorts',      4, -1.0; ...
    'DunedinHospitalDelays',   5, -1.0; ...
    'CancelPayEquity_OT_ECE',  6, -1.0; ...
    'TertiaryFeesFreeCut',     7, -1.0; ...
    'TobaccoTaxFreeze',        8, -1.0; ...
    'IncomeTaxBracketCut',     9, +1.0; ...
    'ActiveInvestorVisa',     10, +1.0; ...
    'InvestmentBoost20Pct',   11, +1.0; ...
    'TeacherKaiakoPaySqueeze',12, -1.0; ...
    'KiwiSaverMatchCut',      13, -1.0; ...
    'ThreeWatersRatesWedge',           14, -1.0; ...
    'ArtsCivicWCCSqueeze',             15, -1.0; ...
    'ParisNDCLiabilityAndEVRollback',  16, -1.0};
for r = 1:size(legacy_map, 1)
    fn = legacy_map{r, 1};
    ix = legacy_map{r, 2};
    sg = legacy_map{r, 3};
    if isfield(Opts, fn) && ~isempty(Opts.(fn))
        u_vec(ix) = sg * double(Opts.(fn));
    end
end
end

%% ========================================================================
%  CROSS-COMMITMENT COUPLING & COHESION DIAGNOSTICS
%  ========================================================================
function [P, Meta, z_grid_Out] = sync_and_diagnose(P, Regions, Meta, z_grid_Out, is_reanchor)
HH_Names   = strcat('HH_',   Regions);
Firm_Names = strcat('Firm_', Regions);
dt_val     = get_def(P, 'dt', 3);
scale_dt   = dt_val / 5.0;

w_hh_row = P.Pop_Weights_4(:)' / sum(P.Pop_Weights_4);
w_hh_col = w_hh_row(:);

if isfield(P, 'Q_reg_base_vec') && ~isempty(P.Q_reg_base_vec)
    Q_base_row = P.Q_reg_base_vec(:)';
else
    Q_base_row = ptype_to_row(get_def(P, 'Q_reg_base', struct()), HH_Names, [1.03, 1.37, 2.00, 3.02]);
end
Q_now_row = get_def(P, 'Q_k_vec', ptype_to_row(get_def(P, 'Q_reg', struct()), HH_Names, Q_base_row));
nu_k      = get_def(P, 'nu_kaiako', 0.350);

P.Kaiako_Deflator_Vec = (Q_base_row ./ Q_now_row) .^ nu_k;
P.Kaiako_Deflator     = row_to_ptype(P.Kaiako_Deflator_Vec, HH_Names);

[P, z_grid_Out] = sync_regional_ptypes(P, Regions, HH_Names, Firm_Names, Q_base_row, Q_now_row, scale_dt, z_grid_Out, is_reanchor);

g1_sched0  = P.G_ece1_sched(1);
ygr_sched0 = P.YouthGrant_sched(1);

G1_eff_row = ptype_to_row(P.G_ECE_1_eff,  HH_Names, repmat(g1_sched0, 1, 4));
Q_reg_row  = ptype_to_row(P.Q_reg,        HH_Names, Q_base_row);
v_abr_row  = ptype_to_row(P.V_Abroad_Add, HH_Names, zeros(1, 4));
zh_now_row = cellfun(@(f) P.z_f_grid.(f)(2), Firm_Names);
zh_ref_row = [1.15, 1.28, 1.50, 1.75];

tau_l_now   = get_def(P, 'tau_l', 0.220);
tau_k_now   = get_def(P, 'tau_k', 0.250);
v_abroad_sc = get_def(P, 'V_Abroad_SkillPrem_Shift', 0.0);
y_grant     = get_def(P, 'YouthGrant', ygr_sched0);
coh_direct  = get_def(P, 'Cohesion_Shock_Pts', 0.0);

d_Strug_row = max(-0.205, -0.38 * (G1_eff_row - g1_sched0) ...
    + 0.045 * (Q_reg_row - Q_base_row) ...
    + 0.15  * (tau_l_now - 0.220));

d_Emig_row  = max(-0.050,  0.32  * (v_abroad_sc + v_abr_row) ...
    + 0.042 * (Q_reg_row  - Q_base_row) ...
    - 0.45  * (y_grant    - ygr_sched0) ...
    + 0.35  * (tau_l_now  - 0.220) ...
    + 0.18  * (tau_k_now  - 0.250) ...
    - 0.06  * (zh_now_row - zh_ref_row));
d_Churn_row = max(0.0, 0.65 * d_Emig_row);

base_strug_row = 0.01 * get_def(P, 'base_struggle_vec', [19.8, 18.2, 15.6, 14.3]);
if isfield(P, 'u_target_4x5') && isequal(size(P.u_target_4x5), [4, 5])
    exp_u         = exp(P.u_target_4x5);
    base_emig_row = (exp_u(:, 5) ./ sum(exp_u, 2))';
else
    base_emig_row = [0.018, 0.091, 0.234, 0.070];
end
base_emig_nat  = get_def(P, 'Base_Emig_Share', base_emig_row * w_hh_col);

civic_norm_row = [0.75, 0.85, 2.10, 1.35] / ([0.75, 0.85, 2.10, 1.35] * w_hh_col);
St_reg_row     = 100.0 - 125.0 * d_Strug_row - 160.0 * d_Emig_row - 85.0 * d_Churn_row + coh_direct * civic_norm_row;

Meta.Struggling_By_PType     = row_to_ptype(base_strug_row + d_Strug_row, HH_Names);
Meta.Emig_By_PType           = row_to_ptype(base_emig_row  + d_Emig_row,  HH_Names);
Meta.Cohesion_St_By_PType    = row_to_ptype(St_reg_row,                   HH_Names);
Meta.Frac_Struggling_Imputed = (base_strug_row + d_Strug_row) * w_hh_col;
Meta.Emig_Nat_Imputed        = base_emig_nat + (d_Emig_row * w_hh_col);
Meta.Social_Cohesion_St      = St_reg_row * w_hh_col;
Meta.TI_Social_Credit_CPI    = 81.0 + 0.423 * (Meta.Social_Cohesion_St - 100.0);
end

function [P, z_grid_Out] = sync_regional_ptypes(P, Regions, HH_Names, Firm_Names, Q_base_row, Q_vec, scale_dt, z_grid_Out, is_reanchor)
w_direct_vec = get_def(P, 'w_k_vec',            ptype_to_row(get_def(P, 'w_reg',       struct()), HH_Names, [0.85, 0.93, 1.05, 1.18]));
ebar_vec     = get_def(P, 'ebar_k_vec',         ptype_to_row(get_def(P, 'ebar_energy', struct()), HH_Names, [0.048, 0.036, 0.022, 0.016]));
mu_base      = get_def(P, 'mu_maint_base',      0.0400);
mu_wedge_vec = get_def(P, 'mu_rates_wedge_vec', [0.0, 0.0, 0.0, 0.0]);
k_defl       = get_def(P, 'Kaiako_Deflator_Vec',[1, 1, 1, 1]);
G1_base      = get_def(P, 'G_ECE_1',            P.G_ece1_sched(1));
G2_base      = get_def(P, 'G_ECE_2',            P.G_ece2_sched(1));
zh_reg_mult  = get_def(P, 'Z_h_reg_mult',       [1, 1, 1, 1]);
v_abr_vec    = get_def(P, 'V_Abroad_Reg_Shift', [0, 0, 0, 0]);
lam_psy_vec  = get_def(P, 'lambda_psy_vec',     [0.38, 0.38, 0.38, 0.38]);
club_vec     = get_def(P, 'psi_club_buffer_vec',[1, 1, 1, 1]);

def_zf_mat    = [0.70, 0.75, 0.83, 0.90; 1.15, 1.28, 1.50, 1.75];
zh_ref_vec    = [1.15, 1.28, 1.50, 1.75];
tau_k_delta   = get_def(P, 'tau_k', 0.250)      - 0.250;
lam_col_delta = get_def(P, 'lambda_col', 1.800) - 1.800;
r_spread_ann  = get_def(P, 'r_sov_spread', 0.0);
w_ge_vec      = w_direct_vec;

for k = 1:numel(Regions)
    zf_field = ['z_f_', Regions{k}];
    firm_tp  = Firm_Names{k};
    if isfield(P, zf_field) && numel(P.(zf_field)) >= 2
        zf_pair = P.(zf_field)(:);
    elseif isfield(P, 'z_f_grid') && isfield(P.z_f_grid, firm_tp)
        zf_pair = P.z_f_grid.(firm_tp)(:);
    else
        zf_pair = def_zf_mat(:, k);
    end
    zf_pair(2)           = zf_pair(2) * zh_reg_mult(k);
    P.z_f_grid.(firm_tp) = zf_pair;
    if isstruct(z_grid_Out)
        z_grid_Out.(firm_tp) = zf_pair;
    end
    if ~is_reanchor
        d_ln_zh     = (zf_pair(2) - zh_ref_vec(k)) / zh_ref_vec(k);
        ge_cap_lift = -0.28 * tau_k_delta + 0.08 * lam_col_delta - 1.20 * r_spread_ann;
        ge_tfp_lift = 0.45 * d_ln_zh;
        w_ge_vec(k) = w_direct_vec(k) * (1.0 + ge_cap_lift + ge_tfp_lift);
    end
end

P.Q_reg_base      = row_to_ptype(Q_base_row,             HH_Names);
P.Q_reg           = row_to_ptype(Q_vec,                  HH_Names);
P.w_reg           = row_to_ptype(w_ge_vec,               HH_Names, Firm_Names);
P.ebar_energy     = row_to_ptype(ebar_vec,               HH_Names);
P.mu_maint        = row_to_ptype(mu_base + mu_wedge_vec, HH_Names);
P.upsilon_h_reg   = row_to_ptype(repmat(get_def(P, 'upsilon_h', 0.0095), 1, numel(Regions)), HH_Names);
P.gbar_ece        = get_def(P, 'gbar_ece', 0.020);
P.gbar_ECE        = P.gbar_ece;

% Provide both scalar and PType views safely:
P.G_ece_stage1    = row_to_ptype(repmat(G1_base, 1, numel(Regions)), HH_Names);
P.G_ece_stage2    = row_to_ptype(repmat(G2_base, 1, numel(Regions)), HH_Names);
P.G_ece           = P.G_ece_stage1;
P.G_ECE_1_eff     = row_to_ptype(G1_base * k_defl, HH_Names);
P.G_ECE_2_eff     = row_to_ptype(G2_base * k_defl, HH_Names);

P.V_Abroad_Add    = row_to_ptype(v_abr_vec,   HH_Names);
P.lambda_psy      = row_to_ptype(lam_psy_vec, HH_Names);
P.psi_club_buffer = row_to_ptype(club_vec,    HH_Names);

hc_mult    = get_def(P, 'delta_hc_mult', 1.000);
P.delta_hc = 1 - (1 - min(0.45, 0.087 * hc_mult)) ^ scale_dt;

super_age_eff   = 20 + (P.Jr - 1) * P.dt;
elder_time_mult = exp(-P.eta_elder_whanau * max(0, super_age_eff - 65));
for k = 1:numel(Regions)
    hh_tp           = HH_Names{k};
    elder_home_mult = min(1.15, max(0.50, (P.p_super / 0.18) * ((Q_base_row(k) / Q_vec(k)) ^ 0.35)));
    club_mult       = 1.0;
    if ~is_reanchor
        club_mult = club_vec(k);
    end
    P.K_whanau.(hh_tp) = P.K_whanau_base.(hh_tp) * elder_time_mult * elder_home_mult * club_mult;
end
end

function val = get_opt(S, fname, defval)
if isstruct(S) && isfield(S, fname) && ~isempty(S.(fname))
    val = S.(fname);
else
    val = defval;
end
end

function val = get_def(S, fname, defval)
if isstruct(S) && isfield(S, fname) && ~isempty(S.(fname))
    val = S.(fname);
else
    val = defval;
end
end

function row_vec = ptype_to_row(S, FieldNames, def_row)
if isstruct(S) && all(isfield(S, FieldNames))
    row_vec = cellfun(@(f) S.(f), FieldNames);
    row_vec = row_vec(:)';
else
    row_vec = def_row(:)';
end
end

function S = row_to_ptype(row_vec, PrimaryNames, SecondaryNames)
S = cell2struct(num2cell(row_vec(:)'), PrimaryNames, 2);
if nargin >= 3 && ~isempty(SecondaryNames)
    for k = 1:numel(SecondaryNames)
        S.(SecondaryNames{k}) = row_vec(k);
    end
end
end
