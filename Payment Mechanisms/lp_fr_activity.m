function [options_uptake, option_choice, best_rate, farm_payment, tot_benefits] = lp_fr_activity(elm_options, ...
                                                                                        budget, ...
                                                                                        markup, ...
                                                                                        opp_costs, ...
                                                                                        benefits, ...
                                                                                        elm_ha, ...
                                                                                        cell_ids)

    %% 1. INITIALISE
    %  =============
    
    % 1.1. Add the cplex path into matlab
    if ismac
        addpath(genpath('/Applications/CPLEX_Studio1210/cplex/matlab/x86-64_osx'))
    elseif ispc
        addpath(genpath('C:\Program Files\IBM\ILOG\CPLEX_Studio1210\cplex\matlab\x64_win64'))
    end
      
    % 1.2. CLPEX optimisation object
    % ------------------------------
    cplex = Cplex('elms_lp');
    cplex.Model.sense = 'minimize';
    cplex.Param.emphasis.mip.Cur = 0;
    cplex.Param.mip.strategy.search.Cur = 2;
    cplex.Param.parallel.Cur = 1;
%     cplex.Param.mip.tolerances.integrality.Cur = 0;
%     cplex.Param.mip.tolerances.mipgap.Cur = 0;
%     cplex.Param.conflict.algorithm.Cur = 6;
%     cplex.Param.conflict.display.Cur = 2;
%     cplex.Param.mip.tolerances.absmipgap.Cur = 0;
%     cplex.DisplayFunc = '';
    
    %% 2. DECISION VARIABLES
    %  =====================
    fprintf('\n  Set data matrices for MIP optimisation \n  -------------------------------------- \n');
    b = benefits(:, 1:length(elm_options));
    c = opp_costs(:, 1:length(elm_options));
    q = elm_ha(:, 1:length(elm_options));
    c = markup * c; % add 15% markup
    
    % Reduce size of the problem: search for prices that would exhaust the
    % entire budget for each option, calculate uptake and remove subset of
    % cells that are never selected under any option when the budget is
    % exhausted
    fprintf('\n  Reducing problem size...\n');
    max_rates1      = zeros(1, length(elm_options));
    excluded_cells1 = ones(size(c,1),1);
    for i = 1:length(elm_options)
        [price_pts, sortidx] = sort(c(:,i)./q(:,i));
        ind_over_budget = (cumsum(q(sortidx,i)) .* price_pts) >= budget;
        excluded_cells1 = excluded_cells1 .* ind_over_budget(sortidx);
        max_rates1(i) = price_pts(find(ind_over_budget, 1)-1);
    end
    
    [max_rates, ids_to_remove] = fcn_find_max_prices(c, q, cell_ids, budget, 'fr_act');    
    [~, excluded_cells , ~] = intersect(cell_ids, ids_to_remove);
    
    fprintf('  Removed %u rows\n  ------------------------ \n', sum(excluded_cells));
    excluded_cells = logical(excluded_cells);
    b(excluded_cells, :) = [];
    c(excluded_cells, :) = [];
    q(excluded_cells, :) = [];
    cell_ids(excluded_cells, :) = [];

    % Calculate parameters based on the size of the matrix
    num_farmers = size(b, 1);
    num_options = size(b, 2);
    num_x = num_options + num_farmers + num_options * num_farmers;
    
    % Store transposed matrices
    bt = b';
    ct = c';
    qt = q';

    % set the parameters for the big-M formulation
    qf = max(q, [], 2);
    C_ha = (c ./ q);
    Ro = sparse(1, num_options);
    for col = 1: num_options
        C_col = C_ha(:,col);
        Ro(col) = max(C_col(~isinf(C_col)));
    end
    R = max(Ro(~isinf(Ro)));
    Rf = R * qf;
    S = max(Rf);
    T = 1;

    % Set f, used in optimand
    f_p = sparse(num_options, 1);
    f_u = sparse(num_farmers, 1);
    f_d = -bt(:);
    f = [f_p; f_u; f_d];
    
    % Set variable bounds and types
    lb    = sparse(num_options + num_farmers + num_options * num_farmers, 1);
    ub    = [inf((num_options + num_farmers), 1); ones((num_options * num_farmers), 1)]; %
    ctype = [repmat('C',1,(num_options + num_farmers)), repmat('I', 1, (num_options * num_farmers))];
    
    % Add to cplex class
    cplex.addCols(f, [], lb, ub, ctype);

    %% 3. CONSTRAINTS
    %  ==============
    % 1st inequality (unit demand)
    Aineq1_p = sparse(num_farmers, num_options);
    Aineq1_u = sparse(num_farmers, num_farmers);
    Aineq1_d = kron(speye(num_farmers), ones(1, num_options));
    Aineq1 = [Aineq1_p, Aineq1_u, Aineq1_d];

    Bineq1 = ones(num_farmers, 1);
    B1_lb = zeros(num_farmers, 1);
    B1_ub = Bineq1;
    
    clear Aineq1_p Aineq1_u Aineq1_d

    % 2nd inequality
    Aineq2_p = [];
    for i = 1:num_farmers
        Aineq2_p = [Aineq2_p; spdiags(q(i, :)', 0, num_options, num_options)];
    end
    Aineq2_u = -repelem(speye(num_farmers), num_options, 1);
    Aineq2_d = sparse(num_options * num_farmers,num_options * num_farmers);
    Aineq2 = [Aineq2_p, Aineq2_u, Aineq2_d];

    Bineq2 = reshape(c', [num_options*num_farmers, 1]);
    B2_lb = ones(length(Bineq2), 1) * -Inf;
    B2_ub = Bineq2;

    clear Aineq2_p Aineq2_u Aineq2_d

    % 3rd inequality
    Aineq3_p = [];
    for i = 1:num_farmers
        Aineq3_p = [Aineq3_p; -spdiags(q(i,:)', 0, num_options, num_options)];
    end
    Aineq3_u = repelem(speye(num_farmers), num_options, 1);

    eye_temp = speye(num_farmers);
    Aineq3_d = [];
    for i = 1:num_farmers
        Aineq3_d = [Aineq3_d, kron(c(i, :), eye_temp(i, :)')];
    end
    Aineq3_d = repelem(Aineq3_d, num_options, 1);

    Rf_rep = repmat(Rf, 1, num_options)';
    Rf_rep = Rf_rep(:);
    Aineq3_d = Aineq3_d + (Rf_rep.*speye(num_farmers*num_options));
    Aineq3 = [Aineq3_p, Aineq3_u, Aineq3_d];

    Bineq3 = Rf_rep;
    B3_lb = ones(length(Bineq3), 1) * -Inf;
    B3_ub = Bineq3;

    clear Aineq3_p Aineq3_u Aineq3_d

    % 4th inequality
    Aineq4_p = -speye(num_options);
    Aineq4_u = sparse(num_options, num_farmers);
    Aineq4_d = sparse(num_options, num_farmers * num_options);
    Aineq4 = [Aineq4_p, Aineq4_u, Aineq4_d];

    Bineq4 = sparse(num_options, 1);
    B4_lb = ones(num_options, 1) * -Inf;
    B4_ub = Bineq4;

    clear Aineq4_p Aineq4_u Aineq4_d

    % 5th inequality
    Aineq5_p = sparse(num_farmers, num_options);
    Aineq5_u = -speye(num_farmers);
    Aineq5_d = sparse(num_farmers, num_farmers * num_options);
    Aineq5 = [Aineq5_p, Aineq5_u, Aineq5_d];

    Bineq5 = sparse(num_farmers, 1);
    B5_lb = ones(num_farmers, 1) * -Inf;
    B5_ub = Bineq5;

    clear Aineq5_p Aineq5_u Aineq5_d

    % 6th inequality constraint: budget
    Aineq6_p = sparse(1, num_options);
    Aineq6_u = ones(1, num_farmers);
    Aineq6_d = ct(:)';
    Aineq6 = [Aineq6_p, Aineq6_u, Aineq6_d];

    Bineq6 = budget;
    B6_lb = 0;
    B6_ub = budget;
    
    clear Aineq6_p Aineq6_u Aineq6_d

    % 7th inequality constraint: maximum price
    Aineq7_p = speye(num_options);
    Aineq7_u = sparse(num_options, num_farmers);
    Aineq7_d = sparse(num_options, num_farmers * num_options);
    Aineq7 = [Aineq7_p, Aineq7_u, Aineq7_d];

%   Bineq7 = Ro';
    Bineq7 = max_rates';
    B7_lb = zeros(num_options, 1);
    B7_ub = Bineq7;

    clear Aineq7_p Aineq7_u Aineq7_d
    
    % 8th inequality constraint: x = 1 when Uf>0
    Aineq8_p = zeros(num_farmers, num_options);
    Aineq8_u = speye(num_farmers);
    Aineq8_d = -kron(speye(num_farmers), ones(1, num_options)) .* S;
    Aineq8 = [Aineq8_p, Aineq8_u, Aineq8_d];

    Bineq8 = zeros(num_farmers, 1);
    B8_lb = ones(num_farmers, 1) * -Inf;
    B8_ub = Bineq8;
    
    clear Aineq8_p Aineq8_u Aineq8_d

    % 9th constraint (Utility must be slightly greater than 0 for having an uptake)
    Aineq9_p = zeros(num_farmers, num_options);
    Aineq9_u = -speye(num_farmers) .* T;
    Aineq9_d = kron(speye(num_farmers), ones(1, num_options));
    Aineq9 = [Aineq9_p, Aineq9_u, Aineq9_d];

    Bineq9 = zeros(num_farmers, 1);
    B9_lb = ones(num_farmers, 1) * -Inf;
    B9_ub = Bineq9;
    
    clear Aineq9_p Aineq9_u Aineq9_d
    
    % 10th inequality constraint: p_o=0 when sum over f(x_of)=0
    Aineq10_p = speye(num_options);
    Aineq10_u = zeros(num_options, num_farmers);
    Aineq10_d = -kron(ones(1, num_farmers), eye(num_options)) .* S;
    Aineq10 = [Aineq10_p, Aineq10_u, Aineq10_d];

    Bineq10 = zeros(num_options, 1);
    B10_lb = ones(num_options, 1) * -Inf;
    B10_ub = Bineq10;
    
    clear Aineq10_p Aineq10_u Aineq10_d
    
    % Combine all inequalities into one matrix
    A = [Aineq1; Aineq2; Aineq3; Aineq4; Aineq5; Aineq6; Aineq7; Aineq8; Aineq9; Aineq10];
    B = [Bineq1; Bineq2; Bineq3; Bineq4; Bineq5; Bineq6; Bineq7; Bineq8; Bineq9; Bineq10];
    B_lb = [B1_lb; B2_lb; B3_lb; B4_lb; B5_lb; B6_lb; B7_lb; B8_lb; B9_lb; B10_lb];
    B_ub = [B1_ub; B2_ub; B3_ub; B4_ub; B5_ub; B6_ub; B7_ub; B8_ub; B9_ub; B10_ub];
    
%     options = cplexoptimset;
%     options.Display = 'on';
%     [x, fval, exitflag, output] = cplexmilp (f, A, B, [], [],...
%       [], [], [], lb, ub, ctype, [], options);
    % Add to cplex class
    cplex.addRows(B_lb, A, B_ub);
    
    %% 4. WARMSTART
    %  ============
%     sln = [0,1537.69285758507,16005.2944927036,0,0,795.968794355287,0,8488.68973915132];
%     idx = [0, 1, 2, 3, 4, 5, 6, 7];
%     filename = 'warmstart.mst';
%     probname = 'elms_lp';
%     
%     fcn_write_warmstart(sln, idx, filename, probname)
%     cplex.readMipStart('warmstart.xml');
    
    
    %% 5. SOLVE
    %  ========
    tic
    cplex.solve();
    toc
    
    %% 6. OUTPUT
    %  =========
    x = cplex.Solution.x;
    fval = cplex.Solution.objval;
    
    % extract option_uptake matrix
    options_uptake = round(reshape(x((num_options + num_farmers + 1):end), num_options, num_farmers)');
    
    % extract option IDs for farmers taking any options
    option_choice = zeros(1, num_farmers);
    for i = 1:num_farmers
        if sum(options_uptake(i, :), 2) == 0
            option_choice(i) = 0;
        else
            [~, col] = find(options_uptake(i, :));
            option_choice(i) = col;
        end
    end
    
    option_choice = option_choice';
    
    % Extract flat rates
    best_rate = x(1:num_options)';
    
    % Calculate farm payments
    farm_payment = sum(options_uptake .* q .* best_rate, 2);

    % Extract total benefits from optimization
    tot_benefits = -fval;
end



    