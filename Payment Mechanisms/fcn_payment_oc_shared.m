function [opt_cells, option_choice, farm_payment] = fcn_payment_oc_shared(budget, markup, cell_ids_year, elm_ha_year, costs_year, benefits_year)

 % Number of ELM options
    %num_elm_options = size(elm_ha_year, 2);
    
    per_farm_per_ha = 5*budget / 8721600;
    costs = markup*costs_year;

    % profit = per_farm_per_ha*(elm_ha_year(:,1) + elm_ha_year(:,2)) - opp_costs_year;

    % If a farm's profit would be negative under an option, they would only
    % do part of this option - scale the proportion such that profit > = 0
    
    % calculate proportions
    % !!! opp_cost_year is the sum of farm opportunity cost, recreation
    % access cost and woodland cost
    % !!! need to deal with fixed cost issue
    farm_payment = per_farm_per_ha*(elm_ha_year(:,1) + elm_ha_year(:,2)); % Add arable & grassland which are quantites in first two elm options
    
    farm_proportion_for_payment = farm_payment ./ costs;
    farm_proportion_for_payment(farm_proportion_for_payment>1) = 1;
    
    benefit = benefits_year .* farm_proportion_for_payment;
    
    %farmers_not_in = sum(sum(benefit==0,2)==num_elm_options) - sum(sum(elm_ha_year==0,2)==num_elm_options);
    
    % Calculate which option is best in terms of benefit for fixed payment
    [option_b, option_choice] = max(benefit, [], 2);
    
    opt_cells = zeros(length(elm_ha_year),1);
    % Extract the correct proportions for chosen option 
    for i = 1:length(elm_ha_year)
        opt_cells(i) = farm_proportion_for_payment(i, option_choice(i));
    end
    
    opt_cells = [cell_ids_year opt_cells];
    
    % Remove cells with no agricultural land
    elm_ha_ind       = ~((elm_ha_year(:,1)==0) | (elm_ha_year(:,2)==0));
    opt_cells = opt_cells(elm_ha_ind, :);
    option_choice = option_choice(elm_ha_ind, :);
    farm_payment = farm_payment(elm_ha_ind, :);
    costs = costs(elm_ha_ind, :);
    
end