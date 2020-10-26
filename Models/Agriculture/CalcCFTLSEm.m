function [CFT_LS_Em] = CalcCFTLSEm(CellTemp,LSOrder,TempFactor)
% Calculate, then sort for matrix multiplication:
  % Internally:
  % 1 Dairy
  % 2 Beef
  % 3 Sheep
  
%% Constants in kg C0_2 eq per head per year
 const(1)=4584.5;
 const(2)=1963.4;
 const(3)=299.2;

% NEA 2 (not FO):
%  const(1)=3022.791634;%117*25+296*105.12*44*0.002/28
%  const(2)=1458.615874;%57*25+296*36.135*44*0.002/28
%  const(3)=387.6037429;%8*25+296*20.16625*44*0.02/28
  
  
%% Temperature Dependent  
% Get into range:
CellTemp=max(min(round(CellTemp),26),1);
% These now give row index in CFT.TempFactor
tempfac=TempFactor(CellTemp,2:end);
% Total
CFT_LS_Em = bsxfun(@plus,const,25*tempfac);

  
end



%% Reorder and return
% Match order to headings:
    
% DAIRY
% BEEF
% SHEEP
% STRMATCH DEPRECATED. SWITCH ALL TO USE STRCMP AND FIND COMBO
  %loc(i)=strmatch(FieldOrder(i),Headings.Ag_Cells,'exact');