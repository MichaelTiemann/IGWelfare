# DOCUMENT 1B: Intergenerational Welfare — Strategy and Policy Answer Key
## Exact Cross-Reference Guide Linking Strategic Claims in Document 1A & Document 1C to VFI Toolkit Variables, Structural Equations, 6-Gate Fiscal Ledgers, and CSV/PNG/HTML Outputs (4-Region + Abroad Multiphase Edition)

**Author:** Michael Tiemann (`mdtiemann@gmail.com`)  
**Date:** November 2026 | **Code & Replication Repository:** [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)

**Disclaimer:** No people nor organizations mentioned herein have endorsed this work unless stated otherwise.  This is the work of the author, and all errors and omissions are his alone.

---

## 1. Purpose, Scope, & Suite Cross-Reference

This document is the quantitative and methodological companion ("Answer Key") to **[Document 1A](Document%201A.md)** (*Intergenerational Welfare, Capital Allocation, and Human Potential in New Zealand — A Multi-Audience Strategic Monograph*), **[Document 1C](Document%201C.md)** (*Flying, Not Floundering — Broad-Circulation Executive Brief & Suite Guide*), and **[Document 3](Document%203.md)** (*Leaving Our Silos, Lifting All Boats — Dynamic Complementarity & Coalition Architecture*), sitting directly alongside **[Document 2B](Document%202B.md)** (*Technical Documentation & Model Specification Guide*) and the mini-tutorial **[Document 2T: "Thick" vs. "Thin" Numbers in Quantitative Public Policy](Document%202T.md)**.

To make cross-referencing effortless for readers who want every technical, empirical, and parametric detail, the sections of this Answer Key follow the exact sequence of Document 1A:

* **Section 1:** *Introduction & Executive Matrix* (*SS0* Status Quo Baseline → *SS1* Foundation & Incubation → *SS2* 2050 Solvency & Dividend Harvest)
* **Section 2:** *Part I (Five Audience Briefings) & Part II (The Three Coupled Lifecycle Aspects & Social Cohesion)*
* **Section 3:** *Part III (The Accounting Pillar: 5-Stage Population & 6-Gate Fiscal Sankey Ledgers, Plus Extended Whānau & Super Age U-Curve Calibration)*
* **Section 4:** *Part IV (Headline Quantitative Findings, Tables 1–12, Retirement-Age U-Curve, & 10-Tier Survey-Anchored Distributional Incidence)*
* **Section 5:** *Part V (The Actuarial & Attribution Pillars: 2050 Debt-Sinking Protocol, Year 5 Audit, Mirror Investment Ledger, & 11-Layer Constructive Synergy Attribution)*
* **Section 6:** *Part VI (International Benchmarks — Table 6A Winners vs. Table 6B Cautionary Cases — & The Deming-to-Tokyo Coda)*
* **Section 7:** *Methodological Guardrails, Parameter Reference Tables, & Core Equations*

Every strategic claim, welfare percentage, fertility shift, migration flow, wealth-tier incidence figure, and fiscal ledger flow in Documents 1A, 1C, and 3 is mapped below to its exact **MATLAB script**, **VFI Toolkit parameter/grid index**, **structural equation**, and **output CSV/PNG/HTML file** in [`Output_NZ_4Region_Intergen/`](Output_NZ_4Region_Intergen/).

### 1.1 Cross-Reference for Document 1A (Introduction & Overview), Document 1C, and Document 3 ($`SS0 \to SS1 \to SS2`$)

* **The Treasury Status Quo Binary (185%–200% Net Crown Debt vs. Punitive Tax/Entitlement Cliffs — Doc 1A Intro & Doc 3 Part II):**
  * *Document 1A & Doc 3 Claim:* Under unchanged policy settings, the New Zealand Treasury's *Long-term Fiscal Statement (He Tirohanga Mokopuna 2025)* and 2026 background papers project net core Crown debt spiraling toward **185%–200% of GDP**, or require punitive tax hikes (working-age PAYE or GST rising from 22.0% toward 28.2%–30.7%) and/or entitlement cuts (raising the NZ Superannuation eligibility age toward 67–72), eroding household welfare by **-16.21% CE** (or **-21.69% CE** under an unfunded 3.0%-of-GDP defense commitment).
  * *Empirical & Literature Anchor:* New Zealand Treasury (*He Tirohanga Mokopuna: The Treasury's Combined Statement on the Long-term Fiscal Position*, Sept 2025); New Zealand Treasury *Analytical Note 26/01* (*Long-term Fiscal Model: 2025 Update*, Feb/March 2026, Table 2, downgrading long-run annual labour productivity growth from 1.0% to 0.9%/yr); and New Zealand Treasury *Working Paper 26/01* (March 2026, OLG general-equilibrium simulations of demographic ageing). Modeled in `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m` (`Table 21`).
* **Preventative vs. Reactive Infrastructure Stewardship (The 2026 Moa Point Lesson & The 2050 50/50 Protocol — Doc 1A Part I.3 & Part V.1):**
  * *Document 1A Claim:* Underfunding preventative social and physical infrastructure forces ballooning reactive remediation costs—mirrored physically in the February 2026 Moa Point wastewater failure—whereas locking 50% of post-breakeven fiscal surpluses (*SS1* Foundation & Incubation → *SS2* 2050 Solvency & Dividend Harvest) into the **Sovereign Debt Reduction Sinking Fund** ($`\Omega_{\mathrm{debt}}`$) and 50% into the **Public Infrastructure Reinvestment Pool** ($`\Omega_{\mathrm{infra}}`$, at multiplier $`\mu_{\mathrm{infra}} = 1.65`$) retires **NZD 17.50B–17.82B (*SS1*) to NZD 21.85B (*SS2*)** of sovereign debt per cohort wave and mobilizes **NZD 11.52B–12.16B (*SS1*) to NZD 14.90B (*SS2*)** per wave for core public infrastructure.
  * *Code & Empirical Anchor:* Computed in `Plot_ChildFiscal_SSankey.m` (`FiscalLedger.Protocol_2050_Summary`) and `Plot_ActuarialContinuationValuation.m` (`Table16_Actuarial_Continuation_Audit_Dunedin_22.csv`). Physical infrastructure benchmarked to the *Independent Crown Review into the Moa Point Wastewater Treatment Plant Failure* (Jaduram et al., Sept 2026) and New Zealand Infrastructure Commission / *Te Waihanga* (*Rautaki Hanganga o Aotearoa — New Zealand Infrastructure Strategy 2022–2052* and *National Infrastructure Plan*, 2025/2026).

* **1-to-1 Master Mapping Across the Five Methodological Pillars ($`SS0 \to SS1 \to SS2`$):**

| Methodological Pillar | Primary MATLAB Script(s) & Operators | *SS0* Status Quo Baseline | *SS1* Foundation & Incubation (Phase 1) | *SS2* Solvency & Dividend Harvest (Phase 2 — 2050) | Primary Output CSV / Figure |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Dual-Gate Capability** *(First 2000 Days + Montessori / Tuakana)* | `HumanCapital_Lifecycle_aprimeFn.m`, `Build_IntergenTransitionMatrix.m` ($`\varphi_1 = 0.35, \varphi_2 = -0.95, \Delta_{\mathrm{Tuakana}} = +0.11`$) | 22.0%–28.5% Struggling; 23.5% Thriving; 17.3% Mentored | **4.0%–4.5% Struggling; 57.3%–61.0% Thriving; 57.3% Mentored** | **1.5% Struggling; 65.0% Thriving; 65.0%+ Mentored** (-33.4% IGE) | `Table12A–12C`, `Table15`, `Fig_ChildFates_5Stage_*` |
| **2. Coupled Markets** *(Property-to-Enterprise Tax Shift)* | `ReturnFn_Firm.m`, `WelfareDecomposition_4Region.m` ($`\tau_a = 1.5\%, \tau_b = 25\% \to 18\%, E = 0.065 \to 0.080`$) | +0.0% Wage; 28.0% Young Own; 10.93% Nat. Emig ($`S_t = 100`$) | **+3.2% to +5.5% Wage; 38.2% Own; 8.56% Emig** ($`S_t = 112.0\text{--}118.4`$) | **+6.8% to +9.6% Wage; 41.2%–41.5% Own; 7.60% Emig** ($`S_t = 126.0`$) | `Table1`, `Table3`, `Fig2_Kiyotaki_*`, `Fig3_BrainDrain_*` |
| **3. Sankey Fiscal Ledger** *(18-Node Pop & 29-Node Fiscal)* | `Plot_ChildFates_SSankey.m`, `Plot_ChildFiscal_SSankey.m` ( Ω fiscal ) | 14.0%–14.6% $z_l$ Rent-Seekers vs. 6.8%–7.1% $z_h$ Builders; +2.1 to +3.2 kNZD/yr Base Balance (NZD 17.7B/yr Exits) | *39.9% *z*<sub>h</sub> Builders (7.7% *z*<sub>l</sub>); +27.0 to +28.0 kNZD/yr Net Surplus (+13.5k–14.0k Debt Sink + Reinvest)* | *52.0% $z_h$ Builders (3.6% $z_l$); +29.9 to +31.2 kNZD/yr Net Surplus (+15.0k–15.6k Debt Sink + Reinvest)* | Table14 , Table15 , Fig_ChildFiscal_6Gate_* |
| **4. Actuarial Valuation** *(ACC-Style Continuation Value)* | `Plot_ActuarialContinuationValuation.m` ($`\mathcal{V}_{k,t_0}^{(L)}, r_{\mathrm{disc}} = 0.02`$) | Cash breakeven takes **18.8 yrs** (46.4 yrs direct savings) | **Yr 5: NZD 35.25B Fiscal (3.84x) / NZD 85.40B GDP** (1.16x cost avoidance alone) | **60-Yr Cash: NZD 702.3B Fiscal / NZD 1,510.7B GDP (6.86x)** | `Table16_Actuarial_*`, `Fig_Actuarial_*` |
| **5. The *SS2* Dividend Harvest** *(2050 50/50 Debt & Infra + Super U-Curve)* | `FertilityBargaining_Module.m`, `Plot_Counterfactuals_And_MirrorInvestments.m` ($`\Omega_{\mathrm{debt}}, \Omega_{\mathrm{infra}}`$) | 1.66 TFR; **23.61%–28.20% PAYE req.**; 22.0% actual PAYE | 1.85–1.93 TFR; **20.84% PAYE req.** (at 22.0% actual → Sinks Debt) | **Super Age 64 (+24.70% CE Peak, 18.25% PAYE) or Age 65 (17.97% PAYE Min)**; NZD 21.85B Debt + 14.90B Infra/Wave | `Table7`, `Table8`, `Table8B`, `Table19`, `Table20`, `FigFert_*` |

```text
+-----------------------------------------------------------------------------------+
|                                                                                   |
|                       [ THIS SPACE INTENTIONALLY LEFT BLANK ]                     |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

---

## 2. Part I & Part II Cross-Reference: The Five Audiences & Three Coupled Lifecycle Aspects

### 2.1 Audience Briefings Cross-Reference (Part I: Sections 1 to 5 & Calls to Action)

1. **Audience 1 — Philanthropists, Iwi Trusts, & Community Foundations (Doc 1A Part I.1):**
   * *Dunedin Study Concentration Benchmark:* The most disadvantaged **22.0%** of a birth cohort (identifiable at age 3; `h1`–`h2` on our 7-point human capital grid) drives **57% to 81%** of adult hospital nights, long-term welfare receipt, and criminal convictions (Caspi et al., 2016, *Nature Human Behaviour* 1, 0005), alongside Oranga Tamariki state care placements costing **~NZD 180,000 per care-year** (or **NZD 37.1k–54.7k/yr** annualised across early-exit cohorts and **NZD 181k** lifetime Crown abuse-in-care liability).
   * *Two Catalytic Gates:* Gate 1 (**First 2000 Days**, ages 0–5, modeled on Barnardos' *Te Korowai Mokopuna*, *Whānau Ora* navigators, *Kōhanga Reo*, and Pasifika *A'oga Amata*) and Gate 2 (**Early-Adolescent Transition**, ages 12–14 / Years 8–10, modeled on indigenous *Tuakana–Teina* leadership, the **Graeme Dingle Foundation's *Stars / Te Kāhui Whetū* and *Project K***, Pasifika *Tuakana* academies, and Montessori *Erdkinder* adolescent communities).

2. **Audience 2 — Venture Capitalists, Founders, & Growth Investors (Doc 1A Part I.2):**
   * *Productive Capital Reallocation:* Replaces distortionary capital-income taxation ($`\tau_k`$) with a **1.5% book-value land/wealth levy** (*τ_a* = 0.015 (1.5%)) on dormant equity and a **25% peak estate levy** ($`\tau_b = 25\%`$, stepping down to `0.18` in `SS2`) on the **NZD 1.6T intergenerational property transfer wave** (Guvenen et al., 2023, *QJE* 138(2)).
   * *Talent Retention:* Roughly **19.5%** of educated young adults in metropolitan hubs (`19.29%` in Auckland, `23.41%` in Large regional cities) emigrate at ages 20–35 in `SS0`. Recycling estate revenues into a universal **Youth Capital Grant** at age 20 ($`E = 0.065`$ in `SS1`, $`0.080`$ in `SS2`) and a **-3.75 to -4.03 pp working-age PAYE cut** (`22.0% -> 17.97%–18.25%`) in `SS2` expands the thriving domestic talent pool ($`h_6`$–$`h_7`$) from **23.2%–23.5% to 57.3%–61.0%+ in `SS1` and 65.0% in `SS2`**.
   * *Occupational Talent Allocation & The Rent-Seeking Extraction Wedge (Murphy, Shleifer, & Vishny, 1991, *QJE* 106(2): 503–530):* **Document 1A & 1C Claim:** Pairing the Guvenen et al. (2023) property-to-enterprise tax rebalance (*τ_a* = 0.015 (1.5%), $`\tau_b = 25\% \rightarrow 18\%`$) with the universal Youth Capital Grant ($`E = 0.065 \rightarrow 0.080`$) and front-loaded human capability ($`G_{\text{ECE},1}, G_{\text{ECE},2}`$) reverses both external youth emigration (`Nat_Emig_Abroad_Pct`: $`10.93\% \rightarrow 7.60\%`$) and internal talent misallocation into unproductive property speculation ($`z_\ell`$).
   * **Theoretical & Empirical Mapping:** In Murphy, Shleifer, and Vishny's (1991, Sec. I–III) Lucas-style superstar model, productive entrepreneurs with ability $`A > A^*`$ earn $`\pi_{\text{ent}}(A) = (1 - T)[s \cdot A \cdot F(H) - wH]`$, while rent-seekers extract a share $`T \cdot Y`$ of existing wealth and output via $`R_{\text{rent}}(A) = \frac{A \cdot G(H) \cdot T \cdot Y}{\int A G(H) f(A) dA} - wH`$. In an economy with a large existing wealth stock (NZD 1.6T residential land) and slow baseline productivity growth ($`0.9\%/\text{yr}`$ in Treasury *AN 26/01*), $`R_{\text{rent}}(A)`$ dominates $`\pi_{\text{ent}}(A)`$ at the top of the ability distribution *a*, drawing potential innovators into zero-sum wealth redistribution and permanently lowering endogenous TFP growth $`g_s = s(t)/s(t-1) - 1`$. Lowering the effective rent-seeking wedge $T$ on productive firms (via corporate tax relief, $`-60\text{ bps}`$ credit crowding-in, and the *τ_a* = 0.015 (1.5%) land/wealth levy on $`z_\ell`$) shifts the marginal and top-tail ability thresholds back into productive entrepreneurship—Validated empirically by MSV (1991, Tables III–VI, $N=55$), where engineering share raises real per-capita growth ($`\beta_{\text{eng}} = +0.054\text{ direct}, +0.125\text{ total}`$) and strongly co-moves with primary human-capital investment ($`+1.02, \text{SE } 0.408`$) and physical investment ($`+0.432, \text{SE } 0.119`$), whereas rent-seeking law concentration directly depresses growth ($`\beta_{\text{law}} = -0.078, \text{SE } 0.040`$).

3. **Audience 3 — Policy-Makers, Cabinet Ministers, & Treasury Officials (Doc 1A Part I.3):**
   * *Closing the Micro-to-Macro Modelling Gap (Treasury OIA Response 20250878, Feb 2026):* In *OIA 20250878* (pp. 6–11), the New Zealand Treasury documented that its macro models (`FSM`, `LTFM`, and the 2025 `OLG` model) operate at the aggregate level and *"contain no data at the micro level, including at the cohort level,"* whereas frontline agencies evaluate individual budget bids in micro silos (`CBAx`, `TAWA`, and Stats NZ `IDI`). Our coupled `8-PType` OLG + 6-Gate Lifecycle Sankey engine welds these three institutional layers together:
     * **Layer 1 (Frontline Agencies & Social Investment Agency):** Track verified IDI cohort transitions out of $`h_1`$–$`h_2`$ at Gate 1 (ages 0–5) and Gate 2 (ages 12–14).
     * **Layer 2 (Treasury Vote Analysts, `CBAx` Teams, & ACC Actuaries):** Apply **Actuarial Continuation Valuation** ($`\mathcal{V}_{k,t_0}^{(L)}`$, following ACC's *Financial Condition Report 2025*, p. 17, and Treasury Circular 2024/15 dual discount rates of **2.0% real SRTP** and **8.0% real SOC** net of a 30% attribution haircut) to book 25-year avoided remediation liabilities at Year 5 (**NZD 10.68B** direct cost avoidance = **1.16x outlay**; **NZD 35.25B** total fiscal return = **3.84x outlay**).
     * **Layer 3 (Treasury Macro `LTFM`/`OLG` Teams, *Te Waihanga*, & Cabinet):** Feed verified cohort capability and fiscal surpluses into the **2050 50/50 Sovereign Debt-Sinking and Infrastructure Protocol**.

4. **Audience 4 — Academic & Policy Economists: Synthesizing Five Decades of Longitudinal Evidence and Operator Theory (Doc 1A Part I.4):**
   * *Empirical & Theoretical Convergence:* Over the past five decades, developmental scientists and quantitative macroeconomists have built all of the required empirical and mathematical machinery in separate literatures: New Zealand's 50-year *Dunedin Study* and *Growing Up in New Zealand* longitudinal cohorts, Cunha and Heckman's multi-stage skill operators, Guvenen et al.'s heterogeneous-agent wealth-tax proofs, spatial housing and migration sorting operators, and twelve international natural experiments. Assembling and calibrating these established tools onto a single GPU ledger allows New Zealand to replace reactive cash-flow austerity with a verified, self-financing generational transition inside a single 3-to-5-year parliamentary cycle.
   * *Four Methodological Pillars in VFI Toolkit:* (I) Mixed Finite/Infinite-Horizon 8-PType GPU synthesis (*J* = 27 three-year periods or *J* = 16 five-year periods for households alongside $`N_j = \infty`$ collateral-constrained firms); (II) Multi-stage CES + *Tuakana–Teina* + Ben-Porath + Stone-Geary laws of motion; (III) Dimension-free spatial housing bubbles (Hirano & Toda, 2025; Kiyotaki et al., 2024) + $`4 \times 5`$ Gumbel migration sorting (Labrousse & Perdereau, 2025); and (IV) Tractable dynastic transition closure $`\mathbf{T}_{\mathrm{IG}}: \mathbf{Q}_h \times \mathbf{Q}_a \times \Pi_{\mathrm{mig}}`$ paired with ACC-style actuarial valuation $`\mathcal{V}_{k,t_0}^{(L)}`$.

[ This space left intentionally blank ]

---

5\. **Audience 5 — Creatives, Storytellers, & Artists: Building the Future as a Creative Act (Doc 1A Part I.5):**
   * *Parametric & Economic Channels Empowering the Creative Sector:*
     * **1. Narrative & Civic Credibility ($\lambda_{\text{cred}}(t)$ in `TransPath_4Region_Master.m`):** Translating the 18 nodes of the Population Sankey and 29 nodes of the Fiscal Sankey into living *pūrākau* accelerates public and youth belief convergence ($\lambda_{\text{cred}}(t) \to 1$), pulling forward brain-drain reversal (`Regime B/C`).
     * **2. Creative Agency at Gate 2 ($`\Delta_{\mathrm{Tuakana}} = +0.11 \to +0.14`$ in `Build_IntergenTransitionMatrix.m`):** Music, storytelling, *kapa haka*, design, and maker micro-economies are the active non-cognitive inputs inside *Montessori / Tuakana–Teina* and *Stars / Project K* adolescent communities at ages 12–14.
     * **3. The Creative Endowment & Urban Rent Relief ($`E = 0.065 \to 0.080`$, $`Q_{\mathrm{Akl}} -7.5\% \to -10.5\%`$, $`\tau_l: 22.0\% \to 18.25\%`$):** Cooling metropolitan rental user costs ($`rr_k`$) in Auckland and Large regional cities (Wellington, Christchurch, Hamilton, Tauranga, Dunedin) while providing every 20-year-old with the universal **Youth Capital Grant** (*E*) gives young artists, game developers, filmmakers, and cultural founders the economic runway to stay and build IP in Aotearoa rather than emigrating to Melbourne, Sydney, London, or Los Angeles.

---

### 2.2 Aspect 1: Early Childhood & The Adolescent Mentoring Gate (`Ages 0–19`)

Our overlapping generation (OLG) model depends critically on the development potential of human capital, thus we must pay particular attention to the most sensitive periods of that development potential: childhood and adolescence.  By making the factors of this development explicit and by calibrating our model to domestic and international datasets, it becomes clear just how significant these factors can be for the overall potential of the economy as a whole.

#### 2.2.1 Gate 1 (Age 0) and Gate 2 (Ages 0–5): Differentiating Acute Hardship from the Residual AHC Squeeze

Standard single-threshold poverty metrics obscure the structural mechanisms driving early childhood developmental risk in Aotearoa New Zealand. When the birth entry gate ($J = 1$) conflates acute material deprivation with broader housing-induced liquidity stress into a single vulnerability node (~24–26% of the birth cohort), it invites two opposing critiques: social policy analysts note that official severe material hardship rates are closer to 8–10% at birth, while longitudinal developmental researchers observe that a 10% threshold fails to account for the **22.0% high-burden developmental cohort** documented in the Dunedin Multidisciplinary Health and Development Study (Caspi et al., 2016).

To resolve this tension with institutional precision, the 18-node Sankey architecture partitions childhood entry ($J = 1$) into three distinct constituent states:

1. **Node 1: Severe Material Hardship (DEP-17 9+ / High-Needs Deprivation, ~9.5–10.5% in SS0):** Anchored to Stats NZ and Ministry of Social Development (MSD) severe material hardship thresholds (enforced lack of 9 or more of 17 basic essentials) and Treasury Integrated Data Infrastructure (IDI) multiple-risk birth flags. These households reside at the acute liquid asset floor ($a < 0.05 Q_{\text{reg}}$) alongside bottom labor productivity states ($z \le 2$). Without proactive, high-intensity wraparound intervention, constituents in Node 1 face near-certain entry into the **Unmitigated Corner ($ic = 0$, Node 4)** during the First 2000 Days ($J = 2..3$).
2. **Node 2: Residual After-Housing-Costs (AHC) Squeeze & Paper Support (~13.5–14.5% in SS0):** Anchored to MSD Household Incomes Report AHC-50 residual income metrics and Welfare Expert Advisory Group (*Whakamana Tāngata*) findings on transfer inadequacy. Constituents in Node 2 sit above the emergency destitution floor ($0.05 Q_{\text{reg}} \le a < 0.16 Q_{\text{reg}}$) and qualify *on paper* for statutory transfers (Working for Families, Best Start, Paid Parental Leave, and the Accommodation Supplement). However, three structural frictions prevent these paper entitlements from securing a healthy First 2000 Days trajectory:
   * **Metropolitan Housing Capture:** In high-rent regions (`Auckland` $Q = 3.10$, `Large` $Q = 2.05$), housing costs breach Accommodation Supplement caps, absorbing household cash flow.
   * **Abatement Cliffs and Administrative Friction:** High effective marginal tax rates (EMTRs) on secondary earners and complex application gates penalize variable working hours.
   * **Time Poverty and Uncounted Alloparental Labor ($K_{\text{whānau}}$):** As established in Marilyn Waring's foundational critique of national income accounting (*Counting for Nothing*, 1988), formal fiscal ledgers treat unpaid household and extended family care as having zero economic value. In our spatial lifecycle framework, whether an infant in **Node 2** falls into the **Unmitigated Corner (Node 4)** or reaches **Public ECE + Moderate Investment (Node 5)** depends critically on regional alloparental network capacity $K_{\text{whānau}}(k)$. In `Rural` ($K_{\text{whānau}} = 0.42$) and `Small` provincial ($0.38$) regions, lower housing costs allow kaumātua and extended whānau to reside in close proximity, providing unpaid care that bridges statutory transfer gaps. Conversely, in metropolitan `Auckland` ($0.28$) and `Large` cities ($0.32$), high housing multipliers ($Q_{\text{reg}} / Q_{\text{reg,base}}$) price extended family out of commuting range, isolating nuclear households. Furthermore, fiscal policies that raise the public pension eligibility age ($J_r > 65$) reduce elder time availability at a rate of $\exp(-0.09 \max(0, \text{Age}_{\text{super}} - 65))$, stripping unpaid care from Node 2 families and shifting long-term costs onto state hospitalisation, benefit, and justice ledgers at Gate 5.
3. **Node 3: Secure Parental Asset Buffer (~75.0–77.0% in SS0 $\to$ >90.0% in SS1):** Households possessing sufficient liquid equity and after-housing-cost disposable income to absorb birth income transitions and sustain baseline First 2000 Days investment without emergency assistance.

---

#### 2.2.2 Gate 3 (Ages 12–14): Adolescent Psychosocial & Relational Morbidity

#### A. Structural Rationale: Beyond Household Material Deprivation
In a conventional lifecycle human capital model, adolescent disengagement at the ages 12–14 gate ($J = 5$) is modeled primarily as a transmission of parental unemployment and material deprivation ($z_1$). However, contemporary longitudinal evidence in Aotearoa New Zealand demonstrates that household economic hardship alone leaves a substantial unexplained residual in early secondary school detachment, chronic truancy, and non-cognitive skill depreciation.

Since 2012, four interconnected psychosocial hazards—peer victimization and cyberbullying, algorithmic social media compulsion, sexual violence victimization, and clinical-grade depressive and anxiety morbidity—have operated as cross-income human capital shocks. Within a Cunha-Heckman dynamic complementarity framework, ages 12–14 represent a sensitive neurodevelopmental window for prefrontal cortex pruning and executive function consolidation. Sustained relational threat and attentional fragmentation during this window induce chronic cortisol elevation and sleep architecture disruption, degrading the self-regulatory and cognitive returns on prior early-childhood investments. When these psychosocial shocks intersect with household unemployment stress, they compound multiplicatively, locking vulnerable constituents into attainment-deficit trajectories (**Node 7: Compounded Household & Psychosocial Stress**) and generating severe downstream fiscal liabilities.

#### B. Domestic Baselines: Aotearoa New Zealand Cohort Evidence
To calibrate the baseline psychosocial hazard rate ($\lambda_{\text{psy}}$) at the ages 12–14 gate, the model draws on four primary domestic statistical series:

* **Longitudinal Depressive and Anxiety Trajectories ([Growing Up in New Zealand](https://www.growingup.co.nz/)):** Data from the *Now We Are Twelve* wave establishes that entering early adolescence is marked by a broad-based deterioration in mental health. Between ages 8 and 12, **52.4%** of the cohort experienced an escalation in depressive symptoms, while **37.2%** experienced rising anxiety scores. Longitudinal regressions confirm two primary drivers at age 12: prior frequent bullying victimization at age 8 and the erosion of communicative parent-child and peer relationships. While depressive symptoms are exacerbated by area-level deprivation, baseline anxiety elevations at age 12 occur across all socioeconomic deciles, confirming that relational and digital stressors operate across the broader youth population.
* **Secular Surge in Adolescent Clinical Morbidity ([Youth19 Rangatahi Smart Survey](https://www.youth19.ac.nz/)):** Across the Youth2000 longitudinal survey series, the prevalence of clinically significant depressive symptoms (measured via RADS-SF) among secondary school constituents nearly doubled in a single decade, rising from **13%** in 2012 to **23%** in 2019 overall—and surging from **14%** to **28%** among rangatahi Māori and **14%** to **25%** among Pacific youth. Over the same window, 12-month suicide attempt rates among Māori and Pacific adolescents rose to **13%** and **12%** respectively, demonstrating an acute escalation in severe adolescent distress coinciding with the ubiquity of smartphone-mediated social environments.
* **Peer Victimization and Bullying Incidence ([Mental Health Foundation NZ / OECD PISA](https://mentalhealth.org.nz/)):** New Zealand consistently records one of the highest rates of school bullying in the OECD. In comparative PISA assessments, **32%** of New Zealand students reported being bullied at least a few times a month (compared to the OECD average of **23%**), with incidence peaking in the intermediate and early secondary transition years (ages 12–14). Within the *Growing Up in New Zealand* cohort, **35%** of children reported bullying victimization in the preceding year, with **24%** experiencing weekly verbal degradation or social exclusion.
* **Sexual Harm and Long-Term Fiscal Liability ([ACC Sensitive Claims](https://www.acc.co.nz/) & [Social Investment Agency](https://sia.govt.nz/)):** Unresolved adolescent sexual harm and severe relational trauma translate directly into long-term Crown fiscal burdens via three documented channels:
  1. *Direct Rehabilitation and Compensation Costs:* New claims lodged with ACC's Integrated Services for Sensitive Claims (ISSC) increased by **193%** between 2013/14 and 2020/21 (rising from 4,328 to 12,702 annual new claims, with active claims exceeding 38,000). When sexual or physical trauma occurs during childhood or adolescence and impairs adult earning capacity at labor market entry, claimants qualify for Loss of Potential Earnings (LOPE) entitlements set at **80%** of the adult minimum wage—representing both a direct Crown liability and a permanent reduction in lifetime tax receipts (**Node 15: Exit 3 Lower Lifetime Income** and **Node 16: Exit 4 Benefit & Justice Burden**).
  2. *Educational Detachment and NEET Entry:* Frequent victimization and untreated adolescent trauma are primary precursors to chronic school avoidance, NCEA non-completion, and entry into NEET (Not in Education, Employment, or Training) status at ages 16–24 (**Node 10: Struggling Tier $h_1\text{–}h_2$**).
  3. *Adult Welfare Inflow:* Actuarial evaluations by the Social Investment Agency confirm that early adolescent mental health and behavioral disengagement are leading predictors of inflow onto Youth Payment, Jobseeker Support (Health and Disability), and long-term Supported Living Payments (SLP).

#### C. International and Domestic Policy Analogs
A central question for model validation is whether the **SS1 reform package**—specifically the expansion of high-agency Montessori *Erdkinder* / *Tuakana-Teina* mentoring (**Node 9**), family connection buffers ($K_{\text{whānau}}$ and parental time), and critical thinking / digital metacognition—can credibly reduce the stress-trap persistence probability from **82%** to **38%**. Three empirical analogs demonstrate that restructuring the relational and pedagogical architecture of early adolescence yields reductions of this magnitude:

1. **The Icelandic Prevention Model ([Planet Youth](https://planetyouth.org/)):** In the late 1990s, Iceland exhibited the highest rates of adolescent substance abuse, intoxication, and behavioral disengagement in Europe. Rather than relying on individualized clinical therapy or didactic risk education, the Icelandic Prevention Model treated adolescent pathology as an environmental and relational deficit, restructuring the ages 12–16 developmental ecology around four institutional domains: (i) structured quantity and quality of parent-adolescent time; (ii) shifting peer status hierarchies away from unsupervised aggregation; (iii) embedding every adolescent in a relational school environment; and (iv) universalizing access to mentored community cohorts. Within twenty years, 30-day adolescent alcohol intoxication fell from **42%** to **5%**, daily smoking fell from **23%** to **2%**, and cannabis use dropped from **17%** to **5%**, confirming that population-level adolescent crises are highly elastic with respect to family connection and mentored peer architecture.
2. **Peer-Norm Restructuring in Aotearoa ([KiVa New Zealand Evaluations](https://www.kivaprogram.net/new-zealand/)):** Traditional disciplinary responses to bullying and cyberbullying fail because they treat victimization as a dyadic conflict between perpetrator and victim while leaving the surrounding peer status hierarchy intact. Evaluated across New Zealand schools by researchers at Victoria University of Wellington, the *KiVa* framework targets the bystander peer ecology—training students in critical social awareness, empathy, and collective peer intervention. Within the SS1 framework, the *Tuakana-Teina* (cross-age vertical mentoring) component institutionalizes this mechanism: replacing horizontal age-segregated status competition with vertical mentoring responsibility gives older constituents an institutional mandate to protect and guide younger peers.
3. **Cognitive Inoculation and Relational Replacement in the Post-Smartphone Era:** Following New Zealand's 2024 statutory restrictions on student cellphone use during school hours and parallel OECD shifts, comparative evaluations highlight a critical distinction between *hardware restriction* and *relational replacement*. Removing mobile devices during instructional hours reduces acute classroom distraction, but leaves after-hours cyberbullying and algorithmic compulsion intact unless paired with: (i) explicit training in metacognitive critical thinking to recognize algorithmic attention-capture and synthetic social comparison; and (ii) embodied agency (*Erdkinder* pedagogy) that satisfies the adolescent developmental drive for autonomy, competence, and social contribution.

#### D. Mapping Mechanisms to the Gate 3 ($J = 5$) Transition Matrix
To preserve state-space parsimony in the 18-node Sankey diagram while capturing these dynamics accurately, the ages 12–14 transition mechanics distinguish three structural channels:

| Mechanism Channel | Baseline (`SS0`) Vulnerability Dynamics | Reform (`SS1` / `SS2`) Mitigation Pathway |
| :--- | :--- | :--- |
| **1. Incidence Channel ($\lambda_{\text{psy}}$)** | High baseline exposure to peer victimization (**32–35%**), algorithmic compulsion, and depressive escalation (**52.4%** worsening from age 8 to 12) erodes executive function across all income deciles, pulling even stable-income adolescents into **Node 7**. | Critical thinking curricula, digital metacognition, and *Tuakana-Teina* vertical peer norms directly reduce the incidence of peer victimization and compulsive digital detachment. |
| **2. Buffering / Insulation Channel** | When psychosocial harm or sexual trauma occurs inside a household experiencing unemployment or residual AHC stress, lack of relational support results in an **82%** lock-in to the disengagement trap (**Node 7**). | Expanding *Erdkinder* / *Tuakana* mentoring (**Node 9**) to **57%** cohort coverage (and **28%** conditional access for stressed households) alongside strengthened family connection buffers ($K_{\text{whānau}}$) insulates victims, reducing stress-trap persistence to **38%**. |
| **3. Clinical Floor (The 38% Residual)** | Unmitigated compounding of material and severe psychosocial trauma drives acute CAMHS queues, ACC LOPE claims, and NEET inflow (**Node 10** $\to$ **Nodes 13–16**). | The model explicitly retains a **38%** conditional persistence residual under Phase 1 reform, acknowledging that acute clinical trauma and severe psychiatric morbidity require specialized clinical intervention (ACC ISSC and CAMHS) beyond school and family buffers. |

In consideration of the above, we construct our adolescent gate as follows:

| Aotearoa Delivery Pathway at Gate 3 ($`J = 5`$, Ages 12–14 / Years 8–10) | Representative New Zealand Programs & Institutions | Status Quo (`SS0`) | Phase 1 (`SS1`) | Phase 2 (`SS2`) | Primary Mechanism in `Build_IntergenTransitionMatrix.m` |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **1. Structured School Peer-Mentoring Charities** | **Graeme Dingle Foundation** (*Stars / Te Kāhui Whetū* Year 12–13 *tuakana* mentoring Year 9 *teina*; *Project K* wilderness & community mentoring), *I Have a Dream NZ* | 10.0% | 28.5% | 32.0% | Insulates at-risk Year 8–10 students against `z1` family unemployment stress; cuts truancy and Exit 1/Exit 4 entry |
| **2. *Kura Kaupapa Māori*, *Kura-ā-Iwi*, & Pasifika *Tuakana* Academies** | *Te Rūnanga Nui o Ngā Kura Kaupapa Māori*, *Ngā Kura ā Iwi o Aotearoa*, bilingual *whānau* classes, Pasifika *Tuakana–Teina* & Polyfest leadership hubs | 4.7% | 16.8% | 19.5% | Embeds *Tuakana–Teina*, *Ako*, and *Whanaungatanga* across vertical age cohorts; lifts NCEA Level 3 retention |
| **3. High-Agency Vertical-*Whānau* State Secondary/Intermediate Schools** | *Ao Tawhiti Unlimited Discovery* (Christchurch), *Hobsonville Point Secondary School*, *Tai Wānanga*, project-based state *whānau* houses | 1.8% | 8.5% | 9.5% | Replaces rigid age-segregated tracking with multi-age advisory *whānau* and creative community enterprise projects |
| **4. State & State-Integrated Montessori Adolescent Units (*Erdkinder*)** | *Wāora Montessori School* (Lower Hutt), *Berhampore*, *Royal Oak Intermediate*, Montessori Aotearoa adolescent units | 0.8% | 3.5% | 4.0% | Direct Montessori *Erdkinder* micro-economy and cross-age mentoring |
| **Combined Montessori / *Tuakana–Teina* Gate 3 Participation** | **All Four Pathways Combined (`Node 9` in Fates / `Node 12` in Fiscal)** | **17.3%** | **57.3%** | **65.0%** | **Two-way skill boost ($`\Delta \ln h = +0.11`$ to $`+0.14`$) + buffers family job-loss shock** |

Putting this all together, we construct Gates 1-3 with the following constraints and parameters:

* **Intergenerational Borrowing Constraint & Private Corner Solution (*i_c* = 0):**
  * *Document 1A Claim (Part II, Aspect 1):* Cash-poor and rent-squeezed *whānau* in metropolitan centers hit a binding financial corner where discretionary private early-childhood enrichment collapses to zero.
  * *Code & Math Mapping:* In `ReturnFn_SpatialHH.m`, parents during active child-rearing windows $`j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}`$ cannot borrow against the child's future adult human capital $`h'_1`$ ($`a' \ge 0`$ on `a_grid_assets`). When regional house prices *Q_k* (`Params.Q_reg`: Rural = `1.05`, Small = `1.40`, Large = `2.05`, Auckland = `3.10`) inflate user costs $`rr_k, rh_k`$ or mandatory transport subsistence $`\bar{e}_k`$ (`Params.ebar_energy`: Rural = `0.048`, Small = `0.036`, Large = `0.022`, Auckland = `0.016`) binds, optimal private enrichment investment $`d_3 = i_c \in [0, 0.50]`$ hits `d_grid_ic(1) = 0` alongside asset/income hardship (**24.00%** of the national cohort in Baseline `SS0`, falling to **5.67%** in `SS1` and **2.06%** in `SS2`).

* **Gate 1 — Two-Stage CES Skill Technology ($`\theta_c`$ Experience Asset, Ages 0–5 vs. Ages 6–17):**
  * *Code & Math Mapping:* Implemented in `ChildCES_aprimeFn.m` and `HumanCapital_Lifecycle_aprimeFn.m` with `vfoptions.experienceasset = 1` over the 9-point grid `a_grid_thetac`:

* **Gate 2 (Sankey Gate 3, $`J = 5`$, Ages 12–14) — Cultural & Pedagogical Synthesis: Montessori *Erdkinder* Meets *Tuakana–Teina* and the Graeme Dingle Foundation:**
  * *Why Early-Childhood Gains Can Erode at Ages 12–14:* When a parent experiences an unbuffered unemployment or severe low-income shock (`is_unemp_stress = (iz == 1) || (n_z1 >= 5 && iz == 2 && is_hardship)`), adolescent skill formation suffers a structural erosion penalty $`\Delta \ln(h_{\mathrm{mean}}) = -0.22`$.
  * *Indigenous Te Ao Māori & Pasifika Foundations Alongside Montessori's Erdkinder:*
    * ***Tuakana–Teina* (Older-to-Younger Kinship Responsibility):** An older or more skilled *tuakana* guides and protects a younger *teina*, buffering the *teina* against family or school alienation while building executive function, empathy, and *mana* in the *tuakana*.
    * ***Ako* (Reciprocal Two-Way Learning):** Teacher and learner roles flow bidirectionally, generating the **two-way skill dividend** in `Build_IntergenTransitionMatrix.m` ($`\Delta \ln(h_{\mathrm{mean}}) = +0.05`$ in `SS0`, rising to $`+0.11`$ in `SS1` and $`+0.14`$ in `SS2`, while amplifying effective Stage-1 wraparound productivity $`G_{\mathrm{ECE,eff}} = 1.15 \times G_{\mathrm{ECE}}`$).
    * ***Manaakitanga*, *Whanaungatanga*, & *Rangatiratanga*:** Uplifting the *mana* of peers through care (*manaakitanga*), school kinship belonging (*whanaungatanga*), and youth creative agency (*rangatiratanga*).
  * *Empirical Breakdown of the 17.3% Baseline (`SS0`) Scaling to 57.3% (`SS1`) and 65.0% (`SS2`):*

| CES Parameter / Policy Lever | Stage 1: First 2000 Days ($`j \in \mathcal{J}_{c,1}`$, Ages 0–5) | Stage 2: School & Adolescent Years ($`j \in \mathcal{J}_{c,2}`$, Ages 6–17) | Economic & Empirical Interpretation |
| :--- | :---: | :---: | :--- |
| **CES Curvature & Elasticity ($`\varphi_s, \sigma_s`$)** | $`\varphi_1 = +0.35`$ ($`\sigma_1 = \frac{1}{1-\varphi_1} = 1.54 > 1`$) | $`\varphi_2 = -0.95`$ ($`\sigma_2 = \frac{1}{1-\varphi_2} = 0.51 < 1`$) | High early substitutability vs. strong school-age dynamic complementarity (Cunha et al., 2010) |
| **Share Weights ($`\gamma_{s,\mathrm{self}}, \gamma_{s,\mathrm{inv}}, \gamma_{s,\mathrm{par}}`$)** | `0.53` / `0.24` / `0.23` | `0.87` / `0.07` / `0.06` | Self-productivity rises from `0.53` to `0.87` in Stage 2; early investment raises Stage-2 returns |
| **Public Wraparound Lever ($`G_{\mathrm{ECE},s}`$)** | `0.045` (`SS0`) → `0.110` (`SS1`) → `0.130` (`SS2`) | `0.065` (`SS0`) → `0.085` (`SS1`) → `0.105` (`SS2`) | Universal First-2000-Days wraparound (Gate 1) + Adolescent mentoring expansion (Gate 2) |
| **Stone-Geary Luxury Floor ($`\bar{g}_{\mathrm{ECE}}`$)** | `Params.gbar_ece = 0.020` | `Params.gbar_ece = 0.020` | Ferriere et al. (2025) non-homothetic floor; in-kind public provision bypasses cash corner |

---

### 2.3 Aspect 2 & Aspect 3: Spatial Sorting, Enterprise Reallocation, & Historical Crisis Comparison (`Ages 20–99`)

* **8-PType Regional Household & Firm Architecture (A3 Two-Column Reference Comparison):**
  * Initialized in `NZ_4Region_Master.m` via `Params.PTypeWeights(1:4)` (Stats NZ June 2025 Subnational Population Estimates) and `Params.PTypeWeights(5:8)` (Stats NZ Feb 2025 Business Demography):

| Regional Tier (*k*) | Household PType (`Names_i(1:4)`) | Base HH Pop Share | House Price *Q_k* (`SS0` → `SS1` → `SS2`) | Transport Floor $`\bar{e}_k`$ |Geo Transfer *T_k* (`SS0` → `SS1` → `SS2`) | Firm PType (`Names_i(5:8)`) | Base Firm Share | Firm Prod Grid $`[z_{\ell,k}, z_{h,k}]`$ | Annual Trend $`G_{k,\mathrm{ann}}`$ |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Rural** | `HH_Rural` | **16.0%** | `1.05` → `1.04` → `1.03` | `0.048` (2.7x–3.0x) | `0.015` → `0.038` → `0.018` (85% retired) | `Firm_Rural` | **15.0%** | `[0.70, 1.15]` | `1.007` (+0.7%/yr) |
| **2. Small (<100k)** | `HH_Small` | **24.0%** | `1.40` → `1.36` → `1.34` | `0.036` (2.3x) | `0.010` → `0.031` → `0.013` (85% retired) | `Firm_Small` | **23.0%** | `[0.75, 1.28]` | `1.011` (+1.1%/yr) |
| **3. Large (>100k)** | `HH_Large` | **25.9%** | `2.05` → `1.95` → `1.90` | `0.022` (1.4x) | `0.005` → `0.025` → `0.008` (85% retired) | `Firm_Large` | **26.9%** | `[0.83, 1.50]` | `1.018` (+1.8%/yr) |
| **4. Auckland** | `HH_Auckland` | **34.1%** | `3.10` → `2.87` → `2.77` | `0.016` (1.0x base) | `0.000` → `0.028` → `0.004` (85% retired) | `Firm_Auckland` | **35.1%** | `[0.90, 1.75]` | `1.025` (+2.5%/yr) |

* **Guvenen et al. (2023) Tax Shift & Wage / House Price Multipliers (`WelfareDecomposition_4Region.m`):**
  * Shifting from corporate/capital income tax $`\tau_k`$ to a book-value wealth/land levy (*τ_a* = 0.015 (1.5%)) and estate levy ($`\tau_b = 25\%`$ in `SS1`, `18%` in `SS2`) on the NZD 1.6T property transfer wave yields `SS1` general-equilibrium wage multipliers `w_mult_GE = [1.032, 1.038, 1.048, 1.055]` (**+3.2% to +5.5%**, rising to **+6.8% to +9.6%** in `SS2`) and house-price cooling multipliers `Q_mult_GE = [0.990, 0.975, 0.950, 0.925]` (**-1.0% to -7.5%** in `SS1`, and **-7.5% to -10.5%** in `SS2`).

* **Aspect 3 Historical Crisis Comparison — Top-1% Net Worth Adjustment vs. Once-a-Decade Market Shocks (Doc 1A Part II, Aspect 3):**
  * *Document 1A Claim:* The controlled cooling of metropolitan land overvaluation (**-7.5% in `SS1` to -10.5% in `SS2` in Auckland**) and the net balance-sheet adjustment for the top 1% of wealth holders (**retaining 90.2% to 94.6% of compounded net worth on a portfolio-average basis, and 95.3% to 98.5% for active business owners**) represent a smaller portfolio haircut than New Zealand investors routinely absorb during once-a-decade macro shocks:
    1. **1987 New Zealand Sharemarket Crash:** Barclays Industrial Index fell **~60%** from its September 1987 peak (RBNZ Financial Stability historical series; Easton, 1997).
    2. **1997–1998 Asian Financial Crisis & 2000–2001 Tech Bust:** NZD trade-weighted index and global equity portfolios experienced **20% to 45%** drawdowns.
    3. **2008–2009 Global Financial Crisis (GFC):** Global equities fell **~40%**, over 60 New Zealand finance companies failed, and real REINZ/RBNZ house prices fell **~12%**.
    4. **2022–2024 RBNZ Interest-Rate Tightening Cycle:** Following the November 2021 peak, real inflation-adjusted REINZ/CoreLogic House Price Indices fell **~18% to 22% nationally** and **~22% to 27% in Auckland and Wellington**—more than double our model's entire 60-year land-value cooling (`Q_mult_GE(4) = 0.925` in `SS1` and `0.895` in `SS2`).

### 2.4 Part II Synthesis — Social Cohesion, Institutional Friction, Identity Utility, and Coalition Supermodularity as a function of Social Credit Ratings

#### 2.4.1 Coase–North Commissioning Efficiency and Williamson Actuarial Alignment

Let $`\tau_{\mathrm{friction}}(\mathcal{G}) \in [0, 1)`$ denote the share of nominal public social expenditure $`G_{\mathrm{nominal},1}`$ dissipated in inter-agency contracting and compliance overhead under governance structure $`\mathcal{G}`$:

$$
G_{\mathrm{effective},1}(\mathcal{G}) = (1 - \tau_{\mathrm{friction}}(\mathcal{G})) G_{\mathrm{nominal},1}, \qquad \tau_{\mathrm{friction}}(\mathcal{G}_{\mathrm{siloed}}) = 0.32 \longrightarrow \tau_{\mathrm{friction}}(\mathcal{G}_{\mathrm{Wh\bar{a}nauOra}}) \le 0.08
$$

Aligning the governance accounting horizon $`T_{\mathrm{horizon}} = 81`$ years with the physical asset life of human capability via the Social Rate of Time Preference ($`r_{\mathrm{SRTP}} = 0.02`$) yields the Year-5 ACC actuarial present-value release:

$$
\mathrm{NPV}_{\mathrm{ACC}}(t = 5) = \sum_{s=1}^{81} \frac{\Delta \mathbb{E}\left[ \tau_y w_s h_s - \sum_{x \in \lbrace 1,2,4 \rbrace} C_x \mathbb{I}(\mathrm{Exit}_x) \right]}{(1 + r_{\mathrm{SRTP}})^s} = \mathrm{NZD}\ 35.25\mathrm{B\ to\ }40.86\mathrm{B}
$$

#### 2.4.2 Akerlof–Kranton Adolescent Identity Utility and Topkis Coalition Supermodularity
At Gate 2 (ages 12–14), adolescent educational effort $`e_2^\star`$ maximizes the identity-augmented utility function:

$$
U_j^i(c, \ell, e_2) = u(c, \ell) + \lambda_{\text{id}} \mathcal{I}_{\mathrm{p\bar{u}r\bar{a}kau}}(e_2, M_{\text{tuakana}}, \text{Cohesion}_t), \qquad \frac{\partial e_2^\star}{\partial \mathcal{I}_{\mathrm{p\bar{u}r\bar{a}kau}}} > 0
$$

Finally, let $`\mathcal{A}_1`$ denote the actuarial and tax-rebalancing policy vector and $`\mathcal{A}_2`$ denote the polycentric community and cultural-stewardship vector. By Topkis's (1998) Supermodularity Theorem, the social welfare functional $`\mathcal{W}(\mathcal{A}_1, \mathcal{A}_2)`$ exhibits strictly positive complementarity across the two institutional architectures:

$$
\mathcal{W}(\mathcal{A}_1 \cup \mathcal{A}_2) - \left[ \mathcal{W}(\mathcal{A}_1) + \mathcal{W}(\mathcal{A}_2) \right] = \Delta_{\mathrm{k\bar{\imath}ato}} > 0
$$

#### 2.4.3 Calibrating the Social Cohesion Index ($`S_t: 100.0 \to 112.0\text{–}118.4 \to 126.0`$) to Transparency International's CPI ("Social Credit Rating")

* **Document 1A Claim (Part II Synthesis):** New Zealand's slide on Transparency International's Corruption Perceptions Index (CPI) from **#1 globally** (peaking at **96/100** in 2004 and still **88/100** as #1-equal in 2021) down to a 30-year low of **81/100** (**#4 equal** in the 2025/2026 index, behind **#1 Denmark at 89, #2 Finland at 88, and #3 Singapore at 84**) reflects the institutional and civic cost of child material deprivation, high replacement-migration turnover (`Churn_Rate`), and opaque property-wealth shelters.
- **Code & Literature Mapping:** In `WelfareDecomposition_4Region.m`, `TransPath_4Region_Master.m`, and `Plot_Counterfactuals_And_MirrorInvestments.m`, the macro Social Cohesion Index $`S_t`$ enters relational utility $`u_{\text{rel}}(S_t, \text{RetainedYouth}_t)`$ as a decreasing function of the struggling cohort share ($`h_1\text{–}h_2`$) and skilled demographic churn (`Churn_Rate`).
- **Literature Anchor on Values-Based Framing & Epistemic Resilience:** Benchmarked to Dr. Jess Berentson-Shaw (*A Matter of Fact: Talking Truth in a Post-Truth World*, Bridget Williams Books, 2018) and Finland's national cross-curricular multiliteracy framework (*Monilukutaito*, Finnish National Agency for Education, 2024; #1 on the European Media Literacy Index and #2 globally on the 2025/2026 Transparency International CPI at 88/100). Demonstrates empirically why leading with shared intergenerational values (*manaakitanga*, *kaitiakitanga*) and causal system metaphors ("getting Aotearoa up on foils" / *Te Waka Hourua*) paired with early executive-function and adolescent *Tuakana–Teina* critical-thinking development accelerates credibility convergence ($`\lambda_{\mathrm{cred}}(t) \to 1`$) and insulates long-horizon policy compacts against polarization drag.

---

## 3. Part III Cross-Reference: Population & Fiscal Sankey Ledgers and Interactive Web Explorer

## 3.1 The 5-Stage (18-Node) Population Cohort Fates Sankey ( Table15_ChildFates_5Stage_Decomp_<Region>.csv )

*Source Script:* `Plot_ChildFates_SSankey.m` *(Supports $N = 1, 2, 3, \dots$ phases via `Active_Phases` and `Build_Phase_Registry.m`; Figure: `Fig_ChildFates_5Stage_2Panel_National_Dunedin_22.png`)*

Each node's ribbon width represents the exact percentage of the birth cohort (`Pop_18Nodes_Pct`) passing through that developmental state:

<img src="./Output_NZ_4Region_Intergen/Fig_ChildFates_5Stage_2Panel_National_Dunedin_22.png" alt="National 5-Stage Population Cohort Fates Sankey" width="100%" style="display: block; width: 100%; margin: 1.0rem auto; break-inside: avoid; page-break-inside: avoid;" />


| *Stage (Child $J$ Axis)* | *Node ID & Canonical Label* | *National `SS0` (%)* | *National `SS1` (%)* | *National `SS2` (%)* | *Auckland `SS0` (%)* | *Auckland `SS1` (%)* | *Structural Definition in `Plot_ChildFates_SSankey.m`* |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| *Stage 1 $(J = 1)$*<br>*Birth, Age 0* | `1_Severe_Material_Hardship_DEP17`<br>`2_Residual_AHC_Squeeze_Paper_Support`<br>`3_Secure_Parental_Asset_Buffer` | 9.80%<br>14.20%<br>76.00% | 2.60%<br>5.14%<br>92.26% | 1.20%<br>3.18%<br>95.62% | 11.40%<br>18.00%<br>70.60% | 3.10%<br>5.72%<br>91.18% | **Node 1 (Deep Crimson):** Acute asset floor ($a < 0.05 Q_k$, DEP-17 9+ `[Ref 48]`).<br>**Node 2 (Burnt Rust):** Residual AHC-50 squeeze ($0.05 Q_k \le a < 0.16 Q_k$), buffered in provincial regions by unpaid *whānau* care $K_{\text{whānau}}(k)$ `[Ref 47]`. |
| *Stage 2 $(J = 2\text{–}3)$*<br>*First 2000 Days* | `4_Unmitigated_Corner_ic0`<br>`5_Public_ECE_Moderate_Inv`<br>`6_High_Wraparound_Whanau_Inv` | 24.00%<br>49.30%<br>26.70% | 5.67%<br>67.63%<br>26.70% | 2.06%<br>69.44%<br>28.50% | 29.40%<br>43.90%<br>26.70% | 6.47%<br>66.83%<br>26.70% | `m_corner`: tracks exit from $i_c = 0$ corner via universal $G_{\text{ECE},1}$ and regional alloparental buffer $K_{\text{whānau}}(k)$. |
| *Stage 3 $(J = 5)$*<br>*Adol. Gate,<br>12–14* | `7_Compounded_HH_Psychosocial_Stress`<br>`8_Standard_Public_Schooling`<br>`9_Montessori_Tuakana_Mentoring` | 18.88%<br>63.82%<br>17.30% | 4.91%<br>37.79%<br>57.30% | 2.45%<br>32.55%<br>65.00% | 21.15%<br>61.55%<br>17.30% | 5.50%<br>37.20%<br>57.30% | Evaluates compounded parental distress ($i_z \in \{1,2\}$) and adolescent psychosocial morbidity $\lambda_{\text{psy}}$ `[Ref 19, 20, 38]` vs. Montessori / *Tuakana–Teina* & family connection buffers `[Ref 18, 55]` (82% $\to$ 38% persistence). |
| *Stage 4 $(J = 6\text{–}7)$*<br>*Adult Launch, 20* | `10_Struggling_Tier_h1_h2`<br>`11_Core_Skill_Tier_h3_h5`<br>`12_Thriving_Tier_h6_h7` | 22.00%<br>54.50%<br>23.50% | 4.02%<br>38.68%<br>57.30% | 1.50%<br>33.50%<br>65.00% | 24.80%<br>52.10%<br>23.10% | 4.50%<br>37.50%<br>58.00% | Completed pre-labor skill mapped onto 7-point grid `h_vec = [0.45..1.80]` (`22.0%` struggling in `Dunedin_22` `[Ref 16]`, `28.5%` in `MetroSqueeze_GUiNZ` `[Ref 17]`). |
| *Stage 5 $(J = 10)$*<br>*Adulthood, 30+* | `13_Exit1_State_Care`<br>`14_Exit2_Avoidable_Hospitalisation`<br>`15_Exit3_Lower_Lifetime_Income`<br>`16_Exit4_Benefit_Justice_Burden`<br>`17_Retained_NZ_Secure_Thriving`<br>`18_Emigrated_Abroad_BrainDrain` | 2.10%<br>4.82%<br>9.63%<br>11.38%<br>61.14%<br>10.93% | 0.49%<br>1.62%<br>4.15%<br>3.89%<br>81.29%<br>8.56% | 0.24%<br>1.12%<br>2.95%<br>2.44%<br>85.65%<br>7.60% | 2.35%<br>5.28%<br>10.42%<br>12.55%<br>50.11%<br>19.29% | 0.54%<br>1.75%<br>4.38%<br>4.18%<br>74.23%<br>14.92% | Dunedin concentration: 22% struggling tier (`Node 10`) drives *74.1%* of acute Exits 1, 2, 4 (`Nodes 13, 14, 16`) in `SS0` (empirical Dunedin Study benchmark: *57%–81%* `[Ref 16]`). |

---

## 3.2 The 6-Gate (29-Node) Lifecycle Fiscal Ledger Sankey & 4-Lane Survey Reconciliation (`Table14_FiscalLedger_6Gate_Decomp_<Region>.csv`)

*Source Script:* `Plot_ChildFiscal_SSankey.m` *(29 Nodes across 6 Gates; Cohort-to-Ledger Transformation with Vertical Regime-Break Wave at Gate 5, $X = 5.0$, separating Human Cohort & Career Strata across Gates 1–5 from the Single Annualized Adult Fiscal Ledger at Gate 6; Figure: `Fig_ChildFiscal_6Gate_3Panel_National_Dunedin_22.png`)*

<img src="./Output_NZ_4Region_Intergen/Fig_ChildFiscal_6Gate_2Panel_National_Dunedin_22.png" alt="National 6-Gate Lifecycle Fiscal Ledger Sankey" width="100%" style="display: block; width: 100%; margin: 1.0rem auto; break-inside: avoid; page-break-inside: avoid;" />

To eliminate cross-account ontological distortion while reconciling model flows with the *NZD 15,000 to NZD 19,000 per child per year* household expenditure survey benchmark, `Table14_FiscalLedger_6Gate_Decomp_<Region>.csv` tracks the human cohort across **Gates 1–5 (Nodes 1–21)** before mapping the five adult career strata into the **eight annualized fiscal ledger accounts at Gate 6 (Nodes 22–29)**, recording both the *Cohort-Weighted Flow (`<Phase>_CohortFlow_kNZD`)*, the *Conditional Per-Person Rate (`<Phase>_CondPerChild_kNZD`)*, and the *4-Lane Decomposition* (anchored to $1.0\text{ model unit} = 95.0\text{ kNZD/yr}$ mean prime household earnings):
- `LaneA_PrivCash_kNZD`: Private parental out-of-pocket cash expenditure (net child investment $(1 - s_{\text{sub}})i_c$ + child sustenance share of food, utilities, and housing $c_{nd} + c_H$).
- `LaneB_WhanauTime_kNZD`: Imputed value of parental and extended *whānau* care and mentoring time ($w_k z_p h_p \ell_{\text{child}}$ plus Marilyn Waring's uncounted alloparental buffer $0.085 K_{\text{whānau}}(k) w_k z_p h_p$ in Node 2 [Ref 47]).
- `LaneC_PubDev_kNZD`: Proactive public developmental investment and core infrastructure/tax flows (Paid Parental Leave, BestStart, universal ECE $G_{\text{ece},1}$, public schooling $d_2$, Montessori / *Tuakana–Teina* mentoring $G_{\text{ece},2}$, domestic workforce/builder strata, base infrastructure/health/NZ Super, and Good Tax revenues).
- `LaneD_RemedRent_kNZD`: Reactive public remediation outlays, rent-seeking capture, and foregone tax drag (Tier 3 acute hardship support, Accommodation Supplement landlord rent capture in Node 2, ECE corner benefit need, household unemployment/truancy remediation, CAMHS/ACC ISSC trauma care, adult Exits 1, 2, 3, and 4, passive land speculation $z_l$, and Abroad brain-drain tax loss).

*(For A3 print readability, the 29-Node Fiscal Ledger is split below into **Table 3.2A: Gates 1–4 — Childhood Resource Flows & Age-20 Skill Launch (Nodes 1–16)** and **Table 3.2B: Gates 5–6 — Prime Career & Enterprise Sorting ($z_l$ vs. $z_h$) into the Annualized Adult Fiscal Ledger (Nodes 17–29)**.)*

### Table 3.2A: Left Regime (Part 1) — Childhood Resource Flows & Skill Launch (Gates 1–4, Nodes 1–16, Ages 0–20)

| **Gate & Window** | **Node ID & Canonical Name** | **SS0 Pop % & Flow (kNZD/yr)** | **SS1 Pop % & Flow (kNZD/yr)** | **SS2 Pop % & Flow (kNZD/yr)** | **4-Lane Assignment & Conditional Rate Reconciliation** |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Gate 1** (*J* = 1)<br>*Birth, Age 0* | `1_Material_And_Severe_Hardship`<br>`2_Residual_AHC_Paper_And_Whanau`<br>`3_Universal_Birth_Benefit`<br>`4_Private_Birth_OutOfPocket` | 9.5% & 1.1<br>15.6% & 1.0<br>100% & 9.5<br>74.9% & 14.0 | 2.5% & 0.4<br>5.7% & 0.5<br>100% & 18.9<br>91.8% & 18.0 | 1.9% & 0.2<br>3.8% & 0.3<br>100% & 20.8<br>94.3% & 19.6 | **Node 1 (Crimson, Lane D):** Acute DEP-17 Tier 3 support. **Node 2 (Rust, Lanes B & D):** AS landlord capture vs. Waring unpaid *whānau* buffer [Ref 47, 48]. **Node 3 (Lane C):** PPL + BestStart. **Node 4 (Gold, Lanes A+B):** 63% cash / 37% time. |
| **Gate 2** (*J* = 2–3)<br>*First 2000 Days* | `5_ECE_Corner_Benefit_Need`<br>`6_Public_ECE_Wraparound`<br>`7_High_Intensity_Public_ECE`<br>`8_Private_Parental_ECE_CashTime` | 23.2% & 3.5<br>51.9% & 4.5<br>24.9% & 3.6<br>76.8% & 14.0 | 5.1% & 0.8<br>55.4% & 8.9<br>39.5% & 9.7<br>94.9% & 18.4 | 3.7% & 0.6<br>52.2% & 10.1<br>44.1% & 10.6<br>96.3% & 19.6 | **Node 5 (Crimson, Lane D):** Unmitigated *i*<sub>c</sub> = 0 corner benefit need. **Nodes 6–7 (Lane C):** Public ECE wraparound (*G*<sub>ece,1</sub>). **Node 8 (Gold, Lanes A+B):** **18.5–18.7 kNZD/yr** conditional per non-corner child (60% cash / 40% time). |
| **Gate 3** (*J* = 5)<br>*Adol. Gate, 12–14* | `9_HH_Unemp_And_Truancy_Remed`<br>`10_Psychosocial_CAMHS_ACC_ISSC`<br>`11_Public_Secondary_Schooling`<br>`12_Montessori_Tuakana_Public`<br>`13_Private_Adol_Commit_CashTime` | 13.5% & 3.5<br>7.1% & 1.0<br>58.8% & 6.3<br>20.6% & 3.2<br>79.4% & 15.1 | 2.0% & 0.3<br>2.5% & 0.6<br>33.4% & 5.6<br>62.1% & 10.6<br>95.5% & 19.9 | 1.3% & 0.2<br>1.7% & 0.4<br>33.2% & 6.0<br>63.8% & 12.0<br>97.0% & 22.3 | **Node 9 (Crimson, Lane D):** Household unemployment & truancy remediation. **Node 10 (Rust, Lane D):** Cross-income psychosocial CAMHS & ACC ISSC (38% clinical floor) [Ref 19, 38]. **Node 12 (Teal, Lane C):** *Tuakana–Teina* mentoring. **Node 13 (Gold):** **19.0–19.8 kNZD/yr** conditional. |
| **Gate 4** (*J* = 6–7)<br>*Launch, Age 20* | `14_Struggling_Tier_h1_h2_Launch`<br>`15_Core_Skill_Tier_h3_h5_Launch`<br>`16_Thriving_Tier_h6_h7_Launch` | 23.5% & 5.1<br>61.1% & 16.0<br>15.4% & 4.4 | 4.5% & 1.0<br>46.4% & 15.2<br>49.1% & 20.8 | 2.5% & 0.6<br>45.0% & 15.8<br>52.5% & 24.5 | Pre-labor capability tiers (*h*<sub>1</sub>–*h*<sub>2</sub>, *h*<sub>3</sub>–*h*<sub>5</sub>, *h*<sub>6</sub>–*h*<sub>7</sub>) launching into Gate 5 career and enterprise sorting. |

### Table 3.2B: Right Regime — Prime Career Sorting (Gate 5, Nodes 17–21) to the Single Annualized Adult Fiscal Ledger (Gate 6, Nodes 22–29)

| **Gate & Window** | **Node ID & Canonical Name** | **SS0 Pop % & Flow (kNZD/yr)** | **SS1 Pop % & Flow (kNZD/yr)** | **SS2 Pop % & Flow (kNZD/yr)** | **Structural Mechanism & Fiscal Ledger Role** |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Gate 5** (*J* = 8–11)<br>*Career & z<sub>l</sub> / z<sub>h</sub> Sorting*<br>*(Left of Wave)* | `17_Career_Chronic_Adversity_Trap`<br>`18_Career_Domestic_Core_Workforce`<br>`19_Career_Passive_Land_Rent_zl`<br>`20_Career_Productive_Builders_zh`<br>`21_Career_Emigrated_Abroad` | 21.7% & 10.7<br>47.9% & 19.6<br>**14.0% & 5.4**<br>**6.8% & 3.5**<br>9.7% & 2.8 | 4.5% & 2.2<br>40.3% & 18.3<br>**7.7% & 3.5**<br>**39.9% & 26.0**<br>7.4% & 2.9 | 2.5% & 1.1<br>36.2% & 16.4<br>**3.6% & 1.7**<br>**52.0% & 34.1**<br>5.7% & 2.2 | Guvenen / Murphy-Shleifer-Vishny occupational sorting [Ref 2, 7]: In **SS0**, 61% of retained top talent is captured by passive land speculation (*z*<sub>l</sub>, **Node 19**). In **SS1/SS2**, τ<sub>a</sub> = 1.5%, τ<sub>b</sub> = 25% → 18%, and Youth Grant *E* rotate talent into *z*<sub>h</sub> Builders (**Node 20**, surging from **6.8% to 39.9%–52.0%**). |
| **Gate 6** (*J* = 10–16)<br>*Bottom 4 Exits*<br>*(Ordered 1 to 4)* | `22_Fiscal_Exit1_State_Care_Legacy`<br>`23_Fiscal_Exit2_Avoidable_Hosp_CAMHS`<br>`24_Fiscal_Exit3_LowerSkill_LostTax`<br>`25_Fiscal_Exit4_Benefit_LOPE_Justice` | 3.25% & 1.30<br>6.7% & 2.4<br>9.5% & 2.4<br>11.5% & 5.6 | 0.81% & 0.26†<br>1.7% & 0.5<br>4.4% & 0.7<br>3.1% & 1.2 | 0.50% & 0.12†<br>1.0% & 0.3†<br>3.5% & 0.6<br>1.7% & 0.6 | Ordered strictly **1 → 2 → 3 → 4** bottom-to-top to match Fates Nodes 13–16. *†(When an Exit compresses below 0.45 kNZD/yr in SS1/SS2, a thin legibility floor keeps the node visible with exact % and kNZD/yr labeled `— not to scale`.)* |
| **Gate 6** (*J* = 10–16)<br>*Base Outlay, Tax Credits & Abroad* | `26_Fiscal_Infra_Health_NZSuper`<br>`27_Fiscal_GST_Cap_Estate_Tax`<br>`28_Fiscal_WorkingAge_PAYE_Tax`<br>`29_Fiscal_Abroad_BrainDrain_LostTax` | 90.3% & 9.2<br>90.3% & 10.3<br>90.3% & 11.4<br>9.7% & 2.8 | 92.6% & 9.5<br>92.6% & 19.7<br>92.6% & 19.7<br>7.4% & 2.9 | 94.3% & 9.6<br>94.3% & 23.1<br>94.3% & 19.2<br>5.7% & 2.2 | **Node 26:** Attributes **10.2 kNZD/yr per retained adult** (6.46k roads/infra/health + 3.76k NZ Super), printing regional gross scale (`0.060 * reg_pop_share * S6_Totals(5)` BNZD/yr per cohort wave; `4.0 * reg_pop_share * S6_Totals(5)` BNZD/yr across adult stock). **Net Fiscal Surplus (Ω<sub>fiscal</sub>):** Rises to **+27.0 to +28.0 kNZD/yr in SS1** and **+29.9 to +31.2 kNZD/yr in SS2** (split 50/50 in the centered callout badge). |

---

### 3.3 Zero-Dependency Interactive HTML5 + SVG Sankey Explorer (`exportSankeyToHTML.m`)

* **Document 1A Claim (End of Part III):** The online versions of the Population and Fiscal Sankey diagrams feature clickable dialogs for every visible ribbon and node, detailing the structural mechanism driving each flow alongside the empirical data and theoretical references justifying each calculation.
* **Code & Output Mapping:** Invoked automatically by `Plot_ChildFates_SSankey.m` and `Plot_ChildFiscal_SSankey.m` via `exportSankeyToHTML(axHdl, SK, linksCell, narrativeMap, valFmtStr, outHtmlFile)`, exporting standalone HTML5 files (`Interactive_ChildFates_SS0_National.html`, `Interactive_ChildFates_SS1_National.html`, `Interactive_ChildFiscal_SS0_National.html`, `Interactive_ChildFiscal_SS1_National.html`, and regional counterparts) into `Output_NZ_4Region_Intergen/`. Uses a 65-point cosine S-curve rail reconstructor ($`s(\tau) = 0.5(1 - \cos(\pi \tau))`$) to guarantee strictly positive vertical ribbon thickness $`(1 - s(\tau))H_L + s(\tau)H_R > 0`$ across all diagonal flows, paired with embedded JSON narrative maps and Up/Down/Left/Right keyboard navigation.

### 3.4 — Complete Standalone Mathematical Specification & Calibration Reference: Extended Whānau Networks, Pension Eligibility U-Curve, and Dynamic Complementarity

#### 3.4.1 Endogenous Coupling of NZ Superannuation, Housing User Costs, and Extended Whānau Capacity

Let $`K_{\mathrm{whanau},0}(k) \in [0, 1]`$ denote the baseline regional extended-*whānau* proximity and alloparental network intensity across the four spatial regions $`k \in \{\mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland}\}`$, calibrated at baseline to:

$$
K_{\mathrm{whanau},0} = \left[0.42, 0.38, 0.32, 0.28\right] \quad (\text{or } [0.65, 0.50, 0.30, 0.20] \text{ in unadjusted proximity units})
$$

This gradient reflects higher multigenerational co-residence and proximity in rural and provincial regions versus nuclear-household isolation in high-rent metropolitan Auckland.

Because cohorts at active parenting ages $`j \in [j_{s1,\mathrm{start}}, j_{s2,\mathrm{end}}]`$ (biological ages 26 to 43) overlap in calendar time with their own parents, aunties, and uncles at ages 55 to 72, the effective regional alloparental bandwidth $`K_{\mathrm{whanau}}(k) \in [0, 1]`$ is not invariant to fiscal pension parameters or regional housing costs. Specifically, effective *whānau* capacity is governed by the product of baseline spatial proximity $`K_{\mathrm{whanau},0}(k)`$, an **Asymmetric Elder Time-Availability Multiplier** $`\Phi_{\mathrm{time}}(A_{\mathrm{super}})`$, and an **Elder Home-Stability Multiplier** $`\Phi_{\mathrm{home}}(p_{\mathrm{super}}, Q_k)`$:

$$
K_{\mathrm{whanau}}(k) = \min\left(1.0, \max\left(0.0, K_{\mathrm{whanau},0}(k) \cdot \Phi_{\mathrm{time}}(A_{\mathrm{super}}) \cdot \Phi_{\mathrm{home}}(p_{\mathrm{super}}, Q_k)\right)\right)
$$

The two endogenous multipliers are defined as follows:

**1. Asymmetric Grandparent and Aunty Time Multiplier Across the Retirement-Age U-Curve ($`\Phi_{\mathrm{time}}`$):** Let $`A_{\mathrm{super}} = 20 + (J_r - 1)\Delta t`$ denote the statutory NZ Superannuation eligibility age relative to the statutory baseline $`A_{\mathrm{base}} = 65.0`$:
- *Above Age 65 (Austerity Squeeze, $`A_{\mathrm{super}} \ge 65`$):* Raising $`A_{\mathrm{super}}`$ above 65 forces older *whānau* aged 65 to $`A_{\mathrm{super}}`$ to remain in market employment ($`\ell > 0`$) to satisfy the pre-retirement budget constraint, withdrawing alloparental caregiving time exponentially at rate $`\eta_{\mathrm{elder}} = 0.09\text{ yr}^{-1}`$.
- *Below Age 65 (Early Retirement Kuia/Koroua Dividend, $`A_{\mathrm{super}} < 65`$):* Lowering $`A_{\mathrm{super}}`$ below 65 releases healthy 60-to-64-year-old *kuia*, *koroua*, and aunties into voluntary alloparental support with concave hyperbolic-tangent saturation ($`\kappa_{\mathrm{kuia}}^{\max} = 0.16`$, saturation scale $`\tau_{\mathrm{kuia}} = 1.80\text{ yrs}`$):

$$
\Phi_{\mathrm{time}}\left(A_{\mathrm{super}}\right) = \begin{cases}
\exp\left(-\eta_{\mathrm{elder}}\left(A_{\mathrm{super}} - 65.0\right)\right) & \text{if } A_{\mathrm{super}} \ge 65.0 \\
1.0 + \kappa_{\mathrm{kuia}}^{\max} \tanh\left(\frac{65.0 - A_{\mathrm{super}}}{\tau_{\mathrm{kuia}}}\right) & \text{if } A_{\mathrm{super}} < 65.0
\end{cases}
$$

Evaluated across statutory retirement ages, this yields $`\Phi_{\mathrm{time}}(64) = 1.081`$ (**+8.1% *Kuia* time boost**), $`\Phi_{\mathrm{time}}(63) = 1.129`$ (**+12.9% boost**), $`\Phi_{\mathrm{time}}(65) = 1.000`$ (baseline), $`\Phi_{\mathrm{time}}(67) = 0.835`$ (**-16.5% time loss**), and $`\Phi_{\mathrm{time}}(70) = 0.638`$ (**-36.2% time loss**).

**2. Elder Housing Tenure Stability and Staying in Their Own Homes ($`\Phi_{\mathrm{home}}`$):** For retired or semi-retired grandmothers and aunties to provide a physical sanctuary in region *k*, their pension income $`p_{\mathrm{super}}`$ must cover the regional housing maintenance and energy user cost relative to the baseline house price $`Q_{k,0}`$:

$$
\Phi_{\mathrm{home}}\left(p_{\mathrm{super}}, Q_k\right) = \min\left(1.20, \max\left(0.50, \left(\frac{p_{\mathrm{super}}}{0.180}\right)\left(\frac{Q_{k,0}}{Q_k}\right)^{0.35}\right)\right)
$$

Under Status Quo ($`SS0`$) at Age 65 ($`p_{\mathrm{super}} = 0.180`$ and $`Q_k = Q_{k,0}`$), both multipliers evaluate to unity ($`\Phi_{\mathrm{time}} = \Phi_{\mathrm{home}} = 1.0`$). Under our Generational Plan ($`SS1 \to SS2`$), land-tax and housing-supply reforms cool metropolitan house prices ($`Q_k < Q_{k,0}`$) while lowering $`A_{\mathrm{super}}`$ to **64** in $`SS2`$, raising both $`\Phi_{\mathrm{home}} > 1`$ and $`\Phi_{\mathrm{time}} = 1.081`$.

---

#### 3.4.2 Four Structural Channels in the Two-Stage CES Child Skill Law of Motion

In `HumanCapital_Lifecycle_aprimeFn.m` (the single-experience-asset transition operator governing $`\theta_c \to \theta_c^{\prime}`$), extended *whānau* intensity $`K_{\mathrm{whanau}}(k)`$ operates alongside bidirectional *Tuakana–Teina* peer/school mentoring intensity $`M_{\mathrm{mentor}} \in [0, 1]`$, where:

$$
M_{\mathrm{mentor}} = \min\left(1.0, \max\left(0.0, \frac{G_{\mathrm{ece},2} - 0.045}{0.085 - 0.045}\right)\right)
$$

Together, $`K_{\mathrm{whanau}}(k)`$ and $`M_{\mathrm{mentor}}`$ enter the child skill accumulation technology through four distinct structural channels:

* **Channel 1: Intergenerational Whānau Human Capital Pooling.** Rather than restricting a child's family scaffolding solely to the nuclear parent's human capital reference $`h_{\mathrm{par}}`$, extended family proximity pools the experiential and cultural human capital of grandparents and aunties with weight $`\omega_{\mathrm{whanau}} = 0.15`$:

$$
h_p^{\mathrm{safe}} = \max\left(10^{-4}, h_{\mathrm{par}}\left(1 + \omega_{\mathrm{whanau}} K_{\mathrm{whanau}}(k)\right)\right)
$$

* **Channel 2: Stage-1 Informal Whānau Care and Early Language Immersion (First 2,000 Days, $`j \in [j_{s1,\mathrm{start}}, j_{s1,\mathrm{end}}]`$).** During ages 0 to 5, where inputs exhibit high substitutability ($`\varphi_1 = 0.35 > 0`$), grandmothers and aunties provide direct in-kind early care $`\eta_{\mathrm{whanau},1} K_{\mathrm{whanau}}(k)`$ (with $`\eta_{\mathrm{whanau},1} = 0.025`$), augmenting private investment $`i_c`$, downward *Tuakana–Teina* mentoring $`G_{\mathrm{ece},1}^{\mathrm{eff}} = G_{\mathrm{ece},1}(1 + \kappa_{\mathrm{down}} M_{\mathrm{mentor}})`$, and universal baseline support $`\bar{g}_{\mathrm{ece}}`$:

$$
I_{\mathrm{tot},1} = \max\left(10^{-4}, i_c + G_{\mathrm{ece},1}\left(1 + \kappa_{\mathrm{down}} M_{\mathrm{mentor}}\right) + \bar{g}_{\mathrm{ece}} + \eta_{\mathrm{whanau},1} K_{\mathrm{whanau}}(k)\right)
$$

$$
\theta_c^{\mathrm{target},1} = \left[\gamma_{1,\mathrm{self}}\left(\theta_c\right)^{\varphi_1} + \gamma_{1,\mathrm{inv}}\left(I_{\mathrm{tot},1}\right)^{\varphi_1} + \gamma_{1,\mathrm{par}}\left(h_p^{\mathrm{safe}}\right)^{\varphi_1}\right]^{1/\varphi_1}
$$

* **Channel 3: Stage-2 Unbanked Skill Fade-Out Anchoring (School & Adolescent Years, $`j \in [j_{s2,\mathrm{start}}, j_{s2,\mathrm{end}}]`$).** Without sustained adolescent scaffolding, early Stage-1 skill gains above the baseline endowment ($`\theta_{\mathrm{base}} = 0.65`$) erode at rate $`\delta_{\theta,\mathrm{fade}} = 0.22 w_2`$. School-based *Tuakana–Teina* mentoring $`M_{\mathrm{mentor}}`$ and extended *whānau* holiday/transition anchoring $`K_{\mathrm{whanau}}(k)`$ jointly arrest this fade-out:

$$
\theta_c^{\mathrm{ret}} = \max\left(10^{-4}, \theta_c - \delta_{\theta,\mathrm{fade}}\left(1 - M_{\mathrm{mentor}}\right)\left(1 - 0.35 K_{\mathrm{whanau}}(k)\right)\max\left(0, \theta_c - \theta_{\mathrm{base}}\right)\right)
$$

* **Channel 4: Stage-2 Harmonic-Mean Bottleneck Relief and Adolescent Corner-Distress Co-Buffering.** In Stage 2, the CES technology exhibits strong Cunha–Heckman dynamic complementarity ($`\varphi_2 = -0.95 < 0`$, approaching a harmonic-mean bottleneck):

$$
I_{\mathrm{tot},2} = \max\left(10^{-4}, i_c + G_{\mathrm{ece},2} + \bar{g}_{\mathrm{ece}} + \eta_{\mathrm{whanau},2} K_{\mathrm{whanau}}(k)\right), \quad \eta_{\mathrm{whanau},2} = 0.010
$$

$$
\theta_c^{\mathrm{ces},2} = \left[\gamma_{2,\mathrm{self}}\left(\theta_c^{\mathrm{ret}}\right)^{\varphi_2} + \gamma_{2,\mathrm{inv}}\left(I_{\mathrm{tot},2}\right)^{\varphi_2} + \gamma_{2,\mathrm{par}}\left(h_p^{\mathrm{safe}}\right)^{\varphi_2}\right]^{1/\varphi_2}
$$

  When a nuclear household suffers an unemployment, health, or housing-cost shock that forces private child investment to the corner ($`i_c < 0.01`$), the adolescent faces a toxic family-stress penalty $`\psi_{\mathrm{unemp}} = 0.045`$ per sub-period step. Active school mentoring $`M_{\mathrm{mentor}}`$ buffers 80% of this shock, while having an aunty's or grandmother's sanctuary ($`K_{\mathrm{whanau}}(k)`$) independently buffers 55% of the residual distress alongside a positive socio-emotional leadership lift $`\kappa_{\mathrm{up}}`$:

$$
\Psi_{\mathrm{adolescent}} = -0.045 \cdot \mathbb{I}\left(i_c < 0.01\right)\left(1 - 0.80 M_{\mathrm{mentor}}\right)\left(1 - 0.55 K_{\mathrm{whanau}}(k)\right) + 0.035 M_{\mathrm{mentor}} + 0.010 K_{\mathrm{whanau}}(k)
$$

---

#### 3.4.3 Mirroring in the Household Bellman Return Function (`ReturnFn_SpatialHH.m` and `ReturnFn_SpatialHH_Compact4D.m`)

To ensure that the household's behavioral first-order condition with respect to private child investment $`i_c`$ and late-life labor supply $`\ell`$ is incentive-compatible across all retirement ages $`A_{\mathrm{super}} \in [60, 75]`$, `ReturnFn_SpatialHH_Compact4D.m` incorporates both the *whānau* child-skill proxy and age-dependent late-life senescence and work disutility:

$$
s_{\mathrm{sub}}(k) = \min\left(0.80, \frac{G_{\mathrm{ece}} + 0.015 K_{\mathrm{whanau}}(k)}{\max\left(10^{-4}, G_{\mathrm{ece}} + \bar{g}_{\mathrm{ece}} + 0.015 K_{\mathrm{whanau}}(k)\right)}\right)
$$

* **Late-Life Physiological Earning Decay & Work Disutility Past Age 65 ($`A_{\mathrm{super}} > 65`$ vs. $`A_{\mathrm{super}} < 65`$):**
  For working-age brackets past biological age 65 ($`\mathrm{age}_j \ge 65`$ when $`A_{\mathrm{super}} > 65`$), earning capacity decays at rate $`\delta_{\mathrm{sen},65+} = 0.08\text{ yr}^{-1}`$ while physical labor disutility rises with slope $`\psi_{\mathrm{wear},65+} = 0.14\text{ yr}^{-1}`$ (amplified for manual/low-*h* workers via $`\max(0.5, 1.5 - 0.6 h)`$). Conversely, when $`A_{\mathrm{super}} < 65`$, workers retiring between $`A_{\mathrm{super}}`$ and 65 gain early-retirement manual wear-and-tear relief $`\psi_{\mathrm{relief},<65} = 0.38`$ and provide positive *Kuia / Koroua* relational utility to young families.

---

#### 3.4.4 Cross-Derivative Proof of the Dynamic Complementarity Casualty Under Super Age 70

Why does raising the NZ Super age from 65 to 70 inflict disproportionate damage on low-income and shock-exposed children? Because $`\varphi_2 = -0.95 < 0`$, the elasticity of substitution in Stage 2 is $`\sigma_2 = 1/(1 - \varphi_2) = 0.513 < 1`$. Taking the cross-partial derivative of $`\theta_c^{\mathrm{ces},2}`$ with respect to retained early skill $`\theta_c^{\mathrm{ret}}`$ and total Stage-2 inputs $`X_m \in \{I_{\mathrm{tot},2}, h_p^{\mathrm{safe}}\}`$ yields:

$$
\frac{\partial^2 \theta_c^{\mathrm{ces},2}}{\partial \theta_c^{\mathrm{ret}} \partial X_m} = \left(1 - \varphi_2\right)\gamma_{2,\mathrm{self}}\gamma_{2,m}\left(\theta_c^{\mathrm{ces},2}\right)^{1 - 2\varphi_2}\left(\theta_c^{\mathrm{ret}} X_m\right)^{\varphi_2 - 1} > 0
$$

Because $`1 - \varphi_2 = 1.95 > 0`$, a reduction in $`K_{\mathrm{whanau}}(k)`$ caused by raising $`A_{\mathrm{super}}`$ from 65 to 70 ($`\Delta K_{\mathrm{whanau}}(k) = -0.362 K_{\mathrm{whanau},0}(k)`$) triggers a three-fold compounding loss: (i) it lowers $`\theta_c^{\mathrm{ret}}`$ entering Stage 2; (ii) it lowers $`h_p^{\mathrm{safe}}`$ and $`I_{\mathrm{tot},2}`$ inside the harmonic-mean aggregator; and (iii) for liquidity-constrained families at the *i_c* = 0 corner, it strips away $`0.55 |\Delta K_{\mathrm{whanau}}(k)|`$ of the exponential stress buffer in $`\exp(\Psi_{\mathrm{adolescent}})`$.

---

#### 3.4.5 Stationary OLG Cohort Pyramid & Unified Government Budget Identity Across $`A_{\mathrm{super}} \in [60, 75]`$

In `FertilityBargaining_Module.m`, for any statutory retirement age $`A_{\mathrm{super}} \in [60, 75]`$, the stationary 16-cohort OLG population pyramid $`N_5(j)`$ ($`j = 1, \dots, 16`$, spanning ages 20 to 99 in 5-year brackets) is constructed from the endogenous national fertility rate $`\mathrm{TFR}_{\mathrm{nat}}`$ and survival schedule $`s_{j,5\mathrm{yr}}`$, with exact continuous interpolation of the retirement boundary $`A_{\mathrm{super}}`$:

* **Above Age 65 ($`A_{\mathrm{super}} > 65`$):** Let $`\Delta M_{\mathrm{cut}} = M_{\mathrm{ret}}(65) - M_{\mathrm{ret}}(A_{\mathrm{super}})`$ denote the mechanical reduction in pensioner mass. The fraction of displaced seniors able to sustain healthy full-time work decays exponentially with age:

$$
\theta_{\mathrm{healthy}}\left(A_{\mathrm{super}}\right) = \theta_{\mathrm{healthy},65} \exp\left(-\lambda_{\mathrm{morb},65+}\left(A_{\mathrm{super}} - 65.0\right)\right)
$$

  Unhealthy displaced seniors ($`1 - \theta_{\mathrm{healthy}}`$) shift onto Supported Living, Jobseeker hardship, and acute geriatric hospital/ACC care with cost multiplier $`\phi_{\mathrm{leak}}(A_{\mathrm{super}}) = \phi_{\mathrm{leak},0} + \phi_{\mathrm{leak},1}(A_{\mathrm{super}} - 65.0)`$, while prime-age adult children suffer a sandwich elder-care tax-base drag $`\psi_{\mathrm{sandwich}}(1 - \theta_{\mathrm{healthy}})\Delta M_{\mathrm{cut}}`$.

* **Below Age 65 ($`A_{\mathrm{super}} < 65`$):** Let $`\Delta M_{\mathrm{add}} = M_{\mathrm{ret}}(A_{\mathrm{super}}) - M_{\mathrm{ret}}(65)`$ denote the added early-retiree mass. Avoided ACC, Supported Living, and Jobseeker payouts offset a decaying fraction $`\bar{\omega}_{\mathrm{off}}(A_{\mathrm{super}})`$ of the gross pension cost, while the working taxpayer denominator shrinks by the peak-earning weight $`\nu_{\mathrm{peak}}(A_{\mathrm{super}}) = \nu_{\mathrm{peak},0} + \nu_{\mathrm{peak},1}(65.0 - A_{\mathrm{super}})`$.

* **Unified PAYE Tax Solvency Identity ($`\tau_l^{\mathrm{req}}`$):** Anchored to the 2026 statutory baseline $`\tau_{l,0} = 22.00\%`$ at $`\mathrm{Dep}_{2026} = 24.50\%`$:

$$
\tau_l^{\mathrm{req}}\left(A_{\mathrm{super}}\right) = 0.22 + \beta_{\mathrm{dep}}\left(\mathrm{DepRatio}_{\mathrm{eff}}\left(A_{\mathrm{super}}\right) - \mathrm{Dep}_{2026}\right) - \beta_{\mathrm{hardship}}\Delta\overline{\mathrm{Struggling}} - \mathbb{I}_{SS2}\left[\Delta\tau_{\mathrm{harvest}}^{SS2}\min\left(1.05, \Phi_{\mathrm{time}}\right) - \psi_{\mathrm{aust}}\max\left(0, A_{\mathrm{super}} - 65\right)^{1.35}\right]
$$

---

#### 3.4.6 Named Calibration Parameters for NZ Superannuation Eligibility Age, Senescence, & Extended Whānau Elasticities (`Configure_TimeGrid_Params.m`)

Every behavioral, demographic, and fiscal elasticity governing the statutory retirement age $`A_{\mathrm{super}} \in [60, 75]`$ in `ReturnFn_SpatialHH_Compact4D.m`, `WelfareDecomposition_4Region.m`, and `FertilityBargaining_Module.m` is stored as a named parameter on `Params`:

| `Params` Field Identifier | Mathematical Symbol | Calibrated Value | Structural Role & Empirical / Literature Anchor |
| :--- | :---: | :---: | :--- |
| `Params.super_age_base` | $`A_{\mathrm{base}}`$ | `65.0` | Statutory NZ Superannuation baseline eligibility age (*New Zealand Superannuation and Retirement Income Act 2001*). |
| `Params.super_age_SS1` | $`A_{\mathrm{super}}^{SS1}`$ | `65.0` | Phase 1 (*SS1*, Years 0–24) statutory NZ Superannuation eligibility age. |
| `Params.super_age_SS2` | $`A_{\mathrm{super}}^{SS2}`$ | `64.0` | Phase 2 (*SS2*, 2050 Protocol) target eligibility age (`64.0` global welfare peak; swept over $[60, 75]$ in `T_UCurve`). |
| `Params.eta_elder_whanau` | $`\eta_{\mathrm{elder}}`$ | `0.090` | Semi-elasticity of grandparent/aunty caregiving time lost per year $`A_{\mathrm{super}} > 65`$ (9%/yr; Rupert & Zanella, 2018; Battistin et al., 2009). |
| `Params.kappa_kuia_max` | $`\kappa_{\mathrm{kuia}}^{\max}`$ | `0.160` | Maximum asymptotic *Kuia / Koroua* alloparental time boost when $`A_{\mathrm{super}} < 65`$ (+16% saturation ceiling; Compton & Pollak, 2014). |
| `Params.tau_kuia_sat` | $`\tau_{\mathrm{kuia}}`$ | `1.800` | Concave saturation scale (in years below 65) in $`\tanh((65 - A_{\mathrm{super}})/\tau_{\mathrm{kuia}})`$ (+8.1% boost at Age 64, +12.9% at Age 63). |
| `Params.delta_senescence_post65` | $`\delta_{\mathrm{sen},65+}`$ | `0.080` | Annual physiological earning-capacity decay past age 65 (8%/yr; Fan, Seshadri, & Taber, 2022; French, 2005). |
| `Params.psi_wear_post65` | $`\psi_{\mathrm{wear},65+}`$ | `0.140` | Annual late-life labor disutility slope per year worked past 65 (amplified for low-*h* manual workers; French & Jones, 2011). |
| `Params.psi_wear_early_relief` | $`\psi_{\mathrm{relief},<65}`$ | `0.380` | Pre-65 manual labor disutility relief when eligible for early NZ Superannuation ($`A_{\mathrm{super}} < 65`$). |
| `Params.theta_healthy_wrk_65` | $`\theta_{\mathrm{healthy},65}`$ | `0.480` | Share of displaced 65-year-olds able to sustain full-time healthy employment without benefit leak (implies 52% initial / 38%–45% average leak; NZ Treasury LTFM / MSD Supported Living tables). |
| `Params.lambda_health_decay_65` | $`\lambda_{\mathrm{morb},65+}`$ | `0.180` | Exponential morbidity decay rate per year above 65 for displaced seniors ($`\theta_{\mathrm{healthy}}(A) = \theta_{\mathrm{healthy},65} \exp(-\lambda_{\mathrm{morb},65+}(A - 65))`$; Case & Deaton, 2005). |
| `Params.phi_geriatric_leak_base` | $`\phi_{\mathrm{leak},0}`$ | `1.150` | Base fiscal cost multiplier on unhealthy displaced 65+ seniors (Supported Living + Accommodation Supplement + acute hospital/ACC drawdowns). |
| `Params.phi_geriatric_leak_slope` | $`\phi_{\mathrm{leak},1}`$ | `0.085` | Annual escalation in acute geriatric/hospital fiscal leak per year $`A_{\mathrm{super}} > 65`$ (Te Whatu Ora age-expenditure curve). |
| `Params.psi_sandwich_wrk_drag` | $`\psi_{\mathrm{sandwich}}`$ | `0.350` | Prime-age labor tax-base drag per unhealthy un-pensioned senior due to upward family caregiving (Coe & Van Houtven, 2009). |
| `Params.omega_acc_offset_under65` | $`\omega_{\mathrm{offset},<65}`$ | `0.280` | Fraction of gross early-retirement pension cost at Age 64 offset by avoided ACC, Supported Living, and Jobseeker payouts (28%, decaying at rate $`\lambda_{\mathrm{off}} = 0.85\text{ yr}^{-1}`$ for younger ages 60–63). |
| `Params.nu_peak_earn_u65` | $`\nu_{\mathrm{peak},0}`$ | `1.050` | Base tax-capacity weight of 60–64 peak lifecycle earners exiting the PAYE denominator when $`A_{\mathrm{super}} < 65`$ (plus slope $`\nu_{\mathrm{peak},1} = 0.040\text{ yr}^{-1}`$). |
| `Params.dep_ratio_2026_anchor` | $`\mathrm{Dep}_{2026}`$ | `24.50` | 2026 OLG effective dependency ratio calibration anchor balanced at statutory $`\tau_l = 22.00\%`$. |
| `Params.beta_aging_tax_drift` | $`\beta_{\mathrm{dep}}`$ | `0.220` | Marginal PAYE tax rate sensitivity (pp per percentage point of effective dependency ratio shift). |
| `Params.beta_exits_skill_div` | $`\beta_{\mathrm{hardship}}`$ | `0.145` | Marginal PAYE tax relief (pp per percentage point of struggling-cohort reduction across Exits 1, 2, 4 and skilled wage expansion). |
| `Params.ss2_harvest_div_base` | $`\Delta \tau_{\mathrm{harvest}}^{SS2}`$ | `2.070` | Phase 2 (*SS2*) Sovereign Debt-Sinking (-60 bps) and GE brain-drain/wage tax-base dividend (percentage points at Age 65, eroded by $`\psi_{\mathrm{aust}} = 0.220 (A_{\mathrm{super}} - 65)^{1.35}`$ when $`A_{\mathrm{super}} > 65`$). |

---

#### 3.4.7 Audited Retirement-Age U-Curve (`Table8B_SuperAge_UCurve_60to75.csv` from `FertilityBargaining_Module.m`)

Evaluating the unified government budget identity and household welfare decomposition across statutory retirement ages $`A_{\mathrm{super}} \in [60, 75]`$ reveals a textbook **U-curve in required working-age PAYE taxation** (minimized at **Age 65 = 17.97%** and **Age 64 = 18.25%**) and an **Inverted-U in national household welfare** (peaking at **Age 64 = +24.70% CE**):

| **Statutory NZ Super Age ($A_{\mathrm{super}}$)** | **SS2 Required PAYE Tax ($\tau_l$)** | **SS2 Effective Dependency Ratio** | **SS2 National TFR** | **SS2 Mean Struggling Share** | **SS2 National Welfare Gain (CE%)** | **SS0 Status Quo Required PAYE Tax** | **Structural & Fiscal Regime Interpretation** |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Age 60** | 20.45% | 39.80% | 1.871 | 2.22% | +22.72% | 26.40% | *Too Early:* Moving 60–64 peak earners onto Super swells DepRatio to 39.8%, consuming +2.48 pp of the PAYE tax cut. |
| **Age 61** | 19.83% | 36.95% | 1.871 | 2.23% | +23.62% | 25.68% | Prime-earner denominator loss still outweighs marginal *Kuia* time gain. |
| **Age 62** | 19.25% | 34.31% | 1.871 | 2.24% | +24.40% | 25.03% | Unlocks a -2.75 pp PAYE cut alongside 3 years of early retirement. |
| **Age 63** | 18.72% | 31.87% | 1.870 | 2.29% | +24.56% | 24.45% | Strong +12.9% *Kuia/Koroua* time boost + -3.28 pp PAYE tax cut. |
| **★ Age 64** | **18.25%** | **29.68%** | **1.869** | **2.41%** | **+24.70% (PEAK)** | 23.97% | **★ Global Welfare Peak:** 1 yr early retirement + +8.1% *Kuia* boost + **-3.75 pp PAYE cut** (incl. -0.64 pp from 85% $T_k$ retirement). |
| **★ Age 65** | **17.97% (MIN)** | **27.81%** | **1.866** | **2.60%** | **+24.53%** | 23.61% | **★ Global Tax Minimum:** Full **-4.03 pp PAYE cut** at current statutory retirement age 65. |
| **Age 66** | 18.38% | 27.45% | 1.864 | 3.21% | +22.74% | 23.65% | *Inflection Point:* Losing grandparent care (-8.6%) & late-life wear turns tax curve UP and welfare DOWN. |
| **Age 67** | 19.03% | 27.55% | 1.861 | 4.06% | +19.45% | 23.81% | Disability leak & *whānau* squeeze (-16.5%) erode +1.06 pp of tax relief and -5.25% CE of welfare. |
| **Age 68** | 19.85% | 28.10% | 1.859 | 5.00% | +15.70% | 24.10% | Sandwich care drag on 40–55-year-old adult children begins shrinking the effective working denominator. |
| **Age 69** | 20.80% | 29.07% | 1.857 | 6.01% | +11.58% | 24.50% | Almost the entire *SS2* PAYE cut is wiped out by geriatric/disability leaks and hardship rebound. |
| **Age 70** | **21.88%** | 30.44% | 1.855 | 7.07% | +7.15% | 25.01% | *Wipes Out Tax Relief:* Forcing 65–69-year-olds to work (-36.2% *whānau* care) destroys the PAYE dividend. |
| **Age 71** | 23.06% | 32.11% | 1.853 | 8.19% | +2.47% | 25.60% | Crosses above 22.0% baseline PAYE while eroding >90% of the generational welfare gain. |
| **Age 72** | 24.34% | 34.10% | 1.851 | 9.34% | -2.44% | 26.28% | Severe pension confiscation + sandwich drag pulls long-run household welfare negative (-2.44% CE). |
| **Age 73** | 25.72% | 36.39% | 1.849 | 10.52% | -7.57% | 27.05% | Compounding morbidity and benefit substitution drive required PAYE above 25.7%. |
| **Age 74** | 27.18% | 38.99% | 1.848 | 11.73% | -12.90% | 27.89% | Approaches Status Quo LTFM tax cliff while confiscating 9 years of retirement. |
| **Age 75** | **28.73%** | 41.89% | 1.847 | 12.95% | -18.42% | 28.82% | Total collapse of intergenerational *whānau* scaffolding and geriatric safety-net overload (+6.73 pp tax hike). |

### 
#### 3.4.8 Cohort Distribution Drift and Transience Haircuts Across the 4-Region + Abroad Framework (`Dunedin_22` vs. `MetroSqueeze_GUiNZ`)

Let $`s_1 = (a_1, h_1, \theta_c, z, k)`$ denote the initial household state vector at Gate 1 (ages 0–5) across the four domestic regions $`k \in \lbrace 1, 2, 3, 4 \rbrace`$ (`Rural`, `Small`, `Large`, `Auckland`), with dimension *k* = 5 denoting `Abroad`. Under Stone–Geary non-homothetic preferences with regional housing subsistence requirement $`p_{H,k}(j)\bar{h}`$ and mandatory transport/energy floor $`\bar{e}_k`$, private parental cash enrichment $`i_c^\star(s_1, t)`$ satisfies the Kuhn–Tucker condition:

$$
i_c^\star(s_1, t) = \max\left\lbrace 0, \theta_c \left[ y_{\mathrm{disp},k}(s_1) + T_k(t) - p_{H,k}(t)\bar{h} - \bar{e}_{k}(t) - \bar{g}_{\mathrm{ECE}} \right] \right\rbrace
$$

Define the critical disposable-income boundary:

$$
\tilde{y}_{1,k}(t) \equiv \bar{g}_{\mathrm{ECE}} + p_{H,k}(t)\bar{h} + \bar{e}_k(t) - T_k(t)
$$

Between the 1972–1973 Dunedin baseline (*t* = 1972, `Dunedin_22`) and the 2009–2010 *Growing Up in New Zealand* baseline (*t* = 2010, `MetroSqueeze_GUiNZ`), the reduction in unconditional family transfers and the appreciation of untaxed metropolitan land ($`Q_{\mathrm{Auckland}} = 3.10\times`$ versus $`1.20\times`$ in 1972) shifted $`\tilde{y}_{1,k}(t)`$ upward, expanding the struggling launch trajectory ($`h_1\text{--}h_2`$) from 22.0% to 28.5% nationally (and 34.0%–36.6% in Auckland):

$$
\Pr_{1972}^{\mathrm{Dunedin}}\left(h_{\mathrm{launch}} \in \lbrace h_1, h_2 \rbrace\right) = \sum_{k=1}^{4} \omega_k \int_{y_{1,k} \le \tilde{y}_{1,k}(1972)} d\mu_{1972}(s_1 \mid k) = 0.220
$$

$$
\Pr_{2010}^{\mathrm{GUiNZ}}\left(h_{\mathrm{launch}} \in \lbrace h_1, h_2 \rbrace\right) = \sum_{k=1}^{4} \omega_k \int_{y_{1,k} \le \tilde{y}_{1,k}(2010)} d\mu_{2010}(s_1 \mid k) = 0.285
$$

Let $`\nu_k(a_1, Q_k) \in [0, 1]`$ denote the forced residential relocation rate prior to age 5 in private rental tenure ($`>45\%`$ in `GUiNZ`). Residential churn erodes early skill retention by $`(1 - \zeta \nu_k)`$ entering the Stage-2 school-age CES technology ($`\varphi_2 = -0.95 < 0`$). Because Stage-2 inputs exhibit strong Cunha–Heckman dynamic complementarity ($`\sigma_2 = \frac{1}{1 - \varphi_2} = 0.51 < 1`$), the cross-partial derivatives of expected adult skill readiness with respect to universal in-kind wraparound $`G_{\mathrm{ECE},1}`$ and the struggling corner share $`\Pr(i_c^\star = 0)`$ as well as tenure stabilization ($`-\nu_k`$) are strictly positive:

$$
\frac{\partial^2 \mathbb{E}[\theta'_c]}{\partial G_{\mathrm{ECE},1} \partial \Pr(i_c^\star = 0)} > 0 \quad \text{and} \quad \frac{\partial^2 \mathbb{E}[\theta'_c]}{\partial G_{\mathrm{ECE},1} \partial (-\nu_k)} > 0
$$

Consequently, evaluating the unbuffered $`SS0`$ fiscal remediation functional across Exits 1, 2, and 4 under the `MetroSqueeze_GUiNZ` stationary measure yields an additional **+NZD 10.8B/yr** in projected 2050 structural drag (**NZD 17.7B/yr** → **NZD 28.5B/yr**), while increasing the Year-5 ACC actuarial return multiple of the integrated reform package in `Table 16` from **3.84x** (**NZD 35.25B**) to **4.26x** (**NZD 39.14B**, or **4.45x** including full transience recovery):

$$
\Delta \mathcal{D}_{\mathrm{GUiNZ}} = \sum_{k=1}^{4} \sum_{x \in \lbrace 1,2,4 \rbrace} \int_{\mathcal{S}} C_x(s) d\left(\mu_{2010}^{\mathrm{GUiNZ}}(s \mid k) - \mu_{1972}^{\mathrm{Dunedin}}(s \mid k)\right) = +\mathrm{NZD}\ 10.8\mathrm{B/yr}
$$

Finally, note that in `SS1` and `SS2`, the critical disposable-income boundary $`\tilde{y}_{1,k}(t) \equiv \bar{g}_{\mathrm{ECE}} + p_{H,k}(t)\bar{h} + \bar{e}_k(t) - T_k(t)`$ is relaxed from both sides: while universal in-kind wraparound $`G_{\mathrm{ECE},1}`$ and land-tax housing cooling ($`\Delta p_{H,k} < 0`$) relieve metropolitan rent stress in `Auckland` and `Large` cities, deploying a share of the 50% Public Infrastructure Reinvestment Pool ($`\Omega_{\mathrm{reinv}}`$) into distributed household and community electrification—rooftop solar, community microgrids, and rural EV/public-transit charging, which Rewiring Aotearoa (`[Ref 46]`, Ellison, Casey, & Griffith, 2024/2026) shows reduces household energy and transport outlays by NZD 7,600/yr gross (NZD 3,000/yr net of financing, or NZD 12.9B/yr nationally)—permanently compresses the mandatory energy and transport subsistence floor $`\bar{e}_k(t)`$ in `Rural` ($`0.048 \downarrow`$) and `Small` ($`0.036 \downarrow`$) provincial regions, accelerating household exit from the $`i_c^\star = 0`$ corner across all four domestic geographies. We leave it as an exercise for the reader as to whether it is prudent to wait 20 years to accomplish energy transition with newfound capital created from widespread economic efficiencies and complementarities, or whether energy transition is, in fact, a key enabling strategy to accelerate and better afford all the benefits of `SS1` in the first place.

---

## 4. Part IV Cross-Reference: Core Model Output Tables (Tables 1 to 17)

### 4.1 Table 1: Multiphase 4-Region Daruich (2018) & Lee-Seshadri (2019) Welfare Decomposition ($`SS0 \to SS1 \to SS2`$)

*Source Files:* [`Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv`](Output_NZ_4Region_Intergen/Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv) *(Generated by `WelfareDecomposition_4Region.m` with `Active_Phases = {'SS0', 'SS1', 'SS2'}`)* and cohort transition trajectory [`Table_Trans1_Daruich_Cohort_Welfare_4Region.csv`](Output_NZ_4Region_Intergen/Table_Trans1_Daruich_Cohort_Welfare_4Region.csv) *(Generated by `TransPath_4Region_Master.m`; Figure: `Fig1_Daruich_Cohort_Welfare_4Region.png`)*

<img src="./Output_NZ_4Region_Intergen/Fig1_Daruich_Cohort_Welfare_4Region.png" alt="Cohort Welfare Transition Path Across 4 Regions" width="68%" style="display: block; width: 68%; margin: 1.2rem auto; break-inside: avoid; page-break-inside: avoid;" />

* **Jump 1 (*c* = 0, Phase 1 *SS1* Launch):** Immediate surge in incoming cohort welfare driven by universal First-2,000-Days wraparound ($`G_{\mathrm{ece},1} = 0.110`$), Montessori / *Tuakana–Teina* & Graeme Dingle adolescent mentoring ($`G_{\mathrm{ece},2} = 0.085`$), the age-20 Youth Capital Grant ($E = 0.065$), and Guvenen et al. firm capital reallocation.
* **Jump 2 (*c* = +25, Phase 2 *SS2* Harvest):** Second structural leap 20–25 years into the transition when the children of the first reformed cohort enter parenthood with thriving human capital ($`\mu_1^{SS2}`$) and the Crown activates the **2050 50/50 Debt-Sinking and Infrastructure Protocol** alongside **lowering universal NZ Superannuation to Age 64** (+8.1% *Kuia / Whānau* boost) and the **-3.75 percentage-point working-age PAYE tax cut** (22.00% down to 18.25%, including -0.64 pp from retiring 85% of the SS1 geographic transfer as regional $z_l \to z_h$ enterprises mature).

| **Row Label (`T1`)** | **Rural_CE_Pct** | **Small_CE_Pct** | **Large_CE_Pct** | **Auckland_CE_Pct** | **National_CE_Pct** | **Share of Phase Gain from Endogenous Intergenerational Matrix** |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **`SS1_1_ShortRun_PE`** | **+2.02%** (`2.0163`) | **+2.15%** (`2.1464`) | **+2.51%** (`2.5056`) | **+3.21%** (`3.2097`) | **+2.58%** (`2.5812`) | Direct policy levers ($G_{\mathrm{ece},1} = 0.110$, $G_{\mathrm{ece},2} = 0.085$, $E = 0.065$, `Transfer_Geo`) at fixed *SS0* prices & $\mu_1$ |
| **`SS1_2_LongRun_GE_ExoSkills`** | **+6.23%** (`6.2319`) | **+6.28%** (`6.2786`) | **+6.77%** (`6.7684`) | **+7.71%** (`7.7093`) | **+6.89%** (`6.8858`) | Guvenen firm reallocation ($w_k \uparrow$) + regional $z_l \to z_h$ procurement lift ($1.60\times$--$2.16\times$) + housing cooling ($Q_{\mathrm{Akl}} -7.5\%$) at fixed $\mu_1^{\mathrm{SS0}}$ |
| **`SS1_3_LongRun_GE_EndoIntergen`** | **+11.95%** (`11.945`) | **+13.74%** (`13.739`) | **+14.89%** (`14.888`) | **+17.52%** (`17.515`) | **+15.04%** (`15.037`) | **47.8% (`Rural`), 54.3% (`Small`), 54.5% (`Large`), 56.0% (`Auckland`)** from $\mu_1^{\mathrm{SS1}}$ shift |
| **`SS2_1_ShortRun_PE`** | **+5.64%** (`5.6376`) | **+5.82%** (`5.8241`) | **+6.26%** (`6.2614`) | **+6.93%** (`6.9250`) | **+6.28%** (`6.2829`) | Retires 85% of SS1 `Transfer_Geo` top-up to fund **-3.75 pp PAYE tax cut** ($\tau_l: 22.0\% \to 18.25\%$), Super Age 64, $G_{\mathrm{ece},1} = 0.130$, $G_{\mathrm{ece},2} = 0.105$, $E = 0.080$ |
| **`SS2_2_LongRun_GE_ExoSkills`** | **+12.70%** (`12.700`) | **+12.91%** (`12.907`) | **+13.61%** (`13.606`) | **+14.59%** (`14.588`) | **+13.63%** (`13.628`) | Adds 2050 Debt-Sinking ($\Delta r = -0.006$), mature $z_l \to z_h$ regional enterprise upgrading (+4.1% Rural), 1.65x infra wage lift, $Q_{\mathrm{Akl}} -10.5\%$ |
| **`SS2_3_LongRun_GE_EndoIntergen`** | **+20.63%** (`20.628`) | **+22.98%** (`22.984`) | **+24.57%** (`24.574`) | **+27.91%** (`27.913`) | **+24.70%** (`24.699`) | **44.8% of Total National `SS2` Gain (+11.07% out of +24.70%)** stems from $\mu_1^{\mathrm{SS2}}$ dynastic & *Kuia/Whānau* compounding |

### 
| **Wealth Quintile** | **Rural_CE_Pct** | **Small_CE_Pct** | **Large_CE_Pct** | **Auckland_CE_Pct** | **National_CE_Pct** | **Primary Mechanism Driving Quintile Payoff** |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **`Q1_Bottom20`** *(Hardship Renters)* | **+29.91%** (`29.911`) | **+33.33%** (`33.326`) | **+35.63%** (`35.633`) | **+40.47%** (`40.473`) | **+35.81%** | Elimination of $i_c = 0$ corner (`a < 0.12*Q_k`) via $G_{\mathrm{ECE}}$, SS1 `Transfer_Geo` bridge, Youth Grant $E$, & rent relief |
| **`Q2_20to40`** | **+25.17%** (`25.166`) | **+28.04%** (`28.040`) | **+29.98%** (`29.980`) | **+34.05%** (`34.053`) | **+30.13%** | Montessori / *Tuakana–Teina* mentoring + regional $z_l \to z_h$ job upgrading + lower metropolitan rental user cost $r_{h,k}, r_{r,k}$ |
| **`Q3_Middle20`** | **+21.04%** (`21.041`) | **+23.44%** (`23.443`) | **+25.07%** (`25.066`) | **+28.47%** (`28.471`) | **+25.19%** | Wage lift ($w_k \uparrow$) + accelerated homeownership entry ($\xi_k \uparrow$) + **-3.75 pp `SS2` PAYE cut** |
| **`Q4_60to80`** | **+16.91%** (`16.915`) | **+18.85%** (`18.847`) | **+20.15%** (`20.151`) | **+22.89%** (`22.888`) | **+20.25%** | Higher enterprise equity returns & child skill compounding outweigh modest property cooling |
| **`Q5_Top20`** *(Property/Business Owners)* | **+11.96%** (`11.964`) | **+13.33%** (`13.330`) | **+14.25%** (`14.253`) | **+16.19%** (`16.189`) | **+14.33%** | High-$z_{h,k}$ firm reallocation + relational utility $u_{\mathrm{rel}}$ (children retained in NZ) offset $\tau_b$ |

### 
### 4.3 Table 3 & Table 3B: Kiyotaki et al. (2024) Housing Tenure Cleavage & Steady-State Summary

*Source Files:* [`Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv`](Output_NZ_4Region_Intergen/Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv), [`Table3B_4Region_Abroad_SteadyState_Summary.csv`](Output_NZ_4Region_Intergen/Table3B_4Region_Abroad_SteadyState_Summary.csv), and 60-year transition path [`Table_Trans2_Kiyotaki_Housing_PopShares_4Region.csv`](Output_NZ_4Region_Intergen/Table_Trans2_Kiyotaki_Housing_PopShares_4Region.csv) / [`Table9_4Region_Dynamic_Population_Shares.csv`](Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv) *(Figure: `Fig2_Kiyotaki_Housing_Estates_4Region.png`)*

<img src="./Output_NZ_4Region_Intergen/Fig2_Kiyotaki_Housing_Estates_4Region.png" alt="Housing Prices, Homeownership, and Estate Flows" width="92%" style="display: block; width: 92%; margin: 1.0rem auto; break-inside: avoid; page-break-inside: avoid;" />

| **Tenure / Generation Group (`T3`)** | **Rural_CE_Pct** | **Small_CE_Pct** | **Large_CE_Pct** | **Auckland_CE_Pct** | **National_CE_Pct** | **Regional House Price $Q_k$ (`SS0 -> SS1 -> SS2`) & Young Ownership ($\xi_k$)** |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **`1_Young_Renters_20to44`** | **+28.47%** (`28.467`) | **+31.72%** (`31.717`) | **+33.91%** (`33.912`) | **+38.52%** (`38.520`) | **+34.09%** | $Q_{\mathrm{Rural}}: 1.05 \to 1.04 \to 1.03$; Young ownership: `58.0


+-----------------------------------------------------------------------------------+
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                       [ THIS SPACE INTENTIONALLY LEFT BLANK ]                     |
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

---

### 4.4 Tables 4, 5, & 6 (and 12A–12C): Lee & Seshadri (2019) Multi-Stage Counterfactuals
*Source Files:* [`Table4_4Region_LeeSeshadri_IGE.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table4_4Region_LeeSeshadri_IGE.csv), [`Table5_4Region_LeeSeshadri_Output_Welfare.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table5_4Region_LeeSeshadri_Output_Welfare.csv), and [`Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv) *(Figure: `FigE8_LeeSeshadri_4Region_Counterfactuals.png`)*

<img src="./Output_NZ_4Region_Intergen/FigE8_LeeSeshadri_4Region_Counterfactuals.png" alt="Lee-Seshadri 4-Region Counterfactuals" width="68%" style="display: block; width: 68%; margin: 1.0rem auto; break-inside: avoid; page-break-inside: avoid;" />

| Counterfactual Regime | National Long-Run IGE | `Auckland` Long-Run IGE | Variance of LFE Explained at Age 20 (`Nat.` / `Auckland`) | Long-Run Output $`\Delta \bar{E}_{\mathrm{LR}}`$ (`Rural` / `Auckland`) | Long-Run Welfare `CE_LR` (`Rural` / `Auckland`) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline`** (`SS0`) | `0.350` (`0.441` unadj.) | `0.497` | **64.3% Nat.** / `71.74%` Akl (`46.77%` by $`h_1`$) | `0.00%` / `0.00%` | `0.00%` / `0.00%` |
| **`P0_Early_0to5`** *(First 2000 Days)* | **`0.233` (-33.4%)** | `0.489` | `51.2%` Nat. / `71.31%` Akl | `+1.81%` / `+1.10%` | `+1.42%` / `+0.68%` (Stage-1 alone) |
| **`P1P2_Late_6to17`** *(Late School Only)* | `0.338` (-3.4%) | `0.488` | `62.8%` Nat. / `70.82%` Akl | `+0.81%` / `+0.96%` | `+0.31%` / `+0.24%` (Fails to close struggling launch gap) |
| **`BN_FrontLoad`** *(Budget-Neutral)* | `0.281` (-19.7%) | `0.485` | `55.4%` Nat. / `69.85%` (`Large`) | `+0.26%` (`Small`) | `+0.21%` (`Large`, zero net fiscal cost) |
| **`P0_Plus_GrantE`** *(Full Package)* | **`0.218` (-37.7%)** | **`0.482`** | **44.8% Nat.** / `68.11%` (`Small`) | **`+7.08%` / `+5.08%`** | **`+12.7%` to `+15.8%` (Full GE)** |

<br clear="all" />

---

## 4.5 Table 17: Distributional Incidence Across 10 Survey-Anchored Earn + Own Tiers — Productive vs. Passive Asset Bifurcation and Balance-Sheet Resilience (`Plot_WealthBracket_GiveAndGain.m`)

*Source Script:* `Plot_WealthBracket_GiveAndGain.m`; *Output CSV:* `Table17_Survey10Tier_EarnOwn_Welfare_Dunedin_22.csv`; *Figures:* `Fig_WealthBrackets_2Panel_GiveAndGain_Dunedin_22.png`, `Fig_WealthBrackets_PanelA_GiveVsGain_Dunedin_22.png`, and `Fig_WealthBrackets_PanelB_WealthResilience_Dunedin_22.png`

Arguments for and against tax reform are often shallow, because they depend on "thin" numbers: a tax rate here or a percentage of capital flight there.  Our theoretical foundation admits a more substantial analysis that respects both the topography of the wealth terrain, and the willingness of its inhabitants to endure the exercise as both a worthy challenge and a worthwhile reward.  From these three papers we map the practical routes calibrated to New Zealand data.

### 4.5.1 Three-Elasticity Decomposition of Top Marginal Tax Rates
Following Piketty, Saez, and Stantcheva (2014), the total observed taxable income elasticity $`e_{\mathrm{total}}`$ with respect to the net-of-tax rate $`(1 - \tau_{\mathrm{top}})`$ decomposes into real productive supply ($`e_1`$), tax-base sheltering ($`e_2`$), and zero-sum compensation bargaining ($`e_3`$):

$$
e_{\mathrm{total}} = e_1 + e_2 + e_3
$$

When capital-gain and land shelters remain open ($`\tau_a = 0`$), reductions in $`\tau_{\mathrm{top}}`$ primarily stimulate rent-seeking bargaining ($`e_3 > 0`$) while the real productive elasticity remains small ($`e_1 \approx 0.15\text{–}0.25`$). The net fiscal revenue derivative is therefore strictly negative:

$$
\frac{d\mathcal{R}}{d(1 - \tau_{\mathrm{top}})} = Y_{\mathrm{top}} \left( e_1 - \frac{1 - \tau_{\mathrm{top}}}{\tau_{\mathrm{top}}} \right) < 0 \quad \text{for } e_1 \ll \frac{1 - \tau_{\mathrm{top}}}{\tau_{\mathrm{top}}}
$$

### 4.5.2 Return Heterogeneity Under Wealth-Stock vs. Capital-Income Taxation
In the 8-PType occupational-choice block (Guvenen et al., 2023; Murphy, Shleifer, & Vishny, 1991), agents possess heterogeneous entrepreneurial productivity $`z_h`$ versus passive land-holding return $`z_\ell (\dot{P}_L / P_L)`$. Introducing a book-value wealth/land tax *τ_a* = 0.015 (1.5%) paired with lower taxes on active earnings ($`\Delta \tau_k < 0, \Delta \tau_l < 0`$) yields the after-tax return schedule:

$$
r_{\mathrm{net}}(z, \tau_a, \tau_k) = (1 - \tau_k) z_h k^{\alpha - 1} + z_\ell \left( \frac{\dot{P}_L}{P_L} \right) - \tau_a
$$

Differentiating the stationary asset cutoff $`A^\star(\tau_a)`$ confirms that wealth-stock taxation compresses speculative land hoarding ($`\partial A^\star(z_\ell) / \partial \tau_a < 0`$) and expands the stationary measure of high-productivity builders ($`\Delta \mu^\star(z_h) > 0`$), reducing equilibrium metropolitan housing prices *Q_k* by $`10.5\%`$ and curtailing outbound graduate migration to the `Abroad` state (*k* = 5):

$$
V_{20,k}^{\mathrm{Domestic}}(a_{20} + E, h_3) \ge V_{20,5}^{\mathrm{Abroad}}(a_{20}, h_3) - \kappa_{\mathrm{mig}} \quad \forall k \in \{1, 2, 3, 4\}
$$

### 4.5.3 Parental Developmental Time Crowd-Out Under High Abatement

Consider a liquidity-constrained Gate 1 household subject to benefit abatement rate $`\tau_{\mathrm{abate}} \in [0.70, 0.90]`$ that increases low-wage labor supply by $`\Delta \ell_{\mathrm{coerced}} > 0`$, inducing a one-for-one reduction in parental developmental time $`\Delta \ell_{\mathrm{child}} = -\Delta \ell_{\mathrm{coerced}} < 0`$. Differentiating Stage-1 skill $`\theta'_c`$ with respect to coerced labor hours yields:

$$
\frac{d \theta'_c}{d \ell_{\mathrm{coerced}}} = \frac{\partial \theta'_c}{\partial I_{\mathrm{tot},1}} \left[ \mathbb{I}(i_c^\star > 0) w_{\min}(1 - \tau_{\mathrm{abate}}) - \gamma_{1,\mathrm{par}} w_k h_p \right] < 0
$$

At or near the Stone–Geary corner ($`\mathbb{I}(i_c^\star > 0) = 0`$), the marginal cash term vanishes while the loss of parental care time $`-\gamma_{1,\mathrm{par}} w_k h_p`$ strictly degrades early skill formation $`\theta'_c`$.

### 4.5.4 Empirical Mapping Across the 10 Survey-Anchored Benchmarks

For each tier $`m \in \{1, \dots, 10\}`$, total Consumption-Equivalent welfare change ($`\Delta\mathrm{CE}_m`$) is decomposed into **3 Tax & Valuation-Cooling Channels** (House-price cooling $`\Delta Q_k`$, the annual book-value land/wealth levy *τ_a* = 0.015 (1.5%) above the family-home exemption, and the Estate levy $`\tau_b`$) and **4 Economic & Cohesion Gain Channels** (ECE/Rent relief + Youth Grant *E*, the **-3.75 to -4.03 pp *SS2* PAYE cut** + **-60 bps** credit relief, the Firm productive return boost $`\Delta R_k(z_{h,k})`$, and the Social Cohesion / retained-family dividend $`\Delta u_{\mathrm{rel}}`$), reporting separate trajectories for **Active Growth Entrepreneurs** ($`z_f = z_{h,k}`$, 80% operating equity share) versus **Passive Residential Land Hoarders** ($`z_f = z_{\ell,k}`$, 85% passive property share):

![Fiscal Give vs Economic Gain and Net Worth Resilience Across 10 Survey-Anchored Tiers](Output_NZ_4Region_Intergen/Fig_WealthBrackets_2Panel_GiveAndGain_Dunedin_22.png)

| Survey Tier (`Table17_Survey10Tier_*`) | `Income + Net Worth` | Tax & Cooling (`H+W+E`) | Economic & Cohesion Gain (`ECE+Tax+Firm+S`) | **Tier Avg (CE %)** | **Active** ($`z_{h,k}`$) vs. **Passive** ($`z_{\ell,k}`$) | **Post-Reform Retained Net Worth (`% Base`)** | **After-Tax Cash (`/yr`)** |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. `Q1` Renter** *(P12)* | **`45k + 12k`** | 0.0% | +25.4% | **+25.4%** | **+25.4%** / **+25.4%** | **NZD 74k** *(Seeds deposit)* | NZD 46.8k |
| **2. `Q2` Young Saver** *(P35)* | **`85k + 115k`** | -0.3% | +19.4% | **+19.1%** | **+19.1%** / **+19.1%** | **NZD 166k** *(144.3%)* | NZD 78.5k |
| **3. Median Income** *(P50 Inc)* | **`120k + 340k`** | -0.9% | +16.1% | **+15.2%** | **+15.6%** / **+14.3%** | **NZD 382k** *(112.4%)* | NZD 106.2k |
| **4. Median Net Worth** *(P50 NW)* | **`135k + 530k`** | -1.6% | +13.0% | **+11.4%** | **+12.4%** / **+9.6%** | **NZD 573k** *(108.1%)* | NZD 118.4k |
| **5. Top 10% (`P90`)** | **`240k + 2.15M`** | -5.1% | +8.7% | **+3.6%** | **+6.4%** / **+0.4%** | **NZD 2.12M** *(98.6%)* | NZD 198.0k |
| **6. Top 5% (`P95`)** | **`310k + 3.10M`** | -6.9% | +8.3% | **+1.4%** | **+5.2%** / **-2.7%** | **NZD 2.99M** *(96.5%)* | NZD 248.5k |
| **7. Top 2% (`P98`)** | **`450k + 5.20M`** | -8.6% | +8.7% | **+0.1%** | **+4.3%** / **-4.4%** | **NZD 4.96M** *(95.4%)* | NZD 349.0k |
| **8. Top 1% (`P99`)** | **`600k + 8.50M`** | -10.3% | +9.2% | **-1.1%** | **+3.6%** / **-6.2%** | **NZD 8.04M** *(94.6% / **98.5%** act.)* | **NZD 455.0k** |
| **9. IRD HW Median** *(P99.9)* | **`2.1M + 50M`** | -13.2% | +9.1% | **-4.1%** | **+1.2%** / **-9.7%** | **NZD 45.85M** *(91.7% / **96.4%** act.)* | **NZD 1.52M** |
| **10. NBR Rich List** *(P99.99)* | **`6.5M + 140M`** | -14.7% | +8.8% | **-5.9%** | **-0.1%** / **-11.2%** | **NZD 126.3M** *(90.2% / **95.3%** act.)* | **NZD 4.62M** |

<br clear="all" />

Across the bottom 90% of households (`Tiers 1–5`), net welfare gains are unconditionally positive (+3.6% to +25.4% CE), and through the 98th percentile (`Tier 7`) the tier-average impact remains positive (+0.1% CE), with active enterprise builders remaining net positive through `Tier 9` (NZD 50M, +1.2% CE) and breaking even at `Tier 10` (NZD 140M, -0.1% CE). For passive property-heavy portfolios in the top 1% (`Tiers 8–10`), the net balance-sheet adjustment (retaining 90.2% to 94.6% of baseline net worth on a portfolio-average basis) is smaller than a single routine once-a-decade macroeconomic drawdown—of which New Zealand has experienced six over the past sixty years.

**Sensitivity of the NZD 1.6T Estate & Net Wealth Base to Marginal Exemption Thresholds:** Because New Zealand private wealth is heavily right-skewed across Tiers 1–10 (median net worth NZD 530k vs. P90 at NZD 2.15M, P99 at NZD 8.50M, and P99.9 at NZD 50M), applying a marginal primary-residence / family-estate exemption completely insulates modest provincial and suburban homeowners (such as a NZD 250k–500k home in Masterton) while preserving the vast majority of the revenue base:
  - **NZD 250k Provincial Home Exemption:** Exempts **39.2%** of all households/estates 100%, retains **86.5% (NZD 1,385B)** of the NZD 1.6T transfer base, and yields **NZD 8.65B/yr** from the 25% estate levy plus **NZD 33.7B/yr** from the 1.5% wealth levy.
  - **NZD 500k Median Home Exemption:** Exempts **48.7%** of households 100%, retains **75.7% (NZD 1,211B)** of the base, and yields **NZD 7.57B/yr** (estate) plus **NZD 29.5B/yr** (wealth).
  - **NZD 1.0M Metro Family Home Exemption (Canonical Model Threshold):** Exempts **61.6%** of all households 100% and taxes a NZD 1.2M urban home on only its top NZD 200k, yet retains **58.5% (NZD 937B)** of the base—yielding **NZD 5.85B/yr** from the estate levy (fully self-funding a **NZD 60k–97.6k** universal Youth Capital Grant at Age 20) plus **NZD 22.8B/yr** from the 1.5% levy (with deferred payment at sale or estate settlement for cash-poor retirees).
  - **NZD 2.5M Family Farm / P92 Exemption & NZD 5.0M Large Farm / P98 Exemption:** Even at NZD 2.5M (exempting **91.8%** of households) or NZD 5.0M (exempting **97.7%**), the top tail retains **34.7% (NZD 555B)** to **26.3% (NZD 421B)** of the base, while working family farms classified as active operating enterprises ($`z_h`$) are doubly protected by lower enterprise tax drag and $`-60\text{ bps}`$ credit relief. By contrast, single-lane tax proposals that either exempt 99.1%+ of households plus uncapped family mansions while hiking corporate tax to 33%, or tax only post-2027 realised property appreciation while exempting all inheritances, fall **55% to 94% short** of the $`SS_1`$ and $`SS_2`$ fiscal and mobility targets.

---

### 4.6 Tables 9 & 10: Dynamic Regional Population Shares & Three-Wave Brain-Drain Closure (60-Year Path)

*Source Files:* [`Table9_4Region_Dynamic_Population_Shares.csv`](Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv) (dual-aliased as [`Table_Trans2_Kiyotaki_Housing_PopShares_4Region.csv`](Output_NZ_4Region_Intergen/Table_Trans2_Kiyotaki_Housing_PopShares_4Region.csv) matching `Fig2_Kiyotaki_Housing_Estates_4Region.png`) and [`Table10_4Region_Abroad_BrainDrain_Cohesion.csv`](Output_NZ_4Region_Intergen/Table10_4Region_Abroad_BrainDrain_Cohesion.csv) (dual-aliased as [`Table_Trans3_BrainDrain_Cohesion_4Region.csv`](Output_NZ_4Region_Intergen/Table_Trans3_BrainDrain_Cohesion_4Region.csv) matching `Fig3_BrainDrain_Cohesion_4Region.png`; generated by `TransPath_4Region_Master.m` and `Run_All_NZ_Intergen_Suite.m`)

<img src="./Output_NZ_4Region_Intergen/Fig3_BrainDrain_Cohesion_4Region.png" alt="Brain Drain Closure and Social Cohesion Recovery" align="right" width="54%" style="float: right; width: 54%; margin: 0 0 1rem 1.5rem; break-inside: avoid; page-break-inside: avoid;" />

* **Retaining ~3,550 Skilled Young Kiwis Per Year:** Cutting outward emigration of 20-to-35-year-olds from **23.41% to 18.26%** in Large regional cities, **19.29% to 14.92%** in Auckland, and **10.93% to 8.56%** (`SS1`) / **7.60%** (`SS2`) nationally retains roughly **3,550 additional skilled young adults per year** inside New Zealand's workforce and creative communities.
* **Restoring Social Cohesion:** Lower emigration and reduced replacement-migration churn lift the national **Social Cohesion Index ($`S_t`$)** from **100.0 in `SS0` to 112.0–118.4 in `SS1` and 126.0 in `SS2`**.

<br clear="all" />

| Transition Year | `PopPct_Rural` | `PopPct_Small` | `PopPct_Large` | `PopPct_Auckland` | `Emig_Large_Pct` | `Emig_Auckland_Pct` | `Nat_Emig_Abroad_Pct` | `Social_Cohesion_Index_St` (`SS1` / `SS2`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Year 0 (2026 Base)** | 16.00% | 24.00% | 25.90% | 34.10% | 23.41% | 19.29% (`7.02%` net) | 10.93% | 100.0 (`104.3`) |
| **Year 6 ($`t = 2`$)** | 15.62% | 23.68% | 26.04% | 34.66% | 21.55% | 17.65% (`6.46%` net) | 10.07% | 104.8 |
| **Year 15 ($`t = 5`$)** | 15.18% | 23.29% | 26.21% | 35.32% | 19.70% | 16.12% (`5.91%` net) | 9.22% | 108.5 |
| **Year 24 ($`t = 8`$)** | 14.85% | 22.98% | 26.35% | 35.82% | 18.92% | 15.48% (`5.67%` net) | 8.86% | **112.0 (`SS1`)** |
| **Year 36 ($`t = 12`$)** | 14.58% | 22.74% | 26.46% | 36.22% | 18.61% | 15.21% (`5.58%` net) | 8.72% | 119.5 |
| **Year 57 ($`t = 19`$)** | **14.39%** | **22.56%** | **26.54%** | **36.51%** | **18.26%** | **14.92% (`5.47%` net)** | **8.56%** (`7.60%` `SS2`) | **126.0 (`SS2`)** |


```text
+-----------------------------------------------------------------------------------+
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                       [ THIS SPACE INTENTIONALLY LEFT BLANK ]                     |
|                                                                                   |
|                                                                                   |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

---

## 4.7 Tables 7, 8, & 8B: Cooperative Childcare Bargaining, Extended *Whānau* Scaffolding, & The NZ Superannuation Retirement-Age U-Curve (Ages 60 to 75)

*Source Files:* [`Table7_4Region_Fertility_Bargaining_TFR.csv`](Output_NZ_4Region_Intergen/Table7_4Region_Fertility_Bargaining_TFR.csv), [`Table8_4Region_Fertility_Struggling_NZSuperTax.csv`](Output_NZ_4Region_Intergen/Table8_4Region_Fertility_Struggling_NZSuperTax.csv), and `Table8B_SuperAge_UCurve_60to75.csv` *(Script: [`FertilityBargaining_Module.m`](FertilityBargaining_Module.m); Figure: [`FigFert_4Region_Bargaining_Solvency.png`](Output_NZ_4Region_Intergen/FigFert_4Region_Bargaining_Solvency.png))*

![4-Region Fertility Bargaining, Whanau Networks & The NZ Super Retirement-Age U-Curve](Output_NZ_4Region_Intergen/FigFert_4Region_Bargaining_Solvency.png)

---

### Table 4.7A: Six Benchmark Fertility, Differential Fertility, Struggling Launch Share, & PAYE Solvency Regimes (`Tables 7 & 8`)

| Scenario Row (`T_Fert1` & `T_Fert2`) | TFR (`Rural` / `Small` / `Large` / `Auckland`) | Diff. Fertility Gap (`Large` / `Auckland`) | Struggling Cohort Share (`Rural` / `Small` / `Large` / `Auckland`) | Effective Fiscal Dep. Ratio (%) | Required Working-Age PAYE Tax $`\tau_l`$ (%) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **1. Baseline Status Quo (Age 65)** | `1.90` / `1.85` / `1.60` / `1.47` *(Nat: 1.66)* | `0.28` / `0.27` | `19.8%` / `18.2%` / `15.6%` / `14.3%` *(Mean: 17.0%)* | `31.78%` | **`23.60%`** *(+1.60 pp drift vs 22.0%)* |
| **2. Hyperbolic Delay ($`\beta=0.72`$, No ECE)** | `1.51` / `1.47` / `1.28` / `1.17` *(Nat: 1.32)* | `0.24` / `0.23` | `21.4%` / `20.0%` / `17.6%` / `16.4%` *(Mean: 18.8%)* | `41.44%` | **`25.99%`** *(+3.99 pp hike)* |
| **3. Barnardos ECE Bargaining Relief** | `1.94` / `1.92` / `1.66` / `1.53` *(Nat: 1.72)* | `0.17` / `0.16` | `6.3%` / `3.1%` / `2.2%` / `2.2%` *(Mean: 3.4%)* | `30.52%` | **`21.37%`** *(-0.63 pp cut)* |
| **4. Phase 1 (*SS1*) Full Package (Age 65)** | `2.06` / `2.03` / `1.78` / `1.64` *(Nat: 1.84)* | `0.18` / `0.17` | `5.8%` / `2.5%` / `2.2%` / `2.2%` *(Mean: 3.2%)* | `28.33%` | **`20.84%`** *(-1.16 pp surplus sinks debt)* |
| **5. Status Quo Austerity (Raise Super to 70)** | `1.86` / `1.82` / `1.58` / `1.45` *(Nat: 1.64)* | `0.30` / `0.28` | **`25.4%` / `23.2%` / `19.9%` / `18.0%`** *(Rises)* | `35.15%` | **`25.00%`** *(+3.00 pp hike; backfires)* |
| **6. ★ Phase 2 (*SS2*) Harvest (Lower Super to 64)** | **`2.09` / `2.06` / `1.81` / `1.67`** *(Nat: 1.87)* | **`0.16` / `0.16`** | **`3.0%` / `2.2%` / `2.2%` / `2.2%`** *(Mean: 2.4%)* | **`29.66%`** | **`18.25%` (-3.75 pp PAYE Cut)** |

*(For the complete year-by-year continuous Retirement-Age U-Curve from **Age 60 to Age 75** plotted in Panel D above, see **Section 3.4.7 / Table 8B**.)*

---

## 5. Part V Cross-Reference: The 2050 Debt-Sinking Protocol, Actuarial Continuation Valuation, & 11-Layer Constructive Synergy Attribution

### 5.1 The 2050 Sovereign Debt-Sinking & Public Reinvestment Protocol (`FiscalLedger.Protocol_2050_Summary`)
*Source Function:* `Build_Multiphase_2050_Protocol_Table` in `Plot_ChildFiscal_SSankey.m` (`Cohort_N = 60.0 * reg_pop_share` thousand births/yr, `r_gov_bond = 0.042`, `mu_infra_div = 1.65`, `Horizon_2050 = 25 yrs`). Under the 29-Node Solution 1 architecture, `Plot_ChildFiscal_SSankey.m` evaluates the consolidated annualized adult fiscal surplus at Gate 6 (`Good_Adult - Bad_Adult`, reaching **+27.0 to +28.0 kNZD/yr in SS1** and **+29.9 to +31.2 kNZD/yr in SS2** across the combined tax and capital-reallocation ledger), while the table below disaggregates the component human-capital lifecycle horizons at Age 30 versus Career-to-Retirement quoted in Document 1A Part V.1 under both `Dunedin_22` and `MetroSqueeze_GUiNZ`:

| Lifecycle Horizon & Phase | Good Taxes (`kNZD/yr`) | Exits 1,2,4 + Base Outlays (`kNZD/yr`) | Net Fiscal Balance $`\Omega_{\mathrm{fiscal}}`$ (`kNZD/yr`) | 50% Debt-Sinking Allocation $`\Omega_{\mathrm{debt}}`$ (`kNZD/yr`) | Annual Interest Saved (`kNZD/yr`) | 50% Reinvestment Pool $`\Omega_{\mathrm{reinv}}`$ (`kNZD/yr`) | Societal Value at 1.65x (`kNZD/yr`) | 25-Yr Cumulative Sovereign Debt Retired & Infrastructure Capital per Wave |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **`Age30_SS0`** | 8.60 | 13.90 | **-5.30** | 0.00 | 0.00 | 0.00 | 0.00 | NZD 0B Debt / NZD 0B Infra |
| **`Age30_SS1`** *(Dunedin / Metro)* | 17.10–17.72 | 6.60 | **+10.50 to +11.12** | **5.25 to 5.56** | **0.22 to 0.23** | **5.25 to 5.56** | **8.66 to 9.17** | **NZD 13.66B–14.46B Debt** |
| **`Age30_SS2`** | 18.60 | 6.20 | **+12.40** | **6.20** | **0.26** | **6.20** | **10.23** | **NZD 16.13B Debt** |
| **`CareerRet_SS0`** | 10.10 | 12.50 | **-2.40** | 0.00 | 0.00 | 0.00 | 0.00 | NZD 0B Debt / NZD 0B Infra |
| **`CareerRet_SS1`** *(Dunedin / Metro)* | 22.20–26.70 | 8.50 | **+13.70 to +18.20** | **6.85 to 9.10** | **0.29 to 0.38** | **6.85 to 9.10** | **11.30 to 15.01** | **NZD 17.50B–17.82B Debt / NZD 11.52B–12.16B Infra** |
| **`CareerRet_SS2`** | 24.80 | 8.00 | **+16.80** | **8.40** | **0.35** | **8.40** | **13.86** | **NZD 21.85B Debt / NZD 14.90B Infra** |

---

### 5.2 Cross-Reference of Actuarial Terminology, NZ Treasury Circular 2024/15 Rules, & Sibling Figures

* **Three Equivalent Institutional Names for the Forward Discounting Operator:**
  1. **Public Finance & NZ Treasury CBAx:** *Incidence-Based Lifetime Valuation* (or *Present Value of Future Incidence*), which books the discounted lifetime cost avoidance in the year a cohort verifiably exits hardship rather than waiting for annual cash flows to fall due over 40 years (evaluated at Treasury Circular 2024/15's **2.0% real SRTP central rate** and mandatory **8.0% real SOC commercial sensitivity rate**, net of a **30% attribution haircut** $`\alpha_{\mathrm{attr}} = 0.30`$).
  2. **Crown Balance Sheet Accounting (ACC / Social Investment Agency):** *Actuarial Liability Release* (or *Forward Liability Valuation*), directly analogous to the Accident Compensation Corporation (`ACC`) Outstanding Claims Liability (**NZD 63.6B** on the Crown balance sheet; *ACC Financial Condition Report 2025*, p. 17).
  3. **Dynamic Programming / OLG Markov Transition Suite:** *Conditional Continuation Valuation* $`\mathcal{V}_{k,t_0}^{(L)}(H)`$, evaluated on the solved sequence of transition distributions `StationaryDist_t` ($`\mu_{k,t}(a, h, z, j)`$) and firm equity distributions $`\Gamma_{k,t}(a_f, z_f)`$.

* **Canonical Sibling Figure Naming Convention (`Output_NZ_4Region_Intergen/`):**
  * **Combined 2-Panel Figure (Panel A Fiscal + Panel B Economy-Wide GDP):** `Fig_Actuarial_2Panel_<Region>_<Anchor>.png`
  * **Panel A Sibling (Crown Fiscal Ledger):** `Fig_Actuarial_Fiscal_<Region>_<Anchor>.png`
  * **Panel B Sibling (Economy-Wide GDP Lens):** `Fig_Actuarial_WideGDP_<Region>_<Anchor>.png`
  * **All-4-Region Spatial Dashboard & Year 5 Audit Bar Charts:** `Fig_Actuarial_Dashboard_All4_<Anchor>.png`, `Fig_Actuarial_Year5Audit_All4_<Anchor>.png`, `Fig_Actuarial_Year5Audit_Fiscal_All4_<Anchor>.png`, and `Fig_Actuarial_Year5Audit_WideGDP_All4_<Anchor>.png`

<img src="./Output_NZ_4Region_Intergen/Fig_Actuarial_2Panel_National_Dunedin_22.png" alt="National Crown Fiscal Ledger and Economy-Wide GDP Prize" width="98%" style="display: inline-block; width: 98%; vertical-align: middle; break-inside: avoid; page-break-inside: avoid;" />

---

### 5.3 Exact Conditional Continuation Equations Justifying the Findings

At transition period $`t_0`$ (in years, $`t_0 \in \{5, 10, \dots, 60\}`$), let $`\mathcal{C}_{k,\mathrm{realized}}^{(L)}(t_0)`$ denote the cumulative realized cash flow integrated via the trapezoidal rule (`cumtrapz`) from Year 0 to Year $`t_0`$ under lens $`L \in \{\mathrm{Sav}, \mathrm{Fiscal}, \mathrm{Econ}\}`$. Annual flows are interpolated onto a 1-year grid ($`y \in \{0, 1, \dots, 100\}`$) via piecewise cubic Hermite interpolation (`pchip`). The **Actuarial Continuation Valuation** $`\mathcal{V}_{k,t_0}^{(L)}(H)`$ over a rolling $`H = 25`$-year recognition window for region $`k \in \{\mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland}\}`$ is:

```math
\mathcal{V}_{k,t_0}^{(L)}(H; r_{\mathrm{disc}}) = \mathcal{C}_{k,\mathrm{realized}}^{(L)}(t_0) + (1 - \alpha_{\mathrm{attr}}) \Phi_{\mathrm{pipe}}(t_0) \sum_{s=1}^{H} \left(\frac{1 + g_{\mathrm{cost}}}{1 + r_{\mathrm{disc}}}\right)^s \psi_{k,\mathrm{persist}}^s \cdot \mathbb{E}_{t_0}\left[\Delta \mathrm{Flow}_{k, t_0+s}^{(L)} \middle| \mu_{k,t_0}\right]
```

and the national aggregate is obtained by exact spatial summation across the four regional ledgers:

```math
\mathcal{V}_{\mathrm{National},t_0}^{(L)}(H; r_{\mathrm{disc}}) = \sum_{k \in \{\mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland}\}} \mathcal{V}_{k,t_0}^{(L)}(H; r_{\mathrm{disc}})
```

where:
* $`\Phi_{\mathrm{pipe}}(t_0) = \min(1.0, t_0 / 15.0)`$ (`pipeline_maturity`) measures the fraction of the 0–15 childhood age pipeline that has completed or entered active treatment by year $`t_0`$ (reaching `1.0` at Year 15 when all childhood brackets are active).
* $`\psi_{k,\mathrm{persist}}^s`$ (`psi_persist`) is the region-specific Stage-2-to-Adulthood Markov skill-retention conditioning factor (`psi_base_map`: Rural = `0.984`, Small = `0.984`, Large = `0.986`, Auckland = `0.987`), reflecting the probability under $`\Pi_h(h' \mid h, i_{c,2})`$ and dynamic complementarity ($`\varphi_2 = -0.95`$) that a child exiting hardship at age 5 remains out of the struggling tier $`h_1`$–$`h_2`$ at age $`5 + s`$.

---

### 5.4 Year 5 Parliamentary Audit (*t* = 1) & Milestones Through Year 60 (`Table16_Actuarial_Continuation_Audit_Dunedin_22.csv`)

*Source Script:* `Plot_ActuarialContinuationValuation.m` *(Companion 2-Panel National Figure shown in Section 5.2 above; regional sibling plots exported as `Fig_Actuarial_2Panel_<Region>_<Anchor>.png`)*

Table 16 below disaggregates the Year 5 Parliamentary Audit (*t* = 1) across all four geographic tiers alongside the 15-, 20-, 40-, and 60-year national transition milestones under both the default `Dunedin_22` and `MetroSqueeze_GUiNZ` anchors. Notice that while every region achieves immediate direct cost-avoidance breakeven ($`>1.0\times`$ outlay) at Year 5, Auckland (`34.1%` of households, `35.1%` of firms) generates **40.0%** of the national economic prize (`NZD 34.17B` out of `NZD 85.40B` at 2.0% real) because the reform simultaneously relieves the nation's sharpest metropolitan rental squeeze ($`Q_{\text{Akl}} = 3.10`$) and unlocks its highest firm productivity ceiling ($`z_{h,\text{Akl}} = 1.75`$):

| Region / Transition Milestone (`Table16`) | Cumulative Public Investment Outlay | Wait-As-You-Go Cash Fiscal Return | Booked Direct Cost Avoidance Alone (2.0% Real) | Booked Total Fiscal Return (2.0% Central / 8.0% Sens.) | Realized Cash Cumulative GDP Gain | Booked Economy-Wide GDP Prize (2.0% Central / 8.0% Sens.) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Year 5 Audit: `Rural` (16.0% Pop / 15.0% Firm)** | NZD 1.42B | NZD 0.65B | **NZD 1.48B** | **NZD 4.61B / NZD 2.39B** | NZD 1.99B | **NZD 10.87B / NZD 6.13B** *(Yr 60: 196.4B / 270.3B)* |
| **Year 5 Audit: `Small` (24.0% Pop / 23.0% Firm)** | NZD 2.16B | NZD 1.04B | **NZD 2.33B** | **NZD 7.32B / NZD 3.79B** | NZD 3.17B | **NZD 17.31B / NZD 9.76B** *(Yr 60: 312.7B / 430.3B)* |
| **Year 5 Audit: `Large` (25.9% Pop / 26.9% Firm)** | NZD 2.38B | NZD 1.33B | **NZD 2.79B** | **NZD 9.43B / NZD 4.88B** | NZD 4.12B | **NZD 23.05B / NZD 12.96B** *(Yr 60: 406.4B / 568.7B)* |
| **Year 5 Audit: `Auckland` (34.1% Pop / 35.1% Firm)** | NZD 3.24B | NZD 1.95B | **NZD 4.06B** | **NZD 13.90B / NZD 7.18B** | **NZD 6.03B** | **NZD 34.17B / NZD 19.20B** *(Yr 60: 595.2B / 826.5B)* |
| **Year 5 Audit: `National` (`Dunedin_22`, 100%)** | **NZD 9.19B** | **NZD 4.98B** | **NZD 10.68B (1.16x)** | **NZD 35.25B (3.84x) / NZD 18.25B (1.99x)** | **NZD 15.30B** | **NZD 85.40B / NZD 48.05B** |
| **Year 5 Audit: `National` (`MetroSqueeze_GUiNZ`)** | **NZD 9.19B** | **NZD 5.14B** | **NZD 13.69B (1.49x)** | **NZD 39.14B (4.26x) / NZD 20.21B (2.20x)** | **NZD 15.30B** | **NZD 89.95B / NZD 50.18B** *(Yr 60: 1,634.5B / 2,270.3B)* |
| **Year 15 Full Pipeline (`National`, `Dunedin_22`)** | NZD 46.5B | NZD 38.0B | **NZD 68.1B** | **NZD 194.6B / NZD 113.1B** | NZD 114.3B | **NZD 439.2B / NZD 272.8B** |
| **Year 20 Launch (`National`, Cash Breakeven 18.8y)** | NZD 65.5B | NZD 70.1B | **NZD 91.9B** | **NZD 257.8B / NZD 163.7B** | NZD 192.7B | **NZD 576.1B / NZD 382.5B** *(Yr 25 Cash: NZD 117.3B)* |
| **Year 40 Estate Peak (`National`, `Dunedin_22`)** | NZD 142.4B | NZD 328.8B | **NZD 222.8B** | **NZD 587.8B / NZD 467.6B** | NZD 716.1B | **NZD 1,268.4B / NZD 1,010.8B** |
| **Year 60 Convergence (`National`, `Dunedin_22`)** | **NZD 220.1B** | **NZD 702.3B** | **NZD 372.2B** | **NZD 975.1B / NZD 850.5B** | **NZD 1,510.7B (6.86x)** | **NZD 2,095.8B / NZD 1,827.3B** |

---

### 5.5 Credibility-Weighted Belief Blending & Multiphase Policy Announcement Answer Key (`TransPath_4Region_Master.m`)

* **The Credibility Weight $`\lambda_{\mathrm{cred}}(t) \in [0, 1]`$ and Perceived Continuation Value $`\tilde{V}_{k,t+1}`$:** Let $`V_{k,t+1}^{\mathrm{perm,SS1}}`$ denote the backward-induction continuation value if agents believe Phase 1 (`SS1`) parameters remain frozen forever, and let $`V_{k,t+1}^{\mathrm{full,SS2}}`$ denote the continuation value under perfect foresight of the Phase 2 (`SS2`) **-3.75 pp PAYE tax-relief and infrastructure dividend** at transition seam $`T_1`$ (Year 25). At every transition period $`t < T_1`$, households and firms evaluate the credibility-weighted continuation value:

```math
\tilde{V}_{k,t+1}(a', h', z', j+1) = \bigl(1 - \lambda_{\mathrm{cred}}(t)\bigr) V_{k,t+1}^{\mathrm{perm,SS1}}(a', h', z', j+1) + \lambda_{\mathrm{cred}}(t) V_{k,t+1}^{\mathrm{full,SS2}}(a', h', z', j+1)
```

where the time-*t* credibility weight $`\lambda_{\mathrm{cred}}(t)`$ evolves between the announcement date $`t_{\mathrm{ann}}`$ and the Phase-2 enactment date $`T_1`$ according to:

```math
\lambda_{\mathrm{cred}}(t) = \begin{cases} 0 & \text{if } t < t_{\mathrm{ann}} \\ \bar{\lambda}_0 + (1 - \bar{\lambda}_0) \left(\dfrac{t - t_{\mathrm{ann}}}{T_1 - t_{\mathrm{ann}}}\right)^{\kappa_{\mathrm{cred}}} & \text{if } t_{\mathrm{ann}} \le t < T_1 \\ 1 & \text{if } t \ge T_1 \end{cases}
```

* **Three Nested Policy Announcement Regimes in `TransPath_4Region_Master.m`:**
  1. **Regime A — Unanticipated Sequential Reform (MIT Shock at $`T_1`$, $`\lambda_{\mathrm{cred}}(t) = 0`$ for $`t < T_1`$):** Agents solve Phase 1 believing `SS1` is permanent. At $`t = T_1`$ (Year 25), the Crown observes the realized cash surplus ($`\Omega_{\mathrm{reform}} > 0`$) and enacts `SS2` as an unanticipated fiscal dividend.
  2. **Regime B — Fully Credible Pre-Announced Multiphase Plan ($`t_{\mathrm{ann}} = 1, \bar{\lambda}_0 = 1.0`$):** Full commitment from Day 1 maximizes immediate youth retention ($`P_{\mathrm{emig},t} \downarrow`$ at $`t = 1`$) as 20-to-35-year-old graduates price in future career PAYE tax relief ($`\tau_l = 18.25\%`$).
  3. **Regime C — Earned Fiscal Credibility via the Year 5 Actuarial Audit ($`\bar{\lambda}_0 = 0.25, \kappa_{\mathrm{cred}} > 0`$):** Private agents initially discount the Phase-2 tax-cut promise ($`\bar{\lambda}_0 = 0.25`$). However, when the **Year 5 Parliamentary Actuarial Audit (`Plot_ActuarialContinuationValuation.m`)** verifies **NZD 35.25B** in recognised fiscal returns (**3.84x** cumulative outlays) and **NZD 10.68B** in direct cost avoidance alone (**1.16x**), $`\lambda_{\mathrm{cred}}(t)`$ surges upward—accelerating skilled youth retention (`Emig_Large_Pct`: `23.41%` down to `18.26%`; `Nat_Emig_Abroad_Pct`: `10.93%` down to `8.56%`) and parental Stage-2 engagement fifteen years before the cash tax cut takes effect.

```text
+-----------------------------------------------------------------------------------+
|                                                                                   |
|                                                                                   |
|                       [ THIS SPACE INTENTIONALLY LEFT BLANK ]                     |
|                                                                                   |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

---

### 5.6 Synthesis of Parts IV & V: The Mirror Investment Ledger (`Table 20`), 11-Layer Constructive Synergy Attribution (`Table 19`), & Document 3 Coalition Matrix (`Tables 21 & 22`)

*Source Scripts:* `Plot_Counterfactuals_And_MirrorInvestments.m` and `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m`
*Output CSVs:* `Table19_Constructive_Synergy_Wedges_Dunedin_22.csv`, `Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_Dunedin_22.csv`, `Table21_Doc3_LTFM_Sinkhole_Defense_Trajectories_Dunedin_22.csv`, and `Table22_Doc3_2D_Coalition_Complementarity_Matrix_Dunedin_22.csv`
*Figures:* `Fig_Counterfactual_8Scenarios_SS1_SS2_Dunedin_22.png` and `Fig_7Segment_Welfare_And_MirrorInvestments_Dunedin_22.png`

![Constructive 11-Layer Synergy Attribution](Output_NZ_4Region_Intergen/Fig_Counterfactual_8Scenarios_SS1_SS2_Dunedin_22.png)

#### How the 11-Layer Attribution and 4 Synergy Wedges Are Calculated (`Plot_Counterfactuals_And_MirrorInvestments.m`)

Rather than treating policy interactions as an unexplained residual, `Plot_Counterfactuals_And_MirrorInvestments.m` computes each row of **Table 5.6A (`Table 19`)** by pinning the **7 Isolated Policy Factors** strictly to their standalone budget and VFI elasticities (so isolated childhood programs never artificially inflate in `SS2`, and isolated Geographic Transfers `L06` retire by 82% in 1-to-1 lockstep with `-Inv 4`), while the **4 Synergy Wedges** capture the exact VFI supermodular complementarity residual:

1. **7 Isolated Policy Factors (`+11.23% CE` National, `45.5%` of the Total Prize):** Layers `L01`, `L02`, `L04`, `L05`, `L06`, `L09`, and `L10` evaluate each policy instrument standalone while holding complementary stacks at their *SS0* baseline. Deploying early-years wraparound without adolescent mentoring (`P0_Early_0to5` in *Tables 4 & 5*) loses **22%** of unbanked gains to adolescent fade-out ($\delta_{\mathrm{fade}} = 0.22$), while deploying late-school investments without early foundations (`P1P2_Late_6to17`) hits the Cunha–Heckman Stage-2 harmonic-mean bottleneck ($\varphi_2 = -0.95$, $\sigma_2 = 0.513 < 1$). Crucially, **`L06_Iso_GeoTransfer_Income`** bridges acute rural/provincial hardship in *SS1* (`+0.81% CE`) and then **retires by 82% down to `+0.15% CE` in *SS2*** alongside `-Inv 4` as regional $z_l \to z_h$ jobs (`L08`) and the expanded **-3.75 pp PAYE tax cut** (`L10` = **+2.69% CE**) replace transfer dependency.
2. **★ Wedge 1 — Dual-Gate Human Capital Synergy (`L03` = `+3.32% CE` Nat., `+3.85%` Akl, `13.4%` Share):** Computed from the difference between the joint Dual-Gate solve and the sum of the two isolated gates: $\Delta \mathrm{CE}_{k,\mathrm{Wedge1}} = \mathrm{CE}_k(\mathrm{Gate1} \cup \mathrm{Gate2}) - \mathrm{CE}_k(\mathrm{Gate1}_{\mathrm{iso}}) - \mathrm{CE}_k(\mathrm{Gate2}_{\mathrm{iso}})$. Gate 1 ($G_{\mathrm{ECE1}}$ + *Ka Ora, Ka Ako* / CEFS Farm-to-ECE nutrition [Ref 56]) supplies the retained early skill stock $\theta_c^{\mathrm{ret}}$ required for Stage-2 complementarity, while Gate 2 ($M_{\mathrm{mentor}}$ + CEFS FYI / GrowingChange agricultural leadership [Ref 56]) halts $\delta_{\mathrm{fade}}$ and buffers **80%** of family unemployment distress ($\psi_{\mathrm{unemp}}$).
3. **★ Wedge 2 — 20% LVR-Clearance & Whānau-Anchoring Synergy (`L07` = `+2.33% CE` Nat., `+2.79%` Akl, `9.4%` Share):** Because young-adult homeownership requires clearing the non-linear Kiyotaki 20% deposit threshold ($a_1 + E \ge 0.20 Q_k$), cooling metropolitan house prices ($Q_{\mathrm{Akl}}$ down **-10.5%**) and endowing $E = 0.080$ act as supermodular complements that lift Auckland young ownership from **28.0% to 41.2%** (*Table 3*) while stabilizing elder *whānau* housing tenure ($\Phi_{\mathrm{home}} > 1$).
4. **★ Wedge 3 — Cross-Stack Human Capital $\times$ Spatial/Enterprise Synergy (`L08` = `+5.20% CE` Nat., `+5.63%` Akl, `21.1%` Share):** The single largest synergy wedge in the framework ($\Delta \mathrm{CE}_{k,\mathrm{Wedge3}} = \mathrm{CE}_k(\Phi_{\mathrm{HC}} \cup \Phi_{\mathrm{Spatial}}) - \mathrm{CE}_k(\Phi_{\mathrm{HC}}) - \mathrm{CE}_k(\Phi_{\mathrm{Spatial}})$). Coupling the Dual-Gate Human Capital Stack with Guvenen et al. firm capital reallocation, competition reform [Ref 49], and **1.60x–2.16x regional food-hub procurement multipliers** [Ref 56] upgrades rural and provincial enterprises from $z_l$ to $z_h$ (`+4.08
- 
* **Literature & Equation Defense of Layer 9 (Sovereign Debt-Service Interest Relief):**
  1. *Direct Crown Budget Relief ($`r_t d_t \downarrow`$):* Following Ferriere et al. (2025, Sec. 4.2 & 6.1), where government debt service $`r_t d_t`$ absorbs ~2.8%–3.1% of public outlays in the intertemporal budget constraint $`(1 + r_t)d_t + G_t + T_t = d_{t+1} + T_{\mathrm{rev},t}`$, locking 50% of post-breakeven surpluses ($`\Omega_{\mathrm{debt},g}`$) into sovereign debt retirement saves **NZD 0.22k to NZD 0.38k/yr per worker** in deadweight bond interest.
  2. *Domestic Bond-Market Crowding-In ($`\Delta r = -60\text{ bps}`$):* In the national asset market clearing condition $`\sum_k \omega_{F,k} \int (k_k - a_f) d\Gamma_k + B_{\mathrm{gov}} = \sum_k \omega_{HH,k} \int a_{\mathrm{fin}} d\mu_k`$, retiring $`B_{\mathrm{gov}}`$ reduces sovereign crowding-out of private capital, lowering equilibrium interest rates (`r_delta = -0.006`) and reducing SME credit and young-homeowner mortgage costs (Kiyotaki et al., 2024, Fig. 9).
  3. *Stopping External Debt-Service Leakage:* In a small open economy with net foreign debt obligations $`B_t^* / R_t`$ (Kiyotaki et al., 2024, Eq. 29), retiring public debt prevents domestic tax revenues from leaking abroad to foreign bondholders.
  4. *Cross-Reference to [Document 3](Document%203.md) (`Tables 21 & 22`):* For the 60-year LTFM Sinkhole (-16.21% CE), the 3.0%-of-GDP (+NZD 8.0B/yr) Defense Commitment (-21.69% CE under SS0 vs. +20.72% CE under the Unified Plan), the Two-Term (6-Year) "Stop-Go" Policy Cycle (+3.84% CE vs. +6.58% CE for a 1-Term Cycle), and the $`4 \times 4`$ Coalition Dependency Matrix (`Table 22`), see **[Document 3](Document%203.md)** and its Appendix Tables A.1–A.3.

---

## 6. Part VI Cross-Reference: Twelve International Benchmarks (Tables 6A & 6B) & The Deming-to-Tokyo Coda

### 6.1 Symbolic Cross-Country Matrices & Empirical Citations (Matching Doc 1A Tables 6A and 6B)

#### Table 6A: The Eight Full-Loop Winners (Honoring Lifecycle Aspects 1, 2, and 3)

| Historical / International Case | Time Horizon | Primary Policy Instruments Deployed | Corresponding Lifecycle Aspects & Model Channels (`SS0 -> SS1 -> SS2`) | Observed Empirical Payoff & Primary Literature Anchor |
| :--- | :--- | :--- | :--- | :--- |
| **1. Sweden & Finland** (*Nordic Dual-Dividend Model*) | 25–50 Years (1970–2020) | Universal ECE & maternal/infant *Neuvola* clinics (1.6%–2.0% of GDP) + 1993 dual capital/labor tax reform | **Aspect 1** ($`\Delta G_{\mathrm{ECE}}`$) + **Aspect 2** (female labor supply $`\ell_f \uparrow`$) + **Aspect 3** (tax modernization) | Cut lifetime earnings shock variance $`\sigma_y^2`$ in half (`0.14` vs. `0.30` in US; De Nardi, 2004); lifted female employment above 80%; top-decile social mobility |
| **2. Estonia** (*Small-Economy Digital & Tax Benchmark*) | 25–30 Years (1994–2025) | 0% tax on reinvested enterprise capital + pure Land Value Tax + universal kindergartens & 18-month parental leave | **Aspect 3** Guvenen "use-it-or-lose-it" firm shift ($`\tau_k \to \tau_a`$) + **Aspect 1** early skill compression | Ranked #1 in Europe in OECD PISA math/science with minimal socio-economic skill gaps ($`h_1\text{–}h_2`$) and top per-capita unicorn startup density |
| **3. New Deal & Post-WWII United States** | 35–45 Years (1935–1980) | High progressive estate/inheritance tax consensus ($`\tau_b`$) + High School Movement + 1944 GI Bill youth endowment | **Aspect 3** estate taxation ($`\tau_b`$; Piketty & Saez, 2013) funding **Aspects 1 & 2** universal schooling & Youth Grant (*E*) | Average schooling rose from 8 to 13 years; multi-fold surge in TFP, mass middle-class homeownership, and broad real wage growth |
| **4. Post-War 20th-Century Japan** (*Productive Miracle*) | 25–40 Years (1946–1985) | Dissolution of passive land/estate hoarding (*zaibatsu* & landlord estates) + universal *Boshi Kenko Techo* infant health screening & schooling | **Aspect 3** asset de-concentration (Moriguchi & Saez, 2008) + **Aspect 1** First-2000-Days readiness ($`\theta_c, h_p`$) | Lowest infant and child hardship in the world within 1 generation; sustained 8%–10% annual real GDP per capita growth |
| **5. Viet Nam** (*Front-Loaded Basic Skill Miracle*) | 25–35 Years (1990–2025) | Relentless public focus on maternal/infant nutrition and universal foundational schooling post-*Đổi Mới* | **Aspect 1** Cunha–Heckman self-productivity ($`\gamma_{1,\mathrm{self}}`$) & dynamic complementarity ($`\varphi_2 = -0.95`$) | Cut child hardship from >50% to <19%; 15-year-old OECD PISA scores match or exceed high-income OECD averages |
| **6. Ireland** (*Reversing a Century of Youth Brain Drain*) | 25–35 Years (1967–2002) | Universal secondary and regional technical education + pro-enterprise corporate tax regime | **Aspect 2** migration reversal ($`\Pi_{\mathrm{mig}}`$ retaining $`h_6\text{–}h_7`$ youth) + **Aspect 3** enterprise TFP lift | Reversed 150 years of 20–35 youth emigration into high-skill net return migration; tripled real GDP per capita |
| **7. Singapore** (*Youth Endowments + Anti-Speculation Housing*) | 30–50 Years (1970–2025) | Universal Child Development Accounts (CDAs) & Edusave youth grants + Additional Buyer's Stamp Duties (ABSD) on speculative property | **Aspect 1** ($`G_{\mathrm{ECE}} + E`$) + **Aspects 2 & 3** curbing primate-city land overvaluation ($`Q_k \downarrow`$, tenure cutoff $`\xi_k`$) | Top-tier global PISA human capital alongside >85% domestic homeownership without speculative land crowd-out |
| **8. Norway & Quebec** (*Sovereign Rule & Self-Financing ECE*) | 10–35 Years (1990–2025) | Norway Sovereign Wealth fiscal rule + universal *Barnehage* ECE; Quebec 1997 universal low-cost early childhood care | **Aspects 1 & 2** ($`\Delta G_{\mathrm{ECE}} \Rightarrow \ell_f \uparrow, \Delta \mathrm{Tax} \uparrow`$) + **Aspect 3** (`SS2` 2050 Debt/Endowment rule $`\Omega_{\mathrm{reform}}`$) | Quebec maternal employment rose +7–8 pp and new tax revenues exceeded 100% of ECE cost (Doepke et al., 2022); Norway top fiscal solvency & mobility |

#### Table 6B: The Devolved Half-Bridge & The Cautionary Tales (When Aspects 2 & 3 Are Constrained or Ignored)

| Regime Archetype & Case | Time Horizon | What Was Deployed vs. What Was Missing | Lifecycle Aspect Diagnostic (`SS0 -> SS1 -> SS2`) | Observed Empirical Outcome & Audit Citations |
| :--- | :--- | :--- | :--- | :--- |
| **9. The Devolved Half-Bridge:**<br>**Scotland** (*Early-Years & Mentoring Success Hit by Wage-Tax Ceiling*) | 10 Years (2017–2026) | **Deployed:** *Child Poverty Act*, *Scottish Child Payment* (to GBP 28.20 → 40/wk), 1,140 hrs universal ECE, *The Promise* & *MCR Pathways* mentoring.<br>**Missing:** Sovereign land, estate, or corporate tax powers (relied on 42%–48% PAYE hikes & 1991 Council Tax). | **Validates Aspect 1** ($`\Delta G_{\mathrm{ECE},1}`$, Gate 3 mentoring $`\Delta_{\mathrm{Tuakana}}`$, Exit 1 Care closure) **AND proves why Aspects 2 & 3** ($`\tau_a, \tau_b \to E`$ vs. $`\tau_l \uparrow`$) **are essential** | Cut child poverty **6 percentage points below the rest of the UK** (21% vs. 27%+) and lifted mentored care-experienced youth progression from **54.0% to 81.6%**, but stalled above the 18% interim target due to uncooled urban housing (*Q_k*) and lack of sovereign wealth/land tax levers |
| **10. The Primate-City Trap:**<br>**21st-Century South Korea** (*Cautionary "Seoul Squeeze"*) | 25 Years (2000–2025) | **Deployed:** High formal schooling investment.<br>**Missing:** Primate-city housing anti-speculation rules & public First-2000-Days wraparound (replaced by private *Hagwon* child-cost pressure). | Validates why **Aspect 1** schooling fails without **Aspects 2 & 3** (Auckland housing cooling $`Q_{\mathrm{Akl}} \downarrow`$ & universal in-kind $`G_{\mathrm{ECE}}`$) | Unchecked Seoul housing squeeze ($`Q_k \uparrow`$) and private tutoring costs crushed cooperative family bargaining, driving Total Fertility Rate down to **0.72–0.75** (Doepke et al., 2022) |
| **11. The Land-Bubble Collapse:**<br>**Post-1990 Bubble Japan** (*Cautionary Land Overvaluation*) | 30 Years (1990–2020) | **Deployed:** Strong base schooling & industrial quality.<br>**Missing:** Fiscal valves to prevent excess corporate/household savings from pouring into urban land speculation; weak support for working mothers. | Validates Hirano–Toda (2025) land-bubble drag ($`G_k > R`$) in **Aspects 2 & 3** when speculative property is left untaxed | 1991 land-bubble collapse triggered **30 years of balance-sheet stagnation**, depressed fertility, and rapid aging |
| **12. The Unfunded Rate-Cut & Abatement Trap:**<br>**The Curse of Voodoo Economics** *Post-1981 US & 1991 NZ Tax/Welfare Shifts* (*Cautionary Supply-Side & Coercive Abatement*) | 35–45 Years (1981–2025) | **Deployed:** Top-bracket statutory tax cuts without land/estate base broadening ($`\tau_a = 0`$), paired with 1991 benefit cuts and 70%–90% abatement cliffs. **Missing:** First-2,000-Days wraparound ($`G_{\mathrm{ECE},1}`$) and Guvenen wealth-to-enterprise rebalancing ($`\tau_a \to z_h`$). | Validates why cutting $`\tau_k, \tau_l`$ without *τ_a* = 0.015 (1.5%) fuels land hoarding ($`z_\ell`$) and deficits, while punitive benefit abatement at the *i_c* = 0 corner strips parental time ($`\ell_{\mathrm{child}} \downarrow`$) and erodes Stage-1 skill $`\theta_c`$. | 50-year 18-OECD audit shows zero GDP growth lift from top rate cuts alongside higher deficits and top-1% concentration (Hope & Limberg, 2022; Piketty, Saez, & Stantcheva, 2014; Straub & Werning, 2020). |

* **Scotland Literature & Official Audit Citations (2017–2026):**
  * *Wellbeing Economy Governments (WEGo) & Post-Growth Welfare Synthesis:* Corlet Walker, Druckman, & Jackson (2021, *The Lancet Planetary Health* 5(4): e237–e246), linking Scotland, New Zealand, Iceland, Wales, and Finland.
  * *Statutory Targets, Scottish Child Payment, & Labour Supply Audit:* Scottish Government (*Bringing Hope, Building Futures: Tackling Child Poverty Delivery Plan 2026–2031*, March 2026; *Scottish Child Payment and the Labour Market: 2026 Update*, October 2026); Joseph Rowntree Foundation (*Poverty in Scotland 2026*, October 2026); Fraser of Allander Institute (*Meeting Scotland's Child Poverty Targets: Modelling and Policy Packages*, 2025).
  * *1,140 Hours Universal ELC & Adolescent/Care-Exit Prevention:* Audit Scotland (*Early Learning and Childcare: Progress on Delivery of the 1,140 Hours Expansion*, 2023/2025); *The Promise Scotland* (Plan 24–30) and *MCR Pathways* national secondary mentoring impact evaluations (lifting positive post-school destinations for care-experienced youth from 54.0% to 81.6%).

---

### 6.2 Part VI Coda Cross-Reference — From W. Edwards Deming's Post-War Japanese Miracle (1947–1950) to the Hirano–Toda Tokyo Land Bubble (1985–1991) & *Te Tiriti o Waitangi* Stewardship

* **Document 1A Claim (Part VI Coda):** Post-war Japan's rapid ascent under General Douglas MacArthur's reconstruction (land/estate de-concentration + universal *Boshi Kenko Techo* maternal/child health) and W. Edwards Deming's 1947 Census mission and August 1950 Mt. Hakone JUSE lecture (*The System of Profound Knowledge* and *Kaizen*) proves that whole-system alignment of **Aspect 1** and **Aspect 2** delivers measurable transformation within 3 to 5 years—while Japan's 1985–1989 real estate bubble proves that if **Aspect 3** is left unguarded, excess industrial and household surpluses inevitably inflate finite urban land (Hirano & Toda, 2025) before collapsing into multi-decade stagnation.
* **Theoretical & Historical Citations:** Deming, W. E. (1982/1986, *Out of the Crisis*, MIT Press; 1993, *The New Economics for Industry, Government, Education*, introducing *The System of Profound Knowledge*); Tiemann, M. (2023, *Achieving Net-Zero with Sustainable Quality*, OS-Climate / Linux Foundation); Moriguchi, C., & Saez, E. (2008, *Review of Economics and Statistics*, on post-1945 Japanese estate and wealth de-concentration); Hirano, T., & Toda, A. A. (2025, *"Unbalanced Growth and Land Overvaluation,"* *Journal of Political Economy Macroeconomics* / PNAS, proving the *Bubble Necessity Theorem* when productive sectoral growth outpaces elastic land supply without land/wealth taxation $`\tau_a`$); and *Te Tiriti o Waitangi* intergenerational *kaitiakitanga* / *mokopuna* frameworks (Waitangi Tribunal *Hauora* and *Oranga Tamariki* reports; Orange, 2021).

```text
+-----------------------------------------------------------------------------------+
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                       [ THIS SPACE INTENTIONALLY LEFT BLANK ]                     |
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

---

## 7. Methodological Guardrails & Core Reference Equations

### 7.1 Methodological Guardrails

1. **Strict Separation of the Crown Fiscal Lens and the Economy-Wide GDP Lens (Counting Rule #1):** Avoided public service outlays (Oranga Tamariki care at NZD 180k/yr or NZD 37.1k–54.7k/yr annualised cohort flow + NZD 181k lifetime Crown abuse-in-care liability, acute hospital nights, youth/adult justice, and main welfare benefit transfers *T_k*) belong strictly to the **Crown Fiscal Ledger**, whereas additional adult gross output $`\Delta Y_t`$ belongs to the **Economy-Wide GDP Lens**. Benefit transfers are fiscal redistributions (not net additions to GDP), and public tax revenue on $`\Delta Y_t`$ ($`\approx 28.8\%`$ of $`\Delta \mathrm{GDP}`$) is reported inside the Fiscal Ledger and **never added to GDP**.
2. **Cohort-to-Ledger Regime Separation & Exact Ribbon Conservation in the 6-Gate (29-Node) Fiscal Sankey:** To prevent ontological cross-account distortion between working-age and retirement fiscal accounts, `Plot_ChildFiscal_SSankey.m` tracks the human cohort through *Gates 1–5 (Nodes 1–21)*—mapping Age-20 launch skill tiers (Gate 4, Nodes 14–16) into the five *Prime Career & Enterprise Sorting Strata* at Gate 5 (Nodes 17–21: Chronic Adversity, Core Workforce, $z_l$ Passive Land/Rent Speculation, $z_h$ Productive Enterprise Builders, and Emigrated Abroad)—and places the vertical regime-break wave at *Gate 5 ($X = 5.0$)*. Across the regime-break wave, the five human career strata map once and without rescaling into the *eight Annualized Adult Fiscal Ledger accounts at Gate 6 (Nodes 22–29)*, guaranteeing that every ribbon entering Gate 6 sums to the exact `kNZD/yr` printed on the node label, while regional charts scale gross `BNZD/yr` outlays on Node 26 proportionally by the regional population share `reg_pop_share`.
3. **Defending Warm-Glow Bequests + Exact Intergenerational Transition Matrix vs. Outer Dynastic VFI:** As established by De Nardi (2004) and Daruich (2018, Sec. 6), 55% to 75% of the long-run welfare gain from early childhood investment operates through the shift in the **stationary distribution of parent states** $`\mu_k(a, h, z, j)`$ across generations rather than changes in the curvature of the continuation value function. Because `Build_IntergenTransitionMatrix.m` maps exact optimal child investments $`i_c^*(a_p, h_p, z_p, k)`$ and net-of-tax estates $`(1 - \tau_b)a^{\prime *}_j(k)`$ into the next generation's initial distribution `jequaloneDist` ($`\mu_{1,k}(a_1, h_1, z_1)`$), our GPU-vectorized architecture captures 100% of this dynastic general-equilibrium feedback loop ($`\mathcal{T}_{\mathrm{IG}}: \mathbf{Q}_h \times \mathbf{Q}_a \times \Pi_{\mathrm{mig}}`$) without adding parent-child strategic gaming states.

---

### 7.2 Core Reference Equations for Technical Reviewers

* **1. Working-Age & Retirement Household Budget Constraint (`ReturnFn_SpatialHH.m`):**

```math
e_{\mathrm{tot}} = \frac{\bigl(1 + (1 - \tau_k)r\bigr)a + (1 - \tau_l) w_k z h \max(0, \ell - I_h) + \mathbb{I}_{j=1} E + T_k - \bar{e}_k - (1 - s_{\mathrm{sub}}) i_c - a'}{1 + \tau_c}
```

* **2. Analytical Housing Tenure Cutoff $`\xi_k`$ & Composite Housing Price Index $`p_{H,k}(j)`$ (`Kiyotaki et al., 2024`):**

```math
\xi_k = \min\left\{1,  \frac{1}{\bar{\chi}} \left(\frac{rr_k}{rh_k}\right)\right\}, \qquad p_{H,k}(j) = \begin{cases} \xi_k rh_k + (1 - \xi_k) \dfrac{rr_k}{0.5 \bar{\chi}} & \text{if } j < J_r \\ rh_k & \text{if } j \ge J_r \end{cases}
```

* **3. Infinite-Horizon Firm Bellman Equation & After-Tax Return (`ReturnFn_Firm.m`, `Guvenen et al., 2023`):** In region $`k \in \{\mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland}\}`$, firms with productivity $`z_f \in \{z_{\ell,k}, z_{h,k}\}`$ and collateral limit $`k \le \lambda_{\mathrm{col}} a_f`$ ($`\lambda_{\mathrm{col}} = 2.50`$) solve:

```math
V_{F,k}(a_f, z_f) = \max_{a'_f \in [0, R_k(z_f; \Delta t) a_f]} \left\{ \ln\bigl(R_k(z_f; \Delta t) a_f - a'_f\bigr) + \beta_{\mathrm{firm}}(\Delta t) \sum_{z'_f} \Pi_{f,k}(z'_f \mid z_f) V_{F,k}(a'_f, z'_f) \right\}
```

```math
R_k(z_f; \Delta t) = (1 - \tau_a)\Delta t + (1 - \tau_k) \left\{ r + \max\left(0,  \alpha_k \left(\frac{1 - \alpha_k}{w_k}\right)^{\frac{1-\alpha_k}{\alpha_k}} z_f - \bigl(r + \delta_k(\Delta t)\bigr)\right) \lambda_{\mathrm{col}} \right\}
```

* **4. Two-Stage Childhood CES Skill Law of Motion & Adult Ben-Porath Dynamics (`ChildCES_aprimeFn.m` / `HumanCapital_Lifecycle_aprimeFn.m`):** With step weight $`\omega_s = 1 / n_s`$ across Stage 1 ($`\mathcal{J}_{c,1}, \varphi_1 = 0.35`$) and Stage 2 ($`\mathcal{J}_{c,2}, \varphi_2 = -0.95`$):

```math
\theta_{\mathrm{step}}(\theta_c, i_c, G_{\mathrm{ECE},s}, \varphi_s) = \left[ \gamma_{s,\mathrm{self}} \theta_c^{\varphi_s} + \gamma_{s,\mathrm{inv}} (i_c + G_{\mathrm{ECE},s} + \bar{g}_{\mathrm{ECE}})^{\varphi_s} + \gamma_{s,\mathrm{par}} \bar{h}_p^{\varphi_s} \right]^{1/\varphi_s}
```

```math
\theta'_c = \begin{cases} (1 - \omega_{s1}) \theta_c + \omega_{s1} \theta_{\mathrm{step}}(\theta_c, i_c, G_{\mathrm{ECE},1}, \varphi_1) & \text{if } j \in \mathcal{J}_{c,1} \\ (1 - \omega_{s2}) \theta_c + \omega_{s2} \theta_{\mathrm{step}}(\theta_c, i_c, G_{\mathrm{ECE},2}, \varphi_2) & \text{if } j \in \mathcal{J}_{c,2} \\ \theta_c & \text{otherwise} \end{cases}
```

```math
h' = (1 - \delta_{hc}(\Delta t)) h + \left(\frac{\Delta t}{5}\right) I(\ell > 0) I_h^{\alpha_I} h^{\alpha_H}
```

- **5. Macro Public Residual (Ω<sub>fiscal</sub>) & The 2050 50/50 Dynamic Surplus Split (`Plot_ChildFiscal_SSankey.m`):** Projecting the five Gate 5 adult career strata (*s* ∈ {17, …, 21}) onto the eight Gate 6 annualized adult fiscal accounts (*a* ∈ {22, …, 29}), the topline net cohort fiscal balance Ω<sub>fiscal</sub> (indicated by the single black breakeven bar with gold marker above the Node 26 / Node 27 Debit-Credit boundary) and positive reform surplus allocation are defined as:

```math
\Omega_{\mathrm{fiscal}} = (\mathrm{Tax}_{\mathrm{GST,Cap,Est},27} + \mathrm{Tax}_{\mathrm{PAYE},28}) - (\mathrm{Cost}_{\mathrm{Exits},22,23,25} + \mathrm{Cost}_{\mathrm{Infra,Health,Super},26})
```

```math
\Omega_{\mathrm{surplus}} = 0.50 \, \Omega_{\mathrm{debt}} + 0.50 \, \Omega_{\mathrm{reinv}}
```
