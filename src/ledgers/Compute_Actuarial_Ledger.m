function Out = Compute_Actuarial_Ledger(Out_Cash, Params, Opts)
%% PURE ACC-STYLE / TREASURY CBAX CONTINUATION VALUATION LEDGER
% File: src/ledgers/Compute_Actuarial_Ledger.m
% Computes 4-Region + National Cash vs. Actuarial Continuation Valuations (V_{t0})
% under NZ Treasury Circular 2024/15 dual discount rates (2.0% Central SRTP and
% 8.0% Hurdle Sensitivity, net of 30% causal attribution haircut).
%
% Pure function: zero figure creation, zero file exports, zero workspace mutation.
% Supports arbitrary positive or negative cash/fiscal impulse streams so parallel
% counterfactuals (investments, retrenchments, or asset sales) share one ledger rule.

if nargin < 1, Out_Cash = [];       end
if nargin < 2 || isempty(Params), Params = struct(); end
if nargin < 3 || isempty(Opts),   Opts   = struct(); end

if isfield(Params, 'DataSpec') && isstruct(Params.DataSpec)
    DataSpec = Load_Empirical_Profile(Params.DataSpec.Profile_ID);
elseif isfield(Params, 'Profile_Name') && ~isempty(Params.Profile_Name)
    DataSpec = Load_Empirical_Profile(Params.Profile_Name);
else
    anch_in  = get_param_or_default(Params, 'Calibration_Anchor', 'NZ_Dunedin1972');
    DataSpec = Load_Empirical_Profile(anch_in);
end

regions = DataSpec.Regions;
N_reg   = DataSpec.N_reg;

% 1. Ensure national & regional cash flows exist (DataSpec fallback when Out_Cash omitted)
Calibration_Anchor = DataSpec.Legacy_Alias;
if isempty(Out_Cash) || ~isfield(Out_Cash, 'years')
    Out_Cash = build_default_4region_cash_flows(regions, DataSpec);
elseif ~isfield(Out_Cash, 'Reg')
    Out_Cash = split_national_into_4regions(Out_Cash, regions, DataSpec);
end

Out = struct();
Out.Profile_ID         = DataSpec.Profile_ID;
Out.Calibration_Anchor = Calibration_Anchor;
Out.Currency_ISO       = DataSpec.Monetary.Currency_ISO;
Out.Currency_Symbol    = DataSpec.Monetary.Currency_Symbol;
Out.Currency_Base_Year = DataSpec.Monetary.Base_Year;
Out.Currency_Unit      = DataSpec.Monetary.Currency_Unit_Billions;
Out.Pop_Shares         = DataSpec.Pop_Shares;

years = Out_Cash.years;

% 2. Treasury Circular 2024/15 & CBAx Continuation Parameters (from DataSpec, overridable via Params)
Act_Spec  = DataSpec.Actuarial;
H_window  = get_param_or_default(Params, 'H_window',  Act_Spec.H_Window_Yrs);
alpha_att = get_param_or_default(Params, 'alpha_att', Act_Spec.Attribution_Haircut);
g_cost    = get_param_or_default(Params, 'g_cost',    Act_Spec.Real_Cost_Growth);
r_2pct    = get_param_or_default(Params, 'r_2pct',    Act_Spec.Discount_Central);
r_8pct    = get_param_or_default(Params, 'r_8pct',    Act_Spec.Discount_Sensitivity);
psi_vec   = DataSpec.Reg_Table.psi_persist(:)';

% 3. Compute Actuarial Continuation Valuation for each region & sum to exact National aggregate
for r = 1:N_reg
    reg = regions{r};
    Out.Reg.(reg) = compute_single_ledger(Out_Cash.Reg.(reg), years, H_window, alpha_att, ...
        g_cost, r_2pct, r_8pct, psi_vec(r));
end

Out.years            = years;
Out.Regions          = regions;
Out.Cum_Inv          = Out_Cash.Cum_Inv;
Out.Cum_Savings      = Out_Cash.Cum_Savings;
Out.Cum_TotFisc      = Out_Cash.Cum_TotFisc;
Out.Cum_dGDP         = Out_Cash.Cum_dGDP;
Out.Booked_Sav_2pct  = zeros(size(years));
Out.Booked_Sav_8pct  = zeros(size(years));
Out.Booked_Fisc_2pct = zeros(size(years));
Out.Booked_Fisc_8pct = zeros(size(years));
Out.Booked_GDP_2pct  = zeros(size(years));
Out.Booked_GDP_8pct  = zeros(size(years));

for r = 1:N_reg
    reg = regions{r};
    Out.Booked_Sav_2pct  = Out.Booked_Sav_2pct  + Out.Reg.(reg).Booked_Sav_2pct;
    Out.Booked_Sav_8pct  = Out.Booked_Sav_8pct  + Out.Reg.(reg).Booked_Sav_8pct;
    Out.Booked_Fisc_2pct = Out.Booked_Fisc_2pct + Out.Reg.(reg).Booked_Fisc_2pct;
    Out.Booked_Fisc_8pct = Out.Booked_Fisc_8pct + Out.Reg.(reg).Booked_Fisc_8pct;
    Out.Booked_GDP_2pct  = Out.Booked_GDP_2pct  + Out.Reg.(reg).Booked_GDP_2pct;
    Out.Booked_GDP_8pct  = Out.Booked_GDP_8pct  + Out.Reg.(reg).Booked_GDP_8pct;
end

% Build structured Year-5 Parliamentary Audit Table alongside optional console print
idx_y5 = find(years == 5, 1);
if isempty(idx_y5), idx_y5 = min(2, numel(years)); end
Row_Labels = [regions(:); {'National'}];
Y5_Mat     = zeros(N_reg + 1, 6);
for r = 1:N_reg
    L = Out.Reg.(regions{r});
    Y5_Mat(r, :) = [L.Cum_Inv(idx_y5), L.Cum_TotFisc(idx_y5), L.Booked_Sav_2pct(idx_y5), ...
        L.Booked_Fisc_2pct(idx_y5), L.Booked_Fisc_8pct(idx_y5), L.Booked_GDP_2pct(idx_y5)];
end
Y5_Mat(N_reg + 1, :) = [Out.Cum_Inv(idx_y5), Out.Cum_TotFisc(idx_y5), Out.Booked_Sav_2pct(idx_y5), ...
    Out.Booked_Fisc_2pct(idx_y5), Out.Booked_Fisc_8pct(idx_y5), Out.Booked_GDP_2pct(idx_y5)];

Out.AuditYear  = years(idx_y5);
Out.Year5Table = table(Row_Labels, Y5_Mat(:,1), Y5_Mat(:,2), Y5_Mat(:,3), Y5_Mat(:,4), Y5_Mat(:,5), Y5_Mat(:,6), ...
    'VariableNames', {'Region', 'Cum_Outlay_B', 'Cash_Fisc_B', 'Booked_Sav_2pct_B', ...
    'Booked_Fisc_2pct_B', 'Booked_Fisc_8pct_B', 'Booked_GDP_2pct_B'});

if isfield(Opts, 'Verbose') && logical(Opts.Verbose)
    print_regional_audit_summary(Out, regions);
end

end

function L = compute_single_ledger(CashStruct, years, H_window, alpha_att, g_cost, r_2pct, r_8pct, psi_ann)
L = CashStruct;
L.years = years;

dt_step  = years(2) - years(1);
n_ext    = ceil(40 / dt_step);
yr_ext   = [years, years(end) + (1:n_ext)*dt_step];
ann_sav  = [CashStruct.Annual_Savings, repmat(CashStruct.Annual_Savings(end), 1, n_ext)];
ann_fisc = [CashStruct.Annual_TotFisc, repmat(CashStruct.Annual_TotFisc(end), 1, n_ext)];
ann_gdp  = [CashStruct.Annual_dGDP,    repmat(CashStruct.Annual_dGDP(end),    1, n_ext)];

yr_fine   = 0:1:max(yr_ext);
sav_fine  = interp1(yr_ext, ann_sav,  yr_fine, 'pchip');
fisc_fine = interp1(yr_ext, ann_fisc, yr_fine, 'pchip');
gdp_fine  = interp1(yr_ext, ann_gdp,  yr_fine, 'pchip');

s_vec       = 1:H_window;
psi_persist = psi_ann .^ s_vec;
D_2pct      = ((1 + g_cost) ./ (1 + r_2pct)) .^ s_vec;
D_8pct      = ((1 + g_cost) ./ (1 + r_8pct)) .^ s_vec;

N_pts = length(years);
L.Booked_Sav_2pct  = zeros(1, N_pts);
L.Booked_Sav_8pct  = zeros(1, N_pts);
L.Booked_Fisc_2pct = zeros(1, N_pts);
L.Booked_Fisc_8pct = zeros(1, N_pts);
L.Booked_GDP_2pct  = zeros(1, N_pts);
L.Booked_GDP_8pct  = zeros(1, N_pts);

for i = 2:N_pts
    y = years(i);
    idx_fwd = (y + 2) : (y + 1 + H_window);
    pipeline_maturity = min(1.0, y / 15.0);
    L.Booked_Sav_2pct(i)  = CashStruct.Cum_Savings(i) + (1 - alpha_att) * sum(D_2pct .* psi_persist .* sav_fine(idx_fwd)  * pipeline_maturity);
    L.Booked_Sav_8pct(i)  = CashStruct.Cum_Savings(i) + (1 - alpha_att) * sum(D_8pct .* psi_persist .* sav_fine(idx_fwd)  * pipeline_maturity);
    L.Booked_Fisc_2pct(i) = CashStruct.Cum_TotFisc(i) + (1 - alpha_att) * sum(D_2pct .* psi_persist .* fisc_fine(idx_fwd) * pipeline_maturity);
    L.Booked_Fisc_8pct(i) = CashStruct.Cum_TotFisc(i) + (1 - alpha_att) * sum(D_8pct .* psi_persist .* fisc_fine(idx_fwd) * pipeline_maturity);
    L.Booked_GDP_2pct(i)  = CashStruct.Cum_dGDP(i)    + (1 - alpha_att) * sum(D_2pct .* psi_persist .* gdp_fine(idx_fwd)  * pipeline_maturity);
    L.Booked_GDP_8pct(i)  = CashStruct.Cum_dGDP(i)    + (1 - alpha_att) * sum(D_8pct .* psi_persist .* gdp_fine(idx_fwd)  * pipeline_maturity);
end
end

function Out_Cash = build_default_4region_cash_flows(regions, DataSpec)
years     = 0:5:60;
sav_mult  = DataSpec.Actuarial.Sav_Multiplier;
gdp_mult  = DataSpec.Actuarial.GDP_Wave_Multiplier;
gdp_scale = 1.0;
if ~strncmpi(DataSpec.Profile_ID, 'NZ_', 3)
    gdp_scale = DataSpec.Monetary.GDP_Base_Billions / 430.0;
end

annual_inv = zeros(size(years));
annual_inv(2:end) = gdp_scale * (3.6 + 0.3 * (1 - exp(-0.06 * years(2:end))));

annual_sav = zeros(size(years));
annual_gdp = zeros(size(years));
for idx = 2:length(years)
    y = years(idx);
    if y < 20
        annual_sav(idx) = gdp_scale * sav_mult * 0.9 * (y / 20.0);
    else
        annual_sav(idx) = gdp_scale * sav_mult * (0.9 + 6.8 * (1 - exp(-0.08 * (y - 15))));
    end
    eng_A = gdp_scale * 14.5 * (1 - exp(-0.11 * y));
    eng_B = gdp_scale * gdp_mult * (y >= 15) * (28.0 / (1 + exp(-0.14 * (y - 32))));
    annual_gdp(idx) = eng_A + eng_B;
end

Out_Cash.years          = years;
Out_Cash.Annual_Inv     = annual_inv;
Out_Cash.Annual_Savings = annual_sav;
Out_Cash.Annual_dGDP    = annual_gdp;
Out_Cash.Annual_dTax    = 0.288 * annual_gdp;
Out_Cash.Annual_TotFisc = annual_sav + Out_Cash.Annual_dTax;
Out_Cash.Cum_Inv        = cumtrapz(years, Out_Cash.Annual_Inv);
Out_Cash.Cum_Savings    = cumtrapz(years, Out_Cash.Annual_Savings);
Out_Cash.Cum_dGDP       = cumtrapz(years, Out_Cash.Annual_dGDP);
Out_Cash.Cum_TotFisc    = Out_Cash.Cum_Savings + cumtrapz(years, Out_Cash.Annual_dTax);

Out_Cash = split_national_into_4regions(Out_Cash, regions, DataSpec);
end

function Out_Cash = split_national_into_4regions(Out_Cash, regions, DataSpec)
years = Out_Cash.years;
w_inv = DataSpec.Reg_Table.act_w_inv(:)';
w_sav = DataSpec.Reg_Table.act_w_sav(:)';
w_gdp = DataSpec.Reg_Table.act_w_gdp(:)';

for r = 1:length(regions)
    reg = regions{r};
    Out_Cash.Reg.(reg).Annual_Inv     = w_inv(r) * Out_Cash.Annual_Inv;
    Out_Cash.Reg.(reg).Annual_Savings = w_sav(r) * Out_Cash.Annual_Savings;
    Out_Cash.Reg.(reg).Annual_dGDP    = w_gdp(r) * Out_Cash.Annual_dGDP;
    Out_Cash.Reg.(reg).Annual_dTax    = 0.288    * Out_Cash.Reg.(reg).Annual_dGDP;
    Out_Cash.Reg.(reg).Annual_TotFisc = Out_Cash.Reg.(reg).Annual_Savings + Out_Cash.Reg.(reg).Annual_dTax;

    Out_Cash.Reg.(reg).Cum_Inv        = cumtrapz(years, Out_Cash.Reg.(reg).Annual_Inv);
    Out_Cash.Reg.(reg).Cum_Savings    = cumtrapz(years, Out_Cash.Reg.(reg).Annual_Savings);
    Out_Cash.Reg.(reg).Cum_dGDP       = cumtrapz(years, Out_Cash.Reg.(reg).Annual_dGDP);
    Out_Cash.Reg.(reg).Cum_TotFisc    = Out_Cash.Reg.(reg).Cum_Savings + cumtrapz(years, Out_Cash.Reg.(reg).Annual_dTax);
end
end

function print_regional_audit_summary(Out, regions)
idx_y5 = find(Out.years == 5, 1);
if isempty(idx_y5), idx_y5 = 2; end

fprintf('\n========================================================================================================\n');
fprintf(' YEAR %d PARLIAMENTARY AUDIT: 4-REGION ACTUARIAL CONTINUATION VALUATION (%s BILLIONS, REAL %d%s)\n', ...
    Out.years(idx_y5), Out.Currency_ISO, Out.Currency_Base_Year, Out.Currency_Symbol);
fprintf('========================================================================================================\n');
fprintf('%-10s | %8s | %9s | %15s | %17s | %17s | %15s\n', ...
    'Region', 'Outlay', 'Cash Fisc', 'Booked Sav (2%)', 'Booked Fisc (2%)', 'Booked Fisc (8%)', 'Booked GDP (2%)');
fprintf('--------------------------------------------------------------------------------------------------------\n');
for r = 1:length(regions)
    reg = regions{r};
    L   = Out.Reg.(reg);
    fprintf('%-10s | %8.2f | %9.2f | %15.2f | %17.2f | %17.2f | %15.2f\n', ...
        reg, L.Cum_Inv(idx_y5), L.Cum_TotFisc(idx_y5), L.Booked_Sav_2pct(idx_y5), ...
        L.Booked_Fisc_2pct(idx_y5), L.Booked_Fisc_8pct(idx_y5), L.Booked_GDP_2pct(idx_y5));
end
fprintf('--------------------------------------------------------------------------------------------------------\n');
fprintf('%-10s | %8.2f | %9.2f | %15.2f | %17.2f | %17.2f | %15.2f\n', ...
    'National', Out.Cum_Inv(idx_y5), Out.Cum_TotFisc(idx_y5), Out.Booked_Sav_2pct(idx_y5), ...
    Out.Booked_Fisc_2pct(idx_y5), Out.Booked_Fisc_8pct(idx_y5), Out.Booked_GDP_2pct(idx_y5));
fprintf('========================================================================================================\n\n');
end

function val = get_param_or_default(S, fname, default_val)
if isstruct(S) && isfield(S, fname) && ~isempty(S.(fname))
    val = S.(fname);
else
    val = default_val;
end
end
