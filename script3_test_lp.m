%% script3_run_search_for_prices.m
%  ===============================
%  Run search algorithm / scattergun approach to find optimum prices for
%  different payment mechanisms and budgets
clear

%% 1) SET-UP
%  =========
carbon_price_string = 'non_trade_central';
remove_nu_habitat = true;
sample_size = 150;
unscaled_budget = 1e9;
payment_mechanism = 'fr_env';

data_folder = 'D:\Documents\Data\Defra-ELMS\';
data_path = [data_folder, 'Script 2 (ELM Option Runs)/elm_option_results_', carbon_price_string, '.mat'];

%% 2) LOAD DATA
%  ============
[b,c,q,budget,available_elm_options,unit_value_max] = load_data(sample_size, unscaled_budget, data_path, remove_nu_habitat);

%% 3) RUN OPTIMISATION
%  ===================
[prices_1, fval_1, x_1] =  fcn_test_lp('yes', b, c, q, budget, available_elm_options, payment_mechanism, unit_value_max);
[prices_2, fval_2, x_2] =  fcn_test_lp('no', b, c, q, budget, available_elm_options, payment_mechanism, unit_value_max);

uptake_1 = x_1(10+sample_size+1:end);
uptake_2 = x_2(10+sample_size+1:end);

u_1 = x_1(11:10+sample_size);
u_2 = x_2(11:10+sample_size);

uptake_1 = reshape(uptake_1, width(b), [])';
uptake_2 = reshape(uptake_2, width(b), [])';

[row_1, col_1] = find(uptake_1);
[row_2, col_2] = find(uptake_2);

unique_opt_1 = unique(col_1);
unique_opt_2 = unique(col_2);

profits_1  = zeros(sample_size, length(available_elm_options));
spend_1    = zeros(sample_size, length(available_elm_options));
profits_2  = zeros(sample_size, length(available_elm_options));
spend_2    = zeros(sample_size, length(available_elm_options));
for i = 1:length(available_elm_options)
    profits_1(:, i) = q(:, :, i) * prices_1' - c(:, i);
    profits_2(:, i) = q(:, :, i) * prices_2' - c(:, i);
    spend_1(:, i)   = q(:, :, i) * prices_1';
    spend_2(:, i)   = q(:, :, i) * prices_2';
end

profits_1 = profits_1 .* uptake_1;
profits_2 = profits_2 .* uptake_2;
spend_1 = spend_1 .* uptake_1;
spend_2 = spend_2 .* uptake_2;
tot_profits_1 = sum(sum(profits_1));
tot_profits_2 = sum(sum(profits_2));
tot_spend_1 = sum(sum(spend_1));
tot_spend_2 = sum(sum(spend_2));

profit_cmp = [sum(profits_1, 2), u_1, sum(profits_1, 2) ~= u_1, sum(profits_2, 2), u_2, sum(profits_2, 2) ~= u_2];
