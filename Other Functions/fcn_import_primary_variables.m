function PV = fcn_import_primary_variables(conn, cell_info)

    % Import all necessary variables for NEVO models, save in PV structure
    sqlquery = ['SELECT new2kid, x, y, wood_ha, farm_ha, sngrass_ha, ' ...
        'urban_ha, water_ha, p_decid, p_conif, p_fwood, p_maize, ' ...
        'p_othcer, p_hort, p_othcrps, p_othfrm, p_wosr, p_sosr ' ...
        'FROM nevo.nevo_variables WHERE new2kid IN ',cell_info.new2kid_string];
    setdbprefs('DataReturnFormat','structure');
    dataReturn  = fetch(exec(conn,sqlquery));
    PV = dataReturn.Data;

end