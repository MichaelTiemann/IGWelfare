function test_recompute_table14_cond_crlf()
%TEST_RECOMPUTE_TABLE14_COND_CRLF tools/recompute_table14_cond.m keeps CRLF files CRLF.
%   MATLAB writetable on Windows emits CRLF, so a regenerated Table14 CSV may carry
%   CRLF line endings. The tool must neither stop on the CR bytes nor change the
%   endings. Setup (temporary folder, repo files untouched): the six committed Table14
%   CSVs are copied with every LF turned into CRLF; in the National copy the SS2
%   CondPerChild of nodes 1 and 14 is put back to the old floored value Flow/0.01
%   (19 and 36). Expected: the tool reports exactly 2 changed cells, rewrites only
%   the National file, every line of it still ends in CRLF, the other five files are
%   byte-identical to their inputs, only those 2 cells differ, and a second run
%   changes 0 cells.
here = fileparts(mfilename('fullpath'));
repo = fileparts(here);
addpath(fullfile(repo, 'tools'));
src = fullfile(repo, 'Output_NZ_4Region_Intergen');
regions = {'National', 'Auckland', 'Large', 'Small', 'Urban', 'Rural'};

tmp = tempname;
mkdir(tmp);
cleaner = onCleanup(@() rmdir(tmp, 's'));

orig = cell(1, numel(regions));
for r = 1:numel(regions)
    fn = sprintf('Table14_FiscalLedger_6Gate_Decomp_%s.csv', regions{r});
    txt = read_bytes(fullfile(src, fn));
    assert(isempty(strfind(txt, char(13))), '%s unexpectedly has CR in the repo', fn);
    if r == 1
        lines = strsplit(txt, char(10), 'CollapseDelimiters', false);
        hdr = strsplit(lines{1}, ',', 'CollapseDelimiters', false);
        jc = find(strcmp(hdr, 'SS2_CondPerChild_kNZD'));
        assert(numel(jc) == 1, 'SS2_CondPerChild_kNZD column not found');
        for i = [1 14] + 1                       % data rows 1 and 14 (line 1 is the header)
            f = strsplit(lines{i}, ',', 'CollapseDelimiters', false);
            f{jc} = sprintf('%d', round(100 * str2double(f{strcmp(hdr, 'SS2_CohortFlow_kNZD')})));
            lines{i} = strjoin(f, ',');
        end
        txt = strjoin(lines, char(10));
    end
    txt = strrep(txt, char(10), [char(13) char(10)]);
    write_bytes(fullfile(tmp, fn), txt);
    orig{r} = txt;
end

n = recompute_table14_cond(tmp, false, true);
assert(n == 2, 'expected 2 changed cells, got %d', n);

for r = 1:numel(regions)
    fn = sprintf('Table14_FiscalLedger_6Gate_Decomp_%s.csv', regions{r});
    out = read_bytes(fullfile(tmp, fn));
    assert(sum(out == char(10)) == sum(out == char(13)), '%s: CR/LF counts differ', fn);
    assert(isempty(strfind(strrep(out, [char(13) char(10)], ''), char(10))), '%s: bare LF found', fn);
    if r > 1
        assert(strcmp(out, orig{r}), '%s changed although it needed no repair', fn);
    else
        a = strsplit(orig{r}, [char(13) char(10)], 'CollapseDelimiters', false);
        b = strsplit(out,     [char(13) char(10)], 'CollapseDelimiters', false);
        assert(numel(a) == numel(b), 'National: line count changed');
        nd = 0;
        for i = 1:numel(a)
            if ~strcmp(a{i}, b{i})
                fa = strsplit(a{i}, ',', 'CollapseDelimiters', false);
                fb = strsplit(b{i}, ',', 'CollapseDelimiters', false);
                assert(numel(fa) == numel(fb), 'National line %d: field count changed', i);
                nd = nd + sum(~strcmp(fa, fb));
            end
        end
        assert(nd == 2, 'National: expected 2 differing cells, got %d', nd);
    end
end

assert(recompute_table14_cond(tmp, false, true) == 0, 'second run should change 0 cells');
end

function s = read_bytes(fname)
fid = fopen(fname, 'rb');
assert(fid >= 0, 'cannot open %s', fname);
s = fread(fid, Inf, 'uint8=>char')';
fclose(fid);
end

function write_bytes(fname, s)
fid = fopen(fname, 'wb');
assert(fid >= 0, 'cannot write %s', fname);
fwrite(fid, s, 'char');
fclose(fid);
end
