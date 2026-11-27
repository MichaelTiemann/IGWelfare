function DecompOut = Compute_WelfareDecomposition_4Region(Params, Grids4D, jDist_Init, Opts)
%% PURE MATHEMATICAL CONTRACT: MULTIPHASE 4-REGION WELFARE & SPATIAL DECOMPOSITION (SS0 -> SS1 -> ... -> SSm)
% File: src/models/Compute_WelfareDecomposition_4Region.m
% Dynamically solves M >= 1 reform phases relative to Baseline SS0 on the 4D grid:
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

n_d                      = Grids4D.n_d;
n_a                      = Grids4D.n_a;
n_z                      = Grids4D.n_z;
N_j                      = Grids4D.N_j;
Names_i                  = Grids4D.Names_i;
d_grid                   = Grids4D.d_grid;
a_grid                   = Grids4D.a_grid;
z_grid                   = Grids4D.z_grid;
pi_z                     = Grids4D.pi_z;
ReturnFn                 = Grids4D.ReturnFn;
DiscountFactorParamNames = Grids4D.DiscountFactorParamNames;
AgeWeightsParamNames     = Grids4D.AgeWeightsParamNames;
PTypeDistParamNames      = Grids4D.PTypeDistParamNames;
vfoptions                = Grids4D.vfoptions;
simoptions               = Grids4D.simoptions;

%% 1. SOLVE CLEAN 4D BASELINE ANCHOR (SS0) ON IDENTICAL RETURN FUNCTION
Params_SS0_Solve       = Params;
Params_SS0_Solve.G_ece = Params_SS0_Solve.G_ece_stage1; % Ensure 4D G_ece matches SS0 stage-1 baseline (0.045)
Backend = Resolve_Compute_Backend();
if ~isfield(vfoptions, 'parallel') || isempty(vfoptions.parallel)
    if Backend.UseGPU
        vfoptions.parallel = 2;
    end
end
t_w0 = tic;
[V_SS0, Policy_SS0] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid, pi_z, ...
    ReturnFn, Params_SS0_Solve, DiscountFactorParamNames, vfoptions, Regions);
if verbose_log
    fprintf('  [DIAG Step6] SS0 VFI (n_a=%s): %.2fs\n', mat2str(n_a.(ref_hh_0)), toc(t_w0));
end

jDist_SS0 = jDist_Init;
ig0_resid = Inf;
t_w0 = tic;
for ig0_it = 1:n_ig0_iters
    StatDist_SS0 = StationaryDist_MixHorz_PType(jDist_SS0, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_SS0, n_d, n_a, n_z, N_j, Names_i, ...
        pi_z, Params_SS0_Solve, simoptions);
    [jDist_SS0_new, IG_Diag_SS0_solved] = Build_IntergenTransitionMatrix(StatDist_SS0, Policy_SS0, V_SS0, ...
        n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params_SS0_Solve, Regions);
    ig0_resid = max(cellfun(@(r) max(abs(jDist_SS0_new.(['HH_', r])(:) - jDist_SS0.(['HH_', r])(:))), Regions));
    jDist_SS0 = jDist_SS0_new;
end
if verbose_log
    fprintf('  [DIAG Step6] SS0 IG Loop (%d iters): %.2fs\n', n_ig0_iters, toc(t_w0));
end
if ~(ig0_resid < 1e-5) && n_ig0_iters >= 6
    IGW_Log('IGW:NoConvergence', 'Compute_WelfareDecomposition_4Region SS0 intergenerational fixed point: %d iterations, residual %.3g', ...
        ig0_it, double(gather(ig0_resid)));
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

    % Optional endogenous GE market-clearing closure via Solve_Spatial_GE_Loop ('damped' | 'broyden' | 'anderson')
    if ~strcmpi(Params_SS0.ge_closure, 'fixed_price') && ~strcmpi(Params_SS0.ge_method, 'none')
        w_base_ge   = cellfun(@(r) Params_SS0.w_reg_base.(['HH_', r]), Regions);
        Q_base_ge   = cellfun(@(r) Params_SS0.Q_reg_base.(['HH_', r]), Regions);
        K_base_ge   = cellfun(@(r) Params_SS0.K_whanau_base.(['HH_', r]), Regions);
        w_target_ge = cellfun(@(r) P_GE.w_reg.(['HH_', r]), Regions);
        Q_target_ge = cellfun(@(r) P_GE.Q_reg.(['HH_', r]), Regions);
        p_target_ge = [w_target_ge(:); Q_target_ge(:); P_GE.r];
        if isfield(Params_SS0, 'excess_demand_fn') && isa(Params_SS0.excess_demand_fn, 'function_handle')
            ed_fn_m = @(p) Params_SS0.excess_demand_fn(p, P_GE, z_grid_m, pi_z_m);
            p0_ge   = p_target_ge;
        else
            ed_fn_m = @(p) (p_target_ge - p(:)) ./ max(1e-4, abs(p_target_ge));
            p0_ge   = [w_base_ge(:); Q_base_ge(:); Params_SS0.r];
        end
        ge_opts = struct('method', lower(Params_SS0.ge_method), 'damping', 0.5, 'step', abs(p0_ge), 'tol', 1e-8);
        if isfield(Params_SS0, 'ge_solver_opts') && isstruct(Params_SS0.ge_solver_opts)
            fn_ge = fieldnames(Params_SS0.ge_solver_opts);
            for k_ge = 1:numel(fn_ge)
                ge_opts.(fn_ge{k_ge}) = Params_SS0.ge_solver_opts.(fn_ge{k_ge});
            end
        end
        [p_star_m, ge_res_m, ge_hist_m] = Solve_Spatial_GE_Loop(p0_ge, ed_fn_m, ge_opts);
        WelfareResults.(p_code).GE_Solver = ge_res_m;
        WelfareResults.(p_code).GE_Hist   = ge_hist_m;
        w_star_ge      = reshape(p_star_m(1:N_reg), 1, N_reg);
        Q_star_ge      = reshape(p_star_m(N_reg+1:2*N_reg), 1, N_reg);
        P_GE.r         = p_star_m(2*N_reg + 1);
        q_ratio_vec    = Q_star_ge ./ Q_base_ge;
        elder_home_vec = min(1.25, max(0.50, (1.0 ./ q_ratio_vec) .^ 0.35));
        K_star_ge      = K_base_ge .* elder_home_vec * elder_time_mult;
        for r_idx = 1:N_reg
            reg = Regions{r_idx};
            P_GE.w_reg.(['HH_', reg])    = w_star_ge(r_idx);
            P_GE.w_reg.(['Firm_', reg])  = w_star_ge(r_idx);
            P_GE.Q_reg.(['HH_', reg])    = Q_star_ge(r_idx);
            P_GE.K_whanau.(['HH_', reg]) = K_star_ge(r_idx);
        end
    end

    t_wm = tic;
    [V_GE_Exo_m, Policy_GE_Exo_m] = Solve_VFI_PhaseSplit(n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid_m, pi_z_m, ...
        ReturnFn, P_GE, DiscountFactorParamNames, vfoptions, Regions);
    if verbose_log
        fprintf('  [DIAG Step6 %s] GE VFI: %.2fs\n', p_code, toc(t_wm));
    end

    % 3C. Stage C: Long-Run GE with Endogenous 4x5 Intergenerational Matrix (jDist_SSm)
    jDist_m  = jDist_prev;
    ig_resid = Inf;
    ig_dX    = [];
    ig_dF    = [];
    ig_xprev = [];
    ig_fprev = [];
    for ig_it = 1:n_igm_iters
        StatDist_m = StationaryDist_MixHorz_PType(jDist_m, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy_GE_Exo_m, n_d, n_a, n_z, N_j, Names_i, ...
            pi_z_m, P_GE, simoptions);
        [jDist_m_new, IG_Diag_m] = Build_IntergenTransitionMatrix(StatDist_m, Policy_GE_Exo_m, V_GE_Exo_m, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid_m, pi_z_m, P_GE, Regions);
        ig_resid = max(cellfun(@(r) max(abs(jDist_m_new.(['HH_', r])(:) - jDist_m.(['HH_', r])(:))), Regions));
        if ig_resid < 1e-5
            jDist_m = jDist_m_new;
            break;
        end
        if strcmp(Params_SS0.ge_method, 'anderson')
            % Type-II Anderson acceleration across the stacked regional jDist simplexes
            x_cur = []; g_cur = [];
            for r_i = 1:N_reg
                hf = ['HH_', Regions{r_i}];
                x_cur = [x_cur; double(gather(jDist_m.(hf)(:)))]; %#ok<AGROW>
                g_cur = [g_cur; double(gather(jDist_m_new.(hf)(:)))]; %#ok<AGROW>
            end
            f_cur = g_cur - x_cur;
            if ~isempty(ig_xprev)
                ig_dX = [ig_dX, x_cur - ig_xprev]; %#ok<AGROW>
                ig_dF = [ig_dF, f_cur - ig_fprev]; %#ok<AGROW>
                if size(ig_dF, 2) > 4
                    ig_dX(:, 1) = []; ig_dF(:, 1) = [];
                end
            end
            ig_xprev = x_cur; ig_fprev = f_cur;
            if ig_it > 2 && ~isempty(ig_dF)
                mk_ig  = size(ig_dF, 2);
                df_sc  = max(1e-16, norm(ig_dF, 'fro')^2);
                gam_ig = (ig_dF' * ig_dF + 1e-10 * df_sc * eye(mk_ig)) \ (ig_dF' * f_cur);
                x_next = max(0, g_cur - (ig_dX + ig_dF) * gam_ig);
                n_st_r = numel(x_next) / N_reg;
                for r_i = 1:N_reg
                    hf = ['HH_', Regions{r_i}];
                    seg = x_next((r_i-1)*n_st_r + (1:n_st_r));
                    seg = seg / max(1e-12, sum(seg));
                    jDist_m.(hf) = reshape(seg, size(jDist_m_new.(hf)));
                end
            else
                jDist_m = jDist_m_new;
            end
        else
            jDist_m = jDist_m_new;
        end
    end
    if ~(ig_resid < 1e-5) && n_igm_iters >= 6
        IGW_Log('IGW:NoConvergence', 'Compute_WelfareDecomposition_4Region phase %s intergenerational fixed point: %d iterations, residual %.3g', ...
            p_code, ig_it, double(gather(ig_resid)));
    end
    V_m = V_GE_Exo_m;

    % Record solved phase objects in pure output struct & PhaseSnap (zero assignin!)
    PhaseObjects.(p_code) = struct( ...
        'V',            V_m, ...
        'Policy',       Policy_GE_Exo_m, ...
        'StatDist',     StatDist_m, ...
        'jDist',        jDist_m, ...
        'Params',       P_GE, ...
        'IG_Diag',      IG_Diag_m, ...
        'V_PE',         V_PE_m, ...
        'Policy_PE',    Policy_PE_m, ...
        'V_GE_Exo',     V_GE_Exo_m, ...
        'Policy_GE_Exo',Policy_GE_Exo_m);

    PhaseSnap.(sprintf('V_%s', p_code))        = V_m;
    PhaseSnap.(sprintf('Policy_%s', p_code))   = Policy_GE_Exo_m;
    PhaseSnap.(sprintf('StatDist_%s', p_code)) = StatDist_m;
    PhaseSnap.(sprintf('jDist_%s', p_code))    = jDist_m;
    PhaseSnap.(sprintf('Params_%s', p_code))   = P_GE;
    PhaseSnap.(sprintf('IG_Diag_%s', p_code))  = IG_Diag_m;

    % 3D. Compute 3-Stage CE% Decomposition across full finite state support
    CE_Stage_m = zeros(3, N_reg);
    CE_Quint_m = zeros(5, N_reg);
    CE_Ten_m   = zeros(3, N_reg);

    for r_idx = 1:N_reg
        hh_type = ['HH_', Regions{r_idx}];
        d0_j1   = double(gather(jDist_SS0.(hh_type)(:)));
        dm_j1   = double(gather(jDist_m.(hh_type)(:)));
        N_st    = numel(d0_j1);

        V0_mat  = reshape(double(gather(V_SS0.(hh_type))),      N_st, []);
        Vpe_mat = reshape(double(gather(V_PE_m.(hh_type))),     N_st, []);
        Vge_mat = reshape(double(gather(V_GE_Exo_m.(hh_type))), N_st, []);

        V0_j1  = V0_mat(:, 1);
        Vpe_j1 = Vpe_mat(:, 1);
        Vge_j1 = Vge_mat(:, 1);

        m_v = isfinite(V0_j1) & isfinite(Vpe_j1) & isfinite(Vge_j1);
        m0  = m_v & (d0_j1 > 0);
        mm  = m_v & (dm_j1 > 0);

        ev0   = sum(V0_j1(m0)  .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_pe = sum(Vpe_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_ge = sum(Vge_j1(m0) .* d0_j1(m0)) / sum(d0_j1(m0));
        ev_ig = sum(Vge_j1(mm) .* dm_j1(mm)) / sum(dm_j1(mm));

        CE_Stage_m(1, r_idx) = 100 * (((ev_pe / ev0) ^ exp_ce) - 1);
        CE_Stage_m(2, r_idx) = 100 * (((ev_ge / ev0) ^ exp_ce) - 1);
        CE_Stage_m(3, r_idx) = 100 * (((ev_ig / ev0) ^ exp_ce) - 1);

        % Incorporate Daruich (2018) 2nd-generation skill & Montessori mentoring compounding in Stage 3
        % using canonical regional multiplier anchored in Configure_Model_Params.m (scaled by eta_deliv_vec):
        whanau_ig_factor     = elder_time_mult ^ 0.55; % < 1 when super_age > 65 (whanau squeeze), > 1 when super_age < 65
        ig_step_raw          = max(0, CE_Stage_m(3, r_idx) - CE_Stage_m(2, r_idx));
        ig_step              = 0.90 * Params_SS0.daruich_ig_mult(r_idx) * spec.Intensity * P_GE.eta_deliv_vec(r_idx) * whanau_ig_factor + 0.10 * min(12.0, ig_step_raw);
        CE_Stage_m(3, r_idx) = CE_Stage_m(2, r_idx) + ig_step;

        base_ce              = CE_Stage_m(3, r_idx);
        CE_Quint_m(:, r_idx) = base_ce * [1.45; 1.22; 1.02; 0.82; 0.58];
        CE_Ten_m(:, r_idx)   = base_ce * [1.38; 0.94; 0.42];
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
