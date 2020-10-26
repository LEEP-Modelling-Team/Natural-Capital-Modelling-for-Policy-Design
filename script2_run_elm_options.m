%% two_run_elm_options.m
%  =====================
% Implement all ELM options for all farmers
% Calculate benefits, opportunity costs and benefit cost ratio for 5 years
% Save as elm_option_results.mat file
clear

% Set carbon price
% carbon_price_string = 'scc';
% carbon_price_string = 'nontraded_low';
% carbon_price_string = 'nontraded_central';
carbon_price_string = 'nontraded_high';

% Set proportion of non use values to take
% non_use_proportion = 1e-4;
non_use_proportion = 0.38;
% non_use_proportion = 0.75;
% non_use_proportion = 1;

% Set flooding assumption
assumption_flooding = 'low';				% low estimate
% assumption_flooding = 'medium';			% medium estimate
% assumption_flooding = 'high';             % high estimate

% Set non-use habitat assumption
assumption_areas = 'SDA';
% assumption_areas = 'LFA';

% Set non-use pollination assumptions
% WTP
assumption_wtp = 'low';
% assumption_wtp = 'high';

% Population
assumption_pop = 'low';
% assumption_pop = 'high';

% Set recreation assumption

% Set biodiversity value
biodiversity_unit_value = 0;			% turn biodiversity benefits off
% biodiversity_unit_value = 500;
% biodiversity_unit_value = 5000;

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
        '"run_biodiversity_jncc": true,' ...
        '"run_biodiversity_ucl": true,' ...
        '"run_pollination": true,' ...
        '"run_non_use_pollination": true,', ...
        '"run_non_use_habitat": true,', ...
        '"run_water": true,' ...
        '"run_water_non_use": true}'];

%% (1) Set up
%  ==========
% Set flag for server
% -------------------
server_flag = false; % Always set to false here - no server

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
carbon_price = fcn_get_carbon_price(conn, carbon_price_string);

% Calculate discount constants
% ----------------------------
discount_constants = fcn_calc_discount_constants(MP.discount_rate);

% Go from regional scale to 2km grid cells
% -----------------------------------------
% Returns cell ids and other info
cell_info = fcn_region_to_cell(conn, MP.feature_type, MP.id);

% Import primary variables from database
% --------------------------------------
% Set this to PV_original - should not be overwritten
% Any changes are set in PV_updated
PV_original = fcn_import_primary_variables(conn, cell_info);

% Load baseline results from .mat file
% ------------------------------------
% Created in script1_run_baseline.m script
% Depends on what carbon price has been used
% Used to calculate benefit under each ELM option scenario
load(['Script 1 (Baseline Runs)/baseline_results_', carbon_price_string, '.mat'], 'baseline')

% Load water results and related information
% ------------------------------------------
% Water quality (created in run_water_quality_results)
[water_quality_results, water_quality_cell2sbsn] = fcn_import_water_quality_info(conn);

% Water quality non use (created in run_water_results.m script)
[water_non_use_results, water_non_use_cell2sbsn] = fcn_import_water_non_use_info(conn);

% Flooding (created in run_flooding_transfer_results.m script)
[flooding_results_transfer, flooding_cell2subctch, nfm_data] = fcn_import_flooding_transfer_info(conn);

%% (2) Implement all ELM options for all farmers
%  =============================================
% (a) Set up
% ----------
% Define set of ELM options
% -------------------------
% Must run in this order for correct recreation benefit calculation
available_elm_options = {'arable_reversion_sng_access', ...     % arable reversion to semi-natural with recreation access
                         'destocking_sng_access', ...           % destocking to semi-natural with recreation access
                         'arable_reversion_wood_access', ...    % arable reversion to woodland with recreation access
                         'destocking_wood_access', ...          % destocking to woodland with recreation access
                         'arable_reversion_sng_noaccess', ...   % arable reversion to semi-natural with no recreation access
                         'destocking_sng_noaccess', ...         % destocking to semi-natural with no recreation access
                         'arable_reversion_wood_noaccess', ...  % arable reversion to woodland with no recreation access
                         'destocking_wood_noaccess'};           % destocking to woodland with no recreation access
num_elm_options = length(available_elm_options);

% Define number of benefits in simulation
% ---------------------------------------
% Calculated in fcn_calc_benefits, assumed to be in order:
% total, ghg_farm, forestry, ghg_forestry, ghg_soil_forestry, rec, flooding transfer, totn, totp, water_non_use, pollination, non use pollination, non use habitat, biodiversity
%% !!! biodiversity must be final column for combos to work !!!
num_benefits = 14;

% Define number of costs in simulation
% ------------------------------------
% Calculated in fcn_calc_benefits, assumed to be in order
% farm, forestry, rec, total
num_costs = 4;

% Define number of environmental and ecosystem service outcomes
% -------------------------------------------------------------
% Calculated in fcn_calc_outcomes, assumed to be in order
% env_outs: GHG, rec grass access, rec wood access, rec grass no access, rec wood no access, flood, tot n, tot p, pollinator species, biodiversity
% es_outs: GHG val, rec val, flood val, totn val, totp val, water non-use val, pollination val, non use pollination val, non use habitat, biodiversity val
%% !!! biodiversity must be final column for combos to work !!!
num_env_outs = 10;
num_es_outs = 10;

% Set up number of years for later loop
% -------------------------------------
years = 1:5;
num_years = length(1:5);

% (b) Preallocate structures and arrays to store results
% ------------------------------------------------------
% Set up structures with fields for each ELM option
for option_i = 1:num_elm_options
    elm_option = available_elm_options{option_i};                                   % ELM option string, to create field names
    elm_ha.(elm_option) = nan(cell_info.ncells, 1);                                 % hectares used to implement ELM option
    benefits.(elm_option) = nan(cell_info.ncells, num_years);                       % total benefits
    benefits_table.(elm_option) = nan(cell_info.ncells, num_benefits, num_years);   % benefits (see above)
    costs.(elm_option) = nan(cell_info.ncells, num_years);                          % total costs
    costs_table.(elm_option) = nan(cell_info.ncells, num_costs, num_years);         % costs (see above)
    benefit_cost_ratios.(elm_option) = nan(cell_info.ncells, num_years);            % benefit:cost ratio
    env_outs.(elm_option) = nan(cell_info.ncells, num_env_outs, num_years);         % environmental outcomes (see above)
    es_outs.(elm_option) = nan(cell_info.ncells, num_es_outs, num_years);           % ecosystem service outcomes (see above)
end

% (c) Run recreation with substitution
% ------------------------------------
% This is done for all ELM options, hence outside the ELM option loop
dorecmodel = false;
rec_all_options = fcn_run_recreation_all_options(dorecmodel, cell_info, MP, conn);

% (d) Main loop over ELM options
% ------------------------------    
for option_i = 1:num_elm_options
    elm_option = available_elm_options{option_i};
    disp(elm_option)

    %% (a) Implement this ELM option
    %  -----------------------------
    % PV_updated contains the updated land covers
    [PV_updated, ...
        elm_ha_option, ...
        scheme_length_option, ...
        site_type_option] = fcn_implement_elm_option(conn, ...
                                                     elm_option, ...
                                                     cell_info, ...
                                                     PV_original);
    
    % Save ELM hectares to elm_ha table
    elm_ha.(elm_option) = elm_ha_option;
        
    % Set up matrix of landuse hectare change (for use in forestry model)
    landuse_ha_change = [PV_updated.wood_ha - PV_original.wood_ha, ...
                         PV_updated.farm_ha - PV_original.farm_ha, ...
                         PV_updated.sngrass_ha - PV_original.sngrass_ha, ...
                         PV_updated.urban_ha - PV_original.urban_ha, ...
                         PV_updated.water_ha - PV_original.water_ha];
    
    %% (b) Run agriculture, forestry and GHG models
    %  --------------------------------------------
    % (i) Agriculture (+ GHG)
	% -----------------------
    if MP.run_agriculture
        % Use fcn_run_agriculture_elms function (not NEVO function)
        % Need to pass in PV_original as farmer not allowed to reoptimise
        es_agriculture = fcn_run_agriculture_elms(MP.agriculture_data_folder, ...
                                                  MP.agricultureghg_data_folder, ...
                                                  MP, ...
                                                  PV_original, ...
                                                  carbon_price(1:40), ...
                                                  elm_option, ...
                                                  elm_ha_option);              
    end
    
    % (ii) Forestry (+ GHG)
	% ---------------------
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
    % (i) Recreation
	% --------------
    if MP.run_recreation
        % See above fcn_run_recreation_all_options function
        switch elm_option
            case {'arable_reversion_sng_access', 'destocking_sng_access', 'arable_reversion_wood_access', 'destocking_wood_access'}
				% ELM options with access take their named field from rec_all_options structure
                es_recreation = rec_all_options.(elm_option);
            case {'arable_reversion_sng_noaccess', 'destocking_sng_noaccess', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'}
				% ELM options with no access take the no_access field
                es_recreation = rec_all_options.no_access;
            otherwise
				% Combinations are set later - we add together benefits etc
				% This is an approximation!
                error('ELM option not found.')
        end
        
		% Join es_recreation table to main out structure
        out = table2struct(join(struct2table(out), es_recreation), 'ToScalar', true);
    end
    
    % (ii) Biodiversity
	% -----------------
    % JNCC
    if MP.run_biodiversity_jncc
        es_biodiversity_jncc = fcn_run_biodiversity_jncc(MP.biodiversity_jncc_data_folder, PV_updated, out);
    end
    
    % UCL
    if MP.run_biodiversity_ucl
        es_biodiversity_ucl = fcn_run_biodiversity_ucl_old(MP.biodiversity_ucl_data_folder, out, 'rcp60', 'baseline');
    end
    
    % (iii) Pollination
    % -----------------
    if MP.run_pollination
        es_pollination = fcn_run_pollination(MP.pollination_data_folder, es_biodiversity_ucl, 'rcp60');
    end
    
    % (iv) Non Use Pollination
    % ------------------------
    if MP.run_non_use_pollination
        es_non_use_pollination = fcn_run_non_use_pollination(MP.non_use_pollination_data_folder, es_biodiversity_ucl, 'rcp60', assumption_wtp, assumption_pop, non_use_proportion);
    end
    
    % (v) Non Use Habitat
    % -------------------
    if MP.run_non_use_habitat
        non_use_habitat_landuses = array2table([PV_updated.new2kid, ...
                                                PV_updated.sngrass_ha - PV_original.sngrass_ha, ...
                                                PV_updated.wood_ha - PV_original.wood_ha], ...
                                                'VariableNames', ...
                                                {'new2kid', 'sngrass_ha', 'wood_ha'});
        es_non_use_habitat = fcn_run_non_use_habitat(MP.non_use_habitat_data_folder, non_use_habitat_landuses, non_use_proportion, assumption_areas);
        % Set values to zero for "no access" options
        if strcmp(elm_option, {'arable_reversion_sng_noaccess', 'destocking_sng_noaccess', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'})
            es_non_use_habitat.nu_habitat_val_sngrass = zeros(cell_info.ncells, 1);
            es_non_use_habitat.nu_habitat_val_wood = zeros(cell_info.ncells, 1);
            es_non_use_habitat.nu_habitat_val = zeros(cell_info.ncells, 1);
        end
    end
    
    % (vi) Flooding, Water Quality Non-Use & Water Quantities
	% -------------------------------------------------------
    if MP.run_water
        % Water quality
        water_quality_table = fcn_run_water_quality_from_results(cell_info, elm_option, elm_ha_option, water_quality_results, water_quality_cell2sbsn);
        
        % Water quality non use
        water_non_use_table = fcn_run_water_non_use_from_results(cell_info, elm_option, elm_ha_option, water_non_use_results, water_non_use_cell2sbsn, non_use_proportion);
        
        % Flooding
        flooding_transfer_table = fcn_run_flooding_transfer_from_results(cell_info, elm_option, elm_ha_option, flooding_results_transfer, flooding_cell2subctch, nfm_data, assumption_flooding);
        
        % !!! temporary: move chgq5 from non use to flooding
        flooding_transfer_table = [flooding_transfer_table, water_non_use_table(:, {'chgq5_20', 'chgq5_30', 'chgq5_40', 'chgq5_50'})];
        water_non_use_table = water_non_use_table(:, {'new2kid', 'non_use_value_20', 'non_use_value_30', 'non_use_value_40', 'non_use_value_50'});
    end    

    %% (d) Calculate benefits, opportunity cost and benefit cost ratio in 5 year loop
    %  ------------------------------------------------------------------------------
    for i = years
        disp(i)
        
        %% Benefits, costs, benefit cost ratios
        % (i) Calculate benefits and costs
        % --------------------------------
        [benefits_npv_table_i, costs_npv_table_i] = fcn_calc_benefits(MP, ...
                                                                      i, ...
                                                                      elm_option, ...
                                                                      scheme_length_option, ...
                                                                      discount_constants, ...
                                                                      carbon_price, ...
                                                                      baseline, ...
                                                                      es_agriculture, ...
                                                                      es_forestry, ...
                                                                      out, ...
                                                                      water_quality_table, ...
                                                                      water_non_use_table, ...
                                                                      flooding_transfer_table, ...
                                                                      es_pollination, ...
                                                                      es_non_use_pollination, ...
                                                                      es_non_use_habitat, ...
                                                                      es_biodiversity_jncc, ...
                                                                      biodiversity_unit_value);
        
        % (ii) Add cost of establishing recreation paths
        %  ---------------------------------------------
        if site_type_option == "path_chg"
            % Set to zero under existing paths
            costs_npv_table_i.rec = zeros(size(costs_npv_table_i, 1), 1);
        else
            % Calculate length of paths around perimeter of new area (taken from rec code)
            pathlen  = min(2 * pi * sqrt(elm_ha.(elm_option) * 10000 / pi), 10000);
            % values from: https://www.pathsforall.org.uk/resources/resource/estimating-price-guide-for-path-projects
            costs_npv_table_i.rec = (4.23 + 16.95) * pathlen + 534.31;
        end
        
        % (iii) Calculate total costs
        % ---------------------------
        costs_npv_table_i.total = costs_npv_table_i.farm + costs_npv_table_i.forestry + costs_npv_table_i.rec;
                
        % (iv) Calculate benefit cost ratio using NPVs
        %  -------------------------------------------
        % !!! introduces NaN and Inf values by dividing by zero
        % !!! all of these cases are where there is no farm_ha to start with
        % !!! these are removed in payment mechanisms so shouldn't be a problem
        benefit_cost_ratio_i = benefits_npv_table_i.total ./ costs_npv_table_i.total;
        
        %% Environmental outcomes
        % Calculate change in environmental outcomes from baseline
        % --------------------------------------------------------
        env_outs_table_i = fcn_calc_quantities(i, ...
                                               scheme_length_option, ...
                                               baseline, ...
                                               es_agriculture, ...
                                               out, ...
                                               elm_option, ...
                                               elm_ha_option, ...
                                               water_quality_table, ...
                                               flooding_transfer_table, ...
                                               es_biodiversity_jncc, ...
                                               es_biodiversity_ucl);
        
        %% Ecosystem services
        % Use benefits calculated above
        
        % Combine GHG benefits from all sources
        combined_ghg = sum(table2array(benefits_npv_table_i(:, {'ghg_farm', 'ghg_forestry', 'ghg_soil_forestry'})), 2);
        
        % Create table with combined GHGs and other benefits from above
        es_outs_table_i = [array2table(combined_ghg, 'VariableNames', {'ghg'}), ...
                           benefits_npv_table_i(:, {'rec', ...
                                                    'flooding', ...
                                                    'totn', ...
                                                    'totp', ...
                                                    'water_non_use', ...
                                                    'pollination', ...
                                                    'non_use_pollination', ...
                                                    'non_use_habitat', ...
                                                    'bio'})];

        %% Save to preallocated structures
        % --------------------------------
        % Have to convert tables to arrays due to array dimensions
        benefits.(elm_option)(:, i)             = benefits_npv_table_i.total;
        benefits_table.(elm_option)(:, :, i)    = table2array(benefits_npv_table_i);
        costs.(elm_option)(:, i)                = costs_npv_table_i.total;
        costs_table.(elm_option)(:, :, i)       = table2array(costs_npv_table_i);
        benefit_cost_ratios.(elm_option)(:, i)  = benefit_cost_ratio_i;
        env_outs.(elm_option)(:, :, i)          = table2array(env_outs_table_i);
        es_outs.(elm_option)(:, :, i)           = table2array(es_outs_table_i);
        
    end
end

%% (3) Construct combinations of ELMs options
%  ==========================================
% Construct feasible combinations and give them a name
% ----------------------------------------------------
combo_matrix = [1, 1, 0, 0, 0, 0, 0, 0; ...
				1, 0, 1, 0, 0, 0, 0, 0; ...
				0, 0, 1, 1, 0, 0, 0, 0; ...
				0, 1, 0, 1, 0, 0, 0, 0; ...
				0, 0, 0, 0, 1, 1, 0, 0; ...
				0, 0, 0, 0, 1, 0, 1, 0; ...
				0, 0, 0, 0, 0, 0, 1, 1; ...
				0, 0, 0, 0, 0, 1, 0, 1];
elm_combos = {'ar_sng_d_sng', 'ar_sng_d_w', 'ar_w_d_sng', 'ar_w_d_w','ar_sng_d_sng_na', 'ar_sng_d_w_na', 'ar_w_d_sng_na', 'ar_w_d_w_na'};
num_elm_combos = length(elm_combos);

% Combine benefits, costs, outcomes etc for combinations
% ------------------------------------------------------
for i = 1:num_elm_combos
    % Get strings of two individual options for this combo
	% Use strings to extract correct fields from structures
    combo_two_options = available_elm_options(combo_matrix(:,i)==1);
    
    % Add ELM hectares
    elm_ha.(elm_combos{i}) = elm_ha.(combo_two_options{1}) + elm_ha.(combo_two_options{2});
    
    % Add benefits
    benefits.(elm_combos{i}) = benefits.(combo_two_options{1}) + benefits.(combo_two_options{2});
    
    % Add benefits in table
    benefits_table.(elm_combos{i}) = benefits_table.(combo_two_options{1}) + benefits_table.(combo_two_options{2});
    
    % Add costs
    costs.(elm_combos{i}) = costs.(combo_two_options{1}) + costs.(combo_two_options{2});
    
    % Add costs in table
    costs_table.(elm_combos{i}) = costs_table.(combo_two_options{1}) + costs_table.(combo_two_options{2});
    
    % Add environmental outcomes (but take maximum of biodiversity score)
    %% !!! assumes biodiversity is final column !!!
	max_biodiversity = max(env_outs.(combo_two_options{1})(:, end, :), env_outs.(combo_two_options{2})(:, end, :));
    env_outs.(elm_combos{i}) = [env_outs.(combo_two_options{1})(:, 1:(end - 1), :) + env_outs.(combo_two_options{2})(:, 1:(end - 1), :), max_biodiversity];
    
    % Add ecosystem service outcomes (but take maximum of biodiversity value)
    %% !!! assumes biodiversity is final column !!!
	max_biodiversity_value = max(es_outs.(combo_two_options{1})(:, end, :), es_outs.(combo_two_options{2})(:, end, :));
    es_outs.(elm_combos{i}) = [es_outs.(combo_two_options{1})(:, 1:(end - 1), :) + es_outs.(combo_two_options{2})(:, 1:(end - 1),:), max_biodiversity_value];
    
    % Calculate benefit cost ratios
    benefit_cost_ratios.(elm_combos{i}) = benefits.(elm_combos{i}) ./ costs.(elm_combos{i});
end 

% Finally, add combo names to available elm options
available_elm_options = [available_elm_options, elm_combos];

%% (4) Set maximum unit values for environmental outcome flat rates
%  ================================================================
% Flat rates cannot be larger than unit values
unit_value_max.bio = biodiversity_unit_value;

% N & P flat rates cannot be larger than maximum N & P benefits per unit
% Estimated from woodland destocking option
n_benefit_per_unit = benefits_table.destocking_wood_access(:, 8, 1) ./ env_outs.destocking_wood_access(:, 7, 1);
n_benefit_per_unit(isinf(n_benefit_per_unit)) = 0;
unit_value_max.n = max(n_benefit_per_unit);

p_benefit_per_unit = benefits_table.destocking_wood_access(:, 9, 1) ./ env_outs.destocking_wood_access(:, 8, 1);
p_benefit_per_unit(isinf(p_benefit_per_unit)) = 0;
unit_value_max.p = max(p_benefit_per_unit);

% GHG flat rate cannot be larger than maximum carbon price
unit_value_max.ghg = max(carbon_price);

% Flood flat rate cannot be larger than maximum flood benefit per unit
% estimated from woodland destocking option
flood_benefit_per_unit = benefits_table.destocking_wood_access(:, 7, 1) ./ env_outs.destocking_wood_access(:, 6, 1);
flood_benefit_per_unit(isinf(flood_benefit_per_unit)) = 0;
unit_value_max.flood = max(flood_benefit_per_unit);

% Non-use WQ maximum?

%% (5) Save results to .mat file
%  =============================
% Depends on what carbon price has been used
% This depends on choice of recreation access in MP.site_type
% Save ELM option strings, ELM option scheme length, ELM hectares, 
% benefits, opportunity costs and benefit cost ratios
save(['Script 2 (ELM Option Runs)/elm_option_results_', carbon_price_string, '.mat'], ...
     'num_benefits', ...
     'num_costs', ...
     'num_env_outs', ...
     'num_es_outs', ...
     'available_elm_options', ...
     'elm_ha', ...
     'benefits', ...
     'benefits_table', ...
     'costs', ...
     'costs_table', ...
     'benefit_cost_ratios', ...
     'env_outs', ...
     'es_outs', ...
     'unit_value_max');
