function quantities_table = fcn_calc_quantities(start_year, scheme_length, baseline, es_agriculture, out, elm_option, elm_ha, water_quality_table, flooding_transfer_table, es_biodiversity_jncc, es_biodiversity_ucl)

    %% (0) Constants
    %  =============
    % Calculate end year of scheme, and number of extra years outside of
    % 2020-2059 (40 year period) it will run
    end_year = start_year + scheme_length - 1;
    num_extra_years = max(0, end_year - 40);
    
    %% (1) Calculate quantity change from baseline for each ES
    %  =======================================================
    % (a) Greenhouse Gases
    % --------------------
    quantity_ghg = fcn_calc_quantity_ghg(start_year, end_year, num_extra_years, baseline, es_agriculture, out);
    
    % (b) Recreation
    % --------------
    quantity_rec = fcn_calc_quantity_recreation(start_year, end_year, elm_option, elm_ha);
    
    % (c) Flood Value
    % ---------------
    % !!! This is using old flow emulator !!!
    quantity_flooding = fcn_calc_quantity_flood(start_year, end_year, num_extra_years, flooding_transfer_table);
    
    % (d) Water quality
    % -----------------
    [quantity_totn, quantity_totp] = fcn_calc_quantity_water_quality(start_year, end_year, num_extra_years, water_quality_table);
    
    % (e) Water quality non-use
    % -------------------------
    % Already targeting N and P above
    
    % (f) Pollination
    % ---------------
    quantity_pollination = fcn_calc_quantity_pollination(start_year, end_year, num_extra_years, baseline, es_biodiversity_ucl);
    
    % (g) Biodiversity
    % ----------------
    quantity_bio = fcn_calc_quantity_bio(start_year, end_year, num_extra_years, baseline, es_biodiversity_jncc);
    
    %% (2) Combine quantities into a table
    %  ====================================
    var_names = {'ghg', ...
                 'rec_ha_sng_access', ...
                 'rec_ha_wood_access', ...
                 'rec_ha_sng_noaccess', ...
                 'rec_ha_wood_noaccess', ...
                 'flooding', ...
                 'totn', ...
                 'totp', ...
                 'pollination', ...
                 'bio'};
    combined_quantities = [quantity_ghg, ...
                           quantity_rec.rec_ha_sng_access, ...
                           quantity_rec.rec_ha_wood_access, ...
                           quantity_rec.rec_ha_sng_noaccess, ...
                           quantity_rec.rec_ha_wood_noaccess, ...
                           quantity_flooding, ...
                           quantity_totn, ...
                           quantity_totp, ...
                           quantity_pollination, ...
                           quantity_bio];
    quantities_table = array2table(combined_quantities, ...
                                   'VariableNames', ...
                                   var_names);

end