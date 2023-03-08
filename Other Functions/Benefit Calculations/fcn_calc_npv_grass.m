function [benefit_grass_npv, cost_grass_npv] = fcn_calc_npv_grass(MP, sngrass_ha_chg)

    % Data
    % ----
    %  Soil organic carbon:
    %     o study by Gosling et al. (2017) suggests this is negligible
    %  Revenues
    %     o take yield as 2 tonnes/ha Tallowin and Jefferson (1999) and use
    %       price of 'pick up baled meadow hay) of £102 per tonne (£2023)
    %  Costs
    %     o take planting costs of £1,000 per hectare (£2006) for manual
    %       seeding and management for establishment

    yrs_NEV = MP.num_years;

    % Soil Organic Carbon
    % -------------------
    %   None
    
    
    % Benefits
    % --------
    
    % Benefits are an annuity from hay revenues
    % -----------------------------------------
    benefit_hay_ann = 2 * 102 * sngrass_ha_chg;
       
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_hay = benefit_hay_ann/MP.discount_rate;
    
    % extend to data set for planting in each of 40 years
    % ---------------------------------------------------
    npv_inf_hay = repmat(npv_inf_hay, 1,MP.num_years);    
    
    % express as npv in base year
    % ---------------------------
    npv_timber = npv_inf_hay ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base_year prices
    % ----------------------------------
    benefit_grass_npv = npv_timber * MP.rpi_hay;
   

    % Costs
    % -----
    % Costs are a one off planting cost    
    
    % change in NEV annuity
    % ---------------------   
    fix_cost_grass = 1000 * sngrass_ha_chg;
    
    % extend to data set for planting over 40 years
    % ---------------------------------------------
    npv_inf_grass_cost = repmat(fix_cost_grass,1, MP.num_years);    
    
    % express as npv in base year
    % ---------------------------
    npv_forest_cost = npv_inf_grass_cost ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base prices
    % -----------------------------
    cost_grass_npv = npv_forest_cost * MP.rpi_grass;    
    
end