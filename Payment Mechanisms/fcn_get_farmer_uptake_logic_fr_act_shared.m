function [opt_cells, option_choice, farm_payment] = fcn_get_farmer_uptake_logic_fr_act_shared(flat_rates, budget, cell_ids, elm_ha, costs, elm_options)
    num_elm_options = length(elm_options);

    % Budget per farm: Farm as proportion of total agricultural land area
    farm_proportion = (elm_ha(:,1) + elm_ha(:,2)) / sum(elm_ha(:,1) + elm_ha(:,2));
    farm_budget     = farm_proportion .* budget;
    
    % Remove cells with no hectares of arable or grass
    elm_ha_ind   = ~((elm_ha(:,1)==0) | (elm_ha(:,2)==0));

    cell_ids     = cell_ids(elm_ha_ind, :);
    elm_ha       = elm_ha(elm_ha_ind, :);
    opt_costs    = costs(elm_ha_ind, :);
    farm_budget  = farm_budget(elm_ha_ind, :);
    
    % Flat rates for combo options
    combo = [1, 1, 0, 0, 0, 0, 0, 0; ...
             1, 0, 1, 0, 0, 0, 0, 0; ...
             0, 0, 1, 1, 0, 0, 0, 0; ...
             0, 1, 0, 1, 0, 0, 0, 0; ...
             0, 0, 0, 0, 1, 1, 0, 0; ...
             0, 0, 0, 0, 1, 0, 1, 0; ...
             0, 0, 0, 0, 0, 0, 1, 1; ...
             0, 0, 0, 0, 0, 1, 0, 1];
    p_combo = (elm_ha(:,1:8) * (combo .* flat_rates')) ./ elm_ha(:,9:16);
    
    % Farm specific prices
    num_farms = size(elm_ha,1);
    p_farm = [repmat(flat_rates, num_farms, 1), p_combo];
    
    % Ha could pay for of each option for farm given its budget
    elm_ha_at_rate = farm_budget ./ p_farm;
    elm_ha_proportion = elm_ha_at_rate ./ elm_ha;
    elm_ha_proportion(elm_ha_proportion>1) = 1; % Can only pay for full area remainder of budget unspent if this chosen
    
    % Determine which option each farmer would prefer at these prices
    opt_payments = p_farm .* elm_ha_proportion .* elm_ha;
    opt_csts     = elm_ha_proportion .* opt_costs;
    opt_profits  = opt_payments - opt_csts;
    opt_profits  = [zeros(num_farms,1), opt_profits]; % Allow no participation option
    opt_payments = [zeros(num_farms,1), opt_payments]; 
    
    [~, max_profit_col_idx] = max(opt_profits,[],2);
    
    change_ind = [];
    for i = 2:num_elm_options+1
        change_ind = [change_ind, (max_profit_col_idx == i)];
    end
    
    % Payments and farm proportion from maximising choice
    farm_payment  = zeros(num_farms,1);
    opt_ha_prop   = zeros(num_farms,1);
    
    elm_ha_proportion = [zeros(num_farms,1), elm_ha_proportion];    
    
    for i = 1:num_farms
        farm_payment(i)  = opt_payments(i, max_profit_col_idx(i));
        opt_ha_prop(i)   = elm_ha_proportion(i, max_profit_col_idx(i));
    end
    
    any_option_ind = any(change_ind, 2);

    opt_cells    = cell_ids(any_option_ind);
    opt_ha_prop  = opt_ha_prop(any_option_ind);
    farm_payment = farm_payment(any_option_ind);
    
    opt_cells    = [opt_cells, opt_ha_prop];
    
    option_choice = max_profit_col_idx(any_option_ind)-1;
    
end