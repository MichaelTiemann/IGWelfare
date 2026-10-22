# DOCUMENT 1B: Intergenerational Welfare — Strategy and Policy Answer Key
**Exact Cross-Reference Guide Linking Strategic Claims in Document 1A to VFI Toolkit Variables, Structural Equations, 6-Gate Fiscal Ledgers, and CSV/PNG Outputs (4-Region + Abroad Edition)**[cite: 7, 11]

---

## 1. Purpose & Scope of This Answer Key
This document is the quantitative companion ("Answer Key") to **Document 1A (*Intergenerational Welfare, Capital Allocation, and Human Potential in New Zealand — Executive Reader's Edition*)**[cite: 7, 12]. Every strategic claim, welfare percentage, fertility shift, migration flow, and fiscal ledger figure in Document 1A is mapped below to its exact **MATLAB script**, **VFI Toolkit parameter/grid index**, **structural equation**, and **output CSV/PNG file** in [`Output_NZ_4Region_Intergen`](https://github.com/MichaelTiemann/IGWelfare/tree/main/Output_NZ_4Region_Intergen)[cite: 7, 11].

---

## 2. Audience-by-Audience Claim-to-Code Cross-Reference

### A. Philanthropist Section Cross-Reference (`Lens 1: HumanCapital_Lifecycle_aprimeFn.m`, `Plot_ChildFates_2Panel_SSankey.m`, & `PolicyExperiment_LeeSeshadri_4Region.m`)[cite: 7, 8, 9]
* **4-Region Household Population Shares (Stats NZ June 2025 Base):**
  * *Document 1A Claim:* Rural (16.0%), Small provincial towns (24.0%), Large regional cities (25.9%), Auckland (34.1%)[cite: 7].
  * *Code & CSV Mapping:* Initialized in `NZ_4Region_Master.m` via `Params.PTypeWeights(1:4)` normalized to `[0.160, 0.240, 0.259, 0.341]`; tracked dynamically over the 60-year transition path ($t = 1, \dots, T_{\mathrm{trans}}$) in [`Table9_4Region_Dynamic_Population_Shares.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv)[cite: 7, 8].
* **Intergenerational Borrowing Constraint & Private Corner Solution ($i_c = 0$):**
  * *Document 1A Claim:* Cash-poor and rent-squeezed parents in metropolitan centers hit a mathematical wall where discretionary private early childhood enrichment collapses to zero, leaving only baseline food and shelter sustenance[cite: 7, 8].
  * *Code & Math Mapping:* In `ReturnFn_SpatialHH.m`, parents during active child-rearing windows $j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}$ cannot borrow against the child's future adult human capital $h^{\prime}_1$ ($a^{\prime} \ge 0$ on `a_grid_assets`)[cite: 7, 8]. When regional house prices $Q_k$ (`Params.Q_reg`: Rural = 1.05, Small = 1.40, Large = 2.05, Auckland = 3.10) inflate user costs $rr_k, rh_k$ or mandatory transport subsistence $\bar{e}_k$ (`Params.ebar_energy`: Rural = 0.048, Small = 0.036, Large = 0.022, Auckland = 0.016) binds, optimal private enrichment investment $d_3 = i_c \in \lbrack 0, 0.50\rbrack$ hits `d_grid_ic(1) = 0` alongside asset/income hardship (25.79% of the national cohort in Baseline `SS0`, falling to 5.67% in Reform `SS1`, Gate 2 Node 4 of `Plot_ChildFiscal_2Panel_SSankey.m` and [`Table14_FiscalLedger_6Gate_Decomp_National.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table14_FiscalLedger_6Gate_Decomp_National.csv))[cite: 8, 11].
* **Gate 1 — Two-Stage CES Skill Technology ($\theta_c$ Experience Asset, Ages 0–5 vs. 6–17):**
  * *Document 1A Claim:* First 2000 Days (ages 0–5) exhibit high substitutability, while primary/secondary schooling (ages 6–17) exhibits strong dynamic complementarity, yielding a NZD 112B–162B present-value societal payoff[cite: 7, 9, 10].
  * *Code & Math Mapping:* Implemented in `ChildCES_aprimeFn.m` and `HumanCapital_Lifecycle_aprimeFn.m` with `vfoptions.experienceasset = 1` over the 9-point grid `a_grid_thetac`[cite: 7, 8, 9]:
    * **Stage 1 (First 2000 Days, $j \in \mathcal{J}_{c,1}$, child ages 0–5):** `Params.phi1_ces` gives $\varphi_1 = 0.35 > 0$ (elasticity of substitution $\sigma_1 = \frac{1}{1 - \varphi_1} = 1.54 > 1$), `gamma1_self = 0.53`, `gamma1_inv = 0.24`, `gamma1_par = 0.23`, public wraparound lever `Params.G_ece_stage1 = 0.045` (scaling to 0.190 in reform), and Stone-Geary luxury floor `Params.gbar_ece = 0.020`[cite: 7, 8, 9, 10].
    * **Stage 2 (School Years, $j \in \mathcal{J}_{c,2}$, child ages 6–17):** `Params.phi2_ces` gives $\varphi_2 = -0.95 < 0$ (elasticity of substitution $\sigma_2 = \frac{1}{1 - \varphi_2} = 0.51 < 1$), `gamma2_self = 0.87`, `gamma2_inv = 0.07`, `gamma2_par = 0.06`, public lever `Params.G_ece_stage2 = 0.065`[cite: 7, 9, 10, 15].
* **Gate 2 — The Early-Adolescent Vulnerability Window (Ages 12–14, $J = 5$) & Two-Way Montessori / Tuakana Peer Mentoring:**
  * *Document 1A Claim:* Parental unemployment and housing distress at ages 12–14 trigger skill erosion and acute exits, whereas Two-Way Montessori / Tuakana Cross-Age Peer Mentoring buffers vulnerable mentees and boosts high-performing mentors[cite: 8, 9, 11].
  * *Code & Math Mapping:* In `Plot_ChildFates_2Panel_SSankey.m` and `Plot_ChildFiscal_2Panel_SSankey.m` (Column 3, $J = 5$), family unemployment stress is identified on the solved Markov state space via `is_unemp_4D = (z_idx_3D == 1) | (n_z1 >= 5 & (z_idx_3D == 2) & is_hard_4D)`[cite: 8, 11]:
    * **Node 8 (`8. Unemp Stress + Exits 1,2,4` in Fiscal / Node 6 in Fates):** Unbuffered parental job loss imposes a skill-erosion penalty $\Delta \ln\left(h_{\mathrm{mean}}\right) = -0.22$ (18.92% of cohort costing NZD 7.45k/yr cohort-weighted or NZD 39.36k/affected child-yr in Baseline `SS0`, cut to 4.88% and NZD 1.92k/yr in Reform `SS1`)[cite: 8, 11].
    * **Node 9 (`9. Public Schooling` in Fiscal / Node 7 in Fates):** Neutral trajectory maintenance $\Delta \ln\left(h_{\mathrm{mean}}\right) = 0.00$ (63.74% of cohort costing NZD 6.46k/yr public in `SS0`; 37.84% and NZD 3.83k/yr in `SS1` as students shift into mentoring)[cite: 8, 11].
    * **Node 10 (`10. Montessori / Tuakana Mentoring` in Fiscal / Node 8 in Fates):** Encompasses public and state-integrated Montessori adolescent units (*Wāora*, *Berhampore*, *Royal Oak*), high-agency state schools (*Ao Tawhiti*, *Hobsonville Point*), Māori-medium *Tuakana–Teina* kura, and structured state-school peer mentoring (*Graeme Dingle Stars / Project K*). Cross-age mentoring banks Stage-1 skill gains with $\Delta \ln\left(h_{\mathrm{mean}}\right) = +0.05$ in Baseline `SS0` (17.34% of cohort, NZD 2.43k/yr public flow) and rises to $\Delta \ln\left(h_{\mathrm{mean}}\right) = +0.11$ in Reform `SS1` (57.27% of cohort, NZD 7.91k/yr public flow), while amplifying effective Stage-1 public wraparound productivity via $G_{\mathrm{ECE,eff}} = 1.15 \times G_{\mathrm{ECE}}$[cite: 8, 9, 11].
    * **Node 11 (`11. Private Adol. Commit: Cash+Time` in Fiscal):** Tracks private parental adolescent sustenance, activities, and mentoring time across the non-hardship complement (81.08% of cohort spending NZD 15.40k/yr cohort-weighted or NZD 19.00k/child-yr in `SS0`, rising to 95.12% of cohort spending NZD 18.83k/yr cohort-weighted or NZD 19.80k/child-yr in `SS1`).

---

### B. Venture & Growth Capital Section Cross-Reference (`Lens 2 & Lens 3: ReturnFn_Firm.m` & `Build_IntergenTransitionMatrix.m`)[cite: 7, 8]
* **4-Region Business Firm Shares & Entrepreneurial Productivity Ceilings:**
  * *Document 1A Claim:* 35.1% of NZ businesses operate in Auckland and 26.9% in Large regional cities, holding the highest productivity scale-up ceilings[cite: 7].
  * *Code Mapping:* `Params.PTypeWeights(5:8)` normalized to `[0.150, 0.230, 0.269, 0.351]` (Stats NZ Feb 2025 Business Demography)[cite: 7]. Infinite-horizon firm productivity grids `z_grid.Firm_k` ($z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$) and annual regional trend growth rates $G_{k,\mathrm{ann}}$ are calibrated as[cite: 7]:
    * `Firm_Rural`: $\lbrack 0.70, 1.15\rbrack$, $G_{\mathrm{Rural,ann}} = 1.007$.
    * `Firm_Small`: $\lbrack 0.75, 1.28\rbrack$, $G_{\mathrm{Small,ann}} = 1.011$.
    * `Firm_Large`: $\lbrack 0.83, 1.50\rbrack$, $G_{\mathrm{Large,ann}} = 1.018$.
    * `Firm_Auckland`: $\lbrack 0.90, 1.75\rbrack$, $G_{\mathrm{Auckland,ann}} = 1.025$.
* **Guvenen et al. (2023) Tax Shift & Wage / House Price Multipliers:**
  * *Document 1A Claim:* Shifting from capital income tax $\tau_k$ to a book-value wealth/land tax ($\tau_a = 1.5\%$) and estate levy ($\tau_b = 25\%$) on the NZD 1.6T property transfer lifts regional wages by +3.2% to +5.5% and cools urban house overvaluation by -5.0% to -7.5%[cite: 7, 8].
  * *Code Mapping:* In `WelfareDecomposition_4Region.m`, `Params_Reform.tau_a = 0.015`, `Params_Reform.tau_b = 0.25`, `Params_Reform.YouthGrant = 0.065` (up from baseline 0.030), with general equilibrium multipliers `w_mult_GE = [1.032, 1.038, 1.048, 1.055]` and `Q_mult_GE = [0.990, 0.975, 0.950, 0.925]` across `{Rural, Small, Large, Auckland}`[cite: 7, 8].

---

### C. Policy-Maker Section Cross-Reference (`FertilityBargaining_Module.m`, `WelfareDecomposition_4Region.m`, & `Plot_ChildFiscal_2Panel_SSankey.m`)[cite: 7, 8, 18]
* **4-Region "Income x Geography" Transfer Vector (`Params_Reform.Transfer_Geo`):**
  * Baseline regional transfers `[0.025, 0.020, 0.016, 0.014]` scale under the High-Opportunity Reform to `Params_Reform.Transfer_Geo = [0.038, 0.031, 0.025, 0.028]` across `{HH_Rural, HH_Small, HH_Large, HH_Auckland}` to offset Rural/Small mandatory transport subsistence $\bar{e}_k$ and Large/Auckland rental stress[cite: 7, 8, 15].
* **6-Gate Intergenerational Fiscal Ledger (`FiscalLedger.National.SS0`, `FiscalLedger.National.SS1`) & The 2050 Debt-Targeting Protocol:**
  * Computed post-hoc in `Plot_ChildFiscal_2Panel_SSankey.m` with `NZD_Base_Scale = 95.0` (1.0 model unit = NZD 95.0k/yr mean prime household earnings) and Oranga Tamariki acute state care anchored at approximately NZD 180k/care-yr (`@NZD 32k/stunted` annualized cohort burden across Exits 1, 2, and 4)[cite: 8, 14].
  * Summarized in `FiscalLedger.Protocol_2050_Summary` and exported to [`Table14_FiscalLedger_6Gate_Decomp_National.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table14_FiscalLedger_6Gate_Decomp_National.csv) (Section 3 below), partitioning 100% of the net reform fiscal surplus $\Omega_{\mathrm{reform}} = \max\left(0, \Omega_{\mathrm{fiscal}}^{\mathrm{SS1}} - \Omega_{\mathrm{fiscal}}^{\mathrm{SS0}}\right)$ 50/50 into `SinkingFund_50Pct_kNZD` and `ReinvestmentPool_50Pct_kNZD`[cite: 8].

---

## 3. Complete Empirical CSV & Fiscal Ledger Audit Tables

### Table 14: 6-Gate (26-Node) Lifecycle Fiscal & 4-Lane Child-Cost Reconciliation (`Table14_FiscalLedger_6Gate_Decomp_National.csv`)
*Source Script & Figure: `Plot_ChildFiscal_2Panel_SSankey.m` / [`Fig_ChildFiscal_5Stage_2Panel_National_Dunedin_22.png`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Fig_ChildFiscal_5Stage_2Panel_National_Dunedin_22.png)*[cite: 8, 14]

| Gate & Column ($J$) | Node # & Flow Name | `SS0` Pop (%) | `SS0` Cohort Flow (NZD k/yr) | `SS0` Per-Child Rate (NZD k/yr) | `SS1` Pop (%) | `SS1` Cohort Flow (NZD k/yr) | `SS1` Per-Child Rate (NZD k/yr) | 4-Lane Accounting & Empirical Anchor |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Gate 1 ($J=1$)**<br>*Birth, Age 0* | **1.** Means-Tested Birth Support<br>**2.** Universal Birth Benefit<br>**3.** Private Birth Out-of-Pocket | 25.79%<br>100.00%<br>74.21% | 1.20<br>8.90<br>13.73 | 4.65<br>8.90<br>18.50 | **5.67%**<br>100.00%<br>**94.33%** | 2.02<br>22.11<br>**17.64** | 35.61<br>22.11<br>**18.70** | Lane D: WFF/Accommodation Supp.<br>Lane C: PPL + BestStart Yr1 + LMC<br>Lanes A+B: Infant sustenance + leave |
| **Gate 2 ($J=2..3$)**<br>*First 2000 Days* | **4.** ECE Corner + Benefit Need<br>**5.** Public ECE Wraparound<br>**6.** High-Intensity Public ECE<br>**7.** Private Parental ECE (Cash+Time) | 25.79%<br>70.07%<br>4.14%<br>74.21% | 3.49<br>6.01<br>0.60<br>13.73 | 13.52<br>8.58<br>14.49<br>**18.50** | **5.67%**<br>**90.18%**<br>4.14%<br>**94.33%** | **0.77**<br>**22.10**<br>1.26<br>**17.64** | 13.52<br>24.51<br>30.43<br>**18.70** | Lane D: Hardship corner ($i_c = 0$)<br>Lane C: *Te Korowai Mokopuna* $G_{\mathrm{ECE},1}$<br>Lane C: High-intensity public ECE<br>Lanes A+B: Matches NZD 15k–19k survey! |
| **Gate 3 ($J=5$)**<br>*Adol. Ages 12–14* | **8.** Unemp Stress + Exits 1,2,4<br>**9.** Public Schooling ($d_2$)<br>**10.** Montessori / Tuakana Mentoring<br>**11.** Private Adol. Commit (Cash+Time) | 18.92%<br>63.74%<br>17.34%<br>81.08% | 7.45<br>6.46<br>2.43<br>15.40 | 39.36<br>10.14<br>13.99<br>**19.00** | **4.88%**<br>37.84%<br>**57.27%**<br>**95.12%** | **1.92**<br>3.83<br>**7.91**<br>**18.83** | 39.36<br>10.11<br>13.81<br>**19.80** | Lane D: Parental job loss + Exits 1,2,4<br>Lane C: Secondary schooling $d_2$<br>Lane C: Cross-age peer mentoring<br>Lanes A+B: Sustenance + mentoring time |
| **Gate 4 ($J=6..7$)**<br>*Adult Launch, 20* | **12.** Stunted Tier $h_1\text{--}h_2$ [Exits 1,2,4]<br>**13.** Core Skill Tier $h_3\text{--}h_5$<br>**14.** Thriving Tier $h_6\text{--}h_7$ | 74.69%<br>22.84%<br>2.47% | 17.94<br>5.29<br>0.60 | 24.02<br>23.14<br>24.43 | **3.99%**<br>**80.64%**<br>**15.37%** | **1.69**<br>**33.38**<br>**6.69** | 42.35<br>41.40<br>43.55 | Dunedin Study high-need trajectory<br>Vocational/secondary skill launch<br>Tertiary/high-skill launch + Grant $E$ |
| **Gate 5 ($J=10$)**<br>*Age 30 Ledger* | **15.** Exits 1,2,4: Care/Hosp/Just<br>**16.** Infra, Roads & Base Health<br>**17.** Age 30 GST & Cap Tax<br>**18.** Age 30 PAYE Income Tax<br>**19.** Exit 3: Stunting Lost Tax<br>**20.** Age 30 Emig Tax Loss | 100.0%<br>100.0%<br>100.0%<br>100.0%<br>100.0%<br>100.0% | 16.82<br>4.08<br>5.12<br>5.74<br>*(3.15)*<br>*(0.71)* | 16.82<br>4.08<br>5.12<br>5.74<br>*(3.15)*<br>*(0.71)* | 100.0%<br>100.0%<br>100.0%<br>100.0%<br>100.0%<br>100.0% | **3.28**<br>4.10<br>**9.28**<br>**8.45**<br>*(0.73)*<br>*(1.04)* | **3.28**<br>4.10<br>**9.28**<br>**8.45**<br>*(0.73)*<br>*(1.04)* | Acute remediation (`@NZD 32k/stunted`)<br>Universal per-adult public overhead<br>$\tau_c c_{nd} + \tau_k r a + \tau_a a$<br>$\tau_l w_k z h \ell$<br>28.8% foregone tax from Exit 3<br>Foregone tax from 20–35 brain drain |
| **Gate 6 ($J=11..16$)**<br>*Career to Ret.* | **21.** Exits 1,2,4: Ongoing Burden<br>**22.** NZ Super, Infra & Health<br>**23.** GST, Cap & Estate Tax Pool<br>**24.** Career PAYE Income Tax<br>**25.** Exit 3: Career Lost Tax<br>**26.** Perm. Abroad Tax Loss | 100.0%<br>100.0%<br>100.0%<br>100.0%<br>100.0%<br>100.0% | 12.59<br>7.85<br>6.11<br>3.52<br>*(2.42)*<br>*(0.63)* | 12.59<br>7.85<br>6.11<br>3.52<br>*(2.42)*<br>*(0.63)* | 100.0%<br>100.0%<br>100.0%<br>100.0%<br>100.0%<br>100.0% | **2.49**<br>7.87<br>**12.65**<br>**5.07**<br>*(0.57)*<br>*(1.04)* | **2.49**<br>7.87<br>**12.65**<br>**5.07**<br>*(0.57)*<br>*(1.04)* | Chronic adult justice/welfare/hospital<br>Universal $P_{\mathrm{super}}$ + old-age health<br>$\tau_c + \tau_k + \tau_a + \tau_b(1-s_j)a^{\prime}$<br>Annuitized career PAYE stream<br>Foregone career tax from Exit 3<br>Permanent Abroad tax loss |

---

### Table 2: The 2050 Sovereign Debt-Sinking Fund & Public Reinvestment Protocol (`FiscalLedger.Protocol_2050_Summary`)
*Source Script: Section 3.2 of `Plot_ChildFiscal_2Panel_SSankey.m` (National Cohort-Weighted NZD k/yr per Birth)*[cite: 8]

| Lifecycle Ledger Stage | `Baseline_SS0_kNZD` ($\Omega_{\mathrm{fiscal}}^{\mathrm{SS0}}$) | `Reform_SS1_kNZD` ($\Omega_{\mathrm{fiscal}}^{\mathrm{SS1}}$) | `Reform_Gain_Omega_kNZD` ($\Omega_{\mathrm{reform}}$) | `DebtSinking_50Pct_kNZD` (50% of Surplus to 2050 Debt) | `ReinvestPool_50Pct_kNZD` (50% of Surplus to Infra/NZSF) | `DebtInterestSaved_2050_kNZD` ($r_{\mathrm{gov}} = 4.2\%$) | `Infra_NZSF_YieldDiv_2050_kNZD` ($\mu_{\mathrm{infra}} = 1.65\times$) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`Gate5_Age30_J10`** (Age 30) | -10.04 | +10.35 | **+20.39** | +5.18 | +5.18 | +0.22 | +8.54 |
| **`Gate6_CareerToRet_J11_16`** | -10.81 | +7.36 | **+18.17** | +3.68 | +3.68 | +0.15 | +6.07 |

---

### Table 12A: Intergenerational Elasticity of Earnings (`IGE`) — Short-Run PE (`SR`) vs. Long-Run GE (`LR`)
*Source File: [`Table12A_LeeSeshadri_4Region_IGE.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12A_LeeSeshadri_4Region_IGE.csv) (with 3-year time grid sensitivity in [`Table4_4Region_LeeSeshadri_IGE.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table4_4Region_LeeSeshadri_IGE.csv))*[cite: 7]

| `Row` (Policy Regime) | `Rural_SR` | `Small_SR` | `Large_SR` | `Auckland_SR` | `Rural_LR` | `Small_LR` | `Large_LR` | `Auckland_LR` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline`** | 0.2535 | 0.2383 | 0.3488 | 0.4448 | 0.2535 | 0.2383 | 0.3488 | 0.4448 |
| **`P0_Early_0to5`** | 0.2535 | 0.2391 | 0.3274 | 0.4387 | 0.2653 | 0.2388 | 0.3655 | **0.4218** |
| **`P1P2_Late_6to17`** | 0.2764 | 0.2626 | 0.3466 | 0.4335 | 0.2882 | 0.2660 | 0.3555 | 0.4215 |
| **`BN_FrontLoad`** | **0.2345** | **0.2202** | 0.3522 | 0.4475 | **0.2347** | **0.2193** | 0.3635 | 0.4477 |
| **`P0_Plus_GrantE`** | 0.2558 | 0.2412 | **0.3279** | **0.4377** | 0.2571 | **0.2359** | 0.3620 | **0.4264** |

---

### Table 12B: Variance of Adult Human Capital ($h_1$) & Lifetime Earnings (`LFE`) Explained by Parental State at Age 30–35, Plus Log Earnings Variance (`VarLogE`)
*Source File: [`Table12B_LeeSeshadri_4Region_VarExpl.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12B_LeeSeshadri_4Region_VarExpl.csv)*[cite: 7, 20, 21]

| `Row` (Policy Regime) | `VarExpl_h1_Rural` (%) | `VarExpl_h1_Small` (%) | `VarExpl_h1_Large` (%) | `VarExpl_h1_Auckland` (%) | `VarExpl_LFE_Rural` (%) | `VarExpl_LFE_Small` (%) | `VarExpl_LFE_Large` (%) | `VarExpl_LFE_Auckland` (%) | `VarLogE_Rural` | `VarLogE_Small` | `VarLogE_Large` | `VarLogE_Auckland` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline`** | 42.84% | 41.01% | 42.67% | 46.77% | 70.06% | 69.29% | 69.99% | 71.74% | 0.6635 | 0.4695 | 0.4040 | 0.5460 |
| **`P0_Early_0to5`** | **40.06%** | **38.75%** | **39.78%** | **45.77%** | **68.90%** | **68.36%** | **68.78%** | **71.31%** | 0.6624 | 0.4607 | 0.4013 | 0.5451 |
| **`P1P2_Late_6to17`** | 41.63% | 39.73% | 41.59% | 44.64% | 69.55% | 68.76% | 69.54% | 70.82% | 0.6654 | 0.4670 | 0.4040 | 0.5444 |
| **`BN_FrontLoad`** | 42.40% | 40.94% | 42.34% | 47.41% | 69.87% | 69.27% | 69.85% | 72.02% | 0.6653 | 0.4687 | 0.4036 | 0.5468 |
| **`P0_Plus_GrantE`** | **39.79%** | **38.15%** | **40.34%** | **45.30%** | **68.79%** | **68.11%** | **69.02%** | **71.11%** | **0.6366** | **0.4138** | **0.3823** | **0.5380** |

---

### Table 12C: Percentage Change in Average Lifetime Earnings (`Ebar` %) & Newborn Consumption Equivalent Welfare (`CE_LR` %)
*Source File: [`Table12C_LeeSeshadri_4Region_Welfare.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12C_LeeSeshadri_4Region_Welfare.csv)*[cite: 7, 23, 24]

| `Row` (Policy Regime) | `Ebar_SR_Rural` (%) | `Ebar_SR_Small` (%) | `Ebar_SR_Large` (%) | `Ebar_SR_Auckland` (%) | `Ebar_LR_Rural` (%) | `Ebar_LR_Small` (%) | `Ebar_LR_Large` (%) | `Ebar_LR_Auckland` (%) | `CE_LR_Rural` (%) | `CE_LR_Small` (%) | `CE_LR_Large` (%) | `CE_LR_Auckland` (%) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline`** | 0.00% | 0.00% | 0.00% | 0.00% | 0.00% | 0.00% | 0.00% | 0.00% | 0.00% | 0.00% | 0.00% | 0.00% |
| **`P0_Early_0to5`** | -0.11% | +0.04% | -0.00% | +0.12% | **+1.81%** | **+2.34%** | **+1.63%** | **+1.10%** | **+0.63%** | **+0.64%** | **+0.89%** | **+0.68%** |
| **`P1P2_Late_6to17`** | -0.09% | +0.05% | +0.12% | +0.15% | +0.81% | +1.21% | +1.17% | +0.96% | +0.28% | +0.08% | +0.14% | +0.24% |
| **`BN_FrontLoad`** | -0.02% | -0.00% | -0.04% | -0.02% | -0.01% | +0.26% | +0.08% | -0.01% | +0.09% | +0.19% | +0.21% | +0.11% |
| **`P0_Plus_GrantE`** | +3.29% | +3.57% | +3.51% | +3.77% | **+7.08%** | **+7.54%** | **+5.48%** | **+5.08%** | **+1.67%** | **+3.23%** | **+5.92%** | **+6.52%** |

---

### Table Fert1 & Table Fert2: Fertility, Stunted Cohort Share, 65+ Aged Dependency Ratio, and Required Labor Tax Rate ($\tau_l$)
*Source Files: [`Table_Fert1_4Region_TFR_DiffFertility.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table_Fert1_4Region_TFR_DiffFertility.csv) & [`Table_Fert2_4Region_Stunting_NZSuper.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table_Fert2_4Region_Stunting_NZSuper.csv)*[cite: 7, 18, 19]

| `Row` (Fertility Scenario) | `Stunted_Pct_Rural` | `Stunted_Pct_Small` | `Stunted_Pct_Large` | `Stunted_Pct_Auckland` | `DepRatio_65Plus_Pct` | `Required_LaborTax_Pct` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1_Baseline_StatusQuo`** | 19.80% | 18.20% | 15.60% | 14.30% | 30.45% | 26.20% |
| **`2_Hyperbolic_NoCommit` ($\beta_{\mathrm{hyp}} = 0.72$)** | 21.35% | 19.93% | 17.51% | 16.39% | **39.62%** | **28.22%** |
| **`3_Barnardos_ECE_Bargaining_Relief`** | 13.89% | 11.59% | 8.30% | 6.30% | **29.58%** | **25.45%** |
| **`4_Full_Package` (ECE1 + Housing Cool + Commit)** | **13.45%** | **11.10%** | **7.75%** | **5.70%** | **27.45%** | **24.90%** |

---

## 4. Visual Output Manifest & Core Structural Equations

### 4.1 Embedded Repository Graphics (`Output_NZ_4Region_Intergen`)
* **Figure 1 (`Fig1_Daruich_Cohort_Welfare_4Region.png`):** Cohort-by-cohort lifetime Consumption Equivalent welfare trajectory across the 60-year transition path in Rural, Small, Large, and Auckland, isolating Jump 1 ($c = 0$) and Jump 2 ($c = 3\text{--}4$, Year-20 intergenerational multiplier)[cite: 7, 15].
* **Figure 2 (`Fig2_Kiyotaki_Housing_Estates_4Region.png`):** Dynamic impulse responses of regional house prices $Q_{k,t}$, rental yields $rr_{k,t}$, and tenure-disaggregated consumption (Young Renters vs. Leveraged Young Owners vs. Older Retirees) across the NZD 1.6T estate transfer window[cite: 7, 15].
* **Figure 3 (`Fig3_BrainDrain_Cohesion_4Region.png`):** Three-wave closure of the age 20–35 emigration rate to Australia/OECD, the Social Cohesion Index ($S_t$), and the Effective Tax Base per 65+ Retiree[cite: 7, 15].
* **Figure E8 (`FigE8_LeeSeshadri_4Region_Counterfactuals.png`):** 4-region replication of Lee and Seshadri's stage-investment profiles showing how `P0_Early_0to5` crowds *in* private parental effort during school years ($\varphi_2 = -0.95 < 0$)[cite: 7, 15].
* **Figure Fert (`FigFert_4Region_Bargaining_Solvency.png`):** Childcare bargaining, hyperbolic discounting ($\beta_{\mathrm{hyp}} = 0.72$), and NZ Superannuation fiscal solvency across the 4 regions[cite: 7, 18, 19].
* **2-Panel Population & Fiscal Sankey Diagrams (`Plot_ChildFates_2Panel_SSankey.m` & `Plot_ChildFiscal_2Panel_SSankey.m`):** 5-stage cohort population flows (`Table15`) and 6-gate dollar-weighted fiscal flows (`Table14`, in NZD k/yr) across National, Auckland, Large, Small, Urban, and Rural catchments[cite: 8, 11, 14].

### 4.2 Core Reference Equations for Technical Reviewers
* **Infinite-Horizon Firm Bellman Equation & After-Tax Return (`ReturnFn_Firm.m`):**
  In region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$, firms with productivity $z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$ and collateral limit $k \le \lambda_{\mathrm{col}} a_f$ ($\lambda_{\mathrm{col}} = 1.80$) solve:

$$V_{F,k}\left(a_f, z_f\right) = \max_{a^{\prime}_f \in \lbrack 0, R_k\left(z_f; \Delta t\right) a_f\rbrack} \left\lbrace \ln\left(R_k\left(z_f; \Delta t\right) a_f - a^{\prime}_f\right) + \beta_{\mathrm{firm}}\left(\Delta t\right) \sum_{z^{\prime}_f} \Pi_{f,k}\left(z^{\prime}_f \vert z_f\right) V_{F,k}\left(a^{\prime}_f, z^{\prime}_f\right) \right\rbrace$$

$$R_k\left(z_f; \Delta t\right) = \left(1 - \tau_a\right)^{\Delta t} + \left(1 - \tau_k\right) \left\lbrace r + \max\left(0, \alpha_k \left(\frac{1 - \alpha_k}{w_k}\right)^{\frac{1 - \alpha_k}{\alpha_k}} z_f - \left(r + \delta_k\left(\Delta t\right)\right) \right) \lambda_{\mathrm{col}} \right\rbrace$$

* **Two-Stage Childhood CES Skill Law of Motion (`ChildCES_aprimeFn.m` / `HumanCapital_Lifecycle_aprimeFn.m`):**
  With step weight $\omega_s = 1 / n_s$ across Stage 1 ($\mathcal{J}_{c,1}$, $\varphi_1 = 0.35$) and Stage 2 ($\mathcal{J}_{c,2}$, $\varphi_2 = -0.95$)[cite: 7, 8, 9]:

$$\theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},s}, \varphi_s\right) = \left\lbrack \gamma_{s,\mathrm{self}} \theta_c^{\varphi_s} + \gamma_{s,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},s} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_s} + \gamma_{s,\mathrm{par}} \bar{h}_p^{\varphi_s} \right\rbrack^{1/\varphi_s}$$

$$\theta^{\prime}_c = \begin{cases}
\left(1 - \omega_{s1}\right)\theta_c + \omega_{s1} \theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},1}, \varphi_1\right) & \text{if } j \in \mathcal{J}_{c,1} \\
\left(1 - \omega_{s2}\right)\theta_c + \omega_{s2} \theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},2}, \varphi_2\right) & \text{if } j \in \mathcal{J}_{c,2} \\
\theta_c & \text{otherwise}
\end{cases}$$

$$h^{\prime} = \left(1 - \delta_{hc}\left(\Delta t\right)\right) h + \left(\frac{\Delta t}{5}\right) \mathbb{I}\left(\ell > 0\right) I_h^{\alpha_I} h^{\alpha_H}$$

* **Macro Public Residual ($\Omega_{\mathrm{fiscal}}$) & The 2050 50/50 Dynamic Surplus Split (`Plot_ChildFiscal_2Panel_SSankey.m`):**
  At Gate 5 ($J = 10$, Age 30) and Gate 6 ($J = 11..16$, Career to Retirement), the net cohort fiscal balance $\Omega_{\mathrm{fiscal}}$ and positive fiscal surplus allocation are defined as[cite: 8]:

$$\Omega_{\mathrm{fiscal}} = \left(\mathrm{Tax}_{\mathrm{PAYE}} + \mathrm{Tax}_{\mathrm{GST}} + \mathrm{Tax}_{\mathrm{Cap}} + \mathrm{Tax}_{\mathrm{Estate}}\right) - \left(\mathrm{Cost}_{\mathrm{Exits\,1,2,4}} + \mathrm{Cost}_{\mathrm{Infra,Health,Super}}\right)$$

$$\Omega_{\mathrm{surplus}}^{\mathrm{SS1}} = \max\left(0, \Omega_{\mathrm{fiscal}}^{\mathrm{SS1}}\right) = 0.50 \, \Omega_{\mathrm{surplus}}^{\mathrm{SS1}} \;\left(\mathrm{DebtSinking}\right) + 0.50 \, \Omega_{\mathrm{surplus}}^{\mathrm{SS1}} \;\left(\mathrm{ReinvestPool}\right)$$

## 5. Actuarial Continuation Valuation & Cumulative Transition Payoffs Answer Key (`Plot_CumulativeTransitionPayoffs.m` & `Plot_ActuarialContinuationValuation.m`)

### 5.1 Cross-Reference of Terminology, NZ Treasury CBAx Rules, and Sibling Figure Naming Convention
* **Three Equivalent Institutional Names for the Forward Discounting Operator:**
  1. *Public Finance & NZ Treasury CBAx:* **Incidence-Based Lifetime Valuation** (or *Present Value of Future Incidence*), which books the discounted lifetime cost avoidance in the year a cohort verifiably exits hardship rather than waiting for annual cash flows to fall due over 40 years.
  2. *Crown Balance Sheet Accounting (ACC / Social Investment Agency):* **Actuarial Liability Release** (or *Forward Liability Valuation*), directly analogous to the Accident Compensation Corporation (ACC) Outstanding Claims Liability (NZD 63.6B on the Crown balance sheet).
  3. *Dynamic Programming / OLG Markov Transition Suite:* **Conditional Continuation Valuation** $\mathcal{V}_{k,t_0}^{\left(L\right)}\left(H\right)$, evaluated on the solved sequence of transition distributions `StationaryDist_t` ($\mu_{k,t}\left(a, h, z, j\right)$) and firm equity distributions $\Gamma_{k,t}\left(a_f, z_f\right)$.
* **Canonical Sibling Figure Naming Convention (`Output_NZ_4Region_Intergen/`):**
  * **Combined 2-Panel Figure (Panel A Fiscal + Panel B Economy-Wide GDP):** `Fig_Actuarial_2Panel_<Region>_<Anchor>.png` (e.g., `Fig_Actuarial_2Panel_National_Dunedin_22.png`, `Fig_Actuarial_2Panel_Auckland_Dunedin_22.png`).
  * **Panel A Sibling (Crown Fiscal Ledger):** `Fig_Actuarial_Fiscal_<Region>_<Anchor>.png` (e.g., `Fig_Actuarial_Fiscal_National_Dunedin_22.png`, `Fig_Actuarial_Fiscal_Auckland_Dunedin_22.png`).
  * **Panel B Sibling (Economy-Wide GDP Lens):** `Fig_Actuarial_WideGDP_<Region>_<Anchor>.png` (e.g., `Fig_Actuarial_WideGDP_National_Dunedin_22.png`, `Fig_Actuarial_WideGDP_Auckland_Dunedin_22.png`).
  * **All-4-Region Spatial Dashboard & Year 5 Audit Bar Chart:** `Fig_Actuarial_Dashboard_All4_<Anchor>.png` and `Fig_Actuarial_Year5Audit_All4_<Anchor>.png`.
* **Strict Lens Separation & NZ Treasury Acceptance Boundary (Counting Rule #1):**
  * *Accepted & Mandated by NZ Treasury:* Evaluating long-tail social investments over a rolling forward window ($H = 25$ years) using the **NZ Treasury Circular 2024/15** non-commercial social discount rate of **2.0% real** (`r_2pct = 0.020`) printed side-by-side with the mandatory **8.0% real** commercial sensitivity rate (`r_8pct = 0.080`), net of a conservative **30% attribution haircut** (`alpha_att = 0.30`, within the 20%–40% Barnardos/Danalytics macro attribution band) and real cost-base growth `g_cost = 0.015`.
  * *Rejected if Violated (How Our Code Enforces Compliance):* NZ Treasury rejects blending fiscal cost avoidance (avoided benefit transfers and acute Oranga Tamariki/Corrections/hospital outlays) with GDP gains, and rejects booking unappropriated 25-year savings into the 4-year cash Operating Balance (OBEGAL). Consequently, `Plot_ActuarialContinuationValuation.m` computes two strictly separate continuation operators—$\mathcal{V}_{k,t_0}^{\left(\mathrm{Fiscal}\right)}\left(H\right)$ in `Fig_Actuarial_Fiscal_<Region>_<Anchor>.png` and $\mathcal{V}_{k,t_0}^{\left(\mathrm{Econ}\right)}\left(H\right)$ in `Fig_Actuarial_WideGDP_<Region>_<Anchor>.png`—and never adds avoided fiscal costs to GDP.

### 5.2 Exact Conditional Continuation Equations Justifying the Findings
At transition period $t_0$ (in years, $t_0 \in \lbrace 5, 10, \dots, 60 \rbrace$), let $\mathcal{C}_{k,\mathrm{realized}}^{\left(L\right)}\left(t_0\right)$ denote the cumulative realized cash flow integrated via the trapezoidal rule (`cumtrapz`) from Year 0 to Year $t_0$ under lens $L \in \lbrace \mathrm{Sav}, \mathrm{Fiscal}, \mathrm{Econ} \rbrace$. Annual flows are interpolated onto a 1-year grid ($y \in \lbrace 0, 1, \dots, 100 \rbrace$) via piecewise cubic Hermite interpolation (`pchip`). The **Actuarial Continuation Valuation** $\mathcal{V}_{k,t_0}^{\left(L\right)}\left(H\right)$ over a rolling $H = 25$-year recognition window for region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$ is:

$$\mathcal{V}_{k, t_0}^{\left(L\right)}\left(H; r_{\mathrm{disc}}\right) = \mathcal{C}_{k, \mathrm{realized}}^{\left(L\right)}\left(t_0\right) + \left(1 - \alpha_{\mathrm{attr}}\right) \Phi_{\mathrm{pipe}}\left(t_0\right) \sum_{s=1}^{H} \left(\frac{1 + g_{\mathrm{cost}}}{1 + r_{\mathrm{disc}}}\right)^{s} \psi_{k,\mathrm{persist}}^{s} \cdot \mathbb{E}_{t_0}\left\lbrack \Delta \mathrm{Flow}_{k, t_0 + s}^{\left(L\right)} \;\middle|\; \mu_{k, t_0} \right\rbrack$$

and the national aggregate is obtained by exact spatial summation across the four regional ledgers:

$$\mathcal{V}_{\mathrm{National}, t_0}^{\left(L\right)}\left(H; r_{\mathrm{disc}}\right) = \sum_{k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace} \mathcal{V}_{k, t_0}^{\left(L\right)}\left(H; r_{\mathrm{disc}}\right)$$

where:
* $\Phi_{\mathrm{pipe}}\left(t_0\right) = \min\left(1.0, \frac{t_0}{15.0}\right)$ (`pipeline_maturity`) measures the fraction of the 0–15 childhood age pipeline that has completed or entered active treatment by year $t_0$ (reaching 1.0 at Year 15 when all childhood brackets are active).
* $\psi_{k,\mathrm{persist}}^{s}$ (`psi_persist`) is the region-specific Stage-2-to-Adulthood Markov skill-retention conditioning factor (`psi_base_map`: Rural = 0.984, Small = 0.984, Large = 0.986, Auckland = 0.987), reflecting the probability under $\Pi_h\left(h^{\prime} \vert h, i_{c,2}\right)$ and dynamic complementarity ($\varphi_2 = -0.95$) that a child exiting hardship at age 5 remains out of the stunted tier $h_1\text{--}h_2$ at age $5 + s$.

### 5.3 Year 5 Parliamentary Audit ($t = 1$) & Year 60 Convergence by Region (`Dunedin_22` vs. `MetroSqueeze_GUiNZ`)
*Source Script: `Plot_ActuarialContinuationValuation.m` (`Out_Dunedin` console verification table; figures saved as `Fig_Actuarial_2Panel_<Region>_Dunedin_22.png`, `Fig_Actuarial_Fiscal_<Region>_Dunedin_22.png`, and `Fig_Actuarial_WideGDP_<Region>_Dunedin_22.png`)*

| Region (`RegionOption`) | Base Pop / Firm Share (`PTypeWeights`) | Yr 5 Cum. Outlay (`Cum_Inv`) | Yr 5 Cash Fiscal (`Cum_TotFisc`) | Yr 5 Booked Cost Avoidance Alone (2.0% Real) | Yr 5 Booked Total Fiscal Return (2.0% / 8.0%) | Yr 5 Realized Cash GDP (`Cum_dGDP`) | Yr 5 Booked 25-Yr GDP Prize (2.0% / 8.0%) | Yr 60 Realized / Booked GDP Prize (2.0% Real) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`Rural`** | 16.0% / 15.0% | NZD 1.42B | NZD 0.65B | **NZD 1.48B** | **NZD 4.61B** / NZD 2.39B | NZD 1.99B | **NZD 10.87B** / NZD 6.13B | NZD 196.4B / **NZD 270.3B** |
| **`Small`** | 24.0% / 23.0% | NZD 2.16B | NZD 1.04B | **NZD 2.33B** | **NZD 7.32B** / NZD 3.79B | NZD 3.17B | **NZD 17.31B** / NZD 9.76B | NZD 312.7B / **NZD 430.3B** |
| **`Large`** | 25.9% / 26.9% | NZD 2.38B | NZD 1.33B | **NZD 2.79B** | **NZD 9.43B** / NZD 4.88B | NZD 4.12B | **NZD 23.05B** / NZD 12.96B | NZD 406.4B / **NZD 568.7B** |
| **`Auckland`** | 34.1% / 35.1% | NZD 3.24B | NZD 1.95B | **NZD 4.06B** | **NZD 13.90B** / NZD 7.18B | **NZD 6.03B** | **NZD 34.17B** / **NZD 19.20B** | **NZD 595.2B** / **NZD 826.5B** |
| **`National` (`Dunedin_22`)** | **100.0%** | **NZD 9.19B** | **NZD 4.98B** | **NZD 10.66B** | **NZD 35.25B / NZD 18.25B** | **NZD 15.30B** | **NZD 85.40B / NZD 48.05B** | **NZD 1,510.7B / NZD 2,095.8B** |
| **`National` (`MetroSqueeze_GUiNZ`)** | **100.0%** | **NZD 9.19B** | **NZD 5.14B** | **NZD 13.69B** | **NZD 39.14B / NZD 20.21B** | **NZD 15.30B** | **NZD 89.95B / NZD 50.18B** | **NZD 1,634.5B / NZD 2,270.3B** |
