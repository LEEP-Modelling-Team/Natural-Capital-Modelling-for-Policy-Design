function p = fcn_lin_search(nvars,k,p0,e,fcn,env_quants,costs,budget,elm_options)

    % Initialise price vectors 
    plo = zeros(1,nvars);
    phi = zeros(1,nvars);
    pmd = zeros(1,nvars);
    
    % Start price of kth env quantity
    plo(k) = p0/2;
    phi(k) = p0*2;
    
    % Squared budget at these prices
    flo = fcn(plo)^2;
    fhi = fcn(phi)^2;
    
    % Find interval that spans the full budget spend
    while (fhi <= flo) 
        plo(k) = phi(k)/2;
        phi(k) = phi(k)*2;
        flo    = fcn(plo)^2;
        fhi    = fcn(phi)^2;
    end
    
    % Line search the interval    
    np    = 5;
    fdiff     = flo - fhi;
    fdiff_old = fdiff*2;
    
    while (abs(fdiff_old-fdiff) >= e) % Until reach tolerance e

        fdiff_old = fdiff;
        
        % Prices to try across range
        pvec = linspace(plo(k),phi(k),np);        

        % Evaluate fcn at each price
        fvec     = zeros(np,1);
        fvec(1)  = flo;
        fvec(np) = fhi;
        for jj = 2:(np-1)
            pmd(k)   = pvec(jj);
            fvec(jj) = fcn(pmd)^2;        
        end
        
        % Find min of prices in range
        [~,minidx] = min(fvec);
        switch minidx
            case 1
                phi(k) = pvec(2);
                fhi    = fcn(phi)^2;
            case np
                plo(k) = pvec(np-1);
                flo    = fcn(lo)^2;
            otherwise
                plo(k) = pvec(minidx-1);
                phi(k) = pvec(minidx+1);
                flo    = fcn(plo)^2;
                fhi    = fcn(phi)^2;                
        end  
        fdiff = flo - fhi;
        % fprintf('fcn diff change: %.5f \n', abs(fdiff_old-fdiff));  
    end

    p = (phi(k) + plo(k)) /2;
    
 end