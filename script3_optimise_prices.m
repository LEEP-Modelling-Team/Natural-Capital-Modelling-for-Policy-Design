%% script3_run_search_for_prices.m
%  ===============================
%  Run search algorithm / scattergun approach to find optimum prices for
%  different payment mechanisms and budgets
clear

% Flag: remove non-use habitat values?
remove_nu_habitat = true;

%% (1) Set up
%  ==========
% Connect to database
% -------------------
server_flag = false;
conn = fcn_connect_database(server_flag);

% Set up model parameters
% -----------------------
% Markup
markup = 1.15; 

% Carbon price
% carbon_price_string = 'scc';
% carbon_price_string = 'non_trade_low';
carbon_price_string = 'non_trade_central';
% carbon_price_string = 'non_trade_high';

% Load ELM option results from .mat file
% --------------------------------------
% Generated in script2_run_elm_options.m
% Depends on carbon price
load(['Script 2 (ELM Option Runs)/elm_option_results_', carbon_price_string, '.mat'])

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

% Choose sample of farmers to go into price search
% ------------------------------------------------
% Select a 1/5th of farmers 
rng(40);
farmer_perm = randperm(cell_info.ncells);
farmer_sample_ind = (farmer_perm <= round(cell_info.ncells / 5))';

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
% Number of available ELMs options
% (available_elm_options is set in previous script)
num_elm_options = length(available_elm_options);

% Set up number of years for loop
years = 1:5;
nyears = length(1:5);

% Payment mechanism names
% -----------------------
% (comment out as necessary)
% Permitted: 
% - 'fr_act'                    % Flat rate for activity (umbrella budget)
% - 'fr_act_pct'                % Flat rate for activity using percentile prices (umbrella budget)
% - 'fr_act_shared'             % Flat rate for activity (shared budget)
% - 'fr_env'                    % Flat rate for environmental outcome (umbrella budget)
% - 'fr_es'                     % Flat rate for ecosystem service (umbrella budget)
% Not permitted:
% - 'oc'                        % Opportunity cost (umbrella budget)
% - 'oc_shared'                 % Opportunity cost (shared budget)
% payment_mechanisms = {'fr_act'; ...
%                       'fr_act'; ...
%                       'fr_act'; ...
%                       'fr_act_pct'; ...
%                       'fr_act_pct'; ...
%                       'fr_act_pct'; ...
%                       'fr_act_shared'; ...
%                       'fr_act_shared'; ...
%                       'fr_act_shared'; ...
%                       'fr_env'; ...
%                       'fr_env'; ...
%                       'fr_env'; ...
%                       'fr_es'; ...
%                       'fr_es'; ...
%                       'fr_es'};

payment_mechanisms = {'fr_act', ...
                      'fr_act', ...
                      'fr_act'};

% Payment mechanism budgets
% -------------------------
% Must correspond to payment mechanism names above
% (comment out as necessary)
% budgets = [1e+9; ...
%            2e+9; ...
%            3e+9; ...
%            1e+9; ...
%            2e+9; ...
%            3e+9; ...
%            1e+9; ...
%            2e+9; ...
%            3e+9; ...
%            1e+9; ...
%            2e+9; ...
%            3e+9; ...
%            1e+9; ...
%            2e+9; ...
%            3e+9];

budgets = [1e+9, ...
           2e+9, ...
           3e+9];
       
% Set number of payment mechanisms and check equal to number of budgets
nsim = length(payment_mechanisms);
if nsim ~= length(budgets) 
    error('Payment mechanisms and budgets must be of equal length!')
end

% (b) Loop over payment mechanisms
% --------------------------------
for i = 1:nsim
    % Set current payment mechanism and budget to MP structure
    % --------------------------------------------------------
    payment_mechanism_i = payment_mechanisms{i};
    budget_i            = budgets(i);
    
    % Print simulation info to screen
    % -------------------------------
    fprintf('\nELMS SIMULATION %.0f\n', i);   
    fprintf('================= \n\n');  
    fprintf(['  Payment Mechanism: ' payment_mechanism_i '\n']);  
    fprintf('  Budget:        %.0f \n', budget_i); 
    
    % Run search algorithm to find prices
    % -----------------------------------
    tic
    prices = fcn_run_price_optimisation(payment_mechanism_i, ...
                                        budget_i, ...
                                        markup, ...
                                        available_elm_options, ...
                                        farmer_sample_ind, ...
                                        cell_info.new2kid, ...
                                        elm_ha, ...
                                        benefits, ...
                                        costs, ...
                                        env_outs, ...
                                        es_outs, ...
                                        unit_value_max);
    toc
                                      
    % Save prices to /Optimised Prices folder
    % ---------------------------------------
    % Depends on carbon price
    % Turn budget into single character (e.g. 1 billion = '1')
    budget_char = num2str(budget_i);
    budget_char = budget_char(1);
    
    % Create filename and save
    if remove_nu_habitat
        save(['./Script 3 (Optimised Prices)/prices_', ...
              payment_mechanism_i, ...
              '_', ...
              budget_char, ...
              '_lp_no_nu_habitat_', ...
              carbon_price_string, ...
              '.mat'], ...
              'prices');
    else
        save(['./Script 3 (Optimised Prices)/prices_', ...
              payment_mechanism_i, ...
              '_', ...
              budget_char, ...
              '_lp_', ...
              carbon_price_string, ...
              '.mat'], ...
              'prices');
    end
end