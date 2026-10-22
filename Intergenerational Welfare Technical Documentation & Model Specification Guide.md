# DOCUMENT 2: Intergenerational Welfare Technical Documentation & Model Specification Guide
**A Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial OLG Model of Intergenerational Welfare, Housing Wealth, and Human Capital in New Zealand (Parameterized Period Length $\Delta t$)**[cite: 1, 5, 22]

---

## 1. Executive Overview & 8-PType GPU Computational Architecture
This specification guide documents the mathematical structure, $\Delta t$-parameterized time-grid equations, calibration mapping, post-hoc 6-gate fiscal accounting, and VFI Toolkit implementation for evaluating intergenerational welfare across **four domestic New Zealand geographic tiers** (**Rural**, **Small**, **Large**, **Auckland**) plus an endogenous **Abroad** (Australia/OECD) emigration margin[cite: 5, 11, 20, 22]. The framework integrates three coupled life-cycle and macroeconomic lenses[cite: 8, 35]:
1. **Lens 1: Childhood Skill Formation (First 2000 Days & Adolescent Gate):** Anchored cognitive and noncognitive skill production (`ChildCES_aprimeFn.m`), public in-kind provision of luxury goods with "pro-equality" externalities, and Two-Way Montessori Cross-Age Peer Mentoring at the early-adolescent vulnerability gate ($J=5$, ages 12–14)[cite: 8, 9, 20, 35, 43].
2. **Lens 2: The Active Working Generation:** Quantity-quality fertility and cooperative childcare bargaining (`FertilityBargaining_Module.m`), adult Ben-Porath human capital maintenance and part-time/full-time labor supply, and the young renter vs. leveraged homeowner tenure cleavage[cite: 8, 15, 16, 35].
3. **Lens 3: Retirement, The NZD 1.6T Property Transfer, and Capital Allocation:** Universal pension fiscal dynamics, luxury bequest motives and estate taxation, unbalanced sectoral growth driving metropolitan land overvaluation, "use-it-or-lose-it" wealth taxation on heterogeneous-return firms, and the **2050 Sovereign Debt-Sinking & Public Reinvestment Protocol**[cite: 2, 8, 20, 31, 32, 35].

```text
+-----------------------------------------------------------------------------------+  
|                        THE UNIFIED INTERGENERATIONAL LOOP                         |  
|                                                                                   |  
|  [LENS 1: CHILDHOOD & ADOLESCENCE (Ages 0-19)]                                    |  
|   * Gate 1-2 (Ages 0-5): Private (i_c) + Public Wraparound (G_ECE) + Luxury Floor |  
|   * Gate 3 (Ages 12-14): Unemp Stress vs Two-Way Montessori Cross-Age Mentoring   |  
|         |                                                       ^                 |  
|         v (Determines Adult Skill Tier h_1..h_7 & Stunting)     |                 |  
|  [LENS 2: ACTIVE WORKING GENERATION (Ages 20-64)]               | (Funds Youth    |  
|   * 4x5 Spatial Sorting: Rural, Small, Large, Auckland, Abroad  |  Grant E &      |  
|   * Housing Tenure Cleavage: Young Renters vs Leveraged Owners  |  Public G_ECE)  |  
|   * Adult Ben-Porath Skill Maintenance (I_h) & Fertility        |                 |  
|         |                                                       |                 |  
|         v (Accumulates Property/Financial Net Worth & Pays Tax) |                 |  
|  [LENS 3: RETIREMENT, NZD 1.6T TRANSFER & 2050 PROTOCOL (65+)]  |                 |  
|   * Universal PAYG NZ Superannuation + Consumption Floor        |                 |  
|   * NZD 1.6T Property Estate Transfer (Taxed at tau_b) ---------+                 |  
|   * Guvenen "Use-It-or-Lose-It" Wealth Tax (tau_a) -> Reallocates K to z_h Firms  |  
|   * 50/50 Reform Surplus Split -> 2050 Debt-Sinking Fund & Infra/NZSF Pool        |  
+-----------------------------------------------------------------------------------+
```

### 1.1 Parameterized Time Period Length ($\Delta t \in \lbrace 5, 3, 2, 1 \rbrace$ Years)
To allow researchers to trade off execution speed against life-cycle and early-childhood granularity without altering structural equations, the model is parameterized by the period length $\Delta t$ (`Params.dt`, configured via `Configure_TimeGrid_Params.m`)[cite: 7]:
* **Adult Life-Cycle Horizon ($J$):** Economic adulthood spans 80 years from age 20 to age 99 across $J = \mathrm{round}\left(80 / \Delta t\right)$ periods ($J = 16$ for $\Delta t = 5$; $J = 27$ for $\Delta t = 3$; $J = 40$ for $\Delta t = 2$)[cite: 5, 7].
* **NZ Superannuation Retirement Boundary ($J_r$):** Mandatory retirement at age 65 (after 45 working years) begins at period $J_r = 1 + \mathrm{round}\left(45 / \Delta t\right)$ ($J_r = 10$ for $\Delta t = 5$; $J_r = 16$ for $\Delta t = 3$; $J_r = 23$ for $\Delta t = 2$)[cite: 5, 7].
* **Childhood & Adolescent Development Windows ($\mathcal{J}_{c,1}, \mathcal{J}_{c,2}$):** Given parental age index at childbirth $j_{\mathrm{birth}} = 1 + \mathrm{round}\left(6 / \Delta t\right)$, the **First 2000 Days** (child ages 0–5, 6 years; Gate 2, $J=2\text{--}3$ in child timeline) span $n_{s1} = \max\left(1, \mathrm{round}\left(6 / \Delta t\right)\right)$ periods $\mathcal{J}_{c,1} = \lbrace j_{\mathrm{birth}}, \dots, j_{\mathrm{birth}} + n_{s1} - 1 \rbrace$, and **Primary/Secondary Schooling & Early Adolescence** (child ages 6–17, 12 years; including the Ages 12–14 Adolescent Gate at $J=5$) span $n_{s2} = \max\left(1, \mathrm{round}\left(12 / \Delta t\right)\right)$ periods $\mathcal{J}_{c,2} = \lbrace j_{\mathrm{birth}} + n_{s1}, \dots, j_{\mathrm{birth}} + n_{s1} + n_{s2} - 1 \rbrace$, with completed childhood skill extracted at $j_{\mathrm{launch}} = j_{\mathrm{birth}} + n_{s1} + n_{s2}$ (Child $J=6\text{--}7$, Age 20)[cite: 7, 11, 20, 22, 43].

### 1.2 The 8 Permanent Types (`Names_i`) Dispatched on the GPU
To capture heterogeneous life-cycle households and collateral-constrained entrepreneurial firms across all four domestic regions without expanding individual grid dimensions, the model dispatches **8 Permanent Types (`Names_i`)** sequentially on the GPU[cite: 5, 11]:

| Permanent Type (`Names_i`) | Horizon ($N_j$) | Pop / Firm Share (2025 Base) | Economic Role & Spatial Domain | VFI Toolkit Solver Dispatched |
| :--- | :--- | :---: | :--- | :--- |
| **`HH_Rural`** | Finite ($J = 80/\Delta t$) | $16.0\%$ of HH | Rural & primary districts; elastic land ($\delta_H = 0.35$), high fuel/transport burden ($\bar{e} = 0.048$)[cite: 5, 11, 39]. | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Small`** | Finite ($J = 80/\Delta t$) | $24.0\%$ of HH | Small/medium provincial towns (<100k); compressed middle wages, elevated transport cost ($\bar{e} = 0.036$)[cite: 5, 11, 39]. | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Large`** | Finite ($J = 80/\Delta t$) | $25.9\%$ of HH | Non-Auckland major metros (>100k: Wgtn, Chch, Hamilton, Tauranga, Dunedin); university/service stepping-stone hubs[cite: 5, 11, 39]. | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Auckland`** | Finite ($J = 80/\Delta t$) | $34.1\%$ of HH | Primate metropolitan agglomeration ("Paris" analog); high wage variance ($\sigma_z = 0.24$), severely inelastic land ($\delta_H = 0.10$)[cite: 5, 11, 26, 39]. | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`Firm_Rural`** | Infinite ($N_j = \infty$) | $15.0\%$ of Firms | Primary/land-intensive producers ($z_f \in \lbrace 0.70, 1.15 \rbrace$) with annual trend growth $G_{\mathrm{ann}} = 1.007$[cite: 5, 11]. | `ValueFnIter_Case1` |
| **`Firm_Small`** | Infinite ($N_j = \infty$) | $23.0\%$ of Firms | Provincial processing, retail & trade enterprises ($z_f \in \lbrace 0.75, 1.28 \rbrace$) with $G_{\mathrm{ann}} = 1.011$[cite: 5, 11]. | `ValueFnIter_Case1` |
| **`Firm_Large`** | Infinite ($N_j = \infty$) | $26.9\%$ of Firms | Regional metro manufacturing, tech & service firms ($z_f \in \lbrace 0.83, 1.50 \rbrace$) with $G_{\mathrm{ann}} = 1.018$[cite: 5, 11]. | `ValueFnIter_Case1` |
| **`Firm_Auckland`** | Infinite ($N_j = \infty$) | $35.1\%$ of Firms | High-return knowledge & tradable scale-ups ($z_f \in \lbrace 0.90, 1.75 \rbrace$) with $G_{\mathrm{ann}} = 1.025$[cite: 5, 11, 14]. | `ValueFnIter_Case1` |

---

## 2. Macro Demographic & Dynamic Regional Population Law of Motion
Following the NZ Treasury OLG demographic framework (Binning et al., 2024)[cite: 12], cohorts age across $J = \mathrm{round}\left(80 / \Delta t\right)$ brackets via $\Delta t$-period survival probabilities $s_j = \left(s_{j,\mathrm{ann}}\right)^{\Delta t}$, fertility rates $f_j$, and age-specific net migration flows[cite: 5, 12]:

$$\mathbf{N}_t = \mathbf{T}_{t-1} \mathbf{N}_{t-1} + \mathbf{M}_{t-1}$$

Along the 60-year transition path ($t = 1, \dots, T_{\mathrm{trans}}$ where $T_{\mathrm{trans}} = \mathrm{round}\left(60 / \Delta t\right)$), the 4-region household population share vector $\mathbf{s}_{HH,t} = \lbrack s_{\mathrm{Rural},t}, s_{\mathrm{Small},t}, s_{\mathrm{Large},t}, s_{\mathrm{Auckland},t}\rbrack$ and firm share vector $\mathbf{s}_{F,t}$ evolve endogenously from their Stats NZ 2025 base (`[0.160, 0.240, 0.259, 0.341]` and `[0.150, 0.230, 0.269, 0.351]`) via the domestic youth sorting step rate $\nu_{\mathrm{dom}}\left(\Delta t\right) = 1 - \left(1 - 0.12\right)^{\Delta t / 5}$, the normalized $4 \times 4$ domestic migration submatrix $\Pi_{\mathrm{mig},t}^{\mathrm{dom}}$, and the international net migration inflow rate $\zeta_{\mathrm{inflow}}\left(\Delta t\right) = 1 - \left(1 - 0.085\right)^{\Delta t / 5}$ over destination shares $\mathbf{m}_{\mathrm{intl}} = \lbrack 0.115, 0.210, 0.270, 0.405\rbrack$[cite: 5, 11]:

$$\tilde{\mathbf{s}}_{HH,t} = \left(1 - \nu_{\mathrm{dom}}\left(\Delta t\right)\right)\mathbf{s}_{HH,t} + \nu_{\mathrm{dom}}\left(\Delta t\right) \left(\mathbf{s}_{HH,t} \Pi_{\mathrm{mig},t}^{\mathrm{dom}}\right)$$

$$\mathbf{s}_{HH,t+1} = \frac{\left(1 - \zeta_{\mathrm{inflow}}\left(\Delta t\right)\right)\tilde{\mathbf{s}}_{HH,t} + \zeta_{\mathrm{inflow}}\left(\Delta t\right) \mathbf{m}_{\mathrm{intl}}}{\sum_{k=1}^4 \left\lbrack\left(1 - \zeta_{\mathrm{inflow}}\left(\Delta t\right)\right)\tilde{s}_{HH,k,t} + \zeta_{\mathrm{inflow}}\left(\Delta t\right) m_{\mathrm{intl},k}\right\rbrack}, \qquad \mathbf{s}_{F,t+1} = 0.85^{\Delta t / 5} \mathbf{s}_{F,t} + \left(1 - 0.85^{\Delta t / 5}\right) \mathbf{s}_{HH,t+1}$$

*(Full 60-year trajectory output to [`Table9_4Region_Dynamic_Population_Shares.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv))[cite: 11].*

---

## 3. Finite-Horizon Household Problem (Lenses 1, 2, and 3)
In the full 5D experience-asset specification (`UpgradeB`), a household of age $j \in \lbrace 1, \dots, J \rbrace$ in region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$ has state vector[cite: 5, 11]:

$$\mathbf{s}_{HH} = \left(a, h, \theta_c, z, j; k\right)$$

where $a \in \mathcal{A}_{HH}$ ($n_a(1) = 61$ points) is consolidated net worth ($Q_k h_{\mathrm{house}} - b_{\mathrm{debt}}$)[cite: 5, 15], $h \in \mathcal{H}$ ($n_a(2) = 7$ points) is adult human capital[cite: 5, 35], $\theta_c \in \Theta_c$ ($n_a(3) = 9$ points) is the child's multi-stage skill experience asset[cite: 5, 9, 11], and $z \in \mathcal{Z}_k$ ($n_z = 5$ points) is a region-specific Markov labor productivity shock[cite: 5]. Decisions are $d = \left(i_c, \ell, I_h\right)$ (childhood skill investment, labor supply, and adult Ben-Porath training)[cite: 5, 19, 35].

### 3.1 Housing Tenure Choice, User Costs, and 4-Region Unbalanced Growth
Following Kiyotaki, Michaelides, and Nikolov (2024) and Hirano and Toda (2025)[cite: 11, 15, 32], let $Q_k$ denote the regional house price, $R_{\mathrm{ann}} = \left(1 + r\right)^{1/\Delta t}$ the gross annualized interest rate (where $r$ is the $\Delta t$-period interest rate), $\mu_{\mathrm{maint}} = 0.04$ annual maintenance/rates, $\upsilon_h = 0.008$ the owner-occupied tax wedge, and $G_{k,\mathrm{ann}}$ the regional annual trend growth factor ($G_{\mathrm{Auckland},\mathrm{ann}} = 1.025 > G_{\mathrm{Large},\mathrm{ann}} = 1.018 > G_{\mathrm{Small},\mathrm{ann}} = 1.011 > G_{\mathrm{Rural},\mathrm{ann}} = 1.007$)[cite: 11]:

$$rr_k = \left(1 + \mu_{\mathrm{maint}} - \frac{G_{k,\mathrm{ann}}}{R_{\mathrm{ann}}}\right) Q_k, \qquad rh_k = \left(1 + \mu_{\mathrm{maint}} - \upsilon_h - \frac{G_{k,\mathrm{ann}}}{R_{\mathrm{ann}}}\right) Q_k$$

Young working households ($j < J_r$) draw an idiosyncratic rental utility penalty $\chi \sim U\lbrack 0, \bar{\chi}\rbrack$ ($\bar{\chi} = 2.55$), yielding the analytical regional homeownership share $\xi_k$ and composite housing price index $p_{H,k}\left(j\right)$[cite: 15]:

$$\xi_k = \min\left\lbrace 1, \frac{1}{\bar{\chi}} \left(\frac{rr_k}{rh_k}\right)\right\rbrace, \qquad p_{H,k}\left(j\right) = \begin{cases}
\xi_k rh_k + \left(1 - \xi_k\right) \frac{rr_k}{0.5 \bar{\chi}} & \text{if } j < J_r \\
rh_k & \text{if } j \ge J_r
\end{cases}$$

### 3.2 Two-Stage Childhood CES Skill Law (`ChildCES_aprimeFn.m`), The Adolescent Gate ($J=5$), & Adult Ben-Porath Dynamics
* **Child Experience Asset ($\theta^{\prime}_c$):** Driven by private parental investment $i_c$, stage-specific public wraparound provision ($G_{\mathrm{ECE},1}$ during Stage 1 $j \in \mathcal{J}_{c,1}$ vs. $G_{\mathrm{ECE},2}$ during Stage 2 $j \in \mathcal{J}_{c,2}$), and Stone-Geary luxury floor $\bar{g}_{\mathrm{ECE}} = 0.02$[cite: 9, 10, 21, 35]. When $\Delta t < 5$ so that Stage 1 spans $n_{s1} = \mathrm{round}\left(6/\Delta t\right)$ sub-periods and Stage 2 spans $n_{s2} = \mathrm{round}\left(12/\Delta t\right)$ sub-periods, the one-step transition maps onto the 6-year and 12-year cumulative CES operator via step weight $\omega_{s} = 1 / n_{s}$[cite: 7, 9, 22]:

$$\theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},s}, \varphi_s\right) = \left\lbrack \gamma_{s,\mathrm{self}} \theta_c^{\varphi_s} + \gamma_{s,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},s} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_s} + \gamma_{s,\mathrm{par}} \bar{h}_p^{\varphi_s} \right\rbrack^{1/\varphi_s}$$

$$\theta^{\prime}_c = \begin{cases}
\left(1 - \omega_{s1}\right)\theta_c + \omega_{s1} \theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},1}, \varphi_1\right) & \text{if } j \in \mathcal{J}_{c,1} \text{ (First 2000 Days, } \varphi_1 = 0.35\text{)} \\
\left(1 - \omega_{s2}\right)\theta_c + \omega_{s2} \theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},2}, \varphi_2\right) & \text{if } j \in \mathcal{J}_{c,2} \text{ (School Years, } \varphi_2 = -0.95\text{)} \\
\theta_c & \text{otherwise}
\end{cases}$$

* **The Early-Adolescent Gate (Ages 12–14, Child $J=5$) & Two-Way Montessori Cross-Age Mentoring:** During Stage 2 ($\mathcal{J}_{c,2}$), adolescents in households experiencing unemployment or acute hardship stress (`iz == 1` or `iz == 2 && is_hardship`) face an unbuffered skill-erosion shock $\Delta \ln\left(h_{\mathrm{adol}}\right) = -0.22$ and immediate service-cost risk across Exits 1, 2, and 4[cite: 20, 43]. Conversely, **Two-Way Montessori Cross-Age Peer Mentoring** buffers vulnerable mentees while consolidating executive function in $h_6\text{--}h_7$ peer mentors ($\Delta \ln\left(h_{\mathrm{adol}}\right) = +0.05$ in $\mathrm{SS}_0$, rising to $+0.11$ in $\mathrm{SS}_1$ alongside effective wraparound amplification $G_{\mathrm{ECE,eff}} = 1.15 \times G_{\mathrm{ECE}}$)[cite: 20, 43].
* **Adult Ben-Porath Human Capital ($h^{\prime}$):** During working ages ($j < J_r$), adult skill evolves over $\Delta t$ years with depreciation $\delta_{hc}\left(\Delta t\right) = 1 - \left(1 - \delta_{hc,\mathrm{ann}}\right)^{\Delta t}$ and training elasticities $\alpha_I = 0.090, \alpha_H = 0.064$ (unified with childhood CES inside `HumanCapital_Lifecycle_aprimeFn.m`)[cite: 9, 16, 35]:

$$h^{\prime} = \left(1 - \delta_{hc}\left(\Delta t\right)\right) h + \left(\frac{\Delta t}{5}\right) \mathbb{I}\left(\ell > 0\right) I_h^{\alpha_I} h^{\alpha_H}$$

### 3.3 Budget Constraint, "Income x Geography" Transfer, and Recursive Bellman Equation
Total household disposable cash-on-hand before consumption and child investment in region $k$ is[cite: 20, 26, 39]:

$$y_{\mathrm{disp},k} = \left(1 + r\left(1 - \tau_k\right)\right) a + \left(1 - \tau_a\right)^{\Delta t} a - a + \left(1 - \tau_l\right) w_k h z \max\left(0, \ell - I_h\right) + T_k\left(w_k h z \ell\right) + \mathbb{I}\left(j = 1\right) E + \mathbb{I}\left(j \ge J_r\right) P_{\mathrm{super}}$$

where $T_k\left(y\right) = m_k \bar{y} \frac{2 \exp\left(-\xi_{\mathrm{phase}} \left(y / \bar{y}\right)\right)}{1 + \exp\left(-\xi_{\mathrm{phase}} \left(y / \bar{y}\right)\right)}$ is the **Income $\times$ Geography** transfer rule (Ferriere et al. / Labrousse & Perdereau, 2025)[cite: 21, 26, 30, 39]. Deducting savings $a^{\prime}$, net-of-subsidy private child investment $\left(1 - s_{\mathrm{sub}}\right)i_c$, and mandatory regional fuel/transport subsistence $\bar{e}_k$ yields net expenditure $e_{\mathrm{net}} = \frac{y_{\mathrm{disp},k} - a^{\prime} - \left(1 - s_{\mathrm{sub}}\right)i_c - \bar{e}_k}{1 + \tau_c} > 0$, which splits via Cobb-Douglas share $\phi_{nd} = 0.78$ into non-durable consumption $c_{nd} = \phi_{nd} e_{\mathrm{net}}$ and housing services $c_H = \left(1 - \phi_{nd}\right) e_{\mathrm{net}} / p_{H,k}\left(j\right)$, forming composite consumption $u_{\mathrm{comp}} = c_{nd}^{\phi_{nd}} c_H^{1 - \phi_{nd}}$[cite: 15, 20, 39].

The household Bellman equation in region $k$ with discount factor $\beta_{hh}\left(\Delta t\right) = \beta_{\mathrm{ann}}^{\Delta t}$ (and optional quasi-hyperbolic fertility factor $\beta_{\mathrm{hyp}} \in \lbrace 0.72, 1.00 \rbrace$ in `FertilityBargaining_Module.m`)[cite: 36, 44, 45] solves:

$$V_k\left(a, h, \theta_c, z, j\right) = \max_{i_c, \ell, I_h, a^{\prime}, h^{\prime}} \left\lbrace \frac{u_{\mathrm{comp}}^{1 - \eta_c}}{1 - \eta_c} - \psi_l \frac{\ell^2}{2} + X_t + \Phi_{\mathrm{child}}\left(i_c, \theta^{\prime}_c, j\right) + \Phi_{\mathrm{ret}}\left(a^{\prime}, \mathrm{Frac}_{\mathrm{stunted}}, S_t, j\right) + \beta_{hh}\left(\Delta t\right) s_j \sum_{z^{\prime}} \Pi_{z,k}\left(z^{\prime}\vert z\right) V_k\left(a^{\prime}, h^{\prime}, \theta^{\prime}_c, z^{\prime}, j+1\right) \right\rbrace$$

where the intergenerational linkage terms are:
* **Luxury Child Investment & Pro-Equality Externality ($X_t, \Phi_{\mathrm{child}}$):** Following Labrousse and Perdereau and Ferriere et al., early childhood investment is a luxury good ($\bar{g}_{\mathrm{ECE}} > 0$) combining private parental spending $i_c$ and public in-kind provision $G_{\mathrm{ECE}}$ (the Barnardos *Te Korowai Mokopuna* ECE-plus-whānau-support mechanism)[cite: 7, 10, 21, 35]:

$$\Phi_{\mathrm{child}}\left(i_c, G_{\mathrm{ECE}}, j\right) = \mathbb{I}\left(j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}\right) \omega_{ic} \ln\left(i_c + G_{\mathrm{ECE}} + \bar{g}_{\mathrm{ECE}}\right), \qquad X_t = \frac{\chi}{\alpha} \ln\left( \int \left(i_c + G_{\mathrm{ECE}} + \bar{g}_{\mathrm{ECE}}\right)^\alpha \, d\mu \right)$$

Because $\bar{g}_{\mathrm{ECE}} > 0$, low-income and housing-stressed parents hit the corner solution $i_c = 0$[cite: 7, 10, 20, 21]. Public in-kind provision $G_{\mathrm{ECE}}$ directly lifts their children's skill formation and raises the concave societal externality $X_t$ ($\alpha < 1$) in a way that linear Pigouvian subsidies or cash transfers cannot replicate[cite: 10, 21, 35].
* **Retiree Relational Well-Being & Luxury Property Bequests ($\Phi_{\mathrm{ret}}$):** Following De Nardi (2004) and Piketty and Saez, retirees ($j \ge J_r$) derive relational altruism from the thriving share of the younger generation ($1 - \mathrm{Frac}_{\mathrm{stunted}}$) and social cohesion ($S_t$), alongside warm-glow utility over net-of-tax estates $\left(1 - \tau_b\right)a^{\prime}$ upon mortality risk $1 - s_j$[cite: 31, 37, 39, 40]:

$$\Phi_{\mathrm{ret}}\left(a^{\prime}, \mathrm{Frac}_{\mathrm{stunted}}, S_t, j\right) = \mathbb{I}\left(j \ge J_r\right) \left\lbrack \gamma_{\mathrm{rel}} \ln\left(1 - \mathrm{Frac}_{\mathrm{stunted}}\right) + \gamma_{\mathrm{coh}} \ln\left(S_t\right) + \left(1 - s_j\right) b_1 \frac{\left(b_2 + \left(1 - \tau_b\right)\max\left(0, a^{\prime}\right)\right)^{1 - \eta_c}}{1 - \eta_c} \right\rbrace$$

---

## 4. Infinite-Horizon Firm Sector (The Guvenen et al. Engine Across 4 Regions)
In each region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$, a continuum of infinite-horizon entrepreneurs (`Firm_k`, $N_j = \infty$) with persistent talent $z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$ operates a constant-returns technology subject to collateral constraint $k \le \lambda_{\mathrm{col}} a_f$ ($\lambda_{\mathrm{col}} = 1.80$) and discount factor $\beta_{\mathrm{firm}}\left(\Delta t\right) = 0.95^{\Delta t}$[cite: 5, 11, 42]:

$$V_{F,k}\left(a_f, z_f\right) = \max_{a^{\prime}_f \in \lbrack 0, R_k\left(z_f; \Delta t\right) a_f\rbrack} \left\lbrace \ln\left( R_{k}\left(z_f; \Delta t\right) a_f - a^{\prime}_f \right) + \beta_{\mathrm{firm}}\left(\Delta t\right) \sum_{z^{\prime}_f} \Pi_{f,k}\left(z^{\prime}_f \vert z_f\right) V_{F,k}\left(a^{\prime}_f, z^{\prime}_f\right) \right\rbrace$$

where the $\Delta t$-period gross after-tax return on entrepreneurial equity $R_k\left(z_f; \Delta t\right)$ is[cite: 42]:

$$R_k\left(z_f; \Delta t\right) = \left(1 - \tau_a\right)^{\Delta t} + \left(1 - \tau_k\right) \left\lbrace r + \max\left(0, \alpha_k \left(\frac{1 - \alpha_k}{w_k}\right)^{\frac{1 - \alpha_k}{\alpha_k}} z_f - \left(r + \delta_k\left(\Delta t\right)\right) \right) \lambda_{\mathrm{col}} \right\rbrace$$

Replacing corporate/capital income taxation ($\tau_k$) with a book-value wealth tax ($\tau_a = 0.015$) shifts stationary firm net worth $\Gamma_k\left(a_f, z_f\right)$ toward high-talent entrepreneurs $z_{h,k}$ ($d\log Z / d\tau_a > 0$, Guvenen et al., 2023 Proposition 3)—with the largest productivity multiplier occurring in `Firm_Auckland` ($z_h = 1.75$, $35.1\%$ of NZ businesses) and `Firm_Large` ($z_h = 1.50$, $26.9\%$ of NZ businesses)[cite: 2, 11, 14, 42].

---

## 5. The 100% GPU-Vectorized 3-Stage Intergenerational & $4 \times 5$ Abroad Spatial Transition Operator ($\mathcal{T}_{\mathrm{IG}}$)
The stationary distribution of newborn households entering adulthood at $j=1$ in region $k$, denoted $\mu_{1,k}\left(a_1, h_1, z_1\right)$ (`jequaloneDist`), is computed as a fixed point of three coupled GPU-vectorized operators inside `Build_IntergenTransitionMatrix_UpgradeB.m` (5D) and `Build_IntergenTransitionMatrix.m` (4D), replacing CPU loops with 4D/5D GPU tensor broadcasting and `accumarray` projection[cite: 11, 22]:

### Stage 1: Completed Childhood Skill Formation ($\mathbf{Q}_h$)
* In the 5D experience-asset model (`UpgradeB`), completed Stage-2 childhood skill $\theta_3 = \theta_c\left(j = j_{\mathrm{launch}}\right)$ is extracted directly from parents reaching $j = j_{\mathrm{launch}}$ and mapped onto the child's adult human capital grid `a_grid_hc`, penalized by metropolitan housing crowding $\psi_{\mathrm{crowd}} \ln\left(Q_k\right)\mathbb{I}\left(a_p < 0.05 Q_k\right)$[cite: 7, 11, 22].
* In the compact 4D projection, expected log skill integrates parental investments over $j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}$[cite: 22]:

$$\ln\left(h_{\mathrm{child}}\right) = \rho_{hc} \ln\left(h_p\right) + \gamma_{ic} \ln\left(1 + \bar{i}_c\left(a_p, h_p, z_p, k\right) + G_{\mathrm{ECE}}\right) - \psi_{\mathrm{crowd}} \ln\left(Q_k\right) \mathbb{I}\left(a_p < 0.05 Q_k\right) + \eta_h, \qquad \eta_h \sim \mathcal{N}\left(0, \sigma_{hc}^2\right)$$

### Stage 2: The NZD 1.6T Property Bequest & Youth Grant Operator ($\mathbf{Q}_a$)
Dying retirees ($j \ge J_r$, weighted by mortality $1 - s_j$) in region $k$ leave net-of-tax property estates $\left(1 - \tau_b\right)a^{\prime}_j\left(k\right)$[cite: 22, 31]. Combined with the universal Youth Capital Grant $E$ (`YouthGrant`), this induces the initial wealth distribution $P_{a,k}\left(a_1\right)$ (`MeanBequest.(reg)`)[cite: 11, 22].

### Stage 3: The $4 \times 5$ Domestic & International (`Abroad`) Gumbel Youth Sorting Matrix ($\Pi_{\mathrm{mig}}$)
Before settling into working life at $j=1$, young adults in origin region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$ evaluate the 4 domestic regions $m \in \lbrace 1, 2, 3, 4 \rbrace$ (paying moving/entry cost $\kappa\left(k, m\right)$) against the **5th outside option: emigrating to `Abroad` (Australia/OECD)** with value $V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right)$ and Gumbel scale $\varrho$[cite: 11, 22, 37, 40]:

$$\mathbb{P}_t\left(k \to m \mid a_1, h_1, z_1\right) = \frac{\exp\left(V_{m,t}\left(a_1 - \kappa\left(k,m\right), h_1, z_1, 1\right) / \varrho\right)}{\exp\left(V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho\right) + \sum_{r=1}^4 \exp\left(V_{r,t}\left(a_1 - \kappa\left(k,r\right), h_1, z_1, 1\right) / \varrho\right)}$$

$$P_{\mathrm{emig},t}\left(a_1, h_1, z_1; k\right) = \frac{\exp\left(V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho\right)}{\exp\left(V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho\right) + \sum_{r=1}^4 \exp\left(V_{r,t}\left(a_1 - \kappa\left(k,r\right), h_1, z_1, 1\right) / \varrho\right)}$$

---

## 6. Market Clearing, 6-Gate Intergenerational Fiscal Ledger, & The 2050 Debt-Targeting Protocol
### 6.1 General Equilibrium Market Clearing Across the 4 Regions
Equilibrium across the four domestic regions $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$ requires simultaneous clearing of regional labor markets, regional housing markets, the national capital/bond market, and the Crown fiscal ledger[cite: 15, 25, 32]:
* **Regional Labor Markets Clear ($k \in \lbrace 1, 2, 3, 4 \rbrace$):**

$$\int n_k\left(a_f, z_f; w_k, r\right) \, d\Gamma_k = \sum_{j=1}^{J_r-1} \mu_j \int z h \max\left(0, \ell - I_h\right) \, d\mu_{k,j}$$

* **Regional Housing Markets Clear ($k \in \lbrace 1, 2, 3, 4 \rbrace$):** Total owner-occupied and rental housing space demanded by young and old households in region $k$ equals elastic regional supply $HS\left(k\right) = H_k \left(Q_k\right)^{\delta_{H,k}}$[cite: 5, 15, 26]:

$$\sum_{j=1}^J \mu_j \int h_{\mathrm{space}}\left(a, h, z, j; k\right) \, d\mu_{k,j} = H_k \left(Q_k\right)^{\delta_{H,k}}$$

* **National Capital / Bond Market Clears:**

$$\sum_{k=1}^4 \omega_{F,k} \int \left(k_k\left(a_f, z_f\right) - a_f\right) d\Gamma_k + B_{\mathrm{gov}} = \sum_{k=1}^4 \omega_{HH,k} \sum_{j=1}^J \mu_j \int a_{\mathrm{fin}}\left(a, h, z, j; k\right) \, d\mu_{k,j}$$

### 6.2 Post-Hoc 6-Gate Intergenerational Fiscal Ledger (`FiscalLedger`) & The 2050 Protocol
The core VFI state space and policy functions remain unmodified, while `FiscalLedger` (implemented in `Plot_ChildFiscal_2Panel_SSankey.m`) operates strictly post-hoc as a linear operator on `StationaryDist` and `Policy` across 6 life-course gates (anchored to `NZD_Base_Scale = 95.0`, where $1.0\text{ model unit} = \mathrm{NZD\ } 95\mathrm{k/yr}$ reference household labor income)[cite: 7, 20]:
1. **Gate 1 ($J = 1$, Birth / Entry, Age 0):** Separates birth-year investments into (1) **Means-Tested Birth & Hardship Support** (Accommodation Supplement, BestStart years 2–3 means-tested infant support, Sole Parent birth grants, and neonatal acute care for mothers in hardship `is_hardship` or `iz == 1`), (2) **Universal Birth Benefit** (Paid Parental Leave, universal Year-1 BestStart, free LMC midwifery, and Well Child Tamariki Ora / Plunket for $100\%$ of births), and (3) **Private Out-of-Pocket Birth Costs** (infant equipment, housing space, and uncompensated parental leave earnings foregone)[cite: 20].
2. **Gate 2 ($J = 2..3$, First 2000 Days) & Gate 3 ($J = 5$, Ages 12–14 Adolescent Gate):** Tracks the Ferriere et al. luxury corner ($i_c = 0$) vs. public wraparound $G_{\mathrm{ECE},1}$ at Gate 2, and unbuffered family unemployment stress (`iz == 1`) with in-childhood Exits 1, 2, and 4 vs. Two-Way Montessori Cross-Age Peer Mentoring at Gate 3[cite: 7, 20, 21, 43].
3. **Gate 4 ($J = 6..7$, Adult Skill Launch, Age 20), Boundary Rules, & Remediation Outlays (Exits 1, 2, 4):** Acute remediation outlays—Oranga Tamariki state care ($\approx \mathrm{NZD\ } 180\mathrm{k/care\text{-}yr}$, or $\mathrm{NZD\ } 37,054\mathrm{/child\text{-}yr}$ custody average and $\mathrm{NZD\ } 181\mathrm{k}$ Crown lifetime substantiated abuse cost in the Barnardos Generational Plan scorecard)[cite: 20, 29], adult corrections, and acute hospitalizations—are tied directly to childhood stunting ($h_1\text{--}h_2$ tier, `@NZD 32k/stunted` annualized cohort burden)[cite: 7, 20]. Following the strict Barnardos Generational Plan separation between the **Economy-Wide Lens** and the **Crown Fiscal Lens**, **Exit 3 (Lower Lifetime Income)** is never double-counted inside direct Crown spending; instead, only the **28.8% foregone Crown tax revenue** (`Lost Tax: Exit 3 + Emig`) is displayed as a top-of-column tax leak[cite: 7, 20].
4. **Gate 5 ($J = 10$, Age 30) & Gate 6 ($J = 11..16$, Career to Retirement) — Macro Public Residual ($\Omega_{\mathrm{fiscal}}$) & The 2050 50/50 Split:** The cohort net fiscal balance $\Omega_{\mathrm{fiscal}}$ reconciles total good taxes collected ($\tau_l$ PAYE, $\tau_c$ GST, $\tau_k$ capital income, $\tau_a$ book-value wealth, $\tau_{\mathrm{corp}}$ indirect corporate, and $\tau_b$ estate taxes) against acute remediation (Exits 1, 2, 4) and universal public overhead (infrastructure, roads, base healthcare, and NZ Super $P_{\mathrm{super}}$)[cite: 7, 20]:

$$\Omega_{\mathrm{fiscal}} = \left(\mathrm{Tax}_{\mathrm{PAYE}} + \mathrm{Tax}_{\mathrm{GST}} + \mathrm{Tax}_{\mathrm{Cap/Wealth}} + \mathrm{Tax}_{\mathrm{Corp}} + \mathrm{Tax}_{\mathrm{Estate}}\right) - \left(\mathrm{Cost}_{\mathrm{Exits\,1,2,4}} + \mathrm{Cost}_{\mathrm{Infra/Health/Super}}\right)$$

Under the **2050 Debt-Sinking Fund & Reinvestment Allocation Protocol**, any net reform tax surplus $\Omega_{\mathrm{reform}} = \max\left(0, \Omega_{\mathrm{fiscal}}^{\mathrm{SS1}} - \Omega_{\mathrm{fiscal}}^{\mathrm{SS0}}\right) > 0$ ($\Omega_{\mathrm{reform}} = +\mathrm{NZD\ } 15.80\mathrm{k/yr}$ at Age 30; $+\mathrm{NZD\ } 16.10\mathrm{k/yr}$ Career-to-Retirement) is dynamically partitioned 50/50 into[cite: 20]:

$$\Omega_{\mathrm{reform}} = \underbrace{0.50 \, \Omega_{\mathrm{reform}}}_{\text{Sovereign Debt Sinking Fund (`SinkingFund\_50Pct\_kNZD`)}} + \underbrace{0.50 \, \Omega_{\mathrm{reform}}}_{\text{Public Reinvestment Pool (`ReinvestmentPool\_50Pct\_kNZD`)}}$$

---

## 7. Master 4-Region Calibration Table & SMM Identification (`Calibrate_NZ_Moments.m`)

| Parameter | Symbol | Value (`Rural`, `Small`, `Large`, `Auckland`) | Target Moment & Empirical Source |
| :--- | :--- | :--- | :--- |
| **Time Grid & Demographics** | | | |
| Period length switch (years) | $\Delta t$ (`dt`) | $5$ (default), $3$, $2$, or $1$ | Configured via `Configure_TimeGrid_Params.m`[cite: 7] |
| Adult horizon & retirement index | $J, J_r$ | $\mathrm{round}\left(80/\Delta t\right), 1+\mathrm{round}\left(45/\Delta t\right)$ | Ages 20–99; NZ Super at age 65 ($16, 10$ at $\Delta t=5$; $27, 16$ at $\Delta t=3$)[cite: 5, 7, 12] |
| Regional Household Pop Shares (Base) | $\omega_{HH,k}$ | $0.160, 0.240, 0.259, 0.341$ | Stats NZ Subnational Pop Estimates (June 2025: Akl $= 34.1\%$)[cite: 5, 11, 14] |
| Regional Business Firm Shares (Base) | $\omega_{F,k}$ | $0.150, 0.230, 0.269, 0.351$ | Stats NZ Business Demography (Feb 2025: Akl $= 35.1\%$)[cite: 5, 11, 14] |
| Intl. Migration Inflow Shares | $\mathbf{m}_{\mathrm{intl}}$ | $0.115, 0.210, 0.270, 0.405$ | Stats NZ projection (Auckland share rises to $\sim 36.5\%$ by Year 30)[cite: 11, 14] |
| Discount factors & CRRA curvature | $\beta_{hh}, \beta_{\mathrm{firm}}, \eta_c$ | $0.96^{\Delta t}, 0.95^{\Delta t}, 2.0$ | Standard OLG life-cycle benchmark[cite: 11, 15] |
| **Lens 1: Two-Stage Child Skill Formation** | | | |
| Stage 1 (Ages 0–5) CES weights & $\varphi_1$ | $\gamma_{1,s}, \gamma_{1,i}, \gamma_{1,p}, \varphi_1$ | $0.53, 0.24, 0.23, 0.35$ | Cunha, Heckman, & Schennach (2010) Stage 1 estimates[cite: 9] |
| Stage 2 (Ages 6–17) CES weights & $\varphi_2$ | $\gamma_{2,s}, \gamma_{2,i}, \gamma_{2,p}, \varphi_2$ | $0.87, 0.07, 0.06, -0.95$ | Cunha et al. (2010) Stage 2 dynamic complementarity[cite: 9, 35] |
| Public ECE Stage 1, Stage 2 & floor | $G_{\mathrm{ECE},1}, G_{\mathrm{ECE},2}, \bar{g}_{\mathrm{ECE}}$ | $0.045, 0.065, 0.020$ | Ferriere et al. luxury corner share $S = \Pr\left(i_c = 0\right) \approx 0.25\text{--}0.58$[cite: 10, 20, 21] |
| Adolescent Montessori & Unemp Shocks | $\Delta \ln h_{\mathrm{ment}}, \Delta \ln h_{\mathrm{unemp}}$ | $+0.05 \to +0.11, -0.22$ | Gate 3 ($J=5$, ages 12–14) peer mentoring vs. job-loss erosion[cite: 20, 43] |
| Hyperbolic discount factor (Fertility) | $\beta_{\mathrm{hyp}}$ | $1.00$ (Base) vs. $0.72$ (No Commit) | Cao & Li (2021) / Laibson quasi-hyperbolic discounting[cite: 36, 44, 45] |
| **Lens 2: 4-Region Wages, Transport & Ben-Porath** | | | |
| Regional baseline wage levels | $w_k$ | $0.85, 0.93, 1.05, 1.18$ | Spatial wage gradient across NZ urban/rural hierarchy[cite: 11] |
| Regional log-income AR(1) dispersion | $\sigma_z$ | $0.11, 0.14, 0.18, 0.24$ | Labrousse & Perdereau (2025) spatial income variance[cite: 5, 26, 39] |
| Mandatory transport/energy subsistence | $\bar{e}_k$ | $0.048, 0.036, 0.022, 0.016$ | Rural/Small 2.7x–2.8x fuel budget share vs. Auckland[cite: 5, 39] |
| Baseline `Income x Geography` transfer | $T_k$ | $0.025, 0.020, 0.016, 0.014$ | Reforms scale to $0.038, 0.031, 0.025, 0.028$[cite: 26, 39] |
| Adult Ben-Porath depreciation & elasticities | $\delta_{hc,\mathrm{ann}}, \alpha_I, \alpha_H$ | $0.0180\text{/yr}, 0.090, 0.064$ | Fan, Seshadri, & Taber (2022) late-career PT share & wage drop[cite: 16] |
| **Lens 3: 4-Region Housing, Bequests & Firms** | | | |
| Regional baseline house prices | $Q_k$ | $1.05, 1.40, 2.05, 3.10$ | Metropolitan land overvaluation gradient[cite: 7, 11, 14] |
| Regional housing supply elasticity | $\delta_H$ | $0.35, 0.28, 0.18, 0.10$ | Labrousse & Perdereau (2025) regional housing supply[cite: 5, 26, 39] |
| Regional annual trend growth factors | $G_{k,\mathrm{ann}}$ | $1.007, 1.011, 1.018, 1.025$ | Hirano & Toda (2025) unbalanced sectoral growth[cite: 5, 11, 32] |
| Firm productivity ceilings ($z_\ell, z_h$) | $z_{f,k}$ | $\lbrack 0.70,1.15\rbrack, \lbrack 0.75,1.28\rbrack, \lbrack 0.83,1.50\rbrack, \lbrack 0.90,1.75\rbrack$ | Guvenen et al. (2023) heterogeneous firm returns[cite: 5, 42] |
| Warm-glow bequest & Youth Grant (Base $\to$ Ref) | $b_1, b_2, E$ | $4.20, 0.45, 0.030 \to 0.065$ | De Nardi (2004) estate concentration & Piketty/Saez grant[cite: 14, 31] |
| **Fiscal Ledger & 2050 Protocol Anchors** | | | |
| Household income scale & OT Care cost | $\bar{Y}_{HH}, c_{\mathrm{OT}}$ | $\mathrm{NZD\ } 95\mathrm{k/yr}, \approx \mathrm{NZD\ } 180\mathrm{k/care\text{-}yr}$ | NZ Treasury CBAx, Oranga Tamariki & Barnardos Table 2 anchors[cite: 20, 29] |

## 7.5 Post-Hoc Transition Integrals & Actuarial Continuation Valuation Operators (`Plot_CumulativeTransitionPayoffs.m` & `Plot_ActuarialContinuationValuation.m`)

### 7.5.1 State-Space Invariance & Continuous-Time Trapezoidal Integration Over $\mu_{k,t}$ and $\Gamma_{k,t}$
To evaluate cumulative public investment, avoided acute fiscal burdens, and macroeconomic output expansion across the $T_{\mathrm{trans}}$-period transition path ($t = 1, \dots, T_{\mathrm{trans}}$ with step length $\Delta t \in \lbrace 5, 3, 2 \rbrace$ years spanning $T_{\mathrm{trans}} \Delta t = 60$ years) without expanding the household state vector $\left(a, h, \theta_c, z, j\right)$, `Plot_CumulativeTransitionPayoffs.m` defines four linear integral operators over the solved transition sequence of regional household distributions $\mu_{k,t}\left(a, h, z, j\right)$ (`StationaryDist_t`) and infinite-horizon firm equity distributions $\Gamma_{k,t}\left(a_f, z_f\right)$:

1. **Regional Annual Public Investment Outlay ($\mathcal{I}_{k,t}$):**
   Integrates incremental early-childhood wraparound provision $\Delta G_{\mathrm{ECE},k}$, private-enrichment matching subsidies $s_{\mathrm{sub}} i_{c,t}$, and the universal Youth Capital Grant $E$ weighted by the dynamic regional household share $\omega_{HH,k,t}$ (`PTypeWeights_path`):

$$\mathcal{I}_{k,t} = \Lambda_{\mathrm{NZD}} \, \omega_{HH,k,t} \left\lbrack \int_{j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}} \left(\Delta G_{\mathrm{ECE},k} + s_{\mathrm{sub}} i_{c,t}\left(a, h, z, j; k\right)\right) d\mu_{k,t} + \int_{j=1} E \, d\mu_{1,k,t} \right\rbrack$$

2. **Regional Annual Direct Cost Avoidance ($\mathcal{S}_{k,t}$):**
   Integrates the reduction in acute public remediation outlays anchored to the Caspi et al. (2016) Dunedin Study concentration of hospital nights, Oranga Tamariki state care, and justice costs in the stunted human-capital tier $h \in \lbrace h_1, h_2 \rbrace$ across working-age brackets $j \in \lbrace 1, \dots, J_r - 1 \rbrace$, plus means-tested transfer reductions $\Delta T_{k,t}$:

$$\mathcal{B}_{k,t}^{\mathrm{acute}} = \Lambda_{\mathrm{NZD}} \, \omega_{HH,k,t} \left\lbrack c_{\mathrm{acute,Dunedin}} \sum_{j=1}^{J_r - 1} \sum_{i_h=1}^{2} \int_{a,z} d\mu_{k,t}\left(a, h_{i_h}, z, j\right) + \int T_{k,t}\left(a, h, z, j\right) d\mu_{k,t} \right\rbrack$$

$$\mathcal{S}_{k,t} = \max\left(0, \, \mathcal{B}_{k,\mathrm{SS0}}^{\mathrm{acute}} - \mathcal{B}_{k,t}^{\mathrm{acute}}\right)$$

3. **Regional Macroeconomic Output Gain ($\Delta Y_{k,t}$) & Endogenous Tax Base Expansion ($\Delta \mathcal{T}_{k,t}$):**
   Combines the immediate Guvenen et al. (2023) firm capital reallocation channel ($\tau_k \to \tau_a$, shifting $\Gamma_{k,t}\left(a_f, z_f\right)$ toward $z_{h,k}$ and raising sectoral TFP $Z_{k,t}$) with the delayed Cunha-Heckman / Daruich (2018) human-capital cohort wave ($\mu_{1,k,t}$ entering $j = 1$ at Year 20 and parenting the second generation at Years 35–40):

$$\Delta Y_{k,t} = \max\left(0, \, \Lambda_{\mathrm{NZD}} \left\lbrack Z_{k,t}\left(\Gamma_{k,t}\right) K_{k,t}^{\alpha_k} H_{k,t}^{1 - \alpha_k} - Y_{k,\mathrm{SS0}} \right\rbrack \right)$$

$$\Delta \mathcal{T}_{k,t} = \max\left(0, \, \Lambda_{\mathrm{NZD}} \left(\mathrm{TaxRev}_{k,t} - \mathrm{TaxRev}_{k,\mathrm{SS0}}\right)\right), \qquad \mathcal{F}_{k,t}^{\mathrm{tot}} = \mathcal{S}_{k,t} + \Delta \mathcal{T}_{k,t}$$

4. **Trapezoidal Cumulative Cash-Basis Integrals ($\mathcal{C}_{k,\mathrm{realized}}^{\left(L\right)}\left(t_m\right)$):**
   For any discrete transition grid point $t_m = m \Delta t$ ($m = 1, \dots, T_{\mathrm{trans}}$) and flow lens $L \in \lbrace \mathrm{Inv}, \mathrm{Sav}, \mathrm{Fiscal}, \mathrm{Econ} \rbrace$ with annual flow series $f_{k,n}^{\left(L\right)}$:

$$\mathcal{C}_{k,\mathrm{realized}}^{\left(L\right)}\left(t_m\right) = \sum_{n=1}^{m} \frac{\Delta t}{2} \left(f_{k,n-1}^{\left(L\right)} + f_{k,n}^{\left(L\right)}\right)$$

### 7.5.2 The Actuarial Continuation Valuation Operator ($\mathcal{V}_{k,t_0}^{\left(L\right)}\left(H\right)$)
Because childhood human capital investments occur during parental stages $j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}$ whereas adult earnings $w_{k,t} z h \ell$ and avoided acute adult remediation costs $c_{\mathrm{acute,Dunedin}}$ materialize across $j = 1, \dots, J_r - 1$ (15 to 45 years later), cash-basis integrals $\mathcal{C}_{k,\mathrm{realized}}^{\left(L\right)}\left(t_0\right)$ exhibit an incubation lag prior to $t_0 = 20$.

To align transition reporting with New Zealand's Accident Compensation Corporation (ACC) forward liability valuation and New Zealand Treasury Circular 2024/15 Cost-Benefit Analysis (CBAx) incidence accounting, `Plot_ActuarialContinuationValuation.m` projects each region's annual flows onto a 1-year piecewise cubic Hermite interpolating polynomial (`pchip`) grid $y \in \lbrace 0, 1, \dots, 100 \rbrace$ and evaluates the rolling $H$-year ($H = 25$) **Conditional Continuation Valuation Operator**:

$$\mathcal{V}_{k,t_0}^{\left(L\right)}\left(H; r_{\mathrm{disc}}, \mathcal{A}\right) = \mathcal{C}_{k,\mathrm{realized}}^{\left(L\right)}\left(t_0; \mathcal{A}\right) + \left(1 - \alpha_{\mathrm{attr}}\right) \Phi_{\mathrm{pipe}}\left(t_0\right) \sum_{s=1}^{H} D\left(s; r_{\mathrm{disc}}, g_{\mathrm{cost}}\right) \psi_{k,\mathrm{persist}}\left(s\right) f_{k, t_0 + s}^{\left(L\right)}\left(\mathcal{A}\right)$$

where the structural discounting, region-specific Markov persistence (`psi_base_map`), and pipeline maturity components are defined by:

$$D\left(s; r_{\mathrm{disc}}, g_{\mathrm{cost}}\right) = \left(\frac{1 + g_{\mathrm{cost}}}{1 + r_{\mathrm{disc}}}\right)^{s}, \qquad \psi_{k,\mathrm{persist}}\left(s\right) = \left(\psi_{k,0}\right)^{s}, \qquad \Phi_{\mathrm{pipe}}\left(t_0\right) = \min\left\lbrace 1, \, \frac{t_0}{15} \right\rbrace$$

$$\left\lbrack \psi_{\mathrm{Rural},0}, \, \psi_{\mathrm{Small},0}, \, \psi_{\mathrm{Large},0}, \, \psi_{\mathrm{Auckland},0} \right\rbrack = \left\lbrack 0.984, \, 0.984, \, 0.986, \, 0.987 \right\rbrack$$

* **Dual Treasury Discount Rates (`r_2pct`, `r_8pct`):** Evaluated simultaneously at $r_{\mathrm{disc}} = 0.020$ (Circular 2024/15 central social rate) and $r_{\mathrm{disc}} = 0.080$ (mandatory commercial sensitivity rate) with real productivity/cost-base growth $g_{\mathrm{cost}} = 0.015$.
* **Macro Attribution Haircut (`alpha_att`):** $\alpha_{\mathrm{attr}} = 0.30$ enforces a 30% conservative deduction on all unrealized forward continuation claims.
* **Calibration Anchor Switch ($\mathcal{A} \in \lbrace \mathrm{Dunedin\_22}, \mathrm{MetroSqueeze\_GUiNZ} \rbrace$):** Toggles the spatial allocation weights $\left(\mathbf{w}_{\mathrm{sav}}\left(\mathcal{A}\right), \mathbf{w}_{\mathrm{gdp}}\left(\mathcal{A}\right)\right)$ and national remediation/human-capital multipliers between the baseline Dunedin Study stunted share (~17.9%–22.0%) and the Growing Up in New Zealand metropolitan rental-squeeze sensitivity (~36.6% stunted share concentrated in high-$Q_k$ `Auckland` and `Large`):

$$\left(\mathbf{w}_{\mathrm{sav}}\left(\mathcal{A}\right), \, \mathbf{w}_{\mathrm{gdp}}\left(\mathcal{A}\right)\right) = \begin{cases}
\left(\lbrack 0.143, \, 0.225, \, 0.260, \, 0.372\rbrack, \; \lbrack 0.130, \, 0.207, \, 0.269, \, 0.394\rbrack\right) & \text{if } \mathcal{A} = \mathrm{Dunedin\_22} \\
\left(\lbrack 0.115, \, 0.195, \, 0.275, \, 0.415\rbrack, \; \lbrack 0.120, \, 0.195, \, 0.275, \, 0.410\rbrack\right) & \text{if } \mathcal{A} = \mathrm{MetroSqueeze\_GUiNZ}
\end{cases}$$

### 7.5.3 Codebase Manifest & Canonical Output Filenames (Files 15 & 16)
* **`Plot_CumulativeTransitionPayoffs.m`:** Integrates `Annual_Inv`, `Annual_Savings`, `Annual_dGDP`, `Annual_dTax`, and `Annual_TotFisc` across all 4 regions (`Rural`, `Small`, `Large`, `Auckland`) and the `National` aggregate from `StationaryDist_t`, `Policy_t`, and `PricePath`, returning trapezoidal cumulative cash integrals `Cum_Inv`, `Cum_Savings`, `Cum_dGDP`, and `Cum_TotFisc`.
* **`Plot_ActuarialContinuationValuation.m`:** Computes and plots the 25-year rolling Conditional Continuation Valuation $\mathcal{V}_{k,t_0}^{\left(L\right)}\left(H\right)$ at the 2.0% and 8.0% NZ Treasury discount rates, supporting `RegionOption` (`'National'`, `'Rural'`, `'Small'`, `'Large'`, `'Auckland'`, `'All4'`) and `Params.Calibration_Anchor` (`'Dunedin_22'` vs. `'MetroSqueeze_GUiNZ'`), and exporting the sibling figure suite into `Output_NZ_4Region_Intergen/`:
  * `Fig_Actuarial_2Panel_<Region>_<Anchor>.png` (2-panel combined Fiscal + Economy-Wide GDP view)
  * `Fig_Actuarial_Fiscal_<Region>_<Anchor>.png` (Panel A sibling: Crown Fiscal Ledger)
  * `Fig_Actuarial_WideGDP_<Region>_<Anchor>.png` (Panel B sibling: Economy-Wide GDP Lens)
  * `Fig_Actuarial_Dashboard_All4_<Anchor>.png` and `Fig_Actuarial_Year5Audit_All4_<Anchor>.png` (`'All4'` spatial comparison suite)

---

## 8. Methodological Appendices (Appendices A.1–A.4)
### Appendix A.1: Why Calibrated Warm-Glow + Experience Asset ($\theta_c$) Replaces Outer-Loop Dynastic VFI
As De Nardi (2004) establishes, embedding a child's full multi-dimensional recursive value function $V_{\mathrm{child}}\left(a_c, h_c, z_c, 1\right)$ directly inside the parent's Bellman equation expands the state space and introduces strategic parent-child gaming without improving empirical fit in the upper tail of the wealth distribution[cite: 13, 31]. Our architecture splits intergenerational altruism across two tractable mechanisms:
1. **End-of-Life Property Estates ($j \ge J_r$):** Andreoni's luxury warm-glow specification $b_1 \frac{\left(b_2 + \left(1 - \tau_b\right)a^{\prime}\right)^{1 - \eta_c}}{1 - \eta_c}$ replicates the exact empirical concentration of the NZD 1.6T intergenerational property transfer and retiree saving profiles without requiring retirees to track their adult children's state vector on the GPU grid[cite: 2, 31].
2. **Active Parenthood Skill Formation ($j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}$):** Because `UpgradeB` tracks the child's multi-stage skill stock $\theta_c$ dynamically as a VFI Toolkit `experienceasset`, and because a young adult's initial value function $V_{1,k}\left(a_1, h_1, z_1\right)$ in a CRRA/log-utility economy is approximately log-linear in initial human capital $h_1 = \theta_3$, the terminal parental utility reward $\omega_{ic}\ln\left(\theta_3\right)$ at $j = j_{\mathrm{launch}}$ serves as an exact functional proxy for $\mathbb{E}\left\lbrack V_1\left(\cdot, \theta_3\right)\right\rbrack$ while solving in a single backward induction pass[cite: 9, 11, 13, 19].

### Appendix A.2: Capturing Daruich's (2018) 75% Intergenerational Distribution Multiplier
In Daruich (2018, Section 6 & Table 7), roughly three-fourths of the long-run welfare gain from early childhood investment operates through the **endogenous shift in the stationary distribution of parent states $\mu\left(a_p, h_p, z_p\right)$ across generations**—creating a stronger parental background for the next generation—rather than changes in the curvature of the continuation value function[cite: 6, 10, 11, 13]. `WelfareDecomposition_4Region.m` isolates this exact channel by solving the reform twice: first holding `jequaloneDist` fixed at the baseline steady state (Exogenous Skills), and second allowing `Build_IntergenTransitionMatrix.m` to iterate `jequaloneDist` to its new fixed point (Endogenous Intergenerational Transmission)[cite: 11].

### Appendix A.3: Dimension-Free Spatial Housing & Unbalanced Growth Land Overvaluation
Combining Kiyotaki, Michaelides, and Nikolov's (2024) net-worth consolidation ($a = Q_k h_{\mathrm{house}} - b_{\mathrm{debt}}$) and analytical rental-vs.-ownership cutoff $\xi_k = \min\left\lbrace 1, \frac{1}{\bar{\chi}}\left(\frac{rr_k}{rh_k}\right)\right\rbrace$ with Hirano and Toda's (2025) unbalanced sectoral growth mechanism ($G_{\mathrm{Auckland},\mathrm{ann}} > G_{\mathrm{Large},\mathrm{ann}} > G_{\mathrm{Small},\mathrm{ann}} > G_{\mathrm{Rural},\mathrm{ann}}$) allows the model to capture regional house-price-to-income divergence and tenure cleavage within a single continuous asset grid `a_grid`[cite: 5, 11, 15, 32].

### Appendix A.4: Two-Speed 5D-to-4D Projection & `.mat` Checkpoint Caching for 60-Year Transition Shooting
Solving the full 5D experience-asset problem (`(a, h, theta_c, z, j)` across 4 regions) directly inside a 12-to-20 period general equilibrium transition shooting loop would require hundreds of GPU value-function iterations[cite: 5, 11]. By solving the exact 5D Cunha–Heckman experience-asset problem in Steps 1–3 (`NZ_4Region_Master_UpgradeB.m` and `PolicyExperiment_LeeSeshadri_4Region.m`), caching `.mat` checkpoints in `Cache_NZ_Intergen`, and projecting the resulting effective childhood investment policies onto the compact 4D state space `(a, h, z, j)` in Step 4, the full 4-region + Abroad equilibrium, 60-year transition path, and 2-panel Population & Fiscal Sankey suites execute in under 4 minutes[cite: 5, 11, 20].

---

## 9. Complete 14-File VFI Toolkit Pipeline Manifest (4-Region + Abroad Suite)
All output CSV tables and 300-DPI PNG figures generated by this pipeline are archived in [`Output_NZ_4Region_Intergen`](https://github.com/MichaelTiemann/IGWelfare/tree/main/Output_NZ_4Region_Intergen)[cite: 8, 11, 14, 22]:

| # | File Name | Role in the Parameterized 4-Region + Abroad VFI Toolkit Pipeline |
| :---: | :--- | :--- |
| **1** | `Configure_TimeGrid_Params.m` | **Time-Grid Parameterizer:** Sets `Params.dt` ($\Delta t \in \lbrace 5, 3, 2, 1 \rbrace$) and computes $J, J_r, \mathcal{J}_{c,1}, \mathcal{J}_{c,2}, j_{\mathrm{launch}}, T_{\mathrm{trans}}$, and $\Delta t$-compounded rates[cite: 7]. |
| **2** | `Run_All_NZ_Intergen_Suite.m` | **Master Runner (With Checkpoint Caching):** Executes Steps 1–8 across all 4 regions (`Rural`, `Small`, `Large`, `Auckland`), manages `Cache_NZ_Intergen` `.mat` checkpoints and 5D $\to$ 4D projection, and exports all CSV tables and PNG figures[cite: 11]. |
| **3** | `NZ_4Region_Master_UpgradeB.m` | **Upgrade B Baseline Master:** Initializes the 8 PTypes (4 Regions $\times$ Household/Firm) with Stats NZ 2025 weights (`[0.160, 0.240, 0.259, 0.341]`) and `experienceasset = 1`[cite: 5, 11]. |
| **4** | `ChildCES_aprimeFn.m` & `HumanCapital_Lifecycle_aprimeFn.m` | **Experience Asset Laws of Motion:** Implement Cunha, Heckman & Schennach's two-stage CES skill production ($\varphi_1 = 0.35, \varphi_2 = -0.95$) across $\mathcal{J}_{c,1}$ and $\mathcal{J}_{c,2}$ plus adult Ben-Porath skill accumulation[cite: 5, 9, 16, 35]. |
| **5** | `ReturnFn_SpatialHH_UpgradeB.m` | **5D Household Return Function:** Embeds Kiyotaki tenure choice, 4-region subsistence $\bar{e}_k$, Ben-Porath training, two-stage child altruism, and luxury bequests[cite: 5, 15, 31]. |
| **6** | `Build_IntergenTransitionMatrix_UpgradeB.m` | **5D GPU-Vectorized Intergenerational Operator:** Extracts completed Stage-2 skill $\theta_3$ at $j = j_{\mathrm{launch}}$, maps NZD 1.6T estates at $j \ge J_r$, and computes $4 \times 5$ domestic/Abroad sorting[cite: 11, 22]. |
| **7** | `PolicyExperiment_LeeSeshadri_4Region.m` | **Stage Counterfactuals:** Runs `BM_Baseline`, `P0_Early_0to5`, `P1P2_Late_6to17`, `BN_FrontLoad`, and `P0_Plus_GrantE`; outputs [`Table12A`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12A_LeeSeshadri_4Region_IGE.csv), [`Table12B`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12B_LeeSeshadri_4Region_VarExpl.csv), [`Table12C`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12C_LeeSeshadri_4Region_Welfare.csv), and [`FigE8`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/FigE8_LeeSeshadri_4Region_Counterfactuals.png)[cite: 17, 18, 19, 23, 24, 27, 28]. |
| **8** | `FertilityBargaining_Module.m` | **Fertility & Bargaining:** Evaluates childcare bargaining, hyperbolic discounting ($\beta_{\mathrm{hyp}} = 0.72$), differential fertility, and NZ Super tax rates; outputs [`Table_Fert1`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table_Fert1_4Region_TFR_DiffFertility.csv), [`Table_Fert2`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table_Fert2_4Region_Stunting_NZSuper.csv), and [`FigFert`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/FigFert_4Region_Bargaining_Solvency.png)[cite: 36, 44, 45]. |
| **9** | `ReturnFn_SpatialHH.m` & `ReturnFn_Firm.m` | **Compact 4D Household & Firm Return Functions:** Used after Step 4 projection for fast SMM calibration, 3-way decomposition, and the $T_{\mathrm{trans}}$-step transition shooting loop[cite: 5, 11, 42]. |
| **10** | `Build_IntergenTransitionMatrix.m` | **Compact 100% GPU-Vectorized $4 \times 5$ Abroad Brain-Drain Operator:** Computes age 20–35 emigration to Australia/OECD, selective $h_6\text{--}h_7$ skill depletion, replacement migration churn, and social cohesion $S_t$[cite: 11, 22, 37, 40]. |
| **11** | `WelfareDecomposition_4Region.m` | **3-Way Welfare Decomposition:** Outputs the 4-region Daruich/Lee-Seshadri ([`Table1`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table1_4Region_Welfare_Decomposition.csv)), Labrousse & Perdereau $4 \times 5$ quintile ([`Table2`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table2_4Region_Quintile_Matrix.csv)), and Kiyotaki tenure cleavage ([`Table3`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table3_4Region_Tenure_Cleavage.csv)) CE % tables[cite: 11, 13, 15, 26]. |
| **12** | `TransPath_4Region_Master.m` & `Calibrate_NZ_Moments.m` | **60-Year Transition & Dynamic Pop Weights:** Solves the $T_{\mathrm{trans}}$-period transition path with endogenous `PTypeWeights_path` ([`Table9`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv)), [`Fig1`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Fig1_Daruich_Cohort_Welfare_4Region.png), [`Fig2`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Fig2_Kiyotaki_Housing_Estates_4Region.png), and [`Fig3`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Fig3_BrainDrain_Cohesion_4Region.png)[cite: 11, 40]. |
| **13** | `Plot_ChildFates_2Panel_SSankey.m` | **6-Gate Population Cohort Sankey Suite:** 100% GPU-vectorized pairwise Sankey tracing cohort headcount shares (%) from Birth ($J=1$), First 2000 Days ($J=2..3$), Adolescent Montessori Gate ($J=5$), Adult Skill Launch ($J=6..7$), Age 30 ($J=10$), and Retirement ($J=11..16$)[cite: 7, 20, 43]. |
| **14** | `Plot_ChildFiscal_2Panel_SSankey.m` | **6-Gate Intergenerational Fiscal Ledger & 2050 Debt-Sinking Sankey:** Evaluates post-hoc fiscal flows (`NZD k/yr` per birth) across Gates 1–6, computes the Macro Public Residual ($\Omega_{\mathrm{fiscal}}$), and partitions reform surpluses 50/50 into the 2050 Sovereign Debt Sinking Fund and Public Reinvestment Pool (`FiscalLedger.Protocol_2050_Summary`)[cite: 7, 20]. |