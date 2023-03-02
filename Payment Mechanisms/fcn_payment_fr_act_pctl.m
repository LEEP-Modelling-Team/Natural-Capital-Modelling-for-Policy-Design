function [prices, uptake, spend, fval] = fcn_payment_fr_act_pctl(b, c, q, budget, elm_options, pctl)

    % Calculate cost per hectare of each option
    % -----------------------------------------
    c_perha = c./q;
    c_perha(isinf(c_perha)) = inf;
    c_perha(isnan(c_perha)) = inf;

    % Prices at Percentile
    % --------------------
    prices = prctile(c_perha, pctl, 1);
        
    % Uptake and Benefits at those prices
    % -----------------------------------
    uptake   = myfun_uptake(prices, q, c, elm_options);    
    benefits = sum(b.*uptake, 2);
    spend    = sum(prices.*q.*uptake, 2);
    bc_ratio = benefits./spend; % benefits per £spend
    
    % Select most benefits in budget
    % ------------------------------
    [~, sortidx] = sort(bc_ratio, 'descend', 'MissingPlacement', 'last'); % sort from best to worst
    inbudget_ind = 1 - (cumsum(spend(sortidx)) >= budget);
    inbudget_ind(sortidx) = inbudget_ind;  % undo sort to find best in budget
    
    % Select most benefits in budget
    % ------------------------------
    uptake = uptake .* inbudget_ind;
    spend  = sum(prices.*q.*uptake, 'all');
    fval   = sum(b.*uptake, 'all'); 

end