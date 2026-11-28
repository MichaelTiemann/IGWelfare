# Document 2A: Intergenerational Welfare Technical Specification — Part A: Micro-Foundations, Core Agent Problems, & Sectoral Operators
*A GPU-Accelerated Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial Overlapping Generations Framework (Sections 1–4: The Theoretical Lanes)*

**Author:** Michael Tiemann ([mdtiemann@gmail.com](mailto:mdtiemann@gmail.com))  
**Date:** November 2026 | **Code & Replication Repository:** [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)  
*Companion to [Document 1A](Document%201A.md) (Strategic Monograph), [Document 1B](Document%201B.md) (Strategy & Policy Answer Key), [Document 1C](Document%201C.md) (Executive Brief), [Document 2B](Document%202B.md) (Part B: Coupled General-Equilibrium Synthesis, Calibration, Transition Dynamics, & Supermodular Attribution, Sections 5–10), [Document 2T](Document%202T.md) ("Thick" vs. "Thin" Numbers Tutorial), and [Document 3](Document%203.md) (Leaving Our Silos, Lifting All Boats)*

*Disclaimer:* No people nor organizations mentioned herein have endorsed this work unless stated otherwise. This is the work of the author, and all errors and omissions are his alone.

---

## 1. Model Overview, Spatial Taxonomy, & Flexible Period Resolution ($\Delta t \in \lbrace 5, 3, 2, 1 \rbrace$)

### 1.1 Mixed-Horizon 8-PType GPU Architecture
We formulate a quantitative general-equilibrium Spatial Overlapping Generations (OLG) model of Aotearoa New Zealand implemented on the GPU via the VFI Toolkit mixed finite/infinite-horizon permanent-type engines (`ValueFnIter_MixHorz_PType` and `StationaryDist_MixHorz_PType`). The domestic economy is partitioned into $N_{\mathrm{reg}} = 4$ geographic tiers indexed by $k \in \lbrace 1, 2, 3, 4 \rbrace \equiv \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$, augmented by a 5th endogenous outside option $k = 5 \equiv \mathrm{Abroad}$ (representing skilled youth emigration to Australia and the wider OECD):
1. **`HH_Rural` & `Firm_Rural` (16.0% Base Household Share, 15.0% Firm Share):** Agricultural, primary-sector, and remote districts characterized by responsive land supply ($`Q_{\mathrm{Rural},\mathrm{SS0}} = 1.05`$) and elevated mandatory fuel/transport subsistence costs, where baseline wholesale monopsony and retail duopoly markups [Ref 49] are overcome in SS1/SS2 via 1.60x–2.16x regional procurement multipliers [Ref 56] and $z_l \to z_h$ job upgrading ($`\bar{e}_{\mathrm{Rural}} = 0.048`$).
2. **`HH_Small` & `Firm_Small` (24.0% Base Household Share, 23.0% Firm Share):** Secondary provincial towns (population under 100,000) with moderate housing user costs ($Q_{\mathrm{Small},\mathrm{SS0}} = 1.40$) and compressed wage ceilings (upgraded in SS1/SS2 as local food-hub and enterprise value chains shift jobs from $z_l$ to $z_h$ and retire 85% of the SS1 geographic transfer top-up [Ref 49, 56]).
3. **`HH_Large` & `Firm_Large` (25.9% Base Household Share, 26.9% Firm Share):** Major regional metropolitan centers (population over 100,000: Wellington, Christchurch, Hamilton, Tauranga, and Dunedin) featuring tertiary university hubs, constrained urban land ($Q_{\mathrm{Large},\mathrm{SS0}} = 2.05$), and high outward youth turnover.
4. **`HH_Auckland` & `Firm_Auckland` (34.1% Base Household Share, 35.1% Firm Share):** The primate metropolitan agglomeration featuring the highest entrepreneurial productivity ceiling ($`z_{h,\mathrm{Akl}} = 1.75`$), the steepest land supply inelasticity ($`Q_{\mathrm{Auckland},\mathrm{SS0}} = 3.10`$), and severe young-renter crowd-out.

```text
+-----------------------------------------------------------------------------------+
|               8-PTYPE MIXED-HORIZON GPU ARCHITECTURE (Names_i)                    |
|                                                                                   |
|  FINITE-HORIZON HOUSEHOLDS (Ages 20-99, J = round(80/dt), Case 1 MixHorz)         |
|   * HH_Rural (16.0%)  |  HH_Small (24.0%)  |  HH_Large (25.9%)  |  HH_Auckland    |
|   * 4D Compact Grid: (a, h, z, j) + 5th Outside Option: Emigration Abroad (k = 5) |
|         |                                                       ^                 |
|         v (Supplies Effective Labor H_k, Rent/Owner Demand, & Estates)            |
|  INFINITE-HORIZON ENTREPRENEURIAL FIRMS (Guvenen et al. 2023, InfHorz)            |
|   * Firm_Rural (15.0%) | Firm_Small (23.0%) | Firm_Large (26.9%) | Firm_Auckland  |
|   * 2D Grid: (a_f, z_f) with Collateral Constraint k <= lambda_col * a_f          |
+-----------------------------------------------------------------------------------+
```

### 1.2 Exact $\Delta t$-Scaling Laws (`Configure_TimeGrid_Params.m`)
Let $\Delta t \in \lbrace 5, 3, 2, 1 \rbrace$ denote the model period length in years (with $\Delta t = 3$ as the high-resolution developmental default and $\Delta t = 5$ as the fast benchmark). `Configure_TimeGrid_Params(Params, dt)` maps all annual flow rates, stocks, and lifecycle age indices so steady-state and transition magnitudes remain invariant across $\Delta t$:
* **Lifecycle Horizon & Age Brackets:** Adult biological ages span 20 to 99 (80 years), yielding $J = \mathrm{round}\left(80 / \Delta t\right)$ model periods (`J = 16` at $\Delta t = 5$; `J = 27` at $\Delta t = 3$). Retirement begins at age 65: $J_r = \mathrm{round}\left(45 / \Delta t\right) + 1$ (`Jr = 10` at $\Delta t = 5$; `Jr = 16` at $\Delta t = 3$).
* **Childhood Developmental Sub-Stages ($`\mathcal{J}_{c,1}`$ and $`\mathcal{J}_{c,2}`$):** Children are born when parents are age 26 ($`j_{\mathrm{birth}} = \mathrm{round}\left(6 / \Delta t\right) + 1`$).
  * **Stage 1 (First 2000 Days, Child Ages 0–5):** Spans $`n_{s1} = \mathrm{round}\left(6 / \Delta t\right)`$ parental periods $`\mathcal{J}_{c,1} = \lbrace j_{s1,\mathrm{start}}, \dots, j_{s1,\mathrm{end}} \rbrace`$ ($`j_p = 3`$ at $\Delta t = 5$; $`j_p \in \lbrace 3, 4 \rbrace`$ at $\Delta t = 3$).
  * **Stage 2 (Primary/Secondary Schooling & Adolescent Gate, Child Ages 6–17):** Spans $`n_{s2} = \mathrm{round}\left(12 / \Delta t\right)`$ parental periods $`\mathcal{J}_{c,2} = \lbrace j_{s2,\mathrm{start}}, \dots, j_{s2,\mathrm{end}} \rbrace`$ ($`j_p \in \lbrace 4, 5 \rbrace`$ at $\Delta t = 5$; $`j_p \in \lbrace 5, 6, 7, 8 \rbrace`$ at $\Delta t = 3$).
* **Compound Discounting & Flow Scaling ($\mathrm{dt\_scale} = \Delta t / 5$):**

$$
\beta_{hh}\left(\Delta t\right) = \beta_{\mathrm{ann}}^{\Delta t}, \qquad r\left(\Delta t\right) = \left(1 + r_{\mathrm{ann}}\right)^{\Delta t} - 1, \qquad s_j\left(\Delta t\right) = \left(s_{j,\mathrm{5yr}}\right)^{\Delta t / 5}
$$

$$
G_{\mathrm{ECE}}\left(\Delta t\right) = \left(\frac{\Delta t}{5}\right) G_{\mathrm{ECE,5yr}}, \qquad T_k\left(\Delta t\right) = \left(\frac{\Delta t}{5}\right) T_{k,\mathrm{5yr}}, \qquad \bar{e}_k\left(\Delta t\right) = \left(\frac{\Delta t}{5}\right) \bar{e}_{k,\mathrm{5yr}}
$$

while stock endowments (`YouthGrant` *E*) and proportional tax rates ($`\tau_l, \tau_c, \tau_k, \tau_b`$) are invariant to $\Delta t$, and the book-value wealth tax compounds as $`\left(1 - \tau_a\right)^{\Delta t}`$.

---

## 2. Infinite-Horizon Entrepreneurial Firms, Biophysical Exergy, & the 5-Sector Small Open Economy (Aspect 3 & Outer GE Closure)

Following Guvenen, Kambourov, Kuruscu, Ocampo, and Chen (2023), each region *k* contains a unit measure of infinite-horizon entrepreneurial firms (`Firm_Rural`, `Firm_Small`, `Firm_Large`, `Firm_Auckland`) with state vector $`\left(a_f, z_f\right) \in \mathcal{A}_f \times \mathcal{Z}_{f,k}`$, where $`a_f`$ is firm book equity and $`z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace`$ is idiosyncratic entrepreneurial productivity evolving via Markov matrix $`\Pi_{f,k}`$.

### 2.1 Collateral-Constrained Profit Maximization & "Use-It-Or-Lose-It" Return
Firms rent capital $`k_f \le \lambda_{\mathrm{col}} a_f`$ (with collateral multiplier $`\lambda_{\mathrm{col}} = 2.50`$) and hire regional effective labor $`\ell_f`$ at wage *w_k* to produce output $`y_f = z_f \left(k_f^{\alpha_k} \ell_f^{1 - \alpha_k}\right)^{1 - \nu_{\mathrm{span}}}`$. Integrating out static factor demands yields the gross-of-equity-tax rate of return on firm equity $`R_k\left(z_f; \Delta t\right)`$ (`ReturnFn_Firm.m`):

$$
R_k\left(z_f; \Delta t\right) = \left(1 - \tau_a\right)^{\Delta t} + \left(1 - \tau_k\right) \left\lbrack r\left(\Delta t\right) + \max\left\lbrace 0,  \pi_k^{*}\left(z_f, w_k\right) - \left(r\left(\Delta t\right) + \delta_k\left(\Delta t\right)\right) \right\rbrace \lambda_{\mathrm{col}} \right\rbrack
$$

$$
\pi_k^{*}\left(z_f, w_k\right) = \alpha_k \left(\frac{1 - \alpha_k}{w_k}\right)^{\frac{1 - \alpha_k}{\alpha_k}} z_f^{\frac{1}{\alpha_k}}
$$

### 2.2 Firm Bellman Equation & Stationary Equity Distribution ($\Gamma_k$)
Each firm solves the infinite-horizon Bellman equation:

$$
V_{F,k}\left(a_f, z_f\right) = \max_{a_f^{\prime} \in \left\lbrack 0,  R_k\left(z_f; \Delta t\right) a_f \right\rbrack} \left\lbrace \ln\left(R_k\left(z_f; \Delta t\right) a_f - a_f^{\prime} + \varepsilon_c\right) + \beta_{\mathrm{firm}}\left(\Delta t\right) \sum_{z_f^{\prime}} \Pi_{f,k}\left(z_f^{\prime} \middle| z_f\right) V_{F,k}\left(a_f^{\prime}, z_f^{\prime}\right) \right\rbrace
$$

Replacing distortionary capital income taxation ($`\tau_k`$) with a book-value wealth/land tax ($`\tau_a = 0.015`$) penalizes low-productivity land-banking firms ($`z_{\ell,k}`$) while leaving high-productivity firms ($`z_{h,k}`$) with a higher marginal saving propensity, shifting the stationary equity distribution $`\Gamma_k\left(a_f, z_f\right)`$ toward $`z_{h,k}`$ and raising endogenous regional total factor productivity (reinforced in Rural and Small regions by breaking farm-gate wholesale monopsony and retail duopoly markups [Ref 49] and anchoring 1.60x–2.16x local food-hub procurement multipliers [Ref 56] that shift household labor draws from $z_l$ toward $z_h$, $\Delta \mu_{z,\mathrm{SS2}} = [+0.0408, +0.0307, +0.0170, +0.0102]$) $`Z_k\left(\Gamma_k\right)`$.

### 2.3 Five-Sector Small-Open-Economy Macroeconomic Closure

`IGWelfare` solves the 60-year multiphase transition path (`SS0 -> SS1 -> SS2`) across four domestic regions (`Rural`, `Small`, `Large`, `Auckland`) plus an endogenous emigration outside option (`Abroad`) within a unified **5-Sector Biophysical-Exergy & Care-Inclusive Small Open Economy** (`NZ_4Region_Master.m`, `TransPath_4Region_Master.m`, and `Compute_5Sector_Exergy_Equilibrium.m`). Closing the heterogeneous-agent spatial OLG core inside the 5-sector open-economy equilibrium resolves four structural macroeconomic requirements without adding a single endogenous household state variable:

1. **The Small Open Economy (SOE) & Tradable Composition Constraint:** Domestic human-capital, housing, and enterprise reforms only overcome the Long-Term Fiscal Model (`LTFM`) sinkhole [Ref 31, 32] when coupled across the human lifecycle ([Document 3](Document%203.md)). Closing the external accounts answers how a land- and emissions-constrained exporter funds an initial capability incubation window—or sustains a **+150% expansion in national defence spending** (from ~1.2% to 3.0% of GDP, `+NZD 8.0B/yr` [Ref 59])—without triggering a current-account blowout, real exchange rate crowding-out, or widening sovereign risk spreads [Ref 4, 10, 40].
2. **The Biophysical Energy Illusion:** New Zealand routinely conflates an ~85.5%–88.5% renewable *electricity* grid with clean energy independence, ignoring that roughly 60%–68% of total consumer and primary energy consists of fossil fuels—predominantly imported liquid petroleum products (`~NZD 19.5B/yr`) alongside depleting Taranaki gas and thermal coal firming [Ref 39, 46]. Industrial curtailments during 2024–2026 wholesale power spikes demonstrate that energy is not a minor, smoothly substitutable 4% cost share [Ref 9]; it is a physical capacity constraint governed by domestic hydro-firming bottlenecks and vertically integrated gentailer market power [Ref 39, 49].
3. **The Monolithic Non-Tradable & Public-Provision Fallacy:** Treating early childhood wraparound (`G_ece_stage1`), adolescent mentoring (`G_ece_stage2`), hospitals, water networks, roading, grassroots NGOs, and sovereign defence purely as fiscal budget lines—or lumping them inside generic private non-tradables—hides real general-equilibrium resource competition. Scaling human-capital services requires hiring real teachers, nurses, and *Whānau Ora* navigators in regional labor markets (~26%–27% of New Zealand's paid workforce sits in public and for-purpose delivery [Ref 30, 42]), while scaling sovereign defence drains foreign exchange on imported platforms and competes directly for technical engineering talent [Ref 59].
4. **The National-Accounts Care & Volunteer Blind Spot:** Leaving non-market household caregiving and community volunteering bundled inside an undifferentiated "leisure" residual creates a Marilyn Waring accounting distortion [Ref 30, 47]. Shifting early childhood or elder care between *kuia*/community networks and state/market provision alters measured System of National Accounts (`SNA`) GDP even when real care inputs are unchanged, while obscuring how incompressible regional energy and housing bills squeeze unpaid caregiving time [Ref 11, 23, 28, 46, 47].

Consistent with the dimension-free conditioning principles in [Document 2T](Document%202T.md), small-open-economy sectoral trade (adapting Australia's *OLGA* [Ref 57]), biophysical exergy transition (*Keen, Ayres, & Standish* [Ref 9]; *Labrousse & Perdereau* [Ref 23]), polycentric public/NGO and defence production (*Ostrom* [Ref 29]; *Baumol* & *Atkinson* [Ref 58]), and unpaid care (*Waring* [Ref 47]; *Gronau* [Ref 28]) enter as **two orthogonal, non-compounding blocks**: an outer 5-sector general-equilibrium production and external-balance block paired with an intratemporal household time-and-subsistence block (`1.0x` state-space memory multiplier).

### 2.4 Biophysical Exergy Activation & Spatial Dual-Fuel Heterogeneity (Keen, Ayres, & Labrousse–Perdereau)

Standard CGE and OLG climate models append energy via a nested Capital-Labor-Energy (`KLE`) function governed by Solow's cost-share theorem, assigning energy an output elasticity near $`\gamma \approx 0.04`$ that implies a 10% physical energy shortfall reduces output by a trivial ~0.4% to 0.7% [Ref 9]. Following Robert Ayres and Steve Keen (Keen, Ayres, & Standish, 2019; Ayres & Warr, 2009 [Ref 9]), physical capital and labor cannot perform work without energy throughput converted into useful physical work (**exergy**). Once regional plant, machinery, and public facilities are installed, short-run substitutability between capital-labor bundles and useful exergy approaches zero ($`\sigma_{KL,X} \to 0`$; Hassler, Krusell, & Olovsson, 2021 [Ref 10]):

* **Imported Fossil Fuels ($`F`$):** Internal combustion vehicles and industrial/institutional fossil boilers suffer severe Second-Law conversion losses ($`e_F \in \lbrack 0.25, 0.35 \rbrack`$, calibrated baseline `e_F = 0.30`), bleeding foreign exchange out of the current account and compounding Paris Agreement `NDC` liabilities to deliver low useful mechanical or thermal work [Ref 9, 40, 46].
* **Domestic Renewable Electricity ($`N`$):** Electric drive motors, EVs, and industrial/residential heat pumps achieve $`e_N \ge 0.85`$ (calibrated baseline `e_N = 0.88`, yielding $`e_N / e_F = 2.93\times`$ useful work per unit of primary energy) [Ref 9, 46]. Electrification is therefore a **nearly three-fold step-change in end-use exergy efficiency**—provided domestic renewable generation and dry-year firming capacity ($`K_N`$) expand ahead of machine demand and are not throttled by wholesale gentailer oligopoly markups ($`M_{\mathrm{olig}}`$) [Ref 39, 49].

Embedding Labrousse and Perdereau's (2026 [Ref 23]) spatial dual-fuel framework—where **geography dominates income** in determining fossil-fuel exposure—into the 4-region spine (`Rural`, `Small`, `Large`, `Auckland`) closes both regional production and external fuel accounts:

1. **Spatial Non-Homotheticity & Dual-Fuel Exergy Bundles:** Each region *k* carries an incompressible subsistence exergy requirement $`\bar{e}(k)`$ in household utility alongside region-specific CES weights $`\gamma_h(k)`$ and $`\gamma_{s,k}`$ governing the split between domestic electricity ($`N`$) and imported fossil fuel ($`F`$, subject to ETS/carbon pricing $`\tau_F`$) [Ref 23, 39, 50]. Useful exergy $`X_{s,k}`$ in sector *s* and region *k* aggregates electric and fossil throughput as:

$$
X_{s,k} = \left\lbrack \left(1 - \gamma_{s,k}\right)\left(e_N N_{s,k}\right)^{\frac{\epsilon_y - 1}{\epsilon_y}} + \gamma_{s,k}\left(e_F F_{s,k}\right)^{\frac{\epsilon_y - 1}{\epsilon_y}} \right\rbrack^{\frac{\epsilon_y}{\epsilon_y - 1}}
$$

2. **Macro External Closure (Fossil + Defence Imports):** Aggregate imported fossil fuel demand $`F_t = \sum_{k=1}^{4} \left(F_{h,k,t} + \sum_{s} F_{s,k,t}\right) + F_{N,t} + F_{D,t}`$—where $`F_{N,t}`$ captures Huntly dry-year coal/gas peaking [Ref 39] and $`F_{D,t}`$ captures military aviation/marine fuel—must be purchased from the Rest of the World at world price $`p_F^{\ast}`$ (plus shadow `NDC` carbon liability when domestic abatement falls short [Ref 40]), alongside imported defence procurement $`M_{D,t}^{\ast}`$ [Ref 59] and Net Foreign Asset ($`\mathrm{NFA}_t`$) service [Ref 10, 23].

#### 2.4.1 Proposition `[2A-Prop-Factor1]`: Putty-Clay Exergy Bottlenecks, Dual-Fuel Electrification Leverage, and Small-Open-Economy Sovereign Spread Closure

Consider sector $`s`$ in region $`k \in \lbrace 1, 2, 3, 4 \rbrace`$ where gross output $`Y_{s,k}`$ combines the composite capital-labor bundle $`V_{s,k} = K_{s,k}^{\alpha_k} H_{s,k}^{1 - \alpha_k}`$ with useful physical work (**exergy**) $`X_{s,k}`$ via a putty-clay CES operator with short-run elasticity $`\sigma_{KL,X} \in (0, 1)`$ [Ref 9, 10]:

$$
Y_{s,k} = Z_{s,k} \left\lbrack \left(1 - \omega_{X,s}\right) V_{s,k}^{\frac{\sigma_{KL,X} - 1}{\sigma_{KL,X}}} + \omega_{X,s} X_{s,k}^{\frac{\sigma_{KL,X} - 1}{\sigma_{KL,X}}} \right\rbrack^{\frac{\sigma_{KL,X}}{\sigma_{KL,X} - 1}}
$$

where useful exergy $`X_{s,k}`$ aggregates domestic renewable electricity $`N_{s,k}`$ (priced at $`p_N = M_{\mathrm{olig}} c_N`$ with Second-Law conversion efficiency $`e_N`$) and imported fossil fuel $`F_{s,k}`$ (priced at world price $`p_F^{\ast} + \tau_F`$ including shadow Paris `NDC` carbon liability $`\tau_F`$, with conversion efficiency $`e_F < e_N`$) under end-use substitution elasticity $`\epsilon_y > 1`$ [Ref 9, 23, 39, 40]:

$$
X_{s,k} = \left\lbrack \left(1 - \gamma_{s,k}\right)\left(e_N N_{s,k}\right)^{\frac{\epsilon_y - 1}{\epsilon_y}} + \gamma_{s,k}\left(e_F F_{s,k}\right)^{\frac{\epsilon_y - 1}{\epsilon_y}} \right\rbrack^{\frac{\epsilon_y}{\epsilon_y - 1}}
$$

Let $`s_{E,s,k} = \left(p_N N_{s,k} + (p_F^{\ast} + \tau_F) F_{s,k}\right) / Y_{s,k}`$ denote the observed nominal energy expenditure share, and let international borrowing clear via $`r_t = r_t^{\ast} + \psi \left(\exp\left(\mathrm{NFA}_t / Y_t - \bar{b}\right) - 1\right)`$ with $`\psi < 0`$ for net debtor positions ($`\mathrm{NFA}_t < \bar{b} Y_t`$) [Ref 10]. Then:

1. **Failure of the KLE Cost-Share Approximation Under Physical Curtailment ($`\sigma_{KL,X} \to 0`$):** Under rationed firming capacity or acute fuel disruption ($`\Delta \ln X_{s,k} < 0`$) holding $`V_{s,k}`$ fixed in the short run, a finite fractional curtailment $`x = X_{s,k}^{\prime} / X_{s,k} \in (0, 1)`$ induces an exact nonlinear output loss:

$$
\frac{Y_{s,k}^{\prime}}{Y_{s,k}} = \left\lbrack \left(1 - \eta_{X,s,k}\right) + \eta_{X,s,k} \, x^{\frac{\sigma_{KL,X} - 1}{\sigma_{KL,X}}} \right\rbrack^{\frac{\sigma_{KL,X}}{\sigma_{KL,X} - 1}}
$$

   In the putty-clay Leontief limit $`\sigma_{KL,X} \to 0^{+} \implies \frac{\sigma_{KL,X} - 1}{\sigma_{KL,X}} \to -\infty`$, $`Y_{s,k}^{\prime} / Y_{s,k} \to x`$ regardless of how small the baseline nominal expenditure share $`s_{E,s,k} \approx 0.04`$ is—whereas a Cobb-Douglas `KLE` model ($`\sigma_{KL,X} = 1`$) understates output contraction by $`1 - x^{s_{E,s,k}} \ll 1 - x`$.
2. **Asymmetric Regional Wage Compression Under Price-Only Carbon Taxation ($`\Delta \tau_F > 0, \Delta K_N = 0`$):** Let $`P_{X,s,k}`$ denote the dual unit cost of useful exergy. Raising carbon/fuel charges $`\Delta \tau_F > 0`$ or wholesale gentailer markups $`\Delta M_{\mathrm{olig}} > 0`$ without expanding firmed renewable capacity $`K_N`$ raises $`P_{X,s,k}`$ in proportion to fossil exergy cost share $`\theta_{F,s,k}`$, depressing regional labor demand and equilibrium real wages $`w_k`$ most severely in high-fossil-exposure regions (`Rural`, `Small`, where $`\gamma_{s,k}`$ and household subsistence $`\bar{e}(k)`$ are largest):

$$
\frac{\partial \ln w_k}{\partial \ln P_{X,s,k}}\bigg\vert_{K_{s,k}, H_{s,k}} = -\frac{\eta_{X,s,k}}{1 - \eta_{X,s,k}} \left(1 - \sigma_{KL,X}\right) < 0 \qquad \left(\mathrm{for}\ \sigma_{KL,X} < 1\right)
$$

3. **Triple Small-Open-Economy Dividend of Firmed Electrification ($`F_{s,k} \to N_{s,k}`$):** Shifting primary energy throughput at the margin from imported fossil fuel to firmed competitive domestic electricity ($`M_{\mathrm{olig}} \to 1`$) multiplies physical useful work per primary energy unit by the Second-Law factor $`e_N / e_F \approx 2.93`$ while simultaneously improving the external balance and sovereign interest rate via three additive channels:

$$
\Delta \mathrm{BoP}_t = -p_F^{\ast} \Delta F_t - \tau_F^{\mathrm{offshore}} \Delta E_{\mathrm{NDC},t} > 0 \implies \Delta \mathrm{NFA}_t > 0 \implies \Delta r_t < 0
$$

   lowering domestic capital rental rates $`r_t + \delta_k`$ across all four regions and lifting collateral-constrained firm equity returns $`R_k(z_{h,k})`$ without contracting gross energy services.

---

##### Proof of `[2A-Prop-Factor1]`

**Part 1 (Nonlinear Putty-Clay Contraction Limit).**
Factor baseline $`Y_{s,k}`$ out of the CES production operator at $`X_{s,k}^{\prime} = x X_{s,k}`$ and $`V_{s,k}^{\prime} = V_{s,k}`$, using $`\eta_{X,s,k} = Z_{s,k}^{\frac{\sigma_{KL,X}-1}{\sigma_{KL,X}}} \omega_{X,s} (X_{s,k} / Y_{s,k})^{\frac{\sigma_{KL,X}-1}{\sigma_{KL,X}}}`$ and $`1 - \eta_{X,s,k} = Z_{s,k}^{\frac{\sigma_{KL,X}-1}{\sigma_{KL,X}}} (1 - \omega_{X,s}) (V_{s,k} / Y_{s,k})^{\frac{\sigma_{KL,X}-1}{\sigma_{KL,X}}}`$. Setting $`\rho = \frac{\sigma_{KL,X} - 1}{\sigma_{KL,X}} < 0`$ for $`\sigma_{KL,X} \in (0, 1)`$ yields $`Y_{s,k}^{\prime} / Y_{s,k} = \left\lbrack (1 - \eta_{X,s,k}) + \eta_{X,s,k} x^{\rho} \right\rbrack^{1/\rho}`$. For any $`x \in (0, 1)`$ and $`\eta_{X,s,k} > 0`$, as $`\sigma_{KL,X} \to 0^{+}`$ ($`\rho \to -\infty`$), the dominant term inside brackets is $`\eta_{X,s,k} x^{\rho}`$, so:

$$
\lim_{\rho \to -\infty} \frac{1}{\rho} \ln\left\lbrack \left(1 - \eta_{X,s,k}\right) + \eta_{X,s,k} x^{\rho} \right\rbrack = \lim_{\rho \to -\infty} \left( \ln x + \frac{\ln \eta_{X,s,k}}{\rho} \right) = \ln x \implies \lim_{\sigma_{KL,X} \to 0^{+}} \frac{Y_{s,k}^{\prime}}{Y_{s,k}} = x
$$

By contrast, under Cobb-Douglas `KLE` ($`\sigma_{KL,X} = 1`$), $`Y_{s,k}^{\prime} / Y_{s,k} = x^{s_{E,s,k}}`$; at $`s_{E,s,k} = 0.04`$ and $`x = 0.90`$, Cobb-Douglas predicts a `0.42%` loss versus the physical `10.0%` putty-clay bound.

**Part 2 (Dual Exergy Price Index & Regional Real Wage Incidence).**
Minimizing primary expenditure $`p_N N_{s,k} + (p_F^{\ast} + \tau_F) F_{s,k}`$ subject to $`X_{s,k} = 1`$ yields the exact unit cost of useful exergy:

$$
P_{X,s,k} = \left\lbrack \left(1 - \gamma_{s,k}\right)^{\epsilon_y} \left(\frac{M_{\mathrm{olig}} c_N}{e_N}\right)^{1 - \epsilon_y} + \gamma_{s,k}^{\epsilon_y} \left(\frac{p_F^{\ast} + \tau_F}{e_F}\right)^{1 - \epsilon_y} \right\rbrack^{\frac{1}{1 - \epsilon_y}}
$$

By Shephard's Lemma, $`d \ln P_{X,s,k} = (1 - \theta_{F,s,k}) d \ln(M_{\mathrm{olig}} c_N / e_N) + \theta_{F,s,k} d \ln((p_F^{\ast} + \tau_F) / e_F)`$, which increases strictly with regional fossil weight $`\gamma_{s,k}`$. Under competitive regional labor demand $`w_k = \partial Y_{s,k} / \partial H_{s,k}`$ with unconstrained exergy choice $`\partial Y_{s,k} / \partial X_{s,k} = P_{X,s,k}`$, implicit differentiation of the CES marginal product schedule with fixed short-run $`(K_{s,k}, H_{s,k})`$ gives $`d \ln X_{s,k} = -\frac{\sigma_{KL,X}}{1 - \eta_{X,s,k}} d \ln P_{X,s,k}`$ and $`\partial \ln Y_{s,k} / \partial \ln X_{s,k} = \eta_{X,s,k}`$. Since $`w_k \propto Y_{s,k}^{1/\sigma_{KL,X}} V_{s,k}^{1 - 1/\sigma_{KL,X}}`$, holding $`(K_{s,k}, H_{s,k})`$ fixed yields:

$$
d \ln w_k = \frac{1}{\sigma_{KL,X}} d \ln Y_{s,k} - d \ln P_Y = \frac{1 - \sigma_{KL,X}}{\sigma_{KL,X}} \eta_{X,s,k} \, d \ln X_{s,k} = -\frac{\eta_{X,s,k}}{1 - \eta_{X,s,k}} \left(1 - \sigma_{KL,X}\right) d \ln P_{X,s,k} < 0
$$

for all $`\sigma_{KL,X} \in (0, 1)`$, while household disposable cash-on-hand (`Section 3.2`) simultaneously contracts via $`-\Delta \bar{e}_k`$.

**Part 3 (Second-Law Work Multiplier & Sovereign Spread Compression).**
Replacing one unit of primary fossil fuel ($`\Delta F = -1`$) with primary renewable electricity delivering identical useful work ($`\Delta X = 0`$) requires only $`\Delta N = e_F / e_N \approx 0.30 / 0.88 = 0.341`$ units of electrical energy ($`2.93\times`$ primary energy compression). In the small-open-economy current account (`Section 2.4–2.5`), eliminating imported fuel $`\Delta F_t < 0`$ and offshore `NDC` mitigation purchases $`\Delta E_{\mathrm{NDC},t} < 0`$ directly raises $`\Delta \mathrm{NFA}_t = \mathrm{Exports}_t - p_F^{\ast} F_t - \tau_F^{\mathrm{offshore}} E_{\mathrm{NDC},t} - M_{D,t}^{\ast} + r_t \mathrm{NFA}_{t-1}`$. Differentiating the debt-elastic interest schedule with respect to $`\mathrm{NFA}_t / Y_t`$ (where sovereign external debt is $`-\mathrm{NFA}_t > 0`$) confirms $`\partial r_t / \partial (\mathrm{NFA}_t / Y_t) < 0`$, lowering $`r_t`$ and raising $`R_k(z_{h,k})`$ in `ReturnFn_Firm.m` (`Section 2.1`). $`\blacksquare`$

---

### 2.5 Structural Transformation in a 5-Sector Small Open Economy & Anti-Double-Counting Civic/Defence Ledger

Outer-loop production (`Compute_5Sector_Exergy_Equilibrium.m`, parameterized via `profiles/<Profile_ID>/sectors/sectors_2026.csv` and `exergy_and_ndc.yaml`) partitions into **five explicit structural sectors**:

1. **Sector 1 — Land-Bound Primary Tradables:** Dairy, meat, horticulture, and forestry exports subject to fixed agricultural land, diminishing marginal returns, farm-gate value-chain upgrading [Ref 49, 56], and agricultural/`NDC` emissions pricing wedges [Ref 40].
2. **Sector 2 — Weightless / Knowledge Tradables:** High-skill intensive ($`z_h`$), unbound by land, exhibiting substantially higher value-added per joule of exergy and endogenous Arrow (1962) learning-by-doing spillovers [Ref 2, 7, 10].
3. **Sector 3 — Private Market Non-Tradables & Grid Generation:** Private residential housing, civil construction contractors, commercial freight, retail distribution, for-profit care/corporate providers, and domestic electricity generation ($`K_N`$), where private oligopoly markups reside [Ref 39, 49] and whose relative price $`p_t^N`$ pins down the **Real Exchange Rate (`RER`)**.
4. **Sector 4 — Public, NGO & Polycentric Civic Services (`Sector 4A` Human Co-Production + `Sector 4B` Public Network Infrastructure):** Non-market state, local-council, *Iwi/Whānau Ora*, and registered non-profit institutions delivering health, education, community social services, justice, Three Waters, and public transport/roading stewardship [Ref 29, 30, 36, 58].
5. **Sector 5 — Sovereign Defence & External Security (`Sector D`):** The New Zealand Defence Force (`NZDF`), Ministry of Defence capability procurement, and external security apparatus [Ref 59], isolated to stress-test a **+150% defence posture expansion** (1.2% to 3.0% of GDP, `+NZD 8.0B/yr`).

Closing the international capital account with a Schmitt-Grohé and Uribe (2003 [Ref 10]) debt-elastic sovereign risk premium links domestic social, fiscal, defence, and exergy choices directly to international borrowing costs:

$$
r_t = r_t^{\ast} + \psi \left(\exp\left(\frac{\mathrm{NFA}_t}{Y_t} - \bar{b}\right) - 1\right)
$$

#### Anti-Double-Counting Boundary Rules (`CBAx` Counting Rule #1 [Ref 33])

The boundary between `Sector 3` (`Private Market Non-Tradables`) and `Sector 4` (`Public, NGO & Polycentric Civic Services`) is governed strictly by **who owns the asset, sets the price, and governs access**—not who pours the concrete:

* **Rule 1 — Pure Cash Transfers (`0%` in Sectors 4 & 5):** New Zealand Superannuation (`~NZD 26.5B/yr`), working-age income-support transfers (`~NZD 27.0B/yr`), and Crown debt interest (`~NZD 10.2B/yr`) are pure redistributive or financial transfers (`~NZD 63.7B/yr` total) already tracked in household disposable income `y_disp` and sovereign debt service. Only MSD and IRD administrative staff enter `Sector 4`.
* **Rule 2 — Ownership vs. Private Civil Contracting in Water & Roading:** Public network assets—all 67 territorial/unitary councils' Three Waters utilities (`Watercare`, `Wellington Water`, *Local Water Done Well* CCOs) and the state/local road, rail, and public-transport network (`NZTA Waka Kotahi`, council roading, `KiwiRail`, `AT`, `Metlink`)—sit **100% in `Sector 4B`** for asset ownership ($`K_{G,k}`$), network engineering, and civic tariff-setting [Ref 36]. When a water utility or `NZTA` hires private civil contractors (`Fulton Hogan`, `Downer`, `HEB`) to lay pipes or reseal highways, `Sector 4B` purchases gross fixed capital formation ($`I_{G,k}`$) from **`Sector 3` (`Private Construction`)**, while commercial freight (`Mainfreight`) remains in `Sector 3`.
* **Rule 3 — Netting Crown-to-NGO Contracts & Separating Corporate Chains in Health & Education:** Public hospitals (`Te Whatu Ora`), CAMHS, *Iwi/Whānau Ora* providers, charity health trusts (`St John`, `Plunket`, `Barnardos`), state/integrated schools, *Kura Kaupapa Māori*, public tertiary institutions, and community ECE (*Kindergartens, Playcentre, Kōhanga Reo, A'oga Amata*) sit in **`Sector 4A`** (~85%–88% of Health and ~92%–95% of Education) [Ref 30, 37]. For-profit corporate ECE chains, commercial private surgical hospitals, and listed retirement-village operators (`Ryman`, `Summerset`) remain in **`Sector 3`** because they maximize private equity returns $`R_k`$ [Ref 2]. The ~40% of non-profit revenue derived from Crown service contracts is **netted out upon consolidation** so Vote Health/Education dollars and NGO delivery are counted once [Ref 30].

#### Table 2.1: Empirical Composition of New Zealand's Sector 4 (Civic/Polycentric) & Sector 5 (Defence) Ledger (2025/2026)

Consolidating Central and Local Government non-transfer operations with New Zealand's 119,400 for-purpose organisations (*JBWere & University of Waikato, September 2026*; *Public Service Commission, June 2026* [Ref 30, 42, 59]), `Sectors 4` and `5` account for **~26%–27% of New Zealand's paid workforce (~650,000–670,000 paid jobs out of 2.36 million filled jobs)** plus **79,000 FTE-equivalents of unpaid volunteer labor**, and **~NZD 125B–133B/yr in consolidated non-transfer operating and capital throughput**:

| Sector & Sub-Lane | Institutional Components (Net of Cash Transfers & Private Civil Double-Counting) | Consolidated Annual Spend / Revenue (2025/26 NZD) | Paid Workforce (Approx. Headcount / FTEs) | Unpaid Volunteer Co-Production [Ref 30, 47] | Structural Function in `IGWelfare` (`Capacitating` vs. `Reactive` vs. `Physical` vs. `Security`) |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **4A-1. Public & Community Health + Social Care** | *Te Whatu Ora* hospitals, Primary/Iwi PHOs, ACC rehab management, *Whānau Ora*, *St John*, aged/disability NGOs (*excl. listed villages*) | **~NZD 38B – 41B/yr** *(Vote Health NZD 34.2B + ACC care + net NGO revenue)* | **~245,000 – 260,000** *(~100k Te Whatu Ora + ~150k PHO/NGO/care staff)* | **High** (*Whānau* elder/disability care + ambulance/hospice volunteers) | **Bifurcated:** Preventative maternal/primary health (`Capacitating`) vs. Acute wards & CAMHS (`Exit 2 Reactive` [Ref 16, 38]) |
| **4A-2. Public & Community Education** | State & integrated schools, *Kura*, public universities/wānanga, *Kindergartens, Playcentre, Kōhanga Reo, Barnardos* (*excl. corporate ECE*) | **~NZD 24B – 26B/yr** *(Vote Education NZD 22.4B + tertiary/trust revenue)* | **~195,000 – 210,000** *(~115k schools, ~40k tertiary, ~40k+ community ECE)* | **Very High** (*Playcentre, Kōhanga*, school boards, *Tuakana* peer mentoring) | **Core Capacitating Engine:** Produces real Stage-1 & Stage-2 Cunha–Heckman skill inputs (`G_ece` [Ref 11, 18, 37]) |
| **4A-3. Grassroots NGOs, Iwi/Marae, Culture, Sport & Civic Trusts** | Registered charities, *iwi/hapū* entities, arts/music hubs, youth/sport trusts (*net of health/ed contracts in 4A-1 & 4A-2*) [Ref 30] | **~NZD 18B – 22B/yr** *(Philanthropy, iwi distributions, fees, donations)* | **~80,000 – 95,000** *(Remainder of NZ's 231,000 paid for-purpose staff)* | **Massive: ~79,000 FTEs** *(930k volunteers giving 165M hrs/yr = NZD 6.7B imputed)* | **Ostrom Polycentric Multiplier:** Drives social cohesion `S_t`, trust-gated mentoring `M_trust`, & preventative youth engagement [Ref 29, 30] |
| **4A-4. Justice, Police, Corrections & Oranga Tamariki** | NZ Police, Courts, Department of Corrections, *Oranga Tamariki* child protection [Ref 30, 37] | **~NZD 8.5B – 9.5B/yr** *(Justice-cluster Votes ex-transfers)* | **~34,000 – 37,000** *(~15k Police, ~10.5k Corrections, ~5k OT, ~4.5k Courts)* | **Moderate** (*Iwi* restorative justice panels, community patrols) | **Predominantly Reactive ("Anti-Bads"):** `Exits 1 & 4` defensive outlays—compresses by >75% in `SS1 -> SS2` [Ref 16, 37, 58] |
| **4A-5. Core Public Administration & Stewardship** | MSD, IRD, MBIE, MfE, Treasury, DOC, regulatory Crown entities (*net of Justice/OT*) [Ref 30] | **~NZD 8.0B – 9.5B/yr** *(Departmental operating ex-transfers)* | **~45,000 – 50,000** *(Core Public Service is 63,912 FTEs total at June 2026)* | **Moderate** (DOC conservation & catchment volunteers) | **Institutional & Tax/Transfer Overhead:** Revenue collection, social-investment actuarial auditing [Ref 32, 35] |
| **4B-1. Roading, Rail & Public Transport Networks** | `NZTA Waka Kotahi` (`NLTP`), council local roads, `KiwiRail` network, `AT` / `Metlink` (*civil works contracted to Sec 3*) | **~NZD 11B – 12.5B/yr** *(2024–27 NLTP = NZD 32.9B / 3 yrs + rail/PT ops)* | **~14,000 – 18,000** *(Direct agency/council/PT engineering & ops staff)* | **Low** | **Physical Network Capital ($`K_{G,\mathrm{trans}}`$):** Cuts regional transport subsistence $`\bar{e}(k)`$ & lifts firm TFP (`1.65x`) [Ref 36, 46] |
| **4B-2. Local Councils & Three Waters Infrastructure** | Drinking, wastewater & stormwater utilities (*Watercare, Wellington Water, CCOs*) + non-road council facilities [Ref 36] | **~NZD 10B – 12B/yr** *(Council non-road spend; Three Waters = ~NZD 4.5B–5.5B/yr)* | **~45,000 – 50,000** *(55,100 local govt staff less road/PT; ~8k–10k Waters)* | **Moderate** (Watershed groups, Civil Defence volunteers) | **Preventative Civic Capital ($`K_{G,\mathrm{water}}`$):** Prevents Moa-Point-style reactive failure cascades [Ref 36] |
| **5. Sovereign Defence & External Security (`Sector D`)** | NZDF (Navy, Army, Air Force), Ministry of Defence capability rebuild, intelligence/MFAT security [Ref 59] | **~NZD 5.5B – 6.5B/yr** *(~1.2% GDP baseline -> **NZD 13.5B–14.5B/yr** at **3.0% GDP**)* | **~15,000 – 16,500** *(~9k Regular + ~3k civilian + Reserves -> **~30k+** at 3% GDP)* | **Reservists** | **External Security & FX/Skill Sink:** High foreign import share $`\theta_{M,\mathrm{def}} \in \lbrack 0.55, 0.70 \rbrack`$ + `h_4`–`h_7` technical labor demand [Ref 59] |

#### Four Structural Mechanisms Governed by the `Sector 4` & `Sector 5` Ledger

1. **The Headcount-vs.-Capex Dichotomy Inside `Sector 4` (`4A` Human Care vs. `4B` Pipes & Roads):** Health, Education, and Grassroots NGOs (`Rows 4A-1 to 4A-3`) employ **~80%+ of `Sector 4`'s human workforce (~540,000+ paid workers)**, making them classic Baumol (1967 [Ref 58]) labor-intensive sectors where metropolitan housing affordability (`Q_k`) for nurses and *Kaiako* ([Document 2T](Document%202T.md)) and Ostrom (1996 [Ref 29]) community co-production govern unit delivery costs:

$$
Y_{G,k}^{\mathrm{dev}} = A_{\mathrm{poly}}(S_t) \left\lbrack \omega_G \left(H_{G,k}^{\mathrm{dev}}\right)^{\rho_g} + \left(1 - \omega_G\right) \left(L_{u,\mathrm{civic},k} + K_{\mathrm{whanau},k}\right)^{\rho_g} \right\rbrack^{\frac{1}{\rho_g}}
$$

   Conversely, Roading and Three Waters (`Rows 4B-1 & 4B-2`) employ relatively few direct public staff (~25,000 in network engineering/operations) yet steward **hundreds of billions of dollars in physical public capital ($`K_{G,k}`$)**—purchasing civil construction from `Sector 3` and suffering severe nonlinear failure penalties when short-term budgets raid preventative maintenance (*Moa Point Review*, September 2026 [Ref 36]).
2. **The Ageing Volunteer Base Proof (Why Universal NZ Super at Age 64/65 Anchors `Sector 4A`):** The September 2026 *JBWere / University of Waikato For-Purpose Sector Report* [Ref 30] establishes that New Zealand's non-profit sector contributes **NZD 25.8B/yr (5.7% of GDP—larger than agriculture, forestry, and fishing at 5.1%)** once **165 million annual volunteer hours (79,000 FTEs)** are counted, *yet volunteer headcount fell 24%, concentrating volunteer workload onto a shrinking, ageing cohort*. Raising the NZ Superannuation eligibility age to 70 therefore liquidates both grandmother childcare (`K_whanau`) and the unpaid volunteer co-production base $`L_{u,\mathrm{civic},k}`$ of `Sector 4A`, forcing the Crown to replace lost community capacity with 3x to 5x more expensive state remediation [Ref 26, 29, 30, 58].
3. **Internal Labor Release Within `Sector 4A` (`+65k` Reactive FTEs Freed Into Capacitating Care Without Wage Inflation):** `Sector 4A` produces both **Capacitating Investment ($`Y_{G,k}^{\mathrm{dev}}`$)** and **Reactive Remediation ($`Y_{G,k}^{\mathrm{rem}}`$, Gate 6 Exits 1, 2, and 4)** from the same domestic pool of clinical, educational, and social professionals. Compressing struggling youth launches from **22.0% to 1.5%** in `SS1 -> SS2` cuts demand for reactive hospital nights, state care, and corrections by over 75% [Ref 16, 37]—**internally releasing ~65,000 skilled `Sector 4A` FTEs** into preventative early learning, primary health, and `Sector 2` enterprises without overheating domestic wages.
4. **Why a +150% Defence Expansion (`Sector 5`: 1.2% -> 3.0% of GDP) Requires Both Exergy Transition and Human-Capital Scaling:** Because defence procurement carries a foreign import share $`\theta_{M,\mathrm{def}} \in \lbrack 0.55, 0.70 \rbrack`$ (`~NZD 4.5B–5.6B/yr` in direct new FX outflows) plus military fuel $`F_{D,t}`$ and technical `h_4`–`h_7` labor demand, an unfunded `+NZD 8.0B/yr` defence uplift sinks `SS0` welfare to **-21.69% CE**, whereas slashing `~NZD 19.5B/yr` of civilian fossil imports via Keen–Labrousse electrification (`-> ~NZD 5.5B/yr`) and expanding thriving youth launches (`23.5% -> 65.0%`) sustains the full `3.0% GDP` posture at **+21.18% CE** ([Document 3](Document%203.md), `Table A.3`).

#### 2.5.1 Proposition `[2A-Prop-Civic1]`: Polycentric Volunteer Co-Production Gearing, SNA Input-Cost Blindness, and Asymmetric Disinvestment Sinkholes

In `Sector 4A` (`Section 2.5`), regional capacitating civic output $`Y_{G,k}^{\mathrm{dev}}`$ combines paid public/NGO staff $`H_{G,k}^{\mathrm{dev}}`$ (funded by statutory seed/operating outlay $`B_{\mathrm{seed},k} = w_k H_{G,k}^{\mathrm{dev}}`$, with GDP budget share $`s_{\mathrm{seed},k} = B_{\mathrm{seed},k} / Y_k^{\mathrm{SNA}} \ll 0.01`$) with unpaid community volunteer and extended *whānau* co-production $`U_{\mathrm{civic},k} \equiv L_{u,\mathrm{civic},k} + K_{\mathrm{whanau},k}^{\mathrm{eff}}`$ under Ostrom–Waring complementarity $`\rho_g < 0`$ ($`\sigma_g = \frac{1}{1 - \rho_g} \in (0, 1)`$) [Ref 29, 30, 47]:

$$
Y_{G,k}^{\mathrm{dev}} = A_{\mathrm{poly}}(S_t) \left\lbrack \omega_G \left(H_{G,k}^{\mathrm{dev}}\right)^{\rho_g} + \left(1 - \omega_G\right) U_{\mathrm{civic},k}^{\rho_g} \right\rbrack^{\frac{1}{\rho_g}}
$$

Suppose volunteer and *whānau* mobilization responds endogenously to physical/institutional civic venues ($`H_{G,k}^{\mathrm{dev}}`$, e.g., community halls, arts/sport coordinators, *Joiner Passport* seed grants) and statutory pension time availability $`\Phi_{\mathrm{time}}(A_{\mathrm{super}})`$ (`Section 3.3`) via $`U_{\mathrm{civic},k} = \Phi_{\mathrm{time}}(A_{\mathrm{super}}) \, \mathcal{M}(H_{G,k}^{\mathrm{dev}})`$, with crowding-in elasticity $`\zeta_{\mathrm{crowd}} = \frac{\partial \ln \mathcal{M}}{\partial \ln H_{G,k}^{\mathrm{dev}}} > 0`$. Let downstream reactive state remediation $`Y_{G,k}^{\mathrm{rem}}`$ (`Exits 1, 2, & 4`, booked at paid input cost $`B_{\mathrm{rem},k} = w_k H_{G,k}^{\mathrm{rem}}`$) satisfy $`\frac{\partial Y_{G,k}^{\mathrm{rem}}}{\partial Y_{G,k}^{\mathrm{dev}}} = -\chi_{\mathrm{prev}} < 0`$ [Ref 16, 58]. Then:

1. **Super-Unitary Polycentric Seed Gearing (`24x+` Leverage on Tiny `s_B`):** Define the paid-to-co-produced output shares $`\theta_{H,k} \in (0, 1)`$ and $`1 - \theta_{H,k}`$ inside $`Y_{G,k}^{\mathrm{dev}}`$. A marginal statutory seed expansion $`d \ln B_{\mathrm{seed},k} > 0`$ (at fixed $`w_k`$) expands real capacitating output with amplified elasticity:

$$
\frac{d \ln Y_{G,k}^{\mathrm{dev}}}{d \ln B_{\mathrm{seed},k}} = \theta_{H,k} + \left(1 - \theta_{H,k}\right) \zeta_{\mathrm{crowd}} > \theta_{H,k}
$$

   Even though `Tier 1` conventional `SNA` accounting (`Document 2B, Section 5.6`) books zero market value for $`U_{\mathrm{civic},k}`$ (`79,000 FTEs`) and scores $`B_{\mathrm{seed},k}`$ solely at paid input cost $`s_{\mathrm{seed},k}`$, the realized `Tier 3` welfare leverage ratio scales inversely with $`s_{\mathrm{seed},k}`$:

$$
\Lambda_{\mathrm{civic},k} = \frac{d Y_k^{\mathrm{eff}} / d B_{\mathrm{seed},k}}{1} = \frac{\eta_{\mathrm{dev},k}}{s_{\mathrm{seed},k}} \left\lbrack \theta_{H,k} + \left(1 - \theta_{H,k}\right) \zeta_{\mathrm{crowd}} \right\rbrack \gg 1
$$

2. **Asymmetric Retrenchment & Elder-Austerity Sinkhole (`Vote Arts` / `C15` Cuts & `A_super -> 70`):** Because $`\rho_g < 0`$ ($`\sigma_g < 1`$), paid venue coordination $`H_{G,k}^{\mathrm{dev}}`$ and unpaid volunteer/*kuia* time $`U_{\mathrm{civic},k}`$ are strict complements ($`\frac{\partial^2 Y_{G,k}^{\mathrm{dev}}}{\partial H_{G,k}^{\mathrm{dev}} \partial U_{\mathrm{civic},k}} > 0`$). Consequently:
   * **Venue Liquidation Cliff:** Cutting nominal seed grants ($`H_{G,k}^{\mathrm{dev}} \to 0`$) strands unpaid community capacity: for $`\rho_g < 0`$, $`\lim_{H_{G,k}^{\mathrm{dev}} \to 0^{+}} Y_{G,k}^{\mathrm{dev}} = 0`$ regardless of latent volunteer willingness, triggering a nonlinear jump in downstream reactive remediation outlays $`\Delta B_{\mathrm{rem},k} = w_k \chi_{\mathrm{prev}} \vert \Delta Y_{G,k}^{\mathrm{dev}} \vert \gg \vert \Delta B_{\mathrm{seed},k} \vert`$.
   * **Pension-Age Volunteer Liquidation (`A_super > 65`):** Raising the pension age ($`\partial \Phi_{\mathrm{time}} / \partial A_{\mathrm{super}} = -\eta_{\mathrm{elder}} \Phi_{\mathrm{time}} < 0`$) contracts $`U_{\mathrm{civic},k}`$ directly, lowering the marginal product of paid `Sector 4A` staff and forcing the Crown to substitute paid reactive labor $`H_{G,k}^{\mathrm{rem}}`$ at multiple times the fiscal savings.
3. **Perverse `Tier 1` `SNA` GDP Sign Inversion vs. Internal `Sector 4A` Labor Release:** When preventative expansion $`\Delta Y_{G,k}^{\mathrm{dev}} > 0`$ eliminates reactive remediation demand by $`\Delta H_{G,k}^{\mathrm{rem}} = -\chi_{\mathrm{prev}} \Delta Y_{G,k}^{\mathrm{dev}} / \varepsilon_{\mathrm{rem}}`$, holding paid public headcount fixed releases $`\vert \Delta H_{G,k}^{\mathrm{rem}} \vert - \Delta H_{G,k}^{\mathrm{dev}} > 0`$ skilled domestic workers (`~65,000 FTEs`) into capacitating care and `Sector 2` tradables without wage inflation—whereas input-cost public `SNA` accounting mechanically records the vanished prison and acute-ward payroll ($`-w_k \vert \Delta H_{G,k}^{\mathrm{rem}} \vert`$) as a contraction in government output unless audited via `Tier 2` Atkinson–Waring (`Y_AW`) or `Tier 3` `CE%`.

---

##### Proof of `[2A-Prop-Civic1]`

**Part 1 (Volunteer Crowding-In Amplification).**
Logarithmically differentiating the CES operator $`Y_{G,k}^{\mathrm{dev}}`$ at fixed $`S_t`$ and $`A_{\mathrm{super}}`$, with paid input share $`\theta_{H,k} = \omega_G \left(A_{\mathrm{poly}}(S_t) H_{G,k}^{\mathrm{dev}} / Y_{G,k}^{\mathrm{dev}}\right)^{\rho_g}`$ and volunteer share $`1 - \theta_{H,k} = (1 - \omega_G)\left(A_{\mathrm{poly}}(S_t) U_{\mathrm{civic},k} / Y_{G,k}^{\mathrm{dev}}\right)^{\rho_g}`$, gives:

$$
d \ln Y_{G,k}^{\mathrm{dev}} = \theta_{H,k} \, d \ln H_{G,k}^{\mathrm{dev}} + \left(1 - \theta_{H,k}\right) d \ln U_{\mathrm{civic},k} = \left\lbrack \theta_{H,k} + \left(1 - \theta_{H,k}\right) \zeta_{\mathrm{crowd}} \right\rbrack d \ln B_{\mathrm{seed},k}
$$

Applying `[2B-Prop-Wedge1]` with converted factor $`X_{\mathrm{civic},k} = Y_{G,k}^{\mathrm{dev}}`$ and effective conversion multiplier $`\varepsilon_{\mathrm{civic},k} = Y_{G,k}^{\mathrm{dev}} / H_{G,k}^{\mathrm{dev}}`$ yields $`1 + \frac{d \ln \varepsilon_{\mathrm{civic},k}}{d \ln B_{\mathrm{seed},k}} = \theta_{H,k} + (1 - \theta_{H,k})\zeta_{\mathrm{crowd}}`$, and dividing by the small input-cost budget weight $`s_{\mathrm{seed},k}`$ (`0.140%` `CE` on `MirrorInv2E` vs. `76.0–79.0 kFTE` volunteer labor) produces $`\Lambda_{\mathrm{civic},k} \gg 1`$ (`24.29x` in `NZ_Dunedin1972`; `24.04x` in `FI_FBC1987`).

**Part 2 (Essentiality Under `rho_g < 0` and Fiscal Remediation Backfire).**
Because $`\rho_g < 0`$, as $`H_{G,k}^{\mathrm{dev}} \to 0^{+}`$ we have $`(H_{G,k}^{\mathrm{dev}})^{\rho_g} \to +\infty`$, so $`\left\lbrack \omega_G (H_{G,k}^{\mathrm{dev}})^{\rho_g} + (1 - \omega_G) U_{\mathrm{civic},k}^{\rho_g} \right\rbrack^{1/\rho_g} \le \omega_G^{1/\rho_g} H_{G,k}^{\mathrm{dev}} \to 0`$. Cross-differentiation yields:

$$
\frac{\partial^2 Y_{G,k}^{\mathrm{dev}}}{\partial H_{G,k}^{\mathrm{dev}} \partial U_{\mathrm{civic},k}} = \left(1 - \rho_g\right) \frac{\theta_{H,k}\left(1 - \theta_{H,k}\right) Y_{G,k}^{\mathrm{dev}}}{H_{G,k}^{\mathrm{dev}} U_{\mathrm{civic},k}} > 0
$$

Hence cutting either $`B_{\mathrm{seed},k}`$ (`C15`) or elder time $`\Phi_{\mathrm{time}}(A_{\mathrm{super}})`$ (`A_super -> 70`) degrades the marginal productivity of the remaining input and induces net Crown cash deterioration whenever $`w_k \chi_{\mathrm{prev}} \frac{\partial Y_{G,k}^{\mathrm{dev}}}{\partial B_{\mathrm{seed},k}} > 1`$, even though 4-year `OBEGALx` (`Lens 1`) books only the immediate savings $`-\Delta B_{\mathrm{seed},k} > 0`$ before cohort transition lags mature.

**Part 3 (`SNA` Input-Cost Distortion vs. `Y_AW` Accounting).**
Under `Tier 1` input-cost `SNA` rules (`Document 2B, Section 5.6`), `Sector 4A` value added is $`V_{4A,k}^{\mathrm{SNA}} = w_k (H_{G,k}^{\mathrm{dev}} + H_{G,k}^{\mathrm{rem}})`$. Whenever upstream prevention satisfies $`\vert \Delta H_{G,k}^{\mathrm{rem}} \vert > \Delta H_{G,k}^{\mathrm{dev}}`$, $`\Delta V_{4A,k}^{\mathrm{SNA}} < 0`$ at fixed sector boundaries despite strictly releasing $`\Delta L_{\mathrm{free},k} = \vert \Delta H_{G,k}^{\mathrm{rem}} \vert - \Delta H_{G,k}^{\mathrm{dev}} > 0`$ workers to productive sectors and strictly raising `Tier 2` Atkinson–Waring output $`\Delta Y_{k}^{\mathrm{AW}} = p_{\mathrm{shadow}} \Delta Y_{G,k}^{\mathrm{dev}} - w_k \Delta H_{G,k}^{\mathrm{rem}} > 0`$ [Ref 47, 58]. $`\blacksquare`$

---

## 3. Finite-Horizon Household Problem Across Aspects 1, 2, and 3

### 3.1 State Vector, Decision Grids, & Return Function Signature

In the GPU experience-asset specification (`NZ_4Region_Master.m` and `ReturnFn_SpatialHH.m`, alongside the compact 4D solver `ReturnFn_SpatialHH_Compact4D.m`), a household in region $k$ at age bracket $j \in \{1, \dots, J\}$ has endogenous state vector $a = (a_1, h, \theta_c)$, exogenous productivity state $z$, and chooses decision vector $d = (\ell, I_h, i_c)$:

* **`d_grid` (`n_d = [4, 3, 7]`, 84 composite decision states):**
  * $\ell \in \{0, 0.5, 0.8, 1.0\}$ ($n_{d_1} = 4$, extensive and intensive margin market labor supply).
  * $I_h \in \text{linspace}(0, 0.30, 3)^{\top}$ ($n_{d_2} = 3$, adult Ben-Porath on-the-job training time).
  * $i_c \in [0, 0.50]$ ($n_{d_3} = 7$, private early/school child skill investment, placed last in `n_d` as the experience-asset control). To prevent working families in the residual after-housing-costs (AHC) squeeze (**Node 2**) from being artificially rounded down to the $i_c = 0$ corner—which occurs under linear spacing where the first positive rung sits at $`0.0833 \approx 7,917\text{ NZD/yr}`$—`d_grid_ic` uses a convex power grid:
    $$d_{\text{grid,ic}} = 0.50 \times (\text{linspace}(0, 1, 7))^{1.8} = [0, 0.0203, 0.0706, 0.1460, 0.2456, 0.3649, 0.5000]^{\top}$$
    providing accessible interior rungs at $i_{c,2} = 0.0203$ ($`\approx 1,929\text{ NZD/yr}`$) and $i_{c,3} = 0.0706$ ($`\approx 6,707\text{ NZD/yr}`$) while matching the 7-tier resolution of $h$ and $z$.
* **`a_grid` (`n_a = [61, 7, 9]`):**
  * $a_1 \in [0, 25]$ ($n_{a_1} = 61$, household liquid net worth spaced cubically via $25 \times (\text{linspace}(0, 1, 61))^3$, concentrating 17 grid nodes below $a = 0.48 \approx \text{NZD } 45\text{k}$ to resolve regional housing thresholds $Q_k$ via continuous sub-grid linear cell interpolation).
  * $h \in \{0.45, 0.65, 0.85, 1.00, 1.20, 1.45, 1.80\}$ ($n_{a_2} = 7$, canonical adult human capital tiers $h_1 \dots h_7$: $h_1\text{–}h_2$ Struggling, $h_3\text{–}h_5$ Core, $h_6\text{–}h_7$ Thriving).
  * $\theta_c \in \text{linspace}(0.45, 1.85, 9)^{\top}$ ($n_{a_3} = 9$, continuous-interpolation child skill experience asset governed by `HumanCapital_Lifecycle_aprimeFn.m`, placed last in `n_a`).
* **`z_grid` (`n_z = 7`):** $z \in Z_{hh}$ ($n_z = 7$, 7-point Rouwenhorst idiosyncratic earnings shock (Kopecky & Suen, 2010) with $\rho_z = 0.85$ and region-specific drift $\mu_k$ and volatility $\sigma_k \in [0.11, 0.24]$, where $i_z \in \{1, 2\}$ denotes unemployment or severe low-wage distress).

### 3.2 Budget Constraint, Stone-Geary Subsistence, & Housing Tenure Cutoff
Effective labor supply during working life ($`j < J_r`$) is $`\ell_{\mathrm{eff}} = \max\left(0,  \ell - I_h\right)`$, generating gross labor income $`y_{\mathrm{lab}} = w_k z h \ell_{\mathrm{eff}}`$. In retirement ($`j \ge J_r`$), households receive universal New Zealand Superannuation $`p_{\mathrm{super}}`$ plus means-tested consumption floor support $\underline{c}$. Total disposable cash-on-hand available for composite expenditure $`e_{\mathrm{tot}}`$ is:

$$
y_{\mathrm{disp}} = \left(1 - \tau_a\right)^{\Delta t} a + \left(1 - \tau_k\right) r\left(\Delta t\right) a + \left(1 - \tau_l\right) y_{\mathrm{lab}} + \mathbb{I}_{\left\lbrace j \ge J_r\right\rbrace} p_{\mathrm{super}} + \mathbb{I}_{\left\lbrace j = 1\right\rbrace} E + T_k\left(a, y_{\mathrm{lab}}\right)
$$

$$
e_{\mathrm{tot}} = \frac{y_{\mathrm{disp}} - \bar{e}_k - \mathbb{I}_{\left\lbrace j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}\right\rbrace} \left(1 - s_{\mathrm{sub}}\right) i_c - a^{\prime}}{1 + \tau_c}
$$

Following Kiyotaki, Michaelides, and Nikolov (2024), households with net worth below the regional down-payment threshold ($`a < \xi_k Q_k`$, where $`\xi_k = 0.20`$) are **Renters** facing rental user cost $`r_{h,k}^{\mathrm{rent}} = \left(1 + \mu_{\mathrm{maint}} - G_k / R\right) Q_k`$, while households with $`a \ge \xi_k Q_k`$ are **Homeowners** facing user cost $`r_{h,k}^{\mathrm{own}} = \left(1 + \mu_{\mathrm{maint}} - G_k / R - \psi_{\mathrm{own}}\right) Q_k`$. Optimal non-durable consumption $`c_{nd} = \phi_{nd} e_{\mathrm{tot}}`$ and housing services $`c_H = \left(1 - \phi_{nd}\right) e_{\mathrm{tot}} / r_{h,k}`$ combine in the Cobb-Douglas bundle (while the geographic transfer schedule $T_k$ surges in SS1 to `[0.038, 0.031, 0.025, 0.028]` to bridge acute hardship and then retires by $\psi_{\mathrm{retire},T} = 85\%$ in SS2 to `[0.018, 0.013, 0.008, 0.004]` as regional $z_l \to z_h$ jobs take over, funding an additional $-0.64\text{ pp}$ PAYE cut down to $\tau_l = 18.25\%$ [Ref 49, 56]): $`c_{\mathrm{comp}} = c_{nd}^{\phi_{nd}} c_H^{1 - \phi_{nd}}`$.


#### 3.2.1 Discretization of Early Childhood Investment (`d_grid_ic`)
In the baseline VFI configuration (`NZ_4Region_Master.m`), household liquid assets $a \in [0, 25]$ use cubic spacing (`25 * linspace(0, 1, 61).^3`), providing high resolution across low-wealth states ($a_1 \dots a_{17}$ span $0 \text{ to } 0.4741$, or $0 \text{ to } 45,040$ NZD at the $95,000$ NZD base scale). However, when the early childhood investment decision grid `d_grid_ic` ($n_{ic} = 7$ points on $[0, 0.50]$) is spaced linearly (`linspace(0, 0.50, 7)'`), the first positive investment rung sits at $ic_2 = 0.0833$ ($\approx 7,917\text{ NZD/yr}$ of private out-of-pocket expenditure).

For households in **Node 2 (Residual AHC Squeeze & Paper Support)** whose optimal private cash investment lies between $1,500 \text{ to } 5,000 \text{ NZD/yr}$ ($ic \in [0.015, 0.055]$), a linear decision grid offers no interior point between $0$ and $0.0833$, artificially rounding their policy choice down to the $ic = 0$ corner. Replacing linear spacing with a convex power grid of identical dimension ($n_{ic} = 7$, incurring zero additional GPU memory or Bellman iteration cost):

$$d_{\text{grid,ic}} = 0.50 \times \left(\text{linspace}(0, 1, 7)\right)^{1.8} = [0, 0.0203, 0.0706, 0.1460, 0.2456, 0.3649, 0.5000]^{\top}$$

introduces an accessible first positive rung at $ic_2 = 0.0203$ ($\approx 1,929\text{ NZD/yr}$) and second rung at $ic_3 = 0.0706$ ($\approx 6,707\text{ NZD/yr}$). This allows squeezed working families in Node 2 to register modest positive investments rather than pooling synthetically at $ic = 0$.

#### 3.2.2 Continuous Sub-Grid Cell Interpolation for Regional Housing Thresholds
Because regional housing price multipliers $Q_{\text{reg}}(k)$ span a threefold range (`Rural` $= 1.05$ to `Auckland` $= 3.10$), hard boolean asset cutoffs such as $a < \tau_1 Q_{\text{reg}}$ can fall near a grid node boundary in one region while sitting mid-interval in another. To prevent step-function discretization jumps when housing supply reforms ($Q_{\text{mult}}$) shift $Q_{\text{reg}}$, the 18-node Sankey aggregation evaluates continuous linear cell-fraction weights over the cubic asset grid $a_1 < a_2 < \dots < a_{61}$:

$$w_{\text{cell}}(a_i; \tau Q_{\text{reg}}) = \min\left(1, \max\left(0, \frac{\tau Q_{\text{reg}} - a_{i-1}}{a_i - a_{i-1}}\right)\right)$$

with $a_0 \equiv a_1 - (a_2 - a_1)$. This ensures that marginal changes in regional housing costs ($Q_{\text{reg}}$) and alloparental buffering ($K_{\text{whānau}}$) map smoothly into cohort population shares across all four regions.

---

### 3.3 Adolescent Family Unemployment Stress, Unbanked Skill Fade-Out, and Bidirectional Montessori / Tuakana–Teina Mentoring ($M_{\mathrm{mentor}}$), and the importance of Whānau

In the two-stage Cunha–Heckman–Schennach skill technology (`HumanCapital_Lifecycle_aprimeFn.m`), childhood skill $`\theta_c`$ evolves across Stage 1 (ages 0–5, where $`\varphi_1 = 0.35 > 0`$) and Stage 2 (ages 6–17, where $`\varphi_2 = -0.95 < 0`$):

$$
\theta_{c,\mathrm{ret}} = \theta_c - \delta_{\theta,\mathrm{fade}}(1 - M_{\mathrm{mentor}})\max(0, \theta_c - \theta_{\mathrm{base}})
$$

$$
\Theta_s(\tilde{\theta}_c) = \left[ \gamma_{s,\mathrm{self}}\tilde{\theta}_c^{\varphi_s} + \gamma_{s,\mathrm{inv}}\left(i_c + G_{\mathrm{ECE},s}^{\mathrm{eff}} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_s} + \gamma_{s,\mathrm{par}}\bar{h}_p^{\varphi_s} \right]^{1/\varphi_s}, \quad s \in \lbrace 1, 2 \rbrace
$$

$$
\theta'_c = \begin{cases}
(1 - \omega_{s1})\theta_c + \omega_{s1}\Theta_1(\theta_c) & \text{if } j \in \mathcal{J}_{c,1} \\
(1 - \omega_{s2})\theta_{c,\mathrm{ret}} + \omega_{s2}\Theta_2(\theta_{c,\mathrm{ret}})\exp\left(\Psi_{J=5}(z_p, a_p, M_{\mathrm{mentor}})\right) & \text{if } j \in \mathcal{J}_{c,2} \\
\theta_c & \text{otherwise}
\end{cases}
$$

Because Stage 2 exhibits strong dynamic complementarity ($`\sigma_2 = \frac{1}{1 - \varphi_2} = 0.51 < 1`$) and unbanked gain depreciation $`\delta_{\theta,\mathrm{fade}} > 0`$ (Bailey et al., 2017; Rea & Burton, 2019; Lillard, 2005), early skill gains erode during middle childhood and early adolescence (`J = 5`, child ages 12–14) if children transition into passive factory-model schooling or if Stage-2 socio-emotional stability collapses. We formalize two countervailing mechanisms operating at this gate:

*1. Compounded Family Unemployment & Adolescent Psychosocial Morbidity Shock ($\psi_{\text{unemp}}, \lambda_{\text{psy}}$):* Following the empirical job-displacement and *Family Stress Model* literature (Conger et al., 1992; Coelli, 2011) alongside contemporary Aotearoa longitudinal evidence on early-adolescent peer victimization, algorithmic compulsion, sexual harm, and depressive escalation (*Growing Up in New Zealand* "Now We Are Twelve", Morton et al., 2023/2024; *Youth19*, Fleming et al., 2020; ACC ISSC actuarial valuations), disengagement at the ages 12–14 gate ($J = 5$, **Node 7**) is driven by two interacting channels: (i) household unemployment or severe AHC distress $z_p \in Z_{\text{distress}}$, and (ii) a cross-income psychosocial relational hazard $\lambda_{\text{psy}}(M_{\text{mentor}}, K_{\text{whānau}})$ that erodes executive function across all socioeconomic tiers while compounding multiplicatively when household buffers are depleted. In the adolescent net skill shift $\Psi_{J=5}$, active *Tuakana–Teina* / *Erdkinder* mentoring ($M_{\text{mentor}}$) and extended *whānau* connection ($K_{\text{whānau}}^{\text{eff}}(k)$) operate both to lower primary incidence $\lambda_{\text{psy}}$ (via critical-thinking cognitive inoculation and *KiVa*/*Planet Youth* peer-norm restructuring) and to insulate exposed adolescents against permanent detachment (retaining a conservative 38% clinical persistence residual for acute trauma requiring specialized CAMHS/ACC care):

$$\Psi_{J=5}(z_p, a_p, M_{\text{mentor}}, K_{\text{whānau}}) = -ψ_{\text{unemp}} \left[ I(z_p \in Z_{\text{distress}}) + λ_{\text{psy}}(M_{\text{mentor}}) \right] (1 - \zeta_{\text{buf}} M_{\text{mentor}})(1 - 0.55 K_{\text{whānau}}^{\text{eff}}(k)) + \kappa_{\text{up}} M_{\text{mentor}}$$

**2. Bidirectional Montessori / *Tuakana–Teina* Cross-Age Mentoring ($`M_{\mathrm{mentor}} \in [0, 1]`$):** While Stage 2 cognitive investment productivity is low ($`\gamma_{2,C,3} = 0.044`$), non-cognitive malleability remains more than twice as high ($`\gamma_{2,N,3} = 0.104`$, Cunha et al., 2010). Synthesizing indigenous *Tuakana–Teina* and *Ako* reciprocal whānau in *Kura Kaupapa Māori* and bilingual units, the Graeme Dingle Foundation's *Stars / Te Kāhui Whetū* and *Project K* peer-mentoring programs, CEFS *Food Youth Initiative (FYI)* and *GrowingChange* youth-led agricultural enterprises (92% non-recidivism [Ref 56]), high-agency vertical-*whānau* state schools, and Montessori's multi-age *Erdkinder* pedagogy (Lillard, 2005; Lillard & Else-Quest, 2006; Agostinelli, Saharkhiz, & Wiswall, 2024; Resnjanskij et al., 2024), structured cross-age mentoring where adolescents at `J = 5` mentor younger children at $J = 2\text{--}3$ generates a **two-way intra-generational spillover** without adding an endogenous state variable:
- *Downward Scaffolding Multiplier on Stage 1 ($`\kappa_{\mathrm{down}} > 0`$):* Near-peer tutoring and role-modeling by the *tuakana* adolescent cohort (with mean skill $`\bar{\theta}_{J=5}`$) augment the effective productivity of public early childhood and primary investments (including fresh *Ka Ora, Ka Ako* and NC State CEFS *Farm-to-ECE* nutrition: +24%–33% vegetable intake, $d = 1.20$, +26.6 pp parent nutrition crowding-in, and 46% take-home garden produce [Ref 56]) for younger *teina*:

$$
G_{\mathrm{ECE},1}^{\mathrm{eff}} = G_{\mathrm{ECE},1} \left(1 + \kappa_{\mathrm{down}} M_{\mathrm{mentor}} \bar{\theta}_{J=5}\right)
$$

- *Upward "Protégé Effect", Zero Fade-Out, & Stress Buffer on Stage 2 ($`\kappa_{\mathrm{up}} > 0`$):* Serving as a high-agency *tuakana* mentor builds adolescent executive function, self-regulation, and *mana*, eliminating unbanked Stage-1 skill fade-out ($`(1 - M_{\mathrm{mentor}})\delta_{\theta,\mathrm{fade}} \to 0`$) and directly buffering the family unemployment shock via the adolescent net shift $`\Psi_{J=5}`$:

See definition of $\Psi_{J=5}$ above.

- *Compact 4D Log-Skill Projection & Vectorized Sub-Grid Crowding Operator:* Defining the threshold vector $\tau_{\text{cuts}} = [0.025, 0.050, 0.080, 0.160]$ and the $[n_{a1} \times 4]$ sub-grid weight matrix $W_{\text{cell}}(a_i; \tau_{\text{cuts}} Q_k) = \min(1, \max(0, (Q_k \tau_{\text{cuts}} - a_{i-1}) / \Delta a_i))$, `Build_IntergenTransitionMatrix.m` and `Plot_ChildFates_SSankey.m` evaluate the two-tier Waring-buffered housing crowding vector $`\text{crowd}_{1D}(a_p; k) = W_{\text{cell},3} \psi_{\text{crowd,sev}} + (W_{\text{cell},4} - W_{\text{cell},3})(0.35 \psi_{\text{crowd,ahc}})`$ and induce the anchored log-skill transition mean across the 7-point adult human capital grid $h_{\text{child}} \in H$:

$$\mu_{\ln h}(h_p, i_c, z_p, a_p; k) = \rho_{hc} \ln(h_p^{\text{eff}}) + \gamma_{ic} \ln\left(\frac{i_c^{\text{eff}} + G_{\text{ECE},1}^{\text{eff}} + \bar{g}_{\text{ECE}}}{\bar{i}_c + G_{\text{ECE,base}} + \bar{g}_{\text{ECE}}}\right) - \text{crowd}_{1D}(a_p; k) + \Psi_{J=5}(z_p, i_c, M_{\text{mentor}}, K_{\text{whānau}}) + \alpha_{\text{grid}}$$

**3. The Endogenous Pension–*Whānau* Coupling Operator ($`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{eff}}(k)`$):** To make New Zealand Superannuation parameters ($`A_{\mathrm{super}}, p_{\mathrm{super}}`$) and regional housing user costs (*Q_k*) endogenously legible to the younger parenting generation without expanding the 4D GPU state vector $(a, h, z, j)$, `HumanCapital_Lifecycle_aprimeFn.m`, `ReturnFn_SpatialHH_Compact4D.m`, and `Build_IntergenTransitionMatrix.m` evaluate effective regional *whānau* capacity $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{eff}}(k) = K_{\mathrm{wh\bar{a}nau},0}(k) \cdot \Phi_{\mathrm{super}}(k)`$ from baseline proximity $`K_{\mathrm{wh\bar{a}nau},0} = [0.42, 0.38, 0.32, 0.28]`$ (`[Rural, Small, Large, Auckland]`) and the **Elder Time & Housing Stability Factor** $`\Phi_{\mathrm{super}}(k) \in [0.45, 1.25]`$:

$$
\Phi_{\mathrm{super}}(k) = \underbrace{\Phi_{\mathrm{time}}(A_{\mathrm{super}})}_{\text{Kuia / Aunty time availability}} \times \underbrace{\min\left(1.15, \max\left(0.50, \frac{p_{\mathrm{super}}}{0.18} \cdot \left(\frac{Q_{k,0}}{Q_k}\right)^{0.35}\right)\right)}_{\text{Ability of aunties / kaumātua to stay in their own homes}}
$$

- *Downstream Channels:* Where $`\Phi_{\mathrm{time}}(A_{\mathrm{super}}) = \exp(-\eta_{\mathrm{elder}}(A_{\mathrm{super}} - 65))`$ for $`A_{\mathrm{super}} \ge 65`$ ($`\eta_{\mathrm{elder}} = 0.09\text{ yr}^{-1}`$, yielding a -36.2% loss at Age 70: $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{eff}} \to [0.27, 0.24, 0.20, 0.18]`$) and $`\Phi_{\mathrm{time}}(A_{\mathrm{super}}) = 1 + 0.16 \tanh((65 - A_{\mathrm{super}})/1.80)`$ for $`A_{\mathrm{super}} < 65`$ (+8.1% boost at Age 64). In turn, $`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{eff}}(k)`$ feeds directly into (i) Stage-1 informal *whānau* care and pooled *whānau* human capital $`\bar{h}_p`$, (ii) Stage-2 fade-out retention (`fade_residual`) and adolescent crisis buffering $`\Psi_{J=5}`$ (`psi_unemp_step`), and (iii) domestic youth retention (`whanau_stay_pull`) in $`\Pi_{\mathrm{mig}}`$.

**4. De Nardi (2004) Luxury Warm-Glow Bequest Motive:**

$$
u_{\mathrm{beq}}(a'; \tau_b) = b_1 \frac{\left(1 + \frac{(1 - \tau_b)a'}{b_2}\right)^{1 - \eta_c} - 1}{1 - \eta_c}
$$

**5. Relational Altruism, Social Cohesion Utility ($`u_{\mathrm{rel}}`$), & Transparency International CPI Calibration:** Captures the utility gain experienced by citizens and aging parents when the struggling launch share ($`\mathrm{Frac}_{\mathrm{struggling}}`$) is compressed and domestic social cohesion ($`S_t`$, `S_cohesion`) rises as educated youth remain in New Zealand:

$$
u_{\mathrm{rel}}(\mathrm{Frac}_{\mathrm{struggling}}, S_t) = \chi_{\mathrm{rel}} \left[ (0.285 - \mathrm{Frac}_{\mathrm{struggling}}) + 0.015 (S_t - 100) \right]
$$

- *Macro Social Cohesion Law of Motion:* Along the transition path, the macro **Social Cohesion Index** $S_t$ evolves endogenously as a linear functional of struggling-launch compression, youth brain-drain closure (`Nat_Emig_Abroad_Pct`), and moderated replacement-migration turnover (`Churn_Rate`):

$$
S_t = 100.0 + \zeta_{\mathrm{hardship}} (0.220 - \mathrm{Frac}_{\mathrm{struggling},t}) + \zeta_{\mathrm{ret}} (0.1093 - \mathrm{Emig}_{\mathrm{Nat},t}) - \zeta_{\mathrm{churn}} \max(0, \mathrm{Churn}_t - \overline{\mathrm{Churn}})
$$

- *Empirical CPI Anchor:* Empirically, $`S_t`$ is anchored to New Zealand's sovereign **Transparency International Corruption Perceptions Index (CPI)** ("Social Credit Rating"), which declined from **96/100** (2004 peak) and **88/100** (#1 equal globally in 2021) to a 30-year low of **81/100** (#4 equal in the 2025/2026 release, behind **#1 Denmark at 89, #2 Finland at 88, and #3 Singapore at 84**; Office of the Controller and Auditor-General, *New Zealand's Integrity Inheritance*, 2026; TI-NZ *National Integrity System Gap Analysis*, 2026). Compressing $`\mathrm{Frac}_{\mathrm{struggling}}`$ from 0.220 to 0.015 and cutting $`\mathrm{Emig}_{\mathrm{Nat}}`$ from 10.93% to 7.60% lifts $`S_t`$ from 100.0 (*SS0*) to 118.4 (*SS1*) and 126.0 (*SS2*).

#### 3.3.1 Proposition `[2A-Prop-Factor2]`: Observational Equivalence Failure in Aggregate Public Skill Outlays — Metropolitan Cost-of-Living Deflation vs. Frontier Saturation

In the two-stage Cunha–Heckman–Schennach skill operator (`Section 3.3`), childhood human capital in stage $`s \in \lbrace 1, 2 \rbrace`$ evolves via:

$$
\Theta_s\left(\tilde{\theta}_c\right) = \left\lbrack \gamma_{s,\mathrm{self}} \tilde{\theta}_c^{\varphi_s} + \gamma_{s,\mathrm{inv}} I_{s,k}^{\varphi_s} + \gamma_{s,\mathrm{par}} \bar{h}_p^{\varphi_s} \right\rbrack^{\frac{1}{\varphi_s}}, \qquad I_{s,k} = i_c + G_{\mathrm{ECE},s}^{\mathrm{eff}}(k) + \bar{g}_{\mathrm{ECE}}
$$

with Stage-1 substitutability $`\varphi_1 \in (0, 1)`$ ($`\sigma_1 = \frac{1}{1 - \varphi_1} > 1`$), Stage-2 complementarity $`\varphi_2 < 0`$ ($`\sigma_2 = \frac{1}{1 - \varphi_2} \in (0, 1)`$), and unbanked Stage-1 skill fade-out $`\theta_{c,\mathrm{ret}} = \theta_c - \delta_{\theta,\mathrm{fade}}(1 - M_{\mathrm{mentor}})\max(0, \theta_c - \theta_{\mathrm{base}})`$ [Ref 11, 15]. Suppose region $`k`$ allocates nominal per-child public education expenditure $`B_{\mathrm{edu},s,k}`$ financed by working-age labor tax $`\tau_l`$, decomposed into educator wage cost $`W_{\mathrm{teach},k}(Q_k) = w_{\mathrm{base}} \left(Q_k / Q_{\mathrm{ref}}\right)^{\nu_Q}`$ (with housing cost-of-living pass-through $`\nu_Q > 0`$ and commercial lease/overhead share $`\xi_{\mathrm{ovh},k} \in \lbrack 0, 1)`$) times real educator throughput $`\mathrm{FTE}_{s,k}`$, augmented by pedagogical/mentoring conversion efficiency $`\varepsilon_{\mathrm{ped},s,k} > 0`$ (`daruich_mult` and $`1 + \kappa_{\mathrm{down}} M_{\mathrm{mentor}} \bar{\theta}_{J=5}`$):

$$
B_{\mathrm{edu},s,k} = \frac{W_{\mathrm{teach},k}(Q_k) \cdot \mathrm{FTE}_{s,k}}{1 - \xi_{\mathrm{ovh},k}} \implies G_{\mathrm{ECE},s}^{\mathrm{eff}}(k) = \varepsilon_{\mathrm{ped},s,k} \, \mathrm{FTE}_{s,k} = \frac{\varepsilon_{\mathrm{ped},s,k} \left(1 - \xi_{\mathrm{ovh},k}\right)}{w_{\mathrm{base}} \left(Q_k / Q_{\mathrm{ref}}\right)^{\nu_Q}} B_{\mathrm{edu},s,k}
$$

Then nominal expenditure $`B_{\mathrm{edu},s,k}`$ fails observational equivalence as a sufficient statistic for human-capital formation across three structural regimes:

1. **Non-Identifiability of Equal Nominal Outlays:** Two jurisdictions or reform paths with identical statutory per-child spending ($`B_{\mathrm{edu},s,A} = B_{\mathrm{edu},s,B}`$) generate divergent real skill increments ($`\Delta \Theta_{s,A} \neq \Delta \Theta_{s,B}`$) whenever metropolitan land overvaluation ($`Q_k`$), overhead leakage ($`\xi_{\mathrm{ovh},k}`$), or pedagogical autonomy ($`\varepsilon_{\mathrm{ped},s,k}`$) differ.
2. **Primate-City *Kaiako* Cost-of-Living Attenuation (`Auckland` vs. `Helsinki`):** Under uniform national nominal capitation ($`\bar{B}_{\mathrm{edu},s}`$) without regional land-value cooling ($`Q_{\mathrm{Auckland}} \gg Q_{\mathrm{Rural}}`$), real delivered instructional input decays strictly with $`Q_k`$:

$$
\frac{\partial \ln G_{\mathrm{ECE},s}^{\mathrm{eff}}(k)}{\partial \ln Q_k}\bigg\vert_{B_{\mathrm{edu},s,k} = \bar{B}_{\mathrm{edu},s}} = -\nu_Q < 0
$$

   Simultaneously, high $`Q_k`$ pushes liquidity-constrained renter parents onto the $`i_c = 0`$ corner (`Section 3.2`), starving $`I_{2,k}`$ inside the Stage-2 bottleneck ($`\varphi_2 < 0`$) and compressing metropolitan long-run earnings elasticities relative to provincial regions unless coupled with land-tax cooling ($`\tau_a > 0 \implies \Delta Q_k < 0`$).
3. **Concave Stage-1 Frontier Saturation vs. Starved Bottlenecks (`FI_FBC1987` vs. `NZ_Dunedin1972` on `P0_Early_0to5`):** Let $`\mathrm{MVPF}_{s,k}`$ denote the net welfare change of a tax-financed increment $`d B_{\mathrm{edu},1,k} > 0`$ holding Stage-2 mentoring fixed ($`M_{\mathrm{mentor}} = 0`$), where $`\mathrm{MCF}(\tau_l) > 1`$ is the marginal cost of public funds at labor wedge $`\tau_l`$. The marginal Stage-1 skill yield with respect to nominal spending is:

$$
\frac{\partial \Theta_1}{\partial B_{\mathrm{edu},1,k}} = \gamma_{1,\mathrm{inv}} \left(\frac{\Theta_1}{I_{1,k}}\right)^{1 - \varphi_1} \frac{\partial G_{\mathrm{ECE},1}^{\mathrm{eff}}(k)}{\partial B_{\mathrm{edu},1,k}}, \qquad \text{retained at Gate 3 by } \left(1 - \delta_{\theta,\mathrm{fade}}\right)
$$

   * **Starved Baseline (`NZ_Dunedin1972`):** When baseline $`G_{\mathrm{ECE},1,0}`$ is low and a large birth share sits at $`i_c = 0`$ ($`I_{1,k} \to \bar{g}_{\mathrm{ECE}}`$ small) with moderate $`\tau_l = 0.220`$, $`(\Theta_1 / I_{1,k})^{1 - \varphi_1}`$ is large and net welfare $`d \mathrm{CE}_{\mathrm{LR}} / d B_{\mathrm{edu},1,k} > 0`$.
   * **Saturated Stage-1 Frontier (`FI_FBC1987`):** Because $`1 - \varphi_1 > 0`$, $`\partial \Theta_1 / \partial I_{1,k}`$ is strictly decreasing in $`I_{1,k}`$ ($`\partial^2 \Theta_1 / \partial I_{1,k}^2 < 0`$). When universal *Neuvola* and Nordic `ECEC` already situate $`I_{1,k}`$ near the concave frontier while unmentored Stage-2 fade-out ($`1 - \delta_{\theta,\mathrm{fade}}`$) and a high baseline labor tax wedge ($`\tau_l = 0.325 \implies \mathrm{MCF}(\tau_l)`$ high) remain binding, there exists a finite saturation threshold $`I_1^{\star}(\tau_l, \delta_{\theta,\mathrm{fade}})`$ above which standalone tax-financed Stage-1 spending reduces net welfare ($`d \mathrm{CE}_{\mathrm{LR}} / d B_{\mathrm{edu},1,k} < 0`$) unless coupled with Stage-2 mentoring (`C22`) and `Aspects 2 & 3` tax/land rebalancing.

---

##### Proof of `[2A-Prop-Factor2]`

**Parts 1 and 2 (Observational Non-Equivalence & Regional `Q_k` Deflation).**
Substituting $`G_{\mathrm{ECE},s}^{\mathrm{eff}}(k) = \varepsilon_{\mathrm{ped},s,k} (1 - \xi_{\mathrm{ovh},k}) w_{\mathrm{base}}^{-1} (Q_k / Q_{\mathrm{ref}})^{-\nu_Q} B_{\mathrm{edu},s,k}`$ into $`I_{s,k}`$ shows directly that the mapping $`B_{\mathrm{edu},s,k} \mapsto I_{s,k}`$ is non-injective over $`(\varepsilon_{\mathrm{ped},s,k}, \xi_{\mathrm{ovh},k}, Q_k)`$. Taking logs at fixed $`B_{\mathrm{edu},s,k} = \bar{B}_{\mathrm{edu},s}`$ gives $`\partial \ln G_{\mathrm{ECE},s}^{\mathrm{eff}}(k) / \partial \ln Q_k = -\nu_Q < 0`$. In Stage 2 (`Section 3.3`), because $`\varphi_2 = -0.95 < 0`$, differentiating $`\Theta_2`$ yields:

$$
\frac{\partial \Theta_2}{\partial G_{\mathrm{ECE},2}^{\mathrm{eff}}(k)} = \gamma_{2,\mathrm{inv}} \left(\frac{\Theta_2}{I_{2,k}}\right)^{1 - \varphi_2} = \gamma_{2,\mathrm{inv}} \left(\frac{\Theta_2}{i_c(Q_k) + G_{\mathrm{ECE},2}^{\mathrm{eff}}(k) + \bar{g}_{\mathrm{ECE}}}\right)^{1.95}
$$

In a primate city with uncooled $`Q_{\mathrm{Auckland}} = 3.10`$, a nominal schooling increment $`\Delta B_{\mathrm{edu},2,\mathrm{Akl}}`$ delivers only fraction $`(Q_{\mathrm{Akl}} / Q_{\mathrm{Rural}})^{-\nu_Q} < 1`$ of real `FTE` mentoring relative to `Rural`, attenuating $`\Delta \Theta_2`$ (`+1.38%` `Ebar_LR` in `Auckland` vs. `+2.04%` in `Rural` in `Table 5`), whereas uniform national *peruskoulu* conversion with moderated regional dispersion in `FI_FBC1987` yields near-uniform regional `Ebar_LR` (`+1.67%` to `+1.76%` across all four Finnish regions).

**Part 3 (Stage-1 Concavity and Tax-Financed Saturation Sign Flip).**
Differentiating $`\Theta_1`$ twice with respect to total Stage-1 investment $`I_{1,k}`$ for $`\varphi_1 \in (0, 1)`$:

$$
\frac{\partial \Theta_1}{\partial I_{1,k}} = \gamma_{1,\mathrm{inv}} \left(\frac{\Theta_1}{I_{1,k}}\right)^{1 - \varphi_1} > 0, \qquad \frac{\partial^2 \Theta_1}{\partial I_{1,k}^2} = -\left(1 - \varphi_1\right) \frac{\gamma_{1,\mathrm{inv}}}{I_{1,k}} \left(\frac{\Theta_1}{I_{1,k}}\right)^{1 - \varphi_1} \left(1 - \eta_{I,1,k}\right) < 0
$$

where $`\eta_{I,1,k} = \gamma_{1,\mathrm{inv}} (I_{1,k} / \Theta_1)^{\varphi_1} \in (0, 1)`$, confirming strict concavity and $`\lim_{I_{1,k} \to \infty} \partial \Theta_1 / \partial I_{1,k} = \gamma_{1,\mathrm{inv}}^{1/\varphi_1}`$ (or $`0`$ on marginal gain relative to self/parental anchors). Propagating $`d I_{1,k}`$ through Stage-2 fade-out ($`M_{\mathrm{mentor}} = 0`$) and adult discounted earnings PV $`\Pi_w`$ yields social marginal benefit per dollar of nominal `P0` spend:

$$
\mathrm{MB}_{1,k}\left(I_{1,k}\right) = \Pi_w \left(1 - \delta_{\theta,\mathrm{fade}}\right) \frac{\partial \Theta_2}{\partial \theta_{c,\mathrm{ret}}} \frac{\partial \Theta_1\left(I_{1,k}\right)}{\partial I_{1,k}} \frac{\partial G_{\mathrm{ECE},1}^{\mathrm{eff}}(k)}{\partial B_{\mathrm{edu},1,k}}
$$

which decreases strictly and continuously with baseline $`I_{1,k}`$, whereas the marginal welfare cost of labor-tax financing $`\mathrm{MCF}(\tau_l) = \frac{1}{1 - \tau_l - \tau_l \varepsilon_{\mathrm{ETI}} / (1 - \tau_l)}`$ increases strictly and convexly with $`\tau_l`$ [Ref 6]. Define $`I_1^{\star}(\tau_l, \delta_{\theta,\mathrm{fade}})`$ by $`\mathrm{MB}_{1,k}(I_1^{\star}) = \mathrm{MCF}(\tau_l)`$. For `NZ_Dunedin1972` ($`I_{1,0} < I_1^{\star}`$, $`\tau_l = 0.220`$), $`\mathrm{MB}_{1,k} > \mathrm{MCF}(\tau_l) \implies \Delta \mathrm{CE}_{\mathrm{LR}} > 0`$ (`+0.83%` to `+0.89%`). For `FI_FBC1987` ($`I_{1,0} > I_1^{\star}`$, $`\tau_l = 0.325`$), $`\mathrm{MB}_{1,k} < \mathrm{MCF}(\tau_l) \implies \Delta \mathrm{CE}_{\mathrm{LR}} < 0`$ (`-0.04%` to `-0.05%`), until Stage-2 mentoring (`M_mentor -> 1`) and `Grant E` / `tau_a` rebalancing lift $`\partial \Theta_2 / \partial \theta_{c,\mathrm{ret}}`$ and lower $`\tau_l`$ (`P0_Plus_GrantE` = `+3.61%` to `+4.81%` CE). $`\blacksquare`$

---

### 3.4 Paid vs. Unpaid Care, the Time-Energy Squeeze (Marilyn Waring), & Zero-State-Expansion Conditioning

Completing the household micro-foundation, Marilyn Waring's (1988 [Ref 47]) critique of national-accounts invisibility is formalized via a Becker–Gronau household time trichotomy [Ref 28], splitting the normalized period time endowment ($`T = 1`$) into **market labor ($`\ell_m`$)**, **unpaid household/*whānau* and community volunteer production ($`\ell_u = \ell_{u,\mathrm{home}} + \ell_{u,\mathrm{civic}}`$)**, and **pure leisure ($`1 - \ell_m - \ell_u`$)** [Ref 28, 30, 50]:

* Market non-energy goods and services ($`c_m`$, notably `Sector 3` private non-tradables priced at $`p_t^N`$) combine with unpaid home production ($`c_u = A_u \ell_{u,\mathrm{home}}^{\theta_u}`$) via a high-substitutability CES aggregator ($`\sigma_c > 1`$), while unpaid family and community hours feed directly into child skill transitions (`HumanCapital_Lifecycle_aprimeFn.m`), regional `K_whanau`, and `Sector 4A` polycentric co-production $`L_{u,\mathrm{civic},k}`$ [Ref 11, 29, 30, 47].
* When `Rural` and low-income urban families face high incompressible fossil/electricity bills $`\bar{e}(k)`$ and elevated rents $`r_{h,k}`$, adults must work extra survival market hours $`\ell_m`$, crowding out $`\ell_u`$ and triggering Stage-2 dynamic-complementarity losses ($`\varphi_2 = -0.95`$) ([Document 2T](Document%202T.md) [Ref 11, 23, 46]). Household electrification [Ref 46] and `Sector 4A` universal ECE relieve budget poverty and time poverty simultaneously.

#### Table 3.1: Zero-State-Expansion Conditioning Matrix Across VFI Toolkit Modules

Maintaining strict separation between the **inner backward-induction household state space** ($`N_a \times N_z`$) and **outer general-equilibrium clearing**, all four open-economy, exergy, dual-fuel, and Waring-care blocks incur **zero additional endogenous household state variables**:

| Architectural Block | Target Code / Solver Location | Mathematical Formulation & Calibration Hook | Grid / Compute Impact |
| :--- | :--- | :--- | :--- |
| **Block A: Spatial Exergy & Electricity Grid (Keen + Labrousse Firm Side)** | Outer GE Firm & Grid Block (`Compute_5Sector_Exergy_Equilibrium.m` + `TransPath_4Region_Master.m`) | Partition physical capital into regional productive ($`K_{Y,k,t}`$), public network ($`K_{G,k,t}`$), and renewable grid/firming capacity ($`K_{N,t}`$). Activate regional capital-labor with exergy $`X_{s,k}(e_N N_{s,k}, e_F F_{s,k})`$ under near-Leontief $`\sigma_{KL,X} \in \lbrack 0.05, 0.10 \rbrack`$ [Ref 9, 10, 23], dry-year peaking $`F_{N,t}`$, and gentailer markup $`M_{\mathrm{olig}}`$ on $`p_{N,t}`$ [Ref 39]. | **1.0x** VFI states & `d`-grid; +1–2 outer GE price paths ($`p_{N,t}, K_{N,t}`$). |
| **Block B: 5-Sector SOE, Civic/Defence Clearing & Debt-Elastic $`r_t`$** | Outer GE Sectoral, Labor & BoP Clearing (`Compute_5Sector_Exergy_Equilibrium.m` + `Compute_NDC_Compliance_Ledger.m`) | Clear **Sec 1** (Primary + `NDC` wedge [Ref 40]), **Sec 2** (Knowledge $`z_h`$ + Arrow spillover [Ref 10]), **Sec 3** (Private Non-Tradables $`p_t^N`$), **Sec 4A/4B** (Polycentric Civic Co-Production $`Y_{G,k}^{\mathrm{dev}} - Y_{G,k}^{\mathrm{rem}}`$ + Waters/Roads $`K_{G,k}`$ [Ref 29, 30, 36]), and **Sec 5** (Defence $`H_{D,k}, M_{D,t}^{\ast}`$ [Ref 59]) against BoP $`\mathrm{Exports}_t - p_F^{\ast} F_t - M_{D,t}^{\ast} = \Delta \mathrm{NFA}_t - r_t \mathrm{NFA}_{t-1}`$ [Ref 10, 23]. | **1.0x** VFI states; fast outer equilibrium solve. |
| **Block C: Analytical Dual-Fuel Household Demand** | Intra-period expenditure block inside `ReturnFn_SpatialHH.m` & `ReturnFn_SpatialHH_Compact4D.m` | Replace scalar regional subsistence with dual-fuel Stone-Geary incompressible exergy $`\bar{e}(k)`$ (lowered by `Sec 4B` PT/water & household electrification [Ref 46]) and CES utility over $`(e_N N_h, e_F F_h)`$ [Ref 9, 23], solved analytically in closed form and calibrated to Stats NZ HES [Ref 50]. | **1.0x** VFI states; **1.0x** `d`-grid (~1.1x arithmetic ops in `ReturnFn`). |
| **Block D: Waring Paid vs. Unpaid Care & Volunteer Co-Production** | Intra-period FOC in `ReturnFn_SpatialHH_Compact4D.m` + `Compute_ThreeTier_NationalAccounts_Ledger.m` | Split household time into $`(\ell_m, \ell_u, 1 - \ell_m - \ell_u)`$ [Ref 28, 47], feeding aggregate regional $`L_{u,k,t}`$ into `K_whanau` and `Sec 4A` volunteer co-production (`79,000 FTEs`), calibrated to Stats NZ TUS & JBWere 2026 [Ref 30, 50]. | **1.0x** VFI states; full 60-yr suite solves in **~1.3–4.5 mins**. |

---

## 4. 100% GPU-Vectorized Intergenerational & 4 × 5 Spatial Migration Operators (`Build_IntergenTransitionMatrix.m`)

To eliminate CPU nested loops, `Build_IntergenTransitionMatrix.m` executes all three intergenerational operators via 4D/5D GPU tensor broadcasting and `accumarray` projection, mapping the stationary distribution $`\mu_k\left(a, h, z, j\right)`$ and policy arrays `Policy` into the newborn adult distribution `jequaloneDist` ($`\mu_{1,k}\left(a_1, h_1, z_1\right)`$).

### 4.1 Stage 1 Operator ($Q_h$): Two-Stage Childhood Skill & Montessori / Tuakana–Teina Gate

For fertile parental cohorts in Stage 1 ($`\mathcal{J}_{c,1}`$) and Stage 2 ($`\mathcal{J}_{c,2}`$), expected log pre-labor-market skill $`\ln(\hat{h}_{\mathrm{child}})`$ integrates Stage-1 private and public investment $`(i_{c,1}, G_{\mathrm{ECE},1})`$, housing crowding penalties, and the **Gate 3 (`J = 5`, Ages 12–14) Montessori / *Tuakana–Teina* & Graeme Dingle Foundation Mentoring Operator**:

$$
\ln(\hat{h}_{\mathrm{child}}) = \rho_{hc} \ln(h_p) + \gamma_{ic} \ln\left(1 + i_{c,\mathrm{eff}} + G_{\mathrm{ECE,eff}}\right) - \psi_{\mathrm{crowd}} \ln(Q_k) \mathbb{I}_{\mathrm{hard}} + \Delta_{\mathrm{Adol}}(z_p, M_{\mathrm{Tuakana}}) + \eta_h
$$

where the Adolescent Gate (`J = 5`) transition term $\Delta_{\mathrm{Adol}}(z_p, M_{\mathrm{Tuakana}})$ captures both family unemployment vulnerability (`iz == 1`) and the reciprocal *Tuakana–Teina* / *Ako* / Montessori *Erdkinder* mentoring dividend:

$$
\Delta_{\mathrm{Adol}}(z_p, M_{\mathrm{Tuakana}}) = \begin{cases}
-0.22 & \text{if } z_p = z_1 \text{ and unbuffered by mentoring } (M_{\mathrm{Tuakana}} = 0) \\
0.00 & \text{if standard schooling } (z_p > z_1, M_{\mathrm{Tuakana}} = 0) \\
+0.05 \text{ in } SS0 \ (+0.11 \text{ in } SS1, +0.14 \text{ in } SS2) & \text{if enrolled in Montessori / Tuakana--Teina mentoring } (M_{\mathrm{Tuakana}} = 1)
\end{cases}
$$

### 4.2 Stage 2 Operator ($\mathbf{Q}_a$): The NZD 1.6T Property Estate Wave & Youth Capital Grant *E*
Dying retirees ($`j \ge J_r`$, weighted by mortality $`1 - s_j`$) in region *k* leave net-of-tax estates $`\left(1 - \tau_b\right) a^{\prime *}\left(a, h, z, j; k\right)`$. Adding the universal age-20 Youth Capital Grant *E* (`YouthGrant`) induces the initial young-adult asset distribution $`P_{a,k}\left(a_1\right)`$ over `a_grid`.

### 4.3 Stage 3 Operator ($\Pi_{\mathrm{mig}}$): The 4 × 5 Domestic & International (`Abroad`) Gumbel Youth Sorting Matrix
Upon launching at `j = 1` (age 20) in origin region $k \in \lbrace 1, 2, 3, 4 \rbrace$ with state $`\left(a_1, h_1, z_1\right)`$, young adults evaluate the 4 domestic regions $m \in \lbrace 1, 2, 3, 4 \rbrace$ (incurring moving/entry cost $`\kappa_{k \to m}`$) against the **5th outside option: emigrating to `Abroad` (Australia/OECD)** with continuation value $`V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right)`$ and Gumbel scale parameter $`\varrho_{\mathrm{mig}} > 0`$:

$$
P_t\left(k \to m \middle| a_1, h_1, z_1\right) = \frac{\exp\left(V_{m,t}\left(\max\left(a_{\min}, a_1 - \kappa_{k \to m}\right), h_1, z_1, 1\right) / \varrho_{\mathrm{mig}}\right)}{\exp\left(V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho_{\mathrm{mig}}\right) + \sum_{r=1}^{4} \exp\left(V_{r,t}\left(\max\left(a_{\min}, a_1 - \kappa_{k \to r}\right), h_1, z_1, 1\right) / \varrho_{\mathrm{mig}}\right)}
$$

$$
P_{\mathrm{emig},t}\left(k \to \mathrm{Abroad} \middle| a_1, h_1, z_1\right) = 1 - \sum_{m=1}^{4} P_t\left(k \to m \middle| a_1, h_1, z_1\right)
$$

**Calibration of the Gumbel Scale Parameter ($`\rho_G = 0.10`$ in Labrousse & Perdereau, 2025, Table 8 → $`\varrho_{\mathrm{mig}} = 0.180`$ in `Calibrate_NZ_Moments.m`):** In Table 8 (p. 54) of Labrousse and Perdereau (2025), their baseline Gumbel shock scale parameter is calibrated to $`\rho_G = 0.10`$ to match France's 5-year inter-regional stay rate of 85% (3% annual mobility). In our New Zealand model (`Calibrate_NZ_Moments.m`), $`\varrho_{\mathrm{mig}} = 0.180`$ is higher than France's 0.10 because under the 1973 Trans-Tasman Travel Arrangement (TTTA), New Zealand citizens have visa-free labor-market access to Australia and exhibit the highest cross-border skilled mobility rate in the OECD. Calibrating $`\varrho_{\mathrm{mig}}`$ in SMM (Table 6.1, Row 13) to match New Zealand's observed 10.93% national (and 19.29%–23.41% Auckland/Large-city) age 20–35 trans-Tasman/OECD departure rate uniquely pins down $`\varrho_{\mathrm{mig}} = 0.180`$.

### 4.4 Convex Transition Operator Mixing for Phased *Te Kāhui Waka* Rollouts (Waiters vs. Active Participants)

When the Phase 1 (`SS1`) reform suite is deployed across 13 annual regional waves (`Document 1D, Section 7` and `Document 2B, Section 7.6`) rather than as an instantaneous Day-1 step shock, at any transition period *t* inside the rollout window a fraction *s*<sub>k,m</sub>(*t*) ∈ {0, 1/3, 2/3, 1} of eligible households in region *k* are **Active Participants** receiving effective delivered policy intensity *G*<sub>k,m</sub><sup>eff</sup>(*t*), while the remaining 1 − *s*<sub>k,m</sub>(*t*) are **Waiters** facing the baseline status-quo intensity *G*<sub>m,0</sub>.

* **1. Avoiding Jensen's Inequality Aggregation Bias on Concave CES & LVR Sub-Manifolds:** A naive representative-input approximation replaces the phased wave with the population-weighted mean parameter *Ḡ*<sub>k,m</sub>(*t*) = (1 − *s*<sub>k,m</sub>(*t*))*G*<sub>m,0</sub> + *s*<sub>k,m</sub>(*t*)*G*<sub>k,m</sub><sup>eff</sup>(*t*) inside the skill production operator (**Section 3.3**) and the age-20 bequest/grant operator (**Section 4.2**). However, because the Stage-2 Cunha–Heckman CES technology exhibits strong dynamic complementarity (φ<sub>2</sub> = −0.95 < 0, σ<sub>2</sub> = 0.513 < 1) and the Kiyotaki et al. (2024) 20% LVR deposit rule (*a*<sub>1</sub> + *E* ≥ 0.20 *Q*<sub>k</sub>) is a non-linear step threshold, evaluating the transition laws at the blended parameter *Ḡ*<sub>k,m</sub>(*t*) violates Jensen's Inequality:

$$
f_{\mathrm{CES}}\Bigl(\theta_c, i_c, (1 - s_{k,m}) G_{m,0} + s_{k,m} G_{k,m}^{\mathrm{eff}}\Bigr) > (1 - s_{k,m}) f_{\mathrm{CES}}\bigl(\theta_c, i_c, G_{m,0}\bigr) + s_{k,m} f_{\mathrm{CES}}\bigl(\theta_c, i_c, G_{k,m}^{\mathrm{eff}}\bigr)
$$

  Giving 100% of adolescents one-third of a *Tuakana–Teina* mentor or 100% of 20-year-olds one-third of a Youth Capital Grant *E* fails to clear either the harmonic-mean skill bottleneck or the 20% metropolitan deposit cliff; whereas giving one-third of the cohort full wraparound mentoring and the full grant lifts that one-third cleanly across the threshold while leaving the waiting two-thirds on the baseline trajectory until their wave arrives.

* **2. Dimension-Free Isomorphism via Convex Operator Mixing (`Build_IntergenTransitionMatrix.m`):** Adding an explicit binary state variable ω ∈ {0 (Waiter), 1 (Active)} to the household state vector (*a*, *h*, θ<sub>c</sub>, *z*, ω, *j*) would double the size of all value, policy, and stationary distribution tensors (`61 × 7 × 9 × 7 × 2 × J`). Instead, by linearity of the Perron–Frobenius push-forward operator, `Build_IntergenTransitionMatrix.m` evaluates the pure **Active Participant transition kernel** **T**<sub>k</sub><sup>Active</sup>(*G*<sub>k,m</sub><sup>eff</sup>(*t*)) (`pdf_5D_act` and `Prob_a_act`) and the pure **Waiter transition kernel** **T**<sub>k</sub><sup>Waiter</sup>(*G*<sub>m,0</sub>) (`pdf_5D_wait` and `Prob_a_wait`) separately on the GPU and mixes their resulting probability measures:

$$
\mathbf{T}_{k,t}^{\mathrm{Mix}} = \bigl(1 - s_{k,m}(t)\bigr) \mathbf{T}_{k}^{\mathrm{Waiter}}\bigl(G_{m,0}\bigr) + s_{k,m}(t) \mathbf{T}_{k}^{\mathrm{Active}}\bigl(G_{k,m}^{\mathrm{eff}}(t)\bigr)
$$

  This convex combination of pure operators reproduces the exact cross-sectional marginal distribution of the augmented state space (*a*, *h*, θ<sub>c</sub>, *z*, ω) on the existing grid (`n_a = [61, 7, 9]`, `n_z = 7`) at **zero additional GPU memory or Bellman iteration cost**.

* **3. Intertemporal Wave Convolution into Phase 2 (`SS2` Generational Echo):** Because each regional echelon *w* ∈ {1, …, 13} enters treatment at calendar year *t* = *w* with incremental national share Δ*s*<sub>m</sub>(*w*) = *s*<sub>m</sub>(*w*) − *s*<sub>m</sub>(*w* − 1), the second-generation dynastic skill and enterprise-sorting harvest (`Jump 2` in `WelfareDecomposition_4Region.m` and `Traj_11` in `Plot_Counterfactuals_And_MirrorInvestments.m`) is governed not by a single step-function exponential at *t* = 25, but by the discrete convolution of the `SS1` wave increments Δ*s*<sub>m</sub>(*w*) with the cohort maturation kernel *K*<sub>mat</sub>(*t* − *w* − *T*<sub>gen,m</sub>). This preserves exact phase continuity between the `SS1` rollout (`Years 1–13`) and the `SS2` dynastic harvest (`Years 21.5–35`).

---

### Navigation to Part B & Companion Tutorial
* **Continue to [Document 2B (Sections 5–10)](Document%202B.md):** *Part B — Coupled General-Equilibrium Synthesis, 6-Gate Fiscal Sankey, 2050 Debt-Sinking Protocol, Fertility & Super-Age U-Curve, SMM Calibration, Actuarial Continuation Valuation, 11-Layer Supermodular Attribution, Code Manifest, & Master Reference Library.*
* **Companion Tutorial [Document 2T](Document%202T.md):** *"Thick" vs. "Thin" Numbers in Quantitative Public Policy — Why Dimension-Free State-Contingent Conditioning Captures Comonotonic Tail Risks Without Expanding GPU Grid Dimensions.*
