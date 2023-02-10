function [prices, fval, x] =  fcn_test_lp(eq10, b, c, q, budget, elm_options, payment_mechanism, unit_value_max)
    
    %% 1. INITIALISE
    %  =============
    
    % 1.1. Add the cplex path into matlab
    if ismac
        addpath(genpath('/Applications/CPLEX_Studio1210/cplex/matlab/x86-64_osx'))
    elseif ispc
        addpath(genpath('C:\Program Files\IBM\ILOG\CPLEX_Studio1210\cplex\matlab\x64_win64'))
    end
    
    % Calculate parameters based on the size of the matrix
    num_farmers = size(b, 1);
    num_options = size(b, 2);
    num_env_out = width(q);

    % Set max rates with a linear search
    constraintfunc = @(p) mycon_ES(p, q, c, budget, elm_options);
    max_rates = zeros(1, num_env_out);
    start_rate = 5;
    for i = 1:num_env_out
        env_outs_array_i = squeeze(q(:, i, :));
        if sum(sum(env_outs_array_i)) == 0
            % If there are no benefits/quantities across all options then
            % keep max_rate at zero
            continue
        end
        max_rates(i) = fcn_lin_search(num_env_out,i,start_rate,0.01,constraintfunc,q,c,budget,elm_options);
    end
%     max_rates(1) = min(max_rates(1), unit_value_max.ghg);    % GHG
%     % 2:5 the 4 rec hectares are constrained by budget only
%     max_rates(6) = min(max_rates(6), unit_value_max.flood);  % flood
%     max_rates(7) = min(max_rates(7), unit_value_max.n);      % nitrate
%     max_rates(8) = min(max_rates(8), unit_value_max.p);      % phosphate
    max_rates(10) = min(max_rates(10), unit_value_max.bio);    % biodiversity

    % Store transposed matrices
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
    S = budget;

    % 6) T
    T = 1;

    % 7) M
    M = budget.*10;

    % Set f, used in optimand
    f_p = sparse(num_env_out, 1);
    f_u = sparse(num_farmers, 1);
    f_d = bt(:);
    f = [f_p; f_u; f_d];

    % Set lower and upper variable bounds
    % -----------------------------------
    lb    = sparse(num_env_out + num_farmers + num_options * num_farmers, 1);
    ub    = [max_rates'; repelem(budget, num_farmers, 1); ones((num_options * num_farmers), 1)]; %
    ctype = [repmat('C',1,(num_env_out + num_farmers)), repmat('I', 1, (num_options * num_farmers))];

    % Set Inequality constraints
    % --------------------------

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
    Rf_rep = budget;
%     Rf_rep = repelem(R_f, num_options);
    Aineq3_d = c_rf + (Rf_rep.*speye(num_farmers*num_options));
    Aineq3 = [Aineq3_p, Aineq3_u, Aineq3_d];
    Bineq3 = repelem(Rf_rep, height(Aineq3))';
%     Bineq3 = Rf_rep;
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

    % 10th constraint (Utility must be slightly greater than 0 for having an uptake)
    q_perm = permute(q, [3, 2, 1]);
    Aineq10_p = -reshape(permute(q_perm, [1, 3, 2]), [], size(q_perm, 2), 1);
    Aineq10_u = sparse(num_farmers .* num_options, num_farmers);
    Aineq10_d = M .* speye(num_options * num_farmers);
    Aineq10 = [Aineq10_p, Aineq10_u, Aineq10_d];
    Bineq10 = M - reshape(c', [num_options*num_farmers, 1]);
    B10_lb = ones(length(Bineq10), 1) * -Inf;
    B10_ub = Bineq10;
    clear Aineq10_p Aineq10_u Aineq10_d
   
    
    % Combine all inequalities into one matrix
    switch eq10
        case 'yes'
            A = [Aineq1; Aineq2; Aineq3; Aineq4; Aineq5; Aineq6; Aineq7; Aineq8; Aineq9; Aineq10];
            B = [Bineq1; Bineq2; Bineq3; Bineq4; Bineq5; Bineq6; Bineq7; Bineq8; Bineq9; Bineq10];
            B_lb = [B1_lb; B2_lb; B3_lb; B4_lb; B5_lb; B6_lb; B7_lb; B8_lb; B9_lb; B10_lb];
            B_ub = [B1_ub; B2_ub; B3_ub; B4_ub; B5_ub; B6_ub; B7_ub; B8_ub; B9_ub; B10_ub];
        case 'no'
            A = [Aineq1; Aineq2; Aineq3; Aineq4; Aineq5; Aineq6; Aineq7; Aineq8; Aineq9];
            B = [Bineq1; Bineq2; Bineq3; Bineq4; Bineq5; Bineq6; Bineq7; Bineq8; Bineq9];
            B_lb = [B1_lb; B2_lb; B3_lb; B4_lb; B5_lb; B6_lb; B7_lb; B8_lb; B9_lb];
            B_ub = [B1_ub; B2_ub; B3_ub; B4_ub; B5_ub; B6_ub; B7_ub; B8_ub; B9_ub];
    end
    

    clear Aineq1 Aineq2 Aineq3 Aineq4 Aineq5 Aineq6 Aineq7 Aineq8 Aineq9 Aineq10
    clear Bineq1 Bineq2 Bineq3 Bineq4 Bineq5 Bineq6 Bineq7 Bineq8 Bineq9 Bineq10
    clear B1_lb B2_lb B3_lb B4_lb B5_lb B6_lb B7_lb B8_lb B9_lb B10_lb
    clear B1_ub B2_ub B3_ub B4_ub B5_ub B6_ub B7_ub B8_ub B9_ub B10_ub

    % Warm start
    % ----------
%     best_rate = fcn_find_warm_start(payment_mechanism, ...
%                                         budget, ...
%                                         elm_options, ...
%                                         c, ... 
%                                         b, ...
%                                         q, ...
%                                         unit_value_max, ...
%                                         max_rates);
                                    
    best_rate = [30.6970625777363,29.4899684479249,231.364268148029,275.807608315046,3.40758067433056,6259689.44011931,1203763.01693944,3090373.93449751,129.259940837273,-0.00124772747139409];
    sln = best_rate;
    idx = 0:length(best_rate)-1;
    filename = 'warmstart.mst';
    probname = 'elms_lp';
    fcn_write_warmstart(sln', idx', filename, probname);

    % Set cplex object
    % ----------------
    cplex = Cplex('elms_lp');
    cplex.Model.sense = 'maximize';
    cplex.Param.emphasis.mip.Cur = 0; % balanced
%         cplex.Param.emphasis.mip.Cur = 1; % emphasise feasibility
    cplex.Param.mip.strategy.search.Cur = 2;
    cplex.Param.parallel.Cur = 1;
    cplex.Param.timelimit.Cur = 300;

    cplex.addCols(f, [], lb, ub, ctype);
    cplex.addRows(B_lb, A, B_ub);
    cplex.readMipStart('warmstart.mst');

    % Solve
    % -----
    tic
    cplex.solve();
    toc

    % Retrieve prices
    % ---------------
    prices = cplex.Solution.x(1:num_env_out)';
    fval = cplex.Solution.objval;
    x = cplex.Solution.x;

    clear cplex
    clear A B B_lb B_ub f
end
