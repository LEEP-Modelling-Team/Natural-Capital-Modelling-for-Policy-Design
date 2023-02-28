function quantity_flood = fcn_calc_quantity_flood(MP, elm_option, es_flooding_all)

    % NEV flood change quantities
    % ---------------------------
    % es_flooding_all holds table for each option recording annual value 
    % changes in flood events (chg_q5) under each option for each cell
    % for each decade 2020, 2030, 2040 & 2050. 
    
    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = height(es_flooding_all.arable_reversion_sng_access);

    
    % NEV change in high flow 
    % -----------------------
    % Note: Access & No Access make no difference to flood quantities 
    %       benefits, so just use access results in both cases.
    if contains(elm_option, 'arable')
        NEV_floodq_option_wood = [repmat(es_flooding_all.arable_reversion_wood_access.chgq5_20, 1, 10) ...
                                  repmat(es_flooding_all.arable_reversion_wood_access.chgq5_30, 1, 10) ...
                                  repmat(es_flooding_all.arable_reversion_wood_access.chgq5_40, 1, 10) ...
                                  repmat(es_flooding_all.arable_reversion_wood_access.chgq5_50, 1, 10)];        
        NEV_floodq_option_sng  = [repmat(es_flooding_all.arable_reversion_sng_access.chgq5_20, 1, 10) ...
                                  repmat(es_flooding_all.arable_reversion_sng_access.chgq5_30, 1, 10) ...
                                  repmat(es_flooding_all.arable_reversion_sng_access.chgq5_40, 1, 10) ...
                                  repmat(es_flooding_all.arable_reversion_sng_access.chgq5_50, 1, 10)];   
    else

        NEV_floodq_option_wood = [repmat(es_flooding_all.destocking_wood_access.chgq5_20, 1, 10) ...
                                  repmat(es_flooding_all.destocking_wood_access.chgq5_30, 1, 10) ...
                                  repmat(es_flooding_all.destocking_wood_access.chgq5_40, 1, 10) ...
                                  repmat(es_flooding_all.destocking_wood_access.chgq5_50, 1, 10)];        
        NEV_floodq_option_sng  = [repmat(es_flooding_all.destocking_sng_access.chgq5_20, 1, 10) ...
                                  repmat(es_flooding_all.destocking_sng_access.chgq5_30, 1, 10) ...
                                  repmat(es_flooding_all.destocking_sng_access.chgq5_40, 1, 10) ...
                                  repmat(es_flooding_all.destocking_sng_access.chgq5_50, 1, 10)];   
    end
    
    % Extend to 100 year time series
    NEV_floodq_option_wood = [NEV_floodq_option_wood repmat(NEV_floodq_option_wood(:,end),1,yrs_tser-yrs_NEV)];
    NEV_floodq_option_sng  = [NEV_floodq_option_sng  repmat(NEV_floodq_option_sng(:,end),1,yrs_tser-yrs_NEV)];
    
    % Ensure no NaNs
    NEV_floodq_option_wood(isnan(NEV_floodq_option_wood)) = 0;       
    NEV_floodq_option_sng(isnan(NEV_floodq_option_sng))   = 0;  
    
    
    % mean of time series from each year to end of time series    
    % --------------------------------------------------------
    quantity_flood = zeros(N, yrs_NEV);
    for t =1:yrs_NEV
        % growth weights
        % --------------
        growth_wgts = ones(1, yrs_tser-t+1);
        if contains(elm_option, 'wood')
            growth_wgts(1:MP.forest_growth_years) = MP.forest_growth_wgt; 
            growth_wgts = 1 - growth_wgts;
        end
        % mean with weighting for growth
        % ------------------------------
        quantity_flood(:,t) = mean(NEV_floodq_option_sng(:,t:end).*growth_wgts + NEV_floodq_option_wood(:,t:end).*(1 - growth_wgts), 2);
    end
    
end
