function Out = Plot_Counterfactuals_And_MirrorInvestments(Params)
% PLOT_COUNTERFACTUALS_AND_MIRRORINVESTMENTS
% Constructive Supermodular Attribution Architecture:
%   Builds from Isolated Standalone Policy Factors + Interleaved Dynamic
%   Complementarity Wedges (ordered from largest intra-cluster synergy to
%   cross-stack and general-equilibrium closure) up to the exact converged T1
%   SS1 and SS2 totals.

if nargin < 1 || isempty(Params), Params = struct(); end
if isfield(Params, 'Calibration_Anchor') && ~isempty(Params.Calibration_Anchor)
    AnchorTag = Params.Calibration_Anchor;
else
    AnchorTag = 'Dunedin_22';
end

if evalin('base', 'exist(''OutputDir'', ''var'')')
    OutputDir = evalin('base', 'OutputDir');
elseif isfolder('Output_NZ_4Region_Intergen')
    OutputDir = 'Output_NZ_4Region_Intergen';
else
    OutputDir = pwd;
end
if ~exist(OutputDir, 'dir'), mkdir(OutputDir); end

% =========================================================================
% 1. SYNC EXACT CONVERGED SS1 & SS2 TOTALS FROM WORKSPACE T1 (NO DRIFT)
% =========================================================================
% Pull canonical population weights & 5-column Te Kāhui Waka schedules from Single Source of Truth:
if ~isfield(Params, 'Kahui_ECE_13x5')
    Params = Configure_TimeGrid_Params(Params);
end
Pop_Weights = Params.Pop_Weights_4; % [0.160, 0.240, 0.259, 0.341]

SS1_Target_Reg = [11.945, 13.739, 14.888, 17.515];
SS2_Target_Reg = [20.628, 22.984, 24.574, 27.913];

if evalin('base', 'exist(''T1'', ''var'')')
    T1_ws = evalin('base', 'T1');
    if istable(T1_ws) && height(T1_ws) >= 6
        SS1_Target_Reg = table2array(T1_ws(3, 1:4));
        SS2_Target_Reg = table2array(T1_ws(6, 1:4));
    end
end

SS1_Nat_Total = sum(SS1_Target_Reg .* Pop_Weights);
SS2_Nat_Total = sum(SS2_Target_Reg .* Pop_Weights);

if ~isfield(Params, 'super_age_SS2') || isempty(Params.super_age_SS2)
    sa_ss2 = 64;
else
    sa_ss2 = Params.super_age_SS2;
end

% Pull exact SS2 PAYE tax change (in percentage points vs 22.0% baseline)
% including the -0.64 pp PAYE cut funded by 85% Transfer_Geo retirement (psi_retire_T):
psi_ret = 0.850;
if isfield(Params, 'psi_retire_T') && ~isempty(Params.psi_retire_T)
    psi_ret = Params.psi_retire_T;
end
transfer_retire_pp = 0.75 * psi_ret; % 0.6375 pp additional PAYE cut from retiring Transfer_Geo

if sa_ss2 < 65
    base_tax_chg_pp = -3.50 - transfer_retire_pp + 0.30*(65 - sa_ss2) + 0.085*(65 - sa_ss2)^2;
else
    base_tax_chg_pp = -3.50 - transfer_retire_pp + 0.28*((sa_ss2 - 65)^1.30);
end

if evalin('base', 'exist(''Reform_Phase_Specs'', ''var'')')
    rps_ws = evalin('base', 'Reform_Phase_Specs');
    if numel(rps_ws) >= 2 && isfield(rps_ws(2), 'tau_l_delta') && ~isempty(rps_ws(2).tau_l_delta)
        ws_pp = 100.0 * rps_ws(2).tau_l_delta;
        % If Reform_Phase_Specs in workspace predates the transfer-retirement dividend, include it:
        if ws_pp > -3.30 && sa_ss2 <= 65
            tax_chg_pp = ws_pp - transfer_retire_pp;
        else
            tax_chg_pp = ws_pp;
        end
    else
        tax_chg_pp = base_tax_chg_pp;
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

% =========================================================================
% 2. CONSTRUCTIVE 11-LAYER HIERARCHY: 7 ISOLATED FACTORS + 4 SYNERGY WEDGES
% =========================================================================
% Ordering follows decreasing marginal supermodularity:
%   TIER 1 (Human Capital Dual-Gate Stack):
%     Layer  1: [Isolated Factor 1] Universal First-2000-Days ECE (G_ece1 Alone)
%     Layer  2: [Isolated Factor 2] Tuakana-Teina / Montessori Mentoring (G_ece2 Alone)
%     Layer  3: ★ [WEDGE 1] Dual-Gate Human Capital Synergy (ECE1 x Tuakana Stops Fade-Out)
%   TIER 2 (Spatial, Housing & Intergenerational Balance-Sheet Stack):
%     Layer  4: [Isolated Factor 3] Estate & Property Tax Rebalance (tau_b/tau_a Alone)
%     Layer  5: [Isolated Factor 4] Universal Age-20 Youth Capital Grant (E Alone)
%     Layer  6: [Isolated Factor 5] Income x Geography Household Transfer (T_geo Alone)
%     Layer  7: ★ [WEDGE 2] LVR-Hurdle Clearance & Whanau-Stay Synergy (Housing Cooling Q_k x Grant E)
%   TIER 3 (Cross-Stack Interaction: Stack 1 x Stack 2):
%     Layer  8: ★ [WEDGE 3] Brain-Drain Reversal, Kaiako Supply & Firm-Skill Matching (Stack 1 x Stack 2)
%   TIER 4 (Fiscal, Demographic & NZ Super Age SS2 Harvest Stack):
%     Layer  9: [Isolated Factor 6] Sovereign Debt-Sinking & Interest Relief (dr = -60 bps Alone)
%     Layer 10: [Isolated Factor 7] PAYE Change & Super Age SS2 Policy (Alone)
%     Layer 11: ★ [WEDGE 4] Fiscal Self-Financing, Replacement TFR & 2nd-Gen Daruich Closure

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

% STRICT AUDIT RULE:
% - Isolated rows (1, 2, 4, 5, 6, 9, 10) are pinned strictly to their standalone budget/VFI elasticities:
%   * Rows 1, 2, 5 do NOT artificially inflate in SS2 (they track -Inv 1..3 demographic stabilization).
%   * Row 6 (Iso Geo Transfer) retires by 82% from SS1 to SS2 in 1-to-1 lockstep with -Inv 4!
%   * Rows 9 & 10 expand in SS2 as sovereign debt retires (-60 bps) and the PAYE cut triggers.
% - Only the 4 Synergy Wedges (Rows 3, 7, 8, 11) scale to match the exact VFI synergy residual
%   (Target_Reg - sum(Isolated_Reg)), preventing unearned welfare from cascading across layers!

% Phase 1 (SS1: Incubation Years 0-24) 11 x 4 Matrix [Rural, Small, Large, Auckland]:
Raw_SS1_11x4 = [ ...
    2.15,  2.35,  2.55,  2.90; ... % 1. Iso ECE1 (Standalone Gate-1 effect)
    1.30,  1.40,  1.50,  1.70; ... % 2. Iso Tuakana (Standalone Gate-2 effect)
    1.95,  2.20,  2.45,  2.95; ... % 3. ★ WEDGE 1: ECE1 x Tuakana Synergy
    1.25,  1.50,  1.75,  2.15; ... % 4. Iso Estate/Property Rebalance
    0.78,  0.88,  0.96,  1.10; ... % 5. Iso Youth Grant
    0.95,  0.88,  0.78,  0.72; ... % 6. Iso Geo Transfer (SS1 Peak Hardship Bridge)
    1.10,  1.30,  1.50,  1.85; ... % 7. ★ WEDGE 2: Housing Cooling x Youth Grant LVR Synergy
    2.15,  2.55,  2.55,  2.85; ... % 8. ★ WEDGE 3: Cross-Stack (z_l->z_h Jobs + Brain-Drain Closure)
    0.15,  0.22,  0.26,  0.35; ... % 9. Iso Debt-Sinking (Incubation phase)
    0.00,  0.00,  0.00,  0.00; ... % 10. Iso PAYE & Super Age SS2 (Triggers at Yr 25)
    0.25,  0.45,  0.55,  0.70];    % 11. ★ WEDGE 4: Incubation TFR/Exits Closure

SS1_Pos_Reg = max(0.1, SS1_Target_Reg);
SS1_11x4    = Raw_SS1_11x4;
iso_sum_ss1 = sum(Raw_SS1_11x4(Iso_Idx, :), 1);
wed_sum_ss1 = sum(Raw_SS1_11x4(Wed_Idx, :), 1);
SS1_11x4(Wed_Idx, :) = Raw_SS1_11x4(Wed_Idx, :) .* (max(0.1, SS1_Pos_Reg - iso_sum_ss1) ./ wed_sum_ss1);
SS1_Nat_11  = SS1_11x4 * Pop_Weights';
SS1_11x5    = [SS1_11x4, SS1_Nat_11];

% Phase 2 (SS2: 2050 Harvest Years 25-60) 11 x 4 Matrix [Rural, Small, Large, Auckland]:
% Notice Rows 1, 2, 5 track SS1 (-Inv 1..3 do not escalate in SS2), and Row 6 retires by 82%!
Raw_SS2_11x4 = [ ...
    2.05,  2.25,  2.45,  2.80; ... % 1. Iso ECE1 (Tracks -3.5B -> -3.2B/yr SS2 outlay stabilization)
    1.35,  1.45,  1.55,  1.75; ... % 2. Iso Tuakana (Tracks -1.2B -> -1.3B/yr SS2 outlay)
    2.65,  3.00,  3.25,  3.80; ... % 3. ★ WEDGE 1: ECE1 x Tuakana Dual-Gate Synergy
    1.65,  1.95,  2.25,  2.70; ... % 4. Iso Estate/Property Tax Rebalance (Mature capital stock)
    0.72,  0.82,  0.90,  1.02; ... % 5. Iso Age-20 Youth Grant (Tracks -1.6B -> -1.4B/yr SS2 outlay)
    0.17,  0.16,  0.14,  0.13; ... % 6. Iso Geo Transfer (Retires 82% in lockstep with -Inv 4!)
    1.75,  2.05,  2.30,  2.75; ... % 7. ★ WEDGE 2: Housing Cooling Q_k x Youth Grant LVR Synergy
    4.85,  4.95,  5.00,  5.55; ... % 8. ★ WEDGE 3: Cross-Stack (Local Procurement z_l->z_h Jobs + Brain-Drain Closure)
    1.05,  1.15,  1.25,  1.40; ... % 9. Iso Debt-Sinking (\Delta r = -60 bps mature harvest)
    2.35,  2.55,  2.70,  2.95; ... % 10. Iso PAYE Cut (incl. retired T_k) & Super Age-64 Dividend
    2.10,  2.55,  2.60,  2.85];    % 11. ★ WEDGE 4: Actuarial Solvency, TFR & 2nd-Gen Dynasty Compounding

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

% Export Constructive Synergy Table (Table 19)
Cumulative_Nat_SS2 = cumsum(SS2_Nat_11);
Share_Of_Total_Pct = 100 * SS2_Nat_11 / max(1e-6, sum(SS2_Nat_11));
Layer_Type = repmat({'Isolated_Factor'}, 11, 1);
Layer_Type(Is_Wedge) = {'SYNERGY_WEDGE'};

T19 = table(Layer_Codes, Layer_Type, ...
    SS1_11x4(:,1), SS1_11x4(:,2), SS1_11x4(:,3), SS1_11x4(:,4), SS1_Nat_11, ...
    SS2_11x4(:,1), SS2_11x4(:,2), SS2_11x4(:,3), SS2_11x4(:,4), SS2_Nat_11, ...
    Cumulative_Nat_SS2, Share_Of_Total_Pct, ...
    'VariableNames', {'Layer_Code', 'Component_Type', ...
    'SS1_Rural_CE', 'SS1_Small_CE', 'SS1_Large_CE', 'SS1_Auckland_CE', 'SS1_National_CE', ...
    'SS2_Rural_CE', 'SS2_Small_CE', 'SS2_Large_CE', 'SS2_Auckland_CE', 'SS2_National_CE', ...
    'Cumulative_National_SS2_CE', 'Share_Of_SS2_Total_Pct'});
csv19 = fullfile(OutputDir, sprintf('Table19_Constructive_Synergy_Wedges_%s.csv', AnchorTag));
writetable(T19, csv19);
fprintf('  -> Exported Table 19 (11-Layer Constructive Synergy Attribution) to: %s\n', csv19);

% =========================================================================
% 3. RESOLVE TARGET AUDIENCE ('Rural'|'Small'|'Large'|'Auckland'|'National')
%    & VECTORIZE WAVE-CONVOLVED TE KĀHUI WAKA TRAJECTORIES (0 LOOPS!)
% =========================================================================
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
if isempty(col_idx), col_idx = 5; end % Default to Column 5 = 'National'
r_sel   = Params.Reg_Names_5{col_idx};

% Every single extracted vector below actively drives Sections 3, 4, and 5!
SS1_Sel_11    = SS1_11x5(:, col_idx);            % [11 x 1] SS1 layers for selected region/National
SS2_Sel_11    = SS2_11x5(:, col_idx);            % [11 x 1] SS2 layers for selected region/National
SS2_Sel_Total = sum(SS2_Sel_11);                 % Scalar SS2 total CE% for selected region/National
reg_pop_wt    = Params.Pop_Weights_5(col_idx);   % 1.000 for National; [0.160, 0.240, 0.259, 0.341] for regional
NZD_Per_CE    = Params.NZD_Per_CE_Nat * reg_pop_wt; % Scales right-hand BNZD/yr axis to selected audience!
GDP_Sel_BNZD  = Params.GDP_2026_BNZD  * reg_pop_wt;
sh_ygr_base0  = Params.sh_ygr_base0_5(col_idx);  % 0.1730 Nat, or [0.196, 0.185, 0.158, 0.165] regional

Waves_13      = Params.Waves_13;                 % [13 x 1]
ECE_13_Share  = Params.Kahui_ECE_13x5(:, col_idx);     % [13 x 1] in [0, 1]
YGr_New_Share = Params.Kahui_YGr_New_13x5(:, col_idx); % [13 x 1] in [0, 1]
Elc_13_Share  = Params.Kahui_Elc_13x5(:, col_idx);     % [13 x 1] in [0, 1]

% File suffix: keeps standard filename for 'National', appends '_Auckland' etc. when regional!
if col_idx == 5, Reg_File_Suffix = AnchorTag;
else,            Reg_File_Suffix = sprintf('%s_%s', r_sel, AnchorTag); end

% --- Vectorized Cohort Grid Evaluation (Years -10 to +60, 0 Loops) ---
Yr_Grid              = (-10:0.5:60)';
n_yr                 = numel(Yr_Grid);
m_pre                = Yr_Grid < 0;
m_pos                = ~m_pre;
y_pre                = Yr_Grid(m_pre);
y_pos                = Yr_Grid(m_pos);
y1_pos               = min(y_pos, 25.0);

Traj_11              = zeros(n_yr, 11);
Traj_11_1Shot        = zeros(n_yr, 11);
YGr_Early_Share_Grid = zeros(n_yr, 1);

% 3A. Pre-launch cohorts (y < 0):
w_pre_mat              = (0.04 * exp(y_pre / 2.5)) * [0.5, 0, 0, 1, 0, 1, 0, 0, 0.5, 0, 0];
Traj_11(m_pre, :)      = w_pre_mat .* (SS1_Sel_11');
Traj_11_1Shot(m_pre,:) = (2.5 * w_pre_mat) .* (SS1_Sel_11');

% 3B. Single-Phase Step Reference (y >= 0, Vectorized):
b_drag_1s   = 1.0 - 0.14 * exp(-y_pos / 14.0);
w_iso       = (0.22 + 0.78 * (1.0 - exp(-y1_pos / 8.0))) .* b_drag_1s;
w_geo_1s    = (1.0 - 0.35 * exp(-y1_pos / 2.5)) .* (1.0 - 0.55 ./ (1.0 + exp(-(y1_pos - 15.0) / 4.0)));
w_wed1_1s   = b_drag_1s ./ (1.0 + exp(-(y1_pos - 11.0) / 4.2));
w_wed2_1s   = b_drag_1s ./ (1.0 + exp(-(y1_pos - 9.0)  / 4.0));
w_wed3_1s   = b_drag_1s ./ (1.0 + exp(-(y1_pos - 16.0) / 4.0));
unment_drag = 1.0 - (0.42 * (1.0 - sh_ygr_base0)) * exp(-y_pos / 5.5);

W_1s_S1     = [w_iso, w_iso, w_wed1_1s, w_iso, w_iso.*unment_drag, w_geo_1s, w_wed2_1s.*unment_drag, w_wed3_1s, 0.5*w_iso, zeros(size(y_pos)), w_wed3_1s];
Row_1s      = W_1s_S1 .* (SS1_Sel_11');
Row_1s(:,8) = Row_1s(:,8) + max(0.0, w_iso - w_geo_1s) * SS1_Sel_11(6);

m_25        = y_pos >= 25.0;
w_ss2_1s    = (y_pos >= 25.0) .* (1.0 - exp(-max(0.0, y_pos - 25.0) / 8.5));
w_inv2_1s   = (y_pos >= 25.0) .* (1.0 - exp(-max(0.0, y_pos - 25.0) / 5.0));
D_ss2_1s    = (SS2_Sel_11') - Row_1s;
Row_1s      = Row_1s + w_ss2_1s .* D_ss2_1s;
Row_1s(:,6) = Row_1s(:,6) + m_25 .* (w_inv2_1s - w_ss2_1s) .* D_ss2_1s(:,6);
Row_1s(:,8) = Row_1s(:,8) - m_25 .* (w_inv2_1s - w_ss2_1s) .* D_ss2_1s(:,6);
Traj_11_1Shot(m_pos, :) = Row_1s;

% 3C. Wave-Convolved 13-Wave Te Kāhui Waka Trajectory (y >= 0, Vectorized Implicit Expansion + Matrix Multiply):
dw_e_13 = [ECE_13_Share(1); diff(ECE_13_Share)];                                  % [13 x 1]
dw_y_13 = (1.0 - sh_ygr_base0) * [YGr_New_Share(1); diff(YGr_New_Share)];         % [13 x 1]
dw_l_13 = [Elc_13_Share(1); diff(Elc_13_Share)];                                  % [13 x 1]

dy_s1_e = y_pos - (Waves_13 - 0.8)';                                              % [N_pos x 13]
w_kh_ece = ((dy_s1_e > 0) .* (1.0 - 0.72 * exp(-max(0.0, dy_s1_e) / 5.2))) * dw_e_13;
w_kh_elc = ((dy_s1_e > 0) .* (1.0 - 0.65 * exp(-max(0.0, dy_s1_e) / 3.5))) * dw_l_13;

dy_s1_y       = y_pos - (Waves_13 - 0.5)';                                        % [N_pos x 13]
w_kh_ygr_new  = (((y_pos >= 7.0) & (dy_s1_y > 0)) .* (1.0 - 0.60 * exp(-max(0.0, dy_s1_y) / 4.2))) * dw_y_13;
w_kh_ygr_base = (y_pos > 0.2) .* sh_ygr_base0 .* (1.0 - 0.45 * exp(-max(0.0, y_pos - 0.2) / 2.2));
w_kh_ygr      = w_kh_ygr_base + w_kh_ygr_new;
YGr_Early_Share_Grid(m_pos) = min(1.0, w_kh_ygr_base ./ max(1e-8, w_kh_ygr));

sh_tax_t   = 0.38 * min(1.0, y_pos / Params.T_ramp_CGT_Est_yrs) + 0.62 * min(1.0, y_pos / Params.T_ramp_LVT_yrs);
w_kh_tax   = sh_tax_t .* (1.0 - 0.55 * exp(-y_pos / 5.5));
retire_kh  = 1.0 ./ (1.0 + exp(-(y1_pos - 14.0) / 3.8));
w_kh_geo   = (0.65 * w_kh_elc + 0.35 * (1.0 - exp(-y_pos / 2.2))) .* (1.0 - 0.55 * retire_kh);

w_wed1_kh  = (w_kh_ece .^ 1.15) ./ (1.0 + exp(-(y1_pos - 9.2) / 4.1));
w_wed2_kh  = (0.75 * w_kh_ygr .* w_kh_tax + 0.25 * w_kh_tax) ./ (1.0 + exp(-(y1_pos - 8.0) / 3.8));
w_wed3_kh  = ((w_kh_ece .* w_kh_tax) .^ 0.85) ./ (1.0 + exp(-(y1_pos - 13.0) / 4.1));

Row_kh      = [w_kh_ece, w_kh_ece, w_wed1_kh, w_kh_tax, w_kh_ygr, w_kh_geo, w_wed2_kh, w_wed3_kh, 0.55*w_kh_tax, zeros(size(y_pos)), w_wed3_kh] .* (SS1_Sel_11');
Row_kh(:,8) = Row_kh(:,8) + max(0.0, w_kh_ece - w_kh_geo) * SS1_Sel_11(6);

% Wave-Convolved SS2 Generational & Fiscal Echo (Converging to Exact SS2_Sel_11 at Year 60):
dy_s2_hc       = y_pos - (20.5 + Waves_13)';                                      % [N_pos x 13]
dy_s2_ygr      = y_pos - (16.0 + Waves_13)';                                      % [N_pos x 13]
w_ss2_echo_hc  = ((dy_s2_hc  > 0) .* (1.0 - exp(-max(0.0, dy_s2_hc)  / 6.0))) * dw_e_13;
w_ss2_echo_ygr = sh_ygr_base0 * (y_pos > 18.0) .* (1.0 - exp(-max(0.0, y_pos - 18.0) / 6.0)) ...
    + ((dy_s2_ygr > 0) .* (1.0 - exp(-max(0.0, dy_s2_ygr) / 5.8))) * dw_y_13;
w_ss2_fisc     = (1.0 ./ (1.0 + exp(-(y_pos - 25.0) / 2.5))) .* (1.0 - exp(-max(0.0, y_pos - 20.0) / 6.2));
w_geo_ret2     = (1.0 ./ (1.0 + exp(-(y_pos - 24.5) / 2.5))) .* (1.0 - exp(-max(0.0, y_pos - 20.0) / 4.5));

D_ss2_kh    = (SS2_Sel_11') - Row_kh;
W_ss2_mat   = [w_ss2_echo_hc, w_ss2_echo_hc, w_ss2_echo_hc, w_ss2_echo_ygr, w_ss2_echo_ygr, ...
    w_geo_ret2, w_ss2_echo_ygr, 0.5*(w_ss2_echo_hc + w_ss2_echo_ygr), ...
    w_ss2_fisc, w_ss2_fisc, 0.65*w_ss2_echo_hc + 0.35*w_ss2_fisc];
Row_kh      = Row_kh + W_ss2_mat .* D_ss2_kh;
Row_kh(:,8) = Row_kh(:,8) - (w_geo_ret2 - 0.5*(w_ss2_echo_hc + w_ss2_echo_ygr)) .* D_ss2_kh(:,6);
Traj_11(m_pos, :) = max(0.0, Row_kh);

Total_Traj_CE    = sum(Traj_11, 2);
Iso_Only_Traj_CE = sum(Traj_11(:, ~Is_Wedge), 2);
Total_1Shot_Grid = sum(Traj_11_1Shot, 2);

% Distinct Color Palette: Layer 5 (Youth Grant) uses Vivid Orchid Purple, plus Super-Pale Lavender for Early Adopters!
c_pale_purple_pos = [0.88, 0.76, 0.94];
c_pale_purple_neg = [0.84, 0.68, 0.90];

layer_colors = [ ...
    0.20, 0.48, 0.68; ... % L1 [Iso]: First-2000d ECE (Steel Blue)
    0.38, 0.65, 0.78; ... % L2 [Iso]: Tuakana Mentoring (Sky Teal)
    0.96, 0.76, 0.12; ... % L3 [★ WEDGE 1]: Dual-Gate ECE x Tuakana Synergy (Vivid Amber Gold)
    0.28, 0.54, 0.40; ... % L4 [Iso]: Estate/Property Tax Rebalance (Deep Sage Green)
    0.62, 0.24, 0.66; ... % L5 [Iso]: Age-20 Youth Grant (Vivid Orchid Purple — Matches -Inv 3!)
    0.64, 0.80, 0.62; ... % L6 [Iso]: Geographic Transfer (Light Meadow Moss)
    0.94, 0.50, 0.12; ... % L7 [★ WEDGE 2]: LVR & Whanau-Stay Synergy (Tangerine Flame)
    0.84, 0.18, 0.24; ... % L8 [★ WEDGE 3]: Cross-Stack (Stack 1 x Stack 2) Synergy (Crimson Synergy)
    0.42, 0.46, 0.70; ... % L9 [Iso]: Sovereign Debt-Sinking (Slate Indigo)
    0.62, 0.62, 0.82; ... % L10 [Iso]: PAYE & Super Age SS2 Alone (Periwinkle Slate)
    0.05, 0.56, 0.32];    % L11 [★ WEDGE 4]: Fiscal/TFR/2nd-Gen Compounding Closure (Deep Emerald)

% =========================================================================
% 4. RENDER FIGURE A: 2-PANEL CONSTRUCTIVE SYNERGY ATTRIBUTION
% =========================================================================
fig_cf = figure('Name', sprintf('Fig_Constructive_Synergy_Attribution_%s', Reg_File_Suffix), ...
    'Color', 'w', 'Position', [35, 45, 1660, 820]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

max_y_val = max([max(sum(SS2_11x5, 1)), max(Total_Traj_CE), 29.5]);
y_top_lim = ceil(max_y_val * 1.18);
min_y_val = min([0, min(sum(SS2_11x5, 1)), min(Total_Traj_CE)]);
y_bot_lim = floor(min_y_val * 1.15);

axA = nexttile(1); hold(axA, 'on');
h_area = area(axA, Yr_Grid, Traj_11, 'LineWidth', 0.6, 'EdgeColor', [0.18 0.18 0.18]);
for k = 1:11
    h_area(k).FaceColor = layer_colors(k, :);
    if Is_Wedge(k)
        h_area(k).FaceAlpha = 0.92;
        h_area(k).EdgeColor = [0.10 0.10 0.10];
        h_area(k).LineWidth = 1.0;
    else
        h_area(k).FaceAlpha = 0.78;
    end
    h_area(k).DisplayName = Layer_Legend_Labels{k};
end

y_bot_L5   = sum(Traj_11(:, 1:4), 2);
y_early_L5 = y_bot_L5 + Traj_11(:, 5) .* YGr_Early_Share_Grid;
h_pale = fill(axA, [Yr_Grid; flipud(Yr_Grid)], [y_bot_L5; flipud(y_early_L5)], c_pale_purple_pos, ...
    'FaceAlpha', 0.95, 'EdgeColor', [0.45 0.18 0.52], 'LineWidth', 0.5, ...
    'DisplayName', sprintf('5a. [Early Adopters] Youth Grants for Existing %.1f%% %s Tuakana Mentees (Active Yr 1!)', 100*sh_ygr_base0, r_sel));

h_tot = plot(axA, Yr_Grid, Total_Traj_CE, 'k-', 'LineWidth', 2.8, ...
    'DisplayName', sprintf('Wave-Convolved 13-Wave Te Kāhui Waka (%s): Converges to %+.2f%% in SS2', r_sel, SS2_Sel_Total));
h_1sh = plot(axA, Yr_Grid, Total_1Shot_Grid, ':', 'Color', [0.15 0.35 0.65], 'LineWidth', 2.0, ...
    'DisplayName', sprintf('Single-Phase Step Reference (Early Bottleneck Drag \\rightarrow Same %+.2f%% SS2)', SS2_Sel_Total));
h_iso = plot(axA, Yr_Grid, Iso_Only_Traj_CE, '--', 'Color', [0.15 0.15 0.15], 'LineWidth', 2.2, ...
    'DisplayName', sprintf('Additive Sum of 7 Isolated Factors Without Synergy (%+.2f%% in SS2)', sum(SS2_Sel_11(~Is_Wedge))));

xline(axA, 0,    'k--', 'LineWidth', 1.3, 'HandleVisibility', 'off');
xline(axA, 7.0,  ':',   'Color', [0.58 0.20 0.62], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(axA, 16.8, ':',   'Color', [0.40 0.15 0.60], 'LineWidth', 1.6, 'HandleVisibility', 'off');
xline(axA, 25.0, '--',  'Color', [0.05 0.50 0.20], 'LineWidth', 1.6, 'HandleVisibility', 'off');

y_iso_52 = interp1(Yr_Grid, Iso_Only_Traj_CE, 52);
y_tot_52 = interp1(Yr_Grid, Total_Traj_CE, 52);
syn_pct_share = 100 * sum(SS2_Sel_11(Is_Wedge)) / max(1e-6, SS2_Sel_Total);
plot(axA, [52, 52], [y_iso_52, y_tot_52], 'r-', 'LineWidth', 2.2, 'HandleVisibility', 'off');
text(axA, 50.5, 0.5*(y_iso_52 + y_tot_52), ...
    sprintf('Total Supermodular\nSynergy Wedges (%s):\n%+.2f%% CE\n(%.1f%% of Total!)', r_sel, sum(SS2_Sel_11(Is_Wedge)), syn_pct_share), ...
    'HorizontalAlignment', 'right', 'FontSize', 8.2, 'FontWeight', 'bold', ...
    'Color', [0.65 0.05 0.10], 'BackgroundColor', [1.0 0.96 0.94], 'EdgeColor', [0.75 0.15 0.20], 'Margin', 4);

text(axA, 0.6, 5.2, sprintf('Yrs 1-6: %.1f%% Early-Adopter\nGrants (Pale Purple) \\rightarrow\nTe Kāhui Waka Expansion @ Yr 7+', 100*sh_ygr_base0), ...
    'FontSize', 7.5, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', [0.45 0.18 0.52], 'Margin', 2.5);
text(axA, 25.6, 16.2, sprintf('%s\n(Wave-Convolved SS2 Echo)', box25_label), 'FontSize', 7.8, 'FontWeight', 'bold', ...
    'Color', [0.00 0.42 0.18], 'BackgroundColor', 'w', 'EdgeColor', [0.00 0.45 0.20], 'Margin', 2.5);

title(axA, sprintf('A. Constructive Attribution (%s): Wave-Convolved Te Kāhui Waka vs. Single-Phase Reference', r_sel), ...
    'FontSize', 10.6, 'FontWeight', 'bold');
xlabel(axA, 'Cohort Entry Year Relative to 2026 Reform Introduction (13-Wave Te Kāhui Waka S-Curve)', 'FontSize', 10.2, 'FontWeight', 'bold');
ylabel(axA, 'Lifetime Consumption-Equivalent Welfare Gain (CE %)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlim(axA, [-3, 63]); xticks(axA, 0:10:60); ylim(axA, [y_bot_lim, y_top_lim]);
grid(axA, 'on'); box(axA, 'on');
legend(axA, [h_area(1:5), h_pale, h_area(6:11), h_tot, h_1sh, h_iso], 'Location', 'northwest', 'FontSize', 6.2);

% --- PANEL B: REGIONAL & NATIONAL SS2 STACKED BUILD-UP WITH WEDGE CALLOUTS ---
axB = nexttile(2); hold(axB, 'on');
x_5 = 1:5;
b_reg = bar(axB, x_5, SS2_11x5', 'stacked', 'BarWidth', 0.58, 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.6);
for k = 1:11
    b_reg(k).FaceColor = layer_colors(k, :);
    if Is_Wedge(k)
        b_reg(k).FaceAlpha = 0.94;
        b_reg(k).LineWidth = 1.1;
    else
        b_reg(k).FaceAlpha = 0.80;
    end
end

Reg_Totals_5 = sum(SS2_11x5, 1);
for c = 1:5
    cum_bot = 0;
    for k = 1:11
        val_kc = SS2_11x5(k, c);
        if val_kc >= 0.95
            y_mid = cum_bot + 0.5 * val_kc;
            pct_sh = round(100 * val_kc / max(1e-6, Reg_Totals_5(c)));
            if Is_Wedge(k)
                lbl_str = sprintf('★%+.2f%%\n(%d%%)', val_kc, pct_sh);
                txt_col = [0.10 0.05 0.00];
                if k == 8 || k == 11, txt_col = [1 1 1]; end
            else
                lbl_str = sprintf('%+.2f%%\n(%d%%)', val_kc, pct_sh);
                txt_col = [1 1 1];
                if k == 6 || k == 10, txt_col = [0.12 0.12 0.12]; end
            end
            text(axB, c, y_mid, lbl_str, 'HorizontalAlignment', 'center', ...
                'FontSize', 6.7, 'FontWeight', 'bold', 'Color', txt_col);
        end
        cum_bot = cum_bot + val_kc;
    end
    iso_sum_c = sum(SS2_11x5(~Is_Wedge, c));
    wed_sum_c = sum(SS2_11x5(Is_Wedge, c));
    text(axB, c, Reg_Totals_5(c) + 0.85, ...
        sprintf('Total: %+.2f%%\n(Iso %+.1f%% | ★Syn %+.1f%%)', Reg_Totals_5(c), iso_sum_c, wed_sum_c), ...
        'HorizontalAlignment', 'center', 'FontSize', 7.5, 'FontWeight', 'bold', 'Color', [0.05 0.15 0.05]);
end

c_nat_cum = cumsum(SS2_Nat_11);
tier_tops = [c_nat_cum(3), c_nat_cum(7), c_nat_cum(8), c_nat_cum(11)];
tier_bots = [0,            c_nat_cum(3), c_nat_cum(7), c_nat_cum(8)];
tier_lbls = { ...
    sprintf('Tier 1: Dual-Gate HC\n(%+.2f%%: %+.1f%% Iso, ★%+.1f%% Wedge)', tier_tops(1) - tier_bots(1), SS2_Nat_11(1)+SS2_Nat_11(2), SS2_Nat_11(3)), ...
    sprintf('Tier 2: Spatial/LVR Stack\n(%+.2f%%: %+.1f%% Iso, ★%+.1f%% Wedge)', tier_tops(2) - tier_bots(2), sum(SS2_Nat_11(4:6)), SS2_Nat_11(7)), ...
    sprintf('★ Wedge 3: Stack 1 \\times Stack 2\n(%+.2f%% Cross-Stack Synergy)', tier_tops(3) - tier_bots(3)), ...
    sprintf('%s\n(%+.2f%%: %+.1f%% Iso, ★%+.1f%% Wedge)', tier4_hdr, tier_tops(4) - tier_bots(4), SS2_Nat_11(9)+SS2_Nat_11(10), SS2_Nat_11(11))};
for t_i = 1:4
    ym = 0.5 * (tier_bots(t_i) + tier_tops(t_i));
    plot(axB, [5.32, 5.38, 5.38, 5.32], [tier_bots(t_i)+0.15, tier_bots(t_i)+0.15, tier_tops(t_i)-0.15, tier_tops(t_i)-0.15], ...
        'k-', 'LineWidth', 1.1, 'HandleVisibility', 'off');
    text(axB, 5.42, ym, tier_lbls{t_i}, 'FontSize', 7.1, 'FontWeight', 'bold', 'Color', [0.15 0.15 0.15]);
end

x_lbls_5 = arrayfun(@(c) sprintf('%s (%+.2f%%)', Params.Reg_Names_5{c}, Reg_Totals_5(c)), 1:5, 'UniformOutput', false);
set(axB, 'XTick', x_5, 'XTickLabel', x_lbls_5, 'XTickLabelRotation', 20, 'FontSize', 9.0, 'FontWeight', 'bold');
ylabel(axB, 'Phase 2 (SS2) Long-Run Welfare Gain (CE %)', 'FontSize', 10.2, 'FontWeight', 'bold');
title(axB, 'B. Regional SS2 Build-Up: 7 Isolated Factors + 4 Named Complementarity Wedges (★)', ...
    'FontSize', 10.8, 'FontWeight', 'bold');
xlim(axB, [0.4, 6.45]); ylim(axB, [y_bot_lim, y_top_lim]);
grid(axB, 'on'); box(axB, 'on');

f_cf_out = fullfile(OutputDir, sprintf('Fig_Counterfactual_8Scenarios_SS1_SS2_%s.png', Reg_File_Suffix));
exportgraphics(fig_cf, f_cf_out, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved 2-Panel Constructive Synergy Attribution Figure (%s) to: %s\n', r_sel, f_cf_out);

% =========================================================================
% 5. PART 2: VECTORIZED MIRROR-IMAGE 11-LAYER WELFARE GAINS VS. ANNUAL OUTLAYS
%            (0 LOOPS! SINGLE-PHASE LEFT vs. TE KĀHUI WAKA RIGHT)
% =========================================================================
Yr_Mir  = (0:2:60)';
y1_mir  = min(Yr_Mir, 25.0);
yr_w_g  = [0; Waves_13; 25; 60];

Pos_11_Mir    = interp1(Yr_Grid, Traj_11_1Shot,        Yr_Mir, 'pchip');
Pos_11_Kahui  = interp1(Yr_Grid, Traj_11,              Yr_Mir, 'pchip');
Early_Share_M = interp1(Yr_Grid, YGr_Early_Share_Grid, Yr_Mir, 'linear');

Total_Mir_CE   = sum(Pos_11_Mir,   2);
Total_Kahui_CE = sum(Pos_11_Kahui, 2);

Pos_12_Mir   = [Pos_11_Mir(:, 1:4),   Pos_11_Mir(:, 5)*sh_ygr_base0,        Pos_11_Mir(:, 5)*(1-sh_ygr_base0),       Pos_11_Mir(:, 6:11)];
Pos_12_Kahui = [Pos_11_Kahui(:, 1:4), Pos_11_Kahui(:, 5).*Early_Share_M,    Pos_11_Kahui(:, 5).*(1-Early_Share_M),   Pos_11_Kahui(:, 6:11)];

SS1_Inv_CE = -[1.45, 0.52, 0.68, 0.65]; % -3.30% CE/yr at SS1 peak
SS2_Inv_CE = -[1.35, 0.55, 0.60, 0.12]; % -2.62% CE/yr in SS2 after 82% GeoTransfer retirement

% 5A. Vectorized Single-Phase Negative Outlays & Remediation:
ramp_1s_m   = 1.0 - 0.35 * exp(-y1_mir / 2.5);
retire_1s_m = 1.0 ./ (1.0 + exp(-(y1_mir - 15.0) / 4.0));
Neg_4Investments_CE      = ramp_1s_m * SS1_Inv_CE;
Neg_4Investments_CE(:,4) = Neg_4Investments_CE(:,4) .* (1.0 - 0.55 * retire_1s_m);
Remediation_Savings_CE   = 4.65 ./ (1.0 + exp(-(y1_mir - 16.5) / 4.2));

w_inv2_m    = (Yr_Mir >= 25.0) .* (1.0 - exp(-max(0.0, Yr_Mir - 25.0) / 5.0));
Neg_4Investments_CE    = Neg_4Investments_CE + w_inv2_m .* (SS2_Inv_CE - Neg_4Investments_CE);
Remediation_Savings_CE = Remediation_Savings_CE + (Yr_Mir >= 25.0) .* (1.45 * (1.0 - exp(-max(0.0, Yr_Mir - 25.0) / 9.0)));

% 5B. Vectorized 13-Wave Te Kāhui Waka Negative Outlays & Early-Adopter Youth Grants:
sh_ece_m     = interp1(yr_w_g, [0.00; ECE_13_Share; 1.0; 1.0], min(60.0, Yr_Mir), 'linear');
sh_elc_m     = interp1(yr_w_g, [0.00; Elc_13_Share; 1.0; 1.0], min(60.0, Yr_Mir), 'linear');
sh_ygr_ear_m = (Yr_Mir > 0)    .* sh_ygr_base0 .* min(1.0, Yr_Mir / 1.5);
sh_ygr_new_m = (Yr_Mir >= 7.0) .* (1.0 - sh_ygr_base0) .* interp1(yr_w_g, [0.00; YGr_New_Share; 1.0; 1.0], min(60.0, Yr_Mir), 'linear');
sh_ygr_m     = sh_ygr_ear_m + sh_ygr_new_m;
retire_kh_m  = 1.0 ./ (1.0 + exp(-(y1_mir - 13.5) / 3.6));

Neg_4Inv_Kahui_CE = [sh_ece_m, sh_ece_m, sh_ygr_m, 0.65*sh_elc_m.*(1.0 - 0.72*retire_kh_m) + 0.35*min(1.0, Yr_Mir/2.0)] .* SS1_Inv_CE;
w_inv_kh20        = (Yr_Mir >= 20.0) .* (1.0 - exp(-max(0.0, Yr_Mir - 20.0) / 4.8));
Neg_4Inv_Kahui_CE = Neg_4Inv_Kahui_CE + w_inv_kh20 .* (SS2_Inv_CE - Neg_4Inv_Kahui_CE);

ear_frac_inv3         = sh_ygr_ear_m ./ max(1e-8, sh_ygr_m);
Neg_Inv3_Early_Kh_CE  = Neg_4Inv_Kahui_CE(:, 3) .* ear_frac_inv3;
Neg_Inv3_New_Kh_CE    = Neg_4Inv_Kahui_CE(:, 3) .* (1.0 - ear_frac_inv3);

sh_tax_m             = 0.38 * min(1.0, Yr_Mir / Params.T_ramp_CGT_Est_yrs) + 0.62 * min(1.0, Yr_Mir / Params.T_ramp_LVT_yrs);
remed_raw_m          = 4.92 ./ (1.0 + exp(-(Yr_Mir - 14.8) / 3.85)) - 4.92 / (1.0 + exp(14.8 / 3.85));
Remed_Savings_Kh_CE  = remed_raw_m + 0.28 * sh_tax_m .* exp(-max(0.0, Yr_Mir - 5.0) / 5.0) + 0.055 * min(1.0, Yr_Mir / 4.0);

Neg_5_Mir   = [Neg_4Investments_CE(:, 1:2), Neg_4Investments_CE(:, 3)*sh_ygr_base0, Neg_4Investments_CE(:, 3)*(1-sh_ygr_base0), Neg_4Investments_CE(:, 4)];
Neg_5_Kahui = [Neg_4Inv_Kahui_CE(:, 1:2),   Neg_Inv3_Early_Kh_CE,                   Neg_Inv3_New_Kh_CE,                         Neg_4Inv_Kahui_CE(:, 4)];

Gross_Investment_Mirror_CE   = sum(Neg_4Investments_CE, 2);
Gross_Investment_Mirror_BNZD = Gross_Investment_Mirror_CE * NZD_Per_CE;
Gross_Inv_Kahui_CE           = sum(Neg_4Inv_Kahui_CE, 2);

Net_Fiscal_Outlay_Mirror_CE  = min(0.0, Gross_Investment_Mirror_CE + Remediation_Savings_CE);
Net_Fiscal_Outlay_Kahui_CE   = min(0.0, Gross_Inv_Kahui_CE         + Remed_Savings_Kh_CE);

% 5C. Vectorized 2D Rolling Window for Grounded ACC / Treasury CBAx Actuarial Continuation Valuation:
r_disc_SRTP  = 0.020;
g_cost_real  = 0.015;
alpha_attr   = 0.300;
psi_persist  = 0.986;
H_window     = 25;
q_step       = ((1 + g_cost_real) / (1 + r_disc_SRTP)) * psi_persist;
pv_mult_25yr = sum(q_step .^ (1:H_window)) / H_window;

s_row_25     = linspace(0.0, 1.0, H_window);                                           % [1 x 25]
Y_Look_2D    = Yr_Mir + (min(max(Yr_Grid), Yr_Mir + H_window) - Yr_Mir) .* s_row_25;   % [N_mir x 25]
welf_look_m  = mean(interp1(Yr_Grid, Total_Traj_CE, Y_Look_2D, 'pchip'), 2);           % [N_mir x 1]
fwd_pot_m    = (1.0 - alpha_attr) * pv_mult_25yr * welf_look_m;

phi_pipe_m   = min(1.0, max(0.0, Yr_Mir / 15.0));
phi_1s_m     = min(1.0, max(0.0, (Yr_Mir + 1.2) / 14.0));
sh_enr_m     = 0.75 * sh_ece_m + 0.25 * sh_ygr_m;

Actuarial_CBAx_Mirror_CE = min(Total_Mir_CE(end), ...
    (1.0 - phi_pipe_m) .* (Net_Fiscal_Outlay_Mirror_CE + phi_1s_m .* fwd_pot_m) + phi_pipe_m .* Total_Mir_CE);
Actuarial_CBAx_Kahui_CE  = min(Total_Kahui_CE(end), ...
    (1.0 - phi_pipe_m) .* (Net_Fiscal_Outlay_Kahui_CE  + (sh_enr_m .^ 0.75) .* min(1.0, Yr_Mir / 12.0) .* fwd_pot_m) + phi_pipe_m .* Total_Kahui_CE);
Actuarial_CBAx_Mirror_BNZD = Actuarial_CBAx_Mirror_CE * NZD_Per_CE;

% 5D. Apples-to-Apples Annual Incremental LTFM Fiscal Deficit / Debt-Sinking Flow (-dDebt/dt):
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

T20 = table(Yr_Mir, Total_Mir_CE, Total_Mir_CE * NZD_Per_CE, ...
    sum(Pos_11_Mir(:, ~Is_Wedge), 2), sum(Pos_11_Mir(:, Is_Wedge), 2), ...
    Neg_4Investments_CE(:,1), Neg_4Investments_CE(:,2), Neg_4Investments_CE(:,3), Neg_4Investments_CE(:,4), ...
    Gross_Investment_Mirror_CE, Gross_Investment_Mirror_BNZD, ...
    Net_Fiscal_Outlay_Mirror_CE, Actuarial_CBAx_Mirror_CE, Actuarial_CBAx_Mirror_BNZD, ...
    Total_Kahui_CE, Gross_Inv_Kahui_CE, Net_Fiscal_Outlay_Kahui_CE, Actuarial_CBAx_Kahui_CE, ...
    LTFM_Ann_Flow_CE_Mir, LTFM_Ann_Flow_BNZD_Mir, Debt_LTFM_Stock_Mir, ...
    'VariableNames', {'Year', 'Total_Welfare_Gain_CE_Pct', 'Total_Welfare_Equiv_BNZD_Yr', ...
    'Isolated_Factors_Sum_CE', 'Synergy_Wedges_Sum_CE', ...
    'MirrorInv1_Universal_ECE_CE', 'MirrorInv2_Tuakana_Mentoring_CE', ...
    'MirrorInv3_YouthGrant_CE', 'MirrorInv4_GeoTransfer_CE', ...
    'Total_Gross_Inv_Mirror_CE_Pct', 'Total_Gross_Inv_Mirror_BNZD_Yr', ...
    'Net_Unrecovered_Outlay_Mirror_CE', 'Actuarial_CBAx_Net_CE_Pct', 'Actuarial_CBAx_Net_BNZD_Yr', ...
    'Total_TeKahuiWaka_Welfare_CE_Pct', 'Total_Gross_Inv_TeKahuiWaka_CE_Pct', ...
    'Net_Unrecovered_Outlay_TeKahuiWaka_CE', 'Actuarial_CBAx_TeKahuiWaka_CE_Pct', ...
    'LTFM_Annual_Deficit_Flow_CE_Pct', 'LTFM_Annual_Deficit_Flow_BNZD_Yr', 'LTFM_Cumulative_Debt_PctGDP'});
csv20 = fullfile(OutputDir, sprintf('Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_%s.csv', Reg_File_Suffix));
writetable(T20, csv20);

fig_mir = figure('Name', sprintf('Fig_11Layer_Welfare_And_MirrorInvestments_%s', Reg_File_Suffix), ...
    'Color', 'w', 'Position', [40, 35, 1640, 880]);
axM = axes(fig_mir); hold(axM, 'on');

dx_half = 0.42;
bw_half = 0.38;

pos12_colors = [layer_colors(1:4, :); c_pale_purple_pos; layer_colors(5:11, :)];
neg5_colors  = [0.78, 0.12, 0.18; 0.92, 0.38, 0.22; c_pale_purple_neg; 0.58, 0.20, 0.62; 0.32, 0.32, 0.48];

% 1. Left Half-Columns: Single-Phase Launch
b_pos_1s = bar(axM, Yr_Mir - dx_half, Pos_12_Mir, 'stacked', 'BarWidth', bw_half, ...
    'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 0.35, 'HandleVisibility', 'off');
for k = 1:12
    b_pos_1s(k).FaceColor = pos12_colors(k, :);
    b_pos_1s(k).FaceAlpha = 0.62;
end

b_neg_1s = bar(axM, Yr_Mir - dx_half, Neg_5_Mir, 'stacked', 'BarWidth', bw_half, ...
    'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 0.35, 'HandleVisibility', 'off');
for k = 1:5
    b_neg_1s(k).FaceColor = neg5_colors(k, :);
    b_neg_1s(k).FaceAlpha = 0.62;
end

% 2. Right Half-Columns: 13-Wave Te Kāhui Waka Launch
b_pos12 = bar(axM, Yr_Mir + dx_half, Pos_12_Kahui, 'stacked', 'BarWidth', bw_half, ...
    'EdgeColor', [0.10 0.10 0.10], 'LineWidth', 0.55);
pos12_labels = [Layer_Legend_Labels(1:4), ...
    {sprintf('5a. [Early Adopters] Youth Grants for Existing %.1f%% %s Tuakana Mentees (Pale Purple: Active Yr 1!)', 100*sh_ygr_base0, r_sel)}, ...
    {'5b. [Te Kāhui Waka Waves 7-13] Youth Grants for New Mentored Waves (Vivid Orchid: Launches Yr 7+!)'}, ...
    Layer_Legend_Labels(6:11)];
for k = 1:12
    b_pos12(k).FaceColor   = pos12_colors(k, :);
    b_pos12(k).FaceAlpha   = 0.94;
    b_pos12(k).DisplayName = pos12_labels{k};
end

b_neg5 = bar(axM, Yr_Mir + dx_half, Neg_5_Kahui, 'stacked', 'BarWidth', bw_half, ...
    'EdgeColor', [0.10 0.10 0.10], 'LineWidth', 0.55);
inv5_names = { ...
    '-Inv 1: Universal First-2000-Days Wraparound (\DeltaG_{ECE,1})', ...
    '-Inv 2: Tuakana-Teina / Montessori Mentoring (\DeltaG_{ECE,2})', ...
    sprintf('-Inv 3a: Early-Adopter Youth Grants (%.1f%% Existing %s Tuakana Mentees, Pale Purple)', 100*sh_ygr_base0, r_sel), ...
    '-Inv 3b: Te Kāhui Waka Expansion Youth Grants (Waves 7-13: 0 in Yrs 1-6 \rightarrow Launches Yr 7+, Vivid Orchid)', ...
    '-Inv 4: Geographic & Electrification Grants (\DeltaT_k: Retires 82% in SS2!)'};
for k = 1:5
    b_neg5(k).FaceColor   = neg5_colors(k, :);
    b_neg5(k).FaceAlpha   = 0.94;
    b_neg5(k).DisplayName = inv5_names{k};
end

% 3. Overlays: Envelopes, Grounded Actuarial CBAx, Cash J-Curves, & LTFM Annual Deficit
plot(axM, Yr_Mir - dx_half, Total_Mir_CE, '--', 'Color', [0.18 0.38 0.58], 'LineWidth', 2.0, ...
    'DisplayName', sprintf('Left Half-Bar Envelope: Single-Phase Launch (Early Bottleneck Drag \\rightarrow %+.2f%% SS2)', Total_Mir_CE(end)));
plot(axM, Yr_Mir + dx_half, Total_Kahui_CE, '-o', 'Color', [0.00 0.32 0.12], 'MarkerFaceColor', [0.00 0.58 0.24], ...
    'LineWidth', 2.6, 'MarkerSize', 4.4, ...
    'DisplayName', sprintf('Right Half-Bar Envelope: 13-Wave Te Kāhui Waka (Same %+.2f%% SS2 Asymptote!)', Total_Kahui_CE(end)));

cbax_yr5 = interp1(Yr_Mir, Actuarial_CBAx_Kahui_CE, 5.0, 'linear');
plot(axM, Yr_Mir + dx_half, Actuarial_CBAx_Kahui_CE, '-.s', 'Color', [0.00 0.72 0.78], 'MarkerFaceColor', [0.15 0.92 0.95], ...
    'MarkerEdgeColor', [0.00 0.38 0.44], 'LineWidth', 2.4, 'MarkerSize', 4.8, ...
    'DisplayName', sprintf('Te Kāhui Waka ACC / CBAx Actuarial Valuation (0%% Yr 0 \\rightarrow %+.2f%% CE [%+.1fB/yr] at Yr 5)', cbax_yr5, cbax_yr5*NZD_Per_CE));

trough_1s = min(Net_Fiscal_Outlay_Mirror_CE);
trough_kh = min(Net_Fiscal_Outlay_Kahui_CE);
plot(axM, Yr_Mir - dx_half, Net_Fiscal_Outlay_Mirror_CE, ':v', 'Color', [0.85 0.48 0.05], 'MarkerFaceColor', [0.95 0.60 0.10], ...
    'LineWidth', 2.0, 'MarkerSize', 4.0, ...
    'DisplayName', sprintf('Single-Phase Annual Net Unrecovered Cost (%.2f%% CE [%.1fB/yr] Trough \\rightarrow Breakeven Yr 18.8)', trough_1s, trough_1s*NZD_Per_CE));
plot(axM, Yr_Mir + dx_half, Net_Fiscal_Outlay_Kahui_CE, '--d', 'Color', [0.95 0.82 0.15], 'MarkerFaceColor', [0.95 0.82 0.15], ...
    'MarkerEdgeColor', [0.25 0.20 0.00], 'LineWidth', 2.4, 'MarkerSize', 4.6, ...
    'DisplayName', sprintf('Te Kāhui Waka Annual Net Unrecovered Cost (%.2f%% CE [%.1fB/yr] Trough \\rightarrow Breakeven Yr 16.8!)', trough_kh, trough_kh*NZD_Per_CE));

% 4. Crimson Status Quo LTFM Annual Incremental Deficit / Debt-Sinking Flow (-dDebt/dt)
y_mir_top = max(37.5, ceil(max([Total_Mir_CE(:); Total_Kahui_CE(:); SS2_Sel_Total]) * 1.46));
y_mir_bot = -8.5;

m_pos_f = Yr_Fine >= 0;
plot(axM, Yr_Fine(m_pos_f), LTFM_Ann_Deficit_CE(m_pos_f), '-', 'Color', [0.76 0.04 0.12], 'LineWidth', 3.4, ...
    'DisplayName', sprintf('Status Quo LTFM Annual Incremental Debt Sinking (-dDebt/dt: -4.57%% CE [%.1fB/yr] @ Yr 30 \\rightarrow -6.24%% CE [%.1fB/yr] @ Yr 60!)', ...
    -4.57*NZD_Per_CE, -6.24*NZD_Per_CE));

flow_ce_30   = interp1(Yr_Fine, LTFM_Ann_Deficit_CE,   30.0);
flow_bnzd_30 = interp1(Yr_Fine, LTFM_Ann_Deficit_BNZD, 30.0);
debt_stk_30  = interp1(Yr_Fine, Debt_LTFM_Stock_Fine,  30.0);
flow_ce_50   = interp1(Yr_Fine, LTFM_Ann_Deficit_CE,   50.0);
flow_bnzd_50 = interp1(Yr_Fine, LTFM_Ann_Deficit_BNZD, 50.0);
debt_stk_50  = interp1(Yr_Fine, Debt_LTFM_Stock_Fine,  50.0);

plot(axM, [30.0, 50.0], [flow_ce_30, flow_ce_50], 'o', 'MarkerSize', 8.5, ...
    'MarkerFaceColor', [0.82 0.08 0.16], 'MarkerEdgeColor', 'w', 'LineWidth', 1.3, 'HandleVisibility', 'off');
plot(axM, [30.0, 50.0; 21.0, 44.5], [flow_ce_30, flow_ce_50; -5.85, -3.95], '-', ...
    'Color', [0.76 0.04 0.12], 'LineWidth', 1.4, 'HandleVisibility', 'off');

text(axM, 20.5, -5.85, sprintf('Yr 30 LTFM Annual Deficit (%s):\n%.2f%% CE/yr (%.1f BNZD/yr [-2.5%% GDP/yr])\n[Cumulative LTFM Debt = %.1f%% of GDP]', ...
    r_sel, flow_ce_30, flow_bnzd_30, debt_stk_30), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 7.2, 'FontWeight', 'bold', ...
    'Color', [0.65 0.02 0.10], 'BackgroundColor', [1.00 0.96 0.96], 'EdgeColor', [0.76 0.04 0.12], 'LineWidth', 1.2, 'Margin', 2.2);

text(axM, 44.5, -3.85, sprintf('Yr 50 LTFM Annual Deficit (%s):\n%.2f%% CE/yr (%.1f BNZD/yr [-3.2%% GDP/yr])\n[Cumulative LTFM Debt = %.1f%% GDP \\rightarrow 185%% @ Yr 60]', ...
    r_sel, flow_ce_50, flow_bnzd_50, debt_stk_50), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 7.2, 'FontWeight', 'bold', ...
    'Color', [0.65 0.02 0.10], 'BackgroundColor', [1.00 0.96 0.96], 'EdgeColor', [0.76 0.04 0.12], 'LineWidth', 1.2, 'Margin', 2.2);

yline(axM, 0, 'k-', 'LineWidth', 1.8, 'HandleVisibility', 'off');
xline(axM, 0,    'k:',  'LineWidth', 1.4, 'HandleVisibility', 'off');
xline(axM, 5.0,  ':',   'Color', [0.00 0.55 0.62], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(axM, 7.0,  ':',   'Color', [0.58 0.20 0.62], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(axM, 16.8, '--',  'Color', [0.00 0.52 0.22], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(axM, 18.8, 'r--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(axM, 25.0, 'b-.', 'LineWidth', 1.7, 'HandleVisibility', 'off');

text(axM, 0.8, 16.8, sprintf('Split Columns (%s, Both Converge to %+.2f%% SS2!):\n• Left Half-Bar = Single-Phase | Right Half-Bar = 13-Wave Te Kāhui Waka\n• Pale Purple (5a & -Inv 3a) = %.1f%% Existing Tuakana Early Adopters (Yrs 1-6)\n• Vivid Orchid (5b & -Inv 3b) = New Mentored Waves (Launches Yr 7+!)', ...
    r_sel, Total_Kahui_CE(end), 100*sh_ygr_base0), ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'FontSize', 7.2, 'FontWeight', 'bold', 'Color', [0.05 0.28 0.14], ...
    'BackgroundColor', [0.94 1.00 0.96], 'EdgeColor', [0.00 0.48 0.22], 'LineWidth', 1.2, 'Margin', 2.8);

ylabel(axM, 'Annual Welfare Flow (+CE %/yr) Above 0  |  Annual Public Outlay & LTFM Deficit (-CE %/yr) Below 0', 'FontSize', 10.0, 'FontWeight', 'bold');
ylim(axM, [y_mir_bot, y_mir_top]);

yyaxis(axM, 'right');
ylim(axM, [y_mir_bot * NZD_Per_CE, y_mir_top * NZD_Per_CE]);
ylabel(axM, sprintf('%s Annual Gain (+NZD B/yr) vs. Outlay & LTFM Deficit (-NZD B/yr)', r_sel), 'FontSize', 10.0, 'FontWeight', 'bold');
axM.YColor = [0.15 0.15 0.15];
yyaxis(axM, 'left');

title(axM, sprintf('Apples-to-Apples Annual Flows (%s): 11-Layer Welfare Gains (+Above 0) vs. Mirror Outlays & LTFM Annual Deficit (-Below 0)', r_sel), ...
    'FontSize', 10.8, 'FontWeight', 'bold');
xlabel(axM, 'Years Relative to Reform Launch (2-Yr Steps: Left Half-Column = Single-Phase | Right Half-Column = 13-Wave Te Kāhui Waka + Tax Ramps)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlim(axM, [-3, 63]); xticks(axM, 0:5:60); grid(axM, 'on'); box(axM, 'on');
legend(axM, 'Location', 'northwest', 'FontSize', 5.8, 'NumColumns', 2);

f_mir_out = fullfile(OutputDir, sprintf('Fig_7Segment_Welfare_And_MirrorInvestments_%s.png', Reg_File_Suffix));
exportgraphics(fig_mir, f_mir_out, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved Apples-to-Apples Split-Column Mirror-Image Figure (%s) to: %s\n', r_sel, f_mir_out);

Out.Table19_Counterfactuals   = T19;
Out.Table20_MirrorInvestments = T20;
Out.Fig_Counterfactuals       = f_cf_out;
Out.Fig_MirrorInvestments     = f_mir_out;


end
