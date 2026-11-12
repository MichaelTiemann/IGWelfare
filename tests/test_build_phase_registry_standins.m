function test_build_phase_registry_standins()
%% TEST_BUILD_PHASE_REGISTRY_STANDINS
% Build_Phase_Registry must not block a run for a missing phase and must not substitute stand-in values silently.
% Default: the documented stand-in values are used and each one is logged (IGW_Log: warning + igw_run.log line naming
% phase, variable and value, id IGW:PhaseStandIn).
% Solved phases in the workspace must pass through unchanged and unlogged.
% Runs in a scratch directory and plants variables in the base workspace; if any of those names already exist it
% prints a SKIP line and returns without touching them. Throws on failure, silent on success. No toolboxes, no GPU; MATLAB and GNU Octave.
addpath(fileparts(fileparts(mfilename('fullpath'))));

base_vars = {'StatDist_SS0', 'Policy_SS0', 'V_SS0', 'jDist_SS0', 'Params_SS0', 'IG_Diag_SS0', ...
    'StatDist_SS1', 'Params_SS1', 'StatDist_SS2'};
% The test plants and then clears these names in the base workspace: never do that to a live session
clash = intersect(base_vars, evalin('base', 'who'));
if ~isempty(clash)
    fprintf('SKIP test_build_phase_registry_standins: base workspace already holds %s; not clearing a live session.\n', strjoin(clash, ', '));
    return
end
tmp  = tempname();
mkdir(tmp);
here = pwd;
cleanup = onCleanup(@() cleanup_all(here, tmp, base_vars)); %#ok<NASGU>
cd(tmp);

P0 = struct('G_ece', 0.045, 'tau_l', 0.22);
P0.Q_reg = struct('HH_Rural', 1.05, 'HH_Small', 1.40, 'HH_Large', 2.05, 'HH_Auckland', 3.10);
P0.w_reg = struct('HH_Rural', 0.85, 'HH_Small', 0.93, 'HH_Large', 1.05, 'HH_Auckland', 1.18);
assignin('base', 'StatDist_SS0', 'dist0');
assignin('base', 'Policy_SS0',   'pol0');
assignin('base', 'V_SS0',        'v0');
assignin('base', 'jDist_SS0',    'jd0');
assignin('base', 'Params_SS0',   P0);
assignin('base', 'IG_Diag_SS0',  struct('Emig_By_SkillTier', [0.10 0.20 0.30]));

% 1. Default, nothing solved beyond SS0: no error; stand-in values used and logged
lastwarn('');
evalc('Ph = Build_Phase_Registry({''SS0'', ''SS1'', ''SS2''});');
[~, wid] = lastwarn();
check(strcmp(wid, 'IGW:PhaseStandIn'), 'default: expected a logged warning IGW:PhaseStandIn');
check(abs(Ph(2).Params.G_ece - (0.045 + 0.14)) < 1e-12, 'SS1 G_ece stand-in value changed');
check(abs(Ph(2).Params.Q_reg.HH_Auckland - 3.10 * 0.925) < 1e-12, 'SS1 Q_reg stand-in value changed');
check(all(abs(Ph(2).Diag.Emig_By_SkillTier - [0.10 0.20 0.30] * 0.55) < 1e-12), 'SS1 Emig stand-in value changed');
check(abs(Ph(3).Params.G_ece - (0.045 + 0.14 + 0.03)) < 1e-12, 'SS2 G_ece stand-in value changed');
check(abs(Ph(3).Params.tau_l - (0.22 - 0.025)) < 1e-12, 'SS2 tau_l stand-in value changed');
check(abs(Ph(3).Params.w_reg.HH_Rural - 0.85 * 1.035) < 1e-12, 'SS2 w_reg stand-in value changed');
L = read_lines('igw_run.log');
check(all(cellfun(@(l) ~isempty(strfind(l, ' IGW:PhaseStandIn ')), L)), 'a log line lacks the IGW:PhaseStandIn id');
check(has_line(L, {'phase SS1', 'StatDist_SS1', 'missing'}), 'log lacks the missing-variable line for SS1');
check(has_line(L, {'phase SS1', 'G_ece = 0.1850'}), 'log lacks the SS1 G_ece value');
check(has_line(L, {'phase SS1', 'Q_reg.HH_Auckland', '2.8675'}), 'log lacks the SS1 Q_reg value');
check(has_line(L, {'phase SS1', 'Emig_By_SkillTier'}), 'log lacks the SS1 Emig stand-in');
check(has_line(L, {'phase SS2', 'StatDist_SS2', 'missing'}), 'log lacks the missing-variable line for SS2');
check(has_line(L, {'phase SS2', 'G_ece = 0.2150'}), 'log lacks the SS2 G_ece value');
check(has_line(L, {'phase SS2', 'tau_l = 0.1950'}), 'log lacks the SS2 tau_l value');
check(has_line(L, {'phase SS2', 'w_reg.HH_Rural'}), 'log lacks the SS2 w_reg value');
n_logged = numel(L);

% 2. Solved phases pass through with no stand-in and nothing new logged
assignin('base', 'StatDist_SS1', 'dist1');
assignin('base', 'Params_SS1',   P0);
assignin('base', 'StatDist_SS2', 'dist2');
lastwarn('');
Ph = Build_Phase_Registry({'SS0', 'SS1', 'SS2'});
[~, wid] = lastwarn();
check(numel(Ph) == 3 && strcmp(Ph(2).Dist, 'dist1') && strcmp(Ph(3).Dist, 'dist2'), 'solved phases not passed through');
check(~strcmp(wid, 'IGW:PhaseStandIn'), 'warning raised although every phase was solved');
check(numel(read_lines('igw_run.log')) == n_logged, 'log grew although every phase was solved');
evalin('base', 'clear StatDist_SS1 Params_SS1 StatDist_SS2');
end

function L = read_lines(f)
L = strsplit(strtrim(fileread(f)), char(10));
end

function tf = has_line(L, needles)
tf = false;
for i = 1:numel(L)
    if all(cellfun(@(n) ~isempty(strfind(L{i}, n)), needles)), tf = true; return; end
end
end

function clear_base(names)
for k = 1:numel(names)
    evalin('base', sprintf('clear %s', names{k}));
end
end

function cleanup_all(here, tmp, names)
cd(here);
rmdir(tmp, 's');
clear_base(names);
end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_build_phase_registry_standins: %s', msg);
end
end
