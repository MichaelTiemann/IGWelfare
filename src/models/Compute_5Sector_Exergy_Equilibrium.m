function Out = Compute_5Sector_Exergy_Equilibrium(Params, RegimeCode, Opts)
%% PURE 5-SECTOR SMALL OPEN ECONOMY, BIOPHYSICAL EXERGY & EXTERNAL BALANCE SOLVER
% File: src/models/Compute_5Sector_Exergy_Equilibrium.m
% Implements Unified 5-Sector SOE & Exergy Outer-Loop Closure (Document 2A §2.3-2.5, 100% vectorized, 0 time loops):
%   - Keen, Ayres & Standish (2019) Second-Law exergy activation (e_N = 0.88 vs e_F = 0.30, sigma_KL_X = 0.07)
%   - Labrousse & Perdereau (2026) 4-region dual-fuel substitution & fossil import bill
%   - 5-Sector output & labor allocation (S1 Primary, S2 Weightless z_h, S3 Market Non-Tradable & Grid,
%     S4A Capacitating vs Reactive Civic Co-Production, S4B Waters/Roads Capital, S5 Sovereign Defence)
%   - Balance of Payments, Real Exchange Rate (p_N_rel), & Schmitt-Grohe/Uribe debt-elastic spread r_t.
%   - Sub-Wave 7C Exogenous Shock & Contingent Stabilizer Coupling:
%       Opts.ExogShocks = struct('HC_Realization_Lag', 0, 'S4A_Poaching_Shock', 0, ...
%           'World_Fossil_Spike', 0, 'Dry_Hydro_Shock', 0, 'Export_ToT_Hit', 0, 'World_Rate_Shock_bps', 0)
%       Opts.Enable_Contingent_Stabilizers (logical, default false when unshocked; attenuates shocks via K01..K15 remedies)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end
if nargin < 2 || isempty(RegimeCode)
    RegimeCode = 'Phase2_Reform';
end
if nargin < 3 || isempty(Opts)
    Opts = struct();
end

SecSpec = Load_Sectoral_Exergy_Spec(Params.Profile_ID);
Ex      = SecSpec.Exergy;
NDC     = SecSpec.NDC;
SOE     = SecSpec.SOE;
MT      = SecSpec.MacroSector_Table;

% Parse optional exogenous shocks (all 0.0 by default -> exact Wave 6 baseline!):
Shk      = get_substruct(Opts, 'ExogShocks');
s_hc     = max(0.0, get_val(Shk, 'HC_Realization_Lag',   0.0)); % 1.0 = 35% slower cohort skill exit
s_staff  = max(0.0, get_val(Shk, 'S4A_Poaching_Shock',   0.0)); % 1.0 = severe trans-Tasman S4A staffing raid
s_oil    = max(0.0, get_val(Shk, 'World_Fossil_Spike',   0.0)); % 1.0 = +60% world oil/gas price spike
s_hydro  = max(0.0, get_val(Shk, 'Dry_Hydro_Shock',      0.0)); % 1.0 = multi-year dry-hydro thermal peaking surge
s_tot    = max(0.0, get_val(Shk, 'Export_ToT_Hit',       0.0)); % 1.0 = -12% Sector 1 commodity / CBAM terms-of-trade hit
s_rbps   = max(0.0, get_val(Shk, 'World_Rate_Shock_bps', 0.0)); % e.g. 180 = +180 bps world interest rate shock

stab_on  = logical(get_val(Opts, 'Enable_Contingent_Stabilizers', 0.0));

% Automatic stabilizer attenuation factors when Two-Key + K01..K15 remedies are active:
eff_hc    = s_hc    * (1.0 - 0.42 * stab_on); % K02/K07 Tuakana & Joiner coaching surge
eff_staff = s_staff * (1.0 - 0.62 * stab_on); % K04 S4A Kaiako/nurse rent & pay parity indexing
eff_oil   = s_oil   * (1.0 - 0.45 * stab_on); % K12 accelerated CERF heat-pump/EV substitution
eff_hydro = s_hydro * (1.0 - 0.58 * stab_on); % K12/K15 front-loaded K_N renewable overbuild & demand response
eff_tot   = s_tot   * (1.0 - 0.48 * stab_on); % K12 S1->S2 weightless export & Clean-Green diversification
eff_rbps  = s_rbps  * (1.0 - 0.40 * stab_on); % K15 70/30 Sovereign Debt-Sinking buffer

% Column time vector [T x 1] (2026..2086):
Years   = (2026:1:2086)';
t_col   = Years - 2026;
tau_60  = t_col / 60.0;

% Shock time-profiles [T x 1] (multi-year macro episodes + persistent structural tail):
oil_pulse   = eff_oil   * (0.45 + 0.55 * exp(-((t_col - 6.5)  / 4.5) .^ 2));
hydro_pulse = eff_hydro * (0.40 + 0.60 * exp(-((t_col - 6.0)  / 3.8) .^ 2));
tot_pulse   = eff_tot   * (0.55 + 0.45 * exp(-((t_col - 10.0) / 6.0) .^ 2));
rate_pulse  = (eff_rbps / 10000.0) * (0.50 + 0.50 * exp(-((t_col - 12.0) / 6.5) .^ 2));

% Resolve regime dials [ref_prog, clean_prog, civic_dial, def_dial, priv_dial, aust_drag]:
[ref_s, clean_s, civic_s, def_s, priv_s, aust_s] = resolve_regime_dials(RegimeCode, Params, Opts);

% Smooth transition S-curves [T x 1], stretched when HC realization or S4A staffing shocks hit:
tau_p1  = 11.0 * (1.0 + 0.35 * eff_hc + 0.25 * eff_staff);
ss2_lag = 20.0 + 4.5 * eff_hc + 3.0 * eff_staff + 2.5 * (eff_rbps / 180.0) * stab_on;
w_p1    = 1.0 - exp(-t_col / tau_p1);
w_p2    = (t_col >= ss2_lag) .* (1.0 - exp(-max(0.0, t_col - ss2_lag) / 9.5));
w_ref   = ref_s   * (0.55 * w_p1 + 0.45 * w_p2);
w_clean = clean_s * (1.0 ./ (1.0 + exp(-(t_col - 7.5) / 4.2))) .* (1.0 + 0.14 * stab_on * min(1.5, s_oil + s_hydro));
w_clean = min(1.12, w_clean);
w_def   = def_s   * (1.0 - exp(-t_col / 4.5));

% 1. Biophysical Exergy & Domestic Renewable Grid Capacity (K_N,t, M_olig,t, e_N vs e_F)
e_N     = Ex.e_N_elec;
e_F     = Ex.e_F_fossil;
K_N_t   = Ex.K_N_Grid_Init_BCurr * (1.0 + 1.15 * w_clean + 0.25 * w_ref ...
        + 0.18 * stab_on * min(1.5, s_hydro + s_oil) * w_p1 - 0.18 * max(0, -priv_s) * w_p1);

m_grid0 = Ex.M_olig_grid_schedule(1);
m_grid2 = Ex.M_olig_grid_schedule(3);
M_olig_t = m_grid0 + min(1.0, w_ref) * (m_grid2 - m_grid0) ...
         + 0.14 * hydro_pulse .* (1.0 - 0.55 * min(1.0, w_clean)) ...
         + max(0, -priv_s) * 0.24 * w_p1 - max(0, priv_s) * 0.12 * w_p1;

fossil_mult_t  = max(0.12, 1.0 - 0.72 * min(1.05, w_clean) + 0.12 * aust_s * w_p1);
elec_share_inc = max(0.0, 1.0 - fossil_mult_t);
curtail_drag   = 0.065 * hydro_pulse + 0.045 * oil_pulse .* fossil_mult_t;
exergy_gain_t  = max(0.72, 1.0 + 0.16 * ((e_N / e_F - 1.0) * elec_share_inc) ./ M_olig_t ...
               - 0.09 * aust_s * w_p1 - curtail_drag);

dry_share_t    = (Ex.DryYear_Thermal_Share_SS0 * (1.0 - min(1.0, w_clean)) + Ex.DryYear_Thermal_Share_SS2 * min(1.0, w_clean)) ...
               .* (1.0 + 1.35 * hydro_pulse);
p_F_mult_t     = 1.0 + 0.60 * oil_pulse;
Fossil_Bill_t  = Ex.Fossil_Import_Bill_SS0_BCurr * p_F_mult_t .* fossil_mult_t .* (1.0 + 0.45 * dry_share_t);

% 2. Paris NDC Net Emissions, Pine Saturation Cliff (Yr 25), & Clean-Green vs CBAM Terms-of-Trade
e_ndc_1     = NDC.E_NDC_schedule(2);
e_ndc_2     = NDC.E_NDC_schedule(3);
E_NDC_cap_t = 1.00 - (1.00 - e_ndc_1) * (1.0 - exp(-t_col / 8.0)) ...
            - (e_ndc_1 - e_ndc_2) * (t_col >= 10.0) .* (1.0 - exp(-max(0, t_col - 10.0) / 12.0));
kp0         = NDC.kappa_pine_schedule(1);
kappa_pine  = max(0.0, kp0 * (1.0 - 0.75 * min(1.0, w_clean) - 0.25 * w_p2));
S_pine_t    = 0.18 * kappa_pine .* exp(-0.085 * max(0.0, t_col - 25.0));
S_native_t  = (0.14 * min(1.0, w_clean) + 0.06 * max(0, civic_s) * w_p1) .* min(1.0, t_col / 22.0);
E_gross_t   = 1.00 * (0.35 + 0.65 * fossil_mult_t) .* (1.0 - 0.22 * min(1.0, w_clean)) + 0.05 * hydro_pulse;
E_net_t     = max(0.10, E_gross_t - S_pine_t - S_native_t);
ndc_gap_t   = max(0.0, E_net_t - E_NDC_cap_t);

theta_ag_t   = min(1.0, w_clean);
Pi_trade_Tx4 = max(0.68, 1.0 + theta_ag_t * NDC.pi_green_reg - ndc_gap_t * NDC.chi_CBAM_reg ...
             - tot_pulse * [0.120, 0.095, 0.045, 0.030]);
Pi_trade_S1  = Pi_trade_Tx4 * [0.46; 0.30; 0.14; 0.10];

mt_base_tot        = sum(NDC.MtCO2e_2025_reg);
NDC_Outflow_BNZD_t = mt_base_tot * ndc_gap_t .* (NDC.p_NDC_intl_BCurr_per_Mt * (1.012 .^ t_col));

% 3. Five-Sector Labor Reallocation (Internal Sector 4A Reactive -> Capacitating Release!) & Output [T x 6]
L0_row = MT.Paid_kFTE(:)';
Y0_row = MT.Annual_Spend_BCurr(:)';

ST        = SecSpec.SubSector_Table;
idx_hlth  = find(strcmp(ST.SubSector_ID, 'S4A1_Health_SocialCare'), 1);
idx_just  = find(strcmp(ST.SubSector_ID, 'S4A4_Justice_OT_Remed'),  1);
L_rem_0   = ST.Paid_Workforce_kFTE(idx_just) + SOE.Health_Reactive_Share_SS0 * ST.Paid_Workforce_kFTE(idx_hlth);
Y_rem_0   = ST.Annual_Spend_BCurr(idx_just)  + SOE.Health_Reactive_Share_SS0 * ST.Annual_Spend_BCurr(idx_hlth);

rem_compress_t  = min(1.35, max(0.22, 1.0 - 0.76 * w_ref ./ (1.0 + 0.28 * eff_hc + 0.22 * eff_staff) + 0.28 * aust_s * tau_60));
L_S4A_rem_t     = L_rem_0 * rem_compress_t;
L_released_t    = max(0.0, L_rem_0 - L_S4A_rem_t);

poach_drain_kfte = 34.0 * eff_staff * (1.0 - exp(-t_col / 6.0));
skill_pool_mult  = max(0.75, 1.0 + 0.24 * w_ref ./ (1.0 + 0.25 * eff_hc) ...
                 + 0.04 * max(0, civic_s) * w_p1 - 0.08 * eff_staff - 0.14 * aust_s * tau_60);

L_S5_t   = L0_row(6) * (1.0 + 0.95 * w_def);
def_pull = max(0.0, L_S5_t - L0_row(6));
unbuf_def_crowd = max(0.0, def_pull - 0.35 * L_released_t) .* (1.0 - 0.75 * w_ref);

L_S1_t   = L0_row(1) * (1.0 - 0.06 * tau_60 + 0.04 * w_ref - 0.03 * tot_pulse);
L_S2_t   = max(120.0, L0_row(2) * (1.0 + 0.62 * w_ref + 0.08 * max(0, civic_s) * w_p1 ...
         + 0.06 * stab_on * eff_tot * w_p1 - 0.12 * eff_hc - 0.22 * aust_s * tau_60) ...
         + 0.45 * L_released_t - 0.55 * unbuf_def_crowd - 0.35 * poach_drain_kfte);
L_S3_t   = L0_row(3) * (1.0 + 0.08 * tau_60 - 0.04 * w_ref);
L_S4A_cap_t = max(220.0, (L0_row(4) - L_rem_0) * (1.0 + 0.22 * w_ref - 0.12 * aust_s * w_p1) ...
            + 0.45 * L_released_t - 0.65 * poach_drain_kfte);
L_S4A_t  = L_S4A_cap_t + L_S4A_rem_t;
L_S4B_t  = L0_row(5) * (1.0 + 0.18 * w_ref + 0.10 * max(0, priv_s) * w_p1 - 0.10 * aust_s * w_p1) - 0.20 * unbuf_def_crowd;

Paid_kFTE_Tx6 = [L_S1_t, L_S2_t, L_S3_t, L_S4A_t, L_S4B_t, L_S5_t];

Vol_Civic_kFTE_t = SecSpec.Civic_Volunteer_kFTE * max(0.55, 1.0 + 0.18 * w_ref + 0.28 * civic_s * w_p1 ...
                 - 0.07 * (eff_oil + eff_staff) - 0.24 * aust_s * tau_60);
Care_Home_kFTE_t = SOE.Household_Unpaid_Care_kFTE_SS0 * max(0.65, 1.0 + 0.11 * w_ref + 0.06 * min(1.0, w_clean) ...
                 - 0.06 * eff_oil - 0.15 * aust_s * tau_60);

Y_S1_t  = Y0_row(1) * ((L_S1_t / L0_row(1)) .^ 0.68) .* Pi_trade_S1 .* exergy_gain_t .* (1.0 + 0.14 * w_ref);
Y_S2_t  = Y0_row(2) * ((L_S2_t / L0_row(2)) .^ (1.0 + SOE.Arrow_S2_Spillover_Eta)) .* skill_pool_mult .* exergy_gain_t;
Y_S3_t  = Y0_row(3) * (L_S3_t / L0_row(3)) .* exergy_gain_t .* (1.0 + 0.08 * w_ref - 0.06 * aust_s * tau_60);

wage_idx_t    = max(0.78, 1.0 + 0.14 * w_ref + 0.04 * (exergy_gain_t - 1.0) - 0.04 * tot_pulse - 0.08 * aust_s * tau_60);
Y_S4A_cap_SNA = (Y0_row(4) - Y_rem_0) * (L_S4A_cap_t / (L0_row(4) - L_rem_0)) .* wage_idx_t;
Y_S4A_rem_SNA = Y_rem_0 * (L_S4A_rem_t / L_rem_0) .* wage_idx_t;
Y_S4A_SNA_t   = Y_S4A_cap_SNA + Y_S4A_rem_SNA;
Y_S4B_SNA_t   = Y0_row(5) * (L_S4B_t / L0_row(5)) .* wage_idx_t .* (1.0 + 0.15 * w_ref);
Y_S5_SNA_t    = Y0_row(6) * (1.0 + 1.50 * w_def) .* (1.0 + 0.12 * w_ref);

Y_Sector_SNA_Tx6 = [Y_S1_t, Y_S2_t, Y_S3_t, Y_S4A_SNA_t, Y_S4B_SNA_t, Y_S5_SNA_t];
gdp_26_bcurr     = get_val(Params, 'GDP_2026_BCurr', get_val(Params, 'GDP_2026_BNZD', 430.0));
sna_scale        = gdp_26_bcurr / sum(Y_Sector_SNA_Tx6(1, :));
Y_Sector_SNA_Tx6 = Y_Sector_SNA_Tx6 * sna_scale;
Y_SNA_t          = sum(Y_Sector_SNA_Tx6, 2);

ostrom_mult_t = (SOE.Ostrom_Omega_Paid + (1.0 - SOE.Ostrom_Omega_Paid) * ...
    ((Vol_Civic_kFTE_t / SecSpec.Civic_Volunteer_kFTE) .^ SOE.Ostrom_CoProd_Rho)) .^ (1.0 / SOE.Ostrom_CoProd_Rho);
Y_S4A_Cap_Outcome_t = (Y_S4A_cap_SNA * sna_scale) .* ostrom_mult_t .* (1.0 + 0.22 * w_ref + 0.12 * max(0, civic_s) * w_p1);
Y_S4A_Rem_Regret_t  = (Y_S4A_rem_SNA * sna_scale);

% 4. External Balance of Payments, Real Exchange Rate (p_N_rel), & Schmitt-Grohe/Uribe Spread r_t
Exports_BNZD_t     = 0.72 * Y_Sector_SNA_Tx6(:, 1) + 0.78 * Y_Sector_SNA_Tx6(:, 2);
Def_Imports_BNZD_t = SOE.Defence_Import_Share * Y_Sector_SNA_Tx6(:, 6);
NonEnergy_Imp_t    = 0.175 * Y_SNA_t;
Trade_Bal_BNZD_t   = Exports_BNZD_t - (Fossil_Bill_t + Def_Imports_BNZD_t + NDC_Outflow_BNZD_t + NonEnergy_Imp_t);

% 70/30 Sovereign Debt-Sinking buffer activates strictly in proportion to realized external shock magnitude:
ext_shk_mag        = min(1.8, 0.5*(s_oil + s_hydro) + s_tot + (s_rbps / 180.0));
debt_sink_shield   = 0.11 * stab_on * ext_shk_mag .* w_p1;
tb_gdp_delta_t     = (Trade_Bal_BNZD_t ./ Y_SNA_t) - (Trade_Bal_BNZD_t(1) / Y_SNA_t(1));
NFA_to_GDP_t       = max(-1.45, min(0.35, SOE.NFA_to_GDP_Init + cumtrapz(t_col, 0.38 * tb_gdp_delta_t) ...
                   + debt_sink_shield - 0.14 * rate_pulse * 10.0 - 0.42 * aust_s * (tau_60 .^ 1.3)));

r_dom_t   = SOE.r_dom_SS0 + rate_pulse ...
          + SOE.psi_sov_spread * (exp(max(-0.45, SOE.NFA_to_GDP_Bar - NFA_to_GDP_t)) - 1.0) ...
          - (0.0060 + 0.0022 * stab_on * min(1.5, ext_shk_mag)) * w_ref .* w_p2;
RER_pN_t  = 1.0 + 0.18 * tb_gdp_delta_t - 0.06 * (M_olig_t - m_grid0);

Out = struct();
Out.RegimeCode           = RegimeCode;
Out.Years                = Years;
Out.Macro_Sector_Names   = MT.Macro_Sector';
Out.Paid_kFTE_Tx6        = Paid_kFTE_Tx6;
Out.Vol_Civic_kFTE_t     = Vol_Civic_kFTE_t;
Out.Care_Home_kFTE_t     = Care_Home_kFTE_t;
Out.L_S4A_Released_kFTE  = L_released_t;
Out.Reactive_Compress_Pct= 100.0 * (1.0 - rem_compress_t);
Out.Y_Sector_SNA_Tx6     = Y_Sector_SNA_Tx6;
Out.Currency_ISO         = SecSpec.Currency_ISO;
Out.Y_SNA_BCurr_t        = Y_SNA_t;
Out.Y_SNA_BNZD_t         = Y_SNA_t;
Out.Y_S4A_Cap_Outcome_t  = Y_S4A_Cap_Outcome_t;
Out.Y_S4A_Rem_Regret_t   = Y_S4A_Rem_Regret_t;
Out.K_N_Grid_BCurr_t     = K_N_t;
Out.K_N_Grid_BNZD_t      = K_N_t;
Out.M_Olig_Grid_t        = M_olig_t;
Out.Exergy_Gain_Mult_t   = exergy_gain_t;
Out.Fossil_Import_BCurr_t= Fossil_Bill_t;
Out.Fossil_Import_BNZD_t = Fossil_Bill_t;
Out.Def_Imports_BCurr_t  = Def_Imports_BNZD_t;
Out.Def_Imports_BNZD_t   = Def_Imports_BNZD_t;
Out.NDC_Outflow_BCurr_t  = NDC_Outflow_BNZD_t;
Out.NDC_Outflow_BNZD_t   = NDC_Outflow_BNZD_t;
Out.Exports_BCurr_t      = Exports_BNZD_t;
Out.Exports_BNZD_t       = Exports_BNZD_t;
Out.Trade_Balance_BCurr_t= Trade_Bal_BNZD_t;
Out.Trade_Balance_BNZD_t = Trade_Bal_BNZD_t;
Out.NFA_to_GDP_t         = NFA_to_GDP_t;
Out.r_Sovereign_t        = r_dom_t;
Out.Spread_Cut_bps_t     = 10000.0 * ((SOE.r_dom_SS0 + rate_pulse) - r_dom_t);
Out.RER_NonTradable_t    = RER_pN_t;
Out.Pi_Trade_Tx4         = Pi_trade_Tx4;
Out.E_Net_Norm_t         = E_net_t;
Out.E_NDC_Cap_Norm_t     = E_NDC_cap_t;
Out.Wage_Index_t         = wage_idx_t;
Out.SecSpec              = SecSpec;
end

function [ref_s, clean_s, civic_s, def_s, priv_s, aust_s] = resolve_regime_dials(RegimeCode, Params, Opts)
ref_s = 0.0; clean_s = 0.0; civic_s = 0.0; def_s = 0.0; priv_s = 0.0; aust_s = 0.0;
switch lower(strtrim(char(RegimeCode)))
    case {'ss0', 'ss0_ltfm', 'baseline_2023'}
        aust_s = 0.45;
    case {'domestic_15', 'coalition_2024', 'full_16_commitments'}
        aust_s = 1.00; civic_s = -0.50; priv_s = -0.35;
    case {'ss0_defence_3pct', 'unfunded_defence_3pct'}
        aust_s = 0.55; def_s = 1.00;
    case {'phase2_reform', 'ss2_reform', 'foiling_aotearoa'}
        ref_s = 1.00; clean_s = 1.00; priv_s = 0.50;
    case {'phase2_civic_doc1e', 'arts_enabled_ss2'}
        ref_s = 1.00; clean_s = 1.00; civic_s = 1.00; priv_s = 0.65;
    case {'phase2_defence_3pct', 'reform_plus_defence_3pct'}
        ref_s = 1.00; clean_s = 1.00; civic_s = 0.50; def_s = 1.00; priv_s = 0.50;
    otherwise
        ref_s   = get_val(Opts, 'Ref_Scale',   get_val(Params, 'Reform_Intensity', 0.0));
        clean_s = get_val(Opts, 'Clean_Scale', get_val(Params, 'Clean_Exergy_Scale', ref_s));
        civic_s = get_val(Opts, 'Civic_Scale', get_val(Params, 'Civic_Commitment_Scale', 0.0));
        def_s   = get_val(Opts, 'Def_Scale',   get_val(Params, 'Defence_Posture_Dial', 0.0));
        priv_s  = get_val(Opts, 'Asset_Scale', get_val(Params, 'Asset_Stewardship_Dial', 0.0));
        aust_s  = get_val(Opts, 'Aust_Scale',  0.0);
end
end

function S_sub = get_substruct(S, fn)
if isstruct(S) && isfield(S, fn) && isstruct(S.(fn))
    S_sub = S.(fn);
else
    S_sub = struct();
end
end

function v = get_val(S, fn, defv)
if isstruct(S) && isfield(S, fn) && ~isempty(S.(fn))
    v = double(S.(fn));
else
    v = defv;
end
end
