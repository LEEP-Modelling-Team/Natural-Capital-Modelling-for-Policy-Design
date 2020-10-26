function es_non_use_pollination = fcn_run_non_use_pollination(non_use_pollination_data_folder, es_biodiversity_ucl, climate_scen_string, wtp_assumption, pop_assumption, non_use_proportion)
    % fcn_run_non_use_pollination.m
    % =====================
    % Author: Nathan Owen, Mattia Mancini, Brett Day
    % Last modified: 11/11/2019
    % Inputs:
    % -
    % Outputs:
    % -
    
    %% (1) Set up
    %  ==========
    % (a) Data files 
    % --------------
    NEVO_NonUsePollination_data_mat = strcat(non_use_pollination_data_folder, 'NEVO_NonUsePollination_data.mat');
    load(NEVO_NonUsePollination_data_mat, 'NonUsePollination');
    
    % (b) Choose climate mask and set up decade info
    % ----------------------------------------------
    switch climate_scen_string
        case 'current'
            ndecades = 1;
            decade_string = {''};
            baseline_wtp = NonUsePollination.baseline_wtp_now;
        case 'rcp60'
            ndecades = 4;
            decade_string = {'_20','_30','_40','_50'};
            baseline_wtp_20 = NonUsePollination.baseline_wtp_rcp60_20;
            baseline_wtp_30 = NonUsePollination.baseline_wtp_rcp60_30;
            baseline_wtp_40 = NonUsePollination.baseline_wtp_rcp60_40;
            baseline_wtp_50 = NonUsePollination.baseline_wtp_rcp60_50;
        case 'rcp85'
            ndecades = 4;
            decade_string = {'_20','_30','_40','_50'};
            baseline_wtp_20 = NonUsePollination.baseline_wtp_rcp85_20;
            baseline_wtp_30 = NonUsePollination.baseline_wtp_rcp85_30;
            baseline_wtp_40 = NonUsePollination.baseline_wtp_rcp85_40;
            baseline_wtp_50 = NonUsePollination.baseline_wtp_rcp85_50;
        otherwise
            error('Please choose a climate scenario from ''current'', ''rcp60'' or ''rcp85''.')
    end
    
    % (c) Deal with WTP and population assumptions
    % --------------------------------------------
    % WTP
    switch wtp_assumption
        case 'low'
            wtp_individual = 0.84;
        case 'high'
            wtp_individual = 1.63;
        otherwise
            error('Please choose WTP assumption from ''low'' (£0.84) or ''high'' (£1.63).')
    end
    
    % Population
    switch pop_assumption
        case 'low'
            pop_proportion = 0.14;
        case 'high'
            pop_proportion = 1;
        otherwise
            error('Please choose population assumption from ''low'' (14% of adult population) or ''high'' (100% of adult population).')
    end
    
    % Baseline WTP: depends on WTP and population assumptions
    assumptions_string = [wtp_assumption, '_', pop_assumption];
    switch climate_scen_string
        case 'current'
            baseline_wtp = baseline_wtp.(assumptions_string);
        case {'rcp60', 'rcp85'}
            baseline_wtp_20 = baseline_wtp_20.(assumptions_string);
            baseline_wtp_30 = baseline_wtp_30.(assumptions_string);
            baseline_wtp_40 = baseline_wtp_40.(assumptions_string);
            baseline_wtp_50 = baseline_wtp_50.(assumptions_string);
    end
    
    %% (2) Reduce to inputted 2km cells
    %  ================================
    % For inputted 2km grid cells, extract rows of relevant tables and
    % arrays in NonUsePollination structure
    [input_cells_ind, input_cell_idx] = ismember(es_biodiversity_ucl.new2kid, NonUsePollination.Data_cells.new2kid);
    input_cell_idx = input_cell_idx(input_cells_ind);
    
    % Data cells
    data_cells = NonUsePollination.Data_cells(input_cell_idx, :);
    
    % wtp levels
    switch climate_scen_string
        case 'current'
            baseline_wtp = baseline_wtp(input_cell_idx, :);
        case {'rcp60', 'rcp85'}
            baseline_wtp_20 = baseline_wtp_20(input_cell_idx, :);
            baseline_wtp_30 = baseline_wtp_30(input_cell_idx, :);
            baseline_wtp_40 = baseline_wtp_40(input_cell_idx, :);
            baseline_wtp_50 = baseline_wtp_50(input_cell_idx, :);
    end
    
    %% (3) Calculate non use pollination output
    %  ========================================
    % (a) Create es_pollination structure with new2kid cell ids
    % ---------------------------------------------------------
    es_non_use_pollination.new2kid = es_biodiversity_ucl.new2kid;
    
    % (b) Loop over decades to calculate non use pollination value change 
    % -------------------------------------------------------------------
    for decade = 1:ndecades
        % (a) Extract information for this decade (or current period)
        % -----------------------------------------------------------
        % Pollinator species richness from es_biodiversity_ucl
        pollinator_sr_decade = eval(['es_biodiversity_ucl.pollinator_sr', decade_string{decade}]);
        
        % Pollinator species richness threshold
        baseline_wtp_decade = eval(['baseline_wtp', decade_string{decade}]);
                
        % (b) Calculate pollinator percentage in scenario
        % -----------------------------------------------
        poll_percent_decade = 100 * (pollinator_sr_decade / 105);
        poll_percent_decade(poll_percent_decade> 100) = 100;
        
        % (c) Main calculations
        % ---------------------
        adj_factor = 0.39 * wtp_individual * pop_proportion * data_cells.pop;
        scenario_wtp_decade = adj_factor .* poll_percent_decade;
        change_wtp_decade = scenario_wtp_decade - baseline_wtp_decade;
        
        % Take proportion of non use value
        baseline_wtp_decade = non_use_proportion * baseline_wtp_decade;
        scenario_wtp_decade = non_use_proportion * scenario_wtp_decade;
        change_wtp_decade = non_use_proportion * change_wtp_decade;
        
        % Add to es_non_use_pollination structure
        es_non_use_pollination.(['wtp_baseline', decade_string{decade}]) = baseline_wtp_decade;
        es_non_use_pollination.(['wtp_scenario', decade_string{decade}]) = scenario_wtp_decade;
        es_non_use_pollination.(['wtp_change', decade_string{decade}]) = change_wtp_decade;
    end
    
    % Convert structure to table for output
	es_non_use_pollination = struct2table(es_non_use_pollination);
end

