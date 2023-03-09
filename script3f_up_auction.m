% script3f_up_auction.m
% =====================
% Uniform price auction.


% 1. Initialise
% -------------
clear
rng(23112010)

% Model
% -----
payment_mechanism = 'up_auc';
unscaled_budget = 1e9;
urban_pct_limit = 0.5;
bio_constraint = false;
carbon_price_string = 'non_trade_central';
drop_vars = {'habitat_non_use', 'biodiversity'};
budget_str = [num2str(round(unscaled_budget/1e9)) 'bill'];
biocnst_str = [num2str(round(bio_constraint*100)) 'pct'];

% Markup
% ------
markup = 1.15;

% Paths to Data & Cplex Working Dir
% ---------------------------------
data_folder  = 'D:\myGitHub\defra-elms\Data\';
data_path = [data_folder, 'elm_data_', carbon_price_string, '.mat'];


% 2. Prepare data
% ---------------
data_year = 1;    
sample_size = 'no';  % all data
[b, c, q, budget, cnst_data, cnst_target, elm_options, price_vars, new2kid] = load_data(sample_size, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, urban_pct_limit, bio_constraint, data_year);
num_prices  = length(price_vars);
num_options = size(b,2);
num_farmers = size(b,1);


% 3. Auction
% ----------
% Auction pays a flat rate for each unit of ecosystem service value
% delivered.

% Calculate benefits cost ratio
% -----------------------------
b_lng = b(:);
c_lng = c(:);
b_lng(b_lng<0) = 0;
cb_ratio = c_lng./b_lng;

% Sort from cheapest ES unit to most expensive
% --------------------------------------------
[price_pts, sortidx] = sort(cb_ratio, 'ascend', 'MissingPlacement', 'last'); % sort from best to worst

% Best option for each farm
% -------------------------
ids_lng = repmat(new2kid,num_options,1);
[~, ididx] = ismember(new2kid, ids_lng(sortidx)); 
first_id_ind = zeros(num_farmers*num_options,1);
first_id_ind(ididx) = 1;

% Find optimal uniform price
% --------------------------
ind_over_budget = (cumsum(b_lng(sortidx) .* first_id_ind) .* price_pts) >= budget;
prices = price_pts(find(ind_over_budget, 1)-1);

% Find uptake
% -----------
uptake_lng(sortidx) = (1 - ind_over_budget) .* first_id_ind;
uptake     = reshape(uptake_lng, num_farmers, num_options);
uptake_ind = logical(sum(uptake,2)>0);

% Process result
% --------------
option_nums   = (1:8)';
option_choice = (uptake>0) * option_nums;
benefits      = sum(b.*uptake, 2);
costs         = sum(c.*uptake, 2);
farm_payment  = sum(prices*b.*uptake, 2);


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

if bio_constraint > 0    
    save(['solution_' biocnst_str '_' budget_str '_' payment_mechanism '.mat'], 'solution'); 
else
    save(['solution_' budget_str '_' payment_mechanism '.mat'], 'solution');     
end


