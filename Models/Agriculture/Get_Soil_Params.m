function [s] = Get_Soil_Params(Grid)

% This function is passed soil data from a particular grid
% and returns parameters relevant to GHG calculations
%            
% Original code from Sylvia Vetter, University of Aberdeen
% Based on the Cool Farm Tool
% 
% Input parameters:
% gridCell( soil_texture, SOM,  soil_drainage, soil_pH)
% Values are indices, see calling program.
%       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO: Convert these into array lookups of saved data %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% soil texture
switch Grid(1) % soil_texture
    case 1                  % fine
        s.s_t_index_N2O=0;
        s.s_t_index_NO=0;
        s.s_t_index_NH3=0;
        s.s_t_index_CEC=0.6;
        s.bd_index_CEC=1.5;   %bulk density for fine soil texture
    case 2                  % medium
        s.s_t_index_N2O=-0.472;
        s.s_t_index_NO=0;
        s.s_t_index_NH3=0;
        s.s_t_index_CEC=0.3;
        s.bd_index_CEC=1.3;   %bulk density for fine soil texture
    case 3                  % coarse
        s.s_t_index_N2O=-0.008;
        s.s_t_index_NO=0;
        s.s_t_index_NH3=0;
        s.s_t_index_CEC=0.15;
        s.bd_index_CEC=1.7;   %bulk density for fine soil texture
end

        
%% SOM/SOC
switch Grid(2)%SOM
    case 1                 % <= 1.72
        s.SOM_index_N2O=0;
        s.SOM_index_NO=0;
        s.SOM_index_NH3=0;
        s.SOM_index_CEC=30;
    case 2                 % 1.72 - 5.16
        s.SOM_index_N2O=0.14;
        s.SOM_index_NO=0;
        s.SOM_index_NH3=0;
        s.SOM_index_CEC=60;
    case 3                 % 5.16 - 10.32
        s.SOM_index_N2O=0.58;
        s.SOM_index_NO=2.571;
        s.SOM_index_NH3=0;
        s.SOM_index_CEC=135;
    case 4                 % >= 10.32
        s.SOM_index_N2O=1.045;
        s.SOM_index_NO=2.571;
        s.SOM_index_NH3=0;
        s.SOM_index_CEC=180;
end

%% soil drainage
switch Grid(4)%soil_drainage
    case 1              % poor
        s.s_d_N2O=0;
        s.s_d_NO=0;
        s.s_d_NH3=0;
    case 2              % good
        s.s_d_N2O=-0.42;
        s.s_d_NO=0.946;
        s.s_d_NH3=0;
end


%% soil pH
switch Grid(3)%soil_pH
    case 1              % pH <= 5.5        
        s.s_pH_N2O=0;
        s.s_pH_NO=0;
        s.s_pH_NH3=-1.072;
        s.pH_index_CEC=5;
    case 2              % 5.5 <= pH <= 7.3
        s.s_pH_N2O=0.109;
        s.s_pH_NO=0;
        s.s_pH_NH3=-0.933;
        s.pH_index_CEC=6.4;
    case 3              % 7.3 <= pH <= 8.5
        s.s_pH_N2O=-0.352;
        s.s_pH_NO=0;
        s.s_pH_NH3=-0.208;
        s.pH_index_CEC=7.9;
    case 4              % pH >= 8.5
        s.s_pH_N2O=-0.352;
        s.s_pH_NO=0;
        s.s_pH_NH3=0;
        s.pH_index_CEC=9;
end

%% soil CEC
% pH, soil texture, SOM index and bulk density for CEC calculation > see above

%if SOM >= 1 
if Grid(2) >= 1 
    s.CEC_index=s.SOM_index_CEC*1000*s.bd_index_CEC;
else 
    s.CEC_index=30*s.SOM*s.bd_index_CEC/1.72;             % SOM -Wert hier noch unklar, SOM=1
end

s.soil_CEC=(-59+51*s.pH_index_CEC)*s.CEC_index/3000000/s.bd_index_CEC+(30+4.4*s.pH_index_CEC)*s.s_t_index_CEC;

s.s_CEC_N2O=0;
s.s_CEC_NO=0;
if s.soil_CEC<16
       s.s_CEC_NH3=0.088;
else
    if s.soil_CEC>=16 && s.soil_CEC<24   
       s.s_CEC_NH3=0.012;
    else
        if s.soil_CEC>=24 && s.soil_CEC<32
            s.s_CEC_NH3=0.163;
        else
            s.s_CEC_NH3=0;

        end
    end
end    

% %% Put it together and return to caller:
% % soil texture
% s.s_t_index_N2O=s_t_index_N2O;
% s.s_t_index_NO=s_t_index_NO;
% s.s_t_index_NH3=s_t_index_NH3;
% s.s_t_index_CEC=s_t_index_CEC;
% s.bd_index_CEC=bd_index_CEC;
% % SOM/SOC
% s.SOM_index_N2O=SOM_index_N2O;
% s.SOM_index_NO=SOM_index_NO;
% s.SOM_index_NH3=SOM_index_NH3;
% s.SOM_index_CEC=SOM_index_CEC;
% % Soil drainage
% s.s_d_N2O=s_d_N2O;
% s.s_d_NO=s_d_NO;
% s.s_d_NH3=s_d_NH3;
% % soil pH
% s.s_pH_N2O=s_pH_N2O;
% s.s_pH_NO=s_pH_NO;
% s.s_pH_NH3=s_pH_NH3;
% s.pH_index_CEC=pH_index_CEC;
% % soil CEC
% s.s_CEC_NH3=s_CEC_NH3;
% s.s_CEC_N2O=s_CEC_N2O;
% s.s_CEC_NO=s_CEC_NO;
% s.soil_CEC=soil_CEC;
% s.CEC_index=CEC_index;
end