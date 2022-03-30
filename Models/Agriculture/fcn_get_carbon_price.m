function [carbon_price] = fcn_get_carbon_price(conn, carbon_price_level)
% FCN_GET_CARBON_PRICE
% Quickly retrieve carbon price from SQL database
% Author: Frankie Cho

sqlquery = ['SELECT year, ', carbon_price_level ,' FROM greenbook.c02_val_2018_ext'];
setdbprefs('DataReturnFormat', 'table');
dataReturn  = fetch(exec(conn, sqlquery));
carbon_table = dataReturn.Data;

% Extract carbon price from 2020 for 300 years
idx_2020 = find(carbon_table.year == 2020);
carbon_price_table = carbon_table.(carbon_price_level);
carbon_price = carbon_price_table(idx_2020:(idx_2020 + 300 - 1));
end