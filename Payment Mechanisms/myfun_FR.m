function f = myfun_FR(p, ES, C, B, elm_option, netB_flag)

    % Determine which option each farmer would prefer at these prices
    profit  = zeros(length(C), length(elm_option) + 1);
    benefit = zeros(length(C), length(elm_option) + 1);
    spend = zeros(length(C), length(elm_option) + 1);
    
    % ELM option price indicator
    elm_pind = [1,0,0,0,0,0,0,0;...
                0,1,0,0,0,0,0,0,;...
                0,0,1,0,0,0,0,0;...
                0,0,0,1,0,0,0,0;...
                0,0,0,0,1,0,0,0;...
                0,0,0,0,0,1,0,0;...
                0,0,0,0,0,0,1,0;...
                0,0,0,0,0,0,0,1;...
                1,1,0,0,0,0,0,0;...
                1,0,0,1,0,0,0,0;...
                0,1,1,0,0,0,0,0;...
                0,0,1,1,0,0,0,0;...
                0,0,0,0,1,1,0,0;...
                0,0,0,0,1,0,0,1;...
                0,0,0,0,0,1,1,0;...
                0,0,0,0,0,0,1,1];
    
    elm_pind = elm_pind .* p;
    
    %Evaluate profit & cost for each option 
    for i = 1:length(elm_option)
        spend(:,i+1)  = elm_pind(i,:) * ES(:,1:8)';
        profit(:,i+1)  = elm_pind(i,:) * ES(:,1:8)' - C(:,i)';
        benefit(:,i+1) = B(:,i);
    end
    
    [~, max_profit_col_idx] = max(profit,[],2);
    
    benefit_final = zeros(size(C,1),1);
    spend_final = zeros(size(C,1),1);
    for i = 1:size(C,1)
        benefit_final(i) = benefit(i,max_profit_col_idx(i));
        spend_final(i) = spend(i,max_profit_col_idx(i));
    end
    
    if netB_flag
        f = -(sum(benefit_final) - sum(spend_final));
    else
        f = -sum(benefit_final);
    end
    
end