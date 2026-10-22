# Intergenerational Welfare Technical Documentation & Model Specification Guide
**A GPU-Accelerated Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial Overlapping Generations Framework (Multiphase Edition)**

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

*(In the full two-stage CES experience-asset specification with 5D Emigration Abroad, `ReturnFn_SpatialHH.m` and `HumanCapital_Lifecycle_aprimeFn.m`, `a_grid` also tracks the 5-point child skill experience asset $\theta_c \in \mathcal{G}_{\theta}$ across childhood stages $\mathcal{J}_{c,1}$ and $\mathcal{J}_{c,2}$).**(In the full two-stage CES experience-asset specification with Emigration Abroad, `ReturnFn_SpatialHH.m` and `HumanCapital_Lifecycle_aprimeFn.m`, `a_grid` also tracks the 5-point child skill experience asset $\theta_c \in \mathcal{G}_{\theta}$ across childhood stages $\mathcal{J}_{c,1}$ and $\mathcal{J}_{c,2}$).*

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

3. **Relational Altruism & Social Cohesion Utility ($u_{\mathrm{rel}}$):**
   Captures the utility gain experienced by citizens and aging parents when cohort stunting (`Frac_stunted`) is compressed and domestic social cohesion ($S_t$, `S_cohesion`) rises as educated youth remain in New Zealand:

$$u_{\mathrm{rel}}\left(\mathrm{Frac}_{\mathrm{stunted}}, S_t\right) = \chi_{\mathrm{rel}} \left\lbrack \left(0.285 - \mathrm{Frac}_{\mathrm{stunted}}\right) + 0.015 \left(S_t - 100\right) \right\rbrack$$

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

## 5. Post-Hoc Lifecycle Operators: The 6-Gate Fiscal Ledger, 2050 Protocol, & Fertility Bargaining

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

### 5.2 Net Fiscal Balance ($\Omega_{\mathrm{fiscal}}$) & The 2050 Sovereign Debt-Sinking Protocol
At **Gate 5 (Age 30, $J = 10$)** and **Gate 6 (Career to Retirement, $J = 11\text{--}16$)**, the cohort-weighted **Net Fiscal Balance** $\Omega_{\mathrm{fiscal},g}$ is:

$$\Omega_{\mathrm{fiscal},g} = \underbrace{\left(\mathrm{Tax}_{\mathrm{PAYE},g} + \mathrm{Tax}_{\mathrm{GST+Cap+Beq},g}\right)}_{\text{Good Taxes Collected}} - \underbrace{\left(\mathrm{Burden}_{\mathrm{Exits\,1,2,4},g} + \mathrm{Outlay}_{\mathrm{Infra+Health+Super},g}\right)}_{\text{Direct Public Outlays}}$$

Under the **2050 Sovereign Debt-Sinking & Public Reinvestment Protocol** (`Build_Custom_Protocol_2050_Table`), any positive net fiscal surplus $\Omega_{\mathrm{reform},g} = \max\left(0, \, \Omega_{\mathrm{fiscal},g}\right)$ is partitioned 50/50:

$$\Omega_{\mathrm{debt},g} = 0.50 \, \Omega_{\mathrm{reform},g}, \qquad \Omega_{\mathrm{reinv},g} = 0.50 \, \Omega_{\mathrm{reform},g}$$

$$\Delta D_{2050,g} = N_{\mathrm{births}} \, \Omega_{\mathrm{debt},g} \sum_{\tau=1}^{25} \left(1 + r_{\mathrm{bond}}\right)^{\tau - 1}, \qquad \mathcal{S}_{\mathrm{reinv},g} = \mu_{\mathrm{infra}} \, \Omega_{\mathrm{reinv},g}$$

with $N_{\mathrm{births}} = 60,000/\text{yr}$, sovereign bond yield $r_{\mathrm{bond}} = 0.042$, and public infrastructure multiplier $\mu_{\mathrm{infra}} = 1.65$.

### 5.3 Cooperative Childcare Bargaining & Hyperbolic Fertility (`FertilityBargaining_Module.m`)
Following Doepke, Hannusch, Kindermann, and Tertilt (2022) and Kim (2025), couples in fertile brackets $j \in \lbrace 2, 3, 4 \rbrace$ with female/male productivity $\left(h_f, h_m\right)$ and present-bias parameter $\beta_{\mathrm{hyp}} = 0.72$ bargain cooperatively over fertility $n_f \in \lbrace 0, 1, 2, 3 \rbrace$. A birth occurs if and only if both partners achieve positive net marital surplus over their outside options:

$$\mathcal{S}_f\left(n_f; Q_k, G_{\mathrm{ECE}}, \theta_{\tau}\right) = u_f\left(c_f\left(n_f\right)\right) + \beta_{\mathrm{hyp}} \delta V_f^{\prime}\left(n_f\right) - \theta_{\tau} \psi_{\mathrm{time}} n_f + \omega_{\mathrm{ECE}} G_{\mathrm{ECE}} n_f - \psi_Q Q_k n_f \ge \underline{U}_f$$

### 5.4 Endogenous NZ Superannuation Solvency & The Fiscal Substitution Leak of Raising the Eligibility Age ($J_r \to 67\text{ or }70$)
Let $\mathcal{D}_{65+,t}$ denote the national old-age dependency ratio of retirees ($j \ge J_r$, age 65+) to effective working-age taxpayers ($1 \le j < J_r$, ages 20–64) across the four domestic regions:

$$\mathcal{D}_{65+,t} = \frac{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=J_r}^{J} \int d\mu_{k,t}\left(a, h, z, j\right)}{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=1}^{J_r - 1} \int d\mu_{k,t}\left(a, h, z, j\right)}$$

In a pay-as-you-go universal pension system with replacement benefit $p_{\mathrm{super}}$ and consumption-floor top-up $\underline{c}$, the required working-age labor tax rate $\tau_{l,t}^{\mathrm{req}}$ needed to maintain New Zealand Superannuation solvency is inversely proportional to average working-age human capital $\bar{H}_t = \sum_k \omega_{HH,k,t} \int_{j < J_r} w_{k,t} z h \ell_{\mathrm{eff}} \, d\mu_{k,t}$ and directly proportional to $\mathcal{D}_{65+,t}$:

$$\tau_{l,t}^{\mathrm{req}}\left(J_r\right) = \tau_{l,\mathrm{non-super}} + \frac{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=J_r}^{J} \int \left\lbrack p_{\mathrm{super}} + \underline{c}_{\mathrm{health}}\left(a, h, j\right) \right\rbrack d\mu_{k,t}}{\bar{H}_t}$$

When evaluating conventional austerity proposals that raise the statutory retirement age from $A_r = 65$ to $A_r^{\prime} \in \lbrace 67, 70 \rbrace$ while leaving baseline child stunting ($\mathrm{Frac}_{\mathrm{stunted}} = 0.22$), fertility ($\mathrm{TFR} = 1.66$), and youth emigration ($\mathrm{Emig}_{\mathrm{Nat}} = 10.93\%$) unaddressed, `Plot_Fertility_SuperSolvency_2Panel.m` accounts for the **endogenous fiscal substitution leak** $\lambda_{\mathrm{leak}}\left(A_r^{\prime}\right) \in \left\lbrack 0.38, 0.45 \right\rbrack$. Because manual and lower-tier workers ($h \in \lbrace h_1, h_2, h_3 \rbrace$) experience cumulative Ben-Porath physical skill depreciation $\delta_{hc} = 0.087$ and elevated unemployment shocks ($i_z \in \lbrace 1, 2 \rbrace$) in their late sixties, withholding universal superannuation over ages $\left\lbrack 65, A_r^{\prime} \right)$ shifts a fraction $\lambda_{\mathrm{leak}}\left(A_r^{\prime}\right)$ of gross pension savings directly into means-tested Supported Living, Jobseeker, Accommodation Supplement, and acute hospital outlays:

$$\Delta \mathrm{NetSavings}_{t}\left(A_r^{\prime}\right) = \left\lbrack 1 - \lambda_{\mathrm{leak}}\left(A_r^{\prime}\right) \right\rbrack \sum_{k=1}^{4} \omega_{HH,k,t} \int_{65 \le \mathrm{age}\left(j\right) < A_r^{\prime}} p_{\mathrm{super}} \, d\mu_{k,t}^{\mathrm{SS0}}$$

Consequently, raising the pension age to 67 or 70 under status-quo demographics still leaves the required PAYE tax rate climbing to $26.85\%$ (Age 67) or $25.55\%$ (Age 70) while imposing a regressive survival-weighted utility loss $\Delta V_k\left(a, h, z, j\right) < 0$ on Māori, Pasifika, and rural manual cohorts with lower conditional survival probabilities $s_j$. Conversely, expanding the denominator $\bar{H}_t$ via First-2000-Days wraparound investment ($G_{\mathrm{ECE},1}$), Montessori / *Tuakana–Teina* adolescent mentoring ($G_{\mathrm{ECE},2}$), youth retention ($\Pi_{\mathrm{mig}}$), and cooperative fertility recovery ($\mathrm{TFR}: 1.66 \to 1.98$) keeps $A_r = 65$ intact while bending $\tau_{l,t}^{\mathrm{req}}$ down from $28.22\%$ to $24.45\%\text{--}24.90\%$.

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
|Warm-Glow Bequest Threshold | $b_2$ | `2.800` | De Nardi (2004) / Stats NZ top-30% estate skewness | `70th pct` |
| Gumbel Migration Scale | $\varrho_{\mathrm{mig}}$ | `0.180` | OECD / Stats NZ age 20–35 skilled trans-Tasman emigration rate (19.3% Akl / 10.9% Nat.) | `10.93%` |
| Present-Bias Fertility | $\beta_{\mathrm{hyp}}$ | `0.720` | Kim (2025) / Stats NZ baseline national Total Fertility Rate ($\mathrm{TFR} = 1.66$) | `1.66` |
| Female Childcare Share | $\theta_{\tau}$ | `0.680` | Doepke et al. (2022) / Stats NZ Time Use Survey maternal share of childcare | `68.0%` |

---

## 7. Multiphase Transition Path, Actuarial Continuation Valuation, & Credibility-Weighted Belief Blending

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

---

## 8. Consolidated 17-File VFI Toolkit Codebase Manifest

| File # | MATLAB Script / Function Name | Primary Role in the 4-Region + Abroad Multiphase Suite |
| :---: | :--- | :--- |
| **1** | `Run_All_NZ_Intergen_Suite.m` | Master 9-step execution pipeline with `.mat` checkpoint caching (`Cache_NZ_Intergen/`) and `Active_Phases = {'SS0', 'SS1', 'SS2'}` |
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
| **18** | `Plot_Fertility_SuperSolvency_2Panel.m` | Generates the 2-panel Fertility Recovery & NZ Super Solvency comparison (`Keep Age 65` vs. `Raise Age to 67 or 70`, modeling the 38%–45% disability/hardship fiscal substitution leak; Doepke et al. 2022, Kim 2025, Fan, Seshadri, & Taber 2022, and NZ Treasury 2024) |
| **19** | `Plot_SS2_7Factor_StackedAttribution.m` | Decomposes multiphase (`SS0 -> SS1 -> SS2`) Consumption-Equivalent welfare gains (`T1`) into 7 additive structural engines across the 60-year cohort trajectory and 4 regions—isolating Sovereign Debt-Service Interest Relief ($r_t d_t \downarrow$; Ferriere et al. 2025, Kiyotaki et al. 2024, Guvenen et al. 2023, and Daruich 2018) |