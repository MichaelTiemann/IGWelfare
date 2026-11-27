function DataSpec = Load_Empirical_Profile(Profile_Name)
%% LAYER 1 CONTRACT: PURE, IDEMPOTENT EMPIRICAL DATA & COUNTRY PROFILE LOADER
% File: src/data/Load_Empirical_Profile.m
% Usage:
%   DataSpec = Load_Empirical_Profile('NZ_Dunedin1972');
%   DataSpec = Load_Empirical_Profile('NZ_GUiNZ2009');
%   DataSpec = Load_Empirical_Profile('Dunedin_22');         % Legacy alias supported
%   DataSpec = Load_Empirical_Profile('MetroSqueeze_GUiNZ'); % Legacy alias supported
%
% Supports single-parent profile inheritance via 'Inherits_From' in profile.yaml:
%   - Child profile inherits parent YAML sections and CSV files unless overridden locally.
%   - Computes deterministic MD5 DataSpec.Digest for steady-state cache validation.

persistent cache_map;
if isempty(cache_map)
    cache_map = struct();
end
if nargin < 1 || isempty(Profile_Name)
    Profile_Name = 'NZ_Dunedin1972';
elseif isstruct(Profile_Name)
    if isfield(Profile_Name, 'Profile_ID') && ~isempty(Profile_Name.Profile_ID)
        Profile_Name = Profile_Name.Profile_ID;
    elseif isfield(Profile_Name, 'Profile_Name') && ~isempty(Profile_Name.Profile_Name)
        Profile_Name = Profile_Name.Profile_Name;
    elseif isfield(Profile_Name, 'Calibration_Anchor') && ~isempty(Profile_Name.Calibration_Anchor)
        Profile_Name = Profile_Name.Calibration_Anchor;
    else
        Profile_Name = 'NZ_Dunedin1972';
    end
end
if isstring(Profile_Name)
    Profile_Name = char(Profile_Name);
end
cache_key = regexprep(strtrim(Profile_Name), '[^a-zA-Z0-9_]', '_');
if ~isempty(cache_key) && isvarname(cache_key) && isfield(cache_map, cache_key)
    DataSpec = cache_map.(cache_key);
    return;
end

igw_root     = resolve_igw_root();
profiles_dir = fullfile(igw_root, 'profiles');

% Resolve legacy aliases ('Dunedin_22', 'MetroSqueeze_GUiNZ') or direct directory names
canonical_id = resolve_profile_alias(Profile_Name, profiles_dir);
prof_dir     = fullfile(profiles_dir, canonical_id);
yaml_path    = fullfile(prof_dir, 'profile.yaml');

if exist(yaml_path, 'file') ~= 2
    error('IGWelfare:UnknownProfile', ...
        'Empirical profile "%s" (resolved: "%s") not found at %s.', ...
        Profile_Name, canonical_id, yaml_path);
end

raw_yaml = Read_IGW_YAML(yaml_path);

% Handle single-level inheritance (e.g., NZ_GUiNZ2009 -> NZ_Dunedin1972)
parent_dir = '';
if isfield(raw_yaml, 'Inherits_From') && ~isempty(raw_yaml.Inherits_From)
    parent_id   = resolve_profile_alias(raw_yaml.Inherits_From, profiles_dir);
    parent_dir  = fullfile(profiles_dir, parent_id);
    parent_yaml = Read_IGW_YAML(fullfile(parent_dir, 'profile.yaml'));
    cfg_yaml    = merge_structs(parent_yaml, raw_yaml);
else
    cfg_yaml    = raw_yaml;
end

% Load tabular CSVs (child folder takes precedence over parent folder)
files_cfg = cfg_yaml.Files;
Reg_CSV   = Read_IGW_CSV(resolve_profile_file(files_cfg.Regions_CSV,      prof_dir, parent_dir));
Demo_CSV  = Read_IGW_CSV(resolve_profile_file(files_cfg.Demography_CSV,   prof_dir, parent_dir));
Mig_CSV   = Read_IGW_CSV(resolve_profile_file(files_cfg.Migration_CSV,    prof_dir, parent_dir));
Mom_CSV   = Read_IGW_CSV(resolve_profile_file(files_cfg.Moments_CSV,      prof_dir, parent_dir));
Trans_CSV = Read_IGW_CSV(resolve_profile_file(files_cfg.Trans_Sorting_CSV, prof_dir, parent_dir));

% Assemble standardized DataSpec contract
DataSpec                     = struct();
DataSpec.Profile_ID          = cfg_yaml.Profile_ID;
DataSpec.Legacy_Alias        = get_field_def(cfg_yaml, 'Legacy_Alias', cfg_yaml.Profile_ID);
DataSpec.Cohort_Label        = get_field_def(cfg_yaml, 'Cohort_Label', cfg_yaml.Profile_ID);
DataSpec.Country_Name        = get_field_def(cfg_yaml, 'Country_Name', 'Unknown');
DataSpec.External_Dest_Label = get_field_def(cfg_yaml, 'External_Dest_Label', 'Abroad');
DataSpec.Profile_Dir         = prof_dir;
DataSpec.Parent_Profile_Dir  = parent_dir;

% Spatial topology
Regions               = Reg_CSV.Region_ID(:)'; % 1 x N_reg row cell array of char
N_reg                 = numel(Regions);
DataSpec.Regions      = Regions;
DataSpec.N_reg        = N_reg;
DataSpec.Reg_Names_Plus_Nat = [Regions, {'National'}];
DataSpec.Echelon_Idx  = Reg_CSV.Echelon_Idx(:)';
DataSpec.N_Echelons   = max(DataSpec.Echelon_Idx);

% Identify Primate Metro index (replaces hardcoded HH_Auckland) and Representative Urban index (replaces HH_Urban)
primate_id = get_field_def(cfg_yaml, 'Primate_Region_ID', Regions{end});
primate_ix = find(strcmpi(Regions, primate_id), 1, 'first');
if isempty(primate_ix), primate_ix = N_reg; end
DataSpec.Primate_Region_ID  = Regions{primate_ix};
DataSpec.Primate_Region_Idx = primate_ix;

rep_urb_id = get_field_def(cfg_yaml, 'Representative_Urban_ID', Regions{max(1, N_reg - 1)});
rep_urb_ix = find(strcmpi(Regions, rep_urb_id), 1, 'first');
if isempty(rep_urb_ix), rep_urb_ix = max(1, N_reg - 1); end
DataSpec.Representative_Urban_ID  = Regions{rep_urb_ix};
DataSpec.Representative_Urban_Idx = rep_urb_ix;

% Monetary, Institutional, Regime, and Actuarial sections (strictly validated; zero silent defaults!)
if ~isfield(cfg_yaml, 'Monetary') || ~isfield(cfg_yaml, 'Institutions') || ...
   ~isfield(cfg_yaml, 'Regime_Schedules') || ~isfield(cfg_yaml, 'Actuarial')
    error('IGWelfare:IncompleteProfileSchema', ...
        'Profile "%s" must define Monetary, Institutions, Regime_Schedules, and Actuarial sections in profile.yaml.', ...
        DataSpec.Profile_ID);
end
DataSpec.Monetary         = cfg_yaml.Monetary;
DataSpec.Institutions     = cfg_yaml.Institutions;
DataSpec.Regime_Schedules = cfg_yaml.Regime_Schedules;
DataSpec.Actuarial        = cfg_yaml.Actuarial;
validate_dataspec_schema(DataSpec);

% Regional cross-section vectors (stored as clean [1 x N_reg] row vectors to match Configure_TimeGrid_Params)
Pop_Shares  = Reg_CSV.Pop_Share(:)'  / sum(Reg_CSV.Pop_Share(:));
Firm_Shares = Reg_CSV.Firm_Share(:)' / sum(Reg_CSV.Firm_Share(:));
DataSpec.Pop_Shares   = Pop_Shares;
DataSpec.Firm_Shares  = Firm_Shares;
DataSpec.Reg_Table    = rmfield(Reg_CSV, {'Headers', 'N_Rows'});

% Build N_reg x (N_reg + 1) Gumbel migration utility matrix dynamically from Migration_CSV
u_mig = zeros(N_reg, N_reg + 1);
for c = 1:N_reg
    col_name = ['To_', Regions{c}];
    if ~isfield(Mig_CSV, col_name)
        error('IGWelfare:MigrationColMissing', 'Migration CSV missing column "%s".', col_name);
    end
    u_mig(:, c) = Mig_CSV.(col_name)(:);
end
u_mig(:, N_reg + 1)    = Mig_CSV.To_External(:);
DataSpec.u_target_mig  = u_mig;

% Build Transition Sorting matrices (Pi_dom_SS1, Pi_dom_SS2, Intl_Inflow_Share, Q_init, Emig_0/SS1/SS2)
Pi_SS1 = zeros(N_reg, N_reg);
Pi_SS2 = zeros(N_reg, N_reg);
for c = 1:N_reg
    Pi_SS1(:, c) = Trans_CSV.(['Pi_SS1_', Regions{c}])(:);
    Pi_SS2(:, c) = Trans_CSV.(['Pi_SS2_', Regions{c}])(:);
end
DataSpec.Transition = struct( ...
    'Pi_dom_SS1',        Pi_SS1, ...
    'Pi_dom_SS2',        Pi_SS2, ...
    'Intl_Inflow_Share', Trans_CSV.Intl_Inflow_Share(:)', ...
    'Q_init_trans',      Trans_CSV.Q_init_trans(:)', ...
    'Emig_0',            Trans_CSV.Emig_0(:)', ...
    'Emig_SS1',          Trans_CSV.Emig_SS1(:)', ...
    'Emig_SS2',          Trans_CSV.Emig_SS2(:)');

% 5-year benchmark demographic life table
DataSpec.Demography_5yr = struct( ...
    'Age_Mid',    Demo_CSV.Age_Mid(:)', ...
    'sj',         Demo_CSV.sj(:)', ...
    'fj',         Demo_CSV.fj(:)', ...
    'mig_rate_j', Demo_CSV.mig_rate_j(:)');

% Empirical SMM calibration target moments
DataSpec.TargetMoments = struct( ...
    'Moment_ID',   {Mom_CSV.Moment_ID(:)}, ...
    'Target_Val',  Mom_CSV.Target_Val(:), ...
    'Weight',      Mom_CSV.Weight(:), ...
    'Description', {Mom_CSV.Description(:)});

% Compute deterministic MD5 digest over data payload (excluding local filesystem paths so digest is machine-portable!)
hash_payload = rmfield(DataSpec, {'Profile_Dir', 'Parent_Profile_Dir'});
DataSpec.Digest = compute_struct_md5(hash_payload);
if ~isempty(cache_key) && isvarname(cache_key)
    cache_map.(cache_key) = DataSpec;
end
if isvarname(DataSpec.Profile_ID)
    cache_map.(DataSpec.Profile_ID) = DataSpec;
end

end

%% --- LOCAL HELPERS ---
function igw_root = resolve_igw_root()
igw_root = getappdata(0, 'IGW_ROOT_DIR');
if isempty(igw_root) || exist(fullfile(igw_root, 'profiles'), 'dir') == 0
    here = fileparts(mfilename('fullpath')); % .../src/data
    igw_root = fileparts(fileparts(here));
end
end

function canonical_id = resolve_profile_alias(name_in, profiles_dir)
clean = strtrim(name_in);
if exist(fullfile(profiles_dir, clean, 'profile.yaml'), 'file') == 2
    canonical_id = clean;
    return;
end
% Built-in fast map for legacy Calibration_Anchor names
switch lower(clean)
    case {'dunedin_22', 'dunedin', 'nz_dunedin', 'nz_dunedin1972'}
        canonical_id = 'NZ_Dunedin1972';
        return;
    case {'metrosqueeze_guinz', 'guinz', 'nz_guinz', 'nz_guinz2009'}
        canonical_id = 'NZ_GUiNZ2009';
        return;
end
% Fallback: scan profiles/*/profile.yaml for matching Legacy_Alias or Profile_ID
listing = dir(profiles_dir);
for k = 1:numel(listing)
    if listing(k).isdir && listing(k).name(1) ~= '.'
        yp = fullfile(profiles_dir, listing(k).name, 'profile.yaml');
        if exist(yp, 'file') == 2
            y = Read_IGW_YAML(yp);
            if (isfield(y, 'Legacy_Alias') && strcmpi(y.Legacy_Alias, clean)) || ...
               (isfield(y, 'Profile_ID')   && strcmpi(y.Profile_ID, clean))
                canonical_id = listing(k).name;
                return;
            end
        end
    end
end
canonical_id = clean;
end

function fpath = resolve_profile_file(rel_name, prof_dir, parent_dir)
p1 = fullfile(prof_dir, rel_name);
if exist(p1, 'file') == 2
    fpath = p1;
    return;
end
if ~isempty(parent_dir)
    p2 = fullfile(parent_dir, rel_name);
    if exist(p2, 'file') == 2
        fpath = p2;
        return;
    end
end
error('IGWelfare:MissingProfileAsset', ...
    'Profile asset "%s" not found in %s or parent %s.', rel_name, prof_dir, parent_dir);
end

function out = merge_structs(base_s, over_s)
out = base_s;
fn  = fieldnames(over_s);
for i = 1:numel(fn)
    k = fn{i};
    if isfield(base_s, k) && isstruct(base_s.(k)) && isstruct(over_s.(k)) && numel(over_s.(k)) == 1
        out.(k) = merge_structs(base_s.(k), over_s.(k));
    else
        out.(k) = over_s.(k);
    end
end
end

function val = get_field_def(S, fname, def_val)
if isstruct(S) && isfield(S, fname) && ~isempty(S.(fname))
    val = S.(fname);
else
    val = def_val;
end
end

function validate_dataspec_schema(DS)
req_mon = {'Currency_ISO', 'Currency_Symbol', 'Currency_Unit_Billions', 'Base_Year', ...
           'Currency_Base_Scale', 'CE_Monetary_Scale_Nat', 'GDP_Base_Billions'};
req_ins = {'tau_l', 'tau_c', 'tau_k', 'tau_a', 'tau_b', 'p_super', 's_sub', ...
           'Super_Age_Base', 'Super_Age_SS1', 'Super_Age_SS2', 'Dep_Ratio_Anchor', ...
           'Estate_Exemption', 'Target_NetMig_Rate', 'w_External', 'Q_External'};
req_reg = {'G_ece1_sched', 'G_ece2_sched', 'YouthGrant_sched'};
req_act = {'H_Window_Yrs', 'Attribution_Haircut', 'Real_Cost_Growth', ...
           'Discount_Central', 'Discount_Sensitivity', 'Sav_Multiplier', 'GDP_Wave_Multiplier'};

assert_section_complete(DS.Monetary,         'Monetary',         req_mon, DS.Profile_ID);
assert_section_complete(DS.Institutions,     'Institutions',     req_ins, DS.Profile_ID);
assert_section_complete(DS.Regime_Schedules, 'Regime_Schedules', req_reg, DS.Profile_ID);
assert_section_complete(DS.Actuarial,        'Actuarial',        req_act, DS.Profile_ID);
end

function assert_section_complete(S, sec_name, req_fields, prof_id)
for k = 1:numel(req_fields)
    fn = req_fields{k};
    if ~isstruct(S) || ~isfield(S, fn) || isempty(S.(fn))
        error('IGWelfare:IncompleteProfileSchema', ...
            'Profile "%s" is incomplete: missing required key %s.%s in profile.yaml (no silent defaults allowed).', ...
            prof_id, sec_name, fn);
    end
end
end

function digest = compute_struct_md5(S)
digest = IGW_MD5_Hex(S);
end
