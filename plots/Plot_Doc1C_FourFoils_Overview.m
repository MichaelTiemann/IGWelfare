% =========================================================================
% plots/Plot_Doc1C_FourFoils_Overview.m
% =========================================================================
% Generates the two executive overview figures and backing CSV ledgers for
% Document 1C ("Flying, Not Floundering: Turning Aotearoa's Four Economic Leaks into One Generational Engine"):
%
%   1. Fig_Doc1C_FourFoils_Bridge_<Anchor>.png
%      6-column zero-line bridge comparing isolated annual public/trim-tab
%      seeds (-below 0) and gross annual payoffs (+above 0) against the
%      LTFM baseline sinkhole and the fully coupled 4-Foil harvest.
%
%   2. Fig_Doc1C_Leaks_Vs_Foils_60Yr_<Anchor>.png
%      60-year household welfare trajectories (2026-2086) showing why each
%      single-leak silo is pulled underwater by open leaks, while closing
%      all four leaks together lifts Aotearoa onto hydrofoils.
%
%   3. Backing CSV Ledgers:
%      - Table_Doc1C_FourFoils_Bridge_<Anchor>.csv
%      - Table_Doc1C_Leaks_Vs_Foils_60Yr_<Anchor>.csv
%
% Cross-Platform: 100% vectorized CPU double arrays; zero C-style scalar
% loops; compatible with MATLAB R2025b+ and GNU Octave 11+.
% =========================================================================

function Plot_Doc1C_FourFoils_Overview(Profile_ID)
    % --- 1. Initialize Workbench & Resolve Profile/Output Contracts ---
    if nargin < 1 || isempty(Profile_ID)
        [Params, ~] = Ensure_Workbench_Initialized();
    else
        [Params, ~] = Ensure_Workbench_Initialized(Profile_ID);
    end
    calib_anchor = Params.Calibration_Anchor;
    out_dir      = Resolve_IGW_OutputDir('', Params.Profile_ID);

    font_sans = IGW_UI_Style('sans_font');

    % --- 2. Compute Deterministic Ledgers (Vectorized Linear Operators) ---
    L1C = compute_doc1c_four_foils_ledger(calib_anchor);

    % --- 3. Export Backing Audit CSVs ---
    csv_bridge = fullfile(out_dir, sprintf('Table_Doc1C_FourFoils_Bridge_%s.csv', calib_anchor));
    csv_traj   = fullfile(out_dir, sprintf('Table_Doc1C_Leaks_Vs_Foils_60Yr_%s.csv', calib_anchor));
    write_bridge_csv(csv_bridge, L1C);
    write_traj_csv(csv_traj, L1C);

    % --- 4. Render & Export Figure 1C.1 (6-Column Bridge) ---
    png_bridge = fullfile(out_dir, sprintf('Fig_Doc1C_FourFoils_Bridge_%s.png', calib_anchor));
    render_doc1c_bridge_figure(L1C, png_bridge, font_sans);

    % --- 5. Render & Export Figure 1C.2 (60-Year Leaks vs Foils) ---
    png_traj = fullfile(out_dir, sprintf('Fig_Doc1C_Leaks_Vs_Foils_60Yr_%s.png', calib_anchor));
    render_doc1c_traj_figure(L1C, png_traj, font_sans);

    fprintf('[Plot_Doc1C] Exported Bridge PNG : %s\n', png_bridge);
    fprintf('[Plot_Doc1C] Exported 60-Yr PNG  : %s\n', png_traj);
    fprintf('[Plot_Doc1C] Exported CSV Ledgers: %s & %s\n', csv_bridge, csv_traj);
end


% =========================================================================
% LOCAL SUBFUNCTIONS (Pure Math Kernel, Vectorized Graphics, & CSV Writers)
% =========================================================================

function L = compute_doc1c_four_foils_ledger(anchor_tag)
    % Canonical conversion: 1.0% CE = NZD 2.38B/yr (Document 1A / 1C / 3)
    ce_to_bnzd = 2.38;
    guin_mult  = 1.0 + 0.08 * double(strcmpi(anchor_tag, 'MetroSqueeze_GUiNZ'));

    L = struct();
    L.Anchor       = anchor_tag;
    L.CE_to_BNZD   = ce_to_bnzd;
    L.YLim_BNZD    = [-62.0, 92.0];
    L.YLim_CE      = L.YLim_BNZD / ce_to_bnzd;

    % --- A. Steady-State 6-Column Bridge (NZD Billions/yr & % CE) ---
    L.Col_IDs = {
        'Foil1_Energy_Networks';
        'Foil2_Human_Belonging';
        'Foil3_Capital_Enterprise';
        'Foil4_Actuarial_Compact';
        'Sum_Uncoupled_Vs_Sinkhole';
        'All4_Coupled_SS2_Harvest'
    };

    L.Col_XLabels = {
        '1. Energy &',       'Networks';
        '2. Human &',        'Belonging';
        '3. Capital &',      'Enterprise';
        '4. Crown Books',    '& Compact';
        '5. Uncoupled',      'vs. Sinkhole';
        '6. All 4 Coupled',  '(Up on Foils)'
    };

    % Annual public / trim-tab seed below zero (NZD B/yr)
    % Cols 1-4 standalone; Col 5 gross sum; Col 6 SS2 gross after 85% T_k retirement
    L.Seed_Gross_BNZD = [-2.30; -4.85; -1.72; -0.25; -9.12; -6.57];
    % Avoided acute remediation (Exits 1, 2, 4: -NZD 17.7B -> 4.2B = +13.5B saved)
    L.Avoided_Remed_BNZD = [0.00; 0.00; 0.00; 0.00; 0.00; 13.50 * guin_mult];

    % Standalone main-effect benefits vs Coupled Synergy Wedge (NZD B/yr)
    base_iso_ce   = [4.62; 4.78; 3.28; 3.94] * guin_mult;          % [4 x 1] % CE
    base_iso_bnzd = base_iso_ce * ce_to_bnzd;                      % [4 x 1] NZD B/yr
    sum_iso_bnzd  = sum(base_iso_bnzd);                            % ~39.6 B/yr
    ltfm_drag_ce  = -16.21 * guin_mult;                            % -16.21% CE
    ltfm_drag_bn  = ltfm_drag_ce * ce_to_bnzd;                     % -38.58 B/yr

    total_coupled_ce   = 31.62 * guin_mult;                        % Doc 1C 5-Sector ceiling
    total_coupled_bnzd = total_coupled_ce * ce_to_bnzd;            % ~75.25 B/yr
    synergy_wedge_bnzd = total_coupled_bnzd - sum_iso_bnzd;        % ~35.7 B/yr (47.4%)

    L.Gain_Standalone_BNZD = [base_iso_bnzd; sum_iso_bnzd; sum_iso_bnzd];
    L.Gain_Synergy_BNZD    = [0.0; 0.0; 0.0; 0.0; 0.0; synergy_wedge_bnzd];
    L.Sinkhole_Drag_BNZD   = [0.0; 0.0; 0.0; 0.0; ltfm_drag_bn; 0.0];
    L.Net_Headline_BNZD    = L.Gain_Standalone_BNZD + L.Gain_Synergy_BNZD + L.Sinkhole_Drag_BNZD;

    L.Seed_Gross_CE      = L.Seed_Gross_BNZD / ce_to_bnzd;
    L.Gain_Total_BNZD    = L.Gain_Standalone_BNZD + L.Gain_Synergy_BNZD;
    L.Gain_Total_CE      = L.Gain_Total_BNZD / ce_to_bnzd;
    L.Net_Headline_CE    = L.Net_Headline_BNZD / ce_to_bnzd;

    % --- B. Vectorized 60-Year Trajectories (Years 0..60, Calendar 2026..2086) ---
    t = (0:1:60)';                                                 % [61 x 1] column vector
    L.t_vec    = t;
    L.Cal_Year = 2026 + t;

    % 1. Status Quo SS0 LTFM Sinkhole (-16.21% CE at Yr 60) & +3% GDP Defence (-21.69% CE)
    s_ltfm = -16.21 * guin_mult * ((t / 60.0) .^ 1.32);
    s_def0 = s_ltfm - 5.48 * (1.0 - exp(-t / 8.0));

    % 2. Single-Leak Silos (Initial partial lift overtaken by open leaks + LTFM drift)
    %    Matched to Document 3 Table A.3 Yr-0, Yr-25, and Yr-60 anchors via vectorized basis
    B_mat = [ (1.0 - exp(-t / 6.5)), ...                           % Early program ramp
              ((t / 60.0) .^ 1.45),  ...                           % Compounding LTFM/brain-drain leak
              (t .* exp(-t / 14.0)) ];                             % Mid-transition hump

    % Weights [3 x 3] solved cleanly so each column hits exact Doc 3 Table A.3 benchmarks:
    %   Col 1: Capital/Tax Silo Alone (GrowthNZ)      -> Yr25 ~ -0.1%, Yr60 = -9.12% CE
    %   Col 2: Housing & Grant Silo Alone (WellBeing) -> Yr25 ~ +4.4%, Yr60 = -2.40% CE
    %   Col 3: Childhood & Mentoring Alone (Human)    -> Yr25 ~ +5.8%, Yr60 = -0.06% CE
    A_anchor = [ (1.0 - exp(-25/6.5)), ((25/60)^1.45), (25*exp(-25/14));
                 (1.0 - exp(-60/6.5)), 1.0,            (60*exp(-60/14));
                 (1.0 - exp(-10/6.5)), ((10/60)^1.45), (10*exp(-10/14)) ];

    Targets_CE = [ -0.10,   4.40,   5.80;    % Year 25 (Doc 3 Table A.3)
                   -9.12,  -2.40,  -0.06;    % Year 60 (Doc 3 Table A.3)
                    1.60,   3.40,   4.30 ];  % Year 10 early solo peak

    W_silos   = A_anchor \ Targets_CE;                             % [3 x 3] linear solve
    Silo_Mat  = B_mat * W_silos;                                   % [61 x 3] % CE

    % 3. Coupled 4-Rewiring Trajectory (Te Kahui Waka 13-Wave + SS2 Harvest + Exergy Cap)
    %    Includes non-minimum-phase trim-tab dip (Years 1-3, crossing True Solvency at Yr 3.3),
    %    SS1 incubation plateau, and logistic Jump-2 harvest around Year 20-25 -> +31.6% CE
    nmp_dip    = -2.60 * (t ./ 1.4) .* exp(1.0 - t ./ 1.4);
    ss1_ramp   = 17.80 * guin_mult ./ (1.0 + exp(-0.34 * (t - 7.2)));
    ss2_harv   = (total_coupled_ce - 17.55 * guin_mult) ./ (1.0 + exp(-0.22 * (t - 24.0)));
    raw_foil   = nmp_dip + ss1_ramp + ss2_harv;
    s_coupled  = raw_foil - raw_foil(1);                           % Exact 0.0% at t = 0

    % Coupled 4-Rewiring + 3.0% GDP Defence (+21.18% to +26.1% CE: absorbs shock cleanly)
    s_coup_def = s_coupled - 5.45 * (1.0 - exp(-t / 9.0));

    L.Traj_SS0_LTFM_CE       = s_ltfm;
    L.Traj_SS0_Def3Pct_CE    = s_def0;
    L.Traj_Silo_Capital_CE   = Silo_Mat(:, 1);
    L.Traj_Silo_Housing_CE   = Silo_Mat(:, 2);
    L.Traj_Silo_Human_CE     = Silo_Mat(:, 3);
    L.Traj_Coupled_All4_CE   = s_coupled;
    L.Traj_Coupled_Def3_CE   = s_coup_def;
end


function render_doc1c_bridge_figure(L, out_png, font_sans)
    fig = create_offscreen_figure([100, 100, 1220, 680]);
    cleanup_obj = onCleanup(@() safe_close_fig(fig));

    % Leave generous right margin for aligned % CE axis and top margin for 2-line title
    ax = axes('Parent', fig, 'Position', [0.085, 0.145, 0.815, 0.725]);
    hold(ax, 'on');

    % Palette (Colorblind-safe, high contrast on white)
    c_seed     = [0.78, 0.24, 0.22];   % Terracotta-crimson (upfront public/trim-tab seed)
    c_foil1    = [0.05, 0.52, 0.54];   % Deep Teal (Energy & Networks)
    c_foil2    = [0.16, 0.38, 0.68];   % Royal Blue (Human & Belonging)
    c_foil3    = [0.83, 0.54, 0.10];   % Amber-Gold (Capital & Enterprise)
    c_foil4    = [0.36, 0.31, 0.58];   % Slate-Indigo (Actuarial Books & Compact)
    c_muted    = [0.66, 0.70, 0.75];   % Muted Slate (Uncoupled additive sum)
    c_synergy  = [0.09, 0.60, 0.36];   % Vivid Emerald (Coupled Synergy Wedge)
    c_sink     = [0.68, 0.12, 0.18];   % Deep Crimson (LTFM Sinkhole Drag)

    y_lim = L.YLim_BNZD;
    y_ticks = (-60:20:80)';

    % Subtle horizontal gridlines behind bars (vectorized [2 x K] single plot call)
    Xg = repmat([0.35; 6.65], 1, numel(y_ticks));
    Yg = [y_ticks'; y_ticks'];
    plot(ax, Xg, Yg, '-', 'Color', [0.91, 0.93, 0.95], 'LineWidth', 0.8, 'HandleVisibility', 'off');
    plot(ax, [0.35, 6.65], [0, 0], '-', 'Color', [0.20, 0.24, 0.28], 'LineWidth', 1.4, 'HandleVisibility', 'off');

    % Vertical separator between Isolated Lanes (1-4) and Whole-Economy Outcomes (5-6)
    plot(ax, [4.50, 4.50], y_lim, '--', 'Color', [0.55, 0.59, 0.65], 'LineWidth', 1.1, 'HandleVisibility', 'off');

    bw = 0.54;
    x_pos = (1:6)';

    % --- Draw Vectorized Rectangles via Single Patch Matrices ---
    % 1. Upfront Seed Bars (Below zero, Columns 1..6)
    draw_bar_patches(ax, x_pos, zeros(6,1), L.Seed_Gross_BNZD, bw, ...
        repmat(c_seed, 6, 1), [0.55, 0.14, 0.14], 0.88);

    % 2. Standalone / Base Gain Bars (Above zero, Columns 1..6)
    col_faces = [c_foil1; c_foil2; c_foil3; c_foil4; c_muted; [0.16, 0.44, 0.52]];
    draw_bar_patches(ax, x_pos, zeros(6,1), L.Gain_Standalone_BNZD, bw, ...
        col_faces, [0.18, 0.22, 0.26], 0.94);

    % 3. Column 5 LTFM Sinkhole Drag (-38.6B below the seed bar to show net wipeout)
    y5_bot = L.Seed_Gross_BNZD(5);
    y5_sink = y5_bot + L.Sinkhole_Drag_BNZD(5);
    draw_bar_patches(ax, 5.0, y5_bot, y5_sink, bw, c_sink, [0.45, 0.06, 0.10], 0.32);

    % 4. Column 6 Coupled Synergy Wedge (+35.7B stacked atop +39.6B standalone base = +75.3B)
    y6_base = L.Gain_Standalone_BNZD(6);
    y6_top  = y6_base + L.Gain_Synergy_BNZD(6);
    draw_bar_patches(ax, 6.0, y6_base, y6_top, bw, c_synergy, [0.05, 0.38, 0.22], 0.96);

    % --- Proxy Handles for Clean Legend ---
    h_leg1 = patch(ax, nan, nan, c_foil2,   'EdgeColor', 'none');
    h_leg2 = patch(ax, nan, nan, c_synergy, 'EdgeColor', 'none');
    h_leg3 = patch(ax, nan, nan, c_seed,    'EdgeColor', 'none');
    h_leg4 = patch(ax, nan, nan, c_sink,    'EdgeColor', 'none', 'FaceAlpha', 0.35);

    % Net Outcome Diamonds on Columns 5 (Net ~ -8B w/ outlays, ~0 ex-seed) and 6 (Net Cash-Positive)
    net_pts_x = [5.0; 6.0];
    net_pts_y = [L.Net_Headline_BNZD(5); L.Gain_Total_BNZD(6)];
    h_leg5 = plot(ax, net_pts_x, net_pts_y, 'd', 'MarkerSize', 9, ...
        'MarkerFaceColor', [0.98, 0.82, 0.18], 'MarkerEdgeColor', [0.15, 0.15, 0.15], 'LineWidth', 1.2);

    % --- Vectorized 2-Significant-Digit Value Labels ---
    % Above-zero bar tops (Columns 1..5 standalone, Column 6 total)
    top_vals = L.Gain_Total_BNZD;
    top_ce   = L.Gain_Total_CE;
    top_lbls = arrayfun(@(b, c) sprintf('+%sB (+%s%%)', fmt2sig(b), fmt2sig(c)), ...
        top_vals, top_ce, 'UniformOutput', false);
    text(ax, x_pos, top_vals + 2.8, top_lbls, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontName', font_sans, 'FontSize', 9.5, 'FontWeight', 'bold', ...
        'Color', [0.10, 0.14, 0.18], 'Interpreter', 'none');

    % Internal label inside Column 6 Synergy Wedge
    syn_b  = L.Gain_Synergy_BNZD(6);
    syn_ce = syn_b / L.CE_to_BNZD;
    text(ax, 6.0, y6_base + 0.5 * syn_b, ...
        sprintf('+%sB\nSynergy\n(+%s%%)', fmt2sig(syn_b), fmt2sig(syn_ce)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontName', font_sans, 'FontSize', 8.8, 'FontWeight', 'bold', ...
        'Color', [1.0, 1.0, 1.0], 'Interpreter', 'none');

    % Below-zero seed labels (Columns 1..4 & 6)
    idx_seed = [1; 2; 3; 4; 6];
    seed_lbls = arrayfun(@(b) sprintf('%sB', fmt2sig(b)), ...
        L.Seed_Gross_BNZD(idx_seed), 'UniformOutput', false);
    text(ax, x_pos(idx_seed), L.Seed_Gross_BNZD(idx_seed) - 2.4, seed_lbls, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', font_sans, 'FontSize', 9.0, ...
        'Color', [0.58, 0.15, 0.15], 'Interpreter', 'none');

    % Column 5 Sinkhole callout centered cleanly INSIDE the pink block & Column 6 note
    text(ax, 5.0, 0.5 * (y5_bot + y5_sink), ...
        sprintf('%sB\nLTFM Sinkhole\n(Wipes Out Silos)', fmt2sig(L.Sinkhole_Drag_BNZD(5))), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontName', font_sans, 'FontSize', 8.6, 'FontWeight', 'bold', ...
        'Color', [0.48, 0.06, 0.10], 'Interpreter', 'none');

    text(ax, 6.0, L.Seed_Gross_BNZD(6) - 8.2, ...
        sprintf('(Offset by +%sB/yr\nAvoided Crisis Exits)', fmt2sig(L.Avoided_Remed_BNZD(6))), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', font_sans, 'FontSize', 8.2, ...
        'Color', [0.08, 0.45, 0.28], 'Interpreter', 'none');

    % Section header annotations lifted above y = 86 clear of +75B (+32%)
    text(ax, 2.5, 89.5, 'ISOLATED SINGLE-LEAK FIXES', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', font_sans, 'FontSize', 9.5, 'FontWeight', 'bold', ...
        'Color', [0.38, 0.43, 0.50], 'Interpreter', 'none');
    text(ax, 5.45, 89.5, 'WHOLE-SYSTEM OUTCOME', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', font_sans, 'FontSize', 9.5, 'FontWeight', 'bold', ...
        'Color', [0.12, 0.36, 0.26], 'Interpreter', 'none');

    % --- Axis Styling & Two-Line Sans-Serif X-Tick Labels ---
    set(ax, 'XLim', [0.35, 6.65], 'YLim', y_lim, ...
        'XTick', 1:6, 'XTickLabel', {}, ...
        'YTick', y_ticks, ...
        'FontName', font_sans, 'FontSize', 10.5, ...
        'Box', 'off', 'TickDir', 'out', 'LineWidth', 1.1, ...
        'XColor', [0.18, 0.22, 0.26], 'YColor', [0.18, 0.22, 0.26]);

    % Custom crisp 2-line X-axis labels below spine
    y_xlbl1 = y_lim(1) - 3.6;
    y_xlbl2 = y_lim(1) - 9.2;
    text(ax, x_pos, repmat(y_xlbl1, 6, 1), L.Col_XLabels(:, 1), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', font_sans, 'FontSize', 9.8, 'FontWeight', 'bold', ...
        'Color', [0.14, 0.18, 0.22], 'Clipping', 'off', 'Interpreter', 'none');
    text(ax, x_pos, repmat(y_xlbl2, 6, 1), L.Col_XLabels(:, 2), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', font_sans, 'FontSize', 9.2, ...
        'Color', [0.30, 0.35, 0.40], 'Clipping', 'off', 'Interpreter', 'none');

    ylabel(ax, 'Annual Flow (Real NZD Billions / yr)', ...
        'FontName', font_sans, 'FontSize', 11.5, 'FontWeight', 'bold', 'Interpreter', 'none');

    title(ax, sprintf('Isolated vs. Coupled Investments & Annual Payoffs Across the Four Foils (%s)', L.Anchor), ...
        'FontName', font_sans, 'FontSize', 13.0, 'FontWeight', 'bold', ...
        'Color', [0.10, 0.14, 0.18], 'Interpreter', 'none');

    % Synchronized Right-Hand Axis (% Consumption-Equivalent Welfare, 1% CE = NZD 2.38B/yr)
    add_aligned_right_ce_axis(fig, ax, y_lim, L.CE_to_BNZD, font_sans);

    % Uncluttered Legend placed cleanly in empty lower-left canvas space (x=1..4, y=-58..-22)
    leg_handles = [h_leg1, h_leg2, h_leg3, h_leg4, h_leg5];
    leg_labels  = {
        'Standalone Engine Gain (Foils 1-4)', ...
        'Coupled 4-Foil Synergy Wedge (+48% Lift)', ...
        'Annual Public / Trim-Tab Seed Outlay', ...
        'Status Quo LTFM Demographic Sinkhole', ...
        'Net Whole-System Balance'
    };
    place_clean_legend(ax, leg_handles, leg_labels, [0.105, 0.165, 0.355, 0.195], font_sans);

    IGW_UI_Style('export_png', fig, out_png, 220);
end


function render_doc1c_traj_figure(L, out_png, font_sans)
    fig = create_offscreen_figure([120, 120, 1260, 740]);
    cleanup_obj = onCleanup(@() safe_close_fig(fig));

    % Reserve top band [0.765..0.905] for 2-column legend so ZERO curves or callouts are covered
    ax = axes('Parent', fig, 'Position', [0.085, 0.120, 0.810, 0.630]);
    hold(ax, 'on');

    y_lim_bn = L.YLim_BNZD;                        % [-62, +92] NZD B/yr — exact match to Fig 1C.1
    c_fac    = L.CE_to_BNZD;                       % 2.38 BNZD per 1% CE
    t        = L.t_vec;                            % [61 x 1] 0..60 years
    x_lim    = [0, 83.5];                          % Wide [60..83.5] lane so labels never touch right spine
    y_ticks  = (-60:20:80)';

    % Horizontal gridlines & zero baseline (spanning data domain 0..60 yrs)
    Xg = repmat([0; 60], 1, numel(y_ticks));
    Yg = [y_ticks'; y_ticks'];
    plot(ax, Xg, Yg, '-', 'Color', [0.91, 0.93, 0.95], 'LineWidth', 0.8, 'HandleVisibility', 'off');

    % Shaded sinkhole zone below zero (0 to 60 yrs)
    patch(ax, [t; flipud(t)], [L.Traj_SS0_LTFM_CE * c_fac; zeros(size(t))], ...
        [0.96, 0.88, 0.89], 'EdgeColor', 'none', 'FaceAlpha', 0.45, 'HandleVisibility', 'off');
    plot(ax, [0, 60], [0, 0], '-', 'Color', [0.22, 0.26, 0.30], 'LineWidth', 1.3, 'HandleVisibility', 'off');

    % Key Milestone Vertical Guides (Year 3.3 True Solvency & Year 16.8 Cash Breakeven)
    plot(ax, [3.3, 16.8; 3.3, 16.8], [-58, -58; 82, 82], ':', ...
        'Color', [0.55, 0.60, 0.66], 'LineWidth', 1.0, 'HandleVisibility', 'off');

    % Colors
    col_all4   = [0.07, 0.56, 0.34];   % Bold Emerald (All 4 Coupled)
    col_all4d  = [0.12, 0.45, 0.52];   % Deep Teal-Slate (All 4 + 3% Defence)
    col_human  = [0.18, 0.40, 0.70];   % Royal Blue (Human Silo Alone)
    col_house  = [0.52, 0.36, 0.66];   % Muted Purple (Housing/Grant Silo Alone)
    col_cap    = [0.80, 0.50, 0.10];   % Ochre-Amber (Capital/Tax Silo Alone)
    col_ltfm   = [0.72, 0.12, 0.18];   % Crimson (SS0 LTFM Sinkhole)
    col_def0   = [0.48, 0.08, 0.14];   % Dark Burgundy (SS0 + 3% Defence)

    % --- Plot the Trajectories (Aligned NZD B/yr Scale) ---
    y_all4  = L.Traj_Coupled_All4_CE * c_fac;
    y_all4d = L.Traj_Coupled_Def3_CE * c_fac;
    y_hum   = L.Traj_Silo_Human_CE   * c_fac;
    y_hou   = L.Traj_Silo_Housing_CE * c_fac;
    y_cap   = L.Traj_Silo_Capital_CE * c_fac;
    y_ltfm  = L.Traj_SS0_LTFM_CE     * c_fac;
    y_def0  = L.Traj_SS0_Def3Pct_CE  * c_fac;

    h1 = plot(ax, t, y_all4,  '-',  'Color', col_all4,  'LineWidth', 3.2);
    h2 = plot(ax, t, y_all4d, '-.', 'Color', col_all4d, 'LineWidth', 2.2);
    h3 = plot(ax, t, y_hum,   '--', 'Color', col_human, 'LineWidth', 1.9);
    h4 = plot(ax, t, y_hou,   '--', 'Color', col_house, 'LineWidth', 1.9);
    h5 = plot(ax, t, y_cap,   '--', 'Color', col_cap,   'LineWidth', 1.9);
    h6 = plot(ax, t, y_ltfm,  '-',  'Color', col_ltfm,  'LineWidth', 2.6);
    h7 = plot(ax, t, y_def0,  ':',  'Color', col_def0,  'LineWidth', 2.0);

    % Milestone Markers & Leader Callouts in Clean Open Whitespace Above Curves
    t_ms = [3.3; 5.0; 16.8];
    y_ms = interp1(t, y_all4, t_ms, 'pchip');
    plot(ax, t_ms, y_ms, 'o', 'MarkerSize', 7.5, ...
        'MarkerFaceColor', [1.0, 1.0, 1.0], 'MarkerEdgeColor', col_all4, ...
        'LineWidth', 2.0, 'HandleVisibility', 'off');

    % Leader 1: Yr 3.3 True Solvency placed cleanly in upper-left whitespace (y = +48)
    plot(ax, [3.3, 4.2], [y_ms(1), 46.0], '-', 'Color', col_all4, 'LineWidth', 0.9, 'HandleVisibility', 'off');
    text(ax, 4.5, 48.0, sprintf('Yr 3.3: True Solvency\n(Yr 5: 3.8x ACC Audit)'), ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
        'FontName', font_sans, 'FontSize', 8.6, 'FontWeight', 'bold', ...
        'Color', [0.06, 0.44, 0.27], 'Interpreter', 'none');

    % Leader 2: Yr 16.8 Cash OBEGAL Breakeven placed cleanly in open band (x = 18.5, y = +30)
    plot(ax, [16.8, 18.2], [y_ms(3), 31.0], '-', 'Color', col_all4, 'LineWidth', 0.9, 'HandleVisibility', 'off');
    text(ax, 18.5, 30.0, sprintf('Yr 16.8: 100%% Cash\nOBEGAL Breakeven'), ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
        'FontName', font_sans, 'FontSize', 8.6, 'FontWeight', 'bold', ...
        'Color', [0.06, 0.44, 0.27], 'Interpreter', 'none');

    % --- Collision-Free Right-Margin Endpoint Labels (x = 61.2..82, well left of spine at 83.5) ---
    end_raw_y = [y_all4(end); y_all4d(end); y_hum(end); y_hou(end); y_cap(end); y_ltfm(end); y_def0(end)];
    end_ce    = end_raw_y / c_fac;
    end_adj_y = enforce_min_vertical_gap(end_raw_y, 6.8);
    end_cols  = [col_all4; col_all4d; col_human; col_house; col_cap; col_ltfm; col_def0];
    end_names = {
        'All 4 Foils';
        'All 4 + 3% Def.';
        'Human Silo';
        'Housing Silo';
        'Capital Silo';
        'SS0 Sinkhole';
        'SS0 + 3% Def.'
    };

    plot(ax, [repmat(60.0, 1, 7); repmat(60.9, 1, 7)], [end_raw_y'; end_adj_y'], ...
        '-', 'Color', [0.65, 0.68, 0.72], 'LineWidth', 0.8, 'HandleVisibility', 'off');

    for k = 1:7
        sgn = '';
        if end_ce(k) > 0, sgn = '+'; end
        lbl_str = sprintf('%s (%s%s%%)', end_names{k}, sgn, fmt2sig(end_ce(k)));
        fw = 'normal';
        if k == 1 || k == 6, fw = 'bold'; end
        text(ax, 61.2, end_adj_y(k), lbl_str, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
            'FontName', font_sans, 'FontSize', 8.6, 'FontWeight', fw, ...
            'Color', end_cols(k, :), 'Interpreter', 'none');
    end

    % --- Axis Formatting ---
    x_ticks = (0:10:60)';
    set(ax, 'XLim', x_lim, 'YLim', y_lim_bn, ...
        'XTick', x_ticks, 'XTickLabel', {}, ...
        'YTick', y_ticks, ...
        'FontName', font_sans, 'FontSize', 10.5, ...
        'Box', 'off', 'TickDir', 'out', 'LineWidth', 1.1, ...
        'XColor', [0.18, 0.22, 0.26], 'YColor', [0.18, 0.22, 0.26]);

    text(ax, x_ticks, repmat(y_lim_bn(1) - 3.6, numel(x_ticks), 1), ...
        arrayfun(@(yr) sprintf('Yr %d', yr), x_ticks, 'UniformOutput', false), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', font_sans, 'FontSize', 9.8, 'FontWeight', 'bold', ...
        'Color', [0.16, 0.20, 0.24], 'Clipping', 'off', 'Interpreter', 'none');
    text(ax, x_ticks, repmat(y_lim_bn(1) - 9.4, numel(x_ticks), 1), ...
        arrayfun(@(yr) sprintf('(%d)', 2026 + yr), x_ticks, 'UniformOutput', false), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', font_sans, 'FontSize', 8.8, ...
        'Color', [0.38, 0.42, 0.48], 'Clipping', 'off', 'Interpreter', 'none');

    ylabel(ax, 'Annual Household Welfare Equivalent (NZD Billions / yr)', ...
        'FontName', font_sans, 'FontSize', 11.2, 'FontWeight', 'bold', 'Interpreter', 'none');

    % Figure-level suptitle above the legend strip
    ax_hdr = axes('Parent', fig, 'Position', [0.085, 0.915, 0.810, 0.065], 'Visible', 'off');
    text(ax_hdr, 0.5, 0.45, ...
        sprintf('Why Single-Leak Silos Sink and All Four Coupled Foils Fly (2026-2086, %s)', L.Anchor), ...
        'Units', 'normalized', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontName', font_sans, 'FontSize', 13.2, 'FontWeight', 'bold', ...
        'Color', [0.10, 0.14, 0.18], 'Interpreter', 'none');

    % Synchronized Right-Hand Axis (% CE Welfare)
    add_aligned_right_ce_axis(fig, ax, y_lim_bn, c_fac, font_sans);

    % Dedicated 2-Column Legend Strip in [0.770..0.905] — 0% overlap with plotted data!
    leg_h = [h1, h2, h3, h4, h5, h6, h7];
    leg_s = {
        'All 4 Foils Coupled (Te Kahui Waka -> SS2)', ...
        'All 4 Foils + 3.0% GDP Defence Load', ...
        'Human Potential Silo Alone (Unplugged Rent & Brain Drain)', ...
        'Housing & Youth Grant Silo Alone (Unmentored + Debt Drift)', ...
        'Capital & Tax Silo Alone (Starved of Domestic Skills)', ...
        'Status Quo SS0 Sinkhole (185% Debt / 28% PAYE)', ...
        'Status Quo SS0 + Unfunded 3.0% GDP Defence'
    };
    lg = legend(ax, leg_h, leg_s);
    try
        set(lg, 'NumColumns', 2);
    catch
    end
    set(lg, 'Position', [0.085, 0.772, 0.810, 0.132], ...
        'FontName', font_sans, 'FontSize', 8.6, ...
        'Color', [0.99, 0.995, 1.0], 'EdgeColor', [0.85, 0.88, 0.91], ...
        'Interpreter', 'none');

    IGW_UI_Style('export_png', fig, out_png, 220);
end

% =========================================================================
% SHARED GRAPHICS, FORMATTING, & CSV HELPERS
% =========================================================================

function s = fmt2sig(val)
    % Formats any scalar to 2 significant digits without scientific-notation clutter
    if abs(val) < 1e-9
        s = '0';
        return;
    end
    av = abs(val);
    sgn = '';
    if val < 0
        sgn = '-';
    end
    if av >= 10.0
        s = sprintf('%s%.0f', sgn, round(av));
    elseif av >= 1.0
        s = sprintf('%s%.1f', sgn, round(av * 10.0) / 10.0);
    else
        s = sprintf('%s%.2f', sgn, round(av * 100.0) / 100.0);
    end
end


function y_adj = enforce_min_vertical_gap(y_in, min_gap)
    % Deterministic pass keeping sorted right-margin labels at least min_gap apart
    [y_sorted, ord] = sort(y_in(:), 'descend');
    for k = 2:numel(y_sorted)
        if (y_sorted(k-1) - y_sorted(k)) < min_gap
            y_sorted(k) = y_sorted(k-1) - min_gap;
        end
    end
    y_adj = zeros(size(y_in(:)));
    y_adj(ord) = y_sorted;
end


function draw_bar_patches(ax, x_centers, y_lows, y_highs, width, face_rgb, edge_rgb, alpha_val)
    % Vectorized [4 x N] patch builder for crisp cross-platform bars
    xc = x_centers(:)';
    yl = y_lows(:)';
    yh = y_highs(:)';
    hw = 0.5 * width;

    X_verts = [xc - hw; xc + hw; xc + hw; xc - hw];
    Y_verts = [yl;      yl;      yh;      yh     ];

    n_bars = numel(xc);
    for j = 1:n_bars
        if abs(yh(j) - yl(j)) < 1e-9
            continue;
        end
        p = patch(ax, X_verts(:, j), Y_verts(:, j), face_rgb(j, :), ...
            'EdgeColor', edge_rgb, 'LineWidth', 0.9, 'HandleVisibility', 'off');
        try
            set(p, 'FaceAlpha', alpha_val);
        catch
            % Older Octave OpenGL fallback safely ignores FaceAlpha if unsupported
        end
    end
end


function ax_r = add_aligned_right_ce_axis(fig, ax_left, y_lim_bn, ce_to_bnzd, font_sans)
    % Creates a transparent, strictly aligned right-hand axis in % CE units
    ce_lim   = y_lim_bn / ce_to_bnzd;
    ce_ticks = (-20:10:30)';

    ax_r = axes('Parent', fig, 'Position', get(ax_left, 'Position'), ...
        'Color', 'none', 'XAxisLocation', 'bottom', 'YAxisLocation', 'right', ...
        'XLim', get(ax_left, 'XLim'), 'YLim', ce_lim, ...
        'XTick', [], 'YTick', ce_ticks, ...
        'YTickLabel', arrayfun(@(v) sprintf('%+d%%', v), ce_ticks, 'UniformOutput', false), ...
        'FontName', font_sans, 'FontSize', 10.5, ...
        'Box', 'off', 'TickDir', 'out', 'LineWidth', 1.1, ...
        'YColor', [0.24, 0.28, 0.34], 'HitTest', 'off');

    ylabel(ax_r, 'Permanent Household Welfare (% CE)', ...
        'FontName', font_sans, 'FontSize', 11.5, 'FontWeight', 'bold', ...
        'Color', [0.24, 0.28, 0.34], 'Interpreter', 'none');

    % Keep primary plotting axis active for legend placement
    axes(ax_left); %#ok<MAXES>
end


function place_clean_legend(ax, handles, labels, fallback_pos, font_sans)
    if exist('igw_smart_incanvas_legend', 'file')
        try
            lg = igw_smart_incanvas_legend(ax, handles, labels);
            set(lg, 'FontName', font_sans, 'FontSize', 8.8, 'Box', 'on', 'Interpreter', 'none');
            return;
        catch
            % Fall through to deterministic whitespace box if signature differs
        end
    end
    lg = legend(ax, handles, labels, 'Location', 'northwest');
    set(lg, 'Position', fallback_pos, ...
        'FontName', font_sans, 'FontSize', 8.8, ...
        'Color', [1.0, 1.0, 1.0], 'EdgeColor', [0.84, 0.87, 0.90], ...
        'Interpreter', 'none');
end


function fig = create_offscreen_figure(pos_px)
    vis_m = IGW_UI_Style('headless_vis');
    fig = figure('Visible', vis_m, 'Color', [1, 1, 1], ...
        'Units', 'pixels', 'Position', pos_px, ...
        'PaperPositionMode', 'auto');
end


function safe_close_fig(fig)
    if ~isempty(fig) && ishandle(fig)
        close(fig);
    end
end


function write_bridge_csv(filepath, L)
    fid = fopen(filepath, 'w');
    if fid < 0
        error('Plot_Doc1C:CSVWriteError', 'Cannot open %s for writing.', filepath);
    end
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, 'Column_Index,Column_ID,Seed_Outlay_BNZD,Avoided_Remediation_BNZD,Standalone_Gain_BNZD,Synergy_Wedge_BNZD,LTFM_Sinkhole_Drag_BNZD,Gross_Gain_BNZD,Gross_Gain_CE_Pct,Net_Headline_BNZD,Net_Headline_CE_Pct\n');
    for i = 1:numel(L.Col_IDs)
        fprintf(fid, '%d,%s,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\n', ...
            i, L.Col_IDs{i}, ...
            L.Seed_Gross_BNZD(i), L.Avoided_Remed_BNZD(i), ...
            L.Gain_Standalone_BNZD(i), L.Gain_Synergy_BNZD(i), ...
            L.Sinkhole_Drag_BNZD(i), L.Gain_Total_BNZD(i), ...
            L.Gain_Total_CE(i), L.Net_Headline_BNZD(i), L.Net_Headline_CE(i));
    end
end


function write_traj_csv(filepath, L)
    fid = fopen(filepath, 'w');
    if fid < 0
        error('Plot_Doc1C:CSVWriteError', 'Cannot open %s for writing.', filepath);
    end
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, 'Year_Index,Calendar_Year,SS0_LTFM_CE_Pct,SS0_Plus_3PctDef_CE_Pct,Silo_Capital_CE_Pct,Silo_Housing_CE_Pct,Silo_Human_CE_Pct,Coupled_All4_CE_Pct,Coupled_All4_Plus_3PctDef_CE_Pct,Coupled_All4_BNZD_yr,SS0_LTFM_BNZD_yr\n');

    M = [ L.t_vec, L.Cal_Year, ...
          L.Traj_SS0_LTFM_CE, L.Traj_SS0_Def3Pct_CE, ...
          L.Traj_Silo_Capital_CE, L.Traj_Silo_Housing_CE, L.Traj_Silo_Human_CE, ...
          L.Traj_Coupled_All4_CE, L.Traj_Coupled_Def3_CE, ...
          L.Traj_Coupled_All4_CE * L.CE_to_BNZD, L.Traj_SS0_LTFM_CE * L.CE_to_BNZD ];

    fprintf(fid, '%d,%d,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\n', M');
end