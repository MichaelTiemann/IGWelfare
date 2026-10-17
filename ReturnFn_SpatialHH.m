function F = ReturnFn_SpatialHH(l, Ih, ic, aprime, hprime, a, h, z, ...
    w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
    Transfer_Geo, p_super, c_floor, G_ece, gbar_ece, omega_ic, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_b, agej, Jr, sj)
%% FINITE-HORIZON HOUSEHOLD WITH REGIONAL HOUSING, TENURE CHOICE & BEQUESTS

F = -Inf;

% 1. HUMAN CAPITAL EVOLUTION (Ben-Porath, Source 11)
if agej < Jr
    if l > 0
        h_expected = (1 - delta_hc) * h + (Ih^alpha_I) * (h^alpha_H);
    else
        if Ih > 0; return; end
        h_expected = (1 - delta_hc) * h;
    end
    if abs(hprime - h_expected) > 0.18; return; end
else
    if l > 0 || Ih > 0 || ic > 0; return; end
    if abs(hprime - h) > 1e-4; return; end
end

% 2. REGIONAL HOUSING FUNDAMENTALS & TENURE CHOICE (Kiyotaki et al. Source 1, Eq 2, 6, 9, 14)
% Annualized gross interest rate R_ann from 5-yr rate r
R_ann = (1 + r)^(1/5);

% Regional rental price rr(k) and homeowner user cost rh(k) driven by regional growth G_reg
rr_k = max(0.01, (1 + mu_maint - (G_reg / R_ann)) * Q_reg);
rh_k = max(0.008, (1 + mu_maint - upsilon_h - (G_reg / R_ann)) * Q_reg);

% Young households (agej < Jr) choose Renter vs Leveraged Owner via cutoff xi_k (Eq 14);
% Old households (agej >= Jr) all prefer to own (chi_o = 0, Source 1 Sec 2.1)
if agej < Jr
    xi_own = min(1.0, (1 / chi_bar) * (rr_k / rh_k));
    % Composite housing price index across young owners and renters
    p_housing_eff = xi_own * rh_k + (1 - xi_own) * (rr_k / (0.5 * chi_bar));
else
    xi_own = 1.0;
    p_housing_eff = rh_k;
end

% 3. CONSOLIDATED NET WORTH BUDGET CONSTRAINT (Sources 1, 2, 7, 9)
% Net worth a includes home equity + landlord rental equity (for old)
net_asset_resources = (1 + (1 - tau_k) * r) * a;

if agej < Jr
    if (agej ~= 3 && agej ~= 4) && ic > 0; return; end
    grant_E = (agej == 1) * YouthGrant;
    eff_hours = max(0, l - Ih);
    net_labor = (1 - tau_l) * w_reg * z * h * eff_hours;
    
    % Total expenditure after subsistence rural/urban transport & energy cost ebar_energy (Source 2)
    total_exp = (net_asset_resources + net_labor + grant_E + Transfer_Geo ...
                 - ebar_energy - ic - aprime) / (1 + tau_c);
else
    % Retirees: NZ Super + Landlord/Home Equity Net Worth - Subsistence Energy
    total_exp = max(c_floor, (net_asset_resources + p_super + Transfer_Geo ...
                 - ebar_energy - aprime) / (1 + tau_c));
end

if total_exp <= 0
    return;
end

% 4. INTRA-PERIOD COBB-DOUGLAS SPLIT: NONDURABLE C vs HOUSING H (Kiyotaki et al. Source 1)
% Indirect utility from total expenditure given local housing user cost / rent:
u_composite = total_exp * (p_housing_eff^(phi_nd - 1));
F = ((u_composite^(1 - 2.0)) / (1 - 2.0)) - 1.2 * (l^2) / 2;

% 5. LENS 1: EARLY CHILDHOOD INVESTMENT (Constrained by high Urban housing costs!)
if agej == 3 || agej == 4
    F = F + omega_ic * log(ic + G_ece + gbar_ece);
end

% 6. LENS 3: THE $1.6T PROPERTY WEALTH BEQUEST (De Nardi Source 9 + Piketty/Saez Source 7)
if agej >= Jr
    % Older homeowners hold housing equity (Ho + Hr)*Q_reg inside net worth aprime
    net_estate = (1 - tau_b) * max(0, aprime);
    u_beq = (1 - sj) * b1_beq * ((b2_beq + net_estate)^(1 - 2.0)) / (1 - 2.0);
    F = F + u_beq;
end

end
