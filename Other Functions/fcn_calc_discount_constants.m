function discount_constants = fcn_calc_discount_constants(discount_rate)

    % Set up a range of useful constants to NPV and annuity calculations
    % over 10 year and 40 year periods
    
    %% 1. Discount vectors (delta)
    %  ---------------------------
    % For turning 10/40 year vectors into NPVs
    discount_constants.delta_10 = 1 ./ ((1 + discount_rate) .^ (1:10))';
    discount_constants.delta_40 = 1 ./ ((1 + discount_rate) .^ (1:40))';
    
    %% 2. Discount decade
    %  ------------------
    % For turning decadal (2020s, 2030s, 2040s, 2050s) averages into NPVs
    discount_constants.discount_decade = sum(reshape(discount_constants.delta_40, [10, 4]), 1)';
    
    %% 3. Annuity constants (gamma)
    %  ----------------------------
    % For turning NPVs into annual equivalents across 10/40 year periods
    discount_constants.gamma_10 = discount_rate / (1 - (1 + discount_rate) ^ (-10));
    discount_constants.gamma_40 = discount_rate / (1 - (1 + discount_rate) ^ (-40));
    
end
