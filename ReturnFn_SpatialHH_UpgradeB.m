function F = ReturnFn_SpatialHH_UpgradeB(l, Ih, ic, aprime, a, h, theta_c, z, ...
    w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
    Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, s_sub, omega_ic, ...
    b1_beq, b2_beq, YouthGrant, tau_l, tau_c, tau_k, tau_b, agej, Jr, sj)
%% RETURN FUNCTION: 4-REGION HOUSEHOLD WITH TWO EXPERIENCE ASSETS (UPGRADE B)
% File: ReturnFn_SpatialHH_UpgradeB.m
% VFI Toolkit Two-Experience-Asset Architecture (experienceasset = 2, l_dexperienceasset = 2):
%   Action Space (l_d + l_aprime = 3 + 1 = 4):
%     - d      : l (Labor), Ih (Adult Ben-Porath Inv -> a2_1), ic (Child Inv -> a2_2)
%     - aprime : aprime (Next-period Net Worth; h and theta_c have no chosen aprime!)
%   State Space (l_a + l_z = 3 + 1 = 4):
%     - a1     : a (Current Net Worth)
%     - a2     : h (Current Adult Human Capital), theta_c (Current Child Skill Stock)
%     - z      : z (Idiosyncratic Labor Productivity)
%
% Division of Labor with ChildCES_aprimeFn:
%   - ChildCES_aprimeFn evolves BOTH h (whicha=1) and theta_c (whicha=2).
%   - ReturnFn_SpatialHH_UpgradeB purely OBSERVES h and theta_c and accounts for the
%     budget costs of Ih and (1 - s_sub)*ic.

F = -Inf;

%% 1. AGE-DEPENDENT ACTION CONSTRAINTS
if agej >= Jr
    % Mandatory retirement at Jr (Age 65): No labor supply or Ben-Porath training
    if l > 0 || Ih > 0
        return;
    end
end

% Active child investment ic is only chosen during Stage 1 (j = 3) and Stage 2 (j = 4)
is_parenting_stage = (agej == 3) || (agej == 4);
if ~is_parenting_stage && (ic > 0)
    return;
end

%% 2. REGIONAL USER COST OF HOUSING & TENURE CHOICE (Kiyotaki et al. 2024 / Hirano & Toda)
R_ann  = (1 + r)^(1/5);
rr_reg = max(0.010, (1 + mu_maint - (G_reg / R_ann)) * Q_reg);
rh_reg = max(0.008, (1 + mu_maint - upsilon_h - (G_reg / R_ann)) * Q_reg);

is_owner = (a >= 0.15 * Q_reg);
if is_owner
    p_housing = rh_reg;
    upsilon_b = 0.0;
else
    p_housing = rr_reg;
    upsilon_b = 0.04; % Rental utility wedge
end

%% 3. HOUSEHOLD BUDGET CONSTRAINT (5-YEAR MODEL PERIOD)
if agej < Jr
    % Observe current adult human capital experience asset h
    labor_inc   = (1 - tau_l) * w_reg * z * h * l;
    pension_inc = 0.0;
else
    labor_inc   = 0.0;
    pension_inc = p_super; % Universal NZ Superannuation
end

cap_inc    = (1 + (1 - tau_k) * r) * a;
youth_end  = (agej == 1) * YouthGrant;
child_cost = is_parenting_stage * (1 - s_sub) * ic;

% Net resources after saving aprime and paying for human capital investments Ih and child_cost
net_resources = labor_inc + pension_inc + cap_inc + Transfer_Geo + youth_end ...
              - aprime - Ih - child_cost;

% Subtract mandatory regional fuel/transport subsistence ebar_energy (Labrousse & Perdereau)
c_total = (net_resources / (1 + tau_c)) - ebar_energy;
if c_total <= 0
    return;
end

c_nd   = max(c_floor, phi_nd * c_total);
h_size = max(0.05, ((1 - phi_nd) * c_total) / p_housing);

%% 4. WITHIN-PERIOD UTILITY + OBSERVED EXPERIENCE ASSET (theta_c) + WARM-GLOW BEQUESTS
eta_c    = 2.0;
comp_c   = (c_nd ^ phi_nd) * (h_size ^ (1 - phi_nd)) * exp(-upsilon_b) * ((1 - 0.55 * l) ^ 0.35);
u_period = (comp_c ^ (1 - eta_c)) / (1 - eta_c);

% --- OBSERVE CHILD SKILL EXPERIENCE ASSET theta_c ---
u_child_skill = 0.0;
if agej == 3
    u_child_skill = 0.05 * omega_ic * log(max(1e-4, theta_c + G_ece_stage1));
elseif agej == 4
    u_child_skill = 0.05 * omega_ic * log(max(1e-4, theta_c + G_ece_stage2));
elseif agej == 5
    % Child reaches adulthood at j = 5: parent observes completed skill theta_c = theta_3
    u_child_skill = omega_ic * log(max(1e-4, theta_c));
end

% Luxury Warm-Glow Bequest Utility upon death (1 - sj) in retirement (De Nardi 2004)
u_bequest = 0.0;
if (agej >= Jr) && (aprime > 0)
    net_estate = (1 - tau_b) * aprime;
    u_bequest  = (1 - sj) * b1_beq * (((b2_beq + net_estate) ^ (1 - eta_c)) / (1 - eta_c));
end

F = u_period + u_child_skill + u_bequest;

end
