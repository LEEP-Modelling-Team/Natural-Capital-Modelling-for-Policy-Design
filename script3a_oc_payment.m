% script3a_oc_payments.m
% ======================
%  Find optimal set of farmers and activities to deliver most benefit for 
%  fixed budget

% 1. Initialise
% -------------
clear
rng(23112010)

% Model
% -----
payment_mechanism = 'oc_pay';
unscaled_budget = 1e9;
urban_pct_limit = 0.5;
bio_constraint = false;
carbon_price_string = 'non_trade_central';
drop_vars = {'habitat_non_use', 'biodiversity'};
budget_str = [num2str(round(unscaled_budget/1e9)) 'bill'];

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
[b, c, q, budget, cnst_data, cnst_target, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, data_year);
num_options = size(b,2);
num_farmers = size(b,1);


% 3. Multiple Choice Knapsack Optimisation
% ----------------------------------------
if ~bio_constraint
    result = double(sortrows(mex_minmcknap(int32(num_farmers), int32(num_options), int64(budget), int32(b'), int32(c'))', 1));
end

% Process result
% --------------
option_choice = result(:, 2);
farm_payment  = result(:, 3);
uptake_ind    = (option_choice > 0);
uptake        = sparse(double(result(uptake_ind, 1)), double(result(uptake_ind, 2)), 1, num_farmers, num_options);
benefits      = sum(b.*uptake, 2);
costs         = sum(c.*uptake, 2);

% Check Biodiversity Constraint
% -----------------------------
num_spgrp = length(cnst_target);
spgrp_chg = zeros(num_spgrp,1);
for k = 1:num_spgrp
    spgrp_chg(k) = sum(uptake.*squeeze(cnst_data(k,:,:))', 'all');        
end
if any(spgrp_chg < cnst_target)
   error('Failed to achieve biodiversity target'); 
end


% 4. Save Solution
% ----------------
solution.prices        = [];
solution.fval          = sum(benefits);
solution.spend         = sum(farm_payment);
solution.uptake        = uptake;
solution.uptake_ind    = uptake_ind;
solution.option_choice = option_choice;
solution.farm_costs    = costs;
solution.farm_benefits = benefits;
solution.farm_payment  = farm_payment;
solution.new2kid       = new2kid(uptake_ind);

save(['solution_' budget_str '_' payment_mechanism '.mat'], 'solution');                                                                          



