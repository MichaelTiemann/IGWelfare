function Reform_Phase_Specs = Default_Reform_Phase_Specs(Params_SS0, Enable_SS2_Phase)
%% CANONICAL MULTIPHASE REFORM SPECIFICATION BUILDER (SS1 & SS2)
% File: src/config/Default_Reform_Phase_Specs.m
% Pure Tier-D helper returning the canonical SS1 (and optional SS2) reform structs
% from Params_SS0 without workspace side effects.

if nargin < 2 || isempty(Enable_SS2_Phase)
    Enable_SS2_Phase = false;
end

Regions = Params_SS0.Regions;
N_reg   = numel(Regions);

Reform_Phase_Specs = struct([]);

% --- PHASE 1 (SS1): Barnardos First-2000-Days + Montessori + Wealth/Estate Tax Rebalance ---
Reform_Phase_Specs(1).Code            = 'SS1';
Reform_Phase_Specs(1).Label           = 'B. High-Opportunity Reform + Montessori Mentoring (SS1)';
Reform_Phase_Specs(1).Intensity       = 1.0;
Reform_Phase_Specs(1).G_ece_stage1    = Params_SS0.G_ece1_sched(2);
Reform_Phase_Specs(1).G_ece_stage2    = Params_SS0.G_ece2_sched(2);
Reform_Phase_Specs(1).G_ece           = Params_SS0.G_ece1_sched(2);
Reform_Phase_Specs(1).YouthGrant      = Params_SS0.YouthGrant_sched(2);
Reform_Phase_Specs(1).tau_a           = Params_SS0.tau_a;
Reform_Phase_Specs(1).tau_b           = 0.180;
Reform_Phase_Specs(1).tau_l_delta     = 0.000;
Reform_Phase_Specs(1).r_delta         = -0.004;
Reform_Phase_Specs(1).w_mult_vs_SS0   = Params_SS0.w_mult_SS1;
Reform_Phase_Specs(1).Q_mult_vs_SS0   = Params_SS0.Q_mult_SS1;
Reform_Phase_Specs(1).Frac_struggling = 0.045;
Reform_Phase_Specs(1).S_cohesion      = 112.0;

t1_mult_def = [1.52, 1.55, 1.5625, 2.00];
t_geo_ss1   = struct();
for r_tg = 1:N_reg
    hk_tg = ['HH_', Regions{r_tg}];
    m_tg  = t1_mult_def(min(r_tg, numel(t1_mult_def)));
    t_geo_ss1.(hk_tg) = round(Params_SS0.Transfer_Geo.(hk_tg) * m_tg, 4);
end
Reform_Phase_Specs(1).Transfer_Geo = t_geo_ss1;
Reform_Phase_Specs(1).super_age    = Params_SS0.Super_Age_SS1;

if Enable_SS2_Phase
    % --- PHASE 2 (SS2): 2050 Actuarial Liability Release, Debt-Sinking & PAYE Tax-Relief Harvest ---
    Reform_Phase_Specs(2).Code            = 'SS2';
    Reform_Phase_Specs(2).Label           = 'C. 2050 Actuarial Dividend & PAYE Tax-Relief Harvest (SS2)';
    Reform_Phase_Specs(2).Intensity       = 1.30;
    Reform_Phase_Specs(2).G_ece_stage1    = Params_SS0.G_ece1_sched(3);
    Reform_Phase_Specs(2).G_ece_stage2    = Params_SS0.G_ece2_sched(3);
    Reform_Phase_Specs(2).G_ece           = Params_SS0.G_ece1_sched(3);
    Reform_Phase_Specs(2).YouthGrant      = Params_SS0.YouthGrant_sched(3);
    Reform_Phase_Specs(2).tau_a           = Params_SS0.tau_a;
    Reform_Phase_Specs(2).tau_b           = 0.180;
    Reform_Phase_Specs(2).r_delta         = -0.006;
    Reform_Phase_Specs(2).w_mult_vs_SS0   = Params_SS0.w_mult_SS2;
    Reform_Phase_Specs(2).Q_mult_vs_SS0   = Params_SS0.Q_mult_SS2;
    Reform_Phase_Specs(2).Frac_struggling = 0.015;
    Reform_Phase_Specs(2).S_cohesion      = 126.0;

    psi_ret = Params_SS0.psi_retire_T;
    T0_vec  = cellfun(@(r) Params_SS0.Transfer_Geo.(['HH_', r]), Regions);
    T1_vec  = cellfun(@(r) Reform_Phase_Specs(1).Transfer_Geo.(['HH_', r]), Regions);
    T2_vec  = max(Params_SS0.T_reg_min_floor(1:N_reg), T0_vec + (1.0 - psi_ret) * (T1_vec - T0_vec));

    t_geo_ss2 = struct();
    for r_tg = 1:N_reg
        t_geo_ss2.(['HH_', Regions{r_tg}]) = T2_vec(r_tg);
    end
    Reform_Phase_Specs(2).Transfer_Geo = t_geo_ss2;
    Reform_Phase_Specs(2).super_age    = Params_SS0.Super_Age_SS2;

    if isfield(Params_SS0, 'tau_l_delta_SS2') && ~isempty(Params_SS0.tau_l_delta_SS2) && isfinite(Params_SS0.tau_l_delta_SS2)
        % Synchronize directly with Compute_FiscalSolvency_And_Fertility when Step 3 has evaluated exact SS2 solvency:
        Reform_Phase_Specs(2).tau_l_delta = Params_SS0.tau_l_delta_SS2;
    else
        sa2 = Reform_Phase_Specs(2).super_age;
        if sa2 < 65.0
            super_tax_cost = 0.0030 * (65.0 - sa2) + 0.00085 * ((65.0 - sa2) ^ 2);
        else
            super_tax_cost = 0.0028 * ((sa2 - 65.0) ^ 1.30);
        end
        transfer_retire_tax_div           = 0.0075 * psi_ret;
        Reform_Phase_Specs(2).tau_l_delta = -0.0350 - transfer_retire_tax_div + super_tax_cost;
    end
end

end
