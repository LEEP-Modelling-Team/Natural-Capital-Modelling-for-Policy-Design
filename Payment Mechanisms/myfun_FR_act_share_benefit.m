function f = myfun_FR_act_share_benefit(p, opt_costs, opt_benefits, opt_ha, farm_budget)

    % Flat rates for combo options
    combo = [1, 1, 0, 0, 0, 0, 0, 0; ...
             1, 0, 1, 0, 0, 0, 0, 0; ...
             0, 0, 1, 1, 0, 0, 0, 0; ...
             0, 1, 0, 1, 0, 0, 0, 0; ...
             0, 0, 0, 0, 1, 1, 0, 0; ...
             0, 0, 0, 0, 1, 0, 1, 0; ...
             0, 0, 0, 0, 0, 0, 1, 1; ...
             0, 0, 0, 0, 0, 1, 0, 1];
    p_combo = (opt_ha(:,1:8) * (combo .* p')) ./ opt_ha(:,9:16);
    
    % Farm specific prices
    num_farms = size(opt_ha,1);
    p_farm = [repmat(p, num_farms, 1), p_combo];         

    % Ha could pay for of each option for farm given its budget
    opt_ha_at_rate = farm_budget ./ p_farm;
    opt_ha_proportion = opt_ha_at_rate ./ opt_ha;
    opt_ha_proportion(opt_ha_proportion>1) = 1; % Can only pay for full area remainder of budget unspent if this chosen
        
    %Determine which option each farmer would prefer at these prices
    opt_payments = p_farm.*opt_ha_proportion.*opt_ha;
    opt_csts     = opt_ha_proportion.*opt_costs;
    opt_bens     = opt_ha_proportion.*opt_benefits;
    opt_profits  = opt_payments - opt_csts;
    opt_profits  = [zeros(num_farms,1) opt_profits]; % Allow no participation option
    opt_bens     = [zeros(num_farms,1) opt_bens];
    [~, max_profit_col_idx] = max(opt_profits,[],2);
    
    %Benefits from profit maximising choice
    benefit_final = zeros(num_farms,1);
    for i = 1:num_farms
        benefit_final(i) = opt_bens(i,max_profit_col_idx(i));
    end
    
    f = -sum(benefit_final);

end