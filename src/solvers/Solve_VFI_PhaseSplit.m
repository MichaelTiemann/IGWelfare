function [V, Policy] = Solve_VFI_PhaseSplit( ...
    n_d, n_a, n_z, N_j, d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions, Regions)
%% PHASE-SPLIT EXACT MULTI-REGION VFI FOR 5D EXPERIENCE-ASSET LIFECYCLE HOUSEHOLDS + INFHORZ FIRMS
% Zero VFI Toolkit modifications required. Exploits exact lifecycle sub-manifolds AND fuses all N_reg
% regions x N_z shocks into a single batch per phase (saturating all CPU workers & using compiled .oct/.ptx kernels):
%   - Phase 4 (Jr : J)              : Retirees      -> 4D Case1, n_d = [1,1,1]     (756x smaller, compiled ReturnFn_SpatialHH)
%   - Phase 3 (j_s2_end+1 : Jr-1)   : Post-Parent   -> 4D Case1, n_d = [4,3,1]     ( 63x smaller, compiled ReturnFn_SpatialHH)
%   - Phase 2 (j_s1_start : j_s2_end): Parenting     -> 5D ExpAsset, full grids     (  1x exact)
%   - Phase 1 (1 : j_s1_start-1)    : Pre-Parenting -> 5D ExpAsset, n_d = [4,3,1]   (  7x smaller)

N_reg  = length(Regions);
V      = struct();
Policy = struct();

%% 1. SOLVE 4 INFINITE-HORIZON FIRMS VIA EXISTING TOOLKIT DISPATCH
Names_Firm = cell(1, N_reg);
for r_idx = 1:N_reg
    Names_Firm{r_idx} = ['Firm_', Regions{r_idx}];
end
[V_firm, Pol_firm] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_Firm, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions);
for r_idx = 1:N_reg
    ft = Names_Firm{r_idx};
    V.(ft)      = V_firm.(ft);
    Policy.(ft) = Pol_firm.(ft);
end

Names_HH = cell(1, N_reg);
for r_idx = 1:N_reg
    Names_HH{r_idx} = ['HH_', Regions{r_idx}];
end

Backend = Resolve_Compute_Backend();

assert(numel(n_a.(Names_HH{1})) == 3, ...
    'IGWelfare:Require5DGrid', 'Solve_VFI_PhaseSplit requires canonical 5D household grids [n_a1, n_h, n_thetac].');

%% 2. LIFECYCLE WINDOW BOUNDARIES (HANDLES ANY CONTINUOUS Jr / super_age)
J             = Params.J;
dt            = Params.dt;
super_age_yrs = 20 + (Params.Jr - 1) * dt;
% Exact first bracket where is_full_ret == true in ReturnFn_SpatialHH (l=0, Ih=0, ic=0):
Jr_int = J + 1;
for jj = (Params.j_s2_end + 1) : J
    age_s = 20 + (jj - 1) * dt;
    age_e = age_s + dt;
    if (age_s >= 65.0 - 1e-4) && ((age_e - super_age_yrs) / dt >= 0.999)
        Jr_int = jj;
        break;
    end
end
j_p4 = Jr_int : J;                           % Phase 4: Full Retirement (l=0, Ih=0, ic=0, singleton theta_c=1)
j_p3 = (Params.j_s2_end + 1) : (Jr_int - 1); % Phase 3: Post-Parenting & Partial Super (ic=0, singleton theta_c=1)
j_p2 = Params.j_s1_start : Params.j_s2_end;  % Phase 2: Active Stages 1 & 2 Parenting (full 5D ExpAsset)
j_p1 = 1 : (Params.j_s1_start - 1);          % Phase 1: Pre-Parenting Youth (ic=0, carries theta_c)

%% 3. BUILD PER-PHASE MULTI-REGION INPUT STRUCTS (ALL REGIONS FUSED PER PHASE)
nd_p4 = struct(); nd_p3 = struct(); nd_p1 = struct();
na_2d = struct();
dg_p4 = struct(); dg_p3 = struct(); dg_p1 = struct();
ag_2d = struct();
nj_p4 = struct(); nj_p3 = struct(); nj_p2 = struct(); nj_p1 = struct();
ReturnFn_2d = struct();

for r_idx = 1:N_reg
    hh_type  = Names_HH{r_idx};
    n_d_full = n_d.(hh_type);     % [4, 3, 7]
    n_a_full = n_a.(hh_type);     % [61, 7, 9]
    n_z_reg  = n_z.(hh_type);     % [7]
    N_z      = prod(n_z_reg);
    n_a1     = n_a_full(1);       % 61
    n_h      = n_a_full(2);       % 7
    n_th     = n_a_full(3);       % 9

    d_all  = d_grid.(hh_type);
    d_l_Ih = d_all(1 : sum(n_d_full(1:2)));                % [4 + 3 = 7 x 1]
    d_pre  = [d_l_Ih; d_all(sum(n_d_full(1:2)) + 1)];      % [l; Ih; ic=0] -> [8 x 1]

    a_all  = a_grid.(hh_type);
    % Phase 3 & 4 (experienceasset=0) have 2 endogenous states [a, h] (8 Case-1 grid args);
    % bind unused theta_c = 1.0 in slot 8 so all 37 Params align 1-to-1 with ReturnFn_SpatialHH!
    a_2d_reg = a_all(1 : (n_a1 + n_h));

    nd_p4.(hh_type) = [1, 1, 1];
    nd_p3.(hh_type) = [n_d_full(1:2), 1];
    nd_p1.(hh_type) = [n_d_full(1:2), 1];
    na_2d.(hh_type) = [n_a1, n_h];

    dg_p4.(hh_type) = [0; 0; 0];
    dg_p3.(hh_type) = d_pre;
    dg_p1.(hh_type) = d_pre;
    ag_2d.(hh_type) = a_2d_reg;

    ReturnFn_2d.(hh_type) = @(l, Ih, ic, aprime, hprime, a, h, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg_base, K_whanau) ...
        ReturnFn_SpatialHH(l, Ih, ic, aprime, hprime, a, h, 1.0, z, ...
        w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
        Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
        omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
        gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
        delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
        tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
        j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
        Q_reg_base, K_whanau);

    nj_p4.(hh_type) = length(j_p4);
    nj_p3.(hh_type) = length(j_p3);
    nj_p2.(hh_type) = length(j_p2);
    nj_p1.(hh_type) = length(j_p1);

    V.(hh_type)      = Backend.Zeros(n_a1, n_h, n_th, N_z, J);
    Policy.(hh_type) = Backend.Ones(5, n_a1, n_h, n_th, N_z, J);
end

%% 4. BACKWARD PHASE HANDOFF ACROSS ALL 4 REGIONS CONCURRENTLY
V_next_4d = struct();
% ---- PHASE 4: RETIREMENT (Jr_int : J) — 2-State [a, h] Case1, n_d = [1,1,1] ----
if ~isempty(j_p4)
    vfo_4 = struct('verbose', 0, 'experienceasset', 0, 'vectorized', 1);
    P_p4  = slice_age_params_ptype(Params, Names_HH, j_p4, J);
    [V_p4, Pol_p4] = ValueFnIter_MixHorz_PType(nd_p4, na_2d, n_z, nj_p4, Names_HH, ...
        dg_p4, ag_2d, z_grid, pi_z, ReturnFn_2d, P_p4, DiscountFactorParamNames, vfo_4);

    for r_idx = 1:N_reg
        hh_type  = Names_HH{r_idx};
        n_a_full = n_a.(hh_type);
        n_a1 = n_a_full(1); n_h = n_a_full(2); n_th = n_a_full(3);
        N_z  = prod(n_z.(hh_type));
        len4 = length(j_p4);

        V.(hh_type)(:, :, :, :, j_p4) = repmat(reshape(V_p4.(hh_type), [n_a1, n_h, 1, N_z, len4]), [1, 1, n_th, 1, 1]);
        % Pol_p4 has 5 rows: [d1=1; d2=1; d3=1; aprime_idx; hprime_idx]. Extract rows 4:5:
        Pol_p4_ah = Pol_p4.(hh_type)(4:5, :, :, :, :);
        Policy.(hh_type)(4:5, :, :, :, :, j_p4) = repmat(reshape(Pol_p4_ah, [2, n_a1, n_h, 1, N_z, len4]), [1, 1, 1, n_th, 1, 1]);
        V_next_4d.(hh_type) = reshape(V_p4.(hh_type)(:, :, :, 1), [n_a1, n_h, 1, N_z]);
    end
end

% ---- PHASE 3: POST-PARENTING (j_s2_end+1 : Jr_int-1) — 2-State [a, h] Case1, n_d = [4, 3, 1] ----
if ~isempty(j_p3)
    vfo_3 = struct('verbose', 0, 'experienceasset', 0, 'vectorized', 1);
    if ~isempty(fieldnames(V_next_4d))
        vfo_3_vj = struct();
        for r_idx = 1:N_reg
            ht = Names_HH{r_idx};
            na = na_2d.(ht); Nz = prod(n_z.(ht));
            vfo_3_vj.(ht) = reshape(V_next_4d.(ht), [na(1), na(2), Nz]);
        end
        vfo_3.V_Jplus1 = vfo_3_vj;
    end
    P_p3 = slice_age_params_ptype(Params, Names_HH, j_p3, J);
    [V_p3, Pol_p3] = ValueFnIter_MixHorz_PType(nd_p3, na_2d, n_z, nj_p3, Names_HH, ...
        dg_p3, ag_2d, z_grid, pi_z, ReturnFn_2d, P_p3, DiscountFactorParamNames, vfo_3);

    for r_idx = 1:N_reg
        hh_type  = Names_HH{r_idx};
        n_a_full = n_a.(hh_type);
        n_a1 = n_a_full(1); n_h = n_a_full(2); n_th = n_a_full(3);
        N_z  = prod(n_z.(hh_type));
        len3 = length(j_p3);

        V.(hh_type)(:, :, :, :, j_p3) = repmat(reshape(V_p3.(hh_type), [n_a1, n_h, 1, N_z, len3]), [1, 1, n_th, 1, 1]);
        % Pol_p3 has 5 rows: [l_idx; Ih_idx; ic_idx=1; aprime_idx; hprime_idx]. Extract [1,2,4,5]:
        Pol_p3_sub = Pol_p3.(hh_type)([1, 2, 4, 5], :, :, :, :);
        Policy.(hh_type)([1, 2, 4, 5], :, :, :, :, j_p3) = repmat(reshape(Pol_p3_sub, [4, n_a1, n_h, 1, N_z, len3]), [1, 1, 1, n_th, 1, 1]);
        V_next_4d.(hh_type) = reshape(V_p3.(hh_type)(:, :, :, 1), [n_a1, n_h, 1, N_z]);
    end
end

% Broadcast 4D continuation value at j_s2_end + 1 across 9 theta_c points -> [61, 7, 9, n_z]
V_next_5d = struct();
for r_idx = 1:N_reg
    hh_type  = Names_HH{r_idx};
    n_a_full = n_a.(hh_type);
    n_th     = n_a_full(3);
    V_next_5d.(hh_type) = repmat(V_next_4d.(hh_type), [1, 1, n_th, 1]);
end

% ---- PHASE 2: ACTIVE PARENTING (j_s1_start : j_s2_end) — Full 5D Experience Asset ----
vfo_2 = vfoptions;
vfo_2.verbose    = 0;
vfo_2.vectorized = 1;
vfo_2.V_Jplus1   = V_next_5d;
P_p2 = slice_age_params_ptype(Params, Names_HH, j_p2, J);
[V_p2, Pol_p2] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, nj_p2, Names_HH, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, P_p2, DiscountFactorParamNames, vfo_2);

for r_idx = 1:N_reg
    hh_type  = Names_HH{r_idx};
    n_a_full = n_a.(hh_type);
    n_a1 = n_a_full(1); n_h = n_a_full(2); n_th = n_a_full(3);
    N_z  = prod(n_z.(hh_type));
    len2 = length(j_p2);

    V.(hh_type)(:, :, :, :, j_p2)      = reshape(V_p2.(hh_type),   [n_a1, n_h, n_th, N_z, len2]);
    Policy.(hh_type)(:, :, :, :, :, j_p2) = reshape(Pol_p2.(hh_type), [5, n_a1, n_h, n_th, N_z, len2]);
    V_next_5d.(hh_type) = reshape(V.(hh_type)(:, :, :, :, j_p2(1)), [n_a1, n_h, n_th, N_z]);
end

% ---- PHASE 1: PRE-PARENTING YOUTH (1 : j_s1_start-1) — 5D Experience Asset, n_d = [4, 3, 1] ----
% Must stay 5D because V_next_5d at j_s1_start depends on inherited theta_c!
if ~isempty(j_p1)
    vfo_1 = vfoptions;
    vfo_1.verbose    = 0;
    vfo_1.vectorized = 1;
    vfo_1.V_Jplus1   = V_next_5d;
    P_p1 = slice_age_params_ptype(Params, Names_HH, j_p1, J);
    [V_p1, Pol_p1] = ValueFnIter_MixHorz_PType(nd_p1, n_a, n_z, nj_p1, Names_HH, ...
        dg_p1, a_grid, z_grid, pi_z, ReturnFn, P_p1, DiscountFactorParamNames, vfo_1);

    for r_idx = 1:N_reg
        hh_type  = Names_HH{r_idx};
        n_a_full = n_a.(hh_type);
        n_a1 = n_a_full(1); n_h = n_a_full(2); n_th = n_a_full(3);
        N_z  = prod(n_z.(hh_type));
        len1 = length(j_p1);

        V.(hh_type)(:, :, :, :, j_p1) = reshape(V_p1.(hh_type), [n_a1, n_h, n_th, N_z, len1]);
        if size(Pol_p1.(hh_type), 1) == 5
            Policy.(hh_type)(:, :, :, :, :, j_p1) = reshape(Pol_p1.(hh_type), [5, n_a1, n_h, n_th, N_z, len1]);
        else
            Policy.(hh_type)([1, 2, 4, 5], :, :, :, :, j_p1) = reshape(Pol_p1.(hh_type), [4, n_a1, n_h, n_th, N_z, len1]);
        end
    end
end
end

%% ---- LOCAL HELPERS ----
function P_sub = slice_age_params_ptype(Params, Names_HH, j_range, J)
% Slices all age-indexed vectors of length J globally and per HH_Region, wrapping
% shared age vectors into per-HH structs so ValueFnIter_MixHorz_PType never mistakes
% a sub-horizon of length N_reg (e.g. length(j_p2) == 4 == N_i) for a PType vector!
P_sub    = Params;
all_flds = fieldnames(P_sub);
for k = 1:length(all_flds)
    fn  = all_flds{k};
    val = P_sub.(fn);
    if isstruct(val)
        changed = false;
        for r = 1:length(Names_HH)
            ht = Names_HH{r};
            if isfield(val, ht) && isnumeric(val.(ht)) && isvector(val.(ht)) && numel(val.(ht)) == J
                val.(ht) = val.(ht)(j_range);
                changed  = true;
            end
        end
        if changed
            P_sub.(fn) = val;
        end
    elseif isnumeric(val) && isvector(val) && numel(val) == J
        s_sliced = struct();
        for r = 1:length(Names_HH)
            s_sliced.(Names_HH{r}) = val(j_range);
        end
        P_sub.(fn) = s_sliced;
    end
end


end
