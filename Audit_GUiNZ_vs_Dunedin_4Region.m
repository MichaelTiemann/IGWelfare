% ==============================================================================
% Audit_GUiNZ_vs_Dunedin_4Region.m
% Document 2: Zero-VFI Stationary Measure Re-Weighting across 4 Regions + Abroad
% Compares the 1972-73 Dunedin Cohort Baseline against the 2009-10 GUiNZ Cohort
% Compatible with both MATLAB and GNU Octave (VFI Toolkit 'octave' branch)
%
% Optional inputs (empty or absent -> the documented defaults below are used):
%   StationaryDist_SS0 / StationaryDist_SS2 : 20-element birth-vigintile mass
%       under SS0 / SS2 (normalised to sum to 1). SS0 weights the Dunedin and
%       GUiNZ corner shares and drag sums; SS2 weights the SS2 corner share.
%       Any other size is ignored with a warning (defaults used).
%   Params (struct; every field optional, default in brackets):
%       Cost_5Yr_Package [9.18]   NPV_Dunedin [35.25]   NPV_PassThrough [0.52]
%       National_Drag_Target [17.70]   Drag_Nat_SS2 [4.20]
%       Abroad_Drain_Pct [19.3 23.4 7.6]   PAYE_Drift_Pct [28.2 30.4 18.5]
%       OutFile ['guinz_vs_dunedin_4region_audit.csv'; '' skips the CSV]
% ==============================================================================

function AuditResults = Audit_GUiNZ_vs_Dunedin_4Region(StationaryDist_SS0, StationaryDist_SS2, Params)

if nargin < 1
    StationaryDist_SS0 = [];
end
if nargin < 2
    StationaryDist_SS2 = [];
end
if nargin < 3 || ~isstruct(Params)
    Params = struct();
end

% Canonical 5D Spatial Structure: 4 Domestic Regions + Abroad
RegionNames = {'Rural', 'Small_Urban', 'Large_Urban', 'Auckland', 'Abroad'};
DomesticWeights = [0.16, 0.24, 0.27, 0.33, 0.00]; % Share of domestic Gate 1 births

% Regional private-rental transience rate nu_r (>45% national rental churn before age 5)
% Higher in Auckland and Large Urban due to 3.1x price-to-income ratios
Nu_Regional_1972  = [0.04, 0.05, 0.06, 0.08, 0.00];
Nu_Regional_2010  = [0.18, 0.22, 0.26, 0.31, 0.00];
Zeta_Haircut      = 0.96; % Calibration scalar mapping nu_r to gamma_1 erosion

% 20 Birth Vigintiles (v = 1..20, 5.0% population mass each)
Vigintiles = (1:20)';
Pi_v = ones(20, 1) / 20.0;
Pi_SS0 = local_vigintile_mass(StationaryDist_SS0, Pi_v, 'StationaryDist_SS0');
Pi_SS2 = local_vigintile_mass(StationaryDist_SS2, Pi_v, 'StationaryDist_SS2');
Wt_SS0 = numel(Pi_SS0) * Pi_SS0; % relative vigintile weight (= 1 each at the uniform default)

% Probability of binding at the Stone-Geary zero-cash-investment corner Pr(i_c* = 0)
% 1972 Dunedin Baseline: 22.0% aggregate vulnerability (concentrated in v = 1..4)
Pr_Corner_Dunedin = [ ...
    0.95; 0.85; 0.85; 0.75; 0.45; ...
    0.25; 0.12; 0.12; 0.05; 0.05; ...
    0.01; 0.01; 0.01; 0.01; 0.01; ...
    0.01; 0.01; 0.01; 0.01; 0.01  ...
    ];

% 2010 GUiNZ Empirical Reality: 14.3% acute persistent material hardship (v = 1..3)
% + 15.7% moderate hardship & private-rental squeeze (v = 4..6) = 30.0% exposure
Pr_Corner_GUiNZ = [ ...
    0.99; 0.95; 0.95; 0.90; 0.82; ...
    0.72; 0.32; 0.32; 0.12; 0.12; ...
    0.02; 0.02; 0.02; 0.02; 0.02; ...
    0.02; 0.02; 0.02; 0.02; 0.02  ...
    ];

% SS2 Foil-Borne Equilibrium (Universal In-Kind ECE + Land-Tax Rent Cooling + Solar)
Pr_Corner_SS2 = [ ...
    0.08; 0.05; 0.05; 0.03; 0.02; ...
    0.01; 0.00; 0.00; 0.00; 0.00; ...
    0.00; 0.00; 0.00; 0.00; 0.00; ...
    0.00; 0.00; 0.00; 0.00; 0.00  ...
    ];

% Regional transience haircut on early skill self-productivity gamma_1
Mean_Haircut_1972 = DomesticWeights * Nu_Regional_1972' * Zeta_Haircut;
Mean_Haircut_2010 = DomesticWeights * Nu_Regional_2010' * Zeta_Haircut;

Haircut_Vec_1972 = zeros(20, 1);
Haircut_Vec_1972(1:4) = 0.06;
Haircut_Vec_1972(5:20) = 0.01;

Haircut_Vec_2010 = zeros(20, 1);
Haircut_Vec_2010(1:6)  = 0.25; % Bottom 30% exposed to high private-rental churn
Haircut_Vec_2010(7:10) = 0.10;
Haircut_Vec_2010(11:20) = 0.02;

Haircut_Vec_SS2 = zeros(20, 1); % SS2 removes the private-rental transience haircut

% Annualized remediation fiscal incidence (health, state care, justice) in NZD thousands
Drag_Raw_Dunedin = 80.5 .* Pr_Corner_Dunedin .* (1.0 + Haircut_Vec_1972);
Drag_Raw_GUiNZ   = 95.0 .* Pr_Corner_GUiNZ   .* (1.0 + Haircut_Vec_2010);
Drag_Raw_SS2     = 14.0 .* Pr_Corner_SS2     + 1.85;

% Scale to national aggregate baseline (NZD 17.70B/yr under 1972 Dunedin weights)
National_Drag_Target = local_param(Params, 'National_Drag_Target', 17.70);
Scale_National   = National_Drag_Target / sum(Wt_SS0 .* Drag_Raw_Dunedin);
Drag_Nat_Dunedin = sum(Wt_SS0 .* Drag_Raw_Dunedin) * Scale_National;
Drag_Nat_GUiNZ   = sum(Wt_SS0 .* Drag_Raw_GUiNZ)   * Scale_National;
Drag_Nat_SS2     = local_param(Params, 'Drag_Nat_SS2', 4.20); % Canonical SS2 remediation floor

% 4-Region + Abroad Spatial Decomposition of Remediation Drag (NZD Billions/yr)
% Abroad (5th dimension) absorbs 0% of domestic remediation expenditure but captures
% outbound skilled graduate migration under unbuffered SS0 (19.3%-23.4% metro exile)
Regional_Vulnerability_Share = [0.21, 0.25, 0.24, 0.30, 0.00];
Regional_Drag_Dunedin = Drag_Nat_Dunedin .* Regional_Vulnerability_Share;
Regional_Drag_GUiNZ   = Drag_Nat_GUiNZ   .* Regional_Vulnerability_Share;
Regional_Drag_SS2     = Drag_Nat_SS2     .* Regional_Vulnerability_Share;

% Year-5 ACC Actuarial Liability Release (2.0% real SRTP over 81-year lifecycle)
Cost_5Yr_Package = local_param(Params, 'Cost_5Yr_Package', 9.18); % NZD Billions
NPV_Dunedin      = local_param(Params, 'NPV_Dunedin', 35.25);
NPV_PassThrough  = local_param(Params, 'NPV_PassThrough', 0.52);
NPV_GUiNZ        = NPV_Dunedin + (Drag_Nat_GUiNZ - Drag_Nat_Dunedin) * NPV_PassThrough;
Mult_Dunedin     = NPV_Dunedin / Cost_5Yr_Package;
Mult_GUiNZ       = NPV_GUiNZ   / Cost_5Yr_Package;

% Printed-only quantities (percent). Haircut = Vigintile-1 value of each Haircut_Vec;
% Abroad drain and 2050 PAYE drift have no in-script model, so they are typed defaults
% (override via Params.Abroad_Drain_Pct / Params.PAYE_Drift_Pct) ordered [Dunedin GUiNZ SS2].
Haircut_Pct      = 0 - 100 * [Haircut_Vec_1972(1), Haircut_Vec_2010(1), Haircut_Vec_SS2(1)];
Abroad_Drain_Pct = local_param(Params, 'Abroad_Drain_Pct', [19.3, 23.4, 7.6]);
PAYE_Drift_Pct   = local_param(Params, 'PAYE_Drift_Pct',   [28.2, 30.4, 18.5]);

% Package results struct for downstream consumption by Compute_Actuarial_NPV_4Region.m
AuditResults = struct();
AuditResults.Vigintiles            = Vigintiles;
AuditResults.CornerShare_Dunedin   = sum(Pi_SS0 .* Pr_Corner_Dunedin);
AuditResults.CornerShare_GUiNZ     = sum(Pi_SS0 .* Pr_Corner_GUiNZ);
AuditResults.CornerShare_SS2       = sum(Pi_SS2 .* Pr_Corner_SS2);
AuditResults.NationalDrag_Dunedin  = Drag_Nat_Dunedin;
AuditResults.NationalDrag_GUiNZ    = Drag_Nat_GUiNZ;
AuditResults.NationalDrag_SS2      = Drag_Nat_SS2;
AuditResults.RegionNames           = RegionNames;
AuditResults.RegionalDrag_Dunedin  = Regional_Drag_Dunedin;
AuditResults.RegionalDrag_GUiNZ    = Regional_Drag_GUiNZ;
AuditResults.RegionalDrag_SS2      = Regional_Drag_SS2;
AuditResults.ActuarialMult_Dunedin = Mult_Dunedin;
AuditResults.ActuarialMult_GUiNZ   = Mult_GUiNZ;
AuditResults.Cost_5Yr_Package      = Cost_5Yr_Package;
AuditResults.NPV_Dunedin           = NPV_Dunedin;
AuditResults.NPV_GUiNZ             = NPV_GUiNZ;

% Console Reporting
fprintf('====================================================================================\n');
fprintf('DOCUMENT 2 AUDIT: 1972 DUNEDIN BASELINE VS. 2010 GUiNZ COHORT DRIFT (4R + ABROAD)\n');
fprintf('====================================================================================\n');
fprintf('Metric / Equilibrium State                    | 1972 Dunedin |   2010 GUiNZ |  SS2 Optimal\n');
fprintf('------------------------------------------------------------------------------------\n');
fprintf('Stone-Geary Corner Share Pr(i_c* = 0)         |       %5.1f%% |       %5.1f%% |       %5.1f%%\n', ...
    AuditResults.CornerShare_Dunedin * 100, AuditResults.CornerShare_GUiNZ * 100, AuditResults.CornerShare_SS2 * 100);
fprintf('Private-Rental Transience Haircut (Vig 1-6)   |       %5.1f%% |       %5.1f%% |       %5.1f%%\n', ...
    Haircut_Pct(1), Haircut_Pct(2), Haircut_Pct(3));
fprintf('National Remediation Drag (NZD Billions/yr)   |     NZD %4.1fB |     NZD %4.1fB |     NZD %4.1fB\n', ...
    Drag_Nat_Dunedin, Drag_Nat_GUiNZ, Drag_Nat_SS2);
fprintf('  - Region 1: Rural (%2.0f%% births)              |     NZD %4.2fB |     NZD %4.2fB |     NZD %4.2fB\n', ...
    100 * DomesticWeights(1), Regional_Drag_Dunedin(1), Regional_Drag_GUiNZ(1), Regional_Drag_SS2(1));
fprintf('  - Region 2: Small Urban (%2.0f%% births)        |     NZD %4.2fB |     NZD %4.2fB |     NZD %4.2fB\n', ...
    100 * DomesticWeights(2), Regional_Drag_Dunedin(2), Regional_Drag_GUiNZ(2), Regional_Drag_SS2(2));
fprintf('  - Region 3: Large Urban (%2.0f%% births)        |     NZD %4.2fB |     NZD %4.2fB |     NZD %4.2fB\n', ...
    100 * DomesticWeights(3), Regional_Drag_Dunedin(3), Regional_Drag_GUiNZ(3), Regional_Drag_SS2(3));
fprintf('  - Region 4: Auckland (%2.0f%% births)           |     NZD %4.2fB |     NZD %4.2fB |     NZD %4.2fB\n', ...
    100 * DomesticWeights(4), Regional_Drag_Dunedin(4), Regional_Drag_GUiNZ(4), Regional_Drag_SS2(4));
fprintf('  - Dimension 5: Abroad (Metro Graduate Drain)|       %5.1f%% |       %5.1f%% |       %5.1f%%\n', ...
    Abroad_Drain_Pct(1), Abroad_Drain_Pct(2), Abroad_Drain_Pct(3));
fprintf('2050 Steady-State PAYE Income Tax Drift       |       %5.1f%% |       %5.1f%% |       %5.1f%%\n', ...
    PAYE_Drift_Pct(1), PAYE_Drift_Pct(2), PAYE_Drift_Pct(3));
fprintf('Year-5 ACC Actuarial Return Multiple          |        %4.2fx |        %4.2fx |    Locked In\n', ...
    Mult_Dunedin, Mult_GUiNZ);
fprintf('====================================================================================\n');

% Export CSV table for automated monograph table generation
OutFile = 'guinz_vs_dunedin_4region_audit.csv';
if isfield(Params, 'OutFile')
    OutFile = Params.OutFile; % '' skips the CSV
end
fid = -1;
if ~isempty(OutFile)
    fid = fopen(OutFile, 'w');
end
if fid ~= -1
    fprintf(fid, 'vigintile,pr_corner_dunedin_1972,pr_corner_guinz_2010,pr_corner_ss2,transience_haircut_guinz,drag_nzd_k_dunedin,drag_nzd_k_guinz,drag_nzd_k_ss2\n');
    for v = 1:20
        fprintf(fid, '%d,%.3f,%.3f,%.3f,%.3f,%.2f,%.2f,%.2f\n', ...
            v, Pr_Corner_Dunedin(v), Pr_Corner_GUiNZ(v), Pr_Corner_SS2(v), ...
            Haircut_Vec_2010(v), Drag_Raw_Dunedin(v), Drag_Raw_GUiNZ(v), Drag_Raw_SS2(v));
    end
    fclose(fid);
end


end

function v = local_param(Params, name, default)
% Params.(name) if present and non-empty, else the documented default
if isfield(Params, name) && ~isempty(Params.(name))
    v = Params.(name);
else
    v = default;
end
end

function Pi = local_vigintile_mass(D, Pi_default, label)
% 20-element non-negative mass -> normalised column; empty/other -> default
Pi = Pi_default;
if isempty(D)
    return
end
if isnumeric(D) && numel(D) == numel(Pi_default) && all(D(:) >= 0) && sum(D(:)) > 0
    Pi = D(:) / sum(D(:));
else
    warning('Audit_GUiNZ_vs_Dunedin_4Region:input', ...
        '%s is not a 20-element non-negative vigintile mass; using the uniform default.', label);
end
end
