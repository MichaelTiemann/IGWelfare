function test_prune_and_balance_flow_matrix()
%TEST_PRUNE_AND_BALANCE_FLOW_MATRIX Structural properties of pruneAndBalanceFlowMatrix.m.
%   Asserted (all promised by the function's header/body):
%     P1  output has the input's size, is real double and >= 0; input is not modified
%     P2  zero stays zero (pruning never creates a ribbon where there was none)
%     P3  no non-zero row/column is orphaned, none is created
%     P4  a sub-threshold entry survives only as the documented "keep the largest
%         outflow/inflow" rescue (it must be the row-max or column-max of the input),
%         and at least one sub-threshold entry per fixture really is removed
%     P5  target-block column sums are preserved (the last RAS sweep is a column
%         sweep): relative to the matrix total, COL_TOL
%     P8  nothing to prune => returned unchanged (also for minRibbonVal = 0)
%     P9  idempotent: prune(prune(F)) == prune(F) (second pass takes the first
%         pass's margins as targets)
%   Row-sum preservation is deliberately not asserted here: with the function's fixed
%   number of RAS sweeps it is only approximate on some inputs (see the companion
%   fix PR, which tests it).
%   Fixtures are Fates-shaped percent-of-cohort matrices: 3x3 (marginals of Table15
%   National SS1 Gate1->Gate2) and 3x6 (Gate4->Gate5), each with sub-0.15 ribbons.
addpath(fileparts(fileparts(mfilename('fullpath'))));
COL_TOL = 1e-9;     % relative to the matrix total
THR     = 0.15;     % the Fates call site uses minFatesRibbon_Pct = 0.15

A = [1.20  0.70  0.06;
     0.10  3.20  1.09;
     2.67 53.69 37.29];
B = [0.01  0.40  1.55  0.00  0.00  0.00;
     0.09  0.80  1.50  0.60  0.98  0.20;
     0.00  0.10  1.20  3.10 81.39  6.00];
fixtures = {A, B};

for f = 1:numel(fixtures)
    F = fixtures{f};
    Fin = F;
    G = pruneAndBalanceFlowMatrix(F, THR);
    tag = sprintf('fixture %d', f);

    assert(isequal(size(G), size(F)), '%s: size changed', tag);                          % P1
    assert(isa(G, 'double') && isreal(G) && all(G(:) >= 0), '%s: output not real/non-negative', tag);
    assert(isequal(F, Fin), '%s: input modified', tag);
    assert(all(G(F == 0) == 0), '%s: ribbon created where input was zero', tag);          % P2
    assert(all((sum(F, 2) > 0) == (sum(G, 2) > 0)), '%s: a row was orphaned/created', tag);   % P3
    assert(all((sum(F, 1) > 0) == (sum(G, 1) > 0)), '%s: a column was orphaned/created', tag);
    for i = 1:size(G, 1)                                                                  % P4
        for j = 1:size(G, 2)
            if G(i, j) > 0 && G(i, j) < THR
                isRowMax = F(i, j) == max(F(i, :));
                isColMax = F(i, j) == max(F(:, j));
                assert(isRowMax || isColMax, ...
                    '%s: entry (%d,%d)=%g below %g survived without being a rescue', ...
                    tag, i, j, G(i, j), THR);
            end
        end
    end
    assert(any(F(:) > 0 & F(:) < THR & G(:) == 0), '%s: nothing was pruned (fixture too tame)', tag);
    colErr = max(abs(sum(G, 1) - sum(F, 1)));                                             % P5
    assert(colErr <= COL_TOL * sum(F(:)), '%s: column sums drifted by %g', tag, colErr);
    H = pruneAndBalanceFlowMatrix(G, THR);                                                % P9
    assert(max(abs(H(:) - G(:))) <= 1e-9, '%s: not idempotent (max diff %g)', tag, max(abs(H(:) - G(:))));
end

D = [10 20; 30 40];                                                                       % P8
assert(max(max(abs(pruneAndBalanceFlowMatrix(D, THR) - D))) < 1e-12, 'balanced input changed');
assert(max(max(abs(pruneAndBalanceFlowMatrix(A, 0) - A))) < 1e-12, 'threshold 0 changed the matrix');

Z = pruneAndBalanceFlowMatrix(zeros(2, 3), THR);                                          % edge cases
assert(isequal(Z, zeros(2, 3)), 'all-zero input not returned as zeros');
N = pruneAndBalanceFlowMatrix([1 -2; 3 4], 0.1);
assert(all(N(:) >= 0) && N(1, 2) == 0, 'negative input not clamped to zero');
S = pruneAndBalanceFlowMatrix(single([1 0.01; 0.01 1]), 0.1);
assert(isa(S, 'double'), 'single input should come back as double');
end
