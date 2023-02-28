function [benefit_farm_ann, opp_cost_farm_ann] = fcn_calc_benefit_agriculture(start_year, scheme_length, discount_constants, baseline, es_agriculture)

    % Calculate the year in the 4 decades which relates to the end of the
    % current scheme, if the scheme ends after the fourth decade set to 40
    % and add extra annuity
    end_year = min(40, start_year + (scheme_length - 1));
    
    % Set farm profit equal to the baseline, but overwrite years 
    % start_year:end_year with new farm profit from es_agriculture
    farm_profit = baseline.farm_profit;
    farm_profit(:, start_year:end_year) = es_agriculture.farm_profit(:, start_year:end_year);
    
    % Calculate benefit from agriculture by taking subtracting baseline 
    % farm profit, discounting and turning into annuity
    benefit_farm_ann_20 = ((farm_profit(:, 1:10)  - baseline.farm_profit(:, 1:10))  * discount_constants.delta_10) * discount_constants.gamma_10;
    benefit_farm_ann_30 = ((farm_profit(:, 11:20) - baseline.farm_profit(:, 11:20)) * discount_constants.delta_10) * discount_constants.gamma_10;
    benefit_farm_ann_40 = ((farm_profit(:, 21:30) - baseline.farm_profit(:, 21:30)) * discount_constants.delta_10) * discount_constants.gamma_10;
    benefit_farm_ann_50 = ((farm_profit(:, 31:40) - baseline.farm_profit(:, 31:40)) * discount_constants.delta_10) * discount_constants.gamma_10;
    
    % Combine into a matrix
    if (end_year < 40)
        benefit_farm_ann = [benefit_farm_ann_20, benefit_farm_ann_30, benefit_farm_ann_40, benefit_farm_ann_50];
    else
        benefit_farm_ann_extra = farm_profit(:, 40) - baseline.farm_profit(:, 40);
        benefit_farm_ann = [benefit_farm_ann_20, benefit_farm_ann_30, benefit_farm_ann_40, benefit_farm_ann_50, benefit_farm_ann_extra];
    end
    
    % Opportunity cost for farm is absolute value of benefit
    opp_cost_farm_ann = abs(benefit_farm_ann);
    
end