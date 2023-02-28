function quantity_pollinators = fcn_calc_quantity_pollination(MP, elm_option, baseline, es_pollination_all)

    % NEV pollinator quantity data
    % ----------------------------
    % es_pollination_all holds table for each option recording annual value 
    % changes in horticultural yield from pollinator changes under option
    % for each cell for each decade 2020, 2030, 2040 & 2050. 
    
    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = height(es_pollination_all.arable_reversion_sng_access);

    % Baseline Pollinator SR 
    % ----------------------
    poll_baseline = [repmat(baseline.pollinator_sr_20, 1, 10) ...
                     repmat(baseline.pollinator_sr_30, 1, 10) ...
                     repmat(baseline.pollinator_sr_40, 1, 10) ...
                     repmat(baseline.pollinator_sr_50, 1, 10)];

    % Option Pollinator SR 
    % --------------------
    % Note: Access & No Access make no difference to pollinator SR, so 
    %       just use access results in both cases.
    if contains(elm_option, 'arable')
        NEV_poll_option_wood = [repmat(es_pollination_all.arable_reversion_wood_access.pollinator_sr_20, 1, 10) ...
                                repmat(es_pollination_all.arable_reversion_wood_access.pollinator_sr_30, 1, 10) ...
                                repmat(es_pollination_all.arable_reversion_wood_access.pollinator_sr_40, 1, 10) ...
                                repmat(es_pollination_all.arable_reversion_wood_access.pollinator_sr_50, 1, 10)];        
        NEV_poll_option_sng  = [repmat(es_pollination_all.arable_reversion_sng_access.pollinator_sr_20, 1, 10) ...
                                repmat(es_pollination_all.arable_reversion_sng_access.pollinator_sr_30, 1, 10) ...
                                repmat(es_pollination_all.arable_reversion_sng_access.pollinator_sr_40, 1, 10) ...
                                repmat(es_pollination_all.arable_reversion_sng_access.pollinator_sr_50, 1, 10)];   
    else

        NEV_poll_option_wood = [repmat(es_pollination_all.destocking_wood_access.pollinator_sr_20, 1, 10) ...
                                repmat(es_pollination_all.destocking_wood_access.pollinator_sr_30, 1, 10) ...
                                repmat(es_pollination_all.destocking_wood_access.pollinator_sr_40, 1, 10) ...
                                repmat(es_pollination_all.destocking_wood_access.pollinator_sr_50, 1, 10)];        
        NEV_poll_option_sng  = [repmat(es_pollination_all.destocking_sng_access.pollinator_sr_20, 1, 10) ...
                                repmat(es_pollination_all.destocking_sng_access.pollinator_sr_30, 1, 10) ...
                                repmat(es_pollination_all.destocking_sng_access.pollinator_sr_40, 1, 10) ...
                                repmat(es_pollination_all.destocking_sng_access.pollinator_sr_50, 1, 10)];   
    end
    
    % Extend to 100 year time series
    poll_baseline        = [poll_baseline repmat(poll_baseline(:,end),1,yrs_tser-yrs_NEV)];
    NEV_poll_option_wood = [NEV_poll_option_wood repmat(NEV_poll_option_wood(:,end),1,yrs_tser-yrs_NEV)];
    NEV_poll_option_sng  = [NEV_poll_option_sng  repmat(NEV_poll_option_sng(:,end),1,yrs_tser-yrs_NEV)];
    
    % Ensure no NaNs
    poll_baseline(isnan(poll_baseline))               = 0;       
    NEV_poll_option_wood(isnan(NEV_poll_option_wood)) = 0;       
    NEV_poll_option_sng(isnan(NEV_poll_option_sng))   = 0;     
    
    % difference in pollinator sr from baseline under option    
    % ------------------------------------------------------
    poll_chg_wood = NEV_poll_option_wood - poll_baseline;
    poll_chg_sng  = NEV_poll_option_sng  - poll_baseline;
        
    % mean of pollinator change time series from each year to end of time series    
    % --------------------------------------------------------------------------
    quantity_pollinators = zeros(N, yrs_NEV);
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
        quantity_pollinators(:,t) = mean((poll_chg_sng(:,t:end).*growth_wgts + poll_chg_wood(:,t:end).*(1 - growth_wgts))./ (1 + MP.discount_rate).^(1:yrs_tser-t+1), 2);
    end                          

end