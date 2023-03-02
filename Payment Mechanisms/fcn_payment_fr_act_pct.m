function [prices, pct] = fcn_payment_fr_act_pct(budget, ...
                                                elm_options, ...
                                                costs, ...
                                                elm_ha)

    % Calculate cost per hectare of each option
    costs_perha = costs ./ elm_ha;
    costs_perha(isinf(costs_perha)) = 0;
    costs_perha(isnan(costs_perha)) = 0;

    % Set up num_pct percentiles between pct_min and pct_max
    num_pct = 1000;
    pct_min = 1;
    pct_max = 50;
    pct_range = linspace(pct_min, pct_max, num_pct);

    % Calculate percentile of costs per hectare for each individual option
    price_pcts = prctile(costs_perha(:, 1:8), pct_range, 1);

    % Calculate budget surplus for each percentile of costs
    surplus_pcts = nan(num_pct, 1);
    for i = 1:num_pct
        surplus_pcts(i) = mycon_FR(price_pcts(i, :), elm_ha, costs, budget, elm_options);
    end

    % Find which percentile corresponds to smallest surplus
    [~, idx_min_surplus] = min(abs(surplus_pcts));

    % Return these prices and percentile
    prices = price_pcts(idx_min_surplus, :);
    pct = pct_range(idx_min_surplus);

end