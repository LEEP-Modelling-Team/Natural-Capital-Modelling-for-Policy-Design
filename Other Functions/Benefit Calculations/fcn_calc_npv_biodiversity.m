function benefit_biodiversity_npv = fcn_calc_npv_biodiversity(MP, elm_option, es_biodiversity_jncc_all, baseline, biodiversity_unit_value)
    
    % NEV JNCC species-richness data
    % ------------------------------
    % es_biodiversity_all holds table for each option recording annual value 
    % changes in water non-use for nutrient changes for each cell for each 
    % decade 2020, 2030, 2040 & 2050. 
    
    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = size(es_biodiversity_jncc_all.arable_reversion_sng_access.sr_100_20,1);
    
    % NEV water non-use values
    % ------------------------
    % Note: Access & No Access make no difference to water quality 
    %       benefits, so just use access results in both cases.
    if contains(elm_option, 'arable')
        NEV_biodiversity_option_wood = [repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.arable_reversion_wood_access.sr_100_20 - baseline.es_biodiversity_jncc.sr_100_20), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.arable_reversion_wood_access.sr_100_30 - baseline.es_biodiversity_jncc.sr_100_30), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.arable_reversion_wood_access.sr_100_40 - baseline.es_biodiversity_jncc.sr_100_40), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.arable_reversion_wood_access.sr_100_50 - baseline.es_biodiversity_jncc.sr_100_50), 1, 10)];        
        NEV_biodiversity_option_sng  = [repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.arable_reversion_sng_access.sr_100_20  - baseline.es_biodiversity_jncc.sr_100_20), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.arable_reversion_sng_access.sr_100_30  - baseline.es_biodiversity_jncc.sr_100_30), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.arable_reversion_sng_access.sr_100_40  - baseline.es_biodiversity_jncc.sr_100_40), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.arable_reversion_sng_access.sr_100_50  - baseline.es_biodiversity_jncc.sr_100_50), 1, 10)];   
    else

        NEV_biodiversity_option_wood = [repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.destocking_reversion_wood_access.sr_100_20 - baseline.es_biodiversity_jncc.sr_100_20), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.destocking_reversion_wood_access.sr_100_30 - baseline.es_biodiversity_jncc.sr_100_30), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.destocking_reversion_wood_access.sr_100_40 - baseline.es_biodiversity_jncc.sr_100_40), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.destocking_reversion_wood_access.sr_100_50 - baseline.es_biodiversity_jncc.sr_100_50), 1, 10)];        
        NEV_biodiversity_option_sng  = [repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.destocking_reversion_sng_access.sr_100_20  - baseline.es_biodiversity_jncc.sr_100_20), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.destocking_reversion_sng_access.sr_100_30  - baseline.es_biodiversity_jncc.sr_100_30), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.destocking_reversion_sng_access.sr_100_40  - baseline.es_biodiversity_jncc.sr_100_40), 1, 10) ...
                                        repmat(biodiversity_unit_value*(es_biodiversity_jncc_all.destocking_reversion_sng_access.sr_100_50  - baseline.es_biodiversity_jncc.sr_100_50), 1, 10)];   
    end
    
    % Extend to 100 year time series
    NEV_biodiversity_option_wood = [NEV_biodiversity_option_wood repmat(NEV_biodiversity_option_wood(:,end),1,yrs_tser-yrs_NEV)];
    NEV_biodiversity_option_sng  = [NEV_biodiversity_option_sng  repmat(NEV_biodiversity_option_sng(:,end),1,yrs_tser-yrs_NEV)];
    
    % Ensure no NaNs
    NEV_biodiversity_option_wood(isnan(NEV_biodiversity_option_wood)) = 0;       
    NEV_biodiversity_option_sng(isnan(NEV_biodiversity_option_sng))   = 0;      
        
    % npv of time series from each year to end of time series    
    % -------------------------------------------------------
    npv_NEV_biodiversity = zeros(N, yrs_NEV);
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
        npv_NEV_biodiversity(:,t) = sum((NEV_biodiversity_option_sng(:,t:end).*growth_wgts + NEV_biodiversity_option_wood(:,t:end).*(1 - growth_wgts))./ (1 + MP.discount_rate).^(1:yrs_tser-t+1), 2);
    end
    
    % annuity equivalent of that npv
    % ------------------------------
    ann_NEV_biodiversity = zeros(N, yrs_NEV);
    for t =1:yrs_NEV
        ann_NEV_biodiversity(:,t) = npv_NEV_biodiversity(:,t) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^ -(yrs_tser-t+1));
    end
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_biodiversity = ann_NEV_biodiversity/MP.discount_rate;

    % express as npv in base year
    % ---------------------------
    npv_biodiversity = npv_inf_NEV_biodiversity ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base_year prices
    % ----------------------------------
    benefit_biodiversity_npv = npv_biodiversity * MP.rpi_biod;

end