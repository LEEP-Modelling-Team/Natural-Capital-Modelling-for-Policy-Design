function [water_quality_results, water_quality_cell2sbsn] = fcn_import_water_quality_info(conn)
    % fcn_import_water_quality_info.m
    % ===============================
    % Load data necessary for calculating water quality benefits in the 
    % two_run_elm_options.m code. Specifically the outputs of this function
    % are used in fcn_run_water_quality_from_results.m

    % (a) Load water quality results from .mat file
    % ---------------------------------------------
    load('Water Data/water_quality_results.mat', 'water_quality_results')

    % (c) Cell to Subbasin lookup from database
    % -----------------------------------------
    sqlquery = ['SELECT ' ...
                    'tbl1.new2kid, tbl1.src_id, tbl1.proportion, ' ...
                    'tbl2.arable_ha_20 * tbl1.proportion AS arable_ha_20, ' ...
                    'tbl2.grass_ha_20 * tbl1.proportion AS grass_ha_20 ' ...
                'FROM regions_keys.key_grid_subbasins AS tbl1 ' ...
                   'INNER JOIN nevo_explore.explore_2km AS tbl2 ' ...
                   'ON tbl1.new2kid = tbl2.new2kid ' ...
                'ORDER BY tbl1.new2kid, tbl1.src_id'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn = fetch(exec(conn, sqlquery));
    water_quality_cell2sbsn = dataReturn.Data;
end