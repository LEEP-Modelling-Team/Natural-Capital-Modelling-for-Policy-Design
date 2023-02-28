function [benefit_rec_npv, cost_rec_npv] = fcn_calc_npv_recreation_substitution(MP, elm_option, elm_option_ha, es_recreation_all)

    % ORval recreation value data
    % ---------------------------
    % es_recreation_all is a structure with a table for each "access" 
    % option. The table holds a 'rec_val' column which is the ORVal value
    % for the annual change in recreation value flows for each option in 
    % each cell. Value estimates use the 'simultaneous' option which  
    % institutes the same change in all cells at the same time ensuring 
    % lower bound value. 

    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = height(es_recreation_all.arable_reversion_sng_access);
    
    % NEV Recreation Values Time Series
    % ---------------------------------      
    if contains(elm_option, 'noaccess') 
        NEV_rec_option_wood = es_recreation_all.no_access.rec_val;
        NEV_rec_option_sng  = es_recreation_all.no_access.rec_val;        
    else
        if contains(elm_option, 'arable')
            NEV_rec_option_wood = es_recreation_all.arable_reversion_wood_access.rec_val;
            NEV_rec_option_sng  = es_recreation_all.arable_reversion_sng_access.rec_val;
        else
            NEV_rec_option_wood = es_recreation_all.destocking_wood_access.rec_val;
            NEV_rec_option_sng  = es_recreation_all.destocking_sng_access.rec_val;
        end
    end
   
    % Extend to 100 year time series
    NEV_rec_option_wood = repmat(NEV_rec_option_wood,1,yrs_tser);
    NEV_rec_option_sng  = repmat(NEV_rec_option_sng,1,yrs_tser);

    % Ensure no NaNs
    NEV_rec_option_wood(isnan(NEV_rec_option_wood)) = 0;       
    NEV_rec_option_sng(isnan(NEV_rec_option_sng))   = 0;           
        
    % npv of time series from each year to end of time series    
    % -------------------------------------------------------
    npv_NEV_rec = zeros(N, yrs_NEV);
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
        npv_NEV_rec(:,t) = sum((NEV_rec_option_sng(:,t:end).*growth_wgts + NEV_rec_option_wood(:,t:end).*(1 - growth_wgts))./ (1 + MP.discount_rate).^(1:yrs_tser-t+1), 2);
    end
           
    % annuity equivalent of that npv
    % ------------------------------
    ann_NEV_rec = zeros(N, yrs_NEV);
    for t =1:yrs_NEV
        ann_NEV_rec(:,t) = npv_NEV_rec(:,t) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^ -(yrs_tser-t+1));
    end    
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_rec = ann_NEV_rec/MP.discount_rate;
    
    % express as npv in base year
    % ---------------------------
    npv_rec = npv_inf_NEV_rec ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base_year prices
    % ----------------------------------
    benefit_rec_npv = npv_rec * MP.rpi_rec;

    
    % Cost of Recreation Provision
    % ----------------------------
    switch elm_option
        case {'arable_reversion_sng_noaccess', 'destocking_sng_noaccess', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'}
            site_type = "path_chg";
        case {'arable_reversion_sng_access', 'destocking_sng_access'}
            site_type = "path_new";
        case {'arable_reversion_wood_access', 'destocking_wood_access'}
            site_type = "park_new";
    end    
    
    if site_type == "path_chg"
        % Costs are zero under existing paths
        cost_rec_npv = zeros(N, 1);
    else
        % Calculate length of paths around perimeter of new area (taken from rec code)
        pathlen  = 2 * pi * sqrt(elm_option_ha * 10000 / pi);
        % values from: https://www.pathsforall.org.uk/resources/resource/estimating-price-guide-for-path-projects
        cost_rec_npv = ((4.23 + 16.95) * pathlen + 534.31) * MP.rpi_rec_cst;
    end    
    % since this is taken to be a one-off cost can treat as a npv
    cost_rec_npv = cost_rec_npv ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
   
end