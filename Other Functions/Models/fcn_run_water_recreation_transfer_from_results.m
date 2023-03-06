function water_rec_table = fcn_run_water_recreation_transfer_from_results(cell_info, elm_option_string, elm_ha_option, water_rec_results, water_rec_cell2sbsn, rec_proportion)
    
    % (0) Set up
    % ==========
    % Get water non use results for this ELM option
    % ---------------------------------------------
    water_rec_results_option = water_rec_results.(elm_option_string);
    
    % Calculate indicators and ordering indexes
    % -----------------------------------------
    % Subbasin id in cell2sbsn lookup table
    [cell2sbsn_ind, cell2sbsn_idx] = ismember(water_rec_cell2sbsn.subctch_id, water_rec_results_option.subctch_id); 
	
	% Non-use water quality assumption: take a proportion of full value
    % -----------------------------------------------------------------
    rec_value_20 = rec_proportion * water_rec_results_option.rec_value_20;
    rec_value_30 = rec_proportion * water_rec_results_option.rec_value_30;
    rec_value_40 = rec_proportion * water_rec_results_option.rec_value_40;
    rec_value_50 = rec_proportion * water_rec_results_option.rec_value_50;
    
    % (1) Main calculations
    % =====================
    % (a) Convert option results from representative cell to per ha
    % -------------------------------------------------------------
    % Water quality non-use
    rec_value_20_perha = rec_value_20 ./ water_rec_results_option.hectares;
    rec_value_30_perha = rec_value_30 ./ water_rec_results_option.hectares;
    rec_value_40_perha = rec_value_40 ./ water_rec_results_option.hectares;
    rec_value_50_perha = rec_value_50 ./ water_rec_results_option.hectares;
    
    % (b) Align subbasin per ha water flood/quant to cells 2 subbasins lookup
    % -----------------------------------------------------------------------
    % Multiply by proportion of cell in subbasin
    water_chg_cells  = water_rec_cell2sbsn(cell2sbsn_ind, :);
    
    % Non use value
    rec_value_20_perha_in_cell = rec_value_20_perha(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    rec_value_30_perha_in_cell = rec_value_30_perha(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    rec_value_40_perha_in_cell = rec_value_40_perha(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
    rec_value_50_perha_in_cell = rec_value_50_perha(cell2sbsn_idx(cell2sbsn_ind), :) .* water_chg_cells.proportion;
   
    % (c) Calculate per ha water flood/quant for each cell
    % ----------------------------------------------------
    [water_chg_cellid, ~, cellid_idx] = unique(water_chg_cells.new2kid);
    
    % Non use value
    rec_value_20_cell = accumarray(cellid_idx, rec_value_20_perha_in_cell);
    rec_value_30_cell = accumarray(cellid_idx, rec_value_30_perha_in_cell);
    rec_value_40_cell = accumarray(cellid_idx, rec_value_40_perha_in_cell);
    rec_value_50_cell = accumarray(cellid_idx, rec_value_50_perha_in_cell);
       
    % (e) Calculate total water flood/quant for each cell with given 
    % landcover change
    % --------------------------------------------------------------
    % Preallocate table to store results
    water_rec_table = array2table(zeros(cell_info.ncells, 1 + 4), ...
                                      'VariableNames', ...
                                      {'new2kid', ...
                                       'rec_value_20', ...
                                       'rec_value_30', ...
                                       'rec_value_40', ...
                                       'rec_value_50'});
    water_rec_table.new2kid = cell_info.new2kid;    % Fill in cell ids
    
    % Calculate indicator and index of all cell ids to changed cells
    [cell2chgcell_ind, cell2chgcell_idx] = ismember(cell_info.new2kid, water_chg_cellid);
    
    % Calculate value for each cell with given landcover change
    % Recreation value
    water_rec_table.rec_value_20(cell2chgcell_ind) = rec_value_20_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_rec_table.rec_value_30(cell2chgcell_ind) = rec_value_30_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_rec_table.rec_value_40(cell2chgcell_ind) = rec_value_40_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_rec_table.rec_value_50(cell2chgcell_ind) = rec_value_50_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
 end