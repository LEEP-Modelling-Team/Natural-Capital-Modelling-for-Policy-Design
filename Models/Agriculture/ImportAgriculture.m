clear

database_calls_flag = false;
test_function_flag = true;

% Connect to the database
server_flag = false;
conn = fcn_connect_database(server_flag);

% Set paths for storing imported data
agriculture_data_folder = 'C:\Data\Agriculture\';
agricultureghg_data_folder = 'C:\Data\GHG\';

%% Import variables from database and save as .mat files
if database_calls_flag

    % Set file names for storing imported data
    NEVO_AgricultureProduction_data_mat = strcat(agriculture_data_folder, 'NEVO_AgricultureProduction_data.mat');
    NEVO_AgricultureGHG_data_mat = strcat(agricultureghg_data_folder, 'NEVO_AgricultureGHG_data.mat');

    % Import agriculture production and agriculture GHG data
    tic
        AgricultureProduction = ImportAgricultureProduction(conn);
        AgricultureGHG = ImportAgricultureGHG(conn);
    toc
    
    % Save data to .mat files
    save(NEVO_AgricultureProduction_data_mat, 'AgricultureProduction', '-mat', '-v6')
    save(NEVO_AgricultureGHG_data_mat, 'AgricultureGHG', '-mat', '-v6')
    
end

%% Test fcn_run_agriculture function
if test_function_flag
    
    % Set up MP strucure
    MP.num_years = 40;
    MP.start_year = 2020;
    MP.run_ghg = true;
    MP.price_wheat = 0;
    MP.price_osr = 0;
    MP.price_wbar = 0;
    MP.price_sbar = 0;
    MP.price_pot = 0;
    MP.price_sb = 0;
    MP.price_other = 0;
    MP.price_dairy = 0;
    MP.price_beef = 0;
    MP.price_sheep = 0;
    MP.price_fert = 0;
    MP.price_quota = 0;
    MP.irrigation = true;
    MP.discount_rate = 0.035;

    % Set up PV structure
    sqlquery = 'SELECT new2kid, farm_ha FROM nevo.nevo_variables ORDER BY new2kid';
    setdbprefs('DataReturnFormat','structure');
    dataReturn  = fetch(exec(conn,sqlquery));
    PV = dataReturn.Data;
    
    % Set up carbon price
    sqlquery    = 'SELECT * FROM nevo.ghg_carbon_prices';
    setdbprefs('DataReturnFormat','numeric');
    dataReturn  = fetch(exec(conn,sqlquery));
    GHG.CarbonPrices = dataReturn.Data;
    GHG.startindex = find(GHG.CarbonPrices(:,1) == MP.start_year);
    GHG.CarbonPrices = GHG.CarbonPrices(GHG.startindex:(GHG.startindex+300-1),:);
    carbon_price = GHG.CarbonPrices(1:40,2);

    % Run the main function
    tic
    es_agriculture = fcn_run_agriculture(agriculture_data_folder, agricultureghg_data_folder, MP, PV, carbon_price);
    toc
    
end
