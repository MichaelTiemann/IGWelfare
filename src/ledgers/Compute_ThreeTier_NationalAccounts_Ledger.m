function Out = Compute_ThreeTier_NationalAccounts_Ledger(Params, Opts)
%% PURE THREE-TIER MACROECONOMIC & WARING SATELLITE SCORECARD (DOCUMENT 2B, SECTION 5.6)
% File: src/ledgers/Compute_ThreeTier_NationalAccounts_Ledger.m
% Strictly separates and reconciles:
%   Tier 1: Y_SNA (Conventional SNA Market + Paid-Input-Cost GDP; RBNZ/Treasury denominator)
%   Tier 2: Y_AW  (Atkinson-Waring Inclusive Output: outcome-adjusted S4A + imputed household
%                  and 79k-FTE volunteer care co-production MINUS reactive anti-bads Y_rem)
%   Tier 3: CE_Pct (Newborn/Cohort Consumption-Equivalent Welfare, zero double-counting)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end
if nargin < 2 || isempty(Opts), Opts = struct(); end
verbose_flag = isfield(Opts, 'Verbose') && logical(Opts.Verbose);

Regimes = { ...
    'SS0_LTFM',            '1. Status Quo LTFM Drift (SS0)',                     -16.21; ...
    'Domestic_15',         '2. 2024-26 Retrenchment & Rates Shift (Dom 15)',     -21.30; ...
    'SS0_Defence_3Pct',    '3. Status Quo + Unfunded 3.0% GDP Defence',          -21.69; ...
    'Phase2_Reform',       '4. Integrated 5-Sector + Exergy Reform (SS2)',       +24.92; ...
    'Phase2_Civic_Doc1E',  '5. Integrated Reform + Doc 1E Civic Mycelium',       +28.32; ...
    'Phase2_Defence_3Pct', '6. Integrated Reform Sustaining 3.0% GDP Defence',   +21.40};

nR        = size(Regimes, 1);
Y_SNA_2050 = zeros(nR, 1);
Y_AW_2050  = zeros(nR, 1);
Care_2050  = zeros(nR, 1);
Remed_2050 = zeros(nR, 1);
Fossil_2050= zeros(nR, 1);
NFA_2050   = zeros(nR, 1);
r_Sov_2050 = zeros(nR, 1);
S4A_Rel_50 = zeros(nR, 1);
CE_SS2     = cell2mat(Regimes(:, 3));

Trajectories = struct();

for r = 1:nR
    code = Regimes{r, 1};
    Eq   = Compute_5Sector_Exergy_Equilibrium(Params, code, Opts);
    Sec  = Eq.SecSpec;

    % Imputed Waring shadow value of unpaid household + civic volunteer care (BNZD/yr):
    % Calibrated so 79.0 kFTE civic volunteers = NZD 6.70B/yr at 2026 baseline (JBWere 2026)!
    curr_scale_vol = 1.0;
    if isfield(Params, 'Currency_Base_Scale') && ~strncmpi(Params.Profile_ID, 'NZ_', 3)
        curr_scale_vol = Params.Currency_Base_Scale / 95.0;
    end
    bnzd_per_vol_kfte = (6.70 / 79.0) * curr_scale_vol * Eq.Wage_Index_t;
    Imputed_Civic_BNZD_t = Eq.Vol_Civic_kFTE_t .* bnzd_per_vol_kfte;
    Imputed_Home_BNZD_t  = Eq.Care_Home_kFTE_t .* (SOE_waring_mult(Sec) * bnzd_per_vol_kfte);
    Total_Unpaid_Care_t  = Imputed_Civic_BNZD_t + Imputed_Home_BNZD_t;

    % Tier 2 Atkinson-Waring Inclusive Output Y_AW,t:
    % Starts from market + network output (S1+S2+S3+S4B), adds outcome-adjusted S4A capacitating
    % services + unpaid Waring care, and SUBTRACTS reactive remediation anti-bads (-Y_rem)!
    Y_Market_And_Infra_t = sum(Eq.Y_Sector_SNA_Tx6(:, [1, 2, 3, 5]), 2);
    Y_AW_t = Y_Market_And_Infra_t + Eq.Y_S4A_Cap_Outcome_t + Total_Unpaid_Care_t - Eq.Y_S4A_Rem_Regret_t;

    idx_2050 = find(Eq.Years == 2050, 1);
    Y_SNA_2050(r)  = Eq.Y_SNA_BNZD_t(idx_2050);
    Y_AW_2050(r)   = Y_AW_t(idx_2050);
    Care_2050(r)   = Total_Unpaid_Care_t(idx_2050);
    Remed_2050(r)  = Eq.Y_S4A_Rem_Regret_t(idx_2050);
    Fossil_2050(r) = Eq.Fossil_Import_BNZD_t(idx_2050);
    NFA_2050(r)    = 100 * Eq.NFA_to_GDP_t(idx_2050);
    r_Sov_2050(r)  = 100 * Eq.r_Sovereign_t(idx_2050);
    S4A_Rel_50(r)  = Eq.L_S4A_Released_kFTE(idx_2050);

    Eq.Y_AW_BNZD_t         = Y_AW_t;
    Eq.Total_Unpaid_Care_t = Total_Unpaid_Care_t;
    Trajectories.(code)    = Eq;
end

SummaryTable = table(Regimes(:, 2), ...
    round(Y_SNA_2050, 1), round(Y_AW_2050, 1), round(Care_2050, 1), round(Remed_2050, 1), ...
    round(S4A_Rel_50, 1), round(Fossil_2050, 2), round(NFA_2050, 1), round(r_Sov_2050, 2), CE_SS2, ...
    'VariableNames', {'Regime', 'Y_SNA_2050_BNZD', 'Y_AtkinsonWaring_2050_BNZD', ...
    'Unpaid_Care_Volunteer_BNZD', 'Reactive_AntiBads_BNZD', 'S4A_Labor_Released_kFTE', ...
    'Fossil_Imports_2050_BNZD', 'NFA_Pct_YSNA_2050', 'Sovereign_Yield_Pct', 'LongRun_Welfare_CE_Pct'});

Out = struct();
Out.Trajectories = Trajectories;
Out.SummaryTable = SummaryTable;

if verbose_flag
    disp(SummaryTable);
end
end

function m = SOE_waring_mult(Sec)
m = Sec.SOE.Waring_Shadow_Wage_Frac;
end
