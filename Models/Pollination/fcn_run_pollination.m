function es_pollination = fcn_run_pollination(pollination_data_folder, es_biodiversity_ucl, climate_scen_string, insecthort_gm)
    % fcn_run_pollination.m
    % =====================
    % Author: Nathan Owen, Henry Ferguson-Gow, Richard Pearson
    % Last modified: 22/10/2019
    % Function to run the NEV pollination model, devised by Henry
    % Ferguson-Gow and Richard Pearson (UCL). Given cell pollinator species
    % richness under a scenario, this is compared to the species richness
    % under the baseline, and the value lost (if any) from reduced wild 
    % insect pollination of horticultural crops is calculated and returned.
    % Inputs:
    % - pollination_data_folder: path to the .mat file containing the data
    %   for the model. The .mat file is generated in ImportPollination.m
    %   and for me is stored in the folder C:/Data/Pollination/
    % - es_biodiversity_ucl: a structure containing biodiversity results,
    %   obtained by running the UCL biodiversity model using
    %   fcn_run_biodiversity_ucl.m. The fields of es_biodiversity_ucl used
    %   in this function are either 'pollinator_sr' (if
    %   'climate_scen_string' parameter is set to 'current') or
    %   'pollinator_sr_20', 'pollinator_sr_30', 'pollinator_sr_40',
    %   'pollinator_sr_50' (if 'climate_scen_string' parameter is set to
    %   'rcp60' or 'rcp85'). The field 'new2kid' is also used to determine
    %   the 2km grid cells.
    % - climate_scen_string: a string to specify which climate scenario
    %   should be used when making predictions. Can be one of: 'current',
    %   'rcp60', or 'rcp85'. See fcn_run_biodiversity_ucl.m.
    % - hort_gm: gross margin per hectare of horticulture. If not specified
    %   this is set to a default value below. The 2018 John Nix Pocketbook 
    %   quotes a wide range of values, from £783/ha (broccoli) to £14537/ha
    %   (strawberries).
    % Outputs:
    % - es_pollination: a structure containing the loss in value from wild
    %   wild insect pollinated horticulture due to land use change for the
    %   specified set of 2km grid cells. If 'climate_scen_string' is 
    %   'rcp60' or 'rcp85' then four fields are returned containing output
    %   in each decade, and if it is 'current' a single field is returned.
    
    %% (1) Set up
    %  ==========
    % (a) Data files 
    % --------------
    NEVO_Pollination_data_mat = strcat(pollination_data_folder, 'NEVO_Pollination_data.mat');
    load(NEVO_Pollination_data_mat, 'Pollination');
    
    % (b) Choose climate mask and set up decade info
    % ----------------------------------------------
    switch climate_scen_string
        case 'current'
            ndecades = 1;
            decade_string = {''};
            thresh = Pollination.thresh_now;
        case 'rcp60'
            ndecades = 4;
            decade_string = {'_20','_30','_40','_50'};
            thresh_20 = Pollination.thresh_rcp60_20;
            thresh_30 = Pollination.thresh_rcp60_30;
            thresh_40 = Pollination.thresh_rcp60_40;
            thresh_50 = Pollination.thresh_rcp60_50;
        case 'rcp85'
            ndecades = 4;
            decade_string = {'_20','_30','_40','_50'};
            thresh_20 = Pollination.thresh_rcp85_20;
            thresh_30 = Pollination.thresh_rcp85_30;
            thresh_40 = Pollination.thresh_rcp85_40;
            thresh_50 = Pollination.thresh_rcp85_50;
        otherwise
            error('Please choose a climate scenario from ''current'', ''rcp60'' or ''rcp85''.')
    end
    
    % (c) If hort_gm not specified, set default value
    % -----------------------------------------------
    if nargin < 4
        % Calculated by Mattia and Nathan using Defra Horticulture 
        % Statistics 2017
        insecthort_gm = 3607.55;
    end
    
    %% (2) Reduce to inputted 2km cells
    %  ================================
    % For inputted 2km grid cells, extract rows of relevant tables and
    % arrays in Pollination structure
    [input_cells_ind, input_cell_idx] = ismember(es_biodiversity_ucl.new2kid, Pollination.Data_cells.new2kid);
    input_cell_idx = input_cell_idx(input_cells_ind);
    
    % Data cells
    data_cells = Pollination.Data_cells(input_cell_idx,:);
    
    % Pollinator species richness thresholds
    switch climate_scen_string
        case 'current'
            thresh = thresh(input_cell_idx, :);
        case {'rcp60', 'rcp85'}
            thresh_20 = thresh_20(input_cell_idx, :);
            thresh_30 = thresh_30(input_cell_idx, :);
            thresh_40 = thresh_40(input_cell_idx, :);
            thresh_50 = thresh_50(input_cell_idx, :);
    end
    
    %% (3) Calculate pollination output
    %  ================================
    % (a) Create es_pollination structure with new2kid cell ids
    % ---------------------------------------------------------
    es_pollination.new2kid = es_biodiversity_ucl.new2kid;
    
    % (b) Calculate value of wild insect pollinated horticulture in
    % baseline using provided horticulture gross margin
    % -------------------------------------------------
    data_cells.insecthort_val = insecthort_gm * data_cells.insecthort_ha;
    
	% (c) Loop over decades to calculate pollinator value loss in scenario
    % --------------------------------------------------------------------
    for decade = 1:ndecades
        % (a) Extract information for this decade (or current period)
        % -----------------------------------------------------------
        % Pollinator species richness from es_biodiversity_ucl
        pollinator_sr_decade = eval(['es_biodiversity_ucl.pollinator_sr', decade_string{decade}]);
        
        % Pollinator species richness threshold
        thresh_decade = eval(['thresh', decade_string{decade}]);
        
        % (b) Compare pollinator species richness to threshold
        % ----------------------------------------------------
        % Two cases in each cell:
        % 1. Pollinator species richness < threshold, do not adjust
        %    pollinator species richness
        % 2. Pollinator species richness >= threshold, set pollinator
        %    pollinator species richness = threshold
        pollinator_sr_decade_adj = pollinator_sr_decade;
        pollinator_sr_decade_adj(pollinator_sr_decade_adj >= 105) = 105;
        
%         % (c) Calculate multipler
%         % -----------------------
%         % Multiplier should be in range [0, 1], and 1 when in case 2 above
%         multiplier_decade = pollinator_sr_decade_adj ./ thresh_decade;
%         
%         % (d) Calculate future wild insect pollinated horticulture value
%         % --------------------------------------------------------------
%         % Multiply baseline wild insect value by multiplier
%         insecthort_val_future = multiplier_decade .* data_cells.insecthort_val;
%         
%         % (e) Create outputs
%         % ------------------
%         % Main output is difference in future and baseline wild insect
%         % pollinated horticulture value
%         insecthort_val_diff = insecthort_val_future - data_cells.insecthort_val;
        
        insecthort_val_diff = data_cells.insecthort_val .* ((pollinator_sr_decade_adj / 105) - (thresh_decade / 105));
        
        % Add to es_pollination structure
        es_pollination.(['pollinator_val', decade_string{decade}]) = insecthort_val_diff;
    end
    
    % Convert structure to table for output
	es_pollination = struct2table(es_pollination);
end

