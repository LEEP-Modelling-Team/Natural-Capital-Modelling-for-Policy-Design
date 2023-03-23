clear

payment_mechanism = 'fr_act_pctl_rnd';
unscaled_budget   = 1e9;
urban_pct_limit   = 0.5;
bio_constraint    = 0;
bio_as_prices     = false;
byparcel          = true;
sample_size       = 'no';
carbon_price_string = 'non_trade_central';
drop_vars   = {'habitat_non_use', 'biodiversity'};

budget_str  = [num2str(round(unscaled_budget/1e9)) 'bill' ];
if bio_constraint > 0
    biocnst_str = ['_' num2str(round(bio_constraint*100)) 'pct'];
else
    biocnst_str = '';
end
if bio_as_prices
    biop_str = '_pbio';
else
    biop_str = '';
end
markup = 1.15;

% Paths to Data & Cplex Working Dir
% ---------------------------------
cplex_folder = 'D:\myGitHub\defra-elms\Cplex\';
data_folder  = 'D:\myGitHub\defra-elms\Data\';
data_path = [data_folder, 'elm_data_', carbon_price_string, '.mat'];

clear solution
load([data_folder 'solution_' payment_mechanism '_' budget_str biocnst_str biop_str '.mat'], 'solution');   

surplus = sum(solution.farm_payment - solution.farm_costs)

data_year = 1;    
sample_size = 'no';  % all data
[b, c, q, hectares, budget, lu_data, cnst_data, cnst_target, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, bio_constraint, bio_as_prices, byparcel, data_year);

hectares = sum(table2array(hectares).*solution.uptake, 2);

surplus/sum(hectares)

