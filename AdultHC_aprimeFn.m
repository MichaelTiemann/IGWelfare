function hprime = AdultHC_aprimeFn(Ih, h, delta_hc, alpha_I, alpha_H, agej, Jr)
%% SINGLE EXPERIENCE ASSET LAW OF MOTION FOR COMPACT 4D SPACE (experienceasset = 1)
% File: AdultHC_aprimeFn.m
% Evolves Adult Ben-Porath Human Capital h -> hprime using decision Ih (last in n_d).

if agej < Jr
    hprime = (1 - delta_hc) * h + (Ih ^ alpha_I) * (h ^ alpha_H);
else
    hprime = (1 - delta_hc) * h;
end

end
