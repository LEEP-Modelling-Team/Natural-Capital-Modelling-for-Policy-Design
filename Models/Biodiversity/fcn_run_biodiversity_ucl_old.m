function es_biodiversity_ucl = fcn_run_biodiversity_ucl_old(biodiversity_data_folder, landuses, climate_scen_string, other_ha_string)
    % fcn_run_biodiversity_ucl_old.m
    % ==============================
    % Author: Nathan Owen, Henry Ferguson-Gow
    % Last modified: 18/09/2019
    % Function to run the UCL biodiversity models (currently pollinators 
    % but priority species soon) for current climate and future climate 
    % scenarios.
    % Inputs:
    % - biodiversity_data_folder: path to the .mat file containing the data
    %   for the model. The .mat file is generated in ImportBiodiversityUCL.m
    %   and for me it is saved in the path C:/Data/Biodiversity/UCL/
    % - landuses: a structure or table containing land uses (in hectares) 
    %   for a set of 2km grid cells. Must have a new2kid column/field with 
    %   2km grid IDs. See fcn_create_model_matrix_ucl.m for required land 
    %   uses and how they are used.
    % - climate_scen_string: a string to specify which climate scenario
    %   should be used when making predictions. Can be one of: 'current',
    %   'rcp60', or 'rcp85'.
    % Outputs:
    % - es_biodiversity_ucl: a structure containing two fields. Firstly, a
    %   table showing presence (1) or absence (0) of all pollinator species
    %   in each 2km grid cell (pollinator_presence). Secondly, a vector
    %   showing the species richness of pollinator species in each 2km grid
    %   cell, i.e. the sum of the presence table across species 
    %   (pollinator_sr).

    %% (1) Set up
    %  ==========
    % (a) Data files 
    % --------------
    NEVO_Biodiversity_data_mat = strcat(biodiversity_data_folder, 'NEVO_Biodiversity_UCL_data_old.mat');
    load(NEVO_Biodiversity_data_mat, 'Biodiversity');
    
    % (b) Choose climate mask and set up decade info
    % ----------------------------------------------
    switch climate_scen_string
        case 'current'
            ndecades = 1;
            decade_string = {''};
            climate_mask  = Biodiversity.Mask_Pollinators_cells_now;
        case 'rcp60'
            ndecades = 4;
            decade_string = {'_20','_30','_40','_50'};
            climate_mask_20 = Biodiversity.Mask_Pollinators_cells_rcp60_20;
            climate_mask_30 = Biodiversity.Mask_Pollinators_cells_rcp60_30;
            climate_mask_40 = Biodiversity.Mask_Pollinators_cells_rcp60_40;
            climate_mask_50 = Biodiversity.Mask_Pollinators_cells_rcp60_50;
        case 'rcp85'
            ndecades = 4;
            decade_string = {'_20','_30','_40','_50'};
            climate_mask_20 = Biodiversity.Mask_Pollinators_cells_rcp85_20;
            climate_mask_30 = Biodiversity.Mask_Pollinators_cells_rcp85_30;
            climate_mask_40 = Biodiversity.Mask_Pollinators_cells_rcp85_40;
            climate_mask_50 = Biodiversity.Mask_Pollinators_cells_rcp85_50;
        otherwise
            error('Please choose a climate scenario from ''current'', ''rcp60'' or ''rcp85''.')
    end
    
    % (c) Treatment of other_ha category
    % ----------------------------------
    % Decide how other_ha is split up into subcategories
    switch other_ha_string
        case 'baseline'
            % Split up into subcategories based on baseline proportions
            % (no action taken - info contained in Biodiversity structure)
        case 'maize'
            % Convert all other_ha to maize
            ncells_all = length(Biodiversity.Data_cells.p_maize);
            Biodiversity.Data_cells.p_maize = ones(ncells_all, 1);
            Biodiversity.Data_cells.p_hort = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcer = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othfrm = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcrps = zeros(ncells_all, 1);
        case 'hort'
            % Convert all other_ha to hort
            ncells_all = length(Biodiversity.Data_cells.p_maize);
            Biodiversity.Data_cells.p_maize = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_hort = ones(ncells_all, 1);
            Biodiversity.Data_cells.p_othcer = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othfrm = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcrps = zeros(ncells_all, 1);
        case 'othcer'
            % Convert all other_ha to othcer
            ncells_all = length(Biodiversity.Data_cells.p_maize);
            Biodiversity.Data_cells.p_maize = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_hort = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcer = ones(ncells_all, 1);
            Biodiversity.Data_cells.p_othfrm = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcrps = zeros(ncells_all, 1);
        case 'othfrm'
            % Convert all other_ha to othfrm
            ncells_all = length(Biodiversity.Data_cells.p_maize);
            Biodiversity.Data_cells.p_maize = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_hort = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcer = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othfrm = ones(ncells_all, 1);
            Biodiversity.Data_cells.p_othcrps = zeros(ncells_all, 1);
        case 'othcrps'
            % Convert all other_ha to othcrps
            ncells_all = length(Biodiversity.Data_cells.p_maize);
            Biodiversity.Data_cells.p_maize = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_hort = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcer = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othfrm = zeros(ncells_all, 1);
            Biodiversity.Data_cells.p_othcrps = ones(ncells_all, 1);
        otherwise
            error('other_ha_string must be one of: ''baseline'', ''maize'', ''hort'', ''othcer'', ''othfrm'', ''othcrps''');
    end
    
    %% (2) Reduce to inputted 2km cells
    %  ================================
    % For inputted 2km grid cells, extract rows of relevant tables and
    % arrays in Biodiversity structure
    [input_cells_ind, input_cell_idx] = ismember(landuses.new2kid, Biodiversity.new2kid);
    input_cell_idx = input_cell_idx(input_cells_ind);
    
    % Data cells
    data_cells = Biodiversity.Data_cells(input_cell_idx,:);
    
    % Climate mask
    switch climate_scen_string
        case 'current'
            climate_mask = climate_mask(input_cell_idx, :);
        case {'rcp60', 'rcp85'}
            climate_mask_20 = climate_mask_20(input_cell_idx, :);
            climate_mask_30 = climate_mask_30(input_cell_idx, :);
            climate_mask_40 = climate_mask_40(input_cell_idx, :);
            climate_mask_50 = climate_mask_50(input_cell_idx, :);
    end
    
    %% (3) Calculate biodiversity output
    %  =================================
    for decade = 1:ndecades
        % (a) Create model matrix for this decade
        % ---------------------------------------
        model_matrix = fcn_create_model_matrix_ucl_old(data_cells, landuses, decade_string{decade});
        
        % (b) Model prediction
        % --------------------
        % Multiply model matrix by coefficients to get logit of probability
        % of occurrence for the 472 pollinator species
        pollinator_prob_logit = model_matrix * Biodiversity.Coefficients_Pollinators;
        
        % (c) Logit to presence using threshold
        % --------------------------------------
        % Use species-specific thresholds to calculate presence
        pollinator_presence = double(pollinator_prob_logit > Biodiversity.Thresholds_Pollinators);
        
        % (d) Mask species presence using climate envelope
        % ------------------------------------------------
        switch decade_string{decade}
            case ''
                pollinator_presence_masked = pollinator_presence .* climate_mask;
            case '_20'
                pollinator_presence_masked = pollinator_presence .* climate_mask_20;
            case '_30'
                pollinator_presence_masked = pollinator_presence .* climate_mask_30;
            case '_40'
                pollinator_presence_masked = pollinator_presence .* climate_mask_40;
            case '_50'
                pollinator_presence_masked = pollinator_presence .* climate_mask_50;
        end
        
        % (e) Create outputs
        % -----------------
        % Presence of each species & total richness in each cell
        es_biodiversity_ucl.new2kid = landuses.new2kid;
        es_biodiversity_ucl.(['pollinator_presence', decade_string{decade}]) = pollinator_presence_masked;
        es_biodiversity_ucl.(['pollinator_sr', decade_string{decade}]) = sum(pollinator_presence_masked,2);
    end
    
    % Also add new2kid 2km grid cell id (needed for pollination model)
    es_biodiversity_ucl.new2kid = landuses.new2kid;
end