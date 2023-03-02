% script5_fr_activity_pctl.m
% ==========================

clear

% 1. Initialise
% -------------

% Model
% -----
payment_mechanism = 'fr_act_pctl';
carbon_price_string = 'scc';
drop_vars = {'habitat_non_use', 'biodiversity'};
unscaled_budget = 1e9;

% Markup
% ------
markup = 1.15;

% Paths to Data & Cplex Working Dir
% ---------------------------------
data_folder  = 'D:\myGitHub\defra-elms\Data\';
data_path = [data_folder, 'elm_option_results_', carbon_price_string, '.mat'];


% 2. Prepare data
% ---------------

% (a) Load data
% -------------
data_year = 1;    
sample_size = 'no';  % all data
[b, c, q, budget, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, data_year);
num_prices  = length(price_vars);
num_options = size(b,2);
num_farmers = size(b,1);


% 3. Multiple Choice Knapsack Optimisation
% ----------------------------------------
[prices, pct] = fcn_payment_fr_act_pct(budget, elm_options, c, q);

% 4. Save Solution
% ----------------
solution.opt_cells    = opt_cells;
solution.opt_choice   = opt_choice;
solution.farm_payment = farm_payment;
save('solution_oc_payments.mat', 'solution');                                                                                



