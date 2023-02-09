function [chosen_option_ind, ...
		  chosen_option_idx, ...
		  option_choice, ...
		  opt_cells, ...
		  scheme_year, ...
		  flat_rates, ...
		  farm_payment] = fcn_run_payment_mechanisms(payment_mechanism_string, ...
													 budget, ...
													 markup, ...
													 elm_options, ...
													 year, ...
													 scheme_year, ...
													 cell_ids, ...
													 elm_ha, ...
													 benefits, ...
													 costs, ...
													 env_outs, ...
													 es_outs, ...
                                                     remove_nu_habitat, ...
                                                     carbon_price_string)

    %% (0) Set up
    %  ==========
    % Number of ELM options
    num_elm_options = length(elm_options);
    
    % Number of 2km grid cells
    num_cells = length(cell_ids);
    
    % Set flat rates and farm payment to empty matrices
    flat_rates = [];
    farm_payment = [];
    
    % Convert budget into single character (e.g. 1 billion = '1')
    budget_char = num2str(budget);
	budget_char = budget_char(1);
    
    % Discount the budget based on year
%     budget = budget / ((1 + 0.035)^(year - 1));

    % Construct matrices for selected elm_options in this year
    % --------------------------------------------------------
    % ELM hectares, opportunity cost benefits, benefit cost ratios
    % Farmers compare across these when deciding which ELM option to do
    elm_ha_year              = nan(num_cells, num_elm_options);
    benefits_year            = nan(num_cells, num_elm_options);
    costs_year               = nan(num_cells, num_elm_options);

    % !!! Always use year 1 costs, benefits, etc...
    for k = 1:num_elm_options
        elm_ha_year(:, k)    = elm_ha.(elm_options{k});
        benefits_year(:, k)  = benefits.(elm_options{k})(:, 1);
        costs_year(:, k)     = costs.(elm_options{k})(:, 1);
        env_outs_year.(elm_options{k}) = env_outs.(elm_options{k})(:, :, 1);
        es_outs_year.(elm_options{k})  = es_outs.(elm_options{k})(:, :, 1);
    end
    
    % Use scheme year to extract eligible farmers this year
    % -----------------------------------------------------
    % Indicator for farmers eligible this year
    scheme_year_ind = (scheme_year == year);
    
    % Extract relevant rows from above arrays/structures
    elm_ha_year = elm_ha_year(scheme_year_ind, :);
    benefits_year = benefits_year(scheme_year_ind, :);
    costs_year = costs_year(scheme_year_ind, :);
    for k = 1:num_elm_options
        env_outs_year.(elm_options{k}) = env_outs_year.(elm_options{k})(scheme_year_ind, :);
        es_outs_year.(elm_options{k})  = es_outs_year.(elm_options{k})(scheme_year_ind, :);
    end

    % Also extract cell ids for eligible farmers
    cell_ids_year = cell_ids(scheme_year_ind);

    %% (2) Run payment mechanism
    %  =========================
    switch payment_mechanism_string
        case 'oc'
            [opt_cells, option_choice, farm_payment] = fcn_payment_oc_mcknap(budget, markup, cell_ids_year, costs_year, benefits_year);
            
%             % Old code: before mcknap optimiser (comment out)
%             [opt_cells, option_choice, farm_payment] = fcn_payment_oc(budget, markup, cell_ids_year, costs_year, benefit_cost_ratios_year);
		case 'oc_shared'
            [opt_cells, option_choice, farm_payment] = fcn_payment_oc_shared(budget, markup, cell_ids_year, elm_ha_year, costs_year, benefits_year);
        case 'fr_act'
            % Load prices (generated in script3a_run_search_for_prices)
            if remove_nu_habitat
                load(['./Script 3 (Optimised Prices)/prices_fr_act_', budget_char, '_lp_no_nu_habitat_', carbon_price_string, '.mat'], 'prices')
            else
                load(['./Script 3 (Optimised Prices)/prices_fr_act_', budget_char, '_lp_', carbon_price_string, '.mat'], 'prices')
            end
            flat_rates = prices;
            % Discount prices based on scheme year
%             flat_rates = flat_rates / ((1 + 0.035)^(year - 1));
			
            % Apply prices to get farmer uptake
            [change_ind, option_idx, farm_payment] = fcn_get_farmer_uptake_logic_fr_act(flat_rates, elm_ha_year, markup * costs_year, elm_options);
            any_option_ind = any(change_ind, 2);
            opt_cells = cell_ids_year(any_option_ind);
            opt_cells = [opt_cells, ones(length(opt_cells), 1)]; % Using whole cells so add column of proportions with 1 in 
            option_choice = option_idx(any_option_ind) - 1;
            case 'fr_act_pct'
            % Load prices (generated in script3a_run_search_for_prices)
            if remove_nu_habitat
                load(['./Script 3 (Optimised Prices)/prices_fr_act_pct_', budget_char, '_search_no_nu_habitat_', carbon_price_string, '.mat'], 'prices')
            else
                load(['./Script 3 (Optimised Prices)/prices_fr_act_pct_', budget_char, '_search_', carbon_price_string, '.mat'], 'prices')
            end
            flat_rates = prices;
            % Discount prices based on scheme year
%             flat_rates = flat_rates / ((1 + 0.035)^(year - 1));
			
            % Apply prices to get farmer uptake
            [change_ind, option_idx, farm_payment] = fcn_get_farmer_uptake_logic_fr_act(flat_rates, elm_ha_year, markup * costs_year, elm_options);
            any_option_ind = any(change_ind, 2);
            opt_cells = cell_ids_year(any_option_ind);
            opt_cells = [opt_cells, ones(length(opt_cells), 1)]; % Using whole cells so add column of proportions with 1 in 
            option_choice = option_idx(any_option_ind) - 1;
        case 'fr_act_shared'
            % Load prices (generated in script3a_run_search_for_prices)
            if remove_nu_habitat
                load(['./Script 3 (Optimised Prices)/prices_fr_act_shared_', budget_char, '_search_no_nu_habitat_', carbon_price_string, '.mat'], 'prices')
            else
                load(['./Script 3 (Optimised Prices)/prices_fr_act_shared_', budget_char, '_search_', carbon_price_string, '.mat'], 'prices')
            end
            flat_rates = prices;
            % Discount prices based on scheme year
%             flat_rates = flat_rates / ((1 + 0.035)^(year - 1));
			
            [opt_cells, option_choice, farm_payment] = fcn_get_farmer_uptake_logic_fr_act_shared(flat_rates, budget, cell_ids_year, elm_ha_year, markup * costs_year, elm_options);
            
%             [opt_cells, option_choice, farm_payment, flat_rates] = fcn_payment_fr_act_shared(budget, markup, cell_ids_year, elm_ha_year, costs_year, benefits_year, elm_options);
        case 'fr_env'
			% Load prices (generated in script3a_run_search_for_prices)
            if remove_nu_habitat
                load(['./Script 3 (Optimised Prices)/prices_fr_env_', budget_char, '_search_no_nu_habitat_', carbon_price_string, '.mat'], 'prices')
            else
                load(['./Script 3 (Optimised Prices)/prices_fr_env_', budget_char, '_search_' carbon_price_string, '.mat'], 'prices')
            end
            flat_rates = prices;
            % Discount prices based on scheme year
%             flat_rates = flat_rates / ((1 + 0.035)^(year - 1));
			
			% Apply prices to get farmer uptake
			[uptake_logic, option_idx] = fcn_get_farmer_uptake_logic_fr_env_es(flat_rates, env_outs_year, markup * costs_year, elm_options);
			any_option_ind = any(uptake_logic, 2);
			opt_cells = cell_ids_year(any_option_ind);
			opt_cells = [opt_cells, ones(length(opt_cells), 1)];	% Using whole cells so add column of proportions with 1 in 
			option_choice = option_idx(any_option_ind) - 1;
        case 'fr_es'
			% Load prices (generated in script3a_run_search_for_prices)
            if remove_nu_habitat
                load(['./Script 3 (Optimised Prices)/prices_fr_es_', budget_char, '_search_no_nu_habitat_', carbon_price_string, '.mat'], 'prices')
            else
                load(['./Script 3 (Optimised Prices)/prices_fr_es_', budget_char, '_search_', carbon_price_string, '.mat'], 'prices')
            end
            flat_rates = prices;
            % Discount prices based on scheme year
%             flat_rates = flat_rates / ((1 + 0.035)^(year - 1));
			
			% Apply prices to get farmer uptake
			[uptake_logic, option_idx] = fcn_get_farmer_uptake_logic_fr_env_es(flat_rates, es_outs_year, markup * costs_year, elm_options);
			any_option_ind = any(uptake_logic, 2);
			opt_cells = cell_ids_year(any_option_ind);
			opt_cells = [opt_cells, ones(length(opt_cells), 1)];	% Using whole cells so add column of proportions with 1 in 
			option_choice = option_idx(any_option_ind) - 1;
        otherwise
            error('Payment mechanism not found.')
    end
    
    %% (3) Process output
    %  ==================
    % Find index of chosen cells in full cell list
    % --------------------------------------------
    for k = 1:num_elm_options
        [chosen_option_ind.(elm_options{k}), chosen_option_idx.(elm_options{k})] = ismember(cell_ids, opt_cells(option_choice == k, 1));
        chosen_option_idx.(elm_options{k}) = chosen_option_idx.(elm_options{k})(chosen_option_ind.(elm_options{k}));
    end

    % Update scheme years
    % -------------------
    % Cells not chosen can be considered next year
    % Cells chosen can be considered again in 5 years
    opt_cells_ind = ismember(cell_ids, opt_cells(:, 1));
    scheme_year((~opt_cells_ind) & (scheme_year == year)) = year + 1;
    scheme_year(opt_cells_ind) = year + 5;

end