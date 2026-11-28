function test_solve_vfi_phasesplit()
%TEST_SOLVE_VFI_PHASESPLIT Timed Bellman VFI sanity check across GPU, MATLAB No-GPU, and Octave.
%   Times raw MATLAB No-GPU on a miniature 2-region 4-phase problem and tests automatic
%   bailout to VFIToolkit-octave CPU-vectorized solvers when raw CPU is slow or unsupported.

if exist('ValueFnIter_MixHorz_PType', 'file') == 0
    mode = strtrim(getenv('IGWELFARE_TEST_MODE'));
    if isempty(mode)
        error('tests:skip', 'ValueFnIter_MixHorz_PType not on path (interactive run)');
    else
        error('tests:fail', 'ValueFnIter_MixHorz_PType required in CI mode %s', mode);
    end
end

Backend  = Resolve_Compute_Backend();
isOctave = Backend.IsOctave;
hasGpu   = Backend.UseGPU;

Regions = {'Rural', 'Auckland'};
J  = 6;
dt = 15.0; % Crosses age 65 cleanly at j = 4 on miniature 6-period grid

d_l  = [0.0; 0.75];
d_Ih = [0.0; 0.05];
d_ic = [0.0; 0.0203; 0.08];
n_d_hh    = [numel(d_l), numel(d_Ih), numel(d_ic)];  % [2, 2, 3]
d_grid_hh = [d_l; d_Ih; d_ic];

a_vec     = [0.00; 0.80; 2.20; 5.00];                % n_a1 = 4 (includes a=0 borrowing bound)
h_vec     = [0.65; 1.00; 1.45];                      % n_h  = 3
th_vec    = [0.75; 1.25];                            % n_th = 2
n_a_5d    = [numel(a_vec), numel(h_vec), numel(th_vec)]; % [4, 3, 2]
a_grid_5d = [a_vec; h_vec; th_vec];

z_vec    = [0.85; 1.18];
pi_z_mat = [0.85, 0.15; 0.20, 0.80];

Params = struct();
Params.J              = J;
Params.dt             = dt;
Params.Jr             = 1 + (65.0 - 20.0) / dt;      % Jr = 4
Params.j_s1_start     = 2;
Params.j_s1_end       = 2;
Params.j_s2_start     = 3;
Params.j_s2_end       = 3;
Params.n_stage1_steps = 1;
Params.n_stage2_steps = 1;
Params.agej           = 1:J;
Params.beta_hh        = 0.980 ^ 5;
Params.beta_firm      = 0.9815 ^ 5;
Params.sj             = 0.98 * ones(1, J);

Params.r            = 0.04;  Params.alpha_k     = 0.33; Params.lambda_col = 1.50;
Params.delta_k      = 0.06;  Params.phi_nd      = 0.45; Params.mu_maint   = 0.02;
Params.upsilon_h    = 0.12;  Params.chi_bar     = 0.80; Params.ebar_energy = 0.03;
Params.Transfer_Geo = 0.01;  Params.p_super     = 0.22; Params.c_floor    = 0.05;
Params.gbar_ece     = 0.04;  Params.s_sub       = 0.15; Params.omega_ic   = 0.35;
Params.gamma1_self  = 0.45;  Params.gamma1_inv  = 0.35; Params.gamma1_par = 0.20; Params.phi1_ces = 0.35;
Params.gamma2_self  = 0.55;  Params.gamma2_inv  = 0.28; Params.gamma2_par = 0.17; Params.phi2_ces = -0.95;
Params.h_par_mean   = 1.00;
Params.delta_hc     = 0.05;  Params.alpha_I     = 0.50; Params.alpha_H    = 0.35;
Params.b1_beq       = 1.50;  Params.b2_beq      = 2.00; Params.YouthGrant = 0.0;
Params.tau_l        = 0.22;  Params.tau_c       = 0.15; Params.tau_k      = 0.28;
Params.tau_a        = 0.0;   Params.tau_b       = 0.0;

Params.w_reg        = struct('Firm_Rural', 1.00, 'Firm_Auckland', 1.18, 'HH_Rural', 1.00, 'HH_Auckland', 1.18);
Params.Q_reg        = struct('HH_Rural', 1.05, 'HH_Auckland', 1.65);
Params.Q_reg_base   = struct('HH_Rural', 1.05, 'HH_Auckland', 1.65);
Params.G_reg        = struct('HH_Rural', 0.07, 'HH_Auckland', 0.08);
Params.G_ece_stage1 = struct('HH_Rural', 0.05, 'HH_Auckland', 0.06);
Params.G_ece_stage2 = struct('HH_Rural', 0.05, 'HH_Auckland', 0.06);
Params.K_whanau     = struct('HH_Rural', 0.14, 'HH_Auckland', 0.09);

n_d = struct(); n_a = struct(); n_z = struct(); N_j = struct();
d_grid = struct(); a_grid = struct(); z_grid = struct(); pi_z = struct();
ReturnFn = struct(); DiscountFactorParamNames = struct();

firmFn = @(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt) ...
    ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt);

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

vfoptions = struct('verbose', 0, 'tolerance', 1e-7, 'maxiter', 250);

for r_idx = 1:numel(Regions)
    ft = ['Firm_', Regions{r_idx}];
    ht = ['HH_', Regions{r_idx}];

    a_vec_firm = [0.10; 0.80; 2.20; 5.00];
    n_d.(ft) = 0;               n_a.(ft) = numel(a_vec_firm);
    n_z.(ft) = numel(z_vec);    N_j.(ft) = Inf;
    d_grid.(ft) = [];           a_grid.(ft) = a_vec_firm;
    z_grid.(ft) = z_vec;        pi_z.(ft)   = pi_z_mat;
    ReturnFn.(ft) = firmFn;     DiscountFactorParamNames.(ft) = {'beta_firm'};
    vfoptions.experienceasset.(ft) = 0;

    n_d.(ht) = n_d_hh;          n_a.(ht) = n_a_5d;
    n_z.(ht) = numel(z_vec);    N_j.(ht) = J;
    d_grid.(ht) = d_grid_hh;    a_grid.(ht) = a_grid_5d;
    z_grid.(ht) = z_vec;        pi_z.(ht)   = pi_z_mat;
    ReturnFn.(ht) = hh5dFn;     DiscountFactorParamNames.(ht) = {'beta_hh', 'sj'};
    vfoptions.experienceasset.(ht) = 1;
    vfoptions.aprimeFn.(ht)        = apFn;
end

% 1. Timed Primary Solve
t0 = tic();
raw_failed = false;
V_raw = struct();
try
    [V, Policy] = Solve_VFI_PhaseSplit( ...
        n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions, Regions);
    dt_primary = toc(t0);
    V_raw = V;
    fprintf('  [VFI Timer] Primary solve (%s): %.3fs\n', which('ValueFnIter_MixHorz_PType'), dt_primary);
catch err
    dt_primary = toc(t0);
    raw_failed = true;
    fprintf('  [VFI Watchdog] Raw solver failed after %.3fs (%s)\n', dt_primary, err.message);
end

% 2. Watchdog Bailout for MATLAB No-GPU:
%    If raw MATLAB CPU failed OR exceeded 1.0s on a tiny 24-state problem (which projects
%    to hours on full 61x7x9 grids), bail out to VFIToolkit-octave vectorized CPU layer!
bail_threshold_s = 1.0;
if ~isOctave && ~hasGpu && (raw_failed || dt_primary > bail_threshold_s || exist('enable_vfi_cpu_accel', 'file') ~= 0)
    origPath = path();
    cleanupPath = onCleanup(@() path(origPath));
    if exist('enable_vfi_cpu_accel', 'file') ~= 0 && enable_vfi_cpu_accel()
        t1 = tic();
        [V, Policy] = Solve_VFI_PhaseSplit( ...
            n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions, Regions);
        dt_accel = toc(t1);
        fprintf('  [VFI Timer] Accelerated MATLAB No-GPU solve (%s): %.3fs (%.2fx vs raw)\n', ...
            which('ValueFnIter_MixHorz_PType'), dt_accel, dt_primary / max(dt_accel, 1e-4));

        if ~raw_failed
            for r_idx = 1:numel(Regions)
                ht = ['HH_', Regions{r_idx}];
                max_v_diff = max(abs(double(gather(V.(ht)(:))) - double(gather(V_raw.(ht)(:)))));
                check(max_v_diff < 1e-10, ...
                    sprintf('Raw vs Accelerated MATLAB CPU V mismatch on %s: %.3e', ht, max_v_diff));
            end
        end
    elseif raw_failed
        rethrow(err);
    end
elseif raw_failed
    rethrow(err);
end

% 3. Validate Economic & Bellman Axioms
for r_idx = 1:numel(Regions)
    ft = ['Firm_', Regions{r_idx}];
    ht = ['HH_', Regions{r_idx}];

    Vf = double(gather(V.(ft)));
    Vh = double(gather(V.(ht)));
    Ph = double(gather(Policy.(ht)));

    check(all(isfinite(Vf(:))), sprintf('%s value function has non-finite entries', ft));
    check(isequal(size(Vh), [n_a_5d(1), n_a_5d(2), n_a_5d(3), numel(z_vec), J]), ...
        sprintf('%s value function shape mismatch', ht));
    check(all(isfinite(Vh(:))), sprintf('%s value function has non-finite entries', ht));

    dV_da = diff(Vh, 1, 1);
    check(all(dV_da(:) >= -1e-10), sprintf('%s V is decreasing in assets a', ht));
    check(isequal(size(Ph), [5, n_a_5d(1), n_a_5d(2), n_a_5d(3), numel(z_vec), J]), ...
        sprintf('%s Policy shape mismatch', ht));
end
end

function check(cond, msg)
if ~cond
    error('tests:fail', '%s', msg);
end


end
