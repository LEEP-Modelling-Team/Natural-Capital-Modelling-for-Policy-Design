function [opt_cells, option_choice, best_rate] = fcn_payment_fr_env_es(payment_mechanism_string, budget, markup, elm_options, cell_ids, opp_costs, benefits, env_outs, unit_value_max)

    num_env_out = size(env_outs.(elm_options{1}), 2);
    num_farmers   = size(env_outs.(elm_options{1}), 1);
    
    costs = opp_costs * markup;

    benefitfunc    = @(p) myfun_ES(p, env_outs, costs, benefits, elm_options);
    constraintfunc = @(p) mycon_ES(p, env_outs, costs, budget,   elm_options);
    
%     % Test: set all flat rates to be the same
%     x = 0.01:0.01:1;
%     temp_benefits = zeros(length(x), 1);
%     temp_constraint = zeros(length(x), 1);
%     for i = 1:length(x)
%         p = repmat(x(i), 1, num_env_out);
%         temp_benefits(i) = -myfun_ES(p, env_outs, costs, benefits, elm_options);
%         temp_constraint(i) = mycon_ES(p, env_outs, costs, budget, elm_options);
%     end
%     
%     idx = sum(temp_constraint < 0);
%     y = x(idx):0.0001:x(idx + 1);
%     temp_benefits2 = zeros(length(y), 1);
%     temp_constraint2 = zeros(length(y), 1);
%     for i = 1:length(y)
%         p = repmat(y(i), 1, num_env_out);
%         temp_benefits2(i) = -myfun_ES(p, env_outs, costs, benefits, elm_options);
%         temp_constraint2(i) = mycon_ES(p, env_outs, costs, budget, elm_options);
%     end
%     
%     idx2 = sum(temp_constraint2 < 0);
%     print(y(idx2));
    
    fprintf('\n  Search for Benefit Maximising Payment Rates \n  ------------------------------------------- \n');
    fprintf('   num prices:  %.0f \n', num_env_out);  
    fprintf('   num farmers: %.0f \n', num_farmers);  
  
    % (2) Find maximum prices for each quantity
    % -----------------------------------------
    max_rates = zeros(1, num_env_out);
    start_rate = 5;
    env_outs_array = struct2array(env_outs);
    for i = 1:num_env_out
        env_outs_array_i = env_outs_array(:, i:num_env_out:(16*num_env_out));
        if sum(sum(env_outs_array_i)) == 0
            % If there are no benefits/quantities across all options then
            % keep max_rate at zero
            continue
        end
        max_rates(i) = fcn_lin_search(num_env_out,i,start_rate,0.01,constraintfunc,env_outs,costs,budget,elm_options);
    end
    
    % Adjusted maximum prices based on logic
    switch payment_mechanism_string
        case 'fr_env'
            max_rates(1) = min(max_rates(1), unit_value_max.ghg);    % GHG
            % 2:5 the 4 rec hectares are constrained by budget only
            max_rates(6) = min(max_rates(6), unit_value_max.flood);  % flood
            max_rates(7) = min(max_rates(7), unit_value_max.n);      % nitrate
            max_rates(8) = min(max_rates(8), unit_value_max.p);      % phosphate
            max_rates(10) = min(max_rates(10), unit_value_max.bio);    % biodiversity
        case 'fr_es'
            % We don't want to pay more than £1 for £1 benefit
            max_rates = ones(1, num_env_out);
        otherwise
            error('ELM option not found.')
    end

    % (3) Find a decent starting point
    % --------------------------------
    fprintf('\n  Rough Search of Parameter Space: \n  ------------------------------- \n');
    feasible_rates    = [];
    feasible_benefits = [];
    Ngsearch = 15000;
    LatinHC  = lhsdesign(Ngsearch, num_env_out);
    for jj = 1:5
        max_rates_jj  = max_rates/jj; 
        test_rates = LatinHC .* max_rates_jj;
        test_benefits = nan(Ngsearch,1);
        fprintf('   iteration: %.0f \n', jj);  
        parfor i = 1:Ngsearch
            test_benefits(i) = -myfun_ES(test_rates(i, :), env_outs, costs, benefits, elm_options);
            if myfun_ESspend(test_rates(i,:), env_outs, costs, budget, elm_options) > 0 % overspend!
                test_benefits(i) = 0;
            end
        end
        [maxbenefits, maxbenefitsidx] = max(test_benefits);
        fprintf(['      benefits:       £' sprintf('%s', num2sepstr(maxbenefits,  '%.0f')) '\n']);    
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
    
    % (2) Refine search around feasible starting point
    % ----------------------------------------------
    fprintf('\n  Refine Search in Feasible Parameter Space: \n  ----------------------------------------- \n');
   
    rough_rates    = feasible_rates;
    rough_benefits = feasible_benefits;
    
    Ngsearch = 1000;
    LatinHC  = lhsdesign(Ngsearch, num_env_out);
    
    for jj = 1:size(feasible_rates,1)
        % Set min and max range of Latin Hypercube for each env quant
        test_rates = LatinHC;
        for i = 1:num_env_out
            if ((feasible_rates(jj,i) + feasible_rates(jj,i)/2) > max_rates(i))
                test_rates(:,i) = LatinHC(:,i) .* (max_rates(i) - feasible_rates(jj,i)/2) + feasible_rates(jj,i)/2; % search space between 50% & max of feasible starting point
            else
                test_rates(:,i) = LatinHC(:,i) .* feasible_rates(jj,i) + feasible_rates(jj,i)/2; % search space between 50% & 150% of feasible starting point
            end
        end
        test_benefits = nan(Ngsearch,1);
        fprintf('   Feasible price: %.0f \n', jj);  
        parfor i = 1:Ngsearch
            test_benefits(i) = -myfun_ES(test_rates(i, :), env_outs, costs, benefits, elm_options);
            if myfun_ESspend(test_rates(i,:), env_outs, costs, budget, elm_options) > 0 % overspend!
                test_benefits(i) = 0;
            end
        end
        [maxbenefits, maxbenefitsidx] = max(test_benefits);
        fprintf(['      benefits:       £' sprintf('%s', num2sepstr(maxbenefits,  '%.0f')) '\n']);    
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
    
    % (3) Precise search around best parameters from grid search
    % ----------------------------------------------------------
    fprintf('\n  Precise Minimisation from Best Parameters: \n  ------------------------------------------ \n');

    best_rates    = good_rates;
    best_benefits = good_benefits;
   
    % normalise data & parameters
    ord_mag = 10.^floor(log(abs(mean(good_rates)))./log(10));
    good_rates = good_rates./ord_mag;
    for i = 1:length(elm_options)
        env_outs_norm.(elm_options{i}) = env_outs.(elm_options{i}).*ord_mag;
    end
    max_rates_org = max_rates ./ ord_mag;
    max_rates_org(isnan(max_rates_org)) = 0;

    benefitfunc    = @(p) myfun_ES(p, env_outs_norm, costs, benefits, elm_options);
    constraintfunc = @(p) mycon_ES(p, env_outs_norm, costs, budget,   elm_options);

    for jj = 1:size(good_rates,1)
        % optimiser call
        %[fmin_rate, fmin_benefit] = fmincon(benefitfunc, good_rates(jj,:),[],[],[],[],zeros(1,num_env_out),[],constraintfunc,[]);
        [fmin_rate, fmin_benefit] = patternsearch(benefitfunc, good_rates(jj,:),[],[],[],[],zeros(1,num_env_out),max_rates_org,constraintfunc,[]);
        fprintf(['      benefits:       £' sprintf('%s', num2sepstr(-benefitfunc(fmin_rate),   '%.0f')) '\n']);    
        fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(constraintfunc(fmin_rate),'%.0f')) '\n']);    
        % rescale parameters
        best_rates    = [best_rates; fmin_rate.*ord_mag];
        best_benefits = [best_benefits; -fmin_benefit];
    end
    
    % (4)  Best rate
    % --------------
    fprintf('\n  Best prices: \n  ------------ \n');

    [max_best_benefits, max_best_benefits_idx] = max(best_benefits);
    best_rate     = best_rates(max_best_benefits_idx,:);
    best_benefit = best_benefits(max_best_benefits_idx,:);

    benefitfunc    = @(p) myfun_ES(p, env_outs, costs, benefits, elm_options);
    constraintfunc = @(p) mycon_ES(p, env_outs, costs, budget,   elm_options);

    fprintf(['      benefits:       £' sprintf('%s', num2sepstr(-benefitfunc(best_rate),   '%.0f')) '\n']);    
    fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(constraintfunc(best_rate),'%.0f')) '\n']);    
    fprintf( '      best price: £%.2f \n', best_rate);      
        
    % Choose Random Set of Prices to Clear Budget
    %flat_rates = fmincon(@(p) myfun_ES2(p, env_outs, costs, budget, elm_options),flat_rate0,[],[],[],[],zeros(1,num_env_out),[],[],[]);
    
    % Calculate which and how many farms take up options
    [change_ind, option_idx, spend] = fcn_get_farmer_uptake_logic_fr_env_es(best_rate, env_outs, costs, elm_options);

    any_option_ind = any(change_ind, 2);

    opt_cells = cell_ids(any_option_ind);
    
    % Using whole cells so add column of proportions with 1 in 
    opt_cells = [opt_cells, ones(length(opt_cells), 1)];
    
    option_choice = option_idx(any_option_ind)-1;
    
end