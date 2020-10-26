function es_water_non_use = fcn_run_water_non_use(water_non_use_data_folder, es_water)

    %% (1) INITIALIZE
    %  ==============
    
    % a. Constants/flags
    % ------------------
	% River length scale - should we multiply value by the length of the river in cell?
	% Continuous - should we use the switch probabilities continuously or use the maximum probability?
    river_length_scale_flag = false;	% false is more conservative
    continuous_flag = true;				% true is more conservative
    
    Nchoice = 365;
    decade_string = {'_20', '_30', '_40', '_50'};
    
    % b. NEVO .mats from ImportWaterNonUse.m
    % --------------------------------------
    NEVO_water_non_use_data_mat = strcat(water_non_use_data_folder, 'NEVO_NU_Water_data.mat');
    load(NEVO_water_non_use_data_mat);
    
    %% (2) DATA FOR NEVO INPUT SUBBASINS
    %  =================================
    % Given NEVO subbasins in es_water, extract affected river cells
    [input_srcid_ind, input_srcid_idx] = ismember(WaterNonUse.src_id, cell2table(es_water.src_id, 'VariableNames', {'src_id'}));
    input_srcid_idx                    = input_srcid_idx(input_srcid_ind);
    
    % Reduce data down to these river cells
    WaterNonUse.src_id = WaterNonUse.src_id(input_srcid_ind, :);
    WaterNonUse.river_cells_1400_baseline = WaterNonUse.river_cells_1400_baseline(input_srcid_ind, :);
    WaterNonUse.nutr_init_class = WaterNonUse.nutr_init_class(input_srcid_ind, :);
    WaterNonUse.wfd_init_class = WaterNonUse.wfd_init_class(input_srcid_ind, :);
    
    % Given river cells, extract affected lsoas
    % Are river cells in lsoa's nearest 500 list (closest_idx)?
    % (we use index_2km here / river_cell_idx rather than new2kid)
    river_cell_idx = find(input_srcid_ind);
    [lsoa_ind_mat, lsoa_idx_mat] = ismember(WaterNonUse.closest_idx, river_cell_idx);
    lsoa_ind = any(lsoa_ind_mat); % logical of lsoas affected
    
    % Reduce data down to these lsoas
    WaterNonUse.lsoa_data = WaterNonUse.lsoa_data(lsoa_ind, :);
    WaterNonUse.cell_dist_500 = WaterNonUse.cell_dist_500(lsoa_ind, :);
    WaterNonUse.closest_idx = WaterNonUse.closest_idx(:, lsoa_ind);
    lsoa_ind_mat = lsoa_ind_mat(:, lsoa_ind); % for extracting from cell_dist_500 later
    lsoa_idx_mat = lsoa_idx_mat(:, lsoa_ind); % for extracting from cell_dist_500 later
    
    % Number of river cells and lsoas for these subbasins
    num_river_cell = sum(input_srcid_ind);
    num_lsoa = sum(lsoa_ind);
    
    % For reduced list of affected lsoas and river cells, get list of
    % closest river cells to each lsoa (in order nearest to furthest)
    lsoa_river_cells_order = cell(num_lsoa, 1);
    for i = 1:num_lsoa
        lsoa_river_cells_order{i} = lsoa_idx_mat(lsoa_ind_mat(:, i), i);
    end
    
    %% (3) CALCULATE WATER NON USE ES
    %  ==============================
    
    % New nutrient concentrations and classes
    % ---------------------------------------
    
    
    % For now, set new concentrations to 2020-2029
    %% !!! need to consider other decades (baseline and scenario) too
    %% !!! need a temporal loop somewhere around here
    % Use input_srcid_idx index to get concentrations for river cells (in correct order)
    nitr_new_20 = es_water.totn_20(input_srcid_idx);
    phos_new_20 = es_water.totp_20(input_srcid_idx);
    nitr_new_30 = es_water.totn_30(input_srcid_idx);
    phos_new_30 = es_water.totp_30(input_srcid_idx);
    nitr_new_40 = es_water.totn_40(input_srcid_idx);
    phos_new_40 = es_water.totp_40(input_srcid_idx);
    nitr_new_50 = es_water.totn_50(input_srcid_idx);
    phos_new_50 = es_water.totp_50(input_srcid_idx);
    nitr_new = [nitr_new_20, nitr_new_30, nitr_new_40, nitr_new_50];
    phos_new = [phos_new_20, phos_new_30, phos_new_40, phos_new_50];
    
    % Convert to nutrient class
    nitr_new_class = 1 * (nitr_new < 5) + 2 * (nitr_new > 5) .* (nitr_new < 10) + 3 * (nitr_new > 10) .* (nitr_new < 20) + 4 * (nitr_new > 20) .* (nitr_new < 30) + 5 * (nitr_new > 30) .* (nitr_new < 40) + 6 * (nitr_new > 40); 
    phos_new_class = 1 * (phos_new < 0.02) + 2 * (phos_new > 0.02) .* (phos_new < 0.06) + 3 * (phos_new > 0.06) .* (phos_new < 0.1) + 4 * (phos_new > 0.1) .* (phos_new < 0.2) + 5 * (phos_new > 0.2) .* (phos_new < 1) + 6 * (phos_new > 1); 
    
    nutr_new_class = zeros(size(nitr_new_class));
    wfd_new_class = zeros(size(nitr_new_class));
        
    % Loop over decades
    for i = 1:4
        
        % Get new nutrient class
        nutr_new_class(:,i) = max([nitr_new_class(:,i) phos_new_class(:,i)], [], 2);
        
        % Extract probabilities of switching class
        lookup_table_idx = fcn_get_wfd_lookup_index(WaterNonUse.nutr_init_class(:,i), nutr_new_class(:,i), WaterNonUse.wfd_init_class(:,i));
        switch_prob = table2array(WaterNonUse.wfd_lookup_table(lookup_table_idx, :));
        
        % Convert to new wfd class by taking maximum probability
        %% !!! should there be 5 classes here?
        [~, wfd_new_class(:,i)] = max(switch_prob, [], 2);
        
        % Reformat initial water quality
        WQual0 = [WaterNonUse.wfd_init_class(:,i) == 1, WaterNonUse.wfd_init_class(:,i) == 2, WaterNonUse.wfd_init_class(:,i) == 3, (WaterNonUse.wfd_init_class(:,i) == 4) | (WaterNonUse.wfd_init_class(:,i) == 5)];
        
        % Reformat new water quality
        if continuous_flag
            WQual1 = switch_prob;
        else    
            WQual1 = [wfd_new_class(:,i) == 1, wfd_new_class(:,i) == 2, wfd_new_class(:,i) == 3, wfd_new_class(:,i) == 4];
        end
        
        % Preallocate vectors 
        vCENU0 = zeros(num_lsoa, 1);
        vCENU1 = zeros(num_lsoa, 1);

        % Loop over lsoas
        for j = 1:num_lsoa

            % Extract distances to necessary river cells and apply distance decay
            DistdeltaNU = WaterNonUse.cell_dist_500(j, lsoa_ind_mat(:, j)) .^ WaterNonUse.deltaNU;

            if river_length_scale_flag
                % If river_length_scale_flag is true, also scale by river length (in kilometres)
                % Change the ordering to be consistent with distances
                DistdeltaNU = DistdeltaNU .* WaterNonUse.river_cells_1400_baseline.river_length(lsoa_river_cells_order{j})' / 1000;
            end

            % Extract water quality classes/probability for necessary river cells
            % Change the ordering to be consistent with distances
            % Multiply by beta parameter
            XbQNU0 = WQual0(lsoa_river_cells_order{j}, 2:4) * WaterNonUse.betaQNU;
            XbQNU1 = WQual1(lsoa_river_cells_order{j}, 2:4) * WaterNonUse.betaQNU;

            % Multiply decayed distances by XbQNU matrices, scaled up by Nchoice
            vCENU0(j) = Nchoice * DistdeltaNU * XbQNU0;
            vCENU1(j) = Nchoice * DistdeltaNU * XbQNU1;

        end

        % Output is difference in value, scaled by households in lsoa and
        % deltaU parameter
        % Save to function output as value_ann_decade
        es_water_non_use.(['value_ann', decade_string{i}]) = sum(WaterNonUse.lsoa_data.hhld .* (vCENU1 - vCENU0) / - WaterNonUse.deltaU);
        
    end
    
end
