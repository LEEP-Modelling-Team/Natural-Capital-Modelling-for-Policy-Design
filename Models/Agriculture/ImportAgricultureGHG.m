function AgricultureGHG = ImportAgricultureGHG(conn)

    %% IMPORTAGRICULTUREGHG
    %  ====================

    % Imports soil and temperature data and runs the  Cool Farm Tool code 
    % written by Sylvia Vetter (University of Aberdeen) and AJ De-Gol 
    % (University of East Anglia).
    %
    % The input required is the connection to the database conn.
    %
    % The output is the AgricultureGHG structure, which contains fields:
    %
    % EmissionsGridPerHa [ncells x 7 table]: 
    % - Per hectare emissions from grid cells (machinery, land use and soils).
    % Divided into 7 agricultural land uses: oil seed rape, cereals, root 
    % crops, temporary grass, permanent grass, rough grazing and other.
    %
    % EmissionsLivestockPerHead [ncells x 3 x 40 array]:
    % - Per head emissions from livestock in grid cells over a 40 year
    % simulation period (2020-2059). Divided into 3 livestock types: dairy,
    % beef and sheep.
    %
    % These will be multiple by hectares of crops and grassland, and heads of
    % livestock, in the main function for the agriculture model.

    %% (1) LOAD DATA FROM DATABASE
    %  ===========================

    % a. Cell-specific soil data
    % --------------------------
    % Soil Organic Matter (SOM) class, % of coarse/medium/fine, % of 5 soil PH
    % categories
    sqlquery = ['SELECT new2kid, som_class, pca_coarse, pca_med, pca_fine, ' ...
        'pca_ph1, pca_ph2, pca_ph3, pca_ph4, pca_ph5 ' ...
        'FROM nevo.nevo_variables ORDER BY new2kid'];
    setdbprefs('DataReturnFormat','table');
    dataReturn  = fetch(exec(conn,sqlquery));
    soil_cells = dataReturn.Data;

    % Save 2km cell id's into AgricultureGHG structure and define number of
    % cells
    AgricultureGHG.new2kid = soil_cells.new2kid;
    ncells = length(AgricultureGHG.new2kid);

    % b. Cool Farm Tool livestock temperature factor
    % ----------------------------------------------
    sqlquery = 'SELECT * FROM nevo.ag_cft_tempfactor';
    setdbprefs('DataReturnFormat','numeric');
    dataReturn  = fetch(exec(conn,sqlquery));
    ls_temp_factor = dataReturn.Data;

    % c. Temperature in growing season (for livestock emissions)
    % ----------------------------------------------------------
    %%% !!! - should we use restricted climate here or not?
    % sqlquery = ['SELECT temp2020, temp2021, temp2022, temp2023, temp2024, temp2025, temp2026, temp2027, temp2028, temp2029, ' ...
    %     'temp2030, temp2031, temp2032, temp2033, temp2034, temp2035, temp2036, temp2037, temp2038, temp2039, ' ...
    %     'temp2040, temp2041, temp2042, temp2043, temp2044, temp2045, temp2046, temp2047, temp2048, temp2049, ' ...
    %     'temp2050, temp2051, temp2052, temp2053, temp2054, temp2055, temp2056, temp2057, temp2058, temp2059 ' ...
    %     'FROM nevo.nevo_fclimate_grow_avg ORDER BY new2kid'];
    sqlquery = ['SELECT temp2020, temp2021, temp2022, temp2023, temp2024, temp2025, temp2026, temp2027, temp2028, temp2029, ' ...
        'temp2030, temp2031, temp2032, temp2033, temp2034, temp2035, temp2036, temp2037, temp2038, temp2039, ' ...
        'temp2040, temp2041, temp2042, temp2043, temp2044, temp2045, temp2046, temp2047, temp2048, temp2049, ' ...
        'temp2050, temp2051, temp2052, temp2053, temp2054, temp2055, temp2056, temp2057, temp2058, temp2059 ' ...
        'FROM nevo.nevo_fclimate_grow_avg_restrict ORDER BY new2kid'];
    setdbprefs('DataReturnFormat','table');
    dataReturn  = fetch(exec(conn,sqlquery));
    climate = dataReturn.Data;

    %% (2) CALCULATE SOIL PROPERTY VARIABLES
    % From the variables imported in step (1), additional variables need to be
    % derived for the Cool Farm Tool

    % a. Soil Texture
    % ---------------
    % A categorial variable defined as 1, 2 or 3 depending on whether the soil
    % is predominately coarse, medium or fine quality.
    [~,soil_cells.soil_texture] = max([soil_cells.pca_coarse soil_cells.pca_med soil_cells.pca_fine],[],2);

    % b. Soil Drainage
    % ----------------
    % A categorical variable defined as 2 for all cells, except for those cells
    % where Soil Texture = 3, where it is defined as 1.
    soil_cells.soil_drainage = 2*ones(ncells,1);
    soil_cells.soil_drainage(soil_cells.soil_texture == 3) = 1;

    % c. Soil PH
    % ----------
    % A categorical variable defined as 1 if the soil is predominately ph1
    % or ph2, and 2, 3 or 4 is the soil is predominately ph3, ph4 or ph5
    % respectively.
    [~,ph_category] = max([soil_cells.pca_ph1,soil_cells.pca_ph2,soil_cells.pca_ph3,soil_cells.pca_ph4,soil_cells.pca_ph5],[],2);
    soil_cells.soil_ph = zeros(ncells,1);
    soil_cells.soil_ph(ph_category < 3) = 1;
    soil_cells.soil_ph(ph_category > 2) = ph_category(ph_category > 2) - 1;
    
    
    % d. Soil Moisture
    % ----------------
    % A categorical variable defined as 1 for all cells (UK soils always moist)
    soil_cells.soil_moisture = ones(ncells,1);

    %% (3) CALCULATE TOTAL GRID EMISSIONS PER HECTARE
    % This is made up of emissions from machinery, land use type, and grid (soils?)

    % Define order of land use types
    order_landuse = {'osrape' 'cer' 'root' 'tgrass' 'pgrass' 'rgraz'}; 

    %%% !!! - change the names of these functions? Also required functions:
    %%% !!! Get_Fert_Params, Get_Land_ParamsR4, CFTReorderLandType, Get_Residue_Params, Get_Land_Params, Get_Soil_Params
    % Land-type-specific machinery emissions (constant):
    emissions_machinery = CalcCFTMachEm(order_landuse); 

    % Land-type-specific emissions (constant):
    emissions_landuse = CalcCFTLandTypeEm(order_landuse);

    %%% !!! - is this specifically emissions from soils? Define as emissions_soils if so
    %%% !!! - change the way second argument is passed into function?
    % Cell-specific emissions:
    emissions_grid = CalcCFTGridEm(order_landuse,[soil_cells.soil_texture,soil_cells.som_class,soil_cells.soil_ph,soil_cells.soil_drainage,soil_cells.soil_moisture]); 

    % Total grid emissions = machinery + land use + grid (soils?)
    % Note: need to repeat machinery and landuse emissions for ncells
    emissions_total_grid = repmat(emissions_machinery + emissions_landuse,[ncells 1]) + emissions_grid;

    % Convert total grid emissions to table with column names for land uses
    emissions_total_grid = array2table(emissions_total_grid,'VariableNames',order_landuse);

    % Create 'other' land use category
    %%% !!! - why do these coefficients not sum to 1?
    coef_other = [0.05,0.15,0.25,0.05,0.05,0.05];
    emissions_total_grid.other = table2array(emissions_total_grid)*coef_other';

    % Save total grid emissions into AgricultureGHG structure
    AgricultureGHG.EmissionsGridPerHa = emissions_total_grid;

    %% (4) CALCULATE TOTAL LIVESTOCK EMISSIONS PER HEAD
    % Livestock emissions per head are assumed to change over time with
    % temperature increase

    % Define order of livestock types
    order_livestock = {'DAIRY' 'BEEF' 'SHEEP'};

    % Define the sequence of years in the simulation (2020-2059)
    year_start = 2020;
    year_end = 2059;
    year_seq = year_start:year_end;
    num_years = length(year_seq);

    % Emissions from 3 livestock types (dairy, beef, sheep) to be stored in an
    % array of size ncells x 3 x num_years
    emissions_livestock = zeros(ncells,3,num_years);

    % Loop over the years in the simulation
    % Predict emissions per head from livestock as a function of temperature in
    % that year
    for n = 1:num_years
        % Extract temperature in current year from climate table
        current_year_temp = eval(['climate.temp' num2str(year_seq(n))]);
        % Predict emissions per head of 3 livestock types in current year
        %%% !!! - change the names of this function?
        emissions_livestock(:,:,n) = CalcCFTLSEm(current_year_temp, order_livestock, ls_temp_factor);
    end

    % Save livestock emissions into AgricultureGHG structure
    % Change order of 2nd and 3rd dimensions for ease of use in fcn_agriculture
    emissions_livestock = permute(emissions_livestock, [1 3 2]);
    AgricultureGHG.EmissionsLivestockPerHead.dairy = emissions_livestock(:,:,1);
    AgricultureGHG.EmissionsLivestockPerHead.beef = emissions_livestock(:,:,2);
    AgricultureGHG.EmissionsLivestockPerHead.sheep = emissions_livestock(:,:,3);
    

end

