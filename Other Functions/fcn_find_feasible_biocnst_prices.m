% fcn_find_feasible_biocnst_prices
% ================================

% Purpose
% -------
%  Search price space to find a set of feasible prices that do not break
%  the constraints (budget & biodiverisity targets)

function [prices_feas, benefit_feas] = fcn_find_feasible_biocnst_prices(budget, c, q, elm_options, prices_uncnst, prices_lb, prices_ub, cnst_data, cnst_target)
        
    % Constants
    % ---------
    num_spgrp = length(cnst_target);
        
    % Check for constraint violation
    % ------------------------------
    uptake = myfun_uptake(prices_uncnst, q, c, elm_options);  
    spgrp_chg = zeros(num_spgrp,1);
    for k = 1:num_spgrp
        spgrp_chg(k) = sum(uptake.*squeeze(cnst_data(k,:,:))', 'all');        
    end
    % [spgrp_chg cnst_target (spgrp_chg-cnst_target)>0]    
    
    % Search for Feasible Prices
    % --------------------------
    if ~any((spgrp_chg-cnst_target) > 0) 
        prices_feas = prices_uncnst;
    else        
        % Scale so prices same order of magnitude for maximisation
        % --------------------------------------------------------
        prices_uncnst(prices_uncnst==0) = 1;
        ord_mag = 10.^floor(log(abs(prices_uncnst))./log(10));
        ord_mag(ord_mag==0) = 1;
        prices_uncnst = prices_uncnst./ord_mag;

        q_uncnst = q.*ord_mag;
        prices_uncnst_min = prices_lb ./ ord_mag';
        prices_uncnst_min(isnan(prices_uncnst_min)) = 0;
        prices_uncnst_max = prices_ub ./ ord_mag'; 

        % GA search for biodiversity & budget constraint feasible prices
        % --------------------------------------------------------------
        benefitfunc    = @(p) myfun_Biod(p, q_uncnst, c, elm_options, cnst_data, cnst_target);
        constraintfunc = @(p) mycon_budget(p, q_uncnst, c, budget, elm_options);        
        tic
        options = optimoptions('ga', ...
                               'Display', 'iter');
        [prices_feas, benefit_feas] = ga(benefitfunc, length(prices_uncnst),[],[],[],[],prices_uncnst_min,prices_uncnst_max,constraintfunc,options);
        toc  
        
        if benefit_feas > 0
            warning('Unable to find prices that can deliver biodiversity constraint in budget');
        else
            prices_feas = prices_feas.*ord_mag;
        end
    end
    
 end