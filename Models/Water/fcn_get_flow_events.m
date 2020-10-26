function [day_seq_events, flow_events] = fcn_get_flow_events(day_seq, flow, thresh, event_parameter)

    if event_parameter ~= 0
        % Find when flow is above threshold and number of times this happens
        ind_thresh = flow > thresh;
        num_exceed = sum(ind_thresh);

        % Find days where flow is above threshold
        day_seq_thresh = day_seq(ind_thresh);

        % Extract flows above threshold
        flow_thresh = flow(ind_thresh);

        % Calculate first differences of day_seq_thresh
        % This is the number of days between exceedances
        inter_exceedance = diff(day_seq_thresh);
    %     disp(inter_exceedance)

        % Calculate clusters as zeros
        clusters = max(inter_exceedance - event_parameter, zeros(1, num_exceed - 1));
    %     disp(clusters)

        % Loop to pick out exceedances which form part of a cluster
        % (leave single exceedances alone)
        num_zeros = sum(clusters == 0); % max number of clusters
        cluster_group = cell(num_zeros, 1);

        group_num = 1;

        for i = 1:(num_exceed - 1)

            if clusters(i) == 0
                if i == (num_exceed - 1)
                    cluster_group{group_num} = [cluster_group{group_num} day_seq_thresh(i) day_seq_thresh(i + 1)];
                else
                    if clusters(i + 1) == 0
                        cluster_group{group_num} = [cluster_group{group_num} day_seq_thresh(i)];
                    else
                        cluster_group{group_num} = [cluster_group{group_num} day_seq_thresh(i) day_seq_thresh(i + 1)];
                        group_num = group_num + 1;
                    end
                end
            end

        end

        % Delete empty groups
        cluster_group = cluster_group(~cellfun('isempty', cluster_group));
        num_groups = size(cluster_group, 1);

    %     for i = 1:num_groups
    %         disp(cluster_group{i})
    %     end

        % Refine flow_exceed to flow_events
        day_seq_events = day_seq_thresh;
        flow_events = flow_thresh;

        for i = 1:num_groups

            % Find indices of this groups days in full list of days
            [ind, ~] = ismember(day_seq_events, cluster_group{i});
            idx = find(ind);

            % Find maximium flow in this group
            [~, max_idx] = max(flow_events(idx)); % what if equal maximums??

            % Refine flow_events by discarding all other flows and days in this group
            ind(idx(max_idx)) = 0;
            flow_events = flow_events(~ind);
            day_seq_events = day_seq_events(~ind);

        end
    else
        ind_thresh = flow > thresh;
        day_seq_events = day_seq(ind_thresh);
        flow_events = flow(ind_thresh);
    end
    

%     disp([day_seq_thresh; flow_events])

end