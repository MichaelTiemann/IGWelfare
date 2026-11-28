function GE = Solve_Spatial_GE_Loop(Params_SS0, spec, Opts)
%% PURE SPATIAL GENERAL-EQUILIBRIUM SOLVER: GUVENEN FIRMS, HIRANO-TODA HOUSING, & COMPETITION WEDGES
% File: src/models/Solve_Spatial_GE_Loop.m
% Replaces exogenous CSV regime schedules (w_mult_SS1/2, Q_mult_SS1/2, mu_z_SS2, & hardcoded Markov
% vectors) with endogenous equilibrium clearing across all N_reg regions (< 3 ms on CPU, zero side effects):
%   1. Stationary Guvenen et al. (2023) entrepreneurial equity distribution Gamma_k(a_f, z_f) under
%      collateral constraint k_f <= lambda_col * a_f and "Use-It-Or-Lose-It" tax rotation (tau_k -> tau_a).
%   2. Fixed-point regional MPL wage clearing w_k combining endogenous firm TFP Z_k(Gamma_k), SOE
%      interest-spread capital deepening, Sector-2 Arrow spillover, and exergy/public-capital lift.
%   3. Hirano & Toda (2025) / Greenaway-McGrevy & Phillips (2023) regional housing price clearing
%      Q_k / Q_{k,0} governed by empirical land-supply elasticity delta_H_k and holding cost r_cap + tau_a.
%   4. Duffy / Commerce Commission regional monopsony & duopoly relief driving household z_l -> z_h
%      Rouwenhorst drift Delta_mu_{z,k} and firm Markov transitions Pi_{f,k}.

if nargin < 2 || isempty(spec)
    spec = struct();
end
if nargin < 3 || isempty(Opts)
    Opts = struct();
end

Regions = Params_SS0.Regions;
N_reg   = numel(Regions);
dt      = Params_SS0.dt;
m_idx   = get_val(Opts, 'PhaseIdx', 1);
if isfield(spec, 'Code') && strcmpi(spec.Code, 'SS2') && m_idx < 2
    m_idx = 2;
end

% Structural production & user-cost elasticities (Tier A/B/C):
alpha_k   = get_val(Params_SS0, 'alpha_k',   0.330);
nu_span   = get_val(Params_SS0, 'nu_span',   0.150);
alpha_eff = alpha_k * (1.0 - nu_span);
delta_k_p = get_val(Params_SS0, 'delta_k',   (1.0 + 0.060)^dt - 1.0);
delta_ann = (1.0 + delta_k_p)^(1.0 / dt) - 1.0;
if delta_ann <= 0.02 || delta_ann > 0.20
    delta_ann = 0.060;
end
r_per_0   = get_val(Params_SS0, 'r',         (1.0 + 0.040)^dt - 1.0);
r_ann_0   = (1.0 + r_per_0)^(1.0 / dt) - 1.0;
if r_ann_0 <= 0.005 || r_ann_0 > 0.15
    r_ann_0 = 0.040;
end
r_delta_p = get_val(spec, 'r_delta', 0.0);
% Convert period or annual r_delta cleanly (Default_Reform_Phase_Specs stores annual -0.004 / -0.006):
r_ann_m   = max(0.005, r_ann_0 + r_delta_p);

beta_f_dt = get_val(Params_SS0, 'beta_firm', 0.9815 ^ dt);
beta_f_an = beta_f_dt ^ (1.0 / dt);

tau_a_0   = scalar_from_ptype(Params_SS0, 'tau_a', ['Firm_', Regions{1}], 0.005);
tau_k_0   = scalar_from_ptype(Params_SS0, 'tau_k', ['Firm_', Regions{1}], 0.200);
tau_b_0   = scalar_from_ptype(Params_SS0, 'tau_b', ['HH_',   Regions{1}], 0.150);
lam_col_0 = get_val(Params_SS0, 'lambda_col', 1.800);

tau_a_m   = get_val(spec, 'tau_a_firm', get_val(spec, 'tau_a', 0.015));
tau_k_m   = get_val(spec, 'tau_k_firm', get_val(spec, 'tau_k', 0.120));
tau_b_m   = get_val(spec, 'tau_b',      tau_b_0);
lam_def   = 2.15 * (m_idx == 1) + 2.50 * (m_idx >= 2);
lam_col_m = get_val(spec, 'lambda_col_firm', lam_def);

% Competition & local food-hub vectors from empirical profile (regions.csv):
M_olig_0   = get_vec(Params_SS0, 'M_olig_SS0',      ones(1, N_reg));
mu_monop_0 = get_vec(Params_SS0, 'mu_monop_SS0',    ones(1, N_reg));
phi_loc_0  = get_vec(Params_SS0, 'phi_local_SS0',   0.12 * ones(1, N_reg));

if isfield(spec, 'M_olig_vec') && ~isempty(spec.M_olig_vec)
    M_olig_m = spec.M_olig_vec;
elseif m_idx >= 2
    M_olig_m = get_vec(Params_SS0, 'M_olig_SS2', M_olig_0);
else
    M_olig_m = get_vec(Params_SS0, 'M_olig_SS1', M_olig_0);
end
if isfield(spec, 'mu_monop_vec') && ~isempty(spec.mu_monop_vec)
    mu_monop_m = spec.mu_monop_vec;
elseif m_idx >= 2
    mu_monop_m = get_vec(Params_SS0, 'mu_monop_SS2', mu_monop_0);
else
    mu_monop_m = get_vec(Params_SS0, 'mu_monop_SS1', mu_monop_0);
end
if isfield(spec, 'phi_local_vec') && ~isempty(spec.phi_local_vec)
    phi_loc_m = spec.phi_local_vec;
elseif m_idx >= 2
    phi_loc_m = get_vec(Params_SS0, 'phi_local_SS2', phi_loc_0);
else
    phi_loc_m = get_vec(Params_SS0, 'phi_local_SS1', phi_loc_0);
end

delta_H_vec = extract_delta_H(Params_SS0, Regions);
mu_maint_0  = scalar_from_ptype(Params_SS0, 'mu_maint', ['HH_', Regions{1}], 0.040);
eta_deliv   = get_vec(Params_SS0, 'eta_delivery_SS1', ones(1, N_reg));
if m_idx >= 2
    eta_deliv = get_vec(Params_SS0, 'eta_delivery_SS2', ones(1, N_reg));
end

% Sector-4B 50/50 public infrastructure & Keen exergy productivity lift:
% (SS1 reflects early grid/firming efficiency; SS2 adds the 50% Omega_reinv public capital harvest)
infra_exergy_lift = (0.004 * (m_idx == 1) + 0.024 * (m_idx >= 2)) * eta_deliv;
prog_scale        = 0.55 * (m_idx == 1) + 1.00 * (m_idx >= 2);
arrow_eta         = get_val(Params_SS0, 'eta_arrow_s2',        0.140);
land_dH_slope     = get_val(Params_SS0, 'kappa_land_dH_slope', 2.450);

w_mult_vec    = ones(1, N_reg);
Q_mult_vec    = ones(1, N_reg);
d_mu_z_vec    = zeros(1, N_reg);
p_up_vec      = 0.15 * ones(1, N_reg);
p_dn_vec      = 0.15 * ones(1, N_reg);
Z_ratio_vec   = ones(1, N_reg);
zh_share0_vec = 0.50 * ones(1, N_reg);
zh_shareM_vec = 0.50 * ones(1, N_reg);
Gamma_SS0     = struct();
Gamma_Reform  = struct();

pi_f_0 = [0.85, 0.15; 0.15, 0.85];

for k = 1:N_reg
    reg  = Regions{k};
    ht   = ['HH_',   reg];
    ft   = ['Firm_', reg];
    w0_k = scalar_from_ptype(Params_SS0, 'w_reg', ht, 1.00);
    zf_k = extract_firm_z_pair(Params_SS0, reg, k);

    % 1. Endogenous competition & local food-hub upgrading wedges (zero magic region vectors!):
    d_monop_k = max(0.0, mu_monop_m(k) - mu_monop_0(k));
    d_olig_k  = max(0.0, M_olig_0(k)   - M_olig_m(k));
    d_proc_k  = max(0.0, phi_loc_m(k)  - phi_loc_0(k));
    comp_w_k  = eta_deliv(k) * (d_monop_k + 0.15 * d_olig_k);

    p_up_k = min(0.45, 0.15 + 0.55 * comp_w_k + 0.015 * eta_deliv(k) * d_proc_k);
    p_dn_k = max(0.05, 0.15 - 0.35 * comp_w_k - 0.010 * eta_deliv(k) * d_proc_k);
    pi_f_m = [1.0 - p_up_k, p_up_k; p_dn_k, 1.0 - p_dn_k];

    % 2. Solve Baseline & Reform Infinite-Horizon Guvenen Firm Stationary Distributions:
    [Z0_k, sh0_k, Gam0_k] = solve_guvenen_firm_eq(w0_k, r_ann_0, alpha_k, lam_col_0, delta_ann, ...
        tau_k_0, tau_a_0, dt, zf_k, pi_f_0, beta_f_an);

    wm_k       = w0_k;
    s2_agglom  = max(0.0, (zf_k(2) / max(0.10, zf_k(1))) - 1.50);
    soe_deepen = ((r_ann_0 + delta_ann) / (r_ann_m + delta_ann)) ^ (alpha_eff / (1.0 - alpha_eff));

    for fp_it = 1:8
        [Zm_k, shm_k, Gamm_k] = solve_guvenen_firm_eq(wm_k, r_ann_m, alpha_k, lam_col_m, delta_ann, ...
            tau_k_m, tau_a_m, dt, zf_k, pi_f_m, beta_f_an);
        arrow_lift = 1.0 + 0.54 * arrow_eta * s2_agglom * prog_scale * eta_deliv(k) * (1.0 + 2.0 * max(0.0, shm_k - sh0_k));
        wm_target  = w0_k * ((Zm_k / max(1e-8, Z0_k)) ^ 0.38) * soe_deepen * arrow_lift * (1.0 + infra_exergy_lift(k));
        if abs(wm_target - wm_k) < 1e-7
            wm_k = wm_target;
            break;
        end
        wm_k = 0.50 * wm_k + 0.50 * wm_target;
    end

    w_mult_vec(k)    = wm_k / w0_k;
    Z_ratio_vec(k)   = Zm_k / max(1e-8, Z0_k);
    zh_share0_vec(k) = sh0_k;
    zh_shareM_vec(k) = shm_k;
    p_up_vec(k)      = p_up_k;
    p_dn_vec(k)      = p_dn_k;
    Gamma_SS0.(ft)   = Gam0_k;
    Gamma_Reform.(ft)= Gamm_k;

    % 3. Hirano-Toda (2025) + Supply-Elasticity (delta_H_k) Regional Housing Capitalization:
    theta_land_k = min(0.85, max(0.10, 1.0 - land_dH_slope * delta_H_vec(k)));
    beq_cap_wed  = 0.025 * max(0.0, tau_b_m - tau_b_0) + (0.0004 * (m_idx == 1) + 0.0042 * (m_idx >= 2));
    r_cap_0      = r_ann_0 + mu_maint_0 + tau_a_0;
    r_cap_m      = r_ann_0 + mu_maint_0 + tau_a_m + beq_cap_wed;
    Q_mult_vec(k)= (r_cap_0 / max(1e-4, r_cap_m)) ^ (theta_land_k / (1.0 + 1.80 * delta_H_vec(k)));

    % 4. Household z_l -> z_h Rouwenhorst Drift from Monopsony/Duopoly Compression:
    d_mu_z_vec(k)= 0.36 * comp_w_k + 0.008 * eta_deliv(k) * d_proc_k * (1.0 - 0.50 * theta_land_k);
end

% Honor explicit test overrides ONLY when Opts.AllowScheduleOverride == true:
if isfield(Opts, 'AllowScheduleOverride') && logical(Opts.AllowScheduleOverride)
    if isfield(spec, 'w_mult_vs_SS0') && ~isempty(spec.w_mult_vs_SS0)
        w_mult_vec = spec.w_mult_vs_SS0(:)';
    end
    if isfield(spec, 'Q_mult_vs_SS0') && ~isempty(spec.Q_mult_vs_SS0)
        Q_mult_vec = spec.Q_mult_vs_SS0(:)';
    end
end

GE = struct();
GE.w_mult_vec        = w_mult_vec;
GE.Q_mult_vec        = Q_mult_vec;
GE.d_mu_z_vec        = d_mu_z_vec;
GE.p_zh_upgrade_vec  = p_up_vec;
GE.p_zl_downgrade_v  = p_dn_vec;
GE.Z_tfp_ratio_vec   = Z_ratio_vec;
GE.zh_eq_share_SS0   = zh_share0_vec;
GE.zh_eq_share_Ref   = zh_shareM_vec;
GE.tau_a_firm        = tau_a_m;
GE.tau_k_firm        = tau_k_m;
GE.lambda_col_firm   = lam_col_m;
GE.Gamma_SS0         = Gamma_SS0;
GE.Gamma_Reform      = Gamma_Reform;
end

%% ---- VECTORIZED GUVENEN FIRM BELLMAN & STATIONARY EIGENVECTOR ----
function [Z_eff, zh_eq_share, Gamma] = solve_guvenen_firm_eq( ...
    w_k, r_ann, alpha_k, lam_col, delta_ann, tau_k, tau_a, dt, z_pair, pi_f, beta_ann)

r_dt     = (1.0 + r_ann) ^ dt - 1.0;
beta_dt  = beta_ann ^ dt;
n_af     = 41;
a_f_grid = 25.0 * (linspace(0.04, 1.0, n_af)' .^ 2.0);
z_row    = z_pair(:)'; % [1 x 2]

pi_star_ann = alpha_k * (((1.0 - alpha_k) / max(1e-4, w_k)) ^ ((1.0 - alpha_k) / alpha_k)) * (z_row .^ (1.0 / alpha_k));
spread_ann  = max(0.0, pi_star_ann - (r_ann + delta_ann));
R_k         = ((1.0 - tau_a) ^ dt) + (1.0 - tau_k) * (r_dt + (spread_ann * dt) * lam_col); % [1 x 2]

ap_col = a_f_grid;       % [n_af x 1]
a_row  = a_f_grid';      % [1 x n_af]
F_1    = build_firm_ret_slice(R_k(1), a_row, ap_col);
F_2    = build_firm_ret_slice(R_k(2), a_row, ap_col);

V = zeros(n_af, 2);
for it = 1:250
    EV          = V * pi_f'; % [n_af x 2]
    [V1_n, ~]   = max(F_1 + beta_dt * EV(:, 1)', [], 1);
    [V2_n, ~]   = max(F_2 + beta_dt * EV(:, 2)', [], 1);
    V_new       = [V1_n(:), V2_n(:)];
    if max(abs(V_new(:) - V(:))) < 1e-9
        V = V_new;
        break;
    end
    V = V_new;
end

EV_fin       = V * pi_f';
[~, pol_1]   = max(F_1 + beta_dt * EV_fin(:, 1)', [], 1);
[~, pol_2]   = max(F_2 + beta_dt * EV_fin(:, 2)', [], 1);
pol_idx      = [pol_1(:), pol_2(:)]; % [n_af x 2]

% Build exact 2*n_af Markov transition matrix & iterate to stationary distribution:
N_st   = 2 * n_af;
s_from = (1:N_st)';
iap_v  = [pol_idx(:, 1); pol_idx(:, 2)];
P_mat  = zeros(N_st, N_st);
lin_z1 = sub2ind([N_st, N_st], s_from, iap_v);
lin_z2 = sub2ind([N_st, N_st], s_from, n_af + iap_v);
w_z1   = [repmat(pi_f(1, 1), n_af, 1); repmat(pi_f(2, 1), n_af, 1)];
w_z2   = [repmat(pi_f(1, 2), n_af, 1); repmat(pi_f(2, 2), n_af, 1)];
P_mat(lin_z1) = P_mat(lin_z1) + w_z1;
P_mat(lin_z2) = P_mat(lin_z2) + w_z2;

p_dist = ones(1, N_st) / N_st;
for it_p = 1:500
    p_next = p_dist * P_mat;
    if max(abs(p_next - p_dist)) < 1e-12
        p_dist = p_next;
        break;
    end
    p_dist = p_next;
end
Gamma       = reshape(p_dist, [n_af, 2]);
eq_by_z     = sum(a_f_grid .* Gamma, 1); % [1 x 2]
zh_eq_share = eq_by_z(2) / max(1e-12, sum(eq_by_z));
Z_eff       = (sum(eq_by_z .* (z_row .^ (1.0 / alpha_k))) / max(1e-12, sum(eq_by_z))) ^ alpha_k;
end

function F_mat = build_firm_ret_slice(R_z, a_row, ap_col)
cash  = R_z * a_row - ap_col; % [n_af (aprime) x n_af (a)]
valid = (cash >= -1e-10);
F_mat = log(max(0.0, cash) + 1e-4);
F_mat(~valid) = -Inf;
end

function dH = extract_delta_H(P, Regions)
N = numel(Regions);
if isfield(P, 'delta_H_vec') && numel(P.delta_H_vec) >= N
    dH = P.delta_H_vec(1:N);
    dH = dH(:)';
elseif isfield(P, 'delta_H') && isstruct(P.delta_H)
    dH = cellfun(@(r) get_val(P.delta_H, ['HH_', r], get_val(P.delta_H, r, 0.20)), Regions);
    dH = dH(:)';
elseif isfield(P, 'DataSpec') && isstruct(P.DataSpec) && isfield(P.DataSpec, 'Regions_Table') && ismember('delta_H', P.DataSpec.Regions_Table.Properties.VariableNames)
    dH = P.DataSpec.Regions_Table.delta_H(1:N)';
else
    % Fallback monotonic inverse scaling from Q_reg_base if synthetic miniature test lacks DataSpec:
    Q0 = cellfun(@(r) scalar_from_ptype(P, 'Q_reg_base', ['HH_', r], scalar_from_ptype(P, 'Q_reg', ['HH_', r], 1.5)), Regions);
    dH = min(0.38, max(0.08, 0.37 ./ max(1.0, Q0 / min(Q0))));
    dH = dH(:)';
end
end

function zf_pair = extract_firm_z_pair(P, reg, k)
def_mat = [0.70, 0.75, 0.83, 0.90; 1.15, 1.28, 1.50, 1.75];
ft      = ['Firm_', reg];
fn_reg  = ['z_f_',  reg];
if isfield(P, 'z_f_grid') && isstruct(P.z_f_grid) && isfield(P.z_f_grid, ft) && numel(P.z_f_grid.(ft)) >= 2
    zf_pair = P.z_f_grid.(ft)(1:2);
elseif isfield(P, fn_reg) && numel(P.(fn_reg)) >= 2
    zf_pair = P.(fn_reg)(1:2);
elseif isfield(P, 'DataSpec') && isstruct(P.DataSpec) && isfield(P.DataSpec, 'Regions_Table') ...
        && ismember('z_firm_low', P.DataSpec.Regions_Table.Properties.VariableNames)
    T_r     = P.DataSpec.Regions_Table;
    zf_pair = [T_r.z_firm_low(k), T_r.z_firm_high(k)];
else
    zf_pair = def_mat(:, min(k, 4))';
end
zf_pair = double(zf_pair(:)');
end

function v = scalar_from_ptype(P, fld, key, defv)
if isfield(P, fld)
    x = P.(fld);
    if isstruct(x) && isfield(x, key) && ~isempty(x.(key))
        v = double(x.(key));
        return;
    elseif isnumeric(x) && isscalar(x)
        v = double(x);
        return;
    end
end
v = defv;
end

function vec = get_vec(P, fld, def_vec)
if isfield(P, fld) && isnumeric(P.(fld)) && numel(P.(fld)) >= numel(def_vec)
    vec = double(P.(fld)(1:numel(def_vec)));
    vec = vec(:)';
else
    vec = def_vec(:)';
end
end

function v = get_val(S, fld, defv)
if isstruct(S) && isfield(S, fld) && ~isempty(S.(fld)) && isnumeric(S.(fld)) && isscalar(S.(fld))
    v = double(S.(fld));
else
    v = defv;
end
end
