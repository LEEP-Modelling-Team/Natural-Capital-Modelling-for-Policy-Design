% % Benders Decomposition of Bioenergy Facility Location Problem
% % ------------------------------------------------------------
% clear;
% 
% % 1. CPLEX optimisation object
% % ----------------------------
% addpath ('C:\Program Files\IBM\ILOG\CPLEX_Studio1210\cplex\matlab\x64_win64');
% 
% % 2. Simple Benders Example
% % -------------------------
% N = 11;
% c = (1:0.01:1.10)';
% f = 1.045;
% A = [ones(1,N); speye(N)];
% B = [1; sparse(N,1)];
% b = [1000; 100*ones(N,1)];
% 
% % Full Problem
% % ------------
% fprintf('Full Problem\n');
% fprintf('------------\n');
% cplexFP = Cplex('benders_full');
% cplexFP.Model.sense = 'maximize';
% cplexFP.Param.mip.tolerances.mipgap.Cur = 0;
% cplexFP.Param.mip.tolerances.integrality.Cur = 0;
% cplexFP.DisplayFunc = '';
% cplexFP.Param.timelimit.Cur = 60;
% 
% ctype = [repmat('C',1,N) 'I'];
% lb = zeros(N+1,1);
% cplexFP.addCols([c;f], [], lb, [], ctype);
% cplexFP.addRows(-inf(N+1,1), [A B], b);
% cplexFP.solve;
% fprintf('   y is: ['); fprintf('%g ', cplexFP.Solution.x); fprintf(']    ');
% fprintf('   fval is: %0.2f \n', cplexFP.Solution.objval);
% 
% % Master Problem
% % --------------
% fprintf('Bender''s Decomposition\n');
% fprintf('-----------------------\n');
% cplexMP = Cplex('benders_master');
% cplexMP.Model.sense = 'maximize';
% cplexMP.Param.mip.tolerances.mipgap.Cur = 0;
% cplexMP.Param.mip.tolerances.integrality.Cur = 0;
% cplexMP.DisplayFunc = '';
% cplexMP.Param.timelimit.Cur = 60;
% cplexMP.addCols([f;1], [], sparse(2,1), [], ['IC']);
%     
% 
% % e. Initialise
% % -------------
% lobound = -inf;
% upbound = inf;
% tol = 0.01;
% y = 1500;
% iter = 1;
% 
% while (abs(upbound - lobound) > tol && iter <20)
%     
%     fprintf('   Iteration: %d     ', iter);
%     fprintf(' y is: ['); fprintf('%g', y); fprintf(']    ');
%     
%     % Step 1: Solve the dual of the subproblem
%     % ----------------------------------------
%     cplexSP = Cplex('benders_sub');
%     cplexSP.Model.sense = 'minimize';
%     cplexSP.Param.mip.tolerances.mipgap.Cur = 0;
%     cplexSP.Param.mip.tolerances.integrality.Cur = 0;
%     cplexSP.DisplayFunc = '';
%     cplexSP.Param.timelimit.Cur = 60;    
%     
%     cplexSP.addCols((b-B*y), [], sparse(N+1,1), [], repmat('C',1,N+1));
%     cplexSP.addRows(-inf(N,1), -A', -c);
%     cplexSP.solve;
%     u  = cplexSP.Solution.x;
%     rc = cplexSP.Solution.status;
%     
%     % Step 2: Add optimality cut to master problem
%     % --------------------------------------------
%     if rc == 101
%         % Add optimality constraint
%         cplexMP.addRows(-inf, [u'*B 1], u'*b);
%         lobound = cplexSP.Solution.objval + f'*y;        
%     elseif rc == 118
%         % Add feasibility constraint        
%         cplexMP.addRows(-inf, [u'*B 0], u'*b);
%     else 
%         fprintf('   Unexpected Cplex return code: %0.0f (%s)', rc, cplexSP.Solution.statusstring);
%     end
%     cplexMP.solve;
%     y = cplexMP.Solution.x(1); 
%     upbound = cplexMP.Solution.objval;
%     
%     fprintf('   Lower Bound: %0.2f ', lobound);
%     fprintf('   Upper Bound: %0.2f \n', upbound);
%     
%     iter = iter + 1;
%     
% end
% 
% fprintf('   y is: ['); fprintf('%g', y); fprintf(']    \n');
% 
% 
% % 3. More Complex Benders Example
% % -------------------------------
% % x coefficients
% N = 11;
% c = (1:0.01:1.10)';
% % y coefficients
% f = [1.045; 1.048];
% J = length(f);
% 
% % y only constraints
% A  = [0, 1];
% b  = [200];
% nb = length(b);
% % x & y constraints
% E  = [ones(1,N); speye(N)];
% F  = [ones(1,J); sparse(N,J)];
% h  = [1000; 50*ones(N,1)];
% nh = length(h);
% 
% % Full Problem
% % ------------
% fprintf('Full Problem\n');
% fprintf('------------\n');
% cplexFP = Cplex('benders_full');
% cplexFP.Model.sense = 'maximize';
% cplexFP.Param.mip.tolerances.mipgap.Cur = 0;
% cplexFP.Param.mip.tolerances.integrality.Cur = 0;
% cplexFP.DisplayFunc = '';
% cplexFP.Param.timelimit.Cur = 60;
% 
% ctype = [repmat('C',1,N) repmat('I',1,J)];
% lb = zeros(N+J,1);
% cplexFP.addCols([c;f], [], lb, [], ctype);
% cplexFP.addRows(-inf(nb+nh,1), [sparse(1,N) A; E F], [b; h]);
% cplexFP.solve;
% fprintf('   y is: ['); fprintf('%g ', cplexFP.Solution.x); fprintf(']    ');
% fprintf('   fval is: %0.2f \n', cplexFP.Solution.objval);
% 
% % Master Problem
% % --------------
% fprintf('Bender''s Decomposition\n');
% fprintf('-----------------------\n');
% cplexMP = Cplex('benders_master');
% cplexMP.Model.sense = 'maximize';
% cplexMP.Param.mip.tolerances.mipgap.Cur = 0;
% cplexMP.Param.mip.tolerances.integrality.Cur = 0;
% cplexMP.DisplayFunc = '';
% cplexMP.Param.timelimit.Cur = 60;
% cplexMP.addCols([f;1], [], sparse(J+1,1), [], [repmat('I',1,J) 'C']);
% cplexMP.addRows(-inf(nb,1), [A 0], b);
%     
% 
% % e. Initialise
% % -------------
% lobound = -inf;
% upbound = inf;
% tol = 0.01;
% y = [900; 100];
% iter = 1;
% 
% while (abs(upbound - lobound) > tol && iter <20)
%     
%     fprintf('   Iteration: %d     ', iter);
%     fprintf(' y is: ['); fprintf('%g ', y); fprintf(']    ');
%     
%     % Step 1: Solve the dual of the subproblem
%     % ----------------------------------------
%     cplexSP = Cplex('benders_sub');
%     cplexSP.Model.sense = 'minimize';
%     cplexSP.Param.mip.tolerances.mipgap.Cur = 0;
%     cplexSP.Param.mip.tolerances.integrality.Cur = 0;
%     cplexSP.DisplayFunc = '';
%     cplexSP.Param.timelimit.Cur = 60;
%     
%     cplexSP.addCols((h-F*y), [], sparse(nh,1), [], repmat('C',1,nh));
%     cplexSP.addRows(-inf(N,1), -E', -c);
%     cplexSP.solve;
%     u  = cplexSP.Solution.x;
%     rc = cplexSP.Solution.status;
%           
%     % Step 2: Add optimality cut to master problem
%     % --------------------------------------------
%     if rc == 101
%         % Add optimality constraint
%         cplexMP.addRows(-inf, [u'*F 1], u'*h);
%         lobound = cplexSP.Solution.objval + f'*y;        
%     elseif rc == 118
%         % Add feasibility constraint        
%         cplexMP.addRows(-inf, [u'*F 0], u'*h);
%     else 
%         fprintf('   Unexpected Cplex return code: %0.0f (%s)', rc, cplexSP.Solution.statusstring);
%     end   
%     
%     cplexMP.solve;
%     y = cplexMP.Solution.x(1:2); 
%     upbound = cplexMP.Solution.objval;
%         
%     fprintf('   Lower Bound: %0.2f ', lobound);
%     fprintf('   Upper Bound: %0.2f \n', upbound);
%     
%     iter = iter + 1;
%     
% end
% 
% fprintf('   y is: ['); fprintf('%g ', y); fprintf(']    \n');


% 3. Minimise Problem
% -------------------
% Put assets into investments that give minimum spend. Must spend at least
% 1000, must spend at least 200 on y2, must spend at least 10 on x's.

% x coefficients
N = 11;
c = (2:0.01:2.10)';
% y coefficients
f = [1.045; 1.048];
J = length(f);

% y only constraints
A  = [-1, 0; 0, -1];
b  = [-200; -100];
nb = length(b);
% x & y constraints
E  = [-ones(1,N); -speye(N)];
F  = [-ones(1,J); -sparse(N,J)];
h  = [-1000; -10*ones(N,1)];
nh = length(h);

% Full Problem
% ------------
fprintf('Full Problem\n');
fprintf('------------\n');
cplexFP = Cplex('benders_full');
cplexFP.Model.sense = 'minimize';
cplexFP.Param.mip.tolerances.mipgap.Cur = 0;
cplexFP.Param.mip.tolerances.integrality.Cur = 0;
cplexFP.DisplayFunc = '';
cplexFP.Param.timelimit.Cur = 60;

ctype = [repmat('C',1,N) repmat('I',1,J)];
lb = zeros(N+J,1);
cplexFP.addCols([c;f], [], lb, [], ctype);
cplexFP.addRows(-inf(nb+nh,1), [sparse(nb,N) A; E F], [b; h]);
cplexFP.solve;
fprintf('   y is: ['); fprintf('%g ', cplexFP.Solution.x); fprintf(']    ');
fprintf('   fval is: %0.2f \n', cplexFP.Solution.objval);

% Master Problem
% --------------
fprintf('Bender''s Decomposition\n');
fprintf('-----------------------\n');
cplexMP = Cplex('benders_master');
cplexMP.Model.sense = 'minimize';
cplexMP.Param.mip.tolerances.mipgap.Cur = 0;
cplexMP.Param.mip.tolerances.integrality.Cur = 0;
cplexMP.DisplayFunc = '';
cplexMP.Param.timelimit.Cur = 60;
cplexMP.addCols([f;1], [], sparse(J+1,1), [], [repmat('I',1,J) 'C']);
cplexMP.addRows(-inf(nb,1), [A sparse(nb,1)], b);
    

% e. Initialise
% -------------
lobound = -inf;
upbound = inf;
tol = 0.01;
y = [500; 250];
iter = 1;

while (abs(upbound - lobound) > tol && iter <20)
    
    fprintf('   Iteration: %d     ', iter);
    fprintf(' y is: ['); fprintf('%g ', y); fprintf(']    ');
    
    % Step 1: Solve the dual of the subproblem
    % ----------------------------------------
    cplexSP = Cplex('benders_sub');
    cplexSP.Model.sense = 'maximize';
    cplexSP.Param.mip.tolerances.mipgap.Cur = 0;
    cplexSP.Param.mip.tolerances.integrality.Cur = 0;
    cplexSP.DisplayFunc = '';
    cplexSP.Param.timelimit.Cur = 60;
    
    cplexSP.addCols(-(h-F*y), [], sparse(nh,1), [], repmat('C',1,nh));
    cplexSP.addRows(-inf(N,1), -E', c);
    cplexSP.solve;
    u  = cplexSP.Solution.x;
    rc = cplexSP.Solution.status;
          
    % Step 2: Add optimality cut to master problem
    % --------------------------------------------
    if rc == 101
        % Add optimality constraint
        cplexMP.addRows(-inf, [u'*F -1], u'*h);
        upbound = cplexSP.Solution.objval + f'*y;        
    elseif rc == 118
        % Add feasibility constraint        
        cplexMP.addRows(-inf, [u'*F 0], u'*h);
    else 
        fprintf('   Unexpected Cplex return code: %0.0f (%s)', rc, cplexSP.Solution.statusstring);
    end   
    
    cplexMP.solve;
    y = cplexMP.Solution.x(1:2); 
    lobound = cplexMP.Solution.objval;
        
    fprintf('   Lower Bound: %0.2f ', lobound);
    fprintf('   Upper Bound: %0.2f \n', upbound);
    
    iter = iter + 1;
    
end

fprintf('   y is: ['); fprintf('%g ', y); fprintf(']    \n');

