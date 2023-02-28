%% run_water_results_new.m
clc
clear

% Define available ELM options
% CHOOSE ONE:
available_elm_options = {'arable_reversion_wood_access', ...
                         'destocking_wood_access'};

% available_elm_options = {'arable_reversion_sng_access', ...
%                          'destocking_sng_access', ...
%                          'arable_reversion_wood_access', ...
%                          'destocking_wood_access'};
num_elm_options = length(available_elm_options);

%% (0) Set up JSON string to run script
%  ====================================
json = ['{"id": "E92000001",'...
        '"feature_type": "integrated_countries",' ...
        '"price_wheat": 0,' ...
        '"price_osr": 0,' ...
        '"price_sbar": 0,' ...
        '"price_wbar": 0,' ...
        '"price_pot": 0,' ...
        '"price_sb": 0,' ...
        '"price_other": 0,' ...
        '"price_dairy": 0,' ...
        '"price_beef": 0,' ...
        '"price_sheep": 0,' ...
        '"price_fert": 0,' ...
        '"price_quota": 0,' ...
        '"price_broad": 0,' ...
        '"price_conif": 0,' ...
        '"price_carbon": 1,' ...
        '"discount_rate": 0,' ...
        '"irrigation": true,' ...
        '"run_agriculture": true,' ...
        '"run_forestry": true,' ...
        '"run_recreation": true,' ...
        '"run_ghg": true,' ...
        '"run_biodiversity": true,' ...
        '"run_water": true,' ...
        '"run_water_non_use": true}'];

%% (1) Set up
%  ==========

% Set flag for server
% -------------------
% true - NEVO
% false - local machine (for testing)
server_flag = false;

% Connect to database
% -------------------
conn = fcn_connect_database(server_flag);

% Set model parameters
% --------------------
% Decode JSON object/string
% Set other default parameters
MP = fcn_set_model_parameters(json, server_flag);

% Get carbon prices
% -----------------
carbon_prices = fcn_get_carbon_prices(conn, MP);

% Go from regional scale to 2km grid cells
% -----------------------------------------
% Returns cell ids and other info
cell_info = fcn_region_to_cell(conn, MP.feature_type, MP.id);

% Import primary variables from database
% --------------------------------------
% Set this to PV_original
% We create copies from this to overwrite
PV_original = fcn_import_primary_variables(conn, cell_info);

% Get key_grid_subbasins and firstdownstream tables from database
% ---------------------------------------------------------------
key_grid_subbasins = fcn_get_key_grid_subbasins(conn);
firstdownstream = fcn_get_firstdownstream(conn);

% Baseline totn and totp values for all subbasins
% -----------------------------------------------
sqlquery = ['SELECT ', ...
                'src_id, ', ...
                'totn_20, totn_30, totn_40, totn_50, ', ...
                'totp_20, totp_30, totp_40, totp_50 ', ...
            'FROM nevo_explore.explore_subbasins ', ...
            'ORDER BY src_id'];
setdbprefs('DataReturnFormat', 'table');
dataReturn  = fetch(exec(conn, sqlquery));
subbasin_baseline = dataReturn.Data;

% Subbasins with water abstraction
% --------------------------------
sqlquery = ['SELECT ', ...
                'src_id, ', ...
                'abstraction_m3_yr ', ...
            'FROM water.wtw_catchment_nevo ', ...
            'ORDER BY src_id'];
setdbprefs('DataReturnFormat', 'table');
dataReturn  = fetch(exec(conn, sqlquery));
subbasin_abstraction = dataReturn.Data;

for elm_opt = 1:num_elm_options

    elm_option = available_elm_options{elm_opt};
    disp(elm_option)
    
    % For each option, set up string of land type we are switching from
    % -----------------------------------------------------------------
    switch elm_option
        case {'arable_reversion_sng_access', 'arable_reversion_wood_access'}
            land_type = 'arable';
        case {'destocking_sng_access', 'destocking_wood_access'}
            land_type = 'grass';
        otherwise
            error('Panic.')
    end
    
    % Get representative cell for each subbasin for this land type
    % ------------------------------------------------------------
    % The representative cell is that which has the most hectares of the
    % land type in the subbasin 
    % Just consider cells in England here
    % Remove Scottish basins (21009, 21016, 21022, 77001, 77004)
    sqlquery = ['SELECT DISTINCT ON (tbl1.src_id) ' ...
                    'tbl1.src_id, ' ...
                    'tbl1.new2kid, ' ...
                    'tbl2.' land_type '_ha_20 * tbl1.proportion AS hectares ' ...                             
                'FROM regions_keys.key_grid_subbasins AS tbl1 ' ...
                    'INNER JOIN nevo_explore.explore_2km AS tbl2 ON tbl1.new2kid = tbl2.new2kid ' ...
                    'INNER JOIN regions_keys.key_grid_countries_england AS tbl3 ON tbl1.new2kid = tbl3.new2kid ' ...
                    'INNER JOIN regions_keys.lookup_basins AS tbl4  ON tbl1.src_id = tbl4.src_id ' ...
                'WHERE tbl2.' land_type '_ha_20 * tbl1.proportion > 0 ' ...
                    'AND tbl4.basin_id NOT IN (21009, 21016, 21022, 77001, 77004) ' ...
                'ORDER BY tbl1.src_id, tbl2.' land_type '_ha_20 * tbl1.proportion DESC'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn  = fetch(exec(conn, sqlquery));
    subbasin_cell = dataReturn.Data;
    basin_subbasin = split(subbasin_cell.src_id,'_');
    subbasin_cell.basin_id = strcat(basin_subbasin(:, 1), {'_'});

    %% (2) Implement ELM options in all cells (where possible)
    %  =======================================================

    %% (a) Implement this ELM option
    %  -----------------------------
    % PV_updated contains the updated land covers
    [PV_updated, elm_ha_option, scheme_length_option, site_type_option] = fcn_implement_elm_option(conn, elm_option, cell_info, PV_original);

    % Set up matrix of landuse hectare change (for use in forestry model)
    landuse_ha_change = [PV_updated.wood_ha - PV_original.wood_ha, ...
        PV_updated.farm_ha - PV_original.farm_ha, ...
        PV_updated.sngrass_ha - PV_original.sngrass_ha, ...
        PV_updated.urban_ha - PV_original.urban_ha, ...
        PV_updated.water_ha - PV_original.water_ha];

    %% (b) Run agriculture, forestry and GHG models
    %  --------------------------------------------

    % (i) Agriculture (+ GHG)
    if MP.run_agriculture
        % Use fcn_run_agriculture_elms function (not NEVO function)
        % Need to pass in PV_original as farmer not allowed to optimise
        es_agriculture = fcn_run_agriculture_elms(MP.agriculture_data_folder, MP.agricultureghg_data_folder, MP, PV_original, carbon_prices(1:40), elm_option, elm_ha_option);              
    end

    % (ii) Forestry (+ GHG)
    if MP.run_forestry
        es_forestry = fcn_run_forestry_elms(MP.forest_data_folder, MP.forestghg_data_folder, MP, PV_updated, landuse_ha_change, carbon_prices);
    end

    % (iii) Collect output from agriculture, forestry and GHG models
    % --------------------------------------------------------------
    % Create decadal output in 2020-2029, 2030-2039, 2040-2049, 2050-2059
    out = fcn_collect_output(MP, PV_updated, es_agriculture, es_forestry, carbon_prices);

    %% (c) Run additional models based on averaged decadal output
    %  ----------------------------------------------------------
    % colnames in eswater to save
    colnames = {'totn_20', 'totn_30', 'totn_40', 'totn_50', ...
                'totp_20', 'totp_30', 'totp_40', 'totp_50'};    

    % (i) Flooding, water quantity and water quality
    if MP.run_water

        [~, sbcell_in_allcell_idx] = ismember(subbasin_cell.new2kid, cell_info.new2kid);

        % Preallocate table to store results for this option
        results_table_temp1 = subbasin_cell(:, {'src_id', 'new2kid', 'hectares'});
        results_table_temp2 = cell2table(cell(size(subbasin_cell.new2kid, 1), 2 + length(colnames)), ...
                                         'VariableNames', ...
                                         {'abstraction_src_id', ...
                                          'abstraction_cost', ...
                                          'chgtotn_20', ...
                                          'chgtotn_30', ...
                                          'chgtotn_40', ...
                                          'chgtotn_50', ...
                                          'chgtotp_20', ...
                                          'chgtotp_30', ...
                                          'chgtotp_40', ...
                                          'chgtotp_50'});
        results_table_temp3 = array2table(zeros(size(subbasin_cell.new2kid, 1), length(colnames)), ...
                                          'VariableNames', ...
                                          {'totn_ann_20', ...
                                           'totn_ann_30', ...
                                           'totn_ann_40', ...
                                           'totn_ann_50', ...
                                           'totp_ann_20', ...
                                           'totp_ann_30', ...
                                           'totp_ann_40', ...
                                           'totp_ann_50'});
        results_table = [results_table_temp1, ...
                         results_table_temp2, ...
                         results_table_temp3];
        clear results_table_temp1 results_table_temp2 results_table_temp3
        
        % Convert PV and out structures to tables for ease of extracting
        % cells in loop
        PV_updated_table = struct2table(PV_updated);
        out_table = struct2table(out);
        
        % Set up index for permuting columns of es_water
        [es_water, ~] = fcn_run_water_elms(MP.water_data_folder, table2struct(PV_updated_table(sbcell_in_allcell_idx(1),:),'ToScalar',true), table2struct(out_table(sbcell_in_allcell_idx(1),:),'ToScalar',true), subbasin_cell.src_id(1), 0, 0, subbasin_cell.src_id(1));
        [~, colidx] = ismember(colnames, es_water.Properties.VariableNames);
        
        % Parfor doesn't work yet
        for i = 1:size(subbasin_cell.new2kid,1)
%         parfor i = 1:size(subbasin_cell.new2kid,1)
            % Print progress update
            disp(['Processing subcatchment ', ...
                  num2str(i), ' of ', num2str(size(subbasin_cell.new2kid, 1)), ...
                  ' (', subbasin_cell.src_id{i}, ')'])

            % Get src_ids of subbasins affected by change
            affected_src_id = fcn_get_downstream_src_id(subbasin_cell.src_id(i), firstdownstream);
            
            % Check if any of these subbasins have abstraction
            [abstraction_ind, ~] = ismember(affected_src_id, subbasin_abstraction.src_id);
            
            % Run water model if
            % a. subbasins are affected AND
            % b. there is water abstraction
            if ~isempty(affected_src_id) && any(abstraction_ind)
                [es_water, ~] = fcn_run_water_elms(MP.water_data_folder, ...
                                                   table2struct(PV_updated_table(sbcell_in_allcell_idx(i),:),'ToScalar',true), ...
                                                   table2struct(out_table(sbcell_in_allcell_idx(i),:),'ToScalar',true), ...
                                                   affected_src_id, ...
                                                   0, ...
                                                   0, ...
                                                   subbasin_cell.src_id(i));
                
                % Reduce to abstraction subcatchments
                es_water_abstraction = es_water(abstraction_ind, :);
                
                % Get abstraction amount
                [~, abstraction_idx] = ismember(es_water_abstraction.src_id, subbasin_abstraction.src_id);
                abstraction_amount = subbasin_abstraction.abstraction_m3_yr(abstraction_idx);
                
                % Get change in N and P concentrations by subtracting baseline
                [baseline_ind, baseline_idx] = ismember(es_water_abstraction.src_id, subbasin_baseline.src_id);
                baseline_array = table2array(subbasin_baseline(baseline_idx, 2:end));
                es_water_abstraction_array = table2array(es_water_abstraction(:, colidx));
                diff_array = baseline_array - es_water_abstraction_array; % positive is reduction in concentration (good)
                
                % Calculate benefits
                benefit_array = sum(0.0006 * diff_array .* repmat(abstraction_amount, 1, 8), 1);
                
                % Store in results
                results_table.abstraction_src_id(i) = {es_water_abstraction.src_id'};   % abstraction src_id
                results_table.abstraction_cost(i) = {abstraction_amount'};              % damage costs
                results_table.chgtotn_20(i) = {diff_array(:, 1)'};                      % chgtotn_20
                results_table.chgtotn_30(i) = {diff_array(:, 2)'};                      % chgtotn_30
                results_table.chgtotn_40(i) = {diff_array(:, 3)'};                      % chgtotn_40
                results_table.chgtotn_50(i) = {diff_array(:, 4)'};                      % chgtotn_50
                results_table.chgtotp_20(i) = {diff_array(:, 5)'};                      % chgtotp_20
                results_table.chgtotp_30(i) = {diff_array(:, 6)'};                      % chgtotp_30
                results_table.chgtotp_40(i) = {diff_array(:, 7)'};                      % chgtotp_40
                results_table.chgtotp_50(i) = {diff_array(:, 8)'};                      % chgtotp_50
                results_table.totn_ann_20(i) = benefit_array(1);                        % benefit from chgtotn_20
                results_table.totn_ann_30(i) = benefit_array(2);                        % benefit from chgtotn_30
                results_table.totn_ann_40(i) = benefit_array(3);                        % benefit from chgtotn_40
                results_table.totn_ann_50(i) = benefit_array(4);                        % benefit from chgtotn_50
                results_table.totp_ann_20(i) = benefit_array(5);                        % benefit from chgtotp_20
                results_table.totp_ann_30(i) = benefit_array(6);                        % benefit from chgtotp_30
                results_table.totp_ann_40(i) = benefit_array(7);                        % benefit from chgtotp_40
                results_table.totp_ann_50(i) = benefit_array(8);                        % benefit from chgtotp_50
            end
            
            % Print progress update
            disp(['   Finished subcatchment ', ...
                  num2str(i), ' of ', num2str(size(subbasin_cell.new2kid, 1)), ...
                  ' (', subbasin_cell.src_id{i}, ')'])
        end
    end
    
    % Save results table to water_results structure with ELM option
    % subscript, and save water_results to .mat file
    water_quality_results.(elm_option) = results_table;
    save('Water Data/water_quality_results.mat', 'water_quality_results');
end

% Add no access options and save again
% water_quality_results.arable_reversion_sng_noaccess = water_quality_results.arable_reversion_sng_access;
water_quality_results.arable_reversion_wood_noaccess = water_quality_results.arable_reversion_wood_access;
% water_quality_results.destocking_sng_noaccess = water_quality_results.destocking_sng_access;
water_quality_results.destocking_wood_noaccess = water_quality_results.destocking_wood_access;

save('Water Data/water_quality_results.mat', 'water_quality_results');