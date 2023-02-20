% MILP_output_prices
% ==================

%  Purpose
%  -------
%  Maximises benefits suject to a budget constraint, by offering flat rate 
%  prices to farmers for eachoutcome arising from farmer choice over a set 
%  of possible farm land use change options.

%  Inputs
%  ------
%    b     [N x Np]  



function [x, prices, fval, exitflag, exitmsg] =  MILP_output_prices(b, c, q, budget, warm_start_prices, warm_start_uptake, price_lb, price_ub, cplex_time)
    
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
    %      >0            >0           0-1          0-1 
    
    
    % 3. Bounds for Choice Variables
    % ==============================
    lb    = [price_lb; sparse(num_farmers + num_options * num_farmers, 1)];
    ub    = [price_ub; repelem(budget, num_farmers, 1); ones((num_options * num_farmers), 1)];     

    
    % 4. Cost vector
    % ==============    
    f_p = sparse(num_env_out, 1);
    f_u = sparse(num_farmers, 1);
    f_x = bt(:);
    f = [f_p; f_u; f_x];
    clear f_p f_u f_x

    
    % 5. Variable types
    % =================
    ctype = [repmat('C',1,(num_env_out + num_farmers)), repmat('B', 1, (num_options * num_farmers))];

    
    cplex.addCols(f, [], lb, ub, ctype);  
    
    clear f lb ub ctype
    
    
    % 6. Inequality Constraints
    % =========================

    % 6.1 Unit Demand
    % ---------------
    %  Farm can select at most one of the options.
    %
    %     sum_f(x_of) <= 1   (f = 1...N)      (Eq 12)
    %    
    A_p = sparse(num_farmers, num_env_out);
    A_u = sparse(num_farmers, num_farmers);
    A_x = repelem(speye(num_farmers), 1, num_options);
    A   = [A_p, A_u, A_x];
    Bl  = sparse(num_farmers,1);
    Bu  = ones(num_farmers,1);
    if ~isempty(A),cplex.addRows(Bl, A, Bu); end
    clear A A_p A_x Bl Bu

    % 6.2 Utility Maximisation: Lower Bound
    % -------------------------------------
    %  Farm utility must be >= utility of option offering the most profit
    %  at current prices
    %
    %    u_f >= sum_e(p_e.q_eof) - c_of) (f = 1...N; o = 1...No)   (Eq 13)
    %    
    A_p = permute(q, [3, 2, 1]);
    A_p = reshape(permute(A_p, [1, 3, 2]), [num_farmers*num_options num_env_out]);   
    A_u = -repelem(speye(num_farmers), num_options, 1);
    A_x = sparse(num_farmers*num_options, num_farmers*num_options);
    A   = [A_p, A_u, A_x];
    Bl  = ones(num_farmers*num_options, 1) * -Inf;
    Bu  = ct(:);
    if ~isempty(A),cplex.addRows(Bl, A, Bu); end
    clear A A_u A_x Bl Bu    
    
    
    % 6.3 Utility Maximisation: Upper Bound
    % -------------------------------------
    %  Farm utility <= utility of option chosen by farmer, tying the choice
    %  of option to utility maximising choice from (Eq 12).
    %
    %    u_f <= sum_e(p_e.q_eof) - sum_oo(c_oof.x_oof) + (1 - x_of)R  (f = 1...N; o = 1...No)   (Eq 14)
    %   
    %  Here R is a constant that is sufficiently high to ensure that if
    %  option o is not chosen (x_of = 0) that the rhs holds trivially. Only
    %  when the option is chosen (x_of = 1) will this upper bound be placed
    %  on farmer utility. The only way the optimiser can get (6.2) and
    %  (6.3) to hold simultaneously is if the chosen option is also the one
    %  that gives the highest utility of all options. Alternatively, if all
    %  options give negative utility then u_f = 0 on account of positivity
    %  constraint, in which case all x_of must be zero and no option is
    %  chosen.    
    R   = budget .* 1.01;
    A_p = -A_p;   
    A_u = repelem(speye(num_farmers), num_options, 1);
    A_x = num2cell(c,2);
    A_x = repelem(sparse(blkdiag(A_x{:})), num_options, 1);
    A_x = A_x + R*speye(num_farmers*num_options);
    A   = [A_p, A_u, A_x];
    B   = ones(num_farmers*num_options, 1);
    Bl  = B * -Inf;
    Bu  = B * R;
    if ~isempty(A),cplex.addRows(Bl, A, Bu); end    
    clear A_p A_u A_x c_rf A B Bl Bu   

    
    % 6.4 Budget Constraint
    % ---------------------
    %  Amount paid to farmers cannot exceed budget.
    %
    %    sum_f(u_f) + sum_f(sum_o(c_of.x_of)) <= M   (Eq 17)
    %   
    A_p = sparse(1, num_env_out);
    A_u = ones(1, num_farmers);
    A_x = ct(:)';
    A   = [A_p, A_u, A_x];
    Bl  = 0;
    Bu  = budget;
    if ~isempty(A),cplex.addRows(Bl, A, Bu); end        
    clear A_p A_u A_x A Bl Bu  

    
    % 6.4 Additional Cuts
    % -------------------
    %  Surplus must be zero if no option chosen
    %
    %    u_f <= S * sum_o(x_of)   (f = 1...N)   (Eq 16)
    %   
    S   = budget * 1.01;
    A_p = sparse(num_farmers, num_env_out);
    A_u = speye(num_farmers);
    A_x = -repelem(speye(num_farmers), 1, num_options) * S;
    A   = [A_p, A_u, A_x];
    Bl  = ones(num_farmers, 1) * -Inf;
    Bu  = zeros(num_farmers, 1);
    if ~isempty(A),cplex.addRows(Bl, A, Bu); end                
    clear A_p A_u A_x A Bl Bu

    %  Surplus must be > 1 if option chosen
    %
    %    u_f >= sum_o(x_of)   (f = 1...N)   (Eq 18)
    %   
    A_p = sparse(num_farmers, num_env_out);
    A_u = -speye(num_farmers);
    A_x = -repelem(speye(num_farmers), 1, num_options) * S;
    A   = [A_p, A_u, A_x];
    Bl  = ones(num_farmers, 1) * -Inf;
    Bu  = zeros(num_farmers, 1);
    if ~isempty(A),cplex.addRows(Bl, A, Bu); end    
    clear A_p A_u A_x A Bl Bu  


    % 7. CPLEX call
    % =============
    
    % 7.1 Warm start
    % --------------
    sln = [warm_start_prices warm_start_uptake];
    idx = [1:num_env_out num_env_out+num_farmers+1:num_env_out+num_farmers+num_options*num_farmers];
    idx = idx - 1;            
    filename = 'warmstart.mst';
    probname = 'elms_lp';
    fcn_write_warmstart(sln', idx', filename, probname);
    
    % 7.2 Solve
    % ---------
    tic
    cplex.readMipStart('warmstart.mst');
    cplex.solve();
    toc   
    
    % 7.3 Collect Outputs
    % -------------------
    x        = cplex.Solution.x;
    prices   = x(1:num_env_out)';
    fval     = cplex.Solution.objval; 
    exitflag = cplex.Solution.status;
    exitmsg   = cplex.Solution.statusstring;

end
