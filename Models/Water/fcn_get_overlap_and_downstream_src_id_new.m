function src_id = fcn_get_overlap_and_downstream_src_id_new(new2kid, key_grid_subbasins, firstdownstream)

    % Get (unique) overlapping subbasins
    new2kid_src_id_ind = ismember(key_grid_subbasins.new2kid, new2kid);
    src_id_overlap = unique(key_grid_subbasins.src_id(new2kid_src_id_ind));
    
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
                
                firstdownstream_temp = firstdownstream.firstdownstream(strcmp(firstdownstream.src_id, src_id{count-1}));

                if strcmp(firstdownstream_temp, 'end') || any(strcmp(src_id, firstdownstream_temp))
                    % If firstdownstream = 'end' or is already in list, break
                    break
                else
                    % Else, add firstdownstream subbasin to list and increment
                    % counter
                    src_id(count) = firstdownstream_temp;
                    count = count + 1;
                end

            end
        
        end

    end

    % Take unique subbasins (also sorts) and return transpose for
    % convenience
    src_id = unique(src_id');

end