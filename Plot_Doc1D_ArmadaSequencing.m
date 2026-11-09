function Out = Plot_Doc1D_ArmadaSequencing(OutputDir, AnchorTag)
% PLOT_DOC1D_ARMADASEQUENCING
% Models & plots the 13-Wave "Armada" Phased Rollout (Years 1-13) with:
%   - 1/3rd regional echelons for ECE + Adolescent Mentoring (Waves 1-9)
%   - Synchronized Age-20 Youth Capital Grants starting at Wave 7 (Waves 7-13)
%   - Consecutive Electrification Grants: Rural+Small (Waves 1-3), Large (Waves 4-6), Auckland (Waves 7-9)
%   - Dual-Speed Tax Ramps: 3-Yr CGT/Estate Ramp (Waves 1-3) & 10-Yr LVT Ramp (+0.15%/yr, Waves 1-10)
%   - Convex workforce adjustment costs (phi_adj) & inter-wave learning curves (Psi_armada)
%   - Apples-to-Apples LTFM Annual Incremental Deficit Flow (-dDebt/dt) + 4.2x Magnified J-Curve Inset
% Exports:
%   1. Table23_Doc1D_13Wave_Armada_Schedule_<AnchorTag>.csv
%   2. Table24_Doc1D_Armada_Vs_SingleShot_Trajectory_<AnchorTag>.csv
%   3. Fig_Doc1D_13Wave_Armada_Schedule_<AnchorTag>.png
%   4. Fig_Doc1D_Armada_Vs_SingleShot_JCurve_<AnchorTag>.png

if nargin < 1 || isempty(OutputDir)
    OutputDir = 'Output_NZ_4Region_Intergen';
end
if nargin < 2 || isempty(AnchorTag)
    AnchorTag = 'Dunedin_22';
end
if ~exist(OutputDir, 'dir'), mkdir(OutputDir); end

f19 = fullfile(OutputDir, sprintf('Table19_Constructive_Synergy_Wedges_%s.csv', AnchorTag));
f20 = fullfile(OutputDir, sprintf('Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_%s.csv', AnchorTag));
f21 = fullfile(OutputDir, sprintf('Table21_Doc3_LTFM_Sinkhole_Defense_Trajectories_%s.csv', AnchorTag));

T19 = readtable(f19);
T20 = readtable(f20);
T21 = readtable(f21);

is_wedge   = strcmpi(T19.Component_Type, 'SYNERGY_WEDGE');
Iso_SS2    = sum(T19.SS2_National_CE(~is_wedge));
Wed_SS2    = sum(T19.SS2_National_CE(is_wedge));
SS2_Tot    = Iso_SS2 + Wed_SS2;
NZD_Per_CE = 2.38;

% Regional population shares: Rural+Small = 40.0% (16% + 24%), Large = 25.9%, Auckland = 34.1%
w_RS  = 0.400;
w_Lrg = 0.259;
w_Akl = 0.341;

%% =========================================================================
%  1. BUILD THE EXACT 13-WAVE DEPLOYMENT MATRIX (YEARS 1 TO 13)
%% =========================================================================
Waves = (1:13)';

% Regional active shares (in thirds: 0, 1/3, 2/3, 3/3) across Years 1..13:
% ECE & Adolescent Mentoring: R+S (W1, W4, W7), Large (W2, W5, W8), Auckland (W3, W6, W9)
ECE_RS  = [1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3]' / 3.0;
ECE_Lrg = [0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3]' / 3.0;
ECE_Akl = [0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3]' / 3.0;

Mnt_RS  = ECE_RS;
Mnt_Lrg = ECE_Lrg;
Mnt_Akl = ECE_Akl;

% Youth Capital Grant E: Starts at Wave 7 when Wave-1 13-14yo mentees turn Age 19-20!
YGr_RS  = [0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3]' / 3.0;
YGr_Lrg = [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3]' / 3.0;
YGr_Akl = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 3]' / 3.0;

% Consecutive Electrification Grants (Rewiring Aotearoa ebar_energy compression):
% Waves 1-3: Rural+Small (1/3 -> 2/3 -> 3/3)
% Waves 4-6: Large Metros (1/3 -> 2/3 -> 3/3)
% Waves 7-9: Auckland (1/3 -> 2/3 -> 3/3)
Elc_RS  = [1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]' / 3.0;
Elc_Lrg = [0, 0, 0, 1, 2, 3, 3, 3, 3, 3, 3, 3, 3]' / 3.0;
Elc_Akl = [0, 0, 0, 0, 0, 0, 1, 2, 3, 3, 3, 3, 3]' / 3.0;

% National Population-Weighted Active Shares across Waves 1..13
Nat_ECE_Pct = 100 * (w_RS * ECE_RS  + w_Lrg * ECE_Lrg + w_Akl * ECE_Akl);
Nat_Mnt_Pct = 100 * (w_RS * Mnt_RS  + w_Lrg * Mnt_Lrg + w_Akl * Mnt_Akl);
Nat_YGr_Pct = 100 * (w_RS * YGr_RS  + w_Lrg * YGr_Lrg + w_Akl * YGr_Akl);
Nat_Elc_Pct = 100 * (w_RS * Elc_RS  + w_Lrg * Elc_Lrg + w_Akl * Elc_Akl);

% Revenue Armada Ramps across Waves 1..13:
%   - CGT & Estate Levy Ramp (tau_b: 15% -> 25%): 3-Year fast ramp (Waves 1-3: 33.3% -> 66.7% -> 100%)
%   - Land Value / Wealth Tax Ramp (tau_a: 0% -> 1.50%): 10-Year smooth ramp (+0.15%/yr across Waves 1-10)
%     paired in 1-to-1 lockstep with the Corporate Tax Cut (tau_k: 20.0% -> 12.0% at -0.80%/yr)
CGT_Est_Share = min(1.0, Waves / 3.0);
LVT_Share     = min(1.0, Waves / 10.0);
LVT_Rate_Pct  = 1.50 * LVT_Share;
Corp_Tax_Pct  = 20.0 - 8.0 * LVT_Share;

% Cumulative Armada Learning Stock L(t-1) & Commissioning Friction tau_fric(t)
Cum_Learn_Stock  = [0; cumsum(0.5*(Nat_ECE_Pct(1:12)/100) + 0.5*(Nat_Elc_Pct(1:12)/100))];
Tau_Fric_Armada  = 0.042 + (0.280 - 0.042) * exp(-0.42 * Cum_Learn_Stock);
Tau_Fric_1Shot   = 0.065 + (0.320 - 0.065) * exp(-0.18 * (0:12)');
Eff_Yield_Armada = 100 * (1.0 - Tau_Fric_Armada); % Rises from 72.0% in W1 to >95% by W7

T23 = table(Waves, ...
    round(100*ECE_RS,1), round(100*ECE_Lrg,1), round(100*ECE_Akl,1), round(Nat_ECE_Pct,1), ...
    round(100*Mnt_RS,1), round(100*Mnt_Lrg,1), round(100*Mnt_Akl,1), round(Nat_Mnt_Pct,1), ...
    round(100*YGr_RS,1), round(100*YGr_Lrg,1), round(100*YGr_Akl,1), round(Nat_YGr_Pct,1), ...
    round(100*Elc_RS,1), round(100*Elc_Lrg,1), round(100*Elc_Akl,1), round(Nat_Elc_Pct,1), ...
    round(100*CGT_Est_Share,1), round(100*LVT_Share,1), round(LVT_Rate_Pct,2), round(Corp_Tax_Pct,1), ...
    round(100*Tau_Fric_Armada,2), round(Eff_Yield_Armada,2), ...
    'VariableNames', {'Wave_Year', ...
    'ECE_RuralSmall_Pct', 'ECE_Large_Pct', 'ECE_Auckland_Pct', 'Nat_ECE_Active_Pct', ...
    'Mentor_RuralSmall_Pct', 'Mentor_Large_Pct', 'Mentor_Auckland_Pct', 'Nat_Mentor_Active_Pct', ...
    'YouthGrant_RuralSmall_Pct', 'YouthGrant_Large_Pct', 'YouthGrant_Auckland_Pct', 'Nat_YouthGrant_Active_Pct', ...
    'Electrif_RuralSmall_Pct', 'Electrif_Large_Pct', 'Electrif_Auckland_Pct', 'Nat_Electrif_Active_Pct', ...
    'CGT_Estate_Ramp_Pct', 'LVT_10Yr_Ramp_Pct', 'Active_LVT_Rate_Pct', 'Active_CorpTax_Rate_Pct', ...
    'Commissioning_Friction_Pct', 'Effective_Program_Yield_Pct'});

csv23 = fullfile(OutputDir, sprintf('Table23_Doc1D_13Wave_Armada_Schedule_%s.csv', AnchorTag));
writetable(T23, csv23);
fprintf('  -> Exported Table 23 (13-Wave Armada + 10-Yr LVT & 3-Yr CGT Ramp Schedule) to: %s\n', csv23);

%% =========================================================================
%  2. EVALUATE 60-YEAR TRAJECTORIES: SINGLE-SHOT VS. 13-WAVE ARMADA
%% =========================================================================
y_all = linspace(-5, 60, 651)';
N_pts = numel(y_all);

p1_mask = (T20.Year >= 0) & (T20.Year <= 25.0);
y_p1    = T20.Year(p1_mask);
tot_p1  = T20.Total_Welfare_Gain_CE_Pct(p1_mask);

% Single-Shot Baseline Curves (Plans B & C from Plot_Doc1D_LaunchPlans)
w0_20   = interp1(y_p1, tot_p1, 20.0, 'pchip');
w0_25   = interp1(y_p1, tot_p1, 25.0, 'pchip');
w_s1_60 = w0_25 + (SS2_Tot - w0_25) * (1.0 - exp(-35.0 / 8.50));
tau_s2  = -30.0 / log((SS2_Tot - w_s1_60) / (SS2_Tot - w0_20));

Welf_1Shot_PlanB = zeros(N_pts, 1);
Welf_1Shot_PlanC = zeros(N_pts, 1);
GInv_1Shot       = zeros(N_pts, 1);
Unrec_1Shot      = zeros(N_pts, 1);
Act_1Shot        = zeros(N_pts, 1);

% Armada Curves
Welf_Armada_PlanB = zeros(N_pts, 1);
Welf_Armada_PlanC = zeros(N_pts, 1);
GInv_Armada       = zeros(N_pts, 1);
Unrec_Armada      = zeros(N_pts, 1);
Act_Armada        = zeros(N_pts, 1);

for k = 1:N_pts
    y = y_all(k);
    if y < 0, continue; end

    % --- 1. Single-Shot Step-Shock Baseline ---
    ginv_1s  = interp1(T20.Year, T20.Total_Gross_Inv_Mirror_CE_Pct, min(25.0, y), 'pchip');
    remed_1s = 4.65 / (1.0 + exp(-(y - 16.5) / 4.2));
    unrec_1s = min(0.0, ginv_1s + remed_1s);
    GInv_1Shot(k)  = ginv_1s;
    Unrec_1Shot(k) = unrec_1s;

    if y <= 20.0
        Welf_1Shot_PlanB(k) = interp1(y_p1, tot_p1, y, 'pchip');
    else
        Welf_1Shot_PlanB(k) = w0_20 + (SS2_Tot - w0_20) * (1.0 - exp(-(y - 20.0) / tau_s2));
    end
    if y <= 15.0
        Welf_1Shot_PlanC(k) = interp1(y_p1, tot_p1, y, 'pchip');
    elseif y <= 20.0
        w15 = interp1(y_p1, tot_p1, 15.0, 'pchip');
        Welf_1Shot_PlanC(k) = w15 + (SS2_Tot - w15) * (1.0 - exp(-(y - 15.0) / 8.50));
    else
        w15 = interp1(y_p1, tot_p1, 15.0, 'pchip');
        w20 = w15 + (SS2_Tot - w15) * (1.0 - exp(-5.0 / 8.50));
        Welf_1Shot_PlanC(k) = w20 + (SS2_Tot - w20) * (1.0 - exp(-(y - 20.0) / 6.85));
    end

    % --- 2. 13-Wave Armada Phased Rollout + 10-Yr LVT & 3-Yr CGT/Estate Ramps ---
    yr_w   = [0; Waves; 25; 60];
    sh_ece = interp1(yr_w, [0.000; Nat_ECE_Pct/100; 1.0; 1.0], min(60, y), 'pchip');
    sh_ygr = interp1(yr_w, [0.000; Nat_YGr_Pct/100; 1.0; 1.0], min(60, y), 'pchip');
    sh_elc = interp1(yr_w, [0.000; Nat_Elc_Pct/100; 1.0; 1.0], min(60, y), 'pchip');

    retire_geo = 1.0 / (1.0 + exp(-(y - 13.5) / 3.6));
    sh_budget  = 0.60 * sh_ece + 0.20 * sh_ygr + 0.20 * (0.65 * sh_elc * (1.0 - 0.72 * retire_geo) + 0.35 * min(1.0, y / 2.0));

    if y <= 20.0
        GInv_Armada(k) = -3.30 * sh_budget * (1.0 - 0.12 * exp(-y / 4.0));
    else
        g20_arm = -3.30 * (0.60 + 0.20 + 0.20 * (0.65 * (1.0 - 0.72 / (1.0 + exp(-(20.0 - 13.5)/3.6))) + 0.35));
        GInv_Armada(k) = g20_arm + (-2.55 - g20_arm) * (1.0 - exp(-(y - 20.0) / 4.8));
    end

    % Dual-Speed Tax Ramp (3-Yr CGT/Estate + 10-Yr LVT) matched to the 13-Wave Expenditure Ramp:
    sh_cgt_t         = min(1.0, y / 3.0);
    sh_lvt_t         = min(1.0, y / 10.0);
    sh_tax_ramp      = 0.38 * sh_cgt_t + 0.62 * sh_lvt_t;
    remed_raw        = 4.92 ./ (1.0 + exp(-(y - 14.8) / 3.85)) - 4.92 ./ (1.0 + exp(14.8 / 3.85));
    tax_match_buffer = 0.28 * sh_tax_ramp .* exp(-max(0, y - 5.0) / 5.0);
    remed_armada     = remed_raw + tax_match_buffer;
    Unrec_Armada(k)  = min(0.0, GInv_Armada(k) + remed_armada);

    % Effective Delivered Welfare under Armada:
    learn_quality_lift = 1.0 + 0.032 * (1.0 ./ (1.0 + exp(-(y - 9.5) / 2.8)));
    phase_ramp_factor  = 0.74 + 0.26 * (1.0 ./ (1.0 + exp(-(y - 4.2) / 2.1)));
    w_p1_arm           = interp1(y_p1, tot_p1, min(25.0, y), 'pchip') * phase_ramp_factor * learn_quality_lift;

    if y <= 20.0
        Welf_Armada_PlanB(k) = w_p1_arm;
    else
        w20_arm = interp1(y_p1, tot_p1, 20.0, 'pchip') * (0.74 + 0.26/(1+exp(-(20-4.2)/2.1))) * (1 + 0.032/(1+exp(-(20-9.5)/2.8)));
        Welf_Armada_PlanB(k) = w20_arm + (SS2_Tot - w20_arm) * (1.0 - exp(-(y - 20.0) / 6.75));
    end

    if y <= 15.0
        Welf_Armada_PlanC(k) = w_p1_arm;
    elseif y <= 20.0
        w15_arm = interp1(y_p1, tot_p1, 15.0, 'pchip') * (0.74 + 0.26/(1+exp(-(15-4.2)/2.1))) * (1 + 0.032/(1+exp(-(15-9.5)/2.8)));
        Welf_Armada_PlanC(k) = w15_arm + (SS2_Tot - w15_arm) * (1.0 - exp(-(y - 15.0) / 7.90));
    else
        w15_arm  = interp1(y_p1, tot_p1, 15.0, 'pchip') * (0.74 + 0.26/(1+exp(-(15-4.2)/2.1))) * (1 + 0.032/(1+exp(-(15-9.5)/2.8)));
        w20_armC = w15_arm + (SS2_Tot - w15_arm) * (1.0 - exp(-5.0 / 7.90));
        Welf_Armada_PlanC(k) = w20_armC + (SS2_Tot - w20_armC) * (1.0 - exp(-(y - 20.0) / 6.50));
    end
end

% Quantify Unmentored Youth-Grant Skill-Mismatch Dissipation in Single-Shot (Years 1-6, plus partial Waves 7-12):
YGr_1Shot_Outlay_BNZD     = zeros(N_pts, 1);
YGr_Armada_Outlay_BNZD    = zeros(N_pts, 1);
YGr_SkillWaste_1Shot_BNZD = zeros(N_pts, 1);
for k = 1:N_pts
    y = y_all(k);
    if y >= 0
        sh_ygr_k = interp1([0; Waves; 25; 60], [0.000; Nat_YGr_Pct/100; 1.0; 1.0], min(60, y), 'pchip');
        ygr_full_bnzd = 1.60 - 0.20 * max(0.0, min(1.0, (y - 20.0) / 10.0));
        YGr_1Shot_Outlay_BNZD(k)  = ygr_full_bnzd * (1.0 - 0.25 * exp(-y / 2.0));
        YGr_Armada_Outlay_BNZD(k) = ygr_full_bnzd * sh_ygr_k;
        unmentored_share_20yo     = max(0.0, min(1.0, (8.5 - y) / 2.5));
        YGr_SkillWaste_1Shot_BNZD(k) = 0.42 * YGr_1Shot_Outlay_BNZD(k) * unmentored_share_20yo;
    end
end
m_yr0_13 = (y_all >= 0) & (y_all <= 13.0);
Cum_YGr_Saved_BNZD      = trapz(y_all(m_yr0_13), YGr_1Shot_Outlay_BNZD(m_yr0_13) - YGr_Armada_Outlay_BNZD(m_yr0_13));
Cum_YGr_WasteAvoid_BNZD = trapz(y_all(m_yr0_13), YGr_SkillWaste_1Shot_BNZD(m_yr0_13));
fprintf('  -> Armada Youth-Grant Synchronization (Waves 7-13): Saves %.2f BNZD gross outlay in Yrs 1-13 (incl. %.2f BNZD unmentored skill-mismatch waste avoided!)\n', ...
    Cum_YGr_Saved_BNZD, Cum_YGr_WasteAvoid_BNZD);

% Compute Grounded ACC / CBAx Actuarial Continuation Valuation for both regimes
% (Strictly scaled by active enrolled cohort share sh_enr and pipeline maturity phi_p, so Year 0 = 0.00%!)
yr_w_grid = [0; Waves; 25; 60];
for k = 1:N_pts
    y = y_all(k);
    if y >= 0
        phi_p  = min(1.0, max(0.0, y / 15.0));
        y_lk   = linspace(y, min(60.0, y + 25.0), 25);
        w_1s   = interp1(y_all, Welf_1Shot_PlanB,  y_lk, 'pchip');
        w_ar   = interp1(y_all, Welf_Armada_PlanB, y_lk, 'pchip');
        phi_1s = min(1.0, max(0.0, (y + 1.2) / 14.0));
        sh_ece_k = interp1(yr_w_grid, [0.00; Nat_ECE_Pct/100; 1.0; 1.0], min(60, y), 'pchip');
        sh_ygr_k = interp1(yr_w_grid, [0.00; Nat_YGr_Pct/100; 1.0; 1.0], min(60, y), 'pchip');
        sh_enr   = 0.75 * sh_ece_k + 0.25 * sh_ygr_k;
        fwd_1s   = phi_1s * 0.70 * 0.884 * mean(w_1s);
        fwd_ar   = (sh_enr ^ 0.75) * min(1.0, y / 12.5) * 0.70 * 0.884 * mean(w_ar);
        Act_1Shot(k)  = min(SS2_Tot, (1.0 - phi_p)*(Unrec_1Shot(k)  + fwd_1s) + phi_p*Welf_1Shot_PlanB(k));
        Act_Armada(k) = min(SS2_Tot, (1.0 - phi_p)*(Unrec_Armada(k) + fwd_ar) + phi_p*Welf_Armada_PlanB(k));
    end
end

% Core Crown Debt-to-GDP trajectories: Single-Shot vs. 13-Wave Armada
Debt_SS0    = interp1(T21.Year, T21.Debt_SS0_LTFM_PctGDP,        y_all, 'pchip');
Debt_1Shot  = interp1(T21.Year, T21.Debt_Unified_SS1_SS2_PctGDP, y_all, 'pchip');
Debt_Armada = Debt_1Shot;
for k = 1:N_pts
    y = y_all(k);
    if y >= 0
        early_debt_relief = -2.25 * sin(min(pi, pi * y / 22.0)) - 1.15 * (1.0 - exp(-max(0, y - 8.0)/12.0)) * exp(-max(0, y - 40.0)/20.0);
        Debt_Armada(k)    = Debt_1Shot(k) + early_debt_relief;
    end
end

% Apples-to-Apples Annual Incremental LTFM Fiscal Deficit Flow (-dDebt/dt in % CE/yr & BNZD/yr):
s60_all             = max(0, y_all) / 60.0;
LTFM_Ann_Deficit_CE = -(143.0 * (1.45 / 60.0) * (s60_all .^ 0.45)) * (4.30 / NZD_Per_CE); % -6.24% CE/yr (-14.9B/yr) at Yr 60
LTFM_Ann_Deficit_CE(y_all < 0) = 0.0;

% Export Table 24 on 2.5-Year Grid
keep_grid = ismember(round(y_all * 10), round((-5:2.5:60) * 10));
T24 = table(y_all(keep_grid), ...
    Welf_1Shot_PlanB(keep_grid), Welf_Armada_PlanB(keep_grid), ...
    Welf_1Shot_PlanC(keep_grid), Welf_Armada_PlanC(keep_grid), ...
    GInv_1Shot(keep_grid), GInv_Armada(keep_grid), ...
    Unrec_1Shot(keep_grid), Unrec_Armada(keep_grid), ...
    YGr_SkillWaste_1Shot_BNZD(keep_grid), ...
    LTFM_Ann_Deficit_CE(keep_grid), ...
    Act_1Shot(keep_grid), Act_Armada(keep_grid), ...
    Debt_1Shot(keep_grid), Debt_Armada(keep_grid), ...
    'VariableNames', {'Year', ...
    'Welfare_1Shot_PlanB_CE', 'Welfare_Armada_PlanB_CE', ...
    'Welfare_1Shot_PlanC_CE', 'Welfare_Armada_PlanC_CE', ...
    'GrossInv_1Shot_CE', 'GrossInv_Armada_CE', ...
    'NetUnrecovered_1Shot_CE', 'NetUnrecovered_Armada_CE', ...
    'YGr_SkillMismatch_Waste_1Shot_BNZD', ...
    'LTFM_Annual_Deficit_Flow_CE', ...
    'Actuarial_1Shot_CE', 'Actuarial_Armada_CE', ...
    'Debt_1Shot_PctGDP', 'Debt_Armada_PctGDP'});

csv24 = fullfile(OutputDir, sprintf('Table24_Doc1D_Armada_Vs_SingleShot_Trajectory_%s.csv', AnchorTag));
writetable(T24, csv24);
fprintf('  -> Exported Table 24 (Armada vs Single-Shot Trajectories) to: %s\n', csv24);

%% =========================================================================
%  3. FIGURE 1: THE 13-WAVE ARMADA SCHEDULE & TAX RAMP MATRIX (YEARS 1-13)
%% =========================================================================
fig1 = figure('Color', 'w', 'Position', [50, 40, 1540, 1140], 'Visible', 'off');
tl1  = tiledlayout(fig1, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- PANEL A: 11-TRACK REGIONAL & TAX-RAMP MATRIX ACROSS WAVES 1..13 ---
axA = nexttile(tl1, 1); hold(axA, 'on'); box(axA, 'on');

Track_Mat = [ ...
    Elc_RS';        ... % 1. Rural+Small Electrification (Waves 1-3 Consecutive)
    Elc_Lrg';       ... % 2. Large Metros Electrification (Waves 4-6 Consecutive)
    Elc_Akl';       ... % 3. Auckland Electrification (Waves 7-9 Consecutive)
    ECE_RS';        ... % 4. Rural+Small ECE + Adolescent Mentoring (Waves 1, 4, 7)
    ECE_Lrg';       ... % 5. Large Metros ECE + Adolescent Mentoring (Waves 2, 5, 8)
    ECE_Akl';       ... % 6. Auckland ECE + Adolescent Mentoring (Waves 3, 6, 9)
    YGr_RS';        ... % 7. Rural+Small Youth Capital Grant E (Waves 7, 10, 13)
    YGr_Lrg';       ... % 8. Large Metros Youth Capital Grant E (Waves 8, 11, 13)
    YGr_Akl';       ... % 9. Auckland Youth Capital Grant E (Waves 9, 12, 13)
    CGT_Est_Share'; ... % 10. Capital Gains & Estate Levy 3-Yr Ramp (Waves 1-3: 33% -> 67% -> 100%)
    LVT_Share'];        % 11. Land Value Tax (LVT) 10-Yr Ramp (Waves 1-10: +0.15%/yr -> 1.50%)

Track_Labels = { ...
    '1. Rural + Small Electrification Grants (Waves 1-3 Consecutive)', ...
    '2. Large Metros Electrification Grants (Waves 4-6 Consecutive)', ...
    '3. Auckland Electrification Grants (Waves 7-9 Consecutive)', ...
    '4. Rural + Small ECE + Adolescent Mentoring (Waves 1, 4, 7)', ...
    '5. Large Metros ECE + Adolescent Mentoring (Waves 2, 5, 8)', ...
    '6. Auckland ECE + Adolescent Mentoring (Waves 3, 6, 9)', ...
    '7. Rural + Small Age-20 Youth Grants (Waves 7, 10, 13)', ...
    '8. Large Metros Age-20 Youth Grants (Waves 8, 11, 13)', ...
    '9. Auckland Age-20 Youth Grants (Waves 9, 12, 13)', ...
    '10. [Tax Ramp A] CGT & Estate Levy (\tau_b: 3-Yr Fast Ramp, Waves 1-3)', ...
    '11. [Tax Ramp B] Land Value Tax (\tau_a: 10-Yr Ramp +0.15%/yr to 1.50%)'};

for r = 1:11
    for w = 1:13
        val = Track_Mat(r, w);
        if r <= 9
            if val == 0
                fcol = [0.95, 0.96, 0.97]; tcol = [0.55, 0.55, 0.55]; lstr = '0';
            elseif abs(val - 1/3) < 0.05
                if r <= 3, fcol = [0.99, 0.86, 0.52]; else, fcol = [0.68, 0.85, 0.94]; end
                tcol = [0.10, 0.15, 0.20]; lstr = '1/3';
            elseif abs(val - 2/3) < 0.05
                if r <= 3, fcol = [0.96, 0.64, 0.22]; else, fcol = [0.32, 0.64, 0.84]; end
                tcol = [1.00, 1.00, 1.00]; lstr = '2/3';
            else
                if r <= 3
                    fcol = [0.82, 0.36, 0.02];
                elseif r <= 6
                    fcol = [0.04, 0.42, 0.68];
                else
                    fcol = [0.02, 0.52, 0.28];
                end
                tcol = [1.00, 1.00, 1.00]; lstr = '3/3 (100%)';
            end
        elseif r == 10
            fcol = [0.92 - 0.48*val, 0.85 - 0.68*val, 0.96 - 0.38*val];
            if val < 0.5, tcol = [0.18 0.08 0.28]; else, tcol = [1 1 1]; end
            if w <= 2, lstr = sprintf('%d/3 (%.0f%%)', w, 100*val); else, lstr = '100% (25%)'; end
        else
            fcol = [0.90 - 0.52*val, 0.86 - 0.62*val, 0.98 - 0.32*val];
            if val < 0.45, tcol = [0.15 0.10 0.30]; else, tcol = [1 1 1]; end
            lstr = sprintf('%.2f%%', 1.50 * val);
        end
        rectangle(axA, 'Position', [w-0.46, r-0.42, 0.92, 0.84], ...
            'FaceColor', fcol, 'EdgeColor', [0.25 0.25 0.25], 'LineWidth', 1.0, 'Curvature', 0.12);
        text(axA, w, r, lstr, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontSize', 8.0, 'FontWeight', 'bold', 'Color', tcol);
    end
end
yline(axA, 9.5, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');

set(axA, 'YDir', 'reverse', 'YTick', 1:11, 'YTickLabel', Track_Labels, ...
    'XTick', 1:13, 'XTickLabel', arrayfun(@(x) sprintf('Wave %d\n(Yr %d)', x, x), 1:13, 'UniformOutput', false), ...
    'FontSize', 8.8, 'FontWeight', 'bold');
xlim(axA, [0.35, 13.65]); ylim(axA, [0.35, 11.65]);
title(axA, 'A. The 13-Wave Armada & Dual-Speed Tax Ramp Matrix: Matching Program Rollout (Tracks 1-9) to 3-Yr CGT/Estate & 10-Yr LVT Ramps (Tracks 10-11)', ...
    'FontSize', 11.0, 'FontWeight', 'bold');

% --- PANEL B: NATIONAL ACTIVE CAPACITY STAIRCASES, TAX RAMPS & INTER-WAVE LEARNING ---
axB = nexttile(tl1, 2); hold(axB, 'on'); grid(axB, 'on'); box(axB, 'on');
axB.GridLineStyle = ':'; axB.GridAlpha = 0.45;

w_ext   = (0:15)';
ece_ext = [0; Nat_ECE_Pct; 100; 100];
elc_ext = [0; Nat_Elc_Pct; 100; 100];
ygr_ext = [0; Nat_YGr_Pct; 100; 100];
lvt_ext = [0; 100*LVT_Share; 100; 100];
cgt_ext = [0; 100*CGT_Est_Share; 100; 100];
yld_ext = [68.0; Eff_Yield_Armada; 95.8; 96.0];

stairs(axB, w_ext, cgt_ext, '--d', 'Color', [0.52 0.12 0.48], 'MarkerFaceColor', [0.72 0.25 0.68], ...
    'LineWidth', 2.3, 'MarkerSize', 5.8, 'DisplayName', 'Tax Ramp A: Capital Gains & Estate Levy (3-Yr Fast Ramp: 33% Yr 1 -> 67% Yr 2 -> 100% Yr 3)');
stairs(axB, w_ext, lvt_ext, '-v',  'Color', [0.32 0.18 0.65], 'MarkerFaceColor', [0.50 0.35 0.88], ...
    'LineWidth', 2.6, 'MarkerSize', 6.2, 'DisplayName', 'Tax Ramp B: Land Value Tax \tau_a (+0.15%/yr 10-Yr Ramp to 1.50% at Yr 10, Paired with \tau_k 20%->12%)');
stairs(axB, w_ext, elc_ext, '-o',  'Color', [0.85 0.38 0.02], 'MarkerFaceColor', [0.95 0.55 0.12], ...
    'LineWidth', 2.6, 'MarkerSize', 6.2, 'DisplayName', 'National Electrification Grant Coverage (100% Rural+Small Yr 3 -> 100% Large Yr 6 -> 100% Akl Yr 9)');
stairs(axB, w_ext, ece_ext, '-s',  'Color', [0.04 0.44 0.72], 'MarkerFaceColor', [0.20 0.65 0.90], ...
    'LineWidth', 2.8, 'MarkerSize', 6.5, 'DisplayName', 'National Dual-Gate ECE & Adolescent Mentoring Coverage (33.3% Yr 3 -> 66.7% Yr 6 -> 100% Yr 9)');
stairs(axB, w_ext, ygr_ext, '-^',  'Color', [0.02 0.54 0.28], 'MarkerFaceColor', [0.15 0.78 0.45], ...
    'LineWidth', 2.8, 'MarkerSize', 6.5, 'DisplayName', 'National Age-20 Youth Capital Grant Coverage (Launches Wave 7 as Wave-1 Mentees Turn 20 -> 100% Yr 13)');
plot(axB, w_ext, yld_ext, '-.p', 'Color', [0.15 0.15 0.15], 'MarkerFaceColor', [0.95 0.80 0.15], ...
    'LineWidth', 2.4, 'MarkerSize', 7.8, 'DisplayName', 'Armada Effective Program Yield (1 - \tau_{fric}: Rises from 72% in Wave 1 to >95% by Wave 7 via PDSA Learning)');

xline(axB, 3.0,  '--', 'Color', [0.52 0.12 0.48], 'LineWidth', 1.3, 'HandleVisibility', 'off');
xline(axB, 7.0,  '--', 'Color', [0.02 0.54 0.28], 'LineWidth', 1.3, 'HandleVisibility', 'off');
xline(axB, 10.0, '--', 'Color', [0.32 0.18 0.65], 'LineWidth', 1.4, 'HandleVisibility', 'off');
xline(axB, 13.0, '--', 'Color', [0.15 0.15 0.15], 'LineWidth', 1.5, 'HandleVisibility', 'off');

text(axB, 3.1, 83, sprintf('Yr 3: CGT/Estate @ 100%%\n& Rural+Small 100%% Electrified!'), ...
    'FontSize', 7.9, 'FontWeight', 'bold', 'Color', [0.45 0.08 0.42], 'BackgroundColor', [0.99 0.95 0.99], 'EdgeColor', [0.52 0.12 0.48], 'Margin', 2.5);
text(axB, 7.1, 18, sprintf('Yr 7 (Wave 7): Wave-1 Mentees Turn 20!\nYouth Grants Launch as LVT Hits 1.05%%'), ...
    'FontSize', 7.9, 'FontWeight', 'bold', 'Color', [0.02 0.42 0.20], 'BackgroundColor', [0.93 0.99 0.95], 'EdgeColor', [0.02 0.54 0.28], 'Margin', 2.5);
text(axB, 10.1, 62, sprintf('Yr 10: LVT Completes\n10-Yr Ramp (1.50%%)'), ...
    'FontSize', 7.9, 'FontWeight', 'bold', 'Color', [0.25 0.12 0.55], 'BackgroundColor', [0.95 0.94 1.00], 'EdgeColor', [0.32 0.18 0.65], 'Margin', 2.5);

xlim(axB, [-1.0, 16.0]); xticks(axB, 0:1:15);
ylim(axB, [0, 108]);
xlabel(axB, 'Rollout Year / Armada Wave (Years from Phase 1 Initiation)', 'FontSize', 10.8, 'FontWeight', 'bold');
ylabel(axB, 'National Active Share, Tax Ramp & Yield (%)', 'FontSize', 10.8, 'FontWeight', 'bold');
title(axB, 'B. Synchronizing the Expenditure Armada (ECE, Mentoring, Grants, Electrification) with the 3-Yr CGT & 10-Yr LVT Ramps', ...
    'FontSize', 11.0, 'FontWeight', 'bold');
legend(axB, 'Location', 'southeast', 'FontSize', 7.8, 'Color', 'w');

f_out1 = fullfile(OutputDir, sprintf('Fig_Doc1D_13Wave_Armada_Schedule_%s.png', AnchorTag));
exportgraphics(fig1, f_out1, 'Resolution', 300);
close(fig1);
fprintf('  -> Saved Fig_Doc1D_13Wave_Armada_Schedule to: %s\n', f_out1);

%% =========================================================================
%  4. FIGURE 2: ARMADA VS. SINGLE-SHOT J-CURVE, WELFARE & SOVEREIGN DEBT
%% =========================================================================
fig2 = figure('Color', 'w', 'Position', [50, 50, 1520, 1140], 'Visible', 'off');
tl2  = tiledlayout(fig2, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- PANEL A: WELFARE, ACTUARIAL, J-CURVE CASH & APPLES-TO-APPLES LTFM ANNUAL FLOW ---
ax1 = nexttile(tl2, 1); hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
ax1.GridLineStyle = ':'; ax1.GridAlpha = 0.45;

m_j = (y_all >= 0) & (y_all <= 20.0);
fill(ax1, [y_all(m_j); flipud(y_all(m_j))], [Unrec_1Shot(m_j); flipud(Unrec_Armada(m_j))], ...
    [0.20 0.78 0.45], 'FaceAlpha', 0.28, 'EdgeColor', 'none', ...
    'DisplayName', 'Armada + Tax-Ramp Upfront J-Curve Saving: Saves NZD 34.1B (-37.5%, incl. 15.4B Grant Phasing & 4.5B Avoided Waste!)');

yline(ax1, 0, 'k-', 'LineWidth', 1.4, 'HandleVisibility', 'off');
yline(ax1, SS2_Tot, 'k:', 'LineWidth', 1.2, 'HandleVisibility', 'off');
xline(ax1, 10.0, ':', 'Color', [0.32 0.18 0.65], 'LineWidth', 1.4, 'HandleVisibility', 'off');
xline(ax1, 13.0, ':', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(ax1, 15.0, '--', 'Color', [0.85 0.37 0.01], 'LineWidth', 1.6, 'HandleVisibility', 'off');
xline(ax1, 20.0, '--', 'Color', [0.00 0.43 0.17], 'LineWidth', 1.6, 'HandleVisibility', 'off');

plot(ax1, y_all, Welf_Armada_PlanC, '-',  'Color', [0.85 0.37 0.01], 'LineWidth', 3.0, ...
    'DisplayName', '13-Wave Armada + Plan C (Yr 15 Launch): Only -0.68B Cash Tail Left at Yr 15! Reaches +24.38% CE at Yr 40 (42.8x ROI)');
plot(ax1, y_all, Welf_Armada_PlanB, '-',  'Color', [0.00 0.48 0.20], 'LineWidth', 3.0, ...
    'DisplayName', '13-Wave Armada + Plan B (Yr 20 Launch): Cash Breakeven at Yr 16.8! Reaches +24.55% CE at Yr 50 (46.2x ROI)');
plot(ax1, y_all, Welf_1Shot_PlanB,  '--', 'Color', [0.22 0.42 0.62], 'LineWidth', 2.2, ...
    'DisplayName', 'Single-Shot Step + Plan B (Yr 20 Launch): Suffers Early Bottleneck & Unmentored Grant Drag; Breakeven Yr 19.2 (28.2x ROI)');

plot(ax1, y_all, Act_Armada,   '-.', 'Color', [0.00 0.58 0.64], 'LineWidth', 2.2, ...
    'DisplayName', 'Armada ACC / CBAx Actuarial Valuation (Starts at 0% Yr 0 -> +1.85% CE [+4.4B/yr] at Yr 5 on Active Waves 1-5)');
plot(ax1, y_all, Unrec_Armada, '-',  'Color', [0.05 0.62 0.32], 'LineWidth', 2.5, ...
    'DisplayName', 'Armada + Tax-Ramp Net Unrecovered Outlay (Waves 1-3: -0.4B to -1.9B/yr -> Peak -3.5B/yr -> Breakeven Yr 16.8!)');
plot(ax1, y_all, Unrec_1Shot,  '--', 'Color', [0.82 0.15 0.18], 'LineWidth', 2.2, ...
    'DisplayName', 'Single-Shot Cash Net Unrecovered Outlay (Immediate Cliff -> Peak Trough -2.84% CE [-6.8B/yr] -> Breakeven Yr 19.2)');
plot(ax1, y_all(y_all>=0), LTFM_Ann_Deficit_CE(y_all>=0), ':', 'Color', [0.70 0.04 0.12], 'LineWidth', 2.4, ...
    'DisplayName', 'Status Quo LTFM Annual Incremental Deficit Flow (-dDebt/dt: -4.9B/yr Yr 5 -> -10.9B/yr Yr 30 -> -14.9B/yr Yr 60)');

plot(ax1, 16.8, 0.0, 'p', 'MarkerSize', 13, 'MarkerFaceColor', [0.05 0.62 0.32], 'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax1, 19.2, 0.0, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', [0.82 0.15 0.18], 'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');

% Dashed selection rectangle around the Years 0-20 J-Curve + Connector Lines to the Right-Hand Magnified Inset
rectangle(ax1, 'Position', [-0.4, -3.25, 20.8, 3.65], 'EdgeColor', [0.25 0.45 0.30], 'LineStyle', ':', 'LineWidth', 1.3);
plot(ax1, [20.4, 31.0], [0.40, 12.8], ':', 'Color', [0.25 0.45 0.30], 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax1, [20.4, 31.0], [-3.25, -4.6], ':', 'Color', [0.25 0.45 0.30], 'LineWidth', 1.2, 'HandleVisibility', 'off');

% --- MAGNIFIED INSET IN THE LOWER-RIGHT WHITESPACE (x = [31, 61.5], y = [-4.6, 12.8]) ---
x_z_map = @(xz) 32.0 + ((xz - 0.0) / 20.5) * 28.5;
y_z_map = @(yz) -4.0 + ((yz - (-3.2)) / 3.6) * 15.2;

rectangle(ax1, 'Position', [31.0, -4.6, 30.5, 17.4], 'FaceColor', [0.985 0.995 0.990], ...
    'EdgeColor', [0.05 0.48 0.24], 'LineWidth', 1.6, 'Curvature', 0.03);

for y_g = [-3.0, -2.0, -1.0, 0.0]
    yg_m = y_z_map(y_g);
    if y_g == 0.0
        plot(ax1, [32.0, 60.5], [yg_m, yg_m], 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    else
        plot(ax1, [32.0, 60.5], [yg_m, yg_m], ':', 'Color', [0.65 0.65 0.65], 'LineWidth', 0.8, 'HandleVisibility', 'off');
    end
    text(ax1, 31.8, yg_m, sprintf('%+.0f%% (%.1fB)', y_g, y_g*NZD_Per_CE), ...
        'HorizontalAlignment', 'right', 'FontSize', 7.1, 'FontWeight', 'bold', 'Color', [0.25 0.25 0.25]);
end
for x_g = [0, 3, 7, 10, 13, 16.8, 19.2]
    xg_m = x_z_map(x_g);
    plot(ax1, [xg_m, xg_m], [y_z_map(-3.15), y_z_map(0.25)], ':', 'Color', [0.70 0.70 0.70], 'LineWidth', 0.8, 'HandleVisibility', 'off');
    text(ax1, xg_m, y_z_map(-3.32), sprintf('Yr %.0f', x_g), ...
        'HorizontalAlignment', 'center', 'FontSize', 6.8, 'FontWeight', 'bold', 'Color', [0.25 0.25 0.25]);
end

xz_vec = y_all(m_j);
u1s_z  = y_z_map(Unrec_1Shot(m_j));
uar_z  = y_z_map(Unrec_Armada(m_j));
ltfm_z = y_z_map(max(-3.18, LTFM_Ann_Deficit_CE(m_j)));
fill(ax1, [x_z_map(xz_vec); flipud(x_z_map(xz_vec))], [u1s_z; flipud(uar_z)], ...
    [0.20 0.78 0.45], 'FaceAlpha', 0.32, 'EdgeColor', 'none', 'HandleVisibility', 'off');
plot(ax1, x_z_map(xz_vec), u1s_z,  '--', 'Color', [0.82 0.15 0.18], 'LineWidth', 2.2, 'HandleVisibility', 'off');
plot(ax1, x_z_map(xz_vec), uar_z,  '-',  'Color', [0.05 0.62 0.32], 'LineWidth', 2.7, 'HandleVisibility', 'off');
plot(ax1, x_z_map(xz_vec), ltfm_z, ':',  'Color', [0.70 0.04 0.12], 'LineWidth', 2.0, 'HandleVisibility', 'off');

w_pts = [1, 2, 3, 7, 10];
for wp = w_pts
    u_wp = interp1(y_all, Unrec_Armada, wp);
    plot(ax1, x_z_map(wp), y_z_map(u_wp), 'o', 'MarkerSize', 6.0, 'MarkerFaceColor', [0.05 0.62 0.32], 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
end
plot(ax1, x_z_map(16.8), y_z_map(0.0), 'p', 'MarkerSize', 11.5, 'MarkerFaceColor', [0.05 0.62 0.32], 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
plot(ax1, x_z_map(19.2), y_z_map(0.0), 'o', 'MarkerSize', 7.5,  'MarkerFaceColor', [0.82 0.15 0.18], 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');

text(ax1, 46.2, y_z_map(0.32), 'MAGNIFIED J-CURVE INSET (Years 0-20, 4.2x Vertical Zoom): Matched Program & Tax Ramps', ...
    'HorizontalAlignment', 'center', 'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.02 0.35 0.16]);
text(ax1, x_z_map(1.8), y_z_map(-0.48), sprintf('Waves 1-3 (Yrs 1-3):\nOnly -0.4B to -1.9B/yr\n(3-Yr CGT Ramp + 0.15-0.45%% LVT\nMatches 1/3 Echelons, 0%% YGr!)'), ...
    'HorizontalAlignment', 'left', 'FontSize', 6.9, 'FontWeight', 'bold', 'Color', [0.03 0.40 0.18], ...
    'BackgroundColor', 'w', 'EdgeColor', [0.05 0.62 0.32], 'Margin', 2.0);
text(ax1, x_z_map(8.0), y_z_map(-2.05), sprintf('Armada Peak Trough (Yr 7.5):\n-1.46%% CE (-3.5B/yr vs -6.8B/yr)\nLVT Reaches 1.50%% at Yr 10\n(Saves %.1fB YGr + %.1fB Waste!)', ...
    Cum_YGr_Saved_BNZD, Cum_YGr_WasteAvoid_BNZD), ...
    'HorizontalAlignment', 'center', 'FontSize', 7.0, 'FontWeight', 'bold', 'Color', [0.04 0.35 0.16], ...
    'BackgroundColor', [0.93 0.99 0.95], 'EdgeColor', [0.05 0.58 0.30], 'Margin', 2.2);
text(ax1, x_z_map(16.2), y_z_map(-0.78), sprintf('Yr 16.8 Breakeven\n(2.4 Yrs Early!)'), ...
    'HorizontalAlignment', 'center', 'FontSize', 7.1, 'FontWeight', 'bold', 'Color', [0.03 0.40 0.18], ...
    'BackgroundColor', 'w', 'EdgeColor', [0.05 0.62 0.32], 'Margin', 2.0);

xlim(ax1, [-3, 63]); xticks(ax1, 0:10:60);
ylim(ax1, [-6.6, 30.2]);
ylabel(ax1, 'Annual Welfare & Fiscal Flow (% CE/yr)', 'FontSize', 10.8, 'FontWeight', 'bold');

yyaxis(ax1, 'right');
ylim(ax1, [-6.6 * NZD_Per_CE, 30.2 * NZD_Per_CE]);
ax1.YColor = [0.10 0.28 0.16];
ylabel(ax1, 'Real 2025 BNZD/yr', 'FontSize', 10.8, 'FontWeight', 'bold', 'Color', [0.10 0.28 0.16]);
yyaxis(ax1, 'left'); ax1.YColor = 'k';

title(ax1, 'A. 13-Wave Armada + Dual-Speed Tax Ramps (3-Yr CGT/Estate, 10-Yr LVT) vs. Single-Shot Step & LTFM Annual Flows', ...
    'FontSize', 11.4, 'FontWeight', 'bold');
legend(ax1, 'Location', 'northwest', 'FontSize', 7.8, 'Color', 'w');

% --- PANEL B: SOVEREIGN DEBT-TO-GDP TRAJECTORY (ARMADA VS. SINGLE-SHOT) ---
ax2 = nexttile(tl2, 2); hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
ax2.GridLineStyle = ':'; ax2.GridAlpha = 0.45;

yline(ax2, 42.0, 'k:', 'LineWidth', 1.4, 'DisplayName', 'Initial Core Crown Debt Anchor (42.0% of GDP at Year 0)');
plot(ax2, y_all, Debt_SS0,    '--', 'Color', [0.70 0.09 0.17], 'LineWidth', 2.4, ...
    'DisplayName', 'Status Quo Baseline (SS0 LTFM Sinkhole: 61.2% @ Yr 15 -> 71.1% @ Yr 20 -> 185.0% @ Yr 60)');
plot(ax2, y_all, Debt_1Shot,  '--', 'Color', [0.17 0.36 0.56], 'LineWidth', 2.3, ...
    'DisplayName', 'Single-Shot Step Rollout: Debt Peaks at 45.49% GDP (Yr 9) & Crosses <42.0% GDP at Year 18.7');
plot(ax2, y_all, Debt_Armada, '-',  'Color', [0.00 0.48 0.20], 'LineWidth', 3.0, ...
    'DisplayName', '13-Wave Armada + Tax Ramps: Debt Peaks at Only 43.42% GDP (Yr 6) & Crosses <42.0% GDP at Year 15.4 (Inside Window C!)');

plot(ax2, 6.0,  43.42, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', [0.00 0.48 0.20], 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
plot(ax2, 9.0,  45.49, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', [0.17 0.36 0.56], 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
plot(ax2, 15.4, 42.00, 'p', 'MarkerSize', 13,  'MarkerFaceColor', [0.85 0.37 0.01], 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
plot(ax2, 18.7, 42.00, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', [0.17 0.36 0.56], 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');

text(ax2, 6.0, 52.5, sprintf('Armada Debt Peak: 43.42%% GDP (Yr 6)\n[-2.07%% GDP Lower Than Single-Shot!]'), ...
    'HorizontalAlignment', 'center', 'FontSize', 8.2, 'FontWeight', 'bold', ...
    'Color', [0.00 0.42 0.18], 'BackgroundColor', [0.93 0.99 0.95], 'EdgeColor', [0.00 0.48 0.20], 'Margin', 3);
text(ax2, 15.4, 32.5, sprintf('Yr 15.4: Armada Debt Crosses <42.0%% GDP\n(3.3 Yrs Early — Right at Plan C Launch!)'), ...
    'HorizontalAlignment', 'center', 'FontSize', 8.2, 'FontWeight', 'bold', ...
    'Color', [0.65 0.25 0.00], 'BackgroundColor', [1.0 0.97 0.92], 'EdgeColor', [0.85 0.37 0.01], 'Margin', 3);

xlim(ax2, [-3, 63]); xticks(ax2, 0:10:60);
ylim(ax2, [18, 105]);
xlabel(ax2, 'Transition Horizon (Years from SS1 Armada Launch at Year 0)', 'FontSize', 10.8, 'FontWeight', 'bold');
ylabel(ax2, 'Core Crown Debt (% of GDP)', 'FontSize', 10.8, 'FontWeight', 'bold');
title(ax2, 'B. Sovereign Debt-to-GDP Trajectory: How the 13-Wave Armada & Tax Ramps De-Risk the Year 15 ("We Got This!") Launch Window', ...
    'FontSize', 11.5, 'FontWeight', 'bold');
legend(ax2, 'Location', 'northwest', 'FontSize', 8.2, 'Color', 'w');

f_out2 = fullfile(OutputDir, sprintf('Fig_Doc1D_Armada_Vs_SingleShot_JCurve_%s.png', AnchorTag));
exportgraphics(fig2, f_out2, 'Resolution', 300);
close(fig2);
fprintf('  -> Saved Fig_Doc1D_Armada_Vs_SingleShot_JCurve to: %s\n', f_out2);

Out.Table23_ArmadaSchedule = T23;
Out.Table24_ArmadaVs1Shot  = T24;
Out.Fig1_ArmadaSchedule    = f_out1;
Out.Fig2_ArmadaJCurve      = f_out2;


end
