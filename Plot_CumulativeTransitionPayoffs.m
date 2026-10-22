function Out = Plot_CumulativeTransitionPayoffs(StationaryDist_SS0, StationaryDist_t, Policy_t, PricePath, Params, Grids)
% PLOT_CUMULATIVETRANSITIONPAYOFFS
% Integrates Cumulative Public Investment, Direct Cost Savings, Total Fiscal Return,
% and Cumulative GDP Growth across the 60-year transition path for all 4 regions
% ('Rural', 'Small', 'Large', 'Auckland') and the National aggregate.

T_trans = length(StationaryDist_t);
if isfield(Params, 'dt')
    dt = Params.dt;
else
    dt = 5;
end
years = (0:T_trans) * dt;

if isfield(Params, 'Regions')
    regions = Params.Regions; % {'Rural', 'Small', 'Large', 'Auckland'}
else
    regions = {'Rural', 'Small', 'Large', 'Auckland'};
end
N_reg = length(regions);

% Initialize National arrays
Annual_Inv     = zeros(1, T_trans + 1);
Annual_Savings = zeros(1, T_trans + 1);
Annual_dGDP    = zeros(1, T_trans + 1);
Annual_dTax    = zeros(1, T_trans + 1);

% Initialize Regional arrays inside Out.Reg.(reg)
for r = 1:N_reg
    reg = regions{r};
    Out.Reg.(reg).Annual_Inv     = zeros(1, T_trans + 1);
    Out.Reg.(reg).Annual_Savings = zeros(1, T_trans + 1);
    Out.Reg.(reg).Annual_dGDP    = zeros(1, T_trans + 1);
    Out.Reg.(reg).Annual_dTax    = zeros(1, T_trans + 1);
end

% Period-by-period regional and national integration
for t = 1:T_trans
    inv_nat = 0; sav_nat = 0; dgdp_nat = 0; dtax_nat = 0;

    for r = 1:N_reg
        reg = regions{r};
        hh_type = ['HH_', reg];

        % Support either HH_Region or Region struct field naming
        if isfield(StationaryDist_t{t}, hh_type)
            mu_t = StationaryDist_t{t}.(hh_type);
            pol  = Policy_t{t}.(hh_type);
        else
            mu_t = StationaryDist_t{t}.(reg);
            pol  = Policy_t{t}.(reg);
        end

        % Dynamic regional population weight s_{HH,k,t}
        if isfield(PricePath, 'PTypeWeights_path')
            w_pop_k = PricePath.PTypeWeights_path(r, t) / sum(PricePath.PTypeWeights_path(1:N_reg, t));
        else
            default_w = [0.160, 0.240, 0.259, 0.341];
            w_pop_k = default_w(r);
        end

        % 1. Regional Public Investment Outlay (\Delta G_ECE + s_sub*i_c + YouthGrant E + \Delta T_k)
        mass_parents = sum(mu_t(:, :, :, 3:4), 'all');
        ic_subsidy   = sum(Params.s_sub .* pol.ic(:, :, :, 3:4) .* mu_t(:, :, :, 3:4), 'all');
        mass_j1      = sum(mu_t(:, :, :, 1), 'all');

        inv_reg = Params.NZD_Scale * w_pop_k * ...
            (Params.dG_ECE.(reg) * mass_parents + ic_subsidy + Params.YouthGrant_E * mass_j1);

        % 2. Regional Direct Cost Savings (Dunedin h1-h2 acute reduction + transfer savings)
        mass_stunted_adult = sum(mu_t(:, 1:2, :, 1:9), 'all');
        transfer_outlay    = sum(pol.Transfers .* mu_t, 'all');
        acute_reg_t        = Params.NZD_Scale * w_pop_k * ...
            (Params.c_acute_dunedin * mass_stunted_adult + transfer_outlay);
        acute_reg_SS0      = Params.AcuteBurden_Reg_SS0.(reg);
        sav_reg            = max(0, acute_reg_SS0 - acute_reg_t);

        % 3. Regional Macroeconomic Output Gain (\Delta Y_{k,t})
        gdp_reg_t   = PricePath.Y_reg.(reg)(t) * Params.NZD_Scale;
        gdp_reg_SS0 = Params.Y_Reg_SS0.(reg);
        dgdp_reg    = max(0, gdp_reg_t - gdp_reg_SS0);

        % 4. Regional Endogenous Tax Base Expansion (\Delta Tax_{k,t})
        tax_reg_t   = PricePath.TaxRev_reg.(reg)(t) * Params.NZD_Scale;
        tax_reg_SS0 = Params.TaxRev_Reg_SS0.(reg);
        dtax_reg    = max(0, tax_reg_t - tax_reg_SS0);

        % Store regional flows at step t+1
        Out.Reg.(reg).Annual_Inv(t+1)     = inv_reg;
        Out.Reg.(reg).Annual_Savings(t+1) = sav_reg;
        Out.Reg.(reg).Annual_dGDP(t+1)    = dgdp_reg;
        Out.Reg.(reg).Annual_dTax(t+1)    = dtax_reg;

        % Accumulate to National
        inv_nat  = inv_nat  + inv_reg;
        sav_nat  = sav_nat  + sav_reg;
        dgdp_nat = dgdp_nat + dgdp_reg;
        dtax_nat = dtax_nat + dtax_reg;
    end

    Annual_Inv(t+1)     = inv_nat;
    Annual_Savings(t+1) = sav_nat;
    Annual_dGDP(t+1)    = dgdp_nat;
    Annual_dTax(t+1)    = dtax_nat;
end

% Trapezoidal Cumulative Integration for each Region
for r = 1:N_reg
    reg = regions{r};
    Out.Reg.(reg).Annual_TotFisc = Out.Reg.(reg).Annual_Savings + Out.Reg.(reg).Annual_dTax;
    Out.Reg.(reg).Cum_Inv        = cumtrapz(years, Out.Reg.(reg).Annual_Inv);
    Out.Reg.(reg).Cum_Savings    = cumtrapz(years, Out.Reg.(reg).Annual_Savings);
    Out.Reg.(reg).Cum_dGDP       = cumtrapz(years, Out.Reg.(reg).Annual_dGDP);
    Out.Reg.(reg).Cum_TotFisc    = Out.Reg.(reg).Cum_Savings + cumtrapz(years, Out.Reg.(reg).Annual_dTax);
end

% Trapezoidal Cumulative Integration for National Aggregate
Out.years          = years;
Out.Regions        = regions;
Out.Annual_Inv     = Annual_Inv;
Out.Annual_Savings = Annual_Savings;
Out.Annual_dGDP    = Annual_dGDP;
Out.Annual_dTax    = Annual_dTax;
Out.Annual_TotFisc = Annual_Savings + Annual_dTax;

Out.Cum_Inv        = cumtrapz(years, Annual_Inv);
Out.Cum_Savings    = cumtrapz(years, Annual_Savings);
Out.Cum_dGDP       = cumtrapz(years, Annual_dGDP);
Out.Cum_TotFisc    = Out.Cum_Savings + cumtrapz(years, Annual_dTax);
end
