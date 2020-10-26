function [ area ] = length_to_area(length, linear_decay)
    % Length in metres to area in hectares
    if (length > 0)
        if (linear_decay == 0)
            steps = length/25; % Number of 25m steps from start to end
        else
            % Decay area linearly from 0 to linear_decay
            steps = sum((linear_decay:-25:(linear_decay-length))/linear_decay);
        end
        % Assume 1.5 grid cells width and multiply by area of grid cell in ha
        area = steps * 1.5 * 0.0625; 
    else
        area = 0;
    end
end

