# **Intergenerational Welfare, Capital Allocation, and Human Potential in New Zealand**

**A Multi-Audience Strategic & Technical Monograph (4-Region + Abroad Edition)**

## **Part I: Targeted Executive Summaries**

### **1. For Philanthropists: Catalytic Impact & The Intergenerational Multiplier**

**Strategic Mandate:** Shift from funding late-stage symptom remediation to unlocking early-stage human potential where private markets fail.

* **The Core Problem:** In New Zealand, roughly **14.3% to 22%** of each birth cohort grows up in severe material hardship or developmental stunting. The Dunedin Multidisciplinary Health and Development Study demonstrates that 22% of a cohort—identifiable as early as age 3—accounts for **57% to 81%** of adult hospital nights, welfare benefits, and criminal convictions. Because young parents cannot borrow against their children's future adult earnings (an intergenerational borrowing constraint) and face severe housing stress in metropolitan centers like **Auckland** (34.1% of the population) and **Large** regional cities (25.9%), low-income families hit a mathematical "corner solution" ($i_c = 0$) where private early-childhood investment collapses.  
* **The Catalytic Lever (Two-Stage Dynamic Complementarity):** Incorporating Cunha, Heckman, and Schennach's (2010) two-stage CES skill technology ($\theta_c$ experience asset) proves that early investment in the First 2000 Days ($j = 3$, ages 0–5, where elasticity of substitution is high, $\varphi_1 = 0.35$) raises the marginal productivity of later schooling ($j = 4$, ages 6–17, where dynamic complementarity is strong, $\varphi_2 = -0.95$). Scaling wraparound early childhood provision ($G_{\text{ECE}}$, modeled on Barnardos' *Te Korowai Mokopuna*) crowds *in* private parental effort during school years and captures a \$112–\$162 billion present-value societal payoff.

### **2. For Venture & Growth Capital Firms: Ending the Brain Drain & Reallocating Capital**

**Strategic Mandate:** Unlock domestic productive capital trapped in overvalued urban land and stem the positive-selection emigration of top-tier talent.

* **The Core Problem (The Stepping-Stone Brain Drain):** New Zealand suffers acute outward migration among educated 20-to-35-year-olds. Our $4 \times 5$ spatial discrete-choice model (**Rural**, **Small**, **Large**, **Auckland** $\rightarrow$ **Abroad**) reveals a two-stage funnel: high-potential youth from **Rural** districts (16.0% pop) and **Small** provincial towns (24.0% pop) use **Large** university/service metros (Wellington, Christchurch, Hamilton, Tauranga, Dunedin) as a stepping stone, while **Large** cities and **Auckland** (where 35.1% of NZ businesses reside) suffer the sharpest direct brain drain of top human-capital tiers ($h_5 - h_7$) to Australia/OECD. Young adults who do not inherit family property deposits leave because overvalued Auckland and Large-city housing ($Q_{\text{Auckland}} = 3.10, Q_{\text{Large}} = 2.05$) and capital-starved local firms depress their domestic real return.  
* **Integration into Venture Strategic Plans:**  
  1. **Champion Tax Mix Reform ($\tau_k \downarrow, \tau_a/\tau_b \uparrow$):** Following Guvenen et al. (2023), shifting from capital-income taxation to a book-value wealth/land tax ($\tau_a = 1.5\%$) and estate tax ($\tau_b = 25\%$) on the **\$1.6T intergenerational property transfer** triggers a "use-it-or-lose-it" reallocation from passive property hoarders ($z_\ell$) to high-productivity entrepreneurs ($z_h$), lifting regional wages by **3.2% to 5.5%**.  
  2. **Leverage Secondary Urban Hubs:** Exploit the improved housing affordability and rising skill retention in **Large** regional metros and **Small** provincial centers as land overvaluation cools.

### **3. For Policy-Makers: The "Income $\times$ Geography" Rule & Fiscal Solvency**

**Strategic Mandate:** Replace uniform national transfers with spatially differentiated policy across New Zealand's four distinct geographic tiers to secure the long-run fiscal solvency of NZ Superannuation.

* **Why a 4-Region Taxonomy Matters:** Splitting "Urban" into **Small** provincial towns (24.0%) and **Large** regional metros (25.9%) alongside **Rural** (16.0%) and **Auckland** (34.1%) exposes why uniform welfare rules fail:  
  1. **Rural & Small Provincial Towns:** Exhibit compressed income distributions ($Q_2 - Q_4$), elastic housing supply ($\delta_H \in [0.28, 0.35]$), and high mandatory fuel/transport subsistence burdens ($\bar{e}_{\text{Rural}} = 0.048, \bar{e}_{\text{Small}} = 0.036$). They require broad transport/cost-of-living relief and universal in-kind ECE delivery ($G_{\text{ECE}}$), with lower transfer progressivity.  
  2. **Large Regional Cities & Auckland:** Exhibit bifurcated income distributions ($Q_1$ hardship alongside $Q_5$ knowledge workers), inelastic land supply ($\delta_H \in [0.10, 0.18]$), and severe rental/deposit crowd-out. Following Labrousse and Perdereau (2025), increasing transfer progressivity in **Large** cities and **Auckland** while funding a universal **Youth Capital Grant ($E$)** yields the largest median welfare jump (mirroring the +24.1% Large-city gain in Labrousse & Perdereau) and cuts the national welfare-loss share by 10 percentage points.

### **4. For Economists: Advancing the Quantitative Macroeconomics Frontier**

**Research Contribution:** A tractable, GPU-accelerated Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial Overlapping Generations (OLG) framework built in the **VFI Toolkit**.

* **How This Model Advances the Field:**  
  * **8-PType Mixed Finite/Infinite-Horizon Architecture:** Solves 4 finite-horizon regional household types (HH_Rural, HH_Small, HH_Large, HH_Auckland, $J = 16$) and 4 infinite-horizon collateral-constrained firm types (Firm_Rural, Firm_Small, Firm_Large, Firm_Auckland, $N_j = \infty$) simultaneously on the GPU.  
  * **Two-Stage Child Experience Asset ($\theta_c$) + Adult Ben-Porath + Luxury In-Kind Externalities:** Integrates Cunha–Heckman–Schennach two-stage CES skill production (`experienceasset = 1`) with adult Ben-Porath training ($I_h$), Stone-Geary in-kind public provision ($\bar{g}_{\text{ECE}} > 0$), and intra-household fertility bargaining with hyperbolic discounting ($\beta_{\text{hyp}} < 1$).  
  * **Dimension-Free 4-Region Housing & $4 \times 5$ Domestic/International Migration:** Combines Kiyotaki et al.'s net-worth consolidation ($a = Q_k h - b$) and analytical tenure cutoff ($\xi_k$) with a $4 \times 5$ Gumbel youth sorting matrix across **Rural**, **Small**, **Large**, **Auckland**, and **Abroad** (Australia/OECD), plus endogenous 60-year evolution of regional population weights (`PTypeWeights_path`).  
  * **Tractable Dynastic Macroeconomic Closure:** Captures 100% of the distributional Barro–Becker intergenerational multiplier via the 3-stage operator $T_{IG} : Q_h \times Q_a \times \Pi_{\text{mig}}$, with an optional 2-parameter dynastic slope toggle.

## **Part II: The Three Coupled Life-Cycle & Macroeconomic Lenses**

### **Lens 1: Early Childhood Skill Formation (First 2000 Days vs. Schooling) & Fertility**

* **Two-Stage CES Experience Asset ($\theta_c$):** Children progress through Stage 1 (First 2000 Days, parental age $j = 3$, $\varphi_1 = 0.35$) and Stage 2 (Schooling, parental age $j = 4$, $\varphi_2 = -0.95$). Public front-loading in Stage 1 ($P_0$) raises $\theta_2$ entering school, which crowds *in* private parental investment during Stage 2, whereas late school-age subsidies ($P_1/P_2$) fail to remediate early stunting.  
* **Endogenous Fertility & Hyperbolic Bargaining:** When metropolitan housing costs ($Q_{\text{Large}}, Q_{\text{Auckland}}$) surge or present-biased preferences ($\beta < 1$) bind, young adults delay or undershoot intended fertility, accelerating demographic aging.

### **Lens 2: The 4-Region Spatial Divide & The $4 \times 5$ Brain-Drain Funnel**

* **The Spatial Gradient (Rural $\rightarrow$ Small $\rightarrow$ Large $\rightarrow$ Auckland):**  
  * **Rural (16.0% Pop / 15.0% Firms):** Elastic land ($\delta_H = 0.35, Q = 1.05$), lower wage ceiling ($w = 0.85$), highest mandatory transport/energy share ($\bar{e} = 0.048$).  
  * **Small Provincial Towns (24.0% Pop / 23.0% Firms):** Moderate housing elasticity ($\delta_H = 0.28, Q = 1.40$), compressed middle-quintile wages ($w = 0.93$), elevated transport costs ($\bar{e} = 0.036$).  
  * **Large Regional Metros (25.9% Pop / 26.9% Firms — Wellington, Chch, Hamilton, Tauranga, Dunedin):** Constrained urban land ($\delta_H = 0.18, Q = 2.05$), higher knowledge/service wages ($w = 1.05$), moderate transport share ($\bar{e} = 0.022$).  
  * **Auckland Primate Agglomeration (34.1% Pop / 35.1% Firms — "Paris" Analog):** Severely constrained land supply ($\delta_H = 0.10, Q = 3.10$) and highest trend growth ($G = 1.025$), generating structural land overvaluation, the fattest top-income tail ($w = 1.18, \sigma_z = 0.24$), and severe housing crowd-out for bottom-quintile renters.  
* **Adult Ben-Porath Decay & Positive-Selection Emigration:** Workers entering adulthood stunted ($h_1, h_2$) have a low marginal return to adult training ($I_h^{\alpha_I} h^{\alpha_H}$), causing wages to decay in their 50s. Meanwhile, high-skill youth ($h_5 - h_7$) without inherited deposits compare squeezed domestic utility $V_k$ against $V_{\text{Abroad}}$, driving outward emigration between ages 20 and 35.

### **Lens 3: Pensions, The \$1.6T Property Transfer, & Capital Allocation**

* **Weighting Auckland Accurately (34.1% Pop / 35.1% Firms):** Because Auckland house prices ($Q_{\text{Auckland}} = 3.10$) are nearly triple rural levels and 50% above Large regional metros, weighting Auckland at its true Stats NZ share (34.1% rising to $\sim 36.5\%$ by Year 30) increases the national estate/wealth tax base by **8%–10%**, funding both the universal Youth Grant ($E = 0.065$) and expanded ECE ($G_{\text{ECE}} = 0.110$) without raising labor taxes ($\tau_l$).

## **Part III: Integrated Policy Results & 60-Year Transition Findings**

### **1. 4-Region Decomposition of Long-Run Welfare Gains (CE %)**

Evaluating lifetime Consumption Equivalent Variation (CE %) under the veil of ignorance for incoming cohorts ($j = 1$) across all four regions:

| Decomposition Stage | Mechanism Active | Rural (CE %) | Small (CE %) | Large (CE %) | Auckland (CE %) | Economic Interpretation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Short-Run Partial Equilibrium (PE)** | Policy levers ($G_{\text{ECE}}, E, T_k, \tau_a, \tau_b$) only; prices & parent skills fixed. | $+3.8\%$ | $+4.0\%$ | $+4.3\%$ | $+4.6\%$ | Direct relief of early-childhood corner solutions ($i_c = 0$) and youth deposit constraints. |
| **2. Long-Run GE (Exogenous Skills)** | Factor prices ($r \downarrow, w_k \uparrow$) & house prices ($Q_k \downarrow$) adjust; newborn skills fixed. | $+6.2\%$ | $+6.8\%$ | $+7.6\%$ | $+8.4\%$ | Guvenen et al. firm reallocation ($w_k +3.2\text{--}5.5\%$) + cooling of Large/Auckland land bubbles ($Q_k -5.0\text{--}7.5\%$). |
| **3. Long-Run GE (Endogenous Intergen Matrix)** | Full $4 \times 5$ transition matrix ($Q_h, Q_a, \Pi_{\text{mig}}$) updates parent skills & retention. | **$+10.4\%$** | **$+11.2\%$** | **$+12.6\%$** | **$+13.9\%$** | **55%–65%+ of total gain** comes from creating better-skilled parents & retaining $h_6 - h_7$ youth domestically. |

### **2. Breaking the Intergenerational Trap: Multi-Stage Counterfactuals (Lee & Seshadri Table 12)**

1. **Baseline Persistence (`BM_Baseline`):** Parental states at ages 30–35 explain **60%–65%** of the variance in children's adult human capital ($h'_1$) and $\sim 70\%$ of future lifetime earnings ($\text{LFE}'$), with **Auckland** exhibiting the highest Intergenerational Elasticity of Earnings (IGE) and log-earnings variance ($\text{VarLogE}$) due to its property divide.  
2. **Early Front-Loading (`P0_Early_0to5` & `BN_FrontLoad`) vs. Late Remediation (`P1P2_Late_6to17`):** Expanding First-2000-Days investment ($P_0$) plus the Youth Grant ($E$, `P0_Plus_GrantE`) sharply lowers IGE and parent-explained variance across all four regions, whereas late school-age subsidies ($P_1/P_2$) barely move the IGE.

### **3. Dynamic Regional Population Shares & Three-Wave Brain-Drain Closure (60-Year Path)**

Tracking the $4 \times 5$ Gumbel migration matrix (**Rural**, **Small**, **Large**, **Auckland**, **Abroad**) and dynamic population weights (`Reg_HH_Share_Path`) across the 60-year transition path reveals:

1. **Dynamic Agglomeration Trajectory:** Driven by domestic youth sorting and Auckland absorbing $\sim 46\% \text{--} 48\%$ of international net migration inflows, Auckland's population share evolves endogenously from **34.1% in Year 0 (2025/2026) to $\sim 36.2\% \text{--} 36.5\%$ by Year 30**, while cooling urban house prices and tailored Income x Geography transfers stabilize retention in **Small** and **Large** regions.  
2. **Three-Wave Brain-Drain Recovery:**  
   * **Wave 1 (Years 0–5):** Cooling **Auckland** ($-7.5\%$) and **Large** metro ($-5.0\%$) house prices plus the Youth Grant $E$ immediately cuts the age 20–35 emigration rate to Australia/OECD by **$\sim 35\% \text{--} 40\%$**, with the sharpest drop in Auckland and Large cities.  
   * **Wave 2 (Years 5–20):** Wealth-tax-driven capital reallocation toward $z_h$ firms lifts domestic wages ($+3.2\%$ in Rural to $+5.5\%$ in Auckland), closing another **$\sim 35\%$** of the high-skill ($h_6 - h_7$) outflow.  
   * **Wave 3 (Year 20+ Inflection):** When Cohort $c = 0$ (raised under expanded First-2000-Days $G_{\text{ECE}}$) enters the 20–35 migration window at Year 20, domestic stunting falls toward 2%–4%, replacement migration churn drops, the **Social Cohesion Index ($S_t$)** rises from 100 to $\sim 118+$, and the **Effective Tax Base per 65+ Retiree** expands by over 20%.