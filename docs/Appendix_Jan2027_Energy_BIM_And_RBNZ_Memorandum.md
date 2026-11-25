<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Inter, Roboto, 'Helvetica Neue', Arial, sans-serif; font-size: 16px; line-height: 1.65; color: #1f2328; max-width: 960px; margin: 2rem auto; padding: 0 1.5rem;">

# Appendix: January 2027 Energy Minister Briefing (BIM) & Reserve Bank Governor's Companion Memorandum

**Repository Integration:** `IGWelfare` (`wave8-docs` — Pillar I: The Energy Rewiring)  
**Synchronized Ledger, Model & Exogenous Input Provenance:**
* `src/ledgers/Compute_Hormuz_EV_Counterfactual_Ledger.m` — Solves deterministic central paths and 1,000-draw Monte Carlo P95 tail fans (2023–2065) under joint Markov Hormuz/oil-supply and portfolio-balance UIP shocks for bilateral FX, landed capex penalties (`Delta P_K`), refined road-fuel import bills (NZD 9.3B in 2025 rising to NZD 14.5B in 2026), and 2065 Net Core Crown Debt.
* `src/returnfns/ReturnFn_SpatialHH.m` & `src/returnfns/ReturnFn_Firm.m` — Calibrate four-region Stone-Geary survival/energy floors (`c_floor`, `ebar_energy`), Kimball effective prudence, Second-Law exergy efficiencies ($e_F = 0.30$, $e_N = 0.88$), and Dixit-Pindyck waiting wedges ($\Omega_{\mathrm{opt}}$).
* `plots/Plot_LTFM_EV_And_Hormuz_Shocks.m` — Generates `output/NZ_Dunedin1972/Table_LTFM_EV_Credit_And_Hormuz_OilShocks_Dunedin_22.csv` (source of the 2025–2026 road-fuel spike table and scenario debt rows) and `output/NZ_Dunedin1972/Fig_LTFM_EV_Credit_And_Hormuz_OilShocks_Dunedin_22.png`.
* **Exogenous Sectoral & Engineering Inputs (*Rewiring Aotearoa*, 2026):** Household delivered solar-plus-battery LCOE (23c/kWh vs. 40c/kWh retail), household annual cash-flow savings (NZD 6,800–7,300/yr), and gross domestic electrical/trades installation demand (58,000 cumulative FTE job-years across peak deployment; exogenous engineering-ledger multiplier rather than an endogenous OLG labor-clearing output).

---

## Overview & Cross-Scenario Exchange-Rate / Debt Tail-Risk Summary

This paired policy appendix translates the incomplete-markets, spatial-exergy Overlapping Generations (OLG) and Small Open Economy (SOE) mechanics of `ReturnFn_SpatialHH`, `ReturnFn_Firm`, and `Compute_Hormuz_EV_Counterfactual_Ledger` into two complementary executive instruments dated **January 2027**:

1. **Part I — Briefing to the Incoming Minister of Energy (BIM):** Voiced directly to the incoming Energy Minister's Cabinet seat, demonstrating how a single three-year parliamentary term (2027–2030) breaks New Zealand's precautionary liquidity and capital-expenditure freeze, locks in twenty years of sovereign currency and debt resilience, and avoids the stranded-asset trap of an imported Liquefied Natural Gas (LNG) terminal.
2. **Part II — Illustrative Monetary-Physical Companion Memorandum (Reserve Bank Analytical Perspective):** An author-constructed analytical simulation framed from the Monetary Policy Committee's structural remit (not an official Reserve Bank document or endorsement), setting out the formal non-homothetic Euler, Dixit-Pindyck real-options, and Dornbusch-Gabaix-Maggiori exchange-rate equations explaining why monetary policy is currently "pushing on a string"—and why physical electrification is the precondition for restoring symmetric Official Cash Rate (OCR) transmission.

### Synchronized NZD/USD & Sovereign Debt Tail-Risk Matrix (2023–2065)

Anchored at the Clean Car Discount repeal on **31 December 2023** (0.632 USD per NZD; $S_0 = 1.583$ NZD per USD), bilateral exchange-rate trajectories decompose into hydrocarbon terms-of-trade bleed, cumulative Net Foreign Asset (NFA/Y) drift, and Dornbusch Uncovered Interest Parity (UIP) overshooting, calibrated to the November 2026 spot trough of **0.545 USD** ($S_t = 1.835$ NZD per USD). *(Convention note: New Zealand market commentary quotes the Kiwi in USD per NZD, e.g., 0.545 USD, whereas open-economy import-pricing equations define $S_t$ in NZD per 1 USD, e.g., 1.835 NZD/USD so that $\Delta S_t > 0$ measures imported price inflation; both conventions are reported below.)* Shifting from imported hydrocarbons ($e_F = 0.30$) to domestic rooftop/farm solar, batteries, and electric drive ($e_N = 0.88$) collapses the P95 downside risk fan (95th percentile across 1,000 stochastic oil-and-UIP paths) after 2035:

| Policy & Energy Architecture | 2026 Spot (USD/NZD) & NZD/USD | 2035 NZD/USD (Central / P95) & (USD/NZD) | 2045 NZD/USD (Central / P95) & (USD/NZD) | 2045 Landed Capex Penalty (Delta P_K) | 2065 Net Crown Debt % GDP (Central / P95 Tail) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **1. Ended EV Credit (Repeal CCD — Fossil Lock-In)** | **(0.545 USD)** **1.835** | 1.72 / **2.06** (+0.34) (0.581 / 0.485) | 1.76 / **2.15** (+0.39) (0.568 / 0.465) | +11% to **+36%** | 223.8% / **258.4%** (+34.6 pp tail) |
| **1b. Repeal + Imported LNG Terminal** *(USD Gas Lock-In)* | **(0.545 USD)** **1.835** | 1.74 / **2.11** (+0.37) (0.575 / 0.474) | 1.79 / **2.19** (+0.40) (0.559 / 0.457) | +13% to **+38%** | 227.5% / **264.1%** (+36.6 pp tail) |
| **2. Kept EV Credit (Keep CCD — Self-Funding Feebate)** | **(0.549 USD)** **1.822** | 1.66 / **1.86** (+0.20) (0.602 / 0.538) | 1.65 / **1.82** (+0.17) (0.606 / 0.549) | +4% to **+15%** | 205.6% / **221.9%** (+16.3 pp tail) |
| **3. +30%/yr Boost + Domestic Solar (*Rewiring Aotearoa*)** | **(0.553 USD)** **1.808** | 1.59 / **1.67** (+0.08) (0.629 / 0.599) | **1.53** / **1.57** (**+0.04**) (0.654 / 0.637) | **-3% to +0%** | **186.4%** / **191.2%** (**+4.8 pp tail**) |

**Scope Reconciliation Across Hydrocarbon Outflow Metrics:** Three distinct fuel-import aggregates appear in the ledger and text, each covering a specific boundary and pricing regime:
* **NZD 9.3B (2025 pre-shock) rising to NZD 14.5B (2026 Hormuz shock):** Landed CIF import bill for **refined road-transport fuels only** (retail petrol and on-road diesel) reported in `Table_LTFM_EV_Credit_And_Hormuz_OilShocks_Dunedin_22.csv`.
* **NZD 12B to 16B/yr (electrifiable fuel outflow extinguished by 2040–2045):** Road petrol and diesel **plus off-road agricultural/construction diesel, coastal/rail middle distillates, and stationary LPG/light fuel oil** displaced by domestic EVs, utes, farm solar-battery systems, and industrial heat pumps across calm-to-elevated crude scenarios.
* **NZD 19B to 28B/yr (gross economy-wide hydrocarbon & petrochemical exposure):** Total gross external hydrocarbon-linked outflow during moderate-to-acute shock years, adding **international aviation jet fuel, maritime bunker fuel, bitumen, hydrocarbon-derived fertilizers/feedstocks, and prospective spot LNG cargoes** at depreciated exchange rates.

---

## Part I: Briefing to the Incoming Minister of Energy (January 2027)

**Date:** January 2027  
**Classification:** Cabinet Policy & Macroeconomic Strategy — *In Confidence*  
**To:** Incoming Minister of Energy  
**Subject:** Breaking New Zealand's Macroeconomic Stall: Why Monetary Policy Is Trapped, Why Imported LNG Deepens the Hole, and How a Three-Year Electrification Drive Locks In Twenty Years of Sovereign & Household Resilience

### 1.1 Executive Summary: You Hold the Macroeconomic Lever That the Reserve Bank Lost

Minister, you take up the Energy portfolio at an extraordinary moment. Most incoming Energy Ministers are told their job is keeping the lights on and managing sector regulation while the Minister of Finance and the Reserve Bank of New Zealand (RBNZ) steer the macroeconomy. **In January 2027, that division of labor is dead.**

Over the past twelve months, the Strait of Hormuz oil and middle-distillate shock pushed retail petrol toward NZD 3.70/L and diesel up 71% (NZD 3.51/L), while the New Zealand dollar sank to **0.545 USD** (**1.835 NZD/USD**)—a 17-year extreme. Despite the RBNZ cutting the Official Cash Rate (OCR) aggressively to 2.75%, household consumption remains frozen and business capital expenditure has stalled.

The central finding of our four-region spatial macroeconomic modeling is blunt: **the Reserve Bank is pushing on a string because New Zealand households and firms are trapped in a physical energy squeeze.** Until households and businesses believe their future energy bills are bounded, further OCR cuts will simply be hoarded as precautionary cash while trashing the exchange rate.

**You—not the Reserve Bank Governor—hold the circuit-breaker.** Decisions you take inside a **single three-year parliamentary term (2027–2030)** will determine whether New Zealand spends the next twenty years trapped in stagflationary debt drift (heading past 220% Net Core Crown Debt to GDP by 2065) or locks in a domestic solar-and-electrification floor that cuts **over 85% of New Zealand's currency and fiscal tail risk by 2040**. Worse, the siren song currently on your desk—underwriting an **imported LNG terminal**—would hard-wire the exact US-dollar commodity and currency vulnerability that caused this crisis.

### 1.2 Why the Reserve Bank Cannot Rescue This Recovery ("Pushing on a String")

In calm waters, a 150 to 200 basis point OCR cut reliably stimulates mortgage-holder spending and small-business investment. Standard linear models assume that same elasticity still works in a storm. **It does not—and four real-world frictions wired into household and firm balance sheets explain why:**

1. **The Household "Subsistence-Amplified Prudence" Trap:**  
   Households do not make spending decisions on gross income; they budget on **discretionary headroom above irreducible survival floors**—rent, rates, food, and mandatory transport and heating fuel (`c_floor` and `ebar_energy`). In rural New Zealand, provincial towns, and outer urban commuter belts, households cannot simply stop driving to work or chilling milk when diesel hits NZD 3.51/L. As surging fuel bills eat toward that survival floor, household anxiety (*effective prudence*) spikes nonlinearly. When the RBNZ cuts the OCR and shaves NZD 60/week off a family's mortgage, that family does **not** spend it on local retail or hospitality—they **hoard every dollar into liquid precautionary savings** to brace for the next fuel or cost-of-living shock. Our four-region calibration shows this precautionary wedge adds an invisible **+180 to +260 bps shadow drag**, swallowing an entire RBNZ easing cycle and **cutting the consumption power of OCR cuts in half (45% to 60% muted)**.

2. **Business Paralysis: The Option Value of Waiting (Dixit-Pindyck Freeze):**  
   Capital equipment—processing lines, delivery fleets, coolstores, orchards—is expensive to buy and costly to reverse. Facing violent swings in diesel freight margins and winter wholesale power prices, New Zealand boards and farm owners attach a massive premium to *waiting for clarity*. That uncertainty adds a **+250 to +350 bp hurdle wedge** onto investment decisions. Cutting the OCR by 150 bps cannot clear a 300 bp fog of energy uncertainty.

3. **The Small-Open-Economy Capex Catch-22 (0.545 USD / 1.835 NZD per USD):**  
   Because New Zealand faces NZD 19B to 28B/yr in gross hydrocarbon-linked external outflows during global supply spikes while the United States exports energy and holds higher interest rates, RBNZ easing leans into an already sliding currency—from 0.632 USD (1.583 NZD/USD) at the end of 2023 to **0.545 USD (1.835 NZD/USD)** in late 2026, a **14.8% cumulative log jump in the NZD cost of USD**. Here is the trap: **New Zealand imports nearly 100% of its productive machinery, commercial vehicles, transformers, heat pumps, and solar hardware in foreign currency.** In our structural UIP ledger (Part II, Equation II), a standalone 150 bp OCR cut in calm conditions weakens the Kiwi by ~4.0% and inflates landed equipment prices by ~3.6% (clawing back over a third of the ~10.0% financing relief, leaving a net ~6.4% user-cost drop that still cannot clear the +300 bp energy-uncertainty hurdle). Worse, when that 150 bp cut stacks atop the Hormuz terms-of-trade hit (~6.8% FX drop) and unanchored current-account expectations (~4.0% FX drop), the combined **14.8% currency slide inflates landed NZD capital sticker prices by +13.3%**, overpowering the cheaper interest rate and **raising net capital user cost by +3.3% on day one**.

4. **Domestic Demand Pessimism:**  
   Because businesses see households hoarding cash rather than spending, domestic small and medium enterprises (SMEs) anticipate flat order books. Even debt-free firms with cash in the bank sit on their hands because nobody builds capacity for customers who are hunkered down.

### 1.3 How *Rewiring Aotearoa* Breaks the Trap Today—Not in 2040

Critics will tell you that electrifying vehicles, farms, and rooftops takes a decade, so it cannot solve a 2027 growth slump. **That misunderstands how forward-looking households and businesses make decisions.**

Households and firms hoard cash *today* because they fear **permanent, open-ended exposure** to future energy shocks. *Rewiring Aotearoa* already has the engineering and economic answers to this test:

* **Thermodynamics on Our Side:** Replacing imported combustion fuel (30% useful mechanical work, 70% waste heat) with domestic renewable electricity (88% work efficiency in electric motors and heat pumps) cuts primary energy requirements by **nearly two-thirds** per kilometre driven or tonne-kilometre hauled.
* **Cheapest Delivered Energy in New Zealand History:** Financed rooftop solar paired with home batteries delivers an effective household electricity price around 23c/kWh (versus 40c/kWh grid retail) and daytime marginal energy equivalent to **NZD 0.40/L petrol**—saving an electrified New Zealand household NZD 6,800 to 7,300/yr (NZD 9.6B/yr nationwide, or NZD 96B cumulatively through 2040) while remaining completely immune to Middle East Strait blockades, refinery crack spreads, and NZD/USD currency crashes.

When you legislate a **credible, irreversible 2027–2030 Electrification Compact**—restoring and escalating clean-vehicle and commercial-ute feebates at +30%/yr over three years (2.20x rebate by Year 3), unlocking low-interest Crown-backed finance for household and farm solar plus batteries, and mandating symmetrical export tariffs so households and farmers are paid fairly for peak injection—**three things happen immediately in 2027:**

1. **Future Tail Risk & Subsistence Squeeze Collapse, Melting ~70% of Precautionary Hoarding in 2027:**  
   Even though physical fleet turnover peaks in the 2030s, the shadow precautionary wedge drops by roughly **70% in Year 1 (2027)** through three immediate channels in our four-region OLG solver: **(i) ~30 percentage points from Day-1 cash-flow switching at the subsistence boundary**, as zero-upfront *Rewire Finance* moves the most fuel-stressed rural and commuter cohorts off hyperbolic prudence right away; **(ii) ~25 percentage points from permanent-income re-anchoring**, as legislating post-2032 fossil phase-down reclassifies the 2026–2028 oil spike from *permanent impoverishment* to a *bounded transitory bridge*, slashing next-period consumption-adjustment variance today; and **(iii) ~15 percentage points from immediate spot FX firming** (0.545 to 0.553 USD on announcement), easing imported retail tradables inflation.
2. **OCR Cuts Channel Directly Into High-Return Balance-Sheet Upgrades:**  
   Instead of hoping anxious families borrow at 2.75% to buy imported consumer goods, low interest rates pair with point-of-sale electrification finance so households and farms **swap NZD 4,500 to 7,000/yr in imported fossil OPEX for NZD 2,200/yr in domestic solar and EV finance**, supporting an estimated 58,000 cumulative FTE job-years in local electrical/installation trades (*Rewiring Aotearoa*, 2026 sectoral estimate) and raising household disposable cash flow every month thereafter.
3. **Currency & Sovereign Debt Bridge (How Retained Fuel Dollars Shave 37.4 pp off 2065 Crown Debt):**  
   Extinguishing NZD 12B to 16B/yr of electrifiable fuel imports narrows New Zealand's structural current-account deficit, **cutting P95 currency tail risk from +0.39 to +0.04 NZD/USD by 2045** and reducing 2065 Net Core Crown Debt by **37.4 percentage points of GDP** (186.4% vs. 223.8%). Crucially, the ledger nets out all three fiscal leakages before booking Crown gains: roughly **30c per saved fuel dollar** goes offshore for amortized panels, batteries, and vehicles (leaving **70c, or ~1.8%–2.2% of GDP**, in net domestic retention); lost Fuel Excise Duty (FED) is **fiscally neutral** under New Zealand's universal distance-based Road User Charges (RUC); and the 2027–2030 Compact's net Crown outlay (0.2%–0.4% GDP/yr, adding **+1.2 pp** compounded to 2065) is charged upfront. Against that +1.2 pp seed cost, three compounding channels deliver **-38.6 pp** by 2065 (net **-37.4 pp**):
   * **Sovereign $(r - g)$ Compounding (-16.2 pp):** Narrowing Net Foreign Liabilities trims sovereign external risk premia by 25–40 bps while higher exergy efficiency ($e_N = 0.88$) lifts trend real GDP growth $g$ by +0.15–0.20 pp/yr, shaving 16.2 pp off a ~200%-of-GDP LTFM debt trajectory over 38 years.
   * **Primary Tax Capture on Domestic Value-Added (-13.8 pp):** Redirecting the retained 70c/dollar from untaxed CIF crude imports into domestic wages, retail spending, and SME/farm operating surpluses yields ~27c/dollar in GST, PAYE, and corporate tax (~0.50% GDP/yr structural primary-balance improvement).
   * **Avoided Shock Stabilizers & Bailouts (-8.6 pp):** Insulating households and freight from recurring oil/Hormuz spikes eliminates repeated emergency fiscal relief packages, temporary excise/RUC cuts, and recessionary transfer spikes.

### 1.4 Why an Imported LNG Terminal Is a Macroeconomic Own-Goal

You will face intense lobbying in your first 90 days to fast-track or Crown-underwrite an **imported LNG regasification terminal** in Taranaki or Marsden Point as "dry-year insurance." **Decline it—and use the macro-FX ledger to show Cabinet why:**

* **It Replaces One USD Strait-of-Hormuz Choke Point With Another:** Roughly one-fifth of global seaborne LNG transits the exact same Strait of Hormuz, and Asian spot LNG (JKM) spikes simultaneously whenever crude oil and geopolitical risk flare. Importing LNG means **importing US-dollar commodity volatility directly into New Zealand's wholesale electricity price**.
* **Worst Possible Dry-Year / Currency Correlation:** When a dry hydro winter coincides with a global energy shock, NZD/USD plunges (1.835+) *at the exact moment* New Zealand must outbid Asian and European utilities in US dollars for spot LNG cargoes—multiplying wholesale power spikes instead of capping them.
* **Stranded Take-or-Pay Liability That Freezes Solar & Storage Investment:** Regasification terminals require 10 to 15 year take-or-pay charter guarantees (NZD 1.0B to 1.5B+ in fixed commitments). Passing terminal levies onto consumers or Crown balance sheets **re-creates the Dixit-Pindyck investment freeze**, chilling private capital that would otherwise build domestic distributed solar, grid batteries, geothermal, wind, and industrial demand response with **zero USD fuel cost** for 30 years.
* **Thermodynamic Waste:** Burning imported NZD 20 to 28/GJ landed LNG in a 40% to 55% thermal peaker to run resistive heaters—instead of deploying heat pumps (COP ~ 3.5), insulated hot-water storage, rooftop solar, and two-way vehicle/stationary batteries—throws away two-thirds of our scarce foreign exchange before an electron ever reaches a home.

### 1.5 Your Three-Year Term (2027–2030) vs. the Twenty-Year Payoff

Three years is too short to pour concrete for mega-projects, **which is precisely why modular electrification wins inside a single parliamentary term.** Rooftop solar installs in two days; heat pumps and smart water cylinders install in an afternoon; electric vans, utes, and commuter EVs roll off ships every week once the price signal is set.

| Decision Seat (2027–2030 Term) | Path A: Passive Drift + Imported LNG ("Status Quo Lock-In") | Path B: *Rewiring Aotearoa* Trim-Tab (+30%/yr Electrification + Solar Finance) |
| :--- | :--- | :--- |
| **Upfront 3-Year Crown Outlay** | Low visible EV outlay, **high hidden LNG take-or-pay contingent liability** + ongoing RUC/FED tax patches | Deliberate **0.2% to 0.4% GDP/yr seed** (partially self-funded by high-emitter fees + green bond facilities) |
| **RBNZ Monetary Transmission** | **Broken** (0.40x multiplier; households hoard; 1.835+ Kiwi inflates imported machinery) | **Restored** (0.90x multiplier; cheap credit flows immediately into cost-saving household/SME capex) |
| **2027–2030 Growth Trajectory** | **Dead at the start:** stagflationary drift, deferred SME capex, persistent current-account bleed | **Immediate domestic trades/construction stimulus** + permanent monthly household cash-flow dividend |
| **20-Year Structural Outcome (2045)** | Still 75%+ exposed to USD oil/LNG shocks; P95 FX crash risk past **2.15 NZD/USD** | Fossil import exposure cut **over 80%**; P95 FX tail compressed to **+0.04**; Crown debt **37.4 pp lower** by 2065 |

### 1.6 Recommended First-100-Days Action Plan

1. **Enact the Three-Year Accelerated Electrification Feebate & Fleet Compact (2027–2030):** Restore and commit to a legislated +30%/yr three-year ramp (NZD 7,015 base escalating past NZD 15,400 by Year 3) targeting commercial vans, rural/trade utes, freight, and household EVs, alongside pre-tax salary-sacrifice EV leasing (EV Salary Boost), ahead of scheduled post-parity tapering in the early 2030s.
2. **Launch Universal Cash-Flow-Positive "Rewire Finance" (Ratepayer / Property-Assessed Solar + Battery + Heat Pump Loans):** Guarantee zero-upfront, low-interest financing across all four regions—where Day-1 fossil and power bill savings exceed loan repayments—prioritizing rural, provincial, and low-income commuter households where subsistence prudence is tightest.
3. **Mandate Symmetrical Export Tariffs & Fast-Track Rooftop/Farm Permitting:** Direct the Electricity Authority and lines companies to compensate distributed household and farm solar-battery peak injection on equal footing with centralized generation, enabling rural landowners to "farm energy alongside food and fibre."
4. **Rule Out Crown Underwriting for Imported LNG:** Issue a definitive policy statement declining Crown fiscal guarantees or regulated levy recovery for imported LNG infrastructure, redirecting firming capital into domestic geothermal, hydro-storage management, grid/distributed batteries, biomass peakers, and industrial demand response.

---

## Part II: Illustrative Companion Memorandum — The Monetary-Physical Transmission Perspective (January 2027)

<div style="background-color: #f6f8fa; border-left: 4px solid #57606a; padding: 0.75rem 1rem; margin: 1rem 0; font-size: 0.93em; color: #24292f;">
<strong>Author's Analytical Illustration — Disclaimer:</strong> The following memorandum is a stylised macroeconomic policy device authored by the <code>IGWelfare</code> modeling team to formalise how physical energy exposure interacts with the Monetary Policy Committee's statutory remit. It is <strong>not</strong> an official document, statement, or policy endorsement of the Reserve Bank of New Zealand (Te Pūtea Matua) or its Governor.
</div>

**Analytical Voice:** Illustrative Central-Bank Structural Assessment (Monetary-Physical Coordination Simulation)  
**Date:** January 2027  
**Addressed To:** Minister of Finance; Incoming Minister of Energy  
**Subject:** Restoring the Monetary Transmission Mechanism: Structural Equations of the 2026–2027 Stagflationary Trap and Why Real-Side Domestic Electrification Is Prerequisite to Symmetric OCR Policy

### 2.1 Purpose: Why Te Pūtea Matua Is Writing on Energy Architecture

Under the Remit for the Monetary Policy Committee (MPC), the Reserve Bank is charged with keeping future annual Consumers Price Index (CPI) inflation between 1% and 3% over the medium term (with a focus near the 2% midpoint) and supporting maximum sustainable employment, while seeking to avoid unnecessary instability in output, interest rates, and the exchange rate. Standard post-1989 New Keynesian doctrine treats energy supply architecture as an exogenous relative-price disturbance through which monetary policy can "look" while managing aggregate demand via the Official Cash Rate (OCR).

Over the past four quarters, that separability assumption has broken down both empirically and analytically. Following the 2026 Strait of Hormuz crude and middle-distillate shock, the MPC lowered the OCR to 2.75% to cushion contracting domestic output and rising unemployment (5.6%). Yet domestic household consumption and private non-residential capital formation have failed to respond at historical elasticities, while the bilateral exchange rate has depreciated to 0.545 USD ($S_t = 1.835$ NZD per USD)—importing fresh tradables inflation directly back into the CPI basket.

This memorandum sets out the formal structural mechanics obtained when linearized representative-agent DSGE approximations (Smets & Wouters, 2007) are replaced with an incomplete-markets, spatial-exergy Heterogeneous Agent New Keynesian / Overlapping Generations framework (Kaplan, Moll & Violante, 2018; Auclert, Rognlie & Straub, 2024; Labrousse & Perdereau, 2026; Keen, Ayres & Standish, 2019). The analytical conclusion is unambiguous: **the OCR transmission channel is currently blocked by an unhedged physical energy boundary.** Only real-side policy action from the Energy portfolio can remove that boundary.

### 2.2 Equation I: Subsistence-Amplified Prudence and the Collapse of the Consumption Euler Elasticity

Linearized central-bank models assume certainty equivalence and constant Intertemporal Elasticity of Substitution ($\mathrm{IES} = 1 / \eta_c$). In reality, New Zealand households across regions $r \in \lbrace \mathrm{Rural}, \mathrm{SmallUrban}, \mathrm{LargeUrban}, \mathrm{Auckland} \rbrace$ maximize expected lifetime utility subject to non-homothetic Stone-Geary subsistence floors and irreducible spatial energy commitments (commuting, refrigeration, water heating; Labrousse & Perdereau, *JME* 2026):

$$
u\left(c_{i, r, t}, \ell_{i, r, t}\right) = \frac{\left(\left(c_{i, r, t} - c_{\mathrm{floor}} - p_{E, t} \bar{e}_r\right)^{\phi_{nd}} \left(1 - \ell_{i, r, t}\right)^{1 - \phi_{nd}}\right)^{1 - \eta_c}}{1 - \eta_c}
$$

Define discretionary consumption headroom above irreducible physical commitments as $\tilde{c}_t > 0$, with composite curvature $\tilde{\eta} \equiv 1 - \phi_{nd}\left(1 - \eta_c\right) > 1$. Taking a second-order Taylor expansion of the incomplete-markets stochastic Euler equation (Kimball, 1990; Carroll, 1997; Bewley-Huggett-Aiyagari) around expected discretionary consumption growth yields:

$$
\mathbb{E}_t \lbrack \Delta \ln \tilde{c}_{i, r, t+1} \rbrack \approx \frac{1}{\tilde{\eta}} \left(r_t - \rho\right) + \frac{1}{2} \mathcal{P}_{\mathrm{eff}}\left(c_{i, r, t}\right) \mathrm{Var}_t \left(\Delta \ln \tilde{c}_{i, r, t+1}\right)
$$

where Kimball's **effective relative prudence** with respect to total household expenditure $c_{i, r, t}$ is:

$$
\mathcal{P}_{\mathrm{eff}}\left(c_{i, r, t}\right) = -\frac{c_{i, r, t} u_{ccc}}{u_{cc}} = \left(\tilde{\eta} + 1\right) \left(\frac{c_{i, r, t}}{c_{i, r, t} - c_{\mathrm{floor}} - p_{E, t} \bar{e}_r}\right)
$$

Observe what occurs simultaneously during an unhedged hydrocarbon shock (+38% retail petrol and +71% retail diesel while fiscal retrenchment compresses public in-kind service buffers):

1. **Hyperbolic Prudence Amplification:** As mandatory fuel expenditure rises toward the household's discretionary margin—most acutely in Rural and SmallUrban regions where spatial energy intensity $\bar{e}_r$ is structurally high and public-transit substitution is near zero—the ratio $c_t / \tilde{c}_t$ diverges upward, multiplying effective prudence by 2.5x to 4.0x across the bottom three wealth quintiles.
2. **Variance Dominance Over OCR Cuts:** Simultaneously, uncertainty over future Strait disruptions and imported tradables inflation elevates conditional headroom variance $\sigma_t^2$. For the MPC to hold current aggregate consumption flat ($\Delta C_t = 0$) via monetary policy alone, the real policy rate $r_t$ must fall by the shadow precautionary wedge:

$$
\Delta r_t^{\mathrm{shadow}} = -\frac{\tilde{\eta}}{2} \Delta \lbrack \mathcal{P}_{\mathrm{eff}}\left(c_{i, r, t}\right) \sigma_{\tilde{c}, t}^2 \rbrack
$$

In our four-region calibration, $\Delta r_t^{\mathrm{shadow}}$ widens by **-180 to -260 bps**. When the MPC cuts the OCR by 150 to 200 bps, households near the subsistence-energy boundary do not substitute intertemporally into domestic non-tradable spending; they divert freed mortgage cash flows into liquid buffer-stock assets $a^{\prime}$ to self-insure against unanchored fuel bills. The effective aggregate demand multiplier $\partial C_t / \partial r_t$ collapses to **0.40x of its calm-water value**.

### 2.3 Equation II: Real-Options Paralysis and the Dornbusch-Jorgenson Capex Catch-22

On the production side, infinite-horizon regional firms operate with useful exergy conversion (Ayres & Warr, 2009; Keen et al., 2019), where useful physical work $X_t = e_F E_F + e_N E_N$ captures the Second-Law thermodynamic gap between combustion hydrocarbons ($e_F = 0.30$) and renewable electric drive and heat pumps ($e_N = 0.88$). Firms accumulate collateral-constrained capital $k^{\prime} \le \lambda_{\mathrm{col}} a$ subject to partial irreversibility.

Under Dixit & Pindyck (1994) and Bloom (2009), a firm invests only when the marginal revenue product of capital clears the **option-adjusted Jorgensonian user cost** $u_{K, t}$:

$$
\mathrm{MPK}_t \ge u_{K, t} \equiv P_{K, t}^{\mathrm{NZD}}\left(S_t\right) \left(r_t + \delta_k + \Omega_{\mathrm{opt}}\left(\sigma_{p_E}^2\right)\right)
$$

Here the MPC confronts a perverse **Small-Open-Economy Capex Catch-22** linking Dornbusch (1976) exchange-rate overshooting and Gabaix & Maggiori (2015) imperfect international financial intermediation:

1. **The Real-Options Wedge:** Volatile diesel freight and thermal peaking margins inject a +250 to +350 bp option value of waiting into $\Omega_{\mathrm{opt}}$.
2. **Adverse Exchange-Rate Pass-Through:** Under portfolio-balance Uncovered Interest Parity with peripheral net-foreign-asset friction $\Gamma_{\mathrm{NFA}}$, the log bilateral exchange rate $s_t = \ln S_t$ (NZD per USD) satisfies:

$$
s_t = \mathbb{E}_t\lbrack \bar{s}_T \rbrack - \bar{\tau}_{\mathrm{gap}} \left(i_t^{\mathrm{NZ}} - i_t^{\mathrm{US}}\right) + \eta_{\mathrm{ToT}} \phi_{F, t} M_{\mathrm{oil}, t} + \Gamma_{\mathrm{NFA}} \left\vert \frac{\mathrm{NFA}_t}{Y_t} \right\vert
$$

Because New Zealand imports virtually 100% of its plant, machinery, commercial vehicles, and electrical switchgear at world foreign-currency price $P_K^{\ast}$, the landed NZD price of capital scales as $S_t^{\theta} P_K^{\ast}$ ($\theta \approx 0.90$). Differentiating log user cost with respect to an OCR cut ($\Delta i_t < 0$) while foreign rates remain elevated (5.15% US 10-year yield) gives:

$$
\frac{\mathrm{d} \ln u_{K, t}}{\mathrm{d} i_t^{\mathrm{NZ}}} = \frac{1}{r_t + \delta_k + \Omega_{\mathrm{opt}}} - \theta \bar{\tau}_{\mathrm{gap}}
$$

Evaluating this derivative exposes both the **partial-equilibrium attenuation** and the **general-equilibrium reversal** of OCR cuts during an unhedged energy shock:

* **Partial-Equilibrium UIP Slope ($\theta \bar{\tau}_{\mathrm{gap}} = 2.4$):** With $\theta = 0.90$, $\bar{\tau}_{\mathrm{gap}} = 2.67$, and $r_t + \delta_k + \Omega_{\mathrm{opt}} \approx 0.15$ (so $\left(r_t + \delta_k + \Omega_{\mathrm{opt}}\right)^{-1} \approx 6.67$), a standalone -150 bp OCR cut ($\Delta i_t^{\mathrm{NZ}} = -0.015$) holding oil prices and long-run FX expectations fixed depreciates $s_t$ by 4.0%, inflating landed $P_{K, t}^{\mathrm{NZD}}$ by +3.6% against a -10.0% financing-rate reduction. Even in isolation, adverse FX pass-through claws back over one-third of the easing, leaving a net -6.4% user-cost reduction (equivalent to ~95 bps) that cannot clear the +250 to +350 bp waiting hurdle $\Omega_{\mathrm{opt}}$.
* **Stacked 2024–2026 Total Differential (Effective Slope $\approx 9.9$ on $s_t$, ~8.9 on $\ln P_K^{\mathrm{NZD}}$):** In the full `Compute_Hormuz_EV_Counterfactual_Ledger` transition from 1.583 to 1.835 NZD/USD ($\Delta s_t = +0.148$, or 0.632 to 0.545 USD), the -150 bp rate-differential move (+4.0% on $s_t$) stacks with the Hormuz hydrocarbon terms-of-trade shock $\eta_{\mathrm{ToT}} \phi_{F, t} \Delta M_{\mathrm{oil}, t}$ (+6.8%) and unanchored long-run FX expectations plus NFA drift $\Delta \mathbb{E}_t\lbrack \bar{s}_T \rbrack + \Gamma_{\mathrm{NFA}} \Delta \vert \mathrm{NFA}_t / Y_t \vert$ following Clean Car Discount repeal (+4.0%). Landed capital goods prices jump +13.3% ($\theta \Delta s_t$ with $\theta = 0.90$, $\Delta s_t = 0.148$), overpowering the -10.0% interest relief and **raising net user cost $u_{K, t}$ by +3.3%** (matching Part I's Catch-22). Moreover, if further unanchored OCR cuts unmoor $\mathbb{E}_t\lbrack \bar{s}_T \rbrack$, the marginal total derivative $\mathrm{d} \ln u_{K, t} / \mathrm{d} i_t^{\mathrm{NZ}}$ itself flips negative—meaning rate cuts actively *raise* the hurdle cost of capital.

### 2.4 Why Imported LNG Locks In Wrong-Way Stagflationary Covariance

From a central bank's risk-management perspective, proposals to underwrite an **imported LNG regasification terminal** worsen every structural term in Equations I and II:

* **Wrong-Way Covariance:** Seaborne spot LNG (JKM) is invoiced in USD and shares physical choke points and geopolitical tail risk with crude oil, yielding positive shock covariance $\mathrm{Cov}\left(M_t, S_t\right) > 0$. During a global supply or risk-off shock, spot USD gas prices surge *at the exact moment* $S_t$ (NZD/USD) depreciates—multiplying wholesale electricity short-run marginal cost:

$$
\mathrm{SRMC}_t^{\mathrm{NZD}} = \frac{S_t P_{\mathrm{LNG}, t}^{\mathrm{USD}}}{e_F}
$$

* **Persistent Real-Options Overhang:** Multi-decade take-or-pay charter guarantees crowd out zero-marginal-cost domestic renewables and distributed battery storage, leaving industrial and commercial firms permanently exposed to winter marginal pricing spikes via $\Omega_{\mathrm{opt}}$.

### 2.5 How the Energy Minister's Three-Year Compact Restores Monetary Policy

Consider instead how a legislated **2027–2030 Domestic Electrification & Distributed Solar Compact** (*Rewiring Aotearoa*: +30%/yr clean-fleet and commercial-ute feebate escalation paired with universal cash-flow-positive solar, battery, and heat-pump finance) transforms the Bellman continuation value $\beta \mathbb{E}_t\lbrack V_{t+1}\left(a^{\prime}, h^{\prime}, z^{\prime}\right) \rbrack$ across all four regions:

1. **Immediate 2027 Compression of the Shadow Prudence Wedge (~70% Drop):**  
   In a single-period heuristic, removing risk after 2032 would move 2027 saving modestly; in the incomplete-markets OLG Bellman problem (`ReturnFn_SpatialHH`), iterating the Euler equation forward shows that current precautionary saving integrates discounted future prudence-weighted variance across the lifecycle while optimal $c_{t+1}$ responds immediately to permanent-income variance:

$$
\ln \tilde{c}_{i, r, t} = \mathbb{E}_t \lbrack \ln \tilde{c}_{i, r, T} \rbrack - \sum_{k=0}^{T-t-1} \left( \frac{1}{\tilde{\eta}}\left(\mathbb{E}_t\lbrack r_{t+k} \rbrack - \rho\right) + \frac{1}{2} \mathbb{E}_t \lbrack \mathcal{P}_{\mathrm{eff}}\left(c_{i, r, t+k}\right) \mathrm{Var}_{t+k}\left(\Delta \ln \tilde{c}_{i, r, t+k+1}\right) \rbrack \right)
$$

   Driving $\phi_F$ down to 0.16 by 2040 shrinks the aggregate 2027 shadow wedge $\Delta r_{2027}^{\mathrm{shadow}}$ by **~70%** via three simultaneous Year-1 effects: **(a) ~30% from targeted cash-flow-positive *Rewire Finance* uptake** among high-$\bar{e}_r$ Rural and SmallUrban commuters, lifting $\tilde{c}_{2027}$ away from the Stone-Geary pole where $\mathcal{P}_{\mathrm{eff}}$ is hyperbolic; **(b) ~25% from reclassifying oil shocks from permanent lifetime-wealth erosion to a bounded 3-to-5 year bridge**, cutting one-step policy-function variance $\mathrm{Var}_{2027}\left(\Delta \ln \tilde{c}_{2028}\right)$ immediately; and **(c) ~15% from spot NZD appreciation** (1.835 to 1.808 NZD/USD on impact via $\Delta \mathbb{E}_t\lbrack \bar{s}_T \rbrack$), trimming 2027–2028 imported pump and tradables prices. Together, these **restore household OCR responsiveness from 0.40x back toward 0.90x in 2027**.
2. **Channeling 2.75% Credit Into Deflationary Balance-Sheet Capex:**  
   Rather than pushing on a string of anxious retail borrowers, low policy rates coupled with Rewire point-of-sale finance flow directly into positive-NPV household, farm, and SME electrification upgrades—permanently *lowering* non-tradable and transport unit costs in the CPI basket every quarter thereafter.
3. **Re-Anchoring Long-Run FX Expectations and Compressing the P95 Tail:**  
   In our portfolio-balance UIP equation, spot $s_t$ moves one-for-one with expectations of the long-run equilibrium real exchange rate $\mathbb{E}_t\lbrack \bar{s}_T \rbrack$. Legislating the permanent elimination of NZD 12B to 16B/yr in offshore hydrocarbon drain anchors long-run exchange-rate expectations stronger today, compressing New Zealand's P95 downside exchange-rate tail from +0.39 NZD/USD to +0.04 NZD/USD and allowing the MPC to adjust the OCR counter-cyclically without triggering a currency rout.

### 2.6 Concluding Synthesis: Physical Energy Insulation as Precondition for Monetary Symmetry

Central banks rightly guard operational independence and do not endorse specific fiscal or sectoral programmes; yet analytical candor requires stating the physical boundary conditions of a single nominal overnight rate. **An Official Cash Rate cannot manufacture electrons off Waikato barn roofs, cannot repeal the Second Law of Thermodynamics to lift combustion efficiency from 30% to 88%, and cannot insure a provincial household against a Strait of Hormuz diesel blockade.**

Whenever an economy remains unhedged against imported physical exergy shocks, monetary policy is forced to use a blunt nominal rate to lean against stagflation—watching rate relief vanish into subsistence-driven precautionary hoarding while a 17-year-trough exchange rate (0.545 USD / 1.835 NZD per USD) re-imports tradables and capital-goods inflation.

Conversely, any credible real-side policy that substitutes zero-marginal-cost domestic electricity and storage for imported USD hydrocarbons—while avoiding new USD gas lock-in—lifts the subsistence-prudence and real-options straitjacket off household and corporate balance sheets. **Insulating the physical kilowatt-hours over the 2027–2030 parliamentary term is what restores clean, symmetric, low-volatility monetary transmission for a sovereign New Zealand economy.**

*Analytical Simulation Prepared by the `IGWelfare` Monetary-Physical Modeling Team (Not an official communication of Te Pūtea Matua / RBNZ)*

---

### Technical References

* **Auclert, A., Rognlie, M., & Straub, L. (2024).** *Exchange Rates and Monetary Policy with Heterogeneous Agents: Sizing up the Real Income Channel.* Econometrica / NBER Working Paper.
* **Ayres, R. U., & Warr, B. (2009).** *The Economic Growth Engine: How Energy and Work Drive Material Prosperity.* Edward Elgar.
* **Bloom, N. (2009).** *The Impact of Uncertainty Shocks.* Econometrica, 77(3), 623–685.
* **Carroll, C. D. (1997).** *Buffer-Stock Saving and the Life Cycle/Permanent Income Hypothesis.* Quarterly Journal of Economics, 112(1), 1–55.
* **Dixit, A. K., & Pindyck, R. S. (1994).** *Investment under Uncertainty.* Princeton University Press.
* **Dornbusch, R. (1976).** *Expectations and Exchange Rate Dynamics.* Journal of Political Economy, 84(6), 1161–1176.
* **Gabaix, X., & Maggiori, M. (2015).** *International Liquidity and Exchange Rate Dynamics.* Quarterly Journal of Economics, 130(3), 1369–1420.
* **Kaplan, G., Moll, B., & Violante, G. L. (2018).** *Monetary Policy According to HANK.* American Economic Review, 108(3), 697–743.
* **Keen, S., Ayres, R. U., & Standish, R. (2019).** *A Note on the Role of Energy in Production.* Ecological Economics, 157, 40–46.
* **Kimball, M. S. (1990).** *Precautionary Saving in the Small and in the Large.* Econometrica, 58(1), 53–73.
* **Labrousse, C., & Perdereau, Y. (2026).** *Geography versus Income: The Heterogeneous Effects of Carbon Taxation.* Journal of Monetary Economics.
* **Rewiring Aotearoa (2026).** *Electric Homes and Vehicles 2026: The Strategic Context & Powered from Within.* Queenstown / Wellington.
* **Smets, F., & Wouters, R. (2007).** *Shocks and Frictions in US Business Cycles: A Bayesian DSGE Approach.* American Economic Review, 97(3), 586–606.

</div>
