%% script3_run_rep_cells.m
%  =======================
% Author: Nathan Owen
% Last modified: 22/06/2020
% Run water models (flow, water quality, flooding) for each representative 
% cell in each subcatchment when they change to other land uses. Here we 
% consider arable and grassland converting to semi-natural grassland, 
% woodland and maize.
% NB. this script takes a long time to run!
% (1-4 days per land use change depending on PC)
clear

%% (1) Set up
%  ==========
% (a) Define land use changes/options
% -----------------------------------
options = {'arable2sng', ...
           'arable2wood', ...
           'grass2sng', ...
           'grass2wood'};
num_options = length(options);

% (b) Add path to NEV model code
% ------------------------------
addpath(genpath('D:/Documents/Github/NEV/'))

% (c) Connect to database
% -----------------------
server_flag = false;
conn = fcn_connect_database(server_flag);

% (d) Path to water transfer model data
% -------------------------------------
water_transfer_data_folder    = 'D:/Documents/NEV/Model Data/Water Transfer/';
flooding_transfer_data_folder = 'D:/Documents/NEV/Model Data/Flooding Transfer/';    

% (e) Subcatchment information
% ----------------------------
% Subcatchment input/output
% Used to determine downstream subcatchments
load('D:/Documents/NEV/Model Data/Water Transfer/Input Output/firstdownstream.mat', 'firstdownstream')

% Subcatchment baseline summary data
load('D:/Documents/NEV/Model Data/Water Transfer/baseline_summary_data.mat', 'subctch_summary')

%% (2) Loop over options
%  =====================
for i = 1:num_options
    % Get this option name
    option_i = options{i};
    
    % (a) Load land use changes for this option
    % -----------------------------------------
    % Store in lcs_option_i
    % Also error check option names here
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
    
    % (b) Load representative cells for this option
    % ---------------------------------------------
    % Store in rep_cells_option_i
    split_opt = split(option_i, '2');
    option = split_opt{1};
    load(strcat('MAT Files/rep_cell_', option), 'subctch_rep_cell')
    rep_cells_option_i = subctch_rep_cell;
    num_rep_cells = size(rep_cells_option_i, 1);     % Number of representative cells
    
    % (c) Index between representative cell and land cover cells
    % ----------------------------------------------------------
    [~, idx_lcs] = ismember(rep_cells_option_i.new2kid, lcs_option_i.new2kid);
    
    %% (3) Loop over representative cells
    %  ----------------------------------
    % Run water model for each representative cell
    
    % Preallocate - vectors for within parfor loop
    downstream_subctch_id = cell(num_rep_cells, 1);
    flood_value_low = nan(num_rep_cells, 1);
    flood_value_medium = nan(num_rep_cells, 1);
    flood_value_high = nan(num_rep_cells, 1);
    q95_20 = cell(num_rep_cells, 1);
    q95_30 = cell(num_rep_cells, 1);
    q95_40 = cell(num_rep_cells, 1);
    q95_50 = cell(num_rep_cells, 1);
    q50_20 = cell(num_rep_cells, 1);
    q50_30 = cell(num_rep_cells, 1);
    q50_40 = cell(num_rep_cells, 1);
    q50_50 = cell(num_rep_cells, 1);
    q5_20 = cell(num_rep_cells, 1);
    q5_30 = cell(num_rep_cells, 1);
    q5_40 = cell(num_rep_cells, 1);
    q5_50 = cell(num_rep_cells, 1);
    qmean_20 = cell(num_rep_cells, 1);
    qmean_30 = cell(num_rep_cells, 1);
    qmean_40 = cell(num_rep_cells, 1);
    qmean_50 = cell(num_rep_cells, 1);
    v_20 = cell(num_rep_cells, 1);
    v_30 = cell(num_rep_cells, 1);
    v_40 = cell(num_rep_cells, 1);
    v_50 = cell(num_rep_cells, 1);
    orgn_20 = cell(num_rep_cells, 1);
    orgn_30 = cell(num_rep_cells, 1);
    orgn_40 = cell(num_rep_cells, 1);
    orgn_50 = cell(num_rep_cells, 1);
    no3_20 = cell(num_rep_cells, 1);
    no3_30 = cell(num_rep_cells, 1);
    no3_40 = cell(num_rep_cells, 1);
    no3_50 = cell(num_rep_cells, 1);
    no2_20 = cell(num_rep_cells, 1);
    no2_30 = cell(num_rep_cells, 1);
    no2_40 = cell(num_rep_cells, 1);
    no2_50 = cell(num_rep_cells, 1);
    nh4_20 = cell(num_rep_cells, 1);
    nh4_30 = cell(num_rep_cells, 1);
    nh4_40 = cell(num_rep_cells, 1);
    nh4_50 = cell(num_rep_cells, 1);
    totn_20 = cell(num_rep_cells, 1);
    totn_30 = cell(num_rep_cells, 1);
    totn_40 = cell(num_rep_cells, 1);
    totn_50 = cell(num_rep_cells, 1);
    orgp_20 = cell(num_rep_cells, 1);
    orgp_30 = cell(num_rep_cells, 1);
    orgp_40 = cell(num_rep_cells, 1);
    orgp_50 = cell(num_rep_cells, 1);
    pmin_20 = cell(num_rep_cells, 1);
    pmin_30 = cell(num_rep_cells, 1);
    pmin_40 = cell(num_rep_cells, 1);
    pmin_50 = cell(num_rep_cells, 1);
    totp_20 = cell(num_rep_cells, 1);
    totp_30 = cell(num_rep_cells, 1);
    totp_40 = cell(num_rep_cells, 1);
    totp_50 = cell(num_rep_cells, 1);
    chgq95_20 = cell(num_rep_cells, 1);
    chgq95_30 = cell(num_rep_cells, 1);
    chgq95_40 = cell(num_rep_cells, 1);
    chgq95_50 = cell(num_rep_cells, 1);
    chgq50_20 = cell(num_rep_cells, 1);
    chgq50_30 = cell(num_rep_cells, 1);
    chgq50_40 = cell(num_rep_cells, 1);
    chgq50_50 = cell(num_rep_cells, 1);
    chgq5_20 = cell(num_rep_cells, 1);
    chgq5_30 = cell(num_rep_cells, 1);
    chgq5_40 = cell(num_rep_cells, 1);
    chgq5_50 = cell(num_rep_cells, 1);
    chgqmean_20 = cell(num_rep_cells, 1);
    chgqmean_30 = cell(num_rep_cells, 1);
    chgqmean_40 = cell(num_rep_cells, 1);
    chgqmean_50 = cell(num_rep_cells, 1);
    chgv_20 = cell(num_rep_cells, 1);
    chgv_30 = cell(num_rep_cells, 1);
    chgv_40 = cell(num_rep_cells, 1);
    chgv_50 = cell(num_rep_cells, 1);
    chgorgn_20 = cell(num_rep_cells, 1);
    chgorgn_30 = cell(num_rep_cells, 1);
    chgorgn_40 = cell(num_rep_cells, 1);
    chgorgn_50 = cell(num_rep_cells, 1);
    chgno3_20 = cell(num_rep_cells, 1);
    chgno3_30 = cell(num_rep_cells, 1);
    chgno3_40 = cell(num_rep_cells, 1);
    chgno3_50 = cell(num_rep_cells, 1);
    chgno2_20 = cell(num_rep_cells, 1);
    chgno2_30 = cell(num_rep_cells, 1);
    chgno2_40 = cell(num_rep_cells, 1);
    chgno2_50 = cell(num_rep_cells, 1);
    chgnh4_20 = cell(num_rep_cells, 1);
    chgnh4_30 = cell(num_rep_cells, 1);
    chgnh4_40 = cell(num_rep_cells, 1);
    chgnh4_50 = cell(num_rep_cells, 1);
    chgtotn_20 = cell(num_rep_cells, 1);
    chgtotn_30 = cell(num_rep_cells, 1);
    chgtotn_40 = cell(num_rep_cells, 1);
    chgtotn_50 = cell(num_rep_cells, 1);
    chgorgp_20 = cell(num_rep_cells, 1);
    chgorgp_30 = cell(num_rep_cells, 1);
    chgorgp_40 = cell(num_rep_cells, 1);
    chgorgp_50 = cell(num_rep_cells, 1);
    chgpmin_20 = cell(num_rep_cells, 1);
    chgpmin_30 = cell(num_rep_cells, 1);
    chgpmin_40 = cell(num_rep_cells, 1);
    chgpmin_50 = cell(num_rep_cells, 1);
    chgtotp_20 = cell(num_rep_cells, 1);
    chgtotp_30 = cell(num_rep_cells, 1);
    chgtotp_40 = cell(num_rep_cells, 1);
    chgtotp_50 = cell(num_rep_cells, 1);
    
    % Preallocate - table for results outside parfor loop
    temp_table1 = array2table(nan(num_rep_cells, 6), ...
                              'VariableNames', ...
                              {'subctch_id', ...
                               'new2kid', ...
                               'hectares', ...
                               'flood_value_low', ...
                               'flood_value_medium', ...
                               'flood_value_high'});
    
    temp_table2 = cell2table(cell(num_rep_cells, 1 + 24*4), ...
                             'VariableNames', ...
                             {'downstream_subctch_id', ...
                              'q95_20', 'q95_30', 'q95_40', 'q95_50', ...
                              'q50_20', 'q50_30', 'q50_40', 'q50_50', ...
                              'q5_20', 'q5_30', 'q5_40', 'q5_50', ...
                              'qmean_20', 'qmean_30', 'qmean_40', 'qmean_50', ...
                              'v_20', 'v_30', 'v_40', 'v_50', ...
                              'orgn_20', 'orgn_30', 'orgn_40', 'orgn_50', ...
                              'no3_20', 'no3_30', 'no3_40', 'no3_50', ...
                              'no2_20', 'no2_30', 'no2_40', 'no2_50', ...
                              'nh4_20', 'nh4_30', 'nh4_40', 'nh4_50', ...
                              'totn_20', 'totn_30', 'totn_40', 'totn_50', ...
                              'totp_20', 'totp_30', 'totp_40', 'totp_50', ...
                              'chgq95_20', 'chgq95_30', 'chgq95_40', 'chgq95_50', ...
                              'chgq50_20', 'chgq50_30', 'chgq50_40', 'chgq50_50', ...
                              'chgq5_20', 'chgq5_30', 'chgq5_40', 'chgq5_50', ...
                              'chgqmean_20', 'chgqmean_30', 'chgqmean_40', 'chgqmean_50', ...
                              'chgv_20', 'chgv_30', 'chgv_40', 'chgv_50', ...
                              'chgorgn_20', 'chgorgn_30', 'chgorgn_40', 'chgorgn_50', ...
                              'chgno3_20', 'chgno3_30', 'chgno3_40', 'chgno3_50', ...
                              'chgno2_20', 'chgno2_30', 'chgno2_40', 'chgno2_50', ...
                              'chgnh4_20', 'chgnh4_30', 'chgnh4_40', 'chgnh4_50', ...
                              'chgtotn_20', 'chgtotn_30', 'chgtotn_40', 'chgtotn_50', ...
                              'chgorgp_20', 'chgorgp_30', 'chgorgp_40', 'chgorgp_50', ...
                              'chgpmin_20', 'chgpmin_30', 'chgpmin_40', 'chgpmin_50', ...
                              'chgtotp_20', 'chgtotp_30', 'chgtotp_40', 'chgtotp_50'});
                              
    results_option_i = [temp_table1, temp_table2];
    results_option_i.subctch_id = rep_cells_option_i.subctch_id;
    results_option_i.new2kid = rep_cells_option_i.new2kid;
    results_option_i.hectares = rep_cells_option_i.hectares;
    
    tic
%     for j = 1:num_rep_cells
    parfor j = 1:num_rep_cells

        % Print progress update
        disp([option_i, ': Processing subcatchment ', ...
              num2str(j), ' of ', num2str(num_rep_cells), ...
              ' (', rep_cells_option_i.subctch_id{j}, ')'])
          
        % (a) Get subctch_ids of subcatchments affected by change
        % -------------------------------------------------------
        affected_subctch_id = fcn_get_downstream_subctch_id(rep_cells_option_i.subctch_id(j), ...
                                                            firstdownstream);
        
        % (b) Get land use for this representative cell
        % ---------------------------------------------
        lcs_option_i_cell_j = lcs_option_i(idx_lcs(j), :);
        
        % (c) Run water model under these land uses
        % -----------------------------------------
        % Limit land cover change in subcatchment
        [es_water_transfer_temp, ...
            flow_transfer_temp] = fcn_run_water_transfer(water_transfer_data_folder, ...
                                                         lcs_option_i_cell_j, ...
                                                         affected_subctch_id, ...
                                                         0, ...
                                                         'baseline', ...
                                                         rep_cells_option_i.subctch_id(j));
                                                     
        % (d) Run flooding model
        % ----------------------
        es_flooding_transfer_temp = fcn_run_flooding_transfer(flooding_transfer_data_folder, ...
                                                              affected_subctch_id, ...
                                                              flow_transfer_temp, ...
                                                              7, ...
                                                              false);
                                                          
        % Sum value across affected subcatchments to get flood value for this cell
        % Save the 3 different flood values for comparison
        flood_value_low(j) = nansum(es_flooding_transfer_temp.flood_value_low);
        flood_value_medium(j) = nansum(es_flooding_transfer_temp.flood_value_medium);
        flood_value_high(j) = nansum(es_flooding_transfer_temp.flood_value_high);
        
        % (e) Collect downstream water flow and quality information
        % ---------------------------------------------------------
        % Get index of subctch in subctch_summary
        [~, summary_idx] = ismember(es_water_transfer_temp.subctch_id, subctch_summary.subctch_id);
        subctch_summary_j = subctch_summary(summary_idx, :);
        
        % Save downstream subctch_id, water quality measures and changes from baseline
        downstream_subctch_id(j) = {es_water_transfer_temp.subctch_id'};
        
        q95_20(j) = {es_water_transfer_temp.q95_20'};
        q95_30(j) = {es_water_transfer_temp.q95_30'};
        q95_40(j) = {es_water_transfer_temp.q95_40'};
        q95_50(j) = {es_water_transfer_temp.q95_50'};
        
        q50_20(j) = {es_water_transfer_temp.q50_20'};
        q50_30(j) = {es_water_transfer_temp.q50_30'};
        q50_40(j) = {es_water_transfer_temp.q50_40'};
        q50_50(j) = {es_water_transfer_temp.q50_50'};
        
        q5_20(j) = {es_water_transfer_temp.q5_20'};
        q5_30(j) = {es_water_transfer_temp.q5_30'};
        q5_40(j) = {es_water_transfer_temp.q5_40'};
        q5_50(j) = {es_water_transfer_temp.q5_50'};
        
        qmean_20(j) = {es_water_transfer_temp.qmean_20'};
        qmean_30(j) = {es_water_transfer_temp.qmean_30'};
        qmean_40(j) = {es_water_transfer_temp.qmean_40'};
        qmean_50(j) = {es_water_transfer_temp.qmean_50'};
        
        v_20(j) = {es_water_transfer_temp.v_20'};
        v_30(j) = {es_water_transfer_temp.v_30'};
        v_40(j) = {es_water_transfer_temp.v_40'};
        v_50(j) = {es_water_transfer_temp.v_50'};
        
        orgn_20(j) = {es_water_transfer_temp.orgn_20'};
        orgn_30(j) = {es_water_transfer_temp.orgn_30'};
        orgn_40(j) = {es_water_transfer_temp.orgn_40'};
        orgn_50(j) = {es_water_transfer_temp.orgn_50'};
        
        no3_20(j) = {es_water_transfer_temp.no3_20'};
        no3_30(j) = {es_water_transfer_temp.no3_30'};
        no3_40(j) = {es_water_transfer_temp.no3_40'};
        no3_50(j) = {es_water_transfer_temp.no3_50'};
        
        no2_20(j) = {es_water_transfer_temp.no2_20'};
        no2_30(j) = {es_water_transfer_temp.no2_30'};
        no2_40(j) = {es_water_transfer_temp.no2_40'};
        no2_50(j) = {es_water_transfer_temp.no2_50'};
        
        nh4_20(j) = {es_water_transfer_temp.nh4_20'};
        nh4_30(j) = {es_water_transfer_temp.nh4_30'};
        nh4_40(j) = {es_water_transfer_temp.nh4_40'};
        nh4_50(j) = {es_water_transfer_temp.nh4_50'};
        
        totn_20(j) = {es_water_transfer_temp.totn_20'};
        totn_30(j) = {es_water_transfer_temp.totn_30'};
        totn_40(j) = {es_water_transfer_temp.totn_40'};
        totn_50(j) = {es_water_transfer_temp.totn_50'};
        
        orgp_20(j) = {es_water_transfer_temp.orgp_20'};
        orgp_30(j) = {es_water_transfer_temp.orgp_30'};
        orgp_40(j) = {es_water_transfer_temp.orgp_40'};
        orgp_50(j) = {es_water_transfer_temp.orgp_50'};
        
        pmin_20(j) = {es_water_transfer_temp.pmin_20'};
        pmin_30(j) = {es_water_transfer_temp.pmin_30'};
        pmin_40(j) = {es_water_transfer_temp.pmin_40'};
        pmin_50(j) = {es_water_transfer_temp.pmin_50'};
        
        totp_20(j) = {es_water_transfer_temp.totp_20'};
        totp_30(j) = {es_water_transfer_temp.totp_30'};
        totp_40(j) = {es_water_transfer_temp.totp_40'};
        totp_50(j) = {es_water_transfer_temp.totp_50'};
        
        chgq95_20(j) = {(es_water_transfer_temp.q95_20 - subctch_summary_j.q95_20)'};
        chgq95_30(j) = {(es_water_transfer_temp.q95_30 - subctch_summary_j.q95_30)'};
        chgq95_40(j) = {(es_water_transfer_temp.q95_40 - subctch_summary_j.q95_40)'};
        chgq95_50(j) = {(es_water_transfer_temp.q95_50 - subctch_summary_j.q95_50)'};
        
        chgq50_20(j) = {(es_water_transfer_temp.q50_20 - subctch_summary_j.q50_20)'};
        chgq50_30(j) = {(es_water_transfer_temp.q50_30 - subctch_summary_j.q50_30)'};
        chgq50_40(j) = {(es_water_transfer_temp.q50_40 - subctch_summary_j.q50_40)'};
        chgq50_50(j) = {(es_water_transfer_temp.q50_50 - subctch_summary_j.q50_50)'};
        
        chgq5_20(j) = {(es_water_transfer_temp.q5_20 - subctch_summary_j.q5_20)'};
        chgq5_30(j) = {(es_water_transfer_temp.q5_30 - subctch_summary_j.q5_30)'};
        chgq5_40(j) = {(es_water_transfer_temp.q5_40 - subctch_summary_j.q5_40)'};
        chgq5_50(j) = {(es_water_transfer_temp.q5_50 - subctch_summary_j.q5_50)'};
        
        chgqmean_20(j) = {(es_water_transfer_temp.qmean_20 - subctch_summary_j.qmean_20)'};
        chgqmean_30(j) = {(es_water_transfer_temp.qmean_30 - subctch_summary_j.qmean_30)'};
        chgqmean_40(j) = {(es_water_transfer_temp.qmean_40 - subctch_summary_j.qmean_40)'};
        chgqmean_50(j) = {(es_water_transfer_temp.qmean_50 - subctch_summary_j.qmean_50)'};
        
        chgv_20(j) = {(es_water_transfer_temp.v_20 - subctch_summary_j.v_20)'};
        chgv_30(j) = {(es_water_transfer_temp.v_30 - subctch_summary_j.v_30)'};
        chgv_40(j) = {(es_water_transfer_temp.v_40 - subctch_summary_j.v_40)'};
        chgv_50(j) = {(es_water_transfer_temp.v_50 - subctch_summary_j.v_50)'};
        
        chgorgn_20(j) = {(es_water_transfer_temp.orgn_20 - subctch_summary_j.orgn_20)'};
        chgorgn_30(j) = {(es_water_transfer_temp.orgn_30 - subctch_summary_j.orgn_30)'};
        chgorgn_40(j) = {(es_water_transfer_temp.orgn_40 - subctch_summary_j.orgn_40)'};
        chgorgn_50(j) = {(es_water_transfer_temp.orgn_50 - subctch_summary_j.orgn_50)'};
        
        chgno3_20(j) = {(es_water_transfer_temp.no3_20 - subctch_summary_j.no3_20)'};
        chgno3_30(j) = {(es_water_transfer_temp.no3_30 - subctch_summary_j.no3_30)'};
        chgno3_40(j) = {(es_water_transfer_temp.no3_40 - subctch_summary_j.no3_40)'};
        chgno3_50(j) = {(es_water_transfer_temp.no3_50 - subctch_summary_j.no3_50)'};
        
        chgno2_20(j) = {(es_water_transfer_temp.no2_20 - subctch_summary_j.no2_20)'};
        chgno2_30(j) = {(es_water_transfer_temp.no2_30 - subctch_summary_j.no2_30)'};
        chgno2_40(j) = {(es_water_transfer_temp.no2_40 - subctch_summary_j.no2_40)'};
        chgno2_50(j) = {(es_water_transfer_temp.no2_50 - subctch_summary_j.no2_50)'};
        
        chgnh4_20(j) = {(es_water_transfer_temp.nh4_20 - subctch_summary_j.nh4_20)'};
        chgnh4_30(j) = {(es_water_transfer_temp.nh4_30 - subctch_summary_j.nh4_30)'};
        chgnh4_40(j) = {(es_water_transfer_temp.nh4_40 - subctch_summary_j.nh4_40)'};
        chgnh4_50(j) = {(es_water_transfer_temp.nh4_50 - subctch_summary_j.nh4_50)'};
        
        chgtotn_20(j) = {(es_water_transfer_temp.totn_20 - subctch_summary_j.totn_20)'};
        chgtotn_30(j) = {(es_water_transfer_temp.totn_30 - subctch_summary_j.totn_30)'};
        chgtotn_40(j) = {(es_water_transfer_temp.totn_40 - subctch_summary_j.totn_40)'};
        chgtotn_50(j) = {(es_water_transfer_temp.totn_50 - subctch_summary_j.totn_50)'};
        
        chgorgp_20(j) = {(es_water_transfer_temp.orgp_20 - subctch_summary_j.orgp_20)'};
        chgorgp_30(j) = {(es_water_transfer_temp.orgp_30 - subctch_summary_j.orgp_30)'};
        chgorgp_40(j) = {(es_water_transfer_temp.orgp_40 - subctch_summary_j.orgp_40)'};
        chgorgp_50(j) = {(es_water_transfer_temp.orgp_50 - subctch_summary_j.orgp_50)'};
        
        chgpmin_20(j) = {(es_water_transfer_temp.pmin_20 - subctch_summary_j.pmin_20)'};
        chgpmin_30(j) = {(es_water_transfer_temp.pmin_30 - subctch_summary_j.pmin_30)'};
        chgpmin_40(j) = {(es_water_transfer_temp.pmin_40 - subctch_summary_j.pmin_40)'};
        chgpmin_50(j) = {(es_water_transfer_temp.pmin_50 - subctch_summary_j.pmin_50)'};
        
        chgtotp_20(j) = {(es_water_transfer_temp.totp_20 - subctch_summary_j.totp_20)'};
        chgtotp_30(j) = {(es_water_transfer_temp.totp_30 - subctch_summary_j.totp_30)'};
        chgtotp_40(j) = {(es_water_transfer_temp.totp_40 - subctch_summary_j.totp_40)'};
        chgtotp_50(j) = {(es_water_transfer_temp.totp_50 - subctch_summary_j.totp_50)'};
                
    end
    toc
    
    % Add values to results table
    results_option_i.downstream_subctch_id = downstream_subctch_id;
    results_option_i.flood_value_low = flood_value_low;
    results_option_i.flood_value_medium = flood_value_medium;
    results_option_i.flood_value_high = flood_value_high;
    results_option_i.q95_20 = q95_20;
    results_option_i.q95_30 = q95_30;
    results_option_i.q95_40 = q95_40;
    results_option_i.q95_50 = q95_50;
    results_option_i.q50_20 = q50_20;
    results_option_i.q50_30 = q50_30;
    results_option_i.q50_40 = q50_40;
    results_option_i.q50_50 = q50_50;
    results_option_i.q5_20 = q5_20;
    results_option_i.q5_30 = q5_30;
    results_option_i.q5_40 = q5_40;
    results_option_i.q5_50 = q5_50;
    results_option_i.qmean_20 = qmean_20;
    results_option_i.qmean_30 = qmean_30;
    results_option_i.qmean_40 = qmean_40;
    results_option_i.qmean_50 = qmean_50;
    results_option_i.v_20 = v_20;
    results_option_i.v_30 = v_30;
    results_option_i.v_40 = v_40;
    results_option_i.v_50 = v_50;
    results_option_i.orgn_20 = orgn_20;
    results_option_i.orgn_30 = orgn_30;
    results_option_i.orgn_40 = orgn_40;
    results_option_i.orgn_50 = orgn_50;
    results_option_i.no3_20 = no3_20;
    results_option_i.no3_30 = no3_30;
    results_option_i.no3_40 = no3_40;
    results_option_i.no3_50 = no3_50;
    results_option_i.no2_20 = no2_20;
    results_option_i.no2_30 = no2_30;
    results_option_i.no2_40 = no2_40;
    results_option_i.no2_50 = no2_50;
    results_option_i.nh4_20 = nh4_20;
    results_option_i.nh4_30 = nh4_30;
    results_option_i.nh4_40 = nh4_40;
    results_option_i.nh4_50 = nh4_50;
    results_option_i.totn_20 = totn_20;
    results_option_i.totn_30 = totn_30;
    results_option_i.totn_40 = totn_40;
    results_option_i.totn_50 = totn_50;
    results_option_i.orgp_20 = orgp_20;
    results_option_i.orgp_30 = orgp_30;
    results_option_i.orgp_40 = orgp_40;
    results_option_i.orgp_50 = orgp_50;
    results_option_i.pmin_20 = pmin_20;
    results_option_i.pmin_30 = pmin_30;
    results_option_i.pmin_40 = pmin_40;
    results_option_i.pmin_50 = pmin_50;
    results_option_i.totp_20 = totp_20;
    results_option_i.totp_30 = totp_30;
    results_option_i.totp_40 = totp_40;
    results_option_i.totp_50 = totp_50;
    results_option_i.chgq95_20 = chgq95_20;
    results_option_i.chgq95_30 = chgq95_30;
    results_option_i.chgq95_40 = chgq95_40;
    results_option_i.chgq95_50 = chgq95_50;
    results_option_i.chgq50_20 = chgq50_20;
    results_option_i.chgq50_30 = chgq50_30;
    results_option_i.chgq50_40 = chgq50_40;
    results_option_i.chgq50_50 = chgq50_50;
    results_option_i.chgq5_20 = chgq5_20;
    results_option_i.chgq5_30 = chgq5_30;
    results_option_i.chgq5_40 = chgq5_40;
    results_option_i.chgq5_50 = chgq5_50;
    results_option_i.chgqmean_20 = chgqmean_20;
    results_option_i.chgqmean_30 = chgqmean_30;
    results_option_i.chgqmean_40 = chgqmean_40;
    results_option_i.chgqmean_50 = chgqmean_50;
    results_option_i.chgv_20 = chgv_20;
    results_option_i.chgv_30 = chgv_30;
    results_option_i.chgv_40 = chgv_40;
    results_option_i.chgv_50 = chgv_50;
    results_option_i.chgorgn_20 = chgorgn_20;
    results_option_i.chgorgn_30 = chgorgn_30;
    results_option_i.chgorgn_40 = chgorgn_40;
    results_option_i.chgorgn_50 = chgorgn_50;
    results_option_i.chgno3_20 = chgno3_20;
    results_option_i.chgno3_30 = chgno3_30;
    results_option_i.chgno3_40 = chgno3_40;
    results_option_i.chgno3_50 = chgno3_50;
    results_option_i.chgno2_20 = chgno2_20;
    results_option_i.chgno2_30 = chgno2_30;
    results_option_i.chgno2_40 = chgno2_40;
    results_option_i.chgno2_50 = chgno2_50;
    results_option_i.chgnh4_20 = chgnh4_20;
    results_option_i.chgnh4_30 = chgnh4_30;
    results_option_i.chgnh4_40 = chgnh4_40;
    results_option_i.chgnh4_50 = chgnh4_50;
    results_option_i.chgtotn_20 = chgtotn_20;
    results_option_i.chgtotn_30 = chgtotn_30;
    results_option_i.chgtotn_40 = chgtotn_40;
    results_option_i.chgtotn_50 = chgtotn_50;
    results_option_i.chgorgp_20 = chgorgp_20;
    results_option_i.chgorgp_30 = chgorgp_30;
    results_option_i.chgorgp_40 = chgorgp_40;
    results_option_i.chgorgp_50 = chgorgp_50;
    results_option_i.chgpmin_20 = chgpmin_20;
    results_option_i.chgpmin_30 = chgpmin_30;
    results_option_i.chgpmin_40 = chgpmin_40;
    results_option_i.chgpmin_50 = chgpmin_50;
    results_option_i.chgtotp_20 = chgtotp_20;
    results_option_i.chgtotp_30 = chgtotp_30;
    results_option_i.chgtotp_40 = chgtotp_40;
    results_option_i.chgtotp_50 = chgtotp_50;
    
    % Save results table to .mat file depending on option name
    switch option_i
        case 'arable2sng'
            water_arable2sng = results_option_i;
            save('MAT Files/water_arable2sng', 'water_arable2sng');
        case 'arable2wood'
            water_arable2wood = results_option_i;
            save('MAT Files/water_arable2wood', 'water_arable2wood');
        case 'grass2sng'
            water_grass2sng = results_option_i;
            save('MAT Files/water_grass2sng', 'water_grass2sng');
        case 'grass2wood'
            water_grass2wood = results_option_i;
            save('MAT Files/water_grass2wood', 'water_grass2wood');
    end
    
end