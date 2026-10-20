%% PLOT_CHILDFATES_2PANEL_SSANKEY.M
% Five-Stage (J=1, J=2-3, J=5, J=6-7, J=10) Two-Panel Sankey Diagram
% Exposes Stage J=5 (Age 12-14): Family Unemployment Stress (z_1) vs.
% Montessori Cross-Age Mentoring ("Banking" First-2000-Days Gains).

%% 1. CONFIGURATION SWITCHES
Target_Region      = 'Rural';   % 'Auckland', 'Urban', 'National', 'Large', 'Small', 'Rural'
Calibration_Anchor = 'Dunedin_22'; % 'Dunedin_22' (~17.9% baseline) or 'MetroSqueeze_GUiNZ' (~36.6% baseline)
Merge_Orientation  = 'Vertical';   % 'Vertical' (Stacked Top/Bottom) or 'Horizontal' (Side-by-Side)
Out_PNG_Name       = sprintf('Fig_ChildFates_5Stage_2Panel_%s_%s.png', Target_Region, Calibration_Anchor);

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
    Q_mult_Map  = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);
    for r_i = 1:length(Regions)
        reg = Regions{r_i};
        hk  = ['HH_', reg];
        if isfield(P_SS0.Q_reg, hk) && isfield(Q_mult_Map, reg)
            P_SS1.Q_reg.(hk) = P_SS0.Q_reg.(hk) * Q_mult_Map.(reg);
        end
    end
    Diag_SS1 = Diag_SS0;
    if isfield(Diag_SS1, 'Emig_By_SkillTier')
        Diag_SS1.Emig_By_SkillTier = Diag_SS0.Emig_By_SkillTier * 0.55;
    else
        Diag_SS1.Emig_By_SkillTier = [0.02, 0.02, 0.05, 0.06, 0.07, 0.11, 0.12];
    end
end

%% 3. RENDER PANEL A & PANEL B AND MERGE INTO A SINGLE HIGH-RES IMAGE
figA = figure('Color', 'w', 'Position', [50, 50, 1480, 720], 'Visible', 'on');
axA  = axes('Parent', figA, 'Position', [0.02, 0.06, 0.95, 0.86]);
Build_And_Render_Panel(axA, Target_Region, Dist_SS0, Pol_SS0, P_SS0, Diag_SS0, ...
    n_d, n_a, n_z, d_grid, a_grid, Regions, 'A. Status Quo Baseline (SS0)', ...
    Calibration_Anchor, false);
drawnow;
tmpA = [tempname, '_PanelA.png'];
imgA = AutoCrop_White_Border(print(figA, '-RGBImage', '-r300'));
close(figA);

figB = figure('Color', 'w', 'Position', [50, 50, 1480, 720], 'Visible', 'on');
axB  = axes('Parent', figB, 'Position', [0.02, 0.06, 0.95, 0.86]);
Build_And_Render_Panel(axB, Target_Region, Dist_SS1, Pol_SS1, P_SS1, Diag_SS1, ...
    n_d, n_a, n_z, d_grid, a_grid, Regions, 'B. High-Opportunity Reform + Montessori Mentoring (SS1)', ...
    Calibration_Anchor, true);
drawnow;
imgB = AutoCrop_White_Border(print(figB, '-RGBImage', '-r300'));
close(figB);

% Match dimensions and add generous whitespace around all text legends & titles
[hA, wA, ~] = size(imgA);
[hB, wB, ~] = size(imgB);

if strcmpi(Merge_Orientation, 'Vertical')
    W_max    = max(wA, wB);
    pad_L    = 65;
    pad_R    = 95;
    W_canvas = W_max + pad_L + pad_R;

    imgA_pad = uint8(255 * ones(hA, W_canvas, 3));
    imgA_pad(:, (pad_L+1):(pad_L+wA), :) = imgA;

    imgB_pad = uint8(255 * ones(hB, W_canvas, 3));
    imgB_pad(:, (pad_L+1):(pad_L+wB), :) = imgB;

    top_frame_pad    = uint8(255 * ones(90, W_canvas, 3)); % Above Panel A Title
    gap_below_PanelA = uint8(255 * ones(80, W_canvas, 3)); % Below Panel A J-Axis
    divider_line     = uint8(220 * ones(4,  W_canvas, 3)); % Subtle hairline
    gap_above_PanelB = uint8(255 * ones(90, W_canvas, 3)); % Above Panel B Title
    bot_frame_pad    = uint8(255 * ones(90, W_canvas, 3)); % Below Panel B J-Axis

    img_Merged = [top_frame_pad; imgA_pad; gap_below_PanelA; divider_line; gap_above_PanelB; imgB_pad; bot_frame_pad];
    fig_pos    = [80, 20, 1320, 1080];
else
    H_max    = max(hA, hB);
    pad_T    = 90; pad_B = 90;
    H_canvas = H_max + pad_T + pad_B;
    imgA_pad = uint8(255 * ones(H_canvas, wA, 3)); imgA_pad((pad_T+1):(pad_T+hA), :, :) = imgA;
    imgB_pad = uint8(255 * ones(H_canvas, wB, 3)); imgB_pad((pad_T+1):(pad_T+hB), :, :) = imgB;
    left_pad  = uint8(255 * ones(H_canvas, 65, 3));
    mid_gap   = uint8(255 * ones(H_canvas, 120, 3));
    right_pad = uint8(255 * ones(H_canvas, 95, 3));
    img_Merged = [left_pad, imgA_pad, mid_gap, imgB_pad, right_pad];
    fig_pos    = [20, 80, 1860, 740];
end

imwrite(img_Merged, fullfile(OutputDir, Out_PNG_Name));
fprintf('Saved merged 5-stage 2-panel Sankey image to: %s\n', fullfile(OutputDir, Out_PNG_Name));

fig_Merged = figure('Name', ['Merged 5-Stage Child Fates: ', Target_Region], ...
    'Color', 'w', 'Position', fig_pos);
ax_M = axes('Parent', fig_Merged, 'Position', [0, 0, 1, 1]);
imshow(img_Merged, 'Parent', ax_M, 'Border', 'tight');
axis(ax_M, 'off');


%% ========================================================================
%  LOCAL HELPER: COMPUTE 5-STAGE FLOWS & RENDER SINGLE SANKEY PANEL
%  ========================================================================
function Build_And_Render_Panel(ax, reg_choice, Dist_Sim, Pol_Sim, ...
    P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, Regions, Panel_Tag, ...
    Calibration_Anchor, is_reform_panel)

% 1. Inspect actual HH_* fields present inside Dist_Sim
f_all   = fieldnames(Dist_Sim);
hh_f    = f_all(strncmp(f_all, 'HH_', 3));
avail_r = erase(hh_f, 'HH_');
N_reg   = length(avail_r);

all_w   = P_Sim.PTypeWeights(1:N_reg);
all_w   = all_w(:) / sum(all_w);

if strcmpi(reg_choice, 'National')
    reg_list    = avail_r(:)';
    pop_weights = all_w;
elseif strcmpi(reg_choice, 'Urban') && ~ismember('Urban', avail_r)
    urb_mask    = ismember(avail_r, {'Small', 'Large', 'Auckland'});
    reg_list    = avail_r(urb_mask)';
    pop_weights = all_w(urb_mask) / sum(all_w(urb_mask));
elseif strcmpi(reg_choice, 'ProvincialUrban') && ~ismember('ProvincialUrban', avail_r)
    prov_mask   = ismember(avail_r, {'Small', 'Large'});
    reg_list    = avail_r(prov_mask)';
    pop_weights = all_w(prov_mask) / sum(all_w(prov_mask));
else
    reg_list    = {reg_choice};
    pop_weights = 1.0;
end

ref_type = ['HH_', avail_r{1}];
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

% Bidirectional Montessori Cross-Age Mentoring Dividend in Reform (SS1):
%   1. Downward spillover: J=5 adolescent mentors boost effective Early ECE by +15%
%   2. Upward ("Protege Effect") spillover: buffers J=5 adolescents against family stress & locks in gains
if is_reform_panel
    if G_ece <= 0.06, G_ece = G_ece + 0.14; end
    G_ece_eff       = G_ece * 1.15; % Downward mentoring boost to J=2-3 children
    montessori_bank = +0.11;        % Upward non-cognitive boost to J=5 adolescent mentors
else
    G_ece_eff       = G_ece;
    montessori_bank = +0.05;
end

% 5-Stage Flow Accumulators:
%   Stage 1 (J=1, 2 nodes)   -> Stage 2 (J=2-3, 3 nodes): 2x3
%   Stage 2 (J=2-3, 3 nodes) -> Stage 3 (J=5, 3 nodes):   3x3
%   Stage 3 (J=5, 3 nodes)   -> Stage 4 (J=6-7, 3 nodes): 3x3
Flow_S1_to_S2 = zeros(2, 3);
Flow_S2_to_S3 = zeros(3, 3);
Flow_S3_to_S4 = zeros(3, 3);

Q_base_Map = struct('Rural', 1.05, 'Small', 1.40, 'Urban', 1.75, 'Large', 2.05, 'Auckland', 3.10);
Q_mult_Map = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);

for r_i = 1:length(reg_list)
    reg     = reg_list{r_i};
    w_reg   = pop_weights(r_i);
    hh_type = ['HH_', reg];

    Dist_k  = Dist_Sim.(hh_type);
    Pol_k   = Pol_Sim.(hh_type);
    Q_house = P_Sim.Q_reg.(hh_type);
    if is_reform_panel && isfield(Q_base_Map, reg) && abs(Q_house - Q_base_Map.(reg)) < 1e-3
        Q_house = Q_house * Q_mult_Map.(reg);
    end

    % --- GPU-VECTORIZED 5-STAGE CHILDHOOD FLOW TENSORS ACROSS [ia, ih, iz, jf] ---
    use_gpu = (gpuDeviceCount > 0);
    if use_gpu
        Dist_Fert = gpuArray(double(Dist_k(:, :, :, fertile_j)));  % [n_a1, n_h, n_z1, 2]
        Pol_Fert  = gpuArray(double(Pol_k(3, :, :, :, fertile_j)));
        a_G       = gpuArray(reshape(double(a_vec), [n_a1, 1, 1, 1]));
        h_G       = gpuArray(reshape(double(h_vec), [1, n_h, 1, 1]));
        ic_G      = gpuArray(double(ic_vec(:)));
        z_idx_3D  = gpuArray(reshape(1:n_z1, [1, 1, n_z1, 1]));
        log_h_dst = gpuArray(reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]));
    else
        Dist_Fert = double(Dist_k(:, :, :, fertile_j));
        Pol_Fert  = double(Pol_k(3, :, :, :, fertile_j));
        a_G       = reshape(double(a_vec), [n_a1, 1, 1, 1]);
        h_G       = reshape(double(h_vec), [1, n_h, 1, 1]);
        ic_G      = double(ic_vec(:));
        z_idx_3D  = reshape(1:n_z1, [1, 1, n_z1, 1]);
        log_h_dst = reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]);
    end

    tot_p    = max(1e-12, gather(sum(Dist_Fert(:))));
    d_ic_idx = max(1, min(length(ic_vec), Pol_Fert));
    ic_4D    = reshape(ic_G(d_ic_idx(:)), size(Dist_Fert));        % [n_a1, n_h, n_z1, 2]

    % Stage 1 (J=1): Material Hardship & Housing Squeeze vs. Secure Asset Buffer
    is_hard_4D = (a_G < 0.08 * Q_house);                           % [n_a1, 1, 1, 1]
    mask_s1_1  = is_hard_4D;
    mask_s1_2  = ~is_hard_4D;

    % Stage 2 (J=2-3): First 2000 Days Gate Weights [n_a1, n_h, n_z1, 2]
    m_corner = (ic_4D <= 1e-5);
    m_mod    = (~m_corner) & (ic_4D <= 0.35 * max(ic_vec));
    m_high   = (~m_corner) & (~m_mod);

    if ~is_reform_panel
        s2_W1 = 1.00 .* m_corner;
        s2_W2 = 1.00 .* m_mod;
        s2_W3 = 1.00 .* m_high;
    else
        s2_W1 = 0.22 .* m_corner;
        s2_W2 = 0.78 .* m_corner + 1.00 .* m_mod;
        s2_W3 = 1.00 .* m_high;
    end
    s2_W_5D = cat(5, s2_W1, s2_W2, s2_W3);                         % [n_a1, n_h, n_z1, 2, 3]

    reg_F12 = zeros(2, 3);
    for s2_i = 1:3
        reg_F12(1, s2_i) = gather(sum(Dist_Fert .* s2_W_5D(:, :, :, :, s2_i) .* mask_s1_1,'all') / tot_p); % Wait: broadcast mask_s1_1 first!
    end
    % Proper broadcasted Stage 1 -> Stage 2 sum:
    for s2_i = 1:3
        w_s2 = Dist_Fert .* s2_W_5D(:, :, :, :, s2_i);
        reg_F12(1, s2_i) = gather(sum(w_s2 .* mask_s1_1,'all')) / tot_p;
        reg_F12(2, s2_i) = gather(sum(w_s2 .* mask_s1_2,'all')) / tot_p;
    end

    % Stage 3 (J=5, Age 12-14): Early Adolescence & Montessori Mentoring Gate
    is_unemp_4D = (z_idx_3D == 1) | (n_z1 >= 5 & (z_idx_3D == 2) & is_hard_4D);

    % Transition probability tables p_s3(s2_i, s3_i) for Unemployed Stress vs. Stable
    if ~is_reform_panel
        P_unemp = [0.82, 0.16, 0.02;
            0.55, 0.37, 0.08;
            0.28, 0.54, 0.18];
        P_stabl = [0.35, 0.58, 0.07;
            0.12, 0.68, 0.20;
            0.05, 0.55, 0.40];
    else
        P_unemp = [0.38, 0.34, 0.28;
            0.16, 0.36, 0.48;
            0.08, 0.30, 0.62];
        P_stabl = [0.14, 0.46, 0.40;
            0.04, 0.38, 0.58;
            0.02, 0.26, 0.72];
    end

    % Precompute Stage 3 -> Stage 4 Gaussian Skill Transition Probabilities on GPU
    inv_gap_4D = log(ic_4D + G_ece_eff + 0.02) - log(0.20 + 0.05 + 0.02);
    if strcmpi(Calibration_Anchor, 'Dunedin_22')
        crowd_pen_4D = 0.14 * log(max(1.0, Q_house)) .* is_hard_4D;
        grid_anchor  = +0.040;
    else
        crowd_pen_4D = 0.18 * log(max(1.0, Q_house)) .* is_hard_4D;
        grid_anchor  = -0.125;
    end
    base_log_h_4D = rho_hc .* log(h_G) + gamma_ic .* inv_gap_4D - crowd_pen_4D + grid_anchor;
    s3_shifts     = [-0.22, 0.00, montessori_bank];

    % Precompute p_st, p_co, p_th 4D tensors for each s3_i in {1, 2, 3}
    p_st_cell = cell(1, 3);
    p_co_cell = cell(1, 3);
    p_th_cell = cell(1, 3);
    for s3_i = 1:3
        mean_4D = base_log_h_4D + s3_shifts(s3_i);
        pdf_5D  = exp(-0.5 .* ((log_h_dst - mean_4D) ./ sig_hc).^2);
        pdf_5D  = pdf_5D ./ sum(pdf_5D, 5);
        p_st_cell{s3_i} = sum(pdf_5D(:, :, :, :, 1:2), 5);
        p_co_cell{s3_i} = sum(pdf_5D(:, :, :, :, 3:5), 5);
        p_th_cell{s3_i} = sum(pdf_5D(:, :, :, :, 6:7), 5);
    end

    reg_F23 = zeros(3, 3);
    reg_F34 = zeros(3, 3);
    for s2_i = 1:3
        m_s2_4D = Dist_Fert .* s2_W_5D(:, :, :, :, s2_i);
        for s3_i = 1:3
            p_s3_4D = P_unemp(s2_i, s3_i) .* is_unemp_4D + P_stabl(s2_i, s3_i) .* (~is_unemp_4D);
            m_s3_4D = m_s2_4D .* p_s3_4D;

            reg_F23(s2_i, s3_i) = gather(sum(m_s3_4D(:))) / tot_p;

            reg_F34(s3_i, 1) = reg_F34(s3_i, 1) + gather(sum(m_s3_4D(:) .* p_st_cell{s3_i}(:))) / tot_p;
            reg_F34(s3_i, 2) = reg_F34(s3_i, 2) + gather(sum(m_s3_4D(:) .* p_co_cell{s3_i}(:))) / tot_p;
            reg_F34(s3_i, 3) = reg_F34(s3_i, 3) + gather(sum(m_s3_4D(:) .* p_th_cell{s3_i}(:))) / tot_p;
        end
    end

    Flow_S1_to_S2 = Flow_S1_to_S2 + 100 * w_reg * reg_F12;
    Flow_S2_to_S3 = Flow_S2_to_S3 + 100 * w_reg * reg_F23;
    Flow_S3_to_S4 = Flow_S3_to_S4 + 100 * w_reg * reg_F34;
end

% Stage 4 (J=6-7) -> Stage 5 (J=10): Priced Fiscal Exits, Domestic Retention & Brain Drain
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

Flow_S4_to_S5 = zeros(3, 6);
S3_J5_mass    = sum(Flow_S2_to_S3, 1); % [UnempStress_Mass, Standard_Mass, Montessori_Mass] at J=5
S4_Skill_mass = sum(Flow_S3_to_S4, 1); % [Stunted_Mass, Core_Mass, Thriving_Mass] at J=6-7

m_st = S4_Skill_mass(1);
Flow_S4_to_S5(1, 1) = m_st * 0.20;
Flow_S4_to_S5(1, 2) = m_st * 0.24;
Flow_S4_to_S5(1, 3) = m_st * 0.26;
Flow_S4_to_S5(1, 4) = m_st * (0.26 - emig_stunted);
Flow_S4_to_S5(1, 5) = m_st * 0.04;
Flow_S4_to_S5(1, 6) = m_st * emig_stunted;

m_co = S4_Skill_mass(2);
Flow_S4_to_S5(2, 2) = m_co * 0.05;
Flow_S4_to_S5(2, 3) = m_co * 0.12;
Flow_S4_to_S5(2, 4) = m_co * 0.05;
Flow_S4_to_S5(2, 5) = m_co * (0.78 - emig_core);
Flow_S4_to_S5(2, 6) = m_co * emig_core;

m_th = S4_Skill_mass(3);
Flow_S4_to_S5(3, 5) = m_th * (1.00 - emig_thriving);
Flow_S4_to_S5(3, 6) = m_th * emig_thriving;

%% BUILD 5-STAGE LINK LIST FOR slandarer's SSankey
Nodes_S1 = {'1. Material Hardship & Housing Squeeze', ...
    '2. Secure Parental Asset Buffer'};
Nodes_S2 = {'3. Unmitigated Corner (ic = 0)', ...
    '4. Public ECE + Moderate Inv', ...
    '5. High Wraparound + Parental Inv'};
Nodes_S3 = {sprintf('6. Family Unemp Stress z1 (%.1f%%)', S3_J5_mass(1)), ...
    sprintf('7. Standard Schooling (%.1f%%)', S3_J5_mass(2)), ...
    sprintf('8. Montessori Peer Mentoring (%.1f%%)', S3_J5_mass(3))};
Nodes_S4 = {sprintf('9. Stunted Tier h1-h2 (%.1f%%)', S4_Skill_mass(1)), ...
    sprintf('10. Core Skill Tier h3-h5 (%.1f%%)', S4_Skill_mass(2)), ...
    sprintf('11. Thriving Tier h6-h7 (%.1f%%)', S4_Skill_mass(3))};
Nodes_S5 = {'12. Exit 1: State Care (Govt Cost)', ...
    '13. Exit 2: Avoidable Hospitalisation', ...
    '14. Exit 3: Lower Lifetime Income', ...
    '15. Exit 4: Benefit & Justice Burden', ...
    '16. Retained NZ Secure/Thriving Adult', ...
    '17. Emigrated Abroad (20-35 Brain Drain)'};

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
    for j = 1:3
        if Flow_S3_to_S4(i, j) > 0.01
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S3{i}, Nodes_S4{j}, Flow_S3_to_S4(i, j)};
        end
    end
end
for i = 1:3
    for j = 1:6
        if Flow_S4_to_S5(i, j) > 0.01
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S4{i}, Nodes_S5{j}, Flow_S4_to_S5(i, j)};
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

% 17-Node Cohesive Color Palette across the 5 Stages
Master_Colors = [
    0.77, 0.19, 0.19;  % 1. Material Hardship (Crimson)
    0.18, 0.49, 0.55;  % 2. Secure Parental Buffer (Teal-Blue)
    0.65, 0.16, 0.16;  % 3. Unmitigated Corner ic=0 (Dark Red)
    0.27, 0.51, 0.71;  % 4. Public ECE + Moderate Inv (Steel Blue)
    0.16, 0.62, 0.56;  % 5. High Wraparound (Emerald Teal)
    0.80, 0.28, 0.16;  % 6. J=5 Family Unemp Stress z1 (Rust Red-Orange)
    0.36, 0.54, 0.66;  % 7. J=5 Standard Schooling (Slate Blue)
    0.12, 0.64, 0.48;  % 8. J=5 Montessori Peer Mentoring (Vibrant Sea Green)
    0.72, 0.18, 0.18;  % 9. Stunted Tier h1-h2 (Brick Red)
    0.32, 0.56, 0.68;  % 10. Core Skill Tier h3-h5 (Slate Blue)
    0.13, 0.55, 0.45;  % 11. Thriving Tier h6-h7 (Deep Sea Green)
    0.85, 0.22, 0.22;  % 12. Exit 1: State Care (Red)
    0.87, 0.42, 0.13;  % 13. Exit 2: Avoidable Hospitalisations (Orange-Red)
    0.84, 0.62, 0.18;  % 14. Exit 3: Lower Lifetime Income (Amber)
    0.55, 0.15, 0.20;  % 15. Exit 4: Benefit & Justice Burden (Burgundy)
    0.15, 0.60, 0.52;  % 16. Retained NZ Secure/Thriving Adult (Teal)
    0.48, 0.32, 0.68   % 17. Emigrated Abroad / Brain Drain (Royal Purple)
    ];

All_Node_Names = [Nodes_S1, Nodes_S2, Nodes_S3, Nodes_S4, Nodes_S5];
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
xlim(ax, [curr_xlim(1) - 0.02, curr_xlim(2) + 1.45]);

% Pad Y-limits for the 5-column J-axis at the bottom and Title at the top
curr_ylim = ylim(ax);
y_span    = diff(curr_ylim);
ylim(ax, [curr_ylim(1) - 0.23 * y_span, curr_ylim(2) + 0.12 * y_span]);

set(ax, 'FontName', 'Helvetica');
set(findall(ax, 'Type', 'text'), 'FontName', 'Helvetica', 'FontSize', 9.2);

%% DRAW 5-COLUMN HORIZONTAL "J" LIFECYCLE AXIS ALIGNED TO CENTER OF BLOCKS
y_axis_line = curr_ylim(1) - 0.09 * y_span;
tick_h      = 0.022 * y_span;

p_objs       = findall(ax, 'Type', 'Patch');
block_centers = [];
for k_p = 1:length(p_objs)
    xd = get(p_objs(k_p), 'XData');
    if numel(xd) == 4
        block_centers(end+1) = sum(xd(:))/4; %#ok<AGROW>
    end
end
if numel(block_centers) >= 5
    x_center_cols = zeros(1, 5);
    for c_i = 1:5
        near_c = block_centers(abs(block_centers - c_i) < 0.45);
        if ~isempty(near_c)
            x_center_cols(c_i) = max(near_c);
        else
            x_center_cols(c_i) = c_i + 0.08;
        end
    end
else
    x_center_cols = [1, 2, 3, 4, 5] + 0.08;
end

plot(ax, [x_center_cols(1), x_center_cols(5)], [y_axis_line, y_axis_line], '-', ...
    'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.4);

J_Stage_Labels = {
    sprintf('J = 1\n(Birth / Entry, Age 0)');
    sprintf('J = 2 - 3\n(First 2000 Days, Ages 0-5)');
    sprintf('J = 5\n(Adolescent Gate, Ages 12-14)');
    sprintf('J = 6 - 7\n(Adult Skill Launch, Age 20)');
    sprintf('J = 10\n(Adulthood Fates, Age 30+)')
    };

for col_x = 1:5
    x_tick = x_center_cols(col_x);
    plot(ax, [x_tick, x_tick], [y_axis_line - tick_h, y_axis_line + tick_h], '-', ...
        'Color', [0.25, 0.25, 0.25], 'LineWidth', 1.5);

    if col_x == 1
        h_align = 'left'; % Prevents J=1 from overflowing left border
    else
        h_align = 'center';
    end

    text(ax, x_tick, y_axis_line - 1.6 * tick_h, J_Stage_Labels{col_x}, ...
        'HorizontalAlignment', h_align, 'VerticalAlignment', 'top', ...
        'FontName', 'Helvetica', 'FontSize', 9.2, 'FontWeight', 'bold', ...
        'Color', [0.20, 0.20, 0.20]);
end

%% COMPUTE WEIGHTED MEAN Q FOR TITLE (SAFE FOR SINGLE OR COMPOSITE REGIONS)
Q_val = 0;
for r_i = 1:length(reg_list)
    r_name = reg_list{r_i};
    q_r    = P_Sim.Q_reg.(['HH_', r_name]);
    if is_reform_panel && isfield(Q_base_Map, r_name) && abs(q_r - Q_base_Map.(r_name)) < 1e-3
        q_r = q_r * Q_mult_Map.(r_name);
    end
    Q_val = Q_val + pop_weights(r_i) * q_r;
end

if strcmpi(reg_choice, 'Urban') && length(reg_list) > 1
    disp_reg = 'Urban (Auckland + Large + Small)';
elseif strcmpi(reg_choice, 'National')
    disp_reg = 'National (All Regions)';
else
    disp_reg = reg_choice;
end

t_obj = title(ax, sprintf('%s — %s (Mean Q = %.2f) | J=5 Unemp Stress: %.1f%% | Stunted h1-h2: %.1f%% | Thriving: %.1f%%', ...
    Panel_Tag, disp_reg, Q_val, S3_J5_mass(1), S4_Skill_mass(1), S4_Skill_mass(3)), ...
    'FontName', 'Helvetica', 'FontSize', 12, 'FontWeight', 'bold');
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

function img_cropped = AutoCrop_White_Border(img)
is_nonwhite = any(img < 252, 3);
rows = find(any(is_nonwhite, 2));
cols = find(any(is_nonwhite, 1));
if ~isempty(rows) && ~isempty(cols)
    img_cropped = img(min(rows):max(rows), min(cols):max(cols), :);
else
    img_cropped = img;
end
end
