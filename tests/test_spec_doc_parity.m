function test_spec_doc_parity()
%TEST_SPEC_DOC_PARITY Verify code-to-code and code-to-Markdown spec parity (<0.1s).

here     = fileparts(mfilename('fullpath'));
repoRoot = fileparts(here);

ret5d = fileread(fullfile(repoRoot, 'src', 'models', 'ReturnFn_SpatialHH.m'));
apFn  = fileread(fullfile(repoRoot, 'src', 'models', 'HumanCapital_Lifecycle_aprimeFn.m'));
compB = fileread(fullfile(repoRoot, 'src', 'config', 'Compose_Policy_Bundle.m'));

doc2A = fileread(fullfile(repoRoot, 'Document 2A.md'));
doc2B = fileread(fullfile(repoRoot, 'Document 2B.md'));
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
assert(isempty(strfind(doc2B, '\left\lbrack -1, +1 \right\rbrack^{18}')), ...
    'Stale [-1, +1]^18 lattice dimension found in Document 2B.md.');
assert(isempty(strfind(doc2T, '\lbrack -1, +1 \rbrack^{18}')), ...
    'Stale [-1, +1]^18 lattice dimension found in Document 2T.md.');

%% 3. Retired Compact4D Reference & GFM MathJax Hygiene Guard
docs = {doc2A, doc2B, doc2T};
docNames = {'Document 2A.md', 'Document 2B.md', 'Document 2T.md'};
for k = 1:numel(docs)
    txt = docs{k};
    nm  = docNames{k};
    assert(isempty(strfind(txt, 'ReturnFn_SpatialHH_Compact4D')), ...
        sprintf('%s still references retired ReturnFn_SpatialHH_Compact4D.', nm));
    assert(isempty(strfind(txt, '<sub>')) && isempty(strfind(txt, '<sup>')), ...
        sprintf('%s contains raw HTML <sub>/<sup> tags.', nm));
end
end
