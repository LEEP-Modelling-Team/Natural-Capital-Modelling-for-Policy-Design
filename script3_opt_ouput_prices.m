% script3_opt_output_prices.m
% ===============================
%  Search for optimum flat rateprices for different payment mechanisms and 
%  budgets

clear
rng(23112010)


% 1. Initialise
% -------------
carbon_price_string = 'non_trade_central';
remove_nu_habitat = true;

unscaled_budget = 1e9;
payment_mechanism = 'fr_env';
numP = 9;

data_folder = 'D:\mydata\Research\Projects (Land Use)\Defra_ELMS\Data\';
data_path = [data_folder, 'Script 2 (ELM Option Runs)/elm_option_results_', carbon_price_string, '.mat'];

sample_size = 5000; % either 'no' or a number representing the sample size

if sample_size > 1000
    eval(['matfile_name = ''prices_' num2str(round(sample_size/1000)) 'k_sample.mat'';']);
else
    eval(['matfile_name = ''prices_' num2str(round(sample_size)) '_sample.mat'';']);
end
mfile = matfile(matfile_name, 'Writable', true);
if ~isfile(matfile_name)
    mfile.prices_good   = [];
    mfile.benefits_good = [];
    mfile.prices        = [];
    mfile.benefits      = [];
end


% 2. Iterate through data samples to identify price ranges
% --------------------------------------------------------
Niter = 1;

for iter = 1:Niter

    
    % (a) Load new sample of data
    % ---------------------------
    [b, c, q, budget, elm_options, new2kid] = load_data(sample_size, unscaled_budget, data_path, remove_nu_habitat);
    q(:, 10, :) = [];    
    
    
    % (b) Linear search for maximum possible prices
    % ---------------------------------------------
    constraintfunc = @(p) mycon_ES(p, q, c, budget, elm_options);
    prices_max = zeros(1, numP);
    start_rate = 5;
    for i = 1:numP
        env_outs_array_i = squeeze(q(:, i, :));
        prices_max(i) = fcn_lin_search(numP,i,start_rate,0.01,constraintfunc,q,c,budget,elm_options);
    end
    prices_min = zeros(size(prices_max));

    
    % (c) Find feasible prices
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
            
    
    % (d) Find local optima prices
    % ----------------------------  
    Ngood = 50;
    [prices_locopt, benefits_locopt] = fcn_find_locopt_prices(budget, b, c, q, elm_options, prices_max, prices_feasible, benefits_feasible, Ngood);

    Ngood = size(prices_locopt,1);
    mfile.prices_good(end+1:end+Ngood, 1:numP) = prices_locopt;
    mfile.benefits_good(end+1:end+Ngood,1)     = benefits_locopt;                                        
    

    % (e) MIP for global optimum
    % --------------------------  
    price_lb = min(prices_locopt)' * 0;
    price_ub = max(prices_locopt)' * 1.25;

    uptake_locopt = myfun_uptake(prices_locopt(1, :), q, c, elm_options)';
    uptake_locopt = uptake_locopt(:)';
    
    [x_milp, prices_milp, fval_milp, exitflag, exitmsg] =  MILP_output_prices(b, c, q, budget, prices_locopt(1, :), uptake_locopt, price_lb, price_ub);

    mfile.prices(iter, 1:numP) = prices_milp;
    mfile.benefits(iter,1)     = fval_milp;
        
end    
    

% 3. Solve Full Problem
% ---------------------
sample_size = 'no';  % all data

% (a) Load data
% -------------
[b, c, q, budget, elm_options, new2kid] = load_data(sample_size, unscaled_budget, data_path, remove_nu_habitat);
q(:, 10, :) = [];    

% (b) Price bounds from sample searches
% -------------------------------------
matfile_name = 'prices_5k_sample.mat';
load(matfile_name, 'prices');

prices_lb = min(prices)';
prices_ub = max(prices)';

% (c) Find feasible prices
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

uptake_locopt = myfun_uptake(prices_locopt(1, :), q, c, elm_options)';
uptake_locopt = uptake_locopt(:)';

cplex_time = 61200;
[x_milp, prices_milp, fval_milp, exitflag, exitmsg] =  MILP_output_prices(b1, c1, q1, budget, prices_locopt(1, :), uptake_locopt1, prices_lb, prices_ub, cplex_time);



% 4. Save Solution
% ----------------
solution.x             = x_milp;
solution.prices        = prices_milp;
solution.fval          = fval_milp;
solution.exitflag      = exitflag;
solution.prices_locopt = prices_locopt;
solution.prices_lb     = prices_lb;
solution.prices_ub     = prices_ub;
solution.new2kid       = new2kid;

save('solution_env_out_prices.mat', 'solution');

