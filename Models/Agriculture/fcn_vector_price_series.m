function price_vector = fcn_vector_price_series(price_series,years)
%FCN_CHECK_PRICE_SERIES Check price series input in parameter field in fcn_run_agriculture
% Author: Frankie Cho
% Modified: 14/10/2021
% 
% Inputs
% price_series: a vector or scalar price series
% years: number of years

% Note: number of years is added by one, because the first year are prices
% before the start year


if (isscalar(price_series))
    price_vector = ones(years,1) * price_series;
    return;
end

if (size(price_series,1) ~= years)
    error("Length of vector price series do not match number of years + 1. Make sure the vector is a column vector and the length of the vector prices is equal to parameter.num_years+1.");
else
    price_vector = price_series;
end

end