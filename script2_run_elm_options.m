%  script2_run_elm_options.m
%  =========================
% Implement all ELM options for all farmers
% Calculate benefits, opportunity costs and benefit cost ratio for 5 years
% Save as elm_option_results.mat file
clear

tic    
% 1. Set up
% ----------

% 1.1 Connect to database
% -----------------------
server_flag = false;
conn = fcn_connect_database(server_flag);

% 1.2 Set model parameters
% ------------------------
json = ['{"id": "E92000001",'...
        '"feature_type": "integrated_countries",' ...
        '"run_lcs": true,' ...
        '"run_agriculture": true,' ...
        '"run_forestry": true,' ...
        '"run_recreation": true,' ...
        '"run_biodiversity_jncc": true,' ...
        '"run_biodiversity_ucl": true,' ...
        '"run_water": true,' ...
        '"run_pollination": true,' ...
        '"run_non_use_pollination": true,' ...
        '"run_non_use_habitat": true}'];
% Decode JSON object/string & set other default parameters
MP = fcn_set_model_parameters(conn, json, server_flag);

% 1.3 Connect to NEV Model
% ------------------------
addpath(genpath(MP.NEV_code_folder))

% 1.4 Go from regional scale to 2km grid cells
% --------------------------------------------
% Returns cell ids and other info
cell_info = fcn_region_to_cell(conn, MP.feature_type, MP.id);

% 1.5 Load baseline results from .mat file
% ----------------------------------------
% Created in script1_run_baseline.m script
% Depends on what carbon price has been used
% Used to calculate benefit under each ELM option scenario
baseline_structure_file = [MP.data_out, 'model_runs_baseline_', MP.carbon_price_str, '.mat'];
load(baseline_structure_file);
baseline_lcs = baseline.baseline_lcs;


%  2. ELM options
%  --------------

% 2.1 Define set of ELM options
% -----------------------------
% Must run in this order for correct recreation benefit calculation
elm_options = {'arable_reversion_sng_access', ...     % arable reversion to semi-natural with recreation access
               'destocking_sng_access', ...           % destocking to semi-natural with recreation access
               'arable_reversion_wood_access', ...    % arable reversion to woodland with recreation access
               'destocking_wood_access', ...          % destocking to woodland with recreation access
               'arable_reversion_sng_noaccess', ...   % arable reversion to semi-natural with no recreation access
               'destocking_sng_noaccess', ...         % destocking to semi-natural with no recreation access
               'arable_reversion_wood_noaccess', ...  % arable reversion to woodland with no recreation access
               'destocking_wood_noaccess'};           % destocking to woodland with no recreation access
num_elm_options = length(elm_options);

% 2.2. Define number of benefits in simulation
% --------------------------------------------
% Timber is a private benefit so is taken as a negative cost
vars_benefits = {'ghg_farm', ...
                 'ghg_dispfood', ...
                 'ghg_forestry', ...
                 'ghg_soil_forestry', ...
                 'rec', ...
                 'flooding', ...
                 'totn', ...
                 'totp', ...
                 'water_non_use', ...
                 'water_rec', ...
                 'pollination_yield', ...
                 'pollination_non_use', ...
                 'habitat_non_use', ...
                 'biodiversity'};
num_benefits = length(vars_benefits);

% 2.3 Define number of costs & benefits in simulation
% ---------------------------------------------------
vars_costs = {'farm', ...
              'forestry', ...
              'timber', ...
              'grass', ...
              'hay', ...              
              'rec'};
num_costs  = length(vars_costs);

% 2.4 Define number of environmental and ecosystem service outcomes
% -----------------------------------------------------------------
vars_env_outs = {'ghg', ...
                 'sng_rec', ...
                 'wood_rec', ...
                 'sng_norec', ...
                 'wood_norec', ...
                 'flood', ...
                 'tot_n', ...
                 'tot_p', ...
                 'pollinators', ...
                 'biodiversity'};
num_env_outs  = length(vars_env_outs);

vars_es_outs  = {'ghg', ...
                 'rec', ...
                 'flood', ...
                 'tot_n', ...
                 'tot_p', ...
                 'water_non_use' ...
                 'water_rec' ...
                 'poll_yield', ...
                 'poll_non_use', ...
                 'habitat_non_use', ...
                 'biodiversity'};
num_es_outs   = length(vars_es_outs);

% 2.5 Landcover variable lists
% ----------------------------
vars_arable     = {'arable', 'wheat', 'osr', 'wbar', 'sbar', 'pot', 'sb', 'other'};
vars_grass_ha   = {'grass', 'tgrass', 'pgrass', 'rgraz'};
vars_grass_food = {'livestock', 'dairy', 'beef', 'sheep'};

% 2.6 Years of Scheme
% -------------------
scheme_years = 1:5;
num_scheme_years = length(scheme_years);


% 3. NEV Model Runs Under Each Option
% -----------------------------------
% Load existing elm_model_runs structure
elms_data_matfile_filename = [MP.data_out, 'model_runs_elm_', MP.carbon_price_str, '.mat'];
if exist(elms_data_matfile_filename, 'file') == 2
    load(elms_data_matfile_filename);
end
% Open matfile on disk to overwrite with new model runs
elms_data_matfile = matfile(elms_data_matfile_filename, 'Writable', true);

    
% 3.1 Landcovers
% --------------
if MP.run_lcs
    
    clear elm_ha option_lcs_all land_type_ha

    for option_i = 1:num_elm_options

        elm_option = elm_options{option_i};

        % 3.1.1 Option Land Covers
        % ------------------------
        option_lcs = baseline_lcs;

        % Area of land into option: Since baseline_lcs rescaled to keep
        % arable_ha and grass_ha constant at first decade averages, taking 
        % Year 1 data is same as any other.

        % Land Use From
        % -------------
        if contains(elm_option, 'arable')
            % Arable
            % ------
            elm_option_ha = option_lcs.arable_ha(:,1); 
            for i = 1:length(vars_arable) 
                eval(['option_lcs.' vars_arable{i} '_ha = zeros(size(baseline_lcs.' vars_arable{i} '_ha));']);
                for t = 20:10:50
                    eval(['option_lcs.' vars_arable{i} '_ha_' num2str(t) ' = zeros(size(baseline_lcs.' vars_arable{i} '_ha_' num2str(t) '));']);
                end
            end
        else
            % Grass
            % -----
            elm_option_ha = option_lcs.grass_ha(:,1);
            for i = 1:length(vars_grass_ha) 
                eval(['option_lcs.' vars_grass_ha{i} '_ha = zeros(size(baseline_lcs.' vars_grass_ha{i} '_ha));']);
                for t = 20:10:50
                    eval(['option_lcs.' vars_grass_ha{i} '_ha_' num2str(t) ' = zeros(size(baseline_lcs.' vars_grass_ha{i} '_ha_' num2str(t) '));']);
                end
            end
        end
        elm_ha.(elm_option) = elm_option_ha;

        % Land Use To
        % -----------       
        if contains(elm_option, 'wood')
            % Woods
            % -----        
            option_lcs.farm_ha = option_lcs.farm_ha - elm_option_ha;        
            option_lcs.wood_ha = option_lcs.wood_ha + elm_option_ha;
        else
            % Semi-Natural Grassland
            % ----------------------        
            option_lcs.farm_ha    = option_lcs.farm_ha    - elm_option_ha;
            option_lcs.sngrass_ha = option_lcs.sngrass_ha + elm_option_ha;
        end

        option_lcs_all.(elm_option) = option_lcs;

    end
    
    % Save to matfile
    elms_data_matfile.elm_ha         = elm_ha;
    elms_data_matfile.option_lcs_all = option_lcs_all;    
    
end

% 3.2 Agriculture
% ---------------
if MP.run_agriculture
    
    for option_i = 1:num_elm_options

        elm_option = elm_options{option_i};

        % 3.2.1 Agriculture (+ GHG)
        % -------------------------
        % Note: Data has been rescaled so same arable and grass extent
        % across all 40 years of time series. Do not call NEV agriculture
        % model again here with grass or arable removed as this would
        % re-optimise across the smaller farm_ha area and result in yet
        % more grass or arable being generated on the smaller farm. Instead
        % simply lose all grass or arable benefits and costs from original
        % model run.        
        es_agriculture = baseline.es_agriculture;

        if contains(elm_option, 'arable')
            % Arable Option
            % -------------
            es_agriculture.farm_ha         = es_agriculture.farm_ha         - es_agriculture.arable_ha;
            es_agriculture.farm_profit     = es_agriculture.farm_profit     - es_agriculture.arable_profit;
            es_agriculture.farm_profit_ann = es_agriculture.farm_profit_ann - es_agriculture.arable_profit_ann;
            es_agriculture.ghg_farm        = es_agriculture.ghg_farm        - es_agriculture.ghg_arable;
            es_agriculture.ghg_farm_ann    = es_agriculture.ghg_farm_ann    - es_agriculture.ghg_arable_ann;
            for i = 1:length(vars_arable)         
                eval(['es_agriculture.', vars_arable{i}, '_ha         = zeros(size(es_agriculture.', vars_arable{i}, '_ha));']);                
                eval(['es_agriculture.', vars_arable{i}, '_profit     = zeros(size(es_agriculture.', vars_arable{i}, '_profit));']);                
                eval(['es_agriculture.', vars_arable{i}, '_profit_ann = zeros(size(es_agriculture.', vars_arable{i}, '_profit_ann));']);                
                eval(['es_agriculture.ghg_', vars_arable{i}, '        = zeros(size(es_agriculture.ghg_', vars_arable{i}, '));']);                
                eval(['es_agriculture.ghg_', vars_arable{i}, '_ann    = zeros(size(es_agriculture.ghg_', vars_arable{i}, '_ann));']);                    
            end    
            es_agriculture.arable_food = zeros(size(es_agriculture.arable_food));

        else
            % Grass Option
            % ------------
            es_agriculture.farm_ha         = es_agriculture.farm_ha         - es_agriculture.grass_ha;
            es_agriculture.farm_profit     = es_agriculture.farm_profit     - es_agriculture.livestock_profit;
            es_agriculture.farm_profit_ann = es_agriculture.farm_profit_ann - es_agriculture.livestock_profit_ann;
            es_agriculture.ghg_farm        = es_agriculture.ghg_farm        - es_agriculture.ghg_grass     - es_agriculture.ghg_livestock;
            es_agriculture.ghg_farm_ann    = es_agriculture.ghg_farm_ann    - es_agriculture.ghg_grass_ann - es_agriculture.ghg_livestock_ann;            
            for i = 1:length(vars_grass_ha)         
                eval(['es_agriculture.', vars_grass_ha{i}, '_ha      = zeros(size(es_agriculture.', vars_grass_ha{i}, '_ha));']);                
                eval(['es_agriculture.ghg_', vars_grass_ha{i}, '     = zeros(size(es_agriculture.ghg_', vars_grass_ha{i}, '));']);                
                eval(['es_agriculture.ghg_', vars_grass_ha{i}, '_ann = zeros(size(es_agriculture.ghg_', vars_grass_ha{i}, '_ann));']);                
            end   
            for i = 1:length(vars_grass_food)         
                eval(['es_agriculture.', vars_grass_food{i}, '_profit     = zeros(size(es_agriculture.', vars_grass_food{i}, '_profit));']);                
                eval(['es_agriculture.', vars_grass_food{i}, '_profit_ann = zeros(size(es_agriculture.', vars_grass_food{i}, '_profit_ann));']); 
                eval(['es_agriculture.ghg_', vars_grass_food{i}, '        = zeros(size(es_agriculture.ghg_', vars_grass_food{i}, '));']);                
                eval(['es_agriculture.ghg_', vars_grass_food{i}, '_ann    = zeros(size(es_agriculture.ghg_', vars_grass_food{i}, '_ann));']);                       
            end   
            es_agriculture.dairy_food = zeros(size(es_agriculture.dairy_food));
            es_agriculture.beef_food  = zeros(size(es_agriculture.beef_food));
            es_agriculture.sheep_food = zeros(size(es_agriculture.sheep_food));

        end

        es_agriculture_all.(elm_option) = es_agriculture;
    end
    
    elms_data_matfile.es_agriculture_all = es_agriculture_all;
   
end

% 3.3  Forestry
% -------------
if MP.run_forestry 
    
    for option_i = 1:num_elm_options

        elm_option = elm_options{option_i};

        % Changes in land use from option
        landuses_chg.new2kid        = baseline_lcs.new2kid;
        landuses_chg.wood_ha_chg    = option_lcs_all.(elm_option).wood_ha    - baseline_lcs.wood_ha;
        landuses_chg.sngrass_ha_chg = option_lcs_all.(elm_option).sngrass_ha - baseline_lcs.sngrass_ha;
        landuses_chg.arable_ha_chg  = es_agriculture_all.(elm_option).arable_ha(:,1) - baseline_lcs.arable_ha(:,1);
        landuses_chg.tgrass_ha_chg  = es_agriculture_all.(elm_option).tgrass_ha(:,1) - baseline_lcs.tgrass_ha(:,1);
        landuses_chg.pgrass_ha_chg  = es_agriculture_all.(elm_option).pgrass_ha(:,1) - baseline_lcs.pgrass_ha(:,1);
        landuses_chg.rgraz_ha_chg   = es_agriculture_all.(elm_option).rgraz_ha(:,1)  - baseline_lcs.rgraz_ha(:,1);

        % Note: Even if no woodland planted, timber benefits and costs
        % arise from extant managed forest in certain cells. These net out
        % of benefit & cost calculations subsequently.          
        es_forestry = fcn_run_forestry(MP.forest_data_folder, ...
                                       MP.forestghg_data_folder, ...
                                       MP, ...
                                       landuses_chg, ...
                                       MP.carbon_price);
        es_forestry_all.(elm_option) = es_forestry;

    end

    elms_data_matfile.es_forestry_all = es_forestry_all;
    
end

% 3.4 Recreation
% --------------
if MP.run_recreation
    % The recreation benefits calculations for woodland assume a
    % transition over the growth period from benefits of rec from grass
    % to benefits of rec from woodland. Hence the woodland options need
    % the grass rec benefits as well. To that end, the es_recreation
    % structure runs all option recreation models on first run through.
    % Values returned from the ORVal model are already as changes from 
    % baseline
    es_recreation_all = fcn_run_recreation_all_options(MP, ...
                                                       baseline_lcs.new2kid, ...
                                                       baseline_lcs.arable_ha(:,1), ...
                                                       baseline_lcs.grass_ha(:,1));
                                                   
    elms_data_matfile.es_recreation_all = es_recreation_all;  
    
end

% 3.5 Biodiversity, Pollination & Habitat
% ---------------------------------------
for option_i = 1:num_elm_options
    
    elm_option = elm_options{option_i};
    
    % 3.5.1 Biodiversity
	% ------------------
    % JNCC
    if MP.run_biodiversity_jncc
        es_biodiversity_jncc_all.(elm_option) = fcn_run_biodiversity_jncc(MP.biodiversity_data_folder_jncc, option_lcs_all.(elm_option), 'future', 'baseline');
    end
    
    % UCL
    if MP.run_biodiversity_ucl
        es_biodiversity_ucl_all.(elm_option) = fcn_run_biodiversity_ucl(MP.biodiversity_data_folder, option_lcs_all.(elm_option), 'rcp60', 'baseline');
    end
    
    % 3.5.2 Pollination: Horticultural Yield
    % --------------------------------------
    if MP.run_pollination
        es_pollination_all.(elm_option) = fcn_run_pollination(MP.pollination_data_folder, es_biodiversity_ucl_all.(elm_option), 'rcp60');
    end
    
    % 3.5.3 Pollination: Wildflower Non-Use
    % -------------------------------------
    if MP.run_non_use_pollination
        es_non_use_pollination_all.(elm_option) = fcn_run_non_use_pollination(MP.non_use_pollination_data_folder, es_biodiversity_ucl_all.(elm_option), 'rcp60', MP.assumption_wtp, MP.assumption_pop, MP.non_use_proportion);
    end
    
    % 3.5.4 Non Use Habitat
    % ---------------------
    if MP.run_non_use_habitat

        landuses_chg.new2kid        = baseline_lcs.new2kid;
        landuses_chg.wood_ha_chg    = option_lcs_all.(elm_option).wood_ha    - baseline_lcs.wood_ha;
        landuses_chg.sngrass_ha_chg = option_lcs_all.(elm_option).sngrass_ha - baseline_lcs.sngrass_ha;
        
        non_use_habitat_landuses = array2table([landuses_chg.new2kid, ...
                                                landuses_chg.sngrass_ha_chg, ...
                                                landuses_chg.wood_ha_chg], ...
                                                'VariableNames', ...
                                                {'new2kid', 'sngrass_ha', 'wood_ha'});
        es_non_use_habitat_all.(elm_option) = fcn_run_non_use_habitat(MP.non_use_habitat_data_folder, non_use_habitat_landuses, MP.non_use_proportion, MP.assumption_areas);
        % Set values to zero for "no access" options
        if contains(elm_option, 'noaccess')
            es_non_use_habitat_all.(elm_option).nu_habitat_val_sngrass = zeros(cell_info.ncells, 1);
            es_non_use_habitat_all.(elm_option).nu_habitat_val_wood    = zeros(cell_info.ncells, 1);
            es_non_use_habitat_all.(elm_option).nu_habitat_val         = zeros(cell_info.ncells, 1);
        end
    end
end    
% JNCC
if MP.run_biodiversity_jncc
    elms_data_matfile.es_biodiversity_jncc_all = es_biodiversity_jncc_all;
end
% UCL
if MP.run_biodiversity_ucl
    elms_data_matfile.es_biodiversity_ucl_all = es_biodiversity_ucl_all;
end
% Pollination: Horticultural Yield
if MP.run_pollination
     elms_data_matfile.es_pollination_all = es_pollination_all;
end
if MP.run_non_use_pollination
    elms_data_matfile.es_non_use_pollination_all = es_non_use_pollination_all;
end
% Pollination: Wildflower Non-Use
if MP.run_non_use_habitat
     elms_data_matfile.es_non_use_habitat_all = es_non_use_habitat_all;
end
       
% 3.6 Flooding, Water Treatment & Water Non-Use
% ---------------------------------------------
if MP.run_water

    % 3.6.2 Load water results and related information
    % ------------------------------------------------
    % Water transfer results, including water quality, non-use and flooding
    % (created running scripts 1 to 6 in Water_Runs)
    [water_transfer_results, water_transfer_cell2subctch, nfm_data] = fcn_import_water_transfer_info(conn, MP);

    % As per recreation, water benefits for wood options are supposed
    % to grow from sng to full wood over growing period. As such
    % need sng and wood values for wood options in advance so do all
    % options here on first iteration.

    % 3.6.2 Flooding
    % --------------
    for opt = elm_options
        if contains(opt{1}, 'arable')
            opt_ha = baseline_lcs.arable_ha(:,1); 
        else
            opt_ha = baseline_lcs.grass_ha(:,1);
        end
        es_flood_all.(opt{1}) = fcn_run_flooding_transfer_from_results(cell_info, opt{1}, opt_ha, water_transfer_results, water_transfer_cell2subctch, nfm_data, MP.assumption_flooding);
    end
    elms_data_matfile.es_flood_all = es_flood_all;

    % 3.6.3 Water Quality: Water Treatment
    % ------------------------------------
    for opt = elm_options
        if contains(opt{1}, 'arable')
            opt_ha = baseline_lcs.arable_ha(:,1); 
        else
            opt_ha = baseline_lcs.grass_ha(:,1);
        end
        es_water_quality_all.(opt{1}) = fcn_run_water_quality_transfer_from_results(cell_info, opt{1}, opt_ha, water_transfer_results, water_transfer_cell2subctch);                 
    end
    elms_data_matfile.es_water_quality_all = es_water_quality_all;
    
    % 3.6.4 Water Quality: Non-Use
    % ----------------------------
    for opt = elm_options
        if contains(opt{1}, 'arable')
            opt_ha = baseline_lcs.arable_ha(:,1); 
        else
            opt_ha = baseline_lcs.grass_ha(:,1);
        end
        es_water_non_use_all.(opt{1}) = fcn_run_water_non_use_transfer_from_results(cell_info, opt{1}, opt_ha, water_transfer_results, water_transfer_cell2subctch, MP.non_use_proportion);                 
    end
    elms_data_matfile.es_water_non_use_all = es_water_non_use_all;
    
    % 3.6.5 Water Quality: Recreation
    % -------------------------------
    for opt = elm_options
        if contains(opt{1}, 'arable')
            opt_ha = baseline_lcs.arable_ha(:,1); 
        else
            opt_ha = baseline_lcs.grass_ha(:,1);
        end
        es_water_rec_all.(opt{1}) = fcn_run_water_recreation_transfer_from_results(cell_info, opt{1}, opt_ha, water_transfer_results, water_transfer_cell2subctch, MP.non_use_proportion);                 
    end
    elms_data_matfile.es_water_rec_all = es_water_rec_all;
    
end


% 4. Benefit & Cost Calculations
% ------------------------------

% Initialise Benefits and Cost Structures
% ---------------------------------------
for option_i = 1:num_elm_options
    elm_option                       = elm_options{option_i};                                   % ELM option string, to create field names
    benefits.(elm_option)            = nan(cell_info.ncells, num_scheme_years);                 % total benefits
    benefits_table.(elm_option)      = nan(cell_info.ncells, num_benefits, num_scheme_years);   % benefits (see above)
    costs.(elm_option)               = nan(cell_info.ncells, num_scheme_years);                 % total costs
    costs_table.(elm_option)         = nan(cell_info.ncells, num_costs, num_scheme_years);      % costs (see above)
    benefit_cost_ratios.(elm_option) = nan(cell_info.ncells, num_scheme_years);                 % benefit:cost ratio
    env_outs.(elm_option)            = nan(cell_info.ncells, num_env_outs, num_scheme_years);   % environmental outcomes (see above)
    es_outs.(elm_option)             = nan(cell_info.ncells, num_es_outs, num_scheme_years);    % ecosystem service outcomes (see above)
end

for option_i = 1:num_elm_options
    
    elm_option = elm_options{option_i};

    % 4.1 Agriculture
    % ---------------
    opp_cost_farm_npv = fcn_calc_npv_agriculture(baseline.es_agriculture, es_agriculture_all.(elm_option), MP);
    % Returned as negative benefit so invert sign for cost
    opp_cost_farm_npv = -opp_cost_farm_npv;
    
    % 4.2 Forest
    % ----------
    [benefit_forestry_npv, cost_forestry_npv] = fcn_calc_npv_forestry(baseline, es_forestry_all.(elm_option), MP);

    % 4.3 Grassland
    % -------------
    sngrass_ha_chg = option_lcs_all.(elm_option).sngrass_ha - baseline_lcs.sngrass_ha;
    [benefit_grass_npv, cost_grass_npv] = fcn_calc_npv_grass(MP, sngrass_ha_chg);
    
    % 4.4 Greenhouse Gases
    % --------------------
    [benefit_ghg_farm_npv, benefit_ghg_dispfood_npv, benefit_ghg_forestry_npv, benefit_ghg_soil_forestry_npv] = fcn_calc_npv_ghg(baseline, es_agriculture_all.(elm_option), es_forestry_all.(elm_option), MP);
    benefit_ghg_npv = benefit_ghg_farm_npv + benefit_ghg_dispfood_npv + benefit_ghg_forestry_npv + benefit_ghg_soil_forestry_npv;
    
    % 4.5 Recreation
    % --------------
    [benefit_rec_npv, cost_rec_npv] = fcn_calc_npv_recreation_substitution(MP, elm_option, elm_ha.(elm_option), es_recreation_all);
    
    % 4.6 Flooding
    % ------------
    benefit_flood_npv = fcn_calc_npv_water_flood(MP, elm_option, es_flood_all);
    
    % 4.7 Water Quality Treatment
    % ---------------------------
    [benefit_totn_npv, benefit_totp_npv] = fcn_calc_npv_water_quality(MP, elm_option, es_water_quality_all);
    
    % 4.8 Water Quality Non-Use
    % -------------------------
    benefit_water_non_use_npv = fcn_calc_npv_water_non_use(MP, elm_option, es_water_non_use_all);
 
    % 4.9 Water Quality Recreation
    % ----------------------------
    benefit_water_rec_npv = fcn_calc_npv_water_recreation(MP, elm_option, es_water_rec_all);
          
    % 4.10 Pollination: Horticultural Yields
    % --------------------------------------
    benefit_pollination_yield_npv = fcn_calc_npv_pollination(MP, elm_option, es_pollination_all);
        
    % 4.11 Pollination: Wildflower Non-Use 
    % ------------------------------------
    benefit_pollination_non_use_npv = fcn_calc_npv_pollination_non_use(MP, elm_option, es_non_use_pollination_all);
    
    % 4.12 Non Use Habitat
    % --------------------
    benefit_habitat_non_use_npv = fcn_calc_npv_non_use_habitat(MP, elm_option, es_non_use_habitat_all);
    
    % 4.13 Biodiversity
    % -----------------
    benefit_bio_npv = fcn_calc_npv_biodiversity(MP, elm_option, es_biodiversity_jncc_all, baseline, MP.biodiversity_unit_value);
    
    for t = scheme_years
        
        % 4.14 Collect benefits for each scheme year
        % ------------------------------------------
        benefits_t = [benefit_ghg_farm_npv(:,t), ...
                      benefit_ghg_dispfood_npv(:,t), ...
                      benefit_ghg_forestry_npv(:,t), ...
                      benefit_ghg_soil_forestry_npv(:,t), ...
                      benefit_rec_npv(:,t), ...
                      benefit_flood_npv(:,t), ...
                      benefit_totn_npv(:,t), ...
                      benefit_totp_npv(:,t), ...
                      benefit_water_non_use_npv(:,t), ...
                      benefit_water_rec_npv(:,t), ...
                      benefit_pollination_yield_npv(:,t), ...
                      benefit_pollination_non_use_npv(:,t), ...
                      benefit_habitat_non_use_npv(:,t), ...
                      benefit_bio_npv(:,t)];
        % Accumulate benefits for each option and scheme year
        benefits.(elm_option)(:, t)          = nansum(benefits_t,2);
        benefits_table.(elm_option)(:, :, t) = benefits_t;    
        
        % 4.15 Collect costs for each scheme year
        % ---------------------------------------
        costs_t = [opp_cost_farm_npv(:,t), ...
                   cost_forestry_npv(:,t), ...
                  -benefit_forestry_npv(:,t), ...
                   cost_grass_npv(:,t), ...
                  -benefit_grass_npv(:,t), ...
                   cost_rec_npv(:,t)];
        % Accumulate costs for each option and scheme year
        costs.(elm_option)(:, t)          = nansum(costs_t,2);
        costs_table.(elm_option)(:, :, t) = costs_t;    
        
        % 4.16 Calculate benefit cost ratio using NPVs
        % --------------------------------------------
        % Note: Introduces NaN and Inf values by dividing by zero
        % all of these cases are where there is no farm_ha to start with
        % these are removed in payment mechanisms so shouldn't be a problem
        benefit_cost_ratios.(elm_option)(:, t) = benefits.(elm_option)(:, t)  ./ costs.(elm_option)(:, t); 
        
        % 4.16 Collect ES outcomes as ES values
        % -------------------------------------
        % vars_es_outs  = {'ghg', 'rec', 'flood', 'tot_n', 'tot_p', 'water_non_use' 'water_rec' 'poll_yield', 'poll_non_use', 'habitat_non_use', 'biodiversity'};
        es_outs_t = [benefit_ghg_npv(:,t), ...
                     benefit_rec_npv(:,t), ...
                     benefit_flood_npv(:,t), ...
                     benefit_totn_npv(:,t), ...
                     benefit_totp_npv(:,t), ...
                     benefit_water_non_use_npv(:,t), ...
                     benefit_water_rec_npv(:,t), ...
                     benefit_pollination_yield_npv(:,t), ...
                     benefit_pollination_non_use_npv(:,t), ...
                     benefit_habitat_non_use_npv(:,t), ...
                     benefit_bio_npv(:,t)];
        es_outs.(elm_option)(:, :, t) = es_outs_t;
    end
        
end


% 5. Environmental Outcomes
% -------------------------
for option_i = 1:num_elm_options

    elm_option = elm_options{option_i};

    % 5.1 Greenhouse Gases
    % --------------------
    %  ghg quantities are all in net sequestration (a good) as average
    %  annual quantities
    [quantity_ghg_farm, quantity_ghg_dispfood, quantity_ghg_forestry, quantity_ghg_forest_soil] = fcn_calc_quantity_ghg(MP, baseline, es_agriculture_all.(elm_option), es_forestry_all.(elm_option));
    quantity_ghg = quantity_ghg_farm + quantity_ghg_dispfood + quantity_ghg_forestry + quantity_ghg_forest_soil;
        
    % 5.2 Recreation
    % --------------
    %  Recreation environmental outcomes are hectares of land in different
    %  access schemes. Also include no access as a price might pay for land
    %  without access.
    quantity_sng_rec    = zeros(cell_info.ncells, MP.num_years);
    quantity_wood_rec   = zeros(cell_info.ncells, MP.num_years);
    quantity_sng_norec  = zeros(cell_info.ncells, MP.num_years);
    quantity_wood_norec = zeros(cell_info.ncells, MP.num_years);
    
    if contains(elm_option, 'noaccess')
        if contains(elm_option, 'sng')
            quantity_sng_norec  = repmat(elm_ha.(elm_option), 1, MP.num_years);
        else
            quantity_wood_norec = repmat(elm_ha.(elm_option), 1, MP.num_years);
        end
    else
        if contains(elm_option, 'sng')
            quantity_sng_rec  = repmat(elm_ha.(elm_option), 1, MP.num_years);
        else
            quantity_wood_rec = repmat(elm_ha.(elm_option), 1, MP.num_years);
        end
        
    end

    % 5.3 Flood Quantity
    % ------------------
    % Flood quantity is change in annual flow events that exceed the 5th
    % percentile under the baseline. For wood, transition from sng to wood  
    quantity_flooding = fcn_calc_quantity_flood(MP, elm_option, es_flood_all);   
    
    % 5.4 Water quality
    % -----------------
    % Water quality is change in nutrient concentrations with transition
    % for wood
    [quantity_totn, quantity_totp] = fcn_calc_quantity_water_quality(MP, elm_option, es_water_quality_all);
       
    % 5.5 Pollinators
    % ---------------
    % Pollinators is change is species richness of pollinators with
    % transition for wood
    quantity_pollinators = fcn_calc_quantity_pollination(MP, elm_option, baseline.es_biodiversity_ucl, es_pollination_all);
    
    % 5.6 Biodiversity
    % ----------------
    % Biodiversity is change is species richness of pollinators & priority 
    % species with transition for wood
    quantity_bio = fcn_calc_quantity_bio(MP, elm_option, baseline.es_biodiversity_ucl, es_biodiversity_ucl_all);
            
    % 5.7 Collect Environmental Outcome quantities for each scheme year
    % ----------------------------------------------------------------- 
    % vars_env_outs = {'ghg', 'sng_rec', 'wood_rec', 'sng_norec', 'wood_norec', 'flood', 'tot_n', 'tot_p', 'pollinators', 'biodiversity'};
    for t = scheme_years
        env_outs_t = [quantity_ghg(:,t), ...                        
                      quantity_sng_rec(:,t), ...
                      quantity_wood_rec(:,t), ...
                      quantity_sng_norec(:,t), ...
                      quantity_wood_norec(:,t), ...
                      quantity_flooding(:,t), ...
                      quantity_totn(:,t), ...
                      quantity_totp(:,t), ...
                      quantity_pollinators(:,t), ...
                      quantity_bio(:,t)];
         env_outs.(elm_option)(:, :, t) = env_outs_t;
    end
    
end    


% 6. Biodiversity Constraint Data
% -------------------------------
%  
    
% 6.1 Biodiversity Group Data
% ---------------------------
% Check that data with groups from xlsx files are in same order as the
% data from the model estimation.
load(strcat(MP.biodiversity_data_folder, 'NEVO_Biodiversity_UCL_data.mat'), 'Biodiversity');    
names_poll = cell2table(Biodiversity.Names_Pollinators, 'VariableNames',  {'species'});
names_prio = cell2table(Biodiversity.Names_PrioritySpecies, 'VariableNames',  {'species'});

grps_poll = readtable(strcat(MP.biodiversity_data_folder, 'biod_poll_species_groups.xlsx'));
grps_prio = readtable(strcat(MP.biodiversity_data_folder, 'biod_prio_species_groups.xlsx'));

% Join names to grps to ensure group names are aligned with species names in data   
grps_poll = join(names_poll, grps_poll, 'Keys' , {'species'});
grps_prio = join(names_prio, grps_prio, 'Keys' , {'species'});    
    

% 6.2 Grouping Matrices
% ---------------------
%  Create dummy variable matrices that can be use to add up quantity of
%  presence measures for species in agroup by cell 
cat_poll = categorical(grps_poll.group);
names_poll_grp = categories(cat_poll);
dmat_poll = dummyvar(cat_poll);

cat_prio = categorical(grps_prio.group);
names_prio_grp = categories(cat_prio);
dmat_prio = dummyvar(cat_prio);

biodiversity_constraints.names_grp = [names_poll_grp; names_prio_grp];
    
% 6.3 Target Counts by Groups
% ---------------------------
%  Quantity of presence that represents a MP.bio_pct_increase_target% increase for species
%  group over baseline in each period
biodiversity_constraints.targets_20 = [ceil(MP.bio_pct_increase_target*sum(baseline.es_biodiversity_ucl.pollinator_presence_20 * dmat_poll)), ...
                                       ceil(MP.bio_pct_increase_target*sum(baseline.es_biodiversity_ucl.priority_presence_20 * dmat_prio))]';
biodiversity_constraints.targets_30 = [ceil(MP.bio_pct_increase_target*sum(baseline.es_biodiversity_ucl.pollinator_presence_30 * dmat_poll)), ...
                                       ceil(MP.bio_pct_increase_target*sum(baseline.es_biodiversity_ucl.priority_presence_30 * dmat_prio))]';
biodiversity_constraints.targets_40 = [ceil(MP.bio_pct_increase_target*sum(baseline.es_biodiversity_ucl.pollinator_presence_40 * dmat_poll)), ...
                                       ceil(MP.bio_pct_increase_target*sum(baseline.es_biodiversity_ucl.priority_presence_40 * dmat_prio))]';
biodiversity_constraints.targets_50 = [ceil(MP.bio_pct_increase_target*sum(baseline.es_biodiversity_ucl.pollinator_presence_50 * dmat_poll)), ...
                                       ceil(MP.bio_pct_increase_target*sum(baseline.es_biodiversity_ucl.priority_presence_50 * dmat_prio))]';
    
% 6.4 Additions to Presence of Groups by each land use change
% -----------------------------------------------------------
%  For each cell in each NEV period calculate how much each different luc
%  option impacts on the quantity of presence of species groups.
for option_i = 1:num_elm_options

    elm_option = elm_options{option_i};
        
    biodiversity_constraints.(elm_option).data_20 = [(es_biodiversity_ucl_all.(elm_option).pollinator_presence_20 - baseline.es_biodiversity_ucl.pollinator_presence_20) * dmat_poll, ...
                                                     (es_biodiversity_ucl_all.(elm_option).priority_presence_20   - baseline.es_biodiversity_ucl.priority_presence_20) * dmat_prio];
    biodiversity_constraints.(elm_option).data_30 = [(es_biodiversity_ucl_all.(elm_option).pollinator_presence_30 - baseline.es_biodiversity_ucl.pollinator_presence_30) * dmat_poll, ...
                                                     (es_biodiversity_ucl_all.(elm_option).priority_presence_30   - baseline.es_biodiversity_ucl.priority_presence_30) * dmat_prio];
    biodiversity_constraints.(elm_option).data_40 = [(es_biodiversity_ucl_all.(elm_option).pollinator_presence_40 - baseline.es_biodiversity_ucl.pollinator_presence_40) * dmat_poll, ...
                                                     (es_biodiversity_ucl_all.(elm_option).priority_presence_40   - baseline.es_biodiversity_ucl.priority_presence_40) * dmat_prio];
    biodiversity_constraints.(elm_option).data_50 = [(es_biodiversity_ucl_all.(elm_option).pollinator_presence_50 - baseline.es_biodiversity_ucl.pollinator_presence_50) * dmat_poll, ...
                                                     (es_biodiversity_ucl_all.(elm_option).priority_presence_50   - baseline.es_biodiversity_ucl.priority_presence_50) * dmat_prio];
end
    

% 7. Save results to .mat file
% ----------------------------
% Depends on what carbon price has been used
% This depends on choice of recreation access in MP.site_type
save([MP.data_out 'elm_data_', MP.carbon_price_str, '.mat'], ...
     'cell_info', ...
     'num_benefits', ...
     'num_costs', ...
     'num_env_outs', ...
     'num_es_outs', ...
     'vars_benefits', ...
     'vars_costs', ...
     'vars_env_outs', ...
     'vars_es_outs', ...
     'num_elm_options', ...
     'elm_options', ...
     'elm_ha', ...
     'benefits', ...
     'benefits_table', ...
     'costs', ...
     'costs_table', ...
     'benefit_cost_ratios', ...
     'env_outs', ...
     'es_outs', ...
     'biodiversity_constraints');
 
 toc
 