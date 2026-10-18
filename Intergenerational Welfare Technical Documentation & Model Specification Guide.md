# **Intergenerational Welfare Technical Documentation & Model Specification Guide**

**A Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial OLG Model of Intergenerational Welfare, Housing Wealth, and Human Capital in New Zealand**

## **1. Executive Overview & 8-fold Permanent Type (PType) Computational Architecture**

This document provides the complete mathematical specification, calibration mapping, and VFI Toolkit implementation blueprint for evaluating intergenerational welfare in New Zealand across **four domestic geographic tiers** (**Rural**, **Small**, **Large**, **Auckland**) plus an endogenous **Abroad** (Australia/OECD) emigration margin.  
To capture heterogeneous life-cycle households and collateral-constrained entrepreneurial firms across all four regions without expanding individual grid dimensions, the model dispatches **8 Permanent Types (`Names_i`)** sequentially on the GPU:

| Permanent Type (`Names_i`) | Horizon ($N_j$) | Pop / Firm Share (2025 Base) | Economic Role & Spatial Domain | VFI Toolkit Solver Dispatched |
| :--- | :--- | :--- | :--- | :--- |
| **`HH_Rural`** | Finite ($J=16$) | 16.0% of HH | Rural & primary districts; elastic land ($\delta_H = 0.35$), high fuel/transport burden ($\bar{e} = 0.048$). | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Small`** | Finite ($J=16$) | 24.0% of HH | Small/medium provincial towns (<100k); compressed middle wages, elevated transport cost ($\bar{e} = 0.036$). | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Large`** | Finite ($J=16$) | 25.9% of HH | Non-Auckland major metros (>100k: Wgtn, Chch, Hamilton, Tauranga, Dunedin); university/service stepping-stone hubs. | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`HH_Auckland`** | Finite ($J=16$) | 34.1% of HH | Primate metropolitan agglomeration ("Paris" analog); high wage variance ($\sigma_z = 0.24$), severely inelastic land ($\delta_H = 0.10$). | `ValueFnIter_Case1_FHorz_ExpAsset` |
| **`Firm_Rural`** | Infinite ($N_j = \infty$) | 15.0% of Firms | Primary/land-intensive producers ($z_f \in \{0.70, 1.15\}$) with trend growth $G_{\text{Rural}} = 1.007$. | `ValueFnIter_Case1` |
| **`Firm_Small`** | Infinite ($N_j = \infty$) | 23.0% of Firms | Provincial processing, retail & trade enterprises ($z_f \in \{0.75, 1.28\}$) with $G_{\text{Small}} = 1.011$. | `ValueFnIter_Case1` |
| **`Firm_Large`** | Infinite ($N_j = \infty$) | 26.9% of Firms | Regional metro manufacturing, tech & service firms ($z_f \in \{0.83, 1.50\}$) with $G_{\text{Large}} = 1.018$. | `ValueFnIter_Case1` |
| **`Firm_Auckland`** | Infinite ($N_j = \infty$) | 35.1% of Firms | High-return knowledge & tradable scale-ups ($z_f \in \{0.90, 1.75\}$) with $G_{\text{Auckland}} = 1.025$. | `ValueFnIter_Case1` |

*(Note: In Step 4 of the Master Runner, the 5D experience-asset state space $[a, h, \theta_c, z, j]$ is marginalized over $\theta_c$ into the compact 4D space $[a, h, z, j]$ via `ValueFnIter_Case1_FHorz` for rapid SMM calibration, 3-way decomposition, and the 60-year transition shooting path.)*

## **2. Macro Demographic & Dynamic Regional Population Law of Motion**

Following the NZ Treasury OLG framework (Binning et al., 2024), cohorts age across $J=16$ five-year brackets (ages 20–99, retirement at $J_r = 10$, age 65) via survival probabilities $s_j$, fertility rates $f_j$, and age-specific net migration rates:

$$N_t = T_{t-1} N_{t-1} + M_{t-1}$$

Along the 60-year transition path ($t = 1, \dots, T_{\text{trans}}$), the 4-region household population share vector $s_{HH,t} = [s_{\text{Rural},t}, s_{\text{Small},t}, s_{\text{Large},t}, s_{\text{Auckland},t}]$ and firm share vector $s_{F,t}$ evolve endogenously from their Stats NZ 2025 base ([0.160, 0.240, 0.259, 0.341] and [0.150, 0.230, 0.269, 0.351]) via domestic youth sorting $\Pi_{\text{mig},t}^{\text{dom}}$ (the normalized $4 \times 4$ domestic submatrix of the $4 \times 5$ migration operator) and international net migration inflows $m_{\text{intl}} = [0.115, 0.210, 0.270, 0.405]$:

$$\tilde{s}_{HH,t} = (1 - 0.12) s_{HH,t} + 0.12 \left( s_{HH,t} \Pi_{\text{mig},t}^{\text{dom}} \right)$$

$$s_{HH,t+1} = \frac{(1 - \zeta_{\text{inflow}}) \tilde{s}_{HH,t} + \zeta_{\text{inflow}} m_{\text{intl}}}{\sum_{k=1}^4 \left[ (1 - \zeta_{\text{inflow}}) \tilde{s}_{HH,k,t} + \zeta_{\text{inflow}} m_{\text{intl},k} \right]}, \qquad s_{F,t+1} = 0.85 s_{F,t} + 0.15 s_{HH,t+1}$$

## **3. Finite-Horizon Household Problem (Lenses 1, 2, and 3)**

In Upgrade B (5D full specification), a household of age $j \in \{1, \dots, 16\}$ in region $k \in \{\text{Rural}, \text{Small}, \text{Large}, \text{Auckland}\}$ has state vector:

$$s_{HH} = (a, h, \theta_c, z, j; k)$$

where $a \in A_{HH}$ (61 points) is consolidated net worth ($Q_k h_{\text{house}} - b_{\text{debt}}$), $h \in H$ (7 points) is adult human capital, $\theta_c \in \Theta_c$ (9 points) is the child's multi-stage skill experience asset, and $z \in Z_k$ (5 points) is a region-specific Markov labor productivity shock. Decisions are $d = (i_c, \ell, I_h)$ (early/school-age child investment, labor supply, and adult Ben-Porath training).

### **3.1 Housing Tenure Choice, User Costs, and 4-Region Unbalanced Growth**

Following Kiyotaki, Michaelides, and Nikolov (2024) and Hirano and Toda (2025), let $Q_k$ be the regional house price, $R_{\text{ann}} = (1+r)^{1/5}$ the gross annualized interest rate, $\mu_{\text{maint}} = 0.04$ maintenance/rates, $\upsilon_h = 0.008$ the owner-occupied tax subsidy, and $G_k$ the regional trend growth factor ($G_{\text{Auckland}} = 1.025 > G_{\text{Large}} = 1.018 > G_{\text{Small}} = 1.011 > G_{\text{Rural}} = 1.007$):

$$rr_k = \left( 1 + \mu_{\text{maint}} - \frac{G_k}{R_{\text{ann}}} \right) Q_k, \qquad rh_k = \left( 1 + \mu_{\text{maint}} - \upsilon_h - \frac{G_k}{R_{\text{ann}}} \right) Q_k$$

Young working households ($j < J_r$) draw an idiosyncratic rental utility penalty $\chi \sim U[0, \bar{\chi}]$ ($\bar{\chi} = 2.55$), yielding the analytical regional homeownership share $\xi_k$ and composite housing price index $p_{H,k}(j)$:

$$\xi_k = \min\left\{ 1, \frac{1}{\bar{\chi}} \left( \frac{rr_k}{rh_k} \right) \right\}, \qquad p_{H,k}(j) = \begin{cases} \xi_k rh_k + (1 - \xi_k) \frac{rr_k}{0.5 \bar{\chi}} & \text{if } j < J_r \\ rh_k & \text{if } j \ge J_r \end{cases}$$

### **3.2 Two-Stage Childhood CES Skill Law of Motion (`ChildCES_aprimeFn.m`) & Adult Ben-Porath Dynamics**

* **Child Experience Asset ($\theta'_c$):** Driven by private investment $i_c$, stage-specific public wraparound provision ($G_{\text{ECE},1}$ at $j=3$ vs. $G_{\text{ECE},2}$ at $j=4$), and Stone-Geary luxury floor $\bar{g}_{\text{ECE}} = 0.02$:  
  $$
  \theta'_c = \begin{cases} 
  \left[ \gamma_{1,\text{self}} \theta_c^{\varphi_1} + \gamma_{1,\text{inv}} (i_c + G_{\text{ECE},1} + \bar{g}_{\text{ECE}})^{\varphi_1} + \gamma_{1,\text{par}} \bar{h}_p^{\varphi_1} \right]^{1/\varphi_1} & \text{if } j = 3 \text{ (First 2000 Days, } \varphi_1 = 0.35\text{)} \\ 
  \left[ \gamma_{2,\text{self}} \theta_c^{\varphi_2} + \gamma_{2,\text{inv}} (i_c + G_{\text{ECE},2} + \bar{g}_{\text{ECE}})^{\varphi_2} + \gamma_{2,\text{par}} \bar{h}_p^{\varphi_2} \right]^{1/\varphi_2} & \text{if } j = 4 \text{ (School Years, } \varphi_2 = -0.95\text{)} \\ 
  \theta_c & \text{otherwise} 
  \end{cases}
  $$  
* **Adult Ben-Porath Human Capital ($h'$):** During working ages ($j < J_r$), adult skill evolves via $h' = (1 - \delta_{\text{hc}}) h + I_h^{\alpha_I} h^{\alpha_H}$ with $\delta_{\text{hc}} = 0.087, \alpha_I = 0.090, \alpha_H = 0.064$.

### **3.3 Recursive Bellman Equation of the Household**

The value function $V_k(a, h, \theta_c, z, j)$ solves:

$$
V_k(a, h, \theta_c, z, j) = \max_{i_c, \ell, I_h, a', h'} \left\{ \frac{u_{\text{comp}}^{1 - \eta_c}}{1 - \eta_c} - \psi_l \frac{\ell^2}{2} + X_t + \Phi_{\text{child}}(i_c, \theta'_c, j) + \Phi_{\text{ret}}(a', \text{Frac}_{\text{stunted}}, S_t, j) + \beta_{hh} s_j \sum_{z'} \Pi_{z,k}(z' \mid z) V_k(a', h', \theta'_c, z', j+1) \right\}
$$  
where composite non-durable and housing consumption $u_{\text{comp}}$ deducts mandatory regional transport/energy subsistence $\bar{e}_k$ and adds the **Income $\times$ Geography** transfer $T_k(y)$, while retirees ($j \ge J_r$) derive relational utility from domestic youth thriving $(1 - \text{Frac}_{\text{stunted}})$, social cohesion / retention $S_t$, and warm-glow luxury bequests over net-of-tax estates $(1 - \tau_b) a'$.

## **4. Infinite-Horizon Firm Sector (The Guvenen et al. Engine Across 4 Regions)**

In each region $k \in \{\text{Rural}, \text{Small}, \text{Large}, \text{Auckland}\}$, a continuum of infinite-horizon entrepreneurs (`Firm_k`, $N_j = \infty$) with persistent talent $z_f \in \{z_{\ell,k}, z_{h,k}\}$ operates a constant-returns technology subject to collateral constraint $k \le \lambda_{\text{col}} a_f$ ($\lambda_{\text{col}} = 1.80$):

$$
V_{F,k}(a_f, z_f) = \max_{a'_f} \left\{ \ln\left( R_k(z_f; w_k, r, \tau_k, \tau_a) a_f - a'_f \right) + \beta_{\text{firm}} \sum_{z'_f} \Pi_{f,k}(z'_f \mid z_f) V_{F,k}(a'_f, z'_f) \right\}
$$  
Replacing capital income taxation ($\tau_k$) with a book-value wealth tax ($\tau_a = 0.015$) shifts stationary firm net worth $\Gamma_k(a_f, z_f)$ toward high-talent entrepreneurs $z_{h,k}$—with the largest productivity multiplier occurring in `Firm_Auckland` ($z_h = 1.75$, 35.1% of NZ businesses) and `Firm_Large` ($z_h = 1.50$, 26.9% of NZ businesses).

## **5. The 3-Stage Intergenerational & $4 \times 5$ Abroad Spatial Transition Operator**

The stationary distribution of newborn households entering adulthood at $j=1$ in region $k$, denoted $\mu_{1,k}(a_1, h_1, z_1)$ (`jequaloneDist`), is computed as a fixed point of three coupled operators inside `Build_IntergenTransitionMatrix_UpgradeB.m` (5D) and `Build_IntergenTransitionMatrix.m` (4D):

### **5.1 Stage 1: Completed Childhood Skill Formation ($Q_h$)**

* In the 5D experience-asset model (`UpgradeB`), completed Stage-2 childhood skill $\theta_3 = \theta'_c(j=4)$ is extracted directly from parents reaching $j=5$ and mapped onto the child's adult human capital grid `a_grid_hc`, penalized by metropolitan housing crowding $\psi_{\text{crowd}} \ln(Q_k) \mathbb{I}(a_p < 0.05 Q_k)$.

In the compact 4D projection, expected log skill follows the anchored Cobb-Douglas relation:

$$\ln(h_{\text{child}}) = \rho_{\text{hc}} \ln(h_p) + \gamma_{\text{ic}} \ln\left(1 + i_c(a_p, h_p, z_p, k) + G_{\text{ECE}}\right) - \psi_{\text{crowd}} \ln(Q_k) \mathbb{I}(a_p < 0.05 Q_k) + \eta_h, \quad \eta_h \sim \mathcal{N}(0, \sigma_{\text{hc}}^2)$$

### **5.2 Stage 2: The \$1.6T Property Bequest & Youth Grant Operator ($Q_a$)**

Dying retirees ($j \ge J_r$) in region $k$ leave net-of-tax property estates $(1 - \tau_b) a'_j(k)$. Combined with the universal Youth Grant $E$ (`YouthGrant`), this induces the initial wealth distribution $P_{a,k}(a_1)$, where Auckland retirees generate the largest estate flows (`MeanBequest.Auckland`) due to $Q_{\text{Auckland}} = 3.10$.

### **5.3 Stage 3: The $4 \times 5$ Domestic & International (Abroad) Gumbel Youth Sorting Matrix ($\Pi_{\text{mig}}$)**

Before settling into working life at $j=1$ (and early career $j=2$), young adults in origin region $k \in \{\text{Rural}, \text{Small}, \text{Large}, \text{Auckland}\}$ evaluate the 4 domestic regions $m \in \{1, 2, 3, 4\}$ (paying moving/entry cost $\kappa(k, m)$) against the **5th outside option: emigrating to Abroad (Australia/OECD)** with value $V_{\text{Abroad},t}(a_1, h_1, z_1)$:

$$
\mathbb{P}_t(k \to m \mid a_1, h_1, z_1) = \frac{\exp\left(V_{m,t}(a_1 - \kappa(k,m), h_1, z_1, 1) / \varrho\right)}{\exp\left(V_{\text{Abroad},t}(a_1, h_1, z_1, 1) / \varrho\right) + \sum_{r=1}^4 \exp\left(V_{r,t}(a_1 - \kappa(k,r), h_1, z_1, 1) / \varrho\right)}
$$

$$
P_{\text{emig},t}(a_1, h_1, z_1; k) = \frac{\exp\left(V_{\text{Abroad},t}(a_1, h_1, z_1, 1) / \varrho\right)}{\exp\left(V_{\text{Abroad},t}(a_1, h_1, z_1, 1) / \varrho\right) + \sum_{r=1}^4 \exp\left(V_{r,t}(a_1 - \kappa(k,r), h_1, z_1, 1) / \varrho\right)}
$$

Each state cell $(a_1, h_1, z_1)$ is weighted by its domestic retention probability $(1 - P_{\text{emig},t})$, capturing both the **Rural/Small $\to$ Large $\to$ Auckland** domestic stepping-stone funnel and the selective brain-drain depletion of high-skill ($h_5 - h_7$), low-asset youth to Australia/OECD.

## **6. Master 4-Region Calibration Table (Stats NZ 2025/2026 & Literature Benchmarks)**

| Parameter | Symbol | Value (Rural, Small, Large, Auckland) | Target / Empirical Source |
| :--- | :--- | :--- | :--- |
| **Demographics & Regional Weights** | | | |
| Model horizon & retirement age | $J, J_r$ | 16, 10 | Ages 20–99 (5-yr brackets); NZ Super at 65. |
| Regional Household Pop Shares (Base) | $\omega_{HH,k}$ | 0.160, 0.240, 0.259, 0.341 | Stats NZ Subnational Pop Estimates (June 2025: Akl = 34.1%). |
| Regional Business Firm Shares (Base) | $\omega_{F,k}$ | 0.150, 0.230, 0.269, 0.351 | Stats NZ Business Demography (Feb 2025: Akl = 35.1%). |
| Intl. Migration Inflow Shares | $m_{\text{intl}}$ | 0.115, 0.210, 0.270, 0.405 | Stats NZ projection (Auckland share rises to ~36.5% by Year 30). |
| Discount factors & CRRA curvature | $\beta_{hh}, \beta_{\text{firm}}, \eta_c$ | $0.96^5, 0.95^5, 2.0$ | Standard OLG life-cycle benchmark. |
| **Lens 1: Two-Stage Child Skill Formation** | | | |
| Stage 1 (Ages 0–5) CES weights & $\varphi_1$ | $\gamma_{1,s}, \gamma_{1,i}, \gamma_{1,p}, \varphi_1$ | 0.53, 0.24, 0.23, 0.35 | Cunha, Heckman, & Schennach (2010) Stage 1 estimates. |
| Stage 2 (Ages 6–17) CES weights & $\varphi_2$ | $\gamma_{2,s}, \gamma_{2,i}, \gamma_{2,p}, \varphi_2$ | 0.87, 0.07, 0.06, -0.95 | Cunha et al. (2010) Stage 2 dynamic complementarity. |
| Public ECE Stage 1, Stage 2 & floor | $G_{\text{ECE},1}, G_{\text{ECE},2}, \bar{g}_{\text{ECE}}$ | 0.045, 0.065, 0.020 | Ferriere et al. (2025) luxury floor & NZ ECE baseline. |
| Baseline stunted cohort share | $\text{Frac}_{\text{stunted}}$ | 0.143 – 0.220 | NZ material hardship & Dunedin Study cohort benchmark. |
| **Lens 2: 4-Region Wages, Transport & Ben-Porath** | | | |
| Regional baseline wage levels | $w_k(R, S, L, \text{Akl})$ | 0.85, 0.93, 1.05, 1.18 | Spatial wage gradient across NZ urban/rural hierarchy. |
| Regional log-income AR(1) dispersion | $\sigma_z(R, S, L, \text{Akl})$ | 0.11, 0.14, 0.18, 0.24 | Labrousse & Perdereau (2025) spatial income variance. |
| Mandatory transport/energy subsistence | $\bar{e}_k(R, S, L, \text{Akl})$ | 0.048, 0.036, 0.022, 0.016 | Step-down from Rural/Small towns to dense Auckland. |
| Baseline Income x Geography transfer | $T_k(R, S, L, \text{Akl})$ | 0.025, 0.020, 0.016, 0.014 | Reforms scale to 0.038, 0.031, 0.025, 0.028. |
| Adult Ben-Porath depreciation & elasticities | $\delta_{\text{hc}}, \alpha_I, \alpha_H$ | 0.087, 0.090, 0.064 | Life-cycle adult human capital estimation. |
| **Lens 3: 4-Region Housing, Bequests & Firms** | | | |
| Regional baseline house prices | $Q_k(R, S, L, \text{Akl})$ | 1.05, 1.40, 2.05, 3.10 | Metropolitan land overvaluation gradient. |
| Regional housing supply elasticity | $\delta_H(R, S, L, \text{Akl})$ | 0.35, 0.28, 0.18, 0.10 | Elastic rural land vs. constrained Auckland supply. |
| Regional trend growth factors | $G_k(R, S, L, \text{Akl})$ | 1.007, 1.011, 1.018, 1.025 | Hirano & Toda (2025) unbalanced sectoral growth. |
| Firm productivity ceilings ($z_\ell, z_h$) | $z_{f,k}(R, S, L, \text{Akl})$ | [0.70, 1.15], [0.75, 1.28], [0.83, 1.50], [0.90, 1.75] | Guvenen et al. (2023) heterogeneous firm returns. |
| Warm-glow bequest & Youth Grant (Base $\to$ Ref) | $b_1, b_2, E$ | $4.20, 0.45, 0.030 \to 0.065$ | De Nardi (2004) & Piketty/Saez youth endowment. |

## **7. Complete 11-File VFI Toolkit Pipeline Manifest (4-Region + Abroad Suite)**

| # | File Name | Role in the 4-Region + Abroad VFI Toolkit Pipeline |
| :--- | :--- | :--- |
| **1** | `Run_All_NZ_Intergen_Suite.m` | **Master Runner:** Executes Steps 1–7 across all 4 regions (Rural, Small, Large, Auckland), manages 5D $\to$ 4D projection, and exports all CSV tables (Tables 1–9) and 300-DPI figures. |
| **2** | `NZ_4Region_Master_UpgradeB.m` | **Upgrade B Baseline Master:** Initializes the 8 PTypes (4 Regions $\times$ Household/Firm) with Stats NZ 2025 weights ([0.160, 0.240, 0.259, 0.341]) and `experienceasset = 1`. |
| **3** | `ChildCES_aprimeFn.m` | **Experience Asset Law of Motion:** Implements Cunha, Heckman & Schennach's two-stage CES skill production ($\varphi_1 = 0.35, \varphi_2 = -0.95$) across $j=3$ and $j=4$. |
| **4** | `ReturnFn_SpatialHH_UpgradeB.m` | **5D Household Return Function:** Embeds Kiyotaki tenure choice, 4-region subsistence $\bar{e}_k$, Ben-Porath training, two-stage child altruism, and luxury bequests. |
| **5** | `Build_IntergenTransitionMatrix_UpgradeB.m` | **5D Intergenerational Operator:** Extracts completed Stage-2 skill $\theta_3$ at $j=5$, maps \$1.6T estates at $j \ge J_r$, and computes $4 \times 5$ domestic/Abroad spatial sorting. |
| **6** | `PolicyExperiment_LeeSeshadri_4Region.m` | **Stage Counterfactuals:** Runs BM, P0_Early_0to5, P1P2_Late_6to17, BN_FrontLoad, and P0_Plus_GrantE across 4 regions; outputs IGE, Table 12 variance explained, and 4-panel Figure E8. |
| **7** | `FertilityBargaining_Module.m` | **Fertility & Bargaining:** Evaluates cooperative childcare bargaining, hyperbolic discounting ($\beta_{\text{hyp}}$), differential fertility, and NZ Super tax rates across 4 regions. |
| **8** | `ReturnFn_SpatialHH.m` & `ReturnFn_Firm.m` | **Compact 4D Household & Firm Return Functions:** Used after Step 4 projection for fast SMM calibration, 3-way decomposition, and the 60-year transition shooting loop. |
| **9** | `Build_IntergenTransitionMatrix.m` | **Compact $4 \times 5$ Abroad Brain-Drain Operator:** Computes age 20–35 emigration to Australia/OECD, selective $h_6 - h_7$ skill depletion, replacement migration churn, and social cohesion $S_t$. |
| **10** | `WelfareDecomposition_4Region.m` | **3-Way Welfare Decomposition:** Outputs the 4-region Daruich/Lee–Seshadri (Table 1), Labrousse & Perdereau $4 \times 5$ quintile (Table 2), and Kiyotaki tenure cleavage (Table 3) CE % tables. |
| **11** | `TransPath_4Region_Master.m` & `Calibrate_NZ_Moments.m` | **60-Year Transition & Dynamic Pop Weights:** Solves the non-linear transition path with endogenous `PTypeWeights_path` (Auckland 34.1% $\to$ 36.5%, Table 9), brain-drain closure, and SMM moment matching. |

---

## **Version Previous**

# **Technical Documentation & Model Specification Guide**

**A Mixed Finite/Infinite-Horizon Spatial OLG Model of Intergenerational Welfare, Housing Wealth, and Human Capital in New Zealand**

## **1. Executive Overview & Computational Architecture**

This document provides the complete mathematical specification, calibration mapping, and VFI Toolkit implementation blueprint for evaluating intergenerational welfare in New Zealand across three coupled life-cycle and macroeconomic lenses:

> 1. **Lens 1: Early Childhood Skill Formation (First 1000/2000 Days):** Anchored cognitive and noncognitive skill production, public in-kind provision of luxury goods with "pro-equality" externalities, and the macroeconomic returns to early childhood development policies.  
> 2. **Lens 2: The Active Working Generation:** Quantity-quality fertility and time/money child investment, adult Ben-Porath human capital maintenance and part-time/full-time labor supply, and the young renter vs. leveraged homeowner tenure cleavage.  
> 3. **Lens 3: Retirement, The \$1.6T Property Transfer, and Capital Allocation:** Universal pension fiscal dynamics, luxury bequest motives and estate taxation, unbalanced sectoral growth driving metropolitan land overvaluation, and "use-it-or-lose-it" wealth taxation on heterogeneous-return firms.

### **1.1 Mixed-Horizon Permanent Type (`Names_i`) Structure**

To capture spatial heterogeneity across New Zealand (**Rural**, **Urban**, and **Auckland**) alongside dynamic entrepreneurial production without triggering the curse of dimensionality, the model partitions agents into six Permanent Types (`Names_i`) in the VFI Toolkit:

| Permanent Type (`Names_i`) | Horizon ($N_j$) | Economic Role & Spatial Domain | VFI Toolkit Solver Dispatched |
| :--- | :--- | :--- | :--- |
| **`HH_Rural`** | Finite ($J = 16$) | Provincial & agricultural NZ households; high transport/fuel subsistence, elastic housing. | `ValueFnIter_Case1_FHorz` |
| **`HH_Urban`** | Finite ($J = 16$) | Regional cities (Wellington, Christchurch, Hamilton, Tauranga, Dunedin); balanced wages/housing. | `ValueFnIter_Case1_FHorz` |
| **`HH_Auckland`** | Finite ($J = 16$) | Primate metropolitan agglomeration ("Paris" analog); high productivity variance, inelastic land. | `ValueFnIter_Case1_FHorz` |
| **`Firm_Rural`** | Infinite ($N_j = \infty$) | Land/primary-intensive producers ($z \in \{z_\ell, z_h\}$) with trend growth $G_{\text{Rural}}$. | `ValueFnIter_Case1` |
| **`Firm_Urban`** | Infinite ($N_j = \infty$) | Regional manufacturing/service firms with trend growth $G_{\text{Urban}}$. | `ValueFnIter_Case1` |
| **`Firm_Auckland`** | Infinite ($N_j = \infty$) | Knowledge & high-return service firms with trend growth $G_{\text{Auckland}} > G_{\text{Rural}}$. | `ValueFnIter_Case1` |

## **2. Demographics & The 3-Region Spatial Cohort Matrix**

Time is discrete, where each model period corresponds to 5 calendar years. Households enter economic adulthood at age 20 ($j = 1$), retire mandatorily at age 65 ($J_r = 10$), and face a maximum lifespan of age 99 ($J = 16$).

### **2.1 Macro Demographic Law of Motion**

Following the demographic matrix structure, let $\mathbf{N}_{k,t} = [N_{1,k,t}, \dots, N_{J,k,t}]'$ denote the vector of cohort population masses in region $k \in \{\text{Rural}, \text{Urban}, \text{Auckland}\}$. The cohort population evolves via survival probabilities $p_j$ (denoted $s_j$ in code), age-specific fertility rates $\omega f_j$, and net migration $\mathbf{M}_{k,t}$:  
$$\mathbf{N}_{k,t} = \mathbf{T}_{\text{demo}} \mathbf{N}_{k,t-1} + \mathbf{M}_{k,t-1}$$  
where $\mathbf{T}_{\text{demo}}$ contains age-specific fertility rates $\omega f_j$ in the first row (for fertile ages $j \in \{2, 3, 4\}$) and survival probabilities $s_j$ along the sub-diagonal:  
$$
\mathbf{T}_{\text{demo}} = \begin{bmatrix} 0 & \omega f_2 & \omega f_3 & \omega f_4 & 0 & \cdots & 0 & 0 \\ s_1 & 0 & 0 & 0 & 0 & \cdots & 0 & 0 \\ 0 & s_2 & 0 & 0 & 0 & \cdots & 0 & 0 \\ \vdots & \vdots & \ddots & \ddots & \vdots & \ddots & \vdots & \vdots \\ 0 & 0 & 0 & 0 & 0 & \cdots & s_{J-1} & 0 \end{bmatrix}
$$  
In the stationary demographic equilibrium, cohort weights $\mu_j$ (`Params.mewj`) satisfy $\sum_{j=1}^J \mu_j = 1$, pinning down the Old-Age Dependency Ratio $\text{Dep}_{65+} = \frac{\sum_{j=J_r}^J \mu_j}{\sum_{j=1}^{J_r-1} \mu_j}$.

## **3. Finite-Horizon Household Problem (Lenses 1, 2, and 3)**

A household of age $j \in \{1, \dots, J\}$ residing in region $k \in \{\text{Rural}, \text{Urban}, \text{Auckland}\}$ is characterized by the state vector:  
$$\mathbf{s}_{HH} = (a, h, z, j; k)$$  
where:

> * $a \in \mathcal{A}_{HH}$ is consolidated nonhuman net worth (combining financial assets and net housing equity $Q_k h_{\text{house}} - b_{\text{debt}}$).  
> * $h \in \mathcal{H}$ is adult human capital anchored to log earnings.  
> * $z \in \mathcal{Z}_k$ is an exogenous Markov labor productivity shock with region-specific transition matrix $\Pi_{z,k}(z' \mid z)$ and dispersion $\nu_k$.

### **3.1 Housing Tenure Choice, User Costs, and Spatial Subsistence**

Following Kiyotaki, Michaelides, and Nikolov and Hirano and Toda, let $Q_k$ be the price of a unit of housing/land in region $k$, $R_{\text{ann}} = (1+r)^{1/5}$ be the gross annualized interest rate, $\mu_{\text{maint}}$ be the maintenance and property rates cost, $\upsilon_h$ be the implicit tax subsidy to owner-occupied housing, and $G_k$ be the regional trend growth factor. The local rental yield $rr_k$ and homeowner user cost $rh_k$ are:  
$$rr_k = \left(1 + \mu_{\text{maint}} - \frac{G_k}{R_{\text{ann}}}\right) Q_k, \qquad rh_k = \left(1 + \mu_{\text{maint}} - \upsilon_h - \frac{G_k}{R_{\text{ann}}}\right) Q_k$$  
Because unbalanced productivity growth between the knowledge/service sector (Auckland) and the land/primary sector (Rural) implies $G_{\text{Auckland}} > G_{\text{Urban}} > G_{\text{Rural}}$ with elasticity of substitution $>1$, the denominator term $R_{\text{ann}} + \mu_{\text{maint}} - G_{\text{Auckland}}$ compresses in Auckland, generating structural land overvaluation ($Q_{\text{Auckland}} \gg Q_{\text{Rural}}$) and a rising price-to-rent ratio.  
Young working households ($j < J_r$) draw an idiosyncratic rental utility penalty $\chi \sim U[0, \bar{\chi}]$. Those with high $\chi$ become leveraged homeowners, while those with low $\chi$ rent, yielding the analytical regional homeownership share $\xi_k$ and composite housing price index $p_{H,k}(j)$:  
$$\xi_k = \min\left\{1, \frac{1}{\bar{\chi}} \left(\frac{rr_k}{rh_k}\right)\right\}, \qquad p_{H,k}(j) = \begin{cases} \xi_k rh_k + (1 - \xi_k) \frac{rr_k}{0.5 \bar{\chi}} & \text{if } j < J_r \\ rh_k & \text{if } j \ge J_r \end{cases}$$  
Retirees ($j \ge J_r$) have $\chi_o = 0$ (all prefer owning) and hold both their owner-occupied housing and the regional rental stock leased to young renters.

### **3.2 Budget Constraints & Adult Human Capital Evolution**

During the working phase ($j < J_r$), the household chooses labor supply $\ell \in \{0, \ell_{PT}, \ell_{FT}, \ell_{OT}\}$ (capturing the part-time option for older workers), on-the-job Ben-Porath skill investment $I_h \in [0, \bar{I}]$, private early-childhood investment $i_c \ge 0$ (active during fertile ages $j \in \{3, 4\}$), and next-period net worth $a' \ge 0$.

> 1. **Adult Ben-Porath Human Capital Law of Motion ($j < J_r$):** Following the specification with adult skill depreciation $\delta_{\text{hc}}$ and training elasticities ($\alpha_I, \alpha_H$), measured wages reflect time net of training $w_k z h (\ell - I_h)$, and human capital evolves according to:  
>    $$h' = \begin{cases} (1 - \delta_{\text{hc}}) h + I_h^{\alpha_I} h^{\alpha_H} & \text{if } \ell > 0 \\ (1 - \delta_{\text{hc}}) h & \text{if } \ell = 0 \text{ (with } I_h = 0\text{)} \end{cases}$$  
> 2. **Working-Age Budget Constraint ($j < J_r$):** Incorporating progressive/linear labor taxation $\tau_l$, capital income taxation $\tau_k$, consumption GST $\tau_c$, private child-investment subsidies $s_{\text{sub}}$, mandatory regional transport/energy subsistence costs $\bar{e}_k$ (`ebar_energy`), regional transfers $T_k$ (`Transfer_Geo`), and the universal youth endowment $E$ received at $j = 1$:  
>    $$e_{\text{tot}} = \frac{(1 + (1 - \tau_k)r)a + (1 - \tau_l) w_k z h \max(0, \ell - I_h) + \mathbb{I}_{j=1} E + T_k - \bar{e}_k - (1 - s_{\text{sub}}) i_c - a'}{1 + \tau_c}$$  
> 3. **Retirement Budget Constraint ($j \ge J_r$):** Retirees set $\ell = I_h = i_c = 0$, receive universal New Zealand Superannuation $p_{\text{super}}$, and are protected by a retirement consumption floor $\underline{c}$:  
>    $$e_{\text{tot}} = \max\left\{\underline{c}, \, \frac{(1 + (1 - \tau_k)r)a + p_{\text{super}} + T_k - \bar{e}_k - a'}{1 + \tau_c}\right\}$$

Given total net expenditure $e_{\text{tot}} > 0$, Cobb-Douglas intra-period optimization between non-durable consumption $c$ (share $\phi_{nd}$) and housing space $h_{\text{space}}$ (share $1 - \phi_{nd}$) yields composite consumption utility index $u_{\text{comp}} = e_{\text{tot}} \cdot (p_{H,k}(j))^{\phi_{nd} - 1}$.

### **3.3 Recursive Bellman Equation of the Household**

The value function $V_k(a, h, z, j)$ for household type $k$ solves:  
$$V_k(a, h, z, j) = \max_{\ell, I_h, i_c, a'} \left\{ \frac{u_{\text{comp}}^{1 - \eta_c}}{1 - \eta_c} - \psi_l \frac{\ell^2}{2} + X_t + \Phi_{\text{child}}(i_c, G_{\text{ECE}}, j) + \Phi_{\text{ret}}(a', \bar{h}_{\text{child}}, j) + \beta_{hh} s_j \sum_{z'} \Pi_{z,k}(z' \mid z) V_k(a', h', z', j+1) \right\}$$  
where the three intergenerational linkage terms are:

> * **Luxury Child Investment & Pro-Equality Externality ($X_t, \Phi_{\text{child}}$):** Following Labrousse and Perdereau, early childhood investment is a luxury good ($\bar{g}_{\text{ECE}} > 0$) that combines private parental spending $i_c$ and public in-kind provision $G_{\text{ECE}}$ (the Barnardos ECE-plus-whānau-support mechanism):  
>   $$\Phi_{\text{child}}(i_c, G_{\text{ECE}}, j) = \mathbb{I}_{j \in \{3,4\}} \omega_{ic} \ln(i_c + G_{\text{ECE}} + \bar{g}_{\text{ECE}}), \qquad X_t = \frac{\chi}{\alpha} \ln\left( \int (i_c + G_{\text{ECE}} + \bar{g}_{\text{ECE}})^\alpha \, d\mu \right)$$  
>   Because $\bar{g}_{\text{ECE}} > 0$, low-income and housing-stressed parents hit the corner solution $i_c = 0$. Public in-kind provision $G_{\text{ECE}}$ directly lifts their children's skill formation and raises the concave societal externality $X_t$ ($\alpha < 1$) in a way that linear Pigouvian subsidies or cash transfers cannot replicate.  
> * **Retiree Relational Well-Being & Luxury Property Bequests ($\Phi_{\text{ret}}$):** Following De Nardi and Piketty and Saez, retirees at $j \ge J_r$ derive relational utility from the thriving share of the younger generation ($1 - \text{Frac}_{\text{stunted}}$) and warm-glow utility over net-of-tax estates $(1 - \tau_b)a'$ upon mortality risk ($1 - s_j$):  
>   $$\Phi_{\text{ret}}(a', \bar{h}_{\text{child}}, j) = \mathbb{I}_{j \ge J_r} \left[ \gamma_{\text{rel}} \ln(1 - \text{Frac}_{\text{stunted}}) + (1 - s_j) b_1 \frac{\left(b_2 + (1 - \tau_b)\max(0, a')\right)^{1 - \eta_c}}{1 - \eta_c} \right]$$

## **4. Infinite-Horizon Firm Sector (The Guvenen et al. Engine)**

In each region $k \in \{\text{Rural}, \text{Urban}, \text{Auckland}\}$, a continuum of infinite-horizon entrepreneurs/firms (`N_j.Firm_k = Inf`) operates a constant-returns technology over capital $k$ and effective labor $n$ with persistent idiosyncratic productivity $z_f \in \{z_{\ell,k}, z_{h,k}\}$ governed by Markov matrix $\Pi_{f,k}(z'_f \mid z_f)$.

### **4.1 Collateral-Constrained Production & Wealth vs. Capital Income Taxation**

A firm with internal net worth (equity) $a_f \in \mathcal{A}_F$ can borrow capital from the national bond market up to a collateral limit $k \le \lambda_{\text{col}} a_f$. Optimizing out static labor demand $n(k, z_f)$ given regional wage $w_k$ yields the marginal return to capital $\text{MPK}_k(z_f)$ and excess return $\pi_k(z_f)$:  
$$\text{MPK}_k(z_f) = \alpha_k \left(\frac{1 - \alpha_k}{w_k}\right)^{\frac{1 - \alpha_k}{\alpha_k}} z_f, \qquad \pi_k(z_f) = \max\left\{0, \, \text{MPK}_k(z_f) - (r + \delta_k)\right\} \lambda_{\text{col}}$$  
The firm faces both a capital income/profit tax $\tau_k$ and a book-value wealth tax $\tau_a$. Its gross-of-saving after-tax return $R_k(z_f)$ and infinite-horizon Bellman equation are:  
$$R_k(z_f) = (1 - \tau_a)^5 + (1 - \tau_k)\left(r + \pi_k(z_f)\right)$$  
$$V_{F,k}(a_f, z_f) = \max_{a'_f \in [0, R_k(z_f)a_f]} \left\{ \ln\left(R_k(z_f) a_f - a'_f\right) + \beta_{\text{firm}} \sum_{z'_f} \Pi_{f,k}(z'_f \mid z_f) V_{F,k}(a'_f, z'_f) \right\}$$  
As established in Proposition 6 and Lemma 5 of Guvenen et al., replacing capital income taxation $\tau_k$ with wealth taxation $\tau_a$ shifts the stationary distribution of firm equity $\Gamma_k(a_f, z_f)$ toward high-productivity entrepreneurs ($\mu_{h,k} \uparrow$), increasing equilibrium aggregate productivity $Z(\mu)$ and wages $w_k$ via the **"use-it-or-lose-it" reallocation effect**.

## **5. The 3-Stage Intergenerational & Spatial Transition Matrix**

The stationary distribution of newborn households entering adulthood at $j = 1$ in region $k$, denoted $\mu_{1,k}(a_1, h_1, z_1)$ (`jequaloneDist`), is determined endogenously as a fixed point of three coupled transition operators implemented in `Build_IntergenTransitionMatrix.m`:

### **5.1 Stage 1: Anchored Childhood Skill Formation ($Q_h$)**

Following Cunha, Heckman, and Schennach and Daruich, adult human capital $h_{\text{child}}$ at age 20 ($j=1$) is anchored to childhood cognitive/noncognitive skills produced by parental human capital $h_p$, early-years private + public investment ($i_c + G_{\text{ECE}}$), and a regional housing-stress penalty for low-asset renters in overvalued markets:  
$$\ln(h_{\text{child}}) = \rho_{\text{hc}} \ln(h_p) + \gamma_{\text{ic}} \ln(1 + i_c(a_p, h_p, z_p, k) + G_{\text{ECE}}) - \psi_{\text{crowd}} \ln(Q_k) \mathbb{I}(a_p < 0.05 Q_k) + \eta_h, \quad \eta_h \sim \mathcal{N}(0, \sigma_{\text{hc}}^2)$$  
Integrating over the stationary distribution of fertile parents ($j \in \{3, 4\}$) in region $k$ produces the marginal skill distribution $P_{h,k}(h_1)$.

### **5.2 Stage 2: The \$1.6T Property Bequest & Youth Grant Operator ($Q_a$)**

Following De Nardi and Piketty and Saez, dying retirees ($j \ge J_r$, with mortality weight $1 - s_j$) pass on net-of-tax estates $(1 - \tau_b)a'_j(k)$ augmented by the universal youth grant $E$:  
$$a_{1,\text{inherited}} = (1 - \tau_b) a'_j(a_r, h_r, z_r, j; k) + E$$  
Integrating across dying cohorts in region $k$ yields the pre-migration initial wealth distribution $P_{a,k}(a_1)$.

### **5.3 Stage 3: The $3 \times 3$ Spatial Youth Migration Matrix ($\Pi_{\text{mig}}$)**

Before entering the labor market at $j = 1$, young adults born in origin region $k$ with state $(a_1, h_1, z_1)$ draw Gumbel regional preference shocks with scale $\varrho_{\text{gumbel}}$ and evaluate moving to destination region $k' \in \{\text{Rural}, \text{Urban}, \text{Auckland}\}$ subject to fixed moving/entry cost $\kappa(k, k')$:

$$\mathbb{P}(k \to k' \mid a_1, h_1, z_1) = \frac{\exp\left(V_{k'}(a_1 - \kappa(k,k'), h_1, z_1, 1) / \varrho_{\text{gumbel}}\right)}{\sum_{m=1}^3 \exp\left(V_{m}(a_1 - \kappa(k,m), h_1, z_1, 1) / \varrho_{\text{gumbel}}\right)} \cdot \mathbb{I}(a_1 \ge \kappa(k,k'))$$

## **6. General Equilibrium Market Clearing Conditions**

A Stationary Recursive Competitive Equilibrium consists of value functions $\{V_k, V_{F,k}\}$, policy rules, stationary distributions $\{\mu_k, \Gamma_k\}$, newborn distributions $\{\mu_{1,k}\}$, factor prices $\{r, w_{\text{Rural}}, w_{\text{Urban}}, w_{\text{Auckland}}\}$, regional house prices $\{Q_{\text{Rural}}, Q_{\text{Urban}}, Q_{\text{Auckland}}\}$, and fiscal instruments $\{\tau_l, \tau_c, \tau_k, \tau_a, \tau_b, G_{\text{ECE}}, E, p_{\text{super}}\}$ such that:

> 1. **Regional Labor Markets Clear ($k \in \{\text{Rural}, \text{Urban}, \text{Auckland}\}$):**  
>    $$\int n_k(a_f, z_f; w_k, r) \, d\Gamma_k = \sum_{j=1}^{J_r-1} \mu_j \int z h \max(0, \ell - I_h) \, d\mu_{k,j}$$  
> 2. **Regional Housing Markets Clear ($k \in \{\text{Rural}, \text{Urban}, \text{Auckland}\}$):** Total owner-occupied and rental housing space demanded by young and old households in region $k$ equals elastic regional supply $\text{HS}(k) = H_k (Q_k)^{\delta_{H,k}}$:  
>    $$\sum_{j=1}^J \mu_j \int h_{\text{space}}(a, h, z, j; k) \, d\mu_{k,j} = H_k (Q_k)^{\delta_{H,k}}$$  
> 3. **National Capital / Bond Market Clears:**  
>    $$\sum_{k=1}^3 \omega_{F,k} \int \left(k_k(a_f, z_f) - a_f\right) d\Gamma_k + B_{\text{gov}} = \sum_{k=1}^3 \omega_{HH,k} \sum_{j=1}^J \mu_j \int a_{\text{fin}}(a, h, z, j; k) \, d\mu_{k,j}$$  
> 4. **Crown Fiscal Budget Balance (with Stunted Cohort Remediation Drag):** Total revenues from labor income taxes ($\tau_l$), GST ($\tau_c$), corporate/capital income taxes ($\tau_k$), book-value wealth taxes ($\tau_a$), and estate taxes ($\tau_b$) equal outlays on universal NZ Superannuation ($p_{\text{super}}$), First-2000-Days public ECE ($G_{\text{ECE}}$), youth grants ($E$), regional transfers ($T_k$), and the fiscal remediation drag of stunted cohorts ($\Delta G_{\text{stunted}} \cdot \text{Frac}_{\text{stunted}}$).

## **7. Master Calibration Table (NZ Data & Literature Proxies)**

| Parameter | Symbol | Value | Target / Empirical Source |
| :--- | :--- | :--- | :--- |
| **Demographics & Preferences** | | | |
| Model horizon & retirement | $J, J_r$ | 16, 10 | Ages 20–99 (5-yr brackets); NZ Super eligibility at 65. |
| Household & Firm discount factors | $\beta_{hh}, \beta_{\text{firm}}$ | $0.96^5, 0.95^5$ | Standard OLG benchmark ($\beta \in [0.96, 0.97]$). |
| CRRA risk aversion & labor disutility | $\eta_c, \psi_l$ | 2.0, 1.2 | Separable consumption-leisure life-cycle benchmark. |
| **Lens 1: Child Skill Formation & Public Provision** | | | |
| Intergenerational skill persistence | $\rho_{\text{hc}}$ | 0.40 | Anchored skill persistence & variance explained. |
| Early investment elasticity | $\gamma_{\text{ic}}$ | 0.35 | Early childhood production function estimates. |
| Stone-Geary luxury parameter (ECE) | $\bar{g}_{\text{ECE}}$ | 0.02 | Income elasticity of education/health $\theta \in [1.15, 1.38] > 1$. |
| Pro-equality externality parameters | $\chi, \alpha$ | 0.20, 0.50 | Concave externality calibration ($\chi = 0.2, \alpha \in (-2, 2)$). |
| Baseline stunted cohort share | $\text{Frac}_{\text{stunted}}$ | $0.143\text{--}0.22$ | NZ material hardship & Dunedin Study cohort benchmark. |
| **Lens 2: Adult Ben-Porath & Spatial Income** | | | |
| Adult skill depreciation & elasticities | $\delta_{\text{hc}}, \alpha_I, \alpha_H$ | $0.086, 0.098, 0.051$ | Life-cycle Ben-Porath human capital estimation. |
| Regional income dispersion | $\sigma_z(\text{R, U, Akl})$ | 0.11, 0.16, 0.24 | Spatial income variance ($\nu \in (0.1, 0.2)$) & primate city tail. |
| Mandatory transport/energy cost | $\bar{e}(\text{R, U, Akl})$ | 0.048, 0.026, 0.018 | Rural vs. metropolitan transport/fuel expenditure gap. |
| **Lens 3: Housing, Pensions, Bequests & Firms** | | | |
| Non-durable consumption share | $\phi_{nd}$ | 0.80 | Housing expenditure share $1 - \phi_{nd} = 0.20$. |
| Maintenance, HO subsidy, tenure bound | $\mu_{\text{maint}}, \upsilon_h, \bar{\chi}$ | 0.04, 0.008, 2.55 | Kiyotaki, Michaelides, & Nikolov housing calibration. |
| Regional housing supply elasticity | $\delta_H(\text{R, U, Akl})$ | 0.35, 0.22, 0.10 | Inelastic metropolitan land vs. elastic rural supply. |
| Regional trend growth factors | $G(\text{R, U, Akl})$ | 1.007, 1.015, 1.025 | Unbalanced sectoral growth ($G_{\text{Akl}} > G_{\text{Rural}}$). |
| Retirement floor & NZ Super | $\underline{c}, p_{\text{super}}$ | 0.04, 0.18 | Retirement consumption floor & pension replacement rate. |
| Warm-glow luxury bequest parameters | $b_1, b_2$ | 4.20, 0.45 | Top wealth decile share (~50% of total wealth). |
| Firm collateral multiplier & return gap | $\lambda_{\text{col}}, z_h / z_\ell$ | 1.80, 1.94 | Heterogeneous-return firm equilibrium bounds. |

## **8. File Manifest & Execution Workflow in MATLAB**

Your VFI Toolkit repository consists of five modular MATLAB scripts that execute in sequence:

> 1. `NZ_3Region_Master.m`: Initializes the 6 Permanent Types (`HH_Rural`, `HH_Urban`, `HH_Auckland`, `Firm_Rural`, `Firm_Urban`, `Firm_Auckland`), constructs the demographic matrix $\mathbf{T}_{\text{demo}}$, sets up state/decision grids, calls `ValueFnIter_PType` on the GPU, and iterates on the intergenerational fixed point.  
> 2. `ReturnFn_SpatialHH.m`: Evaluates the finite-horizon household Bellman objective, enforcing the Ben-Porath human capital law of motion, Kiyotaki et al. analytical tenure cutoffs $\xi_k$ and user costs $rh_k, rr_k$, luxury early-childhood investment, and warm-glow estate bequests.  
> 3. `ReturnFn_Firm.m`: Evaluates the infinite-horizon firm Bellman objective with collateral constraint $\lambda_{\text{col}}$ and book-value wealth tax $\tau_a$ vs. capital income tax $\tau_k$.  
> 4. `Build_IntergenTransitionMatrix.m`: Computes the 3-stage transition from fertile parents ($j \in \{3,4\}$) and dying retirees ($j \ge J_r$) to newborn human capital $\mathbf{Q}_h$, property inheritances $\mathbf{Q}_a$, and $3 \times 3$ Gumbel youth spatial sorting $\Pi_{\text{mig}}$ across Rural, Urban, and Auckland.  
> 5. `WelfareDecomposition_3Region.m`: Runs the policy counterfactuals and outputs the three publication-ready Consumption Equivalence (CE %) tables:  
   * *Table 1:* Short-Run PE vs. Long-Run GE and Exogenous vs. Endogenous Intergenerational Skill Transmission.  
   * *Table 2:* Spatial (Rural, Urban, Auckland) $\times$ Income Quintile ($Q_1\text{--}Q_5$) Welfare Matrix.  
   * *Table 3:* Housing Tenure & Generational Cleavage (Young Renters vs. Young Leveraged Homeowners vs. Older Retirees/Landlords).