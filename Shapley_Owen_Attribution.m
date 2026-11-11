
function [phi, info] = Shapley_Owen_Attribution(v, n, unions)
% SHAPLEY_OWEN_ATTRIBUTION
% Order-invariant attribution of a joint welfare gain to n policy levers.
%   - Shapley value: the average marginal contribution of each lever over ALL n! orderings.
%   - Owen value (Shapley with a priori unions): the same average, restricted to orderings in
%     which the members of each union (coalition) enter contiguously, e.g. the four
%     Document 3 coalitions (Barnardos/Youth, WellBeing/Housing, GrowthNZ, Fiscal Stewards).
% Neither value depends on the order in which levers are layered, unlike a single-path
% decomposition Wedge = CE(A u B) - CE(A) - CE(B), whose split between wedges changes if the
% build order changes.
%
% Pure MATLAB / GNU Octave, no toolboxes. Requires implicit expansion (MATLAB R2016b+, Octave).
% Exact closed-form enumeration (no sampling); cost O(n * 2^n), intended for n <= 10 (hard cap 16).
%
% USAGE
%   [phi, info] = Shapley_Owen_Attribution(v, n)            % Shapley value
%   [phi, info] = Shapley_Owen_Attribution(v, n, unions)    % Owen value
%
% INPUTS
%   v      Coalition value function v(S), S a subset of the n levers, either
%            (a) a function handle v(mask) returning a real scalar, where mask is a BITMASK INTEGER
%                (double): bit k set (value 2^(k-1)) <=> lever k is in the coalition, so mask = 0 is the
%                empty coalition (the SS0 baseline) and mask = 2^n - 1 is the grand coalition; or
%            (b) a vector of length 2^n indexed by bitmask + 1, i.e. v(mask + 1) is the value of mask.
%          Entries that have not been run may be NaN: the call succeeds if the values it needs are
%          present and otherwise errors listing the missing coalitions (see info.masks_needed).
%   n      Number of levers (players), 1 <= n <= 16.
%   unions Optional. Omitted or empty -> Shapley. Otherwise a cell array of index vectors that
%          partitions 1:n (disjoint, non-empty, covering), e.g. {[1 2], 3, [4 5], [6 7]} -> Owen value.
%
% OUTPUTS
%   phi    n x 1 attribution vector. sum(phi) = v(grand) - v(empty) (efficiency).
%   info   struct:
%            .method           'Shapley' or 'Owen'
%            .unions           the partition used (cell array)
%            .efficiency_gap   sum(phi) - (v(grand) - v(empty)); zero up to rounding
%            .interactions     n x n matrix, I(i,j) = v({i,j}) - v({i}) - v({j}) + v(empty), i ~= j;
%                              zero diagonal; NaN where an input value is missing. Computed only when
%                              the second output is requested.
%            .n_evaluations    number of distinct coalition values read (calls to v if a handle)
%            .masks_needed     sorted bitmasks of the coalitions whose values phi depends on
%
% FORMULA (Owen, 1977). Partition the n levers into m unions B_1..B_m; lever i is in union B_k, |B_k| = b.
%   phi_i = sum over Q subset of M\{k}, T subset of B_k\{i} of
%             [ q!(m-q-1)!/m! ] [ t!(b-t-1)!/b! ] * ( v(B_Q u T u {i}) - v(B_Q u T) ),
%   q = |Q|, t = |T|, B_Q = union of B_j for j in Q. One grand union (m = 1) and all-singleton unions
%   (m = n) both reduce to the Shapley value; for a game whose only interactions are pairwise the Owen
%   value equals the Shapley value for every partition.

if nargin < 3, unions = []; end
if nargin < 2 || ~isnumeric(n) || ~isscalar(n) || n < 1 || n ~= floor(n) || n > 16
    error('Shapley_Owen_Attribution:badN', 'n must be an integer between 1 and 16.');
end

% =========================================================================
% 1. VALIDATE INPUTS AND DEFINE THE UNION STRUCTURE
% =========================================================================
n_mask = 2^n;
grand  = n_mask - 1;
bit    = 2 .^ (0:n-1);                      % bit(k) = mask of lever k alone

use_fcn = isa(v, 'function_handle');
if use_fcn
    V = NaN(n_mask, 1);                     % filled lazily, only where needed
else
    V = double(v(:));
    if numel(V) ~= n_mask
        error('Shapley_Owen_Attribution:badV', 'Vector v must have 2^n = %d entries (indexed by bitmask + 1).', n_mask);
    end
end

if isempty(unions)
    unions = {1:n};  method = 'Shapley';
else
    method = 'Owen';
    if ~iscell(unions)
        error('Shapley_Owen_Attribution:badUnions', 'unions must be a cell array of index vectors.');
    end
    unions = unions(:)';
    all_idx = [];
    for k = 1:numel(unions)
        u = unions{k}(:)';
        if isempty(u) || ~isnumeric(u) || any(u ~= floor(u)) || any(u < 1) || any(u > n)
            error('Shapley_Owen_Attribution:badUnions', 'Union %d must be a non-empty vector of integers in 1..%d.', k, n);
        end
        unions{k} = u;
        all_idx   = [all_idx, u]; %#ok<AGROW>
    end
    if numel(all_idx) ~= n || ~isequal(sort(all_idx), 1:n)
        error('Shapley_Owen_Attribution:badUnions', 'unions must partition 1:%d (disjoint and covering).', n);
    end
end
m    = numel(unions);
ubit = zeros(1, m);                         % mask of each union
for k = 1:m, ubit(k) = sum(bit(unions{k})); end

% =========================================================================
% 2. ENUMERATE THE COALITIONS EACH LEVER'S MARGINAL CONTRIBUTIONS NEED, WITH WEIGHTS
% =========================================================================
Base = cell(n, 1);                          % Base{i}: |Q-subsets| x |T-subsets| masks of B_Q u T
Wgt  = cell(n, 1);                          % matching Owen weights
for k = 1:m
    members = unions{k};
    b       = numel(members);
    [BQ, wQ] = subset_masks(ubit(setdiff(1:m, k)), m);
    for i = members
        [T, wT] = subset_masks(bit(members(members ~= i)), b);
        Base{i} = BQ(:) + T(:)';            % B_Q and T are disjoint, so + is union
        Wgt{i}  = wQ(:) * wT(:)';
    end
end

needed = [];
for i = 1:n
    needed = [needed; Base{i}(:); Base{i}(:) + bit(i)]; %#ok<AGROW>
end
needed = unique(needed);

% =========================================================================
% 3. READ OR EVALUATE THE REQUIRED COALITION VALUES
% =========================================================================
if use_fcn
    for c = needed(:)'
        V(c + 1) = v(c);
    end
end
miss = needed(isnan(V(needed + 1)));
if ~isempty(miss)
    error('Shapley_Owen_Attribution:missingValues', ...
          '%d required coalition value(s) missing or NaN, e.g. %s', numel(miss), mask_list(miss(1:min(5, end)), n));
end

% =========================================================================
% 4. ASSEMBLE THE ATTRIBUTION
% =========================================================================
phi = zeros(n, 1);
for i = 1:n
    gain   = reshape(V(Base{i}(:) + bit(i) + 1) - V(Base{i}(:) + 1), size(Base{i}));
    phi(i) = sum(sum(Wgt{i} .* gain));
end

read = unique([needed(:); 0; grand]);
info.method         = method;
info.unions         = unions;
info.efficiency_gap = sum(phi) - (V(grand + 1) - V(1));
info.masks_needed   = needed;

if nargout > 1
    I = zeros(n);
    pair_masks = [];
    for i = 1:n
        for j = i+1:n
            pair_masks(end+1) = bit(i) + bit(j); %#ok<AGROW>
        end
    end
    extra = unique([0, bit, pair_masks]);
    read  = unique([read; extra(:)]);
    if use_fcn
        for c = extra(isnan(V(extra + 1)))
            V(c + 1) = v(c);
        end
    end
    for i = 1:n
        for j = i+1:n
            I(i, j) = V(bit(i) + bit(j) + 1) - V(bit(i) + 1) - V(bit(j) + 1) + V(1);
            I(j, i) = I(i, j);
        end
    end
    info.interactions = I;
end
info.n_evaluations = numel(read);
end

% -------------------------------------------------------------------------
function [sums, w] = subset_masks(vals, sz)
% All 2^r subset sums of the r (bit-disjoint) masks in vals, with Shapley-type weights
% q!(sz-q-1)!/sz! for a subset of cardinality q, where sz is the size of the surrounding set.
r    = numel(vals);
idx  = (0:2^r - 1)';
sel  = mod(floor(idx ./ 2 .^ (0:r-1)), 2);          % 2^r x r membership indicators
sums = sel * vals(:);
card = sum(sel, 2);
w    = factorial(card) .* factorial(sz - 1 - card) / factorial(sz);
end

function s = mask_list(masks, n)
% Human-readable list of coalitions, e.g. {1,3},{2}
parts = cell(1, numel(masks));
for c = 1:numel(masks)
    members = find(bitget(masks(c), 1:n));
    parts{c} = ['{' strjoin(arrayfun(@num2str, members, 'UniformOutput', false), ',') '}'];
end
s = strjoin(parts, ', ');
end
