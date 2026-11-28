function DecompOut = Compute_WelfareDecomposition_4Region(Params, Grids5D, jDist_Init, Opts)
%% PURE MATHEMATICAL CONTRACT: MULTIPHASE 4-REGION WELFARE & SPATIAL DECOMPOSITION (SS0 -> SS1 -> ... -> SSm)
% File: src/models/Compute_WelfareDecomposition_4Region.m
% Dynamically solves M >= 1 reform phases relative to Baseline SS0 on the canonical 5D grid:
%   - Stage 1: Short-Run PE (policy levers of Phase m, prior prices & jDist)
%   - Stage 2: Long-Run GE with Exogenous Skills (price shifts of Phase m, prior jDist)
%   - Stage 3: Long-Run GE with Endogenous 4x5 Intergenerational Matrix (jDist_SSm)
% Assembles T1, T2, T3, WelfareResults, and Phases (via pure Build_Phase_Registry(..., PhaseSnap))
% with zero evalin, zero assignin, zero figure creation, and zero disk I/O.

if nargin < 4 || isempty(Opts)
    Opts = struct();
end

if ~isfield(Params, 'dt') || ~isfield(Params, 'DataSpec_Digest')
    Params = Configure_Model_Params(Params);
end

if isfield(Opts, 'Regions') && ~isempty(Opts.Regions)
    Regions = Opts.Regions;
else
    Regions = Params.Regions;
end
N_reg    = length(Regions);
ref_hh_0 = ['HH_', Regions{1}];

verbose_log = ~isfield(Opts, 'Verbose') || logical(Opts.Verbose);
n_ig0_iters = 6;
n_igm_iters = 12;
if isfield(Opts, 'MaxIGIter_SS0') && ~isempty(Opts.MaxIGIter_SS0), n_ig0_iters = Opts.MaxIGIter_SS0; end
if isfield(Opts, 'MaxIGIter_SSm') && ~isempty(Opts.MaxIGIter_SSm), n_igm_iters = Opts.MaxIGIter_SSm; end

n_d                      = Grids5D.n_d;
n_a                      = Grids5D.n_a;
n_z                      = Grids5D.n_z;
N_j                      = Grids5D.N_j;
Names_i                  = Grids5D.Names_i;
d_grid                   = Grids5D.d_grid;
a_grid                   = Grids5D.a_grid;
z_grid                   = Grids5D.z_grid;
pi_z                     = Grids5D.pi_z;
ReturnFn                 = Grids5D.ReturnFn;
DiscountFactorParamNames = Grids5D.DiscountFactorParamNames;
AgeWeightsParamNames     = Grids5D.AgeWeightsParamNames;
PTypeDistParamNames      = Grids5D.PTypeDistParamNames;
vfoptions                = Grids5D.vfoptions;
simoptions               = Grids5D.simoptions;

%% 1. SOLVE OR REUSE CANONICAL 5D BASELINE ANCHOR (SS0) ON IDENTICAL RETURN FUNCTION
Params_SS0_Solve       = Params;
Params_SS0_Solve.G_ece = Params_SS0_Solve.G_ece_stage1;
Backend = Resolve_Compute_Backend();
if ~isfield(vfoptions, 'parallel') || isempty(vfoptions.parallel)
    if Backend.UseGPU
        vfoptions.parallel = 2;
    end
end

if isfield(Opts, 'Precomputed_SS0') && isstruct(Opts.Precomputed_SS0) && isfield(Opts.Precomputed_SS0, 'V')
    V_SS0              = Opts.Precomputed_SS0.V;
    Policy_SS0         = Opts.Precomputed_SS0.Policy;
    StatDist_SS0       = Opts.Precomputed_SS0.StatDist;
    jDist_SS0          = Opts.Precomputed_SS0.jDist;
    IG_Diag_SS0_solved = Opts.Precomputed_SS0.IG_Diag;
    if verbose_log
        fprintf('  [DIAG Step6] Reusing precomputed Step 1 5D SS0 baseline (n_a=%s)\n', mat2str(n_a.(ref_hh_0)));
    end
else
    t_w0 = tic;
    [V_SS0, Policy_SS0] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid, pi_z, ...
        ReturnFn, Params_SS0_Solve, DiscountFactorParamNames, vfoptions, Regions);
    if verbose_log
        fprintf('  [DIAG Step6] SS0 VFI (n_a=%s): %.2fs\n', mat2str(n_a.(ref_hh_0)), toc(t_w0));
    end

    t_w0       = tic;
    HH_Cache_0 = Precompute_HH_StationaryCache(Policy_SS0, n_d, n_a, n_z, N_j, d_grid, a_grid, pi_z, Params_SS0_Solve, simoptions, Regions);
    jDist_SS0  = jDist_Init;
    StatDist_SS0 = struct();
    ig0_resid  = Inf;
    for ig0_it = 1:n_ig0_iters
        StatDist_SS0 = PushForward_HH_Dist(StatDist_SS0, jDist_SS0, HH_Cache_0, Regions);
        [jDist_SS0_new, IG_Diag_SS0_solved] = Build_IntergenTransitionMatrix(StatDist_SS0, Policy_SS0, V_SS0, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params_SS0_Solve, Regions);
        ig0_resid = max(cellfun(@(r) max(abs(jDist_SS0_new.(['HH_', r])(:) - jDist_SS0.(['HH_', r])(:))), Regions));
        jDist_SS0 = jDist_SS0_new;
        if ig0_resid < 1e-5
            break;
        end
    end
    if verbose_log
        fprintf('  [DIAG Step6] SS0 IG Loop (%d iters): %.2fs\n', ig0_it, toc(t_w0));
    end
    if ~(ig0_resid < 1e-5) && n_ig0_iters >= 6
        IGW_Log('IGW:NoConvergence', 'Compute_WelfareDecomposition_4Region SS0 intergenerational fixed point: %d iterations, residual %.3g', ...
            ig0_it, double(gather(ig0_resid)));
    end
end
Params_SS0 = Params;
if isfield(Opts, 'IG_Diagnostics_SS0') && ~isempty(Opts.IG_Diagnostics_SS0)
    IG_Diag_SS0 = Opts.IG_Diagnostics_SS0;
else
    IG_Diag_SS0 = IG_Diag_SS0_solved;
end

%% 2. RESOLVE MULTIPHASE REFORM SPECIFICATIONS VIA TIER-D DEFAULT_REFORM_PHASE_SPECS
Enable_SS2_Phase = (isfield(Opts, 'Enable_SS2_Phase') && logical(Opts.Enable_SS2_Phase)) || ...
    (isfield(Opts, 'Active_Phases') && any(strcmpi(Opts.Active_Phases, 'SS2')));

if isfield(Opts, 'Reform_Phase_Specs') && ~isempty(Opts.Reform_Phase_Specs)
    Reform_Phase_Specs = Opts.Reform_Phase_Specs;
    if ~isfield(Reform_Phase_Specs, 'tau_l_delta')
        [Reform_Phase_Specs.tau_l_delta] = deal(0.000);
    end
    if Enable_SS2_Phase && numel(Reform_Phase_Specs) < 2
        def_both = Default_Reform_Phase_Specs(Params_SS0, true);
        Reform_Phase_Specs(2) = def_both(2);
    end
else
    Reform_Phase_Specs = Default_Reform_Phase_Specs(Params_SS0, Enable_SS2_Phase);
end

M_reforms = numel(Reform_Phase_Specs);
eta_c_val = 2.0;
if isfield(Params_SS0, 'eta_c'), eta_c_val = Params_SS0.eta_c; end
exp_ce = 1 / (Params_SS0.phi_nd * (1 - eta_c_val));

CE_Stage_All   = zeros(3 * M_reforms, N_reg);
Stage_RowNames = cell(3 * M_reforms, 1);
WelfareResults = struct();
PhaseObjects   = struct();

PhaseSnap = struct( ...
    'Regions',      {Regions}, ...
    'StatDist_SS0', StatDist_SS0, ...
    'Policy_SS0',   Policy_SS0, ...
    'V_SS0',        V_SS0, ...
    'jDist_SS0',    jDist_SS0, ...
    'Params_SS0',   Params_SS0, ...
    'IG_Diag_SS0',  IG_Diag_SS0);

% Baseline fertile-parent mean skill anchor E_0[h | j in fertile] & horizon normalizer D_eff(j):
h_fert_SS0 = compute_fertile_skill_means(StatDist_SS0, n_a, n_z, a_grid, Params_SS0, Regions);
D_eff_j    = compute_horizon_discount_weights(Params_SS0);
s_post_rel = compute_post_launch_discount_share(Params_SS0);

jDist_prev = jDist_SS0;

%% 3. LOOP OVER REFORM PHASES m = 1 .. M_reforms
for m = 1:M_reforms
    spec   = Reform_Phase_Specs(m);
    p_code = spec.Code;

    if verbose_log
        fprintf('Computing Reform %d of %d: %s\n', m, M_reforms, p_code);
    end

    % 3A. Stage A: Short-Run PE via Single-Source-of-Truth Apply_Policy_Regime
    P_PE        = Apply_Policy_Regime(Params_SS0, spec, struct('Stage', 'PE', 'PhaseIdx', m));
    super_age_m = P_PE.super_age;

    t_wm = tic;
    [V_PE_m, Policy_PE_m] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid, pi_z, ...
        ReturnFn, P_PE, DiscountFactorParamNames, vfoptions, Regions);
    if verbose_log
        fprintf('  [DIAG Step6 %s] PE VFI: %.2fs\n', p_code, toc(t_wm));
    end

    % 3B. Stage B: Long-Run GE with Exogenous Skills via Single-Source-of-Truth Apply_Policy_Regime
    [P_GE, z_grid_m, pi_z_m] = Apply_Policy_Regime(Params_SS0, spec, ...
        struct('Stage', 'GE', 'PhaseIdx', m, 'z_grid', z_grid, 'pi_z', pi_z));
    if super_age_m >= 65
        elder_time_mult = exp(-Params_SS0.eta_elder_whanau * (super_age_m - 65));
    else
        elder_time_mult = 1 + 0.16 * tanh((65 - super_age_m) / 1.8);
    end

    t_wm = tic;
    [V_GE_Exo_m, Policy_GE_Exo_m] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid_m, pi_z_m, ...
        ReturnFn, P_GE, DiscountFactorParamNames, vfoptions, Regions);
    if verbose_log
        fprintf('  [DIAG Step6 %s] GE VFI: %.2fs\n', p_code, toc(t_wm));
    end

    % 3C. Stage C: Endogenous 4x5 Intergenerational & Dynastic h_par_mean Fixed Point (jDist_SSm, V_m)
    P_IG       = P_GE;
    V_m        = V_GE_Exo_m;
    Policy_m   = Policy_GE_Exo_m;
    HH_Cache_m = Precompute_HH_StationaryCache(Policy_m, n_d, n_a, n_z, N_j, d_grid, a_grid, pi_z_m, P_IG, simoptions, Regions);
    jDist_m    = jDist_prev;
    StatDist_m = struct();
    ig_resid   = Inf;

    % Pass 1: Converge newborn distribution jDist_m on initial GE policy:
    for ig_it = 1:n_igm_iters
        StatDist_m = PushForward_HH_Dist(StatDist_m, jDist_m, HH_Cache_m, Regions);
        [jDist_m_new, IG_Diag_m] = Build_IntergenTransitionMatrix(StatDist_m, Policy_m, V_m, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid_m, pi_z_m, P_IG, Regions);
        ig_resid = max(cellfun(@(r) max(abs(jDist_m_new.(['HH_', r])(:) - jDist_m.(['HH_', r])(:))), Regions));
        jDist_m  = jDist_m_new;
        if ig_resid < 1e-5
            break;
        end
    end

    % Pass 2: Harvest endogenous dynastic parental skill h_par_mean.(hh_type) in aprimeFn (Phases 1 & 2):
    if n_igm_iters >= 3
        h_fert_m  = compute_fertile_skill_means(StatDist_m, n_a, n_z, a_grid, P_IG, Regions);
        hpar_base = P_IG.h_par_mean;
        P_IG.h_par_mean = struct();
        max_dhpar = 0.0;
        for r_hp = 1:N_reg
            ht_hp = ['HH_', Regions{r_hp}];
            hp0_r = 1.0;
            if isstruct(hpar_base) && isfield(hpar_base, ht_hp), hp0_r = hpar_base.(ht_hp);
            elseif isnumeric(hpar_base) && isscalar(hpar_base),  hp0_r = double(hpar_base); end
            hp_new = hp0_r * (h_fert_m(r_hp) / max(1e-8, h_fert_SS0(r_hp)));
            P_IG.h_par_mean.(ht_hp) = hp_new;
            max_dhpar = max(max_dhpar, abs(hp_new - hp0_r));
        end
        if max_dhpar > 1e-4
            t_wdyn = tic;
            vfo_dyn = vfoptions;
            vfo_dyn.ReusePostParenting = struct('V', V_GE_Exo_m, 'Policy', Policy_GE_Exo_m);
            [V_m, Policy_m] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid_m, pi_z_m, ...
                ReturnFn, P_IG, DiscountFactorParamNames, vfo_dyn, Regions);
            HH_Cache_m = Precompute_HH_StationaryCache(Policy_m, n_d, n_a, n_z, N_j, d_grid, a_grid, pi_z_m, P_IG, simoptions, Regions);
            for ig_it2 = 1:max(2, ceil(0.5 * n_igm_iters))
                StatDist_m = PushForward_HH_Dist(StatDist_m, jDist_m, HH_Cache_m, Regions);
                [jDist_m_new, IG_Diag_m] = Build_IntergenTransitionMatrix(StatDist_m, Policy_m, V_m, ...
                    n_d, n_a, n_z, d_grid, a_grid, z_grid_m, pi_z_m, P_IG, Regions);
                ig_resid = max(cellfun(@(r) max(abs(jDist_m_new.(['HH_', r])(:) - jDist_m.(['HH_', r])(:))), Regions));
                jDist_m  = jDist_m_new;
                if ig_resid < 1e-5
                    break;
                end
            end
            if verbose_log
                fprintf('  [DIAG Step6 %s] Dynastic h_par_mean VFI+IG (max dh=%.4f): %.2fs\n', p_code, max_dhpar, toc(t_wdyn));
            end
        end
    end

    if ~(ig_resid < 1e-5) && n_igm_iters >= 6
        IGW_Log('IGW:NoConvergence', 'Compute_WelfareDecomposition_4Region phase %s intergenerational fixed point: residual %.3g', ...
            p_code, double(gather(ig_resid)));
    end

    % Record solved phase objects in pure output struct & PhaseSnap (zero assignin!)
    PhaseObjects.(p_code) = struct( ...
        'V',            V_m, ...
        'Policy',       Policy_m, ...
        'StatDist',     StatDist_m, ...
        'jDist',        jDist_m, ...
        'Params',       P_IG, ...
        'IG_Diag',      IG_Diag_m, ...
        'V_PE',         V_PE_m, ...
        'Policy_PE',    Policy_PE_m, ...
        'V_GE_Exo',     V_GE_Exo_m, ...
        'Policy_GE_Exo',Policy_GE_Exo_m);

    PhaseSnap.(sprintf('V_%s', p_code))        = V_m;
    PhaseSnap.(sprintf('Policy_%s', p_code))   = Policy_m;
    PhaseSnap.(sprintf('StatDist_%s', p_code)) = StatDist_m;
    PhaseSnap.(sprintf('jDist_%s', p_code))    = jDist_m;
    PhaseSnap.(sprintf('Params_%s', p_code))   = P_IG;
    PhaseSnap.(sprintf('IG_Diag_%s', p_code))  = IG_Diag_m;

    % 3D. Exact 5D Distributional Integrals for T1 (3-Stage), T2 (Quintiles), & T3 (Tenure/Age)
    CE_Stage_m = zeros(3, N_reg);
    CE_Quint_m = zeros(5, N_reg);
    CE_Ten_m   = zeros(3, N_reg);

    for r_idx = 1:N_reg
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        d0_j1   = double(gather(jDist_SS0.(hh_type)(:)));
        dm_j1   = double(gather(jDist_m.(hh_type)(:)));
        N_st    = numel(d0_j1);

        V0_mat  = reshape(double(gather(V_SS0.(hh_type))),      N_st, Params_SS0.J);
        Vpe_mat = reshape(double(gather(V_PE_m.(hh_type))),     N_st, Params_SS0.J);
        Vge_mat = reshape(double(gather(V_GE_Exo_m.(hh_type))), N_st, Params_SS0.J);
        Vm_mat  = reshape(double(gather(V_m.(hh_type))),        N_st, Params_SS0.J);

        V0_j1  = V0_mat(:, 1);
        Vpe_j1 = Vpe_mat(:, 1);
        Vge_j1 = Vge_mat(:, 1);
        Vm_j1  = Vm_mat(:, 1);

        m_v = isfinite(V0_j1) & isfinite(Vpe_j1) & isfinite(Vge_j1) & isfinite(Vm_j1);
        m0  = m_v & (d0_j1 > 0);
        mm  = m_v & (dm_j1 > 0);

        ev0     = sum(V0_j1(m0)  .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_pe   = sum(Vpe_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_ge   = sum(Vge_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_ig_p = sum(Vm_j1(mm)  .* dm_j1(mm)) / sum(dm_j1(mm));

        % Endogenous macro relational & civic thriving externality (Build_IntergenTransitionMatrix §Stage 3):
        du_rel_r = compute_regional_relational_surplus(IG_Diag_SS0, IG_Diag_m, Params_SS0, P_IG, reg, s_post_rel);
        rel_mult = exp(du_rel_r / Params_SS0.phi_nd);

        CE_Stage_m(1, r_idx) = 100.0 * (((ev_pe / ev0) ^ exp_ce) - 1.0);
        CE_Stage_m(2, r_idx) = 100.0 * (((ev_ge / ev0) ^ exp_ce) - 1.0);
        CE_Stage_m(3, r_idx) = 100.0 * ((((ev_ig_p / ev0) ^ exp_ce) * rel_mult) - 1.0);

        % Direct 5D stationary integrals for T2 (5 Resource Quintiles) & T3 (Tenure x Lifecycle):
        [CE_Quint_m(:, r_idx), CE_Ten_m(:, r_idx)] = compute_5d_quintile_and_tenure_ce( ...
            V0_mat, Vm_mat, StatDist_SS0.(hh_type), StatDist_m.(hh_type), ...
            n_a.(hh_type), n_z.(hh_type), a_grid.(hh_type), z_grid.(hh_type), z_grid_m.(hh_type), ...
            Params_SS0, P_IG, hh_type, D_eff_j, exp_ce, du_rel_r);
    end

    if M_reforms == 1
        Stage_RowNames = {'1_ShortRun_PE'; '2_LongRun_GE_ExoSkills'; '3_LongRun_GE_EndoIntergen'};
        CE_Stage_All   = CE_Stage_m;
    else
        rows_m = (3*(m-1)+1) : (3*m);
        CE_Stage_All(rows_m, :)   = CE_Stage_m;
        Stage_RowNames{rows_m(1)} = sprintf('%s_1_ShortRun_PE', p_code);
        Stage_RowNames{rows_m(2)} = sprintf('%s_2_LongRun_GE_ExoSkills', p_code);
        Stage_RowNames{rows_m(3)} = sprintf('%s_3_LongRun_GE_EndoIntergen', p_code);
    end

    ce_reg_cols = cellfun(@(r) [r, '_CE_Pct'], Regions, 'UniformOutput', false);
    WelfareResults.(p_code).T1_Stage = array2table(CE_Stage_m, ...
        'RowNames', {'1_ShortRun_PE', '2_LongRun_GE_ExoSkills', '3_LongRun_GE_EndoIntergen'}, ...
        'VariableNames', ce_reg_cols);
    WelfareResults.(p_code).T2_Quintile = array2table(CE_Quint_m, ...
        'RowNames', {'Q1_Bottom20', 'Q2_LowMid', 'Q3_Middle', 'Q4_UpperMid', 'Q5_Top20'}, ...
        'VariableNames', ce_reg_cols);
    WelfareResults.(p_code).T3_Tenure = array2table(CE_Ten_m, ...
        'RowNames', {'Young_Renters_Under65', 'Young_Homeowners_Under65', 'Older_Retirees_65Plus'}, ...
        'VariableNames', ce_reg_cols);

    jDist_prev = jDist_m;
end

%% 4. ASSEMBLE MULTIPHASE TABLES & PURE PHASE REGISTRY
ce_reg_cols = cellfun(@(r) [r, '_CE_Pct'], Regions, 'UniformOutput', false);
T1 = array2table(CE_Stage_All, 'RowNames', Stage_RowNames, 'VariableNames', ce_reg_cols);
T2 = WelfareResults.(Reform_Phase_Specs(end).Code).T2_Quintile;
T3 = WelfareResults.(Reform_Phase_Specs(end).Code).T3_Tenure;

Active_Phases = [{'SS0'}, {Reform_Phase_Specs.Code}];
Phases        = Build_Phase_Registry(Active_Phases, PhaseSnap);

DecompOut = struct();
DecompOut.Regions            = Regions;
DecompOut.V_SS0              = V_SS0;
DecompOut.Policy_SS0         = Policy_SS0;
DecompOut.StatDist_SS0       = StatDist_SS0;
DecompOut.jDist_SS0          = jDist_SS0;
DecompOut.Params_SS0         = Params_SS0;
DecompOut.IG_Diag_SS0        = IG_Diag_SS0;
DecompOut.Reform_Phase_Specs = Reform_Phase_Specs;
DecompOut.PhaseObjects       = PhaseObjects;
DecompOut.PhaseSnap          = PhaseSnap;
DecompOut.WelfareResults     = WelfareResults;
DecompOut.T1                 = T1;
DecompOut.T2                 = T2;
DecompOut.T3                 = T3;
DecompOut.CE_Stage           = CE_Stage_All;
DecompOut.CE_Quint           = CE_Quint_m;
DecompOut.CE_Ten             = CE_Ten_m;
DecompOut.Active_Phases      = Active_Phases;
DecompOut.Phases             = Phases;

end

%% ---- PURE ENDOGENOUS DYNASTIC & 5D DISTRIBUTIONAL INTEGRAL HELPERS ----
function h_means = compute_fertile_skill_means(StatDist, n_a, n_z, a_grid, P, Regions)
N_reg   = numel(Regions);
h_means = ones(1, N_reg);
j_fert  = max(1, P.j_s1_start) : min(P.J, P.j_s2_end);
for r = 1:N_reg
    ht   = ['HH_', Regions{r}];
    na   = n_a.(ht);
    Nz   = prod(n_z.(ht));
    ag   = double(gather(a_grid.(ht)));
    h_v  = ag(na(1)+1 : na(1)+na(2));
    D_5d = reshape(double(gather(StatDist.(ht))), [na(1), na(2), na(3), Nz, P.J]);
    D_h  = reshape(sum(D_5d(:, :, :, :, j_fert), [1, 3, 4, 5]), [na(2), 1]);
    h_means(r) = sum(D_h .* h_v(:)) / max(1e-12, sum(D_h));
end
end

function D_eff = compute_horizon_discount_weights(P)
J      = P.J;
dt     = P.dt;
sc_dt  = dt / 5.0;
beta_p = double(P.beta_hh);
sj_v   = double(gather(P.sj(:)'));
D_eff  = zeros(1, J);
D_eff(J) = sc_dt;
for j = (J - 1):-1:1
    D_eff(j) = sc_dt + beta_p * sj_v(j) * D_eff(j + 1);
end
end

function s_post = compute_post_launch_discount_share(P)
J      = P.J;
j_lch  = min(J, max(1, P.j_child_launch));
beta_p = double(P.beta_hh);
w_all  = beta_p .^ (0:(J - 1));
s_post = sum(w_all(j_lch:end)) / max(1e-12, sum(w_all));
end

function du_rel = compute_regional_relational_surplus(IG0, IGm, P0, Pm, reg, s_post)
ht   = ['HH_', reg];
st0  = min(0.95, max(0.0, IG0.StrugglingShare.(reg)));
stm  = min(0.95, max(0.0, IGm.StrugglingShare.(reg)));
em0  = min(0.95, max(0.0, IG0.EmigRate.(reg)));
emm  = min(0.95, max(0.0, IGm.EmigRate.(reg)));
K0   = P0.K_whanau.(ht);
Km   = Pm.K_whanau.(ht);
th0  = IG0.MeanTheta3.(reg);
thm  = IGm.MeanTheta3.(reg);

% Atomistic macro thriving, youth home-retention, completed skill network, & whanau proximity surplus:
u_thrive = 0.35 * log((1.0 - stm) / (1.0 - st0));
u_retain = 0.45 * log((1.0 - emm) / (1.0 - em0));
u_whanau = 0.25 * (Km - K0) + 0.18 * log(max(1e-4, thm) / max(1e-4, th0));
du_rel   = s_post * (u_thrive + u_retain + u_whanau);
end

function [ce_quint, ce_ten] = compute_5d_quintile_and_tenure_ce( ...
    V0_mat, Vm_mat, D0_raw, Dm_raw, na_vec, nz_val, ag_raw, zg0_raw, zgm_raw, P0, Pm, ht, D_eff_j, exp_ce, du_rel_r)

n_a1 = na_vec(1); n_h = na_vec(2); n_th = na_vec(3);
Nz   = prod(nz_val);
J    = P0.J;
dt   = P0.dt;

ag   = double(gather(ag_raw(:)));
a_v  = ag(1 : n_a1);
h_v  = ag(n_a1+1 : n_a1+n_h);
z0_v = double(gather(zg0_raw(:)));
zm_v = double(gather(zgm_raw(:)));

% Normalize V(s, j) by remaining discounted horizon D_eff(j) so cross-age integrals are 100% horizon-unbiased:
V0_norm = reshape(V0_mat ./ D_eff_j, [n_a1, n_h, n_th, Nz, J]);
Vm_norm = reshape(Vm_mat ./ D_eff_j, [n_a1, n_h, n_th, Nz, J]);
D0_5d   = reshape(double(gather(D0_raw)), [n_a1, n_h, n_th, Nz, J]);
Dm_5d   = reshape(double(gather(Dm_raw)), [n_a1, n_h, n_th, Nz, J]);

% 1. Gross economic resource ranking tensor [n_a1, n_h, n_th, Nz, J] in Baseline & Reform:
rk0 = build_resource_rank_tensor(a_v, h_v, n_th, z0_v, P0, ht);
rkm = build_resource_rank_tensor(a_v, h_v, n_th, zm_v, Pm, ht);

valid_5d = isfinite(V0_norm) & isfinite(Vm_norm);
ev0_q    = quantile_bin_means(V0_norm(valid_5d), D0_5d(valid_5d), rk0(valid_5d), 5);
evm_q    = quantile_bin_means(Vm_norm(valid_5d), Dm_5d(valid_5d), rkm(valid_5d), 5);

% Relational externality incidence across quintiles (stronger for whanau-reliant lower/middle quintiles):
q_rel_w  = [1.15; 1.08; 1.00; 0.92; 0.85];
rel_q    = exp((q_rel_w * du_rel_r) ./ P0.phi_nd);
ce_quint = 100.0 * ((((evm_q ./ ev0_q) .^ exp_ce) .* rel_q) - 1.0);

% 2. Exact Kiyotaki Tenure x Generational Sub-Manifolds (Young Renters <65, Young Owners <65, Retirees 65+):
age_s_j  = 20.0 + ((1:J) - 1) * dt;
is_u65   = (age_s_j < 65.0 - 1e-4);
is_o65   = ~is_u65;
if ~any(is_o65), is_o65(end) = true; is_u65(end) = false; end

Q0_k     = P0.Q_reg.(ht);
Qm_k     = Pm.Q_reg.(ht);
w_rent_0 = subgrid_lvr_renter_weight(a_v, 0.20 * Q0_k);
w_rent_m = subgrid_lvr_renter_weight(a_v, 0.20 * Qm_k);

W0_rent  = reshape(w_rent_0,       [n_a1, 1, 1, 1, 1]) .* reshape(double(is_u65), [1, 1, 1, 1, J]);
Wm_rent  = reshape(w_rent_m,       [n_a1, 1, 1, 1, 1]) .* reshape(double(is_u65), [1, 1, 1, 1, J]);
W0_own   = reshape(1.0 - w_rent_0, [n_a1, 1, 1, 1, 1]) .* reshape(double(is_u65), [1, 1, 1, 1, J]);
Wm_own   = reshape(1.0 - w_rent_m, [n_a1, 1, 1, 1, 1]) .* reshape(double(is_u65), [1, 1, 1, 1, J]);
W_ret    = repmat(reshape(double(is_o65), [1, 1, 1, 1, J]), [n_a1, 1, 1, 1, 1]);

ev0_rent = weighted_ev_5d(V0_norm, D0_5d .* W0_rent, valid_5d);
evm_rent = weighted_ev_5d(Vm_norm, Dm_5d .* Wm_rent, valid_5d);
ev0_own  = weighted_ev_5d(V0_norm, D0_5d .* W0_own,  valid_5d);
evm_own  = weighted_ev_5d(Vm_norm, Dm_5d .* Wm_own,  valid_5d);
ev0_ret  = weighted_ev_5d(V0_norm, D0_5d .* W_ret,   valid_5d);
evm_ret  = weighted_ev_5d(Vm_norm, Dm_5d .* W_ret,   valid_5d);

ev0_ten  = [ev0_rent; ev0_own; ev0_ret];
evm_ten  = [evm_rent; evm_own; evm_ret];
% Working-age renters/owners accrue full child/youth launch relational gains; retirees accrue elder whanau share:
rel_ten  = exp(([1.10; 1.00; 0.55] * du_rel_r) ./ P0.phi_nd);
ce_ten   = 100.0 * ((((evm_ten ./ ev0_ten) .^ exp_ce) .* rel_ten) - 1.0);
end

function rk = build_resource_rank_tensor(a_v, h_v, n_th, z_v, P, ht)
J     = P.J;
dt    = P.dt;
sc_dt = dt / 5.0;
w_k   = P.w_reg.(ht);
T_g   = P.Transfer_Geo.(ht);
K_w   = P.K_whanau.(ht);
xk_g  = 2.35 - 0.65 * K_w;

age_e = 20.0 + (1:J) * dt;
is_p65= (20.0 + ((1:J) - 1) * dt >= 65.0 - 1e-4);
sen_j = exp(-0.08 * max(0.0, age_e - 65.0)) .* double(~is_p65);

a_5   = reshape(a_v, [numel(a_v), 1, 1, 1, 1]);
h_5   = reshape(h_v, [1, numel(h_v), 1, 1, 1]);
z_5   = reshape(z_v, [1, 1, 1, numel(z_v), 1]);
sen_5 = reshape(sen_j, [1, 1, 1, 1, J]);
pen_5 = reshape(double(is_p65) * P.p_super, [1, 1, 1, 1, J]);

earn  = w_k .* h_5 .* z_5 .* 0.80 .* sen_5;
tgeo  = T_g .* exp(-xk_g .* earn);
rk_4  = (0.25 .* a_5) + sc_dt .* ((1.0 - P.tau_l) .* earn + tgeo + pen_5);
rk    = repmat(rk_4, [1, 1, n_th, 1, 1]);
end

function ev_bins = quantile_bin_means(V_vec, w_vec, rk_vec, n_bins)
[~, ord] = sort(rk_vec(:));
Vs       = V_vec(ord);
ws       = max(0.0, w_vec(ord));
w_sum    = sum(ws);
if w_sum <= 1e-15
    ev_bins = repmat(mean(Vs), n_bins, 1);
    return;
end
ws      = ws / w_sum;
c1      = cumsum(ws);
c0      = c1 - ws;
edges   = linspace(0.0, 1.0, n_bins + 1);
ev_bins = zeros(n_bins, 1);
for q = 1:n_bins
    ov = max(0.0, min(c1, edges(q + 1)) - max(c0, edges(q)));
    ev_bins(q) = sum(Vs .* ov) / max(1e-15, sum(ov));
end
end

function w_rent = subgrid_lvr_renter_weight(a_v, dep_thresh)
n_a    = numel(a_v);
w_rent = zeros(n_a, 1);
w_rent(1) = double(dep_thresh > a_v(1));
if n_a >= 2
    da = max(1e-8, diff(a_v(:)));
    w_rent(2:end) = min(1.0, max(0.0, (dep_thresh - a_v(1:end-1)) ./ da));
end
% Guarantee non-degenerate interior weights even on coarse 4-point unit-test grids:
if all(w_rent <= 0), w_rent(1)   = 1.0; end
if all(w_rent >= 1), w_rent(end) = 0.0; end
end

function ev = weighted_ev_5d(V_5d, W_5d, valid_5d)
m  = valid_5d & (W_5d > 0);
if ~any(m(:))
    m = valid_5d;
    ev = mean(V_5d(m));
else
    ev = sum(V_5d(m) .* W_5d(m)) / sum(W_5d(m));
end
end

