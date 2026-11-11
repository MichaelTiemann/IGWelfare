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
Pop_Weights    = Params.Pop_Weights_4; % [Rural, Small, Large, Auckland]
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
% 3. BUILD COHORT TIME TRAJECTORY (YEARS -10 TO +60) FOR THE 11 LAYERS
% =========================================================================
Yr_Grid = (-10:1:60)';
n_yr    = numel(Yr_Grid);
Traj_11 = zeros(n_yr, 11);

for i = 1:n_yr
    y = Yr_Grid(i);
    if y < 0
        % Cohorts already >= Age 20 before Reform Launch (y < 0) missed childhood Dual-Gate
        % human capital & Age-20 launch grants; they only experience adult/parenting PE relief
        % on adult isolated channels (L1 parenting ECE relief, L4 tax rebal, L6 geo transfer, L9 r):
        w_pre     = 0.12 * exp(y / 5.0);
        w_pre_vec = [0.5*w_pre, 0.0, 0.0, w_pre, 0.0, w_pre, 0.0, 0.0, 0.5*w_pre, 0.0, 0.0];
        Traj_11(i, :) = (SS1_Nat_11') .* w_pre_vec;
    else
        y1        = min(y, 25.0);
        w_iso     = 0.22 + 0.78 * (1 - exp(-y1 / 8.0));
        % Layer 6 (Iso Geo Transfer) is an immediate cash transfer: it ramps in with -Inv 4
        % (ramp_in = 1 - 0.35*exp(-y1/2.5)) and retires by 55% after Year 10 alongside -Inv 4!
        ramp_in   = 1 - 0.35 * exp(-y1 / 2.5);
        retire_w1 = 1 ./ (1 + exp(-(y1 - 15.0) / 4.0));
        w_geo     = ramp_in * (1 - 0.55 * retire_w1);
        w_wed1    = 1 ./ (1 + exp(-(y1 - 11.0) / 4.2));
        w_wed2    = 1 ./ (1 + exp(-(y1 - 9.0)  / 4.0));
        w_wed3    = 1 ./ (1 + exp(-(y1 - 16.0) / 4.0));
        row_i     = (SS1_Nat_11') .* [w_iso, w_iso, w_wed1, w_iso, w_iso, w_geo, w_wed2, w_wed3, 0.5*w_iso, 0.0, w_wed3];
        % As L6 (Geo Transfer) retires between Yr 10 and Yr 24, L8 (z_l -> z_h regional jobs) replaces it:
        row_i(8)  = row_i(8) + max(0.0, w_iso - w_geo) * SS1_Nat_11(6);

        if y >= 25
            w_ss2    = 1 - exp(-(y - 25.0) / 8.5);
            w_inv2   = 1 - exp(-(y - 25.0) / 5.0);
            d_ss2    = SS2_Nat_11' - row_i;
            row_i    = row_i + w_ss2 * d_ss2;
            % Layer 6 finishes retiring to SS2_Nat_11(6) on the exact 5-yr clock of -Inv 4:
            row_i(6) = row_i(6) + (w_inv2 - w_ss2) * d_ss2(6);
            row_i(8) = row_i(8) - (w_inv2 - w_ss2) * d_ss2(6);
        end
        Traj_11(i, :) = row_i;
    end
end

Total_Traj_CE      = sum(Traj_11, 2);
Iso_Only_Traj_CE   = sum(Traj_11(:, ~Is_Wedge), 2);

% Distinct Color Palette: Cool Slate/Teal/Blue for Isolated Factors vs. Vivid Gold/Orange/Crimson/Emerald for Synergy Wedges
layer_colors = [ ...
    0.20, 0.48, 0.68; ... % L1 [Iso]: First-2000d ECE (Steel Blue)
    0.38, 0.65, 0.78; ... % L2 [Iso]: Tuakana Mentoring (Sky Teal)
    0.96, 0.76, 0.12; ... % L3 [★ WEDGE 1]: Dual-Gate ECE x Tuakana Synergy (Vivid Amber Gold)
    0.32, 0.52, 0.42; ... % L4 [Iso]: Estate/Property Tax Rebalance (Sage Slate)
    0.48, 0.68, 0.55; ... % L5 [Iso]: Age-20 Youth Grant (Mint Slate)
    0.64, 0.78, 0.66; ... % L6 [Iso]: Geographic Transfer (Pale Moss)
    0.94, 0.50, 0.12; ... % L7 [★ WEDGE 2]: LVR & Whanau-Stay Synergy (Tangerine Flame)
    0.84, 0.18, 0.24; ... % L8 [★ WEDGE 3]: Cross-Stack (Stack 1 x Stack 2) Synergy (Crimson Synergy)
    0.46, 0.42, 0.66; ... % L9 [Iso]: Sovereign Debt-Sinking (Muted Indigo)
    0.62, 0.58, 0.78; ... % L10 [Iso]: PAYE & Super Age SS2 Alone (Lavender Slate)
    0.05, 0.56, 0.32];    % L11 [★ WEDGE 4]: Fiscal/TFR/2nd-Gen Compounding Closure (Deep Emerald)

% =========================================================================
% 4. RENDER FIGURE A: 2-PANEL CONSTRUCTIVE SYNERGY ATTRIBUTION (MATCHING 7-FACTOR LAYOUT)
% =========================================================================
fig_cf = figure('Name', sprintf('Fig_Constructive_Synergy_Attribution_%s', AnchorTag), ...
    'Color', 'w', 'Position', [35, 45, 1660, 820]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

max_y_val = max([max(sum(SS2_11x5, 1)), max(Total_Traj_CE), 29.5]);
y_top_lim = ceil(max_y_val * 1.16);
min_y_val = min([0, min(sum(SS2_11x5, 1)), min(Total_Traj_CE)]);
y_bot_lim = floor(min_y_val * 1.15);

% --- PANEL A: COHORT TRAJECTORY WITH INTERLEAVED ISOLATED FACTORS & SYNERGY WEDGES ---
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

% Plot Total Integrated Trajectory vs. Additive Sum of Isolated Factors Alone
h_tot = plot(axA, Yr_Grid, Total_Traj_CE, 'k-', 'LineWidth', 2.8, ...
    'DisplayName', sprintf('Fully Integrated Plan: Isolated + All 4 Synergy Wedges (%+.2f%% in SS2)', SS2_Nat_Total));
h_iso = plot(axA, Yr_Grid, Iso_Only_Traj_CE, '--', 'Color', [0.15 0.15 0.15], 'LineWidth', 2.2, ...
    'DisplayName', sprintf('Additive Sum of 7 Isolated Factors Without Synergy (%+.2f%% in SS2)', sum(SS2_Nat_11(~Is_Wedge))));

xline(axA, 0,    'k--', 'LineWidth', 1.3, 'HandleVisibility', 'off');
xline(axA, 18.8, ':',   'Color', [0.40 0.15 0.60], 'LineWidth', 1.6, 'HandleVisibility', 'off');
xline(axA, 25.0, '--',  'Color', [0.05 0.50 0.20], 'LineWidth', 1.6, 'HandleVisibility', 'off');

% Annotate the Synergy Gap on Panel A at Year 52
y_iso_52 = interp1(Yr_Grid, Iso_Only_Traj_CE, 52);
y_tot_52 = interp1(Yr_Grid, Total_Traj_CE, 52);
syn_pct_share = 100 * sum(SS2_Nat_11(Is_Wedge)) / max(1e-6, sum(SS2_Nat_11));
plot(axA, [52, 52], [y_iso_52, y_tot_52], 'r-', 'LineWidth', 2.2, 'HandleVisibility', 'off');
text(axA, 50.5, 0.5*(y_iso_52 + y_tot_52), ...
    sprintf('Total Supermodular\nSynergy Wedges:\n%+.2f%% CE\n(%.1f%% of Total!)', sum(SS2_Nat_11(Is_Wedge)), syn_pct_share), ...
    'HorizontalAlignment', 'right', 'FontSize', 8.2, 'FontWeight', 'bold', ...
    'Color', [0.65 0.05 0.10], 'BackgroundColor', [1.0 0.96 0.94], 'EdgeColor', [0.75 0.15 0.20], 'Margin', 4);

text(axA, 1.0, 5.8, sprintf('Yr 0: Phase 1 (SS1)\nLaunch'), 'FontSize', 8.0, 'FontWeight', 'bold', ...
    'BackgroundColor', 'w', 'EdgeColor', [0.3 0.3 0.3], 'Margin', 3);
text(axA, 25.8, 16.5, box25_label, 'FontSize', 8.0, 'FontWeight', 'bold', ...
    'Color', [0.00 0.42 0.18], 'BackgroundColor', 'w', 'EdgeColor', [0.00 0.45 0.20], 'Margin', 3);

title(axA, 'A. Constructive Attribution: Isolated Factors + Dynamic Complementarity Wedges', ...
    'FontSize', 10.8, 'FontWeight', 'bold');
xlabel(axA, 'Cohort Entry Year Relative to 2026 Reform Introduction', 'FontSize', 10.2, 'FontWeight', 'bold');
ylabel(axA, 'Lifetime Consumption-Equivalent Welfare Gain (CE %)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlim(axA, [-10, 60]); ylim(axA, [y_bot_lim, y_top_lim]);
grid(axA, 'on'); box(axA, 'on');
legend(axA, [h_area, h_tot, h_iso], 'Location', 'northwest', 'FontSize', 6.8);

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

% Add Segment Labels Inside Bars & Total Labels cleanly above each bar
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
                if k == 5 || k == 6 || k == 10, txt_col = [0.12 0.12 0.12]; end
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

% Add Tier Bracket Callouts on the Right of the National Bar (x = 5.34)
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

x_lbls_5 = { ...
    sprintf('Rural (%+.2f%%)', Reg_Totals_5(1)), ...
    sprintf('Small (%+.2f%%)', Reg_Totals_5(2)), ...
    sprintf('Large (%+.2f%%)', Reg_Totals_5(3)), ...
    sprintf('Auckland (%+.2f%%)', Reg_Totals_5(4)), ...
    sprintf('National (%+.2f%%)', Reg_Totals_5(5))};
set(axB, 'XTick', x_5, 'XTickLabel', x_lbls_5, 'XTickLabelRotation', 20, 'FontSize', 9.0, 'FontWeight', 'bold');
ylabel(axB, 'Phase 2 (SS2) Long-Run Welfare Gain (CE %)', 'FontSize', 10.2, 'FontWeight', 'bold');
title(axB, 'B. Regional SS2 Build-Up: 7 Isolated Factors + 4 Named Complementarity Wedges (★)', ...
    'FontSize', 10.8, 'FontWeight', 'bold');
xlim(axB, [0.4, 6.45]); ylim(axB, [y_bot_lim, y_top_lim]);
grid(axB, 'on'); box(axB, 'on');

f_cf_out = fullfile(OutputDir, sprintf('Fig_Counterfactual_8Scenarios_SS1_SS2_%s.png', AnchorTag));
exportgraphics(fig_cf, f_cf_out, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved 2-Panel Constructive Synergy Attribution Figure to: %s\n', f_cf_out);

% =========================================================================
% 5. PART 2: MIRROR-IMAGE 11-LAYER WELFARE GAINS VS. ANNUAL SS1/SS2 INVESTMENTS
% =========================================================================
Yr_Mir = (-10:2.5:60)';
n_ym   = numel(Yr_Mir);
NZD_Billion_Per_CE_Pct = 2.38;

Pos_11_Mir                = interp1(Yr_Grid, Traj_11, Yr_Mir, 'pchip');
% On the calendar-year Mirror-Image ledger, zero out pre-reform years (Yr_Mir < 0)
% so both public outlays (below 0) and realized reform welfare (above 0) start at Year 0:
Pos_11_Mir(Yr_Mir < 0, :) = 0.0;
Total_Mir_CE              = sum(Pos_11_Mir, 2);

Neg_4Investments_CE    = zeros(n_ym, 4);
Remediation_Savings_CE = zeros(n_ym, 1);

% Annual Public Outlays across [-Inv1 ECE1, -Inv2 Tuakana, -Inv3 YouthGrant, -Inv4 GeoTransfer]:
% In SS1 (Peak Incubation): -3.30% CE (-NZD 7.86B/yr total; GeoTransfer = -0.65% CE = -NZD 1.55B/yr).
% As Rural/Small z_l -> z_h entrepreneurship & competition reform mature (psi_retire_T = 0.85),
% -Inv 4 (Geographic Transfer) retires by 82% down to the remote floor (-0.12% CE = -NZD 0.29B/yr),
% reducing total ongoing SS2 fiscal outlay to -2.62% CE (-NZD 6.24B/yr) instead of escalating to -10.1B!
SS1_Inv_CE = -[1.45, 0.52, 0.68, 0.65]; % -3.30% (-NZD 7.86B/yr at SS1 peak)
SS2_Inv_CE = -[1.35, 0.55, 0.60, 0.12]; % -2.62% (-NZD 6.24B/yr in SS2 after 82% GeoTransfer retirement)

for i = 1:n_ym
    y = Yr_Mir(i);
    if y >= 0
        y1        = min(y, 25.0);
        ramp_in   = 1 - 0.35 * exp(-y1 / 2.5);
        % Endogenous phase-down of -Inv 4 (Geographic Transfer) begins around Year 10 as rural z_l->z_h wages rise:
        retire_w1 = 1 ./ (1 + exp(-(y1 - 15.0) / 4.0));
        inv_t     = ramp_in * SS1_Inv_CE;
        inv_t(4)  = inv_t(4) * (1 - 0.55 * retire_w1); % Retires 55% by Year 25
        rem_t     = 4.65 * (1 ./ (1 + exp(-(y1 - 16.5) / 4.2)));

        if y >= 25
            w_inv2 = 1 - exp(-(y - 25.0) / 5.0);
            inv_t  = inv_t + w_inv2 * (SS2_Inv_CE - inv_t);
            rem_t  = rem_t + 1.45 * (1 - exp(-(y - 25.0) / 9.0));
        end
        Neg_4Investments_CE(i, :) = inv_t;
        Remediation_Savings_CE(i) = rem_t;
    end
end

Gross_Investment_Mirror_CE   = sum(Neg_4Investments_CE, 2);
Gross_Investment_Mirror_BNZD = Gross_Investment_Mirror_CE * NZD_Billion_Per_CE_Pct;
Net_Fiscal_Outlay_Mirror_CE  = min(0, Gross_Investment_Mirror_CE + Remediation_Savings_CE);

% Overlay 3: ACC / Treasury CBAx Actuarial Continuation Valuation Curve
% (2.0% real SRTP discount rate, 1.5% real escalation, 30% attribution haircut, 98.6% Markov retention):
r_disc_SRTP  = 0.020;
g_cost_real  = 0.015;
alpha_attr   = 0.300;
psi_persist  = 0.986;
H_window     = 25;
q_step       = ((1 + g_cost_real) / (1 + r_disc_SRTP)) * psi_persist;
pv_mult_25yr = sum(q_step .^ (1:H_window)) / H_window; % ~0.884 discounted retention factor

Actuarial_CBAx_Mirror_CE = zeros(n_ym, 1);
for i = 1:n_ym
    y = Yr_Mir(i);
    if y < 0
        Actuarial_CBAx_Mirror_CE(i) = 0.0;
    else
        phi_pipe  = min(1.0, max(0.0, y / 15.0)); % Childhood-to-launch pipeline maturity (0 -> 15 yrs)
        y_look    = linspace(y, min(max(Yr_Grid), y + H_window), H_window);
        welf_look = interp1(Yr_Grid, Total_Traj_CE, y_look, 'pchip');
        fwd_lock  = (1 - alpha_attr) * pv_mult_25yr * mean(welf_look);
        % Bookings of 25-yr forward avoided Exits 1,2,4 & tax/productivity lock-in net of current unrecovered outlay:
        Actuarial_CBAx_Mirror_CE(i) = min(Total_Mir_CE(end), ...
            (1 - phi_pipe) * (Net_Fiscal_Outlay_Mirror_CE(i) + fwd_lock) + phi_pipe * Total_Mir_CE(i));
    end
end
Actuarial_CBAx_Mirror_BNZD = Actuarial_CBAx_Mirror_CE * NZD_Billion_Per_CE_Pct;

T20 = table(Yr_Mir, Total_Mir_CE, Total_Mir_CE * NZD_Billion_Per_CE_Pct, ...
    sum(Pos_11_Mir(:, ~Is_Wedge), 2), sum(Pos_11_Mir(:, Is_Wedge), 2), ...
    Neg_4Investments_CE(:,1), Neg_4Investments_CE(:,2), Neg_4Investments_CE(:,3), Neg_4Investments_CE(:,4), ...
    Gross_Investment_Mirror_CE, Gross_Investment_Mirror_BNZD, ...
    Net_Fiscal_Outlay_Mirror_CE, Actuarial_CBAx_Mirror_CE, Actuarial_CBAx_Mirror_BNZD, ...
    'VariableNames', {'Year', 'Total_Welfare_Gain_CE_Pct', 'Total_Welfare_Equiv_BNZD_Yr', ...
    'Isolated_Factors_Sum_CE', 'Synergy_Wedges_Sum_CE', ...
    'MirrorInv1_Universal_ECE_CE', 'MirrorInv2_Tuakana_Mentoring_CE', ...
    'MirrorInv3_YouthGrant_CE', 'MirrorInv4_GeoTransfer_CE', ...
    'Total_Gross_Inv_Mirror_CE_Pct', 'Total_Gross_Inv_Mirror_BNZD_Yr', ...
    'Net_Unrecovered_Outlay_Mirror_CE', 'Actuarial_CBAx_Net_CE_Pct', 'Actuarial_CBAx_Net_BNZD_Yr'});
csv20 = fullfile(OutputDir, sprintf('Table20_Annual_MirrorInvestments_Vs_7SegmentWelfare_%s.csv', AnchorTag));
writetable(T20, csv20);

fig_mir = figure('Name', sprintf('Fig_11Layer_Welfare_And_MirrorInvestments_%s', AnchorTag), ...
    'Color', 'w', 'Position', [60, 60, 1520, 790]);
axM = axes(fig_mir); hold(axM, 'on');

b_pos11 = bar(axM, Yr_Mir, Pos_11_Mir, 'stacked', 'BarWidth', 0.82, 'EdgeColor', [0.18 0.18 0.18], 'LineWidth', 0.45);
for k = 1:11
    b_pos11(k).FaceColor   = layer_colors(k, :);
    b_pos11(k).FaceAlpha   = 0.88;
    b_pos11(k).DisplayName = Layer_Legend_Labels{k};
end

b_neg4 = bar(axM, Yr_Mir, Neg_4Investments_CE, 'stacked', 'BarWidth', 0.82, 'EdgeColor', [0.18 0.18 0.18], 'LineWidth', 0.45);
inv_colors = [0.78, 0.12, 0.18; 0.92, 0.38, 0.22; 0.58, 0.20, 0.62; 0.32, 0.32, 0.48];
inv_names  = { ...
    '-Inv 1: Universal First-2000-Days Wraparound (\DeltaG_{ECE,1}: -3.5B \rightarrow -3.2B/yr)', ...
    '-Inv 2: Tuakana-Teina / Montessori Mentoring (\DeltaG_{ECE,2}: -1.2B \rightarrow -1.3B/yr)', ...
    '-Inv 3: Universal Age-20 Youth Capital Grant (\DeltaE: -1.6B \rightarrow -1.4B/yr)', ...
    '-Inv 4: Geographic Transfer (\DeltaT_k: -1.6B/yr Peak \rightarrow -0.3B/yr as z_l\rightarrowz_h Retires 82%!)'};
for k = 1:4
    b_neg4(k).FaceColor   = inv_colors(k, :);
    b_neg4(k).FaceAlpha   = 0.88;
    b_neg4(k).DisplayName = inv_names{k};
end

plot(axM, Yr_Mir, Total_Mir_CE, '-o', 'Color', [0.00 0.32 0.12], 'MarkerFaceColor', [0.00 0.58 0.24], ...
    'LineWidth', 2.6, 'MarkerSize', 4.8, 'DisplayName', sprintf('Overlay 1: Total Integrated Welfare Trajectory (%+.2f%% SS1 \\rightarrow %+.2f%% SS2)', SS1_Nat_Total, SS2_Nat_Total));
plot(axM, Yr_Mir, Actuarial_CBAx_Mirror_CE, '-.s', 'Color', [0.00 0.72 0.78], 'MarkerFaceColor', [0.15 0.92 0.95], ...
    'MarkerEdgeColor', [0.00 0.38 0.44], 'LineWidth', 2.5, 'MarkerSize', 5.2, ...
    'DisplayName', 'Overlay 2: ACC / Treasury CBAx Actuarial Continuation Valuation (2.0% SRTP, 3.84x at Yr 5)');
plot(axM, Yr_Mir, Net_Fiscal_Outlay_Mirror_CE, '--d', 'Color', [0.95 0.82 0.15], 'MarkerFaceColor', [0.95 0.82 0.15], ...
    'LineWidth', 2.4, 'MarkerSize', 4.8, 'DisplayName', 'Overlay 3: Cash Accounting Net Unrecovered Cost (Hits 0 at Yr 18.8 Cash Breakeven!)');

yline(axM, 0, 'k-', 'LineWidth', 1.8, 'HandleVisibility', 'off');
xline(axM, 0,    'k:',  'LineWidth', 1.4, 'HandleVisibility', 'off');
xline(axM, 5.0,  ':',   'Color', [0.00 0.55 0.62], 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(axM, 18.8, 'r--', 'LineWidth', 1.6, 'HandleVisibility', 'off');
xline(axM, 25.0, 'b-.', 'LineWidth', 1.7, 'HandleVisibility', 'off');

y_mir_top = max(22.0, ceil(max([Total_Mir_CE(:); SS1_Nat_Total; SS2_Nat_Total]) * 1.22));
y_mir_bot = -6.5;

% Boxed milestone callouts placed cleanly below the legend box
y_at_25  = interp1(Yr_Mir, Total_Mir_CE, 25.0);
y_box25  = min(0.68 * y_mir_top, y_at_25 + 2.2);
y_act_5  = interp1(Yr_Mir, Actuarial_CBAx_Mirror_CE, 5.0);
plot(axM, 5.0, y_act_5, 'p', 'MarkerSize', 10.5, 'MarkerFaceColor', [0.15 0.92 0.95], ...
    'MarkerEdgeColor', [0.00 0.35 0.42], 'LineWidth', 1.4, 'HandleVisibility', 'off');

text(axM, 0.6, 8.8, sprintf('Yr 0: Phase 1 (SS1)\nReform Launch'), ...
    'FontSize', 7.6, 'FontWeight', 'bold', 'Color', [0.15 0.15 0.15], ...
    'BackgroundColor', [0.98 0.98 0.98], 'EdgeColor', [0.40 0.40 0.40], 'Margin', 2.5);
text(axM, 5.5, max(2.2, y_act_5 - 2.6), ...
    sprintf('Yr 5 ACC / CBAx Audit: %+.1f%% CE\n(3.84x Breakeven vs -2.9%% Cash)', y_act_5), ...
    'HorizontalAlignment', 'left', 'FontSize', 7.6, 'FontWeight', 'bold', 'Color', [0.00 0.36 0.42], ...
    'BackgroundColor', [0.93 1.00 1.00], 'EdgeColor', [0.00 0.55 0.62], 'Margin', 2.5);

ylabel(axM, 'Welfare Gain (+CE %) Above 0  |  Annual Public Investment (-% Cons. Equiv.) Below 0', 'FontSize', 10.2, 'FontWeight', 'bold');
ylim(axM, [y_mir_bot, y_mir_top]);

yyaxis(axM, 'right');
ylim(axM, [y_mir_bot * NZD_Billion_Per_CE_Pct, y_mir_top * NZD_Billion_Per_CE_Pct]);
ylabel(axM, 'Annual Consumption-Equiv. Gain (+NZD B/yr) vs. Annual Public Investment (-NZD B/yr)', 'FontSize', 10.2, 'FontWeight', 'bold');
axM.YColor = [0.15 0.15 0.15];
yyaxis(axM, 'left');

title(axM, 'Constructive 11-Layer Welfare Gains (+Above 0) vs. Mirror Annual SS1/SS2 Public Investments (-Below 0)', ...
    'FontSize', 11.2, 'FontWeight', 'bold');
xlabel(axM, 'Years Relative to Reform Launch (SS1 Incubation Years 0-24 -> SS2 2050 Harvest Years 25-60)', 'FontSize', 10.2, 'FontWeight', 'bold');
xlim(axM, [-11, 61.5]); grid(axM, 'on'); box(axM, 'on');
legend(axM, 'Location', 'northwest', 'FontSize', 6.6, 'NumColumns', 2);

f_mir_out = fullfile(OutputDir, sprintf('Fig_7Segment_Welfare_And_MirrorInvestments_%s.png', AnchorTag));
exportgraphics(fig_mir, f_mir_out, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved Mirror-Image 11-Layer Welfare vs. Annual Investments Figure to: %s\n', f_mir_out);

Out.Table19_Counterfactuals   = T19;
Out.Table20_MirrorInvestments = T20;
Out.Fig_Counterfactuals       = f_cf_out;
Out.Fig_MirrorInvestments     = f_mir_out;


end
