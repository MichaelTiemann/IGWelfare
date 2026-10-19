%% PLOT_CHILDFATES_SSANKEY.M
% Plots simulated intergenerational child fate flows (by region or national)
% using Zhaoxu Liu / slandarer's SSankey class (FEX #128679).
%
% Compatible with:
%   - 3-Region or 4-Region workspaces (Regions = {'Rural','Small','Large','Auckland'})
%   - 4D Compact or 5D UpgradeB (experienceasset = 1) state spaces
%   - Baseline (StatDist_Base / Policy_Base) or Reform (StatDist_GE_Endo / Policy_GE_Exo)

%% 1. SELECT REGION & SCENARIO FROM WORKSPACE
% Set Target_Region to 'Auckland', 'Rural', 'Small', 'Large', 'Urban', or 'National'
Target_Region = 'Auckland';
Calibration_Anchor = 'Dunedin_22'; % 'Dunedin_22' (~17.9% baseline) or 'MetroSqueeze_GUiNZ' (~36.6% baseline)
Plot_Mode     = 'Single'; % 'Single' = Detailed figure for Target_Region
% 'Tiled_All_Regions' = 2x2 grid across all regions

% Automatically detect active distribution and policy structs in workspace
if exist('StatDist_Base', 'var') && exist('Policy_Base', 'var')
    Dist_Sim = StatDist_Base;
    Pol_Sim  = Policy_Base;
    P_Sim    = Params_Base;
    Diag_Sim = IG_Diag_Base;
    Scenario_Label = 'Baseline Steady State (SS0)';
elseif exist('StationaryDist', 'var') && exist('Policy', 'var')
    Dist_Sim = StationaryDist;
    Pol_Sim  = Policy;
    P_Sim    = Params;
    Diag_Sim = IG_Diagnostics;
    Scenario_Label = 'Current Workspace Simulation';
else
    error('Run NZ_4Region_Master_UpgradeB.m or WelfareDecomposition_4Region.m first.');
end

if strcmpi(Plot_Mode, 'Single')
    figure('Name', ['Child Fates Sankey: ', Target_Region, ' (', Scenario_Label, ')'], ...
        'Color', 'w', 'Position', [80, 80, 1280, 720]);
    ax = axes('Position', [0.03, 0.06, 0.94, 0.86]);
    Build_And_Render_Regional_Sankey(ax, Target_Region, Dist_Sim, Pol_Sim, ...
        P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, Regions, Scenario_Label);
else
    figure('Name', ['4-Region Child Fates Sankey Comparison (', Scenario_Label, ')'], ...
        'Color', 'w', 'Position', [40, 40, 1550, 860]);
    tlo = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    for r_idx = 1:length(Regions)
        ax = nexttile(tlo);
        Build_And_Render_Regional_Sankey(ax, Regions{r_idx}, Dist_Sim, Pol_Sim, ...
            P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, Regions, Scenario_Label);
    end
end


%% ========================================================================
%  LOCAL HELPER: EXTRACT SIMULATED FLOWS & CALL slandarer's SSankey
%  ========================================================================
function Build_And_Render_Regional_Sankey(ax, reg_choice, Dist_Sim, Pol_Sim, ...
    P_Sim, Diag_Sim, n_d, n_a, n_z, d_grid, a_grid, Regions, Scenario_Label)

N_reg = length(Regions);
if strcmpi(reg_choice, 'National')
    reg_list    = Regions;
    pop_weights = P_Sim.PTypeWeights(1:N_reg) / sum(P_Sim.PTypeWeights(1:N_reg));
else
    reg_list    = {reg_choice};
    pop_weights = 1.0;
end

% Unpack grids from first household PType
ref_type = ['HH_', Regions{1}];
n_a1     = n_a.(ref_type)(1);
n_h      = n_a.(ref_type)(2);
n_z1     = n_z.(ref_type);
a_vec    = a_grid.(ref_type)(1:n_a1);
h_vec    = a_grid.(ref_type)(n_a1+1 : n_a1+n_h);

% Detect whether model is 5D UpgradeB (ic is d1) or 4D Compact (ic is d3)
is_5D = (length(n_a.(ref_type)) == 3);
if is_5D
    n_ic   = n_d.(ref_type)(1);
    ic_vec = d_grid.(ref_type)(1:n_ic);
else
    n_ic   = n_d.(ref_type)(3);
    ic_vec = d_grid.(ref_type)(n_d.(ref_type)(1)+n_d.(ref_type)(2)+1 : end);
end

% Fertile parent age indices (adapts to dt = 5, 3, or 2)
if isfield(P_Sim, 'j_child_s1_start')
    fertile_j = P_Sim.j_child_s1_start : P_Sim.j_child_s2_end;
else
    fertile_j = [3, 4];
end

% Fallback parameters if UpgradeB vs Compact naming differs
rho_hc   = getfield_def(P_Sim, 'rho_hc_ig',   0.53);
gamma_ic = getfield_def(P_Sim, 'gamma_ic',    0.24);
G_ece    = getfield_def(P_Sim, 'G_ece',       getfield_def(P_Sim, 'G_ece_stage1', 0.045));
sig_hc   = getfield_def(P_Sim, 'sigma_hc_ig', 0.18);

% Accumulators for joint transition probabilities (normalized to 100 children)
% Stage 1 (2 nodes): 1 = Material Hardship (a_p < 0.05 Q_k), 2 = Secure Buffer
% Stage 2 (3 nodes): 1 = Unmitigated Corner (ic = 0), 2 = Moderate ECE+ic, 3 = High Wraparound
% Stage 3 (3 nodes): 1 = Stunted (h1-h2), 2 = Core (h3-h5), 3 = Thriving (h6-h7)
Flow_S1_to_S2 = zeros(2, 3);
Flow_S2_to_S3 = zeros(3, 3);

% Extract decision grid for ic (3rd decision variable in n_d = [4, 3, 7])
n_ic   = n_d.(ref_type)(3);
ic_vec = d_grid.(ref_type)(n_d.(ref_type)(1)+n_d.(ref_type)(2)+1 : end);

for r_i = 1:length(reg_list)
    reg     = reg_list{r_i};
    w_reg   = pop_weights(r_i);
    hh_type = ['HH_', reg];

    Dist_k  = Dist_Sim.(hh_type);
    Pol_k   = Pol_Sim.(hh_type);
    Q_house = P_Sim.Q_reg.(hh_type);

    reg_F12 = zeros(2, 3);
    reg_F23 = zeros(3, 3);
    tot_p   = 0;

    for jf = fertile_j
        for ia = 1:n_a1
            % Stage 1: Material Hardship & Housing Squeeze vs. Secure Buffer
            is_hardship = (a_vec(ia) < 0.08 * Q_house);
            s1_idx = 1 * is_hardship + 2 * (~is_hardship);

            for ih = 1:n_h
                for iz = 1:n_z1
                    mass_p = Dist_k(ia, ih, iz, jf);
                    if mass_p > 1e-12
                        tot_p    = tot_p + mass_p;
                        d_ic_idx = Pol_k(3, ia, ih, iz, jf);
                        ic_val   = ic_vec(max(1, min(length(ic_vec), d_ic_idx)));

                        % Stage 2: Early Childhood Investment Gate
                        if ic_val <= 1e-5
                            s2_idx = 1; % 3. Unmitigated Corner (ic = 0)
                        elseif ic_val <= 0.35 * max(ic_vec)
                            s2_idx = 2; % 4. Public ECE + Moderate Inv
                        else
                            s2_idx = 3; % 5. High Wraparound + Parental Inv
                        end
                        reg_F12(s1_idx, s2_idx) = reg_F12(s1_idx, s2_idx) + mass_p;

                        % Stage 2 -> Stage 3: Unified Anchored Skill Formation (Section 5.1, Eq Q_h)
                        % Choose 'Dunedin_22' (Caspi et al. 2016 22% benchmark)
                        %     or 'MetroSqueeze_GUiNZ' (GUiNZ / DPMC 30-37% After-Housing-Cost & Crowding squeeze)

                        % 1. Effective early investment relative to cohort benchmark (Ferriere et al. floor g_bar = 0.02)
                        inv_gap = log(ic_val + G_ece + 0.02) - log(0.20 + 0.05 + 0.02);

                        % 2. Regional housing crowding & material hardship penalty (-psi_crowd * ln(Q_k) * I(Hardship))
                        if strcmpi(Calibration_Anchor, 'Dunedin_22')
                            % Anchored to Caspi et al. (2016) Dunedin Study: ~21-22% baseline stunted share in Auckland
                            crowd_penalty = 0.14 * log(max(1.0, Q_house)) * is_hardship;
                            grid_anchor   = +0.025;
                        else
                            % 'MetroSqueeze_GUiNZ': Incorporates full AHC housing-cost crowd-out (Newman & Holupka 2014;
                            % DPMC 34-37% OTI>30% child housing stress; GUiNZ 37% damp/mould exposure) -> ~36.6% in Auckland
                            crowd_penalty = 0.18 * log(max(1.0, Q_house)) * is_hardship;
                            grid_anchor   = -0.140;
                        end

                        % 3. Expected log child adult skill (Section 5.1, Eq Q_h)
                        log_h_mean = rho_hc * log(h_vec(ih)) + gamma_ic * inv_gap - crowd_penalty + grid_anchor;

                        trans_probs = normpdf(log(h_vec), log_h_mean, sig_hc);
                        trans_probs = trans_probs / sum(trans_probs);

                        reg_F23(s2_idx, 1) = reg_F23(s2_idx, 1) + mass_p * sum(trans_probs(1:2)); % h1-h2
                        reg_F23(s2_idx, 2) = reg_F23(s2_idx, 2) + mass_p * sum(trans_probs(3:5)); % h3-h5
                        reg_F23(s2_idx, 3) = reg_F23(s2_idx, 3) + mass_p * sum(trans_probs(6:7)); % h6-h7
                    end
                end
            end
        end
    end

    reg_F12 = reg_F12 / max(1e-12, tot_p);
    reg_F23 = reg_F23 / max(1e-12, tot_p);

    % If Diag_Sim.StuntedShare.(reg) is present and positive, lock Stage 3 column sums to it
    if isfield(Diag_Sim, 'StuntedShare') && isfield(Diag_Sim.StuntedShare, reg) ...
            && Diag_Sim.StuntedShare.(reg) > 0.01
        target_st = Diag_Sim.StuntedShare.(reg);
        col_s     = sum(reg_F23, 1);
        if col_s(1) > 1e-8
            scale_st = target_st / col_s(1);
            reg_F23(:, 1) = reg_F23(:, 1) * scale_st;
            % Re-normalize each row so Stage 2 node outflows match Stage 2 node inflows
            row_t = sum(reg_F12, 1)';
            for rr = 1:3
                if sum(reg_F23(rr, :)) > 1e-8
                    reg_F23(rr, 2:3) = reg_F23(rr, 2:3) * ...
                        max(0, (row_t(rr) - reg_F23(rr, 1))) / max(1e-8, sum(reg_F23(rr, 2:3)));
                end
            end
        end
    end

    Flow_S1_to_S2 = Flow_S1_to_S2 + 100 * w_reg * reg_F12;
    Flow_S2_to_S3 = Flow_S2_to_S3 + 100 * w_reg * reg_F23;
end

% Stage 3 -> Stage 4: Map Skill Tiers to the 4 Priced Fiscal Exits, Domestic Retention & Abroad Brain Drain
% Extract emigration probabilities by skill tier if present in Diag_Sim
if isfield(Diag_Sim, 'Emig_By_SkillTier')
    emig_stunted  = mean(Diag_Sim.Emig_By_SkillTier(1:2));
    emig_core     = mean(Diag_Sim.Emig_By_SkillTier(3:5));
    emig_thriving = mean(Diag_Sim.Emig_By_SkillTier(6:7));
else
    emig_stunted  = 0.04;
    emig_core     = 0.11;
    emig_thriving = 0.22; % Positive selection brain drain to Australia/OECD
end

% 6 Target Fates in Stage 4:
%   1: Exit 1 - State Care Entry (Single-Yr Govt Cost)
%   2: Exit 2 - Avoidable Hospitalisations (Single-Yr Govt Cost)
%   3: Exit 3 - Lower Lifetime Income (Multi-Decade Stream)
%   4: Exit 4 - Benefit & Justice Contact (57-81% Fiscal Burden)
%   5: Fate 5 - Retained NZ Thriving / Secure Adulthood
%   6: Fate 6 - Emigrated Abroad (Age 20-35 Brain Drain)
Flow_S3_to_S4 = zeros(3, 6);
S3_mass       = sum(Flow_S2_to_S3, 1); % [Stunted_Mass, Core_Mass, Thriving_Mass]

% Stunted Tier (h1-h2) -> Drives 57-81% of acute fiscal exits
m_st = S3_mass(1);
Flow_S3_to_S4(1, 1) = m_st * 0.20;                   % Exit 1: State Care
Flow_S3_to_S4(1, 2) = m_st * 0.24;                   % Exit 2: Avoidable Hospitalisations
Flow_S3_to_S4(1, 3) = m_st * 0.26;                   % Exit 3: Lower Lifetime Income
Flow_S3_to_S4(1, 4) = m_st * (0.26 - emig_stunted);  % Exit 4: Benefit & Justice Contact
Flow_S3_to_S4(1, 5) = m_st * 0.04;                   % Residual resilient adulthood
Flow_S3_to_S4(1, 6) = m_st * emig_stunted;           % Emigrated Abroad

% Core Skill Tier (h3-h5) -> Primarily domestic working adulthood + moderate income/health risk + emigration
m_co = S3_mass(2);
Flow_S3_to_S4(2, 2) = m_co * 0.05;                   % Residual hospitalisations
Flow_S3_to_S4(2, 3) = m_co * 0.12;                   % Moderate/lower income stream
Flow_S3_to_S4(2, 4) = m_co * 0.05;                   % Episodic benefit receipt
Flow_S3_to_S4(2, 5) = m_co * (0.78 - emig_core);     % Retained NZ Secure Adulthood
Flow_S3_to_S4(2, 6) = m_co * emig_core;              % Emigrated Abroad

% Thriving Skill Tier (h6-h7) -> High earnings retention vs. Positive-Selection Brain Drain Abroad
m_th = S3_mass(3);
Flow_S3_to_S4(3, 5) = m_th * (1.00 - emig_thriving); % Retained NZ High-Skill Adulthood
Flow_S3_to_S4(3, 6) = m_th * emig_thriving;          % High-Skill Brain Drain to Australia/OECD

%% BUILD LINK LIST FOR slandarer's SSankey
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

% Append Stage 1 -> Stage 2 links
for i = 1:2
    for j = 1:3
        if Flow_S1_to_S2(i, j) > 0.01   % <-- changed from 0.15
            row_k = row_k + 1;
            links{row_k, 1} = Nodes_S1{i};
            links{row_k, 2} = Nodes_S2{j};
            links{row_k, 3} = Flow_S1_to_S2(i, j);
        end
    end
end

% Append Stage 2 -> Stage 3 links
for i = 1:3
    for j = 1:3
        if Flow_S2_to_S3(i, j) > 0.01   % <-- changed from 0.15
            row_k = row_k + 1;
            links{row_k, 1} = Nodes_S2{i};
            links{row_k, 2} = Nodes_S3{j};
            links{row_k, 3} = Flow_S2_to_S3(i, j);
        end
    end
end

% Append Stage 3 -> Stage 4 links
for i = 1:3
    for j = 1:6
        if Flow_S3_to_S4(i, j) > 0.01   % <-- changed from 0.15
            row_k = row_k + 1;
            links{row_k, 1} = Nodes_S3{i};
            links{row_k, 2} = Nodes_S4{j};
            links{row_k, 3} = Flow_S3_to_S4(i, j);
        end
    end
end

%% INSTANTIATE & RENDER slandarer's SSankey OBJECT
axes(ax); hold(ax, 'on');
SK = SSankey(links(:, 1), links(:, 2), links(:, 3));

% Configure SSankey aesthetics (compatible with slandarer v1.x - 2026 releases)
SK.RenderingMethod = 'interp';   % Smooth gradient ribbons between stages
SK.Align           = 'center';
SK.LabelLocation   = 'right';
SK.BlockScale      = 0.14;       % Vertical padding between blocks
SK.Sep             = 0.06;

% Assign cohesive 14-node color palette (Crimson/Amber for hardship & exits; Teal/Navy for thriving; Purple for Abroad)
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

% Use sans-serif font inside SSankey before drawing
if isprop(SK, 'FontName')
    SK.FontName = 'Helvetica'; % or 'Arial' / 'Calibri'
end

% Draw the Sankey diagram
SK.draw();

% 1. Flip Y-axis back to 'normal' so Material Hardship & Adverse Exits are on the BOTTOM
%    and Secure Buffer & Thriving Adulthood are on the TOP
set(ax, 'YDir', 'normal');

% 2. Expand X-limits to the right so Stage-4 right-hand labels never clip
curr_xlim = xlim(ax);
xlim(ax, [curr_xlim(1), curr_xlim(2) + 1.05]);

% 3. Enforce Sans-Serif font across all rendered text & title objects
set(ax, 'FontName', 'Helvetica');
set(findall(ax, 'Type', 'text'), 'FontName', 'Helvetica', 'FontSize', 10);

% Format title with simulated regional stunted share and house price Q_k
if strcmpi(reg_choice, 'National')
    title(ax, sprintf('National Child Fates Sankey (%s) | Stunted h1-h2: %.1f%%', ...
        Scenario_Label, S3_mass(1)), 'FontName', 'Helvetica', 'FontSize', 13, 'FontWeight', 'bold');
else
    Q_val = P_Sim.Q_reg.(['HH_', reg_choice]);
    title(ax, sprintf('%s Child Fates (Q = %.2f) | Stunted h1-h2: %.1f%% | Thriving h6-h7: %.1f%%', ...
        reg_choice, Q_val, S3_mass(1), S3_mass(3)), 'FontName', 'Helvetica', 'FontSize', 12, 'FontWeight', 'bold');
end
axis(ax, 'off');
end

function val = getfield_def(S, fname, default_val)
if isfield(S, fname)
    val = S.(fname);
else
    val = default_val;
end

end
