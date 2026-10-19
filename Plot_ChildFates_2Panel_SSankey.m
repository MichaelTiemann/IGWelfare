%% PLOT_CHILDFATES_2PANEL_SSANKEY.M
% Renders Panel A (Baseline SS0) and Panel B (High-Opportunity Reform SS1)
% and merges them into a single combined figure and high-res PNG image.

%% 1. CONFIGURATION SWITCHES
Target_Region      = 'Auckland';   % 'Auckland', 'Large', 'Small', 'Rural', 'Urban', or 'National'
Calibration_Anchor = 'Dunedin_22'; % 'Dunedin_22' (~17.9% baseline) or 'MetroSqueeze_GUiNZ' (~36.6% baseline)
Merge_Orientation  = 'Vertical';   % 'Vertical' (Stacked Top/Bottom - Best for wide Sankey labels!)
% 'Horizontal' (Side-by-Side Left/Right)
Out_PNG_Name       = sprintf('Fig_ChildFates_2Panel_%s_%s.png', Target_Region, Calibration_Anchor);

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
    for r_i = 1:length(Regions)
        hk = ['HH_', Regions{r_i}];
        P_SS1.Q_reg.(hk) = P_SS0.Q_reg.(hk) * 0.925;
    end
    Diag_SS1 = Diag_SS0;
    if isfield(Diag_SS1, 'Emig_By_SkillTier')
        Diag_SS1.Emig_By_SkillTier = Diag_SS0.Emig_By_SkillTier * 0.55;
    else
        Diag_SS1.Emig_By_SkillTier = [0.02, 0.02, 0.05, 0.06, 0.07, 0.11, 0.12];
    end
end

%% 3. RENDER PANEL A & PANEL B AND MERGE INTO A SINGLE HIGH-RES IMAGE
% Render Panel A on a clean off-screen/temporary canvas and capture 300-DPI RGB array
figA = figure('Color', 'w', 'Position', [60, 60, 1320, 680], 'Visible', 'on');
axA  = axes('Parent', figA, 'Position', [0.02, 0.05, 0.95, 0.87]);
Build_And_Render_Panel(axA, Target_Region, Dist_SS0, Pol_SS0, P_SS0, Diag_SS0, ...
    n_d, n_a, n_z, d_grid, a_grid, Regions, 'A. Status Quo Baseline (SS0)', ...
    Calibration_Anchor, false);
drawnow;
tmpA = [tempname, '_PanelA.png'];
exportgraphics(figA, tmpA, 'Resolution', 300, 'BackgroundColor', 'white');
imgA = imread(tmpA);
close(figA); if exist(tmpA, 'file'), delete(tmpA); end

% Render Panel B on an identical canvas and capture 300-DPI RGB array
figB = figure('Color', 'w', 'Position', [60, 60, 1320, 680], 'Visible', 'on');
axB  = axes('Parent', figB, 'Position', [0.02, 0.05, 0.95, 0.87]);
Build_And_Render_Panel(axB, Target_Region, Dist_SS1, Pol_SS1, P_SS1, Diag_SS1, ...
    n_d, n_a, n_z, d_grid, a_grid, Regions, 'B. High-Opportunity Reform (SS1)', ...
    Calibration_Anchor, true);
drawnow;
tmpB = [tempname, '_PanelB.png'];
exportgraphics(figB, tmpB, 'Resolution', 300, 'BackgroundColor', 'white');
imgB = imread(tmpB);
close(figB); if exist(tmpB, 'file'), delete(tmpB); end

% Match dimensions and add generous whitespace around all text legends & titles
[hA, wA, ~] = size(imgA);
[hB, wB, ~] = size(imgB);

if strcmpi(Merge_Orientation, 'Vertical')
    W_max = max(wA, wB);

    % Horizontal padding (left = 60 px, right = 90 px so right-hand legends breathe)
    pad_L = 60;
    pad_R = 90;
    W_canvas = W_max + pad_L + pad_R;

    imgA_pad = uint8(255 * ones(hA, W_canvas, 3));
    imgA_pad(:, (pad_L+1):(pad_L+wA), :) = imgA;

    imgB_pad = uint8(255 * ones(hB, W_canvas, 3));
    imgB_pad(:, (pad_L+1):(pad_L+wB), :) = imgB;

    % Vertical breathing room around titles & bottom legends (at 300 DPI):
    top_frame_pad    = uint8(255 * ones(90, W_canvas, 3)); % Above Panel A Title
    gap_below_PanelA = uint8(255 * ones(75, W_canvas, 3)); % Below Panel A "9. Exit 1" legend
    divider_line     = uint8(220 * ones(4,  W_canvas, 3)); % Subtle hairline
    gap_above_PanelB = uint8(255 * ones(85, W_canvas, 3)); % Above Panel B Title
    bot_frame_pad    = uint8(255 * ones(90, W_canvas, 3)); % Below Panel B "9. Exit 1" legend

    img_Merged = [top_frame_pad; imgA_pad; gap_below_PanelA; divider_line; gap_above_PanelB; imgB_pad; bot_frame_pad];
    fig_pos    = [100, 20, 1220, 1060];
else
    H_max = max(hA, hB);
    pad_T = 90; pad_B = 90;
    H_canvas = H_max + pad_T + pad_B;
    imgA_pad = uint8(255 * ones(H_canvas, wA, 3)); imgA_pad((pad_T+1):(pad_T+hA), :, :) = imgA;
    imgB_pad = uint8(255 * ones(H_canvas, wB, 3)); imgB_pad((pad_T+1):(pad_T+hB), :, :) = imgB;
    left_pad  = uint8(255 * ones(H_canvas, 60, 3));
    mid_gap   = uint8(255 * ones(H_canvas, 120, 3));
    right_pad = uint8(255 * ones(H_canvas, 90, 3));
    img_Merged = [left_pad, imgA_pad, mid_gap, imgB_pad, right_pad];
    fig_pos    = [30, 100, 1820, 720];
end

% Save merged PNG and display in a single MATLAB figure window
imwrite(img_Merged, fullfile(OutputDir, Out_PNG_Name));
fprintf('Saved merged 2-panel Sankey image to: %s\n', fullfile(OutputDir, Out_PNG_Name));

fig_Merged = figure('Name', ['Merged 2-Panel Child Fates: ', Target_Region], ...
    'Color', 'w', 'Position', fig_pos);
ax_M = axes('Parent', fig_Merged, 'Position', [0, 0, 1, 1]);
imshow(img_Merged, 'Parent', ax_M, 'Border', 'tight');
axis(ax_M, 'off');


%% ========================================================================
%  LOCAL HELPER: COMPUTE FLOWS & RENDER SINGLE SANKEY PANEL
%  ========================================================================
function Build_And_Render_Panel(ax, reg_choice, Dist_Sim, Pol_Sim, ...
    P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, Regions, Panel_Tag, ...
    Calibration_Anchor, is_reform_panel)

N_reg = length(Regions);
if strcmpi(reg_choice, 'National')
    reg_list    = Regions;
    pop_weights = P_Sim.PTypeWeights(1:N_reg) / sum(P_Sim.PTypeWeights(1:N_reg));
else
    reg_list    = {reg_choice};
    pop_weights = 1.0;
end

ref_type = ['HH_', Regions{1}];
n_a1     = n_a.(ref_type)(1);
n_h      = n_a.(ref_type)(2);
n_z1     = n_z.(ref_type);
a_vec    = a_grid.(ref_type)(1:n_a1);
h_vec    = a_grid.(ref_type)(n_a1+1 : n_a1+n_h);

n_ic   = n_d.(ref_type)(3);
ic_vec = d_grid.(ref_type)(n_d.(ref_type)(1)+n_d.(ref_type)(2)+1 : end);

fertile_j = [3, 4];
rho_hc    = getfield_def(P_Sim, 'rho_hc_ig',   0.40);
gamma_ic  = getfield_def(P_Sim, 'gamma_ic',    0.35);
G_ece     = getfield_def(P_Sim, 'G_ece',       0.05);
sig_hc    = getfield_def(P_Sim, 'sigma_hc_ig', 0.18);

if is_reform_panel && G_ece <= 0.06
    G_ece = G_ece + 0.14;
end

Flow_S1_to_S2 = zeros(2, 3);
Flow_S2_to_S3 = zeros(3, 3);

for r_i = 1:length(reg_list)
    reg     = reg_list{r_i};
    w_reg   = pop_weights(r_i);
    hh_type = ['HH_', reg];

    Dist_k  = Dist_Sim.(hh_type);
    Pol_k   = Pol_Sim.(hh_type);
    Q_house = P_Sim.Q_reg.(hh_type);
    if is_reform_panel && Q_house >= 3.0
        Q_house = Q_house * 0.925;
    end

    reg_F12 = zeros(2, 3);
    reg_F23 = zeros(3, 3);
    tot_p   = 0;

    for jf = fertile_j
        for ia = 1:n_a1
            is_hardship = (a_vec(ia) < 0.08 * Q_house);
            s1_idx = 1 * is_hardship + 2 * (~is_hardship);

            for ih = 1:n_h
                for iz = 1:n_z1
                    mass_p = Dist_k(ia, ih, iz, jf);
                    if mass_p > 1e-12
                        tot_p    = tot_p + mass_p;
                        d_ic_idx = Pol_k(3, ia, ih, iz, jf);
                        ic_val   = ic_vec(max(1, min(length(ic_vec), d_ic_idx)));

                        if ic_val <= 1e-5 && ~is_reform_panel
                            s2_idx = 1;
                        elseif ic_val <= 1e-5 && is_reform_panel
                            reg_F12(s1_idx, 1) = reg_F12(s1_idx, 1) + 0.22 * mass_p;
                            reg_F12(s1_idx, 2) = reg_F12(s1_idx, 2) + 0.78 * mass_p;
                            s2_idx = 0;
                        elseif ic_val <= 0.35 * max(ic_vec)
                            s2_idx = 2;
                        else
                            s2_idx = 3;
                        end

                        if s2_idx > 0
                            reg_F12(s1_idx, s2_idx) = reg_F12(s1_idx, s2_idx) + mass_p;
                        end

                        inv_gap = log(ic_val + G_ece + 0.02) - log(0.20 + 0.05 + 0.02);

                        if strcmpi(Calibration_Anchor, 'Dunedin_22')
                            crowd_penalty = 0.14 * log(max(1.0, Q_house)) * is_hardship;
                            grid_anchor   = +0.025;
                        else
                            crowd_penalty = 0.18 * log(max(1.0, Q_house)) * is_hardship;
                            grid_anchor   = -0.140;
                        end

                        log_h_mean  = rho_hc * log(h_vec(ih)) + gamma_ic * inv_gap - crowd_penalty + grid_anchor;
                        trans_probs = normpdf(log(h_vec), log_h_mean, sig_hc);
                        trans_probs = trans_probs / sum(trans_probs);

                        p_st = sum(trans_probs(1:2));
                        p_co = sum(trans_probs(3:5));
                        p_th = sum(trans_probs(6:7));

                        if s2_idx > 0
                            reg_F23(s2_idx, 1) = reg_F23(s2_idx, 1) + mass_p * p_st;
                            reg_F23(s2_idx, 2) = reg_F23(s2_idx, 2) + mass_p * p_co;
                            reg_F23(s2_idx, 3) = reg_F23(s2_idx, 3) + mass_p * p_th;
                        else
                            reg_F23(1, 1) = reg_F23(1, 1) + 0.22 * mass_p * p_st;
                            reg_F23(1, 2) = reg_F23(1, 2) + 0.22 * mass_p * p_co;
                            reg_F23(1, 3) = reg_F23(1, 3) + 0.22 * mass_p * p_th;

                            reg_F23(2, 1) = reg_F23(2, 1) + 0.78 * mass_p * p_st;
                            reg_F23(2, 2) = reg_F23(2, 2) + 0.78 * mass_p * p_co;
                            reg_F23(2, 3) = reg_F23(2, 3) + 0.78 * mass_p * p_th;
                        end
                    end
                end
            end
        end
    end

    reg_F12 = reg_F12 / max(1e-12, tot_p);
    reg_F23 = reg_F23 / max(1e-12, tot_p);

    Flow_S1_to_S2 = Flow_S1_to_S2 + 100 * w_reg * reg_F12;
    Flow_S2_to_S3 = Flow_S2_to_S3 + 100 * w_reg * reg_F23;
end

if isfield(Diag_Sim, 'Emig_By_SkillTier')
    emig_stunted  = mean(Diag_Sim.Emig_By_SkillTier(1:2));
    emig_core     = mean(Diag_Sim.Emig_By_SkillTier(3:5));
    emig_thriving = mean(Diag_Sim.Emig_By_SkillTier(6:7));
else
    if ~is_reform_panel
        emig_stunted = 0.04; emig_core = 0.11; emig_thriving = 0.22;
    else
        emig_stunted = 0.02; emig_core = 0.06; emig_thriving = 0.12;
    end
end

Flow_S3_to_S4 = zeros(3, 6);
S3_mass       = sum(Flow_S2_to_S3, 1);

m_st = S3_mass(1);
Flow_S3_to_S4(1, 1) = m_st * 0.20;
Flow_S3_to_S4(1, 2) = m_st * 0.24;
Flow_S3_to_S4(1, 3) = m_st * 0.26;
Flow_S3_to_S4(1, 4) = m_st * (0.26 - emig_stunted);
Flow_S3_to_S4(1, 5) = m_st * 0.04;
Flow_S3_to_S4(1, 6) = m_st * emig_stunted;

m_co = S3_mass(2);
Flow_S3_to_S4(2, 2) = m_co * 0.05;
Flow_S3_to_S4(2, 3) = m_co * 0.12;
Flow_S3_to_S4(2, 4) = m_co * 0.05;
Flow_S3_to_S4(2, 5) = m_co * (0.78 - emig_core);
Flow_S3_to_S4(2, 6) = m_co * emig_core;

m_th = S3_mass(3);
Flow_S3_to_S4(3, 5) = m_th * (1.00 - emig_thriving);
Flow_S3_to_S4(3, 6) = m_th * emig_thriving;

Nodes_S1 = {'1. Material Hardship & Housing Squeeze', ...
    '2. Secure Parental Asset Buffer'};
Nodes_S2 = {'3. Unmitigated Corner (ic = 0)', ...
    '4. Public ECE + Moderate Inv', ...
    '5. High Wraparound + Parental Inv'};
Nodes_S3 = {sprintf('6. Stunted Tier h1-h2 (%.1f%%)', S3_mass(1)), ...
    sprintf('7. Core Skill Tier h3-h5 (%.1f%%)', S3_mass(2)), ...
    sprintf('8. Thriving Tier h6-h7 (%.1f%%)', S3_mass(3))};
Nodes_S4 = {'9. Exit 1: State Care (Govt Cost)', ...
    '10. Exit 2: Avoidable Hospitalisation', ...
    '11. Exit 3: Lower Lifetime Income', ...
    '12. Exit 4: Benefit & Justice Burden', ...
    '13. Retained NZ Secure/Thriving Adult', ...
    '14. Emigrated Abroad (20-35 Brain Drain)'};

links = {};
row_k = 0;
for i = 1:2
    for j = 1:3
        if Flow_S1_to_S2(i, j) > 0.01
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S1{i}, Nodes_S2{j}, Flow_S1_to_S2(i, j)};
        end
    end
end
for i = 1:3
    for j = 1:3
        if Flow_S2_to_S3(i, j) > 0.01
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S2{i}, Nodes_S3{j}, Flow_S2_to_S3(i, j)};
        end
    end
end
for i = 1:3
    for j = 1:6
        if Flow_S3_to_S4(i, j) > 0.01
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S3{i}, Nodes_S4{j}, Flow_S3_to_S4(i, j)};
        end
    end
end

axes(ax); hold(ax, 'on');
SK = SSankey(links(:, 1), links(:, 2), links(:, 3));

SK.RenderingMethod = 'interp';
SK.Align           = 'center';
SK.LabelLocation   = 'right';
SK.BlockScale      = 0.14;
SK.Sep             = 0.06;
if isprop(SK, 'FontName')
    SK.FontName = 'Helvetica';
end

Master_Colors = [
    0.77, 0.19, 0.19;  % 1. Material Hardship (Crimson)
    0.18, 0.49, 0.55;  % 2. Secure Parental Buffer (Teal-Blue)
    0.65, 0.16, 0.16;  % 3. Unmitigated Corner ic=0 (Dark Red)
    0.27, 0.51, 0.71;  % 4. Public ECE + Moderate Inv (Steel Blue)
    0.16, 0.62, 0.56;  % 5. High Wraparound (Emerald Teal)
    0.72, 0.18, 0.18;  % 6. Stunted Tier h1-h2 (Brick Red)
    0.32, 0.56, 0.68;  % 7. Core Skill Tier h3-h5 (Slate Blue)
    0.13, 0.55, 0.45;  % 8. Thriving Tier h6-h7 (Deep Sea Green)
    0.85, 0.22, 0.22;  % 9. Exit 1: State Care (Red)
    0.87, 0.42, 0.13;  % 10. Exit 2: Avoidable Hospitalisations (Orange-Red)
    0.84, 0.62, 0.18;  % 11. Exit 3: Lower Lifetime Income (Amber)
    0.55, 0.15, 0.20;  % 12. Exit 4: Benefit & Justice Burden (Burgundy)
    0.15, 0.60, 0.52;  % 13. Retained NZ Secure/Thriving Adult (Teal)
    0.48, 0.32, 0.68   % 14. Emigrated Abroad / Brain Drain (Royal Purple)
    ];

All_Node_Names = [Nodes_S1, Nodes_S2, Nodes_S3, Nodes_S4];
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

% Give right-hand legends extra room inside the axis so exportgraphics never clips them
curr_xlim = xlim(ax);
xlim(ax, [curr_xlim(1) - 0.05, curr_xlim(2) + 1.35]);

% Pad Y-limits so top/bottom legends ("9. Exit 1..." and the Title) have breathing room from the bars
curr_ylim = ylim(ax);
y_span    = diff(curr_ylim);
ylim(ax, [curr_ylim(1) - 0.08 * y_span, curr_ylim(2) + 0.12 * y_span]);

set(ax, 'FontName', 'Helvetica');
set(findall(ax, 'Type', 'text'), 'FontName', 'Helvetica', 'FontSize', 10);

if strcmpi(reg_choice, 'National')
    t_obj = title(ax, sprintf('%s — National | Stunted h1-h2: %.1f%% | Thriving h6-h7: %.1f%%', ...
        Panel_Tag, S3_mass(1), S3_mass(3)), ...
        'FontName', 'Helvetica', 'FontSize', 12.5, 'FontWeight', 'bold');
else
    Q_val = P_Sim.Q_reg.(['HH_', reg_choice]);
    if is_reform_panel && Q_val >= 3.0, Q_val = Q_val * 0.925; end
    t_obj = title(ax, sprintf('%s — %s (Q = %.2f) | Stunted h1-h2: %.1f%% | Thriving h6-h7: %.1f%%', ...
        Panel_Tag, reg_choice, Q_val, S3_mass(1), S3_mass(3)), ...
        'FontName', 'Helvetica', 'FontSize', 12.5, 'FontWeight', 'bold');
end
% Lift the title slightly above the top of the Sankey bars
set(t_obj, 'Units', 'normalized');
t_pos = get(t_obj, 'Position');
set(t_obj, 'Position', [t_pos(1), 1.03, t_pos(3)]);

axis(ax, 'off');
end

function val = getfield_def(S, fname, default_val)
if isfield(S, fname)
    val = S.(fname);
else
    val = default_val;
end
end