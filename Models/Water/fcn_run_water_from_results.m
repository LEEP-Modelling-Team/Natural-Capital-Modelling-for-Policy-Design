function water_table = fcn_run_water_from_results(cell_info, elm_option_string, elm_ha_option, water_results, water_results_baseline, water_colnames, water_cell2sbsn, non_use_proportion)
    
    %% (0) Set up
    %  ==========
    % Get water results for this ELM option
    % -------------------------------------
    water_results_option = water_results.(elm_option_string);
    
    % Calculate indicators and ordering indexes
    % -----------------------------------------
    % Subbasin id in baseline results   
    [~, sbsn_baseline_idx] = ismember(water_results_option.src_id, water_results_baseline.src_id);
    
    % Desired column name order in option and baseline results
    [~, col_idx] = ismember(water_colnames, water_results_option.Properties.VariableNames);
    [~, col_baseline_idx] = ismember(water_colnames, water_results_baseline.Properties.VariableNames);
    
    % Subbasin id in cell2sbsn lookup table
    [cell2sbsn_ind, cell2sbsn_idx] = ismember(water_cell2sbsn.src_id, water_results_option.src_id); 
	
	% Non-use water quality assumption: take a proportion of full value
    non_use_value_20 = non_use_proportion * water_results_option.non_use_value_20;
    non_use_value_30 = non_use_proportion * water_results_option.non_use_value_30;
    non_use_value_40 = non_use_proportion * water_results_option.non_use_value_40;
    non_use_value_50 = non_use_proportion * water_results_option.non_use_value_50;
    
    %% (1) Main calculations
    %  =====================
    % (a) Subtract option results from baseline results
    % -------------------------------------------------
    % Subtract from baseline as decrease in water quantities are beneficial
    water_results_chg = table2array(water_results_baseline(sbsn_baseline_idx, col_baseline_idx)) - table2array(water_results_option(:, col_idx));
    
    % (b) Convert option results from representative cell to per ha
    % -------------------------------------------------------------
    % Water quality non-use
    water_non_use_value_perha_20 = non_use_value_20 ./ water_results_option.hectares;
    water_non_use_value_perha_30 = non_use_value_30 ./ water_results_option.hectares;
    water_non_use_value_perha_40 = non_use_value_40 ./ water_results_option.hectares;
    water_non_use_value_perha_50 = non_use_value_50 ./ water_results_option.hectares;
    
    % Water quantities
    water_quantities_perha = water_results_chg ./ water_results_option.hectares;
    
    % (c) Align subbasin per ha water flood/quant to cells 2 subbasins lookup
    % -----------------------------------------------------------------------
    water_chg_cells  = water_cell2sbsn(cell2sbsn_ind, :);
    % Multiply by proportion of cell in subbasin
    water_non_use_value_perha_20_in_cell = water_non_use_value_perha_20(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    water_non_use_value_perha_30_in_cell = water_non_use_value_perha_30(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    water_non_use_value_perha_40_in_cell = water_non_use_value_perha_40(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    water_non_use_value_perha_50_in_cell = water_non_use_value_perha_50(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    water_quantities_perha_in_cell = water_quantities_perha(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    
    % (d) Calculate per ha water flood/quant for each cell
    % ----------------------------------------------------
    [water_chg_cellid, ~, cellid_idx] = unique(water_chg_cells.new2kid);
    water_non_use_value_20_cell = accumarray(cellid_idx, water_non_use_value_perha_20_in_cell);
    water_non_use_value_30_cell = accumarray(cellid_idx, water_non_use_value_perha_30_in_cell);
    water_non_use_value_40_cell = accumarray(cellid_idx, water_non_use_value_perha_40_in_cell);
    water_non_use_value_50_cell = accumarray(cellid_idx, water_non_use_value_perha_50_in_cell);
    for jj = size(water_quantities_perha_in_cell,2):-1:1 % Count backwards for dynamic preallocation
        water_quantities_cell(:,jj) = accumarray(cellid_idx, water_quantities_perha_in_cell(:,jj));
    end
    
    % (e) Calculate total water flood/quant for each cell with given 
    % landcover change
    % --------------------------------------------------------------
    % Preallocate table to store results
    water_table = array2table(zeros(cell_info.ncells, 5 + length(water_colnames)), ...
                              'VariableNames', ...
                              [{'new2kid', ...
                                'non_use_value_20', ...
                                'non_use_value_30', ...
                                'non_use_value_40', ...
                                'non_use_value_50'}, ...
                               water_colnames]);
    water_table.new2kid = cell_info.new2kid;    % Fill in cell ids
    
    % Calculate indicator and index of all cell ids to changed cells
    [cell2chgcell_ind, cell2chgcell_idx] = ismember(cell_info.new2kid, water_chg_cellid);
    
    % Calculate water quality non-use value for each cell with given landcover change
    water_table.non_use_value_20(cell2chgcell_ind) = water_non_use_value_20_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_table.non_use_value_30(cell2chgcell_ind) = water_non_use_value_30_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_table.non_use_value_40(cell2chgcell_ind) = water_non_use_value_40_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_table.non_use_value_50(cell2chgcell_ind) = water_non_use_value_50_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    
    % Calculate water quantities for each cell with given landcover change
    water_table(cell2chgcell_ind, water_colnames) = array2table(water_quantities_cell(cell2chgcell_idx(cell2chgcell_ind), :) .* elm_ha_option(cell2chgcell_ind), 'VariableNames', water_colnames);

end