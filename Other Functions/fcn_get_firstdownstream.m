function firstdownstream = fcn_get_firstdownstream(conn)

    sqlquery = 'SELECT src_id, firstdownstream FROM nevo_explore.explore_subbasins ORDER by src_id';
    setdbprefs('DataReturnFormat', 'table');
    dataReturn  = fetch(exec(conn, sqlquery));
    firstdownstream = dataReturn.Data;
    
end