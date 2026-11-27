function PolicyCatalog = Load_Commitment_Catalog(DataSpec)
%% PURE LOADER FOR CONVENTION-2 INSTITUTIONAL COMMITMENT CATALOG & BUNDLES
% File: src/data/Load_Commitment_Catalog.m
% Loads commitment_catalog.csv and policy_bundles.yaml for DataSpec.Profile_ID,
% automatically falling back to parent profile (Inherits_From) when a derived
% profile such as NZ_GUiNZ2009 shares the canonical policy algebra.
%
% Supports sparse code-indexed commitments (e.g., C01..C18 and C21..C28 with
% unallocated slots C19..C20 and C29+ reserved cleanly without index drift) via:
%   - PolicyCatalog.Code_Nums   : [nC x 1] integer code numbers (1..18, 21..28)
%   - PolicyCatalog.Code_To_Pos : [maxCode x 1] O(1) lookup mapping cnum -> row pos (0 if reserved)

if nargin < 1 || isempty(DataSpec)
    DataSpec = Load_Empirical_Profile('NZ_Dunedin1972');
elseif ischar(DataSpec) || isstring(DataSpec)
    DataSpec = Load_Empirical_Profile(char(DataSpec));
end

igw_root = getappdata(0, 'IGW_ROOT_DIR');
if isempty(igw_root)
    igw_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end

cand_dirs = {fullfile(igw_root, 'profiles', DataSpec.Profile_ID, 'policies')};
if isfield(DataSpec, 'Parent_Profile_ID') && ~isempty(DataSpec.Parent_Profile_ID)
    cand_dirs{end+1} = fullfile(igw_root, 'profiles', DataSpec.Parent_Profile_ID, 'policies');
end
cand_dirs{end+1} = fullfile(igw_root, 'profiles', 'NZ_Dunedin1972', 'policies');

pol_dir = '';
for k = 1:numel(cand_dirs)
    if exist(fullfile(cand_dirs{k}, 'commitment_catalog.csv'), 'file') == 2
        pol_dir = cand_dirs{k};
        break;
    end
end
if isempty(pol_dir)
    error('IGWelfare:MissingCommitmentCatalog', 'Could not locate commitment_catalog.csv for profile %s.', DataSpec.Profile_ID);
end

CatTable   = Read_IGW_CSV(fullfile(pol_dir, 'commitment_catalog.csv'));
if isfield(CatTable, 'Claimed_4Yr_BCurr') && ~isfield(CatTable, 'Claimed_4Yr_BNZD')
    CatTable.Claimed_4Yr_BNZD = CatTable.Claimed_4Yr_BCurr;
elseif isfield(CatTable, 'Claimed_4Yr_BNZD') && ~isfield(CatTable, 'Claimed_4Yr_BCurr')
    CatTable.Claimed_4Yr_BCurr = CatTable.Claimed_4Yr_BNZD;
end
if isfield(CatTable, 'Claimed_Pos_4Yr_BCurr') && ~isfield(CatTable, 'Claimed_Pos_4Yr_BNZD')
    CatTable.Claimed_Pos_4Yr_BNZD = CatTable.Claimed_Pos_4Yr_BCurr;
elseif isfield(CatTable, 'Claimed_Pos_4Yr_BNZD') && ~isfield(CatTable, 'Claimed_Pos_4Yr_BCurr')
    CatTable.Claimed_Pos_4Yr_BCurr = CatTable.Claimed_Pos_4Yr_BNZD;
end
BundleSpec = Read_IGW_YAML(fullfile(pol_dir, 'policy_bundles.yaml'));

cids    = CatTable.Commitment_ID(:);
nC      = numel(cids);
tok     = regexp(cids, '^C0*(\d+)', 'tokens', 'once');
c_nums  = cellfun(@(t) str2double(t{1}), tok);
max_num = max([39; c_nums(:)]);
c2pos   = zeros(max_num, 1);
c2pos(c_nums) = (1:nC)';

PolicyCatalog = struct();
PolicyCatalog.Profile_ID       = DataSpec.Profile_ID;
PolicyCatalog.Source_Dir       = pol_dir;
PolicyCatalog.Catalog_Table    = CatTable;
PolicyCatalog.Commitment_IDs   = cids;
PolicyCatalog.Domains          = CatTable.Domain(:);
PolicyCatalog.Code_Nums        = c_nums(:);
PolicyCatalog.Code_To_Pos      = c2pos;
if isfield(CatTable, 'Portfolio_Lane')
    PolicyCatalog.Portfolio_Lanes = CatTable.Portfolio_Lane(:);
end
if isfield(CatTable, 'Is_Positive_Only')
    PolicyCatalog.Is_Positive_Only = logical(CatTable.Is_Positive_Only(:));
else
    PolicyCatalog.Is_Positive_Only = false(nC, 1);
end

Meta        = BundleSpec.Metadata;
BundlesOnly = rmfield(BundleSpec, 'Metadata');
PolicyCatalog.Bundles                   = BundlesOnly;
PolicyCatalog.Default_Core13_PassThrough = Meta.Default_Core13_PassThrough;
PolicyCatalog.Digest                    = IGW_MD5_Hex(struct('Catalog', CatTable, 'Bundles', BundleSpec));

end
