function theta_c_prime = ChildCES_aprimeFn(ic, theta_c, ...
    G_ece_stage1, G_ece_stage2, gbar_ece, ...
    gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
    gamma2_self, gamma2_inv, gamma2_par, phi2_ces, h_par_mean, agej)
%% TWO-STAGE CHILDHOOD CES SKILL PRODUCTION FUNCTION (EXPERIENCE ASSET)
% Implements Cunha, Heckman, & Schennach (2010, Eq 2.3-2.4 & Table V, Source 5)
% and Lee & Seshadri (2019, Eq 5-7, Source 11) inside VFI Toolkit's aprimeFn:
%   - At j = 2 (Ages 25-29, Conception/Birth): Initializes child endowment theta_1
%   - At j = 3 (Ages 30-34, Stage 1: First 1000/2000 Days): High substitutability
%     (phi1_ces > 0) & high investment productivity (gamma1_inv = 0.24)
%   - At j = 4 (Ages 35-39, Stage 2: Schooling): Strong dynamic complementarity
%     (phi2_ces = -0.95 < 0) & high self-productivity (gamma2_self = 0.87)
%   - At j >= 5: Carries completed child adult skill theta_3 forward for evaluation

if agej < 2
    % Pre-fertility young adulthood (Ages 20-24): baseline initial endowment
    theta_c_prime = theta_c;
    
elseif agej == 2
    % Birth / neonatal entry: child starts Stage 1 with initial skill theta_1
    theta_c_prime = max(0.45, theta_c);
    
elseif agej == 3
    % STAGE 1: EARLY CHILDHOOD (First 1000/2000 Days - Barnardos wraparound G_ece_stage1)
    % Effective investment includes private time+goods (ic), public ECE (G_ece_stage1),
    % and Stone-Geary subsistence/luxury shifter gbar_ece (Ferriere et al. Source 4)
    I_stage1 = max(0.05, ic + G_ece_stage1 + gbar_ece);
    
    % CES aggregator with phi1_ces = 0.35 (Elasticity of substitution = 1.54 > 1, Source 5 Table V)
    term_self = gamma1_self * (max(0.1, theta_c) ^ phi1_ces);
    term_inv  = gamma1_inv  * (I_stage1 ^ phi1_ces);
    term_par  = gamma1_par  * (h_par_mean ^ phi1_ces);
    
    theta_c_prime = (term_self + term_inv + term_par) ^ (1 / phi1_ces);
    
elseif agej == 4
    % STAGE 2: LATE CHILDHOOD / SCHOOL YEARS (Dynamic Complementarity phi2_ces = -0.95 < 0)
    % If theta_c coming out of Stage 1 (First 2000 Days) is low (stunted),
    % phi2_ces < 0 severely penalizes the productivity of late investment I_stage2!
    I_stage2 = max(0.05, ic + G_ece_stage2 + gbar_ece);
    
    term_self2 = gamma2_self * (max(0.1, theta_c) ^ phi2_ces);
    term_inv2  = gamma2_inv  * (I_stage2 ^ phi2_ces);
    term_par2  = gamma2_par  * (h_par_mean ^ phi2_ces);
    
    theta_c_prime = (term_self2 + term_inv2 + term_par2) ^ (1 / phi2_ces);
    
else
    % Post-schooling (j >= 5): Completed child skill stock theta_3 is preserved
    theta_c_prime = theta_c;
end

% Bound within experience asset grid limits for stable linear interpolation
theta_c_prime = min(2.20, max(0.40, theta_c_prime));

end
