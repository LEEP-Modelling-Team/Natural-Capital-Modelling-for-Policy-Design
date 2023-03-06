function [water_transfer_results, water_transfer_cell2subctch, nfm_data] = fcn_import_water_transfer_info(conn, NEV)
   
    % fcn_import_water_quality_info.m
    % ===============================
    % Load data necessary for calculating water quality benefits in the 
    % two_run_elm_options.m code. Specifically the outputs of this function
    % are used in fcn_run_water_quality_from_results.m

    % (a) Load water quality results from .mat file
    % ---------------------------------------------
    load([NEV.water_runs_folder 'water_arable2sng.mat'],  'water_arable2sng')
    load([NEV.water_runs_folder 'water_arable2wood.mat'], 'water_arable2wood')
    load([NEV.water_runs_folder 'water_grass2sng.mat'],   'water_grass2sng')
    load([NEV.water_runs_folder 'water_grass2wood.mat'],  'water_grass2wood')
    
    water_transfer_results.arable_reversion_sng_access    = water_arable2sng;
    water_transfer_results.arable_reversion_sng_noaccess  = water_arable2sng;
    water_transfer_results.arable_reversion_wood_access   = water_arable2wood;
    water_transfer_results.arable_reversion_wood_noaccess = water_arable2wood;
    water_transfer_results.destocking_sng_access          = water_grass2sng;
    water_transfer_results.destocking_sng_noaccess        = water_grass2sng;
    water_transfer_results.destocking_wood_access         = water_grass2wood;
    water_transfer_results.destocking_wood_noaccess       = water_grass2wood;
    
    % (b) Cell to subcatchment lookup from database
    % ---------------------------------------------
    sqlquery = ['SELECT ' ...
                    'tbl1.new2kid, tbl1.subctch_id, tbl1.proportion, ' ...
                    'tbl2.arable_ha_20 * tbl1.proportion AS arable_ha_20, ' ...
                    'tbl2.grass_ha_20  * tbl1.proportion AS grass_ha_20 ' ...
                'FROM regions_keys.key_grid_wfd_subcatchments AS tbl1 ' ...
                      'INNER JOIN nevo_explore.explore_2km AS tbl2 ' ...
                      'ON tbl1.new2kid = tbl2.new2kid ' ...
                'ORDER BY tbl1.new2kid, tbl1.subctch_id'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn = fetch(exec(conn, sqlquery));
    water_transfer_cell2subctch = dataReturn.Data;
    
    % (c) Natural flood management areas
    % ----------------------------------
    sqlquery = ['SELECT ', ...
                    'new2kid, ', ...
                    'nfm_cell, ', ...
                    'nfm_area_ha ', ...
                'FROM flooding.nfm_cells_gb ', ...
                'ORDER BY new2kid'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn = fetch(exec(conn, sqlquery));
    nfm_data = dataReturn.Data;
end