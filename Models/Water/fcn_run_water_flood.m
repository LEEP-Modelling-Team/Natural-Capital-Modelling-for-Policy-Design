function es_water_flood = fcn_run_water_flood(water_flood_data_folder, input_sbsn, flow, event_parameter)

    %% (1) Set up
    %  ==========
    % (a) Constants
    % -------------
    if (event_parameter ~= 1 && event_parameter ~= 7)
        error('Event parameter must be 1 or 7.')
    end
    num_subbasin = size(input_sbsn, 1);
    day_seq = 1:14610;
    
    % (b) Data files
    % --------------
    NEVO_Water_Flood_data_mat = [water_flood_data_folder, 'NEVO_Water_Flood_data_', num2str(event_parameter), '.mat'];
    load(NEVO_Water_Flood_data_mat, 'WaterFlood');
    
    %% (2) Reduced to inputted subbasins
    %  =================================
    [input_sbsn_ind, input_sbsn_idx] = ismember(input_sbsn, WaterFlood.src_id);
    input_sbsn_idx = input_sbsn_idx(input_sbsn_ind);
    
    % WaterFlood structure
    WaterFlood = WaterFlood(input_sbsn_idx, :);
    
    %% (3) Calculate flooding outputs
    %  ==============================
    % Preallocate outputs
    flood_value_30 = zeros(num_subbasin, 1);
    flood_value_30_100 = zeros(num_subbasin, 1);
    flood_value_30_100_1000 = zeros(num_subbasin, 1);
    
    % These are 'bad' subbasins - flood model doesn't work for these
    % as flow is zero
    bad_src_id = {'43013_5', '43013_6', '43013_8', '43013_10', '43013_12', '43013_15', '45005_3', '45005_6', '46006_3', '46006_5', '46006_7', '46006_10', '48005_6', '48005_7', '48005_13', '48007_3'};
    
    % Loop over subbasins
    for i = 1:num_subbasin
        if ~any(strcmp(input_sbsn(i), bad_src_id))
            % (a) Get baseline info for this subbasin
            % ---------------------------------------
            base_threshold = WaterFlood.threshold(i);                       % threshold
            base_num_events_per_year = WaterFlood.num_events_per_year(i);   % number of events per year
            damage_30 = WaterFlood.damage_30(i);                            % damage for 30-year event
            damage_100 = WaterFlood.damage_100(i);                          % damage for 100-year event
            damage_1000 = WaterFlood.damage_1000(i);                        % damage for 1000-year event

            % (b) Calculate number of events per year in scenario
            % ---------------------------------------------------
            % Get scenario flow events above baseline threshold
            [day_seq_events, ~] = fcn_get_flow_events(day_seq, flow(i, :), base_threshold, event_parameter);

            % Calculate scenario number of events per year
            scen_num_events = length(day_seq_events);
            scen_num_events_per_year = scen_num_events / 40;
            
            % (c) Has number of events per year reduced?
            % ------------------------------------------
            % Flood value only generated if number of events per year has
            % reduced
            % Take the minimum of baseline and scenario number events per
            % year
            scen_num_events_per_year = min(base_num_events_per_year, scen_num_events_per_year);

            % (d) Calculate probability of 30, 100, and 1000 year events in
            % scenario
            % -------------------------------------------------------------
            % Baseline probability is reciprocal of 30, 100 and 1000
            % Reverse order to make calculations easier
            base_prob = [1/1000, 1/100, 1/30]; 
            
            % Scenario probability is baseline probability multiplied by
            % factor scen_num_events_per_year / base_num_events_per_year
            % Note: if scenario number of events per year has not reduced
            % this factor is 1, i.e. probabilities remain the same
            scen_prob = (scen_num_events_per_year / base_num_events_per_year) * base_prob;
            
            % (e) Calculate expected damage reduction / flood benefit
            % -------------------------------------------------------
            % Approximate as rectangular area
            % Reduction in probability of 1000, 100 and 30 year events
            diff_prob = base_prob - scen_prob;
            
            % First differences of damages
            % Reverse order to be consistent with order of probabilities
            damages = [damage_1000, damage_100, damage_30];
            diff_damage = [abs(diff(damages)) damages(3)];

            % Calculate 3 areas associated with 1000, 100 and 30 year
            % events (approximate as rectangular areas)
            areas = diff_prob .* diff_damage;
            
            % Return three outputs...
            % 1. If land use change assumed to affect only 30 year event
            % 2. If land use change assumed to affect 30 and 100 year events
            % 3. If land use change assumed to affect 30, 100 and 1000 year events
            flood_value_30(i) = areas(3);
            flood_value_30_100(i) = sum(areas(2:3));
            flood_value_30_100_1000(i) = sum(areas);
        else
            % No action taken, flood values remain at zero
        end      
    end
    
    %% (4) Format output
    %  =================
    % Return as table
    es_water_flood = table(input_sbsn, ...
                           flood_value_30, ...
                           flood_value_30_100, ...
                           flood_value_30_100_1000, ...
                           'VariableNames', ...
                           {'src_id', ...
                            'flood_value_30', ...
                            'flood_value_30_100', ...
                            'flood_value_30_100_1000'});

end