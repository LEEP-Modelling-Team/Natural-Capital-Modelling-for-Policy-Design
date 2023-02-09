function best_rate = fcn_payment_fr_act_monopsony(elm_options, ...
                                                         budget, ...
                                                         markup, ...
                                                         cell_ids, ...
                                                         opp_costs, ...
                                                         benefits, ...
                                                         elm_ha, ...
                                                         model)
    %% TEST UNIT DEMAND PRICING OPTIMIZATION
    % MIP formulation derived from the Utility formulation from 
    % Fernandes et al. 2016 and modified to represent a monopsonistic pricing
    % problem subject to a budget constraint.
    % No combination options are included

    %% Add the cplex path into matlab
    if ismac
        addpath(genpath('/Applications/CPLEX_Studio1210/cplex/matlab/x86-64_osx'))
    elseif ispc
        addpath(genpath('C:\Program Files\IBM\ILOG\CPLEX_Studio1210\cplex\matlab\x64_win64'))
    end
    
    fprintf('\n  Set data matrices for MIP optimisation \n  ------------------------------------------- \n');

    %% Select the data
    b = benefits(:, 1:length(elm_options));
    c = opp_costs(:, 1:length(elm_options));
    q = elm_ha(:, 1:length(elm_options));
    c = markup * c; % add 15% markup

    %% Calculate parameters based on the size of the matrix
    num_farmers = size(b, 1);
    num_options = size(b, 2);
    num_x = num_options + num_farmers + num_options * num_farmers;

    %% Store transposed matrices
    bt = b';
    ct = c';
    qt = q';

    %% set the parameters for the big-M formulation
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

    %% Set f, used in optimand
    f_p = sparse(1, num_options);
    f_u = sparse(1, num_farmers);
    f_d = -bt(:)';
    f = [f_p, f_u, f_d];
    
    fprintf('\n  Set inequality constraints for MIP optimisation \n  ------------------------------------------------- \n');


    %% Set Aineq matrix, used in inequality constraints

    %% 1st inequality (unit demand)
    Aineq1_p = sparse(num_farmers, num_options);
    Aineq1_u = sparse(num_farmers, num_farmers);
    Aineq1_d = kron(speye(num_farmers), ones(1, num_options));
    Aineq1 = [Aineq1_p, Aineq1_u, Aineq1_d];

    Bineq1 = ones(num_farmers, 1);

    %% 2nd inequality
    Aineq2_p = [];
    for i = 1:num_farmers
        Aineq2_p = [Aineq2_p; spdiags(q(i, :)', 0, num_options, num_options)];
    end
    Aineq2_u = -repelem(speye(num_farmers), num_options, 1);
    Aineq2_d = sparse(num_options * num_farmers,num_options * num_farmers);
    Aineq2 = [Aineq2_p, Aineq2_u, Aineq2_d];

    Bineq2 = reshape(c', [num_options*num_farmers, 1]);

    clear Aineq2_p Aineq2_u Aineq2_d

    %% 3rd inequality
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

    clear Aineq3_p Aineq3_u Aineq3_d

    %% 4th inequality
    Aineq4_p = -speye(num_options);
    Aineq4_u = sparse(num_options, num_farmers);
    Aineq4_d = sparse(num_options, num_farmers * num_options);
    Aineq4 = [Aineq4_p, Aineq4_u, Aineq4_d];

    Bineq4 = sparse(num_options, 1);

    clear Aineq4_p Aineq4_u Aineq4_d

    %% 5th inequality
    Aineq5_p = sparse(num_farmers, num_options);
    Aineq5_u = -speye(num_farmers);
    Aineq5_d = sparse(num_farmers, num_farmers * num_options);
    Aineq5 = [Aineq5_p, Aineq5_u, Aineq5_d];

    Bineq5 = sparse(num_farmers, 1);

    clear Aineq5_p Aineq5_u Aineq5_d

    %% 6th inequality constraint: budget
    Aineq6_p = sparse(1, num_options);
    Aineq6_u = ones(1, num_farmers);
    Aineq6_d = ct(:)';
    Aineq6 = [Aineq6_p, Aineq6_u, Aineq6_d];

    Bineq6 = budget;

    clear Aineq6_p Aineq6_u Aineq6_d

    %% 7th inequality constraint: maximum price
    Aineq7_p = speye(num_options);
    Aineq7_u = sparse(num_options, num_farmers);
    Aineq7_d = sparse(num_options, num_farmers * num_options);
    Aineq7 = [Aineq7_p, Aineq7_u, Aineq7_d];

    Bineq7 = Ro';

    clear Aineq7_p Aineq7_u Aineq7_d
    
    %% 8th inequality constraint: x = 1 when Uf>0
    Aineq8_p = zeros(num_farmers, num_options);
    Aineq8_u = speye(num_farmers);
    Aineq8_d = -kron(speye(num_farmers), ones(1, num_options)) .* S;
    Aineq8 = [Aineq8_p, Aineq8_u, Aineq8_d];

    Bineq8 = zeros(num_farmers, 1);

    %% 9th constraint (Utility must be slightly greater than 0 for having an uptake)
    Aineq9_p = zeros(num_farmers, num_options);
    Aineq9_u = -speye(num_farmers) .* T;
    Aineq9_d = kron(speye(num_farmers), ones(1, num_options));
    Aineq9 = [Aineq9_p, Aineq9_u, Aineq9_d];

    Bineq9 = zeros(num_farmers, 1);
    
    %% 10th inequality constraint: p_o=0 when sum over f(x_of)=0
    Aineq10_p = speye(num_options);
    Aineq10_u = zeros(num_options, num_farmers);
    Aineq10_d = -kron(ones(1, num_farmers), eye(num_options)) .* S;
    Aineq10 = [Aineq10_p, Aineq10_u, Aineq10_d];

    Bineq10 = zeros(num_options, 1);
    
    %% Combine all inequalities into one matrix
    if isequal(model, 'positive_surplus')
        Aineq = [Aineq1; Aineq2; Aineq3; Aineq4; Aineq5; Aineq6; Aineq7; Aineq8; Aineq9; Aineq10];
        Bineq = [Bineq1; Bineq2; Bineq3; Bineq4; Bineq5; Bineq6; Bineq7; Bineq8; Bineq9; Bineq10];
    elseif isequal(model, 'zero_surplus')
        Aineq = [Aineq1; Aineq2; Aineq3; Aineq4; Aineq5; Aineq6; Aineq7; Aineq8; Aineq10];
        Bineq = [Bineq1; Bineq2; Bineq3; Bineq4; Bineq5; Bineq6; Bineq7; Bineq8; Bineq10];
    else
        error('Model can only take arguments ''positive_surplus'' or ''zero_surplus''')
    end
    %% Set Aeq matrix, used in equality constraints
    % no Aeq matrices

    %% Set beq vector, used in equality constraints
    % no beq matrices

    %% Set low and high bound for the decision variables, and variable type
    lb    = sparse(num_options + num_farmers + num_options * num_farmers, 1);
    ub    = [inf((num_options + num_farmers), 1); ones((num_options * num_farmers), 1)]; %
    ctype = [repmat('C',1,(num_options + num_farmers)), repmat('I', 1, (num_options * num_farmers))];
    % ctype = [repmat('C',1,(num_options + num_farmers)), repmat('C', 1, (num_options * num_farmers))];

    %% Set solver options
    options = cplexoptimset;
    options.Display = 'on';

    %% Run optimization function
    fprintf("Number of farmers (before doubling): %4.f\n", size(b, 1));
    fprintf("Number of inequality constraints: %4.f\n", size(Aineq,1));
    fprintf('Running optimisation\n')
    [x, fval, exitflag, output] = cplexmilp (f, Aineq, Bineq, [], [],...
      [], [], [], lb, ub, ctype, [], options);
    % [x, fval, exitflag, output] = cplexlp (f, Aineq, Bineq, [], [],...
    %   lb, ub, [], options);

    % [x, fval] = cplexlp (f, Aineq, Bineq, lb, ub, options);

    %% Extract output
    %----------------
    % Extract farmer option choice (0 for do nothing)
    
    fprintf('\n  Calculating output \n  --------------------------------- \n');
    
    % extract option_uptake matrix
    options_uptake = round(reshape(x((num_options + num_farmers + 1):end), num_options, num_farmers)');
    
    % extract cell IDs of farmers taking any option, sorted by increasing
    % values
    opt_cells = cell_ids(find(sum(options_uptake, 2)));
    
    option_choice = zeros(1, num_farmers);
    % extract option IDs for farmers taking any options
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
    
    % Calculate total expenditures
    tot_spent = sum(farm_payment);
    
    % Report surplus 
    surplus = x(num_options+1:num_options+num_farmers);
    
    fprintf('\n  Optimisation done \n  -------------------------------------- \n');

end