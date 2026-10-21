%% PLOT_CHILDFATES_2PANEL_SSANKEY.M
% 5-Stage (17-Node) Pairwise 2-Panel Cohort Population Sankey Diagram (A3 Layout, 100% GPU-Vectorized)
% Synchronized 100% with Plot_ChildFiscal_2Panel_SSankey.m (Table 14) and exports Table 15 CSVs:
%   - Gate 1 (J = 1, Birth / Entry, Age 0):
%       (1) Material Hardship & Housing Squeeze (~25.8% SS0 -> ~7.7% SS1) vs. (2) Secure Parental Asset Buffer
%   - Gate 2 (J = 2..3, First 2000 Days ECE Gate, Ages 0-5):
%       (3) Unmitigated Corner ic=0 (~25.8% -> ~5.7%), (4) Public ECE + Moderate Inv, (5) High Wraparound + Time
%   - Gate 3 (J = 5, Adolescent Gate, Ages 12-14):
%       (6) Family Unemp Stress z1 (~18.9% -> ~4.9%), (7) Standard Schooling, (8) Montessori / Tuakana Mentoring (~17.3% -> ~57.3%)
%   - Gate 4 (J = 6..7, Adult Skill Launch, Age 20):
%       (9) Stunted Tier h1-h2 (~74.7% -> ~4.0%), (10) Core Skill Tier h3-h5 (~22.8% -> ~80.6%), (11) Thriving Tier h6-h7 (~2.5% -> ~15.4%)
%   - Gate 5 (J = 10, Adulthood Fates, Age 30+):
%       (12) Exit 1: State Care, (13) Exit 2: Avoidable Hospitalisation, (14) Exit 3: Lower Lifetime Income,
%       (15) Exit 4: Benefit & Justice Burden, (16) Retained NZ Secure/Thriving Adult, (17) Emigrated Abroad (20-35 Brain Drain)

%% 1. CONFIGURATION SWITCHES (N-PHASE COMPATIBLE: 1, 2, 3, OR MORE PANELS)
Target_Regions     = {'National', 'Auckland', 'Large', 'Small', 'Rural', 'Urban'};
if ischar(Target_Regions) || isstring(Target_Regions), Target_Regions = cellstr(Target_Regions); end

% Specify any 1, 2, 3, or N phases: e.g. {'SS0'}, {'SS0','SS1'}, or {'SS0','SS1','SS2'}
if ~exist('Active_Phases', 'var') || isempty(Active_Phases)
    Active_Phases = {'SS0', 'SS1'};
end
Calibration_Anchor = 'Dunedin_22'; % 'Dunedin_22' or 'MetroSqueeze_GUiNZ'
Merge_Orientation  = 'Vertical';   % 'Vertical' (Stacked Top/Bottom for A3) or 'Horizontal'

if ~exist('OutputDir', 'var') || ~isfolder(OutputDir)
    if isfolder('Output_NZ_4Region_Intergen')
        OutputDir = 'Output_NZ_4Region_Intergen';
    else
        OutputDir = pwd;
    end
end

%% 2. ASSEMBLE N-PHASE REGISTRY (SUPPORTS 1, 2, 3, ... N PHASES)
Phases   = Build_Phase_Registry(Active_Phases);
N_phases = numel(Phases);

%% 3. RENDER 1..N PANELS ON A3 CANVASES, STITCH, AND EXPORT N-PHASE TABLE 15 CSVs
FatesLedger = struct();

Fate_Gates = { ...
    'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0'; ...
    'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; ...
    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14'; ...
    'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20'; ...
    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30'; ...
    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30'};

Fate_Node_Names = { ...
    '1_Material_Hardship_Housing_Squeeze'; '2_Secure_Parental_Asset_Buffer'; ...
    '3_Unmitigated_Corner_ic0';            '4_Public_ECE_Moderate_Inv';           '5_High_Wraparound_Parental_Inv'; ...
    '6_Family_Unemp_Stress_z1';            '7_Standard_Public_Schooling';         '8_Montessori_Tuakana_Mentoring'; ...
    '9_Stunted_Tier_h1_h2';                '10_Core_Skill_Tier_h3_h5';            '11_Thriving_Tier_h6_h7'; ...
    '12_Exit1_State_Care';                 '13_Exit2_Avoidable_Hospitalisation';  '14_Exit3_Lower_Lifetime_Income'; ...
    '15_Exit4_Benefit_Justice_Burden';     '16_Retained_NZ_Secure_Thriving';      '17_Emigrated_Abroad_BrainDrain'};

for r_loop = 1:length(Target_Regions)
    Target_Region = Target_Regions{r_loop};
    Out_PNG_Name  = sprintf('Fig_ChildFates_5Stage_%dPanel_%s_%s.png', ...
        N_phases, Target_Region, Calibration_Anchor);

    %% 3.1 RENDER EACH PHASE p = 1..N_phases
    Panel_Imgs = cell(1, N_phases);
    Pop_Mat    = zeros(17, N_phases);

    for p = 1:N_phases
        p_code = Phases(p).Code;
        figP   = figure('Color', 'w', 'Position', [20, 40, 1850, 820], 'Visible', 'on');
        axP    = axes('Parent', figP, 'Position', [0.02, 0.07, 0.95, 0.85]);

        F_p = Build_And_Render_Fates_Panel(axP, Target_Region, ...
            Phases(p).Dist, Phases(p).Pol, Phases(p).Params, Phases(p).Diag, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid, ...
            Phases(p).Label, Calibration_Anchor, Phases(p).Intensity);
        drawnow;
        Panel_Imgs{p} = AutoCrop_White_Border(print(figP, '-RGBImage', '-r300'));
        close(figP);

        FatesLedger.(Target_Region).(p_code) = F_p;
        Pop_Mat(:, p) = reshape(F_p.Pop_17Nodes_Pct, 17, 1);
    end

    %% 3.2 STITCH 1..N PANELS CLEANLY
    [img_Merged, fig_pos] = Stitch_NPanels_Canvas(Panel_Imgs, Merge_Orientation);

    imwrite(img_Merged, fullfile(OutputDir, Out_PNG_Name));
    fprintf('\nSaved %d-panel 5-stage Child Fates Sankey image to: %s\n', N_phases, fullfile(OutputDir, Out_PNG_Name));

    %% 3.3 BUILD CUSTOM 17-NODE TABLE 15 CSV FOR 1, 2, 3, ... N PHASES
    T_FatesCSV = table(Fate_Gates, Fate_Node_Names, 'VariableNames', {'Gate', 'Node_Name'});
    for p = 1:N_phases
        T_FatesCSV.([Phases(p).Code, '_Pop_Pct']) = round(Pop_Mat(:, p), 2);
    end
    if N_phases == 2
        T_FatesCSV.Reform_Delta_PctPt = round(Pop_Mat(:, 2) - Pop_Mat(:, 1), 2);
    elseif N_phases >= 3
        for p = 2:N_phases
            col_d = sprintf('Delta_%s_vs_%s_PctPt', Phases(p).Code, Phases(p-1).Code);
            T_FatesCSV.(col_d) = round(Pop_Mat(:, p) - Pop_Mat(:, p-1), 2);
        end
        col_cum = sprintf('Cumul_%s_vs_%s_PctPt', Phases(N_phases).Code, Phases(1).Code);
        T_FatesCSV.(col_cum) = round(Pop_Mat(:, N_phases) - Pop_Mat(:, 1), 2);
    end

    fates_csv_fname = fullfile(OutputDir, sprintf('Table15_ChildFates_5Stage_Decomp_%s.csv', Target_Region));
    writetable(T_FatesCSV, fates_csv_fname);
    FatesLedger.(Target_Region).Table15_Decomp = T_FatesCSV;
    fprintf('  -> Exported %d-Phase (17-Node) Child Fates CSV to: %s\n', N_phases, fates_csv_fname);

    fig_Merged = figure('Name', sprintf('%d-Panel 5-Stage Child Fates Sankey: %s', N_phases, Target_Region), ...
        'Color', 'w', 'Position', fig_pos);
    ax_M = axes('Parent', fig_Merged, 'Position', [0, 0, 1, 1]);
    imshow(img_Merged, 'Parent', ax_M, 'Border', 'tight');
    axis(ax_M, 'off');
end

%% ========================================================================
%  LOCAL HELPER: GPU-VECTORIZED 5-STAGE (17-NODE) CHILD FATES SANKEY
%  ========================================================================
function Ledger = Build_And_Render_Fates_Panel(ax, reg_choice, Dist_Sim, Pol_Sim, ...
    P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, z_grid, Panel_Tag, ...
    Calibration_Anchor, reform_intensity)

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

n_l    = n_d.(ref_type)(1);
n_Ih   = n_d.(ref_type)(2);
ic_vec = d_grid.(ref_type)(n_l+n_Ih+1 : end);

fertile_j = [3, 4];
rho_hc    = getfield_def(P_Sim, 'rho_hc_ig',   0.40);
gamma_ic  = getfield_def(P_Sim, 'gamma_ic',    0.35);
G_ece     = getfield_def(P_Sim, 'G_ece',       0.05);
sig_hc    = getfield_def(P_Sim, 'sigma_hc_ig', 0.18);

% Map boolean or scalar reform_intensity (0.0 = SS0, 1.0 = SS1, >1.0 = SS2+):
is_reform_panel = (reform_intensity > 0);
eta_ref         = min(1.18, max(0.0, double(reform_intensity)));

if is_reform_panel
    if G_ece <= 0.06, G_ece = G_ece + 0.14 * eta_ref; end
    G_ece_eff       = G_ece * (1.0 + 0.15 * eta_ref); % Montessori / Tuakana downward multiplier
    montessori_bank = 0.05 + 0.06 * eta_ref;          % +0.05 in SS0, +0.11 in SS1, +0.12 in SS2
else
    G_ece_eff       = G_ece;
    montessori_bank = +0.05;
end

Flow_S1_to_S2 = zeros(2, 3);
Flow_S2_to_S3 = zeros(3, 3);
Flow_S3_to_S4 = zeros(3, 3);
Flow_S4_to_S5 = zeros(3, 6);

Q_base_Map = struct('Rural', 1.05, 'Small', 1.40, 'Urban', 1.75, 'Large', 2.05, 'Auckland', 3.10);
Q_mult_Map = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);
mean_Q     = 0;

use_gpu = (gpuDeviceCount > 0);

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
    mean_Q = mean_Q + w_reg * Q_house;

    if use_gpu
        Dist_G     = gpuArray(double(Dist_k));
        Pol_G      = gpuArray(double(Pol_k));
        a_G        = gpuArray(reshape(double(a_vec), [n_a1, 1, 1, 1]));
        h_G        = gpuArray(reshape(double(h_vec), [1, n_h, 1, 1]));
        ic_G       = gpuArray(double(ic_vec(:)));
        z_idx_3D   = gpuArray(reshape(1:n_z1, [1, 1, n_z1, 1]));
        log_h_dst5 = gpuArray(reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]));
    else
        Dist_G     = double(Dist_k);
        Pol_G      = double(Pol_k);
        a_G        = reshape(double(a_vec), [n_a1, 1, 1, 1]);
        h_G        = reshape(double(h_vec), [1, n_h, 1, 1]);
        ic_G       = double(ic_vec(:));
        z_idx_3D   = reshape(1:n_z1, [1, 1, n_z1, 1]);
        log_h_dst5 = reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]);
    end

    Dist_Fert = Dist_G(:, :, :, fertile_j);
    tot_p     = max(1e-12, gather(sum(Dist_Fert, 'all')));

    d_ic_idx  = max(1, min(length(ic_vec), Pol_G(3, :, :, :, fertile_j)));
    ic_4D     = reshape(ic_G(d_ic_idx(:)), size(Dist_Fert));

    is_hard_4D  = (a_G < 0.08 * Q_house);
    is_unemp_4D = (z_idx_3D == 1) | (n_z1 >= 5 & (z_idx_3D == 2) & is_hard_4D);

    % --- STAGE 2 (J = 2..3, Ages 0-5) EXACT POPULATION WEIGHTS (Synchronized with Table 14!) ---
    m_corner = (ic_4D <= 1e-5) & (is_hard_4D | (z_idx_3D <= 2));
    m_mod    = (~m_corner) & ((ic_4D <= 1e-5) | (ic_4D <= 0.35 * max(ic_vec)));
    m_high   = (~m_corner) & (~m_mod);

    lift_s2 = min(0.92, 0.78 * eta_ref);          % 0.00 in SS0, 0.78 in SS1, 0.92 in SS2
    s2_W1   = (1.00 - lift_s2) .* m_corner;       % Node 3: Unmitigated Corner ic=0
    s2_W2   = lift_s2 .* m_corner + 1.00 .* m_mod;% Node 4: Public ECE + Moderate Inv
    s2_W3   = 1.00 .* m_high;                     % Node 5: High Wraparound + Parental Inv
    s2_W_5D = cat(5, s2_W1, s2_W2, s2_W3);

    % --- STAGE 1 (J = 1, Birth, Age 0): MATERIAL HARDSHIP & HOUSING SQUEEZE vs SECURE BUFFER ---
    is_birth_squeeze_4D = is_hard_4D | (a_G < 0.15 * Q_house & (z_idx_3D <= 2)) | m_corner;
    lift_s1 = min(0.85, 0.70 * eta_ref);          % 0.00 in SS0, 0.70 in SS1, 0.82 in SS2
    s1_W1   = (1.00 - lift_s1) .* is_birth_squeeze_4D;
    s1_W2   = 1.00 - s1_W1;                       % Node 2: Secure Parental Asset Buffer (~74.2% -> ~92.3%)
    s1_W_5D = cat(5, s1_W1, s1_W2);

    reg_F12 = zeros(2, 3);
    for s1_i = 1:2
        w1 = s1_W_5D(:, :, :, :, s1_i);
        for s2_i = 1:3
            w2 = s2_W_5D(:, :, :, :, s2_i);
            reg_F12(s1_i, s2_i) = gather(sum(Dist_Fert .* w1 .* w2, 'all')) / tot_p;
        end
    end

    % --- STAGE 3 (J = 5, Ages 12-14 Adolescent Gate) & STAGE 4 (J = 6..7 Adult Skill Launch) ---
    if ~is_reform_panel
        P_unemp = [0.82, 0.16, 0.02; 0.55, 0.37, 0.08; 0.28, 0.54, 0.18];
        P_stabl = [0.35, 0.58, 0.07; 0.12, 0.68, 0.20; 0.05, 0.55, 0.40];
    else
        P_unemp = [0.38, 0.34, 0.28; 0.16, 0.36, 0.48; 0.08, 0.30, 0.62];
        P_stabl = [0.14, 0.46, 0.40; 0.04, 0.38, 0.58; 0.02, 0.26, 0.72];
    end

    % Credit non-corner families (~m_corner) with their baseline child sustenance + 20-Hrs ECE investment
    % so middle-class children at ic_grid=0 on the coarse 4D grid are not hit with an artificial -0.47 log-skill penalty!
    ic_eff_4D  = max(ic_4D, 0.185 .* (~m_corner));
    inv_gap_4D = log(ic_eff_4D + G_ece_eff + 0.02) - log(0.20 + 0.05 + 0.02);
    if strcmpi(Calibration_Anchor, 'Dunedin_22')
        crowd_pen_4D = 0.14 * log(max(1.0, Q_house)) .* is_hard_4D;
        grid_anchor  = +0.265; % Calibrates National SS0 Stunted h1-h2 to the ~22.0% Dunedin Study benchmark!
    else
        crowd_pen_4D = 0.18 * log(max(1.0, Q_house)) .* is_hard_4D;
        grid_anchor  = +0.105; % Metropolitan Squeeze sensitivity (~34-36% Stunted in Auckland)
    end
    base_log_h_4D = rho_hc .* log(h_G) + gamma_ic .* inv_gap_4D - crowd_pen_4D + grid_anchor;
    s3_shifts     = [-0.22, 0.00, montessori_bank];

    p_st_cell = cell(1, 3); p_co_cell = cell(1, 3); p_th_cell = cell(1, 3);
    for s3_i = 1:3
        mean_4D = base_log_h_4D + s3_shifts(s3_i);
        pdf_5D  = exp(-0.5 .* ((log_h_dst5 - mean_4D) ./ sig_hc).^2);
        pdf_5D  = pdf_5D ./ sum(pdf_5D, 5);
        p_st_cell{s3_i} = sum(pdf_5D(:, :, :, :, 1:2), 5);
        p_co_cell{s3_i} = sum(pdf_5D(:, :, :, :, 3:5), 5);
        p_th_cell{s3_i} = sum(pdf_5D(:, :, :, :, 6:7), 5);
    end

    reg_F23 = zeros(3, 3);
    reg_F34 = zeros(3, 3);
    for s2_i = 1:3
        ws2     = s2_W_5D(:, :, :, :, s2_i);
        mass_s2 = Dist_Fert .* ws2;
        for s3_i = 1:3
            p_s3_4D = P_unemp(s2_i, s3_i) .* is_unemp_4D + P_stabl(s2_i, s3_i) .* (~is_unemp_4D);
            mass_s3 = mass_s2 .* p_s3_4D;
            m_share = gather(sum(mass_s3, 'all')) / tot_p;
            reg_F23(s2_i, s3_i) = m_share;

            m_st = gather(sum(mass_s3 .* p_st_cell{s3_i}, 'all')) / tot_p;
            m_co = gather(sum(mass_s3 .* p_co_cell{s3_i}, 'all')) / tot_p;
            m_th = gather(sum(mass_s3 .* p_th_cell{s3_i}, 'all')) / tot_p;

            reg_F34(s3_i, 1) = reg_F34(s3_i, 1) + m_st;
            reg_F34(s3_i, 2) = reg_F34(s3_i, 2) + m_co;
            reg_F34(s3_i, 3) = reg_F34(s3_i, 3) + m_th;
        end
    end

    % --- STAGE 5 (J = 10, Adulthood Fates at Age 30+): EXITS 1-4, RETAINED THRIVING, & EMIGRATED ABROAD ---
    if isfield(Diag_Sim, 'Emig_By_SkillTier')
        emig_t = [mean(Diag_Sim.Emig_By_SkillTier(1:2)), ...
            mean(Diag_Sim.Emig_By_SkillTier(3:5)), ...
            mean(Diag_Sim.Emig_By_SkillTier(6:7))];
    else
        if ~is_reform_panel, emig_t = [0.04, 0.11, 0.22];
        else,                emig_t = [0.02, 0.06, 0.12];
        end
    end

    % Conditional mapping from Adult Skill Launch Tiers [Stunted h1-h2; Core h3-h5; Thriving h6-h7]
    % into the 6 Adulthood Fate Nodes [Exit 1 Care, Exit 2 Hosp, Exit 3 LowInc, Exit 4 Ben/Just, Retained Secure, Emigrated]:
    S4_Shares = sum(reg_F34, 1);
    reg_F45   = zeros(3, 6);
    % Row 1: Stunted h1-h2 (~22% Dunedin segment drives ~74% of Exits 1, 2, 4; State Care = ~2.1% of cohort)
    ret_1 = 1 - emig_t(1);
    reg_F45(1, :) = S4_Shares(1) * [ret_1*0.090, ret_1*0.165, ret_1*0.260, ret_1*0.385, ret_1*0.100, emig_t(1)];
    % Row 2: Core Skill Tier h3-h5 (~54.5% of cohort in SS0)
    ret_2 = 1 - emig_t(2);
    reg_F45(2, :) = S4_Shares(2) * [ret_2*0.004, ret_2*0.024, ret_2*0.080, ret_2*0.065, ret_2*0.827, emig_t(2)];
    % Row 3: Thriving Tier h6-h7 (~23.5% of cohort in SS0 -> ~58% in SS1)
    ret_3 = 1 - emig_t(3);
    reg_F45(3, :) = S4_Shares(3) * [0.000,       ret_3*0.008, 0.000,       0.000,       ret_3*0.992, emig_t(3)];

    Flow_S1_to_S2 = Flow_S1_to_S2 + w_reg * 100 * reg_F12;
    Flow_S2_to_S3 = Flow_S2_to_S3 + w_reg * 100 * reg_F23;
    Flow_S3_to_S4 = Flow_S3_to_S4 + w_reg * 100 * reg_F34;
    Flow_S4_to_S5 = Flow_S4_to_S5 + w_reg * 100 * reg_F45;
end

% Exact 5-stage node population shares (%) across all 17 nodes
S1_Pct = sum(Flow_S1_to_S2, 2);  % 2x1: [1. Material Hardship %, 2. Secure Buffer %]
S2_Pct = sum(Flow_S1_to_S2, 1)'; % 3x1: [3. Unmitigated Corner %, 4. Public ECE %, 5. High Wraparound %]
S3_Pct = sum(Flow_S2_to_S3, 1)'; % 3x1: [6. Unemp Stress %, 7. Standard School %, 8. Montessori / Tuakana %]
S4_Pct = sum(Flow_S3_to_S4, 1)'; % 3x1: [9. Stunted h1-h2 %, 10. Core h3-h5 %, 11. Thriving h6-h7 %]
S5_Pct = sum(Flow_S4_to_S5, 1)'; % 6x1: [12. Exit 1 %, 13. Exit 2 %, 14. Exit 3 %, 15. Exit 4 %, 16. Retained %, 17. Emigrated %]

Ledger = struct();
Ledger.Pop_17Nodes_Pct = [S1_Pct(:); S2_Pct(:); S3_Pct(:); S4_Pct(:); S5_Pct(:)];
Ledger.Flow_S1_to_S2   = Flow_S1_to_S2;
Ledger.Flow_S2_to_S3   = Flow_S2_to_S3;
Ledger.Flow_S3_to_S4   = Flow_S3_to_S4;
Ledger.Flow_S4_to_S5   = Flow_S4_to_S5;

%% BUILD 17-NODE PERCENTAGE-LABELED NODE NAMES
Nodes_S1 = {sprintf('1. Material Hardship & Housing Squeeze (%.1f%%)', S1_Pct(1)), ...
    sprintf('2. Secure Parental Asset Buffer (%.1f%%)',        S1_Pct(2))};

Nodes_S2 = {sprintf('3. Unmitigated Corner ic=0 (%.1f%%)',        S2_Pct(1)), ...
    sprintf('4. Public ECE + Moderate Inv (%.1f%%)',      S2_Pct(2)), ...
    sprintf('5. High Wraparound + Parental Inv (%.1f%%)', S2_Pct(3))};

Nodes_S3 = {sprintf('6. Family Unemp Stress z1 (%.1f%%)',          S3_Pct(1)), ...
    sprintf('7. Standard Schooling (%.1f%%)',              S3_Pct(2)), ...
    sprintf('8. Montessori / Tuakana Mentoring (%.1f%%)',  S3_Pct(3))};

Nodes_S4 = {sprintf('9. Stunted Tier h1-h2 (%.1f%%)',   S4_Pct(1)), ...
    sprintf('10. Core Skill Tier h3-h5 (%.1f%%)',S4_Pct(2)), ...
    sprintf('11. Thriving Tier h6-h7 (%.1f%%)',  S4_Pct(3))};

Nodes_S5 = {sprintf('12. Exit 1: State Care (%.1f%%)',                S5_Pct(1)), ...
    sprintf('13. Exit 2: Avoidable Hospitalisation (%.1f%%)', S5_Pct(2)), ...
    sprintf('14. Exit 3: Lower Lifetime Income (%.1f%%)',     S5_Pct(3)), ...
    sprintf('15. Exit 4: Benefit & Justice Burden (%.1f%%)',  S5_Pct(4)), ...
    sprintf('16. Retained NZ Secure/Thriving Adult (%.1f%%)', S5_Pct(5)), ...
    sprintf('17. Emigrated Abroad (20-35 Brain Drain, %.1f%%)',S5_Pct(6))};

links = {};
row_k = 0;
for i = 1:2
    for j = 1:3
        if Flow_S1_to_S2(i, j) > 1e-4
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S1{i}, Nodes_S2{j}, Flow_S1_to_S2(i, j)};
        end
    end
end
for i = 1:3
    for j = 1:3
        if Flow_S2_to_S3(i, j) > 1e-4
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S2{i}, Nodes_S3{j}, Flow_S2_to_S3(i, j)};
        end
    end
end
for i = 1:3
    for j = 1:3
        if Flow_S3_to_S4(i, j) > 1e-4
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S3{i}, Nodes_S4{j}, Flow_S3_to_S4(i, j)};
        end
    end
end
for i = 1:3
    for j = 1:6
        if Flow_S4_to_S5(i, j) > 1e-4
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
SK.BlockScale      = 0.13;
SK.Sep             = 0.048;
if isprop(SK, 'FontName')
    SK.FontName = 'Helvetica';
end

Master_Colors = [
    0.78, 0.20, 0.16;  % 1. Material Hardship & Housing Squeeze
    0.16, 0.50, 0.56;  % 2. Secure Parental Asset Buffer
    0.76, 0.18, 0.16;  % 3. Unmitigated Corner ic=0
    0.26, 0.52, 0.72;  % 4. Public ECE + Moderate Inv
    0.14, 0.62, 0.50;  % 5. High Wraparound + Parental Inv
    0.82, 0.28, 0.14;  % 6. Family Unemp Stress z1
    0.34, 0.54, 0.68;  % 7. Standard Schooling
    0.10, 0.60, 0.46;  % 8. Montessori / Tuakana Mentoring
    0.74, 0.18, 0.18;  % 9. Stunted Tier h1-h2
    0.28, 0.54, 0.68;  % 10. Core Skill Tier h3-h5
    0.10, 0.58, 0.46;  % 11. Thriving Tier h6-h7
    0.82, 0.22, 0.20;  % 12. Exit 1: State Care
    0.86, 0.44, 0.14;  % 13. Exit 2: Avoidable Hospitalisation
    0.82, 0.62, 0.20;  % 14. Exit 3: Lower Lifetime Income
    0.58, 0.18, 0.22;  % 15. Exit 4: Benefit & Justice Burden
    0.12, 0.60, 0.48;  % 16. Retained NZ Secure/Thriving Adult
    0.46, 0.28, 0.66   % 17. Emigrated Abroad (20-35 Brain Drain)
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

curr_xlim = xlim(ax);
xlim(ax, [curr_xlim(1) - 0.18, curr_xlim(2) + 1.25]);

curr_ylim = ylim(ax);
y_span    = diff(curr_ylim);
ylim(ax, [curr_ylim(1) - 0.24 * y_span, curr_ylim(2) + 0.10 * y_span]);

set(ax, 'FontName', 'Helvetica');
set(findall(ax, 'Type', 'text'), 'FontName', 'Helvetica', 'FontSize', 8.8);

%% DRAW 5-STAGE HORIZONTAL "J" AXIS CENTERED ON EACH BAR
y_axis_line = curr_ylim(1) - 0.09 * y_span;
tick_h      = 0.022 * y_span;

p_all        = findall(ax, 'Type', 'Patch');
x_center_col = zeros(1, 5);
for c_i = 1:5
    c_centers = [];
    for k_p = 1:length(p_all)
        xd = get(p_all(k_p), 'XData');
        if numel(xd) == 4
            xc = sum(xd(:)) / 4;
            if abs(xc - c_i) < 0.45
                c_centers(end+1) = xc; %#ok<AGROW>
            end
        end
    end
    if ~isempty(c_centers)
        x_center_col(c_i) = mean(c_centers);
    else
        x_center_col(c_i) = c_i;
    end
end

plot(ax, [x_center_col(1), x_center_col(5)], [y_axis_line, y_axis_line], '-', ...
    'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.4);

J_Stage_Labels = {
    sprintf('J = 1\n(Birth / Entry, Age 0)');
    sprintf('J = 2 - 3\n(First 2000 Days, Ages 0-5)');
    sprintf('J = 5\n(Adolescent Gate, Ages 12-14)');
    sprintf('J = 6 - 7\n(Adult Skill Launch, Age 20)');
    sprintf('J = 10\n(Adulthood Fates, Age 30+)')
    };

for col_x = 1:5
    x_tick = x_center_col(col_x);
    plot(ax, [x_tick, x_tick], [y_axis_line - tick_h, y_axis_line + tick_h], '-', ...
        'Color', [0.25, 0.25, 0.25], 'LineWidth', 1.5);

    text(ax, x_tick, y_axis_line - 1.6 * tick_h, J_Stage_Labels{col_x}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', 'Helvetica', 'FontSize', 9.0, 'FontWeight', 'bold', ...
        'Color', [0.20, 0.20, 0.20]);
end

if strcmpi(reg_choice, 'National')
    disp_reg = 'National (All Regions)';
elseif strcmpi(reg_choice, 'Urban') && length(reg_list) > 1
    disp_reg = 'Urban (Small + Large + Auckland)';
else
    disp_reg = reg_choice;
end

t_str = sprintf('%s — %s (Mean Q = %.2f) | J=5 Unemp Stress: %.1f%% | Stunted h1-h2: %.1f%% | Thriving: %.1f%%', ...
    Panel_Tag, disp_reg, mean_Q, S3_Pct(1), S4_Pct(1), S4_Pct(3));
t_obj = title(ax, t_str, 'FontName', 'Helvetica', 'FontSize', 11.2, 'FontWeight', 'bold');
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

function [img_Merged, fig_pos] = Stitch_NPanels_Canvas(Panel_Imgs, Merge_Orientation)
N_p = numel(Panel_Imgs);
hs  = cellfun(@(x) size(x, 1), Panel_Imgs);
ws  = cellfun(@(x) size(x, 2), Panel_Imgs);

if strcmpi(Merge_Orientation, 'Vertical')
    W_max    = max(ws);
    pad_L    = 65; pad_R = 95;
    W_canvas = W_max + pad_L + pad_R;

    top_pad  = uint8(255 * ones(90, W_canvas, 3));
    bot_pad  = uint8(255 * ones(90, W_canvas, 3));
    gap_pre  = uint8(255 * ones(80, W_canvas, 3));
    div_line = uint8(220 * ones(4,  W_canvas, 3));
    gap_post = uint8(255 * ones(90, W_canvas, 3));

    blocks = {top_pad};
    for p = 1:N_p
        img_p = uint8(255 * ones(hs(p), W_canvas, 3));
        img_p(:, (pad_L+1):(pad_L+ws(p)), :) = Panel_Imgs{p};
        blocks{end+1} = img_p; %#ok<AGROW>
        if p < N_p
            blocks{end+1} = gap_pre;  %#ok<AGROW>
            blocks{end+1} = div_line; %#ok<AGROW>
            blocks{end+1} = gap_post; %#ok<AGROW>
        end
    end
    blocks{end+1} = bot_pad;
    img_Merged    = vertcat(blocks{:});
    fig_pos       = [80, 20, 1320, min(1150, 560 * N_p)];
else
    H_max    = max(hs);
    pad_T    = 90; pad_B = 90;
    H_canvas = H_max + pad_T + pad_B;
    left_pad = uint8(255 * ones(H_canvas, 65, 3));
    mid_gap  = uint8(255 * ones(H_canvas, 120, 3));
    right_pad= uint8(255 * ones(H_canvas, 95, 3));

    blocks = {left_pad};
    for p = 1:N_p
        img_p = uint8(255 * ones(H_canvas, ws(p), 3));
        img_p((pad_T+1):(pad_T+hs(p)), :, :) = Panel_Imgs{p};
        blocks{end+1} = img_p; %#ok<AGROW>
        if p < N_p
            blocks{end+1} = mid_gap; %#ok<AGROW>
        end
    end
    blocks{end+1} = right_pad;
    img_Merged    = horzcat(blocks{:});
    fig_pos       = [20, 80, min(1920, 920 * N_p), 740];
end
end

function T_Out = Build_NPhase_Summary_Table(Phase_Ledgers, Phase_Codes, vec_field, val_suffix, delta_suffix)
N_p   = numel(Phase_Ledgers);
L_ref = Phase_Ledgers{1};
n_row = numel(L_ref.(vec_field));

if isfield(L_ref, 'Gate_Column') && isfield(L_ref, 'Node_Names')
    Gates = L_ref.Gate_Column;
    Names = L_ref.Node_Names;
else
    Gates = { ...
        'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0'; ...
        'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; ...
        'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14'; ...
        'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20'; ...
        'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30'; ...
        'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30';    'Gate5_J10_AdultFates_Age30'};
    Names = { ...
        '1_Material_Hardship_Housing_Squeeze'; '2_Secure_Parental_Asset_Buffer'; ...
        '3_Unmitigated_Corner_ic0';            '4_Public_ECE_Moderate_Inv';          '5_High_Wraparound_Parental_Inv'; ...
        '6_Family_Unemp_Stress_z1';            '7_Standard_Public_Schooling';        '8_Montessori_Peer_Mentoring'; ...
        '9_Stunted_Tier_h1_h2';                '10_Core_Skill_Tier_h3_h5';           '11_Thriving_Tier_h6_h7'; ...
        '12_Exit1_State_Care';                 '13_Exit2_Avoidable_Hospitalisation'; '14_Exit3_Lower_Lifetime_Income'; ...
        '15_Exit4_Benefit_Justice_Burden';     '16_Retained_NZ_Secure_Thriving';     '17_Emigrated_Abroad_BrainDrain'};
end

T_Out = table(Gates(1:n_row), Names(1:n_row), 'VariableNames', {'Gate', 'Node_Name'});
Mat   = zeros(n_row, N_p);

for p = 1:N_p
    col_vec   = reshape(Phase_Ledgers{p}.(vec_field), n_row, 1);
    Mat(:, p) = col_vec;
    T_Out.([Phase_Codes{p}, val_suffix]) = round(col_vec, 2);
end

% Add incremental phase-to-phase deltas and cumulative delta vs Phase 1 (SS0)
if N_p == 2
    T_Out.(['Reform', delta_suffix]) = round(Mat(:, 2) - Mat(:, 1), 2);
elseif N_p >= 3
    for p = 2:N_p
        d_name = sprintf('Delta_%s_vs_%s%s', Phase_Codes{p}, Phase_Codes{p-1}, delta_suffix);
        T_Out.(d_name) = round(Mat(:, p) - Mat(:, p-1), 2);
    end
    cum_name = sprintf('Cumul_%s_vs_%s%s', Phase_Codes{N_p}, Phase_Codes{1}, delta_suffix);
    T_Out.(cum_name) = round(Mat(:, N_p) - Mat(:, 1), 2);
end
end
