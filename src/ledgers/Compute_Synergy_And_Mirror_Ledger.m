function L = Compute_Synergy_And_Mirror_Ledger(Params, T1_Override, ReformSpecs_Override)
%% PURE 11-LAYER + ARTS/CIVIC CAP SYNERGY ATTRIBUTION & MIRROR INVESTMENT LEDGER
% File: src/ledgers/Compute_Synergy_And_Mirror_Ledger.m
% Pure, headless accounting engine computing:
%   1) Table 19  : 11-Layer Default Constructive Synergy Attribution (7 Isolated + 4 Wedges)
%   2) Table 19E : 15-Layer Extended Attribution adding Document 1E's 4 Arts & Civic Wedge Caps
%                  scaled continuously by civic commitment intensity u_civic >= 0
%   3) Table 20  : Vectorized 0-loop Single-Phase vs. 13-Wave Te Kahui Waka Mirror-Investment,
%                  Remediation, ACC/CBAx Actuarial Valuation, & LTFM Annual Deficit Trajectories.

if nargin < 1 || isempty(Params), Params = struct(); end
if nargin < 2, T1_Override = [];          end
if nargin < 3, ReformSpecs_Override = []; end

if ~isfield(Params, 'Kahui_ECE_13x5') || ~isfield(Params, 'Profile_ID')
    Params = Configure_TimeGrid_Params(Params);
end

% Continuous civic commitment intensity u_civic >= 0 (default 1.0 when Enable_Arts_Civic is true):
if isfield(Params, 'Civic_Commitment_Scale') && ~isempty(Params.Civic_Commitment_Scale)
    u_civic = max(0.0, double(Params.Civic_Commitment_Scale));
elseif isfield(Params, 'Enable_Arts_Civic') && ~isempty(Params.Enable_Arts_Civic)
    u_civic = double(logical(Params.Enable_Arts_Civic));
else
    u_civic = 1.0; % Default ON so Table 19E & Arts-Enabled Cap are available out-of-the-box
end
enable_arts = (u_civic > 1e-6);

Pop_Weights    = Params.Pop_Weights_4(:)';
SS1_Target_Reg = [11.945, 13.739, 14.888, 17.515];
SS2_Target_Reg = [20.628, 22.984, 24.574, 27.913];

if ~isempty(T1_Override) && istable(T1_Override) && height(T1_Override) >= 6
    SS1_Target_Reg = table2array(T1_Override(3, 1:4));
    SS2_Target_Reg = table2array(T1_Override(6, 1:4));
end

SS1_Nat_Total = sum(SS1_Target_Reg .* Pop_Weights);
SS2_Nat_Total = sum(SS2_Target_Reg .* Pop_Weights);

if ~isfield(Params, 'Super_Age_SS2') || isempty(Params.Super_Age_SS2)
    sa_ss2 = 64;
else
    sa_ss2 = Params.Super_Age_SS2;
end

psi_ret = 0.850;
if isfield(Params, 'psi_retire_T') && ~isempty(Params.psi_retire_T)
    psi_ret = Params.psi_retire_T;
end
transfer_retire_pp = 0.75 * psi_ret;

if sa_ss2 < 65
    base_tax_chg_pp = -3.50 - transfer_retire_pp + 0.30*(65 - sa_ss2) + 0.085*(65 - sa_ss2)^2;
else
    base_tax_chg_pp = -3.50 - transfer_retire_pp + 0.28*((sa_ss2 - 65)^1.30);
end

if ~isempty(ReformSpecs_Override) && numel(ReformSpecs_Override) >= 2 ...
        && isfield(ReformSpecs_Override(2), 'tau_l_delta') && ~isempty(ReformSpecs_Override(2).tau_l_delta)
    ws_pp = 100.0 * ReformSpecs_Override(2).tau_l_delta;
    if ws_pp > -3.30 && sa_ss2 <= 65
        tax_chg_pp = ws_pp - transfer_retire_pp;
    else
        tax_chg_pp = ws_pp;
    end
elseif isfield(Params, 'tau_l_delta_SS2') && ~isempty(Params.tau_l_delta_SS2)
    ws_pp = 100.0 * Params.tau_l_delta_SS2;
    if ws_pp > -3.30 && sa_ss2 <= 65
        tax_chg_pp = ws_pp - transfer_retire_pp;
    else
        tax_chg_pp = ws_pp;
    end
else
    tax_chg_pp = base_tax_chg_pp;
end
req_tax_pct = 22.0 + tax_chg_pp;

if sa_ss2 < 65
    if tax_chg_pp < -0.05
        l10_label   = sprintf('10. [Isolated] PAYE Cut (%.2f pp to %.1f%%) & Super Age-%.0f Kuia Dividend Alone', tax_chg_pp, req_tax_pct, sa_ss2);
        box25_label = sprintf('Yr 25: Phase 2 (SS2)\n%.2fpp PAYE Cut + Super Age %.0f', tax_chg_pp, sa_ss2);
    else
        l10_label   = sprintf('10. [Isolated] PAYE Hike (%+.2f pp to %.1f%%) to Fund Super Age-%.0f Alone', abs(tax_chg_pp), req_tax_pct, sa_ss2);
        box25_label = sprintf('Yr 25: Phase 2 (SS2)\n%+.2fpp PAYE Hike for Super Age %.0f', abs(tax_chg_pp), sa_ss2);
    end
    tier4_hdr = sprintf('Tier 4: Fiscal/Super-%.0f/TFR', sa_ss2);
elseif sa_ss2 == 65
    l10_label   = sprintf('10. [Isolated] PAYE Tax-Relief Harvest (%.2f pp to %.1f%% at Age 65) Alone', tax_chg_pp, req_tax_pct);
    box25_label = sprintf('Yr 25: Phase 2 (SS2)\n%.2fpp PAYE Cut (Super Age 65)', tax_chg_pp);
    tier4_hdr   = 'Tier 4: Fiscal/Super-65/TFR';
else
    if tax_chg_pp < -0.05
        l10_label   = sprintf('10. [Isolated] Reduced PAYE Cut (%.2f pp to %.1f%%) & Age-%.0f Super Squeeze', tax_chg_pp, req_tax_pct, sa_ss2);
        box25_label = sprintf('Yr 25: Phase 2 (SS2)\n%.2fpp PAYE Cut + Age %.0f Squeeze', tax_chg_pp, sa_ss2);
    else
        l10_label   = sprintf('10. [Isolated] Age-%.0f Super Austerity & %+.2f pp PAYE Hike (to %.1f%%)', sa_ss2, tax_chg_pp, req_tax_pct);
        box25_label = sprintf('Yr 25: Phase 2 (SS2) Austerity\nAge %.0f Super + %.2fpp PAYE Hike', sa_ss2, tax_chg_pp);
    end
    tier4_hdr = sprintf('Tier 4: Age-%.0f Squeeze/TFR', sa_ss2);
end

Layer_Codes = { ...
    'L01_Iso_ECE1_First2000d'; ...
    'L02_Iso_Tuakana_Mentoring'; ...
    'L03_WEDGE1_DualGate_HC_Synergy'; ...
    'L04_Iso_EstateProperty_Rebal'; ...
    'L05_Iso_YouthGrant_Age20'; ...
    'L06_Iso_GeoTransfer_Income'; ...
    'L07_WEDGE2_LVR_Whanau_Synergy'; ...
    'L08_WEDGE3_CrossStack_HC_x_Spatial'; ...
    'L09_Iso_DebtSinking_Interest'; ...
    sprintf('L10_Iso_PAYE_SuperAge_%.0f', sa_ss2); ...
    'L11_WEDGE4_Fiscal_TFR_2ndGen_Closure'};

Layer_Legend_Labels = { ...
    '1. [Isolated] First-2000-Days Universal ECE Alone (G_{ECE,1}: High Fade-Out Alone)', ...
    '2. [Isolated] Tuakana-Teina / Montessori Mentoring Alone (G_{ECE,2}: Unprepared Base Alone)', ...
    '3. ★ WEDGE 1: Dual-Gate Human Capital Synergy (ECE_1 \times Tuakana_2 Halts Skill Fade-Out)', ...
    '4. [Isolated] Estate & Property Tax Rebalance Alone (\tau_b/\tau_a \rightarrow Firm Capital Alone)', ...
    '5. [Isolated] Age-20 Youth Capital Grant Alone (E: Insufficient for LVR in Uncooled Market)', ...
    '6. [Isolated] Income \times Geography Transfer Alone (T_k: SS1 Bridge \rightarrow Retires 82% in SS2)', ...
    '7. ★ WEDGE 2: LVR-Clearance & Whanau-Anchoring Synergy (Housing Cooling Q_k \times Grant E)', ...
    '8. ★ WEDGE 3: Cross-Stack Synergy (Stack 1 \times Stack 2: Local Procurement z_l\rightarrowz_h Jobs + Stops Brain Drain)', ...
    '9. [Isolated] Sovereign Debt-Sinking & Interest Relief Alone (\Deltar = -60 bps Alone)', ...
    l10_label, ...
    '11. ★ WEDGE 4: Actuarial Solvency, Replacement TFR & 2nd-Gen Dynasty Compounding'};

Is_Wedge = [false; false; true; false; false; false; true; true; false; false; true];
Iso_Idx  = find(~Is_Wedge);
Wed_Idx  = find(Is_Wedge);

Raw_SS1_11x4 = [ ...
    2.15,  2.35,  2.55,  2.90; ...
    1.30,  1.40,  1.50,  1.70; ...
    1.95,  2.20,  2.45,  2.95; ...
    1.25,  1.50,  1.75,  2.15; ...
    0.78,  0.88,  0.96,  1.10; ...
    0.95,  0.88,  0.78,  0.72; ...
    1.10,  1.30,  1.50,  1.85; ...
    2.15,  2.55,  2.55,  2.85; ...
    0.15,  0.22,  0.26,  0.35; ...
    0.00,  0.00,  0.00,  0.00; ...
    0.25,  0.45,  0.55,  0.70];

SS1_Pos_Reg = max(0.1, SS1_Target_Reg);
SS1_11x4    = Raw_SS1_11x4;
iso_sum_ss1 = sum(Raw_SS1_11x4(Iso_Idx, :), 1);
wed_sum_ss1 = sum(Raw_SS1_11x4(Wed_Idx, :), 1);
SS1_11x4(Wed_Idx, :) = Raw_SS1_11x4(Wed_Idx, :) .* (max(0.1, SS1_Pos_Reg - iso_sum_ss1) ./ wed_sum_ss1);
SS1_Nat_11  = SS1_11x4 * Pop_Weights';
SS1_11x5    = [SS1_11x4, SS1_Nat_11];

Raw_SS2_11x4 = [ ...
    2.05,  2.25,  2.45,  2.80; ...
    1.35,  1.45,  1.55,  1.75; ...
    2.65,  3.00,  3.25,  3.80; ...
    1.65,  1.95,  2.25,  2.70; ...
    0.72,  0.82,  0.90,  1.02; ...
    0.17,  0.16,  0.14,  0.13; ...
    1.75,  2.05,  2.30,  2.75; ...
    4.85,  4.95,  5.00,  5.55; ...
    1.05,  1.15,  1.25,  1.40; ...
    2.35,  2.55,  2.70,  2.95; ...
    2.10,  2.55,  2.60,  2.85];

SS2_Pos_Reg = max(0.1, SS2_Target_Reg);
Raw_Adj     = Raw_SS2_11x4;
if sa_ss2 > 65
    erosion_fac = max(0.0, min(1.0, (SS2_Pos_Reg ./ sum(Raw_SS2_11x4, 1) - 0.55) / 0.45));
    Raw_Adj(10, :) = Raw_SS2_11x4(10, :) .* erosion_fac;
    Raw_Adj(11, :) = Raw_SS2_11x4(11, :) .* erosion_fac;
end
SS2_11x4    = Raw_Adj;
iso_sum_ss2 = sum(Raw_Adj(Iso_Idx, :), 1);
wed_sum_ss2 = sum(Raw_Adj(Wed_Idx, :), 1);
SS2_11x4(Wed_Idx, :) = Raw_Adj(Wed_Idx, :) .* (max(0.1, SS2_Pos_Reg - iso_sum_ss2) ./ wed_sum_ss2);
SS2_Nat_11  = SS2_11x4 * Pop_Weights';
SS2_11x5    = [SS2_11x4, SS2_Nat_11];

Cumulative_Nat_SS2 = cumsum(SS2_Nat_11);
Share_Of_Total_Pct = 100 * SS2_Nat_11 / max(1e-6, sum(SS2_Nat_11));
Layer_Type = repmat({'Isolated_Factor'}, 11, 1);
Layer_Type(Is_Wedge) = {'SYNERGY_WEDGE'};

ss1_t19_cols = cellfun(@(r) ['SS1_', r, '_CE'], Params.Reg_Names_5, 'UniformOutput', false);
ss2_t19_cols = cellfun(@(r) ['SS2_', r, '_CE'], Params.Reg_Names_5, 'UniformOutput', false);
T19 = table(Layer_Codes, Layer_Type, ...
    SS1_11x4(:,1), SS1_11x4(:,2), SS1_11x4(:,3), SS1_11x4(:,4), SS1_Nat_11, ...
    SS2_11x4(:,1), SS2_11x4(:,2), SS2_11x4(:,3), SS2_11x4(:,4), SS2_Nat_11, ...
    Cumulative_Nat_SS2, Share_Of_Total_Pct, ...
    'VariableNames', [{'Layer_Code', 'Component_Type'}, ss1_t19_cols, ss2_t19_cols, ...
    {'Cumulative_National_SS2_CE', 'Share_Of_SS2_Total_Pct'}]);

% Document 1E Arts & Civic Mycelium Cap (+Delta W1..W4, scaled by u_civic):
Arts_Codes = { ...
    'L03E_WEDGE1_Arts_Psychosocial'; ...
    'L07E_WEDGE2_JoinOrDie_CivicSpace'; ...
    'L08E_WEDGE3_CreativeZH_Retention'; ...
    'L11E_WEDGE4_Bridging_Cohesion_2ndGen'};

Arts_SS1_4x4 = u_civic * [ ...
    0.54,  0.60,  0.63,  0.66; ...
    0.53,  0.51,  0.47,  0.44; ...
    0.45,  0.50,  0.59,  0.60; ...
    0.19,  0.20,  0.22,  0.22];

Arts_SS2_4x4 = u_civic * [ ...
    0.76,  0.85,  0.90,  0.94; ...
    0.82,  0.80,  0.74,  0.72; ...
    0.95,  1.05,  1.22,  1.23; ...
    0.57,  0.61,  0.64,  0.64];

if enable_arts && sa_ss2 > 65
    kaumatua_eros = max(0.55, 1.0 - 0.10 * (sa_ss2 - 65));
    Arts_SS2_4x4(2, :) = Arts_SS2_4x4(2, :) * kaumatua_eros;
    Arts_SS2_4x4(4, :) = Arts_SS2_4x4(4, :) * kaumatua_eros;
end

Arts_SS1_Nat_4 = Arts_SS1_4x4 * Pop_Weights';
Arts_SS2_Nat_4 = Arts_SS2_4x4 * Pop_Weights';
Arts_SS1_5     = [Arts_SS1_4x4, Arts_SS1_Nat_4];
Arts_SS2_5     = [Arts_SS2_4x4, Arts_SS2_Nat_4];

Ext15_Codes   = [Layer_Codes; Arts_Codes];
Ext15_Types   = [Layer_Type; repmat({'ARTS_CIVIC_WEDGE_CAP'}, 4, 1)];
Ext15_SS1_4   = [SS1_11x4; Arts_SS1_4x4];
Ext15_SS1_Nat = [SS1_Nat_11; Arts_SS1_Nat_4];
Ext15_SS2_4   = [SS2_11x4; Arts_SS2_4x4];
Ext15_SS2_Nat = [SS2_Nat_11; Arts_SS2_Nat_4];
Ext15_Cum_SS2 = cumsum(Ext15_SS2_Nat);
Ext15_Share   = 100 * Ext15_SS2_Nat / max(1e-6, sum(Ext15_SS2_Nat));

T19E = table(Ext15_Codes, Ext15_Types, ...
    Ext15_SS1_4(:,1), Ext15_SS1_4(:,2), Ext15_SS1_4(:,3), Ext15_SS1_4(:,4), Ext15_SS1_Nat, ...
    Ext15_SS2_4(:,1), Ext15_SS2_4(:,2), Ext15_SS2_4(:,3), Ext15_SS2_4(:,4), Ext15_SS2_Nat, ...
    Ext15_Cum_SS2, Ext15_Share, ...
    'VariableNames', [{'Layer_Code', 'Component_Type'}, ss1_t19_cols, ss2_t19_cols, ...
    {'Cumulative_National_SS2_CE', 'Share_Of_T1E_Total_Pct'}]);

% Target region resolution ('Rural'|'Small'|'Large'|'Auckland'|'National')
r_sel = 'National';
if isfield(Params, 'Target_Region') && ~isempty(Params.Target_Region)
    if iscell(Params.Target_Region), r_sel = char(Params.Target_Region{1});
    else, r_sel = char(Params.Target_Region); end
elseif isfield(Params, 'Target_Regions') && ~isempty(Params.Target_Regions)
    if iscell(Params.Target_Regions) && numel(Params.Target_Regions) == 1
        r_sel = char(Params.Target_Regions{1});
    elseif ischar(Params.Target_Regions) || isstring(Params.Target_Regions)
        r_sel = char(Params.Target_Regions);
    end
end
col_idx = find(strcmpi(r_sel, Params.Reg_Names_5), 1);
if isempty(col_idx), col_idx = 5; end
r_sel   = Params.Reg_Names_5{col_idx};

SS1_Sel_11    = SS1_11x5(:, col_idx);
SS2_Sel_11    = SS2_11x5(:, col_idx);
Arts_SS1_Sel  = Arts_SS1_5(:, col_idx);
Arts_SS2_Sel  = Arts_SS2_5(:, col_idx);
SS2_Sel_Total = sum(SS2_Sel_11);
reg_pop_wt    = Params.Pop_Weights_5(col_idx);
NZD_Per_CE    = Params.NZD_Per_CE_Nat * reg_pop_wt;
GDP_Sel_BNZD  = Params.GDP_2026_BNZD  * reg_pop_wt;
sh_ygr_base0  = Params.sh_ygr_base0_5(col_idx);

Waves_13      = Params.Waves_13;
ECE_13_Share  = Params.Kahui_ECE_13x5(:, col_idx);
YGr_New_Share = Params.Kahui_YGr_New_13x5(:, col_idx);
Elc_13_Share  = Params.Kahui_Elc_13x5(:, col_idx);

% Vectorized Cohort Grid Evaluation (Years -10 to +60, 0 Loops)
Yr_Grid              = (-10:0.5:60)';
n_yr                 = numel(Yr_Grid);
m_pre                = Yr_Grid < 0;
m_pos                = ~m_pre;
y_pre                = Yr_Grid(m_pre);
y_pos                = Yr_Grid(m_pos);
y1_pos               = min(y_pos, 25.0);

Traj_11              = zeros(n_yr, 11);
Traj_11_1Shot        = zeros(n_yr, 11);
Traj_Arts            = zeros(n_yr, 4);
YGr_Early_Share_Grid = zeros(n_yr, 1);

w_pre_mat              = (0.04 * exp(y_pre / 2.5)) * [0.5, 0, 0, 1, 0, 1, 0, 0, 0.5, 0, 0];
Traj_11(m_pre, :)      = w_pre_mat .* (SS1_Sel_11');
Traj_11_1Shot(m_pre,:) = (2.5 * w_pre_mat) .* (SS1_Sel_11');
Traj_Arts(m_pre, :)    = (0.12 * exp(y_pre / 4.0)) * [0.0, 1.0, 0.25, 0.40] .* (Arts_SS1_Sel');

t_join  = 16.0;
dw_e_13 = [ECE_13_Share(1); diff(ECE_13_Share)];
dw_y_13 = (1.0 - sh_ygr_base0) * [YGr_New_Share(1); diff(YGr_New_Share)];
dw_l_13 = [Elc_13_Share(1); diff(Elc_13_Share)];

dy_s1_e  = y_pos - (Waves_13 - 0.8)';
w_kh_ece = ((dy_s1_e > 0) .* (1.0 - 0.68 * exp(-max(0.0, dy_s1_e) / 3.2))) * dw_e_13;
w_kh_elc = ((dy_s1_e > 0) .* (1.0 - 0.60 * exp(-max(0.0, dy_s1_e) / 2.6))) * dw_l_13;

dy_s1_y       = y_pos - (Waves_13 - 0.5)';
w_kh_ygr_new  = (((y_pos >= 7.0) & (dy_s1_y > 0)) .* (1.0 - 0.55 * exp(-max(0.0, dy_s1_y) / 2.8))) * dw_y_13;
w_kh_ygr_base = (y_pos > 0.2) .* sh_ygr_base0 .* (1.0 - 0.45 * exp(-max(0.0, y_pos - 0.2) / 1.8));
w_kh_ygr      = w_kh_ygr_base + w_kh_ygr_new;

yr_w_pos          = [0; Waves_13; 25; 60];
ygr_uni_cov       = (y_pos >= 7.0) .* interp1(yr_w_pos, [0.00; YGr_New_Share; 1.0; 1.0], min(60.0, max(0.0, y_pos - 0.5)), 'linear');
w_kh_ygr_ear_only = w_kh_ygr_base .* max(0.0, 1.0 - ygr_uni_cov);
YGr_Early_Share_Grid(m_pos) = min(1.0, w_kh_ygr_ear_only ./ max(1e-8, w_kh_ygr));

sh_tax_t   = 0.38 * min(1.0, y_pos / Params.T_ramp_CGT_Est_yrs) + 0.62 * min(1.0, y_pos / Params.T_ramp_LVT_yrs);
w_kh_tax   = sh_tax_t .* (1.0 - 0.50 * exp(-y_pos / 3.8));
retire_kh  = 1.0 ./ (1.0 + exp(-(y1_pos - 14.0) / 3.8));
w_kh_geo   = (0.65 * w_kh_elc + 0.35 * (1.0 - exp(-y_pos / 2.0))) .* (1.0 - 0.55 * retire_kh);

w_wed1_kh  = (w_kh_ece .^ 1.12) ./ (1.0 + exp(-(y1_pos - 8.2) / 3.6));
w_wed2_kh  = (0.75 * w_kh_ygr .* w_kh_tax + 0.25 * w_kh_tax) ./ (1.0 + exp(-(y1_pos - 7.5) / 3.5));
w_wed3_kh  = ((w_kh_ece .* w_kh_tax) .^ 0.85) ./ (1.0 + exp(-(y1_pos - 11.8) / 3.8));

Row_kh      = [w_kh_ece, w_kh_ece, w_wed1_kh, w_kh_tax, w_kh_ygr, w_kh_geo, w_wed2_kh, w_wed3_kh, 0.55*w_kh_tax, zeros(size(y_pos)), w_wed3_kh] .* (SS1_Sel_11');
Row_kh(:,8) = Row_kh(:,8) + max(0.0, w_kh_ece - w_kh_geo) * SS1_Sel_11(6);

dy_s2_hc       = y_pos - (20.5 + Waves_13)';
dy_s2_ygr      = y_pos - (16.0 + Waves_13)';
w_ss2_echo_hc  = ((dy_s2_hc  > 0) .* (1.0 - exp(-max(0.0, dy_s2_hc)  / 5.8))) * dw_e_13;
w_ss2_echo_ygr = sh_ygr_base0 * (y_pos > 18.0) .* (1.0 - exp(-max(0.0, y_pos - 18.0) / 5.8)) ...
    + ((dy_s2_ygr > 0) .* (1.0 - exp(-max(0.0, dy_s2_ygr) / 5.6))) * dw_y_13;
w_ss2_fisc     = (1.0 ./ (1.0 + exp(-(y_pos - 25.0) / 2.5))) .* (1.0 - exp(-max(0.0, y_pos - 20.0) / 6.0));
w_geo_ret2     = (1.0 ./ (1.0 + exp(-(y_pos - 24.5) / 2.5))) .* (1.0 - exp(-max(0.0, y_pos - 20.0) / 4.5));

D_ss2_kh    = (SS2_Sel_11') - Row_kh;
W_ss2_mat   = [w_ss2_echo_hc, w_ss2_echo_hc, w_ss2_echo_hc, w_ss2_echo_ygr, w_ss2_echo_ygr, ...
    w_geo_ret2, w_ss2_echo_ygr, 0.5*(w_ss2_echo_hc + w_ss2_echo_ygr), ...
    w_ss2_fisc, w_ss2_fisc, 0.65*w_ss2_echo_hc + 0.35*w_ss2_fisc];
Row_kh      = max(0.0, Row_kh + W_ss2_mat .* D_ss2_kh);
Row_kh(:,8) = max(0.0, Row_kh(:,8) - (w_geo_ret2 - 0.5*(w_ss2_echo_hc + w_ss2_echo_ygr)) .* D_ss2_kh(:,6));
Traj_11(m_pos, :) = Row_kh;

% Vectorized Arts & Civic Cap trajectory (y >= 0, fast Joiner Fair / Meanwhile Space ignition):
w_art1    = 1.0 ./ (1.0 + exp(-(y1_pos - 6.5)  / 3.4));
w_art2    = 0.28 + 0.72 * (1.0 - exp(-y1_pos / 4.5));
w_art3    = 1.0 ./ (1.0 + exp(-(y1_pos - 9.5)  / 3.8));
w_art4    = 1.0 ./ (1.0 + exp(-(y1_pos - 12.0) / 4.2));
Row_arts  = [w_art1, w_art2, w_art3, w_art4] .* (Arts_SS1_Sel');
w_art_ss2 = (y_pos >= 25.0) .* (1.0 - exp(-max(0.0, y_pos - 25.0) / 8.5));
Row_arts  = Row_arts + w_art_ss2 .* ((Arts_SS2_Sel') - Row_arts);
Traj_Arts(m_pos, :) = Row_arts;

% Single-Phase Step Reference (y >= 0):
b_drag_1s   = 1.0 - 0.16 * exp(-y_pos / 4.2);
w_iso_1s    = (0.28 + 0.72 * (1.0 - exp(-y1_pos / 4.8))) .* b_drag_1s;
w_geo_1s    = (1.0 - 0.30 * exp(-y1_pos / 2.0)) .* (1.0 - 0.55 ./ (1.0 + exp(-(y1_pos - 14.0) / 3.8)));
w_wed1_1s   = b_drag_1s ./ (1.0 + exp(-(y1_pos - 8.2)  / 3.6));
w_wed2_1s   = b_drag_1s ./ (1.0 + exp(-(y1_pos - 7.5)  / 3.5));
w_wed3_1s   = b_drag_1s ./ (1.0 + exp(-(y1_pos - 11.8) / 3.8));
unment_drag = 1.0 - (0.42 * (1.0 - sh_ygr_base0)) * exp(-y_pos / 3.8);

Row_1s_raw      = [w_iso_1s, w_iso_1s, w_wed1_1s, w_iso_1s, w_iso_1s.*unment_drag, w_geo_1s, w_wed2_1s.*unment_drag, w_wed3_1s, 0.55*w_iso_1s, zeros(size(y_pos)), w_wed3_1s] .* (SS1_Sel_11');
Row_1s_raw(:,8) = Row_1s_raw(:,8) + max(0.0, w_iso_1s - w_geo_1s) * SS1_Sel_11(6);

join_w = min(1.0, max(0.0, (y_pos - 10.0) / (t_join - 10.0)));
join_w = (join_w .^ 2) .* (3.0 - 2.0 * join_w);
Traj_11_1Shot(m_pos, :) = (1.0 - join_w) .* Row_1s_raw + join_w .* Row_kh;

Total_Traj_CE      = sum(Traj_11, 2);
Arts_Cap_Traj_CE   = sum(Traj_Arts, 2);
Total_Arts_Traj_CE = Total_Traj_CE + Arts_Cap_Traj_CE;
Iso_Only_Traj_CE   = sum(Traj_11(:, ~Is_Wedge), 2);
Total_1Shot_Grid   = sum(Traj_11_1Shot, 2);

% Mirror-Image Calendar Grid (0:2:60)
Yr_Mir  = (0:2:60)';
y1_mir  = min(Yr_Mir, 25.0);
yr_w_g  = [0; Waves_13; 25; 60];

Pos_11_Mir    = interp1(Yr_Grid, Traj_11_1Shot,        Yr_Mir, 'pchip');
Pos_11_Kahui  = interp1(Yr_Grid, Traj_11,              Yr_Mir, 'pchip');
Pos_Arts_Mir  = interp1(Yr_Grid, Traj_Arts,            Yr_Mir, 'pchip');
Early_Share_M = interp1(Yr_Grid, YGr_Early_Share_Grid, Yr_Mir, 'linear');

Total_Mir_CE        = sum(Pos_11_Mir,   2);
Total_Kahui_CE      = sum(Pos_11_Kahui, 2);
Arts_Cap_Mir_CE     = sum(Pos_Arts_Mir, 2);
Total_Arts_Kahui_CE = Total_Kahui_CE + Arts_Cap_Mir_CE;

SS1_Inv_CE  = -[1.45, 0.52, 0.68, 0.65];
SS2_Inv_CE  = -[1.35, 0.55, 0.60, 0.12];
SS1_ArtsInv = -0.15 * u_civic;
SS2_ArtsInv = -0.14 * u_civic;

ramp_1s_m   = 1.0 - 0.35 * exp(-y1_mir / 2.5);
retire_1s_m = 1.0 ./ (1.0 + exp(-(y1_mir - 15.0) / 4.0));
Neg_4Investments_CE      = ramp_1s_m * SS1_Inv_CE;
Neg_4Investments_CE(:,4) = Neg_4Investments_CE(:,4) .* (1.0 - 0.55 * retire_1s_m);
Remediation_Savings_CE   = 4.65 ./ (1.0 + exp(-(y1_mir - 16.5) / 4.2));

w_inv2_m    = (Yr_Mir >= 25.0) .* (1.0 - exp(-max(0.0, Yr_Mir - 25.0) / 5.0));
Neg_4Investments_CE    = Neg_4Investments_CE + w_inv2_m .* (SS2_Inv_CE - Neg_4Investments_CE);
Remediation_Savings_CE = Remediation_Savings_CE + (Yr_Mir >= 25.0) .* (1.45 * (1.0 - exp(-max(0.0, Yr_Mir - 25.0) / 9.0)));

sh_ece_m     = interp1(yr_w_g, [0.00; ECE_13_Share; 1.0; 1.0], min(60.0, Yr_Mir), 'linear');
sh_elc_m     = interp1(yr_w_g, [0.00; Elc_13_Share; 1.0; 1.0], min(60.0, Yr_Mir), 'linear');
uni_ygr_cov  = (Yr_Mir >= 7.0) .* interp1(yr_w_g, [0.00; YGr_New_Share; 1.0; 1.0], min(60.0, Yr_Mir), 'linear');

sh_ygr_ear_m = (Yr_Mir > 0) .* min(1.0, Yr_Mir / 1.5) .* sh_ygr_base0 .* (1.0 - uni_ygr_cov);
sh_ygr_uni_m = uni_ygr_cov;
sh_ygr_m     = sh_ygr_ear_m + sh_ygr_uni_m;
retire_kh_m  = 1.0 ./ (1.0 + exp(-(y1_mir - 13.5) / 3.6));

Neg_4Inv_Kahui_CE = [sh_ece_m, sh_ece_m, sh_ygr_m, 0.65*sh_elc_m.*(1.0 - 0.72*retire_kh_m) + 0.35*min(1.0, Yr_Mir/2.0)] .* SS1_Inv_CE;
w_inv_kh20        = (Yr_Mir >= 20.0) .* (1.0 - exp(-max(0.0, Yr_Mir - 20.0) / 4.8));
Neg_4Inv_Kahui_CE = Neg_4Inv_Kahui_CE + w_inv_kh20 .* (SS2_Inv_CE - Neg_4Inv_Kahui_CE);

Neg_JoinerPassport_CE = ramp_1s_m * SS1_ArtsInv;
Neg_JoinerPassport_CE = Neg_JoinerPassport_CE + w_inv2_m .* (SS2_ArtsInv - Neg_JoinerPassport_CE);
Remed_ArtsBonus_CE    = u_civic * (0.62 ./ (1.0 + exp(-(y1_mir - 8.5) / 3.2)) ...
    + (Yr_Mir >= 25.0) .* (0.25 * (1.0 - exp(-max(0.0, Yr_Mir - 25.0) / 8.0))));

join_m = min(1.0, max(0.0, (Yr_Mir - 11.0) / (t_join - 11.0)));
join_m = (join_m .^ 2) .* (3.0 - 2.0 * join_m);
Neg_4Investments_CE = (1.0 - join_m) .* Neg_4Investments_CE + join_m .* Neg_4Inv_Kahui_CE;

Pos_12_Mir   = [Pos_11_Mir(:, 1:4),   zeros(size(Yr_Mir)),               Pos_11_Mir(:, 5),                      Pos_11_Mir(:, 6:11)];
Pos_12_Kahui = [Pos_11_Kahui(:, 1:4), Pos_11_Kahui(:, 5).*Early_Share_M, Pos_11_Kahui(:, 5).*(1-Early_Share_M), Pos_11_Kahui(:, 6:11)];

ear_frac_inv3        = sh_ygr_ear_m ./ max(1e-8, sh_ygr_m);
Neg_Inv3_Early_Kh_CE = Neg_4Inv_Kahui_CE(:, 3) .* ear_frac_inv3;
Neg_Inv3_New_Kh_CE   = Neg_4Inv_Kahui_CE(:, 3) .* (1.0 - ear_frac_inv3);

sh_tax_m            = 0.38 * min(1.0, Yr_Mir / Params.T_ramp_CGT_Est_yrs) + 0.62 * min(1.0, Yr_Mir / Params.T_ramp_LVT_yrs);
remed_raw_m         = 4.92 ./ (1.0 + exp(-(Yr_Mir - 14.8) / 3.85)) - 4.92 / (1.0 + exp(14.8 / 3.85));
Remed_Savings_Kh_CE = remed_raw_m + 0.28 * sh_tax_m .* exp(-max(0.0, Yr_Mir - 5.0) / 5.0) + 0.055 * min(1.0, Yr_Mir / 4.0);

Neg_5_Mir   = [Neg_4Investments_CE(:, 1:2), zeros(size(Yr_Mir)),  Neg_4Investments_CE(:, 3), Neg_4Investments_CE(:, 4)];
Neg_5_Kahui = [Neg_4Inv_Kahui_CE(:, 1:2),   Neg_Inv3_Early_Kh_CE, Neg_Inv3_New_Kh_CE,        Neg_4Inv_Kahui_CE(:, 4)];

Gross_Investment_Mirror_CE   = sum(Neg_4Investments_CE, 2);
Gross_Investment_Mirror_BNZD = Gross_Investment_Mirror_CE * NZD_Per_CE;
Gross_Inv_Kahui_CE           = sum(Neg_4Inv_Kahui_CE, 2);
Gross_Inv_Arts_Kahui_CE      = Gross_Inv_Kahui_CE + Neg_JoinerPassport_CE;

Net_Fiscal_Outlay_Mirror_CE     = min(0.0, Gross_Investment_Mirror_CE + Remediation_Savings_CE);
Net_Fiscal_Outlay_Kahui_CE      = min(0.0, Gross_Inv_Kahui_CE         + Remed_Savings_Kh_CE);
Net_Fiscal_Outlay_Arts_Kahui_CE = min(0.0, Gross_Inv_Arts_Kahui_CE    + Remed_Savings_Kh_CE + Remed_ArtsBonus_CE);

r_disc_SRTP  = 0.020;
g_cost_real  = 0.015;
alpha_attr   = 0.300;
psi_persist  = 0.986;
H_window     = 25;
q_step       = ((1 + g_cost_real) / (1 + r_disc_SRTP)) * psi_persist;
pv_mult_25yr = sum(q_step .^ (1:H_window)) / H_window;

s_row_25     = linspace(0.0, 1.0, H_window);
Y_Look_2D    = Yr_Mir + (min(max(Yr_Grid), Yr_Mir + H_window) - Yr_Mir) .* s_row_25;
welf_look_m  = mean(interp1(Yr_Grid, Total_Traj_CE,      Y_Look_2D, 'pchip'), 2);
welf_look_E  = mean(interp1(Yr_Grid, Total_Arts_Traj_CE, Y_Look_2D, 'pchip'), 2);
fwd_pot_m    = (1.0 - alpha_attr) * pv_mult_25yr * welf_look_m;
fwd_pot_E    = (1.0 - alpha_attr) * pv_mult_25yr * welf_look_E;

phi_pipe_m   = min(1.0, max(0.0, Yr_Mir / 15.0));
phi_1s_m     = min(1.0, max(0.0, (Yr_Mir + 1.2) / 14.0));
sh_enr_m     = 0.75 * sh_ece_m + 0.25 * sh_ygr_m;

Actuarial_CBAx_Mirror_CE     = min(Total_Mir_CE(end), ...
    (1.0 - phi_pipe_m) .* (Net_Fiscal_Outlay_Mirror_CE + phi_1s_m .* fwd_pot_m) + phi_pipe_m .* Total_Mir_CE);
Actuarial_CBAx_Kahui_CE      = min(Total_Kahui_CE(end), ...
    (1.0 - phi_pipe_m) .* (Net_Fiscal_Outlay_Kahui_CE  + (sh_enr_m .^ 0.75) .* min(1.0, Yr_Mir / 12.0) .* fwd_pot_m) + phi_pipe_m .* Total_Kahui_CE);
Actuarial_CBAx_Arts_Kahui_CE = min(Total_Arts_Kahui_CE(end), ...
    (1.0 - phi_pipe_m) .* (Net_Fiscal_Outlay_Arts_Kahui_CE + (sh_enr_m .^ 0.75) .* min(1.0, Yr_Mir / 12.0) .* fwd_pot_E) + phi_pipe_m .* Total_Arts_Kahui_CE);
Actuarial_CBAx_Mirror_BNZD   = Actuarial_CBAx_Mirror_CE * NZD_Per_CE;

Yr_Fine               = linspace(-3, 60, 631)';
s60_fine              = max(0.0, Yr_Fine) / 60.0;
Debt_LTFM_Stock_Fine  = 42.0 + 143.0 * (s60_fine .^ 1.45);
dDebt_dt_PctGDP_Fine  = -143.0 * (1.45 / 60.0) * (s60_fine .^ 0.45);
LTFM_Ann_Deficit_BNZD = dDebt_dt_PctGDP_Fine * (GDP_Sel_BNZD / 100.0);
LTFM_Ann_Deficit_CE   = LTFM_Ann_Deficit_BNZD / NZD_Per_CE;
LTFM_Ann_Deficit_CE(Yr_Fine < 0)   = 0.0;
LTFM_Ann_Deficit_BNZD(Yr_Fine < 0) = 0.0;

LTFM_Ann_Flow_CE_Mir   = interp1(Yr_Fine, LTFM_Ann_Deficit_CE,   Yr_Mir, 'pchip');
LTFM_Ann_Flow_BNZD_Mir = interp1(Yr_Fine, LTFM_Ann_Deficit_BNZD, Yr_Mir, 'pchip');
Debt_LTFM_Stock_Mir    = interp1(Yr_Fine, Debt_LTFM_Stock_Fine,  Yr_Mir, 'pchip');

% Preserves all 21 existing Table 20 columns + appends the 5 Arts-Enabled columns cleanly!
T20 = table(Yr_Mir, Total_Mir_CE, Total_Mir_CE * NZD_Per_CE, ...
    sum(Pos_11_Mir(:, ~Is_Wedge), 2), sum(Pos_11_Mir(:, Is_Wedge), 2), ...
    Neg_4Investments_CE(:,1), Neg_4Investments_CE(:,2), Neg_4Investments_CE(:,3), Neg_4Investments_CE(:,4), ...
    Gross_Investment_Mirror_CE, Gross_Investment_Mirror_BNZD, ...
    Net_Fiscal_Outlay_Mirror_CE, Actuarial_CBAx_Mirror_CE, Actuarial_CBAx_Mirror_BNZD, ...
    Total_Kahui_CE, Gross_Inv_Kahui_CE, Net_Fiscal_Outlay_Kahui_CE, Actuarial_CBAx_Kahui_CE, ...
    LTFM_Ann_Flow_CE_Mir, LTFM_Ann_Flow_BNZD_Mir, Debt_LTFM_Stock_Mir, ...
    Arts_Cap_Mir_CE, Total_Arts_Kahui_CE, Neg_JoinerPassport_CE, Net_Fiscal_Outlay_Arts_Kahui_CE, Actuarial_CBAx_Arts_Kahui_CE, ...
    'VariableNames', {'Year', 'Total_Welfare_Gain_CE_Pct', 'Total_Welfare_Equiv_BNZD_Yr', ...
    'Isolated_Factors_Sum_CE', 'Synergy_Wedges_Sum_CE', ...
    'MirrorInv1_Universal_ECE_CE', 'MirrorInv2_Tuakana_Mentoring_CE', ...
    'MirrorInv3_YouthGrant_CE', 'MirrorInv4_GeoTransfer_CE', ...
    'Total_Gross_Inv_Mirror_CE_Pct', 'Total_Gross_Inv_Mirror_BNZD_Yr', ...
    'Net_Unrecovered_Outlay_Mirror_CE', 'Actuarial_CBAx_Net_CE_Pct', 'Actuarial_CBAx_Net_BNZD_Yr', ...
    'Total_TeKahuiWaka_Welfare_CE_Pct', 'Total_Gross_Inv_TeKahuiWaka_CE_Pct', ...
    'Net_Unrecovered_Outlay_TeKahuiWaka_CE', 'Actuarial_CBAx_TeKahuiWaka_CE_Pct', ...
    'LTFM_Annual_Deficit_Flow_CE_Pct', 'LTFM_Annual_Deficit_Flow_BNZD_Yr', 'LTFM_Cumulative_Debt_PctGDP', ...
    'ArtsCivic_Cap_CE_Pct', 'ArtsEnabled_Total_Welfare_CE_Pct', ...
    'MirrorInv2E_JoinerPassport_CE', 'Net_Unrecovered_Outlay_Arts_CE', 'Actuarial_CBAx_Arts_CE_Pct'});

L = struct();
L.Params               = Params;
L.AnchorTag            = Params.Calibration_Anchor;
L.Profile_ID           = Params.Profile_ID;
L.Target_Region        = r_sel;
L.Col_Idx              = col_idx;
L.enable_arts          = enable_arts;
L.u_civic              = u_civic;
L.Pop_Weights          = Pop_Weights;
L.NZD_Per_CE           = NZD_Per_CE;
L.sh_ygr_base0         = sh_ygr_base0;
L.t_join               = t_join;
L.box25_label          = box25_label;
L.tier4_hdr            = tier4_hdr;
L.Layer_Codes          = Layer_Codes;
L.Layer_Legend_Labels  = Layer_Legend_Labels;
L.Is_Wedge             = Is_Wedge;
L.Iso_Idx              = Iso_Idx;
L.Wed_Idx              = Wed_Idx;
L.SS1_11x5             = SS1_11x5;
L.SS2_11x5             = SS2_11x5;
L.SS2_Nat_11           = SS2_Nat_11;
L.SS1_Sel_11           = SS1_Sel_11;
L.SS2_Sel_11           = SS2_Sel_11;
L.SS2_Sel_Total        = SS2_Sel_Total;
L.Arts_SS1_5           = Arts_SS1_5;
L.Arts_SS2_5           = Arts_SS2_5;
L.Arts_SS1_Sel         = Arts_SS1_Sel;
L.Arts_SS2_Sel         = Arts_SS2_Sel;
L.Yr_Grid              = Yr_Grid;
L.Traj_11              = Traj_11;
L.Traj_11_1Shot        = Traj_11_1Shot;
L.Traj_Arts            = Traj_Arts;
L.YGr_Early_Share_Grid = YGr_Early_Share_Grid;
L.Total_Traj_CE        = Total_Traj_CE;
L.Arts_Cap_Traj_CE     = Arts_Cap_Traj_CE;
L.Total_Arts_Traj_CE   = Total_Arts_Traj_CE;
L.Iso_Only_Traj_CE     = Iso_Only_Traj_CE;
L.Total_1Shot_Grid     = Total_1Shot_Grid;
L.Yr_Mir               = Yr_Mir;
L.Pos_12_Mir           = Pos_12_Mir;
L.Pos_12_Kahui         = Pos_12_Kahui;
L.Pos_Arts_Mir         = Pos_Arts_Mir;
L.Neg_5_Mir            = Neg_5_Mir;
L.Neg_5_Kahui          = Neg_5_Kahui;
L.Neg_JoinerPassport_CE= Neg_JoinerPassport_CE;
L.Total_Mir_CE         = Total_Mir_CE;
L.Total_Kahui_CE       = Total_Kahui_CE;
L.Total_Arts_Kahui_CE  = Total_Arts_Kahui_CE;
L.Net_Fiscal_Outlay_Mirror_CE     = Net_Fiscal_Outlay_Mirror_CE;
L.Net_Fiscal_Outlay_Kahui_CE      = Net_Fiscal_Outlay_Kahui_CE;
L.Net_Fiscal_Outlay_Arts_Kahui_CE = Net_Fiscal_Outlay_Arts_Kahui_CE;
L.Actuarial_CBAx_Mirror_CE        = Actuarial_CBAx_Mirror_CE;
L.Actuarial_CBAx_Kahui_CE         = Actuarial_CBAx_Kahui_CE;
L.Actuarial_CBAx_Arts_Kahui_CE    = Actuarial_CBAx_Arts_Kahui_CE;
L.Yr_Fine              = Yr_Fine;
L.LTFM_Ann_Deficit_CE  = LTFM_Ann_Deficit_CE;
L.LTFM_Ann_Deficit_BNZD= LTFM_Ann_Deficit_BNZD;
L.Debt_LTFM_Stock_Fine = Debt_LTFM_Stock_Fine;
L.Table19              = T19;
L.Table19E             = T19E;
L.Table20              = T20;
end
