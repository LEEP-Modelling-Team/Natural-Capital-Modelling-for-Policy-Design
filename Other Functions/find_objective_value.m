function benefits = find_objective_value(prices, q, c, b, budget, elm_options)
    benefits = myfun_ES(prices, q, c, b, elm_options);
    if myfun_ESspend(prices, q, c, budget, elm_options) > 0 % overspend!
        benefits = +inf;
    end
end