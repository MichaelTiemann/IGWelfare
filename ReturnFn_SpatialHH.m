function F = ReturnFn_SpatialHH(l, ic, Ih, aprime, a, h, z, ...
    w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
    Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, s_sub, omega_ic, ...
    b1_beq, b2_beq, YouthGrant, tau_l, tau_c, tau_k, tau_b, agej, Jr, sj)
%% COMPACT 4D RETURN FUNCTION WITH ADULT HC EXPERIENCE ASSET (experienceasset = 1)
% File: ReturnFn_SpatialHH.m
% Action Space (l_d + l_aprime = 3 + 1 = 4):
%   - d      : l (Labor, 4), ic (Child Inv, 7), Ih (Adult Ben-Porath Inv, 3 -> LAST for aprimeFn)
%   - aprime : aprime (Next-period Net Worth; h evolves via AdultHC_aprimeFn!)
% State Space (l_a + l_z = 2 + 1 = 3):
%   - a1     : a (Current Net Worth, 61)
%   - a2     : h (Current Adult Human Capital Experience Asset, 7)
%   - z      : z (Idiosyncratic Labor Productivity, 5)

F = -Inf;

%% 1. AGE-DEPENDENT ACTION CONSTRAINTS
if agej >= Jr
    if l > 0 || Ih > 0
        return;
    end
end

is_parenting_stage = (agej == 3) || (agej == 4);
if ~is_parenting_stage && (ic > 0)
    return;
end

%% 2. REGIONAL USER COST OF HOUSING & TENURE CHOICE
R_ann  = (1 + r)^(1/5);
rr_reg = max(0.010, (1 + mu_maint - (G_reg / R_ann)) * Q_reg);
rh_reg = max(0.008, (1 + mu_maint - upsilon_h - (G_reg / R_ann)) * Q_reg);

is_owner = (a >= 0.15 * Q_reg);
if is_owner
    p_housing = rh_reg;
    upsilon_b = 0.0;
else
    p_housing = rr_reg;
    upsilon_b = 0.04;
end

%% 3. HOUSEHOLD BUDGET CONSTRAINT (OBSERVING ADULT HC h)
if agej < Jr
    labor_inc   = (1 - tau_l) * w_reg * z * h * l;
    pension_inc = 0.0;
else
    labor_inc   = 0.0;
    pension_inc = p_super;
end

cap_inc    = (1 + (1 - tau_k) * r) * a;
youth_end  = (agej == 1) * YouthGrant;
child_cost = is_parenting_stage * (1 - s_sub) * ic;

net_resources = labor_inc + pension_inc + cap_inc + Transfer_Geo + youth_end ...
    - aprime - Ih - child_cost;

c_total = (net_resources / (1 + tau_c)) - ebar_energy;
if c_total <= 0
    return;
end

c_nd   = max(c_floor, phi_nd * c_total);
h_size = max(0.05, ((1 - phi_nd) * c_total) / p_housing);

%% 4. WITHIN-PERIOD UTILITY + WARM-GLOW CHILD INVESTMENT + BEQUESTS
eta_c    = 2.0;
comp_c   = (c_nd ^ phi_nd) * (h_size ^ (1 - phi_nd)) * exp(-upsilon_b) * ((1 - 0.55 * l) ^ 0.35);
u_period = (comp_c ^ (1 - eta_c)) / (1 - eta_c);

u_child = 0.0;
if is_parenting_stage
    u_child = omega_ic * log(max(1e-4, gbar_ece + ic + G_ece));
end

u_bequest = 0.0;
if (agej >= Jr) && (aprime > 0)
    net_estate = (1 - tau_b) * aprime;
    u_bequest  = (1 - sj) * b1_beq * (((b2_beq + net_estate) ^ (1 - eta_c)) / (1 - eta_c));
end

F = u_period + u_child + u_bequest;

end