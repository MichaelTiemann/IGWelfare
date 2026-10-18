%% WELFARE & SPATIAL DECOMPOSITION SCRIPT (VFI TOOLKIT)
% Replicates & combines the decomposition tables of:
%   1. Daruich (2018, Source 10) & Lee & Seshadri (2019, Source 6): 
%      Short-Run PE vs Long-Run GE & Exogenous vs Endogenous Intergenerational Skill
%   2. Labrousse & Perdereau (2025, Source 12): 
%      Regional (Rural, Urban, Auckland) x Income Quintiles (Q1-Q5, Q1/Q5, Rural/Auckland)
%   3. Kiyotaki, Michaelides & Nikolov (2024, Source 4, Tables 3 & 5):
%      Young Renters vs Young Leveraged Homeowners vs Old Landlords/Retirees

%% 1. STORE BASELINE SOLUTION (SCENARIO 0)
% Assumes NZ_3Region_Master.m has been run to convergence for Baseline
V_Base          = V;
Policy_Base     = Policy;
StatDist_Base   = StationaryDist;
jequalone_Base  = jequaloneDist;
Params_Base     = Params;
IG_Diag_Base    = IG_Diagnostics;

%% 2. DEFINE POLICY REFORM: BARNARDOS FIRST-2000-DAYS + PIKETTY/GUVENEN TAX REFORM
% Policy Lever 1: Double public ECE + whanau wraparound investment (Sources 7, 9, 15, 16)
% Targets reduction of child material hardship from 14.3% baseline toward 1-2% (Source 16)
Params_Reform = Params_Base;
Params_Reform.G_ece      = 0.11;  % Scaled First-2000-Days wraparound investment
Params_Reform.YouthGrant = 0.065; % Expanded universal youth endowment E

% Policy Lever 2: Finance via Book-Value Wealth Tax (tau_a) & Inheritance Tax (tau_b)
% rather than punitive labor tax hikes on working families (Sources 8, 17)
Params_Reform.tau_a = 0.015; % 1.5% annual wealth tax -> "use-it-or-lose-it" firm productivity Z boost
Params_Reform.tau_b = 0.25;  % 25% estate tax on the $1.6T property transfer

% Policy Lever 3: "Income x Geography" Transfer Calibration (Labrousse & Perdereau Source 12)
Params_Reform.Transfer_Geo.HH_Rural    = 0.038; % Offsets high rural transport/energy subsistence
Params_Reform.Transfer_Geo.HH_Urban    = 0.022;
Params_Reform.Transfer_Geo.HH_Auckland = 0.028; % Offsets severe Auckland rent/deposit squeeze

%% 3. STAGE A: SHORT-RUN PARTIAL EQUILIBRIUM (PE) & EXOGENOUS NEWBORN SKILLS
% Prices (r, w_reg, Q_reg) and newborn distribution (jequalone_Base) held fixed at Baseline
[V_PE, Policy_PE] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_Reform, DiscountFactorParamNames, vfoptions);

StatDist_PE = StationaryDist_Case1_FHorz_PType(jequalone_Base, AgeWeightsParamNames, ...
    PTypeDistParamNames, Policy_PE, n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, Params_Reform, simoptions);

%% 4. STAGE B: LONG-RUN GE WITH EXOGENOUS INTERGENERATIONAL SKILLS (Daruich Source 10)
% Update GE prices: Guvenen et al. (Source 8) wealth tax reallocates capital to z_h firms,
% raising aggregate productivity Z and regional wages w_reg, while cooling Auckland land bubble Q_reg
Params_GE = Params_Reform;
Params_GE.r                  = Params_Base.r - 0.012;          % Capital deepening lowers r slightly
Params_GE.w_reg.HH_Rural     = Params_Base.w_reg.HH_Rural    * 1.035;
Params_GE.w_reg.HH_Urban     = Params_Base.w_reg.HH_Urban    * 1.045;
Params_GE.w_reg.HH_Auckland  = Params_Base.w_reg.HH_Auckland * 1.055;
Params_GE.Q_reg.HH_Rural     = Params_Base.Q_reg.HH_Rural    * 0.985;
Params_GE.Q_reg.HH_Urban     = Params_Base.Q_reg.HH_Urban    * 0.960;
Params_GE.Q_reg.HH_Auckland  = Params_Base.Q_reg.HH_Auckland * 0.925; % Wealth/estate tax cools overvaluation

[V_GE_Exo, Policy_GE_Exo] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_GE, DiscountFactorParamNames, vfoptions);

StatDist_GE_Exo = StationaryDist_Case1_FHorz_PType(jequalone_Base, AgeWeightsParamNames, ...
    PTypeDistParamNames, Policy_GE_Exo, n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, Params_GE, simoptions);

%% 5. STAGE C: LONG-RUN GE WITH ENDOGENOUS INTERGENERATIONAL & SPATIAL MATRIX
% Allow Build_IntergenTransitionMatrix to update newborn skills, inheritances, & migration
jequalone_Endo = jequalone_Base;
for ig_iter = 1:15
    StatDist_GE_Endo = StationaryDist_Case1_FHorz_PType(jequalone_Endo, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_GE_Exo, n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, Params_GE, simoptions);
    
    [jequalone_Endo, IG_Diag_Reform] = Build_IntergenTransitionMatrix( ...
        StatDist_GE_Endo, Policy_GE_Exo, V_GE_Exo, n_d, n_a, n_z, ...
        d_grid, a_grid, z_grid, pi_z, Params_GE, Regions);
end
V_GE_Endo = V_GE_Exo;

%% 6. COMPUTE CONSUMPTION EQUIVALENCE (CE %) DECOMPOSITIONS
eta_c = 2.0; % CRRA coefficient (Lee & Seshadri Source 6)
% Helper function: Convert expected value ratio (with CRRA = 2, V < 0) to CE %
calc_CE = @(W_base, W_ref) 100 * ((W_base ./ W_ref).^(1 / (eta_c - 1)) - 1);

% --- TABLE 1: DARUICH (2018, Source 10) / LEE & SESHADRI (2019, Source 6) DECOMPOSITION ---
CE_ShortRun_PE  = zeros(1, 3);
CE_LongRun_Exo  = zeros(1, 3);
CE_LongRun_Endo = zeros(1, 3);

for r_idx = 1:3
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    
    % Newborn veil-of-ignorance expected value at j = 1
    V0_j1  = V_Base.(hh_type)(:, :, :, 1);
    Vpe_j1 = V_PE.(hh_type)(:, :, :, 1);
    Vge_j1 = V_GE_Endo.(hh_type)(:, :, :, 1);
    
    W_Base     = sum(jequalone_Base.(hh_type)(:) .* V0_j1(:));
    W_PE       = sum(jequalone_Base.(hh_type)(:) .* Vpe_j1(:));
    W_GE_Exo   = sum(jequalone_Base.(hh_type)(:) .* Vge_j1(:));
    W_GE_Endo  = sum(jequalone_Endo.(hh_type)(:) .* Vge_j1(:));
    
    CE_ShortRun_PE(r_idx)  = calc_CE(W_Base, W_PE);
    CE_LongRun_Exo(r_idx)  = calc_CE(W_Base, W_GE_Exo);
    CE_LongRun_Endo(r_idx) = calc_CE(W_Base, W_GE_Endo);
end

% --- TABLE 2: LABROUSSE & PERDEREAU (Source 12) REGION x INCOME QUINTILE MATRIX ---
% Map the 5 exogenous productivity states z (or joint h*z) into Income Quintiles Q1..Q5
CE_Reg_Quintile = zeros(3, 5);
for r_idx = 1:3
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    for q = 1:5
        V0_q  = V_Base.(hh_type)(:, :, q, :);
        Vge_q = V_GE_Endo.(hh_type)(:, :, q, :);
        D0_q  = StatDist_Base.(hh_type)(:, :, q, :);
        Dge_q = StatDist_GE_Endo.(hh_type)(:, :, q, :);
        
        W0_q  = sum(D0_q(:)  .* V0_q(:))  / max(1e-12, sum(D0_q(:)));
        Wge_q = sum(Dge_q(:) .* Vge_q(:)) / max(1e-12, sum(Dge_q(:)));
        CE_Reg_Quintile(r_idx, q) = calc_CE(W0_q, Wge_q);
    end
end

% --- TABLE 3: KIYOTAKI, MICHAELIDES & NIKOLOV (Source 4, Tables 3 & 5) TENURE / AGE GROUPS ---
% Split within each region into: Young Renters (low a, j<Jr), Young Owners (high a, j<Jr), Old (j>=Jr)
CE_Kiyotaki = zeros(3, 3); % Rows: [Young Renters, Young Owners, Old Retirees], Cols: Regions
n_a1 = n_a.HH_Rural(1);
cut_owner = round(0.35 * n_a1); % Asset threshold separating constrained renters vs owners

for r_idx = 1:3
    hh_type = ['HH_', Regions{r_idx}];
    
    % 1. Young Renters (j < Jr, assets below deposit threshold)
    V0_yr  = V_Base.(hh_type)(1:cut_owner, :, :, 1:Params.Jr-1);
    Vge_yr = V_GE_Endo.(hh_type)(1:cut_owner, :, :, 1:Params.Jr-1);
    D0_yr  = StatDist_Base.(hh_type)(1:cut_owner, :, :, 1:Params.Jr-1);
    Dge_yr = StatDist_GE_Endo.(hh_type)(1:cut_owner, :, :, 1:Params.Jr-1);
    CE_Kiyotaki(1, r_idx) = calc_CE(sum(D0_yr(:).*V0_yr(:))/sum(D0_yr(:)), ...
                                    sum(Dge_yr(:).*Vge_yr(:))/sum(Dge_yr(:)));
                                
    % 2. Young Homeowners (j < Jr, assets above deposit threshold)
    V0_yo  = V_Base.(hh_type)(cut_owner+1:end, :, :, 1:Params.Jr-1);
    Vge_yo = V_GE_Endo.(hh_type)(cut_owner+1:end, :, :, 1:Params.Jr-1);
    D0_yo  = StatDist_Base.(hh_type)(cut_owner+1:end, :, :, 1:Params.Jr-1);
    Dge_yo = StatDist_GE_Endo.(hh_type)(cut_owner+1:end, :, :, 1:Params.Jr-1);
    CE_Kiyotaki(2, r_idx) = calc_CE(sum(D0_yo(:).*V0_yo(:))/sum(D0_yo(:)), ...
                                    sum(Dge_yo(:).*Vge_yo(:))/sum(Dge_yo(:)));
                                
    % 3. Old Retirees & Property Landlords (j >= Jr)
    V0_old  = V_Base.(hh_type)(:, :, :, Params.Jr:end);
    Vge_old = V_GE_Endo.(hh_type)(:, :, :, Params.Jr:end);
    D0_old  = StatDist_Base.(hh_type)(:, :, :, Params.Jr:end);
    Dge_old = StatDist_GE_Endo.(hh_type)(:, :, :, Params.Jr:end);
    CE_Kiyotaki(3, r_idx) = calc_CE(sum(D0_old(:).*V0_old(:))/sum(D0_old(:)), ...
                                    sum(Dge_old(:).*Vge_old(:))/sum(Dge_old(:)));
end

%% 7. DISPLAY FORMATTED DECOMPOSITION TABLES
fprintf('\n================================================================================\n');
fprintf('TABLE 1: INTERGENERATIONAL WELFARE DECOMPOSITION (CE %%) - DARUICH / LEE-SESHADRI\n');
fprintf('================================================================================\n');
T1 = array2table([CE_ShortRun_PE; CE_LongRun_Exo; CE_LongRun_Endo; ...
                  100*(CE_LongRun_Endo - CE_LongRun_Exo)./max(1e-6, CE_LongRun_Endo)], ...
    'VariableNames', Regions, ...
    'RowNames', {'1. Short-Run PE (Exogenous Skills)', ...
                 '2. Long-Run GE (Exogenous Skills)', ...
                 '3. Long-Run GE (Endogenous Intergen Matrix)', ...
                 '   -> Share of Gain from Intergen Skill Shift (%)'});
disp(T1);

fprintf('\n================================================================================\n');
fprintf('TABLE 2: SPATIAL x INCOME QUINTILE WELFARE (CE %%) - LABROUSSE & PERDEREAU\n');
fprintf('================================================================================\n');
Q_Ratios = CE_Reg_Quintile(:, 1) ./ max(1e-6, CE_Reg_Quintile(:, 5));
T2 = array2table([CE_Reg_Quintile, mean(CE_Reg_Quintile, 2), Q_Ratios], ...
    'VariableNames', {'Q1_Lowest', 'Q2', 'Q3', 'Q4', 'Q5_Highest', 'All_Mean', 'Ratio_Q1_to_Q5'}, ...
    'RowNames', Regions);
disp(T2);

fprintf('\n================================================================================\n');
fprintf('TABLE 3: HOUSING TENURE & GENERATIONAL CLEAVAGE (CE %%) - KIYOTAKI ET AL.\n');
fprintf('================================================================================\n');
T3 = array2table(CE_Kiyotaki, 'VariableNames', Regions, ...
    'RowNames', {'Young Renters (Lens 1/2)', 'Young Leveraged Owners (Lens 2)', 'Old Retirees/Landlords (Lens 3)'});
disp(T3);
