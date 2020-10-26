function [fert] = Get_Fert_Params

% fertiliser 1  - Ammonium nitrate - 35% N
        fert(1).name='Ammonium nitrate - 35% N';
        fert(1).N_concentration=0.35;
        fert(1).EFMA=0.96;                  %new technik, values from 2011
        fert(1).Bouwman_N2O=0.0061;
        fert(1).Bouwman_NO=0.004;
        fert(1).Bouwman_NH3=-0.35;        
     
% fertiliser 2  -  Triple super phosphate - 48% P2O5
        fert(2).name='Triple super phosphate - 48% P2O5';
        fert(2).N_concentration=0;
        fert(2).P_concentration=0.2093;
        fert(2).P2O5_concentration=0.48;
        fert(2).EFMA=0.35;                  %new technik, values from 2011
        fert(2).Bouwman_N2O=0;
        fert(2).Bouwman_NO=0;
        fert(2).Bouwman_NH3=0;
        
        
% fertiliser 3  -  Muriate of potash / Potassium Chloride - 60% K2O
        fert(3).name='Muriate of potash / Potassium Chloride - 60% K2O';
        fert(3).N_concentration=0;
        fert(3).K_concentration=0.4957;
        fert(3).K2O_concentration=0.6;
        fert(3).EFMA=0.36;                  %new technik, values from 2011
        fert(3).Bouwman_N2O=0;
        fert(3).Bouwman_NO=0;
        fert(3).Bouwman_NH3=0;    
        

% fertiliser 4  -  Lime - 52% CaO
        fert(4).name='Lime - 52% CaO';
        fert(4).N_concentration=0;
        fert(4).CaO_concentration=0.52;
        fert(4).EFMA=0.1;                  %current technik, values from 2006
        fert(4).Bouwman_N2O=0;
        fert(4).Bouwman_NO=0;
        fert(4).Bouwman_NH3=0;
        
end