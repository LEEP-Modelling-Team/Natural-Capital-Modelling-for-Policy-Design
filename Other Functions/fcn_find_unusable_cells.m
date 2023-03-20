function unusable_cells = fcn_find_unusable_cells(q, c, budget, elm_options, prices_max, prices)
    
    % Constants
    % ---------
    num_farmers = size(c,1);
    num_options = size(c,2);
    num_prices  = length(prices_max);

    % Choose some test prices
    % -----------------------
    prices_test = diag(prices_max);
    if exist('prices', 'var')
       prices_test = [prices_test; prices'];
    end
    prices_test(isinf(prices_test)) = 0;
    
    uptake = zeros(num_farmers, num_options);
    for ii = 1:length(prices_test)
        uptake = uptake + myfun_uptake(prices_test(ii,:), q, c, elm_options);
    end
    unusable_cells = sum(uptake, 2) == 0; 

end