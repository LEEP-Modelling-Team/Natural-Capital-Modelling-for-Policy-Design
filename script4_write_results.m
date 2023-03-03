% script4_write_results.m
% ======================

% 1. Initialise
% -------------
clear
rng(23112010)

% Model
% -----
payment_mechanisms = {'fr_env', 'fr_es', 'fr_act', 'fr_act_pctl', 'fr_act_pctl_rnd', 'oc_pay', 'up_auc'};
unscaled_budget = 1e9;
carbon_price_string = 'scc';
drop_vars = {'habitat_non_use', 'biodiversity'};
budget_str = [num2str(round(unscaled_budget/1e9)) 'bill'];
scheme_year = 1;

% Markup
% ------
markup = 1.15;

% Paths to Data & Cplex Working Dir
% ---------------------------------
data_folder  = 'D:\myGitHub\defra-elms\Data\';
data_path = [data_folder, 'elm_option_results_', carbon_price_string, '.mat'];


% 2. Initialise
% -------------

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


% Remove vars in 'drop_vars'
% --------------------------
if ~isempty(drop_vars)

    for var = drop_vars

        % Remove from Environmental Outcomes
        % ----------------------------------
        [indvar, idxvar] = ismember(var, vars_env_outs);            
        if indvar
            % Remove from var list
            vars_env_outs(idxvar) = [];
            num_env_outs = num_env_outs - 1;
            % Remove from quantities                
            for k = 1:length(elm_options)                 
                env_outs.(elm_options{k})(:,idxvar,:) = [];                
            end
        end
        
        % Remove from Ecosystem Services
        % ------------------------------
        [indvar, idxvar] = ismember(var, vars_es_outs);            
        if indvar
            % Remove from var list
            vars_es_outs(idxvar) = [];  
            num_es_outs = num_es_outs - 1;
            % Remove from quantities                
            for k = 1:length(elm_options)                 
                es_outs.(elm_options{k})(:,idxvar,:) = [];
            end
        end        

        % Remove from Benefits
        % --------------------
        [indvar, idxvar] = ismember(var, vars_benefits);            
        if indvar   
            % Remove from benefits var list
            vars_benefits(idxvar) = []; 
            num_benefits = num_benefits - 1;
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


% Preallocate arrays to store results
% -----------------------------------

nyears = 1;



for i = 1:numel(payment_mechanisms)
    
    payment_mechanism = payment_mechanisms{i};
    
    fprintf('\nPayment Mechanism: %s \n', payment_mechanism);    
    fprintf('------------------\n');    
        
    % Load Solution for this Payment Mechanism
    % ----------------------------------------
    clear solution
    load([data_folder 'solution_' budget_str '_' payment_mechanism '.mat'], 'solution');   

    % Number of cells chosen in this year
    num_chosen = size(solution.new2kid, 1);
    fprintf('Num Farmers with Agreement: %.0f \n', num_chosen);    

    % IDs of cells chosen in this year
    chosen_cells{1} = solution.new2kid;
    
    % Cell id
    cell_id = array2table(cell_info.new2kid, 'VariableNames', {'new2kid'});

    % Which options farmers have chosen
    option_choice = array2table(solution.option_choice, 'VariableNames', {'option_choice'});

    % Probability of seeing this choice (only <1 in 'fr_act_pctl_rnd') 
    choice_prob = array2table(solution.uptake_ind, 'VariableNames', {'choice_prob'});

    % Payment to farmer
    farm_payment = array2table(solution.farm_payment.*solution.uptake_ind, 'VariableNames', {'farm_payment'});
    farm_costs   = array2table(solution.farm_costs.*solution.uptake_ind, 'VariableNames', {'farm_costs'});
    farm_net     = array2table((solution.farm_payment - solution.farm_costs).*solution.uptake_ind, 'VariableNames', {'farm_net'});
 
    
    % Option specific info
    % --------------------
    % Hectares in chosen option
    option_hectares = array2table(zeros(cell_info.ncells, 1), 'VariableNames', {'option_hectares'});

    % Total benefits as npv, also split into ecosystem services
    benefits_npv_table = array2table(zeros(cell_info.ncells, num_benefits+1), 'VariableNames', strcat('benefits_', ['total' vars_benefits]));

    % Total costs as npv, also split into individual costs
    costs_npv_table = array2table(zeros(cell_info.ncells, num_costs+1), 'VariableNames', strcat('costs_', ['total' vars_costs]));

    % Environmental outcomes
    env_outcomes_table = array2table(zeros(cell_info.ncells, num_env_outs), 'VariableNames', strcat('env_out_', vars_env_outs)); 

    % Ecosystem services
    es_outcomes_table = array2table(zeros(cell_info.ncells, num_es_outs), 'VariableNames', strcat('es_out_', vars_es_outs));
    
    for k = 1:num_elm_options

        elm_option = elm_options{k};
        
        option_ind = (solution.option_choice == k);

        % Hectares for chosen option 
        option_hectares.option_hectares(option_ind) = elm_ha.(elm_option)(option_ind) .* solution.uptake_ind(option_ind);
        
        % Benefits
        benefits_k = benefits_table.(elm_option)(option_ind, :, scheme_year).* solution.uptake_ind(option_ind);
        benefits_npv_table(option_ind, :) = array2table([sum(benefits_k,2) benefits_k]);

        % Costs
        costs_k = costs_table.(elm_option)(option_ind, :, scheme_year) .* solution.uptake_ind(option_ind);
        costs_npv_table(option_ind, :) = array2table([sum(costs_k,2) costs_k]);
              
        % Environmental outcomes
        env_outcomes_table(option_ind, :) = array2table(env_outs.(elm_option)(option_ind, :, scheme_year) .* solution.uptake_ind(option_ind));

        % Environmental outcome values
        es_outcomes_table(option_ind, :) = array2table(es_outs.(elm_option)(option_ind, :, scheme_year) .* solution.uptake_ind(option_ind));
        
    end

    % Construct results table
    % -----------------------
    results = [cell_id, ...
               option_choice, ...
               option_hectares, ...
               farm_payment, ...
               farm_costs, ...
               farm_net, ...
               benefits_npv_table, ...
               costs_npv_table, ...
               env_outcomes_table, ...
               es_outcomes_table];    
   
    % Add Benefit to Cost ratio
    results.bcr = results.benefits_total ./ results.farm_payment;
    results.bcr(isnan(results.bcr)) = 0;
    
    % Reduce to chosen farms
    results = results(solution.uptake_ind>0,:); 

    % Write results table to .csv file 
    writetable(results, [data_folder 'results_' budget_str '_' payment_mechanism '.csv']);   
    
    
    % (5) Write aggregated/summarised data to spreadsheet
    %  ==================================================
    % Set up filename and correct sheet for .xls spreadsheet
    filename = [data_folder 'results_all.xlsx'];
    sheet = [payment_mechanism, '_', budget_str];

    % (a) Title
    % ---------
    xlswrite(filename, {['Scheme: ' sheet]}, sheet, 'A1');
    
    % (b) Scheme Summary
    % ------------------
    xlswrite(filename, {'Outcomes:'}, sheet, 'A4');
    summary_data = [solution.fval, solution.spend, solution.fval/solution.spend, length(solution.new2kid)];
    summary_vars = {'es_benefits', 'spend', 'benefit2spend', 'num_cells'};
    summary_tbl  = array2table(summary_data, 'VariableNames', summary_vars);
    writetable(summary_tbl, filename, 'Sheet', sheet, 'Range', 'A5');
        
    % (c) Prices
    % ----------
    xlswrite(filename, {'Prices:'}, sheet, 'A7');
    switch payment_mechanism
        case 'fr_es'
            vars_price = vars_es_outs;
        case 'fr_env'
            vars_price = vars_env_outs;
        case {'fr_act', 'fr_act_pctl', 'fr_act_pctl_rnd'}
            vars_price = elm_options;
        case {'up_auc'}
            vars_price = {'es_value'};        
        case {'oc_pay'}
            vars_price = [];
    end  
    
    if ~strcmp(payment_mechanism, {'oc_pay'})
        
        if strcmp(payment_mechanism, {'fr_env'})
            % Convert units of flooding, N and P prices
            % Flooding: cubic metres per second -> litres per second
            % N & P: milligrams per litre -> micrograms per litre
            idx = find(strcmp(vars_env_outs, 'tot_n'));
            solution.prices(idx) = solution.prices(idx)/1000;
            idx = find(strcmp(vars_env_outs, 'tot_p'));
            solution.prices(idx) = solution.prices(idx)/1000;
            idx = find(strcmp(vars_env_outs, 'flood'));
            solution.prices(idx) = solution.prices(idx)/1000;
        end
        
        prices_tbl = array2table(solution.prices, 'VariableNames', vars_price);
        writetable(prices_tbl, filename, 'Sheet', sheet, 'Range', 'A8');       
    end
        
    % (d) Option Choice Frequency
    % ---------------------------
    xlswrite(filename, {'Option Uptake:'}, sheet, 'A11');
    summary_option = tabulate(results.option_choice);
    option_choice_tbl = array2table(summary_option, 'VariableNames', {'option_idx', 'count', 'percent'});
    option_names_tbl  = cell2table(elm_options', 'VariableNames', {'option_name'});
    height_diff = height(option_choice_tbl) < height(option_names_tbl);
    if height_diff > 0
       new_rows = array2table([(height(option_choice_tbl)+1:1:height(option_choice_tbl)+height_diff)' zeros(height_diff, width(option_choice_tbl)-1)], 'VariableNames', option_choice_tbl.Properties.VariableNames);
       option_choice_tbl = vertcat(option_choice_tbl, new_rows); 
    end
    option_tbl = [option_names_tbl option_choice_tbl];
	writetable(option_tbl, filename, 'Sheet', sheet, 'Range', 'A12');
    
    
end