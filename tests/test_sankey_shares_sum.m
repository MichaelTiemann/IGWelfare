function test_sankey_shares_sum()
%TEST_SANKEY_SHARES_SUM Node shares in every Sankey stage/gate sum to 100 (+/- 0.05 pp).
%   CSV structure (read from the files and from Plot_ChildFates_SSankey.m /
%   Plot_ChildFiscal_SSankey.m, which write them with writetable):
%     Output_NZ_4Region_Intergen/Table15_ChildFates_5Stage_Decomp_<Region>.csv
%       18 rows = 5 stages (column Gate) of 3,3,3,3,6 nodes. <SS>_Pop_Pct is the
%       share of the birth cohort in that node; the nodes of one stage are a
%       partition of the cohort, so each stage sums to 100.
%     Output_NZ_4Region_Intergen/Table14_FiscalLedger_6Gate_Decomp_<Region>.csv
%       29 rows = 6 gates (column Gate); node number = digits before the first '_'
%       in Node_Name. <SS>_Pop_Pct is the share of the cohort in the node, but the
%       gates are not all plain partitions (code: Build_Custom_Table14_Fiscal_CSV
%       and the "HARMONIZE 6-GATE" block of Plot_ChildFiscal_SSankey.m):
%         Gate1: nodes 1,2,4 partition the cohort; node 3 (universal benefit) = 100
%         Gate2: nodes 5,6,7 partition;            node 8 (private) = 100 - node 5
%         Gate3: nodes 9,10,11,12 partition;       node 13 (private) = 100 - (9+10)
%         Gate4: nodes 14,15,16 partition
%         Gate5: nodes 17..21 partition
%         Gate6: nodes 22..29 are eight separate fiscal accounts, each 100
%   Regions: National, Auckland, Large, Small, Urban, Rural.  Scenarios: SS0, SS1, SS2.
%   Tolerance TOL = 0.05 percentage points; the CSVs are rounded to 0.01 so a sum of
%   up to 6 nodes can be off by 0.03 from rounding alone.
%   Interior consistency flows-out == flows-in is not testable from these CSVs (only
%   node marginals are exported, not the ribbon matrices).
here = fileparts(mfilename('fullpath'));
addpath(here);
outDir = fullfile(fileparts(here), 'Output_NZ_4Region_Intergen');
TOL = 0.05;
regions = {'National', 'Auckland', 'Large', 'Small', 'Urban', 'Rural'};
scens   = {'SS0', 'SS1', 'SS2'};
bad = {};

for r = 1:numel(regions)
    % ---------------- Fates: 5 stages, each sums to 100 ----------------
    fname = fullfile(outDir, sprintf('Table15_ChildFates_5Stage_Decomp_%s.csv', regions{r}));
    [hdr, cells] = read_csv_cells(fname);
    assert(size(cells, 1) == 18, '%s: expected 18 rows, got %d', fname, size(cells, 1));
    gate = cells(:, strcmp(hdr, 'Gate'));
    gates = unique_stable(gate);
    assert(numel(gates) == 5, '%s: expected 5 stages, got %d', fname, numel(gates));
    for s = 1:numel(scens)
        v = col_num(hdr, cells, [scens{s} '_Pop_Pct'], fname);
        for g = 1:numel(gates)
            tot = sum(v(strcmp(gate, gates{g})));
            if abs(tot - 100) > TOL
                bad{end+1} = sprintf('Fates %s %s %s: sum %.4f', regions{r}, scens{s}, gates{g}, tot); %#ok<AGROW>
            end
        end
    end

    % ---------------- Fiscal: 6 gates, documented structure ----------------
    fname = fullfile(outDir, sprintf('Table14_FiscalLedger_6Gate_Decomp_%s.csv', regions{r}));
    [hdr, cells] = read_csv_cells(fname);
    assert(size(cells, 1) == 29, '%s: expected 29 rows, got %d', fname, size(cells, 1));
    names = cells(:, strcmp(hdr, 'Node_Name'));
    num = zeros(29, 1);
    for i = 1:29
        num(i) = str2double(strtok(names{i}, '_'));
    end
    assert(isequal(num', 1:29), '%s: node numbering is not 1..29 in order', fname);
    gate = cells(:, strcmp(hdr, 'Gate'));
    assert(numel(unique_stable(gate)) == 6, '%s: expected 6 gates', fname);
    parts = {[1 2 4], [5 6 7], [9 10 11 12], [14 15 16], 17:21};
    for s = 1:numel(scens)
        v = col_num(hdr, cells, [scens{s} '_Pop_Pct'], fname);
        lbl = sprintf('Fiscal %s %s', regions{r}, scens{s});
        for k = 1:numel(parts)
            tot = sum(v(parts{k}));
            if abs(tot - 100) > TOL
                bad{end+1} = sprintf('%s partition %s: sum %.4f', lbl, mat2str(parts{k}), tot); %#ok<AGROW>
            end
        end
        chk = {3, 100, 'node 3 (universal) = 100'; ...
               8, 100 - v(5), 'node 8 = 100 - node 5'; ...
               13, 100 - v(9) - v(10), 'node 13 = 100 - (9+10)'};
        for k = 1:size(chk, 1)
            if abs(v(chk{k,1}) - chk{k,2}) > TOL
                bad{end+1} = sprintf('%s %s: node=%.4f expected %.4f', lbl, chk{k,3}, v(chk{k,1}), chk{k,2}); %#ok<AGROW>
            end
        end
        if any(abs(v(22:29) - 100) > TOL)
            bad{end+1} = sprintf('%s Gate6 accounts not all 100: min %.4f max %.4f', lbl, min(v(22:29)), max(v(22:29))); %#ok<AGROW>
        end
    end
end

if ~isempty(bad)
    error('test_sankey_shares_sum:shares', '%d violation(s):\n%s', numel(bad), strjoin(bad, char(10)));
end
end

function v = col_num(hdr, cells, name, fname)
j = find(strcmp(hdr, name));
assert(numel(j) == 1, '%s: column %s not found exactly once', fname, name);
v = str2double(cells(:, j));
assert(~any(isnan(v)), '%s: non-numeric entries in %s', fname, name);
end

function u = unique_stable(c)
u = {};
for i = 1:numel(c)
    if ~any(strcmp(u, c{i})), u{end+1} = c{i}; end %#ok<AGROW>
end
end
