function thetac_prime = HumanCapital_Lifecycle_aprimeFn(i_c, thetac, agej, ...
    phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
    phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, ...
    gbar_ece, h_parent_ref, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
    Q_reg, Q_base_reg, K_whanau_base, Jr, dt)
% HUMANCAPITAL_LIFECYCLE_APRIMEFN
% Parameterized Two-Stage CES Law of Motion for Child Skill (theta_c) with:
%   1. Kaiako Housing-Affordability Supply Deflator: (Q_base_reg / Q_reg)^nu_kaiako
%   2. Stage-2 Unbanked Gain Fade-Out & Bidirectional Mentoring (M_mentor)
%   3. Non-Fungible Whanau Trust Gating & Sandwich-Generation Eldercare Reversal
%      at the i_c < 0.01 distress corner when the NZ Super age is raised.
%

thetac_safe = max(thetac, 1e-4);
hp_safe     = max(h_parent_ref, 1e-4);

% 1. KAIAKO & SPECIALIST WORKFORCE HOUSING-AFFORDABILITY SUPPLY DEFLATOR:
%    High metropolitan house prices Q_reg relative to baseline price out early
%    childhood educators (Kaiako) and speech therapists; cooling Q_reg in SS1/SS2
%    endogenously expands real wraparound staffing capacity per nominal Crown dollar:
nu_kaiako   = 0.35;
kaiako_mult = (max(0.50, Q_base_reg) / max(0.50, Q_reg)) ^ nu_kaiako;

% 2. ACTIVE MONTESSORI / TUAKANA-TEINA / GRAEME DINGLE MENTORING INTENSITY:
G_ece2_real = G_ece_stage2 * kaiako_mult;
M_mentor    = min(1.0, max(0.0, (G_ece2_real - 0.045) / (0.085 - 0.045)));

% 3. SANDWICH-GENERATION ELDERCARE REVERSAL & WHANAU TRUST GATING:
%    Check if NZ Super vesting age has been pushed past Age 65 (20 + (Jr-1)*dt > 65):
super_age_yrs    = 20 + (Jr - 1) * dt;
is_super_cut     = double(super_age_yrs > 65.5);
is_corner_stress = double(i_c < 0.01);

% When distressed families (i_c < 0.01) lose grandparent retirement security
% (Super age > 65), extended whanau care K_whanau flips negative into an upward
% sandwich-generation care and financial drain (-psi_sandwich = -0.28):
psi_sandwich = 0.28;
K_whanau_net    = K_whanau_base * (1.0 - 0.362 * is_super_cut) ...
    - psi_sandwich * is_super_cut * is_corner_stress;
K_whanau_pos    = max(0.0, K_whanau_net);

if (agej >= j_s1_start) && (agej <= j_s1_end)
    % =====================================================================
    % STAGE 1: FIRST 2000 DAYS (Ages 0-5)
    % High substitutability: phi1_ces = 0.35 > 0
    % Includes Kaiako supply multiplier + downward Tuakana mentoring boost
    % =====================================================================
    kappa_down     = 0.15;
    G_ece1_eff     = (G_ece_stage1 * kaiako_mult) * (1.0 + kappa_down * M_mentor) ...
        + 0.025 * K_whanau_pos;
    inv_tot1       = max(i_c + G_ece1_eff + gbar_ece, 1e-4);
    inside1        = gamma1_self * (thetac_safe ^ phi1_ces) ...
        + gamma1_inv  * (inv_tot1    ^ phi1_ces) ...
        + gamma1_par  * (hp_safe     ^ phi1_ces);
    thetac_target1 = inside1 ^ (1.0 / phi1_ces);

    w1 = 1.0 / max(1.0, n_stage1_steps);
    thetac_prime = (1.0 - w1) * thetac_safe + w1 * thetac_target1;

elseif (agej >= j_s2_start) && (agej <= j_s2_end)
    % =====================================================================
    % STAGE 2: SCHOOL YEARS & ADOLESCENCE (Ages 6-17, Gate 2 at Ages 12-14)
    % Strong dynamic complementarity: phi2_ces = -0.95 < 0
    % =====================================================================
    w2 = 1.0 / max(1.0, n_stage2_steps);

    % Non-fungible Whanau Trust Gating: trusted whanau stability (K_whanau_pos)
    % bridges vulnerable youth into school-based Tuakana-Teina mentoring:
    M_trust_gated = M_mentor * (0.45 + 0.55 * min(1.0, K_whanau_pos / 0.35));

    % 1. EXPLICIT UNBANKED SKILL GAIN FADE-OUT (Bailey et al. 2017):
    delta_theta_fade = 0.22 * w2;
    theta_base       = 0.65;
    thetac_retained  = max(1e-4, thetac_safe - delta_theta_fade * (1.0 - M_trust_gated) * max(0.0, thetac_safe - theta_base));

    % 2. STAGE-2 CES SKILL PRODUCTION (Harmonic-Mean Bottleneck phi2_ces = -0.95 < 0):
    inv_tot2    = max(i_c + G_ece2_real + gbar_ece + 0.020 * K_whanau_pos, 1e-4);
    inside2     = gamma2_self * (thetac_retained ^ phi2_ces) ...
        + gamma2_inv  * (inv_tot2        ^ phi2_ces) ...
        + gamma2_par  * (hp_safe         ^ phi2_ces);
    thetac_ces2 = inside2 ^ (1.0 / phi2_ces);

    % 3. ADOLESCENT FAMILY-STRESS EROSION VS. TRUST-GATED MENTORING & SANDWICH DRAIN:
    %    Notice that if K_whanau_net < 0 (upward eldercare reversal under Super > 65),
    %    (1 - 0.55 * K_whanau_net) > 1, amplifying adolescent corner stress!
    unbuffered_mult = (1.0 - 0.55 * K_whanau_net) * (1.0 - 0.80 * M_trust_gated);
    psi_unemp_step  = 0.045 * is_corner_stress * max(0.0, unbuffered_mult);
    kappa_up_step   = 0.035 * M_trust_gated;
    Psi_adolescent  = -psi_unemp_step + kappa_up_step;

    thetac_target2 = thetac_ces2 * exp(Psi_adolescent);
    thetac_prime   = (1.0 - w2) * thetac_retained + w2 * thetac_target2;
else
    % Outside active childhood investment windows: skill stock is preserved
    thetac_prime = thetac;
end


end
