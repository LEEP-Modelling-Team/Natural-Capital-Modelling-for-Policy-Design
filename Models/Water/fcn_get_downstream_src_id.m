function src_id = fcn_get_downstream_src_id(src_id_overlap, firstdownstream)

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

% Returns transpose
src_id = src_id';

end