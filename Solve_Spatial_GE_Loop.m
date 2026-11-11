function [prices, res, hist] = Solve_Spatial_GE_Loop(prices0, excess_demand_fn, opts)
%% SOLVE_SPATIAL_GE_LOOP  TOOLKIT-INDEPENDENT MARKET-CLEARING SOLVER
% File: Solve_Spatial_GE_Loop.m
% Scaffold: solver logic tested on an analytic toy economy; not yet wired to the VFI Toolkit household block (see docs/GE_Closure_Spec.md).
%
% Finds the price vector p* such that excess_demand_fn(p*) = 0. The caller
% assembles the residual vector (regional labour markets, regional housing
% markets, capital/bond market, in any order it chooses), so the household
% block (VFI + stationary distribution) can be plugged in later without
% touching this file. Pure MATLAB/Octave: no toolboxes, no GPU.
%
% USAGE
%   [prices, res, hist] = Solve_Spatial_GE_Loop(prices0, excess_demand_fn, opts)
%
% INPUTS
%   prices0           : initial price vector (any shape; the shape is preserved)
%   excess_demand_fn  : handle, z = excess_demand_fn(prices); z is a vector with
%                       numel(z) == numel(prices0) (square system). SIGN
%                       CONVENTION: z = demand - supply, so z_i > 0 pushes price i UP.
%   opts (all optional; unknown field names are an error, to catch typos):
%     .method    'damped' (default) | 'broyden'
%                'damped' : p <- p + lambda .* step .* z, with adaptive lambda:
%                           a step that does not lower ||z||_2 is rejected and
%                           lambda is multiplied by opts.shrink; an accepted step
%                           multiplies lambda by opts.grow (capped at damping_max).
%                'broyden': quasi-Newton on z(p) = 0 with the "good" Broyden
%                           update of the inverse Jacobian and a halving line
%                           search on ||z||_2 (resets to the initial Jacobian
%                           if the line search fails).
%     .tol       convergence tolerance on ||z||_inf          (default 1e-8)
%                (steps are accepted on the 2-norm merit ||z||_2: with coupled
%                markets the max-norm can rise for every small step even when
%                the iteration is converging; found while testing the toy)
%     .max_iter  maximum loop passes                         (default 200)
%     .damping   initial damping lambda for 'damped'; for 'broyden' it scales
%                the initial inverse Jacobian when jac0 = 'diag'  (default 0.5)
%     .verbose   true/false, print one line per pass         (default false)
%     .bounds    price floors: scalar, or vector with numel == numel(prices0)
%                (NaN/-Inf = no floor). Trial prices are projected onto the
%                floors. Floors are a safeguard to keep iterates inside the
%                domain of the household block; a corner solution (floor
%                binding with excess supply) is NOT treated as cleared.
%     .on_fail   'warn' (default) | 'error'   what to do at max_iter without tol:
%                'warn' issues warning('IGW:NoConvergence', ...) and returns the last
%                accepted iterate with res.converged = false; 'error' raises it.
%     .step      per-price scaling of the damped update (default ones)
%     .damping_max, .damping_min, .grow, .shrink
%                bounds / factors for the adaptive lambda
%                (defaults 1, 1e-8, 1.2, 0.5)
%     .jac0      'broyden' initial Jacobian: 'fd' (default; forward finite
%                differences, numel(prices0) extra evaluations), 'diag'
%                (-1/damping on the diagonal; no extra evaluations), or a
%                numeric n-by-n matrix dz/dp.
%     .fd_step   relative finite-difference step for jac0='fd' (default 1e-6)
%
% OUTPUTS
%   prices : final price vector (same shape as prices0)
%   res    : result struct: .converged (logical), .residual (column vector
%            excess_demand_fn(prices)), .res_inf (its max-norm), .n_iter, .n_eval
%   hist   : struct with one row per pass (row 1 = initial point):
%              .price (iter+1 x n), .res_inf, .res_2 (residual norms),
%              .step (lambda or line-search factor), .accepted,
%              .n_iter, .n_eval (excess_demand_fn calls), .converged, .method
%
% SCALING (measured on the toy in tests/test_ge_loop_toy.m): express z as relative
% excess demand and set opts.step to typical price magnitudes. With step = 1 and
% raw prices, a stiff market (the interest rate) caps lambda and 'damped' did not
% converge in 20000 passes on the toy; with step = abs(prices0) it took 68.
%
% NON-CONVERGENCE: at max_iter without ||z||_inf < tol the default (opts.on_fail =
% 'warn') issues
%   warning('IGW:NoConvergence', 'Solve_Spatial_GE_Loop: %d iterations, residual %.3g')
% and returns the last accepted iterate with res.converged = false (also
% hist.converged), so a long run is captured rather than lost. Callers must check
% res.converged. opts.on_fail = 'error' raises the same identifier and message
% as an error instead (no outputs are returned in that case).

if nargin < 3 || isempty(opts), opts = struct(); end
if ~isa(excess_demand_fn, 'function_handle')
    error('IGW:BadInput', 'Solve_Spatial_GE_Loop: excess_demand_fn must be a function handle');
end
if ~isnumeric(prices0) || isempty(prices0) || any(~isfinite(prices0(:)))
    error('IGW:BadInput', 'Solve_Spatial_GE_Loop: prices0 must be a non-empty finite numeric array');
end
opt    = igw_fill_options(opts);
shape0 = size(prices0);
n      = numel(prices0);
floor_p = igw_expand_floor(opt.bounds, n);
step   = igw_expand_vec(opt.step, n, 'step');

p = max(double(prices0(:)), floor_p);
z = igw_eval(excess_demand_fn, p, shape0, n);
if any(~isfinite(z))
    error('IGW:BadResidual', 'Solve_Spatial_GE_Loop: non-finite residual at the initial prices');
end
n_eval = 1;
nz     = norm(z, Inf);    % convergence measure
mz     = norm(z, 2);      % merit for accepting steps (the max-norm is not a descent merit for coupled markets)

% History buffers (row 1 = initial point)
H_price = nan(opt.max_iter + 1, n);  H_inf = nan(opt.max_iter + 1, 1);
H_two   = nan(opt.max_iter + 1, 1);  H_step = nan(opt.max_iter + 1, 1);
H_acc   = false(opt.max_iter + 1, 1);
H_price(1, :) = p';  H_inf(1) = nz;  H_two(1) = mz;  H_acc(1) = true;

it = 0;
if strcmp(opt.method, 'damped')
    %% DAMPED FIXED POINT WITH ADAPTIVE DAMPING
    lam = opt.damping;
    while nz >= opt.tol && it < opt.max_iter
        it    = it + 1;
        p_try = max(p + lam .* step .* z, floor_p);
        z_try = igw_eval(excess_demand_fn, p_try, shape0, n);
        n_eval = n_eval + 1;
        nz_try = norm(z_try, Inf);
        mz_try = norm(z_try, 2);
        used   = lam;
        if isfinite(mz_try) && mz_try < mz
            p = p_try;  z = z_try;  nz = nz_try;  mz = mz_try;
            lam = min(opt.damping_max, lam * opt.grow);
            acc = true;
        else
            lam = max(opt.damping_min, lam * opt.shrink);
            acc = false;
        end
        [H_price, H_inf, H_two, H_step, H_acc] = igw_record(H_price, H_inf, H_two, H_step, H_acc, ...
            it, p, z, nz, mz, used, acc);
        if opt.verbose
            fprintf('  GE damped  iter %3d  |z|_inf = %.3e  lambda = %.3g  %s\n', it, nz, used, igw_tag(acc));
        end
    end
else
    %% GOOD-BROYDEN QUASI-NEWTON WITH HALVING LINE SEARCH
    [H0, n_extra] = igw_initial_inverse(opt, excess_demand_fn, p, z, shape0, n, step);
    n_eval = n_eval + n_extra;
    Hinv   = H0;
    while nz >= opt.tol && it < opt.max_iter
        it     = it + 1;
        s_full = -Hinv * z;
        t      = 1;
        ok     = false;
        while true
            p_try = max(p + t * s_full, floor_p);
            z_try = igw_eval(excess_demand_fn, p_try, shape0, n);
            n_eval = n_eval + 1;
            nz_try = norm(z_try, Inf);
            mz_try = norm(z_try, 2);
            if isfinite(mz_try) && mz_try <= (1 - 1e-4 * t) * mz
                ok = true;  break;
            end
            t = t / 2;
            if t < 1e-4, break; end
        end
        if ok
            s = p_try - p;  y = z_try - z;
            Hy = Hinv * y;  den = s' * Hy;
            if abs(den) > 1e-14 * norm(s) * norm(Hy)
                Hinv = Hinv + ((s - Hy) * (s' * Hinv)) / den;   % good Broyden (inverse form)
            end
            p = p_try;  z = z_try;  nz = nz_try;  mz = mz_try;  acc = true;
        else
            acc = false;
            if ~isequal(Hinv, H0)
                Hinv = H0;                                      % line search failed: restart from H0
            elseif isfinite(mz_try)
                p = p_try;  z = z_try;  nz = nz_try;  mz = mz_try;  acc = true; % H0 already: take the smallest step
            end
        end
        [H_price, H_inf, H_two, H_step, H_acc] = igw_record(H_price, H_inf, H_two, H_step, H_acc, ...
            it, p, z, nz, mz, t, acc);
        if opt.verbose
            fprintf('  GE broyden iter %3d  |z|_inf = %.3e  t = %.3g  %s\n', it, nz, t, igw_tag(acc));
        end
    end
end

converged = (nz < opt.tol);
hist = struct('method', opt.method, 'tol', opt.tol, ...
    'price', H_price(1:it+1, :), 'res_inf', H_inf(1:it+1), 'res_2', H_two(1:it+1), ...
    'step', H_step(1:it+1), 'accepted', H_acc(1:it+1), ...
    'n_iter', it, 'n_eval', n_eval, 'converged', converged);
prices = reshape(p, shape0);
res    = struct('converged', converged, 'residual', z, 'res_inf', nz, 'n_iter', it, 'n_eval', n_eval);

if ~converged
    if strcmpi(opt.on_fail, 'warn')
        warning('IGW:NoConvergence', 'Solve_Spatial_GE_Loop: %d iterations, residual %.3g', it, nz);
    else
        error('IGW:NoConvergence', 'Solve_Spatial_GE_Loop: %d iterations, residual %.3g', it, nz);
    end
end
end

%% ------------------------------------------------------------------------
%  LOCAL HELPERS
%  ------------------------------------------------------------------------
function opt = igw_fill_options(opts)
if ~isstruct(opts), error('IGW:BadInput', 'Solve_Spatial_GE_Loop: opts must be a struct'); end
opt = struct('method', 'damped', 'tol', 1e-8, 'max_iter', 200, 'damping', 0.5, ...
    'verbose', false, 'bounds', [], 'on_fail', 'warn', 'step', 1, ...
    'damping_max', 1, 'damping_min', 1e-8, 'grow', 1.2, 'shrink', 0.5, ...
    'jac0', 'fd', 'fd_step', 1e-6);
fn = fieldnames(opts);
for k = 1:numel(fn)
    if ~isfield(opt, fn{k})
        error('IGW:BadOption', 'Solve_Spatial_GE_Loop: unknown option "%s"', fn{k});
    end
    opt.(fn{k}) = opts.(fn{k});
end
opt.method = lower(opt.method);
if ~any(strcmp(opt.method, {'damped', 'broyden'}))
    error('IGW:BadOption', 'Solve_Spatial_GE_Loop: method must be ''damped'' or ''broyden'' (got "%s")', opt.method);
end
if ~any(strcmpi(opt.on_fail, {'error', 'warn'}))
    error('IGW:BadOption', 'Solve_Spatial_GE_Loop: on_fail must be ''error'' or ''warn''');
end
if ~(isscalar(opt.tol) && opt.tol > 0) || ~(isscalar(opt.max_iter) && opt.max_iter >= 1) ...
        || ~(isscalar(opt.damping) && opt.damping > 0)
    error('IGW:BadOption', 'Solve_Spatial_GE_Loop: tol, max_iter and damping must be positive scalars');
end
opt.max_iter = floor(opt.max_iter);
end

function f = igw_expand_floor(b, n)
if isempty(b), f = -Inf(n, 1); return; end
f = igw_expand_vec(b, n, 'bounds');
f(isnan(f)) = -Inf;
end

function v = igw_expand_vec(x, n, name)
x = double(x(:));
if numel(x) == 1
    v = repmat(x, n, 1);
elseif numel(x) == n
    v = x;
else
    error('IGW:BadOption', 'Solve_Spatial_GE_Loop: opts.%s must be a scalar or have %d elements', name, n);
end
end

function z = igw_eval(fn, p, shape0, n)
z = fn(reshape(p, shape0));
z = double(z(:));
if numel(z) ~= n
    error('IGW:BadResidual', ...
        'Solve_Spatial_GE_Loop: excess_demand_fn returned %d residuals for %d prices (system must be square)', numel(z), n);
end
end

function [H0, n_extra] = igw_initial_inverse(opt, fn, p, z, shape0, n, step)
% Initial inverse Jacobian for Broyden. Falls back to the damped-step
% equivalent -damping*diag(step) if the supplied/FD Jacobian is unusable.
Hdiag   = -opt.damping * diag(step);
n_extra = 0;
if isnumeric(opt.jac0)
    J = double(opt.jac0);
    if ~isequal(size(J), [n n]), error('IGW:BadOption', 'Solve_Spatial_GE_Loop: jac0 must be %d-by-%d', n, n); end
elseif strcmpi(opt.jac0, 'diag')
    H0 = Hdiag;  return;
elseif strcmpi(opt.jac0, 'fd')
    J = zeros(n, n);
    n_extra = n;
    for i = 1:n
        h = opt.fd_step * max(1, abs(p(i)));
        q = p;  q(i) = q(i) + h;
        J(:, i) = (igw_eval(fn, q, shape0, n) - z) / h;
    end
else
    error('IGW:BadOption', 'Solve_Spatial_GE_Loop: jac0 must be ''fd'', ''diag'' or a numeric matrix');
end
if any(~isfinite(J(:))) || rcond(J) < 1e-12
    H0 = Hdiag;
else
    H0 = inv(J);
end
end

function [Hp, Hi, H2, Hs, Ha] = igw_record(Hp, Hi, H2, Hs, Ha, it, p, z, nz, mz, stp, acc) %#ok<INUSL>
Hp(it + 1, :) = p';  Hi(it + 1) = nz;  H2(it + 1) = mz;
Hs(it + 1) = stp;    Ha(it + 1) = acc;
end

function s = igw_tag(acc)
if acc, s = 'accepted'; else, s = 'rejected'; end
end
