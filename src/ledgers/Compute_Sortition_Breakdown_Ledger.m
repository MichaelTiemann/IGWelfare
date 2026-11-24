function Out = Compute_Sortition_Breakdown_Ledger(Params, Opts)
% COMPUTE_SORTITION_BREAKDOWN_LEDGER
% Pure vectorized Byzantine fault-tolerance, hypergeometric/stratified sortition
% tail-risk, recruitment-bias, and 4-of-5 Sub-Lattice Quarantine diagnostic for
% the Five Parallel Citizens' Assemblies (Document 1F Part V & Document 2B).
%
% Evaluates four institutional resilience dimensions:
%   1) Adversarial Privateer Infiltration Curve (phi_priv in [0, 0.60]) across
%      M = 5 parallel assemblies (N_A = 100 stratified vs N_A = 12 elite committee)
%   2) Assembly Size Sweep (N_A in [10, 150]): Stratified vs Unstratified Variance
%   3) Volunteer Response-Bias Stress-Test (Odds Ratio OR_bias in [1.0, 5.0]x):
%      Raw Self-Selected Volunteers vs Stats NZ / Electoral-Roll Quota Stratification
%   4) Mechanism 3.2 — Captured-Lane Quarantine & Graceful 4-of-5 Sub-Lattice
%      Degradation (PBE IFRS 17 blocks -NZD 176.4B fire-sales; 4-of-5 sub-compact clears)

if nargin < 2 || isempty(Opts)
    Opts = struct();
end

M_lanes     = 5;    if isfield(Opts, 'M_lanes'),     M_lanes     = Opts.M_lanes;     end
N_A_default = 100;  if isfield(Opts, 'N_A'),         N_A_default = Opts.N_A;         end
R2_strata   = 0.38; if isfield(Opts, 'R2_strata'),   R2_strata   = Opts.R2_strata;   end
p_gf_canon  = 0.965; % Good-faith citizen agreement rate on Thick ledger (from 6-persona ABM)
p_gf_hair30 = 0.925; % Good-faith citizen agreement rate under -30% CBAx synergy haircut

%% 1. Panel A: Byzantine Breakdown Curve Across Privateer Share phi_priv in [0, 0.60]
phi_grid = linspace(0.0, 0.60, 121)';

% Vectorized 5-lane joint clearance probability P(All 5 Assemblies >= tau_vote):
Clear_Strat_67   = local_joint_clear_prob(phi_grid, N_A_default, 2/3,  p_gf_canon,  R2_strata, M_lanes);
Clear_Strat_75   = local_joint_clear_prob(phi_grid, N_A_default, 0.75, p_gf_canon,  R2_strata, M_lanes);
Clear_Strat_50   = local_joint_clear_prob(phi_grid, N_A_default, 0.50, p_gf_canon,  R2_strata, M_lanes);
Clear_Hair30_67  = local_joint_clear_prob(phi_grid, N_A_default, 2/3,  p_gf_hair30, R2_strata, M_lanes);
Clear_Small12_67 = local_joint_clear_prob(phi_grid, 12,          2/3,  p_gf_canon,  0.00,      M_lanes);

% On a Thin scalar spreadsheet, good-faith delegates split ~48% and asset-sale mirages capture the room:
Thin_Viable_Curve  = zeros(size(phi_grid));
Thin_FireSale_Risk = 100.0 * (1.0 - exp(-9.5 * (phi_grid + 0.04)));

% Exact 50%-reliability breakdown thresholds (phi* where 5-lane clearance crosses 50%):
phi_star_50     = local_crossing_point(phi_grid, Clear_Strat_50,   50.0);
phi_star_67     = local_crossing_point(phi_grid, Clear_Strat_67,   50.0);
phi_star_75     = local_crossing_point(phi_grid, Clear_Strat_75,   50.0);
phi_star_hair30 = local_crossing_point(phi_grid, Clear_Hair30_67,  50.0);
phi_star_sm12   = local_crossing_point(phi_grid, Clear_Small12_67, 50.0);

Breakdown = struct();
Breakdown.phi_grid           = phi_grid;
Breakdown.Clear_Strat_50     = Clear_Strat_50;
Breakdown.Clear_Strat_67     = Clear_Strat_67;
Breakdown.Clear_Strat_75     = Clear_Strat_75;
Breakdown.Clear_Hair30_67    = Clear_Hair30_67;
Breakdown.Clear_Small12_67   = Clear_Small12_67;
Breakdown.Thin_Viable_Curve  = Thin_Viable_Curve;
Breakdown.Thin_FireSale_Risk = Thin_FireSale_Risk;
Breakdown.phi_star_50        = phi_star_50;
Breakdown.phi_star_67        = phi_star_67;
Breakdown.phi_star_75        = phi_star_75;
Breakdown.phi_star_hair30    = phi_star_hair30;
Breakdown.phi_star_sm12      = phi_star_sm12;

%% 2. Panel B: Assembly Size Sweep N_A in [10, 150] (Law of Large Numbers + Stratification)
N_grid = (10:2:150)';
n_ng   = numel(N_grid);
SizeSweep = struct();
SizeSweep.N_grid            = N_grid;
SizeSweep.Strat_Phi15_67    = zeros(n_ng, 1);
SizeSweep.Unstrat_Phi15_67  = zeros(n_ng, 1);
SizeSweep.Strat_Phi22_67    = zeros(n_ng, 1);
SizeSweep.Unstrat_Phi22_67  = zeros(n_ng, 1);

for i = 1:n_ng
    na = N_grid(i);
    SizeSweep.Strat_Phi15_67(i)   = local_joint_clear_prob(0.15, na, 2/3, p_gf_canon, R2_strata, M_lanes);
    SizeSweep.Unstrat_Phi15_67(i) = local_joint_clear_prob(0.15, na, 2/3, p_gf_canon, 0.00,      M_lanes);
    SizeSweep.Strat_Phi22_67(i)   = local_joint_clear_prob(0.22, na, 2/3, p_gf_canon, R2_strata, M_lanes);
    SizeSweep.Unstrat_Phi22_67(i) = local_joint_clear_prob(0.22, na, 2/3, p_gf_canon, 0.00,      M_lanes);
end

idx_12  = find(N_grid == 12,  1);
idx_100 = find(N_grid == 100, 1);
SizeSweep.Clear_N12_Phi15_Unstrat = SizeSweep.Unstrat_Phi15_67(idx_12);
SizeSweep.Clear_N100_Phi15_Strat  = SizeSweep.Strat_Phi15_67(idx_100);
SizeSweep.Clear_N12_Phi22_Unstrat = SizeSweep.Unstrat_Phi22_67(idx_12);
SizeSweep.Clear_N100_Phi22_Strat  = SizeSweep.Strat_Phi22_67(idx_100);

%% 3. Panel C: Differential Recruitment / Volunteer Bias Stress-Test (OR_bias in [1.0, 5.0]x)
% Base true population Privateer share phi_0 = 0.12 (12% extractive rent-seekers).
% Under raw unweighted volunteering, Privateer seat share rises via odds ratio:
%   phi_raw(OR) = (OR * phi_0) / (1 - phi_0 + OR * phi_0).
% Under Stats NZ / Electoral Roll quota stratification (Age x Region x Income/Tenure x Whakapapa),
% within-cell residual unobserved selection retains only (1 - kappa_quota) = 18% of raw log-odds tilt!
phi_base_pop = 0.12;
OR_grid      = linspace(1.0, 5.0, 81)';
kappa_quota  = 0.82; % 82% observable demographic/tenure bias absorption via stratified replacement

phi_eff_raw   = (OR_grid * phi_base_pop) ./ ((1.0 - phi_base_pop) + OR_grid * phi_base_pop);
OR_resid      = OR_grid .^ (1.0 - kappa_quota);
phi_eff_quota = (OR_resid * phi_base_pop) ./ ((1.0 - phi_base_pop) + OR_resid * phi_base_pop);

Clear_Raw_Vol     = local_joint_clear_prob(phi_eff_raw,   N_A_default, 2/3, p_gf_canon, 0.00,      M_lanes);
Clear_Quota_Strat = local_joint_clear_prob(phi_eff_quota, N_A_default, 2/3, p_gf_canon, R2_strata, M_lanes);
Clear_Quota_H30   = local_joint_clear_prob(phi_eff_quota, N_A_default, 2/3, p_gf_hair30,R2_strata, M_lanes);

SelectionBias = struct();
SelectionBias.phi_base_pop      = phi_base_pop;
SelectionBias.OR_grid           = OR_grid;
SelectionBias.phi_eff_raw_pct   = 100.0 * phi_eff_raw;
SelectionBias.phi_eff_quota_pct = 100.0 * phi_eff_quota;
SelectionBias.Clear_Raw_Vol     = Clear_Raw_Vol;
SelectionBias.Clear_Quota_Strat = Clear_Quota_Strat;
SelectionBias.Clear_Quota_H30   = Clear_Quota_H30;
SelectionBias.OR_Raw_Fail50     = local_crossing_point(OR_grid, Clear_Raw_Vol, 50.0);

%% 4. Panel D (Mechanism 3.2): Captured-Lane Quarantine & Graceful 4-of-5 Sub-Lattice Degradation
% Exact canonical main-effect vector w_iso (sum = +11.23 pp) & Topkis Hessian H_syn (+13.47 pp = +24.70 pp total)
w_iso = [4.02; 1.04; 1.15; 2.24; 2.78];
H_raw = [ ...
    0.00, 2.40, 1.85, 3.10, 1.45; ...
    2.40, 0.00, 1.10, 2.85, 1.30; ...
    1.85, 1.10, 0.00, 0.95, 1.20; ...
    3.10, 2.85, 0.95, 0.00, 2.15; ...
    1.45, 1.30, 1.20, 2.15, 0.00];
H_syn = H_raw * (2.0 * 13.47 / sum(H_raw(:)));
v_act = [8.60; 4.10; 2.40; 7.50; 6.20];

% Evaluate full 5-of-5 compact vs each 4-of-5 sub-lattice when Lane m is captured by Privateer holdouts (u_m = 0)
% plus Thin Omnibus Fire-Sale Poison Pill (-NZD 176.4B PV loss / -4.60 pp CE net harm):
Scen_Labels = { ...
    'Thin Omnibus (Privateer Fire-Sale)', ...
    'Quarantine A1 (A2..A5 Clear)', ...
    'Quarantine A4 (A1..A3,A5 Clear)', ...
    'Quarantine A5 (A1..A4 Clear)', ...
    'Quarantine A2 (A1,A3..A5 Clear)', ...
    'Quarantine A3 (A1,A2,A4,A5 Clear)', ...
    'Full 5-of-5 Thick Compact'};

U_vecs = [ ...
    0.00, 0.00, 1.00, 1.00, 1.00, 1.00, 1.00; ... % A1
    0.00, 0.94, 0.95, 0.96, 0.00, 0.97, 1.00; ... % A2
    0.00, 0.95, 0.96, 0.96, 0.96, 0.00, 1.00; ... % A3
    0.00, 0.92, 0.00, 0.95, 0.95, 0.97, 1.00; ... % A4
    0.00, 0.94, 0.94, 0.00, 0.95, 0.97, 1.00];    % A5 (5 x 7 matrix, cols = scenarios)

n_sc        = numel(Scen_Labels);
SubLat_CE   = zeros(n_sc, 1);
SubLat_Solv = zeros(n_sc, 1);
FireSale_Blocked_Pct = [0.0; 100.0; 100.0; 100.0; 100.0; 100.0; 100.0];

% Col 1: Thin Omnibus when captured Finance/Infra lane forces +NZD 34.8B asset fire-sale (-NZD 176.4B PV loss)
SubLat_CE(1)   = -4.60;
SubLat_Solv(1) = -17.64; % Scaled 10x B/yr annuity equivalent of -NZD 176.4B PV hole

for s = 2:n_sc
    u_s = U_vecs(:, s);
    % If A1 is quarantined (s == 2), Assembly 2 holds Youth Grant on Early-Adopter 17.3% mentored bridge (zero BCH penalty!)
    SubLat_CE(s)   = (u_s' * w_iso) + 0.5 * (u_s' * H_syn * u_s);
    SubLat_Solv(s) = (u_s' * v_act) - 1.15 * sum(1.0 - u_s);
end

Quarantine = struct();
Quarantine.Scen_Labels          = Scen_Labels;
Quarantine.Realized_CE_pp       = SubLat_CE;
Quarantine.Retained_Share_Pct   = max(0.0, 100.0 * SubLat_CE / SubLat_CE(end));
Quarantine.Net_Solvency_Score   = SubLat_Solv;
Quarantine.FireSale_Blocked_Pct = FireSale_Blocked_Pct;
Quarantine.Mean_4of5_CE_pp      = mean(SubLat_CE(2:6));
Quarantine.Min_4of5_CE_pp       = min(SubLat_CE(2:6));
Quarantine.Max_4of5_CE_pp       = max(SubLat_CE(2:6));

%% 5. Package Pure Output Struct
Out = struct();
Out.M_lanes       = M_lanes;
Out.N_A_default   = N_A_default;
Out.R2_strata     = R2_strata;
Out.Breakdown     = Breakdown;
Out.SizeSweep     = SizeSweep;
Out.SelectionBias = SelectionBias;
Out.Quarantine    = Quarantine;
end

%% ========================================================================
%  INTERNAL PURE VECTORIZED HELPERS
%  ========================================================================
function P_joint_pct = local_joint_clear_prob(phi_vec, N_A, tau_vote, p_gf, R2_strata, M_lanes)
% Expected pro-compact vote share in each assembly when phi_priv delegates vote No/Sabotage
% and (1 - phi_priv) good-faith citizens vote Yes with probability p_gf:
phi_col = phi_vec(:);
mu_yes  = (1.0 - phi_col) * p_gf;

% Stratified sortition shrinks sampling variance by (1 - R2_strata) relative to SRS binomial:
% Equivalent effective binomial precision N_eff = round(N_A / (1 - R2_strata)).
N_eff = max(N_A, round(N_A / max(0.20, 1.0 - R2_strata)));
k_req = ceil(tau_vote * N_eff);

% Exact log-space binomial survival P(X >= k_req | N_eff, mu_yes) across all phi points:
k_row   = 0:(k_req - 1);
log_nck = gammaln(N_eff + 1) - gammaln(k_row + 1) - gammaln(N_eff - k_row + 1);

mu_clamped = min(1.0 - 1e-12, max(1e-12, mu_yes));
log_pmf    = log_nck + k_row .* log(mu_clamped) + (N_eff - k_row) .* log(1.0 - mu_clamped);
P_fail_one = min(1.0, max(0.0, sum(exp(log_pmf), 2)));
P_fail_one(mu_yes <= 0) = 1.0;
P_fail_one(mu_yes >= 1) = 0.0;

P_joint_pct = 100.0 * ((1.0 - P_fail_one) .^ M_lanes);
end

function x_star = local_crossing_point(x_vec, y_pct, target_pct)
idx = find(y_pct < target_pct, 1, 'first');
if isempty(idx)
    x_star = x_vec(end);
elseif idx == 1
    x_star = x_vec(1);
else
    x0 = x_vec(idx - 1); x1 = x_vec(idx);
    y0 = y_pct(idx - 1); y1 = y_pct(idx);
    x_star = x0 + (target_pct - y0) * (x1 - x0) / (y1 - y0);
end
end
