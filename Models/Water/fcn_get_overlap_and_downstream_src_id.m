function src_id = fcn_get_overlap_and_downstream_src_id(conn, new2kid)

    % Set up string for Postgresql
    if length(new2kid) > 1
        new2kid_string = regexprep(regexprep(jsonencode(new2kid),'[','('),']',')');
    else
        new2kid_string = ['(' jsonencode(new2kid) ')'];
    end
%     new2kid_string = regexprep(regexprep(regexprep(jsonencode(new2kid),'[','('),']',')'),'"','''');

    % Get (unique) overlapping subbasins
    sqlquery = ['SELECT DISTINCT src_id ' ...
        'FROM regions_keys.key_grid_subbasins ' ...
        'WHERE new2kid IN ', new2kid_string, ...
        ' ORDER BY src_id'];
    setdbprefs('DataReturnFormat', 'cellarray');
    dataReturn  = fetch(exec(conn, sqlquery));
    src_id_overlap = dataReturn.Data;
    
    % Remove subbasins from basins 21009, 21016, 21022, 77001, 77004
    if size(src_id_overlap,1) == 1
        bsn_ids = str2double(split(src_id_overlap,'_'))';
    else
        bsn_ids = str2double(split(src_id_overlap,'_'));
    end
    bsn_ids = bsn_ids(:,1);
    src_id_overlap = src_id_overlap(~ismember(bsn_ids, [21009, 21016, 21022, 77001, 77004]));
    

    % Add downstream subbasins to this list
    % Will be some duplicates, may be a better way
    src_id = {};
    count = 1;

    for i = 1:size(src_id_overlap, 1)
        
        % If src_id_overlap subbasin not already in list...
        if ~any(strcmp(src_id,src_id_overlap(i)))
            
            % Add overlapping subbasin to list and increment counter
            src_id(count) = src_id_overlap(i);
            count = count + 1;
        
            % Do loop for downstream subbasins
            while true

                % Get firstdownstream subbasin from database
                sqlquery = ['SELECT firstdownstream FROM nevo_explore.explore_subbasins WHERE src_id = ''' src_id{count-1} ''''];
                setdbprefs('DataReturnFormat', 'cellarray');
                dataReturn  = fetch(exec(conn, sqlquery));
                firstdownstream = dataReturn.Data;

                if strcmp(firstdownstream, 'end') || any(strcmp(src_id, firstdownstream))
                    % If firstdownstream = 'end' or is already in list, break
                    break
                else
                    % Else, add firstdownstream subbasin to list and increment
                    % counter
                    src_id(count) = firstdownstream;
                    count = count + 1;
                end

            end
        
        end

    end

    % Take unique subbasins (also sorts) and return transpose for
    % convenience
    src_id = unique(src_id');

end