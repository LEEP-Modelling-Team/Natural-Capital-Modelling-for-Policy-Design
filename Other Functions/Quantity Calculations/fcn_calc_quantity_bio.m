function quantity_bio = fcn_calc_quantity_bio(MP, elm_option, baseline, es_biodiversity_ucl_all)

    % NEV pollinator quantity data
    % ----------------------------
    % es_biodiversity_ucl_all holds table for each option recording annual value 
    % changes in horticultural yield from pollinator changes under option
    % for each cell for each decade 2020, 2030, 2040 & 2050. 
    
    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = size(baseline.pollinator_sr_20,1);

    % Baseline Pollinator SR 
    % ----------------------
    bio_baseline = [repmat(baseline.pollinator_sr_20 + baseline.priority_sr_20, 1, 10) ...
                    repmat(baseline.pollinator_sr_30 + baseline.priority_sr_30, 1, 10) ...
                    repmat(baseline.pollinator_sr_40 + baseline.priority_sr_40, 1, 10) ...
                    repmat(baseline.pollinator_sr_50 + baseline.priority_sr_50, 1, 10)];

    % Option Pollinator SR 
    % --------------------
    % Note: Access & No Access make no difference to pollinator SR, so 
    %       just use access results in both cases.
    if contains(elm_option, 'arable')
        NEV_bio_option_wood = [repmat(es_biodiversity_ucl_all.arable_reversion_wood_access.pollinator_sr_20 + es_biodiversity_ucl_all.arable_reversion_wood_access.priority_sr_20, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.arable_reversion_wood_access.pollinator_sr_30 + es_biodiversity_ucl_all.arable_reversion_wood_access.priority_sr_30, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.arable_reversion_wood_access.pollinator_sr_40 + es_biodiversity_ucl_all.arable_reversion_wood_access.priority_sr_40, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.arable_reversion_wood_access.pollinator_sr_50 + es_biodiversity_ucl_all.arable_reversion_wood_access.priority_sr_50, 1, 10)];        
        NEV_bio_option_sng  = [repmat(es_biodiversity_ucl_all.arable_reversion_sng_access.pollinator_sr_20 + es_biodiversity_ucl_all.arable_reversion_sng_access.priority_sr_20 , 1, 10) ...
                               repmat(es_biodiversity_ucl_all.arable_reversion_sng_access.pollinator_sr_30 + es_biodiversity_ucl_all.arable_reversion_sng_access.priority_sr_30, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.arable_reversion_sng_access.pollinator_sr_40 + es_biodiversity_ucl_all.arable_reversion_sng_access.priority_sr_40, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.arable_reversion_sng_access.pollinator_sr_50 + es_biodiversity_ucl_all.arable_reversion_sng_access.priority_sr_50, 1, 10)];   
    else

        NEV_bio_option_wood = [repmat(es_biodiversity_ucl_all.destocking_wood_access.pollinator_sr_20 + es_biodiversity_ucl_all.destocking_wood_access.priority_sr_20, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.destocking_wood_access.pollinator_sr_30 + es_biodiversity_ucl_all.destocking_wood_access.priority_sr_30, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.destocking_wood_access.pollinator_sr_40 + es_biodiversity_ucl_all.destocking_wood_access.priority_sr_40, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.destocking_wood_access.pollinator_sr_50 + es_biodiversity_ucl_all.destocking_wood_access.priority_sr_50, 1, 10)];        
        NEV_bio_option_sng  = [repmat(es_biodiversity_ucl_all.destocking_sng_access.pollinator_sr_20 + es_biodiversity_ucl_all.destocking_sng_access.priority_sr_20, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.destocking_sng_access.pollinator_sr_30 + es_biodiversity_ucl_all.destocking_sng_access.priority_sr_30, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.destocking_sng_access.pollinator_sr_40 + es_biodiversity_ucl_all.destocking_sng_access.priority_sr_40, 1, 10) ...
                               repmat(es_biodiversity_ucl_all.destocking_sng_access.pollinator_sr_50 + es_biodiversity_ucl_all.destocking_sng_access.priority_sr_50, 1, 10)];   
    end
    
    % Extend to 100 year time series
    bio_baseline        = [bio_baseline repmat(bio_baseline(:,end),1,yrs_tser-yrs_NEV)];
    NEV_bio_option_wood = [NEV_bio_option_wood repmat(NEV_bio_option_wood(:,end),1,yrs_tser-yrs_NEV)];
    NEV_bio_option_sng  = [NEV_bio_option_sng  repmat(NEV_bio_option_sng(:,end),1,yrs_tser-yrs_NEV)];
    
    % Ensure no NaNs
    bio_baseline(isnan(bio_baseline))               = 0;       
    NEV_bio_option_wood(isnan(NEV_bio_option_wood)) = 0;       
    NEV_bio_option_sng(isnan(NEV_bio_option_sng))   = 0;     
    
    % difference in pollinator sr from baseline under option    
    % ------------------------------------------------------
    bio_chg_wood = NEV_bio_option_wood - bio_baseline;
    bio_chg_sng  = NEV_bio_option_sng  - bio_baseline;
        
    % mean of pollinator change time series from each year to end of time series    
    % --------------------------------------------------------------------------
    quantity_bio = zeros(N, yrs_NEV);
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
        quantity_bio(:,t) = mean((bio_chg_sng(:,t:end).*growth_wgts + bio_chg_wood(:,t:end).*(1 - growth_wgts))./ (1 + MP.discount_rate).^(1:yrs_tser-t+1), 2);
    end    
    
end