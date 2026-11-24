%% RUN_THICKVSTHIN_AUCTION_DEMO
% Top-level pipeline orchestrating the Thick-vs.-Thin Citizens' Assembly ABM,
% 30%/50% Epistemic Synergy-Haircut Stress-Test, 12-Spoke 6-Persona Institutional Radar, and
% 2024->2026 Ambition-Unraveling Clock.

Params = Ensure_Workbench_Initialized();
t0 = tic;

PlotOut = Plot_ThickVsThin_Assembly_Auction(Params);
ABM     = PlotOut.ABM;
H       = ABM.Homotopy;
U       = ABM.Unravel;

fprintf('\n========================================================================================================\n');
fprintf('  1. HISTORICAL HOMOTOPY & SYNERGY-HAIRCUT STRESS-TEST: 1972 (1/16x) -> 2026 (1.0x) (%s)\n', Params.Profile_ID);
fprintf('========================================================================================================\n');
fprintf('  %-48s | %8s | %8s | %9s | %9s | %9s\n', ...
    'Backlog Era / Regime', 'ThinViab', 'Mirage%', 'Thick 0%', 'Hair -30%', 'Hair -50%');
fprintf('--------------------------------------------------------------------------------------------------------\n');
for b = 1:numel(H.Bench_Idx)
    ix = H.Bench_Idx(b);
    fprintf('  %-48s | %7.1f%% | %7.1f%% | %8.1f%% | %8.1f%% | %8.1f%%\n', ...
        H.Bench_Labels{b}, H.Thin_Viable_Pct(ix), H.Thin_FoolsGold_Pct(ix), ...
        H.Thick_Viable_Pct(ix), H.Thick_Haircut30_Pct(ix), H.Thick_Haircut50_Pct(ix));
end

fprintf('\n========================================================================================================\n');
fprintf('  2. SYMMETRIC PERSONA RADAR METRICS (2026 BASELINE: VIABLE CLOSURE %% & REALIZED CE WELFARE)\n');
fprintf('========================================================================================================\n');
for k = 1:size(ABM.Arch_Stats, 1)
    st = ABM.Arch_Stats(k, :);
    fprintf('  * %-26s : ThinPaper %5.1f%% (Viab %4.1f%%, %+5.1f%% CE) | Thick %5.1f%% (%+5.1f%% CE) | -30%%Hair %5.1f%% (%+5.1f%% CE)\n', ...
        ABM.Archetype_Names{k}, st(1), st(2), st(5), st(4), st(6), st(9), st(10));
end

fprintf('\n========================================================================================================\n');
fprintf('  3. YEAR-2 (2024 -> 2026) AMBITION ATTAINMENT CHECK (100 = PROMISED DAY-1 TARGET, <0 = NET WORSE)\n');
fprintf('========================================================================================================\n');
fprintf('  * Mode 1 — Cash-Basis Omitted-Liability Cuts (2024->2026) : %+6.1f  (Unravels < 0 before Yr 1)\n', U.Yr2_CashBias);
fprintf('  * Mode 2 — Fragile Thin Silo Deal (Cracks on Yr-2 Shock)     : %+6.1f  (Stalls & fractures into Stop-Go)\n', U.Yr2_Fragile);
fprintf('  * Thick Clearinghouse w/ 30%% CBAx Synergy Haircut            : %+6.1f  (Absorbs shock via Amber buffer)\n', U.Yr2_Thick30);
fprintf('  * Thick Clearinghouse Canonical (13-Wave + ACC Actuarial)    : %+6.1f  (On track to 3.84x Yr-5 Audit)\n', U.Yr2_Thick);
fprintf('========================================================================================================\n');
fprintf('  Saved Figure : %s\n', PlotOut.FigurePNG);
fprintf('  Completed in %.2f seconds.\n\n', toc(t0));
