function quantity_pollination = fcn_calc_quantity_pollination(start_year, end_year, num_extra_years, baseline, es_biodiversity_ucl)
    % Convert decadal biodiversity output into annual for baseline and
    % scenario
    baseline_pollinator_sr = [repmat(baseline.pollinator_sr_20, 1, 10) ...
                       repmat(baseline.pollinator_sr_30, 1, 10) ...
                       repmat(baseline.pollinator_sr_40, 1, 10) ...
                       repmat(baseline.pollinator_sr_50, 1, 10)];
    scenario_pollinator_sr = [repmat(es_biodiversity_ucl.pollinator_sr_20, 1, 10) ...
                       repmat(es_biodiversity_ucl.pollinator_sr_30, 1, 10) ...
                       repmat(es_biodiversity_ucl.pollinator_sr_40, 1, 10) ...
                       repmat(es_biodiversity_ucl.pollinator_sr_50, 1, 10)];
    
    % Repeat 40th year for num_extra_years (works with 0 too)
    baseline_pollinator_sr = [baseline_pollinator_sr, repmat(baseline_pollinator_sr(:, 40), 1, num_extra_years)];
    scenario_pollinator_sr = [scenario_pollinator_sr, repmat(scenario_pollinator_sr(:, 40), 1, num_extra_years)];
    
    % Calculate difference between scenario and baseline
    diff_pollinator_sr = scenario_pollinator_sr(:, start_year:end_year) - baseline_pollinator_sr(:, start_year:end_year);
    
%     % Set negative differences to zero
%     diff_pollinator_sr(diff_pollinator_sr < 0) = 0;
    
    % Sum to get biodiversity quantity change
    quantity_pollination = nansum(diff_pollinator_sr, 2);
end