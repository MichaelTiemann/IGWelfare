# DOCUMENT 1B: Intergenerational Welfare — Strategy and Policy Answer Key
**Exact Cross-Reference Guide Linking Strategic Claims in Document 1A to VFI Toolkit Variables, Structural Equations, 6-Gate Fiscal Ledgers, and CSV/PNG Outputs (4-Region + Abroad Edition)**[cite: 2, 5, 15]

---

## 1. Purpose & Scope of This Answer Key
This document is the quantitative companion ("Answer Key") to **Document 1A (*Intergenerational Welfare, Capital Allocation, and Human Potential in New Zealand — Executive Reader's Edition*)**[cite: 2, 20]. Every strategic claim, welfare percentage, fertility shift, migration flow, and fiscal ledger figure in Document 1A is mapped below to its exact **MATLAB script**, **VFI Toolkit parameter/grid index**, **structural equation**, and **output CSV/PNG file** in [`Output_NZ_4Region_Intergen`](https://github.com/MichaelTiemann/IGWelfare/tree/main/Output_NZ_4Region_Intergen)[cite: 2, 5, 15].

---

## 2. Audience-by-Audience Claim-to-Code Cross-Reference

### A. Philanthropist Section Cross-Reference (`Lens 1: ChildCES_aprimeFn.m`, `Plot_ChildFates_2Panel_SSankey.m`, & `PolicyExperiment_LeeSeshadri_4Region.m`)[cite: 2, 15]
* **4-Region Household Population Shares (Stats NZ June 2025 Base):**
  * *Document 1A Claim:* Rural ($16.0\%$), Small provincial towns ($24.0\%$), Large regional cities ($25.9\%$), Auckland ($34.1\%$)[cite: 2, 15].
  * *Code & CSV Mapping:* Initialized in `NZ_4Region_Master_UpgradeB.m` via `Params.PTypeWeights(1:4)` normalized to `[0.160, 0.240, 0.259, 0.341]`; tracked dynamically over the 60-year transition path ($t = 1, \dots, T_{\mathrm{trans}}$) in [`Table9_4Region_Dynamic_Population_Shares.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table9_4Region_Dynamic_Population_Shares.csv)[cite: 2, 3].
* **Intergenerational Borrowing Constraint & Private Corner Solution ($i_c = 0$):**
  * *Document 1A Claim:* Cash-poor and rent-squeezed parents in metropolitan centers hit a mathematical wall where private early childhood enrichment collapses to zero[cite: 2, 20].
  * *Code & Math Mapping:* In `ReturnFn_SpatialHH_UpgradeB.m`, parents during active child-rearing windows $j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}$ cannot borrow against the child's future adult human capital $h^{\prime}_1$ ($a^{\prime} \ge 0$ on `a_grid_assets`)[cite: 2]. When regional house prices $Q_k$ (`Params.Q_reg`: Rural $= 1.05$, Small $= 1.40$, Large $= 2.05$, Auckland $= 3.10$) inflate user costs $rr_k, rh_k$ or mandatory transport subsistence $\bar{e}_k$ (`Params.ebar_energy`: Rural $= 0.048$, Small $= 0.036$, Large $= 0.022$, Auckland $= 0.016$) binds, optimal private investment $d_1 = i_c \in \lbrack 0, 0.50\rbrack$ hits `d_grid_ic(1) = 0` ($58.8\%$ of the national cohort in Baseline $\mathrm{SS}_0$, falling to $12.9\%$ in Reform $\mathrm{SS}_1$, Gate 2 Node 4 of `Plot_ChildFiscal_2Panel_SSankey.m`)[cite: 2, 5, 15].
* **Gate 1 — Two-Stage CES Skill Technology ($\theta_c$ Experience Asset, Ages 0–5 vs. 6–17):**
  * *Document 1A Claim:* First 2000 Days (ages 0–5) exhibit high substitutability, while primary/secondary schooling (ages 6–17) exhibits strong dynamic complementarity, yielding a NZD 112B–162B present-value societal payoff[cite: 2, 15, 20].
  * *Code & Math Mapping:* Implemented in `ChildCES_aprimeFn.m` (and unified across the full lifecycle in `HumanCapital_Lifecycle_aprimeFn.m`) with `vfoptions.experienceasset = 1` over the 9-point grid `a_grid_thetac`[cite: 2]:
    * **Stage 1 (First 2000 Days, $j \in \mathcal{J}_{c,1}$, child ages 0–5):** `Params.phi1_ces` $= \varphi_1 = 0.35 > 0$ (elasticity of substitution $\sigma_1 = \frac{1}{1 - \varphi_1} = 1.54 > 1$), `gamma1_self = 0.53`, `gamma1_inv = 0.24`, `gamma1_par = 0.23`, public wraparound lever `Params.G_ece_stage1 = 0.045` (scaling to $0.110$ in reform), and Stone-Geary luxury floor `Params.gbar_ece = 0.020`[cite: 2, 11].
    * **Stage 2 (School Years, $j \in \mathcal{J}_{c,2}$, child ages 6–17):** `Params.phi2_ces` $= \varphi_2 = -0.95 < 0$ (elasticity of substitution $\sigma_2 = \frac{1}{1 - \varphi_2} = 0.51 < 1$), `gamma2_self = 0.87`, `gamma2_inv = 0.07`, `gamma2_par = 0.06`, public lever `Params.G_ece_stage2 = 0.065`[cite: 2].
* **Gate 2 — The Early-Adolescent Vulnerability Window (Ages 12–14, $J=5$) & Two-Way Montessori Peer Mentoring:**
  * *Document 1A Claim:* Parental unemployment and housing distress at ages 12–14 trigger skill erosion and acute exits, whereas Two-Way Montessori Cross-Age Peer Mentoring buffers vulnerable mentees and boosts high-performing mentors[cite: 6, 15].
  * *Code & Math Mapping:* In `Plot_ChildFates_2Panel_SSankey.m` and `Plot_ChildFiscal_2Panel_SSankey.m` (Column 3, $J=5$), family unemployment stress is identified on the solved Markov state space via `is_unemp_stress = (iz == 1) || (n_z1 >= 5 && iz == 2 && is_hardship)`[cite: 15]:
    * **Node 7 (`Unemp Stress + Exits 1,2,4`):** Unbuffered parental job loss imposes a skill-erosion penalty $\Delta \ln\left(h_{\mathrm{mean}}\right) = -0.22$ ($26.8\%$ of cohort costing $\mathrm{NZD\ } 10.8\mathrm{k/yr}$ in Baseline $\mathrm{SS}_0$, cut to $5.7\%$ and $\mathrm{NZD\ } 2.3\mathrm{k/yr}$ in Reform $\mathrm{SS}_1$)[cite: 5, 15].
    * **Node 8 (`Standard Schooling`):** Neutral trajectory maintenance $\Delta \ln\left(h_{\mathrm{mean}}\right) = 0.00$ ($56.2\%$ of cohort in $\mathrm{SS}_0$; $35.7\%$ in $\mathrm{SS}_1$)[cite: 5, 15].
    * **Node 9 (`Montessori Mentoring`):** Cross-age peer mentoring banks Stage-1 skill gains with $\Delta \ln\left(h_{\mathrm{mean}}\right) = +0.05$ in $\mathrm{SS}_0$ ($17.0\%$ of cohort, $\mathrm{NZD\ } 9.8\mathrm{k/yr}$) and rises to $\Delta \ln\left(h_{\mathrm{mean}}\right) = +0.11$ in $\mathrm{SS}_1$ ($58.6\%$ of cohort, $\mathrm{NZD\ } 26.8\mathrm{k/yr}$), while amplifying effective Stage-1 public wraparound productivity via $G_{\mathrm{ECE,eff}} = 1.15 \times G_{\mathrm{ECE}}$[cite: 5, 15].

In New Zealand, the 17.3% baseline for Montessori / Tuakana Mentoring comprises state/integrated Montessori adolescent units (Wāora, Berhampore, Royal Oak), high-agency state schools (Ao Tawhiti, Hobsonville Point), Māori-medium Tuakana–Teina kura, and structured cross-age school mentoring (Graeme Dingle Stars/Project K), which the reform scales to 57.3% of all Years 8–10 students nationwide.

---

### B. Venture & Growth Capital Section Cross-Reference (`Lens 2 & Lens 3: ReturnFn_Firm.m` & `Build_IntergenTransitionMatrix.m`)[cite: 2]
* **4-Region Business Firm Shares & Entrepreneurial Productivity Ceilings:**
  * *Document 1A Claim:* $35.1\%$ of NZ businesses operate in Auckland and $26.9\%$ in Large regional cities, holding the highest productivity scale-up ceilings[cite: 2].
  * *Code Mapping:* `Params.PTypeWeights(5:8)` normalized to `[0.150, 0.230, 0.269, 0.351]` (Stats NZ Feb 2025 Business Demography)[cite: 2]. Infinite-horizon firm productivity grids `z_grid.Firm_k` ($z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$) and annual regional trend growth rates $G_{k,\mathrm{ann}}$ are calibrated as[cite: 2]:
    * `Firm_Rural`: $\lbrack 0.70, 1.15\rbrack$, $G_{\mathrm{Rural,ann}} = 1.007$[cite: 2].
    * `Firm_Small`: $\lbrack 0.75, 1.28\rbrack$, $G_{\mathrm{Small,ann}} = 1.011$[cite: 2].
    * `Firm_Large`: $\lbrack 0.83, 1.50\rbrack$, $G_{\mathrm{Large,ann}} = 1.018$[cite: 2].
    * `Firm_Auckland`: $\lbrack 0.90, 1.75\rbrack$, $G_{\mathrm{Auckland,ann}} = 1.025$[cite: 2].
* **Guvenen et al. (2023) Tax Shift & Wage / House Price Multipliers:**
  * *Document 1A Claim:* Shifting from capital income tax $\tau_k$ to a book-value wealth/land tax ($\tau_a = 1.5\%$) and estate levy ($\tau_b = 25\%$) on the NZD 1.6T property transfer lifts regional wages by $+3.2\%$ to $+5.5\%$ and cools urban house overvaluation by $-5.0\%$ to $-7.5\%$[cite: 2].
  * *Code Mapping:* In `WelfareDecomposition_4Region.m`, `Params_Reform.tau_a = 0.015`, `Params_Reform.tau_b = 0.25`, `Params_Reform.YouthGrant = 0.065` (up from baseline $0.030$), with general equilibrium multipliers `w_mult_GE = [1.032, 1.038, 1.048, 1.055]` and `Q_mult_GE = [0.990, 0.975, 0.950, 0.925]` across `{Rural, Small, Large, Auckland}`[cite: 2].

---

### C. Policy-Maker Section Cross-Reference (`FertilityBargaining_Module.m`, `WelfareDecomposition_4Region.m`, & `Plot_ChildFiscal_2Panel_SSankey.m`)[cite: 2, 5, 6]
* **4-Region "Income x Geography" Transfer Vector (`Params_Reform.Transfer_Geo`):**
  * Baseline regional transfers `[0.025, 0.020, 0.016, 0.014]` scale under the High-Opportunity Reform to `Params_Reform.Transfer_Geo = [0.038, 0.031, 0.025, 0.028]` across `{HH_Rural, HH_Small, HH_Large, HH_Auckland}` to offset Rural/Small mandatory transport subsistence $\bar{e}_k$ and Large/Auckland rental stress[cite: 2].
* **6-Gate Intergenerational Fiscal Ledger (`FiscalLedger.SS0`, `FiscalLedger.SS1`) & The 2050 Debt-Targeting Protocol:**
  * Computed post-hoc in `Plot_ChildFiscal_2Panel_SSankey.m` with `NZD_Base_Scale = 95.0` ($1.0\text{ model unit} = \mathrm{NZD\ } 95.0\mathrm{k/yr}$ mean prime household earnings) and Oranga Tamariki acute state care anchored at $\approx \mathrm{NZD\ } 180\mathrm{k/care\text{-}yr}$ (`@NZD 32k/stunted` annualized cohort burden across Exits 1, 2, and 4)[cite: 5, 6].
  * Summarized in `FiscalLedger.Protocol_2050_Summary` (Section 3 below), partitioning 100% of the net reform fiscal gain $\Omega_{\mathrm{reform}} = \max\left(0, \Omega_{\mathrm{fiscal}}^{\mathrm{SS1}} - \Omega_{\mathrm{fiscal}}^{\mathrm{SS0}}\right)$ 50/50 into `SinkingFund_50Pct_kNZD` and `ReinvestmentPool_50Pct_kNZD`[cite: 5, 6].

---

## 3. Complete Empirical CSV & Fiscal Ledger Audit Tables

### Table 1: 6-Gate Lifecycle Fiscal & Private Cost Flows (`FiscalLedger.SS0` vs. `FiscalLedger.SS1` — National Cohort-Weighted NZD k/yr per Birth)
*Source Script & Figure: `Plot_ChildFiscal_2Panel_SSankey.m` / [`Fig_ChildFiscal_2Panel_National_Dunedin_22.png`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Fig_ChildFiscal_2Panel_National_Dunedin_22.png)*[cite: 5, 6]

| Gate & Column ($J$) | Block # & Flow Node Name | Baseline $\mathrm{SS}_0$ Pop Share (%) | Baseline $\mathrm{SS}_0$ Flow (`NZD k/yr`) | Reform $\mathrm{SS}_1$ Pop Share (%) | Reform $\mathrm{SS}_1$ Flow (`NZD k/yr`) | Accounting Lens & Empirical Anchor |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Gate 1 ($J=1$)**<br>*Birth, Age 0* | **1.** Means-Tested Birth Support<br>**2.** Universal Birth Benefit<br>**3.** Private Birth Out-of-Pocket | $68.0\%$<br>$100.0\%$<br>$93.4\%$ | $\mathrm{NZD\ } 4.9\mathrm{k/yr}$<br>$\mathrm{NZD\ } 13.5\mathrm{k/yr}$<br>$\mathrm{NZD\ } 23.3\mathrm{k/yr}$ | $68.0\%$<br>$100.0\%$<br>$93.4\%$ | $\mathrm{NZD\ } 4.9\mathrm{k/yr}$<br>$\mathrm{NZD\ } 17.8\mathrm{k/yr}$<br>$\mathrm{NZD\ } 23.2\mathrm{k/yr}$ | WFF/BestStart + Accommodation Supp.<br>PPL + Universal BestStart + Plunket/LMC<br>Private infant gear, housing & leave cost[cite: 5] |
| **Gate 2 ($J=2..3$)**<br>*First 2000 Days* | **4.** ECE Corner + Benefit Need ($i_c=0$)<br>**5.** Public ECE + Mod. Inv<br>**6.** High Wraparound + Time | $58.8\%$<br>$14.5\%$<br>$26.7\%$ | $\mathrm{NZD\ } 8.4\mathrm{k/yr}$<br>$\mathrm{NZD\ } 4.3\mathrm{k/yr}$<br>$\mathrm{NZD\ } 20.4\mathrm{k/yr}$ | **$12.9\%$**<br>**$60.4\%$**<br>$26.7\%$ | **$\mathrm{NZD\ } 1.8\mathrm{k/yr}$**<br>**$\mathrm{NZD\ } 23.6\mathrm{k/yr}$**<br>$\mathrm{NZD\ } 24.7\mathrm{k/yr}$ | Ferriere et al. luxury corner ($i_c=0$)<br>Barnardos *Te Korowai Mokopuna* $G_{\mathrm{ECE},1}$<br>Private top-up $i_c$ + parental time[cite: 2, 5, 15] |
| **Gate 3 ($J=5$)**<br>*Adol. Ages 12–14* | **7.** Unemp Stress + Exits 1,2,4<br>**8.** Standard Schooling<br>**9.** Montessori Peer Mentoring | $26.8\%$<br>$56.2\%$<br>$17.0\%$ | $\mathrm{NZD\ } 10.8\mathrm{k/yr}$<br>$\mathrm{NZD\ } 20.4\mathrm{k/yr}$<br>$\mathrm{NZD\ } 9.8\mathrm{k/yr}$ | **$5.7\%$**<br>$35.7\%$<br>**$58.6\%$** | **$\mathrm{NZD\ } 2.3\mathrm{k/yr}$**<br>$\mathrm{NZD\ } 12.0\mathrm{k/yr}$<br>**$\mathrm{NZD\ } 26.8\mathrm{k/yr}$** | Parental job loss (`iz==1`) + acute care<br>Standard secondary schooling $G_{\mathrm{ECE},2}$<br>Two-way cross-age peer mentoring[cite: 5, 6, 15] |
| **Gate 4 ($J=6..7$)**<br>*Adult Launch, 20* | **10.** Stunted $h_1\text{--}h_2$ [Exits 1,2,4]<br>**11.** Core Skill Tier $h_3\text{--}h_5$<br>**12.** Thriving Tier $h_6\text{--}h_7$ | $28.5\%$<br>$48.2\%$<br>$23.2\%$ | $\mathrm{NZD\ } 10.0\mathrm{k/yr}$<br>$\mathrm{NZD\ } 15.6\mathrm{k/yr}$<br>$\mathrm{NZD\ } 13.0\mathrm{k/yr}$ | **$0.2\%$**<br>$38.8\%$<br>**$61.0\%$** | **$\mathrm{NZD\ } 2.2\mathrm{k/yr}$**<br>$\mathrm{NZD\ } 15.5\mathrm{k/yr}$<br>**$\mathrm{NZD\ } 26.2\mathrm{k/yr}$** | Dunedin Study 22% high-need anchor<br>Core vocational/secondary launch<br>Tertiary/high-skill launch + Youth Grant $E$[cite: 2, 5, 15] |
| **Gate 5 ($J=10$)**<br>*Age 30 Ledger* | **13.** Exits 1,2,4: Care/Hosp/Just<br>**14.** Infra, Roads & Base Health<br>**15.** Age 30 GST & Cap Tax<br>**16.** Age 30 PAYE Income Tax<br>**17.** Lost Tax: Exit 3 + Emig | — | $\mathrm{NZD\ } 10.0\mathrm{k/yr}$<br>$\mathrm{NZD\ } 3.9\mathrm{k/yr}$<br>$\mathrm{NZD\ } 4.2\mathrm{k/yr}$<br>$\mathrm{NZD\ } 4.4\mathrm{k/yr}$<br>*($\mathrm{NZD\ } 2.9\mathrm{k/yr}$)* | — | **$\mathrm{NZD\ } 2.7\mathrm{k/yr}$**<br>$\mathrm{NZD\ } 3.9\mathrm{k/yr}$<br>**$\mathrm{NZD\ } 8.2\mathrm{k/yr}$**<br>**$\mathrm{NZD\ } 8.9\mathrm{k/yr}$**<br>*($\mathrm{NZD\ } 2.2\mathrm{k/yr}$)* | Acute remediation (`@NZD 32k/stunted`)<br>Universal per-adult public overhead<br>$\tau_c c_{nd} + \tau_k r a + \tau_a a + \tau_{\mathrm{corp}}$<br>$\tau_l w_k z h \ell$<br>Foregone Crown tax from stunting/Abroad[cite: 5] |
| **Gate 6 ($J=11..16$)**<br>*Career to Ret.* | **18.** Exits 1,2,4: Ongoing Burden<br>**19.** NZ Super, Infra & Health<br>**20.** GST, Cap & Estate Tax Pool<br>**21.** Career PAYE Income Tax<br>**22.** Lost Tax: Exit 3 + Abroad | — | $\mathrm{NZD\ } 7.1\mathrm{k/yr}$<br>$\mathrm{NZD\ } 5.4\mathrm{k/yr}$<br>$\mathrm{NZD\ } 8.4\mathrm{k/yr}$<br>$\mathrm{NZD\ } 1.7\mathrm{k/yr}$<br>*($\mathrm{NZD\ } 2.7\mathrm{k/yr}$)* | — | **$\mathrm{NZD\ } 2.0\mathrm{k/yr}$**<br>$\mathrm{NZD\ } 6.5\mathrm{k/yr}$<br>**$\mathrm{NZD\ } 16.9\mathrm{k/yr}$**<br>**$\mathrm{NZD\ } 5.3\mathrm{k/yr}$**<br>*($\mathrm{NZD\ } 2.6\mathrm{k/yr}$)* | Chronic adult justice/welfare/hospital<br>Universal $P_{\mathrm{super}}$ + old-age health<br>$\tau_c + \tau_k + \tau_a + \tau_b(1-s_j)a^{\prime}$<br>Annuitized career PAYE stream<br>Foregone Crown tax from brain drain[cite: 5] |

---

### Table 2: The 2050 Sovereign Debt-Sinking Fund & Public Reinvestment Protocol (`FiscalLedger.Protocol_2050_Summary`)
*Source Script: Section 3 of `Plot_ChildFiscal_2Panel_SSankey.m` (National Cohort-Weighted `NZD k/yr` per Birth)*[cite: 5, 6]

| Lifecycle Ledger Stage | `Baseline_SS0_kNZD` ($\Omega_{\mathrm{fiscal}}^{\mathrm{SS0}}$) | `Reform_SS1_kNZD` ($\Omega_{\mathrm{fiscal}}^{\mathrm{SS1}}$) | `Reform_Gain_Omega_kNZD` ($\Omega_{\mathrm{reform}}$) | `DebtSinking_50Pct_kNZD` (50% to 2050 Debt Target) | `ReinvestPool_50Pct_kNZD` (50% to Infra / NZSF) | `DebtInterestSaved_2050_kNZD` ($r_{\mathrm{gov}}=4.2\%$) | `Infra_NZSF_YieldDiv_2050_kNZD` ($\mu_{\mathrm{infra}}=1.65\times$) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`Gate5_Age30_J10`** (Age 30) | $-\mathrm{NZD\ } 5.30\mathrm{k/yr}$ | $+\mathrm{NZD\ } 10.50\mathrm{k/yr}$ | **$+\mathrm{NZD\ } 15.80\mathrm{k/yr}$** | $+\mathrm{NZD\ } 7.90\mathrm{k/yr}$ | $+\mathrm{NZD\ } 7.90\mathrm{k/yr}$ | $+\mathrm{NZD\ } 0.33\mathrm{k/yr}$ | $+\mathrm{NZD\ } 13.04\mathrm{k/yr}$ |
| **`Gate6_CareerToRet_J11_16`** | $-\mathrm{NZD\ } 2.40\mathrm{k/yr}$ | $+\mathrm{NZD\ } 13.70\mathrm{k/yr}$ | **$+\mathrm{NZD\ } 16.10\mathrm{k/yr}$** | $+\mathrm{NZD\ } 8.05\mathrm{k/yr}$ | $+\mathrm{NZD\ } 8.05\mathrm{k/yr}$ | $+\mathrm{NZD\ } 0.34\mathrm{k/yr}$ | $+\mathrm{NZD\ } 13.28\mathrm{k/yr}$ |

---

### Table 12A: Intergenerational Elasticity of Earnings (`IGE`) — Short-Run PE (`SR`) vs. Long-Run GE (`LR`)
*Source File: [`Table12A_LeeSeshadri_4Region_IGE.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12A_LeeSeshadri_4Region_IGE.csv) (with 3-year time grid sensitivity in [`Table4_4Region_LeeSeshadri_IGE.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table4_4Region_LeeSeshadri_IGE.csv))*[cite: 2, 15, 22, 23]

| `Row` (Policy Regime) | `Rural_SR` | `Small_SR` | `Large_SR` | `Auckland_SR` | `Rural_LR` | `Small_LR` | `Large_LR` | `Auckland_LR` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline`** | $0.2535$ | $0.2383$ | $0.3488$ | $0.4448$ | $0.2535$ | $0.2383$ | $0.3488$ | $0.4448$ |
| **`P0_Early_0to5`** | $0.2535$ | $0.2391$ | $0.3274$ | $0.4387$ | $0.2653$ | $0.2388$ | $0.3655$ | **$0.4218$** |
| **`P1P2_Late_6to17`** | $0.2764$ | $0.2626$ | $0.3466$ | $0.4335$ | $0.2882$ | $0.2660$ | $0.3555$ | $0.4215$ |
| **`BN_FrontLoad`** | **$0.2345$** | **$0.2202$** | $0.3522$ | $0.4475$ | **$0.2347$** | **$0.2193$** | $0.3635$ | $0.4477$ |
| **`P0_Plus_GrantE`** | $0.2558$ | $0.2412$ | **$0.3279$** | **$0.4377$** | $0.2571$ | **$0.2359$** | $0.3620$ | **$0.4264$** |

---

### Table 12B: Variance of Adult Human Capital ($h_1$) & Lifetime Earnings (`LFE`) Explained by Parental State at Age 30–35, Plus Log Earnings Variance (`VarLogE`)
*Source File: [`Table12B_LeeSeshadri_4Region_VarExpl.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12B_LeeSeshadri_4Region_VarExpl.csv)*[cite: 2]

| `Row` (Policy Regime) | `VarExpl_h1_Rural` (%) | `VarExpl_h1_Small` (%) | `VarExpl_h1_Large` (%) | `VarExpl_h1_Auckland` (%) | `VarExpl_LFE_Rural` (%) | `VarExpl_LFE_Small` (%) | `VarExpl_LFE_Large` (%) | `VarExpl_LFE_Auckland` (%) | `VarLogE_Rural` | `VarLogE_Small` | `VarLogE_Large` | `VarLogE_Auckland` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline`** | $58.80\%$ | $62.91\%$ | $79.24\%$ | $85.81\%$ | $70.74\%$ | $73.23\%$ | $83.98\%$ | $88.74\%$ | $0.1209$ | $0.2510$ | $0.3471$ | $0.4155$ |
| **`P0_Early_0to5`** | $64.36\%$ | $66.71\%$ | **$78.31\%$** | **$84.37\%$** | $74.13\%$ | $75.61\%$ | **$83.33\%$** | **$87.67\%$** | $0.1500$ | $0.2864$ | **$0.3161$** | **$0.4047$** |
| **`P1P2_Late_6to17`** | $63.01\%$ | $66.11\%$ | $78.26\%$ | $84.44\%$ | $73.29\%$ | $75.22\%$ | $83.30\%$ | $87.73\%$ | $0.1322$ | $0.2692$ | $0.3304$ | $0.4079$ |
| **`BN_FrontLoad`** | $58.92\%$ | $62.88\%$ | $79.79\%$ | $85.89\%$ | $70.81\%$ | $73.21\%$ | $84.37\%$ | $88.80\%$ | $0.1239$ | $0.2551$ | $0.3454$ | $0.4161$ |
| **`P0_Plus_GrantE`** | $63.03\%$ | $66.07\%$ | **$77.87\%$** | **$84.35\%$** | $73.31\%$ | $75.20\%$ | **$83.02\%$** | **$87.66\%$** | $0.1491$ | $0.2869$ | **$0.3133$** | **$0.4052$** |

---

### Table 12C: Percentage Change in Average Lifetime Earnings (`Ebar` %) & Newborn Consumption Equivalent Welfare (`CE_LR` %)
*Source File: [`Table12C_LeeSeshadri_4Region_Welfare.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table12C_LeeSeshadri_4Region_Welfare.csv)*[cite: 2]

| `Row` (Policy Regime) | `Ebar_SR_Rural` (%) | `Ebar_SR_Small` (%) | `Ebar_SR_Large` (%) | `Ebar_SR_Auckland` (%) | `Ebar_LR_Rural` (%) | `Ebar_LR_Small` (%) | `Ebar_LR_Large` (%) | `Ebar_LR_Auckland` (%) | `CE_LR_Rural` (%) | `CE_LR_Small` (%) | `CE_LR_Large` (%) | `CE_LR_Auckland` (%) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`BM_Baseline`** | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ | $0.00\%$ |
| **`P0_Early_0to5`** | $-0.03\%$ | $-0.07\%$ | $-0.10\%$ | $-0.01\%$ | **$+10.63\%$** | **$+19.97\%$** | **$+11.22\%$** | **$+3.94\%$** | **$+9.99\%$** | **$+12.48\%$** | **$+14.33\%$** | **$+5.54\%$** |
| **`P1P2_Late_6to17`** | $-0.01\%$ | $-0.07\%$ | $-0.10\%$ | $-0.01\%$ | $+3.55\%$ | $+6.96\%$ | $+5.16\%$ | $+1.33\%$ | $+3.26\%$ | $+4.53\%$ | $+6.84\%$ | $+2.48\%$ |
| **`BN_FrontLoad`** | $-0.03\%$ | $-0.08\%$ | $-0.10\%$ | $-0.01\%$ | $+1.75\%$ | $+2.19\%$ | $+2.09\%$ | $+1.29\%$ | $+1.72\%$ | $+1.60\%$ | $+2.39\%$ | $+1.41\%$ |
| **`P0_Plus_GrantE`** | $-0.07\%$ | $+0.88\%$ | $-0.05\%$ | $-0.01\%$ | **$+10.51\%$** | **$+20.80\%$** | **$+11.91\%$** | **$+3.38\%$** | **$+18.13\%$** | **$+18.55\%$** | **$+18.66\%$** | **$+4.85\%$** |

---

### Table Fert1: Endogenous Total Fertility Rate (`TFR`) & Differential Fertility Ratio (`DiffFert` = Low-Skill / High-Skill Fertility)
*Source File: [`Table_Fert1_4Region_TFR_DiffFertility.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table_Fert1_4Region_TFR_DiffFertility.csv)*[cite: 2]

| `Row` (Fertility Scenario) | `TFR_Rural` | `TFR_Small` | `TFR_Large` | `TFR_Auckland` | `DiffFert_Rural` | `DiffFert_Small` | `DiffFert_Large` | `DiffFert_Auckland` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1_Baseline_StatusQuo`** | $3.7944$ | $3.7923$ | $3.5681$ | **$1.4227$** | $1.0442$ | $1.0772$ | $2.1802$ | $2.9841$ |
| **`2_Hyperbolic_NoCommit` ($\beta_{\mathrm{hyp}}=0.72$)** | $3.7920$ | $3.7859$ | $3.4173$ | **$1.1765$** | $1.0695$ | $1.1480$ | $2.6157$ | $2.8548$ |
| **`3_Barnardos_ECE_Bargaining_Relief`** | $3.7950$ | $3.7942$ | **$3.6815$** | **$1.7453$** | $1.0384$ | $1.0558$ | **$1.5562$** | $3.0226$ |
| **`4_Full_Package` (ECE1 + Housing Cool + Commit)** | $3.7950$ | $3.7942$ | **$3.6817$** | **$1.7460$** | $1.0385$ | $1.0561$ | **$1.5566$** | $3.0235$ |

---

### Table Fert2: Stunted Cohort Share, 65+ Aged Dependency Ratio, and Required Labor Tax Rate ($\tau_l$)
*Source File: [`Table_Fert2_4Region_Stunting_NZSuper.csv`](https://github.com/MichaelTiemann/IGWelfare/blob/main/Output_NZ_4Region_Intergen/Table_Fert2_4Region_Stunting_NZSuper.csv)*[cite: 2]

| `Row` (Fertility Scenario) | `Stunted_Rural_Pct` | `Stunted_Small_Pct` | `Stunted_Large_Pct` | `Stunted_Auckland_Pct` | `DepRatio_65Plus_Pct` | `Required_LaborTax_Pct` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1_Baseline_StatusQuo`** | $97.22\%$ | $96.45\%$ | $89.50\%$ | $46.58\%$ | $12.95\%$ | $26.96\%$ |
| **`2_Hyperbolic_NoCommit` ($\beta_{\mathrm{hyp}}=0.72$)** | $97.23\%$ | $96.48\%$ | $91.01\%$ | $48.16\%$ | **$14.79\%$** | $27.41\%$ |
| **`3_Barnardos_ECE_Bargaining_Relief`** | $97.22\%$ | $96.44\%$ | $88.14\%$ | $43.47\%$ | **$11.20\%$** | $28.12\%$ |
| **`4_Full_Package` (ECE1 + Housing Cool + Commit)** | $97.22\%$ | $96.44\%$ | **$88.09\%$** | **$43.42\%$** | **$11.19\%$** | **$28.10\%$** |

### 3.1 Reconciling Conventional Child-Rearing Estimates (NZD 15k–19k/yr) with the 6-Gate Macroeconomic & Fiscal Ledger
A natural question arises when comparing standard household budget surveys against the 6-Gate Fiscal Sankey diagram (`Fig_ChildFiscal_5Stage_2Panel_National_Dunedin_22.jpg` and `Table14_FiscalLedger_6Gate_Decomp_National.csv`): *Conventional New Zealand estimates (such as Inland Revenue Child Support expenditure tables and Otago/Stats NZ Household Economic Survey benchmarks) place a family's out-of-pocket cost of raising a child at roughly **NZD 15,000 to NZD 19,000 per year**. Why, then, do the total column heights in the Fiscal Sankey diagram run from **NZD 16.0k/yr (ages 0–5) to NZD 30.1k/yr (ages 12–14) and NZD 25.8k/yr (age 20)** under the Status Quo, and from **NZD 31.5k/yr (birth to age 5) down to NZD 27.7k/yr (ages 12–14) and NZD 28.9k/yr (age 20)** under the High-Opportunity Reform?*

The reconciliation rests on three structural insights that bridge family-level cash budgets with the full macroeconomic and Crown ledger:

1. **Conventional Surveys Measure Only Lane A (Direct Out-of-Pocket Cash), Whereas the Sankey Tracks All Four Societal Resource Lanes:**
   Standard household surveys capture only **Lane A: Direct Private Out-of-Pocket Cash** (food, clothing, childcare co-payments, and marginal bedroom rent). Following Lee and Seshadri (2019) and Daruich (2018), the Fiscal Sankey tracks the sum of four distinct resource lanes:
   * **Lane A — Private Out-of-Pocket Cash:** In the Status Quo (`SS0`), because metropolitan rent and provincial transport costs push a large share of young families to the developmental corner ($i_c = 0$), cohort-weighted private out-of-pocket birth and early-years spending is severely depressed (**NZD 2.8k/yr** at birth), whereas under the Reform (`SS1`), higher young-adult wages (+3.2% to +5.5%), the Youth Capital Grant, and cooled urban rents allow parents to commit **NZD 10.5k to NZD 15.8k/yr** in direct private cash outlays—aligning with the conventional **NZD 15k–19k/yr** benchmark for thriving families.
   * **Lane B — Private Parental Time Commitment:** In early childhood, 68% to 90% of private developmental investment consists of parental time (reading, teaching, and cross-age mentoring) valued at the parent's opportunity wage ($w_k z_p h_p \ell_{\mathrm{child}}$), adding **NZD 3.1k to NZD 8.2k/yr** in non-cash family commitment that household cash surveys omit.
   * **Lane C — Public In-Kind Developmental Investment:** Universal Paid Parental Leave, Well Child Tamariki Ora / Plunket, 20-Hours ECE, *Te Korowai Mokopuna* wraparound provision ($G_{\mathrm{ECE}}$, anchored to the **NZD 13.5k/yr** early-childhood benchmark in Daruich, 2018), public primary/secondary schooling, and Adolescent Montessori Peer Mentoring.
   * **Lane D — Reactive Crown Hardship & Crisis Remediation:** Working for Families hardship transfers, emergency housing grants, avoidable paediatric hospitalisations (Exit 2), Oranga Tamariki state care (**NZD 180k/care-yr**, Exit 1), and youth justice (Exit 4).

2. **Why the Status Quo Spikes to NZD 30.1k/yr in Adolescence While the Reform Drops to NZD 27.7k/yr:**
   * **The Status Quo Trap (`SS0`):** At ages 0 to 5, total cohort flows are only **NZD 16.0k–16.1k/yr**, and over three-fourths of that (**NZD 12.3k/yr** in Node 4) is passive hardship benefit support rather than skill formation. Because 94.1% of the cohort misses out on high-intensity early wraparound care, developmental deficits compound by ages 12 to 14 ($J=5$), forcing total spending to **surge to NZD 30.1k/yr** (**NZD 13.6k/yr** in acute adolescent unemployment stress and Exits 1, 2, and 4 + **NZD 13.4k/yr** in standard schooling + **NZD 3.1k/yr** in mentoring). Society pays *more* during adolescence to manage preventable crisis exits.
   * **The Reform Front-Loading Dividend (`SS1`):** By front-loading **NZD 31.5k/yr** at Birth and Ages 0 to 5 (**NZD 25.0k/yr** in `Node 5: Public ECE + Mod. Inv` and **NZD 3.8k/yr** in `Node 6: High Wraparound + Time`), children enter primary school with strong cognitive and emotional foundations. Consequently, by ages 12 to 14 ($J=5$), acute adolescent crisis remediation (`Node 7`) **collapses by 82% (from NZD 13.6k/yr to NZD 2.5k/yr)**, and total adolescent resource costs settle to **NZD 27.7k/yr**—**NZD 2.4k/yr cheaper than the status quo at ages 12–14**, while shifting 54.0% of adolescents into high-return Montessori peer mentoring (`Node 9: NZD 16.3k/yr`).

3. **Who Pays for the NZD 31.5k/yr Early-Years Investment? (Why Young Parents Do NOT Face Higher Income Taxes):**
   Young parents do **not** pay higher PAYE income taxes to finance the expanded First 2000 Days wraparound program. Instead:
   * **Capital & Estate Reallocation:** The public wraparound expansion (**NZD 15.8k to NZD 25.0k/yr**) is funded by the **1.5% book-value wealth/land levy** and **25% estate tax** on the **NZD 1.6 trillion** retirement property transfer (Lens 3), relieving the tax burden on young working families.
   * **Voluntary Private Crowding-In:** Because early public wraparound investment raises the child's Stage-1 skill stock ($\theta_2 \uparrow$) and Stage-2 schooling exhibits strong dynamic complementarity ($\varphi_2 = -0.95 < 0$), parents experience a higher return on their own effort and voluntarily expand their private cash and time commitment (`Node 3` rising from **NZD 2.8k to NZD 10.5k/yr**).
   * **Self-Financing Adult Fiscal Payoff:** By cutting the stunted adult launch tier (`Node 10`) from **79.7% to 4.5%**, the reform slashes adult remediation outlays (`Node 13`) from **NZD 17.6k/yr to NZD 3.4k/yr** at Age 30 and swings the Crown's net fiscal balance from a **-NZD 10.9k/yr deficit** to a **+NZD 10.2k/yr surplus** at Age 30 (and **+NZD 7.2k/yr** through retirement, funding **+NZD 3.6k/yr** for the 2050 Sovereign Debt Sinking Fund and **+NZD 3.6k/yr** for the Public Infrastructure & NZ Super Reinvestment Pool).

---

## 4. Visual Output Manifest & Core Structural Equations

### 4.1 Embedded Repository Graphics (`Output_NZ_4Region_Intergen`)
* **Figure 1 (`Fig1_Daruich_Cohort_Welfare_4Region.png`):** Cohort-by-cohort lifetime Consumption Equivalent welfare trajectory across the 60-year transition path in Rural, Small, Large, and Auckland, isolating Jump 1 ($c=0$) and Jump 2 ($c=3\text{--}4$, Year-20 intergenerational multiplier)[cite: 7, 15].
* **Figure 2 (`Fig2_Kiyotaki_Housing_Estates_4Region.png`):** Dynamic impulse responses of regional house prices $Q_{k,t}$, rental yields $rr_{k,t}$, and tenure-disaggregated consumption (Young Renters vs. Leveraged Young Owners vs. Older Retirees) across the NZD 1.6T estate transfer window[cite: 7].
* **Figure 3 (`Fig3_BrainDrain_Cohesion_4Region.png`):** Three-wave closure of the age 20–35 emigration rate to Australia/OECD, the Social Cohesion Index ($S_t$), and the Effective Tax Base per 65+ Retiree[cite: 2, 11].
* **Figure E8 (`FigE8_LeeSeshadri_4Region_Counterfactuals.png`):** 4-region replication of Lee & Seshadri's stage-investment profiles showing how `P0_Early_0to5` crowds *in* private parental effort during school years ($\varphi_2 = -0.95 < 0$)[cite: 2, 7].
* **Figure Fert (`FigFert_4Region_Bargaining_Solvency.png`):** Childcare bargaining, hyperbolic discounting ($\beta_{\mathrm{hyp}} = 0.72$), and NZ Superannuation fiscal solvency across the 4 regions[cite: 2].
* **2-Panel Population & Fiscal Sankey Diagrams (`Plot_ChildFates_2Panel_SSankey.m` & `Plot_ChildFiscal_2Panel_SSankey.m`):** 6-gate cohort population and dollar-weighted fiscal flows (`NZD k/yr`) across National, Auckland, Large, Small, Urban, and Rural catchments[cite: 5, 6, 15].

### 4.2 Core Reference Equations for Technical Reviewers
* **Infinite-Horizon Firm Bellman Equation & After-Tax Return (`ReturnFn_Firm.m`):**
  In region $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$, firms with productivity $z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$ and collateral limit $k \le \lambda_{\mathrm{col}} a_f$ ($\lambda_{\mathrm{col}} = 1.80$) solve[cite: 2]:

$$V_{F,k}\left(a_f, z_f\right) = \max_{a^{\prime}_f \in \lbrack 0, R_k\left(z_f; \Delta t\right) a_f\rbrack} \left\lbrace \ln\left(R_k\left(z_f; \Delta t\right) a_f - a^{\prime}_f\right) + \beta_{\mathrm{firm}}\left(\Delta t\right) \sum_{z^{\prime}_f} \Pi_{f,k}\left(z^{\prime}_f \vert z_f\right) V_{F,k}\left(a^{\prime}_f, z^{\prime}_f\right) \right\rbrace$$

$$R_k\left(z_f; \Delta t\right) = \left(1 - \tau_a\right)^{\Delta t} + \left(1 - \tau_k\right) \left\lbrace r + \max\left(0, \alpha_k \left(\frac{1 - \alpha_k}{w_k}\right)^{\frac{1 - \alpha_k}{\alpha_k}} z_f - \left(r + \delta_k\left(\Delta t\right)\right) \right) \lambda_{\mathrm{col}} \right\rbrace$$

* **Two-Stage Childhood CES Skill Law of Motion (`ChildCES_aprimeFn.m`) & Adult Ben-Porath (`ReturnFn_SpatialHH_UpgradeB.m`):**
  With step weight $\omega_s = 1 / n_s$ across Stage 1 ($\mathcal{J}_{c,1}$, $\varphi_1 = 0.35$) and Stage 2 ($\mathcal{J}_{c,2}$, $\varphi_2 = -0.95$)[cite: 2, 15]:

$$\theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},s}, \varphi_s\right) = \left\lbrack \gamma_{s,\mathrm{self}} \theta_c^{\varphi_s} + \gamma_{s,\mathrm{inv}} \left(i_c + G_{\mathrm{ECE},s} + \bar{g}_{\mathrm{ECE}}\right)^{\varphi_s} + \gamma_{s,\mathrm{par}} \bar{h}_p^{\varphi_s} \right\rbrack^{1/\varphi_s}$$

$$\theta^{\prime}_c = \begin{cases}
\left(1 - \omega_{s1}\right)\theta_c + \omega_{s1} \theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},1}, \varphi_1\right) & \text{if } j \in \mathcal{J}_{c,1} \\
\left(1 - \omega_{s2}\right)\theta_c + \omega_{s2} \theta_{\mathrm{step}}\left(\theta_c, i_c, G_{\mathrm{ECE},2}, \varphi_2\right) & \text{if } j \in \mathcal{J}_{c,2} \\
\theta_c & \text{otherwise}
\end{cases}$$

$$h^{\prime} = \left(1 - \delta_{hc}\left(\Delta t\right)\right) h + \left(\frac{\Delta t}{5}\right) \mathbb{I}\left(\ell > 0\right) I_h^{\alpha_I} h^{\alpha_H}$$

* **Macro Public Residual ($\Omega_{\mathrm{fiscal}}$) & The 2050 50/50 Dynamic Surplus Split (`Plot_ChildFiscal_2Panel_SSankey.m`):**
  At Gate 5 ($J=10$, Age 30) and Gate 6 ($J=11..16$, Career to Retirement), the net cohort fiscal balance $\Omega_{\mathrm{fiscal}}$ and reform dividend $\Omega_{\mathrm{reform}}$ are defined as[cite: 5, 6]:

$$\Omega_{\mathrm{fiscal}} = \underbrace{\left(\mathrm{Tax}_{\mathrm{PAYE}} + \mathrm{Tax}_{\mathrm{GST}} + \mathrm{Tax}_{\mathrm{Cap/Wealth}} + \mathrm{Tax}_{\mathrm{Corp}} + \mathrm{Tax}_{\mathrm{Estate}}\right)}_{\text{Total Good Crown Taxes Collected}} - \underbrace{\left(\mathrm{Cost}_{\mathrm{Exits\,1,2,4}} + \mathrm{Cost}_{\mathrm{Infra/Health/Super}}\right)}_{\text{Acute Remediation + Universal Public Overhead}}$$

$$\Omega_{\mathrm{reform}} = \max\left(0, \Omega_{\mathrm{fiscal}}^{\mathrm{SS1}} - \Omega_{\mathrm{fiscal}}^{\mathrm{SS0}}\right) = \underbrace{0.50 \, \Omega_{\mathrm{reform}}}_{\text{2050 Debt-Sinking Fund}} + \underbrace{0.50 \, \Omega_{\mathrm{reform}}}_{\text{Public Reinvestment Pool (Infra/Health/NZSF)}}$$