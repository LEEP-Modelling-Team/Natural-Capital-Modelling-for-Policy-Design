function best_rate = fcn_find_warm_start(payment_mechanism_string, ...
                                            budget, ...
                                            elm_options, ...
                                            opp_costs, ... 
                                            benefits, ...
                                            env_outs, ...
                                            unit_value_max, ...
                                            max_rates)

    num_env_out = width(env_outs);
    num_farmers   = height(opp_costs);
    
    costs = opp_costs;
    
    fprintf('\n  Search for Benefit Maximising Payment Rates \n  ------------------------------------------- \n');
    fprintf('   num prices:  %.0f \n', num_env_out);  
    fprintf('   num farmers: %.0f \n', num_farmers); 
    
    constraintfunc = @(p) mycon_ES(p, env_outs, costs, budget, elm_options);
  
    % (2) Find maximum prices for each quantity
    % -----------------------------------------    
    % Adjusted maximum prices based on logic
    switch payment_mechanism_string
        case 'fr_env'
%             max_rates(1) = min(max_rates(1), unit_value_max.ghg);    % GHG
%             % 2:5 the 4 rec hectares are constrained by budget only
%             max_rates(6) = min(max_rates(6), unit_value_max.flood);  % flood
%             max_rates(7) = min(max_rates(7), unit_value_max.n);      % nitrate
%             max_rates(8) = min(max_rates(8), unit_value_max.p);      % phosphate
            if num_env_out == 10
                max_rates(10) = min(max_rates(10), unit_value_max.bio);    % biodiversity
            end
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
        env_outs_norm.(elm_options{i}) = env_outs(:, :, i).*ord_mag;
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
end