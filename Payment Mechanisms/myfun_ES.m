function f = myfun_ES(p, ES, C, B, elm_option)

    % Determine which option each farmer would prefer at these prices
    profit  = zeros(length(C), length(elm_option) + 1);
    benefit = zeros(length(C), length(elm_option) + 1);
    
    % Evaluate profit & cost for each option 
    % Evaluate profit and spend for each option and farmer
    if isstruct(ES) 
        for i = 1:length(elm_option)
            profit(:, i + 1)  = p * ES.(elm_option{i})' - C(:, i)';
            benefit(:, i + 1) = B(:, i);
        end
    else
        for i = 1:length(elm_option)
            profit(:, i + 1) = p * ES(:, :, i)' - C(:, i)';
            benefit(:, i + 1)  = p * ES(:, :, i)';
        end
    end
    
	% Find which option gives each farmer maximum profit
	% They will choose 'do nothing' if all profits are negative
    [~, max_profit_col_idx] = max(profit, [], 2);
    
	% Calculate benefits for each farmer under this option uptake
    benefit_final = zeros(size(C, 1), 1);
    for i = 1:size(C, 1)
        benefit_final(i) = benefit(i, max_profit_col_idx(i));
    end
    
	% Calculate total benefits, return negative for minimisation
    f = -sum(benefit_final);

end