function L = Compute_Hormuz_EV_Counterfactual_Ledger(Params)
%% COMPUTE_HORMUZ_EV_COUNTERFACTUAL_LEDGER
% Pure vectorized 3x2 counterfactual & fossil-price ledger (2023-2065):
%   Policy Arms:
%     1. Repeal Clean Car Discount (31 Dec 2023 Actual Policy)
%     2. Keep Clean Car Discount (July 2023 Self-Funding Feebate Schedule)
%     3. Boost Clean Car Discount (+30%/yr Escalation -> 2.20x Rebate in 3 Yrs)
%   Shock States:
%     A. Calm-Water Equilibrium Oil Prices (No Strait of Hormuz Shocks)
%     B. 2026 Strait of Hormuz Oil & Middle-Distillate Refinery Shocks

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end

yr = (2023:2065)';                                  % [T x 1] column grid
T  = numel(yr);

% -------------------------------------------------------------------------
% 1. Baseline Nominal/Real Scale & Treasury LTFS 2025 "No-Shock" Trajectory
% -------------------------------------------------------------------------
tau_ltfm = (yr - 2026) / (2065 - 2026);
m_pre26  = (yr <= 2026);
m_post26 = (yr >  2026);

Debt_Hist_Calm = interp1([2023; 2024; 2025; 2026], [38.8; 41.2; 41.8; 41.3], ...
                         min(2026, yr), 'pchip');
tp = max(0, tau_ltfm);
Debt_LTFM_NoShock = m_pre26 .* Debt_Hist_Calm ...
                  + m_post26 .* (41.3 + 48.0 * tp + 110.7 * (tp .^ 2.35));

GDP_Real26_B = 452.2 * ((1.019) .^ (yr - 2026));

% -------------------------------------------------------------------------
% 2. Three Fleet Electrification Paths: Repeal vs. Keep vs. Boost (+20%/yr)
% -------------------------------------------------------------------------
% (a) Repeal CCD (Actual): 2024-26 uptake stalled ~65%, S-curve midpoint ~2043.5
ev_share_repeal = 0.022 + 0.76 ./ (1.0 + exp(-0.165 * (yr - 2043.5)));

% (b) Keep CCD (Self-funding feebate): S-curve midpoint ~2038.7 (~4.8 yrs faster)
ev_share_keep   = 0.022 + 0.80 ./ (1.0 + exp(-0.185 * (yr - 2038.7)));
ev_share_keep(yr == 2023) = ev_share_repeal(yr == 2023);

% (c) Boost CCD (+30%/yr rebate growth: $7,015 * 1.30^t -> $15,412 in Yr 3 (2.20x), $20,035 in Yr 4,
%     accelerating light + commercial van/ute electrification by ~10.7 yrs vs Repeal):
ev_share_boost  = 0.022 + 0.89 ./ (1.0 + exp(-0.245 * (yr - 2032.8)));
ev_share_boost(yr == 2023) = ev_share_repeal(yr == 2023);

delta_ev_keep   = max(0, ev_share_keep  - ev_share_repeal);
delta_ev_boost  = max(0, ev_share_boost - ev_share_repeal);

% Rebate schedule (Real 2026 NZD per qualifying BEV) & Net Crown Feebate Cash Cost (% GDP):
% Keep CCD is revenue-neutral via ute fees after 2025; Boost CCD (+30%/yr for 2024-2027,
% tapering smoothly as sticker price parity arrives by 2031-32) requires deliberate upfront Crown seed:
u_pol = max(0, yr - 2023);
Rebate_Keep_NZD  = (yr == 2023) * 7015 + (yr >= 2024) .* max(0, 7015 * (0.82 .^ u_pol) .* (yr <= 2032));
Rebate_Boost_NZD = (yr == 2023) * 7015 ...
                 + ((yr >= 2024) & (yr <= 2027)) .* (7015 * (1.30 .^ u_pol)) ...
                 + (yr >  2027) .* (7015 * (1.30 ^ 4) * exp(-max(0, yr - 2027) / 4.0));

Feebate_Cost_Keep_PctGDP  = (yr == 2024) * 0.02 + (yr == 2025) * 0.01;
Feebate_Cost_Boost_PctGDP = (yr >= 2024) .* ( ...
    0.15 * ((1.30) .^ min(4, u_pol)) .* exp(-max(0, yr - 2027) / 3.4));

% Keen-Ayres Second-Law work efficiency (e_N = 0.88 vs e_F = 0.30):
Road_Fossil_Base_B  = 9.8 * ((1.008) .^ (yr - 2026));
exergy_keep_factor  = (1.0 - (0.30 / 0.88) * 0.22);
FX_Saved_Keep_Calm  = Road_Fossil_Base_B .* delta_ev_keep  * exergy_keep_factor;
FX_Saved_Boost_Calm = Road_Fossil_Base_B .* delta_ev_boost * exergy_keep_factor;

% -------------------------------------------------------------------------
% 3. Explicit Equilibrium vs. Strait of Hormuz Fossil Fuel Price Trajectories
% -------------------------------------------------------------------------
% Calm-water equilibrium assumptions (MBIE / IEA Reference + gradual real extraction/ETS drift):
Brent_Eq_USD  = 80.0 * ((1.0045) .^ (yr - 2023));   % ~US$80/bbl in 2023 -> ~US$96/bbl by 2065 (real 2026 USD)
Petrol_Eq_NZD = 2.66 * ((1.0050) .^ (yr - 2023));   % ~NZD 2.66-2.70/L retail regular petrol (incl. ETS/FED)
Diesel_Eq_NZD = 2.04 * ((1.0050) .^ (yr - 2023));   % ~NZD 2.04-2.07/L retail pump diesel (excl. RUC)

% Two-component Strait of Hormuz shock kernel starting March 2026:
%   1. Acute Gulf blockade & refinery crack-spread spike: tau_acute = 2.4 yrs (half-life ~1.66 yrs)
%   2. Structural maritime war-risk, rerouting & underinvestment tail: tau_tail = 22.0 yrs
u_shk       = yr - 2026;
Acute_Pulse = (yr >= 2026) .* exp(-max(0, u_shk - 0.35) / 2.4);
Tail_Plat   = (yr >= 2026) .* (1.0 - exp(-max(0, u_shk) / 1.4)) .* exp(-max(0, u_shk) / 22.0);

% Differentiated crude, petrol (+38% YoY Oct 2026), and middle-distillate diesel (+71.2% YoY Oct 2026) multipliers:
Mult_Brent  = 0.38 * Acute_Pulse + 0.15 * Tail_Plat; % Peaks ~US$113/bbl in 2026, ~US$93/bbl in 2031
Mult_Petrol = 0.36 * Acute_Pulse + 0.13 * Tail_Plat; % Peaks ~NZD 3.70/L (+38% YoY in 2026)
Mult_Diesel = 0.68 * Acute_Pulse + 0.18 * Tail_Plat; % Peaks ~NZD 3.51/L (+71% YoY middle-distillate crunch!)

% Fleet-weighted composite imported fuel shock multiplier (55% petrol / 45% diesel freight+utes):
Hormuz_Price_Mult = 0.55 * Mult_Petrol + 0.45 * Mult_Diesel;

Brent_Shock_USD  = Brent_Eq_USD  .* (1.0 + Mult_Brent);
Petrol_Shock_NZD = Petrol_Eq_NZD .* (1.0 + Mult_Petrol);
Diesel_Shock_NZD = Diesel_Eq_NZD .* (1.0 + Mult_Diesel);

% Composite Retail Fuel Index (Real 2026 NZD / Litre, fleet-weighted):
FuelPrice_Eq_NZD_L    = 0.55 * Petrol_Eq_NZD    + 0.45 * Diesel_Eq_NZD;
FuelPrice_Shock_NZD_L = 0.55 * Petrol_Shock_NZD + 0.45 * Diesel_Shock_NZD;

% -------------------------------------------------------------------------
% 4. Assemble the 6 Cumulative Net Core Crown Debt (% of GDP) Trajectories
% -------------------------------------------------------------------------
dt_mat   = yr - yr';
Comp_Mat = (dt_mat >= 0) .* ((1.0165) .^ max(0, dt_mat)); % r - g snowball operator

% Direct fiscal + macro shock impulse (% of GDP/yr) under actual low-EV fleet (Repeal CCD):
Fiscal_Shock_Flow_Repeal = (yr == 2026) * (-0.45) ... % FY26 nominal GDP inflation denominator dip -> 40.9% actual
    + (yr == 2027) * 2.15 ...                         % PREFU 2026 jump: 40.9% -> 43.7% GDP (+$1.4B FED/RUC delay)
    + (yr == 2028) * 0.85 ...                         % Peak ~43.9% debt step + delayed RUC/FED revenue loss
    + (yr >= 2029) .* (0.62 * Hormuz_Price_Mult + 0.14);

% Shock attenuation scales directly with extra electrified fleet share during the spike & tail:
Atten_Keep  = min(0.55, 1.85 * delta_ev_keep  + 0.08 * (yr >= 2026));
Atten_Boost = min(0.88, 2.15 * delta_ev_boost + 0.16 * (yr >= 2026));

Fiscal_Shock_Flow_Keep  = (yr == 2026) * (-0.52) + (yr >= 2027) .* (Fiscal_Shock_Flow_Repeal .* (1.0 - Atten_Keep));
Fiscal_Shock_Flow_Boost = (yr == 2026) * (-0.58) + (yr >= 2027) .* (Fiscal_Shock_Flow_Repeal .* (1.0 - Atten_Boost));

% Calm-water net fiscal dividend (% of GDP/yr = Sovereign NFA/macro gain minus net Crown rebate outlay):
Annual_Div_Keep_Calm  = (FX_Saved_Keep_Calm  ./ GDP_Real26_B) * 100 * 0.42 - Feebate_Cost_Keep_PctGDP;
Annual_Div_Boost_Calm = (FX_Saved_Boost_Calm ./ GDP_Real26_B) * 100 * 0.46 - Feebate_Cost_Boost_PctGDP;

% --- Calm-Water Trio (No Hormuz Shocks) ---
Debt_1_Repeal_NoShock = Debt_LTFM_NoShock;
Debt_2_Keep_NoShock   = Debt_LTFM_NoShock - Comp_Mat * Annual_Div_Keep_Calm;
Debt_5_Boost_NoShock  = Debt_LTFM_NoShock - Comp_Mat * Annual_Div_Boost_Calm;

% --- Hormuz-Shocked Trio (With 2026 Strait of Hormuz Shocks) ---
Extra_FX_Shield_Keep  = (Road_Fossil_Base_B .* Hormuz_Price_Mult .* delta_ev_keep  ./ GDP_Real26_B) * 100 * 0.55;
Extra_FX_Shield_Boost = (Road_Fossil_Base_B .* Hormuz_Price_Mult .* delta_ev_boost ./ GDP_Real26_B) * 100 * 0.60;

Debt_3_Repeal_WithShock = Debt_LTFM_NoShock + Comp_Mat * Fiscal_Shock_Flow_Repeal;
Debt_3_Repeal_WithShock(yr == 2026) = 40.9; % Exact 30 June 2026 FSG outturn ($186.8B / 40.9%)

Debt_4_Keep_WithShock   = Debt_2_Keep_NoShock  + Comp_Mat * (Fiscal_Shock_Flow_Keep  - Extra_FX_Shield_Keep);
Debt_6_Boost_WithShock  = Debt_5_Boost_NoShock + Comp_Mat * (Fiscal_Shock_Flow_Boost - Extra_FX_Shield_Boost);

% Annual Road Fuel FX Outflows across all 6 states (Real 2026 NZD B/yr):
Fuel_1_Repeal_NoShock = Road_Fossil_Base_B .* (1.0 - 0.82 * ev_share_repeal);
Fuel_2_Keep_NoShock   = Road_Fossil_Base_B .* (1.0 - 0.82 * ev_share_keep);
Fuel_5_Boost_NoShock  = Road_Fossil_Base_B .* (1.0 - 0.82 * ev_share_boost);

Fuel_3_Repeal_WithShock = Fuel_1_Repeal_NoShock .* (1.0 + Hormuz_Price_Mult);
Fuel_4_Keep_WithShock   = Fuel_2_Keep_NoShock   .* (1.0 + Hormuz_Price_Mult);
Fuel_6_Boost_WithShock  = Fuel_5_Boost_NoShock  .* (1.0 + Hormuz_Price_Mult);

% -------------------------------------------------------------------------
% 5. Compact FX_NZD_per_USD & Downside Tail-Risk Sensitivity (Dec 2023 = 1.583)
% -------------------------------------------------------------------------
S0_Dec2023 = 1.583; % 31 Dec 2023 Clean Car Discount repeal anchor (NZD per 1 USD)

% Residual economy-wide imported hydrocarbon exposure (1 = 2023 fossil baseline;
% Boost + Domestic Rooftop/Farm Solar compresses fossil share to ~0.16 by 2040, ~0.06 by 2050):
Solar_Grid_Shield   = 1.0 ./ (1.0 + exp(-0.24 * (yr - 2033.5)));
Fossil_Exp_Repeal   = max(0.18, 1.0 - 0.78 * ev_share_repeal);
Fossil_Exp_Keep     = max(0.12, 1.0 - 0.84 * ev_share_keep);
Fossil_Exp_BoostSol = max(0.05, (1.0 - 0.88 * ev_share_boost) .* (1.0 - 0.68 * Solar_Grid_Shield));

% Cumulative NFA/Y FX bleed differential vs. Dec 2023 (% of GDP, scaled):
Cum_NFA_Drag_Repeal = cumsum(Fuel_3_Repeal_WithShock ./ GDP_Real26_B) * 0.0115;
Cum_NFA_Drag_Keep   = cumsum(Fuel_4_Keep_WithShock   ./ GDP_Real26_B) * 0.0095;
Cum_NFA_Drag_Boost  = cumsum(Fuel_6_Boost_WithShock  .* (1.0 - 0.55 * Solar_Grid_Shield) ./ GDP_Real26_B) * 0.0065;

% Dornbusch UIP + Global Risk-Off Wedge (calibrates Nov 2026 spot = 1.835 NZD/USD, tau_uip = 2.8 yrs):
UIP_Pulse_2026 = (yr >= 2024) .* interp1([2023; 2024; 2025; 2026; 2027], [0.0; 0.032; 0.058; 0.0955; 0.072], min(2027, yr), 'pchip') ...
               .* ((yr <= 2026) + (yr > 2026) .* exp(-max(0, yr - 2026) / 2.8));

% Central Hormuz + UIP FX Forecast (NZD per USD):
FX_Repeal_Central = S0_Dec2023 * exp(0.105 * Fossil_Exp_Repeal   .* Hormuz_Price_Mult + Cum_NFA_Drag_Repeal + UIP_Pulse_2026);
FX_Keep_Central   = S0_Dec2023 * exp(0.105 * Fossil_Exp_Keep     .* Hormuz_Price_Mult + Cum_NFA_Drag_Keep   + 0.94 * UIP_Pulse_2026);
FX_Boost_Central  = S0_Dec2023 * exp(0.105 * Fossil_Exp_BoostSol .* Hormuz_Price_Mult + Cum_NFA_Drag_Boost  + 0.88 * UIP_Pulse_2026);

% P95 Downside Sensitivity Envelope (Recurrent Geopolitical Oil + UIP Rate-Squeeze Stress):
% Notice: Downside wedge scales strictly with residual Fossil_Exp, collapsing to ~0.04 NZD/USD under Solar+EV!
Stress_Env = (yr >= 2026) .* (0.04 + 0.16 * (1.0 - exp(-max(0, yr - 2026) / 4.0)));
FX_Repeal_P95_Weak = FX_Repeal_Central .* exp(Stress_Env .* (0.35 + 0.95 * Fossil_Exp_Repeal));
FX_Keep_P95_Weak   = FX_Keep_Central   .* exp(Stress_Env .* (0.25 + 0.85 * Fossil_Exp_Keep));
FX_Boost_P95_Weak  = FX_Boost_Central  .* exp(Stress_Env .* (0.08 + 0.55 * Fossil_Exp_BoostSol));

L = struct();
L.Years                     = yr;
L.FX_Anchor_Dec2023         = S0_Dec2023;
L.FX_Repeal_Central         = FX_Repeal_Central;
L.FX_Keep_Central           = FX_Keep_Central;
L.FX_Boost_Central          = FX_Boost_Central;
L.FX_Repeal_P95_Weak        = FX_Repeal_P95_Weak;
L.FX_Keep_P95_Weak          = FX_Keep_P95_Weak;
L.FX_Boost_P95_Weak         = FX_Boost_P95_Weak;
L.Fossil_Exp_Repeal         = Fossil_Exp_Repeal;
L.Fossil_Exp_BoostSol       = Fossil_Exp_BoostSol;
L.Hormuz_Window             = [2026.15, 2028.50];
L.Tau_Acute_Yrs             = 2.4;
L.Tau_Tail_Yrs              = 22.0;

% 6 Debt Trajectories (% of GDP):
L.Debt_1_Repeal_NoShock     = Debt_1_Repeal_NoShock;
L.Debt_2_Keep_NoShock       = Debt_2_Keep_NoShock;
L.Debt_5_Boost_NoShock      = Debt_5_Boost_NoShock;
L.Debt_3_Repeal_WithShock   = Debt_3_Repeal_WithShock;
L.Debt_4_Keep_WithShock     = Debt_4_Keep_WithShock;
L.Debt_6_Boost_WithShock    = Debt_6_Boost_WithShock;

% Fossil Price Trajectories (Equilibrium vs. Hormuz Shocks):
L.Brent_Eq_USD              = Brent_Eq_USD;
L.Brent_Shock_USD           = Brent_Shock_USD;
L.Petrol_Eq_NZD             = Petrol_Eq_NZD;
L.Petrol_Shock_NZD          = Petrol_Shock_NZD;
L.Diesel_Eq_NZD             = Diesel_Eq_NZD;
L.Diesel_Shock_NZD          = Diesel_Shock_NZD;
L.FuelPrice_Eq_NZD_L        = FuelPrice_Eq_NZD_L;
L.FuelPrice_Shock_NZD_L     = FuelPrice_Shock_NZD_L;
L.Hormuz_Price_Mult         = Hormuz_Price_Mult;

% Fleet & Rebate Schedules:
L.EV_Share_Repeal           = ev_share_repeal;
L.EV_Share_Keep             = ev_share_keep;
L.EV_Share_Boost            = ev_share_boost;
L.Rebate_Keep_NZD           = Rebate_Keep_NZD;
L.Rebate_Boost_NZD          = Rebate_Boost_NZD;
L.Feebate_Cost_Boost_PctGDP = Feebate_Cost_Boost_PctGDP;

% FX Fuel Outflows (NZD B/yr):
L.Fuel_3_Repeal_WithShock_B = Fuel_3_Repeal_WithShock;
L.Fuel_4_Keep_WithShock_B   = Fuel_4_Keep_WithShock;
L.Fuel_6_Boost_WithShock_B  = Fuel_6_Boost_WithShock;

L.SummaryTable = table(yr, ...
    round(Debt_1_Repeal_NoShock,   2), ...
    round(Debt_2_Keep_NoShock,     2), ...
    round(Debt_5_Boost_NoShock,    2), ...
    round(Debt_3_Repeal_WithShock, 2), ...
    round(Debt_4_Keep_WithShock,   2), ...
    round(Debt_6_Boost_WithShock,  2), ...
    round(Brent_Eq_USD,            2), ...
    round(Brent_Shock_USD,         2), ...
    round(Petrol_Shock_NZD,        2), ...
    round(Diesel_Shock_NZD,        2), ...
    round(FX_Repeal_Central,       3), ...
    round(FX_Repeal_P95_Weak,      3), ...
    round(FX_Boost_Central,        3), ...
    round(FX_Boost_P95_Weak,       3), ...
    'VariableNames', {'Year', ...
                      'Debt_Repeal_NoShock_PctGDP', 'Debt_KeepCCD_NoShock_PctGDP', 'Debt_Boost30pct_NoShock_PctGDP', ...
                      'Debt_Actual_Repeal_Hormuz_PctGDP', 'Debt_KeepCCD_Hormuz_PctGDP', 'Debt_Boost30pct_Hormuz_PctGDP', ...
                      'Brent_Equil_USD_bbl', 'Brent_Hormuz_USD_bbl', 'Retail_Petrol_Hormuz_NZD_L', 'Retail_Diesel_Hormuz_NZD_L', ...
                      'FX_NZD_USD_Repeal_Central', 'FX_NZD_USD_Repeal_P95Tail', ...
                      'FX_NZD_USD_BoostSolar_Central', 'FX_NZD_USD_BoostSolar_P95Tail'});
end
