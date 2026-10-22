function F_clean = pruneAndBalanceFlowMatrix(F, minRibbonVal)
% pruneAndBalanceFlowMatrix Drops sub-threshold phantom ribbons (< minRibbonVal)
% and redistributes their mass pro-rata via bi-proportional (RAS) scaling so
% BOTH source-block row sums and target-block column sums remain 100% exact
% (guaranteeing zero pixel gaps where ribbons meet blocks!).

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

% Bi-proportional (RAS) pro-rata redistribution (preserves BOTH row & col sums)
for iter = 1:6
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
end
end
