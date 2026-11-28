function test_wave5_policy_composition()
%% TEST_WAVE5_POLICY_COMPOSITION
% Regression gate for Wave 5 Compositional Policy Algebra & Pure Ledgers:
%   1. Catalog schema & profile inheritance (NZ_Dunedin1972 -> NZ_GUiNZ2009).
%   2. Commutativity & exact equivalence of composed bundles ({A, B} == {B, A} == named composite).
%   3. Non-linear cross-commitment coupling (C01 x C10 Q_Auckland -> Kaiako_Deflator) & two-sided C15 symmetry.
%   4. Pure headless ledgers (Actuarial, Synergy/Mirror Table19+19E, Civic Gearing, Divergence).
%   5. Fast solved 5D general-equilibrium + endogenous-IG batch verifying PE -> IG reversal & interaction wedges.

repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);
setup_igw_paths(true);

%% 1. COMMITMENT CATALOG SCHEMA & PROFILE INHERITANCE
Cat_Dun  = Load_Commitment_Catalog('NZ_Dunedin1972');
Cat_Gui  = Load_Commitment_Catalog('NZ_GUiNZ2009');
check(numel(Cat_Dun.Commitment_IDs) >= 15, 'Expected at least 15 institutional commitments');
check(strcmp(Cat_Dun.Digest, Cat_Gui.Digest), 'NZ_GUiNZ2009 failed to inherit commitment catalog digest');

%% 2. EXACT COMMUTATIVITY & NAMED-BUNDLE EQUIVALENCE IN COMPOSE_POLICY_BUNDLE
P0  = Configure_Model_Params(struct('Profile_Name', 'NZ_Dunedin1972', 'dt', 5));
pi0 = struct();
for r = 1:4
    reg = P0.Regions{r};
    pi0.(['HH_', reg]) = repmat([0.06, 0.12, 0.22, 0.28, 0.18, 0.10, 0.04], 7, 1);
end
[P_base, pi_base] = Compose_Policy_Bundle(P0, pi0, 'baseline_2023');

[P_ab, pi_ab, M_ab] = Compose_Policy_Bundle(P_base, pi_base, {'retrenchment_and_tenure_10', 'tax_visa_expensing_3'});
[P_ba, pi_ba, M_ba] = Compose_Policy_Bundle(P_base, pi_base, {'tax_visa_expensing_3', 'retrenchment_and_tenure_10'});
[P_13, pi_13, M_13] = Compose_Policy_Bundle(P_base, pi_base, 'combined_13_commitments');

check(abs(P_ab.Q_reg.HH_Auckland - P_ba.Q_reg.HH_Auckland) < 1e-15, 'Bundle composition violated commutativity on Q_reg');
check(abs(P_ab.Q_reg.HH_Auckland - P_13.Q_reg.HH_Auckland) < 1e-15, 'Composed {A, B} differed from combined_13_commitments');
check(abs(M_ab.Social_Cohesion_St - M_13.Social_Cohesion_St) < 1e-12, 'Composed {A, B} cohesion differed from combined_13_commitments');
check(max(abs(pi_ab.HH_Large(:) - pi_13.HH_Large(:))) < 1e-15, 'Composed layoff Markov matrix differed');

% 4-part composition == domestic_15_bundle (and legacy alias 'all_but_ndc'):
[P_comp15, ~, M_comp15] = Compose_Policy_Bundle(P_base, pi_base, ...
    {'retrenchment_and_tenure_10', 'tax_visa_expensing_3', 'water_stewardship_shift', 'civic_commons_contraction'});
[P_dom15,  ~, M_dom15]  = Apply_Coalition_2024_Shocks(P_base, pi_base, 'all_but_ndc');
check(abs(P_comp15.mu_maint.HH_Large - P_dom15.mu_maint.HH_Large) < 1e-15, '4-part composition differed from domestic_15_bundle mu_maint');
check(abs(M_comp15.TI_Social_Credit_CPI - M_dom15.TI_Social_Credit_CPI) < 1e-12, '4-part composition differed from Apply_Coalition_2024_Shocks');

%% 3. CROSS-COMMITMENT COUPLING (C01 x C10 -> KAIAKO DEFLATOR) & TWO-SIDED C15 SYMMETRY
[P_c01, ~] = Compose_Policy_Bundle(P_base, pi_base, struct('C01_tenure_tax_neutrality', -1.0));
[P_c10, ~] = Compose_Policy_Bundle(P_base, pi_base, struct('C10_investor_visa_capital_inflow', +1.0));
[P_both,~] = Compose_Policy_Bundle(P_base, pi_base, struct('C01_tenure_tax_neutrality', -1.0, 'C10_investor_visa_capital_inflow', +1.0));
check(P_both.Q_reg.HH_Auckland > P_c01.Q_reg.HH_Auckland && P_both.Q_reg.HH_Auckland > P_c10.Q_reg.HH_Auckland, ...
    'Joint C01(-) and C10(+) failed to compound urban house-price pressure');
check(P_both.Kaiako_Deflator.HH_Auckland < P_c01.Kaiako_Deflator.HH_Auckland, ...
    'Joint Q_k inflation failed to trigger Kaiako housing-cost deflator');

[~, ~, M_c15_neg] = Compose_Policy_Bundle(P_base, pi_base, 'civic_commons_contraction');
[~, ~, M_c15_pos] = Compose_Policy_Bundle(P_base, pi_base, 'civic_commons_expansion_doc1e');
check(M_c15_neg.Social_Cohesion_St < 96.0 && M_c15_pos.Social_Cohesion_St > 107.0, ...
    'C15 failed two-sided opposite-sign cohesion check');

%% 4. PURE HEADLESS LEDGERS (ZERO FIGURE SIDE EFFECTS)
figs_before = numel(findall(0, 'Type', 'figure'));
L_act = Compute_Actuarial_Ledger([], struct('Profile_Name', 'NZ_Dunedin1972'));
L_syn = Compute_Synergy_And_Mirror_Ledger(struct('Profile_Name', 'NZ_Dunedin1972', 'Civic_Commitment_Scale', 1.0));
L_syn0= Compute_Synergy_And_Mirror_Ledger(struct('Profile_Name', 'NZ_Dunedin1972', 'Civic_Commitment_Scale', 0.0));
L_civ = Compute_Civic_Gearing_Ledger(P0);
L_div = Compute_Divergence_Trajectory_Ledger(P0);
figs_after = numel(findall(0, 'Type', 'figure'));

check(figs_after == figs_before, 'Pure ledger functions leaked figure handles');
check(abs(L_act.Year5Table.Booked_Fisc_2pct_B(end) - 35.25) < 0.05, 'Actuarial Year-5 national benchmark drifted');
check(abs((L_syn.Table19E.Cumulative_National_SS2_CE(end) - L_syn0.Table19E.Cumulative_National_SS2_CE(end)) - 3.40) < 0.02, ...
    'Arts & Civic Cap (u_civic = 1 vs 0) deviated from +3.40% CE');
check(L_civ.Gearing_Up > 24.0 && L_civ.Gearing_Down > 24.0, 'Civic two-sided gearing dropped below 24x');
check(height(L_div.Table_Divergence) == 21, 'Divergence ledger expected 21 dt=3 steps (2024..2084)');

%% 5. FAST CANONICAL-5D SOLVED EQUILIBRIUM BATCH CHECK (PE -> GE -> ENDOGENOUS IG)
BS = build_5d_test_state();
MiniSpecs = { ...
    'Retrenchment_10', 'retrenchment_and_tenure_10', 'Retrenchment'; ...
    'TaxVisaExp_3',    'tax_visa_expensing_3',       'Tax/Visa/Exp'; ...
    'Combined_13',     {'retrenchment_and_tenure_10', 'tax_visa_expensing_3'}, 'Combined 13'};
BatchMini = Compute_Policy_Composition_Batch(BS, MiniSpecs, struct('Verbose', false, 'Core13Scale', 0.40));

ce_ret = BatchMini.Table_Stage3_Delta{'Retrenchment_10', 'National_CE_Pct'};
ce_tax = BatchMini.Table_Stage3_Delta{'TaxVisaExp_3',    'National_CE_Pct'};
ce_c13 = BatchMini.Table_Stage3_Delta{'Combined_13',     'National_CE_Pct'};
pe_c13 = BatchMini.Bundles.Combined_13.CE_Nat_3x1(1);

check(ce_ret < -1.0 && ce_tax > 0.2 && ce_c13 < -0.5, ...
    sprintf('Unexpected Stage-3 signs: Ret=%.2f%%, Tax=%.2f%%, C13=%.2f%%', ce_ret, ce_tax, ce_c13));
check(BatchMini.Additionality.PE_to_IG_Reversal_C13 < -1.0, ...
    sprintf('Expected strong negative PE -> IG reversal on Combined_13 (PE=%.2f%%, IG=%.2f%%)', pe_c13, ce_c13));

end

function BS = build_5d_test_state()
P = Configure_Model_Params(struct('Profile_Name', 'NZ_Dunedin1972', 'dt', 5, 'n_z_pts', 5));
[P, ~]  = Compose_Policy_Bundle(P, struct(), 'baseline_2023');
mew_raw = [1.0, cumprod(P.sj(1:end-1))];
P.mewj  = mew_raw / sum(mew_raw);
P.PTypeWeights = [0.90 * P.Pop_Weights_4(:); 0.10 * P.Firm_Weights_4(:)];
P.h_par_mean   = 1.00;
Regions = P.Regions;
n_a1 = 15; n_h = 5; n_th = 3; n_z1 = 5;
a_vec  = (linspace(0, 1, n_a1)'.^2.2) * 18.0;
h_vec  = linspace(0.45, 1.80, n_h)';
th_vec = linspace(0.55, 1.65, n_th)';
d_vec  = [0; 0.5; 0.8; 1.0; 0; 0.08; 0.20; 0; 0.0203; 0.0706; 0.18];

n_d = struct(); n_a = struct(); n_z = struct(); N_j = struct();
d_grid = struct(); a_grid = struct(); z_grid = struct(); pi_z = struct();
ReturnFn = struct(); DiscountFactorParamNames = struct();
jequaloneDist = struct(); vfoptions = struct(); simoptions = struct();

[z_g, pi_g] = discretizeAR1_Rouwenhorst(0.0, P.rho_z, 0.18, n_z1);
z_g = exp(z_g);

hh5dFn = @(l, Ih, ic, aprime, hprime, a, h, theta_c, z, ...
    w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
    Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
    omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
    gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
    Q_reg_base, K_whanau) ...
    ReturnFn_SpatialHH(l, Ih, ic, aprime, hprime, a, h, theta_c, z, ...
    w_reg, r, Q_reg, G_reg, phi_nd, mu_maint, upsilon_h, chi_bar, ebar_energy, ...
    Transfer_Geo, p_super, c_floor, G_ece_stage1, G_ece_stage2, gbar_ece, s_sub, ...
    omega_ic, gamma1_self, gamma1_inv, gamma1_par, phi1_ces, ...
    gamma2_self, gamma2_inv, gamma2_par, phi2_ces, ...
    delta_hc, alpha_I, alpha_H, b1_beq, b2_beq, YouthGrant, ...
    tau_l, tau_c, tau_k, tau_a, tau_b, agej, Jr, sj, dt, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
    Q_reg_base, K_whanau);

apFn = @(i_c, thetac, agej, phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
    phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, gbar_ece, h_par_mean, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
    Q_reg, Q_reg_base, K_whanau, Jr, dt) ...
    HumanCapital_Lifecycle_aprimeFn(i_c, thetac, agej, phi1_ces, gamma1_self, gamma1_inv, gamma1_par, G_ece_stage1, ...
    phi2_ces, gamma2_self, gamma2_inv, gamma2_par, G_ece_stage2, gbar_ece, h_par_mean, ...
    j_s1_start, j_s1_end, j_s2_start, j_s2_end, n_stage1_steps, n_stage2_steps, ...
    Q_reg, Q_reg_base, K_whanau, Jr, dt);

for r = 1:numel(Regions)
    ht = ['HH_', Regions{r}];
    ft = ['Firm_', Regions{r}];

    n_d.(ht) = [4, 3, 4];
    n_a.(ht) = [n_a1, n_h, n_th];
    n_z.(ht) = n_z1;
    N_j.(ht) = P.J;
    d_grid.(ht) = d_vec;
    a_grid.(ht) = [a_vec; h_vec; th_vec];
    z_grid.(ht) = z_g;
    pi_z.(ht)   = pi_g;
    ReturnFn.(ht) = hh5dFn;
    DiscountFactorParamNames.(ht) = {'beta_hh', 'sj'};
    vfoptions.experienceasset.(ht)  = 1;
    vfoptions.aprimeFn.(ht)         = apFn;
    simoptions.experienceasset.(ht) = 1;
    simoptions.aprimeFn.(ht)        = apFn;

    jd = zeros(n_a1, n_h, n_th, n_z1);
    jd(1:3, 2:3, 2, :) = 1.0;
    jequaloneDist.(ht) = jd / sum(jd(:));

    n_d.(ft) = 0;
    n_a.(ft) = 15;
    n_z.(ft) = 2;
    N_j.(ft) = Inf;
    d_grid.(ft) = [];
    a_grid.(ft) = linspace(0.1, 10.0, 15)';
    z_grid.(ft) = P.z_f_grid.(ft)(:);
    if isfield(P, 'pi_z_f')
        pi_z.(ft) = P.pi_z_f;
    else
        pi_z.(ft) = [0.88, 0.12; 0.08, 0.92];
    end
    ReturnFn.(ft) = @(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt) ...
        ReturnFn_Firm(aprime, a, z, w_reg, r, alpha_k, lambda_col, delta_k, tau_k, tau_a, dt);
    DiscountFactorParamNames.(ft) = {'beta_firm'};
    vfoptions.experienceasset.(ft)  = 0;
    simoptions.experienceasset.(ft) = 0;
end
vfoptions.verbose = 0; vfoptions.vectorized = 1;
simoptions.verbose = 0; simoptions.d_grid = d_grid; simoptions.a_grid = a_grid;

BS = struct('Params', P, 'Regions', {Regions}, 'n_d', n_d, 'n_a', n_a, 'n_z', n_z, 'N_j', N_j, ...
    'd_grid', d_grid, 'a_grid', a_grid, 'z_grid', z_grid, 'pi_z', pi_z, ...
    'ReturnFn', ReturnFn, 'DiscountFactorParamNames', {DiscountFactorParamNames}, ...
    'jequaloneDist', jequaloneDist, 'vfoptions', vfoptions, 'simoptions', simoptions);
end

function check(cond, msg)
if ~cond
    error('IGW:TestFailure', 'test_wave5_policy_composition: %s', msg);
end
end
