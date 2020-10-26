%% run_flooding_transfer_results.m
clear

% Define available ELM options
% (comment out as necessary)
% available_elm_options = {'destocking_wood_access'};
available_elm_options = {'arable_reversion_sng_access', ...
                         'destocking_sng_access', ...
                         'arable_reversion_wood_access', ...
                         'destocking_wood_access'};

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

% Add path to NEV model code
% --------------------------
addpath(genpath('C:/Users/neo204/OneDrive - University of Exeter/NEV/'))

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
load('C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Water Transfer\Input Output\firstdownstream.mat')

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

% FloodingTransfer data
% ---------------------
% Use event parameter = 7
load('C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Flooding Transfer\NEVO_Flooding_Transfer_data_7.mat')

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
    % land type in the subcatchment
    % Just consider cells in England here
    sqlquery = ['SELECT DISTINCT ON (tbl1.subctch_id) ' ...
                    'tbl1.subctch_id, ' ...
                    'tbl1.new2kid, ' ...
                    'tbl2.' land_type '_ha_20 * tbl1.proportion AS hectares ' ...                             
                'FROM regions_keys.key_grid_wfd_subcatchments AS tbl1 ' ...
                    'INNER JOIN nevo_explore.explore_2km AS tbl2 ON tbl1.new2kid = tbl2.new2kid ' ...
                    'INNER JOIN regions_keys.key_grid_countries_england AS tbl3 ON tbl1.new2kid = tbl3.new2kid ' ...
                'WHERE tbl2.' land_type '_ha_20 * tbl1.proportion > 0 ' ...
                'ORDER BY tbl1.subctch_id, tbl2.' land_type '_ha_20 * tbl1.proportion DESC'];
    setdbprefs('DataReturnFormat', 'table');
    dataReturn  = fetch(exec(conn, sqlquery));
    subctch_cell = dataReturn.Data;
    
    % Reduce to subcatchments with IO & land
    % --------------------------------------
    ind_run = ismember(subctch_cell.subctch_id, subctch_ids_run);
    subctch_cell = subctch_cell(ind_run, :);

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

    % (i) Flooding, water quantity and water quality
    if MP.run_water
        
        water_transfer_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Water Transfer\';
        flooding_transfer_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Flooding Transfer\';
        
        [~, sbcell_in_allcell_idx] = ismember(subctch_cell.new2kid, cell_info.new2kid);

        % Preallocate structure for this option with vector to store results
        flood_result_low = nan(size(subctch_cell.new2kid,1), 1);
        flood_result_medium = nan(size(subctch_cell.new2kid,1), 1);
        flood_result_high = nan(size(subctch_cell.new2kid,1), 1);
        
        results_table = array2table(nan(size(subctch_cell.new2kid,1), 3 + 3), ...
                                    'VariableNames', ...
                                    {'src_id', ...
                                     'new2kid', ...
                                     'hectares', ...
                                     'flood_value_low', ...
                                     'flood_value_medium', ...
                                     'flood_value_high'});
        results_table.subctch_id = subctch_cell.subctch_id;
        results_table.new2kid = subctch_cell.new2kid;
        results_table.hectares = subctch_cell.hectares;

        % Convert PV and out structures to tables for ease of extracting
        % cells in loop
        PV_updated_table = struct2table(PV_updated);
        out_table = struct2table(out);

        tic
        
%         for i = 1:size(subctch_cell.new2kid, 1)
        parfor i = 1:size(subctch_cell.new2kid, 1)
            % Print progress update
            disp(['Processing subcatchment ', ...
                  num2str(i), ' of ', num2str(size(subctch_cell.new2kid, 1)), ...
                  ' (', subctch_cell.subctch_id{i}, ')'])

            % Get src_ids of subbasins affected by change
            affected_subctch_id = fcn_get_downstream_subctch_id(subctch_cell.subctch_id(i), firstdownstream);
            
            % Are there damage costs associated with these subbasins?
            % Compute logical TRUE if any damage costs for affected_subctch_ids
            % are positive
            [~, FloodingTransfer_idx] = ismember(affected_subctch_id, FloodingTransfer.subctch_id);
            some_damage = any(any(table2array(FloodingTransfer(FloodingTransfer_idx, ...
                                                               {'damage_10', ...
                                                                'damage_30', ...
                                                                'damage_100', ...
                                                                'damage_200', ...
                                                                'damage_1000'}))));

            % Run water and flood models if:
            % a. subcatchments are affected AND
            % b. there is flood damage
            if ~isempty(affected_subctch_id) && some_damage
                % Run water transfer model to get flow time series
                % Use other_ha_string = 'baseline' so that other_ha is split normally
                % Also limit land cover change in subcatchment
                [~, flow_transfer_temp] = fcn_run_water_transfer(water_transfer_data_folder, ...
                                                                 out_table(sbcell_in_allcell_idx(i),:), ...
                                                                 affected_subctch_id, ...
                                                                 0, ...
                                                                 0, ...
                                                                 'baseline', ...
                                                                 subctch_cell.subctch_id(i));
                                                             
                % Run flood transfer model to calculate flood benefit
                es_flooding_transfer_temp = fcn_run_flooding_transfer(flooding_transfer_data_folder, ...
                                                                      affected_subctch_id, ...
                                                                      flow_transfer_temp, ...
                                                                      7);
            
                % Sum value across affected subbasins to get flood value for this cell
                flood_result_low(i) = nansum(es_flooding_transfer_temp.flood_value_low);
                flood_result_medium(i) = nansum(es_flooding_transfer_temp.flood_value_medium);
                flood_result_high(i) = nansum(es_flooding_transfer_temp.flood_value_high);
            end
            
            % Print progress update
            disp(['   Finished subcatchment ', ...
                  num2str(i), ' of ', num2str(size(subctch_cell.new2kid, 1)), ...
                  ' (', subctch_cell.subctch_id{i}, ')'])
        end
        
        toc
        
        % Add results to table
        results_table.flood_value_low = flood_result_low;
        results_table.flood_value_medium = flood_result_medium;
        results_table.flood_value_high = flood_result_high;
    end
    
    % Save results table to water_results structure with ELM option
    % subscript, and save water_results to .mat file
    flooding_transfer_results.(elm_option) = results_table;
    save('Water Data/flooding_transfer_results.mat', 'flooding_transfer_results');
    
end

% Add no access options and save again
flooding_transfer_results.arable_reversion_sng_noaccess = flooding_transfer_results.arable_reversion_sng_access;
flooding_transfer_results.arable_reversion_wood_noaccess = flooding_transfer_results.arable_reversion_wood_access;
flooding_transfer_results.destocking_sng_noaccess = flooding_transfer_results.destocking_sng_access;
flooding_transfer_results.destocking_wood_noaccess = flooding_transfer_results.destocking_wood_access;

save('Water Data/flooding_transfer_results.mat', 'flooding_transfer_results');
