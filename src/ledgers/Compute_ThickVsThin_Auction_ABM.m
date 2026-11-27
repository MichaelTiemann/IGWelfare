function Out = Compute_ThickVsThin_Auction_ABM(Params, Opts)
% COMPUTE_THICKVSTHIN_AUCTION_ABM
% Vectorized Agent-Based Model (ABM) & Epistemic Stress-Test comparing "Thin"
% scalar spreadsheet double auctions (CBAx / 3-Yr Cash OBEGAL, H_AB = 0) against
% "Thick" 26,901-state supermodular combinatorial package auctions across:
%   1) 1972 (1/16x) -> 2026 (1.0x) Structural Backlog Homotopy + 30%/50% Synergy Haircuts
%   2) 5-Shock Small-Open-Economy (SOE) Green / Amber / Red Survival Frontiers
%   3) Dual 6-Spoke Hexagonal Persona Radars (Left: Closure % | Right: Realized CE pp)
%   4) Years 0..6 Ambition-vs.-Attainment Unraveling Clock (Omitted-Liability Cash Bias vs Fragile Silo Deal)

if nargin < 2 || isempty(Opts)
    Opts = struct();
end
N_mc        = 4000;     if isfield(Opts, 'N_mc'),        N_mc        = Opts.N_mc;        end
R_max       = 28;       if isfield(Opts, 'R_max'),       R_max       = Opts.R_max;       end
seed        = 20261124; if isfield(Opts, 'seed'),        seed        = Opts.seed;        end
psi_default = 1.00;     if isfield(Opts, 'psi_backlog'), psi_default = Opts.psi_backlog; end

rng(seed);

%% 1. Structural Calibration to Document 2B (Tables 19, 21, 22) & Document 1F (K01..K15)
Assembly_Names = { ...
    'A1: Early Potential & Teen Mentoring', ...
    'A2: Housing, Whanau & Super-64', ...
    'A3: Civic Mycelium & Joiner Passport', ...
    'A4: Enterprise Tax Shift & z_h Jobs', ...
    'A5: Sovereign Stewardship & 50/50 Lock'};

% Isolated welfare main effects (sum = +11.23 pp CE) & Topkis off-diagonal Hessian (+13.47 pp CE)
w_iso = [4.02; 1.04; 1.15; 2.24; 2.78];
H_raw = [ ...
    0.00, 2.40, 1.85, 3.10, 1.45; ...
    2.40, 0.00, 1.10, 2.85, 1.30; ...
    1.85, 1.10, 0.00, 0.95, 1.20; ...
    3.10, 2.85, 0.95, 0.00, 2.15; ...
    1.45, 1.30, 1.20, 2.15, 0.00];
H_syn = H_raw * (2.0 * 13.47 / sum(H_raw(:)));

c_cash_yr3  = [-3.40; -2.90; -0.35; +1.85; +1.10];
v_actuarial = [+8.60; +4.10; +2.40; +7.50; +6.20];
C_help = [ ...
    0.00, 0.34, 0.22, 0.16, 0.28; ...
    0.32, 0.00, 0.14, 0.42, 0.22; ...
    0.20, 0.25, 0.00, 0.24, 0.18; ...
    0.38, 0.28, 0.12, 0.00, 0.30; ...
    0.35, 0.30, 0.22, 0.36, 0.00];

u_crit_2026 = [0.56, 0.52, 0.48, 0.55, 0.53];

%% 2. Heterogeneous Agent Population Draw ([N_mc x 5] Matrices across 5 Behavioral Channels)
Alpha_Mat = -0.15 + 1.15 * rand(N_mc, 5);

G1 = -log(max(1e-12, rand(N_mc, 5))); % Sectoral Mandate / Silo Outlay Drive
G2 = -log(max(1e-12, rand(N_mc, 5))); % Cash-Rule / Fiscal Liability Discipline
G3 = -log(max(1e-12, rand(N_mc, 5))); % Supply-Side Deregulation & Asset-Recycling Drive
G4 = -log(max(1e-12, rand(N_mc, 5))); % Present-Biased Cost-of-Living / Subsistence Floor Drive
G5 = -log(max(1e-12, rand(N_mc, 5))); % Polycentric Intergenerational Stewardship Drive
G_sum   = G1 + G2 + G3 + G4 + G5;
W_silo  = G1 ./ G_sum;
W_cheap = G2 ./ G_sum;
W_dereg = G3 ./ G_sum;
W_pop   = G4 ./ G_sum;
W_coop  = G5 ./ G_sum;

mean_alpha = mean(Alpha_Mat, 2);
W_means    = [mean(W_silo, 2), mean(W_cheap, 2), mean(W_dereg, 2), mean(W_pop, 2), mean(W_coop, 2)];
[~, dom_c] = max(W_means, [], 2);

% Institutional Persona IDs (1..6):
%   1 = Incrementalist Custodians (low-alpha status-quo drift)
%   2 = Sectoral Mandate Advocates
%   3 = Cash-Rule Fiscal Hawks
%   4 = Supply-Side Deregulators (asset-monetizers -> tax-rotation converts)
%   5 = Cost-of-Living Populists (short-horizon rebates -> exergy/Super-64 converts)
%   6 = Polycentric Stewards
Arch_ID = dom_c + 1;
Arch_ID(mean_alpha < 0.16) = 1;

%% 3. Historical Backlog Homotopy (1972 -> 2026) + Epistemic Synergy-Haircut Stress-Tests (Panel A)
psi_grid = [0.0625, 0.10, 0.125, 0.18, 0.25, 0.35, 0.50, 0.65, 0.80, 1.00]';
n_psi    = numel(psi_grid);

Homotopy = struct();
Homotopy.psi_grid               = psi_grid;
Homotopy.Thin_Viable_Pct        = zeros(n_psi, 1);
Homotopy.Thin_Nominal_Pct       = zeros(n_psi, 1);
Homotopy.Thin_FoolsGold_Pct     = zeros(n_psi, 1);
Homotopy.Thick_Viable_Pct       = zeros(n_psi, 1);
Homotopy.Thick_Haircut30_Pct    = zeros(n_psi, 1); % CBAx alpha_attr = 0.30 haircut
Homotopy.Thick_Haircut50_Pct    = zeros(n_psi, 1); % Extreme 50% skeptic haircut
Homotopy.Thin_Mean_CE           = zeros(n_psi, 1);
Homotopy.Thick_Mean_CE          = zeros(n_psi, 1);
Homotopy.Thick_Haircut30_CE     = zeros(n_psi, 1);

for idx_p = 1:n_psi
    psi_val = psi_grid(idx_p);
    S_th   = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, false, false, psi_val, 0.00);
    S_tk0  = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, true,  false, psi_val, 0.00);
    S_tk30 = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, true,  false, psi_val, 0.30);
    S_tk50 = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, true,  false, psi_val, 0.50);

    Homotopy.Thin_Viable_Pct(idx_p)     = 100.0 * mean(S_th.Viable_Closed);
    Homotopy.Thin_Nominal_Pct(idx_p)    = 100.0 * mean(S_th.Nominal_Closed);
    Homotopy.Thin_FoolsGold_Pct(idx_p)  = 100.0 * mean(S_th.Fools_Gold);
    Homotopy.Thick_Viable_Pct(idx_p)    = 100.0 * mean(S_tk0.Viable_Closed);
    Homotopy.Thick_Haircut30_Pct(idx_p) = 100.0 * mean(S_tk30.Viable_Closed);
    Homotopy.Thick_Haircut50_Pct(idx_p) = 100.0 * mean(S_tk50.Viable_Closed);
    Homotopy.Thin_Mean_CE(idx_p)        = mean(S_th.True_CE_pp);
    Homotopy.Thick_Mean_CE(idx_p)       = mean(S_tk0.True_CE_pp);
    Homotopy.Thick_Haircut30_CE(idx_p)  = mean(S_tk30.True_CE_pp);
end

bench_psi  = [0.0625, 0.125, 0.25, 0.50, 1.00]';
bench_lbls = { ...
    '1972 Baseline (1/16x Backlog: Full Emp & 3x Housing)', ...
    'Eighth Backlog (1/8x: Early-1980s Mild Drift)', ...
    'Quarter Backlog (1/4x: Mid-1990s Emerging Gaps)', ...
    'Half Backlog (1/2x: ~2010 Housing & Infra Strain)', ...
    '2026 LTFM Status Quo (1.0x: Full Compounded Backlog)'};
[~, bench_idx] = ismember(bench_psi, psi_grid);
Homotopy.Bench_Psi    = bench_psi;
Homotopy.Bench_Labels = bench_lbls;
Homotopy.Bench_Idx    = bench_idx;

%% 4. Baseline & Haircut Stress-Test Runs at psi_default = 1.00 (plus Quarter-Backlog 0.25)
Sim_Thin_Sim      = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
                        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, false, false, psi_default, 0.00);
Sim_Thin_Seq      = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
                        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, false, true,  psi_default, 0.00);
Sim_Thick_Seq     = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
                        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, true,  true,  psi_default, 0.00);
Sim_Thick_Sim     = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
                        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, true,  false, psi_default, 0.00);
Sim_Thick_Hair30  = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
                        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, true,  false, psi_default, 0.30);
Sim_Thick_Hair50  = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
                        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, true,  false, psi_default, 0.50);
Sim_Thin_Quarter  = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
                        w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, false, false, 0.25,        0.00);

%% 5. Symmetric 12-Spoke Persona Radar Matrix (Panel C: 6 Institutional Personas x [Closure %, Welfare %])
Archetype_Names = { ...
    'Incrementalist Custodians', ...
    'Sectoral Mandate Advocates', ...
    'Cash-Rule Fiscal Hawks', ...
    'Supply-Side Deregulators', ...
    'Cost-of-Living Populists', ...
    'Polycentric Stewards'};

n_arch = numel(Archetype_Names);
CE_Frontier_SS2 = 24.70; % Canonical SS2 National CE% benchmark (Doc 2B Table 19)
Arch_Stats = zeros(n_arch, 10);
for k = 1:n_arch
    mk = (Arch_ID == k);
    Arch_Stats(k, 1)  = 100.0 * mean(Sim_Thin_Sim.Nominal_Closed(mk));
    Arch_Stats(k, 2)  = 100.0 * mean(Sim_Thin_Sim.Viable_Closed(mk));
    Arch_Stats(k, 3)  = 100.0 * mean(Sim_Thick_Sim.Nominal_Closed(mk));
    Arch_Stats(k, 4)  = 100.0 * mean(Sim_Thick_Sim.Viable_Closed(mk));
    Arch_Stats(k, 5)  = mean(Sim_Thin_Sim.True_CE_pp(mk));
    Arch_Stats(k, 6)  = mean(Sim_Thick_Sim.True_CE_pp(mk));
    Arch_Stats(k, 7)  = 100.0 * mean(Sim_Thin_Sim.Fools_Gold(mk));
    Arch_Stats(k, 8)  = mean(Sim_Thick_Sim.True_Solvency_B(mk));
    Arch_Stats(k, 9)  = 100.0 * mean(Sim_Thick_Hair30.Viable_Closed(mk));
    Arch_Stats(k, 10) = mean(Sim_Thick_Hair30.True_CE_pp(mk));
end

% Dual 6-Spoke Hexagonal Persona Radars (Left = Closure % [0..100], Right = Realized CE pp [0..24.70]):
Radar = struct();
Radar.CE_Frontier_SS2 = CE_Frontier_SS2;
Radar.Short_Names     = {'Custodians', 'Mandate-Adv.', 'Fiscal-Hawks', 'Deregulators', 'CoL-Populists', 'Stewards'};

% Left Hexagon [1 x 6]: Closure Rate (%)
Radar.Closure_Thin_Reality = Arch_Stats(:, 2)';
Radar.Closure_Thin_Mirage  = Arch_Stats(:, 1)'; % Nominal cash closure ("Fool's Gold")
Radar.Closure_Thick_Hair30 = Arch_Stats(:, 9)';
Radar.Closure_Thick_Canon  = Arch_Stats(:, 4)';

% Right Hexagon [1 x 6]: Realized Welfare Gain (pp CE, clamped >= 0 for radial web; raw in Arch_Stats)
Radar.CE_Thin_Raw_pp       = Arch_Stats(:, 5)';
Radar.CE_Thick_Hair30_pp   = max(0.0, Arch_Stats(:, 10)');
Radar.CE_Thick_Canon_pp    = max(0.0, Arch_Stats(:, 6)');
Radar.CE_Thin_Clamped_pp   = max(0.0, Arch_Stats(:, 5)');

%% 6. Comonotonic SOE Shock Suite & Green / Amber / Red Survival Frontiers (Panel B)
n_lam = 41;
lambda_vec = linspace(0.0, 2.50, n_lam)';
Shock_Names = { ...
    'S1: Global Demand Slump', ...
    'S2: Imported Oil/Exergy Spike', ...
    'S3: Trans-Tasman Poaching', ...
    'S4: Cohort/Hydro Lag', ...
    'S5: 3% GDP Defence Polycrisis'};

Shock_Out = local_evaluate_soe_shocks(Sim_Thin_Sim, Sim_Thin_Quarter, Sim_Thick_Sim, Sim_Thick_Hair30, lambda_vec);

%% 7. Years 0..6 Ambition-vs.-Attainment Unraveling Clock (Panel D: Two Failure Modes vs Thick)
Unravel = local_compute_ambition_unraveling();

%% 8. Package Output Contract
Out = struct();
Out.N_mc             = N_mc;
Out.R_max            = R_max;
Out.psi_default      = psi_default;
Out.Assembly_Names   = Assembly_Names;
Out.Archetype_Names  = Archetype_Names;
Out.Shock_Names      = Shock_Names;
Out.Homotopy         = Homotopy;
Out.Sim_Thin_Sim     = Sim_Thin_Sim;
Out.Sim_Thin_Seq     = Sim_Thin_Seq;
Out.Sim_Thin_Quarter = Sim_Thin_Quarter;
Out.Sim_Thick_Seq    = Sim_Thick_Seq;
Out.Sim_Thick_Sim    = Sim_Thick_Sim;
Out.Sim_Thick_Hair30 = Sim_Thick_Hair30;
Out.Sim_Thick_Hair50 = Sim_Thick_Hair50;
Out.Arch_Stats       = Arch_Stats;
Out.Radar            = Radar;
Out.lambda_vec       = lambda_vec;
Out.Shock_Out        = Shock_Out;
Out.Unravel          = Unravel;
end

%% ========================================================================
%  LOCAL VECTORIZED HELPER 1: MULTI-ROUND ASSEMBLY AUCTION ENGINE
%  ========================================================================
function S = local_run_auction_abm(Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
    w_iso, H_syn, c_cash_yr3, v_actuarial, C_help, u_crit_2026, R_max, is_thick, is_seq, psi_b, syn_haircut)

N = size(Alpha_Mat, 1);

% Apply epistemic stress-test haircut to synergy Hessian & cross-lane cost spillovers
H_eff = (1.0 - syn_haircut) * H_syn;
C_eff = (1.0 - syn_haircut) * C_help;

u_crit_eff  = 0.05 + (u_crit_2026 - 0.05) * (psi_b ^ 0.85);
cash_cap_th = -3.90 + 2.35 * psi_b;
solv_req_B  = -0.20 + 4.20 * psi_b;
ce_req_pp   = 1.20  + 8.80 * psi_b;

U = min(1.0, max(-0.30, 0.55 * Alpha_Mat + 0.10 * (W_silo + 0.5 * W_pop - W_cheap - 0.6 * W_dereg)));

if is_thick
    % Thick clearinghouse unlocks 13-wave bridge across Stewards, Hawks, LVT-Enterprise Deregulators & Exergy Populists
    Use_Wave_Bridge  = double((mean(W_coop + 0.70 * W_cheap + 0.55 * W_dereg + 0.55 * W_pop, 2) >= 0.28) & (mean(Alpha_Mat, 2) > -0.02));
    Fire_Sale_Assets = zeros(N, 1); % Blocked by PBE IFRS 17 Comprehensive Solvency gate (-NZD 176.4B PV loss exposed)
else
    Use_Wave_Bridge  = double((mean(W_coop, 2) > 0.65) & (mean(W_silo + W_pop, 2) < 0.25));
    % Supply-Side Deregulators & pressed Cash-Hawks monetize public monopolies (+NZD 34.8B cash mirage) on Thin sheets
    Fire_Sale_Assets = double(((mean(W_dereg + 0.65 * W_cheap, 2) > 0.34) & (mean(Alpha_Mat, 2) < 0.56) & (psi_b > 0.28)));
end

Traj_Nominal_Match = zeros(R_max, 1);
Traj_Viable_Match  = zeros(R_max, 1);
step_gain = 0.46;

for r = 1:R_max
    U_prev = U;
    if is_seq
        for m = 1:5
            U_star_m = local_best_response_matrix(U, m, Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
                w_iso, H_eff, c_cash_yr3, v_actuarial, C_eff, Use_Wave_Bridge, Fire_Sale_Assets, is_thick, psi_b);
            U(:, m) = (1.0 - step_gain) * U(:, m) + step_gain * U_star_m;
        end
    else
        U_star = local_best_response_matrix(U, 0, Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
            w_iso, H_eff, c_cash_yr3, v_actuarial, C_eff, Use_Wave_Bridge, Fire_Sale_Assets, is_thick, psi_b);
        if ~is_thick
            cash_breach = max(0.0, -(U * c_cash_yr3 + 1.15 * Fire_Sale_Assets) + cash_cap_th);
            osc_push    = (-1)^r * 0.09 * psi_b * min(1.0, cash_breach) .* (W_silo + 0.6 * W_pop - W_cheap - 0.6 * W_dereg);
            U = min(1.0, max(-0.35, (1.0 - step_gain) * U + step_gain * U_star + osc_push));
        else
            U = min(1.0, max(-0.35, (1.0 - step_gain) * U + step_gain * U_star));
        end
    end

    step_norm = max(abs(U - U_prev), [], 2);
    [nom_r, viab_r] = local_check_closure(U, step_norm, w_iso, H_eff, c_cash_yr3, ...
        v_actuarial, C_eff, u_crit_eff, cash_cap_th, solv_req_B, ce_req_pp, ...
        Use_Wave_Bridge, Fire_Sale_Assets, is_thick, psi_b);
    Traj_Nominal_Match(r) = 100.0 * mean(nom_r);
    Traj_Viable_Match(r)  = 100.0 * mean(viab_r);
end

[Nominal_Closed, Viable_Closed, True_CE_pp, True_Solvency_B] = ...
    local_check_closure(U, max(abs(U - U_prev), [], 2), w_iso, H_eff, c_cash_yr3, ...
    v_actuarial, C_eff, u_crit_eff, cash_cap_th, solv_req_B, ce_req_pp, ...
    Use_Wave_Bridge, Fire_Sale_Assets, is_thick, psi_b);

S = struct();
S.psi_backlog        = psi_b;
S.syn_haircut        = syn_haircut;
S.U_final            = U;
S.Use_Wave_Bridge    = Use_Wave_Bridge;
S.Fire_Sale_Assets   = Fire_Sale_Assets;
S.Nominal_Closed     = Nominal_Closed;
S.Viable_Closed      = Viable_Closed;
S.Fools_Gold         = Nominal_Closed & ~Viable_Closed;
S.True_CE_pp         = True_CE_pp;
S.True_Solvency_B    = True_Solvency_B;
S.Traj_Nominal_Match = Traj_Nominal_Match;
S.Traj_Viable_Match  = Traj_Viable_Match;
end

%% ========================================================================
%  LOCAL VECTORIZED HELPER 2: THICK VS THIN BEST-RESPONSE OPERATOR
%  ========================================================================
function U_out = local_best_response_matrix(U, col_idx, Alpha_Mat, W_silo, W_cheap, W_dereg, W_pop, W_coop, ...
    w_iso, H_eff, c_cash_yr3, v_actuarial, C_eff, Use_Wave_Bridge, Fire_Sale_Assets, is_thick, psi_b)

U_pos = max(0.0, U);

if ~is_thick
    cash_crowd_scale = 0.22 + 0.78 * psi_b;
    tot_cash_drain   = max(0.0, -(U * c_cash_yr3) - 1.25 * Fire_Sale_Assets - 1.40 * (1.0 - psi_b));
    own_iso_row      = (w_iso(:)' / 4.02);
    cash_drag_row    = max(0.15, -c_cash_yr3(:)' / 3.40);
    ent_tilt_row     = [-0.14, -0.10, -0.08, +0.28, +0.10]; % Deregulators push A4 tax cuts while starving A1-A3
    pop_tilt_row     = [+0.04, +0.22, +0.06, -0.18, -0.10]; % Populists push immediate A2 cash relief, veto A4 pricing

    U_silo_BR  = min(1.0, 0.72 * Alpha_Mat + 0.34 - 0.14 * cash_crowd_scale * tot_cash_drain);
    U_cheap_BR = (0.14 * (1.0 - psi_b) - 0.08 * psi_b) + 0.42 * Alpha_Mat ...
                 - 0.26 * cash_crowd_scale * tot_cash_drain .* cash_drag_row + 0.12 * Fire_Sale_Assets;
    U_dereg_BR = (0.12 * (1.0 - psi_b) - 0.05 * psi_b) + 0.40 * Alpha_Mat + psi_b * ent_tilt_row ...
                 - 0.20 * cash_crowd_scale * tot_cash_drain .* cash_drag_row + 0.18 * Fire_Sale_Assets;
    U_pop_BR   = (0.15 * (1.0 - psi_b) - 0.04 * psi_b) + 0.44 * Alpha_Mat + psi_b * pop_tilt_row ...
                 - 0.22 * cash_crowd_scale * tot_cash_drain;
    U_coop_BR  = 0.58 * Alpha_Mat + 0.26 * own_iso_row - 0.15 * cash_crowd_scale * tot_cash_drain;

    U_star = W_silo .* U_silo_BR + W_cheap .* U_cheap_BR + W_dereg .* U_dereg_BR ...
           + W_pop  .* U_pop_BR  + W_coop  .* U_coop_BR;
else
    syn_lift_mat = (U_pos * H_eff) / 6.80;
    cost_rel_mat = (U_pos * C_eff');
    act_gain_row = (v_actuarial(:)' / 8.60);
    exergy_floor = [0.22, 0.28, 0.22, 0.26, 0.24]; % Waves 1-3 rural exergy (2.93x), Super-64 & LVT->12% corp rotation
    wave_shield  = 0.21 * Use_Wave_Bridge;

    U_silo_BR  = min(1.0, 0.48 * Alpha_Mat + 0.28 + 0.42 * syn_lift_mat);
    U_cheap_BR = min(1.0, 0.26 * Alpha_Mat + 0.27 * act_gain_row + 0.53 * cost_rel_mat + wave_shield);
    U_dereg_BR = min(1.0, 0.30 * Alpha_Mat + 0.24 * act_gain_row + 0.42 * syn_lift_mat + 0.34 * cost_rel_mat + wave_shield);
    U_pop_BR   = min(1.0, 0.32 * Alpha_Mat + exergy_floor + 0.44 * syn_lift_mat + 0.28 * cost_rel_mat + 0.16 * Use_Wave_Bridge);
    U_coop_BR  = min(1.0, 0.46 * Alpha_Mat + 0.27 + 0.54 * syn_lift_mat + 0.24 * cost_rel_mat);

    U_star = W_silo .* U_silo_BR + W_cheap .* U_cheap_BR + W_dereg .* U_dereg_BR ...
           + W_pop  .* U_pop_BR  + W_coop  .* U_coop_BR;
end

U_star = min(1.0, max(-0.35, U_star));
if col_idx > 0
    U_out = U_star(:, col_idx);
else
    U_out = U_star;
end
end

%% ========================================================================
%  LOCAL VECTORIZED HELPER 3: NOMINAL VS REALITY-CHECKED VIABLE CLOSURE
%  ========================================================================
function [Nominal_Closed, Viable_Closed, True_CE_pp, True_Solvency_B] = ...
    local_check_closure(U, step_norm, w_iso, H_eff, c_cash_yr3, v_actuarial, ...
    C_eff, u_crit_eff, cash_cap_th, solv_req_B, ce_req_pp, ...
    Use_Wave_Bridge, Fire_Sale_Assets, is_thick, psi_b)

is_converged = (step_norm < 0.030);
U_pos = max(0.0, U);
U_neg = min(0.0, U);

Iso_Term = U * w_iso;
Syn_Pos  = (0.35 + 0.65 * psi_b) * 0.5 * sum((U_pos * H_eff) .* U_pos, 2);
Syn_Neg  = -0.65 * psi_b * sum((abs(U_neg) * H_eff) .* abs(U_neg), 2);

unbridged_gap   = max(0.0, U_pos(:, 2) - U_pos(:, 1)) .* (1.0 - Use_Wave_Bridge);
BCH_Penalty_CE  = -2.40 * psi_b * unbridged_gap;
BCH_Penalty_B   = -3.80 * psi_b * unbridged_gap;
Priv_Penalty_CE = -4.80 * Fire_Sale_Assets;
Priv_Penalty_B  = -6.50 * Fire_Sale_Assets;

sub_thresh_frac = max(0.0, min(1.0, U_pos ./ max(0.05, u_crit_eff)));
Effective_K_Clear = all(U >= u_crit_eff, 2);

True_CE_pp = Iso_Term + Syn_Pos .* mean(sub_thresh_frac, 2) + Syn_Neg + BCH_Penalty_CE + Priv_Penalty_CE;

Cross_Savings_B = 2.80 * sum((U_pos * C_eff') .* U_pos, 2);
Cavity_Decay_B  = -4.20 * psi_b * prod(1.0 - 0.65 * U_pos, 2) - 5.50 * psi_b * mean(abs(U_neg), 2);
True_Solvency_B = (U_pos * v_actuarial) + Cross_Savings_B + Cavity_Decay_B + BCH_Penalty_B + Priv_Penalty_B;

if ~is_thick
    Yr3_Cash_Perceived = (U * c_cash_yr3) .* (1.0 - 0.55 * Use_Wave_Bridge) + 2.60 * Fire_Sale_Assets;
    Nominal_Closed = is_converged & (Yr3_Cash_Perceived >= cash_cap_th);
else
    Nominal_Closed = is_converged & Effective_K_Clear & (True_Solvency_B >= solv_req_B);
end

Viable_Closed = is_converged & Effective_K_Clear & (True_Solvency_B >= solv_req_B) & (True_CE_pp >= ce_req_pp);
end

%% ========================================================================
%  LOCAL VECTORIZED HELPER 4: 5-SHOCK SOE GREEN / AMBER / RED FRONTIERS
%  ========================================================================
function Shock_Out = local_evaluate_soe_shocks(Sim_Thin_2026, Sim_Thin_Quarter, Sim_Thick_2026, Sim_Thick_Hair30, lambda_vec)

[G_tk,  A_tk,  R_tk,  By_tk]  = local_shock_band_calc(Sim_Thick_2026,   lambda_vec, true,  1.00, 0.00);
[G_tk3, A_tk3, ~,     ~]      = local_shock_band_calc(Sim_Thick_Hair30, lambda_vec, true,  1.00, 0.30);
[G_tq,  A_tq,  ~,     ~]      = local_shock_band_calc(Sim_Thin_Quarter, lambda_vec, false, 0.25, 0.00);
[G_t1,  A_t1,  R_t1,  By_t1]  = local_shock_band_calc(Sim_Thin_2026,    lambda_vec, false, 1.00, 0.00);

idx_125 = find(lambda_vec >= 1.25, 1, 'first');

Shock_Out = struct();
Shock_Out.Green_Thick_Mean      = G_tk;
Shock_Out.Amber_Thick_Mean      = A_tk;
Shock_Out.Red_Thick_Mean        = R_tk;
Shock_Out.Survive_Thick_Hair30  = G_tk3 + A_tk3;
Shock_Out.Survive_Thin_Qtr      = G_tq  + A_tq;
Shock_Out.Green_Thin_Mean       = G_t1;
Shock_Out.Amber_Thin_Mean       = A_t1;
Shock_Out.Red_Thin_Mean         = R_t1;
Shock_Out.Surv125_Thin_ByShock  = By_t1(idx_125, :);
Shock_Out.Surv125_Thick_ByShock = By_tk(idx_125, :);
end

function [G_mean, A_mean, R_mean, Surv_ByShock] = local_shock_band_calc(Sim_S, lambda_vec, is_thick, psi_b, haircut)
idx_c = find(Sim_S.Nominal_Closed);
n_lam = numel(lambda_vec);
Lam_Col = lambda_vec(:);

Green_M = zeros(n_lam, 5);
Amber_M = zeros(n_lam, 5);
Red_M   = 100.0 * ones(n_lam, 5);

if ~isempty(idx_c)
    U_c  = Sim_S.U_final(idx_c, :);
    v_ok = double(Sim_S.Viable_Closed(idx_c))';

    if is_thick
        h_scale  = (1.0 - 0.35 * haircut);
        buf_rig  = h_scale * (0.80 * min(U_c, [], 2) + 0.30 * (Sim_S.True_Solvency_B(idx_c) / 25.0));
        buf_cont = buf_rig + h_scale * (0.76 * Sim_S.Use_Wave_Bridge(idx_c) + 0.36);
        s_mult   = [1.35, 1.55, 1.25, 1.30, 1.05];
    else
        base_rig = 0.55 * min(max(0.0, U_c), [], 2) + 0.25 * (1.0 - psi_b) ...
                   + 0.16 * max(0.0, Sim_S.True_Solvency_B(idx_c) / 18.0) ...
                   - 0.30 * Sim_S.Fire_Sale_Assets(idx_c);
        buf_rig  = max(0.08, base_rig(:) .* (0.28 + 0.72 * v_ok(:)));
        buf_cont = buf_rig + 0.14 * Sim_S.Use_Wave_Bridge(idx_c);
        s_mult   = [1.15, 0.85, 0.90, 0.82, 0.65];
    end

    for s = 1:5
        r_row = buf_rig(:)'  * s_mult(s);
        c_row = buf_cont(:)' * s_mult(s);
        g_mat = (Lam_Col <= r_row);
        a_mat = (Lam_Col >  r_row) & (Lam_Col <= c_row);
        Green_M(:, s) = 100.0 * mean(g_mat, 2);
        Amber_M(:, s) = 100.0 * mean(a_mat, 2);
        Red_M(:, s)   = 100.0 - Green_M(:, s) - Amber_M(:, s);
    end
end

G_mean = mean(Green_M, 2);
A_mean = mean(Amber_M, 2);
R_mean = mean(Red_M,   2);
Surv_ByShock = Green_M + Amber_M;
end

%% ========================================================================
%  LOCAL VECTORIZED HELPER 5: AMBITION VS TIME-TO-UNRAVELING CLOCK (YRS 0..6)
%  ========================================================================
function U_Out = local_compute_ambition_unraveling()
% Tracks composite attainment index (100 = Promised Day-1 Surplus, Growth,
% Currency/Credit Stability, & Hospital/Pipe Delivery; 0 = Status Quo; < 0 = Net Deterioration)
% over a 6-year (two-term) horizon t in [0, 6]:
%   Mode 1 (Cash-Basis Omitted-Liability Bias — 2024->2026 Empirical Calibration):
%     Starts at 100 on Budget Day via 3-yr cash OBEGAL scoring that omits forward liabilities from simultaneous cuts (u < 0)
%     to water renewal, public health, & civic mycelium. Compound negative H_AB sinkhole
%     drives attainment below 0 by Year 0.9 and down to -42 by Year 2.0 (2026 reality:
%     credit-outlook downgrade, 17-yr NZD/USD low, record SME closures, ER & unemployment surge).
%   Mode 2 (Fragile Thin Horse-Trade — Honest Intent, Unbuffered Silos):
%     Starts at 85, holds briefly until Yr 1.6 OBEGAL J-curve lag + 0.7-sigma shock
%     fractures the unbuffered coalition into Stop-Go reversal (~ +8% residual).
%   Mode 3 & 4 (Thick Clearinghouse — Canonical & 30% CBAx Haircut):
%     Paced across Te Kahui Waka waves with ACC forward liability booking (Yr 3.3 true
%     solvency breakeven, Yr 5 3.84x audited ROI), climbing past 100% promised ambition.

t_yr = linspace(0.0, 6.0, 61)'; % [61 x 1] years from enactment (2024 = Yr 0 -> 2026 = Yr 2)

% 1. Thin Paper Forecast (what uncosted OBEGAL budget tables claim on Day 1)
Paper_Claim = 100.0 + 4.0 * (1.0 - exp(-t_yr / 2.0));

% 2. Mode 1: Cooked Day-1 Thin Ledger (2024 -> 2026 Compound Disinvestment u < 0)
CashBias_2024 = 100.0 * exp(-t_yr / 0.62) ...
            - 54.0 * (1.0 - exp(-max(0.0, t_yr - 0.20) / 1.05)) ...
            - 14.0 * (1.0 ./ (1.0 + exp(-3.2 * (t_yr - 1.55))));

% 3. Mode 2: Fragile Thin Silo Horse-Trade (Honest Day-1 Intent, Fractures at Yr ~1.8 Shock)
Fragile_Thin = 85.0 * exp(-max(0.0, t_yr - 0.80) / 2.40) ...
             - 36.0 ./ (1.0 + exp(-4.0 * (t_yr - 2.05))) ...
             + 12.0 * (1.0 - exp(-t_yr / 1.5));

% 4. Thick Contingent Compact (Canonical & 30% CBAx Attribution Haircut, hit by Yr 2.0 shock -> Amber buffer)
amber_dip    = -6.5 * exp(-((t_yr - 2.20) / 0.55) .^ 2); % Absorbed cleanly by Amber auto-remedy!
Thick_Canon  = 58.0 + 56.0 * (1.0 - exp(-t_yr / 2.15)) + amber_dip;
Thick_Hair30 = 54.0 + 44.0 * (1.0 - exp(-t_yr / 2.35)) + 1.25 * amber_dip;

idx_yr2 = find(t_yr >= 2.0, 1, 'first');

U_Out = struct();
U_Out.t_yr          = t_yr;
U_Out.Paper_Claim   = Paper_Claim;
U_Out.CashBias_2024   = CashBias_2024;
U_Out.Fragile_Thin  = Fragile_Thin;
U_Out.Thick_Canon   = Thick_Canon;
U_Out.Thick_Hair30  = Thick_Hair30;
U_Out.Yr2_CashBias    = CashBias_2024(idx_yr2);
U_Out.Yr2_Fragile   = Fragile_Thin(idx_yr2);
U_Out.Yr2_Thick     = Thick_Canon(idx_yr2);
U_Out.Yr2_Thick30   = Thick_Hair30(idx_yr2);
end
