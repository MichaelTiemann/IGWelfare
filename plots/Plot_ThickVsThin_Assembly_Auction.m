function Out = Plot_ThickVsThin_Assembly_Auction(Params, Opts)
%% PLOT_THICKVSTHIN_ASSEMBLY_AUCTION (DOCUMENTS 2T, 2B SEC 7.7.4, & 1F)
% Cross-platform (MATLAB HG2 & GNU Octave) 4-panel dashboard:
%   Panel A (NW): 1972 (1/16x) -> 2026 (1x) Backlog Bifurcation + 30%/50% Synergy Haircuts
%   Panel B (NE): SOE Shock Telemetry (Green / Amber / Red + 30% Haircut Resilience)
%   Panel C (SW): Twin 6-Spoke Hexagonal Persona Radars (Left: Closure % | Right: Welfare +CE pp)
%   Panel D (SE): Stated Ambition vs Realized Trajectory (Cash-Basis Bias vs Fragile Silo Deal)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Ensure_Workbench_Initialized();
end
if nargin < 2 || isempty(Opts)
    Opts = struct();
end

if isfield(Opts, 'OutputDir') && ~isempty(Opts.OutputDir)
    OutputDir = Opts.OutputDir;
else
    OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
end
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
for k = 1:size(ABM.Arch_Stats, 1)
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
%  PANEL C (SW): Twin 6-Spoke Hexagonal Radars (Left: Closure % | Right: CE pp)
%  ========================================================================
pos_SW_hdr = [0.032, 0.020, 0.472, 0.488];
pos_SW_L   = [0.034, 0.076, 0.230, 0.358];
pos_SW_R   = [0.270, 0.076, 0.230, 0.358];

% Shared header, sub-headers, & bottom legend canvas (frees 100% of radar YLim for the hexagons!)
ax3H = axes('Parent', fig, 'Position', pos_SW_hdr, 'XLim', [0, 1], 'YLim', [0, 1], ...
    'Color', 'none', 'Visible', 'off', 'XTick', [], 'YTick', []);
hold(ax3H, 'on');

text(ax3H, 0.500, 0.975, 'C. 6-Persona Institutional Radars: Closure Rate (%) vs Realized Welfare (+CE pp)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 10.5, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Color', [0.08, 0.12, 0.16]);
text(ax3H, 0.248, 0.910, 'C1. Compact Closure Rate (0–100%)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 8.9, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Color', [0.12, 0.18, 0.24]);
text(ax3H, 0.752, 0.910, 'C2. Realized Welfare (+0 to +24.7 pp CE)', ...
    'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 8.9, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Color', [0.05, 0.36, 0.30]);

% Shared 2x2 bottom legend strip tucked cleanly at the base of the SW quadrant
ly1 = 0.082; ly2 = 0.020;
plot(ax3H, [0.04, 0.10], [ly1, ly1], '-',  'Color', c_thick_dk, 'LineWidth', 2.6, ...
    'Marker', 'o', 'MarkerSize', 4.2, 'MarkerFaceColor', c_thick_dk);
text(ax3H, 0.115, ly1, 'Thick Canonical (15/15 Clear)', 'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.5);

plot(ax3H, [0.53, 0.59], [ly1, ly1], '-.', 'Color', c_thick_30, 'LineWidth', 2.2);
text(ax3H, 0.605, ly1, 'Thick w/ 30% CBAx Haircut', 'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.5);

plot(ax3H, [0.04, 0.10], [ly2, ly2], ':',  'Color', c_fool_amb, 'LineWidth', 2.3, ...
    'Marker', 'd', 'MarkerSize', 3.9, 'MarkerFaceColor', c_fool_amb);
text(ax3H, 0.115, ly2, 'Thin Cash Mirage ("Fool''s Gold")', 'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.5);

plot(ax3H, [0.53, 0.59], [ly2, ly2], '--', 'Color', c_thin_red, 'LineWidth', 2.5, ...
    'Marker', 's', 'MarkerSize', 4.0, 'MarkerFaceColor', c_thin_red);
text(ax3H, 0.605, ly2, 'Thin 2026 Reality (0% Viable)', 'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.5);

% 6 symmetric hexagon angles starting at North (pi/2) stepping clockwise by 60 degrees:
% Outer vertices sit at (0, +1), (+0.866, +0.50), (+0.866, -0.50), (0, -1), (-0.866, -0.50), (-0.866, +0.50)
n_hex   = 6;
theta_6 = (pi/2) - (0:(n_hex - 1)) * (2*pi / n_hex);
theta_c = [theta_6, theta_6(1)];
th_hex  = [theta_6, theta_6(1)];

% Center every label horizontally on its exact vertex x-coordinate (+/-0.866 at shoulders, 0 at N/S)
% and float close to the vertex with clean vertical breathing room so the hexagon fills the tile!
vx6     = cos(theta_6); % [0, +0.866, +0.866, 0, -0.866, -0.866]
lbl_x6  = [ 0.000, +0.965, +0.965,  0.000, -0.965, -0.965];
lbl_y6  = [+1.055, +0.615, -0.615, -1.060, -0.615, +0.615];
lbl_va6 = {'bottom', 'bottom', 'top', 'top', 'top', 'bottom'};

% --- SUB-PANEL C1 (LEFT): CLOSURE RATE (%) [0..100%] ---
ax3L = axes('Parent', fig, 'Position', pos_SW_L);
vfi_active_ax(ax3L);
hold(ax3L, 'on');
axis(ax3L, 'equal');
set(ax3L, 'Visible', 'off', 'XLim', [-1.28, 1.28], 'YLim', [-1.32, 1.32]);

for rr = [0.25, 0.50, 0.75, 1.00]
    lw_r  = 0.7 + 0.45 * (rr == 1.00);
    col_r = [0.80, 0.84, 0.88] - 0.12 * (rr == 1.00);
    plot(ax3L, rr * cos(th_hex), rr * sin(th_hex), '-', 'Color', col_r, 'LineWidth', lw_r);
    text(ax3L, 0.035, rr - 0.035, sprintf('%d%%', round(rr * 100)), ...
        'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 6.5, ...
        'HorizontalAlignment', 'left', 'Color', [0.36, 0.41, 0.47]);
end
plot(ax3L, [zeros(1, n_hex); 1.02 * vx6], [zeros(1, n_hex); 1.02 * sin(theta_6)], ...
    '-', 'Color', [0.76, 0.80, 0.85], 'LineWidth', 0.80);

c_mir = [R.Closure_Thin_Mirage,  R.Closure_Thin_Mirage(1)]  / 100.0;
c_thr = [R.Closure_Thin_Reality, R.Closure_Thin_Reality(1)] / 100.0;
c_h30 = [R.Closure_Thick_Hair30, R.Closure_Thick_Hair30(1)] / 100.0;
c_tkc = [R.Closure_Thick_Canon,  R.Closure_Thick_Canon(1)]  / 100.0;

patch(ax3L, c_tkc .* cos(theta_c), c_tkc .* sin(theta_c), c_thick_dk, 'FaceAlpha', 0.15, 'EdgeColor', 'none');
patch(ax3L, c_mir .* cos(theta_c), c_mir .* sin(theta_c), c_fool_amb, 'FaceAlpha', 0.13, 'EdgeColor', 'none');

plot(ax3L, c_tkc .* cos(theta_c), c_tkc .* sin(theta_c), '-',  'Color', c_thick_dk, 'LineWidth', 2.6, ...
    'Marker', 'o', 'MarkerSize', 4.4, 'MarkerFaceColor', c_thick_dk);
plot(ax3L, c_h30 .* cos(theta_c), c_h30 .* sin(theta_c), '-.', 'Color', c_thick_30, 'LineWidth', 2.1);
plot(ax3L, c_mir .* cos(theta_c), c_mir .* sin(theta_c), ':',  'Color', c_fool_amb, 'LineWidth', 2.3, ...
    'Marker', 'd', 'MarkerSize', 4.0, 'MarkerFaceColor', c_fool_amb);
plot(ax3L, c_thr .* cos(theta_c), c_thr .* sin(theta_c), '--', 'Color', c_thin_red, 'LineWidth', 2.4, ...
    'Marker', 's', 'MarkerSize', 4.1, 'MarkerFaceColor', c_thin_red);

for s = 1:n_hex
    lbl_L = sprintf('%s\n(%.0f%%)', R.Short_Names{s}, R.Closure_Thick_Canon(s));
    text(ax3L, lbl_x6(s), lbl_y6(s), lbl_L, ...
        'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.3, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', lbl_va6{s}, 'Color', [0.12, 0.16, 0.22]);
end

% --- SUB-PANEL C2 (RIGHT): REALIZED WELFARE (+CE pp) [0..+24.7 pp] ---
ax3R = axes('Parent', fig, 'Position', pos_SW_R);
vfi_active_ax(ax3R);
hold(ax3R, 'on');
axis(ax3R, 'equal');
set(ax3R, 'Visible', 'off', 'XLim', [-1.28, 1.28], 'YLim', [-1.32, 1.32]);

ce_max = R.CE_Frontier_SS2;
for rr = [0.25, 0.50, 0.75, 1.00]
    lw_r  = 0.7 + 0.45 * (rr == 1.00);
    col_r = [0.80, 0.84, 0.88] - 0.12 * (rr == 1.00);
    plot(ax3R, rr * cos(th_hex), rr * sin(th_hex), '-', 'Color', col_r, 'LineWidth', lw_r);
    text(ax3R, 0.035, rr - 0.035, sprintf('+%.1f', rr * ce_max), ...
        'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 6.5, ...
        'HorizontalAlignment', 'left', 'Color', [0.05, 0.40, 0.32]);
end
plot(ax3R, [zeros(1, n_hex); 1.02 * vx6], [zeros(1, n_hex); 1.02 * sin(theta_6)], ...
    '-', 'Color', [0.76, 0.80, 0.85], 'LineWidth', 0.80);

w_thin = [R.CE_Thin_Clamped_pp, R.CE_Thin_Clamped_pp(1)] / ce_max;
w_h30  = [R.CE_Thick_Hair30_pp, R.CE_Thick_Hair30_pp(1)] / ce_max;
w_tkc  = [R.CE_Thick_Canon_pp,  R.CE_Thick_Canon_pp(1)]  / ce_max;

patch(ax3R, w_tkc  .* cos(theta_c), w_tkc  .* sin(theta_c), c_thick_dk, 'FaceAlpha', 0.16, 'EdgeColor', 'none');
patch(ax3R, w_thin .* cos(theta_c), w_thin .* sin(theta_c), c_fool_amb, 'FaceAlpha', 0.18, 'EdgeColor', 'none');

plot(ax3R, w_tkc  .* cos(theta_c), w_tkc  .* sin(theta_c), '-',  'Color', c_thick_dk, 'LineWidth', 2.6, ...
    'Marker', 'o', 'MarkerSize', 4.4, 'MarkerFaceColor', c_thick_dk);
plot(ax3R, w_h30  .* cos(theta_c), w_h30  .* sin(theta_c), '-.', 'Color', c_thick_30, 'LineWidth', 2.1);
plot(ax3R, w_thin .* cos(theta_c), w_thin .* sin(theta_c), ':',  'Color', c_fool_amb, 'LineWidth', 2.3, ...
    'Marker', 'd', 'MarkerSize', 4.0, 'MarkerFaceColor', c_fool_amb);
plot(ax3R, w_thin .* cos(theta_c), w_thin .* sin(theta_c), '--', 'Color', c_thin_red, 'LineWidth', 1.8);

for s = 1:n_hex
    lbl_R = sprintf('%s\n(+%.1fpp)', R.Short_Names{s}, R.CE_Thick_Canon_pp(s));
    text(ax3R, lbl_x6(s), lbl_y6(s), lbl_R, ...
        'Interpreter', 'none', 'FontName', 'Helvetica', 'FontSize', 7.3, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', lbl_va6{s}, 'Color', [0.05, 0.36, 0.30]);
end

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
