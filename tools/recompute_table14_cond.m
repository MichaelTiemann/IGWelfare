function nChanged = recompute_table14_cond(outDir, dryRun, quiet)
%RECOMPUTE_TABLE14_COND Repair <SS>_CondPerChild_kNZD in the six Table14 CSVs (MATLAB or Octave).
%   n = recompute_table14_cond()            rewrites the CSVs in ../Output_NZ_4Region_Intergen
%   n = recompute_table14_cond(dir)         uses another folder
%   n = recompute_table14_cond(dir, true)   dry run: report only, write nothing
%   n = recompute_table14_cond(dir, false, true)   quiet: no console output
%
%   Background: Build_Custom_Table14_Fiscal_CSV (Plot_ChildFiscal_SSankey.m) used to
%   compute  Cond = Flow ./ max(0.01, Pop_Pct/100),  which floors the population
%   fraction at 1%. For every node with 0 < Pop_Pct < 1 the committed value was
%   therefore  old_Cond = round(Flow_unrounded / 0.01, 2),  i.e. too low by Pop_Pct/1.
%   The code now uses max(1e-9, ...).
%
%   Derivation used here (no GPU model needed). For a floored cell
%       Flow_unrounded = old_Cond * 0.01      (known to +-0.00005, because old_Cond
%                                              carries 2 decimals; far better than the
%                                              2-decimal CohortFlow cell, +-0.005)
%       corrected Cond = Flow_unrounded / (Pop_Pct/100) = old_Cond / Pop_Pct
%   rounded to 2 decimals. Remaining error source: Pop_Pct is committed to 0.01 pp,
%   so the corrected value carries a relative error of up to 0.005/Pop_Pct (about
%   +-1% for a 0.5% node). Re-running Plot_ChildFiscal_SSankey.m gives exact values.
%
%   Only cells with 0 < Pop_Pct < 1 that are still "floored" are rewritten, i.e. where
%   |old_Cond*0.01 - CohortFlow| <= 0.0051 (the floored identity holds to the CSV's
%   rounding). A corrected cell no longer satisfies that, so a second run changes
%   nothing (idempotent). All other cells (computed from unrounded model values),
%   line endings and columns are left byte-for-byte as they were. Files with LF or
%   CRLF endings (MATLAB writetable on Windows) are both handled and keep their
%   endings; a file mixing the two is rejected.
here = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(outDir)
    outDir = fullfile(fileparts(here), 'Output_NZ_4Region_Intergen');
end
if nargin < 2 || isempty(dryRun), dryRun = false; end
if nargin < 3 || isempty(quiet), quiet = false; end
regions = {'National', 'Auckland', 'Large', 'Small', 'Urban', 'Rural'};
scens   = {'SS0', 'SS1', 'SS2'};
nChanged = 0;

for r = 1:numel(regions)
    fname = fullfile(outDir, sprintf('Table14_FiscalLedger_6Gate_Decomp_%s.csv', regions{r}));
    fid = fopen(fname, 'rb');
    if fid < 0, error('recompute_table14_cond:open', 'cannot open %s', fname); end
    raw = fread(fid, Inf, 'uint8=>char')';
    fclose(fid);
    if ~isempty(strfind(raw, '"'))
        error('recompute_table14_cond:format', '%s has quoted fields; not handled', fname);
    end
    nCR = sum(raw == char(13));
    hasCR = nCR > 0;
    if hasCR && nCR ~= sum(raw == char(10))
        error('recompute_table14_cond:format', '%s mixes CRLF and LF line endings', fname);
    end
    lines = strsplit(raw, char(10), 'CollapseDelimiters', false);   % last element is '' after the final LF
    if hasCR
        for i = 1:numel(lines)
            if ~isempty(lines{i}) && lines{i}(end) == char(13)
                lines{i}(end) = [];
            end
        end
    end
    hdr = strsplit(lines{1}, ',', 'CollapseDelimiters', false);
    changedHere = 0;
    for s = 1:numel(scens)
        jp = find(strcmp(hdr, [scens{s} '_Pop_Pct']));
        jf = find(strcmp(hdr, [scens{s} '_CohortFlow_kNZD']));
        jc = find(strcmp(hdr, [scens{s} '_CondPerChild_kNZD']));
        if numel(jp) ~= 1 || numel(jf) ~= 1 || numel(jc) ~= 1
            error('recompute_table14_cond:cols', '%s: columns for %s not found', fname, scens{s});
        end
        for i = 2:numel(lines)
            if isempty(lines{i}), continue; end
            f = strsplit(lines{i}, ',', 'CollapseDelimiters', false);
            pop = str2double(f{jp});  flow = str2double(f{jf});  old = str2double(f{jc});
            if pop > 0 && pop < 1 && abs(old * 0.01 - flow) <= 0.0051
                new = round(old / pop * 100) / 100;
                if abs(new - old) > 0.005
                    f{jc} = sprintf('%.15g', new);
                    lines{i} = strjoin(f, ',');
                    changedHere = changedHere + 1;
                    if ~quiet, fprintf(1, '  %-9s %s node %-2d pop=%.2f flow=%.2f  cond %.2f -> %.2f\n', ...
                           regions{r}, scens{s}, i - 1, pop, flow, old, new); end
                end
            end
        end
    end
    nChanged = nChanged + changedHere;
    if changedHere > 0 && ~dryRun
        eol = char(10);
        if hasCR, eol = [char(13) char(10)]; end
        fid = fopen(fname, 'wb');
        fwrite(fid, strjoin(lines, eol), 'char');
        fclose(fid);
    end
end
if ~quiet
    fprintf(1, '%d CondPerChild cell(s) %s.\n', nChanged, ternary(dryRun, 'would change', 'changed'));
end
end

function s = ternary(c, a, b)
if c, s = a; else, s = b; end
end
