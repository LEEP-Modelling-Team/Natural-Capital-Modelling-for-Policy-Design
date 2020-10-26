function [opt_cells, option_choice, farm_payment, best_rate] = fcn_payment_fr_act_shared(budget, markup, cell_ids, opt_ha, costs, opt_benefits, elm_options)

    % (1) Prepare data for per ha flat rate scheme
    % --------------------------------------------
    num_elm_options = size(elm_options, 2);
    num_farms       = size(opt_ha,1);
    num_prices      = num_elm_options /2;
    
    % Include markup in option costs
    costs = markup*costs;
    
    % Budget per farm: Farm as proportion of total agricultural land area
    farm_proportion = (opt_ha(:,1) + opt_ha(:,2)) / sum(opt_ha(:,1) + opt_ha(:,2));
    farm_budget     = farm_proportion .* budget;
    
    % Remove cells with no hectares of arable or grass
    opt_ha_ind   = ~((opt_ha(:,1)==0) | (opt_ha(:,2)==0));

    cell_ids     = cell_ids(opt_ha_ind, :);
    opt_ha       = opt_ha(opt_ha_ind, :);
    opt_costs    = costs(opt_ha_ind, :);
    opt_benefits = opt_benefits(opt_ha_ind, :);
    farm_budget  = farm_budget(opt_ha_ind, :);
    
    num_farms    = size(opt_ha,1);

    
    % Cost per ha
    opt_costs_per_ha = opt_costs(:,1:8) ./ opt_ha(:,1:8);
    

    fprintf('\n  Search for Benefit Maximising Flat Rates per Ha (Shared Budget) \n  --------------------------------------------------------------- \n');
    fprintf('   num prices:  %.0f \n', num_prices);  
    fprintf('   num farmers: %.0f \n', num_farms);  
  
    % (2) Start from median costs as flat rate prices
    % -----------------------------------------------
    flat_rates = median(opt_costs_per_ha);

    % (3)  Optimisation functions
    % ---------------------------
    benefitfunc = @(p) myfun_FR_act_share_benefit(p, opt_costs, opt_benefits, opt_ha, farm_budget);
    spendfunc   = @(p) myfun_FR_act_share_spend(p, opt_costs, opt_benefits, opt_ha, farm_budget);
    
    
    % (3) Find a decent starting point around median costs
    % ----------------------------------------------------
    fprintf('\n  Rough Search of Parameter Space: \n  ------------------------------- \n');
    feasible_rates    = [];
    feasible_benefits = [];
    Ngsearch = 10000;
    LatinHC  = lhsdesign(Ngsearch, num_prices);

    max_rates  = flat_rates * 2; 
    test_rates = LatinHC .* max_rates;
    test_benefits = nan(Ngsearch,1);
    
    parfor i = 1:Ngsearch
        test_benefits(i) = -benefitfunc(test_rates(i, :));
    end
    [maxbenefits, maxbenefitsidx] = max(test_benefits);
    fprintf(['      benefits:       £' sprintf('%s', num2sepstr(maxbenefits,  '%.0f')) '\n']);    
    fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(budget - spendfunc(test_rates(maxbenefitsidx,:)),'%.0f')) '\n']);    

    [max_test_benefits, max_test_benefits_idx] = sort(test_benefits, 'descend');
    max_test_benefits_idx = max_test_benefits_idx(max_test_benefits > 0);
    feasible_rates    = [feasible_rates;    test_rates(max_test_benefits_idx(1:min(10,length(max_test_benefits_idx))),:)];
    feasible_benefits = [feasible_benefits; test_benefits(max_test_benefits_idx(1:min(10,length(max_test_benefits_idx))))];

  
    % (4) Refine search around rough rates
    % ------------------------------------
    fprintf('\n  Refine Search in Feasible Parameter Space: \n  ----------------------------------------- \n');
   
    rough_rates    = feasible_rates;
    rough_benefits = feasible_benefits;
    
    Ngsearch = 100;
    LatinHC  = lhsdesign(Ngsearch, num_prices);
    
    for jj = 1:size(feasible_rates,1);
        test_rates    = LatinHC.*feasible_rates(jj,:) + feasible_rates(jj,:)/2; % search space between 50% & 150% of feasible starting point
        test_benefits = nan(Ngsearch,1);
        fprintf('   Feasible price: %.0f \n', jj);  
        parfor i = 1:Ngsearch
            test_benefits(i) = -benefitfunc(test_rates(i, :));
        end
        [maxbenefits, maxbenefitsidx] = max(test_benefits);
        fprintf(['      benefits:       £' sprintf('%s', num2sepstr(maxbenefits,  '%.0f')) '\n']);    
        fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(budget - spendfunc(test_rates(maxbenefitsidx,:)),'%.0f')) '\n']);    
        if maxbenefits > 0
            [max_test_benefits, max_test_benefits_idx] = sort(test_benefits, 'descend');
            max_test_benefits_idx = max_test_benefits_idx(max_test_benefits > 0);
            rough_rates    = [rough_rates;    test_rates(max_test_benefits_idx(1:min(10,length(max_test_benefits_idx))),:)];
            rough_benefits = [rough_benefits; test_benefits(max_test_benefits_idx(1:min(10,length(max_test_benefits_idx))))];
        end
    end
    
    [max_rough_benefits, max_rough_benefits_idx] = sort(rough_benefits, 'descend');
    good_rates    = rough_rates(max_rough_benefits_idx(1:min(20,length(max_rough_benefits_idx))),:);
    good_benefits = rough_benefits(max_rough_benefits_idx(1:min(20,length(max_rough_benefits_idx))));
    
    % (3) Precise search around best parameters from grid search
    % ----------------------------------------------------------
    fprintf('\n  Precise Minimisation from Best Parameters: \n  ------------------------------------------ \n');

    best_rates    = good_rates;
    best_benefits = good_benefits;
    
    for jj = 1:size(good_rates,1)
        % optimiser call
        %[fmin_rate, fmin_benefit] = fmincon(benefitfunc, good_rates(jj,:),[],[],[],[],zeros(1,num_prices),[],constraintfunc,[]);
        [fmin_rate, fmin_benefit] = patternsearch(benefitfunc, good_rates(jj,:),[],[],[],[],zeros(1,num_prices),[],[],[]);
        fprintf(['      benefits:       £' sprintf('%s', num2sepstr(-benefitfunc(fmin_rate),   '%.0f')) '\n']);    
        fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(budget-spendfunc(fmin_rate),'%.0f')) '\n']);    
        % rescale parameters
        best_rates    = [best_rates; fmin_rate];
        best_benefits = [best_benefits; -fmin_benefit];
    end
    
    % (4)  Best rate
    % --------------
    fprintf('\n  Best prices: \n  ------------ \n');

    [max_best_benefits, max_best_benefits_idx] = max(best_benefits);
    best_rate    = best_rates(max_best_benefits_idx,:);
    best_benefit = best_benefits(max_best_benefits_idx,:);

    fprintf(['      benefits:       £' sprintf('%s', num2sepstr(-benefitfunc(best_rate),   '%.0f')) '\n']);    
    fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(budget-spendfunc(best_rate),'%.0f')) '\n']);    
    fprintf( '      best price: £%.2f \n', best_rate);

    % Flat rates for combo options
    combo = [1, 1, 0, 0, 0, 0, 0, 0; ...
             1, 0, 1, 0, 0, 0, 0, 0; ...
             0, 0, 1, 1, 0, 0, 0, 0; ...
             0, 1, 0, 1, 0, 0, 0, 0; ...
             0, 0, 0, 0, 1, 1, 0, 0; ...
             0, 0, 0, 0, 1, 0, 1, 0; ...
             0, 0, 0, 0, 0, 0, 1, 1; ...
             0, 0, 0, 0, 0, 1, 0, 1];
    p_combo = (opt_ha(:,1:8) * (combo .* best_rate')) ./ opt_ha(:,9:16);
    
    % Farm specific prices
    num_farms = size(opt_ha,1);
    p_farm = [repmat(best_rate, num_farms, 1), p_combo];         

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
    opt_payments = [zeros(num_farms,1) opt_payments];    
    
    [~, max_profit_col_idx] = max(opt_profits,[],2);
    
    change_ind = [];
    for i = 2:num_elm_options+1
        change_ind = [change_ind (max_profit_col_idx == i)];
    end
    
    %Benefits from profit maximising choice
    benefit_final = zeros(num_farms,1);
    farm_payment  = zeros(num_farms,1);
    opt_ha_prop   = zeros(num_farms,1);
    
    opt_ha_proportion = [zeros(num_farms,1) opt_ha_proportion];    
    
    for i = 1:num_farms
        benefit_final(i) = opt_bens(i,max_profit_col_idx(i));
        farm_payment(i)  = opt_payments(i,max_profit_col_idx(i));
        opt_ha_prop(i)   = opt_ha_proportion(i,max_profit_col_idx(i));
    end

    any_option_ind = any(change_ind, 2);

    opt_cells    = cell_ids(any_option_ind);
    opt_ha_prop  = opt_ha_prop(any_option_ind);
    farm_payment = farm_payment(any_option_ind);
    
    opt_cells     = [opt_cells, opt_ha_prop];
    
    option_choice = max_profit_col_idx(any_option_ind)-1;
    
end