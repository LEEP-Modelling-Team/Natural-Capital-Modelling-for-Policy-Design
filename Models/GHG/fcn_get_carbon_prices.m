function carbon_prices = fcn_get_carbon_prices(conn, MP)

    %% Carbon Prices

    % Data
    sqlquery    = 'SELECT * FROM nevo.ghg_carbon_prices';
    setdbprefs('DataReturnFormat','numeric');
    dataReturn  = fetch(exec(conn,sqlquery));
    GHG.CarbonPrices = dataReturn.Data;

    % Extract just the carbon prices we need: 300 years from and including
    % MP.startyear
    GHG.startindex = find(GHG.CarbonPrices(:,1) == MP.start_year);
    GHG.CarbonPrices = GHG.CarbonPrices(GHG.startindex:(GHG.startindex+300-1),:);
    
    % Select carbon price scenario based on user input
    % NB: Need + 1 since year is first column in GHG.CarbonPrices
    carbon_prices = GHG.CarbonPrices(:,MP.price_carbon + 1);
    
end
