function uptake = myfun_uptake(p, ES, C, elm_option)

    N  = length(C);
    Nq = length(elm_option);

    % Determine which option each farmer would prefer at these prices
    profit  = zeros(N, length(elm_option) + 1);
    
    % Evaluate profit & cost for each option 
    if isstruct(ES) 
        for i = 1:length(elm_option)
            profit(:, i + 1)  = p * ES.(elm_option{i})' - C(:, i)';
        end
    else
        for i = 1:length(elm_option)
            profit(:, i + 1) = p * ES(:, :, i)' - C(:, i)';
        end
    end
    
	% Find which option gives each farmer maximum profit
	% They will choose 'do nothing' if all profits are negative
    [~, max_profit_col_idx] = max(profit, [], 2);

    % uptake
    uptake = full(sparse(1:N, max_profit_col_idx, ones(N,1), N, Nq+1)); 
    
    % remove do-nothing option
    uptake = uptake(:,2:end);
    
end