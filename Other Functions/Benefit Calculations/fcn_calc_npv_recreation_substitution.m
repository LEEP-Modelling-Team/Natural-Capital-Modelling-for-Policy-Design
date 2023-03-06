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
        NEV_recval_option_wood = es_recreation_all.no_access.rec_val;
        NEV_recval_option_sng  = es_recreation_all.no_access.rec_val;        
        NEV_recviscar_option   = es_recreation_all.no_access.rec_viscar;
    else
        if contains(elm_option, 'arable')
            NEV_recval_option_wood    = es_recreation_all.arable_reversion_wood_access.rec_val;
            NEV_recval_option_sng     = es_recreation_all.arable_reversion_sng_access.rec_val;
            if contains(elm_option, 'wood')
                NEV_recviscar_option = es_recreation_all.arable_reversion_wood_access.rec_viscar;
            else
                NEV_recviscar_option  = es_recreation_all.arable_reversion_sng_access.rec_viscar;              
            end
        else
            NEV_recval_option_wood    = es_recreation_all.destocking_wood_access.rec_val;
            NEV_recval_option_sng     = es_recreation_all.destocking_sng_access.rec_val;
            if contains(elm_option, 'wood')
                NEV_recviscar_option = es_recreation_all.destocking_wood_access.rec_viscar;
            else
                NEV_recviscar_option  = es_recreation_all.destocking_sng_access.rec_viscar;              
            end             
        end
    end
   
    % Extend to 100 year time series
    NEV_recval_option_wood = repmat(NEV_recval_option_wood,1,yrs_tser);
    NEV_recval_option_sng  = repmat(NEV_recval_option_sng,1,yrs_tser);

    % Ensure no NaNs
    NEV_recval_option_wood(isnan(NEV_recval_option_wood))  = 0;       
    NEV_recval_option_sng(isnan(NEV_recval_option_sng))    = 0;   
    NEV_recviscar_option(isnan(NEV_recviscar_option)) = 0;  
     
        
    % npv of time series from each year to end of time series    
    % -------------------------------------------------------
    npv_NEV_recval = zeros(N, yrs_NEV);
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
        npv_NEV_recval(:,t) = sum((NEV_recval_option_sng(:,t:end).*growth_wgts + NEV_recval_option_wood(:,t:end).*(1 - growth_wgts))./ (1 + MP.discount_rate).^(1:yrs_tser-t+1), 2);
    end
           
    % annuity equivalent of that npv
    % ------------------------------
    ann_NEV_recval = zeros(N, yrs_NEV);
    for t =1:yrs_NEV
        ann_NEV_recval(:,t) = npv_NEV_recval(:,t) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^ -(yrs_tser-t+1));
    end    
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_recval = ann_NEV_recval/MP.discount_rate;
    
    % express as npv in base year
    % ---------------------------
    npv_rec = npv_inf_NEV_recval ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base_year prices
    % ----------------------------------
    benefit_rec_npv = npv_rec * MP.rpi_rec;

    
    % Cost of Recreation Provision
    % ----------------------------
    if contains(elm_option, 'noaccess') 
        site_type = "path_chg";
    else
        if contains(elm_option, 'wood')
            site_type =  MP.site_type_wood;
        else
            site_type =  MP.site_type_sng;      
        end
    end    
    
    if site_type == "path_chg"
        % Costs are zero under existing paths
        cost_rec_npv = zeros(N, 1);
    else
        % Costs assumed the same whether this is a park or a path type of
        % recreation
        if strcmp(MP.site_area2length, 'diameter')
            % Diameter: Path length in m as diameter of circle with this site area (maximum length 10km)
            pathlen  = min(2*sqrt(elm_option_ha*10000/pi), 10000);
        else
            % Perimeter: Path length in m as perimeter of circle with this site area (maximum length 10km)
            pathlen  = min(2*pi*sqrt(elm_option_ha*10000/pi), 10000);        
        end
        
        % Costs:
        % ------
        %   o Paths: 
        %     https://www.pathsforall.org.uk/resources/resource/estimating-price-guide-for-path-projects
        %     Accessed 15/01/2020
        %     Vegetation clearance £4.25/m
        %     Full tray geotextile path £20.00/m
        %   o Car Park:
        %     Assume need enough spaces for car visits of one hour duration
        %        carhours/day = carvis/365 * 1hr
        %     Assume open for 8 hours a day
        %        carsatonetime = carhours/day / 10hrs
        %     Space for one car is 2.4m * 4.8m plus 50% for manoeuvre room 
        %     Cost is £2,500 per 50m2 unit
        carpark_area = min(2, ceil((NEV_recviscar_option/365)/10)) * 2.4*2.8*1.5;
        carpark_cost = carpark_area/50 * 2500;        
        cost_rec_npv = ((4.25 + 20.00)*pathlen + carpark_cost) * MP.rpi_rec_cst;
        
    end    
    % since this is taken to be a one-off cost can treat as a npv
    cost_rec_npv = cost_rec_npv ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
   
end