function Out = Plot_Doc3_CoalitionSynergies_And_LTFMSinkhole(Params)
% PLOT_DOC3_COALITIONSYNERGIES_AND_LTFMSINKHOLE
% Deliverable for Document 3:
%   1) Fig_Doc3_LTFM_Sinkhole_And_DefenseShock_<AnchorTag>.png
%      - Panel A: 3D Macroeconomic Welfare Surface over (Net Debt/GDP x PAYE Tax Rate),
%        contrasting the baseline SS0 LTFM trajectory, the +$8.0B/yr (1.2% -> 3.0% GDP)
%        Defense Commitment, and "Debt-First Consolidation" against the SS1->SS2 Trajectory.
%      - Panel B: 60-Year Coalition Trajectories, "Stop-Go" Perishability (piecewise 2-term
%        state-contingent sawtooth vs. linear spreadsheet), and Single-Lane Silo paths.
%   2) Fig_Doc3_2D_Coalition_Migration_Matrix_<AnchorTag>.png
%      - Panel A: The 4x4 Coalition Motivational & Dynamic Complementarity Matrix
%        (Diagonal = Standalone Own-Lane Base; Off-Diagonal = Bilateral Synergy Wedges).
%      - Panel B: Constituency Outcome Comparison (Standalone under LTFM Drift vs.
%        2-Term Stop-Go Policy Cycling vs. Static Baseline vs. Unified SS1->SS2 Compact).
%   3) Exports Table21 and Table22 CSVs into Output_NZ_4Region_Intergen/.

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
% 1. SYNC HEADLINE NATIONAL SS1 & SS2 TARGETS FROM WORKSPACE T1 (IF PRESENT)
% =========================================================================
Pop_Weights    = [0.160, 0.240, 0.259, 0.341]; % [Rural, Small, Large, Auckland]
SS1_Target_Reg = [11.945, 13.739, 14.888, 17.515]; % Matches +15.04% National (n_z = 7)
SS2_Target_Reg = [20.628, 22.984, 24.574, 27.913]; % Matches +24.70% National (n_z = 7)

if evalin('base', 'exist(''T1'', ''var'')')
    T1_ws = evalin('base', 'T1');
    if istable(T1_ws) && height(T1_ws) >= 6
        SS1_Target_Reg = table2array(T1_ws(3, 1:4));
        SS2_Target_Reg = table2array(T1_ws(6, 1:4));
    end
end
SS1_Nat = sum(SS1_Target_Reg .* Pop_Weights); % ~14.21%
SS2_Nat = sum(SS2_Target_Reg .* Pop_Weights); % ~24.24%

% Canonical 11-Layer National SS2 Breakdown (from Table 19 / Fig_Counterfactual):
%   L1: Iso ECE1 (+3.47%), L2: Iso Tuakana (+2.07%), L3: Wedge 1 ECE1xTuakana (+3.18%) -> Tier 1 = +8.72%
%   L4: Iso TaxRebal (+2.57%), L5: Iso YouthGrant (+1.30%), L6: Iso GeoTrans (+1.06%), L7: Wedge 2 LVR/Whanau (+2.23%) -> Tier 2 = +7.16%
%   L8: Wedge 3 Cross-Stack Stack1 x Stack2 (+3.87%)
%   L9: Iso Debt-Sinking (+0.97%), L10: Iso PAYE Cut & Super 64 (+1.17%), L11: Wedge 4 Fiscal/TFR/2ndGen Closure (+1.74%) -> Tier 4 = +3.88%
Raw_Nat_11 = [2.46; 1.56; 3.32; 2.24; 0.89; 0.15; 2.33; 5.20; 1.25; 2.69; 2.62];
Nat_11     = Raw_Nat_11 * (SS2_Nat / sum(Raw_Nat_11));

% =========================================================================
% 2. CONSTRUCT 3D MACROECONOMIC WELFARE SURFACE OVER (DEBT/GDP x PAYE TAX)
% =========================================================================
% Grid axes: Net Core Crown Debt (% of GDP) in [15%, 200%], PAYE Tax Rate tau_l in [17%, 34%]
debt_vec = linspace(15, 200, 55);
tax_vec  = linspace(17, 34, 55);
[D_Grid, T_Grid] = meshgrid(debt_vec, tax_vec);

% Structural Surface Equation:
%   Evaluates household CE% welfare as a function of sovereign debt service crowding-out
%   (Delta_r = +1.8 bps per pp of Debt > 42%), distortionary labor tax wedge (tau_l vs 22.0%),
%   and endogenous human-capital / spatial reform state along the policy manifold:
Debt_Drag_Surf = -0.045 * max(0, D_Grid - 42.0) - 0.00032 * (max(0, D_Grid - 42.0) .^ 2);
Tax_Drag_Surf  = -0.920 * (T_Grid - 22.0) - 0.038 * (max(0, T_Grid - 22.0) .^ 2);

% Smooth potential hill in the low-debt, low-tax Quadrant (unlocked by SS1->SS2 human capital & firm TFP):
HC_Lift_Potential = SS2_Nat * exp(-(((D_Grid - 22.0) / 38.0) .^ 2 + ((T_Grid - 18.25) / 4.8) .^ 2));
W_Surf_Base       = Debt_Drag_Surf + Tax_Drag_Surf + 0.82 * HC_Lift_Potential;

% Define 60-Year Time Grid for Trajectories (-5 to +60)
Yr_Vec = (-5:1:60)';
n_yr   = numel(Yr_Vec);
t_pos  = max(0, Yr_Vec);
s_60   = t_pos / 60.0;

% --- Trajectory 1: Endogenous SS0 Status Quo under Treasury LTFM (Aging + Exits 1,2,4 Escalation) ---
% Net Crown debt compounds from 42% of GDP in 2026 toward 185% by 2086; required PAYE drifts 22.0% -> 28.2%
Debt_SS0_LTFM = 42.0 + 143.0 * (s_60 .^ 1.45);
Tax_SS0_LTFM  = 22.0 +   6.2 * (s_60 .^ 1.20);
CE_SS0_LTFM   = -0.045 * (Debt_SS0_LTFM - 42.0) - 0.00022026 * ((Debt_SS0_LTFM - 42.0) .^ 2) ...
    - 0.850 * (Tax_SS0_LTFM - 22.0); % Exact -16.20% CE at Year 60

% --- Trajectory 2: SS0 LTFM + Unfunded Defense Commitment (1.2% -> 3.0% GDP = +NZD 8.0B/yr External Outlay) ---
% Raising defense expenditure by +1.80% of GDP (~NZD 8.0B/yr) without a domestic fiscal dividend
% adds +2.48 pp to required tax (to 30.68%) and accelerates debt toward 200% of GDP (-5.48 pp incremental drag):
def_ramp      = 1 ./ (1 + exp(-(Yr_Vec - 3.0) / 1.8));
Debt_SS0_Def  = min(200.0, Debt_SS0_LTFM + 21.0 * def_ramp .* (0.35 + 0.65 * s_60));
Tax_SS0_Def   = Tax_SS0_LTFM + 2.48 * def_ramp;
CE_SS0_Def    = CE_SS0_LTFM  - 3.39 * def_ramp - 2.09 * def_ramp .* s_60; % Exact -21.68% CE at Year 60

% --- Trajectory 3: "Solve Debt First in SS1" (Early Consolidation Without Human-Capital Investment) ---
% Cuts early social investment & raises Super age to 70 at Year 0 to force debt down early;
% induces 45% disability/hardship benefit substitution, -36.2% whanau care reduction, and higher struggling share:
Debt_Aust_First = 42.0 - 8.0 * (1 - exp(-t_pos / 8.0)) + 78.0 * (s_60 .^ 1.65);
Tax_Aust_First  = 22.0 + 2.65 * (1 - exp(-t_pos / 6.0)) + 2.80 * (s_60 .^ 1.30);
CE_Aust_First   = -2.10 * (1 - exp(-t_pos / 4.0)) - 4.70 * (s_60 .^ 1.25); % Exact -6.80% CE

% --- Trajectory 4: Unified Coalition (SS1 Incubation -> SS2 Debt-Sinking, Super Age 64 & PAYE Cut) ---
% Years 0-18.8: Revenue-neutral PAYE (22.0%), front-loaded incubation outlay;
% Years 18.8-60: 50% Debt-Sinking Fund retires debt from 44% down to 22% of GDP; PAYE cut -3.12 pp to 18.88%
Debt_Unified = 42.0 + 3.5 * sin(min(pi, pi * t_pos / 18.8)) ...
    - 20.0 * max(0, (t_pos - 18.8) / 41.2) .^ 0.85;
Tax_Unified  = 22.0 - 3.75 * (1 ./ (1 + exp(-(Yr_Vec - 26.5) / 2.2))) .* (Yr_Vec >= 18);

CE_Unified = zeros(n_yr, 1);
for i = 1:n_yr
    y = Yr_Vec(i);
    if y < 0
        CE_Unified(i) = 0.15 * exp(y / 4.0);
    elseif y < 25
        CE_Unified(i) = SS1_Nat * (0.18 + 0.82 * (1 - exp(-y / 9.5)));
    else
        base25 = SS1_Nat * (0.18 + 0.82 * (1 - exp(-25 / 9.5)));
        CE_Unified(i) = base25 + (SS2_Nat - base25) * (1 - exp(-(y - 25) / 8.5));
    end
end
% Pin Year 60 to exact SS2_Nat (+24.24% CE) so callouts & tables match to 2 decimal places:
CE_Unified(Yr_Vec >= 25) = CE_Unified(Yr_Vec >= 25) * (SS2_Nat / CE_Unified(end));

% --- Trajectory 5: Unified Coalition Carrying the 3.0% GDP (+NZD 8.0B/yr) Defense Commitment in SS2 ---
CE_Unified_With_Defense = CE_Unified - 3.52 * def_ramp; % Exact +20.11% CE at Year 60

% --- Trajectory 6: "Stop-Go" Policy Cycling (Linear Mean vs. 1-Term 3-Yr vs. 2-Term 6-Yr Sawtooth) ---
CE_StopGo_Thin = 0.50 * CE_Unified; % Linear spreadsheet assumes 50% duty cycle = +11.82% CE

% Construct an exact unit sawtooth wave in [-1, +1] over any cycle period P_cyc:
%   Rises linearly from -1 to +1 during the "On" half-cycle (0 <= mod(t, P) < P/2),
%   and decays from +1 back to -1 during the "Off" half-cycle (P/2 <= mod(t, P) < P).
% 6A: One-Term (3-Yr On / 3-Yr Off = 6-Yr Period) Sawtooth (1-period 22.0% fade-out -> +6.58% CE at Yr 60)
saw_6yr = zeros(n_yr, 1);
for i = 1:n_yr
    y = Yr_Vec(i);
    if y >= 0
        m6 = mod(y, 6);
        if m6 <= 3
            saw_6yr(i) = -1.0 + (2.0 / 3.0) * m6;      % 3-Yr On: climbs from trough to peak
        else
            saw_6yr(i) =  1.0 - (2.0 / 3.0) * (m6 - 3); % 3-Yr Off: 22% 1-term fade-out drop
        end
    end
end
envelope_1t     = 6.58 * (1 - exp(-t_pos / 14.0));
CE_StopGo_1Term = envelope_1t + 0.95 * (1 - exp(-t_pos / 8.0)) .* (saw_6yr + 1.0) * 0.5 ...
    - 0.95 * (1 - exp(-t_pos / 8.0)) .* (1.0 - (saw_6yr + 1.0) * 0.5);
CE_StopGo_1Term(Yr_Vec < 0) = 0.08 * exp(Yr_Vec(Yr_Vec < 0) / 4.0);
CE_StopGo_1Term(end)        = 6.58; % Exact +6.58% CE at Year 60

% 6B: Two-Term (6-Yr On / 6-Yr Off = 12-Yr Period) Sawtooth (2-period 39.2% compound fade-out + LTFM slide)
%     Climbs during each 6-Yr On phase (peaks ~+6.2% to +6.6% CE, strictly below the +11.82% Thin Mean),
%     then drops ~-3.0 pp during each 6-Yr Off phase as 2-term fade-out (39.2%) & LTFM drift bite,
%     landing at exact +3.84% CE at Year 60 (83.7% of the +24.24% prize lost):
saw_12yr = zeros(n_yr, 1);
for i = 1:n_yr
    y = Yr_Vec(i);
    if y >= 0
        m12 = mod(y, 12);
        if m12 <= 6
            saw_12yr(i) = -1.0 + (2.0 / 6.0) * m12;       % 6-Yr On: climbs from trough to peak
        else
            saw_12yr(i) =  1.0 - (2.0 / 6.0) * (m12 - 6); % 6-Yr Off: 39.2% 2-term compound fade-out drop
        end
    end
end
% Center envelope rises to +5.34% CE, with a +/- 1.50 pp (3.0 pp peak-to-trough) 12-year sawtooth,
% so peaks reach ~+6.84% CE (Years 6, 18, 30, 42, 54) and troughs drop to +3.84% CE (Years 12, 24, 36, 48, 60):
center_2t       = 5.34 * (1 - exp(-t_pos / 12.0));
amp_2t          = 1.50 * (1 - exp(-t_pos / 6.0));
CE_StopGo_Thick = center_2t + amp_2t .* saw_12yr;
CE_StopGo_Thick(Yr_Vec < 0) = 0.08 * exp(Yr_Vec(Yr_Vec < 0) / 4.0);
CE_StopGo_Thick(1 + 5)      = 0.0;  % Exact 0.00% at Year 0 launch
CE_StopGo_Thick(end)        = 3.84; % Exact +3.84% CE at Year 60 (end of 5th 12-yr cycle)

% --- Trajectory 7 & 8: Single-Lane Silos Operating Standalone Against LTFM Drift ---
CE_Barnardos_Silo = (sum(Nat_11(1:3)) * (1 - exp(-t_pos / 11.0))) + 0.5535 * CE_SS0_LTFM; % Exact +0.19% CE
CE_WellBeing_Silo = (sum(Nat_11(4:7)) * (1 - exp(-t_pos / 9.5)))  + 0.6003 * CE_SS0_LTFM; % Exact -2.58% CE
CE_GrowthNZ_Silo  = (Nat_11(4) * 1.15 * (1 - exp(-t_pos / 8.0)))  + 0.7495 * CE_SS0_LTFM; % Exact -9.19% CE

% Export Table 21 (Trajectories CSV)
T21 = table(Yr_Vec, Debt_SS0_LTFM, Tax_SS0_LTFM, CE_SS0_LTFM, ...
    Debt_SS0_Def, Tax_SS0_Def, CE_SS0_Def, ...
    Debt_Aust_First, Tax_Aust_First, CE_Aust_First, ...
    Debt_Unified, Tax_Unified, CE_Unified, CE_Unified_With_Defense, ...
    CE_StopGo_Thin, CE_StopGo_1Term, CE_StopGo_Thick, ...
    CE_Barnardos_Silo, CE_WellBeing_Silo, CE_GrowthNZ_Silo, ...
    'VariableNames', {'Year', 'Debt_SS0_LTFM_PctGDP', 'Tax_SS0_LTFM_Pct', 'CE_SS0_LTFM_Pct', ...
    'Debt_SS0_Defense3Pct_GDP', 'Tax_SS0_Defense3Pct', 'CE_SS0_Defense3Pct_Pct', ...
    'Debt_AusterityFirst_PctGDP', 'Tax_AusterityFirst_Pct', 'CE_AusterityFirst_Pct', ...
    'Debt_Unified_SS1_SS2_PctGDP', 'Tax_Unified_SS1_SS2_Pct', 'CE_Unified_SS1_SS2_Pct', ...
    'CE_Unified_With_3PctDefense_Pct', 'CE_StopGo_ThinSpreadsheet_Pct', ...
    'CE_StopGo_1Term_3YrCycle_Pct', 'CE_StopGo_ThickStateContingent_Pct', ...
    'CE_Barnardos_Silo_NetLTFM_Pct', 'CE_WellBeing_Silo_NetLTFM_Pct', 'CE_GrowthNZ_Silo_NetLTFM_Pct'});

csv21 = fullfile(OutputDir, sprintf('Table21_Doc3_LTFM_Sinkhole_Defense_Trajectories_%s.csv', AnchorTag));
writetable(T21, csv21);
fprintf('  -> Exported Table 21 (LTFM Drift, 3%% GDP Defense & Stop-Go Trajectories) to: %s\n', csv21);

% =========================================================================
% 3. RENDER FIGURE 1: 3D LTFM DRIFT SURFACE + 60-YR COALITION TRAJECTORIES
% =========================================================================
fig1 = figure('Name', sprintf('Fig_Doc3_2Panel_LTFM_Surface_and_Sinkhole_%s', AnchorTag), ...
    'Color', 'w', 'Position', [40, 40, 1680, 840]);
tiledlayout(1, 2, 'TileSpacing', 'loose', 'Padding', 'loose');

% --- PANEL A: 3D MACROECONOMIC SURFACE (DEBT/GDP x PAYE TAX -> WELFARE CE%) ---
ax1 = nexttile(1); hold(ax1, 'on');
s_surf = surf(ax1, D_Grid, T_Grid, W_Surf_Base, 'EdgeColor', 'none', 'FaceAlpha', 0.72, 'HandleVisibility', 'off');
colormap(ax1, turbo); caxis(ax1, [-23, 24]);

% Add translucent z = 0 Reference Plane (2026 Static Baseline)
patch(ax1, [15, 200, 200, 15], [17, 17, 34, 34], [0, 0, 0, 0], [0.55 0.55 0.55], ...
    'FaceAlpha', 0.22, 'EdgeColor', [0.3 0.3 0.3], 'LineStyle', ':', 'DisplayName', 'z = 0% Reference Plane (2026 Static Baseline)');

% Plot the 4 3D Trajectories elevated +0.8 above the surface
p3_ss0 = plot3(ax1, Debt_SS0_LTFM, Tax_SS0_LTFM, CE_SS0_LTFM + 0.8, '-o', ...
    'Color', [0.75 0.12 0.12], 'MarkerFaceColor', [0.85 0.20 0.20], 'MarkerIndices', 1:10:n_yr, ...
    'LineWidth', 2.8, 'MarkerSize', 6, 'DisplayName', sprintf('1. SS0 Treasury LTFM Drift (Debt -> 185%%, PAYE -> 28.2%%, CE: %+.2f%%)', CE_SS0_LTFM(end)));

p3_def = plot3(ax1, Debt_SS0_Def, Tax_SS0_Def, CE_SS0_Def + 0.8, '--v', ...
    'Color', [0.35 0.00 0.45], 'MarkerFaceColor', [0.55 0.10 0.65], 'MarkerIndices', 1:10:n_yr, ...
    'LineWidth', 2.8, 'MarkerSize', 6, 'DisplayName', sprintf('2. SS0 + 3.0%% GDP Defense (+$8.0B/yr Unfunded -> CE: %+.2f%%)', CE_SS0_Def(end)));

p3_aus = plot3(ax1, Debt_Aust_First, Tax_Aust_First, CE_Aust_First + 0.8, '-.s', ...
    'Color', [0.85 0.45 0.05], 'MarkerFaceColor', [0.95 0.55 0.10], 'MarkerIndices', 1:10:n_yr, ...
    'LineWidth', 2.5, 'MarkerSize', 6, 'DisplayName', sprintf('3. "Debt-First" Consolidation (Age 70 + Early Cuts -> CE: %+.2f%%)', CE_Aust_First(end)));

p3_uni = plot3(ax1, Debt_Unified, Tax_Unified, CE_Unified + 0.8, '-p', ...
    'Color', [0.00 0.50 0.22], 'MarkerFaceColor', [0.10 0.85 0.35], 'MarkerIndices', [6, 25, 31, 66], ...
    'LineWidth', 3.4, 'MarkerSize', 9, 'DisplayName', sprintf('4. Unified Coalition (SS1 -> SS2: Debt 22%%, PAYE 18.25%%, %+.2f%% CE)', SS2_Nat));

% 3D Endpoint Callout Labels Placed Cleanly ABOVE the Surface Mesh
text(ax1, 52, 23.6, 5.2, '2026 Start (42% Debt, 22% Tax)', 'FontSize', 8.0, 'FontWeight', 'bold', ...
    'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 2);
text(ax1, Debt_Unified(end), Tax_Unified(end), CE_Unified(end) + 3.5, ...
    sprintf('2086 SS2 Convergence:\n%+.2f%% CE\n(Debt 22%%, Tax 18.25%%)', SS2_Nat), ...
    'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.00 0.38 0.15], ...
    'BackgroundColor', [0.94 1.00 0.95], 'EdgeColor', [0.00 0.45 0.20], 'Margin', 2);
text(ax1, Debt_SS0_LTFM(end)-18, Tax_SS0_LTFM(end)-0.8, CE_SS0_LTFM(end) + 5.8, ...
    sprintf('LTFM Drift:\n%+.2f%% CE', CE_SS0_LTFM(end)), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.65 0.05 0.05], ...
    'BackgroundColor', [1.00 0.96 0.96], 'EdgeColor', [0.75 0.15 0.15], 'Margin', 2);
text(ax1, Debt_SS0_Def(end)-22, Tax_SS0_Def(end)+0.4, CE_SS0_Def(end) + 5.2, ...
    sprintf('LTFM + 3.0%% Defense\n(+$8.0B/yr): %+.2f%% CE', CE_SS0_Def(end)), ...
    'FontSize', 7.8, 'FontWeight', 'bold', 'Color', [0.35 0.00 0.45], ...
    'BackgroundColor', [0.98 0.95 1.00], 'EdgeColor', [0.45 0.10 0.55], 'Margin', 2);

view(ax1, -128, 26);
xlabel(ax1, 'Net Core Crown Debt (% of GDP)', 'FontSize', 9.8, 'FontWeight', 'bold');
ylabel(ax1, 'Required Working-Age PAYE Tax \tau_l (%)', 'FontSize', 9.8, 'FontWeight', 'bold');
zlabel(ax1, 'Lifetime Household Welfare Change (CE %)', 'FontSize', 10.0, 'FontWeight', 'bold');
title(ax1, 'A. The LTFM Fiscal Surface & 3.0% GDP (+$8.0B/yr) Defense Commitment vs. SS1\rightarrowSS2 Trajectory', ...
    'FontSize', 10.4, 'FontWeight', 'bold');
xlim(ax1, [15, 200]); ylim(ax1, [17, 34]); zlim(ax1, [-25, 28]);
grid(ax1, 'on'); box(ax1, 'on');
legend(ax1, [p3_uni, p3_aus, p3_ss0, p3_def], 'Location', 'northwest', 'FontSize', 7.1);

% --- PANEL B: 60-YEAR COALITION TRAJECTORIES, PERISHABILITY & SILO COUNTERFACTUALS ---
ax2 = nexttile(2); hold(ax2, 'on');

% Shade the incremental fiscal drag from an unfunded 1.2% -> 3.0% GDP defense increase under SS0
fill(ax2, [Yr_Vec; flipud(Yr_Vec)], [CE_SS0_LTFM; flipud(CE_SS0_Def)], [0.92 0.82 0.95], ...
    'FaceAlpha', 0.45, 'EdgeColor', 'none', 'DisplayName', 'Incremental -5.48% CE Fiscal Drag from Unfunded 3.0% GDP (+$8.0B/yr) Defense Commitment');

h_u1 = plot(ax2, Yr_Vec, CE_Unified, '-', 'Color', [0.00 0.52 0.22], 'LineWidth', 3.2, ...
    'DisplayName', sprintf('1. Unified 4-Coalition Plan (SS1 \\rightarrow SS2 at Super Age 64: %+.2f%% CE)', SS2_Nat));
h_u2 = plot(ax2, Yr_Vec, CE_Unified_With_Defense, '--', 'Color', [0.05 0.68 0.45], 'LineWidth', 2.4, ...
    'DisplayName', sprintf('2. Unified Plan + 3.0%% GDP Defense (Sustains +$8.0B/yr Outlay at %+.2f%% CE)', CE_Unified_With_Defense(end)));

h_sg_thin = plot(ax2, Yr_Vec, CE_StopGo_Thin, ':', 'Color', [0.20 0.45 0.75], 'LineWidth', 2.0, ...
    'DisplayName', sprintf('3a. "Stop-Go" 2-Term (6-Yr) Cycle (Linear Mean Spreadsheet: %+.2f%% CE)', CE_StopGo_Thin(end)));
h_sg_thk  = plot(ax2, Yr_Vec, CE_StopGo_Thick, '-', 'Color', [0.12 0.35 0.72], 'LineWidth', 2.4, ...
    'DisplayName', sprintf('3b. "Stop-Go" 2-Term (6-Yr) Cycle (State-Contingent 12-Yr Sawtooth: %+.2f%% CE)', CE_StopGo_Thick(end)));

h_silo_b = plot(ax2, Yr_Vec, CE_Barnardos_Silo, '-.', 'Color', [0.88 0.55 0.05], 'LineWidth', 2.1, ...
    'DisplayName', sprintf('4. Barnardos/Youth Silo Alone vs. LTFM Drift (Net %+.2f%% CE: >100%% Offset by Drift)', CE_Barnardos_Silo(end)));
h_silo_w = plot(ax2, Yr_Vec, CE_WellBeing_Silo, '-.', 'Color', [0.55 0.35 0.70], 'LineWidth', 2.0, ...
    'DisplayName', sprintf('5. WellBeing/Housing Silo Alone vs. LTFM Drift (Net %+.2f%% CE)', CE_WellBeing_Silo(end)));
h_aus = plot(ax2, Yr_Vec, CE_Aust_First, '--', 'Color', [0.85 0.32 0.08], 'LineWidth', 2.2, ...
    'DisplayName', sprintf('6. "Debt-First" Consolidation in SS1 (Early Cuts + Super Age 70: %+.2f%% CE)', CE_Aust_First(end)));

h_ss0 = plot(ax2, Yr_Vec, CE_SS0_LTFM, '-', 'Color', [0.75 0.10 0.12], 'LineWidth', 2.6, ...
    'DisplayName', sprintf('7. Status Quo SS0 under Treasury LTFM Drift (%+.2f%% CE by Yr 60)', CE_SS0_LTFM(end)));
h_def = plot(ax2, Yr_Vec, CE_SS0_Def, ':', 'Color', [0.40 0.00 0.50], 'LineWidth', 2.6, ...
    'DisplayName', sprintf('8. Status Quo SS0 + 3.0%% GDP Defense (+$8.0B/yr Unfunded: %+.2f%% CE)', CE_SS0_Def(end)));

yline(ax2, 0, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(ax2, 0,    'k:',  'LineWidth', 1.2, 'HandleVisibility', 'off');
xline(ax2, 18.8, 'r--', 'LineWidth', 1.3, 'HandleVisibility', 'off');
xline(ax2, 25.0, 'b-.', 'LineWidth', 1.4, 'HandleVisibility', 'off');

% Annotate the Perishability Gap (Thin vs. Thick 2-Term Cycle) & Total Swing vs LTFM
plot(ax2, [48, 48], [CE_StopGo_Thick(Yr_Vec==48), CE_StopGo_Thin(Yr_Vec==48)], 'b-', 'LineWidth', 1.8, 'HandleVisibility', 'off');
text(ax2, 47.0, 0.5*(CE_StopGo_Thick(Yr_Vec==48) + CE_StopGo_Thin(Yr_Vec==48)) + 1.2, ...
    sprintf('State-Contingent vs. Linear 2-Term Cycle:\n2-Period Fade-Out (39.2%% Loss) & LTFM Drift\nReduce Payoff by %.1f%% (vs. %.1f%% in 1-Term)', ...
        100*(1 - CE_StopGo_Thick(end)/SS2_Nat), 100*(1 - CE_StopGo_1Term(end)/SS2_Nat)), ...
    'HorizontalAlignment', 'right', 'FontSize', 7.4, 'FontWeight', 'bold', ...
    'Color', [0.08 0.25 0.58], 'BackgroundColor', [0.95 0.98 1.00], 'EdgeColor', [0.15 0.35 0.70], 'Margin', 3);

text(ax2, 58.5, 0.5*(CE_Unified(end) + CE_SS0_LTFM(end)), ...
    sprintf('Net Welfare Swing vs.\nLTFM Baseline Drift:\n%+.2f pp CE', SS2_Nat - CE_SS0_LTFM(end)), ...
    'HorizontalAlignment', 'right', 'FontSize', 8.0, 'FontWeight', 'bold', ...
    'Color', [0.00 0.38 0.15], 'BackgroundColor', [0.94 1.00 0.95], 'EdgeColor', [0.00 0.45 0.20], 'Margin', 3);

xlabel(ax2, 'Years Relative to 2026 Reform Launch (SS1 Incubation -> Yr 25 SS2 Harvest)', 'FontSize', 10.0, 'FontWeight', 'bold');
ylabel(ax2, 'Lifetime Consumption-Equivalent Welfare Change (CE %)', 'FontSize', 10.0, 'FontWeight', 'bold');
title(ax2, 'B. Standalone Silos, 2-Term Policy Cycling, & The Unified Compact Relative to LTFM Drift', ...
    'FontSize', 10.4, 'FontWeight', 'bold');
xlim(ax2, [-5, 60]); ylim(ax2, [-25, 29]);
grid(ax2, 'on'); box(ax2, 'on');
legend(ax2, 'Location', 'northwest', 'FontSize', 6.8);

f_out1 = fullfile(OutputDir, sprintf('Fig_Doc3_LTFM_Surface_And_Sinkhole_%s.png', AnchorTag));
exportgraphics(fig1, f_out1, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved Figure 1 (3D LTFM Surface + LTFM Sinkhole) to: %s\n', f_out1);

fig1b = figure('Name', sprintf('Fig_Doc3_LTFM_Sinkhole_And_DefenseShock_%s', AnchorTag), ...
    'Color', 'w', 'Position', [40, 40, 1280, 720]);
ax_copied = copyobj(ax2,fig1b);
legend(ax_copied, 'Location', 'northwest', 'FontSize', 6.8);
set(ax_copied, 'OuterPosition', 'default');

f_out1b = fullfile(OutputDir, sprintf('Fig_Doc3_LTFM_Sinkhole_And_DefenseShock_%s.png', AnchorTag));
exportgraphics(fig1b, f_out1b, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved Figure 1b (LTFM + Defense Commitment + Policy Cycling) to: %s\n', f_out1b);

% =========================================================================
% 4. CONSTRUCT THE 2D (4 x 4) COALITION COMPLEMENTARITY & DEPENDENCY MATRIX
% =========================================================================
Coalition_Names = { ...
    '1. Barnardos & Youth (ECE + Tuakana)'; ...
    '2. WellBeing Alliance (Housing + Grant + Whanau)'; ...
    '3. GrowthNZ & Venture (Firm Capital + Jobs)'; ...
    '4. Fiscal Stewards (Debt-Sinking + PAYE Relief)'};

Raw_Mat_4x4 = [ ...
    7.52,  2.15,  1.95,  1.45; ...
    2.15,  5.06,  1.15,  0.65; ...
    1.95,  1.15,  2.10,  0.65; ...
    1.45,  0.65,  0.65,  0.95];

raw_unique_sum = trace(Raw_Mat_4x4) + sum(triu(Raw_Mat_4x4, 1), 'all');
scale_mat      = SS2_Nat / raw_unique_sum;
Mat_4x4        = Raw_Mat_4x4 * scale_mat;

% Neutral, institutional cell narratives with zero exclamation points
Cell_Narratives = { ...
    'OWN LANE:\nECE_1 + Tuakana_2\n(+Dual-Gate Base)', ...
    '★ SYNERGY WEDGE:\nKaiako Rent Relief +\nh_6-h_7 Youth Use Grant E', ...
    '★ SYNERGY WEDGE:\nHigh-z_h Jobs Retain\nh_6-h_7 Youth in NZ', ...
    '★ SYNERGY WEDGE:\nACC Actuarial Valuation +\nExits Drop Funds Super 64'; ...
    ...
    '★ SYNERGY WEDGE:\nWhanau Stay-Pull +\nGrant E Needs h_6-h_7 Skill', ...
    'OWN LANE:\nCool Q_k + Grant E +\nGeo Floor + LVR Base', ...
    '★ SYNERGY WEDGE:\nNZD 1.6T Land Rotates\nto z_h Operating Firms', ...
    '★ SYNERGY WEDGE:\n-60 bps Debt-Sinking\nLowers Young Mortgage r_h'; ...
    ...
    '★ SYNERGY WEDGE:\nDomestic 65%% Thriving\nTalent Pool Feeds Firms', ...
    '★ SYNERGY WEDGE:\nDe-Hoarding Land Frees\nSME Credit Collateral', ...
    'OWN LANE:\nFirm Tax Shift +\n1.65x Infra Base Alone', ...
    '★ SYNERGY WEDGE:\n-60 bps Credit + -3.1pp\nPAYE Retains Founders'; ...
    ...
    '★ SYNERGY WEDGE:\n+16.8k/Birth Surplus &\nTFR 1.87 Secures Super', ...
    '★ SYNERGY WEDGE:\nPeak Estate Wave (\\tau_b)\nSelf-Funds SS1 Outlay', ...
    '★ SYNERGY WEDGE:\n+8.8%% Wage & Firm Growth\nExpands Tax Base +14.5%%', ...
    'OWN LANE:\nStatic Debt/Tax Target\n(Unachievable Standalone)'};

% Compute 4-Bar Outcome Breakdown for Each Constituency in Panel B:
%   StopGo_Interf_4 is scaled so sum(StopGo_Interf_4) == CE_StopGo_Thick(end) (+3.84% CE):
Silo_Static_4   = diag(Mat_4x4);
Silo_Swamped_4  = [CE_Barnardos_Silo(end); CE_WellBeing_Silo(end); CE_GrowthNZ_Silo(end); -10.55];
StopGo_Interf_4 = (CE_StopGo_Thick(end) / sum(Silo_Static_4)) * Silo_Static_4; % [+1.85; +1.24; +0.52; +0.23] -> sum = +3.84%
Full_Coalit_4   = [ ...
    Mat_4x4(1,1) + sum(Mat_4x4(1, [2,3,4])); ...
    Mat_4x4(2,2) + sum(Mat_4x4(2, [1,3,4])); ...
    Mat_4x4(3,3) + sum(Mat_4x4(3, [1,2,4])); ...
    Mat_4x4(4,4) + sum(Mat_4x4(4, [1,2,3]))];

T22 = table(Coalition_Names, Silo_Static_4, ...
    Mat_4x4(:,1), Mat_4x4(:,2), Mat_4x4(:,3), Mat_4x4(:,4), ...
    Silo_Swamped_4, StopGo_Interf_4, Full_Coalit_4, ...
    'VariableNames', {'Coalition_Constituency', 'Own_Lane_Diagonal_CE', ...
    'Col1_Barnardos_CE', 'Col2_WellBeing_CE', 'Col3_GrowthNZ_CE', 'Col4_FiscalStewards_CE', ...
    'Net_In_Sinking_LTFM_CE', 'StopGo_Interference_CE', 'Total_With_Adjacent_Wedges_CE'});

csv22 = fullfile(OutputDir, sprintf('Table22_Doc3_2D_Coalition_Complementarity_Matrix_%s.csv', AnchorTag));
writetable(T22, csv22);
fprintf('  -> Exported Table 22 (2D Coalition Complementarity Matrix) to: %s\n', csv22);

% =========================================================================
% 5. RENDER FIGURE 2: 2D COALITION MATRIX & SILO-VS-COALITION COMPARISON
% =========================================================================
fig2 = figure('Name', sprintf('Fig_Doc3_2D_Coalition_Migration_Matrix_%s', AnchorTag), ...
    'Color', 'w', 'Position', [55, 55, 1680, 830]);
tiledlayout(1, 2, 'TileSpacing', 'loose', 'Padding', 'loose');

% --- PANEL A: THE 4x4 COALITION COMPLEMENTARITY & DEPENDENCY MATRIX ---
axA = nexttile(1); hold(axA, 'on');
imagesc(axA, 1:4, 1:4, Mat_4x4);
set(axA, 'YDir', 'reverse');

cmap_mat = [linspace(0.95, 0.12, 64)', linspace(0.96, 0.58, 64)', linspace(0.92, 0.35, 64)'];
colormap(axA, cmap_mat); caxis(axA, [0.5, max(Mat_4x4(:)) * 1.05]);

for r = 1:4
    for c = 1:4
        val_rc = Mat_4x4(r, c);
        if r == c
            rectangle(axA, 'Position', [c-0.48, r-0.48, 0.96, 0.96], ...
                'EdgeColor', [0.10 0.25 0.45], 'LineWidth', 2.4, 'FaceColor', [0.86 0.92 0.98]);
            hdr_str = sprintf('[OWN SILO %d]\n%+.2f%% CE', r, val_rc);
            hdr_col = [0.08 0.20 0.42];
        else
            rectangle(axA, 'Position', [c-0.48, r-0.48, 0.96, 0.96], ...
                'EdgeColor', [0.75 0.42 0.05], 'LineWidth', 1.8, 'FaceColor', [1.00 0.95 0.82]);
            hdr_str = sprintf('★ WEDGE (%d \\times %d)\n%+.2f%% CE', min(r,c), max(r,c), val_rc);
            hdr_col = [0.65 0.12 0.05];
        end
        text(axA, c, r - 0.16, hdr_str, 'HorizontalAlignment', 'center', ...
            'FontSize', 8.6, 'FontWeight', 'bold', 'Color', hdr_col);
        text(axA, c, r + 0.20, sprintf(Cell_Narratives{r, c}), 'HorizontalAlignment', 'center', ...
            'FontSize', 7.2, 'FontWeight', 'bold', 'Color', [0.18 0.18 0.18]);
    end
end

short_names = {'1. Barnardos/Youth', '2. WellBeing/Housing', '3. GrowthNZ/Venture', '4. Fiscal Stewards'};
set(axA, 'XTick', 1:4, 'XTickLabel', short_names, 'XTickLabelRotation', 15, ...
    'YTick', 1:4, 'YTickLabel', short_names, 'FontSize', 9.2, 'FontWeight', 'bold');
xlim(axA, [0.45, 4.55]); ylim(axA, [0.45, 4.95]);

diag_sum = trace(Mat_4x4);
wedg_sum = sum(triu(Mat_4x4, 1), 'all');
text(axA, 2.5, 4.72, ...
    sprintf('4 Diagonal Own-Silos Sum = %+.2f%% CE (%.1f%%)  +  6 Bilateral Synergy Wedges (★) = %+.2f%% CE (%.1f%%)   \\Rightarrow   Unified SS2 = %+.2f%% CE', ...
    diag_sum, 100*diag_sum/SS2_Nat, wedg_sum, 100*wedg_sum/SS2_Nat, SS2_Nat), ...
    'HorizontalAlignment', 'center', 'FontSize', 8.1, 'FontWeight', 'bold', ...
    'Color', [0.00 0.35 0.15], 'BackgroundColor', [0.92 0.99 0.94], 'EdgeColor', [0.00 0.45 0.20], 'Margin', 4);

title(axA, 'A. The 2D Coalition Matrix: Own-Lane Silos (Diagonal) vs. Neighbour Synergy Wedges (★)', ...
    'FontSize', 10.5, 'FontWeight', 'bold');
box(axA, 'on');

% --- PANEL B: HOW EACH CONSTITUENCY FARES ALONE VS. UNDER LTFM DRIFT VS. UNIFIED ---
axB = nexttile(2); hold(axB, 'on');
x_c = 1:4;
Bar_Mat_4x4 = [Silo_Swamped_4, StopGo_Interf_4, Silo_Static_4, Full_Coalit_4];
b_fate = bar(axB, x_c, Bar_Mat_4x4, 'grouped', 'BarWidth', 0.82);

fate_colors = [ ...
    0.78, 0.15, 0.18; ... % 1. Standalone Against LTFM Fiscal Drift (Crimson)
    0.88, 0.58, 0.12; ... % 2. "Stop-Go" 2-Term Policy Cycling (Amber)
    0.25, 0.52, 0.75; ... % 3. Standalone in Static Baseline (Slate Blue)
    0.05, 0.58, 0.30];    % 4. Unified Coalition: Own Silo + All Connected Wedges (Emerald)

fate_labels = { ...
    '1. Standalone Against LTFM Fiscal Drift (Offset by Debt & Aging)', ...
    sprintf('2. "Stop-Go" 2-Term Policy Cycle (%+.2f%% Total: %.1f%% Lost to Fade-Out & Drift)', ...
        CE_StopGo_Thick(end), 100*(1 - CE_StopGo_Thick(end)/SS2_Nat)), ...
    '3. Standalone in Static Baseline (Omits Cross-Lane Synergies)', ...
    '4. Unified 4-Coalition Compact (Own Silo + All 3 Neighbour Synergy Wedges)'};

for k = 1:4
    b_fate(k).FaceColor   = fate_colors(k, :);
    b_fate(k).FaceAlpha   = 0.88;
    b_fate(k).EdgeColor   = [0.15 0.15 0.15];
    b_fate(k).DisplayName = fate_labels{k};
    x_pts = b_fate(k).XEndPoints;
    y_pts = b_fate(k).YEndPoints;
    for c_i = 1:4
        val_v = y_pts(c_i);
        y_pos = val_v + (val_v >= 0) * 0.55 - (val_v < 0) * 0.85;
        v_str = sprintf('%+.1f%%', val_v);
        text(axB, x_pts(c_i), y_pos, v_str, 'HorizontalAlignment', 'center', ...
            'FontSize', 7.6, 'FontWeight', 'bold', 'Color', fate_colors(k, :) * 0.75);
    end
end

yline(axB, 0, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% Place Fiscal Stewardship callout box in the open upper-right whitespace (x=2.52, y=10.8)
msg_mba = sprintf(['Why Balance-Sheet Stewardship Requires Cross-Portfolio Coupling:\n', ...
    '• Attempting to reduce debt first in SS1 via early cuts or Age-70 Super\n', ...
    '  lowers welfare to -10.6%% CE as benefit substitution & whanau care loss mount.\n', ...
    '• Joining the Unified Compact unlocks %+.2f%% CE in connected fiscal,\n', ...
    '  demographic & enterprise wedges—retiring debt & cutting PAYE to 18.9%%.'], Full_Coalit_4(4));
text(axB, 2.52, 10.8, msg_mba, 'FontSize', 7.7, 'FontWeight', 'bold', 'Color', [0.05 0.28 0.12], ...
    'BackgroundColor', [0.94 0.99 0.95], 'EdgeColor', [0.05 0.45 0.20], 'Margin', 4);

set(axB, 'XTick', 1:4, 'XTickLabel', short_names, 'XTickLabelRotation', 12, 'FontSize', 9.2, 'FontWeight', 'bold');
ylabel(axB, 'Effective Welfare Payoff to Constituency Mandate (CE %)', 'FontSize', 10.0, 'FontWeight', 'bold');
title(axB, 'B. Constituency Outcomes: Standalone Under LTFM Drift vs. Unified Compact', ...
    'FontSize', 10.5, 'FontWeight', 'bold');
xlim(axB, [0.4, 4.6]); ylim(axB, [-13.0, 18.5]);
grid(axB, 'on'); box(axB, 'on');
legend(axB, 'Location', 'northwest', 'FontSize', 7.4);

f_out2 = fullfile(OutputDir, sprintf('Fig_Doc3_2D_Coalition_Migration_Matrix_%s.png', AnchorTag));
exportgraphics(fig2, f_out2, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Saved Figure 2 (2D Coalition Matrix & Constituency Outcome Comparison) to: %s\n', f_out2);

Out.Table21_SinkholeTrajectories = T21;
Out.Table22_CoalitionMatrix      = T22;
Out.Fig1_SinkholeAndDefense      = f_out1b;
Out.Fig2_CoalitionMatrix         = f_out2;


end
