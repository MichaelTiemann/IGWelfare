function test_prune_balance_warns_noconvergence()
%% TEST_PRUNE_BALANCE_WARNS_NOCONVERGENCE
% pruneAndBalanceFlowMatrix iterates RAS rescaling to a tolerance (1e-9 of the matrix total, 500-sweep cap). When the
% row / column sums are still off at the cap it must warn (IGW:NoConvergence); when nothing is pruned it must stay silent and return the input unchanged.
% Throws on failure, silent on success. No toolboxes, no GPU; runs under MATLAB and GNU Octave.
addpath(fileparts(fileparts(mfilename('fullpath'))));

% 1. Nothing below the threshold: output equals input, no warning
F = [3 2; 1 4];
lastwarn('');
out = evalc('Fc = pruneAndBalanceFlowMatrix(F, 0.5);'); %#ok<NASGU>
[~, wid] = lastwarn();
check(max(abs(Fc(:) - F(:))) < 1e-12, 'matrix with no sub-threshold ribbons was altered');
check(~strcmp(wid, 'IGW:NoConvergence'), 'warning raised although nothing was pruned');

% 2. Pruning leaves a support on which the marginals cannot be matched: warn, residual in the text
G = [0.5 0 0; 0.5 0 4; 1 0 0];
lastwarn('');
out = evalc('Gc = pruneAndBalanceFlowMatrix(G, 1);'); %#ok<NASGU>
[wmsg, wid] = lastwarn();
check(strcmp(wid, 'IGW:NoConvergence'), 'unbalanced result: expected warning IGW:NoConvergence');
check(~isempty(strfind(wmsg, '500 iterations')) && ~isempty(strfind(wmsg, 'residual')), 'warning text lacks iteration count / residual');
check(isequal(size(Gc), size(G)), 'output size changed');
end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_prune_balance_warns_noconvergence: %s', msg);
end
end
