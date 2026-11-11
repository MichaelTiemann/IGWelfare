function test_cohort_weight_identity()
%TEST_COHORT_WEIGHT_IDENTITY Document 2B s5.1: Flow = p x c_cond, checked on Table14.
%   Document 2B.md, section 5.1 item 1 ("Cohort-Weighted Ribbon Width Identity"):
%       Flow_{g,i}^cohort = p_{g,i} * c_{g,i}^cond
%   i.e. for every node i and scenario, <SS>_CohortFlow_kNZD must equal
%   <SS>_Pop_Pct/100 * <SS>_CondPerChild_kNZD in the exported
%   Table14_FiscalLedger_6Gate_Decomp_<Region>.csv (3 scenarios x 29 nodes x 6 regions).
%   Tolerance TOL = 0.015 kNZD, derived from the 2-decimal rounding in the CSV:
%   flow +-0.005, cond +-0.005 x p (p<=1), pop +-0.00005 x cond (cond<=~70) => <=0.0134.
%   The tolerance is NOT widened to fit the data: where the identity fails the test
%   fails and lists the rows. Build_Custom_Table14_Fiscal_CSV computes
%   Cond = Flow ./ max(0.01, Pop_29/100) with Pop_29 in percent, so the 0.01 floor is a
%   1% population share, not a numerical guard; nodes below 1% get CondPerChild that
%   is too low by a factor pop/1%.
here = fileparts(mfilename('fullpath'));
addpath(here);
outDir = fullfile(fileparts(here), 'Output_NZ_4Region_Intergen');
TOL = 0.015;
regions = {'National', 'Auckland', 'Large', 'Small', 'Urban', 'Rural'};
scens   = {'SS0', 'SS1', 'SS2'};
bad = {};
for r = 1:numel(regions)
    fname = fullfile(outDir, sprintf('Table14_FiscalLedger_6Gate_Decomp_%s.csv', regions{r}));
    [hdr, cells] = read_csv_cells(fname);
    for s = 1:numel(scens)
        pop  = getcol(hdr, cells, [scens{s} '_Pop_Pct'], fname);
        flow = getcol(hdr, cells, [scens{s} '_CohortFlow_kNZD'], fname);
        cond = getcol(hdr, cells, [scens{s} '_CondPerChild_kNZD'], fname);
        err = flow - pop / 100 .* cond;
        for i = find(abs(err) > TOL)'
            bad{end+1} = sprintf('%s %s node %2d: pop=%.2f%% flow=%.2f cond=%.2f -> pop*cond=%.4f (diff %.4f)', ...
                regions{r}, scens{s}, i, pop(i), flow(i), cond(i), pop(i)/100*cond(i), err(i)); %#ok<AGROW>
        end
    end
end
if ~isempty(bad)
    error('test_cohort_weight_identity:identity', '%d row(s) break Flow = p*c_cond (tol %g):\n%s', ...
          numel(bad), TOL, strjoin(bad, char(10)));
end
end

function v = getcol(hdr, cells, name, fname)
j = find(strcmp(hdr, name));
assert(numel(j) == 1, '%s: column %s not found exactly once', fname, name);
v = str2double(cells(:, j));
assert(~any(isnan(v)), '%s: non-numeric entries in %s', fname, name);
end
