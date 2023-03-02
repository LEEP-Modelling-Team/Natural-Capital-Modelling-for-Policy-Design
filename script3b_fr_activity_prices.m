% script3_opt_output_prices.m
% ===============================
%  Search for optimum flat rateprices for different payment mechanisms and 
%  budgets

clear
rng(23112010)

% 1. Initialise
% -------------

% Model
% -----
payment_mechanism = 'fr_act';
carbon_price_string = 'scc';
drop_vars = {'habitat_non_use', 'biodiversity'};
unscaled_budget = 1e9;
budget_str = [num2str(round(unscaled_budget/1e9)) 'bill'];

% Markup
% ------
markup = 1.15;

% Paths to Data & Cplex Working Dir
% ---------------------------------
% data_folder = 'D:\mydata\Research\Projects (Land Use)\Defra_ELMS\Data\';
% data_folder = 'D:\Documents\Data\Defra-ELMS\';
% data_path = [data_folder, 'Script 2 (ELM Option Runs)/elm_option_results_', carbon_price_string, '.mat'];
cplex_folder = 'D:\myGitHub\defra-elms\Cplex\';
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
    [price_pts, sortidx] = sort(c(:,i)./q(:,i));
    ind_over_budget = (cumsum(q(sortidx,i)) .* price_pts) >= budget;
    cell_over_budget(sortidx) = ind_over_budget;
    excluded_cells = excluded_cells .* cell_over_budget';
    prices_ub(i)   = price_pts(find(ind_over_budget, 1)-1);
end

% (c) Reduce to relevant cells
% ----------------------------
%  Remove cells where could no possible price would enduce participation
excluded_cells = logical(excluded_cells);
b(excluded_cells, :) = [];
c(excluded_cells, :) = [];
q(excluded_cells, :) = [];
new2kid(excluded_cells, :) = [];


% 3. MIP for Global Optimal Prices
% --------------------------------
cplex_options.time = 1800;
cplex_options.logs = cplex_folder;  
[options_uptake, option_choice, prices_milp, farm_payment, fval_milp] = MIP_fr_act(b, c, q, budget, prices_lb, prices_ub, cplex_options);

% num_farmers = size(q,1);
% num_options = size(q,2);
% q_cell = mat2cell(q, size(q,1), repelem(1,1,size(q,2)));
% q_lng  = blkdiag(q_cell{:});
% q_3d   = reshape(q_lng,[num_farmers,num_options,num_options]);
% 
% [x_milp, prices_milp1, fval_milp1, exitflag, exitmsg] = MIP_fr_out(b, c, q_3d, budget, [], [], prices_lb, prices_ub, cplex_options);


% 4. Save Solution
% ----------------
solution.prices  = prices_milp;
solution.fval    = fval_milp;
save(['solution_' budget_str '_' payment_mechanism '_prices.mat'], 'solution');                                                                         



