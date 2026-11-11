function IGW_Log(id, fmt, varargin)
%% RUN-LOG WRITER FOR IGW:* SIGNALS (WARNING + igw_run.log LINE)
% File: IGW_Log.m
% Usage: IGW_Log('IGW:NoConvergence', '%s: %d iterations, residual %.3g', name, n, resid)
% Nothing in the suite is blocked by a failed check: the run carries on, and every failure is recorded.
% Each call (a) appends ONE line  <ISO8601 local time> <id> <message>  to igw_run.log in the current directory
% (created if absent; newlines in the message are folded to ' | ') and (b) issues warning(id, ...) with the same text.
% If the log cannot be written (read-only folder, igw_run.log is a directory, ...) the call falls back to the
% warning alone and never errors. The line is written first, so it is kept even if warning('error', id) is set.
% Ids in use: IGW:PhaseStandIn, IGW:StaleCache, IGW:NoConvergence, IGW:TypedAnchor, IGW:NoMD5.

msg = sprintf(fmt, varargin{:});

try
    fid = fopen(fullfile(pwd, 'igw_run.log'), 'a');
    if fid > 0
        line = strrep(strrep(msg, char(13), ''), char(10), ' | ');
        fprintf(fid, '%s %s %s\n', datestr(now, 'yyyy-mm-ddTHH:MM:SS'), id, line);
        fclose(fid);
    end
catch
    % logging must never break a run: fall through to the warning alone
end

warning(id, '%s', msg);

end
