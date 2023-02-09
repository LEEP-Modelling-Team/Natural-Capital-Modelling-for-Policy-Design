function [options_uptake, best_rate, tot_benefits] = lp_fr_env(elm_options, ...
                                                                     budget, ...
                                                                     markup, ...
                                                                     opp_costs, ...
                                                                     benefits, ...
                                                                     env_outs, ...
                                                                     payment_mechanism, ...
                                                                     unit_value_max, ...
                                                                     warm_start_prices)

    %% 1. INITIALISE
    %  =============
    
    % 1.1. Add the cplex path into matlab
    if ismac
        addpath(genpath('/Applications/CPLEX_Studio1210/cplex/matlab/x86-64_osx'))
    elseif ispc
        addpath(genpath('C:\Program Files\IBM\ILOG\CPLEX_Studio1210\cplex\matlab\x64_win64'))
    end
    
    %% 2. DECISION VARIABLES
    %  =====================
    fprintf('\n  Set data matrices for MIP optimisation \n  -------------------------------------- \n');
    
    % Load data
    % ---------
    num_env_out = 10;
    qe = cat(3, env_outs.arable_reversion_sng_access, env_outs.destocking_sng_access,...
        env_outs.arable_reversion_wood_access, env_outs.destocking_wood_access,...
        env_outs.arable_reversion_sng_noaccess, env_outs.destocking_sng_noaccess,...
        env_outs.arable_reversion_wood_noaccess, env_outs.destocking_wood_noaccess);
 
    b = benefits(:, 1:length(elm_options));
    c = opp_costs(:, 1:length(elm_options));
    q = qe(:, 1:end, 1:length(elm_options));  
    c = c .* markup;
    
    % Restrict price space
    % --------------------
    sample_size = 500;
    num_iters = 10;
    [prices, times, vals] = reduce_lp_price_space(b, c, q, budget, elm_options, payment_mechanism, unit_value_max, sample_size, num_iters);

%     price_table = array2table(prices);
%     
%     if isfile('price_table.csv')
%         all_prices = readtable('price_table.csv');
%         all_prices = [all_prices; price_table];
%     else
%         all_prices = price_table;
%         writetable(all_prices, 'price_table.csv');
%     end
%     
%     price_min = min(table2array(all_prices)) .* 0.8;
%     price_max = max(table2array(all_prices)) .* 1.5;
%     price_max(:, 6) = unit_value_max.flood;
%     price_max(:, 7) = unit_value_max.n;
%     price_max(:, 8) = unit_value_max.p;
%     price_max(:, 10) = unit_value_max.bio;
    
       
    % Reduce size of the problem: search for prices that would exhaust the
    % entire budget for each option
    % --------------------------------------------------------------------    
    fprintf('\n  Calculate maximum rates...\n');
    constraintfunc = @(p) mycon_ES(p, env_outs, c, budget, elm_options);
    max_rates = zeros(1, num_env_out);
    start_rate = 5;
    env_outs_array = struct2array(env_outs);
    for i = 1:num_env_out
        env_outs_array_i = env_outs_array(:, i:num_env_out:(8*num_env_out));
        if sum(sum(env_outs_array_i)) == 0
            % If there are no benefits/quantities across all options then
            % keep max_rate at zero
            continue
        end
        max_rates(i) = fcn_lin_search(num_env_out,i,start_rate,0.01,constraintfunc,env_outs,c,budget,elm_options);
    end
       
    % Set parameters for optimisation
    % -------------------------------
    num_farmers = size(b, 1);
    num_options = size(b, 2);
    bt = b';
    ct = c';

    % set the parameters for the big-M formulation
    % 1) q_ef
    q_ef = max(q, [], 3);

    % 2) R_oe
    c_of = zeros(num_farmers, num_env_out, num_options);
    for i = 1:num_options
        c_of(:,:,i) = repmat(c(:,i), 1, num_env_out);
    end
    R_oe = max(c_of .* ~isinf(c_of ./ q), [], 1);

    % 3) Re
    R_e = max(R_oe, [], 3);

    % 4) Rf
    R_f = sum(q_ef .* R_e, 2);
    
    % 5) S
    S = max(R_f);
    
    % 6) T
    T = 1;

    % Set f, used in optimand
    % -----------------------
    f_p = sparse(num_env_out, 1);
    f_u = sparse(num_farmers, 1);
    f_d = bt(:);
    f = [f_p; f_u; f_d];
    
    % Set variable bounds and types
    % -----------------------------
    lb    = [price_min'; sparse(num_farmers + num_options * num_farmers, 1)];
    ub    = [price_max'; repelem(budget, num_farmers, 1); ones((num_options * num_farmers), 1)]; %
    ctype = [repmat('C',1,(num_env_out + num_farmers)), repmat('I', 1, (num_options * num_farmers))];
        

    %% 3. CONSTRAINTS
    %  ==============
    % 1st inequality (unit demand)
    Aineq1_p = sparse(num_farmers, num_env_out);
    Aineq1_u = sparse(num_farmers, num_farmers);
    Aineq1_d = kron(speye(num_farmers), ones(1, num_options));
    Aineq1 = [Aineq1_p, Aineq1_u, Aineq1_d];
    Bineq1 = ones(num_farmers, 1);
    B1_lb = sparse(num_farmers, 1);
    B1_ub = Bineq1;    
    clear Aineq1_p Aineq1_u Aineq1_d

    % 2nd inequality
    q_perm = permute(q, [3, 2, 1]);
    Aineq2_p = reshape(permute(q_perm, [1, 3, 2]), [], size(q_perm, 2), 1);
    Aineq2_u = -repelem(speye(num_farmers), num_options, 1);
    Aineq2_d = sparse(num_options * num_farmers, num_options * num_farmers);
    Aineq2 = [Aineq2_p, Aineq2_u, Aineq2_d];
    Bineq2 = reshape(c', [num_options*num_farmers, 1]);
    B2_lb = ones(length(Bineq2), 1) * -Inf;
    B2_ub = Bineq2;
    clear Aineq2_p Aineq2_u Aineq2_d

    % 3rd inequality
    q_perm = permute(q, [3, 2, 1]);
    Aineq3_p = -reshape(permute(q_perm, [1, 3, 2]), [], size(q_perm, 2), 1);
    Aineq3_u = repelem(speye(num_farmers), num_options, 1);
    c_rf = num2cell(c,2);
    c_rf = repelem(sparse(blkdiag(c_rf{:})), num_options, 1);
%     Rf_rep = repmat(R_f, 1, num_options)'; 
%     Rf_rep = Rf_rep(:);
    Rf_rep = budget .* 2;
    Aineq3_d = c_rf + (Rf_rep.*speye(num_farmers*num_options));
    Aineq3 = [Aineq3_p, Aineq3_u, Aineq3_d];
    Bineq3 = repelem(Rf_rep, height(Aineq3))';
    B3_lb = ones(length(Bineq3), 1) * -Inf;
    B3_ub = Bineq3;
    clear Aineq3_p Aineq3_u Aineq3_d c_rf

    % 4th inequality
    Aineq4_p = -speye(num_env_out);
    Aineq4_u = sparse(num_env_out, num_farmers);
    Aineq4_d = sparse(num_env_out, num_farmers * num_options);
    Aineq4 = [Aineq4_p, Aineq4_u, Aineq4_d];
    Bineq4 = zeros(num_env_out, 1);
    B4_lb = ones(num_env_out, 1) * -Inf;
    B4_ub = Bineq4;
    clear Aineq4_p Aineq4_u Aineq4_d

    % 5th inequality
    Aineq5_p = sparse(num_farmers, num_env_out);
    Aineq5_u = -speye(num_farmers);
    Aineq5_d = sparse(num_farmers, num_farmers * num_options);
    Aineq5 = [Aineq5_p, Aineq5_u, Aineq5_d];
    Bineq5 = zeros(num_farmers, 1);
    B5_lb = ones(num_farmers, 1) * -Inf;
    B5_ub = Bineq5;
    clear Aineq5_p Aineq5_u Aineq5_d

    % 6th inequality constraint: budget
    Aineq6_p = sparse(1, num_env_out);
    Aineq6_u = ones(1, num_farmers);
    Aineq6_d = ct(:)';
    Aineq6 = [Aineq6_p, Aineq6_u, Aineq6_d];
    Bineq6 = budget;
    B6_lb = 0;
    B6_ub = budget;    
    clear Aineq6_p Aineq6_u Aineq6_d

    % 7th inequality constraint: maximum price
    Aineq7_p = speye(num_env_out);
    Aineq7_u = sparse(num_env_out, num_farmers);
    Aineq7_d = sparse(num_env_out, num_farmers * num_options);
    Aineq7 = [Aineq7_p, Aineq7_u, Aineq7_d];
%     Bineq7 = R_e';
    Bineq7 = max_rates';
    B7_lb = zeros(num_env_out, 1);
    B7_ub = Bineq7;
    clear Aineq7_p Aineq7_u Aineq7_d
    
    % 8th inequality constraint: x = 1 when Uf>0
    Aineq8_p = sparse(num_farmers, num_env_out);
    Aineq8_u = speye(num_farmers);
    Aineq8_d = -kron(speye(num_farmers), ones(1, num_options)) .* S;
    Aineq8 = [Aineq8_p, Aineq8_u, Aineq8_d];
    Bineq8 = zeros(num_farmers, 1);
    B8_lb = ones(num_farmers, 1) * -Inf;
    B8_ub = Bineq8;    
    clear Aineq8_p Aineq8_u Aineq8_d

    % 9th constraint (Utility must be slightly greater than 0 for having an uptake)
    Aineq9_p = sparse(num_farmers, num_env_out);
    Aineq9_u = -speye(num_farmers) .* T;
    Aineq9_d = kron(speye(num_farmers), ones(1, num_options));
    Aineq9 = [Aineq9_p, Aineq9_u, Aineq9_d];
    Bineq9 = zeros(num_farmers, 1);
    B9_lb = ones(num_farmers, 1) * -Inf;
    B9_ub = Bineq9;    
    clear Aineq9_p Aineq9_u Aineq9_d    
   
    % Combine all inequalities into one matrix
    A = [Aineq1; Aineq2; Aineq3; Aineq4; Aineq5; Aineq6; Aineq7; Aineq8; Aineq9];
    B = [Bineq1; Bineq2; Bineq3; Bineq4; Bineq5; Bineq6; Bineq7; Bineq8; Bineq9];
    B_lb = [B1_lb; B2_lb; B3_lb; B4_lb; B5_lb; B6_lb; B7_lb; B8_lb; B9_lb];
    B_ub = [B1_ub; B2_ub; B3_ub; B4_ub; B5_ub; B6_ub; B7_ub; B8_ub; B9_ub];
    
    %% 4. WARMSTART
    %  ============
    small_price = table2array(all_prices);
    small_price = small_price(1, :);
    [uptake_logic, option_idx] = fcn_get_farmer_uptake_logic_fr_env_es(small_price, env_outs, c, elm_options);
    any_option_ind = any(uptake_logic, 2);
    
    uptake_vector = reshape(uptake_logic', 1, (height(uptake_logic).*width(uptake_logic)));
%     benefitfunc = @(p) myfun_ES(p, env_outs, c, b, elm_options);
    profit = zeros(num_farmers, num_options+1);
    for i = 1:length(elm_options)
        profit(:, i+1) = small_price * env_outs.(elm_options{i})' - c(:, i)';
    end
    [profit, Aind] = max(profit, [], 2);
    f_search = [small_price, profit', uptake_vector]; 

    % Write warmstart file
    % --------------------
    warmstart_prices = table2array(all_prices);
    sln = warmstart_prices;
    idx = 0:num_env_out-1;
%     sln = f_search;
%     idx = 0:length(f_search)-1;
    filename = 'warmstart.mst';
    probname = 'elms_lp';
    fcn_write_warmstart(sln', idx', filename, probname);
    
    
    %% 5. RUN OPTIMISATION
    % ====================
    
    % Set cplex object
    % ----------------
    cplex = Cplex('elms_lp');
    cplex.Model.sense = 'maximize';
    cplex.Param.emphasis.mip.Cur = 0;
    cplex.Param.mip.strategy.search.Cur = 2;
    cplex.Param.parallel.Cur = 1;
    cplex.Param.timelimit.Cur = 400;
    
    % Add problem formulation to cplex object
    % ---------------------------------------
    cplex.addCols(f, [], lb, ub, ctype);
    cplex.addRows(B_lb, A, B_ub);
    cplex.readMipStart('warmstart.mst');
    
    % Solve optimisation
    % ------------------
    tic
    cplex.solve();
    toc
    
    %% 6. OUTPUT
    %  =========
    x = cplex.Solution.x;
    fval = cplex.Solution.objval;
    
    u = x(num_env_out + 1:num_env_out + num_farmers);
    
    % extract option_uptake matrix
    options_uptake = round(reshape(x((num_env_out + num_farmers + 1):end), num_options, num_farmers)');
    
    % extract option IDs for farmers taking any options

    % Extract total benefits from optimization
    tot_benefits = -fval;
    
    % best rates
    best_rate = x(1:num_env_out);  
    
end



    