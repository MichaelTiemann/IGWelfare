# Document 2: Intergenerational Welfare Technical Documentation & Model Specification Guide (Master Index & Directory)
*A GPU-Accelerated Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial Overlapping Generations Framework (Multiphase Edition)*

**Author:** Michael Tiemann ([mdtiemann@gmail.com](mailto:mdtiemann@gmail.com))  
**Date:** November 2026 | **Code & Replication Repository:** [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)  
*Companion to [Document 1A](Document%201A.md) (Strategic Monograph), [Document 1B](Document%201B.md) (Empirical Answer Key), [Document 1C](Document%201C.md) (Executive Brief), [Document 1D](Document%201D.md) (Te Kāhui Waka Sequencing), [Document 1E](Document%201E.md) (Grassroots Civic Mycelium), [Document 1F](Document%201F.md) (Citizens' Assembly Compact), [Document 3](Document%203.md) (Leaving Our Silos), and [GLOSSARY.md](GLOSSARY.md) (Master Glossary & Ledger Index)*

---

## Technical Architecture Organization (`Document 2A`, `Document 2B`, `Document 2C`, & `Document 2T`)

To keep every volume comfortably within GitHub's per-file MathJax limits (~80–105 KB per volume) with **globally unique section identifiers**, **Document 2** is structured as a **continuous 3-volume specification series (`Sections 1–12`)** paired with a standalone tutorial volume using the **`T1`–`T7` namespace**:

1. **[Document 2A: Part A — Micro-Foundations, Core Agent Problems, & Sectoral Operators (`Sections 1–4`)](Document%202A.md)**  
   *Mixed-Horizon 8-PType architecture, exact $\Delta t$-scaling laws, infinite-horizon Guvenen et al. (2023) firms, endogenous spatial GE clearing (`Solve_Spatial_GE_Loop.m`: stationary $\Gamma_k$, MPL wages $w_k$, Hirano–Toda / $\delta_{H,k}$ housing capitalization $Q_k$, and competition drift $\Delta \mu_{z,k}$), 5-Sector Biophysical-Exergy SOE closure, canonical 5D Experience-Asset household problem (`ReturnFn_SpatialHH.m`, `HumanCapital_Lifecycle_aprimeFn.m`), and $4 \times 5$ intergenerational/migration operators (`Build_IntergenTransitionMatrix.m`).*
2. **[Document 2B: Part B — Coupled Equilibrium Synthesis, Distributional Incidence, SMM Calibration, Transition Dynamics, & Supermodular Attribution (`Sections 5–7`)](Document%202B.md)**  
   *6-Gate (29-Node) Lifecycle Fiscal Sankey, 2050 50/50 Sovereign Debt-Sinking Protocol, cooperative hyperbolic fertility bargaining, NZ Superannuation eligibility-age U-curve (Ages 60–75), 10-tier survey-anchored incidence, exact horizon-normalized 5D distributional welfare integrals (`T1`–`T3`) & endogenous dynastic $\bar{h}_{p,k}$ closure (`Compute_WelfareDecomposition_4Region.m`), two-stage Sobol + Nelder-Mead SMM calibration, 60-year transition paths, ACC Actuarial Continuation Valuation, 11-layer supermodular attribution (`[2B-Prop-Wedge1]`), SVG/HTML5 explorers, and 13-wave Te Kāhui Waka frictions.*
3. **[Document 2C: Part C — Compositional Policy Algebra, Combinatorial Citizens' Assembly Clearinghouse, Cross-Country Validation, & Master Annexes (`Sections 8–12`)](Document%202C.md)**  
   *Sparse 26-code compositional policy algebra (`C01`–`C18`, `C21`–`C28`), Topkis vs. Baker–Campbell–Hausdorff (`BCH`) operator commutators, five two-sided mirror regimes, non-minimum-phase trim-tab control dynamics, Milgrom–Topkis supermodular combinatorial Citizens' Assembly clearinghouse (`K01`–`K15`) & `GREEN`/`AMBER`/`RED` shock frontiers, unified literature contributions, out-of-sample 58-year Finnish twin validation (`FI_Peruskoulu1967` & `FI_FBC1987`), Scotland & Deming-to-Tokyo Coda, consolidated 34-test codebase manifest, and 60-reference Master Library.*
4. **[Document 2T: Standalone Technical Tutorial — "Thick" vs. "Thin" Numbers in Quantitative Public Policy (`Sections T1–T7`)](Document%202T.md)**  
   *Pedagogical walkthrough and Jensen's Inequality proofs for dimension-free state-contingent conditioning, Topkis/`BCH` policy composition, and 1972-to-2026 backlog homotopy stress-testing of the Five-Assembly combinatorial auction (`Sections T1–T7`).*

---

## Quick Section-by-Section Routing Table (`Sections 1–12` & `Sections T1–T7`)

| Section ID | Section Title & Core MATLAB / Octave Operators | Volume & Direct Link |
| :--- | :--- | :--- |
| **Section 1** | **Model Overview, Spatial Taxonomy, & Flexible Period Resolution** (`Configure_Model_Params.m`, 8-PType Mixed-Horizon Architecture) | **[Document 2A (Section 1)](Document%202A.md)** |
| **Section 2** | **Infinite-Horizon Firms, Spatial GE Clearing, & 5-Sector Exergy SOE** (`ReturnFn_Firm.m`, `Solve_Spatial_GE_Loop.m`, `Compute_5Sector_Exergy_Equilibrium.m`) | **[Document 2A (Section 2)](Document%202A.md)** |
| **Section 3** | **Canonical 5D Finite-Horizon Household Problem Across Aspects 1, 2, & 3** (`ReturnFn_SpatialHH.m`, `HumanCapital_Lifecycle_aprimeFn.m`, *Tuakana–Teina* & *Whānau*) | **[Document 2A (Section 3)](Document%202A.md)** |
| **Section 4** | **Vectorized Intergenerational & $4 \times 5$ Spatial Migration Operators** (`Build_IntergenTransitionMatrix.m`, $Q_h$, $\mathbf{Q}_a$, $\Pi_{\mathrm{mig}}$, & 13-Wave Convex Mixing) | **[Document 2A (Section 4)](Document%202A.md)** |
| **Section 5** | **Post-Hoc Lifecycle Operators, Statutory Rules, Fertility, & Exact 5D `T1`–`T3` Integrals** (`Plot_ChildFiscal_SSankey.m`, `Compute_FiscalSolvency_And_Fertility.m`, `Compute_WelfareDecomposition_4Region.m`) | **[Document 2B (Section 5)](Document%202B.md)** |
| **Section 6** | **Calibration & Two-Stage Sobol + Nelder-Mead SMM Identification** (`Calibrate_NZ_Moments.m`, 15 NZ Empirical Moments, Ferriere et al. In-Kind Weights) | **[Document 2B (Section 6)](Document%202B.md)** |
| **Section 7** | **Multiphase Transition Path, Actuarial Continuation Valuation, 11-Layer Attribution, & *Te Kāhui Waka*** (`TransPath_4Region_Master.m`, `Plot_ActuarialContinuationValuation.m`, `[2B-Prop-Wedge1]`) | **[Document 2B (Section 7)](Document%202B.md)** |
| **Section 8** | **Compositional Policy Algebra, Five Mirror Regimes, & Non-Minimum-Phase Trim-Tab Control** (`Compose_Policy_Bundle.m`, `Compute_Policy_Composition_Batch.m`, `Compute_Helm_TrimTab_Ledger.m`) | **[Document 2C (Section 8)](Document%202C.md)** |
| **Section 9** | **Milgrom–Topkis Combinatorial Citizens' Assembly Clearinghouse & Unified Contributions** (`Compute_Assembly_Clearinghouse_Ledger.m`, `Compute_Contract_Shock_Sensitivity_Ledger.m`) | **[Document 2C (Section 9)](Document%202C.md)** |
| **Section 10** | **Cross-Country Validation, 58-Year Finnish Twin (`FI_Peruskoulu1967` / `FI_FBC1987`), Scotland, & Deming-to-Tokyo Coda** (`Finland_Twin_Validation.md`, `test_finland_profiles.m`) | **[Document 2C (Section 10)](Document%202C.md)** |
| **Section 11** | **Consolidated Modular Codebase Manifest** (`setup_igw_paths.m`, `profiles/`, `src/`, `plots/`, `pipelines/`, & 34-test suite in `tests/`) | **[Document 2C (Section 11)](Document%202C.md)** |
| **Section 12** | **Annex: Master 60-Reference Library & Empirical Source of Truth** (Decile-Indexed References `[1]`–`[60]` across 6 Folders) | **[Document 2C (Section 12)](Document%202C.md)** |
| **Sections T1–T7** | **Standalone Tutorial: "Thick" vs. "Thin" Numbers, Sub-Manifold Conditioning, & 1972-to-2026 Auction Homotopy** (`Compute_ThickVsThin_Auction_ABM.m`) | **[Document 2T (`Sections T1–T7`)](Document%202T.md)** |
| **Reference** | **Master Glossary, 12-Ledger Index, `OIA 20250878` / `LTFM` Lexicon, Nobel Foundations, & Control Dictionary** (`src/ledgers/*.m`, `K01–K15`, `GREEN/AMBER/RED`) | **[GLOSSARY.md](GLOSSARY.md)** |
