function out = fcn_collect_output(MP, PV, es_agriculture, es_forestry, carbon_price)

    % 2k grid cell id
    out.new2kid = PV.new2kid;
    ncells = length(out.new2kid);

    % Total hectares in region
    out.tot_area = PV.wood_ha+PV.farm_ha+PV.sngrass_ha+PV.urban_ha+PV.water_ha;

    % Hectares of five high-level land uses
    out.wood_ha = PV.wood_ha;
    out.sngrass_ha = PV.sngrass_ha;
    out.urban_ha = PV.urban_ha;
    out.water_ha = PV.water_ha;
    out.farm_ha = PV.farm_ha;

    %% Agriculture
    if MP.run_agriculture
        % Total agriculture from above
        % Hectares of arable land
        out.arable_ha_20 = mean(es_agriculture.arable_ha(:,1:10),2);
        out.arable_ha_30 = mean(es_agriculture.arable_ha(:,11:20),2);
        out.arable_ha_40 = mean(es_agriculture.arable_ha(:,21:30),2);
        out.arable_ha_50 = mean(es_agriculture.arable_ha(:,31:40),2);
        % Hectares of grassland
        out.grass_ha_20 = mean(es_agriculture.grass_ha(:,1:10),2);
        out.grass_ha_30 = mean(es_agriculture.grass_ha(:,11:20),2);
        out.grass_ha_40 = mean(es_agriculture.grass_ha(:,21:30),2);
        out.grass_ha_50 = mean(es_agriculture.grass_ha(:,31:40),2);
        % Hectares of crop types
        out.wheat_ha_20 = mean(es_agriculture.wheat_ha(:,1:10),2);
        out.wheat_ha_30 = mean(es_agriculture.wheat_ha(:,11:20),2);
        out.wheat_ha_40 = mean(es_agriculture.wheat_ha(:,21:30),2);
        out.wheat_ha_50 = mean(es_agriculture.wheat_ha(:,31:40),2);
        out.osr_ha_20 = mean(es_agriculture.osr_ha(:,1:10),2);
        out.osr_ha_30 = mean(es_agriculture.osr_ha(:,11:20),2);
        out.osr_ha_40 = mean(es_agriculture.osr_ha(:,21:30),2);
        out.osr_ha_50 = mean(es_agriculture.osr_ha(:,31:40),2);
        out.wbar_ha_20 = mean(es_agriculture.wbar_ha(:,1:10),2);
        out.wbar_ha_30 = mean(es_agriculture.wbar_ha(:,11:20),2);
        out.wbar_ha_40 = mean(es_agriculture.wbar_ha(:,21:30),2);
        out.wbar_ha_50 = mean(es_agriculture.wbar_ha(:,31:40),2);
        out.sbar_ha_20 = mean(es_agriculture.sbar_ha(:,1:10),2);
        out.sbar_ha_30 = mean(es_agriculture.sbar_ha(:,11:20),2);
        out.sbar_ha_40 = mean(es_agriculture.sbar_ha(:,21:30),2);
        out.sbar_ha_50 = mean(es_agriculture.sbar_ha(:,31:40),2);
        out.pot_ha_20 = mean(es_agriculture.pot_ha(:,1:10),2);
        out.pot_ha_30 = mean(es_agriculture.pot_ha(:,11:20),2);
        out.pot_ha_40 = mean(es_agriculture.pot_ha(:,21:30),2);
        out.pot_ha_50 = mean(es_agriculture.pot_ha(:,31:40),2);
        out.sb_ha_20 = mean(es_agriculture.sb_ha(:,1:10),2);
        out.sb_ha_30 = mean(es_agriculture.sb_ha(:,11:20),2);
        out.sb_ha_40 = mean(es_agriculture.sb_ha(:,21:30),2);
        out.sb_ha_50 = mean(es_agriculture.sb_ha(:,31:40),2);
        out.other_ha_20 = mean(es_agriculture.other_ha(:,1:10),2);
        out.other_ha_30 = mean(es_agriculture.other_ha(:,11:20),2);
        out.other_ha_40 = mean(es_agriculture.other_ha(:,21:30),2);
        out.other_ha_50 = mean(es_agriculture.other_ha(:,31:40),2);
        % Hectares of grassland types
        out.pgrass_ha_20 = mean(es_agriculture.pgrass_ha(:,1:10),2);
        out.pgrass_ha_30 = mean(es_agriculture.pgrass_ha(:,11:20),2);
        out.pgrass_ha_40 = mean(es_agriculture.pgrass_ha(:,21:30),2);
        out.pgrass_ha_50 = mean(es_agriculture.pgrass_ha(:,31:40),2);
        out.tgrass_ha_20 = mean(es_agriculture.tgrass_ha(:,1:10),2);
        out.tgrass_ha_30 = mean(es_agriculture.tgrass_ha(:,11:20),2);
        out.tgrass_ha_40 = mean(es_agriculture.tgrass_ha(:,21:30),2);
        out.tgrass_ha_50 = mean(es_agriculture.tgrass_ha(:,31:40),2);
        out.rgraz_ha_20 = mean(es_agriculture.rgraz_ha(:,1:10),2);
        out.rgraz_ha_30 = mean(es_agriculture.rgraz_ha(:,11:20),2);
        out.rgraz_ha_40 = mean(es_agriculture.rgraz_ha(:,21:30),2);
        out.rgraz_ha_50 = mean(es_agriculture.rgraz_ha(:,31:40),2);
        out.dairy_20 = mean(es_agriculture.dairy(:,1:10),2);
        out.dairy_30 = mean(es_agriculture.dairy(:,11:20),2);
        out.dairy_40 = mean(es_agriculture.dairy(:,21:30),2);
        out.dairy_50 = mean(es_agriculture.dairy(:,31:40),2);
        out.beef_20 = mean(es_agriculture.beef(:,1:10),2);
        out.beef_30 = mean(es_agriculture.beef(:,11:20),2);
        out.beef_40 = mean(es_agriculture.beef(:,21:30),2);
        out.beef_50 = mean(es_agriculture.beef(:,31:40),2);
        out.sheep_20 = mean(es_agriculture.sheep(:,1:10),2);
        out.sheep_30 = mean(es_agriculture.sheep(:,11:20),2);
        out.sheep_40 = mean(es_agriculture.sheep(:,21:30),2);
        out.sheep_50 = mean(es_agriculture.sheep(:,31:40),2);
        out.livestock_20 = mean(es_agriculture.livestock(:,1:10),2);
        out.livestock_30 = mean(es_agriculture.livestock(:,11:20),2);
        out.livestock_40 = mean(es_agriculture.livestock(:,21:30),2);
        out.livestock_50 = mean(es_agriculture.livestock(:,31:40),2);
        % Food
        out.wheat_food_20 = mean(es_agriculture.wheat_food(:,1:10),2);
        out.wheat_food_30 = mean(es_agriculture.wheat_food(:,11:20),2);
        out.wheat_food_40 = mean(es_agriculture.wheat_food(:,21:30),2);
        out.wheat_food_50 = mean(es_agriculture.wheat_food(:,31:40),2);
        out.osr_food_20 = mean(es_agriculture.osr_food(:,1:10),2);
        out.osr_food_30 = mean(es_agriculture.osr_food(:,11:20),2);
        out.osr_food_40 = mean(es_agriculture.osr_food(:,21:30),2);
        out.osr_food_50 = mean(es_agriculture.osr_food(:,31:40),2);
        out.wbar_food_20 = mean(es_agriculture.wbar_food(:,1:10),2);
        out.wbar_food_30 = mean(es_agriculture.wbar_food(:,11:20),2);
        out.wbar_food_40 = mean(es_agriculture.wbar_food(:,21:30),2);
        out.wbar_food_50 = mean(es_agriculture.wbar_food(:,31:40),2);
        out.sbar_food_20 = mean(es_agriculture.sbar_food(:,1:10),2);
        out.sbar_food_30 = mean(es_agriculture.sbar_food(:,11:20),2);
        out.sbar_food_40 = mean(es_agriculture.sbar_food(:,21:30),2);
        out.sbar_food_50 = mean(es_agriculture.sbar_food(:,31:40),2);
        out.pot_food_20 = mean(es_agriculture.pot_food(:,1:10),2);
        out.pot_food_30 = mean(es_agriculture.pot_food(:,11:20),2);
        out.pot_food_40 = mean(es_agriculture.pot_food(:,21:30),2);
        out.pot_food_50 = mean(es_agriculture.pot_food(:,31:40),2);
        out.sb_food_20 = mean(es_agriculture.sb_food(:,1:10),2);
        out.sb_food_30 = mean(es_agriculture.sb_food(:,11:20),2);
        out.sb_food_40 = mean(es_agriculture.sb_food(:,21:30),2);
        out.sb_food_50 = mean(es_agriculture.sb_food(:,31:40),2);
        out.food_20 = mean(es_agriculture.food(:,1:10),2);
        out.food_30 = mean(es_agriculture.food(:,11:20),2);
        out.food_40 = mean(es_agriculture.food(:,21:30),2);
        out.food_50 = mean(es_agriculture.food(:,31:40),2);
        % Farm profit annuity
        out.arable_profit_ann = es_agriculture.arable_profit_ann;
        out.livestock_profit_ann = es_agriculture.livestock_profit_ann;
        out.farm_profit_ann = es_agriculture.farm_profit_ann;
        % Farm profit annual flow in each decade
        out.arable_profit_flow_20 = mean(es_agriculture.arable_profit(:, 1:10), 2);
        out.arable_profit_flow_30 = mean(es_agriculture.arable_profit(:, 11:20), 2);
        out.arable_profit_flow_40 = mean(es_agriculture.arable_profit(:, 21:30), 2);
        out.arable_profit_flow_50 = mean(es_agriculture.arable_profit(:, 31:40), 2);
        out.livestock_profit_flow_20 = mean(es_agriculture.livestock_profit(:, 1:10), 2);
        out.livestock_profit_flow_30 = mean(es_agriculture.livestock_profit(:, 11:20), 2);
        out.livestock_profit_flow_40 = mean(es_agriculture.livestock_profit(:, 21:30), 2);
        out.livestock_profit_flow_50 = mean(es_agriculture.livestock_profit(:, 31:40), 2);
        out.farm_profit_flow_20 = mean(es_agriculture.farm_profit(:, 1:10), 2);
        out.farm_profit_flow_30 = mean(es_agriculture.farm_profit(:, 11:20), 2);
        out.farm_profit_flow_40 = mean(es_agriculture.farm_profit(:, 21:30), 2);
        out.farm_profit_flow_50 = mean(es_agriculture.farm_profit(:, 31:40), 2);

        if MP.run_ghg
            % Farm carbon sequestration quantity
            out.ghg_arable_20 = mean(es_agriculture.ghg_arable(:, 1:10), 2);
            out.ghg_arable_30 = mean(es_agriculture.ghg_arable(:, 11:20), 2);
            out.ghg_arable_40 = mean(es_agriculture.ghg_arable(:, 21:30), 2);
            out.ghg_arable_50 = mean(es_agriculture.ghg_arable(:, 31:40), 2);
            out.ghg_grass_20 = mean(es_agriculture.ghg_grass(:, 1:10), 2);
            out.ghg_grass_30 = mean(es_agriculture.ghg_grass(:, 11:20), 2);
            out.ghg_grass_40 = mean(es_agriculture.ghg_grass(:, 21:30), 2);
            out.ghg_grass_50 = mean(es_agriculture.ghg_grass(:, 31:40), 2);
            out.ghg_livestock_20 = mean(es_agriculture.ghg_livestock(:, 1:10), 2);
            out.ghg_livestock_30 = mean(es_agriculture.ghg_livestock(:, 11:20), 2);
            out.ghg_livestock_40 = mean(es_agriculture.ghg_livestock(:, 21:30), 2);
            out.ghg_livestock_50 = mean(es_agriculture.ghg_livestock(:, 31:40), 2);
            out.ghg_farm_20 = mean(es_agriculture.ghg_farm(:, 1:10), 2);
            out.ghg_farm_30 = mean(es_agriculture.ghg_farm(:, 11:20), 2);
            out.ghg_farm_40 = mean(es_agriculture.ghg_farm(:, 21:30), 2);
            out.ghg_farm_50 = mean(es_agriculture.ghg_farm(:, 31:40), 2);
            % Farm carbon sequestration value annuity
            out.ghg_arable_ann = es_agriculture.ghg_arable_ann;
            out.ghg_grass_ann = es_agriculture.ghg_grass_ann;
            out.ghg_livestock_ann = es_agriculture.ghg_livestock_ann;
            out.ghg_farm_ann = es_agriculture.ghg_farm_ann;
            % Farm carbon sequestration value flow annuity in each decade
            out.ghg_arable_flow_20 = mean(es_agriculture.ghg_arable(:, 1:10) .* carbon_price(1:10)', 2);
            out.ghg_arable_flow_30 = mean(es_agriculture.ghg_arable(:, 11:20) .* carbon_price(11:20)', 2);
            out.ghg_arable_flow_40 = mean(es_agriculture.ghg_arable(:, 21:30) .* carbon_price(21:30)', 2);
            out.ghg_arable_flow_50 = mean(es_agriculture.ghg_arable(:, 31:40) .* carbon_price(31:40)', 2);
            out.ghg_grass_flow_20 = mean(es_agriculture.ghg_grass(:, 1:10) .* carbon_price(1:10)', 2);
            out.ghg_grass_flow_30 = mean(es_agriculture.ghg_grass(:, 11:20) .* carbon_price(11:20)', 2);
            out.ghg_grass_flow_40 = mean(es_agriculture.ghg_grass(:, 21:30) .* carbon_price(21:30)', 2);
            out.ghg_grass_flow_50 = mean(es_agriculture.ghg_grass(:, 31:40) .* carbon_price(31:40)', 2);
            out.ghg_livestock_flow_20 = mean(es_agriculture.ghg_livestock(:, 1:10) .* carbon_price(1:10)', 2);
            out.ghg_livestock_flow_30 = mean(es_agriculture.ghg_livestock(:, 11:20) .* carbon_price(11:20)', 2);
            out.ghg_livestock_flow_40 = mean(es_agriculture.ghg_livestock(:, 21:30) .* carbon_price(21:30)', 2);
            out.ghg_livestock_flow_50 = mean(es_agriculture.ghg_livestock(:, 31:40) .* carbon_price(31:40)', 2);
            out.ghg_farm_flow_20 = mean(es_agriculture.ghg_farm(:, 1:10) .* carbon_price(1:10)', 2);
            out.ghg_farm_flow_30 = mean(es_agriculture.ghg_farm(:, 11:20) .* carbon_price(11:20)', 2);
            out.ghg_farm_flow_40 = mean(es_agriculture.ghg_farm(:, 21:30) .* carbon_price(21:30)', 2);
            out.ghg_farm_flow_50 = mean(es_agriculture.ghg_farm(:, 31:40) .* carbon_price(31:40)', 2);
        end
    end

    %% Forestry
    if MP.run_forestry
        % Total woodland from above
        % Non-farm and farm woodland
        out.nfwood_ha = (1-PV.p_fwood).*PV.wood_ha;
        out.fwood_ha = PV.p_fwood.*PV.wood_ha;
        % Split of broadleaf and coniferous woodland
        out.broad_ha = PV.p_decid.*PV.wood_ha;
        out.conif_ha = PV.p_conif.*PV.wood_ha;
        % Yield class / ESC score (broadleaf and coniferous)
        out.broad_yc_20 = double(mode(es_forestry.YC_prediction_cell.PedunculateOak(:,1:10),2));
        out.broad_yc_30 = double(mode(es_forestry.YC_prediction_cell.PedunculateOak(:,11:20),2));
        out.broad_yc_40 = double(mode(es_forestry.YC_prediction_cell.PedunculateOak(:,21:30),2));
        out.broad_yc_50 = double(mode(es_forestry.YC_prediction_cell.PedunculateOak(:,31:40),2));
        out.conif_yc_20 = double(mode(es_forestry.YC_prediction_cell.SitkaSpruce(:,1:10),2));
        out.conif_yc_30 = double(mode(es_forestry.YC_prediction_cell.SitkaSpruce(:,11:20),2));
        out.conif_yc_40 = double(mode(es_forestry.YC_prediction_cell.SitkaSpruce(:,21:30),2));
        out.conif_yc_50 = double(mode(es_forestry.YC_prediction_cell.SitkaSpruce(:,31:40),2));
        % Rotation period (broadleaf and coniferous)
        out.broad_rp = es_forestry.RotPeriod_cell.PedunculateOak;
        out.conif_rp = es_forestry.RotPeriod_cell.SitkaSpruce;
        % Timber volume
        out.timber_broad_yr = es_forestry.Timber.QntYr.PedunculateOak;
        out.timber_conif_yr = es_forestry.Timber.QntYr.SitkaSpruce;
        out.timber_mixed_yr = es_forestry.Timber.QntYr.Mix6040;
        out.timber_current_yr = es_forestry.Timber.QntYr.Current;
        out.timber_broad_20 = es_forestry.Timber.QntYr20.PedunculateOak;
        out.timber_broad_30 = es_forestry.Timber.QntYr30.PedunculateOak;
        out.timber_broad_40 = es_forestry.Timber.QntYr40.PedunculateOak;
        out.timber_broad_50 = es_forestry.Timber.QntYr50.PedunculateOak;
        out.timber_conif_20 = es_forestry.Timber.QntYr20.SitkaSpruce;
        out.timber_conif_30 = es_forestry.Timber.QntYr30.SitkaSpruce;
        out.timber_conif_40 = es_forestry.Timber.QntYr40.SitkaSpruce;
        out.timber_conif_50 = es_forestry.Timber.QntYr50.SitkaSpruce;
        out.timber_mixed_20 = es_forestry.Timber.QntYr20.Mix6040;
        out.timber_mixed_30 = es_forestry.Timber.QntYr30.Mix6040;
        out.timber_mixed_40 = es_forestry.Timber.QntYr40.Mix6040;
        out.timber_mixed_50 = es_forestry.Timber.QntYr50.Mix6040;
        out.timber_current_20 = es_forestry.Timber.QntYr20.Current;
        out.timber_current_30 = es_forestry.Timber.QntYr30.Current;
        out.timber_current_40 = es_forestry.Timber.QntYr40.Current;
        out.timber_current_50 = es_forestry.Timber.QntYr50.Current;
        % Timber profit annuity over rotation
        out.timber_broad_ann = es_forestry.Timber.ValAnn.PedunculateOak;
        out.timber_conif_ann = es_forestry.Timber.ValAnn.SitkaSpruce;
        out.timber_mixed_ann = es_forestry.Timber.ValAnn.Mix6040;
        out.timber_current_ann = es_forestry.Timber.ValAnn.Current;
        % Timber profit flow annuity in each decade
        out.timber_broad_flow_20 = es_forestry.Timber.FlowAnn20.PedunculateOak;
        out.timber_broad_flow_30 = es_forestry.Timber.FlowAnn30.PedunculateOak;
        out.timber_broad_flow_40 = es_forestry.Timber.FlowAnn40.PedunculateOak;
        out.timber_broad_flow_50 = es_forestry.Timber.FlowAnn50.PedunculateOak;
        out.timber_conif_flow_20 = es_forestry.Timber.FlowAnn20.SitkaSpruce;
        out.timber_conif_flow_30 = es_forestry.Timber.FlowAnn30.SitkaSpruce;
        out.timber_conif_flow_40 = es_forestry.Timber.FlowAnn40.SitkaSpruce;
        out.timber_conif_flow_50 = es_forestry.Timber.FlowAnn50.SitkaSpruce;
        out.timber_mixed_flow_20 = es_forestry.Timber.FlowAnn20.Mix6040;
        out.timber_mixed_flow_30 = es_forestry.Timber.FlowAnn30.Mix6040;
        out.timber_mixed_flow_40 = es_forestry.Timber.FlowAnn40.Mix6040;
        out.timber_mixed_flow_50 = es_forestry.Timber.FlowAnn50.Mix6040;
        out.timber_current_flow_20 = es_forestry.Timber.FlowAnn20.Current;
        out.timber_current_flow_30 = es_forestry.Timber.FlowAnn30.Current;
        out.timber_current_flow_40 = es_forestry.Timber.FlowAnn40.Current;
        out.timber_current_flow_50 = es_forestry.Timber.FlowAnn50.Current;
        
        if MP.run_ghg
            % Timber carbon sequestration quantity
            out.ghg_broad_yr = es_forestry.TimberC.QntYr.PedunculateOak;
            out.ghg_conif_yr = es_forestry.TimberC.QntYr.SitkaSpruce;
            out.ghg_mixed_yr = es_forestry.TimberC.QntYr.Mix6040;
            out.ghg_current_yr = es_forestry.TimberC.QntYr.Current;
            out.ghg_broad_yrUB = es_forestry.TimberC.QntYrUB.PedunculateOak;
            out.ghg_conif_yrUB = es_forestry.TimberC.QntYrUB.SitkaSpruce;
            out.ghg_mixed_yrUB = es_forestry.TimberC.QntYrUB.Mix6040;
            out.ghg_current_yrUB = es_forestry.TimberC.QntYrUB.Current;
            out.ghg_broad_20 = es_forestry.TimberC.QntYr20.PedunculateOak;
            out.ghg_broad_30 = es_forestry.TimberC.QntYr30.PedunculateOak;
            out.ghg_broad_40 = es_forestry.TimberC.QntYr40.PedunculateOak;
            out.ghg_broad_50 = es_forestry.TimberC.QntYr50.PedunculateOak;
            out.ghg_conif_20 = es_forestry.TimberC.QntYr20.SitkaSpruce;
            out.ghg_conif_30 = es_forestry.TimberC.QntYr30.SitkaSpruce;
            out.ghg_conif_40 = es_forestry.TimberC.QntYr40.SitkaSpruce;
            out.ghg_conif_50 = es_forestry.TimberC.QntYr50.SitkaSpruce;
            out.ghg_mixed_20 = es_forestry.TimberC.QntYr20.Mix6040;
            out.ghg_mixed_30 = es_forestry.TimberC.QntYr30.Mix6040;
            out.ghg_mixed_40 = es_forestry.TimberC.QntYr40.Mix6040;
            out.ghg_mixed_50 = es_forestry.TimberC.QntYr50.Mix6040;
            out.ghg_current_20 = es_forestry.TimberC.QntYr20.Current;
            out.ghg_current_30 = es_forestry.TimberC.QntYr30.Current;
            out.ghg_current_40 = es_forestry.TimberC.QntYr40.Current;
            out.ghg_current_50 = es_forestry.TimberC.QntYr50.Current;
            % Timber carbon sequestration value annuity over two rotations
            out.ghg_broad_ann = es_forestry.TimberC.ValAnn.PedunculateOak;
            out.ghg_conif_ann = es_forestry.TimberC.ValAnn.SitkaSpruce;
            out.ghg_mixed_ann = es_forestry.TimberC.ValAnn.Mix6040;
            out.ghg_current_ann = es_forestry.TimberC.ValAnn.Current;
            % Timber carbon sequestration value flow annuity in each decade
            out.ghg_broad_flow_20 = es_forestry.TimberC.FlowAnn20.PedunculateOak;
            out.ghg_broad_flow_30 = es_forestry.TimberC.FlowAnn30.PedunculateOak;
            out.ghg_broad_flow_40 = es_forestry.TimberC.FlowAnn40.PedunculateOak;
            out.ghg_broad_flow_50 = es_forestry.TimberC.FlowAnn50.PedunculateOak;
            out.ghg_conif_flow_20 = es_forestry.TimberC.FlowAnn20.SitkaSpruce;
            out.ghg_conif_flow_30 = es_forestry.TimberC.FlowAnn30.SitkaSpruce;
            out.ghg_conif_flow_40 = es_forestry.TimberC.FlowAnn40.SitkaSpruce;
            out.ghg_conif_flow_50 = es_forestry.TimberC.FlowAnn50.SitkaSpruce;
            out.ghg_mixed_flow_20 = es_forestry.TimberC.FlowAnn20.Mix6040;
            out.ghg_mixed_flow_30 = es_forestry.TimberC.FlowAnn30.Mix6040;
            out.ghg_mixed_flow_40 = es_forestry.TimberC.FlowAnn40.Mix6040;
            out.ghg_mixed_flow_50 = es_forestry.TimberC.FlowAnn50.Mix6040;
            out.ghg_current_flow_20 = es_forestry.TimberC.FlowAnn20.Current;
            out.ghg_current_flow_30 = es_forestry.TimberC.FlowAnn30.Current;
            out.ghg_current_flow_40 = es_forestry.TimberC.FlowAnn40.Current;
            out.ghg_current_flow_50 = es_forestry.TimberC.FlowAnn50.Current;
            
            % If soil carbon results have been returned, save these
            % Else, return a vector of zeros
            if isfield(es_forestry.SoilC.QntYr,'PedunculateOak')
                % Soil carbon quantity
                out.ghg_soil_broad_yr = es_forestry.SoilC.QntYr.PedunculateOak;
                out.ghg_soil_conif_yr = es_forestry.SoilC.QntYr.SitkaSpruce;
                out.ghg_soil_mixed_yr = es_forestry.SoilC.QntYr.Mix6040;
                out.ghg_soil_current_yr = es_forestry.SoilC.QntYr.Current;
                out.ghg_soil_broad_20 = es_forestry.SoilC.QntYr20.PedunculateOak;
                out.ghg_soil_broad_30 = es_forestry.SoilC.QntYr30.PedunculateOak;
                out.ghg_soil_broad_40 = es_forestry.SoilC.QntYr40.PedunculateOak;
                out.ghg_soil_broad_50 = es_forestry.SoilC.QntYr50.PedunculateOak;
                out.ghg_soil_conif_20 = es_forestry.SoilC.QntYr20.SitkaSpruce;
                out.ghg_soil_conif_30 = es_forestry.SoilC.QntYr30.SitkaSpruce;
                out.ghg_soil_conif_40 = es_forestry.SoilC.QntYr40.SitkaSpruce;
                out.ghg_soil_conif_50 = es_forestry.SoilC.QntYr50.SitkaSpruce;
                out.ghg_soil_mixed_20 = es_forestry.SoilC.QntYr20.Mix6040;
                out.ghg_soil_mixed_30 = es_forestry.SoilC.QntYr30.Mix6040;
                out.ghg_soil_mixed_40 = es_forestry.SoilC.QntYr40.Mix6040;
                out.ghg_soil_mixed_50 = es_forestry.SoilC.QntYr50.Mix6040;
                out.ghg_soil_current_20 = es_forestry.SoilC.QntYr20.Current;
                out.ghg_soil_current_30 = es_forestry.SoilC.QntYr30.Current;
                out.ghg_soil_current_40 = es_forestry.SoilC.QntYr40.Current;
                out.ghg_soil_current_50 = es_forestry.SoilC.QntYr50.Current;
                
                % Soil carbon value annuity
                out.ghg_soil_broad_ann = es_forestry.SoilC.ValAnn.PedunculateOak;
                out.ghg_soil_conif_ann = es_forestry.SoilC.ValAnn.SitkaSpruce;
                out.ghg_soil_mixed_ann = es_forestry.SoilC.ValAnn.Mix6040;
                out.ghg_soil_current_ann = es_forestry.SoilC.ValAnn.Current;
                % Soil carbon value flow annuity in each decade
                out.ghg_soil_broad_flow_20 = es_forestry.SoilC.FlowAnn20.PedunculateOak;
                out.ghg_soil_broad_flow_30 = es_forestry.SoilC.FlowAnn30.PedunculateOak;
                out.ghg_soil_broad_flow_40 = es_forestry.SoilC.FlowAnn40.PedunculateOak;
                out.ghg_soil_broad_flow_50 = es_forestry.SoilC.FlowAnn50.PedunculateOak;
                out.ghg_soil_conif_flow_20 = es_forestry.SoilC.FlowAnn20.SitkaSpruce;
                out.ghg_soil_conif_flow_30 = es_forestry.SoilC.FlowAnn30.SitkaSpruce;
                out.ghg_soil_conif_flow_40 = es_forestry.SoilC.FlowAnn40.SitkaSpruce;
                out.ghg_soil_conif_flow_50 = es_forestry.SoilC.FlowAnn50.SitkaSpruce;
                out.ghg_soil_mixed_flow_20 = es_forestry.SoilC.FlowAnn20.Mix6040;
                out.ghg_soil_mixed_flow_30 = es_forestry.SoilC.FlowAnn30.Mix6040;
                out.ghg_soil_mixed_flow_40 = es_forestry.SoilC.FlowAnn40.Mix6040;
                out.ghg_soil_mixed_flow_50 = es_forestry.SoilC.FlowAnn50.Mix6040;
                out.ghg_soil_current_flow_20 = es_forestry.SoilC.FlowAnn20.Current;
                out.ghg_soil_current_flow_30 = es_forestry.SoilC.FlowAnn30.Current;
                out.ghg_soil_current_flow_40 = es_forestry.SoilC.FlowAnn40.Current;
                out.ghg_soil_current_flow_50 = es_forestry.SoilC.FlowAnn50.Current;
            else
                % Soil carbon quantity
                out.ghg_soil_broad_yr = zeros(ncells,1);
                out.ghg_soil_conif_yr = zeros(ncells,1);
                out.ghg_soil_mixed_yr = zeros(ncells,1);
                out.ghg_soil_current_yr = zeros(ncells,1);
                out.ghg_soil_broad_20 = zeros(ncells,1);
                out.ghg_soil_broad_30 = zeros(ncells,1);
                out.ghg_soil_broad_40 = zeros(ncells,1);
                out.ghg_soil_broad_50 = zeros(ncells,1);
                out.ghg_soil_conif_20 = zeros(ncells,1);
                out.ghg_soil_conif_30 = zeros(ncells,1);
                out.ghg_soil_conif_40 = zeros(ncells,1);
                out.ghg_soil_conif_50 = zeros(ncells,1);
                out.ghg_soil_mixed_20 = zeros(ncells,1);
                out.ghg_soil_mixed_30 = zeros(ncells,1);
                out.ghg_soil_mixed_40 = zeros(ncells,1);
                out.ghg_soil_mixed_50 = zeros(ncells,1);
                out.ghg_soil_current_20 = zeros(ncells,1);
                out.ghg_soil_current_30 = zeros(ncells,1);
                out.ghg_soil_current_40 = zeros(ncells,1);
                out.ghg_soil_current_50 = zeros(ncells,1);
                
                % Soil carbon value annuity
                out.ghg_soil_broad_ann = zeros(ncells,1);
                out.ghg_soil_conif_ann = zeros(ncells,1);
                out.ghg_soil_mixed_ann = zeros(ncells,1);
                out.ghg_soil_current_ann = zeros(ncells,1);
                % Soil carbon value flow annuity in each decade
                out.ghg_soil_broad_flow_20 = zeros(ncells,1);
                out.ghg_soil_broad_flow_30 = zeros(ncells,1);
                out.ghg_soil_broad_flow_40 = zeros(ncells,1);
                out.ghg_soil_broad_flow_50 = zeros(ncells,1);
                out.ghg_soil_conif_flow_20 = zeros(ncells,1);
                out.ghg_soil_conif_flow_30 = zeros(ncells,1);
                out.ghg_soil_conif_flow_40 = zeros(ncells,1);
                out.ghg_soil_conif_flow_50 = zeros(ncells,1);
                out.ghg_soil_mixed_flow_20 = zeros(ncells,1);
                out.ghg_soil_mixed_flow_30 = zeros(ncells,1);
                out.ghg_soil_mixed_flow_40 = zeros(ncells,1);
                out.ghg_soil_mixed_flow_50 = zeros(ncells,1);
                out.ghg_soil_current_flow_20 = zeros(ncells,1);
                out.ghg_soil_current_flow_30 = zeros(ncells,1);
                out.ghg_soil_current_flow_40 = zeros(ncells,1);
                out.ghg_soil_current_flow_50 = zeros(ncells,1);
            end
        end
    end
end
