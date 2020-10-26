%% script4_run_farmer_uptake.m
%  ===========================
% For a choice of budget(s) and payment mechanism(s), let farmers choose 
% between options
% Extract costs, benefits, etc from farmers which have taken up an option
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
% carbon_price_string = 'nontraded_low';
carbon_price_string = 'nontraded_central';
% carbon_price_string = 'nontraded_high';

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

% Load ELM option results from .mat file
% --------------------------------------
% This depends on choice of recreation access in MP.site_type
load(['Script 2 (ELM Option Runs)/elm_option_results_', carbon_price_string, '.mat'])

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
% - 'oc'                        % Opportunity cost (umbrella budget)
% - 'oc_shared'                 % Opportunity cost (shared budget)
% - 'fr_act'                    % Flat rate for activity (umbrella budget)
% - 'fr_act_pct'                % Flat rate for activity using percentile prices (umbrella budget)
% - 'fr_act_shared'             % Flat rate for activity (shared budget)
% - 'fr_env'                    % Flat rate for environmental outcome (umbrella budget)
% - 'fr_es'                     % Flat rate for ecosystem service (umbrella budget)
% payment_mechanisms = {'oc'; ...
%                       'oc'; ...
%                       'oc'; ...
%                       'oc_shared'; ...
%                       'oc_shared'; ...
%                       'oc_shared'; ...
%                       'fr_act'; ...
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
% Must be 1, 2, or 3 billion
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
for sim = 1:nsim
    % Set year farmer is in scheme
    % ----------------------------
    % Must be reset for every simulation, gets updated within year loop
    rng(2074675) % Use random seed to get repeatable results
    scheme_year = randi(5, cell_info.ncells, 1);
    
    % Set current payment mechanism and budget to MP structure
    % --------------------------------------------------------
    payment_mechanism_sim = payment_mechanisms{sim};
    budget_sim            = budgets(sim);
    
    % Turn budget into single character (e.g. 1 billion = '1')
    budget_char = num2str(budget_sim);
    budget_char = budget_char(1);
    
    % Print simulation info to screen
    % -------------------------------
    fprintf('\nELMS SIMULATION %.0f\n', sim);   
    fprintf('================= \n\n');  
    fprintf(['  Payment Mechanism: ' payment_mechanism_sim '\n']);  
    fprintf('  Budget:        %.0f \n', budget_sim);   

    % Preallocate arrays to store results
    % -----------------------------------
    % Number of farms chosen each year
    num_chosen = zeros(nyears, 1);

    % 2km grid cell ids of chosen each year
    chosen_cells = cell(nyears, 1);

    % Year farmer is chosen
    year_chosen = array2table(zeros(cell_info.ncells, 1), 'VariableNames', {'year_chosen'});

    % Which options farmers have chosen
    option_choices = array2table(zeros(cell_info.ncells, 1), 'VariableNames', {'option_choices'});

    % Hectares in chosen option
    option_hectares = array2table(zeros(cell_info.ncells, 1), 'VariableNames', {'option_hectares'});

    % Total benefits as npv, also split into ecosystem services
    benefits_npv_table = array2table(zeros(cell_info.ncells, num_benefits), 'VariableNames', {'benefit_total', 'benefit_ghg_farm', 'benefit_forestry', 'benefit_ghg_forestry', 'benefit_ghg_soil_forestry', 'benefit_rec', 'benefit_flooding', 'benefit_totn', 'benefit_totp', 'benefit_water_non_use', 'benefit_pollination', 'benefit_non_use_pollination', 'benefit_non_use_habitat', 'benefit_bio'});
    
    % Total costs as npv, also split into individual costs
    costs_npv_table = array2table(zeros(cell_info.ncells, num_costs), 'VariableNames', {'cost_farm', 'cost_forestry', 'cost_rec', 'cost_total'});
    
    % Total costs as annuity
    costs_ann_table = array2table(zeros(cell_info.ncells, 1), 'VariableNames', {'cost_total'});

    % Environmental outcomes
    env_outcomes_table = array2table(zeros(cell_info.ncells, num_env_outs), 'VariableNames', {'env_out_ghg', 'env_out_rec_grass_access', 'env_out_rec_wood_access', 'env_out_rec_grass_noaccess', 'env_out_rec_wood_no_access', 'env_out_flooding', 'env_out_totn', 'env_out_totp', 'env_out_pollination', 'env_out_bio'}); 

    % Ecosystem services
    es_outcomes_table = array2table(zeros(cell_info.ncells, num_es_outs), 'VariableNames', {'es_out_ghg', 'es_out_rec', 'es_out_flooding', 'es_out_totn', 'es_out_totp', 'es_out_water_non_use', 'es_out_pollination', 'es_out_non_use_pollination', 'es_out_non_use_habitat', 'es_out_bio'});

    % Payment to farmer
    payment_to_farmer = array2table(zeros(cell_info.ncells, 1), 'VariableNames', {'payment_to_farmer'});

    % Net payment to farmer
    % (set below loop)

    %% (3) Let farmers choose ELM options over 5 year loop
    %  ===================================================
    % Loop over 5 years
    for i = years
        % Print simulation info to screen
        fprintf('\n  Year of Scheme:  %.0f \n', i);  
        fprintf('  ------------------ \n');  

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
													es_outs, ...
                                                    remove_nu_habitat, ...
                                                    carbon_price_string);

        % (b) Save results in this year
        %  ----------------------------
        % Number of cells chosen in this year
        num_chosen(i) = size(opt_cells, 1);
        fprintf('Num Farmers with Agreement: %.0f \n', num_chosen(i));    

        % IDs of cells chosen in this year
        chosen_cells{i} = opt_cells(:, 1);

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
            % Year chosen
            year_chosen.year_chosen(elm_option_ind) = i;

            % Chosen option 1-16 (regardless of year)
            option_choices.option_choices(elm_option_ind) = k;

            % Hectares for chosen option (regardless of year)
            option_hectares.option_hectares(elm_option_ind) = elm_option_proportion .* elm_ha.(elm_option)(elm_option_ind);

            % Total benefits
            % !!! Always use year 1 costs, benefits, etc...
            benefits_npv_table(elm_option_ind, :) =  array2table(elm_option_proportion .* benefits_table.(elm_option)(elm_option_ind, :, 1));

            % Total costs
            % !!! Always use year 1 costs, benefits, etc...
            costs_npv_table(elm_option_ind, :)   =  array2table(elm_option_proportion .* costs_table.(elm_option)(elm_option_ind, :, 1));
            
            % Total costs as annuity
            % !!! Always use year 1 costs, benefits, etc...
            gamma_5 = 0.035 ./ (1 - (1 + 0.035) .^ -(5));
            gamma_50 = 0.035 ./ (1 - (1 + 0.035) .^ -(50));
            switch elm_option
                case {'arable_reversion_sng_access', 'destocking_sng_access', 'arable_reversion_sng_noaccess', 'destocking_sng_noaccess', 'ar_sng_d_sng', 'ar_sng_d_sng_na'}
                    costs_ann_table(elm_option_ind, :) = array2table(elm_option_proportion .* gamma_5 .* costs_table.(elm_option)(elm_option_ind, 4, 1));
                case {'arable_reversion_wood_access', 'destocking_wood_access', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess', 'ar_w_d_w', 'ar_w_d_w_na'}
                    costs_ann_table(elm_option_ind, :) = array2table(elm_option_proportion .* gamma_50 .* costs_table.(elm_option)(elm_option_ind, 4, 1));
                case 'ar_sng_d_w'
                    costs_ann_table(elm_option_ind, :) = array2table(elm_option_proportion .* (gamma_5 .* costs_table.arable_reversion_sng_access(elm_option_ind, 4, 1) + gamma_50 .* costs_table.destocking_wood_access(elm_option_ind, 4, 1)));
                case 'ar_sng_d_w_na'
                    costs_ann_table(elm_option_ind, :) = array2table(elm_option_proportion .* (gamma_5 .* costs_table.arable_reversion_sng_noaccess(elm_option_ind, 4, 1) + gamma_50 .* costs_table.destocking_wood_noaccess(elm_option_ind, 4, 1)));
                case 'ar_w_d_sng'
                    costs_ann_table(elm_option_ind, :) = array2table(elm_option_proportion .* (gamma_5 .* costs_table.arable_reversion_wood_access(elm_option_ind, 4, 1) + gamma_50 .* costs_table.destocking_sng_access(elm_option_ind, 4, 1)));
                case 'ar_w_d_sng_na'
                    costs_ann_table(elm_option_ind, :) = array2table(elm_option_proportion .* (gamma_5 .* costs_table.arable_reversion_wood_noaccess(elm_option_ind, 4, 1) + gamma_50 .* costs_table.destocking_sng_noaccess(elm_option_ind, 4, 1)));
                otherwise
                    error('ELM option not found.')
            end
            
            % Environmental outcomes
            % !!! Always use year 1 costs, benefits, etc...
            env_outcomes_table(elm_option_ind, :) =  array2table(elm_option_proportion .* env_outs.(elm_option)(elm_option_ind, :, 1));

            % Environmental outcome values
            % !!! Always use year 1 costs, benefits, etc...
            es_outcomes_table(elm_option_ind, :) =  array2table(elm_option_proportion .* es_outs.(elm_option)(elm_option_ind, :, 1));

            % Payment to farmer
            switch payment_mechanism_sim
                case 'fr_env'
                    % Multiply environmental outcomes by flat rates and sum
                    payment_to_farmer.payment_to_farmer(elm_option_ind) = table2array(env_outcomes_table(elm_option_ind, :)) * flat_rate';
                case 'fr_es'
                    % Multiply ecosystem services by flat rates and sum
                    payment_to_farmer.payment_to_farmer(elm_option_ind) = table2array(es_outcomes_table(elm_option_ind, :)) * flat_rate';
                case {'oc', 'oc_shared', 'fr_act', 'fr_act_pct', 'fr_act_shared'}
                    % Farm payment for each cell in correct order
                    farm_payment_option_k   = farm_payment(option_choice == k);
                    elm_option_farm_payment = farm_payment_option_k(elm_option_idx);
                    payment_to_farmer.payment_to_farmer(elm_option_ind) = elm_option_farm_payment;
                otherwise
                    error('Payment mechanism not found');
            end
        end
    end

    % Net payment to farmer
    net_payment_to_farmer = array2table(payment_to_farmer.payment_to_farmer - costs_npv_table.cost_total, ...
                                        'VariableNames', {'net_payment_to_farmer'});

    %% (4) Write 2km grid cell data to .csv file
    %  =========================================
    % 2km grid cell ids and coordinates
    coords = array2table([cell_info.new2kid, cell_info.easting, cell_info.northing], ...
                         'VariableNames', {'new2kid', 'x', 'y'});

    % Construct results table
    results = [coords, ...
               year_chosen, ...
               option_choices, ...
               option_hectares, ...
               payment_to_farmer, ...
               net_payment_to_farmer, ...
               benefits_npv_table, ...
               costs_npv_table, ...
               env_outcomes_table, ...
               es_outcomes_table];

    % Change column names to be consistent with Amy
    results.Properties.VariableNames{'year_chosen'} = 'year_selected';
    results.Properties.VariableNames{'option_choices'} = 'option_choice';
    results.Properties.VariableNames{'payment_to_farmer'} = 'payments';
    results.Properties.VariableNames{'benefit_total'} = 'benefits';
    results.Properties.VariableNames{'cost_total'} = 'opp_costs';
    results.bcr = results.benefits ./ results.payments;
    results.bcr(isnan(results.bcr)) = 0;

    % Write results table to .csv file in /Runs folder
    writetable(results, ['Runs/', payment_mechanism_sim, '_', budget_char, '.csv']);

    %% (5) Write aggregated/summarised data to spreadsheet
    %  ===================================================
    % Set up filename and correct sheet for .xls spreadsheet
    filename = 'Results';
    sheet = [payment_mechanism_sim, '_', budget_char];
    
    % (a) Aggregate results by year selected
    % --------------------------------------
    summary_year = table2array(grpstats(results, 'year_selected', 'sum'));
    xlswrite(filename, [summary_year(:, 1:2), summary_year(:, 7:end)], sheet, 'E12');
    
    % (b) Get frequency table of options chosen
    % -----------------------------------------
    summary_option = tabulate(results.option_choice);
    xlswrite(filename, summary_option, sheet, 'A3');
    
    % (c) Write flat rates if appropriate
    % -----------------------------------
    if any(strcmp(payment_mechanism_sim, {'fr_act', 'fr_act_pct', 'fr_act_shared', 'fr_env', 'fr_es'}))
        if strcmp(payment_mechanism_sim, {'fr_env'})
            % Convert units of flooding, N and P prices
            % Flooding: cubic metres per second -> litres per second
            % N & P: milligrams per litre -> micrograms per litre
            flat_rate(6:8) = flat_rate(6:8) / 1000; 
        end
        xlswrite(filename, flat_rate, sheet, 'E3');
    end
    
    % (d) Calculate proportion of agriculture production loss (approximate)
    % --------------------------------------------------------------------
    summary_agloss = (sum(costs_ann_table.cost_total) / 3e+9);
    xlswrite(filename, {'% loss ag production'}, sheet, 'A21');
    xlswrite(filename, summary_agloss, sheet, 'A22');
    
    % (e) Calculate proportion of agricultural area taken (approximate)
    % -----------------------------------------------------------------
    summary_agland = (sum(option_hectares.option_hectares) / 8721600);
    xlswrite(filename, {'% ag area'}, sheet, 'B21');
    xlswrite(filename, summary_agland, sheet, 'B22');
end    
