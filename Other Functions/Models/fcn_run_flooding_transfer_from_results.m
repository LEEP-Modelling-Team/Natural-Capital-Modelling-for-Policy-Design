function flooding_transfer_table = fcn_run_flooding_transfer_from_results(cell_info, elm_option_string, elm_ha_option, flooding_results_transfer, flooding_cell2subctch, nfm_data, assumption_flooding)
    
    % 1. Set up
    % ---------
    % Get water results for this ELM option
    % -------------------------------------
    flooding_results_option = flooding_results_transfer.(elm_option_string);
    
    % Calculate indicators and ordering indexes
    % -----------------------------------------
    % Subctch id in cell2subctch lookup table
    [cell2subctch_ind, cell2subctch_idx] = ismember(flooding_cell2subctch.subctch_id, flooding_results_option.subctch_id); 
	
	% Deal with flooding and non-use water quality assumptions
	% --------------------------------------------------------
	% Flooding assumption
	% 'low': use 10 and 30 year events
	% 'medium': use 10, 30 and 100 year events
	% 'high': use 10, 30, 100 and 1000 year events
	switch assumption_flooding
		case 'low'
			flood_value = flooding_results_option.flood_value_low;
		case 'medium'
			flood_value = flooding_results_option.flood_value_medium;
		case 'high'
			flood_value = flooding_results_option.flood_value_high;
		otherwise
			error('Flooding assumption must be one of: {''low'', ''medium'', or ''high''}')
    end
    
    % 2. Main calculations
    % --------------------
    
    % (a) Convert option results from representative cell to per ha
    % -------------------------------------------------------------
    % Flood value
	floodvalue_perha = flood_value ./ flooding_results_option.hectares;
    
    % Flooding q5
    chgq5_20 = cellfun(@sum, flooding_results_option.chgq5_20);
    chgq5_30 = cellfun(@sum, flooding_results_option.chgq5_30);
    chgq5_40 = cellfun(@sum, flooding_results_option.chgq5_40);
    chgq5_50 = cellfun(@sum, flooding_results_option.chgq5_50);
    chgq5_20_perha = chgq5_20 ./ flooding_results_option.hectares;
    chgq5_30_perha = chgq5_30 ./ flooding_results_option.hectares;
    chgq5_40_perha = chgq5_40 ./ flooding_results_option.hectares;
    chgq5_50_perha = chgq5_50 ./ flooding_results_option.hectares;
    
    % (c) Align subbasin per ha water flood/quant to cells 2 subbasins lookup
    % -----------------------------------------------------------------------
    % Multiply by proportion of cell in subbasin
    flooding_chg_cells  = flooding_cell2subctch(cell2subctch_ind, :);
    
    % Flood value
    floodvalue_perha_in_cell = floodvalue_perha(cell2subctch_idx(cell2subctch_ind)) .* flooding_chg_cells.proportion;
    
    % Flooding q5
    chgq5_20_perha_in_cell = chgq5_20_perha(cell2subctch_idx(cell2subctch_ind)) .* flooding_chg_cells.proportion;
    chgq5_30_perha_in_cell = chgq5_30_perha(cell2subctch_idx(cell2subctch_ind)) .* flooding_chg_cells.proportion;
    chgq5_40_perha_in_cell = chgq5_40_perha(cell2subctch_idx(cell2subctch_ind)) .* flooding_chg_cells.proportion;
    chgq5_50_perha_in_cell = chgq5_50_perha(cell2subctch_idx(cell2subctch_ind)) .* flooding_chg_cells.proportion;


    % (d) Calculate per ha water flood/quant for each cell
    % ----------------------------------------------------
    [flooding_chg_cellid, ~, cellid_idx] = unique(flooding_chg_cells.new2kid);
    
    % Flood value
    floodvalue_cell = accumarray(cellid_idx, floodvalue_perha_in_cell);
    
    % Flooding q5
    chgq5_20_cell = accumarray(cellid_idx, chgq5_20_perha_in_cell);
    chgq5_30_cell = accumarray(cellid_idx, chgq5_30_perha_in_cell);
    chgq5_40_cell = accumarray(cellid_idx, chgq5_40_perha_in_cell);
    chgq5_50_cell = accumarray(cellid_idx, chgq5_50_perha_in_cell);

    
    % (e) Calculate total water flood/quant for each cell with given 
    % landcover change
    % --------------------------------------------------------------
    % Preallocate table to store results
    flooding_transfer_table = array2table(nan(cell_info.ncells, 6), ...
                                          'VariableNames', ...
                                          {'new2kid', ...
                                           'flood_value', ...
                                           'chgq5_20', ...
                                           'chgq5_30', ...
                                           'chgq5_40', ...
                                           'chgq5_50'});
    flooding_transfer_table.new2kid = cell_info.new2kid;    % Fill in cell ids
    
    % Calculate indicator and index of all cell ids to changed cells
    [cell2chgcell_ind, cell2chgcell_idx] = ismember(cell_info.new2kid, flooding_chg_cellid);
    
    % Also do this for natural flood management data
    % Tells us which cells are actually suitable for NFM
    [~, nfm_idx] = ismember(cell_info.new2kid, nfm_data.new2kid);
    nfm_data = nfm_data(nfm_idx, :);
    
    % Add Flooding Value
    % ------------------
    % Adjust hectares for NFM based on available hectares under ELM option
    nfm_ha_adjusted = nfm_data.nfm_area_ha;
    
    % these areas are not suitable for NFM, set to zero
    nfm_ha_adjusted(isnan(nfm_ha_adjusted)) = 0;
    
    % these areas have more hectares for NFM than is available under ELM
    % scheme, set to ELM scheme hectares
    nfm_ha_adjusted(nfm_ha_adjusted > elm_ha_option) = elm_ha_option(nfm_ha_adjusted > elm_ha_option);
    
    % Calculate flood value for each cell with given landcover change
    % !!! select whether to multiply by elm or nfm hectares here (nfm preferred) !!!
    % flooding_transfer_table.flood_value(cell2chgcell_ind) = floodvalue_cell(cell2chgcell_idx(cell2chgcell_ind)) .* nfm_ha_adjusted(cell2chgcell_ind);
    flooding_transfer_table.flood_value(cell2chgcell_ind) = floodvalue_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);

    flooding_transfer_table.flood_value(isnan(flooding_transfer_table.flood_value)) = 0; % these areas are not suitable for NFM
        
    % Add Flooding q5 Change
    % ----------------------
    flooding_transfer_table.chgq5_20(cell2chgcell_ind) = chgq5_20_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    flooding_transfer_table.chgq5_30(cell2chgcell_ind) = chgq5_30_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    flooding_transfer_table.chgq5_40(cell2chgcell_ind) = chgq5_40_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);
    flooding_transfer_table.chgq5_50(cell2chgcell_ind) = chgq5_50_cell(cell2chgcell_idx(cell2chgcell_ind)) .* elm_ha_option(cell2chgcell_ind);


end