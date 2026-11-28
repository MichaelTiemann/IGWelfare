# Factor Conversion vs. Nominal Outlay: Reading Exergy Effects and Structural Isomorphisms in `IGWelfare`

**Status:** Technical Specification & Methodological Synthesis  
**Companion Routing:** Formal equilibrium proofs are routed to **Document 2A** (Theoretical Foundations); profile schemas, calibration tables, and post-hoc ledger identities are routed to **Document 2B** (Quantitative Calibration & Computational Architecture).

---

## 1. The Core Identification Problem: Nominal Cost Shares vs. Physical Conversion Factors

A pervasive specification error in standard macroeconomic and fiscal policy modeling is the **Price-Deflator vs. Real-Factor Confound**: using nominal expenditure ($P \cdot Q$) or market cost shares as sufficient statistics for productive throughput ($\varepsilon \cdot Q$).

In neoclassical growth accounting, if a factor commands a small share of nominal national expenditure, cost-share theorems assign it a commensurately small output elasticity. Similarly, in conventional public finance ledgers, if nominal spending on a public program rises, fiscal accounting records an expansion of public investment regardless of whether input prices, regional cost-of-living premia, or structural inefficiencies absorbed the outlay before it reached households.

`IGWelfare` encounters this exact structural problem across two domains that obey identical mathematical accounting:

1. **Biophysical Production (Keen, Ayres & Standish):** Distinguishing **energy price parameters** ($p_E$) and gross primary energy ($E$) from **useful exergy** ($U = \varepsilon E$)—the quality-adjusted physical work actually converted by capital and labor.
2. **Human Capital & Fiscal Provision (`FI_FBC1987` and `NZ_4Region_Master`):** Distinguishing **nominal public outlays and unit wages** (such as aggregate education spend `G_ece_s` or Accommodation Supplement transfers) from **effective developmental intensity** entering the Cunha–Heckman skill operator and child transition matrices.

Treating these together requires zero poetic analogy between physics and welfare. Both are strict instances of **omitted conversion efficiency ($\varepsilon$) and non-unitary substitution ($\sigma < 1$)** in multi-stage production and accounting networks.

---

## 2. Biophysical Foundations: Exergy as a Factor vs. Energy Price as a Parameter

### 2.1 The Cost-Share Fallacy in Neoclassical Production

In standard macroeconomic models, energy either is omitted entirely from the value-added production function $Y = A K^\alpha H^{1-\alpha}$ or enters as a separable third input $Y = A K^\alpha H^\beta E^\gamma$ calibrated under competitive factor-pricing assumptions where $\gamma$ equals energy's share of nominal GDP (typically $0.04 \le \gamma \le 0.06$).

Steve Keen, Robert Ayres, and Russell Standish demonstrate why this parameterization fails empirically and analytically:

* **Expenditure Share Misstates Physical Indispensability:** Under $\gamma = 0.05$ and Cobb–Douglas unitary elasticity of substitution ($\sigma = 1$), a $50\%$ reduction in physical energy availability implies an output loss of only $1 - 0.5^{0.05} \approx 3.4\%$. Empirically and physically, capital machinery cannot operate and labor cannot perform work without continuous energy throughput.
* **Price Shocks vs. Quantity/Efficiency Bottlenecks:** Modeling energy solely via an exogenous price parameter $p_E$ assumes firms and households smoothly substitute capital or labor for energy along a continuous isoquant. When short-run elasticity of substitution is sharply below unity ($\sigma \ll 1$), price-share weights severely underestimate marginal physical productivity during supply constraints, dry-year hydro shortfalls, or decarbonization transitions.
* **Solow Residual Contamination:** As Ayres and Warr show for historical US and international growth data, what standard growth accounting attributes to exogenous Total Factor Productivity ($A$) largely tracks secular improvements in **aggregate exergy conversion efficiency** ($\varepsilon_t$)—the transition from low-efficiency thermal/mechanical processes to high-efficiency electrification, traction, and industrial control.

### 2.2 Capital as an Exergy Conversion Conduit

Keen, Ayres, and Standish reformulate production by recognizing that capital $K$ and labor $H$ do not generate physical output autonomously; rather, physical capital is an engineered structure designed to harness an inflow of **exergy** (available work potential) and direct it into economically useful tasks.

Let $E_r$ denote gross primary or final energy throughput in region $r$, and let $\varepsilon_r \in (0, 1)$ denote aggregate technical conversion efficiency mapping gross energy into **useful work (exergy)**:

$$U_r = \varepsilon_r E_r$$

The unrecovered remainder, $(1 - \varepsilon_r) E_r$, dissipates as waste heat or friction without generating economic value. Rather than entering as a minor additive factor, useful exergy $U_r$ activates the regional capital stock $K_r$. In a general equilibrium overlapping-generations (OLG) production block suitable for `NZ_4Region_Master`, effective capital services are governed by a nested constant-elasticity-of-substitution (CES) composite with tight complementarity ($\sigma_{KU} \ll 1$):

$$Y_r = \tilde{A}_r \left[ \omega_r \left( K_r^{\alpha} U_r^{1-\alpha} \right)^{\frac{\sigma - 1}{\sigma}} + (1 - \omega_r) H_r^{\frac{\sigma - 1}{\sigma}} \right]^{\frac{\sigma}{\sigma - 1}}$$

*(Alternatively, in Keen's strict physical-conduit specification, $U_r = \varepsilon_r \cdot \kappa(K_r) \cdot e_K$, where $e_K$ is utilization-adjusted energy per machine unit, directly tying capital's marginal product to $\varepsilon_r$.)*

### 2.3 Policy Divergence: Changing $p_E$ vs. Changing $\varepsilon_r$

Separating the price parameter $p_E$ from the conversion factor $\varepsilon_r$ reverses standard policy conclusions across New Zealand's regional economies (`Rural`, `Small`, `Large`, `Auckland`) and connects directly to Nationally Determined Contribution (`ndc`) transition liabilities:

1. **Pure Price / Tax Parameter Shock ($\Delta p_E > 0$, $\Delta \varepsilon_r = 0$):** Raising domestic energy or carbon prices without upgrading conversion capital reduces optimal energy demand $E_r^*(p_E)$. Because $\sigma_{KU} \ll 1$, useful work $U_r$ contracts alongside $E_r$, depressing the marginal product of regional capital ($r$) and effective labor ($w_r$). Regions with lower baseline conversion efficiency or higher process-heat and freight intensity (`Rural` and `Small`) suffer disproportionate real wage compression relative to service-dense `Auckland`.
2. **Conversion Efficiency Upgrade ($\Delta \varepsilon_r > 0$):** Electrifying industrial heat, deploying high-COP heat pumps ($U_{\text{thermal}} \approx 3.5 E_{\text{elec}}$ vs. $0.95 E_{\text{elec}}$ for resistive heating), or upgrading grid/transport efficiency expands useful work $U_r$ **even as gross energy $E_r$ and nominal energy expenditure $p_E E_r$ fall**. In standard expenditure-based national accounts, falling $p_E E_r$ looks like a shrinking energy sector; in exergy factor accounting, rising $\varepsilon_r E_r$ acts as a structural productivity expansion.

---

## 3. Empirical Validation in `IGWelfare`: The Finland Twin (`FI_FBC1987`) and Teacher Wage Decomposition

The exact confound between nominal factor price and real converted input surfaced independently during the historical validation of `IGWelfare` against Finland's post-1960s institutional reforms (`FI_FBC1987`) and its comparison with New Zealand (`NZ_4Region_Master` / `NZ_Dunedin1972`).

### 3.1 The `G_ece_s` Legibility Problem

In a baseline fiscal specification, public early-childhood and schooling expenditure in region $k$, denoted $G_{\text{ece\_s}, k}$, enters as a single real-deflated scalar per child. While compact—preserving a lean 4D/5D Bellman state space—this aggregation conflates two economically distinct quantities:

$$\mathrm{Spend}_{\text{edu}, k} = W_{\text{teach}, k} \cdot \mathrm{FTE}_{\text{teach}, k} + \mathrm{Other}_{\text{edu}, k}$$

Here:
* $W_{\text{teach}, k}$ is the **unit price/wage parameter** required to attract, retain, and compensate educators in region $k$, subject to local housing and cost-of-living pressures (`nu_col_index`).
* $\mathrm{FTE}_{\text{teach}, k}$ (scaled by pedagogical preparation and institutional autonomy, $\varepsilon_{\text{edu}, k}$) determines **real instructional and mentoring intensity** $I_{\text{edu}, k} = \varepsilon_{\text{edu}, k} \cdot \mathrm{FTE}_{\text{teach}, k}$—the actual factor entering the Cunha–Heckman skill technology.
* $\mathrm{Other}_{\text{edu}, k}$ spans non-wage outlays, which divide between productive support (targeted special-needs intervention, nutrition) and non-instructional overhead (commercial property leases, administrative compliance).

### 3.2 Why Finland (`FI_FBC1987`) Exposes the Price-vs.-Factor Split

Finland's transition from a two-track system to universal comprehensive schooling (*peruskoulu*) in the 1970s, paired with the late-1970s mandate requiring research-based Master's degrees for primary and secondary teachers, provides an out-of-sample test of how `G_ece_s` operates:

1. **Moderate Statutory Wage Share, High Conversion Efficiency ($\varepsilon_{\text{edu}}$):** Relative to OECD GDP per capita, Finnish statutory teacher salaries have historically been competitive and stable rather than extreme outliers. Finland's compression of variance in $\log(h)$ and drop in intergenerational persistence ($T_{\text{IGE}}$) did not stem from inflating $W_{\text{teach}}$ alone; it stemmed from high pedagogical conversion efficiency $\varepsilon_{\text{edu}}$—professional autonomy, low bureaucratic inspection overhead, small-group early remediation (*erityisopetus*) preventing downward cohort transitions, and low teacher attrition.
2. **Cost-of-Living Wage Absorption in High-Rent NZ Regions:** In New Zealand (`Auckland` and `Large` metro profiles), severe housing cost inflation (`nu_col_index`) forces nominal $W_{\text{teach}, k}$ and school property charges upward merely to prevent acute teacher vacancies and attrition. If Treasury ledgers or un-decomposed model runs evaluate policy via aggregate nominal `G_ece_s`, a wage adjustment that merely offsets Auckland rent inflation looks identical to an expansion in classroom mentoring intensity—overstating expected human-capital gains unless $W_{\text{teach}, k}$ and real input volume $\mathrm{FTE}_{\text{teach}, k}$ are separated.
3. **Retention Thresholds as Conduit Maintenance:** Just as capital requires baseline maintenance energy before performing net useful work, $W_{\text{teach}, k}$ relative to regional outside wages and `nu_col_index` governs **turnover dissipation**. Below a retention threshold, high churn degrades $\varepsilon_{\text{edu}, k}$ (loss of institutional continuity and mentoring stability); above that threshold, raising $W_{\text{teach}, k}$ redistributes income and stabilizes retention, whereas expanding $\mathrm{FTE}_{\text{teach}, k}$ or targeted early support directly increases skill formation per cohort.

### 3.3 Methodological Parallel: The `daruich_mult` Parameter-Binding Lesson

Validating `FI_FBC1987` alongside `NZ_Dunedin1972` also exposed a silent structural hazard in `Compute_LeeSeshadri_Counterfactuals.m`: when a conversion multiplier (`daruich_mult`) is improperly bound across regimes or regional profiles, the model silently collapses heterogeneous skill-transmission intensity back into a uniform scalar.

Mathematically, mis-wiring `daruich_mult` in the skill block is identical to burying $\varepsilon_r$ inside an invariant constant in the production block: policy counterfactuals (`Apply_Policy_Regime.m`) then misattribute structural conversion differences across regimes (e.g., Finland's *peruskoulu* vs. NZ baseline) to household preferences or unexplained residuals rather than the institutional transmission channel itself.

---

## 4. Audited Structural Isomorphisms Across `IGWelfare`

With the **Nominal Outlay ($P \cdot Q$) vs. Effective Converted Factor ($\varepsilon \cdot Q$)** identity established in both production theory and the `FI_FBC1987` education ledger, four additional mechanisms inside `IGWelfare` exhibit exact structural isomorphism—each grounded in microeconomic constraints and fiscal accounting rather than loose analogy.

| Domain in `IGWelfare` | Nominal Price / Outlay Parameter ($P \cdot Q$) | Conversion Structure ($\varepsilon$) | Effective Factor Input ($\varepsilon \cdot Q$) | Cost-Share / Ledger Fallacy Exposed |
|---|---|---|---|---|
| **1. Macro & Regional Production** | Primary energy bill $p_E E_r$; carbon price shock | Industrial electrification, heat-pump COP, freight logistics ($\varepsilon_r$) | Useful physical work $U_r = \varepsilon_r E_r$ complementing $K_r$ | Low GDP energy cost share (~5%) masks severe output & wage sensitivity when $\sigma_{KU} \ll 1$. |
| **2. Public Education (`G_ece_s`)** | Nominal budget $W_{\text{teach},k}\mathrm{FTE}_k + \mathrm{Other}_k$ | Pedagogical quality, retention stability, low admin overhead ($\varepsilon_{\text{edu},k}$) | Effective mentoring & classroom intensity entering Cunha–Heckman | Rising nominal `G_ece_s` absorbed by `nu_col_index` or leases yields zero gain in child $\theta_{j+1}$. |
| **3. Housing Transfers & Domestic Thermal Comfort** | Accommodation Supplement (`AS`); household utility spend $p_E e_{\text{heat}}$ | Supply elasticity; building envelope insulation & heating COP ($\varepsilon_{\text{housing}}$) | Tenure stability & indoor thermal floor $u_{\text{heat}} = \varepsilon_{\text{housing}} e_{\text{heat}}$ | Subsidizing rent/bills in leaky, supply-constrained rentals inflates rents and resistive-heat waste while child health hazards persist. |
| **4. Grassroots Civic, Arts & Sport Infrastructure (`Document 1E`)** | Public seed grants (`Vote Arts`, `Vote Sport`, council civic funds) | Volunteer networks, club infrastructure, mentoring leverage ($\varepsilon_{\text{civic}}$) | Adolescent pro-social engagement & non-cognitive skill protection | Tiny fiscal budget share (<0.5%) makes cuts (`coalition_2024_shocks`) look harmless in static ledgers while destroying high-multiplier preventative capacity. |
| **5. 6-Gate Fiscal Architecture (`Table14`)** | Aggregate social spending across all 6 fiscal gates | Developmental timing & Cunha–Heckman plasticity window ($\frac{\partial \theta_{j+1}}{\partial i_j}$) | Net addition to adult effective human capital $H_r$ | Static budgets treat $1 of early-childhood investment and $1 of late-stage acute remediation (Care, Health, Justice) as equivalent fiscal outlays. |

### 4.1 Housing Subsidies and Residential Thermal Efficiency

In New Zealand, low-income and present-biased ($\beta\text{-}\delta$, liquidity-constrained $a \ge 0$) households disproportionately rent poorly insulated dwellings equipped with resistive electric heaters ($\varepsilon_{\text{housing}}$ low) rather than insulated envelopes with heat pumps ($\varepsilon_{\text{housing}}$ $3\times\text{--}4\times$ higher).

* Household biological health and child retention in the *Thriving* Markov state depend on **delivered indoor thermal comfort** $u_{\text{heat}} = \varepsilon_{\text{housing}} e_{\text{heat}}$ exceeding a Stone–Geary subsistence threshold $\bar{u}_{\text{heat}}$, not on nominal kilowatt-hours purchased.
* Cash rent subsidies (such as New Zealand's Accommodation Supplement in supply-inelastic urban markets) or temporary winter energy payments alter nominal budget flows without lifting $\varepsilon_{\text{housing}}$. By contrast, capital standards and envelope/heat-pump retrofits directly raise $\varepsilon_{\text{housing}}$, lowering the shadow price of domestic thermal comfort $p_U = p_E / \varepsilon_{\text{housing}}$ permanently and reducing childhood respiratory and housing-instability transitions into *Stunted*, *Care/Housing*, and *Health/Addiction*.

### 4.2 The Civic & Arts Cost-Share Fallacy (`Document 1E` & `coalition_2024_shocks`)

Keen’s critique of the 5% energy cost share applies with equal force to grassroots community, arts, and youth sport ecosystems analyzed in **Document 1E** and modeled in the `coalition_2024_shocks` branch:

* In central and local government budgets (e.g., `Vote Arts`, Creative NZ, Sport NZ, and Wellington City Council civic grants), public seed funding represents a tiny fraction of total expenditure.
* A conventional fiscal audit assumes removing $10M–$50M of civic grants yields clean fiscal savings with negligible macroeconomic cost.
* Structurally, those modest public grants maintain physical venues, coordinator roles, and institutional scaffolding (such as community hubs, youth clubs, and music spaces) that mobilize unpaid volunteer hours and peer networks—an institutional conversion multiplier $\varepsilon_{\text{civic}} \gg 1$. Defunding the seed conduit collapses the volunteer conversion structure, pushing at-risk adolescents across developmental thresholds into high-cost downstream fiscal gates (`Table 19E` additionality).

### 4.3 Flow-Network Accounting: Headcount Sankeys vs. Value-Potential Sankeys

In `IGWelfare`’s visual and actuarial reporting (`Plot_ChildFates_SSankey.m`, `Plot_ChildFiscal_SSankey.m`, and `Table14`), distinguishing conserved headcount flows from productive potential clarifies why timing governs fiscal solvency:

* **Population Headcount Conservation:** Across lifecycle stages $j \in \{1, \dots, J\}$, cohort population mass $\sum_{z=1}^5 \mu_{j,z} = 1$ is conserved (modulo mortality). Every child appears somewhere on the right-hand side of the Sankey diagram.
* **Productive & Fiscal Potential:** Effective human capital $h(j, z, \theta)$ and net lifecycle fiscal contribution (`net_fisc_30`, `DebtSink_50_CR`) are **not** conserved. Because Cunha–Heckman skill formation exhibits declining plasticity with age and strong dynamic complementarity, downward transitions out of *Thriving* during early windows permanently forfeit compounding skill gains. Late-stage outlays in acute gates (*Care*, *Health/Addiction*, *Justice*) operate as **remedial maintenance expenditure**—necessary to prevent deeper social harm, yet structurally unable to restore early-life developmental trajectories at comparable cost.

---

## 5. Implementation Architecture: Keeping the Bellman Solver Lean

A core engineering principle of `IGWelfare` and its `VFIToolkit-matlab` (`UFHorz`) solver layer is **non-invasive parsimony**: never add continuous state variables to the 4D/5D household Bellman array when structural factor decomposition can be resolved cleanly in the **profile pre-processing layer**, **aggregate regional production equilibrium**, or **post-hoc actuarial ledger**.

1. **Zero-State-Bloat Teacher Wage & Intensity Split (Profile & Ledger Layer):**
   * Decompose `G_ece_s` inside `regions.csv` and `Apply_Policy_Regime.m` by specifying baseline regional educator wage indices (`w_teach_rel`, anchored to `nu_col_index`), retention elasticity, and real instructional input intensity (`fte_intensity_mult`).
   * Pass **only** the converted real instructional intensity into the Cunha–Heckman / `daruich_mult` skill operator during VFI/distribution iteration, while recording both the wage bill ($W_{\text{teach},k} \cdot \mathrm{FTE}_k$) and non-wage outlays in the fiscal/actuarial ledger tables.
2. **Macro Regional Exergy Block (GE Equilibrium Layer Only):**
   * Evaluate $U_r = \varepsilon_r E_r$ inside the regional firm's first-order conditions in `NZ_4Region_Master.m` when solving for equilibrium $(w_r, r)$ under energy-price or `ndc` decarbonization counterfactuals. From the household VFI solver's perspective, this requires **zero extra grid dimensions**—households simply face the resulting general-equilibrium factor prices $(w_r, r)$ and, where modeled, a scalar regional Stone–Geary subsistence floor $\bar{c}_{\text{heat}, r}(p_E, \varepsilon_{\text{housing}, r})$ in the period budget constraint.

---

## 6. Proof & Specification Routing Ledger

To preserve separation of concerns across the `IGWelfare` documentation suite, formal mathematical derivations and calibration schemas derived from this framework are routed as follows:

### 6.1 Routing to **Document 2A** (Theoretical & Analytical Foundations)

* **`[2A-Prop-Factor1]` Breakdown of Cost-Share Sufficiency under $\sigma_{KU} \ll 1$:** Formal derivation showing why small nominal expenditure shares ($s_U = p_U U / Y \ll 1$) coexist with large output and wage elasticities $\frac{d \ln Y_r}{d \ln U_r}$ in nested regional OLG general equilibrium (building on Keen, Ayres & Standish).
* **`[2A-Prop-Factor2]` Observational Equivalence Failure in Public Skill Outlays:** Proof that two fiscal regimes with identical per-child real-GDP-deflated expenditure $G_{\text{ece\_s}}$ generate strictly divergent steady-state human-capital variance $\mathrm{Var}(\ln h)$ and intergenerational persistence $T_{\text{IGE}}$ when regional cost-of-living premia (`nu_col_index`) or turnover thresholds create wedges between nominal spend and converted instructional intensity $I_{\text{edu}}$.
* **`[2A-Prop-Factor3]` In-Kind Conversion Upgrades vs. Cash Transfers under $\beta\text{-}\delta$ Borrowing Constraints:** Proof that when households face $a_{j+1} \ge 0$ and present bias $\beta < 1$, raising durable residential conversion efficiency ($\Delta \varepsilon_{\text{housing}} > 0$) strictly dominates fiscally equivalent unconditional utility/rent transfers in lowering child downward Markov transition hazards.

### 6.2 Routing to **Document 2B** (Quantitative Calibration & Computational Architecture)

* **`[2B-Spec-Edu1]` Non-Invasive `G_ece_s` Wage vs. Intensity Schema:** Column definitions for `profiles/*/regions.csv`, regime-switching logic in `src/config/Apply_Policy_Regime.m`, and sub-column actuarial reporting for NZ (`NZ_4Region_Master`, `NZ_Dunedin1972`) and Finland (`FI_FBC1987`).
* **`[2B-Spec-Exergy1]` NZ 4-Region Useful Exergy & Housing Efficiency Calibration:** Empirical mapping of EECA end-use energy/useful-work balances and BRANZ housing thermal-envelope parameters onto `Rural`, `Small`, `Large`, and `Auckland`, aligned with `ndc` branch shock scenarios.
* **`[2B-Spec-Sankey1]` Actuarial Potential vs. Headcount Accounting in `Table14`:** Exact accounting definitions separating conserved cohort headcount flows from net fiscal/human-capital loss wedges in `Plot_ChildFiscal_SSankey.m` and `Plot_ChildFates_SSankey.m`.