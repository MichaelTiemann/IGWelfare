function F = ReturnFn_SpatialHH_Compact4D(l, Ih, ic, aprime, hprime, a, h, z, ...
    w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
    Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, K_whanau, omega_ic, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
    j_s1_start, j_s2_end)
%% COMPACT 4D HOUSEHOLD RETURN FUNCTION (PARAMETRIC SUPER_AGE VIA Jr = 1 + (super_age - 20)/dt)

F = -Inf;
scale_dt      = dt / 5;
tol_hc        = max(0.18, 0.16 * h);
age_start_yrs = 20 + (agej - 1) * dt;
age_end_yrs   = age_start_yrs + dt;
super_age_yrs = 20 + (Jr - 1) * dt; % Exact continuous statutory retirement age (e.g. 65, 64, 63, 62, 70)

% Fraction of current period [age_start_yrs, age_end_yrs] spent in NZ Super eligibility:
super_share_j = min(1.0, max(0.0, (age_end_yrs - super_age_yrs) / dt));
is_full_ret   = (super_share_j >= 0.999);

%% 1. FULL-LIFECYCLE ADULT BEN-PORATH HUMAN CAPITAL LAW OF MOTION (h -> hprime)
if ~is_full_ret
    if l == 0 && Ih > 0
        return;
    end
    if l > 0
        h_expected = (1 - delta_hc) * h + 0.14 * scale_dt * (Ih ^ alpha_I) * (h ^ alpha_H);
    else
        h_expected = (1 - delta_hc) * h;
    end
    if abs(hprime - h_expected) > tol_hc && abs(hprime - h) > 0.01
        return;
    end
else
    if l > 0 || Ih > 0 || ic > 0
        return;
    end
    h_expected = (1 - 0.5 * delta_hc) * h;
    if abs(hprime - h_expected) > 0.22 && abs(hprime - h) > 0.16
        return;
    end
end

is_parenting = (agej >= j_s1_start) && (agej <= j_s2_end);
if (~is_parenting) && (ic > 0)
    return;
end

%% 2. STATE-CONTINGENT HOUSING USER COST p_H(a, z, Q_reg) (LVR-GATED ON 61-PT ASSET GRID)
R_ann  = (1 + r) ^ (1 / dt);
rr_reg = max(0.010 * Q_reg, (1 + mu_maint - (G_reg / R_ann)) * Q_reg);
rh_reg = max(0.008 * Q_reg, (1 + mu_maint - upsilon_h - (G_reg / R_ann)) * Q_reg);
xi_reg = min(1.0, (1 / chi_bar) * (rr_reg / rh_reg));

lvr_access       = min(1.0, max(0.0, a / max(1e-4, 0.20 * Q_reg)));
xi_hh            = min(1.0, xi_reg * (0.98 + 0.04 * lvr_access));
is_evict_tail    = double(a < 0.08 * Q_reg) * double(z < 0.85);
transience_wedge = 1.0 + 0.04 * is_evict_tail * max(0.0, (0.110 - G_ece) / 0.065);

if ~is_full_ret
    p_H = (xi_hh * rh_reg + (1 - xi_hh) * (rr_reg / (0.5 * chi_bar))) * transience_wedge;
else
    p_H = rh_reg;
end

%% 3. PARAMETRIC WHANAU CARE K_whanau_net(super_age_yrs) & MENTORING TRUST GATING
is_super_cut    = double(super_age_yrs > 65.5);
is_distress_z   = double(z < 0.80) * double(a < 0.12 * Q_reg);
if super_age_yrs >= 65
    elder_time_mult = exp(-0.09*(super_age_yrs - 65));
else
    elder_time_mult = 1 + 0.16*tanh((65 - super_age_yrs)/1.8);
end

K_whanau_net  = (K_whanau * elder_time_mult) - 0.28 * is_super_cut * is_distress_z;
sandwich_drag = max(0.0, -K_whanau_net) * 0.035;

M_mentor      = min(1.0, max(0.0, 0.173 + 12.0 * (G_ece - 0.045)));
M_trust_gated = M_mentor * (0.45 + 0.55 * min(1.0, max(0.0, K_whanau_net) / 0.35));

%% 4. BUDGET CONSTRAINT & "INCOME x GEOGRAPHY" TRANSFER RULE (FLOWS SCALED BY scale_dt)
s_sub            = min(0.80, G_ece / (G_ece + gbar_ece));
gross_earn       = w_reg * h * z * l;
T_geo            = Transfer_Geo * exp(-1.8 * gross_earn);
wealth_after_tax = ((1 - tau_a) ^ dt) * a + r * (1 - tau_k) * a;
youth_endow      = (agej == 1) * YouthGrant;
pension_inc      = super_share_j * p_super; % Exact parametric pension share for any super_age!

c_budget = wealth_after_tax - aprime + youth_endow ...
    + scale_dt * ((1 - tau_l) * gross_earn + T_geo + pension_inc - (1 - s_sub) * ic - ebar_energy - sandwich_drag);
c_eff    = max(scale_dt * c_floor, c_budget / (1 + tau_c)) / scale_dt;

if c_budget <= 0 && (aprime > 0 || ic > 0) && (~is_full_ret)
    return;
end

%% 5. COMPOSITE CONSUMPTION, LABOR/TRAINING DISUTILITY, & CHILD ALTRUISM
c_nd   = phi_nd * c_eff;
c_H    = (1 - phi_nd) * c_eff / p_H;
u_comp = (c_nd ^ phi_nd) * (c_H ^ (1 - phi_nd));
eta_c  = 2.0;

manual_wear_mult = (1.0 - 0.55 * super_share_j * double(~is_full_ret)) ...
    + 0.35 * double(age_end_yrs > 65.0) * double(~is_full_ret) * max(0.0, (1.00 - h) / 0.55);

u_flow = scale_dt * ((u_comp ^ (1 - eta_c)) / (1 - eta_c) - 0.85 * manual_wear_mult * ((l + Ih) ^ 1.6) / 1.6);

u_child = 0;
if is_parenting
    is_corner_ic   = double(ic < 0.01);
    metro_ece_mult = (max(1.0, Q_reg / 1.05) ^ 0.85) * (1.0 + 0.80 * max(0.0, 0.42 - K_whanau));
    Psi_perc       = -0.025 * is_corner_ic * max(0.0, (1 - 0.55 * K_whanau_net) * (1 - 0.80 * M_trust_gated)) ...
        + 0.045 * max(0.0, M_trust_gated - 0.173) * metro_ece_mult;
    I_eff          = 1.0 + 2.20 * (ic + G_ece * metro_ece_mult * (1 + 0.25 * M_trust_gated) + 0.025 * max(0.0, K_whanau_net) + gbar_ece);
    h_child_exp    = (h ^ 0.40) * (I_eff ^ 0.55) * exp(Psi_perc);
    u_child        = scale_dt * omega_ic * log(max(1e-4, h_child_exp));
end

%% 6. END-OF-LIFE WARM-GLOW BEQUEST (WITH SKILL-MANIFOLD MORTALITY GRADIENT sj_eff(h, j))
u_beq = 0;
if super_share_j > 0
    mort_grad  = exp(0.05 * (1.05 - h));
    mort_prob  = min(0.99, max(0.01, (1 - sj) * mort_grad));
    net_estate = (1 - tau_b) * max(0, aprime);
    u_beq      = super_share_j * mort_prob * b1_beq * (((b2_beq + net_estate) ^ (1 - eta_c)) / (1 - eta_c));
end

F = u_flow + u_child + u_beq;


end
