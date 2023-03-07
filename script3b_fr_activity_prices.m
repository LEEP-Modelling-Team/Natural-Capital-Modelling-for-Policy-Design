% script3b_fr_activity_prices.m
% =============================
%  Search for optimum flat rate prices for activities to deliver optimal 
%  benefits for budget.

% 1. Initialise
% -------------
clear
rng(23112010)

% Model
% -----
payment_mechanism = 'fr_act';
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
% data_folder = 'D:\mydata\Research\Projects (Land Use)\Defra_ELMS\Data\';
% data_folder = 'D:\Documents\Data\Defra-ELMS\';
% data_path = [data_folder, 'Script 2 (ELM Option Runs)/elm_data_', carbon_price_string, '.mat'];
cplex_folder = 'D:\myGitHub\defra-elms\Cplex\';
data_folder  = 'D:\myGitHub\defra-elms\Data\';
data_path = [data_folder, 'elm_data_', carbon_price_string, '.mat'];


% 2. Prepare data
% ---------------

% (a) Load data
% -------------
data_year = 1;    
sample_size = 'no';  % all data
[b, c, q, budget, cnst_data, cnst_target, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, data_year);
num_prices  = length(price_vars);
num_options = size(b,2);
num_farmers = size(b,1);

cnst_target = floor(cnst_target/1000);

% (b) Reduce problem size
% -----------------------
%  Reduce size of the problem: search for prices that would exhaust the
%  entire budget for each option, calculate uptake and remove subset of
%  cells that are never selected under any option when the budget is
%  exhausted
prices_lb = zeros(length(elm_options), 1);
prices_ub = zeros(length(elm_options), 1);
excluded_cells = ones(size(c,1),1);
for i = 1:length(elm_options)
    [price_pts, sortidx] = sort(c(:,i)./q(:,i), 'ascend', 'MissingPlacement', 'last');
    ind_over_budget = (cumsum(q(sortidx,i)) .* price_pts) >= budget;
    cell_over_budget(sortidx) = ind_over_budget;
    excluded_cells = excluded_cells .* cell_over_budget';
    prices_ub(i)   = price_pts(find(ind_over_budget, 1)-1);
end
prices_ub = prices_ub;

% (c) Reduce to relevant cells
% ----------------------------
%  Remove cells where no possible price would enduce participation
excluded_cells = logical(excluded_cells);
b(excluded_cells, :) = [];
c(excluded_cells, :) = [];
q(excluded_cells, :) = [];
cnst_data(excluded_cells, :) = [];


% 3. MIP for Global Optimal Prices
% --------------------------------
cplex_options.time = 1800;
cplex_options.logs = cplex_folder;  
[prices, uptake_sml, fval, exitflag, exitmsg] = MIP_fr_act(b, c, q, budget, prices_lb, prices_ub, bio_constraint, cnst_data, cnst_target, cplex_options);

% This gives slightly different result though putting prices back through
% benefits calculator shows it is wrong ...
%
% num_farmers = size(q,1);
% num_options = size(q,2);
% q_cell = mat2cell(q, size(q,1), repelem(1,1,size(q,2)));
% q_lng  = blkdiag(q_cell{:});
% q_3d   = reshape(q_lng,[num_farmers,num_options,num_options]);
% 
% [x_milp, prices_milp1, fval_milp1, exitflag, exitmsg] = MIP_fr_out(b, c, q_3d, budget, [], [], prices_lb, prices_ub, cplex_options);

% Process result
% --------------
uptake_ind_sml    = (sum(uptake_sml,2) > 0);
option_nums       = (1:8)';
option_choice_sml = (uptake_sml * option_nums);
benefits_sml      = sum(b.*uptake_sml, 2);
costs_sml         = sum(c.*uptake_sml, 2);
farm_payment_sml  = sum(prices.*q.*uptake_sml, 2);

% Rexpand to full cell list
% -------------------------
uptake        = zeros(num_farmers, num_options);
uptake_ind    = zeros(num_farmers, 1);
option_choice = zeros(num_farmers, 1);
benefits      = zeros(num_farmers, 1);
costs         = zeros(num_farmers, 1);
farm_payment  = zeros(num_farmers, 1);

sample_idx                = find(1-excluded_cells);
uptake(sample_idx,:)      = uptake_sml;
uptake_ind(sample_idx)    = uptake_ind_sml;
uptake_ind                = logical(uptake_ind);
option_choice(sample_idx) = option_choice_sml;
benefits(sample_idx)      = benefits_sml;
costs(sample_idx)         = costs_sml;
farm_payment(sample_idx)  = farm_payment_sml;


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

