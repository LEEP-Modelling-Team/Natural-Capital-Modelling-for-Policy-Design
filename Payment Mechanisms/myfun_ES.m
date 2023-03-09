function f = myfun_ES(p, q, costs, benefits, elm_option)

    % Determine which option each farmer would prefer at these prices
    profit  = zeros(length(costs), length(elm_option) + 1);
    benefit = zeros(length(costs), length(elm_option) + 1);
    
    % Evaluate profit & cost for each option 
    % Evaluate profit and spend for each option and farmer
    if isstruct(q) 
        for i = 1:length(elm_option)
            profit(:, i + 1)  = p * q.(elm_option{i})' - costs(:, i)';
            benefit(:, i + 1) = benefits(:, i);
        end
    else
        for i = 1:length(elm_option)
            profit(:, i + 1) = p * q(:, :, i)' - costs(:, i)';
            benefit(:, i + 1)  = benefits(:, i);
        end
    end
    
	% Find which option gives each farmer maximum profit
	% They will choose 'do nothing' if all profits are negative
    [~, max_profit_col_idx] = max(profit, [], 2);
    
	% Calculate benefits for each farmer under this option uptake
    benefit_final = zeros(size(costs, 1), 1);
    for i = 1:size(costs, 1)
        benefit_final(i) = benefit(i, max_profit_col_idx(i));
    end
    
	% Calculate total benefits, return negative for minimisation
    f = -sum(benefit_final);

end