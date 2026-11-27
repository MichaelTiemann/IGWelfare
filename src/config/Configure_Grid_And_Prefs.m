function Params = Configure_Grid_And_Prefs(Params, dt, n_z_pts)
%% TIER A PROVENANCE CONTRACT: DISCRETIZATION GRIDS & DEEP INVARIANT PREFERENCES
% File: src/config/Configure_Grid_And_Prefs.m
% Populates time-step discretization, lifecycle age-window indices, and deep
% preference/technology constants invariant to statutory data or policy regimes.
% Canonical default time step: dt = 3 years (J = 27 periods, Ages 20-99).

if nargin < 1 || isempty(Params)
    Params = struct();
end

if nargin < 2 || isempty(dt)
    if isfield(Params, 'dt') && ~isempty(Params.dt)
        dt = Params.dt;
    else
        dt = 3;
    end
end
if nargin < 3 || isempty(n_z_pts)
    if isfield(Params, 'n_z_pts') && ~isempty(Params.n_z_pts)
        n_z_pts = Params.n_z_pts;
    else
        n_z_pts = 7;
    end
end

Params.dt      = dt;
scale_dt       = dt / 5;  % Ratio relative to 5-year calibration benchmark
Params.n_z_pts = n_z_pts; % N-point Rouwenhorst regional productivity grid

%% 1. LIFE-CYCLE HORIZON (AGES 20-99) & BASELINE RETIREMENT INDEX (AGE 65)
Params.J  = round(80 / dt);           % 27 (dt=3), 16 (dt=5), 40 (dt=2), 80 (dt=1)
if isfield(Params, 'super_age') && ~isempty(Params.super_age)
    Params.Jr = 1 + (Params.super_age - 20.0) / dt;
else
    Params.Jr = 1 + round(45 / dt);   % 16 (dt=3), 10 (dt=5), 23 (dt=2)
end
Params.agej = 1:Params.J;

%% 2. CHILDHOOD & LIFECYCLE HUMAN CAPITAL WINDOWS
Params.j_s1_start     = 1 + round(10 / dt);               % Age 30: j=4 (dt=3), j=3 (dt=5)
Params.n_stage1_steps = max(1, round(5 / dt));            % 2 (dt=3), 1 (dt=5), 3 (dt=2)
Params.j_s1_end       = Params.j_s1_start + Params.n_stage1_steps - 1;

Params.j_s2_start     = Params.j_s1_end + 1;              % Age 35: j=6 (dt=3), j=4 (dt=5)
Params.n_stage2_steps = max(1, round(5 / dt));            % 2 (dt=3), 1 (dt=5), 3 (dt=2)
Params.j_s2_end       = Params.j_s2_start + Params.n_stage2_steps - 1;

Params.j_child_launch = min(Params.J, Params.j_s2_end + 1); % j=8 (dt=3), j=5 (dt=5)

%% 3. DEEP PREFERENCES, TECHNOLOGY & TRANSITION HORIZON CONSTANTS
Params.beta_hh   = 0.980^dt;
Params.beta_firm = 0.9815^dt;

if ~isfield(Params, 'eta_c'),    Params.eta_c    = 2.0;  end % CRRA risk aversion coefficient
if ~isfield(Params, 'phi_nd'),   Params.phi_nd   = 0.80; end % Non-durable Cobb-Douglas expenditure share
if ~isfield(Params, 'c_floor'),  Params.c_floor  = 0.04; end % Minimum subsistence consumption floor
if ~isfield(Params, 'alpha_k'),  Params.alpha_k  = 0.33; end % Firm physical capital share
if ~isfield(Params, 'rho_z'),    Params.rho_z    = 0.85; end % Regional log-productivity AR(1) persistence
if ~isfield(Params, 'delta_hc'), Params.delta_hc = 1 - (1 - 0.087)^scale_dt; end
if ~isfield(Params, 'delta_k'),  Params.delta_k  = 1 - (1 - 0.06)^dt;        end

Params.T_trans_years = 60;
Params.T_trans       = round(Params.T_trans_years / dt);  % 20 (dt=3), 12 (dt=5), 30 (dt=2)
Params.zeta_cohort   = 1 - (1 - 0.085)^scale_dt;

%% 4. GE CLOSURE & PRICE-SOLVER SELECTION (Solve_Spatial_GE_Loop.m)
% Canonical GE & Transition Path Anderson Acceleration Toggles:
%   - Params.ge_method  = 'anderson' | 'broyden' | 'damped' | 'none'
%   - Params.ge_closure = 'fixed_price' (default fast multipliers) | 'neoclassical' | 'keynesian'
% Note: Params.ge_method overrides default Params.ge_closure, not the other way around

if ~isfield(Params, 'ge_method') || isempty(Params.ge_method)
    if isfield(Params, 'ge_closure') && any(strcmpi(Params.ge_closure, {'neoclassical', 'keynesian'}))
        Params.ge_method = 'anderson';
    else
        Params.ge_method = 'none';
    end
end
if any(strcmpi(Params.ge_method, {'anderson','broyden','damped'}))
    if ~isfield(Params, 'ge_closure')
        warning("selecting 'keynesian' for `Params.ge_closure`");
        Params.ge_closure = 'keynesian';
    elseif ~any(strcmpi(Params.ge_closure, {'fixed_price','neoclassical','keynesian'}))
        error("unrecognized `Params.ge_closure` setting");
    end
    if strcmp(Params.ge_closure, 'fixed_price')
        warning("When Params.ge_closure is 'fixed_price' the GE solver will not run");
    end
elseif strcmp(Params.ge_method, 'none')
    if ~isfield(Params, 'ge_closure')
        Params.ge_closure = 'fixed_price';
    elseif ~strcmp(Params.ge_closure, 'fixed_price')
        warning("overriding `Params.ge_closure` to 'fixed_price' since `Params.ge_method` set to 'none'");
        Params.ge_closure = 'fixed_price';
    end
else
    error("unrecognized `Params.ge_method` setting");
end

end
