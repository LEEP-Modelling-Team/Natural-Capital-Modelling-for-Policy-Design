function [landtype] = Get_Land_ParamsR4
% Define and return relevant land parameters
% 1 oilseed rape, 2 cereals, 3 root crops, 4 grassland with rough grazing,
% 5 permanent grassland, 6 temperate grassland, 7 other use

croptype_N2O=[-1.268,-1.242,-0.023,0,-2.536];
croptype_NH3=[-0.158,-0.158,-0.045,-0.045,0];
applic_method=[-1.292;-1.305;-1.844;-2.465;-1.895;-1.292];

landtype(1).LandType = 'Oilseed Rape';
landtype(1).ShortCode = 'osrape'; % to match up with Ag model
landtype(1).Nrate       = 191;
landtype(1).P2O5rate    = 58;
landtype(1).K2Orate     = 65;
landtype(1).CaOrate     = 4400;
landtype(1).croptype    =4;
landtype(1).cropspec    =31;
landtype(1).fresh_product = 3;
landtype(1).applications = 5;
landtype(1).application_method = 2;
landtype(1).method_crop_residue = 6;
landtype(1).croptype_N2O=croptype_N2O(landtype(1).croptype);
landtype(1).croptype_NH3=croptype_NH3(landtype(1).croptype);
landtype(1).applic_method=applic_method(landtype(1).application_method);

landtype(2).LandType = 'Cereals';
landtype(2).ShortCode = 'cer';
landtype(2).Nrate       = 146;
landtype(2).P2O5rate    = 54;
landtype(2).K2Orate     = 64;
landtype(2).CaOrate     = 4000;
landtype(2).croptype    =4;
landtype(2).cropspec    =24;
landtype(2).fresh_product = 3;
landtype(2).applications = 2;
landtype(2).application_method = 2;
landtype(2).method_crop_residue = 6;
landtype(2).croptype_N2O=croptype_N2O(landtype(2).croptype);
landtype(2).croptype_NH3=croptype_NH3(landtype(2).croptype);
landtype(2).applic_method=applic_method(landtype(2).application_method);


landtype(3).LandType = 'Root Crops';
landtype(3).ShortCode = 'root';
landtype(3).Nrate       = 129;
landtype(3).P2O5rate    = 95;
landtype(3).K2Orate     = 165;
landtype(3).CaOrate     = 0;
landtype(3).croptype    =4;
landtype(3).cropspec    =14;
landtype(3).fresh_product = 3;
landtype(3).applications = 8;
landtype(3).application_method = 2;
landtype(3).method_crop_residue = 6;
landtype(3).croptype_N2O=croptype_N2O(landtype(3).croptype);
landtype(3).croptype_NH3=croptype_NH3(landtype(3).croptype);
landtype(3).applic_method=applic_method(landtype(3).application_method);

landtype(4).LandType = 'Rough Grazing';
landtype(4).ShortCode = 'rgraz';
landtype(4).Nrate       = 0;
landtype(4).P2O5rate    = 0;
landtype(4).K2Orate     = 0;
landtype(4).CaOrate     = 0;
landtype(4).croptype    =2;
landtype(4).cropspec    =8;
landtype(4).fresh_product = 3;
landtype(4).applications = 0;
landtype(4).application_method = 3;
landtype(4).method_crop_residue = 6;
landtype(4).croptype_N2O=croptype_N2O(landtype(4).croptype);
landtype(4).croptype_NH3=croptype_NH3(landtype(4).croptype);
landtype(4).applic_method=applic_method(landtype(4).application_method);


landtype(5).LandType = 'Perm Grass';
landtype(5).ShortCode = 'pgrass';
landtype(5).Nrate       = 85;
landtype(5).P2O5rate    = 21;
landtype(5).K2Orate     = 25;
landtype(5).CaOrate     = 4300;
landtype(5).croptype    =1;
landtype(5).cropspec    =13;
landtype(5).fresh_product = 3;
landtype(5).applications = 6;
landtype(5).application_method = 2;
landtype(5).method_crop_residue = 6;
landtype(5).croptype_N2O=croptype_N2O(landtype(5).croptype);
landtype(5).croptype_NH3=croptype_NH3(landtype(5).croptype);
landtype(5).applic_method=applic_method(landtype(5).application_method);


landtype(6).LandType = 'Temp Grass';
landtype(6).ShortCode = 'tgrass';
landtype(6).Nrate       = 118;
landtype(6).P2O5rate    = 27;
landtype(6).K2Orate     = 41;
landtype(6).CaOrate     = 4600;
landtype(6).croptype    =1;
landtype(6).cropspec    =13;
landtype(6).fresh_product = 3;
landtype(6).applications = 6;
landtype(6).application_method = 2;
landtype(6).method_crop_residue = 6;
landtype(6).croptype_N2O=croptype_N2O(landtype(6).croptype);
landtype(6).croptype_NH3=croptype_NH3(landtype(6).croptype);
landtype(6).applic_method=applic_method(landtype(6).application_method);

end