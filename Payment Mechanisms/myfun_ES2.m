function f = myfun_ES2(p, ES, C, bc, elm_option)

    % Determine which option each farmer would prefer at these prices
    profit = zeros(length(C),length(elm_option)+1);
    spend = zeros(length(C),length(elm_option)+1);
    % Evaluate income - costs for each option
      
    for i = 1:length(elm_option)
        profit(:,i+1) = p*ES.(elm_option{i})' - C(:,i)';
        spend(:,i+1)  = p*ES.(elm_option{i})';
    end
           
    [profit, Aind] = max(profit,[],2);
    
    spend_final = zeros(size(C,1),1);
    
    for i = 1:size(C,1)
        spend_final(i) = spend(i,Aind(i));
    end
    
    
    x = sum(spend_final) - bc;
    
    f = x^2;
    

end