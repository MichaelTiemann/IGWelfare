function F = ReturnFn_SpatialHH(l, Ih, ic, aprime, hprime, a, h, theta_c, z, ...
    w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
    Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
    omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
    gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
    Q_base_reg, K_whanau_base)
%% CANONICAL 5D HOUSEHOLD RETURN FUNCTION (TAUCHEN-ENHANCED ACROSS EXISTING [a, h, theta_c, z, j] GRIDS)

F = -Inf;
scale_dt = dt / 5;

%% 1. FULL-LIFECYCLE ADULT BEN-PORATH HUMAN CAPITAL LAW OF MOTION (h -> hprime)
tol_hc = max(0.11, 0.16 * scale_dt);
if agej < Jr
    if l == 0 && Ih > 0
        return;
    end
    if l > 0
        h_expected = (1 - delta_hc) * h + 0.14 * scale_dt * (Ih ^ alpha_I) * (h ^ alpha_H);
    else
        h_expected = (1 - delta_hc) * h;
    end
    if abs(hprime - h_expected) > tol_hc
        return;
    end
else
    if l > 0 || Ih > 0 || ic > 0
        return;
    end
    % In retirement (j >= Jr), adult human capital slowly depreciates or stays adjacent on grid
    h_expected = (1 - 0.5 * delta_hc) * h;
    if abs(hprime - h_expected) > 0.22 && abs(hprime - h) > 0.16
        return;
    end
end

is_stage1 = (agej >= j_s1_start) && (agej <= j_s1_end);
is_stage2 = (agej >= j_s2_start) && (agej <= j_s2_end);
if (~is_stage1 && ~is_stage2) && (ic > 0)
    return;
end

%% 2. STATE-CONTINGENT HOUSING USER COST p_H(a, z, Q_reg) ON EXISTING 61-POINT ASSET GRID
R_ann  = (1 + r) ^ (1 / dt);
rr_reg = max(0.010 * Q_reg, (1 + mu_maint - (G_reg / R_ann)) * Q_reg);
rh_reg = max(0.008 * Q_reg, (1 + mu_maint - upsilon_h - (G_reg / R_ann)) * Q_reg);
xi_reg = min(1.0, (1 / chi_bar) * (rr_reg / rh_reg));

% Individual household tenure weight xi_hh(a, Q_reg) depends on clearing the 20% LVR
% deposit hurdle (0.20 * Q_reg), plus a tail eviction/transience penalty when asset-poor
% (a < 0.08 * Q_reg) and hit by an adverse income shock (z < 0.85):
lvr_access   = min(1.0, max(0.0, a / max(1e-4, 0.20 * Q_reg)));
xi_hh        = xi_reg * (0.25 + 0.75 * lvr_access);
is_evict_tail = double(a < 0.08 * Q_reg) * double(z < 0.85);
transience_wedge = 1.0 + 0.12 * is_evict_tail;

if agej < Jr
    p_H = (xi_hh * rh_reg + (1 - xi_hh) * (rr_reg / (0.5 * chi_bar))) * transience_wedge;
else
    p_H = (0.70 + 0.30 * lvr_access) * rh_reg + (1 - (0.70 + 0.30 * lvr_access)) * (rr_reg / (0.5 * chi_bar));
end

%% 3. TAUCHEN- & ASSET-CONDITIONED WHANAU CARE K_whanau_net(z, a, Jr) AND KAIAKO SUPPLY
super_age_yrs = 20 + (Jr - 1) * dt;
is_super_cut  = double(super_age_yrs > 65.5);
is_distress_z = double(z < 0.80) * double(a < 0.12 * Q_reg);

% When Super age > 65 and household is in tail distress, K_whanau_net turns negative
% (upward eldercare and financial bailout drain on working-age Sandwich Generation):
K_whanau_net     = K_whanau_base * (1.0 - 0.362 * is_super_cut) - 0.28 * is_super_cut * is_distress_z;
sandwich_drag = max(0.0, -K_whanau_net) * 0.035; % Upward eldercare cash/time drain

nu_kaiako     = 0.35;
kaiako_mult   = (max(0.50, Q_base_reg) / max(0.50, Q_reg)) ^ nu_kaiako;
G_ece1_eff    = G_ece_stage1 * kaiako_mult;
G_ece2_eff    = G_ece_stage2 * kaiako_mult;
M_mentor      = min(1.0, max(0.0, (G_ece2_eff - 0.045) / (0.085 - 0.045)));
M_trust_gated = M_mentor * (0.45 + 0.55 * min(1.0, max(0.0, K_whanau_net) / 0.35));

%% 4. BUDGET CONSTRAINT & "INCOME x GEOGRAPHY" TRANSFER RULE (FLOWS SCALED BY scale_dt)
gross_earn       = w_reg * h * z * l;
T_geo            = Transfer_Geo * exp(-1.8 * gross_earn);
wealth_after_tax = ((1 - tau_a) ^ dt) * a + r * (1 - tau_k) * a;
youth_endow      = (agej == 1) * YouthGrant;
pension_inc      = (agej >= Jr) * p_super;

c_budget = wealth_after_tax - aprime + youth_endow ...
    + scale_dt * ((1 - tau_l) * gross_earn + T_geo + pension_inc - (1 - s_sub) * ic - ebar_energy - sandwich_drag);
c_eff    = max(scale_dt * c_floor, c_budget / (1 + tau_c)) / scale_dt;

if c_budget <= 0 && agej < Jr
    return;
end

%% 5. COMPOSITE CONSUMPTION, LABOR/TRAINING DISUTILITY, & TWO-STAGE CHILD ALTRUISM
c_nd   = phi_nd * c_eff;
c_H    = (1 - phi_nd) * c_eff / p_H;
u_comp = (c_nd ^ phi_nd) * (c_H ^ (1 - phi_nd));
eta_c  = 2.0;

% Differential physical health depreciation / labor disutility for manual low-h
% older workers forced to work past Age 65 (ages 65-69 when Jr is raised):
age_yrs          = 20 + (agej - 1) * dt;
manual_wear_mult = 1.0 + 0.35 * double(age_yrs >= 65) * max(0.0, (1.00 - h) / 0.55);

u_flow = scale_dt * ((u_comp ^ (1 - eta_c)) / (1 - eta_c) - 0.85 * manual_wear_mult * ((l + Ih) ^ 1.6) / 1.6);

u_child = 0;
if is_stage1
    I_eff1  = 0.55 + 2.50 * max(1e-4, ic + G_ece1_eff * (1 + 0.15 * M_trust_gated) + 0.025 * max(0.0, K_whanau_net) + gbar_ece);
    th_2    = (gamma1_self * (max(1e-4, theta_c)^phi1_ces) + gamma1_inv * (I_eff1^phi1_ces) + gamma1_par * (h^phi1_ces)) ^ (1 / phi1_ces);
    u_child = (omega_ic / max(1, n_stage1_steps)) * log(max(1e-4, th_2));
elseif is_stage2
    I_eff2  = 0.55 + 2.50 * max(1e-4, ic + G_ece2_eff + 0.020 * max(0.0, K_whanau_net) + gbar_ece);
    th_3    = (gamma2_self * (max(1e-4, theta_c)^phi2_ces) + gamma2_inv * (I_eff2^phi2_ces) + gamma2_par * (h^phi2_ces)) ^ (1 / phi2_ces);
    is_corner_ic = double(ic < 0.01);
    Psi_perc     = -0.045 * is_corner_ic * max(0.0, (1 - 0.55 * K_whanau_net) * (1 - 0.80 * M_trust_gated)) + 0.035 * M_trust_gated;
    u_child = (omega_ic / max(1, n_stage2_steps)) * log(max(1e-4, th_3 * exp(Psi_perc)));
end

%% 6. END-OF-LIFE WARM-GLOW BEQUEST (WITH DIFFERENTIAL MORTALITY GRADIENT sj_eff(h, j))
u_beq = 0;
if agej >= Jr
    % Differential mortality gradient: manual/low-h cohorts face higher late-life mortality hazard
    mort_grad = exp(0.18 * (1.00 - h));
    mort_prob = min(0.99, max(0.01, (1 - sj) * mort_grad));
    net_estate = (1 - tau_b) * max(0, aprime);
    u_beq      = mort_prob * b1_beq * (((b2_beq + net_estate) ^ (1 - eta_c)) / (1 - eta_c));
end

F = u_flow + u_child + u_beq;


end
