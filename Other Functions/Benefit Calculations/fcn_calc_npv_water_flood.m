function benefit_flood_npv = fcn_calc_npv_water_flood(MP, elm_option, es_flood_all)

    % NEV flood value data
    % --------------------
    % es_flod_all holds sincle table with column for annual changes in 
    % flood damage mitigation value water for each cell. Note that only 
    % one value for each cell so assumed to be constant over all future 
    % years. 

    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = height(es_flood_all.arable_reversion_wood_noaccess);
    
    % NEV Flood Values Time Series
    % ----------------------------
    % Note: Access & No Access make no difference to flood benefits, so
    %       just use access results in both cases.
    if contains(elm_option, 'arable')
        NEV_flood_option_wood = es_flood_all.arable_reversion_wood_access.flood_value;
        NEV_flood_option_sng  = es_flood_all.arable_reversion_sng_access.flood_value;
    else
        NEV_flood_option_wood = es_flood_all.destocking_wood_access.flood_value;
        NEV_flood_option_sng  = es_flood_all.destocking_sng_access.flood_value;
    end
   
    % Extend to 100 year time series
    NEV_flood_option_wood = repmat(NEV_flood_option_wood,1,yrs_tser);
    NEV_flood_option_sng  = repmat(NEV_flood_option_sng,1,yrs_tser);
    
    % Ensure no NaNs
    NEV_flood_option_wood(isnan(NEV_flood_option_wood)) = 0;       
    NEV_flood_option_sng(isnan(NEV_flood_option_sng))   = 0;      
        
    
    % npv of time series from each year to end of time series    
    % -------------------------------------------------------
    npv_NEV_flood = zeros(N, yrs_NEV);
    for t =1:yrs_NEV
        % growth weights
        % --------------
        growth_wgts = ones(1, yrs_tser-t+1);
        if contains(elm_option, 'wood')
            growth_wgts(1:MP.forest_growth_years) = MP.forest_growth_wgt; 
            growth_wgts = 1 - growth_wgts;
        end
        % npv with weighting for 
        % --------------        
        npv_NEV_flood(:,t) = sum((NEV_flood_option_sng(:,t:end).*growth_wgts + NEV_flood_option_wood(:,t:end).*(1 - growth_wgts))./ (1 + MP.discount_rate).^(1:yrs_tser-t+1), 2);
    end
           
    % annuity equivalent of that npv
    % ------------------------------
    ann_NEV_flood = zeros(N, yrs_NEV);
    for t =1:yrs_NEV
        ann_NEV_flood(:,t) = npv_NEV_flood(:,t) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^ -(yrs_tser-t+1));
    end    
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_flood = ann_NEV_flood/MP.discount_rate;
    
    % express as npv in base year
    % ---------------------------
    npv_flood = npv_inf_NEV_flood ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base_year prices
    % ----------------------------------
    benefit_flood_npv = npv_flood * MP.rpi_flood;

end