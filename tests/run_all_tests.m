function nFailed = run_all_tests(forceExit)
%RUN_ALL_TESTS Discover and run every tests/test_*.m, MATLAB or Octave, no toolboxes.
%   run_all_tests            prints one line per test (PASS / FAIL / SKIP) and a summary
%                            "N passed, M failed" (plus "(K skipped)" when K > 0).
%   n = run_all_tests        also returns the number of failures.
%   run_all_tests('exit')    exit(1) on any failure even when interactive.
%
%   Non-interactive runs (Octave --eval, MATLAB -batch) exit with status 1 on any
%   failure automatically, so CI can use the process exit code.
%
%   A test is a function test_<name>() that throws on failure and prints nothing on
%   success. A test that cannot run in the current interpreter may call
%   error('tests:skip', reason); it is reported as SKIP and is not a failure.
%   Run from any folder:  cd tests; run_all_tests   or   run('tests/run_all_tests.m').
if nargin < 1, forceExit = ''; end

here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fileparts(here));

listing = dir(fullfile(here, 'test_*.m'));
names = cell(1, numel(listing));
for k = 1:numel(listing)
    names{k} = listing(k).name(1:end-2);
end
names = sort(names);

nPass = 0; nFail = 0; nSkip = 0;
for k = 1:numel(names)
    try
        feval(names{k});
        fprintf('PASS %s\n', names{k});
        nPass = nPass + 1;
    catch err
        if strcmp(err.identifier, 'tests:skip')
            fprintf('SKIP %s: %s\n', names{k}, strtrim(err.message));
            nSkip = nSkip + 1;
        else
            msg = strrep(strtrim(err.message), char(10), [char(10) '     ']);
            fprintf('FAIL %s: %s\n', names{k}, msg);
            nFail = nFail + 1;
        end
    end
end

if nSkip > 0
    fprintf('%d passed, %d failed (%d skipped)\n', nPass, nFail, nSkip);
else
    fprintf('%d passed, %d failed\n', nPass, nFail);
end

if nargout > 0, nFailed = nFail; end
if nFail > 0 && (strcmp(forceExit, 'exit') || is_noninteractive())
    exit(1);
end
end

function tf = is_noninteractive()
tf = false;
if exist('OCTAVE_VERSION', 'builtin') ~= 0
    a = argv();                       % Octave: started with --eval / a script file
    for i = 1:numel(a)
        if strncmp(a{i}, '--eval', 6), tf = true; return; end
    end
elseif exist('batchStartupOptionUsed', 'file') ~= 0
    tf = batchStartupOptionUsed();    % MATLAB R2019a+: true under -batch
end
end
