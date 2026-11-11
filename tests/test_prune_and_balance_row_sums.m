function test_prune_and_balance_row_sums()
%TEST_PRUNE_AND_BALANCE_ROW_SUMS Row sums and node balance of pruneAndBalanceFlowMatrix.
%   Adopted from the handoff test written on another branch; calls wrapped in evalc so a success run prints nothing.
%   Assumes the function iterates RAS sweeps to a tolerance (<= ~1e-9 relative) under a
%   sweep cap, ends every sweep on a column sweep, and when the cap is hit calls
%   IGW_Log('IGW:NoConvergence', ...) (a warning plus a log line). Against main's fixed-6-sweep version R1/R2 FAIL
%   (fixture B row drift 0.00709, fixture C 0.0228, chain imbalance 0.0228).
%     R1  feasible fixtures A (3x3), B (3x6), C (3x3): row sums preserved, ROW_TOL
%     R2  chain A -> C (rowsum(C) == colsum(A) beforehand): colsum(G_A) == rowsum(G_C)
%     R3  columns stay exact (COL_TOL, relative to the matrix total)
%     R4  a matrix whose pruned support cannot satisfy both margins
%         ([2.09 0 0.11; 0.13 2.26 0; 85.06 0 77.31], threshold 0.15) must not fail
%         silently: it must raise warning id IGW:NoConvergence
%     R5  feasible inputs must NOT warn
%   ROW_TOL = 1e-6 pp (tolerance 1e-9 inside the function leaves ample margin).
addpath(fileparts(fileparts(mfilename('fullpath'))));
ROW_TOL = 1e-6;
COL_TOL = 1e-9;
THR     = 0.15;

A = [1.20  0.70  0.06;  0.10  3.20  1.09;  2.67 53.69 37.29];
B = [0.01  0.40  1.55  0.00  0.00  0.00;
     0.09  0.80  1.50  0.60  0.98  0.20;
     0.00  0.10  1.20  3.10 81.39  6.00];
C = [3.5 0.04 0.5;  0.2 40.0 16.7;  0.1 0.06 38.2];
C = bsxfun(@times, C, (sum(A, 1)') ./ sum(C, 2));
assert(max(abs(sum(A, 1)' - sum(C, 2))) < 1e-12, 'chain fixture construction failed');

bad = {};
lastwarn('');
fx = {A, B, C};  nm = {'A', 'B', 'C'};
G = cell(1, 3);
for k = 1:numel(fx)
    evalc('G{k} = pruneAndBalanceFlowMatrix(fx{k}, THR);');
    e = max(abs(sum(G{k}, 2) - sum(fx{k}, 2)));
    if e > ROW_TOL
        bad{end+1} = sprintf('R1 fixture %s: row sums drift by %.3g (tol %g)', nm{k}, e, ROW_TOL); %#ok<AGROW>
    end
    ec = max(abs(sum(G{k}, 1) - sum(fx{k}, 1)));
    if ec > COL_TOL * sum(fx{k}(:))
        bad{end+1} = sprintf('R3 fixture %s: column sums drift by %.3g', nm{k}, ec); %#ok<AGROW>
    end
end
e = max(abs(sum(G{1}, 1)' - sum(G{3}, 2)));
if e > ROW_TOL
    bad{end+1} = sprintf('R2 chain A->C: node imbalance %.3g (tol %g)', e, ROW_TOL);
end
[~, wid] = lastwarn();
if ~isempty(wid)
    bad{end+1} = sprintf('R5 feasible fixtures raised warning %s', wid);
end

% R4: infeasible pruned support must warn, not pass silently
X = [2.09 0 0.11;  0.13 2.26 0;  85.06 0 77.31];
lastwarn('');
evalc('pruneAndBalanceFlowMatrix(X, THR);');
[~, wid] = lastwarn();
if ~strcmp(wid, 'IGW:NoConvergence')
    bad{end+1} = sprintf('R4 infeasible support did not raise IGW:NoConvergence (lastwarn id = ''%s'')', wid);
end

if ~isempty(bad)
    error('test_prune_and_balance_row_sums:drift', '%s', strjoin(bad, char(10)));
end
end
