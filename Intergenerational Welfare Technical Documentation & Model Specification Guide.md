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

$$\tilde{s}_{HH,t} = (1 - 0.12) s_{HH,t} + 0.12 \left\lparen s_{HH,t} \Pi_{\text{mig},t}^{\text{dom}} \right\rparen$$

$$s_{HH,t+1} = \frac{(1 - \zeta_{\text{inflow}}) \tilde{s}_{HH,t} + \zeta_{\text{inflow}} m_{\text{intl}}}{\sum_{k=1}^4 \left\lbrack (1 - \zeta_{\text{inflow}}) \tilde{s}_{HH,k,t} + \zeta_{\text{inflow}} m_{\text{intl},k} \right\rbrack}$$

$$s_{F,t+1} = 0.85 s_{F,t} + 0.15 s_{HH,t+1}$$

## **3. Finite-Horizon Household Problem (Lenses 1, 2, and 3)**

In Upgrade B (5D full specification), a household of age $j \in \{1, \dots, 16\}$ in region $k \in \{\text{Rural}, \text{Small}, \text{Large}, \text{Auckland}\}$ has state vector:

$$s_{HH} = (a, h, \theta_c, z, j; k)$$

where $a \in A_{HH}$ (61 points) is consolidated net worth ($Q_k h_{\text{house}} - b_{\text{debt}}$), $h \in H$ (7 points) is adult human capital, $\theta_c \in \Theta_c$ (9 points) is the child's multi-stage skill experience asset, and $z \in Z_k$ (5 points) is a region-specific Markov labor productivity shock. Decisions are $d = (i_c, \ell, I_h)$ (early/school-age child investment, labor supply, and adult Ben-Porath training).

### **3.1 Housing Tenure Choice, User Costs, and 4-Region Unbalanced Growth**

Following Kiyotaki, Michaelides, and Nikolov (2024) and Hirano and Toda (2025), let $Q_k$ be the regional house price, $R_{\text{ann}} = (1+r)^{1/5}$ the gross annualized interest rate, $\mu_{\text{maint}} = 0.04$ maintenance/rates, $\upsilon_h = 0.008$ the owner-occupied tax subsidy, and $G_k$ the regional trend growth factor ($G_{\text{Auckland}} = 1.025 > G_{\text{Large}} = 1.018 > G_{\text{Small}} = 1.011 > G_{\text{Rural}} = 1.007$):

$$rr_k = \left\lparen 1 + \mu_{\text{maint}} - \frac{G_k}{R_{\text{ann}}} \right\rparen Q_k$$

$$rh_k = \left\lparen 1 + \mu_{\text{maint}} - \upsilon_h - \frac{G_k}{R_{\text{ann}}} \right\rparen Q_k$$

Young working households ($j < J_r$) draw an idiosyncratic rental utility penalty $\chi \sim U[0, \bar{\chi}]$ ($\bar{\chi} = 2.55$), yielding the analytical regional homeownership share $\xi_k$ and composite housing price index $p_{H,k}(j)$:

$$\xi_k = \min\left\lbrace 1, \frac{1}{\bar{\chi}} \left\lparen \frac{rr_k}{rh_k} \right\rparen \right\rbrace$$

$$p_{H,k}(j) = \begin{cases} \xi_k rh_k + (1 - \xi_k) \frac{rr_k}{0.5 \bar{\chi}} & \text{if } j < J_r \\  rh_k & \text{if } j \ge J_r \end{cases}$$

### **3.2 Two-Stage Childhood CES Skill Law of Motion (`ChildCES_aprimeFn.m`) & Adult Ben-Porath Dynamics**

* **Child Experience Asset ($\theta'_c$):** Driven by private investment $i_c$, stage