# Order-independent attribution: Shapley and Owen values for the 11-layer decomposition

Companion to `Shapley_Owen_Attribution.m` and `tests/`. Numbers are national SS2 long-run CE %. The layer values are those typed in the scripts at upstream commit c23787e (`Raw_Nat_11`, `Raw_Mat_4x4` and the regional targets in `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m`, lines 36-38, 55 and 331-335); derived figures are computed from them by the function and asserted in `tests/test_Shapley_Owen_SuiteExample.m`.

## Why order independence matters for "54.5% from four wedges"
The headline total is already order-invariant: if the seven isolated layers are the singleton values v({i}), the wedge total is v(N) − Σ v({i}) = 24.71 − 11.24 = 13.47, i.e. 54.51%. How that 13.47 is split among Wedges 1–4, and credited to levers or coalitions, depends on the chosen build order and bucketing; Wedges 3 and 4 are defined relative to earlier stacks (Wedge 4 closes the residual). Three-player illustration (tested): building A, B, C gives staircase wedges 4 and 4; building C, B, A gives 3 and 5; the total, 8, is the same.

The eleven typed values are rounded to two decimals and sum to 24.71; the national figure computed from the regional targets is 24.70 (24.6996), which is the figure printed in the documents (Document 3.md line 261: +24.70%, isolated +11.23%, wedges +13.47%, 54.5%). The 0.01 differences come from that rounding; the 54.5% share is the same either way.

## How the current wedges relate to Shapley interaction terms
Write the Harsanyi dividend of a lever set S as d(S). Then Shapley φ_i = Σ over S ∋ i of d(S)/|S|, and each wedge is a sum of dividends over one bucket of sets. For two-lever stacks the wedge is exactly the two-way interaction v({A,B}) − v({A}) − v({B}) + v(∅) (checked for Wedge 1 = 3.32 and Wedge 3 = 5.20), and Shapley splits it equally: Dual-Gate gives ECE₁ 4.12 and Tuakana 3.22; stacks give HC 9.94 and Spatial 8.21. The Owen value additionally respects the Document 3 coalitions as a priori unions. If interactions are only pairwise it equals Shapley for any grouping; the grouping matters only through three-way and higher terms (Wedges 2–4).

The coalition matrix built in `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m` (`Raw_Mat_4x4`, rescaled to the national total; exported as Table 22) has row totals 13.66, 9.42, 6.11, 3.87, which sum to 33.06 because each pairwise wedge appears in both partners' rows. Splitting each wedge equally (Shapley under the matrix's own pairwise accounting) gives 10.76, 7.35, 4.15, 2.43, summing to 24.70. Table A.2 in `Document 3.md` (lines 267-270) prints different cell values (own-lane 6.33, 3.52, 2.21, 2.49; row totals 13.28, 8.17, 7.21, 6.19); the figures above follow the script.

## The "path-dependent" sentence (Document 2B, line 323 at c23787e)
> "Rather than relying on an arbitrary path-dependent Shapley residual, `Plot_Counterfactuals_And_MirrorInvestments.m` constructs an **11-Layer Supermodular Hierarchy**..."

Alternative wording: *Shapley values average each lever's marginal contribution over all orderings and are therefore order-independent; it is a single-path decomposition that is path-dependent.* The 11-layer hierarchy remains a description of isolated effects and stack-level wedges; Shapley/Owen allocates those wedges.

## Populating the value table
Index coalitions by bitmask (lever k ⇔ bit k), levers 1–7 = ECE₁, Tuakana, Estate/Property rebalance, Youth Grant, Geo transfer, Debt-sinking, PAYE/Super-64. Fill a 128-vector with SS2 national CE from the same model-run pipeline, NaN where not run, then call `Shapley_Owen_Attribution(V, 7, unions)`; if a required value is missing the call errors with a count and the first five missing coalitions; the full list is `info.masks_needed` from a stub call such as `Shapley_Owen_Attribution(@(m) 0, 7, unions)`. Existing values: 12 of 128 (∅, 7 singletons, {1,2}, {3,4,5}, {1..5}, grand), assuming those layers come from model runs; the Plot scripts hard-code them (v({1,2}) = 7.34, v({3,4,5}) = 5.61, v({1..5}) = 18.15, v(N) = 24.71 from the typed layers).

| Target | New runs |
|---|---|
| Full Shapley, 7 levers | 116 |
| Owen, 4 coalitions {1,2},{4,5},{3},{6,7} | 52 |
| Owen, 3 stacks {1,2},{3,4,5},{6,7} | 36 |
| All 21 pairs (checks the pairwise assumption against v(N) = 24.71) | 20 |

Each run is one SS2 long-run model run (the current pipeline solves households under typed prices); time per run was not measured here.
