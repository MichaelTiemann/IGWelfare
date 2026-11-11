%% PLOT_CHILDFISCAL_SSANKEY.M
% 6-Gate (28-Node) Pairwise N-Panel Lifecycle Fiscal Sankey Diagram (A3 Layout, 100% GPU-Vectorized)
% Units: Cohort-Weighted Annual NZD Thousands (kNZD/yr per child born in cohort)
%        + Explicit Population Share (% pop) on Gates 1-4 & Explicit 4-Lane Waring / Landlord Split:
%   - Gate 1 (J = 1, Birth, Age 0 — 4 Nodes: 1..4):
%       (1) Acute Hardship Tier 3 Support (DEP-17 9+), (2) Residual AHC Paper & Whanau Buffer,
%       (3) Universal Birth Benefit (PPL + BestStart), (4) Private Birth Out-of-Pocket
%   - Gate 2 (J = 2..3, First 2000 Days ECE Gate, Ages 0-5 — 4 Nodes: 5..8):
%       (5) ECE Corner + Benefit Need, (6) Public ECE Wraparound, (7) High-Intensity Public ECE,
%       (8) Private Parental ECE (Cash + Unpaid Whanau Time)
%   - Gate 3 (J = 5, Adolescent Gate, Ages 12-14 — 5 Nodes: 9..13):
%       (9) HH Unemp & Truancy Remediation, (10) Psychosocial Trauma CAMHS & ACC ISSC (38% Clinical Floor),
%       (11) Public Secondary Schooling (d_2), (12) Montessori / Tuakana Mentoring,
%       (13) Private Adolescent Commitment (Cash + Time)
%   - Gate 4 (J = 6..7, Adult Skill Launch, Age 20 — 3 Nodes: 14..16):
%       (14) Struggling Tier h1-h2, (15) Core Skill Tier h3-h5, (16) Thriving Tier h6-h7
%   - Gate 5 (J = 10, Age 30 — 6 Nodes: 17..22) & Gate 6 (J = 11..16, Career to Ret. — 6 Nodes: 23..28):
%       Exits 1,2,4 + Base Infra/Super Outlays at Bottom (BAD), GST/Cap/Estate + PAYE Tax in Middle (GOOD),
%       Exit 3 Foregone Tax + Emigrated Abroad Lost Tax at Top (BEYOND), with Net-Zero Breakeven & 50/50 Split.

%% 1. CONFIGURATION SWITCHES (N-PHASE COMPATIBLE: 1, 2, 3, OR MORE PANELS)
if ~exist('Target_Regions', 'var') || isempty(Target_Regions)
    Target_Regions     = {'National', 'Auckland', 'Large', 'Small', 'Rural', 'Urban'};
else
    if ischar(Target_Regions) || isstring(Target_Regions), Target_Regions = cellstr(Target_Regions); end
end
% Specify any 1, 2, 3, or N phases: e.g. {'SS0'}, {'SS0','SS1'}, or {'SS0','SS1','SS2'}
if ~exist('Active_Phases', 'var') || isempty(Active_Phases)
    Active_Phases = {'SS0', 'SS1', 'SS2'};
else
    if ischar(Active_Phases) || isstring(Active_Phases), Active_Phases = cellstr(Active_Phases); end
end

Calibration_Anchor = 'Dunedin_22'; % 'Dunedin_22' or 'MetroSqueeze_GUiNZ'
Merge_Orientation  = 'Vertical';   % 'Vertical' (Stacked Top/Bottom for A3) or 'Horizontal'
NZD_Base_Scale     = 95.0;         % 1.0 model unit = $95.0 kNZD/yr (mean prime household earnings)
Interactive_Hover_Mode = true;     % TRUE = keep live vector SSankey figure open for mouse-hover narratives

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

%% 3. RENDER 1..N FISCAL PANELS, STITCH, AND EXPORT 28-NODE TABLE 14 & 2050 PROTOCOL LEDGERS
FiscalLedger = struct();

for r_loop = 1:length(Target_Regions)
    Target_Region = Target_Regions{r_loop};
    Out_PNG_Name  = sprintf('Fig_ChildFiscal_6Gate_%dPanel_%s_%s.png', ...
        N_phases, Target_Region, Calibration_Anchor);

    Panel_Imgs    = cell(1, N_phases);
    Phase_Ledgers = cell(1, N_phases);

    for p = 1:N_phases
        p_code = Phases(p).Code;
        figP   = figure('Name', sprintf('LIVE HOVER — %s (%s)', Phases(p).Label, Target_Region), ...
            'Color', 'w', 'Position', [20, 40, 1850, 820], 'Visible', 'on');
        axP    = axes('Parent', figP, 'Position', [0.02, 0.07, 0.95, 0.85]);

        [L_p, SK_p, links_p] = Build_And_Render_Fiscal_Panel(axP, Target_Region, ...
            Phases(p).Dist, Phases(p).Pol, Phases(p).Params, Phases(p).Diag, ...
            n_d, n_a, n_z, d_grid, a_grid, z_grid, ...
            Phases(p).Label, Calibration_Anchor, NZD_Base_Scale, Phases(p).Intensity);
        drawnow;

        % 1. Capture high-res raster image BEFORE attaching interactive hover UI
        Panel_Imgs{p} = AutoCrop_White_Border(print(figP, '-RGBImage', '-r300'));

        % 2. If Interactive_Hover_Mode is enabled, wire up hover callbacks & keep figure open!
        if Interactive_Hover_Mode && strcmpi(Target_Region, 'National')
            fiscalNarrativeMap = getFiscalRibbonNarratives(p_code);
            attachSankeyHoverNarratives(axP, SK_p, links_p, fiscalNarrativeMap, '%.2f kNZD/yr per cohort birth');
            html_fname = fullfile(OutputDir, sprintf('Interactive_ChildFiscal_%s_%s.html', p_code, Target_Region));
            exportSankeyToHTML(axP, SK_p, links_p, fiscalNarrativeMap, '%.2f kNZD/yr per cohort birth', html_fname);
        else
            close(figP);
        end

        Phase_Ledgers{p}                        = L_p;
        FiscalLedger.(Target_Region).(p_code)   = L_p;
        FiscalLedger.(p_code)                   = L_p;
    end

    %% 3.1 STITCH 1..N PANELS CLEANLY
    [img_Merged, fig_pos] = Stitch_NPanels_Canvas(Panel_Imgs, Merge_Orientation);

    imwrite(img_Merged, fullfile(OutputDir, Out_PNG_Name));
    fprintf('\nSaved %d-panel 6-gate Fiscal Sankey image to: %s\n', N_phases, fullfile(OutputDir, Out_PNG_Name));

    %% 3.2 MULTIPHASE 2050 DEBT-SINKING FUND & PUBLIC REINVESTMENT PROTOCOL SUMMARY
    if N_phases >= 2
        FiscalLedger.(Target_Region).Protocol_2050_Summary = ...
            Build_Multiphase_2050_Protocol_Table(Phase_Ledgers, {Phases.Code}, Target_Region);
        FiscalLedger.Protocol_2050_Summary = FiscalLedger.(Target_Region).Protocol_2050_Summary;
    end

    %% 3.3 EXPORT CUSTOM 6-GATE (28-NODE) FISCAL LEDGER CSV (Table14_FiscalLedger_6Gate_Decomp_<Region>.csv)
    T_FiscalCSV = Build_Custom_Table14_Fiscal_CSV(Phase_Ledgers, {Phases.Code});
    FiscalLedger.(Target_Region).Table14_Decomp = T_FiscalCSV;

    fiscal_csv_fname = fullfile(OutputDir, sprintf('Table14_FiscalLedger_6Gate_Decomp_%s.csv', Target_Region));
    writetable(T_FiscalCSV, fiscal_csv_fname);
    fprintf('  -> Exported %d-Phase 6-Gate (28-Node) Fiscal CSV to: %s\n', N_phases, fiscal_csv_fname);

    fig_Merged = figure('Name', sprintf('%d-Panel 6-Gate Child Fiscal Sankey: %s', N_phases, Target_Region), ...
        'Color', 'w', 'Position', fig_pos);
    ax_M = axes('Parent', fig_Merged, 'Position', [0, 0, 1, 1]);
    imshow(img_Merged, 'Parent', ax_M, 'Border', 'tight');
    axis(ax_M, 'off');
end

%% ========================================================================
%  LOCAL HELPER: GPU-VECTORIZED 6-GATE FISCAL & PRIVATE LEDGER + SANKEY
%  ========================================================================
function [Ledger, SK, links] = Build_And_Render_Fiscal_Panel(ax, reg_choice, Dist_Sim, Pol_Sim, ...
    P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, z_grid, Panel_Tag, ...
    Calibration_Anchor, NZD_Scale, reform_intensity)

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

reg_pop_share = sum(all_w(ismember(avail_r, reg_list)));
if strcmpi(reg_choice, 'National')
    reg_tag = 'NZ';
else
    reg_tag = reg_choice;
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
Jr        = round(getfield_def(P_Sim, 'Jr',          10));
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

% Define boolean flag for legacy if/else blocks below
is_reform_panel = (reform_intensity > 0);
% Clamp incoming scalar/boolean reform_intensity (0.0 = SS0, 1.0 = SS1, >1.0 = SS2+)
eta_ref         = min(1.18, max(0.0, double(reform_intensity)));


if is_reform_panel
    if tau_a <= 0.006, tau_a = tau_a + 0.010; end
    if tau_b <= 0.06,  tau_b = tau_b + 0.10;  end
    montessori_bank = +0.11;        % Montessori / Tuakana adolescent skill lock-in
else
    montessori_bank = +0.05;
end

% 6-Gate (28-Node) Accumulators (Cohort-Weighted kNZD/yr per birth + Exact Population Shares):
%   Gate 1 (J = 1 Birth, 4 nodes -> Nodes 1..4):
%     [1: Acute Hardship Tier 3 Support (DEP-17 9+, Deep Crimson);
%      2: Residual AHC Paper Support & Waring Whanau Buffer (AS Landlord Capture + Unpaid Care, Burnt Rust);
%      3: Universal Birth Benefit (PPL + BestStart + LMC, Public Steel Blue);
%      4: Private Birth Out-of-Pocket (Secure Buffer, Parental Warm Gold)]
%   Gate 2 (J = 2..3 First 2000 Days ECE Gate, 3 public/corner accumulators + Node 8 Private -> Nodes 5..8):
%     [5: ECE Corner + Benefit Need (Bad); 6: Public ECE Wraparound;
%      7: High-Intensity Public ECE;       8: Private Parental ECE (Cash + Whanau Time, Warm Gold)]
%   Gate 3 (J = 5 Adolescent Gate, Ages 12-14, 4 public/crisis accumulators + Node 13 Private -> Nodes 9..13):
%     [9:  HH Unemp & Truancy Remediation (Vote Social Dev / Alt-Ed / Youth Justice);
%      10: Psychosocial Trauma, CAMHS & ACC ISSC (38% Clinical Floor + LOPE Liability, Crimson-Plum);
%      11: Public Secondary Schooling (d_2);
%      12: Montessori / Tuakana-Teina Mentoring (Public Teal);
%      13: Private Adolescent Commitment (Cash + Whanau Time, Warm Gold)]
%   Gate 4 (J = 6..7 Adult Skill Launch, Age 20, 3 nodes -> Nodes 14..16):
%     [14: Struggling Tier h1-h2 (Exits 1,2,4 active); 15: Core Skill Tier h3-h5; 16: Thriving Tier h6-h7]
%   Gate 5 (J = 10 Age 30 Annual Fiscal Balance, 6 nodes -> Nodes 17..22):
%     [17: Exits 1,2,4 Care/Hosp/Just/Ben (Bad 1); 18: Infra, Roads & Base Health (Bad 2);
%      19: Age 30 GST & Cap Tax (Good 1);          20: Age 30 PAYE Income Tax (Good 2);
%      21: Exit 3 Lower-Skill Lost Tax (Foregone); 22: Age 30 Emigrated Abroad Lost Tax (Beyond)]
%   Gate 6 (J = 11..16 Career to Retirement Fiscal Destiny, 6 nodes -> Nodes 23..28):
%     [23: Exits 1,2,4 Ongoing Burden (Bad 1);     24: NZ Super, Infra & Health (Bad 2);
%      25: GST, Cap & Estate Tax Pool (Good 1);    26: Career PAYE Income Tax (Good 2);
%      27: Exit 3 Career Lost Tax (Foregone);      28: Permanent Abroad Lost Tax (Beyond)]
Flow_S1_to_S2 = zeros(4, 3); % 4 Gate-1 Birth Nodes -> 3 Gate-2 Public/Corner States
Flow_S2_to_S3 = zeros(3, 4); % 3 Gate-2 States      -> 4 Gate-3 Public/Crisis States
Flow_S3_to_S4 = zeros(4, 3); % 4 Gate-3 States      -> 3 Gate-4 Launch Skill Tiers
Pop_S1_Birth  = zeros(1, 4); % [1: Severe DEP-17 %, 2: Residual AHC Squeeze %, 3: Universal 100%, 4: Secure Buffer %]
Pop_S2_ECE    = zeros(1, 3); % [5: Corner ic=0 %, 6: Mod ECE %, 7: High ECE %]
Pop_S3_Adol   = zeros(1, 4); % [9: HH Unemp Rem %, 10: Psychosocial CAMHS/ACC %, 11: Std School %, 12: Tuakana %]
Pop_S4_Skill  = zeros(1, 3); % [14: Struggling h1-h2 %, 15: Core h3-h5 %, 16: Thriving h6-h7 %]

ECE_Step_Dollars  = zeros(1, 3); % Cohort-weighted kNZD/yr at J=2-3 (Public/Remediation nodes 5, 6, 7)
Adol_Step_Dollars = zeros(1, 4); % Cohort-weighted kNZD/yr at J=5   (Public/Remediation nodes 9, 10, 11, 12)
Whanau_Care_G1_G2 = zeros(1, 2); % [Node 2 Waring Unpaid Whanau Care kNZD/yr, Node 2 AS Landlord Capture kNZD/yr]

% Solution 1: Gate 5 = 5 Human Adult Career Strata (Nodes 17..21); Gate 6 = 8 Fiscal Accounts (Nodes 22..29)
%   Gate 5 Rows (1..5): [17: Chronic Adversity, 18: Core Workforce, 19: z_l Rent-Seekers, 20: z_h Builders, 21: Emigrated Abroad]
%   Gate 6 Cols (1..8): [22: Exit 1 Care, 23: Exit 2 Hosp, 24: Exit 4 Ben/Just, 25: Infra/Super,
%                        26: GST/Cap/Estate, 27: PAYE Tax, 28: Exit 3 Lost Tax, 29: Abroad Lost Tax]
Pop_S5_Career    = zeros(1, 5);
Flow_S4_to_S5_P  = zeros(3, 5); % 3 Launch Skill Tiers -> 5 Adult Career & Enterprise Strata (Population shares)
Adult_Fiscal_5x8 = zeros(5, 8); % 5 Adult Career Strata -> 8 Annualized Adult Fiscal Accounts (Exact kNZD/yr)

Q_base_Map   = struct('Rural', 1.05, 'Small', 1.40, 'Urban', 1.75, 'Large', 2.05, 'Auckland', 3.10);
Q_mult_Map   = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);
K_whanau_Map = struct('Rural', 0.42, 'Small', 0.38, 'Urban', 0.34, 'Large', 0.32, 'Auckland', 0.28);

% Precompute [n_a1 x 1] cell spans, threshold row vector tau_cuts [1 x 4], and [n_h x 3] Tier_Map:
a_dbl    = double(a_vec(:));
da_span  = [max(1e-6, a_dbl(2) - a_dbl(1)); diff(a_dbl)];
a_prev   = a_dbl - da_span;
tau_cuts = [0.025, 0.050, 0.080, 0.160]; % [1: Extreme, 2: Severe DEP-17, 3: Hardship, 4: AHC-50]
Tier_Map = double([ismember((1:n_h)', 1:2), ismember((1:n_h)', 3:5), ismember((1:n_h)', 6:7)]); % [7 x 3]

if ~is_reform_panel
    P_unemp   = [0.82, 0.16, 0.02; 0.55, 0.37, 0.08; 0.28, 0.54, 0.18];
    P_stabl   = [0.35, 0.58, 0.07; 0.12, 0.68, 0.20; 0.05, 0.55, 0.40];
    psy_share = 0.346;
else
    P_unemp   = [0.38, 0.34, 0.28; 0.16, 0.36, 0.48; 0.08, 0.30, 0.62];
    P_stabl   = [0.14, 0.46, 0.40; 0.04, 0.38, 0.58; 0.02, 0.26, 0.72];
    psy_share = 0.560;
end
Split_3to4 = [1.0 - psy_share, psy_share, 0, 0; ...
    0,               0,         1, 0; ...
    0,               0,         0, 1];
lift_s1    = min([0.88, 0.82], [0.735, 0.638] * eta_ref);
lift_s2    = min(0.92, 0.78 * eta_ref);
s3_shifts  = reshape([-0.22, 0.00, montessori_bank], [1, 1, 1, 1, 1, 3]);

use_gpu = (gpuDeviceCount > 0);

for r_i = 1:length(reg_list)
    reg     = reg_list{r_i};
    w_reg   = pop_weights(r_i);
    hh_type = ['HH_', reg];
    Dist_k  = Dist_Sim.(hh_type);
    Pol_k   = Pol_Sim.(hh_type);

    Q_house = P_Sim.Q_reg.(hh_type);
    Q_base  = getfield_def(Q_base_Map, reg, Q_house);
    if is_reform_panel && isfield(Q_base_Map, reg) && abs(Q_house - Q_base) < 1e-3
        Q_house = Q_house * Q_mult_Map.(reg);
    end

    if isfield(P_Sim, 'K_whanau') && isfield(P_Sim.K_whanau, hh_type)
        K_whanau_k = P_Sim.K_whanau.(hh_type);
    else
        K_whanau_k = getfield_def(K_whanau_Map, reg, 0.34) * ((Q_base / max(0.5, Q_house)) ^ 0.35);
    end

    G_ece_base = getfield_def(P_Sim, 'G_ece', 0.05);
    if isstruct(G_ece_base) && isfield(G_ece_base, hh_type)
        G_ece_k = G_ece_base.(hh_type);
    elseif isnumeric(G_ece_base) && numel(G_ece_base) >= length(reg_list) && ~isscalar(G_ece_base)
        G_ece_k = G_ece_base(r_i);
    elseif isfield(P_Sim, 'G_ece_reg') && isnumeric(P_Sim.G_ece_reg) && numel(P_Sim.G_ece_reg) >= length(reg_list)
        G_ece_k = P_Sim.G_ece_reg(r_i);
    else
        G_ece_k = double(G_ece_base(1));
        if is_reform_panel && G_ece_k <= 0.06
            G_ece_k = G_ece_k + 0.14;
        end
    end
    zeta_kaiako = getfield_def(P_Sim, 'zeta_kaiako', 0.25);
    kaiako_defl = (Q_base / max(0.5, Q_house)) ^ zeta_kaiako;
    if is_reform_panel
        G_ece_eff_k = G_ece_k * 1.15 * kaiako_defl;
    else
        G_ece_eff_k = G_ece_k * kaiako_defl;
    end

    w_mkt = getfield_def(P_Sim, 'w', 1.0);
    if isfield(P_Sim, 'w_reg') && isfield(P_Sim.w_reg, hh_type)
        w_mkt = P_Sim.w_reg.(hh_type);
    end
    if is_reform_panel, w_mkt = w_mkt * 1.042; end

    W_cell = min(1.0, max(0.0, (Q_house .* tau_cuts - a_prev) ./ da_span));

    % Properly collapse 5D [a, h, theta_c, z, j] to 4D [a, h, z, j] for both Part A and Part B:
    Dist_raw = double(gather(Dist_k));
    Pol_raw  = double(gather(Pol_k));
    J_tot_k  = size(Dist_raw, ndims(Dist_raw));
    if numel(n_a.(ref_type)) == 3 && numel(Dist_raw) == n_a1 * n_h * n_a.(ref_type)(3) * n_z1 * J_tot_k
        n_th      = n_a.(ref_type)(3);
        Dist_5D   = reshape(Dist_raw, [n_a1, n_h, n_th, n_z1, J_tot_k]);
        Pol_5D    = reshape(Pol_raw,  [size(Pol_raw, 1), n_a1, n_h, n_th, n_z1, J_tot_k]);
        Dist_4D   = reshape(sum(Dist_5D, 3), [n_a1, n_h, n_z1, J_tot_k]);
        mid_th    = ceil(n_th / 2);
        Pol_4D    = reshape(Pol_5D(:, :, :, mid_th, :, :), [size(Pol_5D, 1), n_a1, n_h, n_z1, J_tot_k]);
        w_th      = Dist_5D ./ max(1e-12, sum(Dist_5D, 3));
        ic_idx5   = max(1, min(length(ic_vec), round(squeeze(Pol_5D(3, :, :, :, :, :)))));
        ic_val5   = reshape(ic_vec(ic_idx5(:)), size(Dist_5D));
        ic_4D_all = reshape(sum(w_th .* ic_val5, 3), [n_a1, n_h, n_z1, J_tot_k]);
        ic_Fert_cpu = ic_4D_all(:, :, :, fertile_j);
    else
        Dist_4D     = reshape(Dist_raw, [n_a1, n_h, n_z1, J_tot_k]);
        Pol_4D      = reshape(Pol_raw,  [size(Pol_raw, 1), n_a1, n_h, n_z1, J_tot_k]);
        d_ic_idx    = max(1, min(length(ic_vec), round(Pol_4D(3, :, :, :, fertile_j))));
        ic_Fert_cpu = reshape(ic_vec(d_ic_idx(:)), [n_a1, n_h, n_z1, numel(fertile_j)]);
    end

    Dist_G   = Dist_4D;
    Pol_G    = Pol_4D;
    ic_4D    = ic_Fert_cpu;
    a_G      = reshape(a_dbl,               [n_a1, 1, 1, 1]);
    h_G      = reshape(double(h_vec),       [1, n_h, 1, 1]);
    z_G      = reshape(double(z_vec),       [1, 1, n_z1, 1]);
    l_G      = double(l_vec(:));
    Ih_G     = double(Ih_vec(:));
    ic_G     = double(ic_vec(:));
    z_idx_3D = reshape(1:n_z1,              [1, 1, n_z1, 1]);
    log_h_5D = reshape(log(double(h_vec)),  [1, 1, 1, 1, n_h]);
    W_G      = reshape(W_cell,              [n_a1, 1, 1, 1, 4]);
    Tier_G   = Tier_Map;

    if use_gpu
        Dist_G   = gpuArray(Dist_G);   Pol_G    = gpuArray(Pol_G);
        ic_4D    = gpuArray(ic_4D);    a_G      = gpuArray(a_G);
        h_G      = gpuArray(h_G);      z_G      = gpuArray(z_G);
        l_G      = gpuArray(l_G);      Ih_G     = gpuArray(Ih_G);
        ic_G     = gpuArray(ic_G);     z_idx_3D = gpuArray(z_idx_3D);
        log_h_5D = gpuArray(log_h_5D); W_G      = gpuArray(W_G);
        Tier_G   = gpuArray(Tier_G);
    end

    %% PART A (GPU): GATES 1 TO 4 — SYNCHRONIZED WITH 18-NODE PLOT_CHILDFATES_SSANKEY.M
    Dist_Fert   = Dist_G(:, :, :, fertile_j);
    N_st        = numel(Dist_Fert);
    p_flat      = Dist_Fert(:) / max(1e-12, sum(Dist_Fert, 'all'));
    pwage_4D    = w_mkt .* z_G .* h_G + 0 .* ic_4D;
    is_hard_4D  = W_G(:, :, :, :, 3);
    is_unemp_4D = (z_idx_3D <= 2) | ((z_idx_3D == 3) & (is_hard_4D > 0.25));
    m_cash_low  = double(ic_4D <= 0.025) .* max(is_hard_4D, double(z_idx_3D <= 3));

    w_sev_4D = max(is_hard_4D, max(W_G(:, :, :, :, 4) .* double(z_idx_3D <= 2), ...
        double(ic_4D <= 1e-5) .* max(double(z_idx_3D <= 2), 0.75 .* double(h_G <= 0.65) .* double(z_idx_3D <= 4))));
    w_tot_4D = max(w_sev_4D, max(W_G(:, :, :, :, 4) .* double(z_idx_3D <= 4), ...
        max(m_cash_low, 0.65 .* double(ic_4D <= 0.025) .* double(h_G <= 0.85))));
    w_ahc_4D = max(0.0, w_tot_4D - w_sev_4D);

    s1_W1_sev = (1.0 - lift_s1(1)) .* w_sev_4D;
    s1_W2_ahc = (1.0 - lift_s1(2)) .* w_ahc_4D;
    S1_Pop_W  = reshape(cat(5, s1_W1_sev, s1_W2_ahc, ones(size(ic_4D)), max(0.0, 1.0 - s1_W1_sev - s1_W2_ahc)), N_st, 4);

    whanau_rescue_k = min(0.45, 0.35 * K_whanau_k * ((Q_base / max(0.5, Q_house)) ^ 0.25));
    m_corner = min(1.0, max(0.0, w_sev_4D + (1.0 - whanau_rescue_k) .* w_ahc_4D));
    m_mod    = max(0.0, (1.0 - m_corner) .* double(ic_4D <= 0.35 * max(ic_vec)));
    S2_W     = reshape(cat(5, (1.0 - lift_s2) .* m_corner, lift_s2 .* m_corner + m_mod, max(0.0, 1.0 - m_corner - m_mod)), N_st, 3);

    univ_rate = 0.142 + 0.045 * eta_ref * double(is_reform_panel);
    G1_Cost_M = NZD_Scale .* reshape(cat(5, ...
        (0.195 + 0.045 .* double(z_idx_3D <= 2)) .* s1_W1_sev, ...
        (0.095 + 0.028 * max(0, Q_house - 1.0))  .* s1_W2_ahc, ...
        univ_rate + 0 .* ic_4D, ...
        0.045 * Q_house + 0.120 .* pwage_4D .* (0.25 + 0.75 .* (1.0 - m_corner)) + 0.55 .* (1 - s_sub) .* ic_4D), N_st, 4);

    waring_whanau_kNZD = NZD_Scale * gather(p_flat' * reshape(s1_W2_ahc .* (0.085 * K_whanau_k .* pwage_4D), N_st, 1));
    as_landlord_kNZD   = gather(p_flat' * G1_Cost_M(:, 2));
    Whanau_Care_G1_G2  = Whanau_Care_G1_G2 + w_reg * [waring_whanau_kNZD, as_landlord_kNZD];

    reg_Pop_S1 = gather(p_flat' * S1_Pop_W);
    reg_Pop_S2 = gather(p_flat' * S2_W);
    reg_F12    = gather(G1_Cost_M' * (p_flat .* S2_W));

    G2_Cost_M = NZD_Scale .* reshape(cat(5, ...
        0.135 + 0.085 .* is_hard_4D + 0.065 .* double(is_unemp_4D) + 0 .* ic_4D, ...
        G_ece_eff_k + 0.045 + s_sub .* ic_4D, ...
        G_ece_eff_k + 0.065 + s_sub .* ic_4D), N_st, 3);
    reg_ECE_Step = gather(sum((p_flat .* S2_W) .* G2_Cost_M, 1));

    ic_eff_4D  = (1.0 - m_corner) .* max(ic_4D, 0.185) + m_corner .* (lift_s2 * 0.145);
    inv_gap_4D = log(ic_eff_4D + G_ece_eff_k + 0.02) - log(0.27);
    if strcmpi(Calibration_Anchor, 'Dunedin_22')
        base_log_h = rho_hc .* log(h_G) + gamma_ic .* inv_gap_4D - 0.14 * log(max(1.0, Q_house)) .* m_corner - 0.035;
    else
        base_log_h = rho_hc .* log(h_G) + gamma_ic .* inv_gap_4D - 0.18 * log(max(1.0, Q_house)) .* m_corner - 0.115;
    end

    pdf_6D    = exp(-0.5 .* ((log_h_5D - (base_log_h + s3_shifts)) ./ sig_hc).^2);
    pdf_6D    = pdf_6D ./ sum(pdf_6D, 5);
    P_Tier_3D = reshape(reshape(permute(pdf_6D, [1,2,3,4,6,5]), N_st * 3, n_h) * Tier_G, [N_st, 3, 3]);

    u_flat      = reshape(double(is_unemp_4D) + 0 .* ic_4D, N_st, 1);
    M_s2_u      = (p_flat .* u_flat)       .* S2_W;
    M_s2_s      = (p_flat .* (1 - u_flat)) .* S2_W;
    reg_F23_3x3 = gather(sum(M_s2_u, 1)' .* P_unemp + sum(M_s2_s, 1)' .* P_stabl);
    M_s3        = M_s2_u * P_unemp + M_s2_s * P_stabl;
    reg_F34_3x3 = gather(squeeze(sum(M_s3 .* P_Tier_3D, 1)));

    reg_F23_raw = reg_F23_3x3 * Split_3to4;
    reg_F34_raw = Split_3to4' * reg_F34_3x3;
    reg_Pop_S3  = sum(reg_F23_raw, 1);
    reg_Pop_S4  = sum(reg_F34_raw, 1);
    reg_Pop_S4  = reg_Pop_S4 / max(1e-12, sum(reg_Pop_S4));

    tot_stress_flat = NZD_Scale .* reshape(0.414 + 0.045 .* is_hard_4D + 0 .* ic_4D, N_st, 1);
    G3_Cost_M = [tot_stress_flat * [1.0 - psy_share, psy_share], ...
        NZD_Scale .* reshape(0.105 + s_sub .* ic_4D, N_st, 1), ...
        NZD_Scale .* reshape(0.143 + s_sub .* ic_4D, N_st, 1)];
    reg_Adol_Step = gather(sum((M_s3 * Split_3to4) .* G3_Cost_M, 1));

    Flow_S1_to_S2     = Flow_S1_to_S2     + w_reg * reg_F12;
    Flow_S2_to_S3     = Flow_S2_to_S3     + w_reg * reg_F23_raw;
    Flow_S3_to_S4     = Flow_S3_to_S4     + w_reg * reg_F34_raw;
    Pop_S1_Birth      = Pop_S1_Birth      + w_reg * reg_Pop_S1;
    Pop_S2_ECE        = Pop_S2_ECE        + w_reg * reg_Pop_S2;
    Pop_S3_Adol       = Pop_S3_Adol       + w_reg * reg_Pop_S3;
    Pop_S4_Skill      = Pop_S4_Skill      + w_reg * reg_Pop_S4;
    ECE_Step_Dollars  = ECE_Step_Dollars  + w_reg * reg_ECE_Step;
    Adol_Step_Dollars = Adol_Step_Dollars + w_reg * reg_Adol_Step;

    %% PART B (GPU): SOLUTION 1 — GATE 5 HUMAN CAREER & ENTERPRISE STRATA (5 NODES) -> GATE 6 FISCAL LEDGER (8 NODES)
    % 1. Map Gate 4 Launch Skill Tiers (1: Struggling h1-h2, 2: Core h3-h5, 3: Thriving h6-h7)
    %    into Gate 5 Adult Career & Enterprise Strata (Nodes 17..21):
    %      Col 1 (Node 17): Chronic Adversity & Benefit/NEET Trap
    %      Col 2 (Node 18): Domestic Core Workforce & Skilled Trades
    %      Col 3 (Node 19): Passive Land/Rent Speculation [z_l Skew]
    %      Col 4 (Node 20): Productive Enterprise Builders [z_h Innovators]
    %      Col 5 (Node 21): Emigrated Abroad [Trans-Tasman Brain Drain]
    if isfield(Diag_Sim, 'Emig_By_SkillTier')
        emig_t = [mean(Diag_Sim.Emig_By_SkillTier(1:2)); ...
            mean(Diag_Sim.Emig_By_SkillTier(3:5)); ...
            mean(Diag_Sim.Emig_By_SkillTier(6:7))];
    elseif ~is_reform_panel
        emig_t = [0.04; 0.11; 0.22];
    else
        emig_t = [0.02; 0.06; 0.12];
    end
    ret_t = 1.0 - emig_t;

    % Guvenen / Murphy-Shleifer-Vishny Occupational Allocation (z_l Rent-Seekers vs z_h Builders):
    if reform_intensity <= 0
        % SS0 Status Quo: High Q_house & untaxed land wealth pull 68% of retained Thriving talent into z_l rent-seeking
        P_Ret_3x4 = [0.78, 0.22, 0.00, 0.00; ... % Retained Struggling -> 78% Chronic Adversity, 22% Core Workforce
            0.09, 0.73, 0.12, 0.06; ... % Retained Core       -> 9% Adversity, 73% Core, 12% z_l, 6% z_h
            0.01, 0.09, 0.61, 0.29];    % Retained Thriving   -> 1% Adversity, 9% Core, 61% z_l Rent, 29% z_h Builder
    elseif reform_intensity <= 1.0
        % SS1 Reform Pivot: 1.5% Land/Wealth Levy + Youth Grant E flips occupational cutoff A* from z_l to z_h Builders
        P_Ret_3x4 = [0.68, 0.32, 0.00, 0.00; ...
            0.04, 0.76, 0.04, 0.16; ...
            0.00, 0.08, 0.14, 0.78];
    else
        % SS2 2050 Harvest: Sovereign Debt Retired + 18.85% PAYE locks talent into positive-sum z_h Builders
        P_Ret_3x4 = [0.62, 0.38, 0.00, 0.00; ...
            0.03, 0.75, 0.02, 0.20; ...
            0.00, 0.06, 0.06, 0.88];
    end
    P_G4_to_G5   = [ret_t .* P_Ret_3x4, emig_t]; % [3 x 5] row-stochastic transition from Launch Tiers to Career Strata
    reg_F45_Pop  = reg_Pop_S4(:) .* P_G4_to_G5;  % [3 x 5] cohort population share matrix
    reg_Pop_S5   = sum(reg_F45_Pop, 1);          % [1 x 5] population shares in Gate 5 Career Strata

    Flow_S4_to_S5_P = Flow_S4_to_S5_P + w_reg * reg_F45_Pop;
    Pop_S5_Career   = Pop_S5_Career   + w_reg * reg_Pop_S5;

    % 2. Compute Annualized Adult Fiscal Flows (J = 6..16) on GPU by Skill Tier, then project onto the 5 Career Strata:
    d_l_all  = max(1, min(n_l,  round(Pol_G(1, :, :, :, :))));
    d_Ih_all = max(1, min(n_Ih, round(Pol_G(2, :, :, :, :))));
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

    tier_bins   = {1:2, 3:5, 6:7};
    ex124_split = [0.141, 0.258, 0.601]; % [Exit 1 State Care 14.1%, Exit 2 Hosp/CAMHS 25.8%, Exit 4 Ben/LOPE/Just 60.1%]

    % Conditional per-person annual fiscal rates across the 3 launch skill tiers:
    paye_tier  = zeros(3, 1);
    gst_tier   = zeros(3, 1);
    ex124_tier = zeros(3, 1);
    for t_idx = 1:3
        ih_set = tier_bins{t_idx};
        D_w    = Dist_G(:, ih_set, :, 1:(Jr-1));
        mass_w = max(1e-12, gather(sum(D_w, 'all')));
        P_w    = paye_4D(:, ih_set, :, 1:(Jr-1));
        GC_w   = gst_w4D(:, ih_set, :, 1:(Jr-1)) + cap_4D(:, ih_set, :, 1:(Jr-1));
        E_w    = earn_4D(:, ih_set, :, 1:(Jr-1));
        BN_w   = 0.075 .* (E_w < 0.35) + 0.045 .* W_G(:, :, :, :, 2);

        D_r    = Dist_G(:, ih_set, :, Jr:J_tot);
        mass_r = max(1e-12, gather(sum(D_r, 'all')));
        RT_r   = cap_4D(:, ih_set, :, Jr:J_tot) + beq_r4D(:, ih_set, :, Jr:J_tot) + gst_r4D(:, ih_set, :, Jr:J_tot);

        paye_w_val = NZD_Scale * gather(sum(D_w .* P_w,  'all')) / mass_w;
        gst_w_val  = NZD_Scale * gather(sum(D_w .* GC_w, 'all')) / mass_w;
        bneed_val  = NZD_Scale * gather(sum(D_w .* BN_w, 'all')) / mass_w;
        ret_tx_val = NZD_Scale * gather(sum(D_r .* RT_r, 'all')) / mass_r;

        paye_tier(t_idx)  = 0.72 * paye_w_val;
        gst_tier(t_idx)   = 0.72 * gst_w_val + 0.28 * ret_tx_val;
        ex124_tier(t_idx) = bneed_val;
    end

    % Build 5x8 Adult Fiscal Incidence Matrix (Rows = 5 Gate-5 Career Strata; Cols = 8 Gate-6 Fiscal Accounts):
    %   Gate 6 Columns ordered strictly Bottom-to-Top:
    %     Col 1 (Node 22): Exit 1: State Care Legacy          [Bottom 1]
    %     Col 2 (Node 23): Exit 2: Avoidable Hosp & CAMHS     [Bottom 2]
    %     Col 3 (Node 24): Exit 3: Lower-Skill Lost Tax       [Bottom 3]
    %     Col 4 (Node 25): Exit 4: Benefit, LOPE & Justice    [Bottom 4]
    %     Col 5 (Node 26): Base Infra, Health & NZ Super      [Middle Outlay]
    %     Col 6 (Node 27): GST, Productive Cap & Estate Tax   [GOOD Revenue 1]
    %     Col 7 (Node 28): Working-Age PAYE Income Tax        [GOOD Revenue 2]
    %     Col 8 (Node 29): Abroad Brain-Drain Lost Tax        [Top — Emigration]
    infra_sup_cond = NZD_Scale * (0.068 + 0.22 * p_super); % ~10.2 kNZD/yr annualized public health, roads & NZ Super per retained adult
    reg_F56_kNZD   = zeros(5, 8);

    % Row 1: 17. Chronic Adversity & Benefit Trap
    c124_adv = ex124_tier(1) + NZD_Scale * 0.365;
    reg_F56_kNZD(1, [1, 2, 4]) = reg_Pop_S5(1) * c124_adv * ex124_split; % Cols 1, 2, 4 = Exits 1, 2, 4
    reg_F56_kNZD(1, 3)         = reg_Pop_S5(1) * (NZD_Scale * 0.088);    % Col 3 = Exit 3 Lower-Skill Lost Tax
    reg_F56_kNZD(1, 5)         = reg_Pop_S5(1) * infra_sup_cond;         % Col 5 = Base Infra, Health & Super
    reg_F56_kNZD(1, 6)         = reg_Pop_S5(1) * (0.45 * gst_tier(1));   % Col 6 = GST/Cap/Estate
    reg_F56_kNZD(1, 7)         = reg_Pop_S5(1) * (0.35 * paye_tier(1));  % Col 7 = PAYE

    % Row 2: 18. Domestic Core Workforce & Trades
    c124_core = 0.25 * ex124_tier(2) + NZD_Scale * 0.022;
    reg_F56_kNZD(2, [1, 2, 4]) = reg_Pop_S5(2) * c124_core * [0.05, 0.35, 0.60];
    reg_F56_kNZD(2, 3)         = reg_Pop_S5(2) * (NZD_Scale * 0.012);    % Col 3 = Exit 3 Minor Skill-Mismatch Drag
    reg_F56_kNZD(2, 5)         = reg_Pop_S5(2) * infra_sup_cond;
    reg_F56_kNZD(2, 6)         = reg_Pop_S5(2) * gst_tier(2);
    reg_F56_kNZD(2, 7)         = reg_Pop_S5(2) * paye_tier(2);

    % Row 3: 19. Passive Land/Rent Speculation [z_l Skew]
    reg_F56_kNZD(3, 5)         = reg_Pop_S5(3) * infra_sup_cond;
    reg_F56_kNZD(3, 6)         = reg_Pop_S5(3) * (0.95 * gst_tier(3));
    reg_F56_kNZD(3, 7)         = reg_Pop_S5(3) * (0.68 * paye_tier(3));

    % Row 4: 20. Productive Enterprise Builders [z_h Innovators]
    zh_mult = 1.18 + 0.14 * eta_ref;
    reg_F56_kNZD(4, 5)         = reg_Pop_S5(4) * infra_sup_cond;
    reg_F56_kNZD(4, 6)         = reg_Pop_S5(4) * (zh_mult * gst_tier(3));
    reg_F56_kNZD(4, 7)         = reg_Pop_S5(4) * (zh_mult * paye_tier(3));

    % Row 5: 21. Emigrated Abroad [Brain Drain] -> 100% into Col 8 (Node 29: Abroad Brain-Drain Lost Tax)
    emig_weights = reg_F45_Pop(:, 5) / max(1e-12, sum(reg_F45_Pop(:, 5)));
    cond_emig_tx = sum(emig_weights .* (paye_tier + gst_tier));
    reg_F56_kNZD(5, 8)         = reg_Pop_S5(5) * cond_emig_tx;

    Adult_Fiscal_5x8 = Adult_Fiscal_5x8 + w_reg * reg_F56_kNZD;
end

%% HARMONIZE 6-GATE (29-NODE SOLUTION 1) FLOW SCALES — ZERO RIBBON DISTORTION AT GATE 6!
Pop_Priv_G1_G2  = 1.0 - Pop_S2_ECE(1);
Pop_Priv_G3     = 1.0 - sum(Pop_S3_Adol(1:2));
Pop_S1_Birth(4) = max(0.0, 1.0 - Pop_S1_Birth(1) - Pop_S1_Birth(2));

Pop_S2_ECE_4Node  = [Pop_S2_ECE(1), Pop_S2_ECE(2), Pop_S2_ECE(3), Pop_Priv_G1_G2];
Pop_S3_Adol_5Node = [Pop_S3_Adol(1), Pop_S3_Adol(2), Pop_S3_Adol(3), Pop_S3_Adol(4), Pop_Priv_G3];

if ~is_reform_panel
    cond_priv_G2 = 18.50;
    cond_priv_G3 = 19.00;
else
    cond_priv_G2 = 18.70;
    cond_priv_G3 = 19.80;
end
Priv_Cohort_G2 = Pop_Priv_G1_G2 * cond_priv_G2;
Priv_Cohort_G3 = Pop_Priv_G3    * cond_priv_G3;

S2_ECE_4Node_kNZD  = [ECE_Step_Dollars(1),  ECE_Step_Dollars(2),  ECE_Step_Dollars(3),  Priv_Cohort_G2];
S3_Adol_5Node_kNZD = [Adol_Step_Dollars(1), Adol_Step_Dollars(2), Adol_Step_Dollars(3), Adol_Step_Dollars(4), Priv_Cohort_G3];

% Store full 8-column unpruned Adult Fiscal Ledger vector for Table 14 CSV & Node Labels:
% Cols 1..8: [22: Exit 1, 23: Exit 2, 24: Exit 3, 25: Exit 4, 26: Infra/Super, 27: GST/Cap/Estate, 28: PAYE, 29: Abroad]
Fiscal_Col_Full8 = sum(Adult_Fiscal_5x8, 1);

% Exact Cohort Population Shares (%) experiencing Exits 1..4 in Adulthood (synchronized with Fates Gate 5):
Exit_Pop_Pct = 100 * [ ...
    0.141 * Pop_S5_Career(1) + 0.004 * Pop_S5_Career(2), ... % Exit 1: State Care Legacy (% of cohort)
    0.258 * Pop_S5_Career(1) + 0.024 * Pop_S5_Career(2), ... % Exit 2: Avoidable Hosp & CAMHS (% of cohort)
    0.260 * Pop_S5_Career(1) + 0.080 * Pop_S5_Career(2), ... % Exit 3: Lower-Skill Lost Tax (% of cohort)
    0.385 * Pop_S5_Career(1) + 0.065 * Pop_S5_Career(2)];    % Exit 4: Benefit, LOPE & Justice (% of cohort)

% NEVER suppress Exit 1..4 in SS1/SS2! Instead, enforce a 0.45 kNZD/yr visual height floor on Exit 1..4
% so the block and ribbon always render at the bottom, and note "[ribbon not to scale]" on the label when floored:
Fiscal_5x8_Plot  = max(Adult_Fiscal_5x8, 0);
minExit_Vis_kNZD = 0.45;
is_floored_ex    = false(1, 4);
Fiscal_5x8_Plot(:, is_floored_ex) = repmat([minExit_Vis_kNZD; zeros(4, 1)], 1, sum(is_floored_ex));

Flow_S5_to_S6 = Fiscal_5x8_Plot;
S6_Totals     = Fiscal_Col_Full8;       % [1 x 8] Exact unfloored Gate 6 kNZD/yr for labels & Table 14!
S5_Totals     = sum(Flow_S5_to_S6, 2)'; % [1 x 5] Gate 5 Career Stratum Total Fiscal Footprint kNZD/yr
active_c6     = true(1, 8);             % All 8 Gate-6 nodes remain active across SS0, SS1, and SS2!

% Build 3x5 Flow_S4_to_S5 (3 Launch Skill Tiers -> 5 Adult Career Strata) conserving S5_Totals:
P_into_G5     = Flow_S4_to_S5_P ./ max(1e-12, sum(Flow_S4_to_S5_P, 1));
Flow_S4_to_S5 = P_into_G5 .* S5_Totals;
S4_Totals     = sum(Flow_S4_to_S5, 2)';

% Build Gates 1->2->3->4 scaled smoothly to match childhood kNZD/yr proportions while meeting S4_Totals:
Flow_S1_to_S2(4, 1) = 0;
Flow_S1_to_S2_4N = zeros(4, 4);
for c2 = 1:3
    pub_in = sum(Flow_S1_to_S2(1:3, c2));
    if pub_in > 1e-8
        Flow_S1_to_S2_4N(1:3, c2) = S2_ECE_4Node_kNZD(c2) * (Flow_S1_to_S2(1:3, c2) / pub_in);
    else
        Flow_S1_to_S2_4N(3, c2) = S2_ECE_4Node_kNZD(c2);
    end
end
Flow_S1_to_S2_4N(4, 4) = S2_ECE_4Node_kNZD(4);
S1_Totals = sum(Flow_S1_to_S2_4N, 2);

P_23 = Flow_S2_to_S3 ./ max(1e-8, sum(Flow_S2_to_S3, 2));
Flow_S2_to_S3_5N = zeros(4, 5);
Flow_S2_to_S3_5N(1:3, 1:4) = (S2_ECE_4Node_kNZD(1:3)' .* P_23) * 0.82;
Flow_S2_to_S3_5N(1:3, 5)   = sum((S2_ECE_4Node_kNZD(1:3)' .* P_23) * 0.18, 2);

w_priv_r2    = [0, ECE_Step_Dollars(2), ECE_Step_Dollars(3)];
w_priv_r2    = w_priv_r2 / max(1e-8, sum(w_priv_r2));
P_priv_to_G3 = w_priv_r2 * P_23;
for c3 = 1:4
    Flow_S2_to_S3_5N(4, c3) = S2_ECE_4Node_kNZD(4) * P_priv_to_G3(c3) * (1 - 0.78 * (c3 >= 3));
    Flow_S2_to_S3_5N(4, 5)  = Flow_S2_to_S3_5N(4, 5) + S2_ECE_4Node_kNZD(4) * P_priv_to_G3(c3) * (0.78 * (c3 >= 3));
end
target_G3_widths = sum(S2_ECE_4Node_kNZD) * (S3_Adol_5Node_kNZD / max(1e-8, sum(S3_Adol_5Node_kNZD)));
for iter_ras = 1:4
    Flow_S2_to_S3_5N = Flow_S2_to_S3_5N .* (target_G3_widths ./ max(1e-8, sum(Flow_S2_to_S3_5N, 1)));
    Flow_S2_to_S3_5N = Flow_S2_to_S3_5N .* (S2_ECE_4Node_kNZD' ./ max(1e-8, sum(Flow_S2_to_S3_5N, 2)));
end

S3_In_Widths = sum(Flow_S2_to_S3_5N, 1);
P_34 = Flow_S3_to_S4 ./ max(1e-8, sum(Flow_S3_to_S4, 2));
Flow_S3_to_S4_5N = zeros(5, 3);
Flow_S3_to_S4_5N(1:4, :) = S3_In_Widths(1:4)' .* P_34;
w_priv_r3 = [0, 0, Adol_Step_Dollars(3), Adol_Step_Dollars(4)];
w_priv_r3 = w_priv_r3 / max(1e-8, sum(w_priv_r3));
Flow_S3_to_S4_5N(5, :) = S3_In_Widths(5) * (w_priv_r3 * P_34);

scale_child_to_adult = sum(S5_Totals) / max(1e-8, sum(Flow_S3_to_S4_5N, 'all'));
Flow_S1_to_S2_4N = Flow_S1_to_S2_4N * scale_child_to_adult;
Flow_S2_to_S3_5N = Flow_S2_to_S3_5N * scale_child_to_adult;
Flow_S3_to_S4_5N = Flow_S3_to_S4_5N * scale_child_to_adult;
for iter_ras = 1:10
    Flow_S3_to_S4_5N = Flow_S3_to_S4_5N .* (S4_Totals ./ max(1e-8, sum(Flow_S3_to_S4_5N, 1)));
    Flow_S3_to_S4_5N = Flow_S3_to_S4_5N .* (sum(Flow_S2_to_S3_5N, 1)' ./ max(1e-8, sum(Flow_S3_to_S4_5N, 2)));
end

%% COMPUTE MACRO PUBLIC RESIDUAL (OMEGA) & 2050 50/50 SURPLUS SPLIT AT GATE 6
% Columns 1..5 of Gate 6 are Domestic Outlays & Foregone Drag (Exits 1, 2, 3, 4 + Infra/Super);
% Direct Crown Budget Outlays are Cols [1, 2, 4, 5] (Exits 1, 2, 4 + Infra/Super);
% Good Tax Revenues are Cols [6, 7] (GST/Cap/Estate + PAYE):
Bad_Adult  = sum(Fiscal_Col_Full8([1, 2, 4, 5]));
Good_Adult = sum(Fiscal_Col_Full8([6, 7]));
net_fisc   = Good_Adult - Bad_Adult;

Surplus_Adult  = max(0, net_fisc) * double(is_reform_panel);
DebtSink_50    = 0.50 * Surplus_Adult;
Reinvest_50    = 0.50 * Surplus_Adult;

r_gov_bond   = 0.042;
mu_infra_div = 1.65;
Cohort_N     = 60.0 * reg_pop_share;

% Save exact 29-node population & monetary vectors into output Ledger struct
Ledger.Pop_S1_Birth                     = Pop_S1_Birth(:);
Ledger.Pop_S2_ECE                       = Pop_S2_ECE(:);
Ledger.Pop_S2_ECE_4Node                 = Pop_S2_ECE_4Node(:);
Ledger.Pop_S3_Adol                      = Pop_S3_Adol(:);
Ledger.Pop_S3_Adol_5Node                = Pop_S3_Adol_5Node(:);
Ledger.Pop_S4_Skill                     = Pop_S4_Skill(:);
Ledger.Pop_S5_Career                    = Pop_S5_Career(:);    % 5x1 vector (Nodes 17..21)
Ledger.S1_Birth_kNZD                    = S1_Totals(:);
Ledger.S2_ECE_3Node_kNZD                = ECE_Step_Dollars(:);
Ledger.S2_ECE_4Node_kNZD                = S2_ECE_4Node_kNZD(:);
Ledger.S3_Adol_4Node_kNZD               = Adol_Step_Dollars(:);
Ledger.S3_Adol_5Node_kNZD               = S3_Adol_5Node_kNZD(:);
Ledger.S4_Skill_kNZD                    = S4_Totals(:);
Ledger.S5_Career_kNZD                   = S5_Totals(:);        % 5x1 vector (Nodes 17..21)
Ledger.S6_Fiscal_kNZD                   = Fiscal_Col_Full8(:); % 8x1 vector (Nodes 22..29: Exits 1,2,3,4 at bottom!)
Ledger.Whanau_And_Landlord_G1_kNZD      = Whanau_Care_G1_G2(:);
Ledger.Net_Fiscal_Balance_kNZD          = [net_fisc, net_fisc];
Ledger.SinkingFund_50Pct_kNZD           = [DebtSink_50, DebtSink_50];
Ledger.ReinvestmentPool_50Pct_kNZD      = [Reinvest_50, Reinvest_50];
Ledger.Annual_DebtService_Saving_kNZD   = r_gov_bond * [DebtSink_50, DebtSink_50];
Ledger.Public_Infra_Yield_Dividend_kNZD = mu_infra_div * [Reinvest_50, Reinvest_50];
Ledger.Cum_2050_DebtReduction_MNZD      = 25 * Cohort_N * DebtSink_50 * (1 + 0.5 * 25 * r_gov_bond);
Ledger.Cum_2050_ReinvestPool_MNZD       = 25 * Cohort_N * Reinvest_50;

%% BUILD 29-NODE LABELS (EXITS 1, 2, 3, 4 ORDERED BOTTOM-TO-TOP AT GATE 6!)
Nodes_S1 = {sprintf('1. Material & Severe Hardship\n     (%.1f%% pop | %.1f kNZD/yr)', 100*Pop_S1_Birth(1), S1_Totals(1)), ...
    sprintf('2. Residual AHC Paper &\n     Whanau (%.1f%% pop | %.1f kNZD/yr)', 100*Pop_S1_Birth(2), S1_Totals(2)), ...
    sprintf('3. Universal Birth Benefit\n     (100%% pop | %.1f kNZD/yr)',     S1_Totals(3)), ...
    sprintf('4. Private Birth Out-of-Pocket\n     (%.1f%% pop | %.1f kNZD/yr)',100*Pop_S1_Birth(4), S1_Totals(4))};

Nodes_S2 = {sprintf('5. ECE Corner + Benefit Need\n     (%.1f%% pop | %.1f kNZD/yr)',          100*Pop_S2_ECE_4Node(1), S2_ECE_4Node_kNZD(1)), ...
    sprintf('6. Public ECE Wraparound\n     (%.1f%% pop | %.1f kNZD/yr)',              100*Pop_S2_ECE_4Node(2), S2_ECE_4Node_kNZD(2)), ...
    sprintf('7. High-Intensity Public ECE\n     (%.1f%% pop | %.1f kNZD/yr)',          100*Pop_S2_ECE_4Node(3), S2_ECE_4Node_kNZD(3)), ...
    sprintf('8. Private Parental ECE (Cash+Time)\n     (%.1f%% pop | %.1f kNZD/yr)',   100*Pop_S2_ECE_4Node(4), S2_ECE_4Node_kNZD(4))};

Nodes_S3 = {sprintf('9. HH Unemp & Truancy Remed.\n     (%.1f%% pop | %.1f kNZD/yr)',          100*Pop_S3_Adol_5Node(1), S3_Adol_5Node_kNZD(1)), ...
    sprintf('10. Psychosocial CAMHS &\n       ACC ISSC (%.1f%% pop | %.1f kNZD/yr)',   100*Pop_S3_Adol_5Node(2), S3_Adol_5Node_kNZD(2)), ...
    sprintf('11. Public Schooling (d_2)\n       (%.1f%% pop | %.1f kNZD/yr)',          100*Pop_S3_Adol_5Node(3), S3_Adol_5Node_kNZD(3)), ...
    sprintf('12. Montessori / Tuakana Mentoring\n       (%.1f%% pop | %.1f kNZD/yr)',  100*Pop_S3_Adol_5Node(4), S3_Adol_5Node_kNZD(4)), ...
    sprintf('13. Private Adol. Commit (Cash+Time)\n       (%.1f%% pop | %.1f kNZD/yr)',100*Pop_S3_Adol_5Node(5), S3_Adol_5Node_kNZD(5))};

Nodes_S4 = {sprintf('14. Struggling Tier h1-h2\n       (%.1f%% pop)', 100*Pop_S4_Skill(1)), ...
    sprintf('15. Core Skill Tier h3-h5\n       (%.1f%% pop)', 100*Pop_S4_Skill(2)), ...
    sprintf('16. Thriving Tier h6-h7\n       (%.1f%% pop)',   100*Pop_S4_Skill(3))};

Nodes_S5 = {sprintf('17. Chronic Adversity & Benefit Trap\n       (%.1f%% pop | %.1f kNZD/yr)',  100*Pop_S5_Career(1), S5_Totals(1)), ...
    sprintf('18. Domestic Core Workforce & Trades\n       (%.1f%% pop | %.1f kNZD/yr)',  100*Pop_S5_Career(2), S5_Totals(2)), ...
    sprintf('19. Passive Land/Rent Speculation [z_l]\n       (%.1f%% pop | %.1f kNZD/yr)', 100*Pop_S5_Career(3), S5_Totals(3)), ...
    sprintf('20. Productive Enterprise Builders [z_h]\n       (%.1f%% pop | %.1f kNZD/yr)',100*Pop_S5_Career(4), S5_Totals(4)), ...
    sprintf('21. Emigrated Abroad [Brain Drain]\n       (%.1f%% pop | %.1f kNZD/yr)',    100*Pop_S5_Career(5), S5_Totals(5))};

% Gate 6 (Nodes 22..29): Pure gross credit labels on Nodes 27 & 28 (no embedded 50/50 split text)
ret_pop_pct = 100 * (1.0 - Pop_S5_Career(5));
if is_reform_panel
    lbl_27 = sprintf('27. GST, z_h Cap & Estate Tax\n       (%.1f%% pop | %.1f kNZD/yr)', ret_pop_pct, S6_Totals(6));
    lbl_28 = sprintf('28. Working-Age Builder PAYE Tax\n       (%.1f%% pop | %.1f kNZD/yr)', ret_pop_pct, S6_Totals(7));
else
    lbl_27 = sprintf('27. GST, Cap & Estate Pool [z_l Skew]\n       (%.1f%% pop | %.1f kNZD/yr)', ret_pop_pct, S6_Totals(6));
    lbl_28 = sprintf('28. Working-Age PAYE Income Tax\n       (%.1f%% pop | %.1f kNZD/yr)',       ret_pop_pct, S6_Totals(7));
end

scale_tag = {'', ' — not to scale'};
Nodes_S6 = {sprintf('22. Exit 1: State Care Legacy (%.2f%% pop | %.2f kNZD/yr%s)', ...
    Exit_Pop_Pct(1), S6_Totals(1), scale_tag{1 + is_floored_ex(1)}), ...
    sprintf('23. Exit 2: Avoidable Hosp & CAMHS (%.1f%% pop | %.1f kNZD/yr%s)', ...
    Exit_Pop_Pct(2), S6_Totals(2), scale_tag{1 + is_floored_ex(2)}), ...
    sprintf('24. Exit 3: Lower-Skill Lost Tax (%.1f%% pop | %.1f kNZD/yr%s)', ...
    Exit_Pop_Pct(3), S6_Totals(3), scale_tag{1 + is_floored_ex(3)}), ...
    sprintf('25. Exit 4: Benefit, LOPE & Justice (%.1f%% pop | %.1f kNZD/yr%s)', ...
    Exit_Pop_Pct(4), S6_Totals(4), scale_tag{1 + is_floored_ex(4)}), ...
    sprintf('26. Base Infra, Health & NZ Super\n       (%.1f%% pop @ %.1fk/adult = %.1f kNZD/yr)\n       [Gross: %.2f BNZD/yr cohort | %.1f BNZD/yr %s]', ...
    ret_pop_pct, S6_Totals(5) / max(1e-4, 1 - Pop_S5_Career(5)), S6_Totals(5), ...
    0.060 * reg_pop_share * S6_Totals(5), 4.0 * reg_pop_share * S6_Totals(5), reg_tag), ...
    lbl_27, ...
    lbl_28, ...
    sprintf('29. Abroad Brain-Drain Lost Tax\n       (%.1f%% pop | %.1f kNZD/yr)', ...
    100*Pop_S5_Career(5), S6_Totals(8))};

% Prune sub-threshold phantom ribbons (< 0.10 kNZD/yr), keeping Exit 1..4 visual floors intact:
minFiscalRibbon_k = 0.10;
Flow_S1_to_S2_4N = pruneAndBalanceFlowMatrix(Flow_S1_to_S2_4N, minFiscalRibbon_k);
Flow_S2_to_S3_5N = pruneAndBalanceFlowMatrix(Flow_S2_to_S3_5N, minFiscalRibbon_k);
Flow_S3_to_S4_5N = pruneAndBalanceFlowMatrix(Flow_S3_to_S4_5N, minFiscalRibbon_k);
Flow_S4_to_S5    = pruneAndBalanceFlowMatrix(Flow_S4_to_S5,    minFiscalRibbon_k);
Flow_S5_to_S6    = pruneAndBalanceFlowMatrix(Flow_S5_to_S6,    minFiscalRibbon_k);
re_floor = is_floored_ex & (sum(Flow_S5_to_S6(:, 1:4), 1) < minExit_Vis_kNZD);
Flow_S5_to_S6(:, re_floor) = [minExit_Vis_kNZD; zeros(4, 1)] .* ones(1, sum(re_floor));

% Assemble links cell array (looping j outer / i inner on Gate 5->6 guarantees Nodes 22..29 enter SK.NodeList in exact 1->2->3->4 order!)
links = {};
row_k = 0;
for j = 1:4
    for i = 1:4
        if Flow_S1_to_S2_4N(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S1{i}, Nodes_S2{j}, Flow_S1_to_S2_4N(i, j)};
        end
    end
end
for j = 1:5
    for i = 1:4
        if Flow_S2_to_S3_5N(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S2{i}, Nodes_S3{j}, Flow_S2_to_S3_5N(i, j)};
        end
    end
end
for j = 1:3
    for i = 1:5
        if Flow_S3_to_S4_5N(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S3{i}, Nodes_S4{j}, Flow_S3_to_S4_5N(i, j)};
        end
    end
end
for j = 1:5
    for i = 1:3
        if Flow_S4_to_S5(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S4{i}, Nodes_S5{j}, Flow_S4_to_S5(i, j)};
        end
    end
end
for j = 1:8
    for i = 1:5
        if Flow_S5_to_S6(i, j) > 0
            row_k = row_k + 1;
            links(row_k, :) = {Nodes_S5{i}, Nodes_S6{j}, Flow_S5_to_S6(i, j)};
        end
    end
end

axes(ax);
hold(ax, 'on');

SK = SSankey(links(:, 1), links(:, 2), links(:, 3));
SK.RenderingMethod = 'interp';
SK.Align           = 'center';
SK.LabelLocation   = 'right';
SK.BlockScale      = 0.13;
SK.Sep             = 0.038;
if isprop(SK, 'FontName')
    SK.FontName = 'Helvetica';
end

% 29-Node Palette (Exits 1, 2, 3, 4 at Nodes 22..25 matched 1-to-1 with Fates Nodes 13..16!):
Master_Colors = [0.72, 0.12, 0.14;  % 1. Material & Severe Hardship [Deep Crimson]
    0.78, 0.32, 0.20;  % 2. Residual AHC Paper & Whanau [Burnt Rust]
    0.24, 0.50, 0.70;  % 3. Universal Birth Benefit [Public Steel Blue]
    0.82, 0.54, 0.14;  % 4. Private Birth Out-of-Pocket [Parental Warm Gold]
    0.72, 0.12, 0.14;  % 5. ECE Corner + Benefit Need [Deep Crimson]
    0.24, 0.50, 0.70;  % 6. Public ECE Wraparound
    0.14, 0.62, 0.50;  % 7. High-Intensity Public ECE
    0.84, 0.56, 0.14;  % 8. Private Parental ECE (Cash+Time) [Parental Warm Gold]
    0.72, 0.12, 0.14;  % 9. HH Unemp & Truancy Remediation [Deep Crimson]
    0.78, 0.32, 0.20;  % 10. Psychosocial CAMHS & ACC ISSC [Burnt Rust]
    0.26, 0.52, 0.70;  % 11. Public Schooling (d_2)
    0.14, 0.62, 0.50;  % 12. Montessori / Tuakana Mentoring
    0.84, 0.56, 0.14;  % 13. Private Adol. Commit (Cash+Time) [Parental Warm Gold]
    0.72, 0.12, 0.14;  % 14. Struggling Tier h1-h2 [Deep Crimson]
    0.30, 0.56, 0.68;  % 15. Core Skill Tier h3-h5
    0.12, 0.58, 0.46;  % 16. Thriving Tier h6-h7
    0.72, 0.12, 0.14;  % 17. Gate 5: Chronic Adversity & Benefit Trap [Deep Crimson]
    0.28, 0.54, 0.68;  % 18. Gate 5: Domestic Core Workforce & Trades [Steel Blue]
    0.76, 0.44, 0.18;  % 19. Gate 5: Passive Land/Rent Speculation [z_l Ochre-Rust]
    0.10, 0.60, 0.46;  % 20. Gate 5: Productive Enterprise Builders [z_h Emerald Teal]
    0.48, 0.30, 0.66;  % 21. Gate 5: Emigrated Abroad [Purple]
    0.72, 0.12, 0.14;  % 22. Gate 6 Exit 1: State Care Legacy [Deep Crimson — Bottom 1]
    0.78, 0.32, 0.20;  % 23. Gate 6 Exit 2: Avoidable Hosp & CAMHS [Burnt Rust — Bottom 2]
    0.80, 0.58, 0.20;  % 24. Gate 6 Exit 3: Lower-Skill Lost Tax [Warm Amber/Gold-Ochre — Bottom 3]
    0.58, 0.14, 0.20;  % 25. Gate 6 Exit 4: Benefit, LOPE & Justice [Dark Ruby — Bottom 4]
    0.70, 0.44, 0.22;  % 26. Gate 6: Base Infra, Health & NZ Super [Ochre-Brown]
    0.20, 0.46, 0.68;  % 27. Gate 6: GST, Cap & Estate Tax Pool [Steel Blue]
    0.12, 0.58, 0.46;  % 28. Gate 6: Working-Age PAYE Income Tax [Teal]
    0.46, 0.28, 0.66   % 29. Gate 6: Abroad Brain-Drain Lost Tax [Purple — Top]
    ];

All_Node_Names = [Nodes_S1, Nodes_S2, Nodes_S3, Nodes_S4, Nodes_S5, Nodes_S6];
if isprop(SK, 'NodeList') && ~isempty(SK.NodeList)
    % Enforce strict canonical 1..29 vertical node ordering within each column!
    active_canonical = All_Node_Names(ismember(All_Node_Names, SK.NodeList));
    SK.NodeList      = active_canonical(:);
    mapped_colors    = zeros(length(SK.NodeList), 3);
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
xlim(ax, [curr_xlim(1) - 0.16, curr_xlim(2) + 1.18]);
curr_ylim = ylim(ax);
y_span    = diff(curr_ylim);
ylim(ax, [curr_ylim(1) - 0.24 * y_span, curr_ylim(2) + 0.12 * y_span]);

txt_all = findall(ax, 'Type', 'text');
set(ax, 'FontName', 'Helvetica');
set(txt_all, 'FontName', 'Helvetica', 'FontSize', 8.4);

% --- VERTICAL ANTI-OVERLAP DE-CROWDING FOR SANKEY NODE LABELS ACROSS COLUMNS 1..6 ---
% Scans rendered text labels in each column, sorts bottom-to-top, and enforces minimum
% vertical spacing (scaled by line count) so compressed bottom nodes never collide!
for c_col = 1:6
    c_txts = [];
    c_ypos = [];
    c_nlin = [];
    for k_t = 1:numel(txt_all)
        pos_t = get(txt_all(k_t), 'Position');
        str_t = get(txt_all(k_t), 'String');
        if abs(pos_t(1) - c_col) < 0.48 && ~isempty(str_t)
            c_txts(end+1) = txt_all(k_t); %#ok<AGROW>
            c_ypos(end+1) = pos_t(2);     %#ok<AGROW>
            if iscell(str_t)
                c_nlin(end+1) = numel(str_t); %#ok<AGROW>
            else
                c_nlin(end+1) = size(char(str_t), 1); %#ok<AGROW>
            end
        end
    end
    if numel(c_txts) >= 2
        [c_ypos, ord_y] = sort(c_ypos, 'ascend');
        c_txts          = c_txts(ord_y);
        c_nlin          = c_nlin(ord_y);
        % Allow bottom label to sit slightly below the bottom bar edge so thin Exit 1..4 labels fan out cleanly:
        c_ypos(1) = max(curr_ylim(1) - 0.025 * y_span, c_ypos(1) - 0.018 * y_span * (c_col == 6));
        for j_t = 2:numel(c_txts)
            min_gap = (0.024 + 0.013 * (0.5 * (c_nlin(j_t-1) + c_nlin(j_t)) - 1)) * y_span;
            if c_ypos(j_t) - c_ypos(j_t-1) < min_gap
                c_ypos(j_t) = c_ypos(j_t-1) + min_gap;
            end
        end
        for j_t = 1:numel(c_txts)
            old_p = get(c_txts(j_t), 'Position');
            set(c_txts(j_t), 'Position', [old_p(1), c_ypos(j_t), old_p(3)]);
        end
    end
end

%% DRAW 6-GATE HORIZONTAL "J" AXIS CENTERED ON EACH BAR
y_axis_line  = curr_ylim(1) - 0.09 * y_span;
tick_h       = 0.022 * y_span;
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

J_Stage_Labels = {sprintf('J = 1 (Birth, Age 0)\n(Out-of-Pocket vs Public kNZD)');
    sprintf('J = 2..3 (Ages 0-5)\n(First 2000 Days ECE Gate)');
    sprintf('J = 5 (Ages 12-14)\n(Adol. Gate + Crisis Remed.)');
    sprintf('J = 6..7 (Age 20)\n(Adult Skill Launch)');
    sprintf('J = 8..11 (Ages 30-54)\n(Career & z_l / z_h Sorting)');
    sprintf('J = 10..16 (Adult Ledger)\n(Exits 1-4 & Super vs Tax kNZD)') };

for col_x = 1:6
    x_tick = x_center_col(col_x);
    plot(ax, [x_tick, x_tick], [y_axis_line - tick_h, y_axis_line + tick_h], '-', ...
        'Color', [0.25, 0.25, 0.25], 'LineWidth', 1.5);
    text(ax, x_tick, y_axis_line - 1.6 * tick_h, J_Stage_Labels{col_x}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', 'Helvetica', 'FontSize', 8.8, 'FontWeight', 'bold', ...
        'Color', [0.20, 0.20, 0.20]);
end

%% DRAW WIGGLY REGIME-BREAK LINE DOWN GATE 5 (J = 8..11: COHORT STRATA -> FISCAL LEDGER)
col5_boxes = [];
for k_p = 1:length(p_all)
    xd = get(p_all(k_p), 'XData');
    yd = get(p_all(k_p), 'YData');
    if numel(xd) == 4 && abs((sum(xd(:)) / 4) - 5) < 0.45
        col5_boxes(end+1, :) = [min(xd(:)), max(xd(:)), min(yd(:)), max(yd(:))]; %#ok<AGROW>
    end
end
if ~isempty(col5_boxes)
    x_c5     = mean(col5_boxes(:, 1:2), 'all');
    w_c5     = mean(col5_boxes(:, 2) - col5_boxes(:, 1));
    y_bot_c5 = min(col5_boxes(:, 3)) - 0.025 * y_span;
    y_top_c5 = max(col5_boxes(:, 4)) + 0.025 * y_span;

    y_wig   = linspace(y_bot_c5, y_top_c5, 180);
    n_waves = 9.5;
    amp_x   = 0.16 * w_c5;
    dx_gap  = 0.11 * w_c5;
    x_wig_C = x_c5 + amp_x * sin(2 * pi * n_waves * (y_wig - y_bot_c5) / max(1e-8, y_top_c5 - y_bot_c5));

    plot(ax, x_wig_C,          y_wig, '-', 'Color', [1.00, 1.00, 1.00], 'LineWidth', 3.6);
    plot(ax, x_wig_C - dx_gap, y_wig, '-', 'Color', [0.15, 0.15, 0.15], 'LineWidth', 1.4);
    plot(ax, x_wig_C + dx_gap, y_wig, '-', 'Color', [0.15, 0.15, 0.15], 'LineWidth', 1.4);

    text(ax, x_c5, y_top_c5 + 0.012 * y_span, ...
        sprintf('%s Cohort Career Strata  |  Adult Fiscal Ledger %s', char(9668), char(9658)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontName', 'Helvetica', 'FontSize', 7.8, 'FontWeight', 'bold', ...
        'Color', [0.20, 0.20, 0.20], 'BackgroundColor', [0.98, 0.98, 0.94], ...
        'EdgeColor', [0.55, 0.55, 0.55], 'Margin', 1.8);
end

%% DOCUMENT 2 PROTOCOL: NET-ZERO BREAKEVEN MARKER & 50/50 SURPLUS SPLIT ON GATE 6 (COL 6)
% Bottom 5 columns of Gate 6 (Cols 1..5 = Exits 1, 2, 3, 4 + Infra/Super) sit below Good Taxes (Cols 6..7 = GST/Cap + PAYE):
n_bad_vis = sum(active_c6(1:5));
col6_boxes = [];
for k_p = 1:length(p_all)
    xd = get(p_all(k_p), 'XData');
    yd = get(p_all(k_p), 'YData');
    if numel(xd) == 4 && abs((sum(xd(:)) / 4) - 6) < 0.45
        col6_boxes(end+1, :) = [min(xd(:)), max(xd(:)), min(yd(:)), max(yd(:))]; %#ok<AGROW>
    end
end

if size(col6_boxes, 1) >= (n_bad_vis + 2)
    [~, s_ord] = sort(col6_boxes(:, 3), 'ascend');
    col6_boxes = col6_boxes(s_ord, :);

    x_left_c6 = col6_boxes(1, 1);
    x_rght_c6 = col6_boxes(1, 2);
    x_cent_c6 = 0.5 * (x_left_c6 + x_rght_c6);

    bad_boxes  = col6_boxes(1:n_bad_vis, :);
    good_boxes = col6_boxes((n_bad_vis+1):min(n_bad_vis+2, size(col6_boxes, 1)), :);

    y_top_bad  = bad_boxes(end, 4);
    y_bot_good = good_boxes(1, 3);
    y_origin   = 0.5 * (y_top_bad + y_bot_good);
    y_zero_c6  = y_origin;

    if net_fisc > 0
        f_surplus = min(1.0, net_fisc / max(1e-8, Good_Adult));
        g_heights = good_boxes(:, 4) - good_boxes(:, 3);
        target_h  = f_surplus * sum(g_heights);
        cum_h     = 0;
        for g_k = 1:size(good_boxes, 1)
            if cum_h + g_heights(g_k) >= target_h || g_k == size(good_boxes, 1)
                y_zero_c6 = good_boxes(g_k, 3) + max(0, target_h - cum_h);
                break;
            end
            cum_h = cum_h + g_heights(g_k);
        end
    elseif net_fisc < 0
        f_deficit = min(1.0, (Bad_Adult - Good_Adult) / max(1e-8, Bad_Adult));
        b_heights = bad_boxes(:, 4) - bad_boxes(:, 3);
        target_d  = f_deficit * sum(b_heights);
        cum_d     = 0;
        for b_k = size(bad_boxes, 1):-1:1
            if cum_d + b_heights(b_k) >= target_d || b_k == 1
                y_zero_c6 = bad_boxes(b_k, 4) - max(0, target_d - cum_d);
                break;
            end
            cum_d = cum_d + b_heights(b_k);
        end
    end

    % 1. Dotted Debit/Credit boundary line at y_origin (between Node 26 Outlays and Node 27 Tax Credits):
    plot(ax, [x_left_c6 - 0.030, x_rght_c6 + 0.030], [y_origin, y_origin], ':', ...
        'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.3);

    % 2. Single topline Net Fiscal Balance / Surplus marker at y_zero_c6 (Black line with Gold dot):
    plot(ax, [x_left_c6 - 0.040, x_rght_c6 + 0.040], [y_zero_c6, y_zero_c6], '-', ...
        'Color', [0.10, 0.10, 0.10], 'LineWidth', 2.8);
    plot(ax, x_cent_c6, y_zero_c6, 'o', 'MarkerSize', 6.5, ...
        'MarkerFaceColor', [0.98, 0.82, 0.18], 'MarkerEdgeColor', [0.10, 0.10, 0.10]);

    % 3. Center the 3-line summary callout in the open gap between max(Node 27) and min(Node 28):
    if size(good_boxes, 1) >= 2
        y_badge_c6 = 0.5 * (good_boxes(1, 4) + good_boxes(2, 3));
    else
        y_badge_c6 = good_boxes(1, 4);
    end
    x_badge_c6 = x_rght_c6 + 0.04;
    plot(ax, [x_rght_c6 + 0.010, x_badge_c6], [y_zero_c6, y_badge_c6], '--', ...
        'Color', [0.25, 0.25, 0.25], 'LineWidth', 1.1);

    if is_reform_panel && net_fisc > 0.5
        text(ax, x_badge_c6, y_badge_c6, ...
            sprintf('Net Fiscal Surplus: +%.1f kNZD/yr\n  • 50%% 2050 Debt Sinking: +%.1f kNZD/yr\n  • 50%% Reinvest (Infra/NZSF): +%.1f kNZD/yr', ...
            net_fisc, DebtSink_50, Reinvest_50), ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
            'FontName', 'Helvetica', 'FontSize', 7.8, 'FontWeight', 'bold', ...
            'Color', [0.08, 0.22, 0.18], 'BackgroundColor', [0.95, 1.00, 0.96], ...
            'EdgeColor', [0.15, 0.55, 0.45], 'Margin', 2.0);
    else
        text(ax, x_badge_c6, y_badge_c6, ...
            sprintf('Net Fiscal Balance: %+.1f kNZD/yr\n  • Good Taxes (27+28): %.1f kNZD/yr\n  • Crown Outlays (22..26): %.1f kNZD/yr', ...
            net_fisc, Good_Adult, Bad_Adult), ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
            'FontName', 'Helvetica', 'FontSize', 7.8, 'FontWeight', 'bold', ...
            'Color', [0.12, 0.12, 0.12], 'BackgroundColor', [1.0, 0.98, 0.90], ...
            'EdgeColor', [0.45, 0.45, 0.45], 'Margin', 2.0);
    end
end

if strcmpi(reg_choice, 'Urban') && length(reg_list) > 1
    disp_reg = 'Urban';
elseif strcmpi(reg_choice, 'National')
    disp_reg = 'National';
else
    disp_reg = reg_choice;
end
n_sign = char('+' * (net_fisc >= 0) + '-' * (net_fisc < 0));

if is_reform_panel && net_fisc > 0
    t_str = sprintf('%s — %s | Builders [z_h]: %.1f%% | Net Fiscal Surplus: %s%.1f kNZD/yr (%.1fk Debt Sink + %.1fk Reinvest)', ...
        Panel_Tag, disp_reg, 100*Pop_S5_Career(4), n_sign, abs(net_fisc), DebtSink_50, Reinvest_50);
else
    t_str = sprintf('%s — %s (Cohort-Weighted kNZD/yr per Birth) | Rent-Seekers [z_l]: %.1f%% vs Builders [z_h]: %.1f%% | Net Balance: %s%.1f kNZD/yr', ...
        Panel_Tag, disp_reg, 100*Pop_S5_Career(3), 100*Pop_S5_Career(4), n_sign, abs(net_fisc));
end
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

function T_Prot = Build_Multiphase_2050_Protocol_Table(Phase_Ledgers, Phase_Codes, Target_Region)
%% BUILD_MULTIPHASE_2050_PROTOCOL_TABLE
N_p   = numel(Phase_Ledgers);
L_ref = Phase_Ledgers{1};

T_Prot = table([L_ref.Net_Fiscal_Balance_kNZD(1); L_ref.Net_Fiscal_Balance_kNZD(2)], ...
    'RowNames', {'Gate5_CareerSorting_J8_11', 'Gate6_AdultFiscalLedger_J10_16'}, ...
    'VariableNames', {sprintf('Baseline_%s_kNZD', Phase_Codes{1})});

for p = 2:N_p
    Lp   = Phase_Ledgers{p};
    code = Phase_Codes{p};
    Omega_1 = max(0, Lp.Net_Fiscal_Balance_kNZD(1) - L_ref.Net_Fiscal_Balance_kNZD(1));
    Omega_2 = max(0, Lp.Net_Fiscal_Balance_kNZD(2) - L_ref.Net_Fiscal_Balance_kNZD(2));

    T_Prot.(sprintf('Reform_%s_kNZD', code))             = [Lp.Net_Fiscal_Balance_kNZD(1); Lp.Net_Fiscal_Balance_kNZD(2)];
    T_Prot.(sprintf('Gain_Omega_%s_kNZD', code))         = [Omega_1; Omega_2];
    T_Prot.(sprintf('DebtSinking_50Pct_%s_kNZD', code))  = [Lp.SinkingFund_50Pct_kNZD(1); Lp.SinkingFund_50Pct_kNZD(2)];
    T_Prot.(sprintf('ReinvestPool_50Pct_%s_kNZD', code)) = [Lp.ReinvestmentPool_50Pct_kNZD(1); Lp.ReinvestmentPool_50Pct_kNZD(2)];
    T_Prot.(sprintf('DebtIntSaved_2050_%s_kNZD', code))  = [Lp.Annual_DebtService_Saving_kNZD(1); Lp.Annual_DebtService_Saving_kNZD(2)];
    T_Prot.(sprintf('InfraYieldDiv_2050_%s_kNZD', code)) = [Lp.Public_Infra_Yield_Dividend_kNZD(1); Lp.Public_Infra_Yield_Dividend_kNZD(2)];
end

fprintf('\n=========================================================================================================\n');
fprintf('SECTION 5 PROTOCOL: MULTIPHASE 2050 SOVEREIGN DEBT-SINKING & REINVESTMENT LEDGER (%s)\n', Target_Region);
fprintf('=========================================================================================================\n');
disp(T_Prot);
for p = 2:N_p
    fprintf('  [%s] Cumulative 2050 Sovereign Debt Reduction (per 60k cohort): %.1f MNZD | Reinvest Pool: %.1f MNZD\n', ...
        Phase_Codes{p}, Phase_Ledgers{p}.Cum_2050_DebtReduction_MNZD, Phase_Ledgers{p}.Cum_2050_ReinvestPool_MNZD);
end
end

function T_Fiscal = Build_Custom_Table14_Fiscal_CSV(Phase_Ledgers, Phase_Codes)
%% BUILD_CUSTOM_TABLE14_FISCAL_CSV
% Builds the 29-Node, 6-Gate Monetary & 4-Lane Fiscal Decomposition Table (Solution 1):
%   - Gates 1..4 (Nodes 1..16): Childhood & Age-20 Launch
%   - Gate 5 (Nodes 17..21):    Prime Career & Enterprise Sorting (Adversity, Core, z_l Rent, z_h Builder, Abroad)
%   - Gate 6 (Nodes 22..29):    Annualized Adult Fiscal Ledger (Exits 1, 2, 4, Infra/Super, GST/Cap/Estate, PAYE, Exit 3, Abroad)
N_p = numel(Phase_Ledgers);

Gate_Labels = { ...
    'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0';           'Gate1_J1_Birth_Age0'; ...
    'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; 'Gate2_J2_3_First2000Days_0to5'; ...
    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14';    'Gate3_J5_Adolescent_12to14'; ...
    'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20';  'Gate4_J6_7_AdultLaunch_Age20'; ...
    'Gate5_J8_11_CareerSorting';     'Gate5_J8_11_CareerSorting';     'Gate5_J8_11_CareerSorting';     'Gate5_J8_11_CareerSorting';     'Gate5_J8_11_CareerSorting'; ...
    'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger'; ...
    'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger';'Gate6_J10_16_AdultFiscalLedger'};

Node_Names = { ...
    '1_Material_And_Severe_Hardship';      '2_Residual_AHC_Paper_And_Whanau';     '3_Universal_Birth_Benefit';           '4_Private_Birth_OutOfPocket'; ...
    '5_ECE_Corner_Benefit_Need';           '6_Public_ECE_Wraparound';             '7_High_Intensity_Public_ECE';         '8_Private_Parental_ECE_CashTime'; ...
    '9_HH_Unemp_And_Truancy_Remed';        '10_Psychosocial_CAMHS_ACC_ISSC';      '11_Public_Secondary_Schooling';       '12_Montessori_Tuakana_Public';        '13_Private_Adol_Commit_CashTime'; ...
    '14_Struggling_Tier_h1_h2_Launch';     '15_Core_Skill_Tier_h3_h5_Launch';     '16_Thriving_Tier_h6_h7_Launch'; ...
    '17_Career_Chronic_Adversity_Trap';    '18_Career_Domestic_Core_Workforce';   '19_Career_Passive_Land_Rent_zl';      '20_Career_Productive_Builders_zh';    '21_Career_Emigrated_Abroad'; ...
    '22_Fiscal_Exit1_State_Care_Legacy';   '23_Fiscal_Exit2_Avoidable_Hosp_CAMHS';'24_Fiscal_Exit3_LowerSkill_LostTax';  '25_Fiscal_Exit4_Benefit_LOPE_Justice'; ...
    '26_Fiscal_Infra_Health_NZSuper';      '27_Fiscal_GST_Cap_Estate_Tax';        '28_Fiscal_WorkingAge_PAYE_Tax';       '29_Fiscal_Abroad_BrainDrain_LostTax'};

T_Fiscal = table(Gate_Labels, Node_Names, 'VariableNames', {'Gate', 'Node_Name'});
Flow_Mat = zeros(29, N_p);

for p = 1:N_p
    L = Phase_Ledgers{p};
    c = Phase_Codes{p};

    Pop_29 = 100 * [ ...
        L.Pop_S1_Birth(:); ...
        L.Pop_S2_ECE_4Node(:); ...
        L.Pop_S3_Adol_5Node(:); ...
        L.Pop_S4_Skill(:); ...
        L.Pop_S5_Career(:); ...
        ones(8, 1)];

    Flow_29 = [ ...
        L.S1_Birth_kNZD(:); ...
        L.S2_ECE_4Node_kNZD(:); ...
        L.S3_Adol_5Node_kNZD(:); ...
        L.S4_Skill_kNZD(:); ...
        L.S5_Career_kNZD(:); ...
        L.S6_Fiscal_kNZD(:)];

    Cond_29 = Flow_29 ./ max(1e-9, Pop_29 / 100);
    Cond_29(Pop_29 == 0) = 0;   % guard: a zero-population node must not print Flow x 1e9
    Flow_Mat(:, p) = Flow_29;

    LaneA = zeros(29, 1); LaneB = zeros(29, 1); LaneC = zeros(29, 1); LaneD = zeros(29, 1);
    LaneD(1) = Flow_29(1);
    LaneD(2) = Flow_29(2);
    if isfield(L, 'Whanau_And_Landlord_G1_kNZD'), LaneB(2) = L.Whanau_And_Landlord_G1_kNZD(1); end
    LaneC(3) = Flow_29(3);
    LaneA(4) = 0.63 * Flow_29(4); LaneB(4) = 0.37 * Flow_29(4);

    LaneD(5) = Flow_29(5); LaneC(6:7) = Flow_29(6:7);
    LaneA(8) = 0.60 * Flow_29(8); LaneB(8) = 0.40 * Flow_29(8);

    LaneD(9:10) = Flow_29(9:10); LaneC(11:12) = Flow_29(11:12);
    LaneA(13) = 0.62 * Flow_29(13); LaneB(13) = 0.38 * Flow_29(13);

    LaneD(14) = 0.82 * Flow_29(14); LaneC(14) = 0.18 * Flow_29(14);
    LaneA(15) = 0.29 * Flow_29(15); LaneB(15) = 0.12 * Flow_29(15); LaneC(15) = 0.53 * Flow_29(15); LaneD(15) = 0.06 * Flow_29(15);
    LaneA(16) = 0.37 * Flow_29(16); LaneB(16) = 0.13 * Flow_29(16); LaneC(16) = 0.50 * Flow_29(16);

    % Gate 5 Career Strata (17..21) & Gate 6 Fiscal Accounts (22..29: Exits 1..4 = 22..25, Infra = 26, GST = 27, PAYE = 28, Abroad = 29)
    LaneD([17, 19, 21, 22, 23, 24, 25, 29]) = Flow_29([17, 19, 21, 22, 23, 24, 25, 29]);
    LaneC([18, 20, 26, 27, 28])             = Flow_29([18, 20, 26, 27, 28]);

    T_Fiscal.(sprintf('%s_Pop_Pct', c))               = round(Pop_29, 2);
    T_Fiscal.(sprintf('%s_CohortFlow_kNZD', c))       = round(Flow_29, 2);
    T_Fiscal.(sprintf('%s_CondPerChild_kNZD', c))     = round(Cond_29, 2);
    T_Fiscal.(sprintf('%s_LaneA_PrivCash_kNZD', c))   = round(LaneA, 2);
    T_Fiscal.(sprintf('%s_LaneB_WhanauTime_kNZD', c)) = round(LaneB, 2);
    T_Fiscal.(sprintf('%s_LaneC_PubDev_kNZD', c))     = round(LaneC, 2);
    T_Fiscal.(sprintf('%s_LaneD_RemedRent_kNZD', c))  = round(LaneD, 2);
end

if N_p == 2
    T_Fiscal.Reform_Delta_Flow_kNZD = round(Flow_Mat(:, 2) - Flow_Mat(:, 1), 2);
elseif N_p >= 3
    for p = 2:N_p
        d_col = sprintf('Delta_%s_vs_%s_kNZD', Phase_Codes{p}, Phase_Codes{p-1});
        T_Fiscal.(d_col) = round(Flow_Mat(:, p) - Flow_Mat(:, p-1), 2);
    end
    cum_col = sprintf('Cumul_%s_vs_%s_kNZD', Phase_Codes{N_p}, Phase_Codes{1});
    T_Fiscal.(cum_col) = round(Flow_Mat(:, N_p) - Flow_Mat(:, 1), 2);
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
