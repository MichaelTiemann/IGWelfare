function Params = Configure_TimeGrid_Params(Params, dt)
% CONFIGURE_TIMEGRID_PARAMS Parameterizes the OLG model period length dt (in years)
% Supports dt = 5 (J=16), dt = 3 (J=27), dt = 2 (J=40), or dt = 1 (J=80).

Params.dt = dt;

%% 1. LIFE-CYCLE HORIZON (AGES 20 TO 99) & RETIREMENT (AGE 65)
Params.age_entry = 20;
Params.age_ret   = 65;
Params.age_max   = 100;

Params.J  = round((Params.age_max - Params.age_entry) / dt);     % 16 (dt=5), 27 (dt=3), 40 (dt=2)
Params.Jr = 1 + round((Params.age_ret - Params.age_entry) / dt); % 10 (dt=5), 16 (dt=3), 23 (dt=2)

%% 2. CHILDHOOD SKILL STAGES (PARENT BIRTH AT AGE ~26-29 -> CHILD AGES 0-5 AND 6-17)
% Parent age index at childbirth (approx age 26-29):
j_birth        = 1 + round(6 / dt);              % j=2 or 3 (dt=5->3, dt=3->3, dt=2->4)
n_stage1       = max(1, round(6 / dt));          % Ages 0-5  (6 yrs): 1 pd (dt=5), 2 pds (dt=3), 3 pds (dt=2)
n_stage2       = max(1, round(12 / dt));         % Ages 6-17 (12 yrs): 1 pd (dt=5), 4 pds (dt=3), 6 pds (dt=2)

Params.j_child_s1_start = j_birth;
Params.j_child_s1_end   = j_birth + n_stage1 - 1;
Params.j_child_s2_start = j_birth + n_stage1;
Params.j_child_s2_end   = j_birth + n_stage1 + n_stage2 - 1;
Params.j_child_launch   = Params.j_child_s2_end + 1; % Parent age j when child completes Stage 2

% Sub-period CES self-productivity & investment step scaling when n_stage > 1
Params.n_stage1_steps = n_stage1;
Params.n_stage2_steps = n_stage2;

%% 3. COMPOUNDING OF ANNUALIZED RATES OVER dt YEARS
beta_hh_ann   = 0.960;
beta_firm_ann = 0.950;
r_ann_base    = (1 + 0.22)^(1/5) - 1; % ~4.06% annual real interest rate
delta_hc_ann  = 1 - (1 - 0.087)^(1/5); % ~1.80% annual Ben-Porath depreciation

Params.beta_hh   = beta_hh_ann^dt;
Params.beta_firm = beta_firm_ann^dt;
Params.r         = (1 + r_ann_base)^dt - 1;
Params.delta_hc  = 1 - (1 - delta_hc_ann)^dt;

% Regional annual trend growth factors G_k,ann (Hirano & Toda 2025)
% Annual rates: Rural = 1.007, Small = 1.011, Large = 1.018, Auckland = 1.025
Params.G_ann.HH_Rural    = 1.007;
Params.G_ann.HH_Small    = 1.011;
Params.G_ann.HH_Large    = 1.018;
Params.G_ann.HH_Auckland = 1.025;

%% 4. TRANSITION HORIZON (60 YEARS) & MIGRATION TURNOVER RATES
Params.T_trans_years     = 60;
Params.T_trans           = round(Params.T_trans_years / dt); % 12 (dt=5), 20 (dt=3), 30 (dt=2)
Params.zeta_inflow_rate  = 1 - (1 - 0.085)^(dt / 5);         % International migration inflow weight per dt
Params.dom_mig_step_rate = 1 - (1 - 0.120)^(dt / 5);         % Domestic youth sorting step weight per dt


end
