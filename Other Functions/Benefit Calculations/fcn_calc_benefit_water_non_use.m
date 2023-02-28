function benefit_water_non_use_ann = fcn_calc_benefit_water_non_use(start_year, scheme_length, discount_constants, water_non_use_table)

    % Calculate the year in the 4 decades which relates to the end of the
    % current scheme, if the scheme ends after the fourth decade set to 40
    % and add extra annuity
    end_year = min(40, start_year + (scheme_length - 1));
    
    if (end_year < 40)
        % Return annuities in each decade as matrix
        % !!! this is hard coded to be a 5 year scheme !!!
        benefit_water_non_use_ann = [repmat(water_non_use_table.non_use_value_20, 1, 5) * discount_constants.delta_scheme_length * discount_constants.gamma_10, ...
                                     zeros(size(water_non_use_table.non_use_value_20)), ...
                                     zeros(size(water_non_use_table.non_use_value_20)), ...
                                     zeros(size(water_non_use_table.non_use_value_20))];
    else
        % Same as above, but use 2050's annuity for additional years
        benefit_water_non_use_ann = [water_non_use_table.non_use_value_20, ...
                                     water_non_use_table.non_use_value_30, ...
                                     water_non_use_table.non_use_value_40, ...
                                     water_non_use_table.non_use_value_50, ...
                                     water_non_use_table.non_use_value_50];
    end

end