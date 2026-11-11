#!/usr/bin/env python3
"""Documentation consistency checker for the IGWelfare monograph suite.

Standard library only.  Not a generic number-diff: it checks

  (a) a CURATED registry of named quantities (QUANTITIES below).  Each
      quantity lists (file, regex-with-one-capture-group) patterns that pull
      the value out of the Markdown documents, and, where a committed CSV in
      Output_NZ_4Region_Intergen/ carries the same quantity, a CSV extractor;
  (b) doc-vs-doc and doc-vs-CSV disagreements for those quantities, and
      CSV-vs-CSV disagreements when two committed CSVs give different values;
  (c) broken relative links, broken anchors, file references that do not
      resolve (case-sensitively), and GitHub file URLs that are not valid
      blob/tree URLs;
  (d) stated vs actual Sankey node / gate counts (actual counts come from the
      Table14 / Table15 CSVs and the Interactive_*.html files).

Output is deterministic Markdown written to tools/CONSISTENCY_REPORT.md
(regenerate with:  python3 tools/check_docs_consistency.py).

  --strict    exit 1 if any finding is not listed in KNOWN_AUTHOR_DECISIONS
  --no-write  do not rewrite the report (print the summary only)

Comparison rule: a captured value with d decimals matches another value when
they differ by at most 0.5 * 10**-d (so "23.6" matches 23.61, "23.60" does not).
A pattern that matches nothing is itself reported (category REGISTRY), so the
registry cannot silently go stale.
"""
import argparse
import csv
import fnmatch
import glob
import os
import re
import sys
import urllib.parse
from collections import OrderedDict, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = "Output_NZ_4Region_Intergen"
REPORT = os.path.join(ROOT, "tools", "CONSISTENCY_REPORT.md")
REPO_URL = "github.com/MichaelTiemann/IGWelfare"

DOCS = ["README.md"] + sorted(
    os.path.basename(p) for p in glob.glob(os.path.join(ROOT, "Document *.md")))

# ---------------------------------------------------------------------------
# KNOWN_AUTHOR_DECISIONS: (category, quantity-or-target, one-line reason).
# --strict ignores findings listed here; everything else must be zero.
# ---------------------------------------------------------------------------
KNOWN_AUTHOR_DECISIONS = [
    # --- links and file references ---
    ("LINK", "./Document%201B.md#lifecycle-vulnerability-gates-empirical-baselines-unpaid-buffers-and-policy-analogs",
     "Document 1B.md has no such heading; the author picks the target (candidates: 1B section 2.2.2 at line 111, or 2.2.1 at line 96)."),
    ("LINK", "ChildCES_aprimeFn.m",
     "File was deleted in e48aada (2026-10-19); 1B:162 and 1B:956 still name it beside HumanCapital_Lifecycle_aprimeFn.m; for the author to decide: drop or restore."),
    ("LINK", "SSankey.m",
     "Third-party MATLAB function (Document 2B.md:367), not in the repo; for the author to decide: state source and version."),
    ("LINK", "Solve_Spatial_GE_Loop.m",
     "Not on upstream/main; the danalytics/ge-scaffold branch supplies it; re-run the checker after it merges."),
    ("LINK", "Table16_Actuarial_Continuation_Audit_Dunedin_22.csv",
     "Not committed and no .m file names it; for the author to decide: commit the output or reword 1B:34, 1B:789."),
    # --- Sankey comments in .m files (no .m edits in this PR) ---
    ("SANKEY", "fiscal_nodes=28",
     "Comment-only: Plot_ChildFiscal_SSankey.m lines 2/111/205 and getFiscalRibbonNarratives.m:4 say 28; the code, CSVs and HTML have 29."),
    # --- PAYE: documents moved to the 8 Nov rates (18.25 at age 64, 17.97 at age 65, incl. -0.64 pp from Transfer_Geo retirement) ---
    ("DOC_VS_CSV", "PAYE_SS2_SuperAge64_pct",
     "Documents (18.25) agree with Table21 Year 60 (18.25); Table8/Table8B (18.8433) are written by FertilityBargaining_Module.m:324-325, which does not apply psi_retire_T (the -0.64 pp is applied in WelfareDecomposition_4Region.m:109-110). For the author to decide whether to align the generators."),
    ("CSV_VS_CSV", "PAYE_SS2_SuperAge64_pct",
     "Table21 Year 60 (18.25) vs Table8/Table8B (18.8433): generator inconsistency, see DOC_VS_CSV entry."),
    ("DOC_VS_CSV", "PAYE_CUT_PP_SuperAge64",
     "Documents (3.75) agree with Table21 Year 60; Table8B gives 3.1567 for the same reason as PAYE_SS2_SuperAge64_pct; 1A:96 (3.32) matches no CSV value."),
    ("CSV_VS_CSV", "PAYE_CUT_PP_SuperAge64", "Follows the Table21 vs Table8B split for PAYE_SS2_SuperAge64_pct."),
    ("DOC_VS_DOC", "PAYE_CUT_PP_SuperAge64",
     "1A:96 still says 3.32 pp; every other mention (and Table21) says 3.75 pp. 3.32 differs from them; for the author to decide whether to update."),
    ("DOC_VS_DOC", "PAYE_SS2_SuperAge65_pct",
     "1A:456 still says 18.57% at Age 65; 1A:459 and every other document say 17.97% (CSV Table8B gives 18.5628, which matches neither); for the author to decide which to use."),
    ("DOC_VS_CSV", "PAYE_SS2_SuperAge65_pct",
     "Documents (17.97) include the -0.64 pp transfer retirement; Table8B (18.5628, FertilityBargaining_Module.m) does not. Same split as PAYE_SS2_SuperAge64_pct."),
    ("DOC_VS_CSV", "PAYE_CUT_PP_SuperAge65", "Follows PAYE_SS2_SuperAge65_pct (4.03 vs 22.0 - 18.5628 = 3.4372)."),
    ("DOC_VS_CSV", "PAYE_SuperAge65_below_SS0_Drift_pp",
     "Follows PAYE_SS2_SuperAge65_pct (23.61 - 17.97 = 5.64 vs Table8B 5.0505)."),
    ("DOC_VS_DOC", "PAYE_SS0_StatusQuo_Drift_pct",
     "Remaining 23.60 is 1B:725 inside Table 4.7A, which mirrors typed fallbacks in Plot_Fertility_SuperSolvency_2Panel.m:50-67; refresh the whole table or leave."),
    ("DOC_VS_CSV", "PAYE_SS0_StatusQuo_Drift_pct", "Same as above (1B:725 only)."),
    ("DOC_VS_DOC", "PAYE_SS0_Drift_pp", "1B:725 (+1.60 pp) is part of Table 4.7A, see PAYE_SS0_StatusQuo_Drift_pct."),
    ("DOC_VS_CSV", "PAYE_SS0_Drift_pp", "1B:725 (+1.60 pp) is part of Table 4.7A, see PAYE_SS0_StatusQuo_Drift_pct."),
    # --- Table 4.7A / policy-pathway tables vs Table7/Table8 ---
    ("DOC_VS_DOC", "DepRatio_SS0_Baseline_pct",
     "31.80 (1A:464) and 31.78 (1B:725) both differ from Table8 (31.8329); Table 4.7A mirrors typed fallbacks; for the author to decide whether to refresh."),
    ("DOC_VS_CSV", "DepRatio_SS0_Baseline_pct", "Same as above."),
    ("DOC_VS_DOC", "DepRatio_SS2_SuperAge64_pct",
     "1B:730 (29.66) is the typed fallback in Plot_Fertility_SuperSolvency_2Panel.m:63/66; Table8/8B give 29.6723 (1A:470 and 1B:478 say 29.68)."),
    ("DOC_VS_CSV", "DepRatio_SS2_SuperAge64_pct", "Same as above."),
    ("DOC_VS_DOC", "Struggling_Hyperbolic_Rural_pct",
     "1B:726 (21.4) vs 1A:465 and Table8 (21.3); inside Table 4.7A, see above."),
    ("DOC_VS_CSV", "Struggling_Hyperbolic_Rural_pct", "Same as above."),
    ("DOC_VS_CSV", "TFR_Baseline_Rural", "Table 4.7A TFRs equal typed fallbacks in Plot_Fertility_SuperSolvency_2Panel.m:50-54; Table7 differs by 0.01-0.02."),
    ("DOC_VS_CSV", "TFR_Baseline_Auckland", "Same as TFR_Baseline_Rural."),
    ("DOC_VS_CSV", "TFR_SS2Age64_Rural", "Same as TFR_Baseline_Rural."),
    ("DOC_VS_CSV", "TFR_SS2Age64_Auckland", "Same as TFR_Baseline_Rural."),
    # --- IGE and parameters (no CSV decides) ---
    ("DOC_VS_DOC", "IGE_reduction_FullPackage_pct",
     "-33.4% is the First-2000-Days lever alone (1A:352, 1B:596); 1B:40, 1C:58, 2B:222/225 attribute it to the package, 1B:599 gives -37.7%. No CSV carries national IGE."),
    ("DOC_VS_DOC", "PSI_sandwich",
     "Two parameters share one symbol: 0.35 = Params.psi_sandwich_wrk_drag (Configure_TimeGrid_Params.m:121); 0.28 = literal in HumanCapital_Lifecycle_aprimeFn.m:38 (2T:73). For the author to decide: rename one or the other."),
    # --- Sankey tables and narrative vs the Table14/15 regenerations (last written c57fb1b, 2026-11-08) ---
    ("DOC_VS_DOC", "SS0_Corner_ic0_pct", "1A:270, 1B:280 (23.2) and 1B:254 (24.00) disagree; neither matches Table14/15 (21.29), which were regenerated after the doc tables were written; re-sync is the author's call."),
    ("DOC_VS_CSV", "SS0_Corner_ic0_pct", "Same as above (CSV 21.29)."),
    ("DOC_VS_DOC", "SS0_Hardship_Node1_pct", "Same as SS0_Corner_ic0_pct."),
    ("DOC_VS_CSV", "SS0_Hardship_Node1_pct", "Same as above (CSV 8.97)."),
    ("DOC_VS_DOC", "SS0_LaunchTier_Core_pct", "1B:256 (54.5) vs 1B:282 (61.1); neither matches Table14/15 (63.98)."),
    ("DOC_VS_CSV", "SS0_LaunchTier_Core_pct", "Same as above."),
    ("DOC_VS_DOC", "SS0_LaunchTier_Struggling_pct", "1B:256 (22.00) vs 1B:282 (23.5); Table14/15 give 21.98."),
    ("DOC_VS_CSV", "SS0_LaunchTier_Struggling_pct", "Same as above."),
    ("DOC_VS_DOC", "SS0_LaunchTier_Thriving_pct", "23.2/23.5 (1A, 1B:256, 1C) vs 15.4 (1B:282); Table14/15 give 14.04."),
    ("DOC_VS_CSV", "SS0_LaunchTier_Thriving_pct", "Same as above."),
    # --- headline welfare numbers: Documents and Table19/Table21 moved together; README and Table8B did not ---
    ("DOC_VS_DOC", "CE_SS2_National_Total_pct", "README.md:9 (24.24) was not refreshed in the 8 Nov update; all Documents say 24.70."),
    ("DOC_VS_CSV", "CE_SS2_National_Total_pct", "Documents (24.70) agree with Table19 and Table21 Year 60 (24.6995); Table8B age 64 (24.54) is written by FertilityBargaining_Module.m, see PAYE_SS2_SuperAge64_pct; README.md:9 says 24.24."),
    ("CSV_VS_CSV", "CE_SS2_National_Total_pct", "Table8B (24.54) vs Table19/Table21 (24.6995): same generator split as PAYE_SS2_SuperAge64_pct."),
    ("DOC_VS_DOC", "CE_SS2_WedgeSum_pct", "README.md:9 (+11.46) was not refreshed; Documents say +13.47 and Table19 sums to 13.467."),
    ("DOC_VS_CSV", "CE_SS2_WedgeSum_pct", "README.md:9 only (see above)."),
    ("DOC_VS_DOC", "CE_SS2_WedgeShare_pct", "README.md:9 (47.3%) was not refreshed; Documents say 54.5% and Table19 gives 54.52%."),
    ("DOC_VS_CSV", "CE_SS2_WedgeShare_pct", "README.md:9 only (see above)."),
    ("DOC_VS_CSV", "CE_FiscalStewards_Standalone_Low_pct",
     "3.md:228 cites -10.55% as the low end beside Table 21 (min -6.80); -10.55 is Table22 Net_In_Sinking_LTFM_CE, and Table A.3 (3.md:277 onward) has no -10.55 row."),
    ("CSV_VS_CSV", "CE_FiscalStewards_Standalone_Low_pct", "Same as above."),
]


# ---------------------------------------------------------------------------
# CSV access
# ---------------------------------------------------------------------------
_csv_cache = {}


def rows(fname):
    if fname not in _csv_cache:
        with open(os.path.join(ROOT, OUT, fname), newline="", encoding="utf8") as fh:
            _csv_cache[fname] = list(csv.DictReader(fh))
    return _csv_cache[fname]


def cell(fname, keycol, key, col):
    for r in rows(fname):
        if r[keycol] == key:
            return float(r[col])
    raise KeyError((fname, keycol, key))


def col_vals(fname, col):
    return [float(r[col]) for r in rows(fname)]


T8B = "Table8B_SuperAge_UCurve_60to75.csv"
T8 = "Table8_4Region_Fertility_Struggling_NZSuperTax.csv"
T21 = "Table21_Doc3_LTFM_Sinkhole_Defense_Trajectories_Dunedin_22.csv"
T22 = "Table22_Doc3_2D_Coalition_Complementarity_Matrix_Dunedin_22.csv"
T19 = "Table19_Constructive_Synergy_Wedges_Dunedin_22.csv"
T20 = "Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_Dunedin_22.csv"
T1 = "Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv"
T15N = "Table15_ChildFates_5Stage_Decomp_National.csv"
T14N = "Table14_FiscalLedger_6Gate_Decomp_National.csv"
T8_ROW = {
    "base": "1_Baseline_StatusQuo",
    "ss2_64": "6_SS2_Lower_Super_Age_Dividend (Age 64 -> Kuia/Whanau Boost)",
}


def t8b(age, col):
    return cell(T8B, "NZ_Super_Age", str(age), col)


def t21_year(year, col):
    return cell(T21, "Year", str(year), col)


# ---------------------------------------------------------------------------
# Pattern helpers (every pattern has exactly one capture group)
# ---------------------------------------------------------------------------
NUM = r"(\d+\.\d+)"


def br(first, idx):
    """Cell after a node-list cell in 1B Table 3.1: values separated by <br>."""
    return first + r"[^|]*\| " + (r"\d+\.\d+%<br>" * idx) + NUM + "%"


def br_flow(first, idx):
    """Cell in 1B Table 3.2A: 'x% & flow' values separated by <br>."""
    return first + r"[^|]*\| " + (r"\d+\.\d+% & [\d.]+<br>" * idx) + NUM + "% & "


def tcell(label, k, inner=NUM):
    """k-th table cell (0-based, after the label cell) of the row starting with `label`."""
    return label + r"[^|]*\|" + (r"[^|]*\|" * k) + r"[^|]*?" + inner


# ---------------------------------------------------------------------------
# The registry
# ---------------------------------------------------------------------------
# docs:  list of (file or None for all docs, regex)
# csv:   list of (csv name, description, zero-arg function -> float)
# cmp:   optional function(doc_value, csv_value) -> bool (consistent?)
# ---------------------------------------------------------------------------
QUANTITIES = OrderedDict()


def Q(name, desc, docs, csv=(), cmp=None):
    QUANTITIES[name] = dict(name=name, desc=desc, docs=list(docs), csv=list(csv), cmp=cmp)


Q("PAYE_SS2_SuperAge64_pct",
  "SS2 required working-age PAYE rate at NZ Super age 64 (%)",
  [("Document 1A.md", r"22\.0% to " + NUM + r"%\)\*\*, \*\*Super Age 64"),
   ("Document 1A.md", r"working-age PAYE tax rate to \*\*" + NUM + r"% \(including"),
   ("Document 1A.md", r"down to \d+\.\d+%[–-]" + NUM + r"%, boosted by"),
   ("Document 1A.md", r"\(to " + NUM + r"% at Super Age 64 or"),
   ("Document 1A.md", r"-3\.75 percentage points down to " + NUM + "%"),
   ("Document 1A.md", r"\*\*" + NUM + r"% \(-3\.75 pp Cut\)\*\*"),
   ("Document 1B.md", r"\+24\.70% CE Peak, " + NUM + r"% PAYE\)"),
   ("Document 1B.md", r"\*\*Age 64 = " + NUM + r"%\*\*"),
   ("Document 1B.md", r"\*\*★ Age 64\*\* \| \*\*" + NUM + r"%\*\*"),
   ("Document 1B.md", r"22\.00% down to " + NUM + r"%[,)]"),
   ("Document 1B.md", r"\\tau_l: 22\.0\\% \\to " + NUM + r"\\%"),
   ("Document 1B.md", r"\(`22\.0% -> \d+\.\d+%[–-]" + NUM + r"%`\)"),
   ("Document 1B.md", r"`" + NUM + r"%` \(-3\.75 pp PAYE Cut\)"),
   ("Document 1C.md", r"percentage points \(down to " + NUM + r"%[,)]"),
   ("Document 1C.md", r"22\.00% down to " + NUM + r"% \(boosted by 85% geographic transfer retirement\)\*\* at Age 64"),
   ("Document 1C.md", r"\*\*" + NUM + r"% PAYE \(-3\.75 pp Cut\)"),
   ("Document 1C.md", r"cutting PAYE taxes to " + NUM + r"%"),
   ("Document 1C.md", r"Taxes to " + NUM + r"% \(Phase 2"),
   ("Document 2B.md", r"Age 64 \(`" + NUM + r"% PAYE`"),
   ("Document 2B.md", r"`" + NUM + r"%` at Super Age 64"),
   ("Document 3.md", r"PAYE taxes to \*\*" + NUM + r"%"),
   ("Document 3.md", r"-3\.75 pp PAYE tax cut to " + NUM + r"%"),
   ("Document 3.md", r"PAYE cut -3\.75 pp to " + NUM + r"%"),
   ("Document 3.md", r"-3\.75 pp to " + NUM + r"%\) & Super"),
   ("Document 3.md", r"\*\*" + NUM + r"%\*\* \| \*\*\+24\.70%\*\* \| \*\*\+40\.91 pp"),
   ("Document 3.md", r"\*\*22\.0%\*\* \| \*\*" + NUM + r"%\*\* \| \*\*\+24\.70%\*\*")],
  [(T8B, "Table8B age 64 SS2_Required_PAYE_Pct", lambda: t8b(64, "SS2_Required_PAYE_Pct")),
   (T8, "Table8 row 6 Required_LaborTax_Pct", lambda: cell(T8, "Row", T8_ROW["ss2_64"], "Required_LaborTax_Pct")),
   (T21, "Table21 Year 60 Tax_Unified_SS1_SS2_Pct", lambda: t21_year(60, "Tax_Unified_SS1_SS2_Pct"))])

Q("PAYE_SS2_SuperAge65_pct",
  "SS2 required working-age PAYE rate at NZ Super age 65 (%)",
  [
    ("Document 1A.md", r"\(or \*\*" + NUM + r"%\*\* if Super is held at Age 65\)"),
    ("Document 1A.md", r"global minimum of \*\*" + NUM + r"%\*\*"),
    ("Document 1A.md", r"\*\*" + NUM + r"% \(-4\.03 pp Cut\)\*\*"),
    ("Document 1A.md", r"down to " + NUM + r"%[–-]\d+\.\d+%, boosted by"),
    ("Document 1A.md", r"at Super Age 64 or " + NUM + r"% at Age 65\)"),
    ("Document 1A.md", r"vs\. `" + NUM + r"%` at Age 65"),
    ("Document 1B.md", r"Age 65 \(" + NUM + r"% PAYE Min\)"),
    ("Document 1B.md", r"\(`22\.0% -> " + NUM + r"%[–-]\d+\.\d+%`\)"),
    ("Document 1B.md", r"\*\*Age 65 = " + NUM + r"%\*\*"),
    ("Document 1B.md", r"\*\*★ Age 65\*\* \| \*\*" + NUM + r"% \(MIN\)\*\*"),
    ("Document 1C.md", r"\(or \*\*" + NUM + r"%\*\* at Age 65\)"),
    ("Document 1C.md", r"minimizes PAYE tax \(" + NUM + r"%\)"),
    ("Document 2B.md", r"Age 65 \(`" + NUM + r"% PAYE`"),
  ],
  [(T8B, "Table8B age 65 SS2_Required_PAYE_Pct", lambda: t8b(65, "SS2_Required_PAYE_Pct"))])

Q("PAYE_CUT_PP_SuperAge64",
  "SS2 PAYE cut below the 22.0% statutory rate at age 64 (percentage points)",
  [("Document 1A.md", r"-(3\.\d\d) pp PAYE tax cut \(22\.0% to"),
   ("Document 1A.md", r"-(3\.\d\d) percentage points down to"),
   ("Document 1A.md", r"18\.25% \(-(3\.\d\d) pp Cut\)\*\*"),
   ("Document 1A.md", r"universal New Zealand Superannuation by \*\*(\d+\.\d+) percentage points"),
   ("Document 1B.md", r"-(3\.\d\d) pp PAYE tax cut\*\* \(\$"),
   ("Document 1B.md", r"\*\*-(3\.\d\d) percentage-point working-age PAYE tax cut"),
   ("Document 1B.md", r"Kuia\* boost \+ \*\*-(3\.\d\d) pp PAYE cut\*\*"),
   ("Document 1B.md", r"\(-(3\.\d\d) pp PAYE Cut\)"),
   ("Document 1C.md", r"\*\*-(3\.\d\d) percentage points \(down to"),
   ("Document 3.md", r"-(3\.\d\d) pp PAYE tax cut to"),
   ("Document 3.md", r"PAYE cut -(3\.\d\d) pp to"),
   ("Document 3.md", r"-(3\.\d\d)pp PAYE Cut \+ 85%")],
  [(T8B, "22.0 - Table8B age 64 SS2_Required_PAYE_Pct", lambda: 22.0 - t8b(64, "SS2_Required_PAYE_Pct")),
   (T21, "22.0 - Table21 Year 60 Tax_Unified_SS1_SS2_Pct", lambda: 22.0 - t21_year(60, "Tax_Unified_SS1_SS2_Pct"))])

Q("PAYE_CUT_PP_SuperAge65",
  "SS2 PAYE cut below the 22.0% statutory rate at age 65 (percentage points)",
  [("Document 1A.md", r"\*\*-(\d\.\d\d) percentage-point tax cut\*\* below today's 22\.0% PAYE"),
   ("Document 1A.md", r"17\.97% \(-(\d\.\d\d) pp Cut\)\*\*"),
   ("Document 1B.md", r"Global Tax Minimum:\*\* Full \*\*-(\d\.\d\d) pp PAYE cut\*\*")],
  [(T8B, "22.0 - Table8B age 65 SS2_Required_PAYE_Pct", lambda: 22.0 - t8b(65, "SS2_Required_PAYE_Pct"))])

Q("PAYE_SS0_StatusQuo_Drift_pct",
  "SS0 status-quo required PAYE rate at NZ Super age 65 (%)",
  [("Document 1A.md", r"below the " + NUM + r"% 2050 Status Quo drift"),
   ("Document 1A.md", r"\*\*" + NUM + r"%\*\* \*\(\+1\.\d\d pp hike\)\*"),
   ("Document 1B.md", r"\*\*" + NUM + r"%[–-]28\.20% PAYE req"),
   ("Document 1B.md", r"\| " + NUM + r"% \| \*\*★ Global Tax Minimum"),
   ("Document 1B.md", r"\*\*`" + NUM + r"%`\*\* \*\(\+1\.\d\d pp drift")],
  [(T8, "Table8 row 1 Required_LaborTax_Pct", lambda: cell(T8, "Row", T8_ROW["base"], "Required_LaborTax_Pct")),
   (T8B, "Table8B age 65 SS0_StatusQuo_Required_PAYE_Pct", lambda: t8b(65, "SS0_StatusQuo_Required_PAYE_Pct"))])

Q("PAYE_SS0_Drift_pp",
  "SS0 PAYE drift above 22.0% (percentage points)",
  [("Document 1A.md", r"\(\+(1\.\d\d) pp hike\)\*\s*\| \*\*0\.00%"),
   ("Document 1B.md", r"\(\+(1\.\d\d) pp drift vs 22\.0%\)")],
  [(T8, "Table8 row 1 Required_LaborTax_Pct - 22.0", lambda: cell(T8, "Row", T8_ROW["base"], "Required_LaborTax_Pct") - 22.0)])

Q("PAYE_SuperAge65_below_SS0_Drift_pp",
  "SS2 age-65 PAYE minimum below the SS0 status-quo drift (percentage points)",
  [("Document 1A.md", r"\*\*-(\d\.\d\d) pp\*\* below the \d+\.\d+% 2050 Status Quo drift")],
  [(T8B, "Table8B age 65 SS0 - SS2 Required PAYE",
    lambda: t8b(65, "SS0_StatusQuo_Required_PAYE_Pct") - t8b(65, "SS2_Required_PAYE_Pct"))])

Q("DepRatio_SS2_SuperAge64_pct",
  "SS2 effective fiscal dependency ratio at NZ Super age 64 (%)",
  [("Document 1A.md", r"\*\*" + NUM + r"%\*\* \| \*\*18\.25% \(-3\.75 pp Cut\)"),
   ("Document 1B.md", r"\*\*★ Age 64\*\* \| \*\*\d+\.\d+%\*\* \| \*\*" + NUM + r"%\*\*"),
   ("Document 1B.md", r"\*\*`" + NUM + r"%`\*\* \| \*\*`18\.25%`")],
  [(T8B, "Table8B age 64 SS2_Effective_DepRatio_Pct", lambda: t8b(64, "SS2_Effective_DepRatio_Pct")),
   (T8, "Table8 row 6 DepRatio_65Plus_Pct", lambda: cell(T8, "Row", T8_ROW["ss2_64"], "DepRatio_65Plus_Pct"))])

Q("DepRatio_SS0_Baseline_pct",
  "SS0 baseline 65+ dependency ratio (%)",
  [("Document 1A.md", r"\| " + NUM + r"% \| \*\*23\.61%\*\*"),
   ("Document 1B.md", r"\| `" + NUM + r"%` \| \*\*`23\.\d\d%`\*\*")],
  [(T8, "Table8 row 1 DepRatio_65Plus_Pct", lambda: cell(T8, "Row", T8_ROW["base"], "DepRatio_65Plus_Pct"))])

T7 = "Table7_4Region_Fertility_Bargaining_TFR.csv"
_T7_BASE = "1_Baseline_StatusQuo"
_T7_SS2 = "6_SS2_Lower_Super_Age_Dividend (Age 64 -> Kuia/Whanau Boost)"
_B1 = r"\*\*1\. Baseline Status Quo \(Age 65\)\*\*\s*\| `"
_B6 = r"Harvest \(Lower Super to 64\)\*\*\s*\| \*\*`"
for _q, _d, _pat, _row, _col in [
        ("TFR_Baseline_Rural", "Baseline TFR, Rural", _B1 + NUM + r"` /", _T7_BASE, "TFR_Rural"),
        ("TFR_Baseline_Auckland", "Baseline TFR, Auckland", _B1 + r"[\d.]+` / `[\d.]+` / `[\d.]+` / `" + NUM + "`", _T7_BASE, "TFR_Auckland"),
        ("TFR_SS2Age64_Rural", "SS2 (Super age 64) TFR, Rural", _B6 + NUM + r"` /", _T7_SS2, "TFR_Rural"),
        ("TFR_SS2Age64_Auckland", "SS2 (Super age 64) TFR, Auckland", _B6 + r"[\d.]+` / `[\d.]+` / `[\d.]+` / `" + NUM + "`", _T7_SS2, "TFR_Auckland")]:
    Q(_q, _d, [("Document 1B.md", _pat)],
      [(T7, "Table7 %s %s" % ("baseline" if _row == _T7_BASE else "SS2 age 64", _col),
        (lambda r=_row, c=_col: cell(T7, "Row", r, c)))])

Q("Struggling_Hyperbolic_Rural_pct",
  "Rural struggling-launch share under the hyperbolic-delay scenario (%)",
  [("Document 1A.md", r"Delayed family formation[^|]*\| " + NUM + r"% → "),
   ("Document 1B.md", tcell(r"\*\*2\. Hyperbolic Delay", 2, r"`" + NUM + r"%`"))],
  [(T8, "Table8 row 2 Struggling_Pct_Rural",
    lambda: cell(T8, "Row", "2_Hyperbolic_NoCommit (beta=0.72, No ECE)", "Struggling_Pct_Rural"))])

Q("IGE_reduction_FirstThousandDays_only_pct",
  "National IGE reduction from the First-2000-Days lever alone (P0_Early_0to5) (%)",
  [("Document 1A.md", r"by \*\*" + NUM + r"%\*\* \(from \*\*0\.350 down to 0\.233\*\*\)"),
   ("Document 1B.md", r"`P0_Early_0to5`\*\* \*\(First 2000 Days\)\* \| \*\*`0\.233` \(-" + NUM + r"%\)")])

Q("IGE_reduction_FullPackage_pct",
  "National IGE reduction from the full package (P0_Plus_GrantE / SS2) (%)",
  [("Document 1B.md", r"`P0_Plus_GrantE`\*\* \*\(Full Package\)\* \| \*\*`0\.218` \(-" + NUM + r"%\)"),
   ("Document 1B.md", r"65\.0%\+ Mentored\*\* \(-" + NUM + r"% IGE\)"),
   ("Document 1C.md", r"one-third \(-" + NUM + r"%\)"),
   ("Document 2B.md", r"\*\*-" + NUM + r"% IGE reduction\*\*"),
   ("Document 2B.md", r"and -" + NUM + r"% IGE reduction")])

Q("PSI_sandwich",
  "psi_sandwich (sandwich-generation elder-care drag) as written in the text",
  [("Document 1B.md", r"Params\.psi_sandwich_wrk_drag` \| [^|]*\| `(0\.\d+)`"),
   ("Document 2B.md", r"\\psi_\{\\mathrm\{sandwich\}\} = (0\.\d+)"),
   ("Document 2B.md", r"psi_sandwich_wrk_drag = (0\.\d+)`"),
   ("Document 2T.md", r"\\psi_\{\\mathrm\{sandwich\}\} = (0\.\d+)"),
   ("Document 3.md", r"\\psi_\{\\mathrm\{sandwich\}\} = (0\.\d+)")])

Q("CE_FiscalStewards_Standalone_Low_pct",
  "Fiscal Stewards standalone CE lower bound (%, magnitude); cited column is Table 21",
  [("Document 3.md", r"\*\*-6\.80% to -" + NUM + r"% CE\*\*")],
  [(T21, "Table21 min CE_AusterityFirst_Pct (magnitude)", lambda: -min(col_vals(T21, "CE_AusterityFirst_Pct"))),
   (T22, "Table22 row 4 Net_In_Sinking_LTFM_CE (magnitude)",
    lambda: -cell(T22, "Coalition_Constituency", "4. Fiscal Stewards (Debt-Sinking + PAYE Relief)", "Net_In_Sinking_LTFM_CE"))])

_SH1 = r"`1_Severe_Material_Hardship_DEP17`"
_G4 = r"`10_Struggling_Tier_h1_h2`"
_G4F = r"`14_Struggling_Tier_h1_h2_Launch`"
for _i, (_q, _nm, _node15, _node14) in enumerate([
        ("SS0_LaunchTier_Struggling_pct", "Struggling (h1-h2)", "10_Struggling_Tier_h1_h2", "14_Struggling_Tier_h1_h2_Launch"),
        ("SS0_LaunchTier_Core_pct", "Core skill (h3-h5)", "11_Core_Skill_Tier_h3_h5", "15_Core_Skill_Tier_h3_h5_Launch"),
        ("SS0_LaunchTier_Thriving_pct", "Thriving (h6-h7)", "12_Thriving_Tier_h6_h7", "16_Thriving_Tier_h6_h7_Launch")]):
    Q(_q, "National SS0 adult-launch tier share, %s (%%)" % _nm,
      [("Document 1B.md", br(_G4, _i)),
       ("Document 1B.md", br_flow(_G4F, _i))],
      [(T15N, "Table15 National SS0_Pop_Pct %s" % _node15, (lambda n=_node15: cell(T15N, "Node_Name", n, "SS0_Pop_Pct"))),
       (T14N, "Table14 National SS0_Pop_Pct %s" % _node14, (lambda n=_node14: cell(T14N, "Node_Name", n, "SS0_Pop_Pct")))])
QUANTITIES["SS0_LaunchTier_Thriving_pct"]["docs"] = [
    ("Document 1B.md", br(_G4, 2)),
    ("Document 1B.md", br_flow(_G4F, 2)),
    ("Document 1A.md", r"talent pool from \*\*" + NUM + r"% to over 61\.0%\*\*"),
    ("Document 1C.md", r"from \*\*" + NUM + r"% to 65\.0%\*\*"),
]

Q("SS0_Hardship_Node1_pct",
  "National SS0 birth share in material and severe hardship (Node 1) (%)",
  [("Document 1B.md", br(_SH1, 0)),
   ("Document 1B.md", br_flow(r"`1_Material_And_Severe_Hardship`", 0)),
   ("Document 1A.md", r"\*\*" + NUM + r"% in Material & Severe Material Hardship"),
   ("Document 2B.md", r"~" + NUM + r"% of births at Gate 1 Node 1")],
  [(T15N, "Table15 National SS0_Pop_Pct Node 1", lambda: cell(T15N, "Node_Name", "1_Severe_Material_Hardship_DEP17", "SS0_Pop_Pct")),
   (T14N, "Table14 National SS0_Pop_Pct Node 1", lambda: cell(T14N, "Node_Name", "1_Material_And_Severe_Hardship", "SS0_Pop_Pct"))])

Q("SS0_Corner_ic0_pct",
  "National SS0 share in the unmitigated i_c = 0 corner (%)",
  [("Document 1B.md", br(r"`4_Unmitigated_Corner_ic0`", 0)),
   ("Document 1B.md", br_flow(r"`5_ECE_Corner_Benefit_Need`", 0)),
   ("Document 1A.md", r"leaving \*\*" + NUM + r"%\*\* trapped in the unmitigated")],
  [(T15N, "Table15 National SS0_Pop_Pct Node 4", lambda: cell(T15N, "Node_Name", "4_Unmitigated_Corner_ic0", "SS0_Pop_Pct")),
   (T14N, "Table14 National SS0_Pop_Pct Node 5", lambda: cell(T14N, "Node_Name", "5_ECE_Corner_Benefit_Need", "SS0_Pop_Pct"))])


def _breakeven_last_negative_year():
    last = None
    for r in rows(T20):
        if float(r["Net_Unrecovered_Outlay_Mirror_CE"]) < -0.005:
            last = float(r["Year"])
    return last


Q("CashBreakeven_Year",
  "Year in which Net Unrecovered Public Outlay reaches zero (cash breakeven)",
  [(None, r"\bYear (\d{2}\.\d)\b")],
  [(T20, "Table20 last grid year with Net_Unrecovered_Outlay_Mirror_CE < 0 (breakeven must be later)",
    _breakeven_last_negative_year)],
  cmp=lambda d, c: d > c)

Q("CE_SS2_National_Total_pct",
  "SS2 national long-run welfare gain (CE %)",
  [(None, r"\+(24\.(?:24|70))(?=%)(?! \(PEAK\))(?!\*\* \(Rural)")],
  [(T8B, "Table8B age 64 SS2_National_Welfare_CE_Pct", lambda: t8b(64, "SS2_National_Welfare_CE_Pct")),
   (T21, "Table21 Year 60 CE_Unified_SS1_SS2_Pct", lambda: t21_year(60, "CE_Unified_SS1_SS2_Pct")),
   (T19, "Table19 sum of SS2_National_CE over 11 layers", lambda: sum(col_vals(T19, "SS2_National_CE")))])

Q("CE_SS2_IsolatedSum_pct",
  "SS2 national CE from the 7 isolated factors (%)",
  [(None, r"\+(11\.23)(?:%|\s?pp)")],
  [(T19, "Table19 sum of SS2_National_CE over Isolated_Factor rows",
    lambda: sum(float(r["SS2_National_CE"]) for r in rows(T19) if r["Component_Type"] == "Isolated_Factor"))])

Q("CE_SS2_WedgeSum_pct",
  "SS2 national CE from the 4 synergy wedges (%)",
  [(None, r"\+(13\.47|11\.46)(?:%|\s?pp)")],
  [(T19, "Table19 sum of SS2_National_CE over SYNERGY_WEDGE rows",
    lambda: sum(float(r["SS2_National_CE"]) for r in rows(T19) if r["Component_Type"] != "Isolated_Factor"))])

Q("CE_SS2_WedgeShare_pct",
  "Wedge share of the SS2 national gain (%)",
  [(None, r"(54\.5|47\.3)% \(\+(?:13\.47|11\.46)% CE\)"),
   ("Document 1A.md", r"\*\*(54\.5)%\*\* of which is generated"),
   ("Document 1A.md", r"\((54\.5)% Wedges\)"),
   ("Document 1C.md", r"(54\.5)% of that entire gain"),
   ("Document 1C.md", r"(54\.5)% from dynamic complementarity"),
   ("Document 2B.md", r"\+13\.47 pp, (54\.5) pct share"),
   ("Document 3.md", r"`\+13\.47%`, `(54\.5)%`")],
  [(T19, "Table19 wedge sum / total * 100",
    lambda: 100.0 * sum(float(r["SS2_National_CE"]) for r in rows(T19) if r["Component_Type"] != "Isolated_Factor")
    / sum(col_vals(T19, "SS2_National_CE")))])

Q("CE_SS1_National_Total_pct",
  "SS1 national long-run welfare gain (CE %)",
  [("Document 1A.md", r"\*\*\+(15\.04)%\*\* \| \*\*54% to 62%"),
   ("Document 1A.md", r"4 Wedges \(`\+13\.47%`\)\*\* \| \*\*\+(15\.04)%\*\*"),
   ("Document 2B.md", r"\[\+(15\.04)% National\]")],
  [(T19, "Table19 sum of SS1_National_CE over 11 layers", lambda: sum(col_vals(T19, "SS1_National_CE")))])

_REG = ["Rural", "Small", "Large", "Auckland"]
for _ph, _row, _lab1a, _lab1b in [
        ("SS1_3", "SS1_3_LongRun_GE_EndoIntergen", r"\*\*Phase 1 \(`SS1`\): 3\. Long-Run GE \(Endogenous Intergen\)\*\*", r"`SS1_3_LongRun_GE_EndoIntergen`\*\*"),
        ("SS2_3", "SS2_3_LongRun_GE_EndoIntergen", r"\*\*Phase 2 \(`SS2`\): 3\. Long-Run GE \(Endogenous Intergen\)\*\*", r"`SS2_3_LongRun_GE_EndoIntergen`\*\*")]:
    for _k, _reg in enumerate(_REG):
        Q("T1_%s_%s_CE_pct" % (_ph, _reg),
          "Table 1 row %s, %s CE (%%)" % (_row, _reg),
          [("Document 1A.md", tcell(_lab1a, 1 + _k, r"\+" + NUM + "%")),
           ("Document 1B.md", tcell(_lab1b, _k, r"\+" + NUM + "%")),
           ("Document 1B.md", tcell(_lab1b, _k, r"\(`" + NUM + r"`\)"))],
          [(T1, "Table1 %s %s_CE_Pct" % (_row, _reg),
            (lambda r=_row, g=_reg: cell(T1, "Row", r, g + "_CE_Pct")))])

# ---------------------------------------------------------------------------
# Sankey stated counts.  (file or None for all docs, regex, kind, what)
# kind: fates_nodes | fiscal_nodes | fates_stages | fiscal_gates
# ---------------------------------------------------------------------------
SANKEY_STATED = [
    (None, r"5[- ]Stages?,? \(?" + r"(\d+)[- ]Nodes?", "fates_nodes"),
    (None, r"(\d+) nodes of our cohort lifecycle", "fates_nodes"),
    (None, r"Translating the (\d+) nodes of the Population Sankey", "fates_nodes"),
    (None, r"in the (\d+)-Node Sankey Architecture", "fates_nodes"),
    (None, r"Plot_ChildFates_SSankey\.m` across (\d+) nodes", "fates_nodes"),
    (None, r"\*\((\d+)-Node Pop & \d+-Node Fiscal\)\*", "fates_nodes"),
    (None, r"the (\d+)-node Sankey (?:architecture|diagram|aggregation)", "fates_nodes"),
    (None, r"Pop_(\d+)Nodes_Pct", "fates_nodes"),
    (None, r"6[- ]Gates?,? \(?(\d+)[- ]Nodes?", "fiscal_nodes"),
    (None, r"and the (\d+) nodes of our fiscal ledger", "fiscal_nodes"),
    (None, r"and (\d+) nodes of the Fiscal Sankey", "fiscal_nodes"),
    (None, r"Plot_ChildFiscal_SSankey\.m` across (\d+) nodes", "fiscal_nodes"),
    (None, r"\*\(\d+-Node Pop & (\d+)-Node Fiscal\)\*", "fiscal_nodes"),
    (None, r"\*\((\d+) Nodes across 6 Gates", "fiscal_nodes"),
    (None, r"the (\d+)-Node Fiscal Ledger is split", "fiscal_nodes"),
    (None, r"Under the (\d+)-Node Solution 1", "fiscal_nodes"),
    (None, r"our (\d+)-Node Fiscal Sankey", "fiscal_nodes"),
    (None, r"Cohort-Weighted Ribbon Width Identity Across (\d+) Nodes", "fiscal_nodes"),
    (None, r"i \\in \\\{1, \\dots, (\d+)\\\}\$ across Gates", "fiscal_nodes"),
    (None, r"(\d+)[- ]Stages?,? \(?\d+[- ]Nodes?", "fates_stages"),
    (None, r"(\d+)[- ]Gates?,? \(?\d+[- ]Nodes?", "fiscal_gates"),
    (None, r"Nodes across (\d+) Gates", "fiscal_gates"),
    ("Plot_ChildFates_SSankey.m", r"\((\d+)-Node\)", "fates_nodes"),
    ("Plot_ChildFates_SSankey.m", r"across all (\d+) nodes", "fates_nodes"),
    ("Plot_ChildFiscal_SSankey.m", r"6-Gate \((\d+)-Node\)", "fiscal_nodes"),
    ("Plot_ChildFiscal_SSankey.m", r"(\d+)-Node, 6-Gate", "fiscal_nodes"),
    ("Plot_ChildFiscal_SSankey.m", r"(\d+)-Node Palette", "fiscal_nodes"),
    ("getFatesRibbonNarratives.m", r"\((\d+)-Node\)", "fates_nodes"),
    ("getFiscalRibbonNarratives.m", r"\((\d+)-Node\)", "fiscal_nodes"),
]


def sankey_actual():
    """Actual counts from the committed CSVs and HTML explorers."""
    fates, fiscal = {}, {}
    for p in sorted(glob.glob(os.path.join(ROOT, OUT, "Table15_ChildFates_5Stage_Decomp_*.csv"))):
        r = list(csv.DictReader(open(p, newline="", encoding="utf8")))
        fates[os.path.basename(p)] = (len(r), len({x["Gate"].split("_")[0] for x in r}))
    for p in sorted(glob.glob(os.path.join(ROOT, OUT, "Table14_FiscalLedger_6Gate_Decomp_*.csv"))):
        r = list(csv.DictReader(open(p, newline="", encoding="utf8")))
        fiscal[os.path.basename(p)] = (len(r), len({x["Gate"].split("_")[0] for x in r}))
    html = {}
    for p in sorted(glob.glob(os.path.join(ROOT, OUT, "Interactive_*.html"))):
        txt = open(p, encoding="utf8").read()
        html[os.path.basename(p)] = len(re.findall(r'class="sankey-block"', txt))
    return fates, fiscal, html


# ---------------------------------------------------------------------------
# Findings
# ---------------------------------------------------------------------------
class Finding:
    def __init__(self, category, key, text, cites):
        self.category, self.key, self.text, self.cites = category, key, text, cites
        self.known = None

    def sort_key(self):
        return (self.category, self.key, self.text)


def decs(s):
    return len(s.split(".")[1]) if "." in s else 0


def close(a, da, b, db):
    return abs(a - b) <= 0.5 * 10 ** (-min(da, db)) + 1e-9


def read_lines(rel):
    with open(os.path.join(ROOT, rel), encoding="utf8") as fh:
        return fh.read().split("\n")


_lines_cache = {}


def lines_of(rel):
    if rel not in _lines_cache:
        _lines_cache[rel] = read_lines(rel)
    return _lines_cache[rel]


def targets(fspec):
    return DOCS if fspec is None else [fspec]


def extract(pattern_list):
    """-> (hits [(file, line, valstr)], stale [(file, regex)])"""
    hits, stale = [], []
    for fspec, rx in pattern_list:
        crx = re.compile(rx)
        n = 0
        for f in targets(fspec):
            for i, ln in enumerate(lines_of(f), 1):
                for m in crx.finditer(ln):
                    hits.append((f, i, m.group(1)))
                    n += 1
        if n == 0:
            stale.append((fspec or "*", rx))
    return hits, stale


def cite(f, i, v=None):
    return "%s:%d" % (f, i) + (" (%s)" % v if v is not None else "")


def check_quantities():
    out = []
    for q in QUANTITIES.values():
        hits, stale = extract(q["docs"])
        for fspec, rx in stale:
            out.append(Finding("REGISTRY", q["name"], "pattern matched nothing: `%s` in %s" % (rx, fspec), []))
        # CSV values
        csvv = []
        for fname, label, fn in q["csv"]:
            try:
                csvv.append((fname, label, fn()))
            except Exception as e:  # missing/renamed CSV or column
                out.append(Finding("REGISTRY", q["name"], "CSV extractor failed (%s): %s" % (label, e), []))
        # CSV vs CSV
        for a in range(len(csvv)):
            for b in range(a + 1, len(csvv)):
                if q["cmp"] is None and abs(csvv[a][2] - csvv[b][2]) > 0.005 + 1e-9:
                    out.append(Finding(
                        "CSV_VS_CSV", q["name"],
                        "%s = %.4f  vs  %s = %.4f" % (csvv[a][1], csvv[a][2], csvv[b][1], csvv[b][2]), []))
        if not hits:
            continue
        # group doc hits by value string (cites de-duplicated, document order)
        byval = OrderedDict()
        for f, i, v in sorted(set(hits), key=lambda h: (DOCS.index(h[0]) if h[0] in DOCS else 99, h[1], h[2])):
            byval.setdefault(v, []).append((f, i))
        vals = list(byval)
        # doc vs doc (skipped when a custom cmp is used: those are one-sided thresholds)
        if q["cmp"] is None:
            bad = any(not close(float(vals[a]), decs(vals[a]), float(vals[b]), decs(vals[b]))
                      for a in range(len(vals)) for b in range(a + 1, len(vals)))
            if bad:
                cites, text = [], []
                for v in vals:
                    ms = [fn_.split("_")[0] for fn_, _, c in csvv if close(float(v), decs(v), c, decs(v))]
                    text.append("%s%s" % (v, (" [matches CSV: %s]" % ", ".join(ms)) if ms else ""))
                    cites += [cite(f, i, v) for f, i in byval[v]]
                out.append(Finding("DOC_VS_DOC", q["name"],
                                   "%s: documents state %s" % (q["desc"], "; ".join(text)), cites))
        # doc vs CSV: one finding per quantity, listing every CSV source that disagrees
        text, cites = [], []
        for fname, label, c in csvv:
            off = [v for v in vals
                   if not (q["cmp"](float(v), c) if q["cmp"] else close(float(v), decs(v), c, decs(v)))]
            if off:
                text.append("%s = %.4f vs documents %s" % (label, c, ", ".join(off)))
                for v in off:
                    cites += [cite(f, i, v) for f, i in byval[v] if cite(f, i, v) not in cites]
        if text:
            out.append(Finding("DOC_VS_CSV", q["name"], "%s: %s" % (q["desc"], "; ".join(text)), cites))
    return out


# ----- links ---------------------------------------------------------------
def exists_cs(rel):
    """Case-sensitive existence check relative to ROOT."""
    cur = ROOT
    parts = [p for p in rel.replace("\\", "/").split("/") if p not in ("", ".")]
    for p in parts:
        try:
            names = os.listdir(cur)
        except OSError:
            return False
        if p not in names:
            return False
        cur = os.path.join(cur, p)
    return True


def slug(heading):
    h = heading.strip().lower()
    h = re.sub(r"[^\w\- ]", "", h, flags=re.UNICODE)
    return h.replace(" ", "-")


def anchors_of(rel):
    seen, out = defaultdict(int), set()
    in_code = False
    for ln in lines_of(rel):
        if ln.lstrip().startswith("```"):
            in_code = not in_code
        m = re.match(r"^(#{1,6})\s+(.*?)\s*#*\s*$", ln)
        if m and not in_code:
            s = slug(m.group(2))
            n = seen[s]
            seen[s] += 1
            out.add(s if n == 0 else "%s-%d" % (s, n))
    return out


LINK_RX = re.compile(r"\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)|(?:src|href)=\"([^\"]+)\"")
FILEREF_RX = re.compile(r"(?<![A-Za-z0-9_/.%-])([A-Za-z][A-Za-z0-9_\-]*\*?[A-Za-z0-9_\-]*\.(?:m|csv|png|html))\b")


def check_links():
    out = []
    broken = defaultdict(list)
    anch = defaultdict(list)
    ghbad = defaultdict(list)
    missing_ref = defaultdict(list)
    for f in DOCS:
        for i, ln in enumerate(lines_of(f), 1):
            for m in LINK_RX.finditer(ln):
                t = m.group(1) or m.group(2)
                if t.startswith("mailto:"):
                    continue
                if t.startswith(("http://", "https://")):
                    u = urllib.parse.urlparse(t)
                    if u.netloc == "github.com" and u.path.startswith("/MichaelTiemann/IGWelfare/"):
                        rest = urllib.parse.unquote(u.path[len("/MichaelTiemann/IGWelfare/"):])
                        mm = re.match(r"(?:blob|tree|raw)/[^/]+/(.*)$", rest)
                        if not mm:
                            ghbad[t].append(cite(f, i))
                        elif not exists_cs(mm.group(1)):
                            broken[t].append(cite(f, i))
                    continue
                path, _, frag = t.partition("#")
                p = urllib.parse.unquote(path)
                target = f if p == "" else p
                if p != "" and not exists_cs(p):
                    broken[t].append(cite(f, i))
                    continue
                if frag and target.endswith(".md") and exists_cs(target):
                    if urllib.parse.unquote(frag).lower() not in anchors_of(target):
                        anch[t].append(cite(f, i))
            for m in FILEREF_RX.finditer(ln):
                name = m.group(1)
                if "<" in name:
                    continue
                if "*" in name:
                    ok = any(fnmatch.fnmatch(x, name) for d in ("", OUT) for x in os.listdir(os.path.join(ROOT, d)))
                else:
                    ok = exists_cs(name) or exists_cs(OUT + "/" + name)
                if not ok:
                    missing_ref[name].append(cite(f, i))
    for t, c in sorted(broken.items()):
        out.append(Finding("LINK", t, "link target does not exist (case-sensitive)", c))
    for t, c in sorted(anch.items()):
        out.append(Finding("LINK", t, "anchor does not match any heading in the target file", c))
    for t, c in sorted(ghbad.items()):
        out.append(Finding("LINK", t, "GitHub URL has no blob/<branch>/ (or tree/) segment, so it is not a file URL", c))
    for t, c in sorted(missing_ref.items()):
        out.append(Finding("LINK", t, "referenced file is not in the repository", c))
    return out


def check_sankey():
    out = []
    fates, fiscal, html = sankey_actual()
    fn = {v[0] for v in fates.values()}
    fg = {v[1] for v in fates.values()}
    sn = {v[0] for v in fiscal.values()}
    sg = {v[1] for v in fiscal.values()}
    hf = {n for k, n in html.items() if "ChildFates" in k}
    hs = {n for k, n in html.items() if "ChildFiscal" in k}
    for lab, a, b in [("fates nodes", fn, hf), ("fiscal nodes", sn, hs)]:
        if len(a) != 1 or a != b:
            out.append(Finding("CSV_VS_CSV", "sankey_" + lab.replace(" ", "_"),
                               "CSV row counts %s vs HTML node blocks %s" % (sorted(a), sorted(b)), []))
    if len(fg) != 1 or len(sg) != 1:
        out.append(Finding("CSV_VS_CSV", "sankey_gates", "CSV gate counts differ: fates %s fiscal %s" % (sorted(fg), sorted(sg)), []))
    actual = {"fates_nodes": min(fn), "fiscal_nodes": min(sn), "fates_stages": min(fg), "fiscal_gates": min(sg)}
    seen = defaultdict(list)
    for fspec, rx, kind in SANKEY_STATED:
        crx = re.compile(rx)
        n = 0
        for f in targets(fspec):
            for i, ln in enumerate(lines_of(f), 1):
                for m in crx.finditer(ln):
                    n += 1
                    seen[(kind, int(m.group(1)))].append(cite(f, i))
        if n == 0:
            out.append(Finding("REGISTRY", "sankey_" + kind, "pattern matched nothing: `%s` in %s" % (rx, fspec or "*"), []))
    for (kind, v), cites in sorted(seen.items()):
        if v != actual[kind]:
            out.append(Finding("SANKEY", kind + "=" + str(v),
                               "stated %d, actual %d (CSV rows/gates and HTML blocks)" % (v, actual[kind]),
                               sorted(set(cites))))
    return out, actual, fates, fiscal, html


def apply_known(findings):
    km = {(c, k): r for c, k, r in KNOWN_AUTHOR_DECISIONS}
    used = set()
    for f in findings:
        r = km.get((f.category, f.key))
        if r is not None:
            f.known = r
            used.add((f.category, f.key))
    unused = sorted(set(km) - used)
    return unused


CATEGORIES = [
    ("LINK", "Unresolved links and file references"),
    ("SANKEY", "Sankey node / gate counts: stated vs actual"),
    ("DOC_VS_DOC", "Documents disagree with each other"),
    ("DOC_VS_CSV", "Documents disagree with a committed CSV"),
    ("CSV_VS_CSV", "Committed CSVs disagree with each other"),
    ("REGISTRY", "Registry health (patterns that match nothing, extractor errors)"),
]


def render(findings, actual, fates, fiscal, html, unused_known):
    L = []
    L.append("# Documentation consistency report")
    L.append("")
    L.append("Generated by `tools/check_docs_consistency.py` (regenerate with `python3 tools/check_docs_consistency.py`).")
    L.append("Output is deterministic. Only registered quantities are checked; see `QUANTITIES` in the script.")
    L.append("")
    L.append("## Summary")
    L.append("")
    L.append("| Category | Findings | Known author decisions | Unresolved |")
    L.append("| :--- | ---: | ---: | ---: |")
    tot = [0, 0, 0]
    for c, title in CATEGORIES:
        fs = [f for f in findings if f.category == c]
        k = sum(1 for f in fs if f.known)
        L.append("| %s | %d | %d | %d |" % (c, len(fs), k, len(fs) - k))
        tot[0] += len(fs)
        tot[1] += k
        tot[2] += len(fs) - k
    L.append("| **Total** | **%d** | **%d** | **%d** |" % tuple(tot))
    L.append("")
    L.append("Registry: %d named quantities, %d Sankey count patterns; %d documents scanned." % (
        len(QUANTITIES), len(SANKEY_STATED), len(DOCS)))
    L.append("")
    L.append("## Sankey ground truth")
    L.append("")
    L.append("| Diagram | Nodes | Gates/stages | Sources |")
    L.append("| :--- | ---: | ---: | :--- |")
    L.append("| Child fates | %d | %d | %d Table15 CSVs; %d HTML explorers |" % (
        actual["fates_nodes"], actual["fates_stages"], len(fates), sum(1 for k in html if "ChildFates" in k)))
    L.append("| Child fiscal | %d | %d | %d Table14 CSVs; %d HTML explorers |" % (
        actual["fiscal_nodes"], actual["fiscal_gates"], len(fiscal), sum(1 for k in html if "ChildFiscal" in k)))
    L.append("")
    for c, title in CATEGORIES:
        fs = sorted([f for f in findings if f.category == c], key=Finding.sort_key)
        L.append("## %s: %s" % (c, title))
        L.append("")
        if not fs:
            L.append("No findings.")
            L.append("")
            continue
        for f in fs:
            L.append("- **%s**%s" % (f.key, " *(known author decision)*" if f.known else ""))
            L.append("  - %s" % f.text)
            if f.known:
                L.append("  - Reason: %s" % f.known)
            if f.cites:
                L.append("  - Cites: " + ", ".join(f.cites))
        L.append("")
    if unused_known:
        L.append("## Resolved (no longer observed)")
        L.append("")
        for c, k in unused_known:
            L.append("- %s / %s (known entry with no matching finding; not a strict failure, can be removed from the list)" % (c, k))
        L.append("")
    return "\n".join(L).rstrip() + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--strict", action="store_true", help="exit 1 if any finding is not in KNOWN_AUTHOR_DECISIONS")
    ap.add_argument("--no-write", action="store_true", help="do not rewrite tools/CONSISTENCY_REPORT.md")
    a = ap.parse_args()
    findings = check_links()
    sf, actual, fates, fiscal, html = check_sankey()
    findings += sf
    findings += check_quantities()
    unused = apply_known(findings)
    report = render(findings, actual, fates, fiscal, html, unused)
    if not a.no_write:
        with open(REPORT, "w", encoding="utf8") as fh:
            fh.write(report)
    print("category counts (total / known / unresolved):")
    unresolved = 0
    for c, _ in CATEGORIES:
        fs = [f for f in findings if f.category == c]
        k = sum(1 for f in fs if f.known)
        unresolved += len(fs) - k
        print("  %-11s %3d / %3d / %3d" % (c, len(fs), k, len(fs) - k))
    print("  %-11s %3d / %3d / %3d" % ("TOTAL", len(findings), len(findings) - unresolved, unresolved))
    if unused:
        print("resolved known entries (no longer observed, not a failure): %d" % len(unused))
        for c, k in unused:
            print("  resolved: %s / %s" % (c, k))
    if a.strict and unresolved:
        print("STRICT: FAIL (%d unresolved finding(s))" % unresolved)
        return 1
    if a.strict:
        print("STRICT: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
