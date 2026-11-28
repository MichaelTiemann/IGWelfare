function test_spec_doc_parity()
%TEST_SPEC_DOC_PARITY Verify code-to-code and code-to-Markdown spec parity (<0.1s).

here     = fileparts(mfilename('fullpath'));
repoRoot = fileparts(here);

ret5d = fileread(fullfile(repoRoot, 'src', 'models', 'ReturnFn_SpatialHH.m'));
apFn  = fileread(fullfile(repoRoot, 'src', 'models', 'HumanCapital_Lifecycle_aprimeFn.m'));
compB = fileread(fullfile(repoRoot, 'src', 'config', 'Compose_Policy_Bundle.m'));

doc2  = fileread(fullfile(repoRoot, 'Document 2.md'));
doc2A = fileread(fullfile(repoRoot, 'Document 2A.md'));
doc2B = fileread(fullfile(repoRoot, 'Document 2B.md'));
doc2C = fileread(fullfile(repoRoot, 'Document 2C.md'));
doc2T = fileread(fullfile(repoRoot, 'Document 2T.md'));

%% 1. Canonical 5D Internal Code Parity (ReturnFn_SpatialHH vs aprimeFn)
assert(~isempty(strfind(ret5d, 'kaiako_spatial')) && ~isempty(strfind(apFn, 'kaiako_spatial')), ...
    'Both ReturnFn_SpatialHH and aprimeFn must evaluate kaiako_spatial.');
assert(~isempty(strfind(ret5d, '0.005')) && ~isempty(strfind(ret5d, '0.035')), ...
    'ReturnFn_SpatialHH must use two-tier [0.005, 0.035) corner stress matching aprimeFn.');
assert(isempty(strfind(ret5d, 'ic < 0.01')), ...
    'Legacy hard cutoff ic < 0.01 must not appear in ReturnFn_SpatialHH.m.');
assert(~isempty(strfind(compB, 'c2pos(28)')) || ~isempty(strfind(compB, 'eC(28)')), ...
    'Compose_Policy_Bundle must include sparse pillars through C28.');

%% 2. Exact Constants Across Code and Technical Specs (2A, 2B, 2T)
for tok = {'0.94', '0.04', '0.0836', '0.34', '0.005', '0.035'}
    t = tok{1};
    assert(~isempty(strfind(doc2A, t)), sprintf('Document 2A.md missing canonical constant %s.', t));
    assert(~isempty(strfind(doc2T, t)), sprintf('Document 2T.md missing canonical constant %s.', t));
end
assert(isempty(strfind(doc2T, '0.18\left(1.00 - h\right)')), ...
    'Stale 0.18 mortality gradient found in Document 2T.md.');
assert(isempty(strfind(doc2B, '\left\lbrack -1, +1 \right\rbrack^{18}')) && isempty(strfind(doc2C, '\left\lbrack -1, +1 \right\rbrack^{18}')), ...
    'Stale [-1, +1]^18 lattice dimension found in Document 2B/2C.md.');
assert(~isempty(strfind(doc2A, 'Solve_Spatial_GE_Loop')) && ~isempty(strfind(doc2B, 'D_{\mathrm{eff}}(j)')), ...
    'Document 2A/2B missing Wave C Solve_Spatial_GE_Loop or horizon-normalized D_eff equations.');
assert(~isempty(strfind(doc2C, '## 8.')) && ~isempty(strfind(doc2C, '## 12.')) && ~isempty(strfind(doc2T, '## T1.')), ...
    'Document 2C (Sections 8-12) or Document 2T (T1-T7 namespace) heading contract violated.');
assert(isempty(strfind(doc2T, '\lbrack -1, +1 \rbrack^{18}')), ...
    'Stale [-1, +1]^18 lattice dimension found in Document 2T.md.');

%% 3. Retired Compact4D Reference & GFM MathJax Hygiene Guard
docs = {doc2, doc2A, doc2B, doc2C, doc2T};
docNames = {'Document 2.md', 'Document 2A.md', 'Document 2B.md', 'Document 2C.md', 'Document 2T.md'};
for k = 1:numel(docs)
    txt = docs{k};
    nm  = docNames{k};
    assert(isempty(strfind(txt, 'ReturnFn_SpatialHH_Compact4D')), ...
        sprintf('%s still references retired ReturnFn_SpatialHH_Compact4D.', nm));
    assert(isempty(strfind(txt, '<sub>')) && isempty(strfind(txt, '<sup>')), ...
        sprintf('%s contains raw HTML <sub>/<sup> tags.', nm));
end

%% 4A. Retired Proportionality-Vector & Exogenous-Markov Guard (Wave C)
wd_code = fileread(fullfile(repoRoot, 'src', 'models', 'Compute_WelfareDecomposition_4Region.m'));
ap_code = fileread(fullfile(repoRoot, 'src', 'config', 'Apply_Policy_Regime.m'));
assert(isempty(strfind(wd_code, '[1.38; 0.94; 0.42]')) && isempty(strfind(wd_code, '[1.45; 1.22;')), ...
    'Compute_WelfareDecomposition_4Region still contains retired T2/T3 proportionality vectors.');
assert(isempty(strfind(wd_code, 'daruich_ig_mult')), ...
    'Compute_WelfareDecomposition_4Region still references retired daruich_ig_mult override.');
assert(isempty(strfind(ap_code, '[0.08, 0.06, 0.03, 0.01]')), ...
    'Apply_Policy_Regime still contains retired hardcoded Markov upgrade vector.');

%% 4B. Retired Compact4D Codebase Elimination Guard
assert(exist(fullfile(repoRoot, 'src', 'models', 'ReturnFn_SpatialHH_Compact4D.m'), 'file') == 0, ...
    'Retired ReturnFn_SpatialHH_Compact4D.m must not exist on disk.');
for sub = {'src', 'pipelines', 'plots'}
    mfiles = dir(fullfile(repoRoot, sub{1}, '**', '*.m'));
    if isempty(mfiles)
        mfiles = dir(fullfile(repoRoot, sub{1}, '*.m'));
    end
    for i = 1:numel(mfiles)
        fp = fullfile(mfiles(i).folder, mfiles(i).name);
        assert(isempty(strfind(fileread(fp), 'ReturnFn_SpatialHH_Compact4D')), ...
            sprintf('%s still references retired ReturnFn_SpatialHH_Compact4D.', fp));
    end
end
end
