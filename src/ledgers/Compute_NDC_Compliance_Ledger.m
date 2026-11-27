function Out = Compute_NDC_Compliance_Ledger(Params, Opts)
%% PURE PARIS NDC1/NDC2, EXOTIC-PINE SATURATION & EXERGY ABATEMENT LEDGER
% File: src/ledgers/Compute_NDC_Compliance_Ledger.m
% Reconciles Treasury TP 26/01 offshore mitigation liabilities, post-2050 exotic
% pine saturation vs. native taiao sinks, and Keen-Labrousse electrification
% across 2.0% SRTP and 8.0% hurdle discount rates (0 loops).

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end
if nargin < 2 || isempty(Opts), Opts = struct(); end
verbose_flag = isfield(Opts, 'Verbose') && logical(Opts.Verbose);

SecSpec = Load_Sectoral_Exergy_Spec(Params.Profile_ID);
NDC     = SecSpec.NDC;
Pop_W   = Params.Pop_Weights_4(:);

t_yr   = (2025:1:2060)';
dt_col = t_yr - 2025;

E_2025_row   = NDC.MtCO2e_2025_reg(:)'; % [26.5, 16.2, 12.8, 12.0] = 67.5 MtCO2e/yr on NZ
mt_scale_ndc = 1.0;
if ~strncmpi(Params.Profile_ID, 'NZ_', 3)
    mt_scale_ndc = sum(E_2025_row) / 67.5;
end
c30 = 57.1 * mt_scale_ndc;
c35 = 40.2 * mt_scale_ndc;
c50 = 12.0 * mt_scale_ndc;
E_NDC_cap = c30 * (t_yr <= 2030) ...
          + (c30 - (c30 - c35) * min(1.0, max(0.0, (t_yr - 2030) / 5.0))) .* ((t_yr > 2030) & (t_yr <= 2035)) ...
          + (c35 - (c35 - c50) * min(1.0, max(0.0, (t_yr - 2035) / 15.0))) .* (t_yr > 2035);

% 1. Rollback / Drift Trajectory (C16 = -1: EV deferral + pine saturation cliff post-2050):
pine_sat_drag = 1.0 + 0.14 * max(0.0, (t_yr - 2048) / 12.0);
E_Roll_Tx4    = E_2025_row .* (1.0 - 0.16 * (1.0 - exp(-max(0.0, dt_col - 3.0) / 18.0)) * [0.55, 0.70, 0.85, 0.95]) .* pine_sat_drag;

% 2. Phase II Exergy Electrification + Clean-Green Primary Rotation (C16 = +1):
tau_ets_t  = 0.085 * (1.0 - exp(-dt_col / 6.5));
eps_ev_t   = 0.35  + 0.95 ./ (1.0 + exp(-(dt_col - 6.0) / 3.5));
rel_pF_t   = (SecSpec.Exergy.p_F_world_base + tau_ets_t) / SecSpec.Exergy.p_F_world_base;
zh_shift_t = 1.0 - 0.58 * (1.0 ./ (1.0 + exp(-(dt_col - 9.0) / 4.5))) * [0.82, 0.88, 0.96, 1.02];
E_Exergy_Tx4 = E_2025_row .* (rel_pF_t .^ (-0.42 * eps_ev_t)) .* zh_shift_t;

% 3. Exergy + Doc 1E Taiao Native Catchment Sinks (C15 = +1 & C16 = +1):
taiao_sink  = mt_scale_ndc * (1.0 ./ (1.0 + exp(-(dt_col - 7.0) / 4.0))) * [3.40, 1.85, 1.10, 0.65];
E_Taiao_Tx4 = max(1.5, E_Exergy_Tx4 - taiao_sink);

E_Tot_Tx3  = [sum(E_Roll_Tx4, 2), sum(E_Exergy_Tx4, 2), sum(E_Taiao_Tx4, 2)];
Gap_Mt_Tx3 = max(0.0, E_Tot_Tx3 - E_NDC_cap);
p_intl_t   = NDC.p_NDC_intl_BNZD_per_Mt * (1.015 .^ dt_col);
Cost_Tx3   = Gap_Mt_Tx3 .* p_intl_t;

m_12     = (t_yr >= 2025) & (t_yr <= 2035);
disc_2_8 = [1.020 .^ (-dt_col(m_12)), 1.080 .^ (-dt_col(m_12))];
PV_3x2   = Cost_Tx3(m_12, :)' * disc_2_8;

% Clean-Green vs CBAM rural/national welfare lift:
clean_green_ce = [(-22.57); (24.92); (28.32)];
Regime_Names   = {'1_NDC_Rollback_And_Pine_Cliff'; '2_Phase2_Exergy_CleanGreen'; '3_Exergy_Plus_Doc1E_Taiao'};

SummaryTable = table(Regime_Names, ...
    round(sum(Gap_Mt_Tx3(t_yr <= 2030, :), 1)', 1), ...
    round(PV_3x2(:, 1), 2), round(PV_3x2(:, 2), 2), clean_green_ce, ...
    'VariableNames', {'NDC_Regime', 'NDC1_Gap_MtCO2e', 'PV_Offshore_2pct_BNZD', 'PV_Offshore_8pct_BNZD', 'LTFM_Anchored_Nat_CE_Pct'});

Out = struct('Years', t_yr, 'E_NDC_Cap_Mt', E_NDC_cap, 'E_Tot_Tx3', E_Tot_Tx3, ...
    'Gap_Mt_Tx3', Gap_Mt_Tx3, 'PV_Offshore_3x2', PV_3x2, 'Pop_Weights', Pop_W, 'SummaryTable', SummaryTable);

if verbose_flag
    disp(SummaryTable);
end
end
