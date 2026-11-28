function test_wave3_model_boundaries()
%% TEST_WAVE3_MODEL_BOUNDARIES
% Verifies Wave 3 Script-vs-Function architectural contracts:
%   1. Static purity audit: zero evalin / assignin / figure / exportgraphics / writetable inside src/models/ and src/solvers/.
%   2. Ensure_Workbench_Initialized idempotency and region/share resolution.
%   3. Build_Phase_Registry explicit WorkspaceSnap mode (zero base-workspace dependence).
%   4. Compute_FiscalSolvency_And_Fertility purity + O(1) Step 6 T1 re-anchoring + Default_Reform_Phase_Specs sync.
%   5. Compute_TransitionPath_4Region pure multiphase transition & MIT credibility wedge.
%   6. Compute_WelfareDecomposition_4Region pure 3-stage solver on a miniature 5D grid (zero base-workspace pollution).

repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);
setup_igw_paths(true);

%% 1. STATIC PURITY AUDIT OF src/models/*.m AND src/solvers/*.m
pure_dirs = {fullfile(repo_root, 'src', 'models'), fullfile(repo_root, 'src', 'solvers')};
forbidden = {'evalin(', 'assignin(', 'exportgraphics(', 'writetable(', 'figure('};
for d_i = 1:numel(pure_dirs)
    mfiles = dir(fullfile(pure_dirs{d_i}, '*.m'));
    for f_i = 1:numel(mfiles)
        fpath = fullfile(pure_dirs{d_i}, mfiles(f_i).name);
        lines = strsplit(fileread(fpath), char(10));
        for ln_i = 1:numel(lines)
            s = strtrim(lines{ln_i});
            if isempty(s) || s(1) == '%', continue; end
            pct = strfind(s, '%');
            if ~isempty(pct), s = s(1:pct(1)-1); end
            for tok_i = 1:numel(forbidden)
                check(isempty(strfind(s, forbidden{tok_i})), ...
                    sprintf('%s:%d contains forbidden side-effect token %s', mfiles(f_i).name, ln_i, forbidden{tok_i}));
            end
        end
    end
end

%% 2. ENSURE_WORKBENCH_INITIALIZED CONTRACT
[P0, Regs, Shares] = Ensure_Workbench_Initialized(struct('dt', 5, 'n_z_pts', 3));
check(P0.dt == 5 && P0.n_z_pts == 3 && numel(Regs) == 4 && abs(sum(Shares) - 1.0) < 1e-12, ...
    'Ensure_Workbench_Initialized failed basic initialization');
[P0_idem, ~, ~] = Ensure_Workbench_Initialized(P0);
check(strcmp(P0.DataSpec_Digest, P0_idem.DataSpec_Digest), 'Ensure_Workbench_Initialized broke DataSpec_Digest idempotency');

%% 3. BUILD_PHASE_REGISTRY EXPLICIT SNAPSHOT CONTRACT (ZERO BASE WORKSPACE MUTATION)
base_before = evalin('base', 'who');
Snap = struct('StatDist_SS0', 'd0', 'Params_SS0', P0, 'StatDist_SS1', 'd1', 'Params_SS1', P0, 'StatDist_SS2', 'd2', 'Params_SS2', P0);
Ph = Build_Phase_Registry({'SS0', 'SS1', 'SS2'}, Snap);
base_after = evalin('base', 'who');
check(isequal(base_before, base_after), 'Build_Phase_Registry mutated base workspace in explicit Snap mode');
check(numel(Ph) == 3 && strcmp(Ph(1).Code, 'SS0') && strcmp(Ph(3).Code, 'SS2') && strcmp(Ph(3).Dist, 'd2'), ...
    'Build_Phase_Registry explicit Snap returned unexpected Phases struct');

%% 4. COMPUTE_FISCALSOLVENCY_AND_FERTILITY + T1 RE-ANCHOR + REFORM SPEC SYNC
P_before_fields = fieldnames(P0);
for r = 1:P0.N_reg
    ht = ['HH_', Regs{r}];
    n_a_5D.(ht)    = [4, 7, 3];
    n_z.(ht)       = 3;
    a_grid_5D.(ht) = [linspace(0, 10, 4)'; [0.45; 0.65; 0.85; 1.00; 1.20; 1.45; 1.80]; linspace(0.5, 1.5, 3)'];
    D5             = ones(4, 7, 3, 3, P0.J);
    StatDist_5D.(ht) = D5 / sum(D5(:));
end
Fert0 = Compute_FiscalSolvency_And_Fertility(P0, StatDist_5D, n_a_5D, n_z, a_grid_5D);
check(isequal(fieldnames(P0), P_before_fields), 'Compute_FiscalSolvency_And_Fertility mutated input Params');
check(strcmp(Fert0.ce_anchor_source, 'typed_default') && isfinite(Fert0.tau_l_delta_SS2), ...
    'Fert0 missing expected default anchor metadata or tau_l_delta_SS2');

% Verify Default_Reform_Phase_Specs picks up Params.tau_l_delta_SS2 when synchronized
P_synced = P0;
P_synced.tau_l_delta_SS2 = Fert0.tau_l_delta_SS2;
Specs_synced = Default_Reform_Phase_Specs(P_synced, true);
check(abs(Specs_synced(2).tau_l_delta - Fert0.tau_l_delta_SS2) < 1e-15, ...
    'Default_Reform_Phase_Specs failed to synchronize with Params.tau_l_delta_SS2');

% Verify O(1) Step 6 T1 re-anchoring
T1_mock = array2table([2 2.1 2.4 3.1; 6.2 6.3 6.7 7.6; 11.9 13.7 14.8 17.5; 5.6 5.8 6.2 6.9; 12.7 12.9 13.6 14.6; 21.0 23.0 25.0 29.0], ...
    'VariableNames', {'Rural_CE_Pct', 'Small_CE_Pct', 'Large_CE_Pct', 'Auckland_CE_Pct'});
expected_anchor = sum([21.0, 23.0, 25.0, 29.0] .* Shares(:)');
Fert1 = Compute_FiscalSolvency_And_Fertility(P0, [], [], [], [], struct('ReanchorFrom', Fert0, 'T1', T1_mock));
idx64 = find(Fert1.SuperAge_Grid == 64, 1);
check(strcmp(Fert1.ce_anchor_source, 'T1') && abs(Fert1.CE_UCurve_SS2(idx64) - expected_anchor) < 1e-12, ...
    'O(1) T1 re-anchoring failed to match weighted National SS2 CE%');

%% 5. COMPUTE_TRANSITIONPATH_4REGION PURE CONTRACT
TransOut = Compute_TransitionPath_4Region(P0, struct(), T1_mock, struct('Phases', Ph));
check(TransOut.has_SS2 && istable(TransOut.T_CohortWelfare) && istable(TransOut.T_PopShares), ...
    'Compute_TransitionPath_4Region failed table contract');
check(all( abs(sum(TransOut.s_HH_path, 2) - 1.0) < 1e-12 ), ...
    'Dynamic regional household population shares s_HH_path failed to sum to 1');

%% 6. MINIATURE 5D COMPUTE_WELFAREDECOMPOSITION_4REGION PURITY CHECK
if exist('ValueFnIter_MixHorz_PType', 'file') ~= 0
    P_mini = Configure_Model_Params(struct('dt', 15, 'n_z_pts', 2));
    Regs_m = P_mini.Regions;
    N_rm   = numel(Regs_m);
    Names_i = [cellfun(@(r) ['HH_', r], Regs_m, 'UniformOutput', false), ...
               cellfun(@(r) ['Firm_', r], Regs_m, 'UniformOutput', false)];
    P_mini.PTypeWeights = [0.90 * P_mini.Pop_Weights_4(:); 0.10 * P_mini.Firm_Weights_4(:)];
    P_mini.mewj         = ones(1, P_mini.J) / P_mini.J;
    P_mini.G_ece        = P_mini.G_ece_stage1;
    P_mini.h_par_mean   = 1.00;

    hh5dFn = @(l, Ih, ic, aprime, hprime, a, h, theta_c, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg_base, K_whanau) ...
        ReturnFn_SpatialHH(l, Ih, ic, aprime, hprime, a, h, theta_c, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg_base, K_whanau);

    apFn = @(i_c, thetac, agej, phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
        phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, gbar_ece, h_par_mean, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg, Q_reg_base, K_whanau, Jr, dt) ...
        HumanCapital_Lifecycle_aprimeFn(i_c, thetac, agej, phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
        phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, gbar_ece, h_par_mean, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg, Q_reg_base, K_whanau, Jr, dt);

    for r = 1:N_rm
        ht = ['HH_', Regs_m{r}];
        ft = ['Firm_', Regs_m{r}];
        N_j.(ht) = P_mini.J;
        N_j.(ft) = Inf;
        n_d.(ht) = [2, 2, 2];
        d_grid.(ht) = [0; 1.0; 0; 0.2; 0; 0.3];
        n_a.(ht) = [4, 3, 2];
        a_grid.(ht) = [linspace(0, 8, 4)'; [0.6; 1.0; 1.5]; [0.75; 1.25]];
        n_z.(ht) = 2;
        z_grid.(ht) = [0.85; 1.15];
        pi_z.(ht) = [0.8, 0.2; 0.2, 0.8];

        n_d.(ft) = 0; d_grid.(ft) = [];
        n_a.(ft) = 5; a_grid.(ft) = linspace(0.5, 10, 5)';
        n_z.(ft) = 2; z_grid.(ft) = [0.8; 1.3];
        pi_z.(ft) = [0.85, 0.15; 0.15, 0.85];

        DiscountFactorParamNames.(ht) = {'beta_hh', 'sj'};
        DiscountFactorParamNames.(ft) = {'beta_firm'};
        vfoptions.experienceasset.(ht)  = 1;
        vfoptions.aprimeFn.(ht)         = apFn;
        vfoptions.experienceasset.(ft)  = 0;
        simoptions.experienceasset.(ht) = 1;
        simoptions.aprimeFn.(ht)        = apFn;
        simoptions.experienceasset.(ft) = 0;

        ReturnFn.(ht) = hh5dFn;
        ReturnFn.(ft) = @(aprime,a,z,w_reg,r,alpha_k,lambda_col,delta_k,tau_k,tau_a,dt) ReturnFn_Firm(aprime,a,z,w_reg,r,alpha_k,lambda_col,delta_k,tau_k,tau_a,dt);

        jDist_init.(ht) = ones([n_a.(ht), n_z.(ht)]) / prod([n_a.(ht), n_z.(ht)]);
    end
    vfoptions.verbose = 0; vfoptions.vectorized = 1;
    simoptions.verbose = 0; simoptions.d_grid = d_grid; simoptions.a_grid = a_grid;

    Grids5D = struct('n_d', n_d, 'n_a', n_a, 'n_z', n_z, 'N_j', N_j, 'Names_i', {Names_i}, ...
        'd_grid', d_grid, 'a_grid', a_grid, 'z_grid', z_grid, 'pi_z', pi_z, 'ReturnFn', ReturnFn, ...
        'DiscountFactorParamNames', {DiscountFactorParamNames}, 'AgeWeightsParamNames', {{'mewj'}}, ...
        'PTypeDistParamNames', {{'PTypeWeights'}}, 'vfoptions', vfoptions, 'simoptions', simoptions);

    base_vars_pre = evalin('base', 'who');
    Decomp = Compute_WelfareDecomposition_4Region(P_mini, Grids5D, jDist_init, ...
        struct('Enable_SS2_Phase', false, 'Verbose', false, 'MaxIGIter_SS0', 2, 'MaxIGIter_SSm', 2));
    base_vars_post = evalin('base', 'who');

    check(isequal(base_vars_pre, base_vars_post), 'Compute_WelfareDecomposition_4Region leaked variables into base workspace');
    check(istable(Decomp.T1) && height(Decomp.T1) == 3 && numel(Decomp.Phases) == 2, ...
        'Compute_WelfareDecomposition_4Region returned unexpected T1 or Phases dimensions');
end

end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_wave3_model_boundaries: %s', msg);
end
end
