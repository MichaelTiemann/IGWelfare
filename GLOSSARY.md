# Master Glossary, Ledger Index, & Institutional Reference Guide (`IGWelfare`)

*A Cross-Disciplinary Orientation Guide for Citizens, Policy-Makers, Treasury & Crown Analysts, Iwi & Community Leaders, Investors, and Economists*

**Author:** [Michael Tiemann](https://github.com/MichaelTiemann) ([mdtiemann@gmail.com](mailto:mdtiemann@gmail.com))
**Date:** November 2026 | **Repository:** [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)
*Companion Reference to [README.md](README.md), [Document 1C](Document%201C.md) (Executive Brief), [Document 3](Document%203.md) (Coalition Synthesis), [Document 1A](Document%201A.md) (Strategic Monograph), [Document 1B](Document%201B.md) (Policy & Audit Answer Key), [Document 1D](Document%201D.md) (Sequencing & Launch Plans), [Document 1E](Document%201E.md) (Civic Capacity), [Document 1F](Document%201F.md) (Citizens' Assemblies), and [Documents 2 / 2A / 2B / 2T](Document%202.md) (Technical Specifications)*

---

## Quick Navigation

1. [Master Index of Pure Accounting Ledgers (`src/ledgers/`)](#1-master-index-of-pure-accounting-ledgers-srcledgers)
2. [Statutory Regimes (`SS0`, `SS1`, `SS2`), Launch Plans (`A, B, C`), & Fiscal Rules](#2-statutory-regimes-ss0-ss1-ss2-launch-plans-a-b-c--fiscal-rules)
3. [Treasury `OIA 20250878`, `LTFM`, `CBAx`, & `ACC` Institutional Lexicon](#3-treasury-oia-20250878-ltfm-cbax--acc-institutional-lexicon)
4. [Nobel Prize Foundations: Why Proven Economics Outlasts Political Orthodoxy](#4-nobel-prize-foundations-why-proven-economics-outlasts-political-orthodoxy)
5. [Model Anatomy: Aspects, Sectors, Regions, Generations, Skills, & Capitals](#5-model-anatomy-aspects-sectors-regions-generations-skills--capitals)
6. [Lifecycle Gates, Taxes & Balancing Costs, Builders vs. Speculators, & Waring Work](#6-lifecycle-gates-taxes--balancing-costs-builders-vs-speculators--waring-work)
7. [Polycentric Stakeholders, Six Civic Pillars, & Four Policy Constituencies](#7-polycentric-stakeholders-six-civic-pillars--four-policy-constituencies)
8. [Five Citizens' Assemblies, Sortition, & `GREEN` / `AMBER` / `RED` Risk Governance](#8-five-citizens-assemblies-sortition--green--amber--red-risk-governance)
9. [Navigational & Foiling Metaphors Translated into Formal Control Theory](#9-navigational--foiling-metaphors-translated-into-formal-control-theory)
10. [International Near-Peer Statistical Abstract (`SS0` vs. `SS2` in Context)](#10-international-near-peer-statistical-abstract-ss0-vs-ss2-in-context)

---

## 1. Master Index of Pure Accounting Ledgers (`src/ledgers/`)

Every quantitative claim across the monograph suite is produced by side-effect-free accounting modules in `src/ledgers/` operating on the solved 4-Region + `Abroad` dynamic-programming and 5-sector Small-Open-Economy (`SOE`) state arrays:

| Ledger Module (`src/ledgers/`) | Core Accounting Function | Key Exported Audit Table(s) (`output/<Profile_ID>/`) | Primary Monograph Anchor(s) |
| :--- | :--- | :--- | :--- |
| **`Compute_Actuarial_Ledger.m`** | Computes ACC-style / Treasury `CBAx` 25-year forward **Actuarial Continuation Valuations** at `2.0%` real `SRTP` and `8.0%` real `SOC` (net of a `30%` attribution haircut), proving `3.84x` total fiscal ROI (`1.16x` from direct cost avoidance alone) by Year 5. | `Table16_Actuarial_Valuation_*.csv` | [Doc 1C §2](Document%201C.md), [Doc 1B §5](Document%201B.md), [Doc 2B §7.3](Document%202B.md) |
| **`Compute_Synergy_And_Mirror_Ledger.m`** | Decomposes total welfare into **7 isolated policy instruments** (`+11.23% CE`) plus **4 supermodular synergy wedges** (`+13.47%` to `+13.98% CE`, over `54%` of total lift) and pairs annual outlays against welfare flows (`Mirror Ledger`). | `Table19_Constructive_Synergy_Wedges_*.csv`, `Table20_Annual_MirrorInvestments_*.csv` | [Doc 1A §4](Document%201A.md), [Doc 1D §2](Document%201D.md), [Doc 2B §7.5](Document%202B.md) |
| **`Compute_Civic_Gearing_Ledger.m`** | Quantifies two-sided grassroots civic & creative gearing across the **6 Pro-Social Pillars** (`NZD 500` *Joiner Passport*, `25.5x` ROI) and tests symmetry against 2024–2026 municipal/arts retrenchments (`C14`–`C15`). | `Table19E_ArtsEnabled_Synergy_*.csv` | [Doc 1E §3](Document%201E.md), [Doc 1B §3.5](Document%201B.md) |
| **`Compute_ThreeTier_NationalAccounts_Ledger.m`** | Reconciles **Tier 1** conventional `Y_SNA` GDP against **Tier 2** output-weighted Atkinson public quality + Marilyn Waring unpaid care/volunteering (`Y_AW`, `79,000 FTE` volunteers) and **Tier 3** household `CE%` welfare with zero double-counting. | `Table_Phase2_ThreeTier_Scorecard_*.csv` | [Doc 2A §2.5](Document%202A.md), [Doc 2B §5.6](Document%202B.md) |
| **`Compute_Public_Asset_Stewardship_Ledger.m`** | Evaluates four governance regimes over a `NZD 50B` public network/grid block, showing Ostrom civic turnaround dominates distressed fire-sale privatization by `+NZD 176.4B` in societal NPV (`+NZD 34.8B` upfront cash vs. `-24%` monopoly markup drag). | `Table_Phase2_PublicAsset_Stewardship_*.csv` | [Doc 1C §3](Document%201C.md), [Doc 2B §5.6](Document%202B.md) |
| **`Compute_Helm_TrimTab_Ledger.m`** | Solves the **non-minimum-phase (`NMP`) inverse-response** system linking a `~NZD 2.9B/yr` boundary-actuator seed (`TT1`–`TT4`) to `51.9x` system gain by 2050, isolating the `10.6-year` observability lag between True Solvency (`Yr 3.3`) and cash `OBEGAL` (`Yr 13.9`). | `Table_Phase2_Helm_TrimTab_*.csv` | [Doc 1C §3](Document%201C.md), [Doc 2B §7.7.2](Document%202B.md) |
| **`Compute_Divergence_Trajectory_Ledger.m`** | Tracks 60-year divergence across Status Quo `LTFM` drift, `3.0% GDP` defence shock, premature 6-year `Stop–Go` policy reversal, and committed `SS0 -> SS1 -> SS2` trajectories. | `Table21_Doc3_LTFM_Sinkhole_*.csv` | [Doc 3 §2](Document%203.md), [Doc 1D §4](Document%201D.md) |
| **`Compute_Assembly_Clearinghouse_Ledger.m`** | Audits **15 bilateral Citizens' Assembly contracts (`K01`–`K15`)** across four political regimes (Unified Compact vs. Day-1 Unmentored Grant, Cherry-Picked Silos, and 50%-Split Horse-Trade) and simulates **5 Macro/Structural Risk Channels (`S1`–`S5`) + Compound Polycrisis (`S6`)**. | `Table_Doc1F_Clearinghouse_15Contracts_*.csv`, `Table_Doc1F_RiskScenarios_*.csv` | [Doc 1F §4–5](Document%201F.md) |
| **`Compute_Contract_Shock_Sensitivity_Ledger.m`** | Computes continuous comonotonic SOE shock breaking-point frontiers (`GREEN` self-clearing $	o$ `AMBER` auto-remedy $	o$ `RED` plenary reconvene), proving state-contingent contracts expand shock tolerance by `~2.1x–2.8x` over rigid calendar promises. | `Table_Doc1F_ShockFrontiers_*.csv` | [Doc 1F §5](Document%201F.md), [Doc 2T](Document%202T.md) |
| **`Compute_NDC_Compliance_Ledger.m`** | Tracks domestic fossil-fuel displacement (`e_N = 0.88` vs. `e_F = 0.30`), exotic-pine afforestation saturation, and shadow Paris Agreement `NDC1`/`NDC2` offshore carbon liabilities *(full climate/NDC glossary reserved for dedicated future release)*. | `Table_Phase2_NDC_Exergy_*.csv` | [Doc 2A §2.4](Document%202A.md), [Doc 2B §5.6](Document%202B.md) |

*(Supplemented by lifecycle gate decompositions `Table14_FiscalLedger_6Gate_Decomp_*.csv` and `Table15_ChildFates_5Stage_Decomp_*.csv` from `plots/Plot_ChildFiscal_SSankey.m` and `plots/Plot_ChildFates_SSankey.m`.)*

---

## 2. Statutory Regimes (`SS0`, `SS1`, `SS2`), Launch Plans (`A, B, C`), & Fiscal Rules

* **Layer-1 Parameter Backstop & 1-to-1 Naming Contract (`Load_Empirical_Profile.m` -> `Apply_Empirical_Data.m`):** Every jurisdiction's `profile.yaml` (after `Inherits_From` merge) is validated by `validate_dataspec_schema` to guarantee all 7 `Monetary` keys, 15 `Institutions` keys (`tau_l`, `tau_c`, `tau_k`, `tau_a`, `tau_b`, `p_super`, `s_sub`, `Super_Age_Base`, `Super_Age_SS1`, `Super_Age_SS2`, `Dep_Ratio_Anchor`, `Estate_Exemption`, `Target_NetMig_Rate`, `w_External`, `Q_External`—copied 1-to-1 onto `Params` with zero case-renaming), 3 `Regime_Schedules` vectors, and 7 `Actuarial` keys are explicitly present; missing keys fail fast with `IGWelfare:IncompleteProfileSchema`.

### 2.1 Tax-and-Spend Mechanics of `SS0`, `SS1`, and `SS2`

| Policy Dimension | `SS0` — Status Quo Baseline (*LTFM Drift*) | `SS1` — Phase 1 Foundation & Incubation (*Years 0–15/25*) | `SS2` — Phase 2 Generational Harvest (*2050 Protocol*) |
| :--- | :--- | :--- | :--- |
| **Early Childhood (`Gate 1`, Ages 0–5)** | Underfunded (`G_ece,1 = 0.045`); `25.1%` births in hardship/AHC squeeze | Universal First-2,000-Days wraparound (`G_ece,1 = 0.110`) + *Farm-to-ECE* fresh nutrition | Enhanced wraparound (`G_ece,1 = 0.130`) + 2nd-generation family skill compounding |
| **Early Adolescence (`Gate 2/3`, Ages 12–14)** | Fragmented (`17.3%` vanguard coverage); `20.5%` distress bottleneck | Universal *Tuakana–Teina* / Graeme Dingle / Montessori mentoring (`G_ece,2 = 0.085`) | Mature system fidelity (`>98.5%` delivery yield) + civic *Joiner* floor |
| **Youth Launch (`Age 20`, `Gate 4`)** | Zero asset floor; `20%` LVR cliff blocks young renters; high brain drain | Universal **Age-20 Youth Capital Grant (`E = 0.065`)** (`17.3%` Early-Adopter Bridge Yrs 1–6 $	o$ `100%` by Wave 13) | Expanded **Youth Capital Grant (`E = 0.080`)** + cooled urban housing (`Q_Akl -10.5%`) |
| **Land, Wealth, Estate & Corporate Tax** | `0%` land/wealth levy (`tau_a = 0`); `0%` comprehensive CGT/estate; `20%` effective corporate rate | **10-yr smooth LVT/wealth ramp** (`+0.15%/yr` to `1.50%` above exemptions) + **3-yr `25%` CGT/Estate ramp**, paired 1-for-1 with **corporate tax cut (`20.0% -> 12.0%`)** | Retained `1.50%` book-value land/wealth & `25%` estate settings keeping capital in active `z_h` firms (`52%–56%` builders) |
| **Working-Age `PAYE` & `GST`** | Base effective `PAYE` `22.0%` (drifting toward `28.2%` under `LTFM`); `15.0%` `GST` | `PAYE` held steady at `22.0%` while upfront J-curve repays; `15.0%` `GST` | **`-3.75 pp` working-age `PAYE` cut (`22.0% -> 18.25%`)** earned via fiscal harvest; `15.0%` `GST` |
| **Geographic Hardship Transfers (`T_k`)** | Reactive, permanent accommodation & benefit top-ups | Targeted *Income $	imes$ Geography* bridge (`-NZD 1.55B/yr`) during transition | **82%–85% naturally retired** as thriving skills, cooler rents, and `z_h` regional wages take over |
| **NZ Superannuation Eligibility Age** | Age `65` (threatened with austerity hikes to `67–70`) | Protected universal **Age `65`** anchor | **Lowered to Age `64`** (global welfare peak, releasing `+8.1%` *kuia/koroua* caregiving dividend) |
| **Clean Exergy & Sovereign Debt** | `~NZD 19.5B/yr` imported oil; debt climbs `42% -> 185%–200% GDP` | 9-wave `CERF` regional electrification (`Rural+Small` $	o$ `Large` $	o$ `Auckland`); debt peaks at `43.4%` (Yr 6) | Oil imports cut to `~NZD 5.5B/yr`; **Core Crown Debt retired to `21%–22% of GDP`** |

### 2.2 Core Governance & Sequencing Protocols
* **13-Wave *Te Kāhui Waka* Rollout (`Document 1D`):** Steps regional program capacity in thirds (`1/3 -> 2/3 -> 3/3`) across `Rural + Small` (`40.0%` pop), `Large` (`25.9%`), and `Auckland` (`34.1%`) over Waves 1–9, eliminating `88.9%` of workforce surge congestion, funding the `17.3%` existing *Tuakana* vanguard immediately in Years 1–6 (`-NZD 0.28B/yr`, zero waste), phasing full Youth Grants across Waves 7–13 as mentored youth turn 20 (saving `NZD 12.9B` gross and avoiding `NZD 3.8B` unmentored waste), and cutting Year-3 capital at risk by `75%`.
* **The Three `SS2` Launch Plans (`A`, `B`, `C`) & Two-Key Statutory Protocol:**
  * **`Plan A` — Accelerated Plan (`Year 15.0` Launch $	o$ `Year 46.9` Target):** Authorized by **Key 1** at the Year 15 audit once all 13 waves are live, `>=95%` of the J-curve is paid (`96.6%` actual), Crown debt sits below its `42.0%` Year-0 anchor (`41.7%`), and `CBAx` actuarial return exceeds `+10% CE`. Trades a brief 4-year deferral of reportable cash-zero closure for **`+NZD 190B`** in extra 60-year household welfare.
  * **`Plan B` — Balanced Self-Funding Plan (`Year 20.0` Launch $	o$ `Year 50.0` Target):** Guaranteed automatically by **Key 2** once annual fiscal cash flow turns permanently positive (`Year 16.8` cash breakeven) and debt falls below `40% GDP` (`39.6%` at Yr 20). Requires **zero fiscal bridge** (`60.0x` ROI), meets Wave-1 newborns on their 20th birthday, and delivers **`+NZD 104B`** extra 60-year welfare over Plan C.
  * **`Plan C` — Conservative Plan (`Year 25.0` Launch $	o$ `Year 60.0` Target):** Waits until Wave-1 Dual-Gate graduates reach Age 25 and have climbed 1–2 career rungs (`8.2 years` after cash breakeven; `Debt = 36.6% GDP`). Serves as the conservative reference baseline.
* **2050 50/50 Sovereign Surplus Protocol:** Legally ring-fences post-breakeven net fiscal surpluses **50% into Sovereign Debt Retirement** (driving net debt to `21%–22% GDP` and compressing sovereign risk premia by `-60 bps`) and **50% into Preventative Public Infrastructure, Healthcare, & Capability** (`Sector 4A/4B`).
* **70/30 Revenue-to-Outlay Attribution Shield:** In all actuarial audits, prospective productivity/tax gains receive a conservative `30%` statutory haircut (booking `70%`), ensuring balance-sheet credibility under strict Treasury/Audit NZ scrutiny.

---

## 3. Treasury `OIA 20250878`, `LTFM`, `CBAx`, & `ACC` Institutional Lexicon

To prevent translation gaps with New Zealand public-finance practice, `IGWelfare` uses the exact technical definitions established in Treasury's *Official Information Act Response 20250878* (4 February 2026), *He Tirohanga Mokopuna 2025*, *Analytical Note 26/01*, *CBAx User Guidance* (Nov 2025), *Circular 2024/15*, and *ACC's Financial Condition Report 2025*:

* **Micro-Founding vs. Macro-Founding (`OIA 20250878`, pp. 6–11):**
  * **Micro-Founded Agency Tools (`CBAx`, `TAWA`, Stats NZ `IDI`):** Bottom-up tools used by sector agencies and the Social Investment Agency (`SIA`) to evaluate individual budget bids at the person/household level using longitudinal administrative data (`IDI`) and tax-transfer microsimulation (`TAWA`), holding macroeconomic wages, asset prices, migration, and sovereign debt exogenous (*partial equilibrium*).
  * **Macro-Founded Fiscal Tools (`FSM`, `LTFM`, Treasury `2025 OLG`):** Top-down aggregate projections—the medium-term Fiscal Strategy Model (`FSM`) and 40-to-60-year Long-Term Fiscal Model (`LTFM`)—which project aggregate Crown revenue, expenditure, and debt, but as Treasury formally noted in `OIA 20250878`, *"contain no data at the micro level, including at the cohort level,"* and therefore cannot endogenously capture how early-childhood or adolescent interventions alter future cohort tax capacity, migration, or reactive expenditure.
  * **The `IGWelfare` Micro-to-Macro Weld:** Couples a **micro-founded** 26,901-state-per-cohort lifecycle graph (calibrated to Dunedin Study, `GUiNZ`, and `IDI`/`CBAx` unit costs) directly inside a **macro-founded** 4-Region + `Abroad`, 5-Sector general-equilibrium engine—closing the exact institutional boundary identified in `OIA 20250878`.
* **Long-Term Fiscal Model (`LTFM` / *He Tirohanga Mokopuna 2025* & `AN 26/01`):**
  * **Bottom-Up Demographic vs. Non-Demographic Cost Growth:** Projects Health, Education, NZ Superannuation, and Welfare by combining Stats NZ cohort aging with historical non-demographic cost growth (`~0.9%/yr` economy-wide labor productivity assumption), causing status-quo real government spending per capita to nearly double (`NZD 18,300 -> NZD 35,900`) and **Unstabilized Net Core Crown Debt** to compound toward `185%–200% of GDP` (`-16.21% CE` welfare drift, or `-21.69% CE` with an unfunded `3.0% GDP` defence lift).
  * **Primary Fiscal Gap & Debt-Interest Spiral:** Once primary operating deficits persist alongside rising debt-to-GDP, sovereign interest service compounds faster than nominal GDP growth ($`r_{\mathrm{gov}} > g`$), forcing punitive future `PAYE`/`GST` hikes or deep service rationing unless structural productivity and preventative exits bend the underlying cost curves.
* **`OBEGAL` (Operating Balance Before Gains and Losses):** The Crown's headline annual cash/accrual operating balance on a 1-to-4-year Budget Economic and Fiscal Update (`BEFU`) horizon. Treats human-capital investment as an immediate consumption expense with zero asset value, causing raw `OBEGAL` to lag comprehensive national solvency by **`10.6 years`** during generational transitions.
* **`CBAx` (Treasury Cost-Benefit Analysis Tool) & Counting Rule #1 (`July 2015 Guide`, pp. 10–15):** Standardizes monetized social impacts across Crown agencies. **Counting Rule #1** strictly separates pure fiscal transfer payments (`T_k`, which redistribute purchasing power without directly creating real output) from real resource/output changes (`Delta Y_t`) so transfers are never double-counted as GDP.
* **Dual Public Discount Rates (`Treasury Circular 2024/15` & `OIA 20250126`):** Anchored by Grimes, Abelson & Dalton, and Jensen & Parker (CCAPM/Ramsey/Weitzman proofs): mandates **`2.0%` real Social Rate of Time Preference (`SRTP`)** for non-commercial social/intergenerational appraisals over Years 1–30 (`1.5%` Years 31–100)—matched in `IGWelfare` by `beta_hh = 0.980^dt`—alongside mandatory **`8.0%` real Social Opportunity Cost of Capital (`SOC`)** sensitivity testing.
* **ACC Actuarial Continuation Valuation (`OCL Release`, `New Year Costs`, `PBE IPSAS 19` / `PBE IFRS 17`):** Under the Accident Compensation Act 2001 and `ACC Financial Condition Report 2025` (`NZD 57.3B` funding-basis **Outstanding Claims Liability [`OCL`]**), ACC books **New Year Costs** when injuries occur and records an audited **`OCL Release`** when rehabilitation durably lowers multi-decade claim trajectories. `Compute_Actuarial_Ledger.m` applies this identical GAAP discipline (`PBE IPSAS 19` / `IFRS 17`) to verified cohort exits from severe childhood and adolescent hardship at Gates 1 and 2.

---

## 4. Nobel Prize Foundations: Why Proven Economics Outlasts Political Orthodoxy

Many components of this compact challenge short-term political habits—just as free and open-source software defied 1980s commercial orthodoxy before powering the modern digital economy ([Document 1C §6](Document%201C.md)). Yet every structural mechanism in `IGWelfare` rests on Nobel Prize-winning economic proofs whose implications politicians both then and now have frequently overlooked:

| Nobel Laureate(s) | Core Theoretical Discovery | Why Short-Term Politics Missed It — And How `IGWelfare` Operationalizes It |
| :--- | :--- | :--- |
| **James J. Heckman** *(Nobel, 2000)* | **Dynamic Complementarity & Self-Productivity of Early Human Capability** (Cunha & Heckman, 2007) | 3-year cash budgets treat early childhood as a consumption subsidy and try to fix youth distress in late-teen crisis wards. Two-stage CES skill dynamics (`HumanCapital_Lifecycle_aprimeFn.m`) prove **First-2,000-Days** (`Gate 1`) + **Early-Adolescent Mentoring** (`Gate 2`) multiply each other (`Wedge 1 = +3.46% CE`). |
| **Elinor Ostrom** *(Nobel, 2009)* | **Polycentric Governance & Citizen Co-Production of the Commons** | Politicians oscillate between centralized Wellington micromanagement and distressed asset privatization. `Sector 4A/4B` and `Compute_Public_Asset_Stewardship_Ledger.m` prove high-trust *Whānau Ora*, *iwi*, municipal, and volunteer co-production beats both state silos and fire-sales (`+NZD 176.4B` advantage). |
| **Ronald H. Coase** *(Nobel, 1991)* & **Oliver E. Williamson** *(Nobel, 2009)* | **Transaction-Cost Economics & Relational Institutional Governance** | Adversarial 3-year NGO re-tendering, fragmented ministry silos, and parliamentary horse-trading burn billions in frictional transaction drag. Ranged contingent Citizens' Assembly contracts (`K01`–`K15`) and multi-decade *Te Kāhui Waka* compacts slash institutional friction. |
| **Paul M. Romer** *(Nobel, 2018)* | **Endogenous Growth via Non-Rival Ideas & Skilled Human Capital** | Taxing working brains and reinvested enterprise profits while leaving passive land untaxed starves the idea engine (`61%` of retained top graduates pulled into `z_l` rent-seeking). Rotating tax onto unimproved land (`tau_a`) and cutting corporate/PAYE drag expands `z_h` enterprise builders seven-fold. |
| **Kenneth J. Arrow** *(Nobel, 1972)* | **Learning-by-Doing & General Equilibrium Under Uncertainty** | Instantaneous "Day-1 nationwide rollouts" overload workforces (`28%–32%` friction). `Plot_Doc1D_TeKahuiWakaSequencing.m` embeds Arrow learning-by-doing across 13 regional waves, lifting delivery fidelity from `72%` to `>95%` by Wave 7. |
| **Gary S. Becker** *(Nobel, 1992)* *(extended by Marilyn Waring)* | **Household Time Allocation, Human Capital, & Endogenous Fertility** | Treating household/grandparent caregiving as "free" zero-cost leisure causes pension hikes (`Age 67–70`) and urban rent squeezes to collapse fertility (`1.66` TFR) and *whānau* care. Our `Atkinson–Waring` time-budget and `FertilityBargaining_Module.m` price every hour of family care explicitly. |
| **Amartya Sen** *(Nobel, 1998)* & **Joseph E. Stiglitz** *(Nobel, 2001)* | **Substantive Human Capabilities, Beyond-GDP Inclusive Wealth, & Land-Rent Taxation** | Raw `Y_SNA` GDP rises when avoidable hospitalisations, prisons, or monopoly water bills expand. Our **Three-Tier Scorecard** (`Compute_ThreeTier_NationalAccounts_Ledger.m`) and **Henry George / Stiglitz land-tax rotation** align fiscal metrics with real human capability and inclusive wealth. |

---

## 5. Model Anatomy: Aspects, Sectors, Regions, Generations, Skills, & Capitals

* **Three Coupled Aspects (`Aspects 1, 2, & 3`):**
  * **`Aspect 1` — Intergenerational Human Capability & Belonging:** Two-stage childhood/adolescent skill formation (`Gates 1 & 2`), adult Ben-Porath learning, and pro-social civic participation.
  * **`Aspect 2` — Spatial Housing, *Whānau* Anchoring, & Lifecycle Mobility:** Regional housing tenure (`20%` LVR deposit gate), `4 x 5` Gumbel domestic/emigration sorting, cooperative fertility bargaining, and the *kuia/koroua* NZ Super caregiving bridge.
  * **`Aspect 3` — Productive Enterprise, Biophysical Exergy, & Sovereign Solvency:** Infinite-horizon `z_l / z_h` entrepreneurial firms, 5-sector open-economy trade & renewable electrification (`e_N = 0.88` vs. `e_F = 0.30`), ACC actuarial valuation, and the 2050 `50/50` debt-sinking protocol.
* **Four Domestic Regions + `Abroad` (`8` Permanent Types + External Outside Option):**
  1. **`Rural` (`16.0%` HH share, `15.0%` Firm share):** Agricultural, horticultural, forestry, and remote districts.
  2. **`Small` (`24.0%` HH, `23.5%` Firm):** Provincial towns and districts under `100,000` residents (*`Rural + Small` = `40.0%` provincial echelon*).
  3. **`Large` (`25.9%` HH, `26.9%` Firm):** Major regional metropolitan centers over `100,000` (Wellington, Christchurch, Hamilton, Tauranga, Dunedin).
  4. **`Auckland` (`34.1%` HH, `34.6%` Firm):** Tāmaki Makaurau primate metropolitan economy (`3.10x` baseline house-price multiple).
  5. **`Abroad` (Endogenous `5th` Migration Destination):** Trans-Tasman (Australia) and wider OECD labor market absorbing net young-adult brain drain when domestic rent-Adjusted wages lag.
* **Five Structural Production Sectors (`S1`–`S5` in `Compute_5Sector_Exergy_Equilibrium.m`):**
  * **`Sector 1` — Land-Bound Primary Tradables:** Dairy, meat, horticulture, forestry, and farm-gate value-chain hubs.
  * **`Sector 2` — Clean-Exergy, Manufacturing & Knowledge Tradables:** High-productivity `z_h` export manufacturing, software/deep-tech, and domestic renewable electricity/firming (`CERF`).
  * **`Sector 3` — Private Market Non-Tradables & Commercial Real Estate:** Retail, hospitality, private construction, banking, corporate childcare/aged-care chains, and rental housing.
  * **`Sector 4` — Polycentric Public, NGO & Civic Services:** Split into **`Sector 4A` Human Co-Production** (`Te Whatu Ora` public hospitals, state/*kura* schools, community ECE, *Whānau Ora*, registered charities/NGOs, core public service—releasing `~65,000` staff internally from crisis remediation to preventative care) and **`Sector 4B` Public Network Infrastructure** (67 councils' Three Waters, public roading/transit, national grid/commons).
  * **`Sector 5` — Sovereign Defence & Maritime Security:** Dedicated external-security sector (`1.2% -> 3.0% of GDP` stress test) capturing high imported platform/fuel foreign-exchange leakage (`M_D*`, `F_D`) and technical labor competition.
* **OLG Generations & Period Resolution (`Configure_Grid_And_Prefs.m`):**
  * Tracks `80` adult lifecycle years (**Ages `20–99`**, plus embedded childhood **Ages `0–19`** inside parent households = **100-year birth-to-elder span**). Production resolution uses **`dt = 3` years (`J = 27` cohorts, `Jr = 16` retirement at Age 65)**; fast exploratory mode uses **`dt = 5` years (`J = 16` cohorts, `Jr = 10`)**, unified via exact continuous-time scaling (`beta_hh = 0.980^dt`, `beta_firm = 0.9815^dt`).
* **Seven Human Capital Achievement Levels (`h1`–`h7`, `h_grid = [0.45, 0.65, 0.85, 1.00, 1.20, 1.45, 1.80]`):**
  * **`h1–h2` (`0.45, 0.65`) — Struggling Launch (`22.0%–23.5%` in `SS0` $	o$ `4.0%` `SS1` $	o$ `1.5%` `SS2`):** High exposure to NEET status, low-wage precarity, chronic morbidity, and benefit dependency.
  * **`h3–h5` (`0.85, 1.00, 1.20`) — Core Working Capability (`54.5%` in `SS0`):** Solid foundational numeracy/literacy, trade qualifications, and steady domestic employment.
  * **`h6–h7` (`1.45, 1.80`) — Thriving Capability (`23.5%` in `SS0` $	o$ `65.0%` in `SS2`):** High executive function, tertiary/advanced technical mastery, and peak mobile talent (`Abroad` vs. `z_h` vs. `z_l` margin).
* **Three Early Childhood Hardship Levels (`Gate 1` Entry):**
  1. **Material & Severe Material Hardship (`9.5%` national / `10.8%` `GUiNZ` — `Node 1`):** Stats NZ `DEP-17` deprivation score `6+` / `9+`; acute food, heating, and crowding stress (`i_c = 0` corner).
  2. **Residual After-Housing-Costs (`AHC`) Squeeze (`15.6%`–`16.4%` — `Node 2`):** Working families above gross income cutoffs whose metropolitan rent/mortgage service strips away time and cash for enrichment (*total early vulnerability = `25.1%` Dunedin / `27.2%` GUiNZ*).
  3. **Secure *Whānau* & Material Buffer (`74.9%` — `Node 3`):** Stable housing and extended *whānau/kuia* care scaffolding.
* **Wellbeing Economy & Multiple Forms of Capital (Extending Treasury's *Living Standards Framework*):** Tracks stocks rather than raw input flows across **five capitals**: **(1) Human Capability** (`h`, `theta_c`, health), **(2) Social, Civic & Cultural Capital** (*whakapapa*, *manaakitanga*, `6` *Joiner* pillars, Ostrom trust), **(3) Natural & Biophysical Exergy Capital** (renewable `e_N` work, clean water/catchments, `NDC` carbon balance), **(4) Productive & Network Physical Capital** (`z_h` plant, `Sector 4B` water/grid/housing stock), and **(5) Sovereign & Net Foreign Financial Capital** (Core Crown Debt `% GDP` and `NFA`).

---

## 6. Lifecycle Gates, Taxes & Balancing Costs, Builders vs. Speculators, & Waring Work

* **5-Gate (`18-Node`) Child Fates Sankey vs. 6-Gate (`29-Node`) Fiscal Sankey:**
  * **5-Gate Fates (`Plot_ChildFates_SSankey.m`):** Tracks **human headcount (`60,000` annual births = `100%`)** across Birth Context (`Gate 1`), First 2,000 Days (`Gate 2`), Schooling & Adolescence (`Gate 3`), Age-20 Adult Launch & Migration (`Gate 4`), and Prime-Age Occupational/Civic Realization (`Gate 5`).
  * **6-Gate Fiscal (`Plot_ChildFiscal_SSankey.m`):** Tracks **discounted lifetime Crown & private dollar flows** across those five lifecycle gates plus **Gate 6 (Retirement, NZ Super, Sovereign Debt-Sinking, & Core Crown Allocation)**.
* **The Four Adverse ("Bad") Exit Gates + Skilled Emigration:**
  * **`Exit 1` (Early Childhood):** Oranga Tamariki state care notifications/placements and severe early developmental trauma (`NZD 37.1k–54.7k/child-yr` custody; `NZD 181k` discounted Crown abuse-in-care cost).
  * **`Exit 2` (Adolescence):** Avoidable acute hospitalisations, CAMHS youth mental-health crises, and school exclusion/stand-downs.
  * **`Exit 3` (Opportunity Loss):** Foregone lifetime `PAYE`/`GST` tax base from cohorts trapped in under-skilled `h1–h2` low-wage trajectories (an uncollected revenue opportunity rather than a cash outlay).
  * **`Exit 4` (Adult Remediation):** Long-term Jobseeker/Supported Living benefits, Accommodation Supplement landlord capture, and Corrections/Justice custody (`NZD 150k+/prisoner-yr`).
  * **Plus Skilled Emigration (`Node 18` / `Abroad`):** Publicly educated 20-to-35-year-olds (`10.9%` nationally; `19.3%–23.4%` from metros in `SS0`) whose childhood education was paid by NZ taxpayers while their prime-age `PAYE` and `GST` accrue overseas.
* **Why Our Household Fiscal Ledger Counts `PAYE` + `GST` — And Which Balancing Costs Close the Budget:**
  * **Why `PAYE` and `GST`:** In New Zealand's tax mix, progressive labor/pension income tax (**`PAYE`**) and broad-based `15%` consumption tax (**`GST`**) represent **over `80%` of household-attributable Crown revenue** and directly reflect a cohort's lifetime earning and spending capacity across `h1..h7` (while outer GE closure separately accounts for corporate tax `tau_k`, book-value land/wealth `tau_a`, and estate/CGT `tau_b`).
  * **Major Balancing Costs Counted (`Gate 6`):** To ensure honest general-equilibrium fiscal closure, cohort `PAYE + GST` contributions must fund four real Crown commitments: **(1) Universal Base Healthcare** (`Te Whatu Ora` non-remedial care), **(2) Core Public Infrastructure & Administration** (`Sector 4B` water/roads/grid + `4A` schools/defence), **(3) Universal New Zealand Superannuation** (`Age 65` in `SS0/SS1`, `Age 64` in `SS2`), and **(4) Reactive Social Remediation (`Exits 1, 2, & 4` = `NZD 17.7B/yr` in `SS0`, compressed by `>75%` to `NZD 4.2B/yr` in `SS2`)**.
* **What We Mean by "Passive Land Speculation (`z_l`)" vs. "Productive Builders (`z_h`)" *(Not All Landholders Are Speculators!)*:**
  * **Crucial Distinction:** Holding land to **produce food, fiber, or timber** (working farms, orchards, *whenua Māori* agribusiness), owning a **family home** (protected by generous primary-residence/exemption thresholds audited in `Table 18`), or **developing new housing and commercial plant** that expands real physical supply is **productive `z_h` activity**—not speculation.
  * **Passive Speculation (`z_l`):** Refers specifically to leveraged **unimproved land-banking and non-productive rent extraction** (`Node 19`)—bidding up existing fixed urban land titles for untaxed capital gains while adding zero new housing units, zero R&D, and zero tradable output, or extracting regional wholesale/retail duopoly markups. Under `SS0` tax asymmetries, `z_l` captures `61%` of retained top-tier talent; pairing the `1.5%` LVT ramp with a `20% -> 12%` corporate tax cut makes **Productive Builders (`z_h`, `Node 20`)**—founders, innovative farmers, manufacturers, creatives, and home-builders—the highest-return vocation in every region (`6.9% -> 52.9%` of the cohort).
* **Marilyn Waring "Uncounted" Care & Volunteer Work (`Atkinson–Waring Satellite`):** Non-market household childcare, elder care, *kuia/koroua* grandchild scaffolding, *marae* hospitality, and **`79,000 FTE` (`159M hrs/yr`)** of formal/informal community volunteering. Invisible in conventional `Tier 1` `Y_SNA` GDP, yet essential to producing human capability and preventing `Sector 4A` burnout.

---

## 7. Polycentric Stakeholders, Six Civic Pillars, & Four Policy Constituencies

* **Five Polycentric Stakeholder Groups (`Document 1C §4` & `Document 1F`):**
  1. **Crown, Parliament, & Treasury:** Enact honest ACC/CBAx actuarial rules, phase the land-to-enterprise tax rotation, and guard the `50/50` debt/infrastructure stabilizers.
  2. **Philanthropy, Iwi, & Community Organizations:** (*Whānau Ora*, *iwi/hapū* trusts, Barnardos Aotearoa, Graeme Dingle Foundation, Pasifika hubs) lead high-trust *manaakitanga*, *Tuakana–Teina* mentoring, and the open *Matakahi* co-design interface for *Te Ōhanga Māori*.
  3. **Entrepreneurs, Venture Investors, & Regional Businesses:** Deploy capital and retained graduates into `z_h` operating companies, clean electrification, and regional food/export hubs.
  4. ***Whānau*, Parents, & Grandparents (*Kuia / Koroua*):** Anchor early childhood nurturing and inter-household stability, reinforced by cooler rents and Age-64 NZ Superannuation.
  5. **Citizens & Sortition Assemblies:** Exercise deliberative oversight over normative trade-offs (`What Is Decidable`) and hold cross-party commitments to ranged contingent contracts (`K01`–`K15`).
* **Six Pro-Social Civic Pillars (`Document 1E Part II` — `25.5x` *Joiner* Gearing):**
  1. *Community Food Systems, Māra Kai, & Shared Commons Tables* | 2. *Service Organizations & Intergenerational Civic Brigades* | 3. *Rewilding, Predator-Free Halos, & Taiao Catchment Hubs* | 4. *Outdoor Adventures, Waka Voyaging, & Physical Craft Academies* | 5. *Community Theater, Kapa Haka, & Living Pūrākau* | 6. *Youth Orchestras, Choirs, Brass Bands, & Sonic Commons*.
* **Four Key Policy Constituencies, Their Silos, & Why `LTFM` Swamps Standalone Effort (`Document 3`):**
  1. **`Coalition 1` — Children, Iwi & Youth Capability** *(Barnardos `9.10:1` SROI catalyst, Whānau Ora, Mentoring)*: `+6.33% CE` standalone $	o$ **`-0.06% CE` net of `LTFM` drift** if urban rents and brain drain go unaddressed (`+13.28% CE` with neighbor wedges).
  2. **`Coalition 2` — WellBeing & Housing Justice** *(LVT/Rent Relief, Age-20 Youth Grant, Whānau)*: `+3.52% CE` standalone $	o$ **`-2.40% CE` net of `LTFM`** without mentored youth capability (`+8.17% CE` with neighbors).
  3. **`Coalition 3` — GrowthNZ & Venture Enterprise** *(Corporate Tax Cut, `z_h` Builders, Exergy/Infra)*: `+2.21% CE` standalone $	o$ **`-9.12% CE` net of `LTFM`** in a domestic skill shortage (`+7.21% CE` with neighbors).
  4. **`Coalition 4` — Fiscal Stewards & Sovereign Solvency** *(Debt-Sinking, Actuarial Rules, PAYE Relief)*: Attempting "debt austerity first" via early cuts or Age-70 Super sinks welfare to **`-10.55% CE`** via benefit substitution and *whānau* care loss, whereas coupling with Coalitions 1–3 retires debt to `22% GDP` and cuts `PAYE` to `18.25%`.

---

## 8. Five Citizens' Assemblies, Sortition, & `GREEN` / `AMBER` / `RED` Risk Governance

To secure durable multi-party permission without destructive horse-trading ([Document 1F](Document%201F.md)), **civic sortition** (demographically representative lottery selection modeled on Porirua, Tairāwhiti, Melbourne, Ireland, and Paris precedents) convenes **Five Contingent Citizens' Assemblies** reconciled by a **Joint Citizen Plenary Council** and an open-source **Economic Clearinghouse**:

* **The Five Assemblies & Ranged Mandates (`K01`–`K15`: *"Assume `[X_min, X_max]` $	o$ Deliver `[U_min, U_max]`"*):**
  * **`Assembly 1` (Early Potential & *Rangatahi* Agency):** Governs Gates 1 & 2 (`First 2,000 Days` + *Tuakana* mentoring) to compress struggling launches (`22% -> <=4%`).
  * **`Assembly 2` (Housing Affordability, *Whānau* Anchoring & Dignified Retirement):** Governs urban rent cooling, Age-20 Youth Grant staging, and Age-64 NZ Superannuation.
  * **`Assembly 3` (Grassroots Civic Mycelium, Creative Arts & Belonging):** Governs the `NZD 500` *Joiner Passport*, municipal *Meanwhile Spaces*, and the `6` Civic Pillars.
  * **`Assembly 4` (Productive Enterprise, Fair Tax Rotation & Regional Jobs):** Governs the 10-year LVT/corporate tax rotation, `CERF` regional electrification, and `z_h` builder expansion.
  * **`Assembly 5` (Sovereign Stewardship, Infrastructure Maintenance & Launch Sequencing):** Governs ACC actuarial audits, `50/50` debt/infrastructure rules, defence FX headroom, and Two-Key `SS2` triggers (`Plans A, B, C`).
* **The Five Sovereign & Macroeconomic Risk Channels (`Compute_Assembly_Clearinghouse_Ledger.m`):**
  1. **`Risk 1` (`S1` — Stock Formation Lag):** `35%` slower cohort skill or struggling-exit realization at Gates 1–2.
  2. **`Risk 2` (`S2` — `Sector 4A` Educator & Healthcare Retention Shock):** Trans-Tasman wage poaching of teachers and nurses.
  3. **`Risk 3` (`S3` — Dry-Year Hydro & Oil Exergy Shock):** `+75%` imported fossil-fuel price spike alongside low hydro inflows.
  4. **`Risk 4` (`S4` — Export Terms-of-Trade & `CBAM` Shock):** `-12%` `Sector 1` primary export price/carbon-border hit.
  5. **`Risk 5` (`S5` — Sovereign Credit Spread Spike):** `+180 bps` jump in international sovereign borrowing yields *(tested individually and simultaneously as **`S6` Compound Polycrisis**)*.
* **Three-Band Circuit-Breaker Protocol (`GREEN` / `AMBER` / `RED`):**
  * **`GREEN` (Self-Clearing Band):** Realized indicators stay inside `[Assumed_Min, Assumed_Max]` via automatic SOE buffers (floating exchange rate, monetary accommodation, 13-wave pacing); execution continues undisturbed.
  * **`AMBER` (Pre-Agreed Auto-Remedy Band):** Shock exceeds rigid calendar tolerance (`lambda > lambda*_Rigid`) but stays inside state-contingent capacity (`lambda <= lambda*_Cont`); pre-legislated stabilizers fire automatically (e.g., pacing `Plan A` to `Plan B`, accelerating `CERF` firming, or targeted `Sector 4A` retention allowances) **without reopening parliamentary horse-trading**.
  * **`RED` (Plenary Reconvene Band):** Extreme tail shock breaches `lambda*_Cont`; triggers a focused reconvening of the **Joint Citizen Plenary Council** to recalibrate ranged burden-sharing transparently on the live Clearinghouse ledger.

---

## 9. Navigational & Foiling Metaphors Translated into Formal Control Theory

Our broad-circulation essays ([Documents 1C](Document%201C.md), [1D](Document%201D.md), & [3](Document%203.md)) use New Zealand's America's Cup hydrofoil engineering and Polynesian *waka hourua* navigation to make nonlinear control theory intuitive. In [Documents 2A & 2B](Document%202A.md), each metaphor maps `1-to-1` onto a formal mathematical operator:

| Navigational / Foiling Term | Formal Control-Systems & Economic Equivalent | Code / Ledger Implementation |
| :--- | :--- | :--- |
| **Displacement Hull Slogging in Heavy Seas** | High-drag equilibrium trapped in reactive remediation (`NZD 17.7B/yr`), `e_F = 0.30` fossil-import leakage, and compounding `LTFM` debt (`r_gov > g`). | `SS0` Baseline (`NZ_4Region_Master.m`) |
| **Getting "Up on Foils"** | Transitioning from reactive transfer/remediation drag to a self-sustaining high-skill (`h6–h7`), high-exergy (`e_N = 0.88`), `z_h`-enterprise growth regime (`+24.7%` to `+25.2% CE`). | Coupled `SS0 -> SS1 -> SS2` Transition (`TransPath_4Region_Master.m`) |
| **Front Lifting Foil / Wing-Sail / Rear T-Foil Stabilizer** | The three mutually stabilizing subsystems: **`Aspect 1`** Dual-Gate human capability (lift) + **`Aspect 2/3`** land-to-enterprise tax & exergy power plant (thrust) + **ACC Actuarial & `50/50` Debt Rule** (pitch stability). | `WelfareDecomposition_4Region.m` |
| **Pitch-Poling / Capsizing** | Enacting one subsystem without its stabilizers—e.g., expanding schooling without cooling urban rents (driving brain drain, as in Scotland/Seoul) or cutting taxes before building skills/solvency. | Off-diagonal commutator / silo runs (`Plot_Doc3_CoalitionSynergies_*.m`) |
| **Trim-Tab (`TT1`–`TT4`)** | **High-gain boundary-layer state-feedback actuator**: a small (`~NZD 2.9B/yr`) low-inertia input that alters structural transition hazards (`Sector 4A` release, `CERF` exergy, Ostrom turnaround, `tau_a` shift), yielding `51.9x` system gain by 2050. | `Compute_Helm_TrimTab_Ledger.m` |
| **Port Stern Kick / "Years 1–8 Panic Window"** | **Non-Minimum-Phase (`NMP`) right-half-plane zero inverse response**: upfront capability outlays plus falling reactive GDP (`Delta Y_rem < 0`) dip cash `OBEGAL` (`-NZD 9.1B` at Yr 3) for `10.6 years` even while True Solvency breaks even at `Yr 3.3`. | `Plot_HelmPhysics_TrimTabs_And_CounterSteering.m` (`Panel B`) |
| **6-Year `Stop–Go` Limit Cycle** | **Premature feedback reversal inside the `NMP` inverse-response window**: repealing early-years investments at Year 6 because cash `OBEGAL` hasn't crossed zero yet, forfeiting `84.2%` of long-run welfare. | `Compute_Helm_TrimTab_Ledger.m` (`Panel C`) |
| ***Te Kāhui Waka* & *Waka Mataika* (Vanguard Hulls)** | **13-wave echeloned regional staging with Arrow/Deming PDSA inter-wave learning**, cutting quadratic adjustment drag `(Delta s)^2` by `88.9%` and lifting delivery yield `72% -> >95%`. | `Plot_Doc1D_TeKahuiWakaSequencing.m` |
| ***Te Kapehu Whetū* (Star Compass Launch Windows)** | **State-contingent optimal stopping / launch gates (`Plans A, B, C`)** aligning `SS2` `PAYE` cuts with generational cohort wave convolution (`Omega_echo` at `T_gen ~ 20.5 yrs`) and sovereign debt anchors. | `Plot_Doc1D_LaunchPlans.m` |

---

## 10. International Near-Peer Statistical Abstract (`SS0` vs. `SS2` in Context)

To situate Aotearoa New Zealand's `SS0` baseline and `SS2` (`2050 Protocol`) harvest alongside small advanced open economies and historical natural experiments analyzed in [Document 1A §5](Document%201A.md) and [Document 2B §6](Document%202B.md) *(2025/2026 IMF WEO, OECD National Accounts, UNICEF Innocenti, & IEA rounded statistical benchmarks)*:

| Country / Regime Benchmark | Pop. (`M`) | GDP / Capita (`USD PPP`) | Net General Gov. Debt (`% GDP`) | Child Hardship / Youth Struggling (`%`) | Total Fertility Rate (`TFR`) | Clean End-Use Energy Share (`%`) | Comparative Structural Lesson on Our Dashboard |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **NZ `SS0` Status Quo (2026 -> 2065 `LTFM`)** | `5.3` | `~54,000` | `42% -> 185%+` | `22.0%–25.1%` | `1.66` *(Akl `1.49`)* | `~32%` *(87% grid, 68% fossil end-use)* | High skill waste, `3.1x` metro housing squeeze, `61%` top-talent `z_l` capture, & `LTFM` debt sinkhole (`-16.2% CE`). |
| **★ NZ `SS2` Harvest (`Te Kāhui Waka` 2050)** | `5.9` | `~74,000+` *(equiv. lift)* | **`21%–22%`** | **`1.5%–4.0%`** | **`1.87–1.95`** | **`~78%+`** *(electrified `e_N = 0.88`)* | **`+24.7%` to `+25.2% CE` lift**, `PAYE` cut to `18.25%`, Super at `64`, `52.9%` `z_h` builders, `3,550/yr` talent retained. |
| **Australia** *(Trans-Tasman Outside Option)* | `27.2` | `~69,000` | `~32%` | `~13%–15%` | `1.50` | `~24%` | `~28%–35%` higher skilled wage benchmark (`Abroad` magnet in `Gate 4`), cushioned by mineral rents & superannuation pool. |
| **Denmark** *(Nordic Flexicurity + Early Years)* | `6.0` | `~77,000` | `~11%` | `~6%–8%` | `1.55` | `~45%` | Universal First-2,000-Days pedagogy + municipal land/property tax anchor + deep R&D export base (`Novo/Maersk`). |
| **Sweden** *(Universal Childcare + Innovation)* | `10.6` | `~70,000` | `~16%` | `~8%–9%` | `1.45` | `~66%` | Low sovereign debt, universal preschool, and deep venture/industrial ecosystems; warns against urban housing queues. |
| **Finland** *(Equitable Schooling & Youth Trust)* | `5.6` | `~62,000` | `~48%` | `~5%–7%` | `1.26` | `~52%` | World-leading early/comprehensive schooling equity, but aging demographics show why `Aspect 1` needs `Aspect 2/3` growth. |
| **Estonia** *(2000 `0%` Reinvested Corp + LVT)* | `1.4` | `~49,000` | `~8%` | `~9%–10%` | `1.31` | `~38%` | Empirical proof for `Aspect 3`: `0%` tax on reinvested business equity + pure Land Value Tax ignited Europe's highest unicorn density. |
| **Ireland** *(Retained Talent, Missing Housing Anchor)* | `5.4` | `~105,000` *(GNI* `~68k`)* | `~34%` | `~12%–14%` | `1.50` | `~22%` | Reversed historic youth emigration via high-skill `z_h` export jobs, but Dublin rent inflation shows why LVT/supply (`Aspect 2`) is vital. |
| **Singapore** *(Universal Housing + Asset Grants)* | `6.0` | `~108,000` | `Net Creditor` | `~5%–7%` | `0.97` | `~15%` | Proves universal homeownership anchoring + child baby-bonus/CPF accounts build middle-class wealth; warns against work-hours squeeze on TFR. |
| **Scotland** *(2017–26 `Aspect 1` Only via `PAYE`)* | `5.5` | `~56,000` | `UK ~96%` | `21.0%` *(vs `27%` rUK)* | `1.30` | `~42%` | Natural experiment ([Doc 2B §6](Document%202B.md)): `1,140 hr` ECE + *MCR Pathways* mentoring cut child poverty `-6 pp`, but stalled at `21%` without land/estate tax powers. |
| **Japan** *(1950 Deming `z_h` Boom -> 1990 Land Bubble)* | `124.0` | `~52,000` | `~155%` | `~11%` | `1.20` | `~22%` | Hirano & Toda (2025) proof: Deming capability compounding without `tau_a` land taxation mathematically forces a rational urban land bubble. |
| **OECD Weighted Benchmark** | `—` | `~59,000` | `~68%` | `~15%` | `1.48` | `~28%` | Reference multilateral peer average across 38 OECD member economies. |
