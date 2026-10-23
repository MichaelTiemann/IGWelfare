# Strategy and Policy Answer Key
**Quantitative Companion & Technical Audit Reference for Document 1A (4-Region + Abroad Multiphase Edition)**

---

## 1. Purpose & Cross-Document Mapping

This **Strategy and Policy Answer Key (Document 1B)** serves as the quantitative bridge between the executive narrative in **Document 1A** (*Intergenerational Welfare, Capital Allocation, and Human Potential in New Zealand.md*) and the formal mathematical and VFI Toolkit codebase specifications in **Document 2** (*Intergenerational Welfare Technical Documentation & Model Specification Guide.md*). Every headline statistic, Sankey node flow, multiphase welfare gain, actuarial continuation valuation, and historical benchmark in Document 1A is mapped below to its exact MATLAB script, CSV output table, parameter struct field, and empirical literature anchor.

| Document 1A Part & Section | Primary MATLAB Script(s) | Exported CSV Table(s) in `Output_NZ_4Region_Intergen/` | Canonical Figure Filename(s) |
| :--- | :--- | :--- | :--- |
| **Part I & Part II:** Three Coupled Lenses & Montessori / *Tuakana–Teina* Gate | `Run_All_NZ_Intergen_Suite.m`, `Configure_TimeGrid_Params.m`, `Build_Phase_Registry.m` | `Table3B_4Region_Abroad_SteadyState_Summary.csv` | Unified Loop Diagram & Cultural Pedagogy Mapping |
| **Part III, Sec. 1:** 5-Stage (17-Node) Population Cohort Fates Sankey | `Plot_ChildFates_2Panel_SSankey.m` | `Table15_ChildFates_5Stage_Decomp_<Region>.csv` | `Fig_ChildFates_5Stage_2Panel_<Region>_Dunedin_22.png` (and `3Panel` for `SS0-SS1-SS2`) |
| **Part III, Sec. 2:** 6-Gate (26-Node) Lifecycle Fiscal Sankey & 4-Lane Split | `Plot_ChildFiscal_2Panel_SSankey.m` | `Table14_FiscalLedger_6Gate_Decomp_<Region>.csv` | `Fig_ChildFiscal_2Panel_<Region>_Dunedin_22.jpg` (and `3Panel` for `SS0-SS1-SS2`) |
| **Part IV, Sec. 1:** Multiphase 4-Region Welfare Decomposition (`SS1` & `SS2`) | `WelfareDecomposition_4Region.m`, `TransPath_4Region_Master.m` | `Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv`, `Table2_4Region_LabroussePerdereau_SpatialQuintiles.csv` | `Fig1_Daruich_Cohort_Welfare_4Region.png` |
| **Part IV, Sec. 2:** Multi-Stage Counterfactuals (First 2000 Days vs. Late) | `Counterfactuals_LeeSeshadri_4Region.m` | `Table4_4Region_LeeSeshadri_IGE.csv`, `Table5_4Region_LeeSeshadri_Output_Welfare.csv`, `Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv` | `FigE8_LeeSeshadri_4Region_Counterfactuals.png` |
| **Part IV, Sec. 3:** Housing Tenure & Generational Cleavage | `TransPath_4Region_Master.m` | `Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv` | `Fig2_Kiyotaki_Housing_Estates_4Region.png` |
| **Part IV, Sec. 4:** Dynamic Population Shares & Brain-Drain Closure | `Build_IntergenTransitionMatrix.m`, `TransPath_4Region_Master.m` | `Table9_4Region_Dynamic_Population_Shares.csv`, `Table10_4Region_Abroad_BrainDrain_Cohesion.csv` | `Fig3_BrainDrain_Cohesion_4Region.png` |
| **Part IV, Sec. 5:** Childcare Bargaining, Fertility, & NZ Super Solvency | `FertilityBargaining_Module.m` | `Table7_4Region_Endogenous_TFR_DiffFertility.csv`, `Table8_4Region_Fertility_Stunting_NZSuperTax.csv` | `FigFert_4Region_Fertility_SuperSolvency.png` |
| **Part V, Sec. 1:** 2050 Sovereign Debt-Sinking & Reinvestment Protocol | `Plot_ChildFiscal_2Panel_SSankey.m` (`Build_Custom_Protocol_2050_Table`) | `FiscalLedger.Protocol_2050_Summary` | Gate 5 & Gate 6 Net-Zero Breakeven Overlay |
| **Part V, Sec. 2–3:** ACC-Style Actuarial Continuation Valuation & Credibility | `Plot_CumulativeTransitionPayoffs.m`, `Plot_ActuarialContinuationValuation.m` | `Out_Dunedin` / `Out_GUiNZ` Console & Struct Audit | `Fig_Actuarial_2Panel_<Region>_<Anchor>.png`, `Fig_Actuarial_Fiscal_<Region>_<Anchor>.png`, `Fig_Actuarial_WideGDP_<Region>_<Anchor>.png` |
| **Part VI:** Historical Precedents & Cautionary Tales (10 Cases) | Cross-Country Macro-Calibration Benchmarks | Section 5.5 Literature & Parameter Verification Table | 10-Case Comparative Matrix |

---

## 2. Sankey Architecture, Montessori / *Tuakana–Teina* Pathways, & 2050 Protocol Answer Key

### 2.1 Cultural & Pedagogical Synthesis at Gate 3 ($J = 5$, Ages 12–14): Montessori *Erdkinder* Meets *Tuakana–Teina* and the Graeme Dingle Foundation
In `Build_IntergenTransitionMatrix.m` and both Sankey scripts (`Plot_ChildFates_2Panel_SSankey.m` and `Plot_ChildFiscal_2Panel_SSankey.m`), **Gate 3 ($J = 5$ under $\Delta t = 3$, corresponding to parental period $j_p = 4$ and adolescent ages 12–14 / Years 8–10)** models the early-adolescent vulnerability window.

* **Why Early-Childhood Gains Can Erode at Ages 12–14:** In Cunha, Heckman, and Schennach (2010), Stage-2 schooling investments exhibit strong dynamic complementarity ($\varphi_2 = -0.95$, elasticity of substitution $\sigma_2 \approx 0.51$) alongside heightened vulnerability to household distress. When a parent experiences an unbuffered unemployment or severe low-income shock (`is_unemp_stress = (iz == 1) || (n_z1 >= 5 && iz == 2 && is_hardship)`), adolescent skill formation suffers a structural erosion penalty $\Delta \ln\left(h_{\mathrm{mean}}\right) = -0.22$.
* **Indigenous Te Ao Māori & Pasifika Foundations Alongside Montessori's *Erdkinder*:**
  While Maria Montessori's *Erdkinder* ("land-children") framework describes ages 12–15 as a sensitive period requiring real-world social contribution, economic agency, and cross-age mentoring, Aotearoa New Zealand's indigenous **Te Ao Māori** and **Pasifika** traditions provide the primary cultural anchor for this parameter:
  * ***Tuakana–Teina* (Older-to-Younger Kinship Responsibility):** An older or more skilled *tuakana* guides and protects a younger *teina*, buffering the *teina* against family or school alienation while building executive function, empathy, and *mana* in the *tuakana*.
  * ***Ako* (Reciprocal Two-Way Learning):** Teacher and learner roles flow bidirectionally, generating the **two-way skill dividend** in our transition matrix ($\Delta \ln\left(h_{\mathrm{mean}}\right) = +0.05$ in `SS0`, rising to $+0.11$ in `SS1` and $+0.14$ in `SS2`, while amplifying effective Stage-1 wraparound productivity $G_{\mathrm{ECE,eff}} = 1.15 \times G_{\mathrm{ECE}}$).
  * ***Manaakitanga*, *Whanaungatanga*, & *Rangatiratanga*:** Uplifting the *mana* of peers through care (*manaakitanga*), school kinship belonging (*whanaungatanga*), and youth self-determination (*rangatiratanga*).
* **Empirical Breakdown of the 17.3% Baseline (`SS0`) Scaling to 57.3% (`SS1`) and 65.0% (`SS2`):**

| Aotearoa Delivery Pathway at Gate 3 ($J = 5$, Ages 12–14 / Years 8–10) | Representative New Zealand Programs & Institutions | Status Quo Share (`SS0`) | Phase 1 Reform (`SS1`) | Phase 2 Harvest (`SS2`) | Primary Mechanism in `Build_IntergenTransitionMatrix.m` |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **1. Structured School Peer-Mentoring Charities** | **Graeme Dingle Foundation** (*Stars / Te Kāhui Whetū* Year 12–13 *tuakana* mentoring Year 9 *teina*; *Project K* wilderness & community mentoring), *I Have a Dream NZ* | 10.0% | 28.5% | 32.0% | Insulates at-risk Year 8–10 students against `z1` family unemployment stress; cuts truancy and Exit 1/Exit 4 entry |
| **2. *Kura Kaupapa Māori*, *Kura-ā-Iwi*, & Pasifika *Tuakana* Academies** | *Te Runanga Nui o Ngā Kura Kaupapa Māori*, *Ngā Kura ā Iwi o Aotearoa*, bilingual *whānau* classes, Pasifika *Tuakana–Teina* & polyfest leadership hubs | 4.7% | 16.8% | 19.5% | Embeds *Tuakana–Teina*, *Ako*, and *Whanaungatanga* across vertical age cohorts; lifts NCEA Level 3 retention |
| **3. High-Agency Vertical-*Whānau* State Secondary/Intermediate Schools** | *Ao Tawhiti Unlimited Discovery* (Christchurch), *Hobsonville Point Secondary School*, *Tai Wananga*, project-based state *whānau* houses | 1.8% | 8.5% | 9.5% | Replaces rigid age-segregated tracking with multi-age advisory *whānau* and community enterprise projects |
| **4. State & State-Integrated Montessori Adolescent Units (*Erdkinder*)** | *Wāora Montessori School* (Lower Hutt), *Berhampore*, *Royal Oak Intermediate*, Montessori Aotearoa adolescent units | 0.8% | 3.5% | 4.0% | Direct Montessori *Erdkinder* micro-economy and cross-age mentoring |
| **Combined Montessori / *Tuakana–Teina* Gate 3 Participation** | **All Four Pathways Combined (`Node 8` in Fates / `Node 10` in Fiscal)** | **17.3%** | **57.3%** | **65.0%** | **Two-way skill boost ($\Delta \ln h = +0.11\text{ to }+0.14$) + buffers family job-loss shock** |

---

### 2.2 The 5-Stage (17-Node) Population Cohort Fates Sankey (`Table15_ChildFates_5Stage_Decomp_<Region>.csv`)
*Source Script: `Plot_ChildFates_2Panel_SSankey.m` (Supports $N = 1, 2, 3, \dots$ phases via `Active_Phases` and `Build_Phase_Registry.m`)*

Each node's ribbon width in the Population Fates Sankey represents the exact percentage of the birth cohort (`Pop_17Nodes_Pct`) passing through that developmental state:

| Stage (Child $J$ Axis) | Node ID & Canonical Label | `National` `SS0` (%) | `National` `SS1` (%) | `National` `SS2` (%) | `Auckland` `SS0` (%) | `Auckland` `SS1` (%) | Structural Definition in `Plot_ChildFates_2Panel_SSankey.m` |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Stage 1 ($J = 1$)**<br>*Birth, Age 0* | `1_Birth_Material_Hardship_Squeeze`<br>`2_Birth_Secure_Parental_Buffer` | 25.79%<br>74.21% | 7.74%<br>92.26% | 4.38%<br>95.62% | 29.40%<br>70.60% | 8.82%<br>91.18% | `is_birth_squeeze_4D`: low asset buffer (`a < 0.15*Q_k`) or low-income corner (`iz <= 2 & ic == 0`) |
| **Stage 2 ($J = 2\text{--}3$)**<br>*First 2000 Days* | `3_ECE_Unmitigated_Corner_ic0`<br>`4_ECE_Public_Wraparound_Mod_Inv`<br>`5_ECE_High_Wraparound_Parental_Inv` | 25.79%<br>47.51%<br>26.70% | 5.67%<br>67.63%<br>26.70% | 2.06%<br>69.44%<br>28.50% | 29.40%<br>43.90%<br>26.70% | 6.47%<br>66.83%<br>26.70% | `m_corner = (ic <= 1e-5) & (is_hard | iz <= 2)`; `G_ECE` lifts families into `m_mod` & `m_high` |
| **Stage 3 ($J = 5$)**<br>*Adol. Gate, 12–14* | `6_Adol_Family_Unemp_Stress_z1`<br>`7_Adol_Standard_Schooling`<br>`8_Adol_Montessori_Tuakana_Mentoring` | 18.88%<br>63.82%<br>17.30% | 4.91%<br>37.79%<br>57.30% | 2.45%<br>32.55%<br>65.00% | 21.15%<br>61.55%<br>17.30% | 5.50%<br>37.20%<br>57.30% | Evaluates parental employment shock `iz == 1` vs. Montessori / *Tuakana–Teina* & Graeme Dingle buffer |
| **Stage 4 ($J = 6\text{--}7$)**<br>*Adult Launch, 20* | `9_Launch_Stunted_Tier_h1_h2`<br>`10_Launch_Core_Tier_h3_h5`<br>`11_Launch_Thriving_Tier_h6_h7` | 22.00%<br>54.50%<br>23.50% | 4.02%<br>38.68%<br>57.30% | 1.50%<br>33.50%<br>65.00% | 24.80%<br>52.10%<br>23.10% | 4.50%<br>37.50%<br>58.00% | Completed pre-labor skill mapped onto 7-point grid `h_vec = [0.45..1.80]` (`Dunedin_22` anchor) |
| **Stage 5 ($J = 10$)**<br>*Adulthood, 30+* | `12_Exit1_State_Care_Placement`<br>`13_Exit2_Avoidable_Hospitalisation`<br>`14_Exit3_Lower_Lifetime_Income`<br>`15_Exit4_Benefit_Justice_Burden`<br>`16_Retained_NZ_Thriving_Adult`<br>`17_Emigrated_Abroad_Brain_Drain` | 2.10%<br>4.82%<br>9.63%<br>11.38%<br>61.14%<br>10.93% | 0.49%<br>1.62%<br>4.15%<br>3.89%<br>81.29%<br>8.56% | 0.24%<br>1.12%<br>2.95%<br>2.44%<br>85.65%<br>7.60% | 2.35%<br>5.28%<br>10.42%<br>12.55%<br>50.11%<br>19.29% | 0.54%<br>1.75%<br>4.38%<br>4.18%<br>74.23%<br>14.92% | Dunedin concentration: 22% stunted tier drives **74.1%** of acute Exits 1, 2, 4 in `SS0` (benchmark: 57%–81%) |

---

### 2.3 The 6-Gate (26-Node) Lifecycle Fiscal Ledger Sankey & 4-Lane Reconciliation (`Table14_FiscalLedger_6Gate_Decomp_<Region>.csv`)
*Source Script: `Plot_ChildFiscal_2Panel_SSankey.m` (26 Nodes across 6 Gates; Dual-Regime Scaling with Wiggly Vertical Scale Break at Gate 4, $X = 4.0$)*

To resolve the unit disambiguation problem and reconcile model flows with the **NZD 15,000 to NZD 19,000 per child per year** conventional household expenditure survey benchmark, `Table14_FiscalLedger_6Gate_Decomp_<Region>.csv` records both the **Cohort-Weighted Flow (`_Cohort_Flow_kNZD`)** and the **4-Lane Decomposition**:
* `LaneA_Priv_Cash_kNZD`: Private parental out-of-pocket cash expenditure (net child investment $(1 - s_{\mathrm{sub}})i_c$ + child sustenance share of food, clothing, utilities, and housing $c_{nd} + c_H$).
* `LaneB_Priv_Time_kNZD`: Imputed value of parental care and mentoring time ($w_k z_p h_p \ell_{\mathrm{child}}$).
* `LaneC_Pub_DevInv_kNZD`: Proactive public developmental investment (Paid Parental Leave, BestStart, Plunket, universal ECE $G_{\mathrm{ECE},1}$, public schooling $d_2$, Montessori / *Tuakana–Teina* & Graeme Dingle mentoring $G_{\mathrm{ECE},2}$, and Youth Grant $E$).
* `LaneD_Pub_Remed_kNZD`: Reactive public remediation outlays (means-tested hardship transfers $T_k$, emergency housing, and in-childhood/adult Exits 1, 2, and 4).

| Gate & Lifecycle Window | Node ID & 26-Node Canonical Name | `SS0` Cohort Flow (`_kNZD/yr`) | `SS1` Cohort Flow (`_kNZD/yr`) | `SS1` 4-Lane Split (`Priv Cash` / `Priv Time` / `Pub Dev` / `Pub Remed`) | Conditional Per-Child Rate in Node (`_Cond_PerChild_kNZD`) |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Gate 1 ($J = 1$)**<br>*Birth, Age 0* | `1_MeansTested_Birth_Support`<br>`2_Universal_Birth_Benefit`<br>`3_Private_Birth_OutOfPocket` | 3.70<br>2.70<br>9.60 | 1.15<br>5.20<br>12.40 | 0.0 / 0.0 / 0.0 / 1.15<br>0.0 / 0.0 / 5.20 / 0.0<br>7.80 / 4.60 / 0.0 / 0.0 | NZD 14.3k/hardship birth<br>NZD 5.2k/birth (PPL+BestStart)<br>NZD 16.7k/buffered birth |
| **Gate 2 ($J = 2\text{--}3$)**<br>*First 2000 Days* | `4_ECE_Corner_Benefit_Need`<br>`5_Public_ECE_Wraparound`<br>`6_High_Intensity_Public_ECE`<br>`7_Private_Parental_ECE_CashTime` | 12.30<br>0.30<br>0.50<br>15.80 | 2.70<br>13.00<br>0.60<br>18.80 | 0.0 / 0.0 / 0.0 / 2.70<br>0.0 / 0.0 / 13.00 / 0.0<br>0.0 / 0.0 / 0.60 / 0.0<br>**11.80 / 7.00** / 0.0 / 0.0 | NZD 47.6k/corner child<br>**NZD 13.5k/child (Daruich ECE)**<br>NZD 15.8k/high-ECE child<br>**NZD 19.9k/child (Cash+Time)** |
| **Gate 3 ($J = 5$)**<br>*Adol. Gate, 12–14* | `8_Unemp_Stress_Exits124`<br>`9_Public_Schooling_d2`<br>`10_Montessori_Tuakana_Public`<br>`11_Private_Adol_Commit_CashTime` | 13.60<br>8.00<br>1.10<br>16.20 | 2.50<br>5.30<br>6.50<br>19.40 | 0.0 / 0.0 / 0.0 / 2.50<br>0.0 / 0.0 / 5.30 / 0.0<br>0.0 / 0.0 / 6.50 / 0.0<br>**12.10 / 7.30** / 0.0 / 0.0 | NZD 50.9k/crisis teen (Exits 1,2,4)<br>NZD 14.0k/student<br>NZD 11.3k/mentored teen<br>**NZD 20.4k/teen (Cash+Time)** |
| **Gate 4 ($J = 6\text{--}7$)**<br>*Launch, Age 20* | `12_Stunted_Launch_h1_h2`<br>`13_Core_Launch_h3_h5`<br>`14_Thriving_Launch_h6_h7` | 10.00<br>15.60<br>13.00 | 2.20<br>15.50<br>26.20 | 0.0 / 0.0 / 0.40 / 1.80<br>4.50 / 1.80 / 8.20 / 1.00<br>9.80 / 3.40 / 13.00 / 0.0 | Carries Exits 1, 2, 4 into adulthood<br>Core skill launch + Youth Grant $E$<br>Thriving launch + Youth Grant $E$ |
| **Gate 5 ($J = 10$)**<br>*Age 30 Ledger* | `15_Age30_Exits124_Burden`<br>`16_Age30_Infra_Base_Health`<br>`17_Age30_GST_Cap_Tax`<br>`18_Age30_PAYE_Income_Tax`<br>`19_Age30_Exit3_Lost_Tax`<br>`20_Age30_Emig_Abroad_Lost_Tax` | 10.00<br>3.90<br>4.20<br>4.40<br>1.80<br>1.10 | 2.70<br>3.90<br>8.20<br>8.90<br>0.90<br>1.30 | **Net Fiscal Balance at Age 30:**<br>`SS0`: **-NZD 5.30k/yr**<br>`SS1`: **+NZD 10.50k/yr**<br>`SS2`: **+NZD 12.40k/yr** | Good Taxes (`Nodes 17+18`) minus Public Outlays (`Nodes 15+16`) swings by **+NZD 15.80k/yr per birth**! |
| **Gate 6 ($J = 11\text{--}16$)**<br>*Career to Ret.* | `21_Career_Exits124_Burden`<br>`22_NZSuper_Infra_Health`<br>`23_GST_Cap_Estate_Tax_Pool`<br>`24_Career_PAYE_Income_Tax`<br>`25_Career_Exit3_Lost_Tax`<br>`26_Perm_Abroad_Lost_Tax` | 7.10<br>5.40<br>8.40<br>1.70<br>1.60<br>1.10 | 2.00<br>6.50<br>16.90<br>5.30<br>1.10<br>1.50 | **Net Fiscal Balance to Ret.:**<br>`SS0`: **-NZD 2.40k/yr**<br>`SS1`: **+NZD 13.70k/yr**<br>`SS2`: **+NZD 16.80k/yr** | Good Taxes (`Nodes 23+24`) minus Outlays (`Nodes 21+22`) swings by **+NZD 16.10k/yr per birth**! |

---

### 2.4 The 2050 Sovereign Debt-Sinking & Public Reinvestment Protocol (`FiscalLedger.Protocol_2050_Summary`)
*Source Function: `Build_Custom_Protocol_2050_Table` in `Plot_ChildFiscal_2Panel_SSankey.m` (`Cohort_Births = 60,000/yr`, `r_bond_yield = 0.042`, `mult_reinvest = 1.65`, `Horizon_2050 = 25 yrs`)*

| Lifecycle Horizon & Phase | Good Taxes (`_kNZD/yr`) | Exits 1,2,4 + Base Outlays (`_kNZD/yr`) | Net Fiscal Balance $\Omega_{\mathrm{fiscal}}$ (`_kNZD/yr`) | 50% Debt-Sinking Allocation $\Omega_{\mathrm{debt}}$ (`_kNZD/yr`) | Annual Interest Saved (`_kNZD/yr`) | 50% Reinvestment Pool $\Omega_{\mathrm{reinv}}$ (`_kNZD/yr`) | Reinvestment Societal Value at 1.65x (`_kNZD/yr`) | 25-Yr Cumulative Sovereign Debt Retired per Cohort (`_MNZD`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`Age30_SS0`** | 8.60 | 13.90 | **-5.30** | 0.00 | 0.00 | 0.00 | 0.00 | NZD 0M |
| **`Age30_SS1`** | 17.10 | 6.60 | **+10.50** | 5.25 | 0.22 | 5.25 | 8.66 | **NZD 13,658M** (NZD 13.66B) |
| **`Age30_SS2`** | 18.60 | 6.20 | **+12.40** | 6.20 | 0.26 | 6.20 | 10.23 | **NZD 16,130M** (NZD 16.13B) |
| **`CareerRet_SS0`** | 10.10 | 12.50 | **-2.40** | 0.00 | 0.00 | 0.00 | 0.00 | NZD 0M |
| **`CareerRet_SS1`** | 22.20 | 8.50 | **+13.70** | 6.85 | 0.29 | 6.85 | 11.30 | **NZD 17,821M** (NZD 17.82B) |
| **`CareerRet_SS2`** | 24.80 | 8.00 | **+16.80** | 8.40 | 0.35 | 8.40 | 13.86 | **NZD 21,853M** (NZD 21.85B) |

---

## 3. Core Model Output Tables Answer Key (Tables 1 to 12)

### 3.1 Table 1: Multiphase 4-Region Daruich (2018) & Lee-Seshadri (2019) Welfare Decomposition (`SS0 -> SS1 -> SS2`)
*Source File: [`Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv) (Generated by `WelfareDecomposition_4Region.m` with `Active_Phases = {'SS0', 'SS1', 'SS2'}`)*

| Row Label (`T1`) | `Rural_CE_Pct` | `Small_CE_Pct` | `Large_CE_Pct` | `Auckland_CE_Pct` | Share of Phase Gain from Endogenous Intergenerational Matrix |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **`SS1_1_ShortRun_PE`** | **+1.78%** (`1.7848`) | **+1.16%** (`1.1598`) | **+0.60%** (`0.5954`) | **+0.47%** (`0.4736`) | Direct policy levers ($G_{\mathrm{ECE},1}=0.110, G_{\mathrm{ECE},2}=0.085, E=0.065, T_k$) at fixed $\mathrm{SS0}$ prices & $\mu_1$ |
| **`SS1_2_LongRun_GE_ExoSkills`** | **+2.62%** (`2.6224`) | **+3.14%** (`3.1425`) | **+3.77%** (`3.7699`) | **+4.56%** (`4.5634`) | Guvenen firm reallocation ($w_k \uparrow$) + housing cooling ($Q_{\mathrm{Akl}} -7.5\%$) at fixed $\mu_1^{\mathrm{SS0}}$ |
| **`SS1_3_LongRun_GE_EndoIntergen`** | **+8.13%** (`8.1324`) | **+10.41%** (`10.4120`) | **+12.48%** (`12.4750`) | **+15.44%** (`15.4410`) | **67.8% (`Rural`), 69.8% (`Small`), 69.8% (`Large`), 70.4% (`Auckland`)** from $\mu_1^{\mathrm{SS1}}$ shift |
| **`SS2_1_ShortRun_PE`** | **+4.85%** (`4.8547`) | **+4.49%** (`4.4897`) | **+3.76%** (`3.7606`) | **+3.48%** (`3.4761`) | Adds `-3.5 pp` PAYE tax cut ($\tau_l: 22.0\% \to 18.5\%$), $G_{\mathrm{ECE},1}=0.130, G_{\mathrm{ECE},2}=0.105, E=0.080$ |
| **`SS2_2_LongRun_GE_ExoSkills`** | **+7.12%** (`7.1191`) | **+8.82%** (`8.8232`) | **+9.71%** (`9.7149`) | **+10.60%** (`10.6030`) | Adds 2050 Debt-Sinking ($\Delta r = -0.006$), 1.65x infra wage lift ($w_k +6.8\%\text{ to }+9.6\%$), $Q_{\mathrm{Akl}} -10.5\%$ |
| **`SS2_3_LongRun_GE_EndoIntergen`** | **+14.28%** (`14.2820`) | **+13.66%** (`13.6610`) | **+22.17%** (`22.1740`) | **+26.03%** (`26.0270`) | **50.1% (`Rural`), 35.4% (`Small`), 56.2% (`Large`), 59.3% (`Auckland`)** from $\mu_1^{\mathrm{SS2}}$ shift |

#### 3.1.1 Seven-Factor Attribution of Phase 2 (`SS2`) Long-Run Welfare Gains (`Plot_SS2_7Factor_StackedAttribution.m`)
*Source Script: `Plot_SS2_7Factor_StackedAttribution.m`; Sibling Figures: [`Fig1_SS2_7Factor_StackedAttribution_National_Dunedin_22.png`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Fig1_SS2_7Factor_StackedAttribution_National_Dunedin_22.png), `Fig1_SS2_7Factor_AreaTrajectory_National_Dunedin_22.png`, and `Fig1_SS2_7Factor_RegionalBars_All4_Dunedin_22.png`*

To provide an exhaustive accounting of the **+14.28% (`Rural`), +13.66% (`Small`), +22.17% (`Large`), +26.03% (`Auckland`), and +20.49% (`National`)** long-run Consumption-Equivalent (CE %) welfare gains in row `SS2_3_LongRun_GE_EndoIntergen` of `T1`, we partition the total multiphase payoff into seven orthogonal structural engines—explicitly isolating **Factor 4: Sovereign Debt-Sinking & Reduced Debt-Service Interest** for fiscal and bond-market hawks:

| Attribution Engine (`Plot_SS2_7Factor_StackedAttribution.m`) | Primary Model Parameters & Literature Channel | `Rural` (`+14.28%`) | `Small` (`+13.66%`) | `Large` (`+22.17%`) | `Auckland` (`+26.03%`) | `National` (`+20.49%`) | Share of National `SS2` Prize |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Reduced Deadweight Losses & Acute Exits 1, 2, 4** | Eliminating $i_c=0$ corners ($\bar{g}_{\mathrm{ECE}}$; Ferriere et al. 2025), `Transfer_Geo`, & slashing Dunedin $h_1\text{--}h_2$ care/hospital/justice burdens (Caspi et al. 2016) | +2.25% | +2.15% | +2.35% | +2.55% | **+2.35%** | **11.5%** |
| **2. Housing Affordability & Youth Capital Seeding** | Cooling land overvaluation ($Q_{\mathrm{Akl}} -10.5\%$; Hirano & Toda 2025), lower renter user cost $r_{h,k}^{\mathrm{rent}}$ (Kiyotaki et al. 2024), & Youth Grant $E=0.080$ | +1.15% | +1.35% | +2.30% | +3.05% | **+2.10%** | **10.2%** |
| **3. Productive Firm Capital Reallocation & 2050 Infra** | Guvenen et al. (2023) firm equity shift ($\Gamma_k \to z_{h,k}$ raising TFP $Z_k$) + 50% Public Infrastructure Reinvestment Pool ($\mu_{\mathrm{infra}} = 1.65$) | +1.20% | +1.30% | +2.00% | +2.40% | **+1.85%** | **9.0%** |
| **4. Sovereign Debt-Sinking & Reduced Debt-Service Interest** | 50% Debt-Sinking Fund ($\Omega_{\mathrm{debt}}$ retiring NZD 17.82B–21.85B debt/wave), lower debt service $r_t d_t \downarrow$, & bond crowding-out relief ($\Delta r = -0.006$) | **+0.90%** | **+0.95%** | **+1.35%** | **+1.55%** | **+1.25%** | **6.1%** |
| **5. Brain-Drain Reversal, Workforce Retention & Cohesion** | $4 \times 5$ Gumbel retention of $h_5\text{--}h_7$ youth (`Nat_Emig`: 10.93% down to 7.60%), lower churn, & Social Cohesion $S_t: 100 \to 126$ in $u_{\mathrm{rel}}$ | +1.95% | +1.85% | +3.80% | +4.45% | **+3.25%** | **15.9%** |
| **6. Demographic Strength, Fertility & NZ Super Dividend** | Cooperative bargaining TFR recovery ($1.66 \to 1.98$; Doepke et al. 2022) & `-3.32 pp` Super solvency dividend funding the `-3.5 pp` `SS2` PAYE cut | +2.45% | +2.40% | +3.15% | +3.45% | **+2.95%** | **14.4%** |
| **7. Human Capital & Dynastic Skill Productivity** | Cunha-Heckman First 2000 Days ($\varphi_1=0.35, \varphi_2=-0.95$), Montessori / *Tuakana–Teina* & Graeme Dingle mentoring, & Daruich $\mu_1^{\mathrm{SS2}}$ shift | +4.38% | +3.66% | +7.22% | +8.58% | **+6.74%** | **32.9%** |
| **Total Phase 2 (`SS2`) Long-Run Welfare Gain (CE %)** | **Row 6 of `T1` (`SS2_3_LongRun_GE_EndoIntergen`)** | **+14.28%** | **+13.66%** | **+22.17%** | **+26.03%** | **+20.49%** | **100.0%** |

* **Literature Defense of Factor 4 (Sovereign Debt-Service Interest Relief):**
  1. *Direct Crown Budget Relief ($r_t d_t \downarrow$):* Following Ferriere et al. (2025, Sec. 4.2 & 6.1), where government debt service $r_t d_t$ absorbs ~2.8%–3.1% of public outlays in the intertemporal budget constraint $\left(1 + r_t\right) d_t + G_t + T_t = d_{t+1} + \mathrm{Taxes}_t$, locking 50% of post-breakeven surpluses ($\Omega_{\mathrm{debt},g}$) into sovereign debt retirement saves **NZD 0.22k to NZD 0.35k/yr per worker** in deadweight bond interest.
  2. *Domestic Bond-Market Crowding-In ($\Delta r = -60\text{ bps}$):* In the national asset market clearing condition $\sum_k \omega_{F,k} \int \left(k_k - a_f\right) d\Gamma_k + B_{\mathrm{gov}} = \sum_k \omega_{HH,k} \int a_{\mathrm{fin}} d\mu_k$, retiring $B_{\mathrm{gov}}$ reduces sovereign crowding-out of private capital, lowering equilibrium interest rates (`r_delta = -0.006`) and reducing SME credit and young-homeowner mortgage costs (Kiyotaki et al., 2024, Fig. 9).
  3. *Stemming External Debt-Service Leakage:* In a small open economy with net foreign debt obligations $B_t^{*} / R_t$ (Kiyotaki et al., 2024, Eq. 29), retiring public debt prevents domestic tax revenues from leaking abroad to foreign bondholders.

![7-Factor Stacked Attribution of SS2 Welfare Gains](./Output_NZ_4Region_Intergen/Fig1_SS2_7Factor_StackedAttribution_National_Dunedin_22.png)

---

### 3.2 Table 2: Labrousse & Perdereau (2026) Spatial Wealth Quintile Welfare Gains (CE %)
*Source File: [`Table2_4Region_LabroussePerdereau_SpatialQuintiles.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table2_4Region_LabroussePerdereau_SpatialQuintiles.csv)*

| Wealth Quintile | `Rural_CE_Pct` | `Small_CE_Pct` | `Large_CE_Pct` | `Auckland_CE_Pct` | Primary Mechanism Driving Quintile Payoff |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **`Q1_Bottom20` (Hardship Renters)** | +14.8% | +16.2% | +19.5% | +22.4% | Elimination of $i_c=0$ corner via universal $G_{\mathrm{ECE}}$, `Transfer_Geo`, Youth Grant $E$, & rent relief |
| **`Q2_20to40`** | +10.2% | +12.1% | +14.3% | +17.1% | Montessori / *Tuakana–Teina* mentoring + lower metropolitan rental user cost $r_{h,k}$ |
| **`Q3_Middle20`** | +7.9% | +9.8% | +11.6% | +14.2% | Wage lift ($w_k \uparrow$) + accelerated homeownership entry ($\xi_k \uparrow$) + `SS2` PAYE cut |
| **`Q4_60to80`** | +5.4% | +6.9% | +8.2% | +10.1% | Higher enterprise equity returns & child skill compounding outweigh modest property cooling |
| **`Q5_Top20` (Property/Business Owners)** | +2.1% | +2.8% | +3.4% | +4.2% | High-$z_h$ firm reallocation gain + relational utility $u_{\mathrm{rel}}$ (children retained in NZ) offset $\tau_b$ |

---

### 3.3 Table 3 & Table 3B: Kiyotaki et al. (2024) Housing Tenure Cleavage & Steady-State Summary
*Source Files: [`Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv) and [`Table3B_4Region_Abroad_SteadyState_Summary.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table3B_4Region_Abroad_SteadyState_Summary.csv)*

| Tenure / Generation Group (`T3`) | `Rural_CE_Pct` | `Small_CE_Pct` | `Large_CE_Pct` | `Auckland_CE_Pct` | Regional House Price $Q_k$ (`SS0 -> SS1 -> SS2`) & Young Ownership |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **`1_Young_Renters_20to44`** | +9.8% | +11.4% | +13.9% | +16.4% | $Q_{\mathrm{Rural}}: 1.05 \to 1.04 \to 1.03$; Young ownership: $58.0\% \to 64.5\%$ |
| **`2_Young_Leveraged_Owners`** | +4.2% | +5.1% | +6.0% | +6.9% | $Q_{\mathrm{Small}}: 1.40 \to 1.36 \to 1.34$; Young ownership: $49.0\% \to 57.2\%$ |
| **`3_Older_Retirees_Landlords_65plus`** | -1.1% | -1.8% | -2.5% | -3.4% | $Q_{\mathrm{Large}}: 2.05 \to 1.95 \to 1.90$; $Q_{\mathrm{Akl}}: 3.10 \to 2.87 \to 2.77$ (Ownership: $28.0\% \to 41.2\%$) |

---

### 3.4 Tables 4, 5, & 6 (and 12A–12C): Lee & Seshadri (2019) Multi-Stage Counterfactuals
*Source Files: [`Table4_4Region_LeeSeshadri_IGE.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table4_4Region_LeeSeshadri_IGE.csv), [`Table5_4Region_LeeSeshadri_Output_Welfare.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table5_4Region_LeeSeshadri_Output_Welfare.csv), and [`Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv)*

| Counterfactual Regime | National Long-Run IGE | `Auckland` Long-Run IGE | Variance of LFE Explained at Age 20 (`Auckland`) | Long-Run Output $\Delta \bar{E}_{\mathrm{LR}}$ (`Rural` / `Auckland`) | Long-Run Welfare `CE_LR` (`Auckland`) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline` (`SS0`)** | 0.350 (`0.441` unadjusted) | 0.497 | 71.74% (46.77% by $h_1$ alone) | 0.00% / 0.00% | 0.00% |
| **`P0_Early_0to5` (First 2000 Days)** | 0.233 (-33.4%) | 0.489 | 71.31% (45.77% by $h_1$) | +1.81% / +1.10% | +0.68% (Stage-1 alone) |
| **`P1P2_Late_6to17` (Late Schooling Only)** | 0.338 (-3.4%) | 0.488 | 70.82% (44.64% by $h_1$) | +0.81% / +0.96% | +0.24% (Fails to fix early stunting) |
| **`BN_FrontLoad` (Budget-Neutral Shift)** | 0.281 (-19.7%) | 0.485 | 69.85% (`Large`) | +0.26% (`Small`) | +0.21% (`Large`, zero net fiscal cost) |
| **`P0_Plus_GrantE` (Full Package + Grant $E$)** | **0.218 (-37.7%)** | **0.482** | **68.11% (`Small`) / 44.8% Nat.** | **+7.08% / +5.08%** | **+6.52% (PE) / +15.44% (Full GE)** |

---

### 3.5 Tables 7 & 8: Cooperative Childcare Bargaining, Fertility, & NZ Super Solvency
*Source Files: [`Table7_4Region_Endogenous_TFR_DiffFertility.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table7_4Region_Endogenous_TFR_DiffFertility.csv) and [`Table8_4Region_Fertility_Stunting_NZSuperTax.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table8_4Region_Fertility_Stunting_NZSuperTax.csv)*

| Region | Baseline TFR (`SS0`) | Reformed TFR (`SS1`) | Low- vs. High-Skill Fertility Gap (`SS0 -> SS1`) | Old-Age 65+ Dependency Ratio (`SS0 -> SS1`) | Required PAYE Tax Rate for NZ Super Solvency (`SS0 -> SS1`) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **`Rural`** | 1.88 | 2.06 | +0.42 $\to$ +0.18 | 0.540 $\to$ 0.452 | 29.10% $\to$ 25.85% (-3.25 pp) |
| **`Small`** | 1.76 | 1.99 | +0.38 $\to$ +0.15 | 0.525 $\to$ 0.438 | 28.60% $\to$ 25.25% (-3.35 pp) |
| **`Large`** | 1.57 | 1.86 | +0.35 $\to$ +0.13 | 0.502 $\to$ 0.415 | 27.95% $\to$ 24.60% (-3.35 pp) |
| **`Auckland`** | 1.49 | 1.80 | +0.39 $\to$ +0.14 | 0.498 $\to$ 0.408 | 27.65% $\to$ 24.30% (-3.35 pp) |
| **`National`** | **1.66** | **1.93** | **+0.38 $\to$ +0.15 (-61%)** | **0.514 $\to$ 0.425** | **28.22% $\to$ 24.90% (-3.32 pp)** |

#### 3.5.1 Why Keeping NZ Super at Age 65 Outperforms Raising the Eligibility Age to 67 or 70 (`Plot_Fertility_SuperSolvency_2Panel.m`)
*Source Script: `Plot_Fertility_SuperSolvency_2Panel.m`; Sibling Figures: [`FigFert_2Panel_National_Dunedin_22.png`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/FigFert_2Panel_National_Dunedin_22.png), `FigFert_TFR_National_Dunedin_22.png`, and `FigFert_SuperSolvency_National_Dunedin_22.png`*

To benchmark our Generational Plan against conventional fiscal austerity proposals that raise the New Zealand Superannuation eligibility age from 65 ($J_r = 10$ at $\Delta t = 5$; $J_r = 16$ at $\Delta t = 3$) to **Age 67** or **Age 70** without addressing early-childhood stunting or youth emigration, Panel B of `Plot_Fertility_SuperSolvency_2Panel.m` evaluates four 60-year solvency trajectories:

| Superannuation Solvency Policy Regime (2026–2086) | Eligibility Age | 65+ Dependency Ratio (Yr 60) | Fiscal Substitution Leak into Disability/Hardship Support (Ages 65–69) | Terminal Required PAYE Tax Rate (Yr 60) | Distributional & Equity Impact on Māori, Pasifika, & Manual Workers ($h_1\text{--}h_3$) |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **1. Status Quo Baseline (`SS0`, No Reform)** | **Age 65** | 51.4% (`0.514`) | 0.0% (Baseline) | **28.22%** (+6.22 pp hike) | Unsustainable PAYE tax hike crushes working families & accelerates brain drain |
| **2. Alternative A: Raise Super Age to 67 (No Child/Tax Reform)** | **Age 67** | 46.8% *(adj.)* | **38.0% leak** into Supported Living, Jobseeker & acute health | **26.85%** (+4.85 pp hike) | Regressive penalty on manual/rural workers; fails to stop long-run tax climb |
| **3. Alternative B: Raise Super Age to 70 (Regressive Cut)** | **Age 70** | 40.2% *(adj.)* | **45.0% leak** into Supported Living, accommodation & hospital care | **25.55%** (+3.55 pp hike) | Confiscates 30%–40% of retirement years for Māori, Pasifika & manual workers |
| **4. Our Generational Plan (`SS1 -> SS2`, Keep Age 65!)** | **Age 65** | **42.5%** (`0.425`) | **0.0% leak** (Healthier, higher-skill workforce) | **24.45%–24.90%** (-3.32 to -3.77 pp dividend) | **Protects Age 65 retirement dignity while achieving a LOWER tax rate than Age 70!** |

![Fertility Recovery and NZ Super Solvency vs Age 67 and 70](./Output_NZ_4Region_Intergen/FigFert_2Panel_National_Dunedin_22.png)

---

### 3.6 Tables 9 & 10: Dynamic Regional Population Shares & Brain-Drain Closure (60-Year Path)
*Source Files: [`Table9_4Region_Dynamic_Population_Shares.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv) and [`Table10_4Region_Abroad_BrainDrain_Cohesion.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table10_4Region_Abroad_BrainDrain_Cohesion.csv)*

| Transition Year | `PopPct_Rural` | `PopPct_Small` | `PopPct_Large` | `PopPct_Auckland` | `Emig_Large_Pct` | `Emig_Auckland_Pct` | `Nat_Emig_Abroad_Pct` | `Social_Cohesion_Index_St` (`SS1` / `SS2`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Year 0 (2026 Base)** | 16.00% | 24.00% | 25.90% | 34.10% | 23.41% | 19.29% (7.02% net) | 10.93% | 100.0 (104.3) |
| **Year 6 ($t = 2$)** | 15.62% | 23.68% | 26.04% | 34.66% | 21.55% | 17.65% (6.46% net) | 10.07% | 104.8 |
| **Year 15 ($t = 5$)** | 15.18% | 23.29% | 26.21% | 35.32% | 19.70% | 16.12% (5.91% net) | 9.22% | 108.5 |
| **Year 24 ($t = 8$)** | 14.85% | 22.98% | 26.35% | 35.82% | 18.92% | 15.48% (5.67% net) | 8.86% | 112.0 (`SS1`) |
| **Year 36 ($t = 12$)** | 14.58% | 22.74% | 26.46% | 36.22% | 18.61% | 15.21% (5.58% net) | 8.72% | 119.5 |
| **Year 57 ($t = 19$)** | **14.39%** | **22.56%** | **26.54%** | **36.51%** | **18.26%** | **14.92% (5.47% net)** | **8.56%** | **126.0 (`SS2`)** |

---

## 4. Methodological Defense & Accounting Guardrails

1. **Strict Separation of the Crown Fiscal Lens and the Economy-Wide GDP Lens (Counting Rule #1):**
   Avoided public service outlays (Oranga Tamariki care at NZD 180k/yr, acute hospital nights, youth/adult justice, and main welfare benefit transfers $T_k$) belong strictly to the **Crown Fiscal Ledger**, whereas additional adult gross output $\Delta Y_t$ belongs to the **Economy-Wide GDP Lens**. Benefit transfers are fiscal redistributions (not net additions to GDP), and public tax revenue on $\Delta Y_t$ ($\approx 28.8\%$ of $\Delta \mathrm{GDP}$) is reported inside the Fiscal Ledger and **never added to GDP**.
2. **Global Dual-Regime Visual Scaling in the 6-Gate Fiscal Sankey:**
   Because childhood developmental investments (`Gates 1–3`, totaling NZD 18.8k–35.1k/yr) and adult tax/pension flows (`Gates 5–6`, totaling NZD 25.9k–30.7k/yr) operate on different institutional ledgers, `Plot_ChildFiscal_2Panel_SSankey.m` enforces a **uniform vertical dollar-to-pixel scale across Gates 1–3** and a **uniform adult fiscal scale across Gates 5–6**, separated by a dual-wave scale break at **Gate 4 (Age 20 Adult Skill Launch, $X = 4.0$)**.
3. **Defending Warm-Glow Bequests + Exact Intergenerational Transition Matrix vs. Outer Dynastic VFI:**
   As established by De Nardi (2004) and Daruich (2018, Sec. 6), 75% of the long-run welfare gain from early childhood investment operates through the shift in the **stationary distribution of parent states $\mu_k\left(a, h, z, j\right)$** across generations rather than changes in the curvature of the continuation value function. Because `Build_IntergenTransitionMatrix.m` maps exact optimal child investments $i_c^{*}\left(a_p, h_p, z_p, k\right)$ and net-of-tax estates $\left(1 - \tau_b\right)a^{\prime *}_j\left(k\right)$ into the next generation's initial distribution `jequaloneDist` ($\mu_{1,k}\left(a_1, h_1, z_1\right)$), our GPU-vectorized architecture captures 100% of this dynastic general-equilibrium feedback loop without adding parent-child strategic gaming states.

---

## 5. Actuarial Continuation Valuation, Credibility-Weighted Belief Blending, & Historical Precedents Answer Key

### 5.1 Cross-Reference of Terminology, NZ Treasury CBAx Rules, and Sibling Figure Naming Convention
* **Three Equivalent Institutional Names for the Forward Discounting Operator:**
  1. *Public Finance & NZ Treasury CBAx:* **Incidence-Based Lifetime Valuation** (or *Present Value of Future Incidence*), which books the discounted lifetime cost avoidance in the year a cohort verifiably exits hardship rather than waiting for annual cash flows to fall due over 40 years.
  2. *Crown Balance Sheet Accounting (ACC / Social Investment Agency):* **Actuarial Liability Release** (or *Forward Liability Valuation*), directly analogous to the Accident Compensation Corporation (ACC) Outstanding Claims Liability (NZD 63.6B on the Crown balance sheet).
  3. *Dynamic Programming / OLG Markov Transition Suite:* **Conditional Continuation Valuation** $\mathcal{V}_{k,t_0}^{\left(L\right)}\left(H\right)$, evaluated on the solved sequence of transition distributions `StationaryDist_t` ($\mu_{k,t}\left(a, h, z, j\right)$) and firm equity distributions $\Gamma_{k,t}\left(a_f, z_f\right)$.
* **Canonical Sibling Figure Naming Convention (`Output_NZ_4Region_Intergen/`):**
  * **Combined 2-Panel Figure (Panel A Fiscal + Panel B Economy-Wide GDP):** `Fig_Actuarial_2Panel_<Region>_<Anchor>.png` (e.g., `Fig_Actuarial_2Panel_National_Dunedin_22.png`, `Fig_Actuarial_2Panel_Auckland_Dunedin_22.png`).
  * **Panel A Sibling (Crown Fiscal Ledger):** `Fig_Actuarial_Fiscal_<Region>_<Anchor>.png` (e.g., `Fig_Actuarial_Fiscal_National_Dunedin_22.png`, `Fig_Actuarial_Fiscal_Auckland_Dunedin_22.png`).
  * **Panel B Sibling (Economy-Wide GDP Lens):** `Fig_Actuarial_WideGDP_<Region>_<Anchor>.png` (e.g., `Fig_Actuarial_WideGDP_National_Dunedin_22.png`, `Fig_Actuarial_WideGDP_Auckland_Dunedin_22.png`).
  * **All-4-Region Spatial Dashboard & Year 5 Audit Bar Chart:** `Fig_Actuarial_Dashboard_All4_<Anchor>.png`, `Fig_Actuarial_Year5Audit_All4_<Anchor>.png`, `Fig_Actuarial_Year5Audit_Fiscal_All4_<Anchor>.png`, and `Fig_Actuarial_Year5Audit_WideGDP_All4_<Anchor>.png`.

### 5.2 Exact Conditional Continuation Equations Justifying the Findings
At transition period $t_0$ (in years, $t_0 \in \lbrace 5, 10, \dots, 60 \rbrace$), let $\mathcal{C}_{k,\mathrm{realized}}^{\left(L\right)}\left(t_0\right)$ denote the cumulative realized cash flow integrated via the trapezoidal rule (`cumtrapz`) from Year 0 to Year $t_0$ under lens $L \in \lbrace \mathrm{Sav}, \mathrm{Fiscal}, \mathrm{Econ} \rbrace$. Annual flows are interpolated onto a 1-year grid ($y \in \lbrace 0, 1, \dots, 100 \rbrace$) via piecewise cubic Hermite interpolation (`pchip`). The **Actuarial Continuation Valuation** $\mathcal{V}_{k,t_0}^{\left(L\right)}\left(H\right)$ over a rolling $H = 25$-year recognition window for region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$ is:

$$\mathcal{V}_{k, t_0}^{\left(L\right)}\left(H; r_{\mathrm{disc}}\right) = \mathcal{C}_{k, \mathrm{realized}}^{\left(L\right)}\left(t_0\right) + \left(1 - \alpha_{\mathrm{attr}}\right) \Phi_{\mathrm{pipe}}\left(t_0\right) \sum_{s=1}^{H} \left(\frac{1 + g_{\mathrm{cost}}}{1 + r_{\mathrm{disc}}}\right)^{s} \psi_{k,\mathrm{persist}}^{s} \cdot \mathbb{E}_{t_0}\left\lbrack \Delta \mathrm{Flow}_{k, t_0 + s}^{\left(L\right)} \;\middle|\; \mu_{k, t_0} \right\rbrack$$

and the national aggregate is obtained by exact spatial summation across the four regional ledgers:

$$\mathcal{V}_{\mathrm{National}, t_0}^{\left(L\right)}\left(H; r_{\mathrm{disc}}\right) = \sum_{k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace} \mathcal{V}_{k, t_0}^{\left(L\right)}\left(H; r_{\mathrm{disc}}\right)$$

where:
* $\Phi_{\mathrm{pipe}}\left(t_0\right) = \min\left(1.0, \frac{t_0}{15.0}\right)$ (`pipeline_maturity`) measures the fraction of the 0–15 childhood age pipeline that has completed or entered active treatment by year $t_0$ (reaching 1.0 at Year 15 when all childhood brackets are active).
* $\psi_{k,\mathrm{persist}}^{s}$ (`psi_persist`) is the region-specific Stage-2-to-Adulthood Markov skill-retention conditioning factor (`psi_base_map`: Rural = 0.984, Small = 0.984, Large = 0.986, Auckland = 0.987), reflecting the probability under $\Pi_h\left(h^{\prime} \vert h, i_{c,2}\right)$ and dynamic complementarity ($\varphi_2 = -0.95$) that a child exiting hardship at age 5 remains out of the stunted tier $h_1\text{--}h_2$ at age $5 + s$.

### 5.3 Year 5 Parliamentary Audit ($t = 1$) & Year 60 Convergence by Region (`Dunedin_22` vs. `MetroSqueeze_GUiNZ`)
*Source Script: `Plot_ActuarialContinuationValuation.m` (`Out_Dunedin` console verification table)*

| Region (`RegionOption`) | Base Pop / Firm Share (`PTypeWeights`) | Yr 5 Cum. Outlay (`Cum_Inv`) | Yr 5 Cash Fiscal (`Cum_TotFisc`) | Yr 5 Booked Cost Avoidance Alone (2.0% Real) | Yr 5 Booked Total Fiscal Return (2.0% / 8.0%) | Yr 5 Realized Cash GDP (`Cum_dGDP`) | Yr 5 Booked 25-Yr GDP Prize (2.0% / 8.0%) | Yr 60 Realized / Booked GDP Prize (2.0% Real) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`Rural`** | 16.0% / 15.0% | NZD 1.42B | NZD 0.65B | **NZD 1.48B** | **NZD 4.61B** / NZD 2.39B | NZD 1.99B | **NZD 10.87B** / NZD 6.13B | NZD 196.4B / **NZD 270.3B** |
| **`Small`** | 24.0% / 23.0% | NZD 2.16B | NZD 1.04B | **NZD 2.33B** | **NZD 7.32B** / NZD 3.79B | NZD 3.17B | **NZD 17.31B** / NZD 9.76B | NZD 312.7B / **NZD 430.3B** |
| **`Large`** | 25.9% / 26.9% | NZD 2.38B | NZD 1.33B | **NZD 2.79B** | **NZD 9.43B** / NZD 4.88B | NZD 4.12B | **NZD 23.05B** / NZD 12.96B | NZD 406.4B / **NZD 568.7B** |
| **`Auckland`** | 34.1% / 35.1% | NZD 3.24B | NZD 1.95B | **NZD 4.06B** | **NZD 13.90B** / NZD 7.18B | **NZD 6.03B** | **NZD 34.17B** / **NZD 19.20B** | **NZD 595.2B** / **NZD 826.5B** |
| **`National` (`Dunedin_22`)** | **100.0%** | **NZD 9.19B** | **NZD 4.98B** | **NZD 10.66B** | **NZD 35.25B / NZD 18.25B** | **NZD 15.30B** | **NZD 85.40B / NZD 48.05B** | **NZD 1,510.7B / NZD 2,095.8B** |
| **`National` (`MetroSqueeze_GUiNZ`)** | **100.0%** | **NZD 9.19B** | **NZD 5.14B** | **NZD 13.69B** | **NZD 39.14B / NZD 20.21B** | **NZD 15.30B** | **NZD 89.95B / NZD 50.18B** | **NZD 1,634.5B / NZD 2,270.3B** |

### 5.4 Credibility-Weighted Belief Blending & Multiphase Policy Announcement Answer Key (`TransPath_4Region_Master.m`)
* **The Credibility Weight $\lambda_{\mathrm{cred}}\left(t\right) \in \lbrack 0, 1\rbrack$ and Perceived Continuation Value $\tilde{V}_{k,t+1}$:**
  Let $V_{k,t+1}^{\mathrm{perm\,SS1}}$ denote the backward-induction continuation value if agents believe Phase 1 (`SS1`) parameters remain frozen forever, and let $V_{k,t+1}^{\mathrm{full\,SS2}}$ denote the continuation value under perfect foresight of the Phase 2 (`SS2`) `-3.5 pp` PAYE tax-relief and infrastructure dividend at transition seam $T_1$ (Year 25). At every transition period $t < T_1$, households and firms evaluate the credibility-weighted continuation value:

$$\tilde{V}_{k,t+1}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right) = \left(1 - \lambda_{\mathrm{cred}}\left(t\right)\right) V_{k,t+1}^{\mathrm{perm\,SS1}}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right) + \lambda_{\mathrm{cred}}\left(t\right) V_{k,t+1}^{\mathrm{full\,SS2}}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right)$$

  where the time-$t$ credibility weight $\lambda_{\mathrm{cred}}\left(t\right)$ evolves between the announcement date $t_{\mathrm{ann}}$ and the Phase-2 enactment date $T_1$ according to:

$$\lambda_{\mathrm{cred}}\left(t\right) = \begin{cases}
0 & \text{if } t < t_{\mathrm{ann}} \\
\bar{\lambda}_0 + \left(1 - \bar{\lambda}_0\right)\left(\frac{t - t_{\mathrm{ann}}}{T_1 - t_{\mathrm{ann}}}\right)^{\kappa_{\mathrm{cred}}} & \text{if } t_{\mathrm{ann}} \le t < T_1 \\
1 & \text{if } t \ge T_1
\end{cases}$$

* **Three Nested Policy Announcement Regimes in `TransPath_4Region_Master.m`:**
  1. **Regime A — Unanticipated Sequential Reform (MIT Shock at $T_1$, $\lambda_{\mathrm{cred}}\left(t\right) = 0$ for $t < T_1$):** Agents solve Phase 1 believing `SS1` is permanent. At $t = T_1$ (Year 25), the Crown observes the realized cash surplus ($\Omega_{\mathrm{reform}} > 0$) and enacts `SS2` as an unanticipated fiscal dividend.
  2. **Regime B — Fully Credible Pre-Announced Multiphase Plan ($t_{\mathrm{ann}} = 1, \bar{\lambda}_0 = 1.0$):** Full commitment from Day 1 maximizes immediate youth retention ($P_{\mathrm{emig},t} \downarrow$ at $t = 1$) as 20-to-35-year-old graduates price in future career PAYE tax relief ($\tau_l = 18.5\%$).
  3. **Regime C — Earned Fiscal Credibility via the Year 5 Actuarial Audit ($\bar{\lambda}_0 = 0.25, \kappa_{\mathrm{cred}} > 0$):** Private agents initially discount the Phase-2 tax-cut promise ($\bar{\lambda}_0 = 0.25$). However, when the **Year 5 Parliamentary Actuarial Audit (`Plot_ActuarialContinuationValuation.m`)** verifies NZD 35.25B in recognised fiscal returns (3.84x cumulative outlays) and NZD 10.66B in direct cost avoidance alone, $\lambda_{\mathrm{cred}}\left(t\right)$ surges upward—accelerating skilled youth retention (`Emig_Large_Pct`: 23.41% down to 18.26%; `Nat_Emig_Abroad_Pct`: 10.93% down to 8.56%) and parental Stage-2 engagement fifteen years before the cash tax cut takes effect.

### 5.5 Symbolic Cross-Country Matrix & Empirical Citations for Part VI Historical Precedents

| Historical / International Case | Time Horizon | Primary Policy Instruments Deployed | Corresponding Model Channels (`SS0 -> SS1 -> SS2`) | Observed Empirical Payoff |
| :--- | :---: | :--- | :--- | :--- |
| **Sweden & Finland** (*Nordic Dual-Dividend Model*) | 25–50 Years (1970–2020) | Universal ECE & maternal/infant *Neuvola* clinics (1.6%–2.0% of GDP) + 1993 dual capital/labor tax reform | **Lens 1** ($\Delta G_{\mathrm{ECE}}$) + **Lens 2** female labor supply + **Lens 3** tax modernization | Cut earnings shock variance $\sigma_y^2$ in half (0.14 vs. 0.30 in US); lifted female employment above 80%; top-decile intergenerational mobility |
| **Estonia** (*Small-Economy Digital & Tax Benchmark*) | 25–30 Years (1994–2025) | 0% tax on reinvested enterprise capital + pure Land Value Tax + universal kindergartens & 18-month parental leave | **Lens 3** Guvenen "use-it-or-lose-it" firm shift ($\tau_k \to \tau_a$) + **Lens 1** early skill compression | Ranked #1 in Europe in OECD PISA math/science with minimal socio-economic stunting ($h_1\text{--}h_2$) and top per-capita startup density |
| **New Deal & Post-WWII United States** | 35–45 Years (1935–1980) | High progressive estate/inheritance tax consensus ($\tau_b$) + High School Movement + 1944 GI Bill youth endowment | **Lens 3** estate taxation ($\tau_b$) funding **Lens 1/2** universal schooling & Youth Capital Grant ($E$) | Average schooling rose from 8 to 13 years; multi-fold surge in TFP, mass homeownership, and broad-based real wage growth |
| **Post-War 20th-Century Japan** (*Productive Miracle*) | 25–40 Years (1946–1985) | Dissolution of passive land/estate hoarding + universal *Boshi Kenko Techo* infant health screening & high-standards schooling | **Lens 3** asset de-concentration + **Lens 1** First-2000-Days physical/cognitive readiness ($\theta_c, h_p$) | Lowest infant/child stunting in the world within 1 generation; sustained 8%–10% annual real GDP per capita growth |
| **Viet Nam** (*Front-Loaded Basic Skill Miracle*) | 25–35 Years (1990–2025) | Relentless public focus on maternal/infant nutrition and universal foundational schooling post-*Đổi Mới* | **Lens 1** Cunha-Heckman self-productivity ($\gamma_{1,\mathrm{self}}$) & dynamic complementarity ($\varphi_2 = -0.95$) | Cut child stunting from >50% to <19%; 15-year-old PISA scores match or exceed high-income OECD averages |
| **Ireland** (*Reversing a Century of Youth Brain Drain*) | 25–35 Years (1967–2002) | Universal secondary/technical education + pro-enterprise corporate tax regime | **Lens 2** migration reversal ($\Pi_{\mathrm{mig}}$ retaining $h_6\text{--}h_7$ youth) + **Lens 3** enterprise TFP lift | Reversed 150 years of 20–35 youth emigration into high-skill net return migration; tripled real GDP per capita |
| **Singapore** (*Youth Endowments + Anti-Speculation Housing*) | 30–50 Years (1970–2025) | Universal Child Development Accounts (CDAs) & Edusave youth grants + Additional Buyer's Stamp Duties (ABSD) on speculative property | **Lens 1** ($G_{\mathrm{ECE}} + E$) + **Lens 2/3** curbing primate-city land overvaluation ($Q_k \downarrow$, tenure cutoff $\xi_k$) | Top-tier global PISA human capital alongside >85% domestic homeownership without speculative land crowd-out |
| **Norway & Quebec** (*Sovereign Rule & Self-Financing ECE*) | 10–35 Years (1990–2025) | Norway Sovereign Wealth rule + universal *Barnehage* ECE; Quebec 1997 universal low-cost early childhood care | **Lens 1/2** ($\Delta G_{\mathrm{ECE}} \Rightarrow \ell_f \uparrow, \Delta \mathrm{Tax} \uparrow$) + **Lens 3** (`SS2` 2050 Debt/Endowment rule $\Omega_{\mathrm{reform}}$) | Quebec maternal employment rose +7–8 pp and new tax revenues exceeded 100% of ECE cost; Norway top fiscal solvency & mobility |
| **21st-Century South Korea** (*Cautionary "Seoul Trap"*) | 25 Years (2000–2025) | High schooling investment **without** curbing primate-city housing speculation or private *Hagwon* child-cost pressure | Validates why **Lens 1** fails without **Lens 2/3** housing cooling ($Q_{\mathrm{Akl}} \downarrow$) & public $G_{\mathrm{ECE}}$ | Unchecked Seoul housing squeeze ($Q_k \uparrow$) and private tutoring costs drove Total Fertility Rate down to 0.72–0.75 |
| **Post-1990 Bubble Japan** (*Cautionary Land Overvaluation*) | 30 Years (1990–2020) | Unchecked 1980s urban land and real-estate bubble crowding out enterprise credit alongside low support for working mothers | Validates Hirano-Toda (2025) land-bubble drag ($G_k > R$) in **Lens 2/3** when property hoarding is untaxed | 1991 land-bubble collapse triggered 30 years of balance-sheet stagnation, low female labor participation, and rapid aging |
| **Scotland** (*Devolved Wellbeing & Early-Years Reform*) | 10 Years (2017–2026) | *Child Poverty Act* (<10% target) + *Scottish Child Payment* (GBP 28.20 $\to$ 40/wk infant boost) + 1,140 hrs universal $G_{\mathrm{ECE}}$ + *The Promise* (Exit 1 care reduction) & *MCR Pathways* adolescent mentoring (financed via higher $\tau_l$ without $\tau_a, \tau_b$) | Validates **Lens 1** ($\Delta G_{\mathrm{ECE},1}$, Gate 3 mentoring $\Delta_{\mathrm{Tuakana}}$, Exit 1 closure) **AND** proves why **Lens 3** ($\tau_a, \tau_b \to E$ vs. $\tau_l \uparrow$) is required | Cut child poverty **6 pp below rest of UK** (21% vs. 27%+) and lifted mentored care-experienced youth progression from 54% to 81.6%, but missed 18% interim target because lack of sovereign land/wealth tax powers ($\tau_a, \tau_b$) left urban housing $Q_k$ uncooled and forced reliance on PAYE hikes ($\tau_l \uparrow$) |

* **Scotland Literature & Official Audit Citations (2023–2026):**
  * *Wellbeing Economy Governments (WEGo) & Post-Growth Welfare Synthesis:* Corlet Walker, Druckman, & Jackson (2021) and *Lancet Planetary Health* Review (2024, Source 5), linking Scotland, New Zealand, and Finland.
  * *Statutory Targets, Scottish Child Payment, & Labour Supply Audit:* Scottish Government (*Bringing Hope, Building Futures: Tackling Child Poverty Delivery Plan 2026–2031*, March 2026; *Scottish Child Payment and the Labour Market: 2026 Update*, October 2026); Joseph Rowntree Foundation (*Poverty in Scotland 2026*, October 2026); Fraser of Allander Institute (*Meeting Scotland's Child Poverty Targets: Modelling and Policy Packages*, 2025).
  * *1,140 Hours Universal ELC & Adolescent/Care-Exit Prevention:* Audit Scotland (*Early Learning and Childcare: Progress on Delivery of the 1,140 Hours Expansion*, 2023/2025); *The Promise Scotland* (Plan 24–30) and *MCR Pathways* national secondary mentoring impact evaluations (lifting positive post-school destinations for care-experienced youth from 54.0% to 81.6%, directly paralleling Gate 3 Montessori / *Tuakana–Teina* and Graeme Dingle Foundation *Stars* / *Project K* outcomes).

