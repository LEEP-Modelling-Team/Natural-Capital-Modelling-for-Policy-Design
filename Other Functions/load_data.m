function [b, c, q, budget, elm_options, vars_price, new2kid] = load_data(sample_num, unscaled_budget, data_path, payment_mechanism, drop_vars, markup, data_year)

    % (1) Set up
    %  ==========
    % Connect to database
    % -------------------
    server_flag = false;
    conn = fcn_connect_database(server_flag);

    % Load ELM option results from .mat file
    % --------------------------------------
    % Generated in script2_run_elm_options.m
    % Depends on carbon price
    load(data_path);
    
    % Remove Dodgy Data
    % -----------------
    dodgy_data_ind = round(costs.arable_reversion_sng_access(:,1),2)==534.31;
    % cells
    cell_info.new2kid  = cell_info.new2kid(~dodgy_data_ind);
    cell_info.ncells   = length(cell_info.new2kid);
    % benefits
    for k = 1:length(elm_options)
        elm_option_k = elm_options{k};
        benefits.(elm_option_k)             = benefits.(elm_option_k)(~dodgy_data_ind,:);
        benefits_table.(elm_option_k)       = benefits_table.(elm_option_k)(~dodgy_data_ind,:,:);
        benefit_cost_ratios.(elm_option_k)  = benefit_cost_ratios.(elm_option_k)(~dodgy_data_ind,:);
        costs.(elm_option_k)                = costs.(elm_option_k)(~dodgy_data_ind,:);
        costs_table.(elm_option_k)          = costs_table.(elm_option_k)(~dodgy_data_ind,:,:);
        es_outs.(elm_option_k)              = es_outs.(elm_option_k)(~dodgy_data_ind,:,:);
        env_outs.(elm_option_k)             = env_outs.(elm_option_k)(~dodgy_data_ind,:,:);
        elm_ha.(elm_option_k)               = elm_ha.(elm_option_k)(~dodgy_data_ind);
    end    
    
    % Choose sample of farmers to go into price search
    % ------------------------------------------------   
    if isnumeric(sample_num)
        farmer_perm = randperm(cell_info.ncells);
        farmer_sample_ind = (farmer_perm <= sample_num)';
        budget = (unscaled_budget/cell_info.ncells) * sample_num;
    elseif strcmp(sample_num, 'no')
        farmer_sample_ind = true(cell_info.ncells,1);
        budget = unscaled_budget;
    else
        fprintf('''sample_num'' can only assume a numeric value or ''no'' if no sampling is required\n'); 
    end

    
    % Remove vars in 'drop_vars'
    % --------------------------
    switch payment_mechanism
        case 'fr_es'
            vars_price = vars_es_outs;
            quantities = es_outs;
        case 'fr_env'
            vars_price = vars_env_outs;
            quantities = env_outs;
        case {'fr_act', 'fr_act_pctl'}
            vars_price = elm_options;
            quantities = elm_ha;  
        case 'oc'
            vars_price = elm_options;
            quantities = elm_ha;        
    end
    
    if ~isempty(drop_vars)
        
        for var = drop_vars

            % Remove from Quantities
            % ----------------------
            if ~any(strcmp(payment_mechanism, {'fr_act', 'fr_act_pctl', 'oc'}))
                [indvar, idxvar] = ismember(var, vars_price);            
                if indvar
                    % Remove from var list
                    vars_price(idxvar) = [];                                
                    % Remove from quantities                
                    for k = 1:length(elm_options)                 
                        quantities.(elm_options{k})(:,idxvar,:) = [];
                    end
                end
            end
            
            % Remove from Benefits
            % --------------------
            [indvar, idxvar] = ismember(var, vars_benefits);            
            if indvar   
                % Remove from benefits var list
                vars_benefits(idxvar) = [];                   
                % Remove from quantities
                for k = 1:length(elm_options) 
                    % Subtract away benefits for this var
                    benefits_drop = squeeze(benefits_table.(elm_options{k})(:, idxvar, :));                    
                    benefits.(elm_options{k}) = benefits.(elm_options{k}) - benefits_drop;
                    % Remove from benefits_table
                    benefits_table.(elm_options{k})(:,idxvar,:) = [];
                    % Recalculate benefits/costs ratio
                    benefit_cost_ratios.(elm_options{k}) = benefits.(elm_options{k}) ./ costs.(elm_options{k});                     
                end
            end                
        end        
    end
        
    % (2) Extract Sample Data
    % =======================
    % Note: All data has a 40 year time series for each cell for scheme  
    %       costs & benefits when implemented in each of those years.
    %       Those are expressed in npv in the base_year in £price_year.
    %       Model currently extracting just single year's data given by 
    %       data_year.
    benefits_year = nan(cell_info.ncells, num_elm_options);
    costs_year    = nan(cell_info.ncells, num_elm_options);
    for k = 1:num_elm_options
        benefits_year(:, k)         = benefits.(elm_options{k})(:, data_year);
        costs_year(:, k)            = costs.(elm_options{k})(:, data_year);
        if ~strcmp(payment_mechanism, 'fr_act')
            quantities.(elm_options{k}) = quantities.(elm_options{k})(:, :, data_year);
        end
    end

    % Use farmer_sample_ind to select farmers to include in price search
    % ------------------------------------------------------------------    
    % Extract relevant rows from above arrays/structures
    b = benefits_year(farmer_sample_ind, :);    
    c = costs_year(farmer_sample_ind, :);
    c = c .* markup;    
    q = [];
    if strcmp(payment_mechanism, 'fr_act')
        q = table2array(struct2table(quantities));
    else
        for k = 1:num_elm_options
            quantities.(elm_options{k}) = quantities.(elm_options{k})(farmer_sample_ind, :);
            q = cat(3, q, quantities.(elm_options{k}));
        end
    end
    new2kid = cell_info.new2kid;
    
end
