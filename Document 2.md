# Document 2: Intergenerational Welfare Technical Documentation & Model Specification Guide (Master Index & Directory)
*A GPU-Accelerated Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial Overlapping Generations Framework (Multiphase Edition)*

**Author:** Michael Tiemann ([mdtiemann@gmail.com](mailto:mdtiemann@gmail.com))  
**Date:** November 2026 | **Code & Replication Repository:** [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)  
*Companion to [Document 1A](Document%201A.md) (Strategic Monograph), [Document 1B](Document%201B.md) (Strategy & Policy Answer Key), [Document 1C](Document%201C.md) (Executive Brief), and [Document 3](Document%203.md) (Leaving Our Silos, Lifting All Boats)*

---

## Notice of Technical Architecture Reorganization (`Document 2A`, `Document 2B`, & `Document 2T`)

To ensure every structural equation, operator derivation, and calibration annex renders cleanly within GitHub's per-file MathJax limits—and to separate the foundational sectoral models from the coupled general-equilibrium synthesis—**Document 2** has been organized into three companion technical volumes while **preserving the original Section 1–10 numbering across the suite**:

1. **[Document 2A: Part A — Micro-Foundations, Core Agent Problems, & Sectoral Operators (Sections 1–4)](Document%202A.md)**  
   *Covers the theoretical mechanisms operating within each individual economic lane: the Mixed-Horizon 8-PType GPU architecture, exact period-length scaling laws, infinite-horizon Guvenen et al. (2023) collateral-constrained firms, the finite-horizon household Bellman problem, two-stage Cunha–Heckman child skill formation, bidirectional Montessori / Tuakana–Teina mentoring, the endogenous pension–whānau coupling operator, and the 100% GPU-vectorized intergenerational and 4 × 5 Gumbel spatial migration matrices.*
2. **[Document 2B: Part B — Coupled General-Equilibrium Synthesis, Calibration, Transition Dynamics, & Supermodular Attribution (Sections 5–10)](Document%202B.md)**  
   *Covers what happens when all theoretical lanes are coupled together in general equilibrium: the 6-Gate (29-Node) Lifecycle Fiscal Sankey, the 2050 50/50 Sovereign Debt-Sinking Protocol, cooperative hyperbolic fertility bargaining, the NZ Superannuation eligibility-age U-curve (Ages 60–75), 10-tier wealth-and-income distributional incidence, two-stage SMM calibration, international validation benchmarks, ACC-style Actuarial Continuation Valuation, the constructive 11-layer supermodular synergy attribution, the 22-file VFI Toolkit codebase manifest, and the 60-reference Master Library.*
3. **[Document 2T: Companion Technical Tutorial — "Thick" vs. "Thin" Numbers in Quantitative Public Policy](Document%202T.md)** *(formerly Document 2B)*  
   *Provides the pedagogical walkthrough and formal Jensen's Inequality proofs showing why dimension-free state-contingent conditioning captures comonotonic tail risks (such as sandwich-generation care reversal, the Kaiako housing supply deflator, the 20% LVR deposit cliff, and actuarial pension regressivity) without expanding GPU grid dimensions.*

---

## Quick Section-by-Section Routing Table (Sections 1 to 10)

| Original Section | Section Title & Core MATLAB / VFI Operators | New Volume & Direct Link |
| :--- | :--- | :--- |
| **Section 1** | **Model Overview, Spatial Taxonomy, & Flexible Period Resolution** (`Configure_TimeGrid_Params.m`, 8-PType Mixed-Horizon GPU Architecture) | **[Read in Document 2A (Section 1)](Document%202A.md)** |
| **Section 2** | **Infinite-Horizon Entrepreneurial Firms & Capital Reallocation** (`ReturnFn_Firm.m`, Guvenen et al. 2023 "Use-It-Or-Lose-It" Wealth Tax Shift) | **[Read in Document 2A (Section 2)](Document%202A.md)** |
| **Section 3** | **Finite-Horizon Household Problem Across Lenses 1, 2, & 3** (`ReturnFn_SpatialHH_Compact4D.m`, `HumanCapital_Lifecycle_aprimeFn.m`, Two-Stage CES, *Tuakana–Teina* Mentoring, & Pension–*Whānau* Operator) | **[Read in Document 2A (Section 3)](Document%202A.md)** |
| **Section 4** | **100% GPU-Vectorized Intergenerational & 4 × 5 Spatial Migration Operators** (`Build_IntergenTransitionMatrix.m`, Stage-1 Skill $Q_h$, Stage-2 Estates $Q_a$, & Stage-3 Gumbel Emigration $\Pi_{\mathrm{mig}}$) | **[Read in Document 2A (Section 4)](Document%202A.md)** |
| **Section 5** | **Post-Hoc Lifecycle Operators: 6-Gate Fiscal Ledger, Statutory Rules, Fertility Bargaining, & 10-Tier Incidence** (`Plot_ChildFiscal_SSankey.m`, `FertilityBargaining_Module.m`, `Plot_WealthBracket_GiveAndGain.m`) | **[Read in Document 2B (Section 5)](Document%202B.md)** |
| **Section 6** | **Calibration, SMM Identification, & Cross-Country Validation Benchmarks** (`Calibrate_NZ_Moments.m`, 15 NZ Empirical Moments, `'Dunedin_22'` vs. `'MetroSqueeze_GUiNZ'`, Scotland & Deming-to-Tokyo Coda) | **[Read in Document 2B (Section 6)](Document%202B.md)** |
| **Section 7** | **Multiphase Transition Path, Actuarial Continuation Valuation, 11-Layer Supermodular Attribution, & Web SVG Architecture** (`TransPath_4Region_Master.m`, `Plot_ActuarialContinuationValuation.m`, `Plot_Counterfactuals_And_MirrorInvestments.m`, `exportSankeyToHTML.m`) | **[Read in Document 2B (Section 7)](Document%202B.md)** |
| **Section 8** | **Consolidated 22-File VFI Toolkit Codebase Manifest** (`Run_All_NZ_Intergen_Suite.m` and full script directory) | **[Read in Document 2B (Section 8)](Document%202B.md)** |
| **Section 9** | **Annex: Master Reference Library & Empirical Source of Truth** (Decile-Indexed References `[1]`–`[60]` across 6 Folders) | **[Read in Document 2B (Section 9)](Document%202B.md)** |
| **Section 10** | **Companion Technical Tutorial: "Thick" vs. "Thin" Numbers & Dimension-Free State-Contingent Conditioning** (Four Zero-Dimension-Cost Operators) | **[Read in Document 2T (Full Tutorial)](Document%202T.md)** |
