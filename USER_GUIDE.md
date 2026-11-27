# Intergenerational Welfare Model: Workbench User Guide

This guide outlines the zero-install HTML5 interactive explorers (the **recommended front door** for exploring policy combinations and downloading CSV ledgers), the modular directory layout, the Three-Layer Data & Policy Architecture, and how to execute full numerical suite runs in MATLAB and GNU Octave.

---

## 0. Interactive HTML5 Explorers (Preferred Policy & CSV Workflow)

Before launching MATLAB or GNU Octave, note that the repository includes **standalone, zero-dependency HTML5 workbenches** that open directly in any modern browser (`file://` or static web host) and generate **on-demand CSV downloads** without leaving ad-hoc plot or table clutter in `output/`:

1. **`igwelfare_policy_mirage_explorer.html` — Policy Mirage, 5-Regime Reform Mirrors & Additionality Explorer (`C01`–`C18`):**
   * **What It Does:** Evaluates any subset of the 18 ongoing institutional commitments across all **4 Portfolio Lanes** and **5 Public-Finance Accounting Lenses** (`4-Yr OBEGALx Cash`, `8.0% Siloed CBA`, `2.5% Siloed CBAx`, `2.5% Canonical IGWelfare GE`, and `2.0%/1.5% Official NZ Treasury SRTP`).
   * **Two-Sided Shock vs. `+Reform` Toggles:** Toggle any item between its calibrated 2024–2026 `Shock`, `Off`, or its literature-grounded `+Reform` mirror across the five asymmetric regimes (`C18` 1.2%-base onshore clean-defence stern-kick, `C04`/`C05` future-proofed buffers, `C02` 12-year lab-plant stern-kick, scalable interior programs `C01`/`C06`/`C15`/`C16`, and the 1/3-to-1/2 behavioral/incidence kinks on `C08`, `C07`, `C09`, `C11`, `C13`), or type signed set expressions directly (`c01, c05, c06, c08` or `ret10, +c06, +c15, +c16`).
   * **Four Live Views + CSV & CLI Export:** Switch across **View A** (Groupings & Multipliers), **View B** (Dynamic Waterfall Bridge & exact `2^m` Shapley Attribution), **View C** (2023–2065 `LTFM` Debt Crossover & Annual Flows), and **View D** (5-Lens Accounting Translator), plus **Tab 2** (full MathJax Algebraic & Accounting `README`). Click **Download Active View CSV** for instant tables or **Copy MATLAB/Octave CLI Call** when you need a high-DPI publication `.png`.
2. **`igwelfare_clearinghouse_explorer.html` — "Thick" vs. "Thin" Citizens' Assembly Combinatorial Clearinghouse (`K01`–`K15`):**
   * **What It Does:** Simulates 28-round tâtonnement across five parallel Citizens' Assemblies (`A1`–`A5`) and 15 bilateral contracts (`K01`–`K15`), sweeping historical backlog severity from **1972 (`1/16x` Dunedin Baseline)** to **2026 (`1.0x LTFM`)**, testing Small-Open-Economy shocks (`S1`–`S5`), and running 1,000-trial heterogeneous Monte Carlo benchmarks with CSV export.
3. **Interactive Lifecycle & Fiscal Sankey HTML Exports (`output/<Profile_ID>/*_Interactive.html`):**
   * Generated via `exportSankeyToHTML.m` (`Plot_ChildFates_SSankey.m` and `Plot_ChildFiscal_SSankey.m`) for 29-node ribbon inspection and keyboard traversal.

### Repository Output Hygiene Policy (`output/<Profile_ID>/`)
To keep Git history lean and avoid dozens of combinatorially named `Fig_LTFM_SingleShock_*`, `Fig_Doc3_Set_*`, and `Table_*` artifacts accumulating in `output/`:
* **Keep in Git (`output/<Profile_ID>/`):** Only the canonical leave-behind figures and interactive Sankey HTMLs embedded directly in `Document 1A`–`1F`, `Document 2A`–`2T`, and `Document 3` (for the Policy Mirage suite: `Fig_Doc3_Coalition_ShockByShock_Mirage_Multiplier_<Anchor>.png`, `Fig_Doc3_Coalition_Negative_Additionality_Wedges_<Anchor>.png`, and `Fig_Doc3_Accounting_Lens_Translator_<Anchor>.png`).
* **Explore & Export via HTML5 (or Clean Up Ad-Hoc CLI Runs):** Use `igwelfare_policy_mirage_explorer.html` for single-commitment deep dives (`C01`–`C18`), custom subsets (`Set*`), and CSV table downloads. Any ad-hoc `Fig_LTFM_SingleShock_*`, `Table_LTFM_SingleShock_*`, `Fig_Doc3_Set_*`, or `Table_Doc3_Set_*` files generated locally via MATLAB/Octave are transient working artifacts and should not be committed.

---

## 1. Architectural Principles

The `IGWelfare` repository separates empirical grounding, rollout staging, governance contingencies, and numerical solvers across two orthogonal contracts:

### A. The Three-Layer Data & Policy Stack (`profiles/<Profile_ID>/`)
1. **Layer 1 — Empirical World (`DataSpec = Load_Empirical_Profile(Profile_Name)`):**
   * Pure, idempotent loader reading `profile.yaml`, `regions.csv`, `demography_5yr.csv`, `migration_utility.csv`, `transition_sorting.csv`, and `target_moments.csv`.
   * Built-in profiles include `'NZ_Dunedin1972'` (legacy alias `'Dunedin_22'`) and `'NZ_GUiNZ2009'` (legacy alias `'MetroSqueeze_GUiNZ'`, demonstrating single-parent `Inherits_From` profile inheritance), plus `profiles/TEMPLATE_Profile/` for custom jurisdictions.
2. **Layer 2 — Kinematic Rollout Schedule (`RolloutSpec = Load_Rollout_Schedule(DataSpec, Rollout_Mode)`):**
   * Defines how investment gates, regional echelons, tax ramps, and implementation frictions (`tau_friction_0`, `phi_adj_bottleneck`, `gamma_learning`) unfold in relative track time (`'TeKahuiWaka'`, `'SingleShot'`, or `'Frictionless_Textbook'`).
3. **Layer 3 — State-Contingent Governance (`ContingencySpec = Load_Contingency_Policy(DataSpec, Policy_Name)`):**
   * Declarative YAML gate policies (`'contingent_armada'`, `'fixed_calendar_2050'`) evaluated via `Evaluate_Contingency_Gates.m` to determine *when* and *whether* downstream tracks (such as `SS2` dividend harvest) unlock based on realized fiscal and human-capital metrics.

### B. Three-Tier Content-Hashed Caching (`Get_ModelConfigHash.m` & `Validate_CacheConfig.m`)
* **`SS0_*` (Steps 1–5 Baseline Steady State):** Hashed strictly on Layer 1 `DataSpec` + structural baseline parameters. Editing rollout modes or contingency gates **never** invalidates baseline 5D/4D steady-state caches.
* **`SSReform_*` (Step 6 Reform Steady States):** Hashed on `SS0_*` + asymptotic delivery multipliers (`Rollout_Mode`), invariant to Layer 3 contingency rules.
* **`Trans_*` (Step 7+ Transition & VaR):** Hashed on all three layers (`DataSpec` + `RolloutSpec` + `ContingencySpec`).
* Outputs and caches are automatically isolated per profile under `output/<Profile_ID>/` and `cache/<Profile_ID>/`.

---

## 2. Repository Directory Hierarchy

* `igwelfare_policy_mirage_explorer.html` & `igwelfare_clearinghouse_explorer.html` — Standalone, zero-install HTML5 interactive policy, additionality, and Citizens' Assembly workbenches with built-in CSV export
* `setup_igw_paths.m` — Authoritative path, toolkit, and 3-backend bootstrap (`matlab_cuda`, `matlab_cpu`, `octave_pool`)
* `profiles/` — Modular CSV + YAML empirical profiles, rollout schedules, `commitment_catalog.csv` (with 5-Regime two-sided `+Reform` parameters), `policy_bundles.yaml`, and contingency policies
* `src/data/` — `Load_Empirical_Profile.m`, `Load_Rollout_Schedule.m`, `Load_Contingency_Policy.m`, `Evaluate_Contingency_Gates.m`, `Load_Commitment_Catalog.m`, `Read_IGW_YAML.m`, `Read_IGW_CSV.m`
* `src/config/` — 4-tier epistemic parameter pipeline (`Configure_Model_Params.m`, `Apply_Empirical_Data.m`, `Apply_Calibrated_Params.m`, `Apply_Policy_Regime.m`, `Configure_Grid_And_Prefs.m`, `Describe_Params_Provenance.m`, `Configure_TimeGrid_Params.m`), `Compose_Policy_Bundle.m`, `Ensure_Workbench_Initialized.m`, `Build_Phase_Registry.m`, `Default_Reform_Phase_Specs.m`, `Get_ModelConfigHash.m`, `Validate_CacheConfig.m`
* `src/models/` — Pure, side-effect-free Bellman kernels (`ReturnFn_SpatialHH.m`, `ReturnFn_SpatialHH_Compact4D.m`, `ReturnFn_Firm.m`, `HumanCapital_Lifecycle_aprimeFn.m`) and general-equilibrium counterfactual/composition solvers (`Compute_Policy_Composition_Batch.m`, `Compute_FiscalSolvency_And_Fertility.m`, `Compute_LeeSeshadri_Counterfactuals.m`, `Compute_WelfareDecomposition_4Region.m`, `Compute_TransitionPath_4Region.m`)
* `src/ledgers/` — Pure, headless accounting & attribution ledgers (`Compute_Actuarial_Ledger.m`, `Compute_Synergy_And_Mirror_Ledger.m`, `Compute_Civic_Gearing_Ledger.m`, `Compute_Divergence_Trajectory_Ledger.m`, `Compute_ThreeTier_NationalAccounts_Ledger.m`, `Compute_Public_Asset_Stewardship_Ledger.m`, `Compute_NDC_Compliance_Ledger.m`, `Compute_Assembly_Clearinghouse_Ledger.m`, `Compute_Contract_Shock_Sensitivity_Ledger.m`)
* `src/solvers/` — `Solve_VFI_PhaseSplit.m`, `Precompute_HH_StationaryCache.m`, `PushForward_HH_Dist.m`, `Build_IntergenTransitionMatrix.m`
* `src/calibration/` — `Calibrate_NZ_Moments.m`
* `src/utils/` — Single-source platform & UI contracts (`Resolve_Compute_Backend.m`, `IGW_UI_Style.m`, `IGW_MD5_Hex.m`, `IGW_Restore_Tables.m`, `vfi_active_ax.m`, `enable_vfi_cpu_accel.m`, `IGW_Log.m`, `Resolve_IGW_OutputDir.m`)
* `pipelines/` — Top-level orchestration scripts (`Run_All_NZ_Intergen_Suite.m`, `NZ_4Region_Master.m`, `PolicyExperiment_LeeSeshadri_4Region.m`, `FertilityBargaining_Module.m`, `WelfareDecomposition_4Region.m`, `TransPath_4Region_Master.m`) and post-simulation sensitivity engines (`Audit_GUiNZ_vs_Dunedin_4Region.m`, `Run_WealthTax_Exemption_Sensitivity.m`)
* `plots/` — Publication figure, HTML5/SVG Sankey (`exportSankeyToHTML.m`), and set-algebraic policy mirage modules (`Plot_*.m`, incl. `Plot_LTFM_Coalition_Shock_Mirage.m`)
* `tests/` — Automated cross-platform verification suite (`run_all_tests.m` + 23 contract tests)

---

## 3. Setting Up Your Workbench Manually

Initialize your MATLAB (CUDA GPU or CPU-only / MATLAB Online) or GNU Octave session from the repository root with `Ensure_Workbench_Initialized` (or `setup_igw_paths()` + `Configure_Model_Params`):

    clear; clc; close all;
    setup_igw_paths();

    % Single-call 4-tier parameter + optional Octave RAMDisk worker-pool bootstrap:
    Params = struct( ...
        'Profile_Name',       'NZ_Dunedin1972', ... % Or 'NZ_GUiNZ2009'
        'Rollout_Mode',       'TeKahuiWaka',    ... % 'TeKahuiWaka', 'SingleShot', or 'Frictionless_Textbook'
        'Contingency_Policy', 'contingent_armada', ...
        'dt',                 3, ...
        'n_z_pts',            7);
    [Params, Regions] = Ensure_Workbench_Initialized(Params, struct('RequireWorkerPool', true));
    OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);

    % Inspect active hardware backend ('matlab_cuda', 'matlab_cpu', or 'octave_pool')
    Backend = Resolve_Compute_Backend();

### Composing Custom Policy Counterfactuals (`Compose_Policy_Bundle.m`)
Every ongoing institutional commitment in `profiles/<Profile_ID>/policies/commitment_catalog.csv` uses signed Convention-2 dials (`u > 0` strengthens/expands; `u < 0` retrenches/defers; tax/expensing dials `C09..C11 > 0` enact relief):

    setup_igw_paths();
    P0  = Configure_Model_Params(struct('Profile_Name', 'NZ_Dunedin1972', 'dt', 3));
    [P_Base, pi_Base] = Compose_Policy_Bundle(P0, struct(), 'baseline_2023');

    % Compose named bundles or pass custom signed dials directly:
    [P_Mix, pi_Mix, Meta] = Compose_Policy_Bundle(P_Base, pi_Base, ...
        {'tax_visa_expensing_3', 'civic_commons_expansion_doc1e'});

    % For interactive exploration & CSV downloads, prefer opening igwelfare_policy_mirage_explorer.html!
    % To regenerate the 3 canonical Document 3 PNGs (or render a specific signed CLI set on demand):
    Plot_LTFM_Coalition_Shock_Mirage('all');                     % Canonical Multipliers + 4-Wedge Bridge PNGs
    Plot_LTFM_Coalition_Shock_Mirage('lenses');                  % Canonical 5-Lens Accounting Translator PNG
    Plot_LTFM_Coalition_Shock_Mirage('ret10, +c06, +c15, +c16'); % On-demand mixed Shock + 5-Regime Reform set

    % Or run the full 5D solved composition & additionality suite:
    run(which('Run_Policy_Composition_Suite.m'));

    % Run the 5-Sector SOE, Exergy, Atkinson-Waring, Public-Asset Stewardship & Trim-Tab suite:
    run(which('Run_Phase2_5Sector_Suite.m'));
    Plot_HelmPhysics_TrimTabs_And_CounterSteering(Configure_Model_Params());

    % Run the Document 1F Five-Assembly Clearinghouse & 5-Risk Contingency Stress-Test suite:
    run(which('Run_Contingency_Suite.m'));

To run the full suite from the command line with overrides:

    setup_igw_paths();
    Profile_Name = 'NZ_GUiNZ2009';
    Params = struct('dt', 3, 'Rollout_Mode', 'SingleShot');
    run(which('Run_All_NZ_Intergen_Suite.m'));

---

## 4. Invoking GNU Octave & MATLAB: Dos and Don'ts

The repository root includes both **`.octaverc`** (for GNU Octave) and **`startup.m`** (for MATLAB), which automatically invoke `setup_igw_paths()`—adding all `src/**`, `pipelines/`, and `plots/` directories, loading `VFIToolkit-matlab` and `VFIToolkit-octave` shims, and configuring safe graphics defaults before your first command runs.

### Recommended Invocations (From Repo Root)
* **Interactive GNU Octave Terminal (with `qt` offscreen plotting support):**
      octave --no-gui
* **Batch / One-Liner GNU Octave Execution:**
      octave --no-gui --eval "run(which('Run_All_NZ_Intergen_Suite.m'));"
      octave --no-gui --eval "Plot_ActuarialContinuationValuation([], struct('Profile_Name','NZ_GUiNZ2009'), 'National');"
* **Pure Compute-Only CLI (no Qt library overhead when no plots are exported):**
      octave-cli
* **Batch MATLAB Execution:**
      matlab -batch "run(which('Run_All_NZ_Intergen_Suite.m'));"

### Critical Don'ts
1. **Do NOT pass `--norc` or `-f` to Octave without calling `setup_igw_paths()`:** Passing `--norc` suppresses `.octaverc`, leaving `src/**` and `VFIToolkit_Octave_Setup` unloaded unless your `--eval` string starts with `setup_igw_paths(true);`.
2. **Do NOT set `graphics_toolkit('gnuplot')` in Octave:** Octave 11's `gnuplot` backend cannot render modern `hggroup` primitives (`xline`, translucent `fill` bands) inside legends. Leave graphics on `'qt'` or `'fltk'` as configured by `setup_igw_paths()`.
3. **Do NOT scatter manual `OCTAVE_VERSION`, `gpuDeviceCount`, or `fltk` checks in model or plotting code:** Use `Resolve_Compute_Backend()` for device placement and `vis = IGW_UI_Style('headless_vis')` (plus `IGW_UI_Style('legend_alpha', lgd)`) so figures export cleanly under MATLAB HG2, Octave Qt, and Octave FLTK (`test_wave4_platform_contracts` enforces this boundary automatically).
4. **Do NOT hardcode relative paths like `run('NZ_4Region_Master.m')` when calling across subfolders:** Use `run(which('NZ_4Region_Master.m'))` so both MATLAB and GNU Octave resolve pipeline scripts cleanly from any working directory.
