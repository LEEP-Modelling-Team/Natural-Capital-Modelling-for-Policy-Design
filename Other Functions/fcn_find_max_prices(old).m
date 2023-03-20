%% fcn_find_max_prices
%  ===================
%  Author:        Mattia Mancini
%  Created:       19-Jan-2023
%  Last modified: 19-Jan_2023
%  -----------------------------
%
%  DESCRIPTION
%  Function to find a max bound for the payment per hectare of each elms
%  option which will use the entire budget. This also allows to identify
%  the subset of cells that is never enrolled into any option, regardldess
%  of the budget
%
%  INPUTS:
%      - c: cost array: total cost for each farmer for each option,
%           including markup
%      - q: quantity array. This can be the number of hectares available
%           for enrollment in the scheme (payments for activity, 2d array) 
%           or quantity of environmental good/ecosystem service generated
%           (this is a 3d array of size X x Y x Z where X is the number of
%           cells (i.e., 32784 for England), Y is the number of
%           environmental quantities/ecosystem services (e.g., 10) and Z is
%           the number of elms options (e.g., 8).
%       - cell_ids: the new2kid of the cells in the analysis
%       - budget: the total budget for the scheme
%       - payment: the type of payment ('fr_act', 'fr_env', 'fr_es').
%  ========================================================================


function [max_rates, ids_to_remove, unique_options] = fcn_find_max_prices(c, q, cell_ids, budget, payment_mechanism)
    
    switch payment_mechanism
        case 'fr_act'
            
            %% 1. COSTS IN ASCENDING ORDER
            %  ===========================
            cost_sorted  = nan(length(c), size(c,2));
            cells_sorted = nan(length(q), size(q,2));
            q_sorted = nan(length(q), size(q,2));
            for i = 1:size(c,2)
                [cost_sorted(:, i), idx] = sort(c(:, i),'ascend');
                cells_sorted(:, i) = cell_ids(idx);
                q_sorted(:, i) = q(idx);
            end
            q_sorted(q_sorted == 0) = nan;

            %% 2. FIND RATES THAT EXHAUST THE BUDGET
            %  =====================================
            max_rates = zeros(1, size(q,2));
            excluded_cells = ones(length(cell_ids), size(q,2));
            for i = 1:size(q,2)
                p = max_rates(i);
                surplus = (p .* q_sorted(:, i) - cost_sorted(:, i));
                while ~any(any(cumsum(surplus(surplus > 0), 'omitnan') > budget))
                    p = p + 100;
                    surplus = (p .* q_sorted(:, i) - cost_sorted(:, i));
                end
                max_rates(i) = p;
                excluded_cells(surplus > 0, i) = 0;
            end

            %% 3. FIND CELLS NEVER INTO ANY SCHEME
            %  ===================================
            excluded_idx = sum(excluded_cells, 2) == size(q,2);
            ids_to_remove = cell_ids(excluded_idx);
        
        case {'fr_env'}
            %% 1. FIND RATES THAT EXHAUST THE BUDGET
            %  =====================================
            
            % env_outs = GHG, rec grass access, rec wood access, rec grass no access, rec wood no access, flood, tot n, tot p, pollinator species, biodiversity
            % es_outs =  GHG val, rec val, flood val, totn val, totp val, water non-use val, pollination val, non use pollination val, non use habitat, biodiversity val
            max_rates = zeros(1, 10);
            excluded_cells = ones(length(cell_ids), size(q, 2));
            unique_options = [];
            for i = 1:10
                p = max_rates(i);
                q_i = reshape(q(:, i, :), [height(q), 8]);
                if i == 6 || i == 7 || i == 8 
                    q_i = -q_i;
                end
                surplus = p .* q_i - c;
                [uptake, idx] = max(surplus .* (surplus > 0), [], 2);
               
                while sum(uptake) <= budget
                    if i == 6 || i == 7 || i == 8
                        p = p + 10;
                    else
                        p = p + 0.1;
                    end
                    surplus = (p .* q_i - c);
                    [uptake, idx] = max(surplus .* (surplus > 0), [], 2);
                    idx(uptake == 0) = 0;
                end
                max_rates(i) = p;
                excluded_cells(idx > 0, i) = 0;
                unique_options = union(unique_options, unique(idx));
            end
            %% 2. FIND CELLS NEVER INTO ANY SCHEME
            %  ===================================
            excluded_idx = sum(excluded_cells, 2) == size(q,2);
            ids_to_remove = cell_ids(excluded_idx);
    end
end
    
