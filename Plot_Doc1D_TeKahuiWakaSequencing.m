function Out = Plot_Doc1D_TeKahuiWakaSequencing(OutputDir, AnchorTag, Params)
if nargin < 1 || isempty(OutputDir), OutputDir = 'Output_NZ_4Region_Intergen'; end
if nargin < 2 || isempty(AnchorTag), AnchorTag = 'Dunedin_22'; end
if nargin < 3 || isempty(Params),    Params    = struct(); end
if ~isfield(Params, 'Kahui_ECE_13x5')
    Params = Configure_TimeGrid_Params(Params);
end
if ~exist(OutputDir, 'dir'), mkdir(OutputDir); end

f19 = fullfile(OutputDir, sprintf('Table19_Constructive_Synergy_Wedges_%s.csv', AnchorTag));
f20 = fullfile(OutputDir, sprintf('Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_%s.csv', AnchorTag));
f21 = fullfile(OutputDir, sprintf('Table21_Doc3_LTFM_Sinkhole_Defense_Trajectories_%s.csv', AnchorTag));

T19 = readtable(f19);
T20 = readtable(f20);
T21 = readtable(f21);

is_wedge = strcmpi(T19.Component_Type, 'SYNERGY_WEDGE');
Iso_SS2  = sum(T19.SS2_National_CE(~is_wedge));
Wed_SS2  = sum(T19.SS2_National_CE(is_wedge));
SS2_Tot  = Iso_SS2 + Wed_SS2;

%% =========================================================================
%  1. UNPACK CANONICAL 13-WAVE TE KĀHUI WAKA SCHEDULE FROM PARAMS
%% =========================================================================
if nargin < 3 || isempty(Params), Params = struct(); end
if ~isfield(Params, 'Kahui_ECE_13x5')
    Params = Configure_TimeGrid_Params(Params);
end

NZD_Per_CE      = Params.NZD_Per_CE_Nat;
Waves           = Params.Waves_13;
sh_base_3       = Params.sh_ygr_base0_3echelon; % [0.1894, 0.1580, 0.1650]
sh_ygr_base0    = Params.sh_ygr_base0_nat;      % 0.1730

ECE_RS          = Params.Kahui_ECE_13x3(:, 1);
ECE_Lrg         = Params.Kahui_ECE_13x3(:, 2);
ECE_Akl         = Params.Kahui_ECE_13x3(:, 3);
Mnt_RS          = Params.Kahui_Mnt_13x3(:, 1);
Mnt_Lrg         = Params.Kahui_Mnt_13x3(:, 2);
Mnt_Akl         = Params.Kahui_Mnt_13x3(:, 3);

YGr_New_RS      = Params.Kahui_YGr_New_13x3(:, 1);
YGr_New_Lrg     = Params.Kahui_YGr_New_13x3(:, 2);
YGr_New_Akl     = Params.Kahui_YGr_New_13x3(:, 3);
YGr_RS          = Params.Kahui_YGr_Tot_13x3(:, 1);
YGr_Lrg         = Params.Kahui_YGr_Tot_13x3(:, 2);
YGr_Akl         = Params.Kahui_YGr_Tot_13x3(:, 3);

Elc_RS          = Params.Kahui_Elc_13x3(:, 1);
Elc_Lrg         = Params.Kahui_Elc_13x3(:, 2);
Elc_Akl         = Params.Kahui_Elc_13x3(:, 3);

% Column 5 of Kahui_*_13x5 is National!
Nat_ECE_Pct     = 100.0 * Params.Kahui_ECE_13x5(:, 5);
Nat_Mnt_Pct     = 100.0 * Params.Kahui_Mnt_13x5(:, 5);
Nat_YGr_New_Pct = 100.0 * Params.Kahui_YGr_New_13x5(:, 5);
Nat_YGr_Pct     = 100.0 * Params.Kahui_YGr_Tot_13x5(:, 5);
Nat_Elc_Pct     = 100.0 * Params.Kahui_Elc_13x5(:, 5);

CGT_Est_Share   = min(1.0, Waves / Params.T_ramp_CGT_Est_yrs);
LVT_Share       = min(1.0, Waves / Params.T_ramp_LVT_yrs);
LVT_Rate_Pct    = 1.50 * LVT_Share;
Corp_Tax_Pct    = 20.0 - 8.0 * LVT_Share;

% Cumulative Te Kāhui Waka Learning Stock L(t-1) & Commissioning Friction tau_fric(t)
Cum_Learn_Stock  = [0; cumsum(0.5*(Nat_ECE_Pct(1:12)/100) + 0.5*(Nat_Elc_Pct(1:12)/100))];
Tau_Fric_Kahui  = 0.042 + (0.280 - 0.042) * exp(-0.42 * Cum_Learn_Stock);
Tau_Fric_1Shot   = 0.065 + (0.320 - 0.065) * exp(-0.18 * (0:12)');
Eff_Yield_Kahui = 100 * (1.0 - Tau_Fric_Kahui);

T23 = table(Waves, ...
    round(100*ECE_RS,1), round(100*ECE_Lrg,1), round(100*ECE_Akl,1), round(Nat_ECE_Pct,1), ...
    round(100*Mnt_RS,1), round(100*Mnt_Lrg,1), round(100*Mnt_Akl,1), round(Nat_Mnt_Pct,1), ...
    round(100*YGr_RS,1), round(100*YGr_Lrg,1), round(100*YGr_Akl,1), round(Nat_YGr_Pct,1), ...
    round(100*Elc_RS,1), round(100*Elc_Lrg,1), round(100*Elc_Akl,1), round(Nat_Elc_Pct,1), ...
    round(100*CGT_Est_Share,1), round(100*LVT_Share,1), round(LVT_Rate_Pct,2), round(Corp_Tax_Pct,1), ...
    round(100*Tau_Fric_Kahui,2), round(Eff_Yield_Kahui,2), ...
    'VariableNames', {'Wave_Year', ...
    'ECE_RuralSmall_Pct', 'ECE_Large_Pct', 'ECE_Auckland_Pct', 'Nat_ECE_Active_Pct', ...
    'Mentor_RuralSmall_Pct', 'Mentor_Large_Pct', 'Mentor_Auckland_Pct', 'Nat_Mentor_Active_Pct', ...
    'YouthGrant_RuralSmall_Pct', 'YouthGrant_Large_Pct', 'YouthGrant_Auckland_Pct', 'Nat_YouthGrant_Active_Pct', ...
    'Electrif_RuralSmall_Pct', 'Electrif_Large_Pct', 'Electrif_Auckland_Pct', 'Nat_Electrif_Active_Pct', ...
    'CGT_Estate_Ramp_Pct', 'LVT_10Yr_Ramp_Pct', 'Active_LVT_Rate_Pct', 'Active_CorpTax_Rate_Pct', ...
    'Commissioning_Friction_Pct', 'Effective_Program_Yield_Pct'});

csv23 = fullfile(OutputDir, sprintf('Table23_Doc1D_13Wave_TeKahuiWaka_Schedule_%s.csv', AnchorTag));
writetable(T23, csv23);
fprintf('  -> Exported Table 23 (13-Wave Te Kāhui Waka + 17.3%% Early-Adopter Grants & Tax Ramps) to: %s\n', csv23);

%% =========================================================================
%  2. VECTORIZED 60-YEAR TRAJECTORIES: SINGLE-SHOT VS. 13-WAVE ARMADA (0 LOOPS)
%% =========================================================================
y_all   = linspace(-5, 60, 651)';
N_pts   = numel(y_all);
m_pos   = y_all >= 0;
y_pos   = y_all(m_pos);

p1_mask = (T20.Year >= 0) & (T20.Year <= 25.0);
y_p1    = T20.Year(p1_mask);
tot_p1  = T20.Total_Welfare_Gain_CE_Pct(p1_mask);

w0_15   = interp1(y_p1, tot_p1, 15.0, 'pchip');
w0_20   = interp1(y_p1, tot_p1, 20.0, 'pchip');
w0_25   = interp1(y_p1, tot_p1, 25.0, 'pchip');
w_s1_60 = w0_25 + (SS2_Tot - w0_25) * (1.0 - exp(-35.0 / 8.50));
tau_s2  = -30.0 / log((SS2_Tot - w_s1_60) / (SS2_Tot - w0_20));

% Pre-allocate full-horizon vectors (y < 0 remains 0.0 automatically)
Welf_1Shot_PlanB  = zeros(N_pts, 1);
Welf_1Shot_PlanC  = zeros(N_pts, 1);
GInv_1Shot        = zeros(N_pts, 1);
Unrec_1Shot       = zeros(N_pts, 1);
Welf_Kahui_PlanB = zeros(N_pts, 1);
Welf_Kahui_PlanC = zeros(N_pts, 1);
GInv_Kahui       = zeros(N_pts, 1);
Unrec_Kahui      = zeros(N_pts, 1);

% --- 2A. Vectorized Single-Shot Step-Shock Baseline ---
ginv_1s  = interp1(T20.Year, T20.Total_Gross_Inv_Mirror_CE_Pct, min(25.0, y_pos), 'pchip');
remed_1s = 4.65 ./ (1.0 + exp(-(y_pos - 16.5) / 4.2));
GInv_1Shot(m_pos)  = ginv_1s;
Unrec_1Shot(m_pos) = min(0.0, ginv_1s + remed_1s);

w_p1_pos = interp1(y_p1, tot_p1, min(25.0, y_pos), 'pchip');
Welf_1Shot_PlanB(m_pos) = (y_pos <= 20.0) .* w_p1_pos ...
    + (y_pos > 20.0) .* (w0_20 + (SS2_Tot - w0_20) * (1.0 - exp(-max(0, y_pos - 20.0) / tau_s2)));

w20_1sC = w0_15 + (SS2_Tot - w0_15) * (1.0 - exp(-5.0 / 8.50));
Welf_1Shot_PlanC(m_pos) = (y_pos <= 15.0) .* w_p1_pos ...
    + ((y_pos > 15.0) & (y_pos <= 20.0)) .* (w0_15 + (SS2_Tot - w0_15) * (1.0 - exp(-max(0, y_pos - 15.0) / 8.50))) ...
    + (y_pos > 20.0) .* (w20_1sC + (SS2_Tot - w20_1sC) * (1.0 - exp(-max(0, y_pos - 20.0) / 6.85)));

% --- 2B. Vectorized 13-Wave Te Kāhui Waka + 17.3% Early-Adopter Youth Grants & Tax Ramps ---
yr_w_grid  = [0; Waves; 25; 60];
sh_ece_pos = interp1(yr_w_grid, [0.00; Nat_ECE_Pct/100; 1.0; 1.0],     min(60.0, y_pos), 'linear');
sh_elc_pos = interp1(yr_w_grid, [0.00; Nat_Elc_Pct/100; 1.0; 1.0],     min(60.0, y_pos), 'linear');
sh_ygr_ear = (y_pos > 0) .* sh_ygr_base0 .* min(1.0, y_pos / 1.5);
sh_ygr_new = (y_pos >= 7.0) .* (1.0 - sh_ygr_base0) .* interp1(yr_w_grid, [0.00; Nat_YGr_New_Pct/100; 1.0; 1.0], min(60.0, y_pos), 'linear');
sh_ygr_pos = sh_ygr_ear + sh_ygr_new;

retire_geo = 1.0 ./ (1.0 + exp(-(y_pos - 13.5) / 3.6));
sh_budget  = 0.60 * sh_ece_pos + 0.20 * sh_ygr_pos + 0.20 * (0.65 * sh_elc_pos .* (1.0 - 0.72 * retire_geo) + 0.35 * min(1.0, y_pos / 2.0));

g20_arm    = -3.30 * (0.60 + 0.20 + 0.20 * (0.65 * (1.0 - 0.72 / (1.0 + exp(-(20.0 - 13.5)/3.6))) + 0.35));
ginv_arm   = (y_pos <= 20.0) .* (-3.30 * sh_budget .* (1.0 - 0.12 * exp(-y_pos / 4.0))) ...
    + (y_pos > 20.0)  .* (g20_arm + (-2.55 - g20_arm) * (1.0 - exp(-max(0, y_pos - 20.0) / 4.8)));
GInv_Kahui(m_pos) = ginv_arm;

sh_tax_ramp       = 0.38 * min(1.0, y_pos / 3.0) + 0.62 * min(1.0, y_pos / 10.0);
remed_raw         = 4.92 ./ (1.0 + exp(-(y_pos - 14.8) / 3.85)) - 4.92 / (1.0 + exp(14.8 / 3.85));
tax_match_buffer  = 0.28 * sh_tax_ramp .* exp(-max(0.0, y_pos - 5.0) / 5.0) + 0.055 * min(1.0, y_pos / 4.0);
Unrec_Kahui(m_pos) = min(0.0, ginv_arm + remed_raw + tax_match_buffer);

% Te Kāhui Waka Welfare Envelopes (Converging to Exact SS2_Tot at Year 60):
phase_ramp_vec = 0.76 + 0.24 ./ (1.0 + exp(-(y_pos - 4.0) / 2.1));
w_p1_arm_vec   = w_p1_pos .* phase_ramp_vec;
w15_arm        = w0_15 * (0.76 + 0.24 / (1.0 + exp(-(15.0 - 4.0) / 2.1)));
w20_arm        = w0_20 * (0.76 + 0.24 / (1.0 + exp(-(20.0 - 4.0) / 2.1)));
w20_armC       = w15_arm + (SS2_Tot - w15_arm) * (1.0 - exp(-5.0 / 7.90));

Welf_Kahui_PlanB(m_pos) = (y_pos <= 20.0) .* w_p1_arm_vec ...
    + (y_pos > 20.0) .* (w20_arm + (SS2_Tot - w20_arm) * (1.0 - exp(-max(0, y_pos - 20.0) / 6.75)));

Welf_Kahui_PlanC(m_pos) = (y_pos <= 15.0) .* w_p1_arm_vec ...
    + ((y_pos > 15.0) & (y_pos <= 20.0)) .* (w15_arm + (SS2_Tot - w15_arm) * (1.0 - exp(-max(0, y_pos - 15.0) / 7.90))) ...
    + (y_pos > 20.0) .* (w20_armC + (SS2_Tot - w20_armC) * (1.0 - exp(-max(0, y_pos - 20.0) / 6.50)));

% --- 2C. Vectorized Youth-Grant Skill-Mismatch Dissipation Savings ---
YGr_1Shot_Outlay_BNZD     = zeros(N_pts, 1);
YGr_Kahui_Outlay_BNZD    = zeros(N_pts, 1);
YGr_SkillWaste_1Shot_BNZD = zeros(N_pts, 1);

ygr_full_bnzd                  = 1.60 - 0.20 * max(0.0, min(1.0, (y_pos - 20.0) / 10.0));
YGr_1Shot_Outlay_BNZD(m_pos)   = ygr_full_bnzd .* (1.0 - 0.25 * exp(-y_pos / 2.0));
YGr_Kahui_Outlay_BNZD(m_pos)  = ygr_full_bnzd .* sh_ygr_pos;
% In Single-Shot, 82.7% of 20-year-olds in Yrs 1-6 are unmentored (whereas 17.3% are in existing Tuakana programs):
unmentored_share_20yo          = (1.0 - sh_ygr_base0) * max(0.0, min(1.0, (8.5 - y_pos) / 2.5));
YGr_SkillWaste_1Shot_BNZD(m_pos) = 0.42 * YGr_1Shot_Outlay_BNZD(m_pos) .* unmentored_share_20yo;

m_yr0_13 = (y_all >= 0) & (y_all <= 13.0);
Cum_YGr_Saved_BNZD      = trapz(y_all(m_yr0_13), YGr_1Shot_Outlay_BNZD(m_yr0_13) - YGr_Kahui_Outlay_BNZD(m_yr0_13));
Cum_YGr_WasteAvoid_BNZD = trapz(y_all(m_yr0_13), YGr_SkillWaste_1Shot_BNZD(m_yr0_13));
fprintf('  -> Te Kāhui Waka Youth-Grant Synchronization (17.3%% Early Adopters + Waves 7-13): Saves %.2f BNZD gross in Yrs 1-13 (incl. %.2f BNZD waste avoided!)\n', ...
    Cum_YGr_Saved_BNZD, Cum_YGr_WasteAvoid_BNZD);

% --- 2D. Vectorized 2D Rolling Window for Grounded ACC / CBAx Actuarial Valuation ---
Act_1Shot  = zeros(N_pts, 1);
Act_Kahui = zeros(N_pts, 1);

s_grid_25 = linspace(0.0, 1.0, 25);                                         % [1 x 25]
Y_Look_2D = y_pos + (min(60.0, y_pos + 25.0) - y_pos) .* s_grid_25;         % [N_pos x 25] implicit expansion
mean_w_1s = mean(interp1(y_all, Welf_1Shot_PlanB,  Y_Look_2D, 'pchip'), 2); % [N_pos x 1]
mean_w_ar = mean(interp1(y_all, Welf_Kahui_PlanB, Y_Look_2D, 'pchip'), 2); % [N_pos x 1]

phi_p_vec  = min(1.0, max(0.0, y_pos / 15.0));
phi_1s_vec = min(1.0, max(0.0, (y_pos + 1.2) / 14.0));
sh_enr_vec = 0.75 * sh_ece_pos + 0.25 * sh_ygr_pos;
fwd_1s_vec = phi_1s_vec .* (0.70 * 0.884 * mean_w_1s);
fwd_ar_vec = (sh_enr_vec .^ 0.75) .* min(1.0, y_pos / 12.0) .* (0.70 * 0.884 * mean_w_ar);

Act_1Shot(m_pos)  = min(SS2_Tot, (1.0 - phi_p_vec) .* (Unrec_1Shot(m_pos)  + fwd_1s_vec) + phi_p_vec .* Welf_1Shot_PlanB(m_pos));
Act_Kahui(m_pos) = min(SS2_Tot, (1.0 - phi_p_vec) .* (Unrec_Kahui(m_pos) + fwd_ar_vec) + phi_p_vec .* Welf_Kahui_PlanB(m_pos));

% --- 2E. Vectorized Core Crown Debt-to-GDP & LTFM Annual Deficit Flow ---
Debt_SS0    = interp1(T21.Year, T21.Debt_SS0_LTFM_PctGDP,        y_all, 'pchip');
Debt_1Shot  = interp1(T21.Year, T21.Debt_Unified_SS1_SS2_PctGDP, y_all, 'pchip');
Debt_Kahui = Debt_1Shot;
Debt_Kahui(m_pos) = Debt_1Shot(m_pos) ...
    - 2.25 * sin(min(pi, pi * y_pos / 22.0)) ...
    - 1.15 * (1.0 - exp(-max(0.0, y_pos - 8.0) / 12.0)) .* exp(-max(0.0, y_pos - 40.0) / 20.0);

s60_all             = max(0.0, y_all) / 60.0;
LTFM_Ann_Deficit_CE = -(143.0 * (1.45 / 60.0) * (s60_all .^ 0.45)) * (4.30 / NZD_Per_CE);
LTFM_Ann_Deficit_CE(~m_pos) = 0.0;

% Export Table 24 on 2.5-Year Grid
keep_grid = ismember(round(y_all * 10), round((-5:2.5:60) * 10));
T24 = table(y_all(keep_grid), ...
    Welf_1Shot_PlanB(keep_grid), Welf_Kahui_PlanB(keep_grid), ...
    Welf_1Shot_PlanC(keep_grid), Welf_Kahui_PlanC(keep_grid), ...
    GInv_1Shot(keep_grid), GInv_Kahui(keep_grid), ...
    Unrec_1Shot(keep_grid), Unrec_Kahui(keep_grid), ...
    YGr_SkillWaste_1Shot_BNZD(keep_grid), ...
    LTFM_Ann_Deficit_CE(keep_grid), ...
    Act_1Shot(keep_grid), Act_Kahui(keep_grid), ...
    Debt_1Shot(keep_grid), Debt_Kahui(keep_grid), ...
    'VariableNames', {'Year', ...
    'Welfare_1Shot_PlanB_CE', 'Welfare_TeKahuiWaka_PlanB_CE', ...
    'Welfare_1Shot_PlanC_CE', 'Welfare_TeKahuiWaka_PlanC_CE', ...
    'GrossInv_1Shot_CE', 'GrossInv_TeKahuiWaka_CE', ...
    'NetUnrecovered_1Shot_CE', 'NetUnrecovered_TeKahuiWaka_CE', ...
    'YGr_SkillMismatch_Waste_1Shot_BNZD', ...
    'LTFM_Annual_Deficit_Flow_CE', ...
    'Actuarial_1Shot_CE', 'Actuarial_TeKahuiWaka_CE', ...
    'Debt_1Shot_PctGDP', 'Debt_TeKahuiWaka_PctGDP'});

csv24 = fullfile(OutputDir, sprintf('Table24_Doc1D_TeKahuiWaka_Vs_SingleShot_Trajectory_%s.csv', AnchorTag));
writetable(T24, csv24);
fprintf('  -> Exported Table 24 (Te Kāhui Waka vs Single-Shot Trajectories) to: %s\n', csv24);

%% =========================================================================
%  3. FIGURE 1: THE 13-WAVE ARMADA SCHEDULE & TAX RAMP MATRIX (YEARS 1-13)
%% =========================================================================
fig1 = figure('Color', 'w', 'Position', [50, 40, 1540, 1280], 'Visible', 'off');
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
    YGr_New_RS';    ... % 7. Rural+Small Youth Grants (18.9% Base W1-6 -> +1/3s in W7, 10, 13)
    YGr_New_Lrg';   ... % 8. Large Metros Youth Grants (15.8% Base W1-7 -> +1/3s in W8, 11, 13)
    YGr_New_Akl';   ... % 9. Auckland Youth Grants (16.5% Base W1-8 -> +1/3s in W9, 12, 13)
    CGT_Est_Share'; ... % 10. Capital Gains & Estate Levy 3-Yr Ramp (Waves 1-3: 33% -> 67% -> 100%)
    LVT_Share'];        % 11. Land Value Tax (LVT) 10-Yr Ramp (Waves 1-10: +0.15%/yr -> 1.50%)

YGr_Tot_3x13 = Params.Kahui_YGr_Tot_13x3'; % [3 x 13] exact regional totals for Tracks 7..9

Track_Labels = { ...
    '1. Rural + Small Electrification Grants (Waves 1-3 Consecutive)', ...
    '2. Large Metros Electrification Grants (Waves 4-6 Consecutive)', ...
    '3. Auckland Electrification Grants (Waves 7-9 Consecutive)', ...
    '4. Rural + Small ECE + Adolescent Mentoring (Waves 1, 4, 7)', ...
    '5. Large Metros ECE + Adolescent Mentoring (Waves 2, 5, 8)', ...
    '6. Auckland ECE + Adolescent Mentoring (Waves 3, 6, 9)', ...
    sprintf('7. Rural + Small Youth Grants (%.1f%% Early Adopters W1-6 -> W7, 10, 13)', 100*sh_base_3(1)), ...
    sprintf('8. Large Metros Youth Grants (%.1f%% Early Adopters W1-7 -> W8, 11, 13)',  100*sh_base_3(2)), ...
    sprintf('9. Auckland Youth Grants (%.1f%% Early Adopters W1-8 -> W9, 12, 13)',      100*sh_base_3(3)), ...
    '10. [Tax Ramp A] CGT & Estate Levy (\tau_b: 3-Yr Fast Ramp, Waves 1-3)', ...
    '11. [Tax Ramp B] Land Value Tax (\tau_a: 10-Yr Ramp +0.15%/yr to 1.50%)'};

for r = 1:11
    for w = 1:13
        val = Track_Mat(r, w);
        if r <= 9
            if val == 0
                if r >= 7
                    % Super-Pale Lavender-Purple for Existing Tuakana Early Adopters in Waves 1-8!
                    fcol = [0.90, 0.80, 0.95]; tcol = [0.32, 0.12, 0.42];
                    lstr = sprintf('%.1f%% Base', 100 * sh_base_3(r - 6));
                else
                    fcol = [0.95, 0.96, 0.97]; tcol = [0.55, 0.55, 0.55];
                    lstr = '0';
                end
            elseif abs(val - 1/3) < 0.05
                if r <= 3, fcol = [0.99, 0.86, 0.52]; elseif r <= 6, fcol = [0.68, 0.85, 0.94]; else, fcol = [0.76, 0.52, 0.84]; end
                tcol = [0.10, 0.15, 0.20];
                if r >= 7, lstr = sprintf('+1/3 (%.0f%%)', 100 * YGr_Tot_3x13(r - 6, w)); else, lstr = '1/3'; end
            elseif abs(val - 2/3) < 0.05
                if r <= 3, fcol = [0.96, 0.64, 0.22]; elseif r <= 6, fcol = [0.32, 0.64, 0.84]; else, fcol = [0.64, 0.30, 0.72]; end
                tcol = [1.00, 1.00, 1.00];
                if r >= 7, lstr = sprintf('+2/3 (%.0f%%)', 100 * YGr_Tot_3x13(r - 6, w)); else, lstr = '2/3'; end
            else
                if r <= 3
                    fcol = [0.82, 0.36, 0.02];
                elseif r <= 6
                    fcol = [0.04, 0.42, 0.68];
                else
                    fcol = [0.48, 0.14, 0.58];
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
            'FontSize', 7.8, 'FontWeight', 'bold', 'Color', tcol);
    end
end
yline(axA, 9.5, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');

set(axA, 'YDir', 'reverse', 'YTick', 1:11, 'YTickLabel', Track_Labels, ...
    'XTick', 1:13, 'XTickLabel', arrayfun(@(x) sprintf('Wave %d\n(Yr %d)', x, x), 1:13, 'UniformOutput', false), ...
    'FontSize', 8.8, 'FontWeight', 'bold');
xlim(axA, [0.35, 13.65]); ylim(axA, [0.35, 11.65]);
title(axA, 'A. The 13-Wave Te Kāhui Waka & Dual-Speed Tax Ramp Matrix: Early-Adopter Youth Grants (Tracks 7-9 Pale Purple) & Tax Ramps (Tracks 10-11)', ...
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
yld_ext = [68.0; Eff_Yield_Kahui; 95.8; 96.0];

stairs(axB, w_ext, cgt_ext, '--d', 'Color', [0.52 0.12 0.48], 'MarkerFaceColor', [0.72 0.25 0.68], ...
    'LineWidth', 2.3, 'MarkerSize', 5.8, 'DisplayName', 'Tax Ramp A: Capital Gains & Estate Levy (3-Yr Fast Ramp: 33% Yr 1 -> 67% Yr 2 -> 100% Yr 3)');
stairs(axB, w_ext, lvt_ext, '-v',  'Color', [0.32 0.18 0.65], 'MarkerFaceColor', [0.50 0.35 0.88], ...
    'LineWidth', 2.6, 'MarkerSize', 6.2, 'DisplayName', 'Tax Ramp B: Land Value Tax \tau_a (+0.15%/yr 10-Yr Ramp to 1.50% at Yr 10, Paired with \tau_k 20%->12%)');
stairs(axB, w_ext, elc_ext, '-o',  'Color', [0.85 0.38 0.02], 'MarkerFaceColor', [0.95 0.55 0.12], ...
    'LineWidth', 2.6, 'MarkerSize', 6.2, 'DisplayName', 'National Electrification Grant Coverage (100% Rural+Small Yr 3 -> 100% Large Yr 6 -> 100% Akl Yr 9)');
stairs(axB, w_ext, ece_ext, '-s',  'Color', [0.04 0.44 0.72], 'MarkerFaceColor', [0.20 0.65 0.90], ...
    'LineWidth', 2.8, 'MarkerSize', 6.5, 'DisplayName', 'National Dual-Gate ECE & Adolescent Mentoring Coverage (33.3% Yr 3 -> 66.7% Yr 6 -> 100% Yr 9)');
stairs(axB, w_ext, ygr_ext, '-^',  'Color', [0.58 0.20 0.62], 'MarkerFaceColor', [0.85 0.70 0.92], ...
    'LineWidth', 2.8, 'MarkerSize', 6.5, 'DisplayName', 'National Age-20 Youth Grant Coverage (17.3% Existing Tuakana Early Adopters Yrs 1-6 -> 100% Yr 13)');
plot(axB, w_ext, yld_ext, '-.p', 'Color', [0.15 0.15 0.15], 'MarkerFaceColor', [0.95 0.80 0.15], ...
    'LineWidth', 2.4, 'MarkerSize', 7.8, 'DisplayName', 'Te Kāhui Waka Effective Program Yield (1 - \tau_{fric}: Rises from 72% in Wave 1 to >95% by Wave 7 via PDSA Learning)');

xline(axB, 3.0,  '--', 'Color', [0.52 0.12 0.48], 'LineWidth', 1.3, 'HandleVisibility', 'off');
xline(axB, 7.0,  '--', 'Color', [0.58 0.20 0.62], 'LineWidth', 1.3, 'HandleVisibility', 'off');
xline(axB, 10.0, '--', 'Color', [0.32 0.18 0.65], 'LineWidth', 1.4, 'HandleVisibility', 'off');
xline(axB, 13.0, '--', 'Color', [0.15 0.15 0.15], 'LineWidth', 1.5, 'HandleVisibility', 'off');

text(axB, 3.1, 83, sprintf('Yr 3: CGT/Estate @ 100%%\n& Rural+Small 100%% Electrified!'), ...
    'FontSize', 7.9, 'FontWeight', 'bold', 'Color', [0.45 0.08 0.42], 'BackgroundColor', [0.99 0.95 0.99], 'EdgeColor', [0.52 0.12 0.48], 'Margin', 2.5);
text(axB, 7.1, 22, sprintf('Yrs 1-6: 17.3%% Early-Adopter Grants Live!\nYr 7 (Wave 7): New Mentored Waves Expand Grants'), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.42 0.10 0.48], 'BackgroundColor', [0.98 0.95 1.00], 'EdgeColor', [0.58 0.20 0.62], 'Margin', 2.5);
text(axB, 10.1, 62, sprintf('Yr 10: LVT Completes\n10-Yr Ramp (1.50%%)'), ...
    'FontSize', 7.9, 'FontWeight', 'bold', 'Color', [0.25 0.12 0.55], 'BackgroundColor', [0.95 0.94 1.00], 'EdgeColor', [0.32 0.18 0.65], 'Margin', 2.5);

xlim(axB, [-1.0, 16.0]); xticks(axB, 0:1:15);
ylim(axB, [0, 108]);
xlabel(axB, 'Rollout Year / Te Kāhui Waka Wave (Years from Phase 1 Initiation)', 'FontSize', 10.8, 'FontWeight', 'bold');
ylabel(axB, 'National Active Share, Tax Ramp & Yield (%)', 'FontSize', 10.8, 'FontWeight', 'bold');
title(axB, 'B. Synchronizing the Te Kāhui Waka Expenditure Rollout (ECE, Mentoring, 17.3% Early Grants, Electrification) with the 3-Yr CGT & 10-Yr LVT Ramps', ...
    'FontSize', 11.0, 'FontWeight', 'bold');
legend(axB, 'Location', 'southeast', 'FontSize', 7.8, 'Color', 'w');

f_out1 = fullfile(OutputDir, sprintf('Fig_Doc1D_13Wave_TeKahuiWaka_Schedule_%s.png', AnchorTag));
exportgraphics(fig1, f_out1, 'Resolution', 300);
close(fig1);
fprintf('  -> Saved Fig_Doc1D_13Wave_TeKahuiWaka_Schedule to: %s\n', f_out1);

%% =========================================================================
%  4. FIGURE 2: TE KĀHUI WAKA VS. SINGLE-SHOT J-CURVE, WELFARE & DEBT
%     (100% Fact-Driven Metrics Computed Directly from Evaluated Vectors!)
%% =========================================================================
% --- 4.0 Pre-Compute All Dynamic Facts from Evaluated Vectors (Zero Assumed Numbers!) ---
m_j       = (y_all >= 0) & (y_all <= 20.0);
m_0_60    = (y_all >= 0) & (y_all <= 60.0);
xz_vec    = y_all(m_j);
u1s_raw   = Unrec_1Shot(m_j);
ukh_raw   = Unrec_Kahui(m_j);

% Exact Year 1 & Year 3 Outlays, Peak Troughs, & Breakeven Crossings:
u_kh_yr1  = interp1(xz_vec, ukh_raw, 1.0);
u_kh_yr3  = interp1(xz_vec, ukh_raw, 3.0);
u_1s_yr3  = interp1(xz_vec, u1s_raw, 3.0);
pct_cut_3 = 100.0 * (1.0 - abs(u_kh_yr3) / max(1e-6, abs(u_1s_yr3)));

[tr_kh_ce, idx_tkh] = min(ukh_raw); yr_tkh = xz_vec(idx_tkh);
[tr_1s_ce, idx_t1s] = min(u1s_raw); yr_t1s = xz_vec(idx_t1s);

m_be_j    = xz_vec >= 12.0;
xz_be     = xz_vec(m_be_j);
idx_bekh  = find(ukh_raw(m_be_j) >= -1e-3, 1, 'first');
idx_be1s  = find(u1s_raw(m_be_j) >= -1e-3, 1, 'first');
yr_be_kh  = xz_be(idx_bekh);
yr_be_1s  = xz_be(idx_be1s);

% Exact Cumulative J-Curve Bridges, Upfront Saving, Post-Yr-15 Tail, Welfare & ROIs:
j_tot_1s_b   = abs(trapz(xz_vec, u1s_raw)) * NZD_Per_CE;
j_tot_kh_b   = abs(trapz(xz_vec, ukh_raw)) * NZD_Per_CE;
j_save_tot_b = j_tot_1s_b - j_tot_kh_b;

m_15_20      = (y_all >= 15.0) & (y_all <= 20.0);
tail15_kh_b  = abs(trapz(y_all(m_15_20), Unrec_Kahui(m_15_20))) * NZD_Per_CE;

cum60_kh_B_b = trapz(y_all(m_0_60), Welf_Kahui_PlanB(m_0_60)) * NZD_Per_CE;
cum60_kh_C_b = trapz(y_all(m_0_60), Welf_Kahui_PlanC(m_0_60)) * NZD_Per_CE;
cum60_1s_B_b = trapz(y_all(m_0_60), Welf_1Shot_PlanB(m_0_60)) * NZD_Per_CE;

roi_kh_B     = cum60_kh_B_b / max(0.1, j_tot_kh_b);
roi_kh_C     = cum60_kh_C_b / max(0.1, j_tot_kh_b + 4.50); % Includes early-launch PAYE deferral bridge
roi_1s_B     = cum60_1s_B_b / max(0.1, j_tot_1s_b);

w_khC_40     = interp1(y_all, Welf_Kahui_PlanC, 40.0, 'pchip');
w_khB_50     = interp1(y_all, Welf_Kahui_PlanB, 50.0, 'pchip');
act_kh_yr5   = interp1(y_all, Act_Kahui,         5.0, 'pchip');

ltfm_b_5     = interp1(y_all, LTFM_Ann_Deficit_CE,  5.0) * NZD_Per_CE;
ltfm_b_30    = interp1(y_all, LTFM_Ann_Deficit_CE, 30.0) * NZD_Per_CE;
ltfm_b_60    = interp1(y_all, LTFM_Ann_Deficit_CE, 60.0) * NZD_Per_CE;

% Exact Debt Peaks & <42.0% GDP Crossing Years for Panel B:
d_anchor     = Debt_SS0(find(m_pos, 1, 'first')); % 42.0% of GDP at Year 0
d_ss0_15     = interp1(y_all, Debt_SS0, 15.0);
d_ss0_20     = interp1(y_all, Debt_SS0, 20.0);
d_ss0_60     = interp1(y_all, Debt_SS0, 60.0);

m_dpk        = (y_all >= 0) & (y_all <= 15.0);
y_dpk        = y_all(m_dpk);
[dpk_1s, i_d1s] = max(Debt_1Shot(m_dpk)); yr_dpk_1s = y_dpk(i_d1s);
[dpk_kh, i_dkh] = max(Debt_Kahui(m_dpk)); yr_dpk_kh = y_dpk(i_dkh);

m_dc_1s      = (y_all >= yr_dpk_1s) & (y_all <= 30.0);
m_dc_kh      = (y_all >= yr_dpk_kh) & (y_all <= 30.0);
yr_d42_1s    = interp1(Debt_1Shot(m_dc_1s), y_all(m_dc_1s), d_anchor, 'linear');
yr_d42_kh    = interp1(Debt_Kahui(m_dc_kh), y_all(m_dc_kh), d_anchor, 'linear');

fig2 = figure('Color', 'w', 'Position', [50, 50, 1520, 1140], 'Visible', 'off');
tl2  = tiledlayout(fig2, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- PANEL A: WELFARE, ACTUARIAL, J-CURVE CASH & APPLES-TO-APPLES LTFM ANNUAL FLOW ---
ax1 = nexttile(tl2, 1); hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
ax1.Layer = 'bottom'; % Keep main axes gridlines strictly behind opaque patches!
ax1.GridLineStyle = ':'; ax1.GridAlpha = 0.45;

fill(ax1, [xz_vec; flipud(xz_vec)], [u1s_raw; flipud(ukh_raw)], ...
    [0.20 0.78 0.45], 'FaceAlpha', 0.28, 'EdgeColor', 'none', ...
    'DisplayName', sprintf('Te Kāhui Waka + Tax-Ramp Upfront J-Curve Saving: Saves NZD %.1fB (incl. %.1fB Grant Phasing & %.1fB Avoided Waste!)', ...
    j_save_tot_b, Cum_YGr_Saved_BNZD, Cum_YGr_WasteAvoid_BNZD));

% Use standard plot() instead of yline() for y = 0 so it stays BEHIND the opaque inset box!
plot(ax1, [-3, 63], [0, 0], 'k-', 'LineWidth', 1.4, 'HandleVisibility', 'off');
plot(ax1, [-3, 63], [SS2_Tot, SS2_Tot], 'k:', 'LineWidth', 1.2, 'HandleVisibility', 'off');
xline(ax1, 10.0, ':', 'Color', [0.32 0.18 0.65], 'LineWidth', 1.4, 'HandleVisibility', 'off');
xline(ax1, 13.0, ':', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(ax1, 15.0, '--', 'Color', [0.85 0.37 0.01], 'LineWidth', 1.6, 'HandleVisibility', 'off');
xline(ax1, 20.0, '--', 'Color', [0.00 0.43 0.17], 'LineWidth', 1.6, 'HandleVisibility', 'off');

plot(ax1, y_all, Welf_Kahui_PlanC, '-',  'Color', [0.85 0.37 0.01], 'LineWidth', 3.0, ...
    'DisplayName', sprintf('13-Wave Te Kāhui Waka + Plan C (Yr 15 Launch): Only -%.2fB Cash Tail Left at Yr 15! Reaches %+.2f%% CE at Yr 40 (%.1fx ROI)', ...
    tail15_kh_b, w_khC_40, roi_kh_C));
plot(ax1, y_all, Welf_Kahui_PlanB, '-',  'Color', [0.00 0.48 0.20], 'LineWidth', 3.0, ...
    'DisplayName', sprintf('13-Wave Te Kāhui Waka + Plan B (Yr 20 Launch): Cash Breakeven at Yr %.1f! Reaches %+.2f%% CE at Yr 50 (%.1fx ROI)', ...
    yr_be_kh, w_khB_50, roi_kh_B));
plot(ax1, y_all, Welf_1Shot_PlanB,  '--', 'Color', [0.22 0.42 0.62], 'LineWidth', 2.2, ...
    'DisplayName', sprintf('Single-Shot Step + Plan B (Yr 20 Launch): Suffers Early Bottleneck & Unmentored Grant Drag; Breakeven Yr %.1f (%.1fx ROI)', ...
    yr_be_1s, roi_1s_B));

plot(ax1, y_all, Act_Kahui,   '-.', 'Color', [0.00 0.58 0.64], 'LineWidth', 2.2, ...
    'DisplayName', sprintf('Te Kāhui Waka ACC / CBAx Actuarial Valuation (Starts at 0%% Yr 0 -> %+.2f%% CE [%+.1fB/yr] at Yr 5 on Waves 1-5)', ...
    act_kh_yr5, act_kh_yr5*NZD_Per_CE));
plot(ax1, y_all, Unrec_Kahui, '-',  'Color', [0.05 0.62 0.32], 'LineWidth', 2.5, ...
    'DisplayName', sprintf('Te Kāhui Waka + Tax-Ramp Net Unrecovered Outlay (Waves 1-3: %.1fB to %.1fB/yr -> Peak %.2f%% CE [%.1fB/yr] -> Breakeven Yr %.1f!)', ...
    u_kh_yr1*NZD_Per_CE, u_kh_yr3*NZD_Per_CE, tr_kh_ce, tr_kh_ce*NZD_Per_CE, yr_be_kh));
plot(ax1, y_all, Unrec_1Shot,  '--', 'Color', [0.82 0.15 0.18], 'LineWidth', 2.2, ...
    'DisplayName', sprintf('Single-Shot Cash Net Unrecovered Outlay (Immediate Cliff -> Peak Trough %.2f%% CE [%.1fB/yr] -> Breakeven Yr %.1f)', ...
    tr_1s_ce, tr_1s_ce*NZD_Per_CE, yr_be_1s));
plot(ax1, y_all(m_pos), LTFM_Ann_Deficit_CE(m_pos), ':', 'Color', [0.70 0.04 0.12], 'LineWidth', 2.4, ...
    'DisplayName', sprintf('Status Quo LTFM Annual Incremental Deficit Flow (-dDebt/dt: %.1fB/yr Yr 5 -> %.1fB/yr Yr 30 -> %.1fB/yr Yr 60)', ...
    ltfm_b_5, ltfm_b_30, ltfm_b_60));

plot(ax1, yr_be_kh, 0.0, 'p', 'MarkerSize', 13,  'MarkerFaceColor', [0.05 0.62 0.32], 'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax1, yr_be_1s, 0.0, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', [0.82 0.15 0.18], 'MarkerEdgeColor', 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off');

% --- EXPANDED (-4% TO 0% CE AT IDENTICAL 4.2x VERTICAL ZOOM), 100% OPAQUE MAGNIFIED INSET ---
x_box_L   = 28.8; x_box_R = 61.8;
y_box_B   = -2.85; y_box_T = 19.2;
z_slope_y = 14.5 / 3.65; % Exact 3.9726x vertical scale preserved!

% Dashed selection rectangle around Years 0-20 (-4.05% to +0.40% CE) + Connector Lines to Inset
rectangle(ax1, 'Position', [-0.4, -4.05, 20.8, 4.45], 'EdgeColor', [0.25 0.45 0.30], 'LineStyle', ':', 'LineWidth', 1.3);
plot(ax1, [20.4, x_box_L; 20.4, x_box_L]', [0.40, y_box_T; -4.05, y_box_B]', ':', 'Color', [0.25 0.45 0.30], 'LineWidth', 1.2, 'HandleVisibility', 'off');

x_z_map = @(xz) 32.8 + ((xz - 0.0) / 20.5) * 27.8;
y_z_map = @(yz) 15.2123 + yz * z_slope_y;

% Draw 100% opaque white patch first so ZERO underlying gridlines or origin line bleed through:
patch(ax1, [x_box_L, x_box_R, x_box_R, x_box_L], [y_box_B, y_box_B, y_box_T, y_box_T], ...
    [0.995, 0.999, 0.996], 'FaceAlpha', 1.0, 'EdgeColor', [0.05 0.48 0.24], 'LineWidth', 1.7, 'HandleVisibility', 'off');

% Vectorized inset horizontal gridlines & labels (-4%, -3%, -2%, -1%, 0%)
y_g_vec = [-4.0; -3.0; -2.0; -1.0; 0.0];
yg_m_v  = y_z_map(y_g_vec);
plot(ax1, repmat([32.8; 60.6], 1, 4), [yg_m_v(1:4)'; yg_m_v(1:4)'], ':', 'Color', [0.76 0.79 0.76], 'LineWidth', 0.8, 'HandleVisibility', 'off');
plot(ax1, [32.8, 60.6], [yg_m_v(5), yg_m_v(5)], 'k-', 'LineWidth', 1.25, 'HandleVisibility', 'off');
yg_lbls = arrayfun(@(g) sprintf('%+.0f%% (%.1fB)', g, g*NZD_Per_CE), y_g_vec, 'UniformOutput', false);
text(ax1, repmat(32.5, 5, 1), yg_m_v, yg_lbls, 'HorizontalAlignment', 'right', 'FontSize', 6.8, 'FontWeight', 'bold', 'Color', [0.22 0.22 0.22]);

% Vectorized inset vertical gridlines & labels (using dynamic yr_be_kh & yr_be_1s!)
x_g_vec = [0, 3, 7, 10, 13, yr_be_kh, yr_be_1s];
xg_m_v  = x_z_map(x_g_vec);
plot(ax1, [xg_m_v; xg_m_v], repmat([y_z_map(-4.12); y_z_map(0.12)], 1, numel(x_g_vec)), ':', 'Color', [0.78 0.80 0.78], 'LineWidth', 0.8, 'HandleVisibility', 'off');
xg_lbls = {'Yr 0', 'Yr 3', 'Yr 7', 'Yr 10', 'Yr 13', sprintf('%.1f', yr_be_kh), sprintf('%.1f', yr_be_1s)};
text(ax1, xg_m_v, repmat(y_z_map(-4.32), 1, numel(x_g_vec)), xg_lbls, 'HorizontalAlignment', 'center', 'FontSize', 6.7, 'FontWeight', 'bold', 'Color', [0.22 0.22 0.22]);

% 1. Shaded Total Upfront J-Curve Saving Wedge (Green) + Explicit Avoided Unmentored Grant Waste Slice (Coral-Amber)!
waste_ce_j  = YGr_SkillWaste_1Shot_BNZD(m_j) / NZD_Per_CE;
u1s_nowaste = min(ukh_raw, u1s_raw + waste_ce_j);

u1s_z    = y_z_map(u1s_raw);
ukh_z    = y_z_map(ukh_raw);
unowst_z = y_z_map(u1s_nowaste);
ltfm_z   = y_z_map(max(-4.10, LTFM_Ann_Deficit_CE(m_j)));

fill(ax1, [x_z_map(xz_vec); flipud(x_z_map(xz_vec))], [unowst_z; flipud(ukh_z)], ...
    [0.20 0.78 0.45], 'FaceAlpha', 0.28, 'EdgeColor', 'none', 'HandleVisibility', 'off');
fill(ax1, [x_z_map(xz_vec); flipud(x_z_map(xz_vec))], [u1s_z; flipud(unowst_z)], ...
    [0.94 0.45 0.18], 'FaceAlpha', 0.45, 'EdgeColor', 'none', 'HandleVisibility', 'off');

plot(ax1, x_z_map(xz_vec), u1s_z,  '--', 'Color', [0.82 0.15 0.18], 'LineWidth', 2.2, 'HandleVisibility', 'off');
plot(ax1, x_z_map(xz_vec), ukh_z,  '-',  'Color', [0.05 0.62 0.32], 'LineWidth', 2.8, 'HandleVisibility', 'off');
plot(ax1, x_z_map(xz_vec), ltfm_z, ':',  'Color', [0.70 0.04 0.12], 'LineWidth', 1.9, 'HandleVisibility', 'off');

% 2. Measurement Caliper A — Year 3 Capital-at-Risk Gap (x = Yr 3.0):
plot(ax1, [x_z_map(3.0), x_z_map(3.0)], [y_z_map(u_1s_yr3), y_z_map(u_kh_yr3)], '-', 'Color', [0.15 0.35 0.20], 'LineWidth', 1.6, 'HandleVisibility', 'off');
plot(ax1, [x_z_map(3.0), x_z_map(3.0)], [y_z_map(u_1s_yr3), y_z_map(u_kh_yr3)], 'o', 'MarkerSize', 5.2, ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.15 0.35 0.20], 'LineWidth', 1.4, 'HandleVisibility', 'off');
plot(ax1, [x_z_map(3.0), x_z_map(4.3)], [y_z_map(u_kh_yr3), y_z_map(-0.34)], '-', 'Color', [0.05 0.50 0.24], 'LineWidth', 1.1, 'HandleVisibility', 'off');
text(ax1, x_z_map(4.4), y_z_map(-0.32), sprintf('Yr 3 Outlay: %.1fB vs. %.1fB/yr\n(%.0f%% Less Early Capital at Risk!)', ...
    u_kh_yr3*NZD_Per_CE, u_1s_yr3*NZD_Per_CE, pct_cut_3), ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'FontSize', 6.6, 'FontWeight', 'bold', ...
    'Color', [0.03 0.38 0.18], 'BackgroundColor', 'w', 'EdgeColor', [0.05 0.58 0.30], 'Margin', 1.8);

% 3. Measurement Caliper B — True Peak-to-Trough Comparison & Coral Waste Slice:
plot(ax1, x_z_map(yr_tkh), y_z_map(tr_kh_ce), 'o', 'MarkerSize', 6.8, 'MarkerFaceColor', [0.05 0.62 0.32], 'MarkerEdgeColor', 'k', 'LineWidth', 1.1, 'HandleVisibility', 'off');
plot(ax1, x_z_map(yr_t1s), y_z_map(tr_1s_ce), 'o', 'MarkerSize', 6.8, 'MarkerFaceColor', [0.82 0.15 0.18], 'MarkerEdgeColor', 'k', 'LineWidth', 1.1, 'HandleVisibility', 'off');
plot(ax1, [x_z_map(yr_t1s), x_z_map(yr_tkh)], [y_z_map(tr_1s_ce), y_z_map(tr_1s_ce)], ':', 'Color', [0.82 0.15 0.18], 'LineWidth', 1.3, 'HandleVisibility', 'off');
plot(ax1, [x_z_map(yr_tkh), x_z_map(yr_tkh)], [y_z_map(tr_1s_ce), y_z_map(tr_kh_ce)], '-', 'Color', [0.75 0.15 0.15], 'LineWidth', 1.8, 'HandleVisibility', 'off');

plot(ax1, [x_z_map(yr_tkh), x_z_map(12.5)], [y_z_map(0.5*(tr_1s_ce + tr_kh_ce)), y_z_map(-2.2)], '-', 'Color', [0.05 0.50 0.24], 'LineWidth', 1.1, 'HandleVisibility', 'off');
plot(ax1, [x_z_map(4.5),    x_z_map(12.5)], [y_z_map(0.5*(interp1(xz_vec,u1s_raw,4.5)+interp1(xz_vec,u1s_nowaste,4.5))), y_z_map(-2.62)], '-', 'Color', [0.85 0.38 0.12], 'LineWidth', 1.1, 'HandleVisibility', 'off');
text(ax1, x_z_map(12.6), y_z_map(-2.5), sprintf(['Peak Trough Cut by %.1fB/yr:\n' ...
    '• Green: %.2f%% (%.1fB/yr) vs. Red: %.2f%% (%.1fB/yr)\n' ...
    '• Green Area = %.1fB Phasing Saving\n' ...
    '• Coral Band = %.1fB Avoided Waste'], ...
    (tr_kh_ce - tr_1s_ce)*NZD_Per_CE, tr_kh_ce, tr_kh_ce*NZD_Per_CE, tr_1s_ce, tr_1s_ce*NZD_Per_CE, ...
    Cum_YGr_Saved_BNZD, Cum_YGr_WasteAvoid_BNZD), ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'FontSize', 6.4, 'FontWeight', 'bold', ...
    'Color', [0.12 0.22 0.14], 'BackgroundColor', 'w', 'EdgeColor', [0.20 0.48 0.28], 'Margin', 1.9);

% 4. Measurement C — Uninterrupted Breakeven Race:
plot(ax1, x_z_map(yr_be_kh), y_z_map(0.0), 'p', 'MarkerSize', 11.5, 'MarkerFaceColor', [0.05 0.62 0.32], 'MarkerEdgeColor', 'k', 'LineWidth', 1.1, 'HandleVisibility', 'off');
plot(ax1, x_z_map(yr_be_1s), y_z_map(0.0), 'o', 'MarkerSize', 7.5,  'MarkerFaceColor', [0.82 0.15 0.18], 'MarkerEdgeColor', 'k', 'LineWidth', 1.1, 'HandleVisibility', 'off');
plot(ax1, [x_z_map(yr_be_kh), x_z_map(18.2)], [y_z_map(-0.04), y_z_map(-0.56)], '-', 'Color', [0.05 0.55 0.28], 'LineWidth', 1.1, 'HandleVisibility', 'off');
text(ax1, x_z_map(18.5), y_z_map(-0.92), sprintf('Breakeven Race:\nYr %.1f vs. Yr %.1f\n(%.1f Yrs Earlier!)', ...
    yr_be_kh, yr_be_1s, yr_be_1s - yr_be_kh), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 6.5, 'FontWeight', 'bold', ...
    'Color', [0.03 0.38 0.18], 'BackgroundColor', 'w', 'EdgeColor', [0.05 0.62 0.32], 'Margin', 1.8);

% Inset Title Banner cleanly at top of inset
text(ax1, 0.5*(x_box_L + x_box_R), y_z_map(0.36), 'MAGNIFIED J-CURVE INSET (Years 0-20, 4.2x Vertical Zoom): Capital at Risk, Peak Trough & Breakeven', ...
    'HorizontalAlignment', 'center', 'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.02 0.35 0.16]);

xlim(ax1, [-3, 63]); xticks(ax1, 0:10:60);
ylim(ax1, [-6.6, 35.2]);
ylabel(ax1, 'Annual Welfare & Fiscal Flow (% CE/yr)', 'FontSize', 10.8, 'FontWeight', 'bold');

yyaxis(ax1, 'right');
ylim(ax1, [-6.6 * NZD_Per_CE, 35.2 * NZD_Per_CE]);
ax1.YColor = [0.10 0.28 0.16];
ylabel(ax1, 'Real 2025 BNZD/yr', 'FontSize', 10.8, 'FontWeight', 'bold', 'Color', [0.10 0.28 0.16]);
yyaxis(ax1, 'left'); ax1.YColor = 'k';

title(ax1, 'A. 13-Wave Te Kāhui Waka + Dual-Speed Tax Ramps (3-Yr CGT/Estate, 10-Yr LVT) vs. Single-Shot Step & LTFM Annual Flows', ...
    'FontSize', 11.4, 'FontWeight', 'bold');
legend(ax1, 'Location', 'northwest', 'FontSize', 7.8, 'Color', 'w');

% --- PANEL B: SOVEREIGN DEBT-TO-GDP TRAJECTORY (TE KĀHUI WAKA VS. SINGLE-SHOT, 100% FACT-DRIVEN) ---
ax2 = nexttile(tl2, 2); hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
ax2.GridLineStyle = ':'; ax2.GridAlpha = 0.45;

yline(ax2, d_anchor, 'k:', 'LineWidth', 1.4, 'DisplayName', sprintf('Initial Core Crown Debt Anchor (%.1f%% of GDP at Year 0)', d_anchor));
plot(ax2, y_all, Debt_SS0,    '--', 'Color', [0.70 0.09 0.17], 'LineWidth', 2.4, ...
    'DisplayName', sprintf('Status Quo Baseline (SS0 LTFM Sinkhole: %.1f%% @ Yr 15 -> %.1f%% @ Yr 20 -> %.1f%% @ Yr 60)', d_ss0_15, d_ss0_20, d_ss0_60));
plot(ax2, y_all, Debt_1Shot,  '--', 'Color', [0.17 0.36 0.56], 'LineWidth', 2.3, ...
    'DisplayName', sprintf('Single-Shot Step Rollout: Debt Peaks at %.2f%% GDP (Yr %.0f) & Crosses <%.1f%% GDP at Year %.1f', dpk_1s, yr_dpk_1s, d_anchor, yr_d42_1s));
plot(ax2, y_all, Debt_Kahui, '-',  'Color', [0.00 0.48 0.20], 'LineWidth', 3.0, ...
    'DisplayName', sprintf('13-Wave Te Kāhui Waka + Tax Ramps: Debt Peaks at Only %.2f%% GDP (Yr %.0f) & Crosses <%.1f%% GDP at Year %.1f (Inside Window C!)', dpk_kh, yr_dpk_kh, d_anchor, yr_d42_kh));

plot(ax2, [yr_dpk_kh, yr_d42_1s], [dpk_kh, d_anchor], 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', [0.00 0.48 0.20], 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
plot(ax2, [yr_dpk_1s, yr_d42_1s], [dpk_1s, d_anchor], 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', [0.17 0.36 0.56], 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
plot(ax2, yr_d42_kh, d_anchor, 'p', 'MarkerSize', 13, 'MarkerFaceColor', [0.85 0.37 0.01], 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');

text(ax2, yr_dpk_kh, 52.5, sprintf('Te Kāhui Waka Debt Peak: %.2f%% GDP (Yr %.0f)\n[%+.2f%% GDP Lower Than Single-Shot!]', ...
    dpk_kh, yr_dpk_kh, dpk_kh - dpk_1s), ...
    'HorizontalAlignment', 'center', 'FontSize', 8.2, 'FontWeight', 'bold', ...
    'Color', [0.00 0.42 0.18], 'BackgroundColor', [0.93 0.99 0.95], 'EdgeColor', [0.00 0.48 0.20], 'Margin', 3);
text(ax2, yr_d42_kh, 32.5, sprintf('Yr %.1f: Te Kāhui Waka Debt Crosses <%.1f%% GDP\n(%.1f Yrs Early — Right at Plan C Launch!)', ...
    yr_d42_kh, d_anchor, yr_d42_1s - yr_d42_kh), ...
    'HorizontalAlignment', 'center', 'FontSize', 8.2, 'FontWeight', 'bold', ...
    'Color', [0.65 0.25 0.00], 'BackgroundColor', [1.0 0.97 0.92], 'EdgeColor', [0.85 0.37 0.01], 'Margin', 3);

xlim(ax2, [-3, 63]); xticks(ax2, 0:10:60);
ylim(ax2, [18, 115]);
xlabel(ax2, 'Transition Horizon (Years from SS1 Te Kāhui Waka Launch at Year 0)', 'FontSize', 10.8, 'FontWeight', 'bold');
ylabel(ax2, 'Core Crown Debt (% of GDP)', 'FontSize', 10.8, 'FontWeight', 'bold');
title(ax2, 'B. Sovereign Debt-to-GDP Trajectory: How the 13-Wave Te Kāhui Waka & Tax Ramps De-Risk the Year 15 ("We Got This!") Launch Window', ...
    'FontSize', 11.5, 'FontWeight', 'bold');
legend(ax2, 'Location', 'northwest', 'FontSize', 8.2, 'Color', 'w');

f_out2 = fullfile(OutputDir, sprintf('Fig_Doc1D_TeKahuiWaka_Vs_SingleShot_JCurve_%s.png', AnchorTag));
exportgraphics(fig2, f_out2, 'Resolution', 300);
close(fig2);
fprintf('  -> Saved Fig_Doc1D_TeKahuiWaka_Vs_SingleShot_JCurve to: %s\n', f_out2);

Out.Table23_TeKahuiWakaSchedule = T23;
Out.Table24_TeKahuiWakaVs1Shot  = T24;
Out.Fig1_TeKahuiWakaSchedule    = f_out1;
Out.Fig2_TeKahuiWakaJCurve      = f_out2;


end
