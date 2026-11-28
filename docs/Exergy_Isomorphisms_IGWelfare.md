# Factor Conversion vs. Nominal Outlay: Exergy Effects, Wedge Additionality, and Structural Isomorphisms in `IGWelfare`

**Status:** Empirically Grounded Technical Specification & Cross-Country Synthesis (`NZ_Dunedin1972` & `FI_FBC1987`)  
**Companion Routing:** Formal analytical propositions and proofs are routed to **[Document 2A](../Document%202A.md)** (Sections `2.4.1`, `2.5.1`, and `3.3.1`); supermodular wedge theory, profile schemas, calibration tables, and post-hoc ledger identities are routed to **[Document 2B](../Document%202B.md)** (Section `7.4.1` and `[Ref 9, 33]`).

---

## 1. The Core Identification Problem: Nominal Cost Shares vs. Physical Conversion Factors

A pervasive specification error in standard macroeconomic and fiscal policy modeling is the **Price-Deflator vs. Real-Factor Confound**: using nominal expenditure ($`P \cdot Q`$) or market expenditure shares ($`s_B = B / Y`$) as sufficient statistics for productive factor throughput ($`X = \varepsilon \cdot Q`$).

Under neoclassical growth accounting (Hulten 1978), if competitive markets exhibit unit-elastic substitution ($`\sigma = 1`$) and zero institutional wedges, a factor's output elasticity equals its nominal cost share ($`\eta_X = s_B`$). Under that benchmark, an input commanding a tiny fraction of national expenditure cannot generate large macroeconomic fluctuations, and a public budget line is evaluated symmetrically by its gross fiscal cost.

`IGWelfare` demonstrates empirically and analytically why this benchmark fails across both physical production and intergenerational human-capital formation:

1. **Biophysical Production & `NDC` Transition (`Phase2_5Sector` & Keen, Ayres & Standish):** Distinguishing **energy price parameters** ($`p_E`$), imported fossil-fuel foreign-exchange leakage (`Import_FX_Share`), and gross primary energy ($`E`$) from **useful exergy** ($`U = \varepsilon E`$)—the quality-adjusted physical work actually converted by capital and labor.
2. **Human Capital & Public Provision (`FI_FBC1987` vs. `NZ_Dunedin1972`):** Distinguishing **nominal public outlays and unit wages** (such as aggregate education spend `G_ece_s` or passive geographic/housing cash transfers) from **effective developmental and mentoring intensity** entering the Cunha–Heckman skill operator (`daruich_mult`) and child transition matrices.

Analyzing these together requires zero loose metaphor between physics and welfare. Both are exact mathematical instances of **conversion efficiency ($`\varepsilon`$) loosening a complementary ($`\sigma < 1`$) bottleneck** where market or fiscal prices fail to reflect shadow value.

---

## 2. Exergy as a Production Factor vs. Energy Price as a Parameter

### 2.1 The Cost-Share Fallacy in Neoclassical Production

In standard macroeconomic models, energy is either omitted from the value-added production function $`Y = A K^{\alpha} H^{1-\alpha}`$ or enters as a separable third input $`Y = A K^{\alpha} H^{\beta} E^{\gamma}`$ calibrated to energy's nominal GDP share ($`0.04 \le \gamma \le 0.06`$).

Steve Keen, Robert Ayres, and Russell Standish (2019), building on Ayres and Warr (2005, 2009) and Brockway et al. (2021), establish three structural failures in that parameterization:

* **Expenditure Share Misstates Physical Indispensability:** Under $`\gamma = 0.05`$ and Cobb–Douglas unitary substitution ($`\sigma = 1`$), a 50% reduction in physical energy availability implies an output loss of only $`1 - 0.5^{0.05} \approx 3.4\%`$. Physically, capital machinery cannot operate and labor cannot perform work without continuous energy throughput.
* **Price Shocks vs. Physical Conversion Bottlenecks:** Modeling energy solely via an exogenous price parameter $`p_E`$ assumes firms and households smoothly substitute capital or labor for energy along a continuous isoquant. When short-run elasticity of substitution is sharply below unity ($`\sigma_{KL,X} \ll 1`$), cost shares severely understate marginal physical productivity during supply constraints, dry-year hydro shortfalls, or decarbonization transitions (Baqaee & Farhi 2019).
* **Solow Residual Contamination:** Secular growth attributed by standard growth accounting to exogenous Total Factor Productivity ($`A`$) closely tracks aggregate improvements in **exergy conversion efficiency** ($`\varepsilon_t`$)—the historical shift from low-efficiency thermal/combustion processes to high-efficiency electric traction, heat pumps, and industrial control.

### 2.2 Capital as an Exergy Conversion Conduit

Keen, Ayres, and Standish reformulate production by recognizing that capital $`K`$ and labor $`H`$ do not generate physical output autonomously; physical capital is an engineered structure that harnesses an inflow of **exergy** (available work potential) and directs it into economically useful tasks.

Let $`E_k`$ denote gross primary or final energy input in region $`k`$, and let $`\varepsilon_k \in (0, 1)`$ denote technical conversion efficiency mapping gross energy into **useful work (exergy)**:

$$
U_k = \varepsilon_k E_k
$$

The unrecovered fraction $`(1 - \varepsilon_k) E_k`$ dissipates as waste heat or friction without generating economic value. In `IGWelfare`'s regional general-equilibrium production block (`NZ_4Region_Master.m` and `Compute_5Sector_Exergy_Equilibrium.m`), useful exergy activates the regional capital-labor bundle inside a nested putty-clay CES composite with tight complementarity ($`\sigma_{KL,X} \ll 1`$, proved formally in **Document 2A**, Section `2.4.1`, Proposition `[2A-Prop-Factor1]`):

$$
Y_{s,k} = Z_{s,k} \left\lbrack \left(1 - \omega_{X,s}\right) \left( K_{s,k}^{\alpha_k} H_{s,k}^{1-\alpha_k} \right)^{\frac{\sigma_{KL,X} - 1}{\sigma_{KL,X}}} + \omega_{X,s} X_{s,k}^{\frac{\sigma_{KL,X} - 1}{\sigma_{KL,X}}} \right\rbrack^{\frac{\sigma_{KL,X}}{\sigma_{KL,X} - 1}}
$$

### 2.3 Empirical Macro-Sector & `NDC` Validation in `NZ_Dunedin1972`

`IGWelfare`'s Phase 2 five-sector baseline (`Table_Phase2_5Sector_Baseline_Dunedin_22.csv`, anchored to Marilyn Waring's unpaid/volunteer accounting alongside `SNA` capital and foreign-exchange shares) and Nationally Determined Contribution compliance ledger (`Table_Phase2_NDC_Exergy_Compliance_Dunedin_22.csv`) quantify the macroeconomic divergence between price/rollback regimes and physical exergy conversion:

#### Table 2.1: Phase 2 Five-Sector Capital, Volunteer Conversion, and Import-FX Structure (`NZ_Dunedin1972`)

| Macro Sector | Annual Spend (BNZD) | Paid Labor (kFTE) | Volunteer Labor (kFTE) | Capital Stock (BNZD) | Import / FX Leakage Share | Structural Exergy & Conversion Role |
|---|---:|---:|---:|---:|---:|---|
| `Sector_1_Primary` | `38.5` | `148.0` | `2.5` | `165.0` | `18.0%` | High process-heat & freight intensity; rural export base. |
| `Sector_2_Knowledge` | `54.0` | `305.0` | `1.5` | `92.0` | `12.0%` | High skill intensity $`H_k`$; low physical dissipation & FX leakage. |
| `Sector_3_Market_NonTrad` | `211.0` | `1,352.0` | `4.0` | `640.0` | `20.0%` | Dominant domestic capital conduit (NZD 640B, housing & commercial). |
| `Sector_4A_Civic_Human` | `102.3` | `591.0` | **`76.0`** | `148.0` | **`11.0%`** | Core human-capital & Waring civic sector; **87.9% of national volunteer kFTE** and lowest FX leakage. |
| `Sector_4B_Public_Infra` | `22.8` | `53.5` | `3.0` | `277.0` | `18.6%` | Grid, transport, and public civil capital enabling $`\Delta \varepsilon_k > 0`$. |
| `Sector_5_Defence` | `6.0` | `15.8` | `1.5` | `22.0` | **`62.0%`** | High external import/FX leakage (`0.62`); minimal domestic factor multiplier. |

Pairing this sectoral structure with the `NDC` transition regimes (`Table_Phase2_NDC_Exergy_Compliance_Dunedin_22.csv`) demonstrates why raising domestic conversion efficiency ($`e_N = 0.88`$ vs. $`e_F = 0.30`$, a $`2.93\times`$ useful-work step-change) dominates fossil lock-in and offshore carbon-credit purchases:

#### Table 2.2: `NDC` Exergy Conversion vs. Rollback & Offshore Credit Liability (`NZ_Dunedin1972`)

| `NDC` Policy Regime | `NDC1` Emissions Gap ($`\mathrm{MtCO_2e}`$) | Offshore Liability PV @ 2% (BNZD) | Offshore Liability PV @ 8% (BNZD) | `LTFM`-Anchored National Welfare (% CE) |
|---|---:|---:|---:|---:|
| `1_NDC_Rollback_And_Pine_Cliff` | `61.2` | `21.77` | `15.77` | **`-22.57%`** |
| `2_Phase2_Exergy_CleanGreen` | `18.2` | `4.82` | `3.78` | **`+24.92%`** |
| `3_Exergy_Plus_Doc1E_Taiao` | `11.7` | `1.85` | `1.71` | **`+28.32%`** |

* **Rollback Trap (`-22.57%` CE):** Deferring domestic electrification and relying on exotic pine monocultures leaves New Zealand exposed to a $`61.2\ \mathrm{MtCO_2e}`$ compliance gap (NZD 15.77B–21.77B deadweight offshore transfer) plus imported fuel FX drain (`0.18–0.20` share).
* **Domestic Exergy Upgrade (`+24.92%` CE to `+28.32%` CE with Taiao/Civic):** Upgrading end-use conversion $`\varepsilon_k`$ (industrial electrification, heat pumps, transport traction) slashes the `NDC1` gap by 70% (`61.2` to `18.2` $`\mathrm{MtCO_2e}`$) while expanding domestic useful work $`X_{s,k}`$. Layering **Document 1E** grassroots ecological and civic stewardship (`Sector_4A_Civic_Human`'s `76.0 kFTE` volunteer conduit) cuts the residual gap to `11.7` $`\mathrm{MtCO_2e}`$ (NZD 1.71B PV @ 8%) and lifts national welfare to **`+28.32%` CE**.

---

## 3. The Wedge Additionality Identity: Theory & Literature Synthesis

A central analytical question in `IGWelfare` is why constructive synergy wedges (`Table19` and `Table19E`) generate welfare and output gains an order of magnitude larger than their nominal fiscal budget shares ($`s_B = \Delta B / Y_0`$), whereas passive cash or price-captured subsidies yield near-zero long-run additionality.

### 3.1 Formalizing the Wedge Additionality Law

Let policy lever $`k`$ purchase raw input quantity $`Q_k`$ at unit price $`P_k`$, incurring nominal outlay $`B_k = P_k \cdot Q_k`$ (with GDP share $`s_{B,k} = B_k / Y`$). Institutional or physical conversion maps $`Q_k`$ into effective factor throughput $`X_k = \varepsilon_k \cdot Q_k`$, which enters aggregate output or lifecycle human-capital production with structural elasticity $`\eta_k = \frac{\partial \ln Y}{\partial \ln X_k}`$.

Taking log differentials of $`X_k = \varepsilon_k (B_k / P_k)`$ yields the divergence between effective converted factor growth and nominal budget growth:

$$
d \ln X_k - d \ln B_k = d \ln \varepsilon_k - d \ln P_k
$$

Evaluating total output (or consumption-equivalent welfare) response relative to nominal outlay yields the **Wedge Additionality Identity** (proved formally in **Document 2B**, Section `7.4.1`, Proposition `[2B-Prop-Wedge1]`):

$$
\Lambda_k^Y \equiv \frac{d Y}{d B_k} = \left( \frac{\eta_k}{s_{B,k}} \right) \left( 1 + \frac{d \ln \varepsilon_k - d \ln P_k}{d \ln B_k} \right)
$$

This identity establishes two exact conditions governing policy leverage in `IGWelfare`:

1. **Price-Capture Annihilation ($`d \ln P_k \approx d \ln B_k, \ d \ln \varepsilon_k = 0 \implies \Lambda_k^Y \to 0`$):** When increased nominal spending is absorbed by inelastic supply prices—such as urban landlord rent capture under demand-side housing supplements, Baumol/cost-of-living wage inflation (`Q_k` / `nu_col_index`) without expanded mentoring `FTE`, or uninsulated resistive heating bills—the right-hand factor collapses toward zero regardless of how essential the underlying domain is.
2. **Super-Unitary Bottleneck Leverage ($`\eta_k \gg s_{B,k}`$ and $`d \ln \varepsilon_k > 0 \implies \Lambda_k^Y \gg 1`$):** Under Hulten's Theorem ($`\sigma = 1`$, frictionless competition), $`\eta_k = s_{B,k}`$, bounding standalone leverage near unity. When complementarity is tight ($`\sigma < 1`$ across capital-exergy or Cunha–Heckman developmental stages) and policy activates a high-efficiency conversion structure ($`\Delta \ln \varepsilon_k > 0`$, such as volunteer civic clubs or dual-gate ECE + mentoring), both terms multiply—producing outsized macro and fiscal additionality from a small nominal budget share.

### 3.2 Position in the Academic Literature

The Wedge Additionality Identity synthesizes three previously separate research programs inside a single general-equilibrium OLG framework:

* **Production Networks & Hulten's Theorem Breakdown (Hulten 1978; Baqaee & Farhi 2019 *Econometrica*):** Baqaee and Farhi prove that in production networks with complementarities ($`\sigma < 1`$) and allocative wedges, microeconomic efficiency shocks generate macroeconomic output effects far exceeding Domar/expenditure weights (applied empirically to energy cutoffs by Bachmann et al. 2022). `IGWelfare` extends this exact network-bottleneck operator to **intergenerational human-capital transitions**.
* **Biophysical Exergy Growth Accounting (Ayres & Warr 2005, 2009; Keen, Ayres & Standish 2019):** Demonstrates that physical conversion efficiency $`\varepsilon`$ drives secular growth residuals, while `IGWelfare` embeds that mechanism inside household lifecycle optimization and sovereign debt (`LTFM`) accounting.
* **Baumol Cost Disease & Marginal Value of Public Funds (Baumol 1967; Cunha, Heckman & Schennach 2010; Hendren & Sprung-Keyser 2020 *QJE*):** Hendren and Sprung-Keyser establish empirically that early-childhood health and education investments achieve infinite/self-financing MVPFs while passive adult transfers cluster below `1.0`. `IGWelfare` provides the structural general-equilibrium decomposition explaining *why*: separating unit-price capture ($`d \ln P_k`$) from physical/pedagogical conversion ($`d \ln \varepsilon_k`$) and cross-stage dynamic complementarity.

---

## 4. Cross-Country Empirical Validation: `NZ_Dunedin1972` vs. Finland (`FI_FBC1987`)

Validating `IGWelfare` on Finland's post-1960s institutional reforms (`FI_FBC1987`) alongside New Zealand (`NZ_Dunedin1972`) tests the **Nominal Outlay vs. Converted Factor** framework out of sample.

### 4.1 Teacher Salaries vs. Instructional Intensity (`G_ece_s`)

In baseline fiscal specifications, public early-childhood and schooling expenditure in region $`k`$ (`G_ece_s`) is recorded as a single aggregate outlay. Economically, that budget line decomposes into unit factor price versus converted pedagogical volume (**Document 2A**, Section `3.3.1`, Proposition `[2A-Prop-Factor2]`):

$$
B_{\mathrm{edu},s,k} = W_{\mathrm{teach},k}(Q_k) \cdot \mathrm{FTE}_{s,k} + \mathrm{Other}_{\mathrm{edu},s,k}
$$

* **Unit Wage & Regional Cost-of-Living Deflator ($`W_{\mathrm{teach},k}`$):** In high-rent New Zealand regions (`Auckland` and `Large`), housing cost pressure (`Q_k` / `nu_col_index`) absorbs nominal `G_ece_s` merely to maintain baseline educator retention against outside wage options ($`d \ln P_k > 0`$).
* **Converted Instructional Intensity ($`G_{\mathrm{ECE},s}^{\mathrm{eff}}(k) = \varepsilon_{\mathrm{ped},s,k} \cdot \mathrm{FTE}_{s,k}`$):** Finland's *peruskoulu* reform paired moderate statutory OECD teacher wage ratios with high institutional conversion efficiency $`\varepsilon_{\mathrm{ped}}`$—research-based Master's preparation, classroom autonomy, low inspection/administrative overhead, and immediate small-group learning support (*erityisopetus*) preventing early skill gaps from compounding into long-term hardship.
* **The `daruich_mult` Parameter-Binding Lesson:** Auditing `FI_FBC1987` exposed why regional and regime skill multipliers (`daruich_mult` in `Compute_LeeSeshadri_Counterfactuals.m`) must bind dynamically rather than collapsing to a static scalar: flattening `daruich_mult` across regimes is mathematically identical to suppressing $`\varepsilon_k`$, misattributing institutional conversion gains to unexplained residuals.

### 4.2 Regional Frontier Saturation & Cost-of-Living Attenuation (`Table5` Audit)

The exported Lee–Seshadri counterfactual matrix (`Table5_4Region_LeeSeshadri_Output_Welfare.csv`) reveals two striking empirical contrasts between New Zealand and Finland that directly confirm concave bottleneck saturation and urban cost-of-living attenuation:

#### Table 4.1: Lee–Seshadri Regional Earnings (`Ebar_LR`) and Welfare (`CE_LR`) Counterfactuals (`NZ_Dunedin1972` vs. `FI_FBC1987`)

| Counterfactual Lever | NZ `Ebar_LR` Rural | NZ `Ebar_LR` Auckland | NZ `CE_LR` Rural | NZ `CE_LR` Auckland | FI `Ebar_LR` Rural | FI `Ebar_LR` Helsinki | FI `CE_LR` Rural | FI `CE_LR` Helsinki |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `P0_Early_0to5` | `+1.474%` | `+0.971%` | **`+0.887%`** | **`+0.830%`** | `+0.577%` | `+0.363%` | **`-0.051%`** | **`-0.040%`** |
| `P1P2_Late_6to17` | **`+2.043%`** | **`+1.375%`** | `+1.423%` | `+1.610%` | **`+1.758%`** | **`+1.737%`** | `+0.921%` | `+1.456%` |
| `BN_FrontLoad` | `-0.674%` | `-0.370%` | `-0.606%` | `-0.349%` | `-0.154%` | `-0.258%` | `-0.235%` | `-0.270%` |
| `P0_Plus_GrantE` | `+3.284%` | `+3.830%` | `+4.932%` | `+6.150%` | `+2.771%` | `+3.275%` | `+3.612%` | `+4.810%` |

1. **Starved Bottleneck (NZ) vs. Frontier Saturation (Finland) in `P0_Early_0to5`:** Expanding `P0` early-childhood investment in New Zealand delivers substantial long-run earnings (`+0.97%` to `+1.47%`) and net welfare gains (`+0.83%` to `+0.89%` CE) because NZ's baseline leaves a wide early-life skill gap (`25.79%` at `i_c = 0`). In Finland (`FI_FBC1987`), universal *neuvola* clinics and Nordic `ECEC` already operate near the concave Stage-1 frontier; adding extra tax-financed `P0` spend at `tau_l = 0.325` encounters diminishing physical returns ($`\Delta \ln \varepsilon \approx 0`$), yielding smaller earnings gains (`+0.36%` to `+0.58%`) and slightly negative net welfare (`-0.04%` to `-0.05%` CE) unless paired with Stage-2 mentoring and `Aspects 2 & 3` tax/land rebalancing (`P0_Plus_GrantE` = `+3.61%` to `+4.81%` CE).
2. **Auckland Cost-of-Living Compression vs. Helsinki *Peruskoulu* Uniformity in `P1P2_Late_6to17`:** Under `P1P2` schooling expansion, New Zealand's long-run earnings response drops by nearly one-third in `Auckland` (`+1.375%`, with short-run `Ebar_SR = -0.183%`) compared to `Rural` (`+2.043%`), `Small` (`+1.961%`), and `Large` (`+1.962%`), reflecting metropolitan housing and cost-of-living absorption (`Q_Auckland = 3.10`). In Finland, `Ebar_LR` is virtually invariant across space—`+1.758%` in `Rural` versus **`+1.737%` in `Helsinki`**—confirming uniform national pedagogical conversion.

### 4.3 Scale-Free Hulten Leverage Audit (`Table19E` & `Table20` Steady State)

Computing the ratio of realized `SS2` steady-state welfare gains (`Table19E`) to Year-60 steady-state gross mirror-investment outlays $`s_{B,k}`$ (`Table20`, via `src/ledgers/Compute_Wedge_Additionality_Table.m`) quantifies how conversion efficiency and complementarity govern leverage across both twins:

#### Table 4.2: Empirical Hulten Leverage Ratios ($`\Lambda_k = \mathrm{Realized\ SS2\ CE\%} / s_{B,k}`$)

| Policy Lever / Constructive Stack | Gross Outlay $`s_{B,k}`$ (% CE) | NZ `SS2` Gain (% CE) | FI `SS2` Gain (% CE) | NZ Leverage ($`\Lambda_{\mathrm{NZ}}`$) | FI Leverage ($`\Lambda_{\mathrm{FI}}`$) | Structural Conversion Mechanism |
|---|---:|---:|---:|---:|---:|---|
| `L03E–L11E` Arts & Civic Seed Cap (`JoinerPassport`) | `0.140%` | `+3.401%` | `+3.366%` | **`24.29x`** | **`24.04x`** | **Extreme Civic Conversion ($`\varepsilon_{\mathrm{civic}} \gg 1`$):** Tiny seed outlay mobilizes `76–79 kFTE` volunteer scaffolding across all 4 synergy gates; net unrecovered outlay reaches `0%` by Year 16. |
| `L02` Tuakana Mentoring (Isolated) | `0.550%` | `+1.562%` | `+1.535%` | **`2.84x`** | **`2.79x`** | Direct relational mentoring prevents adolescent skill loss with minimal overhead dissipation. |
| `L01` Universal ECE — First 2000d (Isolated) | `1.350%` | `+2.457%` | `+2.406%` | **`1.82x`** | **`1.78x`** | Relieves early developmental plasticity bottleneck; beats Hulten `1.0x` cost-share bound standalone. |
| `L01 + L02 + L03_WEDGE1` Dual-Gate HC Stack | `1.900%` | `+7.520%` | `+7.490%` | **`3.96x`** | **`3.94x`** | Cunha–Heckman dynamic complementarity ($`\varphi_2 = -0.95`$): early readiness (`L01`) preserved by adolescent mentoring (`L02`) adds `+3.50%` NZ / `+3.55%` FI pure synergy wedge. |
| `L05` Age-20 Youth Grant (Isolated) | `0.600%` | `+0.893%` | `+0.872%` | **`1.49x`** | **`1.45x`** | Relieves $`a \ge 0`$ borrowing constraint at adulthood launch; unlocks `+2.46%` `L07_WEDGE2` when paired with LVR/whānau housing reform. |
| `L06` Passive Geo Income Transfer (vs. Yr 0 $`s_B`$) | `0.417%` | `+0.146%` | `+0.149%` | **`0.35x`** | **`0.36x`** | **Zero Structural Conversion ($`\Delta \ln \varepsilon = 0`$):** Cushions `SS1` hardship (`+0.81%`), but decays in `SS2` (`0.57%` of total package; `1.22x` vs. shrunken `0.12%` Yr-60 outlay). |
| **Full 7-Segment Package (Base `Table19`/`20`)** | `2.620%` | `+25.449%` | `+25.479%` | **`9.71x`** | **`9.72x`** | **55.9% (NZ) & 56.9% (FI)** of steady-state gain arises strictly from non-linear synergy wedges (`14.22%` vs. `11.23%` isolated sum in NZ). |
| **Full Arts-Enabled Package (`Table19E`/`20`)** | `2.760%` | `+28.824%` | `+28.820%` | **`10.44x`** | **`10.44x`** | Self-financing in actuarial `CBAx` by **Year 4** (`+1.19%` NZ / `+1.06%` FI); arrests baseline `LTFM` deficit drift (`-6.24%` NZ vs. `-3.48%` FI at Year 60). |

---

## 5. Audited Structural Isomorphisms Across `IGWelfare`

Across every module of `IGWelfare`, separating **nominal budget flow ($`P \cdot Q`$)** from **converted factor throughput ($`\varepsilon \cdot Q`$)** resolves apparent fiscal paradoxes without adding ad-hoc behavioral assumptions:

| Domain in `IGWelfare` | Nominal Outlay / Price Parameter ($`P \cdot Q`$) | Conversion Conduit ($`\varepsilon`$) | Effective Factor Input ($`\varepsilon \cdot Q`$) | Cost-Share / Ledger Fallacy Exposed |
|---|---|---|---|---|
| **1. Macro Production & `NDC` (`Phase2`)** | Fossil energy bill $`p_F^{\ast} F_t`$; offshore carbon credits (`NZD 21.77B` PV) | Electrification ($`e_N = 0.88`$), heat-pump COP, domestic grid/transport (`Sector_4B`) | Useful physical work $`X_{s,k}`$ activating $`K_{s,k}`$ | ~4%–5% GDP energy cost share masks `-22.57%` CE rollback penalty vs. `+28.32%` CE domestic exergy + Taiao gain. |
| **2. Public Education (`G_ece_s`)** | Nominal spend $`W_{\mathrm{teach},k}\mathrm{FTE}_{s,k} + \mathrm{Other}_{s,k}`$ | Master's autonomy, retention stability, early learning triage ($`\varepsilon_{\mathrm{ped},s,k}`$) | Classroom & mentoring intensity entering Cunha–Heckman | High-COL wage capture (`Q_k` in Auckland `P1P2`: `+1.38%` vs. `+2.04%` Rural) masks flat real mentoring volume. |
| **3. Housing & Domestic Thermal Comfort** | Accommodation Supplement (`AS`); resistive utility spend $`p_E e_{\mathrm{heat}}`$ | Housing supply elasticity; insulation & heat-pump COP ($`\varepsilon_{\mathrm{housing}}`$) | Tenure stability & Stone–Geary thermal floor $`\bar{e}_k`$ | Subsidizing rent/bills in supply-constrained, leaky rentals inflates landlord rents ($`d\ln P \approx d\ln B`$) while childhood hardship and respiratory hazards persist. |
| **4. Grassroots Civic, Arts & Sport (`Doc 1E`)** | Seed grants (`JoinerPassport = 0.14%` CE; `Vote Arts` / council funds) | `76–79 kFTE` volunteer network in `Sector_4A_Civic_Human` ($`\varepsilon_{\mathrm{civic}}`$) | Adolescent pro-social belonging, psychosocial resilience & retention | Tiny budget share (<0.2% GDP) makes cuts (`coalition_2024_shocks`) look harmless in static ledgers while destroying a **24.3x** conversion multiplier. |
| **5. 6-Gate Fiscal Architecture (`Table14`)** | Aggregate social outlays across all 6 lifecycle gates | Developmental plasticity window ($`\partial \Theta_s / \partial I_{s,k}`$) | Adult human capital $`H_k`$ & net fiscal solvency (`LTFM`) | Static ledgers treat NZD 1 of early preventative investment and NZD 1 of late-stage acute remediation (`Exits 1, 2, & 4`) as equivalent outlays. |

### 5.1 Housing Subsidies and Residential Thermal Efficiency

Low-asset and present-biased ($`\beta_{\mathrm{hyp}} = 0.72`$, borrowing-constrained $`a^{\prime} \ge 0`$) households disproportionately occupy poorly insulated rentals heated by resistive electric appliances ($`\varepsilon_{\mathrm{housing}}`$ low) rather than insulated dwellings with high-COP heat pumps ($`\varepsilon_{\mathrm{housing}}`$ `3x–4x` higher).

* Child retention on the thriving developmental trajectory—avoiding downward transitions into struggling/hardship states, state care, and avoidable hospitalization—depends on **delivered indoor thermal comfort** and compressed subsistence energy burdens ($`\Delta \bar{e}_{\mathrm{elec},k}`$), not nominal kilowatt-hours billed.
* Passive rent transfers in supply-inelastic urban markets (`L06` / un-reformed `AS`) get capitalized into rents ($`d \ln P_k > 0`$), whereas LVR/whānau tenure access (`L07_WEDGE2`) and *Rewiring Aotearoa* electrification upgrades raise $`\varepsilon_{\mathrm{housing}}`$ directly, cutting the shadow price of domestic comfort permanently.

### 5.2 Flow-Network Accounting: Conserved Headcount vs. Non-Conserved Fiscal Potential

In `IGWelfare`'s cohort and fiscal Sankey visualizations (`Plot_ChildFates_SSankey.m`, `Plot_ChildFiscal_SSankey.m`, `Table14`, and `Table15`), separating conserved population mass from productive human-capital potential explains why timing dominates fiscal solvency:

* **Population Headcount Conservation:** Cohort mass $`\sum_{i} p_{g,i} = 1`$ is conserved across lifecycle gates.
* **Non-Conserved Human-Capital & Fiscal Potential:** Because Cunha–Heckman skill formation exhibits declining plasticity with age and strong cross-stage complementarity (`L03_WEDGE1` + `L08_WEDGE3` = `9.01%` CE in NZ, `9.22%` CE in Finland), allowing children to slip into struggling/skill-loss trajectories forfeits compounding skill gains permanently. Downstream spending in acute remediation gates (`Exits 1, 2, & 4`: Care, Avoidable Hospitalization/CAMHS, Benefit/LOPE/Justice) acts as high-cost containment rather than human-capital creation—driving the baseline `LTFM_Annual_Deficit_Flow` sinkhole (`-6.24%` CE in NZ vs. `-3.48%` CE in Finland by Year 60) while distorting `Tier 1` input-cost `SNA` GDP (**Document 2A**, Section `2.5.1`, Proposition `[2A-Prop-Civic1]`).

---

## 6. Non-Invasive Implementation Architecture

In keeping with `IGWelfare` and `VFIToolkit-matlab` (`MixHorz` / `UFHorz`) design standards, every factor-vs.-outlay decomposition is implemented **without adding endogenous state variables to the 4D/5D household Bellman array**:

1. **Diagnostic Audit Layer (`src/ledgers/Compute_Wedge_Additionality_Table.m`):** Post-processes exported `Table19E`, `Table20`, and `Table5` CSVs across `NZ_Dunedin1972` and `FI_FBC1987` in `<0.2 s` to report scale-free Hulten Leverage Ratios ($`\Lambda_k`$) and regional conversion contrasts.
2. **Profile & Ledger Teacher-Wage Split (`regions.csv` & `Apply_Policy_Regime.m`):** Decomposes `G_ece_s` into a regional cost-of-living educator wage index ($`W_{\mathrm{teach},k}(Q_k)`$, linked to `nu_col_index`) and real converted mentoring intensity (`fte_intensity_mult`), passing only real converted intensity into `HumanCapital_Lifecycle_aprimeFn.m` / `daruich_mult` while reporting the wage/overhead split in the actuarial tables.
3. **Outer-Loop 5-Sector Exergy & Household Subsistence Conditioning (`Compute_5Sector_Exergy_Equilibrium.m` & `ReturnFn_SpatialHH_Compact4D.m`):** Evaluates dual-fuel exergy $`X_{s,k}(e_N N_{s,k}, e_F F_{s,k})`$ in the outer general-equilibrium price block and maps household electrification into the regional Stone–Geary subsistence floor $`\bar{e}_k`$ (`1.0x` Bellman state-space multiplier).

---

## 7. Formal Proof & Specification Routing Ledger

### 7.1 Routed to **[Document 2A](../Document%202A.md)** (Micro-Foundations, Core Agent Problems, & Sectoral Operators)

* **Section `2.4.1` — Proposition `[2A-Prop-Factor1]` (Putty-Clay Exergy Bottlenecks, Dual-Fuel Electrification Leverage, and Small-Open-Economy Sovereign Spread Closure):** Proves why short-run putty-clay complementarity ($`\sigma_{KL,X} \to 0`$) invalidates the ~4% `KLE` cost-share approximation, derives regional real-wage compression under price-only carbon shocks, and establishes the triple small-open-economy dividend ($`e_N / e_F = 2.93\times`$, `NDC` liability elimination, and `NFA` sovereign spread compression).
* **Section `2.5.1` — Proposition `[2A-Prop-Civic1]` (Polycentric Volunteer Co-Production Gearing, `SNA` Input-Cost Blindness, and Asymmetric Disinvestment Sinkholes):** Proves why statutory civic seed grants crowd in `76–79 kFTE` of Ostrom–Waring volunteer co-production (`24.3x` leverage), why `Vote Arts` / `C15` cuts and `Super Age 70` trigger nonlinear reactive remediation sinkholes, and why `Tier 1` input-cost `SNA` accounting mis-signs `~65,000 FTE` reactive-to-capacitating labor release.
* **Section `3.3.1` — Proposition `[2A-Prop-Factor2]` (Observational Equivalence Failure in Aggregate Public Skill Outlays — Metropolitan Cost-of-Living Deflation vs. Frontier Saturation):** Proves non-identifiability of nominal `B_edu,s,k` under metropolitan `Q_k` *Kaiako* cost-of-living absorption (`Auckland` vs. `Helsinki` in `P1P2_Late_6to17`) and derives the concave Stage-1 saturation threshold explaining why standalone tax-financed `P0_Early_0to5` is strongly welfare-positive in `NZ_Dunedin1972` (`+0.83%` to `+0.89%` CE) yet slightly negative in saturated `FI_FBC1987` (`-0.04%` to `-0.05%` CE).

### 7.2 Routed to **[Document 2B](../Document%202B.md)** (Coupled General-Equilibrium Synthesis, Calibration, & Attribution)

* **Section `7.4.1` — Proposition `[2B-Prop-Wedge1]` (Breakdown of Hulten Cost-Share Sufficiency and the Wedge Additionality Identity):** Master derivation of $`\Lambda_k^Y = (\eta_k / s_{B,k})\lbrack 1 + (d\ln\varepsilon_k - d\ln P_k)/d\ln B_k \rbrack`$ and off-diagonal Topkis Hessian positivity ($`\propto 1/\sigma`$), explaining why Constructive Synergy Wedges generate `>54%` of steady-state welfare across both `NZ_Dunedin1972` and `FI_FBC1987`.
* **Section `9` (`[Ref 9]` & `[Ref 33]`) — Master Reference Anchors:** Integrates Hulten (1978) and Baqaee & Farhi (2019) alongside Keen, Ayres, & Standish (2019) in `[Ref 9]`, and Hendren & Sprung-Keyser (2020) alongside NZ Treasury `CBAx` Circular 2024/15 guidance in `[Ref 33]`.
* **Queued Calibration Extension `[2B-Spec-Edu1]`:** Non-invasive profile/ledger schema splitting `G_ece_s` into regional educator wage indexation (`nu_col_index` / `Q_k`) versus converted instructional `FTE` across `profiles/*/regions.csv` and `Apply_Policy_Regime.m`.

---

## References

* Ayres, R. U., & Warr, B. (2005). Accounting for growth: The role of physical work. *Structural Change and Economic Dynamics*, 16(2), 181–209.
* Ayres, R. U., & Warr, B. (2009). *The Economic Growth Engine: How Energy and Work Drive Material Prosperity*. Edward Elgar.
* Bachmann, R., Baqaee, D., Bayer, C., Kuhn, M., Löschel, A., Moll, B., Peichl, A., Pittel, K., & Schularick, M. (2022). What if? The economic effects for Germany of a stop of energy imports from Russia. *Economica*, 91(363), 757–800.
* Baqaee, D. R., & Farhi, E. (2019). The macroeconomic impact of microeconomic shocks: Beyond Hulten's Theorem. *Econometrica*, 87(4), 1155–1203.
* Baumol, W. J. (1967). Macroeconomics of unbalanced growth: The anatomy of urban crisis. *American Economic Review*, 57(3), 415–426.
* Brockway, P. E., Sorrell, S., Semieniuk, G., Heun, M. K., & Court, V. (2021). Energy efficiency and economy-wide rebound effects: A review of the evidence and its implications. *Renewable and Sustainable Energy Reviews*, 141, 110781.
* Cunha, F., Heckman, J. J., & Schennach, S. M. (2010). Estimating the technology of cognitive and noncognitive skill formation. *Econometrica*, 78(3), 883–931.
* Hendren, N., & Sprung-Keyser, B. (2020). A unified welfare analysis of government policies. *Quarterly Journal of Economics*, 135(3), 1209–1318.
* Hulten, C. R. (1978). Growth accounting with intermediate inputs. *Review of Economic Studies*, 45(3), 511–518.
* Keen, S., Ayres, R. U., & Standish, R. (2019). A note on the role of energy in production. *Ecological Economics*, 157, 40–46.
* Labrousse, C., & Perdereau, Y. (2026). Geography versus income: The heterogeneous effects of carbon taxation. *Journal of Monetary Economics*, 161, 103962.
* Ostrom, E. (1996). Crossing the great divide: Coproduction, synergy, and development. *World Development*, 24(6), 1073–1087.
* Waring, M. (1988). *Counting for Nothing: What Men Value and What Women Are Worth*. Allen & Unwin.