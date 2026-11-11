function F_clean = pruneAndBalanceFlowMatrix(F, minRibbonVal)
% pruneAndBalanceFlowMatrix Drops sub-threshold phantom ribbons (< minRibbonVal)
% and redistributes their mass pro-rata via bi-proportional (RAS) scaling.
% RAS sweeps are repeated until max(row-sum error, column-sum error) < 1e-9 x (matrix total), up to 500 sweeps;
% every sweep ends on a column scaling, so column sums match the input to rounding error at all times.
% GUARANTEED: when the pruned support admits a balanced matrix, row sums AND column sums equal the input's to
% within 1e-9 of the matrix total. If the pruned support cannot satisfy both margins (or the cap is reached) the
% function warns (IGW:NoConvergence) and returns the last iterate, whose row sums are NOT exact.

F_clean = max(0, double(F));
rowTarget = sum(F_clean, 2);
colTarget = sum(F_clean, 1);

% Identify visible ribbons above threshold
keepMask = (F_clean >= minRibbonVal);

% Never orphan a non-zero block: keep at least the single largest outflow
% for every non-zero row and single largest inflow for every non-zero column
for i = 1:size(F_clean, 1)
    if rowTarget(i) > 0 && ~any(keepMask(i, :))
        [~, bestJ] = max(F_clean(i, :));
        keepMask(i, bestJ) = true;
    end
end
for j = 1:size(F_clean, 2)
    if colTarget(j) > 0 && ~any(keepMask(:, j))
        [~, bestI] = max(F_clean(:, j));
        keepMask(bestI, j) = true;
    end
end

% Zero out the sub-threshold phantom connections
F_clean(~keepMask) = 0;

% Bi-proportional (RAS) pro-rata redistribution (preserves BOTH row & col sums), iterated to a tolerance
ras_tol    = 1e-9;                          % x matrix total
ras_cap    = 500;                           % sweep cap
ras_scale  = max(sum(rowTarget), eps);
resid_ras  = Inf;
for iter = 1:ras_cap
    % 1. Pro-rata row scaling (matches source block heights)
    rSum = sum(F_clean, 2);
    rScale = ones(size(rSum));
    validR = (rSum > 0);
    rScale(validR) = rowTarget(validR) ./ rSum(validR);
    F_clean = bsxfun(@times, F_clean, rScale);

    % 2. Pro-rata column scaling (matches target block heights)
    cSum = sum(F_clean, 1);
    cScale = ones(size(cSum));
    validC = (cSum > 0);
    cScale(validC) = colTarget(validC) ./ cSum(validC);
    F_clean = bsxfun(@times, F_clean, cScale);

    % Convergence: worst row / column margin error, relative to the matrix total
    resid_ras = max([0, max(abs(sum(F_clean, 2) - rowTarget)), max(abs(sum(F_clean, 1)' - colTarget'))]) / ras_scale;
    if resid_ras < ras_tol
        break;
    end
end
if ~(resid_ras < ras_tol)
    IGW_Log('IGW:NoConvergence', 'pruneAndBalanceFlowMatrix RAS rescaling: %d iterations, residual %.3g (max row/column-sum error as a share of the matrix total; pruned support cannot satisfy both margins)', iter, resid_ras);
end

end
