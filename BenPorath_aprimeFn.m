function hprime = BenPorath_aprimeFn(l, Ih, h, delta_hc, alpha_I, alpha_H, agej, Jr)
%% EXPERIENCE ASSET LAW OF MOTION FOR HUMAN CAPITAL (Fan, Seshadri, & Taber 2022, Eq 6)
% Inputs:
%   d1 = l  (Labor supply choice: 0, 0.5, 0.8, 1.0)
%   d2 = Ih (On-the-job Ben-Porath training time investment)
%   a2 = h  (Current period human capital stock)

if agej < Jr
    if l > 0
        % Working: human capital depreciates by delta_hc and grows via Ben-Porath production
        hprime = (1 - delta_hc) * h + (Ih ^ alpha_I) * (h ^ alpha_H);
    else
        % Non-employment spell: no investment possible, human capital depreciates at rate delta_hc
        % Captures the shadow cost of mid-career time off vs late-career retirement (Source 1, Sec 5.1)
        hprime = (1 - delta_hc) * h;
    end
else
    % Retirement: human capital state remains constant (or is unused)
    hprime = h;
end

end
