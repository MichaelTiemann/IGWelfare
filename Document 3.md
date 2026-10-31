# Document 3: Leaving Our Silos, Lifting All Boats
## Dynamic Complementarity, Coalition Architecture, and Why Single-Lane Policy Fails Against the Fiscal Sinkhole

*Author:* Michael Tiemann (mdtiemann@gmail.com)  
*Date:* November 2026 | *Code & Replication Repository:* [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)  
*Companion to [Document 1A](Document%201A.md) (Strategic Monograph), [Document 1B](Document%201B.md) (Strategy & Policy Answer Key), [Document 1C](Document%201C.md) (Executive Brief), and [Document 2](Document%202.md) (Technical Specification Guide)*

---

## Executive Overview: Why Single-Lane Advocacy Loses in a Sinking Room

In Aotearoa New Zealand, our most dedicated policy advocates, business leaders, community trusts, and fiscal stewards spend vast energy competing for space in the annual Budget. Each constituency stays largely in its own lane—defending early childhood education, or housing affordability, or corporate tax competitiveness, or public debt reduction—while treating adjacent portfolios as rival claimants on a fixed fiscal pie.

That single-lane habit rests on two hidden assumptions, and our quantitative overlapping-generations (OLG) model proves that **both assumptions are false**:

1. **The Myth of the Flat Baseline ($SS0 \neq 0\%$):** Conventional policy analysis evaluates individual budget bids against a static status quo ($SS0 = 0.0\%$ welfare change). Yet as the New Zealand Treasury’s *Long-term Fiscal Statement (He Tirohanga Mokopuna 2025)* and 2026 background papers (*Analytical Note 26/01* and *Working Paper 26/01*) establish, New Zealand's status quo is not a flat floor. It is a **multi-decade fiscal and demographic sinkhole** in which an aging population, unmitigated child skill stunting (22.0%), youth emigration (10.9% nationally and 19.3%–23.4% from major cities), and compounding sovereign debt service ($r_t d_t$) drag net core Crown debt toward **185%–200% of GDP** and push the required working-age PAYE tax rate from **22.0% toward 28.2%**. Along that trajectory, baseline household welfare erodes by **-12.4% in Consumption-Equivalent (CE%) terms**. Worse still, if geopolitical pressures require lifting New Zealand's defense spending from its status-quo ~0.75% of GDP to a 3.0%-of-GDP alliance standard (~+NZD 10.0B/yr in deadweight fiscal load with a 0x domestic skill multiplier), the sinking cost sheet swamps every isolated reform and drags household welfare down to **-19.3% CE**.
2. **The Myth of Additive Independence (47.4% of the Prize Lives Between the Lanes):** Even in an imaginary world without fiscal drift, implementing our seven core policy levers in isolation—without cross-sector coupling—delivers only **+12.43% CE** nationally. When those exact same levers are engineered as a coupled system across the human lifecycle, they unlock **+11.20% CE in supermodular Dynamic Complementarity Wedges**—accounting for **47.4% of the entire +23.63% CE long-run national welfare gain** (+15.65% in Rural, +20.63% in Small towns, +23.59% in Large regional cities, and +29.53% in Auckland).

Just as our spatial Gumbel migration operator ($\Pi_{\mathrm{mig}}$) captures how households naturally prefer to stay in their home region (`Rural <-> Small <-> Large <-> Auckland`) unless the cross-regional utility gain clears a switching threshold, this document introduces a **2D Motivational & Dependency Matrix** across New Zealand's four primary policy constituencies. We show how each constituency fares when fighting alone against the LTFM sinkhole, why trying to "solve debt first" via Phase-1 austerity backfires mathematically, and how uniting the four lanes gets Aotearoa up on hydrofoils—creating an economy strong enough to retire sovereign debt, cut working-age PAYE taxes to **18.88%**, and lower the New Zealand Superannuation eligibility age to **64** in Phase 2 ($SS2$).

---

## Part I: The 2D Coalition Transition Matrix — Why Every Siloed Constituency Needs Its Neighbors

### 1.1 From Geographic Sorting ($4 \times 5$) to Policy Coalition Sorting ($4 \times 4$)

In [Document 2](Document%202.md) (Section 4.3), young adults launching into adulthood at Age 20 ($j=1$) evaluate a $4 \times 5$ transition matrix across four domestic regional tiers (`Rural`, `Small`, `Large`, `Auckland`) and a fifth outside option (`Abroad` to Australia and the wider OECD). High diagonal stay-rates reflect attachment to home and *whānau*, while off-diagonal flows measure movement triggered when housing costs or career ceilings make staying untenable.

New Zealand’s political economy operates on an isomorphic **$4 \times 4$ Motivational Matrix**. Four great policy tribes each champion a vital subset of our **11-Layer Constructive Synergy Stack** (7 Isolated Factors + 4 Named Dynamic Complementarity Wedges, audited in `Table19_Constructive_Synergy_Wedges_Dunedin_22.csv` and [Fig_Counterfactual_8Scenarios_SS1_SS2_Dunedin_22.png](Output_NZ_4Region_Intergen/Fig_Counterfactual_8Scenarios_SS1_SS2_Dunedin_22.png)):

1. **Coalition 1 — The Barnardos, Iwi & Youth Development Constituency (*The Human Potential Lane*):** Champions **Layer 1** (Universal First-2,000-Days wraparound ECE, $G_{\mathrm{ece},1}$) and **Layer 2** (*Tuakana-Teina*, *Kura*, Graeme Dingle Foundation *Stars / Project K*, and Montessori adolescent mentoring at ages 12–14, $G_{\mathrm{ece},2}$).
2. **Coalition 2 — The WellBeing & Housing Justice Alliance (*The Fair Start & Whānau Space Lane*):** Champions **Layer 4 (Household/Land side)** (Cooling speculative urban housing $Q_k$ via property/estate tax rebalancing $\tau_a, \tau_b$), **Layer 5** (the universal Age-20 Youth Capital Grant $E$), and **Layer 6** (the *Income $\times$ Geography* household transfer $T_k$).
3. **Coalition 3 — The GrowthNZ, Founders & Venture Constituency (*The "Where Will the Jobs Come From?" Lane*):** Champions **Layer 4 (Enterprise side)** ("Use-it-or-lose-it" capital reallocation from passive land $z_{\ell}$ to high-productivity operating firms $z_h$ and a 1.65x public infrastructure reinvestment pool) and **Layer 8** (skilled talent retention and agglomeration).
4. **Coalition 4 — The Fiscal Hawks & Sovereign Credit Guardians (*The Balance-Sheet & Tax-Relief Lane*):** Champions **Layer 9** (Sovereign Debt-Sinking $\Omega_{\mathrm{debt}}$ and -60 bps interest rate relief) and **Layer 10** (Working-age PAYE tax cuts $\Delta \tau_l$ and long-run NZ Superannuation solvency).

---

### 1.2 Constructive Attribution: Isolated Factors vs. Dynamic Complementarity Wedges

Before mapping the $4 \times 4$ interaction matrix between these four coalitions, Table 1.1 presents the constructive build-up from [Fig_Counterfactual_8Scenarios_SS1_SS2_Dunedin_22.png](Output_NZ_4Region_Intergen/Fig_Counterfactual_8Scenarios_SS1_SS2_Dunedin_22.png). Rather than slicing a finished cake after the fact, we evaluate what each policy factor achieves **entirely in isolation** (when implemented alone in our state-contingent VFI engine), and then measure the exact **supermodular synergy wedges** ($\Delta_{\mathrm{syn}}(A, B) \equiv W(A \cup B) - W(A) - W(B) > 0$) unlocked as the stacks join together:

#### Table 1.1: The 11-Layer Constructive Synergy Build-Up (`SS2` Long-Run Welfare Gain, CE%)

| Constructive Tier & Layer (`Table 19`) | Policy Constituency ("Owner Lane") | Rural (+15.65%) | Small (+20.63%) | Large (+23.59%) | Auckland (+29.53%) | National (+23.63%) | Share of National Prize |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. [Isolated] First-2,000-Days Universal ECE Alone** ($G_{\mathrm{ece},1}$) | **Coalition 1** *(Barnardos / Early Years)* | +2.50% | +3.12% | +3.48% | +4.17% | **+3.47%** | 14.7% |
| **2. [Isolated] *Tuakana-Teina* / Montessori Mentoring Alone** ($G_{\mathrm{ece},2}$) | **Coalition 1** *(Youth / Educators)* | +1.50% | +1.86% | +2.07% | +2.49% | **+2.07%** | 8.8% |
| **3. ★ WEDGE 1: Dual-Gate Human Capital Synergy** ($\mathrm{ECE}_1 \times \mathrm{Tuakana}_2$) | **Intra-Coalition 1 Synergy** *(Halts $\delta_{\theta}=0.22$ Fade-Out)* | **+2.10%** | **+2.76%** | **+3.18%** | **+3.97%** | **+3.18%** | **13.5%** |
| *Tier 1 Subtotal (The Dual-Gate Human Capital Stack)* | *Coalition 1 Total (Iso +5.54% + Wedge +3.18%)* | *+6.10%* | *+7.74%* | *+8.73%* | *+10.63%* | ***+8.72%*** | *36.9%* |
| **4. [Isolated] Estate & Property Tax Rebalance Alone** ($\tau_b, \tau_a \to \mathrm{Firm}$) | **Coalitions 2 & 3** *(Housing + GrowthNZ)* | +1.60% | +2.16% | +2.57% | +3.31% | **+2.57%** | 10.9% |
| **5. [Isolated] Age-20 Youth Capital Grant Alone** ($E$) | **Coalition 2** *(WellBeing / Youth Start)* | +0.90% | +1.16% | +1.31% | +1.58% | **+1.30%** | 5.5% |
| **6. [Isolated] Income $\times$ Geography Transfer Alone** ($T_k$) | **Coalition 2** *(WellBeing / Regional)* | +1.15% | +1.11% | +1.01% | +1.02% | **+1.06%** | 4.5% |
| **7. ★ WEDGE 2: LVR-Clearance & *Whānau*-Anchoring Synergy** | **Coalition 2 $\times$ 3 Synergy** ($\mathrm{TaxRebal} \times E \times T_k$) | **+1.35%** | **+1.86%** | **+2.22%** | **+2.90%** | **+2.23%** | **9.4%** |
| *Tier 2 Subtotal (The Spatial, LVR & Enterprise Stack)* | *Coalitions 2 & 3 (Iso +4.93% + Wedge +2.23%)* | *+5.00%* | *+6.29%* | *+7.11%* | *+8.81%* | ***+7.15%*** | *30.3%* |
| **8. ★ WEDGE 3: Cross-Stack Synergy ($\mathrm{Stack\ 1} \times \mathrm{Stack\ 2}$)** | **Coalitions 1 $\times$ 2 $\times$ 3** *(Brain-Drain Reversal + *Kaiako* Supply + Firm Skill Match)* | **+2.15%** | **+3.12%** | **+3.89%** | **+5.19%** | **+3.87%** | **16.4%** |
| **9. [Isolated] Sovereign Debt-Sinking & Interest Relief Alone** ($\Delta r = -60\text{ bps}$) | **Coalition 4** *(Fiscal Hawks / MBAs)* | +0.55% | +0.70% | +0.81% | +0.97% | **+0.79%** | 3.3% |
| **10. [Isolated] PAYE Cut (-3.12 pp to 18.9%) & Super Age-64 *Kuia* Dividend Alone** | **Coalition 4 $\times$ 2** *(Taxpayers & Retirees)* | +0.90% | +1.06% | +1.16% | +1.37% | **+1.17%** | 5.0% |
| **11. ★ WEDGE 4: Actuarial Solvency, Replacement TFR & 2nd-Gen Closure** | **All 4 Coalitions** *(Self-Financing Fiscal & Dynastic Loop)* | **+0.95%** | **+1.73%** | **+1.89%** | **+2.57%** | **+1.93%** | **8.2%** |
| *Tier 4 Subtotal (The Fiscal, Super-64 & Demographic Harvest Stack)* | *Coalition 4 + Full Loop (Iso +1.96% + Wedge +1.93%)* | *+2.40%* | *+3.49%* | *+3.86%* | *+4.91%* | ***+3.89%*** | *16.5%* |
| **GRAND TOTAL (`SS2_3` Fully Integrated Policy)** | **7 Isolated (+12.43%, 52.6%) + 4 Wedges (+11.20%, 47.4%)** | **+15.65%** | **+20.63%** | **+23.59%** | **+29.53%** | **+23.63%** | **100.0%** |

---

### 1.3 Anatomy of the Four Single-Lane Silos (And How Each Fails Without Adjacent Lanes)

Look closely at what Table 1.1 and our $4 \times 4$ Coalition Complementarity Matrix (`Table22_Doc3_2D_Coalition_Complementarity_Matrix_Dunedin_22.csv`) reveal about each of the four constituencies when they operate inside their own silo:

#### 1. The Barnardos & Youth Silo (*"Invest in the First 2,000 Days and Adolescent Mentoring"*):
* **What They Achieve Alone:** Universal First-2,000-Days wraparound ($G_{\mathrm{ece},1}$) alone delivers **+3.47% CE** (billions of dollars in new lifetime welfare). Why isn't it higher on its own? Because in our state-contingent child skill law of motion ($\theta_{c,\mathrm{ret}} = \theta_c - \delta_{\theta,\mathrm{fade}}(1 - M_{\mathrm{mentor}})\max(0, \theta_c - \theta_{\mathrm{base}})$), unbanked early-childhood skill gains suffer a **22% adolescent fade-out rate** ($\delta_{\theta,\mathrm{fade}} = 0.22$) when families hit an unbuffered unemployment or housing shock at ages 12–14, and run into Cunha and Heckman's harmonic-mean Stage-2 bottleneck ($\varphi_2 = -0.95 < 0$, elasticity of substitution $\sigma_2 = 0.51 < 1$).
* **The Intra-Silo Double (Wedge 1 = +3.18% CE):** When early-years advocates join forces with adolescent *Tuakana-Teina*, Graeme Dingle Foundation, and Montessori mentoring ($G_{\mathrm{ece},2}$, worth +2.07% alone), they unlock **Wedge 1 (+3.18% CE)**—more than doubling the mentoring gain and lifting Tier 1 to **+8.72% CE** (+10.63% in Auckland).
* **Why They Still Stall Without Lanes 2, 3, and 4:**
  1. *The Cash-Accounting Guillotine (Need for Coalition 4's Actuarial Shield):* On a conventional "wait-as-you-go" cash budget, early-childhood outlays occur in Years 1–5 (NZD 9.19B) while cash tax receipts arrive after Year 18.8. Without **ACC-style Actuarial Continuation Valuation** (booking the 3.84x discounted 25-year fiscal return and 1.16x direct cost avoidance at Year 5), Deficit Hawks cancel or freeze the program in Year 3.
  2. *The Kaiako Rent Bottleneck (Need for Coalition 2's Housing Cooling):* In Auckland ($Q_{\mathrm{Akl}} = 3.10$) and Large cities ($Q_{\mathrm{Large}} = 2.05$), unaffordable rents price early-childhood *Kaiako* and speech therapists out of high-need suburbs via our price-manifold deflator $G_{\mathrm{ece},s}^{\mathrm{eff}}(Q_k) = G_{\mathrm{ece},s} \cdot (Q_{\mathrm{base},k}/Q_k)^{0.35}$.
  3. *Subsidizing Australia's Workforce (Need for Coalition 3's Jobs):* Without domestic firm capital reallocation ($z_h$) and affordable urban housing ($Q_k \downarrow$), **19.3% of Auckland's and 23.4% of Large regional cities' newly thriving $h_6\text{--}h_7$ youth emigrate across the Tasman at Age 20!**

#### 2. The WellBeing & Housing Justice Silo (*"Cool Housing, Seed Youth Capital, and Make Space for Whānau"*):
* **What They Achieve Alone:** Implemented one by one, property/estate tax rebalancing (+2.57%), the Age-20 Youth Capital Grant $E$ (+1.30%), and *Income $\times$ Geography* transfers $T_k$ (+1.06%) sum to **+4.93% CE**. When deployed together as a housing-and-balance-sheet triad, they unlock **Wedge 2 (+2.23% CE)**—because cooling metropolitan land prices ($Q_k \downarrow$) while granting Age-20 seed capital ($E \uparrow$) and relieving regional transport/energy hardship ($T_k \uparrow$) pushes young households across the non-linear **20% LVR mortgage deposit hurdle** ($a \ge 0.20 Q_k$), eliminating the 12% comonotonic eviction/transience penalty and allowing *kuia* and *koroua* to remain anchored in their community homes ($\Delta K_{\mathrm{whanau}} > 0$).
* **Why They Fail Without Lanes 1 and 3:**
  * Look at the standalone Age-20 Youth Capital Grant ($E$ alone = **+1.30% CE**). Why does handing a young adult a capital endowment at Age 20 deliver so little on its own? Because if that young person spent ages 0 to 17 in developmental stunting ($h_1\text{--}h_2$, due to unmitigated childhood hardship or adolescent fade-out), **a lump-sum cash grant at Age 20 cannot retroactively rewire early cognitive and executive-function architecture ($\sigma_2 = 0.51 < 1$)**. In an uncooled housing market without high-skill wage growth, a standalone grant is rapidly capitalized into rents or spent down on subsistence. Only when paired with **Coalition 1** (so 65% of youth arrive at Age 20 in the thriving $h_6\text{--}h_7$ tiers) and **Coalition 3** (so high-productivity $z_h$ enterprises are expanding to hire them) does the Youth Grant ignite **Wedge 3 (+3.87% CE)**.

#### 3. The GrowthNZ & Venture Silo (*"Where Will All the Jobs Come From?"*):
* **What They Achieve Alone:** Growth investors, founders, and business groups rightly point out that social spending alone does not create high-wage jobs. They advocate shifting taxes off corporate reinvestment ($\tau_k \downarrow$), building productive infrastructure ($\mu_{\mathrm{infra}} = 1.65$), and recruiting global talent and capital. Yet in isolation (without domestic child capability or housing reform), enterprise tax and infrastructure levers deliver only **~2.10%–2.57% CE**.
* **Why They Stall Without Lanes 1 and 2:**
  1. *The Domestic Talent Desert:* If 22.0%–28.5% of domestic school-leavers enter adulthood functionally stunted ($h_1\text{--}h_2$) while the brightest local graduates flee to Sydney and Melbourne to escape Auckland's 3.10x rent-to-income squeeze, high-tech $z_h$ firms face a chronic domestic skill bottleneck ($\bar{H}_k$).
  2. *The Lavoisier / Murphy-Shleifer-Vishny Rent-Seeking Trap:* As Murphy, Shleifer, and Vishny (1991) prove, when NZD 1.6 trillion of residential land appreciates tax-free while operating businesses are taxed, New Zealand's sharpest analytical minds are drawn into property speculation, conveyancing, and tax arbitrage rather than founding frontier companies. GrowthNZ **needs** the WellBeing Alliance's land-and-estate rebalance ($\tau_a, \tau_b$) to rotate domestic capital and entrepreneurial talent out of land hoarding ($z_{\ell} \to z_h$), and **needs** Barnardos/Youth to supply a 65%-thriving domestic workforce (**Wedge 3 = +3.87% CE, rising to +5.19% CE in Auckland**).

#### 4. The Fiscal Hawks & MBA Silo (*"Cut Debt and Lower Taxes First"*):
* **What They Achieve Alone:** Fiscally conservative deficit hawks focus almost exclusively on **Layer 9** (Sovereign Debt-Sinking, +0.79% CE alone) and **Layer 10** (Working-age PAYE tax cuts and Superannuation solvency, +1.17% CE alone)—while offering no structural engine to fund or sustain them.
* **The MBA-Without-MPP Paradox:** In corporate turnarounds, an MBA can temporarily improve cash flow by liquidating underperforming divisions. A sovereign nation **cannot** fire its citizens. When fiscal hawks attempt to "solve debt first" in Phase 1 ($SS1$) by cutting early childhood/mentoring outlays or raising the NZ Superannuation age to 67 or 70:
  * They trigger a **38%–45% fiscal substitution leak** as manual and lower-skilled 65–69-year-olds shift onto Supported Living, Jobseeker hardship, and acute hospital care;
  * They trigger a **Sandwich-Generation Care Reversal** ($K_{\mathrm{whanau}}^{\mathrm{net}} < 0$), withdrawing -17% to -36.2% of *kuia* and aunty childcare time from young families, which spikes cohort stunting by +2.5 to +3.5 percentage points; and
  * Within one generation, the resulting erosion of the skilled tax base and surge in acute remediation (Exits 1, 2, 4) **drives required PAYE taxes UP (24.30%–25.99%) and sinks net household welfare to -6.80% CE**!
  * **The Takeaway:** MBAs cannot balance the Crown balance sheet without Master of Public Policy (MPP) human-capital innovations. Sovereign debt reduction and PAYE tax cuts are **Phase 2 ($SS2$) harvests** (**Wedge 4 = +1.93% CE**) earned *after* Phase 1 ($SS1$) closes the remediation drain.

---

### 1.4 Summary Table: The $4 \times 4$ Coalition Dependency Matrix (`Table 22`)

Table 1.2 summarizes the $4 \times 4$ matrix exported by `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m`, showing each constituency's **Own-Lane Diagonal Base** alongside the **six bilateral off-diagonal synergy wedges** that sum identically to **+23.63% CE**:

| Policy Constituency (Row $i$) | 1. Barnardos & Youth *(ECE + Tuakana)* | 2. WellBeing Alliance *(Housing + Grant + Whānau)* | 3. GrowthNZ & Venture *(Firm Capital + Jobs)* | 4. Fiscal Hawks & MBAs *(Debt-Sinking + PAYE Cut)* | **Total Value Connected to Constituency $i$** *(Own Base + 3 Neighbor Wedges)* |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **1. Barnardos & Youth** | **`[OWN SILO 1]`**<br>**+7.52% CE**<br>*(ECE$_1$ + Tuakana$_2$ Base)* | **★ WEDGE (1$\times$2)**<br>**+2.15% CE**<br>*(*Kaiako* Rent Relief + $h_6\text{--}h_7$ Youth Use Grant $E$)* | **★ WEDGE (1$\times$3)**<br>**+1.95% CE**<br>*(High-$z_h$ Jobs Retain $h_6\text{--}h_7$ Youth in NZ!)* | **★ WEDGE (1$\times$4)**<br>**+1.45% CE**<br>*(ACC Actuarial Shield + Exits Drop Funds Super 64)* | **+13.07% CE**<br>*(42.5% from Neighbor Lanes!)* |
| **2. WellBeing Alliance** | **★ WEDGE (1$\times$2)**<br>**+2.15% CE**<br>*(*Whānau* Stay-Pull + Grant $E$ Needs $h_6\text{--}h_7$ Skill)* | **`[OWN SILO 2]`**<br>**+5.06% CE**<br>*(Cool $Q_k$ + Grant $E$ + Geo Floor + LVR Base)* | **★ WEDGE (2$\times$3)**<br>**+1.15% CE**<br>*(NZD 1.6T Land Rotates to $z_h$ Operating Firms!)* | **★ WEDGE (2$\times$4)**<br>**+0.65% CE**<br>*(-60 bps Debt-Sinking Cuts Young Mortgage $r_h$)* | **+9.01% CE**<br>*(43.8% from Neighbor Lanes!)* |
| **3. GrowthNZ & Venture** | **★ WEDGE (1$\times$3)**<br>**+1.95% CE**<br>*(Domestic 65% Thriving Talent Pool Feeds Firms)* | **★ WEDGE (2$\times$3)**<br>**+1.15% CE**<br>*(De-Hoarding Land Frees SME Credit Collateral)* | **`[OWN SILO 3]`**<br>**+2.10% CE**<br>*(Firm Tax Shift + 1.65x Infra Base Alone)* | **★ WEDGE (3$\times$4)**<br>**+0.65% CE**<br>*(-60 bps Credit + -3.1pp PAYE Retains Founders)* | **+5.85% CE**<br>*(64.1% from Neighbor Lanes!)* |
| **4. Fiscal Hawks & MBAs** | **★ WEDGE (1$\times$4)**<br>**+1.45% CE**<br>*(+16.8k/Birth Surplus & TFR 2.03 Solves Super!)* | **★ WEDGE (2$\times$4)**<br>**+0.65% CE**<br>*(Peak Estate Wave $\tau_b$ Self-Funds $SS1$ Outlay)* | **★ WEDGE (3$\times$4)**<br>**+0.65% CE**<br>*(+8.8% Wage & Firm Growth Expands Tax Base +14.5%)* | **`[OWN SILO 4]`**<br>**+0.95% CE**<br>*(Static Debt/Tax Target—Impossible Alone!)* | **+3.70% CE**<br>*(74.3% from Neighbor Lanes!)* |

> **Exact Matrix Identity:** The sum of the 4 Diagonal Own-Lane Silos (`7.52% + 5.06% + 2.10% + 0.95% = +15.63% CE`, which includes intra-silo pairings) plus the 6 unique Off-Diagonal Inter-Coalition Wedges (`2.15% + 1.95% + 1.45% + 1.15% + 0.65% + 0.65% = +8.00% CE`) equals **+23.63% CE**—reconciling to the second decimal place with the national $SS2$ welfare total in Table 1.1!

---

## Part II: The Sinking Baseline ($SS0$ Under the LTFM) & The +NZD 10B/yr Defense Cost-Sheet Shock

### 2.1 Mapping the 3D Macroeconomic Welfare Surface ($\mathrm{Debt/GDP} \times \mathrm{PAYE\ Tax\ Rate\ } \tau_l$)

Why do single-lane advocacy strategies look merely suboptimal in Table 1.2, yet prove **catastrophic** in practice? Because Table 1.2 measures gains relative to a stationary reference point, whereas the real New Zealand baseline ($SS0$) is sliding down a non-linear macroeconomic surface defined by two compounding fiscal coordinates:

1. **Axis 1 — Net Core Crown Debt ($B_{\mathrm{gov}}/Y \in [15\%, 200\%]$ of GDP):** In the national asset-market clearing condition:

$$\sum_{k=1}^{4} \omega_{F,k} \int \left(k_k(a_f, z_f) - a_f\right) d\Gamma_{k,t} + B_{\mathrm{gov},t} = \sum_{k=1}^{4} \omega_{HH,k,t} \int a_{\mathrm{fin}} d\mu_{k,t} + B_t^{*}$$

   every percentage point of net public debt above the 42% prudent baseline absorbs domestic savings, increases external debt-service leakage ($r_t B_t^{*}$) to foreign bondholders, and pushes up the equilibrium domestic interest rate ($\Delta r > 0$), tightening collateral constraints on operating SMEs ($k_f \le \lambda_{\mathrm{col}} a_f$) and inflating young-homeowner mortgage user costs ($r_{h,k}^{\mathrm{own}}$).
2. **Axis 2 — Required Working-Age PAYE Tax Rate ($\tau_l \in [17\%, 34\%]$):** As the 65+ dependency ratio rises and unmitigated child stunting (22.0%) swells reactive outlays across Exits 1, 2, 4 (from NZD 17.7B/yr today toward NZD 28.5B/yr by 2050), closing the government's intertemporal budget constraint $(1 + r_t)d_t + G_t + T_t = d_{t+1} + \mathrm{Taxes}_t$ requires raising $\tau_l$ from 22.0% toward 28.2%+. Higher $\tau_l$ directly compresses after-tax domestic wages $(1 - \tau_l)w_k z h$, which accelerates age 20–35 youth emigration to Australia via the Gumbel sorting operator $P_{\mathrm{emig},t}(k \to \mathrm{Abroad})$—shrinking the tax base denominator $\bar{H}_t$ even faster.

---

### 2.2 The Cruel Irony of the +NZD 10.0B/yr Defense Cost-Sheet Shock (0.75% to 3.0% of GDP)

Now consider what happens when an exogenous geo-strategic shock hits that already-fragile $SS0$ baseline: suppose New Zealand is required by alliance commitments and regional security deterioration to raise defense spending from its historical status quo of **~0.75% of GDP to 3.0% of GDP**—an additional permanent fiscal outlay of **+2.25% of GDP, or approximately +NZD 10.0 billion per year**.

Compare that +NZD 10.0B/yr defense cost shock against the Mirror Investment ledger of our Generational Plan (`Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_Dunedin_22.csv`):

* **Identical Gross Outlay (~NZD 10B/yr), Opposite Macroeconomic Physics:**
  * In our Generational Plan, the **entire Phase 2 ($SS2$) gross public investment across all four human-and-spatial pillars**—Universal First-2,000-Days wraparound (NZD 4.1B/yr), *Tuakana-Teina* / Montessori adolescent mentoring (NZD 1.9B/yr), the universal Age-20 Youth Capital Grant (NZD 2.2B/yr), and *Income $\times$ Geography* household transfers (NZD 2.0B/yr)—totals **NZD 10.10B/yr** (-4.24% CE gross outlay; NZD 7.86B/yr or -3.30% CE in $SS1$).
  * Yet because our NZD 10.10B/yr investment eradicates child stunting (22.0% to 1.5%), slashes reactive Exits 1, 2, 4 by over 75%, retains 3,550 skilled young adults per year, and rotates capital into high-$z_h$ firms, its **net unrecovered public cost hits zero at Year 18.8 (Cash Breakeven)** and generates **+NZD 56.2B/yr (+23.63% CE) in permanent annual household welfare**—a **5.57x steady-state welfare-to-outlay payoff**!
  * By contrast, an unfunded +NZD 10.0B/yr defense expansion—much of it spent on imported naval, aerospace, and munitions platforms—has a **0x domestic child-skill multiplier** and **zero reduction in Oranga Tamariki, hospital, or justice remediation costs**.
* **A Rising Cost Sheet Does Not Lift All Boats—It Sinks All Welfare:**
  * When +NZD 10.0B/yr of deadweight cost is loaded onto the displacement hull of $SS0$, it must be financed through some combination of higher working-age taxes ($\Delta \tau_l \approx +3.10\text{ pp}$, pushing required PAYE from 28.2% to **31.3%**) and faster sovereign debt accumulation (pushing net Crown debt to **200% of GDP** a full decade earlier).
  * On our 3D macroeconomic surface (`Table 21`), that +NZD 10.0B/yr cost-sheet shock drags lifetime household welfare down by an **additional -6.85% CE**—turning the LTFM's **-12.42% CE** slide into a **-19.27% CE national welfare collapse**!
* **How the $SS1 \to SS2$ Hydrofoil Carries a 3%-of-GDP Defense Load Without Sinking:**
  * What if New Zealand *must* fund a 3.0%-of-GDP defense posture in a more dangerous world? Our simulation proves that the **only** way to carry a +NZD 10.0B/yr deadweight hull load without crushing working families is to **get the domestic economy up on hydrofoils first**.
  * When the Unified 4-Coalition Plan ($SS1 \to SS2$) is active, the +NZD 56.2B/yr (+23.63% CE) welfare and fiscal engine easily absorbs a +NZD 10.0B/yr (-4.24% CE) defense requirement while still leaving New Zealand households **+19.39% CE (+NZD 46.1B/yr) ahead of today's baseline**—a **+38.66 percentage-point CE welfare advantage** over facing the same geopolitical shock under $SS0$ (+19.39% vs. -19.27%)!

---

### 2.3 Quantitative Comparison of the Eight 60-Year Macro & Coalition Trajectories (`Table 21`)

Table 2.1 reports the 60-year trajectories generated by `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m` across sovereign debt, required PAYE taxes, and household welfare:

| Trajectory & Policy Regime (`Table 21`) | Year 0 (2026) Debt / PAYE | Year 25 (2050) Debt / PAYE / CE% | Year 60 (2086) Net Debt (% GDP) | Year 60 Required PAYE $\tau_l$ (%) | Year 60 Household Welfare (CE%) | Net Swing vs. Sinking $SS0$ LTFM Floor |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Status Quo $SS0$ under Treasury LTFM Sinkhole** *(Aging + Unmitigated 22% Stunting)* | 42.0% / 22.0% | 80.2% / 24.1% / -3.4% | **185.0%** | **28.20%** | **-12.42%** | 0.00 pp *(Reference Sinkhole)* |
| **2. Status Quo $SS0$ + 3.0% GDP Defense Shock** *(+10.0B/yr Unfunded Cost Sheet)* | 42.0% / 22.0% | 95.4% / 27.2% / -8.7% | **200.0%** | **31.30%** | **-19.27%** | **-6.85 pp** *(Sinks All Boats)* |
| **3. "Solve Debt First in $SS1$" (MBA Austerity)** *(Cuts ECE + Raises Super to 70 at Yr 0)* | 42.0% / 22.0% | 52.4% / 25.4% / -3.6% | **112.0%** | **27.45%** | **-6.80%** | +5.62 pp *(Still Negative!)* |
| **4. GrowthNZ Silo Alone vs. LTFM Drift** *(Firm Tax Cut Without Skill or Housing)* | 42.0% / 22.0% | 76.0% / 23.8% / +0.3% | **168.0%** | **27.10%** | **-6.36%** | +6.06 pp *(Swamped by LTFM)* |
| **5. WellBeing Silo Alone vs. LTFM Drift** *(Housing + Grant $E$ Without ECE/Jobs)* | 42.0% / 22.0% | 72.5% / 23.5% / +4.6% | **154.0%** | **26.40%** | **-0.29%** | +12.13 pp *(Eroded to Zero)* |
| **6. Barnardos/Youth Silo Alone vs. LTFM Drift** *(ECE + Mentoring Without Housing/Jobs)* | 42.0% / 22.0% | 68.0% / 23.1% / +6.0% | **138.0%** | **25.50%** | **+1.89%** | +14.31 pp *(78% Lost to Drift)* |
| **7. Unified 4-Coalition Plan + 3% GDP Defense** *(Hydrofoil Carries +10B/yr Defense Load)* | 42.0% / 22.0% | 46.5% / 21.8% / +9.9% | **34.0%** | **21.10%** | **+19.39%** | **+31.81 pp** *(+38.7 pp vs Row 2!)* |
| **8. ★ Unified 4-Coalition Plan ($SS1 \to SS2$)** *(Super Age 64 + -3.12pp PAYE Cut + Debt Sunk)* | 42.0% / 22.0% | 40.5% / 20.4% / **+13.1%** | **22.0%** | **18.88%** | **+23.63%** | **+36.05 pp Total Welfare Swing!** |

Look at Rows 4, 5, and 6 of Table 2.1: when GrowthNZ (-6.36% CE), the WellBeing Alliance (-0.29% CE), or even the Barnardos/Youth Coalition (+1.89% CE) fights alone in its silo without addressing the macro fiscal and spatial loops of the other lanes, the compounding LTFM sinkhole swallows between **78% and 100% of their hard-won gains**. Only when all four constituencies lock arms in Row 8 does New Zealand reverse the sign of the LTFM—turning a **-12.42% CE** downward spiral into a **+23.63% CE** generational ascent (**a +36.05 percentage-point net welfare swing**).
## Part III: Speaking to Each Tribe in Their Own Language — Why Every Siloed Mission Depends on Its Neighbors

In a fragmented political environment, policy coalitions rarely fail because their core values are wrong; they fail because they attempt to optimize a single sub-system while treating adjacent sub-systems as exogenous constants or budget rivals. Below, we translate the mathematical findings of our $4 \times 4$ Coalition Complementarity Matrix (`Table 22`) into the native analytical dialect of each of New Zealand's four primary constituencies—demonstrating why each tribe's highest-priority goals are mathematically unattainable without the active partnership of the other three.

---

### 3.1 To the Barnardos, Iwi & Youth Development Constituency (*The Human Potential Lane*)
**Your Native Dialect:** *Mana tamaiti*, *mana rangatahi*, *Whānau Ora*, relational trust, breaking the intergenerational cycle of trauma, and closing the Dunedin Study's 22% hardship pipeline into Oranga Tamariki state care (Exit 1), avoidable hospitalisations (Exit 2), and youth justice (Exit 4).

* **What Our Model Validates in Your Lane:** Your core thesis is the foundation of the entire macroeconomic edifice. Front-loading universal First-2,000-Days wraparound support ($G_{\mathrm{ece},1} = 0.110 \to 0.130$, modeled on Barnardos' *Te Korowai Mokopuna*, *Kōhanga Reo*, and *A'oga Amata*) delivers **+3.47% CE** on its own, and pairing it with adolescent *Tuakana-Teina*, Graeme Dingle Foundation (*Stars / Project K*), and Montessori mentoring ($G_{\mathrm{ece},2} = 0.085 \to 0.105$, worth **+2.07% CE** alone) unlocks **Wedge 1 (+3.18% CE)**—lifting your intra-lane total to **+8.72% CE** (36.9% of the entire national prize).
* **Why You Cannot Succeed Alone (Your Three Neighbor Dependencies):**
  1. **Why You Need the Fiscal Hawks & Actuaries (Coalition 4 — Wedge $1 \times 4 = +1.45\%\text{ CE}$):** On a conventional "wait-as-you-go" cash budget, investing NZD 9.19B across Years 1–5 produces only NZD 0.60B in immediate cash savings because five-year-olds do not pay income tax or avoid adult prison beds until Year 18.8. If you treat Treasury and Fiscal Hawks as ideological enemies rather than adopting **ACC-style Actuarial Continuation Valuation** ($\mathcal{V}_{k,t_0}^{(\mathrm{Fiscal})}$), the cash-accounting deficit in Year 3 will be used to freeze or cancel your funding at the next change of government. By speaking the actuaries' language—booking the **NZD 10.68B in discounted 25-year direct cost avoidance (1.16x outlay)** and **NZD 35.25B in total fiscal return (3.84x outlay)** at Year 5—you make early childhood and adolescent mentoring *fiscally untouchable*.
  2. **Why You Need the WellBeing & Housing Alliance (Coalition 2 — Wedge $1 \times 2 = +2.15\%\text{ CE}$):** You cannot deliver high-trust *Te Korowai Mokopuna* wraparound or keep *whānau* intact if *Kaiako* (early-childhood educators), social workers, and *kuia* are priced out of Auckland ($Q_{\mathrm{Akl}} = 3.10$) and Large regional cities ($Q_{\mathrm{Large}} = 2.05$). In our state-contingent price-manifold deflator, $G_{\mathrm{ece},s}^{\mathrm{eff}}(Q_k) = G_{\mathrm{ece},s} \cdot (Q_{\mathrm{base},k}/Q_k)^{0.35}$, every 10% reduction in urban land overvaluation achieved by Coalition 2's property-tax rebalance automatically expands the real purchasing power and retention of your *Kaiako* workforce while keeping grandparents anchored near their *mokopuna* ($\Delta K_{\mathrm{whanau}} > 0$).
  3. **Why You Need GrowthNZ & Venture (Coalition 3 — Wedge $1 \times 3 = +1.95\%\text{ CE}$):** What happens if you succeed brilliantly at Gates 1 and 2—lifting the share of young New Zealanders reaching Age 20 in the thriving $h_6\text{--}h_7$ skill tiers from 23.5% to 65.0%—into a stagnant, low-wage domestic economy dominated by passive land-banking? Our $4 \times 5$ Gumbel migration operator ($\Pi_{\mathrm{mig}}$) gives the sobering answer: **19.3% to 23.4% of the thriving young adults you nurtured will board a plane to Sydney, Melbourne, or Brisbane.** Without GrowthNZ's high-productivity operating enterprises ($z_h$) to hire them at world-class wages, New Zealand becomes an unpaid training academy for the Australian tax base.

---

### 3.2 To the WellBeing & Housing Justice Alliance (*The Fair Start & Whānau Space Lane*)
**Your Native Dialect:** Housing as a human right, ending rental transience and crowding, taxing speculative property wealth ($\tau_a, \tau_b$), seeding every young adult with a fair start (Age-20 Youth Capital Grant $E$), regional cost-of-living justice ($T_k$), and protecting retirement dignity.

* **What Our Model Validates in Your Lane:** Your triad of structural balance-sheet levers—cooling speculative land overvaluation (`+2.57% CE` with firm reallocation), the universal Age-20 Youth Capital Grant $E$ (`+1.30% CE` alone), and *Income $\times$ Geography* household transfers $T_k$ (`+1.06% CE` alone)—combines to unlock **Wedge 2 (+2.23% CE)**. Together, these levers push young renters across the non-linear **20% LVR deposit threshold** ($a \ge 0.20 Q_k$), lifting young-adult homeownership in Auckland from 28.0% to 41.2% and eliminating the 12% comonotonic eviction/transience penalty (`Tier 2 Subtotal = +7.15% CE`).
* **Why You Cannot Succeed Alone (Your Three Neighbor Dependencies):**
  1. **Why Your Youth Capital Grant ($E$) Needs Barnardos & Mentoring (Coalition 1 — Wedge $1 \times 2 = +2.15\%\text{ CE}$):** Look at Layer 5 in Table 1.1: why does handing every 20-year-old a universal Youth Capital Grant ($E$) in isolation deliver only **+1.30% CE**? Because in Cunha, Heckman, and Schennach's (2010) skill technology, the Stage-2 elasticity of substitution is $\sigma_2 = 1/(1 - \varphi_2) = 0.51 < 1$. A cash grant at Age 20 **cannot retroactively rewire early cognitive architecture or adolescent executive function** if a young person grew up stunted ($h_1\text{--}h_2$). Without Coalition 1's First-2,000-Days and *Tuakana-Teina* scaffolding, a standalone Youth Grant is rapidly bid into landlord rents or consumed on subsistence. Paired with Coalition 1, thriving $h_6\text{--}h_7$ 20-year-olds convert $E$ into home equity and business formation.
  2. **Why Your Wealth Tax Needs GrowthNZ's "Use-It-Or-Lose-It" Engine (Coalition 3 — Wedge $2 \times 3 = +1.15\%\text{ CE}$):** If wealth and estate taxation is framed as a punitive extraction on all success, it triggers capital flight and political gridlock. By adopting Guvenen et al.'s (2023) **"Use-It-Or-Lose-It" Productive Capital Rebalance**—levying $\tau_a = 1.5\%$ on dormant land/book equity and $\tau_b = 25\% \to 18\%$ on passive estates while *cutting* corporate and productive reinvestment drag—you split the top 2% right down the middle (`Table 17`): **active growth entrepreneurs ($z_h$) remain net welfare winners all the way up to the IRD High-Wealth Median (NZD 50M, +1.2% CE) and break even at the NBR Rich List Median (NZD 140M, -0.1% CE)**. That alliance with productive business owners gives you the political majority to pass housing and estate reform.
  3. **Why Lowering NZ Super to Age 64 Needs the Fiscal & Demographic Loop (Coalition 4 — Wedge $2 \times 4 = +0.65\%\text{ CE}$):** Protecting—and in Phase 2 ($SS2$), **lowering**—the NZ Superannuation age from 65 to **64** releases a **+8.1% *Kuia / Koroua* alloparental time dividend** ($K_{\mathrm{whanau}} \uparrow$). But as our U-curve sweep (`Table 8`) proved, lowering the pension age without first expanding the skilled tax base and retiring sovereign debt (-60 bps mortgage relief) hits a demographic denominator wall. You need Coalition 1's stunting compression and Coalition 4's 50% Debt-Sinking Fund to make Age-64 Superannuation fiscally self-financing at an **18.88% PAYE tax rate**.

---

### 3.3 To the GrowthNZ, Founders & Venture Constituency (*The "Where Will the Jobs Come From?" Lane*)
**Your Native Dialect:** Total Factor Productivity ($Z_k$), scale-up capital, collateral constraints ($k_f \le \lambda_{\mathrm{col}} a_f$), Murphy-Shleifer-Vishny talent allocation, agglomeration economies, infrastructure ROI ($\mu_{\mathrm{infra}} = 1.65$), and international tax competitiveness.

* **What Our Model Validates in Your Lane:** Social advocates often forget to answer your most important question: *"Once we educate these young people, where will all the high-paying jobs come from?"* In our infinite-horizon firm Bellman equation (`ReturnFn_Firm.m`), rotating capital out of low-yield land hoarding ($z_{\ell}$) and into collateral-constrained operating ventures ($z_h$) while reinvesting 50% of post-breakeven fiscal surpluses into regional infrastructure ($\mu_{\mathrm{infra}} = 1.65$) lifts real regional wages by **+3.2% to +5.5% in $SS1$** and **+6.8% to +9.6% in $SS2$**.
* **Why You Cannot Succeed Alone (Your Three Neighbor Dependencies):**
  1. **Why Tax Cuts and Foreign Recruitment Fail Without Domestic Childhood Capability (Coalition 1 — Wedge $1 \times 3 = +1.95\%\text{ CE}$):** Look at `Table 22`: if GrowthNZ implements firm tax cuts and infrastructure in isolation while ignoring domestic child stunting (22.0%), your standalone payoff is just **+2.10% CE**—and against the LTFM fiscal drift (`Table 21`, Row 4), it sinks to **-6.36% CE**! Why? Because in a production function $y_f = z_f (k_f^{\alpha_k} \ell_f^{1-\alpha_k})^{1-\nu}$, physical capital $k_f$ and effective human capital $\bar{H}_k = \int z h \ell_{\mathrm{eff}}\,d\mu_k$ are strict complements. Recruiting foreign engineers on temporary visas cannot compensate for a domestic school pipeline where nearly a quarter of the cohort launches stunted and top local graduates emigrate. You need Barnardos and *Tuakana-Teina* mentoring to nearly triple your domestic $h_6\text{--}h_7$ talent pool (from 23.5% to 65.0%).
  2. **Why You Need the WellBeing Alliance to Cure the "Lavoisier Syndrome" (Coalition 2 — Wedge $2 \times 3 = +1.15\%\text{ CE}$):** Why do New Zealand startups struggle to raise domestic expansion capital and retain engineering talent? Because when NZD 1.6 trillion of residential land appreciates tax-free at $Q_{\mathrm{Akl}} = 3.10$, two things happen: (i) domestic bank credit and private equity are sucked into leveraged real estate rather than operating SMEs, and (ii) as Murphy, Shleifer, and Vishny (1991) prove, top analytical talent is lured into property speculation, conveyancing, and rent-seeking ($R_{\mathrm{rent}}(A) > \pi_{\mathrm{ent}}(A)$) while young engineers flee Auckland's rent squeeze. You need Coalition 2's land-and-estate levy ($\tau_a, \tau_b$) and Youth Grant ($E$) to break the property cartel and anchor young builders in New Zealand (**Wedge 3 = +3.87% CE nationally, +5.19% CE in Auckland**).
  3. **Why You Need Sovereign Debt-Sinking & PAYE Relief in $SS2$ (Coalition 4 — Wedge $3 \times 4 = +0.65\%\text{ CE}$):** Retiring NZD 17.8B–21.9B of sovereign debt per cohort wave crowds *in* domestic private lending—lowering equilibrium business borrowing rates by **-60 bps** ($\Delta r = -0.006$, directly expanding your collateralized capital limit $k_f \le \lambda_{\mathrm{col}} a_f$)—while the **-3.12 to -3.50 pp working-age PAYE tax cut** makes New Zealand tax-competitive with Australia for senior technical talent.

---

### 3.4 To the Fiscal Hawks, Bond Markets & MBA Stewards (*The Balance-Sheet & Tax-Relief Lane*)
**Your Native Dialect:** Net core Crown debt (% of GDP), OBEGAL surpluses, sovereign credit ratings, deadweight debt-service interest ($r_t d_t$), actuarial liabilities, and lowering marginal PAYE tax rates ($\tau_l$).

* **What Our Model Validates in Your Lane:** Your warning about the Treasury LTFM baseline is 100% right. Allowing net Crown debt to compound toward 185%–200% of GDP and required PAYE taxes to drift toward 28.2% (or 31.3% under a 3%-of-GDP defense cost shock) destroys **-12.42% to -19.27% CE** in household welfare (`Fig_Doc3_LTFM_Sinkhole_And_DefenseShock`). And your 2050 Sovereign Debt-Sinking Fund (-60 bps interest relief) and PAYE tax cut deliver **+3.89% CE** in Tier 4 (`Table 1.1`).
* **Why "Solving Debt First" via Phase-1 Austerity Is Mathematically Impossible (Why MBAs Need MPPs):**
  * Look at Trajectory 3 in `Table 21` (*"Solve Debt First in $SS1$"*): suppose a hardline MBA government tries to fix the Crown balance sheet at Year 0 by cutting early-childhood and mentoring outlays and raising the NZ Superannuation age to 70.
  * In a private corporation, an MBA can boost EBITDA by closing an unprofitable plant and shedding its workforce onto the external state. **A sovereign government *is* the external state—it cannot fire its citizens.**
  * When you cut preventive Gate 1/Gate 2 investments and raise the Super age to 70 in $SS1$, our state-contingent operators (`Document 2`, Section 10) reveal three immediate balance-sheet boomerangs:
    1. **The Geriatric & Disability Substitution Leak:** Displaced manual and low-$h$ 65–69-year-olds draw Supported Living, Jobseeker hardship, and acute hospital/ACC care (`fiscal_leak_mult`), wiping out nearly half the mechanical pension savings.
    2. **The Sandwich-Generation Care Reversal ($K_{\mathrm{whanau}}^{\mathrm{net}} < 0$):** Forcing 65–69-year-old *kuia* and aunties to work withdraws **-36.2%** of extended-*whānau* care from young parents and imposes an upward elder-care drag on 40–55-year-old taxpayers.
    3. **Compounding Stunting & Tax-Base Collapse:** Without early wraparound and *whānau* scaffolding, cohort stunting spikes across all four regions (`25.4%` in Rural, `18.0%` in Auckland in `Table 8`), swelling downstream Oranga Tamariki, prison, and hospital bills (Exits 1, 2, 4) while shrinking the future skilled taxpayer denominator $\bar{H}_t$.
  * **The Verdict:** Attempting to cut debt first in $SS1$ leaves required PAYE taxes climbing to **24.30%–27.45%** and drags national welfare down to **-6.80% CE**. Fiscal Hawks depend on **74.3% of their connected value coming from Neighbor Lanes 1, 2, and 3 (`Table 1.2`)**. Only by protecting the MPP human-capital and enterprise investments in Phase 1 ($SS1$) do you generate the **+NZD 15.8k–16.8k/yr per-birth fiscal surplus** that retires sovereign debt to **22% of GDP** and cuts working-age PAYE to **18.88%** in Phase 2 ($SS2$).

---

## Part IV: Perishability, "Stop-Go" Parliamentary Interference, and Why "Thick" State-Contingent Operators Beat "Thin" Spreadsheets

### 4.1 The Political Tragedy of "Stop-Go" Budgeting

Even when policy-makers accept that early childhood, adolescent mentoring, housing affordability, and enterprise investment are valuable, adversarial three-year parliamentary cycles frequently produce **"Stop-Go" sporadic funding**:
* *Term 1 (Years 1–3):* Government A launches First-2,000-Days wraparound ($G_{\mathrm{ece},1}$) and adolescent mentoring ($G_{\mathrm{ece},2}$).
* *Term 2 (Years 4–6):* Government B takes office promising "fiscal discipline" or an immediate tax cut, freezes or defunds Gate 2 adolescent mentoring and geographic transfers ($T_k$) as "unproven soft spending," and raids the Youth Capital Fund.
* *Term 3 (Years 7–9):* Alarmed by rising youth truancy and hospitalisations, Government C partially restores the programs—only for the cycle to repeat.

Why do conventional Treasury and agency spreadsheets vastly underestimate the damage caused by this three-year "Stop-Go" budgetary interference?

---

### 4.2 "Thin" Linear Spreadsheets vs. "Thick" State-Contingent VFI Operators

As formalized in [Document 2](Document%202.md) (Section 10), a conventional spreadsheet models policy using **"thin" numbers**—evaluating linear algebraic formulas at population-average scalars ($\mathbb{E}[a], \mathbb{E}[h], \mathbb{E}[\theta_c], \mathbb{E}[z]$):

$$Y_{\mathrm{Spreadsheet}} = f\left(\mathbb{E}[a],\, \mathbb{E}[h],\, \mathbb{E}[\theta_c],\, \mathbb{E}[z]\right)$$

Under a "thin" linear spreadsheet (`Trajectory 3a` in `Fig_Doc3_LTFM_Sinkhole_And_DefenseShock` and `Table 21`), if a program is funded 50% of the time (an alternating 3-year On / 3-year Off duty cycle), it is assumed to deliver roughly **52% of the full long-run benefit (+12.29% CE)**—as if human development were a highway paving project that simply sits patiently waiting whenever the road crew takes a three-year break.

In the real world—and in our GPU-accelerated VFI engine—human capability evolves across **"thick" probability distributions** $\mu_k(a, h, \theta_c, z, j)$ (19,215 discrete state coordinates per age and region) governed by non-linear, state-contingent operators:

$$Y_{\mathrm{VFI}} = \mathbb{E}_{\mu_k}\left[f(a, h, \theta_c, z)\right] \ll f\left(\mathbb{E}[a],\, \mathbb{E}[h],\, \mathbb{E}[\theta_c],\, \mathbb{E}[z]\right)$$

When competitive budgetary interference turns key programs On and Off every three years (`Trajectory 3b` in `Table 21`), **four non-linear "perishability traps"** fire simultaneously inside the state-contingent operators:

1. **Unbanked Adolescent Skill Fade-Out ($\delta_{\theta,\mathrm{fade}} = 0.22$) & The Harmonic-Mean Bottleneck ($\varphi_2 = -0.95$):**
   In our two-stage Cunha–Heckman skill law of motion (`HumanCapital_Lifecycle_aprimeFn.m`), early skill gains ($\theta_c > \theta_{\mathrm{base}}$) built during the First 2,000 Days (Ages 0–5) are **perishable until banked at the Adolescent Gate (Ages 12–14)**:
   $$\theta_{c,\mathrm{ret}} = \theta_c - \delta_{\theta,\mathrm{fade}}(1 - M_{\mathrm{mentor}})\max(0, \theta_c - \theta_{\mathrm{base}})$$
   If Cohort A receives world-class First-2,000-Days wraparound in Term 1, but a subsequent government cuts *Tuakana-Teina* / Montessori mentoring ($M_{\mathrm{mentor}} \to 0$) when that cohort hits ages 12–14 during an unbuffered family unemployment shock ($z_1$), **22% of the early skill gain evaporates per period** and the harmonic-mean Stage-2 CES aggregator ($\varphi_2 = -0.95 < 0$) collapses toward its weakest link. **Wedge 1 (+3.18% CE) is wiped out.**
2. **Non-Linear LVR Deposit & Comonotonic Eviction Thresholds ($a < 0.20 Q_k$ and $a < 0.08 Q_k \land z < 0.85$):**
   In `ReturnFn_SpatialHH_Compact4D.m`, crossing from renter user costs ($r_r$) to homeowner user costs ($r_h$) requires clearing a discrete **20% LVR deposit cliff** ($0.20 Q_k$). If a government freezes the Age-20 Youth Capital Grant ($E$) or pauses the land-tax rebalance ($\tau_a, \tau_b$) for a single term, young families fall just short of the 20% cliff and remain trapped in the rental market—where a comonotonic tail shock ($a < 0.08 Q_k \land z < 0.85$) triggers the 12% eviction/transience penalty. **Wedge 2 (+2.23% CE) evaporates.**
3. **Collapse of Multiphase Credibility Blending ($\lambda_{\mathrm{cred}}(t) \to 0$):**
   In `TransPath_4Region_Master.m`, young graduates aged 20–35 decide whether to stay in New Zealand or emigrate to Australia based on the credibility-weighted continuation value:
   $$\tilde{V}_{k,t+1} = \left(1 - \lambda_{\mathrm{cred}}(t)\right) V_{k,t+1}^{\mathrm{perm},SS1} + \lambda_{\mathrm{cred}}(t) V_{k,t+1}^{\mathrm{full},SS2}$$
   When young workers and founders observe "Stop-Go" partisan raiding of the generational compact, $\lambda_{\mathrm{cred}}(t)$ collapses to zero. Even during the "On" years, 20-to-35-year-olds assume the Phase-2 PAYE tax cut and housing relief will be repealed and emigrate anyway. **Wedge 3 (+3.87% CE) collapses.**
4. **Irreversible Cohort Scarring & Loss of the $SS2$ Fiscal Harvest:**
   Because a child only passes through Ages 0–5 once and Ages 12–14 once, a three-year budget cut permanently scars that birth cohort's adult human capital ($h_1\text{--}h_2$) for the next 45 years of working life—preventing the Crown ledger from reaching the Year 18.8 Cash Breakeven threshold needed to unlock **Wedge 4 (+1.93% CE)**.

---

### 4.3 Perishability Audit: Which Gains Are Fragile vs. Which Gains Become Permanent?

Table 4.1 contrasts the naive "Thin Spreadsheet" prediction against the true "Thick State-Contingent VFI" outcome across our counterfactuals, and classifies every layer of the plan by its **Perishability Window** (when it is vulnerable to political interference vs. when it becomes permanently locked into the economy):

#### Table 4.1: Perishability & Counterfactual Audit Across Policy Regimes (`Tables 19, 21, & 22`)

| Counterfactual Regime / Policy Layer | Thin Spreadsheet Prediction (Scalar Means) | Thick VFI State-Contingent Reality | Welfare Lost to Synergy Collapse & Fade-Out | Perishability Window & How the Coalition Compact Protects It |
| :--- | :---: | :---: | :---: | :--- |
| **A. Fully Integrated 4-Coalition Plan ($SS1 \to SS2$, Super Age 64)** | `+12.43% CE` *(Misses Wedges!)* | **`+23.63% CE`** | `0.00%` *(100% Captured)* | **Protected by Design:** ACC Actuarial Valuation + statutory 50/50 Debt/Infra Sinking Rule locks in continuity across parliaments. |
| **B. "Stop-Go" Alternating 3-Yr Funding (50% Duty Cycle)** | `+12.29% CE` *(Assumes 50% linear scaling)* | **`+6.62% CE`** *(Sawtooth attrition)* | **`-17.01% CE` (`72.0%` of prize destroyed!)** | **Highly Perishable in Childhood (Ages 0–14):** Cutting Gate 2 mentoring in alternate terms triggers $\delta_{\theta}=0.22$ fade-out of Gate 1 ECE gains and destroys Wedges 1, 2, 3, and 4. |
| **C. Early-Years ECE ($G_{\mathrm{ece},1}$) Without Gate 2 Mentoring ($G_{\mathrm{ece},2}$)** | `+5.10% CE` *(Ignores $\varphi_2 = -0.95$)* | **`+3.47% CE`** | **`-5.25% CE` vs. Tier 1 (`+8.72%`)** | **Perishable at Ages 12–14:** Without *Tuakana-Teina* / Montessori mentoring and *whānau* stability, unbuffered $z_1$ family shocks erode early gains before Age 20. |
| **D. Age-20 Youth Grant ($E$) Without ECE/Mentoring or Land Cooling** | `+3.10% CE` *(Treats $E$ as additive cash)* | **`+1.30% CE`** | **`-5.85% CE` vs. Tier 2 (`+7.15%`)** | **Perishable at Launch (Age 20):** If youth arrive stunted ($h_1\text{--}h_2$) in an uncooled housing market ($Q_{\mathrm{Akl}}=3.10$), $E$ cannot clear the 20% LVR cliff or substitute for skill. |
| **E. "Solve Debt First in $SS1$" (MBA Cuts + Super Age 70 at Yr 0)** | `+1.80% CE` *(Assumes mechanical savings)* | **`-6.80% CE`** *(Sinks into deficit!)* | **`-30.43% CE` vs. Integrated Plan!** | **Immediate Comonotonic Reversal:** Triggers 45% disability leak + Sandwich Care Reversal ($K_{\mathrm{whanau}}^{\mathrm{net}} < 0$), spiking stunting and forcing PAYE tax hikes. |
| **F. Once Banked at Age 20+ ($h_6\text{--}h_7$ Skill, Home Equity, Sunk Debt)** | *N/A* | **Durable for 45–60 Years** | **Low Perishability Once Banked** | **Permanently Banked After Age 20 & Year 18.8:** Once a cohort reaches Age 20 in $h_6\text{--}h_7$, buys a home, and retires NZD 21.9B/wave of Crown debt, those gains compound for 60 years! |

> **The Core Insight of Table 4.1:** Human capital and social trust are **highly perishable while in the developmental pipeline (Ages 0 to 19)**—where a single three-year budget cut at Gate 2 can destroy **72.0% of the total generational prize (`+23.63% -> +6.62% CE`)**—but become **extraordinarily durable once banked at Age 20**. That is why the four coalitions must never raid one another's pipeline stages during the 18.8-year incubation window.
