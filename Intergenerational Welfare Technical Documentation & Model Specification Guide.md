# **Intergenerational Welfare Technical Documentation & Model Specification Guide**

**A Mixed Finite/Infinite-Horizon 4-Region \+ Abroad Spatial OLG Model of Intergenerational Welfare, Housing Wealth, and Human Capital in New Zealand**

## **1\. Executive Overview & 8-fold Permanent Type (PType) Computational Architecture**

This document provides the complete mathematical specification, calibration mapping, and VFI Toolkit implementation blueprint for evaluating intergenerational welfare in New Zealand across **four domestic geographic tiers** (**Rural**, **Small**, **Large**, **Auckland**) plus an endogenous **Abroad** (Australia/OECD) emigration margin.  
To capture heterogeneous life-cycle households and collateral-constrained entrepreneurial firms across all four regions without expanding individual grid dimensions, the model dispatches **8 Permanent Types (Names\_i)** sequentially on the GPU:

| Permanent Type (Names\_i) | Horizon (NjN\_jNj​) | Pop / Firm Share (2025 Base) | Economic Role & Spatial Domain | VFI Toolkit Solver Dispatched |
| :---- | :---- | :---- | :---- | :---- |
| **HH\_Rural** | Finite ($J=16$) | \$16.0\\%\$ of HH | Rural & primary districts; elastic land (${\delta }_{H}=0.35$), high fuel/transport burden ($\bar{e}=0.048$). | ValueFnIter\_Case1\_FHorz\_ExpAsset  |
| **HH\_Small** | Finite ($J=16$) | \$24.0\\%\$ of HH | Small/medium provincial towns (\<100k); compressed middle wages, elevated transport cost ($\bar{e}=0.036$). | ValueFnIter\_Case1\_FHorz\_ExpAsset  |
| **HH\_Large** | Finite ($J=16$) | \$25.9\\%\$ of HH | Non-Auckland major metros (\>100k: Wgtn, Chch, Hamilton, Tauranga, Dunedin); university/service stepping-stone hubs. | ValueFnIter\_Case1\_FHorz\_ExpAsset  |
| **HH\_Auckland** | Finite ($J=16$) | \$34.1\\%\$ of HH | Primate metropolitan agglomeration ("Paris" analog); high wage variance (${\sigma }_{z}=0.24$), severely inelastic land (${\delta }_{H}=0.10$). | ValueFnIter\_Case1\_FHorz\_ExpAsset  |
| **Firm\_Rural** | Infinite (${N}_{j}=\infty$) | \$15.0\\%\$ of Firms | Primary/land-intensive producers (${z}_{f}\in \{0.70,1.15\}$) with trend growth ${G}_{Rural}=1.007$. | ValueFnIter\_Case1  |
| **Firm\_Small** | Infinite (${N}_{j}=\infty$) | \$23.0\\%\$ of Firms | Provincial processing, retail & trade enterprises (${z}_{f}\in \{0.75,1.28\}$) with ${G}_{Small}=1.011$. | ValueFnIter\_Case1  |
| **Firm\_Large** | Infinite (${N}_{j}=\infty$) | \$26.9\\%\$ of Firms | Regional metro manufacturing, tech & service firms (${z}_{f}\in \{0.83,1.50\}$) with ${G}_{Large}=1.018$. | ValueFnIter\_Case1  |
| **Firm\_Auckland** | Infinite (${N}_{j}=\infty$) | \$35.1\\%\$ of Firms | High-return knowledge & tradable scale-ups (${z}_{f}\in \{0.90,1.75\}$) with ${G}_{Auckland}=1.025$. | ValueFnIter\_Case1  |

(Note: In Step 4 of the Master Runner, the 5D experience-asset state space $[a,h,{\theta }_{c},z,j]$ is marginalized over ${\theta }_{c}$ into the compact 4D space $[a,h,z,j]$ via ValueFnIter\_Case1\_FHorz for rapid SMM calibration, 3-way decomposition, and the 60-year transition shooting path.)

## **2\. Macro Demographic & Dynamic Regional Population Law of Motion**

Following the NZ Treasury OLG framework (Binning et al., 2024), cohorts age across $J=16$ five-year brackets (ages 20–99, retirement at ${J}_{r}=10$, age 65\) via survival probabilities ${s}_{j}$, fertility rates ${f}_{j}$, and age-specific net migration rates:

$${N}_{t}={T}_{t-1}{N}_{t-1}+{M}_{t-1}$$

Along the 60-year transition path (\$t \= 1, \\dots, T\_{\\text{trans}}\$), the 4-region household population share vector ${s}_{HH,t}=[{s}_{Rural,t},{s}_{Small,t},{s}_{Large,t},{s}_{Auckland,t}]$ and firm share vector ${s}_{F,t}$ evolve endogenously from their Stats NZ 2025 base (\[0.160, 0.240, 0.259, 0.341\] and \[0.150, 0.230, 0.269, 0.351\]) via domestic youth sorting ${\Pi }_{mig,t}^{dom}$ (the normalized $4\times 4$ domestic submatrix of the $4\times 5$ migration operator) and international net migration inflows ${m}_{intl}=[0.115,0.210,0.270,0.405]$:

$${\tilde{s}}_{HH,t}=(1-0.12){s}_{HH,t}+0.12\left({{s}_{HH,t}{\Pi }_{mig,t}^{dom}}\right)$$

$${s}_{HH,t+1}=\frac{(1-{\zeta }_{inflow}){\tilde{s}}_{HH,t}+{\zeta }_{inflow}{m}_{intl}}{\sum\limits_{k=1}^{4}\left[{(1-{\zeta }_{inflow}){\tilde{s}}_{HH,k,t}+{\zeta }_{inflow}{m}_{intl,k}}\right]},{s}_{F,t+1}=0.85{s}_{F,t}+0.15{s}_{HH,t+1}$$

## **3\. Finite-Horizon Household Problem (Lenses 1, 2, and 3\)**

In Upgrade B (5D full specification), a household of age \$j \\in \\{1, \\dots, 16\\}\$ in region $k\in \{Rural,Small,Large,Auckland\}$ has state vector:

$${s}_{HH}=(a,h,{\theta }_{c},z,j;k)$$

where $a\in {A}_{HH}$ (61 points) is consolidated net worth (${Q}_{k}{h}_{house}-{b}_{debt}$), $h\in H$ (7 points) is adult human capital, ${\theta }_{c}\in {\Theta }_{c}$ (9 points) is the child's multi-stage skill experience asset, and $z\in {Z}_{k}$ (5 points) is a region-specific Markov labor productivity shock. Decisions are \$d \= (i\_c, \\ell, I\_h)\$ (early/school-age child investment, labor supply, and adult Ben-Porath training).

### **3.1 Housing Tenure Choice, User Costs, and 4-Region Unbalanced Growth**

Following Kiyotaki, Michaelides, and Nikolov (2024) and Hirano and Toda (2025), let ${Q}_{k}$ be the regional house price, ${R}_{ann}=(1+r{)}^{1/5}$ the gross annualized interest rate, ${\mu }_{maint}=0.04$ maintenance/rates, ${\upsilon }_{h}=0.008$ the owner-occupied tax subsidy, and ${G}_{k}$ the regional trend growth factor (${G}_{Auckland}=1.025>{G}_{Large}=1.018>{G}_{Small}=1.011>{G}_{Rural}=1.007$):

$$r{r}_{k}=\left({1+{\mu }_{maint}-\frac{{G}_{k}}{{R}_{ann}}}\right){Q}_{k},r{h}_{k}=\left({1+{\mu }_{maint}-{\upsilon }_{h}-\frac{{G}_{k}}{{R}_{ann}}}\right){Q}_{k}$$

Young working households ($j<{J}_{r}$) draw an idiosyncratic rental utility penalty $\chi \sim U[0,\bar{\chi }]$ ($\bar{\chi }=2.55$), yielding the analytical regional homeownership share ${\xi }_{k}$ and composite housing price index ${p}_{H,k}(j)$:

\$\$\\xi\_k \= \\min\\left\\{1, \\frac{1}{\\bar{\\chi}} \\left(\\frac{rr\_k}{rh\_k}\\right)\\right\\}, \\qquad p\_{H,k}(j) \= \\begin{cases} \\xi\_k rh\_k \+ (1 \- \\xi\_k) \\frac{rr\_k}{0.5 \\bar{\\chi}} & \\text{if } j \< J\_r \\\\ rh\_k & \\text{if } j \\ge J\_r \\end{cases}\$\$

### **3.2 Two-Stage Childhood CES Skill Law of Motion (ChildCES\_aprimeFn.m) & Adult Ben-Porath Dynamics**

* **Child Experience Asset ($\theta'_c$):** Driven by private investment $i_c$, stage-specific public wraparound provision ($G_{\text{ECE},1}$ at $j=3$ vs. $G_{\text{ECE},2}$ at $j=4$), and Stone-Geary luxury floor $\bar{g}_{\text{ECE}} = 0.02$:  
  $$
  \theta'_c = \begin{cases} 
  \left[ \gamma_{1,\text{self}} \theta_c^{\varphi_1} + \gamma_{1,\text{inv}} (i_c + G_{\text{ECE},1} + \bar{g}_{\text{ECE}})^{\varphi_1} + \gamma_{1,\text{par}} \bar{h}_p^{\varphi_1} \right]^{1/\varphi_1} & \text{if } j = 3 \text{ (First 2000 Days, } \varphi_1 = 0.35\text{)} \\ 
  \left[ \gamma_{2,\text{self}} \theta_c^{\varphi_2} + \gamma_{2,\text{inv}} (i_c + G_{\text{ECE},2} + \bar{g}_{\text{ECE}})^{\varphi_2} + \gamma_{2,\text{par}} \bar{h}_p^{\varphi_2} \right]^{1/\varphi_2} & \text{if } j = 4 \text{ (School Years, } \varphi_2 = -0.95\text{)} \\ 
  \theta_c & \text{otherwise} 
  \end{cases}
  $$  
* **Adult Ben-Porath Human Capital ($h'$):** During working ages ($j < J_r$), adult skill evolves via $h' = (1 - \delta_{\text{hc}})h + I_h^{\alpha_I} h^{\alpha_H}$ with $\delta_{\text{hc}} = 0.087, \alpha_I = 0.090, \alpha_H = 0.064$.

### **3.3 Recursive Bellman Equation of the Household**

The value function ${V}_{k}(a,h,{\theta }_{c},z,j)$ solves:

\$\$V\_k(a, h, \\theta\_c, z, j) \= \\max\_{i\_c, \\ell, I\_h, a', h'} \\left\\{ \\frac{u\_{\\text{comp}}^{1 \- \\eta\_c}}{1 \- \\eta\_c} \- \\psi\_l \\frac{\\ell^2}{2} \+ X\_t \+ \\Phi\_{\\text{child}}(i\_c, \\theta'\_c, j) \+ \\Phi\_{\\text{ret}}(a', \\text{Frac}\_{\\text{stunted}}, S\_t, j) \+ \\beta\_{hh} s\_j \\sum\_{z'} \\Pi\_{z,k}(z'\\vert{}z) V\_k(a', h', \\theta'\_c, z', j+1) \\right\\}\$\$  
where composite non-durable and housing consumption ${u}_{comp}$ deducts mandatory regional transport/energy subsistence ${\bar{e}}_{k}$ and adds the **Income $\times$ Geography** transfer ${T}_{k}(y)$, while retirees ($j\geq {J}_{r}$) derive relational utility from domestic youth thriving $(1-Fra{c}_{stunted})$, social cohesion / retention ${S}_{t}$, and warm-glow luxury bequests over net-of-tax estates $(1-{\tau }_{b})a'$.

## **4\. Infinite-Horizon Firm Sector (The Guvenen et al. Engine Across 4 Regions)**

In each region $k\in \{Rural,Small,Large,Auckland\}$, a continuum of infinite-horizon entrepreneurs (Firm\_k, ${N}_{j}=\infty$) with persistent talent \$z\_f \\in \\{z\_{\\ell,k}, z\_{h,k}\\}\$ operates a constant-returns technology subject to collateral constraint $k\leq {\lambda }_{col}{a}_{f}$ (${\lambda }_{col}=1.80$):

\$\$V\_{F,k}(a\_f, z\_f) \= \\max\_{a'\_f} \\left\\{ \\ln\\left( R\_{k}(z\_f; w\_k, r, \\tau\_k, \\tau\_a) a\_f \- a'\_f \\right) \+ \\beta\_{\\text{firm}} \\sum\_{z'\_f} \\Pi\_{f,k}(z'\_f \\vert{} z\_f) V\_{F,k}(a'\_f, z'\_f) \\right\\}\$\$  
Replacing capital income taxation (${\tau }_{k}$) with a book-value wealth tax (${\tau }_{a}=0.015$) shifts stationary firm net worth ${\Gamma }_{k}({a}_{f},{z}_{f})$ toward high-talent entrepreneurs ${z}_{h,k}$—with the largest productivity multiplier occurring in Firm\_Auckland (${z}_{h}=1.75$, 35.1% of NZ businesses) and Firm\_Large (${z}_{h}=1.50$, 26.9% of NZ businesses).

## **5\. The 3-Stage Intergenerational & $4\times 5$ Abroad Spatial Transition Operator**

The stationary distribution of newborn households entering adulthood at $j=1$ in region $k$, denoted ${\mu }_{1,k}({a}_{1},{h}_{1},{z}_{1})$ (jequaloneDist), is computed as a fixed point of three coupled operators inside Build\_IntergenTransitionMatrix\_UpgradeB.m (5D) and Build\_IntergenTransitionMatrix.m (4D):

### **Stage 1: Completed Childhood Skill Formation (${Q}_{h}$)**

* In the 5D experience-asset model (UpgradeB), completed Stage-2 childhood skill ${\theta }_{3}=\theta {'}_{c}(j=4)$ is extracted directly from parents reaching $j=5$ and mapped onto the child's adult human capital grid a\_grid\_hc, penalized by metropolitan housing crowding ${\psi }_{crowd}\ln ({Q}_{k})I({a}_{p}<0.05{Q}_{k})$.

In the compact 4D projection, expected log skill follows the anchored Cobb-Douglas relation:

$$\ln ({h}_{child})={\rho }_{hc}\ln ({h}_{p})+{\gamma }_{ic}\ln \left({1+{i}_{c}({a}_{p},{h}_{p},{z}_{p},k)+{G}_{ECE}}\right)-{\psi }_{crowd}\ln ({Q}_{k})I({a}_{p}<0.05{Q}_{k})+{\eta }_{h},{\eta }_{h}\sim N(0,{\sigma }_{hc}^{2})$$

* 

### **Stage 2: The $1.6TPropertyBequest&YouthGrantOperator($\\mathbf{Q}\_a\$)**

Dying retirees ($j\geq {J}_{r}$) in region $k$ leave net-of-tax property estates $(1-{\tau }_{b})a{'}_{j}(k)$. Combined with the universal Youth Capital Grant $E$ (YouthGrant), this induces the initial wealth distribution ${P}_{a,k}({a}_{1})$, where Auckland retirees generate the largest estate flows (MeanBequest.Auckland) due to ${Q}_{Auckland}=3.10$.

### **Stage 3: The $4\times 5$ Domestic & International (Abroad) Gumbel Youth Sorting Matrix (${\Pi }_{mig}$)**

Before settling into working life at $j=1$ (and early career $j=2$), young adults in origin region $k\in \{Rural,Small,Large,Auckland\}$ evaluate the 4 domestic regions $m\in \{1,2,3,4\}$ (paying moving/entry cost $\kappa (k,m)$) against the **5th outside option: emigrating to Abroad (Australia/OECD)** with value ${V}_{Abroad,t}({a}_{1},{h}_{1},{z}_{1})$:

\$\$\\mathbb{P}\_t(k \\to m \\mid a\_1, h\_1, z\_1) \= \\frac{\\exp\\left(V\_{m,t}(a\_1 \- \\kappa(k,m), h\_1, z\_1, 1\) / \\varrho\\right)}{\\exp\\left(V\_{\\text{Abroad},t}(a\_1, h\_1, z\_1, 1\) / \\varrho\\right) \+ \\sum\_{r=1}^4 \\exp\\left(V\_{r,t}(a\_1 \- \\kappa(k,r), h\_1, z\_1, 1\) / \\varrho\\right)}\$\$

$${P}_{emig,t}({a}_{1},{h}_{1},{z}_{1};k)=\frac{\exp \left({{V}_{Abroad,t}({a}_{1},{h}_{1},{z}_{1},1)/\varrho }\right)}{\exp \left({{V}_{Abroad,t}({a}_{1},{h}_{1},{z}_{1},1)/\varrho }\right)+\sum\limits_{r=1}^{4}\exp \left({{V}_{r,t}({a}_{1}-\kappa (k,r),{h}_{1},{z}_{1},1)/\varrho }\right)}$$

Each state cell $({a}_{1},{h}_{1},{z}_{1})$ is weighted by its domestic retention probability $(1-{P}_{emig,t})$, capturing both the **Rural/Small $\rightarrow$ Large $\rightarrow$ Auckland** domestic stepping-stone funnel and the selective brain-drain depletion of high-skill (${h}_{5}--{h}_{7}$), low-asset youth to Australia/OECD.

## **6\. Master 4-Region Calibration Table (Stats NZ 2025/2026 & Literature Benchmarks)**

| Parameter | Symbol | Value (Rural, Small, Large, Auckland) | Target / Empirical Source |
| :---- | :---- | :---- | :---- |
| **Demographics & Regional Weights** |  |  |  |
| Model horizon & retirement age | $J,{J}_{r}$ | $16,10$ | Ages 20–99 (5-yr brackets); NZ Super at 65\. |
| Regional Household Pop Shares (Base) | ${\omega }_{HH,k}$ | $0.160,0.240,0.259,0.341$ | Stats NZ Subnational Pop Estimates (June 2025: Akl \= 34.1%). |
| Regional Business Firm Shares (Base) | ${\omega }_{F,k}$ | $0.150,0.230,0.269,0.351$ | Stats NZ Business Demography (Feb 2025: Akl \= 35.1%). |
| Intl. Migration Inflow Shares | ${m}_{intl}$ | $0.115,0.210,0.270,0.405$ | Stats NZ projection (Auckland share rises to \~36.5% by Year 30). |
| Discount factors & CRRA curvature | ${\beta }_{hh},{\beta }_{firm},{\eta }_{c}$ | $0.9{6}^{5},0.9{5}^{5},2.0$ | Standard OLG life-cycle benchmark. |
| **Lens 1: Two-Stage Child Skill Formation** |  |  |  |
| Stage 1 (Ages 0–5) CES weights & ${\varphi }_{1}$ | ${\gamma }_{1,s},{\gamma }_{1,i},{\gamma }_{1,p},{\varphi }_{1}$ | $0.53,0.24,0.23,0.35$ | Cunha, Heckman, & Schennach (2010) Stage 1 estimates. |
| Stage 2 (Ages 6–17) CES weights & ${\varphi }_{2}$ | ${\gamma }_{2,s},{\gamma }_{2,i},{\gamma }_{2,p},{\varphi }_{2}$ | $0.87,0.07,0.06,-0.95$ | Cunha et al. (2010) Stage 2 dynamic complementarity. |
| Public ECE Stage 1, Stage 2 & floor | ${G}_{ECE,1},{G}_{ECE,2},{\bar{g}}_{ECE}$ | $0.045,0.065,0.020$ | Ferriere et al. (2025) luxury floor & NZ ECE baseline. |
| Baseline stunted cohort share | $Fra{c}_{stunted}$ | $0.143--0.220$ | NZ material hardship & Dunedin Study cohort benchmark. |
| **Lens 2: 4-Region Wages, Transport & Ben-Porath** |  |  |  |
| Regional baseline wage levels | ${w}_{k}(R,S,L,Akl)$ | $0.85,0.93,1.05,1.18$ | Spatial wage gradient across NZ urban/rural hierarchy. |
| Regional log-income AR(1) dispersion | ${\sigma }_{z}(R,S,L,Akl)$ | $0.11,0.14,0.18,0.24$ | Labrousse & Perdereau (2025) spatial income variance. |
| Mandatory transport/energy subsistence | ${\bar{e}}_{k}(R,S,L,Akl)$ | $0.048,0.036,0.022,0.016$ | Step-down from Rural/Small towns to dense Auckland. |
| Baseline Income x Geography transfer | ${T}_{k}(R,S,L,Akl)$ | $0.025,0.020,0.016,0.014$ | Reforms scale to $0.038,0.031,0.025,0.028$. |
| Adult Ben-Porath depreciation & elasticities | ${\delta }_{hc},{\alpha }_{I},{\alpha }_{H}$ | $0.087,0.090,0.064$ | Life-cycle adult human capital estimation. |
| **Lens 3: 4-Region Housing, Bequests & Firms** |  |  |  |
| Regional baseline house prices | ${Q}_{k}(R,S,L,Akl)$ | $1.05,1.40,2.05,3.10$ | Metropolitan land overvaluation gradient. |
| Regional housing supply elasticity | ${\delta }_{H}(R,S,L,Akl)$ | $0.35,0.28,0.18,0.10$ | Elastic rural land vs. constrained Auckland supply. |
| Regional trend growth factors | ${G}_{k}(R,S,L,Akl)$ | $1.007,1.011,1.018,1.025$ | Hirano & Toda (2025) unbalanced sectoral growth. |
| Firm productivity ceilings (\$z\_\\ell, z\_h\$) | ${z}_{f,k}(R,S,L,Akl)$ | $[0.70,1.15],[0.75,1.28],[0.83,1.50],[0.90,1.75]$ | Guvenen et al. (2023) heterogeneous firm returns. |
| Warm-glow bequest & Youth Grant (Base $\rightarrow$ Ref) | ${b}_{1},{b}_{2},E$ | $4.20,0.45,0.030\rightarrow 0.065$ | De Nardi (2004) & Piketty/Saez youth endowment. |

## **7\. Complete 11-File VFI Toolkit Pipeline Manifest (4-Region \+ Abroad Suite)**

| \# | File Name | Role in the 4-Region \+ Abroad VFI Toolkit Pipeline |
| :---- | :---- | :---- |
| **1** | Run\_All\_NZ\_Intergen\_Suite.m | **Master Runner:** Executes Steps 1–7 across all 4 regions (Rural, Small, Large, Auckland), manages 5D $\rightarrow$ 4D projection, and exports all CSV tables (Tables 1–9) and 300-DPI figures. |
| **2** | NZ\_4Region\_Master\_UpgradeB.m | **Upgrade B Baseline Master:** Initializes the 8 PTypes (4 Regions $\times$ Household/Firm) with Stats NZ 2025 weights (\[0.160, 0.240, 0.259, 0.341\]) and experienceasset \= 1\. |
| **3** | ChildCES\_aprimeFn.m | **Experience Asset Law of Motion:** Implements Cunha, Heckman & Schennach's two-stage CES skill production (${\varphi }_{1}=0.35,{\varphi }_{2}=-0.95$) across $j=3$ and $j=4$. |
| **4** | ReturnFn\_SpatialHH\_UpgradeB.m | **5D Household Return Function:** Embeds Kiyotaki tenure choice, 4-region subsistence ${\bar{e}}_{k}$, Ben-Porath training, two-stage child altruism, and luxury bequests. |
| **5** | Build\_IntergenTransitionMatrix\_UpgradeB.m | **5D Intergenerational Operator:** Extracts completed Stage-2 skill ${\theta }_{3}$ at $j=5$, maps \$1.6T estates at $j\geq {J}_{r}$, and computes $4\times 5$ domestic/Abroad spatial sorting. |
| **6** | PolicyExperiment\_LeeSeshadri\_4Region.m | **Stage Counterfactuals:** Runs BM, P0\_Early\_0to5, P1P2\_Late\_6to17, BN\_FrontLoad, and P0\_Plus\_GrantE across 4 regions; outputs IGE, Table 12 variance explained, and 4-panel Figure E8. |
| **7** | FertilityBargaining\_Module.m | **Fertility & Bargaining:** Evaluates cooperative childcare bargaining, hyperbolic discounting (${\beta }_{hyp}$), differential fertility, and NZ Super tax rates across 4 regions. |
| **8** | ReturnFn\_SpatialHH.m & ReturnFn\_Firm.m | **Compact 4D Household & Firm Return Functions:** Used after Step 4 projection for fast SMM calibration, 3-way decomposition, and the 60-year transition shooting loop. |
| **9** | Build\_IntergenTransitionMatrix.m | **Compact $4\times 5$ Abroad Brain-Drain Operator:** Computes age 20–35 emigration to Australia/OECD, selective ${h}_{6}--{h}_{7}$ skill depletion, replacement migration churn, and social cohesion ${S}_{t}$. |
| **10** | WelfareDecomposition\_4Region.m | **3-Way Welfare Decomposition:** Outputs the 4-region Daruich/Lee–Seshadri (Table 1), Labrousse & Perdereau $4\times 5$ quintile (Table 2), and Kiyotaki tenure cleavage (Table 3\) CE % tables. |
| **11** | TransPath\_4Region\_Master.m & Calibrate\_NZ\_Moments.m | **60-Year Transition & Dynamic Pop Weights:** Solves the non-linear transition path with endogenous PTypeWeights\_path (Auckland 34.1% $\rightarrow$ 36.5%, Table 9), brain-drain closure, and SMM moment matching. |

# **Version Previous**

# **Technical Documentation & Model Specification Guide**

**A Mixed Finite/Infinite-Horizon Spatial OLG Model of Intergenerational Welfare, Housing Wealth, and Human Capital in New Zealand**

## **1\. Executive Overview & Computational Architecture**

This document provides the complete mathematical specification, calibration mapping, and VFI Toolkit implementation blueprint for evaluating intergenerational welfare in New Zealand across three coupled life-cycle and macroeconomic lenses:

> 1. **Lens 1: Early Childhood Skill Formation (First 1000/2000 Days):** Anchored cognitive and noncognitive skill production, public in-kind provision of luxury goods with "pro-equality" externalities, and the macroeconomic returns to early childhood development policies.  
> 2. **Lens 2: The Active Working Generation:** Quantity-quality fertility and time/money child investment, adult Ben-Porath human capital maintenance and part-time/full-time labor supply, and the young renter vs. leveraged homeowner tenure cleavage.  
> 3. **Lens 3: Retirement, The \$1.6T Property Transfer, and Capital Allocation:** Universal pension fiscal dynamics, luxury bequest motives and estate taxation, unbalanced sectoral growth driving metropolitan land overvaluation, and "use-it-or-lose-it" wealth taxation on heterogeneous-return firms.

### **1.1 Mixed-Horizon Permanent Type (Names\_i) Structure**

To capture spatial heterogeneity across New Zealand (**Rural**, **Urban**, and **Auckland**) alongside dynamic entrepreneurial production without triggering the curse of dimensionality, the model partitions agents into six Permanent Types (Names\_i) in the VFI Toolkit:

| Permanent Type (Names\_i) | Horizon (N\_j) | Economic Role & Spatial Domain | VFI Toolkit Solver Dispatched |
| :---- | :---- | :---- | :---- |
| **HH\_Rural** | Finite (J \= 16\) | Provincial & agricultural NZ households; high transport/fuel subsistence, elastic housing. | ValueFnIter\_Case1\_FHorz |
| **HH\_Urban** | Finite (J \= 16\) | Regional cities (Wellington, Christchurch, Hamilton, Tauranga, Dunedin); balanced wages/housing. | ValueFnIter\_Case1\_FHorz |
| **HH\_Auckland** | Finite (J \= 16\) | Primate metropolitan agglomeration ("Paris" analog); high productivity variance, inelastic land. | ValueFnIter\_Case1\_FHorz |
| **Firm\_Rural** | Infinite (N\_j \= \\infty) | Land/primary-intensive producers (z \\in \\{z\_\\ell, z\_h\\}) with trend growth G\_{\\text{Rural}}. | ValueFnIter\_Case1 |
| **Firm\_Urban** | Infinite (N\_j \= \\infty) | Regional manufacturing/service firms with trend growth G\_{\\text{Urban}}. | ValueFnIter\_Case1 |
| **Firm\_Auckland** | Infinite (N\_j \= \\infty) | Knowledge & high-return service firms with trend growth G\_{\\text{Auckland}} \> G\_{\\text{Rural}}. | ValueFnIter\_Case1 |

## **2\. Demographics & The 3-Region Spatial Cohort Matrix**

Time is discrete, where each model period corresponds to 5 calendar years. Households enter economic adulthood at age 20 (j \= 1), retire mandatorily at age 65 (J\_r \= 10), and face a maximum lifespan of age 99 (J \= 16).

### **2.1 Macro Demographic Law of Motion**

Following the demographic matrix structure, let \\mathbf{N}\_{k,t} \= \[N\_{1,k,t}, \\dots, N\_{J,k,t}\]' denote the vector of cohort population masses in region k \\in \\{\\text{Rural}, \\text{Urban}, \\text{Auckland}\\}. The cohort population evolves via survival probabilities p\_{j} (denoted s\_j in code), age-specific fertility rates \\omega f\_j, and net migration \\mathbf{M}\_{k,t}:  
\\mathbf{N}\_{k,t} \= \\mathbf{T}\_{\\text{demo}} \\mathbf{N}\_{k,t-1} \+ \\mathbf{M}\_{k,t-1}  
where \\mathbf{T}\_{\\text{demo}} contains age-specific fertility rates \\omega f\_{j} in the first row (for fertile ages j \\in \\{2, 3, 4\\}) and survival probabilities s\_j along the sub-diagonal:  
\\mathbf{T}\_{\\text{demo}} \= \\begin{bmatrix} 0 & \\omega f\_2 & \\omega f\_3 & \\omega f\_4 & 0 & \\cdots & 0 & 0 \\\\ s\_1 & 0 & 0 & 0 & 0 & \\cdots & 0 & 0 \\\\ 0 & s\_2 & 0 & 0 & 0 & \\cdots & 0 & 0 \\\\ \\vdots & \\vdots & \\ddots & \\ddots & \\vdots & \\ddots & \\vdots & \\vdots \\\\ 0 & 0 & 0 & 0 & 0 & \\cdots & s\_{J-1} & 0 \\end{bmatrix}  
In the stationary demographic equilibrium, cohort weights \\mu\_j (Params.mewj) satisfy \\sum\_{j=1}^J \\mu\_j \= 1, pinning down the Old-Age Dependency Ratio \\text{Dep}\_{65+} \= \\frac{\\sum\_{j=J\_r}^J \\mu\_j}{\\sum\_{j=1}^{J\_r-1} \\mu\_j}.

## **3\. Finite-Horizon Household Problem (Lenses 1, 2, and 3\)**

A household of age j \\in \\{1, \\dots, J\\} residing in region k \\in \\{\\text{Rural}, \\text{Urban}, \\text{Auckland}\\} is characterized by the state vector:  
\\mathbf{s}\_{HH} \= (a, h, z, j; k)  
where:

> * a \\in \\mathcal{A}\_{HH} is consolidated nonhuman net worth (combining financial assets and net housing equity Q\_k h\_{\\text{house}} \- b\_{\\text{debt}}).  
> * h \\in \\mathcal{H} is adult human capital anchored to log earnings.  
> * z \\in \\mathcal{Z}\_k is an exogenous Markov labor productivity shock with region-specific transition matrix \\Pi\_{z,k}(z'\\vert{}z) and dispersion \\nu\_k.

### **3.1 Housing Tenure Choice, User Costs, and Spatial Subsistence**

Following Kiyotaki, Michaelides, and Nikolov and Hirano and Toda, let Q\_k be the price of a unit of housing/land in region k, R\_{\\text{ann}} \= (1 \+ r)^{1/5} be the gross annualized interest rate, \\mu\_{\\text{maint}} be the maintenance and property rates cost, \\upsilon\_h be the implicit tax subsidy to owner-occupied housing, and G\_k be the regional trend growth factor. The local rental yield rr\_k and homeowner user cost rh\_k are:  
rr\_k \= \\left(1 \+ \\mu\_{\\text{maint}} \- \\frac{G\_k}{R\_{\\text{ann}}}\\right) Q\_k, \\qquad rh\_k \= \\left(1 \+ \\mu\_{\\text{maint}} \- \\upsilon\_h \- \\frac{G\_k}{R\_{\\text{ann}}}\\right) Q\_k  
Because unbalanced productivity growth between the knowledge/service sector (Auckland) and the land/primary sector (Rural) implies G\_{\\text{Auckland}} \> G\_{\\text{Urban}} \> G\_{\\text{Rural}} with elasticity of substitution \>1, the denominator term R\_{\\text{ann}} \+ \\mu\_{\\text{maint}} \- G\_{\\text{Auckland}} compresses in Auckland, generating structural land overvaluation (Q\_{\\text{Auckland}} \\gg Q\_{\\text{Rural}}) and a rising price-to-rent ratio.  
Young working households (j \< J\_r) draw an idiosyncratic rental utility penalty \\chi \\sim U\[0, \\bar{\\chi}\]. Those with high \\chi become leveraged homeowners, while those with low \\chi rent, yielding the analytical regional homeownership share \\xi\_k and composite housing price index p\_{H,k}(j):  
\\xi\_k \= \\min\\left\\{1, \\frac{1}{\\bar{\\chi}} \\left(\\frac{rr\_k}{rh\_k}\\right)\\right\\}, \\qquad p\_{H,k}(j) \= \\begin{cases} \\xi\_k rh\_k \+ (1 \- \\xi\_k) \\frac{rr\_k}{0.5 \\bar{\\chi}} & \\text{if } j \< J\_r \\\\ rh\_k & \\text{if } j \\ge J\_r \\end{cases}  
Retirees (j \\ge J\_r) have \\chi\_o \= 0 (all prefer owning) and hold both their owner-occupied housing and the regional rental stock leased to young renters.

### **3.2 Budget Constraints & Adult Human Capital Evolution**

During the working phase (j \< J\_r), the household chooses labor supply \\ell \\in \\{0, \\ell\_{PT}, \\ell\_{FT}, \\ell\_{OT}\\} (capturing the part-time option for older workers), on-the-job Ben-Porath skill investment I\_h \\in \[0, \\bar{I}\], private early-childhood investment i\_c \\ge 0 (active during fertile ages j \\in \\{3, 4\\}), and next-period net worth a' \\ge 0\.

> 1. **Adult Ben-Porath Human Capital Law of Motion (j \< J\_r):** Following the specification with adult skill depreciation \\delta\_{hc} and training elasticities (\\alpha\_I, \\alpha\_H), measured wages reflect time net of training w\_k z h (\\ell \- I\_h), and human capital evolves according to: h' \= \\begin{cases} (1 \- \\delta\_{hc}) h \+ I\_h^{\\alpha\_I} h^{\\alpha\_H} & \\text{if } \\ell \> 0 \\\\ (1 \- \\delta\_{hc}) h & \\text{if } \\ell \= 0 \\text{ (with } I\_h \= 0\\text{)} \\end{cases}  
> 2. **Working-Age Budget Constraint (j \< J\_r):** Incorporating progressive/linear labor taxation \\tau\_l, capital income taxation \\tau\_k, consumption GST \\tau\_c, private child-investment subsidies s\_{\\text{sub}}, mandatory regional transport/energy subsistence costs \\bar{e}\_k (ebar\_energy), regional transfers T\_k (Transfer\_Geo), and the universal youth endowment E received at j \= 1: e\_{\\text{tot}} \= \\frac{(1 \+ (1 \- \\tau\_k)r)a \+ (1 \- \\tau\_l) w\_k z h \\max(0, \\ell \- I\_h) \+ \\mathbb{I}\_{j=1} E \+ T\_k \- \\bar{e}\_k \- (1 \- s\_{\\text{sub}}) i\_c \- a'}{1 \+ \\tau\_c}  
> 3. **Retirement Budget Constraint (j \\ge J\_r):** Retirees set \\ell \= I\_h \= i\_c \= 0, receive universal New Zealand Superannuation p\_{\\text{super}}, and are protected by a retirement consumption floor \\underline{c}: e\_{\\text{tot}} \= \\max\\left\\{\\underline{c}, \\, \\frac{(1 \+ (1 \- \\tau\_k)r)a \+ p\_{\\text{super}} \+ T\_k \- \\bar{e}\_k \- a'}{1 \+ \\tau\_c}\\right\\}

Given total net expenditure e\_{\\text{tot}} \> 0, Cobb-Douglas intra-period optimization between non-durable consumption c (share \\phi\_{nd}) and housing space h\_{\\text{space}} (share 1 \- \\phi\_{nd}) yields composite consumption utility index u\_{\\text{comp}} \= e\_{\\text{tot}} \\cdot (p\_{H,k}(j))^{\\phi\_{nd} \- 1}.

### **3.3 Recursive Bellman Equation of the Household**

The value function V\_k(a, h, z, j) for household type k solves:  
V\_k(a, h, z, j) \= \\max\_{\\ell, I\_h, i\_c, a'} \\left\\{ \\frac{u\_{\\text{comp}}^{1 \- \\eta\_c}}{1 \- \\eta\_c} \- \\psi\_l \\frac{\\ell^2}{2} \+ X\_t \+ \\Phi\_{\\text{child}}(i\_c, G\_{\\text{ECE}}, j) \+ \\Phi\_{\\text{ret}}(a', \\bar{h}\_{\\text{child}}, j) \+ \\beta\_{hh} s\_j \\sum\_{z'} \\Pi\_{z,k}(z'\\vert{}z) V\_k(a', h', z', j+1) \\right\\}  
where the three intergenerational linkage terms are:

> * **Luxury Child Investment & Pro-Equality Externality (X\_t, \\Phi\_{\\text{child}}):** Following Labrousse and Perdereau, early childhood investment is a luxury good (\\bar{g}\_{\\text{ECE}} \> 0\) that combines private parental spending i\_c and public in-kind provision G\_{\\text{ECE}} (the Barnardos ECE-plus-whānau-support mechanism): \\Phi\_{\\text{child}}(i\_c, G\_{\\text{ECE}}, j) \= \\mathbb{I}\_{j \\in \\{3,4\\}} \\omega\_{ic} \\ln(i\_c \+ G\_{\\text{ECE}} \+ \\bar{g}\_{\\text{ECE}}), \\qquad X\_t \= \\frac{\\chi}{\\alpha} \\ln\\left( \\int (i\_c \+ G\_{\\text{ECE}} \+ \\bar{g}\_{\\text{ECE}})^\\alpha \\, d\\mu \\right) Because \\bar{g}\_{\\text{ECE}} \> 0, low-income and housing-stressed parents hit the corner solution i\_c \= 0\. Public in-kind provision G\_{\\text{ECE}} directly lifts their children's skill formation and raises the concave societal externality X\_t (\\alpha \< 1\) in a way that linear Pigouvian subsidies or cash transfers cannot replicate.  
> * **Retiree Relational Well-Being & Luxury Property Bequests (\\Phi\_{\\text{ret}}):** Following De Nardi and Piketty and Saez, retirees at j \\ge J\_r derive relational utility from the thriving share of the younger generation (1 \- \\text{Frac}\_{\\text{stunted}}) and warm-glow utility over net-of-tax estates (1 \- \\tau\_b)a' upon mortality risk (1 \- s\_j): \\Phi\_{\\text{ret}}(a', \\bar{h}\_{\\text{child}}, j) \= \\mathbb{I}\_{j \\ge J\_r} \\left\[ \\gamma\_{\\text{rel}} \\ln(1 \- \\text{Frac}\_{\\text{stunted}}) \+ (1 \- s\_j) b\_1 \\frac{\\left(b\_2 \+ (1 \- \\tau\_b)\\max(0, a')\\right)^{1 \- \\eta\_c}}{1 \- \\eta\_c} \\right\]

## **4\. Infinite-Horizon Firm Sector (The Guvenen et al. Engine)**

In each region k \\in \\{\\text{Rural}, \\text{Urban}, \\text{Auckland}\\}, a continuum of infinite-horizon entrepreneurs/firms (N\_j.Firm\_k \= Inf) operates a constant-returns technology over capital k and effective labor n with persistent idiosyncratic productivity z\_f \\in \\{z\_{\\ell,k}, z\_{h,k}\\} governed by Markov matrix \\Pi\_{f,k}(z'\_f \\vert{} z\_f).

### **4.1 Collateral-Constrained Production & Wealth vs. Capital Income Taxation**

A firm with internal net worth (equity) a\_f \\in \\mathcal{A}\_F can borrow capital from the national bond market up to a collateral limit k \\le \\lambda\_{\\text{col}} a\_f. Optimizing out static labor demand n(k, z\_f) given regional wage w\_k yields the marginal return to capital \\text{MPK}\_k(z\_f) and excess return \\pi\_k(z\_f):  
\\text{MPK}\_k(z\_f) \= \\alpha\_k \\left(\\frac{1 \- \\alpha\_k}{w\_k}\\right)^{\\frac{1 \- \\alpha\_k}{\\alpha\_k}} z\_f, \\qquad \\pi\_k(z\_f) \= \\max\\left\\{0, \\, \\text{MPK}\_k(z\_f) \- (r \+ \\delta\_k)\\right\\} \\lambda\_{\\text{col}}  
The firm faces both a capital income/profit tax \\tau\_k and a book-value wealth tax \\tau\_a. Its gross-of-saving after-tax return R\_k(z\_f) and infinite-horizon Bellman equation are:  
R\_k(z\_f) \= (1 \- \\tau\_a)^5 \+ (1 \- \\tau\_k)\\left(r \+ \\pi\_k(z\_f)\\right) V\_{F,k}(a\_f, z\_f) \= \\max\_{a'\_f \\in \[0, R\_k(z\_f)a\_f\]} \\left\\{ \\ln\\left(R\_k(z\_f) a\_f \- a'\_f\\right) \+ \\beta\_{\\text{firm}} \\sum\_{z'\_f} \\Pi\_{f,k}(z'\_f \\vert{} z\_f) V\_{F,k}(a'\_f, z'\_f) \\right\\}  
As established in Proposition 6 and Lemma 5 of Guvenen et al., replacing capital income taxation \\tau\_k with wealth taxation \\tau\_a shifts the stationary distribution of firm equity \\Gamma\_k(a\_f, z\_f) toward high-productivity entrepreneurs (\\mu\_{h,k} \\uparrow), increasing equilibrium aggregate productivity Z(\\mu) and wages w\_k via the **"use-it-or-lose-it" reallocation effect**.

## **5\. The 3-Stage Intergenerational & Spatial Transition Matrix**

The stationary distribution of newborn households entering adulthood at j \= 1 in region k, denoted \\mu\_{1,k}(a\_1, h\_1, z\_1) (jequaloneDist), is determined endogenously as a fixed point of three coupled transition operators implemented in Build\_IntergenTransitionMatrix.m:

### **Stage 1: Anchored Childhood Skill Formation (\\mathbf{Q}\_h)**

Following Cunha, Heckman, and Schennach and Daruich, adult human capital h\_{\\text{child}} at age 20 (j=1) is anchored to childhood cognitive/noncognitive skills produced by parental human capital h\_p, early-years private \+ public investment (i\_c \+ G\_{\\text{ECE}}), and a regional housing-stress penalty for low-asset renters in overvalued markets:  
\\ln(h\_{\\text{child}}) \= \\rho\_{hc} \\ln(h\_p) \+ \\gamma\_{ic} \\ln(1 \+ i\_c(a\_p, h\_p, z\_p, k) \+ G\_{\\text{ECE}}) \- \\psi\_{\\text{crowd}} \\ln(Q\_k) \\mathbb{I}(a\_p \< 0.05 Q\_k) \+ \\eta\_h, \\quad \\eta\_h \\sim \\mathcal{N}(0, \\sigma\_{hc}^2)  
Integrating over the stationary distribution of fertile parents (j \\in \\{3, 4\\}) in region k produces the marginal skill distribution P\_{h,k}(h\_1).

### **Stage 2: The 1.6T Property Bequest & Youth Grant Operator (\\mathbf{Q}\_a\$)**

Following De Nardi and Piketty and Saez, dying retirees (j \\ge J\_r, with mortality weight 1 \- s\_j) pass on net-of-tax estates (1 \- \\tau\_b)a'\_j(k) augmented by the universal youth grant E:  
a\_{1,\\text{inherited}} \= (1 \- \\tau\_b) a'\_j(a\_r, h\_r, z\_r, j; k) \+ E  
Integrating across dying cohorts in region k yields the pre-migration initial wealth distribution P\_{a,k}(a\_1).

### **Stage 3: The 3 \\times 3 Spatial Youth Migration Matrix (\\Pi\_{\\text{mig}})**

Before entering the labor market at j \= 1, young adults born in origin region k with state (a\_1, h\_1, z\_1) draw Gumbel regional preference shocks with scale \\varrho\_{\\text{gumbel}} and evaluate moving to destination region k' \\in \\{\\text{Rural}, \\text{Urban}, \\text{Auckland}\\} subject to fixed moving/entry cost \\kappa(k, k'):

\\mathbb{P}(k \\to k' \\mid a\_1, h\_1, z\_1) \= \\frac{\\exp\\left(V\_{k'}(a\_1 \- \\kappa(k,k'), h\_1, z\_1, 1\) / \\varrho\_{\\text{gumbel}}\\right)}{\\sum\_{m=1}^3 \\exp\\left(V\_{m}(a\_1 \- \\kappa(k,m), h\_1, z\_1, 1\) / \\varrho\_{\\text{gumbel}}\\right)} \\cdot \\mathbb{I}(a\_1 \\ge \\kappa(k,k'))

## **6\. General Equilibrium Market Clearing Conditions**

A Stationary Recursive Competitive Equilibrium consists of value functions \\{V\_k, V\_{F,k}\\}, policy rules, stationary distributions \\{\\mu\_k, \\Gamma\_k\\}, newborn distributions \\{\\mu\_{1,k}\\}, factor prices \\{r, w\_{\\text{Rural}}, w\_{\\text{Urban}}, w\_{\\text{Auckland}}\\}, regional house prices \\{Q\_{\\text{Rural}}, Q\_{\\text{Urban}}, Q\_{\\text{Auckland}}\\}, and fiscal instruments \\{\\tau\_l, \\tau\_c, \\tau\_k, \\tau\_a, \\tau\_b, G\_{\\text{ECE}}, E, p\_{\\text{super}}\\} such that:

> 1. **Regional Labor Markets Clear (k \\in \\{\\text{Rural}, \\text{Urban}, \\text{Auckland}\\}):** \\int n\_k(a\_f, z\_f; w\_k, r) \\, d\\Gamma\_k \= \\sum\_{j=1}^{J\_r-1} \\mu\_j \\int z h \\max(0, \\ell \- I\_h) \\, d\\mu\_{k,j}  
> 2. **Regional Housing Markets Clear (k \\in \\{\\text{Rural}, \\text{Urban}, \\text{Auckland}\\}):** Total owner-occupied and rental housing space demanded by young and old households in region k equals elastic regional supply HS(k) \= H\_k (Q\_k)^{\\delta\_{H,k}}: \\sum\_{j=1}^J \\mu\_j \\int h\_{\\text{space}}(a, h, z, j; k) \\, d\\mu\_{k,j} \= H\_k (Q\_k)^{\\delta\_{H,k}}  
> 3. **National Capital / Bond Market Clears:** \\sum\_{k=1}^3 \\omega\_{F,k} \\int \\left(k\_k(a\_f, z\_f) \- a\_f\\right) d\\Gamma\_k \+ B\_{\\text{gov}} \= \\sum\_{k=1}^3 \\omega\_{HH,k} \\sum\_{j=1}^J \\mu\_j \\int a\_{\\text{fin}}(a, h, z, j; k) \\, d\\mu\_{k,j}  
> 4. **Crown Fiscal Budget Balance (with Stunted Cohort Remediation Drag):** Total revenues from labor income taxes (\\tau\_l), GST (\\tau\_c), corporate/capital income taxes (\\tau\_k), book-value wealth taxes (\\tau\_a), and estate taxes (\\tau\_b) equal outlays on universal NZ Superannuation (p\_{\\text{super}}), First-2000-Days public ECE (G\_{\\text{ECE}}), youth grants (E), regional transfers (T\_k), and the fiscal remediation drag of stunted cohorts (\\Delta G\_{\\text{stunted}} \\cdot \\text{Frac}\_{\\text{stunted}}).

## **7\. Master Calibration Table (NZ Data & Literature Proxies)**

| Parameter | Symbol | Value | Target / Empirical Source |
| :---- | :---- | :---- | :---- |
| **Demographics & Preferences** |  |  |  |
| Model horizon & retirement | J, J\_r | 16, 10 | Ages 20–99 (5-yr brackets); NZ Super eligibility at 65\. |
| Household & Firm discount factors | \\beta\_{hh}, \\beta\_{\\text{firm}} | 0.96^5, 0.95^5 | Standard OLG benchmark (\\beta \\in \[0.96, 0.97\]). |
| CRRA risk aversion & labor disutility | \\eta\_c, \\psi\_l | 2.0, 1.2 | Separable consumption-leisure life-cycle benchmark. |
| **Lens 1: Child Skill Formation & Public Provision** |  |  |  |
| Intergenerational skill persistence | \\rho\_{hc} | 0.40 | Anchored skill persistence & variance explained. |
| Early investment elasticity | \\gamma\_{ic} | 0.35 | Early childhood production function estimates. |
| Stone-Geary luxury parameter (ECE) | \\bar{g}\_{\\text{ECE}} | 0.02 | Income elasticity of education/health \\theta \\in \[1.15, 1.38\] \> 1\. |
| Pro-equality externality parameters | \\chi, \\alpha | 0.20, 0.50 | Concave externality calibration (\\chi \= 0.2, \\alpha \\in (-2, 2)). |
| Baseline stunted cohort share | \\text{Frac}\_{\\text{stunted}} | 0.143\\text{--}0.22 | NZ material hardship & Dunedin Study cohort benchmark. |
| **Lens 2: Adult Ben-Porath & Spatial Income** |  |  |  |
| Adult skill depreciation & elasticities | \\delta\_{hc}, \\alpha\_I, \\alpha\_H | 0.086, 0.098, 0.051 | Life-cycle Ben-Porath human capital estimation. |
| Regional income dispersion | \\sigma\_z(\\text{R, U, Akl}) | 0.11, 0.16, 0.24 | Spatial income variance (\\nu \\in (0.1, 0.2)) & primate city tail. |
| Mandatory transport/energy cost | \\bar{e}(\\text{R, U, Akl}) | 0.048, 0.026, 0.018 | Rural vs. metropolitan transport/fuel expenditure gap. |
| **Lens 3: Housing, Pensions, Bequests & Firms** |  |  |  |
| Non-durable consumption share | \\phi\_{nd} | 0.80 | Housing expenditure share 1 \- \\phi\_{nd} \= 0.20. |
| Maintenance, HO subsidy, tenure bound | \\mu\_{\\text{maint}}, \\upsilon\_h, \\bar{\\chi} | 0.04, 0.008, 2.55 | Kiyotaki, Michaelides, & Nikolov housing calibration. |
| Regional housing supply elasticity | \\delta\_H(\\text{R, U, Akl}) | 0.35, 0.22, 0.10 | Inelastic metropolitan land vs. elastic rural supply. |
| Regional trend growth factors | G(\\text{R, U, Akl}) | 1.007, 1.015, 1.025 | Unbalanced sectoral growth (G\_{\\text{Akl}} \> G\_{\\text{Rural}}). |
| Retirement floor & NZ Super | \\underline{c}, p\_{\\text{super}} | 0.04, 0.18 | Retirement consumption floor & pension replacement rate. |
| Warm-glow luxury bequest parameters | b\_1, b\_2 | 4.20, 0.45 | Top wealth decile share (\~50% of total wealth). |
| Firm collateral multiplier & return gap | \\lambda\_{\\text{col}}, z\_h / z\_\\ell | 1.80, 1.94 | Heterogeneous-return firm equilibrium bounds. |

## **8\. File Manifest & Execution Workflow in MATLAB**

Your VFI Toolkit repository consists of five modular MATLAB scripts that execute in sequence:

> 1. **NZ\_3Region\_Master.m**: Initializes the 6 Permanent Types (HH\_Rural, HH\_Urban, HH\_Auckland, Firm\_Rural, Firm\_Urban, Firm\_Auckland), constructs the demographic matrix \\mathbf{T}\_{\\text{demo}}, sets up state/decision grids, calls ValueFnIter\_PType on the GPU, and iterates on the intergenerational fixed point.  
> 2. **ReturnFn\_SpatialHH.m**: Evaluates the finite-horizon household Bellman objective, enforcing the Ben-Porath human capital law of motion, Kiyotaki et al. analytical tenure cutoffs \\xi\_k and user costs rh\_k, rr\_k, luxury early-childhood investment, and warm-glow estate bequests.  
> 3. **ReturnFn\_Firm.m**: Evaluates the infinite-horizon firm Bellman objective with collateral constraint \\lambda\_{\\text{col}} and book-value wealth tax \\tau\_a vs. capital income tax \\tau\_k.  
> 4. **Build\_IntergenTransitionMatrix.m**: Computes the 3-stage transition from fertile parents (j \\in \\{3,4\\}) and dying retirees (j \\ge J\_r) to newborn human capital \\mathbf{Q}\_h, property inheritances \\mathbf{Q}\_a, and 3 \\times 3 Gumbel youth spatial sorting \\Pi\_{\\text{mig}} across Rural, Urban, and Auckland.  
> 5. **WelfareDecomposition\_3Region.m**: Runs the policy counterfactuals and outputs the three publication-ready Consumption Equivalence (CE %) tables:  
   * *Table 1:* Short-Run PE vs. Long-Run GE and Exogenous vs. Endogenous Intergenerational Skill Transmission.  
   * *Table 2:* Spatial (Rural, Urban, Auckland) \\times Income Quintile (Q\_1\\text{--}Q\_5) Welfare Matrix.  
   * *Table 3:* Housing Tenure & Generational Cleavage (Young Renters vs. Young Leveraged Homeowners vs. Older Retirees/Landlords).

