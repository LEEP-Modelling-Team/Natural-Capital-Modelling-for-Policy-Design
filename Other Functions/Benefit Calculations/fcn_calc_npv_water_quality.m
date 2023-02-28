function [benefit_wqual_totn_npv, benefit_wqual_totp_npv] = fcn_calc_npv_water_quality(MP, elm_option, es_wqual_all)
    
    % NEV water treatment value data
    % ------------------------------
    % es_wqual_all holds table for each option recording annual value 
    % changes in water treatment for total nitrates and total phosphates 
    % for each cell for each decade 2020, 2030, 2040 & 2050. 
    
    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = height(es_wqual_all.arable_reversion_sng_access);
    
    % NEV Water Treatment Values Time Series
    % --------------------------------------
    % Note: Access & No Access make no difference to water quality 
    %       benefits, so just use access results in both cases.
    if contains(elm_option, 'arable')
        NEV_wqual_totn_option_wood = [repmat(es_wqual_all.arable_reversion_wood_access.totn_ann_20, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_wood_access.totn_ann_30, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_wood_access.totn_ann_40, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_wood_access.totn_ann_50, 1, 10)];        
        NEV_wqual_totn_option_sng  = [repmat(es_wqual_all.arable_reversion_sng_access.totn_ann_20, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_sng_access.totn_ann_30, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_sng_access.totn_ann_40, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_sng_access.totn_ann_50, 1, 10)];   
        NEV_wqual_totp_option_wood = [repmat(es_wqual_all.arable_reversion_wood_access.totp_ann_20, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_wood_access.totp_ann_30, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_wood_access.totp_ann_40, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_wood_access.totp_ann_50, 1, 10)];        
        NEV_wqual_totp_option_sng  = [repmat(es_wqual_all.arable_reversion_sng_access.totp_ann_20, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_sng_access.totp_ann_30, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_sng_access.totp_ann_40, 1, 10) ...
                                      repmat(es_wqual_all.arable_reversion_sng_access.totp_ann_50, 1, 10)];                                     
    else

        NEV_wqual_totn_option_wood = [repmat(es_wqual_all.destocking_wood_access.totn_ann_20, 1, 10) ...
                                      repmat(es_wqual_all.destocking_wood_access.totn_ann_30, 1, 10) ...
                                      repmat(es_wqual_all.destocking_wood_access.totn_ann_40, 1, 10) ...
                                      repmat(es_wqual_all.destocking_wood_access.totn_ann_50, 1, 10)];        
        NEV_wqual_totn_option_sng  = [repmat(es_wqual_all.destocking_sng_access.totn_ann_20, 1, 10) ...
                                      repmat(es_wqual_all.destocking_sng_access.totn_ann_30, 1, 10) ...
                                      repmat(es_wqual_all.destocking_sng_access.totn_ann_40, 1, 10) ...
                                      repmat(es_wqual_all.destocking_sng_access.totn_ann_50, 1, 10)];   
        NEV_wqual_totp_option_wood = [repmat(es_wqual_all.destocking_wood_access.totp_ann_20, 1, 10) ...
                                      repmat(es_wqual_all.destocking_wood_access.totp_ann_30, 1, 10) ...
                                      repmat(es_wqual_all.destocking_wood_access.totp_ann_40, 1, 10) ...
                                      repmat(es_wqual_all.destocking_wood_access.totp_ann_50, 1, 10)];        
        NEV_wqual_totp_option_sng  = [repmat(es_wqual_all.destocking_sng_access.totp_ann_20, 1, 10) ...
                                      repmat(es_wqual_all.destocking_sng_access.totp_ann_30, 1, 10) ...
                                      repmat(es_wqual_all.destocking_sng_access.totp_ann_40, 1, 10) ...
                                      repmat(es_wqual_all.destocking_sng_access.totp_ann_50, 1, 10)];          
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
        
    % npv of time series from each year to end of time series    
    % -------------------------------------------------------
    npv_NEV_wqual_totn = zeros(N, yrs_NEV);
    npv_NEV_wqual_totp = zeros(N, yrs_NEV);
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
        npv_NEV_wqual_totn(:,t) = sum((NEV_wqual_totn_option_sng(:,t:end).*growth_wgts + NEV_wqual_totn_option_wood(:,t:end).*(1 - growth_wgts))./ (1 + MP.discount_rate).^(1:yrs_tser-t+1), 2);
        npv_NEV_wqual_totp(:,t) = sum((NEV_wqual_totp_option_sng(:,t:end).*growth_wgts + NEV_wqual_totp_option_wood(:,t:end).*(1 - growth_wgts))./ (1 + MP.discount_rate).^(1:yrs_tser-t+1), 2);
    end
            
    % annuity equivalent of that npv
    % ------------------------------
    ann_NEV_wqual_totn = zeros(N, yrs_NEV);
    ann_NEV_wqual_totp = zeros(N, yrs_NEV);
    for t =1:yrs_NEV
        ann_NEV_wqual_totn(:,t) = npv_NEV_wqual_totn(:,t) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^ -(yrs_tser-t+1));
        ann_NEV_wqual_totp(:,t) = npv_NEV_wqual_totp(:,t) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^ -(yrs_tser-t+1));
    end
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_wqual_totn = ann_NEV_wqual_totn/MP.discount_rate;
    npv_inf_NEV_wqual_totp = ann_NEV_wqual_totp/MP.discount_rate;
    
    % express as npv in base year
    % ---------------------------
    npv_wqual_totn = npv_inf_NEV_wqual_totn ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    npv_wqual_totp = npv_inf_NEV_wqual_totp ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base_year prices
    % ----------------------------------
    benefit_wqual_totn_npv = npv_wqual_totn * MP.rpi_totn;
    benefit_wqual_totp_npv = npv_wqual_totp * MP.rpi_totp;

end