function test_sortition_breakdown_ledger()
% TEST_SORTITION_BREAKDOWN_LEDGER
% Verifies Byzantine sortition breakdown bounds, N_A=100 stratification shield,
% quota-replacement immunity to volunteer bias, and 4-of-5 Sub-Lattice Quarantine.

Params = Ensure_Workbench_Initialized();
figs_before = numel(findall(0, 'Type', 'figure'));

SB = Compute_Sortition_Breakdown_Ledger(Params);
B  = SB.Breakdown;
S  = SB.SizeSweep;
V  = SB.SelectionBias;
Q  = SB.Quarantine;

% 1. Strict ordering & finite-sample 5-lane breakdown bounds: 75% (~18.6%) < 67% (~26.6%) < 50%+1 (~43.6%)
assert(B.phi_star_75 > 0.17 && B.phi_star_75 < B.phi_star_67 && B.phi_star_67 < B.phi_star_50, ...
    'Expected strict monotonicity in Byzantine breakdown points across 75%%, 67%%, and 50%% thresholds.');
assert(B.phi_star_67 > 0.25 && B.phi_star_50 > 0.42, ...
    sprintf('Expected 5-lane 67%% breakdown > 25%% (got %.1f%%) and 50%%+1 > 42%% (got %.1f%%).', ...
    100*B.phi_star_67, 100*B.phi_star_50));

% 2. Stratified N_A = 100 crushes sampling tail risk relative to N_A = 12 jury across both phi=15% & phi=22%
assert(S.Clear_N100_Phi15_Strat > 99.9 && (S.Clear_N100_Phi15_Strat - S.Clear_N12_Phi15_Unstrat) > 20.0, ...
    'Expected N=100 stratified to outperform N=12 unstratified by >20 pp at phi=15%%.');
assert(S.Clear_N100_Phi22_Strat > 90.0 && S.Clear_N12_Phi22_Unstrat < 45.0, ...
    'Expected N=100 stratified >90%% vs N=12 unstratified <45%% under heavy phi=22%% Privateer stress.');

% 3. Quota stratification defeats 5.0x differential volunteer response bias
assert(V.OR_Raw_Fail50 < 3.0 && V.Clear_Quota_Strat(end) > 99.0, ...
    'Expected unweighted volunteers to fail below 3.0x bias while quota replacement holds >99%% at 5.0x.');

% 4. Mechanism 3.2: All five 4-of-5 Sub-Lattice Quarantines retain >50% of frontier (> +12.5 pp CE),
%    A1 quarantine causes the largest drop (confirming Gate 1&2 centrality), & 100% of fire-sales are blocked
assert(Q.Min_4of5_CE_pp > 12.5 && Q.Mean_4of5_CE_pp > 15.5 && Q.Max_4of5_CE_pp < Q.Realized_CE_pp(end), ...
    sprintf('Expected 4-of-5 sub-compacts in (+12.5, +24.7) pp CE with mean > +15.5 pp, got min %.2f, mean %.2f.', ...
    Q.Min_4of5_CE_pp, Q.Mean_4of5_CE_pp));
assert(Q.Realized_CE_pp(2) == Q.Min_4of5_CE_pp, ...
    'Expected Quarantine A1 (Early Potential & Mentoring) to be the highest-cost single-lane loss.');
assert(all(Q.FireSale_Blocked_Pct(2:end) == 100.0), ...
    'Expected PBE IFRS 17 solvency gate to block 100%% of distressed fire-sales.');

% 5. Smoke-test figure & CSV generation in isolated tempdir with zero figure leaks
tmp_dir = fullfile(tempdir(), 'igw_test_sortition');
if ~exist(tmp_dir, 'dir'), mkdir(tmp_dir); end
PlotOut = Plot_Doc1F_Sortition_Resilience(Params, struct('OutputDir', tmp_dir));
figs_after = numel(findall(0, 'Type', 'figure'));
assert(figs_after == figs_before, 'Figure leak detected in Plot_Doc1F_Sortition_Resilience.');
assert(exist(PlotOut.FigurePNG, 'file') == 2, 'Expected Sortition Resilience PNG missing.');

fprintf('[PASS] test_sortition_breakdown_ledger passed Byzantine, Stratification, Bias, and 4-of-5 Quarantine checks.\n');
end
