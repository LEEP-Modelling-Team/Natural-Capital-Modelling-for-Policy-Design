function [npv_farm] = fcn_calc_npv_agriculture(baseline, es_agriculture, MP)

    % NEV farm data
    % -------------
    % For land use change in each year of the 40 year NEV time series
    % calculate a npv of cost or benefit for a permanent land use change
    % expressed as a npv in MP.base_year and in a price base for 
    % MP.price_year
    
    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = size(es_agriculture.farm_profit,1);
        
    % farm profit change
    % ------------------
    % Farm profits are a 40 year time series of undiscounted returns to
    % agriculture on each cell
    farm_profit_chg = es_agriculture.farm_profit - baseline.farm_profit;

    
    % npv of time series from each year to end of time series    
    % -------------------------------------------------------
    npv_NEV_farm = zeros(N, yrs_NEV);
    for t =1:yrs_NEV
        npv_NEV_farm(:,t) = sum(farm_profit_chg(:,t:end) ./ (1 + MP.discount_rate).^(1:yrs_NEV-t+1), 2);
    end
        
    % annuity equivalent of that npv
    % ------------------------------
    ann_NEV_farm = zeros(size(farm_profit_chg));
    for t =1:yrs_NEV
        ann_NEV_farm(:,t) = npv_NEV_farm(:,t) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^ -(yrs_NEV-t+1));
    end
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_farm = ann_NEV_farm/MP.discount_rate;
        
    % express as npv in base year
    % ---------------------------
    npv_farm = npv_inf_NEV_farm ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base prices
    % -----------------------------
    npv_farm = npv_farm * MP.rpi_farm;
    
end