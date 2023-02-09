function best_rate = fcn_payment_fr_env_monopsony(elm_options, ...
                                                     budget, ...
                                                     markup, ...
                                                     opp_costs, ...
                                                     benefits, ...
                                                     elm_ha, ...
                                                     env_outs, ...
                                                     cell_ids)
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

%% Calculate quantities of env. outcomes based on the randomly assigned year
%  in which farmers enter a scheme contained in 'scheme_year.mat'

% options and combos:
%  1) arable_reversion_sng_access 
%  2) destocking_sng_access
%  3) arable_reversion_wood_access 
%  4) destocking_wood_access
%  5) arable_reversion_sng_noaccess
%  6) destocking_sng_noaccess
%  7) arable_reversion_wood_noaccess
%  8) destocking_wood_noaccess
%  9)  = option 1 + 2
% 10) = option 1 + 4
% 11) = option 2 + 3
% 12) = option 3 + 4
% 13) = option 5 + 6
% 14) = option 5 + 8
% 15) = option 6 + 7
% 16) = option 7 + 8

% env_quantities = {'t_GHG'; 'sng_access_ha'; 'wood_acess_ha'; 'sng_noaccess_ha';...
%     'wood_noacess_ha'; 'flooding'; 'nitrates'; 'phosphates'; 'pollinators';...
%     'priority_species'};

num_env_out = 10;
fn = fieldnames(env_outs);
qe = struct;
for k = 1:numel(fn)
    substr = env_outs.(fn{k});
    env_quantities = zeros(size(benefits, 1), num_env_out);
    for i = 1:size(scheme_year, 1)
        env_quantities(i, :) = substr(i, :, scheme_year(i));
    end
    qe.(fn{k}) = env_quantities;
end

qe = cat(3, qe.arable_reversion_sng_access, qe.destocking_sng_access,...
    qe.arable_reversion_wood_access, qe.destocking_wood_access,...
    qe.arable_reversion_sng_noaccess, qe.destocking_sng_noaccess,...
    qe.arable_reversion_wood_noaccess, qe.destocking_wood_noaccess,...
    qe.ar_sng_d_sng, qe.ar_sng_d_w, qe.ar_w_d_sng, qe.ar_w_d_w,...
    qe.ar_sng_d_sng_na, qe.ar_sng_d_w_na, qe.ar_w_d_sng_na, qe.ar_w_d_w_na);

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

% budget = 10000000

% calculate big-M parameters:
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

S = max(R_f);
% T = max(Rf) / 1e9;
T = 1;

%% Set f, used in optimand
f_p = zeros(1, num_env_out);
f_u = zeros(1, num_farmers);
f_d = -bt(:)';
f = [f_p, f_u, f_d];

%% Set Aineq matrix, used in inequality constraints

%% 1st inequality (unit demand)
Aineq1_p = zeros(num_farmers, num_env_out);
Aineq1_u = zeros(num_farmers, num_farmers);
Aineq1_d = kron(eye(num_farmers), ones(1, num_options));
Aineq1a = [Aineq1_p, Aineq1_u, Aineq1_d];

Bineq1a = ones(num_farmers, 1);

% 1b inequality (unit demand) for only recreation on arable (odd lines) and grassland farms (even lines
Aineq1_p = zeros(num_farmers, num_env_out);
Aineq1_u = zeros(num_farmers, num_farmers);
ind = [1, 0, 0, 0, 1, 0, 0, 0; 0, 1, 0, 0, 0, 1, 0, 0];
ind = repmat(ind, num_farmers/2, num_farmers);
Aineq1_d = ind .* kron(eye(num_farmers), ones(1, num_options));
Aineq1b = [Aineq1_p, Aineq1_u, Aineq1_d];

Bineq1b = ones(num_farmers, 1);

% 1c inequality (unit demand) for only recreation on arable (odd lines) and grassland farms (even lines
Aineq1_p = zeros(num_farmers, num_env_out);
Aineq1_u = zeros(num_farmers, num_farmers);
ind = [0, 0, 1, 0, 0, 0, 1, 0; 0, 0, 0, 1, 0, 0, 0, 1];
ind = repmat(ind, num_farmers/2, num_farmers);
Aineq1_d = ind .* kron(eye(num_farmers), ones(1, num_options));
Aineq1c = [Aineq1_p, Aineq1_u, Aineq1_d];

Bineq1c = ones(num_farmers, 1);

% 1e inequality (unit demand) for only recreation on both farms
Aineq1_p = zeros(num_farmers, num_env_out);
Aineq1_u = zeros(num_farmers, num_farmers);
ind = [1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1;...
       0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0];
ind = repmat(ind, num_farmers/2, num_farmers/2);
Aineq1_d = ind .* repelem(kron(eye(num_farmers/2), ones(1, num_options*2)),2,1);
Aineq1d = [Aineq1_p, Aineq1_u, Aineq1_d];

Bineq1d = ones(num_farmers, 1);

Aineq1 = [Aineq1a; Aineq1b; Aineq1c; Aineq1d];
Bineq1 = [Bineq1a; Bineq1b; Bineq1c; Bineq1d];

%% 2nd inequality
q_perm = permute(q, [3, 2, 1]);
Aineq2_p = reshape(permute(q_perm, [1, 3, 2]), [], size(q_perm, 2), 1);
Aineq2_u = -repelem(eye(num_farmers), num_options, 1);
Aineq2_d = zeros(num_options * num_farmers);
Aineq2 = [Aineq2_p, Aineq2_u, Aineq2_d];

Bineq2 = reshape(c', [num_options*num_farmers, 1]);

%% 3rd inequality
q_perm = permute(q, [3, 2, 1]);
Aineq3_p = -reshape(permute(q_perm, [1, 3, 2]), [], size(q_perm, 2), 1);
Aineq3_u = repelem(eye(num_farmers), num_options, 1);
% r_ib = repmat(R, 1, num_farmers*num_options)';
c_kf = repmat(repelem(c, num_options, 1),1,num_farmers);
kron_product = kron(eye(num_farmers), ones(num_options,num_options));
Rf_rep = repmat(R_f, 1, num_options)';
Rf_rep = Rf_rep(:);
Aineq3_d = kron_product .* c_kf + (Rf_rep.*eye(num_farmers*num_options));
Aineq3 = [Aineq3_p, Aineq3_u, Aineq3_d];
 
Bineq3 = Rf_rep;

%% 4th inequality
Aineq4_p = -eye(num_env_out);
Aineq4_u = zeros(num_env_out, num_farmers);
Aineq4_d = zeros(num_env_out, num_farmers * num_options);
Aineq4 = [Aineq4_p, Aineq4_u, Aineq4_d];

Bineq4 = zeros(num_env_out, 1);

%% 5th inequality
Aineq5_p = zeros(num_farmers, num_env_out);
Aineq5_u = -eye(num_farmers);
Aineq5_d = zeros(num_farmers, num_farmers * num_options);
Aineq5 = [Aineq5_p, Aineq5_u, Aineq5_d];

Bineq5 = zeros(num_farmers, 1);

%% 6th inequality constraint: budget
Aineq6_p = zeros(1, num_env_out);
Aineq6_u = ones(1, num_farmers);
Aineq6_d = ct(:)';
Aineq6 = [Aineq6_p, Aineq6_u, Aineq6_d];

Bineq6 = budget;

%% 7th inequality constraint: maximum price
Aineq7_p = eye(num_env_out);
Aineq7_u = zeros(num_env_out, num_farmers);
Aineq7_d = zeros(num_env_out, num_farmers * num_options);
Aineq7 = [Aineq7_p, Aineq7_u, Aineq7_d];

Bineq7 = R_e';

%% 8th inequality constraint: x = 1 when Uf>0
Aineq8_p = zeros(num_farmers, num_env_out);
Aineq8_u = eye(num_farmers);
Aineq8_d = -kron(eye(num_farmers), ones(1, num_options)) .* S;
Aineq8 = [Aineq8_p, Aineq8_u, Aineq8_d];

Bineq8 = zeros(num_farmers, 1);

%% 9th constraint (Utility must be greater than 0 for having an uptake)
Aineq9_p = zeros(num_farmers, num_env_out);
Aineq9_u = -eye(num_farmers) .* T;
Aineq9_d = kron(eye(num_farmers), ones(1, num_options));
Aineq9 = [Aineq9_p, Aineq9_u, Aineq9_d];

Bineq9 = zeros(num_farmers, 1);

%% Combine all inequalities into one matrix
Aineq = [Aineq1; Aineq2; Aineq3; Aineq4; Aineq5; Aineq6; Aineq7; Aineq8; Aineq9];

%% Combine all inequalities into one matrix
Bineq = [Bineq1; Bineq2; Bineq3; Bineq4; Bineq5; Bineq6; Bineq7; Bineq8; Bineq9];

%% Set Aeq matrix, used in equality constraints
% no Aeq matrices

%% Set beq vector, used in equality constraints
% no beq matrices

%% Set low and high bound for the decision variables, and variable type
lb    = zeros(num_env_out + num_farmers + num_options * num_farmers, 1);
ub    = [inf((num_env_out + num_farmers), 1); ones((num_options * num_farmers), 1)]; %
ctype = [repmat('C',1,(num_env_out + num_farmers)), repmat('I', 1, (num_options * num_farmers))];
% ctype = [repmat('C',1,(num_options + num_farmers)), repmat('C', 1, (num_options * num_farmers))];

%% Set solver options
options = cplexoptimset;
options.Display = 'on';

%% Run optimization function
fprintf('Running optimisation')
[x, fval, exitflag, output] = cplexmilp (f, Aineq, Bineq, [], [],...
  [], [], [], lb, ub, ctype, [], options);

% [x, fval] = cplexlp (f, Aineq, Bineq, lb, ub, options);

%% Extract output
%----------------
% Extract farmer option choice (0 for do nothing)
options_uptake = round(reshape(x((num_env_out + num_farmers + 1):end), num_options, num_farmers)');

% remove doubled farmers adding the second farm (even, grassland) in line with the
% first (odd, arable)
uptake_arable = options_uptake(1:2:end, :);
uptake_grassland = options_uptake(2:2:end, :);
uptake = [uptake_arable, uptake_grassland];

% create matrix containing the farmer id and the options chosen on both
% parts of their land (arable and grassland). Throw an error of the
% option selected in the arable land is conversion from grassland and
% viceversa
cell_uptake = [];
for i = 1:size(uptake,1)
    if sum(uptake(i, 1:8)) == 1
        opt_a = find(uptake(i, 1:8));
    else
        opt_a = 0;
    end
    if sum(uptake(i, 9:16)) == 1
        opt_b = find(uptake(i, 9:16));
    else
        opt_b = 0;
    end
    if ~ismember(opt_a, [0, 1, 3, 5, 7])
        error('Options for farmer %d not in arable range', i);
    elseif ~ismember(opt_b, [0, 2, 4, 6, 8])
        error('Options for farmer %d not in grassland range', i);
    else
        cell_uptake = [cell_uptake; [i, opt_a, opt_b]];
    end       
end

% Assign the index of the options taken for each farmer, including
% combos according to the following numbering system:
% option 9  = option 1 + option 2
% option 10 = option 1 + option 4
% option 11 = option 2 + option 3
% option 12 = option 3 + option 4
% option 13 = option 5 + option 6
% option 14 = option 5 + option 8
% option 15 = option 6 + option 7
% option 16 = option 7 + option 8
cell_uptake(:, 4) = 0;
for i = 1:size(cell_uptake)
    opt = cell_uptake(i, 2:3);
    if ismember(opt, [0,0])
        cell_uptake(i, 4) = 0;
    elseif ismember(opt, [1,2])
        cell_uptake(i, 4) = 9;
    elseif ismember(opt, [1,4])
        cell_uptake(i, 4) = 10;
    elseif ismember(opt, [2,3])
        cell_uptake(i, 4) = 11;
    elseif ismember(opt, [3,4])
        cell_uptake(i, 4) = 12;
    elseif ismember(opt, [5,6])
        cell_uptake(i, 4) = 13;
    elseif ismember(opt, [5,8])
        cell_uptake(i, 4) = 14;
    elseif ismember(opt, [6,7])
        cell_uptake(i, 4) = 15;
    elseif ismember(opt, [7,8])
        cell_uptake(i, 4) = 16;
    else
        [~,~,v] = find(opt);
        cell_uptake(i, 4) = v;
    end
end

cell_uptake(:, 5) = cell_ids;

% extract cell IDs of farmers taking any option, sorted by increasing
% values
opt_cells = cell_ids(find(cell_uptake(:, 4)), 1);
% Using whole cells so add column of proportions with 1 in 
opt_cells = [opt_cells, ones(length(opt_cells), 1)];

% extract option IDs for farmers taking any options
option_choice = nonzeros(cell_uptake(:,4));

% extract option rates from the optimization algorithm
best_rate = x(1:num_env_out)';

% report tot benefits
tot_benefits = -fval;

% calculate cell payments
options_uptake_rep = repmat(options_uptake, 1, 1, num_env_out);
opt_payment = q .* best_rate;
farm_payment = sum(options_uptake_rep .* permute(opt_payment,[1,3,2]), 3);
payment_arable = farm_payment(1:2:end, :);
payment_grassland = farm_payment(2:2:end, :);
cell_payment = [payment_arable, payment_grassland];
farm_payment = nonzeros(sum(cell_payment,2));


% Calculate total expenditures
tot_spent = sum(farm_payment);

% Calculate BCR
bcr = tot_benefits/tot_spent;

% Calculate budget surplus
budget_surplus = budget - tot_spent;

% Report surplus 
surplus = x(num_options+1:num_options+num_farmers);

% Compare surplus with uptake to test the surplus treshold of uptake
comp = [surplus, sum(options_uptake, 2)];
comp_low = comp(comp(:,1) < T, :);
comp_low = comp(comp(:,2) == 1, :);
min(comp_low(:,1));
      