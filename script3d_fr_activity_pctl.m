% script3d_fr_activity_pctl.m
% ===========================
% Finds prices at percentile of cost distribution and selects most benefit 
% farmers from set who volunteer into an option at those prices.

% 1. Initialise
% -------------
clear
rng(23112010)

% Model
% -----
payment_mechanism = 'fr_act_pctl';
unscaled_budget = 1e9;
carbon_price_string = 'scc';
drop_vars = {'habitat_non_use', 'biodiversity'};
budget_str = [num2str(round(unscaled_budget/1e9)) 'bill'];
pctl = 50; % median prices

% Markup
% ------
markup = 1.15;

% Paths to Data & Cplex Working Dir
% ---------------------------------
data_folder  = 'D:\myGitHub\defra-elms\Data\';
data_path = [data_folder, 'elm_option_results_', carbon_price_string, '.mat'];


% 2. Prepare data
% ---------------
data_year = 1;    
sample_size = 'no';  % all data
[b, c, q, budget, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, data_year);
num_prices  = length(price_vars);
num_options = size(b,2);
num_farmers = size(b,1);


% 3. Find Prices & Optimal Uptake at this Percentile of Costs
% -----------------------------------------------------------

% Calculate cost per hectare of each option
% -----------------------------------------
c_perha = c./q;
c_perha(isinf(c_perha)) = inf;
c_perha(isnan(c_perha)) = inf;

% Prices at Percentile
% --------------------
prices = prctile(c_perha, pctl, 1);

% Uptake and Benefits at those prices
% -----------------------------------
uptake   = myfun_uptake(prices, q, c, elm_options);    
benefits = sum(b.*uptake, 2);
spend    = sum(prices.*q.*uptake, 2);
bc_ratio = benefits./spend; % benefits per £spend

% Select most benefits in budget
% ------------------------------
[~, sortidx] = sort(bc_ratio, 'descend', 'MissingPlacement', 'last'); % sort from best to worst
inbudget_ind = 1 - (cumsum(spend(sortidx)) >= budget);
inbudget_ind(sortidx) = inbudget_ind;  % undo sort to find best in budget

% Process result
% --------------
uptake        = sparse(uptake .* inbudget_ind);
uptake_ind    = (sum(uptake,2) > 0);
option_nums   = (1:8)';
option_choice = (uptake * option_nums);
benefits      = sum(b.*uptake, 2);
costs         = sum(c.*uptake, 2);
farm_payment  = sum(prices.*q.*uptake, 2);


% 4. Save Solution
% ----------------
solution.prices        = prices;
solution.fval          = sum(benefits);
solution.spend         = sum(farm_payment);
solution.uptake        = uptake;
solution.uptake_ind    = uptake_ind;
solution.option_choice = option_choice;
solution.new2kid       = new2kid(uptake_ind);
solution.farm_costs    = costs;
solution.farm_benefits = benefits;
solution.farm_payment  = farm_payment;

save(['solution_' budget_str '_' payment_mechanism '.mat'], 'solution');                                                                          






