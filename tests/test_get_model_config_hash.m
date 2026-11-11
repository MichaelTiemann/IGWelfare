function test_get_model_config_hash()
%% TEST_GET_MODEL_CONFIG_HASH
% Get_ModelConfigHash must give a whole-config key: deterministic, sensitive to a change in any array element and to a
% 1e-6 change in a scalar, a 32-char lower-case hex digest in the file name, function handles skipped.
% Runs in a scratch directory (the function creates ./Cache_NZ_Intergen). Throws on failure, silent on success.
% No toolboxes, no GPU; runs under MATLAB and GNU Octave. (The MATLAB/JVM MD5 branch is not exercised under Octave.)
addpath(fileparts(fileparts(mfilename('fullpath'))));

tmp  = tempname();
mkdir(tmp);
here = pwd;
cleanup = onCleanup(@() cleanup_dir(here, tmp)); %#ok<NASGU>
cd(tmp);

P = Configure_TimeGrid_Params(struct(), 3);
P.big = zeros(1, 20000);                       % large array: the old sampled hash ignored most of it
n_d = struct('HH_Rural', [4 3 7]); n_a = struct('HH_Rural', [61 7 9]); n_z = struct('HH_Rural', 7); N_j = struct('HH_Rural', 27, 'Firm_Rural', Inf);

[f0, c0] = Get_ModelConfigHash('tag', P, n_d, n_a, n_z, N_j);
h0 = hash_of(f0);

% 1. Format: 32 lower-case hex chars, char row, file name Cache_<tag>_<hash>.mat inside ./Cache_NZ_Intergen
check(ischar(h0) && size(h0, 1) == 1 && numel(h0) == 32 && all(ismember(h0, '0123456789abcdef')), 'hash is not a 32-char lower-case hex row');
check(~c0, 'is_cached true although no cache file exists');

% 2. Deterministic; the tag names the file but is not part of the digest
f1 = Get_ModelConfigHash('tag', P, n_d, n_a, n_z, N_j);
check(strcmp(f0, f1), 'same inputs gave different paths');
check(strcmp(hash_of(Get_ModelConfigHash('other', P, n_d, n_a, n_z, N_j)), h0), 'tag changed the digest');

% 3. Sensitivity: every deep element of a large array
miss = 0;
for idx = [1 137 5000 9999 12345 19999 20000]
    Q = P; Q.big(idx) = 1;
    if strcmp(hash_of(Get_ModelConfigHash('tag', Q, n_d, n_a, n_z, N_j)), h0), miss = miss + 1; end
end
check(miss == 0, sprintf('change in a deep array element not detected (%d of 7)', miss));

% 4. Sensitivity: 1e-6 change in a scalar, and in a nested struct field
Q = P; Q.r = Q.r + 1e-6;
check(~strcmp(hash_of(Get_ModelConfigHash('tag', Q, n_d, n_a, n_z, N_j)), h0), '1e-6 change in a scalar (r) not detected');
Q = P; Q.K_whanau_base.HH_Rural = Q.K_whanau_base.HH_Rural + 1e-6;
check(~strcmp(hash_of(Get_ModelConfigHash('tag', Q, n_d, n_a, n_z, N_j)), h0), '1e-6 change in a nested field not detected');

% 5. Grid sizes are part of the key
check(~strcmp(hash_of(Get_ModelConfigHash('tag', P, n_d, n_a, n_z, setfield(N_j, 'HH_Rural', 28))), h0), 'change in N_j not detected');

% 6. Function handles are skipped (neither error nor part of the key)
Q = P; Q.fh = @sin; Q.sub.g = @cos;
R = rmfield(Q, {'fh', 'sub'}); R.sub = struct();
check(strcmp(hash_of(Get_ModelConfigHash('tag', Q, n_d, n_a, n_z, N_j)), hash_of(Get_ModelConfigHash('tag', R, n_d, n_a, n_z, N_j))), ...
    'function-handle fields were hashed instead of skipped');

% 7. is_cached / ForceRecompute
fid = fopen(f0, 'w'); fclose(fid);
[~, c1] = Get_ModelConfigHash('tag', P, n_d, n_a, n_z, N_j);
[~, c2] = Get_ModelConfigHash('tag', P, n_d, n_a, n_z, N_j, true);
check(c1 && ~c2, 'is_cached / ForceRecompute behaviour wrong');
end

function h = hash_of(path)
tok = regexp(path, '_([0-9a-f]{32})\.mat$', 'tokens', 'once');
if isempty(tok), error('IGW:TestFailure', 'test_get_model_config_hash: no 32-hex digest in %s', path); end
h = tok{1};
end

function cleanup_dir(here, tmp)
cd(here);
rmdir(tmp, 's');
end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_get_model_config_hash: %s', msg);
end
end
