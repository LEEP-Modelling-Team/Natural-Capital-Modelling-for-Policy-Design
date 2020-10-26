function es_recreation = fcn_run_recreation(rec_data_folder, MP, out, site_type, visval_type, path_agg_method, minsitesize, conn)

    %% NEVO RECREATION MODEL: Vis & Val changes from NEVO alteration
    % ==============================================================
    % Uses working mats from NEVORec1 and NEVORec2 to evaluate the vis and val
    % changes resulting from new land use in NEVO cells.
    % Calculations are done for N lsoas that experience biggest value
    % changes (called 'max' lsoas) from paths and parks in those cells.
    
    % Note: EV0 calculations do not take account of climate change.


    % INPUTS:
    % =======
    %    rec_data_folder: string - path to pre-calculated mat files
    %    out:             matrix - data on id and landcovers in changed cells
    %    site_type:       string - variable indicating nature of recreation type
    %                                'path_chg' - landcover change changes 'green areas' along existing paths
    %                                'path_new' - landcover change area is new recreation site accessed by paths
    %                                'park_new' - landcover change area is new recreation park
    %    visval_type:     string - variable indicating whether vis & val are calculated for each cell as an 
    %                              independent change or for all cells as a simultaneous change
    %                                'simultaneous' - visval for all sites changing at the same time
    %                                'independent'  - visval for each site changing on its own
    %    path_agg_method: string - variable indicating whether change in visits & values to a path in 'park_chg' mode
    %                              are attribute to the cells experiencing landcover change or to all cells traversed
    %                              by that path
    %                                'agg_to_impacted_cells' - change in vis & val to path attributed to all cells traveresed by that path
    %                                'agg_to_changed_cells'  - change in vis & val to path attributed to changed cells
    %    minsitesize:     numeric - variable indicating the minimum area of landcover change in a cell that could be considered big enough to 
    %                               constitute a new site (in hectares)

    
    %% (1) NEVO INPUT
    % ===============
    % Contains cell ids and area in each cell under Wood, Agric, Managed Grass,
    % Semi-Natural Grass. Calculation of Rec Model Categories from NEVO Categories:
    %    Wood          = Woodland
    %    Agriculture   = Crops
    %    Managed Grass = Permanent Grassland + Temporary Grassland
    %    Natural Grass = Rough Grazing + Semi-Natural Grassland    
    %
    % NEVO_input Columns:
    %    1  new2kid    - cell ids of changed cells
    %   2020s:
    %    2   cell_wd  - ha in wood
    %    3   cell_ag  - ha in agriculture
    %    4   cell_mg  - ha in managed grass
    %    5   cell_ng  - ha in natural grass
    %   2030s
    %    6 - 9
    %   2040s
    %    10 - 13
    %   2050s
    %    14 - 17

    NEVO_input = [out.new2kid ...
    out.wood_ha ...
    out.arable_ha_20 ...
    out.pgrass_ha_20+out.tgrass_ha_20 ...
    out.rgraz_ha_20+out.sngrass_ha ...
    out.wood_ha ...
    out.arable_ha_30 ...
    out.pgrass_ha_30+out.tgrass_ha_30 ...
    out.rgraz_ha_30+out.sngrass_ha ...
    out.wood_ha ...
    out.arable_ha_40 ...
    out.pgrass_ha_40+out.tgrass_ha_40 ...
    out.rgraz_ha_40+out.sngrass_ha ...
    out.wood_ha ...
    out.arable_ha_50 ...
    out.pgrass_ha_50+out.tgrass_ha_50 ...
    out.rgraz_ha_50+out.sngrass_ha];


    %% (2) INTITIALISE
    % ================

    % (2.a) Constants
    % ---------------
    ndecades  = 4;
    nsegs     = 4;
    nlsoasave = 50;    
    
    % (2.b) Model
    % -----------    
    model.type = 'mnl3';     


    %% (3) NEW PATH OR PARK
    % =====================
    if strcmp(site_type,'path_new')||strcmp(site_type,'park_new')

        % (3.a) Open required files in NEVO_ORVal_newsite_data:
        % -----------------------------------------------------
        NEVO_ORVal_newsite_data_mat = strcat(rec_data_folder, 'NEVO_ORVal_newsite_data.mat');
        NEVO_ORVal_newsite_data     = load(NEVO_ORVal_newsite_data_mat);

        
        % (3.b) Area of new recreation site
        % ---------------------------------
        % Assume area changed to new woodland or new natural grass is extent of new recreation site

        % Index of cell ids in input data in NEVO_base_sumlcs (sum of green lcs in that cell in the baseline)
        [~,Inputcell_in_Allcell_idx] = ismember(NEVO_input(:,1), NEVO_ORVal_newsite_data.NEVO_base_lcs(:,1));

        % Base landcovers stored in NEVO_base_lcs: col 1 - spid, col 2 - woods, col 5 - sngrass
        % Calculate the change from the base of new woods and sngrass in each period
        NEVO_new_sites_20 = NEVO_input(:, [ 2  5]) - NEVO_ORVal_newsite_data.NEVO_base_lcs(Inputcell_in_Allcell_idx, [ 2  5]);
        NEVO_new_sites_30 = NEVO_input(:, [ 6  9]) - NEVO_ORVal_newsite_data.NEVO_base_lcs(Inputcell_in_Allcell_idx, [ 6  9]);
        NEVO_new_sites_40 = NEVO_input(:, [10 13]) - NEVO_ORVal_newsite_data.NEVO_base_lcs(Inputcell_in_Allcell_idx, [10 13]);
        NEVO_new_sites_50 = NEVO_input(:, [14 17]) - NEVO_ORVal_newsite_data.NEVO_base_lcs(Inputcell_in_Allcell_idx, [14 17]);
        
        % Ensure only positive increases in woods & sngrass are counted as new sites
        NEVO_new_sites_20 = NEVO_new_sites_20 .* (NEVO_new_sites_20 > 0);
        NEVO_new_sites_30 = NEVO_new_sites_30 .* (NEVO_new_sites_30 > 0);
        NEVO_new_sites_40 = NEVO_new_sites_40 .* (NEVO_new_sites_40 > 0);
        NEVO_new_sites_50 = NEVO_new_sites_50 .* (NEVO_new_sites_50 > 0);

        % Calculate new site area
        NEVO_new_sites_area = [sum(NEVO_new_sites_20,2) ...
                               sum(NEVO_new_sites_30,2) ...
                               sum(NEVO_new_sites_40,2) ...
                               sum(NEVO_new_sites_50,2)];

        % Identify sites above minimum size
        NEVO_new_sites_below_min_area = (NEVO_new_sites_area < minsitesize);
        
        NEVO_new_sites_area  =  [NEVO_input(:,1) NEVO_new_sites_area];
                            
        % (3.c) Landcover proportions of new recreation site
        % --------------------------------------------------
        % Calculate percentage of new site under different landcovers
        NEVO_new_sites_lcs_pcts = [NEVO_input(:,1) ...
                                   NEVO_new_sites_20 ./ NEVO_new_sites_area(:,2) ...
                                   NEVO_new_sites_30 ./ NEVO_new_sites_area(:,3) ...
                                   NEVO_new_sites_40 ./ NEVO_new_sites_area(:,4) ...
                                   NEVO_new_sites_50 ./ NEVO_new_sites_area(:,5)];

        % Now correct area if dealing with a path
        if strcmp(site_type,'path_new')

            % Calculate path length in m as perimeter of circle with this site area (maximum length 10km)
            pathlen  = min(2*pi*sqrt(NEVO_new_sites_area(:,2:5)*10000/pi), 10000);

            % Assume 1.5 grid cells width and multiply by area of grid cell, ignore distance decay
            patharea = 1.5 * (pathlen/25) * 0.0625;
            NEVO_new_sites_area = [NEVO_new_sites_area(:,1) patharea];

        end

                               
        % (3.d) v1 for new recreation sites in each decade
        % ------------------------------------------------
        nevo_include_read_params; 
        
        % v1: Landcovers & Area for each decade
        v1lc(:,1) = nevo_function_calculate_v1_lc(site_type, NEVO_new_sites_lcs_pcts(:,[2 3]), NEVO_new_sites_area(:,2), [], [], [], params);
        v1lc(:,2) = nevo_function_calculate_v1_lc(site_type, NEVO_new_sites_lcs_pcts(:,[4 5]), NEVO_new_sites_area(:,3), [], [], [], params);
        v1lc(:,3) = nevo_function_calculate_v1_lc(site_type, NEVO_new_sites_lcs_pcts(:,[6 7]), NEVO_new_sites_area(:,4), [], [], [], params);
        v1lc(:,4) = nevo_function_calculate_v1_lc(site_type, NEVO_new_sites_lcs_pcts(:,[8 9]), NEVO_new_sites_area(:,5), [], [], [], params);

        % v1: Designation & type    
        %[~,Inputcell_in_Allcell_idx] = ismember(NEVO_input(:,1), NEVO_ORVal_newsite_data.NEVO_cell_newsite_v1dg(:,1));
        nsites_new  = length(Inputcell_in_Allcell_idx);

        if strcmp(site_type,'path_new')
            v1 = v1lc + NEVO_ORVal_newsite_data.NEVO_cell_newsite_v1dg(Inputcell_in_Allcell_idx, 2);
        else
            v1 = v1lc + NEVO_ORVal_newsite_data.NEVO_cell_newsite_v1dg(Inputcell_in_Allcell_idx, 3);        
        end 

        % (3.e) v0 and lsoa pops for 'max' lsoas
        % --------------------------------------
        lsoapop_byseg = cell(nsegs,1);
        expv0_byseg   = cell(nsegs,1);
        for i = 1:nsegs    
           lsoapop_byseg{i} = squeeze(NEVO_ORVal_newsite_data.max_newsite_lsoapop(:,i,Inputcell_in_Allcell_idx))';
           expv0_byseg{i}   = squeeze(NEVO_ORVal_newsite_data.max_newsite_ev0(:,i,Inputcell_in_Allcell_idx))';       
        end

        % (3.f) visval calculations
        % -------------------------
        val_site    = zeros(nsites_new,nsegs,ndecades);
        vis_site    = zeros(nsites_new,nsegs,ndecades);
        viscar_site = zeros(nsites_new,ndecades);
        viswlk_site = zeros(nsites_new,ndecades);

        bTCcar   = cell2mat(params(strcmp(params(:,1),'TCCAR'), 2));

        for i = 1:ndecades

            % i. Calculate expv1 for changed (and base) paths
            % -----------------------------------------------
            expv1cari_new = exp(NEVO_ORVal_newsite_data.max_newsite_v1tccar(Inputcell_in_Allcell_idx,:) + v1(:,i));
            expv1wlki_new = exp(NEVO_ORVal_newsite_data.max_newsite_v1tcwlk(Inputcell_in_Allcell_idx,:) + v1(:,i));

            % ii. Set exp(v1) to 0 for sites below minimum size
            % -------------------------------------------------
            expv1cari_new(NEVO_new_sites_below_min_area(:,i),:) = 0;
            expv1wlki_new(NEVO_new_sites_below_min_area(:,i),:) = 0;

            % iii. Find base Sumexpv1 in each LSOA impacted by new site in cells for this decade
            % ----------------------------------------------------------------------------------
            Sumexpv1_base = squeeze(NEVO_ORVal_newsite_data.max_newsite_Sumexpv1(Inputcell_in_Allcell_idx,:,i));


            % iv. Calculate new Sumexpv1 for each LSOA impacted by new site in cells
            % ----------------------------------------------------------------------
            if strcmp(visval_type, 'independent')            
                
                Sumexpv1_new = Sumexpv1_base + expv1cari_new + expv1wlki_new;
            
            elseif strcmp(visval_type, 'simultaneous')
                % Each lsoa may be in top N for many new sites. If assume simultaneous provision of new sites
                % need to add on other sites to Sumexpv1 (denominator) for calculation of vis and val for each lsoa       
                
                % Vectorise Sumexpv1_base 
                Sumexpv1_base_vec = Sumexpv1_base(:);

                % Unique LSOAa with indices to first instance and order in vectorised matrix
                % Unique vectorises input (list of all lsoas using their index number rather than original id number)
                %
                [lsoa_ids,lsoa_rev_idx,lsoa_idx] = unique(NEVO_ORVal_newsite_data.max_newsite_Index(Inputcell_in_Allcell_idx,:));


                % Base Sumexpv1 is the same for this lsoa for all new sites so use reverse
                % index just to pull out first example of this sum
                Sumexpv1_new  = Sumexpv1_base_vec(lsoa_rev_idx) + accumarray(lsoa_idx,expv1cari_new(:),[],@nansum) + accumarray(lsoa_idx,expv1wlki_new(:),[],@nansum);

                % Now reconstruct to original nsite x nlsoa dimensions
                % NOTE: Sumexpv1_new is also the same across repeated lsoas
                Sumexpv1_new = reshape(Sumexpv1_new(lsoa_idx),[],nlsoasave);
               
            end

            
            % v. vis and val calculations
            % ---------------------------
            for j = 1:nsegs

                Sumexpv_new  = expv0_byseg{j} + Sumexpv1_new;
                Sumexpv_base = expv0_byseg{j} + Sumexpv1_base;

                % Visits to each new site from each 'max' lsoa
                viscarij_lsoa_site = (expv1cari_new./Sumexpv_new) .* lsoapop_byseg{j} * 365;
                viswlkij_lsoa_site = (expv1wlki_new./Sumexpv_new) .* lsoapop_byseg{j} * 365;

                if strcmp(visval_type, 'simultaneous')
                    % Total new visits from each lsoa to different new cell sites
                    visij_lsoa = accumarray(lsoa_idx,viscarij_lsoa_site(:) + viswlkij_lsoa_site(:), [], @nansum);
                    % Proportion of lsoa visits going to each different cell site
                    visij_lsoa_site_prop = (viscarij_lsoa_site(:) + viswlkij_lsoa_site(:))./visij_lsoa(lsoa_idx);
                    visij_lsoa_site_prop = reshape(visij_lsoa_site_prop,[],nlsoasave);
                end                

                % Sum visits from 'max' lsoa to each new site
                viscarij_site   = sum(viscarij_lsoa_site,2);
                viswlkij_site   = sum(viswlkij_lsoa_site,2);

                % Accumulate car and walk visits to new sites across segs
                viscar_site(:,i) = viscar_site(:,i) + viscarij_site;
                viswlk_site(:,i) = viswlk_site(:,i) + viswlkij_site;

                % Visits to new site by segment (and decade)
                vis_site(:,j,i) =  viscarij_site + viswlkij_site;

                % Value:
                valij_lsoa_site = (1/-bTCcar)*(((log(Sumexpv_new) - log(Sumexpv_base))) .* lsoapop_byseg{j}) * 365;
                if strcmp(visval_type, 'simultaneous')
                    % When simultaneous valuation, value of set of new sites is the same for 
                    % each lsoa so allocate that value across sites in proportion to visitation
                    valij_lsoa_site = valij_lsoa_site .* visij_lsoa_site_prop;
                end
                val_site(:,j,i)  = sum(valij_lsoa_site,2);
                                
            end

        end

        % (3.g) Organise changes by cell for return to NEVO
        % -------------------------------------------------
        visval_chg_cells = [NEVO_input(:,1)  ...
                            viscar_site      ...
                            viswlk_site      ...
                            vis_site(:,:,1)  ...
                            vis_site(:,:,2)  ...
                            vis_site(:,:,3)  ...
                            vis_site(:,:,4)  ...
                            val_site(:,:,1)  ...
                            val_site(:,:,2)  ...
                            val_site(:,:,3)  ...
                            val_site(:,:,4)];   
        
        visval_base = NEVO_ORVal_newsite_data.visval;

    end


    %% (4) CHANGED PATH
    % =================
    if strcmp(site_type,'path_chg')

        % (4.a) Open required files in NEVO_ORVal_newsite_data:
        % -----------------------------------------------------
        NEVO_ORVal_chgsite_data_mat = strcat(rec_data_folder, 'NEVO_ORVal_chgsite_data.mat');
        NEVO_ORVal_chgsite_data     = load(NEVO_ORVal_chgsite_data_mat); 
    

        % (4.b) Translate NEVO input cell landcovers to ORVal path landcovers
        % -------------------------------------------------------------------
 
        % (4.b.1) NEVO cell areas to percentages
        % --------------------------------------
        % Index of cell ids in input data in NEVO_base_sumlcs (sum of green lcs in that cell in the baseline)
        [~,Inputcell_in_Allcell_idx] = ismember(NEVO_input(:,1), NEVO_ORVal_chgsite_data.NEVO_base_sumlcs(:,1));
        
        % New landcovers to percentage of base green land area. If urban has
        % expanded then percentages no longer sum to 1 
        NEVO_new_lcs_pcts = [NEVO_input(:,1) ... 
                             NEVO_input(:,2:5)./NEVO_ORVal_chgsite_data.NEVO_base_sumlcs(Inputcell_in_Allcell_idx,2)  ... 
                             NEVO_input(:,6:9)./NEVO_ORVal_chgsite_data.NEVO_base_sumlcs(Inputcell_in_Allcell_idx,3)  ...
                             NEVO_input(:,10:13)./NEVO_ORVal_chgsite_data.NEVO_base_sumlcs(Inputcell_in_Allcell_idx,4)  ...
                             NEVO_input(:,14:17)./NEVO_ORVal_chgsite_data.NEVO_base_sumlcs(Inputcell_in_Allcell_idx,5)];
        
        if strcmp(path_agg_method, 'agg_to_changed_cells')
            % Proportion of green area experiencing lc change in each changed cell
            NEVO_base_lcs_pcts = NEVO_ORVal_chgsite_data.NEVO_base_lcs_pcts(Inputcell_in_Allcell_idx,:);
            NEVO_chg_lcs_pcts  = (NEVO_base_lcs_pcts(:,2:17) - NEVO_new_lcs_pcts(:,2:17));
            % Sum postive % changes to get magnitude of change
            NEVO_chg_lcs_pcts  = NEVO_chg_lcs_pcts .* (NEVO_chg_lcs_pcts > 0);
            NEVO_chg_lcs_pcts  = [NEVO_input(:,1) ...
                                  sum(NEVO_chg_lcs_pcts(:,1:4),2) ...
                                  sum(NEVO_chg_lcs_pcts(:,5:8),2) ...
                                  sum(NEVO_chg_lcs_pcts(:,9:12),2) ...
                                  sum(NEVO_chg_lcs_pcts(:,13:16),2)];
        end

        % (4.b.2) Construct table of base lcs in cells crossed by paths in changed cells
        % ------------------------------------------------------------------------------

        % i. Find spids of paths in changed land cells
        % --------------------------------------------
        % Find cells in ORVal_paths_cells that are in NEVO_input, select out path 
        % spids within these cells then reduce to unique spids
        %  ORVal_paths_cells columns:
        %    1     new2kid      cell id
        %    2     spid         path id
        %    3     patharea     total area of path across all cells
        %    4     cellarea_lc  area under wd, ag, ng, mg within cell (urban and water not included)
        %    5     path_pct     percentage of total path area within cell
        chg_paths_spids = unique(NEVO_ORVal_chgsite_data.ORVal_paths_cells(ismember(NEVO_ORVal_chgsite_data.ORVal_paths_cells(:,1), NEVO_input(:,1)), 2));
        npaths_chg      = length(chg_paths_spids);

        % ii. Select all cells containing these spids
        % -------------------------------------------
        % Since path can go beyond changed cells, select out cells that contain
        % path that cross changed changed cells
        chg_paths_cells  = NEVO_ORVal_chgsite_data.ORVal_paths_cells(ismember(NEVO_ORVal_chgsite_data.ORVal_paths_cells(:,2), chg_paths_spids), :);

        % iii. Join NEVO base landcovers pcts to the data on these cells
        % --------------------------------------------------------------
        % Find index of cells in matrix holding base lc pcts and add pcts cols to
        % new_path_cells table
        %  NEVO_base_lcs_pcts columns:
        %    1      new2kid    cell id
        %    2-5    pct_lc 20  percentage in each green landcover in 20s
        %    6-9    pct_lc 30  percentage in each green landcover in 30s
        %    10-13  pct_lc 40  percentage in each green landcover in 40s
        %    14-17  pct_lc 50  percentage in each green landcover in 50s
        [~, Chgpathcells_in_Allcells_idx]   = ismember(chg_paths_cells(:,1), NEVO_ORVal_chgsite_data.NEVO_base_lcs_pcts(:,1));
        chg_paths_cells = [chg_paths_cells NEVO_ORVal_chgsite_data.NEVO_base_lcs_pcts(Chgpathcells_in_Allcells_idx,2:17)];
        %  joined table - chg_paths_cells columns:
        %    1     new2kid       cell id
        %    2     spid          path id
        %    3     path_pct      percentage of total path area within cell
        %    4     patharea      total area of path across all cells
        %    5     cellarea_lc   area under wd, ag, ng, mg within cell (urban and water not included) in baseline
        %    6-9   pct_lc 20     percentage in each green landcover in 20s
        %    10-13 pct_lc 30     percentage in each green landcover in 30s
        %    14-17 pct_lc 40     percentage in each green landcover in 40s
        %    18-21 pct_lc 50     percentage in each green landcover in 50s

        % (4.b.3) Update base landcover pct to NEVO input landcover pcts
        % --------------------------------------------------------------
        [Inputcells_in_Chgpathcells_ind, Inputcells_in_Chgpathcells_idx]      = ismember(chg_paths_cells(:,1), NEVO_new_lcs_pcts(:,1));
        chg_paths_cells(Inputcells_in_Chgpathcells_ind,6:21) = NEVO_new_lcs_pcts(Inputcells_in_Chgpathcells_idx(Inputcells_in_Chgpathcells_ind),2:17);


        % (4.b.4) Calculate has of each landcover along each Path Segment under new NEVO landcovers (pcts * cellarea_lc)
        % --------------------------------------------------------------------------------------------------------------
        paths_cells_new_lc_has = chg_paths_cells(:,6:21).*chg_paths_cells(:,5); 


        % (4.b.5) Accumulate lcs from each path-segment in different cells to give path lc totals
        % ---------------------------------------------------------------------------------------    
        [chg_paths_spids,idxa,idxb] = unique(chg_paths_cells(:,2));

        for jj = size(paths_cells_new_lc_has,2):-1:1 % Count backwards for dynamic preallocation
            chg_paths_lcs_has(:,jj) = accumarray(idxb, paths_cells_new_lc_has(:,jj));
        end

        chg_paths_patharea = chg_paths_cells(idxa,4);
        chg_paths_lcs_pct  = chg_paths_lcs_has./chg_paths_patharea; % Percent of whole path area under 4 green landcovers


        % (4.c) Calculate v1 for each ORVal Path with new landcovers
        % ----------------------------------------------------------

        % (4.c.1) ORVal LC Parameters
        % ---------------------------
        nevo_include_read_params; 

        % (4.c.2) Calculate new expv1 with new landcovers
        % -----------------------------------------------
        % Index of path_spids in full list of ORVal spids
        [~, path_idx] = ismember(chg_paths_spids,NEVO_ORVal_chgsite_data.ORVal_site.spid);

        v1lc(:,1) = nevo_function_calculate_v1_lc(site_type, chg_paths_lcs_pct(:,1:4),  chg_paths_patharea, NEVO_ORVal_chgsite_data.ORVal_site.divxlc(path_idx), NEVO_ORVal_chgsite_data.ORVal_site.div_pct(path_idx), [NEVO_ORVal_chgsite_data.ORVal_site.fw_pct(path_idx) NEVO_ORVal_chgsite_data.ORVal_site.sw_pct(path_idx)], params);
        v1lc(:,2) = nevo_function_calculate_v1_lc(site_type, chg_paths_lcs_pct(:,5:8),  chg_paths_patharea, NEVO_ORVal_chgsite_data.ORVal_site.divxlc(path_idx), NEVO_ORVal_chgsite_data.ORVal_site.div_pct(path_idx), [NEVO_ORVal_chgsite_data.ORVal_site.fw_pct(path_idx) NEVO_ORVal_chgsite_data.ORVal_site.sw_pct(path_idx)], params);
        v1lc(:,3) = nevo_function_calculate_v1_lc(site_type, chg_paths_lcs_pct(:,9:12), chg_paths_patharea, NEVO_ORVal_chgsite_data.ORVal_site.divxlc(path_idx), NEVO_ORVal_chgsite_data.ORVal_site.div_pct(path_idx), [NEVO_ORVal_chgsite_data.ORVal_site.fw_pct(path_idx) NEVO_ORVal_chgsite_data.ORVal_site.sw_pct(path_idx)], params);
        v1lc(:,4) = nevo_function_calculate_v1_lc(site_type, chg_paths_lcs_pct(:,13:16),chg_paths_patharea, NEVO_ORVal_chgsite_data.ORVal_site.divxlc(path_idx), NEVO_ORVal_chgsite_data.ORVal_site.div_pct(path_idx), [NEVO_ORVal_chgsite_data.ORVal_site.fw_pct(path_idx) NEVO_ORVal_chgsite_data.ORVal_site.sw_pct(path_idx)], params);


        % (4.d) Calculate change in visits and values to paths with alterations
        % ---------------------------------------------------------------------
        [~,spid_idx] = ismember(chg_paths_spids,NEVO_ORVal_chgsite_data.max_spid);
        [lsoa_ids,lsoa_rev_idx,lsoa_idx] = unique(NEVO_ORVal_chgsite_data.max_Index(spid_idx,:));

        % (4.d.1) Find expv0 & pop for 'max' lsoas for altered paths
        % ----------------------------------------------------------
        lsoapop_byseg = cell(nsegs,1);
        expv0_byseg   = cell(nsegs,1);
        for i = 1:nsegs    
           lsoapop_byseg{i} = squeeze(NEVO_ORVal_chgsite_data.max_lsoapop(:,i,spid_idx))';
           expv0_byseg{i}   = squeeze(NEVO_ORVal_chgsite_data.max_ev0(:,i,spid_idx))';       
        end

        % (4.d.2) Change in visits and values for altered paths by segment and decade
        % -----------------------------------------------------------------
        val_path    = zeros(npaths_chg,nsegs,ndecades);
        vis_path    = zeros(npaths_chg,nsegs,ndecades);
        viscar_path = zeros(npaths_chg,ndecades);
        viswlk_path = zeros(npaths_chg,ndecades);

        bTCcar   = cell2mat(params(strcmp(params(:,1),'TCCAR'), 2));

        for i = 1:ndecades

            % i. Calculate expv1 for changed (and base) paths
            % -----------------------------------------------
            expv1cari_new  = exp(squeeze(NEVO_ORVal_chgsite_data.max_v1carxlc(:,i,spid_idx))' + v1lc(:,i));
            expv1wlki_new  = exp(squeeze(NEVO_ORVal_chgsite_data.max_v1wlkxlc(:,i,spid_idx))' + v1lc(:,i));

            expv1cari_base = squeeze(NEVO_ORVal_chgsite_data.max_expv1cari_base(:,i,spid_idx))';
            expv1wlki_base = squeeze(NEVO_ORVal_chgsite_data.max_expv1wlki_base(:,i,spid_idx))';

            % ii. Calculate new Sumexpv1 for each lsoa
            % ----------------------------------------
            Sumexpv1car_base = squeeze(NEVO_ORVal_chgsite_data.max_Sumexpv1car_base(:,i,spid_idx))';
            Sumexpv1wlk_base = squeeze(NEVO_ORVal_chgsite_data.max_Sumexpv1wlk_base(:,i,spid_idx))';

            if strcmp(visval_type, 'independent')             
            
                Sumexpv1car_new = Sumexpv1car_base - expv1cari_base + expv1cari_new;
                Sumexpv1wlk_new = Sumexpv1wlk_base - expv1wlki_base + expv1wlki_new;
                
            elseif strcmp(visval_type, 'simultaneous')
                % Each lsoa may be in top N for many changed paths so accumulating by
                % lsoa to find sum of base expv1 and taking away sum of new expv1 for each lsoa.
                
                Sumexpv1car_base_vec = Sumexpv1car_base(:);
                Sumexpv1wlk_base_vec = Sumexpv1wlk_base(:);

                % Base Sumexpv1 is the same for this lsoa in all spids so use reverse
                % index just to pull out first example of this sum
                Sumexpv1car_new  = Sumexpv1car_base_vec(lsoa_rev_idx) - accumarray(lsoa_idx,expv1cari_base(:)) + accumarray(lsoa_idx,expv1cari_new(:));
                Sumexpv1wlk_new  = Sumexpv1wlk_base_vec(lsoa_rev_idx) - accumarray(lsoa_idx,expv1wlki_base(:)) + accumarray(lsoa_idx,expv1wlki_new(:));

                % Now reconstruct to original npath x nlsoa dimensions
                % (same for the same lsoa for each changed path)
                Sumexpv1car_new = reshape(Sumexpv1car_new(lsoa_idx),[],nlsoasave);
                Sumexpv1wlk_new = reshape(Sumexpv1wlk_new(lsoa_idx),[],nlsoasave);                

            end

            % iii. Accumulate visval across 'max' lsoas for each path
            % -------------------------------------------------------
            for j = 1:nsegs

                Sumexpv_new  = expv0_byseg{j} + Sumexpv1car_new  + Sumexpv1wlk_new;
                Sumexpv_base = expv0_byseg{j} + Sumexpv1car_base + Sumexpv1wlk_base;

               % Additional visits to each changed path from each 'max' lsoa
                viscarij_lsoa_path = (expv1cari_new./Sumexpv_new - expv1cari_base./Sumexpv_base) .* lsoapop_byseg{j} * 365;
                viswlkij_lsoa_path = (expv1wlki_new./Sumexpv_new - expv1wlki_base./Sumexpv_base) .* lsoapop_byseg{j} * 365;

                if strcmp(visval_type, 'simultaneous')
                    % Total new visits from each lsoa to altered paths
                    visij_lsoa = accumarray(lsoa_idx, viscarij_lsoa_path(:) + viswlkij_lsoa_path(:), [], @nansum);
                    % Proportion of lsoa visits going to each different cell site
                    visij_lsoa_path_prop = (viscarij_lsoa_path(:) + viswlkij_lsoa_path(:))./visij_lsoa(lsoa_idx);
                    visij_lsoa_path_prop = reshape(visij_lsoa_path_prop,[],nlsoasave);
                end                

                % Sum change in visits from 'max' lsoa to each altered
                viscarij_path   = sum(viscarij_lsoa_path,2);
                viswlkij_path   = sum(viswlkij_lsoa_path,2);

                % Accumulate car and walk visits to new sites across segs
                viscar_path(:,i) = viscar_path(:,i) + viscarij_path;
                viswlk_path(:,i) = viswlk_path(:,i) + viswlkij_path;

                % Visits to new site by segment (and decade)
                vis_path(:,j,i) =  viscarij_path + viswlkij_path;
                
                % Value:
                valij_lsoa_path = (1/-bTCcar)*(((log(Sumexpv_new) - log(Sumexpv_base))) .* lsoapop_byseg{j}) * 365;
                if strcmp(visval_type, 'simultaneous')
                    % When simultaneous valuation, value of set of altered paths is the same for 
                    % each lsoa, so allocate that value across sites in proportion to visitation
                    valij_lsoa_path = valij_lsoa_path .* visij_lsoa_path_prop;
                end
                val_path(:,j,i)  = sum(valij_lsoa_path,2);
                
            end    
            
        end
                
        % (4.e) Translate visits and values from path sites to cells
        % ----------------------------------------------------------

        % (4.e.1) Find Cells containing altered paths
        % -------------------------------------------
        
        if strcmp(path_agg_method, 'agg_to_impacted_cells') 
            
            % Reduce to set of cells traversed by paths that go through a cell with landcover changed
            paths_cells = NEVO_ORVal_chgsite_data.ORVal_paths_cells(ismember(NEVO_ORVal_chgsite_data.ORVal_paths_cells(:,2), chg_paths_spids),:);
            
            % Portion of path in each cell it traverses
            visval_cell_prop = paths_cells(:,3);
            visval_cell_prop = repmat(visval_cell_prop, 1, ndecades);
                        
            [~, path_idx] = ismember(paths_cells(:,2), chg_paths_spids);
            [pathids,path_rev_idx,path_idx] = unique(paths_cells(:,2));
            
        elseif strcmp(path_agg_method, 'agg_to_changed_cells')
            
            % Reduce to set of cells where landcover changed
            paths_cells = NEVO_ORVal_chgsite_data.ORVal_paths_cells(ismember(NEVO_ORVal_chgsite_data.ORVal_paths_cells(:,1), NEVO_input(:,1)),:);
            
            % Index of cells in path_cells 
            [~,cell_idx] = ismember(paths_cells(:,1), NEVO_input(:,1));
            
            % Score is path area in cell x quantity of change of landcover in cell
            visval_cell_prop = (paths_cells(:,3) .* NEVO_chg_lcs_pcts(cell_idx,2:5));
            
            % Calculate approprtionment of change across changing cells that are traversed by same path
            [pathids,path_rev_idx,path_idx] = unique(paths_cells(:,2));

            for i = 1:ndecades
                % Find total score for path
                visval_cell_prop_total = accumarray(path_idx, visval_cell_prop(:,i));
                visval_cell_prop(:,i)  = visval_cell_prop(:,i)./visval_cell_prop_total(path_idx);
            end
            
        end        
        
        % (4.e.2) Organise path visvals into NEVO format and add cell id
        % --------------------------------------------------------------       
        visval_chg_paths_cells = [paths_cells(:, 1) ...
                                  viscar_path(path_idx,:) .* visval_cell_prop  ...
                                  viswlk_path(path_idx,:) .* visval_cell_prop  ...
                                  vis_path(path_idx,:,1)  .* visval_cell_prop(:,1) ...
                                  vis_path(path_idx,:,2)  .* visval_cell_prop(:,2) ...
                                  vis_path(path_idx,:,3)  .* visval_cell_prop(:,3) ...
                                  vis_path(path_idx,:,4)  .* visval_cell_prop(:,4) ...
                                  val_path(path_idx,:,1)  .* visval_cell_prop(:,1) ...
                                  val_path(path_idx,:,2)  .* visval_cell_prop(:,2) ...
                                  val_path(path_idx,:,3)  .* visval_cell_prop(:,3)  ...
                                  val_path(path_idx,:,4)  .* visval_cell_prop(:,4) ];
        
                              
        % (4.e.2) Aggregate vis and vals by cell
        % --------------------------------------              
        [cellids,~,cell_idx] = unique(visval_chg_paths_cells(:,1));
        visval_chg_cells = [cellids zeros(size(cellids,1),size(visval_chg_paths_cells,2)-1)];
        for jj = 2:size(visval_chg_cells,2)
            visval_chg_cells(:,jj) = accumarray(cell_idx, visval_chg_paths_cells(:,jj));
        end

        visval_base = NEVO_ORVal_chgsite_data.visval;
        
    end
    
    %% (5) COLLECT VISIT & VALUE ESTIMATES FOR RETURN TO NEVO
    % =======================================================

    % (5.1) Make Path, Park & Beach VisVal tables
    % -------------------------------------------
    visval_chg = [ visval_chg_cells(:,1) ...
                   visval_chg_cells(:,2:5)+visval_chg_cells(:,6:9) ...
                   visval_chg_cells(:,2:5)  ...
                   visval_chg_cells(:,6:9)  ...
                   visval_chg_cells(:,10:13) ...
                   visval_chg_cells(:,14:17) ...
                   visval_chg_cells(:,18:21) ...
                   visval_chg_cells(:,22:25) ...
                   sum(visval_chg_cells(:,26:29),2) sum(visval_chg_cells(:,30:33),2) sum(visval_chg_cells(:,34:37),2) sum(visval_chg_cells(:,38:41),2) ...
                   visval_chg_cells(:,26:29) ...
                   visval_chg_cells(:,30:33) ...
                   visval_chg_cells(:,34:37) ...
                   visval_chg_cells(:,38:41) ];

    % (5.2) Select appropriate column names
    % -------------------------------------
    if strcmp(site_type, 'park_new')
        colnames = {'prk_vis_20',   'prk_vis_30',   'prk_vis_40',   'prk_vis_50',    ...
                    'prk_viscar_20','prk_viscar_30','prk_viscar_40','prk_viscar_50', ...
                    'prk_viswlk_20','prk_viswlk_30','prk_viswlk_40','prk_viswlk_50', ...
                    'prk_visab_20', 'prk_visc1_20', 'prk_visc2_20', 'prk_visde_20',  ...
                    'prk_visab_30', 'prk_visc1_30', 'prk_visc2_30', 'prk_visde_30',  ...
                    'prk_visab_40', 'prk_visc1_40', 'prk_visc2_40', 'prk_visde_40',  ...
                    'prk_visab_50', 'prk_visc1_50', 'prk_visc2_50', 'prk_visde_50',  ...
                    'prk_val_20',   'prk_val_30',   'prk_val_40',   'prk_val_50',    ...
                    'prk_valab_20', 'prk_valc1_20', 'prk_valc2_20', 'prk_valde_20',  ...
                    'prk_valab_30', 'prk_valc1_30', 'prk_valc2_30', 'prk_valde_30',  ...
                    'prk_valab_40', 'prk_valc1_40', 'prk_valc2_40', 'prk_valde_40',  ...
                    'prk_valab_50', 'prk_valc1_50', 'prk_valc2_50', 'prk_valde_50'};
    else
        colnames = {'pth_vis_20',   'pth_vis_30',   'pth_vis_40',   'pth_vis_50',    ...
                    'pth_viscar_20','pth_viscar_30','pth_viscar_40','pth_viscar_50', ...
                    'pth_viswlk_20','pth_viswlk_30','pth_viswlk_40','pth_viswlk_50', ...
                    'pth_visab_20', 'pth_visc1_20', 'pth_visc2_20', 'pth_visde_20',  ...
                    'pth_visab_30', 'pth_visc1_30', 'pth_visc2_30', 'pth_visde_30',  ...
                    'pth_visab_40', 'pth_visc1_40', 'pth_visc2_40', 'pth_visde_40',  ...
                    'pth_visab_50', 'pth_visc1_50', 'pth_visc2_50', 'pth_visde_50',  ...
                    'pth_val_20',   'pth_val_30',   'pth_val_40',   'pth_val_50',    ...
                    'pth_valab_20', 'pth_valc1_20', 'pth_valc2_20', 'pth_valde_20',  ...
                    'pth_valab_30', 'pth_valc1_30', 'pth_valc2_30', 'pth_valde_30',  ...
                    'pth_valab_40', 'pth_valc1_40', 'pth_valc2_40', 'pth_valde_40',  ...
                    'pth_valab_50', 'pth_valc1_50', 'pth_valc2_50', 'pth_valde_50'};
    end
    
    % (5.3) Base visval for visval cells
    % ----------------------------------
    if strcmp(site_type, 'path_chg') && strcmp(path_agg_method, 'agg_to_impacted_cells')
        % Set of impacted cells may stretch beyond those where landcover has changed that are provided as NEVO_input
        es_recreation = outerjoin(array2table(visval_chg(:,1),'VariableNames',{'new2kid'}),visval_base,'MergeKeys',true,'Type','left');
    else
        es_recreation = outerjoin(array2table(NEVO_input(:,1),'VariableNames',{'new2kid'}),visval_base,'MergeKeys',true,'Type','left');
    end
    es_recreation = table2array(es_recreation);
    
    % (5.4) Get indicator of nans
    % ---------------------------
    nan_ind  = isnan(es_recreation);
    
    % (5.5) Add changes to baselines
    % ------------------------------
    [~, colidx]        = ismember(colnames, visval_base.Properties.VariableNames);     
    % To return just change in recreation value:
    [chg_cells_ind, chg_cells_idx] = ismember(es_recreation(:,1), visval_chg(:,1));
    es_recreation(chg_cells_ind, colidx)  = nansum(cat(3, es_recreation(chg_cells_ind, colidx), visval_chg(chg_cells_idx(chg_cells_ind),2:end)), 3);  
    
    % (5.6) Back to nan where no recreation value before or after changes
    % -------------------------------------------------------------------
    zero_ind = (es_recreation == 0);
    es_recreation((nan_ind) & (zero_ind)) = nan;   
    
    % (5.7) Full visval table back to NEVO
    % ------------------------------------
    es_recreation = array2table(es_recreation, 'VariableNames', visval_base.Properties.VariableNames);
    
    % (5.8) Add variables for total recreation visits and value in each decade
    % ------------------------------------------------------------------------
    % Park visit/value + path visit/value + beach visit/value in each decade
    % nansum of nan's is zero - set back to nan
    es_recreation.rec_vis_20 = nansum([es_recreation.prk_vis_20, es_recreation.pth_vis_20, es_recreation.bch_vis_20], 2);
    es_recreation.rec_vis_30 = nansum([es_recreation.prk_vis_30, es_recreation.pth_vis_30, es_recreation.bch_vis_30], 2);
    es_recreation.rec_vis_40 = nansum([es_recreation.prk_vis_40, es_recreation.pth_vis_40, es_recreation.bch_vis_40], 2);
    es_recreation.rec_vis_50 = nansum([es_recreation.prk_vis_50, es_recreation.pth_vis_50, es_recreation.bch_vis_50], 2);
    es_recreation.rec_vis_20(isnan(es_recreation.prk_vis_20) & isnan(es_recreation.pth_vis_20) & isnan(es_recreation.bch_vis_20)) = nan;
    es_recreation.rec_vis_30(isnan(es_recreation.prk_vis_30) & isnan(es_recreation.pth_vis_30) & isnan(es_recreation.bch_vis_30)) = nan;
    es_recreation.rec_vis_40(isnan(es_recreation.prk_vis_40) & isnan(es_recreation.pth_vis_40) & isnan(es_recreation.bch_vis_40)) = nan;
    es_recreation.rec_vis_50(isnan(es_recreation.prk_vis_50) & isnan(es_recreation.pth_vis_50) & isnan(es_recreation.bch_vis_50)) = nan;
    
    es_recreation.rec_val_20 = nansum([es_recreation.prk_val_20, es_recreation.pth_val_20, es_recreation.bch_val_20], 2);
    es_recreation.rec_val_30 = nansum([es_recreation.prk_val_30, es_recreation.pth_val_30, es_recreation.bch_val_30], 2);
    es_recreation.rec_val_40 = nansum([es_recreation.prk_val_40, es_recreation.pth_val_40, es_recreation.bch_val_40], 2);
    es_recreation.rec_val_50 = nansum([es_recreation.prk_val_50, es_recreation.pth_val_50, es_recreation.bch_val_50], 2);
    es_recreation.rec_val_20(isnan(es_recreation.prk_val_20) & isnan(es_recreation.pth_val_20) & isnan(es_recreation.bch_val_20)) = nan;
    es_recreation.rec_val_30(isnan(es_recreation.prk_val_30) & isnan(es_recreation.pth_val_30) & isnan(es_recreation.bch_val_30)) = nan;
    es_recreation.rec_val_40(isnan(es_recreation.prk_val_40) & isnan(es_recreation.pth_val_40) & isnan(es_recreation.bch_val_40)) = nan;
    es_recreation.rec_val_50(isnan(es_recreation.prk_val_50) & isnan(es_recreation.pth_val_50) & isnan(es_recreation.bch_val_50)) = nan;
    
    % (5.9) Add annuity values over 40 year period by combining decadal annuities
    % ---------------------------------------------------------------------------
    discount_vector = 1 ./ ((1 + MP.discount_rate) .^ (1:MP.num_years));
    discount_decade = sum(reshape(discount_vector, [10, 4]), 1)';
    gamma_data_yrs = MP.discount_rate / (1 - (1 + MP.discount_rate) ^ (-(MP.num_years)));
    
    es_recreation.prk_val_ann = ([es_recreation.prk_val_20, es_recreation.prk_val_30, es_recreation.prk_val_40, es_recreation.prk_val_50] * discount_decade) * gamma_data_yrs;
    es_recreation.prk_valab_ann = ([es_recreation.prk_valab_20, es_recreation.prk_valab_30, es_recreation.prk_valab_40, es_recreation.prk_valab_50] * discount_decade) * gamma_data_yrs;
    es_recreation.prk_valc1_ann = ([es_recreation.prk_valc1_20, es_recreation.prk_valc1_30, es_recreation.prk_valc1_40, es_recreation.prk_valc1_50] * discount_decade) * gamma_data_yrs;
    es_recreation.prk_valc2_ann = ([es_recreation.prk_valc2_20, es_recreation.prk_valc2_30, es_recreation.prk_valc2_40, es_recreation.prk_valc2_50] * discount_decade) * gamma_data_yrs;
    es_recreation.prk_valde_ann = ([es_recreation.prk_valde_20, es_recreation.prk_valde_30, es_recreation.prk_valde_40, es_recreation.prk_valde_50] * discount_decade) * gamma_data_yrs;
    es_recreation.pth_val_ann = ([es_recreation.pth_val_20, es_recreation.pth_val_30, es_recreation.pth_val_40, es_recreation.pth_val_50] * discount_decade) * gamma_data_yrs;
    es_recreation.pth_valab_ann = ([es_recreation.pth_valab_20, es_recreation.pth_valab_30, es_recreation.pth_valab_40, es_recreation.pth_valab_50] * discount_decade) * gamma_data_yrs;
    es_recreation.pth_valc1_ann = ([es_recreation.pth_valc1_20, es_recreation.pth_valc1_30, es_recreation.pth_valc1_40, es_recreation.pth_valc1_50] * discount_decade) * gamma_data_yrs;
    es_recreation.pth_valc2_ann = ([es_recreation.pth_valc2_20, es_recreation.pth_valc2_30, es_recreation.pth_valc2_40, es_recreation.pth_valc2_50] * discount_decade) * gamma_data_yrs;
    es_recreation.pth_valde_ann = ([es_recreation.pth_valde_20, es_recreation.pth_valde_30, es_recreation.pth_valde_40, es_recreation.pth_valde_50] * discount_decade) * gamma_data_yrs;
    es_recreation.bch_val_ann = ([es_recreation.bch_val_20, es_recreation.bch_val_30, es_recreation.bch_val_40, es_recreation.bch_val_50] * discount_decade) * gamma_data_yrs;
    es_recreation.bch_valab_ann = ([es_recreation.bch_valab_20, es_recreation.bch_valab_30, es_recreation.bch_valab_40, es_recreation.bch_valab_50] * discount_decade) * gamma_data_yrs;
    es_recreation.bch_valc1_ann = ([es_recreation.bch_valc1_20, es_recreation.bch_valc1_30, es_recreation.bch_valc1_40, es_recreation.bch_valc1_50] * discount_decade) * gamma_data_yrs;
    es_recreation.bch_valc2_ann = ([es_recreation.bch_valc2_20, es_recreation.bch_valc2_30, es_recreation.bch_valc2_40, es_recreation.bch_valc2_50] * discount_decade) * gamma_data_yrs;
    es_recreation.bch_valde_ann = ([es_recreation.bch_valde_20, es_recreation.bch_valde_30, es_recreation.bch_valde_40, es_recreation.bch_valde_50] * discount_decade) * gamma_data_yrs;    
    es_recreation.rec_val_ann = ([es_recreation.rec_val_20, es_recreation.rec_val_30, es_recreation.rec_val_40, es_recreation.rec_val_50] * discount_decade) * gamma_data_yrs;

end