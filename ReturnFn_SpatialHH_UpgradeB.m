function F = ReturnFn_SpatialHH_UpgradeB(ic, l, Ih, aprime, hprime, a, h, theta_c, z, ...
    w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
    Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
    omega_ic, gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_b, agej, Jr, sj)
%% FINITE-HORIZON HOUSEHOLD RETURN FUNCTION WITH UPGRADE B (2-STAGE CHILD EXPERIENCE ASSET)
% Decision variables d:
%   d1 = ic (Parental investment in child: passed to experienceasset ChildCES_aprimeFn!)
%   d2 = l  (Adult labor supply: 0, 0.5, 0.8, 1.0)
%   d3 = Ih (Adult Ben-Porath on-the-job training)
% Endogenous states a:
%   a1 = a       (Standard asset: Consolidated Net Worth Q*H - b)
%   a2 = h       (Standard asset: Adult Ben-Porath Human Capital)
%   a3 = theta_c (Experience asset: Child Developing Skill Stock across Stages 1 & 2!)

F = -Inf;

% 1. ADULT BEN-PORATH HUMAN CAPITAL EVOLUTION (Fan, Seshadri & Taber Source 6)
if agej < Jr
    if l > 0
        h_expected = (1 - delta_hc) * h + (Ih ^ alpha_I) * (h ^ alpha_H);
    else
        if Ih > 0; return; end
        h_expected = (1 - delta_hc) * h;
    end
    if abs(hprime - h_expected) > 0.16
        return;
    end
else
    if l > 0 || Ih > 0 || ic > 0; return; end
    if abs(hprime - h) > 1e-4; return; end
end

% Restrict child investment ic to Stage 1 (j=3: First 2000 Days) and Stage 2 (j=4: Schooling)
if (agej ~= 3 && agej ~= 4) && ic > 0
    return;
end

% 2. REGIONAL HOUSING TENURE & USER COST (Kiyotaki, Michaelides & Nikolov Source 1, Eq 6, 10, 15)
R_ann = (1 + r)^(1/5);
rr_k  = max(0.010, (1 + mu_maint - (G_reg / R_ann)) * Q_reg);
rh_k  = max(0.008, (1 + mu_maint - upsilon_h - (G_reg / R_ann)) * Q_reg);

if agej < Jr
    xi_own = min(1.0, (1 / chi_bar) * (rr_k / rh_k));
    p_housing_eff = xi_own * rh_k + (1 - xi_own) * (rr_k / (0.5 * chi_bar));
else
    p_housing_eff = rh_k;
end

% 3. BUDGET CONSTRAINT WITH LEE & SESHADRI (Source 11, Eq 6-7) TIME + MONEY COST
net_asset_resources = (1 + (1 - tau_k) * r) * a;

if agej < Jr
    grant_E   = (agej == 1) * YouthGrant;
    eff_hours = max(0, l - Ih);
    net_labor = (1 - tau_l) * w_reg * z * h * eff_hours;
    
    % Total expenditure after mandatory spatial energy/transport ebar_energy (Source 2 Eq 1)
    % and subsidized private child investment (1 - s_sub)*ic (Ferriere et al. Source 4)
    total_exp = (net_asset_resources + net_labor + grant_E + Transfer_Geo ...
                 - ebar_energy - (1 - s_sub) * ic - aprime) / (1 + tau_c);
else
    total_exp = max(c_floor, (net_asset_resources + p_super + Transfer_Geo ...
                 - ebar_energy - aprime) / (1 + tau_c));
end

if total_exp <= 0
    return;
end

% 4. PERIOD UTILITY OVER COMPOSITE CONSUMPTION (C + H) AND LABOR DISUTILITY
u_composite = total_exp * (p_housing_eff ^ (phi_nd - 1));
F = ((u_composite ^ (1 - 2.0)) / (1 - 2.0)) - 1.2 * (l^2) / 2;

% 5. TWO-STAGE CHILD SKILL ALTRUISM & DYNAMIC COMPLEMENTARITY REWARD (Sources 5, 9, 11)
if agej == 3
    % Stage 1 (First 2000 Days): Flow warm-glow + parental skill synergy (Lee & Seshadri Eq 7)
    F = F + 0.35 * omega_ic * log(ic + G_ece_stage1 + gbar_ece);
elseif agej == 4
    % Stage 2 (End of Schooling): Parent evaluates completed child skill theta_3!
    % Because phi2_ces = -0.95 < 0, a higher Stage-1 skill stock theta_c (from j=3)
    % strongly raises the marginal return to Stage-2 investment ic!
    I_stage2 = max(0.05, ic + G_ece_stage2 + gbar_ece);
    theta_3_completed = (gamma2_self * (max(0.1, theta_c)^phi2_ces) ...
                       + gamma2_inv  * (I_stage2^phi2_ces) ...
                       + gamma2_par  * (h^phi2_ces)) ^ (1 / phi2_ces);
    
    % Parent's altruistic payoff over completed child human capital (Cao & Li Source 9 Eq 3)
    F = F + omega_ic * log(theta_3_completed);
end

% 6. RETIREMENT LUXURY PROPERTY BEQUESTS (De Nardi / Piketty & Saez Source 16)
if agej >= Jr
    net_estate = (1 - tau_b) * max(0, aprime);
    u_beq = (1 - sj) * b1_beq * ((b2_beq + net_estate)^(1 - 2.0)) / (1 - 2.0);
    F = F + u_beq;
end

end
