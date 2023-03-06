% script3d_fr_activity_pctl_rnd.m
% ===============================
% Finds prices at percentile of cost distribution and selects farmers at 
% random from set who volunteer into an option at those prices.

% 1. Initialise
% -------------
clear
rng(23112010)

% Model
% -----
payment_mechanism = 'fr_act_pctl_rnd';
unscaled_budget = 1e9;
urban_pct_limit = 0.5;
carbon_price_string = 'non_trade_central';
drop_vars = {'habitat_non_use', 'biodiversity'};
budget_str = [num2str(round(unscaled_budget/1e9)) 'bill'];
pctl  = 50; % median prices
Niter = 1000;

% Markup
% ------
markup = 1.15;

% Paths to Data & Cplex Working Dir
% ---------------------------------
data_folder  = 'D:\myGitHub\defra-elms\Data\';
data_path = [data_folder, 'elm_data_', carbon_price_string, '.mat'];


% 2. Prepare data
% ---------------
data_year = 1;    
sample_size = 'no';  % all data
[b, c, q, budget, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, data_year);
num_prices  = length(price_vars);
num_options = size(b,2);
num_farmers = size(b,1);


% 3. Multiple Choice Knapsack Optimisation
% ----------------------------------------

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

% Number of Iterations of Random Uptake Selection
% -----------------------------------------------
mc_spend  = zeros(Niter, 1);
mc_fval   = zeros(Niter, 1);
mc_uptake = zeros(num_farmers, 1);

for i = 1:Niter
    
    % Random first come, first served
    % -------------------------------
	sortidx = randperm(num_farmers);
	inbudget_ind = 1 - (cumsum(spend(sortidx)) >= budget);
	inbudget_ind(sortidx) = inbudget_ind;  % undo sort to find best in budget
 
    % Select most benefits in budget
    % ------------------------------
    uptake_i    = uptake .* inbudget_ind;
    mc_uptake   = mc_uptake + sum(uptake_i,2);
    mc_spend(i) = sum(prices.*q.*uptake_i, 'all');
    mc_fval(i)  = sum(b.*uptake_i, 'all');    
    
end

% Uptake as a probability
% -----------------------
rnd_uptake_ind = mc_uptake/Niter;

% Process result
% --------------
uptake        = uptake .* rnd_uptake_ind;
option_nums   = (1:8)';
option_choice = (uptake>0) * option_nums;
benefits      = sum(b.*uptake, 2);
costs         = sum(c.*uptake, 2);
farm_payment  = sum(prices.*q.*uptake, 2);


% 4. Save Solution
% ----------------
solution.prices        = prices;
solution.fval          = sum(benefits);
solution.spend         = sum(farm_payment);
solution.uptake        = uptake;
solution.uptake_ind    = rnd_uptake_ind;
solution.option_choice = option_choice;
solution.new2kid       = new2kid(rnd_uptake_ind>0);
solution.farm_costs    = costs;
solution.farm_benefits = benefits;
solution.farm_payment  = farm_payment;

save(['solution_' budget_str '_' payment_mechanism '.mat'], 'solution');  




