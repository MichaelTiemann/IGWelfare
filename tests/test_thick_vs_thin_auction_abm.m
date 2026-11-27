function test_thick_vs_thin_auction_abm()
% TEST_THICK_VS_THIN_AUCTION_ABM
% Verifies 1972->2026 Backlog Homotopy, 30%/50% Epistemic Synergy-Haircut
% resilience, 12-Spoke 6-Persona Radar symmetry, 2024->2026 Unraveling invariants, and zero figure leaks.

Params = Ensure_Workbench_Initialized();
figs_before = numel(findall(0, 'Type', 'figure'));

Opts = struct('N_mc', 1500, 'R_max', 28, 'seed', 20261124);
ABM  = Compute_ThickVsThin_Auction_ABM(Params, Opts);
H    = ABM.Homotopy;

% 1. 1972 Golden-Age Baseline Invariant (psi = 1/16) & 2026 Bifurcation
assert(H.Thin_Viable_Pct(1) > 65.0, 'Expected 1972 Thin viable closure > 65%%.');
assert(H.Thin_Viable_Pct(1) - H.Thin_Viable_Pct(end) > 55.0, 'Expected >55 pp Thin drop from 1972 to 2026.');

% 2. Epistemic Bullet-Proofing Invariant (30% CBAx & 50% Severe Synergy Haircuts at 2026 1.0x)
% Non-laggard cohorts (~75% of population) clear cleanly under the 30% CBAx attribution haircut
% (~72.9% overall vs 0.0% Thin), and cooperative/innovative cohorts still clear under a 50% double haircut.
assert(H.Thick_Haircut30_Pct(end) > 68.0 && H.Thick_Haircut30_Pct(end) < H.Thick_Viable_Pct(end), ...
    sprintf('Expected 30%% CBAx haircut Thick closure in (68%%, Canonical), got %.1f%%.', H.Thick_Haircut30_Pct(end)));
assert(H.Thick_Haircut50_Pct(end) > 25.0 && H.Thick_Haircut50_Pct(end) < H.Thick_Haircut30_Pct(end), ...
    sprintf('Expected 50%% severe haircut Thick closure in (25%%, 30%%-Haircut), got %.1f%%.', H.Thick_Haircut50_Pct(end)));

% 3. Twin 6-Spoke Hexagonal Radar Dimension Invariant (Left: Closure % [1x6] | Right: CE pp [1x6])
assert(size(ABM.Arch_Stats, 1) == 6, 'Expected 6 institutional personas in Arch_Stats.');
assert(isequal(size(ABM.Radar.Closure_Thin_Reality), [1, 6]) && ...
       isequal(size(ABM.Radar.Closure_Thin_Mirage),  [1, 6]) && ...
       isequal(size(ABM.Radar.Closure_Thick_Canon),  [1, 6]) && ...
       isequal(size(ABM.Radar.CE_Thick_Canon_pp),    [1, 6]), ...
       'Expected both C1 (Closure) and C2 (CE pp) hexagons to share clean [1 x 6] dimensions.');

% 4. Day-1 Ambition vs 2026 Unraveling Invariant
assert(ABM.Unravel.Yr2_CashBias < -20.0 && ABM.Unravel.Yr2_Thick30 > 65.0, ...
    'Expected Cash-Basis Omitted-Liability Ledger to be negative by Yr 2 while 30%%-Haircut Thick stays > +65.');

% 5. Smoke-test full plot & CSV export in isolated tempdir so N_mc=1500 never overwrites canonical N_mc=4000 PNG
tmp_dir = fullfile(tempdir(), 'igw_test_thickvsthin');
if ~exist(tmp_dir, 'dir'), mkdir(tmp_dir); end
OptsPlot = Opts;
OptsPlot.OutputDir = tmp_dir;
PlotOut = Plot_ThickVsThin_Assembly_Auction(Params, OptsPlot);
figs_after = numel(findall(0, 'Type', 'figure'));
assert(figs_after == figs_before, 'Figure leak detected in Plot_ThickVsThin_Assembly_Auction.');
assert(exist(PlotOut.FigurePNG, 'file') == 2, 'Expected PNG artifact missing.');

fprintf('[PASS] test_thick_vs_thin_auction_abm passed Homotopy, 30%%/50%% Haircut, Radar, and Unraveling checks.\n');
end
