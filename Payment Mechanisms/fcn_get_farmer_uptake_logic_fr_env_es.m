function [uptake_logic, option_idx, spend_ES] = fcn_get_farmer_uptake_logic_fr_env_es(flat_rates, env_quants, opp_costs, elm_option)

    % Determine which option each farmer would prefer at these prices
    profit = zeros(length(opp_costs), length(elm_option) + 1);
    spend  = zeros(length(opp_costs), length(elm_option) + 1);
    
    %Evaluate profit & cost for each option 
    
    % Profit = price per env_quant x env_quant - opportunity costs  
    for i = 1:length(elm_option)
        profit(:, i + 1) = flat_rates * env_quants.(elm_option{i})' - opp_costs(:, i)';
        spend(:, i + 1)  = flat_rates * env_quants.(elm_option{i})';
    end
 
    % Do farmers have positive profit at this price? 
    has_positive_profit = profit(:, 2:end) > 0;
    
    % Which ELM option has best profit?
    [~, option_idx] = max(profit, [], 2);
    is_best_option = [];
    for i = 2:length(elm_option) + 1
        is_best_option = [is_best_option, (option_idx == i)];
    end
    
    % Farmer will choose option with best profit, provided it is positive
    uptake_logic = (has_positive_profit & is_best_option);

    % spend
    spend_ES = sum(sum(is_best_option .* spend(:, 2:end))); % !!! option_idx does not pull out the required elements
    
end