function [b,c,q,budget,available_elm_options,unit_value_max] = load_data(sample_num, unscaled_budget, data_path, remove_nu_habitat)
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

    % Load ELM option results from .mat file
    % --------------------------------------
    % Generated in script2_run_elm_options.m
    % Depends on carbon price
    load(data_path);

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
    if isnumeric(sample_num)
        farmer_perm = randperm(cell_info.ncells);
        farmer_sample_ind = (farmer_perm <= sample_num)';
        budget = unscaled_budget ./ cell_info.ncells .* sample_num;
    elseif strcmp(sample_num, 'no')
        farmer_perm = randperm(cell_info.ncells);
        farmer_sample_ind = (farmer_perm <= cell_info.ncells)';
        budget = unscaled_budget;
    else
        fprintf('''sample_num'' can only assume a numeric value or ''no'' if no sampling is required\n'); 
    end

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

    %% (2) Run optimisation test
    %  =========================
    % (a) Set up variables for loop
    % -----------------------------
    % Number of available ELMs options
    % (available_elm_options is set in previous script)
    num_elm_options = length(available_elm_options);

    benefits_year            = nan(cell_info.ncells, num_elm_options);
    costs_year               = nan(cell_info.ncells, num_elm_options);
    for k = 1:num_elm_options
        benefits_year(:, k) = benefits.(available_elm_options{k})(:, 1);
        costs_year(:, k)    = costs.(available_elm_options{k})(:, 1);
        env_outs_year.(available_elm_options{k}) = env_outs.(available_elm_options{k})(:, :, 1);
        es_outs_year.(available_elm_options{k})  = es_outs.(available_elm_options{k})(:, :, 1);
    end

    % Use farmer_sample_ind to select farmers to include in price search
    % ------------------------------------------------------------------    
    % Extract relevant rows from above arrays/structures
    b = round(benefits_year(farmer_sample_ind, :), 8);
    c = round(costs_year(farmer_sample_ind, :), 8);
    for k = 1:num_elm_options
        env_outs.(available_elm_options{k}) = round(env_outs_year.(available_elm_options{k})(farmer_sample_ind, :), 8);
        es_outs.(available_elm_options{k}) = round(es_outs_year.(available_elm_options{k})(farmer_sample_ind, :), 8);
    end

    q = cat(3, env_outs.arable_reversion_sng_access, env_outs.destocking_sng_access,...
        env_outs.arable_reversion_wood_access, env_outs.destocking_wood_access,...
        env_outs.arable_reversion_sng_noaccess, env_outs.destocking_sng_noaccess,...
        env_outs.arable_reversion_wood_noaccess, env_outs.destocking_wood_noaccess);
    c = c .* markup;
    
end