# Document 2B: Intergenerational Welfare Technical Specification — Part B: Coupled General-Equilibrium Synthesis, Calibration, Transition Dynamics, & Supermodular Attribution
*A GPU-Accelerated Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial Overlapping Generations Framework (Sections 5–7: Fiscal & Fertility Incidence, SMM Calibration, Transition Dynamics, & Supermodular Attribution)*

**Author:** Michael Tiemann ([mdtiemann@gmail.com](mailto:mdtiemann@gmail.com))  
**Date:** November 2026 | **Code & Replication Repository:** [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)  
*Companion to [Document 2A](Document%202A.md) (Part A: Micro-Foundations, Core Agent Problems, & Sectoral Operators, Sections 1–4), [Document 2C](Document%202C.md) (Part C: Compositional Policy Algebra, Combinatorial Citizens' Assembly Clearinghouse, Cross-Country Validation, & Master Annexes, Sections 8–12), [Document 1A](Document%201A.md) (Strategic Monograph), [Document 1B](Document%201B.md) (Strategy & Policy Answer Key), [Document 1C](Document%201C.md) (Executive Brief), [Document 2T](Document%202T.md) ("Thick" vs. "Thin" Numbers Tutorial), and [Document 3](Document%203.md) (Leaving Our Silos, Lifting All Boats)*

*Disclaimer:* No people nor organizations mentioned herein have endorsed this work unless stated otherwise. This is the work of the author, and all errors and omissions are his alone.

---

## 5. Post-Hoc Lifecycle Operators: The 6-Gate Fiscal Ledger, Statutory Fiscal Rules, Fertility Bargaining, & 10-Tier Wealth Incidence

### 5.1 The 6-Gate (29-Node) Lifecycle Fiscal Ledger & Cohort-to-Ledger Operator (`Plot_ChildFiscal_SSankey.m`)

To map all private parental commitments, unpaid *whānau* care, adult occupational sorting (`z_l` vs. `z_h`), and public fiscal flows from Birth (`J = 1`) to Retirement (`J = 16` at $`\Delta t = 5`$; `J = 27` at $`\Delta t = 3`$) without cross-account ontological distortion, `Plot_ChildFiscal_SSankey.m` defines vectorized linear integral operators over the solved 5D stationary distribution $`\mu_k(a, h, \theta_c, z, j)`$ and policy arrays `Policy`:

1. *Cohort-Weighted Ribbon Width Identity Across 29 Nodes:* Every node $`i \in \lbrace 1, \dots, 29 \rbrace`$ across Gates $`g \in \lbrace 1, \dots, 6 \rbrace`$ has ribbon thickness equal to its cohort-weighted annual monetary flow (in real 2025 NZD thousands per year per cohort birth, where `1.0` model unit `= 95.0 kNZD/yr`):

$$
\mathrm{Flow}_{g,i}^{\mathrm{cohort}} = p_{g,i} \times c_{g,i}^{\mathrm{cond}}, \qquad p_{g,i} = \int_{S_{g,i}} d\mu_k
$$

2. *Gates 1–3 Childhood 4-Lane Decomposition (Nodes 1–13):* Separates childhood resource flows into four orthogonal accounting lanes exported in `Table14_FiscalLedger_6Gate_Decomp_<Region>.csv`:
   - *Lane A (`LaneA_PrivCash_kNZD`):* Out-of-pocket parental cash $`(1 - s_{\mathrm{sub}})i_c + \theta_{\mathrm{child}}(c_{nd} + r_{h,k} c_H)`$ (**Nodes 4, 8, 13**).
   - *Lane B (`LaneB_WhanauTime_kNZD`):* Imputed parental care and mentoring time $`w_k z_p h_p \ell_{\mathrm{child}}`$ (**Nodes 4, 8, 13**) plus Marilyn Waring's uncounted alloparental *whānau* care buffer $`0.085 K_{\mathrm{wh\bar{a}nau}}(k) w_k z_p h_p`$ rescuing squeezed families in **Node 2** [Ref 47].
   - *Lane C (`LaneC_PubDev_kNZD`):* Universal PPL/BestStart (**Node 3**), public wraparound ECE $`G_{\mathrm{ECE},1}`$ (**Nodes 6–7**), public schooling $`d_2`$ (**Node 11**), and Montessori / *Tuakana–Teina* mentoring $`G_{\mathrm{ECE},2}`$ (**Node 12**).
   - *Lane D (`LaneD_RemedRent_kNZD`):* Tier 3 acute hardship support (**Node 1**), Accommodation Supplement landlord rent capture in **Node 2**, ECE corner benefit need (**Node 5**), household unemployment/truancy remediation (**Node 9**), and cross-income psychosocial CAMHS & ACC ISSC trauma care (**Node 10**, generated via the `[3 x 4]` split operator $`\mathrm{Split}_{3 \to 4}`$ with a 38% clinical persistence floor [Ref 19, 38]).

3. *Gate 4 → Gate 5 Occupational & Enterprise Sorting Operator ($`P_{G4 \to G5}`$, Nodes 14–16 → Nodes 17–21):* Rather than connecting two separate adult fiscal columns (which would conflate working-age infrastructure outlays with retirement tax credits), Gate 4 maps the three Age-20 launch skill tiers ($`p_{G4} \in \mathbb{R}^{1 \times 3}`$, flattened from 7-point *h* via the `[7 x 3]` projection matrix `Tier_Map`) into **five human adult career and enterprise strata at Gate 5 (`J = 8..11`, Ages 30–54, left of the vertical regime-break wave)** via the `[3 x 5]` row-stochastic Guvenen / Murphy-Shleifer-Vishny sorting matrix $`P_{G4 \to G5} = \lbrack (1 - \mathrm{emig}_t) \odot P_{\mathrm{Ret},3 \times 4}, \mathrm{emig}_t \rbrack`$ [Ref 2, 7]:
   - **Node 17:** Chronic Adversity & Benefit/NEET Trap
   - **Node 18:** Domestic Core Workforce & Skilled Trades
   - **Node 19:** Passive Land & Rent Speculation [`z_l` Skew] *(61% of retained top talent in SS0 → 14% in SS1 and 6% in SS2)*
   - **Node 20:** Productive Enterprise Builders [`z_h` Innovators] *(29% of retained top talent in SS0 → 78% in SS1 and 88% in SS2)*
   - **Node 21:** Emigrated Abroad [Trans-Tasman Brain Drain]

4. *Gate 5 → Gate 6 Exact Fiscal Incidence Matrix (`Flow_S5_to_S6`, `[5 x 8]`, Nodes 17–21 → Nodes 22–29):* Across the vertical regime-break wave at `X = 5.0`, the five Gate 5 human career strata map directly—without rescaling—into the **eight annualized adult fiscal accounts at Gate 6 (`J = 10..16`)**, ordered bottom-to-top to match the Fates Sankey:
   - **Bottom 4 Adversarial Exits (Nodes 22–25):** **Node 22** (`Exit 1: State Care Legacy`), **Node 23** (`Exit 2: Avoidable Hosp & CAMHS`), **Node 24** (`Exit 3: Lower-Skill Lost Tax`), and **Node 25** (`Exit 4: Benefit, LOPE & Justice`). When an Exit compresses below `0.45 kNZD/yr` in **SS1/SS2**, a vectorized visual floor (`minExit_Vis_kNZD = 0.45`) preserves the block and ribbon at the bottom with exact unfloored percentages and dollar values labeled `— not to scale`.
   - **Middle Base Outlay vs. Good Tax Credits (Nodes 26–28) & Top Emigration Loss (Node 29):** **Node 26** (`Base Infra, Health & NZ Super`, attributing 10.2 kNZD/yr per retained adult and scaling gross BNZD/yr cohort and stock figures by the regional population share $`\omega_{\mathrm{reg}}`$ = `reg_pop_share`), **Node 27** (`GST, Cap & Estate Tax Pool`), **Node 28** (`Working-Age PAYE Income Tax`), and **Node 29** (`Abroad Brain-Drain Lost Tax`).

5. *Zero-State-Expansion Educator Salary vs. Instructional `FTE` Sub-Ledger (`[2B-Spec-Edu1]`, `Compute_Teacher_Wage_Intensity_Ledger.m`):* Because New Zealand (`PPTA` / `NZEI`) and Finland (`OAJ`) standardize statutory base educator salaries nationally—supplemented only by bounded high-cost-of-living allowances $`\psi_{\mathrm{col}} \max(0, Q_{k,p} / Q_{\mathrm{nat},0} - 1)`$—metropolitan land overvaluation ($`Q_{\mathrm{Auckland}} = 3.10`$) absorbs `Lane C` capitation (**Nodes 6, 7, 11, 12**) via site/lease charges and vacancy/reliever turnover $`\xi_{\mathrm{ovh},k,p} = 1 - (1 - \xi_{\mathrm{ovh},0})(Q_{1,0} / Q_{k,p})^{\nu_{\mathrm{kaiako}}}`$ ($`\nu_{\mathrm{kaiako}} = 0.350`$) rather than higher classroom headcount (`Table26_Teacher_Wage_Vs_FTE_Intensity_<Profile>.csv`, Proposition `[2A-Prop-Factor2]`). Should future international profiles introduce regionally decentralized collective salary schedules, `regions.csv` can expose an explicit regional statutory wage-index column while leaving `ReturnFn_SpatialHH.m` untouched.

### 5.2 Net Fiscal Balance (`Omega_fiscal`), The 2050 Sovereign Debt-Sinking Protocol, & New Zealand Statutory Law

At *Gate 6 (the Annualized Adult Fiscal Ledger, `J = 10..16`, Nodes 22–29)*, the cohort-weighted *Net Fiscal Balance* $`\Omega_{\mathrm{fiscal}}`$ (indicated visually by the single black breakeven bar with gold marker measured upward from the dotted Debit/Credit boundary between **Node 26** and **Node 27**) is:

$$
\Omega_{\mathrm{fiscal}} = \underbrace{\left(\mathrm{Tax}_{\mathrm{GST+Cap+Beq},27} + \mathrm{Tax}_{\mathrm{PAYE},28}\right)}_{\mathrm{Good\ Tax\ Credits\ (Nodes\ 27+28)}} - \underbrace{\left(\mathrm{Burden}_{\mathrm{Exits\ 1,2,4\ (Nodes\ 22,23,25)}} + \mathrm{Outlay}_{\mathrm{Infra+Health+Super},26}\right)}_{\mathrm{Direct\ Crown\ Outlay\ Debits\ (Nodes\ 22,23,25,26)}}
$$

Under the *2050 Sovereign Debt-Sinking & Public Reinvestment Protocol* (`Build_Multiphase_2050_Protocol_Table`), any positive net fiscal surplus $`\Omega_{\mathrm{reform}} = \max(0, \Omega_{\mathrm{fiscal}})`$ is partitioned 50/50 in the centered callout badge between Nodes 27 and 28:

$$
\Omega_{\mathrm{debt}} = 0.50 \, \Omega_{\mathrm{reform}}, \qquad \Omega_{\mathrm{reinv}} = 0.50 \, \Omega_{\mathrm{reform}}
$$

$$
\Delta D_{2050}\left(\mathrm{reg}\right) = \left(\omega_{\mathrm{reg}} N_{\mathrm{births}}\right) \Omega_{\mathrm{debt}} \sum_{\tau=1}^{25} \left(1 + r_{\mathrm{bond}}\right)^{\tau - 1}, \qquad S_{\mathrm{reinv}} = \mu_{\mathrm{infra}} \, \Omega_{\mathrm{reinv}}
$$

with national cohort births $`N_{\mathrm{births}} = 60,000\text{/yr}`$ scaled by the regional population share $`\omega_{\mathrm{reg}} \in (0, 1\rbrack`$ (`reg_pop_share`), sovereign bond yield $`r_{\mathrm{bond}} = 0.042`$, and public infrastructure multiplier $`\mu_{\mathrm{infra}} = 1.65`$.

* **Statutory & Legal Integration Under New Zealand Public Finance Law:**
  1. *Public Finance Act 1989 (Part 2, Sections 26G–26Z — Principles of Responsible Fiscal Management):* Section 26G(1)(a)–(e) mandates that the Crown must *"reduce total debt to prudent levels"* and *"have regard to the likely impact of fiscal strategy on present and future generations."* Under the status quo documented in the Treasury's *He Tirohanga Mokopuna 2025* and March 2026 background papers (*AN 26/01* and *WP 26/01*, where long-run labour productivity growth is downgraded to 0.9%/yr and net core Crown debt reaches ~200% of GDP by 2065 unless average labour tax or GST rises to 32%), the Crown violates intergenerational fiscal prudence on a cash-flow basis. Embedding the **Actuarial Continuation Valuation** ($`\mathcal{V}_{k,t_0}^{(\mathrm{Fiscal})}`$) alongside the *OBEGAL (Operating Balance Before Gains and Losses)* note disclosures and locking 50% of post-breakeven surpluses into $`\Omega_{\mathrm{debt},g}`$ operationalizes Section 26G(1)(e) in statutory Crown accounts.
  2. *Accident Compensation Act 2001 & Generally Accepted Accounting Practice (PBE IPSAS 19 / IFRS 17 Actuarial Provisions):* New Zealand's Crown balance sheet already recognizes the present value of future multi-decade injury rehabilitation liabilities via the ACC Outstanding Claims Liability (NZD 63.6B). Booking the verified reduction in future Oranga Tamariki (*Oranga Tamariki Act 1989*), justice, and hospital remediation liabilities at Gate 2 (`J = 2..3`) and Gate 3 (`J = 5`) applies identical actuarial accounting standards to early childhood hardship prevention.
  3. *Preventative Infrastructure Stewardship (Local Government (Water Services) / Te Waihanga National Infrastructure Plan & The 2026 Moa Point Review):* As documented in the *Independent Crown Review into the Moa Point Wastewater Treatment Plant Failure* (Jaduram et al., Sept 2026), deferring preventative maintenance creates an unsustainable escalation in reactive remediation costs. Ring-fencing $`\Omega_{\mathrm{reinv},g} = 0.50 \Omega_{\mathrm{reform},g}`$ into a statutory Infrastructure & Core Health Endowment prevents short-term operating budgets from raiding capital maintenance.
  4. *New Zealand Superannuation and Retirement Income Act 2001 (Part 1 & Part 2) & Te Tiriti o Waitangi Jurisprudence:* Preserving universal entitlement at Age 65 (`Jr`, and lowering to Age 64 in *SS2*) avoids the severe disparate impact on Māori and Pasifika life-expectancy cohorts that would result from raising the statutory age to 67 or 70, while honoring the *Te Tiriti o Waitangi* principles of active protection (*kaitiakitanga*) and equity across *mokopuna* cohorts (Waitangi Tribunal *Wai 2575 Hauora* and *Wai 2915 Oranga Tamariki* reports).

### 5.3 Cooperative Childcare Bargaining, Hyperbolic Fertility (`FertilityBargaining_Module.m`), & Cao & Li's (2022) Intended-vs.-Realized Fertility Wedge

Following Doepke, Hannusch, Kindermann, and Tertilt (2022) and Cao and Li (2022, *Journal of Population Economics*), couples in fertile brackets $`j \in \lbrace 2, 3, 4 \rbrace`$ with female and male productivity $`(h_f, h_m)`$ and quasi-hyperbolic present-bias parameter $`\beta_{\mathrm{hyp}} = 0.72`$ bargain cooperatively over fertility $`n_f \in \lbrace 0, 1, 2, 3 \rbrace`$. A birth occurs if and only if both partners achieve positive net marital surplus over their outside options:

$$
S_f\left(n_f; Q_k, G_{\mathrm{ECE}}, \theta_{\tau}\right) = u_f\left(c_f\left(n_f\right)\right) + \beta_{\mathrm{hyp}} \delta V_f^{\prime}\left(n_f\right) - \theta_{\tau} \psi_{\mathrm{time}} n_f + \omega_{\mathrm{ECE}} G_{\mathrm{ECE}} n_f - \psi_Q Q_k n_f \ge \underline{U}_f
$$

**Theoretical & Empirical Identification via Jones & Schoonbroodt (2010) and Cao & Li (2022, Propositions 1–5) — Why We Evaluate $`\beta_{\mathrm{hyp}} = 0.72`$ Analytically in `Compute_FiscalSolvency_And_Fertility.m` Rather Than Calling `vfoptions.exoticpreferences = 'QuasiHyperbolic'`:**

**1. Reconciling Dynastic Curvature ($`\eta_c = 2.0 > 1`$) via Jones & Schoonbroodt (2010) & The Intended ($`n^c`$) vs. Realized ($`n^t`$) Fertility Wedge (Cao & Li, 2022):** Standard Barro–Becker (1989) formulations restrict utility to $`U_{t+1} > 0`$ with $`0 < \eta_c < 1`$ (an unrealistically high intertemporal elasticity of substitution), which by Topkis (1998, Ch. 2) forces family size and child utility to be preference complements ($`\partial^2 U_t / \partial n_t \partial U_{t+1} > 0`$) and counterfactually predicts rising fertility as productivity grows [Ref 22, 60]. Following **Jones and Schoonbroodt (2010, *IER* / NBER w13680)** [Ref 22], calibrating CRRA curvature in the standard macroeconomic range ($`\eta_c = 2.0 > 1`$ in `ReturnFn_SpatialHH.m` and $`\sigma_c \in \lbrack 2.0, 2.2 \rbrack > 1`$ in dynastic fertility calibrations, so $`u(c) < 0`$) places dynastic altruism $`\Phi(n) = n^{1-\epsilon} / (1-\epsilon)`$ (equivalently $`g(n) = n^{\eta}`$ with $`\eta = 1 - \epsilon \le 1 - \eta_c < 0`$, i.e., $`\epsilon > 1`$) in the **Topkis substitutes regime** ($`\partial^2 U_t / \partial n_t \partial U_{t+1} < 0`$): higher per-child human-capital continuation value induces families to shift from quantity toward child quality, while direct housing and childcare cost relief ($`\theta_{s,t} \downarrow`$) still lifts realized fertility ($`\partial n_t / \partial \theta_{s,t} < 0`$, Proposition 1.2). Incorporating quasi-hyperbolic discounting ($`\beta \delta^{t^{\prime}-t}`$) into this dynastic structure, Cao and Li (2022, Eqs. 5–6) show that Period-1 *intended fertility* ($`n^c`$) satisfies $`\beta \delta^2 R^2 \Phi(n^c) / n^c = 1`$, whereas Period-2 *time-consistent realized fertility* ($`n^t`$, without a childbearing commitment device) discounts Period-3 dynastic utility $`\Phi(n) V_1(e^{\prime}, b^{\prime})`$ by an additional factor $`\beta_{\mathrm{hyp}}`$, yielding $`(\beta_{\mathrm{hyp}} \delta R)^2 \Phi(n^t) / n^t = 1`$. Dividing the two conditions yields Cao and Li's closed-form identification (*Proposition 5*, p. 997)—where $`\epsilon > 1`$ ($`\eta < 0`$) simultaneously satisfies Jones and Schoonbroodt's concavity restriction and matches New Zealand's empirical ratio between intended family size ($`n^c \approx 2.15`$) and baseline realized Total Fertility Rate ($`n^t = 1.66`$ nationally and `1.49` in Auckland, so $`n^t / n^c \in \lbrack 0.693, 0.772 \rbrack`$) at $`\beta_{\mathrm{hyp}} = 0.72`$:

$$
n^t = n^c \beta_{\mathrm{hyp}}^{1/\epsilon} \Longleftrightarrow \ln\left(n^t\right) = \ln\left(n^c\right) + \frac{1}{\epsilon} \ln\left(\beta_{\mathrm{hyp}}\right)
$$

**2. Exact Separation of Period-2 Fertility Realization from Commitment Savings:** In the VFI Toolkit, enabling `vfoptions.exoticpreferences = 'QuasiHyperbolic'` applies quasi-hyperbolic discounting to every continuous savings choice `aprime` across all `J` ages, requiring dual value functions and more than doubling GPU backward-induction runtime. In New Zealand's institutional setting, compulsory KiwiSaver/Superannuation and mortgage amortization act as commitment devices on lifecycle asset accumulation (`aprime`), whereas no commitment device exists for childbearing ($`n_f`$). Evaluating the extra Period-2 present-bias factor $`\beta_{\mathrm{hyp}} = 0.72`$ directly inside `Compute_FiscalSolvency_And_Fertility.m` analytically replicates Cao and Li's Equation (6) time-consistent fertility wedge at zero additional VFI cost.

**3. Interaction with Credit Constraints (`i_c = 0`) and Spousal Bargaining (Doepke & Tertilt, 2018; Cao & Li, 2022, Sec. 4):** Cao and Li (2022, Proposition 4) show that in a frictionless credit market, present-biased parents substitute child quality for quantity ($`n^t < n^c \Rightarrow e^t > e^c`$), reinforcing Jones and Schoonbroodt's (2010) $`\eta_c > 1`$ quantity–quality substitutability, and note that unmodeled hyperbolic discounting confounds estimates of spousal fertility bargaining [Ref 21, 22]. In our spatial OLG framework, unconstrained urban couples exhibit this quantity-to-quality shift, whereas rent-squeezed low-income households ($`a^{\prime} \ge 0, i_c = 0`$) are prevented by the borrowing constraint from increasing `i_c` until universal First-2000-Days wraparound ($`G_{\mathrm{ECE},1}`$) and the Youth Grant (`E`) relax their Period-2 budget constraint.

**4. Why We Couple `vfoptions.experienceasset = 1` with Analytical Period-2 $`\beta_{\mathrm{hyp}}`$ Evaluation Rather Than Global `vfoptions.exoticpreferences = 'QuasiHyperbolic'`:** While VFI Toolkit natively supports pairing `experienceasset = 1` (for the child's skill stock $`\theta_c`$) with `vfoptions.exoticpreferences = 'QuasiHyperbolic'`, enabling global quasi-hyperbolic discounting applies $`\beta_{\mathrm{hyp}} = 0.72`$ to every continuous choice $`(a^{\prime}, i_c, \ell, I_h)`$ across all `J = 27` ages. Doing so would (i) misattribute the early-childhood `i_c = 0` investment corner to parental myopia rather than binding credit and housing-subsistence constraints ($`\bar{g}_{\mathrm{ECE}} > 0`$), (ii) counterfactually depress mortgage and KiwiSaver wealth accumulation (`aprime`) that are anchored by institutional commitment devices in New Zealand, and (iii) require tracking dual value functions $`(V_j, W_j)`$ under non-monotone Markov-perfect policy gaming across the 60-year transition path. Evaluating the Period-2 fertility continuation objective:

$$W_f(n_f) = u_f(n_f) + \beta_{\mathrm{hyp}} \delta V_f^{\prime}(n_f)$$

directly on the uncommitted fertility margin inside `Compute_FiscalSolvency_And_Fertility.m` (paired with our `experienceasset = 1` child skill law of motion and $`\mathcal{T}_{\mathrm{IG}}`$ dynastic closure) achieves exact mathematical equivalence on the Cao and Li (2022) fertility wedge while keeping the `i_c = 0` hardship corner purely credit- and rent-driven.

### 5.4 Endogenous NZ Superannuation Solvency & The Retirement-Age U-Curve (Ages 60 to 75 in `Compute_FiscalSolvency_And_Fertility.m`)

Let $`D_{A_{\mathrm{super}},t}`$ denote the effective national fiscal dependency ratio of retirees ($`\mathrm{age}_j \ge A_{\mathrm{super}}`$) to working-age taxpayers ($`20 \le \mathrm{age}_j < A_{\mathrm{super}}`$) across the four domestic regions:

$$
D_{A_{\mathrm{super}},t} = \frac{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=J_r}^{J} \int d\mu_{k,t}\left(a, h, z, j\right)}{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=1}^{J_r-1} \int d\mu_{k,t}\left(a, h, z, j\right)}
$$

In a pay-as-you-go universal pension system with replacement benefit $`p_{\mathrm{super}}`$ and consumption-floor top-up $`\underline{c}`$, the required working-age labor tax rate $`\tau_{l,t}^{\mathrm{req}}(A_{\mathrm{super}})`$ needed to maintain New Zealand Superannuation solvency is inversely proportional to average working-age effective earnings base $`\bar{H}_t = \sum_k \omega_{HH,k,t} \int_{j < J_r} w_{k,t} z h \ell \, d\mu_{k,t}`$ and directly proportional to $`D_{A_{\mathrm{super}},t}`$:

$$
\tau_{l,t}^{\mathrm{req}}\left(A_{\mathrm{super}}\right) = \tau_{l,\mathrm{non\text{-}super}} - \underbrace{\Delta \tau_{l,\mathrm{retire}}\left(\psi_{\mathrm{retire},T}\right)}_{\mathrm{85\%\ T_k\ Retirement\ Dividend\ (-0.64\ pp)}} + \frac{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=J_r}^{J} \int \left\lbrack p_{\mathrm{super}} + \underline{c}_{\mathrm{health}}\left(a, h, j\right) \right\rbrack d\mu_{k,t}}{\bar{H}_t}
$$

Sweeping the statutory eligibility age continuously over $`A_{\mathrm{super}} \in \lbrack 60, 75 \rbrack`$ in `FertilityBargaining_Module.m` (`Table8B_SuperAge_UCurve_60to75.csv`) captures the asymmetric demographic, fiscal, and *whānau* trade-offs on both sides of the statutory baseline $`A_{\mathrm{base}} = 65.0`$:

1. **Above Age 65 ($`A_{\mathrm{super}} > 65`$ — The Fiscal Substitution Leak & Whānau Care Squeeze):** When evaluating austerity proposals that raise $`A_{\mathrm{super}}`$ to `67, 70, ..., 75`, the fraction of displaced seniors able to sustain healthy full-time work decays exponentially at rate $`\lambda_{\mathrm{morb},65+} = 0.18\,\mathrm{yr}^{-1}`$ from $`\theta_{\mathrm{healthy},65} = 0.48`$, shifting 52% to 68% of displaced seniors onto Supported Living, Jobseeker hardship, and acute geriatric hospital/ACC care (`phi_geriatric_leak_base = 1.15`, slope `0.085/yr`) while withdrawing grandparent caregiving time at rate $`\eta_{\mathrm{elder}} = 0.09\text{ yr}^{-1}`$ ($`\Phi_{\mathrm{time}}(70) = 0.638`$, a -36.2% loss) and imposing a sandwich elder-care tax-base drag $`\psi_{\mathrm{sandwich}} = 0.35`$ on prime-age adult children:

$$
\Delta \mathrm{NetSavings}_t\left(A_{\mathrm{super}}\right) = \left[1 - \lambda_{\mathrm{leak}}\left(A_{\mathrm{super}}\right)\right] \sum_{k=1}^{4} \omega_{HH,k,t} \int_{65 \le \mathrm{age}(j) < A_{\mathrm{super}}} p_{\mathrm{super}} d\mu_{k,t}^{SS0}
$$

   Consequently, raising the pension age to 70 under status-quo demographics drives the struggling launch share up to 25.4% in Rural and 18.0% in Auckland and pushes required PAYE taxes **up** to 25.00% (22.48% even under *SS2*, wiping out the entire tax cut).
2. **Below Age 65 ($`A_{\mathrm{super}} < 65`$ — The Age-64 Kuia/Whānau Sweet Spot vs. The Age-60 Denominator Wall):** Lowering $`A_{\mathrm{super}}`$ below 65 releases healthy 60-to-64-year-old *kuia*, *koroua*, and aunties into voluntary alloparental support via $`\Phi_{\mathrm{time}}\left(A_{\mathrm{super}}\right) = 1 + 0.16\tanh\left((65 - A_{\mathrm{super}})/1.80\right)`$ (`+8.1%` at Age 64, `+12.9%` at Age 63), while avoided ACC/Supported Living payouts offset $`\omega_{\mathrm{offset},<65} = 0.28`$ (28%) of the gross pension cost at Age 64. Dropping all the way to Age 60 swells the effective dependency ratio to 39.78% (`Required PAYE = 21.05%`), whereas **Age 64 (`18.25% PAYE`, `+24.70% CE`)** and **Age 65 (`17.97% PAYE`, `+24.53% CE`)** form the global welfare and tax-solvency sweet spot.

### 5.5 Joint Income-Wealth Distributional Incidence Across 10 Survey-Anchored Earn + Own Tiers (`Plot_WealthBracket_GiveAndGain.m`)

To evaluate welfare incidence across the empirical joint distribution of gross household income $`Y_m`$ and net worth $`W_m`$ (`Annual Income + Net Worth`, spanning $`M_{\mathrm{tier}} = 10`$ official survey-anchored benchmarks from `Tier 1: NZD 45k + 12k` at P12 to `Tier 10: NZD 6.5M + 140M` at P99.99, anchored to Stats NZ Household Economic Survey June 2024/2025, Rashbrooke 2021, the IRD High-Wealth Individuals Research Project 2023, and the *NBR Rich List*), `Plot_WealthBracket_GiveAndGain.m` decomposes the Consumption-Equivalent welfare change $`\Delta\mathrm{CE}_m\left(\omega_{\mathrm{ent}}\right)`$ as a function of the household's operating-enterprise equity share $`\omega_{\mathrm{ent}} \in \lbrack 0, 1 \rbrack`$ (where $`\omega_{\mathrm{ent}} = 0.80`$ for **Active Growth Entrepreneurs** $`z_f = z_{h,k}`$ and $`\omega_{\mathrm{ent}} = 0.15`$ for **Passive Residential Land Hoarders** $`z_f = z_{\ell,k}`$):

$$
\Delta\mathrm{CE}_m\left(\omega_{\mathrm{ent}}\right) = \underbrace{\left(\Delta\mathrm{CE}_{m,\mathrm{House}} + \Delta\mathrm{CE}_{m,\mathrm{WealthTax}} + \Delta\mathrm{CE}_{m,\mathrm{Estate}}\right)}_{\mathrm{3\ Fiscal\ Give\ Channels}\ \left(\le 0\right)} + \underbrace{\left(\Delta\mathrm{CE}_{m,\mathrm{ECE+Rent}} + \Delta\mathrm{CE}_{m,\mathrm{PAYE}} + \omega_{\mathrm{ent}}\Delta\mathrm{CE}_{m,\mathrm{Firm}} + \Delta\mathrm{CE}_{m,\mathrm{Cohesion}}\right)}_{\mathrm{4\ Economic\ Gain\ Channels}\ \left(> 0\right)}
$$

Because Guvenen et al. (2023) capital reallocation raises the after-tax return on high-productivity operating equity $`\Delta R_k(z_{h,k}) > 0`$ while the -3.75 pp (`22.0% -> 18.25%`, incl. `-0.64 pp` from 85% `Transfer_Geo` retirement) *SS2* PAYE cut and -60 bps interest rate reduction boost disposable cash flow, **100% of households across the bottom 90% (`Tiers 1–5`, up to `P90: 240k + 2.15M`) come out unconditionally ahead (`+3.6% to +25.4% CE`), Active Growth Entrepreneurs remain net welfare positive at `P99` (`+3.6% CE`) and the `IRD High-Wealth Median` (`Tier 9: 2.1M + 50M`, `+1.2% CE`), and break even at the `NBR Rich List Median` (`Tier 10: 6.5M + 140M`, `-0.1% CE`)**. Even on a portfolio-average basis across top-1% wealth holders (`Tiers 8–10`), post-reform retained net worth equals **90.2% to 94.6%** of baseline fortune (and **95.3% to 98.5%** for active business owners)—representing a smaller balance-sheet adjustment than routine once-a-decade macroeconomic drawdowns (1987 equities `-60%`, 2008 GFC equities `-40%` / real house prices `-12%`, and the 2021–2024 RBNZ monetary tightening cycle where real Auckland/Wellington house prices fell `-22% to -27%`).

### 5.6 Three-Tier National-Accounts Scorecard, Ostrom Public-Asset Stewardship, & Paris NDC Exergy Ledger (`Run_Phase2_5Sector_Suite.m`)

Adding `Sectors 4` and `5` ([Document 2A, Section 2.5](Document%202A.md)) exposes a classic pathology in System of National Accounts (`SNA`) reporting: because government and non-profit output lacks market prices and is booked **at paid input cost**, building more prisons (`Exit 4`) or acute hospital wards (`Exit 2`) artificially *inflates* conventional GDP, whereas shifting from expensive state remediation to Ostrom/NGO community co-production makes conventional public GDP appear to *shrink* [Ref 47, 58]. `Compute_ThreeTier_NationalAccounts_Ledger.m` resolves this via three strictly separated scorecards (guaranteed free of double-counting):

| Reporting Tier | Valuation Basis & Accounting Boundary | Analytical Purpose in `IGWelfare` |
| :--- | :--- | :--- |
| **Tier 1: Conventional SNA Market + Input-Cost GDP ($`Y_t^{\mathrm{SNA}}`$)** | Values `Sectors 1–3` at market prices and `Sectors 4–5` strictly at paid input cost ($`w_k H_{G,k} + w_k H_{D,k} + \dots`$), excluding unpaid household/volunteer work (`0%` cash transfers) [Ref 33, 58]. | Preserves exact denominator compatibility with RBNZ and NZ Treasury `LTFM` fiscal ratios (`Net Debt / Y_SNA`, `OBEGAL / Y_SNA`, `Defence % of Y_SNA` [Ref 31, 59]) so orthodox reviewers see the compact passes on conventional metrics alone. |
| **Tier 2: Atkinson–Waring Inclusive Output ($`Y_t^{\mathrm{AW}}`$)** | Following **Atkinson (2005)**, **Stiglitz–Sen–Fitoussi (2009)** [Ref 58], and **Waring (1988)** [Ref 47]: values `Sector 4A` capacitating services by **quality-adjusted human outcomes**, adds imputed household and `79,000-FTE` volunteer co-production ($`w_k^{\mathrm{shadow}} L_{u,k}`$ [Ref 30]), and **subtracts reactive remediation ($`-Y_{G,k}^{\mathrm{rem}}`$)** as a regrettable defensive intermediate cost. | Extends the 4-lane fiscal Sankey (`LaneB_WhanauTime` + `LaneC_PubDev` net of `LaneD_RemedRent`) into a macro National Wellbeing & Care Satellite Account [Ref 47, 50, 58]. |
| **Tier 3: Newborn & Transition Consumption-Equivalent Welfare (`CE%`)** | **Zero double-counting:** `Sector 4` and `Sector 5` spending is *never* added ad hoc to household utility (in-kind `G_ece` relief is bounded by Ferriere et al.'s MRS weight $`\omega_i \le 1`$ [Ref 1]). Civic, exergy, and infrastructure payoffs enter `V_k` **solely through solved general-equilibrium outcomes**: higher adult skill `h`, lower PAYE taxes `tau_l`, cooled rents `Q_k`, lower energy subsistence `e_bar(k)`, and higher social cohesion `S_t`. | Remains the definitive micro-founded welfare criterion across both the 1-sector aggregate benchmark and the 5-sector open-economy equilibrium. |

Alongside the Three-Tier Scorecard, `Compute_Public_Asset_Stewardship_Ledger.m` and `Compute_NDC_Compliance_Ledger.m` close two decisive sovereign balance-sheet loops (`Plot_Phase2_5Sector_Dashboard.m`):

1. **Ostrom Public-Asset Stewardship vs. Distressed Fire-Sale Privatization (`NZD 50B` Network/Grid Block):** Evaluating four governance regimes over a 35-year horizon at Treasury's `2%` Social Rate of Time Preference (`SRTP`) proves that selling distressed natural-monopoly infrastructure (`Sector 4B` water/transport or `Sector 3` grid trunks) for `+NZD 34.8B–35.0B` upfront cash to flatter short-term `OBEGAL` inflicts a **`-NZD 83B` net societal PV** (`-NZD 176.4B` opportunity loss relative to `+NZD 93B` under independent Ostrom/commercial-board public stewardship turnaround) because private monopoly buyers price `M_olig > 1` markups onto households and exporters while imposing an **`NZD 80.7B` Year-10 buyback wall** [Ref 29, 36, 49].
2. **Keen–Labrousse Exergy Dividend & Paris `NDC` Compliance:** Compressing civilian fossil-fuel imports from `~NZD 20B/yr` down to `~NZD 5.5B/yr` via firmed domestic electrification (`e_N = 0.88` vs. `e_F = 0.30`) simultaneously eliminates offshore Paris `NDC` carbon-purchase liabilities [Ref 40] and frees `~NZD 14.5B/yr` in permanent foreign-exchange headroom—more than financing the `+NZD 5B–6B/yr` FX import component of a `3.0% GDP` sovereign defence posture while lifting `NFA_t / Y_t` onto a rising surplus trajectory.

![5-Sector Workforce Release, Exergy FX Dividend, Three-Tier Scorecard, and Public-Asset Stewardship Dashboard](output/NZ_Dunedin1972/Fig_Phase2_5Sector_Exergy_Waring_Dashboard_Dunedin_22.png)

---

### 5.7 Horizon-Normalized 5D Distributional Welfare Integrals (`T2`, `T3`) & Endogenous Dynastic Stage-3 Closure (`Compute_WelfareDecomposition_4Region.m`)

Rather than scaling regional headline welfare by fixed proportionality vectors or exogenous second-generation multipliers, `Compute_WelfareDecomposition_4Region.m` integrates solved 5D value tensors $`V_k(a, h, \theta_c, z, j)`$ directly against stationary household distributions $`\mu_k(a, h, \theta_c, z, j)`$:

1. **Endogenous Dynastic Parental Skill Fixed Point ($`\bar{h}_{p,k}`$ in Stage 3C):** In `HumanCapital_Lifecycle_aprimeFn.m`, child skill production depends on regional parental skill $`\bar{h}_{p,k}`$ (`h_par_mean`). During Stage 3C of reform phase $`m`$, once the initial intergenerational fixed point $`\mu_{k,m}^{(1)}`$ converges under `Policy_GE_Exo`, fertile-cohort mean skill $`\bar{h}_{\mathrm{fert},k,m} = \mathbb{E}_{\mu_{k,m}}\lbrack h \mid j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2} \rbrack`$ updates `P_IG.h_par_mean.(hh_type)` relative to the `SS0` baseline anchor $`\bar{h}_{\mathrm{fert},k,0}`$:

$$
\bar{h}_{p,k,m} = \bar{h}_{p,k,0} \left(\frac{\bar{h}_{\mathrm{fert},k,m}}{\bar{h}_{\mathrm{fert},k,0}}\right)
$$

   `Solve_VFI_PhaseSplit.m` then re-solves Phases 1 and 2 (`ReusePostParenting` reuses Infinite-Horizon Firms and Phases 3–4 identically) and re-converges `jDist_m` via cached sparse Tan push-forward (`Precompute_HH_StationaryCache` + `PushForward_HH_Dist`). Stage-3 Consumption-Equivalent welfare (`T1` rows `3` and `6`) combines private dynastic newborn value $`\mathbb{E}_{\mu_{1,k,m}}\lbrack V_{k,m}(\cdot, 1) \rbrack`$ with the macro relational thriving and youth-retention externality $`\Delta u_{\mathrm{rel},k}`$ (`Build_IntergenTransitionMatrix.m`, weighted by discounted post-launch lifecycle share $`s_{\mathrm{post}}`$):

$$
1 + \frac{\mathrm{CE}_{k,m}^{(3)}}{100} = \left( \frac{\int V_{k,m}(s_1, 1) \, d\mu_{1,k,m}(s_1)}{\int V_{k,0}(s_1, 1) \, d\mu_{1,k,0}(s_1)} \right)^{\frac{1}{\phi_{nd}(1 - \eta_c)}} \exp\left(\frac{\Delta u_{\mathrm{rel},k}}{\phi_{nd}}\right)
$$

2. **Eliminating Remaining-Horizon Composition Bias via Flow Normalization ($`D_{\mathrm{eff}}(j)`$):** Because raw continuation values $`V_k(s, j)`$ sum over $`J - j + 1`$ remaining periods ($`\vert V_{20} \vert \gg \vert V_{60} \vert`$), young households crossing the `20%` LVR deposit threshold when $`Q_k`$ cools would bias unnormalized group means downward purely by shifting younger (longer-horizon) cohorts into the homeowner sub-manifold. Defining the exact remaining discounted horizon factor $`D_{\mathrm{eff}}(j) = \sum_{\tau=j}^{J} \varsigma_{\Delta t} \beta_{hh}^{\tau - j} \prod_{u=j}^{\tau - 1} s_u`$ converts every age slice into horizon-invariant flow certainty-equivalent utility $`\tilde{v}_k(s, j) = V_k(s, j) / D_{\mathrm{eff}}(j)`$ (`= -1 / u_comp` along stationary paths).
3. **Exact Quantile-Split Quintiles (`T2`) & Sub-Grid LVR Tenure Cleavage (`T3`):** Ranking all 5D states by gross period household resources $`y_{\mathrm{rank}}(a, h, z, j)`$ splits cumulative stationary probability mass into exact `20%` quantile bins $`q \in \lbrace 1, \dots, 5 \rbrace`$ (`T2`: `Q1_Bottom20` through `Q5_Top20`) with exact fractional cell overlap at bin boundaries, while sub-grid LVR weights $`w_{\mathrm{rent}}(a_i; 0.20 Q_k)`$ partition working-age (`age < 65`) and retired (`age >= 65`) cohorts into `Young_Renters_Under65`, `Young_Homeowners_Under65`, and `Older_Retirees_65Plus` (`T3`).

---

## 6. Calibration & Two-Stage SMM Identification (`Calibrate_NZ_Moments.m`)

### 6.1 Exact SMM Parameter Identification Matrix (15 Parameters <-> 15 NZ Empirical Moments)

| Parameter | Symbol | Value | Empirical Target Moment & Source | Model Fit |
| :--- | :---: | :---: | :--- | :---: |
| Stage-1 CES Substitution | $`\varphi_1`$ | `0.350` | Cunha, Heckman, & Schennach (2010): Stage-1 elasticity $`\sigma_1 = 1/(1-\varphi_1) = 1.54`$ | Exact |
| Stage-2 CES Complementarity | $`\varphi_2`$ | `-0.950` | Cunha et al. (2010): Stage-2 complementarity $`\sigma_2 = 1/(1-\varphi_2) = 0.51`$ | Exact |
| Parental Skill Persistence | $`\rho_{hc}`$ | `0.420` | Lee & Seshadri (2019) / NZ IDI baseline Intergenerational Elasticity `IGE = 0.350` | `0.350` |
| ECE Stone-Geary Threshold | $`\bar{g}_{\mathrm{ECE}}`$ | `0.032` | Barnardos / GUiNZ share of births in material hardship / $`i_c=0`$ corner (25.8%) | `25.79%` |
| Montessori / *Tuakana* Boost | $`\Delta_{\mathrm{Tuakana}}`$ | `0.110` | Graeme Dingle Foundation (*Stars* / *Project K*) & *Kura* NCEA Level 3 lift (+11 log pts) | `+0.110` |
| Dunedin Acute Cost Weight | $`c_{\mathrm{acute}}`$ | `0.380` | Caspi et al. (2016) Dunedin Study: 22% struggling tier drives 57%–81% of Exits 1, 2, 4 | `74.1%` |
| Rural Transport Subsistence | $`\bar{e}_{\mathrm{Rural}}`$ | `0.048` | Stats NZ HES rural vs. metro mandatory fuel/transport budget share (2.75x) | `2.74x` |
| Auckland Land Supply Factor | $`Q_{\mathrm{Akl},\mathrm{SS0}}`$ | `3.100` | Demographia / Stats NZ Auckland house price-to-income ratio vs. Rural (2.95x) | `2.95x` |
| Renter Down-Payment Cutoff | $`\xi_k`$ | `0.200` | RBNZ LVR 20% deposit rule; Auckland young adult homeownership rate (28.0%) | `28.0%` |
| Firm Collateral Multiplier | $`\lambda_{\mathrm{col}}`$ | `2.500` | Guvenen et al. (2023) / RBNZ SME business credit-to-equity ratio | `2.50` |
| Warm-Glow Bequest Scale | $`b_1`$ | `12.50` | NZ 20-year intergenerational property estate transfer wave (NZD 1.6T) | `NZD 1.6T` |
| Warm-Glow Bequest Threshold | $`b_2`$ | `2.800` | De Nardi (2004) / Stats NZ top-30% estate skewness | `70th pct` |
| Gumbel Migration Scale | $`\varrho_{\mathrm{mig}}`$ | `0.180` | Labrousse & Perdereau (2025, Table 8: $`\rho_G = 0.10`$) / Stillman & Maré (2008, Motu WP 08-06) & Poot (2009, NZ Treasury) age 20–35 trans-Tasman emigration (19.3% Akl / 10.9% Nat.) | `10.93%` |
| Present-Bias Fertility | $`\beta_{\mathrm{hyp}}`$ | `0.720` | Cao & Li (2022, *J. Pop. Econ.*, Prop. 5) / Stats NZ realized vs. intended TFR (1.66 vs. 2.15) | `1.66` |
| Female Childcare Share | $`\theta_{\tau}`$ | `0.680` | Doepke et al. (2022) / Stats NZ Time Use Survey maternal share of childcare | `68.0%` |

---

### 6.2 Two-Stage Sobol + Nelder-Mead SMM Optimization & Welfare-Based In-Kind Imputation (`Calibrate_NZ_Moments.m`)

To discipline the structural parameter vector $`\theta`$ against the 15 empirical New Zealand moments in Table 6.1 without getting trapped in local minima on the multi-region general-equilibrium surface, `Calibrate_NZ_Moments.m` executes a two-stage Simulated Method of Moments (SMM) procedure:

**1. Stage 1 — Sobol Quasi-Random Global Hypercube Pre-Screening:** Following Daruich (2018, Appendix C, Fig. C1), we draw $`N_{\mathrm{sobol}}`$ low-discrepancy Sobol sequence points across the bounded parameter hypercube $`\lbrack \underline{\theta}, \overline{\theta} \rbrack`$ and evaluate the weighted percentage-squared SMM objective function:

$$
\mathcal{L}_{\mathrm{SMM}}\left(\theta\right) = \sum_{m=1}^{M} W_m \left( \frac{\hat{M}_m\left(\theta\right) - M_m^{\mathrm{data}}}{\max\left(0.02, \vert M_m^{\mathrm{data}} \vert\right)} \right)^2
$$

**2. Stage 2 — Bound-Constrained Local Nelder-Mead / Quasi-Newton Refinement:** Starting from the best Sobol candidate $`\theta_{\mathrm{sobol}}^{\star}`$, we apply a logistic sigmoid transformation $`\theta(x) = \underline{\theta} + (\overline{\theta} - \underline{\theta}) \oslash (1 + \exp(-x))`$ and refine $`x^{\star}`$ to convergence via `fminsearch`.

**3. Dual Empirical Calibration Anchor Switch (`'Dunedin_22'` vs. `'MetroSqueeze_GUiNZ'`):** In `Plot_ChildFates_SSankey.m`, `Plot_ChildFiscal_SSankey.m`, and `Plot_ActuarialContinuationValuation.m`, the parameter `Params.Calibration_Anchor` toggles between two empirically validated New Zealand hardship anchors:
- `'Dunedin_22'` *(Default Conservative Anchor):* Calibrates the baseline struggling launch tier ($`h_1\text{--}h_2`$) to the **22.0%** high-cost cohort segment identified at age 3 in the Dunedin Multidisciplinary Health and Development Study (Caspi et al., 2016, where 22% of the cohort drives 57%–81% of adult Exits 1, 2, and 4; model fit = **74.1%**), using housing-crowding penalty $`\psi_{\mathrm{crowd}} = 0.14`$ and grid anchor `+0.265`.
- `'MetroSqueeze_GUiNZ'` *(After-Housing-Cost Metropolitan Squeeze Sensitivity):* Incorporates the full metropolitan housing-cost and dampness/crowding penalty documented in *Growing Up in New Zealand* (Morton et al., 2020: 37% damp/mould exposure) and Child Poverty Related Indicators (29.9% AHC60 child poverty; 34%–37% of children in households spending >30% of income on housing), using $`\psi_{\mathrm{crowd}} = 0.18`$ and grid anchor `+0.105` (expanding Auckland's baseline vulnerable trajectory to 34.0%–36.6%).

**4. Welfare-Based In-Kind ECE Imputation Weights ($`\omega_i`$, Ferriere et al., 2025, Eq. 3):** Because early childhood education and preventative health exhibit a Stone-Geary luxury threshold ($`\bar{g}_{\mathrm{ECE}} = 0.032 > 0`$, macro income elasticity $`\theta \in \lbrack 1.15, 1.38 \rbrack > 1`$), liquidity-constrained parents at the private corner solution (`i_c = 0`, share $`S = \Pr(i_c = 0) \approx 0.258`$) have a high marginal utility of liquid cash ($`\partial u_i / \partial y_i`$) to cover immediate rent (*Q_k*) and transport ($`\bar{e}_k`$). Standard static benefit-incidence studies that value public in-kind spending $`G_{\mathrm{ECE}}`$ at 1-for-1 cash equivalence overstate static redistributive compression by up to 50%. `Calibrate_NZ_Moments.m` computes Ferriere et al.'s exact marginal-rate-of-substitution imputation weight across income quintiles:

$$
\omega_i = \frac{\partial u_i / \partial G_{\mathrm{ECE}}}{\partial u_i / \partial y_i} = \min\left\lbrace \frac{y_i / \bar{y}}{F^{-1}(S)}, 1 \right\rbrace
$$

Even after strictly discounting direct static utility for cash-poor households ($`\omega_i < 1`$ in $`Q_1\text{--}Q_2`$), universal wraparound provision $`G_{\mathrm{ECE}}`$ generates large net positive Consumption-Equivalent welfare gains (`CE`) through two dynamic general-equilibrium channels omitted by static incidence studies: (i) the concave pro-equality societal externality $`X_t`$ and fiscal cost avoidance across Exits 1, 2, and 4, and (ii) the intergenerational human-capital transition operator $`Q_h`$.

---

## 7. Multiphase Transition Path, Actuarial Continuation Valuation, Credibility Blending, & Web SVG Architecture

### 7.1 Exact Multiphase Parameter Vector (`SS0 -> SS1 -> SS2` in `WelfareDecomposition_4Region.m`)

| Parameter Field | Symbol | *SS0* (Status Quo) | *SS1* (Incubation & Reallocation) | *SS2* (2050 Actuarial & Super-64 Harvest) | Structural Role in `ReturnFn_SpatialHH` & `Build_IntergenTransitionMatrix` |
| :--- | :---: | :---: | :---: | :---: | :--- |
| `G_ece` / `G_ece_stage1` | $`G_{\mathrm{ECE},1}`$ | `0.045` | `0.110` | `0.130` | Universal First-2,000-Days in-kind wraparound input; eliminates `i_c = 0` corners |
| `G_ece_stage2` | $`G_{\mathrm{ECE},2}`$ | `0.045` | `0.085` | `0.105` | Universal Stage-2 Montessori / *Tuakana–Teina* & Graeme Dingle mentoring (`J = 5`) |
| `YouthGrant` | *E* | `0.030` | `0.065` | `0.080` | Age-20 (`j = 1`) universal capital endowment relaxing young-adult deposit constraint |
| `super_age` (`Jr`) | $`A_{\mathrm{super}}`$ | `65.0` | `65.0` | **`64.0`** *(or 60..75)* | Statutory NZ Superannuation age (`64.0` global welfare peak, releasing `+8.1%` *Kuia* time boost) |
| `tau_l` (`tau_l_delta`) | $`\tau_l`$ ($`\Delta \tau_l`$) | `0.220` (`0.000`) | `0.220` (`0.000`) | **`0.1825` (`-0.0375`)** | Working-age PAYE labor tax rate (`18.25%` at Super Age 64 incl. `-0.64 pp` from 85% `Transfer_Geo` retirement) |
| `tau_b` | $`\tau_b`$ | `0.150` | `0.180–0.250` | `0.180` | Estate/bequest levy on the NZD 1.6T intergenerational property transfer wave |
| `r_delta` | $`\Delta r`$ | `0.000` | `-0.004` | `-0.006` | Reduction in domestic real interest rate from 50% Sovereign Debt-Sinking Fund |
| `w_mult_vec` *(Endog.)* | $`w_k / w_{k,\mathrm{SS0}}`$ | `[1, 1, 1, 1]` | *Solved (`~1.045–1.048`)* | *Solved (`~1.090–1.097`)* | Endogenous `Solve_Spatial_GE_Loop.m` MPL clearing from Guvenen firm $`Z_k(\Gamma_k)`$, SOE spread cut, & Arrow/exergy lift |
| `Q_mult_vec` *(Endog.)* | $`Q_k / Q_{k,\mathrm{SS0}}`$ | `[1, 1, 1, 1]` | *Solved (`[0.989..0.924]`)* | *Solved (`[0.986..0.902]`)* | Endogenous `Solve_Spatial_GE_Loop.m` Hirano–Toda land capitalization governed by regional `delta_H` & $`\tau_a = 0.015`$ |
| `Frac_struggling` | $`\mathrm{Frac}_{\mathrm{struggling}}`$ | `0.220` | `0.045` | `0.015` | Reduction of $`h_1\text{--}h_2`$ struggling launch share (lifting relational utility $`u_{\mathrm{rel}}`$) |
| `Transfer_Geo` | $`T_k`$ | `[0.015, 0.010, 0.005, 0.000]` | `[0.038, 0.031, 0.025, 0.028]` | **`[0.018, 0.013, 0.008, 0.004]`** | Labrousse–Perdereau *Income* $`\times`$ *Geography* transfer (surges in `SS1`, retires by 85% in `SS2` as `z_l` to `z_h` jobs take over) [Ref 23, 49, 56] |
| `z_mean_shift` | $`\Delta \mu_{z,k}`$ | `[0.000, 0.000, 0.000, 0.000]` | `[+0.024, +0.018, +0.010, +0.006]` | **`[+0.041, +0.031, +0.017, +0.010]`** | Regional `z_l` to `z_h` labor productivity shift from competition reform & `1.60x–2.16x` local food-hub procurement [Ref 49, 56] |

* **Core OLG `SS0` Steady State vs. Pre-Shock `SS0_2023` Policy-Mirage Re-Anchor (`Compose_Policy_Bundle.m`):** Table 6.1 and Table 7.1 report the canonical `NZ_Dunedin1972` general-equilibrium steady-state vector (`Q_k = [1.05, 1.40, 2.05, 3.10]`, `lambda_col = 2.50`, `tau_b = 0.150`, `G_ece_stage2 = 0.045`, `gbar_ece = 0.032`). When scoring incremental `2024–2026` fiscal retrenchments and tax changes (`C01`–`C18` in [Document 2C, Section 8](Document%202C.md)), `Compose_Policy_Bundle(..., 'baseline_2023')` initializes from New Zealand's pre-shock `FY2023` statutory anchor (`Debt_to_GDP_Init = 0.405`, `Q_k_vec = [1.03, 1.37, 2.00, 3.02]`, `lambda_col = 1.800`, `tau_k = 0.250`, `tau_b = 0.000`, `G_ECE_2 = 0.065`, `gbar_ece = 0.020`) so zero-estate-tax and pre-shock debt baselines match `BEFU 2023` exactly.

### 7.2 Post-Hoc Transition Integrals & Actuarial Continuation Valuation Operators (`Plot_CumulativeTransitionPayoffs.m` & `Plot_ActuarialContinuationValuation.m`)

At each transition period $`t = 1, \dots, T_{\mathrm{trans}}`$ ($`\Delta t \in \lbrace 5, 3, 2 \rbrace`$ years spanning 60 years), `Plot_CumulativeTransitionPayoffs.m` integrates four regional and national annual flow series from `StationaryDist_t` ($`\mu_{k,t}`$) and $`\Gamma_{k,t}`$:

$$
\mathcal{I}_{k,t} = \Lambda_{\mathrm{NZD}} \omega_{HH,k,t} \left[ \int_{j \in \mathcal{J}_{c,1} \cup \mathcal{J}_{c,2}} \left(\Delta G_{\mathrm{ECE},k} + s_{\mathrm{sub}} i_{c,t}\right) d\mu_{k,t} + \int_{j=1} E d\mu_{1,k,t} \right]
$$

$$
\mathcal{S}_{k,t} = \max\left(0, B_{k,SS0}^{\mathrm{acute}} - \Lambda_{\mathrm{NZD}} \omega_{HH,k,t} \left[ c_{\mathrm{acute,Dunedin}} \sum_{j=1}^{J_r-1} \sum_{ih=1}^{2} \int_{a,z} d\mu_{k,t}\left(a, h_{ih}, z, j\right) + \int T_{k,t} d\mu_{k,t} \right]\right)
$$

$$
\Delta Y_{k,t} = \max\left(0, \Lambda_{\mathrm{NZD}}\left[ Z_{k,t}\left(\Gamma_{k,t}\right) K_{k,t}^{\alpha_k} H_{k,t}^{1-\alpha_k} - Y_{k,SS0} \right]\right), \qquad \mathcal{F}_{k,t}^{\mathrm{tot}} = \mathcal{S}_{k,t} + \Delta\mathcal{T}_{k,t}
$$

To align transition reporting with New Zealand's Accident Compensation Corporation (ACC) forward liability valuation and New Zealand Treasury Circular 2024/15 Cost-Benefit Analysis (`CBAx`) incidence accounting, `Plot_ActuarialContinuationValuation.m` projects each region's annual flows onto a 1-year `pchip` grid $y \in \{0, 1, \dots, 100\}$ and evaluates the rolling $H = 25$-year **Conditional Continuation Valuation Operator**:

$$
\mathcal{V}_{k,t_0}^{(L)}\left(H; r_{\mathrm{disc}}, \mathcal{A}\right) = \mathcal{C}_{k,\mathrm{realized}}^{(L)}\left(t_0; \mathcal{A}\right) + \left(1 - \alpha_{\mathrm{attr}}\right)\Phi_{\mathrm{pipe}}\left(t_0\right) \sum_{s=1}^{H} \left(\frac{1 + g_{\mathrm{cost}}}{1 + r_{\mathrm{disc}}}\right)^s \left(\psi_{k,0}\right)^s f_{k,t_0+s}^{(L)}\left(\mathcal{A}\right)
$$

with dual Treasury discount rates $`r_{\mathrm{disc}} \in \lbrace 0.020, 0.080 \rbrace`$, real cost-base growth $`g_{\mathrm{cost}} = 0.015`$, attribution haircut $`\alpha_{\mathrm{attr}} = 0.30`$, pipeline maturity $`\Phi_{\mathrm{pipe}}(t_0) = \min(1, t_0 / 15)`$, and regional Markov skill retention $`\lbrack \psi_{\mathrm{Rural},0}, \psi_{\mathrm{Small},0}, \psi_{\mathrm{Large},0}, \psi_{\mathrm{Auckland},0} \rbrack = \lbrack 0.984, 0.984, 0.986, 0.987 \rbrack`$.

Inside the unified policy explorer (`igwelfare_policy_mirage_explorer.html`) and `Plot_LTFM_Coalition_Shock_Mirage.m`, these actuarial continuation series sit alongside standard discounted cash and welfare integrals to form a unified **7-Framework Public-Finance & Actuarial Accounting Translator** (`Lenses 1–7`) evaluated across any active policy subset $`S \subseteq \mathcal{C}`$:

| Framework (`Lens`) | Horizon & Valuation Basis | Discount Schedule | Cross-Lane GE Wedges? | What It Reveals (and What Orthodox Cash Accounting Misses) |
| :--- | :--- | :--- | :---: | :--- |
| **`Lens 1`: 4-Yr `OBEGALx` Cash** (`BEFU` / `PREFU`) | 4-year Crown operating cash window (`FY2024–FY2027`; zero weight beyond Year 4) | Nominal cash | No | Scores the 12 public retrenchments as `+NZD 7.69B` of "fiscal savings" while recording upfront `SS1`/`SS2` investments (`-NZD 5.30B`) purely as short-term deficits |
| **`Lens 2`: Commercial Hurdle `CBA`** | 42-year flow integral (`2024–2065`) | Flat 8.0% real | No (Partial-Eq. Silos) | Erases 71% of multi-decade human-capital and health tails (`-NZD 65.2B` on Full-16 Shocks; `+NZD 61.4B` on Clean `SS2`) |
| **`Lens 3`: Agency Social `CBAx`** | 42-year flow integral (`2024–2065`) | Flat 2.5% real | No (Partial-Eq. Silos) | Exposes isolated long-horizon tails (`-NZD 225.4B` on Full-16 Shocks; `+NZD 260.4B` on Clean `SS2`), but misses all cross-ministry feedbacks |
| **`Lens 4`: Canonical `IGWelfare` GE** | 42-year coupled general-equilibrium integral (`2024–2065`) | Flat 2.5% real | **Yes** (`+30.6%` Shock / `+54%` `SS2` Wedges) | Captures *Kaiako* rent pass-through, Cunha–Heckman dual-gate synergy, Gumbel youth migration, and quadratic debt/PAYE closure (`-NZD 294.4B` Full-16 vs. `+NZD 567.8B` Clean `SS2`) |
| **`Lens 5`: Official NZ Treasury `SRTP` GE** | 42-year coupled general-equilibrium integral (`2024–2065`) | 2.0% real (Yrs 1–30), 1.5% real (Yrs 31+) | **Yes** | Applies official non-commercial Treasury time preference to the coupled GE path (`-NZD 339.4B` Full-16 vs. `+NZD 661.2B` Clean `SS2`) |
| **`Lens 6`: ACC Actuarial Crown Fiscal** (`Circular 2024/15`) | Realized cash to audit year $`t_0`$ (`2028`, `2038`, or `2065`) + rolling $`H = 25`$-yr continuation $`\mathcal{V}_{t_0}^{(\mathrm{Fisc})}`$ | 2.0% real central (8.0% sensitivity; 30% haircut) | **Yes** | Books verified forward remediation cost avoidance plus endogenous tax-base expansion (`+NZD 38.6B` at Year-5 `2028` audit on Clean `SS2` vs. `-NZD 47.4B` on Full-16 Shocks) |
| **`Lens 7`: ACC Economy-Wide `WideGDP`** | Realized output to audit year $`t_0`$ + rolling $`H = 25`$-yr output continuation $`\mathcal{V}_{t_0}^{(\mathrm{GDP})}`$ | 2.0% real central (8.0% sensitivity; 30% haircut) | **Yes** | Quantifies the economy-wide productive output prize net of the 30% causal attribution haircut (`+NZD 108.4B` at Year-5 `2028` audit on Clean `SS2` vs. `-NZD 86.2B` on Full-16 Shocks) |

### 7.3 Multiphase Policy Announcements, Credibility-Weighted Belief Blending, and Logistic Seam Smoothing (`TransPath_4Region_Master.m`)

At each transition period $`t \in \{1, \dots, T_1 - 1\}`$ prior to the Phase-2 (*SS2*) enactment date `T_1` (Year 25), households and firms evaluate the **credibility-blended continuation value** $`\tilde{V}_{k,t+1}`$ inside the backward-induction Bellman operator:

$$
V_{k,t}\left(a, h, z, j\right) = \max_{d_t \in \mathcal{D}} \left\lbrace u_k\left(d_t, a, h, z, j; \Phi(t)\right) + s_j \beta_{hh} \mathbb{E}_{z^{\prime}\mid z}\left[\tilde{V}_{k,t+1}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right)\right] + \left(1 - s_j\right) u_{\mathrm{beq}}\left(a^{\prime}; \tau_b(t)\right) \right\rbrace
$$

$$
\tilde{V}_{k,t+1}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right) = \left(1 - \lambda_{\mathrm{cred}}(t)\right) V_{k,t+1}^{\mathrm{perm,SS1}}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right) + \lambda_{\mathrm{cred}}(t) V_{k,t+1}^{\mathrm{full,SS2}}\left(a^{\prime}, h^{\prime}, z^{\prime}, j+1\right)
$$

Under endogenous actuarial credibility updating, $`\lambda_{\mathrm{cred}}^{\mathrm{actuarial}}(t)`$ updates as a function of the audited ratio of recognised actuarial fiscal return $`\mathcal{V}_{\mathrm{National},t}^{(\mathrm{Fiscal})}(H; r_{0.02})`$ to cumulative investment outlay $`\mathcal{C}_{\mathrm{National,realized}}^{(\mathrm{Inv})}(t)`$:

$$
\lambda_{\mathrm{cred}}^{\mathrm{actuarial}}\left(t\right) = \min\left\lbrace 1, \bar{\lambda}_0 + \left(1 - \bar{\lambda}_0\right)\max\left(0, \frac{\mathcal{V}_{\mathrm{National},t}^{(\mathrm{Fiscal})}\left(H; r_{0.02}\right) / \mathcal{C}_{\mathrm{National,realized}}^{(\mathrm{Inv})}\left(t\right) - 1}{\bar{\chi}_{\mathrm{target}} - 1}\right) \right\rbrace
$$

where $`\bar{\chi}_{\mathrm{target}} = 3.50`$. Because the Year 5 Parliamentary Audit (`t = 1`) already achieves an actuarial coverage multiple of $`35.25 / 9.19 = 3.84 > \bar{\chi}_{\mathrm{target}}`$, publishing the ACC-style actuarial audit at Year 5 drives $`\lambda_{\mathrm{cred}}^{\mathrm{actuarial}}(t) \to 1`$. Finally, to prevent step-function tax arbitrage at seam `T_1`, continuous policy levers follow a logistic phase-in ramp:

$$
\Phi(t) = \Phi_1 + \frac{\Phi_2 - \Phi_1}{1 + \exp\left(-\xi_{\mathrm{ramp}}\left(t - T_1\right)\right)}
$$

### 7.4 Constructive 11-Layer Supermodular Attribution, End-to-End Wedge Mechanics, & 3D LTFM Sinkhole Surface (`Plot_Counterfactuals_And_MirrorInvestments.m` & `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m`)

To decompose the multiphase Consumption-Equivalent welfare trajectory (`T1` rows `SS1_1..3` and `SS2_1..3`) into its underlying isolated policy levers and non-linear dynamic complementarity wedges across cohort entry years $`c \in \lbrack -10, +60 \rbrack`$ and regions $`k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland}, \mathrm{National} \rbrace`$, `Plot_Counterfactuals_And_MirrorInvestments.m` evaluates a sequential Topkis (1998) supermodular policy lattice over the three-tier structural parameter vector:

$$
\Phi = \left(\Phi_{\mathrm{HC}}, \Phi_{\mathrm{Spatial}}, \Phi_{\mathrm{Fiscal}}\right)
$$

Let $`W_k(\Phi)`$ denote the expected lifetime Consumption-Equivalent welfare functional of a newborn cohort launching in region *k* relative to the *SS0* baseline $`\Phi_0`$ (at CRRA curvature $`\eta_c = 2.0`$ in `ReturnFn_SpatialHH.m`):

$$
\mathrm{CE}_k\left(\Phi\right) = \left( \frac{\int V_k\left(a_1, h_1, \theta_{c,1}, z_1, j=1; \Phi\right) d\mu_{1,k}\left(\Phi\right)}{\int V_k\left(a_1, h_1, \theta_{c,1}, z_1, j=1; \Phi_0\right) d\mu_{1,k}\left(\Phi_0\right)} \right)^{\frac{1}{\phi_{nd}\left(1 - \eta_c\right)}} - 1
$$

Rather than relying on an arbitrary path-dependent Shapley residual, `Plot_Counterfactuals_And_MirrorInvestments.m` constructs an **11-Layer Supermodular Hierarchy** (`Table 19`) by evaluating the **7 Isolated Policy Factors** standalone (where equilibrium prices and the newborn distribution respond only to lever *m*) and interleaving the **4 Named Dynamic Complementarity Wedges**:

$$
\Delta \mathrm{CE}_{k,m}^{\mathrm{iso}} \equiv \mathrm{CE}_k\left(\Phi_0 + \Delta \Phi_m\right), \qquad \Delta_{\mathrm{syn},w} \equiv \mathrm{CE}_k\left(A_w \cup B_w\right) - \mathrm{CE}_k\left(A_w\right) - \mathrm{CE}_k\left(B_w\right) > 0
$$

$$
\mathrm{CE}_k^{\mathrm{SS2}} = \underbrace{\sum_{m \in \lbrace 1,2,4,5,6,9,10 \rbrace} \Delta \mathrm{CE}_{k,m}^{\mathrm{iso}}}_{\mathrm{7\ Isolated\ Factors\ (+11.23\ pp,\ 45.5\%\ share)}} + \underbrace{\sum_{w \in \lbrace 3,7,8,11 \rbrace} \Delta \mathrm{CE}_{k,w}^{\mathrm{wedge}}}_{\mathrm{4\ Synergy\ Wedges\ (+13.47\ pp,\ 54.5\%\ share)}} = +24.70\,\mathrm{pp\ CE\ (National)}
$$

#### 7.4.1 Proposition `[2B-Prop-Wedge1]`: Breakdown of Hulten Cost-Share Sufficiency and the Wedge Additionality Identity

Let aggregate steady-state output (or certainty-equivalent welfare) $`Y`$ be generated by a twice-continuously differentiable constant-elasticity-of-substitution (CES) operator over converted factor services $`\mathbf{X} = (X_1, \dots, X_K)`$ with elasticity of substitution $`\sigma \in (0, \infty)`$:

$$
Y(\mathbf{X}) = A \left( \sum_{k=1}^{K} \omega_k X_k^{\frac{\sigma - 1}{\sigma}} \right)^{\frac{\sigma}{\sigma - 1}}, \qquad \sum_{k=1}^{K} \omega_k = 1, \quad \omega_k > 0
$$

Suppose policy lever $`k`$ governs a nominal budget outlay $`B_k = P_k Q_k`$ with baseline output expenditure share $`s_{B,k} = B_k / Y > 0`$, purchasing raw input quantity $`Q_k`$ at unit price/cost index $`P_k`$, which maps into effective factor throughput via a structural conversion multiplier $`\varepsilon_k > 0`$ (capturing thermodynamic conversion efficiency, pedagogical throughput, or unpaid Waring/civic volunteer amplification):

$$
X_k = \varepsilon_k Q_k = \frac{\varepsilon_k B_k}{P_k}
$$

Let $`\eta_k = \frac{\partial \ln Y}{\partial \ln X_k}`$ denote the structural output elasticity of converted factor $`X_k`$, and define the **shadow-to-market wedge** $`\mu_k \ge 0`$ as the ratio of the social marginal product of raw input $`Q_k`$ to its nominal market/fiscal unit price $`P_k`$:

$$
\mu_k = \frac{\varepsilon_k (\partial Y / \partial X_k)}{P_k}
$$

Then:

1. **Exact First-Order Wedge Additionality Identity:** Along any local policy perturbation $`(d B_k, d P_k, d \varepsilon_k)`$ holding $`X_{-k}`$ fixed, the **Hulten Leverage Ratio** $`\Lambda_k^Y = d Y / d B_k = (d \ln Y) / (s_{B,k} \, d \ln B_k)`$ satisfies:

$$
\Lambda_k^Y = \left( \frac{\eta_k}{s_{B,k}} \right) \left( 1 + \frac{d \ln \varepsilon_k - d \ln P_k}{d \ln B_k} \right) = \mu_k \left( 1 + \frac{d \ln \varepsilon_k - d \ln P_k}{d \ln B_k} \right)
$$

2. **Three Degenerate vs. Super-Unitary Regimes:**
   * **Neoclassical Cost-Share Benchmark (Hulten Sufficiency):** If pricing reflects social marginal product ($`\mu_k = 1`$) and both conversion efficiency and unit input prices are invariant to nominal spend ($`d \ln \varepsilon_k = d \ln P_k = 0`$), then $`\eta_k = s_{B,k}`$ and $`\Lambda_k^Y = 1`$.
   * **Baumol / Rent-Capture Attenuation:** Under inelastic factor supply or regional cost-of-living absorption where nominal spending inflates unit prices ($`d \ln P_k / d \ln B_k = \kappa_k \in \lbrack 0, 1 \rbrack`$) without raising conversion efficiency ($`d \ln \varepsilon_k = 0`$), leverage collapses to $`\Lambda_k^Y = \mu_k (1 - \kappa_k)`$, vanishing identically ($`\Lambda_k^Y \to 0`$) under complete price capture ($`\kappa_k \to 1`$).
   * **Complementarity-Amplified Bottleneck & Second-Order Synergy Wedge:** Under strict factor complementarity ($`\sigma < 1`$), for any rationed public or biophysical bottleneck $`X_k`$ undersupplied relative to unconstrained optimum, $`\eta_k > s_{B,k}`$ ($`\mu_k > 1`$), and every pair of distinct bottlenecks $`j \neq k`$ exhibits strictly supermodular cross-partial synergy:

$$
\frac{\partial^2 Y}{\partial X_j \partial X_k} = \frac{1}{\sigma} \frac{\eta_j \eta_k Y}{X_j X_k} > 0
$$

Consequently, simultaneous expansion across complementary bottlenecks $`\mathcal{S} \subseteq \lbrace 1, \dots, K \rbrace`$ generates a strictly positive **Constructive Synergy Wedge** ($`\Delta Y_{\mathcal{S}} - \sum_{k \in \mathcal{S}} \Delta Y_{\lbrace k \rbrace} > 0`$) whose magnitude scales inversely with $`\sigma`$.

---

##### Proof of `[2B-Prop-Wedge1]`

**Part 1 (First-Order Identity and Shadow Wedge Equivalence).**
Differentiating the CES aggregator $`Y(\mathbf{X})`$ with respect to $`X_k`$ yields:

$$
\frac{\partial Y}{\partial X_k} = A^{\frac{\sigma - 1}{\sigma}} \omega_k \left( \frac{Y}{X_k} \right)^{\frac{1}{\sigma}} \implies \eta_k = \frac{X_k}{Y} \frac{\partial Y}{\partial X_k} = A^{\frac{\sigma - 1}{\sigma}} \omega_k \left( \frac{X_k}{Y} \right)^{\frac{\sigma - 1}{\sigma}}
$$

Substituting $`X_k = \varepsilon_k B_k / P_k`$ and $`s_{B,k} = B_k / Y`$ into the ratio $`\eta_k / s_{B,k}`$ establishes exact equivalence with the shadow-to-market wedge $`\mu_k`$:

$$
\frac{\eta_k}{s_{B,k}} = \frac{(X_k / Y)(\partial Y / \partial X_k)}{B_k / Y} = \frac{(\varepsilon_k B_k / P_k)(\partial Y / \partial X_k)}{B_k} = \frac{\varepsilon_k (\partial Y / \partial X_k)}{P_k} = \mu_k
$$

Now take the logarithmic differential of $`X_k = \varepsilon_k B_k P_k^{-1}`$:

$$
d \ln X_k = d \ln \varepsilon_k + d \ln B_k - d \ln P_k
$$

Holding $`X_{-k}`$ constant, $`d \ln Y = \eta_k \, d \ln X_k`$. Dividing both sides by $`s_{B,k} \, d \ln B_k`$ and noting that $`(d \ln Y) / (s_{B,k} \, d \ln B_k) = (d Y / Y) / (d B_k / Y) = d Y / d B_k = \Lambda_k^Y`$ yields:

$$
\Lambda_k^Y = \frac{\eta_k}{s_{B,k}} \frac{d \ln X_k}{d \ln B_k} = \left( \frac{\eta_k}{s_{B,k}} \right) \left( 1 + \frac{d \ln \varepsilon_k - d \ln P_k}{d \ln B_k} \right) = \mu_k \left( 1 + \frac{d \ln \varepsilon_k - d \ln P_k}{d \ln B_k} \right)
$$

**Part 2 (Regime Limits and Supermodular Synergy Wedge).**
1. Under competitive marginal-product pricing ($`P_k = \varepsilon_k \, \partial Y / \partial X_k`$), $`\mu_k = 1 \iff \eta_k = s_{B,k}`$ [Ref 9, 33, 60]. Setting $`d \ln \varepsilon_k = d \ln P_k = 0`$ immediately gives $`\Lambda_k^Y = 1`$.
2. Setting $`d \ln \varepsilon_k = 0`$ and $`d \ln P_k = \kappa_k \, d \ln B_k`$ gives $`\Lambda_k^Y = \mu_k (1 - \kappa_k)`$, which equals $`0`$ at $`\kappa_k = 1`$.
3. Under strict complementarity ($`0 < \sigma < 1`$), the exponent $`\frac{\sigma - 1}{\sigma} < 0`$. Thus $`\eta_k = A^{\frac{\sigma - 1}{\sigma}} \omega_k (X_k / Y)^{\frac{\sigma - 1}{\sigma}}`$ is strictly decreasing in $`X_k / Y`$: as any rationed input $`X_k`$ becomes scarce relative to aggregate output ($`X_k / Y \to 0`$), its structural elasticity $`\eta_k \to 1`$ even as its nominal budget share $`s_{B,k} = P_k Q_k / Y`$ remains bounded or small under statutory rationing or unpriced Waring/volunteer inputs, forcing $`\eta_k / s_{B,k} = \mu_k \gg 1`$.

Finally, differentiating $`\partial Y / \partial X_k = \eta_k Y / X_k`$ with respect to $`X_j`$ ($`j \neq k`$) using $`\partial \ln \eta_k / \partial \ln X_j = -\frac{\sigma - 1}{\sigma} \eta_j`$:

$$
\frac{\partial^2 Y}{\partial X_j \partial X_k} = \frac{Y}{X_k} \frac{\partial \eta_k}{\partial X_j} + \frac{\eta_k}{X_k} \frac{\partial Y}{\partial X_j} = \frac{\eta_j \eta_k Y}{X_j X_k} \left( 1 - \frac{\sigma - 1}{\sigma} \right) = \frac{1}{\sigma} \frac{\eta_j \eta_k Y}{X_j X_k} > 0
$$

By Topkis's Monotonicity / Taylor's Theorem on $`\mathbb{R}_{++}^K`$, strict positivity of all off-diagonal Hessians guarantees that joint policy activation over $`\mathcal{S}`$ ($`\vert \mathcal{S} \vert \ge 2`$) strictly exceeds the sum of isolated single-lever perturbations:

$$
\Delta Y_{\mathcal{S}} - \sum_{k \in \mathcal{S}} \Delta Y_{\lbrace k \rbrace} = \sum_{\substack{j, k \in \mathcal{S} \\ j < k}} \int_{0}^{1} \int_{0}^{1} \frac{\partial^2 Y(\mathbf{X}_0 + u \Delta \mathbf{X}_{\lbrace j \rbrace} + v \Delta \mathbf{X}_{\lbrace k \rbrace})}{\partial X_j \partial X_k} \Delta X_j \Delta X_k \, du \, dv + \mathcal{O}(\Vert \Delta \mathbf{X} \Vert^3) > 0
$$

with first-order cross-synergy scaling proportionally to $`1 / \sigma`$. $`\blacksquare`$

#### 7.4.2 Tier-by-Tier Decomposition of the 11-Layer Hierarchy

* **1. Tier 1 — Dual-Gate Human Capital Stack (+7.33% CE Nat.) & Wedge 1 (`L03_WEDGE1_DualGate_HC_Synergy` = +3.32% CE Nat., 13.4% Share):**
   * *Isolated Factors:* Layer 1 evaluates Gate 1 First-2,000-Days wraparound alone ($`G_{\mathrm{ECE},1}: 0.045 \to 0.130`$ with unscaled mentoring, yielding **+2.46% CE**). Layer 2 evaluates Gate 2 Montessori / *Tuakana–Teina* mentoring alone ($`G_{\mathrm{ECE},2}: 0.045 \to 0.105`$ and $`M_{\mathrm{mentor}} \to 1`$ at baseline $`G_{\mathrm{ECE},1} = 0.045`$, yielding **+1.56% CE**).
   * *Structural Complementarity Mechanism:* In `HumanCapital_Lifecycle_aprimeFn.m`, Stage 1 exhibits high substitutability ($`\varphi_1 = +0.35`$, $`\sigma_1 = 1.54 > 1`$) while Stage 2 operates as a Cunha–Heckman harmonic-mean bottleneck ($`\varphi_2 = -0.95`$, $`\sigma_2 = 0.513 < 1`$) subject to per-step unbanked skill depreciation $`\delta_{\theta,\mathrm{fade}} = 0.14 w_2`$ above $`\theta_{\mathrm{base}} = 0.78`$ alongside the `0.22` adolescent psychosocial/distress hazard base (`lambda_psy_raw` / `Delta_Adol`). The cross-partial derivative of Stage-2 CES skill output $`\theta_c^{\mathrm{ces},2}`$ with respect to retained early skill $`\theta_{c,\mathrm{ret}}`$ and Stage-2 inputs $`X_m \in \lbrace I_{\mathrm{tot},2}, h_p^{\mathrm{safe}} \rbrace`$ is strictly positive:

$$
\frac{\partial^2 \theta_c^{\mathrm{ces},2}}{\partial \theta_{c,\mathrm{ret}} \partial X_m} = \left(1 - \varphi_2\right) \gamma_{2,\mathrm{self}} \gamma_{2,m} \left(\theta_c^{\mathrm{ces},2}\right)^{1 - 2\varphi_2} \left(\theta_{c,\mathrm{ret}} X_m\right)^{\varphi_2 - 1} > 0 \qquad \left(1 - \varphi_2 = 1.95\right)
$$

   * Deploying Layer 1 without Layer 2 (`P0_Early_0to5` in `Counterfactuals_LeeSeshadri_4Region.m`) erodes unbanked early skill gains above $`\theta_{\mathrm{base}}`$ across Stage 2 (`delta_theta_fade = 0.14 w_2` per step; ~22% cumulative adolescent gate erosion) and leaves household/psychosocial distress shocks unbuffered. Deploying Layer 2 without Layer 1 (`P1P2_Late_6to17`) feeds a depleted baseline $`\theta_{c,\mathrm{ret}}`$ from the **25.79%** $`i_c^{\star} = 0`$ birth corner into the $`\varphi_2 = -0.95`$ bottleneck. Deploying both gates jointly arrests unbanked fade-out ($`(1 - M_{\mathrm{trust}})\delta_{\theta,\mathrm{fade}} \to 0`$), activates the downward *tuakana* scaffolding multiplier ($`\kappa_{\mathrm{down}} = 0.15`$), and generates the supermodular residual:

$$
G_{\mathrm{ECE},1}^{\mathrm{eff}} = \left(\kappa_{\mathrm{kaiako}} G_{\mathrm{ECE},1}\right)\left(1 + \kappa_{\mathrm{down}} M_{\mathrm{mentor}}\right) + w_{\mathrm{wh\bar{a}nau},1} K_{\mathrm{wh\bar{a}nau}}^{+}
$$

$$
\Delta \mathrm{CE}_{k,\mathrm{Wedge1}} = \mathrm{CE}_k\left(\Delta G_{\mathrm{ECE},1}, \Delta G_{\mathrm{ECE},2}\right) - \Delta \mathrm{CE}_{k,\mathrm{ECE1}}^{\mathrm{iso}} - \Delta \mathrm{CE}_{k,\mathrm{Tuakana}}^{\mathrm{iso}} = +3.32\,\mathrm{pp\ CE}
$$

* **2. Tier 2 — Spatial, LVR & Enterprise Stack (+5.60% CE Nat.) & Wedge 2 (`L07_WEDGE2_LVR_Whanau_Synergy` = +2.33% CE Nat., 9.4% Share):**
   * *Isolated Factors:* Layer 4 ($`\tau_a = 0.015`$ and $`\tau_b: 0.25 \to 0.18`$, yielding **+2.24% CE**), Layer 5 (universal Age-20 Youth Capital Grant $`E: 0.065 \to 0.080`$, yielding **+0.89% CE**), and Layer 6 (Labrousse–Perdereau spatial transfer $`T_k`$, yielding **+0.15% CE after 82%–85% SS2 transfer retirement** via $`T_k^{\mathrm{SS2}} = T_k^{\mathrm{SS0}} + (1 - \psi_{\mathrm{retire},T})(T_k^{\mathrm{SS1}} - T_k^{\mathrm{SS0}})`$ with $`\psi_{\mathrm{retire},T} = 0.850`$, recycling `-0.64 pp` of PAYE relief into Layer 10 [Ref 49, 56]).
   * *Structural Complementarity Mechanism:* In `ReturnFn_SpatialHH.m` and post-hoc tenure ledgers, young households achieve full LVR deposit access ($`\ell_{\mathrm{LVR}} = 1`$) and transition onto homeowner user cost $`rh_k`$ once initial net worth plus skill-capitalized grant equity clears the Kiyotaki et al. (2024) 20% down-payment hurdle:

$$
a_1 + E_{\mathrm{cap}}\left(h_1, j=1\right) \ge \xi_k Q_k\left(\tau_a, \tau_b\right), \qquad \xi_k = 0.20
$$

   * In high-cost metropolitan markets ($`Q_{\mathrm{Auckland}} = 3.10`$ in *SS0*, requiring $`\xi_k Q_k = 0.620`$), providing $`E = 0.080`$ alone leaves cash-poor young adults below the deposit cliff, while cooling *Q_k* by **-10.5%** via $`\tau_a`$ and $`\tau_b`$ alone lowers the hurdle to `0.555` without supplying the seed equity to cross it. Simultaneously, cooling *Q_k* raises the elder housing stability multiplier $`\Phi_{\mathrm{home}}(p_{\mathrm{super}}, Q_k) = (p_{\mathrm{super}}/0.180)(Q_{k,0}/Q_k)^{0.35} > 1`$, anchoring *kaumātua* and aunties in urban neighborhoods and cutting childhood rental transience. Wedge 2 measures the mass of young households pushed across $`\xi_k Q_k`$ and anchored near extended *whānau* by the joint operation of Layers 4, 5, and 6:

$$
\Delta \mathrm{CE}_{k,\mathrm{Wedge2}} = \mathrm{CE}_k\left(\Phi_{\mathrm{Spatial}}\right) - \left(\Delta \mathrm{CE}_{k,\mathrm{TaxRebal}}^{\mathrm{iso}} + \Delta \mathrm{CE}_{k,E}^{\mathrm{iso}} + \Delta \mathrm{CE}_{k,T}^{\mathrm{iso}}\right) = +2.33\,\mathrm{pp\ CE}
$$

* **3. Tier 3 — Cross-Stack Human Capital × Spatial/Enterprise Interaction (`L08_WEDGE3_CrossStack_HC_x_Spatial` = +5.20% CE Nat., +5.63% Akl, 21.1% Share):**
   * *Structural Complementarity Mechanism:* Wedge 3 is the single largest complementarity term in the model, capturing four general-equilibrium cross-derivatives between the Dual-Gate Human Capital Stack ($`\Phi_{\mathrm{HC}}`$, expanding the thriving $`h_6\text{--}h_7`$ launch share from **23.5% to 65.0%**) and the Spatial/Enterprise Stack ($`\Phi_{\mathrm{Spatial}}`$, shifting the infinite-horizon firm distribution $`\Gamma_k(a_f, z_f)`$ toward high-productivity enterprises $`z_{h,k}`$ and cooling *Q_k*): (i) *Firm–Worker Assortative Matching* in `Solve_Spatial_GE_Loop.m`, where $`\frac{\partial^2 Y_k}{\partial Z_k \partial H_k} = (1 - \alpha_k) K_k^{\alpha_k} H_k^{-\alpha_k} > 0`$; (ii) *Domestic Graduate Retention* in the 4 × 5 Gumbel sorting operator $`\Pi_{\mathrm{mig}}`$, where coupling $`\Phi_{\mathrm{HC}}`$ with $`\Phi_{\mathrm{Spatial}}`$ raises domestic continuation values $`V_{m,t}(a_1 + E - \kappa_{k \to m}, h_1, \theta_{c,1}, z_1, 1)`$ relative to $`V_{\mathrm{Abroad},t}`$, cutting national youth emigration from **10.93% to 7.60%** (~3,550 skilled graduates/yr retained); (iii) *Relief of the Kaiako Housing-Affordability Supply Deflator* $`G_{\mathrm{ECE},s}^{\mathrm{eff}}(Q_k)`$ (formalized in [Document 2T](Document%202T.md)); and (iv) **Regional `z_l` to `z_h` Job Upgrading & Monopsony Relief** ($`\Delta \mu_{z,k} > 0`$, [Ref 49, 56]), where breaking farm-gate wholesale monopsony and anchoring `1.60x–2.16x` local food-hub procurement multipliers shifts rural and provincial workers from low-wage `z_l` draws into high-productivity `z_h` enterprises ($`\frac{\partial^2 Y_k}{\partial \mu_{z,k} \partial H_k} > 0`$), allowing 82%–85% of the SS1 geographic transfer to retire.

$$
\Delta \mathrm{CE}_{k,\mathrm{Wedge3}} = \mathrm{CE}_k\left(\Phi_{\mathrm{HC}} \cup \Phi_{\mathrm{Spatial}}\right) - \mathrm{CE}_k\left(\Phi_{\mathrm{HC}}\right) - \mathrm{CE}_k\left(\Phi_{\mathrm{Spatial}}\right) = +5.20\,\mathrm{pp\ CE\ (Nat.)}, \quad +5.63\,\mathrm{pp\ CE\ (Akl)}
$$

* **4. Tier 4 — Fiscal, Super-64 & 2nd-Generation Dynastic Harvest Stack (+6.56% CE Nat.) & Wedge 4 (`L11_WEDGE4_Fiscal_TFR_2ndGen_Closure` = +2.62% CE Nat., 10.6% Share):**
   * *Isolated Factors:* Layer 9 evaluates the **-60 bps** domestic interest rate reduction ($`\Delta r = -0.006`$) from the 50% Sovereign Debt-Sinking allocation $`\Omega_{\mathrm{debt},t} = 0.50 \Omega_{\mathrm{reform},t}`$ in the national asset-market clearing condition:

$$
\sum_{k=1}^{4} \omega_{F,k} \int \left(k_k\left(a_f, z_f\right) - a_f\right) d\Gamma_{k,t} + B_{\mathrm{gov},t} = \sum_{k=1}^{4} \omega_{HH,k,t} \int a_{\mathrm{fin}} d\mu_{k,t} + B_t^{\ast}
$$

   yielding **+1.25% CE**. Layer 10 evaluates the **-3.75 pp** working-age PAYE tax cut ($`\tau_l: 0.2200 \to 0.1825`$, including `-0.64 pp` funded by retiring 85% of the SS1 geographic transfer) paired with lowering universal NZ Superannuation to Age 64 ($`\Phi_{\mathrm{time}}(64) = 1.081`$, yielding **+2.69% CE**).
   * *Structural Complementarity Mechanism:* Wedge 4 captures the closed-loop dynastic and demographic fixed point at $`t \ge 25`$ (`Jump 2` in `T1` row `SS2_3_LongRun_GE_EndoIntergen`): (i) in `FertilityBargaining_Module.m`, combining universal ECE ($`G_{\mathrm{ECE},1}`$), lower housing user costs ($`Q_k \downarrow`$), the **-3.75 pp** PAYE cut, and the **+8.1%** Age-64 *Kuia/Koroua* time boost lifts cooperative marital bargaining surplus $`S_f(n_f)`$ under hyperbolic discounting ($`\beta_{\mathrm{hyp}} = 0.72`$), raising realized national TFR from **1.66 to 1.87** and stabilizing the OLG fiscal dependency ratio $`D_{\mathrm{super},t}`$; and (ii) in `Build_IntergenTransitionMatrix.m`, the first reformed cohort enters parenthood with stationary distribution $`\mu_{1,k}^{\mathrm{SS2}}`$, transmitting higher parental human capital $`h_p^{\mathrm{safe}}`$ and lower distress incidence into the second generation via $`T_{\mathrm{IG}}: Q_h \times Q_a \times \Pi_{\mathrm{mig}}`$.

Finally, `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m` (`Tables 21 & 22` in [Document 3](Document%203.md)) maps this 11-layer system onto (i) the **3D Macroeconomic Welfare Surface** over Net Core Crown Debt ($`B_{\mathrm{gov}}/Y`$ from **15% to 200%** of GDP) and working-age PAYE tax rates ($`\tau_l`$ from **17% to 34%**) — contrasting the endogenous Treasury LTFM sinkhole (**-16.21% CE** at **185%** debt / **28.2%** PAYE) and an unfunded **3.0%-of-GDP** (**+1.8%** of GDP / **+NZD 8.0B/yr**) defense commitment (**-21.69% CE**) against the *SS1* → *SS2* trajectory (**+24.70% CE**, or **+21.18% CE** while sustaining the **3.0%** GDP defense commitment) — and (ii) the 4 × 4 **Coalition Complementarity Matrix** (`Table 22`), where the **+13.47% CE** sequential wedge total partitions into **+3.32% CE** of intra-Coalition-1 dual-gate synergy (`Wedge 1`) and **+10.15% CE** of off-diagonal inter-coalition wedges (`Wedges 2, 3, and 4`).

### 7.5 Zero-Dependency Interactive HTML5 Explorers: SVG Sankey Serialization (`exportSankeyToHTML.m`) & 5-View Policy Mirage / Actuarial Workbench (`igwelfare_policy_mirage_explorer.html`)
When MATLAB's `SSankey.m` renders gradient ribbons on an axes where `set(ax, 'YDir', 'normal')` is applied post-draw, the internal $`4 \times N_{\mathrm{strips}}`$ normal-offset quad vertices invert the vertical tangent sign $`(-dy, dx)`$, which causes direct vertex polygon exports to exhibit sub-pixel vertical striping and mid-span bowtie pinching on steep diagonal ribbons. `exportSankeyToHTML.m` eliminates both artifacts by extracting only the exact left and right block attachment spans $`\lbrack y_{L,\mathrm{bot}}, y_{L,\mathrm{top}} \rbrack`$ at $`x_L`$ and $`\lbrack y_{R,\mathrm{bot}}, y_{R,\mathrm{top}} \rbrack`$ at $`x_R`$, and reconstructing parallel upper and lower rails over $`\tau \in \lbrack 0, 1 \rbrack`$ via the smooth cosine S-curve $`s(\tau) = \frac{1}{2}(1 - \cos(\pi \tau))`$:

$$
y_{\mathrm{top}}\left(\tau\right) = y_{L,\mathrm{top}} + s\left(\tau\right)\left(y_{R,\mathrm{top}} - y_{L,\mathrm{top}}\right), \qquad y_{\mathrm{bot}}\left(\tau\right) = y_{L,\mathrm{bot}} + s\left(\tau\right)\left(y_{R,\mathrm{bot}} - y_{L,\mathrm{bot}}\right)
$$

Because the vertical thickness at every horizontal station $`\tau \in \lbrack 0, 1 \rbrack`$ satisfies $`y_{\mathrm{top}}(\tau) - y_{\mathrm{bot}}(\tau) = (1 - s(\tau)) H_L + s(\tau) H_R > 0`$, every web SVG `<path>` is strictly non-self-intersecting, smooth, and 10x smaller in file size, while supporting interactive click inspection, collision-avoiding narrative callout placement, and 2-level (`Gate -> Block`) keyboard arrow-key traversal across the full 72-panel (`2 Profiles x 3 Modes x 6 Regions x 2 Ledgers`) `igwelfare_sankey_explorer.html` workbench.

Complementing the cross-sectional Sankey explorer, the standalone client-side HTML5 + Canvas workbench **`igwelfare_policy_mirage_explorer.html`** embeds the complete Convention-2 policy algebra, the lower-triangular `LTFM` snowball debt operator, the exact $`2^m`$ active-lane Shapley–Owen decomposition, and the regional ACC / Treasury Circular 2024/15 continuation valuation operator in zero-dependency JavaScript across five synchronized analytical views: (**View A**) Individual & Logical-Group Multipliers, (**View B**) Colon-Split Sequential Additionality Waterfall & Order-Invariant $`2^m`$ Shapley Attribution, (**View C**) `2023–2065` `LTFM` Debt-Crossover & Welfare Trajectories (contrasting Clean-Base `SS1`/`SS2` against post-2024 "digging out of a hole" recovery paths), (**View D**) the 7-Framework Public-Finance & Actuarial Translator, and (**View E**) Live Policy-Driven Regional & National ACC Actuarial Fiscal and `WideGDP` Continuation Curves.

### 7.6 The 13-Wave *Te Kāhui Waka* Schedule, Coase–North Commissioning Friction, Lucas–Hayashi Adjustment Costs, & Arrow–Deming Learning (`Configure_TimeGrid_Params.m` & `Plot_Doc1D_TeKahuiWakaSequencing.m`)

To evaluate realistic implementation constraints alongside the Decadal Orbital Launch Windows in **Document 1D**, Section 8 of `Configure_TimeGrid_Params.m` and `Plot_Doc1D_TeKahuiWakaSequencing.m` parameterize three operational frictions governing the deployment of program $`m \in \lbrace \mathrm{ECE}_1, \mathrm{Mentor}_2, \mathrm{Grant}_E, \mathrm{Elec}_{\bar{e}} \rbrace`$ across region $`k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland} \rbrace`$:

1. **Coase–North Commissioning Friction ($`\tau_{\mathrm{fric}}(t)`$) & Arrow (1962) / Deming (1986) Inter-Wave Learning ($`\gamma_{\mathrm{learn}} = 0.45`$):** Let $`\mathcal{L}_m(t - 1) = \sum_{\tau=1}^{t-1} \sum_{k^{\prime}} \omega_{k^{\prime}} s_{k^{\prime},m}(\tau)`$ denote cumulative national operational experience accumulated across prior regional waves up to year $`t - 1`$. Commissioning overhead decays exponentially from its Day-1 uncalibrated level $`\tau_{\mathrm{fric},0} = 0.280`$ toward the mature *Whānau Ora* high-trust floor $`\tau_{\mathrm{fric},\min} = 0.035`$ as vanguard waves debug contracting, curriculum translation, and IDI data-sharing protocols.
2. **Lucas (1967) / Hayashi (1982) Quadratic Workforce Bottleneck Penalty ($`\phi_{\mathrm{adj}} = 0.18`$):** Attempting to hire and certify $`\Delta s_{k,m}(t)`$ of a region's *kaiako* and *Tuakana* mentoring workforce in a single year against an inelastic 3-year tertiary training pipeline imposes a quadratic surge penalty $`\phi_{\mathrm{adj}}(\Delta s_{k,m}(t))^2`$.
3. **Consecutive Front-Loading of Electrification Grants (`ebar_elec_relief_share = [0.28, 0.25, 0.18, 0.14]`):** Because `Rural` ($`\bar{e}_k = 0.048`$) and `Small` ($`\bar{e}_k = 0.036`$) households face mandatory transport and energy subsistence floors 2.25x to 3.00x higher than `Auckland` ($`\bar{e}_k = 0.016`$) while `Large` and `Auckland` possess deep private home-equity capital for early adopters to self-fund electrification, public *Rewiring Aotearoa* grants [Ref 46] are deployed in **three consecutive waves to `Rural + Small` first (`Waves 1–3`, reaching 100% provincial coverage at Year 3)**, then **`Large` (`Waves 4–6`)**, and finally **`Auckland` (`Waves 7–9`)**.

Combining local adoption maturation $`(1 - \delta_{\mathrm{adopt}} \exp(-\lambda_{\mathrm{adopt}}(t - t_{k,m}^0)))`$, inter-wave learning, and quadratic bottleneck relief yields the **Effective Delivery Multiplier** $`\eta_{k,m}(t) \in (0, 1\rbrack`$ applied to the statutory reform increments in `Configure_TimeGrid_Params.m` and `WelfareDecomposition_4Region.m`:

$$
\eta_{k,m}\left(t\right) = \left(1 - \delta_{\mathrm{adopt}} e^{-\lambda_{\mathrm{adopt}}\left(t - t_{k,m}^0\right)}\right) \cdot \left\lbrack 1 - \tau_{\mathrm{fric},\min} - \left(\tau_{\mathrm{fric},0} - \tau_{\mathrm{fric},\min}\right) e^{-\gamma_{\mathrm{learn}} \mathcal{L}_m\left(t-1\right)} \right\rbrack \cdot \left\lbrack 1 - \phi_{\mathrm{adj}} \left(\Delta s_{k,m}\left(t\right)\right)^2 \right\rbrack
$$

| **`Params` Field Name** | **Symbol** | **Calibrated Value** | **Structural Role in `Configure_TimeGrid_Params.m` & `WelfareDecomposition_4Region.m`** |
| :--- | :---: | :---: | :--- |
| `Params.Rollout_Mode` | — | `'TeKahuiWaka'` | Toggles `'TeKahuiWaka'` (13-Wave phased rollout), `'SingleShot'` (penalized Day-1 step shock), or `'Frictionless_Textbook'`. |
| `Params.tau_friction_0` | $`\tau_{\mathrm{fric},0}`$ | `0.280` | Day-1 uncalibrated commissioning overhead before inter-wave PDSA learning (`Document 1B, Section 2.4.1`). |
| `Params.tau_friction_floor` | $`\tau_{\mathrm{fric},\min}`$ | `0.035` | Mature *Whānau Ora* / high-trust asymptotic commissioning friction floor. |
| `Params.gamma_learning` | $`\gamma_{\mathrm{learn}}`$ | `0.450` | Arrow–Deming inter-wave learning elasticity wrt cumulative wave experience $`\mathcal{L}_m(t - 1)`$. |
| `Params.phi_adj_bottleneck` | $`\phi_{\mathrm{adj}}`$ | `0.180` | Quadratic workforce surge penalty on $`(\Delta s_{k,m})^2`$ (`0.18` for Single-Shot $`\Delta s = 1`$ vs. `0.02` for *Te Kāhui Waka* $`\Delta s = 1/3`$, an **88.9% reduction**). |
| `Params.delta_adopt_ece` | $`\delta_{\mathrm{adopt}}`$ | `0.220` | Initial local cohort adoption lag amplitude upon wave activation ($`t = t_{k,m}^0`$), converging at rate `lambda_adopt_ece = 0.350`/yr. |
| `Params.ebar_elec_relief_share` | $`\Delta \bar{e}_{\mathrm{elec},k}`$ | `[0.28, 0.25, 0.18, 0.14]` | Net compression of mandatory `ebar_energy` from *Rewiring Aotearoa* electrification grants across `[Rural, Small, Large, Auckland]` [Ref 46]. |
| `Params.eta_delivery_SS1` | $`\eta_k^{\mathrm{SS1}}`$ | `[0.955, 0.955, 0.962, 0.968]` (`TeKahuiWaka`)<br>`[0.835, 0.825, 0.810, 0.795]` (`1Shot`) | Time-averaged Phase 1 delivery yield (`SingleShot` suffers an ~18.5% implementation haircut; *Te Kāhui Waka* recovers >96% yield via PDSA learning). |
| `Params.eta_delivery_SS2` | $`\eta_k^{\mathrm{SS2}}`$ | `[0.985, 0.985, 0.988, 0.990]` (`TeKahuiWaka`)<br>`[0.910, 0.905, 0.895, 0.885]` (`1Shot`) | Time-averaged Phase 2 delivery yield in `SS2`. |
| `Params.s_active_ece_vec` | $`s_{k,\mathrm{ece}}(t)`$ | `{0, 1/3, 2/3, 1}` | Active regional coverage share for Dual-Gate ECE & Mentoring (Waves 1–9), driving convex operator mixing in `Build_IntergenTransitionMatrix.m`. |
| `Params.s_active_ygr_vec` | $`s_{k,\mathrm{ygr}}(t)`$ | `{0, 1/3, 2/3, 1}` | Active regional coverage share for Age-20 Youth Grant *E* (Waves 7–13, launching in Year 7 as Wave-1 adolescent mentees turn Age 20). |
| `Params.s_active_elec_vec` | $`s_{k,\mathrm{elec}}(t)`$ | `{0, 1/3, 2/3, 1}` | Active regional coverage share for Electrification Grants (`Rural+Small` Waves 1–3, `Large` Waves 4–6, `Auckland` Waves 7–9). |

---

### Navigation to Part C, Part A, & Companion Tutorial
* **Continue to [Document 2C (Sections 8–12)](Document%202C.md):** *Part C — Compositional Policy Algebra (`C01`–`C28`), Non-Minimum-Phase Trim-Tab Control, Milgrom–Topkis Combinatorial Citizens' Assembly Clearinghouse (`K01`–`K15`), Cross-Country & Finnish Twin Validation, Consolidated Codebase Manifest, & Master 60-Reference Library.*
* **Back to [Document 2A (Sections 1–4)](Document%202A.md):** *Part A — Micro-Foundations, Guvenen Firms & `Solve_Spatial_GE_Loop`, 5-Sector Exergy SOE, 5D Household Problem, & 4 × 5 Intergenerational Operators.*
* **Companion Tutorial [Document 2T (Sections T1–T7)](Document%202T.md):** *"Thick" vs. "Thin" Numbers in Quantitative Public Policy.*
