%% FCN_RUN_AGRICULTURE
%  ===================
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

function es_agriculture = fcn_run_agriculture_elms(agriculture_data_folder, ...
                                                   agricultureghg_data_folder, ...
                                                   MP, ...
                                                   PV, ...
                                                   carbon_price, ...
                                                   elm_option_string, ...
                                                   elm_ha)

    %% (1) INITIALISE
    %  ==============
    
    % a. Constants
    % ------------
    % Number of grid cells
    ncells = length(PV.new2kid);
    
    % Discount and annuity constants
    delta  = 1 / (1 + MP.discount_rate);
    delta_data_yrs = (delta .^ (1:MP.num_years))';	% discount vector for data years
    gamma_data_yrs = MP.discount_rate / (1 - (1 + MP.discount_rate) ^ (-MP.num_years)); % annuity constant for data years
    
    % b. Data files 
    % -------------
    NEVO_AgricultureProduction_data_mat = strcat(agriculture_data_folder, 'NEVO_AgricultureProduction_data.mat');
    NEVO_AgricultureGHG_data_mat = strcat(agricultureghg_data_folder, 'NEVO_AgricultureGHG_data.mat');
    
    % c. NEVO mats from ImportAgriculture
    % -----------------------------------
    load(NEVO_AgricultureProduction_data_mat);
    if MP.run_ghg
        load(NEVO_AgricultureGHG_data_mat);
    end
    
    % d. Hard code old climate in
    % ---------------------------
    % NEV code responds to different climate, here we fix to UKCP09 A1B
    AgricultureProduction.Climate_cells = [AgricultureProduction.Climate_cells_ukcp09_a1b_rain_50, ...
                                           AgricultureProduction.Climate_cells_ukcp09_a1b_temp_50];
    
    %% (2) DATA FOR NEVO INPUT CELLS
    %  =============================
    % Extract NEVO Input Cells for relevant tables and arrays in
    % AgricultureProduction and AgricultureGHG structures
    
    % AgricultureProduction
    [input_cells_ind, input_cell_idx] = ismember(PV.new2kid, AgricultureProduction.new2kid);
    input_cell_idx                    = input_cell_idx(input_cells_ind);
        
    AgricultureProduction.Data_cells = AgricultureProduction.Data_cells(input_cell_idx,:);
    AgricultureProduction.Climate_cells = AgricultureProduction.Climate_cells(input_cell_idx,:);
        
    if MP.run_ghg
        % AgricultureGHG
        [input_cells_ind, input_cell_idx] = ismember(PV.new2kid, AgricultureGHG.new2kid);
        input_cell_idx                    = input_cell_idx(input_cells_ind);
        
        AgricultureGHG.EmissionsGridPerHa = AgricultureGHG.EmissionsGridPerHa(input_cell_idx,:);
        AgricultureGHG.EmissionsLivestockPerHead.dairy = AgricultureGHG.EmissionsLivestockPerHead.dairy(input_cell_idx,:,:);
        AgricultureGHG.EmissionsLivestockPerHead.beef = AgricultureGHG.EmissionsLivestockPerHead.beef(input_cell_idx,:,:);
        AgricultureGHG.EmissionsLivestockPerHead.sheep = AgricultureGHG.EmissionsLivestockPerHead.sheep(input_cell_idx,:,:);
    end
    
    %% (3) USER PROVIDED UPDATES FOR THIS NEVO ALTER
    %  =============================================
    
    % a. Update prices
    % ----------------
    
    % Arable
    AgricultureProduction.Data_cells.price_wheat = AgricultureProduction.Data_cells.price_wheat + MP.price_wheat;
    AgricultureProduction.Data_cells.price_osr   = AgricultureProduction.Data_cells.price_osr + MP.price_osr;
    AgricultureProduction.Data_cells.price_wbar  = AgricultureProduction.Data_cells.price_wbar + MP.price_wbar;
    AgricultureProduction.Data_cells.price_sbar  = AgricultureProduction.Data_cells.price_sbar + MP.price_sbar;
    AgricultureProduction.Data_cells.price_pot   = AgricultureProduction.Data_cells.price_pot + MP.price_pot;
    AgricultureProduction.Data_cells.price_sb    = AgricultureProduction.Data_cells.price_sb + MP.price_sb;
    AgricultureProduction.Data_cells.price_pnb   = AgricultureProduction.Data_cells.price_pnb + MP.price_other;

    % Livestock
    AgricultureProduction.Data_cells.price_milk  = AgricultureProduction.Data_cells.price_milk + MP.price_dairy;
    AgricultureProduction.Data_cells.price_beef  = AgricultureProduction.Data_cells.price_beef + MP.price_beef;
    AgricultureProduction.Data_cells.price_sheep = AgricultureProduction.Data_cells.price_sheep + MP.price_sheep;

    % Other
    AgricultureProduction.Data_cells.price_fert  = AgricultureProduction.Data_cells.price_fert + MP.price_fert;
    AgricultureProduction.Data_cells.price_quota = AgricultureProduction.Data_cells.price_quota + MP.price_quota;
    
    % b. Define normalised price variables based on updated prices
    % ------------------------------------------------------------
    
    % Arable
    AgricultureProduction.Data_cells.nprice_wheat = AgricultureProduction.Data_cells.price_wheat ./ AgricultureProduction.Data_cells.price_fert;
    AgricultureProduction.Data_cells.nprice_osr = AgricultureProduction.Data_cells.price_osr ./ AgricultureProduction.Data_cells.price_fert;
    AgricultureProduction.Data_cells.nprice_wbar = AgricultureProduction.Data_cells.price_wbar ./ AgricultureProduction.Data_cells.price_fert;
    AgricultureProduction.Data_cells.nprice_sbar = AgricultureProduction.Data_cells.price_sbar ./ AgricultureProduction.Data_cells.price_fert;
    AgricultureProduction.Data_cells.nprice_pot = AgricultureProduction.Data_cells.price_pot ./ AgricultureProduction.Data_cells.price_fert;
    AgricultureProduction.Data_cells.nprice_sb = AgricultureProduction.Data_cells.price_sb ./ AgricultureProduction.Data_cells.price_fert;
    AgricultureProduction.Data_cells.nprice_pnb = AgricultureProduction.Data_cells.price_pnb ./ AgricultureProduction.Data_cells.price_fert;

    % Livestock
    AgricultureProduction.Data_cells.nprice_milk_ad = (AgricultureProduction.Data_cells.price_milk - AgricultureProduction.Data_cells.price_quota) ./ AgricultureProduction.Data_cells.price_fert; % milk ad is defined as milk price - quota price / fert price
    AgricultureProduction.Data_cells.nprice_beef = AgricultureProduction.Data_cells.price_beef ./ AgricultureProduction.Data_cells.price_fert;
    AgricultureProduction.Data_cells.nprice_sheep = AgricultureProduction.Data_cells.price_sheep ./ AgricultureProduction.Data_cells.price_fert;
    
    %% (4) CALCULATE AGRICULTURE PRODUCTION AND GHG ES
    %  ===============================================
    
    % a. Preallocate arrays for output variables
    % ------------------------------------------
    
    % Top level model: arable v grassland split
    es_agriculture.arable_ha = zeros(ncells, MP.num_years); % Top level output, hectares of ag land which is arable (vs grassland) in each cell
    es_agriculture.grass_ha = zeros(ncells, MP.num_years); % Top level output, hectares of ag land which is grassland (vs arable) in each cell

    % Arable model: split of different crops
    es_agriculture.wheat_ha = zeros(ncells, MP.num_years); % Hectares in wheat for each cell by year 
    es_agriculture.osr_ha = zeros(ncells, MP.num_years); % Hectares in Oil Seed Rape for each cell
    es_agriculture.wbar_ha = zeros(ncells, MP.num_years); % Hectares in winter barley for each cell
    es_agriculture.sbar_ha = zeros(ncells, MP.num_years); % Hectares in spring barley for each cell
    es_agriculture.bar_ha = zeros(ncells, MP.num_years); % Hectares in barley for each cell (winter + spring barley)
    es_agriculture.pot_ha = zeros(ncells, MP.num_years); % Hectares in potatoes for each cell
    es_agriculture.sb_ha = zeros(ncells, MP.num_years); % Hectares in sugarbeet for each cell
    es_agriculture.root_ha = zeros(ncells, MP.num_years); % Hectares in root crops (potatoes + sugarbeet) for each cell
    es_agriculture.other_ha = zeros(ncells, MP.num_years); % Hectares in other crops for each cell

    % Grassland model: split of different grassland types
    es_agriculture.pgrass_ha = zeros(ncells, MP.num_years); % Hectares of permanent grassland
    es_agriculture.tgrass_ha = zeros(ncells, MP.num_years); % Hectares of temporary grassland
    es_agriculture.rgraz_ha = zeros(ncells, MP.num_years); % Hectares of rough grazing

    % Livestock model: heads of different livestock types
    es_agriculture.dairy = zeros(ncells, MP.num_years); % Heads of dairy cows
    es_agriculture.beef = zeros(ncells, MP.num_years); % Heads of beef cows
    es_agriculture.sheep = zeros(ncells, MP.num_years); % Heads of sheep
    es_agriculture.livestock = zeros(ncells, MP.num_years); % Heads of livestock

    % Food
    es_agriculture.wheat_food = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell 
    es_agriculture.osr_food = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell 
    es_agriculture.wbar_food = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell 
    es_agriculture.sbar_food = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell 
    es_agriculture.pot_food = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell 
    es_agriculture.sb_food = zeros(ncells, MP.num_years); % Total tonnes of food produced in the cell
    es_agriculture.food = zeros(ncells, MP.num_years); % Total tonnes of food (arable crops) produced in the cell 

    % Farm profits
    es_agriculture.arable_profit = zeros(ncells, MP.num_years); % Profit from crops produced in the cell
    es_agriculture.livestock_profit = zeros(ncells, MP.num_years); % Profit from livestock produced in the cell
    es_agriculture.farm_profit = zeros(ncells, MP.num_years); % Farm profit (crop profit + livestock profit);
    
    % b. Calculate agricultural production
    % ------------------------------------
    % Run Carlo's top level, arable, grassland and livestock models by
    % looping over the 40 year time period
    for y = 1:MP.num_years
        
        % Define current year within loop
        current_year = MP.start_year + y - 1;
        
        % Extract rain and temperature for current year and save in
        % climate_current_year structure
        climate_current_year.rain = eval(['AgricultureProduction.Climate_cells.rain' num2str(current_year)]);
        climate_current_year.temp = eval(['AgricultureProduction.Climate_cells.temp' num2str(current_year)]);
        
        % Run top level Model - arable & grassland hectares
%         es_agriculture.arable_ha(:,y) = fcn_calc_toplevel(PV.farm_ha, AgricultureProduction.Data_cells, climate_current_year, AgricultureProduction.Coefficients.TopLevel, MP.irrigation);
%         es_agriculture.grass_ha(:,y)  = PV.farm_ha - es_agriculture.arable_ha(:,y);
        switch elm_option_string
            case {'arable_reversion_sng_access', 'arable_reversion_wood_access', 'arable_reversion_sng_noaccess', 'arable_reversion_wood_noaccess', }
                % for cells taking option, arable_ha stays at zero but grass_ha set to farm_ha - elm_ha
%                 es_agriculture.arable_ha(which_cells,y) = 0;
                es_agriculture.grass_ha(:, y)  = PV.farm_ha - elm_ha;
            case {'destocking_sng_access', 'destocking_wood_access', 'destocking_sng_noaccess', 'destocking_wood_noaccess'}
                % for cells taking option, grass_ha stays at zero but arable_ha set to farm_ha - elm_ha
                es_agriculture.arable_ha(:, y) = PV.farm_ha - elm_ha;
%                 es_agriculture.grass_ha(which_cells,y) = 0;
            case {'ar_sng_d_sng', 'ar_sng_d_w', 'ar_w_d_sng', 'ar_w_sn_w','ar_sng_d_sng_na', 'ar_sng_d_w_na', 'ar_w_d_sng_na', 'ar_w_sn_w_na'}
                % Combination options will be in here - everything remains
                % at zero
            otherwise
                error('ELM option not found!')
        end
        
        % Run arable model - crop hectares, food, profit
        arable_info = fcn_calc_arable(es_agriculture.arable_ha(:,y), AgricultureProduction.Data_cells, climate_current_year, AgricultureProduction.Coefficients.Arable, MP.irrigation);
        es_agriculture.wheat_ha(:,y)      = arable_info.wheat_ha;
        es_agriculture.osr_ha(:,y)        = arable_info.osr_ha;
        es_agriculture.wbar_ha(:,y)       = arable_info.wbar_ha;
        es_agriculture.sbar_ha(:,y)       = arable_info.sbar_ha;
        es_agriculture.bar_ha(:,y)        = arable_info.bar_ha;
        es_agriculture.pot_ha(:,y)        = arable_info.pot_ha;
        es_agriculture.sb_ha(:,y)         = arable_info.sb_ha;
        es_agriculture.root_ha(:,y)       = arable_info.root_ha;
        es_agriculture.other_ha(:,y)      = arable_info.other_ha;
        es_agriculture.wheat_food(:,y)    = arable_info.wheat_food;
        es_agriculture.osr_food(:,y)      = arable_info.osr_food;
        es_agriculture.wbar_food(:,y)     = arable_info.wbar_food;
        es_agriculture.sbar_food(:,y)     = arable_info.sbar_food;
        es_agriculture.pot_food(:,y)      = arable_info.pot_food;
        es_agriculture.sb_food(:,y)       = arable_info.sb_food;
        es_agriculture.food(:,y)          = arable_info.food;
        es_agriculture.arable_profit(:,y) = arable_info.arable_profit;
        
        % Run grassland model - grassland hectares
        grass_info = fcn_calc_grass(es_agriculture.grass_ha(:,y), AgricultureProduction.Data_cells, climate_current_year, AgricultureProduction.Coefficients.Grass);
        es_agriculture.pgrass_ha(:,y) = grass_info.pgrass_ha;
        es_agriculture.tgrass_ha(:,y) = grass_info.tgrass_ha;
        es_agriculture.rgraz_ha(:,y)  = grass_info.rgraz_ha;
        
        % Run livestock model - heads of livestock, profit
        livestock_info = fcn_calc_livestock(es_agriculture.grass_ha(:,y), AgricultureProduction.Data_cells, climate_current_year, AgricultureProduction.Coefficients.Livestock);
        es_agriculture.dairy(:,y) = livestock_info.dairy;
        es_agriculture.beef(:,y) = livestock_info.beef;
        es_agriculture.sheep(:,y) = livestock_info.sheep;
        es_agriculture.livestock(:,y) = livestock_info.livestock;
        es_agriculture.livestock_profit(:,y) = livestock_info.livestock_profit;
        
        % Total farm profit =  arable profit + livestock profit
        es_agriculture.farm_profit(:,y) = es_agriculture.arable_profit(:,y) + es_agriculture.livestock_profit(:,y);

    end
    
    % Calculate farm profit annuity
    
    % Total farm profit annuity
    es_agriculture.farm_profit_ann = (es_agriculture.farm_profit * delta_data_yrs) * gamma_data_yrs;

    % Arable profit annuity
    es_agriculture.arable_profit_ann = (es_agriculture.arable_profit * delta_data_yrs) * gamma_data_yrs;
    
    % Livestock profit annuity
    es_agriculture.livestock_profit_ann = (es_agriculture.livestock_profit * delta_data_yrs) * gamma_data_yrs;
    
    % c. Calculate agricultural emissions
    % -----------------------------------
    % Multiply hectares of crops/grassland & heads of livestock by
    % pre-calculated per hectare & per head emissions from Cool Farm Tool
    % Divide by 1000 to get quantities in tons
    
    if MP.run_ghg
        
        % i. Emissions quantities
        % NB. multiply by -1 as carbon emissions is negative in NEVO
        
        % Multiply hectares of crop types by per hectare emissions 
        es_agriculture.ghg_wheat = - (es_agriculture.wheat_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.cer, [1 MP.num_years]) ./ 1000);
        es_agriculture.ghg_osr = - (es_agriculture.osr_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.osrape, [1 MP.num_years]) ./ 1000);
        es_agriculture.ghg_wbar = - (es_agriculture.wbar_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.cer, [1 MP.num_years]) ./ 1000);
        es_agriculture.ghg_sbar = - (es_agriculture.sbar_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.cer, [1 MP.num_years]) ./ 1000);
        es_agriculture.ghg_pot = - (es_agriculture.pot_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.root, [1 MP.num_years]) ./ 1000);
        es_agriculture.ghg_sb = - (es_agriculture.sb_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.root, [1 MP.num_years]) ./ 1000);
        es_agriculture.ghg_other = - (es_agriculture.other_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.other, [1 MP.num_years]) ./ 1000);
        
        % Total emissions from arable
        es_agriculture.ghg_arable = es_agriculture.ghg_wheat + es_agriculture.ghg_osr + es_agriculture.ghg_wbar + es_agriculture.ghg_sbar + es_agriculture.ghg_pot + es_agriculture.ghg_sb + es_agriculture.ghg_other;
                
        % Multiply hectares of grassland types by per hectare emissions
        es_agriculture.ghg_pgrass = - (es_agriculture.pgrass_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.pgrass, [1 MP.num_years]) ./ 1000);
        es_agriculture.ghg_tgrass = - (es_agriculture.tgrass_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.tgrass, [1 MP.num_years]) ./ 1000);
        es_agriculture.ghg_rgraz = - (es_agriculture.rgraz_ha .* repmat(AgricultureGHG.EmissionsGridPerHa.rgraz, [1 MP.num_years]) ./ 1000);
        
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
        % Turn agricultural greenhouse gas emissions into annuities via multiplying
        % by carbon price.

        % Set up discounted carbon prices
        carbon_disc_price = carbon_price(1:MP.num_years) .* delta_data_yrs;

        % Total agricultural emissions annuity
        es_agriculture.ghg_farm_ann = (es_agriculture.ghg_farm * carbon_disc_price) * gamma_data_yrs;
        
        % Emissions from arable annuity
        es_agriculture.ghg_arable_ann = (es_agriculture.ghg_arable * carbon_disc_price) * gamma_data_yrs;

        % Emissions from grass annuity
        es_agriculture.ghg_grass_ann = (es_agriculture.ghg_grass * carbon_disc_price) * gamma_data_yrs;

        % Emissions from livestock
        es_agriculture.ghg_livestock_ann = (es_agriculture.ghg_livestock * carbon_disc_price) * gamma_data_yrs;
        
    end
    
end