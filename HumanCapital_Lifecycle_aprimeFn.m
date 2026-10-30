function thetac_prime = HumanCapital_Lifecycle_aprimeFn(i_c, thetac, age_j, ...
    phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
    phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, ...
    gbar_ece, h_parent_ref, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps)
% HUMANCAPITAL_LIFECYCLE_APRIMEFN
% Parameterized Two-Stage CES Law of Motion for Child Skill (theta_c) with
% Explicit Stage-2 Unbanked Gain Fade-Out and Bidirectional Mentoring
% (M_mentor: Montessori / Tuakana-Teina / Graeme Dingle Stars & Project K).
%
% Compatible with VFI Toolkit vfoptions.experienceasset = 1 on GPU.
% Supports arbitrary period length dt via stage bounds [j_s1_start, j_s1_end]
% and [j_s2_start, j_s2_end] with sub-period step weights 1/n_stage1_steps, 1/n_stage2_steps.

thetac_safe = max(thetac, 1e-4);
hp_safe     = max(h_parent_ref, 1e-4);

% Infer active Montessori / Tuakana-Teina / Graeme Dingle mentoring intensity
% M_mentor in [0, 1] from Stage-2 public wraparound G_ece_stage2 relative to
% status quo baseline (0.045) vs. high-opportunity reform (0.085 to 0.105):
M_mentor = min(1.0, max(0.0, (G_ece_stage2 - 0.045) / (0.085 - 0.045)));

if (age_j >= j_s1_start) && (age_j <= j_s1_end)
    % =====================================================================
    % STAGE 1: FIRST 2000 DAYS (Ages 0-5, e.g. 0-2 First 1000 Days & 3-5 ECE)
    % High substitutability: phi1_ces = 0.35 > 0
    % Includes downward cross-age mentoring multiplier (kappa_down = 0.15)
    % when older Tuakana / adolescent mentors scaffold younger Teina!
    % =====================================================================
    kappa_down    = 0.15;
    G_ece1_eff    = G_ece_stage1 * (1.0 + kappa_down * M_mentor);
    inv_tot1      = max(i_c + G_ece1_eff + gbar_ece, 1e-4);
    
    inside1       = gamma1_self * (thetac_safe ^ phi1_ces) ...
                  + gamma1_inv  * (inv_tot1    ^ phi1_ces) ...
                  + gamma1_par  * (hp_safe     ^ phi1_ces);
    thetac_target1 = inside1 ^ (1.0 / phi1_ces);
    
    w1 = 1.0 / max(1.0, n_stage1_steps);
    thetac_prime = (1.0 - w1) * thetac_safe + w1 * thetac_target1;

elseif (age_j >= j_s2_start) && (age_j <= j_s2_end)
    % =====================================================================
    % STAGE 2: SCHOOL YEARS & ADOLESCENCE (Ages 6-17, Gate 2 at Ages 12-14)
    % Strong dynamic complementarity: phi2_ces = -0.95 < 0
    % Explicit Fade-Out of Unbanked Early Gains When M_mentor == 0
    % =====================================================================
    w2 = 1.0 / max(1.0, n_stage2_steps);
    
    % 1. EXPLICIT UNBANKED SKILL GAIN FADE-OUT (Bailey et al. 2017; Cunha et al. 2010):
    %    Just as adult human capital h depreciates by delta_hc during non-work (l == 0),
    %    early Stage-1 skill gains above the baseline endowment (theta_base = 0.65)
    %    erode at rate delta_theta_fade = 0.22 across Stage 2 when adolescent
    %    Tuakana-Teina / Montessori mentoring wraparound is absent (M_mentor = 0):
    delta_theta_fade  = 0.22 * w2;
    theta_base        = 0.65;
    thetac_retained   = max(1e-4, thetac_safe - delta_theta_fade * (1.0 - M_mentor) * max(0.0, thetac_safe - theta_base));
    
    % 2. STAGE-2 CES SKILL PRODUCTION (Harmonic-Mean Bottleneck phi2_ces = -0.95 < 0):
    inv_tot2 = max(i_c + G_ece_stage2 + gbar_ece, 1e-4);
    inside2  = gamma2_self * (thetac_retained ^ phi2_ces) ...
             + gamma2_inv  * (inv_tot2        ^ phi2_ces) ...
             + gamma2_par  * (hp_safe         ^ phi2_ces);
    thetac_ces2 = inside2 ^ (1.0 / phi2_ces);
    
    % 3. ADOLESCENT FAMILY-STRESS EROSION VS. MENTORING "GAIN-BANKING" BUFFER (Psi_{J=5}):
    %    When a household is forced to the private investment corner (i_c < 0.01,
    %    capturing parental unemployment/housing distress z_p in Z_distress),
    %    unbuffered stress erodes adolescent non-cognitive skill (-psi_unemp),
    %    whereas active mentoring (M_mentor > 0) buffers 80% of the shock and
    %    confers the upward protege/leadership boost (+kappa_up * M_mentor):
    is_corner_stress = double(i_c < 0.01);
    psi_unemp_step   = 0.045 * is_corner_stress * (1.0 - 0.80 * M_mentor);
    kappa_up_step    = 0.035 * M_mentor;
    Psi_adolescent   = -psi_unemp_step + kappa_up_step;
    
    thetac_target2 = thetac_ces2 * exp(Psi_adolescent);
    thetac_prime   = (1.0 - w2) * thetac_retained + w2 * thetac_target2;

else
    % Outside active childhood investment windows: skill stock is preserved
    thetac_prime = thetac;
end

end
