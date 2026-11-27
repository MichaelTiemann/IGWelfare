# Out-of-Sample Twin Validation: Finland (`FI_Peruskoulu1967` & `FI_FBC1987`) vs. Aotearoa New Zealand (`NZ_Dunedin1972`)

## 1. Epistemic Design: Universal Human Capability Under Divergent Institutional Regimes

To test whether `IGWelfare`'s 4-region Overlapping Generations (OLG) and 5-sector biophysical exergy architecture captures general small-open-economy (SOE) laws rather than overfitting New Zealand, we construct a 58-year historical twin benchmark for Finland spanning its pre-reform baseline (`FI_Peruskoulu1967`, $`t_0 = 1967`$) and modern post-reform cohort state (`FI_FBC1987`, anchored to the 1987 Finnish Birth Cohort and 2025–2026 Statistics Finland / THL / Fingrid accounts).

Crucially, **all deep human-development, preference, and co-production exponents are held strictly identical across New Zealand and Finland** (enforced in CI by `tests/test_finland_profiles.m`):

* **Cunha–Heckman CES Skill Technology:** Identical dynamic complementarity ($`\phi_2 = -0.95`$), early vs. adolescent self-productivity weights, adult Ben-Porath learning elasticity (`alpha_I = 0.090`), unmentored adolescent fade-out (`delta_fade = 0.22`), and 7-point human-capability grid $`h \in \lbrack 0.45, 0.65, 0.85, 1.00, 1.20, 1.45, 1.80 \rbrack`$.
* **Shock Persistence & Intergenerational Scaling:** Identical regional shock autocorrelation (`psi_persist`), shock dispersion (`sigma_z`), and Daruich transmission scaling (`daruich_mult`).
* **Ostrom–Waring Co-Production Technology:** Identical paid-volunteer CES substitution (`Ostrom_CoProd_Rho = 0.650`, `Ostrom_Omega_Paid = 0.720`), unpaid household care shadow-wage weight (`Waring_Shadow_Wage_Frac = 0.720`), and Sector 2 learning-by-doing spillover (`Arrow_S2_Spillover_Eta = 0.140`).

Every divergence between `NZ_Dunedin1972`, `FI_Peruskoulu1967`, and `FI_FBC1987` therefore arises **purely from observable institutional commitments, statutory tax/transfer schedules, spatial housing prices, and biophysical energy infrastructure**.

---

## 2. Five Out-of-Sample Validation Proofs (`1967 -> 2025`)

### Proof 1: Real-World *Te Kāhui Waka* Spatial Sequencing (`1972–1977`) Arrests Adolescent Skill Fade-Out

In 1967, Finland operated a parallel tracked school system (*kansakoulu* vs. selective fee/exam *oppikoulu* splitting children at age 10–11) with 40.9% of households in rural municipalities and severe northern/eastern deprivation. Between 1972 and 1977, Parliament executed the exact peripheral-to-primate rollout geometry formalized by `IGWelfare`'s *Te Kāhui Waka* schedule:

* **Wave 1 (`1972`):** Rural Lapland (`Echelon 1`).
* **Waves 2–4 (`1973–1976`):** Eastern, Central, and Western provincial towns (`Small`) and regional university poles (`Large`: Oulu, Kuopio, Joensuu, Jyväskylä, Tampere, Turku), paired with the 1972 Primary Health Care Act (*terveyskeskus*) and 1973 Act on Children's Day Care (`ECEC`).
* **Wave 5 (`1977`):** Greater Helsinki (`Primate_Region_ID = 'Helsinki'`), followed by 1979 university Master's-level teacher education.

Solving the 5D Bellman lifecycle steady state (`NZ_4Region_Master.m`, `dt = 5`, `J = 16`) across `FI_Peruskoulu1967` and `FI_FBC1987` reproduces three core empirical regularities without target-fitting:

| 5D Bellman / Empirical Metric | `FI_Peruskoulu1967` ($`t_0 = 1967`$) | `FI_FBC1987` (`2025` Base) | Structural Mechanism Verified |
| :--- | :---: | :---: | :--- |
| **Empirical Baseline Struggling Share (`h1–h2`)** | `23.05%` | `7.15%` | Pekkarinen, Uusitalo & Kerr (2009) IGE compression (`0.30 -> 0.23`) + THL `FBC 1987` cohort registry. |
| **Solved 5D Bellman Stage-1 Skill ($`\bar{h}_1`$)** | `0.925` | `0.979` (`+0.054`) | 1973 universal municipal `ECEC` + *Neuvola* infant wraparound (`99.5%` reach). |
| **Solved 5D Bellman Completed Launch Skill ($`\bar{h}_2`$)** | `0.881` | `0.972` (`+10.3%`) | Unified 9-year *peruskoulu* + low-stigma *erityisopetus* (`26%` pupil reach at EUR 4k/yr vs. EUR 146k/yr institutional care). |
| **Adolescent Skill Compounding ($`\bar{h}_2 - \bar{h}_1`$)** | `-0.044` *(all 4 regions `< 0`)* | `+0.011` (`Rural`), `+0.009` (`Small`) | Eliminating age-10 tracking flips rural and small-town adolescence from net skill decay to positive Cunha–Heckman compounding. |
| **Year-5 Actuarial Direct Cost Avoidance (`2%` SRTP, EUR 6.03B Outlay)** | `EUR 9.64B` (`4.35x` total ROI) | `EUR 2.99B` (`3.01x` total ROI) | Proves diminishing marginal returns to `Aspect 1` alone once early/school remediation backlogs are already harvested. |

### Proof 2: Epistemic Complementarity of Finland's `2016` Disinformation Curriculum (`C15 x C22`)

Evaluating `Compose_Policy_Bundle.m` across Finland's historical commitment waves isolates why Finland ranks #1 in Europe on the Open Society Media Literacy Index and #2 globally on Transparency International's CPI (`88–90 / 100`):

* Deploying transversal multiliteracy and disinformation defense (`C15`) **without** the `1972–1979` *peruskoulu* + `ECEC` foundation (`fi_disinfo_without_peruskoulu_test`) yields **`0.00 pp`** reduction in struggling youth and only **`+10.38`** social-cohesion points (`TI_CPI = 85.40`).
* Deploying the exact same `C15` curriculum **atop** `C21 + C22` (`fi_wave4_disinfo_and_age18_2014_2023`) delivers **`+26.88`** cohesion points (`2.59x` standalone gain) and **`TI_CPI = 92.38`**, confirming that population-wide epistemic immunity requires a compressed `Q5/Q1` foundational literacy distribution (`1.45x` vs. NZ's `1.88x`).

### Proof 3: Out-of-Sample Policy Mirages — `1985` *Kotihoidontuki* & `2024–2025` *Asumistuki* Cuts

Two Finnish policy reversals validate `IGWelfare`'s Gate-2 corner and `Document 3` fiscal-mirage predictions:

1. **The `1985` Cash-for-Care Trap (*Kotihoidontuki*, `C06 < 0`):** Paying families a conditional cash allowance *not* to enroll `<3y` toddlers in municipal daycare depressed Finnish `<3y` `ECEC` enrollment to `~40%` (vs. `82%–94%` in Denmark/Sweden and `91%` at ages `3–5` in Finland). In `Compose_Policy_Bundle.m`, adding `kotihoidontuki` (`fi_wave1_to_3_with_kotihoidontuki_drag`) pushes struggling launches back up `+0.23 pp`, while repealing it (`fi25_repeal_kotihoidontuki_only`) trims `Strug%` by `-0.51 pp` in a single generation.
2. **The `2024–2026` Austerity + Unfunded NATO Squeeze (`fi_2024_2026_austerity_plus_nato`):** Cutting general housing allowances (*yleinen asumistuki*), adult-education grants (*aikuiskoulutustuki*), and hospital networks (`Sote`) pushed Finnish single-adult homelessness up **`+20%` in 2024–2025 (`+37%` among under-25 youth)**—reversing a 12-year Housing First decline—while shrinking 2050 `Y_SNA` (`EUR 268.3B -> EUR 249.5B`) and `Y_AtkinsonWaring` (`EUR 259.1B -> EUR 234.6B`).

### Proof 4: Clean Grid & `Kaukolämpö` Exergy Shield vs. `Caruna` Monopoly Reef (`Phase II`)

Comparing `Compute_5Sector_Exergy_Equilibrium.m` across Finland's `1967` fossil-heavy baseline (`70.8%` imported oil/coal) and `2025` nuclear + wind + municipal CHP district-heating grid (`96%` fossil-free electricity at `26 gCO2/kWh`, net fossil imports `EUR 4.40B/yr` = `1.56% GDP`) quantifies the geopolitical value of Second-Law exergy efficiency ($`e_N = 0.88`$ vs. $`e_F = 0.30`$):

| Phase II `2050` Macro-Exergy Outcome | `NZ_Dunedin1972` (`NZD B`) | `FI_Peruskoulu1967` Energy Base (`EUR B`) | `FI_FBC1987` `2025` Clean Grid (`EUR B`) | `FI_FBC1987` + Integrated `SS2` (`EUR B`) |
| :--- | :---: | :---: | :---: | :---: |
| **Annual Fossil Import Bill (`2050`)** | `NZD 21.68B` | `EUR 12.85B` | `EUR 4.69B` (`-EUR 8.16B/yr` saved) | `EUR 1.30B` (`-72.3%` via heat-pump/SMR CHP) |
| **`NFA / Y_SNA` Under Unfunded `3.0% GDP` Defence** | `-89.6%` | `-58.4%` | `-29.8%` *(erodes `+17.0%` init NIIP)* | **`+35.0%`** *(sustains `3.0%` NATO defence)* |
| **Sovereign Yield Under `3.0% GDP` Defence** | `5.48%` | `5.87%` | `4.44%` (**`-143 bps` exergy shield**) | **`2.79%`** (`-165 bps` further spread cut) |
| **Grid Privatization (`Caruna`) vs. Ostrom Turnaround** | `-NZD 176.35B` (`2%` PV) | `-EUR 108.04B` (`2%` PV) | `-EUR 108.04B` (`+EUR 23.55B` cash mirage) | `+EUR 52.43B` (`Yr-10` buyback: `EUR 52.87B`) |

### Proof 5: Why `Aspect 1` Alone Left Finland with `TFR = 1.30`, `88.4%` EDP Debt, & Graduate Emigration

Despite solving `Aspect 1` schooling equity and grid decarbonization, 2025–2026 Finland exhibits `TFR = 1.30`, `88.4%` general government EDP debt,Greater Helsinki housing-cost sorting (`Q_base = 2.45`, driving an endogenous `17.5%` metro struggling rate in the unindexed 5D Bellman baseline), and persistent EU graduate brain drain (`9.55%` solved emigration, peaking at `13.3%` in university cities `Large`).

Our incremental `FI_FBC1987` policy decomposition proves why:
* Repealing *kotihoidontuki* alone (`+C06`) lowers `Strug%` (`7.15% -> 6.64%`) **but moves skilled emigration by `0.00 pp` (`9.66% -> 9.66%`)**.
* Adding **missing `Aspect 2` (`+C23` `1.5%` LVT/estate rotation + `+C24` universal Age-20 Youth Capital Grant)** immediately cuts Finnish skilled emigration **in half (`9.66% -> 4.66%`, `-5.00 pp`)**, cools Helsinki `Q_reg` by `-10.5%`, and delivers **`47.6x` trim-tab gearing** (`TT4`: `EUR 0.16B` seed -> `EUR 7.62B` swing) when paired with `Aspect 3` (`z_h` builder tax shift and `-3.75 pp` working-age labor tax relief).

---

## 3. Structural Economic Innovations Identified for Upstream Merge (`main`)

Cross-validating Finland against New Zealand surfaced seven general economic mechanisms for future upstream `IGWelfare` waves:

1. **Conscript/Reservist Civil-Defence Co-Production (`Sector 5` Waring Channel):** Include `Sector_5_Defence` unpaid reservist FTEs (`28.0 kFTE` in Finland vs. `1.5 kFTE` in NZ) in Ostrom–Waring co-production so universal total-defence models substitute domestic social capital for imported FX defence outlays.
2. **Currency-Union vs. Floating-FX Pass-Through (`FX_Float_PassThrough`):** Parameterize real-exchange-rate shock cushioning between floating inflation-targeters (`NZD = 1.0`) and currency-union members (`EUR = 0.25`, requiring internal wage/fiscal adjustment).
3. **Combined Heat & Power (`CHP`) / Building-Envelope Thermal Exergy (`e_CHP`):** Separate electrical work exergy (`e_N = 0.88`) from district thermal exergy and housing thermal-envelope efficiency (`kaukolämpö` vs. uninsulated NZ dwellings).
4. **Endogenous `LULUCF` Harvest vs. Carbon-Sink Trade-Off:** Couple `Sector 1` forestry harvest intensity directly to net `LULUCF` emissions (capturing Finland's `+9.44 MtCO2e` forest-sink flip alongside NZ's post-2050 *Pinus radiata* age cliff).
5. **Conditional Cash-for-Non-Participation (`Kotihoidontuki` Gate-2 Trap):** Distinguish supply/affordability `ECEC` corners (NZ) from conditional cash-out disincentives that hold `<3y` enrollment down among low-income and immigrant households (Finland/Norway/Germany).
6. **Partially Funded Occupational Pension Buffers (`TyEL` Gross vs. Net Sovereign Debt):** Reconcile gross EDP general government debt (`88.4% GDP`) against ring-fenced earnings-related pension assets (`~48%` net debt) and their embedded payroll tax wedge inside `tau_l`.
7. **Primate-Metro Public Salary Indexation (`nu_col_index`) vs. Land Value Taxation (`C23`):** Allow testing regional public-sector cost-of-living pay supplements against `1.5%` LVT rent cooling in high-`Q_reg` primate cities (`Helsinki` / `Auckland`).