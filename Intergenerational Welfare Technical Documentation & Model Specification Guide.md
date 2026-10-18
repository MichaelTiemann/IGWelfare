# **Intergenerational Welfare Technical Documentation & Model Specification Guide**

**A Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial OLG Model of Intergenerational Welfare, Housing Wealth, and Human Capital in New Zealand**

---

## **1. Executive Overview & 8-fold Permanent Type (PType) Computational Architecture**

This document provides the complete mathematical specification, calibration mapping, and VFI Toolkit implementation blueprint for evaluating intergenerational welfare in New Zealand across **four domestic geographic tiers** (**Rural**, **Small**, **Large**, **Auckland**) plus an endogenous **Abroad** (Australia/OECD) emigration margin. To capture heterogeneous life-cycle households and collateral-constrained entrepreneurial firms across all four regions without expanding individual grid dimensions, the model dispatches **8 Permanent Types (`Names_i`)** sequentially on the GPU:

| Permanent Type (`Names_i`) | Horizon ($N_j$) | Pop / Firm Share (2025 Base) | Economic Role & Spatial Domain | VFI Toolkit Solver Dispatched |
| :--- | :--- | :--- | :--- | :--- |
| **`HH_Rural`** | Finite ($J = 16$) | 16.0% of HH | Rural & primary districts; elastic land ($\delta_H = 0.35$), high fuel/transport burden ($\bar{e} = 0.048$). | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Small`** | Finite ($J = 16$) | 24.0% of HH | Small/medium provincial towns (<100k); compressed middle wages, elevated transport cost ($\bar{e} = 0.036$). | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Large`** | Finite ($J = 16$) | 25.9% of HH | Non-Auckland major metros (>100k: Wgtn, Chch, Hamilton, Tauranga, Dunedin); university/service stepping-stone hubs. | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Auckland`** | Finite ($J = 16$) | 34.1% of HH | Primate metropolitan agglomeration ("Paris" analog); high wage variance ($\sigma_z = 0.24$), severely inelastic land ($\delta_H = 0.10$). | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`Firm_Rural`** | Infinite ($N_j = \infty$) | 15.0% of Firms | Primary/land-intensive producers ($z_f \in \lbrace 0.70, 1.15 \rbrace$) with trend growth $G_{\mathrm{Rural}} = 1.007$. | `ValueFnIter_Case1` |
| **`Firm_Small`** | Infinite ($N_j = \infty$) | 23.0% of Firms | Provincial processing, retail & trade enterprises ($z_f \in \lbrace 0.75, 1.28 \rbrace$) with $G_{\mathrm{Small}} = 1.011$. | `ValueFnIter_Case1` |
| **`Firm_Large`** | Infinite ($N_j = \infty$) | 26.9% of Firms | Regional metro manufacturing, tech & service firms ($z_f \in \lbrace 0.83, 1.50 \rbrace$) with $G_{\mathrm{Large}} = 1.018$. | `ValueFnIter_Case1` |
| **`Firm_Auckland`** | Infinite ($N_j = \infty$) | 35.1% of Firms | High-return knowledge & tradable scale-ups ($z_f \in \lbrace 0.90, 1.75 \rbrace$) with $G_{\mathrm{Auckland}} = 1.025$. | `ValueFnIter_Case1` |

*(Note: In Step 4 of the Master Runner, the 5D experience-asset state space $\lbrack a, h, \theta_c, z, j \rbrack$ is marginalized over $\theta_c$ into the compact 4D space $\lbrack a, h, z, j \rbrack$ via `ValueFnIter_Case1_FHorz` for rapid SMM calibration, 3-way decomposition, and the 60-year transition shooting path.)*

---

## **2. Macro Demographic & Dynamic Regional Population Law of Motion**

Following the NZ Treasury OLG framework (Binning et al., 2024), cohorts age across $J = 16$ five-year brackets (ages 20–99, retirement at $J_r = 10$, age 65) via survival probabilities $s_j$, fertility rates $f_j$, and age-specific net migration rates:

$$
N_t = T_{t-1} N_{t-1} + M_{t-1}
$$

Along the 60-year transition path ($t = 1, \dots, T_{\mathrm{trans}}$), the 4-region household population share vector $s_{\mathrm{HH},t} = \lbrack s_{\mathrm{Rural},t}, s_{\mathrm{Small},t}, s_{\mathrm{Large},t}, s_{\mathrm{Auckland},t} \rbrack$ and firm share vector $s_{F,t}$ evolve endogenously from their Stats NZ 2025 base (`[0.160, 0.240, 0.259, 0.341]` and `[0.150, 0.230, 0.269, 0.351]`) via domestic youth sorting $\Pi_{\mathrm{mig},t}^{\mathrm{dom}}$ (the normalized $4 \times 4$ domestic submatrix of the $4 \times 5$ migration operator) and international net migration inflows $m_{\mathrm{intl}} = \lbrack 0.115, 0.210, 0.270, 0.405 \rbrack$:

$$
\tilde{s}_{\mathrm{HH},t} = \left(1 - 0.12\right) s_{\mathrm{HH},t} + 0.12 \left( s_{\mathrm{HH},t} \Pi_{\mathrm{mig},t}^{\mathrm{dom}} \right)
$$

$$
s_{\mathrm{HH},t+1} = \frac{\left(1 - \zeta_{\mathrm{inflow}}\right) \tilde{s}_{\mathrm{HH},t} + \zeta_{\mathrm{inflow}} m_{\mathrm{intl}}}{\sum_{k=1}^4 \left\lbrack \left(1 - \zeta_{\mathrm{inflow}}\right) \tilde{s}_{\mathrm{HH},k,t} + \zeta_{\mathrm{inflow}} m_{\mathrm{intl},k} \right\rbrack}
$$

$$
s_{F,t+1} = 0.85 s_{F,t} + 0.15 s_{\mathrm{HH},t+1}
$$

---

## **3. Finite-Horizon Household Problem (Lenses 1, 2, and 3)**

## **3. Finite-Horizon Household Problem (Lenses 1, 2, and 3)**

In the 5D full specification, a household of age $j \in \lbrace 1, \dots, 16 \rbrace$ in region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$ has state vector:

$$
s_{\mathrm{HH}} = \left(a, h, \theta_c, z, j; k\right)
$$

where $a \in A_{\mathrm{HH}}$ (61 points) is consolidated net worth ($Q_k h_{\mathrm{house}} - b_{\mathrm{debt}}$), $h \in H$ (7 points) is adult human capital, $\theta_c \in \Theta_c$ (9 points) is the child's multi-stage skill experience asset, and $z \in Z_k$ (5 points) is a region-specific Markov labor productivity shock. Decisions are $d = \left(i_c, \ell, I_h\right)$ (early/school-age child investment, labor supply, and adult Ben-Porath training).

### **3.1 Housing Tenure Choice, User Costs, and 4-Region Unbalanced Growth**

Following Kiyotaki, Michaelides, and Nikolov (2024) and Hirano and Toda (2025), let $Q_k$ be the regional house price, $R_{\mathrm{ann}} = \left(1 + r\right)^{1/5}$ the gross annualized interest rate, $\mu_{\mathrm{maint}} = 0.04$ maintenance/rates, $\upsilon_h = 0.008$ the owner-occupied tax subsidy, and $G_k$ the regional trend growth factor ($G_{\mathrm{Auckland}} = 1.025 > G_{\mathrm{Large}} = 1.018 > G_{\mathrm{Small}} = 1.011 > G_{\mathrm{Rural}} = 1.007$):

$$
rr_k = \left( 1 + \mu_{\mathrm{maint}} - \frac{G_k}{R_{\mathrm{ann}}} \right) Q_k
$$

$$
rh_k = \left( 1 + \mu_{\mathrm{maint}} - \upsilon_h - \frac{G_k}{R_{\mathrm{ann}}} \right) Q_k
$$

Young working households ($j < J_r$) draw an idiosyncratic rental utility penalty $\chi \sim U\lbrack 0, \bar{\chi} \rbrack$ ($\bar{\chi} = 2.55$), yielding the analytical regional homeownership share $\xi_k$ and composite housing price index $p_{H,k}\left(j\right)$:

$$
\xi_k = \min\left\lbrace 1, \frac{1}{\bar{\chi}} \left( \frac{rr_k}{rh_k} \right) \right\rbrace
$$

$$
p_{H,k}\left(j\right) = \begin{cases} 
\xi_k rh_k + \left(1 - \xi_k\right) \frac{rr_k}{0.5 \bar{\chi}} & \mathrm{if } j < J_r \\ 
rh_k & \mathrm{if } j \ge J_r 
\end{cases}
$$

### **3.2 Two-Stage Childhood CES Skill Law of Motion (`ChildCES_aprimeFn.m`) & Adult Ben-Porath Dynamics**

* **Child Experience Asset ($\theta^{\prime}_c$):** Driven by private investment $i_c$, stage-specific public wraparound provision ($G_{\mathrm{ECE},1}$ at $j = 3$ vs. $G_{\mathrm{ECE},2}$ at $j = 4$), and Stone-Geary luxury floor $\bar{g}_{\mathrm{ECE}} = 0.02$:  

$$
\theta^{\prime}_c = \begin{cases} 
\left\lbrack \gamma_{1,\mathrm{self}} \theta_c^{\varphi_1} + \gamma_{1,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},1} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_1} + \gamma_{1,\mathrm{par}} \bar{h}_p^{\varphi_1} \right\rbrack^{1/\varphi_1} & \mathrm{if } j = 3 \text{ (First 2000 Days, } \varphi_1 = 0.35\text{)} \\ 
\left\lbrack \gamma_{2,\mathrm{self}} \theta_c^{\varphi_2} + \gamma_{2,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},2} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_2} + \gamma_{2,\mathrm{par}} \bar{h}_p^{\varphi_2} \right\rbrack^{1/\varphi_2} & \mathrm{if } j = 4 \text{ (School Years, } \varphi_2 = -0.95\text{)} \\ 
\theta_c & \mathrm{otherwise} 
\end{cases}
$$

* **Adult Ben-Porath Human Capital ($h^{\prime}$):** During working ages ($j < J_r$), adult skill evolves via $h^{\prime} = \left(1 - \delta_{\mathrm{hc}}\right) h + I_h^{\alpha_I} h^{\alpha_H}$ with $\delta_{\mathrm{hc}} = 0.087, \alpha_I = 0.090, \alpha_H = 0.064$.

### **3.3 Recursive Bellman Equation of the Household**

The value function $V_k\left(a, h, \theta_c, z, j\right)$ solves:

$$
V_k\left(a, h, \theta_c, z, j\right) = \max_{i_c, \ell, I_h, a^{\prime}, h^{\prime}} \left\lbrace \frac{u_{\mathrm{comp}}^{1 - \eta_c}}{1 - \eta_c} - \psi_l \frac{\ell^2}{2} + X_t + \Phi_{\mathrm{child}}\left(i_c, \theta^{\prime}_c, j\right) + \Phi_{\mathrm{ret}}\left(a^{\prime}, \mathrm{Frac}_{\mathrm{stunted}}, S_t, j\right) + \beta_{\mathrm{hh}} s_j \sum_{z^{\prime}} \Pi_{z,k}\left(z^{\prime} \mid z\right) V_k\left(a^{\prime}, h^{\prime}, \theta^{\prime}_c, z^{\prime}, j + 1\right) \right\rbrace
$$

where composite non-durable and housing consumption $u_{\mathrm{comp}}$ deducts mandatory regional transport/energy subsistence $\bar{e}_k$ and adds the **Income $\times$ Geography** transfer $T_k\left(y\right)$, while retirees ($j \ge J_r$) derive relational utility from domestic youth thriving $\left(1 - \mathrm{Frac}_{\mathrm{stunted}}\right)$, social cohesion / retention $S_t$, and warm-glow luxury bequests over net-of-tax estates $\left(1 - \tau_b\right) a^{\prime}$.

---

## **4. Infinite-Horizon Firm Sector (The Guvenen et al. Engine Across 4 Regions)**

In each region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$, a continuum of infinite-horizon entrepreneurs (`Firm_k`, $N_j = \infty$) with persistent talent $z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$ operates a constant-returns technology subject to collateral constraint $k \le \lambda_{\mathrm{col}} a_f$ ($\lambda_{\mathrm{col}} = 1.80$):

$$
V_{F,k}\left(a_f, z_f\right) = \max_{a^{\prime}_f} \left\lbrace \ln\left( R_k\left(z_f; w_k, r, \tau_k, \tau_a\right) a_f - a^{\prime}_f \right) + \beta_{\mathrm{firm}} \sum_{z^{\prime}_f} \Pi_{f,k}\left(z^{\prime}_f \mid z_f\right) V_{F,k}\left(a^{\prime}_f, z^{\prime}_f\right) \right\rbrace
$$

Replacing capital income taxation ($\tau_k$) with a book-value wealth tax ($\tau_a = 0.015$) shifts stationary firm net worth $\Gamma_k\left(a_f, z_f\right)$ toward high-talent entrepreneurs $z_{h,k}$—with the largest productivity multiplier occurring in `Firm_Auckland` ($z_h = 1.75$, 35.1% of NZ businesses) and `Firm_Large` ($z_h = 1.50$, 26.9% of NZ businesses).

---

## **5. The 3-Stage Intergenerational & $4 \times 5$ Abroad Spatial Transition Operator**

The stationary distribution of newborn households entering adulthood at $j = 1$ in region $k$, denoted $\mu_{1,k}\left(a_1, h_1, z_1\right)$ (`jequaloneDist`), is computed as a fixed point of three coupled operators inside `Build_IntergenTransitionMatrix_5D.m` (5D) and `Build_IntergenTransitionMatrix.m` (4D):

### **5.1 Stage 1: Completed Childhood Skill Formation ($Q_h$)**

* In the 5D experience-asset model, completed Stage-2 childhood skill $\theta_3 = \theta^{\prime}_c\left(j = 4\right)$ is extracted directly from parents reaching $j = 5$ and mapped onto the child's adult human capital grid `a_grid_hc`, penalized by metropolitan housing crowding $\psi_{\mathrm{crowd}} \ln\left(Q_k\right) \mathbb{I}\left(a_p < 0.05 Q_k\right)$.

In the compact 4D projection, expected log skill follows the anchored Cobb-Douglas relation:

$$
\ln\left(h_{\mathrm{child}}\right) = \rho_{\mathrm{hc}} \ln\left(h_p\right) + \gamma_{\mathrm{ic}} \ln\left( 1 + i_c\left(a_p, h_p, z_p, k\right) + G_{\mathrm{ECE}} \right) - \psi_{\mathrm{crowd}} \ln\left(Q_k\right) \mathbb{I}\left(a_p < 0.05 Q_k\right) + \eta_h
$$

where $\eta_h \sim \mathcal{N}\left(0, \sigma_{\mathrm{hc}}^2\right)$.

### **5.2 Stage 2: The \$1.6T Property Bequest & Youth Grant Operator ($Q_a$)**

Dying retirees ($j \ge J_r$) in region $k$ leave net-of-tax property estates $\left(1 - \tau_b\right) a^{\prime}_j\left(k\right)$. Combined with the universal Youth Grant $E$ (`YouthGrant`), this induces the initial wealth distribution $P_{a,k}\left(a_1\right)$, where Auckland retirees generate the largest estate flows (`MeanBequest.Auckland`) due to $Q_{\mathrm{Auckland}} = 3.10$.

### **5.3 Stage 3: The $4 \times 5$ Domestic & International (Abroad) Gumbel Youth Sorting Matrix ($\Pi_{\mathrm{mig}}$)**

Before settling into working life at $j = 1$ (and early career $j = 2$), young adults in origin region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$ evaluate the 4 domestic regions $m \in \lbrace 1, 2, 3, 4 \rbrace$ (paying moving/entry cost $\kappa\left(k, m\right)$) against the **5th outside option: emigrating to Abroad (Australia/OECD)** with value $V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1\right)$:

$$
\mathbb{P}_t\left(k \to m \mid a_1, h_1, z_1\right) = \frac{\exp\left( V_{m,t}\left(a_1 - \kappa\left(k,m\right), h_1, z_1, 1\right) / \varrho \right)}{\exp\left( V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho \right) + \sum_{r=1}^4 \exp\left( V_{r,t}\left(a_1 - \kappa\left(k,r\right), h_1, z_1, 1\right) / \varrho \right)}
$$

$$
P_{\mathrm{emig},t}\left(a_1, h_1, z_1; k\right) = \frac{\exp\left( V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho \right)}{\exp\left( V_{\mathrm{Abroad},t}\left(a_1, h_1, z_1, 1\right) / \varrho \right) + \sum_{r=1}^4 \exp\left( V_{r,t}\left(a_1 - \kappa\left(k,r\right), h_1, z_1, 1\right) / \varrho \right)}
$$

Each state cell $\left(a_1, h_1, z_1\right)$ is weighted by its domestic retention probability $\left(1 - P_{\mathrm{emig},t}\right)$, capturing both the **$\mathrm{Rural/Small} \to \mathrm{Large} \to \mathrm{Auckland}$** domestic stepping-stone funnel and the selective brain-drain depletion of high-skill ($h_5 \mathrm{--} h_7$), low-asset youth to Australia/OECD.

---

## **6. Master 4-Region Calibration Table (Stats NZ 2025/2026 & Literature Benchmarks)**

| Parameter | Symbol | Value (Rural, Small, Large, Auckland) | Target / Empirical Source |
| :--- | :--- | :--- | :--- |
| **Demographics & Regional Weights** | | | |
| Model horizon & retirement age | $J, J_r$ | 16, 10 | Ages 20–99 (5-yr brackets); NZ Super at 65. |
| Regional Household Pop Shares (Base) | $\omega_{\mathrm{HH},k}$ | 0.160, 0.240, 0.259, 0.341 | Stats NZ Subnational Pop Estimates (June 2025: Akl = 34.1%). |
| Regional Business Firm Shares (Base) | $\omega_{F,k}$ | 0.150, 0.230, 0.269, 0.351 | Stats NZ Business Demography (Feb 2025: Akl = 35.1%). |
| Intl. Migration Inflow Shares | $m_{\mathrm{intl}}$ | 0.115, 0.210, 0.270, 0.405 | Stats NZ projection (Auckland share rises to ~36.5% by Year 30). |
| Discount factors & CRRA curvature | $\beta_{\mathrm{hh}}, \beta_{\mathrm{firm}}, \eta_c$ | $0.96^5, 0.95^5, 2.0$ | Standard OLG life-cycle benchmark. |
| **Lens 1: Two-Stage Child Skill Formation** | | | |
| Stage 1 (Ages 0–5) CES weights & $\varphi_1$ | $\gamma_{1,s}, \gamma_{1,i}, \gamma_{1,p}, \varphi_1$ | 0.53, 0.24, 0.23, 0.35 | Cunha, Heckman, & Schennach (2010) Stage 1 estimates. |
| Stage 2 (Ages 6–17) CES weights & $\varphi_2$ | $\gamma_{2,s}, \gamma_{2,i}, \gamma_{2,p}, \varphi_2$ | 0.87, 0.07, 0.06, -0.95 | Cunha et al. (2010) Stage 2 dynamic complementarity. |
| Public ECE Stage 1, Stage 2 & floor | $G_{\mathrm{ECE},1}, G_{\mathrm{ECE},2}, \bar{g}_{\mathrm{ECE}}$ | 0.045, 0.065, 0.020 | Ferriere et al. (2025) luxury floor & NZ ECE baseline. |
| Baseline stunted cohort share | $\mathrm{Frac}_{\mathrm{stunted}}$ | 0.143 – 0.220 | NZ material hardship & Dunedin Study cohort benchmark. |
| **Lens 2: 4-Region Wages, Transport & Ben-Porath** | | | |
| Regional baseline wage levels | $w_k\left(R, S, L, \mathrm{Akl}\right)$ | 0.85, 0.93, 1.05, 1.18 | Spatial wage gradient across NZ urban/rural hierarchy. |
| Regional log-income AR(1) dispersion | $\sigma_z\left(R, S, L, \mathrm{Akl}\right)$ | 0.11, 0.14, 0.18, 0.24 | Labrousse & Perdereau (2025) spatial income variance. |
| Mandatory transport/energy subsistence | $\bar{e}_k\left(R, S, L, \mathrm{Akl}\right)$ | 0.048, 0.036, 0.022, 0.016 | Step-down from Rural/Small towns to dense Auckland. |
| Baseline Income $\times$ Geography transfer | $T_k\left(R, S, L, \mathrm{Akl}\right)$ | 0.025, 0.020, 0.016, 0.014 | Reforms scale to 0.038, 0.031, 0.025, 0.028. |
| Adult Ben-Porath depreciation & elasticities | $\delta_{\mathrm{hc}}, \alpha_I, \alpha_H$ | 0.087, 0.090, 0.064 | Life-cycle adult human capital estimation. |
| **Lens 3: 4-Region Housing, Bequests & Firms** | | | |
| Regional baseline house prices | $Q_k\left(R, S, L, \mathrm{Akl}\right)$ | 1.05, 1.40, 2.05, 3.10 | Metropolitan land overvaluation gradient. |
| Regional housing supply elasticity | $\delta_H\left(R, S, L, \mathrm{Akl}\right)$ | 0.35, 0.28, 0.18, 0.10 | Elastic rural land vs. constrained Auckland supply. |
| Regional trend growth factors | $G_k\left(R, S, L, \mathrm{Akl}\right)$ | 1.007, 1.011, 1.018, 1.025 | Hirano & Toda (2025) unbalanced sectoral growth. |
| Firm productivity ceilings ($z_\ell, z_h$) | $z_{f,k}\left(R, S, L, \mathrm{Akl}\right)$ | `[0.70, 1.15]`, `[0.75, 1.28]`, `[0.83, 1.50]`, `[0.90, 1.75]` | Guvenen et al. (2023) heterogeneous firm returns. |
| Warm-glow bequest & Youth Grant (Base $\to$ Ref) | $b_1, b_2, E$ | $4.20, 0.45, 0.030 \to 0.065$ | De Nardi (2004) & Piketty/Saez youth endowment. |

---

## **7. Complete 11-File VFI Toolkit Pipeline Manifest (4-Region + Abroad Suite)**

| # | File Name | Role in the 4-Region + Abroad VFI Toolkit Pipeline |
| :--- | :--- | :--- |
| **1** | `Run_All_NZ_Intergen_Suite.m` | **Master Runner:** Executes Steps 1–7 across all 4 regions (Rural, Small, Large, Auckland), manages 5D $\to$ 4D projection, and exports all CSV tables (Tables 1–10) and 300-DPI figures. |
| **2** | `NZ_4Region_Master.m` | **Baseline Master:** Initializes the 8 PTypes (4 Regions $\times$ Household/Firm) with Stats NZ 2025 weights (`[0.160, 0.240, 0.259, 0.341]`) and `experienceasset = 1`. |
| **3** | `ChildCES_aprimeFn.m` | **Experience Asset Law of Motion:** Implements Cunha, Heckman & Schennach's two-stage CES skill production ($\varphi_1 = 0.35, \varphi_2 = -0.95$) across $j = 3$ and $j = 4$. |
| **4** | `ReturnFn_SpatialHH_5D.m` | **5D Household Return Function:** Embeds Kiyotaki tenure choice, 4-region subsistence $\bar{e}_k$, Ben-Porath training, two-stage child altruism, and luxury bequests. |
| **5** | `Build_IntergenTransitionMatrix_5D.m` | **5D Intergenerational Operator:** Extracts completed Stage-2 skill $\theta_3$ at $j = 5$, maps \$1.6T estates at $j \ge J_r$, and computes $4 \times 5$ domestic/Abroad spatial sorting. |
| **6** | `PolicyExperiment_LeeSeshadri_4Region.m` | **Stage Counterfactuals:** Runs `BM`, `P0_Early_0to5`, `P1P2_Late_6to17`, `BN_FrontLoad`, and `P0_Plus_GrantE` across 4 regions; outputs IGE, Table 12 variance explained, and 4-panel Figure E8. |
| **7** | `FertilityBargaining_Module.m` | **Fertility & Bargaining:** Evaluates cooperative childcare bargaining, hyperbolic discounting ($\beta_{\mathrm{hyp}}$), differential fertility, and NZ Super tax rates across 4 regions. |
| **8** | `ReturnFn_SpatialHH.m` & `ReturnFn_Firm.m` | **Compact 4D Household & Firm Return Functions:** Used after Step 4 projection for fast SMM calibration, 3-way decomposition, and the 60-year transition shooting loop. |
| **9** | `Build_IntergenTransitionMatrix.m` | **Compact $4 \times 5$ Abroad Brain-Drain Operator:** Computes age 20–35 emigration to Australia/OECD, selective $h_6 \mathrm{--} h_7$ skill depletion, replacement migration churn, and social cohesion $S_t$. |
| **10** | `WelfareDecomposition_4Region.m` | **3-Way Welfare Decomposition:** Outputs the 4-region Daruich/Lee–Seshadri (Table 1), Labrousse & Perdereau $4 \times 5$ quintile (Table 2), and Kiyotaki tenure cleavage (Table 3) CE % tables. |
| **11** | `TransPath_4Region_Master.m` & `Calibrate_NZ_Moments.m` | **60-Year Transition & Dynamic Pop Weights:** Solves the non-linear transition path with endogenous `PTypeWeights_path` (Auckland 34.1% $\to$ 36.5%, Table 9), brain-drain closure, and SMM moment matching. |

---

## **8. Output Artifacts Manifest: CSV Data Tables & Visual Figures (`Output_NZ_4Region_Intergen/`)**

All simulation outputs generated by the 11-file VFI Toolkit pipeline are stored in [`Output_NZ_4Region_Intergen`](Output_NZ_4Region_Intergen). Below is the complete technical catalog of exported CSV data tables and 300-DPI diagnostic figures.

### **8.1 Exported CSV Data Tables (Tables 1 to 10)**

| Table ID | CSV File Name in `Output_NZ_4Region_Intergen/` | Generating MATLAB Script | Primary Variables & Analytical Scope |
| :--- | :--- | :--- | :--- |
| **Table 1** | [`Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv`](Output_NZ_4Region_Intergen/Table1_4Region_Daruich_LeeSeshadri_Decomposition.csv) | `WelfareDecomposition_4Region.m` | 3-stage Consumption Equivalent (`CE %`) decomposition across Rural, Small, Large, and Auckland: Short-Run PE vs. Long-Run GE (Exogenous Skills) vs. Long-Run GE (Endogenous Intergenerational Operator $T_{\mathrm{IG}}$). |
| **Table 2** | [`Table2_4Region_LabroussePerdereau_SpatialQuintiles.csv`](Output_NZ_4Region_Intergen/Table2_4Region_LabroussePerdereau_SpatialQuintiles.csv) | `WelfareDecomposition_4Region.m` | $4 \times 5$ Spatial Region $\times$ Income Quintile ($Q_1 \mathrm{--} Q_5$) welfare incidence matrix, isolating the distributional impact of the **Income $\times$ Geography** transfer rule $T_k\left(y\right)$ and subsistence $\bar{e}_k$. |
| **Table 3** | [`Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv`](Output_NZ_4Region_Intergen/Table3_4Region_Kiyotaki_TenureGenerationalCleavage.csv) | `WelfareDecomposition_4Region.m` | Housing tenure and generational cleavage across all 4 regions: Young Renters ($j < J_r, \chi \text{ low}$) vs. Young Leveraged Homeowners ($j < J_r, \chi \text{ high}$) vs. Older Property-Rich Retirees/Landlords ($j \ge J_r$). |
| **Table 3B** | [`Table3B_4Region_Abroad_SteadyState_Summary.csv`](Output_NZ_4Region_Intergen/Table3B_4Region_Abroad_SteadyState_Summary.csv) | `Build_IntergenTransitionMatrix.m` | Stationary $4 \times 5$ Gumbel youth sorting probabilities $\mathbb{P}\left(k \to m\right)$, selective $h_5 \mathrm{--} h_7$ outward emigration rates $P_{\mathrm{emig}}$, and domestic stepping-stone flows ($\mathrm{Rural/Small} \to \mathrm{Large} \to \mathrm{Auckland}$). |
| **Table 4** | [`Table4_4Region_LeeSeshadri_IGE.csv`](Output_NZ_4Region_Intergen/Table4_4Region_LeeSeshadri_IGE.csv) | `PolicyExperiment_LeeSeshadri_4Region.m` | Short-Run PE (`SR`) and Long-Run GE (`LR`) Intergenerational Elasticity of Earnings (`IGE`) across 5 regimes: `BM_Baseline`, `P0_Early_0to5`, `P1P2_Late_6to17`, `BN_FrontLoad`, and `P0_Plus_GrantE`. |
| **Table 5** | [`Table5_4Region_LeeSeshadri_Output_Welfare.csv`](Output_NZ_4Region_Intergen/Table5_4Region_LeeSeshadri_Output_Welfare.csv) | `PolicyExperiment_LeeSeshadri_4Region.m` | Percentage gains in average lifetime earnings (`Ebar_SR`, `Ebar_LR`) and long-run newborn welfare (`CE_LR %`) across the 5 childhood and youth-grant policy counterfactuals. |
| **Table 6** | [`Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv`](Output_NZ_4Region_Intergen/Table6_4Region_LeeSeshadri_Table12_VarianceExplained.csv) | `PolicyExperiment_LeeSeshadri_4Region.m` | Replication of Lee & Seshadri (2019) Table 12: share of variance in adult human capital ($h_1$) and lifetime earnings (`LFE`) explained by parental state at ages 30–35, plus log-earnings variance (`VarLogE`). |
| **Table 7** | [`Table7_4Region_Endogenous_TFR_DiffFertility.csv`](Output_NZ_4Region_Intergen/Table7_4Region_Endogenous_TFR_DiffFertility.csv) | `FertilityBargaining_Module.m` | Regional Total Fertility Rates (`TFR`) and socioeconomic differential fertility ratios (`DiffFert` = Low-Skill / High-Skill fertility) across Baseline, Hyperbolic Procrastination ($\beta_{\mathrm{hyp}} = 0.72$), and Barnardos ECE Relief. |
| **Table 8** | [`Table8_4Region_Fertility_Stunting_NZSuperTax.csv`](Output_NZ_4Region_Intergen/Table8_4Region_Fertility_Stunting_NZSuperTax.csv) | `FertilityBargaining_Module.m` | Regional stunted cohort shares ($\mathrm{Frac}_{\mathrm{stunted}}$), old-age dependency ratio ($\mathrm{Dep}_{65+}$), and the endogenous labor tax rate ($\tau_l$) required to balance universal NZ Superannuation ($p_{\mathrm{super}}$). |
| **Table 9** | [`Table9_4Region_Dynamic_Population_Shares.csv`](Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv) | `TransPath_4Region_Master.m` | 60-year transition trajectory of regional household shares $s_{\mathrm{HH},t}$ and business firm shares $s_{F,t}$ (`PTypeWeights_path`), tracking Auckland's agglomeration rise from 34.1% to ~36.5%. |
| **Table 10** | [`Table10_4Region_Abroad_BrainDrain_Cohesion.csv`](Output_NZ_4Region_Intergen/Table10_4Region_Abroad_BrainDrain_Cohesion.csv) | `TransPath_4Region_Master.m` | 60-year transition path of age 20–35 emigration rates to Australia/OECD, replacement migration churn (`Churn_Rate`), Social Cohesion Index ($S_t$), and effective tax base per 65+ retiree. |

---

### **8.2 Exported Diagnostic Figures (Figures 1 to 5)**

#### **Figure 1: Cohort Welfare Transition Path Across 4 Regions**
* **File:** [`Daruich__2018__Fig_11__4_Region_Intergenerati.png`](Output_NZ_4Region_Intergen/Daruich__2018__Fig_11__4_Region_Intergenerati.png)
* **Technical Description:** Replicates Daruich (2018) Figure 11 across Rural, Small, Large, and Auckland. Plots the lifetime Consumption Equivalent (`CE %`) welfare gain by birth cohort $c \in \lbrack -10, 60 \rbrack$ along the transition path, isolating the **Year-20 intergenerational inflection** when Cohort $c = 0$ (raised under expanded First-2000-Days $G_{\mathrm{ECE},1}$) matures into adulthood and parenthood.

![Cohort Welfare Transition Path Across 4 Regions](Output_NZ_4Region_Intergen/Daruich__2018__Fig_11__4_Region_Intergenerati.png)

---

#### **Figure 2: 4-Region Childhood Skill Formation & Intergenerational Persistence Counterfactuals**
* **File:** [`Lee___Seshadri__2019__Fig_E8__4_Region_Parent.png`](Output_NZ_4Region_Intergen/Lee___Seshadri__2019__Fig_E8__4_Region_Parent.png)
* **Technical Description:** Replicates Lee and Seshadri (2019) Figure E8 across all four regions. Compares the 5 counterfactual regimes (`BM_Baseline`, `P0_Early_0to5`, `P1P2_Late_6to17`, `BN_FrontLoad`, `P0_Plus_GrantE`) across Intergenerational Elasticity of Earnings (`IGE`), variance of adult human capital explained by parental state (`VarExpl_h1`), and long-run lifetime earnings gains (`Ebar_LR %`).

![4-Region Childhood Skill Formation & Intergenerational Persistence Counterfactuals](Output_NZ_4Region_Intergen/Lee___Seshadri__2019__Fig_E8__4_Region_Parent.png)

---

#### **Figure 3: 4-Region Housing, Tenure, and Estate Impulse Responses**
* **File:** [`Kiyotaki_et_al___2024__Figs_6_7__4_Region_Hou.png`](Output_NZ_4Region_Intergen/Kiyotaki_et_al___2024__Figs_6_7__4_Region_Hou.png)
* **Technical Description:** Replicates Kiyotaki, Michaelides, and Nikolov (2024) Figures 6–7 across Rural, Small, Large, and Auckland. Tracks the 60-year impulse responses of regional house prices $Q_{k,t}$ (cooling $-7.5\%$ in Auckland and $-5.0\%$ in Large cities), young working-age homeownership shares $\xi_{k,t}$, and net-of-tax property bequest flows $\left(1 - \tau_b\right) a^{\prime}_j\left(k\right)$.

![4-Region Housing, Tenure, and Estate Impulse Responses](Output_NZ_4Region_Intergen/Kiyotaki_et_al___2024__Figs_6_7__4_Region_Hou.png)

---

#### **Figure 4: Endogenous Spatial Sorting & Dynamic Population Shares Over 60 Years**
* **File:** [`Stats_NZ___Endogenous_Spatial_Sorting__60_Yea.png`](Output_NZ_4Region_Intergen/Stats_NZ___Endogenous_Spatial_Sorting__60_Yea.png)
* **Technical Description:** Plots the 60-year endogenous law of motion for `PTypeWeights_path` ($s_{\mathrm{HH},t}$ and $s_{F,t}$) driven by the $4 \times 4$ domestic submatrix $\Pi_{\mathrm{mig},t}^{\mathrm{dom}}$ and international net migration inflows $m_{\mathrm{intl}}$.

![Endogenous Spatial Sorting over 60 Years](Output_NZ_4Region_Intergen/Stats_NZ___Endogenous_Spatial_Sorting__60_Yea.png)

---

#### **Figure 5: Three-Wave Brain-Drain Closure, Replacement Churn, and Social Cohesion Recovery**
* **File:** [`40_Year_Transition__Closing_the_NZ_4_Region_Y.png`](Output_NZ_4Region_Intergen/40_Year_Transition__Closing_the_NZ_4_Region_Y.png)
* **Technical Description:** Tracks the 60-year transition of the $4 \times 5$ Abroad emigration probability $P_{\mathrm{emig},t}\left(a_1, h_1, z_1; k\right)$ across Three Waves: Wave 1 (Years 0–5 housing affordability and Youth Grant $E$), Wave 2 (Years 5–20 Guvenen et al. firm wage growth $w_{k,t}$), and Wave 3 (Year 20+ human capital maturation of Cohort $c = 0$), alongside the decline in replacement migration churn and the recovery of the Social Cohesion Index $S_t$.

![Three-Wave Brain-Drain Closure, Replacement Churn, and Social Cohesion Recovery](Output_NZ_4Region_Intergen/40_Year_Transition__Closing_the_NZ_4_Region_Y.png)