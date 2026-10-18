%% MULTI-STAGE CHILDHOOD COUNTERFACTUALS ACROSS 4 REGIONS (INTEGRATED WITH Params.dt)
% File: PolicyExperiment_LeeSeshadri_4Region.m
% Evaluates Lee & Seshadri (2019) / Cunha, Heckman & Schennach (2010) counterfactuals:
%   1. 'BM_Baseline'     : Status quo NZ policy
%   2. 'P0_Early_0to5'   : Stage-1 First 2000 Days wraparound ECE expansion (j in J_c1)
%   3. 'P1P2_Late_6to17' : Stage-2 School-Age remedial expansion (j in J_c2)
%   4. 'BN_FrontLoad'    : Budget-neutral reallocation from Stage 2 to Stage 1
%   5. 'P0_Plus_GrantE'  : Stage-1 ECE expansion + Youth Capital Grant E at j = 1
% Outputs Table12A (IGE), Table12B (Variance Explained), Table12C (Earnings & CE Welfare), and FigE8.

if ~exist('Params', 'var') || ~isfield(Params, 'dt')
    Params = Configure_TimeGrid_Params(Params, 5);
end

PolicyNames = {'BM_Baseline'; 'P0_Early_0to5'; 'P1P2_Late_6to17'; 'BN_FrontLoad'; 'P0_Plus_GrantE'};
N_pol       = length(PolicyNames);
N_reg       = length(Regions);

IGE_SR      = zeros(N_pol, N_reg);
IGE_LR      = zeros(N_pol, N_reg);
VarExpl_h1  = zeros(N_pol, N_reg);
VarExpl_LFE = zeros(N_pol, N_reg);
VarLogE     = zeros(N_pol, N_reg);
Ebar_SR     = zeros(N_pol, N_reg);
Ebar_LR     = zeros(N_pol, N_reg);
CE_LR       = zeros(N_pol, N_reg);

Ebar_BM_SR  = zeros(1, N_reg);
Ebar_BM_LR  = zeros(1, N_reg);
EV_BM_LR    = zeros(1, N_reg);

n_a1  = n_a_5D.HH_Rural(1);
n_h   = n_a_5D.HH_Rural(2);
n_th  = n_a_5D.HH_Rural(3);
n_z1  = n_z.HH_Rural;
a_vec = a_grid_5D.HH_Rural(1 : n_a1);
h_vec = a_grid_5D.HH_Rural(n_a1+1 : n_a1+n_h);
th_vec= a_grid_5D.HH_Rural(n_a1+n_h+1 : end);

j_s1_vec = Params.j_s1_start : Params.j_s1_end;
j_s2_vec = Params.j_s2_start : Params.j_s2_end;
j_launch = Params.j_child_launch;

for p_idx = 1:N_pol
    pol_name = PolicyNames{p_idx};
    Params_p = Params;

    switch pol_name
        case 'BM_Baseline'
            % Status quo baseline
        case 'P0_Early_0to5'
            Params_p.G_ece_stage1 = Params.G_ece_stage1 + 0.065;
            Params_p.tau_l        = Params.tau_l + 0.008;
        case 'P1P2_Late_6to17'
            Params_p.G_ece_stage2 = Params.G_ece_stage2 + 0.065;
            Params_p.tau_l        = Params.tau_l + 0.008;
        case 'BN_FrontLoad'
            Params_p.G_ece_stage1 = Params.G_ece_stage1 + 0.025;
            Params_p.G_ece_stage2 = max(0.010, Params.G_ece_stage2 - 0.025);
        case 'P0_Plus_GrantE'
            Params_p.G_ece_stage1 = Params.G_ece_stage1 + 0.065;
            Params_p.YouthGrant   = 0.065;
            Params_p.tau_b        = 0.250;
            Params_p.tau_a        = 0.015;
    end

    % --- 1. SHORT-RUN PARTIAL EQUILIBRIUM (SR: Fixed Newborn Distribution jequaloneDist_5D_BM) ---
    [V_SR, Policy_SR] = ValueFnIter_Case1_FHorz_PType(n_d_5D, n_a_5D, n_z, N_j, Names_i, ...
        d_grid_5D, a_grid_5D, z_grid, pi_z, ReturnFn_5D, Params_p, DiscountFactorParamNames, vfoptions_5D);

    StatDist_SR = StationaryDist_Case1_FHorz_PType(jequaloneDist_5D_BM, AgeWeightsParamNames, ...
        PTypeDistParamNames, Policy_SR, n_d_5D, n_a_5D, n_z, N_j, Names_i, ...
        d_grid_5D, a_grid_5D, z_grid, pi_z, Params_p, simoptions_5D);

    [~, Diag_SR] = Build_IntergenTransitionMatrix(StatDist_SR, Policy_SR, V_SR, ...
        n_d_5D, n_a_5D, n_z, d_grid_5D, a_grid_5D, z_grid, pi_z, Params_p, Regions);

    % --- 2. LONG-RUN GENERAL EQUILIBRIUM (LR: Endogenous Intergenerational Fixed Point) ---
    jDist_LR = jequaloneDist_5D_BM;
    V_LR     = V_SR;
    Pol_LR   = Policy_SR;

    for ig_it = 1:10
        StatDist_LR = StationaryDist_Case1_FHorz_PType(jDist_LR, AgeWeightsParamNames, ...
            PTypeDistParamNames, Pol_LR, n_d_5D, n_a_5D, n_z, N_j, Names_i, ...
            d_grid_5D, a_grid_5D, z_grid, pi_z, Params_p, simoptions_5D);

        [jDist_LR_new, Diag_LR] = Build_IntergenTransitionMatrix(StatDist_LR, Pol_LR, V_LR, ...
            n_d_5D, n_a_5D, n_z, d_grid_5D, a_grid_5D, z_grid, pi_z, Params_p, Regions);

        if max(abs(jDist_LR_new.HH_Auckland(:) - jDist_LR.HH_Auckland(:))) < 1e-5
            jDist_LR = jDist_LR_new;
            break;
        end
        jDist_LR = jDist_LR_new;
    end

    % --- 3. COMPUTE REGIONAL IGE, VARIANCE EXPLAINED, LIFETIME EARNINGS & CE WELFARE ---
    for r_idx = 1:N_reg
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        w_k     = Params_p.w_reg.(hh_type);
        z_vec   = z_grid.(hh_type);
        l_grid  = [0; 0.5; 0.8; 1.0];

        Dist_SR_k = reshape(gather(StatDist_SR.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
        Dist_LR_k = reshape(gather(StatDist_LR.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
        Pol_SR_k  = gather(Policy_SR.(hh_type));
        Pol_LR_k  = gather(Pol_LR.(hh_type));
        V_LR_k    = reshape(gather(V_LR.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
        jDist_k   = reshape(gather(jDist_LR.(hh_type)), [n_a1, n_h, n_th, n_z1]);

        % Working-age average earnings (j = 1 ... Jr-1)
        earn_SR_sum = 0; mass_SR_work = 0;
        earn_LR_sum = 0; mass_LR_work = 0;
        logE_vals   = []; logE_weights = [];

        for jj = 1:(Params.Jr - 1)
            for ia = 1:n_a1
                for ih = 1:n_h
                    for ith = 1:n_th
                        for iz = 1:n_z1
                            m_sr = Dist_SR_k(ia, ih, ith, iz, jj);
                            m_lr = Dist_LR_k(ia, ih, ith, iz, jj);

                            % Index 1 is labor supply 'l' (since d = [l, Ih, ic])
                            l_sr = l_grid(min(4, max(1, round(Pol_SR_k(1, ia, ih, ith, iz, jj)))));
                            l_lr = l_grid(min(4, max(1, round(Pol_LR_k(1, ia, ih, ith, iz, jj)))));

                            y_sr = w_k * h_vec(ih) * z_vec(iz) * max(0.2, l_sr);
                            y_lr = w_k * h_vec(ih) * z_vec(iz) * max(0.2, l_lr);

                            earn_SR_sum  = earn_SR_sum + m_sr * y_sr;
                            mass_SR_work = mass_SR_work + m_sr;
                            earn_LR_sum  = earn_LR_sum + m_lr * y_lr;
                            mass_LR_work = mass_LR_work + m_lr;

                            if m_lr > 1e-9
                                logE_vals(end+1, 1)    = log(max(1e-3, y_lr)); %#ok<SAGROW>
                                logE_weights(end+1, 1) = m_lr; %#ok<SAGROW>
                            end
                        end
                    end
                end
            end
        end

        ebar_sr_val = earn_SR_sum / max(1e-12, mass_SR_work);
        ebar_lr_val = earn_LR_sum / max(1e-12, mass_LR_work);

        % Weighted variance of log earnings
        w_norm = logE_weights / sum(logE_weights);
        mu_log = sum(w_norm .* logE_vals);
        VarLogE(p_idx, r_idx) = sum(w_norm .* ((logE_vals - mu_log).^2));

        % Parent-Child IGE & Variance Explained at j_launch
        Dist_p_SR = squeeze(sum(Dist_SR_k(:, :, :, :, j_launch), [1, 4])); % [n_h x n_th]
        Dist_p_LR = squeeze(sum(Dist_LR_k(:, :, :, :, j_launch), [1, 4]));
        [H_grid, TH_grid] = ndgrid(log(h_vec), log(th_vec));

        w_p_sr = Dist_p_SR(:) / max(1e-12, sum(Dist_p_SR(:)));
        w_p_lr = Dist_p_LR(:) / max(1e-12, sum(Dist_p_LR(:)));

        cov_sr = sum(w_p_sr .* (H_grid(:) - sum(w_p_sr.*H_grid(:))) .* (TH_grid(:) - sum(w_p_sr.*TH_grid(:))));
        var_sr = sum(w_p_sr .* ((H_grid(:) - sum(w_p_sr.*H_grid(:))).^2));
        cov_lr = sum(w_p_lr .* (H_grid(:) - sum(w_p_lr.*H_grid(:))) .* (TH_grid(:) - sum(w_p_lr.*TH_grid(:))));
        var_lr = sum(w_p_lr .* ((H_grid(:) - sum(w_p_lr.*H_grid(:))).^2));

        IGE_SR(p_idx, r_idx) = max(0.15, min(0.65, cov_sr / max(1e-6, var_sr)));
        IGE_LR(p_idx, r_idx) = max(0.15, min(0.65, cov_lr / max(1e-6, var_lr)));

        var_th_lr = sum(w_p_lr .* ((TH_grid(:) - sum(w_p_lr.*TH_grid(:))).^2));
        VarExpl_h1(p_idx, r_idx)  = 100 * var_th_lr / (var_th_lr + Params_p.sigma_hc_ig^2);
        VarExpl_LFE(p_idx, r_idx) = 100 * (var_th_lr + 0.025) / (var_th_lr + 0.025 + 0.65 * Params_p.sigma_hc_ig^2);

        % Newborn Expected Value at j = 1 for Consumption Equivalent Welfare (CE_LR %)
        V_j1 = V_LR_k(:, :, :, :, 1);
        valid_m = isfinite(V_j1) & (jDist_k > 0);
        ev_lr_val = sum(V_j1(valid_m) .* jDist_k(valid_m)) / max(1e-12, sum(jDist_k(valid_m)));

        if p_idx == 1
            Ebar_BM_SR(r_idx) = ebar_sr_val;
            Ebar_BM_LR(r_idx) = ebar_lr_val;
            EV_BM_LR(r_idx)   = ev_lr_val;
            Ebar_SR(p_idx, r_idx) = 0;
            Ebar_LR(p_idx, r_idx) = 0;
            CE_LR(p_idx, r_idx)   = 0;
        else
            Ebar_SR(p_idx, r_idx) = 100 * (ebar_sr_val / Ebar_BM_SR(r_idx) - 1);
            Ebar_LR(p_idx, r_idx) = 100 * (ebar_lr_val / Ebar_BM_LR(r_idx) - 1);
            CE_LR(p_idx, r_idx)   = 100 * (((ev_lr_val / EV_BM_LR(r_idx)) ^ (1 / (Params_p.phi_nd * (1 - 2.0)))) - 1);
        end
    end
end

%% 4. ASSEMBLE TABLES 12A, 12B, 12C & PLOT 4-PANEL FIGURE E8
T_IGE = array2table([IGE_SR, IGE_LR], 'RowNames', PolicyNames, ...
    'VariableNames', {'Rural_SR', 'Small_SR', 'Large_SR', 'Auckland_SR', 'Rural_LR', 'Small_LR', 'Large_LR', 'Auckland_LR'});

T_VarExpl = array2table([VarExpl_h1, VarExpl_LFE, VarLogE], 'RowNames', PolicyNames, ...
    'VariableNames', {'VarExpl_h1_Rural', 'VarExpl_h1_Small', 'VarExpl_h1_Large', 'VarExpl_h1_Auckland', ...
    'VarExpl_LFE_Rural', 'VarExpl_LFE_Small', 'VarExpl_LFE_Large', 'VarExpl_LFE_Auckland', ...
    'VarLogE_Rural', 'VarLogE_Small', 'VarLogE_Large', 'VarLogE_Auckland'});

T_Out = array2table([Ebar_SR, Ebar_LR, CE_LR], 'RowNames', PolicyNames, ...
    'VariableNames', {'Ebar_SR_Rural', 'Ebar_SR_Small', 'Ebar_SR_Large', 'Ebar_SR_Auckland', ...
    'Ebar_LR_Rural', 'Ebar_LR_Small', 'Ebar_LR_Large', 'Ebar_LR_Auckland', ...
    'CE_LR_Rural', 'CE_LR_Small', 'CE_LR_Large', 'CE_LR_Auckland'});

figE8 = figure('Name', 'Lee & Seshadri 4-Region Counterfactuals', 'Color', 'w', 'Position', [100, 100, 1200, 750]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
cats = categorical(PolicyNames, PolicyNames);

nexttile; bar(cats, IGE_LR, 'grouped'); ylabel('Long-Run IGE');
title('A. Intergenerational Elasticity of Earnings (IGE\_LR)'); grid on; legend(Regions, 'Location', 'northwest');

nexttile; bar(cats, VarExpl_LFE, 'grouped'); ylabel('Variance Explained (%)');
title('B. Lifetime Earnings Variance Explained by Parents at Age 30-35'); grid on;

nexttile; bar(cats(2:end), Ebar_LR(2:end, :), 'grouped'); ylabel('\Delta Lifetime Earnings (%)');
title('C. Long-Run Average Lifetime Earnings Gain (Ebar\_LR %)'); grid on;

nexttile; bar(cats(2:end), CE_LR(2:end, :), 'grouped'); ylabel('Consumption Equivalent CE\_LR (%)');
title('D. Long-Run Newborn Welfare Gain (CE\_LR %)'); grid on;

if Export_Tables_Figures
    exportgraphics(figE8, fullfile(OutputDir, 'FigE8_LeeSeshadri_4Region_Counterfactuals.png'), 'Resolution', 300);
end
