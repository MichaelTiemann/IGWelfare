function F = ReturnFn_SpatialHH(ic, l, Ih, aprime, hprime, a, h, theta_c, z, ...
    w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
    Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
    omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
    gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps)
%% CANONICAL 5D HOUSEHOLD RETURN FUNCTION (PARAMETERIZED BY PERIOD LENGTH dt)

F = -Inf;
scale_dt = dt / 5;

%% 1. FULL-LIFECYCLE ADULT BEN-PORATH HUMAN CAPITAL LAW OF MOTION (h -> hprime)
if agej < Jr
    if l == 0 && Ih > 0
        return;
    end
    if l > 0
        h_expected = (1 - delta_hc) * h + scale_dt * (Ih ^ alpha_I) * (h ^ alpha_H);
    else
        h_expected = (1 - delta_hc) * h;
    end
    if abs(hprime - h_expected) > 0.16
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

%% 2. KIYOTAKI ET AL. (2024) & HIRANO-TODA (2025) HOUSING USER COSTS (SCALED BY dt)
R_ann  = (1 + r) ^ (1 / dt);
rr_reg = max(0.010 * Q_reg, (1 + mu_maint - (G_reg / R_ann)) * Q_reg);
rh_reg = max(0.008 * Q_reg, (1 + mu_maint - upsilon_h - (G_reg / R_ann)) * Q_reg);

xi_own = min(1.0, (1 / chi_bar) * (rr_reg / rh_reg));
if agej < Jr
    p_H = xi_own * rh_reg + (1 - xi_own) * (rr_reg / (0.5 * chi_bar));
else
    p_H = rh_reg;
end

%% 3. BUDGET CONSTRAINT & "INCOME x GEOGRAPHY" TRANSFER RULE
gross_earn = w_reg * h * z * l;
T_geo      = Transfer_Geo * exp(-1.8 * gross_earn);

wealth_after_tax = ((1 - tau_a) ^ dt) * a + r * (1 - tau_k) * a;
youth_endow      = (agej == 1) * YouthGrant;
pension_inc      = (agej >= Jr) * p_super;

c_budget = wealth_after_tax + (1 - tau_l) * gross_earn + T_geo + youth_endow + pension_inc ...
    - aprime - (1 - s_sub) * ic - ebar_energy;
c_eff    = max(c_floor, c_budget / (1 + tau_c));

if c_budget <= 0 && agej < Jr
    return;
end

%% 4. COMPOSITE CONSUMPTION, LABOR/TRAINING DISUTILITY, & TWO-STAGE CHILD ALTRUISM
c_nd   = phi_nd * c_eff;
c_H    = (1 - phi_nd) * c_eff / p_H;
u_comp = (c_nd ^ phi_nd) * (c_H ^ (1 - phi_nd));

eta_c  = 2.0;
u_flow = (u_comp ^ (1 - eta_c)) / (1 - eta_c) - 0.85 * ((l + Ih) ^ 1.6) / 1.6;

u_child = 0;
if is_stage1
    I_eff1  = max(1e-4, ic + G_ece_stage1 + gbar_ece);
    th_2    = (gamma1_self * (max(1e-4, theta_c)^phi1_ces) + gamma1_inv * (I_eff1^phi1_ces) + gamma1_par * (h^phi1_ces)) ^ (1 / phi1_ces);
    u_child = (omega_ic / max(1, n_stage1_steps)) * log(max(1e-4, th_2));
elseif is_stage2
    I_eff2  = max(1e-4, ic + G_ece_stage2 + gbar_ece);
    th_3    = (gamma2_self * (max(1e-4, theta_c)^phi2_ces) + gamma2_inv * (I_eff2^phi2_ces) + gamma2_par * (h^phi2_ces)) ^ (1 / phi2_ces);
    u_child = (omega_ic / max(1, n_stage2_steps)) * log(max(1e-4, th_3));
end

%% 5. END-OF-LIFE WARM-GLOW LUXURY BEQUEST (SCALED BY MORTALITY 1 - sj)
u_beq = 0;
if agej >= Jr
    net_estate = (1 - tau_b) * max(0, aprime);
    u_beq      = (1 - sj) * b1_beq * (((b2_beq + net_estate) ^ (1 - eta_c)) / (1 - eta_c));
end

F = u_flow + u_child + u_beq;


end
