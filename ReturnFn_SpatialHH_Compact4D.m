function F = ReturnFn_SpatialHH_Compact4D(l, Ih, ic, aprime, hprime, a, h, z, ...
    w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
    Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, K_whanau, omega_ic, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
    j_s1_start, j_s2_end)
%% COMPACT 4D HOUSEHOLD RETURN FUNCTION (SCALED BY dt FOR STEP 4 & STEP 6 DECOMPOSITION)

F = -Inf;
scale_dt = dt / 5;
tol_hc   = max(0.11, 0.16 * scale_dt);

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
    h_expected = (1 - 0.5 * delta_hc) * h;
    if abs(hprime - h_expected) > 0.22 && abs(hprime - h) > 0.16
        return;
    end
end

is_parenting = (agej >= j_s1_start) && (agej <= j_s2_end);
if (~is_parenting) && (ic > 0)
    return;
end

R_ann  = (1 + r) ^ (1 / dt);
rr_reg = max(0.010 * Q_reg, (1 + mu_maint - (G_reg / R_ann)) * Q_reg);
rh_reg = max(0.008 * Q_reg, (1 + mu_maint - upsilon_h - (G_reg / R_ann)) * Q_reg);

xi_own = min(1.0, (1 / chi_bar) * (rr_reg / rh_reg));
if agej < Jr
    p_H = xi_own * rh_reg + (1 - xi_own) * (rr_reg / (0.5 * chi_bar));
else
    p_H = rh_reg;
end

K_whanau         = min(1.0, max(0.0, K_whanau));
s_sub            = min(0.80, (G_ece + 0.015 * K_whanau) / max(1e-4, G_ece + gbar_ece + 0.015 * K_whanau));
gross_earn       = w_reg * h * z * l;
T_geo            = Transfer_Geo * exp(-1.8 * gross_earn);
wealth_after_tax = ((1 - tau_a) ^ dt) * a + r * (1 - tau_k) * a;
youth_endow      = (agej == 1) * YouthGrant;
pension_inc      = (agej >= Jr) * p_super;

c_budget = wealth_after_tax - aprime + youth_endow ...
    + scale_dt * ((1 - tau_l) * gross_earn + T_geo + pension_inc - (1 - s_sub) * ic - ebar_energy);
c_eff    = max(scale_dt * c_floor, c_budget / (1 + tau_c)) / scale_dt;
if c_budget <= 0 && agej < Jr
    return;
end

c_nd   = phi_nd * c_eff;
c_H    = (1 - phi_nd) * c_eff / p_H;
u_comp = (c_nd ^ phi_nd) * (c_H ^ (1 - phi_nd));
eta_c  = 2.0;
u_flow = scale_dt * ((u_comp ^ (1 - eta_c)) / (1 - eta_c) - 0.85 * ((l + Ih) ^ 1.6) / 1.6);

u_child = 0;
if is_parenting
    n_par_steps   = max(1, j_s2_end - j_s1_start + 1);
    hp_eff        = h * (1.0 + 0.15 * K_whanau);
    inv_eff       = 1.0 + ic + G_ece + gbar_ece + 0.020 * K_whanau;
    stress_pen    = 0.045 * double(ic < 0.01) * (1.0 - 0.55 * K_whanau);
    h_child_exp   = (hp_eff ^ 0.40) * (inv_eff ^ 0.35) * exp(-stress_pen + 0.010 * K_whanau);
    u_child       = (omega_ic / n_par_steps) * log(max(1e-4, h_child_exp));
end

u_beq = 0;
if agej >= Jr
    net_estate = (1 - tau_b) * max(0, aprime);
    u_beq      = (1 - sj) * b1_beq * (((b2_beq + net_estate) ^ (1 - eta_c)) / (1 - eta_c));
end

F = u_flow + u_child + u_beq;


end
