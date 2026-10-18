function a2prime = ChildCES_aprimeFn(Ih, ic, h, theta_c, whicha, ...
    delta_hc, alpha_I, alpha_H, ...
    G_ece_stage1, G_ece_stage2, gbar_ece, ...
    gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
    gamma2_self, gamma2_inv, gamma2_par, phi2_ces, agej, Jr)
%% DUAL EXPERIENCE ASSET LAW OF MOTION (vfoptions.experienceasset = 2, l_dexperienceasset = 2)
% File: ChildCES_aprimeFn.m
% Leading inputs passed by CreateExperienceAssetFnMatrix when l_a2 == 2 and l_d2 == 2:
%   - d2     : Ih (Adult Ben-Porath investment), ic (Private child investment)
%   - a2     : h  (Adult Human Capital, a2_1),   theta_c (Child Skill Stock, a2_2)
%   - whicha : Integer selector (1 = evolve Adult HC h', 2 = evolve Child Skill theta_c')
%
% Bonus of l_a2 == 2: Because parent's actual human capital h (a2_1) is passed directly
% into aprimeFn alongside theta_c (a2_2), the Cunha-Heckman-Schennach CES technology
% uses the parent's true individual human capital h rather than a scalar average!

if whicha == 1
    %% EXPERIENCE ASSET 1: ADULT BEN-PORATH HUMAN CAPITAL (h -> hprime)
    A_bp = 0.14; % 5-year Ben-Porath TFP scale factor (keeps life-cycle h growth at ~3-5% per 5-yr bin)
    if agej < Jr
        a2prime = (1 - delta_hc) * h + A_bp * (Ih ^ alpha_I) * (h ^ alpha_H);
    else
        a2prime = (1 - delta_hc) * h;
    end

else
    %% EXPERIENCE ASSET 2: TWO-STAGE CUNHA-HECKMAN-SCHENNACH CHILD SKILL (theta_c -> theta_c_prime)
    psi_inv = 3.6; % Calibrated so NZ child stunting is ~24% Rural, ~18% Small, ~14% Large, ~11% Auckland
    if agej == 3
        % Stage 1 (Ages 0-5 / First 2000 Days): High substitutability (phi1_ces > 0)
        I_stage1 = psi_inv * max(0.04, ic + G_ece_stage1 + gbar_ece);
        a2prime  = ( gamma1_self * (theta_c  ^ phi1_ces) ...
            + gamma1_inv  * (I_stage1 ^ phi1_ces) ...
            + gamma1_par  * (h        ^ phi1_ces) ) ^ (1 / phi1_ces);

    elseif agej == 4
        % Stage 2 (Ages 6-17 / School-Age): Strong dynamic complementarity (phi2_ces < 0)
        I_stage2 = psi_inv * max(0.04, ic + G_ece_stage2 + gbar_ece);
        a2prime  = ( gamma2_self * (theta_c  ^ phi2_ces) ...
            + gamma2_inv  * (I_stage2 ^ phi2_ces) ...
            + gamma2_par  * (h        ^ phi2_ces) ) ^ (1 / phi2_ces);

    else
        % Pre-parenting (j = 1, 2) and post-childhood (j >= 5): preserve state
        a2prime  = theta_c;
    end
end


end
