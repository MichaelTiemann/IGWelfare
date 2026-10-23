# Intergenerational Welfare Technical Documentation & Model Specification Guide
**A GPU-Accelerated Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial Overlapping Generations Framework (Multiphase Edition)**

**Author:** Michael Tiemann ([mdtiemann@gmail.com](mailto:mdtiemann@gmail.com))  
**Date:** October 2026 | **Code & Replication Repository:** [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)

---

## 1. Model Overview, Spatial Taxonomy, & Flexible Period Resolution ($\Delta t \in \lbrace 5, 3, 2, 1 \rbrace$)

### 1.1 Mixed-Horizon 8-PType GPU Architecture
We formulate a quantitative general-equilibrium Spatial Overlapping Generations (OLG) model of Aotearoa New Zealand implemented on the GPU via the VFI Toolkit mixed finite/infinite-horizon permanent-type engines (`ValueFnIter_MixHorz_PType` and `StationaryDist_MixHorz_PType`). The domestic economy is partitioned into $N_{\mathrm{reg}} = 4$ geographic tiers indexed by $k \in \lbrace 1, 2, 3, 4 \rbrace \equiv \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$, augmented by a 5th endogenous outside option $k = 5 \equiv \mathrm{Abroad}$ (representing skilled youth emigration to Australia and the wider OECD):
1. **`HH_Rural` & `Firm_Rural` (16.0% Base Household Share, 15.0% Firm Share):** Agricultural, primary-sector, and remote districts characterized by responsive land supply ($Q_{\mathrm{Rural},\mathrm{SS0}} = 1.05$) and elevated mandatory fuel/transport subsistence costs ($\bar{e}_{\mathrm{Rural}} = 0.048$).
2. **`HH_Small` & `Firm_Small` (24.0% Base Household Share, 23.0% Firm Share):** Secondary provincial towns (population under 100,000) with moderate housing user costs ($Q_{\mathrm{Small},\mathrm{SS0}} = 1.40$) and compressed wage ceilings.
3. **`HH_Large` & `Firm_Large` (25.9% Base Household Share, 26.9% Firm Share):** Major regional metropolitan centers (population over 100,000: Wellington, Christchurch, Hamilton, Tauranga, and Dunedin) featuring tertiary university hubs, constrained urban land ($Q_{\mathrm{Large},\mathrm{SS0}} = 2.05$), and high outward youth turnover.
4. **`HH_Auckland` & `Firm_Auckland` (34.1% Base Household Share, 35.1% Firm Share):** The primate metropolitan agglomeration featuring the highest entrepreneurial productivity ceiling ($z_{h,\mathrm{Akl}} = 1.75$), the steepest land supply inelasticity ($Q_{\mathrm{Auckland},\mathrm{SS0}} = 3.10$), and severe young-renter crowd-out.

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
* **Lifecycle Horizon & Age Brackets:** Adult biological ages span 20 to 99 ($80$ years), yielding $J = \mathrm{round}\left(80 / \Delta t\right)$ model periods (`J = 16` at $\Delta t = 5$; `J = 27` at $\Delta t = 3$). Retirement begins at age 65: $J_r = \mathrm{round}\left(45 / \Delta t\right) + 1$ (`Jr = 10` at $\Delta t = 5$; `Jr = 16` at $\Delta t = 3$).
* **Childhood Developmental Sub-Stages ($\mathcal{J}_{c,1}$ and $\mathcal{J}_{c,2}$):** Children are born when parents are age 26 ($j_{\mathrm{birth}} = \mathrm{round}\left(6 / \Delta t\right) + 1$).
  * **Stage 1 (First 2000 Days, Child Ages 0–5):** Spans $n_{s1} = \mathrm{round}\left(6 / \Delta t\right)$ parental periods $\mathcal{J}_{c,1} = \lbrace j_{s1,\mathrm{start}}, \dots, j_{s1,\mathrm{end}} \rbrace$ ($j_p = 3$ at $\Delta t = 5$; $j_p \in \lbrace 3, 4 \rbrace$ at $\Delta t = 3$).
  * **Stage 2 (Primary/Secondary Schooling & Adolescent Gate, Child Ages 6–17):** Spans $n_{s2} = \mathrm{round}\left(12 / \Delta t\right)$ parental periods $\mathcal{J}_{c,2} = \lbrace j_{s2,\mathrm{start}}, \dots, j_{s2,\mathrm{end}} \rbrace$ ($j_p \in \lbrace 4, 5 \rbrace$ at $\Delta t = 5$; $j_p \in \lbrace 5, 6, 7, 8 \rbrace$ at $\Delta t = 3$).
* **Compound Discounting & Flow Scaling ($\mathrm{dt\_scale} = \Delta t / 5$):**

$$\beta_{hh}\left(\Delta t\right) = \beta_{\mathrm{ann}}^{\Delta t}, \qquad r\left(\Delta t\right) = \left(1 + r_{\mathrm{ann}}\right)^{\Delta t} - 1, \qquad s_j\left(\Delta t\right) = \left(s_{j,\mathrm{5yr}}\right)^{\Delta t / 5}$$

$$G_{\mathrm{ECE}}\left(\Delta t\right) = \left(\frac{\Delta t}{5}\right) G_{\mathrm{ECE,5yr}}, \qquad T_k\left(\Delta t\right) = \left(\frac{\Delta t}{5}\right) T_{k,\mathrm{5yr}}, \qquad \bar{e}_k\left(\Delta t\right) = \left(\frac{\Delta t}{5}\right) \bar{e}_{k,\mathrm{5yr}}$$

while stock endowments (`YouthGrant` $E$) and proportional tax rates ($\tau_l, \tau_c, \tau_k, \tau_b$) are invariant to $\Delta t$, and the book-value wealth tax compounds as $\left(1 - \tau_a\right)^{\Delta t}$.

---

## 2. Infinite-Horizon Entrepreneurial Firms & Capital Reallocation (Lens 3)

Following Guvenen, Kambourov, Kuruscu, Ocampo, and Chen (2023), each region $k$ contains a unit measure of infinite-horizon entrepreneurial firms (`Firm_Rural`, `Firm_Small`, `Firm_Large`, `Firm_Auckland`) with state vector $\left(a_f, z_f\right) \in \mathcal{A}_f \times \mathcal{Z}_{f,k}$, where $a_f$ is firm book equity and $z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$ is idiosyncratic entrepreneurial productivity evolving via Markov matrix $\Pi_{f,k}$.

### 2.1 Collateral-Constrained Profit Maximization & "Use-It-Or-Lose-It" Return
Firms rent capital $k_f \le \lambda_{\mathrm{col}} a_f$ (with collateral multiplier $\lambda_{\mathrm{col}} = 2.50$) and hire regional effective labor $\ell_f$ at wage $w_k$ to produce output $y_f = z_f \left(k_f^{\alpha_k} \ell_f^{1 - \alpha_k}\right)^{1 - \nu_{\mathrm{span}}}$. Integrating out static factor demands yields the gross-of-equity-tax rate of return on firm equity $R_k\left(z_f; \Delta t\right)$ (`ReturnFn_Firm.m`):

$$R_k\left(z_f; \Delta t\right) = \left(1 - \tau_a\right)^{\Delta t} + \left(1 - \tau_k\right) \left\lbrack r\left(\Delta t\right) + \max\left\lbrace 0, \, \pi_k^{*}\left(z_f, w_k\right) - \left(r\left(\Delta t\right) + \delta_k\left(\Delta t\right)\right) \right\rbrace \lambda_{\mathrm{col}} \right\rbrack$$

$$\pi_k^{*}\left(z_f, w_k\right) = \alpha_k \left(\frac{1 - \alpha_k}{w_k}\right)^{\frac{1 - \alpha_k}{\alpha_k}} z_f^{\frac{1}{\alpha_k}}$$

### 2.2 Firm Bellman Equation & Stationary Equity Distribution ($\Gamma_k$)
Each firm solves the infinite-horizon Bellman equation:

$$V_{F,k}\left(a_f, z_f\right) = \max_{a_f^{\prime} \in \left\lbrack 0, \, R_k\left(z_f; \Delta t\right) a_f \right\rbrack} \left\lbrace \ln\left(R_k\left(z_f; \Delta t\right) a_f - a_f^{\prime} + \varepsilon_c\right) + \beta_{\mathrm{firm}}\left(\Delta t\right) \sum_{z_f^{\prime}} \Pi_{f,k}\left(z_f^{\prime} \;\middle|\; z_f\right) V_{F,k}\left(a_f^{\prime}, z_f^{\prime}\right) \right\rbrace$$

Replacing distortionary capital income taxation ($\tau_k$) with a book-value wealth/land tax ($\tau_a = 0.015$) penalizes low-productivity land-banking firms ($z_{\ell,k}$) while leaving high-productivity firms ($z_{h,k}$) with a higher marginal saving propensity, shifting the stationary equity distribution $\Gamma_k\left(a_f, z_f\right)$ toward $z_{h,k}$ and raising endogenous regional total factor productivity $Z_k\left(\Gamma_k\right)$.

---

## 3. Finite-Horizon Household Problem Across Lenses 1, 2, and 3

### 3.1 State Vector, Decision Grids, & Return Function Signature
In the compact 4D GPU specification (`ReturnFn_SpatialHH_Compact4D.m`, 40 arguments), a household in region $k$ at age bracket $j \in \lbrace 1, \dots, J \rbrace$ has state vector $\left(a, h, z, j\right)$ and chooses decision vector $d = \left(\ell, I_h, i_c\right)$ and next-period states $\left(a^{\prime}, h^{\prime}\right)$:
* `d_grid`: $\ell \in \lbrack 0.2, 1.0\rbrack$ ($n_{d1} = 5$, labor supply), $I_h \in \lbrack 0, 0.35\rbrack$ ($n_{d2} = 4$, adult Ben-Porath training time), $i_c \in \lbrack 0, 0.45\rbrack$ ($n_{d3} = 5$, private early/school child investment).
* `a_grid`: $a \in \lbrack 0.001, 15.0\rbrack$ ($n_{a1} = 25$, household net worth) and $h \in \lbrack 0.45, 0.65, 0.85, 1.00, 1.20, 1.45, 1.80\rbrack$ ($n_{a2} = 7$, adult human capital tiers $h_1 \dots h_7$).
* `z_grid`: $z \in \mathcal{Z}_{hh}$ ($n_z = 5$, Rouwenhorst idiosyncratic earnings shock, where $i_z = 1$ denotes unemployment/severe distress).

*(In the full two-stage CES experience-asset specification with Emigration Abroad, `ReturnFn_SpatialHH.m` and `HumanCapital_Lifecycle_aprimeFn.m`, `a_grid` also tracks the 5-point child skill experience asset $\theta_c \in \mathcal{G}_{\theta}$ across childhood stages $\mathcal{J}_{c,1}$ and $\mathcal{J}_{c,2}$.)*

### 3.2 Budget Constraint, Stone-Geary Subsistence, & Housing Tenure Cutoff
Effective labor supply during working life ($j < J_r$) is $\ell_{\mathrm{eff}} = \max\left(0, \, \ell - I_h\right)$, generating gross labor income $y_{\mathrm{lab}} = w_k z h \ell_{\mathrm{eff}}$. In retirement ($j \ge J_r$), households receive universal New Zealand Superannuation $p_{\mathrm{super}}$ plus means-tested consumption floor support $\underline{c}$. Total disposable cash-on-hand available for composite expenditure $e_{\mathrm{tot}}$ is:

$$y_{\mathrm{disp}} = \left(1 - \tau_a\right)^{\Delta t} a + \left(1 - \tau_k\right) r\left(\Delta t\right) a + \left(1 - \tau_l\right) y_{\mathrm{lab}} + \mathbb{I}_{\left\lbrace j \ge J_r\right\rbrace} p_{\mathrm{super}} + \mathbb{I}_{\left\lbrace j = 1\right\rbrace} E + T_k\left(a, y_{\mathrm{lab}}\right)$$

$$e_{\mathrm{tot}} = \frac{y_{\mathrm{disp}} - \bar{e}_k - \mathbb{I}_{\left\lbrace j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}\right\rbrace} \left(1 - s_{\mathrm{sub}}\right) i_c - a^{\prime}}{1 + \tau_c}$$

Following Kiyotaki, Michaelides, and Nikolov (2024), households with net worth below the regional down-payment threshold ($a < \xi_k Q_k$, where $\xi_k = 0.20$) are **Renters** facing rental user cost $r_{h,k}^{\mathrm{rent}} = \left(1 + \mu_{\mathrm{maint}} - G_k / R\right) Q_k$, while households with $a \ge \xi_k Q_k$ are **Homeowners** facing user cost $r_{h,k}^{\mathrm{own}} = \left(1 + \mu_{\mathrm{maint}} - G_k / R - \psi_{\mathrm{own}}\right) Q_k$. Optimal non-durable consumption $c_{nd} = \phi_{nd} e_{\mathrm{tot}}$ and housing services $c_H = \left(1 - \phi_{nd}\right) e_{\mathrm{tot}} / r_{h,k}$ combine in the Cobb-Douglas bundle $c_{\mathrm{comp}} = c_{nd}^{\phi_{nd}} c_H^{1 - \phi_{nd}}$.

### 3.3 Per-Period Utility, Altruistic Child-Skill Payoff, & Relational Cohesion Dividend
Total flow utility $u_k\left(d, a, h, z, j\right)$ unifies five structural terms:

$$u_k = \frac{c_{\mathrm{comp}}^{1 - \eta_c}}{1 - \eta_c} - \psi_{\ell} \frac{\ell^{1 + 1/\varepsilon_{\ell}}}{1 + 1/\varepsilon_{\ell}} + \mathbb{I}_{\left\lbrace j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}\right\rbrace} u_{\mathrm{child}}\left(i_c, h, a; k\right) + \left(1 - s_j\right) u_{\mathrm{beq}}\left(a^{\prime}; \tau_b\right) + u_{\mathrm{rel}}\left(\mathrm{Frac}_{\mathrm{stunted}}, S_t\right)$$

1. **Two-Stage Child Skill Formation & Ferriere et al. (2025) Luxury Threshold ($\bar{g}_{\mathrm{ECE}} > 0$):**
   During Stage 1 ($j \in \mathcal{J}_{c,1}$, First 2000 Days, $\varphi_1 = 0.35$) and Stage 2 ($j \in \mathcal{J}_{c,2}$, Schooling & Montessori / *Tuakana–Teina* Mentoring, $\varphi_2 = -0.95$), effective developmental input is $I_{c,\mathrm{eff}} = \max\left(0, \, i_c + G_{\mathrm{ECE},s} - \bar{g}_{\mathrm{ECE}}\right)$, yielding perceived child-skill utility:

$$u_{\mathrm{child}}\left(i_c, h, a; k\right) = \omega_{ic} \ln\left(1 + \gamma_{s,1} h^{\varphi_s} + \gamma_{s,2} I_{c,\mathrm{eff}}^{\varphi_s}\right)^{\frac{1}{\varphi_s}} - \psi_{\mathrm{crowd}} \ln\left(Q_k\right) \mathbb{I}_{\left\lbrace a < 0.08 Q_k\right\rbrace}$$

2. **De Nardi (2004) Luxury Warm-Glow Bequest Motive:**

$$u_{\mathrm{beq}}\left(a^{\prime}; \tau_b\right) = b_1 \frac{\left\lbrack \left(1 + \frac{\left(1 - \tau_b\right) a^{\prime}}{b_2}\right)^{1 - \eta_c} - 1 \right\rbrack}{1 - \eta_c}$$

3. **Relational Altruism, Social Cohesion Utility ($u_{\mathrm{rel}}$), & Transparency International CPI Calibration:**
   Captures the utility gain experienced by citizens and aging parents when cohort stunting (`Frac_stunted`) is compressed and domestic social cohesion ($S_t$, `S_cohesion`) rises as educated youth remain in New Zealand:

$$u_{\mathrm{rel}}\left(\mathrm{Frac}_{\mathrm{stunted}}, S_t\right) = \chi_{\mathrm{rel}} \left\lbrack \left(0.285 - \mathrm{Frac}_{\mathrm{stunted}}\right) + 0.015 \left(S_t - 100\right) \right\rbrack$$

   Along the transition path, the macro **Social Cohesion Index** $S_t$ evolves endogenously as a linear functional of cohort stunting compression, youth brain-drain closure (`Nat_Emig_Abroad_Pct`), and moderated replacement-migration turnover (`Churn_Rate`):

$$S_t = 100.0 + \zeta_{\mathrm{stunt}} \left(0.220 - \mathrm{Frac}_{\mathrm{stunted},t}\right) + \zeta_{\mathrm{ret}} \left(0.1093 - \mathrm{Emig}_{\mathrm{Nat},t}\right) - \zeta_{\mathrm{churn}} \max\left(0, \, \mathrm{Churn}_t - \overline{\mathrm{Churn}}\right)$$

   Empirically, $S_t$ is anchored to New Zealand's sovereign **Transparency International Corruption Perceptions Index (CPI)** ("Social Credit Rating"), which declined from **96/100** (2004 peak) and **88/100** (#1 equal globally in 2021) to a 30-year low of **81/100** (#4 equal in the 2025/2026 release, behind **#1 Denmark at 89, #2 Finland at 88, and #3 Singapore at 84**; Office of the Controller and Auditor-General, *New Zealand's Integrity Inheritance*, 2026; TI-NZ *National Integrity System Gap Analysis*, 2026). Compressing $\mathrm{Frac}_{\mathrm{stunted}}$ from $0.220$ to $0.015$ and cutting $\mathrm{Emig}_{\mathrm{Nat}}$ from $10.93\%$ to $7.60\%$ lifts $S_t$ from $100.0$ (`SS0`) to $118.4$ (`SS1`) and $126.0$ (`SS2`).

---

## 4. 100% GPU-Vectorized Intergenerational & $4 \times 5$ Spatial Migration Operators (`Build_IntergenTransitionMatrix.m`)

To eliminate CPU nested loops, `Build_IntergenTransitionMatrix.m` executes all three intergenerational operators via 4D/5D GPU tensor broadcasting and `accumarray` projection, mapping the stationary distribution $\mu_k\left(a, h, z, j\right)$ and policy arrays `Policy` into the newborn adult distribution `jequaloneDist` ($\mu_{1,k}\left(a_1, h_1, z_1\right)$).

### 4.1 Stage 1 Operator ($\mathbf{Q}_h$): Two-Stage Childhood Skill & Montessori / *Tuakana–Teina* Gate
For fertile parental cohorts $j_p \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}$, expected log pre-labor-market skill $\ln\left(\hat{h}_{\mathrm{child}}\right)$ integrates Stage-1 private/public investment $\left(i_{c,1}, G_{\mathrm{ECE},1}\right)$, housing crowding penalties, and the **Gate 3 ($J = 5$, Ages 12–14) Montessori / *Tuakana–Teina* & Graeme Dingle Foundation Mentoring Operator**:

$$\ln\left(\hat{h}_{\mathrm{child}}\right) = \rho_{hc} \ln\left(h_p\right) + \gamma_{ic} \ln\left(1 + i_{c,\mathrm{eff}} + G_{\mathrm{ECE,eff}}\right) - \psi_{\mathrm{crowd}} \ln\left(Q_k\right) \mathbb{I}_{\mathrm{hard}} + \Delta_{\mathrm{Adol}}\left(z_p, \mathcal{M}_{\mathrm{Tuakana}}\right) + \eta_h$$

where the Adolescent Gate ($J = 5$) transition term $\Delta_{\mathrm{Adol}}\left(z_p, \mathcal{M}_{\mathrm{Tuakana}}\right)$ captures both family unemployment vulnerability (`iz == 1`) and the reciprocal *Tuakana–Teina* / *Ako* / Montessori *Erdkinder* mentoring dividend:

$$\Delta_{\mathrm{Adol}}\left(z_p, \mathcal{M}_{\mathrm{Tuakana}}\right) = \begin{cases}
-0.22 & \text{if } z_p = z_1 \text{ and unbuffered by mentoring } \left(\mathcal{M}_{\mathrm{Tuakana}} = 0\right) \\
0.00 & \text{if standard schooling } \left(z_p > z_1, \, \mathcal{M}_{\mathrm{Tuakana}} = 0\right) \\
+0.05 \text{ in } \mathrm{SS0} \;\left(+0.11 \text{ in } \mathrm{SS1}, \, +0.14 \text{ in } \mathrm{SS2}\right) & \text{if enrolled in Montessori / \textit{Tuakana--Teina} mentoring } \left(\mathcal{M}_{\mathrm{Tuakana}} = 1\right)
\end{cases}$$

### 4.2 Stage 2 Operator ($\mathbf{Q}_a$): The NZD 1.6T Property Estate Wave & Youth Capital Grant $E$
Dying retirees ($j \ge J_r$, weighted by mortality $1 - s_j$) in region $k$ leave net-of-tax estates $\left(1 - \tau_b\right) a^{\prime *}\left(a, h, z, j; k\right)$. Adding the universal age-20 Youth Capital Grant $E$ (`YouthGrant`) induces the initial young-adult asset distribution $P_{a,k}\left(a_1\right)$ over `a_grid`.

### 4.3 Stage 3 Operator ($\Pi_{\mathrm{mig}}$): The $4 \times 5$ Domestic & International (`Abroad`) Gumbel Youth Sorting Matrix
Upon launching at $j = 1$ (age 20) in origin region $k \in \lbrace 1, 2, 3, 4 \rbrace$ with state $\left(a_1, h_1, z_1\right)$, young adults evaluate the 4 domestic regions $m \in \lbrace 1, 2, 3, 4 \rbrace$ (incurring moving/entry cost $\kappa_{k \to m}$) against the **5th outside option: emigrating to `Abroad` (Australia/OECD)** with continuation value $V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right)$ and Gumbel scale parameter $\varrho_{\mathrm{mig}} > 0$:

$$P_t\left(k \to m \;\middle|\; a_1, h_1, z_1\right) = \frac{\exp\left(V_{m,t}\left(\max\left(a_{\min}, a_1 - \kappa_{k \to m}\right), h_1, z_1, 1\right) / \varrho_{\mathrm{mig}}\right)}{\exp\left(V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho_{\mathrm{mig}}\right) + \sum_{r=1}^{4} \exp\left(V_{r,t}\left(\max\left(a_{\min}, a_1 - \kappa_{k \to r}\right), h_1, z_1, 1\right) / \varrho_{\mathrm{mig}}\right)}$$

$$P_{\mathrm{emig},t}\left(k \to \mathrm{Abroad} \;\middle|\; a_1, h_1, z_1\right) = 1 - \sum_{m=1}^{4} P_t\left(k \to m \;\middle|\; a_1, h_1, z_1\right)$$

---

## 5. Post-Hoc Lifecycle Operators: The 6-Gate Fiscal Ledger, Statutory Fiscal Rules, Fertility Bargaining, & 12-Tier Wealth Incidence

### 5.1 The 6-Gate (26-Node) Lifecycle Fiscal Ledger Operator (`Plot_ChildFiscal_2Panel_SSankey.m`)
To map all private parental commitments and public fiscal flows from Birth ($J = 1$) to Retirement ($J = 16$) without expanding the VFI state space, `Plot_ChildFiscal_2Panel_SSankey.m` defines linear integral operators over the solved stationary distribution $\mu_k\left(a, h, z, j\right)$ and policy functions `Policy`:
* **Cohort-Weighted Ribbon Width Identity:** Every node $i \in \lbrace 1, \dots, 26 \rbrace$ at Gate $g \in \lbrace 1, \dots, 6 \rbrace$ has ribbon thickness strictly equal to its cohort-weighted annual monetary flow (in real 2025 NZD thousands per year per cohort birth):

$$\mathrm{Flow}_{g,i}^{\mathrm{cohort}} = p_{g,i} \times c_{g,i}^{\mathrm{cond}}$$

  where $p_{g,i} = \int_{\mathcal{S}_{g,i}} d\mu_k$ is the fraction of the cohort in node $\mathcal{S}_{g,i}$ and $c_{g,i}^{\mathrm{cond}}$ is the conditional annual dollar flow per person in that node.
* **4-Block Childhood Split at Gate 2 ($J = 2\text{--}3$) and Gate 3 ($J = 5$):**
  Separates childhood resource flows into four orthogonal accounting lanes:
  1. **Lane A (`LaneA_Priv_Cash_kNZD`):** Out-of-pocket parental cash $\left(1 - s_{\mathrm{sub}}\right) i_c + \theta_{\mathrm{child}}\left(c_{nd} + r_{h,k} c_H\right)$.
  2. **Lane B (`LaneB_Priv_Time_kNZD`):** Imputed parental care and mentoring time $w_k z_p h_p \ell_{\mathrm{child}}$.
  3. **Lane C (`LaneC_Pub_DevInv_kNZD`):** Universal PPL/BestStart, public wraparound ECE $G_{\mathrm{ECE},1}$, public schooling $d_2$, and Montessori / *Tuakana–Teina* & Graeme Dingle Foundation mentoring $G_{\mathrm{ECE},2}$.
  4. **Lane D (`LaneD_Pub_Remed_kNZD`):** Means-tested hardship transfers $T_k$ and in-childhood acute Exits 1, 2, and 4.

### 5.2 Net Fiscal Balance ($\Omega_{\mathrm{fiscal}}$), The 2050 Sovereign Debt-Sinking Protocol, & New Zealand Statutory Law
At **Gate 5 (Age 30, $J = 10$)** and **Gate 6 (Career to Retirement, $J = 11\text{--}16$)**, the cohort-weighted **Net Fiscal Balance** $\Omega_{\mathrm{fiscal},g}$ is:

$$\Omega_{\mathrm{fiscal},g} = \underbrace{\left(\mathrm{Tax}_{\mathrm{PAYE},g} + \mathrm{Tax}_{\mathrm{GST+Cap+Beq},g}\right)}_{\text{Good Taxes Collected}} - \underbrace{\left(\mathrm{Burden}_{\mathrm{Exits\,1,2,4},g} + \mathrm{Outlay}_{\mathrm{Infra+Health+Super},g}\right)}_{\text{Direct Public Outlays}}$$

Under the **2050 Sovereign Debt-Sinking & Public Reinvestment Protocol** (`Build_Custom_Protocol_2050_Table`), any positive net fiscal surplus $\Omega_{\mathrm{reform},g} = \max\left(0, \, \Omega_{\mathrm{fiscal},g}\right)$ is partitioned 50/50:

$$\Omega_{\mathrm{debt},g} = 0.50 \, \Omega_{\mathrm{reform},g}, \qquad \Omega_{\mathrm{reinv},g} = 0.50 \, \Omega_{\mathrm{reform},g}$$

$$\Delta D_{2050,g} = N_{\mathrm{births}} \, \Omega_{\mathrm{debt},g} \sum_{\tau=1}^{25} \left(1 + r_{\mathrm{bond}}\right)^{\tau - 1}, \qquad \mathcal{S}_{\mathrm{reinv},g} = \mu_{\mathrm{infra}} \, \Omega_{\mathrm{reinv},g}$$

with $N_{\mathrm{births}} = 60,000/\text{yr}$, sovereign bond yield $r_{\mathrm{bond}} = 0.042$, and public infrastructure multiplier $\mu_{\mathrm{infra}} = 1.65$.

* **Statutory & Legal Integration Under New Zealand Public Finance Law:**
  1. ***Public Finance Act 1989* (Part 2, Sections 26G–26Z — Principles of Responsible Fiscal Management):** Section 26G(1)(a)–(e) mandates that the Crown must *"reduce total debt to prudent levels"* and *"have regard to the likely impact of fiscal strategy on present and future generations."* Under the status quo documented in the Treasury's *He Tirohanga Mokopuna 2025* and March 2026 background papers (*AN 26/01* and *WP 26/01*, where long-run labour productivity growth is downgraded to $0.9\%/\text{yr}$ and net core Crown debt reaches ~200% of GDP by 2065 unless average labour tax or GST rises to 32%), the Crown violates intergenerational fiscal prudence on a cash-flow basis. Embedding the **Actuarial Continuation Valuation ($\mathcal{V}_{k,t_0}^{\left(\mathrm{Fiscal}\right)}$)** alongside the **OBEGAL (Operating Balance Before Gains and Losses)** note disclosures and locking 50% of post-breakeven surpluses into $\Omega_{\mathrm{debt},g}$ operationalizes Section 26G(1)(e) in statutory Crown accounts.
  2. ***Accident Compensation Act 2001* & Generally Accepted Accounting Practice (PBE IPSAS 19 / IFRS 17 Actuarial Provisions):** New Zealand's Crown balance sheet already recognizes the present value of future multi-decade injury rehabilitation liabilities via the ACC Outstanding Claims Liability (NZD 63.6B). Booking the verified reduction in future Oranga Tamariki (*Oranga Tamariki Act 1989*), justice, and hospital remediation liabilities at Gate 2 ($J=2\text{--}3$) and Gate 3 ($J=5$) applies identical actuarial accounting standards to childhood stunting prevention.
  3. **Preventative Infrastructure Stewardship (*Local Government (Water Services) / Te Waihanga National Infrastructure Plan* & The 2026 Moa Point Review):** As documented in the *Independent Crown Review into the Moa Point Wastewater Treatment Plant Failure* (Jaduram et al., Sept 2026), deferring preventative maintenance creates an unsustainable escalation in reactive remediation costs. Ring-fencing $\Omega_{\mathrm{reinv},g} = 0.50 \, \Omega_{\mathrm{reform},g}$ into a statutory Infrastructure & Core Health Endowment prevents short-term operating budgets from raiding capital maintenance.
  4. ***New Zealand Superannuation and Retirement Income Act 2001* (Part 1 & Part 2) & *Te Tiriti o Waitangi* Jurisprudence:** Preserving universal entitlement at Age 65 (`Jr`) avoids the severe disparate impact on Māori and Pasifika life-expectancy cohorts that would result from raising the statutory age to 67 or 70, while honoring the *Te Tiriti o Waitangi* principles of active protection (*kaitiakitanga*) and equity across *mokopuna* cohorts (Waitangi Tribunal *Wai 2575 Hauora* and *Wai 2915 Oranga Tamariki* reports).

### 5.3 Cooperative Childcare Bargaining, Hyperbolic Fertility (`FertilityBargaining_Module.m`), & Why Full Quasi-Hyperbolic VFI Solvers Are Unnecessary
Following Doepke, Hannusch, Kindermann, and Tertilt (2022) and Kim (2025), couples in fertile brackets $j \in \lbrace 2, 3, 4 \rbrace$ with female/male productivity $\left(h_f, h_m\right)$ and present-bias parameter $\beta_{\mathrm{hyp}} = 0.72$ bargain cooperatively over fertility $n_f \in \lbrace 0, 1, 2, 3 \rbrace$. A birth occurs if and only if both partners achieve positive net marital surplus over their outside options:

$$\mathcal{S}_f\left(n_f; Q_k, G_{\mathrm{ECE}}, \theta_{\tau}\right) = u_f\left(c_f\left(n_f\right)\right) + \beta_{\mathrm{hyp}} \delta V_f^{\prime}\left(n_f\right) - \theta_{\tau} \psi_{\mathrm{time}} n_f + \omega_{\mathrm{ECE}} G_{\mathrm{ECE}} n_f - \psi_Q Q_k n_f \ge \underline{U}_f$$

* **Why We Evaluate $\beta_{\mathrm{hyp}} = 0.72$ Analytically in `FertilityBargaining_Module.m` Rather Than Calling VFI Toolkit's `vfoptions.exoticpreferences = 'QuasiHyperbolic'`:**
  1. *Exact Separation of Present-Biased Fertility Timing from Illiquid/Commitment Savings:* In the VFI Toolkit, enabling `vfoptions.exoticpreferences = 'QuasiHyperbolic'` (Laibson, 1997) applies quasi-hyperbolic discounting to every continuous consumption/savings choice $a^{\prime}$, requiring the solver to maintain dual value functions $\left(V_j, W_j\right)$ and solve non-concave strategic games between current and future selves—more than doubling GPU backward-induction runtime across the 60-year transition loop. In New Zealand's institutional setting, compulsory KiwiSaver/Superannuation and illiquid mortgage amortization commitment devices anchor long-run lifecycle asset accumulation ($a^{\prime}$), whereas present bias ($\beta_{\mathrm{hyp}} = 0.72$) binds acutely on the **discrete, postponable fertility decision $n_f$** during ages 20–39 (Kim, 2025), where immediate metropolitan rent ($-\psi_Q Q_k n_f$) and unshared maternal childcare costs ($-\theta_{\tau} \psi_{\mathrm{time}} n_f$) are paid upfront while dynastic continuation rewards ($V_f^{\prime}\left(n_f\right)$) accrue decades later.
  2. *Mathematical Equivalence at the Fertility Node:* Because the continuation value function $V_f^{\prime}\left(n_f\right)$ after the fertility window is governed by standard exponential discounting $\delta = \beta_{hh}\left(\Delta t\right)$, evaluating $u_f + \beta_{\mathrm{hyp}} \delta V_f^{\prime}\left(n_f\right)$ directly inside `FertilityBargaining_Module.m` yields the **exact naive/commitment quasi-hyperbolic fertility choice rule** at zero additional VFI computational cost.
  3. *Preserving Clean Identification of the $i_c = 0$ Credit/Luxury Corner:* Keeping the household VFI solver time-consistent ensures that baseline early-childhood underinvestment ($i_c = 0$) is identified purely from intergenerational borrowing constraints ($a^{\prime} \ge 0$) and Stone-Geary luxury thresholds ($\bar{g}_{\mathrm{ECE}} > 0$; Ferriere et al., 2025), rather than attributing child poverty corners to parental myopia or lack of self-control.

### 5.4 Endogenous NZ Superannuation Solvency & The Fiscal Substitution Leak of Raising the Eligibility Age ($J_r \to 67\text{ or }70$)
Let $\mathcal{D}_{65+,t}$ denote the national old-age dependency ratio of retirees ($j \ge J_r$, age 65+) to effective working-age taxpayers ($1 \le j < J_r$, ages 20–64) across the four domestic regions:

$$\mathcal{D}_{65+,t} = \frac{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=J_r}^{J} \int d\mu_{k,t}\left(a, h, z, j\right)}{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=1}^{J_r - 1} \int d\mu_{k,t}\left(a, h, z, j\right)}$$

In a pay-as-you-go universal pension system with replacement benefit $p_{\mathrm{super}}$ and consumption-floor top-up $\underline{c}$, the required working-age labor tax rate $\tau_{l,t}^{\mathrm{req}}$ needed to maintain New Zealand Superannuation solvency is inversely proportional to average working-age human capital $\bar{H}_t = \sum_k \omega_{HH,k,t} \int_{j < J_r} w_{k,t} z h \ell_{\mathrm{eff}} \, d\mu_{k,t}$ and directly proportional to $\mathcal{D}_{65+,t}$:

$$\tau_{l,t}^{\mathrm{req}}\left(J_r\right) = \tau_{l,\mathrm{non-super}} + \frac{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=J_r}^{J} \int \left\lbrack p_{\mathrm{super}} + \underline{c}_{\mathrm{health}}\left(a, h, j\right) \right\rbrack d\mu_{k,t}}{\bar{H}_t}$$

When evaluating conventional austerity proposals that raise the statutory retirement age from $A_r = 65$ to $A_r^{\prime} \in \lbrace 67, 70 \rbrace$ while leaving baseline child stunting ($\mathrm{Frac}_{\mathrm{stunted}} = 0.22$), fertility ($\mathrm{TFR} = 1.66$), and youth emigration ($\mathrm{Emig}_{\mathrm{Nat}} = 10.93\%$) unaddressed, `Plot_Fertility_SuperSolvency_2Panel.m` accounts for the **endogenous fiscal substitution leak** $\lambda_{\mathrm{leak}}\left(A_r^{\prime}\right) \in \left\lbrack 0.38, 0.45 \right\rbrack$. Because manual and lower-tier workers ($h \in \lbrace h_1, h_2, h_3 \rbrace$) experience cumulative Ben-Porath physical skill depreciation $\delta_{hc} = 0.087$ and elevated unemployment shocks ($i_z \in \lbrace 1, 2 \rbrace$) in their late sixties, withholding universal superannuation over ages $\left\lbrack 65, A_r^{\prime} \right)$ shifts a fraction $\lambda_{\mathrm{leak}}\left(A_r^{\prime}\right)$ of gross pension savings directly into means-tested Supported Living, Jobseeker, Accommodation Supplement, and acute hospital outlays:

$$\Delta \mathrm{NetSavings}_{t}\left(A_r^{\prime}\right) = \left\lbrack 1 - \lambda_{\mathrm{leak}}\left(A_r^{\prime}\right) \right\rbrack \sum_{k=1}^{4} \omega_{HH,k,t} \int_{65 \le \mathrm{age}\left(j\right) < A_r^{\prime}} p_{\mathrm{super}} \, d\mu_{k,t}^{\mathrm{SS0}}$$

Consequently, raising the pension age to 67 or 70 under status-quo demographics still leaves the required PAYE tax rate climbing to $26.85\%$ (Age 67) or $25.55\%$ (Age 70) while imposing a regressive survival-weighted utility loss $\Delta V_k\left(a, h, z, j\right) < 0$ on Māori, Pasifika, and rural manual cohorts with lower conditional survival probabilities $s_j$. Conversely, expanding the denominator $\bar{H}_t$ via First-2000-Days wraparound investment ($G_{\mathrm{ECE},1}$), Montessori / *Tuakana–Teina* adolescent mentoring ($G_{\mathrm{ECE},2}$), youth retention ($\Pi_{\mathrm{mig}}$), and cooperative fertility recovery ($\mathrm{TFR}: 1.66 \to 1.98$) keeps $A_r = 65$ intact while bending $\tau_{l,t}^{\mathrm{req}}$ down from $28.22\%$ to $24.45\%\text{--}24.90\%$.

### 5.5 Joint Income-Wealth Distributional Incidence across 12 Earn + Own Tiers (`Plot_WealthBracket_PainAndCelebration.m`)
To evaluate welfare incidence across the empirical joint distribution of gross household income $Y_m$ and net worth $W_m$ (`Annual Income + Net Worth`, spanning $M_{\mathrm{tier}} = 12$ tiers from `Tier 1: NZD 50k + 0` at P10 to `Tier 12: NZD 10M + 250M` at P99.99, anchored to Stats NZ Household Net Worth 2022/2025, Rashbrooke 2021, and the IRD High-Wealth Individuals Research Project 2023), `Plot_WealthBracket_PainAndCelebration.m` decomposes the Consumption-Equivalent welfare change $\Delta \mathrm{CE}_m\left(\omega_{\mathrm{ent}}\right)$ as a function of the household's operating-enterprise equity share $\omega_{\mathrm{ent}} \in \lbrack 0, 1\rbrack$ (where $\omega_{\mathrm{ent}} = 0.80$ for **Active Growth Entrepreneurs** $z_f = z_{h,k}$ and $\omega_{\mathrm{ent}} = 0.15$ for **Passive Residential Land Hoarders** $z_f = z_{\ell,k}$):

$$\Delta \mathrm{CE}_m\left(\omega_{\mathrm{ent}}\right) = \underbrace{\left(\Delta \mathrm{CE}_{m,\mathrm{House}} + \Delta \mathrm{CE}_{m,\mathrm{WealthTax}} + \Delta \mathrm{CE}_{m,\mathrm{Estate}}\right)}_{\text{3 Pain Channels }\left(\le 0\right)} + \underbrace{\left(\Delta \mathrm{CE}_{m,\mathrm{ECE+Rent}} + \Delta \mathrm{CE}_{m,\mathrm{PAYE}} + \omega_{\mathrm{ent}} \Delta \mathrm{CE}_{m,\mathrm{Firm}} + \Delta \mathrm{CE}_{m,\mathrm{Cohesion}}\right)}_{\text{4 Gain Channels }\left(> 0\right)}$$

Because Guvenen et al. (2023) capital reallocation raises the after-tax return on high-productivity operating equity $\Delta R_k\left(z_{h,k}\right) > 0$ while the `-3.5 pp` `SS2` PAYE cut and `-60 bps` interest rate reduction boost disposable cash flow, **Active Growth Entrepreneurs remain net welfare positive ($\Delta \mathrm{CE}_m\left(0.80\right) > 0$) up to `Tier 11: NZD 5M + 100M` (`+0.2%` CE)**. Even on a portfolio-average basis across all top-1% wealth holders (`Tiers 8–12`), post-reform retained net worth equals **89.4% to 94.2%** of baseline fortune—representing a smaller balance-sheet adjustment than routine once-a-decade macroeconomic drawdowns (1987 equities `-60%`, 2008 GFC equities `-40%` / real house prices `-12%`, and the 2021–2024 RBNZ monetary tightening cycle where real Auckland/Wellington house prices fell `-22% to -27%`).

---

## 6. Calibration, SMM Identification (`Calibrate_NZ_Moments.m`), & Cross-Country Validation

### 6.1 Exact SMM Parameter Identification Matrix (15 Parameters $\leftrightarrow$ 15 NZ Empirical Moments)

| Parameter | Symbol | Value | Empirical Target Moment & Source | Model Fit |
| :--- | :---: | :---: | :--- | :---: |
| Stage-1 CES Substitution | $\varphi_1$ | `0.350` | Cunha, Heckman, & Schennach (2010): Stage-1 elasticity $\sigma_1 = 1/(1-\varphi_1) = 1.54$ | Exact |
| Stage-2 CES Complementarity | $\varphi_2$ | `-0.950` | Cunha et al. (2010): Stage-2 complementarity $\sigma_2 = 1/(1-\varphi_2) = 0.51$ | Exact |
| Parental Skill Persistence | $\rho_{hc}$ | `0.420` | Lee & Seshadri (2019) / NZ IDI baseline Intergenerational Elasticity $\mathrm{IGE} = 0.350$ | `0.350` |
| ECE Stone-Geary Threshold | $\bar{g}_{\mathrm{ECE}}$ | `0.032` | Barnardos / GUiNZ share of births in material hardship / $i_c=0$ corner (25.8%) | `25.79%` |
| Montessori / *Tuakana* Boost | $\Delta_{\mathrm{Tuakana}}$ | `0.110` | Graeme Dingle Foundation (*Stars* / *Project K*) & *Kura* NCEA Level 3 lift (+11 log pts) | `+0.110` |
| Dunedin Acute Cost Weight | $c_{\mathrm{acute}}$ | `0.380` | Caspi et al. (2016) Dunedin Study: 22% stunted tier drives 57%–81% of Exits 1, 2, 4 | `74.1%` |
| Rural Transport Subsistence | $\bar{e}_{\mathrm{Rural}}$ | `0.048` | Stats NZ HES rural vs. metro mandatory fuel/transport budget share (2.75x) | `2.74x` |
| Auckland Land Supply Factor | $Q_{\mathrm{Akl},\mathrm{SS0}}$ | `3.100` | Demographia / Stats NZ Auckland house price-to-income ratio vs. Rural (2.95x) | `2.95x` |
| Renter Down-Payment Cutoff | $\xi_k$ | `0.200` | RBNZ LVR 20% deposit rule; Auckland young adult homeownership rate (28.0%) | `28.0%` |
| Firm Collateral Multiplier | $\lambda_{\mathrm{col}}$ | `2.500` | Guvenen et al. (2023) / RBNZ SME business credit-to-equity ratio | `2.50` |
| Warm-Glow Bequest Scale | $b_1$ | `12.50` | NZ 20-year intergenerational property estate transfer wave (NZD 1.6T) | `NZD 1.6T` |
| Warm-Glow Bequest Threshold | $b_2$ | `2.800` | De Nardi (2004) / Stats NZ top-30% estate skewness | `70th pct` |
| Gumbel Migration Scale | $\varrho_{\mathrm{mig}}$ | `0.180` | OECD / Stats NZ age 20–35 skilled trans-Tasman emigration rate (19.3% Akl / 10.9% Nat.) | `10.93%` |
| Present-Bias Fertility | $\beta_{\mathrm{hyp}}$ | `0.720` | Kim (2025) / Stats NZ baseline national Total Fertility Rate ($\mathrm{TFR} = 1.66$) | `1.66` |
| Female Childcare Share | $\theta_{\tau}$ | `0.680` | Doepke et al. (2022) / Stats NZ Time Use Survey maternal share of childcare | `68.0%` |

---

### 6.2 Two-Stage Sobol + Nelder-Mead SMM Optimization & Welfare-Based In-Kind Imputation (`Calibrate_NZ_Moments.m`)

To discipline the structural parameter vector $\theta$ against the 15 empirical New Zealand moments in Table 6.1 without getting trapped in local minima on the multi-region general-equilibrium surface, `Calibrate_NZ_Moments.m` executes a two-stage Simulated Method of Moments (SMM) procedure:

1. **Stage 1 — Sobol Quasi-Random Global Hypercube Pre-Screening:**
   Following Daruich (2018, Appendix C, Fig. C1), we draw $N_{\mathrm{sobol}}$ low-discrepancy Sobol sequence points across the bounded parameter hypercube $\left\lbrack \underline{\theta}, \, \overline{\theta} \right\rbrack$ and evaluate the weighted percentage-squared SMM objective function:

$$\mathcal{L}_{\mathrm{SMM}}\left(\theta\right) = \sum_{m=1}^{M} W_m \left( \frac{\hat{\mathcal{M}}_m\left(\theta\right) - \mathcal{M}_m^{\mathrm{data}}}{\max\left(0.02, \, \left\vert \mathcal{M}_m^{\mathrm{data}} \right\vert\right)} \right)^{2}$$

2. **Stage 2 — Bound-Constrained Local Nelder-Mead / Quasi-Newton Refinement:**
   Starting from the best Sobol candidate $\theta_{\mathrm{sobol}}^{*}$, we apply a logistic sigmoid transformation $\theta\left(\mathbf{x}\right) = \underline{\theta} + \left(\overline{\theta} - \underline{\theta}\right) \oslash \left(\mathbf{1} + \exp\left(-\mathbf{x}\right)\right)$ and refine $\mathbf{x}^{*}$ to convergence via `fminsearch`.
3. **Dual Empirical Calibration Anchor Switch (`'Dunedin_22'` vs. `'MetroSqueeze_GUiNZ'`):**
   In `Plot_ChildFates_2Panel_SSankey.m`, `Plot_ChildFiscal_2Panel_SSankey.m`, and `Plot_ActuarialContinuationValuation.m`, the parameter `Params.Calibration_Anchor` toggles between two empirically validated New Zealand hardship anchors:
   * **`'Dunedin_22'` (Default Conservative Anchor):** Calibrates the baseline stunted launch tier ($h_1\text{--}h_2$) to the **22.0%** high-cost cohort segment identified at age 3 in the Dunedin Multidisciplinary Health and Development Study (Caspi et al., 2016, where 22% of the cohort drives 57%–81% of adult Exits 1, 2, and 4; model fit = **74.1%**), using housing-crowding penalty $\psi_{\mathrm{crowd}} = 0.14$ and grid anchor $+0.265$.
   * **`'MetroSqueeze_GUiNZ'` (After-Housing-Cost Metropolitan Squeeze Sensitivity):** Incorporates the full metropolitan housing-cost and dampness/crowding penalty documented in *Growing Up in New Zealand* (Morton et al., 2020: 37% damp/mould exposure) and Child Poverty Related Indicators (29.9% AHC60 child poverty; 34%–37% of children in households spending $>30\%$ of income on housing), using $\psi_{\mathrm{crowd}} = 0.18$ and grid anchor $+0.105$ (expanding Auckland's baseline vulnerable trajectory to 34.0%–36.6%).
4. **Welfare-Based In-Kind ECE Imputation Weights ($\omega_i$, Ferriere et al., 2025, Eq. 3):**
   Because early childhood education and preventative health exhibit a Stone-Geary luxury threshold ($\bar{g}_{\mathrm{ECE}} = 0.032 > 0$, macro income elasticity $\theta \in \left\lbrack 1.15, 1.38 \right\rbrack > 1$), liquidity-constrained parents at the private corner solution ($i_c = 0$, share $S = \Pr\left(i_c = 0\right) \approx 0.258$) have a high marginal utility of liquid cash ($\partial u_i / \partial y_i$) to cover immediate rent ($Q_k$) and transport ($\bar{e}_k$). Standard static benefit-incidence studies that value public in-kind spending $G_{\mathrm{ECE}}$ at 1-for-1 cash equivalence overstate static redistributive compression by up to 50%. `Calibrate_NZ_Moments.m` computes Ferriere et al.'s exact marginal-rate-of-substitution imputation weight across income quintiles:

$$\omega_i = \frac{\partial u_i / \partial G_{\mathrm{ECE}}}{\partial u_i / \partial y_i} = \min\left\lbrace \frac{y_i / \bar{y}}{F^{-1}\left(S\right)}, \, 1 \right\rbrace$$

   Even after strictly discounting direct static utility for cash-poor households ($\omega_i < 1$ in $Q_1\text{--}Q_2$), universal wraparound provision $G_{\mathrm{ECE}}$ generates large net positive Consumption-Equivalent welfare gains ($\mathrm{CE}\% > 0$) through two dynamic general-equilibrium channels omitted by static incidence studies: (i) the concave pro-equality societal externality $X_t$ and fiscal cost avoidance across Exits 1, 2, and 4, and (ii) the intergenerational human-capital transition operator $\mathbf{Q}_h$.

---

### 6.3 Cross-Country Macro-Calibration Validation Benchmarks & The Deming-to-Tokyo Coda

To verify that our simulated 40-to-60-year multiphase transition magnitudes (`SS0 -> SS1 -> SS2`: +8.13% to +15.44% CE in `SS1`, +14.28% to +26.03% CE in `SS2`, -33.4% IGE reduction, and 6.86x cumulative 60-year GDP multiplier) are structurally consistent with international evidence, we benchmark the model's core elasticities against six historical and contemporary empirical episodes:

* **Nordic Dual-Dividend Calibration (Sweden & Finland, 1970–2020):**
  In De Nardi's (2004, *Review of Economic Studies*, Table 1) quantitative OLG calibration of Sweden versus the United States, universal early human-capital investment and social insurance compress the variance of idiosyncratic earnings shocks $\sigma_y^2$ by **52%** (from $0.30$ in the US to $0.1429$ in Sweden) and intergenerational shock variance $\sigma_{yh}^2$ by **52%** (from $0.37$ to $0.1762$). Paired with Doepke et al. (2022, NBER w29948, Fig. 2)—showing that public ECE spending of 1.6%–2.0% of GDP in Sweden and Finland lifts prime-age female employment above 80% while sustaining fertility—and Finland's 1993 dual capital/labor tax reform (Piketty & Saez, 2013), this directly validates our simulated compression of the stunted tier ($h_1\text{--}h_2$: 22.0% down to 1.5%) and -33.4% IGE reduction.
* **Pro-Enterprise Tax Reallocation + Universal Early Skill Compression (Estonia 1994–2025, Post-War Japan 1946–1985, New Deal US 1935–1980, & Viet Nam 1990–2025):**
  Estonia's 2000 corporate tax reform (0% tax on reinvested enterprise capital paired with a pure Land Value Tax) combined with universal subsidized kindergartens and 18-month parental leave propelled a 1.37-million-person economy to #1 in Europe in OECD PISA assessments while minimizing socio-economic skill stunting—matching our Guvenen et al. (2023) firm reallocation ($\tau_k \downarrow, \tau_a \uparrow \Rightarrow \Gamma_k \to z_{h,k}$) and Lens-1 skill compression. Similarly, post-1945 Japan's estate/land de-concentration and universal *Boshi Kenko Techo* First-2000-Days maternal/infant health screening (Moriguchi & Saez, 2008; Barro & Lee, 2013), the 1910–1980 US progressive estate tax consensus ($\tau_b$) funding the GI Bill youth endowment ($E$), and Viet Nam's post-*Đổi Mới* front-loaded nutrition/schooling miracle (cutting child stunting from $>50\%$ to $<19\%$) confirm the long-horizon TFP and mobility multipliers in `T1`.
* **Youth Brain-Drain Reversal, Anti-Speculation Housing Rules, & Fiscal Self-Financing (Ireland, Singapore, Norway, & Quebec):**
  Ireland's post-1967 combination of universal secondary/technical education and pro-enterprise taxation reversed 150 years of 20–35 youth emigration into net high-skill return migration (validating $\Pi_{\mathrm{mig}}$ in Section 4.3); Singapore's pairing of universal Child Development Accounts (CDAs) and Edusave grants ($E$) with Additional Buyer's Stamp Duties (ABSD) curbed primate-city land crowd-out; and Baker, Gruber, and Milligan (2008, *JPE*) prove that Quebec's 1997 universal low-cost childcare reform raised maternal employment by +7 to +8 percentage points and generated $>100\%$ fiscal self-financing via additional income and consumption taxes.
* **The East Asian Primate-City Land Squeeze Warning (21st-Century South Korea & Post-1990 Bubble Japan):**
  Doepke et al. (2022, Sec. 4) and Hirano and Toda (2025, *JPE Macroeconomics*) demonstrate that when high schooling investment is not paired with metropolitan land-value cooling ($Q_k \downarrow$) and universal in-kind ECE ($G_{\mathrm{ECE}}$), primate-city housing speculation (Seoul and late-1980s Tokyo) and private tutoring arms races (*Hagwon*, an extreme luxury-good corner) crush young-family bargaining surplus, driving South Korea's TFR down to 0.72–0.75—validating why Lens 1 must be coupled with Lens 2 and Lens 3 in Auckland ($Q_{\mathrm{Auckland}} = 3.10$).
* **The Scottish Devolution Natural Experiment (2017–2026) — Empirical Identification of $\Delta G_{\mathrm{ECE}} + T_k$ Under $\Delta \tau_l > 0$ vs. $\Delta \tau_a, \Delta \tau_b > 0$:**
  Scotland's 2017–2026 policy sequence provides an out-of-sample quasi-experimental test of a **Lens-1-only reform financed via $\tau_l$**:
  1. Scaling targeted child transfers (*Scottish Child Payment* + *Best Start*, analogous to $\Delta T_k$) and doubling universal in-kind early childhood provision (from 600 to 1,140 hours/yr, analogous to $\Delta G_{\mathrm{ECE},1}: 0.045 \to 0.110$) alongside school-based adolescent mentoring (*MCR Pathways* / *The Promise*, analogous to Gate 3 $\mathcal{M}_{\mathrm{Tuakana}}$) reduced relative child poverty After Housing Costs by **6.0 percentage points relative to the rest of the UK** (21.0% vs. 27.0%+) with zero statistically significant maternal labor supply reduction ($\Delta \ell_f \approx 0$).
  2. However, because devolved fiscal constraints precluded taxing land overvaluation ($\tau_a$) or intergenerational estates ($\tau_b$) and forced reliance on higher top working-age PAYE rates ($\tau_l: 42\%\text{--}48\%$), metropolitan housing user costs $r_{h,k}^{\mathrm{rent}}$ remained elevated and progress plateaued 3 percentage points above the 18% interim statutory target—confirming our general-equilibrium result that **Lens 1 human-capital investments must be coupled with Lens 2/3 land-value cooling ($Q_k \downarrow$) and pro-enterprise capital reallocation ($\Gamma_k \to z_{h,k}$)** to achieve the full 2050 hardship compression (from 22.0% to 1.5%) and unlock working-age PAYE tax relief ($\Delta \tau_l = -0.035$ in `SS2`).
* **Coda Formalization — From Deming's *System of Profound Knowledge* (1950) to Hirano & Toda's (2025) *Land Bubble Necessity Theorem*:**
  Post-war Japan's trajectory from W. Edwards Deming's 1947 Census mission and August 1950 Mt. Hakone JUSE lecture (*Out of the Crisis*, 1986; *The New Economics*, 1993; Tiemann, 2023) to the 1989 Tokyo land bubble provides the structural proof of why **Lens 1 + Lens 2 must be closed by Lens 3**. In Hirano and Toda's (2025) two-sector OLG model with inelastic urban land supply ($\delta_{H,\mathrm{Metro}} \to 0$), when Deming-style human and organizational capability compounding drives tradable manufacturing/knowledge TFP growth $G_k = 1 + g_{Z,k}$ above the equilibrium gross interest rate $R\left(\tau_a = 0\right)$ on unleveraged savings, the fundamental present value of land rents diverges and a rational land price bubble $B_{\mathrm{land},k,t} > 0$ becomes mathematically necessary in equilibrium:

$$Q_{k,t} = \sum_{s=1}^{\infty} \left(\frac{G_k}{R\left(\tau_a\right)}\right)^{s} d_{\mathrm{land},k,t} + B_{\mathrm{land},k,t} \;\xrightarrow{\; G_k \ge R\left(0\right) \;}\; \text{Land Overvaluation Bubble } \left(B_{\mathrm{land},k,t} > 0\right)$$

  Introducing the book-value land/wealth levy $\tau_a = 0.015$, the estate levy $\tau_b = 0.25$ on passive property accumulations, and the 2050 50/50 Debt-Sinking and Infrastructure Protocol ($\Omega_{\mathrm{debt}}, \Omega_{\mathrm{infra}}$) raises the effective discount factor on passive land holding to $R_{\mathrm{eff}}\left(\tau_a\right) = \left(1 + r\right) / \left(1 - \tau_a\right) > G_k$, **eliminating the rational land bubble condition ($B_{\mathrm{land},k,t} \equiv 0$) while channeling Deming-style human and enterprise surpluses into permanent productive capital and intergenerational endowments**.

---

## 7. Multiphase Transition Path, Actuarial Continuation Valuation, Credibility Blending, & Web SVG Architecture

### 7.1 Exact Multiphase Parameter Vector (`SS0 -> SS1 -> SS2` in `WelfareDecomposition_4Region.m`)

| Parameter Field | Symbol | `SS0` (Status Quo) | `SS1` (Incubation & Reallocation) | `SS2` (2050 Actuarial & PAYE Harvest) | Structural Role in `ReturnFn_SpatialHH_Compact4D` & `Build_IntergenTransitionMatrix` |
| :--- | :---: | :---: | :---: | :---: | :--- |
| `G_ece` / `G_ece_stage1` | $G_{\mathrm{ECE},1}$ | `0.045` | `0.110` | `0.130` | Universal First-2000-Days in-kind wraparound input; eliminates $i_c = 0$ corners |
| `G_ece_stage2` | $G_{\mathrm{ECE},2}$ | `0.045` | `0.085` | `0.105` | Universal Stage-2 Montessori / *Tuakana–Teina* & Graeme Dingle mentoring ($J = 5$) |
| `YouthGrant` | $E$ | `0.030` | `0.065` | `0.080` | Age-20 ($j = 1$) universal capital endowment relaxing young-adult deposit constraint |
| `tau_l` (`tau_l_delta`) | $\tau_l$ ($\Delta \tau_l$) | `0.220` (`0.000`) | `0.220` (`0.000`) | `0.185` (`-0.035`) | Working-age PAYE labor tax rate (-3.5 pp cut in `SS2` from Actuarial & NZ Super dividend) |
| `tau_b` | $\tau_b$ | `0.150` | `0.180`–`0.250` | `0.180` | Estate/bequest levy on the NZD 1.6T intergenerational property transfer wave |
| `r_delta` | $\Delta r$ | `0.000` | `-0.004` | `-0.006` | Reduction in domestic real interest rate from 50% Sovereign Debt-Sinking Fund |
| `w_mult_vs_SS0` | $w_k / w_{k,\mathrm{SS0}}$ | `[1, 1, 1, 1]` | `[1.032, 1.038, 1.048, 1.055]` | `[1.068, 1.075, 1.088, 1.096]` | Guvenen firm reallocation TFP lift (`SS1`) + 1.65x public infrastructure reinvestment (`SS2`) |
| `Q_mult_vs_SS0` | $Q_k / Q_{k,\mathrm{SS0}}$ | `[1, 1, 1, 1]` | `[0.990, 0.975, 0.950, 0.925]` | `[0.985, 0.955, 0.925, 0.895]` | Cooling of regional housing price-to-income ratios (-7.5% `SS1` to -10.5% `SS2` in Auckland) |
| `Frac_stunted` | $\mathrm{Frac}_{\mathrm{stunted}}$ | `0.220` | `0.045` | `0.015` | Compression of $h_1\text{--}h_2$ stunted cohort share (lifting relational utility $u_{\mathrm{rel}}$) |
| `Transfer_Geo` | $T_k$ | `[0.025, 0.020, 0.016, 0.014]` | `[0.038, 0.031, 0.025, 0.028]` | `[0.044, 0.037, 0.031, 0.033]` | Labrousse-Perdereau Income $\times$ Geography transfer schedule across 4 regions |

### 7.2 Post-Hoc Transition Integrals & Actuarial Continuation Valuation Operators (`Plot_CumulativeTransitionPayoffs.m` & `Plot_ActuarialContinuationValuation.m`)
At each transition period $t = 1, \dots, T_{\mathrm{trans}}$ ($\Delta t \in \lbrace 5, 3, 2 \rbrace$ years spanning 60 years), `Plot_CumulativeTransitionPayoffs.m` integrates four regional and national annual flow series from `StationaryDist_t` ($\mu_{k,t}$) and $\Gamma_{k,t}$:

$$\mathcal{I}_{k,t} = \Lambda_{\mathrm{NZD}} \, \omega_{HH,k,t} \left\lbrack \int_{j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}} \left(\Delta G_{\mathrm{ECE},k} + s_{\mathrm{sub}} i_{c,t}\right) d\mu_{k,t} + \int_{j=1} E \, d\mu_{1,k,t} \right\rbrack$$

$$\mathcal{S}_{k,t} = \max\left(0, \, \mathcal{B}_{k,\mathrm{SS0}}^{\mathrm{acute}} - \Lambda_{\mathrm{NZD}} \, \omega_{HH,k,t} \left\lbrack c_{\mathrm{acute,Dunedin}} \sum_{j=1}^{J_r - 1} \sum_{i_h=1}^{2} \int_{a,z} d\mu_{k,t}\left(a, h_{i_h}, z, j\right) + \int T_{k,t} d\mu_{k,t} \right\rbrack \right)$$

$$\Delta Y_{k,t} = \max\left(0, \, \Lambda_{\mathrm{NZD}} \left\lbrack Z_{k,t}\left(\Gamma_{k,t}\right) K_{k,t}^{\alpha_k} H_{k,t}^{1 - \alpha_k} - Y_{k,\mathrm{SS0}} \right\rbrack \right), \qquad \mathcal{F}_{k,t}^{\mathrm{tot}} = \mathcal{S}_{k,t} + \Delta \mathcal{T}_{k,t}$$

To align transition reporting with New Zealand's Accident Compensation Corporation (ACC) forward liability valuation and New Zealand Treasury Circular 2024/15 Cost-Benefit Analysis (CBAx) incidence accounting, `Plot_ActuarialContinuationValuation.m` projects each region's annual flows onto a 1-year `pchip` grid $y \in \lbrace 0, 1, \dots, 100 \rbrace$ and evaluates the rolling $H = 25$-year **Conditional Continuation Valuation Operator**:

$$\mathcal{V}_{k,t_0}^{\left(L\right)}\left(H; r_{\mathrm{disc}}, \mathcal{A}\right) = \mathcal{C}_{k,\mathrm{realized}}^{\left(L\right)}\left(t_0; \mathcal{A}\right) + \left(1 - \alpha_{\mathrm{attr}}\right) \Phi_{\mathrm{pipe}}\left(t_0\right) \sum_{s=1}^{H} \left(\frac{1 + g_{\mathrm{cost}}}{1 + r_{\mathrm{disc}}}\right)^{s} \left(\psi_{k,0}\right)^{s} f_{k, t_0 + s}^{\left(L\right)}\left(\mathcal{A}\right)$$

with dual Treasury discount rates $r_{\mathrm{disc}} \in \lbrace 0.020, 0.080 \rbrace$, real cost-base growth $g_{\mathrm{cost}} = 0.015$, attribution haircut $\alpha_{\mathrm{attr}} = 0.30$, pipeline maturity $\Phi_{\mathrm{pipe}}\left(t_0\right) = \min\left(1, t_0 / 15\right)$, and regional Markov skill retention $\left\lbrack \psi_{\mathrm{Rural},0}, \psi_{\mathrm{Small},0}, \psi_{\mathrm{Large},0}, \psi_{\mathrm{Auckland},0} \right\rbrack = \left\lbrack 0.984, 0.984, 0.986, 0.987 \right\rbrack$.

### 7.3 Multiphase Policy Announcements, Credibility-Weighted Belief Blending, and Logistic Seam Smoothing (`TransPath_4Region_Master.m`)
At each transition period $t \in \lbrace 1, \dots, T_1 - 1 \rbrace$ prior to the Phase-2 (`SS2`) enactment date $T_1$ (Year 25), households and firms evaluate the **credibility-blended continuation value** $\tilde{V}_{k,t+1}$ inside the backward-induction Bellman operator:

$$V_{k,t}\left(a, h, z, j\right) = \max_{d_t \in \mathcal{D}} \left\lbrace u_k\left(d_t, a, h, z, j; \mathcal{\Phi}\left(t\right)\right) + s_j \beta_{hh} \, \mathbb{E}_{z^{\prime} \vert z} \left\lbrack \tilde{V}_{k,t+1}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right) \right\rbrack + \left(1 - s_j\right) u_{\mathrm{beq}}\left(a^{\prime}; \tau_b\left(t\right)\right) \right\rbrace$$

$$\tilde{V}_{k,t+1}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right) = \left(1 - \lambda_{\mathrm{cred}}\left(t\right)\right) V_{k,t+1}^{\mathrm{perm\,SS1}}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right) + \lambda_{\mathrm{cred}}\left(t\right) V_{k,t+1}^{\mathrm{full\,SS2}}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right)$$

Under endogenous actuarial credibility updating, $\lambda_{\mathrm{cred}}^{\mathrm{actuarial}}\left(t\right)$ updates as a function of the audited ratio of recognised actuarial fiscal return $\mathcal{V}_{\mathrm{National},t}^{\left(\mathrm{Fiscal}\right)}\left(H; r_{2\%}\right)$ to cumulative investment outlay $\mathcal{C}_{\mathrm{National},\mathrm{realized}}^{\left(\mathrm{Inv}\right)}\left(t\right)$:

$$\lambda_{\mathrm{cred}}^{\mathrm{actuarial}}\left(t\right) = \min\left\lbrace 1, \, \bar{\lambda}_0 + \left(1 - \bar{\lambda}_0\right) \max\left(0, \, \frac{\mathcal{V}_{\mathrm{National},t}^{\left(\mathrm{Fiscal}\right)}\left(H; r_{2\%}\right) / \mathcal{C}_{\mathrm{National},\mathrm{realized}}^{\left(\mathrm{Inv}\right)}\left(t\right) - 1}{\bar{\chi}_{\mathrm{target}} - 1}\right) \right\rbrace$$

where $\bar{\chi}_{\mathrm{target}} = 3.50$. Because the Year 5 Parliamentary Audit ($t = 1$) already achieves an actuarial coverage multiple of $35.25 / 9.19 = 3.84 > \bar{\chi}_{\mathrm{target}}$, publishing the ACC-style actuarial audit at Year 5 drives $\lambda_{\mathrm{cred}}^{\mathrm{actuarial}}\left(t\right) \to 1$. Finally, to prevent step-function tax arbitrage at seam $T_1$, continuous policy levers follow a logistic phase-in ramp:

$$\mathcal{\Phi}\left(t\right) = \mathcal{\Phi}_1 + \frac{\mathcal{\Phi}_2 - \mathcal{\Phi}_1}{1 + \exp\left(-\xi_{\mathrm{ramp}}\left(t - T_1\right)\right)}$$

### 7.4 Seven-Factor Additive Welfare Attribution & The Sovereign Debt-Service Channel (`Plot_SS2_7Factor_StackedAttribution.m`)
To decompose the multiphase Consumption-Equivalent welfare trajectory $\mathrm{CE}_{k,t}^{\mathrm{tot}}$ (`T1` rows `SS1_1..3` and `SS2_1..3`) into its underlying economic mechanisms across cohort entry years $c \in \left\lbrack -10, +60 \right\rbrack$ and regions $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland}, \mathrm{National} \rbrace$, `Plot_SS2_7Factor_StackedAttribution.m` partitions $\mathrm{CE}_{k,t}^{\mathrm{tot}}$ into $M_{\mathrm{attr}} = 7$ additive structural components:

$$\mathrm{CE}_{k}^{\mathrm{SS2}} = \sum_{m=1}^{7} \Delta \mathrm{CE}_{k,m}^{\mathrm{SS2}} = \Delta \mathrm{CE}_{k,\mathrm{DWL}} + \Delta \mathrm{CE}_{k,\mathrm{House}} + \Delta \mathrm{CE}_{k,\mathrm{Firm}} + \Delta \mathrm{CE}_{k,\mathrm{Debt}} + \Delta \mathrm{CE}_{k,\mathrm{Cohes}} + \Delta \mathrm{CE}_{k,\mathrm{Demog}} + \Delta \mathrm{CE}_{k,\mathrm{Skill}}$$

In particular, **Component 4 ($\Delta \mathrm{CE}_{k,\mathrm{Debt}}$: Sovereign Debt-Sinking & Reduced Debt-Service Interest)** isolates the general-equilibrium welfare gain generated by the 50% Sovereign Debt-Sinking allocation $\Omega_{\mathrm{debt},t} = 0.50 \, \Omega_{\mathrm{reform},t}$ after Cash Breakeven ($t \ge 18.8$ years):
1. **Intertemporal Crown Budget Debt-Service Relief (Ferriere et al., 2025, Sec. 4.2):**
   Retiring sovereign debt stock $B_{\mathrm{gov},t}$ by $\Delta D_{2050}$ reduces annual deadweight interest service $r_t B_{\mathrm{gov},t}$, creating permanent fiscal space $\Delta \tau_{\mathrm{debt}} = r_{\mathrm{bond}} \Delta D_{2050} / \bar{Y}_t$.
2. **Bond-Market Crowding-In & Mortgage Spread Compression (Kiyotaki et al., 2024, Eq. 29 & Fig. 9):**
   In the national asset market clearing condition:

$$\sum_{k=1}^{4} \omega_{F,k} \int \left(k_k\left(a_f, z_f\right) - a_f\right) d\Gamma_{k,t} + B_{\mathrm{gov},t} = \sum_{k=1}^{4} \omega_{HH,k,t} \int a_{\mathrm{fin}} \, d\mu_{k,t} + B_{t}^{*}$$

   reducing $B_{\mathrm{gov},t}$ lowers the equilibrium domestic real interest rate by $\Delta r = -0.006$ (-60 bps in `SS2`), which simultaneously expands collateralized firm capital demand $k_k = \lambda_{\mathrm{col}} a_f$ and reduces the mortgage user cost $r_{h,k}^{\mathrm{own}}$ for leveraged young homeowners, contributing **+0.90% (`Rural`) to +1.55% (`Auckland`) and +1.25% (`National`, 6.1% of the total `SS2` prize)** in permanent Consumption-Equivalent welfare.

### 7.5 Zero-Dependency Interactive HTML5 + SVG Sankey Serialization & Cosine-S-Curve Ribbon Geometry (`exportSankeyToHTML.m`)
When MATLAB's `SSankey.m` renders gradient ribbons on an axes where `set(ax, 'YDir', 'normal')` is applied post-draw, the internal $4 \times N_{\mathrm{strips}}$ normal-offset quad vertices invert the vertical tangent sign $\left(-dy, dx\right)$, which causes direct vertex polygon exports to exhibit sub-pixel vertical striping and mid-span bowtie pinching on steep diagonal ribbons. `exportSankeyToHTML.m` eliminates both artifacts by extracting only the exact left and right block attachment spans $\left\lbrack y_{L,\mathrm{bot}}, y_{L,\mathrm{top}} \right\rbrack$ at $x_L$ and $\left\lbrack y_{R,\mathrm{bot}}, y_{R,\mathrm{top}} \right\rbrack$ at $x_R$, and reconstructing parallel upper and lower rails over $\tau \in \left\lbrack 0, 1 \right\rbrack$ via the smooth cosine S-curve $s\left(\tau\right) = \frac{1}{2}\left(1 - \cos\left(\pi \tau\right)\right)$:

$$y_{\mathrm{top}}\left(\tau\right) = y_{L,\mathrm{top}} + s\left(\tau\right)\left(y_{R,\mathrm{top}} - y_{L,\mathrm{top}}\right), \qquad y_{\mathrm{bot}}\left(\tau\right) = y_{L,\mathrm{bot}} + s\left(\tau\right)\left(y_{R,\mathrm{bot}} - y_{L,\mathrm{bot}}\right)$$

Because the vertical thickness at every horizontal station $\tau \in \left\lbrack 0, 1 \right\rbrack$ satisfies $y_{\mathrm{top}}\left(\tau\right) - y_{\mathrm{bot}}\left(\tau\right) = \left(1 - s\left(\tau\right)\right) H_L + s\left(\tau\right) H_R > 0$, every web SVG `<path>` is strictly non-self-intersecting, smooth, and 10x smaller in file size, while supporting interactive click inspection, collision-avoiding narrative callout placement, and 2-level (`Gate -> Block`) keyboard arrow-key traversal.

---

## 8. Consolidated 21-File VFI Toolkit Codebase Manifest

| File # | MATLAB Script / Function Name | Primary Role in the 4-Region + Abroad Multiphase Suite |
| :---: | :--- | :--- |
| **1** | `Run_All_NZ_Intergen_Suite.m` | Master execution pipeline with `.mat` checkpoint caching (`Cache_NZ_Intergen/`) and `Active_Phases = {'SS0', 'SS1', 'SS2'}` |
| **2** | `Configure_TimeGrid_Params.m` | Maps all flow rates, survival curves, and developmental stage indices across $\Delta t \in \lbrace 5, 3, 2, 1 \rbrace$ |
| **3** | `Build_Phase_Registry.m` | Assembles the $N$-phase registry struct array `Phases(1:N)` for `SS0`, `SS1`, `SS2`, or additional phases |
| **4** | `ReturnFn_SpatialHH_Compact4D.m` | 40-argument GPU household return function (`(l, Ih, ic, aprime, hprime, a, h, z, ...)` on compact 4D grid) |
| **5** | `NZ_4Region_Master.m` & `ReturnFn_SpatialHH.m` | Baseline 4-Region + Emigration Abroad master initializer (5D) and two-stage CES child skill experience-asset return function |
| **6** | `HumanCapital_Lifecycle_aprimeFn.m` | Endogenous human capital and two-stage child skill transition function (`aprimeFn`) |
| **7** | `ReturnFn_Firm.m` | Infinite-horizon Guvenen et al. (2023) collateral-constrained firm return function (`Firm_k`) |
| **8** | `Build_IntergenTransitionMatrix.m` | 100% GPU-vectorized 3-stage operator ($\mathbf{Q}_h$ with Montessori / *Tuakana–Teina* Gate, $\mathbf{Q}_a$, and $4 \times 5$ $\Pi_{\mathrm{mig}}$) |
| **9** | `Solve_Spatial_GE_Loop.m` | Mixed-horizon General Equilibrium solver (`ValueFnIter_MixHorz_PType` & `StationaryDist_MixHorz_PType`) |
| **10** | `Calibrate_NZ_Moments.m` | Simulated Method of Moments (SMM) calibration engine matching the 15 NZ empirical moments |
| **11** | `WelfareDecomposition_4Region.m` | Solves multiphase (`SS1`, `SS2`) 3-step Daruich / Lee-Seshadri decomposition (`T1`), quintiles (`T2`), and tenure (`T3`) |
| **12** | `Counterfactuals_LeeSeshadri_4Region.m` | Multi-stage counterfactual suite (`BM`, `P0_Early`, `P1P2_Late`, `BN_FrontLoad`, `P0_Plus_GrantE`) exporting Tables 4–6 & 12A–C |
| **13** | `FertilityBargaining_Module.m` | Cooperative childcare bargaining, hyperbolic fertility ($\beta_{\mathrm{hyp}} = 0.72$), and NZ Super solvency tax module (Tables 7–8) |
| **14** | `TransPath_4Region_Master.m` | 60-year multiphase shooting algorithm with dynamic `PTypeWeights_path`, credibility blending $\lambda_{\mathrm{cred}}\left(t\right)$, and Figs 1–3 |
| **15** | `Plot_ChildFates_2Panel_SSankey.m` | $N$-panel GPU 5-Stage (17-Node) Population Cohort Fates Sankey & `Table15_ChildFates_5Stage_Decomp_<Region>.csv` |
| **16** | `Plot_ChildFiscal_2Panel_SSankey.m` | $N$-panel GPU 6-Gate (26-Node) Lifecycle Fiscal Sankey, 4-lane split (`Table14`), and 2050 Debt-Sinking Protocol |
| **17** | `Plot_CumulativeTransitionPayoffs.m` & `Plot_ActuarialContinuationValuation.m` | Integrates 60-year transition payoffs and ACC-style 25-year Actuarial Continuation Valuation ($\mathcal{V}_{k,t_0}^{\left(L\right)}$ at 2% & 8% real) with sibling PNG exports |
| **18** | `Plot_Fertility_SuperSolvency_2Panel.m` | Generates the 2-panel Fertility Recovery & NZ Super Solvency comparison (`Keep Age 65` vs. `Raise Age to 67 or 70`, modeling the 38%–45% disability/hardship fiscal substitution leak) |
| **19** | `Plot_SS2_7Factor_StackedAttribution.m` | Decomposes multiphase (`SS0 -> SS1 -> SS2`) Consumption-Equivalent welfare gains (`T1`) into 7 additive structural engines across the 60-year cohort trajectory and 4 regions |
| **20** | `Plot_WealthBracket_PainAndCelebration.m` | Evaluates distributional welfare incidence (3 Pain Channels vs. 4 Gain Channels, Active Entrepreneur vs. Passive Land Hoarder, and Retained Net Worth) across 12 Earn + Own tiers (`Table17`) |
| **21** | `exportSankeyToHTML.m` | Exports live MATLAB `SSankey` axes into standalone, zero-dependency interactive HTML5 + SVG web diagrams (`Interactive_ChildFates_*.html`, `Interactive_ChildFiscal_*.html`) with cosine-S-curve ribbon geometry |
