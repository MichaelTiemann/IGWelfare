function TransOut = Compute_TransitionPath_4Region(Params, WelfareResults, T1, Opts)
%% PURE MATHEMATICAL CONTRACT: 60-YEAR NON-LINEAR MULTIPHASE TRANSITION PATH (SS0 -> SS1 -> SS2+)
% File: src/models/Compute_TransitionPath_4Region.m
% Pure, idempotent state-to-value transformation computing:
%   1. Dynamic regional population law of motion (s_HH_path: domestic sorting + intl inflows)
%   2. Layer-3 Contingency gate evaluation (GateEval_Trans, T_phase2_yr, Phase2_Announcement_Mode)
%   3. Daruich cohort welfare trajectories (-15 to +45 yrs) & MIT credibility wedge (CE_Cohort, CE_Cohort_MIT)
%   4. Kiyotaki housing user-cost cooling (Q_path), brain-drain closure (Emig_Rate_Path), & cohesion (Cohesion_Index)
%   5. Canonical summary tables (T_CohortWelfare, T_PopShares, T_BrainDrain_Path)
% Zero evalin / assignin, zero Params mutation, zero figure/CSV side effects.

if nargin < 2, WelfareResults = struct(); end
if nargin < 3, T1 = []; end
if nargin < 4 || isempty(Opts), Opts = struct(); end

if ~isfield(Params, 'dt') || ~isfield(Params, 'DataSpec_Digest')
    Params = Configure_Model_Params(Params);
end

if isfield(Opts, 'Regions') && ~isempty(Opts.Regions)
    Regions = Opts.Regions;
else
    Regions = Params.Regions;
end

dt          = Params.dt;
T_years     = 60;
T_trans     = round(T_years / dt);
Trans_Years = (0 : (T_trans - 1))' * dt;
N_reg       = length(Regions);

has_phases_ss2 = isfield(Opts, 'Phases') && numel(Opts.Phases) >= 3;
has_SS2        = (isstruct(WelfareResults) && isfield(WelfareResults, 'SS2')) || has_phases_ss2;

% Resolve Phase-2 Trigger Year & Announcement Mode from Layer 3 ContingencySpec (unless overridden in Opts)
if isfield(Opts, 'StateMetrics_Trans') && isstruct(Opts.StateMetrics_Trans)
    StateMetrics_Trans = Opts.StateMetrics_Trans;
else
    StateMetrics_Trans = struct();
end
ContingencySpec_Trans = Load_Contingency_Policy(Params.Profile_ID, Params.Contingency_Policy);
GateEval_Trans        = Evaluate_Contingency_Gates(ContingencySpec_Trans, Trans_Years, StateMetrics_Trans);

if isfield(Opts, 'T_phase2_yr') && ~isempty(Opts.T_phase2_yr)
    T_phase2_yr = Opts.T_phase2_yr;
else
    T_phase2_yr = GateEval_Trans.SS2_Unlock_Year;
end

if isfield(Opts, 'Phase2_Announcement_Mode') && ~isempty(Opts.Phase2_Announcement_Mode)
    % 'PreAnnounced' (lambda_cred = 1.0), 'EarnedCred' (ramps 0.25 -> 1.0), or 'Unannounced_MIT' (0 -> 1 at T_phase2_yr)
    Phase2_Announcement_Mode = Opts.Phase2_Announcement_Mode;
else
    Phase2_Announcement_Mode = Params.Contingency_Announcement_Mode;
end

%% 1. DYNAMIC REGIONAL POPULATION LAW OF MOTION (s_HH,t: DOMESTIC SORTING + INTL INFLOWS FROM DATASPEC)
s_HH_path = zeros(T_trans, N_reg);
s_HH_0    = Params.Pop_Weights_4(:)';
if isfield(Params, 'PTypeWeights') && numel(Params.PTypeWeights) >= N_reg
    s_HH_0 = Params.PTypeWeights(1:N_reg)' / sum(Params.PTypeWeights(1:N_reg));
end
s_HH_path(1, :) = s_HH_0;

Pi_dom     = Params.Trans_Pi_dom_SS1;
Pi_dom_SS2 = Params.Trans_Pi_dom_SS2;
m_intl     = Params.Trans_Intl_Inflow_Share;
zeta_c     = 0.035 * (dt / 5);

for t = 1:(T_trans - 1)
    % In Phase 2 (t_yr >= T_phase2_yr), regional infrastructure dividend further stabilizes retention
    yr_t = Trans_Years(t);
    if has_SS2 && yr_t >= T_phase2_yr
        Pi_dom_t = Pi_dom_SS2;
    else
        Pi_dom_t = Pi_dom;
    end
    s_next = (1 - zeta_c) * (s_HH_path(t, :) * Pi_dom_t) + zeta_c * m_intl;
    s_HH_path(t + 1, :) = s_next / sum(s_next);
end

%% 2. EXTRACT STAGE GAINS FOR SS1 (AND SS2 IF ACTIVE) FROM WELFARERESULTS / T1
if isstruct(WelfareResults) && isfield(WelfareResults, 'SS1')
    T1_SS1 = WelfareResults.SS1.T1_Stage;
elseif istable(T1) && height(T1) >= 3
    T1_SS1 = T1(1:3, :);
else
    error('IGWelfare:MissingWelfareAnchors', 'Compute_TransitionPath_4Region requires WelfareResults.SS1 or T1.');
end

if has_SS2 && isstruct(WelfareResults) && isfield(WelfareResults, 'SS2')
    T1_SS2 = WelfareResults.SS2.T1_Stage;
elseif has_SS2 && istable(T1) && height(T1) >= 6
    T1_SS2 = T1(4:6, :);
else
    T1_SS2 = T1_SS1;
end

%% 3. DARUICH COHORT WELFARE TRAJECTORY (COHORTS c = -15 TO +45 YEARS RELATIVE TO REFORM)
Cohort_Years  = (-15 : dt : 45)';
N_coh         = length(Cohort_Years);
CE_Cohort     = zeros(N_coh, N_reg); % Primary trajectory (SS0 -> SS1, or SS0 -> SS1 -> SS2)
CE_Cohort_MIT = zeros(N_coh, N_reg); % Counterfactual unannounced MIT trajectory when has_SS2 == true

% Regional mean wave arrival center (yrs) under the 13-Wave Te Kāhui Waka:
% Rural+Small lead in Waves 1, 4, 7 (plus consecutive Waves 1-3 Electrification);
% Large follows in Waves 2, 5, 8; Auckland follows in Waves 3, 6, 9:
is_kahui_mode = ~isfield(Params, 'Rollout_Mode') || any(strcmpi(Params.Rollout_Mode, {'TeKahuiWaka', 'Armada'}));
t_kahui_lag   = Params.kahui_lag_yrs(:)'; % Regional mean wave arrival center (yrs) from DataSpec

for r_idx = 1:N_reg
    pe_1 = T1_SS1{1, r_idx};
    ge_1 = T1_SS1{2, r_idx};
    ig_1 = T1_SS1{3, r_idx};

    pe_2 = T1_SS2{1, r_idx};
    ge_2 = T1_SS2{2, r_idx};
    ig_2 = T1_SS2{3, r_idx};

    % Total Phase-2 long-run dividend lift above SS1
    d_ss2_ge = max(0, ge_2 - ge_1);
    d_ss2_ig = max(0, ig_2 - ig_1);

    for c_i = 1:N_coh
        yr = Cohort_Years(c_i);

        % --- Base SS0 -> SS1 Trajectory (With Te Kāhui Waka Wave Sequencing & Learning Curve) ---
        if yr < 0
            ce_base = 0.25 * pe_1 * exp(yr / 15);
        elseif yr < 20
            if is_kahui_mode
                % Armada: Smooth 13-wave echelon ramp + PDSA inter-wave learning acceleration
                yr_eff = max(0.0, yr - 0.35 * t_kahui_lag(r_idx));
                w_ge   = (1 - exp(-yr_eff / 9.2)) * (0.88 + 0.12 * (1 - exp(-yr / 5.5)));
            else
                w_ge   = 1 - exp(-yr / 10);
            end
            ce_base = pe_1 + min(1.0, w_ge) * (ge_1 - pe_1);
        else
            w_ig    = 1 - exp(-(yr - 20) / 12);
            ce_base = ge_1 + w_ig * (ig_1 - ge_1);
        end

        if ~has_SS2
            CE_Cohort(c_i, r_idx)     = ce_base;
            CE_Cohort_MIT(c_i, r_idx) = ce_base;
        else
            % --- Multiphase SS0 -> SS1 -> SS2 Trajectory ---
            % 1. Unannounced MIT Shock at T_phase2_yr (no anticipation prior to T_phase2_yr):
            if yr < T_phase2_yr
                ce_mit = ce_base;
            else
                w_p2   = 1 - exp(-(yr - T_phase2_yr) / 10);
                ce_mit = ce_base + w_p2 * d_ss2_ig;
            end
            CE_Cohort_MIT(c_i, r_idx) = ce_mit;

            % 2. Announced / Credibility-Weighted Trajectory:
            % Cohorts entering adulthood before T_phase2_yr still spend (45 - (T_phase2_yr - yr)) working years
            % inside Phase 2 (lower PAYE tax tau_l and higher infrastructure wages w_reg), Plus parents
            % internalize higher future returns via dynastic slope alpha_1,t!
            if yr < 0
                ce_ann = ce_base;
            elseif yr < T_phase2_yr
                % Fraction of adult working life spent in Phase 2 (after T_phase2_yr)
                rem_career_share = max(0, 1 - (T_phase2_yr - yr) / 35);
                if strcmpi(Phase2_Announcement_Mode, 'PreAnnounced')
                    lam_c = 1.0;
                elseif strcmpi(Phase2_Announcement_Mode, 'EarnedCred')
                    lam_c = 0.25 + 0.75 * (yr / T_phase2_yr)^1.5;
                else
                    lam_c = 0.0;
                end
                ce_ann = ce_base + lam_c * 0.55 * rem_career_share * d_ss2_ge;
            else
                w_p2   = 1 - exp(-(yr - T_phase2_yr) / 9);
                ce_ann = ce_base + 0.55 * d_ss2_ge + w_p2 * (d_ss2_ig - 0.55 * d_ss2_ge);
            end
            CE_Cohort(c_i, r_idx) = ce_ann;
        end
    end
end

%% 4. KIYOTAKI HOUSING USER-COST COOLING, $1.6T ESTATE REALLOCATION & BRAIN-DRAIN CLOSURE
Q_path         = zeros(T_trans, N_reg);
Q_init         = Params.Trans_Q_init;
Q_end_SS1      = Q_init .* Params.Q_mult_SS1;
Q_end_SS2      = Q_init .* Params.Q_mult_SS2;

Emig_Rate_Path = zeros(T_trans, N_reg);
Emig_0         = Params.Trans_Emig_0;
Emig_SS1       = Params.Trans_Emig_SS1;
Emig_SS2       = Params.Trans_Emig_SS2;

for t = 1:T_trans
    yr   = Trans_Years(t);
    w_q1 = 1 - exp(-yr / 14);
    w_e1 = 1 / (1 + exp(-(yr - 18) / 6));

    q_t = Q_init + w_q1 * (Q_end_SS1 - Q_init);
    e_t = Emig_0 + w_e1 * (Emig_SS1  - Emig_0);

    if has_SS2
        if yr >= T_phase2_yr
            w_q2 = 1 - exp(-(yr - T_phase2_yr) / 12);
            w_e2 = 1 - exp(-(yr - T_phase2_yr) / 8);
            q_t  = q_t + w_q2 * (Q_end_SS2 - Q_end_SS1);
            e_t  = e_t + w_e2 * (Emig_SS2  - Emig_SS1);
        elseif strcmpi(Phase2_Announcement_Mode, 'PreAnnounced') && yr > 0
            % Forward-looking Stage-3 Gumbel sorting prices in Phase-2 PAYE cut before T_phase2_yr
            w_ant = 0.35 * (yr / T_phase2_yr);
            e_t   = e_t + w_ant * (Emig_SS2 - Emig_SS1);
        end
    end
    Q_path(t, :)         = q_t;
    Emig_Rate_Path(t, :) = e_t;
end

if ~has_SS2
    Cohesion_Index = 100 + 22 * (1 ./ (1 + exp(-(Trans_Years - 20) / 6)));
else
    Cohesion_Index = 100 + 22 * (1 ./ (1 + exp(-(Trans_Years - 20) / 6))) + ...
        9 * (1 ./ (1 + exp(-(Trans_Years - (T_phase2_yr + 5)) / 5)));
end

Years_grid    = Trans_Years(:);
Emig_path     = 100 * Emig_Rate_Path;
Nat_Emig_path = sum(s_HH_path .* Emig_path, 2);
Cohesion_St   = Cohesion_Index(:);

emig_cols_bd = cellfun(@(r) [r, '_Emig_Pct'], Regions, 'UniformOutput', false);
T_BrainDrain_Path = array2table([Trans_Years, 100 * Emig_Rate_Path, Cohesion_Index], ...
    'VariableNames', [{'Year'}, emig_cols_bd, {'Social_Cohesion_Index'}]);

ce_cols     = cellfun(@(r) ['CE_', r, '_Pct'],     Regions, 'UniformOutput', false);
ce_mit_cols = cellfun(@(r) ['CE_MIT_', r, '_Pct'], Regions, 'UniformOutput', false);
T_CohortWelfare = array2table([Cohort_Years(:), CE_Cohort, CE_Cohort_MIT], ...
    'VariableNames', [{'Cohort_Birth_Or_Entry_Year'}, ce_cols, ce_mit_cols]);

pop_cols = cellfun(@(r) [r, '_PopShare_Pct'], Regions, 'UniformOutput', false);
q_cols   = cellfun(@(r) [r, '_Q_Index'],      Regions, 'UniformOutput', false);
T_PopShares = array2table([Years_grid, 100 * s_HH_path, Q_path], ...
    'VariableNames', [{'Year'}, pop_cols, q_cols]);

%% 5. PACK PURE TRANSITION OUTPUT STRUCT
TransOut = struct();
TransOut.Regions                  = Regions;
TransOut.dt                       = dt;
TransOut.T_years                  = T_years;
TransOut.T_trans                  = T_trans;
TransOut.Trans_Years              = Trans_Years;
TransOut.Years_grid               = Years_grid;
TransOut.has_SS2                  = has_SS2;
TransOut.ContingencySpec_Trans    = ContingencySpec_Trans;
TransOut.GateEval_Trans           = GateEval_Trans;
TransOut.T_phase2_yr              = T_phase2_yr;
TransOut.Phase2_Announcement_Mode = Phase2_Announcement_Mode;
TransOut.s_HH_path                = s_HH_path;
TransOut.T1_SS1                   = T1_SS1;
TransOut.T1_SS2                   = T1_SS2;
TransOut.Cohort_Years             = Cohort_Years;
TransOut.CE_Cohort                = CE_Cohort;
TransOut.CE_Cohort_MIT            = CE_Cohort_MIT;
TransOut.Q_path                   = Q_path;
TransOut.Emig_Rate_Path           = Emig_Rate_Path;
TransOut.Emig_path                = Emig_path;
TransOut.Nat_Emig_path            = Nat_Emig_path;
TransOut.Cohesion_Index           = Cohesion_Index;
TransOut.Cohesion_St              = Cohesion_St;
% Vectorized NDC Abatement, Pine-Saturation Cliff (Yr 25), & Clean-Green Trade Path (0 loops!):
SecSpec_TP      = Load_Sectoral_Exergy_Spec(Params.Profile_ID);
NDC_TP          = SecSpec_TP.NDC;
yr_col          = Trans_Years(:);
w_q1_col        = 1.0 - exp(-yr_col / 14.0);
w_p2_col        = double(has_SS2) .* (yr_col >= T_phase2_yr) .* (1.0 - exp(-max(0.0, yr_col - T_phase2_yr) / 10.0));
E_NDC_cap_path  = 1.00 - 0.35 * w_q1_col - 0.43 * w_p2_col;
theta_ag_path   = 0.50 * w_q1_col + 0.50 * w_p2_col;
kappa_pine_path = max(0.0, 1.00 - 0.75 * w_q1_col - 0.25 * w_p2_col);
S_pine_path     = 0.18 * kappa_pine_path .* exp(-0.085 * max(0.0, yr_col - T_phase2_yr));
S_native_path   = 0.14 * (1.0 - kappa_pine_path) .* min(1.0, yr_col / max(1.0, T_phase2_yr));
E_gross_path    = 1.00 - 0.28 * w_q1_col - 0.40 * w_p2_col;
E_net_dom_path  = max(0.15, E_gross_path - (S_pine_path + S_native_path));
ndc_gap_path    = max(0.0, (E_net_dom_path - E_NDC_cap_path) ./ max(0.10, E_NDC_cap_path));
Pi_trade_path   = 1.0 + theta_ag_path * NDC_TP.pi_green_reg - ndc_gap_path * NDC_TP.chi_CBAM_reg;
r_bond_path     = 0.042 + 0.0045 * ndc_gap_path - 0.0060 * w_p2_col;

T_NDC_Path = table(yr_col, E_gross_path, S_pine_path, S_native_path, ...
    E_net_dom_path, E_NDC_cap_path, ndc_gap_path, theta_ag_path, r_bond_path, ...
    Pi_trade_path(:, 1), Pi_trade_path(:, 2), Pi_trade_path(:, 3), Pi_trade_path(:, 4), ...
    'VariableNames', {'Year', 'E_Gross', 'S_Pine', 'S_Native', ...
    'E_Net_Dom', 'E_NDC_Cap', 'NDC_Gap_Ratio', 'Theta_Ag', 'r_Bond', ...
    sprintf('Pi_Trade_%s', Params.Regions{1}), sprintf('Pi_Trade_%s', Params.Regions{2}), ...
    sprintf('Pi_Trade_%s', Params.Regions{3}), sprintf('Pi_Trade_%s', Params.Regions{4})});

TransOut.T_BrainDrain_Path        = T_BrainDrain_Path;
TransOut.T_NDC_Path               = T_NDC_Path;
TransOut.Pi_trade_path            = Pi_trade_path;
TransOut.E_NDC_cap_path           = E_NDC_cap_path;
TransOut.E_net_dom_path           = E_net_dom_path;
TransOut.S_pine_path              = S_pine_path;
TransOut.S_native_path            = S_native_path;
TransOut.r_bond_path              = r_bond_path;
TransOut.T_CohortWelfare          = T_CohortWelfare;
TransOut.T_PopShares              = T_PopShares;

end
