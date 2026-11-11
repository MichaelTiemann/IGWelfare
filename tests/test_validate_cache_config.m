function test_validate_cache_config()
%% TEST_VALIDATE_CACHE_CONFIG
% Validate_CacheConfig must accept a checkpoint only when it stores a Cache_CfgHash equal to the current one; a missing
% or different hash (or an unreadable file) must warn IGW:StaleCache naming the file and return false.
% Get_ModelConfigHash itself is NOT exercised here (see tests/test_get_model_config_hash.m); the hash is a plain string.
% Throws on failure, silent on success. No toolboxes, no GPU; runs under MATLAB and GNU Octave.
addpath(fileparts(fileparts(mfilename('fullpath'))));

tmp = tempname();
mkdir(tmp);
cleanup = onCleanup(@() rmdir(tmp, 's')); %#ok<NASGU>

x = [1 2 3]; %#ok<NASGU>
Cache_CfgHash = 'A1B2C3D4'; %#ok<NASGU>
f_ok = fullfile(tmp, 'Cache_ok.mat');
save(f_ok, 'x', 'Cache_CfgHash');
f_nohash = fullfile(tmp, 'Cache_nohash.mat');
save(f_nohash, 'x');
f_bad = fullfile(tmp, 'Cache_corrupt.mat');
fid = fopen(f_bad, 'w'); fwrite(fid, 'this is not a mat file'); fclose(fid);

% 1. Matching hash: loads, no warning
lastwarn('');
out = evalc('ok = Validate_CacheConfig(f_ok, ''A1B2C3D4'');'); %#ok<NASGU>
[~, wid] = lastwarn();
check(isequal(ok, true), 'matching hash was rejected');
check(~strcmp(wid, 'IGW:StaleCache'), 'warning raised for a matching hash');

% 2. Different hash: rejected with IGW:StaleCache naming the file
lastwarn('');
out = evalc('ok = Validate_CacheConfig(f_ok, ''FFFFFFFF'');'); %#ok<NASGU>
[wmsg, wid] = lastwarn();
check(~ok, 'mismatched hash was accepted');
check(strcmp(wid, 'IGW:StaleCache'), 'mismatched hash: expected warning IGW:StaleCache');
check(~isempty(strfind(wmsg, f_ok)), 'mismatch warning does not name the file');

% 3. No stored hash (checkpoint from before hashing): rejected
lastwarn('');
out = evalc('ok = Validate_CacheConfig(f_nohash, ''A1B2C3D4'');'); %#ok<NASGU>
[wmsg, wid] = lastwarn();
check(~ok, 'checkpoint without Cache_CfgHash was accepted');
check(strcmp(wid, 'IGW:StaleCache') && ~isempty(strfind(wmsg, f_nohash)), 'missing hash: expected IGW:StaleCache naming the file');

% 3b. No current hash (Get_ModelConfigHash without MD5): never matches, even a checkpoint stored with an empty hash
lastwarn('');
out = evalc('ok = Validate_CacheConfig(f_ok, '''');'); %#ok<NASGU>
[wmsg, wid] = lastwarn();
check(~ok, 'empty current hash was accepted');
check(strcmp(wid, 'IGW:StaleCache') && ~isempty(strfind(wmsg, f_ok)), 'empty current hash: expected IGW:StaleCache naming the file');

% 4. Unreadable file: rejected, not an error
lastwarn('');
out = evalc('ok = Validate_CacheConfig(f_bad, ''A1B2C3D4'');'); %#ok<NASGU>
[wmsg, wid] = lastwarn();
check(~ok, 'unreadable checkpoint was accepted');
check(strcmp(wid, 'IGW:StaleCache') && ~isempty(strfind(wmsg, f_bad)), 'unreadable file: expected IGW:StaleCache naming the file');
end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_validate_cache_config: %s', msg);
end
end
