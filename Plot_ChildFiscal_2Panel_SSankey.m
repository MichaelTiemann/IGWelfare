%% PLOT_CHILDFISCAL_2PANEL_SSANKEY.M
% 6-Gate Pairwise 2-Panel Sankey Diagram (A3 Layout, 100% GPU-Vectorized)
% Units: Cohort-Weighted Annual NZD Thousands ($k/yr per child born in cohort)
%        + Explicit Population Share (% pop) on Gates 1-4 & Explicit Barnardos Exits 1-4:
%   - Gate 1 (J = 1, Birth, Age 0):
%       (1) Means-Tested Birth Support, (2) Universal Birth Benefit, (3) Private Out-of-Pocket Birth Cost
%   - Gate 2 (J = 2..3, First 2000 Days ECE Gate, Ages 0-5):
%       Exposes the ~50/50 split between ECE Corner + Benefit Need vs. High ECE + Parental Time
%   - Gate 3 (J = 5, Adolescent Gate, Ages 12-14):
%       Exposes Unemp Stress + Early Exits 1,2,4 (Care, Hosp, Youth Justice/Benefit) vs. Montessori / Tuakana Mentoring
%   - Gate 4 (J = 6..7, Adult Skill Launch, Age 20):
%       Stunted h1-h2 (carrying Exits 1,2,4; Exit 3 not yet active) vs. Core h3-h5 vs. Thriving h6-h7
%   - Gate 5 (J = 10, Age 30) & Gate 6 (J = 11..16, Career to Retirement):
%       All 4 Barnardos Exits (Exits 1,2,4 Direct Crown Cost + Exit 3 Lower Income/Super Draw) at Bottom (BAD),
%       GST/Cap/Estate Tax + PAYE Tax in Middle (GOOD), Emigrated Tax Loss at Top (BEYOND),
%       with Net-Zero Breakeven Line across Gates 5 & 6.

%% 1. CONFIGURATION SWITCHES
Target_Regions     = {'National', 'Auckland', 'Large', 'Small', 'Rural', 'Urban'}; % Any subset or single region!
if ischar(Target_Regions) || isstring(Target_Regions), Target_Regions = cellstr(Target_Regions); end
Calibration_Anchor = 'Dunedin_22'; % 'Dunedin_22' or 'MetroSqueeze_GUiNZ'
Merge_Orientation  = 'Vertical';   % 'Vertical' (Stacked Top/Bottom for A3) or 'Horizontal'
NZD_Base_Scale     = 95.0;         % 1.0 model unit = NZD $95.0k/yr (mean prime household earnings)

%% 2. DETECT BASELINE (SS0) AND REFORM (SS1) WORKSPACE OBJECTS
if exist('StatDist_Base', 'var') && exist('Policy_Base', 'var')
    Dist_SS0 = StatDist_Base;
    Pol_SS0  = Policy_Base;
    P_SS0    = Params_Base;
    Diag_SS0 = IG_Diag_Base;
elseif exist('StationaryDist', 'var') && exist('Policy', 'var')
    Dist_SS0 = StationaryDist;
    Pol_SS0  = Policy;
    P_SS0    = Params;
    if exist('IG_Diagnostics', 'var'), Diag_SS0 = IG_Diagnostics; else, Diag_SS0 = struct(); end
else
    error('Run NZ_4Region_Master.m or WelfareDecomposition_4Region.m first.');
end

if exist('StatDist_GE_Endo', 'var')
    Dist_SS1 = StatDist_GE_Endo;
    if exist('Policy_GE_Endo', 'var')
        Pol_SS1 = Policy_GE_Endo;
    elseif exist('Policy_GE_Exo', 'var')
        Pol_SS1 = Policy_GE_Exo;
    else
        Pol_SS1 = Pol_SS0;
    end
    if exist('Params_GE', 'var'), P_SS1 = Params_GE; else, P_SS1 = P_SS0; end
    if exist('IG_Diag_Reform', 'var'), Diag_SS1 = IG_Diag_Reform; else, Diag_SS1 = Diag_SS0; end
else
    Dist_SS1 = Dist_SS0;
    Pol_SS1  = Pol_SS0;
    P_SS1    = P_SS0;
    P_SS1.G_ece = getfield_def(P_SS0, 'G_ece', 0.05) + 0.14;
    P_SS1.tau_a = getfield_def(P_SS0, 'tau_a', 0.00) + 0.012;
    P_SS1.tau_b = getfield_def(P_SS0, 'tau_b', 0.05) + 0.10;
    Q_mult_Map  = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);
    f_all       = fieldnames(Dist_SS0);
    hh_f        = f_all(strncmp(f_all, 'HH_', 3));
    for r_i = 1:length(hh_f)
        hk  = hh_f{r_i};
        reg = erase(hk, 'HH_');
        if isfield(P_SS0.Q_reg, hk) && isfield(Q_mult_Map, reg)
            P_SS1.Q_reg.(hk) = P_SS0.Q_reg.(hk) * Q_mult_Map.(reg);
        end
    end
    Diag_SS1 = Diag_SS0;
    if isfield(Diag_SS1, 'Emig_By_SkillTier')
        Diag_SS1.Emig_By_SkillTier = Diag_SS0.Emig_By_SkillTier * 0.55;
    else
        Diag_SS1.Emig_By_SkillTier = [0.02, 0.02, 0.05, 0.06, 0.07, 0.11, 0.12];
    end
end

%% 3. RENDER PANEL A & PANEL B ON A3 CANVASES AND MERGE INTO ONE IMAGE
FiscalLedger = struct();

for r_loop = 1:length(Target_Regions)
    Target_Region = Target_Regions{r_loop};
    Out_PNG_Name  = sprintf('Fig_ChildFiscal_5Stage_2Panel_%s_%s.png', Target_Region, Calibration_Anchor);

    %% 3.1 CREATE SANKEY BLOCKS AND RIBBONS
    figA = figure('Color', 'w', 'Position', [20, 40, 1850, 820], 'Visible', 'on');
    axA  = axes('Parent', figA, 'Position', [0.02, 0.07, 0.95, 0.85]);
    FiscalLedger.(Target_Region).SS0 = Build_And_Render_Fiscal_Panel(axA, Target_Region, Dist_SS0, Pol_SS0, ...
        P_SS0, Diag_SS0, n_d, n_a, n_z, d_grid, a_grid, z_grid, ...
        'A. Status Quo Baseline (SS0)', ...
        Calibration_Anchor, NZD_Base_Scale, false);
    drawnow;
    imgA = AutoCrop_White_Border(print(figA, '-RGBImage', '-r300'));
    close(figA);

    figB = figure('Color', 'w', 'Position', [20, 40, 1850, 820], 'Visible', 'on');
    axB  = axes('Parent', figB, 'Position', [0.02, 0.07, 0.95, 0.85]);
    FiscalLedger.(Target_Region).SS1 = Build_And_Render_Fiscal_Panel(axB, Target_Region, Dist_SS1, Pol_SS1, ...
        P_SS1, Diag_SS1, n_d, n_a, n_z, d_grid, a_grid, z_grid, ...
        'B. High-Opportunity Reform (SS1)', ...
        Calibration_Anchor, NZD_Base_Scale, true);
    drawnow;
    imgB = AutoCrop_White_Border(print(figB, '-RGBImage', '-r300'));
    close(figB);

    [hA, wA, ~] = size(imgA);
    [hB, wB, ~] = size(imgB);

    if strcmpi(Merge_Orientation, 'Vertical')
        W_max    = max(wA, wB);
        pad_L    = 65;
        pad_R    = 95;
        W_canvas = W_max + pad_L + pad_R;

        imgA_pad = uint8(255 * ones(hA, W_canvas, 3));
        imgA_pad(:, (pad_L+1):(pad_L+wA), :) = imgA;

        imgB_pad = uint8(255 * ones(hB, W_canvas, 3));
        imgB_pad(:, (pad_L+1):(pad_L+wB), :) = imgB;

        top_frame_pad    = uint8(255 * ones(90, W_canvas, 3));
        gap_below_PanelA = uint8(255 * ones(80, W_canvas, 3));
        divider_line     = uint8(220 * ones(4,  W_canvas, 3));
        gap_above_PanelB = uint8(255 * ones(90, W_canvas, 3));
        bot_frame_pad    = uint8(255 * ones(90, W_canvas, 3));

        img_Merged = [top_frame_pad; imgA_pad; gap_below_PanelA; divider_line; gap_above_PanelB; imgB_pad; bot_frame_pad];
        fig_pos    = [60, 20, 1380, 1080];
    else
        H_max    = max(hA, hB);
        pad_T    = 90; pad_B = 90;
        H_canvas = H_max + pad_T + pad_B;
        imgA_pad = uint8(255 * ones(H_canvas, wA, 3)); imgA_pad((pad_T+1):(pad_T+hA), :, :) = imgA;
        imgB_pad = uint8(255 * ones(H_canvas, wB, 3)); imgB_pad((pad_T+1):(pad_T+hB), :, :) = imgB;
        left_pad  = uint8(255 * ones(H_canvas, 65, 3));
        mid_gap   = uint8(255 * ones(H_canvas, 120, 3));
        right_pad = uint8(255 * ones(H_canvas, 95, 3));
        img_Merged = [left_pad, imgA_pad, mid_gap, imgB_pad, right_pad];
        fig_pos    = [20, 80, 1880, 760];
    end

    imwrite(img_Merged, fullfile(OutputDir, Out_PNG_Name));
    fprintf('\nSaved merged 6-gate Fiscal Sankey image to: %s\n', fullfile(OutputDir, Out_PNG_Name));

    %% 3.2 DOCUMENT 1A & 1B PROTOCOL: 2050 DEBT-SINKING FUND & PUBLIC REINVESTMENT LEDGER SUMMARY
    L_SS0 = FiscalLedger.(Target_Region).SS0;
    L_SS1 = FiscalLedger.(Target_Region).SS1;
    Omega_Delta_30 = max(0, L_SS1.Net_Fiscal_Balance_kNZD(1) - L_SS0.Net_Fiscal_Balance_kNZD(1));
    Omega_Delta_CR = max(0, L_SS1.Net_Fiscal_Balance_kNZD(2) - L_SS0.Net_Fiscal_Balance_kNZD(2));

    FiscalLedger.Protocol_2050_Summary = table( ...
        [L_SS0.Net_Fiscal_Balance_kNZD(1); L_SS0.Net_Fiscal_Balance_kNZD(2)], ...
        [L_SS1.Net_Fiscal_Balance_kNZD(1); L_SS1.Net_Fiscal_Balance_kNZD(2)], ...
        [Omega_Delta_30; Omega_Delta_CR], ...
        [L_SS1.SinkingFund_50Pct_kNZD(1); L_SS1.SinkingFund_50Pct_kNZD(2)], ...
        [L_SS1.ReinvestmentPool_50Pct_kNZD(1); L_SS1.ReinvestmentPool_50Pct_kNZD(2)], ...
        [L_SS1.Annual_DebtService_Saving_kNZD(1); L_SS1.Annual_DebtService_Saving_kNZD(2)], ...
        [L_SS1.Public_Infra_Yield_Dividend_kNZD(1); L_SS1.Public_Infra_Yield_Dividend_kNZD(2)], ...
        'RowNames', {'Gate5_Age30_J10', 'Gate6_CareerToRet_J11_16'}, ...
        'VariableNames', {'Baseline_SS0_kNZD', 'Reform_SS1_kNZD', 'Reform_Gain_Omega_kNZD', ...
        'DebtSinking_50Pct_kNZD', 'ReinvestPool_50Pct_kNZD', ...
        'DebtInterestSaved_2050_kNZD', 'Infra_NZSF_YieldDiv_2050_kNZD'});

    fprintf('\n=========================================================================================================\n');
    fprintf('SECTION 5 PROTOCOL: 2050 SOVEREIGN DEBT-SINKING FUND & PUBLIC REINVESTMENT LEDGER (%s)\n', Target_Region);
    fprintf('=========================================================================================================\n');
    disp(FiscalLedger.Protocol_2050_Summary);

    %% 3.3 EXPORT 6-GATE FISCAL LEDGER & 4-LANE CHILD-COST RECONCILIATION CSV
    % Bridges the conventional NZD 15k-19k/yr out-of-pocket survey benchmark against
    % the 4 macroeconomic resource lanes in the 6-Gate Sankey diagram:
    %   Lane A: Private Out-of-Pocket Cash ((1-s)*i_c + housing/food/gear)
    %   Lane B: Private Parental Time Commitment (w*z*h*l_child, Lee & Seshadri gamma_a)
    %   Lane C: Public Developmental Investment (PPL, BestStart, G_ECE, Schooling, Montessori / Tuakana Mentoring)
    %   Lane D: Public Reactive Hardship & Remediation (WFF Hardship, Exits 1, 2, 4)

    Gate_Labels = { ...
        'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0'; ...
        'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; ...
        'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14'; ...
        'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20'; ...
        'Gate5_J10_Age30_Fiscal';        'Gate5_J10_Age30_Fiscal';        'Gate5_J10_Age30_Fiscal'; ...
        'Gate5_J10_Age30_Fiscal';        'Gate5_J10_Age30_Fiscal';        'Gate5_J10_Age30_Fiscal'; ...
        'Gate6_J11_16_CareerToRet';      'Gate6_J11_16_CareerToRet';      'Gate6_J11_16_CareerToRet'; ...
        'Gate6_J11_16_CareerToRet';      'Gate6_J11_16_CareerToRet';      'Gate6_J11_16_CareerToRet'};

    Node_Clean_Names = { ...
        '1_MeansTested_Birth_Support';       '2_Universal_Birth_Benefit';         '3_Private_Birth_OutOfPocket'; ...
        '4_ECE_Corner_Benefit_Need';         '5_Public_ECE_Wraparound';           '6_High_Public_ECE_Support';         '7_Private_Parental_ECE_CashTime'; ...
        '8_Adol_UnempStress_Exits124';       '9_Public_Secondary_Schooling';      '10_Montessori_Tuakana_Mentoring';   '11_Private_Adol_Commit_CashTime'; ...
        '12_Stunted_Tier_h1_h2_Exits124';    '13_Core_Skill_Tier_h3_h5';          '14_Thriving_Tier_h6_h7'; ...
        '15_Age30_Exits124_Remediation';     '16_Age30_Infra_Roads_BaseHealth';   '17_Age30_GST_Cap_Tax_Paid'; ...
        '18_Age30_PAYE_Income_Tax_Paid';     '19_Age30_Exit3_Stunting_LostTax';   '20_Age30_Emig_Abroad_LostTax'; ...
        '21_Career_Exits124_OngoingBurden';  '22_Career_NZSuper_Infra_Health';    '23_Career_GST_Cap_Estate_Tax'; ...
        '24_Career_PAYE_Income_Tax';         '25_Career_Exit3_Stunting_LostTax';  '26_Career_Perm_Abroad_LostTax'};

    Pop_SS0_Pct = 100 * [ ...
        reshape(L_SS0.Pop_S1_Birth, 3, 1); ...
        reshape(L_SS0.Pop_S2_ECE_4Node, 4, 1); ...
        reshape(L_SS0.Pop_S3_Adol_4Node, 4, 1); ...
        reshape(L_SS0.Pop_S4_Skill, 3, 1); ...
        ones(12, 1)];

    Pop_SS1_Pct = 100 * [ ...
        reshape(L_SS1.Pop_S1_Birth, 3, 1); ...
        reshape(L_SS1.Pop_S2_ECE_4Node, 4, 1); ...
        reshape(L_SS1.Pop_S3_Adol_4Node, 4, 1); ...
        reshape(L_SS1.Pop_S4_Skill, 3, 1); ...
        ones(12, 1)];

    Flow_SS0_kNZD = [ ...
        reshape(L_SS0.S1_Totals, 3, 1); ...
        reshape(L_SS0.ECE_4Node_Dollars_kNZD, 4, 1); ...
        reshape(L_SS0.Adol_4Node_Dollars_kNZD, 4, 1); ...
        reshape(L_SS0.S4_Totals, 3, 1); ...
        reshape(L_SS0.S5_Totals, 6, 1); ...
        reshape(L_SS0.S6_Totals, 6, 1)];

    Flow_SS1_kNZD = [ ...
        reshape(L_SS1.S1_Totals, 3, 1); ...
        reshape(L_SS1.ECE_4Node_Dollars_kNZD, 4, 1); ...
        reshape(L_SS1.Adol_4Node_Dollars_kNZD, 4, 1); ...
        reshape(L_SS1.S4_Totals, 3, 1); ...
        reshape(L_SS1.S5_Totals, 6, 1); ...
        reshape(L_SS1.S6_Totals, 6, 1)];

    % 4-Lane Share Weights for the 26-Node Split (where Nodes 7 & 11 are 100% Private Cash + Time,
    % and Nodes 5, 6, 9, 10 are 100% Public Developmental Investment)
    Lane_Shares_SS0 = [ ...
        0.00, 0.00, 0.00, 1.00;  % Node 1: Means-Tested Birth Support
        0.00, 0.00, 1.00, 0.00;  % Node 2: Universal Birth Benefit
        0.68, 0.32, 0.00, 0.00;  % Node 3: Private Birth Out-of-Pocket
        0.00, 0.00, 0.15, 0.85;  % Node 4: ECE Corner + Benefit Need
        0.00, 0.00, 1.00, 0.00;  % Node 5: Public ECE Wraparound (100% Public Dev)
        0.00, 0.00, 1.00, 0.00;  % Node 6: High Public ECE Support (100% Public Dev)
        0.56, 0.44, 0.00, 0.00;  % Node 7: Private Parental ECE (Cash + Time)
        0.00, 0.00, 0.20, 0.80;  % Node 8: Adol Unemp Stress + Exits 1,2,4
        0.00, 0.00, 1.00, 0.00;  % Node 9: Public Secondary Schooling (100% Public Dev)
        0.00, 0.00, 1.00, 0.00;  % Node 10: Montessori / Tuakana Mentoring (100% Public Dev)
        0.58, 0.42, 0.00, 0.00;  % Node 11: Private Adol Commit (Cash + Time)
        0.00, 0.00, 0.15, 0.85;  % Node 12: Stunted Tier h1-h2 [Exits 1,2,4]
        0.35, 0.15, 0.50, 0.00;  % Node 13: Core Skill Tier h3-h5
        0.48, 0.22, 0.30, 0.00;  % Node 14: Thriving Tier h6-h7
        zeros(12, 4)];           % Nodes 15..26: Adult Fiscal Ledger Outlays & Taxes

    Lane_Shares_SS1 = Lane_Shares_SS0;

    PrivCash_SS0_kNZD = Flow_SS0_kNZD .* Lane_Shares_SS0(:, 1);
    PrivTime_SS0_kNZD = Flow_SS0_kNZD .* Lane_Shares_SS0(:, 2);
    PubDev_SS0_kNZD   = Flow_SS0_kNZD .* Lane_Shares_SS0(:, 3);
    PubRemed_SS0_kNZD = Flow_SS0_kNZD .* Lane_Shares_SS0(:, 4);

    PrivCash_SS1_kNZD = Flow_SS1_kNZD .* Lane_Shares_SS1(:, 1);
    PrivTime_SS1_kNZD = Flow_SS1_kNZD .* Lane_Shares_SS1(:, 2);
    PubDev_SS1_kNZD   = Flow_SS1_kNZD .* Lane_Shares_SS1(:, 3);
    PubRemed_SS1_kNZD = Flow_SS1_kNZD .* Lane_Shares_SS1(:, 4);

    Cond_PerChild_SS0_kNZD = Flow_SS0_kNZD ./ max(0.01, Pop_SS0_Pct / 100);
    Cond_PerChild_SS1_kNZD = Flow_SS1_kNZD ./ max(0.01, Pop_SS1_Pct / 100);

    T_FiscalCSV = table(Gate_Labels, Node_Clean_Names, ...
        round(Pop_SS0_Pct, 2), round(Flow_SS0_kNZD, 2), round(Cond_PerChild_SS0_kNZD, 2), ...
        round(PrivCash_SS0_kNZD, 2), round(PrivTime_SS0_kNZD, 2), round(PubDev_SS0_kNZD, 2), round(PubRemed_SS0_kNZD, 2), ...
        round(Pop_SS1_Pct, 2), round(Flow_SS1_kNZD, 2), round(Cond_PerChild_SS1_kNZD, 2), ...
        round(PrivCash_SS1_kNZD, 2), round(PrivTime_SS1_kNZD, 2), round(PubDev_SS1_kNZD, 2), round(PubRemed_SS1_kNZD, 2), ...
        'VariableNames', {'Gate', 'Node_Name', ...
        'SS0_Pop_Pct', 'SS0_CohortFlow_kNZD', 'SS0_CondPerChild_kNZD', ...
        'SS0_LaneA_PrivCash_kNZD', 'SS0_LaneB_PrivTime_kNZD', 'SS0_LaneC_PubDev_kNZD', 'SS0_LaneD_PubRemed_kNZD', ...
        'SS1_Pop_Pct', 'SS1_CohortFlow_kNZD', 'SS1_CondPerChild_kNZD', ...
        'SS1_LaneA_PrivCash_kNZD', 'SS1_LaneB_PrivTime_kNZD', 'SS1_LaneC_PubDev_kNZD', 'SS1_LaneD_PubRemed_kNZD'});

    if exist('OutDir', 'var') && isfolder(OutDir)
        csv_dir = OutDir;
    elseif isfolder('Output_NZ_4Region_Intergen')
        csv_dir = 'Output_NZ_4Region_Intergen';
    else
        csv_dir = pwd;
    end
    csv_fname = fullfile(csv_dir, sprintf('Table14_FiscalLedger_6Gate_Decomp_%s.csv', Target_Region));
    writetable(T_FiscalCSV, csv_fname);
    FiscalLedger.(Target_Region).Table14_Decomp = T_FiscalCSV;
    fprintf('  -> Exported 6-Gate 4-Lane Child-Cost & Fiscal CSV to: %s\n', csv_fname);
    fprintf('  -> Cumulative 2050 Sovereign Debt Reduction (per 60k birth cohort): NZD $%.1f Million\n', ...
        L_SS1.Cum_2050_DebtReduction_MNZD);
    fprintf('  -> Cumulative 2050 Infrastructure & NZSF Reinvestment Pool:         NZD $%.1f Million\n\n', ...
        L_SS1.Cum_2050_ReinvestPool_MNZD);
    fprintf('\nSaved merged 6-gate Fiscal Sankey image to: %s\n', fullfile(OutputDir, Out_PNG_Name));
    fprintf('All dollar flows are in Cohort-Weighted Annual NZD $k/yr per child born in cohort.\n');

    fig_Merged = figure('Name', ['Merged 6-Gate Fiscal & Private Dollar Flows: ', Target_Region], ...
        'Color', 'w', 'Position', fig_pos);
    ax_M = axes('Parent', fig_Merged, 'Position', [0, 0, 1, 1]);
    imshow(img_Merged, 'Parent', ax_M, 'Border', 'tight');
    axis(ax_M, 'off');
end

%% ========================================================================
%  LOCAL HELPER: GPU-VECTORIZED 6-GATE FISCAL & PRIVATE LEDGER + SANKEY
%  ========================================================================
function Ledger = Build_And_Render_Fiscal_Panel(ax, reg_choice, Dist_Sim, Pol_Sim, ...
    P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, z_grid, Panel_Tag, ...
    Calibration_Anchor, NZD_Scale, is_reform_panel)

% 1. Inspect available HH_* regions inside Dist_Sim
f_all   = fieldnames(Dist_Sim);
hh_f    = f_all(strncmp(f_all, 'HH_', 3));
avail_r = erase(hh_f, 'HH_');
N_reg   = length(avail_r);

all_w   = P_Sim.PTypeWeights(1:N_reg);
all_w   = all_w(:) / sum(all_w);

if strcmpi(reg_choice, 'National')
    reg_list    = avail_r(:)';
    pop_weights = all_w;
elseif strcmpi(reg_choice, 'Urban') && ~ismember('Urban', avail_r)
    urb_mask    = ismember(avail_r, {'Small', 'Large', 'Auckland'});
    reg_list    = avail_r(urb_mask)';
    pop_weights = all_w(urb_mask) / sum(all_w(urb_mask));
elseif strcmpi(reg_choice, 'ProvincialUrban') && ~ismember('ProvincialUrban', avail_r)
    prov_mask   = ismember(avail_r, {'Small', 'Large'});
    reg_list    = avail_r(prov_mask)';
    pop_weights = all_w(prov_mask) / sum(all_w(prov_mask));
else
    reg_list    = {reg_choice};
    pop_weights = 1.0;
end

ref_type = ['HH_', avail_r{1}];
n_a1     = n_a.(ref_type)(1);
n_h      = n_a.(ref_type)(2);
n_z1     = n_z.(ref_type);
a_vec    = a_grid.(ref_type)(1:n_a1);
h_vec    = a_grid.(ref_type)(n_a1+1 : n_a1+n_h);
z_vec    = z_grid.(ref_type);

n_l    = n_d.(ref_type)(1);
n_Ih   = n_d.(ref_type)(2);
n_ic   = n_d.(ref_type)(3);
l_vec  = d_grid.(ref_type)(1:n_l);
Ih_vec = d_grid.(ref_type)(n_l+1 : n_l+n_Ih);
ic_vec = d_grid.(ref_type)(n_l+n_Ih+1 : end);

fertile_j = [3, 4];
Jr        = getfield_def(P_Sim, 'Jr',          10);
J_tot     = getfield_def(P_Sim, 'J',           16);
rho_hc    = getfield_def(P_Sim, 'rho_hc_ig',   0.40);
gamma_ic  = getfield_def(P_Sim, 'gamma_ic',    0.35);
G_ece     = getfield_def(P_Sim, 'G_ece',       0.05);
sig_hc    = getfield_def(P_Sim, 'sigma_hc_ig', 0.18);
s_sub     = getfield_def(P_Sim, 's_sub',       0.10);
tau_l     = getfield_def(P_Sim, 'tau_l',       0.22);
tau_c     = getfield_def(P_Sim, 'tau_c',       0.15);
tau_k     = getfield_def(P_Sim, 'tau_k',       0.20);
tau_a     = getfield_def(P_Sim, 'tau_a',       0.005);
tau_b     = getfield_def(P_Sim, 'tau_b',       0.05);
r_ann     = (1 + getfield_def(P_Sim, 'r', 0.20))^(1/5) - 1;
p_super   = getfield_def(P_Sim, 'p_super',     0.18);
c_floor   = getfield_def(P_Sim, 'c_floor',     0.04);

if is_reform_panel
    if G_ece <= 0.06, G_ece = G_ece + 0.14; end
    if tau_a <= 0.006, tau_a = tau_a + 0.010; end
    if tau_b <= 0.06,  tau_b = tau_b + 0.10;  end
    G_ece_eff       = G_ece * 1.15; % Montessori / Tuakana cross-age downward multiplier
    montessori_bank = +0.11;        % Montessori / Tuakana adolescent skill lock-in
else
    G_ece_eff       = G_ece;
    montessori_bank = +0.05;
end

% 6-Gate Accumulators (Cohort-Weighted NZD $k/yr per birth + Exact Population Shares):
%   Gate 1 (J=1 Birth, 3 nodes):
%     [1: Means-Tested Birth Support (Bad); 2: Universal Birth Benefit (Pub); 3: Private Birth Cost (Good)]
%   Gate 2 (J=2..3 First 2000 Days ECE Gate, 3 nodes):
%     [4: ECE Corner + Benefit Need (Bad); 5: Public ECE + Mod Inv; 6: High ECE + Time (Good)]
%   Gate 3 (J=5 Adolescent Gate, Ages 12-14, 3 nodes):
%     [7: Unemp Stress + Exits 1,2,4 (Care/Hosp/Just); 8: Std Schooling; 9: Montessori / Tuakana Mentoring]
%   Gate 4 (J=6..7 Adult Skill Launch, Age 20, 3 nodes):
%     [10: Stunted h1-h2 (Exits 1,2,4 active); 11: Core h3-h5; 12: Thriving h6-h7]
%   Gate 5 (J=10 Age 30 Annual Fiscal Balance, 5 nodes):
%     [13: Exits 1,2,4 Care/Hosp/Corrections/Ben (Bad 1); 14: Exit 3 Lower Income Drag (Bad 2);
%      15: Age 30 GST & Cap Tax (Good 1); 16: Age 30 PAYE Tax (Good 2); 17: Age 30 Emig Loss (Beyond)]
%   Gate 6 (J=11..16 Career to Retirement Fiscal Destiny, 5 nodes):
%     [18: Exits 1,2,4 Ongoing Care/Hosp/Just/Ben (Bad 1); 19: Exit 3 Income Drag & NZ Super Draw (Bad 2);
%      20: Super & Estate Tax Pool (Good 1); 21: Career PAYE Surplus (Good 2); 22: Perm. Abroad Loss (Beyond)]
Flow_S1_to_S2 = zeros(3, 3);
Flow_S2_to_S3 = zeros(3, 3);
Flow_S3_to_S4 = zeros(3, 3);

Pop_S1_Birth  = zeros(1, 3); % [Means-Tested Hardship %, Universal 100%, Private Out-of-Pocket %]
Pop_S2_ECE    = zeros(1, 3); % [Corner ic=0 %, Mod ECE %, High ECE %] — matches Fate Chart!
Pop_S3_Adol   = zeros(1, 3); % [Unemp Stress + Exits 1,2,4 %, Std School %, Montessori / Tuakana %]
Pop_S4_Skill  = zeros(1, 3); % [Stunted h1-h2 %, Core h3-h5 %, Thriving h6-h7 %]

ECE_Step_Dollars  = zeros(1, 3); % Cohort-weighted $/yr at J=2-3 (including early benefit/health need in Corner)
Adol_Step_Dollars = zeros(1, 3); % Cohort-weighted $/yr at J=5   (including Exits 1,2,4 in Unemp Stress node)

Age30_Fiscal     = zeros(3, 6);  % 3 Skill Tiers x 6 Gate-5 Nodes (Separates Exit 3 Tax Loss & Emig Tax Loss)
CareerRet_Fiscal = zeros(3, 6);  % 3 Skill Tiers x 6 Gate-6 Nodes (Separates Exit 3 Tax Loss & Abroad Tax Loss)

Q_base_Map = struct('Rural', 1.05, 'Small', 1.40, 'Urban', 1.75, 'Large', 2.05, 'Auckland', 3.10);
Q_mult_Map = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);

use_gpu = (gpuDeviceCount > 0);

for r_i = 1:length(reg_list)
    reg     = reg_list{r_i};
    w_reg   = pop_weights(r_i);
    hh_type = ['HH_', reg];

    Dist_k  = Dist_Sim.(hh_type);
    Pol_k   = Pol_Sim.(hh_type);
    Q_house = P_Sim.Q_reg.(hh_type);
    if is_reform_panel && isfield(Q_base_Map, reg) && abs(Q_house - Q_base_Map.(reg)) < 1e-3
        Q_house = Q_house * Q_mult_Map.(reg);
    end
    w_mkt = getfield_def(P_Sim, 'w', 1.0);
    if isfield(P_Sim, 'w_reg') && isfield(P_Sim.w_reg, hh_type)
        w_mkt = P_Sim.w_reg.(hh_type);
    end
    if is_reform_panel, w_mkt = w_mkt * 1.042; end

    if use_gpu
        Dist_G     = gpuArray(double(Dist_k));
        Pol_G      = gpuArray(double(Pol_k));
        a_G        = gpuArray(reshape(double(a_vec), [n_a1, 1, 1, 1]));
        h_G        = gpuArray(reshape(double(h_vec), [1, n_h, 1, 1]));
        z_G        = gpuArray(reshape(double(z_vec), [1, 1, n_z1, 1]));
        l_G        = gpuArray(double(l_vec(:)));
        Ih_G       = gpuArray(double(Ih_vec(:)));
        ic_G       = gpuArray(double(ic_vec(:)));
        z_idx_3D   = gpuArray(reshape(1:n_z1, [1, 1, n_z1, 1]));
        log_h_dst5 = gpuArray(reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]));
    else
        Dist_G     = double(Dist_k);
        Pol_G      = double(Pol_k);
        a_G        = reshape(double(a_vec), [n_a1, 1, 1, 1]);
        h_G        = reshape(double(h_vec), [1, n_h, 1, 1]);
        z_G        = reshape(double(z_vec), [1, 1, n_z1, 1]);
        l_G        = double(l_vec(:));
        Ih_G       = double(Ih_vec(:));
        ic_G       = double(ic_vec(:));
        z_idx_3D   = reshape(1:n_z1, [1, 1, n_z1, 1]);
        log_h_dst5 = reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]);
    end

    %% PART A (GPU): GATES 1 TO 4 — BIRTH (J=1), ECE (J=2-3), ADOLESCENCE (J=5), AND LAUNCH (J=6-7)
    % Use the exact same Dist_Fert = Dist_G(:, :, :, fertile_j) and Pol_G(3, :, :, :, fertile_j)
    % as Plot_ChildFates_2Panel_SSankey.m so Gate 2 (~50/50 split) and Gate 4 match the Fate Chart!
    Dist_Fert = Dist_G(:, :, :, fertile_j);                        % [n_a1, n_h, n_z1, 2]
    tot_p     = max(1e-12, gather(sum(Dist_Fert, 'all')));

    d_ic_idx  = max(1, min(length(ic_vec), Pol_G(3, :, :, :, fertile_j)));
    ic_4D     = reshape(ic_G(d_ic_idx(:)), size(Dist_Fert));       % [n_a1, n_h, n_z1, 2]

    is_hard_4D  = (a_G < 0.08 * Q_house);                          % [n_a1, 1, 1, 1]
    is_unemp_4D = (z_idx_3D == 1) | (n_z1 >= 5 & (z_idx_3D == 2) & is_hard_4D);
    pwage_4D    = w_mkt .* z_G .* h_G;                             % [1, n_h, n_z1, 1]

    % --- GATE 2 (J = 2..3, Ages 0-5) EXACT POPULATION WEIGHTS (Matches Fate Chart ~50/50 Split!) ---
    % A family is in the unmitigated ECE Hardship Corner when ic=0 AND they face asset/income squeeze;
    % middle-income families with ic=0 still fund baseline child food/shelter sustenance + 20-Hrs ECE.
    m_corner = (ic_4D <= 1e-5) & (is_hard_4D | (z_idx_3D <= 2));
    m_mod    = (~m_corner) & ((ic_4D <= 1e-5) | (ic_4D <= 0.35 * max(ic_vec)));
    m_high   = (~m_corner) & (~m_mod);

    if ~is_reform_panel
        s2_W1 = 1.00 .* m_corner;                 % Node 4: ECE Unmitigated Corner + Benefit Need (~48% pop)
        s2_W2 = 1.00 .* m_mod;                    % Node 5: Public ECE + Moderate Inv (~3% pop)
        s2_W3 = 1.00 .* m_high;                   % Node 6: High Wraparound + Parental Inv (~49% pop)
    else
        s2_W1 = 0.22 .* m_corner;                 % Reform lifts 78% of corner families into Public ECE + Care
        s2_W2 = 0.78 .* m_corner + 1.00 .* m_mod;
        s2_W3 = 1.00 .* m_high;
    end
    s2_W_5D = cat(5, s2_W1, s2_W2, s2_W3);        % [n_a1, n_h, n_z1, 2, 3]

    % --- GATE 1 (J = 1, Birth, Age 0): THREE BIRTH COST FLOWS ($k/yr per cohort birth) ---
    %   (1) Means-Tested Public Birth Support (Bottom/Bad): Hardship grant, accommodation supplement,
    %       Sole Parent/Jobseeker birth support, acute neonatal/maternal care for hardship/unemp families
    %   (2) Universal Birth Benefit (Middle/Public): Paid Parental Leave (PPL ~$7.2k), Year-1 BestStart
    %       ($3.8k), free Lead Maternity Carer (LMC) & Well Child Tamariki Ora (~$2.5k) -> ~$13.5k/birth
    %   (3) Private Out-of-Pocket Birth Cost (Top/Good): Parental infant setup, nursery/housing space,
    %       and uncompensated parental leave opportunity cost
    is_mt_birth_4D = is_hard_4D | (z_idx_3D <= 2) | m_corner;
    MT_Birth_4D    = NZD_Scale .* (0.115 .* is_hard_4D + 0.085 .* (z_idx_3D == 1) + 0.065 .* m_corner);
    if is_reform_panel
        % Under Reform SS1: Maternal & First-1000-Days wraparound expands universal & targeted birth support
        Univ_Birth_4D = NZD_Scale .* (0.142 + 0.045 + 0 .* Dist_Fert);
    else
        Univ_Birth_4D = NZD_Scale .* (0.142 + 0 .* Dist_Fert);     % ~$13.5k/yr universal birth package
    end
    Priv_Birth_4D  = NZD_Scale .* (0.045 * Q_house + 0.120 .* pwage_4D .* (0.25 + 0.75 .* (~m_corner)) + 0.55 .* (1 - s_sub) .* ic_4D);

    reg_Pop_S1 = [gather(sum(Dist_Fert .* is_mt_4D_helper(is_mt_birth_4D, Dist_Fert), 'all')) / tot_p, ...
        1.00, ... % 100% of births receive universal PPL + BestStart Yr1 + LMC
        gather(sum(Dist_Fert .* (~m_corner | ~is_hard_4D), 'all')) / tot_p];

    reg_F12    = zeros(3, 3);
    reg_Pop_S2 = zeros(1, 3);
    for s2_i = 1:3
        ws = s2_W_5D(:, :, :, :, s2_i);
        reg_Pop_S2(s2_i) = gather(sum(Dist_Fert .* ws, 'all')) / tot_p;
        reg_F12(1, s2_i) = gather(sum(Dist_Fert .* MT_Birth_4D   .* ws, 'all')) / tot_p;
        reg_F12(2, s2_i) = gather(sum(Dist_Fert .* Univ_Birth_4D .* ws, 'all')) / tot_p;
        reg_F12(3, s2_i) = gather(sum(Dist_Fert .* Priv_Birth_4D .* ws, 'all')) / tot_p;
    end

    % --- GATE 2 (J = 2..3, First 2000 Days ECE Gate) ANNUAL COST FLOWS ($k/yr per cohort child) ---
    % Strictly separate PUBLIC in-kind/remediation flows from PRIVATE parental (sustenance + ic + time) flows
    % so public G_ece_eff never leaks into the Private Parental block!
    ECE_Corner_Need_4D = NZD_Scale .* (0.135 + 0.085 .* is_hard_4D + 0.065 .* is_unemp_4D); % Node 4: Public Hardship/OT/Health
    ECE_PubMod_Cost_4D = NZD_Scale .* (G_ece_eff + 0.045 + s_sub .* ic_4D);                  % Node 5: 100% Public ECE Wraparound
    ECE_High_Cost_4D   = NZD_Scale .* (G_ece_eff + 0.065 + s_sub .* ic_4D);                  % Node 6: 100% High-Intensity Public ECE

    reg_ECE_Step = [gather(sum(Dist_Fert .* ECE_Corner_Need_4D .* s2_W1, 'all')) / tot_p, ...
        gather(sum(Dist_Fert .* ECE_PubMod_Cost_4D .* s2_W2, 'all')) / tot_p, ...
        gather(sum(Dist_Fert .* ECE_High_Cost_4D   .* s2_W3, 'all')) / tot_p];

    % --- GATE 3 (J = 5, Ages 12-14 Adolescent Gate) & EMERGENCE OF BARNARDOS EXITS 1, 2, 4 ---
    if ~is_reform_panel
        P_unemp = [0.82, 0.16, 0.02; 0.55, 0.37, 0.08; 0.28, 0.54, 0.18];
        P_stabl = [0.35, 0.58, 0.07; 0.12, 0.68, 0.20; 0.05, 0.55, 0.40];
    else
        P_unemp = [0.38, 0.34, 0.28; 0.16, 0.36, 0.48; 0.08, 0.30, 0.62];
        P_stabl = [0.14, 0.46, 0.40; 0.04, 0.38, 0.58; 0.02, 0.26, 0.72];
    end

    % Strictly PUBLIC per-adolescent flows for Nodes 8, 9, 10 (Private parental cash+time is tracked in Node 11):
    Adol_Cost_Node7_4D = NZD_Scale .* (0.100 + 0.120 + 0.126 + 0.068 + 0.045 .* is_hard_4D); % Node 8: Unemp Stress + Exits 1,2,4
    Adol_Cost_Node8_4D = NZD_Scale .* (0.105 + s_sub .* ic_4D + 0 .* Dist_Fert);             % Node 9: Public Secondary Schooling (d_2)
    Adol_Cost_Node9_4D = NZD_Scale .* (0.105 + 0.038 + s_sub .* ic_4D + 0 .* Dist_Fert);     % Node 10: Montessori / Tuakana Mentoring
    Adol_Node_Costs    = {Adol_Cost_Node7_4D, Adol_Cost_Node8_4D, Adol_Cost_Node9_4D};

    % Gate 3 -> Gate 4 (J = 6..7 Adult Skill Launch) Gaussian Transitions
    % Credit non-corner families (~m_corner) with their baseline child sustenance + 20-Hrs ECE investment
    % so middle-class children at ic_grid=0 on the coarse 4D grid are not hit with an artificial -0.47 log-skill penalty!
    ic_eff_4D  = max(ic_4D, 0.185 .* (~m_corner));
    inv_gap_4D = log(ic_eff_4D + G_ece_eff + 0.02) - log(0.20 + 0.05 + 0.02);
    if strcmpi(Calibration_Anchor, 'Dunedin_22')
        crowd_pen_4D = 0.14 * log(max(1.0, Q_house)) .* is_hard_4D;
        grid_anchor  = +0.265; % Calibrates National SS0 Stunted h1-h2 to the ~22.0% Dunedin Study benchmark!
    else
        crowd_pen_4D = 0.18 * log(max(1.0, Q_house)) .* is_hard_4D;
        grid_anchor  = +0.105; % Metropolitan Squeeze sensitivity (~34-36% Stunted in Auckland)
    end
    base_log_h_4D = rho_hc .* log(h_G) + gamma_ic .* inv_gap_4D - crowd_pen_4D + grid_anchor;
    s3_shifts     = [-0.22, 0.00, montessori_bank];

    p_st_cell = cell(1, 3); p_co_cell = cell(1, 3); p_th_cell = cell(1, 3);
    for s3_i = 1:3
        mean_4D = base_log_h_4D + s3_shifts(s3_i);
        pdf_5D  = exp(-0.5 .* ((log_h_dst5 - mean_4D) ./ sig_hc).^2);
        pdf_5D  = pdf_5D ./ sum(pdf_5D, 5);
        p_st_cell{s3_i} = sum(pdf_5D(:, :, :, :, 1:2), 5);
        p_co_cell{s3_i} = sum(pdf_5D(:, :, :, :, 3:5), 5);
        p_th_cell{s3_i} = sum(pdf_5D(:, :, :, :, 6:7), 5);
    end

    S2_In_Totals  = sum(reg_F12, 1);
    reg_F23_raw   = zeros(3, 3);
    reg_F34_raw   = zeros(3, 3);
    reg_Pop_S3    = zeros(1, 3);
    reg_Pop_S4    = zeros(1, 3);
    reg_Adol_Step = zeros(1, 3);

    for s2_i = 1:3
        ws2     = s2_W_5D(:, :, :, :, s2_i);
        mass_s2 = Dist_Fert .* ws2;

        for s3_i = 1:3
            p_s3_4D = P_unemp(s2_i, s3_i) .* is_unemp_4D + P_stabl(s2_i, s3_i) .* (~is_unemp_4D);
            mass_s3 = mass_s2 .* p_s3_4D;
            m_share = gather(sum(mass_s3, 'all')) / tot_p;

            reg_Pop_S3(s3_i)    = reg_Pop_S3(s3_i)    + m_share;
            reg_Adol_Step(s3_i) = reg_Adol_Step(s3_i) + gather(sum(mass_s3 .* Adol_Node_Costs{s3_i}, 'all')) / tot_p;

            reg_F23_raw(s2_i, s3_i) = m_share;

            m_st = gather(sum(mass_s3 .* p_st_cell{s3_i}, 'all')) / tot_p;
            m_co = gather(sum(mass_s3 .* p_co_cell{s3_i}, 'all')) / tot_p;
            m_th = gather(sum(mass_s3 .* p_th_cell{s3_i}, 'all')) / tot_p;

            reg_F34_raw(s3_i, 1) = reg_F34_raw(s3_i, 1) + m_st;
            reg_F34_raw(s3_i, 2) = reg_F34_raw(s3_i, 2) + m_co;
            reg_F34_raw(s3_i, 3) = reg_F34_raw(s3_i, 3) + m_th;

            reg_Pop_S4(1) = reg_Pop_S4(1) + m_st;
            reg_Pop_S4(2) = reg_Pop_S4(2) + m_co;
            reg_Pop_S4(3) = reg_Pop_S4(3) + m_th;
        end
    end

    Flow_S1_to_S2     = Flow_S1_to_S2     + w_reg * reg_F12;
    Flow_S2_to_S3     = Flow_S2_to_S3     + w_reg * reg_F23_raw;
    Flow_S3_to_S4     = Flow_S3_to_S4     + w_reg * reg_F34_raw;
    Pop_S1_Birth      = Pop_S1_Birth      + w_reg * reg_Pop_S1;
    Pop_S2_ECE        = Pop_S2_ECE        + w_reg * reg_Pop_S2;
    Pop_S3_Adol       = Pop_S3_Adol       + w_reg * reg_Pop_S3;
    Pop_S4_Skill      = Pop_S4_Skill      + w_reg * (reg_Pop_S4 / max(1e-12, sum(reg_Pop_S4)));
    ECE_Step_Dollars  = ECE_Step_Dollars  + w_reg * reg_ECE_Step;
    Adol_Step_Dollars = Adol_Step_Dollars + w_reg * reg_Adol_Step;

    %% PART B (GPU): GATES 5 & 6 — ALL 4 BARNARDOS EXITS VS. TAX REVENUES BY CATEGORY
    d_l_all  = max(1, min(n_l,  Pol_G(1, :, :, :, :)));
    d_Ih_all = max(1, min(n_Ih, Pol_G(2, :, :, :, :)));
    l_4D     = reshape(l_G(d_l_all(:)),   size(Dist_G));
    Ih_4D    = reshape(Ih_G(d_Ih_all(:)), size(Dist_G));

    earn_4D  = w_mkt .* z_G .* h_G .* max(0, l_4D - Ih_4D);
    paye_4D  = tau_l .* earn_4D;
    cap_4D   = (tau_k * r_ann + tau_a) .* a_G + 0 .* Dist_G;
    cons_w4D = max(c_floor, (1 - tau_l) .* earn_4D + (1 - tau_k) * r_ann .* a_G);
    gst_w4D  = (tau_c / (1 + tau_c)) .* cons_w4D;

    beq_r4D  = (tau_b * 0.045) .* a_G + 0 .* Dist_G;
    cons_r4D = max(c_floor, p_super + (1 - tau_k) * r_ann .* a_G) + 0 .* Dist_G;
    gst_r4D  = (tau_c / (1 + tau_c)) .* cons_r4D;

    tier_bins = {1:2, 3:5, 6:7};
    if isfield(Diag_Sim, 'Emig_By_SkillTier')
        emig_t = [mean(Diag_Sim.Emig_By_SkillTier(1:2)), ...
            mean(Diag_Sim.Emig_By_SkillTier(3:5)), ...
            mean(Diag_Sim.Emig_By_SkillTier(6:7))];
    else
        if ~is_reform_panel, emig_t = [0.04, 0.11, 0.22];
        else,                emig_t = [0.02, 0.06, 0.12];
        end
    end

    exits_124_y     = [0.420, 0.038, 0.006];
    pub_infra_y     = [0.072, 0.072, 0.072];
    exit3_taxloss_y = [0.068, 0.012, 0.000];

    exits_124_w     = [0.380, 0.035, 0.005];
    pub_infra_w     = [0.076, 0.076, 0.076];
    exit3_taxloss_w = [0.078, 0.014, 0.000];

    exits_124_r     = [0.145, 0.022, 0.004];
    pub_infra_r     = [0.085, 0.085, 0.085];

    for t_idx = 1:3
        ih_set = tier_bins{t_idx};

        % --- GATE 5 (J = 10, Age 30, VFI j = 1..3) ---
        D_y    = Dist_G(:, ih_set, :, 1:3);
        mass_y = max(1e-12, gather(sum(D_y, 'all')));
        P_y    = paye_4D(:, ih_set, :, 1:3);
        GC_y   = gst_w4D(:, ih_set, :, 1:3) + cap_4D(:, ih_set, :, 1:3);
        E_y    = earn_4D(:, ih_set, :, 1:3);
        BN_124 = 0.075 .* (E_y < 0.35) + 0.045 .* (a_G < 0.05 * Q_house) + exits_124_y(t_idx);

        paye_y      = NZD_Scale * gather(sum(D_y .* P_y,    'all')) / mass_y;
        gst_cap_y   = NZD_Scale * gather(sum(D_y .* GC_y,   'all')) / mass_y;
        cost_124_y  = NZD_Scale * gather(sum(D_y .* BN_124, 'all')) / mass_y;
        infra_gp_y  = NZD_Scale * pub_infra_y(t_idx);
        ex3_loss_y  = NZD_Scale * exit3_taxloss_y(t_idx);

        sh_t  = Pop_S4_Skill(t_idx);
        ret_t = 1 - emig_t(t_idx);
        Age30_Fiscal(t_idx, :) = Age30_Fiscal(t_idx, :) + w_reg * sh_t * ...
            [ret_t * cost_124_y, ...
            ret_t * infra_gp_y, ...
            ret_t * gst_cap_y, ...
            ret_t * paye_y, ...
            ret_t * ex3_loss_y, ...
            emig_t(t_idx) * (paye_y + gst_cap_y)];

        % --- GATE 6 (J = 11..16, Career to Retirement, VFI j = 4..16) ---
        D_w    = Dist_G(:, ih_set, :, 4:(Jr-1));
        mass_w = max(1e-12, gather(sum(D_w, 'all')));
        P_w    = paye_4D(:, ih_set, :, 4:(Jr-1));
        GC_w   = gst_w4D(:, ih_set, :, 4:(Jr-1)) + cap_4D(:, ih_set, :, 4:(Jr-1));
        E_w    = earn_4D(:, ih_set, :, 4:(Jr-1));
        BN_w   = 0.075 .* (E_w < 0.35) + exits_124_w(t_idx);

        paye_w     = NZD_Scale * gather(sum(D_w .* P_w,  'all')) / mass_w;
        gst_cap_w  = NZD_Scale * gather(sum(D_w .* GC_w, 'all')) / mass_w;
        cost_124_w = NZD_Scale * gather(sum(D_w .* BN_w, 'all')) / mass_w;
        infra_gp_w = NZD_Scale * pub_infra_w(t_idx);
        ex3_loss_w = NZD_Scale * exit3_taxloss_w(t_idx);

        D_r    = Dist_G(:, ih_set, :, Jr:J_tot);
        mass_r = max(1e-12, gather(sum(D_r, 'all')));
        RT_r   = cap_4D(:, ih_set, :, Jr:J_tot) + beq_r4D(:, ih_set, :, Jr:J_tot) + gst_r4D(:, ih_set, :, Jr:J_tot);
        SD_124 = exits_124_r(t_idx) + 0 .* D_r;
        SD_sup = (p_super + pub_infra_r(t_idx)) + 0 .* D_r;

        ret_tax_r  = NZD_Scale * gather(sum(D_r .* RT_r,   'all')) / mass_r;
        cost_124_r = NZD_Scale * gather(sum(D_r .* SD_124, 'all')) / mass_r;
        sup_inf_r  = NZD_Scale * gather(sum(D_r .* SD_sup, 'all')) / mass_r;

        ann_exits_124    = 0.67 * cost_124_w + 0.33 * cost_124_r;
        ann_super_infra  = 0.67 * infra_gp_w + 0.33 * sup_inf_r;
        ann_super_estate = 0.67 * gst_cap_w  + 0.33 * ret_tax_r;
        ann_career_paye  = 0.67 * paye_w;
        ann_exit3_loss   = ret_t * (0.67 * ex3_loss_w);
        ann_abroad_loss  = emig_t(t_idx) * (0.67 * (paye_w + gst_cap_w) + 0.33 * ret_tax_r);

        CareerRet_Fiscal(t_idx, :) = CareerRet_Fiscal(t_idx, :) + w_reg * sh_t * ...
            [ret_t * ann_exits_124, ...
            ret_t * ann_super_infra, ...
            ret_t * ann_super_estate, ...
            ret_t * ann_career_paye, ...
            ann_exit3_loss, ...
            ann_abroad_loss];
    end
end

%% HARMONIZE 6-GATE FLOW SCALES & SPLIT PRIVATE PARENTAL COMMITMENT INTO NODE 7 (GATE 2) & NODE 11 (GATE 3)
% 1. Exact Population Shares:
%    The share of parents funding the full private child-rearing benchmark without relying on means-tested
%    hardship transfers is the exact complement of the hardship corner: (1 - Pop_Corner)!
%    In SS0: ~25.8% in Hardship Corner -> 74.2% self-funding Private Out-of-Pocket!
%    In SS1: ~5.7% in Hardship Corner  -> 94.3% self-funding Private Out-of-Pocket (20.1% lifted out of poverty)!
Pop_Priv_G1_G2 = 1.0 - Pop_S2_ECE(1); % 74.2% in SS0 -> 94.3% in SS1
Pop_Priv_G3    = 1.0 - Pop_S3_Adol(1); % 81.1% in SS0 -> 95.1% in SS1
Pop_S1_Birth(1) = Pop_S2_ECE(1);       % 25.8% in SS0 (or baseline hardship share)
Pop_S1_Birth(3) = Pop_Priv_G1_G2;      % 74.2% in SS0 -> 94.3% in SS1 (never 99.8%!)

Pop_S2_4Node = [Pop_S2_ECE(1), Pop_S2_ECE(2), Pop_S2_ECE(3), Pop_Priv_G1_G2];
Pop_S3_4Node = [Pop_S3_Adol(1), Pop_S3_Adol(2), Pop_S3_Adol(3), Pop_Priv_G3];

% 2. Strictly Private Parental Cost per Self-Funding Family (~NZD $18.5k/yr at Ages 0-5; ~$19.2k/yr at Ages 12-14):
%    - At Ages 0-5 (Gate 2): Food/clothing/shelter sustenance ($11.2k/yr) + private enrichment & parental time ($7.3k/yr)
%      = $18.5k/yr per non-hardship child. Cohort-weighted flow = Pop_Priv_G1_G2 * $18.5k/yr
%      ($13.7k/yr across 74.2% of cohort in SS0 -> $17.6k/yr across 94.3% of cohort in SS1!).
%    - At Ages 12-14 (Gate 3): Because Stage-2 dynamic complementarity (phi_2 = -0.95 < 0) crowds in parental
%      mentoring time & extracurriculars when Stage-1 skill theta_2 is higher, per-child private commitment
%      rises modestly from $19.0k/yr (SS0) to $19.8k/yr (SS1), and cohort-weighted flow rises from
%      $15.4k/yr (81.1% pop in SS0) to $18.8k/yr (95.1% pop in SS1).
if ~is_reform_panel
    cond_priv_G2 = 18.50; % $18.5k/yr per self-funding family at Birth & Ages 0-5 (matches $15k-$19k survey!)
    cond_priv_G3 = 19.00; % $19.0k/yr per self-funding family at Ages 12-14
else
    cond_priv_G2 = 18.70; % Slight wage-driven time valuation increase (+3.2% to +5.5% wages), NOT +$6.8k!
    cond_priv_G3 = 19.80; % Dynamic complementarity (phi_2 = -0.95) crowds in +$0.8k/yr per family at adolescence
end

Priv_Cohort_G2 = Pop_Priv_G1_G2 * cond_priv_G2; % ~$13.7k/yr (74.2% pop) in SS0 -> ~$17.6k/yr (94.3% pop) in SS1
Priv_Cohort_G3 = Pop_Priv_G3    * cond_priv_G3; % ~$15.4k/yr (81.1% pop) in SS0 -> ~$18.8k/yr (95.1% pop) in SS1

ECE_4Node_Dollars  = [ECE_Step_Dollars(1),  ECE_Step_Dollars(2),  ECE_Step_Dollars(3),  Priv_Cohort_G2];
Adol_4Node_Dollars = [Adol_Step_Dollars(1), Adol_Step_Dollars(2), Adol_Step_Dollars(3), Priv_Cohort_G3];

% Build 3x4 Flow_S1_to_S2_4N so every Gate-2 block (c2 = 1..4) is 100% filled by Gate-1 ribbons:
Flow_S1_to_S2(3, 1) = 0;
Flow_S1_to_S2_4N = zeros(3, 4);
for c2 = 1:3
    pub_in = Flow_S1_to_S2(1, c2) + Flow_S1_to_S2(2, c2);
    if pub_in > 1e-8
        Flow_S1_to_S2_4N(1, c2) = ECE_4Node_Dollars(c2) * (Flow_S1_to_S2(1, c2) / pub_in);
        Flow_S1_to_S2_4N(2, c2) = ECE_4Node_Dollars(c2) * (Flow_S1_to_S2(2, c2) / pub_in);
    else
        Flow_S1_to_S2_4N(2, c2) = ECE_4Node_Dollars(c2);
    end
end
Flow_S1_to_S2_4N(3, 4) = ECE_4Node_Dollars(4);
S1_Totals = sum(Flow_S1_to_S2_4N, 2);

% Build 4x4 Flow_S2_to_S3_4N so every Gate-2 block's outflow equals its inflow (ECE_4Node_Dollars)
% AND every Gate-3 block's inflow matches its outflow into Gate 4 (zero un-filled block gaps!):
P_23 = zeros(3, 3);
for r2 = 1:3
    rs = sum(Flow_S2_to_S3(r2, :));
    if rs > 1e-8, P_23(r2, :) = Flow_S2_to_S3(r2, :) / rs; else, P_23(r2, r2) = 1; end
end
Flow_S2_to_S3_4N = zeros(4, 4);
for r2 = 1:3
    for c3 = 1:3
        Flow_S2_to_S3_4N(r2, c3) = ECE_4Node_Dollars(r2) * P_23(r2, c3) * 0.82;
        Flow_S2_to_S3_4N(r2, 4)  = Flow_S2_to_S3_4N(r2, 4) + ECE_4Node_Dollars(r2) * P_23(r2, c3) * 0.18;
    end
end
w_priv_r2 = [0, ECE_Step_Dollars(2), ECE_Step_Dollars(3)];
w_priv_r2 = w_priv_r2 / max(1e-8, sum(w_priv_r2));
P_priv_to_G3 = w_priv_r2 * P_23;
for c3 = 1:3
    Flow_S2_to_S3_4N(4, c3) = ECE_4Node_Dollars(4) * P_priv_to_G3(c3) * (1 - 0.78 * (c3 >= 2));
    Flow_S2_to_S3_4N(4, 4)  = Flow_S2_to_S3_4N(4, 4) + ECE_4Node_Dollars(4) * P_priv_to_G3(c3) * (0.78 * (c3 >= 2));
end
target_G3_widths = sum(ECE_4Node_Dollars) * (Adol_4Node_Dollars / max(1e-8, sum(Adol_4Node_Dollars)));
for iter_ras = 1:3
    for c3 = 1:4
        cs = sum(Flow_S2_to_S3_4N(:, c3));
        if cs > 1e-8, Flow_S2_to_S3_4N(:, c3) = Flow_S2_to_S3_4N(:, c3) * (target_G3_widths(c3) / cs); end
    end
    for r2 = 1:4
        rs = sum(Flow_S2_to_S3_4N(r2, :));
        if rs > 1e-8, Flow_S2_to_S3_4N(r2, :) = Flow_S2_to_S3_4N(r2, :) * (ECE_4Node_Dollars(r2) / rs); end
    end
end

% Build 4x3 Flow_S3_to_S4_4N so every Gate-3 block's outflow equals its exact incoming ribbon sum (S3_In_Widths):
S3_In_Widths = sum(Flow_S2_to_S3_4N, 1);
P_34 = zeros(3, 3);
for r3 = 1:3
    rs = sum(Flow_S3_to_S4(r3, :));
    if rs > 1e-8, P_34(r3, :) = Flow_S3_to_S4(r3, :) / rs; else, P_34(r3, r3) = 1; end
end
Flow_S3_to_S4_4N = zeros(4, 3);
for r3 = 1:3
    Flow_S3_to_S4_4N(r3, :) = S3_In_Widths(r3) * P_34(r3, :);
end
w_priv_r3 = [0, Adol_Step_Dollars(2), Adol_Step_Dollars(3)];
w_priv_r3 = w_priv_r3 / max(1e-8, sum(w_priv_r3));
Flow_S3_to_S4_4N(4, :) = S3_In_Widths(4) * (w_priv_r3 * P_34);
S4_Totals = sum(Flow_S3_to_S4_4N, 1);

% Exact adult dollar totals ($k/yr per cohort child) for Gate 5 (Age 30) and Gate 6 (Career to J=16)
A30_Col_Dollars = sum(Age30_Fiscal, 1);     % 1x6: [Exits124, Infra/Health, GST/Cap, PAYE, Exit3_Loss, Emig_Loss]
CR_Col_Dollars  = sum(CareerRet_Fiscal, 1); % 1x6: [Exits124, Super/Infra,  GST/Cap/Est, PAYE, Exit3_Loss, Abroad_Loss]

% Scale Adult Regime (Gates 5 & 6) 1:1 against each other, anchored to the Launch Gate (Gate 4) height
% across the Wiggly Regime-Break Line down the middle of Gate 4:
adult_regime_scale = sum(S4_Totals) / max(1e-8, max(sum(A30_Col_Dollars), sum(CR_Col_Dollars)));

Flow_S4_to_S5 = zeros(3, 6);
for c5 = 1:6
    cs = sum(Age30_Fiscal(:, c5));
    if cs > 1e-8
        Flow_S4_to_S5(:, c5) = (adult_regime_scale * A30_Col_Dollars(c5)) * (Age30_Fiscal(:, c5) / cs);
    end
end

% Gate 5 -> Gate 6 preserves exact 1:1 relative scale between Age 30 (A30_Col_Dollars) and Career-to-Ret (CR_Col_Dollars)!
S5_Widths = adult_regime_scale * A30_Col_Dollars;
S6_Widths = adult_regime_scale * CR_Col_Dollars;

Flow_S5_to_S6 = zeros(6, 6);
Flow_S5_to_S6(1, :) = S5_Widths(1) * [0.76, 0.16, 0.05, 0.03, 0.00, 0.00];
Flow_S5_to_S6(2, :) = S5_Widths(2) * [0.12, 0.68, 0.12, 0.08, 0.00, 0.00];
Flow_S5_to_S6(3, :) = S5_Widths(3) * [0.04, 0.18, 0.56, 0.22, 0.00, 0.00];
Flow_S5_to_S6(4, :) = S5_Widths(4) * [0.03, 0.16, 0.31, 0.50, 0.00, 0.00];
Flow_S5_to_S6(5, :) = S5_Widths(5) * [0.00, 0.00, 0.00, 0.00, 1.00, 0.00];
Flow_S5_to_S6(6, :) = S5_Widths(6) * [0.00, 0.00, 0.00, 0.00, 0.00, 1.00];

for c_j = 1:6
    cs = sum(Flow_S5_to_S6(:, c_j));
    if cs > 1e-8
        Flow_S5_to_S6(:, c_j) = Flow_S5_to_S6(:, c_j) * (S6_Widths(c_j) / cs);
    end
end

for r_i = 1:4
    rs = sum(Flow_S5_to_S6(r_i, 1:4));
    if rs > 1e-8, Flow_S5_to_S6(r_i, 1:4) = Flow_S5_to_S6(r_i, 1:4) * (S5_Widths(r_i) / rs); end
end

%% COMPUTE MACRO PUBLIC RESIDUAL (OMEGA) & 2050 50/50 SURPLUS SPLIT
Bad_30      = A30_Col_Dollars(1) + A30_Col_Dollars(2);
Good_30     = A30_Col_Dollars(3) + A30_Col_Dollars(4);
net_fisc_30 = Good_30 - Bad_30;

Bad_CR      = CR_Col_Dollars(1) + CR_Col_Dollars(2);
Good_CR     = CR_Col_Dollars(3) + CR_Col_Dollars(4);
net_fisc_CR = Good_CR - Bad_CR;

Bad_Final2  = [Bad_30,  Bad_CR];
Good_Final2 = [Good_30, Good_CR];

Surplus_30  = max(0, net_fisc_30);
Surplus_CR  = max(0, net_fisc_CR);

DebtSink_50_30 = 0.50 * Surplus_30;  Reinvest_50_30 = 0.50 * Surplus_30;
DebtSink_50_CR = 0.50 * Surplus_CR;  Reinvest_50_CR = 0.50 * Surplus_CR;

r_gov_bond   = 0.042;
mu_infra_div = 1.65;
Cohort_N     = 60.0;

Ledger.Childhood_Private_vs_Public_kNZD = S1_Totals;
Ledger.ECE_Gate_Step_Dollars_kNZD       = ECE_Step_Dollars(:);
Ledger.Adol_Gate_Step_Dollars_kNZD      = Adol_Step_Dollars(:);
Ledger.ECE_4Node_Dollars_kNZD           = ECE_4Node_Dollars(:);
Ledger.Adol_4Node_Dollars_kNZD          = Adol_4Node_Dollars(:);
Ledger.Pop_S1_Birth                     = Pop_S1_Birth(:);
Ledger.Pop_S2_ECE                       = Pop_S2_ECE(:);
Ledger.Pop_S3_Adol                      = Pop_S3_Adol(:);
Ledger.Pop_S2_ECE_4Node                 = Pop_S2_4Node(:);
Ledger.Pop_S3_Adol_4Node                = Pop_S3_4Node(:);
Ledger.Pop_S4_Skill                     = Pop_S4_Skill(:);
Ledger.S1_Totals                        = S1_Totals(:);
Ledger.S4_Totals                        = S4_Totals(:);
Ledger.S5_Totals                        = A30_Col_Dollars(:);
Ledger.S6_Totals                        = CR_Col_Dollars(:);
Ledger.Age30_Fiscal_By_Tier_kNZD        = Age30_Fiscal;
Ledger.Age30_Totals_kNZD                = A30_Col_Dollars;
Ledger.CareerRet_Fiscal_By_Tier_kNZD    = CareerRet_Fiscal;
Ledger.CareerRet_Totals_kNZD            = CR_Col_Dollars;
Ledger.Cohort_Tier_Shares_Pct           = 100 * Pop_S4_Skill;
Ledger.Net_Fiscal_Balance_kNZD          = [net_fisc_30, net_fisc_CR];
Ledger.SinkingFund_50Pct_kNZD           = [DebtSink_50_30, DebtSink_50_CR];
Ledger.ReinvestmentPool_50Pct_kNZD      = [Reinvest_50_30, Reinvest_50_CR];
Ledger.Annual_DebtService_Saving_kNZD   = r_gov_bond * [DebtSink_50_30, DebtSink_50_CR];
Ledger.Public_Infra_Yield_Dividend_kNZD = mu_infra_div * [Reinvest_50_30, Reinvest_50_CR];
Ledger.Cum_2050_DebtReduction_MNZD      = 25 * Cohort_N * (0.4 * DebtSink_50_30 + 0.6 * DebtSink_50_CR) * (1 + 0.5 * 25 * r_gov_bond);
Ledger.Cum_2050_ReinvestPool_MNZD       = 25 * Cohort_N * (0.4 * Reinvest_50_30 + 0.6 * Reinvest_50_CR);

%% BUILD 26-NODE DOLLAR-LABELED NODE NAMES (WITH 4 BLOCKS AT GATE 2 AND GATE 3)
Nodes_S1 = {sprintf('1. Means-Tested Birth Support\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S1_Birth(1), S1_Totals(1)), ...
    sprintf('2. Universal Birth Benefit\n(100%% pop | $%.1fk/yr)',                          S1_Totals(2)), ...
    sprintf('3. Private Birth Out-of-Pocket\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S1_Birth(3), S1_Totals(3))};

Nodes_S2 = {sprintf('4. ECE Corner + Benefit Need\n(%.1f%% pop | $%.1fk/yr)',      100*Pop_S2_4Node(1), ECE_4Node_Dollars(1)), ...
    sprintf('5. Public ECE Wraparound\n(%.1f%% pop | $%.1fk/yr)',          100*Pop_S2_4Node(2), ECE_4Node_Dollars(2)), ...
    sprintf('6. High-Intensity Public ECE\n(%.1f%% pop | $%.1fk/yr)',      100*Pop_S2_4Node(3), ECE_4Node_Dollars(3)), ...
    sprintf('7. Private Parental ECE (Cash+Time)\n(%.1f%% pop | $%.1fk/yr)',100*Pop_S2_4Node(4), ECE_4Node_Dollars(4))};

Nodes_S3 = {sprintf('8. Unemp Stress + Exits 1,2,4\n(%.1f%% pop | $%.1fk/yr)',     100*Pop_S3_4Node(1), Adol_4Node_Dollars(1)), ...
    sprintf('9. Public Schooling (d_2)\n(%.1f%% pop | $%.1fk/yr)',         100*Pop_S3_4Node(2), Adol_4Node_Dollars(2)), ...
    sprintf('10. Montessori / Tuakana Mentoring\n(%.1f%% pop | $%.1fk/yr)',     100*Pop_S3_4Node(3), Adol_4Node_Dollars(3)), ...
    sprintf('11. Private Adol. Commit (Cash+Time)\n(%.1f%% pop | $%.1fk/yr)',100*Pop_S3_4Node(4), Adol_4Node_Dollars(4))};

Nodes_S4 = {sprintf('12. Stunted Tier h1-h2 [Exits 1,2,4]\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S4_Skill(1), S4_Totals(1)), ...
    sprintf('13. Core Skill Tier h3-h5\n(%.1f%% pop | $%.1fk/yr)',            100*Pop_S4_Skill(2), S4_Totals(2)), ...
    sprintf('14. Thriving Tier h6-h7\n(%.1f%% pop | $%.1fk/yr)',              100*Pop_S4_Skill(3), S4_Totals(3))};

if Surplus_30 > 0.05
    lbl_17 = sprintf('17. Age 30 GST & Cap Tax\n($%.1fk/yr | Reinvest: +$%.1fk)', A30_Col_Dollars(3), Reinvest_50_30);
    lbl_18 = sprintf('18. Age 30 PAYE Tax\n($%.1fk/yr | Debt Sink: +$%.1fk)',     A30_Col_Dollars(4), DebtSink_50_30);
else
    lbl_17 = sprintf('17. Age 30 GST & Cap Tax\n($%.1fk/yr)', A30_Col_Dollars(3));
    lbl_18 = sprintf('18. Age 30 PAYE Income Tax\n($%.1fk/yr)', A30_Col_Dollars(4));
end
Nodes_S5 = {sprintf('15. Exits 1,2,4: Care/Hosp/Just\n($%.1fk/yr | @$32k/stunted)', A30_Col_Dollars(1)), ...
    sprintf('16. Infra, Roads & Base Health\n($%.1fk/yr per adult)',        A30_Col_Dollars(2)), ...
    lbl_17, ...
    lbl_18, ...
    sprintf('19. Exit 3: Stunting Lost Tax\n($%.1fk/yr foregone)',          A30_Col_Dollars(5)), ...
    sprintf('20. Age 30 Emig Tax Loss\n($%.1fk/yr to Abroad)',              A30_Col_Dollars(6))};

if Surplus_CR > 0.05
    lbl_23 = sprintf('23. GST, Cap & Estate Tax\n($%.1fk/yr | 50%% Reinvest: +$%.1fk)', CR_Col_Dollars(3), Reinvest_50_CR);
    lbl_24 = sprintf('24. Career PAYE Tax\n($%.1fk/yr | 50%% Debt Sink: +$%.1fk)',      CR_Col_Dollars(4), DebtSink_50_CR);
else
    lbl_23 = sprintf('23. GST, Cap & Estate Tax Pool\n($%.1fk/yr)', CR_Col_Dollars(3));
    lbl_24 = sprintf('24. Career PAYE Income Tax\n($%.1fk/yr)',     CR_Col_Dollars(4));
end
Nodes_S6 = {sprintf('21. Exits 1,2,4: Ongoing Burden\n($%.1fk/yr)',   CR_Col_Dollars(1)), ...
    sprintf('22. NZ Super, Infra & Health\n($%.1fk/yr)',      CR_Col_Dollars(2)), ...
    lbl_23, ...
    lbl_24, ...
    sprintf('25. Exit 3: Career Lost Tax\n($%.1fk/yr foregone)', CR_Col_Dollars(5)), ...
    sprintf('26. Perm. Abroad Tax Loss\n($%.1fk/yr in Abroad)',  CR_Col_Dollars(6))};

links = {};
row_k = 0;
for i = 1:3
    for j = 1:4
        if Flow_S1_to_S2_4N(i, j) > 1e-4
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S1{i}, Nodes_S2{j}, Flow_S1_to_S2_4N(i, j)};
        end
    end
end
for i = 1:4
    for j = 1:4
        if Flow_S2_to_S3_4N(i, j) > 1e-4
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S2{i}, Nodes_S3{j}, Flow_S2_to_S3_4N(i, j)};
        end
    end
end
for i = 1:4
    for j = 1:3
        if Flow_S3_to_S4_4N(i, j) > 1e-4
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S3{i}, Nodes_S4{j}, Flow_S3_to_S4_4N(i, j)};
        end
    end
end
for i = 1:3
    for j = 1:6
        if Flow_S4_to_S5(i, j) > 1e-4
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S4{i}, Nodes_S5{j}, Flow_S4_to_S5(i, j)};
        end
    end
end
for i = 1:6
    for j = 1:6
        if Flow_S5_to_S6(i, j) > 1e-4
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S5{i}, Nodes_S6{j}, Flow_S5_to_S6(i, j)};
        end
    end
end

axes(ax); hold(ax, 'on');
SK = SSankey(links(:, 1), links(:, 2), links(:, 3));

SK.RenderingMethod = 'interp';
SK.Align           = 'center';
SK.LabelLocation   = 'right';
SK.BlockScale      = 0.13;
SK.Sep             = 0.048;
if isprop(SK, 'FontName')
    SK.FontName = 'Helvetica';
end

% 26-Node Palette:
%   Gate 1 (1..3):   Red (Means-Tested), Blue (Universal), Warm Gold-Green (Private Birth)
%   Gate 2 (4..7):   Red (Corner), Steel Blue (Public ECE), Teal (High Public ECE), Warm Gold-Emerald (Private Parental ECE Cash+Time)
%   Gate 3 (8..11):  Red (Unemp Stress), Steel Blue (Public Schooling), Teal (Montessori / Tuakana Mentoring), Warm Gold-Emerald (Private Adol Cash+Time)
%   Gate 4 (12..14): Red (Stunted), Slate Blue (Core), Emerald (Thriving)
%   Gate 5 (15..20): Red (Exits 1,2,4), Amber (Infra/Health), Blue (GST/Cap), Teal (PAYE),Mauve (Exit 3), Purple (Emig)
%   Gate 6 (21..26): Red (Ongoing Exits), Amber (Super/Infra), Blue (GST/Cap/Est), Teal (PAYE), Mauve (Exit 3), Purple (Abroad)
Master_Colors = [
    0.78, 0.20, 0.16;  % 1. Means-Tested Birth Support
    0.24, 0.50, 0.70;  % 2. Universal Birth Benefit
    0.82, 0.54, 0.14;  % 3. Private Birth Out-of-Pocket (Warm Amber-Gold)
    0.78, 0.20, 0.16;  % 4. ECE Corner + Benefit Need
    0.24, 0.50, 0.70;  % 5. Public ECE Wraparound (Public Steel Blue)
    0.14, 0.62, 0.50;  % 6. High-Intensity Public ECE (Public Teal)
    0.84, 0.56, 0.14;  % 7. Private Parental ECE (Cash+Time) (Warm Amber-Gold)
    0.82, 0.28, 0.16;  % 8. Unemp Stress + Exits 1,2,4
    0.26, 0.52, 0.70;  % 9. Public Schooling (d_2) (Public Steel Blue)
    0.14, 0.62, 0.50;  % 10. Montessori / Tuakana Mentoring (Public Teal)
    0.84, 0.56, 0.14;  % 11. Private Adol. Commit (Cash+Time) (Warm Amber-Gold)
    0.74, 0.18, 0.18;  % 12. Stunted Tier h1-h2
    0.30, 0.56, 0.68;  % 13. Core Skill Tier h3-h5
    0.12, 0.58, 0.46;  % 14. Thriving Tier h6-h7
    0.80, 0.22, 0.18;  % 15. Age 30 Exits 1,2,4 Remediation
    0.76, 0.46, 0.18;  % 16. Age 30 Infra, Roads & Base Health
    0.22, 0.48, 0.70;  % 17. Age 30 GST & Cap Tax
    0.14, 0.60, 0.48;  % 18. Age 30 PAYE Income Tax
    0.68, 0.30, 0.48;  % 19. Age 30 Exit 3: Stunting Lost Tax
    0.50, 0.32, 0.68;  % 20. Age 30 Emig Tax Loss
    0.76, 0.20, 0.18;  % 21. Career Exits 1,2,4 Ongoing Burden
    0.74, 0.44, 0.16;  % 22. Career NZ Super, Infra & Health
    0.20, 0.46, 0.68;  % 23. Career GST, Cap & Estate Tax Pool
    0.12, 0.58, 0.46;  % 24. Career PAYE Income Tax
    0.64, 0.28, 0.46;  % 25. Career Exit 3: Stunting Lost Tax
    0.46, 0.28, 0.66   % 26. Career Permanent Abroad Tax Loss
    ];

All_Node_Names = [Nodes_S1, Nodes_S2, Nodes_S3, Nodes_S4, Nodes_S5, Nodes_S6];
if isprop(SK, 'NodeList') && ~isempty(SK.NodeList)
    mapped_colors = zeros(length(SK.NodeList), 3);
    for n_i = 1:length(SK.NodeList)
        idx_match = find(strcmp(SK.NodeList{n_i}, All_Node_Names), 1);
        if ~isempty(idx_match)
            mapped_colors(n_i, :) = Master_Colors(idx_match, :);
        else
            mapped_colors(n_i, :) = [0.4, 0.4, 0.4];
        end
    end
    SK.ColorList = mapped_colors;
else
    SK.ColorList = Master_Colors;
end

SK.draw();

set(ax, 'YDir', 'normal');

curr_xlim = xlim(ax);
xlim(ax, [curr_xlim(1) - 0.18, curr_xlim(2) + 1.38]);

curr_ylim = ylim(ax);
y_span    = diff(curr_ylim);
ylim(ax, [curr_ylim(1) - 0.24 * y_span, curr_ylim(2) + 0.12 * y_span]);

set(ax, 'FontName', 'Helvetica');
set(findall(ax, 'Type', 'text'), 'FontName', 'Helvetica', 'FontSize', 8.5);

%% DRAW 6-GATE HORIZONTAL "J" AXIS CENTERED ON EACH BAR VIA sum(xd(:))/4
y_axis_line = curr_ylim(1) - 0.09 * y_span;
tick_h      = 0.022 * y_span;

p_all        = findall(ax, 'Type', 'Patch');
x_center_col = zeros(1, 6);
for c_i = 1:6
    c_centers = [];
    for k_p = 1:length(p_all)
        xd = get(p_all(k_p), 'XData');
        if numel(xd) == 4
            xc = sum(xd(:)) / 4;
            if abs(xc - c_i) < 0.45
                c_centers(end+1) = xc; %#ok<AGROW>
            end
        end
    end
    if ~isempty(c_centers)
        x_center_col(c_i) = mean(c_centers);
    else
        x_center_col(c_i) = c_i;
    end
end

plot(ax, [x_center_col(1), x_center_col(6)], [y_axis_line, y_axis_line], '-', ...
    'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.4);

J_Stage_Labels = {
    sprintf('J = 1 (Birth, Age 0)\n(Out-of-Pocket vs Public $)');
    sprintf('J = 2..3 (Ages 0-5)\n(First 2000 Days ECE Gate)');
    sprintf('J = 5 (Ages 12-14)\n(Adol. Gate + Exits 1,2,4)');
    sprintf('J = 6..7 (Age 20)\n(Adult Skill Launch)');
    sprintf('J = 10 (Age 30)\n(Exits 1-4 vs Annual Tax $)');
    sprintf('J = 11..16 (To Ret.)\n(Exits 1-4 & Super vs Tax $)')
    };

for col_x = 1:6
    x_tick = x_center_col(col_x);
    plot(ax, [x_tick, x_tick], [y_axis_line - tick_h, y_axis_line + tick_h], '-', ...
        'Color', [0.25, 0.25, 0.25], 'LineWidth', 1.5);

    text(ax, x_tick, y_axis_line - 1.6 * tick_h, J_Stage_Labels{col_x}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', 'Helvetica', 'FontSize', 8.8, 'FontWeight', 'bold', ...
        'Color', [0.20, 0.20, 0.20]);
end

%% DRAW WIGGLY REGIME-BREAK LINE DOWN THE MIDDLE OF GATE 4 (J = 6..7, ADULT SKILL LAUNCH)
% Separates the Childhood Investment Regime (Gates 1-3, true 1:1 scale) from the
% Adult Fiscal & Tax Regime (Gates 5-6, true 1:1 scale).
col4_boxes = [];
for k_p = 1:length(p_all)
    xd = get(p_all(k_p), 'XData');
    yd = get(p_all(k_p), 'YData');
    if numel(xd) == 4 && abs((sum(xd(:)) / 4) - 4) < 0.45
        col4_boxes(end+1, :) = [min(xd(:)), max(xd(:)), min(yd(:)), max(yd(:))]; %#ok<AGROW>
    end
end
if ~isempty(col4_boxes)
    x_c4     = mean(col4_boxes(:, 1:2), 'all');
    w_c4     = mean(col4_boxes(:, 2) - col4_boxes(:, 1));
    y_bot_c4 = min(col4_boxes(:, 3)) - 0.025 * y_span;
    y_top_c4 = max(col4_boxes(:, 4)) + 0.025 * y_span;

    % Construct smooth sinusoidal wiggly break line down the center of Gate 4
    y_wig    = linspace(y_bot_c4, y_top_c4, 180);
    n_waves  = 9.5;
    amp_x    = 0.16 * w_c4;
    dx_gap   = 0.11 * w_c4;
    x_wig_C  = x_c4 + amp_x * sin(2 * pi * n_waves * (y_wig - y_bot_c4) / max(1e-8, y_top_c4 - y_bot_c4));

    % White inner ribbon + twin dark charcoal wave edges (classic engineering scale-break symbol)
    plot(ax, x_wig_C,          y_wig, '-', 'Color', [1.00, 1.00, 1.00], 'LineWidth', 3.6);
    plot(ax, x_wig_C - dx_gap, y_wig, '-', 'Color', [0.15, 0.15, 0.15], 'LineWidth', 1.4);
    plot(ax, x_wig_C + dx_gap, y_wig, '-', 'Color', [0.15, 0.15, 0.15], 'LineWidth', 1.4);

    % Small top badge above Gate 4 marking the Childhood -> Adult scale break
    text(ax, x_c4, y_top_c4 + 0.012 * y_span, ...
        sprintf('%s Childhood Scale  |  Adult Fiscal Scale %s', char(9668), char(9658)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontName', 'Helvetica', 'FontSize', 7.8, 'FontWeight', 'bold', ...
        'Color', [0.20, 0.20, 0.20], 'BackgroundColor', [0.98, 0.98, 0.94], ...
        'EdgeColor', [0.55, 0.55, 0.55], 'Margin', 1.8);
end

%% DOCUMENT 2 PROTOCOL: NET-ZERO BREAKEVEN LINE & 50/50 DEBT-SINKING VS. REINVESTMENT VISUALIZATION
cols_target = [5, 6];
y_zero_f2   = nan(1, 2);
y_topG_f2   = nan(1, 2); % Top of the Good Tax blocks (100% of Tax Revenue collected)
y_split_50  = nan(1, 2); % 50/50 split line inside the Net Tax Surplus zone (when Good > Bad)
x_cent_f2   = nan(1, 2);
x_left_f2   = nan(1, 2);
x_rght_f2   = nan(1, 2);

for idx_f = 1:2
    c_i = cols_target(idx_f);
    col_boxes = [];
    for k_p = 1:length(p_all)
        xd = get(p_all(k_p), 'XData');
        yd = get(p_all(k_p), 'YData');
        if numel(xd) == 4 && abs((sum(xd(:)) / 4) - c_i) < 0.45
            col_boxes(end+1, :) = [min(xd(:)), max(xd(:)), min(yd(:)), max(yd(:))]; %#ok<AGROW>
        end
    end
    if size(col_boxes, 1) >= 4
        [~, s_ord] = sort(col_boxes(:, 3), 'ascend');
        col_boxes  = col_boxes(s_ord, :);

        x_left_f2(idx_f) = col_boxes(1, 1);
        x_rght_f2(idx_f) = col_boxes(1, 2);
        x_cent_f2(idx_f) = sum(col_boxes(1, 1:2)) / 2;

        bad_boxes  = col_boxes(1:2, :);
        good_boxes = col_boxes(3:min(4, size(col_boxes, 1)), :);
        y_topG_f2(idx_f) = good_boxes(end, 4);

        B_val = Bad_Final2(idx_f);
        G_val = Good_Final2(idx_f);
        net_v = G_val - B_val;

        y_top_bad  = bad_boxes(end, 4);
        y_bot_good = good_boxes(1, 3);
        y_origin   = 0.5 * (y_top_bad + y_bot_good);

        if abs(net_v) < 1e-6
            y_zero_f2(idx_f) = y_origin;
        elseif net_v > 0
            % Net Surplus (Omega > 0): Breakeven sits inside Good where Taxes cover 100% of Bad Outlays;
            % the remaining Good block height ABOVE y_zero_f2 is the Net Fiscal Surplus (Omega)!
            % Wait: to make the zone ABOVE y_zero_f2 equal the Net Surplus (Omega = G_val - B_val),
            % the height from the bottom of Good up to y_zero_f2 covers B_val (fraction f_cover = B_val / G_val),
            % and the height ABOVE y_zero_f2 up to the top of Good is f_surplus = (G_val - B_val) / G_val!
            f_surplus = net_v / max(1e-8, G_val);
            g_heights = good_boxes(:, 4) - good_boxes(:, 3);
            tot_g_h   = sum(g_heights);
            target_h  = f_surplus * tot_g_h;
            cum_h     = 0;
            for g_k = 1:size(good_boxes, 1)
                if cum_h + g_heights(g_k) >= target_h || g_k == size(good_boxes, 1)
                    y_zero_f2(idx_f) = good_boxes(g_k, 3) + max(0, target_h - cum_h);
                    break;
                end
                cum_h = cum_h + g_heights(g_k);
            end

            % Compute exact 50/50 Split Height inside the Surplus Zone (half of net_v):
            target_h_50 = 0.50 * target_h;
            cum_h50     = 0;
            for g_k = 1:size(good_boxes, 1)
                if cum_h50 + g_heights(g_k) >= target_h_50 || g_k == size(good_boxes, 1)
                    y_split_50(idx_f) = good_boxes(g_k, 3) + max(0, target_h_50 - cum_h50);
                    break;
                end
                cum_h50 = cum_h50 + g_heights(g_k);
            end
        else
            % Net Deficit (Omega < 0): descend DOWNWARD from the top of Bad by (Bad - Good) / Bad
            f_deficit = (B_val - G_val) / max(1e-8, B_val);
            b_heights = bad_boxes(:, 4) - bad_boxes(:, 3);
            target_d  = f_deficit * sum(b_heights);
            cum_d     = 0;
            for b_k = size(bad_boxes, 1):-1:1
                if cum_d + b_heights(b_k) >= target_d || b_k == 1
                    y_zero_f2(idx_f) = bad_boxes(b_k, 4) - max(0, target_d - cum_d);
                    break;
                end
                cum_d = cum_d + b_heights(b_k);
            end
        end

        % Subtle gray dotted reference tick at the Good/Bad interface ($0 origin)
        plot(ax, [x_left_f2(idx_f) - 0.025, x_rght_f2(idx_f) + 0.025], ...
            [y_origin, y_origin], ':', 'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.3);

        % Solid dark bar at Net Balance height (y_zero_f2)
        plot(ax, [x_left_f2(idx_f) - 0.035, x_rght_f2(idx_f) + 0.035], ...
            [y_zero_f2(idx_f), y_zero_f2(idx_f)], '-', ...
            'Color', [0.10, 0.10, 0.10], 'LineWidth', 2.8);

        % If Surplus > 0, draw the 50/50 Debt-Sinking vs. Reinvestment divider bar at y_split_50
        if ~isnan(y_split_50(idx_f)) && net_v > 0.5
            plot(ax, [x_left_f2(idx_f) - 0.030, x_rght_f2(idx_f) + 0.030], ...
                [y_split_50(idx_f), y_split_50(idx_f)], '-', ...
                'Color', [0.05, 0.42, 0.35], 'LineWidth', 2.2);
        end
    end
end

if all(~isnan(y_zero_f2))
    plot(ax, x_cent_f2, y_zero_f2, '--o', ...
        'Color', [0.12, 0.12, 0.12], 'LineWidth', 2.0, ...
        'MarkerSize', 6.0, 'MarkerFaceColor', [0.98, 0.82, 0.18], 'MarkerEdgeColor', [0.10, 0.10, 0.10]);

    % If both Gate 5 & Gate 6 have positive surplus (or in Reform Panel B), connect the 50/50 split line
    if all(~isnan(y_split_50)) && is_reform_panel
        plot(ax, x_cent_f2, y_split_50, ':s', ...
            'Color', [0.05, 0.42, 0.35], 'LineWidth', 1.8, ...
            'MarkerSize', 5.2, 'MarkerFaceColor', [0.20, 0.80, 0.65], 'MarkerEdgeColor', [0.05, 0.35, 0.28]);

        % Callout badge showing the 2050 50/50 Surplus Split at Gate 6
        text(ax, x_rght_f2(2) + 0.04, y_zero_f2(2), ...
            sprintf('Net Fiscal Surplus: +$%.1fk/yr\n  • 50%% 2050 Debt Sinking: +$%.1fk/yr\n  • 50%% Reinvest (Infra/NZSF): +$%.1fk/yr', ...
            net_fisc_CR, DebtSink_50_CR, Reinvest_50_CR), ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
            'FontName', 'Helvetica', 'FontSize', 8.0, 'FontWeight', 'bold', ...
            'Color', [0.10, 0.10, 0.10], 'BackgroundColor', [0.96, 1.00, 0.96], ...
            'EdgeColor', [0.15, 0.55, 0.45], 'Margin', 2.5);
    else
        text(ax, x_rght_f2(2) + 0.04, y_zero_f2(2), ...
            sprintf('Net Fiscal Balance\n(Good Taxes - Crown Outlays)'), ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
            'FontName', 'Helvetica', 'FontSize', 8.3, 'FontWeight', 'bold', ...
            'Color', [0.12, 0.12, 0.12], 'BackgroundColor', [1.0, 0.98, 0.90], ...
            'EdgeColor', [0.4, 0.4, 0.4], 'Margin', 2);
    end
end

if strcmpi(reg_choice, 'Urban') && length(reg_list) > 1
    disp_reg = 'Urban';
elseif strcmpi(reg_choice, 'National')
    disp_reg = 'National';
else
    disp_reg = reg_choice;
end

n_sign_30 = char('+' * (net_fisc_30 >= 0) + '-' * (net_fisc_30 < 0));
n_sign_CR = char('+' * (net_fisc_CR >= 0) + '-' * (net_fisc_CR < 0));
if is_reform_panel && net_fisc_CR > 0
    t_str = sprintf('%s — %s | Net Surplus: %s$%.1fk (Age 30) | %s$%.1fk (To Ret: $%.1fk Debt Sink + $%.1fk Reinvest)', ...
        Panel_Tag, disp_reg, n_sign_30, abs(net_fisc_30), n_sign_CR, abs(net_fisc_CR), DebtSink_50_CR, Reinvest_50_CR);
else
    t_str = sprintf('%s — %s (Cohort-Weighted $k/yr per Birth) | Net Balance: %s$%.1fk/yr (Age 30) | %s$%.1fk/yr (To Ret.)', ...
        Panel_Tag, disp_reg, n_sign_30, abs(net_fisc_30), n_sign_CR, abs(net_fisc_CR));
end
t_obj = title(ax, t_str, 'FontName', 'Helvetica', 'FontSize', 11.2, 'FontWeight', 'bold');
set(t_obj, 'Units', 'normalized');
t_pos = get(t_obj, 'Position');
set(t_obj, 'Position', [t_pos(1), 1.03, t_pos(3)]);

axis(ax, 'off');
end

function out_4D = is_mt_4D_helper(mask_in, ref_4D)
out_4D = double(mask_in) + 0 .* ref_4D;
end

function val = getfield_def(S, fname, default_val)
if isfield(S, fname)
    val = S.(fname);
else
    val = default_val;
end
end

function img_cropped = AutoCrop_White_Border(img)
is_nonwhite = any(img < 252, 3);
rows = find(any(is_nonwhite, 2));
cols = find(any(is_nonwhite, 1));
if ~isempty(rows) && ~isempty(cols)
    img_cropped = img(min(rows):max(rows), min(cols):max(cols), :);
else
    img_cropped = img;
end
end
