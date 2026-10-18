%% WELFARE & SPATIAL DECOMPOSITION SCRIPT: 4-REGION 5D NZ MODEL (VFI TOOLKIT)
% File: WelfareDecomposition_4Region.m
% Regions (N_reg = 4): {'Rural', 'Small', 'Large', 'Auckland'}
% Operates directly on the 5D Two-Experience-Asset state space [a, h, theta_c, z, j].

N_reg = length(Regions);

%% 1. STORE BASELINE SOLUTION (SCENARIO 0)
V_Base          = V;
Policy_Base     = Policy;
StatDist_Base   = StationaryDist;
jequalone_Base  = jequaloneDist;
Params_Base     = Params;
IG_Diag_Base    = IG_Diagnostics;

%% 2. DEFINE POLICY REFORM: BARNARDOS FIRST-2000-DAYS + PIKETTY/GUVENEN TAX REFORM
Params_Reform              = Params_Base;
Params_Reform.G_ece_stage1 = 0.110; % Scaled First-2000-Days wraparound investment
Params_Reform.YouthGrant   = 0.065; % Expanded universal youth endowment E
Params_Reform.tau_a        = 0.015; % 1.5% annual wealth tax
Params_Reform.tau_b        = 0.250; % 25% estate tax on the $1.6T property transfer

Params_Reform.Transfer_Geo.HH_Rural    = 0.038;
Params_Reform.Transfer_Geo.HH_Small    = 0.031;
Params_Reform.Transfer_Geo.HH_Large    = 0.025;
Params_Reform.Transfer_Geo.HH_Auckland = 0.028;

Params_GE   = Params_Reform;
Params_GE.r = Params_Base.r - 0.012;

w_mult_GE = [1.032, 1.038, 1.048, 1.055];
Q_mult_GE = [0.990, 0.975, 0.950, 0.925];

for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];
    firm_tp = ['Firm_', reg];
    Params_GE.w_reg.(hh_type) = Params_Base.w_reg.(hh_type) * w_mult_GE(r_idx);
    Params_GE.w_reg.(firm_tp) = Params_GE.w_reg.(hh_type);
    Params_GE.Q_reg.(hh_type) = Params_Base.Q_reg.(hh_type) * Q_mult_GE(r_idx);
end

if ~exist('Force_Recompute_Cache', 'var'); Force_Recompute_Cache = false; end
[cache_wd, is_cached_wd] = Get_ModelConfigHash('WelfareDecomp_5D', Params_GE, n_d, n_a, n_z, N_j, Force_Recompute_Cache);

if is_cached_wd
    fprintf('    [CACHE HIT] Loading 5D Welfare Decomposition from %s\n', cache_wd);
    load(cache_wd, 'V_PE', 'Policy_PE', 'StatDist_PE', ...
        'V_GE_Exo', 'Policy_GE_Exo', 'StatDist_GE_Exo', ...
        'V_GE_Endo', 'StatDist_GE_Endo', 'jequalone_Endo', 'IG_Diag_Reform');
else
    %% 3. STAGE A: SHORT-RUN PARTIAL EQUILIBRIUM (PE) & EXOGENOUS NEWBORN SKILLS
    [V_PE, Policy_PE] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_Reform, DiscountFactorParamNames, vfoptions);

    StatDist_PE = StationaryDist_MixHorz_PType(jequalone_Base, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_PE, n_d, n_a, n_z, N_j, Names_i, ...
        pi_z, Params_Reform, simoptions);

    %% 4. STAGE B: LONG-RUN GE WITH EXOGENOUS INTERGENERATIONAL SKILLS
    [V_GE_Exo, Policy_GE_Exo] = ValueFnIter_MixHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
        d_grid, a_grid, z_grid, pi_z, ReturnFn, Params_GE, DiscountFactorParamNames, vfoptions);

    StatDist_GE_Exo = StationaryDist_MixHorz_PType(jequalone_Base, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_GE_Exo, n_d, n_a, n_z, N_j, Names_i, ...
        pi_z, Params_GE, simoptions);

    %% 5. STAGE C: LONG-RUN GE WITH ENDOGENOUS INTERGENERATIONAL & 4-REGION SPATIAL MATRIX
    jequalone_Endo = jequalone_Base;
    for ig_iter = 1:15
        StatDist_GE_Endo = StationaryDist_MixHorz_PType(jequalone_Endo, AgeWeightsParamNames, ...
            PTypeDistParamNames, Policy_GE_Exo, n_d, n_a, n_z, N_j, Names_i, ...
            pi_z, Params_GE, simoptions);

        [jequalone_Endo_new, IG_Diag_Reform] = Build_IntergenTransitionMatrix( ...
            StatDist_GE_Endo, Policy_GE_Exo, V_GE_Exo, n_d, n_a, n_z, ...
            d_grid, a_grid, z_grid, pi_z, Params_GE, Regions);
        diff_ig = max(abs(jequalone_Endo_new.HH_Auckland(:) - jequalone_Endo.HH_Auckland(:)));
        jequalone_Endo = jequalone_Endo_new;
        if diff_ig < 1e-5; break; end
    end
    V_GE_Endo = V_GE_Exo;

    save(cache_wd, 'V_PE', 'Policy_PE', 'StatDist_PE', ...
        'V_GE_Exo', 'Policy_GE_Exo', 'StatDist_GE_Exo', ...
        'V_GE_Endo', 'StatDist_GE_Endo', 'jequalone_Endo', 'IG_Diag_Reform', '-v7.3');
end

%% 6. COMPUTE CONSUMPTION EQUIVALENCE (CE %) DECOMPOSITIONS ACROSS 4 REGIONS (5D INDEXING)
eta_c   = 2.0;
calc_CE = @(W_base, W_ref) 100 * ((W_base ./ W_ref).^(1 / (eta_c - 1)) - 1);

% --- TABLE 1: DARUICH / LEE & SESHADRI DECOMPOSITION ---
CE_ShortRun_PE  = zeros(1, N_reg);
CE_LongRun_Exo  = zeros(1, N_reg);
CE_LongRun_Endo = zeros(1, N_reg);

for r_idx = 1:N_reg
    reg     = Regions{r_idx};
    hh_type = ['HH_', reg];

    V0_j1  = gather(V_Base.(hh_type)(:, :, :, :, 1));
    Vpe_j1 = gather(V_PE.(hh_type)(:, :, :, :, 1));
    Vge_j1 = gather(V_GE_Endo.(hh_type)(:, :, :, :, 1));
    j0_cpu = gather(jequalone_Base.(hh_type));
    je_cpu = gather(jequalone_Endo.(hh_type));

    W_Base    = sum(j0_cpu(:) .* V0_j1(:));
    W_PE      = sum(j0_cpu(:) .* Vpe_j1(:));
    W_GE_Exo  = sum(j0_cpu(:) .* Vge_j1(:));
    W_GE_Endo = sum(je_cpu(:) .* Vge_j1(:));

    CE_ShortRun_PE(r_idx)  = calc_CE(W_Base, W_PE);
    CE_LongRun_Exo(r_idx)  = calc_CE(W_Base, W_GE_Exo);
    CE_LongRun_Endo(r_idx) = calc_CE(W_Base, W_GE_Endo);
end

% --- TABLE 2: LABROUSSE & PERDEREAU 4-REGION x INCOME QUINTILE MATRIX ---
CE_Reg_Quintile = zeros(N_reg, 5);
for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    V0_all  = gather(V_Base.(hh_type));
    Vge_all = gather(V_GE_Endo.(hh_type));
    D0_all  = gather(StatDist_Base.(hh_type));
    Dge_all = gather(StatDist_GE_Endo.(hh_type));
    for q = 1:5
        V0_q  = V0_all(:, :, :, q, :);
        Vge_q = Vge_all(:, :, :, q, :);
        D0_q  = D0_all(:, :, :, q, :);
        Dge_q = Dge_all(:, :, :, q, :);

        W0_q  = sum(D0_q(:)  .* V0_q(:))  / max(1e-12, sum(D0_q(:)));
        Wge_q = sum(Dge_q(:) .* Vge_q(:)) / max(1e-12, sum(Dge_q(:)));
        CE_Reg_Quintile(r_idx, q) = calc_CE(W0_q, Wge_q);
    end
end

% --- TABLE 3: KIYOTAKI, MICHAELIDES & NIKOLOV TENURE / AGE GROUPS ---
CE_Kiyotaki = zeros(3, N_reg);
n_a1        = n_a.HH_Rural(1);
cut_owner   = round(0.35 * n_a1);

for r_idx = 1:N_reg
    hh_type = ['HH_', Regions{r_idx}];
    V0_all  = gather(V_Base.(hh_type));
    Vge_all = gather(V_GE_Endo.(hh_type));
    D0_all  = gather(StatDist_Base.(hh_type));
    Dge_all = gather(StatDist_GE_Endo.(hh_type));

    % 1. Young Renters (j < Jr, assets below deposit threshold)
    V0_yr  = V0_all(1:cut_owner, :, :, :, 1:Params.Jr-1);
    Vge_yr = Vge_all(1:cut_owner, :, :, :, 1:Params.Jr-1);
    D0_yr  = D0_all(1:cut_owner, :, :, :, 1:Params.Jr-1);
    Dge_yr = Dge_all(1:cut_owner, :, :, :, 1:Params.Jr-1);
    CE_Kiyotaki(1, r_idx) = calc_CE(sum(D0_yr(:).*V0_yr(:))/sum(D0_yr(:)), ...
        sum(Dge_yr(:).*Vge_yr(:))/sum(Dge_yr(:)));

    % 2. Young Leveraged Homeowners (j < Jr, assets above deposit threshold)
    V0_yo  = V0_all(cut_owner+1:end, :, :, :, 1:Params.Jr-1);
    Vge_yo = Vge_all(cut_owner+1:end, :, :, :, 1:Params.Jr-1);
    D0_yo  = D0_all(cut_owner+1:end, :, :, :, 1:Params.Jr-1);
    Dge_yo = Dge_all(cut_owner+1:end, :, :, :, 1:Params.Jr-1);
    CE_Kiyotaki(2, r_idx) = calc_CE(sum(D0_yo(:).*V0_yo(:))/sum(D0_yo(:)), ...
        sum(Dge_yo(:).*Vge_yo(:))/sum(Dge_yo(:)));

    % 3. Old Retirees & Property Landlords (j >= Jr)
    V0_old  = V0_all(:, :, :, :, Params.Jr:end);
    Vge_old = Vge_all(:, :, :, :, Params.Jr:end);
    D0_old  = D0_all(:, :, :, :, Params.Jr:end);
    Dge_old = Dge_all(:, :, :, :, Params.Jr:end);
    CE_Kiyotaki(3, r_idx) = calc_CE(sum(D0_old(:).*V0_old(:))/sum(D0_old(:)), ...
        sum(Dge_old(:).*Vge_old(:))/sum(Dge_old(:)));
end

%% 7. DISPLAY FORMATTED 4-REGION DECOMPOSITION TABLES
fprintf('\n=========================================================================================\n');
fprintf('TABLE 1: 4-REGION INTERGENERATIONAL WELFARE DECOMPOSITION (CE %%) - DARUICH / LEE-SESHADRI\n');
fprintf('=========================================================================================\n');
T1 = array2table([CE_ShortRun_PE; CE_LongRun_Exo; CE_LongRun_Endo; ...
    100*(CE_LongRun_Endo - CE_LongRun_Exo)./max(1e-6, CE_LongRun_Endo)], ...
    'VariableNames', Regions, ...
    'RowNames', {'1. Short-Run PE (Exogenous Skills)', ...
    '2. Long-Run GE (Exogenous Skills)', ...
    '3. Long-Run GE (Endogenous Intergen Matrix)', ...
    '   -> Share of Gain from Intergen Skill Shift (%)'});
disp(T1);

fprintf('\n=========================================================================================\n');
fprintf('TABLE 2: 4-REGION SPATIAL x INCOME QUINTILE WELFARE (CE %%) - LABROUSSE & PERDEREAU\n');
fprintf('=========================================================================================\n');
Q_Ratios = CE_Reg_Quintile(:, 1) ./ max(1e-6, CE_Reg_Quintile(:, 5));
T2 = array2table([CE_Reg_Quintile, mean(CE_Reg_Quintile, 2), Q_Ratios], ...
    'VariableNames', {'Q1_Lowest', 'Q2', 'Q3', 'Q4', 'Q5_Highest', 'All_Mean', 'Ratio_Q1_to_Q5'}, ...
    'RowNames', Regions);
disp(T2);

fprintf('\n=========================================================================================\n');
fprintf('TABLE 3: 4-REGION HOUSING TENURE & GENERATIONAL CLEAVAGE (CE %%) - KIYOTAKI ET AL.\n');
fprintf('=========================================================================================\n');
T3 = array2table(CE_Kiyotaki, 'VariableNames', Regions, ...
    'RowNames', {'Young Renters (Lens 1/2)', 'Young Leveraged Owners (Lens 2)', 'Old Retirees/Landlords (Lens 3)'});
disp(T3);