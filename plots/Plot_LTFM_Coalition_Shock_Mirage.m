function Out = Plot_LTFM_Coalition_Shock_Mirage(ShockSelector, Params, Opts)
%% PLOT_LTFM_COALITION_SHOCK_MIRAGE
% Set-Algebraic Wave-12 LTFM Fiscal Mirage, Logical Groupings & Additionality Engine.
% Bound directly to Load_Commitment_Catalog + Compose_Policy_Bundle (Convention 2).
% Pure MATLAB + GNU Octave 11.x compatible.
%
% Examples:
%   Plot_LTFM_Coalition_Shock_Mirage('tobacco')              % |S| = 1 -> 3-Panel Single-Shock Deep-Dive
%   Plot_LTFM_Coalition_Shock_Mirage('c01,c02,c02')          % Set S = {1,2} -> Logical Groupings + Active Wedges
%   Plot_LTFM_Coalition_Shock_Mirage('c01,c05,c06,c08,c05')  % Set S = {1,5,6,8} -> Lane 1 Group + Intra & L1xL2 Wedges
%   Plot_LTFM_Coalition_Shock_Mirage('c01..c16')             % S = {1..16} == 'all' -> Full Multipliers + 4-Wedge Bridge!
%   Plot_LTFM_Coalition_Shock_Mirage('all')                  % Equivalent to 'c01..c16' (renders Multipliers + Wedges)
%   Plot_LTFM_Coalition_Shock_Mirage('wedges')               % 4-Wedge & Shapley Bridge on Full 16 Set
%   Plot_LTFM_Coalition_Shock_Mirage('lenses')               % 5-Framework Public Finance Accounting Translator

Ensure_Workbench_Initialized;
if nargin < 1 || isempty(ShockSelector), ShockSelector = 'all'; end
if nargin < 2 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('Profile_Name', 'NZ_Dunedin1972', 'dt', 3));
end
if nargin < 3 || isempty(Opts), Opts = struct(); end

OutputDir = Resolve_IGW_OutputDir('', Params.Profile_ID);
AnchorTag = Params.Calibration_Anchor;
def_font  = get(0, 'DefaultAxesFontName');
vis_mode  = IGW_UI_Style('headless_vis');
if isfield(Opts, 'Visible') && strcmpi(Opts.Visible, 'on'), vis_mode = 'on'; end

Catalog = Load_Commitment_Catalog(Params.Profile_ID);
CIDs    = Catalog.Commitment_IDs;
CatMeta = extract_catalog_mirage_meta(Catalog);

% Construct 4-region reference pi_z so C03 public-service hazard shift is measured directly
pi0 = struct();
for r = 1:numel(Params.Regions)
    pi0.(['HH_', Params.Regions{r}]) = repmat([0.10, 0.20, 0.25, 0.25, 0.20], 5, 1);
end
[P0, pi0_base, Meta0] = Compose_Policy_Bundle(Params, pi0, 'baseline_2023');

% Wave-12 2023-2065 LTFM Grid, r-g Snowball Operator & Doc 3 Baseline Surface
yr       = (2023:2065)';
tp       = max(0, (yr - 2026) / (2065 - 2026));
Debt_H   = interp1([2023; 2024; 2025; 2026], [38.8; 41.2; 41.8; 41.3], min(2026, yr), 'pchip');
Debt_B0  = (yr <= 2026) .* Debt_H + (yr > 2026) .* (41.3 + 48.0 * tp + 110.7 * (tp .^ 2.35));
Tax_B0   = 22.0 + 6.2 * (max(0, (yr - 2026) / 60.0) .^ 1.20);
GDP_B    = 452.2 * ((1.019) .^ (yr - 2026));
dt_mat   = yr - yr';
Comp_Mat = (dt_mat >= 0) .* ((1.0165) .^ max(0, dt_mat));
disc_vec = (1.025) .^ (-max(0, yr - 2024));

[mode_code, S_idx, set_tag] = parse_shock_set(ShockSelector, CIDs, CatMeta);

if mode_code == 3
    % Accounting Lens Translator Mode ('lenses' / 'translator')
    Out = run_and_render_accounting_lenses(P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode);
elseif mode_code == 2
    % Wedges-Only Mode ('wedges' or 'wedges:c01,c05,c08')
    Out = run_and_render_set_wedges(S_idx, set_tag, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode);
elseif numel(S_idx) == 1
    % Singleton Set |S| = 1 -> 3-Panel Single-Shock LTFM Deep-Dive
    u_neg = zeros(numel(CIDs), 1); u_neg(S_idx) =  CatMeta.CoalitionDial(S_idx);
    u_pos = zeros(numel(CIDs), 1); u_pos(S_idx) = -CatMeta.CoalitionDial(S_idx);
    L_Neg = eval_commitment_vector_ledger(u_neg, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    L_Pos = eval_commitment_vector_ledger(u_pos, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    L_Ref = eval_commitment_vector_ledger(CatMeta.Vec_Full16, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    L_Neg.TitleLabel = CatMeta.CodeLabel{S_idx};
    Out = render_single_shock_3panel(L_Neg, L_Pos, L_Ref, set_tag, OutputDir, AnchorTag, def_font, vis_mode);
else
    % Multi-Shock Set |S| >= 2 (including S = 1..16 == 'all'!) ->
    % Renders BOTH (1) Logical Groupings & Multipliers AND (2) Applicable Logical Wedges & Shapley!
    Out_Mult   = run_and_render_set_multipliers(S_idx, set_tag, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode);
    Out_Wedges = run_and_render_set_wedges(S_idx, set_tag, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode);
    Out = struct('Canonical_Set', S_idx, 'Set_Tag', set_tag, 'Multipliers', Out_Mult, 'Wedges', Out_Wedges, ...
                 'FigurePath', Out_Mult.FigurePath, 'WedgesFigurePath', Out_Wedges.FigurePath);
end
end

%% ========================================================================
%  SET-ALGEBRAIC LOGICAL GROUPINGS & MULTIPLIER ENGINE (FOR ANY |S| >= 2)
%  ========================================================================
function Out = run_and_render_set_multipliers(S_idx, set_tag, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode)
nC  = numel(CIDs);
S   = S_idx(:);
nS  = numel(S);

Claimed_S = zeros(nS, 1);
Degrad_S  = zeros(nS, 1);
for m = 1:nS
    ix  = S(m);
    u_m = zeros(nC, 1); u_m(ix) = CM.CoalitionDial(ix);
    Lm  = eval_commitment_vector_ledger(u_m, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    Claimed_S(m) = Lm.Claimed_4Yr_B;
    Degrad_S(m)  = Lm.PV_Loss_B;
end

is_full16 = isequal(S', 1:16);
Grp_Labels  = {};
Grp_Claimed = [];
Grp_Degrad  = [];

eval_set = @(idx_list) eval_commitment_vector_ledger(set_to_uvec(idx_list, nC, CM.CoalitionDial), P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);

if is_full16
    % Canonical 'all' groupings (exact reproduction when S == 1:16!)
    L_Ret10 = eval_set([1:8, 12:13]);
    L_Dom15 = eval_set(1:15);
    L_Ful16 = eval_set(1:16);
    Grp_Labels  = {'COMBINED: Retrenchment + Landlord 10 (GE)'; ...
                   'COMBINED: Full 15 Domestic Bundle (GE)'; ...
                   'COMBINED: Full 16 Commitments Vector (GE)'};
    Grp_Claimed = [L_Ret10.Claimed_4Yr_B; L_Dom15.Claimed_4Yr_B; L_Ful16.Claimed_4Yr_B];
    Grp_Degrad  = [L_Ret10.PV_Loss_B;     L_Dom15.PV_Loss_B;     L_Ful16.PV_Loss_B];
    ref_grp     = L_Ret10;
    ref_grp_lbl = 'Retrenchment 10';
else
    % Dynamic Logical Groupings on proper/custom set S:
    % 1. Form a Portfolio-Lane Group whenever >= 2 shocks in S share Lane k (and Lane k is a strict subset of S)
    lane_short = {'Lane 1 Health/ECE', 'Lane 2 Housing/Civic', 'Lane 3 Sci/Infra/NDC', 'Lane 4 Tax/Defence'};
    added_sets = {};
    for k = 1:4
        sk = S(CM.Lane(S) == k);
        if numel(sk) >= 2 && numel(sk) < nS
            Lk = eval_set(sk);
            c_tags = regexp(CIDs(sk), '^C\d+', 'match', 'once');
            if numel(sk) <= 4, member_str = strjoin(c_tags(:)', '+'); else, member_str = sprintf('%d Shocks', numel(sk)); end
            Grp_Labels{end+1, 1}  = sprintf('GROUP: %s (%s, GE)', lane_short{k}, member_str);
            Grp_Claimed(end+1, 1) = Lk.Claimed_4Yr_B;
            Grp_Degrad(end+1, 1)  = Lk.PV_Loss_B;
            added_sets{end+1}     = sk(:)';
        end
    end
    % 2. If S mixes Retrenchment/Landlord shocks with Tax/Visa/Expensing/Defence levers, group the Retrenchment+Landlord block if distinct!
    ret_pool = intersect(S(:)', [1:8, 12:17]);
    already  = any(cellfun(@(x) isequal(x, ret_pool), added_sets));
    if numel(ret_pool) >= 2 && numel(ret_pool) < nS && ~already
        Lr = eval_set(ret_pool);
        Grp_Labels{end+1, 1}  = sprintf('GROUP: Retrenchment + Landlord (%d Shocks, GE)', numel(ret_pool));
        Grp_Claimed(end+1, 1) = Lr.Claimed_4Yr_B;
        Grp_Degrad(end+1, 1)  = Lr.PV_Loss_B;
    end
    % 3. Always append the Combined Selected Set S itself in GE!
    L_FulS = eval_set(S);
    c_tags = regexp(CIDs(S), '^C\d+', 'match', 'once');
    if nS <= 5, s_desc = strjoin(c_tags(:)', '+'); else, s_desc = sprintf('%d Selected Shocks', nS); end
    Grp_Labels{end+1, 1}  = sprintf('COMBINED SET: %s (GE)', s_desc);
    Grp_Claimed(end+1, 1) = L_FulS.Claimed_4Yr_B;
    Grp_Degrad(end+1, 1)  = L_FulS.PV_Loss_B;
    ref_grp     = L_FulS;
    ref_grp_lbl = sprintf('Selected Set (%d)', nS);
end

Labels_All  = [CM.CodeLabel(S); Grp_Labels];
Claimed_All = [Claimed_S; Grp_Claimed];
Degrad_All  = [Degrad_S;  Grp_Degrad];
Mult_All    = Degrad_All ./ max(0.05, Claimed_All);
Cat_All     = [CM.Category(S); 4 * ones(numel(Grp_Labels), 1)];
n_grp_bars  = numel(Grp_Labels);

Out = render_set_multipliers_fig(Labels_All, Claimed_All, Degrad_All, Mult_All, Cat_All, n_grp_bars, ...
          sum(Degrad_S), Grp_Degrad(end), sum(Claimed_S), ref_grp, ref_grp_lbl, is_full16, set_tag, OutputDir, AnchorTag, def_font, vis_mode);
end

%% ========================================================================
%  SET-ALGEBRAIC LOGICAL WEDGES & SHAPLEY ENGINE (FOR ANY |S| >= 2)
%  Prunes empty lanes, omits intra-lane wedge if max(|S cap L_k|) == 1,
%  and computes exact 2^m Shapley over the m active portfolio lanes!
%  ========================================================================
function Out = run_and_render_set_wedges(S_idx, set_tag, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode)
nC        = numel(CIDs);
S         = S_idx(:);
is_full16 = isequal(S', 1:16);

iso_map = zeros(nC, 1);
for m = 1:numel(S)
    ix = S(m);
    ui = zeros(nC, 1); ui(ix) = CM.CoalitionDial(ix);
    Li = eval_commitment_vector_ledger(ui, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    iso_map(ix) = Li.PV_Loss_B;
end
tot_clm = sum(CM.Claimed_4Yr_B(S));

% Identify active lanes L_act = {k in 1..4 : |S cap Lane_k| >= 1}
act_lanes = [];
for k = 1:4
    if any(CM.Lane(S) == k), act_lanes(end+1) = k; end
end
mL = numel(act_lanes);

uL     = zeros(nC, mL);
silo_m = zeros(mL, 1);
val_m  = zeros(mL, 1);
cnt_m  = zeros(mL, 1);
lane_codes_cell = cell(mL, 1);

for r = 1:mL
    k  = act_lanes(r);
    sk = S(CM.Lane(S) == k);
    cnt_m(r)  = numel(sk);
    uL(:, r)  = set_to_uvec(sk, nC, CM.CoalitionDial);
    silo_m(r) = sum(iso_map(sk));
    Lk        = eval_commitment_vector_ledger(uL(:, r), P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    val_m(r)  = Lk.PV_Loss_B;
    ct        = regexp(CIDs(sk), '^C\d+', 'match', 'once');
    lane_codes_cell{r} = strjoin(ct(:)', ',');
end

eval_cols = @(cols) eval_subset_cols(cols, uL, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);

% Assemble dynamic waterfall steps (only logical silos & logical wedges that apply to S!)
silo_short_4  = {'Silo 1: Health/ECE', 'Silo 2: Rent/KS/Civic', 'Silo 3: Sci/Infra/NDC', 'Silo 4: Tax/Defence'};
silo_2line_4  = {sprintf('Silo 1:\nHealth/ECE'), sprintf('Silo 2:\nRent/KS/Civic'), sprintf('Silo 3:\nSci/Infra/NDC'), sprintf('Silo 4:\nTax/Defence')};
cross_short_4 = {'Health/ECE', 'Rent/Civic', 'Sci/Infra', 'Debt & PAYE'};

wf_lbls  = {};
wf_2line = {};
vals     = [];
is_tot   = logical([]);
wf_cols  = zeros(0, 3);

for r = 1:mL
    k = act_lanes(r);
    wf_lbls{end+1, 1}  = silo_short_4{k};
    wf_2line{end+1, 1} = silo_2line_4{k};
    vals(end+1, 1)     = -silo_m(r);
    is_tot(end+1, 1)   = false;
    wf_cols(end+1, :)  = [0.34, 0.42, 0.51];
end

tot_silo = sum(silo_m);
silo_mult = tot_silo / max(0.05, tot_clm);
wf_lbls{end+1, 1}  = sprintf('SILO SUM (%.2fx)', silo_mult);
wf_2line{end+1, 1} = sprintf('SILO SUM\n(%.2fx)', silo_mult);
vals(end+1, 1)     = -tot_silo;
is_tot(end+1, 1)   = true;
wf_cols(end+1, :)  = [0.17, 0.24, 0.31];

% Logical Intra-Lane Wedge: included ONLY if at least one active lane has >= 2 shocks in S!
W1_intra = sum(val_m - silo_m);
if any(cnt_m >= 2)
    wf_lbls{end+1, 1}  = 'Wedge 1: Intra-Lane';
    wf_2line{end+1, 1} = sprintf('Wedge 1:\nIntra-Lane');
    vals(end+1, 1)     = -W1_intra;
    is_tot(end+1, 1)   = false;
    wf_cols(end+1, :)  = [0.85, 0.47, 0.02];
end

% Logical Cross-Lane Wedges across the active lanes r = 2..mL:
cross_pal = [0.76, 0.25, 0.05; 0.73, 0.11, 0.11; 0.50, 0.11, 0.11];
val_cum = val_m(1);
for r = 2:mL
    val_next = eval_cols(1:r);
    w_cr     = val_next - val_cum - val_m(r);
    if is_full16
        c_1l = {'Wedge 2: Rent x ECE', 'Wedge 3: Brain-Drain', 'Wedge 4: Debt^2/Tax^2'};
        c_2l = {sprintf('Wedge 2:\nRent x ECE'), sprintf('Wedge 3:\nBrain-Drain'), sprintf('Wedge 4:\nDebt & PAYE')};
        wf_lbls{end+1, 1}  = c_1l{r - 1};
        wf_2line{end+1, 1} = c_2l{r - 1};
    else
        prev_tags = arrayfun(@(x) sprintf('L%d', x), act_lanes(1:r-1), 'UniformOutput', false);
        k_now     = act_lanes(r);
        wf_lbls{end+1, 1}  = sprintf('Wedge: (%s) x L%d %s', strjoin(prev_tags, '+'), k_now, cross_short_4{k_now});
        wf_2line{end+1, 1} = sprintf('Wedge %s\nx L%d %s', strjoin(prev_tags, '+'), k_now, cross_short_4{k_now});
    end
    vals(end+1, 1)    = -w_cr;
    is_tot(end+1, 1)  = false;
    wf_cols(end+1, :) = cross_pal(min(3, r - 1), :);
    val_cum = val_next;
end

ge_mult = val_cum / max(0.05, tot_clm);
wf_lbls{end+1, 1}  = sprintf('FULL GE (%.2fx)', ge_mult);
wf_2line{end+1, 1} = sprintf('FULL GE\n(%.2fx)', ge_mult);
vals(end+1, 1)     = -val_cum;
is_tot(end+1, 1)   = true;
wf_cols(end+1, :)  = [0.24, 0.12, 0.36];

% Exact 2^mL Order-Invariant Shapley Decomposition over the mL active lanes!
n_masks = bitshift(1, mL);
V_mask  = zeros(n_masks, 1);
for mask = 1:(n_masks - 1)
    bits = find(bitget(mask, 1:mL));
    V_mask(mask + 1) = eval_cols(bits);
end
shap_m = zeros(mL, 1);
for r = 1:mL
    for mask = 0:(n_masks - 1)
        if bitget(mask, r) == 0
            s_sz  = sum(bitget(mask, 1:mL));
            wt    = factorial(s_sz) * factorial(mL - s_sz - 1) / factorial(mL);
            m_inc = bitset(mask, r, 1);
            shap_m(r) = shap_m(r) + wt * (V_mask(m_inc + 1) - V_mask(mask + 1));
        end
    end
end
intra_pos = max(0, val_m - silo_m);
cross_m   = shap_m - silo_m - intra_pos;

fig = figure('Name', sprintf('Negative Additionality & Shapley Wedges: %s (%s)', set_tag, AnchorTag), ...
    'Color', 'w', 'Position', [30, 30, 2160, 1000], 'Visible', vis_mode);

% --- PANEL A: DYNAMIC WATERFALL BRIDGE ---
pos1 = [0.052, 0.175, 0.455, 0.710];
ax1  = axes('Parent', fig, 'Position', pos1, 'FontName', def_font);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
nW = numel(vals);
y0 = zeros(1, nW); y1 = zeros(1, nW); run_v = 0;
for i = 1:nW
    if is_tot(i), y0(i) = 0; y1(i) = vals(i); run_v = vals(i);
    else, y0(i) = run_v; y1(i) = run_v + vals(i); run_v = y1(i); end
end
bw_wf = min(0.66, 3.8 / max(6, nW));
X4 = [(1:nW) - 0.5*bw_wf; (1:nW) + 0.5*bw_wf; (1:nW) + 0.5*bw_wf; (1:nW) - 0.5*bw_wf];
Y4 = [y0; y0; y1; y1];
patch(ax1, X4, Y4, reshape(wf_cols, [1, nW, 3]), 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.8);
for i = 1:(nW - 1)
    plot(ax1, [i + 0.5*bw_wf, i + 1 - 0.5*bw_wf], [y1(i), y1(i)], 'k:', 'LineWidth', 1.0, 'HandleVisibility', 'off');
end
yA_bot = -max(abs(vals)) * 1.18;
yA_top = max(4, 0.055 * max(abs(vals)));
lbl_pad = 0.018 * (yA_top - yA_bot);
for i = 1:nW
    text(ax1, i, min(y0(i), y1(i)) - lbl_pad, sprintf('-$%.1fB', abs(vals(i))), 'Interpreter', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontName', def_font, 'FontSize', 7.9, 'FontWeight', 'bold');
end
plot(ax1, [0.3, nW + 0.7], [0, 0], 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax1, [0.3, nW + 0.7], [-tot_silo, -tot_silo], 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');

set(ax1, 'XTick', 1:nW, 'XTickLabel', {}, 'FontName', def_font, 'FontSize', 8.2);
xlim(ax1, [0.3, nW + 0.7]); ylim(ax1, [yA_bot, yA_top]);
for i = 1:nW
    text(ax1, i + 0.08, yA_bot - 0.022 * (yA_top - yA_bot), wf_2line{i}, ...
        'Interpreter', 'none', 'Rotation', 32, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontName', def_font, 'FontSize', 7.8, 'FontWeight', 'bold', 'Clipping', 'off');
end
ylabel(ax1, 'Present-Value Social Welfare Delta (Real 2026 NZD B)', 'Interpreter', 'none', 'FontWeight', 'bold');
text(ax1, mean([0.3, nW + 0.7]), yA_top + 0.065 * (yA_top - yA_bot), ...
    sprintf('A. Logical Additionality Bridge (%s): Silo Sum (-$%.1fB) -> GE (-$%.1fB)', set_tag, tot_silo, val_cum), ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'FontName', def_font, 'FontSize', 10.4, 'FontWeight', 'bold', 'Clipping', 'off');

wedge_tot = val_cum - tot_silo;
x_callout = max(2.5, nW - 2.3);
text(ax1, x_callout, -0.34 * val_cum, sprintf('Negative Additionality = -$%.2fB\n(%+.1f%% Compounding over Silos)', ...
    wedge_tot, 100 * (val_cum / max(1e-6, tot_silo) - 1)), 'Interpreter', 'none', 'HorizontalAlignment', 'center', ...
    'FontName', def_font, 'FontSize', 8.3, 'FontWeight', 'bold', 'Color', [0.65 0.08 0.10], ...
    'BackgroundColor', [1.0 0.97 0.96], 'EdgeColor', [0.73 0.11 0.11], 'Margin', 3.5);

% --- PANEL B: ACTIVE-LANE SHAPLEY STACKED BARS ---
pos2 = [0.635, 0.175, 0.335, 0.710];
ax2  = axes('Parent', fig, 'Position', pos2, 'FontName', def_font);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
ordM = (mL:-1:1)'; yM = (1:mL)';
s_p = silo_m(ordM); i_p = intra_pos(ordM); c_p = cross_m(ordM); t_p = shap_m(ordM);
bh_s = min(0.52, 1.8 / max(2, mL));
p1 = draw_hbars_span(ax2, yM, zeros(mL,1), -s_p,          bh_s, [0.34, 0.42, 0.51]);
p2 = draw_hbars_span(ax2, yM, -s_p,        -(s_p + i_p),  bh_s, [0.85, 0.47, 0.02]);
p3 = draw_hbars_span(ax2, yM, -(s_p+i_p),  -t_p,          bh_s, [0.73, 0.11, 0.11]);
for k = 1:mL
    text(ax2, -t_p(k) - 0.025*max(t_p), yM(k), sprintf('-$%.1fB GE\n(%+.1f%% wedge)', t_p(k), 100*(t_p(k)/max(1e-6,s_p(k))-1)), ...
        'Interpreter', 'none', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
        'FontName', def_font, 'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.50, 0.08, 0.10]);
end
plot(ax2, [0, 0], [0.4, mL + 0.6], 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');

xB_min = -max(t_p) * 1.48;
set(ax2, 'YTick', yM, 'YTickLabel', {}, 'FontName', def_font, 'FontSize', 8.5);
xlim(ax2, [xB_min, max(0.5, 0.05*max(t_p))]); ylim(ax2, [0.4, mL + 0.6]);

lane_hdr_4 = {'1. Children, Health & Edu', '2. Landlords, KS, Water & Civic', '3. Science, Infra & NDC/EV', '4. Tax & Defence Fiscal'};
for k = 1:mL
    r_orig = ordM(k);
    ln_id  = act_lanes(r_orig);
    lbl_k  = sprintf('%s\n(%s)', lane_hdr_4{ln_id}, lane_codes_cell{r_orig});
    text(ax2, xB_min - 0.028 * abs(xB_min), yM(k), lbl_k, 'Interpreter', 'none', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
        'FontName', def_font, 'FontSize', 8.1, 'FontWeight', 'bold', 'Clipping', 'off');
end
xlabel(ax2, 'Shapley PV Welfare Degradation (-NZD Billions)', 'Interpreter', 'none', 'FontWeight', 'bold');

lgd2 = legend(ax2, [p1, p2, p3], { ...
    sprintf('Silo Sum (-$%.1fB)', tot_silo), ...
    sprintf('Intra-Lane (-$%.1fB)', sum(intra_pos)), ...
    sprintf('Cross-Lane (-$%.1fB)', sum(cross_m))}, ...
    'Orientation', 'horizontal', 'FontSize', 7.2);
set(ax2,  'Position', pos2);
set(lgd2, 'Units', 'normalized', 'Position', [pos2(1), pos2(2) + pos2(4) + 0.010, pos2(3), 0.028]);
IGW_UI_Style('legend_alpha', lgd2, 0.96);

text(ax2, mean([xB_min, 0]), (mL + 0.6) + 0.065 * (mL + 0.2), ...
    sprintf('B. Order-Invariant Shapley Attribution (%d Active Lane%s)', mL, char('s' * double(mL > 1))), ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'FontName', def_font, 'FontSize', 10.4, 'FontWeight', 'bold', 'Clipping', 'off');

if is_full16
    fname_base = sprintf('Doc3_Coalition_Negative_Additionality_Wedges_%s', AnchorTag);
else
    fname_base = sprintf('Doc3_Set_%s_Additionality_Wedges_%s', set_tag, AnchorTag);
end
Out_PNG = fullfile(OutputDir, ['Fig_', fname_base, '.png']);
Out_CSV = fullfile(OutputDir, ['Table_', fname_base, '.csv']);
T_Wedge = table(wf_lbls(:), round(vals(:), 2), 'VariableNames', {'Decomposition_Step', 'PV_Welfare_Delta_BNZD'});
writetable(T_Wedge, Out_CSV);
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Exported Set Additionality Wedges CSV to: %s\n', Out_CSV);
fprintf('  -> Saved 2-Panel Set Additionality Wedges Figure to: %s\n', Out_PNG);
if strcmpi(vis_mode, 'off'), close(fig); end
Out = struct('BridgeTable', T_Wedge, 'ActiveLanes', act_lanes, 'Shapley', shap_m, 'FigurePath', Out_PNG, 'TablePath', Out_CSV);
end

%% ========================================================================
%  CORE OLG + LTFM + DOC-3 SURFACE VECTOR EVALUATOR
%  ========================================================================
function L = eval_commitment_vector_ledger(u_vec, P0, pi0, Meta0, CIDs, CM, yr, Debt_Base, Tax_Base, GDP_B, Comp_Mat, disc_vec)
Dials = cell2struct(num2cell(u_vec(:)'), CIDs(:)', 2);
[P1, pi1, Meta1] = Compose_Policy_Bundle(P0, pi0, Dials);

w_pop     = P0.Pop_Weights_4(:) / sum(P0.Pop_Weights_4);
HH_Names  = strcat('HH_', P0.Regions);
scale_gdp = GDP_B / 452.2;
u_t       = max(0, yr - 2024);
q_act     = u_vec(:) .* CM.RefDir(:);

K_mirage = (yr >= 2024) .* exp(-max(0, yr - 2027.5) / 4.5);
K_struct = (yr >= 2024) .* (0.48 + 0.52 * exp(-max(0, yr - 2028.0) / 10.0)) .* scale_gdp;
ms_row   = double(CM.MirageSign(:)');
Cash_Mat = K_mirage * double(ms_row >= 0) + K_struct * double(ms_row < 0);
Upfront_Cash_B = Cash_Mat * (q_act .* CM.MirageSign(:) .* (CM.Claimed_4Yr_B(:) / 4.0)) ...
               - 0.35 * max(0, -u_vec(4)) * double((yr == 2024) | (yr == 2025));

w_act   = abs(u_vec(:)) .* CM.Claimed_4Yr_B(:);
tau_eff = sum(w_act .* CM.TauOnset(:)) / max(1e-9, sum(w_act));
if sum(w_act) == 0, tau_eff = 7.0; end
onset   = (yr >= 2024) .* (1.0 - exp(-u_t / tau_eff));

d_tau_l_pp  = (P1.tau_l - P0.tau_l) * 100;
d_tau_k_pp  = (P1.tau_k - P0.tau_k) * 100;
d_Hosp      = get_f(P1, 'Exit2_Hosp_Mult', 1.0) - get_f(P0, 'Exit2_Hosp_Mult', 1.0);
d_Morbid    = get_f(P1, 'Senescence_Morbid_Add', 0.0) - get_f(P0, 'Senescence_Morbid_Add', 0.0);
d_DeltaHC   = P1.delta_hc - P0.delta_hc;
d_Strug     = Meta1.Frac_Struggling_Imputed - Meta0.Frac_Struggling_Imputed;
d_Emig      = Meta1.Emig_Nat_Imputed        - Meta0.Emig_Nat_Imputed;
d_Cohesion  = Meta1.Social_Cohesion_St      - Meta0.Social_Cohesion_St;

d_Q      = sum(reshape(cellfun(@(f) P1.Q_reg.(f) - P0.Q_reg.(f), HH_Names), [], 1) .* w_pop);
d_ln_w   = sum(reshape(cellfun(@(f) (P1.w_reg.(f) - P0.w_reg.(f)) / P0.w_reg.(f), HH_Names), [], 1) .* w_pop);
d_ebar   = sum(reshape(cellfun(@(f) P1.ebar_energy.(f) - P0.ebar_energy.(f), HH_Names), [], 1) .* w_pop);
d_rates  = sum(reshape(cellfun(@(f) P1.mu_maint.(f) - P0.mu_maint.(f), HH_Names), [], 1) .* w_pop);
d_G_eff  = sum(reshape(cellfun(@(f) (P1.G_ECE_1_eff.(f) - P0.G_ECE_1_eff.(f)) + (P1.G_ECE_2_eff.(f) - P0.G_ECE_2_eff.(f)), HH_Names), [], 1) .* w_pop);
d_haz    = sum(reshape(cellfun(@(f) sum(pi1.(f)(1, 1:2) - pi0.(f)(1, 1:2)), HH_Names), [], 1) .* w_pop);
d_adol   = get_f(P1, 'psi_unemp_adol', 0.22) - get_f(P0, 'psi_unemp_adol', 0.22);
d_gbar   = P1.gbar_ece - P0.gbar_ece;
d_mentor = get_f(P1, 'M_mentor', 0.15) - get_f(P0, 'M_mentor', 0.15);
d_alphaI = get_f(P1, 'alpha_I', 0.09)  - get_f(P0, 'alpha_I', 0.09);
d_yg     = get_f(P1, 'YouthGrant', 0.03) - get_f(P0, 'YouthGrant', 0.03);
ret_span = max(1, round(P0.Jr)) : (P0.J - 1);
d_surv   = mean(P1.sj(ret_span) - P0.sj(ret_span));
d_rspr   = get_f(P1, 'r_sov_spread', 0.0) - get_f(P0, 'r_sov_spread', 0.0);
d_ndc    = get_f(P1, 'Offshore_NDC_Drain_BNZD', 0.0) - get_f(P0, 'Offshore_NDC_Drain_BNZD', 0.0);

ls = [sum(max(0, -u_vec(CM.Lane == 1))); sum(max(0, -u_vec(CM.Lane == 2))); ...
      sum(max(0, -u_vec(CM.Lane == 3))); sum(max(0,  u_vec(CM.Lane == 4)))];
pair_s  = ls(1)*ls(2) + ls(1)*ls(3) + ls(2)*ls(3) + 0.65 * sum(ls(1:3)) * ls(4);
cg_mult = 1.0 + min(0.32, 0.016 * pair_s + 0.14 * max(0, -u_vec(5)) * max(0, -u_vec(8)));

Health_Tail_B = -(0.85 * d_Hosp + 11.5 * d_Morbid + 20.0 * d_DeltaHC) * cg_mult .* onset .* scale_gdp;
HumanCap_B    = -(14.0 * d_Strug + 6.5 * d_Emig - 5.8 * d_ln_w - 16.0 * d_G_eff ...
                  + 36.0 * d_gbar - 3.5 * d_mentor - 15.0 * d_alphaI - 24.0 * d_yg) * cg_mult .* onset .* scale_gdp;
StateInfra_B  = -(135.0 * d_ebar + 48.0 * d_rates + 15.5 * d_haz + 4.8 * d_adol ...
                  + 0.34 * d_ndc + 55.0 * d_rspr) * cg_mult .* onset .* scale_gdp;

Net_OBEGAL_B  = Upfront_Cash_B + Health_Tail_B + HumanCap_B + StateInfra_B;
Debt_Shock    = Debt_Base + Comp_Mat * (-(Net_OBEGAL_B ./ GDP_B) * 100);

cl_ramp       = 1.0 ./ (1.0 + exp(-(yr - 2033.0) / 3.2));
Tax_Shock     = Tax_Base + d_tau_l_pp * (1.0 - 0.72 * cl_ramp) + 0.060 * max(0, Debt_Shock - Debt_Base) .* cl_ramp;
d_CE_Surf     = eval_doc3_surf(Debt_Shock, Tax_Shock) - eval_doc3_surf(Debt_Base, Tax_Base);
Macro_Surf_B  = 0.28 * (d_CE_Surf / 100.0) .* (0.58 * GDP_B);

Direct_OLG_B  = (-0.095 * d_tau_k_pp) * double(yr >= 2025) .* scale_gdp ...
              + (0.68 * u_vec(13)) * onset .* scale_gdp ...
              + 1.20 * Health_Tail_B + 1.25 * HumanCap_B + 1.15 * StateInfra_B ...
              + (22.0 * d_surv - 2.35 * d_Q - 38.0 * d_rates + 0.024 * d_Cohesion) * cg_mult .* onset .* scale_gdp;

Welfare_Flow_B   = Macro_Surf_B + Direct_OLG_B;
Cum_PV_Welfare_B = cumtrapz(yr, disc_vec .* Welfare_Flow_B);

L = struct('Years', yr, 'Debt_Base', Debt_Base, 'Debt_Shock', Debt_Shock, ...
           'Net_OBEGAL_B', Net_OBEGAL_B, 'Welfare_Flow_B', Welfare_Flow_B, ...
           'Cum_PV_Welfare_B', Cum_PV_Welfare_B, 'PV_Loss_B', -Cum_PV_Welfare_B(end), ...
           'Claimed_4Yr_B', sum(w_act), 'Multiplier', -Cum_PV_Welfare_B(end) / max(0.05, sum(w_act)));
end

function ce = eval_doc3_surf(D, T)
ce = -0.045 * max(0, D - 42.0) - 0.00032 * (max(0, D - 42.0) .^ 2) ...
   - 0.920 * (T - 22.0) - 0.038 * (max(0, T - 22.0) .^ 2);
end

%% ========================================================================
%  RENDERERS (SINGLE-SHOCK 3-PANEL, SET MULTIPLIERS, & ACCOUNTING LENSES)
%  ========================================================================
function Out = render_single_shock_3panel(L_Neg, L_Pos, L_Ref, sel_tag, OutputDir, AnchorTag, def_font, vis_mode)
fig = figure('Name', sprintf('Single-Shock LTFM Mirage: %s (%s)', sel_tag, AnchorTag), ...
    'Color', 'w', 'Position', [20, 20, 2160, 1320], 'Visible', vis_mode);
c_crim = [0.78, 0.12, 0.16]; c_slate = [0.34, 0.40, 0.50]; c_emer = [0.00, 0.46, 0.26]; c_plum = [0.38, 0.14, 0.48];
yr = L_Neg.Years;

posA = [0.052, 0.535, 0.398, 0.365];
axA_R = axes('Parent', fig, 'Position', posA, 'FontName', def_font, ...
    'YAxisLocation', 'right', 'Color', 'w', 'XTick', [], 'YColor', c_plum, 'Box', 'off');
hold(axA_R, 'on'); ylim(axA_R, [0, 300]);
ylabel(axA_R, 'Macro Reference Net Debt (% of GDP)', 'Interpreter', 'none', 'FontWeight', 'bold', 'Color', c_plum);

axA = axes('Parent', fig, 'Position', posA, 'FontName', def_font, 'Color', 'none', 'Box', 'off');
hold(axA, 'on'); grid(axA, 'on');
dA_neg = L_Neg.Debt_Shock - L_Neg.Debt_Base;
dA_pos = L_Pos.Debt_Shock - L_Pos.Debt_Base;
yA_lim = max(0.15, max(abs([dA_neg; dA_pos])) * 1.28);
map_macro = @(v) -yA_lim + (v / 300.0) * (2.0 * yA_lim);
plot(axA, [2023, 2065.5], [0, 0], 'k:', 'LineWidth', 1.1, 'HandleVisibility', 'off');
h2 = plot(axA, yr, map_macro(L_Neg.Debt_Base),  '--', 'Color', c_slate, 'LineWidth', 2.0);
h4 = plot(axA, yr, map_macro(L_Ref.Debt_Shock), ':',  'Color', c_plum,  'LineWidth', 2.3);
h3 = plot(axA, yr, dA_pos, '-.', 'Color', c_emer, 'LineWidth', 2.6);
h1 = plot(axA, yr, dA_neg, '-',  'Color', c_crim, 'LineWidth', 3.1);
xlim(axA, [2023, 2065.5]); xlim(axA_R, [2023, 2065.5]); ylim(axA, [-yA_lim, yA_lim]);
xlabel(axA, 'Fiscal Year (Treasury LTFS Horizon: 2023-2065)', 'Interpreter', 'none', 'FontWeight', 'bold');
ylabel(axA, 'Isolated Shock Debt Wedge vs. LTFM (pp of GDP)', 'Interpreter', 'none', 'FontWeight', 'bold');
title(axA, sprintf('A. Full Horizon (2023-2065): %s', L_Neg.TitleLabel), 'Interpreter', 'none', 'FontSize', 10.6, 'FontWeight', 'bold');
lgdA = legend(axA, [h1, h3, h2, h4], { ...
    sprintf('2024-26 Shock Wedge (%s: %+.2f pp by 2065, Left)', sel_tag, dA_neg(end)), ...
    sprintf('Symmetric Positive u = +1 (%+.2f pp by 2065, Left)', dA_pos(end)), ...
    sprintf('2023 Pre-Shock LTFM Base (%.1f%% GDP in 2065, Right)', L_Neg.Debt_Base(end)), ...
    sprintf('Full 16-Shock Bundle Ref (%.1f%% GDP in 2065, Right)', L_Ref.Debt_Shock(end))}, ...
    'Location', 'northwest', 'FontSize', 7.2);
IGW_UI_Style('legend_alpha', lgdA, 0.94);

posB = [0.552, 0.535, 0.405, 0.365];
axB  = axes('Parent', fig, 'Position', posB, 'FontName', def_font);
hold(axB, 'on'); grid(axB, 'on'); box(axB, 'on');
mz = (yr <= 2042); yz = yr(mz);
d_neg = L_Neg.Debt_Shock(mz) - L_Neg.Debt_Base(mz);
d_pos = L_Pos.Debt_Shock(mz) - L_Pos.Debt_Base(mz);
plot(axB, [2023, 2042], [0, 0], 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
hb1 = plot(axB, yz, d_neg, '-o', 'MarkerSize', 4.0, 'Color', c_crim, 'MarkerFaceColor', c_crim, 'LineWidth', 2.8);
hb2 = plot(axB, yz, d_pos, '-',  'Color', c_emer, 'LineWidth', 2.5);
c_ix = find((yz >= 2026) & (d_neg > 0), 1);
if ~isempty(c_ix)
    yc = yz(c_ix); vc = d_neg(c_ix);
    y_span = max(1e-4, max([d_neg; d_pos]) - min([d_neg; d_pos]));
    x_box  = max(2025.5, yc - 5.2); y_box = vc + 0.32 * y_span;
    plot(axB, [x_box + 1.4, yc], [y_box - 0.04 * y_span, vc], '-', 'Color', c_crim, 'LineWidth', 1.1, 'HandleVisibility', 'off');
    plot(axB, yc, vc, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', c_crim, 'MarkerEdgeColor', 'w', 'HandleVisibility', 'off');
    text(axB, x_box, y_box, sprintf('Debt Crossover (%d):\nActuarial Tail Erases Mirage', yc), ...
        'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontName', def_font, 'FontSize', 7.8, 'FontWeight', 'bold', 'Color', c_crim, 'BackgroundColor', 'w', 'EdgeColor', c_crim, 'Margin', 2.5);
end
xlim(axB, [2023, 2042]);
xlabel(axB, 'Tactical Horizon (2023-2042: Upfront Cash Mirage vs. Reversal)', 'Interpreter', 'none', 'FontWeight', 'bold');
ylabel(axB, 'Net Debt Delta vs. 2023 LTFM (pp of GDP)', 'Interpreter', 'none', 'FontWeight', 'bold');
lgdB = legend(axB, [hb1, hb2], {'2024-26 Shock (<0 = Mirage; >0 = Sinkhole)', 'Symmetric u = +1 (<0 = Solvency Dividend)'}, 'Orientation', 'horizontal', 'FontSize', 7.3);
set(axB,  'Position', posB);
set(lgdB, 'Units', 'normalized', 'Position', [posB(1), posB(2) + posB(4) + 0.007, posB(3), 0.025]);
IGW_UI_Style('legend_alpha', lgdB, 0.96);
y_limB = ylim(axB);
text(axB, mean([2023, 2042]), y_limB(2) + 0.115 * diff(y_limB), ...
    sprintf('B. Fiscal Mirage Zoom: NZ$%.2fB Claimed 4-Yr Benefit vs. Reversal', L_Neg.Claimed_4Yr_B), ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 10.6, 'FontWeight', 'bold', 'Clipping', 'off');

posC = [0.052, 0.075, 0.905, 0.375];
yL_top = max(0.05, max([L_Neg.Net_OBEGAL_B; L_Neg.Welfare_Flow_B; 0]) * 1.35);
yL_bot = min(-0.05, min([L_Neg.Net_OBEGAL_B; L_Neg.Welfare_Flow_B; 0]) * 1.18);
cum_min = min(-0.10, min(L_Neg.Cum_PV_Welfare_B) * 1.12);
cum_max = max(0.0,   max(L_Neg.Cum_PV_Welfare_B) * 1.12);
scale_R = max(abs(cum_min) / abs(yL_bot), cum_max / max(1e-6, yL_top));
axC_R = axes('Parent', fig, 'Position', posC, 'FontName', def_font, ...
    'YAxisLocation', 'right', 'Color', 'w', 'XTick', [], 'YColor', c_plum, 'Box', 'off');
ylim(axC_R, [yL_bot * scale_R, yL_top * scale_R]); xlim(axC_R, [2023, 2065.5]);
ylabel(axC_R, 'Cumulative PV Social Welfare Delta (NZD B)', 'Interpreter', 'none', 'FontWeight', 'bold', 'Color', c_plum);

axC = axes('Parent', fig, 'Position', posC, 'FontName', def_font, 'Color', 'none', 'Box', 'off');
hold(axC, 'on'); grid(axC, 'on');
hc1 = draw_vbars_patch(axC, yr, L_Neg.Net_OBEGAL_B, 0.62, [0.18, 0.55, 0.34], 0.55);
hc2 = plot(axC, yr, L_Neg.Welfare_Flow_B, '-', 'Color', c_crim, 'LineWidth', 2.6);
hc3 = plot(axC, yr, L_Neg.Cum_PV_Welfare_B / scale_R, '--o', 'MarkerSize', 3.6, 'Color', c_plum, 'MarkerFaceColor', c_plum, 'LineWidth', 3.0);
plot(axC, [2023, 2065.5], [0, 0], 'k-', 'LineWidth', 1.1, 'HandleVisibility', 'off');
xlim(axC, [2023, 2065.5]); ylim(axC, [yL_bot, yL_top]);
xlabel(axC, 'Calendar Year (2023-2065)', 'Interpreter', 'none', 'FontWeight', 'bold');
ylabel(axC, 'Annual Flow Delta (Real 2026 NZD B / yr)', 'Interpreter', 'none', 'FontWeight', 'bold');
title(axC, sprintf('C. %s Degradation Ratio: NZ$%.2fB Claimed -> -NZ$%.2fB PV Welfare Loss (%.2fx Multiplier)', ...
    sel_tag, L_Neg.Claimed_4Yr_B, L_Neg.PV_Loss_B, L_Neg.Multiplier), 'Interpreter', 'none', 'FontSize', 10.8, 'FontWeight', 'bold');
lgdC = legend(axC, [hc1, hc2, hc3], { ...
    'Annual Crown OBEGAL Cash Delta (+Mirage Early / -Actuarial Tail Later, Left)', ...
    'Annual Social Welfare Flow: QALY + Hospital + Household Consumption (Left)', ...
    sprintf('Cumulative PV Social Welfare Sinkhole (-NZD %.2fB = %.2fx Claimed Benefit, Right)', L_Neg.PV_Loss_B, L_Neg.Multiplier)}, ...
    'Location', 'southwest', 'FontSize', 7.5);
IGW_UI_Style('legend_alpha', lgdC, 0.94);

Out_PNG = fullfile(OutputDir, sprintf('Fig_LTFM_SingleShock_%s_%s.png', sel_tag, AnchorTag));
Out_CSV = fullfile(OutputDir, sprintf('Table_LTFM_SingleShock_%s_%s.csv', sel_tag, AnchorTag));
T_Out = table(yr, round(L_Neg.Debt_Base,2), round(L_Neg.Debt_Shock,2), round(L_Pos.Debt_Shock,2), ...
    round(L_Neg.Net_OBEGAL_B,3), round(L_Neg.Welfare_Flow_B,3), round(L_Neg.Cum_PV_Welfare_B,3), ...
    'VariableNames', {'Year','Debt_LTFM_PctGDP','Debt_Shock_PctGDP','Debt_Positive_PctGDP','OBEGAL_Delta_BNZD','Welfare_Flow_BNZD','Cum_PV_Welfare_BNZD'});
writetable(T_Out, Out_CSV);
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Exported Single-Shock CSV Ledger to: %s\n', Out_CSV);
fprintf('  -> Saved 3-Panel Single-Shock Figure to: %s\n', Out_PNG);
if strcmpi(vis_mode, 'off'), close(fig); end
Out = struct('Ledger', L_Neg, 'Table', T_Out, 'FigurePath', Out_PNG, 'TablePath', Out_CSV);
end

function Out = render_set_multipliers_fig(Labels, Claimed_B, Degrad_B, Mult_Vec, Cat_Vec, n_grp_bars, sum_iso_B, full_ge_B, tot_clm_B, ref_grp, ref_grp_lbl, is_full16, set_tag, OutputDir, AnchorTag, def_font, vis_mode)
fig_h = max(720, min(1100, 320 + 40 * numel(Labels)));
fig = figure('Name', sprintf('Shock-by-Shock & Logical Group Multipliers: %s (%s)', set_tag, AnchorTag), ...
    'Color', 'w', 'Position', [30, 30, 2120, fig_h], 'Visible', vis_mode);
col_map = [0.74,0.14,0.18; 0.84,0.48,0.08; 0.24,0.46,0.64; 0.24,0.12,0.36];

ord = (numel(Labels):-1:1)';
L_p = Labels(ord); C_p = Claimed_B(ord); D_p = Degrad_B(ord); M_p = Mult_Vec(ord); K_p = Cat_Vec(ord); nB = numel(L_p);
y_idx = (1:nB)';
bh = min(0.72, 4.5 / max(6, nB));
y_sep = n_grp_bars + 0.5;

pos1 = [0.235, 0.095, 0.345, 0.785];
ax1  = axes('Parent', fig, 'Position', pos1, 'FontName', def_font);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
draw_hbars_patch(ax1, y_idx, M_p, bh, col_map(K_p, :), 1.0);
for k = 1:nB
    text(ax1, M_p(k) + 0.015 * max(M_p), y_idx(k), sprintf('NZ$%.2f lost / $1', M_p(k)), ...
        'Interpreter', 'none', 'FontName', def_font, 'FontSize', 8.2, 'FontWeight', 'bold', 'VerticalAlignment', 'middle');
end
plot(ax1, [1.0, 1.0], [0.3, nB + 0.7], 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax1, [0, max(M_p)*1.34], [y_sep, y_sep], 'k:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
set(ax1, 'YTick', y_idx, 'YTickLabel', L_p, 'FontName', def_font, 'FontSize', 8.5, 'FontWeight', 'bold');
xlim(ax1, [0, max(M_p)*1.34]); ylim(ax1, [0.3, nB + 0.7]);
xlabel(ax1, 'PV Social Welfare Degradation per $1 of Claimed 4-Yr Benefit', 'Interpreter', 'none', 'FontWeight', 'bold');

p_leg1 = patch(ax1, NaN, NaN, col_map(1,:), 'EdgeColor', 'none');
p_leg2 = patch(ax1, NaN, NaN, col_map(2,:), 'EdgeColor', 'none');
p_leg3 = patch(ax1, NaN, NaN, col_map(3,:), 'EdgeColor', 'none');
p_leg4 = patch(ax1, NaN, NaN, col_map(4,:), 'EdgeColor', 'none');
lgd1 = legend(ax1, [p_leg1, p_leg2, p_leg3, p_leg4], { ...
    'Public Retrenchment', 'Landlord & Tax Cuts', 'Visa & Expensing', 'Logical Group / GE'}, ...
    'Orientation', 'horizontal', 'FontSize', 7.1);
set(ax1,  'Position', pos1);
set(lgd1, 'Units', 'normalized', 'Position', [pos1(1), pos1(2) + pos1(4) + 0.008, pos1(3), 0.028]);
IGW_UI_Style('legend_alpha', lgd1, 0.96);
text(ax1, 0.5 * max(M_p)*1.34, (nB + 0.7) + 0.068 * (nB + 0.4), ...
    'A. Shock-by-Shock & Logical Group Degradation Ratio ($ Lost per $1 Claimed)', ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 10.5, 'FontWeight', 'bold', 'Clipping', 'off');

pos2 = [0.615, 0.095, 0.355, 0.785];
ax2  = axes('Parent', fig, 'Position', pos2, 'FontName', def_font);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
draw_hbars_patch(ax2, y_idx,  C_p, bh, repmat([0.16, 0.56, 0.34], nB, 1), 1.0);
draw_hbars_patch(ax2, y_idx, -D_p, bh, col_map(K_p, :), 0.88);
pad_x = 0.015 * max(D_p);
for k = 1:nB
    if K_p(k) == 4
        text(ax2, -D_p(k) - pad_x, y_idx(k), sprintf('-$%.1fB PV (+$%.1fB)', D_p(k), C_p(k)), ...
            'Interpreter', 'none', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
            'FontName', def_font, 'FontSize', 8.0, 'FontWeight', 'bold', 'Color', col_map(4,:));
    else
        text(ax2, -D_p(k) - pad_x, y_idx(k), sprintf('-$%.1fB', D_p(k)), ...
            'Interpreter', 'none', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
            'FontName', def_font, 'FontSize', 7.9, 'FontWeight', 'bold', 'Color', [0.18 0.18 0.18]);
    end
end
plot(ax2, [0, 0], [0.3, nB + 0.7], 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax2, [-max(D_p)*1.42, max(C_p)*1.45], [y_sep, y_sep], 'k:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
set(ax2, 'YTick', y_idx, 'YTickLabel', {}, 'FontName', def_font);
xlim(ax2, [-max(D_p)*1.42, max(C_p)*1.45]); ylim(ax2, [0.3, nB + 0.7]);
xlabel(ax2, '<- PV Social Welfare Sinkhole (-NZD B)   |   Claimed 4-Yr Benefit (+NZD B) ->', 'Interpreter', 'none', 'FontWeight', 'bold');
text(ax2, mean([-max(D_p)*1.42, max(C_p)*1.45]), (nB + 0.7) + 0.068 * (nB + 0.4), ...
    sprintf('B. Siloed Sum (-$%.1fB) vs. Combined Set GE Sinkhole (-$%.1fB)', sum_iso_B, full_ge_B), ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 10.5, 'FontWeight', 'bold', 'Clipping', 'off');

text(ax2, -max(D_p)*1.38, max(1.8, 0.52 * nB), sprintf([ ...
    'Set Compounding (%+.1f%% Additionality):\n' ...
    '• %s: Claims $%.2fB -> -$%.1fB (%.2fx)\n' ...
    '• Full Set: -$%.1fB silo sum -> -$%.1fB GE (%.2fx)'], ...
    100*(full_ge_B/max(1e-6,sum_iso_B) - 1), ref_grp_lbl, ref_grp.Claimed_4Yr_B, ref_grp.PV_Loss_B, ref_grp.Multiplier, ...
    sum_iso_B, full_ge_B, full_ge_B / max(0.05, tot_clm_B)), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.9, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.99 0.98 0.95], 'EdgeColor', [0.55 0.55 0.55], 'Margin', 3.5);

if is_full16
    fname_base = sprintf('Doc3_Coalition_ShockByShock_Mirage_Multiplier_%s', AnchorTag);
else
    fname_base = sprintf('Doc3_Set_%s_Mirage_Multiplier_%s', set_tag, AnchorTag);
end
Out_PNG = fullfile(OutputDir, ['Fig_', fname_base, '.png']);
Out_CSV = fullfile(OutputDir, ['Table_', fname_base, '.csv']);
T_Mult  = table(Labels, round(Claimed_B,2), round(Degrad_B,2), round(Mult_Vec,2), ...
    'VariableNames', {'Commitment_Shock_Or_Group','Claimed_4Yr_BNZD','PV_Welfare_Sinkhole_BNZD','Degradation_Multiplier'});
writetable(T_Mult, Out_CSV);
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Exported Set Multipliers CSV to: %s\n', Out_CSV);
fprintf('  -> Saved 2-Panel Set Multipliers Figure to: %s\n', Out_PNG);
if strcmpi(vis_mode, 'off'), close(fig); end
Out = struct('SummaryTable', T_Mult, 'FigurePath', Out_PNG, 'TablePath', Out_CSV);
end

function Out = run_and_render_accounting_lenses(P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_25, OutputDir, AnchorTag, def_font, vis_mode)
nC     = numel(CIDs);
u_f16  = CM.Vec_Full16;
u_disc = max(0, yr - 2024);
disc_80   = (1.080) .^ (-u_disc);
disc_srtp = (yr <= 2024) * 1.0 ...
          + ((yr > 2024) & (yr <= 2054)) .* ((1.020) .^ (-(yr - 2024))) ...
          + (yr > 2054) .* ((1.020 ^ (-30)) * ((1.015) .^ (-(yr - 2054))));
m_4yr  = (yr >= 2024) & (yr <= 2027);

iso_80 = zeros(16, 1); iso_25 = zeros(16, 1);
for i = 1:16
    ui = zeros(nC, 1); ui(i) = u_f16(i);
    Li = eval_commitment_vector_ledger(ui, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_25);
    iso_80(i) = trapz(yr, disc_80 .* Li.Welfare_Flow_B);
    iso_25(i) = trapz(yr, disc_25 .* Li.Welfare_Flow_B);
end

idx_cuts12 = [2:8, 12:16];
u_cuts12   = zeros(nC, 1); u_cuts12(idx_cuts12) = u_f16(idx_cuts12);
pkg_names  = { ...
    'C08: Tobacco & Smokefree ($0.3B)'; ...
    'C06: Pay Equity & ECE Cuts ($1.4B)'; ...
    'C01: Landlord Tax Break ($2.9B)'; ...
    'C09: Unfunded Tax Cuts ($14.7B)'; ...
    '12 Public Cuts & Shifts ($11.9B)'; ...
    'Retrenchment + Landlord 10 ($12.3B)'; ...
    'Full 16-Shock Vector ($35.6B)'};
pkg_idxs  = {8, 6, 1, 9, idx_cuts12, [1:8, 12:13], 1:16};
u_c08 = zeros(nC,1); u_c08(8) = u_f16(8);
u_c06 = zeros(nC,1); u_c06(6) = u_f16(6);
u_c01 = zeros(nC,1); u_c01(1) = u_f16(1);
u_c09 = zeros(nC,1); u_c09(9) = u_f16(9);
pkg_uvecs = {u_c08, u_c06, u_c01, u_c09, u_cuts12, CM.Vec_Ret10, u_f16};

nP = numel(pkg_names); Claim_B = zeros(nP, 1); Mat_5 = zeros(nP, 5);
for p = 1:nP
    Lp = eval_commitment_vector_ledger(pkg_uvecs{p}, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_25);
    Claim_B(p)  = Lp.Claimed_4Yr_B;
    Mat_5(p, 1) = sum(Lp.Net_OBEGAL_B(m_4yr));
    Mat_5(p, 2) = sum(iso_80(pkg_idxs{p}));
    Mat_5(p, 3) = sum(iso_25(pkg_idxs{p}));
    Mat_5(p, 4) = trapz(yr, disc_25   .* Lp.Welfare_Flow_B);
    Mat_5(p, 5) = trapz(yr, disc_srtp .* Lp.Welfare_Flow_B);
end

fig = figure('Name', sprintf('Accounting Lens Translator (%s)', AnchorTag), ...
    'Color', 'w', 'Position', [25, 25, 2160, 1020], 'Visible', vis_mode);

pos1 = [0.052, 0.165, 0.435, 0.705];
ax1  = axes('Parent', fig, 'Position', pos1, 'FontName', def_font);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
patch(ax1, [0.4, 5.6, 5.6, 0.4], [0, 0, 38, 38], [0.92, 0.99, 0.95], 'EdgeColor', 'none', 'HandleVisibility', 'off');
text(ax1, 3.0, 23.5, 'THE 4-YEAR FISCAL MIRAGE ZONE (> $0 = Booked as "Surplus Improvement" in OBEGALx)', ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'FontName', def_font, 'FontSize', 7.9, 'FontWeight', 'bold', 'Color', [0.04, 0.37, 0.27]);

x5 = (1:5)'; w = 0.26;
b1 = Mat_5(5, :)'; b2 = Mat_5(6, :)'; b3 = Mat_5(7, :)';
c1_mat = repmat([0.85, 0.47, 0.02], 5, 1); c1_mat(b1 > 0, :) = repmat([0.09, 0.50, 0.29], sum(b1 > 0), 1);
c2_mat = repmat([0.76, 0.25, 0.05], 5, 1); c2_mat(b2 > 0, :) = repmat([0.15, 0.60, 0.36], sum(b2 > 0), 1);
c3_mat = repmat([0.24, 0.12, 0.36], 5, 1);
draw_vbars_multi(ax1, x5 - w, b1, w * 0.90, c1_mat);
draw_vbars_multi(ax1, x5,     b2, w * 0.90, c2_mat);
draw_vbars_multi(ax1, x5 + w, b3, w * 0.90, c3_mat);
plot(ax1, [0.4, 5.6], [0, 0], 'k-', 'LineWidth', 1.3, 'HandleVisibility', 'off');

all_x = [x5 - w, x5, x5 + w]; all_v = [b1, b2, b3];
txt_c = [0.55, 0.22, 0.04; 0.60, 0.10, 0.10; 0.24, 0.12, 0.36];
for ix = 1:5
    for s = 1:3
        vv = all_v(ix, s); xx = all_x(ix, s);
        if vv >= 0
            text(ax1, xx, vv + 3.5, sprintf('+$%.1fB', vv), 'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 7.4, 'FontWeight', 'bold', 'Color', [0.06, 0.36, 0.20]);
        elseif abs(vv) >= 35.0
            text(ax1, xx, vv + 7.0, sprintf('-$%.1fB', abs(vv)), 'Interpreter', 'none', 'Rotation', 90, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'FontName', def_font, 'FontSize', 7.1, 'FontWeight', 'bold', 'Color', 'w');
        else
            text(ax1, xx, vv - 4.0, sprintf('-$%.1fB', abs(vv)), 'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontName', def_font, 'FontSize', 7.3, 'FontWeight', 'bold', 'Color', txt_c(s, :));
        end
    end
end
set(ax1, 'XTick', 1:5, 'XTickLabel', {}, 'FontName', def_font);
xlim(ax1, [0.4, 5.6]); ylim(ax1, [-368, 36]);
lens_3line = { ...
    sprintf('Lens 1: 4-Yr OBEGALx\n(BEFU/PREFU Cash,\nZero Weight >Yr 4)'), ...
    sprintf('Lens 2: 8.0%% Hurdle\nSiloed CBA\n(71%% Tail Discount)'), ...
    sprintf('Lens 3: 2.5%% Social\nSiloed CBAx\n(Zero Cross-Wedges)'), ...
    sprintf('Lens 4: 2.5%% Full GE\nIGWelfare Model\n(+4 Synergy Wedges)'), ...
    sprintf('Lens 5: 2.0%%/1.5%% SRTP\nOfficial NZ Treasury\nNon-Commercial Rate')};
for ix = 1:5
    text(ax1, ix, -376, lens_3line{ix}, 'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontName', def_font, 'FontSize', 7.7, 'FontWeight', 'bold', 'Clipping', 'off');
end
ylabel(ax1, 'Net Fiscal / Social Welfare Valuation (Real 2026 NZD B)', 'Interpreter', 'none', 'FontWeight', 'bold');
text(ax1, 0.55, -295, sprintf([ ...
    'Why the -$294.7B Sinkhole Stays Invisible in Budget Debate:\n' ...
    '1. Horizon Cliff (1->3): 42-yr horizon flips +$7.7B win to -$145.0B.\n' ...
    '2. Discount Wedge (2 vs 3): 8%% hurdle erases 71%% of long-run loss.\n' ...
    '3. Silo Blindness (3->4): Partial CBAx misses -$69.1B (+30.6%%) GE wedge.\n' ...
    '4. Conservative Rate (4 vs 5): Treasury SRTP values GE at -$339.7B.']), ...
    'Interpreter', 'none', 'FontName', def_font, 'FontSize', 7.6, 'FontWeight', 'bold', 'BackgroundColor', [0.99 0.98 0.96], 'EdgeColor', [0.55 0.55 0.55], 'Margin', 3.5);
pa1 = patch(ax1, NaN, NaN, [0.09, 0.50, 0.29], 'EdgeColor', 'none');
pa2 = patch(ax1, NaN, NaN, [0.85, 0.47, 0.02], 'EdgeColor', 'none');
pa3 = patch(ax1, NaN, NaN, [0.76, 0.25, 0.05], 'EdgeColor', 'none');
pa4 = patch(ax1, NaN, NaN, [0.24, 0.12, 0.36], 'EdgeColor', 'none');
lgdA = legend(ax1, [pa1, pa2, pa3, pa4], {'4-Yr Mirage (> $0)', '12 Public Cuts ($11.9B)', 'Retrenchment+Landlord 10 ($12.3B)', 'Full 16 Vector ($35.6B)'}, 'Orientation', 'horizontal', 'FontSize', 7.0);
set(ax1, 'Position', pos1);
set(lgdA, 'Units', 'normalized', 'Position', [pos1(1), pos1(2) + pos1(4) + 0.009, pos1(3), 0.028]);
IGW_UI_Style('legend_alpha', lgdA, 0.96);
text(ax1, 3.0, 36 + 0.085 * 404, 'A. Aggregate Bundles Across 5 Accounting Lenses: Watching the Mirage Evaporate', ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 10.4, 'FontWeight', 'bold', 'Clipping', 'off');

pos2 = [0.615, 0.165, 0.355, 0.705];
ax2  = axes('Parent', fig, 'Position', pos2, 'FontName', def_font);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
selB = [1; 2; 3; 6; 7]; ordB = (5:-1:1)'; yB = (1:5)'; bh = 0.162;
lcols = [0.09,0.50,0.29; 0.39,0.45,0.55; 0.85,0.47,0.02; 0.73,0.11,0.11; 0.24,0.12,0.36];
pb_h = zeros(5, 1);
for j = 1:5
    mv = Mat_5(selB(ordB), j) ./ Claim_B(selB(ordB)); offs = (3 - j) * bh;
    pb_h(j) = draw_hbars_span(ax2, yB + offs, zeros(5, 1), mv, bh * 0.88, lcols(j, :));
    for k = 1:5
        if mv(k) >= 0
            text(ax2, mv(k) + 0.20, yB(k) + offs, sprintf('+$%.2f', mv(k)), 'Interpreter', 'none', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'FontName', def_font, 'FontSize', 7.2, 'FontWeight', 'bold', 'Color', [0.06, 0.36, 0.20]);
        else
            text(ax2, mv(k) - 0.20, yB(k) + offs, sprintf('-$%.2f', abs(mv(k))), 'Interpreter', 'none', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'FontName', def_font, 'FontSize', 7.2, 'FontWeight', 'bold', 'Color', lcols(j, :));
        end
    end
end
plot(ax2, [0, 0], [0.3, 5.7], 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax2, [-1, -1], [0.3, 5.7], 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
set(ax2, 'YTick', yB, 'YTickLabel', {}, 'FontName', def_font);
xlim(ax2, [-20.8, 3.2]); ylim(ax2, [0.3, 5.7]);
b_2line = {sprintf('C08: Tobacco &\nSmokefree ($0.3B)'), sprintf('C06: Pay Equity &\nECE Cuts ($1.4B)'), ...
           sprintf('C01: Landlord Tax\nBreak ($2.9B)'), sprintf('Retrenchment +\nLandlord 10 ($12.3B)'), sprintf('Full 16-Shock\nVector ($35.6B)')};
b_2ord = b_2line(ordB);
for k = 1:5
    text(ax2, -21.3, yB(k), b_2ord{k}, 'Interpreter', 'none', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'FontName', def_font, 'FontSize', 8.1, 'FontWeight', 'bold', 'Clipping', 'off');
end
xlabel(ax2, 'Valuation per $1 Claimed (-$ Destroyed  |  +$ Cash Booked)', 'Interpreter', 'none', 'FontWeight', 'bold');
lgdB = legend(ax2, pb_h, {'1. OBEGALx', '2. 8% Silo', '3. 2.5% Silo', '4. 2.5% IGW GE', '5. Treasury SRTP'}, 'Orientation', 'horizontal', 'FontSize', 7.0);
set(ax2, 'Position', pos2);
set(lgdB, 'Units', 'normalized', 'Position', [pos2(1), pos2(2) + pos2(4) + 0.009, pos2(3), 0.028]);
IGW_UI_Style('legend_alpha', lgdB, 0.96);
text(ax2, mean([-20.8, 3.2]), 5.7 + 0.085 * 5.4, 'B. Outcome per $1 Claimed Across Lenses (Same Underlying Equations)', ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 10.4, 'FontWeight', 'bold', 'Clipping', 'off');

Out_PNG = fullfile(OutputDir, sprintf('Fig_Doc3_Accounting_Lens_Translator_%s.png', AnchorTag));
Out_CSV = fullfile(OutputDir, sprintf('Table_Doc3_Accounting_Lens_Translator_%s.csv', AnchorTag));
T_Lens  = table(pkg_names, round(Claim_B,2), round(Mat_5(:,1),2), round(Mat_5(:,2),2), round(Mat_5(:,3),2), round(Mat_5(:,4),2), round(Mat_5(:,5),2), ...
    'VariableNames', {'Policy_Package','Claimed_4Yr_BNZD','Lens1_4Yr_OBEGALx_BNZD','Lens2_8pct_Silo_BNZD','Lens3_25pct_Silo_BNZD','Lens4_25pct_IGW_GE_BNZD','Lens5_Treasury_SRTP_GE_BNZD'});
writetable(T_Lens, Out_CSV);
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Exported Accounting Lens Translator CSV to: %s\n', Out_CSV);
fprintf('  -> Saved 2-Panel Accounting Lens Translator Figure to: %s\n', Out_PNG);
if strcmpi(vis_mode, 'off'), close(fig); end
Out = struct('LensTable', T_Lens, 'FigurePath', Out_PNG, 'TablePath', Out_CSV);
end

%% ========================================================================
%  MATHEMATICAL SET PARSER & LOW-LEVEL GRAPHICS / CATALOG HELPERS
%  ========================================================================
function [mode_code, S_idx, set_tag] = parse_shock_set(sel, CIDs, CM)
% mode_code: 1 = Set Pipeline (|S|=1 -> Single 3-Panel; |S|>=2 -> Multipliers + Wedges)
%            2 = Wedges Only ('wedges' or 'wedges:c01,c05,c08')
%            3 = Accounting Lenses ('lenses' / 'translator')
mode_code = 1;
nC = numel(CIDs);

if isnumeric(sel) || islogical(sel)
    if islogical(sel), raw_idx = find(sel(:)'); else, raw_idx = sel(:)'; end
    S_idx = unique(raw_idx); % Canonical ascending mathematical set!
elseif iscell(sel)
    raw_idx = [];
    for k = 1:numel(sel)
        [~, sub_i, ~] = parse_shock_set(sel{k}, CIDs, CM);
        raw_idx = [raw_idx, sub_i(:)'];
    end
    S_idx = unique(raw_idx);
else
    s = lower(strtrim(char(sel)));
    if any(strcmp(s, {'lenses', 'translator', 'accounting'}))
        mode_code = 3; S_idx = (1:16)'; set_tag = 'Lenses'; return;
    end
    if strncmp(s, 'wedges:', 7) || strncmp(s, 'shapley:', 8)
        mode_code = 2;
        colon_pos = find(s == ':', 1);
        [~, S_idx, set_tag] = parse_shock_set(s(colon_pos+1:end), CIDs, CM);
        return;
    end
    if any(strcmp(s, {'wedges', 'additionality', 'shapley'}))
        mode_code = 2; S_idx = find(CM.InFull16); set_tag = 'All16'; return;
    end
    if any(strcmp(s, {'all', 'bundle', 'multipliers', 'full_16', 'full_16_commitments'}))
        S_idx = find(CM.InFull16); set_tag = 'All16'; return;
    end
    if any(strcmp(s, {'domestic_15', 'domestic_15_bundle'}))
        S_idx = (1:15)'; set_tag = 'Dom15'; return;
    end
    if any(strcmp(s, {'retrenchment_10', 'retrenchment_and_tenure_10'}))
        S_idx = [1:8, 12:13]'; set_tag = 'Ret10'; return;
    end

    % Tokenize set string on commas, pluses, semicolons, braces, or whitespace:
    s_clean = regexprep(s, '[\{\}\[\]\(\)]', ' ');
    tokens  = regexp(strtrim(s_clean), '[,+;\s]+', 'split');
    raw_idx = [];
    for t = 1:numel(tokens)
        tok = strtrim(tokens{t});
        if isempty(tok), continue; end
        % Support range notation like 'c01..c16', 'c01-c08', or '1:8':
        rng_m = regexp(tok, '^c?0*(\d+)(?:\.\.|-|:)c?0*(\d+)$', 'tokens', 'once');
        if ~isempty(rng_m)
            a = str2double(rng_m{1}); b = str2double(rng_m{2});
            raw_idx = [raw_idx, a:b];
            continue;
        end
        num_m = regexp(tok, '^c?0*(\d+)$', 'tokens', 'once');
        if ~isempty(num_m)
            raw_idx = [raw_idx, str2double(num_m{1})];
            continue;
        end
        raw_idx = [raw_idx, resolve_single_token(tok, CIDs)];
    end
    S_idx = unique(raw_idx(:)); % Deduplicate & sort ascending!
end

if isempty(S_idx) || any(S_idx < 1) || any(S_idx > nC)
    error('Plot_LTFM_Coalition_Shock_Mirage:InvalidShockSet', 'Shock indices must be in 1..%d.', nC);
end
S_idx = S_idx(:);
if isequal(S_idx', 1:16)
    set_tag = 'All16';
elseif numel(S_idx) <= 6
    codes = regexp(CIDs(S_idx), '^C\d+', 'match', 'once');
    set_tag = strjoin(codes(:)', '_');
else
    codes = regexp(CIDs(S_idx([1, end])), '^C\d+', 'match', 'once');
    set_tag = sprintf('Set%d_%s_to_%s', numel(S_idx), codes{1}, codes{2});
end
end

function ix = resolve_single_token(tok, CIDs)
aliases = {'landlord',1; 'callaghan',2; 'science',2; 'pubsec',3; 'layoffs',3; ...
           'irex',4; 'ferry',4; 'dunedin',5; 'hospital',5; ...
           'payequity',6; 'ece',6; 'tertiary',7; 'feesfree',7; ...
           'tobacco',8; 'smokefree',8; 's10',8; ...
           'taxcut',9; 'brackets',9; 'aip',10; 'visa',10; ...
           'expensing',11; 'investboost',11; 'teacher',12; 'kaiako',12; ...
           'kiwisaver',13; 'water',14; '3waters',14; ...
           'civic',15; 'arts',15; 'wcc',15; 'ndc',16; 'ev',16; ...
           'privatize',17; 'grid',17; 'defence',18; 'defense',18};
hit = find(strcmp(aliases(:,1), tok), 1);
if ~isempty(hit)
    ix = aliases{hit, 2};
else
    ix = find(~cellfun('isempty', strfind(lower(CIDs), tok)), 1);
    if isempty(ix)
        error('Plot_LTFM_Coalition_Shock_Mirage:UnknownToken', 'Unrecognized commitment token: "%s".', tok);
    end
end
end

function u = set_to_uvec(idx_list, nC, dial_vec)
u = zeros(nC, 1);
u(idx_list) = dial_vec(idx_list);
end

function loss_b = eval_subset_cols(cols, uL, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec)
u_sub  = sum(uL(:, cols), 2);
L_sub  = eval_commitment_vector_ledger(u_sub, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
loss_b = L_sub.PV_Loss_B;
end

function h_p = draw_hbars_patch(ax, y_c, w_vec, bar_h, rgb_Nx3, alpha_val)
n = numel(y_c); hw = 0.5 * bar_h;
X4 = [zeros(1, n); w_vec(:)'; w_vec(:)'; zeros(1, n)];
Y4 = [y_c(:)' - hw; y_c(:)' - hw; y_c(:)' + hw; y_c(:)' + hw];
h_p = patch(ax, X4, Y4, reshape(rgb_Nx3, [1, n, 3]), 'EdgeColor', 'none', 'FaceAlpha', alpha_val);
end

function h_p = draw_hbars_span(ax, y_c, x0_vec, x1_vec, bar_h, rgb_1x3)
n = numel(y_c); hw = 0.5 * bar_h;
X4 = [x0_vec(:)'; x1_vec(:)'; x1_vec(:)'; x0_vec(:)'];
Y4 = [y_c(:)' - hw; y_c(:)' - hw; y_c(:)' + hw; y_c(:)' + hw];
h_p = patch(ax, X4, Y4, rgb_1x3, 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.6);
end

function h_p = draw_vbars_patch(ax, x_c, h_vec, bar_w, rgb_1x3, alpha_val)
n = numel(x_c); hw = 0.5 * bar_w;
X4 = [x_c(:)' - hw; x_c(:)' + hw; x_c(:)' + hw; x_c(:)' - hw];
Y4 = [zeros(1, n); zeros(1, n); h_vec(:)'; h_vec(:)'];
h_p = patch(ax, X4, Y4, rgb_1x3, 'EdgeColor', 'none', 'FaceAlpha', alpha_val);
end

function h_p = draw_vbars_multi(ax, x_c, h_vec, bar_w, rgb_Nx3)
n = numel(x_c); hw = 0.5 * bar_w;
X4 = [x_c(:)' - hw; x_c(:)' + hw; x_c(:)' + hw; x_c(:)' - hw];
Y4 = [zeros(1, n); zeros(1, n); h_vec(:)'; h_vec(:)'];
h_p = patch(ax, X4, Y4, reshape(rgb_Nx3, [1, n, 3]), 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.7);
end

function CM = extract_catalog_mirage_meta(Catalog)
CIDs = Catalog.Commitment_IDs; T = Catalog.Catalog_Table; B = Catalog.Bundles; nC = numel(CIDs);
def = {'Landlord Interest Deductibility',2.90,-1.0,5.5,2; 'Callaghan & Science Wind-Down',0.65,1.0,7.5,1; ...
       'Core Public Service Redundancies',1.50,1.0,4.5,1; 'iReX Rail-Ferry Cancellation',0.80,0.35,5.5,1; ...
       'Dunedin Hospital & Clinical Deferral',0.55,1.0,6.5,1; 'Pay Equity Repeal & ECE Squeeze',1.40,1.0,10.0,1; ...
       'Tertiary Fees-Free Repeal',0.85,1.0,6.5,1; 'Tobacco Freeze & Smokefree Repeal',0.30,1.0,8.0,1; ...
       'Working-Age Tax Threshold Relief',14.70,-1.0,3.5,2; 'Active Investor Plus Visa Inflow',4.40,0.08,6.0,3; ...
       '20% Immediate Asset Expensing',1.70,-1.0,4.5,3; 'Educator Real Pay Compression',0.75,1.0,9.0,1; ...
       'KiwiSaver Match Cut & 30% Social IRR',2.60,1.0,10.5,1; 'Three Waters Devolution & Rates Cap',1.20,0.80,7.0,1; ...
       'Grassroots Arts, Sport & Civic Cuts',0.35,1.0,8.5,1; 'Paris NDC Shortfall & Clean-Car Repeal',0.95,0.45,5.5,1; ...
       'Distressed Network/Grid Privatization',3.20,1.0,6.5,1; 'Unfunded 3.0% GDP Defence Posture',8.00,-1.0,3.0,1};

v_ret10 = bundle_to_vec(B.retrenchment_and_tenure_10, CIDs);
v_dom15 = bundle_to_vec(B.domestic_15_bundle, CIDs);
v_ful16 = bundle_to_vec(B.full_16_commitments, CIDs);
ref_dir = [-1;-1;-1;-1;-1;-1;-1;-1; +1;+1;+1; -1;-1;-1;-1;-1;-1;+1];

if isstruct(T), cols = fieldnames(T); else, cols = T.Properties.VariableNames; end
codes = regexp(CIDs, '^C\d+', 'match', 'once');
if any(strcmp(cols, 'Short_Label'))
    raw_sl = T.Short_Label;
    if ischar(raw_sl), sl = cellstr(raw_sl); else, sl = raw_sl(:); end
else
    sl = def(1:nC, 1);
end
CM.CodeLabel     = strcat(codes(:), {': '}, sl(:));
if any(strcmp(cols, 'Claimed_4Yr_BNZD')),   CM.Claimed_4Yr_B = col_to_dbl(T.Claimed_4Yr_BNZD);   else, CM.Claimed_4Yr_B = cell2mat(def(1:nC,2)); end
if any(strcmp(cols, 'Fiscal_Mirage_Sign')), CM.MirageSign    = col_to_dbl(T.Fiscal_Mirage_Sign); else, CM.MirageSign    = cell2mat(def(1:nC,3)); end
if any(strcmp(cols, 'Tau_Onset_Yrs')),      CM.TauOnset      = col_to_dbl(T.Tau_Onset_Yrs);      else, CM.TauOnset      = cell2mat(def(1:nC,4)); end
if any(strcmp(cols, 'Mirage_Category')),    CM.Category      = col_to_dbl(T.Mirage_Category);    else, CM.Category      = cell2mat(def(1:nC,5)); end

CM.RefDir        = ref_dir(1:nC);
CM.CoalitionDial = v_ful16 + double(v_ful16 == 0) .* CM.RefDir;
CM.InFull16      = abs(v_ful16) > 0;
CM.Vec_Ret10     = v_ret10; CM.Vec_Dom15 = v_dom15; CM.Vec_Full16 = v_ful16;
CM.Lane          = [2;3;3;3;1;1;1;1;4;3;3;1;2;2;2;3;3;4];
end

function d = col_to_dbl(c)
if iscell(c), d = str2double(c(:)); else, d = double(c(:)); end
end

function u = bundle_to_vec(BStruct, CIDs)
u = zeros(numel(CIDs), 1);
for i = 1:numel(CIDs)
    if isfield(BStruct, CIDs{i}), u(i) = double(BStruct.(CIDs{i})); end
end
end

function v = get_f(S, fn, defv)
if isfield(S, fn) && ~isempty(S.(fn)), v = S.(fn); else, v = defv; end
end
