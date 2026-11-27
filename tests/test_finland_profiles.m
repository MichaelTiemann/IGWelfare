function test_finland_profiles()
% TEST_FINLAND_PROFILES  Contract & invariance suite for TEMPLATE_Profile, FI_Peruskoulu1967, and FI_FBC1987.
%   Verifies:
%     1. TEMPLATE_Profile self-containment across Layer 1, Layer 2, Layer 3, and sectors/.
%     2. FI_Peruskoulu1967 (t0 = 1967) & FI_FBC1987 (2025 observed) simplex, fertility,
%        dynamic Primate ('Helsinki'), and row-stochastic transition invariants.
%     3. Compose_Policy_Bundle profile-awareness (no NZ baseline overwrite on non-NZ profiles,
%        dynamic z_f_Helsinki updates, epistemic Peruskoulu x Disinfo complementarity,
%        Kotihoidontuki drag/unlock sign, and physical [0.5%, 100] bounds).
%     4. Phase II 5-Sector, Exergy, LULUCF (kappa_pine = 0 in 2025), Caruna vs Ostrom EUR
%        asset stewardship, and 1967 vs 2025 NATO 3% GDP sovereign-yield insulation.
%     5. Sankey flow-conservation laws on tests/output/FI_Peruskoulu1967/ Table 14 & Table 15.

    setup_igw_paths(true);
    igw_root = fileparts(fileparts(mfilename('fullpath')));

    %% 1. TEMPLATE_Profile Full Schema Self-Containment & Universal Human Invariance vs NZ_Dunedin1972
    DNZ    = Load_Empirical_Profile('NZ_Dunedin1972');
    SecNZ  = Load_Sectoral_Exergy_Spec(DNZ);
    DTpl   = Load_Empirical_Profile('TEMPLATE_Profile');
    SecTpl = Load_Sectoral_Exergy_Spec(DTpl);
    assert(numel(DTpl.Regions) == 4, 'TEMPLATE_Profile must define 4 domestic regions.');
    assert(numel(SecTpl.SubSector_Table.SubSector_ID) == numel(SecNZ.SubSector_Table.SubSector_ID), ...
        'TEMPLATE_Profile sectors_2026.csv subsector count must match NZ_Dunedin1972.');
    CatTpl = Load_Commitment_Catalog(DTpl);
    assert(numel(CatTpl.Commitment_IDs) == 26, 'TEMPLATE_Profile commitment_catalog.csv must contain 26 commitments (C01..C18, C21..C28).');

    %% 2. Layer-1 Simplex, Dynamic Primate ('Helsinki'), & Demography Invariants
    D67 = Load_Empirical_Profile('FI_Peruskoulu1967');
    D25 = Load_Empirical_Profile('FI_FBC1987');

    assert(strcmp(D67.Primate_Region_ID, 'Helsinki'), 'FI_Peruskoulu1967 Primate_Region_ID must be Helsinki.');
    assert(strcmp(D25.Primate_Region_ID, 'Helsinki'), 'FI_FBC1987 Primate_Region_ID must be Helsinki.');
    assert(isequal(D25.Regions(:)', {'Rural', 'Small', 'Large', 'Helsinki'}), 'Canonical [Rural, Small, Large, Helsinki] order required.');
    assert(strcmp(D67.Monetary.Currency_ISO, 'EUR'), 'Finland Currency_ISO must be EUR.');
    assert(abs(D67.Monetary.GDP_Base_Billions - 281.78) < 1e-6, 'Finland 2025 GDP anchor must equal EUR 281.78B.');

    % Simplex sum checks
    assert(abs(sum(D67.Pop_Shares)  - 1.0) < 1e-12, 'FI_Peruskoulu1967 Pop_Shares must sum to 1.');
    assert(abs(sum(D67.Firm_Shares) - 1.0) < 1e-12, 'FI_Peruskoulu1967 Firm_Shares must sum to 1.');
    assert(abs(sum(D25.Pop_Shares)  - 1.0) < 1e-12, 'FI_FBC1987 Pop_Shares must sum to 1.');
    assert(abs(sum(D25.Firm_Shares) - 1.0) < 1e-12, 'FI_FBC1987 Firm_Shares must sum to 1.');
    assert(D67.Pop_Shares(1) > 0.40 && D25.Pop_Shares(4) > 0.28, '1967 Rural (>40%) -> 2025 Greater Helsinki (28.7%) urbanization shift expected.');

    % Fertility sum(fj) == TFR & Transition row-stochastic checks
    assert(abs(sum(D67.Demography_5yr.fj) - 2.32) < 1e-9, '1967 Finnish TFR sum(fj) must equal 2.32.');
    assert(abs(sum(D25.Demography_5yr.fj) - 1.30) < 1e-9, '2025 Finnish TFR sum(fj) must equal 1.30.');
    assert(max(abs(sum(D67.Transition.Pi_dom_SS1, 2) - 1.0)) < 1e-12, 'Pi_dom_SS1 must be row-stochastic.');
    assert(max(abs(sum(D67.Transition.Pi_dom_SS2, 2) - 1.0)) < 1e-12, 'Pi_dom_SS2 must be row-stochastic.');
    assert(abs(sum(D67.Transition.Intl_Inflow_Share) - 1.0) < 1e-12, 'Intl_Inflow_Share must sum to 1.');

    %% 3. Compose_Policy_Bundle Profile-Awareness & Composable Historical Counterfactuals
    [P67, ~] = Ensure_Workbench_Initialized(struct('Profile_Name', 'FI_Peruskoulu1967', 'dt', 5, 'RequireWorkerPool', false));
    [P_B67, pi_B67, M_B67] = Compose_Policy_Bundle(P67, struct(), 'baseline_2023');
    assert(isfield(P_B67, 'z_f_Helsinki') && numel(P_B67.z_f_Helsinki) == 2, 'Dynamic z_f_Helsinki field must be populated.');
    assert(abs(P_B67.G_ECE_1 - 0.052) < 1e-12, 'Non-NZ baseline_2023 must preserve profile G_ece1_sched(1), not NZ 0.045.');

    [~, ~, M_W1]  = Compose_Policy_Bundle(P_B67, pi_B67, 'fi_wave1_peruskoulu_ecec_1970s');
    [~, ~, M_W23] = Compose_Policy_Bundle(P_B67, pi_B67, 'fi_wave1_to_3_with_kotihoidontuki_drag');
    [~, ~, M_W4]  = Compose_Policy_Bundle(P_B67, pi_B67, 'fi_wave4_disinfo_and_age18_2014_2023');
    [~, ~, M_CF1] = Compose_Policy_Bundle(P_B67, pi_B67, 'fi_disinfo_without_peruskoulu_test');
    [~, ~, M_CF2] = Compose_Policy_Bundle(P_B67, pi_B67, 'fi_remove_kotihoidontuki_unlock');

    % Verify 1985 Kotihoidontuki cash-for-care drag & repeal unlock
    assert(M_W23.Frac_Struggling_Imputed > M_W1.Frac_Struggling_Imputed, '1985 Kotihoidontuki drag must raise struggling share relative to Wave 1.');
    assert(M_CF2.Frac_Struggling_Imputed < M_W4.Frac_Struggling_Imputed, 'Repealing Kotihoidontuki must reduce struggling share relative to observed Wave 4.');

    % Verify epistemic complementarity: 2016 Disinfo defense WITH Peruskoulu > WITHOUT Peruskoulu
    dCoh_with    = M_W4.Social_Cohesion_St  - M_B67.Social_Cohesion_St;
    dCoh_without = M_CF1.Social_Cohesion_St - M_B67.Social_Cohesion_St;
    assert(dCoh_with > 2.0 * dCoh_without, 'Disinformation curriculum atop Peruskoulu must more than double standalone cohesion lift.');

    % Verify FI_FBC1987 incremental 2025 space (zero double-counting & strict physical bounds)
    [P25, ~] = Ensure_Workbench_Initialized(struct('Profile_Name', 'FI_FBC1987', 'dt', 5, 'RequireWorkerPool', false));
    [P_B25, pi_B25, M_B25] = Compose_Policy_Bundle(P25, struct(), 'baseline_2023');
    assert(abs(M_B25.Frac_Struggling_Imputed - 0.071485) < 1e-4, 'FI_FBC1987 baseline struggling share must equal 7.15% (no NZ overwrite).');
    assert(abs(M_B25.Social_Cohesion_St - 100.0) < 1e-9, 'FI_FBC1987 baseline cohesion index must anchor at 100.0.');

    [~, ~, M_Aust] = Compose_Policy_Bundle(P_B25, pi_B25, 'fi_2024_2026_austerity_plus_nato');
    [~, ~, M_Asp2] = Compose_Policy_Bundle(P_B25, pi_B25, 'fi25_aspect2_land_youth_housing_only');
    [~, ~, M_SS2]  = Compose_Policy_Bundle(P_B25, pi_B25, 'fi25_unlock_missing_aspect23_ss2');

    assert(M_Aust.Frac_Struggling_Imputed > M_B25.Frac_Struggling_Imputed && M_Aust.Emig_Nat_Imputed > M_B25.Emig_Nat_Imputed, ...
        '2024-2026 austerity + unfunded NATO posture must increase struggling launches and emigration.');
    assert(M_Asp2.Emig_Nat_Imputed < M_B25.Emig_Nat_Imputed - 0.03, ...
        'Missing Aspect 2 (1.5% LVT + Age-20 Youth Grant) must cut Finnish skilled emigration by >3 pp.');
    assert(M_SS2.Frac_Struggling_Imputed >= 0.005 && M_SS2.Frac_Struggling_Imputed < M_B25.Frac_Struggling_Imputed, ...
        'Incremental SS2 struggling share must remain strictly positive (>=0.5%) and below 2025 baseline.');
    assert(M_SS2.TI_Social_Credit_CPI <= 100.0, 'Imputed TI CPI must respect the 100.0 index ceiling.');

    %% 4. Universal Human Invariance ("People Are People") & Phase II EUR Physics Checks
    Sec67 = Load_Sectoral_Exergy_Spec('FI_Peruskoulu1967');
    Sec25 = Load_Sectoral_Exergy_Spec('FI_FBC1987');

    % Enforce strict equality of universal human/shock/co-production parameters across NZ and Finland:
    for D_fi = {D67, D25}
        Df = D_fi{1};
        assert(max(abs(Df.Reg_Table.daruich_mult(:) - DNZ.Reg_Table.daruich_mult(:))) < 1e-12, 'Universal daruich_mult must match NZ.');
        assert(max(abs(Df.Reg_Table.sigma_z(:)      - DNZ.Reg_Table.sigma_z(:)))      < 1e-12, 'Universal sigma_z must match NZ.');
        assert(max(abs(Df.Reg_Table.psi_persist(:)  - DNZ.Reg_Table.psi_persist(:)))  < 1e-12, 'Universal psi_persist must match NZ.');
    end
    for S_fi = {Sec67, Sec25}
        Sf = S_fi{1};
        assert(abs(Sf.SOE.Arrow_S2_Spillover_Eta  - SecNZ.SOE.Arrow_S2_Spillover_Eta)  < 1e-12, 'Universal Arrow_S2_Spillover_Eta must match NZ.');
        assert(abs(Sf.SOE.Ostrom_CoProd_Rho       - SecNZ.SOE.Ostrom_CoProd_Rho)       < 1e-12, 'Universal Ostrom_CoProd_Rho must match NZ.');
        assert(abs(Sf.SOE.Ostrom_Omega_Paid       - SecNZ.SOE.Ostrom_Omega_Paid)       < 1e-12, 'Universal Ostrom_Omega_Paid must match NZ.');
        assert(abs(Sf.SOE.Waring_Shadow_Wage_Frac - SecNZ.SOE.Waring_Shadow_Wage_Frac) < 1e-12, 'Universal Waring_Shadow_Wage_Frac must match NZ.');
    end
    assert(abs(sum(Sec25.MacroSector_Table.Annual_Spend_BCurr) - 281.8) < 1e-6, 'Finnish 5-sector spend must sum to EUR 281.8B.');
    assert(abs(Sec25.Exergy.Fossil_Import_Bill_SS0_BCurr - 4.40) < 1e-9, '2025 net fossil import bill must equal EUR 4.40B.');
    assert(abs(Sec67.Exergy.Fossil_Import_Bill_SS0_BCurr - 10.85) < 1e-9, '1967 GDP-scaled fossil bill must equal EUR 10.85B.');

    % Verify EUR-scaled Actuarial Ledger (EUR 6.02B Yr-5 outlay vs NZD 9.19B; 1967 Sav > 2025 Sav)
    Act67 = Compute_Actuarial_Ledger([], struct('Profile_Name', 'FI_Peruskoulu1967'), struct('Verbose', false));
    Act25 = Compute_Actuarial_Ledger([], struct('Profile_Name', 'FI_FBC1987'),        struct('Verbose', false));
    assert(strcmp(Act25.Currency_ISO, 'EUR') && strcmp(Act25.Currency_Symbol, '€'), 'Actuarial ledger must carry EUR/€ metadata.');
    assert(abs(Act25.Year5Table.Cum_Outlay_B(5) - 9.19 * (281.78 / 430.0)) < 0.05, 'Year-5 EUR outlay must scale by GDP_Base_Billions.');
    assert(Act67.Year5Table.Booked_Sav_2pct_B(5) > 2.5 * Act25.Year5Table.Booked_Sav_2pct_B(5), ...
        '1967 pre-Peruskoulu direct cost avoidance backlog must exceed 2025 post-Peruskoulu backlog by >2.5x.');
    assert(Sec25.NDC.kappa_pine_schedule(1) == 0.0, '2025 Finnish LULUCF net emission source requires kappa_pine(1) == 0.');

    Eq67_Def = Compute_5Sector_Exergy_Equilibrium(P67, 'SS0_Defence_3Pct');
    Eq25_Def = Compute_5Sector_Exergy_Equilibrium(P25, 'SS0_Defence_3Pct');
    Eq25_SS2 = Compute_5Sector_Exergy_Equilibrium(P25, 'Phase2_Defence_3Pct');
    idx50    = find(Eq25_Def.Years == 2050, 1);

    assert(Eq25_Def.Fossil_Import_BNZD_t(idx50) < 0.5 * Eq67_Def.Fossil_Import_BNZD_t(idx50), ...
        '2025 Nuclear/CHP grid must cut 2050 fossil FX drain by >50% relative to 1967 fossil structure.');
    assert(Eq25_Def.r_Sovereign_t(idx50) < Eq67_Def.r_Sovereign_t(idx50) - 0.01, ...
        'Clean grid + creditor NIIP must save >100 bps in sovereign yield under 3% GDP defence.');
    assert(Eq25_SS2.NFA_to_GDP_t(idx50) > 0.25 && Eq25_Def.NFA_to_GDP_t(idx50) < -0.15, ...
        'Integrated Phase II reform must preserve creditor NFA (>+25% GDP) while sustaining 3% GDP NATO defence.');

    Asset25 = Compute_Public_Asset_Stewardship_Ledger(P25, struct('Verbose', false));
    assert(Asset25.Opportunity_Loss_2pct_B > 100.0 && Asset25.Asset_Book_Value_BNZD < 40.0, ...
        'EUR-scaled Caruna DSO privatization opportunity loss must exceed EUR 100B on ~EUR 32.8B grid block.');

    Helm67 = Compute_Helm_TrimTab_Ledger(P67, struct('Verbose', false));
    Helm25 = Compute_Helm_TrimTab_Ledger(P25, struct('Verbose', false));
    assert(Helm67.Yr_True_Breakeven < Helm25.Yr_True_Breakeven, ...
        '1967 pre-nuclear baseline must achieve faster FX+Waring breakeven than already-decarbonized 2025 grid.');

    %% 5. Reference Table 14 & Table 15 Sankey Flow-Conservation Checks
    t14_path = fullfile(igw_root, 'tests', 'output', 'FI_Peruskoulu1967', 'Table14_FiscalLedger_6Gate_Decomp_National.csv');
    t15_path = fullfile(igw_root, 'tests', 'output', 'FI_Peruskoulu1967', 'Table15_ChildFates_5Stage_Decomp_National.csv');
    assert(exist(t14_path, 'file') == 2 && exist(t15_path, 'file') == 2, 'Reference Finnish Table 14 & 15 CSVs must exist in tests/output/FI_Peruskoulu1967/.');

    T15 = Read_IGW_CSV(t15_path);
    u_gates15 = unique(T15.Gate, 'stable');
    for g = 1:numel(u_gates15)
        m = strcmp(T15.Gate, u_gates15{g});
        assert(abs(sum(T15.SS0_Pop_Pct(m)) - 100.0) < 1e-6, 'Table 15 SS0 gate shares must sum to 100%.');
        assert(abs(sum(T15.SS1_Pop_Pct(m)) - 100.0) < 1e-6, 'Table 15 SS1 gate shares must sum to 100%.');
        assert(abs(sum(T15.SS2_Pop_Pct(m)) - 100.0) < 1e-6, 'Table 15 SS2 gate shares must sum to 100%.');
    end

    T14 = Read_IGW_CSV(t14_path);
    u_gates14 = unique(T14.Gate, 'stable');
    g_sums = zeros(numel(u_gates14), 3);
    for g = 1:numel(u_gates14)
        m = strcmp(T14.Gate, u_gates14{g});
        g_sums(g, :) = [sum(T14.SS0_CohortFlow_kNZD(m)), sum(T14.SS1_CohortFlow_kNZD(m)), sum(T14.SS2_CohortFlow_kNZD(m))];
    end
    assert(max(abs(g_sums(1, :) - g_sums(2, :))) < 1e-6, 'Table 14 Sankey conservation requires Gate 1 == Gate 2.');
    assert(max(abs(g_sums(4, :) - g_sums(5, :))) < 1e-6, 'Table 14 Sankey conservation requires Gate 4 == Gate 5.');
    assert(max(abs(g_sums(5, :) - g_sums(6, :))) < 1e-6, 'Table 14 Sankey conservation requires Gate 5 == Gate 6.');
    assert(abs(T14.SS1_CohortFlow_kNZD(21) - T14.SS1_CohortFlow_kNZD(29)) < 1e-6, 'Node 21 and Node 29 Abroad flows must match.');

    fprintf('[PASS] test_finland_profiles verified TEMPLATE_Profile, FI_Peruskoulu1967, FI_FBC1987, Phase II EUR physics, and Sankey ledgers.\n');
end
