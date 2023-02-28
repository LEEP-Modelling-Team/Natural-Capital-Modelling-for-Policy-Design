function water_non_use_table = fcn_run_water_non_use_transfer_from_results(cell_info, elm_option_string, elm_ha_option, water_non_use_results, water_non_use_cell2sbsn, non_use_proportion)
    
    % (0) Set up
    % ==========
    % Get water non use results for this ELM option
    % ---------------------------------------------
    water_non_use_results_option = water_non_use_results.(elm_option_string);
    
    % Calculate indicators and ordering indexes
    % -----------------------------------------
    % Subbasin id in cell2sbsn lookup table
    [cell2sbsn_ind, cell2sbsn_idx] = ismember(water_non_use_cell2sbsn.subctch_id, water_non_use_results_option.subctch_id); 
	
	% Non-use water quality assumption: take a proportion of full value
    % -----------------------------------------------------------------
    non_use_value_20 = non_use_proportion * water_non_use_results_option.non_use_value_20;
    non_use_value_30 = non_use_proportion * water_non_use_results_option.non_use_value_30;
    non_use_value_40 = non_use_proportion * water_non_use_results_option.non_use_value_40;
    non_use_value_50 = non_use_proportion * water_non_use_results_option.non_use_value_50;
    
    % (1) Main calculations
    % =====================
    % (a) Convert option results from representative cell to per ha
    % -------------------------------------------------------------
    % Water quality non-use
    non_use_value_20_perha = non_use_value_20 ./ water_non_use_results_option.hectares;
    non_use_value_30_perha = non_use_value_30 ./ water_non_use_results_option.hectares;
    non_use_value_40_perha = non_use_value_40 ./ water_non_use_results_option.hectares;
    non_use_value_50_perha = non_use_value_50 ./ water_non_use_results_option.hectares;
    
    % (b) Align subbasin per ha water flood/quant to cells 2 subbasins lookup
    % -----------------------------------------------------------------------
    % Multiply by proportion of cell in subbasin
    water_chg_cells  = water_non_use_cell2sbsn(cell2sbsn_ind, :);
    
    % Non use value
    non_use_value_20_perha_in_cell = non_use_value_20_perha(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    non_use_value_30_perha_in_cell = non_use_value_30_perha(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    non_use_value_40_perha_in_cell = non_use_value_40_perha(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    non_use_value_50_perha_in_cell = non_use_value_50_perha(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
   
    % (c) Calculate per ha water flood/quant for each cell
    % ----------------------------------------------------
    [water_chg_cellid, ~, cellid_idx] = unique(water_chg_cells.new2kid);
    
    % Non use value
    non_use_value_20_cell = accumarray(cellid_idx, non_use_value_20_perha_in_cell);
    non_use_value_30_cell = accumarray(cellid_idx, non_use_value_30_perha_in_cell);
    non_use_value_40_cell = accumarray(cellid_idx, non_use_value_40_perha_in_cell);
    non_use_value_50_cell = accumarray(cellid_idx, non_use_value_50_perha_in_cell);
       
    % (e) Calculate total water flood/quant for each cell with given 
    % landcover change
    % --------------------------------------------------------------
    % Preallocate table to store results
%     water_non_use_table = array2table(zeros(cell_info.ncells, 1 + 4), ...
%                                       'VariableNames', ...
%                                       {'new2kid', ...
%                                        'non_use_value_20', ...
%                                        'non_use_value_30', ...
%                                        'non_use_value_40', ...
%                                        'non_use_value_50'});
                                   
   water_non_use_table = array2table(zeros(cell_info.ncells, 1 + 4), ...
                                      'VariableNames', ...
                                      {'new2kid', ...
                                       'non_use_value_20', ...
                                       'non_use_value_30', ...
                                       'non_use_value_40', ...
                                       'non_use_value_50'});
    water_non_use_table.new2kid = cell_info.new2kid;    % Fill in cell ids
    
    % Calculate indicator and index of all cell ids to changed cells
    [cell2chgcell_ind, cell2chgcell_idx] = ismember(cell_info.new2kid, water_chg_cellid);
    
    % Calculate value for each cell with given landcover change
    % Non use value
    water_non_use_table.non_use_value_20(cell2chgcell_ind) = non_use_value_20_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_non_use_table.non_use_value_30(cell2chgcell_ind) = non_use_value_30_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_non_use_table.non_use_value_40(cell2chgcell_ind) = non_use_value_40_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_non_use_table.non_use_value_50(cell2chgcell_ind) = non_use_value_50_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
 end