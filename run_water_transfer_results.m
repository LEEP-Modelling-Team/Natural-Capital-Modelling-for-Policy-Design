%% run_water_results.m
clc
clear

% Define available ELM options
% CHOOSE ONE:
available_elm_options = {'arable_reversion_sng_access', ...
                         'destocking_sng_access', ...
                         'arable_reversion_wood_access', ...
                         'destocking_wood_access'};
num_elm_options = length(available_elm_options);

%% (0) Set up JSON string to run script
%  ====================================
json = ['{"id": "E92000001",'...
        '"feature_type": "integrated_countries",' ...
        '"run_agriculture": true,' ...
        '"run_forestry": true,' ...
        '"run_recreation": true,' ...
        '"run_ghg": true,' ...
        '"run_biodiversity_jncc": true,' ...
        '"run_biodiversity_ucl": true,' ...
        '"run_water": true,' ...
        '"price_broad": 0,' ...
        '"price_conif": 0,' ...
        '"water": null}'];
parameters = fcn_set_parameters();

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
MP = fcn_set_model_parameters(json, server_flag, parameters);

% Get carbon prices
% -----------------
carbon_price = fcn_get_carbon_price(conn, MP.carbon_price);

% Go from regional scale to 2km grid cells
% -----------------------------------------
% Returns cell ids and other info
cell_info = fcn_region_to_cell(conn, MP.feature_type, MP.id);

% Import primary variables from database
% --------------------------------------
% Set this to PV_original
% We create copies from this to overwrite
PV_original = fcn_import_primary_variables(conn, cell_info);

% Determine subcatchments that cross over with 2km grid cells
% -----------------------------------------------------------
sqlquery = ['SELECT ' ...
                'new2kid, ' ...
                'subctch_id, ' ...
                'proportion ' ...
            'FROM regions_keys.key_grid_wfd_subcatchments ' ...
            'ORDER by new2kid, subctch_id'];
setdbprefs('DataReturnFormat', 'table');
dataReturn  = fetch(exec(conn, sqlquery));
key_grid_subcatchments = dataReturn.Data;

% Subcatchment ids that crossover with 2km grid cells
subctch_ids_land = unique(key_grid_subcatchments.subctch_id);

% Number of subcatchments that cross over with 2km grid cells
num_subctch_land = length(subctch_ids_land);

% Determine subcatchments with IO
% -------------------------------
load(strcat(MP.water_transfer_data_folder, 'Input Output\firstdownstream.mat'))

% Subcatchment IDs with input/output
subctch_ids_io = firstdownstream.subctch_id(~strcmp('NA', firstdownstream.firstdownstream));

% Number of subcatchment ID with input/output
num_subctch_io = length(subctch_ids_io);

% Subcatchments to run the analysis for
% -------------------------------------
% These are catchments which cross over with 2km grid cells and have
% input/output
subctch_temp = [subctch_ids_land; subctch_ids_io];
[~, idx_unique] = unique(subctch_temp);
subctch_ids_run = subctch_temp(setdiff(1:length(subctch_temp), idx_unique));    % extract duplicates
num_subctch_run = length(subctch_ids_run);

% Reduce key_grid_subcatchments table to subctch_ids_run
ind_subctch_run = ismember(key_grid_subcatchments.subctch_id, subctch_ids_run);
key_grid_subcatchments_run = key_grid_subcatchments(ind_subctch_run, :);

% FloodingTransfer data
% ---------------------
% Use event parameter = 7
load(strcat(MP.flooding_transfer_data_folder, 'NEVO_Flooding_Transfer_data_7.mat'))

% Run agriculture model to have the data to calculate representative cells
% ------------------------------------------------------------------------
lcs_toplevel = fcn_run_agriculture(MP.agriculture_data_folder, ...
                                     MP.climate_data_folder, ...
                                     MP.agricultureghg_data_folder, ...
                                     MP, ...
                                     PV_original, ...
                                     carbon_price(1:40));

% Collect high level and agriculture output
% -----------------------------------------
lcs_toplevel = fcn_collect_output_simple(PV_original, lcs_toplevel);

for elm_opt = 1:num_elm_options

    elm_option = available_elm_options{elm_opt};
    disp(elm_option)
    
    % For each option, set up string of land type we are switching from
    % -----------------------------------------------------------------
    switch elm_option
        case {'arable_reversion_sng_access', 'arable_reversion_wood_access'}
            land_type = 'arable';
            subctch_cell_data = innerjoin(key_grid_subcatchments_run, lcs_toplevel(:, {'new2kid', 'arable_ha_20'}));
        case {'destocking_sng_access', 'destocking_wood_access'}
            land_type = 'grass';
            subctch_cell_data = innerjoin(key_grid_subcatchments_run, lcs_toplevel(:, {'new2kid', 'grass_ha_20'}));
        otherwise
            error('Panic.')
    end
    subctch_cell_data.Properties.VariableNames(4) = {'hectares'};
    
    % Get representative cell for each subbasin for this land type
    % ------------------------------------------------------------
    % The representative cell is that which has the most hectares of the
    % land type in the subbasin 
    % Just consider cells in England here
    subctch_rep_cell = [];
    for i = 1:num_subctch_run
        % Select rows for i-th subbasin
        [ind_temp, ~] = ismember(subctch_cell_data.subctch_id, subctch_ids_run(i));
        temp_data = subctch_cell_data(ind_temp, :);

        % Retain row with largest hectare value and add to table
        [~, max_idx] = max(temp_data.hectares);
        subctch_rep_cell = [subctch_rep_cell; temp_data(max_idx, :)];
    end
    
    subctch_rep_cell.proportion = [];
    
    subbasin_cell = subctch_rep_cell(:, {'subctch_id', 'new2kid', 'hectares'});
    baseline_water_transfer = fcn_get_baseline_water_transfer(MP);
    subbasin_cell = join(subbasin_cell, baseline_water_transfer);
    basin_subbasin = split(subbasin_cell.subctch_id,'_');
    subbasin_cell.basin_id = strcat(basin_subbasin(:, 1), {'_'});
    
    %% (2) Implement ELM options in all cells (where possible)
    %  =======================================================

    %% (a) Implement this ELM option
    %  -----------------------------
    % PV_updated contains the updated land covers
    [PV_updated, elm_ha_option, scheme_length_option, site_type_option] = fcn_implement_elm_option(conn, elm_option, cell_info, PV_original, MP, carbon_price);

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
        es_agriculture = fcn_run_agriculture_elms(MP.agriculture_data_folder, ...
                                                  MP.climate_data_folder, ...
                                                  MP.agricultureghg_data_folder, ...
                                                  MP, ...
                                                  PV_original, ...
                                                  carbon_price(1:40), ...
                                                  elm_option, ...
                                                  elm_ha_option);              
    end

    % (ii) Forestry (+ GHG)
    if MP.run_forestry
        es_forestry = fcn_run_forestry_elms(MP.forest_data_folder, ...
                                            MP.forestghg_data_folder, ...
                                            MP, ...
                                            PV_updated, ...
                                            landuse_ha_change, ...
                                            carbon_price, ...
                                            elm_option);
    end

    % (iii) Collect output from agriculture, forestry and GHG models
    % --------------------------------------------------------------
    % Create decadal output in 2020-2029, 2030-2039, 2040-2049, 2050-2059
    out = fcn_collect_output(MP, PV_updated, es_agriculture, es_forestry, carbon_price);

    %% (c) Run additional models based on averaged decadal output
    %  ----------------------------------------------------------

    % colnames in eswater to save
    colnames = {'q5_20',   'q5_30',   'q5_40',   'q5_50',  ...
                'orgn_20', 'orgn_30', 'orgn_40', 'orgn_50',  ...
                'no3_20',  'no3_30',  'no3_40',  'no3_50', ...
                'no2_20',  'no2_30',  'no2_40',  'no2_50', ...
                'nh4_20',  'nh4_30',  'nh4_40',  'nh4_50', ...
                'totn_20', 'totn_30', 'totn_40', 'totn_50', ...
                'orgp_20', 'orgp_30', 'orgp_40', 'orgp_50', ...
                'pmin_20', 'pmin_30', 'pmin_40', 'pmin_50', ...
                'totp_20', 'totp_30', 'totp_40', 'totp_50'};    

    % (i) Flooding, water quantity and water quality
    if MP.run_water

        [~, sbcell_in_allcell_idx] = ismember(subbasin_cell.new2kid, cell_info.new2kid);

        % Preallocate structure for this option with vector to store results 
        results_table = array2table(nan(size(subbasin_cell.new2kid,1), 3 + 3 + 4 + length(colnames)), ...
                                    'VariableNames', ...
                                    [{'subctch_id', ...
                                      'new2kid', ...
                                      'hectares', ...
                                      'flood_value_30', ...
                                      'flood_value_30_100', ...
                                      'flood_value_30_100_1000', ...
                                      'non_use_value_20', ...
                                      'non_use_value_30', ...
                                      'non_use_value_40', ...
                                      'non_use_value_50'}, ...
                                      colnames]);
        results_table.subctch_id = subbasin_cell.subctch_id;
        results_table.new2kid = subbasin_cell.new2kid;
        results_table.hectares = subbasin_cell.hectares;

        % Convert PV and out structures to tables for ease of extracting
        % cells in loop
        PV_updated_table = struct2table(PV_updated);
        out_table = struct2table(out);
        
        % Set up index for permuting columns of es_water
        [es_water, ~] = fcn_run_water_elms(MP.water_data_folder, table2struct(PV_updated_table(sbcell_in_allcell_idx(1),:),'ToScalar',true), table2struct(out_table(sbcell_in_allcell_idx(1),:),'ToScalar',true), subbasin_cell.basin_id(1), 0, 0, subbasin_cell.basin_id(1));
        [es_water, ~] = fcn_run_water_transfer_elms(MP.water_transfer_data_folder, ...
                                                    table2struct(PV_updated_table(sbcell_in_allcell_idx(1),:),'ToScalar',true), ...
                                                    table2struct(out_table(sbcell_in_allcell_idx(1),:),'ToScalar',true), ...
                                                    subbasin_cell.basin_id(1), ...
                                                    0, ...
                                                    0, ...
                                                    subbasin_cell.basin_id(1));
                                                    
                                               
        [~, colidx] = ismember(colnames, es_water.Properties.VariableNames);     
        
        % Preallocate arrays for saving within parfor loop
        flood_result_30 = zeros(size(subbasin_cell.new2kid,1),1);
        flood_result_30_100 = zeros(size(subbasin_cell.new2kid,1),1);
        flood_result_30_100_1000 = zeros(size(subbasin_cell.new2kid,1),1);
        
        non_use_result_20 = zeros(size(subbasin_cell.new2kid,1),1);
        non_use_result_30 = zeros(size(subbasin_cell.new2kid,1),1);
        non_use_result_40 = zeros(size(subbasin_cell.new2kid,1),1);
        non_use_result_50 = zeros(size(subbasin_cell.new2kid,1),1);
        water_result = zeros(size(subbasin_cell.new2kid,1),length(colnames));

%         for i = 1:size(subbasin_cell.new2kid,1)
        parfor i = 1:size(subbasin_cell.new2kid,1)
            disp(i);

            % Get src_ids of subbasins affected by change
            affected_src_id = fcn_get_downstream_src_id(subbasin_cell.src_id(i), firstdownstream);

            % Run water model (and flood model within) and water non-use model for affected subbasins
            if ~isempty(affected_src_id)
                [es_water, es_water_flood] = fcn_run_water_elms(MP.water_data_folder, table2struct(PV_updated_table(sbcell_in_allcell_idx(i),:),'ToScalar',true), table2struct(out_table(sbcell_in_allcell_idx(i),:),'ToScalar',true), affected_src_id, 0, 0, subbasin_cell.src_id(i));

                % Sum value across affected subbasins to get flood value for this cell
                % results_table.flood_value(i) = nansum(es_water_flood.flood_value);
                flood_result_30(i) = nansum(es_water_flood.flood_value_30);
                flood_result_30_100(i) = nansum(es_water_flood.flood_value_30_100);
                flood_result_30_100_1000(i) = nansum(es_water_flood.flood_value_30_100_1000);
                                
                % Take water quantities from first affected subbasin as this is
                % the input subbasin
                % results_table(i, colnames) = es_water(1, colidx);
                input_src_id_ind = ismember(es_water.src_id, subbasin_cell.src_id(i));
                water_result(i,:) = table2array(es_water(input_src_id_ind, colidx));
                
                % Run non-use model
                es_water_non_use = fcn_run_water_non_use(MP.non_use_wq_data_folder, es_water);
                non_use_result_20(i) = es_water_non_use.value_ann_20;
                non_use_result_30(i) = es_water_non_use.value_ann_30;
                non_use_result_40(i) = es_water_non_use.value_ann_40;
                non_use_result_50(i) = es_water_non_use.value_ann_50;
            end
            
        end
        
        % Add results to table
        results_table.flood_value_30 = flood_result_30;
        results_table.flood_value_30_100 = flood_result_30_100;
        results_table.flood_value_30_100_1000 = flood_result_30_100_1000;
        results_table.non_use_value_20 = non_use_result_20;
        results_table.non_use_value_30 = non_use_result_30;
        results_table.non_use_value_40 = non_use_result_40;
        results_table.non_use_value_50 = non_use_result_50;
        results_table(:, colnames) = array2table(water_result, 'VariableNames', colnames);
    end
    
    % Save results table to water_results structure with ELM option
    % subscript, and save water_results to .mat file
    water_results.(elm_option) = results_table;
    save('Water Data/water_results.mat', 'water_results');
    
end

% Add no access options and save again
water_results.arable_reversion_sng_noaccess = water_results.arable_reversion_sng_access;
water_results.arable_reversion_wood_noaccess = water_results.arable_reversion_wood_access;
water_results.destocking_sng_noaccess = water_results.destocking_sng_access;
water_results.destocking_wood_noaccess = water_results.destocking_wood_access;

save('Water Data/water_results.mat', 'water_results');
