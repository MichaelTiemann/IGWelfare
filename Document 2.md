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

### Section 3.3: Adolescent Family Unemployment Stress, Unbanked Skill Fade-Out, and Bidirectional Montessori / *Tuakana–Teina* Mentoring ($M_{\mathrm{mentor}}$)

In the two-stage Cunha–Heckman–Schennach skill technology (`HumanCapital_Lifecycle_aprimeFn.m`), childhood skill $\theta_c$ evolves across Stage 1 ($\mathcal{J}_{c,1}$, ages 0–5, where $\varphi_1 = 0.35 > 0$) and Stage 2 ($\mathcal{J}_{c,2}$, ages 6–17, where $\varphi_2 = -0.95 < 0$)[cite: 2, 4]. Just as adult Ben-Porath human capital $h$ depreciates at rate $\delta_{hc}$ when an adult stops out of the labor force ($\ell = 0$)[cite: 2, 9], early childhood skill gains ($\theta_c > \theta_{\mathrm{base}}$) accumulated during the First 2,000 Days are vulnerable to **adolescent fade-out** at rate $\delta_{\theta,\mathrm{fade}} = 0.22$ if they are not sustained by Stage-2 mentoring wraparound $M_{\mathrm{mentor}} \in \lbrack 0, 1\rbrack$ (Bailey et al., 2017; Cunha et al., 2010):

$$\theta_{c,\mathrm{ret}} = \theta_c - \delta_{\theta,\mathrm{fade}} \left(1 - M_{\mathrm{mentor}}\right) \max\left(0, \theta_c - \theta_{\mathrm{base}}\right)$$

$$\theta^{\prime}_c = \begin{cases}
\left(1 - \omega_{s1}\right)\theta_c + \omega_{s1}\left\lbrack \gamma_{1,\mathrm{self}} \theta_c^{\varphi_1} + \gamma_{1,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},1}^{\mathrm{eff}} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_1} + \gamma_{1,\mathrm{par}} \bar{h}_p^{\varphi_1} \right\rbrack^{1/\varphi_1} & \text{if } j \in \mathcal{J}_{c,1} \\
\left(1 - \omega_{s2}\right)\theta_{c,\mathrm{ret}} + \omega_{s2}\left\lbrack \gamma_{2,\mathrm{self}} \theta_{c,\mathrm{ret}}^{\varphi_2} + \gamma_{2,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},2}^{\mathrm{eff}} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_2} + \gamma_{2,\mathrm{par}} \bar{h}_p^{\varphi_2} \right\rbrack^{1/\varphi_2} \exp\left(\Psi_{J=5}\left(z_p, a_p, M_{\mathrm{mentor}}\right)\right) & \text{if } j \in \mathcal{J}_{c,2} \\
\theta_c & \text{otherwise}
\end{cases}$$

Because Stage 2 exhibits strong dynamic complementarity ($\sigma_2 = \frac{1}{1 - \varphi_2} = 0.51 < 1$) and unbanked gain depreciation $\delta_{\theta,\mathrm{fade}} > 0$, early skill gains $\theta_c$ erode during middle childhood and early adolescence ($J = 5$, child ages 12–14) if Stage-2 investment or socio-emotional stability collapses[cite: 2, 4]. We formalize two countervailing mechanisms operating at this gate[cite: 2]:

1. **Observable Family Unemployment & Housing Distress Shock ($\psi_{\mathrm{unemp}}$):** Following the empirical job-displacement and *Family Stress Model* literature (Conger et al., 1992; Rege, Telle, & Votruba, 2011; Coelli, 2011; *Growing Up in New Zealand* "Now We Are 12", Morton et al., 2024), when a parent in region $k$ experiences an adverse labor-market productivity or unemployment realization $z_p \in \mathcal{Z}_{\mathrm{distress}}$ (specifically $z_p = z_1$, or $z_p = z_2$ combined with housing hardship $a_p < 0.08 Q_k$) during the child's adolescent window, household psychological stress and reduced parental bandwidth impose a non-cognitive skill penalty $-\psi_{\mathrm{unemp}} < 0$[cite: 2, 6, 8].
2. **Bidirectional Montessori / *Tuakana–Teina* Cross-Age Mentoring ($M_{\mathrm{mentor}} \in \lbrack 0, 1\rbrack$):** While Stage 2 cognitive investment productivity is low ($\gamma_{2,C,3} = 0.044$), non-cognitive malleability remains more than twice as high ($\gamma_{2,N,3} = 0.104$, Cunha et al., 2010)[cite: 2, 4, 11]. Synthesizing indigenous *Tuakana–Teina* and *Ako* reciprocal kinship in *Kura Kaupapa Māori* and bilingual units, the Graeme Dingle Foundation's *Stars / Te Kāhui Whetū* and *Project K* peer-mentoring programs, high-agency vertical-*whānau* state schools, and Montessori's multi-age *Erdkinder* pedagogy (Lillard & Else-Quest, 2006; Agostinelli, Saharkhiz, & Wiswall, 2024; Resnjanskij et al., 2024)[cite: 1, 2, 3, 5], structured cross-age mentoring where adolescents at $J = 5$ mentor younger children at $J = 2\text{--}3$ generates a **two-way intra-generational spillover** without adding an endogenous state variable[cite: 2, 4]:
   * **Downward Scaffolding Multiplier on Stage 1 ($\kappa_{\mathrm{down}} > 0$):** Near-peer tutoring and role-modeling by the *tuakana* adolescent cohort (with mean skill $\bar{\theta}_{J=5}$) augment the effective productivity of public early childhood and primary investments for younger *teina*[cite: 1, 2, 5]:

$$G_{\mathrm{ECE},1}^{\mathrm{eff}} = G_{\mathrm{ECE},1} \left(1 + \kappa_{\mathrm{down}} M_{\mathrm{mentor}} \bar{\theta}_{J=5}\right)$$

   * **Upward "Protégé Effect", Zero Fade-Out, & Stress Buffer on Stage 2 ($\kappa_{\mathrm{up}} > 0$):** Serving as a high-agency *tuakana* mentor builds adolescent executive function, self-regulation, and *mana*[cite: 1, 2, 5], eliminating unbanked Stage-1 skill fade-out ($\left(1 - M_{\mathrm{mentor}}\right)\delta_{\theta,\mathrm{fade}} \to 0$) and directly buffering the family unemployment shock via the adolescent net shift $\Psi_{J=5}$[cite: 2, 4]:

$$\Psi_{J=5}\left(z_p, a_p, M_{\mathrm{mentor}}\right) = -\psi_{\mathrm{unemp}} \mathbb{I}\left(z_p \in \mathcal{Z}_{\mathrm{distress}}\right) \left(1 - \zeta_{\mathrm{buf}} M_{\mathrm{mentor}}\right) + \kappa_{\mathrm{up}} M_{\mathrm{mentor}}$$

In the compact 4D projection (`Build_IntergenTransitionMatrix.m` and `Plot_ChildFates_2Panel_SSankey.m`), this induces the unified anchored log-skill transition mean across the 7-point adult human capital grid $h_{\mathrm{child}} \in \mathcal{H}$[cite: 2, 4, 6]:

$$\mu_{\ln h}\left(h_p, i_c, z_p, a_p; k\right) = \rho_{hc} \ln\left(h_p\right) + \gamma_{ic} \ln\left(\frac{i_c + G_{\mathrm{ECE},1}^{\mathrm{eff}} + \bar{g}_{\mathrm{ECE}}}{\bar{i}_c + G_{\mathrm{ECE},\mathrm{base}} + \bar{g}_{\mathrm{ECE}}}\right) - \psi_{\mathrm{crowd}} \ln\left(\max\left(1, Q_k\right)\right) \mathbb{I}\left(a_p < 0.08 Q_k\right) + \Psi_{J=5}\left(z_p, a_p, M_{\mathrm{mentor}}\right) + \alpha_{\mathrm{grid}}$$

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

**Calibration of the Gumbel Scale Parameter ($\rho_G = 0.10$ in Labrousse & Perdereau, 2025, Table 8 $\to$ $\varrho_{\mathrm{mig}} = 0.180$ in `Calibrate_NZ_Moments.m`):** In Table 8 (p. 54) of Labrousse and Perdereau (2025), their baseline Gumbel shock scale parameter is calibrated to $\rho_G = 0.10$ to match France's 5-year inter-regional stay rate of 85% (3% annual mobility). In our New Zealand model (`Calibrate_NZ_Moments.m`), $\varrho_{\mathrm{mig}} = 0.180$ is higher than France's $0.10$ because under the 1973 Trans-Tasman Travel Arrangement (TTTA), New Zealand citizens have visa-free labor-market access to Australia and exhibit the highest cross-border skilled mobility rate in the OECD. Calibrating $\varrho_{\mathrm{mig}}$ in SMM (Table 6.1, Row 13) to match New Zealand's observed 10.93% national (and 19.29%–23.41% Auckland/Large-city) age 20–35 trans-Tasman/OECD departure rate uniquely pins down $\varrho_{\mathrm{mig}} = 0.180$.

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

### 5.3 Cooperative Childcare Bargaining, Hyperbolic Fertility (`FertilityBargaining_Module.m`), & Cao & Li's (2022) Intended-vs.-Realized Fertility Wedge

Following Doepke, Hannusch, Kindermann, and Tertilt (2022) and Cao and Li (2022, *Journal of Population Economics*), couples in fertile brackets $j \in \lbrace 2, 3, 4 \rbrace$ with female/male productivity $\left(h_f, h_m\right)$ and quasi-hyperbolic present-bias parameter $\beta_{\mathrm{hyp}} = 0.72$ bargain cooperatively over fertility $n_f \in \lbrace 0, 1, 2, 3 \rbrace$. A birth occurs if and only if both partners achieve positive net marital surplus over their outside options:

$$\mathcal{S}_f\left(n_f; Q_k, G_{\mathrm{ECE}}, \theta_{\tau}\right) = u_f\left(c_f\left(n_f\right)\right) + \beta_{\mathrm{hyp}} \delta V_f^{\prime}\left(n_f\right) - \theta_{\tau} \psi_{\mathrm{time}} n_f + \omega_{\mathrm{ECE}} G_{\mathrm{ECE}} n_f - \psi_Q Q_k n_f \ge \underline{U}_f$$

* **Theoretical & Empirical Identification via Cao & Li (2022, Propositions 1–5) — Why We Evaluate $\beta_{\mathrm{hyp}} = 0.72$ Analytically in `FertilityBargaining_Module.m` Rather Than Calling `vfoptions.exoticpreferences = 'QuasiHyperbolic'`:**
  1. *The Intended ($n^c$) vs. Realized ($n^t$) Fertility Wedge (Cao & Li, 2022, Propositions 1, 2, & 5):* Incorporating quasi-hyperbolic discounting ($\beta \delta^{t^{\prime}-t}$) into a dynamic Barro–Becker overlapping generations model with altruism $\Phi\left(n\right) = \frac{n^{1-\epsilon}}{1-\epsilon}$, Cao and Li (2022, Eqs. 5–6) prove that when young adults formulate their **intended fertility plan** in Period 1 (*the commitment problem*, $n^c$), steady-state fertility satisfies $\beta \delta^2 R^2 \frac{\Phi\left(n^c\right)}{n^c} = 1$, whereas when they reach the active childbearing window in Period 2 without a commitment device (*the time-consistent / realized problem*, $n^t$), they discount the Period-3 dynastic utility of children $\Phi\left(n\right)V_1\left(e^{\prime}, b^{\prime}\right)$ by an **additional factor of $\beta$**, yielding $\left(\beta \delta R\right)^2 \frac{\Phi\left(n^t\right)}{n^t} = 1$. Dividing the two steady-state conditions yields Cao and Li's closed-form identification equation (**Proposition 5**, p. 997). Matching New Zealand's gap between intended family size ($n^c \approx 2.15$) and baseline realized Total Fertility Rate ($n^t = 1.66$ nationally and $1.49$ in Auckland, so $n^t / n^c \in \left\lbrack 0.693, 0.772 \right\rbrack$) pins down the effective hyperbolic fertility discount factor at $\beta_{\mathrm{hyp}} = 0.72$:

     $$n^t = n^c \, \beta_{\mathrm{hyp}}^{1/\epsilon} \qquad \Longleftrightarrow \qquad \ln\left(n^t\right) = \ln\left(n^c\right) + \frac{1}{\epsilon} \ln\left(\beta_{\mathrm{hyp}}\right)$$

  2. *Exact Separation of Period-2 Fertility Realization from Commitment Savings:* In the VFI Toolkit, enabling `vfoptions.exoticpreferences = 'QuasiHyperbolic'` applies quasi-hyperbolic discounting to every continuous savings choice $a^{\prime}$ across all $J$ ages, requiring dual value functions and more than doubling GPU backward-induction runtime. In New Zealand's institutional setting, compulsory KiwiSaver/Superannuation and mortgage amortization act as commitment devices on lifecycle asset accumulation ($a^{\prime}$), whereas no commitment device exists for childbearing ($n_f$). Evaluating the extra Period-2 present-bias factor $\beta_{\mathrm{hyp}} = 0.72$ directly inside `FertilityBargaining_Module.m` analytically replicates Cao and Li's Equation (6) time-consistent fertility wedge at zero additional VFI cost.
  3. *Interaction with Credit Constraints ($i_c = 0$) and Spousal Bargaining (Doepke & Tertilt, 2018; Cao & Li, 2022, Sec. 4):* Cao and Li (2022, Proposition 4) show that in a frictionless credit market, present-biased parents substitute child quality for quantity ($n^t < n^c \Longrightarrow e^t > e^c$), and note that unmodeled hyperbolic discounting confounds estimates of spousal fertility bargaining (Doepke & Tertilt, 2018). In our spatial OLG framework, unconstrained urban couples exhibit Cao and Li's quantity-to-quality shift, whereas rent-squeezed low-income households ($a^{\prime} \ge 0$, $i_c = 0$) are prevented by the borrowing constraint from increasing $i_c$ until universal First-2000-Days wraparound ($G_{\mathrm{ECE},1}$) and the Youth Grant ($E$) relax their Period-2 budget constraint.
  4. *Why We Couple `vfoptions.experienceasset = 1` with Analytical Period-2 $\beta_{\mathrm{hyp}}$ Evaluation Rather Than Global `vfoptions.exoticpreferences = 'QuasiHyperbolic'`:* While VFI Toolkit natively supports pairing `experienceasset = 1` (for the child's skill stock $\theta_c$) with `vfoptions.exoticpreferences = 'QuasiHyperbolic'`, enabling global quasi-hyperbolic discounting applies $\beta_{\mathrm{hyp}} = 0.72$ to every continuous choice $\left(a^{\prime}, i_c, \ell, I_h\right)$ across all $J = 27$ ages. Doing so would (i) misattribute the early-childhood $i_c = 0$ investment corner to parental myopia rather than binding credit and housing-subsistence constraints ($\bar{g}_{\mathrm{ECE}} > 0$), (ii) counterfactually depress mortgage and KiwiSaver wealth accumulation ($a^{\prime}$) that are anchored by institutional commitment devices in New Zealand, and (iii) require tracking dual value functions $\left(V_j, W_j\right)$ under non-monotone Markov-perfect policy gaming across the 60-year transition path. Evaluating $W_f\left(n_f\right) = u_f\left(n_f\right) + \beta_{\mathrm{hyp}} \delta V_f^{\prime}\left(n_f\right)$ directly on the uncommitted fertility margin inside `FertilityBargaining_Module.m` (paired with our `experienceasset = 1` child skill law of motion and $\mathcal{T}_{\mathrm{IG}}$ dynastic closure) achieves exact mathematical equivalence on the Cao and Li (2022) fertility wedge while keeping the $i_c = 0$ hardship corner purely credit- and rent-driven.

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
| Gumbel Migration Scale | $\varrho_{\mathrm{mig}}$ | `0.180` | Labrousse & Perdereau (2025, Table 8: $\rho_G = 0.10$) / Stillman & Maré (2008, Motu WP 08-06) & Poot (2009, NZ Treasury) age 20–35 trans-Tasman emigration (19.3% Akl / 10.9% Nat.) | `10.93%` |
| Present-Bias Fertility | $\beta_{\mathrm{hyp}}$ | `0.720` | Cao & Li (2022, *J. Pop. Econ.*, Prop. 5) / Stats NZ realized vs. intended TFR ($1.66$ vs. $2.15$) | `1.66` |
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

$$Q_{k,t} = \sum_{s=1}^{\infty} \left(\frac{G_k}{R\left(\tau_a\right)}\right)^{s} d_{\mathrm{land},k,t} + B_{\mathrm{land},k,t} \quad \Longrightarrow \quad B_{\mathrm{land},k,t} > 0 \;\;\left(\mathrm{when}\;\; G_k \ge R\left(0\right)\right)$$

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
| **18** | `Plot_Fertility_SuperSolvency_2Panel.m` | Generates the 2-panel Fertility Recovery & NZ Super Solvency comparison (`Keep Age 65` vs. `Raise Age to 67 or 70`, modeling the 38%–45% disability/hardship fiscal substitution leak; Doepke et al. 2022, Cao & Li 2022, Fan, Seshadri, & Taber 2022, and NZ Treasury 2024) |
| **19** | `Plot_SS2_7Factor_StackedAttribution.m` | Decomposes multiphase (`SS0 -> SS1 -> SS2`) Consumption-Equivalent welfare gains (`T1`) into 7 additive structural engines across the 60-year cohort trajectory and 4 regions |
| **20** | `Plot_WealthBracket_PainAndCelebration.m` | Evaluates distributional welfare incidence (3 Pain Channels vs. 4 Gain Channels, Active Entrepreneur vs. Passive Land Hoarder, and Retained Net Worth) across 12 Earn + Own tiers (`Table17`) |
| **21** | `exportSankeyToHTML.m` | Exports live MATLAB `SSankey` axes into standalone, zero-dependency interactive HTML5 + SVG web diagrams (`Interactive_ChildFates_*.html`, `Interactive_ChildFiscal_*.html`) with cosine-S-curve ribbon geometry |

---

---

## 9. Annex: Master Reference Library & Empirical Source of Truth (`IntergenerationalWelfare` Drive Repository)

To ensure full replicability across the theoretical operators, VFI Toolkit scripts, New Zealand administrative calibrations, and historical benchmarks in **Documents 1A, 1B, 1C, and 2**, the project's primary literature and official datasets are organized into six domain folders in the companion `IntergenerationalWelfare` reference library:

### Folder 1: `01_Core_Macro_OLG_and_Wealth_Tax_Theory` (6 Papers)
1. **Ferriere, A., Grübener, P., Navarro, G., & Vardishvili, O. (2025 / Working Paper 2023):** *"On the Optimal Design of Transfers and Income-Tax Progressivity"* (plus companion ECB/CEPR paper *"In-Kind Transfers, Luxury Thresholds, and Redistribution"*) — **Public PDF:** *Journal of Political Economy Macroeconomics* / ECB Working Paper Series / PSE. *(Anchors the $\bar{g}_{\mathrm{ECE}}$ Stone-Geary luxury corner $i_c = 0$, welfare-based in-kind imputation weight $\omega_i$, and intertemporal government debt-service budget constraint $r_t d_t$.)*
2. **Guvenen, F., Kambourov, G., Kuruscu, B., Ocampo, S., & Chen, D. (2023):** *"Use It or Lose It: Efficiency and Redistributional Effects of Wealth Taxation"* — **Public PDF:** *Quarterly Journal of Economics* 138(2), 835–894 / NBER Working Paper w26284. *(Anchors the $\tau_k \to \tau_a$ property-to-enterprise capital reallocation mechanism and infinite-horizon firm Bellman equation `ReturnFn_Firm.m`.)*
3. **Hirano, T., & Toda, A. A. (2025):** *"Unbalanced Growth and Land Overvaluation"* (and *"Bubble Necessity Theorem"*) — **Public PDF & Replication Code:** *Journal of Political Economy Macroeconomics* / *PNAS* / Alexis Akira Toda's GitHub (`alexisakira.github.io/files/code_unbalanced_growth.zip`). *(Anchors regional land overvaluation $Q_k$ under unbalanced sectoral productivity growth $G_k$ and the Part VI Tokyo Land Bubble Coda.)*
4. **Kiyotaki, N., Michaelides, A., & Nikolov, K. (2024):** *"Housing, Distribution, and Welfare"* — **Public PDF:** *Journal of Money, Credit and Banking* 56(5), 987–1020 (Wiley Open Access). *(Anchors the young renter vs. leveraged homeowner vs. retiree landlord tenure cleavage $\xi_k$ and small-open-economy interest rate crowding-in channel $\Delta r$.)*
5. **De Nardi, M. (2004):** *"Wealth Inequality and Intergenerational Links"* — **Public PDF:** *Review of Economic Studies* 71(3), 743–768 / NBER Working Paper w9768. *(Anchors the warm-glow luxury bequest motive $b_1, b_2$ and the Sweden vs. US idiosyncratic earnings variance compression benchmark.)*
6. **Piketty, T., & Saez, E. (2013):** *"A Theory of Optimal Inheritance Taxation"* (alongside Piketty, Saez, & Zucman, 2022) — **Public PDF:** *Econometrica* 81(5), 1851–1886 / NBER Working Paper w17989. *(Anchors the optimal estate levy $\tau_b = 25\%$ on New Zealand's NZD 1.6T intergenerational property transfer funding the universal Youth Capital Grant $E$.)*

### Folder 2: `02_Human_Capital_First2000Days_and_Adolescent_Gates` (6 Papers)
7. **Cunha, F., Heckman, J. J., & Schennach, S. M. (2010):** *"Estimating the Technology of Cognitive and Noncognitive Skill Formation"* — **Public PDF:** *Econometrica* 78(3), 883–931 / NBER Working Paper w15664. *(Anchors the two-stage CES skill technology with high Stage-1 substitutability $\varphi_1 = 0.35$ in the First 2000 Days and strong Stage-2 dynamic complementarity $\varphi_2 = -0.95$ in schooling.)*
8. **Lee, S. Y., & Seshadri, A. (2019):** *"On the Intergenerational Transmission of Economic Status"* (alongside Fan, Seshadri, & Taber, 2022, on adult Ben-Porath human capital) — **Public PDF:** *Journal of Political Economy* 127(2), 855–921 / NBER Working Paper w24395. *(Anchors `Counterfactuals_LeeSeshadri_4Region.m` regimes `P0_Early_0to5`, `P1P2_Late_6to17`, `BN_FrontLoad`, and `P0_Plus_GrantE`.)*
9. **Daruich, D. (2018 / 2022):** *"The Macroeconomic Consequences of Early Childhood Development Policies"* — **Public PDF:** SSRN / St. Louis Fed Working Paper. *(Anchors the 3-step PE/GE/Intergenerational welfare decomposition `T1`, Jump 1 vs. Jump 2 cohort welfare transition trajectories, and two-stage Sobol + Nelder-Mead SMM calibration.)*
10. **Caspi, A., Houts, R. M., Belsky, D. W., Harrington, H., Hogan, S., Ramrakha, S., Poulton, R., & Moffitt, T. E. (2016):** *"Childhood forecasting of a small segment of the population with large economic burden"* — **Public PDF:** *Nature Human Behaviour* 1, 0005 (PMC Open Access). *(The landmark Dunedin Multidisciplinary Health and Development Study paper proving that the most disadvantaged 22% of a cohort at age 3 accounts for 57%–81% of adult hospital nights, welfare receipt, and criminal convictions.)*
11. **Morton, S. M. B., et al. (2020 / 2023):** *"Growing Up in New Zealand: Now We Are Eight / Now We Are Twelve — Life in Early Adolescence"* — **Public PDF:** University of Auckland / Ministry of Social Development (`growingup.co.nz`). *(Anchors the `'MetroSqueeze_GUiNZ'` housing crowding and dampness penalty $\psi_{\mathrm{crowd}}$ and the Ages 12–14 early-adolescent vulnerability window.)*
12. **Gluckman, P. (2011), Berryman, M., & Eley, E. (2019), & Graeme Dingle Foundation (2023/2025):** *"Improving the Transition: Reducing Social and Psychological Morbidity During Adolescence"* (Office of the Prime Minister's Chief Science Advisor, 2011), *"Tuakana–Teina and Ka Hikitia: Accelerating Māori Student Success"* (*New Zealand Journal of Educational Studies*), and **Graeme Dingle Foundation** *Social Return on Investment (SROI) Reports on Stars / Te Kāhui Whetū & Project K*. *(Anchors the Gate 3 $J = 5$ Montessori / *Tuakana–Teina* and Graeme Dingle adolescent mentoring boost $\Delta_{\mathrm{Tuakana}} = +0.11$.)*

### Folder 3: `03_Fertility_Bargaining_and_Brain_Drain_Migration` (5 Papers)
13. **Doepke, M., Hannusch, A., Kindermann, F., & Tertilt, M. (2022 / 2023):** *"The Economics of Fertility: A New Era"* — **Public PDF:** *Handbook of the Economics of the Family* / NBER Working Paper w29948. *(Anchors the cooperative household childcare bargaining module `FertilityBargaining_Module.m`, maternal time share $\theta_{\tau} = 0.68$, and Nordic vs. East Asian fertility regimes.)*
14. **Cao, J., & Li, M. (2021 / 2022):** *"Hyperbolic discounting in an intergenerational model with altruistic parents"* — **Public PDF:** *Journal of Population Economics* 35(3), 989–1005 ([https://doi.org/10.1007/s00148-021-00824-7](https://doi.org/10.1007/s00148-021-00824-7)). *(Anchors the Period-2 quasi-hyperbolic fertility discount parameter $\beta_{\mathrm{hyp}} = 0.72$ via Proposition 5's closed-form ratio of realized to intended fertility $n^t / n^c = \beta_{\mathrm{hyp}}^{1/\epsilon}$.)*
15a. **Labrousse, C., & Perdereau, Y. (2025):** *"Geography versus Income: The Heterogeneous Effects of Carbon Taxation"* — **Public PDF:** European Central Bank (ECB) Working Paper Series / Paris School of Economics (building on **Ferriere, A., & Navarro, G., 2025**, *Review of Economic Studies* 92(2), 1061–1125). *(Section 3.2, Appendix B, & Table 8 provide the exact $4 \times 5$ Gumbel extreme-value discrete location-choice operator $P_t^{k^{\prime}}\left(a, z, k\right)$ and baseline Gumbel shock variance $\rho_G = 0.10$, adapted in our Stage-3 youth sorting matrix with $\varrho_{\mathrm{mig}} = 0.180$, alongside the Spatial $\times$ Income transfer progressivity framework in `T2`.)*
15b. **Stillman, S., & Maré, D. C. (2008):** *"Housing Markets and Migration: Evidence from New Zealand"* — **Public PDF:** **Motu Working Paper 08-06**, Motu Economic and Public Policy Research ([https://motu-www.motu.org.nz/wpapers/08_06.pdf](https://motu-www.motu.org.nz/wpapers/08_06.pdf)). *(Provides 5-year New Zealand Census inter-regional internal vs. international migration accounting across Local Labour Market Areas and proves that net retention of NZ-born residents is negatively related to local real house price inflation with an elasticity of `-4.4`.)*
15c. **Poot, J. (2009 / 2010) & Greenaway-McGrevy, R., & Phillips, P. C. B. (2023):** *"Trans-Tasman Migration, Transnationalism and Economic Development in Australasia"* (**New Zealand Treasury Guest Lecture / Population Studies Centre DP 72**, [https://www.treasury.govt.nz/sites/default/files/2017-11/tfr-ttmteda-28oct09.pdf](https://www.treasury.govt.nz/sites/default/files/2017-11/tfr-ttmteda-28oct09.pdf); alongside **Bushnell, P., & Choy, W. K., 2001**, *"Go West, Young Man, Go West!?"* **NZ Treasury Working Paper 01/07**) + **Greenaway-McGrevy, R., & Phillips, P. C. B. (2023 / 2025)**, *"The Impact of Upzoning on Housing Construction in Auckland"* (*Journal of Urban Economics* 136, 103558 & UoA Economic Policy Centre WP 013). *(Anchors the age 20–35 trans-Tasman emigration pull $\omega_{\mathrm{OECD}} = 1.32$, replacement-migration turnover churn, and Auckland's housing supply elasticity $\delta_{H,\mathrm{Auckland}} = 0.10$.)*

### Folder 4: `04_NZ_Treasury_LTFS_CBAx_and_Infrastructure_Audits` (8 Official Reports & Models)
16. **New Zealand Treasury (September 2025):** *He Tirohanga Mokopuna 2025 — Long-term Fiscal Statement 2025* (`ltfs-2025.pdf`, [https://www.treasury.govt.nz/publications/ltfp/he-tirohanga-mokopuna-2025](https://www.treasury.govt.nz/publications/ltfp/he-tirohanga-mokopuna-2025)). *(Anchors the status-quo 40-year fiscal outlook where real government spending per person nearly doubles from NZD 18,300 to NZD 35,900 and net core Crown debt reaches ~200% of GDP by 2065, alongside Annexes 1–2 introducing Treasury's OLG model.)*
17. **Bell, M. / New Zealand Treasury (February 2026), Binning et al. (2024), & Treasury OIA Response 20250878 (February 2026):** *Analytical Note 26/01: The 2025 Long-term Fiscal Model — Main features and changes* (`an26-01-v2.pdf`, [https://www.treasury.govt.nz/publications/an/an-26-01](https://www.treasury.govt.nz/publications/an/an-26-01)), *Official Information Act Response 20250878: Social Cost Benefit Analysis and Fiscal Projection Models* (`oia-20250878.pdf`, 4 Feb 2026), and Binning, McKenzie, Özbilgin, & Smith (2024 / *AN 24/08*). *(AN 26/01 anchors the 2025 BEFU-based LTFM debt-interest spiral and 0.9%/yr productivity growth assumption; OIA 20250878 officially confirms on pp. 6–11 that Treasury's macro LTFM/FSM models do not model micro cohort social-harm feedback loops—the exact methodological gap closed by our coupled 4-Region OLG + Dunedin/CBAx lifecycle engine.)*
18a. **New Zealand Treasury (November 2025 & July 2015):** *CBAx Tool User Guidance: Guide for departments and agencies using Treasury's CBAx tool for cost benefit analysis* (`cbax-tool-user-guidance-nov25.pdf`), companion *CBAx Spreadsheet Model & Impacts Database* (`cbax-model-oct25.xlsx`, Oct 2025), and *Guide to Social Cost Benefit Analysis* (`cba-guide-jul15.pdf`, July 2015), supplemented by *Budget 2026 Guidance for Agencies* (`b26-guide-agen-5304608.pdf`). *(Page 15 of the November 2025 CBAx User Guidance anchors Treasury Circular 2024/15's dual public-sector real discount rates—**2.0% real SRTP** for non-commercial social investments over Years 1–30, stepping to 1.5% in Years 31–100, with mandatory **8.0% real SOC** sensitivity testing—while the July 2015 Guide pp. 10–15 anchors Counting Rule #1 separating fiscal transfer payments $T_k$ from real GDP output $\Delta Y_t$.)*
18b. **New Zealand Treasury (March 2025):** *OIA Response 20250126: Review of Public Sector Discount Rates Culminating in Treasury Circular 2024/15* (`oia-20250126.pdf`, containing **Grimes, A., June 2023**, *How should the NZ government discount future payoffs?*; **Abelson, P., & Dalton, T., June 2023**, *Declining Discount Rates in Cost Benefit Analysis*; and **Jensen, K., & Parker, C., Dec 2023**, *Update to Public Sector Discounting — Default SRTP*). *(Provides the theoretical CCAPM, Ramsey Monte Carlo, and Weitzman certainty-equivalent proofs for adopting the 2.0% real SRTP discount rate and declining long-term schedule rather than continuous hyperbolic discounting in public project appraisal.)*
18c. **Accident Compensation Corporation (ACC) (14 November 2025):** *Financial Condition Report 2025* (Prepared by Nina Herries, Chief Actuary, `ACC8828-Financial-Condition-Report-2025.pdf`). *(Provides the statutory and actuarial template for our Year 5 Actuarial Continuation Valuation $\mathcal{V}_{k,t_0}^{\left(L\right)}$: documents the valuation of ACC's NZD 57.34B funding-basis / NZD 63.6B accounting-basis Outstanding Claims Liability, defines "New Year Costs" and "OCL Release" [booking discounted multi-decade liability reductions when rehabilitation performance improves, pp. 17 & 44], and details the transition to PBE IFRS 17.)*
19. **Independent Crown Review / Department of Internal Affairs (September 2026) & *Te Waihanga* (2025/2026):** *Report of the Independent Review into the Moa Point Wastewater Treatment Plant Failure* (Chaired by Raveen Jaduram) + **New Zealand Infrastructure Commission / *Te Waihanga***, *National Infrastructure Plan & Rautaki Hanganga o Aotearoa*. *(Anchors the reactive-vs.-preventative maintenance proof and the 2050 50/50 Debt-Sinking & Infrastructure Protocol.)*
20. **Barnardos Aotearoa (2025 / 2026) & MartinJenkins (2020):** *Generational Plan Economic Case, Derived Measures, & Facts Table* (`Barnardos_GP_Economic_Case_FINAL.docx`, `Barnardos_GP_Derived_Measures_FINAL.docx`, `Barnardos_GP_Facts_Table_FINAL.docx`—modeling *Te Korowai Mokopuna* First 2000 Days wraparound) and **MartinJenkins (2020)**, *Economic Cost of Abuse in Care: Final Report* (for the Royal Commission of Inquiry into Abuse in Care, `MSC0008804`, [https://www.abuseincare.org.nz/__data/assets/pdf_file/0021/25158/martinjenkins-economic-cost-of-abuse-in-care-2020.pdf](https://www.abuseincare.org.nz/__data/assets/pdf_file/0021/25158/martinjenkins-economic-cost-of-abuse-in-care-2020.pdf), alongside Oranga Tamariki *Funding Policy and Guidance for Shared Care*, Oct 2023). *(Anchors the community-delivered First-2000-Days wraparound intervention, the NZD 37,054 to NZD 54,739 per child-year Oranga Tamariki custody cost, and the NZD 181,000 [in 2025 NZD] discounted lifetime Crown fiscal cost per child abused in care.)*

### Folder 5: `05_NZ_Wealth_Distribution_Tax_and_Social_Cohesion_Data` (4 Official Reports)
21. **Inland Revenue Department (IRD) (April 2023):** *High-Wealth Individuals Research Project (HWIRP) — Final Report* — **Public PDF:** `ird.govt.nz`. *(Anchors Tiers 10–12 of the 12-Tier Earn + Own table: NZD 50M median net worth, NZD 106M mean net worth, and 8.9% baseline effective economic tax rate.)*
22. **Statistics New Zealand (2022 / 2025):** *Household Net Worth Statistics* + *Subnational Population Estimates & Business Demography Statistics (Feb/June 2025)* + *Child Poverty Statistics (Year Ended June 2025)* — **Public PDFs/CSVs:** `stats.govt.nz`. *(Anchors median net worth NZD 529k, mean NZD 1.041M, the 4-region household `[0.160, 0.240, 0.259, 0.341]` and firm `[0.150, 0.230, 0.269, 0.351]` weights, and AHC child poverty.)*
23. **Rashbrooke, M. (2015, 2021 / 2024 Updates):** *Wealth and New Zealand* and *Too Much Money: How Wealth Disparities Are Unbalancing Aotearoa New Zealand* (Bridget Williams Books / VUW Institute for Governance and Policy Studies Working Papers). *(Anchors the P50, P90, P95, and P99 wealth percentiles in `Plot_WealthBracket_PainAndCelebration.m`.)*
24. **Transparency International & Office of the Auditor-General of New Zealand (2026):** *Corruption Perceptions Index 2025* (Feb 2026), Office of the Controller and Auditor-General *"New Zealand's Integrity Inheritance"* (Feb 2026), and Transparency International New Zealand *National Integrity System Gap Analysis* (June 2026) — **Public PDFs:** `transparency.org.nz` and `oag.parliament.nz`. *(Anchors the "Sovereign Social Credit Rating" analysis and Social Cohesion Index $S_t: 100.0 \to 118.4 \to 126.0$.)*

### Folder 6: `06_International_Benchmarks_Scotland_Nordics_and_Deming` (4 Reports/Papers)
25. **Scottish Government & Joseph Rowntree Foundation (2026):** *Bringing Hope, Building Futures: Tackling Child Poverty Delivery Plan 2026–2031* (Scottish Government, March 2026), *Scottish Child Payment and the Labour Market* (Oct 2026), and *Poverty in Scotland 2026* (JRF, Oct 2026) + **MCR Pathways (2024/2025)** *National Impact Report*. *(Anchors the Scotland devolved natural experiment in Part VI.)*
26. **Corlet Walker, C., Druckman, A., & Jackson, T. (2021 / 2024):** *"Welfare systems without economic growth: A review of the challenges and next steps for the field"* — **Public PDF:** *The Lancet Planetary Health* 5(4), e237–e246. *(Links New Zealand, Scotland, and Finland in the Wellbeing Economy Governments alliance.)*
27. **Baker, M., Gruber, J., & Milligan, K. (2008):** *"Universal Childcare, Maternal Labor Supply, and Family Well-Being"* — **Public PDF:** *Journal of Political Economy* 116(4), 709–745 / NBER Working Paper w11832. *(Anchors the Quebec universal childcare self-financing and maternal labor supply benchmark.)*
28. **Deming, W. E. (1950 Mt. Hakone JUSE Lecture Transcript / 1986 *Out of the Crisis* Ch. 1–2 / 1993 *The New Economics* Ch. 4: *A System of Profound Knowledge*), Moriguchi, C., & Saez, E. (2008, *Review of Economics and Statistics*), & Tiemann, M. (2023, *Achieving Net-Zero with Sustainable Quality*, OS-Climate / Linux Foundation).** *(Anchors the Part VI Coda on whole-system transformation within 3–5 years vs. the 1989 Tokyo land bubble and *Te Tiriti o Waitangi* intergenerational stewardship.)*
