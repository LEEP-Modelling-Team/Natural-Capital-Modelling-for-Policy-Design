function quantity_ghg = fcn_calc_quantity_ghg(start_year, end_year, num_extra_years, baseline, es_agriculture, out)

    % Extend baseline and scenario food predictions to incorporate extra 
    % years by repeating final year num_extra_year times
    % (has no effect if num_extra_years is 0)
    baseline_ghg_farm = [baseline.ghg_farm, repmat(baseline.ghg_farm(:, 40), 1, num_extra_years)];
    scenario_ghg_farm = [es_agriculture.ghg_farm, repmat(es_agriculture.ghg_farm(:, 40), 1, num_extra_years)];
    
    % Subtract baseline from scenario in between start and end year of
    % scheme
    diff_ghg_farm = scenario_ghg_farm(:, start_year:end_year) - baseline_ghg_farm(:, start_year:end_year);
    quantity_ghg_farm = sum(diff_ghg_farm, 2);
    
    % Calculate forestry ghg annuity
    % For now use 60:40% mix of broad/conif
    % !!! upper bound (UB) on forestry GHG gives higher quantity of carbon
    quantity_ghg_forestry = (end_year - start_year + 1) * (out.ghg_mixed_yr - baseline.ghg_mixed_yr);
%     quantity_ghg_forestry = (end_year - start_year + 1) * (out.ghg_mixed_yrUB - baseline.ghg_mixed_yrUB);

    % Calculate soil forestry ghg annuity
    % For now use 60:40% mix of broad/conif
    quantity_ghg_soil_forestry = (end_year - start_year + 1)  * out.ghg_soil_mixed_yr;
    
    % Output is all quantities added together
    quantity_ghg = quantity_ghg_farm + quantity_ghg_forestry + quantity_ghg_soil_forestry;
    
end