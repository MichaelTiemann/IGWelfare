function [tfr_row, diff_row, struggle_row, dep_ratio, req_tax] = eval_super_age_point( ...
    super_age_s, beta_hyp, chi_f_pen, G_ece1_s, G_ece2_s, Q_mult, p_super_s, is_ss2_flag, ...
    Params, Dist_Reg_Cell, w_Reg_Vec, Q_Base_Vec, K_base_vec, base_struggle_vec, sj_ref, Reg_HH_Shares, h_vec, j_fert_vec, base_struggle_mean)

A_base = Params.Super_Age_Base;
if super_age_s >= A_base
    elder_time_mult = exp(-Params.eta_elder_whanau * (super_age_s - A_base));
else
    elder_time_mult = 1.0 + Params.kappa_kuia_max * tanh((A_base - super_age_s) / Params.tau_kuia_sat);
end

if isstruct(Params) && isfield(Params, 'Regions') && ~isempty(Params.Regions)
    Reg_Names = Params.Regions;
else
    Reg_Names = {'Rural', 'Small', 'Large', 'Auckland'};
end
N_reg        = numel(Dist_Reg_Cell);
n_h          = numel(h_vec);
tfr_row      = zeros(1, N_reg);
diff_row     = zeros(1, N_reg);
struggle_row = zeros(1, N_reg);

for r_idx = 1:N_reg
    hh_t       = ['HH_', Reg_Names{r_idx}];
    g1_r       = G_ece1_s.(hh_t);
    g2_r       = G_ece2_s.(hh_t);
    g1_0       = Params.G_ece_stage1.(hh_t);
    g2_0       = Params.G_ece_stage2.(hh_t);
    M_mentor_s = min(1.0, max(0.0, (g2_r - 0.045) / (0.085 - 0.045)));
    M_mentor_0 = min(1.0, max(0.0, (g2_0 - 0.045) / (0.085 - 0.045)));

    Dist_k = Dist_Reg_Cell{r_idx};
    w_k    = w_Reg_Vec(r_idx);
    Q_k    = Q_Base_Vec(r_idx) * Q_mult(r_idx);

    elder_home_mult = min(1.20, max(0.50, (p_super_s / 0.18) * ((1.0 / Q_mult(r_idx)) ^ 0.35)));
    K_eff_r         = K_base_vec(r_idx) * elder_time_mult * elder_home_mult;
    dK_r            = K_eff_r - K_base_vec(r_idx);

    fert_by_h = zeros(n_h, 1);
    mass_by_h = zeros(n_h, 1);

    for jj = j_fert_vec
        for ih = 1:n_h
            m_cell = sum(Dist_k(:, ih, :, :, jj), 'all');
            opp_cost_mother = chi_f_pen * w_k * h_vec(ih) / max(0.50, 1 + 2.5 * g1_r + 0.65 * dK_r);
            housing_drag    = 0.22 * log(max(1.0, Q_k));

            n_opt = (beta_hyp ^ 0.65) * 2.28 / (1 + opp_cost_mother + housing_drag * (Q_k > 1.8));
            n_opt = max(0.85, min(2.60, n_opt));

            fert_by_h(ih) = fert_by_h(ih) + m_cell * n_opt;
            mass_by_h(ih) = mass_by_h(ih) + m_cell;
        end
    end

    avg_fert_h     = fert_by_h ./ max(1e-12, mass_by_h);
    tfr_row(r_idx) = sum(fert_by_h) / max(1e-12, sum(mass_by_h));
    diff_row(r_idx)= mean(avg_fert_h(1:2)) - mean(avg_fert_h(6:7));

    reg_weight         = 0.75 + 0.10 * r_idx;
    ece_relief         = 115.0 * (g1_r - g1_0) * reg_weight ...
        +  18.0 * (M_mentor_s - M_mentor_0) * reg_weight;
    whanau_gain        = 22.5 * max(0.0, dK_r);
    yrs_late_r         = max(0.0, super_age_s - A_base);
    whanau_squeeze_pen = max(0.0, -dK_r) * (22.5 + 2.8 * yrs_late_r);
    hyp_pen            = 6.50 * (1 - beta_hyp) * reg_weight;

    struggle_post_ece   = max(2.2, base_struggle_vec(r_idx) - ece_relief - whanau_gain + hyp_pen);
    struggle_row(r_idx) = min(98.5, struggle_post_ece + whanau_squeeze_pen);
end

nat_TFR    = sum(tfr_row(:) .* Reg_HH_Shares(:));
g_cohort_5 = ((nat_TFR / 1.42) ^ (5.0 / 30.0)) - 1.0;
N_5        = zeros(16, 1);
N_5(1)     = 1.0;
for jj = 1:15
    N_5(jj+1) = N_5(jj) * sj_ref(jj) / (1.0 + g_cohort_5);
end
N_5 = N_5 / sum(N_5);

ret_share_5 = zeros(16, 1);
for jj = 1:16
    age_lo = 20.0 + (jj - 1) * 5.0;
    age_hi = age_lo + 5.0;
    ret_share_5(jj) = min(1.0, max(0.0, (age_hi - super_age_s) / 5.0));
end

ret_65_mass  = sum(N_5(10:16));
wrk_65_mass  = sum(N_5(1:9));
ret_raw_mass = sum(N_5 .* ret_share_5);

if super_age_s > A_base
    yrs_late          = super_age_s - A_base;
    healthy_wrk_share = Params.theta_healthy_wrk_65 * exp(-Params.lambda_health_decay_65 * yrs_late);
    delta_ret_cut     = ret_65_mass - ret_raw_mass;
    fiscal_leak_mult  = Params.phi_geriatric_leak_base + Params.phi_geriatric_leak_slope * yrs_late;
    eff_ret_mass      = ret_65_mass - healthy_wrk_share * delta_ret_cut ...
        + (fiscal_leak_mult - 1.0) * (1.0 - healthy_wrk_share) * delta_ret_cut;
    sandwich_wrk_loss = Params.psi_sandwich_wrk_drag * (1.0 - healthy_wrk_share) * delta_ret_cut;
    eff_wrk_mass      = max(0.15, wrk_65_mass + 0.60 * healthy_wrk_share * delta_ret_cut - sandwich_wrk_loss);
elseif super_age_s < A_base
    yrs_early     = A_base - super_age_s;
    lam_off       = Params.lambda_offset_decay_u65;
    avg_offset    = Params.omega_acc_offset_under65 * (1.0 - exp(-lam_off * yrs_early)) / max(1e-6, lam_off * yrs_early);
    delta_ret_add = ret_raw_mass - ret_65_mass;
    eff_ret_mass  = ret_65_mass + (1.0 - avg_offset) * delta_ret_add;
    peak_earn_wt  = Params.nu_peak_earn_u65 + Params.nu_peak_earn_slope_u65 * yrs_early;
    eff_wrk_mass  = max(0.15, wrk_65_mass - peak_earn_wt * delta_ret_add);
else
    eff_ret_mass  = ret_65_mass;
    eff_wrk_mass  = wrk_65_mass;
end

dep_ratio       = 100.0 * (eff_ret_mass / max(1e-8, eff_wrk_mass));
tau_l_base_pct  = 100.0 * Params.tau_l;
aging_tax_drift = Params.beta_aging_tax_drift * (dep_ratio - Params.Dep_Ratio_Anchor);
struggle_reduction = base_struggle_mean - mean(struggle_row);
exits_skill_div = Params.beta_exits_skill_div * struggle_reduction;

yrs_over_65_s   = max(0.0, super_age_s - A_base);
austerity_drag  = Params.psi_austerity_tax_drag * (yrs_over_65_s ^ 1.35);
ss2_harvest_div = double(is_ss2_flag) * (Params.ss2_harvest_div_base * min(1.05, elder_time_mult) - austerity_drag);

req_tax = tau_l_base_pct + aging_tax_drift - exits_skill_div - ss2_harvest_div;
end
