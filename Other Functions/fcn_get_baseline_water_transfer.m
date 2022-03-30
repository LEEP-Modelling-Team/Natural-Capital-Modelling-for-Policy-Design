% fcn_get_baseline_water_transfer.m
% ================================
% Author: Nathan Owen
% Last modified: 22/06/2020
% Take the base run of the NEV water transfer model for all subcatchments and 
% store summaries of the flow and water quality results in 
% baseline_summary_data.mat. The .mat file contains the summaries for all 
% subcatchments in the decades 2020s, 2030s, 2040s and 2050s.
function subctch_summary = fcn_get_baseline_water_transfer(parameters)

    % Load water transfer model data
    load([parameters.water_transfer_data_folder, 'NEVO_Water_Transfer_data.mat'])

    % Calculate number of basins and subcatchments
    num_basin = size(basin_ids, 1);
    num_subctch = size(base_lcs_subctch, 1);

    % Pre-allocate arrays to store results
    % number of days in years 2020-2059: 14610
    subctch_ids_unordered = [];   % subbasin ids

    var_names = {'q5', 'orgn', 'no3', 'no2', 'nh4', 'totn', 'orgp', 'pmin', 'totp'};
    subctch_summary_20 = array2table(nan(size(subctch_basins, 1), 9), 'VariableNames', strcat(var_names, '_20'));
    subctch_summary_30 = array2table(nan(size(subctch_basins, 1), 9), 'VariableNames', strcat(var_names, '_30'));
    subctch_summary_40 = array2table(nan(size(subctch_basins, 1), 9), 'VariableNames', strcat(var_names, '_40'));
    subctch_summary_50 = array2table(nan(size(subctch_basins, 1), 9), 'VariableNames', strcat(var_names, '_50'));

    % Start a counter for each decade
    count_20 = 1;
    count_30 = 1;
    count_40 = 1;
    count_50 = 1;

    % Loop over all basins
    for i = 1:num_basin

        % Extract this basin id and print to console
        basin_id = basin_ids(i);
        disp(basin_id)

        % Get subcatchment IDs in this basin, in specific order that they
        % were saved in base run
        subctch_ids_basini = subctch_basins.subctch_id(subctch_basins.basin_id == basin_ids(i));

        % Calculate number of subbasins in this basin
        num_subctch_basini = length(subctch_ids_basini);

        % Add subctch_ids to full list
        subctch_ids_unordered = [subctch_ids_unordered; subctch_ids_basini];

        % Loop over the four decades
        for decade = [2029, 2039, 2049, 2059]

            % Load baseline results for this basin in this decade
            load([parameters.water_transfer_data_folder, 'Base Run\base', num2str(basin_id), '_', num2str(decade), '.mat'])

            % Loop over all subbasins in basin
            for j = 1:num_subctch_basini

                % Save decade summaries of flow and water quality into arrays depending on decade
                switch decade
                    case 2029
                        % Also construct and store subbasin id here
                        subctch_summary_20(count_20, :) = fcn_subctch_summary_calc(basin_em_data{j}, '_20');
                        count_20 = count_20 + 1;
                    case 2039
                        subctch_summary_30(count_30, :) = fcn_subctch_summary_calc(basin_em_data{j}, '_30');
                        count_30 = count_30 + 1;
                    case 2049
                        subctch_summary_40(count_40, :) = fcn_subctch_summary_calc(basin_em_data{j}, '_40');
                        count_40 = count_40 + 1;
                    case 2059
                        subctch_summary_50(count_50, :) = fcn_subctch_summary_calc(basin_em_data{j}, '_50');
                        count_50 = count_50 + 1;
                end

            end

            % Clear basin data for this decade 
            clear basin_em_data

        end

    end

    % Combine summary info with subctch ids in single table
    summary_table = [array2table(subctch_ids_unordered, 'VariableNames', {'subctch_id'}), ...
                     subctch_summary_20, ...
                     subctch_summary_30, ...
                     subctch_summary_40, ...
                     subctch_summary_50];

    % Reorder data so that it is in the order of base_lcs_subctch.subctch_id
    summary_table_join = outerjoin(base_lcs_subctch, summary_table, 'MergeKeys', true, 'LeftVariables', 'subctch_id');
    [~, idx] = ismember(base_lcs_subctch.subctch_id, summary_table_join.subctch_id);
    summary_table_ordered = summary_table_join(idx, :);
    subctch_summary = summary_table_ordered;
end
