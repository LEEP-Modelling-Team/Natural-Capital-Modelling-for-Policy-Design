function [quantity_totn, quantity_totp] = fcn_calc_quantity_water_quality(MP, elm_option, es_water_quality_all)
   

    % NEV nutrient change quantities
    % ------------------------------
    % es_water_quality_all holds table for each option recording annual 
    % changes in nutrient conentrations (chgtotn & chgtotp) under each 
    % option for each cell for each decade 2020, 2030, 2040 & 2050. 
    
    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = height(es_water_quality_all.arable_reversion_sng_access);

    
    % NEV change in nutrient concentrations 
    % -------------------------------------
    % Note: Access & No Access make no difference to water quality
    %       quantities, so just use access results in both cases.
    if contains(elm_option, 'arable')
        NEV_wqual_totn_option_wood = [repmat(es_water_quality_all.arable_reversion_wood_access.chgtotn_20, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_wood_access.chgtotn_30, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_wood_access.chgtotn_40, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_wood_access.chgtotn_50, 1, 10)];        
        NEV_wqual_totn_option_sng  = [repmat(es_water_quality_all.arable_reversion_sng_access.chgtotn_20, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_sng_access.chgtotn_30, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_sng_access.chgtotn_40, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_sng_access.chgtotn_50, 1, 10)];   
        NEV_wqual_totp_option_wood = [repmat(es_water_quality_all.arable_reversion_wood_access.chgtotp_20, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_wood_access.chgtotp_30, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_wood_access.chgtotp_40, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_wood_access.chgtotp_50, 1, 10)];        
        NEV_wqual_totp_option_sng  = [repmat(es_water_quality_all.arable_reversion_sng_access.chgtotp_20, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_sng_access.chgtotp_30, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_sng_access.chgtotp_40, 1, 10) ...
                                      repmat(es_water_quality_all.arable_reversion_sng_access.chgtotp_50, 1, 10)];   
    else

        NEV_wqual_totn_option_wood = [repmat(es_water_quality_all.destocking_wood_access.chgtotn_20, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_wood_access.chgtotn_30, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_wood_access.chgtotn_40, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_wood_access.chgtotn_50, 1, 10)];        
        NEV_wqual_totn_option_sng  = [repmat(es_water_quality_all.destocking_sng_access.chgtotn_20, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_sng_access.chgtotn_30, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_sng_access.chgtotn_40, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_sng_access.chgtotn_50, 1, 10)];   
        NEV_wqual_totp_option_wood = [repmat(es_water_quality_all.destocking_wood_access.chgtotp_20, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_wood_access.chgtotp_30, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_wood_access.chgtotp_40, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_wood_access.chgtotp_50, 1, 10)];        
        NEV_wqual_totp_option_sng  = [repmat(es_water_quality_all.destocking_sng_access.chgtotp_20, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_sng_access.chgtotp_30, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_sng_access.chgtotp_40, 1, 10) ...
                                      repmat(es_water_quality_all.destocking_sng_access.chgtotp_50, 1, 10)];   
    end
    
    % Extend to 100 year time series
    NEV_wqual_totn_option_wood = [NEV_wqual_totn_option_wood repmat(NEV_wqual_totn_option_wood(:,end),1,yrs_tser-yrs_NEV)];
    NEV_wqual_totn_option_sng  = [NEV_wqual_totn_option_sng  repmat(NEV_wqual_totn_option_sng(:,end),1,yrs_tser-yrs_NEV)];
    NEV_wqual_totp_option_wood = [NEV_wqual_totp_option_wood repmat(NEV_wqual_totp_option_wood(:,end),1,yrs_tser-yrs_NEV)];
    NEV_wqual_totp_option_sng  = [NEV_wqual_totp_option_sng  repmat(NEV_wqual_totp_option_sng(:,end),1,yrs_tser-yrs_NEV)];
    
    % Ensure no NaNs
    NEV_wqual_totn_option_wood(isnan(NEV_wqual_totn_option_wood)) = 0;       
    NEV_wqual_totn_option_sng(isnan(NEV_wqual_totn_option_sng))   = 0;  
    NEV_wqual_totp_option_wood(isnan(NEV_wqual_totp_option_wood)) = 0;       
    NEV_wqual_totp_option_sng(isnan(NEV_wqual_totp_option_sng))   = 0;      
    
    % mean of time series from each year to end of time series    
    % --------------------------------------------------------
    quantity_totn = zeros(N, yrs_NEV);
    quantity_totp = zeros(N, yrs_NEV);
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
        quantity_totn(:,t) = mean(NEV_wqual_totn_option_sng(:,t:end).*growth_wgts + NEV_wqual_totn_option_wood(:,t:end).*(1 - growth_wgts), 2);
        quantity_totp(:,t) = mean(NEV_wqual_totp_option_sng(:,t:end).*growth_wgts + NEV_wqual_totp_option_wood(:,t:end).*(1 - growth_wgts), 2);
    end
   
end
