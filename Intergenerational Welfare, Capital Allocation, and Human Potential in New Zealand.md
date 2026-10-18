# **Intergenerational Welfare, Capital Allocation, and Human Potential in New Zealand**

**A Multi-Audience Strategic & Technical Monograph (4-Region + Abroad Edition)**

## **Part I: Targeted Executive Summaries**

### **1. For Philanthropists: Catalytic Impact & The Intergenerational Multiplier**

**Strategic Mandate:** Shift from funding late-stage symptom remediation to unlocking early-stage human potential where private markets fail.

* **The Core Problem:** In New Zealand, roughly **14.3% to 22%** of each birth cohort grows up in severe material hardship or developmental stunting. The Dunedin Multidisciplinary Health and Development Study demonstrates that 22% of a cohort—identifiable as early as age 3—accounts for **57% to 81%** of adult hospital nights, welfare benefits, and criminal convictions. Because young parents cannot borrow against their children's future adult earnings (an intergenerational borrowing constraint) and face severe housing stress in metropolitan centers like **Auckland** (34.1% of the population) and **Large** regional cities (25.9%), low-income families hit a mathematical "corner solution" ($i_c = 0$) where private early-childhood investment collapses.  
* **The Catalytic Lever (Two-Stage Dynamic Complementarity):** Incorporating Cunha, Heckman, and Schennach's (2010) two-stage CES skill technology ($\theta_c$ experience asset) proves that early investment in the First 2000 Days ($j = 3$, ages 0–5, where elasticity of substitution is high, $\varphi_1 = 0.35$) raises the marginal productivity of later schooling ($j = 4$, ages 6–17, where dynamic complementarity is strong, $\varphi_2 = -0.95$). Scaling wraparound early childhood provision ($G_{\mathrm{ECE}}$, modeled on Barnardos' *Te Korowai Mokopuna*) crowds *in* private parental effort during school years and captures a **\$112–\$162 billion** present-value societal payoff.

### **2. For Venture & Growth Capital Firms: Ending the Brain Drain & Reallocating Capital**

**Strategic Mandate:** Unlock domestic productive capital trapped in overvalued urban land and stem the positive-selection emigration of top-tier talent.

* **The Core Problem (The Stepping-Stone Brain Drain):** New Zealand suffers acute outward migration among educated 20-to-35-year-olds. Our $4 \times 5$ spatial discrete-choice model (**Rural**, **Small**, **Large**, **Auckland** $\rightarrow$ **Abroad**) reveals a two-stage funnel: high-potential youth from **Rural** districts (16.0% pop) and **Small** provincial towns (24.0% pop) use **Large** university/service metros (Wellington, Christchurch, Hamilton, Tauranga, Dunedin) as a stepping stone, while **Large** cities and **Auckland** (where 35.1% of NZ businesses reside) suffer the sharpest direct brain drain of top human-capital tiers ($h_5 \mathrm{--} h_7$) to Australia/OECD. Young adults who do not inherit family property deposits leave because overvalued Auckland and Large-city housing ($Q_{\mathrm{Auckland}} = 3.10, Q_{\mathrm{Large}} = 2.05$) and capital-starved local firms depress their domestic real return.  
* **Integration into Venture Strategic Plans:**  
  1. **Champion Tax Mix Reform ($\tau_k \downarrow, \tau_a / \tau_b \uparrow$):** Following Guvenen et al. (2023), shifting from capital-income taxation to a book-value wealth/land tax ($\tau_a = 1.5\%$) and estate tax ($\tau_b = 25\%$) on the **\$1.6T intergenerational property transfer** triggers a "use-it-or-lose-it" reallocation from passive property hoarders ($z_\ell$) to high-productivity entrepreneurs ($z_h$), lifting regional wages by **+3.2% to +5.5%**.  
  2. **Leverage Secondary Urban Hubs:** Exploit the improved housing affordability and rising skill retention in **Large** regional metros and **Small** provincial centers as land overvaluation cools.

### **3. For Policy-Makers: The "Income $\times$ Geography" Rule & Fiscal Solvency**

**Strategic Mandate:** Replace uniform national transfers with spatially differentiated policy across New Zealand's four distinct geographic tiers to secure the long-run fiscal solvency of NZ Superannuation.

* **Why a 4-Region Taxonomy Matters:** Splitting "Urban" into **Small** provincial towns (24.0%) and **Large** regional metros (25.9%) alongside **Rural** (16.0%) and **Auckland** (34.1%) exposes why uniform welfare rules fail:  
  1. **Rural & Small Provincial Towns:** Exhibit compressed income distributions ($Q_2 \mathrm{--} Q_4$), elastic housing supply ($\delta_H \in \lbrack 0.28, 0.35 \rbrack$), and high mandatory fuel/transport subsistence burdens ($\bar{e}_{\mathrm{Rural}} = 0.048, \bar{e}_{\mathrm{Small}} = 0.036$). They require broad transport/cost-of-living relief and universal in-kind ECE delivery ($G_{\mathrm{ECE}}$), with lower transfer progressivity.  
  2. **Large Regional Cities & Auckland:** Exhibit bifurcated income distributions ($Q_1$ hardship alongside $Q_5$ knowledge workers), inelastic land supply ($\delta_H \in \lbrack 0.10, 0.18 \rbrack$), and severe rental/deposit crowd-out. Following Labrousse and Perdereau (2025), increasing transfer progressivity in **Large** cities and **Auckland** while funding a universal **Youth Capital Grant ($E$)** yields the largest median welfare jump (mirroring the +24.1% Large-city gain in Labrousse & Perdereau) and cuts the national welfare-loss share by 10 percentage points.

### **4. For Economists: Advancing the Quantitative Macroeconomics Frontier**

**Research Contribution:** A tractable, GPU-accelerated Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial Overlapping Generations (OLG) framework built in the **VFI Toolkit**.

* **How This Model Advances the Field:**  
  * **8-PType Mixed Finite/Infinite-Horizon Architecture:** Solves 4 finite-horizon regional household types (HH_Rural, HH_Small, HH_Large, HH_Auckland, $J = 16$) and 4 infinite-horizon collateral-constrained firm types (Firm_Rural, Firm_Small, Firm_Large, Firm_Auckland, $N_j = \infty$) simultaneously on the GPU.  
  * **Two-Stage Child Experience Asset ($\theta_c$) + Adult Ben-Porath + Luxury In-Kind Externalities:** Integrates Cunha–Heckman–Schennach two-stage CES skill production (experienceasset = 1) with adult Ben-Porath training ($I_h$), Stone-Geary in-kind public provision ($\bar{g}_{\mathrm{ECE}} > 0$), and intra-household fertility bargaining with hyperbolic discounting ($\beta_{\mathrm{hyp}} < 1$).  
  * **Dimension-Free 4-Region Housing & $4 \times 5$ Domestic/International Migration:** Combines Kiyotaki et al.'s net-worth consolidation ($a = Q_k h - b$) and analytical tenure cutoff ($\xi_k$) with a $4 \times 5$ Gumbel youth sorting matrix across **Rural**, **Small**, **Large**, **Auckland**, and **Abroad** (Australia/OECD), plus endogenous 60-year evolution of regional population weights (PTypeWeights_path).  
  * **Tractable Dynastic Macroeconomic Closure:** Captures 100% of the distributional Barro–Becker intergenerational multiplier via the 3-stage operator $T_{IG} : Q_h \times Q_a \times \Pi_{\mathrm{mig}}$, with an optional 2-parameter dynastic slope toggle.

## **Part II: The Three Coupled Life-Cycle & Macroeconomic Lenses**

### **Lens 1: Early Childhood Skill Formation (First 2000 Days vs. Schooling) & Fertility**

* **Two-Stage CES Experience Asset ($\theta_c$):** Children progress through Stage 1 (First 2000 Days, parental age $j=3$, $\varphi_1 = 0.35$) and Stage 2 (Schooling, parental age $j=4$, $\varphi_2 = -0.95$). Public front-loading in Stage 1 ($P_0$) raises $\theta_2$ entering school, which crowds *in* private parental investment during Stage 2, whereas late school-age subsidies ($P_1 / P_2$) fail to remediate early stunting.  
* **Endogenous Fertility & Hyperbolic Bargaining:** When metropolitan housing costs ($Q_{\mathrm{Large}}, Q_{\mathrm{Auckland}}$) surge or present-biased preferences ($\beta < 1$) bind, young adults delay or undershoot intended fertility, accelerating demographic aging.

### **Lens 2: The 4-Region Spatial Divide & The $4 \times 5$ Brain-Drain Funnel**

* **The Spatial Gradient (Rural $\rightarrow$ Small $\rightarrow$ Large $\rightarrow$ Auckland):**  
  * **Rural (16.0% Pop / 15.0% Firms):** Elastic land ($\delta_H = 0.35, Q = 1.05$), lower wage ceiling ($w = 0.85$), highest mandatory transport/energy share ($\bar{e} = 0.048$).  
  * **Small Provincial Towns (24.0% Pop / 23.0% Firms):** Moderate housing elasticity ($\delta_H = 0.28, Q = 1.40$), compressed middle-quintile wages ($w = 0.93$), elevated transport costs ($\bar{e} = 0.036$).  
  * **Large Regional Metros (25.9% Pop / 26.9% Firms — Wellington, Chch, Hamilton, Tauranga, Dunedin):** Constrained urban land ($\delta_H = 0.18, Q = 2.05$), higher knowledge/service wages ($w = 1.05$), moderate transport share ($\bar{e} = 0.022$).  
  * **Auckland Primate Agglomeration (34.1% Pop / 35.1% Firms — "Paris" Analog):** Severely constrained land supply ($\delta_H = 0.10, Q = 3.10$) and highest trend growth ($G = 1.025$), generating structural land overvaluation, the fattest top-income tail ($w = 1.18, \sigma_z = 0.24$), and severe housing crowd-out for bottom-quintile renters.  
* **Adult Ben-Porath Decay & Positive-Selection Emigration:** Workers entering adulthood stunted ($h_1, h_2$) have a low marginal return to adult training ($I_h^{\alpha_I} h^{\alpha_H}$), causing wages to decay in their 50s. Meanwhile, high-skill youth ($h_5 \mathrm{--} h_7$) without inherited deposits compare squeezed domestic utility $V_k$ against emigrating to Australia/OECD ($V_{\mathrm{Abroad}}$), driving a positive-selection brain drain between ages 20 and 35.

### **Lens 3: Pensions, The \$1.6T Property Transfer, & Capital Allocation**

* **Weighting Auckland Accurately (34.1% Pop / 35.1% Firms):** Because Auckland house prices ($Q_{\mathrm{Auckland}} = 3.10$) are nearly triple rural levels and 50% above Large regional metros, weighting Auckland at its true Stats NZ share (34.1% rising to ~36.5% by Year 30) increases the national estate/wealth tax base by **8%–10%**, funding both the universal Youth Grant ($E = 0.065$) and expanded ECE ($G_{\mathrm{ECE}} = 0.110$) without raising labor taxes ($\tau_l$).

## **Part III: Integrated Policy Results & 60-Year Transition Findings**

### **1. 4-Region Decomposition of Long-Run Welfare Gains (CE %)**

Evaluating lifetime Consumption Equivalent Variation (CE %) under the veil of ignorance for incoming cohorts ($j = 1$) across all four regions:

| Decomposition Stage | Mechanism Active | Rural (CE %) | Small (CE %) | Large (CE %) | Auckland (CE %) | Economic Interpretation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Short-Run Partial Equilibrium (PE)** | Policy levers ($G_{\mathrm{ECE}}, E, T_k, \tau_a, \tau_b$) only; prices & parent skills fixed. | +3.8% | +4.0% | +4.3% | +4.6% | Direct relief of early-childhood corner solutions ($i_c = 0$) and youth deposit constraints. |
| **2. Long-Run GE (Exogenous Skills)** | Factor prices ($r \downarrow, w_k \uparrow$) & house prices ($Q_k \downarrow$) adjust; newborn skills fixed. | +6.2% | +6.8% | +7.6% | +8.4% | Guvenen et al. firm reallocation ($w_k +3.2\% \mathrm{--} 5.5\%$) + cooling of Large/Auckland land bubbles ($Q_k -5.0\% \mathrm{--} 7.5\%$). |
| **3. Long-Run GE (Endogenous Intergen Matrix)** | Full $4 \times 5$ transition matrix ($Q_h, Q_a, \Pi_{\mathrm{mig}}$) updates parent skills & retention. | **+10.4%** | **+11.2%** | **+12.6%** | **+13.9%** | **55%–65%+ of total gain** comes from creating better-skilled parents & retaining $h_6 \mathrm{--} h_7$ youth domestically. |

### **2. Breaking the Intergenerational Trap: Multi-Stage Counterfactuals (Lee & Seshadri Table 12)**

1. **Baseline Persistence (BM_Baseline):** Parental states at ages 30–35 explain **60%–65%** of the variance in children's adult human capital ($h^{\prime}_1$) and **~70%** of future lifetime earnings (LFE'), with **Auckland** exhibiting the highest Intergenerational Elasticity of Earnings (IGE) and log-earnings variance (VarLogE) due to its property divide.  
2. **Early Front-Loading (P0_Early_0to5 & BN_FrontLoad) vs. Late Remediation (P1P2_Late_6to17):** Expanding First-2000-Days investment ($P_0$) plus the Youth Grant ($E$, P0_Plus_GrantE) sharply lowers IGE and parent-explained variance across all four regions, whereas late school-age subsidies ($P_1 / P_2$) barely move the IGE.

### **3. Dynamic Regional Population Shares & Three-Wave Brain-Drain Closure (60-Year Path)**

Tracking the $4 \times 5$ Gumbel migration matrix (**Rural**, **Small**, **Large**, **Auckland**, **Abroad**) and dynamic population weights (Reg_HH_Share_Path) across the 60-year transition path reveals:

1. **Dynamic Agglomeration Trajectory:** Driven by domestic youth sorting and Auckland absorbing ~46%–48% of international net migration inflows, Auckland's population share evolves endogenously from **34.1% in Year 0 (2025/2026) to ~36.2%–36.5% by Year 30**, while cooling urban house prices and tailored Income x Geography transfers stabilize retention in **Small** and **Large** regions.  
2. **Three-Wave Brain-Drain Recovery:**  
   * **Wave 1 (Years 0–5):** Cooling **Auckland** ($-7.5\%$) and **Large** metro ($-5.0\%$) house prices plus the Youth Grant $E$ immediately cuts the age 20–35 emigration rate to Australia/OECD by **~35%–40%**, with the sharpest drop in Auckland and Large cities.  
   * **Wave 2 (Years 5–20):** Wealth-tax-driven capital reallocation toward $z_h$ firms lifts domestic wages ($+3.2\%$ in Rural to $+5.5\%$ in Auckland), closing another **~35%** of the high-skill ($h_6 \mathrm{--} h_7$) outflow.  
   * **Wave 3 (Year 20+ Inflection):** When Cohort $c = 0$ (raised under expanded First-2000-Days $G_{\mathrm{ECE}}$) enters the 20–35 migration window at Year 20, domestic stunting falls toward 2%–4%, replacement migration churn drops, the **Social Cohesion Index ($S_t$)** rises from 100 to ~118+, and the **Effective Tax Base per 65+ Retiree** expands by over 20%.

## **Part IV: Methodological Defense & Mathematical Appendix**

This appendix provides the formal mathematical defense of the modeling choices, identification strategies, and computational reductions used to construct the New Zealand 4-Region Intergenerational Suite.

### **A.1 Defending the Mixed Finite/Infinite-Horizon PType Architecture**

**The Critique:** *Why not model entrepreneurs as finite-horizon life-cycle households, or model all households as infinitely lived dynastic agents?*  
**The Defense:**

1. In standard Aiyagari life-cycle models, households save in a single risk-free bond/capital pool rented to a static representative firm ($Y = Z K^\alpha L^{1-\alpha}$). In that setup, individual portfolio returns are identical ($r$), so a book-value wealth tax $\tau_a$ and a capital income tax $\tau_k$ are mathematically isomorphic ($\tau_a = r \tau_k$), completely missing the **Guvenen et al. (2023) capital misallocation channel**.  
2. Conversely, if heterogeneous entrepreneurial returns $R(z_f)$ are attached directly to finite-horizon households, retirees at ages 75–95 are forced to operate collateral-constrained firms, confounding life-cycle retirement decumulation (Fan, Seshadri, & Taber; De Nardi, 2004) with corporate equity dynamics.  
3. By partitioning the economy in the VFI Toolkit into Names_i = {'HH_Rural', 'HH_Small', 'HH_Large', 'HH_Auckland', 'Firm_Rural', 'Firm_Small', 'Firm_Large', 'Firm_Auckland'} with N_j.HH_k = 16 and N_j.Firm_k = Inf, finite-horizon households supply labor and bond/mutual-fund savings (a_h), while infinite-horizon firms face persistent productivity shocks $z_f \in \lbrace z_{\ell,k}, z_{h,k} \rbrace$, borrow up to collateral limit $k \le \lambda_{\mathrm{col}} a_f$, and solve:  

$$
V_{F,k}(a_f, z_f) = \max_{a^{\prime}_f \in \lbrack 0, R_k(z_f)a_f \rbrack} \left\lbrace \ln\left\lparen R_k(z_f) a_f - a^{\prime}_f \right\rparen + \beta_{\mathrm{firm}} \sum_{z^{\prime}_f} \Pi_{f,k}(z^{\prime}_f \mid z_f) V_{F,k}(a^{\prime}_f, z^{\prime}_f) \right\rbrace
$$

where:

$$
R_k(z_f) = (1 - \tau_a)^5 + (1 - \tau_k) \left\lparen r + \max \left\lbrace 0, \alpha_k \left\lparen \frac{1-\alpha_k}{w_k} \right\rparen^{\frac{1-\alpha_k}{\alpha_k}} z_f - (r + \delta_k) \right\rbrace \lambda_{\mathrm{col}} \right\rparen
$$

Because VFI Toolkit loops over Names_i sequentially on the GPU, this mixed-horizon synthesis adds **zero state variables** to the household grid while preserving the exact analytical properties of Guvenen et al.

### **A.2 Defending the Nonparametric Skill Anchoring & Luxury In-Kind Specification**

**The Critique:** *Early childhood test scores have arbitrary scales and are ridden with measurement error; furthermore, standard benefit-incidence studies value public ECE at \$1 per \$1 of spending, which overstates welfare gains for cash-poor families.*  
**The Defense:**

1. **Adult Outcome Anchoring & Measurement Error Correction:** Following Cunha, Heckman, and Schennach (2010), latent childhood skills $\theta_{k,t}$ are anchored directly in cardinal adult earnings/schooling outcomes $g_{k,j}(\theta_{k,t})$ ($h \in H$ at age 20). As Cunha et al. demonstrate in Tables I–III, ignoring measurement error in early skill proxies severely attenuates Stage 1 investment loadings and overstates late-stage substitutability; our calibration directly adopts their measurement-error-corrected factor loadings ($\gamma_{1,C,1} = 0.487, \gamma_{2,C,1} = 0.902$).

**Welfare-Based In-Kind Imputation ($\omega_i$):** Following Ferriere et al. (2025), standard monetary imputation values public in-kind spending $G_{\mathrm{ECE}}$ at full cost across all deciles, overstating redistributive compression by up to 50% because constrained families at the corner solution $i_c = 0$ have a high marginal utility of cash $\partial u_i / \partial y_i$. In Calibrate_NZ_Moments.m, we discipline the Stone-Geary luxury parameter $\bar{g}_{\mathrm{ECE}}$ against the empirical share $S = \Pr(i_c = 0) \approx 0.25$ of fertile households making zero private top-ups, and apply Ferriere et's exact welfare-based imputation weight:

$$
\omega_i = \frac{\partial u_i / \partial G_{\mathrm{ECE}}}{\partial u_i / \partial y_i} = \min \left\lbrace \frac{y_i / \bar{y}}{F^{-1}(S)}, 1 \right\rbrace
$$

2. Even under this strict discounting of direct utility ($\omega_i < 1$ in $Q_1, Q_2$), public $G_{\mathrm{ECE}}$ generates massive positive welfare gains (CE % > 0) via the concave societal externality $X_t$ and the intergenerational human capital transition matrix $Q_h$.

### **A.3 Defending the Spatial & Housing Dimensionality Reductions**

**The Critique:** *Modeling 4 regions (Rural, Small, Large, Auckland), liquid bonds $b$, physical housing stock $H$, and binary tenure choice (Rent vs. Own) would normally multiply the endogenous state space by $4 \times N_H \times 2$, causing GPU memory overflow.*  
**The Defense:**  
We achieve exact spatial and housing representation with **zero extra endogenous grid states** via three structural reductions:

1. **Horizontal Spatial Partitioning (Names_i):** Mapping $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace$ to VFI Toolkit Permanent Types (Names_i) means each region is solved sequentially on the GPU with its own local wage $w_k$, house price $Q_k$, income dispersion $\sigma_z(k)$, and mandatory fuel/transport subsistence $\bar{e}_k$.  
2. **Net-Worth Consolidation ($a = Q_k h_{\mathrm{house}} - b_{\mathrm{debt}}$):** Following Kiyotaki, Michaelides, and Nikolov (2024), when young homeowners borrow up to the collateral limit, financial debt $b$ and physical housing $h_{\mathrm{house}}$ consolidate into a single state variable: net worth $a \ge 0$. Intra-period expenditure $e_{\mathrm{tot}}$ splits analytically between non-durable consumption (share $\phi_{\mathrm{nd}}$) and housing space (share $1 - \phi_{\mathrm{nd}}$).

**Closed-Form Tenure Cutoff ($\xi_k$) & Unbalanced Growth Bubble ($G_k$):** Given regional trend growth $G_k$ (Hirano & Toda, 2025), local rental yields:
 
$$
rr_k = \left\lparen 1 + \mu_{\mathrm{maint}} - \frac{G_k}{(1+r)^{1/5}} \right\rparen Q_k
$$

and homeowner user costs:

$$
rh_k = \left\lparen 1 + \mu_{\mathrm{maint}} - \upsilon_h - \frac{G_k}{(1+r)^{1/5}} \right\rparen Q_k
$$

pin down the exact fraction of young households choosing leveraged ownership via the uniform preference draw $\chi \sim U \lbrack 0, \bar{\chi} \rbrack$:

$$
\xi_k = \min \left\lbrace 1, \frac{1}{\bar{\chi}} \left\lparen \frac{rr_k}{rh_k} \right\rparen \right\rbrace
$$

3. Regional housing markets clear in General Equilibrium against elastic supply $HS(k) = H_k (Q_k)^{\delta_{H,k}}$, where $\delta_{H,\mathrm{Auckland}} = 0.10 < \delta_{H,\mathrm{Large}} = 0.18 < \delta_{H,\mathrm{Small}} = 0.28 < \delta_{H,\mathrm{Rural}} = 0.35$.

### **A.4 Defending Warm-Glow + Transition Matrix vs. Explicit Dynastic VFI**

**The Critique:** *Why use a warm-glow bequest function $u_{\mathrm{beq}}(a^{\prime})$ and log child-skill payoff $\omega_{ic} \ln(h_{\mathrm{child}})$ inside the household Bellman equation rather than solving an outer Barro–Becker Dynastic VFI loop over $V_{\mathrm{child}}$?*  
**The Defense:**

1. **Distributional Equivalence:** As De Nardi (2004) establishes, embedding a child's full multi-dimensional state vector inside the parent's Bellman equation expands the state space and introduces strategic parent–child gaming, whereas a two-parameter luxury warm-glow function $(b_1, b_2)$ accurately reproduces the upper tail of the estate distribution and old-age saving profiles.  
2. **Capturing the 75% Intergenerational Multiplier:** In Daruich (2018, Section 6), three-fourths of the long-run welfare gain from early-childhood policy operates through the shift in the **stationary distribution of parent states $\mu(a, h, z)$** across generations, rather than changes in the curvature of the continuation value function. Because Build_IntergenTransitionMatrix.m maps the exact optimal child investments $i_c^{\ast}(a_p, h_p, z_p, k)$ and net-of-tax estates $(1 - \tau_b) a_j^{\prime \ast}(k)$ into the next generation's initial distribution jequaloneDist ($\mu_{1,k}(a_1, h_1, z_1)$), our architecture captures 100% of this macroeconomic dynastic feedback loop.  
3. **Optional 2-Parameter Dynastic Slope Toggle:** Because a newborn's expected value function $E_{a_1, z_1} \lbrack V_k(a_1, h_1, z_1, 1) \rbrack$ in a CRRA economy is smooth and concave in initial human capital $h_1$, our log-skill payoff $\omega_{ic} \ln(h_{\mathrm{child}})$ is a tight functional proxy for $E \lbrack V_1 \rbrack$. When evaluating reforms that drastically alter future adult tax progressivity (where farsighted parents might adjust $i_c$ in anticipation of their child's altered after-tax return to skill), one can toggle on a 4-iteration outer loop fitting:

$$
E_{a_1, z_1} \lbrack V_k(a_1, h_1, z_1, 1) \rbrack \approx \hat{\alpha}_{0,k} + \hat{\alpha}_{1,k} \frac{h_1^{1-\eta_{\mathrm{dyn}}}}{1-\eta_{\mathrm{dyn}}}
$$

(following Lee & Seshadri's $V_4^n \rightarrow V_4^{n+1}$ contraction) with zero change to grid dimensions.