%% script6_use_rep_cells.m
%  =======================
% Author: Nathan Owen
% Last modified: 10/09/2020
% For land use changes across GB, use per hectare representative cell water
% results to calculate flooding and water quality results. Here we consider
% arable and grassland converting to semi-natural grassland, woodland and 
% maize.
% Flooding values are scaled up by potential NFM areas.
% !!! water values are not scaled down by time it takes for woodland to
% !!! establish, like we did in the Defra ELMs project.
clear

%% (1) Set up
%  ==========
% (a) Define land use changes/options
% -----------------------------------
% (comment out as necessary)
options = {'arable2sng', ...
           'arable2wood', ...
           'grass2sng', ...
           'grass2wood'};

num_options = length(options);

% (b) Connect to database
% -----------------------
addpath(genpath('D:/Documents/Github/NEV/'))
NEV_data_path = 'D:/Documents/NEV/Model Data/';

server_flag = false;
conn = fcn_connect_database(server_flag);

% (c) Load key_grid_subcatchments
% -------------------------------
% Crossover between 2km grid cells and subcatchments

% (d) Path to water transfer model data
% -------------------------------------
% water_transfer_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Water Transfer\';
water_transfer_data_folder    = 'D:/Documents/NEV/Model Data/Water Transfer/';
load([water_transfer_data_folder, 'NEVO_Water_Transfer_data.mat'], 'base_lcs_subctch_cells')

key_grid_subcatchments = base_lcs_subctch_cells(:, {'subctch_id', 'new2kid', 'proportion'});
clear base_lcs_subctch_cells

% (d) Load NFM areas from database
% --------------------------------
sqlquery = ['SELECT ', ...
                'new2kid, ', ...
                'nfm_area_ha ', ...
            'FROM flooding.nfm_cells_gb ', ...
            'ORDER BY new2kid'];
setdbprefs('DataReturnFormat', 'table');
dataReturn  = fetch(exec(conn, sqlquery));
nfm_data = dataReturn.Data;

%% (2) Loop over options
%  =====================
for i = 1:num_options
    % Get this option name
    option_i = options{i};
    
    % (a) Load land use change hectares for this option
    % -------------------------------------------------
    switch option_i
        case 'arable2sng'
            load('MAT Files/lcs_arable2sng', 'lcs_arable2sng')
            lcs_option_i = lcs_arable2sng;
            clear lcs_arable2sng
        case 'arable2wood'
            load('MAT Files/lcs_arable2wood', 'lcs_arable2wood')
            lcs_option_i = lcs_arable2wood;
            clear lcs_arable2wood
        case 'grass2sng'
            load('MAT Files/lcs_grass2sng', 'lcs_grass2sng')
            lcs_option_i = lcs_grass2sng;
            clear lcs_grass2sng
        case 'grass2wood'
            load('MAT Files/lcs_grass2wood', 'lcs_grass2wood')
            lcs_option_i = lcs_grass2wood;
            clear lcs_grass2wood
        otherwise
            error('Option not found!')
    end
    num_cells = size(lcs_option_i, 1);
    
    % (b) Calculate hectares in cells in subcatchments
    % ------------------------------------------------
    % Use proportion of cell in subcatchment
    subctch_cell_data = innerjoin(key_grid_subcatchments, lcs_option_i(:, {'new2kid', 'hectares'}));
    subctch_cell_data.hectares = subctch_cell_data.proportion .* subctch_cell_data.hectares;
    
    % (c) Load representative cell results for this option
    % ----------------------------------------------------
    % Store in water_option_i
    switch option_i
        case 'arable2sng'
            load('MAT Files/water_arable2sng', 'water_arable2sng')
            water_option_i = water_arable2sng;
            clear water_arable2sng
        case 'arable2wood'
            load('MAT Files/water_arable2wood', 'water_arable2wood')
            water_option_i = water_arable2wood;
            clear water_arable2wood
        case 'grass2sng'
            load('MAT Files/water_grass2sng', 'water_grass2sng')
            water_option_i = water_grass2sng;
            clear water_grass2sng
        case 'grass2wood'
            load('MAT Files/water_grass2wood', 'water_grass2wood')
            water_option_i = water_grass2wood;
            clear water_grass2wood
    end
    
    % (d) Get crossover between subctch_cell_data table and representative cell subctch ids
    % -------------------------------------------------------------------------------------
    [key_ind, key_idx] = ismember(subctch_cell_data.subctch_id, water_option_i.subctch_id);
    
    % (e) Calculate per hectare values for representative cells
    % ---------------------------------------------------------
    flood_value_low_perha = water_option_i.flood_value_low ./ water_option_i.hectares;
    flood_value_medium_perha = water_option_i.flood_value_medium ./ water_option_i.hectares;
    flood_value_high_perha = water_option_i.flood_value_high ./ water_option_i.hectares;
    
    non_use_value_20_perha = water_option_i.non_use_value_20 ./ water_option_i.hectares;
    non_use_value_30_perha = water_option_i.non_use_value_30 ./ water_option_i.hectares;
    non_use_value_40_perha = water_option_i.non_use_value_40 ./ water_option_i.hectares;
    non_use_value_50_perha = water_option_i.non_use_value_50 ./ water_option_i.hectares;
    
    wt_totn_20_perha = water_option_i.wt_totn_20 ./ water_option_i.hectares;
    wt_totn_30_perha = water_option_i.wt_totn_30 ./ water_option_i.hectares;
    wt_totn_40_perha = water_option_i.wt_totn_40 ./ water_option_i.hectares;
    wt_totn_50_perha = water_option_i.wt_totn_50 ./ water_option_i.hectares;
    wt_totp_20_perha = water_option_i.wt_totp_20 ./ water_option_i.hectares;
    wt_totp_30_perha = water_option_i.wt_totp_30 ./ water_option_i.hectares;
    wt_totp_40_perha = water_option_i.wt_totp_40 ./ water_option_i.hectares;
    wt_totp_50_perha = water_option_i.wt_totp_50 ./ water_option_i.hectares;

    % Some nan cases (0/0), set to zero
    flood_value_low_perha(isnan(flood_value_low_perha)) = 0;
    flood_value_medium_perha(isnan(flood_value_medium_perha)) = 0;
    flood_value_high_perha(isnan(flood_value_high_perha)) = 0;
    
    non_use_value_20_perha(isnan(non_use_value_20_perha)) = 0;
    non_use_value_30_perha(isnan(non_use_value_30_perha)) = 0;
    non_use_value_40_perha(isnan(non_use_value_40_perha)) = 0;
    non_use_value_50_perha(isnan(non_use_value_50_perha)) = 0;
    
    wt_totn_20_perha(isnan(wt_totn_20_perha)) = 0;
    wt_totn_30_perha(isnan(wt_totn_30_perha)) = 0;
    wt_totn_40_perha(isnan(wt_totn_40_perha)) = 0;
    wt_totn_50_perha(isnan(wt_totn_50_perha)) = 0;
    wt_totp_20_perha(isnan(wt_totp_20_perha)) = 0;
    wt_totp_30_perha(isnan(wt_totp_30_perha)) = 0;
    wt_totp_40_perha(isnan(wt_totp_40_perha)) = 0;
    wt_totp_50_perha(isnan(wt_totp_50_perha)) = 0;
    
    % (f) Align per hectare values to lookup table and scale by proportion
    % --------------------------------------------------------------------
    % These are per hectare values for proportion of cell in subctch
    flood_value_low_perha_cell_subctch = flood_value_low_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    flood_value_medium_perha_cell_subctch = flood_value_medium_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    flood_value_high_perha_cell_subctch = flood_value_high_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    
    non_use_value_20_perha_cell_subctch = non_use_value_20_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    non_use_value_30_perha_cell_subctch = non_use_value_30_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    non_use_value_40_perha_cell_subctch = non_use_value_40_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    non_use_value_50_perha_cell_subctch = non_use_value_50_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    
    wt_totn_20_perha_cell_subctch = wt_totn_20_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    wt_totn_30_perha_cell_subctch = wt_totn_30_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    wt_totn_40_perha_cell_subctch = wt_totn_40_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    wt_totn_50_perha_cell_subctch = wt_totn_50_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    wt_totp_20_perha_cell_subctch = wt_totp_20_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    wt_totp_30_perha_cell_subctch = wt_totp_30_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    wt_totp_40_perha_cell_subctch = wt_totp_40_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    wt_totp_50_perha_cell_subctch = wt_totp_50_perha(key_idx(key_ind), :) .* subctch_cell_data.proportion(key_ind);
    
    % (g) Calculate per ha value for each cell
    % ----------------------------------------
    % Accumulate values for all subctch cell is in
    [chg_cellid, ~, cellid_idx] = unique(subctch_cell_data.new2kid(key_ind));
    flood_value_low_perha_cell = accumarray(cellid_idx, flood_value_low_perha_cell_subctch);
    flood_value_medium_perha_cell = accumarray(cellid_idx, flood_value_medium_perha_cell_subctch);
    flood_value_high_perha_cell = accumarray(cellid_idx, flood_value_high_perha_cell_subctch);
    
    non_use_value_20_perha_cell = accumarray(cellid_idx, non_use_value_20_perha_cell_subctch);
    non_use_value_30_perha_cell = accumarray(cellid_idx, non_use_value_30_perha_cell_subctch);
    non_use_value_40_perha_cell = accumarray(cellid_idx, non_use_value_40_perha_cell_subctch);
    non_use_value_50_perha_cell = accumarray(cellid_idx, non_use_value_50_perha_cell_subctch);
    
    wt_totn_20_perha_cell = accumarray(cellid_idx, wt_totn_20_perha_cell_subctch);
    wt_totn_30_perha_cell = accumarray(cellid_idx, wt_totn_30_perha_cell_subctch);
    wt_totn_40_perha_cell = accumarray(cellid_idx, wt_totn_40_perha_cell_subctch);
    wt_totn_50_perha_cell = accumarray(cellid_idx, wt_totn_50_perha_cell_subctch);
    wt_totp_20_perha_cell = accumarray(cellid_idx, wt_totp_20_perha_cell_subctch);
    wt_totp_30_perha_cell = accumarray(cellid_idx, wt_totp_30_perha_cell_subctch);
    wt_totp_40_perha_cell = accumarray(cellid_idx, wt_totp_40_perha_cell_subctch);
    wt_totp_50_perha_cell = accumarray(cellid_idx, wt_totp_50_perha_cell_subctch);
    
    % (h) Scale up values by hectares of land use change in cell
    % ----------------------------------------------------------
    % Create table to store results
    water_cell_option_i = array2table(zeros(num_cells, 17), ...
                                      'VariableNames', ...
                                      {'new2kid', ...
                                       'hectares', ...
                                       'flood_low', ...
                                       'flood_medium', ...
                                       'flood_high', ...
                                       'non_use_value_20', ...
                                       'non_use_value_30', ...
                                       'non_use_value_40', ...
                                       'non_use_value_50', ...
                                       'wt_totn_20', ...
                                       'wt_totn_30', ...
                                       'wt_totn_40', ...
                                       'wt_totn_50', ...
                                       'wt_totp_20', ...
                                       'wt_totp_30', ...
                                       'wt_totp_40', ...
                                       'wt_totp_50'});
    water_cell_option_i.new2kid = lcs_option_i.new2kid;
    water_cell_option_i.hectares = lcs_option_i.hectares;
    
    % Adjust NFM hectare area, used to scale flood values
    % NFM area cannot be larger than land use change hectares available
    nfm_ha_adjusted = nfm_data.nfm_area_ha;
    nfm_ha_adjusted(nfm_ha_adjusted > water_cell_option_i.hectares) = water_cell_option_i.hectares(nfm_ha_adjusted > water_cell_option_i.hectares);
    
    % Scale up by hectares
    % For scaling flood use NFM hectare area
    [~, cell2chgcell_idx] = ismember(chg_cellid, water_cell_option_i.new2kid);
    water_cell_option_i.flood_low(cell2chgcell_idx)    = flood_value_low_perha_cell    .* nfm_ha_adjusted(cell2chgcell_idx);
    water_cell_option_i.flood_medium(cell2chgcell_idx) = flood_value_medium_perha_cell .* nfm_ha_adjusted(cell2chgcell_idx);
    water_cell_option_i.flood_high(cell2chgcell_idx)   = flood_value_high_perha_cell   .* nfm_ha_adjusted(cell2chgcell_idx);
    
    water_cell_option_i.non_use_value_20(cell2chgcell_idx) = non_use_value_20_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    water_cell_option_i.non_use_value_30(cell2chgcell_idx) = non_use_value_30_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    water_cell_option_i.non_use_value_40(cell2chgcell_idx) = non_use_value_40_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    water_cell_option_i.non_use_value_50(cell2chgcell_idx) = non_use_value_50_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    
    water_cell_option_i.wt_totn_20(cell2chgcell_idx) = wt_totn_20_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    water_cell_option_i.wt_totn_30(cell2chgcell_idx) = wt_totn_30_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    water_cell_option_i.wt_totn_40(cell2chgcell_idx) = wt_totn_40_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    water_cell_option_i.wt_totn_50(cell2chgcell_idx) = wt_totn_50_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    water_cell_option_i.wt_totp_20(cell2chgcell_idx) = wt_totp_20_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    water_cell_option_i.wt_totp_30(cell2chgcell_idx) = wt_totp_30_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    water_cell_option_i.wt_totp_40(cell2chgcell_idx) = wt_totp_40_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    water_cell_option_i.wt_totp_50(cell2chgcell_idx) = wt_totp_50_perha_cell .* water_cell_option_i.hectares(cell2chgcell_idx);
    
    % Save to water_cell.mat file depending on option
    % -----------------------------------------------
    switch option_i
        case 'arable2sng'
            water_cell_arable2sng = water_cell_option_i;
            save('MAT Files/water_cell_arable2sng.mat', 'water_cell_arable2sng');
            clear water_cell_option_i
        case 'arable2wood'
            water_cell_arable2wood = water_cell_option_i;
            save('MAT Files/water_cell_arable2wood.mat', 'water_cell_arable2wood');
            clear water_cell_option_i
        case 'grass2sng'
            water_cell_grass2sng = water_cell_option_i;
            save('MAT Files/water_cell_grass2sng.mat', 'water_cell_grass2sng');
            clear water_cell_option_i
        case 'grass2wood'
            water_cell_grass2wood = water_cell_option_i;
            save('MAT Files/water_cell_grass2wood.mat', 'water_cell_grass2wood');
            clear water_cell_option_i   
    end 
end
