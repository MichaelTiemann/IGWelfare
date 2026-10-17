function F = ReturnFn_Household(l, Ih, ic, aprime, hprime, a, h, z, ...
    w, r, p_super, c_floor, G_ece, gbar_ece, s_sub, omega_ic, Ext_child, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_b, eta_c, psi_l, agej, Jr, sj)
%% FINITE-HORIZON HOUSEHOLD RETURN FUNCTION (LENSES 1, 2, AND 3)

F = -Inf;

% 1. BEN-PORATH HUMAN CAPITAL LAW OF MOTION (Fan, Seshadri, Taber Source 3, Eq 6 & 24)
if agej < Jr
    if l > 0
        % Working: human capital evolves via on-the-job investment Ih
        h_expected = (1 - delta_hc) * h + (Ih^alpha_I) * (h^alpha_H);
    else
        % Non-employment: human capital depreciates at rate delta_hc, Ih must be 0
        if Ih > 0; return; end
        h_expected = (1 - delta_hc) * h;
    end
    % Restrict hprime to nearest grid point tolerance
    if abs(hprime - h_expected) > 0.15
        return;
    end
else
    % Retirement: no work, no training, no child investment
    if l > 0 || Ih > 0 || ic > 0; return; end
    if abs(hprime - h) > 1e-4; return; end
end

% 2. BUDGET CONSTRAINT (Aiyagari + Ferriere et al. Source 1 + Piketty/Saez Source 9)
net_asset_return = (1 + (1 - tau_k) * r) * a;

if agej < Jr
    % Restrict private child investment ic to fertile parenting periods (j=3,4)
    if (agej ~= 3 && agej ~= 4) && ic > 0
        return;
    end
    
    % Universal youth grant E at start of economic life (j=1, Source 9)
    grant_E = (agej == 1) * YouthGrant;
    
    % Measured wage is H_t * (1 - I_t) (Source 3, Eq 24)
    effective_hours = max(0, l - Ih);
    net_labor_inc   = (1 - tau_l) * w * z * h * effective_hours;
    
    % Consumption net of subsidized child investment (Source 1) and GST (tau_c)
    c = (net_asset_return + net_labor_inc + grant_E - (1 - s_sub) * ic - aprime) / (1 + tau_c);
else
    % Retirement: NZ Superannuation + asset decumulation + consumption floor (Source 3)
    c = max(c_floor, (net_asset_return + p_super - aprime) / (1 + tau_c));
end

if c <= 0
    return;
end

% 3. PERIOD UTILITY: CONSUMPTION, LABOR, STONE-GEARY CHILD QUALITY, & BEQUESTS
u_c = (c^(1 - eta_c)) / (1 - eta_c);
u_l = psi_l * (l^2) / 2;
F   = u_c - u_l + Ext_child; % Includes pro-equality externality X_t (Source 1)

% Lens 1 & 2: Stone-Geary Altruistic / In-Kind Child Skill Formation (Sources 1, 8)
if agej == 3 || agej == 4
    F = F + omega_ic * log(ic + G_ece + gbar_ece);
end

% Lens 3: Warm-Glow Net-of-Tax Bequest Motive upon Mortality Risk (Sources 3, 9)
if agej >= Jr
    net_beq = (1 - tau_b) * max(0, aprime);
    u_beq   = (1 - sj) * b1_beq * ((b2_beq + net_beq)^(1 - eta_c)) / (1 - eta_c);
    F       = F + u_beq;
end

end
