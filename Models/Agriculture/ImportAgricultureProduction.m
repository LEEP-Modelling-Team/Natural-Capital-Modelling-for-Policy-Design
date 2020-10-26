function AgricultureProduction = ImportAgricultureProduction(conn)

    %% IMPORTAGRICULTUREPRODUCTION
    %  ===========================
    %
    % Description goes here
    %

    %% (1) LOAD DATA FROM DATABASE
    %  ===========================

    % a. Coefficients for the top level, arable, grassland and livestock models
    % -------------------------------------------------------------------------

    % i. Top Level
    sqlquery = 'SELECT beta_toplevel AS toplevel FROM nevo.betas_ag_toplevel';
    setdbprefs('DataReturnFormat','numeric');
    dataReturn  = fetch(exec(conn,sqlquery));
    AgricultureProduction.Coefficients.TopLevel = dataReturn.Data;

    % ii. Arable (actually several crop models)
    sqlquery = 'SELECT beta_wheat AS wheat, beta_osr AS osr, beta_tbar AS tbar, beta_root AS root FROM nevo.betas_ag_arable';
    setdbprefs('DataReturnFormat','structure');
    dataReturn  = fetch(exec(conn,sqlquery));
    AgricultureProduction.Coefficients.Arable = dataReturn.Data;

    % iii. Grassland (actually several grassland models)
    sqlquery = 'SELECT beta_pgrass AS pgrass, beta_tgrass AS tgrass, beta_rgraz AS rgraz FROM nevo.betas_ag_grass';
    setdbprefs('DataReturnFormat','structure');
    dataReturn  = fetch(exec(conn,sqlquery));
    AgricultureProduction.Coefficients.Grass = dataReturn.Data;

    % iv. Livestock (actually several livestock models)
    sqlquery = 'SELECT beta_dairy AS dairy, beta_beef AS beef, beta_sheep AS sheep FROM nevo.betas_ag_livestock';
    setdbprefs('DataReturnFormat','structure');
    dataReturn  = fetch(exec(conn,sqlquery));
    AgricultureProduction.Coefficients.Livestock = dataReturn.Data;

    % b. Grid cell data needed for the top level, arable, grassland and livestock models
    % ----------------------------------------------------------------------------------
    sqlquery = ['SELECT new2kid, const, avelev_cell, avelev200_cell, ' ...
        'avslp_cell, sqavslp_cell, pca_fslpgrt6, pca_npoct10, ' ...
        'pca_esa94, pca_ukgre12, pca_nvz09n, wales, scotland, island, ' ...
        'dist300, sb_dist, sb_dist20, sb_dist40, sb_dist80, ' ...
        'sb_dist120, ph, sqph, cuph, root_depth, pca_oc5, pca_oc6, ' ...
        'pca_coarse, pca_med, pca_fine, pca_peat, pca_gravelly, ' ...
        'pca_stony, pca_fragipan, pca_saline, pca_notex, adjsilt, ' ...
        'adjclay, price_wheat, price_osr, price_wbar, price_sbar, ' ...
        'price_pot, price_sb, price_pnb, price_milk, price_beef, ' ...
        'price_sheep, price_fert, price_quota, trend_toplevel, ' ...
        'trend_ar, trend_ls, bse, trend_bse, share_wbar, share_pot, ' ...
        'yield_wheat, yield_osr, yield_wbar, yield_sbar, yield_pot, ' ...
        'yield_sb ' ...
        'FROM nevo.nevo_variables ORDER BY new2kid'];
    setdbprefs('DataReturnFormat','table');
    dataReturn  = fetch(exec(conn,sqlquery));
    data_cells = dataReturn.Data;
    
    % Save 2km grid cell new2kid separately
    AgricultureProduction.new2kid = table2array(data_cells(:,1));
    
    % Rest goes into AgricultureProduction.Data_cells table
    AgricultureProduction.Data_cells = data_cells(:,2:end);

    % c. Grid cell climate data (rain and temperature) in growing season
    % ------------------------------------------------------------------
    % This is the restricted climate the agriculture model needs
    sqlquery = ['SELECT temp2020, temp2021, temp2022, temp2023, temp2024, temp2025, temp2026, temp2027, temp2028, temp2029, ' ...
        'temp2030, temp2031, temp2032, temp2033, temp2034, temp2035, temp2036, temp2037, temp2038, temp2039, ' ...
        'temp2040, temp2041, temp2042, temp2043, temp2044, temp2045, temp2046, temp2047, temp2048, temp2049, ' ...
        'temp2050, temp2051, temp2052, temp2053, temp2054, temp2055, temp2056, temp2057, temp2058, temp2059, ' ...
        'rain2020, rain2021, rain2022, rain2023, rain2024, rain2025, rain2026, rain2027, rain2028, rain2029, ' ...
        'rain2030, rain2031, rain2032, rain2033, rain2034, rain2035, rain2036, rain2037, rain2038, rain2039, ' ...
        'rain2040, rain2041, rain2042, rain2043, rain2044, rain2045, rain2046, rain2047, rain2048, rain2049, ' ...
        'rain2050, rain2051, rain2052, rain2053, rain2054, rain2055, rain2056, rain2057, rain2058, rain2059 ' ...
        'FROM nevo.nevo_fclimate_grow_avg_restrict ORDER BY new2kid'];
    setdbprefs('DataReturnFormat','table');
    dataReturn  = fetch(exec(conn,sqlquery));
    AgricultureProduction.Climate_cells = dataReturn.Data;
 
end