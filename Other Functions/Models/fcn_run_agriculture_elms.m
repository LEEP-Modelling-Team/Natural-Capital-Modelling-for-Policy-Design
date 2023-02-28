% FCN_RUN_AGRICULTURE
% ===================
%
% INPUTS:
%
% agriculture_data_folder
%   - path to agriculture production .mat file
% agricultureghg_data_folder 
%   - path to agriculture ghg .mat file
% MP 
%   - model parameter structure to contain following fields:
%       num_years, start_year, run_ghg, price_wheat, price_osr, price_wbar,
%       price_sbar, price_pot, price_sb, price_pnb, price_milk, price_beef,
%       price_sheep, price_fert, price_quota, irrigation
% PV
%   - primary variables structure to contain following fields:
%       new2kid, farm_ha
%
% carbon_price
%   - a vector of carbon prices from MP.start_year onwards
%
% OUTPUT:
%
% es_agriculture
%   - structure containing...

function es_agriculture = fcn_run_agriculture_elms(MP, landuses, elm_option_string, elm_ha)
   
    % (1) INITIALISE
    %  ==============
    
    % a. Constants
    % ------------
    % Number of grid cells
    ncells = length(landuses.new2kid);
    
    % Discount and annuity constants
    delta  = 1 / (1 + MP.discount_rate);
    delta_data_yrs = (delta .^ (1:MP.num_years))';	% discount vector for data years
    gamma_data_yrs = MP.discount_rate / (1 - (1 + MP.discount_rate) ^ (-MP.num_years)); % annuity constant for data years
    
    % (b) Data files 
    % --------------
    AgricultureProduction_data_mat = strcat(MP.agriculture_data_folder, 'AgricultureProduction_data.mat');
    Climate_data_mat               = strcat(MP.climate_data_folder, 'Climate_data.mat');
    AgricultureGHG_data_mat        = strcat(MP.agricultureghg_data_folder, 'AgricultureGHG_data.mat');
    load(AgricultureProduction_data_mat, 'AgricultureProduction');
    load(Climate_data_mat, 'ClimateData');
    ClimateData = ClimateData.grow_restrict;
    if MP.run_ghg
        load(AgricultureGHG_data_mat, 'AgricultureGHG');
        % Check if the size of AgricultureGHG is consistent with the number
        % of years
        if (size(AgricultureGHG.EmissionsLivestockPerHead.dairy,2) ~= MP.num_years)
            error('Rerun imports for AgricultureGHG such that the number of years matches parameters.num_years');
        end
    end
    
    % (c) Deal with climate scenarios
    % -------------------------------
    % Check climate scenario is possible
    user_defined_temp = ['Climate_cells_', MP.clim_string, '_', MP.clim_scen_string, '_temp_', MP.temp_pct_string];
    user_defined_rain = ['Climate_cells_', MP.clim_string, '_', MP.clim_scen_string, '_rain_', MP.rain_pct_string];
    
    if isfield(ClimateData, user_defined_temp) ~= 1 || isfield(ClimateData, user_defined_rain) ~= 1
        error('foo:bar', 'The climate data loaded and the climate data declared in the import functions do not match.\nMake sure you are using the same climate scenarios in the import modules and the agricultural model!\nSUGGESTION: You might need to re-run the imports')
    end
    
    % Extract temperature and rainfall for this scenario and combine
    temp = ClimateData.(['Climate_cells_', MP.clim_string, '_', MP.clim_scen_string, '_temp_', MP.temp_pct_string]);
    rain = ClimateData.(['Climate_cells_', MP.clim_string, '_', MP.clim_scen_string, '_rain_', MP.rain_pct_string]);
    
    temp = temp(:, fcn_select_years('temp', MP.start_year:(MP.start_year + MP.num_years -1)));
    rain = rain(:, fcn_select_years('rain', MP.start_year:(MP.start_year + MP.num_years -1)));
    ClimateData.Climate_cells = [temp, rain];   

%     
%     % d. Hard code old climate in
%     % ---------------------------
%     % NEV code responds to different climate, here we fix to UKCP09 A1B
%     AgricultureProduction.Climate_cells = [AgricultureProduction.Climate_cells_ukcp09_a1b_rain_50, ...
%                                            AgricultureProduction.Climate_cells_ukcp09_a1b_temp_50];
    
    % (2) Reduce to inputted 2km cells
    %  ================================
    % For inputted 2km grid cells, extract rows of relevant tables and
    % arrays in structures
    
    % (a) AgricultureProduction
    % -------------------------
    [input_cells_ind, input_cell_idx] = ismember(landuses.new2kid, AgricultureProduction.new2kid);
    input_cell_idx = input_cell_idx(input_cells_ind);
    
    % Data cells
    AgricultureProduction.Data_cells = AgricultureProduction.Data_cells(input_cell_idx, :);
    
    % Climate cells
    ClimateData.Climate_cells = ClimateData.Climate_cells(input_cell_idx, :);
        
    % (a) AgricultureGHG
    % ------------------
    if MP.run_ghg
        [input_cells_ind, input_cell_idx] = ismember(landuses.new2kid, AgricultureGHG.new2kid);
        input_cell_idx                    = input_cell_idx(input_cells_ind);
        
        % Emissions from grid
        AgricultureGHG.EmissionsGridPerHa = AgricultureGHG.EmissionsGridPerHa(input_cell_idx, :);
        
        % Emissions from livestock
        AgricultureGHG.EmissionsLivestockPerHead.dairy = AgricultureGHG.EmissionsLivestockPerHead.dairy(input_cell_idx, :, :);
        AgricultureGHG.EmissionsLivestockPerHead.beef  = AgricultureGHG.EmissionsLivestockPerHead.beef(input_cell_idx, :, :);
        AgricultureGHG.EmissionsLivestockPerHead.sheep = AgricultureGHG.EmissionsLivestockPerHead.sheep(input_cell_idx, :, :);
    end
    
    
    % (3) Check price parameters and convert it to vectors
    %  Price vectors should start from prices in the year before
    %  current_year and end at the last year, i.e. with length num_years +
    %  1, or expressed as a scalar
    %  If prices are scalar, convert it to vectors of length num_years + 1
    %  If prices are vectors, check if it has the length num_years + 1
    %  If the field is a vector but does not have length num_years + 1,
    %  return an error
    %  ===========================================
    
    % Arable
    MP.price_wheat  = fcn_vector_price_series(MP.price_wheat, MP.num_years + 1);
    MP.price_osr    = fcn_vector_price_series(MP.price_osr,   MP.num_years + 1);
    MP.price_wbar   = fcn_vector_price_series(MP.price_wbar,  MP.num_years + 1);
    MP.price_sbar   = fcn_vector_price_series(MP.price_sbar,  MP.num_years + 1);
    MP.price_pot    = fcn_vector_price_series(MP.price_pot,   MP.num_years + 1);
    MP.price_sb     = fcn_vector_price_series(MP.price_sb,    MP.num_years + 1);
    MP.price_other  = fcn_vector_price_series(MP.price_other, MP.num_years + 1);
    
    % Grassland
    MP.price_dairy  = fcn_vector_price_series(MP.price_dairy, MP.num_years + 1);
    MP.price_beef   = fcn_vector_price_series(MP.price_beef,  MP.num_years + 1);
    MP.price_sheep  = fcn_vector_price_series(MP.price_sheep, MP.num_years + 1);
    
    % Livestock gross margins
    MP.gm_beef      = fcn_vector_price_series(MP.gm_beef,     MP.num_years + 1);
    MP.gm_sheep     = fcn_vector_price_series(MP.gm_sheep,    MP.num_years + 1);
    
    % Fertiliser and quotas
    MP.price_fert   = fcn_vector_price_series(MP.price_fert,  MP.num_years + 1);
    MP.price_quota  = fcn_vector_price_series(MP.price_quota, MP.num_years + 1);
    
    
    % (4) CALCULATE AGRICULTURE PRODUCTION AND GHG ES
    %  ===============================================
    
    % (a) Preallocate arrays for output variables
    % ------------------------------------------
    % Save new2kid in es_agriculture
    es_agriculture.new2kid = landuses.new2kid;
    
    % Top level model: arable v grassland split
    es_agriculture.arable_ha = zeros(ncells, MP.num_years); % Top level output, hectares of ag land which is arable (vs grassland) in each cell
    es_agriculture.grass_ha  = zeros(ncells, MP.num_years); % Top level output, hectares of ag land which is grassland (vs arable) in each cell

    % Arable model: split of different crops
    es_agriculture.wheat_ha = zeros(ncells, MP.num_years); % Hectares in wheat for each cell by year 
    es_agriculture.osr_ha   = zeros(ncells, MP.num_years); % Hectares in Oil Seed Rape for each cell
    es_agriculture.wbar_ha  = zeros(ncells, MP.num_years); % Hectares in winter barley for each cell
    es_agriculture.sbar_ha  = zeros(ncells, MP.num_years); % Hectares in spring barley for each cell
    es_agriculture.bar_ha   = zeros(ncells, MP.num_years); % Hectares in barley for each cell (winter + spring barley)
    es_agriculture.pot_ha   = zeros(ncells, MP.num_years); % Hectares in potatoes for each cell
    es_agriculture.sb_ha    = zeros(ncells, MP.num_years); % Hectares in sugarbeet for each cell
    es_agriculture.root_ha  = zeros(ncells, MP.num_years); % Hectares in root crops (potatoes + sugarbeet) for each cell
    es_agriculture.other_ha = zeros(ncells, MP.num_years); % Hectares in other crops for each cell

    % Grassland model: split of different grassland types
    es_agriculture.pgrass_ha = zeros(ncells, MP.num_years); % Hectares of permanent grassland
    es_agriculture.tgrass_ha = zeros(ncells, MP.num_years); % Hectares of teparametersorary grassland
    es_agriculture.rgraz_ha  = zeros(ncells, MP.num_years); % Hectares of rough grazing

    % Livestock model: heads of different livestock types
    es_agriculture.dairy     = zeros(ncells, MP.num_years); % Heads of dairy cows
    es_agriculture.beef      = zeros(ncells, MP.num_years); % Heads of beef cows
    es_agriculture.sheep     = zeros(ncells, MP.num_years); % Heads of sheep
    es_agriculture.livestock = zeros(ncells, MP.num_years); % Heads of livestock

    % Food
    es_agriculture.wheat_food = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell 
    es_agriculture.osr_food   = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell 
    es_agriculture.wbar_food  = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell 
    es_agriculture.sbar_food  = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell 
    es_agriculture.pot_food   = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell 
    es_agriculture.sb_food    = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell
    es_agriculture.food       = zeros(ncells, MP.num_years); % Total tonnes of food (arable crops) produced in the cell 

    % Farm profits
    es_agriculture.arable_profit    = zeros(ncells, MP.num_years); % Profit from crops produced in the cell
    es_agriculture.livestock_profit = zeros(ncells, MP.num_years); % Profit from livestock produced in the cell
    es_agriculture.farm_profit      = zeros(ncells, MP.num_years); % Farm profit (crop profit + livestock profit);

    
    % b. Calculate agricultural production
    % ------------------------------------
    % Loop over time period and run top level, arable, grassland and
    % livestock models
    for y = 1:MP.num_years
        % Define current year within loop
        current_year = MP.start_year + y - 1;
        
        % Extract rain and temperature for current year and save in
        % climate_current_year structure
        climate_last_year.rain = eval(['ClimateData.Climate_cells.rain', num2str(current_year)]);
        climate_last_year.temp = eval(['ClimateData.Climate_cells.temp', num2str(current_year)]);
        
        % i. Calculate normalised prices of the previous year, which are
        % the information available for farmers' decision for land
        % allocation in the current year
        % n.b. price vector series starts from current_year-1
        % ----------------------------------------------------
        AgricultureProductionLastYear = AgricultureProduction;
        
        % Arable
        AgricultureProductionLastYear.Data_cells.price_wheat = AgricultureProduction.Data_cells.price_wheat + MP.price_wheat(y);
        AgricultureProductionLastYear.Data_cells.price_osr   = AgricultureProduction.Data_cells.price_osr + MP.price_osr(y);
        AgricultureProductionLastYear.Data_cells.price_wbar  = AgricultureProduction.Data_cells.price_wbar + MP.price_wbar(y);
        AgricultureProductionLastYear.Data_cells.price_sbar  = AgricultureProduction.Data_cells.price_sbar + MP.price_sbar(y);
        AgricultureProductionLastYear.Data_cells.price_pot   = AgricultureProduction.Data_cells.price_pot + MP.price_pot(y);
        AgricultureProductionLastYear.Data_cells.price_sb    = AgricultureProduction.Data_cells.price_sb + MP.price_sb(y);
        AgricultureProductionLastYear.Data_cells.price_pnb   = AgricultureProduction.Data_cells.price_pnb + MP.price_other(y);
        
        % Livestock
        AgricultureProductionLastYear.Data_cells.price_milk  = AgricultureProduction.Data_cells.price_milk + MP.price_dairy(y);
        AgricultureProductionLastYear.Data_cells.price_beef  = AgricultureProduction.Data_cells.price_beef + MP.price_beef(y);
        AgricultureProductionLastYear.Data_cells.price_sheep = AgricultureProduction.Data_cells.price_sheep + MP.price_sheep(y);
        
        % Other
        AgricultureProductionLastYear.Data_cells.price_fert  = AgricultureProduction.Data_cells.price_fert + MP.price_fert(y);
        AgricultureProductionLastYear.Data_cells.price_quota = AgricultureProduction.Data_cells.price_quota + MP.price_quota(y);
        
        % (ii) Define normalised price variables for the year based on last year's prices
        % -------------------------------------------------------------
        % Arable
        AgricultureProductionLastYear.Data_cells.nprice_wheat   = AgricultureProductionLastYear.Data_cells.price_wheat ./ AgricultureProductionLastYear.Data_cells.price_fert;
        AgricultureProductionLastYear.Data_cells.nprice_osr     = AgricultureProductionLastYear.Data_cells.price_osr   ./ AgricultureProductionLastYear.Data_cells.price_fert;
        AgricultureProductionLastYear.Data_cells.nprice_wbar    = AgricultureProductionLastYear.Data_cells.price_wbar ./ AgricultureProductionLastYear.Data_cells.price_fert;
        AgricultureProductionLastYear.Data_cells.nprice_sbar    = AgricultureProductionLastYear.Data_cells.price_sbar ./ AgricultureProductionLastYear.Data_cells.price_fert;
        AgricultureProductionLastYear.Data_cells.nprice_pot     = AgricultureProductionLastYear.Data_cells.price_pot ./ AgricultureProductionLastYear.Data_cells.price_fert;
        AgricultureProductionLastYear.Data_cells.nprice_sb      = AgricultureProductionLastYear.Data_cells.price_sb ./ AgricultureProductionLastYear.Data_cells.price_fert;
        AgricultureProductionLastYear.Data_cells.nprice_pnb     = AgricultureProductionLastYear.Data_cells.price_pnb ./ AgricultureProductionLastYear.Data_cells.price_fert;
        
        % Livestock
        AgricultureProductionLastYear.Data_cells.nprice_milk_ad = (AgricultureProductionLastYear.Data_cells.price_milk - AgricultureProductionLastYear.Data_cells.price_quota) ./ AgricultureProductionLastYear.Data_cells.price_fert; % milk ad is defined as milk price - quota price / fert price
        AgricultureProductionLastYear.Data_cells.nprice_beef    = AgricultureProductionLastYear.Data_cells.price_beef ./ AgricultureProductionLastYear.Data_cells.price_fert;
        AgricultureProductionLastYear.Data_cells.nprice_sheep   = AgricultureProductionLastYear.Data_cells.price_sheep ./ AgricultureProductionLastYear.Data_cells.price_fert;
        
        % iii. Calculate normalised prices of current year, information
        % used for gross margins calculation
        % ----------------------------------------------------
        AgricultureProductionCurrentYear = AgricultureProduction;
        
        % Arable
        AgricultureProductionCurrentYear.Data_cells.price_wheat = AgricultureProduction.Data_cells.price_wheat + MP.price_wheat(y+1);
        AgricultureProductionCurrentYear.Data_cells.price_osr   = AgricultureProduction.Data_cells.price_osr + MP.price_osr(y+1);
        AgricultureProductionCurrentYear.Data_cells.price_wbar  = AgricultureProduction.Data_cells.price_wbar + MP.price_wbar(y+1);
        AgricultureProductionCurrentYear.Data_cells.price_sbar  = AgricultureProduction.Data_cells.price_sbar + MP.price_sbar(y+1);
        AgricultureProductionCurrentYear.Data_cells.price_pot   = AgricultureProduction.Data_cells.price_pot + MP.price_pot(y+1);
        AgricultureProductionCurrentYear.Data_cells.price_sb    = AgricultureProduction.Data_cells.price_sb + MP.price_sb(y+1);
        AgricultureProductionCurrentYear.Data_cells.price_pnb   = AgricultureProduction.Data_cells.price_pnb + MP.price_other(y+1);
        
        % Livestock
        AgricultureProductionCurrentYear.Data_cells.price_milk  = AgricultureProduction.Data_cells.price_milk + MP.price_dairy(y+1);
        AgricultureProductionCurrentYear.Data_cells.price_beef  = AgricultureProduction.Data_cells.price_beef + MP.price_beef(y+1);
        AgricultureProductionCurrentYear.Data_cells.price_sheep = AgricultureProduction.Data_cells.price_sheep + MP.price_sheep(y+1);
        
        % Other
        AgricultureProductionCurrentYear.Data_cells.price_fert  = AgricultureProduction.Data_cells.price_fert + MP.price_fert(y+1);
        AgricultureProductionCurrentYear.Data_cells.price_quota = AgricultureProduction.Data_cells.price_quota + MP.price_quota(y+1);

        % i. Instead of running the top level model, use the top-level split
        %    resulting from the ELMS selected
        switch elm_option_string
            case {'arable_reversion_sng_access', 'arable_reversion_wood_access', 'arable_reversion_sng_noaccess', 'arable_reversion_wood_noaccess', }
                % for cells taking option, arable_ha stays at zero but grass_ha set to farm_ha - elm_ha
%                 es_agriculture.arable_ha(which_cells,y) = 0;
                es_agriculture.grass_ha(:, y)  = landuses.farm_ha - elm_ha;
            case {'destocking_sng_access', 'destocking_wood_access', 'destocking_sng_noaccess', 'destocking_wood_noaccess'}
                % for cells taking option, grass_ha stays at zero but arable_ha set to farm_ha - elm_ha
                es_agriculture.arable_ha(:, y) = landuses.farm_ha - elm_ha;
%                 es_agriculture.grass_ha(which_cells,y) = 0;
            case {'ar_sng_d_sng', 'ar_sng_d_w', 'ar_w_d_sng', 'ar_w_sn_w','ar_sng_d_sng_na', 'ar_sng_d_w_na', 'ar_w_d_sng_na', 'ar_w_sn_w_na'}
                % Combination options will be in here - everything remains
                % at zero
            otherwise
                error('ELM option not found!')
        end
        
        % ii. Run arable model - crop hectares, food, profit
        % --------------------------------------------------
        arable_info = fcn_calc_arable(es_agriculture.arable_ha(:, y), AgricultureProductionLastYear.Data_cells, climate_last_year, AgricultureProductionCurrentYear.Data_cells, AgricultureProduction.Coefficients.Arable, MP.irrigation);
        es_agriculture.wheat_ha(:, y)      = arable_info.wheat_ha;
        es_agriculture.osr_ha(:, y)        = arable_info.osr_ha;
        es_agriculture.wbar_ha(:, y)       = arable_info.wbar_ha;
        es_agriculture.sbar_ha(:, y)       = arable_info.sbar_ha;
        es_agriculture.bar_ha(:, y)        = arable_info.bar_ha;
        es_agriculture.pot_ha(:, y)        = arable_info.pot_ha;
        es_agriculture.sb_ha(:, y)         = arable_info.sb_ha;
        es_agriculture.root_ha(:, y)       = arable_info.root_ha;
        es_agriculture.other_ha(:, y)      = arable_info.other_ha;
        es_agriculture.wheat_food(:, y)    = arable_info.wheat_food;
        es_agriculture.osr_food(:, y)      = arable_info.osr_food;
        es_agriculture.wbar_food(:, y)     = arable_info.wbar_food;
        es_agriculture.sbar_food(:, y)     = arable_info.sbar_food;
        es_agriculture.pot_food(:, y)      = arable_info.pot_food;
        es_agriculture.sb_food(:, y)       = arable_info.sb_food;
        es_agriculture.food(:, y)          = arable_info.food;
        es_agriculture.wheat_profit(:, y)  = arable_info.wheat_profit;
        es_agriculture.osr_profit(:, y)    = arable_info.osr_profit;
        es_agriculture.wbar_profit(:, y)   = arable_info.wbar_profit;
        es_agriculture.sbar_profit(:, y)   = arable_info.sbar_profit;
        es_agriculture.pot_profit(:, y)    = arable_info.pot_profit;
        es_agriculture.sb_profit(:, y)     = arable_info.sb_profit;
        es_agriculture.other_profit(:, y)  = arable_info.other_profit;        
        es_agriculture.arable_profit(:, y) = arable_info.arable_profit;
        
        % iii. Run grassland model - grassland hectares
        % ---------------------------------------------
        grass_info = fcn_calc_grass(es_agriculture.grass_ha(:, y), AgricultureProductionLastYear.Data_cells, climate_last_year, AgricultureProduction.Coefficients.Grass);
        es_agriculture.pgrass_ha(:, y) = grass_info.pgrass_ha;
        es_agriculture.tgrass_ha(:, y) = grass_info.tgrass_ha;
        es_agriculture.rgraz_ha(:, y)  = grass_info.rgraz_ha;
        
        % iv. Run livestock model - heads of livestock, profit
        % ----------------------------------------------------
        
        % Calculate gross margins of current year for beef and sheep
        MP.gm_beef  = MP.gm_beef(y+1);
        MP.gm_sheep = MP.gm_sheep(y+1);
        
        livestock_info = fcn_calc_livestock(es_agriculture.grass_ha(:, y), AgricultureProductionLastYear.Data_cells, climate_last_year, AgricultureProduction.Coefficients.Livestock, MP);
        es_agriculture.dairy(:, y) = livestock_info.dairy;
        es_agriculture.beef(:, y) = livestock_info.beef;
        es_agriculture.sheep(:, y) = livestock_info.sheep;
        es_agriculture.livestock(:, y) = livestock_info.livestock;
        es_agriculture.dairy_profit(:, y)  = livestock_info.dairy_profit;
        es_agriculture.beef_profit(:, y)  = livestock_info.beef_profit;
        es_agriculture.sheep_profit(:, y)  = livestock_info.sheep_profit;
        es_agriculture.livestock_profit(:, y) = livestock_info.livestock_profit;
        
        % Total farm profit =  arable profit + livestock profit
        es_agriculture.farm_profit(:, y) = es_agriculture.arable_profit(:, y) + es_agriculture.livestock_profit(:, y);
    end
    
    % (c) Calculate farm profit annuities
    % -----------------------------------
    % Total farm profit
    es_agriculture.farm_profit_ann = (es_agriculture.farm_profit * delta_data_yrs) * gamma_data_yrs;

    % Arable profit (+ individual crop profits)
    es_agriculture.arable_profit_ann = (es_agriculture.arable_profit * delta_data_yrs) * gamma_data_yrs;
	es_agriculture.wheat_profit_ann = (es_agriculture.wheat_profit * delta_data_yrs) * gamma_data_yrs;
	es_agriculture.osr_profit_ann = (es_agriculture.osr_profit * delta_data_yrs) * gamma_data_yrs;
	es_agriculture.wbar_profit_ann = (es_agriculture.wbar_profit * delta_data_yrs) * gamma_data_yrs;
	es_agriculture.sbar_profit_ann = (es_agriculture.sbar_profit * delta_data_yrs) * gamma_data_yrs;
	es_agriculture.pot_profit_ann = (es_agriculture.pot_profit * delta_data_yrs) * gamma_data_yrs;
	es_agriculture.sb_profit_ann = (es_agriculture.sb_profit * delta_data_yrs) * gamma_data_yrs;
	es_agriculture.other_profit_ann = (es_agriculture.other_profit * delta_data_yrs) * gamma_data_yrs;
    
    % Livestock profit (+ individual livestock profits
    es_agriculture.livestock_profit_ann = (es_agriculture.livestock_profit * delta_data_yrs) * gamma_data_yrs;
	es_agriculture.dairy_profit_ann = (es_agriculture.dairy_profit * delta_data_yrs) * gamma_data_yrs;
	es_agriculture.beef_profit_ann = (es_agriculture.beef_profit * delta_data_yrs) * gamma_data_yrs;
	es_agriculture.sheep_profit_ann = (es_agriculture.sheep_profit * delta_data_yrs) * gamma_data_yrs;	

    
    % d. Calculate agricultural emissions
    % -----------------------------------
    % Multiply hectares of crops/grassland & heads of livestock by
    % pre-calculated per hectare & per head emissions from Cool Farm Tool
    % Divide by 1000 to get quantities in tons
    if MP.run_ghg
        % i. Emissions quantities
        % -----------------------
        % Note: we multiply by -1 here to view emissions as negative
        % sequestration
        
        % Multiply hectares of crop types by per hectare emissions 
        es_agriculture.ghg_wheat = - (es_agriculture.wheat_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.cer, [1, MP.num_years]) ./ 1000);
        es_agriculture.ghg_osr = - (es_agriculture.osr_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.osrape, [1, MP.num_years]) ./ 1000);
        es_agriculture.ghg_wbar = - (es_agriculture.wbar_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.cer, [1, MP.num_years]) ./ 1000);
        es_agriculture.ghg_sbar = - (es_agriculture.sbar_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.cer, [1, MP.num_years]) ./ 1000);
        es_agriculture.ghg_pot = - (es_agriculture.pot_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.root, [1, MP.num_years]) ./ 1000);
        es_agriculture.ghg_sb = - (es_agriculture.sb_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.root, [1, MP.num_years]) ./ 1000);
        es_agriculture.ghg_other = - (es_agriculture.other_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.other, [1, MP.num_years]) ./ 1000);
        
        % Total emissions from arable
        es_agriculture.ghg_arable = es_agriculture.ghg_wheat + es_agriculture.ghg_osr + es_agriculture.ghg_wbar + es_agriculture.ghg_sbar + es_agriculture.ghg_pot + es_agriculture.ghg_sb + es_agriculture.ghg_other;
                
        % Multiply hectares of grassland types by per hectare emissions
        es_agriculture.ghg_pgrass = - (es_agriculture.pgrass_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.pgrass, [1, MP.num_years]) ./ 1000);
        es_agriculture.ghg_tgrass = - (es_agriculture.tgrass_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.tgrass, [1, MP.num_years]) ./ 1000);
        es_agriculture.ghg_rgraz = - (es_agriculture.rgraz_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.rgraz, [1, MP.num_years]) ./ 1000);
        
        % Total emissions from grassland
        es_agriculture.ghg_grass = es_agriculture.ghg_pgrass + es_agriculture.ghg_tgrass + es_agriculture.ghg_rgraz;
                
        % Multiply heads of livestock types by per head emissions
        es_agriculture.ghg_dairy = - (es_agriculture.dairy .* AgricultureGHG.EmissionsLivestockPerHead.dairy ./ 1000);
        es_agriculture.ghg_beef = - (es_agriculture.beef .* AgricultureGHG.EmissionsLivestockPerHead.beef ./ 1000);
        es_agriculture.ghg_sheep = - (es_agriculture.sheep .* AgricultureGHG.EmissionsLivestockPerHead.sheep ./ 1000);
        
        % Total emissions from livestock
        es_agriculture.ghg_livestock = es_agriculture.ghg_dairy + es_agriculture.ghg_beef + es_agriculture.ghg_sheep;
                
        % Total emissions from agriculture
        es_agriculture.ghg_farm = es_agriculture.ghg_arable + es_agriculture.ghg_grass + es_agriculture.ghg_livestock;
        
        % ii. Emissions value annuity
        % ---------------------------        
        % Turn agricultural greenhouse gas emissions into annuities via 
        % multiplying by carbon price.

        % Set up discounted carbon prices
        carbon_disc_price = MP.carbon_price(1:MP.num_years) .* delta_data_yrs;

        % Total agricultural emissions annuity
        es_agriculture.ghg_farm_ann = (es_agriculture.ghg_farm * carbon_disc_price) * gamma_data_yrs;
        
        % Emissions from arable annuity
        es_agriculture.ghg_arable_ann = (es_agriculture.ghg_arable * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_wheat_ann = (es_agriculture.ghg_wheat * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_osr_ann = (es_agriculture.ghg_osr * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_wbar_ann = (es_agriculture.ghg_wbar * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_sbar_ann = (es_agriculture.ghg_sbar * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_pot_ann = (es_agriculture.ghg_pot * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_sb_ann = (es_agriculture.ghg_sb * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_other_ann = (es_agriculture.ghg_other * carbon_disc_price) * gamma_data_yrs;

        % Emissions from grass annuity
        es_agriculture.ghg_grass_ann = (es_agriculture.ghg_grass * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_pgrass_ann = (es_agriculture.ghg_pgrass * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_tgrass_ann = (es_agriculture.ghg_tgrass * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_rgraz_ann = (es_agriculture.ghg_rgraz * carbon_disc_price) * gamma_data_yrs;

        % Emissions from livestock
        es_agriculture.ghg_livestock_ann = (es_agriculture.ghg_livestock * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_dairy_ann = (es_agriculture.ghg_dairy * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_beef_ann = (es_agriculture.ghg_beef * carbon_disc_price) * gamma_data_yrs;
		es_agriculture.ghg_sheep_ann = (es_agriculture.ghg_sheep * carbon_disc_price) * gamma_data_yrs;
		
    end
    
end