function [q_ghg_farm, q_ghg_dispfood, q_ghg_forest, q_ghg_forest_soil] = fcn_calc_quantity_ghg(MP, baseline, es_agriculture, es_forestry)

    % Constants
    % ---------
    yrs_NEV  = MP.num_years;
    yrs_tser = 100;
    N        = size(es_agriculture.ghg_farm,1);

    % ghg change time series
    % ----------------------
    % Farm ghg emissions are a 40 year time series for each cell
    farm_ghg_chg        = es_agriculture.ghg_farm - baseline.es_agriculture.ghg_farm;
    
    % change in farm outputs are converted into food quantities and then 
    % into the co2 of that food production displaced overseas given 
    % maintenance of current import mix.
    dispfood_ghg_chg = MP.food2co2_arable * MP.farm2food_arable * (es_agriculture.arable_food - baseline.es_agriculture.arable_food) + ...
                       MP.food2co2_dairy  * MP.farm2food_dairy  * (es_agriculture.dairy_food  - baseline.es_agriculture.dairy_food)  + ...
                       MP.food2co2_beef   * MP.farm2food_beef   * (es_agriculture.beef_food   - baseline.es_agriculture.beef_food)   + ...
                       MP.food2co2_sheep  * MP.farm2food_sheep  * (es_agriculture.sheep_food  - baseline.es_agriculture.sheep_food);
    
    % Forest & Forest Soil ghg are permanent Carbon equivalent from 
    % 2 x rotation for the carbon time series then averaged over ONE 
    % rotation period.
    %  NOTE: The assumption that soil carbon pattern repeats itself over
    %  successive rotations (as per timber carbon) is not a particularly 
    %  good one since this is emissions from one-off planting on non-wooded land)   
    forest_ghg_chg      = es_forestry.TimberC.QntYr.Mix6040 - baseline.es_forestry.TimberC.QntYr.Mix6040;
    forest_soil_ghg_chg = es_forestry.SoilC.QntYr.Mix6040   - baseline.es_forestry.SoilC.QntYr.Mix6040;
    
    % Extend to 100 year time series
    farm_ghg_chg         = [farm_ghg_chg        repmat(farm_ghg_chg(:,end),1,yrs_tser-yrs_NEV)];
    dispfood_ghg_chg     = [dispfood_ghg_chg    repmat(dispfood_ghg_chg(:,end),1,yrs_tser-yrs_NEV)];
    forest_ghg_chg       = [forest_ghg_chg      repmat(forest_ghg_chg(:,end),1,yrs_tser-yrs_NEV)];
    forest_soil_ghg_chg  = [forest_soil_ghg_chg repmat(forest_soil_ghg_chg(:,end),1,yrs_tser-yrs_NEV)];
    
    % average annual farm_ghg     
    % -----------------------
    q_ghg_farm        = zeros(N,yrs_NEV);
    q_ghg_dispfood    = zeros(N,yrs_NEV);
    q_ghg_forest      = zeros(N,yrs_NEV);
    q_ghg_forest_soil = zeros(N,yrs_NEV);
    for t =1:yrs_NEV
        q_ghg_farm(:,t)        = mean(farm_ghg_chg(:,t:end),2);
        q_ghg_dispfood(:,t)    = mean(dispfood_ghg_chg(:,t:end),2);
        q_ghg_forest(:,t)      = mean(forest_ghg_chg(:,t:end),2);
        q_ghg_forest_soil(:,t) = mean(forest_soil_ghg_chg(:,t:end),2);
    end
    
end