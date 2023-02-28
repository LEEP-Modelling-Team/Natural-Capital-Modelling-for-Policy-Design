function [benefit_ghg_farm_ann, benefit_ghg_forestry_ann, benefit_ghg_soil_forestry_ann] = fcn_calc_benefit_ghg(start_year, scheme_length, discount_constants, carbon_price, baseline, es_agriculture, es_forestry, out)

    % Calculate the year in the 4 decades which relates to the end of the
    % current scheme, if the scheme ends after the fourth decade set to 40
    % and add _ann_50_plus
    end_year = min(40, start_year + (scheme_length - 1));
    
    % (1) Agriculture
    % ---------------
    % Set ghg emissions equal to the baseline, but overwrite years 
    % start_year:end_year with new ghg emissions from es_agriculture
    ghg_farm = baseline.ghg_farm;
    ghg_farm(:,start_year:end_year) = es_agriculture.ghg_farm(:,start_year:end_year);
    
    % Calculate benefit from ghg by taking subtracting baseline emissions,
    % multiplying by carbon price, discounting and turning into annuity
    benefit_ghg_farm_ann_20 = ((ghg_farm(:, 1:10)  - baseline.ghg_farm(:, 1:10)) * (carbon_price(1:10) .* discount_constants.delta_10)) * discount_constants.gamma_10;
    benefit_ghg_farm_ann_30 = ((ghg_farm(:, 11:20) - baseline.ghg_farm(:, 11:20)) * (carbon_price(11:20) .* discount_constants.delta_10)) * discount_constants.gamma_10;
    benefit_ghg_farm_ann_40 = ((ghg_farm(:, 21:30) - baseline.ghg_farm(:, 21:30)) * (carbon_price(21:30) .* discount_constants.delta_10)) * discount_constants.gamma_10;
    benefit_ghg_farm_ann_50 = ((ghg_farm(:, 31:40) - baseline.ghg_farm(:, 31:40)) * (carbon_price(31:40) .* discount_constants.delta_10)) * discount_constants.gamma_10;
    
    % Combine into a matrix
    if (end_year < 40)
        benefit_ghg_farm_ann = [benefit_ghg_farm_ann_20, benefit_ghg_farm_ann_30, benefit_ghg_farm_ann_40, benefit_ghg_farm_ann_50];
    else
        num_extra_years = scheme_length - 40 + start_year - 1;
        benefit_ghg_farm_ann_extra = (repmat(ghg_farm(:, 40) - baseline.ghg_farm(:, 40), 1, num_extra_years) * (carbon_price(41:(41 + num_extra_years - 1)) .* discount_constants.delta_extra)) * discount_constants.gamma_extra;
        benefit_ghg_farm_ann = [benefit_ghg_farm_ann_20, benefit_ghg_farm_ann_30, benefit_ghg_farm_ann_40, benefit_ghg_farm_ann_50, benefit_ghg_farm_ann_extra];
    end
    
    % (2) Forestry
    % ------------
    
    % Calculate forestry ghg annuity
    % For now use 60:40% mix of broad/conif
    benefit_ghg_forestry_ann = es_forestry.TimberC.ValAnn.Mix6040 - baseline.ghg_mixed_ann;
    
    % Calculate forestry soil ghg annuity
    % Baseline is zero here so no need to subtract
    benefit_ghg_soil_forestry_ann = out.ghg_soil_mixed_ann;

end