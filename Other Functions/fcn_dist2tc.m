function tc = fcn_dist2tc(dist)

    % a. straightline vs. travel distance
    % -----------------------------------
    %  I(x/10^1)  I(x^2/10^7) I(x^3/10^12) I(x^4/10^17) I(x^5/10^22) I(x^6/10^28) I(x^7/10^34) 
    % 13.8250357   -0.8971193   -8.2906304    6.2314109   -1.9587947    2.7958513   -1.4747125
    tdistcar = (1/1000)*(13.8250357*dist/10 + -0.8971193*(dist.^2)/10^7 + -8.2906304*(dist.^3)/10^12 + 6.2314109*(dist.^4)/10^17 + -1.9587947*(dist.^5)/10^22 + 2.7958513*(dist.^6)/10^28 + -1.4747125*(dist.^7)/10^34); % Distance in km

    % b. straightline vs. car ttime
    % -----------------------------
    % I(x/10^2)  I(x^2/10^7) I(x^3/10^12) I(x^4/10^17) I(x^5/10^23) I(x^6/10^29) I(x^7/10^35) 
    % 7.598699    -4.626649     3.339851    -1.372186     3.111653    -3.624561     1.698963 
    ttimecar = (1/3600)*(7.598699*dist/10^2 + -4.626649*dist.^2/10^7 + 3.339851*dist.^3/10^12 + -1.372186*dist.^4/10^17 + 3.111653*dist.^5/10^23 + -3.624561*dist.^6/10^29 + 1.698963*dist.^7/10^35); % Time in hours

    % c. straightline vs. car fuel
    % ----------------------------
    % I(x/10^4) I(x^2/10^11) I(x^3/10^16) I(x^4/10^22) I(x^5/10^28) I(x^6/10^34) I(x^7/10^40) 
    % 0.8894736   -6.0871324    2.3648788   -4.9365203    5.4302182   -6.8220266    7.8306890 
    tfuelcar = 0.8894736*dist/10^4 + -6.0871324*dist.^2/10^11 + 2.3648788*dist.^3/10^16 + -4.9365203*dist.^4/10^22 + 5.4302182*dist.^5/10^28 + -6.8220266*dist.^6/10^34 + 7.8306890*dist.^7/10^40; % in �s

    ttime = 2*ttimecar;
    tdist = 2*tdistcar;	
    tccar = 2*tfuelcar;

    tc = tccar + (2.30.*ttime)                      .*(tdist<=8) ... 
               + (2.30.*ttime).*(8./tdist)          .*(tdist>8)  ... 
               + (3.47.*ttime).*((tdist-8)./tdist)  .*(tdist>8).*(tdist<=32) ...
               + (3.47.*ttime).*((32-8)./tdist)     .*(tdist>32) ...
               + (6.14.*ttime).*((tdist-32)./tdist) .*(tdist>32).*(tdist<=160) ...
               + (6.14.*ttime).*((160-32)./tdist)   .*(tdist>160) ...
               + (9.25.*ttime).*((tdist-160)./tdist).*(tdist>160); 

end