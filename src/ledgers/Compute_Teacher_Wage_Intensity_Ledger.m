function T_Edu = Compute_Teacher_Wage_Intensity_Ledger(Profile_Name, Write_CSV, Out_Dir)
% COMPUTE_TEACHER_WAGE_INTENSITY_LEDGER  ([2B-Spec-Edu1])
% Pure post-hoc ledger decomposing nominal regional public skill outlays
% (G_ece_stage1, G_ece_stage2, including dG_kai_k local nutrition lift) into:
%   1. Standardized national collective salary + bounded high-Q_k COL stipend,
%   2. Regional site/lease & reliever-churn overhead absorption xi_ovh(Q_k),
%   3. Real instructional FTE intensity vs. converted Cunha-Heckman input.
% Zero changes to profiles/*/regions.csv or 4D/5D Bellman state dimensions.

    if nargin < 2 || isempty(Write_CSV), Write_CSV = false; end
    if nargin < 3, Out_Dir = ''; end

    Out_Dir = Resolve_IGW_OutputDir(Out_Dir, Profile_Name);

    DataSpec  = Load_Empirical_Profile(Profile_Name);
    Reg_Names = DataSpec.Regions(:);
    N_reg     = DataSpec.N_reg;
    RT        = DataSpec.Reg_Table;

    pop_w   = DataSpec.Pop_Shares(:);
    w_base  = RT.w_base(:);
    Q_base  = RT.Q_base(:);
    w_m_SS1 = RT.w_mult_SS1(:);
    w_m_SS2 = RT.w_mult_SS2(:);
    Q_m_SS1 = RT.Q_mult_SS1(:);
    Q_m_SS2 = RT.Q_mult_SS2(:);
    dar_m   = RT.daruich_mult(:);

    % Profile-native monetary unit in thousands (e.g. 95.0 kNZD in NZ; kEUR in FI)
    unit_kCurr = DataSpec.Monetary.Currency_Base_Scale / 1000.0;
    nu_kaiako  = 0.350;  % Kaiako housing-affordability supply exponent (Compose_Policy_Bundle)
    xi_ovh_min = 0.180;  % Baseline non-wage site/admin share at provincial Q_ref
    psi_col    = 0.055;  % Bounded high-COL / priority-staffing salary stipend slope

    Phases     = {'SS0', 'SS1', 'SS2'};
    W_Mults    = [ones(N_reg, 1), w_m_SS1, w_m_SS2];
    Q_Mults    = [ones(N_reg, 1), Q_m_SS1, Q_m_SS2];
    Q_nat_SS0  = sum(pop_w .* Q_base);
    Q_ref_prov = Q_base(1);

    % Extract solved G_ece_stage1 and G_ece_stage2 per phase from canonical Tier A-D pipeline
    G1_Mat   = zeros(N_reg, 3);
    G2_Mat   = zeros(N_reg, 3);
    Ped_Mult = zeros(N_reg, 3);
    m_vec    = [0.0, 0.85, 1.00];

    for p = 1:3
        P_ph = Configure_Model_Params(struct(), 3, 7, DataSpec, [], Phases{p});
        for k = 1:N_reg
            hh_k = ['HH_', Reg_Names{k}];
            G1_Mat(k, p) = P_ph.G_ece_stage1.(hh_k);
            G2_Mat(k, p) = P_ph.G_ece_stage2.(hh_k);
        end
        Ped_Mult(:, p) = 1.0 + 0.22 * m_vec(p) * (dar_m / mean(dar_m));
    end

    % Vectorized [N_reg x 3] price, overhead, salary, and FTE matrices
    W_reg_Mat    = w_base .* W_Mults;
    Q_reg_Mat    = Q_base .* Q_Mults;
    w_nat_row    = sum(pop_w .* W_reg_Mat, 1);

    COL_Stipend  = 1.0 + psi_col * max(0.0, (Q_reg_Mat ./ Q_nat_SS0) - 1.0);
    W_Teach_kNZD = (unit_kCurr * w_nat_row) .* COL_Stipend;

    Kaiako_Defl  = min(1.05, (Q_ref_prov ./ Q_reg_Mat) .^ nu_kaiako);
    Instr_Share  = (1.0 - xi_ovh_min) .* Kaiako_Defl;
    Ovh_Share    = 1.0 - Instr_Share;

    Spend_S1_kNZD  = unit_kCurr * G1_Mat;
    Spend_S2_kNZD  = unit_kCurr * G2_Mat;
    Spend_Tot_kNZD = Spend_S1_kNZD + Spend_S2_kNZD;

    Salary_Tot_kNZD = Instr_Share .* Spend_Tot_kNZD;
    Ovh_Tot_kNZD    = Ovh_Share   .* Spend_Tot_kNZD;

    % Real educator FTE per 100 children (100 * Direct_Salary_Bill / Annual_Teacher_Salary)
    FTE_S1_Per100  = 100.0 * (Instr_Share .* Spend_S1_kNZD) ./ W_Teach_kNZD;
    FTE_S2_Per100  = 100.0 * (Instr_Share .* Spend_S2_kNZD) ./ W_Teach_kNZD;
    FTE_Tot_Per100 = FTE_S1_Per100 + FTE_S2_Per100;

    % Effective converted instructional input entering Cunha-Heckman (Proposition 3.3.1)
    G1_Eff_Conv = G1_Mat .* Kaiako_Defl .* Ped_Mult;
    G2_Eff_Conv = G2_Mat .* Kaiako_Defl .* Ped_Mult;

    if Write_CSV
        csv_out = fullfile(Out_Dir, sprintf('Table26_Teacher_Wage_Vs_FTE_Intensity_%s.csv', Profile_Name));
        fid = fopen(csv_out, 'w');
        fprintf(fid, ['Phase,Region_ID,Currency_ISO,Q_Housing,Teacher_Salary_kCurr,COL_Stipend_Pct,', ...
                      'Gross_Edu_PerChild_kCurr,Direct_Salary_PerChild_kCurr,Site_Turnover_Ovh_kCurr,', ...
                      'Ovh_Share_Pct,Real_FTE_Per100_Children,Kaiako_Supply_Deflator,', ...
                      'G_ECE1_Eff_Converted,G_ECE2_Eff_Converted\n']);
        c_iso = DataSpec.Monetary.Currency_ISO;
        for p = 1:3
            for k = 1:N_reg
                fprintf(fid, '%s,%s,%s,%.4f,%.3f,%.3f,%.4f,%.4f,%.4f,%.3f,%.4f,%.4f,%.5f,%.5f\n', ...
                    Phases{p}, Reg_Names{k}, c_iso, Q_reg_Mat(k,p), W_Teach_kNZD(k,p), ...
                    100.0 * (COL_Stipend(k,p) - 1.0), Spend_Tot_kNZD(k,p), ...
                    Salary_Tot_kNZD(k,p), Ovh_Tot_kNZD(k,p), 100.0 * Ovh_Share(k,p), ...
                    FTE_Tot_Per100(k,p), Kaiako_Defl(k,p), G1_Eff_Conv(k,p), G2_Eff_Conv(k,p));
            end
        end
        fclose(fid);
    end

    T_Edu = struct( ...
        'Profile',         Profile_Name, ...
        'Currency_ISO',    DataSpec.Monetary.Currency_ISO, ...
        'Regions',         {Reg_Names}, ...
        'Phases',          {Phases}, ...
        'Q_reg_Mat',       Q_reg_Mat, ...
        'W_Teach_kNZD',    W_Teach_kNZD, ...
        'COL_Stipend',     COL_Stipend, ...
        'Spend_Tot_kNZD',  Spend_Tot_kNZD, ...
        'Salary_Tot_kNZD', Salary_Tot_kNZD, ...
        'Ovh_Tot_kNZD',    Ovh_Tot_kNZD, ...
        'Ovh_Share',       Ovh_Share, ...
        'FTE_Tot_Per100',  FTE_Tot_Per100, ...
        'Kaiako_Defl',     Kaiako_Defl, ...
        'G1_Eff_Conv',     G1_Eff_Conv, ...
        'G2_Eff_Conv',     G2_Eff_Conv);
end
