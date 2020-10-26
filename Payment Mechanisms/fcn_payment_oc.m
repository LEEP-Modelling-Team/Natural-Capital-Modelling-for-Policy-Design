function [opt_cells, option_choice, farm_payment] = fcn_payment_oc(budget, margin, cell_ids, costs, benefit_cost_ratios)
    
    %% (0) Set up
    %  ==========
    
    % (a) Adjust costs and benefit:cost ratio by margin
    % -------------------------------------------------
    costs = margin * costs;
    benefit_cost_ratios = benefit_cost_ratios ./ margin;
    
    % (b) Calculate best individual arable and farm grass options by
    % benefit:cost ratio
    % --------------------------------------------------------------
    % NB. assumes specific ordering of ELM options
    % Arable reversion options (options 1, 3, 5, 7)
    [option_arable_bcr, option_arable_ind] = max(benefit_cost_ratios(:,[1,3,5,7]), [], 2);
    option_arable_ind = 2 * (option_arable_ind - 1) + 1; % convert [1,2,3,4] to [1,3,5,7]
    
    % Destocking (farm grass) options (options 2, 4, 6, 8)
    [option_grass_bcr, option_grass_ind] = max(benefit_cost_ratios(:,[2,4,6,8]), [], 2);
    option_grass_ind = 2 * option_grass_ind; % convert [1,2,3,4] to [2,4,6,8]
    
    % (c) Get opportunity costs for best individual arable and farm grass
    % options
    % -------------------------------------------------------------------
    option_arable_oc = 0;
    for k = [1,3,5,7]
        option_arable_oc = option_arable_oc + costs(:, k) .* (option_arable_ind == k);
    end
    option_grass_oc = 0;
    for k = [2,4,6,8]
        option_grass_oc = option_grass_oc + costs(:, k) .* (option_grass_ind == k);
    end
    
    %% (1) Choose farmers
    %  ==================
    
    % (a) Set up farm data table
    % --------------------------
    % - 2km cell ids
    % - costs
    % - benefit:cost ratio
    % - option number (1-16)
    
    % Set up array for best individual arable and farm grass options 
    farm_data_arable = [cell_ids, option_arable_oc, option_arable_bcr, option_arable_ind];
    farm_data_grass = [cell_ids, option_grass_oc, option_grass_bcr, option_grass_ind];
    
    % Combine into a single table with duplicate farms
    colnames = {'new2kid', 'costs', 'bcr', 'option'};
    farm_data = array2table([farm_data_arable; farm_data_grass], 'VariableNames', colnames);
    
    % Take out cells with no farms (i.e. no costs)
    farm_index = farm_data.costs > 0;
    farm_data   = farm_data(farm_index, :);

    % Sort farm table by decreasing benefit:cost ratios
    farm_data = sortrows(farm_data, 3, 'descend', 'MissingPlacement', 'last');

    % Calculate cumulative costs (used to spend budget)
    cum_spend = cumsum(farm_data.costs);
    
    % (b) Choose farmers to spend budget
    % ----------------------------------
    
    % Initialize
    final_spend = 0;
    pct_adjust = 1;
    maxit = 1000;
    count = 1;
    
    % Matrix to convert individual option number to combination option
    % number
    option_to_combo = [0 9 0 10 0 0 0 0; ...
                       9 0 11 0 0 0 0 0; ...
                       0 11 0 12 0 0 0 0; ...
                       10 0 12 0 0 0 0 0; ...
                       0 0 0 0 0 13 0 14; ...
                       0 0 0 0 13 0 15 0; ...
                       0 0 0 0 0 15 0 16; ...
                       0 0 0 0 14 0 16 0];
    
    % while loop until we have overspend
    while final_spend < budget
        
        % Keep inflating budget by pct_adjust until we get overspend
        % ----------------------------------------------------------
        % Due to individual options turning into combinations, we initially
        % do not spend budget.
        % pct_adjust is incremented at end of while loop
        adjusted_budget = budget * pct_adjust;
        
        % Find number of cells needed to add up to £budget, and an
        % indicator variable of those rows in opt_data
        
        % Find rows of farm data that spend adjusted_budget
        % -------------------------------------------------
        chosen_ind = cum_spend < adjusted_budget;
        chosen_idx = sum(chosen_ind);
        chosen_ind(chosen_idx + 1) = true;
        farm_data_chosen = farm_data(chosen_ind, :);
        
        % Find cells chosen once and cells chosen twice
        % ---------------------------------------------
        % Number of times cell is chosen (2nd column of tabulate)
        chosen_cells_freq = tabulate(farm_data_chosen.new2kid);
        
        % Extract cells chosen once and twice
        chosen_once_cells   = chosen_cells_freq(chosen_cells_freq(:, 2) == 1, 1);
        chosen_twice_cells  = chosen_cells_freq(chosen_cells_freq(:, 2) == 2, 1);
        
        % Get indicator of those cells in farm_data_chosen table
        chosen_once_cells_ind = ismember(farm_data_chosen.new2kid, chosen_once_cells);
        chosen_twice_cells_ind = ismember(farm_data_chosen.new2kid, chosen_twice_cells);
        
        % Separate farm_data_chosen table into cells chosen once and twice
        farm_data_chosen_once = farm_data_chosen(chosen_once_cells_ind, :);
        farm_data_chosen_twice = farm_data_chosen(chosen_twice_cells_ind, :);
        
        % For cells chosen twice, convert to combination if possible,
        % otherwise choose best of the two
        % -----------------------------------------------------------
        num_chosen_twice = length(chosen_twice_cells);
        if num_chosen_twice > 0
            % Set empty array to store results
            farm_data_combos = [];
            for i = 1:num_chosen_twice
                % Reduce farm_data_chosen_twice table to i-th cell
                cell_i_ind = (farm_data_chosen_twice.new2kid == chosen_twice_cells(i));
                farm_data_cell_i = farm_data_chosen_twice(cell_i_ind, :);
                
                % Get two option numbers for i-th cell
                two_options = farm_data_cell_i.option;
                
                % Use option_to_combo matrix to convert to combination
                % number
                combo = option_to_combo(two_options(1), two_options(2));
                
                % Two cases:
                if combo == 0
                    % Combination not possible, choose best option out of 
                    % two individual options and add to table
                    [~, max_idx] = max(farm_data_cell_i.bcr);
                    results_to_add = farm_data_cell_i(max_idx, :);
                else
                    % Combination possible
                    % Add correct combination info to table
                    [~, cell_idx] = ismember(chosen_twice_cells(i), cell_ids);
                    results_to_add = [chosen_twice_cells(i), ...
                                      costs(cell_idx, combo), ...
                                      benefit_cost_ratios(cell_idx, combo), ...
                                      combo];
                    results_to_add = array2table(results_to_add, 'VariableNames', colnames);
                end
                
                % Add results to farm_data_combos table
                farm_data_combos = [farm_data_combos; results_to_add];
            end
        end
        
        % Combine tables for cells chosen once and combinations, and re-sort
        % ------------------------------------------------------------------
        farm_data_combined = [farm_data_chosen_once; farm_data_combos];
        farm_data_combined = sortrows(farm_data_combined, 3, 'descend');
        
        % Calculate spend
        % ---------------
        % while loop will end if we have overspent
        final_spend = sum(farm_data_combined.costs);
        
        % Return error if we are stuck in while loop
        % ------------------------------------------
        if count > maxit
            error('Max iterations reached in opp_cost_benefit payment mechanism.')
        end
        
        % Increment counter and pct_adjust
        % --------------------------------
        count = count + 1;
        pct_adjust = pct_adjust + 0.01;     % probably a better way to do this
    end
    
    % (b) Reduce farmers to spend budget exactly
    % ------------------------------------------
    % We now have overspend, need to reduce set of chosen farmers and pay a
    % proportion of last farmer to get exact spend
    
    % Calculate cumulative costs (used to spend budget)
    cum_spend = cumsum(farm_data_combined.costs);
    
    % Find rows of farm data that spend budget
    chosen_ind = double(cum_spend < budget); % need double here as final farmer will be paid a proportion
    chosen_idx = sum(chosen_ind);
    chosen_ind(chosen_idx + 1) = 1;
    farm_data_final = farm_data_combined(chosen_ind == 1, :);
    
    % Calculate proportion of final cell to ensure spend is exactly budget
    proportions = ones(size(farm_data_final, 1), 1);
    farm_payment  = farm_data_final.costs;
    option_choice = farm_data_final.option; 
    
    final_proportion = (budget - cum_spend(chosen_idx)) / farm_payment(end);
    proportions(end) = final_proportion;
    farm_payment(end) = final_proportion * farm_payment(end);
        
    % Extract chosen cell ids
    opt_cells = [farm_data_final.new2kid, proportions];

end