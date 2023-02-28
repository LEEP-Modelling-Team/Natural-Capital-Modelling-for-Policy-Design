function benefit_nuhabitat_npv = fcn_calc_npv_non_use_habitat(MP, elm_option, es_non_use_habitat_all)

    % NEV non-use habitat value data
    % ------------------------------
    % es_non_use_habitat_all holds table with columns for annual changes in 
    % the non-use value of upland habitat for each cell. Each table has 3
    % columns one for value of change in sng, one for change in wood with
    % the final column giving the sum. 

    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = height(es_non_use_habitat_all.arable_reversion_wood_noaccess);
    
    % NEV non-use habitat values time series
    % --------------------------------------
    if contains(elm_option, 'arable')
        if contains(elm_option, 'noaccess')
            NEV_nuhabitat_option_wood = es_non_use_habitat_all.arable_reversion_wood_noaccess.nu_habitat_val_wood;            
            NEV_nuhabitat_option_sng  = es_non_use_habitat_all.arable_reversion_sng_noaccess.nu_habitat_val_sngrass;
        else
            NEV_nuhabitat_option_wood = es_non_use_habitat_all.arable_reversion_wood_access.nu_habitat_val_wood;            
            NEV_nuhabitat_option_sng  = es_non_use_habitat_all.arable_reversion_sng_access.nu_habitat_val_sngrass;
        end
    else
        if contains(elm_option, 'noaccess')            
            NEV_nuhabitat_option_wood = es_non_use_habitat_all.destocking_reversion_wood_noaccess.nu_habitat_val_wood;            
            NEV_nuhabitat_option_sng  = es_non_use_habitat_all.destocking_reversion_sng_noaccess.nu_habitat_val_sngrass;
        else
            NEV_nuhabitat_option_wood = es_non_use_habitat_all.destocking_reversion_wood_access.nu_habitat_val_wood;
            NEV_nuhabitat_option_sng  = es_non_use_habitat_all.destocking_reversion_sng_access.nu_habitat_val_sngrass;
        end
    end
   
    % Extend to 100 year time series
    NEV_nuhabitat_option_wood = repmat(NEV_nuhabitat_option_wood,1,yrs_tser);
    NEV_nuhabitat_option_sng  = repmat(NEV_nuhabitat_option_sng,1,yrs_tser);
    
    % Ensure no NaNs
    NEV_nuhabitat_option_wood(isnan(NEV_nuhabitat_option_wood)) = 0;       
    NEV_nuhabitat_option_sng(isnan(NEV_nuhabitat_option_sng))   = 0;      
        
    
    % npv of time series from each year to end of time series    
    % -------------------------------------------------------
    npv_NEV_nuhabitat = zeros(N, yrs_NEV);
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
        npv_NEV_nuhabitat(:,t) = sum((NEV_nuhabitat_option_sng(:,t:end).*growth_wgts + NEV_nuhabitat_option_wood(:,t:end).*(1 - growth_wgts))./ (1 + MP.discount_rate).^(1:yrs_tser-t+1), 2);
    end
           
    % annuity equivalent of that npv
    % ------------------------------
    ann_NEV_nuhabitat = zeros(N, yrs_NEV);
    for t =1:yrs_NEV
        ann_NEV_nuhabitat(:,t) = npv_NEV_nuhabitat(:,t) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^ -(yrs_tser-t+1));
    end    
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_nuhabitat = ann_NEV_nuhabitat/MP.discount_rate;
    
    % express as npv in base year
    % ---------------------------
    npv_nuhabitat = npv_inf_NEV_nuhabitat ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base_year prices
    % ----------------------------------
    benefit_nuhabitat_npv = npv_nuhabitat * MP.rpi_nuhab;

end