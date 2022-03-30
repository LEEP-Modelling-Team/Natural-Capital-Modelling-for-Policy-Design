%% script2_get_rep_cells.m
%  =======================
% Author: Nathan Owen
% Last modified: 20/06/2020
% Each subcatchment has a representative 2km grid cell. This is the cell in
% the subcatchment which has most hectares of the land use you are
% switching away from. Here we look at switching away from arable, farm
% grassland or woodland. This script calculates the representative cell for 
% each subcatchment for those two cases and saves info to .mat file.
clear

% Define land use option
% ----------------------
% option = 'arable';
% option = 'grass';
options = [{'arable'}, {'grass'}];

%% (1) Set up
%  ==========
% Baseline land covers
load('MAT Files/lcs_baseline.mat', 'lcs_baseline')

% WaterTransfer data
%water_transfer_data_folder = 'C:/Users/neo204/OneDrive - University of Exeter/NEV/Model Data/Water Transfer/';
water_transfer_data_folder = 'D:/Documents/NEV/Model Data/Water Transfer/';
load([water_transfer_data_folder, 'NEVO_Water_Transfer_data.mat'])

% Subcatchment IDs in order
subctch_ids = base_lcs_subctch.subctch_id;
num_subctch = size(subctch_ids, 1);

% Lookup table between 2km grid cells and subcatchments
key_grid_subcatchments = base_lcs_subctch_cells(:, {'subctch_id', 'new2kid', 'proportion'});

% Subcatchment ids that crossover with 2km grid cells
subctch_ids_land = unique(key_grid_subcatchments.subctch_id);
num_subctch_land = length(subctch_ids_land);

% First/next downstream subcatchment for each subcatchment
% (This is constructed in E:/WFD Package)
% load('C:/Users/neo204/OneDrive - University of Exeter/NEV/Model Data/Water Transfer/Input Output/firstdownstream.mat')
load('D:/Documents/NEV/Model Data/Water Transfer/Input Output/firstdownstream.mat')

% Subcatchment IDs with input/output
subctch_ids_io = firstdownstream.subctch_id(~strcmp('NA', firstdownstream.firstdownstream));
num_subctch_io = length(subctch_ids_io);

% Subcatchments to run the analysis for
% These are catchments which cross over with 2km grid cells and have
% input/output
subctch_temp = [subctch_ids_land; subctch_ids_io];
[~, idx_unique] = unique(subctch_temp);
subctch_ids_run = subctch_temp(setdiff(1:length(subctch_temp), idx_unique));    % extract duplicates
num_subctch_run = length(subctch_ids_run);

% Reduce key_grid_subcatchments table to subctch_ids_run
ind_subctch_run = ismember(key_grid_subcatchments.subctch_id, subctch_ids_run);
key_grid_subcatchments_run = key_grid_subcatchments(ind_subctch_run, :);

%% (2) Calculate representative cell
%  =================================
% Each subcatchment has a representative 2km grid cell. This is the cell in
% the subcatchment which has most hectares of arable or grass (2020).
% Flood value will be calculated for these cells only. Flood value for
% other cells are assumed to be a fraction of the representative cell
% value.

% Loop over all land & IO subcatchments, selecting representative cell
% Store in subctch_rep_cell table
for i = 1:length(options)
    % Add land use data to subctch_cell_data depending on option
    % Calculate hectares of this land use within subcatchment
    option = options{i};
    subctch_cell_data = innerjoin(key_grid_subcatchments_run, lcs_baseline(:, {'new2kid', strcat(option, '_ha_20')}));
    subctch_cell_data.hectares = subctch_cell_data.proportion .* (subctch_cell_data.(strcat(option, '_ha_20')));
    
    % find representative cell for each catchment
    subctch_rep_cell = [];
    for j = 1:num_subctch_run
        % Print subctch_id for progress
        disp(subctch_ids_run(j))

        % Select rows for i-th subbasin
        [ind_temp, ~] = ismember(subctch_cell_data.subctch_id, subctch_ids_run(j));
        temp_data = subctch_cell_data(ind_temp, :);

        % Retain row with largest hectare value and add to table
        [~, max_idx] = max(temp_data.hectares);
        subctch_rep_cell = [subctch_rep_cell; temp_data(max_idx, :)];
    end
    
    % Save table to .mat file
    save(strcat('MAT Files/rep_cell_', option, '.mat'), 'subctch_rep_cell', '-mat', '-v6');
end