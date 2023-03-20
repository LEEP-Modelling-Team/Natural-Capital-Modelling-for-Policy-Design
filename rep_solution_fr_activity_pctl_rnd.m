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
bio_constraint = 0;
carbon_price_string = 'non_trade_central';
drop_vars = {'habitat_non_use', 'biodiversity'};
budget_str = [num2str(round(unscaled_budget/1e9)) 'bill'];
biocnst_str = [num2str(round(bio_constraint*100)) 'pct'];

pctl  = 50; % median prices
Niter = 20000;

% Markup
% ------
markup = 1.15;

% Paths to Data & Cplex Working Dir
% ---------------------------------
data_folder  = 'D:\Documents\GitHub\defra-elms\Data\';
data_path = [data_folder, 'elm_data_', carbon_price_string, '.mat'];


% 2. Prepare data
% ---------------
data_year = 1;    
sample_size = 'no';  % all data
[b, c, q, budget, cnst_data, cnst_target, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, bio_constraint, data_year);
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

% Load solution
load('solution_1bill_fr_act_pctl_rnd.mat')
target_fval   = solution.fval;
target_spend  = solution.spend;
max_spend_gap = 0.5e5;
max_fval_gap  = 0.5e5;
clear solution

for i = 1:Niter
    % Random first come, first served
    % -------------------------------
	sortidx = randperm(num_farmers);
	inbudget_ind = 1 - (cumsum(spend(sortidx)) >= budget);
	inbudget_ind(sortidx) = inbudget_ind;  % undo sort to find best in budget
 
    % Select most benefits in budget
    % ------------------------------
    uptake_i  = uptake .* inbudget_ind;      
    mc_spend  = sum(prices.*q.*uptake_i, 'all');
    mc_fval   = sum(b.*uptake_i, 'all'); 
    spend_gap = abs(target_spend - mc_spend);
    fval_gap  = abs(target_fval - mc_fval);
    
        
    % Check if meets constraint
    % -------------------------
    num_spgrp = length(cnst_target);
    spgrp_chg = zeros(num_spgrp,1);
    for k = 1:num_spgrp
        spgrp_chg(k) = sum(uptake_i.*squeeze(cnst_data(k,:,:))', 'all');        
    end
    
    % is the solution a representative one?
    % -------------------------------------
    if (~any(spgrp_chg < cnst_target)) && (spend_gap <= max_spend_gap) && (fval_gap <= max_fval_gap)
        fprintf("Representative solution found at iteration %d of %d. Ending search.\n", i, Niter); 
        uptake        = uptake_i;
        option_nums   = (1:8)';
        option_choice = (uptake>0) * option_nums;
        benefits      = sum(b.*uptake, 2);
        costs         = sum(c.*uptake, 2);
        farm_payment  = sum(prices.*q.*uptake, 2);
        solution.prices        = prices;
        solution.fval          = sum(benefits);
        solution.spend         = sum(farm_payment);
        solution.uptake        = uptake;
        solution.option_choice = option_choice;
        solution.new2kid       = new2kid(option_choice>0);
        solution.farm_costs    = costs;
        solution.farm_benefits = benefits;
        solution.farm_payment  = farm_payment; 
        break
    else
        continue
    end
end

is_solution = exist("solution");
if is_solution == 1
    if bio_constraint > 0    
        save([data_folder 'repr_solution_' biocnst_str '_' budget_str '_' payment_mechanism '.mat'], 'solution'); 
    else
        save([data_folder 'repr_solution_' budget_str '_' payment_mechanism '.mat'], 'solution');     
    end
else
    fprintf("Representative solution not found from %d samples. Increase the value of 'Niter'\n", Niter);
end




