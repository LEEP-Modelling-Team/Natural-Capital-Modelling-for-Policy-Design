function MP = SetModelParameters(json, server_flag, parameters)

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
        paths = fcn_set_data_paths();
        f = fieldnames(paths);
        for i = 1:length(f)
            MP.(f{i}) = paths.(f{i});
        end
    end
    
    %% Add parameters passed to the function to MP 
    f = fieldnames(parameters);
    for i = 1:length(f)
        MP.(f{i}) = parameters.(f{i});
    end
    
           
    %% Fix issue with id's of length 1
    if MP.feature_type ~= "integrated_2km" && MP.feature_type ~= "integrated_basins" && size(MP.id,1) == 1
       MP.id = {MP.id};
    end

    %% Prices

    % Agriculture
    % Done as part of fcn_run_agriculture

    % Forestry
    % Price change is defined as difference from £30 (Oak) and £22 (Sitka Spruce)
    % Need to work out percentage change multiplication factor to multiply time series of actual timber prices
    % Timber price actually changed in fcn_run_forestry
    MP.price_broad_factor = (30 + MP.price_broad)/30;
    MP.price_conif_factor = (22 + MP.price_conif)/22;

    %% Irrigation
    % Done as part of fcn_run_agriculture, in top level and arable models
    
end
