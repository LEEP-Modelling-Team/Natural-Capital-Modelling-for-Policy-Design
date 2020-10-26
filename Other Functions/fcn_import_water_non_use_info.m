function [water_non_use_results, water_non_use_cell2sbsn] = fcn_import_water_non_use_info(conn)
    % fcn_import_water_non_use_info.m
    % ===============================
    % Load data necessary for calculating non-use water quality benefits in
    % the two_run_elm_options.m code. Specifically the outputs of this 
    % function are used in fcn_run_water_non_use_from_results.m
    
    % !!! currently flooding q5 values are processed here too !!!
    % !!! need to move to fcn_import_flooding_transfer_info !!!
    % !!! (requires re-run of run_flooding_transfer_results) !!!

    % (a) Load water non use results from .mat file
    % ---------------------------------------------
    load('Water Data/water_non_use_results.mat', 'water_non_use_results')

    % (b) Retrieve baseline water quantities for subbasins from database
    % ------------------------------------------------------------------
    % !!! temporary as we need baseline q5 values for flooding !!!
    sqlquery = ['SELECT ' ...
                    'src_id, ' ...
                    'q5_20, q5_30, q5_40, q5_50 ' ...                             
                'FROM nevo_explore.explore_subbasins ' ...
                'ORDER BY src_id'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn = fetch(exec(conn, sqlquery));
    baseline_q5 = dataReturn.Data; 
    
    % (c) Subtract baseline values
    % ----------------------------
    % !!! temporary, we should have already subtracted q5 in
    %     run_flooding_transfer_results.m
    [~, baseline_idx] = ismember(water_non_use_results.arable_reversion_sng_access.src_id, baseline_q5.src_id);
    baseline_q5 = baseline_q5(baseline_idx, :);
    
    % Loop over options, subtract baseline
    option_names = fieldnames(water_non_use_results);
    num_options = length(option_names);
    for i = 1:num_options
        % Extract results for this option and subtract baseline 95 in each decade
        water_non_use_results_option_i = water_non_use_results.(option_names{i});
        water_non_use_results_option_i.chgq5_20 = baseline_q5.q5_20 - water_non_use_results_option_i.q5_20;
        water_non_use_results_option_i.chgq5_30 = baseline_q5.q5_30 - water_non_use_results_option_i.q5_30;
        water_non_use_results_option_i.chgq5_40 = baseline_q5.q5_40 - water_non_use_results_option_i.q5_40;
        water_non_use_results_option_i.chgq5_50 = baseline_q5.q5_50 - water_non_use_results_option_i.q5_50;
        
        % Just retain src_id, new2kid, hectares, non_use and q5 columns
        % Overwrite correct field in water_non_use_results
        water_non_use_results.(option_names{i}) = water_non_use_results_option_i(:, {'src_id', ...
                                                                                     'new2kid', ...
                                                                                     'hectares', ...
                                                                                     'non_use_value_20', ...
                                                                                     'non_use_value_30', ...
                                                                                     'non_use_value_40', ...
                                                                                     'non_use_value_50', ...
                                                                                     'chgq5_20', ...
                                                                                     'chgq5_30', ...
                                                                                     'chgq5_40', ...
                                                                                     'chgq5_50'});
    end
    
    % (d) Cell to Subbasin lookup from database
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
    water_non_use_cell2sbsn = dataReturn.Data;
end