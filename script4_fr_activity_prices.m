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

% 3. Solve Full Problem
% ---------------------

% (a) Load data
% -------------
data_year = 1;    
sample_size = 'no';  % all data
[b, c, q, budget, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, data_year);
num_prices = length(price_vars);



[options_uptake, option_choice, best_rate, farm_payment, tot_benefits] = lp_fr_activity(elm_options, ...
                                                                                        budget, ...
                                                                                        markup, ...
                                                                                        c, ...
                                                                                        b, ...
                                                                                        q, ...
                                                                                        new2kid);








% (b) Scale quantities
% --------------------
prices_scale = reshape(permute(q, [1 3 2]),[], size(q,2));
prices_scale(prices_scale==0) = NaN;
prices_scale = nanstd(prices_scale);
q = q ./ repmat(prices_scale, [size(q,1), 1, size(q,3)]);



% (e) MIP for global optimum
% --------------------------  
prices_lb = min(prices_locopt)' * 0.75;
prices_ub = max(prices_locopt)' * 1.25;

prices_lb = zeros(size(prices_lb));

uptake_locopt = myfun_uptake(prices_locopt(1, :), q, c, elm_options)';
uptake_locopt = uptake_locopt(:)';

cplex_options.time = 15000;
cplex_options.logs = cplex_folder;    
[x_milp, prices_milp, fval_milp, exitflag, exitmsg] =  MILP_output_prices(b, c, q, budget, prices_locopt(1, :), uptake_locopt, prices_lb, prices_ub, cplex_time);
prices_milp = prices_milp ./ prices_scale;

% 4. Save Solution
% ----------------
solution.x             = x_milp;
solution.prices        = prices_milp;
solution.fval          = fval_milp;
solution.exitflag      = exitflag;
solution.prices_locopt = prices_locopt;
solution.prices_lb     = prices_lb;
solution.prices_ub     = prices_ub;
solution.new2kid       = new2kid;

if strcmp(payment_mechanism, 'fr_env')
    save('solution_env_out_prices.mat', 'solution');
elseif strcmp(payment_mechanism, 'fr_es')
    save('solution_es_out_prices.mat', 'solution');
else
    error('payment mechanism can only be ''fr_env'' or ''fr_es''')
end

