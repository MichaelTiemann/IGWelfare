function Params = Apply_Empirical_Data(Params, DataSpec)
%% TIER B PROVENANCE CONTRACT: EXTERNAL, STATUTORY & MACRO-SPATIAL DATA
% File: src/config/Apply_Empirical_Data.m
% Maps Layer 1 DataSpec (Load_Empirical_Profile), Layer 2 RolloutSpec, and Layer 3
% ContingencySpec into flat/PType-keyed fields on Params.
%
% STRICT INVARIANT: Every struct-valued field placed onto Params MUST be keyed
% exclusively by VFI Toolkit Permanent Types ('HH_*' / 'Firm_*'). Non-PType
% structs (DataSpec, RolloutSpec, ContingencySpec) are NEVER stored inside Params.

if nargin < 1 || isempty(Params)
    Params = Configure_Grid_And_Prefs(struct());
end

% Strip any legacy non-PType structs if passed in by an older workspace
legacy_non_ptype = {'DataSpec', 'RolloutSpec', 'ContingencySpec'};
for k = 1:numel(legacy_non_ptype)
    fn = legacy_non_ptype{k};
    if isfield(Params, fn)
        if strcmp(fn, 'DataSpec') && isstruct(Params.DataSpec) && isfield(Params.DataSpec, 'Profile_ID') ...
                && (~isfield(Params, 'Profile_ID') || isempty(Params.Profile_ID))
            Params.Profile_ID = Params.DataSpec.Profile_ID;
        end
        Params = rmfield(Params, fn);
    end
end

if nargin >= 2 && ~isempty(DataSpec)
    if ischar(DataSpec) || isstring(DataSpec)
        DataSpec = Load_Empirical_Profile(DataSpec);
    end
elseif isfield(Params, 'Profile_Name') && ~isempty(Params.Profile_Name)
    DataSpec = Load_Empirical_Profile(Params.Profile_Name);
elseif isfield(Params, 'Profile_ID') && ~isempty(Params.Profile_ID)
    DataSpec = Load_Empirical_Profile(Params.Profile_ID);
elseif isfield(Params, 'Calibration_Anchor') && ~isempty(Params.Calibration_Anchor)
    DataSpec = Load_Empirical_Profile(Params.Calibration_Anchor);
else
    DataSpec = Load_Empirical_Profile('NZ_Dunedin1972');
end

Params.Profile_ID         = DataSpec.Profile_ID;
Params.Calibration_Anchor = DataSpec.Legacy_Alias;
Params.DataSpec_Digest    = DataSpec.Digest;

dt       = Params.dt;
scale_dt = dt / 5;

%% 1. DEMOGRAPHIC SURVIVAL, FERTILITY & MIGRATION VECTORS (INTERPOLATED TO J)
sj_5yr  = DataSpec.Demography_5yr.sj(:)';
fj_5yr  = DataSpec.Demography_5yr.fj(:)';
mig_5yr = DataSpec.Demography_5yr.mig_rate_j(:)';
Params.sj_5yr_ref = sj_5yr;

if dt == 5 && numel(sj_5yr) == Params.J
    Params.sj         = sj_5yr;
    Params.fj         = fj_5yr;
    Params.mig_rate_j = mig_5yr;
else
    age_5yr_mid = DataSpec.Demography_5yr.Age_Mid(:)';
    age_dt_mid  = linspace(20 + dt/2, 100 - dt/2, Params.J);

    sj_interp         = interp1(age_5yr_mid, sj_5yr, age_dt_mid, 'pchip');
    Params.sj         = max(0, min(0.999, sj_interp)) .^ scale_dt;
    Params.sj(end)    = 0.0;

    Params.fj         = max(0, interp1(age_5yr_mid, fj_5yr, age_dt_mid, 'linear', 0)) * scale_dt;
    Params.mig_rate_j = interp1(age_5yr_mid, mig_5yr, age_dt_mid, 'linear', 0) * scale_dt;
end

%% 2. STATUTORY TAX, PENSION, RETURN & INSTITUTIONAL BASELINES
if ~isfield(Params, 'r'),      Params.r      = (1 + 0.20)^scale_dt - 1; end
if ~isfield(Params, 'tau_l'),  Params.tau_l  = 0.22;  end % Statutory working-age PAYE tax rate
if ~isfield(Params, 'tau_c'),  Params.tau_c  = 0.15;  end % Statutory GST consumption tax rate
if ~isfield(Params, 'tau_k'),  Params.tau_k  = 0.20;  end % Baseline capital/profit tax rate
if ~isfield(Params, 'tau_a'),  Params.tau_a  = 0.005; end % Baseline asset/holding levy
if ~isfield(Params, 'tau_b'),  Params.tau_b  = 0.15;  end % Baseline estate/bequest tax rate
if ~isfield(Params, 'p_super'),Params.p_super= 0.18;  end % NZ Superannuation replacement rate
if ~isfield(Params, 's_sub'),  Params.s_sub  = 0.100; end % Private childcare co-payment subsidy rate

if ~isfield(Params, 'super_age_base'),        Params.super_age_base        = DataSpec.Institutions.Super_Age_Base;   end
if ~isfield(Params, 'super_age_SS1'),         Params.super_age_SS1         = DataSpec.Institutions.Super_Age_SS1;    end
if ~isfield(Params, 'super_age_SS2'),         Params.super_age_SS2         = DataSpec.Institutions.Super_Age_SS2;    end
if ~isfield(Params, 'dep_ratio_2026_anchor'), Params.dep_ratio_2026_anchor = DataSpec.Institutions.Dep_Ratio_Anchor; end
Params.Estate_Exemption   = DataSpec.Institutions.Estate_Exemption;
Params.Target_NetMig_Rate = DataSpec.Institutions.Target_NetMig_Rate;
Params.w_External         = DataSpec.Institutions.w_External;
Params.Q_External         = DataSpec.Institutions.Q_External;

%% 3. SPATIAL TOPOLOGY, MONETARY REPORTING ANCHORS & PTYPE BASELINE GRIDS
N_reg_ds                    = DataSpec.N_reg;
Reg_Names_ds                = DataSpec.Regions;
RT_ds                       = DataSpec.Reg_Table;
Params.N_reg                = N_reg_ds;
Params.Regions              = Reg_Names_ds;
Params.Reg_Names_4          = Reg_Names_ds;
Params.Reg_Names_5          = DataSpec.Reg_Names_Plus_Nat;
Params.External_Dest_Label  = DataSpec.External_Dest_Label;
Params.Primate_Region_ID    = DataSpec.Primate_Region_ID;
Params.Primate_Region_Idx   = DataSpec.Primate_Region_Idx;
Params.Primate_HH_Type      = ['HH_', DataSpec.Primate_Region_ID];
Params.Representative_Urban_ID  = DataSpec.Representative_Urban_ID;
Params.Representative_Urban_Idx = DataSpec.Representative_Urban_Idx;

if ~isfield(Params, 'Pop_Weights_4'),  Params.Pop_Weights_4  = DataSpec.Pop_Shares;  end
if ~isfield(Params, 'Firm_Weights_4'), Params.Firm_Weights_4 = DataSpec.Firm_Shares; end
Params.Pop_Weights_5 = [Params.Pop_Weights_4, 1.000];
ech_idx_col          = DataSpec.Echelon_Idx(:);
Params.Pop_Weights_3 = accumarray(ech_idx_col, Params.Pop_Weights_4(:), [DataSpec.N_Echelons, 1])';

Params.Currency_ISO           = DataSpec.Monetary.Currency_ISO;
Params.Currency_Symbol        = DataSpec.Monetary.Currency_Symbol;
Params.Currency_Unit_Billions = DataSpec.Monetary.Currency_Unit_Billions;
Params.Currency_Base_Year     = DataSpec.Monetary.Base_Year;
Params.Currency_Base_Scale    = DataSpec.Monetary.Currency_Base_Scale;
Params.CE_Monetary_Scale_Nat  = DataSpec.Monetary.CE_Monetary_Scale_Nat;
Params.GDP_Base_Billions      = DataSpec.Monetary.GDP_Base_Billions;
Params.Curr_Per_CE_Nat        = Params.CE_Monetary_Scale_Nat;
Params.GDP_2026_BCurr         = Params.GDP_Base_Billions;
Params.NZD_Per_CE_Nat         = Params.CE_Monetary_Scale_Nat;
Params.GDP_2026_BNZD          = Params.GDP_Base_Billions;

% Flat empirical vectors for firm grids, SMM targets, & transition paths (avoids nested non-PType structs!)
Params.z_firm_low_vec          = RT_ds.z_firm_low(:)';
Params.z_firm_high_vec         = RT_ds.z_firm_high(:)';
Params.kahui_lag_yrs           = RT_ds.kahui_lag_yrs(:)';
Params.K_whanau_base_vec       = RT_ds.K_whanau_base(:)';
Params.base_struggle_vec       = RT_ds.struggle_pct(:)';
Params.reg_skill_drift         = RT_ds.skill_drift(:)';
Params.daruich_ig_mult         = RT_ds.daruich_mult(:)';
Params.u_target_4x5            = DataSpec.u_target_mig;
Params.TargetMoments_Val       = DataSpec.TargetMoments.Target_Val(:);
Params.TargetMoments_Weight    = DataSpec.TargetMoments.Weight(:);
Params.Trans_Pi_dom_SS1        = DataSpec.Transition.Pi_dom_SS1;
Params.Trans_Pi_dom_SS2        = DataSpec.Transition.Pi_dom_SS2;
Params.Trans_Intl_Inflow_Share = DataSpec.Transition.Intl_Inflow_Share(:)';
Params.Trans_Q_init            = DataSpec.Transition.Q_init_trans(:)';
Params.Trans_Emig_0            = DataSpec.Transition.Emig_0(:)';
Params.Trans_Emig_SS1          = DataSpec.Transition.Emig_SS1(:)';
Params.Trans_Emig_SS2          = DataSpec.Transition.Emig_SS2(:)';

% PType-keyed regional baseline structs ('HH_*' and 'Firm_*' ONLY)
for r_i = 1:N_reg_ds
    hh_k   = ['HH_',   Reg_Names_ds{r_i}];
    firm_k = ['Firm_', Reg_Names_ds{r_i}];
    if ~isfield(Params, 'K_whanau_base') || ~isfield(Params.K_whanau_base, hh_k)
        Params.K_whanau_base.(hh_k) = RT_ds.K_whanau_base(r_i);
    end
    if ~isfield(Params, 'Q_reg_base') || ~isfield(Params.Q_reg_base, hh_k)
        Params.Q_reg_base.(hh_k) = RT_ds.Q_base(r_i);
    end
    if ~isfield(Params, 'w_reg_base') || ~isfield(Params.w_reg_base, hh_k)
        Params.w_reg_base.(hh_k)   = RT_ds.w_base(r_i);
        Params.w_reg_base.(firm_k) = RT_ds.w_base(r_i);
    end
    if ~isfield(Params, 'Q_reg') || ~isfield(Params.Q_reg, hh_k)
        Params.Q_reg.(hh_k) = RT_ds.Q_base(r_i);
    end
    if ~isfield(Params, 'w_reg') || ~isfield(Params.w_reg, hh_k)
        Params.w_reg.(hh_k)   = RT_ds.w_base(r_i);
        Params.w_reg.(firm_k) = RT_ds.w_base(r_i);
    end
    if ~isfield(Params, 'delta_H') || ~isfield(Params.delta_H, hh_k)
        Params.delta_H.(hh_k) = RT_ds.delta_H(r_i);
    end
    if ~isfield(Params, 'G_reg') || ~isfield(Params.G_reg, hh_k)
        Params.G_reg.(hh_k) = RT_ds.G_trend(r_i);
    end
    if ~isfield(Params, 'ebar_energy') || ~isfield(Params.ebar_energy, hh_k)
        Params.ebar_energy.(hh_k) = RT_ds.ebar_energy(r_i);
    end
    if ~isfield(Params, 'Transfer_Geo') || ~isfield(Params.Transfer_Geo, hh_k)
        Params.Transfer_Geo.(hh_k) = RT_ds.Transfer_Geo(r_i);
    end
end
if ~isfield(Params, 'K_whanau')
    Params.K_whanau = Params.K_whanau_base;
end

%% 4. REGIME SCHEDULE ANCHORS, DUOPOLY/LOCAL KAI VECTORS, & ROLLOUT/CONTINGENCY METADATA
Params.G_ece1_sched     = DataSpec.Regime_Schedules.G_ece1_sched(:)';
Params.G_ece2_sched     = DataSpec.Regime_Schedules.G_ece2_sched(:)';
Params.YouthGrant_sched = DataSpec.Regime_Schedules.YouthGrant_sched(:)';
if ~isfield(Params, 'YouthGrant'), Params.YouthGrant = Params.YouthGrant_sched(1); end

Params.w_mult_SS0        = ones(1, N_reg_ds);
Params.w_mult_SS1        = RT_ds.w_mult_SS1(:)';
Params.w_mult_SS2        = RT_ds.w_mult_SS2(:)';
Params.Q_mult_SS0        = ones(1, N_reg_ds);
Params.Q_mult_SS1        = RT_ds.Q_mult_SS1(:)';
Params.Q_mult_SS2        = RT_ds.Q_mult_SS2(:)';

Params.M_olig_SS0        = RT_ds.M_olig_SS0(:)';
Params.M_olig_SS1        = RT_ds.M_olig_SS1(:)';
Params.M_olig_SS2        = RT_ds.M_olig_SS2(:)';
Params.alpha_food_nd_vec = RT_ds.alpha_food_nd(:)';
Params.mu_monop_SS0      = RT_ds.mu_monop_SS0(:)';
Params.mu_monop_SS1      = RT_ds.mu_monop_SS1(:)';
Params.mu_monop_SS2      = RT_ds.mu_monop_SS2(:)';
Params.phi_local_SS0     = RT_ds.phi_local_SS0(:)';
Params.phi_local_SS1     = RT_ds.phi_local_SS1(:)';
Params.phi_local_SS2     = RT_ds.phi_local_SS2(:)';
Params.mu_z_SS0          = RT_ds.mu_z_SS0(:)';
Params.mu_z_SS2          = RT_ds.mu_z_SS2(:)';
Params.sigma_z_vec       = RT_ds.sigma_z(:)';

% Layer 3 Contingency & Layer 2 Rollout flat fields
if ~isfield(Params, 'Contingency_Policy') || isempty(Params.Contingency_Policy)
    Params.Contingency_Policy = 'fixed_calendar_2050';
end
ContingencySpec = Load_Contingency_Policy(DataSpec, Params.Contingency_Policy);
Params.Contingency_Policy_ID         = ContingencySpec.Policy_ID;
Params.Contingency_Announcement_Mode = ContingencySpec.Announcement_Mode;
Params.Contingency_Digest            = ContingencySpec.Digest;

if ~isfield(Params, 'Rollout_Mode') || isempty(Params.Rollout_Mode)
    Params.Rollout_Mode = ContingencySpec.Default_Rollout_Mode;
end
RolloutSpec = Load_Rollout_Schedule(DataSpec, Params.Rollout_Mode);
Params.Rollout_Digest = RolloutSpec.Digest;

if ~isfield(Params, 'tau_friction_0'),         Params.tau_friction_0         = RolloutSpec.tau_friction_0;     end
if ~isfield(Params, 'tau_friction_floor'),     Params.tau_friction_floor     = RolloutSpec.tau_friction_floor; end
if ~isfield(Params, 'gamma_learning'),         Params.gamma_learning         = RolloutSpec.tau_friction_0 * 0 + RolloutSpec.gamma_learning; end
if ~isfield(Params, 'phi_adj_bottleneck'),     Params.phi_adj_bottleneck     = RolloutSpec.phi_adj_bottleneck; end
if ~isfield(Params, 'delta_adopt_ece'),        Params.delta_adopt_ece        = RolloutSpec.delta_adopt_ece;    end
if ~isfield(Params, 'lambda_adopt_ece'),       Params.lambda_adopt_ece       = RolloutSpec.lambda_adopt_ece;   end
if ~isfield(Params, 'ebar_elec_relief_share'), Params.ebar_elec_relief_share = RT_ds.ebar_elec_relief(:)';     end
if ~isfield(Params, 'T_ramp_LVT_yrs'),         Params.T_ramp_LVT_yrs         = RolloutSpec.T_ramp_LVT_yrs;     end
if ~isfield(Params, 'T_ramp_CGT_Est_yrs'),     Params.T_ramp_CGT_Est_yrs     = RolloutSpec.T_ramp_CGT_Est_yrs; end
if ~isfield(Params, 'T_ramp_CorpCut_yrs'),     Params.T_ramp_CorpCut_yrs     = RolloutSpec.T_ramp_CorpCut_yrs; end

if ~isfield(Params, 'sh_ygr_base0_vec'), Params.sh_ygr_base0_vec = RT_ds.sh_ygr_base0(:)'; end
w4_col = Params.Pop_Weights_4(:);
b4_row = Params.sh_ygr_base0_vec(:)';

Params.sh_ygr_base0_nat      = b4_row * w4_col;
Params.sh_ygr_base0_5        = [b4_row, Params.sh_ygr_base0_nat];
Params.sh_ygr_base0_3echelon = RolloutSpec.sh_ygr_base0_echelon;

Params.Waves_13           = RolloutSpec.Rel_Years(:);
Params.Kahui_ECE_13x3     = RolloutSpec.ECE_Echelon;
Params.Kahui_Mnt_13x3     = RolloutSpec.Mnt_Echelon;
Params.Kahui_YGr_New_13x3 = RolloutSpec.YGr_New_Echelon;
Params.Kahui_YGr_Tot_13x3 = RolloutSpec.YGr_Tot_Echelon;
Params.Kahui_Elc_13x3     = RolloutSpec.Elc_Echelon;

YGr_New_Reg_mat           = RolloutSpec.YGr_New_RegNat(:, 1:N_reg_ds);
YGr_Tot_Reg_mat           = b4_row + (1.0 - b4_row) .* YGr_New_Reg_mat;
Params.Kahui_ECE_13x5     = RolloutSpec.ECE_RegNat;
Params.Kahui_Mnt_13x5     = RolloutSpec.Mnt_RegNat;
Params.Kahui_YGr_New_13x5 = RolloutSpec.YGr_New_RegNat;
Params.Kahui_YGr_Tot_13x5 = [YGr_Tot_Reg_mat, YGr_Tot_Reg_mat * w4_col];
Params.Kahui_Elc_13x5     = RolloutSpec.Elc_RegNat;

Params.eta_delivery_SS1   = RolloutSpec.eta_delivery_SS1;
Params.eta_delivery_SS2   = RolloutSpec.eta_delivery_SS2;

end
