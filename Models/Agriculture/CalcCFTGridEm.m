function [CFT_Grid_Em] = CalcCFTGridEm(LandOrder,GridCells)


% debug, temp, ignore/delete.
%clear;
%GridCells=[1,1,1,2,1];
%load('LandOrder.mat');
%LandOrder=tmp;
%clear tmp;

% Calculates the grid-cell-specific emissions from farming certain land types
% These include:
            % Background C02 and
            % Field emissions
%            
% Original code from Sylvia Vetter, University of Aberdeen
% Based on the Cool Farm Tool
% 
% Land Types corresponding to structure index:
% 1 oilseed rape, 2 cereals, 3 root crops, 4 grassland with rough grazing,
% 5 permanent grassland, 6 temperate grassland, 7 other use
%
%% Initial declarations and outside-loop calculations:
% Retrieve fertiliser parameters into a structure
% Structure is fertparams(n) where n is which fertiliser you want
fert = Get_Fert_Params;
%%
% Retrieve applications rates
landtype = Get_Land_Params;
% Reorder landtype here; way quicker:
landtype = CFTReorderLandType(landtype, LandOrder);

%%

% set values
% converters to get values in CO2
converterN_N2O=1.571428571;
N2O=296; 
CH4=25;
climate_NH3 = -0.402; %(CLIMATE IS SET TO TEMPERATE! SO CONSTANT!)
NH3_volatilisation=0.01;

% Allocate memory so as to be contiguous
CFT_Grid_Em=zeros(size(GridCells,1),length(landtype));


% From fertiliser_parameters
% (These might complain about growing arrays etc; for 6 land types this
% isn't a concern, for now.)
for lt = 1:length(landtype)
    exp_croptype_N2O(lt)=exp(landtype(lt).croptype_N2O);

    f1leach=landtype(lt).Nrate;
    fert1N2O=f1leach*fert(1).Bouwman_N2O;
    fert1NO=f1leach*fert(1).Bouwman_NO;
    
    f2leach=landtype(lt).P2O5rate*fert(2).N_concentration/fert(2).P2O5_concentration;
    fert2N2O=f2leach*fert(2).Bouwman_N2O;
    fert2NO=f2leach*fert(2).Bouwman_NO;

    f3leach=landtype(lt).K2Orate*fert(3).N_concentration/fert(3).K2O_concentration;
    fert3N2O=f3leach*fert(3).Bouwman_N2O;
    fert3NO=f3leach*fert(3).Bouwman_NO;

    f4leach=landtype(lt).CaOrate*fert(4).N_concentration/fert(4).CaO_concentration;
    fert4N2O=f4leach*fert(4).Bouwman_N2O;
    fert4NO=f4leach*fert(4).Bouwman_NO;
    
    sumFertN2O(lt)=fert1N2O+fert2N2O+fert3N2O+fert4N2O;
    sumFertNO(lt)=fert1NO+fert2NO+fert3NO+fert4NO;
    sumFertleach(lt)=f1leach+f2leach+f3leach+f4leach;
    

    ftmp=f1leach*exp(fert(1).Bouwman_NH3)+f2leach*exp(fert(2).Bouwman_NH3)+f3leach*exp(fert(3).Bouwman_NH3)+f4leach*exp(fert(4).Bouwman_NH3);
    sum_bg_NH3_fert_part(lt) = exp(climate_NH3+landtype(lt).croptype_NH3+landtype(lt).applic_method)*ftmp;
    
end

%% Main calculations for each grid cell
%soil_options = Get_Soil_Params2;

for i = 1:size(GridCells,1) % number of rows, i.e. grid cells
    % Get cell specific details
    % Variable called "s" as shorthand for "soil"
    % Grid( soil_texture, SOM,  soil_drainage, soil_pH, moisture)
    s = Get_Soil_Params(GridCells(i,:));

	%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate backgroud CO2 %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    sum_bg_N2O_part = -0.414+s.s_t_index_N2O+s.SOM_index_N2O+s.s_CEC_N2O+s.s_d_N2O+s.s_pH_N2O;
    sum_bg_NO_part = -1.527+s.s_t_index_NO+s.SOM_index_NO+s.s_CEC_NO+s.s_d_NO+s.s_pH_NO;
    sum_bg_NH3_cell_part = (s.s_t_index_NH3+s.SOM_index_NH3+s.s_d_NH3+s.s_pH_NH3+s.s_CEC_NH3);   
    
    % NB: croptype_NO is always zero
    bg_NO=0.01*exp(sum_bg_NO_part);
    bg_N2O=exp(sum_bg_N2O_part)*exp_croptype_N2O;
    bg_CO2=N2O*converterN_N2O*(bg_N2O+bg_NO);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate field emissions %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % FIE Totals:
    FIE_totals_N2O=bg_N2O.*(exp(sumFertN2O)-1);
    FIE_totals_NO=bg_NO.*(exp(sumFertNO)-1);
    FIE_totals_NH3=NH3_volatilisation*sum_bg_NH3_fert_part*exp(sum_bg_NH3_cell_part);

    % Leaching
    % Originally looked like:
        %if soil_moisture==1 
        %    leaching_parameter=0.3;
        %else leaching_parameter=0;
        %end
    % where soil_moisture was 1(moist) or 2(dry)
    % Have redone parameter to be 0(dry) or 1(moist); therefore:
    FIE_leaching=GridCells(i,5)*0.3*NH3_volatilisation*sumFertleach;

    % Sum emissions
    field_em=converterN_N2O*N2O*(FIE_totals_N2O+FIE_totals_NO+FIE_totals_NH3+FIE_leaching);

    % Append to output array
    CFT_Grid_Em(i,:) = bg_CO2+field_em;
end

end