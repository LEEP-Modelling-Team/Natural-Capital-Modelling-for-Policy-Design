% script3_opt_output_prices.m
% ===============================
%  Search for optimum flat rateprices for different payment mechanisms and 
%  budgets

clear
rng(23112010)

% 1. Initialise
% -------------

% Model
% -----
payment_mechanism = 'fr_env';
unscaled_budget = 2e9;
urban_pct_limit = 0.5;
carbon_price_string = 'non_trade_central';
drop_vars = {'habitat_non_use', 'biodiversity'};
budget_str = [num2str(round(unscaled_budget/1e9)) 'bill'];

% Markup
% ------
markup = 1.15;

% Paths to Data & Cplex Working Dir
% ---------------------------------
% data_folder = 'D:\mydata\Research\Projects (Land Use)\Defra_ELMS\Data\';
% data_folder = 'D:\Documents\Data\Defra-ELMS\';
% data_path = [data_folder, 'Script 2 (ELM Option Runs)/elm_data_', carbon_price_string, '.mat'];
base_folder  = 'D:\myGitHub\defra-elms\';
cplex_folder = [base_folder 'Cplex\'];
data_folder  = [base_folder 'Data\'];

input_data_path = [data_folder, 'elm_data_', carbon_price_string, '.mat'];

% Search Sample
% -------------
sample_size = 5000; % either 'no' or a number representing the sample size
% On disk mat file to which to write price search results
if sample_size > 1000
    eval(['matfile_name = ''prices_' budget_str '_' payment_mechanism '_' num2str(round(sample_size/1000)) 'k_sample.mat'';']);
else
    eval(['matfile_name = ''prices_' budget_str '_' payment_mechanism '_' num2str(round(sample_size)) '_sample.mat'';']);
end
matfile_name = [base_folder matfile_name];
mfile = matfile(matfile_name, 'Writable', true);
if ~isfile(matfile_name)
    mfile.prices_good   = [];
    mfile.benefits_good = [];
    mfile.prices        = [];
    mfile.benefits      = [];
end


% 2. Iterate through data samples to identify price ranges
% --------------------------------------------------------
Niter = 10;

for iter = 1:Niter
    
    fprintf('Iteration: %d of %d\n', iter, Niter);
    fprintf('------------------\n');
    
    % (a) Load new sample of data
    % ---------------------------
    data_year = 1;    % year in which scheme run 
    [b, c, q, budget, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, input_data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, data_year);
    num_prices = length(price_vars);
    
    % (b) Scale quantities
    % --------------------
    prices_scale = reshape(permute(q, [1 3 2]),[], size(q,2));
    prices_scale(prices_scale==0) = NaN;
    prices_scale = nanstd(prices_scale);
    q = q ./ prices_scale;
           
    % (c) Linear search for maximum possible prices
    % ---------------------------------------------
    constraintfunc = @(p) mycon_ES(p, q, c, budget, elm_options);
    prices_max = zeros(1, num_prices);
    start_rate = 5;
    for i = 1:num_prices
        prices_max(i) = fcn_lin_search(num_prices,i,start_rate,0.01,constraintfunc,q,c,budget,elm_options);
    end
    prices_min = zeros(size(prices_max));
    
    % (d) Find feasible prices
    % ------------------------  
    Nfeas = 40;
    [prices_feasible, benefits_feasible] = fcn_find_feasible_prices(budget, b, c, q, elm_options, prices_min, prices_max, Nfeas);
    if ~isempty(mfile.prices) || ~isempty(mfile.prices_good)
        prices_good = [mfile.prices; mfile.prices_good];
        Nfeas = size(prices_good,1);
        benefits_good = zeros(Nfeas,1);
        parfor i = 1:Nfeas
            benefits_good(i) = -myfun_ES(prices_good(i, :), q, c, b, elm_options);
            if myfun_ESspend(prices_good(i,:), q, c, budget, elm_options) > 0 % overspend!
                benefits_good(i) = 0;
            end
        end   
        prices_feasible   = [prices_feasible;   prices_good(benefits_good>0,:)];
        benefits_feasible = [benefits_feasible; benefits_good(benefits_good>0,:)];
    end  
    
    % (e) Find local optima prices
    % ----------------------------  
    Ngood = 50;
    [prices_locopt, benefits_locopt] = fcn_find_locopt_prices(budget, b, c, q, elm_options, prices_max, prices_feasible, benefits_feasible, Ngood);

    Ngood = size(prices_locopt,1);
    mfile.prices_good(end+1:end+Ngood, 1:num_prices) = prices_locopt;
    mfile.benefits_good(end+1:end+Ngood,1)     = benefits_locopt;                                        
    

    % (f) MIP for global optimum
    % --------------------------  
    prices_lb = min(prices_locopt)' * 0;
    prices_ub = max(prices_locopt)' * 1.5;

    uptake_locopt = myfun_uptake(prices_locopt(1, :), q, c, elm_options)';
    uptake_locopt = uptake_locopt(:)';
    
    cplex_options.time = 1800;
    cplex_options.logs = cplex_folder;    
    [prices, uptake_sml, fval, exitflag, exitmsg] = MIP_fr_out(b, c, q, budget, prices_locopt(1, :), uptake_locopt, prices_lb, prices_ub, cplex_options);

    mfile.prices(iter, 1:num_prices) = prices ./ prices_scale;
    mfile.benefits(iter,1)           = fval;
        
end    
    

% 3. Solve Full Problem
% ---------------------
sample_size = 'no';  % all data

% (a) Load data
% -------------
data_year = 1;    
[b, c, q, budget, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, input_data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, data_year);
num_farmers = size(q, 1);
num_prices  = size(q, 2);
num_options = size(q, 3);
    
% (b) Scale quantities
% --------------------
prices_scale = reshape(permute(q, [1 3 2]),[], size(q,2));
prices_scale(prices_scale==0) = NaN;
prices_scale = nanstd(prices_scale);
q = q ./ prices_scale;

% (c) Price bounds from sample searches
% -------------------------------------
% matfile_name = ['prices_' payment_mechanism '_500_sample.mat'];
load(matfile_name, 'prices');
prices = prices .* prices_scale;

prices_lb = min(prices)';
prices_ub = max(prices)';

% (d) Find feasible prices
% ------------------------  
Nfeas = 40;
[prices_feasible, benefits_feasible] = fcn_find_feasible_prices(budget, b, c, q, elm_options, prices_lb'*0.75, prices_ub'*1.25, Nfeas);
prices_good = prices;
Nfeas = size(prices_good,1);
benefits_good = zeros(Nfeas,1);
parfor i = 1:Nfeas
    benefits_good(i) = -myfun_ES(prices_good(i, :), q, c, b, elm_options);
    if myfun_ESspend(prices_good(i,:), q, c, budget, elm_options) > 0 % overspend!
        benefits_good(i) = 0;
    end
end   
prices_feasible   = [prices_feasible;   prices_good(benefits_good>0,:)];
benefits_feasible = [benefits_feasible; benefits_good(benefits_good>0,:)];


% (d) Find local optima prices
% ----------------------------  
prices_lb = min(prices_feasible);
prices_ub = max(prices_feasible);
Ngood = 50;
[prices_locopt, benefits_locopt] = fcn_find_locopt_prices(budget, b, c, q, elm_options, prices_ub*1.25, prices_feasible, benefits_feasible, Ngood);


% (e) MIP for global optimum
% --------------------------  
prices_lb = min(prices_locopt)' * 0.75;
prices_ub = max(prices_locopt)' * 1.25;
prices_lb = zeros(size(prices_lb));
% prices_ub = max(prices_locopt)' * 2;

uptake_locopt = myfun_uptake(prices_locopt(1, :), q, c, elm_options)';
uptake_locopt = uptake_locopt(:)';

cplex_options.time = 3600;
cplex_options.logs = cplex_folder;   
    
[prices, uptake_sml, fval, exitflag, exitmsg] = MIP_fr_out(b, c, q, budget, prices_locopt(1, :), uptake_locopt, prices_lb, prices_ub, cplex_options);


% Process result
% --------------
% Rescale 
prices = prices ./ prices_scale;
q      = q .* prices_scale;

uptake        = myfun_uptake(prices, q, c, elm_options);
uptake_ind    = (sum(uptake,2) > 0);
option_nums   = (1:8)';
option_choice = (uptake * option_nums);
benefits      = sum(b.*uptake, 2);
costs         = sum(c.*uptake, 2);
pq            = squeeze(sum(q .* prices, 2));
farm_payment  = sum(pq.*uptake, 2);

% 4. Save Solution
% ----------------
solution.prices        = prices;
solution.fval          = sum(benefits);
solution.spend         = sum(farm_payment);
solution.uptake        = uptake;
solution.uptake_ind    = uptake_ind;
solution.option_choice = option_choice;
solution.new2kid       = new2kid(uptake_ind);
solution.farm_costs    = costs;
solution.farm_benefits = benefits;
solution.farm_payment  = farm_payment;
solution.prices_locopt = prices_locopt;
solution.prices_lb     = prices_lb;
solution.prices_ub     = prices_ub;

save(['solution_' budget_str '_' payment_mechanism '.mat'], 'solution');     

