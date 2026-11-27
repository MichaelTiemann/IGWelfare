function LSOut = Compute_LeeSeshadri_Counterfactuals(Params, Grids5D, Baseline5D, Opts)
%% PURE MATHEMATICAL CONTRACT: MULTI-STAGE CHILDHOOD COUNTERFACTUALS ACROSS REGIONS
% File: src/models/Compute_LeeSeshadri_Counterfactuals.m
% Evaluates Lee & Seshadri (2019) / Cunha, Heckman & Schennach (2010) counterfactuals:
%   1. 'BM_Baseline'     : Status quo NZ policy
%   2. 'P0_Early_0to5'   : Stage-1 First 2000 Days wraparound ECE expansion (j in J_c1)
%   3. 'P1P2_Late_6to17' : Stage-2 School-Age remedial expansion (j in J_c2)
%   4. 'BN_FrontLoad'    : Budget-neutral reallocation from Stage 2 to Stage 1
%   5. 'P0_Plus_GrantE'  : Stage-1 ECE expansion + Youth Capital Grant E at j = 1
% Pure, idempotent state-to-value transformation: zero evalin/assignin, zero disk/figure I/O.

if nargin < 4 || isempty(Opts)
    Opts = struct();
end

if ~isfield(Params, 'dt') || ~isfield(Params, 'DataSpec_Digest')
    Params = Configure_Model_Params(Params);
end

if isfield(Opts, 'Regions') && ~isempty(Opts.Regions)
    Regions = Opts.Regions;
else
    Regions = Params.Regions;
end

if isfield(Opts, 'PolicyNames') && ~isempty(Opts.PolicyNames)
    PolicyNames = Opts.PolicyNames(:);
else
    PolicyNames = {'BM_Baseline'; 'P0_Early_0to5'; 'P1P2_Late_6to17'; 'BN_FrontLoad'; 'P0_Plus_GrantE'};
end
verbose_log = ~isfield(Opts, 'Verbose') || logical(Opts.Verbose);
Backend     = Resolve_Compute_Backend();

n_d_5D                   = Grids5D.n_d_5D;
n_a_5D                   = Grids5D.n_a_5D;
n_z                      = Grids5D.n_z;
N_j                      = Grids5D.N_j;
d_grid_5D                = Grids5D.d_grid_5D;
a_grid_5D                = Grids5D.a_grid_5D;
z_grid                   = Grids5D.z_grid;
pi_z                     = Grids5D.pi_z;
ReturnFn_5D              = Grids5D.ReturnFn_5D;
DiscountFactorParamNames = Grids5D.DiscountFactorParamNames;
vfoptions_5D             = Grids5D.vfoptions_5D;
simoptions_5D            = Grids5D.simoptions_5D;

jequaloneDist_5D_BM = Baseline5D.jequaloneDist_5D_BM;
has_bm_sol          = isfield(Baseline5D, 'V_5D_BM') && ~isempty(Baseline5D.V_5D_BM) ...
                   && isfield(Baseline5D, 'Policy_5D_BM') && ~isempty(Baseline5D.Policy_5D_BM);

N_pol = length(PolicyNames);
N_reg = length(Regions);

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

ref_hh_ls = ['HH_', Regions{1}];
n_a1   = n_a_5D.(ref_hh_ls)(1);
n_h    = n_a_5D.(ref_hh_ls)(2);
n_th   = n_a_5D.(ref_hh_ls)(3);
n_z1   = n_z.(ref_hh_ls);
h_vec  = a_grid_5D.(ref_hh_ls)(n_a1+1 : n_a1+n_h);
th_vec = a_grid_5D.(ref_hh_ls)(n_a1+n_h+1 : end);

j_launch = min(Params.J, max(1, Params.j_child_launch));

simoptions_5D.d_grid = d_grid_5D;
simoptions_5D.a_grid = a_grid_5D;

for p_idx = 1:N_pol
    pol_name = PolicyNames{p_idx};
    if strcmp(pol_name, 'BM_Baseline')
        Params_p = Params;
    else
        Params_p = Apply_Policy_Regime(Params, pol_name);
    end

    t_pol = tic;
    if verbose_log
        fprintf('    [Step 2 Policy %d/%d] Solving %s...\n', p_idx, N_pol, pol_name);
        Backend.FlushConsole();
    end

    % --- 1. SHORT-RUN PARTIAL EQUILIBRIUM (SR: Fixed Newborn Distribution jequaloneDist_5D_BM) ---
    if strcmp(pol_name, 'BM_Baseline') && has_bm_sol
        V_SR      = Baseline5D.V_5D_BM;
        Policy_SR = Baseline5D.Policy_5D_BM;
    else
        [V_SR, Policy_SR] = Solve_VFI_PhaseSplit(n_d_5D, n_a_5D, n_z, N_j, ...
            d_grid_5D, a_grid_5D, z_grid, pi_z, ReturnFn_5D, Params_p, DiscountFactorParamNames, vfoptions_5D, Regions);
    end
    if verbose_log
        fprintf('      -> VFI done in %.1fs\n', toc(t_pol));
        Backend.FlushConsole();
    end

    HH_TransCache_p = Precompute_HH_StationaryCache( ...
        Policy_SR, n_d_5D, n_a_5D, n_z, N_j, d_grid_5D, a_grid_5D, pi_z, Params_p, simoptions_5D, Regions);

    StatDist_SR = PushForward_HH_Dist(struct(), jequaloneDist_5D_BM, HH_TransCache_p, Regions);
    StatDist_SR.ptweights = reshape(Params_p.PTypeWeights, [], 1);

    % --- 2. LONG-RUN GENERAL EQUILIBRIUM (LR: Endogenous Intergenerational Fixed Point) ---
    jDist_LR    = jequaloneDist_5D_BM;
    V_LR        = V_SR;
    Pol_LR      = Policy_SR;
    ig_resid    = Inf;
    StatDist_LR = struct();
    for ig_it = 1:10
        StatDist_LR = PushForward_HH_Dist(StatDist_LR, jDist_LR, HH_TransCache_p, Regions);
        StatDist_LR.ptweights = reshape(Params_p.PTypeWeights, [], 1);

        [jDist_LR_new, ~] = Build_IntergenTransitionMatrix(StatDist_LR, Pol_LR, V_LR, ...
            n_d_5D, n_a_5D, n_z, d_grid_5D, a_grid_5D, z_grid, pi_z, Params_p, Regions);

        ig_resid = 0;
        for rr_ig = 1:N_reg
            ht_ig    = ['HH_', Regions{rr_ig}];
            ig_resid = max(ig_resid, max(abs(jDist_LR_new.(ht_ig)(:) - jDist_LR.(ht_ig)(:))));
        end
        jDist_LR = jDist_LR_new;
        if ig_resid < 1e-5
            break;
        end
    end
    if ~(ig_resid < 1e-5)
        IGW_Log('IGW:NoConvergence', 'Compute_LeeSeshadri_Counterfactuals LR intergenerational fixed point (%s): %d iterations, residual %.3g', ...
            pol_name, ig_it, double(gather(ig_resid)));
    end

    % --- 3. COMPUTE REGIONAL IGE, VARIANCE EXPLAINED, LIFETIME EARNINGS & CE WELFARE ---
    for r_idx = 1:N_reg
        reg     = Regions{r_idx};
        hh_type = ['HH_', reg];
        w_k     = Params_p.w_reg.(hh_type);
        z_vec   = z_grid.(hh_type);
        n_l_pts = n_d_5D.(hh_type)(1);
        l_grid  = d_grid_5D.(hh_type)(1:n_l_pts);

        Dist_SR_k = reshape(gather(StatDist_SR.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
        Dist_LR_k = reshape(gather(StatDist_LR.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
        Pol_SR_k  = gather(Policy_SR.(hh_type));
        Pol_LR_k  = gather(Pol_LR.(hh_type));
        V_LR_k    = reshape(gather(V_LR.(hh_type)), [n_a1, n_h, n_th, n_z1, Params.J]);
        jDist_k   = reshape(gather(jDist_LR.(hh_type)), [n_a1, n_h, n_th, n_z1]);

        % Working-age slice: j = 1 ... Jr-1 (5D Tensor: [n_a1, n_h, n_th, n_z1, Jr-1])
        j_work    = 1:max(1, Params.Jr - 1);
        Dist_SR_w = Dist_SR_k(:, :, :, :, j_work);
        Dist_LR_w = Dist_LR_k(:, :, :, :, j_work);

        % Extract labor supply decision l (Index 1 of Policy) across all working-age states at once
        idx_l_sr = min(n_l_pts, max(1, round(reshape(Pol_SR_k(1, :, :, :, :, j_work), size(Dist_SR_w)))));
        idx_l_lr = min(n_l_pts, max(1, round(reshape(Pol_LR_k(1, :, :, :, :, j_work), size(Dist_LR_w)))));
        l_sr_ten = max(0.2, reshape(l_grid(idx_l_sr), size(Dist_SR_w)));
        l_lr_ten = max(0.2, reshape(l_grid(idx_l_lr), size(Dist_LR_w)));

        % 5D implicit expansion: h_vec is [1 x n_h x 1 x 1 x 1], z_vec is [1 x 1 x 1 x n_z1 x 1]
        hz_tensor = w_k .* reshape(h_vec, [1, n_h, 1, 1, 1]) .* reshape(z_vec, [1, 1, 1, n_z1, 1]);
        Y_SR_ten  = hz_tensor .* l_sr_ten;
        Y_LR_ten  = hz_tensor .* l_lr_ten;

        earn_SR_sum  = sum(Dist_SR_w .* Y_SR_ten, 'all');
        mass_SR_work = sum(Dist_SR_w, 'all');
        earn_LR_sum  = sum(Dist_LR_w .* Y_LR_ten, 'all');
        mass_LR_work = sum(Dist_LR_w, 'all');

        mask_pos = Dist_LR_w > 1e-9;
        if any(mask_pos(:))
            logE_vals    = log(max(1e-3, Y_LR_ten(mask_pos)));
            logE_weights = Dist_LR_w(mask_pos);
            w_norm       = logE_weights / sum(logE_weights);
            mu_log       = sum(w_norm .* logE_vals);
            VarLogE(p_idx, r_idx) = sum(w_norm .* ((logE_vals - mu_log).^2));
        end

        ebar_sr_val = earn_SR_sum / max(1e-12, mass_SR_work);
        ebar_lr_val = earn_LR_sum / max(1e-12, mass_LR_work);

        % Parent-Child Lifetime Earnings IGE & Variance Explained at j_launch
        % Mirror exact 5D Stage-3 launch operator from Build_IntergenTransitionMatrix.m (0.68 * log(theta_c)
        % minus parental asset crowding & unbuffered adolescent stress) over [n_a1 x n_h x n_th]:
        a1_vec    = a_grid_5D.(hh_type)(1:n_a1);
        Q_hk      = Params_p.Q_reg.(hh_type);
        Q_bk      = Params_p.Q_reg_base.(hh_type);
        K_wk      = Params_p.K_whanau.(hh_type);
        g2_k      = Params_p.G_ece_stage2.(hh_type);
        M_ment_k  = min(1.0, max(0.0, (g2_k - Params_p.G_ece1_sched(1)) / max(1e-6, Params_p.G_ece2_sched(2) - Params_p.G_ece1_sched(1))));
        M_tr_k    = M_ment_k * (0.45 + 0.55 * min(1.0, K_wk / 0.35));
        lam_b_k   = 0.38;
        if isfield(Params_p, 'lambda_psy') && isstruct(Params_p.lambda_psy) && isfield(Params_p.lambda_psy, hh_type)
            lam_b_k = Params_p.lambda_psy.(hh_type);
        end
        lam_p_k   = max(0.22 * 0.38, 0.22 * (lam_b_k / 0.38) * (1.0 - 0.52 * M_tr_k) * (1.0 - 0.35 * min(1.0, K_wk / 0.38)));
        unbuf_k   = max(0.38 * lam_p_k, (1.0 - 0.80 * M_tr_k) * (1.0 - 0.55 * K_wk));
        stress_at = 0.038 .* ((0.55 * double(a1_vec < 0.12 * Q_hk) + 0.45 * double(reshape(th_vec, [1, 1, n_th]) < 0.85)) ...
                  .* (1.0 + 0.65 * lam_p_k) + lam_p_k) .* unbuf_k;
        psi_cr    = 0.14;
        if isfield(Params_p, 'psi_crowd') && ~isempty(Params_p.psi_crowd), psi_cr = Params_p.psi_crowd; end
        crowd_a   = psi_cr * (Q_hk / max(0.50, Q_bk)) * double(a1_vec < 0.20 * Q_hk);
        Y_ch_3D   = repmat(reshape(log(th_vec), [1, 1, n_th]) - (stress_at + reshape(crowd_a, [n_a1, 1, 1])) ./ 0.68, [1, n_h, 1]);
        H_par_3D  = repmat(reshape(log(h_vec), [1, n_h, 1]), [n_a1, 1, n_th]);

        Dist_3_SR = reshape(sum(Dist_SR_k(:, :, :, :, j_launch), 4), [n_a1, n_h, n_th]);
        Dist_3_LR = reshape(sum(Dist_LR_k(:, :, :, :, j_launch), 4), [n_a1, n_h, n_th]);
        w3_sr     = Dist_3_SR(:) / max(1e-12, sum(Dist_3_SR(:)));
        w3_lr     = Dist_3_LR(:) / max(1e-12, sum(Dist_3_LR(:)));

        rho_ig    = 0.40;
        if isfield(Params_p, 'rho_hc_ig') && ~isempty(Params_p.rho_hc_ig), rho_ig = Params_p.rho_hc_ig; end
        cov_sr    = sum(w3_sr .* (H_par_3D(:) - sum(w3_sr .* H_par_3D(:))) .* (Y_ch_3D(:) - sum(w3_sr .* Y_ch_3D(:))));
        var_sr    = sum(w3_sr .* ((H_par_3D(:) - sum(w3_sr .* H_par_3D(:))).^2));
        cov_lr    = sum(w3_lr .* (H_par_3D(:) - sum(w3_lr .* H_par_3D(:))) .* (Y_ch_3D(:) - sum(w3_lr .* Y_ch_3D(:))));
        var_lr    = sum(w3_lr .* ((H_par_3D(:) - sum(w3_lr .* H_par_3D(:))).^2));

        IGE_SR(p_idx, r_idx) = max(0.10, min(0.65, rho_ig * (cov_sr / max(1e-8, var_sr))));
        IGE_LR(p_idx, r_idx) = max(0.10, min(0.65, rho_ig * (cov_lr / max(1e-8, var_lr))));

        Dist_p_LR = reshape(sum(Dist_3_LR, 1), [n_h, n_th]);
        [~, TH_grid] = ndgrid(log(h_vec), log(th_vec));
        w_p_lr    = Dist_p_LR(:) / max(1e-12, sum(Dist_p_LR(:)));

        var_th_lr = sum(w_p_lr .* ((TH_grid(:) - sum(w_p_lr.*TH_grid(:))).^2));
        VarExpl_h1(p_idx, r_idx)  = 100 * var_th_lr / (var_th_lr + Params_p.sigma_hc_ig^2);
        VarExpl_LFE(p_idx, r_idx) = 100 * (var_th_lr + 0.025) / (var_th_lr + 0.025 + 0.65 * Params_p.sigma_hc_ig^2);

        % Newborn Expected Value at j = 1 for Consumption Equivalent Welfare (CE_LR %)
        V_j1      = V_LR_k(:, :, :, :, 1);
        valid_m   = isfinite(V_j1) & (jDist_k > 0);
        ev_lr_val = sum(V_j1(valid_m) .* jDist_k(valid_m)) / max(1e-12, sum(jDist_k(valid_m)));

        if p_idx == 1
            Ebar_BM_SR(r_idx)     = ebar_sr_val;
            Ebar_BM_LR(r_idx)     = ebar_lr_val;
            EV_BM_LR(r_idx)       = ev_lr_val;
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

%% 4. ASSEMBLE CANONICAL TABLES 12A, 12B, 12C & OUTPUT STRUCT
T_IGE = array2table([IGE_SR, IGE_LR], 'RowNames', PolicyNames, ...
    'VariableNames', [cellfun(@(r) [r, '_SR'], Regions, 'UniformOutput', false), ...
                      cellfun(@(r) [r, '_LR'], Regions, 'UniformOutput', false)]);

T_VarExpl = array2table([VarExpl_h1, VarExpl_LFE, VarLogE], 'RowNames', PolicyNames, ...
    'VariableNames', [cellfun(@(r) ['VarExpl_h1_',  r], Regions, 'UniformOutput', false), ...
                      cellfun(@(r) ['VarExpl_LFE_', r], Regions, 'UniformOutput', false), ...
                      cellfun(@(r) ['VarLogE_',     r], Regions, 'UniformOutput', false)]);

T_Out = array2table([Ebar_SR, Ebar_LR, CE_LR], 'RowNames', PolicyNames, ...
    'VariableNames', [cellfun(@(r) ['Ebar_SR_', r], Regions, 'UniformOutput', false), ...
                      cellfun(@(r) ['Ebar_LR_', r], Regions, 'UniformOutput', false), ...
                      cellfun(@(r) ['CE_LR_',   r], Regions, 'UniformOutput', false)]);

LSOut = struct();
LSOut.Regions     = Regions;
LSOut.PolicyNames = PolicyNames;
LSOut.IGE_SR      = IGE_SR;
LSOut.IGE_LR      = IGE_LR;
LSOut.VarExpl_h1  = VarExpl_h1;
LSOut.VarExpl_LFE = VarExpl_LFE;
LSOut.VarLogE     = VarLogE;
LSOut.Ebar_SR     = Ebar_SR;
LSOut.Ebar_LR     = Ebar_LR;
LSOut.CE_LR       = CE_LR;
LSOut.T_IGE       = T_IGE;
LSOut.T_VarExpl   = T_VarExpl;
LSOut.T_Out       = T_Out;

end
