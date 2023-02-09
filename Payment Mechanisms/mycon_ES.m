function [c, ceq] = mycon_ES(p, ES, C, budget, elm_option)

    % Determine which option each farmer would prefer at these prices
    profit = zeros(length(C), length(elm_option) + 1);
    spend  = zeros(length(C), length(elm_option) + 1);
	
    % Evaluate profit and spend for each option and farmer
    if isstruct(ES) 
        for i = 1:length(elm_option)
            profit(:, i + 1) = p * ES.(elm_option{i})' - C(:, i)';
            spend(:, i + 1)  = p * ES.(elm_option{i})';
        end
    else
        for i = 1:length(elm_option)
            profit(:, i + 1) = p * ES(:, :, i)' - C(:, i)';
            spend(:, i + 1)  = p * ES(:, :, i)';
        end
    end
	% Find which option gives each farmer maximum profit
	% They will choose 'do nothing' if all profits are negative
    [~, Aind] = max(profit, [], 2);
    
	% Calculate spend for each farmer under this option uptake
    spend_final = zeros(size(C, 1), 1);
    for i = 1:size(C, 1)
        spend_final(i) = spend(i, Aind(i));
    end   
    
	% Calculate margin (total spend - budget)
    c   = sum(spend_final) - budget;
    ceq = [];
    
end