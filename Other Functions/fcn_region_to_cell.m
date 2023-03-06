function cell_info = fcn_region_to_cell(conn, feature_type, id)

    cell_info.nids = size(id,1);
    if (feature_type == "integrated_2km")
        if cell_info.nids > 1
            cell_info.id_string = regexprep(regexprep(regexprep(jsonencode(id),'[','('),']',')'),'"','''');
        else
            cell_info.id_string = ['(' regexprep(jsonencode(id),'"','''') ')'];
        end
        cell_info.new2kid = id;
        cell_info.proportion = ones(size(id));
    else
        if feature_type ~= "integrated_basins"
            cell_info.id_string = regexprep(regexprep(regexprep(jsonencode(id),'[','('),']',')'),'"','''');
            if feature_type == "integrated_subbasins"
                sqlquery    = ['SELECT * FROM regions_keys.key_grid_subbasins WHERE id IN ',cell_info.id_string];
                setdbprefs('DataReturnFormat','structure');
                dataReturn  = fetch(exec(conn,sqlquery));
            elseif feature_type == "integrated_national_parks"
                sqlquery    = ['SELECT * FROM regions_keys.key_grid_national_parks WHERE id IN ',cell_info.id_string];
                setdbprefs('DataReturnFormat','structure');
                dataReturn  = fetch(exec(conn,sqlquery));
            elseif feature_type == "integrated_lad"
                sqlquery    = ['SELECT * FROM regions_keys.key_grid_lad WHERE id IN ',cell_info.id_string];
                setdbprefs('DataReturnFormat','structure');
                dataReturn  = fetch(exec(conn,sqlquery));
            elseif feature_type == "integrated_counties_uas"
                sqlquery    = ['SELECT * FROM regions_keys.key_grid_counties_uas WHERE id IN ',cell_info.id_string];
                setdbprefs('DataReturnFormat','structure');
                dataReturn  = fetch(exec(conn,sqlquery));
            elseif feature_type == "integrated_regions"
                sqlquery    = ['SELECT * FROM regions_keys.key_grid_regions WHERE id IN ',cell_info.id_string];
                setdbprefs('DataReturnFormat','structure');
                dataReturn  = fetch(exec(conn,sqlquery));
            elseif feature_type == "integrated_countries"
                sqlquery    = ['SELECT * FROM regions_keys.key_grid_countries WHERE id IN ',cell_info.id_string];
                setdbprefs('DataReturnFormat','structure');
                dataReturn  = fetch(exec(conn,sqlquery));
            end
        else
            if cell_info.nids > 1
                cell_info.id_string = regexprep(regexprep(regexprep(jsonencode(id),'[','('),']',')'),'"','''');
            else
                cell_info.id_string = ['(' regexprep(jsonencode(id),'"','''') ')'];
            end
            sqlquery    = ['SELECT * FROM regions_keys.key_grid_basins WHERE id IN ',cell_info.id_string];
            setdbprefs('DataReturnFormat','structure');
            dataReturn  = fetch(exec(conn,sqlquery));
        end
        cell_info.id_long = dataReturn.Data.id;
        cell_info.new2kid = dataReturn.Data.new2kid;
        cell_info.proportion = dataReturn.Data.proportion;
    end

    cell_info.ncells2 = size(cell_info.new2kid,1);
    if cell_info.ncells2 > 1
        cell_info.new2kid_string = regexprep(regexprep(jsonencode(cell_info.new2kid),'[','('),']',')');
    else
        cell_info.new2kid_string = ['(' jsonencode(cell_info.new2kid) ')'];
    end
    cell_info.ncells = size(unique(cell_info.new2kid),1);
    
    cell_info.baseline_lcs = fcn_import_baseline_lcs(conn, cell_info);

end

