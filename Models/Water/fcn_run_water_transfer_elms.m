function [es_water_transfer, ...
          flow_transfer] = fcn_run_water_transfer_elms(water_transfer_data_folder, ...
                                                       PV, ...
                                                       out, ...
                                                       input_subctch, ...
                                                       baserun_ind, ...
                                                       other_ha_string, ...
                                                       land_cover_subctch)
    % fcn_run_water.m
    % ===============
    % Authors: Brett Day, Nathan Owen
    % Last modified: 18/06/2020
    
    %% (1) Set up
    %  ==========
    % (a) Data files
    % --------------
    NEVO_Water_Transfer_data_mat = strcat(water_transfer_data_folder, 'NEVO_Water_Transfer_data.mat');
    WaterTransfer = load(NEVO_Water_Transfer_data_mat);
    
    % (b) Find which basins have been inputted
    % ----------------------------------------
    % These will be looped over in main part of function
    input_basin = WaterTransfer.subctch_basins.basin_id(ismember(WaterTransfer.subctch_basins.subctch_id, input_subctch));
    input_basin = unique(input_basin);
    
    % (c) Treatment of other_ha category
    % ----------------------------------
    % Decide how other_ha is split up into subcategories
    switch other_ha_string
        case 'baseline'
            % Split up into subcategories based on baseline proportions
            % (no action taken - info contained in WaterTransfer structure)
        case 'maize'
            % Convert all other_ha to maize
            ncells_all = length(WaterTransfer.proportions.p_maize);
            WaterTransfer.proportions.p_maize = ones(ncells_all, 1);
            WaterTransfer.proportions.p_hort = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othcer = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othfrm = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othcrps = zeros(ncells_all, 1);
        case 'hort'
            % Convert all other_ha to hort
            ncells_all = length(WaterTransfer.proportions.p_maize);
            WaterTransfer.proportions.p_maize = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_hort = ones(ncells_all, 1);
            WaterTransfer.proportions.p_othcer = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othfrm = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othcrps = zeros(ncells_all, 1);
        case 'othcer'
            % Convert all other_ha to othcer
            ncells_all = length(WaterTransfer.proportions.p_maize);
            WaterTransfer.proportions.p_maize = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_hort = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othcer = ones(ncells_all, 1);
            WaterTransfer.proportions.p_othfrm = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othcrps = zeros(ncells_all, 1);
        case 'othfrm'
            % Convert all other_ha to othfrm
            ncells_all = length(WaterTransfer.proportions.p_maize);
            WaterTransfer.proportions.p_maize = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_hort = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othcer = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othfrm = ones(ncells_all, 1);
            WaterTransfer.proportions.p_othcrps = zeros(ncells_all, 1);
        case 'othcrps'
            % Convert all other_ha to othcrps
            ncells_all = length(WaterTransfer.proportions.p_maize);
            WaterTransfer.proportions.p_maize = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_hort = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othcer = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othfrm = zeros(ncells_all, 1);
            WaterTransfer.proportions.p_othcrps = ones(ncells_all, 1);
        otherwise
            error('other_ha_string must be one of: ''baseline'', ''maize'', ''hort'', ''othcer'', ''othfrm'', ''othcrps''');
    end
    
    %% (2) Reduce to inputted 2km cells
    %  ================================
    % For inputted 2km grid cells, extract rows of relevant tables and
    % arrays in Water structure
    [input_cells_ind, input_cell_idx] = ismember(landuses.new2kid, WaterTransfer.proportions.new2kid);
    input_cell_idx = input_cell_idx(input_cells_ind);
    
    % Data cells
    proportions = WaterTransfer.proportions(input_cell_idx,:);
    
    %% (3) Calculate new land covers in each subbasin 
    % ===============================================
    % (a) Translate NEV land uses to SWAT emulator land uses
    % -----------------------------------------------------
    NEVO_new_lcs_cells = [landuses.new2kid ...
                          landuses.water_ha ...
                          landuses.urban_ha ...
                          landuses.sngrass_ha ...
                          landuses.wood_ha ...
                          landuses.pgrass_ha_20 + landuses.tgrass_ha_20 + landuses.rgraz_ha_20 ...
                          (proportions.p_hort + proportions.p_othcrps + proportions.p_othfrm) .* landuses.other_ha_20 ...
                          landuses.wheat_ha_20 ...
                          landuses.wbar_ha_20 + landuses.sbar_ha_20 ...
                          landuses.osr_ha_20 ...
                          landuses.pot_ha_20 ...
                          landuses.sb_ha_20 ...
                          proportions.p_maize.*landuses.other_ha_20 ...
                          proportions.p_othcer.*landuses.other_ha_20 ...
                          landuses.water_ha ...
                          landuses.urban_ha ...
                          landuses.sngrass_ha ...
                          landuses.wood_ha ...
                          landuses.pgrass_ha_30 + landuses.tgrass_ha_30 + landuses.rgraz_ha_30 ...
                          (proportions.p_hort + proportions.p_othcrps + proportions.p_othfrm) .* landuses.other_ha_30 ...
                          landuses.wheat_ha_30 ...
                          landuses.wbar_ha_30 + landuses.sbar_ha_30 ...
                          landuses.osr_ha_30 ...
                          landuses.pot_ha_30 ...
                          landuses.sb_ha_30 ...
                          proportions.p_maize.*landuses.other_ha_30 ...
                          proportions.p_othcer.*landuses.other_ha_30 ...
                          landuses.water_ha ...
                          landuses.urban_ha ...
                          landuses.sngrass_ha ...
                          landuses.wood_ha ...
                          landuses.pgrass_ha_40 + landuses.tgrass_ha_40 + landuses.rgraz_ha_40 ...
                          (proportions.p_hort + proportions.p_othcrps + proportions.p_othfrm) .* landuses.other_ha_40 ...
                          landuses.wheat_ha_40 ...
                          landuses.wbar_ha_40 + landuses.sbar_ha_40 ...
                          landuses.osr_ha_40 ...
                          landuses.pot_ha_40 ...
                          landuses.sb_ha_40 ...
                          proportions.p_maize.*landuses.other_ha_40 ...
                          proportions.p_othcer.*landuses.other_ha_40 ...
                          landuses.water_ha ...
                          landuses.urban_ha ...
                          landuses.sngrass_ha ...
                          landuses.wood_ha ...
                          landuses.pgrass_ha_50 + landuses.tgrass_ha_50 + landuses.rgraz_ha_50 ...
                          (proportions.p_hort + proportions.p_othcrps + proportions.p_othfrm) .* landuses.other_ha_50 ...
                          landuses.wheat_ha_50 ...
                          landuses.wbar_ha_50 + landuses.sbar_ha_50 ...
                          landuses.osr_ha_50 ...
                          landuses.pot_ha_50 ...
                          landuses.sb_ha_50 ...
                          proportions.p_maize.*landuses.other_ha_50 ...
                          proportions.p_othcer.*landuses.other_ha_50];
    nSWATlcs = size(NEVO_new_lcs_cells, 2) - 1;
    
    % (b) Find base landcover areas in cell-subbasin for input cells
    % --------------------------------------------------------------
    [cells_ind, cells_idx]   = ismember(WaterTransfer.base_lcs_subctch_cells.new2kid, NEVO_new_lcs_cells(:,1));
    NEVO_base_lcs_subctch_cells = WaterTransfer.base_lcs_subctch_cells(cells_ind,:);
    cells_idx = cells_idx(cells_ind);

    if isempty(cells_idx)        
        error('None of the input cells are in a subbasin!');
    end
    
    % (c) Restrict land cover change to subbasin identified by land_cover_sbsn
    % ------------------------------------------------------------------------
    if exist('land_cover_subctch', 'var')
        NEVO_base_lcs_subctch_cells = NEVO_base_lcs_subctch_cells(ismember(NEVO_base_lcs_subctch_cells.subctch_id, land_cover_subctch), :);
    else
        % No action, land cover change is applied in all relevant subbasins
    end

    % (d) Calculate change in landcover areas in cell-subbasin
    % --------------------------------------------------------
    % i.  Multiply new cell lcs by % in subbasin -> new lc areas for cell-subbasin
    % ii. Substract base lc areas for cell-subbasin to give change of lc in cell-subbasin
    if exist('land_cover_subctch', 'var')
        % cell_idx NOT needed here
        NEVO_chg_lcs_subctch_cells = (NEVO_new_lcs_cells(:, 2:end) .* NEVO_base_lcs_subctch_cells.proportion) - table2array(NEVO_base_lcs_subctch_cells(:, 4:end));
    else
        % cell_idx IS needed here
        NEVO_chg_lcs_subctch_cells = (NEVO_new_lcs_cells(cells_idx, 2:end) .* NEVO_base_lcs_subctch_cells.proportion) - table2array(NEVO_base_lcs_subctch_cells(:, 4:end));
    end

    % (e) Sum up all landcovers within subbasin experiencing change
    % -------------------------------------------------------------
    % Unique subbasin ids and index to associated cell-subbasin rows
    [subctch_chg_ids, ~, subctch_chg_idx] = unique(NEVO_base_lcs_subctch_cells.subctch_id);
    % Sum changes in same subbasin 
    NEVO_chg_lcs_subctch = zeros(length(subctch_chg_ids), nSWATlcs);
    for jj = 1:nSWATlcs
        NEVO_chg_lcs_subctch(:,jj) = accumarray(subctch_chg_idx, NEVO_chg_lcs_subctch_cells(:, jj));
    end

    % (f) Calculate new subbasin landcovers by adding changes to subbasin base landcovers
    % -----------------------------------------------------------------------------------
    [~, subctch_chg_idx] = ismember(subctch_chg_ids, WaterTransfer.base_lcs_subctch.subctch_id);
    NEVO_new_lcs_subctch = table2array(WaterTransfer.base_lcs_subctch(:, 3:54));
    NEVO_new_lcs_subctch(subctch_chg_idx, :) = table2array(WaterTransfer.base_lcs_subctch(subctch_chg_idx, 3:54)) + NEVO_chg_lcs_subctch;

    % (g) Convert landcover extent to percentage of subbasin under each landcover
    % ---------------------------------------------------------------------------
    NEVO_new_lcs_pcts_subctch = NEVO_new_lcs_subctch ./ WaterTransfer.base_lcs_subctch.cell_area_ha;    
    
    % (h) Make indicator vectors of changed subbasins and subbasins for which output requested
    % -----------------------------------------------------------------------------------------
    NEVO_subctch_ids = WaterTransfer.base_lcs_subctch.subctch_id;
    
    subctch_chg_ids = [subctch_chg_ids; WaterTransfer.no_land_subctch];
    NEVO_subctch_chg_ind = ismember(NEVO_subctch_ids, subctch_chg_ids);
    NEVO_subctch_out_ind = ismember(NEVO_subctch_ids, input_subctch);
    
    % RESULTS OF PRE-PROCESSING
    % =========================
    % Matrices all ordered numerically by basin-subbasin number:
    %   NEVO_subctch_ids:           Nsbsn       cell array of subbasin ids
    %   NEVO_subctch_basin_ids:    [Nsbsn x 2]  matrix of basin ids and subbsasin order number
    %   NEVO_new_lcs_pcts_subctch: [Nsbsn x 52] matirx of SWAT landcovers for each subbasin for each decade

    %   NEVO_subctch_chg_ind:       Nsbsn       indicator vector of subbasins experieincing landcover change
    %   NEVO_subctch_out_ind:       Nsbsn       indicator vector of subbasins for which water outputs requested
    
    %% (4) Calculate water output 
    % ===========================
    % Set up
    ndecades = 4;
    output_table_basins = [];
    
    % Daily flow is recorded for output, used as input to flood model
    flow_subctch_id = {};
    flow_20 = [];
    flow_30 = [];
    flow_40 = [];
    flow_50 = [];

    % Loop through basins from which output requested
    for i = 1:length(input_basin)
        % (a) Extract data for this basin
        % -------------------------------
        basini_subctch_ids = WaterTransfer.subctch_basins.subctch_id(WaterTransfer.subctch_basins.basin_id == input_basin(i));
        
%         basini_ind = ismember(WaterTransfer.base_lcs_subctch.subctch_id, basini_subctch_ids);
%         
%         basini_new_lcs_subctch = NEVO_new_lcs_pcts_subctch(basini_ind, :);
%         basini_subctch_chg_ind = NEVO_subctch_chg_ind(basini_ind);
%         basini_subctch_out_ind = NEVO_subctch_out_ind(basini_ind);
        
        [~, basini_idx] = ismember(basini_subctch_ids, WaterTransfer.base_lcs_subctch.subctch_id);
        
        basini_new_lcs_subctch = NEVO_new_lcs_pcts_subctch(basini_idx, :);
        basini_subctch_chg_ind = NEVO_subctch_chg_ind(basini_idx);
        basini_subctch_out_ind = NEVO_subctch_out_ind(basini_idx);
        
        % (b) Preallocate cell array of output subctch_ids in the other 
        % that they are run
        % -----------------
        basini_subctch_out_subctch_ids = cell(sum(basini_subctch_out_ind), 1);
        out_count = 0;  % Start counter which increments when output subctch is stoed
        
        % (c) Load input output data for this basin
        % -----------------------------------------
        IOfile = [water_transfer_data_folder, 'Input Output/io', num2str(input_basin(i)), '.mat'];
        IOdata = load(IOfile);
        
        % Determine number of first and second order subcatchments
        % Total number of subcatchments is the sum of these
        num_firstorder_basini = length(IOdata.firstorder);
        num_secondorder_basini = length(IOdata.secondorder);
        num_subctch_basini = num_firstorder_basini + num_secondorder_basini;
        
        % Loop through decades
        for j = 1:ndecades

            switch j
                case 1
                    basedatafile = [water_transfer_data_folder, 'Base Run/base', num2str(input_basin(i)), '_2029.mat'];
                    startcol = 1;
                    endcol   = 13;
                    decade_str = '_20';
                    output_table_basini_20 = [];
                case 2
                    basedatafile = [water_transfer_data_folder, 'Base Run/base', num2str(input_basin(i)), '_2039.mat'];
                    startcol = 14;
                    endcol   = 26;
                    decade_str = '_30';
                    output_table_basini_30 = [];
                case 3
                    basedatafile = [water_transfer_data_folder, 'Base Run/base', num2str(input_basin(i)), '_2049.mat'];
                    startcol = 27;
                    endcol   = 39;
                    decade_str = '_40';
                    output_table_basini_40 = [];
                case 4
                    basedatafile = [water_transfer_data_folder, 'Base Run/base', num2str(input_basin(i)), '_2059.mat'];
                    startcol = 40;
                    endcol   = 52;
                    decade_str = '_50';
                    output_table_basini_50 = [];
            end

            % Landcovers for this decade
            basini_decj_new_lcs_subctch = basini_new_lcs_subctch(:, startcol:endcol);

            % (d) Initialise arrays
            % ---------------------
            if baserun_ind == 1
                basin_em_data = cell(1, num_subctch_basini);
            else
                load(basedatafile);
            end

            % (e) Run Emulator for first order subbasins
            % ------------------------------------------            
            basini_finished = false;
            for k = 1:num_firstorder_basini
                [~, subctch_order_idx] = ismember(IOdata.firstorder(k), basini_subctch_ids);

                % if this subbasin has changed then run emulator to update subbasin IN and OUT
                if basini_subctch_chg_ind(subctch_order_idx) == 1
                   % Prepare subcatcment info for land use transfer model
                   subctch_id_k = array2table(IOdata.firstorder(k), 'VariableNames', {'subctch_id'});
                   subctch_area_k = array2table(WaterTransfer.base_lcs_subctch.area_km2(strcmp(IOdata.firstorder(k), WaterTransfer.base_lcs_subctch.subctch_id)), 'VariableNames', {'sbsn_area'});
                   subctch_planduse_k = array2table(basini_decj_new_lcs_subctch(subctch_order_idx, :), 'VariableNames', {'p_watr', 'p_urml', 'p_rnge', 'p_frst', 'p_past', 'p_agrl', 'p_wwht', 'p_wbar', 'p_canp', 'p_pota', 'p_sgbt', 'p_corn', 'p_oats'});
                   subctch_info_k = [subctch_id_k, subctch_area_k, subctch_planduse_k];
                   
                   % RUN emulator for firstorder subbasin k in basin i
                   % UPDATE SWATemdata IN & OUT For this subbbasin
                   [subctch_em_summary, basin_em_data{subctch_order_idx}] = fcn_transfer_model_firstorder(water_transfer_data_folder, subctch_info_k, decade_str, WaterTransfer.models_lu);
                   
                   % Record flow output for flood model
                   if basini_subctch_out_ind(subctch_order_idx)
                       switch j
                           case 1
                               flow_subctch_id = [flow_subctch_id; IOdata.firstorder(k)];
                               flow_20 = [flow_20; basin_em_data{subctch_order_idx}.flow'];
                           case 2
                               flow_30 = [flow_30; basin_em_data{subctch_order_idx}.flow'];
                           case 3
                               flow_40 = [flow_40; basin_em_data{subctch_order_idx}.flow'];
                           case 4
                               flow_50 = [flow_50; basin_em_data{subctch_order_idx}.flow'];
                       end
                   end
                end

                if basini_subctch_out_ind(subctch_order_idx) == 1
                   % RECORD OUT data for this subbasin
                   switch j
                       case 1
                           output_table_basini_20 = [output_table_basini_20; subctch_em_summary];
                           out_count = out_count + 1;
                           basini_subctch_out_subctch_ids{out_count} = basini_subctch_ids{subctch_order_idx};
                       case 2
                           output_table_basini_30 = [output_table_basini_30; subctch_em_summary];
                       case 3
                           output_table_basini_40 = [output_table_basini_40; subctch_em_summary];
                       case 4
                           output_table_basini_50 = [output_table_basini_50; subctch_em_summary];
                           basini_subctch_out_ind(subctch_order_idx) = 0;
                   end

                   % Check to see if all output subbasins have been processed
                   if sum(basini_subctch_out_ind) == 0
                       basini_finished = true;
                       break
                   end
                end

            end

            % (f) Run Emulator for second order subbasins
            % -------------------------------------------      
            if basini_finished == false
                for k = 1:num_secondorder_basini
                    [~, subctch_order_idx] = ismember(IOdata.secondorder{k}{1}, basini_subctch_ids);
                    [~, subctch_upstream_order_idx] = ismember(IOdata.secondorder{k}(2:end)', basini_subctch_ids);
                    
                    % if this subbasin has changed or either of its feeders then run emulator to update subbasin IN and OUT
                    if (basini_subctch_chg_ind(subctch_order_idx)) || ...
                       (any(basini_subctch_chg_ind(subctch_upstream_order_idx)))

                       % Add variables from upstream subbasins
                       subctch_em_upstream = fcn_add_transfer_upstream_out(basin_em_data, subctch_upstream_order_idx);
                       
                       % Prepare subcatcment info for land use transfer model
                       subctch_id_k = array2table(IOdata.secondorder{k}(1), 'VariableNames', {'subctch_id'});
                       subctch_area_k = array2table(WaterTransfer.base_lcs_subctch.area_km2(strcmp(IOdata.secondorder{k}(1), WaterTransfer.base_lcs_subctch.subctch_id)), 'VariableNames', {'sbsn_area'});
                       subctch_planduse_k = array2table(basini_decj_new_lcs_subctch(subctch_order_idx, :), 'VariableNames', {'p_watr', 'p_urml', 'p_rnge', 'p_frst', 'p_past', 'p_agrl', 'p_wwht', 'p_wbar', 'p_canp', 'p_pota', 'p_sgbt', 'p_corn', 'p_oats'});
                       subctch_info_k = [subctch_id_k, subctch_area_k, subctch_planduse_k];
                       
                       % RUN emulator for secondorder subbasin k in basin i
                       % UPDATE SWATemdata IN * OUT For this subbbasin
                       [subctch_em_summary, basin_em_data{subctch_order_idx}] = fcn_transfer_model_secondorder(water_transfer_data_folder, subctch_info_k, decade_str, subctch_em_upstream, WaterTransfer.models_lu);
                  
                       %disp('Changing Landcovers!');

                       % Change indicator to show out for this subbasin has changed
                       basini_subctch_chg_ind(subctch_order_idx) = 1; 

                       % Record flow output for flood model
                       if basini_subctch_out_ind(subctch_order_idx)
                           switch j
                               case 1
                                   flow_subctch_id = [flow_subctch_id; IOdata.secondorder{k}(1)];
                                   flow_20 = [flow_20; basin_em_data{subctch_order_idx}.flow'];
                               case 2
                                   flow_30 = [flow_30; basin_em_data{subctch_order_idx}.flow'];
                               case 3
                                   flow_40 = [flow_40; basin_em_data{subctch_order_idx}.flow'];
                               case 4
                                   flow_50 = [flow_50; basin_em_data{subctch_order_idx}.flow'];
                           end
                       end
                    end

                    if basini_subctch_out_ind(subctch_order_idx) == 1
                       % RECORD OUT data for this subbasin
                       switch j
                           case 1
                               output_table_basini_20 = [output_table_basini_20; subctch_em_summary];
                               out_count = out_count + 1;
                               basini_subctch_out_subctch_ids{out_count} = basini_subctch_ids{subctch_order_idx};
                           case 2
                               output_table_basini_30 = [output_table_basini_30; subctch_em_summary];
                           case 3
                               output_table_basini_40 = [output_table_basini_40; subctch_em_summary];
                           case 4
                               output_table_basini_50 = [output_table_basini_50; subctch_em_summary];
                               basini_subctch_out_ind(subctch_order_idx) = 0;
                       end

                       % Check to see if all output subbasins have been processed
                       if sum(basini_subctch_out_ind) == 0
                           basini_finished = true;
                           break
                       end
                    end                    
                end
            end
            % Finished this decade in this basin
            if baserun_ind == 1
                save(basedatafile, 'basin_em_data', '-mat', '-v6');       
            end
        end
        
        % Add subcatchment ids to output water data calculated for those 
        % subcatchments for each decade
        output_table_basini = [cell2table(basini_subctch_out_subctch_ids,'VariableNames', {'subctch_id'}) ...
                               output_table_basini_20, ...
                               output_table_basini_30, ...
                               output_table_basini_40, ...
                               output_table_basini_50];
                           
        % Join to the subbasin info data which contains the sort order of
        % those subbasins in the request
        output_table_basins = [output_table_basins; output_table_basini];
    end
    
    %% (5) Format water outputs for return
    %  ===================================
    % (a) Concatenate flow across decades
    % -----------------------------------
    flow_cat = [flow_20, flow_30, flow_40, flow_50];
    
    % Convert to table with appropriate column names
    flow_table = table(flow_subctch_id, flow_cat);
    flow_table.Properties.VariableNames = {'subctch_id', 'flow'};
    
    % (b) Sort output in order of input_subctch
    % -----------------------------------------
    % Outer join output_table_basins and flow_cat with input_subctch
    % This is because some subctch_ids are not run (they are not part of a basin) 
    % But they should be included in return with NaN flow
    input_subctch_table = cell2table(input_subctch, 'VariableNames', {'subctch_id'});
    es_water_transfer = outerjoin(input_subctch_table, output_table_basins, ...
                                  'MergeKeys', true);
    flow_transfer = outerjoin(input_subctch_table, flow_table, ...
                              'MergeKeys', true);
                          
    % Sort in order of input_subctch using ismember
    [~, sort_idx1] = ismember(input_subctch, es_water_transfer.subctch_id);
    es_water_transfer = es_water_transfer(sort_idx1, :);
    
    [~, sort_idx2] = ismember(input_subctch, flow_transfer.subctch_id);
    flow_transfer = flow_transfer{sort_idx2, 2:end}; % drop subctch id and convert to array

end