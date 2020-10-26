function [opt_cells, option_choice, farm_payment] = fcn_payment_oc_mcknap(budget, margin, cell_ids, costs, benefits)
    
    %% (0) Set up
    %  ==========
    
    % (a) Adjust costs and benefit:cost ratio by margin
    % -------------------------------------------------
    costs = margin * costs;
    
    num_farms = length(cell_ids);
    num_options = size(costs, 2);
    benefits_transposed = benefits';
    costs_transposed = costs';
    
    result = sortrows(mex_minmcknap(int32(num_farms), int32(num_options), int64(budget), int32(benefits_transposed), int32(costs_transposed))', 1);
    
    no0_ind = result(:, 2) > 0;
    opt_cells = [cell_ids(no0_ind), ones(sum(no0_ind), 1)];
    option_choice = result(no0_ind, 2);
    farm_payment = result(no0_ind, 3);
    
end