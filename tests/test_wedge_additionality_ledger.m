function test_wedge_additionality_ledger()
% TEST_WEDGE_ADDITIONALITY_LEDGER
% Verifies Hulten Leverage Ratios and NZ vs. FI_FBC1987 conversion invariants
% documented in Propositions [2B-Prop-Wedge1], [2A-Prop-Civic1], & [2A-Prop-Factor2].

    here = fileparts(mfilename('fullpath'));
    T_NZ = Compute_Wedge_Additionality_Table('NZ_Dunedin1972', false, fullfile(here, 'output', 'NZ_Dunedin1972'));
    T_FI = Compute_Wedge_Additionality_Table('FI_FBC1987',    false, fullfile(here, 'output', 'FI_FBC1987'));

    % 1. Super-unitary Civic/Volunteer seed leverage (> 20x) vs passive transfer (< 0.5x)
    assert(T_NZ.Lambda_Y(7) > 20.0 && T_FI.Lambda_Y(7) > 20.0, ...
        'Civic seed leverage must exceed 20x across both twins.');
    assert(T_NZ.Lambda_Y(5) < 0.50 && T_FI.Lambda_Y(5) < 0.50, ...
        'Passive geographic transfer (vs Yr0 outlay) must exhibit < 0.5x SS2 leverage.');

    % 2. Full constructive package synergy leverage (> 9.5x)
    assert(T_NZ.Lambda_Y(8) > 9.5 && T_FI.Lambda_Y(8) > 9.5, ...
        'Full 7-segment package must achieve > 9.5x Hulten leverage.');

    % 3. [2A-Prop-Factor2] P0_Early_0to5: NZ starved (> 0) vs FI saturated (< 0)
    assert(T_NZ.CE_LR_Reg1(2) > 0.5 && T_FI.CE_LR_Reg1(2) < 0.0, ...
        'P0_Early_0to5 must be welfare-positive in NZ and saturated (< 0) in FI_FBC1987.');

    % 4. [2A-Prop-Factor2] P1P2_Late_6to17: Auckland COL attenuation vs Helsinki uniformity
    nz_gap = abs(T_NZ.Ebar_LR_Reg1(3) - T_NZ.Ebar_LR_Reg4(3));
    fi_gap = abs(T_FI.Ebar_LR_Reg1(3) - T_FI.Ebar_LR_Reg4(3));
    assert(nz_gap > 0.50 && fi_gap < 0.10, ...
        'P1P2 regional Ebar_LR gap must reflect Auckland Q_k attenuation vs Helsinki uniformity.');

    fprintf('[PASS] test_wedge_additionality_ledger\n');
end
