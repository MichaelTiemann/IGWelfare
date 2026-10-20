%% PLOT_CHILDFISCAL_2PANEL_SSANKEY.M
% 6-Gate Pairwise 2-Panel Sankey Diagram (A3 Layout, 100% GPU-Vectorized)
% Units: Cohort-Weighted Annual NZD Thousands ($k/yr per child born in cohort)
%        + Explicit Population Share (% pop) on Gates 1-4 & Explicit Barnardos Exits 1-4:
%   - Gate 1 (J = 1, Birth, Age 0):
%       (1) Means-Tested Birth Support, (2) Universal Birth Benefit, (3) Private Out-of-Pocket Birth Cost
%   - Gate 2 (J = 2..3, First 2000 Days ECE Gate, Ages 0-5):
%       Exposes the ~50/50 split between ECE Corner + Benefit Need vs. High ECE + Parental Time
%   - Gate 3 (J = 5, Adolescent Gate, Ages 12-14):
%       Exposes Unemp Stress + Early Exits 1,2,4 (Care, Hosp, Youth Justice/Benefit) vs. Montessori Mentoring
%   - Gate 4 (J = 6..7, Adult Skill Launch, Age 20):
%       Stunted h1-h2 (carrying Exits 1,2,4; Exit 3 not yet active) vs. Core h3-h5 vs. Thriving h6-h7
%   - Gate 5 (J = 10, Age 30) & Gate 6 (J = 11..16, Career to Retirement):
%       All 4 Barnardos Exits (Exits 1,2,4 Direct Crown Cost + Exit 3 Lower Income/Super Draw) at Bottom (BAD),
%       GST/Cap/Estate Tax + PAYE Tax in Middle (GOOD), Emigrated Tax Loss at Top (BEYOND),
%       with Net-Zero Breakeven Line across Gates 5 & 6.

%% 1. CONFIGURATION SWITCHES
Target_Region      = 'Rural';   % 'Auckland', 'Urban', 'National', 'Large', 'Small', 'Rural'
Calibration_Anchor = 'Dunedin_22'; % 'Dunedin_22' or 'MetroSqueeze_GUiNZ'
Merge_Orientation  = 'Vertical';   % 'Vertical' (Stacked Top/Bottom for A3) or 'Horizontal'
NZD_Base_Scale     = 95.0;         % 1.0 model unit = NZD $95.0k/yr (mean prime household earnings)
Out_PNG_Name       = sprintf('Fig_ChildFiscal_2Panel_%s_%s.png', Target_Region, Calibration_Anchor);

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
    P_SS1.tau_a = getfield_def(P_SS0, 'tau_a', 0.00) + 0.012;
    P_SS1.tau_b = getfield_def(P_SS0, 'tau_b', 0.05) + 0.10;
    Q_mult_Map  = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);
    f_all       = fieldnames(Dist_SS0);
    hh_f        = f_all(strncmp(f_all, 'HH_', 3));
    for r_i = 1:length(hh_f)
        hk  = hh_f{r_i};
        reg = erase(hk, 'HH_');
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

%% 3. RENDER PANEL A & PANEL B ON A3 CANVASES AND MERGE INTO ONE IMAGE
FiscalLedger = struct();

figA = figure('Color', 'w', 'Position', [20, 40, 1850, 820], 'Visible', 'on');
axA  = axes('Parent', figA, 'Position', [0.02, 0.07, 0.95, 0.85]);
FiscalLedger.SS0 = Build_And_Render_Fiscal_Panel(axA, Target_Region, Dist_SS0, Pol_SS0, ...
    P_SS0, Diag_SS0, n_d, n_a, n_z, d_grid, a_grid, z_grid, ...
    'A. Status Quo Baseline (SS0)', ...
    Calibration_Anchor, NZD_Base_Scale, false);
drawnow;
imgA = AutoCrop_White_Border(print(figA, '-RGBImage', '-r300'));
close(figA);

figB = figure('Color', 'w', 'Position', [20, 40, 1850, 820], 'Visible', 'on');
axB  = axes('Parent', figB, 'Position', [0.02, 0.07, 0.95, 0.85]);
FiscalLedger.SS1 = Build_And_Render_Fiscal_Panel(axB, Target_Region, Dist_SS1, Pol_SS1, ...
    P_SS1, Diag_SS1, n_d, n_a, n_z, d_grid, a_grid, z_grid, ...
    'B. High-Opportunity Reform (SS1)', ...
    Calibration_Anchor, NZD_Base_Scale, true);
drawnow;
imgB = AutoCrop_White_Border(print(figB, '-RGBImage', '-r300'));
close(figB);

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

    top_frame_pad    = uint8(255 * ones(90, W_canvas, 3));
    gap_below_PanelA = uint8(255 * ones(80, W_canvas, 3));
    divider_line     = uint8(220 * ones(4,  W_canvas, 3));
    gap_above_PanelB = uint8(255 * ones(90, W_canvas, 3));
    bot_frame_pad    = uint8(255 * ones(90, W_canvas, 3));

    img_Merged = [top_frame_pad; imgA_pad; gap_below_PanelA; divider_line; gap_above_PanelB; imgB_pad; bot_frame_pad];
    fig_pos    = [60, 20, 1380, 1080];
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
    fig_pos    = [20, 80, 1880, 760];
end

imwrite(img_Merged, fullfile(OutputDir, Out_PNG_Name));
fprintf('\nSaved merged 6-gate Fiscal Sankey image to: %s\n', fullfile(OutputDir, Out_PNG_Name));
fprintf('All dollar flows are in Cohort-Weighted Annual NZD $k/yr per child born in cohort.\n');

fig_Merged = figure('Name', ['Merged 6-Gate Fiscal & Private Dollar Flows: ', Target_Region], ...
    'Color', 'w', 'Position', fig_pos);
ax_M = axes('Parent', fig_Merged, 'Position', [0, 0, 1, 1]);
imshow(img_Merged, 'Parent', ax_M, 'Border', 'tight');
axis(ax_M, 'off');


%% ========================================================================
%  LOCAL HELPER: GPU-VECTORIZED 6-GATE FISCAL & PRIVATE LEDGER + SANKEY
%  ========================================================================
function Ledger = Build_And_Render_Fiscal_Panel(ax, reg_choice, Dist_Sim, Pol_Sim, ...
    P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, z_grid, Panel_Tag, ...
    Calibration_Anchor, NZD_Scale, is_reform_panel)

% 1. Inspect available HH_* regions inside Dist_Sim
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
z_vec    = z_grid.(ref_type);

n_l    = n_d.(ref_type)(1);
n_Ih   = n_d.(ref_type)(2);
n_ic   = n_d.(ref_type)(3);
l_vec  = d_grid.(ref_type)(1:n_l);
Ih_vec = d_grid.(ref_type)(n_l+1 : n_l+n_Ih);
ic_vec = d_grid.(ref_type)(n_l+n_Ih+1 : end);

fertile_j = [3, 4];
Jr        = getfield_def(P_Sim, 'Jr',          10);
J_tot     = getfield_def(P_Sim, 'J',           16);
rho_hc    = getfield_def(P_Sim, 'rho_hc_ig',   0.40);
gamma_ic  = getfield_def(P_Sim, 'gamma_ic',    0.35);
G_ece     = getfield_def(P_Sim, 'G_ece',       0.05);
sig_hc    = getfield_def(P_Sim, 'sigma_hc_ig', 0.18);
s_sub     = getfield_def(P_Sim, 's_sub',       0.10);
tau_l     = getfield_def(P_Sim, 'tau_l',       0.22);
tau_c     = getfield_def(P_Sim, 'tau_c',       0.15);
tau_k     = getfield_def(P_Sim, 'tau_k',       0.20);
tau_a     = getfield_def(P_Sim, 'tau_a',       0.005);
tau_b     = getfield_def(P_Sim, 'tau_b',       0.05);
r_ann     = (1 + getfield_def(P_Sim, 'r', 0.20))^(1/5) - 1;
p_super   = getfield_def(P_Sim, 'p_super',     0.18);
c_floor   = getfield_def(P_Sim, 'c_floor',     0.04);

if is_reform_panel
    if G_ece <= 0.06, G_ece = G_ece + 0.14; end
    if tau_a <= 0.006, tau_a = tau_a + 0.010; end
    if tau_b <= 0.06,  tau_b = tau_b + 0.10;  end
    G_ece_eff       = G_ece * 1.15; % Montessori cross-age downward multiplier
    montessori_bank = +0.11;        % Montessori adolescent skill lock-in
else
    G_ece_eff       = G_ece;
    montessori_bank = +0.05;
end

% 6-Gate Accumulators (Cohort-Weighted NZD $k/yr per birth + Exact Population Shares):
%   Gate 1 (J=1 Birth, 3 nodes):
%     [1: Means-Tested Birth Support (Bad); 2: Universal Birth Benefit (Pub); 3: Private Birth Cost (Good)]
%   Gate 2 (J=2..3 First 2000 Days ECE Gate, 3 nodes):
%     [4: ECE Corner + Benefit Need (Bad); 5: Public ECE + Mod Inv; 6: High ECE + Time (Good)]
%   Gate 3 (J=5 Adolescent Gate, Ages 12-14, 3 nodes):
%     [7: Unemp Stress + Exits 1,2,4 (Care/Hosp/Just); 8: Std Schooling; 9: Montessori Mentoring]
%   Gate 4 (J=6..7 Adult Skill Launch, Age 20, 3 nodes):
%     [10: Stunted h1-h2 (Exits 1,2,4 active); 11: Core h3-h5; 12: Thriving h6-h7]
%   Gate 5 (J=10 Age 30 Annual Fiscal Balance, 5 nodes):
%     [13: Exits 1,2,4 Care/Hosp/Corrections/Ben (Bad 1); 14: Exit 3 Lower Income Drag (Bad 2);
%      15: Age 30 GST & Cap Tax (Good 1); 16: Age 30 PAYE Tax (Good 2); 17: Age 30 Emig Loss (Beyond)]
%   Gate 6 (J=11..16 Career to Retirement Fiscal Destiny, 5 nodes):
%     [18: Exits 1,2,4 Ongoing Care/Hosp/Just/Ben (Bad 1); 19: Exit 3 Income Drag & NZ Super Draw (Bad 2);
%      20: Super & Estate Tax Pool (Good 1); 21: Career PAYE Surplus (Good 2); 22: Perm. Abroad Loss (Beyond)]
Flow_S1_to_S2 = zeros(3, 3);
Flow_S2_to_S3 = zeros(3, 3);
Flow_S3_to_S4 = zeros(3, 3);

Pop_S1_Birth  = zeros(1, 3); % [Means-Tested Hardship %, Universal 100%, Private Out-of-Pocket %]
Pop_S2_ECE    = zeros(1, 3); % [Corner ic=0 %, Mod ECE %, High ECE %] — matches Fate Chart!
Pop_S3_Adol   = zeros(1, 3); % [Unemp Stress + Exits 1,2,4 %, Std School %, Montessori %]
Pop_S4_Skill  = zeros(1, 3); % [Stunted h1-h2 %, Core h3-h5 %, Thriving h6-h7 %]

ECE_Step_Dollars  = zeros(1, 3); % Cohort-weighted $/yr at J=2-3 (including early benefit/health need in Corner)
Adol_Step_Dollars = zeros(1, 3); % Cohort-weighted $/yr at J=5   (including Exits 1,2,4 in Unemp Stress node)

Age30_Fiscal     = zeros(3, 5);  % 3 Skill Tiers x 5 Gate-5 Nodes
CareerRet_Fiscal = zeros(3, 5);  % 3 Skill Tiers x 5 Gate-6 Nodes

Q_base_Map = struct('Rural', 1.05, 'Small', 1.40, 'Urban', 1.75, 'Large', 2.05, 'Auckland', 3.10);
Q_mult_Map = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);

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
    w_mkt = getfield_def(P_Sim, 'w', 1.0);
    if isfield(P_Sim, 'w_reg') && isfield(P_Sim.w_reg, hh_type)
        w_mkt = P_Sim.w_reg.(hh_type);
    end
    if is_reform_panel, w_mkt = w_mkt * 1.042; end

    if use_gpu
        Dist_G     = gpuArray(double(Dist_k));
        Pol_G      = gpuArray(double(Pol_k));
        a_G        = gpuArray(reshape(double(a_vec), [n_a1, 1, 1, 1]));
        h_G        = gpuArray(reshape(double(h_vec), [1, n_h, 1, 1]));
        z_G        = gpuArray(reshape(double(z_vec), [1, 1, n_z1, 1]));
        l_G        = gpuArray(double(l_vec(:)));
        Ih_G       = gpuArray(double(Ih_vec(:)));
        ic_G       = gpuArray(double(ic_vec(:)));
        z_idx_3D   = gpuArray(reshape(1:n_z1, [1, 1, n_z1, 1]));
        log_h_dst5 = gpuArray(reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]));
    else
        Dist_G     = double(Dist_k);
        Pol_G      = double(Pol_k);
        a_G        = reshape(double(a_vec), [n_a1, 1, 1, 1]);
        h_G        = reshape(double(h_vec), [1, n_h, 1, 1]);
        z_G        = reshape(double(z_vec), [1, 1, n_z1, 1]);
        l_G        = double(l_vec(:));
        Ih_G       = double(Ih_vec(:));
        ic_G       = double(ic_vec(:));
        z_idx_3D   = reshape(1:n_z1, [1, 1, n_z1, 1]);
        log_h_dst5 = reshape(log(double(h_vec)), [1, 1, 1, 1, n_h]);
    end

    %% PART A (GPU): GATES 1 TO 4 — BIRTH (J=1), ECE (J=2-3), ADOLESCENCE (J=5), AND LAUNCH (J=6-7)
    % Use the exact same Dist_Fert = Dist_G(:, :, :, fertile_j) and Pol_G(3, :, :, :, fertile_j)
    % as Plot_ChildFates_2Panel_SSankey.m so Gate 2 (~50/50 split) and Gate 4 match the Fate Chart!
    Dist_Fert = Dist_G(:, :, :, fertile_j);                        % [n_a1, n_h, n_z1, 2]
    tot_p     = max(1e-12, gather(sum(Dist_Fert, 'all')));

    d_ic_idx  = max(1, min(length(ic_vec), Pol_G(3, :, :, :, fertile_j)));
    ic_4D     = reshape(ic_G(d_ic_idx(:)), size(Dist_Fert));       % [n_a1, n_h, n_z1, 2]

    is_hard_4D  = (a_G < 0.08 * Q_house);                          % [n_a1, 1, 1, 1]
    is_unemp_4D = (z_idx_3D == 1) | (n_z1 >= 5 & (z_idx_3D == 2) & is_hard_4D);
    pwage_4D    = w_mkt .* z_G .* h_G;                             % [1, n_h, n_z1, 1]

    % --- GATE 2 (J = 2..3, Ages 0-5) EXACT POPULATION WEIGHTS (Matches Fate Chart ~50/50 Split!) ---
    m_corner = (ic_4D <= 1e-5);
    m_mod    = (~m_corner) & (ic_4D <= 0.35 * max(ic_vec));
    m_high   = (~m_corner) & (~m_mod);

    if ~is_reform_panel
        s2_W1 = 1.00 .* m_corner;                 % Node 4: ECE Unmitigated Corner + Benefit Need (~48% pop)
        s2_W2 = 1.00 .* m_mod;                    % Node 5: Public ECE + Moderate Inv (~3% pop)
        s2_W3 = 1.00 .* m_high;                   % Node 6: High Wraparound + Parental Inv (~49% pop)
    else
        s2_W1 = 0.22 .* m_corner;                 % Reform lifts 78% of corner families into Public ECE + Care
        s2_W2 = 0.78 .* m_corner + 1.00 .* m_mod;
        s2_W3 = 1.00 .* m_high;
    end
    s2_W_5D = cat(5, s2_W1, s2_W2, s2_W3);        % [n_a1, n_h, n_z1, 2, 3]

    % --- GATE 1 (J = 1, Birth, Age 0): THREE BIRTH COST FLOWS ($k/yr per cohort birth) ---
    %   (1) Means-Tested Public Birth Support (Bottom/Bad): Hardship grant, accommodation supplement,
    %       Sole Parent/Jobseeker birth support, acute neonatal/maternal care for hardship/unemp families
    %   (2) Universal Birth Benefit (Middle/Public): Paid Parental Leave (PPL ~$7.2k), Year-1 BestStart
    %       ($3.8k), free Lead Maternity Carer (LMC) & Well Child Tamariki Ora (~$2.5k) -> ~$13.5k/birth
    %   (3) Private Out-of-Pocket Birth Cost (Top/Good): Parental infant setup, nursery/housing space,
    %       and uncompensated parental leave opportunity cost
    is_mt_birth_4D = is_hard_4D | (z_idx_3D <= 2) | m_corner;
    MT_Birth_4D    = NZD_Scale .* (0.115 .* is_hard_4D + 0.085 .* (z_idx_3D == 1) + 0.065 .* m_corner);
    if is_reform_panel
        % Under Reform SS1: Maternal & First-1000-Days wraparound expands universal & targeted birth support
        Univ_Birth_4D = NZD_Scale .* (0.142 + 0.045 + 0 .* Dist_Fert);
    else
        Univ_Birth_4D = NZD_Scale .* (0.142 + 0 .* Dist_Fert);     % ~$13.5k/yr universal birth package
    end
    Priv_Birth_4D  = NZD_Scale .* (0.045 * Q_house + 0.120 .* pwage_4D .* (0.25 + 0.75 .* (~m_corner)) + 0.55 .* (1 - s_sub) .* ic_4D);

    reg_Pop_S1 = [gather(sum(Dist_Fert .* is_mt_4D_helper(is_mt_birth_4D, Dist_Fert), 'all')) / tot_p, ...
        1.00, ... % 100% of births receive universal PPL + BestStart Yr1 + LMC
        gather(sum(Dist_Fert .* (~m_corner | ~is_hard_4D), 'all')) / tot_p];

    reg_F12    = zeros(3, 3);
    reg_Pop_S2 = zeros(1, 3);
    for s2_i = 1:3
        ws = s2_W_5D(:, :, :, :, s2_i);
        reg_Pop_S2(s2_i) = gather(sum(Dist_Fert .* ws, 'all')) / tot_p;
        reg_F12(1, s2_i) = gather(sum(Dist_Fert .* MT_Birth_4D   .* ws, 'all')) / tot_p;
        reg_F12(2, s2_i) = gather(sum(Dist_Fert .* Univ_Birth_4D .* ws, 'all')) / tot_p;
        reg_F12(3, s2_i) = gather(sum(Dist_Fert .* Priv_Birth_4D .* ws, 'all')) / tot_p;
    end

    % --- GATE 2 (J = 2..3, First 2000 Days ECE Gate) ANNUAL COST FLOWS ($k/yr per cohort child) ---
    %   Node 4 (Corner ic=0): Triggers public hardship transfers + early hospital/OT protection costs!
    %   Node 5 (Public ECE + Mod Inv): Public 20-Hours ECE + Te Korowai Mokopuna wraparound + moderate parent top-up
    %   Node 6 (High ECE + Time): High parental active time (Lee & Seshadri gamma_0 = 0.90) + private ECE + universal subsidy
    ECE_Corner_Need_4D = NZD_Scale .* (0.135 + 0.085 .* is_hard_4D + 0.065 .* is_unemp_4D); % Benefit + early acute health/OT need
    ECE_PubMod_Cost_4D = NZD_Scale .* (G_ece_eff + 0.075 + (1 - s_sub) .* ic_4D + 0.080 .* pwage_4D);
    ECE_High_Cost_4D   = NZD_Scale .* (G_ece_eff + 0.055 + (1 - s_sub) .* ic_4D + 0.145 .* pwage_4D + 0.045 * Q_house);

    reg_ECE_Step = [gather(sum(Dist_Fert .* ECE_Corner_Need_4D .* s2_W1, 'all')) / tot_p, ...
        gather(sum(Dist_Fert .* ECE_PubMod_Cost_4D .* s2_W2, 'all')) / tot_p, ...
        gather(sum(Dist_Fert .* ECE_High_Cost_4D   .* s2_W3, 'all')) / tot_p];

    % --- GATE 3 (J = 5, Ages 12-14 Adolescent Gate) & EMERGENCE OF BARNARDOS EXITS 1, 2, 4 ---
    %   Node 7 (Unemp Stress z1 + Early Exits 1,2,4): Family benefit dependence, Oranga Tamariki care
    %          placement ($145k/case-yr), avoidable hospitalisation, and youth justice contact emerge here!
    %   Node 8 (Standard Schooling): Public secondary schooling (d_2 = $9.5k/yr) + standard family care
    %   Node 9 (Montessori Cross-Age Mentoring): High-agency peer mentoring banking early gains
    if ~is_reform_panel
        P_unemp = [0.82, 0.16, 0.02; 0.55, 0.37, 0.08; 0.28, 0.54, 0.18];
        P_stabl = [0.35, 0.58, 0.07; 0.12, 0.68, 0.20; 0.05, 0.55, 0.40];
    else
        P_unemp = [0.38, 0.34, 0.28; 0.16, 0.36, 0.48; 0.08, 0.30, 0.62];
        P_stabl = [0.14, 0.46, 0.40; 0.04, 0.38, 0.58; 0.02, 0.26, 0.72];
    end

    % Annual cost per adolescent in each J=5 node ($k/yr):
    %   In Node 7 (Stress + Exits 1,2,4): Public school ($9.5k) + Family Benefit ($11.5k) +
    %   Expected Oranga Tamariki State Care (~8% placement risk @ $150k = $12.0k) +
    %   Avoidable Hospitalisation & Youth Justice (~$6.5k) = ~$39.5k/yr per affected adolescent!
    Adol_Cost_Node7_4D = NZD_Scale .* (0.100 + 0.120 + 0.126 + 0.068 + 0.045 .* is_hard_4D);
    Adol_Cost_Node8_4D = NZD_Scale .* (0.100 + (1 - s_sub) .* ic_4D + 0.075 .* pwage_4D + 0.035 * Q_house);
    Adol_Cost_Node9_4D = NZD_Scale .* (0.100 + 0.038 + (1 - s_sub) .* ic_4D + 0.095 .* pwage_4D + 0.040 * Q_house);
    Adol_Node_Costs    = {Adol_Cost_Node7_4D, Adol_Cost_Node8_4D, Adol_Cost_Node9_4D};

    % Gate 3 -> Gate 4 (J = 6..7 Adult Skill Launch) Gaussian Transitions
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

    p_st_cell = cell(1, 3); p_co_cell = cell(1, 3); p_th_cell = cell(1, 3);
    for s3_i = 1:3
        mean_4D = base_log_h_4D + s3_shifts(s3_i);
        pdf_5D  = exp(-0.5 .* ((log_h_dst5 - mean_4D) ./ sig_hc).^2);
        pdf_5D  = pdf_5D ./ sum(pdf_5D, 5);
        p_st_cell{s3_i} = sum(pdf_5D(:, :, :, :, 1:2), 5);
        p_co_cell{s3_i} = sum(pdf_5D(:, :, :, :, 3:5), 5);
        p_th_cell{s3_i} = sum(pdf_5D(:, :, :, :, 6:7), 5);
    end

    % Build Gate 2 -> Gate 3 and Gate 3 -> Gate 4 flows conserving Gate-1 birth dollar scale
    S2_In_Totals  = sum(reg_F12, 1); % Exact Gate-2 block heights from Gate 1
    reg_F23_raw   = zeros(3, 3);
    reg_F34_raw   = zeros(3, 3);
    reg_Pop_S3    = zeros(1, 3);
    reg_Pop_S4    = zeros(1, 3);
    reg_Adol_Step = zeros(1, 3);

    for s2_i = 1:3
        ws2     = s2_W_5D(:, :, :, :, s2_i);
        mass_s2 = Dist_Fert .* ws2;

        for s3_i = 1:3
            p_s3_4D = P_unemp(s2_i, s3_i) .* is_unemp_4D + P_stabl(s2_i, s3_i) .* (~is_unemp_4D);
            mass_s3 = mass_s2 .* p_s3_4D;
            m_share = gather(sum(mass_s3, 'all')) / tot_p;

            reg_Pop_S3(s3_i)    = reg_Pop_S3(s3_i)    + m_share;
            reg_Adol_Step(s3_i) = reg_Adol_Step(s3_i) + gather(sum(mass_s3 .* Adol_Node_Costs{s3_i}, 'all')) / tot_p;

            % Weight ribbon out of s2_i by conditional probability into s3_i
            reg_F23_raw(s2_i, s3_i) = m_share;

            m_st = gather(sum(mass_s3 .* p_st_cell{s3_i}, 'all')) / tot_p;
            m_co = gather(sum(mass_s3 .* p_co_cell{s3_i}, 'all')) / tot_p;
            m_th = gather(sum(mass_s3 .* p_th_cell{s3_i}, 'all')) / tot_p;

            reg_F34_raw(s3_i, 1) = reg_F34_raw(s3_i, 1) + m_st;
            reg_F34_raw(s3_i, 2) = reg_F34_raw(s3_i, 2) + m_co;
            reg_F34_raw(s3_i, 3) = reg_F34_raw(s3_i, 3) + m_th;

            reg_Pop_S4(1) = reg_Pop_S4(1) + m_st;
            reg_Pop_S4(2) = reg_Pop_S4(2) + m_co;
            reg_Pop_S4(3) = reg_Pop_S4(3) + m_th;
        end
    end

    % Scale reg_F23 and reg_F34 to carry forward the Gate-2 dollar flows cleanly
    reg_F23 = zeros(3, 3);
    for s2_i = 1:3
        rs = sum(reg_F23_raw(s2_i, :));
        if rs > 1e-12
            reg_F23(s2_i, :) = S2_In_Totals(s2_i) * (reg_F23_raw(s2_i, :) / rs);
        end
    end
    S3_In_Totals = sum(reg_F23, 1);
    reg_F34 = zeros(3, 3);
    for s3_i = 1:3
        rs = sum(reg_F34_raw(s3_i, :));
        if rs > 1e-12
            reg_F34(s3_i, :) = S3_In_Totals(s3_i) * (reg_F34_raw(s3_i, :) / rs);
        end
    end

    Flow_S1_to_S2     = Flow_S1_to_S2     + w_reg * reg_F12;
    Flow_S2_to_S3     = Flow_S2_to_S3     + w_reg * reg_F23;
    Flow_S3_to_S4     = Flow_S3_to_S4     + w_reg * reg_F34;
    Pop_S1_Birth      = Pop_S1_Birth      + w_reg * reg_Pop_S1;
    Pop_S2_ECE        = Pop_S2_ECE        + w_reg * reg_Pop_S2;
    Pop_S3_Adol       = Pop_S3_Adol       + w_reg * reg_Pop_S3;
    Pop_S4_Skill      = Pop_S4_Skill      + w_reg * (reg_Pop_S4 / max(1e-12, sum(reg_Pop_S4)));
    ECE_Step_Dollars  = ECE_Step_Dollars  + w_reg * reg_ECE_Step;
    Adol_Step_Dollars = Adol_Step_Dollars + w_reg * reg_Adol_Step;

    %% PART B (GPU): GATES 5 & 6 — ALL 4 BARNARDOS EXITS VS. TAX REVENUES BY CATEGORY
    % Extraordinary per-person costs of Exits 1, 2, 4 (Dunedin Study / NZ Treasury CBAx / Barnardos Plan):
    %   - Exit 1 (State Care transition / high-needs residential & supported care): ~$135k-$160k/case-yr
    %   - Exit 2 (Avoidable Hospitalisations & acute mental/addiction health):      ~$28k-$45k/case-yr
    %   - Exit 4 (Corrections prison/community sentence @$150k/yr + Main Benefit):  ~$55k-$95k/case-yr
    %   Combined conditional expected cost of Exits 1, 2 & 4 per Stunted (h1-h2) adult = ~0.38 model units (~$36.1k/yr per stunted adult!)
    %   - Exit 3 (Lower Lifetime Income & Fiscal Tax Shortfall):
    %     Materializes in adulthood (J=10 and J=11..16) as lost earnings & lost tax revenue relative to Core/Thriving!
    d_l_all  = max(1, min(n_l,  Pol_G(1, :, :, :, :)));
    d_Ih_all = max(1, min(n_Ih, Pol_G(2, :, :, :, :)));
    l_4D     = reshape(l_G(d_l_all(:)),   size(Dist_G));
    Ih_4D    = reshape(Ih_G(d_Ih_all(:)), size(Dist_G));

    earn_4D  = w_mkt .* z_G .* h_G .* max(0, l_4D - Ih_4D);
    paye_4D  = tau_l .* earn_4D;
    cap_4D   = (tau_k * r_ann + tau_a) .* a_G + 0 .* Dist_G;
    cons_w4D = max(c_floor, (1 - tau_l) .* earn_4D + (1 - tau_k) * r_ann .* a_G);
    gst_w4D  = (tau_c / (1 + tau_c)) .* cons_w4D;

    beq_r4D  = (tau_b * 0.045) .* a_G + 0 .* Dist_G;
    cons_r4D = max(c_floor, p_super + (1 - tau_k) * r_ann .* a_G) + 0 .* Dist_G;
    gst_r4D  = (tau_c / (1 + tau_c)) .* cons_r4D;

    tier_bins = {1:2, 3:5, 6:7};
    if isfield(Diag_Sim, 'Emig_By_SkillTier')
        emig_t = [mean(Diag_Sim.Emig_By_SkillTier(1:2)), ...
            mean(Diag_Sim.Emig_By_SkillTier(3:5)), ...
            mean(Diag_Sim.Emig_By_SkillTier(6:7))];
    else
        if ~is_reform_panel, emig_t = [0.04, 0.11, 0.22];
        else,                emig_t = [0.02, 0.06, 0.12];
        end
    end

    % Conditional annual per-person Crown outlays & foregone tax base (in model units of $95k/yr):
    %   1. exits_124_*: Direct Crown Remediation Outlays for Exits 1, 2 & 4
    %      (Oranga Tamariki State Care aftercare, Excess Acute Hospitalisations, Corrections/Justice, Main Benefit)
    %   2. pub_infra_*: Per-capita Crown outlay on Roads, Infrastructure, Pure Public Goods (Gp),
    %      Routine Non-Hardship Healthcare & Debt Service (Ferriere et al. Table 28 / Piketty-Saez Table 1: ~34% of Crown budget)
    %   3. exit3_taxloss_*: Exit 3 Fiscal Share (28.8% Crown tax revenue foregone due to lower lifetime income of stunted cohort,
    %      kept strictly in the Beyond/Foregone Tax Base tier per Barnardos Source 9 & 11 integrity rules!)
    exits_124_y     = [0.340, 0.038, 0.006]; % Direct Exits 1,2,4 outlay at Age 30 (~$32.3k/yr per stunted adult)
    pub_infra_y     = [0.072, 0.072, 0.072]; % ~$6.8k/yr per adult for Roads, Infra, Routine Health & Public Goods Gp
    exit3_taxloss_y = [0.068, 0.012, 0.000]; % Crown's 28.8% lost PAYE+GST tax share from Exit 3 lower earnings at Age 30

    exits_124_w     = [0.310, 0.035, 0.005]; % Ongoing Corrections, acute health & benefit burden (Ages 35-64)
    pub_infra_w     = [0.076, 0.076, 0.076]; % ~$7.2k/yr per adult for Roads, Infra, Routine Health & Gp (Ages 35-64)
    exit3_taxloss_w = [0.078, 0.014, 0.000]; % Crown's 28.8% lost PAYE+GST tax share from Exit 3 lower earnings (Ages 35-64)

    exits_124_r     = [0.145, 0.022, 0.004]; % Excess aged acute/residential care in retirement (Ages 65+)
    pub_infra_r     = [0.085, 0.085, 0.085]; % Routine aged health + per-capita public goods/infra in retirement

    for t_idx = 1:3
        ih_set = tier_bins{t_idx};

        % --- GATE 5 (J = 10, Age 30, VFI j = 1..3) ---
        D_y    = Dist_G(:, ih_set, :, 1:3);
        mass_y = max(1e-12, gather(sum(D_y, 'all')));
        P_y    = paye_4D(:, ih_set, :, 1:3);
        GC_y   = gst_w4D(:, ih_set, :, 1:3) + cap_4D(:, ih_set, :, 1:3);
        E_y    = earn_4D(:, ih_set, :, 1:3);
        BN_124 = 0.075 .* (E_y < 0.35) + 0.045 .* (a_G < 0.05 * Q_house) + exits_124_y(t_idx);

        paye_y      = NZD_Scale * gather(sum(D_y .* P_y,    'all')) / mass_y;
        gst_cap_y   = NZD_Scale * gather(sum(D_y .* GC_y,   'all')) / mass_y;
        cost_124_y  = NZD_Scale * gather(sum(D_y .* BN_124, 'all')) / mass_y;
        infra_gp_y  = NZD_Scale * pub_infra_y(t_idx);
        ex3_loss_y  = NZD_Scale * exit3_taxloss_y(t_idx);

        sh_t  = Pop_S4_Skill(t_idx);
        ret_t = 1 - emig_t(t_idx);
        % 5 Columns at Gate 5:
        %   Col 1 (Bad 1 - Social Remediation): Exits 1,2,4 (Care, Acute Hosp, Justice & Benefit)
        %   Col 2 (Bad 2 - General Gov Outlay): Roads, Infra, Baseline Health & Public Goods Gp
        %   Col 3 (Good 1 - Indirect/Cap Tax):  Age 30 GST & Capital/Wealth Tax Paid
        %   Col 4 (Good 2 - Direct Labor Tax):  Age 30 PAYE Income Tax Paid
        %   Col 5 (Beyond - Foregone Tax Base): Exit 3 Lost Tax Revenue (Domestic Stunting) + Emigrated Brain-Drain Tax Loss
        Age30_Fiscal(t_idx, :) = Age30_Fiscal(t_idx, :) + w_reg * sh_t * ...
            [ret_t * cost_124_y, ...
            ret_t * infra_gp_y, ...
            ret_t * gst_cap_y, ...
            ret_t * paye_y, ...
            ret_t * ex3_loss_y + emig_t(t_idx) * (paye_y + gst_cap_y)];

        % --- GATE 6 (J = 11..16, Career to Retirement, VFI j = 4..16) ---
        D_w    = Dist_G(:, ih_set, :, 4:(Jr-1));
        mass_w = max(1e-12, gather(sum(D_w, 'all')));
        P_w    = paye_4D(:, ih_set, :, 4:(Jr-1));
        GC_w   = gst_w4D(:, ih_set, :, 4:(Jr-1)) + cap_4D(:, ih_set, :, 4:(Jr-1));
        E_w    = earn_4D(:, ih_set, :, 4:(Jr-1));
        BN_w   = 0.075 .* (E_w < 0.35) + exits_124_w(t_idx);

        paye_w     = NZD_Scale * gather(sum(D_w .* P_w,  'all')) / mass_w;
        gst_cap_w  = NZD_Scale * gather(sum(D_w .* GC_w, 'all')) / mass_w;
        cost_124_w = NZD_Scale * gather(sum(D_w .* BN_w, 'all')) / mass_w;
        infra_gp_w = NZD_Scale * pub_infra_w(t_idx);
        ex3_loss_w = NZD_Scale * exit3_taxloss_w(t_idx);

        D_r    = Dist_G(:, ih_set, :, Jr:J_tot);
        mass_r = max(1e-12, gather(sum(D_r, 'all')));
        RT_r   = cap_4D(:, ih_set, :, Jr:J_tot) + beq_r4D(:, ih_set, :, Jr:J_tot) + gst_r4D(:, ih_set, :, Jr:J_tot);
        SD_124 = exits_124_r(t_idx) + 0 .* D_r;
        SD_sup = (p_super + pub_infra_r(t_idx)) + 0 .* D_r;

        ret_tax_r  = NZD_Scale * gather(sum(D_r .* RT_r,   'all')) / mass_r;
        cost_124_r = NZD_Scale * gather(sum(D_r .* SD_124, 'all')) / mass_r;
        sup_inf_r  = NZD_Scale * gather(sum(D_r .* SD_sup, 'all')) / mass_r;

        ann_exits_124    = 0.67 * cost_124_w + 0.33 * cost_124_r;
        ann_super_infra  = 0.67 * infra_gp_w + 0.33 * sup_inf_r;
        ann_super_estate = 0.67 * gst_cap_w  + 0.33 * ret_tax_r;
        ann_career_paye  = 0.67 * paye_w;
        ann_foregone_tax = ret_t * (0.67 * ex3_loss_w) + emig_t(t_idx) * (0.67 * (paye_w + gst_cap_w) + 0.33 * ret_tax_r);

        % 5 Columns at Gate 6:
        %   Col 1 (Bad 1): Exits 1,2,4 Ongoing Remediation Burden
        %   Col 2 (Bad 2): Universal NZ Super + Roads, Infra & Baseline Health
        %   Col 3 (Good 1): GST, Capital, Wealth & Estate Tax Pool
        %   Col 4 (Good 2): Career PAYE Income Tax
        %   Col 5 (Beyond): Foregone Tax Base (Exit 3 Stunting Tax Loss + Emigration Abroad)
        CareerRet_Fiscal(t_idx, :) = CareerRet_Fiscal(t_idx, :) + w_reg * sh_t * ...
            [ret_t * ann_exits_124, ...
            ret_t * ann_super_infra, ...
            ret_t * ann_super_estate, ...
            ret_t * ann_career_paye, ...
            ann_foregone_tax];
    end
end

%% HARMONIZE 6-GATE FLOW SCALES & SAVE EXACT DOLLAR LEDGER
S1_Totals = sum(Flow_S1_to_S2, 2);
S4_Totals = sum(Flow_S3_to_S4, 1);

A30_Col_Dollars = sum(Age30_Fiscal, 1);
CR_Col_Dollars  = sum(CareerRet_Fiscal, 1);

Flow_S4_to_S5 = zeros(3, 5);
for t_i = 1:3
    row_sum_a30 = sum(Age30_Fiscal(t_i, :));
    if row_sum_a30 > 1e-8
        Flow_S4_to_S5(t_i, :) = S4_Totals(t_i) * (Age30_Fiscal(t_i, :) / row_sum_a30);
    end
end

S5_Block_Widths = sum(Flow_S4_to_S5, 1);
cr_shares = CR_Col_Dollars / max(1e-8, sum(CR_Col_Dollars));
Flow_S5_to_S6 = zeros(5, 5);
Flow_S5_to_S6(1, :) = S5_Block_Widths(1) * [0.78, 0.14, 0.05, 0.03, 0.00];
Flow_S5_to_S6(2, :) = S5_Block_Widths(2) * [0.10, 0.76, 0.08, 0.06, 0.00];
Flow_S5_to_S6(3, :) = S5_Block_Widths(3) * [0.04, 0.14, 0.56, 0.26, 0.00];
Flow_S5_to_S6(4, :) = S5_Block_Widths(4) * [0.02, 0.12, 0.24, 0.62, 0.00];
Flow_S5_to_S6(5, :) = S5_Block_Widths(5) * [0.00, 0.00, 0.00, 0.00, 1.00];
for c_j = 1:4
    cs = sum(Flow_S5_to_S6(1:4, c_j));
    target_cs = sum(S5_Block_Widths(1:4)) * (cr_shares(c_j) / max(1e-8, sum(cr_shares(1:4))));
    if cs > 1e-8
        Flow_S5_to_S6(1:4, c_j) = Flow_S5_to_S6(1:4, c_j) * (target_cs / cs);
    end
end
for r_i = 1:4
    rs = sum(Flow_S5_to_S6(r_i, 1:4));
    if rs > 1e-8
        Flow_S5_to_S6(r_i, 1:4) = Flow_S5_to_S6(r_i, 1:4) * (S5_Block_Widths(r_i) / rs);
    end
end

Gate4_Step_Dollars = [ ...
    ECE_Step_Dollars(1)*0.3 + Adol_Step_Dollars(1)*0.7, ...
    ECE_Step_Dollars(2)*0.3 + Adol_Step_Dollars(2)*0.7, ...
    ECE_Step_Dollars(3)*0.3 + Adol_Step_Dollars(3)*0.7 ];

Ledger.Gate1_Birth_Costs_kNZD       = S1_Totals;
Ledger.Gate1_Birth_Pop_Pct          = 100 * Pop_S1_Birth;
Ledger.Gate2_ECE_Step_Dollars_kNZD  = ECE_Step_Dollars;
Ledger.Gate2_ECE_Pop_Pct            = 100 * Pop_S2_ECE;
Ledger.Gate3_Adol_Step_Dollars_kNZD = Adol_Step_Dollars;
Ledger.Gate3_Adol_Pop_Pct           = 100 * Pop_S3_Adol;
Ledger.Gate4_Skill_Pop_Pct          = 100 * Pop_S4_Skill;
Ledger.Gate5_Age30_Totals_kNZD      = A30_Col_Dollars;
Ledger.Gate6_CareerRet_Totals_kNZD  = CR_Col_Dollars;

%% BUILD 6-GATE DISAMBIGUATED TWO-LINE NODE LABELS (WITH FULL CROWN BUDGET INTEGRITY)
Nodes_S1 = {sprintf('1. Means-Tested Birth Support\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S1_Birth(1), S1_Totals(1)), ...
    sprintf('2. Universal Birth Benefit\n(100%% pop | $%.1fk/yr)', S1_Totals(2)), ...
    sprintf('3. Private Birth Out-of-Pocket\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S1_Birth(3), S1_Totals(3))};

Nodes_S2 = {sprintf('4. ECE Corner + Benefit Need\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S2_ECE(1), ECE_Step_Dollars(1)), ...
    sprintf('5. Public ECE + Mod. Inv\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S2_ECE(2), ECE_Step_Dollars(2)), ...
    sprintf('6. High Wraparound + Time\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S2_ECE(3), ECE_Step_Dollars(3))};

Nodes_S3 = {sprintf('7. Unemp Stress + Exits 1,2,4\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S3_Adol(1), Adol_Step_Dollars(1)), ...
    sprintf('8. Standard Schooling\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S3_Adol(2), Adol_Step_Dollars(2)), ...
    sprintf('9. Montessori Mentoring\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S3_Adol(3), Adol_Step_Dollars(3))};

Nodes_S4 = {sprintf('10. Stunted h1-h2 [Exits 1,2,4]\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S4_Skill(1), Gate4_Step_Dollars(1)), ...
    sprintf('11. Core Skill Tier h3-h5\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S4_Skill(2), Gate4_Step_Dollars(2)), ...
    sprintf('12. Thriving Tier h6-h7\n(%.1f%% pop | $%.1fk/yr)', 100*Pop_S4_Skill(3), Gate4_Step_Dollars(3))};

% Gate 5 (J = 10 Age 30): Both Social Exits 1,2,4 AND General Public Goods/Infra/Health are in BAD (Outlays),
% while Exit 3 (Lost Tax Share from Lower Income) + Emigration sit in BEYOND (Foregone Tax Base)!
Nodes_S5 = {sprintf('13. Exits 1,2,4: Care/Hosp/Just\n($%.1fk/yr | @$%.0fk/stunted)', A30_Col_Dollars(1), NZD_Scale*exits_124_y(1)), ...
    sprintf('14. Infra, Roads & Base Health\n($%.1fk/yr per adult)', A30_Col_Dollars(2)), ...
    sprintf('15. Age 30 GST & Cap Tax\n($%.1fk/yr)', A30_Col_Dollars(3)), ...
    sprintf('16. Age 30 PAYE Income Tax\n($%.1fk/yr)', A30_Col_Dollars(4)), ...
    sprintf('17. Lost Tax: Exit 3 + Emig\n($%.1fk/yr foregone)', A30_Col_Dollars(5))};

% Gate 6 (J = 11..16 Career to Retirement): Exits 1,2,4 + (NZ Super & Infra/Base Health) vs Taxes Paid
Nodes_S6 = {sprintf('18. Exits 1,2,4: Ongoing Burden\n($%.1fk/yr)', CR_Col_Dollars(1)), ...
    sprintf('19. NZ Super, Infra & Health\n($%.1fk/yr)', CR_Col_Dollars(2)), ...
    sprintf('20. GST, Cap & Estate Tax Pool\n($%.1fk/yr)', CR_Col_Dollars(3)), ...
    sprintf('21. Career PAYE Income Tax\n($%.1fk/yr)', CR_Col_Dollars(4)), ...
    sprintf('22. Lost Tax: Exit 3 + Abroad\n($%.1fk/yr foregone)', CR_Col_Dollars(5))};

links = {};
row_k = 0;
for i = 1:3
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
    for j = 1:5
        if Flow_S4_to_S5(i, j) > 0.01
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S4{i}, Nodes_S5{j}, Flow_S4_to_S5(i, j)};
        end
    end
end
for i = 1:5
    for j = 1:5
        if Flow_S5_to_S6(i, j) > 0.01
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S5{i}, Nodes_S6{j}, Flow_S5_to_S6(i, j)};
        end
    end
end

axes(ax); hold(ax, 'on');
SK = SSankey(links(:, 1), links(:, 2), links(:, 3));

SK.RenderingMethod = 'interp';
SK.Align           = 'center';
SK.LabelLocation   = 'right';
SK.BlockScale      = 0.12;
SK.Sep             = 0.06;
if isprop(SK, 'FontName')
    SK.FontName = 'Helvetica';
end

% 22-Node Palette:
%   Bottom 2 in Gates 5-6 = Crown Outlays [13/18: Exits 1,2,4 (Crimson) + 14/19: Infra/Base Health/Super (Warm Terracotta-Amber)]
%   Middle 2 in Gates 5-6 = Crown Tax Revenues [15/20: GST/Cap/Estate (Blue) + 16/21: PAYE (Teal)]
%   Top 1 in Gates 5-6    = Foregone Crown Tax Base [17/22: Exit 3 Stunting Tax Loss + Emigration (Purple)]
Master_Colors = [
    0.78, 0.22, 0.20;  % 1. Means-Tested Birth Support (Crimson)
    0.28, 0.52, 0.68;  % 2. Universal Birth Benefit (Steel Blue)
    0.16, 0.58, 0.48;  % 3. Private Birth Out-of-Pocket (Emerald Teal)
    0.76, 0.20, 0.18;  % 4. ECE Corner + Benefit Need (Crimson)
    0.32, 0.54, 0.68;  % 5. Public ECE + Mod. Inv (Slate Blue)
    0.14, 0.62, 0.50;  % 6. High Wraparound + Time (Emerald Teal)
    0.80, 0.26, 0.16;  % 7. Unemp Stress + Exits 1,2,4 (Rust Red-Orange)
    0.36, 0.54, 0.66;  % 8. Standard Schooling (Slate Blue)
    0.12, 0.64, 0.48;  % 9. Montessori Mentoring (Vibrant Sea Green)
    0.72, 0.18, 0.18;  % 10. Stunted h1-h2 [Exits 1,2,4] (Brick Red)
    0.32, 0.56, 0.68;  % 11. Core Skill Tier h3-h5 (Slate Blue)
    0.13, 0.55, 0.45;  % 12. Thriving Tier h6-h7 (Deep Sea Green)
    0.78, 0.18, 0.18;  % 13. Gate 5 Exits 1,2,4: Care/Hosp/Just (OUTLAY 1 - Deep Red)
    0.82, 0.48, 0.22;  % 14. Gate 5 Infra, Roads & Base Health (OUTLAY 2 - Terracotta Amber)
    0.24, 0.50, 0.70;  % 15. Gate 5 Age 30 GST & Cap Tax (TAX 1 - Revenue Blue)
    0.15, 0.58, 0.48;  % 16. Gate 5 Age 30 PAYE Income Tax (TAX 2 - Revenue Teal)
    0.52, 0.34, 0.70;  % 17. Gate 5 Lost Tax: Exit 3 + Emig (BEYOND - Purple)
    0.74, 0.16, 0.18;  % 18. Gate 6 Exits 1,2,4: Ongoing Burden (OUTLAY 1 - Deep Red)
    0.80, 0.46, 0.20;  % 19. Gate 6 NZ Super, Infra & Health (OUTLAY 2 - Terracotta Amber)
    0.20, 0.48, 0.68;  % 20. Gate 6 GST, Cap & Estate Tax Pool (TAX 1 - Royal Blue)
    0.12, 0.56, 0.44;  % 21. Gate 6 Career PAYE Income Tax (TAX 2 - Deep Emerald)
    0.46, 0.28, 0.66   % 22. Gate 6 Lost Tax: Exit 3 + Abroad (BEYOND - Deep Purple)
    ];

All_Node_Names = [Nodes_S1, Nodes_S2, Nodes_S3, Nodes_S4, Nodes_S5, Nodes_S6];
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
ylim(ax, [curr_ylim(1) - 0.24 * y_span, curr_ylim(2) + 0.12 * y_span]);

set(ax, 'FontName', 'Helvetica');
set(findall(ax, 'Type', 'text'), 'FontName', 'Helvetica', 'FontSize', 8.5);

%% DRAW 6-GATE HORIZONTAL "J" AXIS CENTERED ON EACH BAR VIA sum(xd(:))/4
y_axis_line = curr_ylim(1) - 0.09 * y_span;
tick_h      = 0.022 * y_span;

p_all        = findall(ax, 'Type', 'Patch');
x_center_col = zeros(1, 6);
for c_i = 1:6
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

plot(ax, [x_center_col(1), x_center_col(6)], [y_axis_line, y_axis_line], '-', ...
    'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.4);

J_Stage_Labels = {
    sprintf('J = 1 (Birth, Age 0)\n(Out-of-Pocket vs Public $)');
    sprintf('J = 2..3 (Ages 0-5)\n(First 2000 Days ECE Gate)');
    sprintf('J = 5 (Ages 12-14)\n(Adol. Gate + Exits 1,2,4)');
    sprintf('J = 6..7 (Age 20)\n(Adult Skill Launch)');
    sprintf('J = 10 (Age 30)\n(Exits 1-4 vs Annual Tax $)');
    sprintf('J = 11..16 (To Ret.)\n(Exits 1-4 & Super vs Tax $)')
    };

for col_x = 1:6
    x_tick = x_center_col(col_x);
    plot(ax, [x_tick, x_tick], [y_axis_line - tick_h, y_axis_line + tick_h], '-', ...
        'Color', [0.25, 0.25, 0.25], 'LineWidth', 1.5);

    text(ax, x_tick, y_axis_line - 1.6 * tick_h, J_Stage_Labels{col_x}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', 'Helvetica', 'FontSize', 8.8, 'FontWeight', 'bold', ...
        'Color', [0.20, 0.20, 0.20]);
end

%% DRAW NET-ZERO BREAKEVEN LINE ON FINAL TWO BARS (COLS 5 & 6: ALL 4 EXITS [BAD] VS. TAXES [GOOD])
% At Gates 5 & 6:
%   BAD  = Sum of Bottom 2 Blocks (Block 1: Exits 1,2,4 Care/Hosp/Just/Ben + Block 2: Exit 3 Income Drag & Super)
%   GOOD = Sum of Middle 2 Blocks (Block 3: GST/Cap/Estate Tax + Block 4: PAYE Income Tax)
Bad_Final2  = [sum(A30_Col_Dollars(1:2)), sum(CR_Col_Dollars(1:2))];
Good_Final2 = [sum(A30_Col_Dollars(3:4)), sum(CR_Col_Dollars(3:4))];
net_fisc_30 = Good_Final2(1) - Bad_Final2(1);
net_fisc_CR = Good_Final2(2) - Bad_Final2(2);

cols_target = [5, 6];
y_zero_f2   = nan(1, 2);
x_cent_f2   = nan(1, 2);
x_left_f2   = nan(1, 2);
x_rght_f2   = nan(1, 2);

for idx_f = 1:2
    c_i = cols_target(idx_f);
    col_boxes = [];
    for k_p = 1:length(p_all)
        xd = get(p_all(k_p), 'XData');
        yd = get(p_all(k_p), 'YData');
        if numel(xd) == 4 && abs((sum(xd(:)) / 4) - c_i) < 0.45
            col_boxes(end+1, :) = [min(xd(:)), max(xd(:)), min(yd(:)), max(yd(:))]; %#ok<AGROW>
        end
    end
    if size(col_boxes, 1) >= 4
        [~, s_ord] = sort(col_boxes(:, 3), 'ascend');
        col_boxes  = col_boxes(s_ord, :);

        x_left_f2(idx_f) = col_boxes(1, 1);
        x_rght_f2(idx_f) = col_boxes(1, 2);
        x_cent_f2(idx_f) = sum(col_boxes(1, 1:2)) / 2;

        % Bottom 2 blocks (rows 1..2) are BAD (Exits 1,2,4 + Exit 3/Super);
        % Middle 2 blocks (rows 3..4) are GOOD (GST/Cap/Estate + PAYE Taxes)
        bad_boxes  = col_boxes(1:2, :);
        good_boxes = col_boxes(3:min(4, size(col_boxes, 1)), :);

        B_val = Bad_Final2(idx_f);
        G_val = Good_Final2(idx_f);
        net_v = G_val - B_val;

        % The exact zero-point is the midpoint of the gap between Top BAD (row 2) and Bottom GOOD (row 3)
        y_top_bad  = bad_boxes(end, 4);
        y_bot_good = good_boxes(1, 3);
        y_origin   = 0.5 * (y_top_bad + y_bot_good);

        if abs(net_v) < 1e-6
            % Exact zero balance: lands precisely between bottom Good and top Bad
            y_zero_f2(idx_f) = y_origin;
        elseif net_v > 0
            % Net Surplus (Good - Bad > 0): rise UPWARD from the bottom of Good by (Good - Bad) / Good
            f_surplus = net_v / max(1e-8, G_val);
            g_heights = good_boxes(:, 4) - good_boxes(:, 3);
            target_h  = f_surplus * sum(g_heights);
            cum_h     = 0;
            for g_k = 1:size(good_boxes, 1)
                if cum_h + g_heights(g_k) >= target_h || g_k == size(good_boxes, 1)
                    y_zero_f2(idx_f) = good_boxes(g_k, 3) + max(0, target_h - cum_h);
                    break;
                end
                cum_h = cum_h + g_heights(g_k);
            end
        else
            % Net Deficit (Good - Bad < 0): descend DOWNWARD from the top of Bad by (Bad - Good) / Bad
            f_deficit = (B_val - G_val) / max(1e-8, B_val);
            b_heights = bad_boxes(:, 4) - bad_boxes(:, 3);
            target_d  = f_deficit * sum(b_heights);
            cum_d     = 0;
            % Traverse Bad blocks from TOP (row 2: Exit 3) downward to BOTTOM (row 1: Exits 1,2,4)
            for b_k = size(bad_boxes, 1):-1:1
                if cum_d + b_heights(b_k) >= target_d || b_k == 1
                    y_zero_f2(idx_f) = bad_boxes(b_k, 4) - max(0, target_d - cum_d);
                    break;
                end
                cum_d = cum_d + b_heights(b_k);
            end
        end

        % Optional subtle gray reference tick at y_origin (the exact Good/Bad interface = $0 line)
        plot(ax, [x_left_f2(idx_f) - 0.02, x_rght_f2(idx_f) + 0.02], ...
            [y_origin, y_origin], ':', 'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.2);

        plot(ax, [x_left_f2(idx_f) - 0.035, x_rght_f2(idx_f) + 0.035], ...
            [y_zero_f2(idx_f), y_zero_f2(idx_f)], '-', ...
            'Color', [0.10, 0.10, 0.10], 'LineWidth', 2.8);
    end
end

if all(~isnan(y_zero_f2))
    plot(ax, x_cent_f2, y_zero_f2, '--o', ...
        'Color', [0.12, 0.12, 0.12], 'LineWidth', 2.0, ...
        'MarkerSize', 6.0, 'MarkerFaceColor', [0.98, 0.82, 0.18], 'MarkerEdgeColor', [0.10, 0.10, 0.10]);

    text(ax, x_rght_f2(2) + 0.04, y_zero_f2(2), ...
        sprintf('Net-Zero Breakeven\n(Good Taxes = Exits 1-4)'), ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
        'FontName', 'Helvetica', 'FontSize', 8.4, 'FontWeight', 'bold', ...
        'Color', [0.12, 0.12, 0.12], 'BackgroundColor', [1.0, 0.98, 0.90], ...
        'EdgeColor', [0.4, 0.4, 0.4], 'Margin', 2);
end

if strcmpi(reg_choice, 'Urban') && length(reg_list) > 1
    disp_reg = 'Urban';
elseif strcmpi(reg_choice, 'National')
    disp_reg = 'National';
else
    disp_reg = reg_choice;
end

n_sign_30 = char('+' * (net_fisc_30 >= 0) + '-' * (net_fisc_30 < 0));
n_sign_CR = char('+' * (net_fisc_CR >= 0) + '-' * (net_fisc_CR < 0));
t_obj = title(ax, sprintf('%s — %s (Units: Cohort-Weighted $k/yr per Birth) | Net Balance: %s$%.1fk/yr (Age 30) | %s$%.1fk/yr (To Ret.)', ...
    Panel_Tag, disp_reg, n_sign_30, abs(net_fisc_30), n_sign_CR, abs(net_fisc_CR)), ...
    'FontName', 'Helvetica', 'FontSize', 11.4, 'FontWeight', 'bold');
set(t_obj, 'Units', 'normalized');
t_pos = get(t_obj, 'Position');
set(t_obj, 'Position', [t_pos(1), 1.03, t_pos(3)]);

axis(ax, 'off');
end

function out_4D = is_mt_4D_helper(mask_in, ref_4D)
out_4D = double(mask_in) + 0 .* ref_4D;
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
