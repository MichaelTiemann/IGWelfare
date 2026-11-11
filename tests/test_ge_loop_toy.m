function test_ge_loop_toy()
%% TEST_GE_LOOP_TOY  Solve_Spatial_GE_Loop on a 2-region analytic toy economy
% File: tests/test_ge_loop_toy.m
% Throws on failure, prints nothing on success. Runs under MATLAB and Octave;
% no toolboxes, no GPU. Set the environment variable IGW_TEST_REPORT=1 to print
% the iteration counts (they are asserted against generous ceilings either way).
%
% Toy economy, prices p = [w1 w2 Q1 Q2 r]:
%   Firms (CRS): Y_k = A_k K_k^(1-a) L_k^a,  labour demand
%       Ld_k(w_k; K_k) = (a*A_k/w_k)^(1/(1-a)) * K_k,  K_k(r) = L_k*((1-a)*A_k/(r+delta))^(1/a)
%   Labour supply fixed at Lbar_k;  capital supply fixed at Kbar.
%   Housing: supply S_k = s_k*Q_k^eta_k,  demand D_k = d_k*w_k^theta*Q_k^(-sigma_k)
%   Residuals (relative excess demand, (demand - supply)/supply):
%       [Ld1/L1-1; Ld2/L2-1; (D1-S1)/S1; (D2-S2)/S2; sum_k K_k(r)/Kbar-1]
% Closed form: u=r+delta=(1-a)*(sum_k L_k*A_k^(1/a)/Kbar)^a, K_k=L_k*((1-a)A_k/u)^(1/a),
%   w_k=a*A_k*(K_k/L_k)^(1-a),  Q_k=(d_k*w_k^theta/s_k)^(1/(eta_k+sigma_k)).

addpath(fileparts(fileparts(mfilename('fullpath'))));
report = strcmp(getenv('IGW_TEST_REPORT'), '1');

[F, truth, p0] = toy_economy();
tol_price = 1e-8;

% --- sanity of the closed form itself (guards the test, not the solver) -----
assert(norm(F(truth), Inf) < 1e-12, 'toy: analytic prices do not clear the toy markets');

% --- 1. damped fixed point with adaptive damping ---------------------------
% step = typical price scale (proportional tatonnement); without it the stiff r-market caps lambda
o = struct('method', 'damped', 'tol', 1e-10, 'max_iter', 500, 'damping', 0.5, 'step', abs(p0));
[p1, res1, h1] = Solve_Spatial_GE_Loop(p0, F, o);
r1 = res1.residual;
assert(res1.converged && h1.converged && norm(r1, Inf) < 1e-10, 'damped: residual not below tol');
assert(max(abs(p1 - truth)) < tol_price, 'damped: prices differ from analytic by > 1e-8');
assert(h1.n_iter == size(h1.price, 1) - 1 && h1.n_eval == h1.n_iter + 1, 'damped: history/eval bookkeeping');
assert(h1.n_iter < 150, 'damped: iteration count above regression ceiling');

% --- 2. good-Broyden quasi-Newton (finite-difference initial Jacobian) -----
o = struct('method', 'broyden', 'tol', 1e-10, 'max_iter', 100);
[p2, res2, h2] = Solve_Spatial_GE_Loop(p0, F, o);
r2 = res2.residual;
assert(res2.converged && h2.converged && norm(r2, Inf) < 1e-10, 'broyden: residual not below tol');
assert(max(abs(p2 - truth)) < tol_price, 'broyden: prices differ from analytic by > 1e-8');
assert(h2.n_iter < 40, 'broyden: iteration count above regression ceiling');

% --- 2b. good-Broyden with the cheap diagonal initial Jacobian -------------
o = struct('method', 'broyden', 'jac0', 'diag', 'damping', 0.5, 'step', abs(p0), 'tol', 1e-10, 'max_iter', 300);
[p2b, ~, h2b] = Solve_Spatial_GE_Loop(p0, F, o);
assert(h2b.converged && max(abs(p2b - truth)) < tol_price, 'broyden(diag): did not recover analytic prices');

% --- 3. non-convergence at max_iter = 1 ------------------------------------
% 3a. DEFAULT (on_fail='warn'): warning IGW:NoConvergence, converged == false,
%     last iterate returned. The warning is captured by promoting it to an error
%     with warning('error', id) (MATLAB does not record disabled warnings in
%     lastwarn, so lastwarn is not used); the outputs are then checked in a second
%     call with the warning switched off. Nothing is printed.
wid_nc = 'IGW:NoConvergence';
for m = {'damped', 'broyden'}
    for explicit = [false true]
        o = struct('method', m{1}, 'tol', 1e-10, 'max_iter', 1);
        if explicit, o.on_fail = 'warn'; end
        ws = warning('error', wid_nc);
        caught = [];
        try
            Solve_Spatial_GE_Loop(p0, F, o);
        catch err
            caught = err;
        end
        warning(ws);
        assert(~isempty(caught), 'default (%s): no IGW:NoConvergence warning raised', m{1});
        assert(strcmp(caught.identifier, wid_nc), 'default (%s): wrong warning id "%s"', m{1}, caught.identifier);
        assert(~isempty(regexp(caught.message, '^Solve_Spatial_GE_Loop: 1 iterations, residual [0-9.eE+-]+$', 'once')), ...
            'default (%s): warning message "%s" does not match the contract', m{1}, caught.message);

        ws = warning('off', wid_nc);
        [pw, resw, hw] = Solve_Spatial_GE_Loop(p0, F, o);
        warning(ws);
        assert(~resw.converged && ~hw.converged && resw.n_iter == 1, 'default (%s): converged flag/iteration count wrong', m{1});
        assert(all(isfinite(pw)) && all(isfinite(resw.residual)) && isequal(size(pw), size(p0)), ...
            'default (%s): last iterate not returned', m{1});
        assert(abs(resw.res_inf - norm(resw.residual, Inf)) < 1e-15 && resw.res_inf == hw.res_inf(end), 'default (%s): res_inf inconsistent', m{1});
    end
end
% a converged run must NOT warn (any warning would be promoted to an error here)
ws = warning('error', wid_nc);
caught = [];
try
    [~, resok] = Solve_Spatial_GE_Loop(p0, F, struct('method', 'broyden', 'tol', 1e-10, 'max_iter', 100));
catch err
    caught = err;
end
warning(ws);
assert(isempty(caught) && resok.converged, 'a converged run raised a warning or did not converge');

% 3b. on_fail = 'error' raises IGW:NoConvergence with the contract message
for m = {'damped', 'broyden'}
    caught = [];
    try
        Solve_Spatial_GE_Loop(p0, F, struct('method', m{1}, 'tol', 1e-10, 'max_iter', 1, 'on_fail', 'error'));
    catch err
        caught = err;
    end
    assert(~isempty(caught), 'on_fail=error (%s): no error raised', m{1});
    assert(strcmp(caught.identifier, 'IGW:NoConvergence'), 'on_fail=error (%s): wrong identifier "%s"', m{1}, caught.identifier);
    assert(~isempty(regexp(caught.message, '^Solve_Spatial_GE_Loop: 1 iterations, residual [0-9.eE+-]+$', 'once')), ...
        'on_fail=error (%s): message "%s" does not match the contract', m{1}, caught.message);
end
expect_id(@() Solve_Spatial_GE_Loop(p0, F, struct('on_fail', 'ignore')), 'IGW:BadOption');

% --- 4. price floors are respected, and actually bind (both methods) --------
fl = truth .* [0.95; 0.8; 0.95; 0.7; 0.9];       % all strictly below the equilibrium
[p4, ~, h4] = Solve_Spatial_GE_Loop(p0, F, struct('tol', 1e-10, 'max_iter', 500, 'bounds', fl, 'step', abs(p0)));
assert(h4.converged && max(abs(p4 - truth)) < tol_price, 'bounds(damped): prices differ from analytic');
assert(all(all(h4.price >= repmat(fl', size(h4.price, 1), 1))), 'bounds(damped): a floor was violated');
assert(any(abs(h4.price(:, 1) - fl(1)) <= 1e-12), 'bounds(damped): floor on w1 never bound (test no longer exercises projection)');
[p4b, ~, h4b] = Solve_Spatial_GE_Loop(p0, F, struct('method', 'broyden', 'tol', 1e-10, 'max_iter', 200, 'bounds', fl));
assert(h4b.converged && max(abs(p4b - truth)) < tol_price, 'bounds(broyden): prices differ from analytic');
assert(all(all(h4b.price >= repmat(fl', size(h4b.price, 1), 1))), 'bounds(broyden): a floor was violated');
assert(any(abs(h4b.price(:, 5) - fl(5)) <= 1e-12), 'bounds(broyden): floor on r never bound (test no longer exercises projection)');

% --- 5. shape is preserved ---------------------------------------------------
Frow = @(pp) F(pp(:))';
p5 = Solve_Spatial_GE_Loop(p0', Frow, struct('tol', 1e-10, 'max_iter', 500, 'step', abs(p0)));
assert(isequal(size(p5), [1 5]) && max(abs(p5' - truth)) < tol_price, 'shape: row input not preserved');

% --- 6. input validation fails loud -----------------------------------------
expect_id(@() Solve_Spatial_GE_Loop(p0, F, struct('tolerance', 1e-6)), 'IGW:BadOption');
expect_id(@() Solve_Spatial_GE_Loop(p0, F, struct('method', 'newton')), 'IGW:BadOption');
expect_id(@() Solve_Spatial_GE_Loop(p0, @(pp) pp(1:4), struct()), 'IGW:BadResidual');
expect_id(@() Solve_Spatial_GE_Loop(p0, @(pp) NaN(5, 1), struct()), 'IGW:BadResidual');
expect_id(@() Solve_Spatial_GE_Loop(p0, 'not a handle', struct()), 'IGW:BadInput');

if report
    fprintf('test_ge_loop_toy: damped   n_iter=%d n_eval=%d |z|=%.2e max|p-p*|=%.2e\n', h1.n_iter, h1.n_eval, norm(r1, Inf), max(abs(p1 - truth)));
    fprintf('test_ge_loop_toy: broyden  n_iter=%d n_eval=%d |z|=%.2e max|p-p*|=%.2e (jac0=fd)\n', h2.n_iter, h2.n_eval, norm(r2, Inf), max(abs(p2 - truth)));
    fprintf('test_ge_loop_toy: broyden  n_iter=%d n_eval=%d max|p-p*|=%.2e (jac0=diag)\n', h2b.n_iter, h2b.n_eval, max(abs(p2b - truth)));
    fprintf('test_ge_loop_toy: floors   damped n_iter=%d, broyden n_iter=%d (floors binding)\n', h4.n_iter, h4b.n_iter);
end
end

%% ------------------------------------------------------------------------
function [F, truth, p0] = toy_economy()
a = 0.64;  delta = 0.06;  r_star = 0.04;
A = [1.0; 1.4];  L = [0.4; 0.6];
eta = [0.9; 0.4];  sig = [1.2; 0.8];  theta = 0.7;  s = [1; 1];  d = [0.8; 1.5];
Kbar = sum(L .* A .^ (1 / a)) * ((1 - a) / (r_star + delta)) ^ (1 / a);   % calibrates r* = 0.04

% closed-form equilibrium
u  = (1 - a) * (sum(L .* A .^ (1 / a)) / Kbar) ^ a;
K  = L .* ((1 - a) * A / u) .^ (1 / a);
w  = a * A .* (K ./ L) .^ (1 - a);
Q  = (d .* w .^ theta ./ s) .^ (1 ./ (eta + sig));
truth = [w; Q; u - delta];
p0    = truth .* [1.4; 0.7; 1.5; 0.6; 1] + [0; 0; 0; 0; 0.03];

F = @(p) toy_excess(p, a, delta, A, L, eta, sig, theta, s, d, Kbar);
end

function z = toy_excess(p, a, delta, A, L, eta, sig, theta, s, d, Kbar)
p = p(:);
w = p(1:2);  Q = p(3:4);  r = p(5);
K  = L .* ((1 - a) * A / (r + delta)) .^ (1 / a);        % capital demanded at user cost r+delta
Ld = K .* (a * A ./ w) .^ (1 / (1 - a));                 % labour demanded given that capital
D  = d .* w .^ theta .* Q .^ (-sig);
S  = s .* Q .^ eta;
z  = [Ld ./ L - 1; (D - S) ./ S; sum(K) / Kbar - 1];     % relative excess demands
end

function expect_id(fh, id)
caught = [];
try
    fh();
catch err
    caught = err;
end
assert(~isempty(caught), 'expected error %s but none was raised', id);
assert(strcmp(caught.identifier, id), 'expected %s, got "%s": %s', id, caught.identifier, caught.message);
end
