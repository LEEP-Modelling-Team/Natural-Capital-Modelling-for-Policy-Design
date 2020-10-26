function [res_spec] = Get_Residue_Params(crop_spec, method_crop_residue)
% set values to calculate crop residue amount due to specific crop type  
switch crop_spec
    case 1
        fraction=0.9;
        slope=0.29;
        intercept=0;
        ratio_below_above=0.4;
        N_content_below=0.019;
        N_above_ground=0.027;
    case 2
        fraction=0;
        slope=0;
        intercept=0;    
        ratio_below_above=0;
        N_content_below=0.013167;
        N_above_ground=0.015167; 
    case 3
        fraction=0.89;
        slope=0.98;
        intercept=0.59;
        ratio_below_above=0.22;
        N_content_below=0.014;
        N_above_ground=0.0077;
    case 4
        fraction=0.9;
        slope=0.3;
        intercept=0; 
        ratio_below_above=0.8;
        N_content_below=0.16;
        N_above_ground=0.025;
    case 5
        fraction=0;
        slope=0;
        intercept=0;  
        ratio_below_above=0;
        N_content_below=0.013167;
        N_above_ground=0.014561;
    case 6
        fraction=0.791666667;
        slope=0.665;
        intercept=0.7216666667;  
        ratio_below_above=0.291666667;
        N_content_below=0.013167;
        N_above_ground=0.015167;
    case 7
        fraction=0.9;
        slope=0.36;
        intercept=0.68; 
        ratio_below_above=0.19;
        N_content_below=0.01;
        N_above_ground=0.01;
    case 8
        fraction=0.9;
        slope=0.3;
        intercept=0;
        ratio_below_above=0.8;
        N_content_below=0.16;
        N_above_ground=0.025;
    case 9
        fraction=0.87;
        slope=1.03;
        intercept=0.61;     
        ratio_below_above=0.22;
        N_content_below=0.007;
        N_above_ground=0.006;
    case 10
        fraction=0.9;
        slope=1.43;
        intercept=0.14;
        ratio_below_above=1;
        N_content_below=0;
        N_above_ground=0.007;
    case 11
        fraction=0.89;
        slope=0.91;
        intercept=0.89;  
        ratio_below_above=0.25;
        N_content_below=0.008;
        N_above_ground=0.007;
    case 12
        fraction=0.94;
        slope=1.07;
        intercept=1.54;      
        ratio_below_above=1;
        N_content_below=0;
        N_above_ground=0.016;
    case 13
        fraction=0.9;
        slope=0.3;
        intercept=0;     
        ratio_below_above=0.54;
        N_content_below=0.012;
        N_above_ground=0.015;
    case 14
        fraction=0.22;
        slope=0.1;
        intercept=1.06;
        ratio_below_above=0.2;
        N_content_below=0.014;
        N_above_ground=0.019;
    case 15
        fraction=0.89;
        slope=0.95;
        intercept=2.46;
        ratio_below_above=0.16;
        N_content_below=0;
        N_above_ground=0.007;
    case 16
        fraction=0.88;
        slope=1.09;
        intercept=0.88;  
        ratio_below_above=0.635;
        N_content_below=0.011;
        N_above_ground=0.005;
    case 17
        fraction=0.89;
        slope=0.88;
        intercept=1.33;      
        ratio_below_above=1;
        N_content_below=0;
        N_above_ground=0.007;
    case 18
        fraction=0.91;
        slope=0.93;
        intercept=1.35;   
        ratio_below_above=0.19;
        N_content_below=0.008;
        N_above_ground=0.008;
    case 19
        fraction=0.89;
        slope=1.29;
        intercept=0.75;      
        ratio_below_above=0.28;
        N_content_below=0.009;
        N_above_ground=0.006;
    case 20
        fraction=0;
        slope=0;
        intercept=0;         
        ratio_below_above=0;
        N_content_below=0.0132;
        N_above_ground=0.0152;
    case 21
        fraction=0.9;
        slope=0;
        intercept=3.226667;   
        ratio_below_above=0.2916666667;
        N_content_below=0.013167;
        N_above_ground=0.015167;
    case 22
        fraction=0;
        slope=0;
        intercept=0; 
        ratio_below_above=0;
        N_content_below=0.0132;
        N_above_ground=0.015167;
    case 23
        fraction=0.1235;
        slope=0.155061111;
        intercept=0.1166388889;         
        ratio_below_above=0.3956;
        N_content_below=0.032;
        N_above_ground=0.032;
    case 24
        fraction=0.89;
        slope=1.61;
        intercept=0.4;
        ratio_below_above=0.23;
        N_content_below=0.009;
        N_above_ground=0.006;
    case 25
        fraction=0.88;
        slope=1.09;
        intercept=0.88;
        ratio_below_above=0.22;
        N_content_below=0.009;
        N_above_ground=0.006;
    case 26
        fraction=0.91;
        slope=1.13;
        intercept=0.85;
        ratio_below_above=0.19;
        N_content_below=0.008;
        N_above_ground=0.008;
    case 27
        fraction=0.9;
        slope=0.3;
        intercept=0;
        ratio_below_above=0.4;
        N_content_below=0.022;
        N_above_ground=0.027;
    case 28
        fraction=0.9;
        slope=0.3;
        intercept=0;
        ratio_below_above=0.54;
        N_content_below=0.012;
        N_above_ground=0.015;
    case 29
        fraction=0.94;
        slope=1.07;
        intercept=1.54;
        ratio_below_above=0.2;
        N_content_below=0.014;
        N_above_ground=0.016;
    case 30
        fraction=0.22;
        slope=0.1;
        intercept=1.06;
        ratio_below_above=0.2;
        N_content_below=0.014;
        N_above_ground=0.019;
    case 31
        fraction=0.7916666667;
        slope=0.665;
        intercept=0.721666666667;
        ratio_below_above=0.291666667;
        N_content_below=0.013167;
        N_above_ground=0.015167;
end                    


% method of crop residue management
switch method_crop_residue          % for explanations of the values see A1.Submodels&data B401 - E408
    case 1                          % Removed; left untreated in heaps or pits
        method_crm_CH4=0.065333333;
        method_crm_N2O=0.00050675;
    case 2                          % Removed; non-Forced Aeration Compost 
        method_crm_CH4=0.005;
        method_crm_N2O=0.00050675;
    case 3                          % Removed; Forced Aeration Compost 
        method_crm_CH4=0.003;
        method_crm_N2O=0.000337833;
    case 4                          % Left on field; Incorporated or mulch    
       method_crm_CH4=0;
       method_crm_N2O=0; 
    case 5                          % Burned
       method_crm_CH4=0.0027;
       method_crm_N2O=0.00007; 
    case 6                          % Exported off farm    
       method_crm_CH4=0;
       method_crm_N2O=0; 
end
      

% Package and send back to caller
res_spec.fraction=fraction;
res_spec.slope=slope;
res_spec.intercept=intercept;
res_spec.ratio_below_above=ratio_below_above;
res_spec.N_content_below=N_content_below;
res_spec.N_above_ground=N_above_ground;
res_spec.method_crm_CH4=method_crm_CH4;
res_spec.method_crm_N2O=method_crm_N2O;
end
