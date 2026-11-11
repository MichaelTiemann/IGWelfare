function test_configure_timegrid_idempotent()
%% TEST_CONFIGURE_TIMEGRID_IDEMPOTENT
% Regression test for the idempotency made upstream in 9e03acd ("Atomic Idempotent Contract Fixes").
% Run_All_NZ_Intergen_Suite.m, NZ_4Region_Master.m and WelfareDecomposition_4Region.m each call
% Configure_TimeGrid_Params on an already-configured Params, so repeated calls must leave Params unchanged.
% This test only asserts that, plus the PType-keyed struct convention, against upstream's function.
% Throws on failure, silent on success. No toolboxes, no GPU; runs under MATLAB and GNU Octave.
addpath(fileparts(fileparts(mfilename('fullpath'))));

% 1. Repeated calls at dt = 3 must not change anything
P1 = Configure_TimeGrid_Params(struct(), 3);
P2 = Configure_TimeGrid_Params(P1, 3);
P3 = Configure_TimeGrid_Params(P2, 3);
check(P2.beta_hh   == P1.beta_hh,   'beta_hh changed on the second call (dt = 3)');
check(P2.beta_firm == P1.beta_firm, 'beta_firm changed on the second call (dt = 3)');
check(P3.beta_hh   == P1.beta_hh,   'beta_hh changed on the third call (dt = 3)');
check(isequal(P1, P2) && isequal(P2, P3), 'Params differs after repeated Configure_TimeGrid_Params calls (dt = 3)');

% 2. Same at the other supported grids
for dt = [5 2 1]
    A = Configure_TimeGrid_Params(struct(), dt);
    B = Configure_TimeGrid_Params(A, dt);
    check(isequal(A, B), sprintf('Params not idempotent at dt = %d', dt));
end

% 3. Struct-valued Params fields are keyed by PType names (HH_* / Firm_*), as the VFI Toolkit reads struct
% parameters per PType
T = Configure_TimeGrid_Params(Configure_TimeGrid_Params(struct(), 3), 3);
fn = fieldnames(T);
for k = 1:numel(fn)
    if isstruct(T.(fn{k}))
        sub = fieldnames(T.(fn{k}));
        check(all(strncmp(sub, 'HH_', 3) | strncmp(sub, 'Firm_', 5)), ...
            sprintf('struct-valued Params field %s is not keyed by PType names', fn{k}));
    end
end
end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_configure_timegrid_idempotent: %s', msg);
end
end
