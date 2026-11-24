function Out = Plot_ThickVsThin_Assembly_Auction(Params, Opts)
%% PLOT_THICKVSTHIN_ASSEMBLY_AUCTION (DOCUMENTS 2T, 2B SEC 7.7.4, & 1F)
% Cross-platform (MATLAB HG2 & GNU Octave) 4-panel dashboard:
%   Panel A (NW): 1972 (1/16x) -> 2026 (1x) Backlog Bifurcation + 30%/50% Synergy Haircuts
%   Panel B (NE): SOE Shock Telemetry (Green / Amber / Red + 30% Haircut Resilience)
%   Panel C (SW): 8-Spoke Symmetric Persona Radar (Closure % & Welfare % on [0, 100] Scale)
%   Panel D (SE): Stated Ambition vs Realized Trajectory (Cash-Basis Bias vs Fragile Silo Deal)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Ensure_Workbench_Initialized();
end
if nargin < 2 || isempty(Opts)
    Opts = struct();
end

OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
AnchorTag = Params.Calibration_Anchor;

ABM = Compute_ThickVsThin_Auction_ABM(Params, Opts);
H   = ABM.Homotopy;
R   = ABM.Radar;
U   = ABM.Unravel;

%% 1. Export Reproducible CSV Ledgers
csv_hom = fullfile(OutputDir, sprintf('Table_Doc2T_BacklogHomotopy_1972to2026_%s.csv', AnchorTag));
fid = fopen(csv_hom, 'w');
fprintf(fid, 'Backlog_Multiple_Psi,Thin_Nominal_Pct,Thin_Viable_Pct,Thin_FoolsGold_Pct,Thick_Viable_Pct,Thick_Haircut30_Pct,Thick_Haircut50_Pct,Thin_Mean_CE_pp,Thick_Mean_CE_pp\n');
hom_mat = [H.psi_grid, H.Thin_Nominal_Pct, H.Thin_Viable_Pct, H.Thin_FoolsGold_Pct, ...
           H.Thick_Viable_Pct, H.Thick_Haircut30_Pct, H.Thick_Haircut50_Pct, H.Thin_Mean_CE, H.Thick_Mean_CE];
fprintf(fid, '%.4f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n', hom_mat');
fclose(fid);

csv_arch = fullfile(OutputDir, sprintf('Table_Doc2T_ThickVsThin_Archetypes_%s.csv', AnchorTag));
fid = fopen(csv_arch, 'w');
fprintf(fid, 'Archetype,Thin_Nominal_Pct,Thin_Viable_Pct,Thin_FoolsGold_Pct,Thick_Viable_Pct,Thick_Haircut30_Viable_Pct,Thin_Mean_CE_pp,Thick_Mean_CE_pp,Thick_Haircut30_CE_pp\n');
for k = 1:4
    st = ABM.Arch_Stats(k, :);
    fprintf(fid, '"%s",%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n', ...
        ABM.Archetype_Names{k}, st(1), st(2), st(7), st(4), st(9), st(5), st(6), st(10));
end
fclose(fid);

csv_shk = fullfile(OutputDir, sprintf('Table_Doc2T_ThickVsThin_ShockSurvival_%s.csv', AnchorTag));
fid = fopen(csv_shk, 'w');
fprintf(fid, 'Lambda_Sigma,Thin2026_Survive_Pct,ThinQuarterBacklog_Survive_Pct,Thick2026_Green_Pct,Thick2026_Amber_Pct,ThickHaircut30_Survive_Pct\n');
shk_mat = [ABM.lambda_vec, ...
           ABM.Shock_Out.Green_Thin_Mean + ABM.Shock_Out.Amber_Thin_Mean, ...
           ABM.Shock_Out.Survive_Thin_Qtr, ...
           ABM.Shock_Out.Green_Thick_Mean, ABM.Shock_Out.Amber_Thick_Mean, ABM.Shock_Out.Survive_Thick_Hair30];
fprintf(fid, '%.3f,%.2f,%.2f,%.2f,%.2f,%.2f\n', shk_mat');
fclose(fid);

%% 2. Render 4-Panel Sans-Serif Publication Figure
vis_m = IGW_UI_Style('headless_vis');
fig = figure('Visible', vis_m, 'Color', 'w', ...
    'Units', 'pixels', 'Position', [50, 50, 1580, 1040], ...
    'PaperUnits', 'inches', 'PaperSize', [15.8, 10.4], 'PaperPosition', [0, 0, 15.8, 10.4]);

c_thick_dk = [0.05, 0.43, 0.35]; % Deep Pounamu / Teal
c_thick_30 = [0.14, 0.63, 0.50]; % Emerald (30% CBAx Haircut)
c_thick_50 = [0.22, 0.50, 0.72]; % Steel Blue (50% Skeptic Haircut)
c_thin_red = [0.78, 0.19, 0.18]; % Brick Red
c_thin_qtr = [0.55, 0.25, 0.68]; % Plum (Fragile / 1/4x Reference)
c_fool_amb = [0.86, 0.53, 0.08]; % Fool's Gold / Paper Claim Ochre
c_amber    = [0.93, 0.68, 0.16]; % Telemetry Amber
c_green    = [0.16, 0.64, 0.38]; % Telemetry Green
c_red      = [0.80, 0.22, 0.22]; % Telemetry Red

pos_NW     = [0.070, 0.565, 0.400, 0.365];
pos_NE     = [0.555, 0.565, 0.292, 0.365];
pos_NE_leg = [0.856, 0.595, 0.136, 0.300];
pos_SW     = [0.055, 0.065, 0.425, 0.415];
pos_SE     = [0.555, 0.085, 0.400, 0.365];

%% ========================================================================
%  PANEL A (NW): 1972 (1/16x) -> 2026 (1x) Backlog Bifurcation + Haircuts
%  ========================================================================
ax1 = axes('Parent', fig, 'Position', pos_NW);
vfi_active_ax(ax1);
hold(ax1, 'on');
set(ax1, 'FontName', 'Helvetica', 'FontSize', 9.5, 'Box', 'on');

x_log2 = log2(H.psi_grid);
fill(ax1, [x_log2; flipud(x_log2)], [H.Thick_Viable_Pct; flipud(H.Thin_Viable_Pct)], ...
    c_thick_30, 'FaceAlpha', 0.11, 'EdgeColor', 'none');

plot(ax1, x_log2, H.Thick_Viable_Pct,    '-',  'Color', c_thick_dk, 'LineWidth', 2.8, ...
    'Marker', 'o', 'MarkerSize', 4.8, 'MarkerFaceColor', c_thick_dk);
plot(ax1, x_log2, H.Thick_Haircut30_Pct, '-.', 'Color', c_thick_30, 'LineWidth', 2.4);
plot(ax1, x_log2, H.Thick_Haircut50_Pct, '-',  'Color', c_thick_50, 'LineWidth', 2.1, ...
    'Marker', '^', 'MarkerSize', 4.5, 'MarkerFaceColor', c_thick_50);
plot(ax1, x_log2, H.Thin_Nominal_Pct,    ':',  'Color', c_fool_amb, 'LineWidth', 2.2);
plot(ax1, x_log2, H.Thin_Viable_Pct,     '--', 'Color', c_thin_red, 'LineWidth', 2.8, ...
    'Marker', 's', 'MarkerSize', 4.8, 'MarkerFaceColor', c_thin_red);

set(ax1, 'XTick', [-4, -3, -2, -1, 0], ...
    'XTickLabel', {'1/16x (1972)', '1/8x (~1982)', '1/4x (~1995)', '1/2x (~2010)', '1.0x (2026)'});
xlim(ax1, [-4.15, 0.15]);
ylim(ax1, [0, 108]);
xlabel(ax1, 'Accumulated Deferred-Maintenance & Housing Backlog (ψ Multiplier)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax1, 'Viable 15/15 Compact Closure (%)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
title(ax1, 'A. 1972 -> 2026 Bifurcation & Synergy-Haircut Stress-Test', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 10.8, 'FontWeight', 'bold');

Items1 = { ...
    '-',  c_thick_dk, 2.5, 'o',    'Thick Clearinghouse (Canonical Synergies)'; ...
    '-.', c_thick_30, 2.3, 'none', 'Thick w/ 30% CBAx Synergy Haircut (Stress-Test)'; ...
    '-',  c_thick_50, 2.0, '^',    'Thick w/ 50% Severe Synergy Haircut'; ...
    ':',  c_fool_amb, 2.2, 'none', 'Thin Nominal Closure ("Fool''s Gold" Cash Mirage)'; ...
    '--', c_thin_red, 2.5, 's',    'Thin Viable Closure (Works in 1972, Fails by 2026)'};
igw_smart_incanvas_legend(ax1, Items1, struct('PreferLocs', {{'southwest'}}, 'FontSize', 6.8));
grid(ax1, 'on');

%% ========================================================================
%  PANEL B (NE): SOE Shock Telemetry (Green / Amber / Red + 30% Haircut)
%  ========================================================================
ax2 = axes('Parent', fig, 'Position', pos_NE);
vfi_active_ax(ax2);
hold(ax2, 'on');
set(ax2, 'FontName', 'Helvetica', 'FontSize', 9.5, 'Box', 'on');

lam   = ABM.lambda_vec;
g_tk  = ABM.Shock_Out.Green_Thick_Mean;
ga_tk = g_tk + ABM.Shock_Out.Amber_Thick_Mean;

fill(ax2, [lam; flipud(lam)], [zeros(size(lam)); flipud(g_tk)], ...
    c_green, 'FaceAlpha', 0.28, 'EdgeColor', 'none');
fill(ax2, [lam; flipud(lam)], [g_tk; flipud(ga_tk)], ...
    c_amber, 'FaceAlpha', 0.32, 'EdgeColor', 'none');
fill(ax2, [lam; flipud(lam)], [ga_tk; 100 * ones(size(lam))], ...
    c_red,   'FaceAlpha', 0.14, 'EdgeColor', 'none');

plot(ax2, lam, ga_tk, '-', 'Color', c_thick_dk, 'LineWidth', 2.8);
plot(ax2, lam, ABM.Shock_Out.Survive_Thick_Hair30, '-.', 'Color', c_thick_50, 'LineWidth', 2.3);
plot(ax2, lam, ABM.Shock_Out.Survive_Thin_Qtr,     ':',  'Color', c_thin_qtr, 'LineWidth', 2.3);
plot(ax2, lam, ABM.Shock_Out.Green_Thin_Mean + ABM.Shock_Out.Amber_Thin_Mean, ...
    '--', 'Color', c_thin_red, 'LineWidth', 2.6);

xlim(ax2, [0, 2.50]);
ylim(ax2, [0, 105]);
set(ax2, 'XTick', 0:0.5:2.5);
xlabel(ax2, 'SOE Shock Severity λ (Std. Dev.)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax2, 'Compacts Avoiding Plenary Recall (%)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
title(ax2, 'B. Shock Resilience: Green + Amber Buffers vs Thin Collapse', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 10.6, 'FontWeight', 'bold');
grid(ax2, 'on');

% Frameless external right-hand legend for Panel B (packed cleanly right, zero border box)
ax2L = axes('Parent', fig, 'Position', pos_NE_leg, 'XLim', [0, 1], 'YLim', [0, 1], ...
    'Color', 'none', 'Visible', 'off', 'XTick', [], 'YTick', []);
hold(ax2L, 'on');

b_leg = { ...
    'line', '-',  c_thick_dk, 'Thick 2026 Surviving',    'Green + Amber Total'; ...
    'line', '-.', c_thick_50, 'Thick (-30% Haircut)',    'Stress-Test Survival'; ...
    'bar',  '',   c_green,    'GREEN: Self-Clearing',    'SOE & 2.93x Exergy'; ...
    'bar',  '',   c_amber,    'AMBER: Auto-Remedy',      'Two-Key Stabilizers'; ...
    'line', ':',  c_thin_qtr, 'Thin (1/4x Backlog)',     '~1995 Shock Decay'; ...
    'line', '--', c_thin_red, 'Thin (2026 Backlog)',     'Immediate Collapse'};

n_bl = size(b_leg, 1);
for ib = 1:n_bl
    yc = 0.91 - (ib - 1) * 0.158;
    if strcmp(b_leg{ib, 1}, 'bar')
        patch(ax2L, [0.00, 0.16, 0.16, 0.00], [yc - 0.028, yc - 0.028, yc + 0.028, yc + 0.028], ...
            b_leg{ib, 3}, 'FaceAlpha', 0.45, 'EdgeColor', b_leg{ib, 3} * 0.75, 'LineWidth', 0.7);
    else
        plot(ax2L, [0.00, 0.16], [yc, yc], b_leg{ib, 2}, 'Color', b_leg{ib, 3}, 'LineWidth', 2.4);
    end
    text(ax2L, 0.20, yc + 0.020, b_leg{ib, 4}, 'Interpreter', 'none', ...
        'FontName', 'Helvetica', 'FontSize', 7.2, 'FontWeight', 'bold', 'Color', [0.12, 0.16, 0.22]);
    text(ax2L, 0.20, yc - 0.028, b_leg{ib, 5}, 'Interpreter', 'none', ...
        'FontName', 'Helvetica', 'FontSize', 6.7, 'Color', [0.38, 0.44, 0.50]);
end

%% ========================================================================
%  PANEL C (SW): 8-Spoke Symmetric Persona Radar (Closure % & Welfare %)
%  ========================================================================
ax3 = axes('Parent', fig, 'Position', pos_SW);
vfi_active_ax(ax3);
hold(ax3, 'on');
axis(ax3, 'equal');
set(ax3, 'Visible', 'off', 'XLim', [-1.68, 1.68], 'YLim', [-1.56, 1.48]);

% 8 symmetric angles starting at North (pi/2) stepping clockwise by 45 degrees
theta_8 = (pi/2) - (0:7) * (2*pi / 8);
theta_c = [theta_8, theta_8(1)];

% Draw concentric web rings w/ dual [Closure % | +CE pp] radial scale ticks
th_ring = linspace(0, 2*pi, 121);
for rr = [0.25, 0.50, 0.75, 1.00]
    lw_r  = 0.7 + 0.5 * (rr == 1.00);
    col_r = [0.80, 0.84, 0.88] - 0.12 * (rr == 1.00);
    plot(ax3, rr * cos(th_ring), rr * sin(th_ring), '-', 'Color', col_r, 'LineWidth', lw_r);
    % Cardinal vertical tick = Closure %; 22.5-deg diagonal tick = Absolute CE (pp)
    text(ax3, -0.03, rr + 0.035, sprintf('%d%%', round(rr * 100)), ...
        'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.0, ...
        'HorizontalAlignment', 'right', 'Color', [0.36, 0.41, 0.47]);
    text(ax3, 0.03, rr + 0.035, sprintf('+%.1fpp', rr * 24.70), ...
        'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.0, ...
        'HorizontalAlignment', 'left', 'Color', [0.05, 0.40, 0.32]);
end

% Draw 8 radial spokes (Vectorized [2 x 8] segment matrix)
X_spokes = [zeros(1, 8); 1.03 * cos(theta_8)];
Y_spokes = [zeros(1, 8); 1.03 * sin(theta_8)];
plot(ax3, X_spokes, Y_spokes, '-', 'Color', [0.76, 0.80, 0.85], 'LineWidth', 0.85);

% Plot the 4 symmetric 8-vertex polygons (every regime has identical 8 dimensions!)
p_mir = [R.Poly_Thin_Mirage,  R.Poly_Thin_Mirage(1)]  / 100.0;
p_thr = [R.Poly_Thin_Reality, R.Poly_Thin_Reality(1)] / 100.0;
p_h30 = [R.Poly_Thick_Hair30, R.Poly_Thick_Hair30(1)] / 100.0;
p_tkc = [R.Poly_Thick_Canon,  R.Poly_Thick_Canon(1)]  / 100.0;

patch(ax3, p_tkc .* cos(theta_c), p_tkc .* sin(theta_c), c_thick_dk, 'FaceAlpha', 0.16, 'EdgeColor', 'none');
patch(ax3, p_mir .* cos(theta_c), p_mir .* sin(theta_c), c_fool_amb, 'FaceAlpha', 0.12, 'EdgeColor', 'none');

plot(ax3, p_tkc .* cos(theta_c), p_tkc .* sin(theta_c), '-',  'Color', c_thick_dk, 'LineWidth', 2.7, ...
    'Marker', 'o', 'MarkerSize', 4.8, 'MarkerFaceColor', c_thick_dk);
plot(ax3, p_h30 .* cos(theta_c), p_h30 .* sin(theta_c), '-.', 'Color', c_thick_30, 'LineWidth', 2.2);
plot(ax3, p_mir .* cos(theta_c), p_mir .* sin(theta_c), ':',  'Color', c_fool_amb, 'LineWidth', 2.3, ...
    'Marker', 'd', 'MarkerSize', 4.2, 'MarkerFaceColor', c_fool_amb);
plot(ax3, p_thr .* cos(theta_c), p_thr .* sin(theta_c), '--', 'Color', c_thin_red, 'LineWidth', 2.6, ...
    'Marker', 's', 'MarkerSize', 4.5, 'MarkerFaceColor', c_thin_red);

% Spoke labels showing both metric role & realized CE% on the 4 Welfare spokes
spoke_txt = { ...
    'Laggards: Closure %', ...
    sprintf('Laggards: CE (%.0f%%=+%.1fpp)', R.Poly_Thick_Canon(2), ABM.Arch_Stats(1,6)), ...
    'Silo-Max: Closure %', ...
    sprintf('Silo-Max: CE (%.0f%%=+%.1fpp)', R.Poly_Thick_Canon(4), ABM.Arch_Stats(2,6)), ...
    'Cost-Hawks: Closure %', ...
    sprintf('Cost-Hawks: CE (%.0f%%=+%.1fpp)', R.Poly_Thick_Canon(6), ABM.Arch_Stats(3,6)), ...
    'Coop: Closure %', ...
    sprintf('Coop: CE (%.0f%%=+%.1fpp)', R.Poly_Thick_Canon(8), ABM.Arch_Stats(4,6))};

r_lbl = [1.14, 1.17, 1.14, 1.17, 1.15, 1.18, 1.14, 1.17];
for s = 1:8
    ang = theta_8(s);
    lx  = r_lbl(s) * cos(ang);
    ly  = r_lbl(s) * sin(ang);
    if abs(cos(ang)) < 0.20
        ha = 'center';
    elseif cos(ang) > 0
        ha = 'left';
    else
        ha = 'right';
    end
    col_s = [0.12, 0.16, 0.22];
    if mod(s, 2) == 0, col_s = [0.05, 0.36, 0.30]; end
    text(ax3, lx, ly, spoke_txt{s}, 'Interpreter', 'none', 'FontName', 'Helvetica', ...
        'FontSize', 8.1, 'FontWeight', 'bold', 'HorizontalAlignment', ha, 'Color', col_s);
end

text(ax3, 0.0, 1.40, 'C. Symmetric Persona Radar: Closure % & Welfare (% of +24.7pp Frontier)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 10.6, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Color', [0.08, 0.12, 0.16]);

% Explicit dual-unit scale key + 2x2 legend strip below the radar web
text(ax3, 0.0, -1.23, 'Ring Scale — Cardinal Spokes: Closure (0–100%)  |  Diagonal Spokes: Welfare (0 to +24.7 pp CE)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.2, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Color', [0.24, 0.30, 0.36]);
leg_y1 = -1.36; leg_y2 = -1.49;
plot(ax3, [-1.62, -1.46], [leg_y1, leg_y1], '-',  'Color', c_thick_dk, 'LineWidth', 2.6);
text(ax3, -1.42, leg_y1, 'Thick Canonical (Closure & CE)', 'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.6);
plot(ax3, [0.22,  0.38],  [leg_y1, leg_y1], '-.', 'Color', c_thick_30, 'LineWidth', 2.2);
text(ax3, 0.42,  leg_y1, 'Thick w/ 30% CBAx Haircut', 'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.6);
plot(ax3, [-1.62, -1.46], [leg_y2, leg_y2], ':',  'Color', c_fool_amb, 'LineWidth', 2.3);
text(ax3, -1.42, leg_y2, 'Thin Cash Mirage (Low Real CE)', 'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.6);
plot(ax3, [0.22,  0.38],  [leg_y2, leg_y2], '--', 'Color', c_thin_red, 'LineWidth', 2.5);
text(ax3, 0.42,  leg_y2, 'Thin 2026 Reality (0% Viable)', 'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.6);

%% ========================================================================
%  PANEL D (SE): Day-1 Ambition vs Time-to-Unraveling (Years 0..6 Clock)
%  ========================================================================
ax4 = axes('Parent', fig, 'Position', pos_SE);
vfi_active_ax(ax4);
hold(ax4, 'on');
set(ax4, 'FontName', 'Helvetica', 'FontSize', 9.5, 'Box', 'on');

ty = U.t_yr;
% Shade below-zero net national deterioration zone (2024->2026 empirical unraveling)
fill(ax4, [0; 6; 6; 0], [-65; -65; 0; 0], c_red, 'FaceAlpha', 0.08, 'EdgeColor', 'none');
plot(ax4, [0, 6], [0, 0],   '-',  'Color', [0.45, 0.50, 0.56], 'LineWidth', 1.1);
plot(ax4, [2, 2], [-65, 125], ':', 'Color', [0.35, 0.40, 0.48], 'LineWidth', 1.3);

plot(ax4, ty, U.Thick_Canon,  '-',  'Color', c_thick_dk, 'LineWidth', 2.8);
plot(ax4, ty, U.Thick_Hair30, '-.', 'Color', c_thick_30, 'LineWidth', 2.2);
plot(ax4, ty, U.Paper_Claim,  ':',  'Color', c_fool_amb, 'LineWidth', 2.2);
plot(ax4, ty, U.Fragile_Thin, '-',  'Color', c_thin_qtr, 'LineWidth', 2.3);
plot(ax4, ty, U.CashBias_2024, '--', 'Color', c_thin_red, 'LineWidth', 2.8);

% Highlight the Year-2 (2024 -> 2026) Outturn Marker in neutral institutional voice
plot(ax4, 2.0, U.Yr2_CashBias, 'o', 'Color', c_thin_red, 'MarkerFaceColor', c_thin_red, 'MarkerSize', 6.4);
text(ax4, 1.92, U.Yr2_CashBias + 7.5, ...
    'Yr 2 (2026 Outturn): Credit/FX Strain, Acute ER & SME Arrears', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.5, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'Color', c_thin_red);

xlim(ax4, [0, 6.0]);
ylim(ax4, [-70, 125]);
set(ax4, 'XTick', 0:6, 'XTickLabel', {'Yr 0 (2024)', 'Yr 1', 'Yr 2 (2026)', 'Yr 3 (Elec)', 'Yr 4', 'Yr 5 (Audit)', 'Yr 6'});
xlabel(ax4, 'Years After Budget / Compact Enactment (Two-Term Clock)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
ylabel(ax4, 'Stated Ambition Attainment (100 = Target, <0 = Net Erosion)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 9.5, 'FontWeight', 'bold');
title(ax4, 'D. Stated Ambition vs Outturn: Cash-Basis Bias & Fragile Deals', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 10.7, 'FontWeight', 'bold');

% Compact legend box shifted right (x in [2.95, 5.90], y in [20, 72]) -> wide clearance from purple & green curves!
patch(ax4, [2.95, 5.90, 5.90, 2.95], [20, 20, 72, 72], [1.0, 1.0, 1.0], ...
    'FaceAlpha', 0.94, 'EdgeColor', [0.62, 0.66, 0.72], 'LineWidth', 0.70);
d_rows_y = [65.8, 55.9, 46.0, 36.1, 26.2];
d_styles = {'-', '-.', ':', '-', '--'};
d_cols   = {c_thick_dk, c_thick_30, c_fool_amb, c_thin_qtr, c_thin_red};
d_labels = { ...
    'Thick Compact (3.84x Yr-5 Audit, Shock-Buffered)', ...
    'Thick Compact w/ 30% CBAx Attribution Haircut', ...
    'Cash-Basis OBEGAL Forecast (Omits Forward Debt)', ...
    'Mode 2: Unbuffered Silo Deal (Fractures at Yr ~2)', ...
    'Mode 1: Omitted-Liability Cuts (2024->2026 Outturn)'};
for ir = 1:5
    plot(ax4, [3.04, 3.29], [d_rows_y(ir), d_rows_y(ir)], d_styles{ir}, 'Color', d_cols{ir}, 'LineWidth', 2.3);
    if ir == 5
        plot(ax4, 3.165, d_rows_y(ir), 'o', 'Color', c_thin_red, 'MarkerFaceColor', c_thin_red, 'MarkerSize', 4.1);
    end
    text(ax4, 3.35, d_rows_y(ir), d_labels{ir}, 'Interpreter', 'none', ...
        'FontName', 'Helvetica', 'FontSize', 6.75, 'VerticalAlignment', 'middle', 'Color', [0.14, 0.17, 0.22]);
end
grid(ax4, 'on');

fig_path = fullfile(OutputDir, sprintf('Fig_Doc2T_ThickVsThin_Assembly_Auction_%s.png', AnchorTag));
print(fig, fig_path, '-dpng', '-r220');
close(fig);

Out = struct();
Out.ABM          = ABM;
Out.FigurePNG    = fig_path;
Out.CSV_Homotopy = csv_hom;
Out.CSV_Arch     = csv_arch;
Out.CSV_Shock    = csv_shk;
end
