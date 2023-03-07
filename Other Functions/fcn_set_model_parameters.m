function MP = fcn_set_model_parameters(conn, json, server_flag)

     MP = jsondecode(json);
    
    % SET OTHER MODEL PARAMETERS    
    % ==========================
        
    % Analysis parameters
    % -------------------
    MP.price_year    = 2020;   % All model monetary values to be expressed in £price_year from rpi 
    MP.base_year     = 2020;   % All model monetary values to be expressed in npvs at base_year
    MP.discount_rate = 0.035;
    % Round output
    MP.rounding = true;
    
    % Climate parameters
    % ------------------
    MP.clim_string      = 'ukcp18';
    MP.clim_scen_string = 'rcp60';
    MP.temp_pct_string  = '50';
    MP.rain_pct_string  = '50';

    % Carbon Prices
    % -------------
    MP.carbon_price_str = 'non_trade_central';  % e.g. 'scc', 'non_trade_low', 'non_trade_central', 'non_trade_high'
    if strcmp(MP.carbon_price_str,'scc')
        % Read in SCC from:
        %   Technical Support Document: Social Cost of Carbon, Methane, and Nitrous Oxide
        %   Interim Estimates under Executive Order 13990
        %   Interagency Working Group on Social Cost of Greenhouse Gases, United States Government 
        %   Feb 2021
        %     Data is from 2020 to 2050 and in $US 2020 per tonne CO2 we use 
        %     the average estimate at 3% discount rate
        scc_data_file = 'D:\mydata\Research\Projects (Land Use)\Defra_ELMS\Data\scc\tsd_2021_annual_unrounded.csv';
        scc_table     = readtable(scc_data_file);
        carbon_price  = scc_table.x3_0__CO2;
        % Extend to 300 years.
        %  (i)  persist price growth until 2100
        %  (ii) maintain same scc from 2100 to 2320 as per UK time series
        incr   = carbon_price(end)-carbon_price(end-1);
        carbon_price = [carbon_price; (carbon_price(end):incr:(carbon_price(end)+incr*(50-1)))'];
        carbon_price = [carbon_price; repelem(carbon_price(end), 220)'];
        % convert from dollars to pounds at 2020 exchange rate
        carbon_price = carbon_price/1.2837;    
    else
        carbon_price = fcn_get_carbon_price(conn, MP.carbon_price_str);
    end
    MP.carbon_price = carbon_price;

    % Agriculture model
    % -----------------
    % NB. The standard climate is ukcp09 a1b 50th percentile temperature 
    % and 50th percentile precipitation. It is possible to specify another
    % climate among the following: 1) clim_string: 'ukcp09', 'ukcp18';
    % 2) clim_scen_string: 'rcp26', 'rcp45', 'rcp60', 'rcp85'; 'a1b'; 
    % 3) temp_pct_string: 50, 70, 90; 3) rain_pct_string: 50, 70, 90.
    % 'a1b' belongs to 'ukcp09', all the RCPs belong to 'ukcp18'
    MP.num_years        = 40;
    MP.start_year       = 2020;
    MP.run_ghg          = true;
    MP.per_ha           = true;
    MP.price_wheat      = 29;
    MP.price_osr        = 78;
    MP.price_wbar       = 18;
    MP.price_sbar       = 20;
    MP.price_pot        = 45;
    MP.price_sb         = -9;
    MP.price_other      = 0;
    MP.price_dairy      = 4;
    MP.price_beef       = 154;
    MP.price_sheep      = 58;
    MP.price_fert       = -11;
    MP.price_quota      = -6;
    MP.gm_beef          = 130; % Nix 2021 deviation from default (200 - 70)
    MP.gm_sheep         = 46;  % Nix 2021 deviation from default (55 - 9)
    MP.irrigation       = true;
    
    % Agricultural land class (ALC) based yield scaling
    % First column: agricultural land class; Second column: gross margin scale
    % factor. If yield factors for an ALC is not specified, it will default to 1
    MP.alc_yield_factor = [1, 1.2;
                           2, 1.1;
                           3, 0.95;
                           4, 0.95;
                           5, 0.95;
                           6, 0.95;
                           7, 0.95];    
    
    % Forestry model
    % --------------
    % Price change is defined as difference from £30 (Oak) and £22 (Sitka Spruce)
    % Need to work out percentage change multiplication factor to multiply time series of actual timber prices
    % Timber price actually changed in fcn_run_forestry
    MP.price_broad = 0;
    MP.price_conif = 0;
    MP.price_broad_factor = (30 + MP.price_broad)/30;
    MP.price_conif_factor = (22 + MP.price_conif)/22;                           
        
    % Forest growth weights
    MP.forest_growth_years = 25;
    tser = 0:(1/MP.forest_growth_years):1;
    tser = tser(2:end);
    mu = 0.5;
    s  = 8;    
    MP.forest_growth_wgt  = 1./(1 + exp(-s*(tser - mu)));    
    
    
    % Recreation model
    % ----------------
    % Assumptions regarding type of site created on 'access' options and
    % how the ORVal model should treat these with respect to subsitution.
    MP.visval_type      = 'simultaneous';  % 'simultaneous' or 'independent' valuation wrt to substituion possibilities 
    MP.site_type_wood   = 'path_new';      %  'park_new' or 'path_new' type of site created
    MP.site_type_sng    = 'path_new';      %  'park_new' or 'path_new' type of site created      
    MP.site_area2length = 'diameter';      %  'diameter' or 'perimeter' type of site created  

    
    % Flooding model
    % --------------
	% Include damages from changes in events of different magnitudes:
	% 'low':    use 10 and 30 year events
	% 'medium': use 10, 30 and 100 year events
	% 'high':   use 10, 30, 100 and 1000 year events
    % MP.assumption_flooding = 'low';			 % low estimate
    % MP.assumption_flooding = 'medium';			% medium estimate
    MP.assumption_flooding = 'high';             % high estimate    
    
    % Non-use models
    % --------------
    % Set proportion of non use values to take
    MP.non_use_proportion = 0.38;
    % MP.non_use_proportion = 0.75;
    % MP.non_use_proportion = 1;

    % Set non-use habitat assumption
    MP.assumption_areas = 'SDA';
    % MP.assumption_areas = 'LFA';

    % Set non-use pollination assumptions
    % WTP
    MP.assumption_wtp = 'low';
    % MP.assumption_wtp = 'high';

    % Population
    MP.assumption_pop = 'low';
    % MP.assumption_pop = 'high';


    % Biodiversity models
    % -------------------
    MP.biodiversity_unit_value = 0;			% turn biodiversity benefits off
    MP.bio_pct_increase_target = 0.10;
    % MP.biodiversity_unit_value = 500;
    
        
    % Food Imports co2
    % ----------------
    %  Factors to translate farm yields/stocks to quantities of food
    MP.farm2food_arable = 1;  % tonnes 
    MP.farm2food_wheat  = 1;  % tonnes 
    MP.farm2food_osr    = 1;  % tonnes 
    MP.farm2food_wbar   = 1;  % tonnes 
    MP.farm2food_sbar   = 1;  % tonnes 
    MP.farm2food_pot    = 1;  % tonnes 
    MP.farm2food_sb     = 1;  % tonnes 
    MP.farm2food_other  = 1;  % tonnes 
    MP.farm2food_dairy  = 8153 * 0.564 * 1.03 * 1/1000;  
                              % head of dairy to tonnes of milk per year
                              %   8153   litres per year from milking cows over 2 years (ADHB, 2021)
                              %   1.03   litres to kg
                              %   0.564  milking cows as proportion of dairy herd (average 2014-18, ADHB) 
                              %   1/1000 kg to tonnnes
    MP.farm2food_beef   = 0.136;
                              % head of beef to tonnes of dead weight beef per year 
                              %   deadweight meat production per head of beef herd (average 2014-18, ADHB) 
    MP.farm2food_sheep  = 0.00871;  
                              % head of sheep to tonnes of dead weight lamb & mutton  
                              %   deadweight meat production per head of sheep herd (average 2014-18, ADHB) 
    
    %  Factors to translate quantities of food imports to tonnes co2e per year
    %  Calculated from faostat, eurostat and UK gov figures
    MP.food2co2_arable = 0.2498;  % arable
    MP.food2co2_wheat  = 0.2498;  % arable
    MP.food2co2_osr    = 0.2498;  % arable
    MP.food2co2_wbar   = 0.2498;  % arable
    MP.food2co2_sbar   = 0.2498;  % arable
    MP.food2co2_pot    = 0.2498;  % arable
    MP.food2co2_sb     = 0.2498;  % arable
    MP.food2co2_other  = 0.2498;  % arable
    MP.food2co2_dairy  = 0.7566;
    MP.food2co2_beef   = 18.3413;
    MP.food2co2_sheep  = 23.4938;    
    
    
    % RPI Adjustment Factors 
    % ----------------------    
    % Bring in rpi index data (1987-2020)
    sqlquery = ['SELECT year, rpi ',...
                'FROM greenbook.rpi ', ...
                'ORDER BY year'];
    sqlerror(exec(conn,sqlquery));
    setdbprefs('DataReturnFormat','numeric');
    rpidata  = fetch(exec(conn,sqlquery));    
    MP.rpi_all = rpidata.Data(:,1:2);

    % rpi Adjustment of costs to account for inflation
    MP.rpi_farm    = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2018),2);       %Data year = 2018
    MP.rpi_forest  = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2012),2);       %Data year = 2012 (assumed from UK NEAFO project when data sourced from FR)        
    MP.rpi_rec     = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2016),2);       %Data year = 2016
    MP.rpi_rec_cst = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2020),2);       %Data year = 2020
    MP.rpi_totn    = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2019),2);       %Data year = 2019
    MP.rpi_totp    = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2019),2);       %Data year = 2019
    MP.rpi_flood   = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2018),2);       %Data year = 2018
    MP.rpi_wq_nu   = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2008),2);       %Data year = 2008
    MP.rpi_yldpoll = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2017),2);       %Data year = 2017
    MP.rpi_nupoll  = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2014),2);       %Data year = 2014
    MP.rpi_ghg     = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2020),2);       %Data year = 2020
    MP.rpi_nuhab   = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2005),2);       %Data year = 2005
    MP.rpi_biod    = MP.rpi_all(find(MP.rpi_all==MP.price_year),2)/MP.rpi_all(find(MP.rpi_all==2020),2);       %Data year = 2020
    
    % Data Paths
    % ----------
    % Set path to model data folders
    % Differs depending on server or local machine
    if server_flag        
        % Server
        MP.agriculture_data_folder = '/opt/routing/nevo/data/agriculture/';
        MP.agricultureghg_data_folder = '/opt/routing/nevo/data/ghg/';
        MP.forest_data_folder = '/opt/routing/nevo/data/forestry/';
        MP.forestghg_data_folder = '/opt/routing/nevo/data/ghg/';
        MP.rec_data_folder = '/opt/routing/nevo/data/recreation/';
        MP.biodiversity_data_folder = '/opt/routing/nevo/data/biodiversity/';
        MP.water_data_folder = '/opt/routing/nevo/data/water/';
        
    else        
        % Local machine
        paths = fcn_set_data_paths();
        f = fieldnames(paths);
        for i = 1:length(f)
            MP.(f{i}) = paths.(f{i});
        end
    end
  
           
    % Fix issue with id's of length 1
    if MP.feature_type ~= "integrated_2km" && MP.feature_type ~= "integrated_basins" && size(MP.id,1) == 1
       MP.id = {MP.id};
    end
    
end
