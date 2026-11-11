# Document 2B: Intergenerational Welfare Technical Specification — Part B: Coupled General-Equilibrium Synthesis, Calibration, Transition Dynamics, & Supermodular Attribution
*A GPU-Accelerated Mixed Finite/Infinite-Horizon 4-Region + Abroad Spatial Overlapping Generations Framework (Sections 5–10: Pulling All Lanes Together)*

**Author:** Michael Tiemann ([mdtiemann@gmail.com](mailto:mdtiemann@gmail.com))  
**Date:** November 2026 | **Code & Replication Repository:** [github.com/MichaelTiemann/IGWelfare](https://github.com/MichaelTiemann/IGWelfare)  
*Companion to [Document 2A](Document%202A.md) (Part A: Micro-Foundations, Core Agent Problems, & Sectoral Operators, Sections 1–4), [Document 1A](Document%201A.md) (Strategic Monograph), [Document 1B](Document%201B.md) (Strategy & Policy Answer Key), [Document 1C](Document%201C.md) (Executive Brief), [Document 2T](Document%202T.md) ("Thick" vs. "Thin" Numbers Tutorial), and [Document 3](Document%203.md) (Leaving Our Silos, Lifting All Boats)*

*Disclaimer:* No people nor organizations mentioned herein have endorsed this work unless stated otherwise. This is the work of the author, and all errors and omissions are his alone.

---

## 5. Post-Hoc Lifecycle Operators: The 6-Gate Fiscal Ledger, Statutory Fiscal Rules, Fertility Bargaining, & 10-Tier Wealth Incidence

### 5.1 The 6-Gate (29-Node) Lifecycle Fiscal Ledger & Cohort-to-Ledger Operator (`Plot_ChildFiscal_SSankey.m`)

To map all private parental commitments, unpaid *whānau* care, adult occupational sorting ($z_l$ vs. $z_h$), and public fiscal flows from Birth ($J = 1$) to Retirement ($J = 16$) without cross-account ontological distortion, `Plot_ChildFiscal_SSankey.m` defines vectorized linear integral operators over the solved stationary distribution $\mu_k(a, h, z, j)$ and policy arrays `Policy`:

1. *Cohort-Weighted Ribbon Width Identity Across 29 Nodes:* Every node $i \in \{1, \dots, 29\}$ across Gates $g \in \{1, \dots, 6\}$ has ribbon thickness equal to its cohort-weighted annual monetary flow (in real 2025 NZD thousands per year per cohort birth, where $1.0\text{ model unit} = 95.0\text{ kNZD/yr}$):

$$\text{Flow}_{g,i}^{\text{cohort}} = p_{g,i} \times c_{g,i}^{\text{cond}}, \qquad p_{g,i} = \int_{S_{g,i}} d\mu_k$$

2\. *Gates 1–3 Childhood 4-Lane Decomposition (Nodes 1–13):* Separates childhood resource flows into four orthogonal accounting lanes exported in `Table14_FiscalLedger_6Gate_Decomp_<Region>.csv`:
   - *Lane A (`LaneA_PrivCash_kNZD`):* Out-of-pocket parental cash $(1 - s_{\text{sub}})i_c + \theta_{\text{child}}(c_{nd} + r_{h,k} c_H)$ (**Nodes 4, 8, 13**).
   - *Lane B (`LaneB_WhanauTime_kNZD`):* Imputed parental care and mentoring time $w_k z_p h_p \ell_{\text{child}}$ (**Nodes 4, 8, 13**) plus Marilyn Waring's uncounted alloparental *whānau* care buffer $0.085 K_{\text{whānau}}(k) w_k z_p h_p$ rescuing squeezed families in **Node 2** [Ref 47].
   - *Lane C (`LaneC_PubDev_kNZD`):* Universal PPL/BestStart (**Node 3**), public wraparound ECE $G_{\text{ECE},1}$ (**Nodes 6–7**), public schooling $d_2$ (**Node 11**), and Montessori / *Tuakana–Teina* mentoring $G_{\text{ECE},2}$ (**Node 12**).
   - *Lane D (`LaneD_RemedRent_kNZD`):* Tier 3 acute hardship support (**Node 1**), Accommodation Supplement landlord rent capture in **Node 2**, ECE corner benefit need (**Node 5**), household unemployment/truancy remediation (**Node 9**), and cross-income psychosocial CAMHS & ACC ISSC trauma care (**Node 10**, generated via the $[3 × 4]$ split operator $\text{Split}_{3\to 4}$ with a 38% clinical persistence floor [Ref 19, 38]).

3\. *Gate 4 → Gate 5 Occupational & Enterprise Sorting Operator ($P_{G4 \to G5}$, Nodes 14–16 → Nodes 17–21):* Rather than connecting two separate adult fiscal columns (which would conflate working-age infrastructure outlays with retirement tax credits), Gate 4 maps the three Age-20 launch skill tiers ($p_{G4} \in \mathbb{R}^{1 × 3}$, flattened from 7-point $h$ via the $[7 × 3]$ projection matrix `Tier_Map`) into **five human adult career and enterprise strata at Gate 5 ($J = 8\text{–}11$, Ages 30–54, left of the vertical regime-break wave)** via the $[3 × 5]$ row-stochastic Guvenen / Murphy-Shleifer-Vishny sorting matrix $`P_{G4 \to G5} = [(1 - \text{emig}_t) \odot P_{\text{Ret},3 × 4}, \text{emig}_t]`$ [Ref 2, 7]:
   - **Node 17:** Chronic Adversity & Benefit/NEET Trap
   - **Node 18:** Domestic Core Workforce & Skilled Trades
   - **Node 19:** Passive Land & Rent Speculation [$z_l$ Skew] *(61% of retained top talent in SS0 → 14% in SS1 and 6% in SS2)*
   - **Node 20:** Productive Enterprise Builders [$z_h$ Innovators] *(29% of retained top talent in SS0 → 78% in SS1 and 88% in SS2)*
   - **Node 21:** Emigrated Abroad [Trans-Tasman Brain Drain]

4\. *Gate 5 → Gate 6 Exact Fiscal Incidence Matrix (`Flow_S5_to_S6`, $[5 × 8]$, Nodes 17–21 → Nodes 22–29):* Across the vertical regime-break wave at $X = 5.0$, the five Gate 5 human career strata map directly—without rescaling—into the **eight annualized adult fiscal accounts at Gate 6 (*J* = 10–16)**, ordered bottom-to-top to match the Fates Sankey:
   - **Bottom 4 Adversarial Exits (Nodes 22–25):** **Node 22** (`Exit 1: State Care Legacy`), **Node 23** (`Exit 2: Avoidable Hosp & CAMHS`), **Node 24** (`Exit 3: Lower-Skill Lost Tax`), and **Node 25** (`Exit 4: Benefit, LOPE & Justice`). When an Exit compresses below $0.45\text{ kNZD/yr}$ in **SS1/SS2**, a vectorized visual floor (`minExit_Vis_kNZD = 0.45`) preserves the block and ribbon at the bottom with exact unfloored percentages and dollar values labeled `— not to scale`.
   - **Middle Base Outlay vs. Good Tax Credits (Nodes 26–28) & Top Emigration Loss (Node 29):** **Node 26** (`Base Infra, Health & NZ Super`, attributing 10.2 kNZD/yr per retained adult and scaling gross BNZD/yr cohort and stock figures by the regional population share $\omega_{\text{reg}}$ = `reg_pop_share`), **Node 27** (`GST, Cap & Estate Tax Pool`), **Node 28** (`Working-Age PAYE Income Tax`), and **Node 29** (`Abroad Brain-Drain Lost Tax`).

### 5.2 Net Fiscal Balance ($\Omega_{\text{fiscal}}$), The 2050 Sovereign Debt-Sinking Protocol, & New Zealand Statutory Law

At *Gate 6 (the Annualized Adult Fiscal Ledger, *J* = 10–16, Nodes 22–29)*, the cohort-weighted *Net Fiscal Balance* $\Omega_{\text{fiscal}}$ (indicated visually by the single black breakeven bar with gold marker measured upward from the dotted Debit/Credit boundary between **Node 26** and **Node 27**) is:

$$\Omega_{\text{fiscal}} = \underbrace{(\text{Tax}_{\text{GST+Cap+Beq},27} + \text{Tax}_{\text{PAYE},28})}_{\text{Good Tax Credits Collected (Nodes 27+28)}} - \underbrace{(\text{Burden}_{\text{Exits } 1,2,4 \text{ (Nodes 22,23,25)}} + \text{Outlay}_{\text{Infra+Health+Super},26})}_{\text{Direct Crown Outlay Debits (Nodes 22,23,25,26)}}$$

Under the *2050 Sovereign Debt-Sinking & Public Reinvestment Protocol* (`Build_Multiphase_2050_Protocol_Table`), any positive net fiscal surplus $\Omega_{\text{reform}} = \max(0, \Omega_{\text{fiscal}})$ is partitioned 50/50 in the centered callout badge between Nodes 27 and 28:

$$\Omega_{\text{debt}} = 0.50 \, \Omega_{\text{reform}}, \qquad \Omega_{\text{reinv}} = 0.50 \, \Omega_{\text{reform}}$$

$$\Delta D_{2050}(\text{reg}) = (\omega_{\text{reg}} N_{\text{births}}) \, \Omega_{\text{debt}} \sum_{\tau=1}^{25} (1 + r_{\text{bond}})^{\tau - 1}, \qquad S_{\text{reinv}} = \mu_{\text{infra}} \, \Omega_{\text{reinv}}$$

with national cohort births $N_{\text{births}} = 60,000/\text{yr}$ scaled by the regional population share $\omega_{\text{reg}} \in (0, 1]$ (`reg_pop_share`), sovereign bond yield $r_{\text{bond}} = 0.042$, and public infrastructure multiplier $\mu_{\text{infra}} = 1.65$.

* **Statutory & Legal Integration Under New Zealand Public Finance Law:**
  1. *Public Finance Act 1989 (Part 2, Sections 26G–26Z — Principles of Responsible Fiscal Management):* Section 26G(1)(a)–(e) mandates that the Crown must *"reduce total debt to prudent levels"* and *"have regard to the likely impact of fiscal strategy on present and future generations."* Under the status quo documented in the Treasury's *He Tirohanga Mokopuna 2025* and March 2026 background papers (*AN 26/01* and *WP 26/01*, where long-run labour productivity growth is downgraded to 0.9%/yr and net core Crown debt reaches ~200% of GDP by 2065 unless average labour tax or GST rises to 32%), the Crown violates intergenerational fiscal prudence on a cash-flow basis. Embedding the **Actuarial Continuation Valuation** ($`\mathcal{V}_{k,t_0}^{(\mathrm{Fiscal})}`$) alongside the *OBEGAL (Operating Balance Before Gains and Losses)* note disclosures and locking 50% of post-breakeven surpluses into $`\Omega_{\mathrm{debt},g}`$ operationalizes Section 26G(1)(e) in statutory Crown accounts.
  2. *Accident Compensation Act 2001 & Generally Accepted Accounting Practice (PBE IPSAS 19 / IFRS 17 Actuarial Provisions):* New Zealand's Crown balance sheet already recognizes the present value of future multi-decade injury rehabilitation liabilities via the ACC Outstanding Claims Liability (NZD 63.6B). Booking the verified reduction in future Oranga Tamariki (*Oranga Tamariki Act 1989*), justice, and hospital remediation liabilities at Gate 2 ($J = 2\text{--}3$) and Gate 3 (`J = 5`) applies identical actuarial accounting standards to early childhood hardship prevention.
  3. *Preventative Infrastructure Stewardship (Local Government (Water Services) / Te Waihanga National Infrastructure Plan & The 2026 Moa Point Review):* As documented in the *Independent Crown Review into the Moa Point Wastewater Treatment Plant Failure* (Jaduram et al., Sept 2026), deferring preventative maintenance creates an unsustainable escalation in reactive remediation costs. Ring-fencing $\Omega_{\mathrm{reinv},g} = 0.50 \Omega_{\mathrm{reform},g}$ into a statutory Infrastructure & Core Health Endowment prevents short-term operating budgets from raiding capital maintenance.
  4. *New Zealand Superannuation and Retirement Income Act 2001 (Part 1 & Part 2) & Te Tiriti o Waitangi Jurisprudence:* Preserving universal entitlement at Age 65 (`Jr`, and lowering to Age 64 in *SS2*) avoids the severe disparate impact on Māori and Pasifika life-expectancy cohorts that would result from raising the statutory age to 67 or 70, while honoring the *Te Tiriti o Waitangi* principles of active protection (*kaitiakitanga*) and equity across *mokopuna* cohorts (Waitangi Tribunal *Wai 2575 Hauora* and *Wai 2915 Oranga Tamariki* reports).

### 5.3 Cooperative Childcare Bargaining, Hyperbolic Fertility (`FertilityBargaining_Module.m`), & Cao & Li's (2022) Intended-vs.-Realized Fertility Wedge

Following Doepke, Hannusch, Kindermann, and Tertilt (2022) and Cao and Li (2022, *Journal of Population Economics*), couples in fertile brackets
$j \in \lbrace 2, 3, 4 \rbrace$
with female and male productivity
$(h_f, h_m)$
and quasi-hyperbolic present-bias parameter
$\beta_{\mathrm{hyp}} = 0.72$
bargain cooperatively over fertility
$n_f \in \lbrace 0, 1, 2, 3 \rbrace$.
A birth occurs if and only if both partners achieve positive net marital surplus over their outside options:

$$
S_f(n_f; Q_k, G_{\mathrm{ECE}}, \theta_\tau) = u_f(c_f(n_f)) + \beta_{\mathrm{hyp}} \delta V'_f(n_f) - \theta_\tau \psi_{\mathrm{time}} n_f + \omega_{\mathrm{ECE}} G_{\mathrm{ECE}} n_f - \psi_Q Q_k n_f \ge \underline{U}_f
$$

**Theoretical & Empirical Identification via Cao & Li (2022, Propositions 1–5) — Why We Evaluate $\beta_{\mathrm{hyp}} = 0.72$ Analytically in `FertilityBargaining_Module.m` Rather Than Calling `vfoptions.exoticpreferences = 'QuasiHyperbolic'`:**

**1. The Intended ($n^c$) vs. Realized ($n^t$) Fertility Wedge (Cao & Li, 2022, Propositions 1, 2, & 5):** Incorporating quasi-hyperbolic discounting ($\beta \delta^{t'-t}$) into a dynamic Barro–Becker overlapping generations model with altruism
$\Phi(n) = \frac{n^{1-\epsilon}}{1-\epsilon}$,
Cao and Li (2022, Eqs. 5–6) show that when young adults formulate their *intended fertility plan* in Period 1 (*the commitment problem*, $n^c$), steady-state fertility satisfies
$\beta \delta^2 R^2 \frac{\Phi(n^c)}{n^c} = 1$,
whereas when they reach the active childbearing window in Period 2 without a commitment device (*the time-consistent / realized problem*, $n^t$), they discount the Period-3 dynastic utility of children
$\Phi(n)V_1(e', b')$
by an *additional factor of* $\beta$, yielding
$(\beta \delta R)^2 \frac{\Phi(n^t)}{n^t} = 1$.
Dividing the two steady-state conditions yields Cao and Li's closed-form identification equation (*Proposition 5*, p. 997). Matching New Zealand's gap between intended family size ($n^c \approx 2.15$) and baseline realized Total Fertility Rate ($n^t = 1.66$ nationally and 1.49 in Auckland, so $n^t / n^c \in [0.693, 0.772]$) pins down the effective hyperbolic fertility discount factor at
$\beta_{\mathrm{hyp}} = 0.72$:

$$
n^t = n^c \beta_{\mathrm{hyp}}^{1/\epsilon} \Longleftrightarrow \ln(n^t) = \ln(n^c) + \frac{1}{\epsilon} \ln(\beta_{\mathrm{hyp}})
$$

**2. Exact Separation of Period-2 Fertility Realization from Commitment Savings:** In the VFI Toolkit, enabling `vfoptions.exoticpreferences = 'QuasiHyperbolic'` applies quasi-hyperbolic discounting to every continuous savings choice `a'` across all *J* ages, requiring dual value functions and more than doubling GPU backward-induction runtime. In New Zealand's institutional setting, compulsory KiwiSaver/Superannuation and mortgage amortization act as commitment devices on lifecycle asset accumulation (`a'`), whereas no commitment device exists for childbearing
($n_f$).
Evaluating the extra Period-2 present-bias factor
$\beta_{\mathrm{hyp}} = 0.72$
directly inside `FertilityBargaining_Module.m` analytically replicates Cao and Li's Equation (6) time-consistent fertility wedge at zero additional VFI cost.

**3. Interaction with Credit Constraints (`i_c = 0`) and Spousal Bargaining (Doepke & Tertilt, 2018; Cao & Li, 2022, Sec. 4):** Cao and Li (2022, Proposition 4) show that in a frictionless credit market, present-biased parents substitute child quality for quantity
($n^t < n^c \Rightarrow e^t > e^c$),
and note that unmodeled hyperbolic discounting confounds estimates of spousal fertility bargaining (Doepke & Tertilt, 2018). In our spatial OLG framework, unconstrained urban couples exhibit Cao and Li's quantity-to-quality shift, whereas rent-squeezed low-income households
($a' \ge 0, i_c = 0$)
are prevented by the borrowing constraint from increasing
`i_c`
until universal First-2000-Days wraparound
($G_{\mathrm{ECE},1}$)
and the Youth Grant (*E*) relax their Period-2 budget constraint.

**4. Why We Couple `vfoptions.experienceasset = 1` with Analytical Period-2 $\beta_{\mathrm{hyp}}$ Evaluation Rather Than Global `vfoptions.exoticpreferences = 'QuasiHyperbolic'`:** While VFI Toolkit natively supports pairing `experienceasset = 1` (for the child's skill stock
$\theta_c$)
with `vfoptions.exoticpreferences = 'QuasiHyperbolic'`, enabling global quasi-hyperbolic discounting applies
$\beta_{\mathrm{hyp}} = 0.72$
to every continuous choice
$(a', i_c, \ell, I_h)$
across all `J = 27` ages. Doing so would (i) misattribute the early-childhood
`i_c = 0`
investment corner to parental myopia rather than binding credit and housing-subsistence constraints
($\bar{g}_{\mathrm{ECE}} > 0$),
(ii) counterfactually depress mortgage and KiwiSaver wealth accumulation (`a'`) that are anchored by institutional commitment devices in New Zealand, and (iii) require tracking dual value functions
$(V_j, W_j)$
under non-monotone Markov-perfect policy gaming across the 60-year transition path. Evaluating the Period-2 fertility continuation objective:

$$
W_f(n_f) = u_f(n_f) + \beta_{\mathrm{hyp}} \delta V'_f(n_f)
$$

directly on the uncommitted fertility margin inside `FertilityBargaining_Module.m` (paired with our `experienceasset = 1` child skill law of motion and
$\mathcal{T}_{\mathrm{IG}}$
dynastic closure) achieves exact mathematical equivalence on the Cao and Li (2022) fertility wedge while keeping the
`i_c = 0`
hardship corner purely credit- and rent-driven.

### 5.4 Endogenous NZ Superannuation Solvency & The Retirement-Age U-Curve ($A_{\mathrm{super}} \in [60, 75]$ in `FertilityBargaining_Module.m`)

Let $`D_{A_{\mathrm{super}},t}`$ denote the effective national fiscal dependency ratio of retirees ($`\mathrm{age}_j \ge A_{\mathrm{super}}`$) to working-age taxpayers ($`20 \le \mathrm{age}_j < A_{\mathrm{super}}`$) across the four domestic regions:

$$
D_{A_{\mathrm{super}},t} = \frac{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=J_r}^{J} \int d\mu_{k,t}\left(a, h, z, j\right)}{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=1}^{J_r-1} \int d\mu_{k,t}\left(a, h, z, j\right)}
$$

In a pay-as-you-go universal pension system with replacement benefit $`p_{\mathrm{super}}`$ and consumption-floor top-up $\underline{c}$, the required working-age labor tax rate $`\tau_{l,t}^{\mathrm{req}}\left(A_{\mathrm{super}}\right)`$ needed to maintain New Zealand Superannuation solvency is inversely proportional to average working-age human capital $`\bar{H}_t = \sum_k \omega_{HH,k,t} \int_{j < J_r} w_{k,t} z h \ell_{\mathrm{eff}} d\mu_{k,t}`$ and directly proportional to $`D_{A_{\mathrm{super}},t}`$:

$$
\tau_{l,t}^{\mathrm{req}}\left(A_{\mathrm{super}}\right) = \tau_{l,\mathrm{non-super}} - \underbrace{\Delta \tau_{l,\mathrm{retire}}(\psi_{\mathrm{retire},T})}_{\text{85\% } T_k \text{ Retirement Dividend } (-0.64\text{ pp})} + \frac{\sum_{k=1}^{4} \omega_{HH,k,t} \sum_{j=J_r}^{J} \int \left[p_{\mathrm{super}} + \underline{c}_{\mathrm{health}}\left(a, h, j\right)\right] d\mu_{k,t}}{\bar{H}_t}
$$

Sweeping the statutory eligibility age continuously over $`A_{\mathrm{super}} \in [60, 75]`$ in `FertilityBargaining_Module.m` (`Table8B_SuperAge_UCurve_60to75.csv`) captures the asymmetric demographic, fiscal, and *whānau* trade-offs on both sides of the statutory baseline $`A_{\mathrm{base}} = 65.0`$:

1. **Above Age 65 ($`A_{\mathrm{super}} > 65`$ — The Fiscal Substitution Leak & Whānau Care Squeeze):** When evaluating austerity proposals that raise $`A_{\mathrm{super}}`$ to $67, 70, \dots, 75$, the fraction of displaced seniors able to sustain healthy full-time work decays exponentially at rate $`\lambda_{\mathrm{morb},65+} = 0.18\text{ yr}^{-1}`$ from $`\theta_{\mathrm{healthy},65} = 0.48`$, shifting 52% to 68% of displaced seniors onto Supported Living, Jobseeker hardship, and acute geriatric hospital/ACC care (`phi_geriatric_leak_base = 1.15`, slope `0.085/yr`) while withdrawing grandparent caregiving time at rate $`\eta_{\mathrm{elder}} = 0.09\text{ yr}^{-1}`$ ($`\Phi_{\mathrm{time}}(70) = 0.638`$, a -36.2% loss) and imposing a sandwich elder-care tax-base drag $`\psi_{\mathrm{sandwich}} = 0.35`$ on prime-age adult children:

$$
\Delta \mathrm{NetSavings}_t\left(A_{\mathrm{super}}\right) = \left[1 - \lambda_{\mathrm{leak}}\left(A_{\mathrm{super}}\right)\right] \sum_{k=1}^{4} \omega_{HH,k,t} \int_{65 \le \mathrm{age}(j) < A_{\mathrm{super}}} p_{\mathrm{super}} d\mu_{k,t}^{SS0}
$$

   Consequently, raising the pension age to 70 under status-quo demographics drives the struggling launch share up to 25.4% in Rural and 18.0% in Auckland and pushes required PAYE taxes **up** to 25.00% (22.48% even under *SS2*, wiping out the entire tax cut).
2. **Below Age 65 ($`A_{\mathrm{super}} < 65`$ — The Age-64 Kuia/Whānau Sweet Spot vs. The Age-60 Denominator Wall):** Lowering $`A_{\mathrm{super}}`$ below 65 releases healthy 60-to-64-year-old *kuia*, *koroua*, and aunties into voluntary alloparental support via $`\Phi_{\mathrm{time}}\left(A_{\mathrm{super}}\right) = 1 + 0.16\tanh\left((65 - A_{\mathrm{super}})/1.80\right)`$ (`+8.1%` at Age 64, `+12.9%` at Age 63), while avoided ACC/Supported Living payouts offset $`\omega_{\mathrm{offset},<65} = 0.28`$ (28%) of the gross pension cost at Age 64. Dropping all the way to Age 60 swells the effective dependency ratio to 39.78% (`Required PAYE = 21.05%`), whereas **Age 64 (`18.25% PAYE`, `+24.70% CE`)** and **Age 65 (`17.97% PAYE`, `+24.53% CE`)** form the global welfare and tax-solvency sweet spot.

### 5.5 Joint Income-Wealth Distributional Incidence Across 10 Survey-Anchored Earn + Own Tiers (`Plot_WealthBracket_GiveAndGain.m`)

To evaluate welfare incidence across the empirical joint distribution of gross household income $`Y_m`$ and net worth $`W_m`$ (`Annual Income + Net Worth`, spanning $`M_{\mathrm{tier}} = 10`$ official survey-anchored benchmarks from `Tier 1: NZD 45k + 12k` at P12 to `Tier 10: NZD 6.5M + 140M` at P99.99, anchored to Stats NZ Household Economic Survey June 2024/2025, Rashbrooke 2021, the IRD High-Wealth Individuals Research Project 2023, and the *NBR Rich List*), `Plot_WealthBracket_GiveAndGain.m` decomposes the Consumption-Equivalent welfare change $`\Delta\mathrm{CE}_m\left(\omega_{\mathrm{ent}}\right)`$ as a function of the household's operating-enterprise equity share $`\omega_{\mathrm{ent}} \in [0, 1]`$ (where $`\omega_{\mathrm{ent}} = 0.80`$ for **Active Growth Entrepreneurs** $`z_f = z_{h,k}`$ and $`\omega_{\mathrm{ent}} = 0.15`$ for **Passive Residential Land Hoarders** $`z_f = z_{\ell,k}`$):

$$
\Delta\mathrm{CE}_m\left(\omega_{\mathrm{ent}}\right) = \underbrace{\left(\Delta\mathrm{CE}_{m,\mathrm{House}} + \Delta\mathrm{CE}_{m,\mathrm{WealthTax}} + \Delta\mathrm{CE}_{m,\mathrm{Estate}}\right)}_{\text{3 Fiscal Give Channels }\left(\le 0\right)} + \underbrace{\left(\Delta\mathrm{CE}_{m,\mathrm{ECE+Rent}} + \Delta\mathrm{CE}_{m,\mathrm{PAYE}} + \omega_{\mathrm{ent}}\Delta\mathrm{CE}_{m,\mathrm{Firm}} + \Delta\mathrm{CE}_{m,\mathrm{Cohesion}}\right)}_{\text{4 Economic Gain Channels }\left(> 0\right)}
$$

Because Guvenen et al. (2023) capital reallocation raises the after-tax return on high-productivity operating equity $\Delta R_k\left(z_{h,k}\right) > 0$ while the -3.75 pp (`22.0% -> 18.25%`, incl. `-0.64 pp` from 85% `Transfer_Geo` retirement) *SS2* PAYE cut and -60 bps interest rate reduction boost disposable cash flow, **100% of households across the bottom 90% (`Tiers 1–5`, up to `P90: 240k + 2.15M`) come out unconditionally ahead (`+3.6% to +25.4% CE`), Active Growth Entrepreneurs remain net welfare positive at `P99` (`+3.6% CE`) and the `IRD High-Wealth Median` (`Tier 9: 2.1M + 50M`, `+1.2% CE`), and break even at the `NBR Rich List Median` (`Tier 10: 6.5M + 140M`, `-0.1% CE`)**. Even on a portfolio-average basis across top-1% wealth holders (`Tiers 8–10`), post-reform retained net worth equals **90.2% to 94.6%** of baseline fortune (and **95.3% to 98.5%** for active business owners)—representing a smaller balance-sheet adjustment than routine once-a-decade macroeconomic drawdowns (1987 equities `-60%`, 2008 GFC equities `-40%` / real house prices `-12%`, and the 2021–2024 RBNZ monetary tightening cycle where real Auckland/Wellington house prices fell `-22% to -27%`).
| `z_mean_shift` | $\Delta \mu_{z,k}$ | `[0.000, 0.000, 0.000, 0.000]` | `[+0.024, +0.018, +0.010, +0.006]` | **`[+0.041, +0.031, +0.017, +0.010]`** | Regional $z_l \to z_h$ labor productivity shift from competition reform & $1.60\times$–$2.16\times$ local food-hub procurement [Ref 49, 56] |

---

## 6. Calibration, SMM Identification (`Calibrate_NZ_Moments.m`), & Cross-Country Validation

### 6.1 Exact SMM Parameter Identification Matrix (15 Parameters $\leftrightarrow$ 15 NZ Empirical Moments)

| Parameter | Symbol | Value | Empirical Target Moment & Source | Model Fit |
| :--- | :---: | :---: | :--- | :---: |
| Stage-1 CES Substitution | $`\varphi_1`$ | `0.350` | Cunha, Heckman, & Schennach (2010): Stage-1 elasticity $`\sigma_1 = 1/(1-\varphi_1) = 1.54`$ | Exact |
| Stage-2 CES Complementarity | $`\varphi_2`$ | `-0.950` | Cunha et al. (2010): Stage-2 complementarity $`\sigma_2 = 1/(1-\varphi_2) = 0.51`$ | Exact |
| Parental Skill Persistence | $\rho_{hc}$ | `0.420` | Lee & Seshadri (2019) / NZ IDI baseline Intergenerational Elasticity $\mathrm{IGE} = 0.350$ | `0.350` |
| ECE Stone-Geary Threshold | $`\bar{g}_{\mathrm{ECE}}`$ | `0.032` | Barnardos / GUiNZ share of births in material hardship / $`i_c=0`$ corner (25.8%) | `25.79%` |
| Montessori / *Tuakana* Boost | $\Delta_{\mathrm{Tuakana}}$ | `0.110` | Graeme Dingle Foundation (*Stars* / *Project K*) & *Kura* NCEA Level 3 lift (+11 log pts) | `+0.110` |
| Dunedin Acute Cost Weight | $c_{\mathrm{acute}}$ | `0.380` | Caspi et al. (2016) Dunedin Study: 22% struggling tier drives 57%–81% of Exits 1, 2, 4 | `74.1%` |
| Rural Transport Subsistence | $\bar{e}_{\mathrm{Rural}}$ | `0.048` | Stats NZ HES rural vs. metro mandatory fuel/transport budget share (2.75x) | `2.74x` |
| Auckland Land Supply Factor | $Q_{\mathrm{Akl},\mathrm{SS0}}$ | `3.100` | Demographia / Stats NZ Auckland house price-to-income ratio vs. Rural (2.95x) | `2.95x` |
| Renter Down-Payment Cutoff | $\xi_k$ | `0.200` | RBNZ LVR 20% deposit rule; Auckland young adult homeownership rate (28.0%) | `28.0%` |
| Firm Collateral Multiplier | $\lambda_{\mathrm{col}}$ | `2.500` | Guvenen et al. (2023) / RBNZ SME business credit-to-equity ratio | `2.50` |
| Warm-Glow Bequest Scale | $b_1$ | `12.50` | NZ 20-year intergenerational property estate transfer wave (NZD 1.6T) | `NZD 1.6T` |
| Warm-Glow Bequest Threshold | $b_2$ | `2.800` | De Nardi (2004) / Stats NZ top-30% estate skewness | `70th pct` |
| Gumbel Migration Scale | $`\varrho_{\mathrm{mig}}`$ | `0.180` | Labrousse & Perdereau (2025, Table 8: $`\rho_G = 0.10`$) / Stillman & Maré (2008, Motu WP 08-06) & Poot (2009, NZ Treasury) age 20–35 trans-Tasman emigration (19.3% Akl / 10.9% Nat.) | `10.93%` |
| Present-Bias Fertility | $\beta_{\mathrm{hyp}}$ | `0.720` | Cao & Li (2022, *J. Pop. Econ.*, Prop. 5) / Stats NZ realized vs. intended TFR (1.66 vs. 2.15) | `1.66` |
| Female Childcare Share | $\theta_{\tau}$ | `0.680` | Doepke et al. (2022) / Stats NZ Time Use Survey maternal share of childcare | `68.0%` |

---

## 6.2 Two-Stage Sobol + Nelder-Mead SMM Optimization & Welfare-Based In-Kind Imputation (`Calibrate_NZ_Moments.m`)

To discipline the structural parameter vector $\theta$ against the 15 empirical New Zealand moments in Table 6.1 without getting trapped in local minima on the multi-region general-equilibrium surface, `Calibrate_NZ_Moments.m` executes a two-stage Simulated Method of Moments (SMM) procedure:

**1. Stage 1 — Sobol Quasi-Random Global Hypercube Pre-Screening:** Following Daruich (2018, Appendix C, Fig. C1), we draw $N_{\mathrm{sobol}}$ low-discrepancy Sobol sequence points across the bounded parameter hypercube $[\underline{\theta}, \overline{\theta}]$ and evaluate the weighted percentage-squared SMM objective function:

$$
\mathcal{L}_{\mathrm{SMM}}(\theta) = \sum_{m=1}^{M} W_m \left( \frac{\hat{M}_m(\theta) - M_m^{\mathrm{data}}}{\max(0.02, |M_m^{\mathrm{data}}|)} \right)^2
$$

**2. Stage 2 — Bound-Constrained Local Nelder-Mead / Quasi-Newton Refinement:** Starting from the best Sobol candidate $\theta_{\mathrm{sobol}}^{\star}$, we apply a logistic sigmoid transformation $\theta(x) = \underline{\theta} + (\overline{\theta} - \underline{\theta}) \oslash (1 + \exp(-x))$ and refine $x^{\star}$ to convergence via `fminsearch`.

**3. Dual Empirical Calibration Anchor Switch (`'Dunedin_22'` vs. `'MetroSqueeze_GUiNZ'`):** In `Plot_ChildFates_SSankey.m`, `Plot_ChildFiscal_SSankey.m`, and `Plot_ActuarialContinuationValuation.m`, the parameter `Params.Calibration_Anchor` toggles between two empirically validated New Zealand hardship anchors:
- `'Dunedin_22'` *(Default Conservative Anchor):* Calibrates the baseline struggling launch tier ($`h_1\text{--}h_2`$) to the **22.0%** high-cost cohort segment identified at age 3 in the Dunedin Multidisciplinary Health and Development Study (Caspi et al., 2016, where 22% of the cohort drives 57%–81% of adult Exits 1, 2, and 4; model fit = **74.1%**), using housing-crowding penalty $`\psi_{\mathrm{crowd}} = 0.14`$ and grid anchor `+0.265`.
- `'MetroSqueeze_GUiNZ'` *(After-Housing-Cost Metropolitan Squeeze Sensitivity):* Incorporates the full metropolitan housing-cost and dampness/crowding penalty documented in *Growing Up in New Zealand* (Morton et al., 2020: 37% damp/mould exposure) and Child Poverty Related Indicators (29.9% AHC60 child poverty; 34%–37% of children in households spending >30% of income on housing), using $\psi_{\mathrm{crowd}} = 0.18$ and grid anchor `+0.105` (expanding Auckland's baseline vulnerable trajectory to 34.0%–36.6%).

**4. Welfare-Based In-Kind ECE Imputation Weights ($`\omega_i`$, Ferriere et al., 2025, Eq. 3):** Because early childhood education and preventative health exhibit a Stone-Geary luxury threshold ($`\bar{g}_{\mathrm{ECE}} = 0.032 > 0`$, macro income elasticity $\theta \in [1.15, 1.38] > 1$), liquidity-constrained parents at the private corner solution (`i_c = 0`, share $`S = \Pr(i_c = 0) \approx 0.258`$) have a high marginal utility of liquid cash ($`\partial u_i / \partial y_i`$) to cover immediate rent (*Q_k*) and transport ($`\bar{e}_k`$). Standard static benefit-incidence studies that value public in-kind spending $`G_{\mathrm{ECE}}`$ at 1-for-1 cash equivalence overstate static redistributive compression by up to 50%. `Calibrate_NZ_Moments.m` computes Ferriere et al.'s exact marginal-rate-of-substitution imputation weight across income quintiles:

$$
\omega_i = \frac{\partial u_i / \partial G_{\mathrm{ECE}}}{\partial u_i / \partial y_i} = \min\left\lbrace \frac{y_i / \bar{y}}{F^{-1}(S)}, 1 \right\rbrace
$$

Even after strictly discounting direct static utility for cash-poor households ($`\omega_i < 1`$ in $`Q_1\text{--}Q_2`$), universal wraparound provision $`G_{\mathrm{ECE}}`$ generates large net positive Consumption-Equivalent welfare gains ($\mathrm{CE}$) through two dynamic general-equilibrium channels omitted by static incidence studies: (i) the concave pro-equality societal externality $`X_t`$ and fiscal cost avoidance across Exits 1, 2, and 4, and (ii) the intergenerational human-capital transition operator $`Q_h`$.

---

### 6.3 Cross-Country Macro-Calibration Validation Benchmarks & The Deming-to-Tokyo Coda

To verify that our simulated 40-to-60-year multiphase transition magnitudes (`SS0 -> SS1 -> SS2`: **+11.95% to +17.52% CE in *SS1* [+15.04% National]**, **+20.63% to +27.91% CE in *SS2* [+24.70% National]**, **-33.4% IGE reduction**, and **6.86x cumulative 60-year GDP multiplier**) are structurally consistent with international evidence, we benchmark the model's core elasticities against six historical and contemporary empirical episodes:

* **Nordic Dual-Dividend Calibration (Sweden & Finland, 1970–2020):**
  In De Nardi's (2004, *Review of Economic Studies*, Table 1) quantitative OLG calibration of Sweden versus the United States, universal early human-capital investment and social insurance compress the variance of idiosyncratic earnings shocks $`\sigma_y^2`$ by **52%** (from 0.30 in the US to 0.1429 in Sweden) and intergenerational shock variance $`\sigma_{yh}^2`$ by **52%** (from 0.37 to 0.1762). Paired with Doepke et al. (2022, NBER w29948, Fig. 2)—showing that public ECE spending of 1.6%–2.0% of GDP in Sweden and Finland lifts prime-age female employment above 80% while sustaining fertility—and Finland's 1993 dual capital/labor tax reform (Piketty & Saez, 2013), this directly validates our simulated compression of the struggling launch tier ($`h_1\text{--}h_2`$: 22.0% down to 1.5%) and -33.4% IGE reduction.
* **Pro-Enterprise Tax Reallocation + Universal Early Skill Compression (Estonia 1994–2025, Post-War Japan 1946–1985, New Deal US 1935–1980, & Viet Nam 1990–2025):**
  Estonia's 2000 corporate tax reform (0% tax on reinvested enterprise capital paired with a pure Land Value Tax) combined with universal subsidized kindergartens and 18-month parental leave propelled a 1.37-million-person economy to #1 in Europe in OECD PISA assessments while minimizing socio-economic skill gaps—matching our Guvenen et al. (2023) firm reallocation ($`\tau_k \downarrow, \tau_a \uparrow \Rightarrow \Gamma_k \to z_{h,k}`$) and Lens-1 skill compression. Similarly, post-1945 Japan's estate/land de-concentration and universal *Boshi Kenko Techo* First-2000-Days maternal/infant health screening (Moriguchi & Saez, 2008; Barro & Lee, 2013), the 1910–1980 US progressive estate tax consensus ($`\tau_b`$) funding the GI Bill youth endowment (*E*), and Viet Nam's post-*Đổi Mới* front-loaded nutrition/schooling miracle (cutting child hardship from >50% to <19%) confirm the long-horizon TFP and mobility multipliers in `T1`.
* **Youth Brain-Drain Reversal, Anti-Speculation Housing Rules, & Fiscal Self-Financing (Ireland, Singapore, Norway, & Quebec):**
  Ireland's post-1967 combination of universal secondary/technical education and pro-enterprise taxation reversed 150 years of 20–35 youth emigration into net high-skill return migration (validating $\Pi_{\mathrm{mig}}$ in Section 4.3); Singapore's pairing of universal Child Development Accounts (CDAs) and Edusave grants (*E*) with Additional Buyer's Stamp Duties (ABSD) curbed primate-city land crowd-out; and Baker, Gruber, and Milligan (2008, *JPE*) prove that Quebec's 1997 universal low-cost childcare reform raised maternal employment by +7 to +8 percentage points and generated >100% fiscal self-financing via additional income and consumption taxes.
* **The East Asian Primate-City Land Squeeze Warning (21st-Century South Korea & Post-1990 Bubble Japan):**
  Doepke et al. (2022, Sec. 4) and Hirano and Toda (2025, *JPE Macroeconomics*) demonstrate that when high schooling investment is not paired with metropolitan land-value cooling ($`Q_k \downarrow`$) and universal in-kind ECE ($`G_{\mathrm{ECE}}`$), primate-city housing speculation (Seoul and late-1980s Tokyo) and private tutoring arms races (*Hagwon*, an extreme luxury-good corner) crush young-family bargaining surplus, driving South Korea's TFR down to 0.72–0.75—validating why Lens 1 must be coupled with Lens 2 and Lens 3 in Auckland ($`Q_{\mathrm{Auckland}} = 3.10`$).
* **The Scottish Devolution Natural Experiment (2017–2026) — Empirical Identification of $`\Delta G_{\mathrm{ECE}} + T_k`$ Under $`\Delta \tau_l > 0`$ vs. $`\Delta \tau_a, \Delta \tau_b > 0`$:**
  Scotland's 2017–2026 policy sequence provides an out-of-sample quasi-experimental test of a **Lens-1-only reform financed via $\tau_l$**:
  1. Scaling targeted child transfers (*Scottish Child Payment* + *Best Start*, analogous to $`\Delta T_k`$) and doubling universal in-kind early childhood provision (from 600 to 1,140 hours/yr, analogous to $`\Delta G_{\mathrm{ECE},1}: 0.045 \to 0.110`$) alongside school-based adolescent mentoring (*MCR Pathways* / *The Promise*, analogous to Gate 3 $`\mathcal{M}_{\mathrm{Tuakana}}`$) reduced relative child poverty After Housing Costs by **6.0 percentage points relative to the rest of the UK** (21.0% vs. 27.0%+) with zero statistically significant maternal labor supply reduction ($`\Delta \ell_f \approx 0`$).
  2. However, because devolved fiscal constraints precluded taxing land overvaluation ($`\tau_a`$) or intergenerational estates ($`\tau_b`$) and forced reliance on higher top working-age PAYE rates ($`\tau_l: 42\%\text{--}48\%`$), metropolitan housing user costs $`r_{h,k}^{\mathrm{rent}}`$ remained elevated and progress plateaued 3 percentage points above the 18% interim statutory target—confirming our general-equilibrium result that **Lens 1 human-capital investments must be coupled with Lens 2/3 land-value cooling ($`Q_k \downarrow`$) and pro-enterprise capital reallocation ($`\Gamma_k \to z_{h,k}`$)** to achieve the full 2050 hardship compression (from 22.0% to 1.5%) and unlock working-age PAYE tax relief ($`\Delta \tau_l = -0.0375`$ in `SS2`).
* **Coda Formalization — From Deming's *System of Profound Knowledge* (1950) to Hirano & Toda's (2025) *Land Bubble Necessity Theorem*:**
  Post-war Japan's trajectory from W. Edwards Deming's 1947 Census mission and August 1950 Mt. Hakone JUSE lecture (*Out of the Crisis*, 1986; *The New Economics*, 1993; Tiemann, 2023) to the 1989 Tokyo land bubble provides the structural proof of why **Lens 1 + Lens 2 must be closed by Lens 3**. In Hirano and Toda's (2025) two-sector OLG model with inelastic urban land supply ($`\delta_{H,\mathrm{Metro}} \to 0`$), when Deming-style human and organizational capability compounding drives tradable manufacturing/knowledge TFP growth $`G_k = 1 + g_{Z,k}`$ above the equilibrium gross interest rate $`R\left(\tau_a = 0\right)`$ on unleveraged savings, the fundamental present value of land rents diverges and a rational land price bubble $`B_{\mathrm{land},k,t} > 0`$ becomes mathematically necessary in equilibrium:

$$
Q_{k,t} = \sum_{s=1}^{\infty} \left(\frac{G_k}{R\left(\tau_a\right)}\right)^{s} d_{\mathrm{land},k,t} + B_{\mathrm{land},k,t} \quad \Longrightarrow \quad B_{\mathrm{land},k,t} > 0 \quad \left(\text{when } G_k \ge R\left(0\right)\right)
$$

  Introducing the book-value land/wealth levy $`\tau_a = 0.015`$, the estate levy $`\tau_b = 0.25`$ on passive property accumulations, and the 2050 50/50 Debt-Sinking and Infrastructure Protocol ($`\Omega_{\mathrm{debt}}, \Omega_{\mathrm{infra}}`$) raises the effective discount factor on passive land holding to $`R_{\mathrm{eff}}\left(\tau_a\right) = \left(1 + r\right) / \left(1 - \tau_a\right) > G_k`$, **eliminating the rational land bubble condition ($`B_{\mathrm{land},k,t} \equiv 0`$) while channeling Deming-style human and enterprise surpluses into permanent productive capital and intergenerational endowments**.

---

## 7. Multiphase Transition Path, Actuarial Continuation Valuation, Credibility Blending, & Web SVG Architecture

### 7.1 Exact Multiphase Parameter Vector (`SS0 -> SS1 -> SS2` in `WelfareDecomposition_4Region.m`)

| Parameter Field | Symbol | *SS0* (Status Quo) | *SS1* (Incubation & Reallocation) | *SS2* (2050 Actuarial & Super-64 Harvest) | Structural Role in `ReturnFn_SpatialHH_Compact4D` & `Build_IntergenTransitionMatrix` |
| :--- | :---: | :---: | :---: | :---: | :--- |
| `G_ece` / `G_ece_stage1` | $G_{\mathrm{ECE},1}$ | `0.045` | `0.110` | `0.130` | Universal First-2,000-Days in-kind wraparound input; eliminates `i_c = 0` corners |
| `G_ece_stage2` | $G_{\mathrm{ECE},2}$ | `0.045` | `0.085` | `0.105` | Universal Stage-2 Montessori / *Tuakana–Teina* & Graeme Dingle mentoring (`J = 5`) |
| `YouthGrant` | *E* | `0.030` | `0.065` | `0.080` | Age-20 (`j = 1`) universal capital endowment relaxing young-adult deposit constraint |
| `super_age` (`Jr`) | $A_{\mathrm{super}}$ | `65.0` | `65.0` | **`64.0`** *(or 60..75)* | Statutory NZ Superannuation age (`64.0` global welfare peak, releasing `+8.1%` *Kuia* time boost) |
| `tau_l` (`tau_l_delta`) | $\tau_l$ ($\Delta \tau_l$) | `0.220` (`0.000`) | `0.220` (`0.000`) | **`0.1825` (`-0.0375`)** | Working-age PAYE labor tax rate (`18.25%` at Super Age 64 incl. `-0.64 pp` from 85% `Transfer_Geo` retirement) |
| `tau_b` | $\tau_b$ | `0.150` | `0.180–0.250` | `0.180` | Estate/bequest levy on the NZD 1.6T intergenerational property transfer wave |
| `r_delta` | $\Delta r$ | `0.000` | `-0.004` | `-0.006` | Reduction in domestic real interest rate from 50% Sovereign Debt-Sinking Fund |
| `w_mult_vs_SS0` | $w_k / w_{k,SS0}$ | `[1, 1, 1, 1]` | `[1.032, 1.038, 1.048, 1.055]` | `[1.068, 1.075, 1.088, 1.096]` | Guvenen firm reallocation TFP lift (*SS1*) + 1.65x public infrastructure reinvestment (*SS2*) |
| `Q_mult_vs_SS0` | $Q_k / Q_{k,SS0}$ | `[1, 1, 1, 1]` | `[0.990, 0.975, 0.950, 0.925]` | `[0.985, 0.955, 0.925, 0.895]` | Cooling of regional housing price-to-income ratios (-7.5% *SS1* to -10.5% *SS2* in Auckland) |
| `Frac_struggling` | $`\mathrm{Frac}_{\mathrm{struggling}}`$ |0.220|0.045|0.015 | Reduction of $`h_1\text{--}h_2`$ struggling launch share (lifting relational utility $`u_{\mathrm{rel}}`$) |
| `Transfer_Geo` | $T_k$ | `[0.015, 0.010, 0.005, 0.000]` | `[0.038, 0.031, 0.025, 0.028]` | **`[0.018, 0.013, 0.008, 0.004]`** | Labrousse–Perdereau *Income* $\times$ *Geography* transfer (surges in `SS1`, retires by 85% in `SS2` as $z_l \to z_h$ jobs take over) [Ref 23, 49, 56] |

### 7.2 Post-Hoc Transition Integrals & Actuarial Continuation Valuation Operators (`Plot_CumulativeTransitionPayoffs.m` & `Plot_ActuarialContinuationValuation.m`)

At each transition period $`t = 1, \dots, T_{\mathrm{trans}}`$ ($\Delta t \in \{5, 3, 2\}$ years spanning 60 years), `Plot_CumulativeTransitionPayoffs.m` integrates four regional and national annual flow series from `StationaryDist_t` ($`\mu_{k,t}`$) and $`\Gamma_{k,t}`$:

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

with dual Treasury discount rates $`r_{\mathrm{disc}} \in \{0.020, 0.080\}`$, real cost-base growth $`g_{\mathrm{cost}} = 0.015`$, attribution haircut $`\alpha_{\mathrm{attr}} = 0.30`$, pipeline maturity $`\Phi_{\mathrm{pipe}}(t_0) = \min(1, t_0 / 15)`$, and regional Markov skill retention $`[\psi_{\mathrm{Rural},0}, \psi_{\mathrm{Small},0}, \psi_{\mathrm{Large},0}, \psi_{\mathrm{Auckland},0}] = [0.984, 0.984, 0.986, 0.987]`$.

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

To decompose the multiphase Consumption-Equivalent welfare trajectory (`T1` rows `SS1_1..3` and `SS2_1..3`) into its underlying isolated policy levers and non-linear dynamic complementarity wedges across cohort entry years $c \in [-10, +60]$ and regions $k \in \lbrace \mathrm{Rural}, \mathrm{Small}, \mathrm{Large}, \mathrm{Auckland}, \mathrm{National} \rbrace$, `Plot_Counterfactuals_And_MirrorInvestments.m` evaluates a sequential Topkis (1998) supermodular policy lattice over the three-tier structural parameter vector:

$$\Phi = \left(\Phi_{\mathrm{HC}}, \Phi_{\mathrm{Spatial}}, \Phi_{\mathrm{Fiscal}}\right)$$

Let $W_k(\Phi)$ denote the expected lifetime Consumption-Equivalent welfare functional of a newborn cohort launching in region *k* relative to the *SS0* baseline $\Phi_0$:

$$\mathrm{CE}_k(\Phi) = \left( \frac{\int V_k(a_1, h_1, z_1, j=1; \Phi) d\mu_{1,k}(\Phi)}{\int V_k(a_1, h_1, z_1, j=1; \Phi_0) d\mu_{1,k}(\Phi_0)} \right)^{\frac{1}{\phi_{nd}(1-\sigma_c)}} - 1$$

Rather than relying on an arbitrary path-dependent Shapley residual, `Plot_Counterfactuals_And_MirrorInvestments.m` constructs an **11-Layer Supermodular Hierarchy** (`Table 19`) by evaluating the **7 Isolated Policy Factors** standalone (where equilibrium prices and the newborn distribution respond only to lever *m*) and interleaving the **4 Named Dynamic Complementarity Wedges**:

$$\Delta \mathrm{CE}_{k,m}^{\mathrm{iso}} \equiv \mathrm{CE}_k\left(\Phi_0 + \Delta \Phi_m\right), \qquad \Delta_{\mathrm{syn},w} \equiv \mathrm{CE}_k\left(A_w \cup B_w\right) - \mathrm{CE}_k\left(A_w\right) - \mathrm{CE}_k\left(B_w\right) > 0$$

$$\mathrm{CE}_k^{SS2} = \underbrace{\sum_{m \in \lbrace 1,2,4,5,6,9,10 \rbrace} \Delta \mathrm{CE}_{k,m}^{\mathrm{iso}}}_{\text{7 Isolated Factors (+11.23 pp, 45.5 pct share)}} + \underbrace{\sum_{w \in \lbrace 3,7,8,11 \rbrace} \Delta \mathrm{CE}_{k,w}^{\mathrm{wedge}}}_{\text{4 Synergy Wedges (+13.47 pp, 54.5 pct share)}} = +24.70\text{ pp CE (National)}$$

* **1. Tier 1 — Dual-Gate Human Capital Stack (+7.33% CE Nat.) & Wedge 1 (`L03_WEDGE1_DualGate_HC_Synergy` = +3.32% CE Nat., 13.4% Share):**
   * *Isolated Factors:* Layer 1 evaluates Gate 1 First-2,000-Days wraparound alone ($G_{\mathrm{ECE1}}: 0.045 \to 0.130$ with $M_{\mathrm{mentor}} = 0$, yielding **+2.46% CE**). Layer 2 evaluates Gate 2 Montessori / *Tuakana–Teina* mentoring alone ($G_{\mathrm{ECE2}}: 0.045 \to 0.105$ and $M_{\mathrm{mentor}} \to 1$ at baseline $G_{\mathrm{ECE1}} = 0.045$, yielding **+1.56% CE**).
   * *Structural Complementarity Mechanism:* In `HumanCapital_Lifecycle_aprimeFn.m`, Stage 1 exhibits high substitutability ($\varphi_1 = +0.35$, $\sigma_1 = 1.54 > 1$) while Stage 2 operates as a Cunha–Heckman harmonic-mean bottleneck ($\varphi_2 = -0.95$, $\sigma_2 = 0.513 < 1$) subject to unbanked skill depreciation $\delta_{\mathrm{fade}} = 0.22 w_2$. The cross-partial derivative of Stage-2 CES skill output $\theta_c^{\mathrm{ces},2}$ with respect to retained early skill $\theta_c^{\mathrm{ret}}$ and Stage-2 inputs $X_m \in \lbrace I_{\mathrm{tot},2}, h_p^{\mathrm{safe}} \rbrace$ is strictly positive:

$$\frac{\partial^2 \theta_c^{\mathrm{ces},2}}{\partial \theta_c^{\mathrm{ret}} \partial X_m} = (1 - \varphi_2) \gamma_{2,\mathrm{self}} \gamma_{2,m} \left(\theta_c^{\mathrm{ces},2}\right)^{1 - 2\varphi_2} \left(\theta_c^{\mathrm{ret}} X_m\right)^{\varphi_2 - 1} > 0 \qquad (1 - \varphi_2 = 1.95)$$

   * Deploying Layer 1 without Layer 2 (`P0_Early_0to5` in `PolicyExperiment_LeeSeshadri_4Region.m`) loses **22%** of early skill gains above $\theta_{\mathrm{base}}$ at ages 12–14 and leaves parental distress shocks ($z_p \in Z_{\mathrm{distress}}$) unbuffered ($-\psi_{\mathrm{unemp}}$). Deploying Layer 2 without Layer 1 (`P1P2_Late_6to17`) feeds a depleted baseline $\theta_c^{\mathrm{ret}}$ from the **25.79%** $i_c^\star = 0$ birth corner into the $\varphi_2 = -0.95$ bottleneck. Deploying both gates jointly eliminates fade-out ($(1 - M_{\mathrm{mentor}})\delta_{\mathrm{fade}} \to 0$), activates the downward *tuakana* scaffolding multiplier, and generates the supermodular residual:

$$G_{\mathrm{ECE},1}^{\mathrm{eff}} = G_{\mathrm{ECE},1}\left(1 + \kappa_{\mathrm{down}} M_{\mathrm{mentor}} \bar{\theta}_{J=5}\right)$$

$$\Delta \mathrm{CE}_{k,\mathrm{Wedge1}} = \mathrm{CE}_k\left(\Delta G_{\mathrm{ECE},1}, \Delta G_{\mathrm{ECE},2}\right) - \Delta \mathrm{CE}_{k,\mathrm{ECE1}}^{\mathrm{iso}} - \Delta \mathrm{CE}_{k,\mathrm{Tuakana}}^{\mathrm{iso}} = +3.32\text{ pp CE}$$

* **2. Tier 2 — Spatial, LVR & Enterprise Stack (+5.60% CE Nat.) & Wedge 2 (`L07_WEDGE2_LVR_Whanau_Synergy` = +2.33% CE Nat., 9.4% Share):**
   * *Isolated Factors:* Layer 4 ($\tau_a = 0.015$ and $\tau_b: 0.25 \to 0.18$, yielding **+2.24% CE**), Layer 5 (universal Age-20 Youth Capital Grant $E: 0.065 \to 0.080$, yielding **+0.89% CE**), and Layer 6 (Labrousse–Perdereau spatial transfer *T_k*, yielding **+0.15% CE after 82%–85% SS2 transfer retirement** via $T_k^{\mathrm{SS2}} = T_k^{\mathrm{SS0}} + (1 - \psi_{\mathrm{retire},T})(T_k^{\mathrm{SS1}} - T_k^{\mathrm{SS0}})$ with $\psi_{\mathrm{retire},T} = 0.850$, recycling $-0.64\text{ pp}$ of PAYE relief into Layer 10 [Ref 49, 56]).
   * *Structural Complementarity Mechanism:* In `ReturnFn_SpatialHH_Compact4D.m`, young households transition from rental user cost $r_{h,k}^{\mathrm{rent}}$ to homeowner user cost $r_{h,k}^{\mathrm{own}} = r_{h,k}^{\mathrm{rent}} - \psi_{\mathrm{own}} Q_k$ if and only if initial net worth clears the non-linear Kiyotaki et al. (2024) 20% LVR down-payment threshold:

$$a_1 + E \geq \xi_k Q_k(\tau_a, \tau_b), \qquad \xi_k = 0.20$$

   * In high-cost metropolitan markets ($Q_{\mathrm{Auckland}} = 3.10$ in *SS0*, requiring $\xi_k Q_k = 0.620$), providing $E = 0.080$ alone leaves cash-poor young adults below the deposit cliff, while cooling *Q_k* by **-10.5%** via $\tau_a$ and $\tau_b$ alone lowers the hurdle to $0.555$ without supplying the seed equity to cross it. Simultaneously, cooling *Q_k* raises the elder housing stability multiplier $\Phi_{\mathrm{home}}(p_{\mathrm{super}}, Q_k) = (p_{\mathrm{super}}/0.180)(Q_{k,0}/Q_k)^{0.35} > 1$, anchoring *kaumātua* and aunties in urban neighborhoods and cutting childhood rental transience $\nu_k$. Wedge 2 measures the mass of young households pushed across $\xi_k Q_k$ and anchored near extended *whānau* by the joint operation of Layers 4, 5, and 6:

$$\Delta \mathrm{CE}_{k,\mathrm{Wedge2}} = \mathrm{CE}_k\left(\Phi_{\mathrm{Spatial}}\right) - \left(\Delta \mathrm{CE}_{k,\mathrm{TaxRebal}}^{\mathrm{iso}} + \Delta \mathrm{CE}_{k,E}^{\mathrm{iso}} + \Delta \mathrm{CE}_{k,T}^{\mathrm{iso}}\right) = +2.33\text{ pp CE}$$

* **3. Tier 3 — Cross-Stack Human Capital × Spatial/Enterprise Interaction (`L08_WEDGE3_CrossStack_HC_x_Spatial` = +5.20% CE Nat., +5.63% Akl, 21.1% Share):**
   * *Structural Complementarity Mechanism:* Wedge 3 is the single largest complementarity term in the model, capturing three general-equilibrium cross-derivatives between the Dual-Gate Human Capital Stack ($\Phi_{\mathrm{HC}}$, expanding the thriving $h_6\text{--}h_7$ launch share from **23.5% to 65.0%**) and the Spatial/Enterprise Stack ($\Phi_{\mathrm{Spatial}}$, shifting the infinite-horizon firm distribution $\Gamma_k(a_f, z_f)$ toward high-productivity enterprises $z_{h,k}$ and cooling *Q_k*): (i) *Firm–Worker Assortative Matching* in `Solve_Spatial_GE_Loop.m`, where $\frac{\partial^2 Y_k}{\partial Z_k \partial H_k} = (1 - \alpha_k) K_k^{\alpha_k} H_k^{-\alpha_k} > 0$; (ii) *Domestic Graduate Retention* in the 4 × 5 Gumbel sorting operator $\Pi_{\mathrm{mig}}$, where coupling $\Phi_{\mathrm{HC}}$ with $\Phi_{\mathrm{Spatial}}$ raises domestic continuation values $V_{m,t}(a_1 + E - \kappa_{k \to m}, h_1, z_1, 1)$ relative to $V_{\mathrm{Abroad},t}$, cutting national youth emigration from **10.93% to 7.60%** ($\sim 3,550$ skilled graduates/yr retained); and (iii) *Relief of the Kaiako Housing-Affordability Supply Deflator* $G_{\mathrm{ECE}}^{\mathrm{eff}}(Q_k)$ (formalized in [Document 2T](Document%202T.md)); and (iv) **Regional $z_l \to z_h$ Job Upgrading & Monopsony Relief** ($\Delta \mu_{z,k} > 0$, [Ref 49, 56]), where breaking farm-gate wholesale monopsony and anchoring $1.60\times$–$2.16\times$ local food-hub procurement multipliers shifts rural and provincial workers from low-wage $z_l$ draws into high-productivity $z_h$ enterprises ($\frac{\partial^2 Y_k}{\partial \mu_{z,k} \partial H_k} > 0$), allowing 82%–85% of the SS1 geographic transfer to retire.

$$\Delta \mathrm{CE}_{k,\mathrm{Wedge3}} = \mathrm{CE}_k\left(\Phi_{\mathrm{HC}} \cup \Phi_{\mathrm{Spatial}}\right) - \mathrm{CE}_k\left(\Phi_{\mathrm{HC}}\right) - \mathrm{CE}_k\left(\Phi_{\mathrm{Spatial}}\right) = +5.20\text{ pp CE (Nat.)}, \quad +5.63\text{ pp CE (Akl)}$$

* **4. Tier 4 — Fiscal, Super-64 & 2nd-Generation Dynastic Harvest Stack (+6.56% CE Nat.) & Wedge 4 (`L11_WEDGE4_Fiscal_TFR_2ndGen_Closure` = +2.62% CE Nat., 10.6% Share):**
   * *Isolated Factors:* Layer 9 evaluates the **-60 bps** domestic interest rate reduction ($\Delta r = -0.006$) from the 50% Sovereign Debt-Sinking allocation $\Omega_{\mathrm{debt},t} = 0.50 \Omega_{\mathrm{reform},t}$ in the national asset-market clearing condition:

$$\sum_{k=1}^4 \omega_{F,k} \int \left(k_k(a_f, z_f) - a_f\right) d\Gamma_{k,t} + B_{\mathrm{gov},t} = \sum_{k=1}^4 \omega_{HH,k,t} \int a_{\mathrm{fin}} d\mu_{k,t} + B_t^\ast$$

   yielding **+1.25% CE**. Layer 10 evaluates the **-3.75 pp** working-age PAYE tax cut ($\tau_l: 0.2200 \to 0.1825$, including `-0.64 pp` funded by retiring 85% of the SS1 geographic transfer) paired with lowering universal NZ Superannuation to Age 64 ($\Phi_{\mathrm{time}}(64) = 1.081$, yielding **+2.69% CE**).
   * *Structural Complementarity Mechanism:* Wedge 4 captures the closed-loop dynastic and demographic fixed point at $t \geq 25$ (`Jump 2` in `T1` row `SS2_3_LongRun_GE_EndoIntergen`): (i) in `FertilityBargaining_Module.m`, combining universal ECE ($G_{\mathrm{ECE1}}$), lower housing user costs ($Q_k \downarrow$), the **-3.75 pp** PAYE cut, and the **+8.1%** Age-64 *Kuia/Koroua* time boost lifts cooperative marital bargaining surplus $S_f(n_f)$ under hyperbolic discounting ($\beta_{\mathrm{hyp}} = 0.72$), raising realized national TFR from **1.66 to 1.87** and stabilizing the OLG fiscal dependency ratio $D_{\mathrm{super},t}$; and (ii) in `Build_IntergenTransitionMatrix.m`, the first reformed cohort enters parenthood with stationary distribution $\mu_{1,k}^{SS2}$, transmitting higher parental human capital $h_p^{\mathrm{safe}}$ and lower distress incidence into the second generation via $T_{\mathrm{IG}}: Q_h \times Q_a \times \Pi_{\mathrm{mig}}$.

Finally, `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m` (`Tables 21 & 22` in [Document 3](Document%203.md)) maps this 11-layer system onto (i) the **3D Macroeconomic Welfare Surface** over Net Core Crown Debt ($B_{\mathrm{gov}}/Y$ from **15% to 200%** of GDP) and working-age PAYE tax rates ($\tau_l$ from **17% to 34%**) — contrasting the endogenous Treasury LTFM sinkhole (**-16.21% CE** at **185%** debt / **28.2%** PAYE) and an unfunded **3.0%-of-GDP** (**+1.8%** of GDP / **+NZD 8.0B/yr**) defense commitment (**-21.69% CE**) against the *SS1* → *SS2* trajectory (**+24.70% CE**, or **+21.18% CE** while sustaining the **3.0%** GDP defense commitment) — and (ii) the 4 × 4 **Coalition Complementarity Matrix** (`Table 22`), where the **+13.47% CE** sequential wedge total partitions into **+3.32% CE** of intra-Coalition-1 dual-gate synergy (`Wedge 1`) and **+10.15% CE** of off-diagonal inter-coalition wedges (`Wedges 2, 3, and 4`).

### 7.5 Zero-Dependency Interactive HTML5 + SVG Sankey Serialization & Cosine-S-Curve Ribbon Geometry (`exportSankeyToHTML.m`)
When MATLAB's `SSankey.m` renders gradient ribbons on an axes where `set(ax, 'YDir', 'normal')` is applied post-draw, the internal $`4 \times N_{\mathrm{strips}}`$ normal-offset quad vertices invert the vertical tangent sign $\left(-dy, dx\right)$, which causes direct vertex polygon exports to exhibit sub-pixel vertical striping and mid-span bowtie pinching on steep diagonal ribbons. `exportSankeyToHTML.m` eliminates both artifacts by extracting only the exact left and right block attachment spans $`\left\lbrack y_{L,\mathrm{bot}}, y_{L,\mathrm{top}} \right\rbrack`$ at $`x_L`$ and $`\left\lbrack y_{R,\mathrm{bot}}, y_{R,\mathrm{top}} \right\rbrack`$ at $`x_R`$, and reconstructing parallel upper and lower rails over $\tau \in \left\lbrack 0, 1 \right\rbrack$ via the smooth cosine S-curve $s\left(\tau\right) = \frac{1}{2}\left(1 - \cos\left(\pi \tau\right)\right)$:

$$
y_{\mathrm{top}}\left(\tau\right) = y_{L,\mathrm{top}} + s\left(\tau\right)\left(y_{R,\mathrm{top}} - y_{L,\mathrm{top}}\right), \qquad y_{\mathrm{bot}}\left(\tau\right) = y_{L,\mathrm{bot}} + s\left(\tau\right)\left(y_{R,\mathrm{bot}} - y_{L,\mathrm{bot}}\right)
$$

Because the vertical thickness at every horizontal station $\tau \in \left\lbrack 0, 1 \right\rbrack$ satisfies $y_{\mathrm{top}}\left(\tau\right) - y_{\mathrm{bot}}\left(\tau\right) = \left(1 - s\left(\tau\right)\right) H_L + s\left(\tau\right) H_R > 0$, every web SVG `<path>` is strictly non-self-intersecting, smooth, and 10x smaller in file size, while supporting interactive click inspection, collision-avoiding narrative callout placement, and 2-level (`Gate -> Block`) keyboard arrow-key traversal.

```text
+-----------------------------------------------------------------------------------+
|                                                                                   |
|                                                                                   |
|                                                                                   |
|                       [ THIS SPACE INTENTIONALLY LEFT BLANK ]                     |
|                                                                                   |
|                                                                                   |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

---

## 8. Consolidated 22-File VFI Toolkit Codebase Manifest

| File # | MATLAB Script / Function Name | Primary Role in the 4-Region + Abroad Multiphase Suite |
| :---: | :--- | :--- |
| **1** | `Run_All_NZ_Intergen_Suite.m` | Master execution pipeline with `.mat` checkpoint caching (`Cache_NZ_Intergen/`) and `Active_Phases = {'SS0', 'SS1', 'SS2'}` |
| **2** | `Configure_TimeGrid_Params.m` | Maps all flow rates, survival curves, and developmental stage indices across $\Delta t \in \lbrace 5, 3, 2, 1 \rbrace$ |
| **3** | `Build_Phase_Registry.m` | Assembles the $N$-phase registry struct array `Phases(1:N)` for `SS0`, `SS1`, `SS2`, or additional phases |
| **4** | `ReturnFn_SpatialHH_Compact4D.m` | 40-argument GPU household return function (`(l, Ih, ic, aprime, hprime, a, h, z, ...)` on compact 4D grid) |
| **5** | `NZ_4Region_Master.m` & `ReturnFn_SpatialHH.m` | Baseline 4-Region + Emigration Abroad master initializer (5D) and two-stage CES child skill experience-asset return function |
| **6** | `HumanCapital_Lifecycle_aprimeFn.m` | Endogenous human capital and two-stage child skill transition function (`aprimeFn`) |
| **7** | `ReturnFn_Firm.m` | Infinite-horizon Guvenen et al. (2023) collateral-constrained firm return function (`Firm_k`) |
| **8** | `Build_IntergenTransitionMatrix.m` | 100% GPU-vectorized 3-stage operator ($`\mathbf{Q}_h`$ with Montessori / *Tuakana–Teina* Gate, $`\mathbf{Q}_a`$, and 4 × 5 $`\Pi_{\mathrm{mig}}`$) |
| **9** | `Solve_Spatial_GE_Loop.m` | Mixed-horizon General Equilibrium solver (`ValueFnIter_MixHorz_PType` & `StationaryDist_MixHorz_PType`) |
| **10** | `Calibrate_NZ_Moments.m` | Simulated Method of Moments (SMM) calibration engine matching the 15 NZ empirical moments |
| **11** | `WelfareDecomposition_4Region.m` | Solves multiphase (`SS1`, `SS2`) 3-step Daruich / Lee-Seshadri decomposition (`T1`), quintiles (`T2`), and tenure (`T3`) |
| **12** | `PolicyExperiment_LeeSeshadri_4Region.m` | Multi-stage counterfactual suite (`BM`, `P0_Early`, `P1P2_Late`, `BN_FrontLoad`, `P0_Plus_GrantE`) exporting Tables 4–6 & 12A–C |
| **13** | `FertilityBargaining_Module.m` | Cooperative childcare bargaining, hyperbolic fertility ($\beta_{\mathrm{hyp}} = 0.72$), and NZ Super solvency tax module (Tables 7–8) |
| **14** | `TransPath_4Region_Master.m` | 60-year multiphase shooting algorithm with dynamic `PTypeWeights_path`, credibility blending $\lambda_{\mathrm{cred}}\left(t\right)$, and Figs 1–3 |
| **15** | `Plot_ChildFates_SSankey.m` | *N*-panel GPU 5-Stage (18-Node) Population Cohort Fates Sankey & `Table15_ChildFates_5Stage_Decomp_<Region>.csv` |
| **16** | `Plot_ChildFiscal_SSankey.m` | *N*-panel GPU 6-Gate (29-Node) Lifecycle Fiscal Sankey (Gate 5 $z_l / z_h$ Career Sorting → Gate 6 Exact Fiscal Ledger), 4-lane Waring/Landlord split ( Table14 ), regional BNZD scaling, and 2050 Debt-Sinking Protocol |
| **17** | `Plot_CumulativeTransitionPayoffs.m`, `Plot_ActuarialContinuationValuation.m`, & `Audit_GUiNZ_vs_Dunedin_4Region.m` | Integrates 60-year transition payoffs, ACC-style 25-year Actuarial Continuation Valuation ($V_{k,t_0}^{(L)}$ at 2% & 8% real), and stationary measure re-weighting between the 1972 `Dunedin_22` (3.84x) and 2010 `MetroSqueeze_GUiNZ` (4.26x–4.45x) cohorts |
| **18** | `Plot_Fertility_SuperSolvency_2Panel.m` | Generates the 2-panel Fertility Recovery & NZ Super Solvency comparison (`Keep Age 65` vs. `Raise Age to 67 or 70`, modeling the 38%–45% disability/hardship fiscal substitution leak; Doepke et al. 2022, Cao & Li 2022, Fan, Seshadri, & Taber 2022, and NZ Treasury 2024) |
| **19** | `Plot_Counterfactuals_And_MirrorInvestments.m` | Constructive 11-Layer Supermodular Synergy Attribution (7 Isolated Factors + 4 Synergy Wedges, `Table 19`, `Fig_Counterfactual_8Scenarios_*`) & Mirror-Image Annual Investment Ledger (`Table 20`, `Fig_7Segment_Welfare_And_MirrorInvestments_*`) |
| **20** | `Plot_WealthBracket_GiveAndGain.m` | Evaluates distributional welfare incidence (3 Fiscal Give Channels vs. 4 Economic Gain Channels, Active Entrepreneur vs. Passive Land Hoarder, and Retained Net Worth) across 10 survey-anchored `Earn + Own` tiers (`Table 17`) |
| **21** | `exportSankeyToHTML.m` | Exports live MATLAB `SSankey` axes into standalone, zero-dependency interactive HTML5 + SVG web diagrams (`Interactive_ChildFates_*.html`, `Interactive_ChildFiscal_*.html`) with cosine-S-curve ribbon geometry |
| **22** | `Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole.m` | Renders the 3D LTFM Fiscal Sinkhole & +3%-GDP Defense Cost-Sheet Shock Surface, 60-year Two-Term "Stop-Go" Perishability trajectories (`Table 21`), and the 4 × 4 Coalition Complementarity Matrix (`Table 22`) for [Document 3](Document%203.md) |

---

---

## 9. Annex: Master Reference Library & Empirical Source of Truth (`IntergenerationalWelfare` Drive Repository)

To ensure full replicability and unambiguous citation across the theoretical operators, VFI Toolkit scripts, New Zealand administrative calibrations, and historical benchmarks in **Documents 1A, 1B, 1C, 2A, 2B, 2T, and 3**, the project's primary literature and official datasets are indexed using a fixed decile numbering scheme (`1–10` for Folder 1, `11–20` for Folder 2, `21–30` for Folder 3, `31–40` for Folder 4, `41–50` for Folder 5, and `51–60` for Folder 6, with `RESERVED` slots preserving stable reference numbers across future additions):

## Folder 1: `01_Core_Macro_OLG_and_Wealth_Tax_Theory` (References 1–10)
- **[1]** **Ferriere, A., Grübener, P., Navarro, G., & Vardishvili, O. (2025 / Working Paper 2023):** *"On the Optimal Design of Transfers and Income-Tax Progressivity"* (plus companion ECB/CEPR paper *"In-Kind Transfers, Luxury Thresholds, and Redistribution"*) — *Public PDF:* *Journal of Political Economy Macroeconomics* / ECB Working Paper Series / PSE. *(Anchors the $`\bar{g}_{\mathrm{ECE}}`$ Stone-Geary luxury corner `i_c = 0`, welfare-based in-kind imputation weight $`\omega_i`$, and intertemporal government debt-service budget constraint $`r_t d_t`$.)*
- **[2]** **Guvenen, F., Kambourov, G., Kuruscu, B., Ocampo, S., & Chen, D. (2023):** *"Use It or Lose It: Efficiency and Redistributional Effects of Wealth Taxation"* — *Public PDF:* *Quarterly Journal of Economics* 138(2), 835–894 / NBER Working Paper w26284. *(Anchors the $`\tau_k \to \tau_a`$ property-to-enterprise capital reallocation mechanism and infinite-horizon firm Bellman equation `ReturnFn_Firm.m`.)*
- **[3]** **Hirano, T., & Toda, A. A. (2025):** *"Unbalanced Growth and Land Overvaluation"* (and *"Bubble Necessity Theorem"*) — *Public PDF & Replication Code:* *Journal of Political Economy Macroeconomics* / *PNAS* / Alexis Akira Toda's GitHub (`alexisakira.github.io/files/code_unbalanced_growth.zip`). *(Anchors regional land overvaluation *Q_k* under unbalanced sectoral productivity growth $`G_k`$ and the Part VI Tokyo Land Bubble Coda.)*
- **[4]** **Kiyotaki, N., Michaelides, A., & Nikolov, K. (2024):** *"Housing, Distribution, and Welfare"* — *Public PDF:* *Journal of Money, Credit and Banking* 56(5), 987–1020 (Wiley Open Access). *(Anchors the young renter vs. leveraged homeowner vs. retiree landlord tenure cleavage $`\xi_k`$ and small-open-economy interest rate crowding-in channel $`\Delta r`$.)*
- **[5]** **De Nardi, M. (2004):** *"Wealth Inequality and Intergenerational Links"* — *Public PDF:* *Review of Economic Studies* 71(3), 743–768 / NBER Working Paper w9768. *(Anchors the warm-glow luxury bequest motive $`b_1, b_2`$ and the Sweden vs. US idiosyncratic earnings variance compression benchmark.)*
- **[6]** **Piketty, T., & Saez, E. (2013) & Piketty, T., Saez, E., & Stantcheva, S. (2014):** *"A Theory of Optimal Inheritance Taxation"* (*Econometrica* 81(5), 1851–1886 / NBER w17989) and *"Optimal Taxation of Top Labor Incomes: A Tale of Three Elasticities"* (*American Economic Journal: Economic Policy* 6(1), 230–271 / NBER w17616). *(Anchors the optimal estate levy $`\tau_b = 25\%`$ on New Zealand's NZD 1.6T intergenerational property transfer funding the universal Youth Capital Grant *E*, and the three-elasticity decomposition $`e_{\mathrm{total}} = e_1 + e_2 + e_3`$ in Document 1B Section 4.5.1.)*
- **[7]** **Murphy, K. M., Shleifer, A., & Vishny, R. W. (1991):** *"The Allocation of Talent: Implications for Growth"* — *Public PDF:* *Quarterly Journal of Economics* 106(2), 503–530 / NBER Working Paper w3530. *(Anchors the occupational talent cutoff $`A^{\star}`$ between rent-seeking property speculation and productive entrepreneurship in Document 1A Part I.2 and `WelfareDecomposition_4Region.m`.)*
- **[8]** **Straub, L., & Werning, I. (2020) & Hope, D., & Limberg, J. (2022):** *"Positive Long-Run Capital Taxation: Chamley-Judd Revisited"* (*American Economic Review* 110(1), 86–119) and *"The Economic Consequences of Major Tax Cuts for the Rich"* (*Socio-Economic Review* 20(2), 539–559). *(Proves that optimal long-run capital/wealth taxation $`\tau_a > 0`$ is strictly positive under binding household liquidity constraints and finite intertemporal elasticity $`\sigma = 2.2`$, and validates empirically across 18 OECD economies over 50 years why top-rate reductions without capital-base broadening fail to lift real GDP growth in Table 6B Case 12.)*
- **[9]** **RESERVED**
- **[10]** **RESERVED**

## Folder 2: `02_Human_Capital_First2000Days_and_Adolescent_Gates` (References 11–20)
- **[11]** **Cunha, F., Heckman, J. J., & Schennach, S. M. (2010):** *"Estimating the Technology of Cognitive and Noncognitive Skill Formation"* — *Public PDF:* *Econometrica* 78(3), 883–931 / NBER Working Paper w15664. *(Anchors the two-stage CES skill technology with high Stage-1 substitutability $`\varphi_1 = 0.35`$ in the First 2000 Days and strong Stage-2 dynamic complementarity $`\varphi_2 = -0.95`$ in schooling.)*
- **[12]** **Lee, S. Y., & Seshadri, A. (2019):** *"On the Intergenerational Transmission of Economic Status"* (alongside Fan, Seshadri, & Taber, 2022, on adult Ben-Porath human capital) — *Public PDF:* *Journal of Political Economy* 127(2), 855–921 / NBER Working Paper w24395. *(Anchors `PolicyExperiment_LeeSeshadri_4Region.m` regimes `P0_Early_0to5`, `P1P2_Late_6to17`, `BN_FrontLoad`, and `P0_Plus_GrantE`.)*
- **[13]** **Fan, X., Seshadri, A., & Taber, C. (2024 / Working Paper 2022):** *"Estimation of a Life-Cycle Model with Human Capital, Labor Supply, and Retirement"* — *Public PDF:* *Journal of Political Economy* 132(1), 48–95 (alongside French, E., 2005, *Review of Economic Studies* 72(2), 395–427). *(Anchors adult Ben-Porath on-the-job training `I_h`, late-life physiological wage senescence `delta_senescence_post65 = 0.080`, and post-65 work disutility `psi_wear_post65 = 0.140` in `Configure_TimeGrid_Params.m` Section 6.)*
- **[14]** **Daruich, D. (2018 / 2022):** *"The Macroeconomic Consequences of Early Childhood Development Policies"* — *Public PDF:* SSRN / St. Louis Fed Working Paper. *(Anchors the 3-step PE/GE/Intergenerational welfare decomposition `T1`, Jump 1 vs. Jump 2 cohort welfare transition trajectories, and two-stage Sobol + Nelder-Mead SMM calibration.)*
- **[15]** **Bailey, D. H., Duncan, G. J., Odgers, C. L., & Yu, W. (2017):** *"Persistence and Fadeout in the Impacts of Child and Adolescent Interventions"* — *Public PDF:* *Journal of Research on Educational Effectiveness* 10(1), 7–39 / Life Course Centre Working Paper 2015-27. *(Anchors the "sustaining environments" and unbanked skill-gain fade-out parameter `delta_theta_fade = 0.22` in `HumanCapital_Lifecycle_aprimeFn.m` and the 39.2% two-term Stop-Go perishability wedge in Document 3 Table 4.1.)*
- **[16]** **Caspi, A., Houts, R. M., Belsky, D. W., Harrington, H., Hogan, S., Ramrakha, S., Poulton, R., & Moffitt, T. E. (2016):** *"Childhood forecasting of a small segment of the population with large economic burden"* — *Public PDF:* *Nature Human Behaviour* 1, 0005 (PMC Open Access). *(The landmark Dunedin Multidisciplinary Health and Development Study paper proving that the most disadvantaged 22% of a cohort at age 3 accounts for 57%–81% of adult hospital nights, welfare receipt, and criminal convictions.)*
- **[17]** **Morton, S. M. B., et al. (2020 / 2023 / 2025):** *"Growing Up in New Zealand: Now We Are Eight / Now We Are Twelve / Now We Are Fifteen — Longitudinal Reports on Material Hardship, Residential Mobility, and Youth Wellbeing"* — *Public PDF:* University of Auckland / Ministry of Social Development (`growingup.co.nz`). *(Anchors the `'MetroSqueeze_GUiNZ'` housing crowding and dampness penalty $`\psi_{\mathrm{crowd}}`$, the >45% private-rental transience rate prior to age 5 eroding early self-productivity in Document 1B Section 3.4.8, and the Ages 12–15 adolescent vulnerability window.)*
- **[18]** **Gluckman, P. (2011), Berryman, M., & Eley, E. (2019), & Graeme Dingle Foundation (2023/2025):** *"Improving the Transition: Reducing Social and Psychological Morbidity During Adolescence"* (Office of the Prime Minister's Chief Science Advisor, 2011), *"Tuakana–Teina and Ka Hikitia: Accelerating Māori Student Success"* (*New Zealand Journal of Educational Studies*), and *Graeme Dingle Foundation Social Return on Investment (SROI) Reports on Stars / Te Kāhui Whetū & Project K*. *(Anchors the Gate 3 `J = 5` Montessori / Tuakana–Teina and Graeme Dingle adolescent mentoring boost $`\Delta_{\mathrm{Tuakana}} = +0.11`$.)*
- **[19]** **Fleming, T., Tiatia-Seath, J., Peiris-John, R., Sutcliffe, K., Kang, K., Bavin, L., Crengle, S., & Clark, T. (2020):** *Youth19 Rangatahi Smart Survey, Initial Findings: Hauora Hinengaro / Emotional and Mental Health* — *Public PDF:* The Youth19 Research Group, University of Auckland and Victoria University of Wellington ( youth19.ac.nz ). *(Anchors the post-2012 doubling of clinically significant adolescent depressive symptoms from 13% to 23% overall—and 28% among rangatahi Māori—entering the Gate 3* $J = 5$ *psychosocial hazard* $\lambda_{\text{psy}}$ *at Node 7.)*
- **[20]** **Green, V. A., Woods, L., Wegerhoff, D., Harcourt, S., & Towl, G. (2020):** *"An Evaluation of the KiVa Anti-Bullying Programme in New Zealand"* — *Public PDF:* *International Journal of Bullying Prevention* 2, 225–237 (alongside OECD PISA 2022/2025 Student Wellbeing bullying incidence tables). *(Anchors New Zealand's 32%–35% baseline peer-victimization incidence and validates bystander peer-ecology restructuring via cross-age* *Tuakana–Teina* *mentoring at Gate 3.)*

## Folder 3: `03_Fertility_Bargaining_and_Brain_Drain_Migration` (References 21–30)
- **[21]** **Doepke, M., Hannusch, A., Kindermann, F., & Tertilt, M. (2022 / 2023):** *"The Economics of Fertility: A New Era"* — *Public PDF:* *Handbook of the Economics of the Family* / NBER Working Paper w29948. *(Anchors the cooperative household childcare bargaining module `FertilityBargaining_Module.m`, maternal time share $`\theta_{\tau} = 0.68`$, and Nordic vs. East Asian fertility regimes.)*
- **[22]** **Cao, J., & Li, M. (2021 / 2022):** *"Hyperbolic discounting in an intergenerational model with altruistic parents"* — *Public PDF:* *Journal of Population Economics* 35(3), 989–1005 ([https://doi.org/10.1007/s00148-021-00824-7](https://doi.org/10.1007/s00148-021-00824-7)). *(Anchors the Period-2 quasi-hyperbolic fertility discount parameter $`\beta_{\mathrm{hyp}} = 0.72`$ via Proposition 5's closed-form ratio of realized to intended fertility $`n^t / n^c = \beta_{\mathrm{hyp}}^{1/\epsilon}`$.)*
- **[23]** **Labrousse, C., & Perdereau, Y. (2025):** *"Geography versus Income: The Heterogeneous Effects of Carbon Taxation"* — *Public PDF:* European Central Bank (ECB) Working Paper Series / Paris School of Economics (building on *Ferriere, A., & Navarro, G., 2025*, *Review of Economic Studies* 92(2), 1061–1125). *(Section 3.2, Appendix B, & Table 8 provide the exact $`4 × 5`$ Gumbel extreme-value discrete location-choice operator $`P_t^{k'}(a, z, k)`$ and baseline Gumbel shock variance $`\rho_G = 0.10`$, adapted in our Stage-3 youth sorting matrix with $`\varrho_{\mathrm{mig}} = 0.180`$, alongside the Spatial $`\times`$ Income transfer progressivity framework in `T2`.)*
- **[24]** **Stillman, S., & Maré, D. C. (2008):** *"Housing Markets and Migration: Evidence from New Zealand"* — *Public PDF:* *Motu Working Paper 08-06*, Motu Economic and Public Policy Research ([https://motu-www.motu.org.nz/wpapers/08_06.pdf](https://motu-www.motu.org.nz/wpapers/08_06.pdf)). *(Provides 5-year New Zealand Census inter-regional internal vs. international migration accounting across Local Labour Market Areas and proves that net retention of NZ-born residents is negatively related to local real house price inflation with an elasticity of **-4.4**.)*
- **[25]** **Poot, J. (2009 / 2010) & Greenaway-McGrevy, R., & Phillips, P. C. B. (2023):** *"Trans-Tasman Migration, Transnationalism and Economic Development in Australasia"* (*New Zealand Treasury Guest Lecture / Population Studies Centre DP 72*, [https://www.treasury.govt.nz/sites/default/files/2017-11/tfr-ttmteda-28oct09.pdf](https://www.treasury.govt.nz/sites/default/files/2017-11/tfr-ttmteda-28oct09.pdf); alongside *Bushnell, P., & Choy, W. K., 2001*, *"Go West, Young Man, Go West!?"* *NZ Treasury Working Paper 01/07*) + *Greenaway-McGrevy, R., & Phillips, P. C. B. (2023 / 2025)*, *"The Impact of Upzoning on Housing Construction in Auckland"* (*Journal of Urban Economics* 136, 103558 & UoA Economic Policy Centre WP 013). *(Anchors the age 20–35 trans-Tasman emigration pull $`\omega_{\mathrm{OECD}} = 1.32`$, replacement-migration turnover churn, and Auckland's housing supply elasticity $`\delta_{H,\mathrm{Auckland}} = 0.10`$.)*
- **[26]** **Rupert, P., & Zanella, G. (2018) & Compton, J., & Pollak, R. A. (2014):** *"Grandchildren and Their Grandparents' Labor Supply"* (*Journal of Public Economics* 159, 89–103 / IZA DP 11235) and *"Family Proximity, Childcare, and Women's Labor Force Attachment"* (*Journal of Urban Economics* 79, 72–90). *(Anchors the grandparental childcare time-transfer elasticity `eta_elder_whanau = 0.090` and the Age-64 Kuia/Koroua time dividend `kappa_kuia_max = 0.160` in `Configure_TimeGrid_Params.m` Section 6.)*
- **[27]** **Coe, N. B., & Van Houtven, C. H. (2009) & Case, A., & Deaton, A. (2005):** *"Caring for Mom and Neglecting Yourself? The Health Effects of Caring for an Elderly Parent"* (*Health Economics* 18(9), 991–1010) and *"Broken Down by Work and Sex: How Our Health Declines"* (NBER Ch. 6). *(Anchors age-morbidity decay `lambda_health_decay_65 = 0.180` and the upward sandwich-generation caregiver labor drag `psi_sandwich_wrk_drag = 0.350` in `Configure_TimeGrid_Params.m` Section 6.)*
- **[28]** **RESERVED**
- **[29]** **RESERVED**
- **[30]** **RESERVED**

## Folder 4: `04_NZ_Treasury_LTFS_CBAx_and_Infrastructure_Audits` (References 31–40)
- **[31]** **New Zealand Treasury (September 2025):** *He Tirohanga Mokopuna 2025 — Long-term Fiscal Statement 2025* (`ltfs-2025.pdf`, [https://www.treasury.govt.nz/publications/ltfp/he-tirohanga-mokopuna-2025](https://www.treasury.govt.nz/publications/ltfp/he-tirohanga-mokopuna-2025)). *(Anchors the status-quo 40-year fiscal outlook where real government spending per person nearly doubles from NZD 18,300 to NZD 35,900 and net core Crown debt reaches ~200% of GDP by 2065, alongside Annexes 1–2 introducing Treasury's OLG model.)*
- **[32]** **Bell, M. / New Zealand Treasury (February 2026), Binning et al. (2024), & Treasury OIA Response 20250878 (February 2026):** *Analytical Note 26/01: The 2025 Long-term Fiscal Model — Main features and changes* (`an26-01-v2.pdf`, [https://www.treasury.govt.nz/publications/an/an-26-01](https://www.treasury.govt.nz/publications/an/an-26-01)), *Official Information Act Response 20250878: Social Cost Benefit Analysis and Fiscal Projection Models* (`oia-20250878.pdf`, 4 Feb 2026), and Binning, McKenzie, Özbilgin, & Smith (2024 / *AN 24/08*). *(AN 26/01 anchors the 2025 BEFU-based LTFM debt-interest spiral and 0.9%/yr productivity growth assumption; OIA 20250878 officially confirms on pp. 6–11 that Treasury's macro LTFM/FSM models do not model micro cohort social-harm feedback loops—the exact methodological gap closed by our coupled 4-Region OLG + Dunedin/CBAx lifecycle engine.)*
- **[33]** **New Zealand Treasury (November 2025 & July 2015):** *CBAx Tool User Guidance: Guide for departments and agencies using Treasury's CBAx tool for cost benefit analysis* (`cbax-tool-user-guidance-nov25.pdf`), companion *CBAx Spreadsheet Model & Impacts Database* (`cbax-model-oct25.xlsx`, Oct 2025), and *Guide to Social Cost Benefit Analysis* (`cba-guide-jul15.pdf`, July 2015), supplemented by *Budget 2026 Guidance for Agencies* (`b26-guide-agen-5304608.pdf`). *(Page 15 of the November 2025 CBAx User Guidance anchors Treasury Circular 2024/15's dual public-sector real discount rates—**2.0% real SRTP** for non-commercial social investments over Years 1–30, stepping to 1.5% in Years 31–100, with mandatory **8.0% real SOC** sensitivity testing—while the July 2015 Guide pp. 10–15 anchors Counting Rule #1 separating fiscal transfer payments *T_k* from real GDP output $`\Delta Y_t`$.)*
- **[34]** **New Zealand Treasury (March 2025):** *OIA Response 20250126: Review of Public Sector Discount Rates Culminating in Treasury Circular 2024/15* (`oia-20250126.pdf`, containing *Grimes, A., June 2023*, *How should the NZ government discount future payoffs?*; *Abelson, P., & Dalton, T., June 2023*, *Declining Discount Rates in Cost Benefit Analysis*; and *Jensen, K., & Parker, C., Dec 2023*, *Update to Public Sector Discounting — Default SRTP*). *(Provides the theoretical CCAPM, Ramsey Monte Carlo, and Weitzman certainty-equivalent proofs for adopting the 2.0% real SRTP discount rate and declining long-term schedule rather than continuous hyperbolic discounting in public project appraisal.)*
- **[35]** **Accident Compensation Corporation (ACC) (14 November 2025):** *Financial Condition Report 2025* (Prepared by Nina Herries, Chief Actuary, `ACC8828-Financial-Condition-Report-2025.pdf`). *(Provides the statutory and actuarial template for our Year 5 Actuarial Continuation Valuation $`\mathcal{V}_{k,t_0}^{(L)}`$: documents the valuation of ACC's NZD 57.34B funding-basis / NZD 63.6B accounting-basis Outstanding Claims Liability, defines "New Year Costs" and "OCL Release" [booking discounted multi-decade liability reductions when rehabilitation performance improves, pp. 17 & 44], and details the transition to PBE IFRS 17.)*
- **[36]** **Independent Crown Review / Department of Internal Affairs (September 2026) & Te Waihanga (2025/2026):** *Report of the Independent Review into the Moa Point Wastewater Treatment Plant Failure* (Chaired by Raveen Jaduram) + *New Zealand Infrastructure Commission / Te Waihanga*, *National Infrastructure Plan & Rautaki Hanganga o Aotearoa*. *(Anchors the reactive-vs.-preventative maintenance proof and the 2050 50/50 Debt-Sinking & Infrastructure Protocol.)*
- **[37]** **Barnardos Aotearoa (2025 / 2026) & MartinJenkins (2020):** *Generational Plan Economic Case, Derived Measures, & Facts Table* (`Barnardos_GP_Economic_Case_FINAL.docx`, `Barnardos_GP_Derived_Measures_FINAL.docx`, `Barnardos_GP_Facts_Table_FINAL.docx` — modeling *Te Korowai Mokopuna* First 2000 Days wraparound) and *MartinJenkins (2020)*, *Economic Cost of Abuse in Care: Final Report* (for the Royal Commission of Inquiry into Abuse in Care, `MSC0008804`, [https://www.abuseincare.org.nz/__data/assets/pdf_file/0021/25158/martinjenkins-economic-cost-of-abuse-in-care-2020.pdf](https://www.abuseincare.org.nz/__data/assets/pdf_file/0021/25158/martinjenkins-economic-cost-of-abuse-in-care-2020.pdf), alongside Oranga Tamariki *Funding Policy and Guidance for Shared Care*, Oct 2023). *(Anchors the community-delivered First-2000-Days wraparound intervention, the NZD 37,054 to NZD 54,739 per child-year Oranga Tamariki custody cost, and the NZD 181,000 [in 2025 NZD] discounted lifetime Crown fiscal cost per child abused in care.)*
- **[38]** **Social Investment Agency (SIA) & Accident Compensation Corporation (ACC) (2023 / 2025):** *Integrated Services for Sensitive Claims (ISSC) & Loss of Potential Earnings (LOPE) Actuarial Valuation and Youth Mental Health Pathways* — *Public PDF:* Crown Actuarial Reports ( acc.co.nz / sia.govt.nz ). *(Documents the 193% surge in annual new ACC sensitive claims from 4,328 to 12,702, the statutory 80%-of-minimum-wage LOPE entitlement when childhood/adolescent trauma impairs adult labor market entry, and the 38% clinical persistence floor at Gate 3 → Gate 5 Exits 2, 3, and 4.)*
- **[39]** **RESERVED**
- **[40]** **RESERVED**

## Folder 5: `05_NZ_Wealth_Distribution_Tax_and_Social_Cohesion_Data` (References 41–50)
- **[41]** **Inland Revenue Department (IRD) (April 2023):** *High-Wealth Individuals Research Project (HWIRP) — Final Report* — *Public PDF:* `ird.govt.nz`. *(Anchors Tiers 9–10 of the 10-Tier Survey-Anchored Earn + Own table: NZD 50M median net worth, NZD 106M mean net worth, and 8.9% baseline effective economic tax rate.)*
- **[42]** **Statistics New Zealand (2022 / 2025):** *Household Net Worth Statistics* + *Subnational Population Estimates & Business Demography Statistics (Feb/June 2025)* + *Child Poverty Statistics (Year Ended June 2025)* — *Public PDFs/CSVs:* `stats.govt.nz`. *(Anchors median net worth NZD 529k, mean NZD 1.041M, the 4-region household `[0.160, 0.240, 0.259, 0.341]` and firm `[0.150, 0.230, 0.269, 0.351]` weights, and AHC child poverty.)*
- **[43]** **Rashbrooke, M. (2015, 2021 / 2024 Updates):** *Wealth and New Zealand* and *Too Much Money: How Wealth Disparities Are Unbalancing Aotearoa New Zealand* (Bridget Williams Books / VUW Institute for Governance and Policy Studies Working Papers). *(Anchors the P50, P90, P95, and P99 wealth percentiles in `Plot_WealthBracket_GiveAndGain.m`.)*
- **[44]** **Transparency International & Office of the Auditor-General of New Zealand (2026):** *Corruption Perceptions Index 2025* (Feb 2026), Office of the Controller and Auditor-General *"New Zealand's Integrity Inheritance"* (Feb 2026), and Transparency International New Zealand *National Integrity System Gap Analysis* (June 2026) — *Public PDFs:* `transparency.org.nz` and `oag.parliament.nz`. *(Anchors the "Sovereign Social Credit Rating" analysis and Social Cohesion Index $`S_t: 100.0 \to 118.4 \to 126.0`$.)*
- **[45]** **Berentson-Shaw, J. (2018) & Finnish National Agency for Education / EDUFI (2024):** *A Matter of Fact: Talking Truth in a Post-Truth World* (Wellington: Bridget Williams Books, BWB Texts, ISBN 9781988545387) and *Monilukutaito (Multiliteracy) Cross-Curricular Epistemic Resilience Framework* (EDUFI, Helsinki; Open Society Institute European Media Literacy Index #1 benchmark, 2017–2026). *(Anchors the values-based framing and causal system-metaphor channel driving credibility convergence $`\lambda_{\mathrm{cred}}(t) \to 1`$ and protecting the Social Cohesion Index $`S_t`$ against polarization drag in Document 1B Section 2.4.3.)*
- **[46]** **Rewiring Aotearoa — Ellison, J., Sahng, J., Kirkham, N., Fahy, B., Karl, D., Casey, M., & Griffith, S. (March 2024 & June 2026 Update):** *Electric Homes & Vehicles: Household Electrification Technical Report* (Peer-reviewed by Cameron Bagrie & Prof. Shaun Hendy; Rewiring Aotearoa / EECA, `pages.rewiring.nz/electric-homes-and-vehicles-2026` and `eeca.govt.nz/assets/Uploads/Electric-Homes-Technical-Report_March-2024.pdf`). *(Documents that New Zealand spends ~NZD 30B/yr on energy—including NZD 19.5B/yr on largely imported fossil fuels—and proves that household electrification via rooftop solar [at ~NZD 0.12/kWh financed vs. NZD 0.26–0.34/kWh grid], battery storage, heat pumps, and EVs cuts household energy and transport bills by NZD 7,600/yr gross [NZD 3,000/yr net of loan repayments, or NZD 12.9B/yr nationally], directly compressing the mandatory energy/transport subsistence floor $`\bar{e}_k(t)`$ and relaxing the Stone–Geary $`i_c^\star = 0`$ corner in Document 1B Section 3.4.8.)*
- **[47]** **Waring, M. (1988 / 1999):** *Counting for Nothing: What Men Value and What Women Are Worth* (Published in US as *If Women Counted: A New Feminist Economics* ) — Wellington: Allen & Unwin / Port Nicholson Press & Bridget Williams Books. *(Foundational feminist and institutional accounting critique proving why unpaid household and alloparental* *whānau* *care* $K_{\text{whānau}}(k)$ *is invisible in standard GDP/Treasury ledgers, yet decisively determines whether infants in Node 2 [Residual AHC Squeeze] escape the Node 4* $i_c = 0$ *corner.)*
- **[48]** **Perry, B. / Ministry of Social Development (2022 / 2025) & Welfare Expert Advisory Group [WEAG] (2019):** *Material Wellbeing in New Zealand (Household Incomes in New Zealand: Trends in Indicators of Inequality and Hardship)* and *Whakamana Tāngata: Restoring Dignity to Social Security in New Zealand* — *Public PDFs:* msd.govt.nz and weag.govt.nz . *(Distinguishes statutory Severe Material Hardship [DEP-17 9+, ~9.8% of births at Gate 1 Node 1] from the Residual After-Housing-Costs Squeeze & Paper-Support Abatement Trap [AHC-50, ~14.2% of births at Gate 1 Node 2].)*
- **[49]** **Duffy, J. (2026) & New Zealand Commerce Commission (2022 / 2024 / 2025):** *"Domestic Oligopoly Markups and Competition Policy"* (in *Facing Up to Our Future*, 2026) + Commerce Commission *Market Study into the Retail Grocery Sector* and *Annual Grocery Sector Reports* (comcom.govt.nz). *(Documents how retail duopoly markups and upstream farm-gate wholesale monopsony depress rural and provincial enterprise returns and trap regions in low-wage $z_l$ equilibria; anchors the regional $z_l \to z_h$ job-upgrading shift $\Delta \mu_{z,k}$ and the 85% retirement of the urban-to-rural geographic transfer $\psi_{\mathrm{retire},T} = 0.850$ in `Configure_TimeGrid_Params.m` and `WelfareDecomposition_4Region.m`.)*
- **[50]** **RESERVED**

## Folder 6: `06_International_Benchmarks_Scotland_Nordics_and_Deming` (References 51–60)
- **[51]** **Scottish Government & Joseph Rowntree Foundation (2026):** *Bringing Hope, Building Futures: Tackling Child Poverty Delivery Plan 2026–2031* (Scottish Government, March 2026), *Scottish Child Payment and the Labour Market* (Oct 2026), and *Poverty in Scotland 2026* (JRF, Oct 2026) + *MCR Pathways (2024/2025) National Impact Report*. *(Anchors the Scotland devolved natural experiment in Part VI.)*
- **[52]** **Corlet Walker, C., Druckman, A., & Jackson, T. (2021 / 2024):** *"Welfare systems without economic growth: A review of the challenges and next steps for the field"* — *Public PDF:* *The Lancet Planetary Health* 5(4), e237–e246. *(Links New Zealand, Scotland, and Finland in the Wellbeing Economy Governments alliance.)*
- **[53]** **Baker, M., Gruber, J., & Milligan, K. (2008):** *"Universal Childcare, Maternal Labor Supply, and Family Well-Being"* — *Public PDF:* *Journal of Political Economy* 116(4), 709–745 / NBER Working Paper w11832. *(Anchors the Quebec universal childcare self-financing and maternal labor supply benchmark.)*
- **[54]** **Deming, W. E. (1950 Mt. Hakone JUSE Lecture Transcript / 1986 *Out of the Crisis* Ch. 1–2 / 1993 *The New Economics* Ch. 4: *A System of Profound Knowledge*), Moriguchi, C., & Saez, E. (2008, *Review of Economics and Statistics*), & Tiemann, M. (2023, *Achieving Net-Zero with Sustainable Quality*, OS-Climate / Linux Foundation).** *(Anchors the Part VI Coda on whole-system transformation within 3–5 years vs. the 1989 Tokyo land bubble and Te Tiriti o Waitangi intergenerational stewardship.)*
- **[55]** **Kristjansson, A. L., Mann, M. J., Sigfusson, J., Thorisdottir, I. E., Allegrante, J. P., & Sigfusdottir, I. D. (2020):** *"Development and Guiding Principles of the Icelandic Model for Preventing Adolescent Substance Use"* — *Public PDF:* *Health Promotion Practice* 21(1), 62–69 ( planet-youth.org ). *(Validates the environmental and relational elasticity at Gate 3* $J = 5$ *, demonstrating how structured family connection time and universal mentored youth cohorts cut adolescent behavioral morbidity from 42% to 5% in Iceland, supporting our 82% → 38% stress-trap compression.)*
- **[56]** **NC State Center for Environmental Farming Systems (CEFS) — Cosco, N. G., Moore, R. C., et al. (2022), Dunn, C., et al. (2006), Bloom, J. D., et al. (2022 / 2026), & Sanford, N. / GrowingChange:** *"Effects of a Gardening and Physical Activity Intervention (Color Me Healthy) on Preschool Children's Fruit and Vegetable Consumption"* (*Preventive Medicine Reports* / NIH R01 HD072202; +24% to +33% preschool vegetable intake, $d = 1.20$; +26.6 pp parent nutrition crowding-in; 46% take-home garden produce), *2025–2026 Local Food Purchasing Incentive (LFPI) Evaluation Report* (1.60x–2.16x regional food-hub economic multiplier), and *CEFS Food Youth Initiative (FYI) & GrowingChange* (repurposing decommissioned rural prison sites into youth-led regenerative agriculture and food-hub enterprises with a 92% non-recidivism rate; cefs.ncsu.edu & growingchange.org). *(Empirical international benchmark for New Zealand's Ka Ora, Ka Ako school/marae procurement, Gate 1/2 nutrition and mentoring efficacy, and regional $z_l \to z_h$ youth enterprise pathways.)*
- **[57]** **RESERVED**
- **[58]** **RESERVED**
- **[59]** **RESERVED**
- **[60]** **RESERVED**

## 10. Companion Technical Tutorial: "Thick" vs. "Thin" Numbers & Dimension-Free State-Contingent Conditioning ([Document 2T](Document%202T.md))

To keep this specification guide within GitHub's per-file MathJax rendering limits while giving our state-contingent operator methodology a full pedagogical treatment, Section 10 has been published as a standalone companion monograph: **[Document 2T: "Thick" vs. "Thin" Numbers in Quantitative Public Policy — Why Dimension-Free State-Contingent Conditioning Captures Comonotonic Tail Risks Without Expanding GPU Grid Dimensions](Document%202T.md)**.

**[Document 2T](Document%202T.md)** provides the formal Jensen's Inequality proofs and state-sub-manifold equations for our four zero-dimension-cost operators:
- **[1]** **State-Contingent Extended *Whānau* Care ($`K_{\mathrm{wh\bar{a}nau}}^{\mathrm{net}}`$):** Comonotonic Sandwich-Generation Care Reversal under Super Age 67/70 and trust-gated adolescent mentoring (`Section 4.1`).
- **[2]** **Price-Manifold Conditioned Public Wraparound ($`G_{\mathrm{ece},s}^{\mathrm{eff}}(Q_k)`$):** The *Kaiako* housing-affordability workforce supply deflator (`Section 4.2`).
- **[3]** **Sub-Manifold Conditioned Housing User Costs ($`p_H(a, z, Q_k, j)`$):** The 61-point asset-grid 20% LVR deposit cliff and comonotonic eviction/transience tail (`Section 4.3`).
- **[4]** **Skill-Manifold Conditioned Survival and Late-Life Labor Disutility ($`s_j^{\mathrm{eff}}(h, j)`$):** Capturing actuarial regressivity and the 38%–52% disability benefit substitution leak (`Section 4.4`).
