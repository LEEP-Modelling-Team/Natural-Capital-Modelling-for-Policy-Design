function carbon_price = fcn_get_carbon_price(conn, ...
                                             price_string, ...
                                             start_year)
    % fcn_get_carbon_price.m
    % ======================
    % Author: Nathan Owen
    % Last modified: 27/05/2020
    % Function to retrieve a vector of carbon prices from a starting year
    % for the next 300 years. Used as an input in the NEV agriculture and
    % forestry models.
    % Inputs:
    % - conn: a connection object to a PostgreSQL database. Obtain by
    %   running the function fcn_connect_database.m. For this function to
    %   work, the database must include the tables nevo.ghg_carbon_prices
    %   and greenbook.c02_val_2018_ext.
    % - price_string: a string specifying which carbon price should be
    %   retrieved from the database. Options are:
    %       - 'scc': social cost of carbon (no longer recommended)
    %       - 'nontraded_low': BEIS non-traded low estimate
    %       - 'nontraded_central': BEIS non-traded central estimate
    %       - 'nontraded_high': BEIS non-traded high estimate
    % - start_year: an integer between 2010 and 2100 specifying the year of
    %   the first required value. If not inputted, by default this is set 
    %   to 2020, the default for NEV models. Carbon values for the 300 
    %   years from this year are returned.
    % Outputs:
    % - carbon_price: a vector of carbon prices from start_year for 300
    %   years.
    
    % Set start_year to 2020 by default if not inputted
    if nargin < 3
        start_year = int16(2020);
    end
                                         
    % Check start year is integer between 2010 and 2100
    if (~isinteger(start_year)) || (start_year < 2010) || (start_year > 2100)
        error('''start_year'' should be integer between 2010 and 2100.')
    end
                                         
    % Set up SQL query to retrieve carbon prices based on price_string
    % Also check that price_string is one of the available options
    switch price_string
        case 'scc'
            % Social cost of carbon
            sqlquery = ['SELECT ', ...
                            'year, ', ...
                            'scc_tol AS carbon_price ', ...
                        'FROM nevo.ghg_carbon_prices'];
        case 'nontraded_low'
            % BEIS non-traded low estimate 
            sqlquery = ['SELECT ', ...
                            'year, ', ...
                            'non_trade_low AS carbon_price ', ...
                        'FROM greenbook.c02_val_2018_ext'];
        case 'nontraded_central'
            % BEIS non-traded central estimate 
            sqlquery = ['SELECT ', ...
                            'year, ', ...
                            'non_trade_central AS carbon_price ', ...
                        'FROM greenbook.c02_val_2018_ext'];
        case 'nontraded_high'
            % BEIS non-traded high estimate 
            sqlquery = ['SELECT ', ...
                            'year, ', ...
                            'non_trade_high AS carbon_price ', ...
                        'FROM greenbook.c02_val_2018_ext'];
        otherwise
            % Print error with list of available price_string
            error(['''price_string'' must be one of ''scc'', ', ...
                   '''nontraded_low'', ''nontraded_central'', ', ...
                   'or ''nontraded_high''.'])
    end
    
    % Use SQL query to retrieve year & carbon price from database as table
    setdbprefs('DataReturnFormat', 'table');
    dataReturn  = fetch(exec(conn, sqlquery));
    carbon_table = dataReturn.Data;
    
    % Extract carbon price from start_year for the next 300 years
    % 300 years of data needed for NEV forestry model
    % carbon_price is returned from the function
    idx_start_year = find(carbon_table.year == start_year);
    carbon_price = carbon_table.carbon_price(idx_start_year:(idx_start_year + 300 - 1));
end
