function test_Shapley_Owen_Attribution()
% TEST_SHAPLEY_OWEN_ATTRIBUTION
% Axiom and cross-check tests for Shapley_Owen_Attribution.m (repo root).
% Throws on the first failure and prints nothing on success. No toolboxes; MATLAB and Octave.
%   1. Hand-computed 3-player game (Shapley and Owen), arithmetic shown below.
%   2. Efficiency, shift invariance, symmetry, null player, additivity (Shapley and Owen).
%   3. Owen with all-singleton unions == Shapley; Owen with one grand union == Shapley.
%   4. Independent brute-force enumeration of orderings (Shapley: all n!; Owen: union-contiguous orderings).
%   5. Pairwise-only games: Owen == Shapley for any partition; a 3-way term separates them.
%   6. Function-handle vs vector input, evaluation counts, NaN handling, input validation.

addpath(fileparts(fileparts(mfilename('fullpath'))));
tol = 1e-9;

% =========================================================================
% 1. HAND-COMPUTED 3-PLAYER GAME  (players A=1, B=2, C=3; bit k <=> player k)
% =========================================================================
% v(empty)=0, v(A)=4, v(B)=6, v(C)=0, v(AB)=14, v(AC)=6, v(BC)=9, v(ABC)=18.
% Vector index = mask + 1:  mask 0..7 = {} A B AB C AC BC ABC.
v3 = [0 4 6 14 0 6 9 18];
%
% SHAPLEY: marginal contributions over the 6 orderings (A,B,C columns):
%   ABC: A=4      B=14-4=10  C=18-14=4
%   ACB: A=4      B=18-6=12  C=6-4=2
%   BAC: A=14-6=8 B=6        C=18-14=4
%   BCA: A=18-9=9 B=6        C=9-6=3
%   CAB: A=6-0=6  B=18-6=12  C=0
%   CBA: A=18-9=9 B=9-0=9    C=0
%   totals A=4+4+8+9+6+9=40, B=10+12+6+6+12+9=55, C=4+2+4+3+0+0=13; each /6.
%   phi_Shapley = [40 55 13]/6 = [6.6667 9.1667 2.1667], sum = 108/6 = 18 = v(ABC)-v(empty).
%
% CROSS-CHECK via Harsanyi dividends: d(AB)=14-4-6=4, d(AC)=6-4-0=2, d(BC)=9-6-0=3,
%   d(ABC)=18-(14+6+9)+(4+6+0)-0=-1;  phi_i = v(i) + 0.5*sum_j d(ij) + d(ABC)/3:
%   A=4+0.5*(4+2)-1/3=6.6667  B=6+0.5*(4+3)-1/3=9.1667  C=0+0.5*(2+3)-1/3=2.1667.
%
% OWEN with unions {A,B},{C}: only orderings with A,B adjacent: ABC, BAC, CAB, CBA (4 of 6):
%   A=(4+8+6+9)/4=6.75   B=(10+6+12+9)/4=9.25   C=(4+4+0+0)/4=2.0   sum=18.
[phi, info] = Shapley_Owen_Attribution(v3, 3);
check(max(abs(phi - [40; 55; 13] / 6)) < tol, '3-player Shapley');
check(abs(info.efficiency_gap) < tol, '3-player efficiency gap');
check(isequal(info.interactions, [0 4 2; 4 0 3; 2 3 0]), '3-player interaction matrix');
check(strcmp(info.method, 'Shapley') && info.n_evaluations == 8, '3-player info fields');
[phi, info] = Shapley_Owen_Attribution(v3, 3, {[1 2], 3});
check(max(abs(phi - [6.75; 9.25; 2.0])) < tol, '3-player Owen {AB},{C}');
check(abs(info.efficiency_gap) < tol && strcmp(info.method, 'Owen'), '3-player Owen info');

% =========================================================================
% 2. AXIOMS ON DETERMINISTIC PSEUDO-RANDOM GAMES
% =========================================================================
n  = 6;
va = hash_game(n, 7919, 13);
vb = hash_game(n, 104729, 5);
parts = {[1 2 3], [4 5], 6};
for use_unions = [false true]
    if use_unions, args = {parts}; else, args = {}; end
    pa  = Shapley_Owen_Attribution(va, n, args{:});
    pb  = Shapley_Owen_Attribution(vb, n, args{:});
    % efficiency (v(empty) ~= 0 here)
    check(va(1) ~= 0 && abs(sum(pa) - (va(end) - va(1))) < tol, 'efficiency');
    % shift invariance: adding a constant to every v leaves phi unchanged
    check(max(abs(Shapley_Owen_Attribution(va + 3.5, n, args{:}) - pa)) < tol, 'shift invariance');
    % additivity
    pab = Shapley_Owen_Attribution(va + vb, n, args{:});
    check(max(abs(pab - (pa + pb))) < tol, 'additivity');
end

% symmetry: players 1 and 2 are interchangeable (and share a union)
masks = (0:2^4-1)';
x     = @(k) bitget(masks, k);
vs    = 3 * (x(1) + x(2)).^2 + 5 * x(3) .* (x(1) + x(2)) + 2 * x(4) + 1.5 * x(3) .* x(4);
check(abs(vs(1 + 1) - vs(1 + 2)) < tol, 'symmetric game construction');
p = Shapley_Owen_Attribution(vs, 4);
check(abs(p(1) - p(2)) < tol && abs(p(1) - p(3)) > 0.1, 'Shapley symmetry');
p = Shapley_Owen_Attribution(vs, 4, {[1 2], [3 4]});
check(abs(p(1) - p(2)) < tol, 'Owen symmetry within a union');

% null player: player 3 never changes any coalition's value
masks = (0:2^5-1)';
vh    = hash_game(5, 7919, 13);
vn    = vh(masks - 4 * bitget(masks, 3) + 1);          % v(S) = v(S minus player 3)
check(max(abs(vn(masks + 1) - vn(masks - 4 * bitget(masks, 3) + 1))) < tol, 'null game construction');
p = Shapley_Owen_Attribution(vn, 5);
check(abs(p(3)) < tol, 'Shapley null player');
p = Shapley_Owen_Attribution(vn, 5, {[1 3], [2 4 5]});
check(abs(p(3)) < tol, 'Owen null player');

% =========================================================================
% 3. OWEN REDUCES TO SHAPLEY AT BOTH EXTREME PARTITIONS
% =========================================================================
% Singletons: each union has one member, so T is empty and Q ranges over all other players with
%   weight q!(n-q-1)!/n! = the Shapley weight.  Grand union: Q is empty (weight 1), T ranges over
%   subsets of N\{i} with weight t!(n-t-1)!/n! = the Shapley weight.
ps = Shapley_Owen_Attribution(va, n);
check(max(abs(Shapley_Owen_Attribution(va, n, num2cell(1:n)) - ps)) < tol, 'Owen(singletons) == Shapley');
check(max(abs(Shapley_Owen_Attribution(va, n, {1:n}) - ps)) < tol, 'Owen(grand union) == Shapley');
check(max(abs(Shapley_Owen_Attribution(va, n, {[3 1 2 6 5 4]}) - ps)) < tol, 'index order inside union is irrelevant');
check(max(abs(Shapley_Owen_Attribution(va, n, parts) - ps)) > 1e-3, 'a nontrivial partition changes the allocation');

% =========================================================================
% 4. INDEPENDENT BRUTE-FORCE ENUMERATION OF ORDERINGS
% =========================================================================
v5 = hash_game(5, 7919, 13);
check(max(abs(Shapley_Owen_Attribution(v5, 5) - brute_force(v5, 5, {1:5}))) < tol, 'Shapley vs 5! orderings');
v6 = hash_game(6, 104729, 5);
for c = {{[1 2], 3, [4 5 6]}, {[1 4], [2 3 5 6]}, {[6 5], [1], [2 4], [3]}}
    u = c{1};
    check(max(abs(Shapley_Owen_Attribution(v6, 6, u) - brute_force(v6, 6, u))) < tol, 'Owen vs union-contiguous orderings');
end

% =========================================================================
% 5. PAIRWISE-ONLY GAMES: OWEN == SHAPLEY; A 3-WAY TERM SEPARATES THEM
% =========================================================================
% v(S) = sum_i a_i + sum_{i<j in S} M_ij has phi_i = a_i + 0.5*sum_j M_ij under Shapley, and the same
% under Owen, because P(j precedes i) = 1/2 both inside a union (inner symmetry) and across unions.
M = [0 1.2 0.4 0.9 0; 1.2 0 2.0 0.1 0.3; 0.4 2.0 0 0.7 1.1; 0.9 0.1 0.7 0 0.6; 0 0.3 1.1 0.6 0];
a = [3 1 2 0.5 4];
vq = zeros(2^5, 1);
for mask = 0:2^5-1
    in = logical(bitget(mask, 1:5));
    vq(mask + 1) = sum(a(in)) + sum(sum(triu(M(in, in), 1)));
end
expect = a(:) + 0.5 * sum(M, 2);
check(max(abs(Shapley_Owen_Attribution(vq, 5) - expect)) < tol, 'pairwise game: Shapley closed form');
check(max(abs(Shapley_Owen_Attribution(vq, 5, {[1 2], [3 4 5]}) - expect)) < tol, 'pairwise game: Owen == Shapley');
check(max(abs(Shapley_Owen_Attribution(vq, 5, {[1 3], 2, [4 5]}) - expect)) < tol, 'pairwise game: Owen == Shapley (2)');
% add a pure 3-way term on {1,2,3} (a "wedge" no pair accounts for): partition now matters
v3way = vq + 2.0 * double(bitand((0:2^5-1)', 7) == 7);
pS = Shapley_Owen_Attribution(v3way, 5);
pO = Shapley_Owen_Attribution(v3way, 5, {[1 2], [3 4 5]});
check(max(abs(pS - (expect + [2; 2; 2; 0; 0] / 3))) < tol, '3-way term: Shapley splits it equally');
check(abs(pO(3) - pS(3)) > 0.05, '3-way term: Owen differs from Shapley');
check(abs(sum(pO) - sum(pS)) < tol, '3-way term: both efficient');

% =========================================================================
% 6. HANDLE VS VECTOR, EVALUATION COUNTS, NaN HANDLING, VALIDATION, n = 10
% =========================================================================
[pv, iv] = Shapley_Owen_Attribution(va, n, parts);
[ph, ih] = Shapley_Owen_Attribution(@(mask) va(mask + 1), n, parts);
check(max(abs(pv - ph)) < tol && isequal(iv.interactions, ih.interactions), 'handle == vector');
check(ih.n_evaluations == iv.n_evaluations && ih.n_evaluations <= 2^n, 'evaluation count');
[~, i1] = Shapley_Owen_Attribution(va, n);
[~, i2] = Shapley_Owen_Attribution(va, n, parts);
check(numel(i1.masks_needed) == 2^n && numel(i2.masks_needed) < 2^n, 'Owen needs fewer coalition values than Shapley');

% a value outside masks_needed may be missing (NaN); one inside may not
spare = setdiff(1:2^n, i2.masks_needed + 1);
vm = va;  vm(spare(1)) = NaN;
check(max(abs(Shapley_Owen_Attribution(vm, n, parts) - pv)) < tol, 'unneeded NaN ignored');
vm = va;  vm(i2.masks_needed(end - 3) + 1) = NaN;
check(fails_with(@() Shapley_Owen_Attribution(vm, n, parts), 'Shapley_Owen_Attribution:missingValues'), 'needed NaN errors');
check(fails_with(@() Shapley_Owen_Attribution(va(1:end-1), n), 'Shapley_Owen_Attribution:badV'), 'wrong vector length');
check(fails_with(@() Shapley_Owen_Attribution(va, n, {[1 2], [2 3 4 5 6]}), 'Shapley_Owen_Attribution:badUnions'), 'overlapping unions');
check(fails_with(@() Shapley_Owen_Attribution(va, n, {[1 2 3]}), 'Shapley_Owen_Attribution:badUnions'), 'non-covering unions');
check(fails_with(@() Shapley_Owen_Attribution(va, 0), 'Shapley_Owen_Attribution:badN'), 'bad n');

v10 = hash_game(10, 7919, 13);
[p10, i10] = Shapley_Owen_Attribution(v10, 10, {1:3, 4:6, 7:10});
check(abs(i10.efficiency_gap) < 1e-8, 'n = 10 Owen efficiency');
check(max(abs(Shapley_Owen_Attribution(v10, 10, {1:10}) - Shapley_Owen_Attribution(v10, 10, num2cell(1:10)))) < 1e-8, 'n = 10 grand union == singletons');
end

% -------------------------------------------------------------------------
function v = hash_game(n, a, b)
% Deterministic pseudo-random coalition values (identical in MATLAB and Octave); v(empty) ~= 0.
masks = (0:2^n - 1)';
pc    = zeros(size(masks));                      % number of players in each coalition
for k = 1:n, pc = pc + bitget(masks, k); end
v     = mod(masks * a + b * pc .^ 2 + 13, 101) / 10;
end

function phi = brute_force(v, n, unions)
% Average marginal contribution over all orderings in which each union's members are contiguous.
orders = zeros(1, 0);
for P = perms(1:numel(unions))'                    % each column of P' is one ordering of the unions
    block = zeros(1, 0);
    for k = P'
        inner = perms(unions{k});                  % all internal orderings of union k
        nb = size(block, 1);  ni = size(inner, 1);
        grown = zeros(nb * ni, size(block, 2) + size(inner, 2));
        r = 0;
        for ia = 1:nb
            for ic = 1:ni
                r = r + 1;
                grown(r, :) = [block(ia, :), inner(ic, :)];
            end
        end
        block = grown;
    end
    orders = [orders; block]; %#ok<AGROW>
end
phi = zeros(n, 1);
for r = 1:size(orders, 1)
    mask = 0;
    for p = orders(r, :)
        phi(p) = phi(p) + v(mask + 2^(p - 1) + 1) - v(mask + 1);
        mask   = mask + 2^(p - 1);
    end
end
phi = phi / size(orders, 1);
end

function tf = fails_with(f, id)
tf = false;
try
    f();
catch err
    tf = strcmp(err.identifier, id);
end
end

function check(cond, msg)
if ~cond, error('test_Shapley_Owen_Attribution:failed', 'FAILED: %s', msg); end
end
