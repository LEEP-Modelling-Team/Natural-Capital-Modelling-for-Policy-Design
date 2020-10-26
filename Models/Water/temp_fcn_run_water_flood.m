function es_water_flood = fcn_run_water_flood(water_flood_data_folder, input_sbsn, flow, event_parameter)

    %% (1) INITIALIZE
    %  ==============
    
    % a. Constants
    % ------------
    if (event_parameter ~= 1 && event_parameter ~= 7)
        error('Event parameter must be 1 or 7.')
    end
    num_subbasin = size(input_sbsn, 1);
    day_seq = 1:14610;
    
    % b. Data files
    % -------------
    NEVO_Water_Flood_data_mat = [water_flood_data_folder, 'NEVO_Water_Flood_data_', num2str(event_parameter), '.mat'];
    
    % c. NEVO mats from ImportWaterFlood
    % ----------------------------------
    load(NEVO_Water_Flood_data_mat);
    
    %% (2) DATA FOR NEVO INPUT SUBBASINS
    %  =================================
    [input_sbsn_ind, input_sbsn_idx] = ismember(input_sbsn, WaterFlood.src_id);
    input_sbsn_idx = input_sbsn_idx(input_sbsn_ind);
    
    WaterFlood = WaterFlood(input_sbsn_idx, :);
    
    %% (3) CALCULATE WATER FLOOD ES
    %  ============================
    
    % (a) Difference in flood damage value
    % ------------------------------------
    
    % Preallocate
    flood_value = zeros(num_subbasin, 1);
    
    % These are 'bad' subbasins - flood model doesn't work for these
    % as flow is zero
    bad_src_id = {'43013_5', '43013_6', '43013_8', '43013_10', '43013_12', '43013_15', '45005_3', '45005_6', '46006_3', '46006_5', '46006_7', '46006_10', '48005_6', '48005_7', '48005_13', '48007_3'};
    
    for i = 1:num_subbasin
        
        if ~any(strcmp(input_sbsn(i), bad_src_id))
        
            % Get the baseline info for this subbasin
            threshold = WaterFlood.threshold(i);                % threshold
            return_level_30 = WaterFlood.return_level_30(i);    % return level (30 year event)
            return_level_100 = WaterFlood.return_level_100(i);  % return level (100 year event)
            return_level_1000 = WaterFlood.return_level_1000(i);% return level (1000 year event)
            damage_30 = WaterFlood.damage_30(i);
            damage_100 = WaterFlood.damage_100(i);
            damage_1000 = WaterFlood.damage_1000(i);
            
            % Baseline parameters for Pareto distribution
            shapebase = WaterFlood.shape(i);
            scalebase = WaterFlood.scale(i);
%             parmbase = [shapebase, scalebase];

            % Store return levels and damages in reverse 
            % (makes area calculation easier later)
            return_levels = [return_level_1000, return_level_100, return_level_30];
            damages = [damage_1000, damage_100, damage_30];

            % Get scenario flow events above baseline threshold
%             [day_seq_events, flow_events] = fcn_get_flow_events(day_seq, flow(i, :), threshold, event_parameter);
            [day_seq_events, ~] = fcn_get_flow_events(day_seq, flow(i, :), threshold, event_parameter);

            % Calculate scenario number of events per year
            num_events = length(day_seq_events);
            num_events_per_year = num_events / 40;
            
            % Take the minimum of baseline and scenario number events per
            % year
            % !!! Decreased events per year generates flood value
            % !!! This is how we generate flood value
            num_events_per_year = min(num_events_per_year, WaterFlood.num_events_per_year(i));

%             % Convert flow events to flow exceedances by subtracting threshold
%             flow_exceed = flow_events - threshold;
% 
%             % Fit Generalized Pareto distribution to flow exceedances
%             % Store shape and scale parameters
% %             [parm_hat, ~] = mygpfit(flow_exceed, parmbase);
%             [parm_hat, ~] = gpfit(flow_exceed);
%             shape_hat = parm_hat(1);
%             scale_hat = parm_hat(2);

            % Calculate probability of exceeding baseline return levels under
            % this Generalized Pareto distribution
%             prob_exceed = gpcdf(return_levels, shape_hat, scale_hat, threshold, 'upper');

            % !!! Assume distribution stays the same as under baseline - no
            % re-estimation
            prob_exceed = gpcdf(return_levels, shapebase, scalebase, threshold, 'upper');

            % Convert probability of exceedance into return periods, adjusting
            % by number of events per year in scenario
            return_periods = 1 ./ (num_events_per_year * prob_exceed);

            % Probability of each damage cost under baseline and scenario
            baseline_prob = [1/1000, 1/100, 1/30];
            scenario_prob = 1 ./ return_periods;

            % Difference in area under probability-damage curve
            % Approximate as rectangular area
            diff_prob = baseline_prob - scenario_prob;
            diff_damage = [abs(diff(damages)) damages(3)];
            area = diff_prob * diff_damage';
            
            if abs(area) < 1e-6
                area = 0;
            end
                        
            % Area is value gained by reduction in flood damages
            flood_value(i) = area;
                    
        else
            
            flood_value(i) = 0;
            
        end
                
    end
    
    
    %% (4) FORMAT OUTPUT
    %  =================
    
    % Return as table
    es_water_flood = table(input_sbsn, flood_value, 'VariableNames', {'src_id', 'flood_value'});

end