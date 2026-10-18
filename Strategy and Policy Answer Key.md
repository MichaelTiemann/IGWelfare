# Intergenerational Welfare: Model-to-Policy Quantitative Answer Key
**Exact Cross-Reference Guide Linking Strategic Claims to VFI Toolkit Variables, Equations, and CSV/PNG Outputs (4-Region + Abroad Edition)**[cite: 2, 3, 4]

---

## 1. Purpose of This Answer Key
This document serves as the quantitative companion ("Answer Key") to **Document 1A (*Intergenerational Welfare, Capital Allocation, and Human Potential in New Zealand — Reader's Edition*)**[cite: 2]. Every strategic claim, percentage gain, and demographic projection in Document 1A is mapped below to its exact **MATLAB script**, **VFI Toolkit parameter/grid index**, **structural equation**, and **output CSV file** in [`Output_NZ_4Region_Intergen`](https://github.com/MichaelTiemann/IGWelfare/tree/main/Output_NZ_4Region_Intergen)[cite: 3].

---

## 2. Audience-by-Audience Claim-to-Code Cross-Reference

### A. Philanthropist Section Cross-Reference (`Lens 1: ChildCES_aprimeFn.m` & `PolicyExperiment_LeeSeshadri_4Region.m`)[cite: 3]
* **4-Region Household Population Shares:**
  * *Reader's Edition Claim:* Rural ($16.0\%$), Small ($24.0\%$), Large ($25.9\%$), Auckland ($34.1\%$).
  * *Code & CSV Mapping:* Initialized in `NZ_4Region_Master_UpgradeB.m` via `Params.PTypeWeights(1:4)` normalized to `[0.160, 0.240, 0.259, 0.341]` (Stats NZ June 2025 Subnational Population Estimates); tracked dynamically over $t = 1 \dots 60$ in [`Table9_4Region_Dynamic_Population_Shares.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv)[cite: 3].
* **Intergenerational Borrowing Constraint & Private Corner Solution ($i_c = 0$):**
  * *Reader's Edition Claim:* Cash-poor parents in high-housing-cost metros hit a corner solution where private early investment collapses[cite: 3, 7].
  * *Code & Math Mapping:* In `ReturnFn_SpatialHH_UpgradeB.m`, young parents at $j \in \lbrace 3, 4 \rbrace$ cannot choose negative net worth ($a^{\prime} \ge 0$ on `a_grid_assets`) against the child's future adult human capital $h^{\prime}_1$[cite: 3]. When regional house prices $Q_k$ (`Params.Q_reg`: Rural $= 1.05$, Small $= 1.40$, Large $= 2.05$, Auckland $= 3.10$) inflate user costs $rr_k, rh_k$ or mandatory transport subsistence $\bar{e}_k$ (`Params.ebar_energy`: Rural $= 0.048$, Small $= 0.036$, Large $= 0.022$, Auckland $= 0.016$) binds, optimal private investment $d_1 = i_c \in \lbrack 0, 0.50\rbrack$ hits `d_grid_ic(1) = 0`[cite: 3].
* **Two-Stage CES Skill Technology ($\theta_c$ Experience Asset):**
  * *Reader's Edition Claim:* First 2000 Days (ages 0–5) have high substitutability, while school years (ages 6–17) exhibit strong dynamic complementarity[cite: 1, 3, 6].
  * *Code & Math Mapping:* Implemented in `ChildCES_aprimeFn.m` with `vfoptions.experienceasset = 1` over the 9-point grid `a_grid_thetac`[cite: 3, 11]:
    * **Stage 1 (First 2000 Days, parental age $j = 3$, child ages 0–5):** `Params.phi1_ces` $= \varphi_1 = 0.35 > 0$ (elasticity of substitution $\sigma_1 = \frac{1}{1 - \varphi_1} = 1.54 > 1$), `gamma1_self = 0.53`, `gamma1_inv = 0.24`, `gamma1_par = 0.23`, public lever `Params.G_ece_stage1 = 0.045`, luxury floor `Params.gbar_ece = 0.020`[cite: 1, 3].
    * **Stage 2 (School Years, parental age $j = 4$, child ages 6–17):** `Params.phi2_ces` $= \varphi_2 = -0.95 < 0$ (elasticity of substitution $\sigma_2 = \frac{1}{1 - \varphi_2} = 0.51 < 1$), `gamma2_self = 0.87`, `gamma2_inv = 0.07`, `gamma2_par = 0.06`, public lever `Params.G_ece_stage2 = 0.065`[cite: 1, 3].

### B. Venture & Growth Capital Section Cross-Reference (`Lens 2 & Lens 3: ReturnFn_Firm.m` & `Build_IntergenTransitionMatrix.m`)[cite: 3, 7]
* **4-Region Business Firm Shares & Entrepreneurial Productivity Ceilings:**
  * *Reader's Edition Claim:* 35.1% of NZ businesses operate in Auckland and 26.9% in Large regional cities, with the highest productivity ceilings[cite: 3].
  * *Code Mapping:* `Params.PTypeWeights(5:8)` normalized to `[0.150, 0.230, 0.269, 0.351]` (Stats NZ Feb 2025 Business Demography). Infinite-horizon firm productivity grids `z_grid.Firm_k` ($z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$) are calibrated as:
    * `Firm_Rural`: $\lbrack 0.70, 1.15\rbrack$, trend growth $G_{\mathrm{Rural}} = 1.007$[cite: 3, 7].
    * `Firm_Small`: $\lbrack 0.75, 1.28\rbrack$, trend growth $G_{\mathrm{Small}} = 1.011$.
    * `Firm_Large`: $\lbrack 0.83, 1.50\rbrack$, trend growth $G_{\mathrm{Large}} = 1.018$.
    * `Firm_Auckland`: $\lbrack 0.90, 1.75\rbrack$, trend growth $G_{\mathrm{Auckland}} = 1.025$[cite: 3, 7].
* **Guvenen et al. Tax Shift & Wage/House Price Multipliers:**
  * *Reader's Edition Claim:* Shifting from $\tau_k$ to $\tau_a = 1.5\%$ and $\tau_b = 25\%$ on the \$1.6T property transfer lifts regional wages by $+3.2\%$ to $+5.5\%$ and cools urban house prices by $-5.0\%$ to $-7.5\%$[cite: 3].
  * *Code Mapping:* In `WelfareDecomposition_4Region.m`, `Params_Reform.tau_a = 0.015`, `Params_Reform.tau_b = 0.25`, `Params_Reform.YouthGrant = 0.065`, with general equilibrium multipliers `w_mult_GE = [1.032, 1.038, 1.048, 1.055]` and `Q_mult_GE = [0.990, 0.975, 0.950, 0.925]` across `{Rural, Small, Large, Auckland}`[cite: 3].

### C. Policy-Maker Section Cross-Reference (`FertilityBargaining_Module.m` & `WelfareDecomposition_4Region.m`)[cite: 3]
* **4-Region "Income x Geography" Transfer Vector (`Params_Reform.Transfer_Geo`):**
  * Baseline transfers `[0.025, 0.020, 0.016, 0.014]` scale under reform to `Params_Reform.Transfer_Geo = [0.038, 0.031, 0.025, 0.028]` across `{HH_Rural, HH_Small, HH_Large, HH_Auckland}` to offset Rural/Small transport subsistence $\bar{e}_k$ and Large/Auckland rental stress[cite: 3].

---

## 3. Complete Empirical CSV Tables (Exact Model Outputs)

### Table 12A: Intergenerational Elasticity of Earnings (`IGE`) — Short-Run PE (`SR`) vs. Long-Run GE (`LR`)
*Source File: [`Table12A_LeeSeshadri_4Region_IGE.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12A_LeeSeshadri_4Region_IGE.csv)*[cite: 8]

| `Row` (Policy Regime) | `Rural_SR` | `Small_SR` | `Large_SR` | `Auckland_SR` | `Rural_LR` | `Small_LR` | `Large_LR` | `Auckland_LR` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline`** | $0.2535$ | $0.2383$ | $0.3488$ | $0.4448$ | $0.2535$ | $0.2383$ | $0.3488$ | $0.4448$ |
| **`P0_Early_0to5`** | $0.2535$ | $0.2391$ | $0.3274$ | $0.4387$ | $0.2653$ | $0.2388$ | $0.3655$ | **$0.4218$** |
| **`P1P2_Late_6to17`** | $0.2764$ | $0.2626$ | $0.3466$ | $0.4335$ | $0.2882$ | $0.2660$ | $0.3555$ | $0.4215$ |
| **`BN_FrontLoad`** | **$0.2345$** | **$0.2202$** | $0.3522$ | $0.4475$ | **$0.2347$** | **$0.2193$** | $0.3635$ | $0.4477$ |
| **`P0_Plus_GrantE`** | $0.2558$ | $0.2412$ | **$0.3279$** | **$0.4377$** | $0.2571$ | **$0.2359$** | $0.3620$ | **$0.4264$** |

---

### Table 12B: Variance of Adult Human Capital ($h_1$) & Lifetime Earnings (`LFE`) Explained by Parental State at Age 30–35, Plus Log Earnings Variance (`VarLogE`)
*Source File: [`Table12B_LeeSeshadri_4Region_VarExpl.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12B_LeeSeshadri_4Region_VarExpl.csv)*[cite: 9]

| `Row` (Policy Regime) | `VarExpl_h1_Rural` (%) | `VarExpl_h1_Small` (%) | `VarExpl_h1_Large` (%) | `VarExpl_h1_Auckland` (%) | `VarExpl_LFE_Rural` (%) | `VarExpl_LFE_Small` (%) | `VarExpl_LFE_Large` (%) | `VarExpl_LFE_Auckland` (%) | `VarLogE_Rural` | `VarLogE_Small` | `VarLogE_Large` | `VarLogE_Auckland` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline`** | $58.80\%$ | $62.91\%$ | $79.24\%$ | $85.81\%$ | $70.74\%$ | $73.23\%$ | $83.98\%$ | $88.74\%$ | $0.1209$ | $0.2510$ | $0.3471$ | $0.4155$ |
| **`P0_Early_0to5`** | $64.36\%$ | $66.71\%$ | **$78.31\%$** | **$84.37\%$** | $74.13\%$ | $75.61\%$ | **$83.33\%$** | **$87.67\%$** | $0.1500$ | $0.2864$ | **$0.3161$** | **$0.4047$** |
| **`P1P2_Late_6to17`** | $63.01\%$ | $66.11\%$ | $78.26\%$ | $84.44\%$ | $73.29\%$ | $75.22\%$ | $83.30\%$ | $87.73\%$ | $0.1322$ | $0.2692$ | $0.3304$ | $0.4079$ |
| **`BN_FrontLoad`** | $58.92\%$ | $62.88\%$ | $79.79\%$ | $85.89\%$ | $70.81\%$ | $73.21\%$ | $84.37\%$ | $88.80\%$ | $0.1239$ | $0.2551$ | $0.3454$ | $0.4161$ |
| **`P0_Plus_GrantE`** | $63.03\%$ | $66.07\%$ | **$77.87\%$** | **$84.35\%$** | $73.31\%$ | $75.20\%$ | **$83.02\%$** | **$87.66\%$** | $0.1491$ | $0.2869$ | **$0.3133$** | **$0.4052$** |

---

### Table 12C: Percentage Change in Average Lifetime Earnings (`Ebar` %) & Newborn Consumption Equivalent Welfare (`CE_LR` %)
*Source File: [`Table12C_LeeSeshadri_4Region_Welfare.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12C_LeeSeshadri_4Region_Welfare.csv)*[cite: 3]

| `Row` (Policy Regime) | `Ebar_SR_Rural` (%) | `Ebar_SR_Small` (%) | `Ebar_SR_Large` (%) | `Ebar_SR_Auckland` (%) | `Ebar_LR_Rural` (%) | `Ebar_LR_Small` (%) | `Ebar_LR_Large` (%) | `Ebar_LR_Auckland` (%) | `CE_LR_Rural` (%) | `CE_LR_Small` (%) | `CE_LR_Large` (%) | `CE_LR_Auckland` (%) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline`** | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ |
| **`P0_Early_0to5`** | $-0.03\%$ | $-0.07\%$ | $-0.10\%$ | $-0.01\%$ | **$+10.63\%$** | **$+19.97\%$** | **$+11.22\%$** | **$+3.94\%$** | **$+9.99\%$** | **$+12.48\%$** | **$+14.33\%$** | **$+5.54\%$** |
| **`P1P2_Late_6to17`** | $-0.01\%$ | $-0.07\%$ | $-0.10\%$ | $-0.01\%$ | $+3.55\%$ | $+6.96\%$ | $+5.16\%$ | $+1.33\%$ | $+3.26\%$ | $+4.53\%$ | $+6.84\%$ | $+2.48\%$ |
| **`BN_FrontLoad`** | $-0.03\%$ | $-0.08\%$ | $-0.10\%$ | $-0.01\%$ | $+1.75\%$ | $+2.19\%$ | $+2.09\%$ | $+1.29\%$ | $+1.72\%$ | $+1.60\%$ | $+2.39\%$ | $+1.41\%$ |
| **`P0_Plus_GrantE`** | $-0.07\%$ | $+0.88\%$ | $-0.05\%$ | $-0.01\%$ | **$+10.51\%$** | **$+20.80\%$** | **$+11.91\%$** | **$+3.38\%$** | **$+18.13\%$** | **$+18.55\%$** | **$+18.66\%$** | **$+4.85\%$** |

---

### Table Fert1: Endogenous Total Fertility Rate (`TFR`) & Differential Fertility Ratio (`DiffFert` = Low-Skill / High-Skill Fertility)
*Source File: [`Table_Fert1_4Region_TFR_DiffFertility.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table_Fert1_4Region_TFR_DiffFertility.csv)*[cite: 3]

| `Row` (Fertility Scenario) | `TFR_Rural` | `TFR_Small` | `TFR_Large` | `TFR_Auckland` | `DiffFert_Rural` | `DiffFert_Small` | `DiffFert_Large` | `DiffFert_Auckland` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1_Baseline_StatusQuo`** | $3.7944$ | $3.7923$ | $3.5681$ | **$1.4227$** | $1.0442$ | $1.0772$ | $2.1802$ | $2.9841$ |
| **`2_Hyperbolic_NoCommit` ($\beta_{\mathrm{hyp}}=0.72$)** | $3.7920$ | $3.7859$ | $3.4173$ | **$1.1765$** | $1.0695$ | $1.1480$ | $2.6157$ | $2.8548$ |
| **`3_Barnardos_ECE_Bargaining_Relief`** | $3.7950$ | $3.7942$ | **$3.6815$** | **$1.7453$** | $1.0384$ | $1.0558$ | **$1.5562$** | $3.0226$ |
| **`4_Full_Package` (ECE1 + Housing Cool + Commit)** | $3.7950$ | $3.7942$ | **$3.6817$** | **$1.7460$** | $1.0385$ | $1.0561$ | **$1.5566$** | $3.0235$ |

---

### Table Fert2: Stunted Cohort Share, 65+ Aged Dependency Ratio, and Required Labor Tax Rate ($\tau_l$)
*Source File: [`Table_Fert2_4Region_Stunting_NZSuper.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table_Fert2_4Region_Stunting_NZSuper.csv)*[cite: 3]

| `Row` (Fertility Scenario) | `Stunted_Rural_Pct` | `Stunted_Small_Pct` | `Stunted_Large_Pct` | `Stunted_Auckland_Pct` | `DepRatio_65Plus_Pct` | `Required_LaborTax_Pct` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1_Baseline_StatusQuo`** | $97.22\%$ | $96.45\%$ | $89.50\%$ | $46.58\%$ | $12.95\%$ | $26.96\%$ |
| **`2_Hyperbolic_NoCommit` ($\beta_{\mathrm{hyp}}=0.72$)** | $97.23\%$ | $96.48\%$ | $91.01\%$ | $48.16\%$ | **$14.79\%$** | $27.41\%$ |
| **`3_Barnardos_ECE_Bargaining_Relief`** | $97.22\%$ | $96.44\%$ | $88.14\%$ | $43.47\%$ | **$11.20\%$** | $28.12\%$ |
| **`4_Full_Package` (ECE1 + Housing Cool + Commit)** | $97.22\%$ | $96.44\%$ | **$88.09\%$** | **$43.42\%$** | **$11.19\%$** | **$28.10\%$** |

---

## 4. Methodological Defense & Core Equations (For Economic Reviewers)

### A.1 Mixed Finite/Infinite-Horizon 8-PType GPU Architecture
In `NZ_4Region_Master_UpgradeB.m`, the economy is partitioned into `Names_i = {'HH_Rural', 'HH_Small', 'HH_Large', 'HH_Auckland', 'Firm_Rural', 'Firm_Small', 'Firm_Large', 'Firm_Auckland'}` with `N_j.HH_k = 16` and `N_j.Firm_k = Inf`[cite: 3]. Infinite-horizon firms in region $k$ with persistent productivity $z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$ borrow up to collateral limit $k \le \lambda_{\mathrm{col}} a_f$ ($\lambda_{\mathrm{col}} = 1.80$) and solve[cite: 3, 7]:

$$V_{F,k}\left(a_f, z_f\right) = \max_{a^{\prime}_f \in \lbrack 0, R_k\left(z_f\right) a_f\rbrack} \left\lbrace \ln\left(R_k\left(z_f\right) a_f - a^{\prime}_f\right) + \beta_{\mathrm{firm}} \sum_{z^{\prime}_f} \Pi_{f,k}\left(z^{\prime}_f \vert z_f\right) V_{F,k}\left(a^{\prime}_f, z^{\prime}_f\right) \right\rbrace$$

where the 5-year gross after-tax return on firm equity $R_k\left(z_f\right)$ is:

$$R_k\left(z_f\right) = \left(1 - \tau_a\right)^5 + \left(1 - \tau_k\right) \left\lbrace r + \max\left(0, \alpha_k \left(\frac{1 - \alpha_k}{w_k}\right)^{\frac{1 - \alpha_k}{\alpha_k}} z_f - \left(r + \delta_k\right) \right) \lambda_{\mathrm{col}} \right\rbrace$$

### A.2 Two-Stage Child Skill Experience Asset ($\theta_c$) & Adult Ben-Porath ($h$)
In `ChildCES_aprimeFn.m`, the child's skill stock $\theta_c$ evolves across $j=3$ (First 2000 Days, $\varphi_1 = 0.35$) and $j=4$ (Schooling, $\varphi_2 = -0.95$) via[cite: 1, 3]:

$$\theta^{\prime}_c = \begin{cases}
\left\lbrack \gamma_{1,\mathrm{self}} \theta_c^{\varphi_1} + \gamma_{1,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},1} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_1} + \gamma_{1,\mathrm{par}} \bar{h}_p^{\varphi_1} \right\rbrack^{1/\varphi_1} & \text{if } j = 3 \\
\left\lbrack \gamma_{2,\mathrm{self}} \theta_c^{\varphi_2} + \gamma_{2,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},2} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_2} + \gamma_{2,\mathrm{par}} \bar{h}_p^{\varphi_2} \right\rbrack^{1/\varphi_2} & \text{if } j = 4 \\
\theta_c & \text{otherwise}
\end{cases}$$

During working ages ($j < J_r = 10$), adult human capital $h$ evolves via the Ben-Porath law of motion[cite: 3, 6]:

$$h^{\prime} = \left(1 - \delta_{hc}\right) h + \mathbb{I}\left(\ell > 0\right) I_h^{\alpha_I} h^{\alpha_H}$$

### A.3 Dimension-Free 4-Region Housing & Unbalanced Growth ($G_k$)
In `ReturnFn_SpatialHH_UpgradeB.m`, regional rental yields $rr_k$, owner user costs $rh_k$, and the analytical homeownership share $\xi_k$ are computed with zero extra state variables via[cite: 3, 7]:

$$rr_k = \left(1 + \mu_{\mathrm{maint}} - \frac{G_k}{\left(1 + r\right)^{1/5}}\right) Q_k, \qquad rh_k = \left(1 + \mu_{\mathrm{maint}} - \upsilon_h - \frac{G_k}{\left(1 + r\right)^{1/5}}\right) Q_k, \qquad \xi_k = \min\left\lbrace 1, \frac{1}{\bar{\chi}}\left(\frac{rr_k}{rh_k}\right) \right\rbrace$$