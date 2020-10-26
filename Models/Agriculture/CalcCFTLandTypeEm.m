function [CFT_Land_Em] = CalcCFTLandTypeEm(LandOrder)
% Calculates the land-type-specific emissions from farming certain land types
% These include:
            % Emissions from feriliser
            % Agrochemicals and
            % Crop residue management
%            
% Original code from Sylvia Vetter, University of Aberdeen
% Based on the Cool Farm Tool
% 
% Refactored by AJ De-Gol (UEA)
% 
% Land Types corresponding to structure index:
% 1 oilseed rape, 2 cereals, 3 root crops, 4 grassland with rough grazing,
% 5 permanent grassland, 6 temperate grassland, 7 other use
%
%% Setup
% For debugging
%clear;
%LandOrder(1).name='s_osrape';
%LandOrder(2).name='s_cer'; 
%LandOrder(3).name='s_root'; 
%LandOrder(4).name='s_tgrass'; 
%LandOrder(5).name='s_pgrass';
%LandOrder(6).name='s_rgraz';

% Retrieve fertiliser parameters into a structure
% Structure is fertparams(n) where n is fertiliser type
fert = Get_Fert_Params;

% Retrieve Land type parameters (e.g. name, application rates, etc - see variable)
landtype = Get_Land_ParamsR4;
% Reorder to match main program
landtype = CFTReorderLandType(landtype, LandOrder);

%% Emissions from fertiliser:

for i = 1:length(landtype)
    % Fertiliser 1
    f1tmp=landtype(i).Nrate*fert(1).EFMA/fert(1).N_concentration;
    % Fertiliser 2
    f2tmp=landtype(i).P2O5rate*fert(2).EFMA/fert(2).P2O5_concentration;
    % Fertiliser 3
    f3tmp=landtype(i).K2Orate*fert(3).EFMA/fert(3).K2O_concentration;
    % Fertiliser 4
    f4tmp=landtype(i).CaOrate*fert(4).EFMA/fert(4).CaO_concentration;
    
    emission_from_fertiliser(i) = f1tmp+f2tmp+f3tmp+f4tmp;
end

%% Agrochemicals
metric_use=20.5;
for i = 1:length(landtype)
    agrochemicals_C02(i) = landtype(i).applications*metric_use;
    %*area %area=1
end

%% Crop Residue Management
% Constants
converterN_N2O=1.571428571;
N2O=296;
CH4=25;
crop_residue_management_CO2=zeros(1,length(landtype));

for i = 1:length(landtype)
    % Gather residue parameters for land type:
    res_spec=Get_Residue_Params(landtype(i).cropspec, landtype(i).method_crop_residue);
    % Calculate residue
    residue_amount=landtype(i).fresh_product*res_spec.fraction*res_spec.slope+res_spec.intercept;
    if landtype(i).method_crop_residue==4
        res_spec.method_crm_N2O=0.01*converterN_N2O*(res_spec.N_above_ground+res_spec.N_content_below*res_spec.ratio_below_above);
    end
    % Method 1
%    CH4res=residue_amount*res_spec.method_crm_CH4;
%    N2Ores=residue_amount*res_spec.method_crm_N2O;
%    crop_residue_management_CO2(i)=1000*(CH4res*CH4+N2Ores*N2O);
    % Method 2
    crop_residue_management_CO2(i)=residue_amount*1000*(res_spec.method_crm_CH4*CH4+res_spec.method_crm_N2O*N2O);
    
end
    
%% Finish
% Sum all emissions for land type; order should be good
    CFT_Land_Em=emission_from_fertiliser+agrochemicals_C02+crop_residue_management_CO2;
    
    
end