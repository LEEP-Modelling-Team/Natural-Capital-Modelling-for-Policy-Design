function [benefit_forestry_npv, cost_forestry_npv] = fcn_calc_npv_forestry(baseline, es_forestry, MP)

    % Data
    % ----
    %  NEV outputs provide the annuity equivalent of timber benefits from
    %  one rotation. The annuity is calcluated from the npv of those 
    %  benefits in the planting year over that rotation period

    yrs_NEV = MP.num_years;
    
    % Benefits
    % --------
    % Benefits are an annuity from timber revenues over a single rotation.
    % On the assumption that those revenues are simply repeated in future
    % rotations, that annuity also represents the permanent land use change
    % annuity.    
    
    % change in NEV annuity
    % ---------------------   
    benefit_forestry_ann = es_forestry.Timber.BenefitAnn.Mix6040 - baseline.es_forestry.Timber.BenefitAnn.Mix6040;
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    npv_inf_NEV_timber = benefit_forestry_ann/MP.discount_rate;
    
    % extend to data set for planting in each of 40 years
    % ---------------------------------------------------
    npv_inf_NEV_timber = repmat(npv_inf_NEV_timber, 1,MP.num_years);    
    
    % express as npv in base year
    % ---------------------------
    npv_timber = npv_inf_NEV_timber ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base_year prices
    % ----------------------------------
    benefit_forestry_npv = npv_timber * MP.rpi_forest;
   

    % Costs
    % -----
    % Costs are an annuity of the fixed from timber revenues over a single rotation.
    % On the assumption that those revenues are simply repeated in future
    % rotations, that annuity also represents the permanent land use change
    % annuity.     
    
    % change in NEV annuity
    % ---------------------   
    cost_forestry_ann = es_forestry.Timber.CostAnn.Mix6040 - baseline.es_forestry.Timber.CostAnn.Mix6040;
    
    % npv over infinite time horizon (permanent land use change)
    % ----------------------------------------------------------
    % Variable planting & management costs
    npv_inf_NEV_forest_varcost = cost_forestry_ann/MP.discount_rate;
    
    % Fixed planting costs
    % Form annuity from npv from one rotation
    ann_NEV_forest_fixcost = ...
         0.6 * (es_forestry.Timber.FixedCost.PedunculateOak - baseline.es_forestry.Timber.FixedCost.PedunculateOak) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^-es_forestry.RotPeriod_cell.PedunculateOak) + ...
         0.4 * (es_forestry.Timber.FixedCost.SitkaSpruce    - baseline.es_forestry.Timber.FixedCost.SitkaSpruce) .* MP.discount_rate ./ (1 - (1 + MP.discount_rate).^-es_forestry.RotPeriod_cell.SitkaSpruce);
    npv_inf_NEV_forest_fixcost = ann_NEV_forest_fixcost/MP.discount_rate;
       
    % extend to data set for planting over 40 years
    % ---------------------------------------------
    npv_inf_NEV_forest_cost = repmat(npv_inf_NEV_forest_fixcost + npv_inf_NEV_forest_varcost,1, MP.num_years);    
    
    % express as npv in base year
    % ---------------------------
    npv_forest_cost = npv_inf_NEV_forest_cost ./ (1 + MP.discount_rate).^((MP.base_year:1:(MP.base_year+yrs_NEV-1)) - MP.start_year);
    
    % express as npv in base prices
    % -----------------------------
    cost_forestry_npv = npv_forest_cost * MP.rpi_forest;    
    
end