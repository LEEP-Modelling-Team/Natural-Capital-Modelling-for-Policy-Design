function [npv_ghg_farm, npv_ghg_forestry, npv_ghg_soil_forestry] = fcn_calc_npv_ghg(baseline, es_agriculture, es_forestry, MP)

    % For land use change in each year of the 40 year NEV time series
    % calculate a npv of cost or benefit for a permanent land use change
    % expressed as a npv in MP.base_year and in a price base for 
    % MP.price_year
        
    % (1) Agriculture
    % ---------------
    
    % farm ghg change
    % ---------------    
    % ghg_farm holds annual sequestration in co2e (here values are negative 
    % as farming emits co2) for each of 40 years of NEV time series for 
    % each cell. 
    ghg_farm_chg = es_agriculture.ghg_farm - baseline.es_agriculture.ghg_farm;
    yrs_NEV = size(ghg_farm_chg,2); 
    
    % npv of time series from each year to end of time series    
    % -------------------------------------------------------
    npv_NEV_ghg_farm = zeros(size(ghg_farm_chg));
    for t =1:yrs_NEV
        npv_NEV_ghg_farm(:,t) = sum(ghg_farm_chg(:,t:yrs_NEV).*MP.carbon_price(t:yrs_NEV)' ./ (1 + MP.discount_rate).^(1:yrs_NEV-t+1), 2);
    end
    
    % annuity equivalent of that npv
    % ------------------------------
    ann_NEV_ghg_farm = zeros(size(ghg_farm_chg));
    for t =1:yrs_NEV
        ann_NEV_ghg_farm(:,t) = npv_NEV_ghg_farm(:,t) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^ -(yrs_NEV-t+1));
    end
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_ghg_farm = ann_NEV_ghg_farm/MP.discount_rate;
        
    % express as npv in base year
    % ---------------------------
    npv_ghg_farm = npv_inf_NEV_ghg_farm ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base prices
    % -----------------------------
    npv_ghg_farm = npv_ghg_farm * MP.rpi_ghg;    
    

    % (2) Forestry
    % ------------
    %  Carbon annuity calculated in NEV fcn_run_forestry is only a single
    %  value for each cell since Carbine does not respond to climate. This
    %  is calculated over a single rotation period and can be used as the
    %  annuity for a permanent land use change on the assumptiont that
    %  these timber carbon savings are repeated over all subsequent
    %  rotation
    
    % change in annuity forestry ghg
    % ------------------------------
    ann_NEV_ghg_forestry = es_forestry.TimberC.ValAnn.Mix6040 - baseline.es_forestry.TimberC.ValAnn.Mix6040;
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_ghg_forestry = ann_NEV_ghg_forestry/MP.discount_rate;
        
    % express as npv in base year
    % ---------------------------
    npv_ghg_forestry = npv_inf_NEV_ghg_forestry ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base prices
    % -----------------------------
    npv_ghg_forestry = npv_ghg_forestry * MP.rpi_ghg;    
    
    
    % (3) Forestry Soil
    % -----------------
    %  Carbon annuity calculated in NEV fcn_run_forestry is only a single
    %  value for each cell since Carbine does not respond to climate.
    %  In NEV the code the soil carbon changes over 2 rotation periods are
    %  converted into a NPV which is subsequently converted into an annuity
    %  to run over 1 rotation period. Since this analysis is a permanent
    %  land use change we reverse that calculation here taking the benefit
    %  to be that 2 year rotation 
    
    % change in annuity forestry ghg
    % ------------------------------
	% Note baseline soil carbon always zero as only associated with tree planting   
    ann_NEV_ghg_soil_forestry = es_forestry.SoilC.ValAnn.Mix6040 - baseline.es_forestry.SoilC.ValAnn.Mix6040;
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_ghg_soil_forestry = ann_NEV_ghg_soil_forestry/MP.discount_rate;
        
    % express as npv in base year
    % ---------------------------
    npv_ghg_soil_forestry = npv_inf_NEV_ghg_soil_forestry ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base prices
    % -----------------------------
    npv_ghg_soil_forestry = npv_ghg_soil_forestry * MP.rpi_ghg;    
 

end