function [benefits_npv_table, costs_npv_table] = fcn_calc_benefits(MP, elm_option, baseline, es_agriculture, es_forestry, es_recreation_all, es_water_quality_all, es_water_non_use_all, es_flood_all, es_pollination, es_non_use_pollination, es_non_use_habitat, es_biodiversity_jncc, biodiversity_unit_value)

 
    % (1) Calculate benefits for each ecosystem service as annuities
    %  ==============================================================
    
    % (a) Agriculture
    % ---------------
    opp_cost_farm_npv = fcn_calc_npv_agriculture(baseline.es_agriculture, es_agriculture, MP);
    
    % (b) Forestry
    % ------------
    [benefit_forestry_npv, cost_forestry_npv] = fcn_calc_npv_forestry(baseline, es_forestry, MP);
    
    % (c) Greenhouse Gases
    % --------------------
    [benefit_ghg_farm_npv, benefit_ghg_forestry_npv, benefit_ghg_soil_forestry_npv] = fcn_calc_npv_ghg(baseline, es_agriculture, es_forestry, MP);
    
    % (d) Recreation
    % --------------
    benefit_rec_npv = fcn_calc_npv_recreation_substitution(MP, elm_option, es_recreation_all);
    
    % (e) Flooding
    % ------------
    benefit_flood_npv = fcn_calc_npv_water_flood(MP, elm_option, es_flood_all);
    
    % (f) Water Quality Treatment
    % ---------------------------
    [benefit_totn_npv, benefit_totp_npv] = fcn_calc_npv_water_quality(MP, elm_option, es_water_quality_all);
    
    % (g) Water Quality Non-Use
    % -------------------------
    benefit_water_non_use_npv = fcn_calc_npv_water_non_use(MP, elm_option, es_water_non_use_all);
          
    % (h) Pollination: Horticultural Yields
    % -------------------------------------
    benefit_pollination_npv = fcn_calc_npv_pollination(MP, elm_option, es_pollination);
    
    
    % (i) Pollination: Wildflower Non-Use 
    % -----------------------------------
    benefit_non_use_pollination_ann = fcn_calc_benefit_non_use_pollination(start_year, scheme_length, discount_constants, es_non_use_pollination);
    
    % (j) Non Use Habitat
    % -------------------
    benefit_non_use_habitat_ann = es_non_use_habitat.nu_habitat_val;
    
    % (k) Biodiversity
    % ----------------
    benefit_bio_ann = fcn_calc_benefit_bio(start_year, scheme_length, discount_constants, baseline, es_biodiversity_jncc, biodiversity_unit_value);
    
    
    % (2) Combine benefits across ecosystem services using NPVs
    %  =========================================================
    % (a) Turn decadal benefit annuities into NPVs using discount decade
    % ------------------------------------------------------------------
    % benefit_farm_npv = benefit_farm_ann * discount_constants.discount_decade;
    benefit_ghg_farm_npv            = benefit_ghg_farm_ann * discount_constants.discount_decade;
    benefit_rec_npv                 = benefit_rec_ann * discount_constants.discount_decade;
    benefit_totn_npv                = benefit_totn_ann * discount_constants.discount_decade;
    benefit_totp_npv                = benefit_totp_ann * discount_constants.discount_decade;
    benefit_water_non_use_npv       = benefit_water_non_use_ann * discount_constants.discount_decade;
    benefit_pollination_npv         = benefit_pollination_ann * discount_constants.discount_decade;
    benefit_non_use_pollination_npv = benefit_non_use_pollination_ann * discount_constants.discount_decade;
    benefit_bio_npv                 = benefit_bio_ann * discount_constants.discount_decade;
    
    % (b) Turn other benefit annuities into NPVs using sum of discount
    % vector over scheme length
    % ----------------------------------------------------------------
    discount_scheme_sum = sum(discount_constants.delta_scheme_length);
    benefit_forestry_npv          = benefit_forestry_ann * discount_scheme_sum;
    benefit_ghg_forestry_npv      = benefit_ghg_forestry_ann * discount_scheme_sum;
    benefit_ghg_soil_forestry_npv = benefit_ghg_soil_forestry_ann * discount_scheme_sum;
    benefit_flooding_npv          = benefit_flooding_ann * discount_scheme_sum;
    benefit_non_use_habitat_npv   = benefit_non_use_habitat_ann * discount_scheme_sum;
    
    % (c) Sum to get total benefit NPV
    % --------------------------------
    % Need nansum due to nan's in recreation benefits
    % NB. we DO NOT include forestry benefits here! 
    benefits_npv = nansum([benefit_ghg_farm_npv, ...
                           benefit_rec_npv, ...
                           benefit_ghg_forestry_npv, ...
                           benefit_ghg_soil_forestry_npv, ...
                           benefit_flooding_npv, ...
                           benefit_totn_npv, ...
                           benefit_totp_npv, ...
                           benefit_water_non_use_npv, ...
                           benefit_pollination_npv, ...
                           benefit_non_use_pollination_npv, ...
                           benefit_non_use_habitat_npv, ...
                           benefit_bio_npv], 2);
    
    
    % (3) Calculate costs as NPV
    %  ==========================
    
    % Farm opportunity costs
    % ----------------------
    opp_cost_farm_npv = opp_cost_farm_ann * discount_constants.discount_decade;
    
    % Forestry costs
    % --------------
    % Convert per hectare cost annuity into npv
    % Add on fixed costs (only for increase hectares of woodland - taken care of in fcn_forestry_elms)
    % Subtract timber benefit npv
    
% THIS NEEDS TO CHANGE AS FIXED COSTS ALREADY IN FORESTRY COST CALCULATION!    
    cost_forestry_npv = cost_forestry_ann * discount_scheme_sum + es_forestry.Timber.FixedCost.Mix6040 - benefit_forestry_npv;
    

    % WHY'S THIS SUCH A PROBLEM!
    if any(cost_forestry_npv < 0)
        error('Forestry costs are negative!');
    end
    
    
    % (4) Combine results to tables for output return
    %  ===============================================
    % (a) Benefits
    % ------------
    var_names = {'total', ...
                 'ghg_farm', ...
                 'forestry', ...
                 'ghg_forestry', ...
                 'ghg_soil_forestry', ...
                 'rec', ...
                 'flooding', ...
                 'totn', ...
                 'totp', ...
                 'water_non_use', ...
                 'pollination', ...
                 'non_use_pollination', ...
                 'non_use_habitat', ...
                 'bio'};
    combined_benefits = [benefits_npv, ...
                         benefit_ghg_farm_npv, ...
                         benefit_forestry_npv, ...
                         benefit_ghg_forestry_npv, ...
                         benefit_ghg_soil_forestry_npv, ...
                         benefit_rec_npv, ...
                         benefit_flooding_npv, ...
                         benefit_totn_npv, ...
                         benefit_totp_npv, ...
                         benefit_water_non_use_npv, ...
                         benefit_pollination_npv, ...
                         benefit_non_use_pollination_npv, ...
                         benefit_non_use_habitat_npv, ...
                         benefit_bio_npv];
    benefits_npv_table = array2table(combined_benefits, ...
                                     'VariableNames', ...
                                     var_names);
    
    % Costs
    % -----
    var_names = {'farm', ...
                 'forestry'};
    combined_costs = [opp_cost_farm_npv, ...
                      cost_forestry_npv];
    costs_npv_table = array2table(combined_costs, ...
                                  'VariableNames', ...
                                  var_names);

end