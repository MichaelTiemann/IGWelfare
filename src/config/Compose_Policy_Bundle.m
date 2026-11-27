function [Params_Out, pi_z_Out, BundleMeta, z_grid_Out] = Compose_Policy_Bundle(Params_In, pi_z_In, BundleSpecOrName, Opts, z_grid_In)
%% COMPOSITIONAL POLICY ALGEBRA OVER ONGOING INSTITUTIONAL COMMITMENTS (CONVENTION 2)
% File: src/config/Compose_Policy_Bundle.m
% Maps any named bundle, legacy preset alias, signed set expression, or arbitrary
% vector/struct of signed institutional commitment dials u_c onto VFI-ready (Params, pi_z, z_grid):
%
%   - Public capability, health, infrastructure & civic commitments (C01..C08, C12..C17):
%       u_c > 0 : Strengthen / invest in commitment (e.g., C15 = +1.0 -> Doc 1E Joiner Passport)
%       u_c < 0 : Retrench / defer commitment       (e.g., C15 = -1.0 -> 2024-26 Arts/WCC pullback)
%   - Tax-relief, investor-visa, expensing & defence levers (C09..C11, C18):
%       u_c > 0 : Enact tax threshold relief / investor inflow / 20% expensing / 3.0% GDP defence
%       u_c < 0 : Tighten tax/depreciation/screening schedule or shift procurement onshore
%   - Constructive SS1 & SS2 Generational Compact Pillars (Sparse Codes C21..C28; C19..C20 & C29+ reserved):
%       u_c > 0 : Activate split SS1/SS2 pillar (C21 First-2000-Days ECE, C22 Tuakana Mentoring,
%                 C23 1.5% Land & 25% Estate Statutory Rebalance, C24 Youth Grant E, C25 Geo Bridge T_k,
%                 C26 Productive z_h Firm Shift, C27 50/50 Debt-Sinking & Infra, C28 PAYE Cut & Super-64 Kuia Care)
%
% Commutative Composition Property:
%   Compose_Policy_Bundle(P0, pi0, {'retrenchment_and_tenure_10', 'tax_visa_expensing_3'})
%   or Compose_Policy_Bundle(P0, pi0, 'hole_ss2') additively sums the underlying sparse
%   commitment dial vectors u = u_A + u_B and accumulates all multiplicative scalings in a
%   commutative product group and all additive wedges in a separate vector sum before applying
%   domain bounds once at closure — guaranteeing zero "last-through-the-door" order dependence
%   while resolving all endogenous cross-gate couplings (Kaiako Q_k deflator, Guvenen w_k MPL
%   pass-through, K_whanau club/elder buffering, & 4x5 Gumbel migration sorting) in one pure pass!

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

% 1. Resolve BundleSpecOrName (supports single name, cell array, signed set expression, or custom struct!)
[u_vec, is_reanchor, resolved_label] = resolve_dial_vector(BundleSpecOrName, Catalog, Opts);

% Separate pass-through scales for macro announcement commitments (Code_Nums <= 13) vs direct statutory/SS1/SS2 levers (Code_Nums >= 14)
s_direct  = get_opt(Opts, 'ShockScale',  get_opt(Opts, 'DirectScale', 1.0000));
s_core13  = get_opt(Opts, 'Core13Scale', Catalog.Default_Core13_PassThrough * s_direct);
is_core13 = (Catalog.Code_Nums <= 13);

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
BundleMeta.Code_Nums        = Catalog.Code_Nums;
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
%  STRICTLY COMMUTATIVE ACCUMULATION OVER SPARSE COMMITMENTS (C01..C18, C21..C28)
%  Multiplicative scalings accumulate in product variables (init = 1.0);
%  additive wedges accumulate in sum variables (init = 0.0); bounds apply once at closure!
%  ========================================================================
c2pos = Catalog.Code_To_Pos;
eC    = @(cn) get_eff_by_code(eff_u, c2pos, cn);

% Base incoming anchors (preserving any upstream caller customizations on Params_In):
debt_0    = get_def(Params_Out, 'Debt_to_GDP_Init',         0.405);
tau_l_0   = get_def(Params_Out, 'tau_l',                    0.220);
tau_k_0   = get_def(Params_Out, 'tau_k',                    0.250);
tau_a_0   = get_def(Params_Out, 'tau_a',                    0.000);
tau_b_0   = get_def(Params_Out, 'tau_b',                    0.000);
lam_col_0 = get_def(Params_Out, 'lambda_col',               1.800);
v_abr_s_0 = get_def(Params_Out, 'V_Abroad_SkillPrem_Shift', 0.000);
ups_h_0   = get_def(Params_Out, 'upsilon_h',                0.0095);
zl_sub_0  = get_def(Params_Out, 'z_l_subsidy_wedge',        0.000);
Q_0       = get_def(Params_Out, 'Q_k_vec',                  [1.03, 1.37, 2.00, 3.02]);
w_0       = get_def(Params_Out, 'w_k_vec',                  [0.85, 0.93, 1.05, 1.18]);
ebar_0    = get_def(Params_Out, 'ebar_k_vec',               [0.048, 0.036, 0.022, 0.016]);
mu_wed_0  = get_def(Params_Out, 'mu_rates_wedge_vec',       [0.0, 0.0, 0.0, 0.0]);
sj_ref    = get_def(Params_Out, 'sj_base',                  Params_Out.sj);
G1_0      = get_def(Params_Out, 'G_ECE_1',                  0.045);
G2_0      = get_def(Params_Out, 'G_ECE_2',                  0.065);
gbar_0    = get_def(Params_Out, 'gbar_ece',                 0.020);
yg_0      = get_def(Params_Out, 'YouthGrant',               0.030);
ment_0    = get_def(Params_Out, 'M_mentor',                 0.150);
alpI_0    = get_def(Params_Out, 'alpha_I',                  0.090);
dhc_0     = get_def(Params_Out, 'delta_hc_mult',            1.000);
hosp_0    = get_def(Params_Out, 'Exit2_Hosp_Mult',          1.000);
morb_0    = get_def(Params_Out, 'Senescence_Morbid_Add',    0.000);
adol_0    = get_def(Params_Out, 'psi_unemp_adol',           0.220);
lam_psy_0 = get_def(Params_Out, 'lambda_psy_vec',           [0.38, 0.38, 0.38, 0.38]);
club_0    = get_def(Params_Out, 'psi_club_buffer_vec',      [1.0, 1.0, 1.0, 1.0]);
zh_reg_0  = get_def(Params_Out, 'Z_h_reg_mult',             [1.0, 1.0, 1.0, 1.0]);
v_abr_r_0 = get_def(Params_Out, 'V_Abroad_Reg_Shift',       [0.0, 0.0, 0.0, 0.0]);
coh_0     = get_def(Params_Out, 'Cohesion_Shock_Pts',       0.000);
rspr_0    = get_def(Params_Out, 'r_sov_spread',             0.000);
ndc_dr_0  = get_def(Params_Out, 'Offshore_NDC_Drain_BNZD',  0.000);
eps_e_0   = get_def(Params_Out, 'eps_h_energy',             0.350);

zf_R_0 = get_def(Params_Out, 'z_f_Rural',    [0.70, 1.15]);
zf_S_0 = get_def(Params_Out, 'z_f_Small',    [0.75, 1.28]);
zf_L_0 = get_def(Params_Out, 'z_f_Large',    [0.83, 1.50]);
zf_A_0 = get_def(Params_Out, 'z_f_Auckland', [0.90, 1.75]);

% Commutative sum & product accumulators:
debt_add   = 0.0; tau_l_add  = 0.0; tau_k_add  = 0.0; tau_a_add = 0.0; tau_b_add = 0.0;
lam_add    = 0.0; v_abr_s_add= 0.0; ups_h_add  = 0.0; zl_sub_add = 0.0;
morb_add   = 0.0; coh_add    = 0.0; rspr_add   = 0.0; ndc_add    = 0.0; eps_e_add = 0.0;
mu_wed_add = [0.0, 0.0, 0.0, 0.0];
ebar_add   = [0.0, 0.0, 0.0, 0.0];
v_abr_r_add= [0.0, 0.0, 0.0, 0.0];

Q_mult       = [1.0, 1.0, 1.0, 1.0];
w_mult       = [1.0, 1.0, 1.0, 1.0];
ebar_mult    = [1.0, 1.0, 1.0, 1.0];
zfl_mult     = [1.0, 1.0, 1.0, 1.0];
zfh_mult     = [1.0, 1.0, 1.0, 1.0];
zh_reg_mult  = [1.0, 1.0, 1.0, 1.0];
lam_psy_mult = [1.0, 1.0, 1.0, 1.0];
club_mult    = [1.0, 1.0, 1.0, 1.0];

G1_mult   = 1.0; G2_mult   = 1.0; gbar_mult = 1.0; yg_mult   = 1.0;
ment_mult = 1.0; alpI_mult = 1.0; dhc_mult  = 1.0; hosp_mult = 1.0;
adol_mult = 1.0; sj_mult   = 1.0;

% C01: Tenure Tax Neutrality
u01 = eC(1);
if abs(u01) > 0
    ups_h_add  = ups_h_add  + u01 * 0.0035;
    Q_mult     = Q_mult    .* max(0.50, 1.0 - u01 * [0.025, 0.035, 0.052, 0.068]);
    zl_sub_add = zl_sub_add - u01 * 0.045;
    debt_add   = debt_add   - u01 * 0.007;
end

% C02: Public R&D & Science Capacity
u02 = eC(2);
if abs(u02) > 0
    zfh_mult    = zfh_mult .* max(0.50, 1.0 + u02 * [0.015, 0.025, 0.075, 0.068]);
    zfl_mult    = zfl_mult .* max(0.50, 1.0 - u02 * [0.020, 0.025, 0.035, 0.045]);
    v_abr_s_add = v_abr_s_add - u02 * 0.085;
end

% C03: Core Public Service Workforce
u03 = eC(3);
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
    adol_mult = adol_mult * max(0.40, 1.0 - u03 * 0.15);
end

% C04: Inter-Island Rail-Ferry Corridor
u04 = eC(4);
if abs(u04) > 0
    debt_add  = debt_add - min(0.0, u04) * 0.0035;
    ebar_mult = ebar_mult .* max(0.50, 1.0 - u04 * [0.065, 0.055, 0.040, 0.015]);
    w_mult    = w_mult    .* max(0.50, 1.0 + u04 * [0.011, 0.009, 0.008, 0.002]);
end

% C05: Acute Hospital & Clinical Capacity
u05 = eC(5);
if abs(u05) > 0
    dhc_mult  = dhc_mult  * max(0.60, 1.0 - u05 * 0.085);
    hosp_mult = hosp_mult * max(0.50, 1.0 - u05 * 0.140);
    Params_Out.G_Health_Regional_Drag = (-u05) * [0.0012, 0.0010, 0.0018, 0.0008];
    ebar_add  = ebar_add  + Params_Out.G_Health_Regional_Drag;
end

% C06: Early-Years Wraparound, OT Prevention & Care Pay Equity
u06 = eC(6);
if abs(u06) > 0
    G1_mult   = G1_mult   * max(0.25, 1.0 + u06 * 0.220);
    G2_mult   = G2_mult   * max(0.25, 1.0 + u06 * 0.160);
    gbar_mult = gbar_mult * max(0.20, 1.0 - u06 * 0.200);
    ment_mult = ment_mult * max(0.20, 1.0 + u06 * 0.250);
    w_mult    = w_mult   .* max(0.50, 1.0 + u06 * [0.006, 0.010, 0.012, 0.008]);
end

% C07: Tertiary Access & Adult Upskilling
u07 = eC(7);
if abs(u07) > 0
    yg_mult   = yg_mult   * max(0.15, 1.0 + u07 * 0.350);
    alpI_mult = alpI_mult * max(0.30, 1.0 + u07 * 0.075);
end

% C08: Smokefree Public Health Excise
u08 = eC(8);
if abs(u08) > 0
    hosp_mult = hosp_mult * max(0.50, 1.0 - u08 * 0.045);
    morb_add  = morb_add  - u08 * 0.008;
    sj_mult   = sj_mult   * (max(0.50, 1.0 + u08 * 0.008) ^ scale_dt);
end

% C09: Working-Age Tax Threshold Relief (statutorily offset post-2026 when SS1 C23 Fiscal Rebalance is active!)
u09 = eC(9);
u23 = eC(23);
if abs(u09) > 0
    c09_tax_persist = 1.0;
    if u09 > 0
        c09_tax_persist = 1.0 - 0.85 * min(1.0, max(0.0, u23));
    end
    tau_l_add = tau_l_add - u09 * 0.012 * c09_tax_persist;
    debt_add  = debt_add  + u09 * 0.024 * (0.45 + 0.55 * c09_tax_persist);
end

% C10: Investor Visa Capital Inflow
u10 = eC(10);
if abs(u10) > 0
    lam_add     = lam_add + u10 * 0.045;
    Q_mult      = Q_mult .* max(0.50, 1.0 + u10 * [0.012, 0.010, 0.008, 0.018]);
    zfh_mult(3) = zfh_mult(3) * max(0.50, 1.0 + u10 * 0.012);
    zfh_mult(4) = zfh_mult(4) * max(0.50, 1.0 + u10 * 0.018);
end

% C11: Accelerated Business Asset Expensing
u11 = eC(11);
if abs(u11) > 0
    tau_k_add = tau_k_add - u11 * 0.022;
    debt_add  = debt_add  + u11 * 0.011;
end

% C12: Educator Real Remuneration Parity
u12 = eC(12);
if abs(u12) > 0
    G1_mult     = G1_mult * max(0.30, 1.0 + u12 * 0.065);
    G2_mult     = G2_mult * max(0.30, 1.0 + u12 * 0.080);
    v_abr_s_add = v_abr_s_add - u12 * 0.025;
end

% C13: Retirement Match & Social Rent Buffer
u13 = eC(13);
if abs(u13) > 0
    yg_mult   = yg_mult   * max(0.20, 1.0 + u13 * 0.150);
    gbar_mult = gbar_mult * max(0.20, 1.0 - u13 * 0.085);
end

% C14: National Water Balance-Sheet Stewardship
u14 = eC(14);
if abs(u14) > 0
    mu_wed_add = mu_wed_add - u14 * [0.0022, 0.0030, 0.0042, 0.0026];
end

% C15: Grassroots Arts, Sport & Civic Commons (TWO-SIDED)
u15 = eC(15);
if u15 < 0
    q_cut        = -u15;
    reg_civic_wt = [0.75, 0.85, 2.10, 1.35];
    debt_add     = debt_add - q_cut * 0.0004;
    G2_mult      = G2_mult  * max(0.30, 1.0 - q_cut * 0.038);
    lam_psy_mult = lam_psy_mult .* (1.0 + q_cut * 0.085 * reg_civic_wt);
    club_mult    = club_mult    .* max(0.50, 1.0 - q_cut * 0.065 * [1.15, 1.10, 1.45, 0.95]);
    zh_reg_mult  = zh_reg_mult  .* max(0.60, 1.0 - q_cut * 0.011 * reg_civic_wt);
    v_abr_r_add  = v_abr_r_add  + q_cut * 0.018 * reg_civic_wt;
    Params_Out.Civic_Hysteresis_Mult = 1.08;
    coh_add      = coh_add - q_cut * 4.80;
elseif u15 > 0
    reg_pos_wt   = [1.05, 1.08, 1.18, 1.20];
    Params_Out.Civic_Commitment_Scale = u15;
    Params_Out.Enable_Arts_Civic      = true;
    debt_add     = debt_add + u15 * 0.00077;
    G2_mult      = G2_mult  * (1.0 + u15 * 0.075);
    lam_psy_mult = lam_psy_mult .* max(0.25, 1.0 - u15 * 0.160 * reg_pos_wt);
    club_mult    = club_mult    .* (1.0 + u15 * 0.125 * [1.22, 1.18, 1.06, 1.02]);
    zh_reg_mult  = zh_reg_mult  .* (1.0 + u15 * 0.020 * [0.85, 0.95, 1.25, 1.28]);
    v_abr_r_add  = v_abr_r_add  - u15 * 0.032 * [0.80, 0.90, 1.30, 1.25];
    coh_add      = coh_add + u15 * 8.50;
end

% C16: Paris NDC & Clean Exergy Transition (TWO-SIDED — unchanged outside ndc branch!)
u16 = eC(16);
clean_exergy_scale = max(0.0, u16);
if u16 < 0
    q_ndc    = -u16;
    ndc_mode = lower(strtrim(char(get_opt(Opts, 'NDC_Settlement_Mode', 'hybrid'))));
    w_pay    = double(strcmp(ndc_mode, 'offshore_pay')) + 0.5 * double(strcmp(ndc_mode, 'hybrid'));
    w_def    = double(strcmp(ndc_mode, 'default_fta_penalty')) + 0.5 * double(strcmp(ndc_mode, 'hybrid'));

    eps_e_add   = eps_e_add - q_ndc * 0.120;
    ebar_mult   = ebar_mult .* (1.0 + q_ndc * [0.065, 0.052, 0.030, 0.022]);
    ndc_q       = q_ndc * w_pay * 1.45;
    rspr_q      = q_ndc * w_def * 0.0022;
    debt_add    = debt_add  + q_ndc * w_pay * 0.0185;
    ndc_add     = ndc_add   + ndc_q;
    zh_reg_mult = zh_reg_mult .* max(0.60, 1.0 - q_ndc * w_def * [0.034, 0.024, 0.008, 0.006]);
    rspr_add    = rspr_add  + rspr_q;
    tau_l_add   = tau_l_add + 0.0025 * (ndc_q / 0.725) + 0.80 * rspr_q;
elseif u16 > 0
    eps_e_add   = eps_e_add + u16 * 0.300;
    ebar_mult   = ebar_mult   .* max(0.45, 1.0 - u16 * [0.220, 0.190, 0.140, 0.110]);
    zh_reg_mult = zh_reg_mult .* (1.0 + u16 * [0.045, 0.030, 0.012, 0.008]);
    rspr_add    = rspr_add  - u16 * 0.0015;
    Params_Out.Clean_Exergy_Scale = u16;
end

% C17: Public Network & Grid Asset Stewardship (TWO-SIDED)
u17 = eC(17);
if abs(u17) > 0
    Params_Out.Asset_Stewardship_Dial = u17;
    if u17 < 0
        q_priv      = -u17;
        debt_add    = debt_add   - q_priv * 0.018;
        ebar_mult   = ebar_mult   .* (1.0 + q_priv * [0.140, 0.125, 0.105, 0.095]);
        mu_wed_add  = mu_wed_add + q_priv * [0.0028, 0.0032, 0.0038, 0.0034];
        zh_reg_mult = zh_reg_mult .* max(0.65, 1.0 - q_priv * [0.028, 0.026, 0.024, 0.022]);
        coh_add     = coh_add    - q_priv * 3.20;
    else
        ebar_mult   = ebar_mult   .* max(0.55, 1.0 - u17 * [0.085, 0.080, 0.070, 0.065]);
        mu_wed_add  = mu_wed_add - u17 * [0.0018, 0.0020, 0.0024, 0.0020];
        zh_reg_mult = zh_reg_mult .* (1.0 + u17 * [0.022, 0.020, 0.018, 0.016]);
        coh_add     = coh_add    + u17 * 2.40;
    end
end

% C18: Sovereign Defence Capability Posture (TWO-SIDED; uses clean_exergy_scale commutatively!)
u18 = eC(18);
if u18 > 0
    Params_Out.Defence_Posture_Dial = u18;
    Params_Out.Defence_PctGDP       = 0.012 + u18 * 0.018;
    net_fx_strain = max(0.0, u18 * (1.0 - 0.65 * clean_exergy_scale));
    debt_add      = debt_add  + net_fx_strain * 0.028;
    rspr_add      = rspr_add  + net_fx_strain * 0.0018;
    tau_l_add     = tau_l_add + u18 * 0.0175 - 0.0040 * clean_exergy_scale;
elseif u18 < 0
    q_ref = -u18;
    Params_Out.Defence_Posture_Dial = u18;
    Params_Out.Defence_PctGDP       = 0.012;
    ebar_mult   = ebar_mult   .* max(0.60, 1.0 - q_ref * [0.032, 0.038, 0.042, 0.030]);
    zh_reg_mult = zh_reg_mult .* (1.0 + q_ref * [0.008, 0.014, 0.018, 0.015]);
    v_abr_s_add = v_abr_s_add - q_ref * 0.018;
    rspr_add    = rspr_add    - q_ref * 0.00045;
end

%% ========================================================================
%  CONSTRUCTIVE SS1 & SS2 PILLARS (SPARSE CODES C21..C28) + SYNERGY WEDGES 1..4
%  (Slots C19..C20 and C29+ remain reserved/unallocated outside ndc branch!)
%  ========================================================================
u21 = eC(21); u22 = eC(22); u24 = eC(24); u25 = eC(25);
u26 = eC(26); u27 = eC(27); u28 = eC(28);

% C21 [SS1 Lane 1]: First-2,000-Days Universal ECE & Farm-to-ECE
if u21 > 0
    G1_mult   = G1_mult   * (1.0 + u21 * 0.720);
    gbar_mult = gbar_mult * max(0.25, 1.0 - u21 * 0.340);
    hosp_mult = hosp_mult * max(0.55, 1.0 - u21 * 0.115);
    coh_add   = coh_add   + u21 * 4.20;
end

% C22 [SS1 Lane 1]: Adolescent Tuakana-Teina, Montessori & FYI Mentoring
if u22 > 0
    G2_mult   = G2_mult   * (1.0 + u22 * 0.420);
    ment_mult = ment_mult * (1.0 + u22 * 0.780);
    adol_mult = adol_mult * max(0.35, 1.0 - u22 * 0.250);
    coh_add   = coh_add   + u22 * 3.10;
end

% ★ WEDGE 1 (Intra-Lane 1: Cunha-Heckman phi_2 = -0.95 Dual-Gate Synergy, C21 x C22)
w1_syn = max(0.0, u21) * max(0.0, u22);
if w1_syn > 0
    G1_mult   = G1_mult   * (1.0 + w1_syn * 0.420);
    G2_mult   = G2_mult   * (1.0 + w1_syn * 0.350);
    ment_mult = ment_mult * (1.0 + w1_syn * 0.600);
    dhc_mult  = dhc_mult  * max(0.55, 1.0 - w1_syn * 0.135);
    hosp_mult = hosp_mult * max(0.50, 1.0 - w1_syn * 0.115);
    coh_add   = coh_add   + w1_syn * 5.40;
end

% C23 [SS1 Lane 2]: 1.5% Land & 25% Estate Tax Rebalance + Statutory Working-Age Base Floor
if u23 > 0
    tau_a_add = tau_a_add + u23 * 0.015;
    tau_b_add = tau_b_add + u23 * 0.180;
    Q_mult    = Q_mult   .* max(0.60, 1.0 - u23 * [0.020, 0.045, 0.075, 0.105]);
    debt_add  = debt_add  - u23 * 0.012;
    coh_add   = coh_add   + u23 * 3.20;
end

% C24 [SS1 Lane 2]: Universal Age-20 Youth Capital Grant (E)
if u24 > 0
    yg_mult   = yg_mult   * (1.0 + u24 * 0.550);
    alpI_mult = alpI_mult * (1.0 + u24 * 0.065);
end

% C25 [SS1 Lane 2]: Income x Geography Household Bridge (85% retired in SS2 when C26 active)
if u25 > 0
    gbar_mult = gbar_mult * max(0.25, 1.0 - u25 * 0.120);
    adol_mult = adol_mult * max(0.40, 1.0 - u25 * 0.080);
    coh_add   = coh_add   + u25 * 2.20;
end

% ★ WEDGE 2 (Intra-Lane 2: 20% Kiyotaki LVR Cliff Clearance & Whanau Anchoring, C23 x C24 [x C25])
w2_syn = max(0.0, u23) * max(0.0, u24) * (1.0 + 0.25 * max(0.0, u25));
if w2_syn > 0
    yg_mult     = yg_mult     * (1.0 + w2_syn * 0.680);
    v_abr_s_add = v_abr_s_add - w2_syn * 0.075;
    coh_add     = coh_add     + w2_syn * 4.80;
end

% C26 [SS1 Lane 3]: Productive z_l -> z_h Firm Tax Shift & Local Food-Hub Procurement
if u26 > 0
    tau_k_add   = tau_k_add   - u26 * 0.038;
    lam_add     = lam_add     + u26 * 0.085;
    zh_reg_mult = zh_reg_mult .* (1.0 + u26 * [0.065, 0.068, 0.062, 0.058]);
end

% ★ WEDGE 3 (Cross-Stack L1 x L2 x L3: Thriving Talent Pool x Land De-Hoarding x Regional z_h Builders)
st1_hc  = 0.5 * (max(0.0, u21) + max(0.0, u22));
st2_sp  = 0.5 * (max(0.0, u23) + max(0.0, u24));
w3_syn  = st1_hc * st2_sp * max(0.0, u26);
if w3_syn > 0
    zh_reg_mult = zh_reg_mult .* (1.0 + w3_syn * [0.085, 0.082, 0.075, 0.072]);
    v_abr_s_add = v_abr_s_add - w3_syn * 0.110;
    coh_add     = coh_add     + w3_syn * 5.50;
end

% C27 [SS2 Lane 4]: 2050 50/50 Sovereign Debt-Sinking (-60 bps) & 1.65x Infrastructure Pool
if u27 > 0
    debt_add    = debt_add    - u27 * 0.028;
    rspr_add    = rspr_add    - u27 * 0.0065;
    ebar_mult   = ebar_mult   .* max(0.55, 1.0 - u27 * [0.105, 0.095, 0.082, 0.072]);
    zh_reg_mult = zh_reg_mult .* (1.0 + u27 * [0.038, 0.038, 0.040, 0.042]);
end

% C28 [SS2 Lane 4]: -3.75pp PAYE Cut (18.25%) & Super Age-64 Kuia Dividend vs u28 < 0 Solve-Debt-First Super-70 Trap
if u28 > 0
    geo_ret_bonus = 0.0064 * max(0.0, u25) * max(0.0, u26);
    tau_l_add     = tau_l_add - u28 * (0.0311 + geo_ret_bonus);
    G1_mult       = G1_mult   * (1.0 + u28 * 0.120);
    hosp_mult     = hosp_mult * max(0.55, 1.0 - u28 * 0.055);
    sj_mult       = sj_mult   * ((1.0 + u28 * 0.006) ^ scale_dt);
    coh_add       = coh_add   + u28 * 5.20;
elseif u28 < 0
    q28       = -u28;
    debt_add  = debt_add  + q28 * 0.012;
    hosp_mult = hosp_mult * (1.0 + q28 * 0.185);
    adol_mult = adol_mult * (1.0 + q28 * 0.280);
    G1_mult   = G1_mult   * max(0.40, 1.0 - q28 * 0.200);
    coh_add   = coh_add   - q28 * 8.40;
end

% ★ WEDGE 4 (All-4-Coalition Solvency, Replacement TFR & 2nd-Gen Closure)
w4_syn = st1_hc * max(0.0, u26) * 0.5 * (max(0.0, u27) + max(0.0, u28));
if w4_syn > 0
    debt_add    = debt_add    - w4_syn * 0.024;
    zh_reg_mult = zh_reg_mult .* (1.0 + w4_syn * [0.048, 0.048, 0.044, 0.042]);
    coh_add     = coh_add     + w4_syn * 4.50;
end

%% ========================================================================
%  SINGLE-PASS DOMAIN CLOSURE (ORDER-INVARIANT)
%  ========================================================================
Params_Out.Debt_to_GDP_Init         = debt_0 + debt_add;
Params_Out.tau_l                    = max(0.05, tau_l_0 + tau_l_add);
Params_Out.tau_k                    = max(0.05, tau_k_0 + tau_k_add);
Params_Out.tau_a                    = max(0.00, tau_a_0 + tau_a_add);
Params_Out.tau_b                    = max(0.00, tau_b_0 + tau_b_add);
Params_Out.lambda_col               = max(1.10, lam_col_0 + lam_add);
Params_Out.V_Abroad_SkillPrem_Shift = v_abr_s_0 + v_abr_s_add;
Params_Out.upsilon_h                = ups_h_0 + ups_h_add;
Params_Out.z_l_subsidy_wedge        = zl_sub_0 + zl_sub_add;
Params_Out.mu_rates_wedge_vec       = max(-0.02, mu_wed_0 + mu_wed_add);
Params_Out.Q_k_vec                  = Q_0 .* Q_mult;
Params_Out.w_k_vec                  = w_0 .* w_mult;
Params_Out.ebar_k_vec               = max(0.004, ebar_0 .* ebar_mult + ebar_add);

sj_new           = sj_ref;
ret_span         = max(1, round(Params_Out.Jr)) : (Params_Out.J - 1);
sj_new(ret_span) = min(0.995, max(0.05, sj_ref(ret_span) .* sj_mult));
Params_Out.sj    = sj_new;

Params_Out.G_ECE_1                  = G1_0   * G1_mult;
Params_Out.G_ECE_2                  = G2_0   * G2_mult;
Params_Out.gbar_ece                 = gbar_0 * gbar_mult;
Params_Out.YouthGrant               = yg_0   * yg_mult;
Params_Out.M_mentor                 = ment_0 * ment_mult;
Params_Out.alpha_I                  = alpI_0 * alpI_mult;
Params_Out.delta_hc_mult            = dhc_0  * dhc_mult;
Params_Out.Exit2_Hosp_Mult          = hosp_0 * hosp_mult;
Params_Out.Senescence_Morbid_Add    = max(-0.02, morb_0 + morb_add);
Params_Out.psi_unemp_adol           = adol_0 * adol_mult;

Params_Out.z_f_Rural                = [zf_R_0(1) * zfl_mult(1), zf_R_0(2) * zfh_mult(1)];
Params_Out.z_f_Small                = [zf_S_0(1) * zfl_mult(2), zf_S_0(2) * zfh_mult(2)];
Params_Out.z_f_Large                = [zf_L_0(1) * zfl_mult(3), zf_L_0(2) * zfh_mult(3)];
Params_Out.z_f_Auckland             = [zf_A_0(1) * zfl_mult(4), zf_A_0(2) * zfh_mult(4)];

Params_Out.lambda_psy_vec           = min(0.65, max(0.16, lam_psy_0 .* lam_psy_mult));
Params_Out.psi_club_buffer_vec      = club_0   .* club_mult;
Params_Out.Z_h_reg_mult             = zh_reg_0 .* zh_reg_mult;
Params_Out.V_Abroad_Reg_Shift       = v_abr_r_0 + v_abr_r_add;
Params_Out.Cohesion_Shock_Pts       = coh_0 + coh_add;
Params_Out.r_sov_spread             = max(-0.015, rspr_0 + rspr_add);
Params_Out.Offshore_NDC_Drain_BNZD  = ndc_dr_0 + ndc_add;
Params_Out.eps_h_energy             = min(0.95, max(0.15, eps_e_0 + eps_e_add));

[Params_Out, BundleMeta, z_grid_Out] = sync_and_diagnose(Params_Out, Regions, BundleMeta, z_grid_Out, false);

end

%% ========================================================================
%  SPARSE CODE LOOKUP & DIAL RESOLVER
%  ========================================================================
function val = get_eff_by_code(eff_u, c2pos, cn)
if cn >= 1 && cn <= numel(c2pos) && c2pos(cn) > 0
    val = eff_u(c2pos(cn));
else
    val = 0.0;
end
end

function [u_vec, is_reanchor, lbl] = resolve_dial_vector(Spec, Catalog, Opts)
CIDs        = Catalog.Commitment_IDs;
c2pos       = Catalog.Code_To_Pos;
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
    % Support comma/space/range set expressions such as 'c01..c16, +c21..c28' or '+c21, +c22':
    if any(name_in == ',') || ~isempty(regexp(name_in, '^[+\-]?[cC]?\d+\s*(\.\.|:)', 'once'))
        u_vec = parse_set_expression(name_in, Catalog);
        lbl   = name_in;
        return;
    end

    b_name = map_alias_to_bundle(name_in, Catalog.Bundles);
    if strcmpi(b_name, 'custom')
        lbl   = 'Custom_Legacy_Opts';
        u_vec = map_legacy_bool_opts(Opts, c2pos, nC);
        return;
    end

    % Match full Commitment_ID or short code like 'C21', '+C21', '-C08':
    cid_idx = find(strcmpi(CIDs, b_name), 1);
    if ~isempty(cid_idx)
        u_vec(cid_idx) = 1.0;
        lbl = CIDs{cid_idx};
        return;
    end
    tok_c = regexp(b_name, '^([+\-]?)c0*(\d+)$', 'tokens', 'ignorecase', 'once');
    if ~isempty(tok_c)
        sg_str = tok_c{1};
        cn     = str2double(tok_c{2});
        if cn >= 1 && cn <= numel(c2pos) && c2pos(cn) > 0
            pos_i = c2pos(cn);
            if strcmp(sg_str, '-')
                u_vec(pos_i) = -1.0;
            else
                u_vec(pos_i) = +1.0;
            end
            lbl = sprintf('%s%s', sg_str, CIDs{pos_i});
            return;
        end
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

% Allow isolating any single shock or subset of a bundle via Opts.ActiveIdx or Opts.ActiveCodes:
if isfield(Opts, 'ActiveCodes') && ~isempty(Opts.ActiveCodes)
    keep_mask = ismember(Catalog.Code_Nums, Opts.ActiveCodes(:));
    u_vec(~keep_mask) = 0.0;
    active_tags = regexp(CIDs(keep_mask), '^C\d+', 'match', 'once');
    lbl = sprintf('%s [%s]', lbl, strjoin(active_tags(:)', '+'));
elseif isfield(Opts, 'ActiveIdx') && ~isempty(Opts.ActiveIdx)
    keep_mask = false(nC, 1);
    keep_mask(Opts.ActiveIdx(:)) = true;
    u_vec(~keep_mask) = 0.0;
    active_tags = regexp(CIDs(keep_mask), '^C\d+', 'match', 'once');
    lbl = sprintf('%s [%s]', lbl, strjoin(active_tags(:)', '+'));
end
end

function u_vec = parse_set_expression(expr_str, Catalog)
% Parses explorer-compatible sparse expressions (e.g. 'c01..c16, +c21..c28' or '+c21, +c22')
% where bare/'-cXX' enacts the 2024 shock direction and '+cXX' enacts the positive reform/SS1/SS2 direction!
nC      = numel(Catalog.Commitment_IDs);
c2pos   = Catalog.Code_To_Pos;
posOnly = Catalog.Is_Positive_Only;
u_vec   = zeros(nC, 1);
% Reference 2024 shock sign in Convention-2 u_i space (+1 for C09,C10,C11,C18; -1 otherwise)
shock_u = -ones(nC, 1);
for cn_pos = [9, 10, 11, 18]
    if cn_pos <= numel(c2pos) && c2pos(cn_pos) > 0
        shock_u(c2pos(cn_pos)) = +1.0;
    end
end

tokens = regexp(lower(strtrim(expr_str)), '[,;\s]+', 'split');
for k = 1:numel(tokens)
    tok = tokens{k};
    if isempty(tok), continue; end
    has_plus  = (tok(1) == '+');
    has_minus = (tok(1) == '-');
    if has_plus || has_minus
        core = tok(2:end);
    else
        core = tok;
    end
    rng_m = regexp(core, '^c?0*(\d+)(?:\.\.|:|-)c?0*(\d+)$', 'tokens', 'once');
    if ~isempty(rng_m)
        a = str2double(rng_m{1}); b = str2double(rng_m{2});
        for cn = min(a, b):max(a, b)
            if cn >= 1 && cn <= numel(c2pos) && c2pos(cn) > 0
                pi = c2pos(cn);
                if has_plus || (posOnly(pi) && ~has_minus)
                    u_vec(pi) = -shock_u(pi);
                else
                    u_vec(pi) = shock_u(pi);
                end
            end
        end
        continue;
    end
    num_m = regexp(core, '^c?0*(\d+)$', 'tokens', 'once');
    if ~isempty(num_m)
        cn = str2double(num_m{1});
        if cn >= 1 && cn <= numel(c2pos) && c2pos(cn) > 0
            pi = c2pos(cn);
            if has_plus || (posOnly(pi) && ~has_minus)
                u_vec(pi) = -shock_u(pi);
            else
                u_vec(pi) = shock_u(pi);
            end
        end
    end
end
end

function b_name = map_alias_to_bundle(name_in, Bundles)
if isfield(Bundles, name_in)
    b_name = name_in;
    return;
end
low = lower(name_in);
switch low
    case {'reanchor_2023', 'ss0_2023', 'ss0'}
        b_name = 'baseline_2023';
    case {'austerity_landlord_only', 'retrenchment_only', 'ret10'}
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
    case {'all_but_ndc', 'full_15_shocks', 'dom15'}
        b_name = 'domestic_15_bundle';
    case 'ndc'
        b_name = 'ndc_clean_energy_rollback';
    case {'ndc_clean_green', 'cerf_ndc_upgrade'}
        b_name = 'ndc_clean_exergy_upgrade';
    case {'full_16_shocks', 'full16'}
        b_name = 'full_16_commitments';
    case 'wedge1'
        b_name = 'wedge1_dualgate_hc';
    case 'wedge2'
        b_name = 'wedge2_lvr_whanau_spatial';
    case 'ss1'
        b_name = 'ss1_clean_base';
    case {'ss2', 'compact'}
        b_name = 'ss2_clean_base';
    case {'debtfirst', 'austerity70'}
        b_name = 'solve_debt_first_super70';
    case {'hole_ss1', 'post2024_ss1'}
        b_name = 'hole_2024_plus_ss1';
    case {'hole_ss2', 'post2024_ss2'}
        b_name = 'hole_2024_plus_ss2';
    case 'custom'
        b_name = 'custom';
    otherwise
        b_name = name_in;
end
end

function u_vec = map_legacy_bool_opts(Opts, c2pos, nC)
u_vec = zeros(nC, 1);
legacy_map = { ...
    'LandlordTaxBreak',                1, -1.0; ...
    'ScienceCallaghanCuts',            2, -1.0; ...
    'PublicSectorLayoffs',             3, -1.0; ...
    'CancelFerriesPorts',              4, -1.0; ...
    'DunedinHospitalDelays',           5, -1.0; ...
    'CancelPayEquity_OT_ECE',          6, -1.0; ...
    'TertiaryFeesFreeCut',             7, -1.0; ...
    'TobaccoTaxFreeze',                8, -1.0; ...
    'IncomeTaxBracketCut',             9, +1.0; ...
    'ActiveInvestorVisa',             10, +1.0; ...
    'InvestmentBoost20Pct',           11, +1.0; ...
    'TeacherKaiakoPaySqueeze',        12, -1.0; ...
    'KiwiSaverMatchCut',              13, -1.0; ...
    'ThreeWatersRatesWedge',          14, -1.0; ...
    'ArtsCivicWCCSqueeze',            15, -1.0; ...
    'ParisNDCLiabilityAndEVRollback', 16, -1.0};
for r = 1:size(legacy_map, 1)
    fn = legacy_map{r, 1};
    cn = legacy_map{r, 2};
    sg = legacy_map{r, 3};
    if cn <= numel(c2pos) && c2pos(cn) > 0 && isfield(Opts, fn) && ~isempty(Opts.(fn))
        u_vec(c2pos(cn)) = sg * double(Opts.(fn));
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
