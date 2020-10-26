function [opt_cells, ...
            option_choice, ...
            farm_payment, ...
            best_rate] = fcn_payment_fr_act(payment_mechanism_string, ...
                                            budget, ...
                                            markup, ...
                                            elm_options, ...
                                            cell_ids, ...
                                            opp_costs, ...
                                            benefits, ...
                                            elm_ha)
    %% (1) Set up
    %  ==========
    % Calculate number of prices and farmers
    num_prices = 8; % fixed at 8
    num_farmers = size(elm_ha, 1);
    
    % Inflate costs by markup
    costs = opp_costs * markup;

    % Print initialisation
    fprintf('\n  Search for Benefit Maximising Payment Rates \n  ------------------------------------------- \n');
    fprintf('   num prices:  %.0f \n', num_prices);  
    fprintf('   num farmers: %.0f \n', num_farmers);  
  
%     %% (2) Find maximum prices for each quantity
%     %  =========================================
%     max_rates = zeros(1, num_prices);
%     start_rate = 5;
%     for i = 1:num_prices
%         max_rates(i) = fcn_lin_search(num_prices,i,start_rate,0.01,constraintfunc,elm_ha,costs,budget,elm_options);
%     end
    
%     % Overwrite max rates with those calculated by Mattia
%     if budget == 1e+9
%         max_rates = [2523.2	1399.6 14691.9 6253.6 1948.8 895.9 14047.6 5733.2];
%     elseif budget == 2e+9
%         max_rates = [2571.2	1707.2 14823.4 6755.1 1994.8 1092.8	14199.5	6290.9];
%     elseif budget == 3e+9
%         max_rates = [2602.3	1843.4 14900.7 7367.8 2021.8 1244.9	14280.1	6842.7];
%     else
%         error('Budget not found.')
%     end
    
    %% (2) Calculate limits on prices
    %  ==============================
    % Find minimum and maximum per ha flat rate on activity possible to
    % constrain the optimisation. Two approaches used:
    % 1. Constrained by budget. Maximum flat rate under each option to
    %    spend entire budget. Minimum flat rate under each option to elicit
    %    participitation. 
    % 2. Constrained by positive net benefits. Maximum flat rate under each
    %    option is that which delivers largest positive net benefits.
    %    Minimum flat rate under each option is that which delivers first
    %    positive net benefit. 
    
    % Extract hectares/costs/benefits for main 8 options
    % Derive per hectare costs for each farmer
    elm_ha_full = elm_ha(:, 1:num_prices);
    costs_full = costs(:, 1:num_prices);
    benefits_full = benefits(:, 1:num_prices);
    costs_perha_full = costs_full ./ elm_ha_full;
    
    % Preallocate vectors to store minimum/maximise rates, plus spend and
    % net/total benefits
    min_netB_rates = zeros(1, num_prices);
    max_netB_rates = zeros(1, num_prices);
    max_netB_spend = zeros(1, num_prices);
    max_netB       = zeros(1, num_prices);
    
    min_totB_rates = zeros(1, num_prices);
    max_totB_rates = zeros(1, num_prices);
    max_totB_spend = zeros(1, num_prices);
    max_totB       = zeros(1, num_prices);
    
    % For each option, calculate minimum/maximum rates
    for k = 1:8
        % Set up array with costs per ha, hectares and benefits
        % Order by per ha costs smallest to largest
        cb = [costs_perha_full(:, k), elm_ha_full(:, k), benefits_full(:, k)];
        cb(any(isinf(cb),2), :) = [];
        cb(any(isnan(cb),2), :) = [];
        cb = sortrows(cb, 1);

        % Extract sorted costs per ha, hectares and benefits
        costs_perha_k = cb(:, 1);
        elm_ha_k = cb(:, 2);
        benefits_k = cb(:, 3); 
        
        % Calculate spend, net benefits and total benefits under each price
        elm_ha_cumsum_k = cumsum(elm_ha_k);
        spend_k = elm_ha_cumsum_k .* costs_perha_k;
        benefits_cumsum_k = cumsum(benefits_k);
        netB_k  = benefits_cumsum_k - spend_k;

        % Extract all rates/spend/benefits/net benefits where spend is less than budget
        ind_spend = spend_k < budget;
        spend_k = spend_k(ind_spend);
        costs_perha_k  = costs_perha_k(ind_spend);
        benefits_cumsum_k = benefits_cumsum_k(ind_spend);
        netB_k = netB_k(ind_spend);
        
        % Min/max rates constrained by budget
        % -----------------------------------
        % Minimum price to elicit option
        min_totB_rates(k) = min(costs_perha_k) - 1;
        
        % Price that clears the budget
        max_totB_rates(k) = max(costs_perha_k);
        
        % Also store largest total benefits and spend possible
        max_totB(k) = max(benefits_cumsum_k);
        max_totB_spend(k) = max(spend_k);
        
        % Min/max rates constrained by net benefit
        % ----------------------------------------
        % Minimum price to elicit option
        idx_min = find(netB_k > 0, 1, 'first');
        if ~isempty(idx_min)
            min_netB_rates(k) = costs_perha_k(idx_min);
        end
        
        % Price that delivers most net benefit (benefit - spend)
        [max_netB(k), idx_max] = max(netB_k);   % Also store largest net benefit
        if max(netB_k) > 0
            max_netB_rates(k) = costs_perha_k(idx_max);
            max_netB_spend(k) = spend_k(idx_max);
        end
        
    end
    
    %% (3) Determine type of optimisation
    %  ==================================
    % If it is possible to spend full budget under option 2, then use these
    % limits and maximise net benefits in optimisation. If it is not
    % possible, then use limits from option 1 and maximise total benefits
    % in optimisation.
    
    % Calculate if it is possible to spend budget under net benefit maximisation
    % Find largest individual arable and grazing option spend
    max_arable_spend = max(max_netB_spend(:, [1, 3, 5, 7]));
    max_grazing_spend = max(max_netB_spend(:, [2, 4, 6, 8]));
    max_spend = max_arable_spend + max_grazing_spend;
    
    % Set net benefit optimisation flag
    if max_spend > budget
        % If true we maximise net benefits using net benefit price limits
        netB_flag = true;
        min_rates = min_netB_rates;
        max_rates = max_netB_rates;
    else
        % If false we maximise total benefits using budget price limits
        netB_flag = false;
        min_rates = min_totB_rates;
        max_rates = max_totB_rates;
    end
    
    % Or hard code the type of optimisaation
    % (remember to comment out!)
    netB_flag = false;
%     netB_flag = true;
    min_rates = min_totB_rates;
    max_rates = max_totB_rates;
%     min_rates = min_netB_rates;
%     max_rates = max_netB_rates;
    
    benefitfunc    = @(p) myfun_FR(p, elm_ha, costs, benefits, elm_options, netB_flag);
    constraintfunc = @(p) mycon_FR(p, elm_ha, costs, budget,   elm_options);
    
    %% (4) Find a decent starting point
    %  ================================
    fprintf('\n  Rough Search of Parameter Space: \n  ------------------------------- \n');
    feasible_rates    = [];
    feasible_benefits = [];
    
    test_rates_1price = diag(max_rates);
    
    % Method 1: Maximise Benefits ST not exceed budget
    % ------------------------------------------------
    Ngsearch = 15000;
    LatinHC  = lhsdesign(Ngsearch, num_prices);
    for jj = 1:5
        % max_rates_jj  = max_rates/jj; 
        % test_rates = LatinHC .* max_rates_jj;
        
        max_rates_jj = min_rates + (max_rates - min_rates)/jj; 
        test_rates   = min_rates + LatinHC .* (max_rates_jj - min_rates);
        
        if jj == 1
           test_rates = [test_rates_1price; test_rates];
           Ngsearch_jj = Ngsearch + 8;
%             Ngsearch_jj = Ngsearch;
        else
            Ngsearch_jj = Ngsearch;
        end 
        
        test_benefits = nan(Ngsearch_jj,1);
        fprintf('   iteration: %.0f \n', jj);  
        parfor i = 1:Ngsearch_jj
            test_benefits(i) = -myfun_FR(test_rates(i, :), elm_ha, costs, benefits, elm_options, netB_flag);
            if myfun_FRspend(test_rates(i,:), elm_ha, costs, budget, elm_options) > 0 % overspend!
                test_benefits(i) = 0;
            end
        end
        [maxbenefits, maxbenefitsidx] = max(test_benefits);
        if netB_flag
            fprintf(['      net benefits:   £' sprintf('%s', num2sepstr(maxbenefits,  '%.0f')) '\n']);  
        else
            fprintf(['      benefits:       £' sprintf('%s', num2sepstr(maxbenefits,  '%.0f')) '\n']);  
        end
        fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(constraintfunc(test_rates(maxbenefitsidx,:)),'%.0f')) '\n']);    
        if maxbenefits > 0
            [max_test_benefits, max_test_benefits_idx] = sort(test_benefits, 'descend');
            max_test_benefits_idx = max_test_benefits_idx(max_test_benefits > 0);
            feasible_rates    = [feasible_rates;    test_rates(max_test_benefits_idx(1:min(10,length(max_test_benefits_idx))),:)];
            feasible_benefits = [feasible_benefits; test_benefits(max_test_benefits_idx(1:min(10,length(max_test_benefits_idx))))];
            if size(feasible_rates,1)>20
                break;
            end
        end
    end
    
    %% (5) Refine search around feasible starting point
    %  ================================================
    fprintf('\n  Refine Search in Feasible Parameter Space: \n  ----------------------------------------- \n');
   
    rough_rates    = feasible_rates;
    rough_benefits = feasible_benefits;
    
    Ngsearch = 1000;
    LatinHC  = lhsdesign(Ngsearch, num_prices);
    
    for jj = 1:size(feasible_rates,1)
        % Set min and max range of Latin Hypercube for each env quant
        test_rates = LatinHC;
        for i = 1:num_prices
            if ((feasible_rates(jj,i) + feasible_rates(jj,i)/2) > max_rates(i))
                test_rates(:,i) = LatinHC(:,i) .* (max_rates(i) - feasible_rates(jj,i)/2) + feasible_rates(jj,i)/2; % search space between 50% & max of feasible starting point
            else
                test_rates(:,i) = LatinHC(:,i) .* feasible_rates(jj,i) + feasible_rates(jj,i)/2; % search space between 50% & 150% of feasible starting point
            end
        end
        test_benefits = nan(Ngsearch,1);
        fprintf('   Feasible price: %.0f \n', jj);  
        parfor i = 1:Ngsearch
            test_benefits(i) = -myfun_FR(test_rates(i, :), elm_ha, costs, benefits, elm_options, netB_flag);
            if myfun_FRspend(test_rates(i,:), elm_ha, costs, budget, elm_options) > 0 % overspend!
                test_benefits(i) = 0;
            end
        end
        [maxbenefits, maxbenefitsidx] = max(test_benefits);
        if netB_flag
            fprintf(['      net benefits:   £' sprintf('%s', num2sepstr(maxbenefits,  '%.0f')) '\n']);
        else
            fprintf(['      benefits:       £' sprintf('%s', num2sepstr(maxbenefits,  '%.0f')) '\n']);
        end
        fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(constraintfunc(test_rates(maxbenefitsidx,:)),'%.0f')) '\n']);    
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
    
    %% (6) Precise search around best parameters from grid search
    %  ==========================================================
    fprintf('\n  Precise Minimisation from Best Parameters: \n  ------------------------------------------ \n');

    best_rates    = good_rates;
    best_benefits = good_benefits;
   
%     % normalise data & parameters
%     ord_mag = 10.^floor(log(abs(mean(good_rates)))./log(10));
%     ord_mag = max(ord_mag);
%     good_rates = good_rates./ord_mag;
%     %for i = 1:length(elm_options)
%         %elm_ha_norm.(elm_options{i}) = elm_ha.(elm_options{i}).*ord_mag;
%         elm_ha_norm = elm_ha.*ord_mag;
%     %end

    ord_mag = 1;
    for jj = 1:size(good_rates,1)
        % optimiser call
        %[fmin_rate, fmin_benefit] = fmincon(benefitfunc, good_rates(jj,:),[],[],[],[],zeros(1,num_prices),[],constraintfunc,[]);
        [fmin_rate, fmin_benefit] = patternsearch(benefitfunc, good_rates(jj,:),[],[],[],[],zeros(1,num_prices),max_rates ./ ord_mag,constraintfunc,[]);
        fprintf(['      benefits:       £' sprintf('%s', num2sepstr(-myfun_FR(fmin_rate.*ord_mag, elm_ha, costs, benefits, elm_options, false),   '%.0f')) '\n']);
        fprintf(['      net benefits:   £' sprintf('%s', num2sepstr(-myfun_FR(fmin_rate.*ord_mag, elm_ha, costs, benefits, elm_options, true),   '%.0f')) '\n']);
        fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(constraintfunc(fmin_rate.*ord_mag),'%.0f')) '\n']);    
        % rescale parameters
        best_rates    = [best_rates; fmin_rate.*ord_mag];
        best_benefits = [best_benefits; -fmin_benefit];
    end
    
    %% (7)  Best rate
    %  ==============
    fprintf('\n  Best prices: \n  ------------ \n');

    [max_best_benefits, max_best_benefits_idx] = max(best_benefits);
    best_rate     = best_rates(max_best_benefits_idx,:);
    best_benefit = best_benefits(max_best_benefits_idx,:);

    fprintf(['      benefits:       £' sprintf('%s', num2sepstr(-myfun_FR(best_rate, elm_ha, costs, benefits, elm_options, false),   '%.0f')) '\n']);
    fprintf(['      net benefits:   £' sprintf('%s', num2sepstr(-myfun_FR(best_rate, elm_ha, costs, benefits, elm_options, true),   '%.0f')) '\n']);
    fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(constraintfunc(best_rate),'%.0f')) '\n']);    
    fprintf( '      best price: £%.2f \n', best_rate);
    
    % Calculate which and how many farms take up options
    [change_ind, option_idx, farm_payment] = fcn_get_farmer_uptake_logic_fr_act(best_rate, elm_ha, costs, elm_options);

    any_option_ind = any(change_ind, 2);

    opt_cells = cell_ids(any_option_ind);
    
    % Using whole cells so add column of proportions with 1 in 
    opt_cells = [opt_cells, ones(length(opt_cells), 1)];
    
    option_choice = option_idx(any_option_ind)-1;
    
end