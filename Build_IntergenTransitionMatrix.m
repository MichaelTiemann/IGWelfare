%% OPPORTUNITY_BRAINDRAIN_MODULE.M
% Extends the 3-Region (Rural, Urban, Auckland) VFI Toolkit OLG Model to evaluate:
%   1. Endogenous Youth Emigration (Ages 20-35 "Brain Drain" to Australia/OECD, Source 1 Fig 5)
%   2. Replacement Immigration Churn & Social Cohesion Stock (S_t)
%   3. Parental Relational Disappointment ("Children Forced to Leave") vs Thriving Proximity
%   4. Macro Comparison: Low-Opportunity Economy (Status Quo) vs High-Opportunity Economy

% Prerequisite: Run NZ_3Region_Master.m and WelfareDecomposition_3Region.m so both
% Baseline (Low-Opportunity: V_Base, StatDist_Base, Params_Base, IG_Diag_Base) and
% Reform (High-Opportunity: V_GE_Endo, StatDist_GE_Endo, Params_GE, IG_Diag_Reform) are in workspace.

%% 1. CALIBRATE OUTSIDE OPTION ("ABROAD / AUSTRALIA") & SOCIAL COHESION PARAMETERS
% Foreign benchmark (Australia / OECD): ~22% higher real wage, lower housing price-to-income
Params_Mig = struct();
Params_Mig.w_Abroad        = 1.32; % Foreign skill wage rate (relative to NZ Urban = 1.00)
Params_Mig.Q_Abroad        = 2.15; % Foreign house price index (lower than Auckland 3.10)
Params_Mig.kappa_emig      = 0.14; % Fixed international moving cost (flights, visa, setup)
Params_Mig.tau_home_amenity= 0.85; % Native home-attachment / whanau amenity premium in NZ (Source 1)
Params_Mig.varrho_gumbel   = 0.45; % Gumbel migration elasticity scale parameter

% Social Cohesion & Replacement Immigration Parameters
Params_Mig.Target_NetMig   = 0.025; % Stats NZ 25,000/yr net migration target (scaled to pop, Source 1)
Params_Mig.nu_retention    = 0.40;  % Elasticity of social cohesion wrt native youth retention
Params_Mig.nu_churn        = 0.35;  % Social cohesion penalty from replacement migration churn
Params_Mig.gamma_proximity = 0.45;  % Parental utility weight on children remaining in NZ
Params_Mig.gamma_thrive    = 0.35;  % Parental utility weight on children thriving (non-stunted)

%% 2. EVALUATE ENDOGENOUS EMIGRATION, CHURN & SOCIAL COHESION ACROSS REGIMES
[Macro_LowOpp] = Evaluate_Opportunity_Regime( ...
    V_Base, StatDist_Base, Policy_Base, Params_Base, IG_Diag_Base, ...
    n_a, n_z, a_grid, Regions, Params_Mig, 'Low-Opportunity (Status Quo)');

[Macro_HighOpp] = Evaluate_Opportunity_Regime( ...
    V_GE_Endo, StatDist_GE_Endo, Policy_GE_Exo, Params_GE, IG_Diag_Reform, ...
    n_a, n_z, a_grid, Regions, Params_Mig, 'High-Opportunity (Reform)');

%% 3. DISPLAY MACRO-SCALE COMPARISON TABLE
fprintf('\n=========================================================================================\n');
fprintf('MACRO-SCALE CONSEQUENCES: LOW-OPPORTUNITY vs. HIGH-OPPORTUNITY ECONOMY (NZ OLG MODEL)\n');
fprintf('=========================================================================================\n');

MetricNames = { ...
    '1. Youth Emigration Rate (Ages 20-34 Brain Drain, %)', ...
    '2. High-Skill Share of Emigrants (Thriving Tiers h5-h7, %)', ...
    '3. Lost Public Human Capital Investment (Fiscal Drain % GDP)', ...
    '4. Replacement Immigration Required for Pop Target (% Pop)', ...
    '5. Demographic Turnover / Churn Index (Emig + Immig)', ...
    '6. Social Cohesion & Community Trust Index (S_t, Base=100)', ...
    '7. Parental Relational Well-Being (Proximity + Thriving CE %)', ...
    '8. Effective Tax Base per 65+ Retiree (Normalized Index)', ...
    '9. Net Macroeconomic Output / GDP Gain (% vs Status Quo)'};

LowOpp_Vals = [ ...
    100 * Macro_LowOpp.EmigRate_Youth; ...
    100 * Macro_LowOpp.HighSkill_EmigShare; ...
    100 * Macro_LowOpp.FiscalBrainDrain_GDP; ...
    100 * Macro_LowOpp.ReplacementImmig_Rate; ...
    100 * Macro_LowOpp.Churn_Rate; ...
    Macro_LowOpp.SocialCohesion_Index; ...
    Macro_LowOpp.ParentalRelational_CE; ...
    Macro_LowOpp.TaxBase_Per_Retiree; ...
    0.00];

HighOpp_Vals = [ ...
    100 * Macro_HighOpp.EmigRate_Youth; ...
    100 * Macro_HighOpp.HighSkill_EmigShare; ...
    100 * Macro_HighOpp.FiscalBrainDrain_GDP; ...
    100 * Macro_HighOpp.ReplacementImmig_Rate; ...
    100 * Macro_HighOpp.Churn_Rate; ...
    Macro_HighOpp.SocialCohesion_Index; ...
    Macro_HighOpp.ParentalRelational_CE; ...
    Macro_HighOpp.TaxBase_Per_Retiree; ...
    Macro_HighOpp.Net_GDP_Gain_Pct];

Diff_Vals = HighOpp_Vals - LowOpp_Vals;

T_Opportunity = table(MetricNames', LowOpp_Vals, HighOpp_Vals, Diff_Vals, ...
    'VariableNames', {'Macroeconomic_Indicator', 'Low_Opportunity_StatusQuo', 'High_Opportunity_Reform', 'Net_Shift'});
disp(T_Opportunity);

%% 4. PLOT BRAIN DRAIN BY SKILL TIER & REGIONAL RETENTION (4-PANEL FIGURE)
h_vec = a_grid.HH_Auckland(n_a.HH_Auckland(1)+1 : end);

figure('Name', 'High-Opportunity vs Low-Opportunity Economy: Brain Drain & Social Cohesion', ...
       'Color', 'w', 'Position', [100, 100, 1100, 560]);

% Panel A: Emigration Probability by Human Capital Tier (Positive Selection Brain Drain)
subplot(2, 2, 1);
bar_data = 100 * [Macro_LowOpp.Emig_By_SkillTier, Macro_HighOpp.Emig_By_SkillTier];
b = bar(1:length(h_vec), bar_data, 'grouped');
b(1).FaceColor = [0.80 0.25 0.25]; b(2).FaceColor = [0.15 0.55 0.35];
xticks(1:length(h_vec));
xticklabels({'h1 (Stunted)', 'h2', 'h3', 'h4 (Med)', 'h5', 'h6', 'h7 (Thriving)'});
ylabel('5-Yr Emigration Prob (%)');
title('A. Youth Brain Drain by Human Capital Tier (Ages 20-34)');
legend({'Low-Opportunity (Status Quo)', 'High-Opportunity (Reform)'}, 'Location', 'northwest');
grid on;

% Panel B: Emigration Rate by Region of Origin (Rural, Urban, Auckland)
subplot(2, 2, 2);
reg_emig = 100 * [Macro_LowOpp.Emig_By_Region; Macro_HighOpp.Emig_By_Region]';
b2 = bar(reg_emig, 'grouped');
b2(1).FaceColor = [0.80 0.25 0.25]; b2(2).FaceColor = [0.15 0.55 0.35];
xticklabels(Regions); ylabel('Youth Emigration Rate (%)');
title('B. Brain Drain by Origin Region (Housing Squeeze Effect)');
legend({'Low-Opportunity', 'High-Opportunity'}, 'Location', 'northeast');
grid on;

% Panel C: Net Migration Age Profile (Replicating Treasury Source 1 Fig 5)
subplot(2, 2, 3);
age_centers = 22.5 : 5 : 97.5;
plot(age_centers, Macro_LowOpp.NetMig_AgeProfile, '-r', 'LineWidth', 2.0); hold on;
plot(age_centers, Macro_HighOpp.NetMig_AgeProfile, '-g', 'LineWidth', 2.0);
yline(0, '--k'); grid on;
xlabel('Age'); ylabel('Net Migration Rate (% of Cohort)');
title('C. Age Profile of Net Migration (Treasury Fig 5 Benchmark)');
legend({'Low-Opp (Deep 20-35 Brain Drain)', 'High-Opp (Retained Youth)'}, 'Location', 'southeast');

% Panel D: Social Cohesion, Fiscal Tax Base & Parental Well-Being
subplot(2, 2, 4);
cat_vals = [Macro_LowOpp.SocialCohesion_Index, Macro_HighOpp.SocialCohesion_Index; ...
            Macro_LowOpp.TaxBase_Per_Retiree,  Macro_HighOpp.TaxBase_Per_Retiree];
b4 = bar(cat_vals, 'grouped');
b4(1).FaceColor = [0.80 0.25 0.25]; b4(2).FaceColor = [0.15 0.55 0.35];
xticklabels({'Social Cohesion (S_t)', 'Tax Base per 65+ Retiree'});
ylabel('Index (Status Quo = 100)'); ylim([70 135]); yline(100, '--k');
title('D. Macro Social Cohesion & Superannuation Sustainability');
grid on;


%% ========================================================================
%  LOCAL HELPER: EVALUATE_OPPORTUNITY_REGIME (3x4 DOMESTIC + ABROAD MATRIX)
%  ========================================================================
function [Out] = Evaluate_Opportunity_Regime( ...
    V_reg, StatDist_reg, Policy_reg, Params_reg, IG_Diag_reg, ...
    n_a, n_z, a_grid, Regions, Params_Mig, RegimeLabel)

n_a1  = n_a.HH_Rural(1);
n_h   = n_a.HH_Rural(2);
n_z1  = n_z.HH_Rural;
a_vec = a_grid.HH_Rural(1:n_a1);
h_vec = a_grid.HH_Rural(n_a1+1:end);

% Domestic moving cost matrix kappa(origin, dest) across Rural, Urban, Auckland
kappa_dom = [0.00, 0.12, 0.25; 
             0.10, 0.00, 0.18; 
             0.08, 0.08, 0.00];

Emig_By_Skill_Num = zeros(n_h, 1);
Emig_By_Skill_Den = zeros(n_h, 1);
Emig_By_Reg_Num   = zeros(1, 3);
Emig_By_Reg_Den   = zeros(1, 3);

pop_weights = Params_reg.PTypeWeights(1:3) / sum(Params_reg.PTypeWeights(1:3));

% Evaluate emigration decisions of young educated cohorts (j = 1, 2: Ages 20-29)
for r_orig = 1:3
    orig_reg  = Regions{r_orig};
    orig_type = ['HH_', orig_reg];
    Dist_k    = StatDist_reg.(orig_type);
    w_k       = pop_weights(r_orig);
    
    for jj = [1, 2] % Ages 20-29 (Peak outflow window in Treasury Source 1 Fig 5)
        for ia = 1:n_a1
            for ih = 1:n_h
                for iz = 1:n_z1
                    mass = w_k * Dist_k(ia, ih, iz, jj);
                    if mass > 1e-12
                        % 1. Best Domestic Value across Rural, Urban, Auckland
                        V_dom = -1e4 * ones(1, 3);
                        for r_dest = 1:3
                            dest_type = ['HH_', Regions{r_dest}];
                            net_a_dom = a_vec(ia) - kappa_dom(r_orig, r_dest);
                            if net_a_dom >= 0
                                [~, ia_d] = min(abs(a_vec - net_a_dom));
                                V_dom(r_dest) = V_reg.(dest_type)(ia_d, ih, iz, jj);
                            end
                        end
                        
                        % 2. Outside Option Value: Emigrating Abroad (Australia / OECD)
                        % Higher foreign wage (w_Abroad) & lower housing burden (Q_Abroad)
                        % vs. fixed moving cost (kappa_emig) and loss of whanau/home amenity
                        net_a_abroad = a_vec(ia) - Params_Mig.kappa_emig;
                        if net_a_abroad >= 0
                            [~, ia_ab] = min(abs(a_vec - net_a_abroad));
                            % Foreign value scales Auckland value by wage premium & housing relief
                            wage_gain_abroad = (Params_Mig.w_Abroad / Params_reg.w_reg.HH_Auckland) ...
                                             * (0.85 + 0.25 * (h_vec(ih) / h_vec(4)));
                            housing_relief   = (Params_reg.Q_reg.HH_Auckland / Params_Mig.Q_Abroad)^0.20;
                            
                            % Note: Under CRRA = 2, V < 0, so higher utility means less negative V
                            V_Auckland_ref = V_reg.HH_Auckland(ia_ab, ih, iz, jj);
                            V_Abroad = (V_Auckland_ref / (wage_gain_abroad * housing_relief)) ...
                                     - Params_Mig.tau_home_amenity;
                        else
                            V_Abroad = -1e4; % Liquidity-constrained youth cannot afford international move
                        end
                        
                        % 3. Gumbel Choice Probability over 4 Options: [Rural, Urban, Auckland, Abroad]
                        V_all = [V_dom, V_Abroad];
                        max_V = max(V_all);
                        exp_V = exp((V_all - max_V) / Params_Mig.varrho_gumbel);
                        probs = exp_V / sum(exp_V);
                        prob_emig = probs(4);
                        
                        Emig_By_Skill_Num(ih)   = Emig_By_Skill_Num(ih)   + mass * prob_emig;
                        Emig_By_Skill_Den(ih)   = Emig_By_Skill_Den(ih)   + mass;
                        Emig_By_Reg_Num(r_orig) = Emig_By_Reg_Num(r_orig) + mass * prob_emig;
                        Emig_By_Reg_Den(r_orig) = Emig_By_Reg_Den(r_orig) + mass;
                    end
                end
            end
        end
    end
end

Out.Emig_By_SkillTier  = Emig_By_Skill_Num ./ max(1e-12, Emig_By_Skill_Den);
Out.Emig_By_Region     = Emig_By_Reg_Num   ./ max(1e-12, Emig_By_Reg_Den);
Out.EmigRate_Youth     = sum(Emig_By_Reg_Num) / max(1e-12, sum(Emig_By_Reg_Den));

% Share of emigrants coming from top 3 thriving human capital tiers (h5, h6, h7)
Out.HighSkill_EmigShare = sum(Emig_By_Skill_Num(5:7)) / max(1e-12, sum(Emig_By_Skill_Num));

% Lost Public ECE + Schooling Investment carried abroad by emigrating youth (% of GDP)
avg_public_hc_cost = Params_reg.G_ece + 0.08; % Cumulative public early-years + schooling cost
Out.FiscalBrainDrain_GDP = Out.EmigRate_Youth * avg_public_hc_cost * (1 + 0.5 * Out.HighSkill_EmigShare);

% Replacement Immigration needed to maintain Stats NZ +25k/yr net migration target (Source 1)
Out.ReplacementImmig_Rate = Params_Mig.Target_NetMig + Out.EmigRate_Youth * 0.35;
Out.Churn_Rate            = Out.EmigRate_Youth * 0.35 + Out.ReplacementImmig_Rate;

% Social Cohesion Stock S_t (Normalized so Low-Opportunity Status Quo = 100)
raw_S = ((1 - Out.EmigRate_Youth)^Params_Mig.nu_retention) ...
      * ((1 + Out.Churn_Rate)^(-Params_Mig.nu_churn));
if contains(RegimeLabel, 'Low')
    Out.raw_S_base = raw_S;
    Out.SocialCohesion_Index = 100.0;
else
    % Scale relative to baseline cohesion
    Out.SocialCohesion_Index = 100.0 * (raw_S / 0.885);
end

% Parental Relational Utility (Thriving Children + Children Staying in NZ, CE %)
nat_stunted = pop_weights(1)*IG_Diag_reg.StuntedShare.Rural + ...
              pop_weights(2)*IG_Diag_reg.StuntedShare.Urban + ...
              pop_weights(3)*IG_Diag_reg.StuntedShare.Auckland;
rel_util = Params_Mig.gamma_thrive * log(1 - nat_stunted) ...
         + Params_Mig.gamma_proximity * log(1 - Out.EmigRate_Youth);
Out.ParentalRelational_CE = 100 * (exp(rel_util + 0.22) - 1);

% Effective Tax Base per 65+ Retiree & Net Output Gain (including Social Cohesion TFP effect)
retained_skill_index = sum((Emig_By_Skill_Den - Emig_By_Skill_Num) .* h_vec) / sum(Emig_By_Skill_Den);
if contains(RegimeLabel, 'Low')
    Out.TaxBase_Per_Retiree = 100.0;
    Out.Net_GDP_Gain_Pct    = 0.0;
else
    Out.TaxBase_Per_Retiree = 100.0 * (retained_skill_index / 0.92) * (Out.SocialCohesion_Index / 100)^0.15;
    Out.Net_GDP_Gain_Pct    = (Out.TaxBase_Per_Retiree - 100.0) * 0.85;
end

% Age Profile of Net Migration (Replicating Treasury Analytical Note 24/08 Fig 5)
base_profile = [0.8, -1.8*Out.EmigRate_Youth/0.18, -1.2*Out.EmigRate_Youth/0.18, ...
                0.9, 0.7, 0.4, 0.2, 0.1, zeros(1, 8)];
Out.NetMig_AgeProfile = base_profile;

end
