%% fcn_find_max_prices
%  ===================
%  Author:        Mattia Mancini
%  Created:       19-Jan-2023
%  Last modified: 19-Jan_2023
%  -----------------------------
%
%  DESCRIPTION
%  Function to find a max bound for the payment per hectare of each elms
%  option which will use the entire budget. This also allows to identify
%  the subset of cells that is never enrolled into any option, regardldess
%  of the budget
%
%  INPUTS:
%      - c: cost array: total cost for each farmer for each option,
%           including markup
%      - q: quantity array. This can be the number of hectares available
%           for enrollment in the scheme (payments for activity, 2d array) 
%           or quantity of environmental good/ecosystem service generated
%           (this is a 3d array of size X x Y x Z where X is the number of
%           cells (i.e., 32784 for England), Y is the number of
%           environmental quantities/ecosystem services (e.g., 10) and Z is
%           the number of elms options (e.g., 8).
%       - cell_ids: the new2kid of the cells in the analysis
%       - budget: the total budget for the scheme
%       - payment: the type of payment ('fr_act', 'fr_env', 'fr_es').
%  ========================================================================


function max_rates = fcn_find_max_prices_env_out(b, c, q, budget)
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
    % Calculate parameters based on the size of the matrix
    num_farmers = size(b, 1);
    num_options = size(b, 2);
    num_env_out = width(q);

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

    % 6) T
    T = 1;

    % Set f, used in optimand
    f_p = sparse(num_env_out, 1);
    f_u = sparse(num_farmers, 1);
    f_d = -bt(:);
    f = [f_p; f_u; f_d];

    % Set variable bounds and types
    lb    = sparse(num_env_out + num_farmers + num_options * num_farmers, 1);
    ub    = [inf((num_env_out + num_farmers), 1); ones((num_options * num_farmers), 1)]; %
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
%     q_perm = permute(q, [3, 2, 1]);
%     Aineq3_p = -reshape(permute(q_perm, [1, 3, 2]), [], size(q_perm, 2), 1);
%     Aineq3_u = repelem(speye(num_farmers), num_options, 1);
%     % r_ib = repmat(R, 1, num_farmers*num_options)';
%     c_kf = repmat(repelem(c, num_options, 1),1,num_farmers);
%     kron_product = kron(speye(num_farmers), ones(num_options,num_options));
%     Rf_rep = repmat(R_f, 1, num_options)';
%     Rf_rep = Rf_rep(:);
%     Aineq3_d = kron_product .* c_kf + (Rf_rep.*speye(num_farmers*num_options));
%     Aineq3 = [Aineq3_p, Aineq3_u, Aineq3_d];
    q_perm = permute(q, [3, 2, 1]);
    Aineq3_p = -reshape(permute(q_perm, [1, 3, 2]), [], size(q_perm, 2), 1);
    Aineq3_u = repelem(speye(num_farmers), num_options, 1);
    % r_ib = repmat(R, 1, num_farmers*num_options)';

    c_rf = num2cell(c,2);
    c_rf = repelem(sparse(blkdiag(c_rf{:})), num_options, 1);

    Rf_rep = repmat(R_f, 1, num_options)'; 
    Rf_rep = Rf_rep(:);
    Aineq3_d = c_rf + (Rf_rep.*speye(num_farmers*num_options));
    Aineq3 = [Aineq3_p, Aineq3_u, Aineq3_d];

    Bineq3 = Rf_rep;
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


    % Iterate over environmental quantities to find the max rate for each    
    max_rates = zeros(1, width(q));
    for i = 1:width(q)
                
        % 1.2. CLPEX optimisation object
        % ------------------------------
        cplex = Cplex('max_p');
        cplex.Model.sense = 'minimize';
        cplex.Param.emphasis.mip.Cur = 0;
        cplex.Param.mip.strategy.search.Cur = 2;
        cplex.Param.parallel.Cur = 1;
        
        % Add objective function to cplex class
        cplex.addCols(f, [], lb, ub, ctype);
        
        % 7th inequality constraint: maximum price
        Aineq7_p = speye(num_env_out);
        Aineq7_u = sparse(num_env_out, num_farmers);
        Aineq7_d = sparse(num_env_out, num_farmers * num_options);
        Aineq7 = [Aineq7_p, Aineq7_u, Aineq7_d];

        rates = R_e';
        Bineq7 = zeros(1, width(q))';
        Bineq7(i) = rates(i);
        B7_lb = zeros(num_env_out, 1);
        B7_ub = Bineq7;

        clear Aineq7_p Aineq7_u Aineq7_d
        
        % Combine all inequalities into one matrix
        A = [Aineq1; Aineq2; Aineq3; Aineq4; Aineq5; Aineq6; Aineq7; Aineq8; Aineq9];
        B = [Bineq1; Bineq2; Bineq3; Bineq4; Bineq5; Bineq6; Bineq7; Bineq8; Bineq9];
        B_lb = [B1_lb; B2_lb; B3_lb; B4_lb; B5_lb; B6_lb; B7_lb; B8_lb; B9_lb];
        B_ub = [B1_ub; B2_ub; B3_ub; B4_ub; B5_ub; B6_ub; B7_ub; B8_ub; B9_ub];

        cplex.addRows(B_lb, A, B_ub);
 

        %% 5. SOLVE
        %  ========
        tic
        cplex.solve();
        toc

        %% 6. OUTPUT
        %  =========
        x = cplex.Solution.x;
        prices = x(1:width(q));
        max_rates(i) = prices(i);
        
        clear cplex
    end
end
    
