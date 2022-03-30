%% script1_run_landuse_change.m
%  ============================
% Author: Nathan Owen
% Last modified: 19/06/2020
% Create .mat files of future land covers under the baseline NEV run and
% scenarios for water runs.
% Current scenarios:
% - 'arable2sng': arable and temporary grassland to semi-natural grassland.
% - 'arable2wood': arable and temporary grassland to woodland.
% - 'arable2maize': arable and temporary grassland to maize.
% - 'grass2sng': permanent grassland and rough grazing to semi-natural grassland.
% - 'grass2wood': permanent grassland and rough grazing to woodland.
% - 'grass2maize': permanent grassland and rough grazing to maize.
% - 'wood2sng': woodland to semi-natural grassland.
% - 'wood2maize': woodland to maize.
% - 'wood2arable': woodland to arable.

%% (1) Set up
%  ==========
clear

% Flags for running baseline and technologies
do_baseline     = true;
do_arable2sng   = true;
do_arable2wood  = true;
do_grass2sng    = true;
do_grass2wood   = true;

% Add NEV model code to search path
addpath(genpath('D:/Documents/Github/NEV/'))

% Connect to database
server_flag = false;
conn = fcn_connect_database(server_flag);

% Path to agriculture model data
SetDataPaths

% Parameters for agriculture model
parameters = fcn_set_parameters();

% Get 5 high level land covers
sqlquery = ['SELECT ', ...
                'new2kid, ', ...
                'farm_ha, ', ...
                'water_ha, ', ...
                'sngrass_ha, ', ...
                'urban_ha, ', ...
                'wood_ha, ', ...
                'wood_mgmt_ha ', ...
            'FROM nevo.nevo_variables ', ...
            'ORDER BY new2kid'];
setdbprefs('DataReturnFormat', 'structure');
dataReturn  = fetch(exec(conn, sqlquery));
high_level_lcs = dataReturn.Data;

% Get carbon prices
carbon_price = fcn_get_carbon_price(conn, parameters.carbon_price);

%% (2) Baseline run of agriculture model
%  =====================================
if do_baseline
    % Land cover change
    % -----------------
    % No land cover change in baseline, just use high_level_lcs
    
    % Run agriculture model to split farm hectares
    % --------------------------------------------
    es_agriculture = fcn_run_agriculture(agriculture_data_folder, ... 
                                         climate_data_folder, ...
                                         agricultureghg_data_folder, ...
                                         parameters, ...
                                         high_level_lcs, ...
                                         carbon_price(1:40));
    
    % Collect high level and agriculture output
    % -----------------------------------------
    lcs_baseline = fcn_collect_output_simple(high_level_lcs, es_agriculture);
    
    % Save to lcs_baseline.mat file
    % -----------------------------
    save('MAT Files/lcs_baseline.mat', 'lcs_baseline', '-mat', '-v6');
else
    % Load lcs_baseline.mat file
    % --------------------------
    load('MAT Files/lcs_baseline.mat', 'lcs_baseline');
end

%% (3) Scenario runs of agriculture model
%  ======================================
% NB. We will assume no climate change here, use 2020s land cover throughout

% (a) arable2sng
% --------------
if do_arable2sng
    % Land cover change
    % -----------------
    % Add arable and tgrass hectares to semi-natural grassland hectares
    % Subtract arable and tgrass hectares from farm hectares
    % Reduce all crops and farm grassland (except permanent grassland and rough grazing) to zero
    lcs_arable2sng = lcs_baseline;
    hectares = lcs_arable2sng.arable_ha_20 + lcs_arable2sng.tgrass_ha_20;
    lcs_arable2sng.hectares = hectares;
    
    lcs_arable2sng.sngrass_ha = lcs_arable2sng.sngrass_ha + hectares;
    lcs_arable2sng.farm_ha = lcs_arable2sng.farm_ha - hectares;
    
    % Set appropriate land covers to zero
    cols_to_zero = {'arable_ha_20', 'arable_ha_30', 'arable_ha_40', 'arable_ha_50', ...
                    'wheat_ha_20', 'wheat_ha_30', 'wheat_ha_40', 'wheat_ha_50', ...
                    'osr_ha_20', 'osr_ha_30', 'osr_ha_40', 'osr_ha_50', ...
                    'wbar_ha_20', 'wbar_ha_30', 'wbar_ha_40', 'wbar_ha_50', ...
                    'sbar_ha_20', 'sbar_ha_30', 'sbar_ha_40', 'sbar_ha_50', ...
                    'pot_ha_20', 'pot_ha_30', 'pot_ha_40', 'pot_ha_50', ...
                    'sb_ha_20', 'sb_ha_30', 'sb_ha_40', 'sb_ha_50', ...
                    'other_ha_20', 'other_ha_30', 'other_ha_40', 'other_ha_50', ...
                    'tgrass_ha_20', 'tgrass_ha_30', 'tgrass_ha_40', 'tgrass_ha_50'};
    lcs_arable2sng(:, cols_to_zero) = array2table(zeros(size(lcs_arable2sng, 1), length(cols_to_zero)));
    
    % Set remaining farmland grass types to 2020s amount
    lcs_arable2sng.rgraz_ha_30 = lcs_arable2sng.rgraz_ha_20;
    lcs_arable2sng.rgraz_ha_40 = lcs_arable2sng.rgraz_ha_20;
    lcs_arable2sng.rgraz_ha_50 = lcs_arable2sng.rgraz_ha_20;
    
    lcs_arable2sng.pgrass_ha_30 = lcs_arable2sng.pgrass_ha_20;
    lcs_arable2sng.pgrass_ha_40 = lcs_arable2sng.pgrass_ha_20;
    lcs_arable2sng.pgrass_ha_50 = lcs_arable2sng.pgrass_ha_20;
    
    % Reset total farming grassland
    lcs_arable2sng.grass_ha_20 = lcs_arable2sng.rgraz_ha_20 + lcs_arable2sng.pgrass_ha_20;
    lcs_arable2sng.grass_ha_30 = lcs_arable2sng.rgraz_ha_30 + lcs_arable2sng.pgrass_ha_30;
    lcs_arable2sng.grass_ha_40 = lcs_arable2sng.rgraz_ha_40 + lcs_arable2sng.pgrass_ha_40;
    lcs_arable2sng.grass_ha_50 = lcs_arable2sng.rgraz_ha_50 + lcs_arable2sng.pgrass_ha_50;
    
    % Save to lcs_arable2sng.mat file
    % -------------------------------
    save('MAT Files/lcs_arable2sng.mat', 'lcs_arable2sng', '-mat', '-v6');
else
    load('MAT Files/lcs_arable2sng.mat', 'lcs_arable2sng')
end

% (b) arable2wood
% ---------------
if do_arable2wood
    % Land cover change
    % -----------------
    % Add arable and tgrass hectares to woodland hectares
    % Subtract arable and tgrass hectares from farm hectares
    % Reduce all crops and farm grassland (except permanent grassland and rough grazing) to zero
    lcs_arable2wood = lcs_baseline;
    hectares = lcs_arable2wood.arable_ha_20 + lcs_arable2wood.tgrass_ha_20;
    lcs_arable2wood.hectares = hectares;
    
    lcs_arable2wood.wood_ha = lcs_arable2wood.wood_ha + hectares;
    lcs_arable2wood.farm_ha = lcs_arable2wood.farm_ha - hectares;
    
    % Set appropriate land covers to zero
    cols_to_zero = {'arable_ha_20', 'arable_ha_30', 'arable_ha_40', 'arable_ha_50', ...
                    'wheat_ha_20', 'wheat_ha_30', 'wheat_ha_40', 'wheat_ha_50', ...
                    'osr_ha_20', 'osr_ha_30', 'osr_ha_40', 'osr_ha_50', ...
                    'wbar_ha_20', 'wbar_ha_30', 'wbar_ha_40', 'wbar_ha_50', ...
                    'sbar_ha_20', 'sbar_ha_30', 'sbar_ha_40', 'sbar_ha_50', ...
                    'pot_ha_20', 'pot_ha_30', 'pot_ha_40', 'pot_ha_50', ...
                    'sb_ha_20', 'sb_ha_30', 'sb_ha_40', 'sb_ha_50', ...
                    'other_ha_20', 'other_ha_30', 'other_ha_40', 'other_ha_50', ...
                    'tgrass_ha_20', 'tgrass_ha_30', 'tgrass_ha_40', 'tgrass_ha_50'};
    lcs_arable2wood(:, cols_to_zero) = array2table(zeros(size(lcs_arable2wood, 1), length(cols_to_zero)));
    
    % Set remaining farmland grass types to 2020s amount
    lcs_arable2wood.rgraz_ha_30 = lcs_arable2wood.rgraz_ha_20;
    lcs_arable2wood.rgraz_ha_40 = lcs_arable2wood.rgraz_ha_20;
    lcs_arable2wood.rgraz_ha_50 = lcs_arable2wood.rgraz_ha_20;
    
    lcs_arable2wood.pgrass_ha_30 = lcs_arable2wood.pgrass_ha_20;
    lcs_arable2wood.pgrass_ha_40 = lcs_arable2wood.pgrass_ha_20;
    lcs_arable2wood.pgrass_ha_50 = lcs_arable2wood.pgrass_ha_20;
    
    % Reset total farming grassland
    lcs_arable2wood.grass_ha_20 = lcs_arable2wood.rgraz_ha_20 + lcs_arable2wood.pgrass_ha_20;
    lcs_arable2wood.grass_ha_30 = lcs_arable2wood.rgraz_ha_30 + lcs_arable2wood.pgrass_ha_30;
    lcs_arable2wood.grass_ha_40 = lcs_arable2wood.rgraz_ha_40 + lcs_arable2wood.pgrass_ha_40;
    lcs_arable2wood.grass_ha_50 = lcs_arable2wood.rgraz_ha_50 + lcs_arable2wood.pgrass_ha_50;
    
    % Save to lcs_arable2wood.mat file
    % --------------------------------
    save('MAT Files/lcs_arable2wood.mat', 'lcs_arable2wood', '-mat', '-v6');
else
    load('MAT Files/lcs_arable2wood.mat', 'lcs_arable2wood')
end

% (d) grass2sng
% --------------
if do_grass2sng
    % Land cover change
    % -----------------
    % Add pgrass and rgraz hectares to semi-natural grassland hectares
    % Subtract pgrass and rgraz hectares from farm hectares
    % Reduce pgrass and rgraz to zero
    lcs_grass2sng = lcs_baseline;
    hectares = lcs_grass2sng.pgrass_ha_20 + lcs_grass2sng.rgraz_ha_20;
    lcs_grass2sng.hectares = hectares;
    
    lcs_grass2sng.sngrass_ha = lcs_grass2sng.sngrass_ha + hectares;
    lcs_grass2sng.farm_ha = lcs_grass2sng.farm_ha - hectares;
    
    % Set appropriate land covers to zero
    cols_to_zero = {'pgrass_ha_20', 'pgrass_ha_30', 'pgrass_ha_40', 'pgrass_ha_50', ...
                    'rgraz_ha_20', 'rgraz_ha_30', 'rgraz_ha_40', 'rgraz_ha_50'};
    lcs_grass2sng(:, cols_to_zero) = array2table(zeros(size(lcs_grass2sng, 1), length(cols_to_zero)));
    
    % Set remaining farmland grass types to 2020s amount
    lcs_grass2sng.arable_ha_30 = lcs_grass2sng.arable_ha_20;
    lcs_grass2sng.arable_ha_40 = lcs_grass2sng.arable_ha_20;
    lcs_grass2sng.arable_ha_50 = lcs_grass2sng.arable_ha_20;
    
    lcs_grass2sng.wheat_ha_30 = lcs_grass2sng.wheat_ha_20;
    lcs_grass2sng.wheat_ha_40 = lcs_grass2sng.wheat_ha_20;
    lcs_grass2sng.wheat_ha_50 = lcs_grass2sng.wheat_ha_20;
    
    lcs_grass2sng.osr_ha_30 = lcs_grass2sng.osr_ha_20;
    lcs_grass2sng.osr_ha_40 = lcs_grass2sng.osr_ha_20;
    lcs_grass2sng.osr_ha_50 = lcs_grass2sng.osr_ha_20;
    
    lcs_grass2sng.wbar_ha_30 = lcs_grass2sng.wbar_ha_20;
    lcs_grass2sng.wbar_ha_40 = lcs_grass2sng.wbar_ha_20;
    lcs_grass2sng.wbar_ha_50 = lcs_grass2sng.wbar_ha_20;
    
    lcs_grass2sng.sbar_ha_30 = lcs_grass2sng.sbar_ha_20;
    lcs_grass2sng.sbar_ha_40 = lcs_grass2sng.sbar_ha_20;
    lcs_grass2sng.sbar_ha_50 = lcs_grass2sng.sbar_ha_20;
    
    lcs_grass2sng.pot_ha_30 = lcs_grass2sng.pot_ha_20;
    lcs_grass2sng.pot_ha_40 = lcs_grass2sng.pot_ha_20;
    lcs_grass2sng.pot_ha_50 = lcs_grass2sng.pot_ha_20;
    
    lcs_grass2sng.sb_ha_30 = lcs_grass2sng.sb_ha_20;
    lcs_grass2sng.sb_ha_40 = lcs_grass2sng.sb_ha_20;
    lcs_grass2sng.sb_ha_50 = lcs_grass2sng.sb_ha_20;
    
    lcs_grass2sng.other_ha_30 = lcs_grass2sng.other_ha_20;
    lcs_grass2sng.other_ha_40 = lcs_grass2sng.other_ha_20;
    lcs_grass2sng.other_ha_50 = lcs_grass2sng.other_ha_20;
    
    lcs_grass2sng.tgrass_ha_30 = lcs_grass2sng.tgrass_ha_20;
    lcs_grass2sng.tgrass_ha_40 = lcs_grass2sng.tgrass_ha_20;
    lcs_grass2sng.tgrass_ha_50 = lcs_grass2sng.tgrass_ha_20;
    
    % Reset total farming grassland
    lcs_grass2sng.grass_ha_20 = lcs_grass2sng.tgrass_ha_20;
    lcs_grass2sng.grass_ha_30 = lcs_grass2sng.tgrass_ha_30;
    lcs_grass2sng.grass_ha_40 = lcs_grass2sng.tgrass_ha_40;
    lcs_grass2sng.grass_ha_50 = lcs_grass2sng.tgrass_ha_50;
    
    % Save to lcs_grass2sng.mat file
    % -------------------------------
    save('MAT Files/lcs_grass2sng.mat', 'lcs_grass2sng', '-mat', '-v6');
else
    load('MAT Files/lcs_grass2sng.mat', 'lcs_grass2sng')
end

% (e) grass2wood
% --------------
if do_grass2wood
    % Land cover change
    % -----------------
    % Add pgrass and rgraz hectares to woodland hectares
    % Subtract pgrass and rgraz hectares from farm hectares
    % Reduce pgrass and rgraz to zero
    lcs_grass2wood = lcs_baseline;
    hectares = lcs_grass2wood.pgrass_ha_20 + lcs_grass2wood.rgraz_ha_20;
    lcs_grass2wood.hectares = hectares;
    
    lcs_grass2wood.wood_ha = lcs_grass2wood.wood_ha + hectares;
    lcs_grass2wood.farm_ha = lcs_grass2wood.farm_ha - hectares;
    
    % Set appropriate land covers to zero
    cols_to_zero = {'pgrass_ha_20', 'pgrass_ha_30', 'pgrass_ha_40', 'pgrass_ha_50', ...
                    'rgraz_ha_20', 'rgraz_ha_30', 'rgraz_ha_40', 'rgraz_ha_50'};
    lcs_grass2wood(:, cols_to_zero) = array2table(zeros(size(lcs_grass2wood, 1), length(cols_to_zero)));
    
    % Set remaining farmland grass types to 2020s amount
    lcs_grass2wood.arable_ha_30 = lcs_grass2wood.arable_ha_20;
    lcs_grass2wood.arable_ha_40 = lcs_grass2wood.arable_ha_20;
    lcs_grass2wood.arable_ha_50 = lcs_grass2wood.arable_ha_20;
    
    lcs_grass2wood.wheat_ha_30 = lcs_grass2wood.wheat_ha_20;
    lcs_grass2wood.wheat_ha_40 = lcs_grass2wood.wheat_ha_20;
    lcs_grass2wood.wheat_ha_50 = lcs_grass2wood.wheat_ha_20;
    
    lcs_grass2wood.osr_ha_30 = lcs_grass2wood.osr_ha_20;
    lcs_grass2wood.osr_ha_40 = lcs_grass2wood.osr_ha_20;
    lcs_grass2wood.osr_ha_50 = lcs_grass2wood.osr_ha_20;
    
    lcs_grass2wood.wbar_ha_30 = lcs_grass2wood.wbar_ha_20;
    lcs_grass2wood.wbar_ha_40 = lcs_grass2wood.wbar_ha_20;
    lcs_grass2wood.wbar_ha_50 = lcs_grass2wood.wbar_ha_20;
    
    lcs_grass2wood.sbar_ha_30 = lcs_grass2wood.sbar_ha_20;
    lcs_grass2wood.sbar_ha_40 = lcs_grass2wood.sbar_ha_20;
    lcs_grass2wood.sbar_ha_50 = lcs_grass2wood.sbar_ha_20;
    
    lcs_grass2wood.pot_ha_30 = lcs_grass2wood.pot_ha_20;
    lcs_grass2wood.pot_ha_40 = lcs_grass2wood.pot_ha_20;
    lcs_grass2wood.pot_ha_50 = lcs_grass2wood.pot_ha_20;
    
    lcs_grass2wood.sb_ha_30 = lcs_grass2wood.sb_ha_20;
    lcs_grass2wood.sb_ha_40 = lcs_grass2wood.sb_ha_20;
    lcs_grass2wood.sb_ha_50 = lcs_grass2wood.sb_ha_20;
    
    lcs_grass2wood.other_ha_30 = lcs_grass2wood.other_ha_20;
    lcs_grass2wood.other_ha_40 = lcs_grass2wood.other_ha_20;
    lcs_grass2wood.other_ha_50 = lcs_grass2wood.other_ha_20;
    
    lcs_grass2wood.tgrass_ha_30 = lcs_grass2wood.tgrass_ha_20;
    lcs_grass2wood.tgrass_ha_40 = lcs_grass2wood.tgrass_ha_20;
    lcs_grass2wood.tgrass_ha_50 = lcs_grass2wood.tgrass_ha_20;
    
    % Reset total farming grassland
    lcs_grass2wood.grass_ha_20 = lcs_grass2wood.tgrass_ha_20;
    lcs_grass2wood.grass_ha_30 = lcs_grass2wood.tgrass_ha_30;
    lcs_grass2wood.grass_ha_40 = lcs_grass2wood.tgrass_ha_40;
    lcs_grass2wood.grass_ha_50 = lcs_grass2wood.tgrass_ha_50;
    
    % Save to lcs_grass2wood.mat file
    % -------------------------------
    save('MAT Files/lcs_grass2wood.mat', 'lcs_grass2wood', '-mat', '-v6');
else
    load('MAT Files//lcs_grass2wood.mat', 'lcs_grass2wood')
end




%% (4) Check land covers sum to 400 hectares in all cells
%  ======================================================
% Choose land covers to test 
% test_lcs = lcs_baseline;
% test_lcs = lcs_arable2sng;
% test_lcs = lcs_arable2wood;
% test_lcs = lcs_grass2sng;
test_lcs = lcs_grass2wood;

% Land cover checks (should return logical 1)
isequal(repmat(400, size(test_lcs, 1), 1), round(sum(table2array(test_lcs(:, {'water_ha', 'urban_ha', 'wood_ha', 'sngrass_ha', 'farm_ha'})), 2), 6))
isequal(repmat(400, size(test_lcs, 1), 1), round(sum(table2array(test_lcs(:, {'water_ha', 'urban_ha', 'wood_ha', 'sngrass_ha', 'arable_ha_20', 'grass_ha_20'})), 2), 6))
isequal(repmat(400, size(test_lcs, 1), 1), round(sum(table2array(test_lcs(:, {'water_ha', 'urban_ha', 'wood_ha', 'sngrass_ha', 'arable_ha_30', 'grass_ha_30'})), 2), 6))
isequal(repmat(400, size(test_lcs, 1), 1), round(sum(table2array(test_lcs(:, {'water_ha', 'urban_ha', 'wood_ha', 'sngrass_ha', 'arable_ha_40', 'grass_ha_40'})), 2), 6))
isequal(repmat(400, size(test_lcs, 1), 1), round(sum(table2array(test_lcs(:, {'water_ha', 'urban_ha', 'wood_ha', 'sngrass_ha', 'arable_ha_50', 'grass_ha_50'})), 2), 6))
isequal(repmat(400, size(test_lcs, 1), 1), round(sum(table2array(test_lcs(:, {'water_ha', 'urban_ha', 'wood_ha', 'sngrass_ha', 'wheat_ha_20', 'osr_ha_20', 'wbar_ha_20', 'sbar_ha_20', 'pot_ha_20', 'sb_ha_20', 'other_ha_20', 'pgrass_ha_20', 'tgrass_ha_20', 'rgraz_ha_20'})), 2), 6))
isequal(repmat(400, size(test_lcs, 1), 1), round(sum(table2array(test_lcs(:, {'water_ha', 'urban_ha', 'wood_ha', 'sngrass_ha', 'wheat_ha_30', 'osr_ha_30', 'wbar_ha_30', 'sbar_ha_30', 'pot_ha_30', 'sb_ha_30', 'other_ha_30', 'pgrass_ha_30', 'tgrass_ha_30', 'rgraz_ha_30'})), 2), 6))
isequal(repmat(400, size(test_lcs, 1), 1), round(sum(table2array(test_lcs(:, {'water_ha', 'urban_ha', 'wood_ha', 'sngrass_ha', 'wheat_ha_40', 'osr_ha_40', 'wbar_ha_40', 'sbar_ha_40', 'pot_ha_40', 'sb_ha_40', 'other_ha_40', 'pgrass_ha_40', 'tgrass_ha_40', 'rgraz_ha_40'})), 2), 6))
isequal(repmat(400, size(test_lcs, 1), 1), round(sum(table2array(test_lcs(:, {'water_ha', 'urban_ha', 'wood_ha', 'sngrass_ha', 'wheat_ha_50', 'osr_ha_50', 'wbar_ha_50', 'sbar_ha_50', 'pot_ha_50', 'sb_ha_50', 'other_ha_50', 'pgrass_ha_50', 'tgrass_ha_50', 'rgraz_ha_50'})), 2), 6))
