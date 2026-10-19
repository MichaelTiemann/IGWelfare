function theta_c_prime = HumanCapital_Lifecycle_aprimeFn(ic, theta_c, ...
    G_ece_stage1, G_ece_stage2, gbar_ece, ...
    gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
    gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
    delta_hc, alpha_I, alpha_H, h_par_mean, Ih_mean, agej, Jr, dt, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps)
%% HUMANCAPITAL_LIFECYCLE_APRIMEFN
% VFI Toolkit experienceasset=1 compliant signature:
%   Arg 1: ic      (Experience asset decision d_end)
%   Arg 2: theta_c (Experience asset state a_end)
%   Arg 3+: Scalar parameters from Params struct

scale_dt = dt / 5;
th_safe  = max(1e-4, theta_c);
hp_safe  = max(1e-4, h_par_mean);

if (agej >= j_s1_start) && (agej <= j_s1_end)
    % --- PHASE 2: STAGE 1 CHILDHOOD (FIRST 2000 DAYS, AGES 0-5, phi1 = 0.35) ---
    I_eff1     = 0.55 + 2.50 * max(1e-4, ic + G_ece_stage1 + gbar_ece);
    ces_inner1 = gamma1_self * (th_safe ^ phi1_ces) ...
        + gamma1_inv  * (I_eff1  ^ phi1_ces) ...
        + gamma1_par  * (hp_safe ^ phi1_ces);
    th_target1 = ces_inner1 ^ (1 / phi1_ces);
    w_s1       = 1 / max(1, n_stage1_steps);
    theta_c_prime = (1 - w_s1) * th_safe + w_s1 * th_target1;

elseif (agej >= j_s2_start) && (agej <= j_s2_end)
    % --- PHASE 3: STAGE 2 CHILDHOOD (SCHOOLING, AGES 6-17, phi2 = -0.95) ---
    I_eff2     = 0.55 + 2.50 * max(1e-4, ic + G_ece_stage2 + gbar_ece);
    ces_inner2 = gamma2_self * (th_safe ^ phi2_ces) ...
        + gamma2_inv  * (I_eff2  ^ phi2_ces) ...
        + gamma2_par  * (hp_safe ^ phi2_ces);
    th_target2 = ces_inner2 ^ (1 / phi2_ces);
    w_s2       = 1 / max(1, n_stage2_steps);
    theta_c_prime = (1 - w_s2) * th_safe + w_s2 * th_target2;

elseif agej < j_s1_start
    % --- PHASE 1: PRE-FERTILITY YOUNG ADULTHOOD (AGES 20-29) ---
    % Preserve initial child endowment draw prior to childbirth at j_s1_start
    theta_c_prime = th_safe;

elseif agej < Jr
    % --- PHASE 4: MATURE WORKING CAREER (AGES 40-64) ---
    theta_c_prime = (1 - delta_hc) * th_safe + 0.14 * scale_dt * (max(0, Ih_mean) ^ alpha_I) * (th_safe ^ alpha_H);

else
    % --- PHASE 5: RETIREMENT (AGES 65+) ---
    theta_c_prime = (1 - 0.5 * delta_hc) * th_safe;
end


end
