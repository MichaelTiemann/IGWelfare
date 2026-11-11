# Provenance: the Gate-1 "vulnerable newborn pool" (25.1%)

**Purpose.** This sheet records where the Gate-1 share quoted as 25.1% comes from, what it measures, and how it relates to published child-poverty measures. Citations of the form `Doc:line` (for example `1B:279`) refer to the repository documents (`1A` = `Document 1A.md`, and so on) at commit `c23787e`.

## 1. Three different objects

| Object | What it is | Population | Value | Repository location |
|---|---|---|---|---|
| Official child-poverty and hardship measures | Stats NZ annual measures under the Child Poverty Reduction Act | Children 0-17, year ended June 2025 (provisional) | Material hardship **14.3%** (169,300); severe hardship **6.0%** (71,000); AHC50 anchored **17.8%**; AHC50 relative **21.5%**; AHC60 **29.9%**; both hardship and below 60% AHC **8.6%** | 14.3% and 6.0%: `1A:57`; AHC60 29.9%: `2B:208` |
| Dunedin "22%" | An outcome-defined segment of one birth cohort (207 of 940): membership of three or more high-cost groups by age 38, predicted by childhood risks including brain health at age 3 (Caspi et al. 2016). It accounts for 66% of welfare benefits, 81% of convictions and 57% of hospital nights | 1972-73 Dunedin cohort, followed to about age 38 | 22% of the cohort | `1A:304`; `1B:256`; `2B:207` |
| GUiNZ-era "28.5%" | A model anchor: the struggling-launch share at age 20 under `MetroSqueeze_GUiNZ` housing assumptions (3.10x metropolitan housing cost, 37% damp/mould, over 45% private-rental transience) | Model cohort | 28.5% national; 34.0%-36.6% Auckland | `1A:304`; `1B:256`; `2B:208` |

Neither 22% nor 28.5% is a hardship prevalence, so neither conflicts with the 14.3% hardship rate. The 25.1% reads as a Stats NZ-type prevalence if presented as the share of newborns in hardship; no published measure gives that value.

Wording note: `2B:207` describes the Dunedin segment as "identified at age 3". In Caspi et al. adult outcomes define the segment and age-3 measures predict it.

## 2. How 25.1% is constructed

| Ledger (SS0) | Node 1 | Node 2 | Sum | Location |
|---|---|---|---|---|
| Fiscal Sankey, Gate 1 | 9.5% | 15.6% | **25.1%** | `1B:279`; headline `1A:270`, `1C:20` |
| Population Sankey, Gate 1 | 9.80% | 14.20% | **24.00%** | `1B:253`; "~10% ... ~14% ... ~24%" at `1A:316` |

Downstream, the unmitigated corner also differs: 24.00% in the population ledger (`1B:254`), 23.2% in the fiscal ledger (`1B:280`, `1A:270`).

## 3. Three definitional questions

1. **Node 1 label moves.** The headline labels Node 1 "Material & Severe Material Hardship (DEP-17 6+ & 9+)" (`1A:270`, `1C:20`). The population Sankey and `1A:316` label it "Severe Material Hardship, DEP-17 9+", operationalised as an asset floor `a < 0.05 Q_k` (`1B:253`). The published severe rate is 6.0% and the all-hardship rate is 14.3%; 9.5%-9.8% lies between them and equals neither.
2. **Node 2 is an income idea measured by an asset band.** "Residual AHC-50 squeeze" is defined as `0.05 Q_k <= a < 0.16 Q_k` (`1B:253`). AHC50 is an income measure. The share of AHC50-poor children who are not also in material hardship is not published; the published overlap is hardship and below 60% AHC (8.6%).
3. **The sum reads as a union of two measures, and no published union matches it.** The union of hardship and AHC60 poverty can be computed from published figures; unions with AHC50 depend on an overlap that is not published.

| Union | Arithmetic | Result | Status |
|---|---|---|---|
| Hardship or AHC60 | 14.3 + 29.9 - 8.6 | **35.6%** | Published inputs |
| Hardship or AHC50 relative | 14.3 + 21.5 - overlap | about 29%-32% | Illustrative; overlap unpublished |
| Hardship or AHC50 anchored | 14.3 + 17.8 - overlap | about 26%-28% | Illustrative; overlap unpublished |

The two illustrative ranges are reproduced by an overlap of 30%-45% of the hardship group (4.3-6.4 percentage points). The base of that percentage is an assumption here. A defined union can fall near one in four; the current two-node decomposition has not yet been mapped onto one.

## 4. One possible restatement

Not yet reflected in the monographs:

> About one in seven children (14.3%, 169,300) were in material hardship in the year to June 2025, 6.0% severely; 17.8% were below the 50% after-housing-costs anchored line, and 8.6% were both in hardship and below 60% AHC. The model's Gate-1 "vulnerable pool" could be defined as (if the union is the intended object) the union of material hardship and anchored-line AHC50 income poverty, about one child in four (illustratively 26%-28%). The Dunedin Study's 22% high-burden segment is used separately, as the outcome-side anchor for the struggling launch tier at age 20.

## 5. The two anchors side by side

One option is to show both anchors as a range (22.0% / 28.5%; Year-5 return 3.84x / 4.26x; remediation NZD 17.7B / 28.5B per year); the documents currently present `Dunedin_22` as the default conservative anchor (`1A:304`, `2B:207`). The switch is `Params.Calibration_Anchor` (`2B:206`).

| Quantity | `Dunedin_22` | `MetroSqueeze_GUiNZ` | Location |
|---|---|---|---|
| Struggling launch share, age 20 | 22.0% | 28.5% | `1B:256`; `1A:304` |
| Year-5 actuarial return | 3.84x (NZD 35.25B) | 4.26x (NZD 39.14B) | `1A:304`; `1B:522`; `1B:801-802` |
| 2050 remediation burden (Exits 1, 2, 4) | NZD 17.7B/yr | NZD 28.5B/yr | `1B:522`; `1C:81` |

## 6. Two notes on comparability

- **Survey continuity.** The 2024-25 estimates moved to the Household Income and Living Survey and the MH-18 index (7+ / 10+, thresholds set for continuity with DEP-17 6+ / 9+) and are provisional. Comparisons across that year need care.
- **Age coverage.** All official rates above are for ages 0-17; the Sankey cohort is newborns. An under-5 rate would come from MSD age breakdowns rather than the 0-17 headline.

## Sources

MSD, *Child Poverty in New Zealand* (Perry, July 2026), table "Stats NZ figures for 2017-18 to 2024-25"; Stats NZ (2026), *Measuring child poverty: material hardship in the Household Income and Living Survey*; Caspi et al. (2016), *Nature Human Behaviour* 1:0005.
