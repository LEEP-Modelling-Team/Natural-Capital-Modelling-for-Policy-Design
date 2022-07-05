%% script1_run_baseline
%  ====================
% Run models at baseline values, save as baseline_results.mat
% Models that automatically return changes from the baseline are not
% required to run here.
clear

%% (0) Set up parameters
%  =====================
json = ['{"id": "E92000001",'...
        '"feature_type": "integrated_countries",' ...
        '"run_agriculture": true,' ...
        '"run_forestry": true,' ...
        '"run_recreation": true,' ...
        '"run_ghg": true,' ...
        '"run_biodiversity_jncc": true,' ...
        '"run_biodiversity_ucl": true,' ...
        '"run_water": true,' ...
        '"run_pollination": true,' ...
        '"run_non_use_pollination": true,' ...
        '"run_non_use_habitat": true,' ...
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
PV = fcn_import_primary_variables(conn, cell_info);

% Set up landuse_ha_change for forestry model
% -------------------------------------------
% (All zeros - no change from baseline)
landuse_ha_change = zeros(cell_info.ncells, 5);

%% (3) Run agriculture, forestry and GHG models
%  ============================================
% (a) Agriculture (+ GHG)
% -----------------------
if MP.run_agriculture
    es_agriculture = fcn_run_agriculture(MP.agriculture_data_folder, ...
                                         MP.climate_data_folder, ...
                                         MP.agricultureghg_data_folder, ...
                                         MP, ...
                                         PV, ...
                                         carbon_price(1:40));
end

% (b) Forestry (+ GHG)
% --------------------
if MP.run_forestry
    es_forestry = fcn_run_forestry(MP.forest_data_folder, ...
                                   MP.forestghg_data_folder, ...
                                   MP, ...
                                   PV, ...
                                   landuse_ha_change, ...
                                   es_agriculture, ...
                                   carbon_price);
end

% Collect output from agriculture, forestry and GHG models
% --------------------------------------------------------
% Create decadal output in 2020-2029, 2030-2039, 2040-2049, 2050-2059
out = fcn_collect_output(MP, ...
                         PV, ...
                         es_agriculture, ...
                         es_forestry, ...
                         carbon_price);

%% (4) Run additional models based on averaged decadal output
%  ==========================================================
% (a) Recreation
% --------------
if MP.run_recreation
    % Set up recreation parameters
    % ----------------------------
    % As this is a baseline run it shouldn't matter
    % Should just load baseline table from .mat file, rather than run full model
	site_type = 'path_new';
	visval_type = 'simultaneous';
	path_agg_method = 'agg_to_changed_cells';
    minsitesize = 10;
    es_recreation = fcn_run_recreation(MP.rec_data_folder, ...
                                       MP, ...
                                       out, ...
                                       site_type, ...
                                       visval_type, ...
                                       path_agg_method, ...
                                       minsitesize, ...
                                       conn);
    % Join recreation output to main out structure
    out = table2struct(join(struct2table(out), es_recreation), 'ToScalar', true);
end

% (b) Biodiversity
% ----------------
% JNCC
if MP.run_biodiversity_jncc
    es_biodiversity_jncc = fcn_run_biodiversity_jncc(MP.biodiversity_data_folder_jncc, ...
                                                     PV, ...
                                                     out);
end

% UCL
if MP.run_biodiversity_ucl
    es_biodiversity_ucl = fcn_run_biodiversity_ucl(MP.biodiversity_data_folder, ...
                                                   out, ...
                                                   'rcp60', ...
                                                   'baseline');
end

% (c) Water quality & water quality non-use
% -----------------------------------------
% Done separately in run_water_results.m

% (d) Flooding
% ------------
% Done separately in run_water_results.m

%% (5) Construct baseline structure for saving results
%  ===================================================
% (a) Agriculture
% ---------------
baseline.es_agriculture = es_agriculture;

% (b) Forestry
% ------------
% Use timber profits for 60:40% mixed woodland for now
baseline.timber_mixed_ann = es_forestry.Timber.ValAnn.Mix6040;
baseline.timber_mixed_benefit_ann = es_forestry.Timber.BenefitAnn.Mix6040;
baseline.timber_mixed_cost_ann = es_forestry.Timber.CostAnn.Mix6040;
baseline.timber_mixed_fixed_cost = es_forestry.Timber.FixedCost.Mix6040;

% (c) Greenhouse Gases
% --------------------
baseline.ghg_farm = es_agriculture.ghg_farm;

% Use timber carbon for 60:40% mixed woodland for now
baseline.ghg_mixed_yr = es_forestry.TimberC.QntYr.Mix6040;
baseline.ghg_mixed_yrUB = es_forestry.TimberC.QntYrUB.Mix6040;

baseline.ghg_mixed_ann = es_forestry.TimberC.ValAnn.Mix6040;

% No forestry soil carbon baseline, all zeros

% (d) Recreation
% --------------
baseline.rec_vis = [repmat(out.rec_vis_20, 1, 10), ...
                    repmat(out.rec_vis_30, 1, 10), ...
                    repmat(out.rec_vis_40, 1, 10), ...
                    repmat(out.rec_vis_50, 1, 10)];

baseline.rec_val = [repmat(out.rec_val_20, 1, 10), ...
                    repmat(out.rec_val_30, 1, 10), ...
                    repmat(out.rec_val_40, 1, 10), ...
                    repmat(out.rec_val_50, 1, 10)];

% (e) Biodiversity
% ----------------
% JNCC
baseline.sr_100_20 = es_biodiversity_jncc.sr_100_20;
baseline.sr_100_30 = es_biodiversity_jncc.sr_100_30;
baseline.sr_100_40 = es_biodiversity_jncc.sr_100_40;
baseline.sr_100_50 = es_biodiversity_jncc.sr_100_50;

% UCL
baseline.pollinator_sr_20 = es_biodiversity_ucl.pollinator_sr_20;
baseline.pollinator_sr_30 = es_biodiversity_ucl.pollinator_sr_30;
baseline.pollinator_sr_40 = es_biodiversity_ucl.pollinator_sr_40;
baseline.pollinator_sr_50 = es_biodiversity_ucl.pollinator_sr_50;

%% (6) Save baseline results to .mat file
%  ======================================
% Depends on what carbon price has been used
save(['Script 1 (Baseline Runs)/baseline_results_', MP.carbon_price, '.mat'], 'baseline');

