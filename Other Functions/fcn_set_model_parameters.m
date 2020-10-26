function MP = SetModelParameters(json, server_flag)

    %% SET MODEL PARAMETERS (MP)
    % THESE WILL BE PASSED AS ARGUMENTS TO THE INTEGRATED FUNCTIONS, NOT SET
    % HERE

    %% DECODE THE JSON OBJECT/STRING INTO A MATLAB STRUCTURE
    MP = jsondecode(json);

    %% Round output
    MP.rounding = true;
    
    %% Set path to model data folders
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
        MP.agriculture_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Agriculture\';
        MP.agricultureghg_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\GHG\';
        MP.forest_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Forestry\';
        MP.forestghg_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\GHG\';
        MP.rec_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Recreation\';
        MP.biodiversity_jncc_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Biodiversity\JNCC\';
        MP.biodiversity_ucl_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Biodiversity\UCL\';
        MP.pollination_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Pollination\';
        MP.non_use_pollination_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\NonUsePollination\';
        MP.non_use_habitat_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\NonUseHabitat\';
        MP.water_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\Water\';
        MP.water_non_use_data_folder = 'C:\Users\neo204\OneDrive - University of Exeter\NEV\Model Data\NonUse\';
        
    end
           
    %% Fix issue with id's of length 1
    if MP.feature_type ~= "integrated_2km" && MP.feature_type ~= "integrated_basins" && size(MP.id,1) == 1
       MP.id = {MP.id};
    end
    
    %% Number of years in simulation and start year (fixed)
    MP.num_years = 40; % Temporal run year length. Fixing this in the tool rather than allowing users to vary
    MP.start_year = 2020; % Temporal start year.

    %% Prices

    % Agriculture
    % Done as part of fcn_run_agriculture

    % Forestry
    % Price change is defined as difference from £30 (Oak) and £22 (Sitka Spruce)
    % Need to work out percentage change multiplication factor to multiply time series of actual timber prices
    % Timber price actually changed in fcn_run_forestry
    MP.price_broad_factor = (30 + MP.price_broad)/30;
    MP.price_conif_factor = (22 + MP.price_conif)/22;

    % Carbon
    % Done as part of fcn_get_carbon_prices

    %% Discount rate
    % Price change is defined as absolute difference from original / 100 (proportion)
    MP.discount_rate = 0.035 + MP.discount_rate;

    %% Irrigation
    % Done as part of fcn_run_agriculture, in top level and arable models
    
end
