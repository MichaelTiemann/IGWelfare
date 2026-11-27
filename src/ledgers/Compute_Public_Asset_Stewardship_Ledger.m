function Out = Compute_Public_Asset_Stewardship_Ledger(Params, Opts)
%% PURE PUBLIC-ASSET PRIVATIZATION VS. STEWARDSHIP TURNAROUND VALUATION LEDGER
% File: src/ledgers/Compute_Public_Asset_Stewardship_Ledger.m
% Evaluates a poorly managed public network/grid asset block (NZD 50.0B book value
% across Three Waters / Gentailer / Rail-Ferry trunks) over a 35-year horizon at
% NZ Treasury Circular 2024/15 discount rates (2.0% SRTP and 8.0% hurdle):
%   1. Mismanaged_Deferred_Maint     : Low public TFP (-14%) + "Tooth Cavity" deferred maintenance
%   2. Distressed_Privatization_Sale : Books +NZD 34.8B Crown Cash in Yrs 0-3 (-28% fire-sale discount),
%                                      while inflicting off-budget private monopoly markups (+24%) & losing buyback option
%   3. RingFenced_Maint_Only         : Halts convex decay without governance/board turnaround
%   4. Public_Stewardship_Turnaround : Ostrom user co-governance + independent commercial-engineering board (+18% lift)

if nargin < 1 || isempty(Params) || ~isfield(Params, 'Profile_ID')
    Params = Configure_Model_Params(struct('dt', 3));
end
if nargin < 2 || isempty(Opts), Opts = struct(); end
verbose_flag = isfield(Opts, 'Verbose') && logical(Opts.Verbose);

SecSpec = Load_Sectoral_Exergy_Spec(Params.Profile_ID);
AS      = SecSpec.AssetStewardship;

gdp_scale   = 1.0;
curr_iso    = 'NZD';
if isfield(Params, 'GDP_Base_Billions') && ~strncmpi(Params.Profile_ID, 'NZ_', 3)
    gdp_scale = Params.GDP_Base_Billions / 430.0;
    curr_iso  = Params.Currency_ISO;
end
K_Book_BNZD = 50.0 * gdp_scale;
t_col       = (0:1:35)';
disc_2      = 1.020 .^ (-t_col);
disc_8      = 1.080 .^ (-t_col);

% 1. Mismanaged Status Quo + Deferred Maintenance ("Tooth Cavity" convex escalation):
sq_crown_t  = gdp_scale * (0.65 * (t_col >= 1 & t_col <= 3) - 0.048 * (max(0.0, t_col - 3.0) .^ AS.Deferred_Maint_Cavity_Convexity));
sq_soc_t    = sq_crown_t - (0.45 * AS.Public_Mismanagement_TFP_Drag * K_Book_BNZD) * (t_col >= 1);

% 2. Irreversible Distressed Privatization (u_17 = -1):
sale_cash_0    = K_Book_BNZD * (1.0 - AS.Privatization_FireSale_Discount); % +NZD 36.0B upfront
debt_int_saved = 0.042 * sale_cash_0 * (t_col >= 1);                       % +NZD 1.51B/yr saved bond interest
lost_pub_div   = -0.037 * K_Book_BNZD * (1.015 .^ t_col) .* (t_col >= 1);  % -NZD 1.85B/yr foregone public dividend
monopoly_drag  = -(0.24 * AS.Privatized_Monopoly_Markup_Add * K_Book_BNZD) * (1.018 .^ t_col) .* (t_col >= 1); % Off-Crown HH/exporter markup!

priv_crown_t   = [sale_cash_0; zeros(numel(t_col)-1, 1)] + debt_int_saved + lost_pub_div;
priv_soc_t     = priv_crown_t + monopoly_drag;

Buyback_Cost_Yr10_BNZD = K_Book_BNZD * (1.018 ^ 10) * (1.0 + AS.Recompra_Irreversibility_Premium);

% 3. Ring-Fenced Preventative Maintenance Only:
maint_crown_t = -0.75 * gdp_scale * (t_col >= 1 & t_col <= 4);
maint_soc_t   = maint_crown_t + 0.018 * K_Book_BNZD * (1.0 - exp(-t_col / 6.0)) .* (t_col >= 1);

% 4. Public Stewardship Turnaround (u_17 = +1: Ostrom + Commercial-Stewardship Board):
turn_crown_t  = -0.95 * gdp_scale * (t_col >= 1 & t_col <= 4) + 0.012 * K_Book_BNZD * (1.0 - exp(-t_col / 6.0)) .* (t_col >= 2);
turn_soc_t    = -0.95 * gdp_scale * (t_col >= 1 & t_col <= 4) ...
              + (0.42 * AS.Stewardship_Reform_TFP_Lift * K_Book_BNZD) * (1.0 - exp(-t_col / 5.5)) .* (1.012 .^ t_col) .* (t_col >= 1);

Crown_Tx4 = [sq_crown_t, priv_crown_t, maint_crown_t, turn_crown_t];
Soc_Tx4   = [sq_soc_t,   priv_soc_t,   maint_soc_t,   turn_soc_t];

Crown_Yr0to3_4x1 = sum(Crown_Tx4(t_col <= 3, :), 1)';
NPV_2pct_4x1     = Soc_Tx4' * disc_2;
NPV_8pct_4x1     = Soc_Tx4' * disc_8;

OppLoss_2pct_BNZD = NPV_2pct_4x1(4) - NPV_2pct_4x1(2);
OppLoss_8pct_BNZD = NPV_8pct_4x1(4) - NPV_8pct_4x1(2);

Strategy_Names = { ...
    '1_Mismanaged_Deferred_Maint'; ...
    '2_Distressed_Privatization_Sale'; ...
    '3_RingFenced_Maint_Only'; ...
    '4_Public_Stewardship_Turnaround'};

SummaryTable = table(Strategy_Names, round(Crown_Yr0to3_4x1, 2), round(NPV_2pct_4x1, 2), round(NPV_8pct_4x1, 2), ...
    'VariableNames', {'Asset_Strategy', 'Crown_Cash_Yr0to3_BNZD', 'Net_Societal_PV_2pct_BNZD', 'Net_Societal_PV_8pct_BNZD'});

Out = struct();
Out.Years                   = 2026 + t_col;
Out.Currency_ISO            = curr_iso;
Out.Asset_Book_Value_BCurr  = K_Book_BNZD;
Out.Asset_Book_Value_BNZD   = K_Book_BNZD;
Out.FireSale_Proceeds_BCurr = sale_cash_0;
Out.FireSale_Proceeds_BNZD  = sale_cash_0;
Out.Buyback_Cost_Yr10_BCurr = Buyback_Cost_Yr10_BNZD;
Out.Buyback_Cost_Yr10_BNZD  = Buyback_Cost_Yr10_BNZD;
Out.Opportunity_Loss_2pct_B = OppLoss_2pct_BNZD;
Out.Opportunity_Loss_8pct_B = OppLoss_8pct_BNZD;
Out.Crown_Flows_BNZD_Tx4    = Crown_Tx4;
Out.Societal_Flows_BNZD_Tx4 = Soc_Tx4;
Out.Cum_Societal_BNZD_Tx4   = cumtrapz(t_col, Soc_Tx4, 1);
Out.SummaryTable            = SummaryTable;

if verbose_flag
    disp(SummaryTable);
    fprintf('  -> Irreversible Privatization Opportunity Loss vs. Turnaround: -%s %.2fB (2%% SRTP) | -%s %.2fB (8%% Hurdle) | Yr-10 Buyback Cost: %s %.2fB\n', ...
        curr_iso, OppLoss_2pct_BNZD, curr_iso, OppLoss_8pct_BNZD, curr_iso, Buyback_Cost_Yr10_BNZD);
end
end
