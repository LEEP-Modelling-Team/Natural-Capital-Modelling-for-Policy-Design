function [benefit_forestry_ann, cost_forestry_ann] = fcn_calc_benefit_forestry(baseline, es_forestry)

    % Benefit is simply difference between timber value annuity (over full
    % rotation period) in scenario and baseline
    % Assume 60:40% broadleaf:coniferous mix here
    
    % Timber benefits with initial fixed cost
%     benefit_forestry_ann = es_forestry.Timber.ValAnn.Mix6040 - baseline.timber_mixed_ann;

    % Timber benefits without any cost
    benefit_forestry_ann = es_forestry.Timber.BenefitAnn.Mix6040 - baseline.timber_mixed_benefit_ann;
    
    % Timber costs
    cost_forestry_ann = es_forestry.Timber.CostAnn.Mix6040 - baseline.timber_mixed_cost_ann;
    % note fixed costs are added outside this function when converting to
    % NPV!

end