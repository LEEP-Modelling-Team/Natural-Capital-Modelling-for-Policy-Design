% fcn_find_locopt_prices
% ======================

% Purpose
% -------
%  Search around starting feasible prices for local optimal prices

function [prices_locopt, benefits_locopt] = fcn_find_locopt_prices(budget, benefits, costs, q, elm_options, prices_max, prices_feas, benefits_feas, cnst_data, cnst_target, Ngood)

    
    % fprintf('\n  Refine Search in Feasible Parameter Space: ');
    % fprintf('\n  ----------------------------------------- \n');  
    
    N = 10000;
    Nq = size(q,2);
    
    old_best_benefit = -inf;
    new_best_benefit = 0;
    search_cnt = 0;
    
    while search_cnt < 3
        
        tic       
        % (1) Refine search around feasible starting point
        % ------------------------------------------------  
        [prices_good, benefits_good] = search_prices_latinHC(N, prices_feas, benefits_feas, Nq, prices_max, Ngood, q, costs, benefits, elm_options, budget, cnst_data, cnst_target);    
        if isempty(prices_good)
            prices_good   = zeros(1, Nq);
            benefits_good = 0;
        end
                
        % (2) Precise search around best parameters from grid search
        % ----------------------------------------------------------
        [prices_locopt, benefits_locopt] = search_prices_nonlin_opt(prices_good, benefits_good, prices_max, elm_options, q, costs, benefits, budget, cnst_data, cnst_target);
        tSolve = toc;
               
        prices_feas   = prices_locopt;
        benefits_feas = benefits_locopt;
        
        c = max(benefits_locopt);
        fprintf(['      benefits:       £' sprintf('%s', num2sepstr(c,  '%.0f')) '    %0.2f secs\n'], tSolve);  
        
        if old_best_benefit == c
            search_cnt = search_cnt + 1;
        else
            search_cnt = 0;
        end
        
        old_best_benefit = c;
        
    end
    
    % (3) Best rate
    % -------------
    fprintf('\n  Best prices: \n  ------------ \n');

    [max_best_benefits, max_best_benefits_idx] = max(benefits_locopt);
    prices_best  = prices_locopt(max_best_benefits_idx,:);
    benefit_best = benefits_locopt(max_best_benefits_idx,:);

    benefitfunc    = @(p) myfun_ES(p, q, costs, benefits, elm_options);
    constraintfunc = @(p) mycon_budget(p, q, costs, budget,   elm_options);

    fprintf(['      benefits:       £' sprintf('%s', num2sepstr(-benefitfunc(prices_best),   '%.0f')) '\n']);    
    fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(constraintfunc(prices_best),'%.0f')) '\n']);    
    fprintf( '      best price: £%.2f \n', prices_best);      
    
end


function [good_rates, good_benefits] = search_prices_latinHC(Ngsearch, prices_feas, benefits_feas, num_env_out, max_rates, num_good, env_outs, costs, benefits, elm_options, budget, cnst_data, cnst_target)
    
    % constraintfunc = @(p) mycon_budget(p, env_outs, costs, budget, elm_options);
    rough_rates    = prices_feas;
    rough_benefits = benefits_feas;
    
    LatinHC  = lhsdesign(Ngsearch, num_env_out);
    for jj = 1:size(prices_feas,1)
        % Set min and max range of Latin Hypercube for each env quant
        test_rates = LatinHC;
        for i = 1:num_env_out
%             triMode = prices_feas(jj,i);
%             triLo   = prices_feas(jj,i)/2;
%             triUp   = prices_feas(jj,i) + (max_rates(i) - prices_feas(jj,i))/2;
%             test_rates(:,i) = icdf('triangular', LatinHC(:,i), triLo, triMode, triUp);
            if ((prices_feas(jj,i) + prices_feas(jj,i)/2) > max_rates(i))
                test_rates(:,i) = prices_feas(jj,i)/2 + LatinHC(:,i) .* (max_rates(i) - prices_feas(jj,i)/2); % search space between 50% & max of feasible starting point
            else
                test_rates(:,i) = prices_feas(jj,i)/2 + LatinHC(:,i) .* prices_feas(jj,i); % search space between 50% & 150% of feasible starting point
            end
        end
        
        test_benefits = nan(Ngsearch,1);
        % fprintf('   Feasible price: %.0f \n', jj);  
        parfor i = 1:Ngsearch
            test_benefits(i) = -myfun_ES(test_rates(i, :), env_outs, costs, benefits, elm_options);
            if any(mycon_budget_bio(test_rates(i,:), env_outs, costs, budget, elm_options, cnst_data, cnst_target) > 0) % constraint violation
                test_benefits(i) = 0;
            end
        end       
        
        [maxbenefits, maxbenefitsidx] = max(test_benefits);
        % fprintf(['      benefits:       £' sprintf('%s', num2sepstr(maxbenefits,  '%.0f')) '\n']);    
        % fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(constraintfunc(test_rates(maxbenefitsidx,:)),'%.0f')) '\n']);    
        if maxbenefits > 0
            [max_test_benefits, max_test_benefits_idx] = sort(test_benefits, 'descend');
            max_test_benefits_idx = max_test_benefits_idx(max_test_benefits > 0);
            rough_rates    = [rough_rates;    test_rates(max_test_benefits_idx(1:min(100,length(max_test_benefits_idx))),:)];
            rough_benefits = [rough_benefits; test_benefits(max_test_benefits_idx(1:min(100,length(max_test_benefits_idx))))];
        end
    end
    
    rough_rates_round = rough_rates./mean(rough_rates);
    rough_rates_round = round(rough_rates_round, 4);
    [rough_rates_round, unique_idx] = unique(rough_rates_round, 'rows');    
    rough_rates    = rough_rates(unique_idx, :);
    rough_benefits = rough_benefits(unique_idx);

    [max_rough_benefits, max_rough_benefits_idx] = sort(rough_benefits, 'descend');
    good_rates    = rough_rates(max_rough_benefits_idx(1:min(num_good,length(max_rough_benefits_idx))),:);
    good_benefits = rough_benefits(max_rough_benefits_idx(1:min(num_good,length(max_rough_benefits_idx))));
    
end


function [best_rates, best_benefits] = search_prices_nonlin_opt(good_rates, good_benefits, max_rates, elm_options, env_outs, costs, benefits, budget, cnst_data, cnst_target)

    %fprintf('\n  Precise Minimisation from Best Parameters: \n  ------------------------------------------ \n');
    num_env_out = size(env_outs,2);
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
    % constraintfunc = @(p) mycon_budget(p, env_outs_norm, costs, budget,   elm_options);
    constraintfunc = @(p) mycon_budget_bio(p, env_outs_norm, costs, budget, elm_options, cnst_data, cnst_target);
    options = optimoptions('patternsearch', 'Display', 'none');


    for jj = 1:size(good_rates,1)
        % optimiser call
        %[fmin_rate, fmin_benefit] = fmincon(benefitfunc, good_rates(jj,:),[],[],[],[],zeros(1,num_env_out),[],constraintfunc,[]);
        [fmin_rate, fmin_benefit] = patternsearch(benefitfunc, good_rates(jj,:),[],[],[],[],zeros(1,num_env_out),max_rates_org,constraintfunc,options);
        %f printf(['      benefits:       £' sprintf('%s', num2sepstr(-benefitfunc(fmin_rate),   '%.0f')) '\n']);    
        % fprintf(['      budget surplus: £' sprintf('%s', num2sepstr(constraintfunc(fmin_rate),'%.0f')) '\n']);    
        % rescale parameters
        best_rates    = [best_rates; fmin_rate.*ord_mag];
        best_benefits = [best_benefits; -fmin_benefit];
    end
    
    best_rates_round = best_rates./mean(best_rates);
    best_rates_round = round(best_rates_round, 4);
    [best_rates_round, unique_idx] = unique(best_rates_round, 'rows');    
    best_rates    = best_rates(unique_idx, :);
    best_benefits = best_benefits(unique_idx);
    
    
    [max_best_benefits, max_best_benefits_idx] = sort(best_benefits, 'descend');
    best_rates    = best_rates(max_best_benefits_idx,:);
    best_benefits = best_benefits(max_best_benefits_idx,:);   

end