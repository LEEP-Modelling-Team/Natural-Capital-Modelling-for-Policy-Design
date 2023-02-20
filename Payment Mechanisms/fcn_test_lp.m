


function [prices, fval, x] =  MILP_output_prices(eq10, b, c, q, budget, elm_options, max_rates, warm_start_prices, warm_start_uptake, price_lb, price_ub, cplex_time)
    
    % 1. Initialise
    % =============
    
    % 1.1 Cplex Object
    % ----------------
    if ismac
        addpath(genpath('/Applications/CPLEX_Studio1210/cplex/matlab/x86-64_osx'))
    elseif ispc
        addpath(genpath('C:\Program Files\IBM\ILOG\CPLEX_Studio1210\cplex\matlab\x64_win64'))
    end
    
    cplex = Cplex('elms_lp');
    cplex.Model.sense = 'maximize';
    cplex.Param.emphasis.mip.Cur = 0; % balanced
	% cplex.Param.emphasis.mip.Cur = 1; % emphasise feasibility
    cplex.Param.mip.strategy.search.Cur = 2;
    cplex.Param.parallel.Cur = 1;
    cplex.Param.timelimit.Cur = cplex_time;
    cplex.Param.mip.tolerances.integrality.Cur = 0;
    cplex.Param.mip.tolerances.mipgap.Cur = 0;
    
    
    % 1.2 Constants
    % -------------
    num_farmers = size(b, 1);
    num_options = size(b, 2);
    num_env_out = size(q, 2);
    
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
    
    
    % 2. Choice Variables
    % ===================
    %
    %    Prices     Farm Utility       Activity Choice
    %   --------   --------------   ---------------------  
    %                                Farm1   ...  FarmN 
    % [1 x Nprice]    [1 x N]      [1 x Nopt]   [1 x Nopt]
    %    >0              >0           0-1          0-1 
    
    
    % 3. Bounds for Choice Variables
    % ==============================
    lb    = [price_lb; sparse(num_farmers + num_options * num_farmers, 1)];
    ub    = [price_ub; repelem(budget, num_farmers, 1); ones((num_options * num_farmers), 1)];     

    
    % 4. Cost vector
    % ==============    
    % Set f, used in optimand
    c_p = sparse(num_env_out, 1);
    c_u = sparse(num_farmers, 1);
    c_x = bt(:);
    c = [c_p; c_u; c_x];
    clear c_p c_u c_x

    
    % 5. Variable types
    % =================
    ctype = [repmat('C',1,(num_env_out + num_farmers)), repmat('B', 1, (num_options * num_farmers))];

    
    cplex.addCols(c, [], lb, ub, ctype);  
    
    clear c lb ub ctype
    
    
    % 6. Inequality Constraints
    % =========================

    % 6.1 Unit Demand
    % ---------------
    %  Farm can select at most one of the options.
    %
    %     sum_f(x_of) <= 1   (f = 1...N)      (Eq 11)
    %    
    A_p = sparse(num_farmers, num_env_out);
    A_u = sparse(num_farmers, num_farmers);
    A_x = kron(speye(num_farmers), ones(1, num_options));
    A   = [A_p, A_u, A_x];
    Bl  = sparse(num_farmers,1);
    Bu  = zeros(num_farmers,1);
    if ~isempty(A),cplex.addRows(Bl, A, Bu); end
    clear A Bl Bu

    % 6.2 Utility Maximisation: Lower Bound
    % -------------------------------------
    %  Farm utility must be greater than utility of option offering the 
    %  most profit at current prices
    %
    %    u_f >= sum_e(p_e.q_eof) - c_of) (f = 1...N; o = 1...No)   (Eq 12)
    %    
    q_perm = permute(q, [3, 2, 1]);
    A_p = reshape(permute(q_perm, [1, 3, 2]), [], size(q_perm, 2), 1);
    A_u = -repelem(speye(num_farmers), num_options, 1);
    A_d = sparse(num_options * num_farmers, num_options * num_farmers);
    A = [A_p, A_u, A_d];
    Bl = ones(length(B), 1) * -Inf;
    Bu = reshape(c', [num_options*num_farmers, 1]);
    clear Aineq2_p Aineq2_u Aineq2_d
    
    % 3rd inequality
    q_perm = permute(q, [3, 2, 1]);
    Aineq3_p = -reshape(permute(q_perm, [1, 3, 2]), [], size(q_perm, 2), 1);
    Aineq3_u = repelem(speye(num_farmers), num_options, 1);
    c_rf = num2cell(c,2);
    c_rf = repelem(sparse(blkdiag(c_rf{:})), num_options, 1);
%     Rf_rep = repmat(R_f, 1, num_options)'; 
%     Rf_rep = Rf_rep(:);
    Rf_rep = budget .* 3;
    Aineq3_d = c_rf + (Rf_rep.*speye(num_farmers*num_options));
    Aineq3 = [Aineq3_p, Aineq3_u, Aineq3_d];
    Bineq3 = repelem(Rf_rep, size(Aineq3,1))';
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
            A = [A; Aineq2; Aineq3; Aineq4; Aineq5; Aineq6; Aineq7; Aineq8; Aineq9; Aineq10];
            B = [Bineq1; Bineq2; Bineq3; Bineq4; Bineq5; Bineq6; Bineq7; Bineq8; Bineq9; Bineq10];
            B_lb = [B1_lb; B2_lb; B3_lb; B4_lb; B5_lb; B6_lb; B7_lb; B8_lb; B9_lb; B10_lb];
            B_ub = [B1_ub; B2_ub; B3_ub; B4_ub; B5_ub; B6_ub; B7_ub; B8_ub; B9_ub; B10_ub];
        case 'no'
            A = [A; Aineq2; Aineq3; Aineq4; Aineq5; Aineq6; Aineq7; Aineq8; Aineq9];
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
    
    sln = [warm_start_prices warm_start_uptake];
    idx = [1:num_env_out num_env_out+num_farmers+1:num_env_out+num_farmers+num_options*num_farmers];
    idx = idx - 1;            
    filename = 'warmstart.mst';
    probname = 'elms_lp';
    fcn_write_warmstart(sln', idx', filename, probname);

    % Set cplex object
    % ----------------


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
