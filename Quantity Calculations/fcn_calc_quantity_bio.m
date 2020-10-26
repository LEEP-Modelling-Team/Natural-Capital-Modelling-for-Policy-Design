function quantity_bio = fcn_calc_quantity_bio(start_year, end_year, num_extra_years, baseline, es_biodiversity_jncc)

    % Convert decadal biodiversity output into annual for baseline and
    % scenario
    baseline_sr_100 = [repmat(baseline.sr_100_20, 1, 10) ...
                       repmat(baseline.sr_100_30, 1, 10) ...
                       repmat(baseline.sr_100_40, 1, 10) ...
                       repmat(baseline.sr_100_50, 1, 10)];
    scenario_sr_100 = [repmat(es_biodiversity_jncc.sr_100_20, 1, 10) ...
                       repmat(es_biodiversity_jncc.sr_100_30, 1, 10) ...
                       repmat(es_biodiversity_jncc.sr_100_40, 1, 10) ...
                       repmat(es_biodiversity_jncc.sr_100_50, 1, 10)];
    
    % Repeat 40th year for num_extra_years (works with 0 too)
    baseline_sr_100 = [baseline_sr_100, repmat(baseline_sr_100(:, 40), 1, num_extra_years)];
    scenario_sr_100 = [scenario_sr_100, repmat(scenario_sr_100(:, 40), 1, num_extra_years)];
    
    % Calculate difference between scenario and baseline
    diff_sr_100 = scenario_sr_100(:, start_year:end_year) - baseline_sr_100(:, start_year:end_year);
    
%     % Set negative differences to zero
%     diff_sr_100(diff_sr_100 < 0) = 0;
    
    % Sum to get biodiversity quantity change
    quantity_bio = nansum(diff_sr_100, 2);
    
end