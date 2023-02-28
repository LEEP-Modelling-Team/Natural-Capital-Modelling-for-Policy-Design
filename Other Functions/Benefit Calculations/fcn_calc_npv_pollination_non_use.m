function benefit_poll_nonuse_npv = fcn_calc_npv_pollination_non_use(MP, elm_option, es_non_use_pollination_all)
    
    % NEV water quality non-use value data
    % ------------------------------------
    % es_poll_nonuse_all holds table for each option recording annual value 
    % changes in water non-use for nutrient changes for each cell for each 
    % decade 2020, 2030, 2040 & 2050. 
    
    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = height(es_non_use_pollination_all.arable_reversion_sng_access);
    
    % NEV water non-use values
    % ------------------------
    % Note: Access & No Access make no difference to water quality 
    %       benefits, so just use access results in both cases.
    if contains(elm_option, 'arable')
        NEV_poll_nonuse_option_wood = [repmat(es_non_use_pollination_all.arable_reversion_wood_access.wtp_change_20, 1, 10) ...
                                       repmat(es_non_use_pollination_all.arable_reversion_wood_access.wtp_change_30, 1, 10) ...
                                       repmat(es_non_use_pollination_all.arable_reversion_wood_access.wtp_change_40, 1, 10) ...
                                       repmat(es_non_use_pollination_all.arable_reversion_wood_access.wtp_change_50, 1, 10)];        
        NEV_poll_nonuse_option_sng  = [repmat(es_non_use_pollination_all.arable_reversion_sng_access.wtp_change_20, 1, 10) ...
                                       repmat(es_non_use_pollination_all.arable_reversion_sng_access.wtp_change_30, 1, 10) ...
                                       repmat(es_non_use_pollination_all.arable_reversion_sng_access.wtp_change_40, 1, 10) ...
                                       repmat(es_non_use_pollination_all.arable_reversion_sng_access.wtp_change_50, 1, 10)];   
    else

        NEV_poll_nonuse_option_wood = [repmat(es_non_use_pollination_all.destocking_wood_access.wtp_change_20, 1, 10) ...
                                       repmat(es_non_use_pollination_all.destocking_wood_access.wtp_change_30, 1, 10) ...
                                       repmat(es_non_use_pollination_all.destocking_wood_access.wtp_change_40, 1, 10) ...
                                       repmat(es_non_use_pollination_all.destocking_wood_access.wtp_change_50, 1, 10)];        
        NEV_poll_nonuse_option_sng  = [repmat(es_non_use_pollination_all.destocking_sng_access.wtp_change_20, 1, 10) ...
                                       repmat(es_non_use_pollination_all.destocking_sng_access.wtp_change_30, 1, 10) ...
                                       repmat(es_non_use_pollination_all.destocking_sng_access.wtp_change_40, 1, 10) ...
                                       repmat(es_non_use_pollination_all.destocking_sng_access.wtp_change_50, 1, 10)];   
    end
    
    % Extend to 100 year time series
    NEV_poll_nonuse_option_wood = [NEV_poll_nonuse_option_wood repmat(NEV_poll_nonuse_option_wood(:,end),1,yrs_tser-yrs_NEV)];
    NEV_poll_nonuse_option_sng  = [NEV_poll_nonuse_option_sng  repmat(NEV_poll_nonuse_option_sng(:,end),1,yrs_tser-yrs_NEV)];
    
    % Ensure no NaNs
    NEV_poll_nonuse_option_wood(isnan(NEV_poll_nonuse_option_wood)) = 0;       
    NEV_poll_nonuse_option_sng(isnan(NEV_poll_nonuse_option_sng))   = 0;      
        
    % npv of time series from each year to end of time series    
    % -------------------------------------------------------
    npv_NEV_poll_nonuse = zeros(N, yrs_NEV);
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
        npv_NEV_poll_nonuse(:,t) = sum((NEV_poll_nonuse_option_sng(:,t:end).*growth_wgts + NEV_poll_nonuse_option_wood(:,t:end).*(1 - growth_wgts))./ (1 + MP.discount_rate).^(1:yrs_tser-t+1), 2);
    end
    
    % annuity equivalent of that npv
    % ------------------------------
    ann_NEV_poll_nonuse = zeros(N, yrs_NEV);
    for t =1:yrs_NEV
        ann_NEV_poll_nonuse(:,t) = npv_NEV_poll_nonuse(:,t) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^ -(yrs_tser-t+1));
    end
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_poll_nonuse = ann_NEV_poll_nonuse/MP.discount_rate;

    % express as npv in base year
    % ---------------------------
    npv_poll_nonuse = npv_inf_NEV_poll_nonuse ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base_year prices
    % ----------------------------------
    benefit_poll_nonuse_npv = npv_poll_nonuse * MP.rpi_nupoll;

end