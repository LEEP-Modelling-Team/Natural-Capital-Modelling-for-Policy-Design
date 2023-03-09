function x = myfun_ESspend(p, ES, C, budget, elm_option)

    % Determine which option each farmer would prefer at these prices
    profit = zeros(length(C),length(elm_option)+1);
    spend  = zeros(length(C),length(elm_option)+1);
    
    % Evaluate profit & costs for each option  
    for i = 1:length(elm_option)
        if isstruct(ES)
            payment       = p*ES.(elm_option{i})';
            profit(:,i+1) = payment - C(:,i)';
            spend(:,i+1)  = payment;
        else
            payment       = p*ES(:, :, i)';
            profit(:,i+1) = payment - C(:,i)';
            spend(:,i+1)  = payment;            
        end
    end
           
    [~, max_profit_col_idx] = max(profit,[],2);
    
    spend_final = zeros(size(C,1),1);
    
    for i = 1:size(C,1)
        spend_final(i) = spend(i,max_profit_col_idx(i));
    end
    
    x = sum(spend_final) - budget;    

end