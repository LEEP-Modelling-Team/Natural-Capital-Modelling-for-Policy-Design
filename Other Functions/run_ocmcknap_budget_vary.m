%% run_ocmcknap_budget_vary.m
%  ==========================
%  Run opportunity cost scheme (multiple-choice knapsack problem) for
%  a range of budgets
clear

% Flag: remove non-use habitat values?
remove_nu_habitat = false;

%% (1) Set up
%  ==========
% Connect to database
% -------------------
server_flag = false;
conn = fcn_connect_database(server_flag);

% Set up model parameters
% -----------------------
markup = 1.15; 

% Load ELM option results from .mat file
% --------------------------------------
% Generated in script2_run_elm_options.m
load('elm_option_results.mat')

% Load 2km grid cells in England
% ------------------------------
sqlquery = ['SELECT ', ...
                'tbl1.new2kid, ', ...
                '(tbl1.__xmin + tbl1.__xmax) / 2 AS easting, ', ...
                '(tbl1.ymin + tbl1.ymax) / 2 AS northing ', ...
            'FROM regions.grid AS tbl1 INNER JOIN ', ...
                 'regions_keys.key_grid_countries_england AS tbl2 ', ...
                 'ON tbl1.new2kid = tbl2.new2kid ', ...
            'ORDER BY new2kid'];
setdbprefs('DataReturnFormat', 'structure');
dataReturn  = fetch(exec(conn, sqlquery));
cell_info = dataReturn.Data;
cell_info.ncells = length(cell_info.new2kid);   % Number of cells

% Remove non-use habitat values if specified
% ------------------------------------------
if remove_nu_habitat
    % Loop over ELM options
    for k = 1:length(available_elm_options)
        % Extract total and individual ES benefits for option k
        elm_option_k = available_elm_options{k};
        total_benefits_elm_option_k = benefits.(elm_option_k);
        benefits_table_elm_option_k = benefits_table.(elm_option_k);
        es_outs_table_elm_option_k = es_outs.(elm_option_k);
        
        % Calculate sum of non-use benefits and subtract from total
        % benefits / ecosystem services
        total_nu_benefits_elm_option_k = squeeze(sum(benefits_table_elm_option_k(:, 13, :), 2));
        benefits.(elm_option_k) = total_benefits_elm_option_k - total_nu_benefits_elm_option_k;
        benefits_table_elm_option_k(:, 1, :) = squeeze(benefits_table_elm_option_k(:, 1, :)) - total_nu_benefits_elm_option_k;
        
        % Set non-use values to zero in appropriate places
        benefits_table_elm_option_k(:, 13, :) = zeros(cell_info.ncells, 1, 5);
        benefits_table.(elm_option_k) = benefits_table_elm_option_k;
        es_outs_table_elm_option_k(:, 9, :) = zeros(cell_info.ncells, 1, 5);
        es_outs.(elm_option_k) = es_outs_table_elm_option_k;
    end
end

%% (2) Loop over payment mechanisms
%  ================================
% (a) Set up variables for loop
% -----------------------------
% Number of available ELMs options - available ELM options in
% elm_option_results.mat
num_elm_options = length(available_elm_options);

% Set up number of years for loop - just use first year for this script
years = 1;
nyears = length(years);

% Set up range of budgets
budget_min = 1e+8;
budget_max = 5e+9;
budget_increment = 1e+8;
budgets = (budget_min:budget_increment:budget_max)';
num_budgets = length(budgets);

% Set up payment mechanism - repeat opp_cost_benefit
payment_mechanisms = repmat({'oc'}, num_budgets, 1);

% Set number of payment mechanisms and check equal to number of budgets
nsim = length(payment_mechanisms);
if nsim ~= length(budgets) 
    error('Payment mechanisms and budgets must be of equal length!')
end

% (b) Preallocate matrices to store results
% -----------------------------------------
es_outcomes = zeros(nsim, num_es_outs);

% (c) Loop over payment mechanisms
% --------------------------------
for sim = 1:nsim
    % Set year farmer is in scheme
    % ----------------------------
    % This gets updated each year
    rng(2074675) % Use random seed to get repeatable results
    scheme_year = randi(5, cell_info.ncells, 1);
    
    % Set current payment mechanism and budget to MP structure
    % --------------------------------------------------------
    payment_mechanism_sim = payment_mechanisms{sim};
    budget_sim            = budgets(sim);
    
    % Print simulation info to screen
    % -------------------------------
    fprintf('\nELMS SIMULATION %.0f\n', sim);   
    fprintf('================= \n\n');  
    fprintf(['  Payment Mechanism: ' payment_mechanism_sim '\n']);  
    fprintf('  Budget:        %.0f \n', budget_sim);   

    % Preallocate arrays to store results for this simulation
    % -------------------------------------------------------
    % Ecosystem services
    es_outcomes_sim = zeros(cell_info.ncells, num_es_outs);

    %% (3) Let farmers choose ELM options over 5 year loop
    %  ===================================================
    % Only use 1st year here
    for i = years
        % (a) Run payment mechanism to select farmers in this year
        %  --------------------------------------------------------
        [chosen_option_ind, ...
		 chosen_option_idx, ...
		 option_choice, ...
		 opt_cells, ...
		 scheme_year, ...
		 flat_rate, ...
		 farm_payment] = fcn_run_payment_mechanisms(payment_mechanism_sim, ...
													budget_sim, ...
													markup, ...
													available_elm_options, ...
													i, ...
													scheme_year, ...
													cell_info.new2kid, ...
													elm_ha, ...
													benefits, ...
													costs, ...
													env_outs, ...
													es_outs);

        % (b) Save results in this year
        %  ----------------------------
        % Option specific info:
        for k = 1:num_elm_options
            % Set up
            % ------
            % Current option
            elm_option = available_elm_options{k};

            % Indicator into full cell list for this option
            elm_option_ind = chosen_option_ind.(elm_option);
            elm_option_idx = chosen_option_idx.(elm_option);

            % opt_cells reduced for this option
            opt_cells_option_k = opt_cells(option_choice == k, :);

            % Proportion of option for each cell in correct order
            elm_option_proportion = opt_cells_option_k(elm_option_idx, 2);

            % Save results
            % ------------
            es_outcomes_sim(elm_option_ind, :) =  elm_option_proportion .* es_outs.(elm_option)(elm_option_ind, :, i);
        end
        
        % Sum benefits/ecosystem services across all cells
        es_outcomes(sim, :) = sum(es_outcomes_sim);
    end
end 

%% (4) Prepare and save results
%  ============================
% Convert es_outcomes to table (remove bio column)
es_outcomes_table = array2table(es_outcomes(:, 1:(end-1)), ...
                                'VariableNames', ...
                                {'ghg', ...
                                 'rec', ...
                                 'flooding', ...
                                 'totn', ...
                                 'totp', ...
                                 'water_non_use', ...
                                 'pollination', ...
                                 'non_use_pollination', ...
                                 'non_use_habitat'});

% Calculate total ecosystem service benefit and convert to table
total_benefits_table = array2table(sum(es_outcomes_table{:, :}, 2), ...
                                   'VariableNames', {'total'});

% Convert budgets to table
budgets_table = array2table(budgets, 'VariableNames', {'budget'});

% Combine tables
results_table = [budgets_table, total_benefits_table, es_outcomes_table];

% Save to CSV
if remove_nu_habitat
    writetable(results_table, './Runs/Final Results/McKnap Budget Vary/ocmcknap_budget_vary_without_nu.csv')
else
    writetable(results_table, './Runs/Final Results/McKnap Budget Vary/ocmcknap_budget_vary.csv')
end

% %% (5) Plots
% %  =========
% figure
% 
% % Budget v Benefits
% subplot(1, 3, 1)
% plot(results_table.budget, results_table.total);
% 
% % Budget v BCR
% subplot(1, 3, 2)
% plot(results_table.budget, results_table.total ./ results_table.budget);
% 
% % Budget v Marginal Benefits
% subplot(1, 3, 3)
% plot(results_table.budget, diff([0; results_table.total]))
% hold on
% plot(results_table.budget, diff([0; results_table.budget])) % add budget v marginal budget line
% hold off