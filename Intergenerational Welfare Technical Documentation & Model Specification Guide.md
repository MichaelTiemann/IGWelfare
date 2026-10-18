# Intergenerational Welfare Technical Documentation & Model Specification Guide

**A Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial OLG Model of Intergenerational Welfare, Housing Wealth, and Human Capital in New Zealand**

## 1. Executive Overview & 8-fold Permanent Type (PType) Computational Architecture

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

---

## 2. Macro Demographic & Dynamic Regional Population Law of Motion

Following the NZ Treasury OLG framework (Binning et al., 2024), cohorts age across $J=16$ five-year brackets (ages 20–99, retirement at $J_r=10$, age 65) via survival probabilities $s_j$, fertility rates $f_j$, and age-specific net migration rates:

$$N_t = T_{t-1} N_{t-1} + M_{t-1}$$

Along the 60-year transition path ($t = 1, \dots, T_{\text{trans}}$), the 4-region household population share vector $s_{HH,t} = [s_{\text{Rural},t}, s_{\text{Small},t}, s_{\text{Large},t}, s_{\text{Auckland},t}]$ and firm share vector $s_{F,t}$ evolve endogenously from their Stats NZ 2025 base ([0.160, 0.240, 0.259, 0.341] and [0.150, 0.230, 0.269, 0.351]) via domestic youth sorting $\Pi_{\text{mig},t}^{\text{dom}}$ (the normalized $4 \times 4$ domestic submatrix of the $4 \times 5$ migration operator) and international net migration inflows $m_{\text{intl}} = [0.115, 0.210, 0.270, 0.405]$:

$$\tilde{s}_{HH,t} = (1 - 0.12) s_{HH,t} + 0.12 \left( s_{HH,t} \Pi_{\text{mig},t}^{\text{dom}} \right)$$

$$s_{HH,t+1} = \frac{(1 - \zeta_{\text{inflow}}) \tilde{s}_{HH,t} + \zeta_{\text{inflow}} m_{\text{intl}}}{\sum_{k=1}^4 \left[ (1 - \zeta_{\text{inflow}}) \tilde{s}_{HH,k,t} + \zeta_{\text{inflow}} m_{\text{intl},k} \right]}, \qquad s_{F,t+1} = 0.85 s_{F,t} + 0.15 s_{HH,t+1}$$

---

## 3. Finite-Horizon Household Problem (Lenses 1, 2, and 3)

In Upgrade B (5D full specification), a household of age $j \in \{1, \dots, 16\}$ in region $k \in \{\text{Rural}, \text{Small}, \text{Large}, \text{Auckland}\}$ has state vector:

$$s_{HH} = (a, h, \theta_c, z, j; k)$$

where $a \in A_{HH}$ (61 points) is consolidated net worth ($Q_k h_{\text{house}} - b_{\text{debt}}$), $h \in H$ (7 points) is adult human capital, $\theta_c \in \Theta_c$ (9 points) is the child's multi-stage skill experience asset, and $z \in Z_k$ (5 points) is a region-specific Markov labor productivity shock. Decisions are $d = (i_c, \ell, I_h)$ (early/school-age child investment, labor supply, and adult Ben-Porath training).

### 3.1 Housing Tenure Choice, User Costs, and 4-Region Unbalanced Growth

Following Kiyotaki, Michaelides, and Nikolov (2024) and Hirano and Toda (2025), let $Q_k$ be the regional house price, $R_{\text{ann}} = (1+r)^{1/5}$ the gross annualized interest rate, $\mu_{\text{maint}} = 0.04$ maintenance/rates, $\upsilon_h = 0.008$ the owner-occupied tax subsidy, and $G_k$ the regional trend growth factor ($G_{\text{Auckland}} = 1.025 > G_{\text{Large}} = 1.018 > G_{\text{Small}} = 1.011 > G_{\text{Rural}} = 1.007$):

$$rr_k = \left( 1 + \mu_{\text{maint}} - \frac{G_k}{R_{\text{ann}}} \right) Q_k, \qquad rh_k = \left( 1 + \mu_{\text{maint}} - \upsilon_h - \frac{G_k}{R_{\text{ann}}} \right) Q_k$$

Young working households ($j < J_r$) draw an idiosyncratic rental utility penalty $\chi \sim U[0, \bar{\chi}]$ ($\bar{\chi} = 2.55$), yielding the analytical regional homeownership share $\xi_k$ and composite housing price index $p_{H,k}(j)$:

$$\xi_k = \min\left\{ 1, \frac{1}{\bar{\chi}} \left( \frac{rr_k}{rh_k} \right) \right\}, \qquad p_{H,k}(j) = \begin{cases} \xi_k rh_k + (1 - \xi_k) \frac{rr_k}{0.5 \bar{\chi}} & \text{if } j < J_r \\ rh_k & \text{if } j \ge J_r \end{cases}$$

### 3.2 Two-Stage Childhood CES Skill Law of Motion (`ChildCES_aprimeFn.m`) & Adult Ben-Porath Dynamics

* **Child Experience Asset ($\theta'_c$):** Driven by private investment $i_c$, stage-specific public wraparound provision ($G_{\text{ECE},1}$ at $j=3$ vs. $G_{\text{ECE},2}$ at $j=4$), and Stone-Geary luxury floor $\bar{g}_{\text{ECE}} = 0.02$:

$$\theta'_c = \begin{cases} \left[ \gamma_{1,\text{self}} \theta_c^{\varphi_1} + \gamma_{1,\text{inv}} (i_c + G_{\text{ECE},1} + \bar{g}_{\text{ECE}})^{\varphi_1} + \gamma_{1,\text{par}} \bar{h}_p^{\varphi_1} \right]^{1/\varphi_1} & \text{if } j = 3 \text{ (First 2000 Days, } \varphi_1 = 0.35\text{)} \\ \left[ \gamma_{2,\text{self}} \theta_c^{\varphi_2} + \gamma_{2,\text{inv}} (i_c + G_{\text{ECE},2} + \bar{g}_{\text{ECE}})^{\varphi_2} + \gamma_{2,\text{par}} \bar{h}_p^{\varphi_2} \right]^{1/\varphi_2} & \text{if } j = 4 \text{ (School Years, } \varphi_2 = -0.95\text{)} \\ \theta_c & \text{otherwise} \end{cases}$$

* **Adult Ben-Porath Human Capital ($h'$):** During working ages ($j < J_r$), adult skill evolves via $h' = (1 - \delta_{\text{hc}}) h + I_h^{\alpha_I} h^{\alpha_H}$ with $\delta_{\text{hc}} = 0.087, \alpha_I = 0.090, \alpha_H = 0.064$.

### 3.3 Recursive Bellman Equation of the Household

The value function $V_k(a, h, \theta_c, z, j)$ solves:

$$V_k(a, h, \theta_c, z, j) = \max_{i_c, \ell, I_h, a', h'} \left\{ \frac{u_{\text{comp}}^{1 - \eta_c}}{1 - \eta_c} - \psi_l \frac{\ell^2}{2} + X_t + \Phi_{\text{child}}(i_c, \theta'_c, j) + \Phi_{\text{ret}}(a', \text{Frac}_{\text{stunted}}, S_t, j) + \beta_{hh} s_j \sum_{z'} \Pi_{z,k}(z' \mid z) V_k(a', h', \theta'_c, z', j+1) \right\}$$

where composite non-durable and housing consumption $u_{\text{comp}}$ deducts mandatory regional transport/energy subsistence $\bar{e}_k$ and adds the **Income $\times$ Geography** transfer $T_k(y)$, while retirees ($j \ge J_r$) derive relational utility from domestic youth thriving $(1 - \text{Frac}_{\text{stunted}})$, social cohesion / retention $S_t$, and warm-glow luxury bequests over net-of-tax estates $(1 - \tau_b) a'$.

---

## 4. Infinite-Horizon Firm Sector (The Guvenen et al. Engine Across 4 Regions)

In each region $k \in \{\text{Rural}, \text{Small}, \text{Large}, \text{Auckland}\}$, a continuum of infinite-horizon entrepreneurs (`Firm_k`, $N_j = \infty$) with persistent talent $z_f \in \{z_{\ell,k}, z_{h,k}\}$ operates a constant-returns technology subject to collateral constraint $k \le \lambda_{\text{col}} a_f$ ($\lambda_{\text{col}} = 1.80$):

$$V_{F,k}(a_f, z_f) = \max_{a'_f} \left\{ \ln\left( R_k(z_f; w_k, r, \tau_k, \tau_a) a_f - a'_f \right) + \beta_{\text{firm}} \sum_{z'_f} \Pi_{f,k}(z'_f \mid z_f) V_{F,k}(a'_f, z'_f) \right\}$$

Replacing capital income taxation ($\tau_k$) with a book-value wealth tax ($\tau_a = 0.015$) shifts stationary firm net worth $\Gamma_k(a_f, z_f)$ toward high-talent entrepreneurs $z_{h,k}$—with the largest productivity multiplier occurring in `Firm_Auckland` ($z_h = 1.75$, 35.1% of NZ businesses) and `Firm_Large` ($z_h = 1.50$, 26.9% of NZ businesses).

---

## 5. The 3-Stage Intergenerational & $4 \times 5$ Abroad Spatial Transition Operator

The stationary distribution of newborn households entering adulthood at $j=1$ in region $k$, denoted $\mu_{1,k}(a_1, h_1, z_1)$ (`jequaloneDist`), is computed as a fixed point of three coupled operators inside `Build_IntergenTransitionMatrix_UpgradeB.m` (5D) and `Build_IntergenTransitionMatrix.m` (4D):

### Stage 1: Completed Childhood Skill Formation ($Q_h$)

* In the 5D experience-asset model (`UpgradeB`), completed Stage-2 childhood skill $\theta_3 = \theta'_c(j=4)$ is extracted directly from parents reaching $j=5$ and mapped onto the child's adult human capital grid `a_grid_hc`, penalized by metropolitan housing crowding $\psi_{\text{crowd}} \ln(Q_k) \mathbb{I}(a_p < 0.05 Q_k)$.
* In the compact 4D projection, expected log skill follows the anchored Cobb-Douglas relation:

$$\ln(h_{\text{child}}) = \rho_{\text{hc}} \ln(h_p) + \gamma_{\text{ic}} \ln\left(1 + i_c(a_p, h_p, z_p, k) + G_{\text{ECE}}\right) - \psi_{\text{crowd}} \ln(Q_k) \mathbb{I}(a_p < 0.05 Q_k) + \eta_h, \qquad \eta_h \sim \mathcal{N}(0, \sigma_{\text{hc}}^2)$$

### Stage 2: The \$1.6T Property Bequest & Youth Grant Operator ($Q_a$)

Dying retirees ($j \ge J_r$) in region $k$ leave net-of-tax property estates $(1 - \tau_b) a'_j(k)$. Combined with the universal Youth Capital Grant $E$ (`YouthGrant`), this induces the initial wealth distribution $P_{a,k}(a_1)$, where Auckland retirees generate the largest estate flows (`MeanBequest.Auckland`) due to $Q_{\text{Auckland}} = 3.10$.

### Stage 3: The $4 \times 5$ Domestic & International (Abroad) Gumbel Youth Sorting Matrix ($\Pi_{\text{mig}}$)

Before settling into working life at $j=1$ (and early career $j=2$), young adults in origin region $k \in \{\text{Rural}, \text{Small}, \text{Large}, \text{Auckland}\}$ evaluate the 4 domestic regions $m \in \{1, 2, 3, 4\}$ (paying moving/entry cost $\kappa(k, m)$) against the **5th outside option: emigrating to Abroad (Australia/OECD)** with value $V_{\text{Abroad},t}(a_1, h_1, z_1)$:

$$\mathbb{P}_t(k \to m \mid a_1, h_1, z_1) = \frac{\exp\left(V_{m,t}(a_1 - \kappa(k,m), h_1, z_1, 1) / \varrho\right)}{\exp\left(V_{\text{Abroad},t}(a_1, h_1, z_1, 1) / \varrho\right) + \sum_{r=1}^4 \exp\left(V_{r,t}(a_1 - \kappa(k,r), h_1, z_1, 1) / \varrho\right)}$$

$$P_{\text{emig},t}(a_1, h_1, z_1; k) = \frac{\exp\left(V_{\text{Abroad},t}(a_1, h_1, z_1, 1) / \varrho\right)}{\exp\left(V_{\text{Abroad},t}(a_1, h_1, z_1, 1) / \varrho\right) + \sum_{r=1}^4 \exp\left(V_{r,t}(a_1 - \kappa(k,r), h_1, z_1, 1) / \varrho\right)}$$

Each state cell $(a_1, h_1, z_1)$ is weighted by its domestic retention probability $(1 - P_{\text{emig},t})$, capturing both the **Rural/Small $\to$ Large $\to$ Auckland** domestic stepping-stone funnel and the selective brain-drain depletion of high-skill ($h_5 - h_7$), low-asset youth to Australia/OECD.

---

## 6. Master 4-Region Calibration Table (Stats NZ 2025/2026 & Literature Benchmarks)

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

---

## 7. Complete 11-File VFI Toolkit Pipeline Manifest (4-Region + Abroad Suite)

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
