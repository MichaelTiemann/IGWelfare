function Phases = Build_Phase_Registry(Requested_Codes)
%% BUILD_PHASE_REGISTRY.M
% Assembles a 1xN struct array Phases(1..N) from workspace variables or Cache_SS*.mat files.
% Supports N = 1 ({'SS0'}), N = 2 ({'SS0','SS1'}), N = 3 ({'SS0','SS1','SS2'}), or more.
%
% Missing phase results are LOGGED, not blocked: if StatDist_SS1 / StatDist_SS2 (...) are not in the base workspace,
% documented stand-in values are substituted (SS1: G_ece + 0.14, Q_reg x [0.990 ... 0.925], Emig_By_SkillTier x 0.55;
% SS2: G_ece + 0.03, tau_l - 0.025, w_reg x 1.035, Emig_By_SkillTier x 0.80) and the missing variable and every
% stand-in value used are written through IGW_Log (id IGW:PhaseStandIn: warning + igw_run.log line naming phase,
% variable and value). A missing phase always substitutes the stand-ins; there is no switch that turns it into an error.

if nargin < 1 || isempty(Requested_Codes)
    % Auto-detect available phases in base workspace
    Requested_Codes = {'SS0'};
    if evalin('base', 'exist(''StatDist_SS1'',''var'') || exist(''StatDist_GE_Endo'',''var'')')
        Requested_Codes{end+1} = 'SS1';
    end
    for k = 2:9
        if evalin('base', sprintf('exist(''StatDist_SS%d'',''var'')', k))
            Requested_Codes{end+1} = sprintf('SS%d', k); %#ok<AGROW>
        end
    end
    % Default to {'SS0', 'SS1'} if user is running standard 2-panel comparison
    if numel(Requested_Codes) == 1
        Requested_Codes = {'SS0', 'SS1'};
    end
end
if ischar(Requested_Codes) || isstring(Requested_Codes)
    Requested_Codes = cellstr(Requested_Codes);
end

N_phases    = numel(Requested_Codes);
Panel_Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
Regions     = evalin_def('Regions', {'Rural', 'Small', 'Large', 'Auckland'});

% 1. Resolve Baseline (SS0) Anchor first
[Dist0, Pol0, V0, jDist0, P0, Diag0] = Resolve_SS0_From_Workspace();

Phases = struct('Code', {}, 'Label', {}, 'Dist', {}, 'Pol', {}, ...
    'V', {}, 'jDist', {}, 'Params', {}, 'Diag', {}, 'Intensity', {});

for p = 1:N_phases
    code = upper(strtrim(Requested_Codes{p}));
    let  = Panel_Chars(min(p, length(Panel_Chars)));

    if strcmp(code, 'SS0')
        Phases(p).Code      = 'SS0';
        Phases(p).Label     = sprintf('%c. Status Quo Baseline (SS0)', let);
        Phases(p).Dist      = Dist0;
        Phases(p).Pol       = Pol0;
        Phases(p).V         = V0;
        Phases(p).jDist     = jDist0;
        Phases(p).Params    = P0;
        Phases(p).Diag      = Diag0;
        Phases(p).Intensity = 0.0;

    elseif strcmp(code, 'SS1')
        [Dist1, Pol1, V1, jDist1, P1, Diag1] = Resolve_SS1_From_Workspace(Dist0, Pol0, V0, jDist0, P0, Diag0, Regions);
        Phases(p).Code      = 'SS1';
        Phases(p).Label     = sprintf('%c. High-Opportunity Reform + Montessori Mentoring (SS1)', let);
        Phases(p).Dist      = Dist1;
        Phases(p).Pol       = Pol1;
        Phases(p).V         = V1;
        Phases(p).jDist     = jDist1;
        Phases(p).Params    = P1;
        Phases(p).Diag      = Diag1;
        Phases(p).Intensity = 1.0;

    else
        % Generic Phase SSk (SS2, SS3, ...): check workspace or Cache_NZ_Intergen/Cache_<code >.mat
        [DistK, PolK, VK, jDistK, PK, DiagK, intensity_k, label_k] = ...
            Resolve_SSk_From_Workspace(code, let, Phases(max(1, p-1)), Regions);
        Phases(p).Code      = code;
        Phases(p).Label     = label_k;
        Phases(p).Dist      = DistK;
        Phases(p).Pol       = PolK;
        Phases(p).V         = VK;
        Phases(p).jDist     = jDistK;
        Phases(p).Params    = PK;
        Phases(p).Diag      = DiagK;
        Phases(p).Intensity = intensity_k;
    end
end
end

%% --- INTERNAL RESOLVERS ---
function [Dist0, Pol0, V0, jDist0, P0, Diag0] = Resolve_SS0_From_Workspace()
if evalin('base', 'exist(''StatDist_SS0'',''var'')')
    Dist0  = evalin('base', 'StatDist_SS0');
    Pol0   = evalin_def('Policy_SS0', evalin_def('Policy', struct()));
    V0     = evalin_def('V_SS0',      evalin_def('V', struct()));
    jDist0 = evalin_def('jDist_SS0',  evalin_def('jequaloneDist', struct()));
    P0     = evalin_def('Params_SS0', evalin_def('Params', struct()));
    Diag0  = evalin_def('IG_Diag_SS0',evalin_def('IG_Diagnostics', struct()));
elseif evalin('base', 'exist(''StatDist_Base'',''var'')')
    Dist0  = evalin('base', 'StatDist_Base');
    Pol0   = evalin('base', 'Policy_Base');
    V0     = evalin_def('V_Base', struct());
    jDist0 = evalin_def('jequalone_Base', struct());
    P0     = evalin('base', 'Params_Base');
    Diag0  = evalin_def('IG_Diag_Base', struct());
elseif evalin('base', 'exist(''StationaryDist'',''var'')')
    Dist0  = evalin('base', 'StationaryDist');
    Pol0   = evalin('base', 'Policy');
    V0     = evalin_def('V', struct());
    jDist0 = evalin_def('jequaloneDist', struct());
    P0     = evalin('base', 'Params');
    Diag0  = evalin_def('IG_Diagnostics', struct());
else
    error('Build_Phase_Registry: No baseline StationaryDist found in workspace.');
end
end

function [Dist1, Pol1, V1, jDist1, P1, Diag1] = Resolve_SS1_From_Workspace(Dist0, Pol0, V0, jDist0, P0, Diag0, Regions)
if evalin('base', 'exist(''StatDist_SS1'',''var'')')
    Dist1  = evalin('base', 'StatDist_SS1');
    Pol1   = evalin_def('Policy_SS1', evalin_def('Policy_GE_Exo', Pol0));
    V1     = evalin_def('V_SS1',      evalin_def('V_GE_Exo', V0));
    jDist1 = evalin_def('jDist_SS1',  jDist0);
    P1     = evalin_def('Params_SS1', evalin_def('Params_Reform', P0));
    Diag1  = evalin_def('IG_Diag_SS1',Diag0);
elseif evalin('base', 'exist(''StatDist_GE_Endo'',''var'')')
    Dist1  = evalin('base', 'StatDist_GE_Endo');
    Pol1   = evalin_def('Policy_GE_Endo', evalin_def('Policy_GE_Exo', Pol0));
    V1     = evalin_def('V_GE_Endo',      evalin_def('V_GE_Exo', V0));
    jDist1 = evalin_def('jequalone_Endo', jDist0);
    P1     = evalin_def('Params_GE',      evalin_def('Params_Reform', P0));
    Diag1  = evalin_def('IG_Diag_Reform', Diag0);
else
    % Parametric fallback from SS0 -- every stand-in value is logged
    IGW_Log('IGW:PhaseStandIn', 'Build_Phase_Registry phase SS1: workspace variable StatDist_SS1 (or StatDist_GE_Endo) is missing; substituting stand-in values, this phase is NOT a solved steady state');
    Dist1 = Dist0; Pol1 = Pol0; V1 = V0; jDist1 = jDist0; P1 = P0;
    G0 = getfield_def(P0, 'G_ece', 0.05);
    P1.G_ece = G0 + 0.14;
    IGW_Log('IGW:PhaseStandIn', 'Build_Phase_Registry phase SS1: stand-in G_ece = %.4f (SS0 G_ece %.4f%s + 0.14)', P1.G_ece, G0, absent_note(P0, 'G_ece', '0.05 assumed'));
    Q_mult   = struct('Rural', 0.990, 'Small', 0.975, 'Urban', 0.960, 'Large', 0.950, 'Auckland', 0.925);
    for r_i = 1:length(Regions)
        reg = Regions{r_i}; hk = ['HH_', reg];
        if isfield(P0, 'Q_reg') && isfield(P0.Q_reg, hk) && isfield(Q_mult, reg)
            P1.Q_reg.(hk) = P0.Q_reg.(hk) * Q_mult.(reg);
            IGW_Log('IGW:PhaseStandIn', 'Build_Phase_Registry phase SS1: stand-in Q_reg.%s = SS0 x %.3f = %.4f', hk, Q_mult.(reg), P1.Q_reg.(hk));
        end
    end
    Diag1 = Diag0;
    if isfield(Diag0, 'Emig_By_SkillTier')
        Diag1.Emig_By_SkillTier = Diag0.Emig_By_SkillTier * 0.55;
        IGW_Log('IGW:PhaseStandIn', 'Build_Phase_Registry phase SS1: stand-in Emig_By_SkillTier = SS0 x 0.55');
    else
        Diag1.Emig_By_SkillTier = [0.02, 0.02, 0.05, 0.06, 0.07, 0.11, 0.12];
        IGW_Log('IGW:PhaseStandIn', 'Build_Phase_Registry phase SS1: stand-in Emig_By_SkillTier = typed [0.02 0.02 0.05 0.06 0.07 0.11 0.12] (no SS0 value)');
    end
end
end

function [DistK, PolK, VK, jDistK, PK, DiagK, intensity_k, label_k] = Resolve_SSk_From_Workspace(code, let, PrevPhase, Regions)
if evalin('base', sprintf('exist(''StatDist_%s'',''var'')', code))
    DistK  = evalin('base', sprintf('StatDist_%s', code));
    PolK   = evalin_def(sprintf('Policy_%s', code), PrevPhase.Pol);
    VK     = evalin_def(sprintf('V_%s', code),      PrevPhase.V);
    jDistK = evalin_def(sprintf('jDist_%s', code),  PrevPhase.jDist);
    PK     = evalin_def(sprintf('Params_%s', code), PrevPhase.Params);
    DiagK  = evalin_def(sprintf('IG_Diag_%s', code),PrevPhase.Diag);
else
    % Parametric preview for SS2 (2050 Debt-Sinking & Dividend Harvest) if not yet solved in VFI
    % -- every stand-in value is logged
    IGW_Log('IGW:PhaseStandIn', 'Build_Phase_Registry phase %s: workspace variable StatDist_%s is missing; substituting stand-in values, this phase is NOT a solved steady state', code, code);
    DistK = PrevPhase.Dist; PolK = PrevPhase.Pol; VK = PrevPhase.V; jDistK = PrevPhase.jDist;
    PK    = PrevPhase.Params;
    G0 = getfield_def(PK, 'G_ece', 0.19);
    t0 = getfield_def(PK, 'tau_l', 0.22);
    PK.G_ece = G0 + 0.03;
    PK.tau_l = max(0.10, t0 - 0.025); % 2050 Debt-Sinking tax relief
    IGW_Log('IGW:PhaseStandIn', 'Build_Phase_Registry phase %s: stand-in G_ece = %.4f (previous phase G_ece %.4f%s + 0.03)', code, PK.G_ece, G0, absent_note(PrevPhase.Params, 'G_ece', '0.19 assumed'));
    IGW_Log('IGW:PhaseStandIn', 'Build_Phase_Registry phase %s: stand-in tau_l = %.4f (previous phase tau_l %.4f%s - 0.025, floor 0.10)', code, PK.tau_l, t0, absent_note(PrevPhase.Params, 'tau_l', '0.22 assumed'));
    for r_i = 1:length(Regions)
        reg = Regions{r_i}; hk = ['HH_', reg];
        if isfield(PK, 'w_reg') && isfield(PK.w_reg, hk)
            PK.w_reg.(hk) = PK.w_reg.(hk) * 1.035; % Public infrastructure yield dividend
            IGW_Log('IGW:PhaseStandIn', 'Build_Phase_Registry phase %s: stand-in w_reg.%s = previous phase x 1.035 = %.4f', code, hk, PK.w_reg.(hk));
        end
    end
    DiagK = PrevPhase.Diag;
    if isfield(DiagK, 'Emig_By_SkillTier')
        DiagK.Emig_By_SkillTier = DiagK.Emig_By_SkillTier * 0.80;
        IGW_Log('IGW:PhaseStandIn', 'Build_Phase_Registry phase %s: stand-in Emig_By_SkillTier = previous phase x 0.80', code);
    end
end
intensity_k = getfield_def(PK, 'Reform_Intensity', PrevPhase.Intensity + 0.25);
label_k     = getfield_def(PK, 'Phase_Label', sprintf('%c. Multiphase Dividend & Harvest (%s)', let, code));
end

function val = evalin_def(varname, default_val)
if evalin('base', sprintf('exist(''%s'',''var'')', varname))
    val = evalin('base', varname);
else
    val = default_val;
end
end

function val = getfield_def(S, fname, default_val)
if isstruct(S) && isfield(S, fname), val = S.(fname); else, val = default_val; end
end

function note = absent_note(S, fname, msg)
% ' [<msg>]' when S has no field fname (the typed default was used), else ''.
if isstruct(S) && isfield(S, fname), note = ''; else, note = [' [absent: ', msg, ']']; end
end
