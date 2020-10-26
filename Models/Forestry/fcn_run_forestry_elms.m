%% RUN FORESTRY
%  ============
function es_forestry = fcn_run_forestry_elms(forest_data_folder, ...
                                             forestghg_data_folder, ...
                                             MP, ...
                                             PV, ...
                                             landuse_ha_change, ...
                                             carbon_price, ...
                                             elm_option)

    % (1) INTITIALISE
    % ===============

    % a. Process inputs
    % -----------------
    wood_new_ha   = landuse_ha_change(:,1);
    agric_new_ha  = landuse_ha_change(:,2);
    sngrass_new_ha = landuse_ha_change(:,3);
    
    % b. Constants
    % ------------
    nCells = length(PV.new2kid);
    
    delta  = 1 / (1 + MP.discount_rate);
    delta_10 = (delta .^ (1:10))';                    % discount vector for 10 year period
    delta_data_yrs = (delta .^ (1:MP.num_years))';	% discount vector for data years (40 year period)
    gamma_10 = MP.discount_rate / (1 - (1 + MP.discount_rate) ^ (-10)); % annuity constant for 10 year period
    
    % c. Data files 
    % -------------
    NEVO_ForestTimber_data_mat = strcat(forest_data_folder, 'NEVO_ForestTimber_data.mat');
    NEVO_ForestGHG_data_mat    = strcat(forestghg_data_folder, 'NEVO_ForestGHG_data.mat');
    
    % d. NEVO mats from NEVORec1
    % --------------------------
    load(NEVO_ForestTimber_data_mat);
    if MP.run_ghg
        load(NEVO_ForestGHG_data_mat);
    end
    
    
    %% (2) DATA FOR NEVO INPUT CELLS
    %  -----------------------------   
    % Extract NEVO Input Cells for Forest GHG data now
    if MP.run_ghg
        [input_cells_ind_ghg, input_cell_idx_ghg] = ismember(PV.new2kid, ForestGHG.new2kid);
        input_cell_idx_ghg                    = input_cell_idx_ghg(input_cells_ind_ghg);
        
%         ForestGHG.landuse_base_cells = ForestGHG.landuse_base_cells(input_cell_idx_ghg,:);
        ForestGHG.SoilC_cells        = ForestGHG.SoilC_cells(input_cell_idx_ghg,:);
        
        % Only do Forest Soil Carbon if woodland has expanded
        wood_gain_ha = wood_new_ha .* (wood_new_ha > 0);
        wood_area_increased = any(wood_gain_ha);
        
        if wood_area_increased
            % Set hectares of arable and non-arable reversion to woodland
            % depending on elm_option
            switch elm_option
                case {'arable_reversion_wood_access', ...
                      'arable_reversion_wood_noaccess'}
                  % New woodland is on arable land
                  arable2wood_ha_cell = wood_new_ha;
                  narable2wood_ha_cell = zeros(size(wood_new_ha));
                case {'destocking_wood_access', ...
                      'destocking_wood_noaccess'}
                  % New woodland is on grazing land
                  arable2wood_ha_cell = zeros(size(wood_new_ha));
                  narable2wood_ha_cell = wood_new_ha;
                case {'arable_reversion_sng_access', ...
                      'destocking_sng_access', ...
                      'arable_reversion_sng_noaccess', ...
                      'destocking_sng_noaccess'}
                  % There is no new woodland here so this case should not
                  % be possible, but set to zero anyway
                  arable2wood_ha_cell = zeros(size(wood_new_ha));
                  narable2wood_ha_cell = zeros(size(wood_new_ha));
                otherwise
                    error('ELM option not found.')
            end         
        end
    end
    
    % Index for NEVO Input Cells for Forest Timber data so can extract by species subsequently
    [input_cells_ind, input_cell_idx] = ismember(PV.new2kid, ForestTimber.new2kid);
    input_cell_idx                    = input_cell_idx(input_cells_ind);
        
    %% (3) USER PROVIDED UPDATES FOR THIS NEVO ALTER
    %  ---------------------------------------------
    
    % (a) Update Price Factors: Renaming Fixes to Work in Loop
    % ------------------------------------------------------
    price_factor.PedunculateOak = MP.price_broad_factor;
    price_factor.SitkaSpruce    = MP.price_conif_factor;  
    
    species_prop_cell.PedunculateOak = PV.p_decid;
    species_prop_cell.SitkaSpruce    = PV.p_conif;

    species_prop_6040.PedunculateOak = 0.6;
    species_prop_6040.SitkaSpruce    = 0.4;

    
    %% (4) CALCULATE TIMBER & SOIL ES FOR EACH SPECIES
    %  -----------------------------------------------
    
    % Initialise vectors for mixed planting outcomes in each cell
    es_forestry.Timber.QntYr.('Mix6040')  = 0;
    es_forestry.Timber.QntYr.('Current')  = 0;
    es_forestry.Timber.QntYr20.('Mix6040')  = 0;
    es_forestry.Timber.QntYr20.('Current')  = 0;
    es_forestry.Timber.QntYr30.('Mix6040')  = 0;
    es_forestry.Timber.QntYr30.('Current')  = 0;
    es_forestry.Timber.QntYr40.('Mix6040')  = 0;
    es_forestry.Timber.QntYr40.('Current')  = 0;
    es_forestry.Timber.QntYr50.('Mix6040')  = 0;
    es_forestry.Timber.QntYr50.('Current')  = 0;
    
    es_forestry.Timber.ValAnn.('Mix6040') = 0;
    es_forestry.Timber.ValAnn.('Current') = 0;
    es_forestry.Timber.BenefitAnn.('Mix6040') = 0;
    es_forestry.Timber.BenefitAnn.('Current') = 0;
    es_forestry.Timber.CostAnn.('Mix6040') = 0;
    es_forestry.Timber.CostAnn.('Current') = 0;
    es_forestry.Timber.FixedCost.('Mix6040') = 0;
    es_forestry.Timber.FixedCost.('Current') = 0;
    es_forestry.Timber.FlowAnn20.('Mix6040') = 0;
    es_forestry.Timber.FlowAnn20.('Current') = 0;
    es_forestry.Timber.FlowAnn30.('Mix6040') = 0;
    es_forestry.Timber.FlowAnn30.('Current') = 0;
    es_forestry.Timber.FlowAnn40.('Mix6040') = 0;
    es_forestry.Timber.FlowAnn40.('Current') = 0;
    es_forestry.Timber.FlowAnn50.('Mix6040') = 0;
    es_forestry.Timber.FlowAnn50.('Current') = 0;
    
    es_forestry.TimberC.QntYr.('Mix6040')  = 0;
    es_forestry.TimberC.QntYr.('Current')  = 0;
    es_forestry.TimberC.QntYrUB.('Mix6040')  = 0;
    es_forestry.TimberC.QntYrUB.('Current')  = 0;
    es_forestry.TimberC.QntYr20.('Mix6040')  = 0;
    es_forestry.TimberC.QntYr20.('Current')  = 0;
    es_forestry.TimberC.QntYr30.('Mix6040')  = 0;
    es_forestry.TimberC.QntYr30.('Current')  = 0;
    es_forestry.TimberC.QntYr40.('Mix6040')  = 0;
    es_forestry.TimberC.QntYr40.('Current')  = 0;
    es_forestry.TimberC.QntYr50.('Mix6040')  = 0;
    es_forestry.TimberC.QntYr50.('Current')  = 0;
    
    es_forestry.TimberC.ValAnn.('Mix6040') = 0;
    es_forestry.TimberC.ValAnn.('Current') = 0;
    es_forestry.TimberC.FlowAnn20.('Mix6040') = 0;
    es_forestry.TimberC.FlowAnn20.('Current') = 0;
    es_forestry.TimberC.FlowAnn30.('Mix6040') = 0;
    es_forestry.TimberC.FlowAnn30.('Current') = 0;
    es_forestry.TimberC.FlowAnn40.('Mix6040') = 0;
    es_forestry.TimberC.FlowAnn40.('Current') = 0;
    es_forestry.TimberC.FlowAnn50.('Mix6040') = 0;
    es_forestry.TimberC.FlowAnn50.('Current') = 0;
    
    es_forestry.SoilC.QntYr.('Mix6040')  = 0;
    es_forestry.SoilC.QntYr.('Current')  = 0;
    es_forestry.SoilC.QntYr20.('Mix6040')  = 0;
    es_forestry.SoilC.QntYr20.('Current')  = 0;
    es_forestry.SoilC.QntYr30.('Mix6040')  = 0;
    es_forestry.SoilC.QntYr30.('Current')  = 0;
    es_forestry.SoilC.QntYr40.('Mix6040')  = 0;
    es_forestry.SoilC.QntYr40.('Current')  = 0;
    es_forestry.SoilC.QntYr50.('Mix6040')  = 0;
    es_forestry.SoilC.QntYr50.('Current')  = 0;
    
    es_forestry.SoilC.ValAnn.('Mix6040') = 0;
    es_forestry.SoilC.ValAnn.('Current') = 0;
    es_forestry.SoilC.FlowAnn20.('Mix6040') = 0;
    es_forestry.SoilC.FlowAnn20.('Current') = 0;
    es_forestry.SoilC.FlowAnn30.('Mix6040') = 0;
    es_forestry.SoilC.FlowAnn30.('Current') = 0;
    es_forestry.SoilC.FlowAnn40.('Mix6040') = 0;
    es_forestry.SoilC.FlowAnn40.('Current') = 0;
    es_forestry.SoilC.FlowAnn50.('Mix6040') = 0;
    es_forestry.SoilC.FlowAnn50.('Current') = 0;
    
    % Loop through species
    for i = 1:height(ForestTimber.SpeciesCode)

        % Species Details
        % ---------------
        species   = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.species(i)));
        spec_code = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.code(i)));

        % Discount & Annuity Constants
        % ----------------------------
        rotp1 = ForestTimber.RotPeriod_max.(species);
        rotp2 = rotp1*2;
        delta_rot1 = (delta .^ (1:rotp1))';    % discount vector for one rotation
        delta_rot2 = (delta .^ (1:rotp2))';    % discount vector for two rotations
        gamma_rot1 = MP.discount_rate ./ (1 - (1 + MP.discount_rate) .^ -(ForestTimber.RotPeriod.(species))); % annuity constant for one rotation
                
        % Reduce Saved Cell Data to NEVO Input Cells
        % ------------------------------------------ 
        ForestTimber.QntPerHa.(species) = ForestTimber.QntPerHa.(species)(input_cell_idx);
        es_forestry.YC_prediction_cell.(species) = es_forestry.YC_prediction_cell.(species)(input_cell_idx,:);
        es_forestry.RotPeriod_cell.(species)     = es_forestry.RotPeriod_cell.(species)(input_cell_idx,:);
        
        % FOREST TIMBER PRODUCTION
        % ========================
            
        % (a) Forest Timber: Quantity
        % ---------------------------
        
        % Brett's per year calculation over full rotation of tree with
        % climate change
        es_forestry.Timber.QntYr.(species)   = ForestTimber.QntPerHa.(species) .* PV.wood_ha;
        es_forestry.Timber.QntYr.('Mix6040') = es_forestry.Timber.QntYr.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.QntYr.(species);
        es_forestry.Timber.QntYr.('Current') = es_forestry.Timber.QntYr.('Current') + species_prop_cell.(species) .* es_forestry.Timber.QntYr.(species);
        
        % other approach is to calculate timber volume flows in each decade
        
        % average timber per hectare for each yield class in each decade
        timber_perha_20 = sum(ForestTimber.Timber.(species)(1:10, :), 1);
        timber_perha_30 = sum(ForestTimber.Timber.(species)(11:20, :), 1);
        timber_perha_40 = sum(ForestTimber.Timber.(species)(21:30, :), 1);
        timber_perha_50 = sum(ForestTimber.Timber.(species)(31:40, :), 1);
        
        % average timber per yr for each cell in each decade, taking into
        % account climate change
        timber_peryr_20 = full(mean(timber_perha_20(es_forestry.YC_prediction_cell.(species)(:, 1:10)), 2));
        timber_peryr_30 = full(mean(timber_perha_30(es_forestry.YC_prediction_cell.(species)(:, 11:20)), 2));
        timber_peryr_40 = full(mean(timber_perha_40(es_forestry.YC_prediction_cell.(species)(:, 21:30)), 2));
        timber_peryr_50 = full(mean(timber_perha_50(es_forestry.YC_prediction_cell.(species)(:, 31:40)), 2));
        
        % scale by woodland hectares in each cell and define mixes
        es_forestry.Timber.QntYr20.(species) = timber_peryr_20 .* PV.wood_ha;
        es_forestry.Timber.QntYr30.(species) = timber_peryr_30 .* PV.wood_ha;
        es_forestry.Timber.QntYr40.(species) = timber_peryr_40 .* PV.wood_ha;
        es_forestry.Timber.QntYr50.(species) = timber_peryr_50 .* PV.wood_ha;
        
        es_forestry.Timber.QntYr20.('Mix6040') = es_forestry.Timber.QntYr20.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.QntYr20.(species);
        es_forestry.Timber.QntYr20.('Current') = es_forestry.Timber.QntYr20.('Current') + species_prop_cell.(species) .* es_forestry.Timber.QntYr20.(species);
        es_forestry.Timber.QntYr30.('Mix6040') = es_forestry.Timber.QntYr30.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.QntYr30.(species);
        es_forestry.Timber.QntYr30.('Current') = es_forestry.Timber.QntYr30.('Current') + species_prop_cell.(species) .* es_forestry.Timber.QntYr30.(species);
        es_forestry.Timber.QntYr40.('Mix6040') = es_forestry.Timber.QntYr40.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.QntYr40.(species);
        es_forestry.Timber.QntYr40.('Current') = es_forestry.Timber.QntYr40.('Current') + species_prop_cell.(species) .* es_forestry.Timber.QntYr40.(species);
        es_forestry.Timber.QntYr50.('Mix6040') = es_forestry.Timber.QntYr50.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.QntYr50.(species);
        es_forestry.Timber.QntYr50.('Current') = es_forestry.Timber.QntYr50.('Current') + species_prop_cell.(species) .* es_forestry.Timber.QntYr50.(species);

        % (b) Forest Timber: Value
        % ------------------------
        % NB. this is calculated in two ways:
        %   1. annuity of annuities over data years + remaining years over one rotation
        %   2. average for each decade in data years only (flow)
        
        % Update value per ha to (possibly new) per ha timber prices
        ForestTimber.TimberValue.(species) = price_factor.(species) * ForestTimber.TimberValue.(species);

        % npv: per ha npv of timber production by yc at new prices & discount rate

        npv_ben_perha       = delta_rot1' * (ForestTimber.TimberValue.(species));         % one rotation
        npv_cst_perha       = delta_rot1' * (ForestTimber.TimberCosts.PerHa.(species));         % one rotation
        
        % annuity: per ha annuity of timber production by yc at new prices & discount rate
        ann_ben_perha  = npv_ben_perha' .* gamma_rot1;       % one rotation
        ann_cst_perha = npv_cst_perha' .* gamma_rot1;       % one rotation

        % Not needed for ELMS
        value_minus_cost = ForestTimber.TimberValue.(species) - ForestTimber.TimberCosts.PerHa.(species);
        % average flow per hectare for each yield class in each decade
        flow_perha_20 = mean(value_minus_cost(1:10, :), 1);    % 2020-2029
        flow_perha_30 = mean(value_minus_cost(11:20, :), 1);   % 2030-2039
        flow_perha_40 = mean(value_minus_cost(21:30, :), 1);   % 2040-2049
        flow_perha_50 = mean(value_minus_cost(31:40, :), 1);   % 2050-2059
        
        %   Takes new series of yc predictions for future climate and each 
        %   year replaces with annuity for that yield class out to the 
        %   cell-specific rotation period for this climate. The npv of that 
        %   stream of annual revenues is calculated and finally an 
        %   annuity of that npv is derived (an annuity of annuities)
        
        % npv of annuities for cell evolution of yc with climate ...
        %   ... for years for which have climate data:
        if nCells == 1
            npv_ben_data_yrs    = ann_ben_perha(es_forestry.YC_prediction_cell.(species))' * delta_data_yrs;
            npv_cst_data_yrs    = ann_cst_perha(es_forestry.YC_prediction_cell.(species))' * delta_data_yrs;
        else
            npv_ben_data_yrs    = ann_ben_perha(es_forestry.YC_prediction_cell.(species)) * delta_data_yrs;
            npv_cst_data_yrs    = ann_cst_perha(es_forestry.YC_prediction_cell.(species)) * delta_data_yrs;
        end
        
        npv_data_yrs_20 = full(sum(flow_perha_20(es_forestry.YC_prediction_cell.(species)(:, 1:10)), 2));
        npv_data_yrs_30 = full(sum(flow_perha_30(es_forestry.YC_prediction_cell.(species)(:, 11:20)), 2));
        npv_data_yrs_40 = full(sum(flow_perha_40(es_forestry.YC_prediction_cell.(species)(:, 21:30)), 2));
        npv_data_yrs_50 = full(sum(flow_perha_50(es_forestry.YC_prediction_cell.(species)(:, 31:40)), 2));

        %   ... remaining years up to end of rotation (uses formula for partial sum of geometric series):
        delta_rot_cell = (delta ^ (MP.num_years - 1) - delta .^ (MP.num_years + es_forestry.RotPeriod_cell.(species))) / (1 - delta);
        npv_ben_final_yrs  = delta_rot_cell .* ann_ben_perha(es_forestry.YC_prediction_cell.(species)(:,end));       
        npv_cst_final_yrs  = delta_rot_cell .* ann_cst_perha(es_forestry.YC_prediction_cell.(species)(:,end));       
        
        npv_ben_perha_cell = npv_ben_data_yrs + npv_ben_final_yrs;
        npv_cst_perha_cell = npv_cst_data_yrs + npv_cst_final_yrs;
        
        % npv of fixed costs based on first year's yc (discount in 1st year)
        npv_fxcst = ForestTimber.TimberCosts.Fixed.(species)(1, es_forestry.YC_prediction_cell.(species)(:, 1))' / (1 + MP.discount_rate);
                
        % Annuity of Annuities:
        gamma_rot_cell  = MP.discount_rate ./ (1 - (1 + MP.discount_rate) .^ -(es_forestry.RotPeriod_cell.(species) - 1));
        es_forestry.Timber.ValAnn.(species) = gamma_rot_cell .* ((npv_ben_perha_cell - npv_cst_perha_cell) .* PV.wood_ha - npv_fxcst .* (PV.wood_ha > 0));
        
        es_forestry.Timber.BenefitAnn.(species) = gamma_rot_cell .* (npv_ben_perha_cell .* PV.wood_ha);
        es_forestry.Timber.CostAnn.(species)    = gamma_rot_cell .* (npv_cst_perha_cell .* PV.wood_ha);
        % fixed cost if you have increased woodland hectares - only for
        % ELMs
        es_forestry.Timber.FixedCost.(species)  = npv_fxcst .* (wood_new_ha > 0);
        
        % Average flow in each decade
        es_forestry.Timber.FlowAnn20.(species) = (npv_data_yrs_20 .* PV.wood_ha - npv_fxcst .* (PV.wood_ha > 0)) / 10;   % subtract costs in first decade
        es_forestry.Timber.FlowAnn30.(species) = (npv_data_yrs_30 .* PV.wood_ha) / 10;
        es_forestry.Timber.FlowAnn40.(species) = (npv_data_yrs_40 .* PV.wood_ha) / 10;
        es_forestry.Timber.FlowAnn50.(species) = (npv_data_yrs_50 .* PV.wood_ha) / 10;
        
        % Accumulate Forest Mixes
        es_forestry.Timber.ValAnn.('Mix6040')       = es_forestry.Timber.ValAnn.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.ValAnn.(species);
        es_forestry.Timber.ValAnn.('Current')       = es_forestry.Timber.ValAnn.('Current') + species_prop_cell.(species) .* es_forestry.Timber.ValAnn.(species);
        es_forestry.Timber.BenefitAnn.('Mix6040')   = es_forestry.Timber.BenefitAnn.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.BenefitAnn.(species);
        es_forestry.Timber.BenefitAnn.('Current')   = es_forestry.Timber.BenefitAnn.('Current') + species_prop_cell.(species) .* es_forestry.Timber.BenefitAnn.(species);
        es_forestry.Timber.CostAnn.('Mix6040')      = es_forestry.Timber.CostAnn.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.CostAnn.(species);
        es_forestry.Timber.CostAnn.('Current')      = es_forestry.Timber.CostAnn.('Current') + species_prop_cell.(species) .* es_forestry.Timber.CostAnn.(species);
        es_forestry.Timber.FixedCost.('Mix6040')    = es_forestry.Timber.FixedCost.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.FixedCost.(species);
        es_forestry.Timber.FixedCost.('Current')    = es_forestry.Timber.FixedCost.('Current') + species_prop_cell.(species) .* es_forestry.Timber.FixedCost.(species);
        es_forestry.Timber.FlowAnn20.('Mix6040')	= es_forestry.Timber.FlowAnn20.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.FlowAnn20.(species);
        es_forestry.Timber.FlowAnn20.('Current')	= es_forestry.Timber.FlowAnn20.('Current') + species_prop_cell.(species) .* es_forestry.Timber.FlowAnn20.(species);
        es_forestry.Timber.FlowAnn30.('Mix6040')	= es_forestry.Timber.FlowAnn30.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.FlowAnn30.(species);
        es_forestry.Timber.FlowAnn30.('Current')	= es_forestry.Timber.FlowAnn30.('Current') + species_prop_cell.(species) .* es_forestry.Timber.FlowAnn30.(species);
        es_forestry.Timber.FlowAnn40.('Mix6040')	= es_forestry.Timber.FlowAnn40.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.FlowAnn40.(species);
        es_forestry.Timber.FlowAnn40.('Current')	= es_forestry.Timber.FlowAnn40.('Current') + species_prop_cell.(species) .* es_forestry.Timber.FlowAnn40.(species);
        es_forestry.Timber.FlowAnn50.('Mix6040')	= es_forestry.Timber.FlowAnn50.('Mix6040') + species_prop_6040.(species) .* es_forestry.Timber.FlowAnn50.(species);
        es_forestry.Timber.FlowAnn50.('Current')	= es_forestry.Timber.FlowAnn50.('Current') + species_prop_cell.(species) .* es_forestry.Timber.FlowAnn50.(species);

        % FOREST CARBON PRODUCTION
        % ========================
        
        if MP.run_ghg        
            
            % (c) Timber Carbon: Quantity
            % ---------------------------

            % Sum of Carbon quantities per year for years for which have climate data:
            if nCells == 1
                TimberC_qnt_data_yrs =  sum(ForestGHG.TimberC_QntYr.(species)(es_forestry.YC_prediction_cell.(species)));
                TimberC_qntUB_data_yrs =  sum(ForestGHG.TimberC_QntYrUB.(species)(es_forestry.YC_prediction_cell.(species)));
                TimberC_qnt_20 =  sum(ForestGHG.TimberC_QntYr20.(species)(es_forestry.YC_prediction_cell.(species)(:, 1:10)));
                TimberC_qnt_30 =  sum(ForestGHG.TimberC_QntYr30.(species)(es_forestry.YC_prediction_cell.(species)(:, 11:20)));
                TimberC_qnt_40 =  sum(ForestGHG.TimberC_QntYr40.(species)(es_forestry.YC_prediction_cell.(species)(:, 21:30)));
                TimberC_qnt_50 =  sum(ForestGHG.TimberC_QntYr50.(species)(es_forestry.YC_prediction_cell.(species)(:, 31:40)));
            else
                TimberC_qnt_data_yrs =  sum(ForestGHG.TimberC_QntYr.(species)(es_forestry.YC_prediction_cell.(species)), 2);
                TimberC_qntUB_data_yrs =  sum(ForestGHG.TimberC_QntYrUB.(species)(es_forestry.YC_prediction_cell.(species)), 2);
                TimberC_qnt_20 =  sum(ForestGHG.TimberC_QntYr20.(species)(es_forestry.YC_prediction_cell.(species)(:, 1:10)), 2);
                TimberC_qnt_30 =  sum(ForestGHG.TimberC_QntYr30.(species)(es_forestry.YC_prediction_cell.(species)(:, 11:20)), 2);
                TimberC_qnt_40 =  sum(ForestGHG.TimberC_QntYr40.(species)(es_forestry.YC_prediction_cell.(species)(:, 21:30)), 2);
                TimberC_qnt_50 =  sum(ForestGHG.TimberC_QntYr50.(species)(es_forestry.YC_prediction_cell.(species)(:, 31:40)), 2);
            end

            % Sum of Carbon quantities remaining years up to end of rotation:
            num_final_yrs  = es_forestry.RotPeriod_cell.(species) - MP.num_years;
            TimberC_qnt_final_yrs = num_final_yrs .* ForestGHG.TimberC_QntYr.(species)(es_forestry.YC_prediction_cell.(species)(:, end));
            TimberC_qntUB_final_yrs = num_final_yrs .* ForestGHG.TimberC_QntYrUB.(species)(es_forestry.YC_prediction_cell.(species)(:, end));
            
            % Average annual Carbon quantities per cell for this species
            es_forestry.TimberC.QntYr.(species)  = PV.wood_ha .* ((TimberC_qnt_data_yrs + TimberC_qnt_final_yrs) ./ es_forestry.RotPeriod_cell.(species));
            elm_contract_length = 50;
            es_forestry.TimberC.QntYrUB.(species)  = PV.wood_ha .* ((TimberC_qntUB_data_yrs + TimberC_qntUB_final_yrs) ./ elm_contract_length);
            
            es_forestry.TimberC.QntYr20.(species) = (PV.wood_ha .* TimberC_qnt_20) / 10;
            es_forestry.TimberC.QntYr30.(species) = (PV.wood_ha .* TimberC_qnt_30) / 10;
            es_forestry.TimberC.QntYr40.(species) = (PV.wood_ha .* TimberC_qnt_40) / 10;
            es_forestry.TimberC.QntYr50.(species) = (PV.wood_ha .* TimberC_qnt_50) / 10;

            % Accumulate Forest Mixes
            es_forestry.TimberC.QntYr.('Mix6040') = es_forestry.TimberC.QntYr.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYr.(species);
            es_forestry.TimberC.QntYr.('Current') = es_forestry.TimberC.QntYr.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYr.(species);
            es_forestry.TimberC.QntYrUB.('Mix6040') = es_forestry.TimberC.QntYrUB.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYrUB.(species);
            es_forestry.TimberC.QntYrUB.('Current') = es_forestry.TimberC.QntYrUB.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYrUB.(species);
            es_forestry.TimberC.QntYr20.('Mix6040') = es_forestry.TimberC.QntYr20.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYr20.(species);
            es_forestry.TimberC.QntYr20.('Current') = es_forestry.TimberC.QntYr20.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYr20.(species);
            es_forestry.TimberC.QntYr30.('Mix6040') = es_forestry.TimberC.QntYr30.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYr30.(species);
            es_forestry.TimberC.QntYr30.('Current') = es_forestry.TimberC.QntYr30.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYr30.(species);
            es_forestry.TimberC.QntYr40.('Mix6040') = es_forestry.TimberC.QntYr40.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYr40.(species);
            es_forestry.TimberC.QntYr40.('Current') = es_forestry.TimberC.QntYr40.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYr40.(species);
            es_forestry.TimberC.QntYr50.('Mix6040') = es_forestry.TimberC.QntYr50.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.QntYr50.(species);
            es_forestry.TimberC.QntYr50.('Current') = es_forestry.TimberC.QntYr50.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.QntYr50.(species);
            
            % (d) Timber Carbon: Value
            % ------------------------
            % NB. this is calculated in two ways:
            % 1. Annuity of annuities over data years + remaining years over two rotations
            % - Carbon npv calculations done over 2 rotations to capture both
            %   sequestration phase and emissions phase after harvest (i.e.
            %   non-permanent storage). 
            % - Carbon Annuity is over single rotation as assume forest is
            %   replanted so continuous value flow achieved by annualising 
            %   two-rotation npv over one rotation
            % 2. Average for each decade in data years only (flow)
        
            % Annuity for each yc for this species
            
            % npv for each yc of this species
            TimberC_npv     = (delta_rot2 .* carbon_price(1:rotp2))' * ForestGHG.TimberC_TSer.(species);         % two rotations
            
            % annuity for each yc of this species
            TimberC_ann     = gamma_rot1 .* TimberC_npv';    % one rotation

            % average flow per hectare for each yield class in each decade
            timber_carbon_value = carbon_price(1:40) .* ForestGHG.TimberC_TSer.(species)(1:40, :);
            TimberC_flow_20 = mean(timber_carbon_value(1:10, :), 1);    % 2020-2029
            TimberC_flow_30 = mean(timber_carbon_value(11:20, :), 1);   % 2030-2039
            TimberC_flow_40 = mean(timber_carbon_value(21:30, :), 1);   % 2040-2049
            TimberC_flow_50 = mean(timber_carbon_value(31:40, :), 1);   % 2050-2059
               
            % NPV of Carbon annuities for years for which have climate data:
            if nCells == 1
                TimberC_npv_data_yrs	= TimberC_ann(es_forestry.YC_prediction_cell.(species))' * delta_data_yrs;
            else
                TimberC_npv_data_yrs	= TimberC_ann(es_forestry.YC_prediction_cell.(species)) * delta_data_yrs;
            end
            
            TimberC_npv_data_yrs_20 = full(sum(TimberC_flow_20(es_forestry.YC_prediction_cell.(species)(:, 1:10)), 2));
            TimberC_npv_data_yrs_30 = full(sum(TimberC_flow_30(es_forestry.YC_prediction_cell.(species)(:, 11:20)), 2));
            TimberC_npv_data_yrs_40 = full(sum(TimberC_flow_40(es_forestry.YC_prediction_cell.(species)(:, 21:30)), 2));
            TimberC_npv_data_yrs_50 = full(sum(TimberC_flow_50(es_forestry.YC_prediction_cell.(species)(:, 31:40)), 2));

            % NPV of Carbon annuities remaining years up to end of rotation:
            TimberC_npv_final_yrs = delta_rot_cell .* TimberC_ann(es_forestry.YC_prediction_cell.(species)(:, end));
            
            TimberC_npv_cell = TimberC_npv_data_yrs + TimberC_npv_final_yrs;        
                
            % Annuity of Annuities:
            es_forestry.TimberC.ValAnn.(species) = gamma_rot_cell .* TimberC_npv_cell .* PV.wood_ha;
            
            % Average flow in each decade
            es_forestry.TimberC.FlowAnn20.(species)	= TimberC_npv_data_yrs_20 .* PV.wood_ha / 10;
            es_forestry.TimberC.FlowAnn30.(species)	= TimberC_npv_data_yrs_30 .* PV.wood_ha / 10;
            es_forestry.TimberC.FlowAnn40.(species)	= TimberC_npv_data_yrs_40 .* PV.wood_ha / 10;
            es_forestry.TimberC.FlowAnn50.(species)	= TimberC_npv_data_yrs_50 .* PV.wood_ha / 10;
            
            % Accumulate Forest Mixes
            es_forestry.TimberC.ValAnn.('Mix6040')      = es_forestry.TimberC.ValAnn.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.ValAnn.(species);
            es_forestry.TimberC.ValAnn.('Current')      = es_forestry.TimberC.ValAnn.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.ValAnn.(species);
            es_forestry.TimberC.FlowAnn20.('Mix6040')	= es_forestry.TimberC.FlowAnn20.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.FlowAnn20.(species);
            es_forestry.TimberC.FlowAnn20.('Current')	= es_forestry.TimberC.FlowAnn20.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.FlowAnn20.(species);
            es_forestry.TimberC.FlowAnn30.('Mix6040')	= es_forestry.TimberC.FlowAnn30.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.FlowAnn30.(species);
            es_forestry.TimberC.FlowAnn30.('Current')	= es_forestry.TimberC.FlowAnn30.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.FlowAnn30.(species);
            es_forestry.TimberC.FlowAnn40.('Mix6040')	= es_forestry.TimberC.FlowAnn40.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.FlowAnn40.(species);
            es_forestry.TimberC.FlowAnn40.('Current')	= es_forestry.TimberC.FlowAnn40.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.FlowAnn40.(species);
            es_forestry.TimberC.FlowAnn50.('Mix6040')	= es_forestry.TimberC.FlowAnn50.('Mix6040') + species_prop_6040.(species) .* es_forestry.TimberC.FlowAnn50.(species);
            es_forestry.TimberC.FlowAnn50.('Current')	= es_forestry.TimberC.FlowAnn50.('Current') + species_prop_cell.(species) .* es_forestry.TimberC.FlowAnn50.(species);
            
            if wood_area_increased
                
                % Reduce Saved Cell Data to NEVO Input Cells
                % ------------------------------------------
                ForestGHG.SoilC_QntYr.narable.(species) = ForestGHG.SoilC_QntYr.narable.(species)(input_cell_idx_ghg);        
                ForestGHG.SoilC_QntYr.arable.(species)  = ForestGHG.SoilC_QntYr.arable.(species)(input_cell_idx_ghg);
                ForestGHG.SoilC_QntYr20.narable.(species) = ForestGHG.SoilC_QntYr20.narable.(species)(input_cell_idx_ghg);        
                ForestGHG.SoilC_QntYr20.arable.(species)  = ForestGHG.SoilC_QntYr20.arable.(species)(input_cell_idx_ghg);
                ForestGHG.SoilC_QntYr30.narable.(species) = ForestGHG.SoilC_QntYr30.narable.(species)(input_cell_idx_ghg);        
                ForestGHG.SoilC_QntYr30.arable.(species)  = ForestGHG.SoilC_QntYr30.arable.(species)(input_cell_idx_ghg);
                ForestGHG.SoilC_QntYr40.narable.(species) = ForestGHG.SoilC_QntYr40.narable.(species)(input_cell_idx_ghg);        
                ForestGHG.SoilC_QntYr40.arable.(species)  = ForestGHG.SoilC_QntYr40.arable.(species)(input_cell_idx_ghg);
                ForestGHG.SoilC_QntYr50.narable.(species) = ForestGHG.SoilC_QntYr50.narable.(species)(input_cell_idx_ghg);        
                ForestGHG.SoilC_QntYr50.arable.(species)  = ForestGHG.SoilC_QntYr50.arable.(species)(input_cell_idx_ghg);

                % (e) Soil Carbon: Value
                % ----------------------
                % NB. this is done in two ways
                % 1. Annuity of annuities over data years + remaining years over two rotations
                % - Carbon npv calculations done over 2 rotations to capture
                %   long run soil changes
                % - Carbon annuity is over single rotation which repeats
                %   the timber Carbon calculation but is less defensible 
                %   as the land use change of Woodland expansion is one-off
                % 2. Annuity for each decade in data years only (flow)

                % Calculate npv for each Carbine YC for this Species
                % --------------------------------------------------
                SoilC_narable_ann_cell = [];
                SoilC_narable_flow_cell_20 = [];
                SoilC_narable_flow_cell_30 = [];
                SoilC_narable_flow_cell_40 = [];
                SoilC_narable_flow_cell_50 = [];
                
                SoilC_arable_ann_cell  = [];
                SoilC_arable_flow_cell_20 = [];
                SoilC_arable_flow_cell_30 = [];
                SoilC_arable_flow_cell_40 = [];
                SoilC_arable_flow_cell_50 = [];
                
                colidx = ones(nCells,1);   
                rowidx = (1:nCells)';
                
                discount_Cprice = delta_rot2 .* carbon_price(1:rotp2);
                
                for j = 1:length(ForestTimber.Carbine_ycs.(species))
                    
                    yc   = ForestTimber.Carbine_ycs.(species)(j);
                    rotp = ForestTimber.RotPeriod.(species)(yc);

                    % npv for this yc & soil type for this species
                    SoilC_npv_yc	= (discount_Cprice(1:rotp*2))' * ForestGHG.SoilC_TSer.(species){yc};          % two rotations

                    % annuity for this yc & soil type for this species
                    SoilC_ann_yc	= gamma_rot1(yc) * SoilC_npv_yc;    % one rotation

                    % average flow per hectare for each yield class in each decade
                    soil_carbon_value = carbon_price(1:40) .* ForestGHG.SoilC_TSer.(species){yc}(1:40, :);
                    SoilC_flow_yc_20 = mean(soil_carbon_value(1:10, :), 1);    % 2020-2029
                    SoilC_flow_yc_30 = mean(soil_carbon_value(11:20, :), 1);   % 2030-2039
                    SoilC_flow_yc_40 = mean(soil_carbon_value(21:30, :), 1);   % 2040-2049
                    SoilC_flow_yc_50 = mean(soil_carbon_value(31:40, :), 1);   % 2050-2059
                    
                    % annuity for soil mix in each cell (for this yc when displacing arable and non-arable)
                    % (first 4 cols of SoilC_TSer are for non-arable last 4 cols are for arable both in order SLCO)
                    SoilC_narable_ann_cell      = [SoilC_narable_ann_cell; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_ann_yc(1:4)']];
                    SoilC_narable_flow_cell_20	= [SoilC_narable_flow_cell_20; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_20(1:4)']];
                    SoilC_narable_flow_cell_30	= [SoilC_narable_flow_cell_30; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_30(1:4)']];
                    SoilC_narable_flow_cell_40	= [SoilC_narable_flow_cell_40; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_40(1:4)']];
                    SoilC_narable_flow_cell_50	= [SoilC_narable_flow_cell_50; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_50(1:4)']];
                    
                    SoilC_arable_ann_cell       = [SoilC_arable_ann_cell;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_ann_yc(5:8)']];
                    SoilC_arable_flow_cell_20   = [SoilC_arable_flow_cell_20;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_20(5:8)']];
                    SoilC_arable_flow_cell_30	= [SoilC_arable_flow_cell_30;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_30(5:8)']];
                    SoilC_arable_flow_cell_40	= [SoilC_arable_flow_cell_40;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_40(5:8)']];
                    SoilC_arable_flow_cell_50	= [SoilC_arable_flow_cell_50;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_flow_yc_50(5:8)']];
                    
                end
                
                % [N x yc] matrices of npvs for each yc for the particular soil combination in each cell
                SoilC_narable_ann_cell      = sparse(SoilC_narable_ann_cell(:,1), SoilC_narable_ann_cell(:,2), SoilC_narable_ann_cell(:,3));
                SoilC_narable_flow_cell_20	= sparse(SoilC_narable_flow_cell_20(:,1), SoilC_narable_flow_cell_20(:,2), SoilC_narable_flow_cell_20(:,3));
                SoilC_narable_flow_cell_30	= sparse(SoilC_narable_flow_cell_30(:,1), SoilC_narable_flow_cell_30(:,2), SoilC_narable_flow_cell_30(:,3));
                SoilC_narable_flow_cell_40	= sparse(SoilC_narable_flow_cell_40(:,1), SoilC_narable_flow_cell_40(:,2), SoilC_narable_flow_cell_40(:,3));
                SoilC_narable_flow_cell_50	= sparse(SoilC_narable_flow_cell_50(:,1), SoilC_narable_flow_cell_50(:,2), SoilC_narable_flow_cell_50(:,3));
                
                SoilC_arable_ann_cell       = sparse(SoilC_arable_ann_cell(:,1),  SoilC_arable_ann_cell(:,2),  SoilC_arable_ann_cell(:,3));
                SoilC_arable_flow_cell_20	= sparse(SoilC_arable_flow_cell_20(:,1), SoilC_arable_flow_cell_20(:,2), SoilC_arable_flow_cell_20(:,3));
                SoilC_arable_flow_cell_30	= sparse(SoilC_arable_flow_cell_30(:,1), SoilC_arable_flow_cell_30(:,2), SoilC_arable_flow_cell_30(:,3));
                SoilC_arable_flow_cell_40	= sparse(SoilC_arable_flow_cell_40(:,1), SoilC_arable_flow_cell_40(:,2), SoilC_arable_flow_cell_40(:,3));
                SoilC_arable_flow_cell_50	= sparse(SoilC_arable_flow_cell_50(:,1), SoilC_arable_flow_cell_50(:,2), SoilC_arable_flow_cell_50(:,3));

                % Increment YC for each of 40yrs to index into the cell annuity matrix
                YC_prediction_cell_idx = (double(es_forestry.YC_prediction_cell.(species)) - 1)*nCells + rowidx;                
                                
                % NPV of Carbon annuities for years for which have climate data:
                SoilC_narable_npv_data_yrs      = SoilC_narable_ann_cell(YC_prediction_cell_idx) * delta_data_yrs;
                SoilC_narable_npv_data_yrs_20	= full(sum(SoilC_narable_flow_cell_20(YC_prediction_cell_idx(:,1:10)), 2));
                SoilC_narable_npv_data_yrs_30	= full(sum(SoilC_narable_flow_cell_30(YC_prediction_cell_idx(:,11:20)), 2));
                SoilC_narable_npv_data_yrs_40	= full(sum(SoilC_narable_flow_cell_40(YC_prediction_cell_idx(:,21:30)), 2));
                SoilC_narable_npv_data_yrs_50	= full(sum(SoilC_narable_flow_cell_50(YC_prediction_cell_idx(:,31:40)), 2));
                
                SoilC_arable_npv_data_yrs       = SoilC_arable_ann_cell(YC_prediction_cell_idx) * delta_data_yrs;
                SoilC_arable_npv_data_yrs_20	= full(sum(SoilC_arable_flow_cell_20(YC_prediction_cell_idx(:,1:10)), 2));
                SoilC_arable_npv_data_yrs_30	= full(sum(SoilC_arable_flow_cell_30(YC_prediction_cell_idx(:,11:20)), 2));
                SoilC_arable_npv_data_yrs_40	= full(sum(SoilC_arable_flow_cell_40(YC_prediction_cell_idx(:,21:30)), 2));
                SoilC_arable_npv_data_yrs_50	= full(sum(SoilC_arable_flow_cell_50(YC_prediction_cell_idx(:,31:40)), 2));

                % NPV of Carbon annuities remaining years up to end of rotation:
                SoilC_narable_npv_final_yrs = delta_rot_cell .* SoilC_narable_ann_cell(YC_prediction_cell_idx(:, end));
                SoilC_arable_npv_final_yrs  = delta_rot_cell .* SoilC_arable_ann_cell(YC_prediction_cell_idx(:, end));

                % NPV of Carbon annuities
                SoilC_narable_npv_cell     = SoilC_narable_npv_data_yrs + SoilC_narable_npv_final_yrs;        
                SoilC_arable_npv_cell      = SoilC_arable_npv_data_yrs + SoilC_arable_npv_final_yrs;        

                % Annuity of Annuities for arable & non-arable land areas:
                es_forestry.SoilC.ValAnn.(species) = gamma_rot_cell .* (SoilC_narable_npv_cell .* narable2wood_ha_cell + SoilC_arable_npv_cell .* arable2wood_ha_cell);
                
                % Annuity of Annuities for arable & non-arable land areas:
                es_forestry.SoilC.FlowAnn20.(species) = (SoilC_narable_npv_data_yrs_20 .* narable2wood_ha_cell + SoilC_arable_npv_data_yrs_20 .* arable2wood_ha_cell) / 10;
                es_forestry.SoilC.FlowAnn30.(species) = (SoilC_narable_npv_data_yrs_30 .* narable2wood_ha_cell + SoilC_arable_npv_data_yrs_30 .* arable2wood_ha_cell) / 10;
                es_forestry.SoilC.FlowAnn40.(species) = (SoilC_narable_npv_data_yrs_40 .* narable2wood_ha_cell + SoilC_arable_npv_data_yrs_40 .* arable2wood_ha_cell) / 10;
                es_forestry.SoilC.FlowAnn50.(species) = (SoilC_narable_npv_data_yrs_50 .* narable2wood_ha_cell + SoilC_arable_npv_data_yrs_50 .* arable2wood_ha_cell) / 10;
                
                % Accumulate Forest Mixes
                es_forestry.SoilC.ValAnn.('Mix6040')	= es_forestry.SoilC.ValAnn.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.ValAnn.(species);
                es_forestry.SoilC.ValAnn.('Current')	= es_forestry.SoilC.ValAnn.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.ValAnn.(species);
                es_forestry.SoilC.FlowAnn20.('Mix6040') = es_forestry.SoilC.FlowAnn20.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.FlowAnn20.(species);
                es_forestry.SoilC.FlowAnn20.('Current') = es_forestry.SoilC.FlowAnn20.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.FlowAnn20.(species);
                es_forestry.SoilC.FlowAnn30.('Mix6040') = es_forestry.SoilC.FlowAnn30.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.FlowAnn30.(species);
                es_forestry.SoilC.FlowAnn30.('Current') = es_forestry.SoilC.FlowAnn30.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.FlowAnn30.(species);
                es_forestry.SoilC.FlowAnn40.('Mix6040') = es_forestry.SoilC.FlowAnn40.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.FlowAnn40.(species);
                es_forestry.SoilC.FlowAnn40.('Current') = es_forestry.SoilC.FlowAnn40.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.FlowAnn40.(species);
                es_forestry.SoilC.FlowAnn50.('Mix6040') = es_forestry.SoilC.FlowAnn50.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.FlowAnn50.(species);
                es_forestry.SoilC.FlowAnn50.('Current') = es_forestry.SoilC.FlowAnn50.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.FlowAnn50.(species);
                
                % (e) Soil Carbon: Quantity
                % -------------------------
                
                % Annuity of Annuities for arable & non-arable land areas:
                es_forestry.SoilC.QntYr.(species)   = (ForestGHG.SoilC_QntYr.narable.(species) .* narable2wood_ha_cell + ForestGHG.SoilC_QntYr.arable.(species) .* arable2wood_ha_cell);
                es_forestry.SoilC.QntYr20.(species) = (ForestGHG.SoilC_QntYr20.narable.(species) .* narable2wood_ha_cell + ForestGHG.SoilC_QntYr20.arable.(species) .* arable2wood_ha_cell);
                es_forestry.SoilC.QntYr30.(species) = (ForestGHG.SoilC_QntYr30.narable.(species) .* narable2wood_ha_cell + ForestGHG.SoilC_QntYr30.arable.(species) .* arable2wood_ha_cell);
                es_forestry.SoilC.QntYr40.(species) = (ForestGHG.SoilC_QntYr40.narable.(species) .* narable2wood_ha_cell + ForestGHG.SoilC_QntYr40.arable.(species) .* arable2wood_ha_cell);
                es_forestry.SoilC.QntYr50.(species) = (ForestGHG.SoilC_QntYr50.narable.(species) .* narable2wood_ha_cell + ForestGHG.SoilC_QntYr50.arable.(species) .* arable2wood_ha_cell);
                
                
                % Accumulate Forest Mixes
                es_forestry.SoilC.QntYr.('Mix6040')   = es_forestry.SoilC.QntYr.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.QntYr.(species);
                es_forestry.SoilC.QntYr.('Current')   = es_forestry.SoilC.QntYr.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.QntYr.(species);
                es_forestry.SoilC.QntYr20.('Mix6040') = es_forestry.SoilC.QntYr20.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.QntYr20.(species);
                es_forestry.SoilC.QntYr20.('Current') = es_forestry.SoilC.QntYr20.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.QntYr20.(species);
                es_forestry.SoilC.QntYr30.('Mix6040') = es_forestry.SoilC.QntYr30.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.QntYr30.(species);
                es_forestry.SoilC.QntYr30.('Current') = es_forestry.SoilC.QntYr30.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.QntYr30.(species);
                es_forestry.SoilC.QntYr40.('Mix6040') = es_forestry.SoilC.QntYr40.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.QntYr40.(species);
                es_forestry.SoilC.QntYr40.('Current') = es_forestry.SoilC.QntYr40.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.QntYr40.(species);
                es_forestry.SoilC.QntYr50.('Mix6040') = es_forestry.SoilC.QntYr50.('Mix6040') + species_prop_6040.(species) .* es_forestry.SoilC.QntYr50.(species);
                es_forestry.SoilC.QntYr50.('Current') = es_forestry.SoilC.QntYr50.('Current') + species_prop_cell.(species) .* es_forestry.SoilC.QntYr50.(species);
                
                                
            end

        end
                                   
    end

end
