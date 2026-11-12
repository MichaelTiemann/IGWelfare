function test_igw_log()
%% TEST_IGW_LOG
% IGW_Log must (a) issue warning(id, ...) and (b) append one well-formed line "<ISO8601> <id> <message>" to igw_run.log in
% the current directory per call, and (c) never error when the log cannot be written.
% Runs in a scratch directory. Throws on failure, silent on success. No toolboxes, no GPU; MATLAB and GNU Octave.
addpath(fileparts(fileparts(mfilename('fullpath'))));

tmp  = tempname();
tmp2 = tempname();
mkdir(tmp);
mkdir(tmp2);
here = pwd;
cleanup = onCleanup(@() cleanup_dirs(here, {tmp, tmp2})); %#ok<NASGU>   % one cleanup: leave the scratch dirs first, then remove both
cd(tmp);

% 1. First call: warning issued with id and text, log created with one well-formed line
lastwarn('');
evalc('IGW_Log(''IGW:NoConvergence'', ''loop %s: %d iterations, residual %.3g'', ''demo'', 12, 0.000244);');
[wmsg, wid] = lastwarn();
check(strcmp(wid, 'IGW:NoConvergence'), 'warning id not issued');
check(strcmp(wmsg, 'loop demo: 12 iterations, residual 0.000244'), 'warning text wrong');
L = read_lines('igw_run.log');
check(numel(L) == 1, 'first call did not write exactly one line');
tok = regexp(L{1}, '^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}) (IGW:NoConvergence) (.*)$', 'tokens', 'once');
check(~isempty(tok), 'log line is not "<ISO8601> <id> <message>"');
check(strcmp(tok{3}, 'loop demo: 12 iterations, residual 0.000244'), 'log message differs from the warning');
first_line = L{1};

% 2. Second call appends a second line (and folds newlines)
evalc('IGW_Log(''IGW:StaleCache'', ''first line\nsecond line'');');
L = read_lines('igw_run.log');
check(numel(L) == 2, 'second call did not append a second line');
check(~isempty(regexp(L{2}, 'IGW:StaleCache first line \| second line$', 'once')), 'newline not folded / id missing in second line');
check(strcmp(L{1}, first_line), 'first line was overwritten');

% 3. Unwritable log (igw_run.log is a directory): no error, warning still issued
cd(here);
mkdir(fullfile(tmp2, 'igw_run.log'));
cd(tmp2);
lastwarn('');
ok = true;
try
    evalc('IGW_Log(''IGW:TypedAnchor'', ''still warns %d'', 7);');
catch
    ok = false;
end
[wmsg, wid] = lastwarn();
check(ok, 'IGW_Log errored when the log could not be written');
check(strcmp(wid, 'IGW:TypedAnchor') && strcmp(wmsg, 'still warns 7'), 'warning not issued when the log is unwritable');
end

function L = read_lines(f)
txt = fileread(f);
L = strsplit(strtrim(txt), char(10));
end

function cleanup_dirs(here, dirs)
cd(here);
for k = 1:numel(dirs)
    rmdir(dirs{k}, 's');
end
end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_igw_log: %s', msg);
end
end
