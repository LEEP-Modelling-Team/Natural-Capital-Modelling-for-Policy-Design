function key_grid_subbasins = fcn_get_key_grid_subbasins(conn)

    sqlquery = 'SELECT new2kid, src_id FROM regions_keys.key_grid_subbasins ORDER by new2kid, src_id';
    setdbprefs('DataReturnFormat', 'table');
    dataReturn  = fetch(exec(conn, sqlquery));
    key_grid_subbasins = dataReturn.Data;
    
end