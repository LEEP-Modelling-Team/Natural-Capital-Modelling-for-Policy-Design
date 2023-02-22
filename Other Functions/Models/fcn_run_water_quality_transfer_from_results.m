function water_quality_table = fcn_run_water_quality_transfer_from_results(cell_info, elm_option_string, elm_ha_option, water_quality_results, water_quality_cell2sbsn)
    
    %% (0) Set up
    %  ==========
    % Get water results for this ELM option
    % -------------------------------------
    water_quality_results_option = water_quality_results.(elm_option_string);
    
    % Calculate indicators and ordering indexes
    % -----------------------------------------
    % Subbasin id in cell2sbsn lookup table
    [cell2sbsn_ind, cell2sbsn_idx] = ismember(water_quality_cell2sbsn.subctch_id, water_quality_results_option.subctch_id); 
	
    %% (1) Main calculations
    %  =====================
    % (a) Calculate total change in N and P across abstraction points
    % ---------------------------------------------------------------
    % These are used in quantity calculations later
    chgtotn_20 = cellfun(@sum, water_quality_results_option.chgtotn_20);
    chgtotn_30 = cellfun(@sum, water_quality_results_option.chgtotn_30);
    chgtotn_40 = cellfun(@sum, water_quality_results_option.chgtotn_40);
    chgtotn_50 = cellfun(@sum, water_quality_results_option.chgtotn_50);
    chgtotp_20 = cellfun(@sum, water_quality_results_option.chgtotp_20);
    chgtotp_30 = cellfun(@sum, water_quality_results_option.chgtotp_30);
    chgtotp_40 = cellfun(@sum, water_quality_results_option.chgtotp_40);
    chgtotp_50 = cellfun(@sum, water_quality_results_option.chgtotp_50);
                     
    % (b) Convert option results from representative cell to per ha
    % -------------------------------------------------------------    
    % Water quality quantities
    chgtotn_20_perha = chgtotn_20 ./ water_quality_results_option.hectares;
    chgtotn_30_perha = chgtotn_30 ./ water_quality_results_option.hectares;
    chgtotn_40_perha = chgtotn_40 ./ water_quality_results_option.hectares;
    chgtotn_50_perha = chgtotn_50 ./ water_quality_results_option.hectares;
    chgtotp_20_perha = chgtotp_20 ./ water_quality_results_option.hectares;
    chgtotp_30_perha = chgtotp_30 ./ water_quality_results_option.hectares;
    chgtotp_40_perha = chgtotp_40 ./ water_quality_results_option.hectares;
    chgtotp_50_perha = chgtotp_50 ./ water_quality_results_option.hectares;
        
    % Water quality values
    totn_ann_20_perha = water_quality_results_option.wt_totn_20 ./ water_quality_results_option.hectares;
    totn_ann_30_perha = water_quality_results_option.wt_totn_30 ./ water_quality_results_option.hectares;
    totn_ann_40_perha = water_quality_results_option.wt_totn_40 ./ water_quality_results_option.hectares;
    totn_ann_50_perha = water_quality_results_option.wt_totn_50 ./ water_quality_results_option.hectares;
    totp_ann_20_perha = water_quality_results_option.wt_totp_20 ./ water_quality_results_option.hectares;
    totp_ann_30_perha = water_quality_results_option.wt_totp_30 ./ water_quality_results_option.hectares;
    totp_ann_40_perha = water_quality_results_option.wt_totp_40 ./ water_quality_results_option.hectares;
    totp_ann_50_perha = water_quality_results_option.wt_totp_50 ./ water_quality_results_option.hectares;
    
    % (c) Align subbasin per ha values to cells 2 subbasins lookup
    % ------------------------------------------------------------
    % Multiply by proportion of cell in subbasin
    water_chg_cells  = water_quality_cell2sbsn(cell2sbsn_ind, :);
    
    % Water quality quantities
    chgtotn_20_perha_in_cell = chgtotn_20_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    chgtotn_30_perha_in_cell = chgtotn_30_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    chgtotn_40_perha_in_cell = chgtotn_40_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    chgtotn_50_perha_in_cell = chgtotn_50_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    chgtotp_20_perha_in_cell = chgtotp_20_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    chgtotp_30_perha_in_cell = chgtotp_30_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    chgtotp_40_perha_in_cell = chgtotp_40_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    chgtotp_50_perha_in_cell = chgtotp_50_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    
    % Water quality values
    totn_ann_20_perha_in_cell = totn_ann_20_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    totn_ann_30_perha_in_cell = totn_ann_30_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    totn_ann_40_perha_in_cell = totn_ann_40_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    totn_ann_50_perha_in_cell = totn_ann_50_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    totp_ann_20_perha_in_cell = totp_ann_20_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    totp_ann_30_perha_in_cell = totp_ann_30_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    totp_ann_40_perha_in_cell = totp_ann_40_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    totp_ann_50_perha_in_cell = totp_ann_50_perha(cell2sbsn_idx(cell2sbsn_ind)) .* water_chg_cells.proportion;
    
    % (d) Calculate per ha water value for each cell
    % ----------------------------------------------
    [water_chg_cellid, ~, cellid_idx] = unique(water_chg_cells.new2kid);
    
    % Water quality quantities
    chgtotn_20_cell = accumarray(cellid_idx, chgtotn_20_perha_in_cell);
    chgtotn_30_cell = accumarray(cellid_idx, chgtotn_30_perha_in_cell);
    chgtotn_40_cell = accumarray(cellid_idx, chgtotn_40_perha_in_cell);
    chgtotn_50_cell = accumarray(cellid_idx, chgtotn_50_perha_in_cell);
    chgtotp_20_cell = accumarray(cellid_idx, chgtotp_20_perha_in_cell);
    chgtotp_30_cell = accumarray(cellid_idx, chgtotp_30_perha_in_cell);
    chgtotp_40_cell = accumarray(cellid_idx, chgtotp_40_perha_in_cell);
    chgtotp_50_cell = accumarray(cellid_idx, chgtotp_50_perha_in_cell);
    
    % Water quality values
    totn_ann_20_cell = accumarray(cellid_idx, totn_ann_20_perha_in_cell);
    totn_ann_30_cell = accumarray(cellid_idx, totn_ann_30_perha_in_cell);
    totn_ann_40_cell = accumarray(cellid_idx, totn_ann_40_perha_in_cell);
    totn_ann_50_cell = accumarray(cellid_idx, totn_ann_50_perha_in_cell);
    totp_ann_20_cell = accumarray(cellid_idx, totp_ann_20_perha_in_cell);
    totp_ann_30_cell = accumarray(cellid_idx, totp_ann_30_perha_in_cell);
    totp_ann_40_cell = accumarray(cellid_idx, totp_ann_40_perha_in_cell);
    totp_ann_50_cell = accumarray(cellid_idx, totp_ann_50_perha_in_cell);
    
    % (e) Calculate total water value for each cell with given 
    % landcover change
    % --------------------------------------------------------
    % Preallocate table to store results for return
    water_quality_table = array2table(zeros(cell_info.ncells, 1 + 8 + 8), ...
                                      'VariableNames', ...
                                      {'new2kid', ...
                                       'chgtotn_20', 'chgtotn_30', 'chgtotn_40', 'chgtotn_50', ...
                                       'chgtotp_20', 'chgtotp_30', 'chgtotp_40', 'chgtotp_50', ...
                                       'totn_ann_20', 'totn_ann_30', 'totn_ann_40', 'totn_ann_50', ...
                                       'totp_ann_20', 'totp_ann_30', 'totp_ann_40', 'totp_ann_50'});
    water_quality_table.new2kid = cell_info.new2kid;    % Fill in cell ids
    
    % Calculate indicator and index of all cell ids to changed cells
    [cell2chgcell_ind, cell2chgcell_idx] = ismember(cell_info.new2kid, water_chg_cellid);
    
    % Calculate values for each cell with given landcover change
    % ----------------------------------------------------------
    % Water quality quantities
    water_quality_table.chgtotn_20(cell2chgcell_ind) = chgtotn_20_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.chgtotn_30(cell2chgcell_ind) = chgtotn_30_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.chgtotn_40(cell2chgcell_ind) = chgtotn_40_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.chgtotn_50(cell2chgcell_ind) = chgtotn_50_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.chgtotp_20(cell2chgcell_ind) = chgtotp_20_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.chgtotp_30(cell2chgcell_ind) = chgtotp_30_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.chgtotp_40(cell2chgcell_ind) = chgtotp_40_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.chgtotp_50(cell2chgcell_ind) = chgtotp_50_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    
    % Water quality values
    water_quality_table.totn_ann_20(cell2chgcell_ind) = totn_ann_20_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.totn_ann_30(cell2chgcell_ind) = totn_ann_30_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.totn_ann_40(cell2chgcell_ind) = totn_ann_40_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.totn_ann_50(cell2chgcell_ind) = totn_ann_50_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.totp_ann_20(cell2chgcell_ind) = totp_ann_20_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.totp_ann_30(cell2chgcell_ind) = totp_ann_30_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.totp_ann_40(cell2chgcell_ind) = totp_ann_40_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    water_quality_table.totp_ann_50(cell2chgcell_ind) = totp_ann_50_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    
end