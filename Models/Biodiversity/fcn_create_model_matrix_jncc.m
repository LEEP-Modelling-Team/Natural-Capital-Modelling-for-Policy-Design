function model_matrix = fcn_create_model_matrix_jncc(data_cells, climate_cells, PV, out, decade_string)

    %% (1) PROCESS INPUT DATA FOR CURRENT DECADE
    %  =========================================
    % Processed variables added to Bio structure

    % a. data_cells table
    % -------------------
    % NB. Variables in hectares divided by 4
    Bio.const = data_cells.const;
    Bio.COAST = data_cells.coast_ha ./ 4;
    Bio.FWATER = data_cells.fwater_ha ./ 4;
    Bio.MARINE = data_cells.marine_ha ./ 4;
    Bio.avElev = data_cells.avelev_cell;
    Bio.aspect = data_cells.aspect;
    Bio.clay = data_cells.pca_clay;
    Bio.urb_lake = data_cells.pca_urb_lake;
    Bio.l_sand = data_cells.pca_l_sand;
    Bio.loam = data_cells.pca_loam;
    Bio.s_loam = data_cells.pca_s_loam;
    Bio.clay_loam = data_cells.pca_clay_loam;
    Bio.sand = data_cells.pca_sand;
    Bio.silt_loam = data_cells.pca_silt_loam;
    Bio.ph1 = data_cells.pca_ph1;
    Bio.ph2 = data_cells.pca_ph2;
    Bio.ph3 = data_cells.pca_ph3;
    Bio.ph4 = data_cells.pca_ph4;
    Bio.SW1 = data_cells.pca_sw1;
    Bio.SW2 = data_cells.pca_sw2;
    Bio.SW3 = data_cells.pca_sw3;
    Bio.SW4 = data_cells.pca_sw4;

    % b. PV structure
    % ---------------
    % NB. Variables in hectares divided by 4
    Bio.URBAN = PV.urban_ha ./ 4;
    Bio.GRSNFRM = PV.sngrass_ha ./ 4;
    Bio.WOOD = PV.wood_ha ./ 4;

    % c. out structure
    % ----------------
    % NB. Variables in hectares divided by 4
    % NB. other_ha split into different crops using PV structure
    Bio.RGRAZ = eval(['out.rgraz_ha',decade_string,' ./ 4']);
    Bio.POTS = eval(['out.pot_ha',decade_string,' ./ 4']);
    Bio.MAIZE = eval(['(PV.p_maize .* out.other_ha',decade_string,') ./ 4']);
    Bio.HORT = eval(['(PV.p_hort .* out.other_ha',decade_string,') ./ 4']);
    Bio.SUGARBEET = eval(['out.sb_ha',decade_string,' ./ 4']);
    Bio.IMPGR = eval(['(out.pgrass_ha',decade_string,' + out.tgrass_ha' decade_string ') ./ 4']);
    Bio.CerOSR = eval(['(PV.p_othcer .* out.other_ha',decade_string,' + out.wheat_ha',decade_string,' + out.osr_ha',decade_string,' + out.wbar_ha',decade_string,' + out.sbar_ha',decade_string,') ./ 4']);

    % d. climate_cells table
    % ----------------------
    Bio.rain = eval(['climate_cells.rain',decade_string]);
    Bio.bio3 = eval(['climate_cells.bio3',decade_string]);
    Bio.bio8 = eval(['climate_cells.bio8',decade_string]);
    Bio.bio9 = eval(['climate_cells.bio9',decade_string]);
    Bio.bio7 = eval(['climate_cells.bio7',decade_string]);
    Bio.bio10 = eval(['climate_cells.bio10',decade_string]);
    Bio.bio11 = eval(['climate_cells.bio11',decade_string]);

    %% (2) CREATE ADDITIONAL REGRESSION VARIABLES
    %  ==========================================

    % a. Squared terms
    % ----------------
    Bio.sqCOAST = Bio.COAST .* Bio.COAST;
    Bio.sqFWATER = Bio.FWATER .* Bio.FWATER;
    Bio.sqMARINE = Bio.MARINE .* Bio.MARINE;
    Bio.sqURBAN = Bio.URBAN .* Bio.URBAN;
    Bio.sqRGRAZ = Bio.RGRAZ .* Bio.RGRAZ;
    Bio.sqGRSNFRM = Bio.GRSNFRM .* Bio.GRSNFRM;
    Bio.sqPOTS = Bio.POTS .* Bio.POTS;
    Bio.sqMAIZE = Bio.MAIZE .* Bio.MAIZE;
    Bio.sqHORT = Bio.HORT .* Bio.HORT;
    Bio.sqSUGARBEET = Bio.SUGARBEET .* Bio.SUGARBEET;
    Bio.sqIMPGR = Bio.IMPGR .* Bio.IMPGR;
    Bio.sqWOOD = Bio.WOOD .* Bio.WOOD;
    Bio.sqCerOSR = Bio.CerOSR .* Bio.CerOSR;
    Bio.sqbio3 = Bio.bio3 .* Bio.bio3;
    Bio.sqbio8 = Bio.bio8 .* Bio.bio8;
    Bio.sqbio9 = Bio.bio9 .* Bio.bio9;
    Bio.sqbio7 = Bio.bio7 .* Bio.bio7;
    Bio.sqbio10 = Bio.bio10 .* Bio.bio10;
    Bio.sqbio11 = Bio.bio11 .* Bio.bio11;
    Bio.sqrain = Bio.rain .* Bio.rain;
    Bio.sqavElev = Bio.avElev .* Bio.avElev;
    Bio.sqaspect = Bio.aspect .* Bio.aspect;
    Bio.sqclay = Bio.clay .* Bio.clay;
    Bio.squrb_lake = Bio.urb_lake .* Bio.urb_lake;
    Bio.sql_sand = Bio.l_sand .* Bio.l_sand;
    Bio.sqloam = Bio.loam .* Bio.loam;
    Bio.sqs_loam = Bio.s_loam .* Bio.s_loam;
    Bio.sqclay_loam = Bio.clay_loam .* Bio.clay_loam;
    Bio.sqsand = Bio.sand .* Bio.sand;
    Bio.sqsilt_loam = Bio.silt_loam .* Bio.silt_loam;
    Bio.sqph1 = Bio.ph1 .* Bio.ph1;
    Bio.sqph2 = Bio.ph2 .* Bio.ph2;
    Bio.sqph3 = Bio.ph3 .* Bio.ph3;
    Bio.sqph4 = Bio.ph4 .* Bio.ph4;
    Bio.sqSW1 = Bio.SW1 .* Bio.SW1;
    Bio.sqSW2 = Bio.SW2 .* Bio.SW2;
    Bio.sqSW3 = Bio.SW3 .* Bio.SW3;
    Bio.sqSW4 = Bio.SW4 .* Bio.SW4;
    
    % b. First order interaction terms
    % --------------------------------
    Bio.COAST_FWATER = Bio.COAST .* Bio.FWATER;
    Bio.COAST_MARINE = Bio.COAST .* Bio.MARINE;
    Bio.COAST_URBAN = Bio.COAST .* Bio.URBAN;
    Bio.COAST_RGRAZ = Bio.COAST .* Bio.RGRAZ;
    Bio.COAST_GRSNFRM = Bio.COAST .* Bio.GRSNFRM;
    Bio.COAST_POTS = Bio.COAST .* Bio.POTS;
    Bio.COAST_MAIZE = Bio.COAST .* Bio.MAIZE;
    Bio.COAST_HORT = Bio.COAST .* Bio.HORT;
    Bio.COAST_SUGARBEET = Bio.COAST .* Bio.SUGARBEET;
    Bio.COAST_IMPGR = Bio.COAST .* Bio.IMPGR;
    Bio.COAST_WOOD = Bio.COAST .* Bio.WOOD;
    Bio.COAST_CerOSR = Bio.COAST .* Bio.CerOSR;
    Bio.COAST_bio3 = Bio.COAST .* Bio.bio3;
    Bio.COAST_bio8 = Bio.COAST .* Bio.bio8;
    Bio.COAST_bio9 = Bio.COAST .* Bio.bio9;
    Bio.COAST_bio7 = Bio.COAST .* Bio.bio7;
    Bio.COAST_bio10 = Bio.COAST .* Bio.bio10;
    Bio.COAST_bio11 = Bio.COAST .* Bio.bio11;
    Bio.COAST_rain = Bio.COAST .* Bio.rain;
    Bio.COAST_avElev = Bio.COAST .* Bio.avElev;
    Bio.COAST_aspect = Bio.COAST .* Bio.aspect;
    Bio.COAST_clay = Bio.COAST .* Bio.clay;
    Bio.COAST_urb_lake = Bio.COAST .* Bio.urb_lake;
    Bio.COAST_l_sand = Bio.COAST .* Bio.l_sand;
    Bio.COAST_loam = Bio.COAST .* Bio.loam;
    Bio.COAST_s_loam = Bio.COAST .* Bio.s_loam;
    Bio.COAST_clay_loam = Bio.COAST .* Bio.clay_loam;
    Bio.COAST_sand = Bio.COAST .* Bio.sand;
    Bio.COAST_silt_loam = Bio.COAST .* Bio.silt_loam;
    Bio.COAST_ph1 = Bio.COAST .* Bio.ph1;
    Bio.COAST_ph2 = Bio.COAST .* Bio.ph2;
    Bio.COAST_ph3 = Bio.COAST .* Bio.ph3;
    Bio.COAST_ph4 = Bio.COAST .* Bio.ph4;
    Bio.COAST_SW1 = Bio.COAST .* Bio.SW1;
    Bio.COAST_SW2 = Bio.COAST .* Bio.SW2;
    Bio.COAST_SW3 = Bio.COAST .* Bio.SW3;
    Bio.COAST_SW4 = Bio.COAST .* Bio.SW4;
    Bio.FWATER_MARINE = Bio.FWATER .* Bio.MARINE;
    Bio.FWATER_URBAN = Bio.FWATER .* Bio.URBAN;
    Bio.FWATER_RGRAZ = Bio.FWATER .* Bio.RGRAZ;
    Bio.FWATER_GRSNFRM = Bio.FWATER .* Bio.GRSNFRM;
    Bio.FWATER_POTS = Bio.FWATER .* Bio.POTS;
    Bio.FWATER_MAIZE = Bio.FWATER .* Bio.MAIZE;
    Bio.FWATER_HORT = Bio.FWATER .* Bio.HORT;
    Bio.FWATER_SUGARBEET = Bio.FWATER .* Bio.SUGARBEET;
    Bio.FWATER_IMPGR = Bio.FWATER .* Bio.IMPGR;
    Bio.FWATER_WOOD = Bio.FWATER .* Bio.WOOD;
    Bio.FWATER_CerOSR = Bio.FWATER .* Bio.CerOSR;
    Bio.FWATER_bio3 = Bio.FWATER .* Bio.bio3;
    Bio.FWATER_bio8 = Bio.FWATER .* Bio.bio8;
    Bio.FWATER_bio9 = Bio.FWATER .* Bio.bio9;
    Bio.FWATER_bio7 = Bio.FWATER .* Bio.bio7;
    Bio.FWATER_bio10 = Bio.FWATER .* Bio.bio10;
    Bio.FWATER_bio11 = Bio.FWATER .* Bio.bio11;
    Bio.FWATER_rain = Bio.FWATER .* Bio.rain;
    Bio.FWATER_avElev = Bio.FWATER .* Bio.avElev;
    Bio.FWATER_aspect = Bio.FWATER .* Bio.aspect;
    Bio.FWATER_clay = Bio.FWATER .* Bio.clay;
    Bio.FWATER_urb_lake = Bio.FWATER .* Bio.urb_lake;
    Bio.FWATER_l_sand = Bio.FWATER .* Bio.l_sand;
    Bio.FWATER_loam = Bio.FWATER .* Bio.loam;
    Bio.FWATER_s_loam = Bio.FWATER .* Bio.s_loam;
    Bio.FWATER_clay_loam = Bio.FWATER .* Bio.clay_loam;
    Bio.FWATER_sand = Bio.FWATER .* Bio.sand;
    Bio.FWATER_silt_loam = Bio.FWATER .* Bio.silt_loam;
    Bio.FWATER_ph1 = Bio.FWATER .* Bio.ph1;
    Bio.FWATER_ph2 = Bio.FWATER .* Bio.ph2;
    Bio.FWATER_ph3 = Bio.FWATER .* Bio.ph3;
    Bio.FWATER_ph4 = Bio.FWATER .* Bio.ph4;
    Bio.FWATER_SW1 = Bio.FWATER .* Bio.SW1;
    Bio.FWATER_SW2 = Bio.FWATER .* Bio.SW2;
    Bio.FWATER_SW3 = Bio.FWATER .* Bio.SW3;
    Bio.FWATER_SW4 = Bio.FWATER .* Bio.SW4;
    Bio.MARINE_URBAN = Bio.MARINE .* Bio.URBAN;
    Bio.MARINE_RGRAZ = Bio.MARINE .* Bio.RGRAZ;
    Bio.MARINE_GRSNFRM = Bio.MARINE .* Bio.GRSNFRM;
    Bio.MARINE_POTS = Bio.MARINE .* Bio.POTS;
    Bio.MARINE_MAIZE = Bio.MARINE .* Bio.MAIZE;
    Bio.MARINE_HORT = Bio.MARINE .* Bio.HORT;
    Bio.MARINE_SUGARBEET = Bio.MARINE .* Bio.SUGARBEET;
    Bio.MARINE_IMPGR = Bio.MARINE .* Bio.IMPGR;
    Bio.MARINE_WOOD = Bio.MARINE .* Bio.WOOD;
    Bio.MARINE_CerOSR = Bio.MARINE .* Bio.CerOSR;
    Bio.MARINE_bio3 = Bio.MARINE .* Bio.bio3;
    Bio.MARINE_bio8 = Bio.MARINE .* Bio.bio8;
    Bio.MARINE_bio9 = Bio.MARINE .* Bio.bio9;
    Bio.MARINE_bio7 = Bio.MARINE .* Bio.bio7;
    Bio.MARINE_bio10 = Bio.MARINE .* Bio.bio10;
    Bio.MARINE_bio11 = Bio.MARINE .* Bio.bio11;
    Bio.MARINE_rain = Bio.MARINE .* Bio.rain;
    Bio.MARINE_avElev = Bio.MARINE .* Bio.avElev;
    Bio.MARINE_aspect = Bio.MARINE .* Bio.aspect;
    Bio.MARINE_clay = Bio.MARINE .* Bio.clay;
    Bio.MARINE_urb_lake = Bio.MARINE .* Bio.urb_lake;
    Bio.MARINE_l_sand = Bio.MARINE .* Bio.l_sand;
    Bio.MARINE_loam = Bio.MARINE .* Bio.loam;
    Bio.MARINE_s_loam = Bio.MARINE .* Bio.s_loam;
    Bio.MARINE_clay_loam = Bio.MARINE .* Bio.clay_loam;
    Bio.MARINE_sand = Bio.MARINE .* Bio.sand;
    Bio.MARINE_silt_loam = Bio.MARINE .* Bio.silt_loam;
    Bio.MARINE_ph1 = Bio.MARINE .* Bio.ph1;
    Bio.MARINE_ph2 = Bio.MARINE .* Bio.ph2;
    Bio.MARINE_ph3 = Bio.MARINE .* Bio.ph3;
    Bio.MARINE_ph4 = Bio.MARINE .* Bio.ph4;
    Bio.MARINE_SW1 = Bio.MARINE .* Bio.SW1;
    Bio.MARINE_SW2 = Bio.MARINE .* Bio.SW2;
    Bio.MARINE_SW3 = Bio.MARINE .* Bio.SW3;
    Bio.MARINE_SW4 = Bio.MARINE .* Bio.SW4;
    Bio.URBAN_RGRAZ = Bio.URBAN .* Bio.RGRAZ;
    Bio.URBAN_GRSNFRM = Bio.URBAN .* Bio.GRSNFRM;
    Bio.URBAN_POTS = Bio.URBAN .* Bio.POTS;
    Bio.URBAN_MAIZE = Bio.URBAN .* Bio.MAIZE;
    Bio.URBAN_HORT = Bio.URBAN .* Bio.HORT;
    Bio.URBAN_SUGARBEET = Bio.URBAN .* Bio.SUGARBEET;
    Bio.URBAN_IMPGR = Bio.URBAN .* Bio.IMPGR;
    Bio.URBAN_WOOD = Bio.URBAN .* Bio.WOOD;
    Bio.URBAN_CerOSR = Bio.URBAN .* Bio.CerOSR;
    Bio.URBAN_bio3 = Bio.URBAN .* Bio.bio3;
    Bio.URBAN_bio8 = Bio.URBAN .* Bio.bio8;
    Bio.URBAN_bio9 = Bio.URBAN .* Bio.bio9;
    Bio.URBAN_bio7 = Bio.URBAN .* Bio.bio7;
    Bio.URBAN_bio10 = Bio.URBAN .* Bio.bio10;
    Bio.URBAN_bio11 = Bio.URBAN .* Bio.bio11;
    Bio.URBAN_rain = Bio.URBAN .* Bio.rain;
    Bio.URBAN_avElev = Bio.URBAN .* Bio.avElev;
    Bio.URBAN_aspect = Bio.URBAN .* Bio.aspect;
    Bio.URBAN_clay = Bio.URBAN .* Bio.clay;
    Bio.URBAN_urb_lake = Bio.URBAN .* Bio.urb_lake;
    Bio.URBAN_l_sand = Bio.URBAN .* Bio.l_sand;
    Bio.URBAN_loam = Bio.URBAN .* Bio.loam;
    Bio.URBAN_s_loam = Bio.URBAN .* Bio.s_loam;
    Bio.URBAN_clay_loam = Bio.URBAN .* Bio.clay_loam;
    Bio.URBAN_sand = Bio.URBAN .* Bio.sand;
    Bio.URBAN_silt_loam = Bio.URBAN .* Bio.silt_loam;
    Bio.URBAN_ph1 = Bio.URBAN .* Bio.ph1;
    Bio.URBAN_ph2 = Bio.URBAN .* Bio.ph2;
    Bio.URBAN_ph3 = Bio.URBAN .* Bio.ph3;
    Bio.URBAN_ph4 = Bio.URBAN .* Bio.ph4;
    Bio.URBAN_SW1 = Bio.URBAN .* Bio.SW1;
    Bio.URBAN_SW2 = Bio.URBAN .* Bio.SW2;
    Bio.URBAN_SW3 = Bio.URBAN .* Bio.SW3;
    Bio.URBAN_SW4 = Bio.URBAN .* Bio.SW4;
    Bio.RGRAZ_GRSNFRM = Bio.RGRAZ .* Bio.GRSNFRM;
    Bio.RGRAZ_POTS = Bio.RGRAZ .* Bio.POTS;
    Bio.RGRAZ_MAIZE = Bio.RGRAZ .* Bio.MAIZE;
    Bio.RGRAZ_HORT = Bio.RGRAZ .* Bio.HORT;
    Bio.RGRAZ_SUGARBEET = Bio.RGRAZ .* Bio.SUGARBEET;
    Bio.RGRAZ_IMPGR = Bio.RGRAZ .* Bio.IMPGR;
    Bio.RGRAZ_WOOD = Bio.RGRAZ .* Bio.WOOD;
    Bio.RGRAZ_CerOSR = Bio.RGRAZ .* Bio.CerOSR;
    Bio.RGRAZ_bio3 = Bio.RGRAZ .* Bio.bio3;
    Bio.RGRAZ_bio8 = Bio.RGRAZ .* Bio.bio8;
    Bio.RGRAZ_bio9 = Bio.RGRAZ .* Bio.bio9;
    Bio.RGRAZ_bio7 = Bio.RGRAZ .* Bio.bio7;
    Bio.RGRAZ_bio10 = Bio.RGRAZ .* Bio.bio10;
    Bio.RGRAZ_bio11 = Bio.RGRAZ .* Bio.bio11;
    Bio.RGRAZ_rain = Bio.RGRAZ .* Bio.rain;
    Bio.RGRAZ_avElev = Bio.RGRAZ .* Bio.avElev;
    Bio.RGRAZ_aspect = Bio.RGRAZ .* Bio.aspect;
    Bio.RGRAZ_clay = Bio.RGRAZ .* Bio.clay;
    Bio.RGRAZ_urb_lake = Bio.RGRAZ .* Bio.urb_lake;
    Bio.RGRAZ_l_sand = Bio.RGRAZ .* Bio.l_sand;
    Bio.RGRAZ_loam = Bio.RGRAZ .* Bio.loam;
    Bio.RGRAZ_s_loam = Bio.RGRAZ .* Bio.s_loam;
    Bio.RGRAZ_clay_loam = Bio.RGRAZ .* Bio.clay_loam;
    Bio.RGRAZ_sand = Bio.RGRAZ .* Bio.sand;
    Bio.RGRAZ_silt_loam = Bio.RGRAZ .* Bio.silt_loam;
    Bio.RGRAZ_ph1 = Bio.RGRAZ .* Bio.ph1;
    Bio.RGRAZ_ph2 = Bio.RGRAZ .* Bio.ph2;
    Bio.RGRAZ_ph3 = Bio.RGRAZ .* Bio.ph3;
    Bio.RGRAZ_ph4 = Bio.RGRAZ .* Bio.ph4;
    Bio.RGRAZ_SW1 = Bio.RGRAZ .* Bio.SW1;
    Bio.RGRAZ_SW2 = Bio.RGRAZ .* Bio.SW2;
    Bio.RGRAZ_SW3 = Bio.RGRAZ .* Bio.SW3;
    Bio.RGRAZ_SW4 = Bio.RGRAZ .* Bio.SW4;
    Bio.GRSNFRM_POTS = Bio.GRSNFRM .* Bio.POTS;
    Bio.GRSNFRM_MAIZE = Bio.GRSNFRM .* Bio.MAIZE;
    Bio.GRSNFRM_HORT = Bio.GRSNFRM .* Bio.HORT;
    Bio.GRSNFRM_SUGARBEET = Bio.GRSNFRM .* Bio.SUGARBEET;
    Bio.GRSNFRM_IMPGR = Bio.GRSNFRM .* Bio.IMPGR;
    Bio.GRSNFRM_WOOD = Bio.GRSNFRM .* Bio.WOOD;
    Bio.GRSNFRM_CerOSR = Bio.GRSNFRM .* Bio.CerOSR;
    Bio.GRSNFRM_bio3 = Bio.GRSNFRM .* Bio.bio3;
    Bio.GRSNFRM_bio8 = Bio.GRSNFRM .* Bio.bio8;
    Bio.GRSNFRM_bio9 = Bio.GRSNFRM .* Bio.bio9;
    Bio.GRSNFRM_bio7 = Bio.GRSNFRM .* Bio.bio7;
    Bio.GRSNFRM_bio10 = Bio.GRSNFRM .* Bio.bio10;
    Bio.GRSNFRM_bio11 = Bio.GRSNFRM .* Bio.bio11;
    Bio.GRSNFRM_rain = Bio.GRSNFRM .* Bio.rain;
    Bio.GRSNFRM_avElev = Bio.GRSNFRM .* Bio.avElev;
    Bio.GRSNFRM_aspect = Bio.GRSNFRM .* Bio.aspect;
    Bio.GRSNFRM_clay = Bio.GRSNFRM .* Bio.clay;
    Bio.GRSNFRM_urb_lake = Bio.GRSNFRM .* Bio.urb_lake;
    Bio.GRSNFRM_l_sand = Bio.GRSNFRM .* Bio.l_sand;
    Bio.GRSNFRM_loam = Bio.GRSNFRM .* Bio.loam;
    Bio.GRSNFRM_s_loam = Bio.GRSNFRM .* Bio.s_loam;
    Bio.GRSNFRM_clay_loam = Bio.GRSNFRM .* Bio.clay_loam;
    Bio.GRSNFRM_sand = Bio.GRSNFRM .* Bio.sand;
    Bio.GRSNFRM_silt_loam = Bio.GRSNFRM .* Bio.silt_loam;
    Bio.GRSNFRM_ph1 = Bio.GRSNFRM .* Bio.ph1;
    Bio.GRSNFRM_ph2 = Bio.GRSNFRM .* Bio.ph2;
    Bio.GRSNFRM_ph3 = Bio.GRSNFRM .* Bio.ph3;
    Bio.GRSNFRM_ph4 = Bio.GRSNFRM .* Bio.ph4;
    Bio.GRSNFRM_SW1 = Bio.GRSNFRM .* Bio.SW1;
    Bio.GRSNFRM_SW2 = Bio.GRSNFRM .* Bio.SW2;
    Bio.GRSNFRM_SW3 = Bio.GRSNFRM .* Bio.SW3;
    Bio.GRSNFRM_SW4 = Bio.GRSNFRM .* Bio.SW4;
    Bio.POTS_MAIZE = Bio.POTS .* Bio.MAIZE;
    Bio.POTS_HORT = Bio.POTS .* Bio.HORT;
    Bio.POTS_SUGARBEET = Bio.POTS .* Bio.SUGARBEET;
    Bio.POTS_IMPGR = Bio.POTS .* Bio.IMPGR;
    Bio.POTS_WOOD = Bio.POTS .* Bio.WOOD;
    Bio.POTS_CerOSR = Bio.POTS .* Bio.CerOSR;
    Bio.POTS_bio3 = Bio.POTS .* Bio.bio3;
    Bio.POTS_bio8 = Bio.POTS .* Bio.bio8;
    Bio.POTS_bio9 = Bio.POTS .* Bio.bio9;
    Bio.POTS_bio7 = Bio.POTS .* Bio.bio7;
    Bio.POTS_bio10 = Bio.POTS .* Bio.bio10;
    Bio.POTS_bio11 = Bio.POTS .* Bio.bio11;
    Bio.POTS_rain = Bio.POTS .* Bio.rain;
    Bio.POTS_avElev = Bio.POTS .* Bio.avElev;
    Bio.POTS_aspect = Bio.POTS .* Bio.aspect;
    Bio.POTS_clay = Bio.POTS .* Bio.clay;
    Bio.POTS_urb_lake = Bio.POTS .* Bio.urb_lake;
    Bio.POTS_l_sand = Bio.POTS .* Bio.l_sand;
    Bio.POTS_loam = Bio.POTS .* Bio.loam;
    Bio.POTS_s_loam = Bio.POTS .* Bio.s_loam;
    Bio.POTS_clay_loam = Bio.POTS .* Bio.clay_loam;
    Bio.POTS_sand = Bio.POTS .* Bio.sand;
    Bio.POTS_silt_loam = Bio.POTS .* Bio.silt_loam;
    Bio.POTS_ph1 = Bio.POTS .* Bio.ph1;
    Bio.POTS_ph2 = Bio.POTS .* Bio.ph2;
    Bio.POTS_ph3 = Bio.POTS .* Bio.ph3;
    Bio.POTS_ph4 = Bio.POTS .* Bio.ph4;
    Bio.POTS_SW1 = Bio.POTS .* Bio.SW1;
    Bio.POTS_SW2 = Bio.POTS .* Bio.SW2;
    Bio.POTS_SW3 = Bio.POTS .* Bio.SW3;
    Bio.POTS_SW4 = Bio.POTS .* Bio.SW4;
    Bio.MAIZE_HORT = Bio.MAIZE .* Bio.HORT;
    Bio.MAIZE_SUGARBEET = Bio.MAIZE .* Bio.SUGARBEET;
    Bio.MAIZE_IMPGR = Bio.MAIZE .* Bio.IMPGR;
    Bio.MAIZE_WOOD = Bio.MAIZE .* Bio.WOOD;
    Bio.MAIZE_CerOSR = Bio.MAIZE .* Bio.CerOSR;
    Bio.MAIZE_bio3 = Bio.MAIZE .* Bio.bio3;
    Bio.MAIZE_bio8 = Bio.MAIZE .* Bio.bio8;
    Bio.MAIZE_bio9 = Bio.MAIZE .* Bio.bio9;
    Bio.MAIZE_bio7 = Bio.MAIZE .* Bio.bio7;
    Bio.MAIZE_bio10 = Bio.MAIZE .* Bio.bio10;
    Bio.MAIZE_bio11 = Bio.MAIZE .* Bio.bio11;
    Bio.MAIZE_rain = Bio.MAIZE .* Bio.rain;
    Bio.MAIZE_avElev = Bio.MAIZE .* Bio.avElev;
    Bio.MAIZE_aspect = Bio.MAIZE .* Bio.aspect;
    Bio.MAIZE_clay = Bio.MAIZE .* Bio.clay;
    Bio.MAIZE_urb_lake = Bio.MAIZE .* Bio.urb_lake;
    Bio.MAIZE_l_sand = Bio.MAIZE .* Bio.l_sand;
    Bio.MAIZE_loam = Bio.MAIZE .* Bio.loam;
    Bio.MAIZE_s_loam = Bio.MAIZE .* Bio.s_loam;
    Bio.MAIZE_clay_loam = Bio.MAIZE .* Bio.clay_loam;
    Bio.MAIZE_sand = Bio.MAIZE .* Bio.sand;
    Bio.MAIZE_silt_loam = Bio.MAIZE .* Bio.silt_loam;
    Bio.MAIZE_ph1 = Bio.MAIZE .* Bio.ph1;
    Bio.MAIZE_ph2 = Bio.MAIZE .* Bio.ph2;
    Bio.MAIZE_ph3 = Bio.MAIZE .* Bio.ph3;
    Bio.MAIZE_ph4 = Bio.MAIZE .* Bio.ph4;
    Bio.MAIZE_SW1 = Bio.MAIZE .* Bio.SW1;
    Bio.MAIZE_SW2 = Bio.MAIZE .* Bio.SW2;
    Bio.MAIZE_SW3 = Bio.MAIZE .* Bio.SW3;
    Bio.MAIZE_SW4 = Bio.MAIZE .* Bio.SW4;
    Bio.HORT_SUGARBEET = Bio.HORT .* Bio.SUGARBEET;
    Bio.HORT_IMPGR = Bio.HORT .* Bio.IMPGR;
    Bio.HORT_WOOD = Bio.HORT .* Bio.WOOD;
    Bio.HORT_CerOSR = Bio.HORT .* Bio.CerOSR;
    Bio.HORT_bio3 = Bio.HORT .* Bio.bio3;
    Bio.HORT_bio8 = Bio.HORT .* Bio.bio8;
    Bio.HORT_bio9 = Bio.HORT .* Bio.bio9;
    Bio.HORT_bio7 = Bio.HORT .* Bio.bio7;
    Bio.HORT_bio10 = Bio.HORT .* Bio.bio10;
    Bio.HORT_bio11 = Bio.HORT .* Bio.bio11;
    Bio.HORT_rain = Bio.HORT .* Bio.rain;
    Bio.HORT_avElev = Bio.HORT .* Bio.avElev;
    Bio.HORT_aspect = Bio.HORT .* Bio.aspect;
    Bio.HORT_clay = Bio.HORT .* Bio.clay;
    Bio.HORT_urb_lake = Bio.HORT .* Bio.urb_lake;
    Bio.HORT_l_sand = Bio.HORT .* Bio.l_sand;
    Bio.HORT_loam = Bio.HORT .* Bio.loam;
    Bio.HORT_s_loam = Bio.HORT .* Bio.s_loam;
    Bio.HORT_clay_loam = Bio.HORT .* Bio.clay_loam;
    Bio.HORT_sand = Bio.HORT .* Bio.sand;
    Bio.HORT_silt_loam = Bio.HORT .* Bio.silt_loam;
    Bio.HORT_ph1 = Bio.HORT .* Bio.ph1;
    Bio.HORT_ph2 = Bio.HORT .* Bio.ph2;
    Bio.HORT_ph3 = Bio.HORT .* Bio.ph3;
    Bio.HORT_ph4 = Bio.HORT .* Bio.ph4;
    Bio.HORT_SW1 = Bio.HORT .* Bio.SW1;
    Bio.HORT_SW2 = Bio.HORT .* Bio.SW2;
    Bio.HORT_SW3 = Bio.HORT .* Bio.SW3;
    Bio.HORT_SW4 = Bio.HORT .* Bio.SW4;
    Bio.SUGARBEET_IMPGR = Bio.SUGARBEET .* Bio.IMPGR;
    Bio.SUGARBEET_WOOD = Bio.SUGARBEET .* Bio.WOOD;
    Bio.SUGARBEET_CerOSR = Bio.SUGARBEET .* Bio.CerOSR;
    Bio.SUGARBEET_bio3 = Bio.SUGARBEET .* Bio.bio3;
    Bio.SUGARBEET_bio8 = Bio.SUGARBEET .* Bio.bio8;
    Bio.SUGARBEET_bio9 = Bio.SUGARBEET .* Bio.bio9;
    Bio.SUGARBEET_bio7 = Bio.SUGARBEET .* Bio.bio7;
    Bio.SUGARBEET_bio10 = Bio.SUGARBEET .* Bio.bio10;
    Bio.SUGARBEET_bio11 = Bio.SUGARBEET .* Bio.bio11;
    Bio.SUGARBEET_rain = Bio.SUGARBEET .* Bio.rain;
    Bio.SUGARBEET_avElev = Bio.SUGARBEET .* Bio.avElev;
    Bio.SUGARBEET_aspect = Bio.SUGARBEET .* Bio.aspect;
    Bio.SUGARBEET_clay = Bio.SUGARBEET .* Bio.clay;
    Bio.SUGARBEET_urb_lake = Bio.SUGARBEET .* Bio.urb_lake;
    Bio.SUGARBEET_l_sand = Bio.SUGARBEET .* Bio.l_sand;
    Bio.SUGARBEET_loam = Bio.SUGARBEET .* Bio.loam;
    Bio.SUGARBEET_s_loam = Bio.SUGARBEET .* Bio.s_loam;
    Bio.SUGARBEET_clay_loam = Bio.SUGARBEET .* Bio.clay_loam;
    Bio.SUGARBEET_sand = Bio.SUGARBEET .* Bio.sand;
    %Bio.SUGARBEET_silt_loam = Bio.SUGARBEET .* Bio.silt_loam; % Not enough data to estimate this term
    Bio.SUGARBEET_ph1 = Bio.SUGARBEET .* Bio.ph1;
    Bio.SUGARBEET_ph2 = Bio.SUGARBEET .* Bio.ph2;
    Bio.SUGARBEET_ph3 = Bio.SUGARBEET .* Bio.ph3;
    Bio.SUGARBEET_ph4 = Bio.SUGARBEET .* Bio.ph4;
    Bio.SUGARBEET_SW1 = Bio.SUGARBEET .* Bio.SW1;
    Bio.SUGARBEET_SW2 = Bio.SUGARBEET .* Bio.SW2;
    Bio.SUGARBEET_SW3 = Bio.SUGARBEET .* Bio.SW3;
    Bio.SUGARBEET_SW4 = Bio.SUGARBEET .* Bio.SW4;
    Bio.IMPGR_WOOD = Bio.IMPGR .* Bio.WOOD;
    Bio.IMPGR_CerOSR = Bio.IMPGR .* Bio.CerOSR;
    Bio.IMPGR_bio3 = Bio.IMPGR .* Bio.bio3;
    Bio.IMPGR_bio8 = Bio.IMPGR .* Bio.bio8;
    Bio.IMPGR_bio9 = Bio.IMPGR .* Bio.bio9;
    Bio.IMPGR_bio7 = Bio.IMPGR .* Bio.bio7;
    Bio.IMPGR_bio10 = Bio.IMPGR .* Bio.bio10;
    Bio.IMPGR_bio11 = Bio.IMPGR .* Bio.bio11;
    Bio.IMPGR_rain = Bio.IMPGR .* Bio.rain;
    Bio.IMPGR_avElev = Bio.IMPGR .* Bio.avElev;
    Bio.IMPGR_aspect = Bio.IMPGR .* Bio.aspect;
    Bio.IMPGR_clay = Bio.IMPGR .* Bio.clay;
    Bio.IMPGR_urb_lake = Bio.IMPGR .* Bio.urb_lake;
    Bio.IMPGR_l_sand = Bio.IMPGR .* Bio.l_sand;
    Bio.IMPGR_loam = Bio.IMPGR .* Bio.loam;
    Bio.IMPGR_s_loam = Bio.IMPGR .* Bio.s_loam;
    Bio.IMPGR_clay_loam = Bio.IMPGR .* Bio.clay_loam;
    Bio.IMPGR_sand = Bio.IMPGR .* Bio.sand;
    Bio.IMPGR_silt_loam = Bio.IMPGR .* Bio.silt_loam;
    Bio.IMPGR_ph1 = Bio.IMPGR .* Bio.ph1;
    Bio.IMPGR_ph2 = Bio.IMPGR .* Bio.ph2;
    Bio.IMPGR_ph3 = Bio.IMPGR .* Bio.ph3;
    Bio.IMPGR_ph4 = Bio.IMPGR .* Bio.ph4;
    Bio.IMPGR_SW1 = Bio.IMPGR .* Bio.SW1;
    Bio.IMPGR_SW2 = Bio.IMPGR .* Bio.SW2;
    Bio.IMPGR_SW3 = Bio.IMPGR .* Bio.SW3;
    Bio.IMPGR_SW4 = Bio.IMPGR .* Bio.SW4;
    Bio.WOOD_CerOSR = Bio.WOOD .* Bio.CerOSR;
    Bio.WOOD_bio3 = Bio.WOOD .* Bio.bio3;
    Bio.WOOD_bio8 = Bio.WOOD .* Bio.bio8;
    Bio.WOOD_bio9 = Bio.WOOD .* Bio.bio9;
    Bio.WOOD_bio7 = Bio.WOOD .* Bio.bio7;
    Bio.WOOD_bio10 = Bio.WOOD .* Bio.bio10;
    Bio.WOOD_bio11 = Bio.WOOD .* Bio.bio11;
    Bio.WOOD_rain = Bio.WOOD .* Bio.rain;
    Bio.WOOD_avElev = Bio.WOOD .* Bio.avElev;
    Bio.WOOD_aspect = Bio.WOOD .* Bio.aspect;
    Bio.WOOD_clay = Bio.WOOD .* Bio.clay;
    Bio.WOOD_urb_lake = Bio.WOOD .* Bio.urb_lake;
    Bio.WOOD_l_sand = Bio.WOOD .* Bio.l_sand;
    Bio.WOOD_loam = Bio.WOOD .* Bio.loam;
    Bio.WOOD_s_loam = Bio.WOOD .* Bio.s_loam;
    Bio.WOOD_clay_loam = Bio.WOOD .* Bio.clay_loam;
    Bio.WOOD_sand = Bio.WOOD .* Bio.sand;
    Bio.WOOD_silt_loam = Bio.WOOD .* Bio.silt_loam;
    Bio.WOOD_ph1 = Bio.WOOD .* Bio.ph1;
    Bio.WOOD_ph2 = Bio.WOOD .* Bio.ph2;
    Bio.WOOD_ph3 = Bio.WOOD .* Bio.ph3;
    Bio.WOOD_ph4 = Bio.WOOD .* Bio.ph4;
    Bio.WOOD_SW1 = Bio.WOOD .* Bio.SW1;
    Bio.WOOD_SW2 = Bio.WOOD .* Bio.SW2;
    Bio.WOOD_SW3 = Bio.WOOD .* Bio.SW3;
    Bio.WOOD_SW4 = Bio.WOOD .* Bio.SW4;
    Bio.CerOSR_bio3 = Bio.CerOSR .* Bio.bio3;
    Bio.CerOSR_bio8 = Bio.CerOSR .* Bio.bio8;
    Bio.CerOSR_bio9 = Bio.CerOSR .* Bio.bio9;
    Bio.CerOSR_bio7 = Bio.CerOSR .* Bio.bio7;
    Bio.CerOSR_bio10 = Bio.CerOSR .* Bio.bio10;
    Bio.CerOSR_bio11 = Bio.CerOSR .* Bio.bio11;
    Bio.CerOSR_rain = Bio.CerOSR .* Bio.rain;
    Bio.CerOSR_avElev = Bio.CerOSR .* Bio.avElev;
    Bio.CerOSR_aspect = Bio.CerOSR .* Bio.aspect;
    Bio.CerOSR_clay = Bio.CerOSR .* Bio.clay;
    Bio.CerOSR_urb_lake = Bio.CerOSR .* Bio.urb_lake;
    Bio.CerOSR_l_sand = Bio.CerOSR .* Bio.l_sand;
    Bio.CerOSR_loam = Bio.CerOSR .* Bio.loam;
    Bio.CerOSR_s_loam = Bio.CerOSR .* Bio.s_loam;
    Bio.CerOSR_clay_loam = Bio.CerOSR .* Bio.clay_loam;
    Bio.CerOSR_sand = Bio.CerOSR .* Bio.sand;
    Bio.CerOSR_silt_loam = Bio.CerOSR .* Bio.silt_loam;
    Bio.CerOSR_ph1 = Bio.CerOSR .* Bio.ph1;
    Bio.CerOSR_ph2 = Bio.CerOSR .* Bio.ph2;
    Bio.CerOSR_ph3 = Bio.CerOSR .* Bio.ph3;
    Bio.CerOSR_ph4 = Bio.CerOSR .* Bio.ph4;
    Bio.CerOSR_SW1 = Bio.CerOSR .* Bio.SW1;
    Bio.CerOSR_SW2 = Bio.CerOSR .* Bio.SW2;
    Bio.CerOSR_SW3 = Bio.CerOSR .* Bio.SW3;
    Bio.CerOSR_SW4 = Bio.CerOSR .* Bio.SW4;
    Bio.bio3_bio8 = Bio.bio3 .* Bio.bio8;
    Bio.bio3_bio9 = Bio.bio3 .* Bio.bio9;
    Bio.bio3_bio7 = Bio.bio3 .* Bio.bio7;
    Bio.bio3_bio10 = Bio.bio3 .* Bio.bio10;
    Bio.bio3_bio11 = Bio.bio3 .* Bio.bio11;
    Bio.bio3_rain = Bio.bio3 .* Bio.rain;
    Bio.bio3_avElev = Bio.bio3 .* Bio.avElev;
    Bio.bio3_aspect = Bio.bio3 .* Bio.aspect;
    Bio.bio3_clay = Bio.bio3 .* Bio.clay;
    Bio.bio3_urb_lake = Bio.bio3 .* Bio.urb_lake;
    Bio.bio3_l_sand = Bio.bio3 .* Bio.l_sand;
    Bio.bio3_loam = Bio.bio3 .* Bio.loam;
    Bio.bio3_s_loam = Bio.bio3 .* Bio.s_loam;
    Bio.bio3_clay_loam = Bio.bio3 .* Bio.clay_loam;
    Bio.bio3_sand = Bio.bio3 .* Bio.sand;
    Bio.bio3_silt_loam = Bio.bio3 .* Bio.silt_loam;
    Bio.bio3_ph1 = Bio.bio3 .* Bio.ph1;
    Bio.bio3_ph2 = Bio.bio3 .* Bio.ph2;
    Bio.bio3_ph3 = Bio.bio3 .* Bio.ph3;
    Bio.bio3_ph4 = Bio.bio3 .* Bio.ph4;
    Bio.bio3_SW1 = Bio.bio3 .* Bio.SW1;
    Bio.bio3_SW2 = Bio.bio3 .* Bio.SW2;
    Bio.bio3_SW3 = Bio.bio3 .* Bio.SW3;
    Bio.bio3_SW4 = Bio.bio3 .* Bio.SW4;
    Bio.bio8_bio9 = Bio.bio8 .* Bio.bio9;
    Bio.bio8_bio7 = Bio.bio8 .* Bio.bio7;
    Bio.bio8_bio10 = Bio.bio8 .* Bio.bio10;
    Bio.bio8_bio11 = Bio.bio8 .* Bio.bio11;
    Bio.bio8_rain = Bio.bio8 .* Bio.rain;
    Bio.bio8_avElev = Bio.bio8 .* Bio.avElev;
    Bio.bio8_aspect = Bio.bio8 .* Bio.aspect;
    Bio.bio8_clay = Bio.bio8 .* Bio.clay;
    Bio.bio8_urb_lake = Bio.bio8 .* Bio.urb_lake;
    Bio.bio8_l_sand = Bio.bio8 .* Bio.l_sand;
    Bio.bio8_loam = Bio.bio8 .* Bio.loam;
    Bio.bio8_s_loam = Bio.bio8 .* Bio.s_loam;
    Bio.bio8_clay_loam = Bio.bio8 .* Bio.clay_loam;
    Bio.bio8_sand = Bio.bio8 .* Bio.sand;
    Bio.bio8_silt_loam = Bio.bio8 .* Bio.silt_loam;
    Bio.bio8_ph1 = Bio.bio8 .* Bio.ph1;
    Bio.bio8_ph2 = Bio.bio8 .* Bio.ph2;
    Bio.bio8_ph3 = Bio.bio8 .* Bio.ph3;
    Bio.bio8_ph4 = Bio.bio8 .* Bio.ph4;
    Bio.bio8_SW1 = Bio.bio8 .* Bio.SW1;
    Bio.bio8_SW2 = Bio.bio8 .* Bio.SW2;
    Bio.bio8_SW3 = Bio.bio8 .* Bio.SW3;
    Bio.bio8_SW4 = Bio.bio8 .* Bio.SW4;
    Bio.bio9_bio7 = Bio.bio9 .* Bio.bio7;
    Bio.bio9_bio10 = Bio.bio9 .* Bio.bio10;
    Bio.bio9_bio11 = Bio.bio9 .* Bio.bio11;
    Bio.bio9_rain = Bio.bio9 .* Bio.rain;
    Bio.bio9_avElev = Bio.bio9 .* Bio.avElev;
    Bio.bio9_aspect = Bio.bio9 .* Bio.aspect;
    Bio.bio9_clay = Bio.bio9 .* Bio.clay;
    Bio.bio9_urb_lake = Bio.bio9 .* Bio.urb_lake;
    Bio.bio9_l_sand = Bio.bio9 .* Bio.l_sand;
    Bio.bio9_loam = Bio.bio9 .* Bio.loam;
    Bio.bio9_s_loam = Bio.bio9 .* Bio.s_loam;
    Bio.bio9_clay_loam = Bio.bio9 .* Bio.clay_loam;
    Bio.bio9_sand = Bio.bio9 .* Bio.sand;
    Bio.bio9_silt_loam = Bio.bio9 .* Bio.silt_loam;
    Bio.bio9_ph1 = Bio.bio9 .* Bio.ph1;
    Bio.bio9_ph2 = Bio.bio9 .* Bio.ph2;
    Bio.bio9_ph3 = Bio.bio9 .* Bio.ph3;
    Bio.bio9_ph4 = Bio.bio9 .* Bio.ph4;
    Bio.bio9_SW1 = Bio.bio9 .* Bio.SW1;
    Bio.bio9_SW2 = Bio.bio9 .* Bio.SW2;
    Bio.bio9_SW3 = Bio.bio9 .* Bio.SW3;
    Bio.bio9_SW4 = Bio.bio9 .* Bio.SW4;
    Bio.bio7_bio10 = Bio.bio7 .* Bio.bio10;
    Bio.bio7_bio11 = Bio.bio7 .* Bio.bio11;
    Bio.bio7_rain = Bio.bio7 .* Bio.rain;
    Bio.bio7_avElev = Bio.bio7 .* Bio.avElev;
    Bio.bio7_aspect = Bio.bio7 .* Bio.aspect;
    Bio.bio7_clay = Bio.bio7 .* Bio.clay;
    Bio.bio7_urb_lake = Bio.bio7 .* Bio.urb_lake;
    Bio.bio7_l_sand = Bio.bio7 .* Bio.l_sand;
    Bio.bio7_loam = Bio.bio7 .* Bio.loam;
    Bio.bio7_s_loam = Bio.bio7 .* Bio.s_loam;
    Bio.bio7_clay_loam = Bio.bio7 .* Bio.clay_loam;
    Bio.bio7_sand = Bio.bio7 .* Bio.sand;
    Bio.bio7_silt_loam = Bio.bio7 .* Bio.silt_loam;
    Bio.bio7_ph1 = Bio.bio7 .* Bio.ph1;
    Bio.bio7_ph2 = Bio.bio7 .* Bio.ph2;
    Bio.bio7_ph3 = Bio.bio7 .* Bio.ph3;
    Bio.bio7_ph4 = Bio.bio7 .* Bio.ph4;
    Bio.bio7_SW1 = Bio.bio7 .* Bio.SW1;
    Bio.bio7_SW2 = Bio.bio7 .* Bio.SW2;
    Bio.bio7_SW3 = Bio.bio7 .* Bio.SW3;
    Bio.bio7_SW4 = Bio.bio7 .* Bio.SW4;
    Bio.bio10_bio11 = Bio.bio10 .* Bio.bio11;
    Bio.bio10_rain = Bio.bio10 .* Bio.rain;
    Bio.bio10_avElev = Bio.bio10 .* Bio.avElev;
    Bio.bio10_aspect = Bio.bio10 .* Bio.aspect;
    Bio.bio10_clay = Bio.bio10 .* Bio.clay;
    Bio.bio10_urb_lake = Bio.bio10 .* Bio.urb_lake;
    Bio.bio10_l_sand = Bio.bio10 .* Bio.l_sand;
    Bio.bio10_loam = Bio.bio10 .* Bio.loam;
    Bio.bio10_s_loam = Bio.bio10 .* Bio.s_loam;
    Bio.bio10_clay_loam = Bio.bio10 .* Bio.clay_loam;
    Bio.bio10_sand = Bio.bio10 .* Bio.sand;
    Bio.bio10_silt_loam = Bio.bio10 .* Bio.silt_loam;
    Bio.bio10_ph1 = Bio.bio10 .* Bio.ph1;
    Bio.bio10_ph2 = Bio.bio10 .* Bio.ph2;
    Bio.bio10_ph3 = Bio.bio10 .* Bio.ph3;
    Bio.bio10_ph4 = Bio.bio10 .* Bio.ph4;
    Bio.bio10_SW1 = Bio.bio10 .* Bio.SW1;
    Bio.bio10_SW2 = Bio.bio10 .* Bio.SW2;
    Bio.bio10_SW3 = Bio.bio10 .* Bio.SW3;
    Bio.bio10_SW4 = Bio.bio10 .* Bio.SW4;
    Bio.bio11_rain = Bio.bio11 .* Bio.rain;
    Bio.bio11_avElev = Bio.bio11 .* Bio.avElev;
    Bio.bio11_aspect = Bio.bio11 .* Bio.aspect;
    Bio.bio11_clay = Bio.bio11 .* Bio.clay;
    Bio.bio11_urb_lake = Bio.bio11 .* Bio.urb_lake;
    Bio.bio11_l_sand = Bio.bio11 .* Bio.l_sand;
    Bio.bio11_loam = Bio.bio11 .* Bio.loam;
    Bio.bio11_s_loam = Bio.bio11 .* Bio.s_loam;
    Bio.bio11_clay_loam = Bio.bio11 .* Bio.clay_loam;
    Bio.bio11_sand = Bio.bio11 .* Bio.sand;
    Bio.bio11_silt_loam = Bio.bio11 .* Bio.silt_loam;
    Bio.bio11_ph1 = Bio.bio11 .* Bio.ph1;
    Bio.bio11_ph2 = Bio.bio11 .* Bio.ph2;
    Bio.bio11_ph3 = Bio.bio11 .* Bio.ph3;
    Bio.bio11_ph4 = Bio.bio11 .* Bio.ph4;
    Bio.bio11_SW1 = Bio.bio11 .* Bio.SW1;
    Bio.bio11_SW2 = Bio.bio11 .* Bio.SW2;
    Bio.bio11_SW3 = Bio.bio11 .* Bio.SW3;
    Bio.bio11_SW4 = Bio.bio11 .* Bio.SW4;
    Bio.rain_avElev = Bio.rain .* Bio.avElev;
    Bio.rain_aspect = Bio.rain .* Bio.aspect;
    Bio.rain_clay = Bio.rain .* Bio.clay;
    Bio.rain_urb_lake = Bio.rain .* Bio.urb_lake;
    Bio.rain_l_sand = Bio.rain .* Bio.l_sand;
    Bio.rain_loam = Bio.rain .* Bio.loam;
    Bio.rain_s_loam = Bio.rain .* Bio.s_loam;
    Bio.rain_clay_loam = Bio.rain .* Bio.clay_loam;
    Bio.rain_sand = Bio.rain .* Bio.sand;
    Bio.rain_silt_loam = Bio.rain .* Bio.silt_loam;
    Bio.rain_ph1 = Bio.rain .* Bio.ph1;
    Bio.rain_ph2 = Bio.rain .* Bio.ph2;
    Bio.rain_ph3 = Bio.rain .* Bio.ph3;
    Bio.rain_ph4 = Bio.rain .* Bio.ph4;
    Bio.rain_SW1 = Bio.rain .* Bio.SW1;
    Bio.rain_SW2 = Bio.rain .* Bio.SW2;
    Bio.rain_SW3 = Bio.rain .* Bio.SW3;
    Bio.rain_SW4 = Bio.rain .* Bio.SW4;
    Bio.avElev_aspect = Bio.avElev .* Bio.aspect;
    Bio.avElev_clay = Bio.avElev .* Bio.clay;
    Bio.avElev_urb_lake = Bio.avElev .* Bio.urb_lake;
    Bio.avElev_l_sand = Bio.avElev .* Bio.l_sand;
    Bio.avElev_loam = Bio.avElev .* Bio.loam;
    Bio.avElev_s_loam = Bio.avElev .* Bio.s_loam;
    Bio.avElev_clay_loam = Bio.avElev .* Bio.clay_loam;
    Bio.avElev_sand = Bio.avElev .* Bio.sand;
    Bio.avElev_silt_loam = Bio.avElev .* Bio.silt_loam;
    Bio.avElev_ph1 = Bio.avElev .* Bio.ph1;
    Bio.avElev_ph2 = Bio.avElev .* Bio.ph2;
    Bio.avElev_ph3 = Bio.avElev .* Bio.ph3;
    Bio.avElev_ph4 = Bio.avElev .* Bio.ph4;
    Bio.avElev_SW1 = Bio.avElev .* Bio.SW1;
    Bio.avElev_SW2 = Bio.avElev .* Bio.SW2;
    Bio.avElev_SW3 = Bio.avElev .* Bio.SW3;
    Bio.avElev_SW4 = Bio.avElev .* Bio.SW4;
    Bio.aspect_clay = Bio.aspect .* Bio.clay;
    Bio.aspect_urb_lake = Bio.aspect .* Bio.urb_lake;
    Bio.aspect_l_sand = Bio.aspect .* Bio.l_sand;
    Bio.aspect_loam = Bio.aspect .* Bio.loam;
    Bio.aspect_s_loam = Bio.aspect .* Bio.s_loam;
    Bio.aspect_clay_loam = Bio.aspect .* Bio.clay_loam;
    Bio.aspect_sand = Bio.aspect .* Bio.sand;
    Bio.aspect_silt_loam = Bio.aspect .* Bio.silt_loam;
    Bio.aspect_ph1 = Bio.aspect .* Bio.ph1;
    Bio.aspect_ph2 = Bio.aspect .* Bio.ph2;
    Bio.aspect_ph3 = Bio.aspect .* Bio.ph3;
    Bio.aspect_ph4 = Bio.aspect .* Bio.ph4;
    Bio.aspect_SW1 = Bio.aspect .* Bio.SW1;
    Bio.aspect_SW2 = Bio.aspect .* Bio.SW2;
    Bio.aspect_SW3 = Bio.aspect .* Bio.SW3;
    Bio.aspect_SW4 = Bio.aspect .* Bio.SW4;
    Bio.clay_urb_lake = Bio.clay .* Bio.urb_lake;
    Bio.clay_l_sand = Bio.clay .* Bio.l_sand;
    Bio.clay_loam2 = Bio.clay .* Bio.loam; % clay_loam is already a variable so need to call this clay_loam2
    Bio.clay_s_loam = Bio.clay .* Bio.s_loam;
    Bio.clay_clay_loam = Bio.clay .* Bio.clay_loam;
    Bio.clay_sand = Bio.clay .* Bio.sand;
    Bio.clay_silt_loam = Bio.clay .* Bio.silt_loam;
    Bio.clay_ph1 = Bio.clay .* Bio.ph1;
    Bio.clay_ph2 = Bio.clay .* Bio.ph2;
    Bio.clay_ph3 = Bio.clay .* Bio.ph3;
    Bio.clay_ph4 = Bio.clay .* Bio.ph4;
    Bio.clay_SW1 = Bio.clay .* Bio.SW1;
    Bio.clay_SW2 = Bio.clay .* Bio.SW2;
    Bio.clay_SW3 = Bio.clay .* Bio.SW3;
    Bio.clay_SW4 = Bio.clay .* Bio.SW4;
    Bio.urb_lake_l_sand = Bio.urb_lake .* Bio.l_sand;
    Bio.urb_lake_loam = Bio.urb_lake .* Bio.loam;
    Bio.urb_lake_s_loam = Bio.urb_lake .* Bio.s_loam;
    Bio.urb_lake_clay_loam = Bio.urb_lake .* Bio.clay_loam;
    Bio.urb_lake_sand = Bio.urb_lake .* Bio.sand;
    Bio.urb_lake_silt_loam = Bio.urb_lake .* Bio.silt_loam;
    Bio.urb_lake_ph1 = Bio.urb_lake .* Bio.ph1;
    Bio.urb_lake_ph2 = Bio.urb_lake .* Bio.ph2;
    Bio.urb_lake_ph3 = Bio.urb_lake .* Bio.ph3;
    Bio.urb_lake_ph4 = Bio.urb_lake .* Bio.ph4;
    Bio.urb_lake_SW1 = Bio.urb_lake .* Bio.SW1;
    Bio.urb_lake_SW2 = Bio.urb_lake .* Bio.SW2;
    Bio.urb_lake_SW3 = Bio.urb_lake .* Bio.SW3;
    Bio.urb_lake_SW4 = Bio.urb_lake .* Bio.SW4;
    Bio.l_sand_loam = Bio.l_sand .* Bio.loam;
    Bio.l_sand_s_loam = Bio.l_sand .* Bio.s_loam;
    Bio.l_sand_clay_loam = Bio.l_sand .* Bio.clay_loam;
    Bio.l_sand_sand = Bio.l_sand .* Bio.sand;
    Bio.l_sand_silt_loam = Bio.l_sand .* Bio.silt_loam;
    Bio.l_sand_ph1 = Bio.l_sand .* Bio.ph1;
    Bio.l_sand_ph2 = Bio.l_sand .* Bio.ph2;
    Bio.l_sand_ph3 = Bio.l_sand .* Bio.ph3;
    Bio.l_sand_ph4 = Bio.l_sand .* Bio.ph4;
    Bio.l_sand_SW1 = Bio.l_sand .* Bio.SW1;
    Bio.l_sand_SW2 = Bio.l_sand .* Bio.SW2;
    Bio.l_sand_SW3 = Bio.l_sand .* Bio.SW3;
    Bio.l_sand_SW4 = Bio.l_sand .* Bio.SW4;
    Bio.loam_s_loam = Bio.loam .* Bio.s_loam;
    Bio.loam_clay_loam = Bio.loam .* Bio.clay_loam;
    Bio.loam_sand = Bio.loam .* Bio.sand;
    Bio.loam_silt_loam = Bio.loam .* Bio.silt_loam;
    Bio.loam_ph1 = Bio.loam .* Bio.ph1;
    Bio.loam_ph2 = Bio.loam .* Bio.ph2;
    Bio.loam_ph3 = Bio.loam .* Bio.ph3;
    Bio.loam_ph4 = Bio.loam .* Bio.ph4;
    Bio.loam_SW1 = Bio.loam .* Bio.SW1;
    Bio.loam_SW2 = Bio.loam .* Bio.SW2;
    Bio.loam_SW3 = Bio.loam .* Bio.SW3;
    Bio.loam_SW4 = Bio.loam .* Bio.SW4;
    Bio.s_loam_clay_loam = Bio.s_loam .* Bio.clay_loam;
    Bio.s_loam_sand = Bio.s_loam .* Bio.sand;
    %Bio.s_loam_silt_loam = Bio.s_loam .* Bio.silt_loam; % Not enough data to estimate this term
    Bio.s_loam_ph1 = Bio.s_loam .* Bio.ph1;
    Bio.s_loam_ph2 = Bio.s_loam .* Bio.ph2;
    Bio.s_loam_ph3 = Bio.s_loam .* Bio.ph3;
    Bio.s_loam_ph4 = Bio.s_loam .* Bio.ph4;
    Bio.s_loam_SW1 = Bio.s_loam .* Bio.SW1;
    Bio.s_loam_SW2 = Bio.s_loam .* Bio.SW2;
    Bio.s_loam_SW3 = Bio.s_loam .* Bio.SW3;
    Bio.s_loam_SW4 = Bio.s_loam .* Bio.SW4;
    Bio.clay_loam_sand = Bio.clay_loam .* Bio.sand;
    %Bio.clay_loam_silt_loam = Bio.clay_loam .* Bio.silt_loam; % Not enough data to estimate this term
    Bio.clay_loam_ph1 = Bio.clay_loam .* Bio.ph1;
    Bio.clay_loam_ph2 = Bio.clay_loam .* Bio.ph2;
    Bio.clay_loam_ph3 = Bio.clay_loam .* Bio.ph3;
    Bio.clay_loam_ph4 = Bio.clay_loam .* Bio.ph4;
    Bio.clay_loam_SW1 = Bio.clay_loam .* Bio.SW1;
    Bio.clay_loam_SW2 = Bio.clay_loam .* Bio.SW2;
    Bio.clay_loam_SW3 = Bio.clay_loam .* Bio.SW3;
    Bio.clay_loam_SW4 = Bio.clay_loam .* Bio.SW4;
    %Bio.sand_silt_loam = Bio.sand .* Bio.silt_loam; % Not enough data to estimate this term
    Bio.sand_ph1 = Bio.sand .* Bio.ph1;
    Bio.sand_ph2 = Bio.sand .* Bio.ph2;
    Bio.sand_ph3 = Bio.sand .* Bio.ph3;
    Bio.sand_ph4 = Bio.sand .* Bio.ph4;
    Bio.sand_SW1 = Bio.sand .* Bio.SW1;
    Bio.sand_SW2 = Bio.sand .* Bio.SW2;
    Bio.sand_SW3 = Bio.sand .* Bio.SW3;
    Bio.sand_SW4 = Bio.sand .* Bio.SW4;
    %Bio.silt_loam_ph1 = Bio.silt_loam .* Bio.ph1; % Not enough data to estimate this term
    Bio.silt_loam_ph2 = Bio.silt_loam .* Bio.ph2;
    %Bio.silt_loam_ph3 = Bio.silt_loam .* Bio.ph3; % Not enough data to estimate this term
    %Bio.silt_loam_ph4 = Bio.silt_loam .* Bio.ph4; % Not enough data to estimate this term
    Bio.silt_loam_SW1 = Bio.silt_loam .* Bio.SW1;
    %Bio.silt_loam_SW2 = Bio.silt_loam .* Bio.SW2; % Not enough data to estimate this term
    Bio.silt_loam_SW3 = Bio.silt_loam .* Bio.SW3;
    Bio.silt_loam_SW4 = Bio.silt_loam .* Bio.SW4;
    Bio.ph1_ph2 = Bio.ph1 .* Bio.ph2;
    Bio.ph1_ph3 = Bio.ph1 .* Bio.ph3;
    Bio.ph1_ph4 = Bio.ph1 .* Bio.ph4;
    Bio.ph1_SW1 = Bio.ph1 .* Bio.SW1;
    Bio.ph1_SW2 = Bio.ph1 .* Bio.SW2;
    Bio.ph1_SW3 = Bio.ph1 .* Bio.SW3;
    Bio.ph1_SW4 = Bio.ph1 .* Bio.SW4;
    Bio.ph2_ph3 = Bio.ph2 .* Bio.ph3;
    Bio.ph2_ph4 = Bio.ph2 .* Bio.ph4;
    Bio.ph2_SW1 = Bio.ph2 .* Bio.SW1;
    Bio.ph2_SW2 = Bio.ph2 .* Bio.SW2;
    Bio.ph2_SW3 = Bio.ph2 .* Bio.SW3;
    Bio.ph2_SW4 = Bio.ph2 .* Bio.SW4;
    %Bio.ph3_ph4 = Bio.ph3 .* Bio.ph4; % Not enough data to estimate this term
    Bio.ph3_SW1 = Bio.ph3 .* Bio.SW1;
    Bio.ph3_SW2 = Bio.ph3 .* Bio.SW2;
    Bio.ph3_SW3 = Bio.ph3 .* Bio.SW3;
    Bio.ph3_SW4 = Bio.ph3 .* Bio.SW4;
    Bio.ph4_SW1 = Bio.ph4 .* Bio.SW1;
    Bio.ph4_SW2 = Bio.ph4 .* Bio.SW2;
    Bio.ph4_SW3 = Bio.ph4 .* Bio.SW3;
    Bio.ph4_SW4 = Bio.ph4 .* Bio.SW4;
    Bio.SW1_SW2 = Bio.SW1 .* Bio.SW2;
    Bio.SW1_SW3 = Bio.SW1 .* Bio.SW3;
    Bio.SW1_SW4 = Bio.SW1 .* Bio.SW4;
    Bio.SW2_SW3 = Bio.SW2 .* Bio.SW3;
    Bio.SW2_SW4 = Bio.SW2 .* Bio.SW4;
    Bio.SW3_SW4 = Bio.SW3 .* Bio.SW4;
    
    %% (3) CREATE MODEL MATRIX
    %  =======================
    model_matrix = [Bio.const Bio.COAST Bio.FWATER Bio.MARINE Bio.URBAN...
        Bio.RGRAZ Bio.GRSNFRM Bio.POTS Bio.MAIZE Bio.HORT Bio.SUGARBEET...
        Bio.IMPGR Bio.WOOD Bio.CerOSR Bio.bio3 Bio.bio8 Bio.bio9 Bio.bio7...
        Bio.bio10 Bio.bio11 Bio.rain Bio.avElev Bio.aspect Bio.clay...
        Bio.urb_lake Bio.l_sand Bio.loam Bio.s_loam Bio.clay_loam Bio.sand...
        Bio.silt_loam Bio.ph1 Bio.ph2 Bio.ph3 Bio.ph4 Bio.SW1 Bio.SW2...
        Bio.SW3 Bio.SW4 Bio.sqCOAST Bio.sqFWATER Bio.sqMARINE Bio.sqURBAN...
        Bio.sqRGRAZ Bio.sqGRSNFRM Bio.sqPOTS Bio.sqMAIZE Bio.sqHORT...
        Bio.sqSUGARBEET Bio.sqIMPGR Bio.sqWOOD Bio.sqCerOSR Bio.sqbio3...
        Bio.sqbio8 Bio.sqbio9 Bio.sqbio7 Bio.sqbio10 Bio.sqbio11 Bio.sqrain...
        Bio.sqavElev Bio.sqaspect Bio.sqclay Bio.squrb_lake Bio.sql_sand...
        Bio.sqloam Bio.sqs_loam Bio.sqclay_loam Bio.sqsand Bio.sqsilt_loam...
        Bio.sqph1 Bio.sqph2 Bio.sqph3 Bio.sqph4 Bio.sqSW1 Bio.sqSW2...
        Bio.sqSW3 Bio.sqSW4 Bio.COAST_FWATER Bio.COAST_MARINE...
        Bio.COAST_URBAN Bio.COAST_RGRAZ Bio.COAST_GRSNFRM Bio.COAST_POTS...
        Bio.COAST_MAIZE Bio.COAST_HORT Bio.COAST_SUGARBEET Bio.COAST_IMPGR...
        Bio.COAST_WOOD Bio.COAST_CerOSR Bio.COAST_bio3 Bio.COAST_bio8...
        Bio.COAST_bio9 Bio.COAST_bio7 Bio.COAST_bio10 Bio.COAST_bio11...
        Bio.COAST_rain Bio.COAST_avElev Bio.COAST_aspect Bio.COAST_clay...
        Bio.COAST_urb_lake Bio.COAST_l_sand Bio.COAST_loam Bio.COAST_s_loam...
        Bio.COAST_clay_loam Bio.COAST_sand Bio.COAST_silt_loam Bio.COAST_ph1...
        Bio.COAST_ph2 Bio.COAST_ph3 Bio.COAST_ph4 Bio.COAST_SW1...
        Bio.COAST_SW2 Bio.COAST_SW3 Bio.COAST_SW4 Bio.FWATER_MARINE...
        Bio.FWATER_URBAN Bio.FWATER_RGRAZ Bio.FWATER_GRSNFRM Bio.FWATER_POTS...
        Bio.FWATER_MAIZE Bio.FWATER_HORT Bio.FWATER_SUGARBEET...
        Bio.FWATER_IMPGR Bio.FWATER_WOOD Bio.FWATER_CerOSR Bio.FWATER_bio3...
        Bio.FWATER_bio8 Bio.FWATER_bio9 Bio.FWATER_bio7 Bio.FWATER_bio10...
        Bio.FWATER_bio11 Bio.FWATER_rain Bio.FWATER_avElev Bio.FWATER_aspect...
        Bio.FWATER_clay Bio.FWATER_urb_lake Bio.FWATER_l_sand...
        Bio.FWATER_loam Bio.FWATER_s_loam Bio.FWATER_clay_loam...
        Bio.FWATER_sand Bio.FWATER_silt_loam Bio.FWATER_ph1 Bio.FWATER_ph2...
        Bio.FWATER_ph3 Bio.FWATER_ph4 Bio.FWATER_SW1 Bio.FWATER_SW2...
        Bio.FWATER_SW3 Bio.FWATER_SW4 Bio.MARINE_URBAN Bio.MARINE_RGRAZ...
        Bio.MARINE_GRSNFRM Bio.MARINE_POTS Bio.MARINE_MAIZE Bio.MARINE_HORT...
        Bio.MARINE_SUGARBEET Bio.MARINE_IMPGR Bio.MARINE_WOOD...
        Bio.MARINE_CerOSR Bio.MARINE_bio3 Bio.MARINE_bio8 Bio.MARINE_bio9...
        Bio.MARINE_bio7 Bio.MARINE_bio10 Bio.MARINE_bio11 Bio.MARINE_rain...
        Bio.MARINE_avElev Bio.MARINE_aspect Bio.MARINE_clay...
        Bio.MARINE_urb_lake Bio.MARINE_l_sand Bio.MARINE_loam...
        Bio.MARINE_s_loam Bio.MARINE_clay_loam Bio.MARINE_sand...
        Bio.MARINE_silt_loam Bio.MARINE_ph1 Bio.MARINE_ph2 Bio.MARINE_ph3...
        Bio.MARINE_ph4 Bio.MARINE_SW1 Bio.MARINE_SW2 Bio.MARINE_SW3...
        Bio.MARINE_SW4 Bio.URBAN_RGRAZ Bio.URBAN_GRSNFRM Bio.URBAN_POTS...
        Bio.URBAN_MAIZE Bio.URBAN_HORT Bio.URBAN_SUGARBEET Bio.URBAN_IMPGR...
        Bio.URBAN_WOOD Bio.URBAN_CerOSR Bio.URBAN_bio3 Bio.URBAN_bio8...
        Bio.URBAN_bio9 Bio.URBAN_bio7 Bio.URBAN_bio10 Bio.URBAN_bio11...
        Bio.URBAN_rain Bio.URBAN_avElev Bio.URBAN_aspect Bio.URBAN_clay...
        Bio.URBAN_urb_lake Bio.URBAN_l_sand Bio.URBAN_loam Bio.URBAN_s_loam...
        Bio.URBAN_clay_loam Bio.URBAN_sand Bio.URBAN_silt_loam Bio.URBAN_ph1...
        Bio.URBAN_ph2 Bio.URBAN_ph3 Bio.URBAN_ph4 Bio.URBAN_SW1...
        Bio.URBAN_SW2 Bio.URBAN_SW3 Bio.URBAN_SW4 Bio.RGRAZ_GRSNFRM...
        Bio.RGRAZ_POTS Bio.RGRAZ_MAIZE Bio.RGRAZ_HORT Bio.RGRAZ_SUGARBEET...
        Bio.RGRAZ_IMPGR Bio.RGRAZ_WOOD Bio.RGRAZ_CerOSR Bio.RGRAZ_bio3...
        Bio.RGRAZ_bio8 Bio.RGRAZ_bio9 Bio.RGRAZ_bio7 Bio.RGRAZ_bio10...
        Bio.RGRAZ_bio11 Bio.RGRAZ_rain Bio.RGRAZ_avElev Bio.RGRAZ_aspect...
        Bio.RGRAZ_clay Bio.RGRAZ_urb_lake Bio.RGRAZ_l_sand Bio.RGRAZ_loam...
        Bio.RGRAZ_s_loam Bio.RGRAZ_clay_loam Bio.RGRAZ_sand...
        Bio.RGRAZ_silt_loam Bio.RGRAZ_ph1 Bio.RGRAZ_ph2 Bio.RGRAZ_ph3...
        Bio.RGRAZ_ph4 Bio.RGRAZ_SW1 Bio.RGRAZ_SW2 Bio.RGRAZ_SW3...
        Bio.RGRAZ_SW4 Bio.GRSNFRM_POTS Bio.GRSNFRM_MAIZE Bio.GRSNFRM_HORT...
        Bio.GRSNFRM_SUGARBEET Bio.GRSNFRM_IMPGR Bio.GRSNFRM_WOOD...
        Bio.GRSNFRM_CerOSR Bio.GRSNFRM_bio3 Bio.GRSNFRM_bio8...
        Bio.GRSNFRM_bio9 Bio.GRSNFRM_bio7 Bio.GRSNFRM_bio10...
        Bio.GRSNFRM_bio11 Bio.GRSNFRM_rain Bio.GRSNFRM_avElev...
        Bio.GRSNFRM_aspect Bio.GRSNFRM_clay Bio.GRSNFRM_urb_lake...
        Bio.GRSNFRM_l_sand Bio.GRSNFRM_loam Bio.GRSNFRM_s_loam...
        Bio.GRSNFRM_clay_loam Bio.GRSNFRM_sand Bio.GRSNFRM_silt_loam...
        Bio.GRSNFRM_ph1 Bio.GRSNFRM_ph2 Bio.GRSNFRM_ph3 Bio.GRSNFRM_ph4...
        Bio.GRSNFRM_SW1 Bio.GRSNFRM_SW2 Bio.GRSNFRM_SW3 Bio.GRSNFRM_SW4...
        Bio.POTS_MAIZE Bio.POTS_HORT Bio.POTS_SUGARBEET Bio.POTS_IMPGR...
        Bio.POTS_WOOD Bio.POTS_CerOSR Bio.POTS_bio3 Bio.POTS_bio8...
        Bio.POTS_bio9 Bio.POTS_bio7 Bio.POTS_bio10 Bio.POTS_bio11...
        Bio.POTS_rain Bio.POTS_avElev Bio.POTS_aspect Bio.POTS_clay...
        Bio.POTS_urb_lake Bio.POTS_l_sand Bio.POTS_loam Bio.POTS_s_loam...
        Bio.POTS_clay_loam Bio.POTS_sand Bio.POTS_silt_loam Bio.POTS_ph1...
        Bio.POTS_ph2 Bio.POTS_ph3 Bio.POTS_ph4 Bio.POTS_SW1 Bio.POTS_SW2...
        Bio.POTS_SW3 Bio.POTS_SW4 Bio.MAIZE_HORT Bio.MAIZE_SUGARBEET...
        Bio.MAIZE_IMPGR Bio.MAIZE_WOOD Bio.MAIZE_CerOSR Bio.MAIZE_bio3...
        Bio.MAIZE_bio8 Bio.MAIZE_bio9 Bio.MAIZE_bio7 Bio.MAIZE_bio10...
        Bio.MAIZE_bio11 Bio.MAIZE_rain Bio.MAIZE_avElev Bio.MAIZE_aspect...
        Bio.MAIZE_clay Bio.MAIZE_urb_lake Bio.MAIZE_l_sand Bio.MAIZE_loam...
        Bio.MAIZE_s_loam Bio.MAIZE_clay_loam Bio.MAIZE_sand...
        Bio.MAIZE_silt_loam Bio.MAIZE_ph1 Bio.MAIZE_ph2 Bio.MAIZE_ph3...
        Bio.MAIZE_ph4 Bio.MAIZE_SW1 Bio.MAIZE_SW2 Bio.MAIZE_SW3...
        Bio.MAIZE_SW4 Bio.HORT_SUGARBEET Bio.HORT_IMPGR Bio.HORT_WOOD...
        Bio.HORT_CerOSR Bio.HORT_bio3 Bio.HORT_bio8 Bio.HORT_bio9...
        Bio.HORT_bio7 Bio.HORT_bio10 Bio.HORT_bio11 Bio.HORT_rain...
        Bio.HORT_avElev Bio.HORT_aspect Bio.HORT_clay Bio.HORT_urb_lake...
        Bio.HORT_l_sand Bio.HORT_loam Bio.HORT_s_loam Bio.HORT_clay_loam...
        Bio.HORT_sand Bio.HORT_silt_loam Bio.HORT_ph1 Bio.HORT_ph2...
        Bio.HORT_ph3 Bio.HORT_ph4 Bio.HORT_SW1 Bio.HORT_SW2 Bio.HORT_SW3...
        Bio.HORT_SW4 Bio.SUGARBEET_IMPGR Bio.SUGARBEET_WOOD...
        Bio.SUGARBEET_CerOSR Bio.SUGARBEET_bio3 Bio.SUGARBEET_bio8...
        Bio.SUGARBEET_bio9 Bio.SUGARBEET_bio7 Bio.SUGARBEET_bio10...
        Bio.SUGARBEET_bio11 Bio.SUGARBEET_rain Bio.SUGARBEET_avElev...
        Bio.SUGARBEET_aspect Bio.SUGARBEET_clay Bio.SUGARBEET_urb_lake...
        Bio.SUGARBEET_l_sand Bio.SUGARBEET_loam Bio.SUGARBEET_s_loam...
        Bio.SUGARBEET_clay_loam Bio.SUGARBEET_sand Bio.SUGARBEET_ph1...
        Bio.SUGARBEET_ph2 Bio.SUGARBEET_ph3 Bio.SUGARBEET_ph4...
        Bio.SUGARBEET_SW1 Bio.SUGARBEET_SW2 Bio.SUGARBEET_SW3...
        Bio.SUGARBEET_SW4 Bio.IMPGR_WOOD Bio.IMPGR_CerOSR Bio.IMPGR_bio3...
        Bio.IMPGR_bio8 Bio.IMPGR_bio9 Bio.IMPGR_bio7 Bio.IMPGR_bio10...
        Bio.IMPGR_bio11 Bio.IMPGR_rain Bio.IMPGR_avElev Bio.IMPGR_aspect...
        Bio.IMPGR_clay Bio.IMPGR_urb_lake Bio.IMPGR_l_sand Bio.IMPGR_loam...
        Bio.IMPGR_s_loam Bio.IMPGR_clay_loam Bio.IMPGR_sand...
        Bio.IMPGR_silt_loam Bio.IMPGR_ph1 Bio.IMPGR_ph2 Bio.IMPGR_ph3...
        Bio.IMPGR_ph4 Bio.IMPGR_SW1 Bio.IMPGR_SW2 Bio.IMPGR_SW3...
        Bio.IMPGR_SW4 Bio.WOOD_CerOSR Bio.WOOD_bio3 Bio.WOOD_bio8...
        Bio.WOOD_bio9 Bio.WOOD_bio7 Bio.WOOD_bio10 Bio.WOOD_bio11...
        Bio.WOOD_rain Bio.WOOD_avElev Bio.WOOD_aspect Bio.WOOD_clay...
        Bio.WOOD_urb_lake Bio.WOOD_l_sand Bio.WOOD_loam Bio.WOOD_s_loam...
        Bio.WOOD_clay_loam Bio.WOOD_sand Bio.WOOD_silt_loam Bio.WOOD_ph1...
        Bio.WOOD_ph2 Bio.WOOD_ph3 Bio.WOOD_ph4 Bio.WOOD_SW1 Bio.WOOD_SW2...
        Bio.WOOD_SW3 Bio.WOOD_SW4 Bio.CerOSR_bio3 Bio.CerOSR_bio8...
        Bio.CerOSR_bio9 Bio.CerOSR_bio7 Bio.CerOSR_bio10 Bio.CerOSR_bio11...
        Bio.CerOSR_rain Bio.CerOSR_avElev Bio.CerOSR_aspect Bio.CerOSR_clay...
        Bio.CerOSR_urb_lake Bio.CerOSR_l_sand Bio.CerOSR_loam...
        Bio.CerOSR_s_loam Bio.CerOSR_clay_loam Bio.CerOSR_sand...
        Bio.CerOSR_silt_loam Bio.CerOSR_ph1 Bio.CerOSR_ph2 Bio.CerOSR_ph3...
        Bio.CerOSR_ph4 Bio.CerOSR_SW1 Bio.CerOSR_SW2 Bio.CerOSR_SW3...
        Bio.CerOSR_SW4 Bio.bio3_bio8 Bio.bio3_bio9 Bio.bio3_bio7...
        Bio.bio3_bio10 Bio.bio3_bio11 Bio.bio3_rain Bio.bio3_avElev...
        Bio.bio3_aspect Bio.bio3_clay Bio.bio3_urb_lake Bio.bio3_l_sand...
        Bio.bio3_loam Bio.bio3_s_loam Bio.bio3_clay_loam Bio.bio3_sand...
        Bio.bio3_silt_loam Bio.bio3_ph1 Bio.bio3_ph2 Bio.bio3_ph3...
        Bio.bio3_ph4 Bio.bio3_SW1 Bio.bio3_SW2 Bio.bio3_SW3 Bio.bio3_SW4...
        Bio.bio8_bio9 Bio.bio8_bio7 Bio.bio8_bio10 Bio.bio8_bio11...
        Bio.bio8_rain Bio.bio8_avElev Bio.bio8_aspect Bio.bio8_clay...
        Bio.bio8_urb_lake Bio.bio8_l_sand Bio.bio8_loam Bio.bio8_s_loam...
        Bio.bio8_clay_loam Bio.bio8_sand Bio.bio8_silt_loam Bio.bio8_ph1...
        Bio.bio8_ph2 Bio.bio8_ph3 Bio.bio8_ph4 Bio.bio8_SW1 Bio.bio8_SW2...
        Bio.bio8_SW3 Bio.bio8_SW4 Bio.bio9_bio7 Bio.bio9_bio10...
        Bio.bio9_bio11 Bio.bio9_rain Bio.bio9_avElev Bio.bio9_aspect...
        Bio.bio9_clay Bio.bio9_urb_lake Bio.bio9_l_sand Bio.bio9_loam...
        Bio.bio9_s_loam Bio.bio9_clay_loam Bio.bio9_sand Bio.bio9_silt_loam...
        Bio.bio9_ph1 Bio.bio9_ph2 Bio.bio9_ph3 Bio.bio9_ph4 Bio.bio9_SW1...
        Bio.bio9_SW2 Bio.bio9_SW3 Bio.bio9_SW4 Bio.bio7_bio10 Bio.bio7_bio11...
        Bio.bio7_rain Bio.bio7_avElev Bio.bio7_aspect Bio.bio7_clay...
        Bio.bio7_urb_lake Bio.bio7_l_sand Bio.bio7_loam Bio.bio7_s_loam...
        Bio.bio7_clay_loam Bio.bio7_sand Bio.bio7_silt_loam Bio.bio7_ph1...
        Bio.bio7_ph2 Bio.bio7_ph3 Bio.bio7_ph4 Bio.bio7_SW1 Bio.bio7_SW2...
        Bio.bio7_SW3 Bio.bio7_SW4 Bio.bio10_bio11 Bio.bio10_rain...
        Bio.bio10_avElev Bio.bio10_aspect Bio.bio10_clay Bio.bio10_urb_lake...
        Bio.bio10_l_sand Bio.bio10_loam Bio.bio10_s_loam Bio.bio10_clay_loam...
        Bio.bio10_sand Bio.bio10_silt_loam Bio.bio10_ph1 Bio.bio10_ph2...
        Bio.bio10_ph3 Bio.bio10_ph4 Bio.bio10_SW1 Bio.bio10_SW2...
        Bio.bio10_SW3 Bio.bio10_SW4 Bio.bio11_rain Bio.bio11_avElev...
        Bio.bio11_aspect Bio.bio11_clay Bio.bio11_urb_lake Bio.bio11_l_sand...
        Bio.bio11_loam Bio.bio11_s_loam Bio.bio11_clay_loam Bio.bio11_sand...
        Bio.bio11_silt_loam Bio.bio11_ph1 Bio.bio11_ph2 Bio.bio11_ph3...
        Bio.bio11_ph4 Bio.bio11_SW1 Bio.bio11_SW2 Bio.bio11_SW3...
        Bio.bio11_SW4 Bio.rain_avElev Bio.rain_aspect Bio.rain_clay...
        Bio.rain_urb_lake Bio.rain_l_sand Bio.rain_loam Bio.rain_s_loam...
        Bio.rain_clay_loam Bio.rain_sand Bio.rain_silt_loam Bio.rain_ph1...
        Bio.rain_ph2 Bio.rain_ph3 Bio.rain_ph4 Bio.rain_SW1 Bio.rain_SW2...
        Bio.rain_SW3 Bio.rain_SW4 Bio.avElev_aspect Bio.avElev_clay...
        Bio.avElev_urb_lake Bio.avElev_l_sand Bio.avElev_loam...
        Bio.avElev_s_loam Bio.avElev_clay_loam Bio.avElev_sand...
        Bio.avElev_silt_loam Bio.avElev_ph1 Bio.avElev_ph2 Bio.avElev_ph3...
        Bio.avElev_ph4 Bio.avElev_SW1 Bio.avElev_SW2 Bio.avElev_SW3...
        Bio.avElev_SW4 Bio.aspect_clay Bio.aspect_urb_lake Bio.aspect_l_sand...
        Bio.aspect_loam Bio.aspect_s_loam Bio.aspect_clay_loam...
        Bio.aspect_sand Bio.aspect_silt_loam Bio.aspect_ph1 Bio.aspect_ph2...
        Bio.aspect_ph3 Bio.aspect_ph4 Bio.aspect_SW1 Bio.aspect_SW2...
        Bio.aspect_SW3 Bio.aspect_SW4 Bio.clay_urb_lake Bio.clay_l_sand...
        Bio.clay_loam2 Bio.clay_s_loam Bio.clay_clay_loam Bio.clay_sand...
        Bio.clay_silt_loam Bio.clay_ph1 Bio.clay_ph2 Bio.clay_ph3...
        Bio.clay_ph4 Bio.clay_SW1 Bio.clay_SW2 Bio.clay_SW3 Bio.clay_SW4...
        Bio.urb_lake_l_sand Bio.urb_lake_loam Bio.urb_lake_s_loam...
        Bio.urb_lake_clay_loam Bio.urb_lake_sand Bio.urb_lake_silt_loam...
        Bio.urb_lake_ph1 Bio.urb_lake_ph2 Bio.urb_lake_ph3 Bio.urb_lake_ph4...
        Bio.urb_lake_SW1 Bio.urb_lake_SW2 Bio.urb_lake_SW3 Bio.urb_lake_SW4...
        Bio.l_sand_loam Bio.l_sand_s_loam Bio.l_sand_clay_loam...
        Bio.l_sand_sand Bio.l_sand_silt_loam Bio.l_sand_ph1 Bio.l_sand_ph2...
        Bio.l_sand_ph3 Bio.l_sand_ph4 Bio.l_sand_SW1 Bio.l_sand_SW2...
        Bio.l_sand_SW3 Bio.l_sand_SW4 Bio.loam_s_loam Bio.loam_clay_loam...
        Bio.loam_sand Bio.loam_silt_loam Bio.loam_ph1 Bio.loam_ph2...
        Bio.loam_ph3 Bio.loam_ph4 Bio.loam_SW1 Bio.loam_SW2 Bio.loam_SW3...
        Bio.loam_SW4 Bio.s_loam_clay_loam Bio.s_loam_sand Bio.s_loam_ph1...
        Bio.s_loam_ph2 Bio.s_loam_ph3 Bio.s_loam_ph4 Bio.s_loam_SW1...
        Bio.s_loam_SW2 Bio.s_loam_SW3 Bio.s_loam_SW4 Bio.clay_loam_sand...
        Bio.clay_loam_ph1 Bio.clay_loam_ph2 Bio.clay_loam_ph3...
        Bio.clay_loam_ph4 Bio.clay_loam_SW1 Bio.clay_loam_SW2...
        Bio.clay_loam_SW3 Bio.clay_loam_SW4 Bio.sand_ph1 Bio.sand_ph2...
        Bio.sand_ph3 Bio.sand_ph4 Bio.sand_SW1 Bio.sand_SW2 Bio.sand_SW3...
        Bio.sand_SW4 Bio.silt_loam_ph2 Bio.silt_loam_SW1 Bio.silt_loam_SW3...
        Bio.silt_loam_SW4 Bio.ph1_ph2 Bio.ph1_ph3 Bio.ph1_ph4 Bio.ph1_SW1...
        Bio.ph1_SW2 Bio.ph1_SW3 Bio.ph1_SW4 Bio.ph2_ph3 Bio.ph2_ph4...
        Bio.ph2_SW1 Bio.ph2_SW2 Bio.ph2_SW3 Bio.ph2_SW4 Bio.ph3_SW1...
        Bio.ph3_SW2 Bio.ph3_SW3 Bio.ph3_SW4 Bio.ph4_SW1 Bio.ph4_SW2...
        Bio.ph4_SW3 Bio.ph4_SW4 Bio.SW1_SW2 Bio.SW1_SW3 Bio.SW1_SW4...
        Bio.SW2_SW3 Bio.SW2_SW4 Bio.SW3_SW4];

end

