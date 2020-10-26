function es_non_use_habitat = fcn_run_non_use_habitat(non_use_habitat_data_folder, landuses, non_use_proportion, assumption_areas)
    % fcn_run_non_use_habitat.m
    % =========================
    % Author: Nathan Owen, Mattia Mancini, Brett Day, Amy Binner
    % Last modified: 12/11/2019
    % Inputs:
    % - 
    % Outputs:
    % - 
    
    %% (1) Set up
    %  ==========
    % (a) Data files 
    % --------------
    NEVO_NonUseHabitat_data_mat = strcat(non_use_habitat_data_folder, 'NEVO_NonUseHabitat_data.mat');
    load(NEVO_NonUseHabitat_data_mat, 'NonUseHabitat');
    
    % (b) Deal with assumption on areas
	% ---------------------------------
    if ~any(strcmp(assumption_areas, {'SDA', 'LFA'}))
        error('Area assumption must be one of ''SDA'' or ''LFA''')
    end
    
    %% (2) Reduce to inputted 2km cells
    %  ================================
    % For inputted 2km grid cells, extract rows of relevant tables and
    % arrays in NonUseHabitat structure
    [input_cells_ind, input_cell_idx] = ismember(landuses.new2kid, NonUseHabitat.Data_cells.new2kid);
    input_cell_idx = input_cell_idx(input_cells_ind);
    
    % Data cells
    data_cells = NonUseHabitat.Data_cells(input_cell_idx,:);
    
    %% (3) Calculate non use habitat output
    %  ====================================
    % (a) Create es_non_use_habitat structure with new2kid cell ids
    % -------------------------------------------------------------
    es_non_use_habitat.new2kid = landuses.new2kid;
    
    % (b) Calculate non use habitat value for SNG, woodland and total
    % ---------------------------------------------------------------
    % Multiply hectares of SNG & woodland by £/hectare non use habitat 
    % values, mask by SDA or LFA areas, take proportion of non use value
    % Values calculated by Brett
    switch assumption_areas
        case 'SDA'
            area_mask = data_cells.sda_logic;
        case 'LFA'
            area_mask = data_cells.lfa_logic;
    end
    nu_habitat_val_sngrass = non_use_proportion * 2966 * landuses.sngrass_ha .* area_mask;
    nu_habitat_val_wood = non_use_proportion * 4129 * landuses.wood_ha .* area_mask;
    nu_habitat_val = nu_habitat_val_sngrass + nu_habitat_val_wood;
    
    % (c) Create outputs
    % ------------------
    % Add values to non_use_habitat structure
    es_non_use_habitat.nu_habitat_val_sngrass = nu_habitat_val_sngrass;
    es_non_use_habitat.nu_habitat_val_wood = nu_habitat_val_wood;
    es_non_use_habitat.nu_habitat_val = nu_habitat_val;
    
    % Convert structure to table for output
    es_non_use_habitat = struct2table(es_non_use_habitat);
end

