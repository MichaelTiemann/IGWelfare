function Out = Plot_LTFM_Coalition_Shock_Mirage(ShockSelector, Params, Opts)
%% PLOT_LTFM_COALITION_SHOCK_MIRAGE
% Unified 5-Regime Signed Set-Algebraic LTFM Fiscal Mirage, Stern-Kick & Additionality Engine.
% Synchronized bit-for-bit with igwelfare_policy_mirage_explorer.html & commitment_catalog.csv.
%
% Examples (MATLAB & GNU Octave 11.x):
%   Plot_LTFM_Coalition_Shock_Mirage('tobacco')                  % Single shock C08 vs. 0.38x +Reform kink
%   Plot_LTFM_Coalition_Shock_Mirage('+c02')                     % Single +Reform: Full R&D + Lab-Plant 12y Stern-Kick
%   Plot_LTFM_Coalition_Shock_Mirage('+c18')                     % Single +Reform: 1.2% Defence Onshore Clean Stern-Kick
%   Plot_LTFM_Coalition_Shock_Mirage('ret10, +c06, +c15, +c16')  % Mixed Shock + Positive Reform Set!
%   Plot_LTFM_Coalition_Shock_Mirage('reforms13')                % 13 Public + Tenure Positive Reforms
%   Plot_LTFM_Coalition_Shock_Mirage('all')                      % Canonical 2024 Full-16 Shocks (Multipliers + Wedges)
%   Plot_LTFM_Coalition_Shock_Mirage('wedges')                   % 4-Wedge & 2^m Shapley Bridge
%   Plot_LTFM_Coalition_Shock_Mirage('lenses')                   % 5-Framework Public-Finance Accounting Translator

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

pi0 = struct();
for r = 1:numel(Params.Regions)
    pi0.(['HH_', Params.Regions{r}]) = repmat([0.10, 0.20, 0.25, 0.25, 0.20], 5, 1);
end
[P0, pi0_base, Meta0] = Compose_Policy_Bundle(Params, pi0, 'baseline_2023');

yr       = (2023:2065)';
tp       = max(0, (yr - 2026) / (2065 - 2026));
Debt_H   = interp1([2023; 2024; 2025; 2026], [38.8; 41.2; 41.8; 41.3], min(2026, yr), 'pchip');
Debt_B0  = (yr <= 2026) .* Debt_H + (yr > 2026) .* (41.3 + 48.0 * tp + 110.7 * (tp .^ 2.35));
Tax_B0   = 22.0 + 6.2 * (max(0, (yr - 2026) / 60.0) .^ 1.20);
GDP_B    = 452.2 * ((1.019) .^ (yr - 2026));
dt_mat   = yr - yr';
Comp_Mat = (dt_mat >= 0) .* ((1.0165) .^ max(0, dt_mat));
disc_vec = (1.025) .^ (-max(0, yr - 2024));

[mode_code, item_state, S_idx, set_tag] = parse_shock_set(ShockSelector, CIDs, CatMeta);

if mode_code == 3
    Out = run_and_render_accounting_lenses(item_state, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode);
elseif mode_code == 2
    Out = run_and_render_set_wedges(item_state, S_idx, set_tag, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode);
elseif numel(S_idx) == 1
    ix = S_idx(1);
    st_act = item_state;
    st_mir = -item_state;
    L_Act = eval_commitment_vector_ledger(state_to_uvec(st_act, CatMeta), P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    L_Mir = eval_commitment_vector_ledger(state_to_uvec(st_mir, CatMeta), P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    L_Ref = eval_commitment_vector_ledger(CatMeta.Vec_Full16, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    if item_state(ix) == 1
        L_Act.TitleLabel = CatMeta.ReformCodeLabel{ix};
    else
        L_Act.TitleLabel = CatMeta.CodeLabel{ix};
    end
    Out = render_single_shock_3panel(L_Act, L_Mir, L_Ref, item_state(ix), set_tag, OutputDir, AnchorTag, def_font, vis_mode);
else
    Out_Mult   = run_and_render_set_multipliers(item_state, S_idx, set_tag, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode);
    Out_Wedges = run_and_render_set_wedges(item_state, S_idx, set_tag, P0, pi0_base, Meta0, CIDs, CatMeta, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode);
    Out = struct('Canonical_Set', S_idx, 'Item_State', item_state, 'Set_Tag', set_tag, ...
                 'Multipliers', Out_Mult, 'Wedges', Out_Wedges, ...
                 'FigurePath', Out_Mult.FigurePath, 'WedgesFigurePath', Out_Wedges.FigurePath);
end
end

%% ========================================================================
%  SIGNED SET-ALGEBRAIC LOGICAL GROUPINGS & MULTIPLIER ENGINE
%  ========================================================================
function Out = run_and_render_set_multipliers(item_state, S_idx, set_tag, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode)
nC = numel(CIDs);
S  = S_idx(:);
nS = numel(S);

Claimed_S = zeros(nS, 1);
Val_S     = zeros(nS, 1);
Item_Lbls = cell(nS, 1);
for m = 1:nS
    ix = S(m);
    st_m = zeros(nC, 1); st_m(ix) = item_state(ix);
    Lm = eval_commitment_vector_ledger(state_to_uvec(st_m, CM), P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    Claimed_S(m) = Lm.Claimed_4Yr_B;
    Val_S(m)     = Lm.PV_Delta_B;
    if item_state(ix) == 1
        Item_Lbls{m} = CM.ReformCodeLabel{ix};
    else
        Item_Lbls{m} = CM.CodeLabel{ix};
    end
end

is_full_shk16 = isequal(S', 1:16) && all(item_state(1:16) == -1);
is_full_ref16 = isequal(S', 1:16) && all(item_state(1:16) == +1);

eval_sub = @(idx_list) eval_commitment_vector_ledger(subset_state_to_uvec(idx_list, item_state, CM), P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);

Grp_Labels = {}; Grp_Claimed = []; Grp_Val = [];
if is_full_shk16 || is_full_ref16
    pfx = 'COMBINED';
    if is_full_ref16, pfx = '+REFORM BUNDLE'; end
    L_R10 = eval_sub([1:8, 12:13]);
    L_D15 = eval_sub(1:15);
    L_F16 = eval_sub(1:16);
    Grp_Labels  = {sprintf('%s: Retrenchment/Tenure 10 (GE)', pfx); ...
                   sprintf('%s: Full 15 Domestic Bundle (GE)', pfx); ...
                   sprintf('%s: Full 16 Commitments Vector (GE)', pfx)};
    Grp_Claimed = [L_R10.Claimed_4Yr_B; L_D15.Claimed_4Yr_B; L_F16.Claimed_4Yr_B];
    Grp_Val     = [L_R10.PV_Delta_B;    L_D15.PV_Delta_B;    L_F16.PV_Delta_B];
    ref_grp     = L_R10;
    ref_grp_lbl = 'Retrenchment/Tenure 10';
else
    lane_short = {'Lane 1 Health/ECE', 'Lane 2 Housing/Civic', 'Lane 3 Sci/Infra/NDC', 'Lane 4 Tax/Defence'};
    added_sets = {};
    for k = 1:4
        sk = S(CM.Lane(S) == k);
        if numel(sk) >= 2 && numel(sk) < nS
            Lk = eval_sub(sk);
            c_tags = format_signed_codes(sk, item_state, CIDs);
            if numel(sk) <= 4, member_str = strjoin(c_tags(:)', '+'); else, member_str = sprintf('%d Items', numel(sk)); end
            Grp_Labels{end+1, 1}  = sprintf('GROUP: %s (%s, GE)', lane_short{k}, member_str);
            Grp_Claimed(end+1, 1) = Lk.Claimed_4Yr_B;
            Grp_Val(end+1, 1)     = Lk.PV_Delta_B;
            added_sets{end+1}     = sk(:)';
        end
    end
    ret_pool = intersect(S(:)', [1:8, 12:17]);
    already  = any(cellfun(@(x) isequal(x, ret_pool), added_sets));
    if numel(ret_pool) >= 2 && numel(ret_pool) < nS && ~already
        Lr = eval_sub(ret_pool);
        Grp_Labels{end+1, 1}  = sprintf('GROUP: Public & Tenure (%d Items, GE)', numel(ret_pool));
        Grp_Claimed(end+1, 1) = Lr.Claimed_4Yr_B;
        Grp_Val(end+1, 1)     = Lr.PV_Delta_B;
    end
    L_FulS = eval_sub(S);
    c_tags = format_signed_codes(S, item_state, CIDs);
    if nS <= 5, s_desc = strjoin(c_tags(:)', ','); else, s_desc = sprintf('%d Active Commitments', nS); end
    Grp_Labels{end+1, 1}  = sprintf('COMBINED SET: %s (GE)', s_desc);
    Grp_Claimed(end+1, 1) = L_FulS.Claimed_4Yr_B;
    Grp_Val(end+1, 1)     = L_FulS.PV_Delta_B;
    ref_grp     = L_FulS;
    ref_grp_lbl = sprintf('Selected Set (%d)', nS);
end

Labels_All  = [Item_Lbls; Grp_Labels];
Claimed_All = [Claimed_S; Grp_Claimed];
Val_All     = [Val_S;     Grp_Val];
Mult_All    = Val_All ./ max(0.05, Claimed_All);
Cat_All     = [CM.Category(S); 4 * ones(numel(Grp_Labels), 1)];

Out = render_set_multipliers_fig(Labels_All, Claimed_All, Val_All, Mult_All, Cat_All, numel(Grp_Labels), ...
          sum(Val_S), Grp_Val(end), sum(Claimed_S), ref_grp, ref_grp_lbl, is_full_shk16, set_tag, OutputDir, AnchorTag, def_font, vis_mode);
end

%% ========================================================================
%  SIGNED SET-ALGEBRAIC LOGICAL WEDGES & 2^m SHAPLEY ENGINE
%  ========================================================================
function Out = run_and_render_set_wedges(item_state, S_idx, set_tag, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec, OutputDir, AnchorTag, def_font, vis_mode)
nC = numel(CIDs);
S  = S_idx(:);
is_full_shk16 = isequal(S', 1:16) && all(item_state(1:16) == -1);

iso_val = zeros(nC, 1);
iso_clm = zeros(nC, 1);
for m = 1:numel(S)
    ix = S(m);
    st_i = zeros(nC, 1); st_i(ix) = item_state(ix);
    Li = eval_commitment_vector_ledger(state_to_uvec(st_i, CM), P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    iso_val(ix) = Li.PV_Delta_B;
    iso_clm(ix) = Li.Claimed_4Yr_B;
end
tot_clm = sum(iso_clm(S));

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
    uL(:, r)  = subset_state_to_uvec(sk, item_state, CM);
    silo_m(r) = sum(iso_val(sk));
    Lk        = eval_commitment_vector_ledger(uL(:, r), P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
    val_m(r)  = Lk.PV_Delta_B;
    ct        = format_signed_codes(sk, item_state, CIDs);
    lane_codes_cell{r} = strjoin(ct(:)', ',');
end

eval_cols = @(cols) eval_subset_cols_signed(cols, uL, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);

silo_short_4  = {'Silo 1: Health/ECE', 'Silo 2: Rent/KS/Civic', 'Silo 3: Sci/Infra/NDC', 'Silo 4: Tax/Defence'};
silo_2line_4  = {sprintf('Silo 1:\nHealth/ECE'), sprintf('Silo 2:\nRent/KS/Civic'), sprintf('Silo 3:\nSci/Infra/NDC'), sprintf('Silo 4:\nTax/Defence')};
cross_short_4 = {'Health/ECE', 'Rent/Civic', 'Sci/Infra', 'Debt & PAYE'};

wf_lbls = {}; wf_2line = {}; vals = []; is_tot = logical([]); wf_cols = zeros(0, 3);
for r = 1:mL
    k = act_lanes(r);
    wf_lbls{end+1, 1}  = silo_short_4{k};
    wf_2line{end+1, 1} = silo_2line_4{k};
    vals(end+1, 1)     = silo_m(r);
    is_tot(end+1, 1)   = false;
    wf_cols(end+1, :)  = [0.34, 0.42, 0.51];
end

tot_silo  = sum(silo_m);
silo_mult = tot_silo / max(0.05, tot_clm);
wf_lbls{end+1, 1}  = sprintf('SILO SUM (%+.2fx)', silo_mult);
wf_2line{end+1, 1} = sprintf('SILO SUM:\n(%+.2fx)', silo_mult);
vals(end+1, 1)     = tot_silo;
is_tot(end+1, 1)   = true;
wf_cols(end+1, :)  = [0.17, 0.24, 0.31];

W1_intra = sum(val_m - silo_m);
if any(cnt_m >= 2)
    wf_lbls{end+1, 1}  = 'Wedge 1: Intra-Lane';
    wf_2line{end+1, 1} = sprintf('Wedge 1:\nIntra-Lane');
    vals(end+1, 1)     = W1_intra;
    is_tot(end+1, 1)   = false;
    if W1_intra >= 0, wf_cols(end+1, :) = [0.06, 0.62, 0.42]; else, wf_cols(end+1, :) = [0.85, 0.47, 0.02]; end
end

val_cum = val_m(1);
for r = 2:mL
    val_next = eval_cols(1:r);
    w_cr     = val_next - val_cum - val_m(r);
    prev_tags = arrayfun(@(x) sprintf('L%d', x), act_lanes(1:r-1), 'UniformOutput', false);
    k_now     = act_lanes(r);
    wf_lbls{end+1, 1}  = sprintf('Wedge %d: (%s)xL%d %s', r, strjoin(prev_tags, '+'), k_now, cross_short_4{k_now});
    wf_2line{end+1, 1} = sprintf('Wedge %d:\n(%s)xL%d', r, strjoin(prev_tags, '+'), k_now);
    vals(end+1, 1)     = w_cr;
    is_tot(end+1, 1)   = false;
    if w_cr >= 0, wf_cols(end+1, :) = [0.06, 0.44, 0.36]; else, wf_cols(end+1, :) = [0.73, 0.11, 0.11]; end
    val_cum = val_next;
end

ge_mult = val_cum / max(0.05, tot_clm);
wf_lbls{end+1, 1}  = sprintf('FULL GE (%+.2fx)', ge_mult);
wf_2line{end+1, 1} = sprintf('FULL GE:\n(%+.2fx)', ge_mult);
vals(end+1, 1)     = val_cum;
is_tot(end+1, 1)   = true;
wf_cols(end+1, :)  = [0.24, 0.12, 0.36];

% Exact 2^mL Shapley over active lanes
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

fig = figure('Name', sprintf('Additionality & Shapley Wedges: %s (%s)', set_tag, AnchorTag), ...
    'Color', 'w', 'Position', [30, 30, 2160, 1000], 'Visible', vis_mode);

pos1 = [0.055, 0.175, 0.450, 0.710];
ax1  = axes('Parent', fig, 'Position', pos1, 'FontName', def_font);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
nW = numel(vals);
y0 = zeros(1, nW); y1 = zeros(1, nW); run_v = 0;
for i = 1:nW
    if is_tot(i), y0(i) = 0; y1(i) = vals(i); run_v = vals(i);
    else, y0(i) = run_v; y1(i) = run_v + vals(i); run_v = y1(i); end
end
bw_wf = min(0.64, 3.8 / max(6, nW));
X4 = [(1:nW) - 0.5*bw_wf; (1:nW) + 0.5*bw_wf; (1:nW) + 0.5*bw_wf; (1:nW) - 0.5*bw_wf];
Y4 = [y0; y0; y1; y1];
patch(ax1, X4, Y4, reshape(wf_cols, [1, nW, 3]), 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.8);
for i = 1:(nW - 1)
    plot(ax1, [i + 0.5*bw_wf, i + 1 - 0.5*bw_wf], [y1(i), y1(i)], 'k:', 'LineWidth', 1.0, 'HandleVisibility', 'off');
end
all_y  = [y0(:); y1(:); 0];
yA_bot = min(-5, min(all_y) * 1.20);
yA_top = max(+5, max(all_y) * 1.20);
pad_v  = 0.018 * (yA_top - yA_bot);
for i = 1:nW
    if vals(i) >= 0
        text(ax1, i, max(y0(i), y1(i)) + pad_v, sprintf('+$%.1fB', vals(i)), 'Interpreter', 'none', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 7.9, 'FontWeight', 'bold');
    else
        text(ax1, i, min(y0(i), y1(i)) - pad_v, sprintf('-$%.1fB', abs(vals(i))), 'Interpreter', 'none', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontName', def_font, 'FontSize', 7.9, 'FontWeight', 'bold');
    end
end
plot(ax1, [0.3, nW + 0.7], [0, 0], 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax1, [0.3, nW + 0.7], [tot_silo, tot_silo], 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
set(ax1, 'XTick', 1:nW, 'XTickLabel', {}, 'FontName', def_font);
xlim(ax1, [0.3, nW + 0.7]); ylim(ax1, [yA_bot, yA_top]);
for i = 1:nW
    text(ax1, i + 0.12, yA_bot - 0.020 * (yA_top - yA_bot), wf_2line{i}, ...
        'Interpreter', 'none', 'Rotation', 30, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontName', def_font, 'FontSize', 7.9, 'FontWeight', 'bold', 'Clipping', 'off');
end
ylabel(ax1, 'Present-Value Social Welfare Delta (Real 2026 NZD B)', 'Interpreter', 'none', 'FontWeight', 'bold');
text(ax1, mean([0.3, nW + 0.7]), yA_top + 0.065 * (yA_top - yA_bot), ...
    sprintf('A. Logical Additionality Bridge (%s): Silo Sum (%+.1fB) -> GE (%+.1fB)', set_tag, tot_silo, val_cum), ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 10.4, 'FontWeight', 'bold', 'Clipping', 'off');

pos2 = [0.640, 0.175, 0.330, 0.710];
ax2  = axes('Parent', fig, 'Position', pos2, 'FontName', def_font);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
ordM = (mL:-1:1)'; yM = (1:mL)';
s_p = silo_m(ordM); t_p = shap_m(ordM);
bh_s = min(0.52, 1.8 / max(2, mL));
p1 = draw_hbars_span(ax2, yM, zeros(mL,1), s_p, bh_s, [0.34, 0.42, 0.51]);
w_col = [0.73, 0.11, 0.11];
if sum(t_p - s_p) >= 0, w_col = [0.06, 0.44, 0.36]; end
p2 = draw_hbars_span(ax2, yM, s_p, t_p, bh_s, w_col);

sB_min = min(-5, min([t_p; s_p; 0]) * 1.38);
sB_max = max(+5, max([t_p; s_p; 0]) * 1.38);
pad_b  = 0.022 * (sB_max - sB_min);
for k = 1:mL
    if t_p(k) >= 0
        text(ax2, max(s_p(k), t_p(k)) + pad_b, yM(k), sprintf('+$%.1fB GE', t_p(k)), ...
            'Interpreter', 'none', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
            'FontName', def_font, 'FontSize', 8.1, 'FontWeight', 'bold', 'Color', [0.06, 0.44, 0.36]);
    else
        text(ax2, min(s_p(k), t_p(k)) - pad_b, yM(k), sprintf('-$%.1fB GE', abs(t_p(k))), ...
            'Interpreter', 'none', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
            'FontName', def_font, 'FontSize', 8.1, 'FontWeight', 'bold', 'Color', [0.55, 0.08, 0.10]);
    end
end
plot(ax2, [0, 0], [0.4, mL + 0.6], 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
set(ax2, 'YTick', yM, 'YTickLabel', {}, 'FontName', def_font);
xlim(ax2, [sB_min, sB_max]); ylim(ax2, [0.4, mL + 0.6]);

lane_topics = {'Health, ECE & Edu', 'Housing, KS & Civic', 'Sci, Infra & NDC/EV', 'Tax & Defence Fiscal'};
for k = 1:mL
    r_orig = ordM(k);
    ln_id  = act_lanes(r_orig);
    lbl_k  = sprintf('Lane %d:\n%s\n(%s)', ln_id, lane_topics{ln_id}, lane_codes_cell{r_orig});
    text(ax2, sB_min - 0.025 * (sB_max - sB_min), yM(k), lbl_k, 'Interpreter', 'none', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'FontName', def_font, 'FontSize', 8.0, 'FontWeight', 'bold', 'Clipping', 'off');
end
xlabel(ax2, 'Shapley PV Welfare Valuation (Real 2026 NZD B)', 'Interpreter', 'none', 'FontWeight', 'bold');

lgd2 = legend(ax2, [p1, p2], {sprintf('Own-Lane Silo (%+.1fB)', tot_silo), sprintf('Shapley Wedge (%+.1fB)', val_cum - tot_silo)}, ...
    'Orientation', 'horizontal', 'FontSize', 7.3);
set(ax2,  'Position', pos2);
set(lgd2, 'Units', 'normalized', 'Position', [pos2(1), pos2(2) + pos2(4) + 0.010, pos2(3), 0.028]);
IGW_UI_Style('legend_alpha', lgd2, 0.96);
text(ax2, mean([sB_min, sB_max]), (mL + 0.6) + 0.065 * (mL + 0.2), ...
    sprintf('B. Order-Invariant Shapley Attribution (%d Active Lane%s)', mL, char('s' * double(mL > 1))), ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 10.4, 'FontWeight', 'bold', 'Clipping', 'off');

if is_full_shk16
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
%  CORE 5-REGIME TWO-SIDED OLG + LTFM VECTOR EVALUATOR
%  ========================================================================
function L = eval_commitment_vector_ledger(u_vec, P0, pi0, Meta0, CIDs, CM, yr, Debt_Base, Tax_Base, GDP_B, Comp_Mat, disc_vec)
Dials = cell2struct(num2cell(u_vec(:)'), CIDs(:)', 2);
[P1, pi1, Meta1] = Compose_Policy_Bundle(P0, pi0, Dials);

w_pop     = P0.Pop_Weights_4(:) / sum(P0.Pop_Weights_4);
HH_Names  = strcat('HH_', P0.Regions);
scale_gdp = GDP_B / 452.2;
u_t       = max(0, yr - 2024);
q_act     = u_vec(:) .* CM.RefDir(:); % >0 = 2024 Shock; <0 = Asymmetric +Reform

nC      = numel(CIDs);
w_act   = zeros(nC, 1);
tau_itm = zeros(nC, 1);
for i = 1:nC
    if q_act(i) > 0
        w_act(i)   = q_act(i) * CM.Claimed_4Yr_B(i);
        tau_itm(i) = CM.TauOnset(i);
    elseif q_act(i) < 0
        w_act(i)   = ((-q_act(i)) / max(1e-9, CM.PosScale(i))) * CM.ClaimedPos_4Yr_B(i);
        tau_itm(i) = CM.TauPos(i);
    end
end
sum_w   = sum(w_act);
tau_eff = 7.0;
if sum_w > 0, tau_eff = sum(w_act .* tau_itm) / sum_w; end
onset   = (yr >= 2024) .* (1.0 - exp(-u_t / tau_eff));

% Upfront Cash Accounting (Mirage vs. Stern-Kick Seed vs. Structural Tax)
K_mirage = (yr >= 2024) .* exp(-max(0, yr - 2027.5) / 4.5);
K_seed   = (yr >= 2024) .* (double(yr <= 2027) + double(yr > 2027) .* exp(-max(0, yr - 2027.0) / 2.0));
K_struct = (yr >= 2024) .* (0.48 + 0.52 * exp(-max(0, yr - 2028.0) / 10.0)) .* scale_gdp;

Upfront_Cash_B = zeros(numel(yr), 1);
for i = 1:nC
    if q_act(i) > 0
        if CM.MirageSign(i) >= 0, kern = K_mirage; else, kern = K_struct; end
        Upfront_Cash_B = Upfront_Cash_B + kern * (q_act(i) * CM.MirageSign(i) * (CM.Claimed_4Yr_B(i) / 4.0));
    elseif q_act(i) < 0
        rel = (-q_act(i)) / max(1e-9, CM.PosScale(i));
        if CM.MiragePosSign(i) < 0
            if CM.IsCapSeed(i) > 0, kern = K_seed; else, kern = K_mirage; end
        else
            kern = K_struct;
        end
        Upfront_Cash_B = Upfront_Cash_B + kern * (rel * CM.MiragePosSign(i) * (CM.ClaimedPos_4Yr_B(i) / 4.0));
    end
end
Upfront_Cash_B = Upfront_Cash_B - 0.35 * max(0, -u_vec(4)) * double((yr == 2024) | (yr == 2025));

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

ls_neg = [sum(max(0, -u_vec(CM.Lane == 1))); sum(max(0, -u_vec(CM.Lane == 2))); ...
          sum(max(0, -u_vec(CM.Lane == 3))); sum(max(0,  u_vec(CM.Lane == 4)))];
ls_pos = [sum(max(0,  u_vec(CM.Lane == 1))); sum(max(0,  u_vec(CM.Lane == 2))); ...
          sum(max(0,  u_vec(CM.Lane == 3))); sum(max(0, -u_vec(CM.Lane == 4)))];
pair_neg = ls_neg(1)*ls_neg(2) + ls_neg(1)*ls_neg(3) + ls_neg(2)*ls_neg(3) + 0.65 * sum(ls_neg(1:3)) * ls_neg(4);
pair_pos = ls_pos(1)*ls_pos(2) + ls_pos(1)*ls_pos(3) + ls_pos(2)*ls_pos(3) + 0.65 * sum(ls_pos(1:3)) * ls_pos(4);
cg_neg   = min(0.32, 0.016 * pair_neg + 0.14 * max(0, -u_vec(5)) * max(0, -u_vec(8)));
cg_pos   = min(0.36, 0.018 * pair_pos + 0.14 * max(0,  u_vec(5)) * max(0,  u_vec(8)));

shk_wt = sum(w_act(q_act > 0));
ref_wt = sum(w_act(q_act < 0));
if shk_wt + ref_wt == 0
    cg_mult = 1.0;
elseif ref_wt == 0
    cg_mult = 1.0 + cg_neg;
elseif shk_wt == 0
    cg_mult = 1.0 + cg_pos;
else
    cg_use  = cg_neg * double(shk_wt >= ref_wt) + cg_pos * double(ref_wt > shk_wt);
    cg_mult = 1.0 + (abs(shk_wt - ref_wt) / (shk_wt + ref_wt)) * cg_use;
end

Health_Tail_B = -(0.85 * d_Hosp + 11.5 * d_Morbid + 20.0 * d_DeltaHC) * cg_mult .* onset .* scale_gdp;
HumanCap_B    = -(14.0 * d_Strug + 6.5 * d_Emig - 5.8 * d_ln_w - 16.0 * d_G_eff ...
                  + 36.0 * d_gbar - 3.5 * d_mentor - 15.0 * d_alphaI - 24.0 * d_yg) * cg_mult .* onset .* scale_gdp;
StateInfra_B  = -(135.0 * d_ebar + 48.0 * d_rates + 15.5 * d_haz + 4.8 * d_adol ...
                  + 0.34 * d_ndc + 55.0 * d_rspr) * cg_mult .* onset .* scale_gdp;

Net_OBEGAL_B  = Upfront_Cash_B + Health_Tail_B + HumanCap_B + StateInfra_B;
Debt_Shock    = Debt_Base + Comp_Mat * (-(Net_OBEGAL_B ./ GDP_B) * 100);

cl_ramp       = 1.0 ./ (1.0 + exp(-(yr - 2033.0) / 3.2));
paye_div      = double(ref_wt > shk_wt) * 0.035 * min(0, Debt_Shock - Debt_Base) .* cl_ramp;
Tax_Shock     = Tax_Base + d_tau_l_pp * (1.0 - 0.72 * cl_ramp) + 0.060 * max(0, Debt_Shock - Debt_Base) .* cl_ramp + paye_div;
d_CE_Surf     = eval_doc3_surf(Debt_Shock, Tax_Shock) - eval_doc3_surf(Debt_Base, Tax_Base);
Macro_Surf_B  = 0.28 * (d_CE_Surf / 100.0) .* (0.58 * GDP_B);

Direct_OLG_B  = (-0.095 * d_tau_k_pp) * double(yr >= 2025) .* scale_gdp ...
              + (0.68 * u_vec(13)) * onset .* scale_gdp ...
              + 1.20 * Health_Tail_B + 1.25 * HumanCap_B + 1.15 * StateInfra_B ...
              + (22.0 * d_surv - 2.35 * d_Q - 38.0 * d_rates + 0.024 * d_Cohesion) * cg_mult .* onset .* scale_gdp;

Welfare_Flow_B   = Macro_Surf_B + Direct_OLG_B;
Cum_PV_Welfare_B = cumtrapz(yr, disc_vec .* Welfare_Flow_B);
pv_delta         = Cum_PV_Welfare_B(end);

L = struct('Years', yr, 'Debt_Base', Debt_Base, 'Debt_Shock', Debt_Shock, ...
           'Net_OBEGAL_B', Net_OBEGAL_B, 'Welfare_Flow_B', Welfare_Flow_B, ...
           'Cum_PV_Welfare_B', Cum_PV_Welfare_B, 'PV_Delta_B', pv_delta, 'PV_Loss_B', -pv_delta, ...
           'Claimed_4Yr_B', sum_w, 'Multiplier', pv_delta / max(0.05, sum_w));
end

function ce = eval_doc3_surf(D, T)
ce = -0.045 * max(0, D - 42.0) - 0.00032 * (max(0, D - 42.0) .^ 2) ...
   - 0.920 * (T - 22.0) - 0.038 * (max(0, T - 22.0) .^ 2);
end

%% ========================================================================
%  RENDERERS (SINGLE-SHOCK/REFORM, SET MULTIPLIERS, & ACCOUNTING LENSES)
%  ========================================================================
function Out = render_single_shock_3panel(L_Act, L_Mir, L_Ref, s_dir, sel_tag, OutputDir, AnchorTag, def_font, vis_mode)
fig = figure('Name', sprintf('Single-Commitment LTFM Trajectory: %s (%s)', sel_tag, AnchorTag), ...
    'Color', 'w', 'Position', [20, 20, 2160, 1320], 'Visible', vis_mode);
is_ref  = (L_Act.PV_Delta_B >= 0);
c_act   = [0.78, 0.12, 0.16]; if is_ref, c_act = [0.00, 0.46, 0.26]; end
c_mir   = [0.00, 0.46, 0.26]; if is_ref, c_mir = [0.78, 0.12, 0.16]; end
c_slate = [0.34, 0.40, 0.50]; c_plum = [0.38, 0.14, 0.48];
yr      = L_Act.Years;

posA = [0.052, 0.535, 0.398, 0.365];
axA_R = axes('Parent', fig, 'Position', posA, 'FontName', def_font, ...
    'YAxisLocation', 'right', 'Color', 'w', 'XTick', [], 'YColor', c_plum, 'Box', 'off');
hold(axA_R, 'on'); ylim(axA_R, [0, 300]);
ylabel(axA_R, 'Macro Reference Net Debt (% of GDP)', 'Interpreter', 'none', 'FontWeight', 'bold', 'Color', c_plum);

axA = axes('Parent', fig, 'Position', posA, 'FontName', def_font, 'Color', 'none', 'Box', 'off');
hold(axA, 'on'); grid(axA, 'on');
dA_act = L_Act.Debt_Shock - L_Act.Debt_Base;
dA_mir = L_Mir.Debt_Shock - L_Mir.Debt_Base;
yA_lim = max(0.15, max(abs([dA_act; dA_mir])) * 1.28);
map_macro = @(v) -yA_lim + (v / 300.0) * (2.0 * yA_lim);
plot(axA, [2023, 2065.5], [0, 0], 'k:', 'LineWidth', 1.1, 'HandleVisibility', 'off');
h2 = plot(axA, yr, map_macro(L_Act.Debt_Base),  '--', 'Color', c_slate, 'LineWidth', 2.0);
h4 = plot(axA, yr, map_macro(L_Ref.Debt_Shock), ':',  'Color', c_plum,  'LineWidth', 2.3);
h3 = plot(axA, yr, dA_mir, '-.', 'Color', c_mir, 'LineWidth', 2.5);
h1 = plot(axA, yr, dA_act, '-',  'Color', c_act, 'LineWidth', 3.1);
xlim(axA, [2023, 2065.5]); xlim(axA_R, [2023, 2065.5]); ylim(axA, [-yA_lim, yA_lim]);
xlabel(axA, 'Fiscal Year (Treasury LTFS Horizon: 2023-2065)', 'Interpreter', 'none', 'FontWeight', 'bold');
ylabel(axA, 'Isolated Debt Wedge vs. LTFM (pp of GDP)', 'Interpreter', 'none', 'FontWeight', 'bold');
title(axA, sprintf('A. Full Horizon (2023-2065): %s', L_Act.TitleLabel), 'Interpreter', 'none', 'FontSize', 10.5, 'FontWeight', 'bold');
lgdA = legend(axA, [h1, h3, h2, h4], { ...
    sprintf('Active Selection (%s: %+.2f pp by 2065, Left)', sel_tag, dA_act(end)), ...
    sprintf('Opposite-Sign Regime Mirror (%+.2f pp by 2065, Left)', dA_mir(end)), ...
    sprintf('2023 Pre-Shock LTFM Base (%.1f%% GDP in 2065, Right)', L_Act.Debt_Base(end)), ...
    sprintf('Full 16-Shock Bundle Ref (%.1f%% GDP in 2065, Right)', L_Ref.Debt_Shock(end))}, ...
    'Location', 'northwest', 'FontSize', 7.2);
IGW_UI_Style('legend_alpha', lgdA, 0.94);

posB = [0.552, 0.535, 0.405, 0.365];
axB  = axes('Parent', fig, 'Position', posB, 'FontName', def_font);
hold(axB, 'on'); grid(axB, 'on'); box(axB, 'on');
mz = (yr <= 2042); yz = yr(mz);
d_act = L_Act.Debt_Shock(mz) - L_Act.Debt_Base(mz);
d_mir = L_Mir.Debt_Shock(mz) - L_Mir.Debt_Base(mz);
plot(axB, [2023, 2042], [0, 0], 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
hb1 = plot(axB, yz, d_act, '-o', 'MarkerSize', 4.0, 'Color', c_act, 'MarkerFaceColor', c_act, 'LineWidth', 2.8);
hb2 = plot(axB, yz, d_mir, '--', 'Color', c_mir, 'LineWidth', 2.4);

c_ix = find((yz >= 2027) & (((d_act(4) < -0.004) & (d_act > 0)) | ((d_act(4) > 0.004) & (d_act < 0))), 1);
if ~isempty(c_ix)
    yc = yz(c_ix); vc = d_act(c_ix);
    y_span = max(1e-4, max([d_act; d_mir]) - min([d_act; d_mir]));
    x_box  = max(2025.5, yc - 5.2); y_box = vc + (1 - 2*double(d_act(4) > 0)) * 0.30 * y_span;
    cross_lbl = 'Mirage Reversal';
    if d_act(4) > 0, cross_lbl = 'Stern-Kick Payoff'; end
    plot(axB, [x_box + 1.2, yc], [y_box, vc], '-', 'Color', c_act, 'LineWidth', 1.1, 'HandleVisibility', 'off');
    plot(axB, yc, vc, 'o', 'MarkerSize', 8.5, 'MarkerFaceColor', c_act, 'MarkerEdgeColor', 'w', 'HandleVisibility', 'off');
    text(axB, x_box, y_box, sprintf('%s (%d)', cross_lbl, yc), ...
        'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontName', def_font, 'FontSize', 7.9, 'FontWeight', 'bold', 'Color', c_act, 'BackgroundColor', 'w', 'EdgeColor', c_act, 'Margin', 2.5);
end
xlim(axB, [2023, 2042]);
xlabel(axB, 'Tactical Horizon (2023-2042: Upfront Mirage / Seed vs. Reversal)', 'Interpreter', 'none', 'FontWeight', 'bold');
ylabel(axB, 'Net Debt Delta vs. 2023 LTFM (pp of GDP)', 'Interpreter', 'none', 'FontWeight', 'bold');
lgdB = legend(axB, [hb1, hb2], { ...
    sprintf('Active %s (%+.2f pp in 2042)', sel_tag, d_act(end)), ...
    sprintf('5-Regime Mirror (%+.2f pp in 2042)', d_mir(end))}, 'Orientation', 'horizontal', 'FontSize', 7.3);
set(axB,  'Position', posB);
set(lgdB, 'Units', 'normalized', 'Position', [posB(1), posB(2) + posB(4) + 0.007, posB(3), 0.025]);
IGW_UI_Style('legend_alpha', lgdB, 0.96);
y_limB = ylim(axB);
text(axB, mean([2023, 2042]), y_limB(2) + 0.115 * diff(y_limB), ...
    sprintf('B. Tactical Zoom: NZ$%.2fB 4-Yr Scale vs. Debt Crossover', L_Act.Claimed_4Yr_B), ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 10.6, 'FontWeight', 'bold', 'Clipping', 'off');

posC = [0.052, 0.075, 0.905, 0.375];
yL_top = max(0.05, max([L_Act.Net_OBEGAL_B; L_Act.Welfare_Flow_B; 0]) * 1.28);
yL_bot = min(-0.05, min([L_Act.Net_OBEGAL_B; L_Act.Welfare_Flow_B; 0]) * 1.22);
cum_min = min(-0.10, min([L_Act.Cum_PV_Welfare_B; 0]) * 1.15);
cum_max = max(+0.10, max([L_Act.Cum_PV_Welfare_B; 0]) * 1.15);
scale_R = max(abs(cum_min) / abs(yL_bot), abs(cum_max) / abs(yL_top));
axC_R = axes('Parent', fig, 'Position', posC, 'FontName', def_font, ...
    'YAxisLocation', 'right', 'Color', 'w', 'XTick', [], 'YColor', c_plum, 'Box', 'off');
ylim(axC_R, [yL_bot * scale_R, yL_top * scale_R]); xlim(axC_R, [2023, 2065.5]);
ylabel(axC_R, 'Cumulative PV Social Welfare Delta (NZD B)', 'Interpreter', 'none', 'FontWeight', 'bold', 'Color', c_plum);

axC = axes('Parent', fig, 'Position', posC, 'FontName', def_font, 'Color', 'none', 'Box', 'off');
hold(axC, 'on'); grid(axC, 'on');
hc1 = draw_vbars_patch(axC, yr, L_Act.Net_OBEGAL_B, 0.62, [0.18, 0.55, 0.34], 0.55);
hc2 = plot(axC, yr, L_Act.Welfare_Flow_B, '-', 'Color', c_act, 'LineWidth', 2.6);
hc3 = plot(axC, yr, L_Act.Cum_PV_Welfare_B / scale_R, '--o', 'MarkerSize', 3.6, 'Color', c_plum, 'MarkerFaceColor', c_plum, 'LineWidth', 3.0);
plot(axC, [2023, 2065.5], [0, 0], 'k-', 'LineWidth', 1.1, 'HandleVisibility', 'off');
xlim(axC, [2023, 2065.5]); ylim(axC, [yL_bot, yL_top]);
xlabel(axC, 'Calendar Year (2023-2065)', 'Interpreter', 'none', 'FontWeight', 'bold');
ylabel(axC, 'Annual Flow Delta (Real 2026 NZD B / yr)', 'Interpreter', 'none', 'FontWeight', 'bold');
title(axC, sprintf('C. %s Valuation: NZ$%.2fB 4-Yr Scale -> %+.2fB PV25 Welfare (%+.2fx per $1)', ...
    sel_tag, L_Act.Claimed_4Yr_B, L_Act.PV_Delta_B, L_Act.Multiplier), 'Interpreter', 'none', 'FontSize', 10.7, 'FontWeight', 'bold');
lgdC = legend(axC, [hc1, hc2, hc3], { ...
    'Annual Crown OBEGAL Cash Delta (Left)', ...
    'Annual Social Welfare Flow (Left)', ...
    sprintf('Cumulative 2.5%% PV Welfare (%+.2fB = %+.2fx, Right)', L_Act.PV_Delta_B, L_Act.Multiplier)}, ...
    'Location', 'southwest', 'FontSize', 7.5);
IGW_UI_Style('legend_alpha', lgdC, 0.94);

Out_PNG = fullfile(OutputDir, sprintf('Fig_LTFM_SingleShock_%s_%s.png', sel_tag, AnchorTag));
Out_CSV = fullfile(OutputDir, sprintf('Table_LTFM_SingleShock_%s_%s.csv', sel_tag, AnchorTag));
T_Out = table(yr, round(L_Act.Debt_Base,2), round(L_Act.Debt_Shock,2), round(L_Mir.Debt_Shock,2), ...
    round(L_Act.Net_OBEGAL_B,3), round(L_Act.Welfare_Flow_B,3), round(L_Act.Cum_PV_Welfare_B,3), ...
    'VariableNames', {'Year','Debt_LTFM_PctGDP','Debt_Active_PctGDP','Debt_Mirror_PctGDP','OBEGAL_Delta_BNZD','Welfare_Flow_BNZD','Cum_PV_Welfare_BNZD'});
writetable(T_Out, Out_CSV);
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Exported Single-Commitment CSV Ledger to: %s\n', Out_CSV);
fprintf('  -> Saved 3-Panel Single-Commitment Figure to: %s\n', Out_PNG);
if strcmpi(vis_mode, 'off'), close(fig); end
Out = struct('Ledger', L_Act, 'MirrorLedger', L_Mir, 'Table', T_Out, 'FigurePath', Out_PNG, 'TablePath', Out_CSV);
end

function Out = render_set_multipliers_fig(Labels, Claimed_B, Val_B, Mult_Vec, Cat_Vec, n_grp_bars, sum_iso_B, full_ge_B, tot_clm_B, ref_grp, ref_grp_lbl, is_full_shk16, set_tag, OutputDir, AnchorTag, def_font, vis_mode)
fig_h = max(720, min(1100, 320 + 40 * numel(Labels)));
fig = figure('Name', sprintf('Individual & Logical Group Multipliers: %s (%s)', set_tag, AnchorTag), ...
    'Color', 'w', 'Position', [30, 30, 2120, fig_h], 'Visible', vis_mode);
col_map = [0.74,0.14,0.18; 0.84,0.48,0.08; 0.24,0.46,0.64; 0.24,0.12,0.36];

ord = (numel(Labels):-1:1)';
L_p = Labels(ord); C_p = Claimed_B(ord); V_p = Val_B(ord); M_p = Mult_Vec(ord); K_p = Cat_Vec(ord); nB = numel(L_p);
y_idx = (1:nB)';
bh = min(0.72, 4.5 / max(6, nB));
y_sep = n_grp_bars + 0.5;

bar_rgb = col_map(K_p, :);
pos_non_grp = (V_p >= 0) & (K_p < 4);
if any(pos_non_grp), bar_rgb(pos_non_grp, :) = repmat([0.06, 0.44, 0.36], sum(pos_non_grp), 1); end

pos1 = [0.245, 0.095, 0.340, 0.785];
ax1  = axes('Parent', fig, 'Position', pos1, 'FontName', def_font);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
draw_hbars_patch(ax1, y_idx, M_p, bh, bar_rgb, 1.0);
m_min = min(-2.0, min(M_p) * 1.34);
m_max = max(+2.0, max(M_p) * 1.34);
pad_m = 0.015 * (m_max - m_min);
for k = 1:nB
    if M_p(k) >= 0
        text(ax1, M_p(k) + pad_m, y_idx(k), sprintf('+$%.2f / $1', M_p(k)), 'Interpreter', 'none', ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'FontName', def_font, 'FontSize', 8.1, 'FontWeight', 'bold');
    else
        text(ax1, M_p(k) - pad_m, y_idx(k), sprintf('-$%.2f / $1', abs(M_p(k))), 'Interpreter', 'none', ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'FontName', def_font, 'FontSize', 8.1, 'FontWeight', 'bold');
    end
end
plot(ax1, [0, 0], [0.3, nB + 0.7], 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax1, [m_min, m_max], [y_sep, y_sep], 'k:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
set(ax1, 'YTick', y_idx, 'YTickLabel', L_p, 'FontName', def_font, 'FontSize', 8.4, 'FontWeight', 'bold');
xlim(ax1, [m_min, m_max]); ylim(ax1, [0.3, nB + 0.7]);
xlabel(ax1, 'PV25 Social Welfare Valuation per $1 of 4-Yr Scale', 'Interpreter', 'none', 'FontWeight', 'bold');
text(ax1, mean([m_min, m_max]), (nB + 0.7) + 0.055 * (nB + 0.4), ...
    'A. Outcome per $1 of 4-Yr Scale (-$ Lost | +$ Gained)', ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 10.5, 'FontWeight', 'bold', 'Clipping', 'off');

pos2 = [0.620, 0.095, 0.350, 0.785];
ax2  = axes('Parent', fig, 'Position', pos2, 'FontName', def_font);
hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
draw_hbars_patch(ax2, y_idx, V_p, bh, bar_rgb, 0.90);
v_min = min(-10.0, min([V_p; 0]) * 1.36);
v_max = max(+10.0, max([V_p; 0]) * 1.36);
pad_v = 0.015 * (v_max - v_min);
for k = 1:nB
    if V_p(k) >= 0
        text(ax2, V_p(k) + pad_v, y_idx(k), sprintf('+$%.1fB', V_p(k)), 'Interpreter', 'none', ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'FontName', def_font, 'FontSize', 8.0, 'FontWeight', 'bold');
    else
        text(ax2, V_p(k) - pad_v, y_idx(k), sprintf('-$%.1fB', abs(V_p(k))), 'Interpreter', 'none', ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'FontName', def_font, 'FontSize', 8.0, 'FontWeight', 'bold');
    end
end
plot(ax2, [0, 0], [0.3, nB + 0.7], 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
plot(ax2, [v_min, v_max], [y_sep, y_sep], 'k:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
set(ax2, 'YTick', y_idx, 'YTickLabel', {}, 'FontName', def_font);
xlim(ax2, [v_min, v_max]); ylim(ax2, [0.3, nB + 0.7]);
xlabel(ax2, 'Present-Value Social Welfare Delta (Real 2026 NZD B)', 'Interpreter', 'none', 'FontWeight', 'bold');
text(ax2, mean([v_min, v_max]), (nB + 0.7) + 0.055 * (nB + 0.4), ...
    sprintf('B. Siloed Sum (%+.1fB) vs. Combined GE Valuation (%+.1fB)', sum_iso_B, full_ge_B), ...
    'Interpreter', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontName', def_font, 'FontSize', 10.5, 'FontWeight', 'bold', 'Clipping', 'off');

if is_full_shk16
    fname_base = sprintf('Doc3_Coalition_ShockByShock_Mirage_Multiplier_%s', AnchorTag);
else
    fname_base = sprintf('Doc3_Set_%s_Mirage_Multiplier_%s', set_tag, AnchorTag);
end
Out_PNG = fullfile(OutputDir, ['Fig_', fname_base, '.png']);
Out_CSV = fullfile(OutputDir, ['Table_', fname_base, '.csv']);
T_Mult  = table(Labels, round(Claimed_B,2), round(Val_B,2), round(Mult_Vec,2), ...
    'VariableNames', {'Commitment_Or_Group','Scale_4Yr_BNZD','PV25_Welfare_Delta_BNZD','Outcome_Per_Dollar'});
writetable(T_Mult, Out_CSV);
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Exported Set Multipliers CSV to: %s\n', Out_CSV);
fprintf('  -> Saved 2-Panel Set Multipliers Figure to: %s\n', Out_PNG);
if strcmpi(vis_mode, 'off'), close(fig); end
Out = struct('SummaryTable', T_Mult, 'FigurePath', Out_PNG, 'TablePath', Out_CSV);
end

function Out = run_and_render_accounting_lenses(item_state, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_25, OutputDir, AnchorTag, def_font, vis_mode)
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
st_ref13   = zeros(nC, 1); st_ref13([1:8, 12:16]) = +1;
u_ref13    = state_to_uvec(st_ref13, CM);
iso_ref_80 = 0; iso_ref_25 = 0;
for ix = [1:8, 12:16]
    st_i = zeros(nC,1); st_i(ix) = +1;
    Lr = eval_commitment_vector_ledger(state_to_uvec(st_i, CM), P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_25);
    iso_ref_80 = iso_ref_80 + trapz(yr, disc_80 .* Lr.Welfare_Flow_B);
    iso_ref_25 = iso_ref_25 + trapz(yr, disc_25 .* Lr.Welfare_Flow_B);
end

pkg_names = { ...
    'C08 Shock: Tobacco Repeal ($0.30B)'; ...
    '+C08 Reform: Cessation Kink ($0.16B)'; ...
    '12 Public Cuts & Shifts ($11.90B)'; ...
    'Retrenchment + Landlord 10 ($12.30B)'; ...
    'Full 16-Shock Vector ($35.60B)'; ...
    '+13 Public & Tenure Reforms ($12.94B)'};
u_c08s = zeros(nC,1); u_c08s(8) = u_f16(8);
st_c08p = zeros(nC,1); st_c08p(8) = +1; u_c08p = state_to_uvec(st_c08p, CM);
pkg_uvecs = {u_c08s, u_c08p, u_cuts12, CM.Vec_Ret10, u_f16, u_ref13};

nP = numel(pkg_names); Claim_B = zeros(nP, 1); Mat_5 = zeros(nP, 5);
silo80_vec = [iso_80(8), 0, sum(iso_80(idx_cuts12)), sum(iso_80([1:8,12:13])), sum(iso_80), iso_ref_80];
silo25_vec = [iso_25(8), 0, sum(iso_25(idx_cuts12)), sum(iso_25([1:8,12:13])), sum(iso_25), iso_ref_25];

for p = 1:nP
    Lp = eval_commitment_vector_ledger(pkg_uvecs{p}, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_25);
    Claim_B(p)  = Lp.Claimed_4Yr_B;
    Mat_5(p, 1) = sum(Lp.Net_OBEGAL_B(m_4yr));
    if p == 2
        Mat_5(p, 2) = trapz(yr, disc_80 .* Lp.Welfare_Flow_B);
        Mat_5(p, 3) = trapz(yr, disc_25 .* Lp.Welfare_Flow_B);
    else
        Mat_5(p, 2) = silo80_vec(p);
        Mat_5(p, 3) = silo25_vec(p);
    end
    Mat_5(p, 4) = trapz(yr, disc_25   .* Lp.Welfare_Flow_B);
    Mat_5(p, 5) = trapz(yr, disc_srtp .* Lp.Welfare_Flow_B);
end

fig = figure('Name', sprintf('Accounting Lens Translator (%s)', AnchorTag), ...
    'Color', 'w', 'Position', [25, 25, 1960, 920], 'Visible', vis_mode);
ax1 = axes('Parent', fig, 'Position', [0.075, 0.14, 0.88, 0.76], 'FontName', def_font);
hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
x5 = (1:5)'; w = 0.24;
b1 = Mat_5(3, :)'; b2 = Mat_5(5, :)'; b3 = Mat_5(6, :)';
draw_vbars_multi(ax1, x5 - w, b1, w * 0.90, repmat([0.85, 0.47, 0.02], 5, 1));
draw_vbars_multi(ax1, x5,     b2, w * 0.90, repmat([0.24, 0.12, 0.36], 5, 1));
draw_vbars_multi(ax1, x5 + w, b3, w * 0.90, repmat([0.06, 0.44, 0.36], 5, 1));
plot(ax1, [0.4, 5.6], [0, 0], 'k-', 'LineWidth', 1.3, 'HandleVisibility', 'off');
set(ax1, 'XTick', 1:5, 'XTickLabel', {'1. 4-Yr OBEGALx', '2. 8% Silo CBA', '3. 2.5% Silo CBAx', '4. 2.5% Full GE', '5. Treasury SRTP'}, 'FontWeight', 'bold');
xlim(ax1, [0.4, 5.6]); ylabel(ax1, 'Valuation (Real 2026 NZD Billions)', 'Interpreter', 'none', 'FontWeight', 'bold');
title(ax1, '5-Framework Accounting Lens Translator: 12 Public Cuts (Amber) vs. Full 16 Shocks (Plum) vs. +13 Reforms (Teal)', 'Interpreter', 'none', 'FontWeight', 'bold');

Out_PNG = fullfile(OutputDir, sprintf('Fig_Doc3_Accounting_Lens_Translator_%s.png', AnchorTag));
Out_CSV = fullfile(OutputDir, sprintf('Table_Doc3_Accounting_Lens_Translator_%s.csv', AnchorTag));
T_Lens  = table(pkg_names, round(Claim_B,2), round(Mat_5(:,1),2), round(Mat_5(:,2),2), round(Mat_5(:,3),2), round(Mat_5(:,4),2), round(Mat_5(:,5),2), ...
    'VariableNames', {'Policy_Package','Scale_4Yr_BNZD','Lens1_4Yr_OBEGALx_BNZD','Lens2_8pct_Silo_BNZD','Lens3_25pct_Silo_BNZD','Lens4_25pct_IGW_GE_BNZD','Lens5_Treasury_SRTP_GE_BNZD'});
writetable(T_Lens, Out_CSV);
exportgraphics(fig, Out_PNG, 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('  -> Exported Accounting Lens Translator CSV to: %s\n', Out_CSV);
fprintf('  -> Saved Accounting Lens Translator Figure to: %s\n', Out_PNG);
if strcmpi(vis_mode, 'off'), close(fig); end
Out = struct('LensTable', T_Lens, 'FigurePath', Out_PNG, 'TablePath', Out_CSV);
end

%% ========================================================================
%  SIGNED SET PARSER & CATALOG METADATA EXTRACTOR
%  ========================================================================
function [mode_code, item_state, S_idx, set_tag] = parse_shock_set(sel, CIDs, CM)
mode_code  = 1;
nC         = numel(CIDs);
item_state = zeros(nC, 1);

if isnumeric(sel) || islogical(sel)
    if islogical(sel)
        idx = find(sel(:));
        item_state(idx) = -1;
    else
        vals = sel(:);
        for k = 1:numel(vals)
            ix = abs(round(vals(k)));
            if vals(k) > 0, item_state(ix) = -1; elseif vals(k) < 0, item_state(ix) = +1; end
        end
    end
elseif iscell(sel)
    for k = 1:numel(sel)
        [~, sub_st, ~, ~] = parse_shock_set(sel{k}, CIDs, CM);
        nz = find(sub_st ~= 0);
        item_state(nz) = sub_st(nz);
    end
else
    s = lower(strtrim(char(sel)));
    if any(strcmp(s, {'lenses', 'translator', 'accounting'}))
        mode_code = 3; item_state(1:16) = -1; S_idx = (1:16)'; set_tag = 'Lenses'; return;
    end
    if strncmp(s, 'wedges:', 7) || strncmp(s, 'shapley:', 8)
        mode_code = 2;
        colon_pos = find(s == ':', 1);
        [~, item_state, S_idx, set_tag] = parse_shock_set(s(colon_pos+1:end), CIDs, CM);
        return;
    end
    if any(strcmp(s, {'wedges', 'additionality', 'shapley'}))
        mode_code = 2; item_state(1:16) = -1; S_idx = (1:16)'; set_tag = 'All16'; return;
    end

    s_clean = regexprep(s, '[\{\}\[\]\(\)]', ' ');
    tokens  = regexp(strtrim(s_clean), '[,;\s]+', 'split');
    for t = 1:numel(tokens)
        tok = strtrim(tokens{t});
        if isempty(tok), continue; end
        sgn = -1; % Bare token = 2024 Shock (-1); leading '+' = Asymmetric +Reform (+1)
        if tok(1) == '+'
            sgn = +1; tok = tok(2:end);
        elseif tok(1) == '-'
            sgn = -1; tok = tok(2:end);
        end
        if any(strcmp(tok, {'all', 'bundle', 'multipliers', 'full16', 'full_16', 'full_16_commitments'}))
            item_state(1:16) = sgn; continue;
        elseif any(strcmp(tok, {'dom15', 'domestic_15', 'domestic_15_bundle'}))
            item_state(1:15) = sgn; continue;
        elseif any(strcmp(tok, {'ret10', 'retrenchment_10', 'retrenchment_and_tenure_10'}))
            item_state([1:8, 12:13]) = sgn; continue;
        elseif strcmp(tok, 'cuts12')
            item_state([2:8, 12:16]) = sgn; continue;
        elseif strcmp(tok, 'reforms13')
            item_state([1:8, 12:16]) = +1; continue;
        end
        rng_m = regexp(tok, '^c?0*(\d+)(?:\.\.|-|:)c?0*(\d+)$', 'tokens', 'once');
        if ~isempty(rng_m)
            a = str2double(rng_m{1}); b = str2double(rng_m{2});
            item_state(min(a,b):max(a,b)) = sgn; continue;
        end
        num_m = regexp(tok, '^c?0*(\d+)$', 'tokens', 'once');
        if ~isempty(num_m)
            item_state(str2double(num_m{1})) = sgn; continue;
        end
        ix = resolve_single_token(tok, CIDs);
        item_state(ix) = sgn;
    end
end

S_idx = find(item_state ~= 0);
if isempty(S_idx)
    error('Plot_LTFM_Coalition_Shock_Mirage:EmptyShockSet', 'No active commitments parsed.');
end
if isequal(S_idx', 1:16) && all(item_state(1:16) == -1)
    set_tag = 'All16';
elseif isequal(S_idx', 1:16) && all(item_state(1:16) == +1)
    set_tag = 'PlusAll16';
elseif numel(S_idx) <= 6
    ct = format_signed_codes(S_idx, item_state, CIDs);
    set_tag = strrep(strjoin(ct(:)', '_'), '+', 'Pos');
else
    n_pos = sum(item_state(S_idx) == 1);
    set_tag = sprintf('Set%d_Pos%d', numel(S_idx), n_pos);
end
end

function ct = format_signed_codes(idx_vec, item_state, CIDs)
raw_c = regexp(CIDs(idx_vec), '^C\d+', 'match', 'once');
ct = cell(numel(idx_vec), 1);
for k = 1:numel(idx_vec)
    if item_state(idx_vec(k)) == 1
        ct{k} = ['+', raw_c{k}];
    else
        ct{k} = raw_c{k};
    end
end
end

function u = state_to_uvec(st_vec, CM)
u = zeros(numel(st_vec), 1);
m_shk = (st_vec == -1);
m_ref = (st_vec == +1);
u(m_shk) =  CM.CoalitionDial(m_shk);
u(m_ref) = -CM.PosScale(m_ref) .* CM.RefDir(m_ref);
end

function u = subset_state_to_uvec(idx_list, item_state, CM)
st_sub = zeros(numel(item_state), 1);
st_sub(idx_list) = item_state(idx_list);
u = state_to_uvec(st_sub, CM);
end

function val_b = eval_subset_cols_signed(cols, uL, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec)
u_sub = sum(uL(:, cols), 2);
L_sub = eval_commitment_vector_ledger(u_sub, P0, pi0, Meta0, CIDs, CM, yr, Debt_B0, Tax_B0, GDP_B, Comp_Mat, disc_vec);
val_b = L_sub.PV_Delta_B;
end

function ix = resolve_single_token(tok, CIDs)
aliases = {'landlord',1; 'callaghan',2; 'science',2; 'pubsec',3; 'layoffs',3; ...
           'irex',4; 'ferry',4; 'dunedin',5; 'hospital',5; ...
           'payequity',6; 'ece',6; 'tertiary',7; 'feesfree',7; ...
           'tobacco',8; 'smokefree',8; 's10',8; ...
           'taxcut',9; 'brackets',9; 'aip',10; 'visa',10; ...
           'expensing',11; 'investboost',11; 'teacher',12; 'kaiako',12; ...
           'kiwisaver',13; 'water',14; '3waters',14; ...
           'civic',15; 'arts',15; 'wcc',15; 'doc1e',15; 'ndc',16; 'ev',16; 'cerf',16; ...
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
def = { ...
    'Landlord Interest Deductibility',       'Owner-Occupier Neutrality & LVR Cool',            2.90,  2.90, 1.00, -1.00,  1.00,  5.5,  5.5, 0, 2; ...
    'Callaghan & Science Wind-Down',         'Full CRI/Marsden + Lab Plant Buildout (12y Lag)', 0.65,  1.80, 1.69,  1.00, -1.00,  7.5, 12.0, 1, 1; ...
    'Core Public Service Redundancies',      'Targeted Analytical & Procurement Cap (0.30x)',   1.50,  0.45, 0.30,  1.00, -1.00,  4.5,  5.5, 0, 1; ...
    'iReX Rail-Ferry Cancellation',          'Electrified Port Shore-Power & Trunk (0.35x)',    0.80,  0.45, 0.35,  0.35, -1.00,  5.5,  6.5, 1, 1; ...
    'Dunedin Hospital & Clinical Deferral',  'Surgical Waitlist & Clinical Buffer (0.35x)',     0.55,  0.30, 0.35,  1.00, -1.00,  6.5,  6.5, 0, 1; ...
    'Pay Equity Repeal & ECE Squeeze',       'First-2000-Days ECE & Whanau Ora (0.80x)',        1.40,  1.12, 0.80,  1.00, -1.00, 10.0, 10.5, 0, 1; ...
    'Tertiary Fees-Free Repeal',             'Liquidity-Constrained Youth Launch (0.50x)',      0.85,  0.43, 0.50,  1.00, -1.00,  6.5,  7.5, 0, 1; ...
    'Tobacco Freeze & Smokefree Repeal',     'Targeted Cessation, NRT & Border Shield (0.38x)', 0.30,  0.16, 0.38,  1.00, -1.00,  8.0, 10.5, 0, 1; ...
    'Working-Age Tax Threshold Relief',      'Local-Band Progressive Revenue Trim (0.45x)',    14.70,  6.60, 0.45, -1.00,  1.00,  3.5,  3.5, 0, 2; ...
    'Active Investor Plus Visa Inflow',      'Screen Passive Luxury-Land Inflows (0.25x)',      4.40,  1.10, 0.25,  0.08, -0.05,  6.0,  5.0, 0, 3; ...
    '20% Immediate Asset Expensing',         'Local Corporate Depreciation Trim (0.40x)',       1.70,  0.68, 0.40, -1.00,  1.00,  4.5,  4.5, 0, 3; ...
    'Educator Real Pay Compression',         'Kaiako & Teacher Parity + Rent Allow (0.50x)',    0.75,  0.38, 0.50,  1.00, -1.00,  9.0,  8.5, 0, 1; ...
    'KiwiSaver Match Cut & 30% Social IRR',  'Low-Income Match & 25% Social Rent Cap (0.45x)',  2.60,  1.17, 0.45,  1.00, -1.00, 10.5, 10.5, 0, 1; ...
    'Three Waters Devolution & Rates Cap',   'Ring-Fenced National Water Balance Sheet (0.55x)',1.20,  0.66, 0.55,  0.80, -0.40,  7.0,  7.0, 0, 1; ...
    'Grassroots Arts, Sport & Civic Cuts',   'Doc 1E Joiner Passport & Creative Clubs ($1.32B)',0.35,  1.32, 1.00,  1.00, -1.00,  8.5,  8.0, 0, 1; ...
    'Paris NDC Shortfall & Clean-Car Repeal','CERF Electrification & Clean-Green Seed ($1.80B)',0.95,  1.80, 1.00,  0.45, -1.00,  5.5,  6.5, 1, 1; ...
    'Distressed Network/Grid Privatization', 'Ostrom & Commercial-Board Grid Reform (0.45x)',   3.20,  0.40, 0.45,  1.00, -1.00,  6.5,  7.0, 1, 1; ...
    'Unfunded 3.0% GDP Defence Posture',     'Keep 1.2% Base + Onshore Clean-Tech Stern-Kick',  8.00,  1.20, 1.00, -1.00, -1.00,  3.0,  6.5, 1, 1};

v_ret10 = bundle_to_vec(B.retrenchment_and_tenure_10, CIDs);
v_dom15 = bundle_to_vec(B.domestic_15_bundle, CIDs);
v_ful16 = bundle_to_vec(B.full_16_commitments, CIDs);
ref_dir = [-1;-1;-1;-1;-1;-1;-1;-1; +1;+1;+1; -1;-1;-1;-1;-1;-1;+1];

if isstruct(T), cols = fieldnames(T); else, cols = T.Properties.VariableNames; end
codes = regexp(CIDs, '^C\d+', 'match', 'once');
sl = get_str_col(T, cols, 'Short_Label',  def(1:nC, 1));
rl = get_str_col(T, cols, 'Reform_Label', def(1:nC, 2));
CM.CodeLabel        = strcat(codes(:), {': '}, sl(:));
CM.ReformCodeLabel  = strcat({'+'}, codes(:), {': '}, rl(:));
CM.Claimed_4Yr_B    = get_num_col(T, cols, 'Claimed_4Yr_BNZD',     def(1:nC, 3));
CM.ClaimedPos_4Yr_B = get_num_col(T, cols, 'Claimed_Pos_4Yr_BNZD', def(1:nC, 4));
CM.PosScale         = get_num_col(T, cols, 'Pos_Mirror_Scale',     def(1:nC, 5));
CM.MirageSign       = get_num_col(T, cols, 'Fiscal_Mirage_Sign',   def(1:nC, 6));
CM.MiragePosSign    = get_num_col(T, cols, 'Mirage_Pos_Sign',      def(1:nC, 7));
CM.TauOnset         = get_num_col(T, cols, 'Tau_Onset_Yrs',        def(1:nC, 8));
CM.TauPos           = get_num_col(T, cols, 'Tau_Pos_Yrs',          def(1:nC, 9));
CM.IsCapSeed        = get_num_col(T, cols, 'Is_Cap_Seed',          def(1:nC, 10));
CM.Category         = get_num_col(T, cols, 'Mirage_Category',      def(1:nC, 11));

CM.RefDir        = ref_dir(1:nC);
CM.CoalitionDial = v_ful16 + double(v_ful16 == 0) .* CM.RefDir;
CM.InFull16      = abs(v_ful16) > 0;
CM.Vec_Ret10     = v_ret10; CM.Vec_Dom15 = v_dom15; CM.Vec_Full16 = v_ful16;
CM.Lane          = [2;3;3;3;1;1;1;1;4;3;3;1;2;2;2;3;3;4];
end

function c_out = get_str_col(T, cols, fn, def_cell)
if any(strcmp(cols, fn))
    raw = T.(fn);
    if ischar(raw), c_out = cellstr(raw); else, c_out = cellstr(raw(:)); end
else
    c_out = def_cell;
end
end

function d_out = get_num_col(T, cols, fn, def_cell)
if any(strcmp(cols, fn))
    raw = T.(fn);
    if iscell(raw), d_out = str2double(raw(:)); else, d_out = double(raw(:)); end
else
    d_out = cell2mat(def_cell);
end
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
