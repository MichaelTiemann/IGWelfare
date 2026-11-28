function test_teacher_wage_intensity_ledger()
% TEST_TEACHER_WAGE_INTENSITY_LEDGER
% Verifies [2B-Spec-Edu1] & [2A-Prop-Factor2] pure post-hoc decomposition of
% standardized national teacher salaries, high-COL allowances, Q_k overhead
% absorption, and real instructional FTE across NZ_Dunedin1972 and FI_FBC1987.

    T_NZ = Compute_Teacher_Wage_Intensity_Ledger('NZ_Dunedin1972', false);
    T_FI = Compute_Teacher_Wage_Intensity_Ledger('FI_FBC1987', false);

    % 1. Exact accounting conservation: Direct Salary + Site/Turnover Overhead == Gross Spend
    err_nz = max(max(abs((T_NZ.Salary_Tot_kNZD + T_NZ.Ovh_Tot_kNZD) - T_NZ.Spend_Tot_kNZD)));
    err_fi = max(max(abs((T_FI.Salary_Tot_kNZD + T_FI.Ovh_Tot_kNZD) - T_FI.Spend_Tot_kNZD)));
    assert(err_nz < 1e-12 && err_fi < 1e-12, ...
        'Salary bill plus overhead must equal gross per-child education outlay to machine precision.');

    % 2. Standardized national salary scale with bounded (< 8%) metropolitan COL stipend
    akl_prem_pct = 100.0 * (T_NZ.W_Teach_kNZD(4, 1) / T_NZ.W_Teach_kNZD(1, 1) - 1.0);
    assert(akl_prem_pct > 2.0 && akl_prem_pct < 8.0, ...
        'Auckland teacher salary stipend over Rural must reflect bounded COL relief (2% to 8%).');

    % 3. Primate-city Q_k attenuation in SS0: Auckland loses more real FTE per dollar than Rural,
    %    and NZ's Rural-to-Auckland FTE dispersion exceeds Finland's Rural-to-Helsinki dispersion
    assert(T_NZ.FTE_Tot_Per100(4, 1) < T_NZ.FTE_Tot_Per100(1, 1), ...
        'High Q_Auckland (3.10) must compress SS0 real FTE per 100 children below Rural.');
    nz_fte_ratio = T_NZ.FTE_Tot_Per100(4, 1) / T_NZ.FTE_Tot_Per100(1, 1);
    fi_fte_ratio = T_FI.FTE_Tot_Per100(4, 1) / T_FI.FTE_Tot_Per100(1, 1);
    assert(nz_fte_ratio < fi_fte_ratio, ...
        'Auckland SS0 FTE compression relative to Rural must be sharper than Helsinki vs Rural.');

    % 4. Cooling Q_Auckland in SS2 (-10.5%) endogenously improves Kaiako supply deflator
    assert(T_NZ.Kaiako_Defl(4, 3) > T_NZ.Kaiako_Defl(4, 1), ...
        'SS2 land-value cooling (Q_mult_SS2 = 0.895) must lift Auckland Kaiako supply deflator.');

    fprintf('[PASS] test_teacher_wage_intensity_ledger\n');
end