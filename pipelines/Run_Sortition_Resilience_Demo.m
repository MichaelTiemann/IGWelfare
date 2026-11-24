%% RUN_SORTITION_RESILIENCE_DEMO
% Top-level pipeline orchestrating the Byzantine Sortition Breakdown, Selection-Bias,
% and 4-of-5 Sub-Lattice Quarantine diagnostic for Document 1F.

Params = Ensure_Workbench_Initialized();
t0 = tic;

PlotOut = Plot_Doc1F_Sortition_Resilience(Params);
SB = PlotOut.SB;
B  = SB.Breakdown;
S  = SB.SizeSweep;
V  = SB.SelectionBias;
Q  = SB.Quarantine;

fprintf('\n========================================================================================================\n');
fprintf('  1. BYZANTINE SORTITION BREAKDOWN THRESHOLDS (N_A = 100 STRATIFIED ACROSS M = 5 ASSEMBLIES)\n');
fprintf('========================================================================================================\n');
fprintf('  * 50%%+1 Majority + PBE IFRS 17 Solvency Lock : Tolerates up to %5.1f%% Privateers (50%% Breakdown)\n', 100 * B.phi_star_50);
fprintf('  * 67%% Supermajority (Canonical Thick)        : Tolerates up to %5.1f%% Privateers (50%% Breakdown)\n', 100 * B.phi_star_67);
fprintf('  * 67%% Supermajority (-30%% CBAx Haircut)      : Tolerates up to %5.1f%% Privateers (50%% Breakdown)\n', 100 * B.phi_star_hair30);
fprintf('  * 75%% Supermajority Consensus Rule           : Tolerates up to %5.1f%% Privateers (50%% Breakdown)\n', 100 * B.phi_star_75);
fprintf('  * At phi = 15%% Privateers: N=12 Jury Clears %5.1f%% vs N=100 Stratified Clears %6.2f%%\n', ...
    S.Clear_N12_Phi15_Unstrat, S.Clear_N100_Phi15_Strat);
fprintf('  * Volunteer Bias (Base 12%%): Raw Self-Selection Fails at %.2fx OR; Quota Replacement Holds %.1f%% at 5.0x OR\n', ...
    V.OR_Raw_Fail50, V.Clear_Quota_Strat(end));

fprintf('\n========================================================================================================\n');
fprintf('  2. MECHANISM 3.2 — GRACEFUL 4-OF-5 SUB-LATTICE QUARANTINE IF 1 ASSEMBLY IS CAPTURED\n');
fprintf('========================================================================================================\n');
for i = 1:numel(Q.Scen_Labels)
    fprintf('  * %-36s : %+6.2f pp CE (%5.1f%% of Frontier | Fire-Sale Blocked: %5.1f%%)\n', ...
        Q.Scen_Labels{i}, Q.Realized_CE_pp(i), Q.Retained_Share_Pct(i), Q.FireSale_Blocked_Pct(i));
end
fprintf('========================================================================================================\n');
fprintf('  Saved Figure : %s\n', PlotOut.FigurePNG);
fprintf('  Completed in %.2f seconds.\n\n', toc(t0));
