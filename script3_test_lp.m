%% script3_run_search_for_prices.m
%  ===============================
%  Run search algorithm / scattergun approach to find optimum prices for
%  different payment mechanisms and budgets
clear

%% 1) SET-UP
%  =========
carbon_price_string = 'non_trade_central';
remove_nu_habitat = true;
sample_size = 500; % either 'no' or a number representing the sample size
unscaled_budget = 1e9;
payment_mechanism = 'fr_env';

data_folder = 'D:\Documents\Data\Defra-ELMS\';
data_path = [data_folder, 'Script 2 (ELM Option Runs)/elm_option_results_', carbon_price_string, '.mat'];

%% 2) LOAD DATA
%  ============
[b,c,q,budget,available_elm_options,unit_value_max] = load_data(sample_size, unscaled_budget, data_path, remove_nu_habitat);

q(:, 10, :) = [];

constraintfunc = @(p) mycon_ES(p, q, c, budget, available_elm_options);
max_rates = zeros(1, width(q));
start_rate = 5;
for i = 1:width(q)
    env_outs_array_i = squeeze(q(:, i, :));
    if sum(sum(env_outs_array_i)) == 0
        % If there are no benefits/quantities across all options then
        % keep max_rate at zero
        continue
    end
    max_rates(i) = fcn_lin_search(width(q),i,start_rate,0.01,constraintfunc,q,c,budget,available_elm_options);
end


best_rate = fcn_find_warm_start(payment_mechanism, ...
                                        budget, ...
                                        available_elm_options, ...
                                        c, ... 
                                        b, ...
                                        q, ...
                                        unit_value_max, ...
                                        max_rates);

benefits = find_objective_value(best_rate, q, c, b, budget, available_elm_options)
fun = @(x) find_objective_value(x, q, c, b, budget, available_elm_options);
options = optimset('MaxFunEvals',inf, 'MaxIter', 20000);

iters = 100;
lb = 0.5;
ub = 1;
p = lb + (rand(iters, width(q)) .* (ub - lb));
fvals_nlsearch = zeros(iters, 1);
prices_nlsearch = zeros(iters, width(q));
fvals_milp = zeros(iters, 1);
prices_milp = zeros(iters, width(q));

for i = 1:iters
    fprintf('Searching from price set %i ...\n', i)
    rate_i = best_rate .* p(i, :);
    if ~isinf(find_objective_value(rate_i, q, c, b, budget, available_elm_options)) 
        [x, fval, exitflag, output] = fminsearch(fun, rate_i, options);
        fvals_nlsearch(i,1) = fval;
        prices_nlsearch(i, :) = x;
        if i <= 10
            [prices_milp(i, :), fvals_milp(i, 1), x_milp] =  fcn_test_lp('yes', b, c, q, budget, available_elm_options, payment_mechanism, unit_value_max, rate_i);
        end
    end
    fprintf('Tot benefits for price set %i = %f \n', [i, fval])
end


nonlin_search = array2table([prices_nlsearch, fvals_nlsearch]);
nonlin_search.Properties.VariableNames = {'Price01', 'Price02', 'Price03', 'Price04', ...
                                                'Price05', 'Price06' 'Price07', 'Price08', ...
                                                'Price09', 'fval'};

milp = array2table([prices_milp, fvals_milp]);
milp.Properties.VariableNames = {'Price01', 'Price02', 'Price03', 'Price04', ...
                                                'Price05', 'Price06' 'Price07', 'Price08', ...
                                                'Price09', 'fval'};

writetable(nonlin_search, 'nonlin_search_500_nobio.csv');
writetable(milp, 'milp_500_nobio.csv');


% %% 3) RUN OPTIMISATION
% %  ===================
[prices_milp, fval_milp, x_milp] =  fcn_test_lp('yes', b, c, q, budget, available_elm_options, payment_mechanism, unit_value_max, best_rates);







% [prices_2, fval_2, x_2] =  fcn_test_lp('no', b, c, q, budget, available_elm_options, payment_mechanism, unit_value_max);
% [prices_3, fval_3, x_3] =  fcn_test_lp('yes', b, c, q, budget, available_elm_options, payment_mechanism, unit_value_max);
% [prices_4, fval_4, x_4] =  fcn_test_lp('no', b, c, q, budget, available_elm_options, payment_mechanism, unit_value_max);
% 
% uptake_1 = x_1(10+sample_size+1:end);
% uptake_2 = x_2(10+sample_size+1:end);
% 
% u_1 = x_1(11:10+sample_size);
% u_2 = x_2(11:10+sample_size);
% 
% uptake_1 = reshape(uptake_1, width(b), [])';
% uptake_2 = reshape(uptake_2, width(b), [])';
% 
% [row_1, col_1] = find(uptake_1);
% [row_2, col_2] = find(uptake_2);
% 
% unique_opt_1 = unique(col_1);
% unique_opt_2 = unique(col_2);
% 
% profits_1  = zeros(sample_size, length(available_elm_options));
% spend_1    = zeros(sample_size, length(available_elm_options));
% profits_2  = zeros(sample_size, length(available_elm_options));
% spend_2    = zeros(sample_size, length(available_elm_options));
% for i = 1:length(available_elm_options)
%     profits_1(:, i) = q(:, :, i) * prices_1' - c(:, i);
%     profits_2(:, i) = q(:, :, i) * prices_2' - c(:, i);
%     spend_1(:, i)   = q(:, :, i) * prices_1';
%     spend_2(:, i)   = q(:, :, i) * prices_2';
% end
% 
% profits_1 = profits_1 .* uptake_1;
% profits_2 = profits_2 .* uptake_2;
% spend_1 = spend_1 .* uptake_1;
% spend_2 = spend_2 .* uptake_2;
% tot_profits_1 = sum(sum(profits_1));
% tot_profits_2 = sum(sum(profits_2));
% tot_spend_1 = sum(sum(spend_1));
% tot_spend_2 = sum(sum(spend_2));
% 
% profit_cmp = [sum(profits_1, 2), u_1, sum(profits_1, 2) ~= u_1, sum(profits_2, 2), u_2, sum(profits_2, 2) ~= u_2];
