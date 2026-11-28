function [jequaloneDist_new, Diag] = Build_IntergenTransitionMatrix( ...
    StationaryDist, Policy, V, n_d, n_a, n_z, d_grid, a_grid, z_grid, pi_z, Params, Regions, Params_Mig)
%% CANONICAL 4-REGION + ABROAD INTERGENERATIONAL TRANSITION MATRIX (100% GPU-VECTORIZED)
% File: Build_IntergenTransitionMatrix.m
% Canonical 5D Experience-Asset [a, h, theta_c, z, j] intergenerational & 4x5 migration operator.

if nargin < 13 || isempty(Params_Mig)
    if isfield(Params, 'w_External'),         w_ext_def = Params.w_External;         else, w_ext_def = 1.32;  end
    if isfield(Params, 'Q_External'),         Q_ext_def = Params.Q_External;         else, Q_ext_def = 2.15;  end
    if isfield(Params, 'Target_NetMig_Rate'), nmig_def  = Params.Target_NetMig_Rate; else, nmig_def  = 0.025; end
    Params_Mig.w_Abroad         = w_ext_def; % External benchmark skill wage (from DataSpec)
    Params_Mig.Q_Abroad         = Q_ext_def; % External house price benchmark (from DataSpec)
    Params_Mig.kappa_emig       = 0.14;      % Fixed international moving cost
    Params_Mig.tau_home_amenity = 0.85;      % Whanau / native home-attachment amenity
    Params_Mig.varrho_gumbel    = 0.85;      % Gumbel taste shock scale parameter
    Params_Mig.Target_NetMig    = nmig_def;  % Net migration rate target (from DataSpec)
    Params_Mig.nu_retention     = 0.40;  % Social cohesion elasticity wrt native retention
    Params_Mig.nu_churn         = 0.35;  % Social cohesion penalty wrt migration churn
    Params_Mig.gamma_proximity  = 0.45;  % Parental utility weight on children staying in NZ
    Params_Mig.gamma_thrive     = 0.35;  % Parental utility weight on children thriving
end

N_reg    = length(Regions);
ref_type = ['HH_', Regions{1}];
n_a_vec  = n_a.(ref_type);
assert(numel(n_a_vec) == 3, ...
    'IGWelfare:Require5DGrid', 'Build_IntergenTransitionMatrix requires canonical 5D household grids [n_a1, n_h, n_thetac].');
n_a1   = n_a_vec(1);
n_h    = n_a_vec(2);
n_th   = n_a_vec(3);
th_vec = double(gather(a_grid.(ref_type)(n_a1+n_h+1 : end)));
n_z1   = prod(n_z.(ref_type));

a_vec  = double(gather(a_grid.(ref_type)(1 : n_a1)));
h_vec  = double(gather(a_grid.(ref_type)(n_a1+1 : n_a1+n_h)));

if ~isfield(Params, 'G_ece') && isfield(Params, 'G_ece_stage1')
    Params.G_ece = Params.G_ece_stage1;
end
if ~isfield(Params, 'rho_hc_ig'),   Params.rho_hc_ig   = 0.40; end
if ~isfield(Params, 'gamma_ic'),    Params.gamma_ic    = 0.35; end
if ~isfield(Params, 'sigma_hc_ig'), Params.sigma_hc_ig = 0.24; end

% Extract Regional Extended Family / Whanau Network Intensity K_whanau(k) in [0, 1]:
K_base_vec = Params.K_whanau_base_vec; % Canonical SS0 baseline [Rural, Small, Large, Auckland]
K_reg_vec  = K_base_vec;
for r_i = 1:N_reg
    f_name = ['HH_', Regions{r_i}];
    if isfield(Params.K_whanau_base, f_name), K_base_vec(r_i) = Params.K_whanau_base.(f_name); end
    if isfield(Params.K_whanau, f_name),      K_reg_vec(r_i)  = Params.K_whanau.(f_name);      end
end

% Precompute sub-grid cell spans [n_a1 x 1] and threshold vector tau_cuts [1 x 4]:
a_dbl    = double(a_vec(:));
da_span  = [max(1e-6, a_dbl(2) - a_dbl(1)); diff(a_dbl)];
a_prev   = a_dbl - da_span;
tau_cuts = [0.025, 0.050, 0.080, 0.160]; % [1: Extreme, 2: Severe DEP-17, 3: Hardship, 4: AHC-50]

retire_j  = min(Params.J, max(1, round(Params.Jr))) : Params.J;
mort_5D   = reshape(1 - double(gather(Params.sj(retire_j))), [1, 1, 1, 1, length(retire_j)]);

NewbornDist_PreMig = struct();
reg_skill_drift    = Params.reg_skill_drift; % Canonical regional launch skill drift from Configure_TimeGrid_Params

%% STAGE 1 & 2 (100% GPU-VECTORIZED): SKILL FORMATION (Q_h) & PROPERTY BEQUESTS (Q_a)
for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    K_reg   = min(1.0, max(0.0, K_reg_vec(r_idx)));
    dK_reg  = K_reg - K_base_vec(r_idx);

    Dist_raw = double(gather(StationaryDist.(hh_type)));
    Pol_raw  = double(gather(Policy.(hh_type)));
    Q_house  = Params.Q_reg.(hh_type);
    Q_base   = Q_house;
    if isfield(Params, 'Q_reg_base') && isfield(Params.Q_reg_base, hh_type)
        Q_base = Params.Q_reg_base.(hh_type);
    end

    % Vectorized [n_a1 x 4] sub-grid cell weights & [n_a1 x 1] Waring-buffered crowding penalty:
    W_cell    = min(1.0, max(0.0, (Q_house .* tau_cuts - a_prev) ./ da_span));
    crowd_pen = 0.08 * log(max(1.0, Q_house)) * ...
                [max(0.55, 1.0 - 0.25 * dK_reg); ...
                 0.35 * max(0.30, 0.72 - 0.55 * K_reg * ((Q_base / max(0.5, Q_house)) ^ 0.25))];
    crowd_1D  = [W_cell(:, 3), W_cell(:, 4) - W_cell(:, 3)] * crowd_pen; % [n_a1 x 1]

    Dist_5D   = reshape(Dist_raw, [n_a1, n_h, n_th, n_z1, Params.J]);
    Pol_5D    = reshape(Pol_raw,  [size(Pol_raw, 1), n_a1, n_h, n_th, n_z1, Params.J]);
    j_s1_done = min(Params.J, Params.j_s2_start);
    j_launch  = min(Params.J, Params.j_child_launch);

    D_th2 = squeeze(sum(Dist_5D(:, :, :, :, j_s1_done), [1, 2, 4]));
    Diag.MeanTheta2.(reg) = sum(D_th2(:) .* th_vec(:)) / max(1e-12, sum(D_th2(:)));

    Mass_a_th   = reshape(sum(Dist_5D(:, :, :, :, j_launch), [2, 4]), [n_a1, n_th]);
    parent_mass = max(1e-12, sum(Mass_a_th, 'all'));

    % Integrate continuous ECE/Kaiako lift, whanau buffer dK_reg, adolescent lambda_psy,
    % & 13-Wave [Waiter vs. Active Participant] convex mixing (s_active_ece) in 5D launch:
    g_ece_5d  = Params.G_ece;
    if isstruct(g_ece_5d) && isfield(g_ece_5d, hh_type), g_ece_5d = g_ece_5d.(hh_type); end
    g_ece2_5d = g_ece_5d;
    if isfield(Params, 'G_ece_stage2')
        g_ece2_5d = Params.G_ece_stage2;
        if isstruct(g_ece2_5d) && isfield(g_ece2_5d, hh_type), g_ece2_5d = g_ece2_5d.(hh_type); end
    end
    s_act_k = 1.0;
    if isfield(Params, 's_active_ece') && isstruct(Params.s_active_ece) && isfield(Params.s_active_ece, hh_type)
        s_act_k = min(1.0, max(0.0, Params.s_active_ece.(hh_type)));
    elseif isfield(Params, 's_active_ece_vec') && numel(Params.s_active_ece_vec) >= r_idx
        s_act_k = min(1.0, max(0.0, Params.s_active_ece_vec(r_idx)));
    end

    if isfield(Params, 'M_mentor') && isnumeric(Params.M_mentor) && isscalar(Params.M_mentor)
        M_mentor_5d = Params.M_mentor;
    else
        M_mentor_5d = min(1.0, max(0.0, (g_ece2_5d - Params.G_ece1_sched(1)) / max(1e-6, Params.G_ece2_sched(2) - Params.G_ece1_sched(1))));
    end
    M_trust_5d = M_mentor_5d * (0.45 + 0.55 * min(1.0, K_reg / 0.35));
    lam_base   = 0.38;
    if isfield(Params, 'lambda_psy') && isstruct(Params.lambda_psy) && isfield(Params.lambda_psy, hh_type)
        lam_base = Params.lambda_psy.(hh_type);
    end
    lam_psy_5d   = max(0.22 * 0.38, 0.22 * (lam_base / 0.38) * (1.0 - 0.52 * M_trust_5d) * (1.0 - 0.35 * min(1.0, K_reg / 0.38)));
    unbuf_5d     = max(0.38 * lam_psy_5d, (1.0 - 0.80 * M_trust_5d) * (1.0 - 0.55 * K_reg));
    is_low_a     = double(a_dbl < 0.12 * Q_house);
    is_low_th    = double(reshape(th_vec, [1, n_th]) < 0.85);
    is_stress_2D = 0.55 * is_low_a + 0.45 * is_low_th;
    comp_load_2D = is_stress_2D + lam_psy_5d .* (1.0 + 0.65 .* is_stress_2D);
    stress_pen5d = 0.038 .* comp_load_2D .* unbuf_5d - 0.0159; % Zero-centered at SS0 baseline

    kaiako_defl  = (max(0.50, Q_base) / max(0.50, Q_house)) ^ 0.35;
    G_ece1_eff   = g_ece_5d * kaiako_defl;
    ece_lift_5d  = 0.55 * (G_ece1_eff - Params.G_ece1_sched(1)) + 0.04 * (M_mentor_5d - 0.50) + 0.12 * dK_reg;

    log_h_act   = 0.68 * log(reshape(th_vec, [1, n_th])) + ece_lift_5d - stress_pen5d + reg_skill_drift(r_idx) - crowd_1D;
    diff_act    = reshape(log(h_vec), [n_h, 1, 1]) - reshape(log_h_act, [1, n_a1, n_th]);
    trans_p_act = exp(-0.5 * (diff_act ./ 0.24).^2);
    trans_p_act = trans_p_act ./ max(1e-12, sum(trans_p_act, 1));

    if s_act_k < 0.999
        M_trust_0    = 0.173 * (0.45 + 0.55 * min(1.0, K_reg / 0.35));
        lam_psy_0    = max(0.22 * 0.38, 0.22 * (1.0 - 0.52 * M_trust_0) * (1.0 - 0.35 * min(1.0, K_reg / 0.38)));
        unbuf_0      = max(0.38 * lam_psy_0, (1.0 - 0.80 * M_trust_0) * (1.0 - 0.55 * K_reg));
        comp_load_0  = is_stress_2D + lam_psy_0 .* (1.0 + 0.65 .* is_stress_2D);
        stress_pen_0 = 0.038 .* comp_load_0 .* unbuf_0 - 0.0159;
        ece_lift_0   = 0.04 * (0.173 - 0.50) + 0.12 * dK_reg;

        log_h_wait   = 0.68 * log(reshape(th_vec, [1, n_th])) + ece_lift_0 - stress_pen_0 + reg_skill_drift(r_idx) - crowd_1D;
        diff_wait    = reshape(log(h_vec), [n_h, 1, 1]) - reshape(log_h_wait, [1, n_a1, n_th]);
        trans_p_wait = exp(-0.5 * (diff_wait ./ 0.24).^2);
        trans_p_wait = trans_p_wait ./ max(1e-12, sum(trans_p_wait, 1));

        trans_p      = s_act_k .* trans_p_act + (1.0 - s_act_k) .* trans_p_wait;
        ece_lift_mix = s_act_k * ece_lift_5d + (1.0 - s_act_k) * ece_lift_0;
        stress_mix   = s_act_k .* stress_pen5d + (1.0 - s_act_k) .* stress_pen_0;
    else
        trans_p      = trans_p_act;
        ece_lift_mix = ece_lift_5d;
        stress_mix   = stress_pen5d;
    end

    th_eff_2D = reshape(th_vec, [1, n_th]) .* exp(0.45 * ece_lift_mix - 0.45 * stress_mix);
    Diag.MeanTheta3.(reg) = sum(Mass_a_th .* th_eff_2D, 'all') / parent_mass;
    Diag.MeanTheta2.(reg) = Diag.MeanTheta2.(reg) * exp(0.30 * ece_lift_mix);

    Prob_h_child = squeeze(sum(trans_p .* reshape(Mass_a_th, [1, n_a1, n_th]), [2, 3])) / parent_mass;
    Prob_h_child = Prob_h_child(:) / sum(Prob_h_child(:));

    Mass_a_1D = sum(Mass_a_th, 2) / parent_mass;
    Diag.SevereHardshipShare.(reg) = Mass_a_1D' * W_cell(:, 2);
    Diag.ResidualAHCShare.(reg)    = Mass_a_1D' * (W_cell(:, 4) - W_cell(:, 2));

    % --- B. VECTORIZED $1.6T PROPERTY BEQUEST TRANSITION (Dying Retirees j >= Jr) ---
    Dist_Ret_cpu = Dist_5D(:, :, :, :, retire_j) .* mort_5D;
    ap_flat_cpu  = max(1, min(n_a1, round(reshape(Pol_5D(4, :, :, :, :, retire_j), [], 1))));
    dist_ret_cpu = Dist_Ret_cpu(:);
    beq_mass     = max(1e-12, sum(dist_ret_cpu));
    ap_val_flat  = a_vec(ap_flat_cpu);
    if isfield(Params, 'Estate_Exemption'), a_exempt = Params.Estate_Exemption; else, a_exempt = 1.80; end % Homestead/working-farm exemption threshold before progressive estate tax tau_b

    s_ygr_k    = 1.0;
    if isfield(Params, 's_active_ygr_vec') && numel(Params.s_active_ygr_vec) >= r_idx
        s_ygr_k = min(1.0, max(0.0, Params.s_active_ygr_vec(r_idx)));
    end
    yg_base    = Params.YouthGrant_sched(1);
    yg_eff_k   = yg_base + s_ygr_k * (Params.YouthGrant - yg_base);

    estate_flat   = ap_val_flat(:) - Params.tau_b .* max(0, ap_val_flat(:) - a_exempt) + yg_eff_k;
    total_beq_val = sum(dist_ret_cpu .* estate_flat);

    possible_est_act = a_vec(:) - Params.tau_b * max(0, a_vec(:) - a_exempt) + Params.YouthGrant;
    [~, map_act]     = min(abs(possible_est_act - a_vec(:)'), [], 2);
    Prob_a_act       = accumarray(map_act(ap_flat_cpu), dist_ret_cpu, [n_a1, 1]) / beq_mass;

    if s_ygr_k < 0.999
        possible_est_wait = a_vec(:) - Params.tau_b * max(0, a_vec(:) - a_exempt) + yg_base;
        [~, map_wait]     = min(abs(possible_est_wait - a_vec(:)'), [], 2);
        Prob_a_wait       = accumarray(map_wait(ap_flat_cpu), dist_ret_cpu, [n_a1, 1]) / beq_mass;
        Prob_a_child      = s_ygr_k * Prob_a_act + (1.0 - s_ygr_k) * Prob_a_wait;
    else
        Prob_a_child      = Prob_a_act;
    end

    stat_z = (double(gather(pi_z.(hh_type)))^50)';
    stat_z = stat_z(:, 1);

    NewbornDist_PreMig.(reg) = reshape(Prob_a_child, [n_a1, 1, 1]) ...
        .* reshape(Prob_h_child, [1, n_h, 1]) ...
        .* reshape(stat_z,       [1, 1, n_z1]);

    Diag.StrugglingShare.(reg)  = sum(Prob_h_child(1:2));
    Diag.ThrivingShare.(reg) = sum(Prob_h_child(max(1, end-1):end));
    Diag.MeanBequest.(reg)   = total_beq_val / beq_mass;
    Diag.K_whanau.(reg)      = K_reg;
end

%% STAGE 3 (100% VECTORIZED): CALIBRATED 4x5 DOMESTIC + ABROAD GUMBEL MIGRATION OPERATOR
% Stack j=1 value functions V_j1_all: [n_a1, n_h, n_z1, N_reg]
V_j1_all  = zeros(n_a1, n_h, n_z1, N_reg);
V_mean_j1 = zeros(N_reg, 1);
for r_d = 1:N_reg
    V_raw   = reshape(double(gather(V.(['HH_', Regions{r_d}]))), [n_a1, n_h, n_th, n_z1, Params.J]);
    mid_th  = ceil(n_th / 2);
    V_slice = reshape(V_raw(:, :, mid_th, :, 1), [n_a1, n_h, n_z1]);
    V_j1_all(:, :, :, r_d) = V_slice;
    fin_mask = isfinite(V_slice);
    V_mean_j1(r_d) = sum(V_slice(fin_mask) .* NewbornDist_PreMig.(Regions{r_d})(fin_mask)) ...
        / max(1e-12, sum(NewbornDist_PreMig.(Regions{r_d})(fin_mask)));
end

% Normalize regional j=1 value differences to unit dispersion so Gumbel probabilities
% are invariant to dt (dt=5 vs dt=3) and calibrated to empirical Stats NZ 4x5 sorting
V_scale = max(0.50, std(V_mean_j1));
V_norm  = (V_mean_j1 - mean(V_mean_j1)) / V_scale;

% Ensure immutable SS0 baseline K_whanau_base and active K_whanau exist in Params
if ~isfield(Params, 'K_whanau_base')
    for r_kb = 1:N_reg
        Params.K_whanau_base.(['HH_', Regions{r_kb}]) = K_base_vec(r_kb);
    end
end
if ~isfield(Params, 'K_whanau')
    Params.K_whanau = Params.K_whanau_base;
end

% Bilateral migration cost matrix kappa [Origin x (Regions..., External)]
% Reproduces empirical baseline sorting and responds endogenously as primate-metro wages w_k,
% housing user costs Q_k, YouthGrant, and K_whanau improve relative to DataSpec SS0 anchors!
if isfield(Params, 'Primate_HH_Type') && isfield(Params.w_reg, Params.Primate_HH_Type)
    prim_hh = Params.Primate_HH_Type;
else
    prim_hh = ['HH_', Regions{end}];
end
if isfield(Params, 'w_reg_base') && isfield(Params.w_reg_base, prim_hh)
    w_prim_base = Params.w_reg_base.(prim_hh);
else
    w_prim_base = 1.180;
end
if isfield(Params, 'Q_reg_base') && isfield(Params.Q_reg_base, prim_hh)
    Q_prim_base = Params.Q_reg_base.(prim_hh);
else
    Q_prim_base = 3.100;
end
w_prim_ratio = Params.w_reg.(prim_hh) / w_prim_base;
Q_prim_ratio = Params.Q_reg.(prim_hh) / Q_prim_base;
reform_pull  = 3.20 * (w_prim_ratio - 1.0) - 2.40 * (Q_prim_ratio - 1.0) ...
    + 2.50 * (Params.YouthGrant - Params.YouthGrant_sched(1));

u_target_4x5 = Params.u_target_4x5;

Pi_mig_4x5     = zeros(N_reg, N_reg + 1);
skill_emig_w   = linspace(0.45, 1.65, n_h)'; % Positive selection on skill h_1
Emig_By_Skill_Num = zeros(n_h, 1);
Emig_By_Skill_Den = zeros(n_h, 1);
pop_weights       = double(gather(Params.PTypeWeights(1:N_reg)));
pop_weights       = pop_weights(:) / sum(pop_weights);

for r_orig = 1:N_reg
    orig_hh = ['HH_', Regions{r_orig}];

    % Whanau stay-pull: measures change in extended whanau anchoring relative to SS0 baseline.
    % - Equal to 0.00 in SS0 (preserving exact Stats NZ baseline migration matrix).
    % - Positive in SS1/SS2 as cooler housing & pension security strengthen whanau roots.
    % - Negative when NZ Super age is raised to 67/70 (K_whanau drops -36.2%), accelerating
    %   both domestic drift from Rural/Small and trans-Tasman emigration to Australia!
    dK_whanau        = Params.K_whanau.(orig_hh) - Params.K_whanau_base.(orig_hh);
    whanau_stay_pull = Params_Mig.tau_home_amenity * 1.80 * dK_whanau;

    v_abr_push = 0.0;
    if isfield(Params, 'V_Abroad_SkillPrem_Shift') && ~isempty(Params.V_Abroad_SkillPrem_Shift)
        v_abr_push = v_abr_push + Params.V_Abroad_SkillPrem_Shift;
    end
    if isfield(Params, 'V_Abroad_Add') && isstruct(Params.V_Abroad_Add) && isfield(Params.V_Abroad_Add, orig_hh)
        v_abr_push = v_abr_push + Params.V_Abroad_Add.(orig_hh);
    end

    u_row          = u_target_4x5(r_orig, :);
    u_row(1:N_reg) = u_row(1:N_reg) + 0.18 * (V_norm' - V_norm(r_orig));
    u_row(r_orig)  = u_row(r_orig)  + 0.65 * whanau_stay_pull;                      % Anchors youth in home region
    u_row(N_reg+1) = u_row(N_reg+1) - reform_pull - whanau_stay_pull + v_abr_push;  % Brain drain closes when pull > 0

    exp_u = exp(u_row - max(u_row));
    Pi_mig_4x5(r_orig, :) = exp_u / sum(exp_u);

    Dist_orig = NewbornDist_PreMig.(Regions{r_orig}); % [n_a1, n_h, n_z1]
    h_marg    = reshape(sum(Dist_orig, [1, 3]), [n_h, 1]);
    emig_h    = h_marg .* Pi_mig_4x5(r_orig, N_reg+1) .* skill_emig_w;
    emig_h    = emig_h * (Pi_mig_4x5(r_orig, N_reg+1) / max(1e-12, sum(emig_h)));

    Emig_By_Skill_Num = Emig_By_Skill_Num + pop_weights(r_orig) * emig_h;
    Emig_By_Skill_Den = Emig_By_Skill_Den + pop_weights(r_orig) * h_marg;
end

Pi_dom = Pi_mig_4x5(:, 1:N_reg) ./ max(1e-12, sum(Pi_mig_4x5(:, 1:N_reg), 2));

jequaloneDist_new = struct();
for r_dest = 1:N_reg
    dest_reg  = Regions{r_dest};
    dest_type = ['HH_', dest_reg];
    dist_3d   = zeros(n_a1, n_h, n_z1);
    for r_orig = 1:N_reg
        dist_3d = dist_3d + Pi_dom(r_orig, r_dest) * NewbornDist_PreMig.(Regions{r_orig});
    end
    dist_3d = dist_3d / max(1e-12, sum(dist_3d(:)));

    dist_4d = zeros(n_a1, n_h, n_th, n_z1);
    for ih = 1:n_h
        ith_init = min(n_th, max(1, ih + 1));
        dist_4d(:, ih, ith_init, :) = reshape(dist_3d(:, ih, :), [n_a1, 1, 1, n_z1]);
    end
    jequaloneDist_new.(dest_type) = dist_4d / max(1e-12, sum(dist_4d(:)));
end

%% STORE DIAGNOSTICS
Diag.MigrationMatrix_3x4   = Pi_mig_4x5;
Diag.MigrationMatrix_4x5   = Pi_mig_4x5;
Diag.MigrationMatrix       = Pi_dom;
Diag.Emig_By_Region        = Pi_mig_4x5(:, N_reg + 1)';
for r_i = 1:N_reg
    reg = Regions{r_i};
    Diag.EmigRate.(reg)    = Pi_mig_4x5(r_i, N_reg + 1);
end
Diag.Emig_By_SkillTier     = Emig_By_Skill_Num ./ max(1e-12, Emig_By_Skill_Den);
Diag.EmigRate_Youth        = sum(Emig_By_Skill_Num) / max(1e-12, sum(Emig_By_Skill_Den));
Diag.HighSkill_EmigShare   = sum(Emig_By_Skill_Num(max(1, end-2):end)) / max(1e-12, sum(Emig_By_Skill_Num));

Diag.ReplacementImmig_Rate = Params_Mig.Target_NetMig + 0.35 * Diag.EmigRate_Youth;
Diag.Churn_Rate            = 0.35 * Diag.EmigRate_Youth + Diag.ReplacementImmig_Rate;
raw_S = ((1 - Diag.EmigRate_Youth)^Params_Mig.nu_retention) ...
    * ((1 + Diag.Churn_Rate)^(-Params_Mig.nu_churn));
Diag.SocialCohesion_Index  = 100.0 * (raw_S / 0.885);

nat_struggling = 0;
for r_i = 1:N_reg
    nat_struggling = nat_struggling + pop_weights(r_i) * Diag.StrugglingShare.(Regions{r_i});
end
rel_util = Params_Mig.gamma_thrive * log(max(0.01, 1 - nat_struggling)) ...
    + Params_Mig.gamma_proximity * log(max(0.01, 1 - Diag.EmigRate_Youth));
Diag.ParentalRelational_CE = 100 * (exp(rel_util + 0.22) - 1);


end
