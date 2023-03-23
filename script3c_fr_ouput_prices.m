% script3_opt_output_prices.m
% ===============================
%  Search for optimum flat rate prices for different payment mechanisms  
%  budgets and constraints.
% 

% 1. Initialise
% -------------
clear
rng(23112010)

% Model
% -----
payment_mechanism = 'fr_es';
unscaled_budget   = 1e9;
urban_pct_limit   = 0.5;
bio_constraint    = 0.15;  % 0 if no biodiversity constraint
bio_as_prices     = false;  % only set to true if have a biodiversity const
byparcel          = true;
sample_size       = 5000;
do_search_sample  = true;
carbon_price_string = 'non_trade_central';
drop_vars   = {'habitat_non_use', 'biodiversity'};
budget_str  = [num2str(round(unscaled_budget/1e9)) 'bill' ];
biocnst_str = [num2str(round(bio_constraint*100)) 'pct'];
if sample_size > 1000            
	sample_str = [num2str(round(sample_size/1000)) 'k_sample'];
else
    sample_str = [num2str(round(sample_size)) '_sample'];
end


% Markup
% ------
markup = 1.15;

% Paths to Data & Cplex Working Dir
% ---------------------------------
cplex_folder = 'D:\myGitHub\defra-elms\Cplex\';
data_folder  = 'D:\myGitHub\defra-elms\Data\';
data_path = [data_folder, 'elm_data_', carbon_price_string, '.mat'];


% 2. Feasible Prices: Biodiveristy Constrained Problem
% ----------------------------------------------------
%   Begin with solution to budget constrained problem and check if this is
%   violating the biodiversity contstraints. If not, can set those prices 
%   as best prices for full optimsation. If so then use ga algorithm to
%   search for prices that 

if bio_constraint > 0 
    
    if ~bio_as_prices
    
        % Load data
        % ---------
        data_year = 1;    
        sample_size = 'no';  % all data
        [b, c, q, hectares, budget, lu_data, cnst_data, cnst_target, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, bio_constraint, bio_as_prices, byparcel, data_year);
        num_prices  = length(price_vars);
        num_options = size(b,2);
        num_farmers = size(b,1);

        % Solution prices from unconstrained model
        % ----------------------------------------
        load([data_folder 'solution_' payment_mechanism '_' budget_str '.mat'], 'solution');        
        prices_uncnst = solution.prices;

        % Check for constraint violation
        % ------------------------------
        uptake = myfun_uptake(prices_uncnst, q, c, elm_options);
        num_spgrp = length(cnst_target);
        spgrp_chg = zeros(num_spgrp,1);
        for k = 1:num_spgrp
            spgrp_chg(k) = sum(uptake.*squeeze(cnst_data(k,:,:))', 'all');        
        end

        if any((spgrp_chg-cnst_target) < 0) 

            % Unconstrained Solution fails Biodiversity Constrained Problem
            % -------------------------------------------------------------
            prices_max = fcn_find_max_prices(q, c, budget, lu_data, elm_options);
            prices_min = zeros(size(prices_max)); 

            % 2.5 Reduce to relevant cells
            % ----------------------------
            %  Remove cells where no possible price would enduce participation
            excluded_cells = fcn_find_unusable_cells(q, c, budget, elm_options, prices_max);
            b(excluded_cells, :)          = [];
            c(excluded_cells, :)          = [];
            q(excluded_cells, :, :)       = [];
            lu_data(excluded_cells, :)    = []; 
            cnst_data(:,:,excluded_cells) = [];        

            % Search for Feasible Prices
            [prices_feas, biodconst_score] = fcn_find_feasible_biocnst_prices(budget, c, q, elm_options, prices_uncnst, prices_min, prices_max, cnst_data, cnst_target);
            if biodconst_score > 0
                error('No feasible prices to deliver biodiversity constraint in budget');
            end
        else
            % Unconstrained Solution solves Biodiversity Constrained Problem
            % --------------------------------------------------------------     
            save(['solution_' payment_mechanism '_' budget_str '_' biocnst_str '.mat'], 'solution');                    
            copyfile([data_folder  'prices_' payment_mechanism '_' budget_str '_0pct_' sample_str '.mat'], ...
                     [data_folder  'prices_' payment_mechanism '_' budget_str '_' biocnst_str '_' sample_str '.mat']);   
            
            return
        end
    
    else
        
        % Check if have Biodiversity Constrained prices
        % ---------------------------------------------
        %  Only will not exist if biodiversity contraints cannot be
        %  achieved with outcome prices alone.
        
        % Optimal prices file
        % -------------------
        price_file = ['solution_' payment_mechanism '_' budget_str '_' biocnst_str '.mat'];
        price_file = [data_folder price_file];
               
%         % Sample prices file
%         % ------------------
%         price_sample_file = ['prices_' payment_mechanism '_' budget_str '_' biocnst_str '_' sample_str '.mat'];
%         price_sample_file = [data_folder price_sample_file];
              
        if isfile(price_file) && isfile(price_sample_file)
            
            % Load prices files
            % -----------------
            load(price_file, 'solution');
%             load(price_sample_file);
            
% ***************************************************************         

    % 3.1 Load data
    % -------------
    sample_size = 'no';  % all data
    data_year = 1;    
    [b, c, q, hectares, budget, lu_data, cnst_data, cnst_target, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, bio_constraint, bio_as_prices, byparcel, data_year);
    num_farmers = size(q, 1);
    num_prices  = size(q, 2);
    num_options = size(q, 3);        

    num_bio_vars = length(cnst_target);
    prices = [solution.prices, zeros(1,num_bio_vars)];

    uptake = myfun_uptake(prices, q, c, elm_options);
    num_spgrp = length(cnst_target);
    spgrp_chg = zeros(num_spgrp,1);
    for k = 1:num_spgrp
        spgrp_chg(k) = sum(uptake.*squeeze(cnst_data(k,:,:))', 'all');        
    end

    (spgrp_chg-cnst_target) < 0;

    % 2.3 Maximum possible prices
    % ---------------------------
    prices_max = fcn_find_max_prices(q, c, budget, lu_data, elm_options);
    prices_min = zeros(size(prices_max));   

    % 2.4 Scale quantities
    % --------------------
    % Scale so prices same order of magnitude for maximisation
    ord_mag = 10.^floor(log(abs(prices_max'))./log(10));
    q_scl = zeros(size(q));
    for i = 1:length(elm_options)
        q_scl(:, :, i) = q(:, :, i) .* ord_mag;
    end
    prices_min = prices_min ./ ord_mag';
    prices_max = prices_max ./ ord_mag'; 
    prices     = prices     ./ ord_mag; 

    % 2.5 Reduce to relevant cells
    % ----------------------------
    %  Remove cells where no possible price would enduce participation
    excluded_cells = fcn_find_unusable_cells(q_scl, c, budget, elm_options, prices_max);
    b(excluded_cells, :)          = [];
    c(excluded_cells, :)          = [];
    q_scl(excluded_cells, :, :)   = [];
    lu_data(excluded_cells, :)    = []; 
    cnst_data(:,:,excluded_cells) = [];        

    tic
    benefitfunc    = @(p) myfun_ES(p, q_scl, c, b, elm_options);
    if ~bio_as_prices
        constraintfunc = @(p) mycon_budget(p, q_scl, c, budget, elm_options);
    else
        constraintfunc = @(p) mycon_budget_bio(p, q_scl, c, budget, elm_options,cnst_data, cnst_target);
    end
    options = optimoptions('patternsearch', ...
                           'Display', 'iter');
    [prices_ps, benefit_ps] = patternsearch(benefitfunc, prices,[],[],[],[],prices_min,prices_max,constraintfunc,options);
    toc
    uptake_ps = myfun_uptake(prices_ps, q_scl, c, elm_options)';
    uptake_ps = uptake_ps(:)';
        
      
    % 3.6 Solution: MIP
    % -----------------
    cplex_options.time = 8000;
    cplex_options.logs = cplex_folder;    
    [prices, uptake_sml, fval, exitflag, exitmsg] = MIP_fr_out(b, c, q_scl, budget, lu_data, prices_ps, uptake_ps, prices_min, prices_max, cnst_data, cnst_target, byparcel, cplex_options);
     
    
% ***************************************************************    
        
            
            
            load(data_path, 'biodiversity_constraints');
            num_bio_vars = length(biodiversity_constraints.names_grp);
            clear biodiversity_constraints
            
            prices = [solution.prices; prices];
            prices = [prices, inf(size(prices,1), num_bio_vars)];            
            
            matfile_name = ['prices_' payment_mechanism '_' budget_str '_' biocnst_str '_pbio_' sample_str '.mat'];
            matfile_name = [data_folder matfile_name];
        
            save(matfile_name, 'prices');
            
            do_search_sample = false;
            
        end
        
    end
        
end 



% 2. Feasible Prices: Unconstrained Problem
% -----------------------------------------
%   The full optimisation problem is too large to be solved directly as a
%   MIP. We employ a number of strategies to identify a feasible price
%   vector to act as a warm start for the MIP and to find upper and lower
%   bounds for prices to limit search.

if do_search_sample

    % 2.1 Search Sample
    % -----------------
    % On disk mat file to which to write price search results
    if ~bio_as_prices
        matfile_name = ['prices_' payment_mechanism '_' budget_str '_' biocnst_str '_' sample_str '.mat'];
    else
        matfile_name = ['prices_' payment_mechanism '_' budget_str '_' biocnst_str '_pbio_' sample_str '.mat'];
    end   
    matfile_name = [data_folder matfile_name];
    mfile = matfile(matfile_name, 'Writable', true);
    if ~isfile(matfile_name)
        mfile.prices_good   = [];
        mfile.benefits_good = [];
        mfile.prices        = [];
        mfile.benefits      = [];
    end

    % Iterate through data samples to identify price ranges
    % -----------------------------------------------------
    Niter = 10;

    for iter = 1:Niter

        fprintf('Iteration: %d of %d\n', iter, Niter);
        fprintf('------------------\n');

        % 2.2 Load new sample of data
        % ---------------------------
        data_year = 1;    % year in which scheme run 
        [b, c, q, hectares, budget, lu_data, cnst_data, cnst_target, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, bio_constraint, bio_as_prices, byparcel, data_year);
        num_farmers = size(q, 1);
        num_prices  = size(q, 2);
        num_options = size(q, 3);

        % 2.3 Maximum possible prices
        % ---------------------------
        prices_max = fcn_find_max_prices(q, c, budget, lu_data, elm_options);
        prices_min = zeros(size(prices_max));   

        % 2.4 Scale quantities
        % --------------------
        % Scale so prices same order of magnitude for maximisation
        ord_mag = 10.^floor(log(abs(prices_max'))./log(10));
        q_scl = zeros(size(q));
        for i = 1:length(elm_options)
            q_scl(:, :, i) = q(:, :, i) .* ord_mag;
        end
        prices_min = prices_min ./ ord_mag';
        prices_max = prices_max ./ ord_mag'; 

        % 2.5 Reduce to relevant cells
        % ----------------------------
        %  Remove cells where no possible price would enduce participation
        excluded_cells = fcn_find_unusable_cells(q_scl, c, budget, elm_options, prices_max);
        b(excluded_cells, :)          = [];
        c(excluded_cells, :)          = [];
        q_scl(excluded_cells, :, :)   = [];
        lu_data(excluded_cells, :)    = []; 
        cnst_data(:,:,excluded_cells) = [];

        % 2.6 Solution: ga algorithm
        % --------------------------
        tic
        benefitfunc    = @(p) myfun_ES(p, q_scl, c, b, elm_options);
        if ~bio_as_prices
            constraintfunc = @(p) mycon_budget(p, q_scl, c, budget, elm_options);
        else
            constraintfunc = @(p) mycon_budget_bio(p, q_scl, c, budget, elm_options,cnst_data, cnst_target);
        end
        options = optimoptions('ga', ...
                               'Display', 'iter');
        [prices_feas, benefit_feas] = ga(benefitfunc, num_prices,[],[],[],[],prices_min,prices_max,constraintfunc,options);
        toc
        uptake_ga = myfun_uptake(prices_feas, q_scl, c, elm_options)';
        uptake_ga = uptake_ga(:)';

        % 2.7 Solution: MIP
        % -----------------
        cplex_options.time = 800;
        cplex_options.logs = cplex_folder;    
        [prices, uptake_sml, fval, exitflag, exitmsg] = MIP_fr_out(b, c, q_scl, budget, lu_data, prices_feas, uptake_ga, prices_min, prices_max, cnst_data, cnst_target, byparcel, cplex_options);

        mfile.prices(iter, 1:num_prices) = prices .* ord_mag;
        mfile.benefits(iter,1)           = fval;

    end   

end


% 3. Solve Full Problem
% ---------------------

% 3.1 Load data
% -------------
sample_size = 'no';  % all data
data_year = 1;    
[b, c, q, hectares, budget, lu_data, cnst_data, cnst_target, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, bio_constraint, bio_as_prices, byparcel, data_year);
num_farmers = size(q, 1);
num_prices  = size(q, 2);
num_options = size(q, 3);
    
% 3.2 Price bounds from sample searches
% -------------------------------------
load(matfile_name, 'prices');
prices_lb = min(prices)';
prices_ub = max(prices)';
prices_max = fcn_find_max_prices(q, c, budget, lu_data, elm_options);
    
% 3.3 Scale quantities
% --------------------
% Scale so prices same order of magnitude for maximisation
ord_mag = 10.^floor(log(abs(prices_max'))./log(10));
ord_mag(ord_mag==0) = 1;
q_scl = zeros(size(q));
for i = 1:length(elm_options)
    q_scl(:, :, i) = q(:, :, i).*ord_mag;
end
prices_lb  = prices_lb  ./ ord_mag';
prices_ub  = prices_ub  ./ ord_mag'; 
prices_max = prices_max ./ ord_mag'; 

if ~do_search_sample
    prices_lb(isinf(prices_lb)) = 0;
end   
   
% 3.4 Reduce to relevant cells
% ----------------------------
%  Remove cells where no possible price would enduce participation
excluded_cells = fcn_find_unusable_cells(q_scl, c, budget, elm_options, prices_max, prices_ub);
b(excluded_cells, :)          = [];
c(excluded_cells, :)          = [];
q_scl(excluded_cells, :, :)   = [];
lu_data(excluded_cells, :)    = []; 
cnst_data(:,:,excluded_cells) = [];
    
% 3.5 Solution: ga algorithm
% --------------------------
benefitfunc    = @(p) myfun_ES(p, q_scl, c, b, elm_options);
if ~bio_as_prices
    constraintfunc = @(p) mycon_budget(p, q_scl, c, budget, elm_options);
else
    constraintfunc = @(p) mycon_budget_bio(p, q_scl, c, budget, elm_options,cnst_data, cnst_target);
end
options = optimoptions('ga', ...
                       'Display', 'iter');
[prices_ga, benefit_ga] = ga(benefitfunc, num_prices,[],[],[],[],prices_lb*0.5,prices_ub*1.5,constraintfunc,options);

uptake_ga = myfun_uptake(prices_ga, q_scl, c, elm_options)';
uptake_ga = uptake_ga(:)';

% 3.6 Solution: MIP
% -----------------
cplex_options.time = 15000;
cplex_options.logs = cplex_folder;    
[prices, uptake_sml, fval, exitflag, exitmsg] = MIP_fr_out(b, c, q_scl, budget, lu_data, prices_ga, uptake_ga, prices_lb*0.5, prices_ub*1.5, cnst_data, cnst_target, byparcel, cplex_options);

% 3.7 Process result
% ------------------
uptake_ind_sml    = (sum(uptake_sml,2) > 0);
option_nums       = (1:8)';
option_choice_sml = (uptake_sml * option_nums);
benefits_sml      = sum(b.*uptake_sml, 2);
costs_sml         = sum(c.*uptake_sml, 2);
payments          = zeros(size(uptake_sml));
for i = 1:num_options
    payments(:,i)  = prices * q_scl(:, :, i)';
end
farm_payment_sml = sum(payments.*uptake_sml, 2);

% 3.8 Re-expand to full cell list
% -------------------------------
uptake        = zeros(num_farmers, num_options);
uptake_ind    = zeros(num_farmers, 1);
option_choice = zeros(num_farmers, 1);
benefits      = zeros(num_farmers, 1);
costs         = zeros(num_farmers, 1);
farm_payment  = zeros(num_farmers, 1);

sample_idx                = find(1-excluded_cells);
uptake(sample_idx,:)      = uptake_sml;
uptake_ind(sample_idx)    = uptake_ind_sml;
uptake_ind                = logical(uptake_ind);
option_choice(sample_idx) = option_choice_sml;
benefits(sample_idx)      = benefits_sml;
costs(sample_idx)         = costs_sml;
farm_payment(sample_idx)  = farm_payment_sml;


% 4. Save Solution
% ----------------
solution.prices        = prices .* ord_mag;
solution.fval          = sum(benefits);
solution.spend         = sum(farm_payment);
solution.uptake        = uptake;
solution.uptake_ind    = uptake_ind;
solution.option_choice = option_choice;
solution.new2kid       = new2kid(uptake_ind);
solution.hectares      = hectares;
solution.farm_costs    = costs;
solution.farm_benefits = benefits;
solution.farm_payment  = farm_payment;

if bio_constraint > 0
    if ~bio_as_prices
        save(['solution_' payment_mechanism '_' budget_str '_' biocnst_str '.mat'], 'solution'); 
    else
        save(['solution_' payment_mechanism '_' budget_str '_' biocnst_str '_pbio.mat'], 'solution'); 
    end
else
    save(['solution_' payment_mechanism '_' budget_str '.mat'], 'solution');     
end







