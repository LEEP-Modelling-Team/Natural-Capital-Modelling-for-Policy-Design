function [es_water, es_water_flood] = fcn_run_water(water_data_folder, PV, out, input_sbsn, baserun_ind, bsnrun_ind)

    % Inputs:
    %    i.   ID & landcovers for cells with changed landcovers (in out structure)
    %    ii.  Basin id for which output requested
    %    iii. List of subbasin ids at which new Water output should be recorded

    %% (1) READ WATER MAT FILE
    % ========================
    NEVO_water_data_mat = strcat(water_data_folder, 'NEVO_Water_data.mat');
    NEVO_water_data     = load(NEVO_water_data_mat);
    
    if size(input_sbsn,1) == 1
        input_bsn = str2double(split(input_sbsn,'_'))';
    else
        input_bsn = str2double(split(input_sbsn,'_'));
    end
    input_bsn = unique(input_bsn(:,1));

    % (a) Translate NEVO input cell landcovers to SWAT emulation landcovers
    % ---------------------------------------------------------------------
    NEVO_new_lcs_cells = [out.new2kid ...
                          out.water_ha ...
                          out.urban_ha ...
                          out.sngrass_ha ...
                          out.wood_ha ...
                          out.pgrass_ha_20 + out.tgrass_ha_20 + out.rgraz_ha_20 ...
                          (PV.p_hort + PV.p_othcrps + PV.p_othfrm).*out.other_ha_20 ...
                          out.wheat_ha_20 ...
                          out.wbar_ha_20 + out.sbar_ha_20 ...
                          out.osr_ha_20 ...
                          out.pot_ha_20 ...
                          out.sb_ha_20 ...
                          PV.p_maize.*out.other_ha_20 ...
                          PV.p_othcer.*out.other_ha_20 ...
                          out.water_ha ...
                          out.urban_ha ...
                          out.sngrass_ha ...
                          out.wood_ha ...
                          out.pgrass_ha_30 + out.tgrass_ha_30 + out.rgraz_ha_30 ...
                          (PV.p_hort + PV.p_othcrps + PV.p_othfrm).*out.other_ha_30 ...
                          out.wheat_ha_30 ...
                          out.wbar_ha_30 + out.sbar_ha_30 ...
                          out.osr_ha_30 ...
                          out.pot_ha_30 ...
                          out.sb_ha_30 ...
                          PV.p_maize.*out.other_ha_30 ...
                          PV.p_othcer.*out.other_ha_30 ...
                          out.water_ha ...
                          out.urban_ha ...
                          out.sngrass_ha ...
                          out.wood_ha ...
                          out.pgrass_ha_40 + out.tgrass_ha_40 + out.rgraz_ha_40 ...
                          (PV.p_hort + PV.p_othcrps + PV.p_othfrm).*out.other_ha_40 ...
                          out.wheat_ha_40 ...
                          out.wbar_ha_40 + out.sbar_ha_40 ...
                          out.osr_ha_40 ...
                          out.pot_ha_40 ...
                          out.sb_ha_40 ...
                          PV.p_maize.*out.other_ha_40 ...
                          PV.p_othcer.*out.other_ha_40 ...
                          out.water_ha ...
                          out.urban_ha ...
                          out.sngrass_ha ...
                          out.wood_ha ...
                          out.pgrass_ha_50 + out.tgrass_ha_50 + out.rgraz_ha_50 ...
                          (PV.p_hort + PV.p_othcrps + PV.p_othfrm).*out.other_ha_50 ...
                          out.wheat_ha_50 ...
                          out.wbar_ha_50 + out.sbar_ha_50 ...
                          out.osr_ha_50 ...
                          out.pot_ha_50 ...
                          out.sb_ha_50 ...
                          PV.p_maize.*out.other_ha_50 ...
                          PV.p_othcer.*out.other_ha_50];

    nSWATlcs = size(NEVO_new_lcs_cells,2) - 1;

    
    %% (2) CALCULATE NEW LANDCOVERS IN EACH SUBBASIN 
    % ==============================================

    % (a) Find base landcover areas in cell-subbasin for input cells
    % --------------------------------------------------------------
    [cells_ind, cells_idx]   = ismember(NEVO_water_data.NEVO_base_lcs_sbsn_cells.new2kid, NEVO_new_lcs_cells(:,1));
    NEVO_base_lcs_sbsn_cells = NEVO_water_data.NEVO_base_lcs_sbsn_cells(cells_ind,:);
    cells_idx = cells_idx(cells_ind);

    if isempty(cells_idx)        
        error('None of the input cells are in a subbasin!!');
    end

    % (b) Calculate change in landcover areas in cell-subbasin
    % --------------------------------------------------------
    %   i.  Multiply new cell lcs by % in subbasin -> new lc areas for cell-subbasin
    %   ii. Substract base lc areas for cell-subbasin to give change of lc in cell-subbasin
    NEVO_chg_lcs_sbsn_cells = (NEVO_new_lcs_cells(cells_idx, 2:end) .* NEVO_base_lcs_sbsn_cells.pct_cell) - table2array(NEVO_base_lcs_sbsn_cells(:,4:end));

    % (c) Sum up all landcovers within subbasin experiencing change
    % -------------------------------------------------------------
    %   Unique subbasin ids and index to associated cell-subbasin rows
    [sbsn_chg_ids,~,sbsn_chg_idx] = unique(NEVO_base_lcs_sbsn_cells.src_id);
    %   Sum changes in same subbasin 
    NEVO_chg_lcs_sbsn = zeros(length(sbsn_chg_ids),nSWATlcs);
    for jj = 1:nSWATlcs
        NEVO_chg_lcs_sbsn(:,jj) = accumarray(sbsn_chg_idx, NEVO_chg_lcs_sbsn_cells(:,jj));
    end

    % (d) Calculate new subbasin landcovers by adding changes to subbasin base landcovers
    % -----------------------------------------------------------------------------------
    [~, sbsn_chg_idx] = ismember(sbsn_chg_ids, NEVO_water_data.NEVO_base_lcs_sbsn.src_id);
    NEVO_sbsn_ids = NEVO_water_data.NEVO_subbasins.src_id;
    NEVO_new_lcs_sbsn = table2array(NEVO_water_data.NEVO_base_lcs_sbsn(:,2:end));
    NEVO_new_lcs_sbsn(sbsn_chg_idx,:) = table2array(NEVO_water_data.NEVO_base_lcs_sbsn(sbsn_chg_idx,2:end)) + NEVO_chg_lcs_sbsn;

    % (e) Convert landcover extent to percentage of subbasin under each landcover
    % ---------------------------------------------------------------------------
    NEVO_new_lcs_pcts_sbsn = NEVO_new_lcs_sbsn./NEVO_water_data.NEVO_subbasins.tot_area;    
    
    % (f) Make indicator vectors of changed subbabsins and subbasins for which output requested
    % -----------------------------------------------------------------------------------------
    NEVO_sbsn_chg_ind = ismember(NEVO_sbsn_ids, sbsn_chg_ids);
    NEVO_sbsn_out_ind = ismember(NEVO_sbsn_ids, input_sbsn);
    %   Split sbsn ids into basin and subbasin order number
    NEVO_sbsn_bsn_ids = [NEVO_water_data.NEVO_subbasins.basin_id NEVO_water_data.NEVO_subbasins.subbasin_id];

    % Results of Preprocessing:
    % ------------------------

    %   Matrices all ordered numerically by basin-subbasin number:
    %   NEVO_sbsn_ids:           Nsbsn       cell array of subbasin ids
    %   NEVO_sbsn_bsn_ids:      [Nsbsn x 2]  matrix of basin ids and subbsasin order number
    %   NEVO_new_lcs_pcts_sbsn: [Nsbsn x 52] matirx of SWAT landcovers for each subbasin for each decade

    %   NEVO_sbsn_chg_ind:       Nsbsn       indicator vector of subbasins experieincing landcover change
    %   NEVO_sbsn_out_ind:       Nsbsn       indicator vector of subbasins for which water outputs requested



    %% (4) RUN SWAT EMULATORS TO CALCUALTE WATER OUTPUTS 
    % ==================================================
    ndecades = 4;

    es_water = [];
    
    % For flood model
    flood_src_id = {};
    flow_20 = [];
    flow_30 = [];
    flow_40 = [];
    flow_50 = [];

    % Loop through basins from which output requested
    for i = 1:length(input_bsn)

        % (a) Extract data for this basin
        % -------------------------------
        bsni_ind          = ismember(NEVO_sbsn_bsn_ids(:,1), input_bsn(i));

        bsni_sbsn_ids     = NEVO_sbsn_ids(bsni_ind);
        bsni_new_lcs_sbsn = NEVO_new_lcs_pcts_sbsn(bsni_ind, :);

        bsni_sbsn_chg_ind = NEVO_sbsn_chg_ind(bsni_ind);
        bsni_sbsn_out_ind = NEVO_sbsn_out_ind(bsni_ind);

        
        % (b) Extract subbasin info for subbasins for which data requested
        % ----------------------------------------------------------------
        % Retrieve list of output subbasins from this basin in the order of 
        % the request and add a sort order variable to ensure can return in
        % the same order as the request
        input_sbsn_bsni            = cell2table(input_sbsn(ismember(input_sbsn, bsni_sbsn_ids),1),'VariableNames',{'src_id'});
        input_sbsn_bsni.sort_order = (1:size(input_sbsn_bsni,1))';
        % Get subbasin or basin info
        if bsnrun_ind == 1
            bsni_sbsn_out_info = NEVO_water_data.NEVO_basins(ismember(NEVO_water_data.NEVO_basins.src_id,input_sbsn_bsni.src_id),:);
        else
            bsni_sbsn_out_info = NEVO_water_data.NEVO_subbasins(ismember(NEVO_water_data.NEVO_subbasins.src_id,input_sbsn_bsni.src_id),:);
        end
        bsni_sbsn_out_info = innerjoin(bsni_sbsn_out_info,input_sbsn_bsni);
        
        bsni_sbsn_out_sbsn_ids = cell(size(input_sbsn_bsni,1),1);
        out_count = 0;
        
        % Loop through decades
        for j = 1:ndecades

            switch j
                case 1
                    SWATemfile = [water_data_folder 'Emulator Coefficients/emulator' num2str(input_bsn(i)) '_2029.mat'];
                    basedatafile = [water_data_folder 'Base Run/base' num2str(input_bsn(i)) '_2029.mat'];
                    startcol = 1;
                    endcol   = 13;
                    decade_str = '_20';
                    output_table_bsni_20 = [];
                case 2
                    SWATemfile = [water_data_folder 'Emulator Coefficients/emulator' num2str(input_bsn(i)) '_2039.mat'];
                    basedatafile = [water_data_folder 'Base Run/base' num2str(input_bsn(i)) '_2039.mat'];
                    startcol = 14;
                    endcol   = 26;
                    decade_str = '_30';
                    output_table_bsni_30 = [];
                case 3
                    SWATemfile = [water_data_folder 'Emulator Coefficients/emulator' num2str(input_bsn(i)) '_2049.mat'];
                    basedatafile = [water_data_folder 'Base Run/base' num2str(input_bsn(i)) '_2049.mat'];
                    startcol = 27;
                    endcol   = 39;
                    decade_str = '_40';
                    output_table_bsni_40 = [];
                case 4
                    SWATemfile = [water_data_folder 'Emulator Coefficients/emulator' num2str(input_bsn(i)) '_2059.mat'];                    
                    basedatafile = [water_data_folder 'Base Run/base' num2str(input_bsn(i)) '_2059.mat'];
                    startcol = 40;
                    endcol   = 52;
                    decade_str = '_50';
                    output_table_bsni_50 = [];
            end


            % (c) Load data for SWAT emulator of this basin for this decade
            % -------------------------------------------------------------
            SWATemdata = load(SWATemfile);

            % Landcovers for this decade
            bsni_decj_new_lcs_sbsn = bsni_new_lcs_sbsn(:,startcol:endcol);

            % (d) Initialise arrays
            % ---------------------
            if baserun_ind == 1
                bsn_em_data = cell(1,SWATemdata.nsubbasin);
            else
                load(basedatafile);
            end

            % (e) Run Emulator for first order subbasins
            % ------------------------------------------            
            bsni_finished = false;
            for k = 1:SWATemdata.nfirstorder

                sbsn_order_idx = SWATemdata.firstorder(k);

                % if this subbasin has changed then run emulator to update subbasin IN and OUT
                if bsni_sbsn_chg_ind(sbsn_order_idx) == 1
                   % RUN emulator for firstorder subbasin k in basin i
                   % UPDATE SWATemdata IN & OUT For this subbbasin
                   [sbsn_em_output, bsn_em_data{sbsn_order_idx}] = fcn_emulator_firstorder(SWATemdata, bsni_decj_new_lcs_sbsn(sbsn_order_idx, 3:end), sbsn_order_idx,decade_str);
                   
                   % Record flow output for flood model
                   if bsni_sbsn_out_ind(sbsn_order_idx)
                       switch j
                           case 1
                               flood_src_id = [flood_src_id; [num2str(input_bsn(i)), '_', num2str(sbsn_order_idx)]];
                               flow_20 = [flow_20; bsn_em_data{sbsn_order_idx}.flow'];
                           case 2
                               flow_30 = [flow_30; bsn_em_data{sbsn_order_idx}.flow'];
                           case 3
                               flow_40 = [flow_40; bsn_em_data{sbsn_order_idx}.flow'];
                           case 4
                               flow_50 = [flow_50; bsn_em_data{sbsn_order_idx}.flow'];
                       end
                   end
                end

                if bsni_sbsn_out_ind(sbsn_order_idx) == 1
                     
                   % RECORD OUT data for this subbasin
                   switch j
                       case 1
                           output_table_bsni_20 = [output_table_bsni_20;sbsn_em_output];
                           out_count = out_count + 1;
                           bsni_sbsn_out_sbsn_ids{out_count} = bsni_sbsn_ids{sbsn_order_idx};
                       case 2
                           output_table_bsni_30 = [output_table_bsni_30;sbsn_em_output];
                       case 3
                           output_table_bsni_40 = [output_table_bsni_40;sbsn_em_output];
                       case 4
                           output_table_bsni_50 = [output_table_bsni_50;sbsn_em_output];
                           bsni_sbsn_out_ind(sbsn_order_idx) = 0;
                   end

                   % Check to see if all output subbasins have been processed
                   if sum(bsni_sbsn_out_ind) == 0;
                       bsni_finished = true;
                       break;
                   end
                end

            end

            % (f) Run Emulator for second order subbasins
            % -------------------------------------------      
            if bsni_finished == false

                for k = 1:SWATemdata.nsecondorder

                    sbsn_order_idx       = SWATemdata.secondorder{k}(1);

                    % If 2 feeder subbasins to this subbasin 
                    if length(SWATemdata.secondorder{k}) == 3

                        sbsn_feed1_order_id = SWATemdata.secondorder{k}(2);
                        sbsn_feed2_order_id = SWATemdata.secondorder{k}(3);

                        % if this subbasin has changed or either of its feeders then run emulator to update subbasin IN and OUT
                        if (bsni_sbsn_chg_ind(sbsn_order_idx) == 1) || ...
                           (bsni_sbsn_chg_ind(sbsn_feed1_order_id) == 1) || ...
                           (bsni_sbsn_chg_ind(sbsn_feed2_order_id) == 1)

                           % Add variables from upstream subbasins
                           sbsn_em_fromupstream = fcn_add_upstream_out(bsn_em_data,SWATemdata.secondorder{k});

                           % RUN emulator for secondorder subbasin k in basin i
                           % UPDATE SWATemdata IN * OUT For this subbbasin
                           [sbsn_em_output, bsn_em_data{sbsn_order_idx}] = fcn_emulator_secondorder(SWATemdata,bsni_decj_new_lcs_sbsn(sbsn_order_idx,3:end),sbsn_order_idx,decade_str,sbsn_em_fromupstream);
                           %disp('Changing Landcovers!');

                           % Change indicator to show out for this subbasin has changed
                           bsni_sbsn_chg_ind(sbsn_order_idx) = 1; 
                           
                           % Record flow output for flood model
                           if bsni_sbsn_out_ind(sbsn_order_idx)
                               switch j
                                   case 1
                                       flood_src_id = [flood_src_id; [num2str(input_bsn(i)), '_', num2str(sbsn_order_idx)]];
                                       flow_20 = [flow_20; bsn_em_data{sbsn_order_idx}.flow'];
                                   case 2
                                       flow_30 = [flow_30; bsn_em_data{sbsn_order_idx}.flow'];
                                   case 3
                                       flow_40 = [flow_40; bsn_em_data{sbsn_order_idx}.flow'];
                                   case 4
                                       flow_50 = [flow_50; bsn_em_data{sbsn_order_idx}.flow'];
                               end
                           end
                        end

                    % If 3 feeder subbasins to this subbasin 
                    elseif length(SWATemdata.secondorder{k}) == 4

                        sbsn_feed1_order_id = SWATemdata.secondorder{k}(2);
                        sbsn_feed2_order_id = SWATemdata.secondorder{k}(3);
                        sbsn_feed3_order_id = SWATemdata.secondorder{k}(4);

                        % if this subbasin has changed or either of its feeders then run emulator to update subbasin IN and OUT
                        if (bsni_sbsn_chg_ind(sbsn_order_idx) == 1) || ...
                           (bsni_sbsn_chg_ind(sbsn_feed1_order_id) == 1) || ...
                           (bsni_sbsn_chg_ind(sbsn_feed2_order_id) == 1) || ...
                           (bsni_sbsn_chg_ind(sbsn_feed3_order_id) == 1)

                           % Add variables from upstream subbasins
                           sbsn_em_fromupstream = fcn_add_upstream_out(bsn_em_data,SWATemdata.secondorder{k});

                           % RUN emulator for secondorder subbasin k in basin i
                           % UPDATE SWATemdata IN * OUT For this subbbasin
                           [sbsn_em_output, bsn_em_data{sbsn_order_idx}] = fcn_emulator_secondorder(SWATemdata,bsni_decj_new_lcs_sbsn(sbsn_order_idx,3:end),sbsn_order_idx,decade_str,sbsn_em_fromupstream);

                           % Change indicator to show out for this subbasin has changed
                           bsni_sbsn_chg_ind(sbsn_order_idx) = 1;
                           
                           % Record flow output for flood model
                           if bsni_sbsn_out_ind(sbsn_order_idx)
                               switch j
                                   case 1
                                       flood_src_id = [flood_src_id; [num2str(input_bsn(i)), '_', num2str(sbsn_order_idx)]];
                                       flow_20 = [flow_20; bsn_em_data{sbsn_order_idx}.flow'];
                                   case 2
                                       flow_30 = [flow_30; bsn_em_data{sbsn_order_idx}.flow'];
                                   case 3
                                       flow_40 = [flow_40; bsn_em_data{sbsn_order_idx}.flow'];
                                   case 4
                                       flow_50 = [flow_50; bsn_em_data{sbsn_order_idx}.flow'];
                               end
                           end
                        end

                    end

                    if bsni_sbsn_out_ind(sbsn_order_idx) == 1

                       % RECORD OUT data for this subbasin
                       switch j
                           case 1
                               output_table_bsni_20 = [output_table_bsni_20;sbsn_em_output];
                               out_count = out_count + 1;
                               bsni_sbsn_out_sbsn_ids{out_count} = bsni_sbsn_ids{sbsn_order_idx};
                           case 2
                               output_table_bsni_30 = [output_table_bsni_30;sbsn_em_output];
                           case 3
                               output_table_bsni_40 = [output_table_bsni_40;sbsn_em_output];
                           case 4
                               output_table_bsni_50 = [output_table_bsni_50;sbsn_em_output];
                               bsni_sbsn_out_ind(sbsn_order_idx) = 0;

                       end

                       % Check to see if all output subbasins have been processed
                       if sum(bsni_sbsn_out_ind) == 0;
                           bsni_finished = true;
                           break;
                       end

                    end                    

                end

            end
            % Finished this decade in this basin
            if baserun_ind == 1
                save(basedatafile, 'bsn_em_data','-mat', '-v6');       
            end
        end
        
        % Add subbasin ids to output water data calculated for those 
        % subbasins for each decade
        output_table_bsni = [cell2table(bsni_sbsn_out_sbsn_ids,'VariableNames',{'src_id'}) ...
                             output_table_bsni_20,output_table_bsni_30,output_table_bsni_40,output_table_bsni_50];
        % Join to the subbasin info data which contains the sort order of
        % those subbasins in the request
        output_table_bsni = sortrows(innerjoin(output_table_bsni,bsni_sbsn_out_info), {'sort_order'}, {'ascend'});
        es_water = [es_water; output_table_bsni];
    end
    
    %% (5) CALCULATE WATER FLOOD ES
    
    % Concatenate flow in each decade for flood model
    flow = [flow_20, flow_30, flow_40, flow_50];
    
    % Set up event parameter (1 or 7)
%     event_parameter = 1;
    event_parameter = 7;
    
    % Run flood model
    es_water_flood = fcn_run_water_flood(water_data_folder, flood_src_id, flow, event_parameter);

    %% (6) FORMAT WATER OUTPUTS
    % =========================
    es_water = es_water(:,1:end-1);

end