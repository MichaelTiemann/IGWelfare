function Params = Configure_TimeGrid_Params(Params, dt)
%% CONFIGURE_TIMEGRID_PARAMS
% Non-destructively integrates variable period length dt (in years) into Params.
% If dt == 5, reproduces the exact 16-period (Ages 20-99) baseline arrays.
% If dt == 3 (J=27) or dt == 2 (J=40), smoothly interpolates demographic vectors
% and compounds annualized rates over dt years.

if nargin < 2 || isempty(dt)
    if isfield(Params, 'dt') && ~isempty(Params.dt)
        dt = Params.dt;
    else
        dt = 5;
    end
end
Params.dt  = dt;
scale_dt   = dt / 5; % Ratio relative to the 5-year calibration benchmark

%% 1. LIFE-CYCLE HORIZON (AGES 20-99) & RETIREMENT BOUNDARY (AGE 65)
Params.J    = round(80 / dt);           % 16 (dt=5), 27 (dt=3), 40 (dt=2)
Params.Jr   = 1 + round(45 / dt);       % 10 (dt=5), 16 (dt=3), 23 (dt=2)
Params.agej = 1:Params.J;

%% 2. CHILDHOOD & LIFECYCLE HUMAN CAPITAL WINDOWS
% Anchor 5-year benchmarks: j=2 (Ages 25-29 conception), j=3 (Ages 30-34 Stage 1),
% j=4 (Ages 35-39 Stage 2), j=5 (Ages 40-44 Launch at child age 20)
Params.j_s1_start     = 1 + round(10 / dt);               % Age 30: j=3 (dt=5), j=4 (dt=3), j=6 (dt=2)
Params.n_stage1_steps = max(1, round(5 / dt));            % 1 (dt=5), 2 (dt=3), 3 (dt=2)
Params.j_s1_end       = Params.j_s1_start + Params.n_stage1_steps - 1;

Params.j_s2_start     = Params.j_s1_end + 1;              % Age 35: j=4 (dt=5), j=6 (dt=3), j=9 (dt=2)
Params.n_stage2_steps = max(1, round(5 / dt));            % 1 (dt=5), 2 (dt=3), 3 (dt=2)
Params.j_s2_end       = Params.j_s2_start + Params.n_stage2_steps - 1;

Params.j_child_launch = min(Params.J, Params.j_s2_end + 1); % j=5 (dt=5), j=8 (dt=3), j=12 (dt=2)

%% 3. TREASURY OLG SURVIVAL, FERTILITY, & MIGRATION VECTORS (INTERPOLATED TO J)
sj_5yr  = [0.995, 0.994, 0.993, 0.991, 0.988, 0.983, 0.975, 0.962, ...
    0.942, 0.910, 0.860, 0.780, 0.660, 0.500, 0.300, 0.000];
fj_5yr  = [0.15, 0.65, 0.65, 0.20, zeros(1, 12)];
mig_5yr = [0.018, -0.012, -0.005, 0.015, 0.010, 0.006, 0.003, zeros(1, 9)];

if dt == 5
    Params.sj         = sj_5yr;
    Params.fj         = fj_5yr;
    Params.mig_rate_j = mig_5yr;
else
    age_5yr_mid = linspace(22.5, 97.5, 16);
    age_dt_mid  = linspace(20 + dt/2, 100 - dt/2, Params.J);

    % Compound survival probability over dt/5 and scale flow rates by dt/5
    sj_interp         = interp1(age_5yr_mid, sj_5yr, age_dt_mid, 'pchip');
    Params.sj         = max(0, min(0.999, sj_interp)) .^ scale_dt;
    Params.sj(end)    = 0.0;
    Params.fj         = max(0, interp1(age_5yr_mid, fj_5yr, age_dt_mid, 'linear', 0)) * scale_dt;
    Params.mig_rate_j = interp1(age_5yr_mid, mig_5yr, age_dt_mid, 'linear', 0) * scale_dt;
end

%% 4. COMPOUNDED DISCOUNT, RETURN, DEPRECIATION, & TRANSITION RATES
if ~isfield(Params, 'beta_hh');   Params.beta_hh   = 0.96^dt; else; Params.beta_hh   = (Params.beta_hh^(1/5))^dt; end
if ~isfield(Params, 'beta_firm'); Params.beta_firm = 0.95^dt; else; Params.beta_firm = (Params.beta_firm^(1/5))^dt; end
if ~isfield(Params, 'r');         Params.r         = (1 + 0.20)^scale_dt - 1; end
if ~isfield(Params, 'delta_hc');  Params.delta_hc  = 1 - (1 - 0.087)^scale_dt; end
if ~isfield(Params, 'delta_k');   Params.delta_k   = 1 - (1 - 0.06)^dt; end

% 60-Year Transition Path Horizon
Params.T_trans_years = 60;
Params.T_trans       = round(Params.T_trans_years / dt); % 12 (dt=5), 20 (dt=3), 30 (dt=2)
Params.zeta_cohort   = 1 - (1 - 0.085)^scale_dt;


end
