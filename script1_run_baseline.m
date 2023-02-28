%  script1_run_baseline
%  ====================
% Run models at baseline values, save as baseline_results.mat
% Models that automatically return changes from the baseline are not
% required to run here.
clear

% (1) Set up
%  ==========

% Connect to database
% -------------------
server_flag = false;
conn = fcn_connect_database(server_flag);

% Set model parameters
% --------------------
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
        '"water": null}'];
% Decode JSON object/string & set other default parameters
MP = fcn_set_model_parameters(conn, json, server_flag);

% Connect to NEV Model
% --------------------
addpath(genpath(MP.NEV_code_folder))

% Go from regional scale to 2km grid cells
% -----------------------------------------
% Returns cell ids and other info
cell_info = fcn_region_to_cell(conn, MP.feature_type, MP.id);

% Import baseline landcovers from database
% ----------------------------------------
% Set this to baseline_lcs_original
baseline_lcs = fcn_import_primary_variables(conn, cell_info);


% (2) Run agriculture, forestry and GHG models
%  ============================================
% (a) Agriculture (+ GHG)
% -----------------------
if MP.run_agriculture
    es_agriculture = fcn_run_agriculture(MP.agriculture_data_folder, ...
                                         MP.climate_data_folder, ...
                                         MP.agricultureghg_data_folder, ...
                                         MP, ...
                                         baseline_lcs, ...
                                         MP.carbon_price(1:40));
    
	% Rescale for Constant Land Areas over Time
    % -----------------------------------------
    % The extent of different agricultural landcovers in each cell are 
    % scaled to ensure consistency with maintaining the average arable &
    % grass extent in each cell from the first decade.    
    
    % ADVENT definitions of Arable & Grass (transfer tgrass)
    % ------------------------------------------------------
    % es_agriculture.arable_ha = es_agriculture.arable_ha + es_agriculture.tgrass_ha;
    % es_agriculture.grass_ha  = es_agriculture.grass_ha  - es_agriculture.tgrass_ha;                                     
           
    % Average Arable & Grass Extent Over First Decade
    % -----------------------------------------------
    arable_ha_tser = es_agriculture.arable_ha;
    grass_ha_tser  = es_agriculture.grass_ha;    
    arable_ha = mean(arable_ha_tser(:,1:10),2);
    grass_ha  = mean(grass_ha_tser(:,1:10),2);

    % Adjustment factors to rescale arable & grass to first decade constant
    % ---------------------------------------------------------------------
    rescale_arable_ha = arable_ha./arable_ha_tser;
    rescale_grass_ha  = grass_ha./grass_ha_tser;
    rescale_arable_ha(isnan(rescale_arable_ha)) = 1;
    rescale_grass_ha(isnan(rescale_grass_ha))   = 1;
    
    % Variable names
    % --------------
    vars_arable     = {'arable', 'wheat', 'osr', 'wbar', 'sbar', 'pot', 'sb', 'other'};
    vars_grass_ha   = {'grass', 'tgrass', 'pgrass', 'rgraz'};
    vars_grass_food = {'livestock', 'dairy', 'beef', 'sheep'};
    
    % Rescale: Landcover ha
    % ---------------------
    vars_all = horzcat(vars_arable, vars_grass_ha);
    for i = 1:length(vars_all) 
        % Rescaling factors for landcover areas
        if find(strcmp(vars_arable, vars_all{i}))
            rescale_ha = rescale_arable_ha;
        else
            rescale_ha = rescale_grass_ha;
        end          
        % Rescale the landarea for this landcover
        eval(['baseline_lcs.', vars_all{i}, '_ha = es_agriculture.', vars_all{i}, '_ha.*rescale_ha;']);        
        eval(['es_agriculture_rescale.', vars_all{i}, '_ha = baseline_lcs.', vars_all{i}, '_ha;']);                
        % Rescale landcovers for NEV Periods
        for t = 1:4
            tstart = (t-1)*10+1;
            tend   = t*10;
            tstr   = num2str(20+(t-1)*10);
            % Hectares of each landcover in each period
            eval(['baseline_lcs.', vars_all{i}, '_ha_', tstr, ' = mean(baseline_lcs.', vars_all{i}, '_ha(:,tstart:tend), 2);']);
        end
    end
    es_agriculture_rescale.farm_ha = es_agriculture_rescale.arable_ha + es_agriculture_rescale.grass_ha;
    
    % Rescale: Profit
    % ---------------
    vars_all = horzcat(vars_arable, vars_grass_food);
    for i = 1:length(vars_all) 
        if find(strcmp(vars_arable, vars_all{i}))
            rescale_ha = rescale_arable_ha;
        else
            rescale_ha = rescale_grass_ha;
        end          
        eval(['es_agriculture_rescale.', vars_all{i}, '_profit = es_agriculture.', vars_all{i}, '_profit.*rescale_ha;']);        
    end   
    es_agriculture_rescale.farm_profit = es_agriculture_rescale.arable_profit + es_agriculture_rescale.livestock_profit;
    
    % Rescale: Profit_ann
    % -------------------
    vars_all = horzcat(vars_arable, vars_grass_food);
    for i = 1:length(vars_all) 
        if find(strcmp(vars_arable, vars_all{i}))
            rescale_ha = rescale_arable_ha;
        else
            rescale_ha = rescale_grass_ha;
        end          
        eval(['es_agriculture_rescale.', vars_all{i}, '_profit_ann = es_agriculture.', vars_all{i}, '_profit_ann.*rescale_ha;']);        
    end
    es_agriculture_rescale.farm_profit_ann = es_agriculture_rescale.arable_profit_ann + es_agriculture_rescale.livestock_profit_ann;    
    
    % Rescale: ghg
    % ------------
    vars_all = horzcat(vars_arable, vars_grass_ha, vars_grass_food);
    for i = 1:length(vars_all) 
        if find(strcmp(vars_arable, vars_all{i}))
            rescale_ha = rescale_arable_ha;
        else
            rescale_ha = rescale_grass_ha;
        end          
        eval(['es_agriculture_rescale.ghg_', vars_all{i}, ' = es_agriculture.ghg_', vars_all{i}, '.*rescale_ha;']);        
    end 
    es_agriculture_rescale.ghg_farm = es_agriculture_rescale.ghg_arable + es_agriculture_rescale.ghg_grass + es_agriculture_rescale.ghg_livestock;  
    
    % Rescale: ghg_ann
    % ----------------
    vars_all = horzcat(vars_arable, vars_grass_ha, vars_grass_food);
    for i = 1:length(vars_all) 
        if find(strcmp(vars_arable, vars_all{i}))
            rescale_ha = rescale_arable_ha;
        else
            rescale_ha = rescale_grass_ha;
        end          
        eval(['es_agriculture_rescale.ghg_', vars_all{i}, '_ann = es_agriculture.ghg_', vars_all{i}, '_ann.*rescale_ha;']);        
    end 
    es_agriculture_rescale.ghg_farm_ann = es_agriculture_rescale.ghg_arable_ann + es_agriculture_rescale.ghg_grass_ann + es_agriculture_rescale.ghg_livestock_ann;
                               
    % Rescale: food
    % -------------
    es_agriculture_rescale.arable_food = es_agriculture.food  .* rescale_arable_ha;
    es_agriculture_rescale.dairy_food  = es_agriculture.dairy .* rescale_grass_ha;
    es_agriculture_rescale.beef_food   = es_agriculture.beef  .* rescale_grass_ha;
    es_agriculture_rescale.sheep_food  = es_agriculture.sheep .* rescale_grass_ha;
    
end

% (b) Forestry (+ GHG)
% --------------------
if MP.run_forestry
    landuses_chg.new2kid         = baseline_lcs.new2kid;
    landuses_chg.wood_ha_chg     = zeros(cell_info.ncells, 1);
    landuses_chg.sngrass_ha_chg  = zeros(cell_info.ncells, 1);
    landuses_chg.arable_ha_chg   = zeros(cell_info.ncells, 1);
    landuses_chg.tgrass_ha_chg   = zeros(cell_info.ncells, 1);
    landuses_chg.pgrass_ha_chg   = zeros(cell_info.ncells, 1);
    landuses_chg.rgraz_ha_chg    = zeros(cell_info.ncells, 1);    
    es_forestry = fcn_run_forestry(MP.forest_data_folder, ...
                                   MP.forestghg_data_folder, ...
                                   MP, ...
                                   landuses_chg, ...
                                   MP.carbon_price);
end
                     
%  (3) Run additional models based on averaged decadal output
%  ==========================================================
% (a) Recreation
% --------------
if MP.run_recreation

    % No baseline recreation run is required as the calculation of benefits
    % is done through the valuation of additions of new parks & paths to
    % the orval sites.
    
end

% (b) Biodiversity
% ----------------
% JNCC
if MP.run_biodiversity_jncc
    es_biodiversity_jncc = fcn_run_biodiversity_jncc(MP.biodiversity_data_folder_jncc, baseline_lcs, 'future', 'baseline');
end
% UCL
if MP.run_biodiversity_ucl
    es_biodiversity_ucl = fcn_run_biodiversity_ucl(MP.biodiversity_data_folder, baseline_lcs, 'rcp60', 'baseline');
end

% (c) Water quality & water quality non-use
% -----------------------------------------
% Done separately in run_water_results.m

% (d) Flooding
% ------------
% Done separately in run_water_results.m


% (5) Construct baseline structure for saving results
%  ==================================================
baseline.baseline_lcs = baseline_lcs;

% (a) Agriculture
% ---------------
baseline.es_agriculture = es_agriculture_rescale;

% (b) Forestry
% ------------
baseline.es_forestry = es_forestry;

% (c) Greenhouse Gases
% --------------------
% In es_agriculture & es_forestry

% (d) Recreation
% --------------
% Not needed in baseline as valuation done using orval procedures which
% value additions to existing recreation sites

% (e) Biodiversity
% ----------------
% JNCC
baseline.es_biodiversity_jncc = es_biodiversity_jncc;

% UCL
baseline.es_biodiversity_ucl = es_biodiversity_ucl;


% (4) Save baseline results to .mat file
% ======================================
% Depends on what carbon price has been used
save([MP.data_out 'baseline_results_', MP.carbon_price_str, '.mat'], 'baseline');

