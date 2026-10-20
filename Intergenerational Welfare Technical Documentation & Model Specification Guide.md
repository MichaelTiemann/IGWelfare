# Intergenerational Welfare Technical Documentation & Model Specification Guide
**A Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial OLG Model of Intergenerational Welfare, Housing Wealth, and Human Capital in New Zealand (Parameterized Period Length $\Delta t$)**[cite: 1, 3, 6, 8, 17]

---

## 1. Executive Overview & 8-PType GPU Computational Architecture
This specification guide documents the mathematical structure, $\Delta t$-parameterized time-grid equations, calibration mapping, and VFI Toolkit implementation for evaluating intergenerational welfare across **four domestic New Zealand geographic tiers** (**Rural**, **Small**, **Large**, **Auckland**) plus an endogenous **Abroad** (Australia/OECD) emigration margin[cite: 3].

### 1.1 Parameterized Time Period Length ($\Delta t \in \lbrace 5, 3, 2, 1 \rbrace$ Years)
To allow researchers to trade off execution speed against life-cycle and early-childhood granularity without altering structural equations, the model is parameterized by the period length $\Delta t$ (`Params.dt`, configured via `Configure_TimeGrid_Params.m`):
* **Adult Life-Cycle Horizon ($J$):** Economic adulthood spans 80 years from age 20 to age 99 across $J = \mathrm{round}\left(80 / \Delta t\right)$ periods ($J = 16$ for $\Delta t = 5$; $J = 27$ for $\Delta t = 3$; $J = 40$ for $\Delta t = 2$)[cite: 3, 4].
* **NZ Superannuation Retirement Boundary ($J_r$):** Mandatory retirement at age 65 (after 45 working years) begins at period $J_r = 1 + \mathrm{round}\left(45 / \Delta t\right)$ ($J_r = 10$ for $\Delta t = 5$; $J_r = 16$ for $\Delta t = 3$; $J_r = 23$ for $\Delta t = 2$)[cite: 1, 4].
* **Childhood Development Windows ($\mathcal{J}_{c,1}, \mathcal{J}_{c,2}$):** Given parental age index at childbirth $j_{\mathrm{birth}} = 1 + \mathrm{round}\left(6 / \Delta t\right)$, the **First 2000 Days** (child ages 0–5, 6 years) span $n_{s1} = \max\left(1, \mathrm{round}\left(6 / \Delta t\right)\right)$ periods $\mathcal{J}_{c,1} = \lbrace j_{\mathrm{birth}}, \dots, j_{\mathrm{birth}} + n_{s1} - 1 \rbrace$, and **Primary/Secondary Schooling** (child ages 6–17, 12 years) spans $n_{s2} = \max\left(1, \mathrm{round}\left(12 / \Delta t\right)\right)$ periods $\mathcal{J}_{c,2} = \lbrace j_{\mathrm{birth}} + n_{s1}, \dots, j_{\mathrm{birth}} + n_{s1} + n_{s2} - 1 \rbrace$, with completed childhood skill extracted at $j_{\mathrm{launch}} = j_{\mathrm{birth}} + n_{s1} + n_{s2}$[cite: 1, 6, 15].

Under $\Delta t = 3$, the First 2000 Days splits into two distinct 3-year sub-stages ($n_{s1} = 2$: Infancy/Toddlerhood ages 0–2 at $j = 3$, and Preschool/ECE ages 3–5 at $j = 4$), while Schooling spans four 3-year sub-stages ($n_{s2} = 4$: Primary, Intermediate, Junior High, and Senior Secondary across $j \in \{5, 6, 7, 8\}$, launching at $j_{\mathrm{launch}} = 9$).
This multi-step compounding makes the Cunha–Heckman dynamic complementarity ($\varphi_2 = -0.95$) much more realistic: early stunting at age 3 compounds across four sequential schooling steps rather than the one period when $\Delta t = 5$.

With 3-year periods, young adults navigate five distinct 3-year migration and tenure-choice windows between ages 20 and 35 ($j \in \{1, \dots, 5\}$) instead of three.
Because households can re-evaluate housing tenure and saving steps every 3 years, the combination of First-2000-Days wraparound ECE, the Youth Capital Grant ($E$), and the Guvenen et al. wealth-tax shift unlocks a massive un-bottlenecking effect in Large regional metros (Wellington, Christchurch, Hamilton, Tauranga, Dunedin) alongside Auckland, as young talent no longer gets trapped at the rental corner solution during their late 20s.

### 1.2 The 8 Permanent Types (`Names_i`) Dispatched on the GPU
To capture heterogeneous life-cycle households and collateral-constrained entrepreneurial firms across all four domestic regions without expanding individual grid dimensions, the model dispatches **8 Permanent Types (`Names_i`)** sequentially on the GPU[cite: 3, 17]:

| Permanent Type (`Names_i`) | Horizon ($N_j$) | Pop / Firm Share (2025 Base) | Economic Role & Spatial Domain | VFI Toolkit Solver Dispatched |
| :--- | :--- | :---: | :--- | :--- |
| **`HH_Rural`** | Finite ($J = 80/\Delta t$) | $16.0\%$ of HH | Rural & primary districts; elastic land ($\delta_H = 0.35$), high fuel/transport burden ($\bar{e} = 0.048$)[cite: 3, 11]. | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Small`** | Finite ($J = 80/\Delta t$) | $24.0\%$ of HH | Small/medium provincial towns (<100k); compressed middle wages, elevated transport cost ($\bar{e} = 0.036$)[cite: 3, 11]. | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Large`** | Finite ($J = 80/\Delta t$) | $25.9\%$ of HH | Non-Auckland major metros (>100k: Wgtn, Chch, Hamilton, Tauranga, Dunedin); university/service stepping-stone hubs[cite: 3]. | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Auckland`** | Finite ($J = 80/\Delta t$) | $34.1\%$ of HH | Primate metropolitan agglomeration ("Paris" analog); high wage variance ($\sigma_z = 0.24$), severely inelastic land ($\delta_H = 0.10$)[cite: 3, 11]. | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`Firm_Rural`** | Infinite ($N_j = \infty$) | $15.0\%$ of Firms | Primary/land-intensive producers ($z_f \in \lbrace 0.70, 1.15 \rbrace$) with annual trend growth $G_{\mathrm{ann}} = 1.007$[cite: 3, 17]. | `ValueFnIter_Case1` |
| **`Firm_Small`** | Infinite ($N_j = \infty$) | $23.0\%$ of Firms | Provincial processing, retail & trade enterprises ($z_f \in \lbrace 0.75, 1.28 \rbrace$) with $G_{\mathrm{ann}} = 1.011$[cite: 3, 17]. | `ValueFnIter_Case1` |
| **`Firm_Large`** | Infinite ($N_j = \infty$) | $26.9\%$ of Firms | Regional metro manufacturing, tech & service firms ($z_f \in \lbrace 0.83, 1.50 \rbrace$) with $G_{\mathrm{ann}} = 1.018$[cite: 3, 17]. | `ValueFnIter_Case1` |
| **`Firm_Auckland`** | Infinite ($N_j = \infty$) | $35.1\%$ of Firms | High-return knowledge & tradable scale-ups ($z_f \in \lbrace 0.90, 1.75 \rbrace$) with $G_{\mathrm{ann}} = 1.025$[cite: 3, 17]. | `ValueFnIter_Case1` |

---

## 2. Macro Demographic & Dynamic Regional Population Law of Motion
Following the NZ Treasury OLG demographic framework (Binning et al., 2024)[cite: 2], cohorts age across $J = \mathrm{round}\left(80 / \Delta t\right)$ brackets via $\Delta t$-period survival probabilities $s_j = \left(s_{j,\mathrm{ann}}\right)^{\Delta t}$, fertility rates $f_j$, and age-specific net migration flows[cite: 2]:

$$\mathbf{N}_t = \mathbf{T}_{t-1} \mathbf{N}_{t-1} + \mathbf{M}_{t-1}$$

Along the 60-year transition path ($t = 1, \dots, T_{\mathrm{trans}}$ where $T_{\mathrm{trans}} = \mathrm{round}\left(60 / \Delta t\right)$), the 4-region household population share vector $\mathbf{s}_{HH,t} = \lbrack s_{\mathrm{Rural},t}, s_{\mathrm{Small},t}, s_{\mathrm{Large},t}, s_{\mathrm{Auckland},t}\rbrack$ and firm share vector $\mathbf{s}_{F,t}$ evolve endogenously from their Stats NZ 2025 base (`[0.160, 0.240, 0.259, 0.341]` and `[0.150, 0.230, 0.269, 0.351]`) via the domestic youth sorting step rate $\nu_{\mathrm{dom}}\left(\Delta t\right) = 1 - \left(1 - 0.12\right)^{\Delta t / 5}$, the normalized $4 \times 4$ domestic migration submatrix $\Pi_{\mathrm{mig},t}^{\mathrm{dom}}$, and the international net migration inflow rate $\zeta_{\mathrm{inflow}}\left(\Delta t\right) = 1 - \left(1 - 0.085\right)^{\Delta t / 5}$ over destination shares $\mathbf{m}_{\mathrm{intl}} = \lbrack 0.115, 0.210, 0.270, 0.405\rbrack$[cite: 3]:

$$\tilde{\mathbf{s}}_{HH,t} = \left(1 - \nu_{\mathrm{dom}}\left(\Delta t\right)\right)\mathbf{s}_{HH,t} + \nu_{\mathrm{dom}}\left(\Delta t\right) \left(\mathbf{s}_{HH,t} \Pi_{\mathrm{mig},t}^{\mathrm{dom}}\right)$$

$$\mathbf{s}_{HH,t+1} = \frac{\left(1 - \zeta_{\mathrm{inflow}}\left(\Delta t\right)\right)\tilde{\mathbf{s}}_{HH,t} + \zeta_{\mathrm{inflow}}\left(\Delta t\right) \mathbf{m}_{\mathrm{intl}}}{\sum_{k=1}^4 \left\lbrack\left(1 - \zeta_{\mathrm{inflow}}\left(\Delta t\right)\right)\tilde{s}_{HH,k,t} + \zeta_{\mathrm{inflow}}\left(\Delta t\right) m_{\mathrm{intl},k}\right\rbrack}, \qquad \mathbf{s}_{F,t+1} = 0.85^{\Delta t / 5} \mathbf{s}_{F,t} + \left(1 - 0.85^{\Delta t / 5}\right) \mathbf{s}_{HH,t+1}$$

*(Full 60-year trajectory output to [`Table9_4Region_Dynamic_Population_Shares.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv))[cite: 3].*

---

## 3. Finite-Horizon Household Problem (Lenses 1, 2, and 3)
In the full 5D experience-asset specification a household of age $j \in \lbrace 1, \dots, J \rbrace$ in region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$ has state vector[cite: 3, 6, 15]:

$$\mathbf{s}_{HH} = \left(a, h, \theta_c, z, j; k\right)$$

where $a \in \mathcal{A}_{HH}$ ($n_a(1) = 61$ points) is consolidated net worth ($Q_k h_{\mathrm{house}} - b_{\mathrm{debt}}$)[cite: 8], $h \in \mathcal{H}$ ($n_a(2) = 7$ points) is adult human capital[cite: 4], $\theta_c \in \Theta_c$ ($n_a(3) = 9$ points) is the child's multi-stage skill experience asset[cite: 6, 15], and $z \in \mathcal{Z}_k$ ($n_z = 5$ points) is a region-specific Markov labor productivity shock[cite: 18, 20]. Decisions are $d = \left(i_c, \ell, I_h\right)$ (childhood skill investment, labor supply, and adult Ben-Porath training)[cite: 4, 6, 15].

### 3.1 Housing Tenure Choice, User Costs, and 4-Region Unbalanced Growth
Following Kiyotaki, Michaelides, and Nikolov (2024)[cite: 8] and Hirano and Toda (2025), let $Q_k$ denote the regional house price, $R_{\mathrm{ann}} = \left(1 + r\right)^{1/\Delta t}$ the gross annualized interest rate (where $r$ is the $\Delta t$-period interest rate), $\mu_{\mathrm{maint}} = 0.04$ annual maintenance/rates, $\upsilon_h = 0.008$ the owner-occupied tax wedge, and $G_{k,\mathrm{ann}}$ the regional annual trend growth factor ($G_{\mathrm{Auckland},\mathrm{ann}} = 1.025 > G_{\mathrm{Large},\mathrm{ann}} = 1.018 > G_{\mathrm{Small},\mathrm{ann}} = 1.011 > G_{\mathrm{Rural},\mathrm{ann}} = 1.007$)[cite: 3, 8]:

$$rr_k = \left(1 + \mu_{\mathrm{maint}} - \frac{G_{k,\mathrm{ann}}}{R_{\mathrm{ann}}}\right) Q_k, \qquad rh_k = \left(1 + \mu_{\mathrm{maint}} - \upsilon_h - \frac{G_{k,\mathrm{ann}}}{R_{\mathrm{ann}}}\right) Q_k$$

Young working households ($j < J_r$) draw an idiosyncratic rental utility penalty $\chi \sim U\lbrack 0, \bar{\chi}\rbrack$ ($\bar{\chi} = 2.55$), yielding the analytical regional homeownership share $\xi_k$ and composite housing price index $p_{H,k}\left(j\right)$[cite: 8]:

$$\xi_k = \min\left\lbrace 1, \frac{1}{\bar{\chi}} \left(\frac{rr_k}{rh_k}\right)\right\rbrace, \qquad p_{H,k}\left(j\right) = \begin{cases}
\xi_k rh_k + \left(1 - \xi_k\right) \frac{rr_k}{0.5 \bar{\chi}} & \text{if } j < J_r \\
rh_k & \text{if } j \ge J_r
\end{cases}$$

### 3.2 Two-Stage Childhood CES Skill Law of Motion (HumanCapital_Lifecycle_aprimeFn.m`) & Adult Ben-Porath Dynamics
* **Child Experience Asset ($\theta^{\prime}_c$):** Driven by private parental investment $i_c$, stage-specific public wraparound provision ($G_{\mathrm{ECE},1}$ during Stage 1 $j \in \mathcal{J}_{c,1}$ vs. $G_{\mathrm{ECE},2}$ during Stage 2 $j \in \mathcal{J}_{c,2}$), and Stone-Geary luxury floor $\bar{g}_{\mathrm{ECE}} = 0.02$[cite: 1, 6, 15]. When $\Delta t < 5$ so that Stage 1 spans $n_{s1} = \mathrm{round}\left(6/\Delta t\right)$ sub-periods and Stage 2 spans $n_{s2} = \mathrm{round}\left(12/\Delta t\right)$ sub-periods, the one-step transition maps onto the 6-year and 12-year cumulative CES operator via step weight $\omega_{s} = 1 / n_{s}$[cite: 1, 6]:

$$\theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},s}, \varphi_s\right) = \left\lbrack \gamma_{s,\mathrm{self}} \theta_c^{\varphi_s} + \gamma_{s,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},s} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_s} + \gamma_{s,\mathrm{par}} \bar{h}_p^{\varphi_s} \right\rbrack^{1/\varphi_s}$$

$$\theta^{\prime}_c = \begin{cases}
\left(1 - \omega_{s1}\right)\theta_c + \omega_{s1} \theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},1}, \varphi_1\right) & \text{if } j \in \mathcal{J}_{c,1} \text{ (First 2000 Days, } \varphi_1 = 0.35\text{)} \\
\left(1 - \omega_{s2}\right)\theta_c + \omega_{s2} \theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},2}, \varphi_2\right) & \text{if } j \in \mathcal{J}_{c,2} \text{ (School Years, } \varphi_2 = -0.95\text{)} \\
\theta_c & \text{otherwise}
\end{cases}$$

* **Adult Ben-Porath Human Capital ($h^{\prime}$):** During working ages ($j < J_r$), adult skill evolves over $\Delta t$ years with depreciation $\delta_{hc}\left(\Delta t\right) = 1 - \left(1 - \delta_{hc,\mathrm{ann}}\right)^{\Delta t}$ and training elasticities $\alpha_I = 0.090, \alpha_H = 0.064$[cite: 4]:

$$h^{\prime} = \left(1 - \delta_{hc}\left(\Delta t\right)\right) h + \left(\frac{\Delta t}{5}\right) \mathbb{I}\left(\ell > 0\right) I_h^{\alpha_I} h^{\alpha_H}$$

### Section 3.3: Adolescent Family Unemployment Stress and Bidirectional Montessori Cross-Age Mentoring
In the baseline two-stage Cunha–Heckman–Schennach skill technology (HumanCapital_Lifecycle_aprimeFn.m`), childhood skill $\theta_c$ evolves across Stage 1 ($\mathcal{J}_{c,1}$, ages 0–5, where $\varphi_1 = 0.35 > 0$) and Stage 2 ($\mathcal{J}_{c,2}$, ages 6–17, where $\varphi_2 = -0.95 < 0$)[cite: 6]:

$$\theta^{\prime}_c = \begin{cases}
\left\lbrack \gamma_{1,\mathrm{self}} \theta_c^{\varphi_1} + \gamma_{1,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},1}^{\mathrm{eff}} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_1} + \gamma_{1,\mathrm{par}} \bar{h}_p^{\varphi_1} \right\rbrack^{1/\varphi_1} & \text{if } j \in \mathcal{J}_{c,1} \\
\left\lbrack \gamma_{2,\mathrm{self}} \theta_c^{\varphi_2} + \gamma_{2,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},2}^{\mathrm{eff}} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_2} + \gamma_{2,\mathrm{par}} \bar{h}_p^{\varphi_2} \right\rbrack^{1/\varphi_2} \exp\left(\Psi_{J=5}\left(z_p, a_p, M_{\mathrm{mont}}\right)\right) & \text{if } j \in \mathcal{J}_{c,2} \\
\theta_c & \text{otherwise}
\end{cases}$$

Because Stage 2 exhibits strong dynamic complementarity ($\sigma_2 = \frac{1}{1 - \varphi_2} = 0.51 < 1$), early skill gains $\theta_c$ accumulated during the First 2,000 Days ($j \in \mathcal{J}_{c,1}$) are vulnerable to fade-out if household investments or socio-emotional stability collapse during early adolescence ($J = 5$, child ages 12–14)[cite: 6, 7]. We formalize two countervailing mechanisms operating at this gate:

1. **Observable Family Unemployment & Housing Distress Shock ($\psi_{\mathrm{unemp}}$):**
   Following the empirical job-displacement and *Family Stress Model* literature (Conger et al., 1992; Rege, Telle, & Votruba, 2011; Coelli, 2011; *Growing Up in New Zealand* "Now We Are 12", Morton et al., 2024), when a parent in region $k$ experiences an adverse labor-market productivity/unemployment realization $z_p \in \mathcal{Z}_{\mathrm{distress}}$ (specifically $z_p = z_1$, or $z_p = z_2$ combined with housing hardship $a_p < 0.08 Q_k$) during the child's adolescent window, household psychological stress and reduced parental supervision impose a non-cognitive skill penalty $-\psi_{\mathrm{unemp}} < 0$[cite: 6, 8].

2. **Bidirectional Montessori Cross-Age Peer Mentoring ($M_{\mathrm{mont}} \in \lbrack 0, 1\rbrack$):**
   While Stage 2 cognitive investment productivity is low ($\gamma_{2,C,3} = 0.044$), non-cognitive malleability remains more than twice as high ($\gamma_{2,N,3} = 0.104$, Cunha et al., 2010)[cite: 17]. Drawing on Montessori's multi-age *Erdkinder* pedagogy (Lillard & Else-Quest, 2006; Lillard et al., 2017), endogenous peer-spillover CES technologies (Agostinelli, Saharkhiz, & Wiswall, 2024), and adolescent mentoring RCTs (Yeager, Dahl, & Dweck, 2018; Resnjanskij, Ruhose, Wiederhold, & Woessmann, 2024), structured cross-age mentoring where adolescents at $J = 5$ mentor younger children at $J = 2\text{--}3$ generates a **two-way intra-generational spillover** without adding an endogenous state variable:
   * **Downward Scaffolding Multiplier on Stage 1 ($\kappa_{\mathrm{down}} > 0$):** Near-peer tutoring and role-modeling by the adolescent cohort (with mean skill $\bar{\theta}_{J=5}$) augment the effective productivity of public early childhood and primary investments:

$$G_{\mathrm{ECE},1}^{\mathrm{eff}} = G_{\mathrm{ECE},1} \left(1 + \kappa_{\mathrm{down}} M_{\mathrm{mont}} \bar{\theta}_{J=5}\right)$$

   * **Upward "Protégé Effect" & Stress Buffer on Stage 2 ($\kappa_{\mathrm{up}} > 0$):** Serving as a high-agency mentor builds adolescent executive function, self-regulation, and social purpose, directly buffering the family unemployment shock and locking in ("banking") Stage 1 skill gains via the adolescent net shift $\Psi_{J=5}$:

$$\Psi_{J=5}\left(z_p, a_p, M_{\mathrm{mont}}\right) = -\psi_{\mathrm{unemp}} \mathbb{I}\left(z_p \in \mathcal{Z}_{\mathrm{distress}}\right) \left(1 - \zeta_{\mathrm{buf}} M_{\mathrm{mont}}\right) + \kappa_{\mathrm{up}} M_{\mathrm{mont}}$$

   In the compact 4D projection (`Build_IntergenTransitionMatrix.m` and `Plot_ChildFates_2Panel_SSankey.m`), this induces the unified anchored log-skill transition mean across the 7-point adult human capital grid $h_{\mathrm{child}} \in \mathcal{H}$[cite: 6, 8]:

$$\mu_{\ln h}\left(h_p, i_c, z_p, a_p; k\right) = \rho_{hc} \ln\left(h_p\right) + \gamma_{ic} \ln\left(\frac{i_c + G_{\mathrm{ECE},1}^{\mathrm{eff}} + \bar{g}_{\mathrm{ECE}}}{\bar{i}_c + G_{\mathrm{ECE},\mathrm{base}} + \bar{g}_{\mathrm{ECE}}}\right) - \psi_{\mathrm{crowd}} \ln\left(\max\left(1, Q_k\right)\right) \mathbb{I}\left(a_p < 0.08 Q_k\right) + \Psi_{J=5}\left(z_p, a_p, M_{\mathrm{mont}}\right) + \alpha_{\mathrm{grid}}$$

### 3.4 Budget Constraint, "Income x Geography" Transfer, and Recursive Bellman Equation
Total household disposable cash-on-hand before consumption and child investment in region $k$ is[cite: 8, 11, 15, 18]:

$$y_{\mathrm{disp},k} = \left(1 + r\left(1 - \tau_k\right)\right) a + \left(1 - \tau_a\right)^{\Delta t} a - a + \left(1 - \tau_l\right) w_k h z \ell + T_k\left(w_k h z \ell\right) + \mathbb{I}\left(j = 1\right) E + \mathbb{I}\left(j \ge J_r\right) P_{\mathrm{super}}$$

where $T_k\left(y\right) = m_k \bar{y} \frac{2 \exp\left(-\xi_{\mathrm{phase}} \left(y / \bar{y}\right)\right)}{1 + \exp\left(-\xi_{\mathrm{phase}} \left(y / \bar{y}\right)\right)}$ is the **Income $\times$ Geography** transfer rule (Ferriere et al. / Labrousse & Perdereau, 2025)[cite: 11, 21]. Deducting savings $a^{\prime}$, private child investment $i_c$, and mandatory regional fuel/transport subsistence $\bar{e}_k$ yields net expenditure $e_{\mathrm{net}} = y_{\mathrm{disp},k} - a^{\prime} - i_c - \bar{e}_k > 0$, which splits via Cobb-Douglas share $\phi_{nd} = 0.78$ into non-durable consumption $c_{nd} = \phi_{nd} e_{\mathrm{net}}$ and housing services $c_H = \left(1 - \phi_{nd}\right) e_{\mathrm{net}} / p_{H,k}\left(j\right)$, forming composite consumption $u_{\mathrm{comp}} = c_{nd}^{\phi_{nd}} c_H^{1 - \phi_{nd}}$[cite: 8, 11].

The household Bellman equation in region $k$ with discount factor $\beta_{hh}\left(\Delta t\right) = \beta_{\mathrm{ann}}^{\Delta t}$ solves[cite: 1, 6, 8, 15, 18]:

$$V_k\left(a, h, \theta_c, z, j\right) = \max_{i_c, \ell, I_h, a^{\prime}, h^{\prime}} \left\lbrace \frac{u_{\mathrm{comp}}^{1 - \eta_c}}{1 - \eta_c} - \psi_l \frac{\ell^2}{2} + X_t + \Phi_{\mathrm{child}}\left(i_c, \theta^{\prime}_c, j\right) + \Phi_{\mathrm{ret}}\left(a^{\prime}, \mathrm{Frac}_{\mathrm{stunted}}, S_t, j\right) + \beta_{hh}\left(\Delta t\right) s_j \sum_{z^{\prime}} \Pi_{z,k}\left(z^{\prime}\vert z\right) V_k\left(a^{\prime}, h^{\prime}, \theta^{\prime}_c, z^{\prime}, j+1\right) \right\rbrace$$

where retirees ($j \ge J_r$) derive relational altruism $\gamma_{\mathrm{rel}} \ln\left(1 - \mathrm{Frac}_{\mathrm{stunted}}\right) + \gamma_{\mathrm{coh}} \ln\left(S_t\right)$ and warm-glow luxury bequest utility $b_1 \frac{\left(b_2 + \left(1 - \tau_b\right)a^{\prime}\right)^{1 - \eta_c}}{1 - \eta_c}$ (De Nardi, 2004)[cite: 18].

---

## 4. Infinite-Horizon Firm Sector (The Guvenen et al. Engine Across 4 Regions)
In each region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$, a continuum of infinite-horizon entrepreneurs (`Firm_k`, $N_j = \infty$) with persistent talent $z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$ operates a constant-returns technology subject to collateral constraint $k \le \lambda_{\mathrm{col}} a_f$ ($\lambda_{\mathrm{col}} = 1.80$) and discount factor $\beta_{\mathrm{firm}}\left(\Delta t\right) = 0.95^{\Delta t}$[cite: 3, 17]:

$$V_{F,k}\left(a_f, z_f\right) = \max_{a^{\prime}_f \in \lbrack 0, R_k\left(z_f; \Delta t\right) a_f\rbrack} \left\lbrace \ln\left( R_{k}\left(z_f; \Delta t\right) a_f - a^{\prime}_f \right) + \beta_{\mathrm{firm}}\left(\Delta t\right) \sum_{z^{\prime}_f} \Pi_{f,k}\left(z^{\prime}_f \vert z_f\right) V_{F,k}\left(a^{\prime}_f, z^{\prime}_f\right) \right\rbrace$$

where the $\Delta t$-period gross after-tax return on entrepreneurial equity $R_k\left(z_f; \Delta t\right)$ is[cite: 17]:

$$R_k\left(z_f; \Delta t\right) = \left(1 - \tau_a\right)^{\Delta t} + \left(1 - \tau_k\right) \left\lbrace r + \max\left(0, \alpha_k \left(\frac{1 - \alpha_k}{w_k}\right)^{\frac{1 - \alpha_k}{\alpha_k}} z_f - \left(r + \delta_k\left(\Delta t\right)\right) \right) \lambda_{\mathrm{col}} \right\rbrace$$

Replacing corporate/capital income taxation ($\tau_k$) with a book-value wealth tax ($\tau_a = 0.015$) shifts stationary firm net worth $\Gamma_k\left(a_f, z_f\right)$ toward high-talent entrepreneurs $z_{h,k}$ ($d\log Z / d\tau_a > 0$, Guvenen et al., 2023 Proposition 3)—with the largest productivity multiplier occurring in `Firm_Auckland` ($z_h = 1.75$, $35.1\%$ of NZ businesses) and `Firm_Large` ($z_h = 1.50$, $26.9\%$ of NZ businesses)[cite: 3, 17].

---

## 5. The 3-Stage Intergenerational & $4 \times 5$ Abroad Spatial Transition Operator ($\mathcal{T}_{\mathrm{IG}}$)
The stationary distribution of newborn households entering adulthood at $j=1$ in region $k$, denoted $\mu_{1,k}\left(a_1, h_1, z_1\right)$ (`jequaloneDist`), is computed as a fixed point of three coupled operators inside `Build_IntergenTransitionMatrix.m` (4D or 5D)[cite: 3]:

### Stage 1: Completed Childhood Skill Formation ($\mathbf{Q}_h$)
* In the 5D experience-asset model (covering emigration/immigration), completed Stage-2 childhood skill $\theta_3 = \theta_c\left(j = j_{\mathrm{launch}}\right)$ is extracted directly from parents reaching $j = j_{\mathrm{launch}}$ and mapped onto the child's adult human capital grid `a_grid_hc`, penalized by metropolitan housing crowding $\psi_{\mathrm{crowd}} \ln\left(Q_k\right)\mathbb{I}\left(a_p < 0.05 Q_k\right)$[cite: 6, 15].
* In the compact 4D projection, expected log skill integrates parental investments over $j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}$[cite: 6, 15]:

$$\ln\left(h_{\mathrm{child}}\right) = \rho_{hc} \ln\left(h_p\right) + \gamma_{ic} \ln\left(1 + \bar{i}_c\left(a_p, h_p, z_p, k\right) + G_{\mathrm{ECE}}\right) - \psi_{\mathrm{crowd}} \ln\left(Q_k\right) \mathbb{I}\left(a_p < 0.05 Q_k\right) + \eta_h, \qquad \eta_h \sim \mathcal{N}\left(0, \sigma_{hc}^2\right)$$

### Stage 2: The \$1.6T Property Bequest & Youth Grant Operator ($\mathbf{Q}_a$)
Dying retirees ($j \ge J_r$,weighted by mortality $1 - s_j$) in region $k$ leave net-of-tax property estates $\left(1 - \tau_b\right)a^{\prime}_j\left(k\right)$[cite: 18]. Combined with the universal Youth Capital Grant $E$ (`YouthGrant`), this induces the initial wealth distribution $P_{a,k}\left(a_1\right)$ (`MeanBequest.(reg)`)[cite: 3, 9].

### Stage 3: The $4 \times 5$ Domestic & International (`Abroad`) Gumbel Youth Sorting Matrix ($\Pi_{\mathrm{mig}}$)
Before settling into working life at $j=1$, young adults in origin region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$ evaluate the 4 domestic regions $m \in \lbrace 1, 2, 3, 4 \rbrace$ (paying moving/entry cost $\kappa\left(k, m\right)$) against the **5th outside option: emigrating to `Abroad` (Australia/OECD)** with value $V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right)$ and Gumbel scale $\varrho$:

$$\mathbb{P}_t\left(k \to m \mid a_1, h_1, z_1\right) = \frac{\exp\left(V_{m,t}\left(a_1 - \kappa\left(k,m\right), h_1, z_1, 1\right) / \varrho\right)}{\exp\left(V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho\right) + \sum_{r=1}^4 \exp\left(V_{r,t}\left(a_1 - \kappa\left(k,r\right), h_1, z_1, 1\right) / \varrho\right)}$$

$$P_{\mathrm{emig},t}\left(a_1, h_1, z_1; k\right) = \frac{\exp\left(V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho\right)}{\exp\left(V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho\right) + \sum_{r=1}^4 \exp\left(V_{r,t}\left(a_1 - \kappa\left(k,r\right), h_1, z_1, 1\right) / \varrho\right)}$$

---

## 6. Master 4-Region Calibration Table (Stats NZ 2025/2026 & Literature Benchmarks)

| Parameter | Symbol | Value (`Rural`, `Small`, `Large`, `Auckland`) | Target / Empirical Source |
| :--- | :--- | :--- | :--- |
| **Time Grid & Demographics** | | | |
| Period length switch (years) | $\Delta t$ (`dt`) | $3\ (default, J=27)$, $5\ (fast, J=16)$, $2$, or $1$ | Configured via `Configure_TimeGrid_Params.m` |
| Adult horizon & retirement index | $J, J_r$ | $\mathrm{round}\left(80/\Delta t\right), 1+\mathrm{round}\left(45/\Delta t\right)$ | Ages 20–99; NZ Super at age 65 ($16, 10$ at $\Delta t=5$; $27, 16$ at $\Delta t=3$)[cite: 1, 2, 3] |
| Regional Household Pop Shares (Base) | $\omega_{HH,k}$ | $0.160, 0.240, 0.259, 0.341$ | Stats NZ Subnational Pop Estimates (June 2025: Akl $= 34.1\%$)[cite: 3] |
| Regional Business Firm Shares (Base) | $\omega_{F,k}$ | $0.150, 0.230, 0.269, 0.351$ | Stats NZ Business Demography (Feb 2025: Akl $= 35.1\%$)[cite: 3] |
| Intl. Migration Inflow Shares | $\mathbf{m}_{\mathrm{intl}}$ | $0.115, 0.210, 0.270, 0.405$ | Stats NZ projection (Auckland share rises to $\sim 36.5\%$ by Year 30)[cite: 3] |
| Discount factors & CRRA curvature | $\beta_{hh}, \beta_{\mathrm{firm}}, \eta_c$ | $0.96^{\Delta t}, 0.95^{\Delta t}, 2.0$ | Standard OLG life-cycle benchmark[cite: 8, 15, 18] |
| **Lens 1: Two-Stage Child Skill Formation** | | | |
| Stage 1 (Ages 0–5) CES weights & $\varphi_1$ | $\gamma_{1,s}, \gamma_{1,i}, \gamma_{1,p}, \varphi_1$ | $0.53, 0.24, 0.23, 0.35$ | Cunha, Heckman, & Schennach (2010) Stage 1 estimates[cite: 6] |
| Stage 2 (Ages 6–17) CES weights & $\varphi_2$ | $\gamma_{2,s}, \gamma_{2,i}, \gamma_{2,p}, \varphi_2$ | $0.87, 0.07, 0.06, -0.95$ | Cunha et al. (2010) Stage 2 dynamic complementarity[cite: 6] |
| Public ECE Stage 1, Stage 2 & floor | $G_{\mathrm{ECE},1}, G_{\mathrm{ECE},2}, \bar{g}_{\mathrm{ECE}}$ | $0.045, 0.065, 0.020$ | Ferriere et al. luxury floor & NZ ECE baseline |
| Hyperbolic discount factor (Fertility) | $\beta_{\mathrm{hyp}}$ | $1.00$ (Base) vs. $0.72$ (No Commit) | Cao & Li / Laibson (1997) quasi-hyperbolic discounting[cite: 12] |
| **Lens 2: 4-Region Wages, Transport & Ben-Porath** | | | |
| Regional baseline wage levels | $w_k$ | $0.85, 0.93, 1.05, 1.18$ | Spatial wage gradient across NZ urban/rural hierarchy[cite: 3, 11] |
| Regional log-income AR(1) dispersion | $\sigma_z$ | $0.11, 0.14, 0.18, 0.24$ | Labrousse & Perdereau (2025) spatial income variance[cite: 11, 20] |
| Mandatory transport/energy subsistence | $\bar{e}_k$ | $0.048, 0.036, 0.022, 0.016$ | Step-down from Rural/Small towns to dense Auckland[cite: 11] |
| Baseline `Income x Geography` transfer | $T_k$ | $0.025, 0.020, 0.016, 0.014$ | Reforms scale to $0.038, 0.031, 0.025, 0.028$[cite: 11, 21] |
| Adult Ben-Porath depreciation & elasticities | $\delta_{hc,\mathrm{ann}}, \alpha_I, \alpha_H$ | $0.0180\text{/yr}, 0.090, 0.064$ | Fan, Seshadri, & Taber (2022) adult human capital[cite: 4] |
| **Lens 3: 4-Region Housing, Bequests & Firms** | | | |
| Regional baseline house prices | $Q_k$ | $1.05, 1.40, 2.05, 3.10$ | Metropolitan land overvaluation gradient[cite: 3, 8] |
| Regional housing supply elasticity | $\delta_H$ | $0.35, 0.28, 0.18, 0.10$ | Labrousse & Perdereau (2025) regional housing supply[cite: 11] |
| Regional annual trend growth factors | $G_{k,\mathrm{ann}}$ | $1.007, 1.011, 1.018, 1.025$ | Hirano & Toda (2025) unbalanced sectoral growth[cite: 3, 8] |
| Firm productivity ceilings ($z_\ell, z_h$) | $z_{f,k}$ | $\lbrack 0.70,1.15\rbrack, \lbrack 0.75,1.28\rbrack, \lbrack 0.83,1.50\rbrack, \lbrack 0.90,1.75\rbrack$ | Guvenen et al. (2023) heterogeneous firm returns[cite: 17] |
| Warm-glow bequest & Youth Grant (Base $\to$ Ref) | $b_1, b_2, E$ | $4.20, 0.45, 0.030 \to 0.065$ | De Nardi (2004) & Piketty/Saez youth endowment[cite: 9, 18] |

While our baseline calibration anchors the high-cost stunted cohort share to the 22.0% benchmark identified at age 3 in the 1972–73 Dunedin Study (Caspi et al., 2016),
contemporary longitudinal evidence from Growing Up in New Zealand (Morton et al., 2014, 2020) and official Child Poverty Related Indicators (Stats NZ / DPMC, 2024–2026) indicate that metropolitan housing overvaluation ($Q_{\text{Auckland}} = 3.10$) has widened early developmental vulnerability.
Nationally, 29.9% of children live below the After-Housing-Costs financial insecurity line (AHC60), 34%–37% live in households spending over 30% of disposable income on housing, and 37% of the GUiNZ cohort experienced damp or mouldy housing.
When the full metropolitan housing crowd-out penalty is activated, Auckland's vulnerable/stunted childhood trajectory expands from 22.0% to 36.6%—demonstrating how an unmitigated urban land bubble acts as an intergenerational tax on early human capital.

---

## 7. Complete 11-File VFI Toolkit Pipeline Manifest (4-Region + Abroad Suite)

All output CSV tables and 300-DPI PNG figures generated by this pipeline are archived in [`Output_NZ_4Region_Intergen`](Output_NZ_4Region_Intergen), with step-level `.mat` checkpoints stored in `Cache_NZ_Intergen`:

| # | File Name | Role in the Parameterized 4-Region + Abroad VFI Toolkit Pipeline |
| :--- | :--- | :--- |
| **1** | `Configure_TimeGrid_Params.m` | **Time-Grid Parameterizer:** Sets `Params.dt` ($\Delta t \in \lbrace 3, 5, 2, 1 \rbrace$) and computes $J, J_r, \mathcal{J}_{c,1}, \mathcal{J}_{c,2}, j_{\mathrm{launch}}, T_{\mathrm{trans}}$, and $\Delta t$-compounded rates. |
| **2** | `Run_All_NZ_Intergen_Suite.m` | **Master Runner:** Executes Steps 1–7 across all 4 regions (`Rural`, `Small`, `Large`, `Auckland`), manages `Cache_NZ_Intergen` checkpoints and 5D $\to$ 4D projection, and exports all CSV tables and PNG figures. |
| **3** | `NZ_4Region_Master.m` | **5D Baseline Master:** Initializes the 8 PTypes (4 Regions $\times$ Household/Firm) with Stats NZ 2025 weights (`[0.160, 0.240, 0.259, 0.341]`), `experienceasset = 1`, and dispatches `ValueFnIter_MixHorz_PType`. |
| **4** | `HumanCapital_Lifecycle_aprimeFn.m` | **Experience Asset Law of Motion:** Implements Cunha, Heckman & Schennach's two-stage CES skill production ($\varphi_1 = 0.35, \varphi_2 = -0.95$) across $\mathcal{J}_{c,1}$ and $\mathcal{J}_{c,2}$ on the GPU via `arrayfun`. |
| **5** | `ReturnFn_SpatialHH.m` | **5D Household Return Function:** Embeds Kiyotaki tenure choice, 4-region subsistence $\bar{e}_k$, Ben-Porath training, two-stage child altruism, and luxury bequests (scaled by $\Delta t / 5$). |
| **6** | `ReturnFn_SpatialHH_Compact4D.m` & `ReturnFn_Firm.m` | **Compact 4D Household & Infinite-Horizon Firm Return Functions:** Used for the 4 regional firm types (`N_j = Inf`) and Step 4 compact household projection. |
| **7** | `Build_IntergenTransitionMatrix.m` | **Unified 5D & 4D Intergenerational Operator:** Extracts completed Stage-2 skill $\theta_3$ at $j = j_{\mathrm{launch}}$, maps \$1.6T estates at $j \ge J_r$, and computes $4 \times 5$ domestic/Abroad Gumbel sorting. |
| **8** | `PolicyExperiment_LeeSeshadri_4Region.m` | **Stage Counterfactuals:** Runs `BM_Baseline`, `P0_Early_0to5`, `P1P2_Late_6to17`, `BN_FrontLoad`, and `P0_Plus_GrantE`; outputs [Table12A](Output_NZ_4Region_Intergen/Table12A_LeeSeshadri_4Region_IGE.csv), [Table12B](Output_NZ_4Region_Intergen/Table12B_LeeSeshadri_4Region_VarExpl.csv), [Table12C](Output_NZ_4Region_Intergen/Table12C_LeeSeshadri_4Region_Welfare.csv), and [FigE8](Output_NZ_4Region_Intergen/FigE8_LeeSeshadri_4Region_Counterfactuals.png). |
| **9** | `FertilityBargaining_Module.m` | **Fertility & Bargaining:** Evaluates childcare bargaining, hyperbolic discounting ($\beta_{\mathrm{hyp}} = 0.72$), differential fertility, and NZ Super tax rates; outputs [Table_Fert1](Output_NZ_4Region_Intergen/Table_Fert1_4Region_TFR_DiffFertility.csv), [Table_Fert2](Output_NZ_4Region_Intergen/Table_Fert2_4Region_Stunting_NZSuper.csv), and [FigFert](Output_NZ_4Region_Intergen/FigFert_4Region_Bargaining_Solvency.png). |
| **10** | `WelfareDecomposition_4Region.m` | **3-Way Welfare Decomposition:** Outputs the 4-region Daruich/Lee–Seshadri ([Table1](Output_NZ_4Region_Intergen/Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv)), Labrousse & Perdereau $4 \times 5$ quintile ([Table2](Output_NZ_4Region_Intergen/Table2_4Region_LabroussePerdereau_SpatialQuintiles.csv)), and Kiyotaki tenure cleavage ([Table3](Output_NZ_4Region_Intergen/Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv)) CE % tables. |
| **11** | `TransPath_4Region_Master.m` & `Calibrate_NZ_Moments.m` | **60-Year Transition & Dynamic Pop Weights:** Solves the $T_{\mathrm{trans}}$-period transition path with endogenous `PTypeWeights_path` ([Table9](Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv), [Table10](Output_NZ_4Region_Intergen/Table10_4Region_Abroad_BrainDrain_Cohesion.csv)), [Fig1](Output_NZ_4Region_Intergen/Fig1_Daruich_Cohort_Welfare_4Region.png), [Fig2](Output_NZ_4Region_Intergen/Fig2_Kiyotaki_Housing_Estates_4Region.png), and [Fig3](Output_NZ_4Region_Intergen/Fig3_BrainDrain_Cohesion_4Region.png). |

## 8. Literature References for Montessori Two-Way Mentoring

* **Agostinelli, F., Saharkhiz, M., & Wiswall, M. (2024).** *Home and School in the Development of Children: Peer Effects and Dynamic Complementarity.* Working Paper / Quantitative Economics.
* **Coelli, M. B. (2011).** *Parental Job Loss and the Post-Secondary Education Decisions of Youth.* *Economica*, 78(310), 354–377.
* **Conger, R. D., Conger, K. J., Elder, G. H., Lorenz, F. O., Simons, R. L., & Whitbeck, L. B. (1992).** *A Family Process Model of Economic Hardship and Adjustment of Early Adolescent Boys.* *Child Development*, 63(3), 526–541.
* **Heller, S. B., Shah, A. K., Guryan, J., Ludwig, J., Mullainathan, S., & Pollack, H. A. (2017).** *Thinking, Fast and Slow? Some Field Experiments to Reduce Crime and Dropouts in Chicago.* *Quarterly Journal of Economics*, 132(1), 1–54.
* **Johnson, R. C., & Jackson, C. K. (2019).** *Reducing Inequality through Dynamic Complementarity: Evidence from Head Start and Public School Spending.* *American Economic Review*, 109(12), 4165–4205.
* **Lillard, A. S., & Else-Quest, N. (2006).** *Evaluating Montessori Education.* *Science*, 313(5795), 1893–1894.
* **Lillard, A. S., Heise, M. J., Richey, E. M., Tong, X., Hart, A., & Bray, P. M. (2017).** *Montessori Preschool Elevates and Equalizes Child Outcomes: A Longitudinal Study.* *Frontiers in Psychology*, 8, 1783.
* **Morton, S. M. B., et al. (2024).** *Now We Are 12: Material Hardship and Adolescent Trajectories in Growing Up in New Zealand.* University of Auckland Centre for Longitudinal Research.
* **Newman, S., & Holupka, C. S. (2014).** *Housing Affordability and Investments in Children.* *Journal of Housing Economics*, 24, 89–100.
* **Rege, M., Telle, K., & Votruba, M. (2011).** *Parental Job Loss and Children's School Performance.* *Review of Economic Studies*, 78(4), 1462–1489.
* **Resnjanskij, S., Ruhose, J., Wiederhold, S., & Woessmann, L. (2024).** *Can Mentoring Alleviate Family Disadvantage in Adolescence? A Field Experiment to Improve Labor Market Prospects.* *Journal of Political Economy*, 132(3), 1013–1062.
* **Yeager, D. S., Dahl, R. E., & Dweck, C. S. (2018).** *Why Interventions to Influence Adolescent Behavior Often Fail but Could Succeed.* *Perspectives on Psychological Science*, 13(1), 101–122.
