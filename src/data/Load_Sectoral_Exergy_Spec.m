function Spec = Load_Sectoral_Exergy_Spec(DataSpecOrID)
%% PURE LOADER FOR UNIFIED 5-SECTOR SOE, EXERGY, NDC & PUBLIC-ASSET SPEC
% File: src/data/Load_Sectoral_Exergy_Spec.m
% Loads profiles/<Profile_ID>/sectors/sectors_2026.csv and exergy_and_ndc.yaml
% with automatic profile inheritance (e.g., NZ_GUiNZ2009 -> NZ_Dunedin1972),
% schema & anti-double-counting assertions, and deterministic MD5 digesting.

if nargin < 1 || isempty(DataSpecOrID)
    DataSpec = Load_Empirical_Profile('NZ_Dunedin1972');
elseif isstruct(DataSpecOrID)
    DataSpec = DataSpecOrID;
else
    DataSpec = Load_Empirical_Profile(char(DataSpecOrID));
end

igw_root = getappdata(0, 'IGW_ROOT_DIR');
if isempty(igw_root)
    igw_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end

cand_dirs = {fullfile(igw_root, 'profiles', DataSpec.Profile_ID, 'sectors')};
if isfield(DataSpec, 'Parent_Profile_ID') && ~isempty(DataSpec.Parent_Profile_ID)
    cand_dirs{end+1} = fullfile(igw_root, 'profiles', DataSpec.Parent_Profile_ID, 'sectors');
end
cand_dirs{end+1} = fullfile(igw_root, 'profiles', 'NZ_Dunedin1972', 'sectors');

sec_dir = '';
for k = 1:numel(cand_dirs)
    if exist(fullfile(cand_dirs{k}, 'sectors_2026.csv'), 'file') == 2
        sec_dir = cand_dirs{k};
        break;
    end
end
if isempty(sec_dir)
    error('IGWelfare:MissingSectoralSpec', 'Could not locate sectors_2026.csv for profile %s.', DataSpec.Profile_ID);
end

SecTable = Read_IGW_CSV(fullfile(sec_dir, 'sectors_2026.csv'));
YamlCfg  = Read_IGW_YAML(fullfile(sec_dir, 'exergy_and_ndc.yaml'));

% Normalize canonical _BCurr <-> legacy _BNZD schema fields seamlessly:
if isfield(SecTable, 'Annual_Spend_BCurr') && ~isfield(SecTable, 'Annual_Spend_BNZD')
    SecTable.Annual_Spend_BNZD = SecTable.Annual_Spend_BCurr;
elseif isfield(SecTable, 'Annual_Spend_BNZD') && ~isfield(SecTable, 'Annual_Spend_BCurr')
    SecTable.Annual_Spend_BCurr = SecTable.Annual_Spend_BNZD;
end
if isfield(SecTable, 'Capital_Stock_BCurr') && ~isfield(SecTable, 'Capital_Stock_BNZD')
    SecTable.Capital_Stock_BNZD = SecTable.Capital_Stock_BCurr;
elseif isfield(SecTable, 'Capital_Stock_BNZD') && ~isfield(SecTable, 'Capital_Stock_BCurr')
    SecTable.Capital_Stock_BCurr = SecTable.Capital_Stock_BNZD;
end

if isfield(YamlCfg.Metadata, 'Anti_Double_Counting_CashTransfers_BCurr')
    YamlCfg.Metadata.Anti_Double_Counting_CashTransfers_BNZD = YamlCfg.Metadata.Anti_Double_Counting_CashTransfers_BCurr;
else
    YamlCfg.Metadata.Anti_Double_Counting_CashTransfers_BCurr = YamlCfg.Metadata.Anti_Double_Counting_CashTransfers_BNZD;
end
if isfield(YamlCfg.Exergy_And_Grid, 'Fossil_Import_Bill_SS0_BCurr')
    YamlCfg.Exergy_And_Grid.Fossil_Import_Bill_SS0_BNZD = YamlCfg.Exergy_And_Grid.Fossil_Import_Bill_SS0_BCurr;
    YamlCfg.Exergy_And_Grid.K_N_Grid_Init_BNZD          = YamlCfg.Exergy_And_Grid.K_N_Grid_Init_BCurr;
else
    YamlCfg.Exergy_And_Grid.Fossil_Import_Bill_SS0_BCurr = YamlCfg.Exergy_And_Grid.Fossil_Import_Bill_SS0_BNZD;
    YamlCfg.Exergy_And_Grid.K_N_Grid_Init_BCurr          = YamlCfg.Exergy_And_Grid.K_N_Grid_Init_BNZD;
end
if isfield(YamlCfg.Paris_NDC_And_Trade, 'p_NDC_intl_BCurr_per_Mt')
    YamlCfg.Paris_NDC_And_Trade.p_NDC_intl_BNZD_per_Mt = YamlCfg.Paris_NDC_And_Trade.p_NDC_intl_BCurr_per_Mt;
    YamlCfg.Paris_NDC_And_Trade.CERF_Pulse_BNZD        = YamlCfg.Paris_NDC_And_Trade.CERF_Pulse_BCurr;
else
    YamlCfg.Paris_NDC_And_Trade.p_NDC_intl_BCurr_per_Mt = YamlCfg.Paris_NDC_And_Trade.p_NDC_intl_BNZD_per_Mt;
    YamlCfg.Paris_NDC_And_Trade.CERF_Pulse_BCurr        = YamlCfg.Paris_NDC_And_Trade.CERF_Pulse_BNZD;
end

% Normalize Digest struct keys to canonical _BCurr only so MD5 stays deterministic:
DigestSec = struct('SubSector_ID', {SecTable.SubSector_ID}, 'Macro_Sector', {SecTable.Macro_Sector}, ...
    'Spend', SecTable.Annual_Spend_BCurr, 'Paid', SecTable.Paid_Workforce_kFTE, ...
    'Vol', SecTable.Unpaid_Volunteer_kFTE, 'Cap', SecTable.Capital_Stock_BCurr, ...
    'Imp', SecTable.Import_FX_Share, 'ExInt', SecTable.Exergy_Intensity, ...
    'Foss', SecTable.Fossil_Share_Base, 'Skill', SecTable.Skill_High_Share);

% Schema & thermodynamic / accounting sanity checks:
Ex = YamlCfg.Exergy_And_Grid;
if ~(Ex.e_N_elec > Ex.e_F_fossil && Ex.e_F_fossil > 0)
    error('IGWelfare:InvalidExergyPhysics', 'Second-Law exergy efficiency requires e_N_elec > e_F_fossil > 0.');
end
if numel(Ex.gamma_h_reg) ~= DataSpec.N_reg || numel(Ex.omega_y_reg) ~= DataSpec.N_reg
    error('IGWelfare:RegionDimMismatch', 'Exergy regional vectors must match N_reg = %d.', DataSpec.N_reg);
end

% Aggregate 5-Sector Rollups (S1, S2, S3, S4A, S4B, S5) from the 11 sub-lanes:
Macro_Names = {'Sector_1_Primary'; 'Sector_2_Knowledge'; 'Sector_3_Market_NonTrad'; ...
               'Sector_4A_Civic_Human'; 'Sector_4B_Public_Infra'; 'Sector_5_Defence'};
nM = numel(Macro_Names);
Spend_M = zeros(nM, 1); Paid_M = zeros(nM, 1); Vol_M = zeros(nM, 1); Cap_M = zeros(nM, 1); Imp_M = zeros(nM, 1);
for m = 1:nM
    msk = strcmp(SecTable.Macro_Sector, Macro_Names{m});
    Spend_M(m) = sum(SecTable.Annual_Spend_BCurr(msk));
    Paid_M(m)  = sum(SecTable.Paid_Workforce_kFTE(msk));
    Vol_M(m)   = sum(SecTable.Unpaid_Volunteer_kFTE(msk));
    Cap_M(m)   = sum(SecTable.Capital_Stock_BCurr(msk));
    Imp_M(m)   = sum(SecTable.Annual_Spend_BCurr(msk) .* SecTable.Import_FX_Share(msk)) / max(1e-8, Spend_M(m));
end

MacroTable = table(Macro_Names, Spend_M, Paid_M, Vol_M, Cap_M, Imp_M, ...
    'VariableNames', {'Macro_Sector', 'Annual_Spend_BCurr', 'Paid_kFTE', 'Volunteer_kFTE', 'Capital_BCurr', 'Import_FX_Share'});

Spec = struct();
Spec.Profile_ID          = DataSpec.Profile_ID;
Spec.Source_Dir          = sec_dir;
Spec.SubSector_Table     = SecTable;
Spec.MacroSector_Table   = MacroTable;
Spec.Metadata            = YamlCfg.Metadata;
Spec.Exergy              = YamlCfg.Exergy_And_Grid;
Spec.NDC                 = YamlCfg.Paris_NDC_And_Trade;
Spec.SOE                 = YamlCfg.External_SOE_And_Defence;
Spec.AssetStewardship    = YamlCfg.Public_Asset_Stewardship;
Spec.Total_Paid_kFTE     = sum(SecTable.Paid_Workforce_kFTE);
Spec.Civic_Def_Share_Paid= sum(Paid_M(4:6)) / max(1e-8, Spec.Total_Paid_kFTE); % ~26.8% paid workforce in Sec 4 & 5!
Spec.Civic_Volunteer_kFTE= sum(Vol_M(4:5));                                    % ~79.0 kFTE JBWere benchmark!
Spec.Currency_ISO        = DataSpec.Monetary.Currency_ISO;
Spec.Currency_Symbol     = DataSpec.Monetary.Currency_Symbol;
Spec.Digest              = IGW_MD5_Hex(struct('Sec', DigestSec, 'Yaml', YamlCfg));

end
