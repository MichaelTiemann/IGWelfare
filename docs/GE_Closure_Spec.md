# GE closure: specification for wiring `Solve_Spatial_GE_Loop.m`

Status: **scaffold / proposal**. `Solve_Spatial_GE_Loop.m` is a toolkit-independent
solver tested on an analytic toy economy (`tests/test_ge_loop_toy.m`). It is **not yet
wired** to the VFI Toolkit household block. No existing file is modified by this branch.
All `file:line` references are to `main` at c23787e and were re-read for this document.

## 0. Starting point

`README.md:72` and `Document 2B.md:401` name `Solve_Spatial_GE_Loop.m`
as the mixed-horizon GE solver. That file was not in the repository before this branch.
Searching all `.m`/`.md` files for `fzero`, `fsolve`, `GeneralEqm`, `HeteroAgent`, `lsqnonlin`
and Broyden finds no equilibrium solver (the only optimiser is `fminsearch` in
`Calibrate_NZ_Moments.m:138`, used for SMM calibration). In the current code, prices enter
as parameters (section 1), and the "GE" stages of `WelfareDecomposition_4Region.m` apply those
parameters and re-solve the household problem once. The fixed-point loops that do exist
(`WelfareDecomposition_4Region.m:245-256`, `NZ_4Region_Master.m:231-242`) iterate on the
intergenerational start-of-life distribution `jDist`, not on prices.

Price vector used below: `p = [w_1..w_4, Q_1..Q_4, r]` (4 wages, 4 house prices, 1 interest
rate; the Abroad "region" has no price). The unit of `r` in `Params.r` is the per-period
rate (`dt`-year compounded): 0.20 per 5 years, which is 3.7137% per year (measured with
Octave this run).

## (a) Typed prices, multipliers and closure parameters

`Stands in for` = the market or condition the number currently replaces. `Replacing residual`
= the residual (demand minus supply, relative) that would determine it. Symbols: `L^d_k, L^s_k`
labour demand/supply in region k (effective units); `H^d_k, H^s_k` housing demand/supply;
`A^s, K^d, B` asset supply, productive-capital demand, government debt.

Scope: the typed prices and multipliers found in the 4-region pipeline, plus the rows for the 2-region
script (`SpatialHousing_Intergen_Main.m`) and the fertility module's scenario baseline. This is the
result of a grep over the repository, not a claim of exhaustiveness for values built inside plotting code.

### Prices and price multipliers

| Name | Value(s) | file:line | Stands in for | Replacing residual |
|---|---|---|---|---|
| `Params.w_reg.HH_*`, `.Firm_*` (SS0 wages) | 0.85, 0.93, 1.05, 1.18 (Rural, Small, Large, Auckland) | `NZ_4Region_Master.m:140-143` | regional labour markets, SS0 | `Z^L_k = (L^d_k(w_k,r) - L^s_k(p)) / L^s_k` |
| `Params.Q_reg.HH_*` (SS0 house prices) | 1.05, 1.40, 2.05, 3.10 | `NZ_4Region_Master.m:133-136` | regional housing markets, SS0 | `Z^H_k = (H^d_k(p) - H^s_k(Q_k)) / H^s_k` |
| `Params.Q_reg_base` | same four values | `NZ_4Region_Master.m:137` (copy); `Configure_TimeGrid_Params.m:82-84` (typed default) | SS0 reference for ratios (`kaiako_cooling`, `elder_home_mult`) | none (reference); one option is to read it from the solved SS0 `Q` |
| `Params.r` (SS0 interest rate) | `(1+0.20)^(dt/5)-1` = 0.20 at dt=5, only if not already set | `Configure_TimeGrid_Params.m:66` | capital/bond market, SS0 | `Z^r = (A^s - K^d - B) / A^s` |
| `Params.w_reg.HH_Rural/Urban`, `.Firm_*` (2-region script) | 0.88, 1.12 | `SpatialHousing_Intergen_Main.m:129-130` | regional labour markets, 2-region variant | `Z^L_k` as above |
| `Params.Q_reg.HH_Rural/Urban` (2-region script) | 1.10, 2.45 | `SpatialHousing_Intergen_Main.m:131-132` | regional housing markets, 2-region variant | `Z^H_k` as above |
| `Params.r` in the 2-region script | 0.20 (header says "initial guess for regional GE prices"; no loop follows) | `SpatialHousing_Intergen_Main.m:127-132` | same | same |
| `r_delta` | -0.004 (SS1), -0.006 (SS2), added to the per-period `Params.r` | `WelfareDecomposition_4Region.m:50, 81`, applied at `:183` | change in `r` after the reform | `r` solved per phase (`Z^r`) |
| `w_mult_vs_SS0` SS1 | [1.032 1.038 1.048 1.055] | `WelfareDecomposition_4Region.m:51`, applied `:226-227` | wage response to the reform | `w_k` solved per phase (`Z^L_k`) |
| `w_mult_vs_SS0` SS2 | [1.068 1.075 1.088 1.096] | `WelfareDecomposition_4Region.m:82` | same, phase 2 | same |
| `Q_mult_vs_SS0` SS1 | [0.990 0.975 0.950 0.925] | `WelfareDecomposition_4Region.m:52`, applied `:228-229` | house-price response | `Q_k` solved per phase (`Z^H_k`) |
| `Q_mult_vs_SS0` SS2 | [0.985 0.955 0.925 0.895] | `WelfareDecomposition_4Region.m:83` | same, phase 2 | same |
| `w_mult_GE`, `Q_mult_GE` | `Params.w_mult_SS1`, `Params.Q_mult_SS1` (the SS1 vectors; typed at `Configure_TimeGrid_Params.m:147, 150`) | `PolicyExperiment_LeeSeshadri_4Region.m:77-78`, applied `:85-87` | same, counterfactual P0_Plus_GrantE | same, per counterfactual |
| `Q_mult` (scenario table) | `Params.Q_mult_SS1` [0.990 .975 .950 .925] and `Params.Q_mult_SS2` [0.985 .955 .925 .895] (typed at `Configure_TimeGrid_Params.m:150-151`) | `FertilityBargaining_Module.m:107, 119` | same, fertility module | same |
| `Q_mult` baseline (no reform) | `Params.Q_mult_SS0` [1.000 1.000 1.000 1.000] (typed at `Configure_TimeGrid_Params.m:149`) | `FertilityBargaining_Module.m:79` | identity house-price multiplier for the status-quo scenarios | solved `Q` per scenario |
| `Q_mult_Map` (`Q_mult` in `Build_Phase_Registry.m`) | Rural .990, Small .975, Urban .960, Large .950, Auckland .925 | `Plot_ChildFates_SSankey.m:207`, `Plot_ChildFiscal_SSankey.m:251`, `Build_Phase_Registry.m:127` | same, plotting/registry fallbacks | read solved `Q` from the phase `Params` |
| wage multiplier | 1.035 | `Build_Phase_Registry.m:160` (fallback when no `StatDist_SS2`) | SS2 wage response | read solved `w` |
| wage multiplier | 1.042 (reform panel) | `Plot_ChildFiscal_SSankey.m:323` | reform wage response in the fiscal ledger | read solved `w` |
| `Q_init`, `Q_end_SS1`, `Q_end_SS2` | [1.00 1.40 2.05 3.10]; x[.990 .975 .950 .925]; x[.985 .960 .930 .900] | `TransPath_4Region_Master.m:153-155` | endpoints of the house-price path | SS0/SS1/SS2 solved `Q`; interior from the shooting loop (d) |
| `Params.G_reg` | 1.007, 1.011, 1.018, 1.025 | `NZ_4Region_Master.m:127-130` | expected regional house-price growth in the user cost (`ReturnFn_SpatialHH.m:49-51`) | expectation consistent with the `Q` path (shooting) |
| `r_gov_bond` | 0.042 (annual) | `Plot_ChildFiscal_SSankey.m:707` | sovereign yield in the debt-service ledger | link to solved `r` or keep as a separate fiscal parameter (Author decision) |
| `mu_infra_div` | 1.65 | `Plot_ChildFiscal_SSankey.m:708` | public-infrastructure yield | enters firm productivity `A_k`; see (c) |
| w-multiplier comment "1.65x Public Infra" | in comment text only | `WelfareDecomposition_4Region.m:82` | link between the 1.65 infrastructure multiplier (`mu_infra_div`) and the SS2 wage vector | `A_k(mu_infra_div)` in the labour-demand side |
| `(1.65 / max(0.80, Q_reg))^0.34` | 1.65 (a house-price reference level, not `mu_infra_div`) | `HumanCapital_Lifecycle_aprimeFn.m:21` | spatial kaiako supply | none; flagged only to avoid conflating the two 1.65 |

### Supply side and market structure (typed, currently inactive or exogenous)

| Name | Value(s) | file:line | Stands in for | Replacing residual |
|---|---|---|---|---|
| `Params.delta_H.HH_*` (housing supply elasticity) | 0.35, 0.28, 0.18, 0.10 | `NZ_4Region_Master.m:133-136` | `H^s_k(Q_k)` | defined but **not read anywhere** (grep over all `.m`); would define `H^s_k = Hbar_k Q_k^delta_H,k` |
| `H_scale_*`, `delta_H_*` (2-region script) | 1.20/0.85; 0.30/0.15 | `SpatialHousing_Intergen_Main.m:99-102` | same | same; also not read |
| `Params.PTypeWeights` | 0.9 x [.160 .240 .259 .341] households, 0.1 x [.150 .230 .269 .351] firms | `NZ_4Region_Master.m:24-28` | fixed regional labour supply and firm count | `L^s_k` becomes an output of the household distribution; with endogenous migration the weights move with `Z^L_k`, `Z^H_k` |
| `alpha_k`, `lambda_col` | 0.33, 1.80 | `NZ_4Region_Master.m:178` | capital share; collateral limit `k = lambda_col * a` | parameters of `L^d_k`, `K^d` |
| `delta_k` | `1-(1-0.06)^dt` | `Configure_TimeGrid_Params.m:68` | depreciation in the firm user cost | parameter of `K^d` |
| `z_grid.Firm_*` | [.70 1.15], [.75 1.28], [.83 1.50], [.90 1.75] | `NZ_4Region_Master.m:115-118` | regional TFP ceilings `A_k` | parameters of `L^d_k` |
| `marg_prod_k = alpha_k*((1-alpha_k)/w)^((1-alpha_k)/alpha_k)*z` | closed form with labour optimised out | `ReturnFn_Firm.m:10` | firm labour demand (implicit) | `L^d_k` is never returned; add it as a `FnsToEvaluate` |
| firm payoff `F = log(div_payout)` | | `ReturnFn_Firm.m:34` | firm profit/dividend | does not enter any household budget (`ReturnFn_SpatialHH.m:80-87` uses `w_reg*h*z*l`, `r*(1-tau_k)*a`; no `Firm_*` reference in `ReturnFn_SpatialHH.m` or `Build_IntergenTransitionMatrix.m`); closure needs a profit/dividend transfer to owners |
| `w_akl_ratio`, `Q_akl_ratio` denominators | 1.180, 3.100 (literals) | `Build_IntergenTransitionMatrix.m:253-254` | SS0 Auckland `w`, `Q` in the migration "reform pull" | one option is to read a new `Params.w_reg_base` field (analogous to the existing `Params.Q_reg_base`, `NZ_4Region_Master.m:137`) and `Q_reg_base`; the literals go stale if SS0 prices become solved values |
| migration utilities, Pi_dom, m_intl, zeta_c | 4x5 matrix; 4x4 matrix; [.08 .14 .28 .50]; .035*dt/5 | `Configure_TimeGrid_Params.m:91-95`; `TransPath_4Region_Master.m:41-46` | regional sorting | `Z^L_k`, `Z^H_k` feed back through utilities `V_k` |

### Fiscal closure parameters (a government budget residual is not in this first scope)

| Name | Value(s) | file:line | Stands in for | Replacing residual |
|---|---|---|---|---|
| `tau_l, tau_c, tau_k, tau_a, tau_b` | .22, .15, .20, .005, .15 | `NZ_4Region_Master.m:177` | tax rates | government budget `Z^G = (T - G - transfers - r B)/Y`; `tau_l` the natural adjuster |
| `tau_l_delta` | 0 (SS1); `-0.0350 - transfer_retire_tax_div + super_tax_cost` (SS2), with `transfer_retire_tax_div = 0.0075 * psi_ret` and `psi_ret = Params_SS0.psi_retire_T` = 0.850 | `WelfareDecomposition_4Region.m:49, 88, 109-110`; `Configure_TimeGrid_Params.m:170` | revenue-neutral PAYE change | `Z^G = 0` per phase |
| `p_super`, `Transfer_Geo`, `YouthGrant` | .18; .025/.020/.016/.014; .03 | `NZ_4Region_Master.m:175-176, 152-155` | pension and transfers | expenditure side of `Z^G` |

### Cites in the repository that point at the GE machinery

| Where | What it says | Observation |
|---|---|---|
| `Run_All_NZ_Intergen_Suite.m:39` | "Run 60-year shooting algorithm (TransPath_4Region_Master.m)" | `TransPath_4Region_Master.m` has no shooting loop (section 4 below) |
| `Plot_Counterfactuals_And_MirrorInvestments.m:29-30` | `SS1_Target_Reg`, `SS2_Target_Reg` typed, overwritten from workspace `T1` if present (`:35-36`) | no `ValueFnIter`, `StationaryDist` or `Solve_*` call in the file |
| `Plot_CumulativeTransitionPayoffs.m:1, 79, 84` | consumes `PricePath.Y_reg`, `PricePath.TaxRev_reg` | nothing in the repository constructs `PricePath` |

Units note for the author: `r_delta = -0.006` is added to the per-period (5-year) rate
`0.20`. Measured with Octave this run: that is -10.4 bp per year (and -0.004 is -6.9 bp), whereas
`Document 1A.md:335` describes the SS2 step as -60 bps. If -60 bp per year is the intent, the
per-period delta is about -0.0343 (measured). Worth confirming which is meant.

## (b) Wiring points (read-only list; nothing here is edited)

The household block that `excess_demand_fn(p)` would call is the existing sequence
VFI -> stationary distribution -> (intergenerational `jDist` fixed point) -> aggregation.

| Step | Existing call site | Role in the new residual |
|---|---|---|
| Price vector -> `Params` | `WelfareDecomposition_4Region.m:183` (`r`), `:226-228` (inside the loop opened at `:222`, setting `w_reg.HH_*`, `w_reg.Firm_*`, `Q_reg.HH_*`) | one option is to replace the multiplier lines by a `Prices_To_Params(p, Params_SS0)` helper; `:229-230` (`elder_home_mult`, `K_whanau`) depend on `Q` and would be recomputed from the trial `Q` |
| Household VFI | `WelfareDecomposition_4Region.m:17-18, 178-179, 240-241`; `NZ_4Region_Master.m:222-224`; `PolicyExperiment_LeeSeshadri_4Region.m:94` | inside `excess_demand_fn` |
| Stationary distribution | `WelfareDecomposition_4Region.m:22-24, 246-248`; `NZ_4Region_Master.m:232-234`; `PolicyExperiment_LeeSeshadri_4Region.m:97, 110` | inside `excess_demand_fn` |
| `jDist` fixed point (12 passes max) | `WelfareDecomposition_4Region.m:245-256`; `NZ_4Region_Master.m:231-242`; `Build_IntergenTransitionMatrix.m` | nested inside the price loop (prices outer, `jDist` inner) or merged into one stacked residual; Author decision |
| Aggregation via `FnsToEvaluate` | pattern at `Calibrate_NZ_Moments.m:13-58` (`L_FTE`, `LogWage`, ...) and the call at `:203` (`EvalFnOnAgentDist_AggVars_FHorz_Case1_PType`) | `L^s_k` (effective labour: `(agej<Jr)*l*h*z`, cf. `ReturnFn_SpatialHH.m:80`), `H^d_k` (housing demand from `c_H`, `ReturnFn_SpatialHH.m:96`), `A^s` (`a`) |
| Firm side | `ReturnFn_Firm.m:10, 15` (`marg_prod_k`, `k = lambda_col*a`); firm PType grids `NZ_4Region_Master.m:93-98` | add `FnsToEvaluate` returning labour demand `n*` and capital `k` for `Firm_k` to build `L^d_k` and `K^d` |
| Housing supply | `NZ_4Region_Master.m:133-136` (`delta_H`, unused) | `H^s_k(Q_k)` |
| Migration/weights | `Build_IntergenTransitionMatrix.m:253-254, 264` | price-dependent sorting; one option is to replace the literals 1.180 / 3.100 with base-price fields |
| Phase orchestration | `WelfareDecomposition_4Region.m:125` (`for m = 1:M_reforms`), stage B at `:181-241` | the loop replaces stage B's multiplier application, once per phase |
| Entry script | `Run_All_NZ_Intergen_Suite.m:231-257` | no change to the call order; add a closure flag next to `Run_Transition_Path` (`:39`) |

## (c) Three closures as selectable modes

Proposed selector: `Params.closure` in `{'neoclassical','keynesian','fixed_price'}` (default
`'fixed_price'`, which is intended to reproduce the present behaviour once wired). One-line residual definitions:

- **neoclassical**: unknowns `(w_k, Q_k, r)`; residuals `Z^L_k = (L^d_k(w_k,r) - L^s_k)/L^s_k`, `Z^H_k = (H^d_k - H^s_k(Q_k))/H^s_k`, `Z^r = (A^s - K^d - B)/A^s`, all set to 0. Wages clear labour, `r` clears the asset market, `Q` clears housing.
- **keynesian**: `w_k = w_k^0` held fixed (SS0 value or a stated rule); the labour-market unknown becomes a regional employment rate `e_k in (0,1]` with residual `Z^e_k = e_k L^s_k - L^d_k(w^0_k, r)` (the quantity adjusts, with a rationing rule in the household problem); `Q_k` and `r` clear as in neoclassical.
- **fixed_price**: no unknowns; `excess_demand_fn(p) = p - pbar`, with `pbar` the present typed values (`w^SS0 .* w_mult_vs_SS0`, `Q^SS0 .* Q_mult_vs_SS0`, `r^SS0 + r_delta`). Market residuals are reported as diagnostics, not forced to zero. It is the degenerate mode, intended to match the current pipeline once wired.

What the modes define and do not define: each mode defines which variables are unknowns and
which residuals are driven to zero. **No ordering of the implied welfare gains across the three
modes is assumed or claimed** (in particular not fixed-price >= Keynesian >= neoclassical);
the comparison is an output to be measured, for example with the stage-2 consumption-equivalent
rows of `WelfareDecomposition_4Region.m:305-307` computed under each mode.

## (d) Shooting algorithm for the transition

Current state of `TransPath_4Region_Master.m`: sections 1-4 (`:33-191`; the typed matrices and
blends sit at `:41-46, 100-147, 153-160, 164-191`) are closed-form: cohort CE is an
exponential blend of the SS1/SS2 `T1` rows (`:100-147`), `Q_path` is `Q_init` blended toward
`Q_end_SS1/SS2` with fixed time constants (`:164-175`), emigration and cohesion are logistic /
exponential blends of typed endpoints (`:158-160, 165, 172-190`). `Q_init(1)` is 1.00 here against
1.05 at `NZ_4Region_Master.m:133`, and `Q_end_SS2` uses [.985 .960 .930 .900] against
[.985 .955 .925 .895] at `WelfareDecomposition_4Region.m:83`. No household problem is solved
along the path.

A shooting algorithm would add:

1. **A price path** `P = {w_{k,t}, Q_{k,t}, r_t}` for `t = 1..T_trans` (`T_trans = round(60/dt)`: 12, 20, 30, 60 for dt = 5, 3, 2, 1), with endpoints given by the solved SS0 and SS1 (SS2) prices from the loop in (b), replacing `TransPath_4Region_Master.m:153-155`.
2. **Backward induction** of household value/policy functions given `P` (the VFI Toolkit transition-path routines or a stacked `ValueFnIter_MixHorz_PType` per `t`), then **forward iteration** of the distribution from SS0.
3. **A residual path** `Z_t(P)` from the same definitions as (c); `excess_demand_fn(P_stacked)` returns `[Z_1; ...; Z_T]`.
4. **Updating `P`** with `Solve_Spatial_GE_Loop` (stacked unknowns, `n = 9T`) or period by period.
5. **Information structure**: `Phase2_Announcement_Mode` (`:28-31, 134-140, 176-180`) maps to what the path assumes households know: 'PreAnnounced' = households solve backward against the full path; 'EarnedCred' = the credibility weight `lam_c` ramps from 0.25 toward 1.0 (`:137`), i.e. partial weight on the announced path; 'Unannounced_MIT' = path revealed at `T_phase2_yr`.
6. **Convergence check** on `max_t ||Z_t||_inf`, which the closed-form blends cannot provide.

Where the loop could be called: one option is to replace section 4 (`:151-191`, the `for t = 1:T_trans` loop at `:162`) by
a call that returns `Q_path`, `w_path`, `r_path`, `s_HH_path`, and to replace the CE blends in
section 3 (`:78-149`) by CE computed from the path. `Plot_CumulativeTransitionPayoffs.m:79,84`
already expects a `PricePath` struct (`Y_reg`, `TaxRev_reg`) that this step could populate.

Non-convergence reporting: by default `Solve_Spatial_GE_Loop` issues the warning `IGW:NoConvergence`
at `max_iter`, returns the last iterate and sets `res.converged = false` (the run is kept, not lost);
`opts.on_fail = 'error'` raises the same identifier instead. Any driver that loops over phases,
closures or counterfactuals would need to record `res.converged` per run so unconverged equilibria
are visible in the output tables.

Solver note for (d): the stacked system has `n = 9T` unknowns (108 at dt=5). The default
`opts.jac0 = 'fd'` costs `n` extra evaluations; at that size one option is `jac0 = 'diag'` or a supplied
block-triangular Jacobian (prices at `t` depend on prices at `t' >= t` through expectations
and on `t' <= t` through the distribution).

## (e) Run-cost note

Nothing in this section was measured on the real model (NOT EXECUTED: no MATLAB, no VFI Toolkit
here). What is known from the code and from the toy:

- One `excess_demand_fn` evaluation = household VFI for 4 HH PTypes (grids `n_a = [61 7 9]`, `n_z = 7`, `n_d = [4 3 7]` at `NZ_4Region_Master.m:61-68`; `J = 80/dt`) + 4 firm PTypes + stationary distribution + up to 12 `jDist` passes. Each new price vector is a cache miss for `Get_ModelConfigHash.m` (the hash includes `Params`).
- Evaluations per solve (toy, 5 prices, measured this run): damped 69 evaluations (68 passes), good-Broyden 24 evaluations (17 passes; 1 initial point + 5 finite-difference columns + 18 trial points). Real counts will differ; with 9 prices Broyden-FD adds 9 evaluations up front.
- Cost multipliers: stationary GE = evaluations x cost(VFI + dist) per phase (2-3 phases); transition = the same per period if solved period by period (T = 12 at dt=5, 60 at dt=1), or evaluations x (backward + forward sweep over T) if stacked.
- Levers: warm-start each phase from the previous phase's prices; reuse the final Broyden inverse Jacobian as `jac0` for the next phase/counterfactual; loosen `tol` first and tighten; run on coarse grids first; set `opts.step` to typical price magnitudes and use relative residuals (unscaled `damped` did not converge in 20000 passes on the toy).

## Open choices for the author

Which closure is the headline; which markets to clear first (suggested order: housing and labour
by region with `r` fixed, then add `r`); whether `jDist` is nested or stacked; whether housing
enters the asset-market residual; the employment-rationing rule for the Keynesian mode; whether
firm profits are rebated to owners; and the unit of `r_delta`.
