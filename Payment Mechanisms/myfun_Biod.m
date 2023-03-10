function f = myfun_Biod(p, q, costs, benefits, elm_option, cnst_data, cnst_target)

    % Calculate uptake
    uptake = myfun_uptake(p, q, costs, elm_option);
        
    % Calculate biodiversity delivery by species group
    num_spgrp = length(cnst_target);
    spgrp_chg = zeros(num_spgrp,1);
    for k = 1:num_spgrp
        spgrp_chg(k) = sum(uptake.*squeeze(cnst_data(k,:,:))', 'all');        
    end

    % objective function
    alpha = 20;
    f = sum((cnst_target - spgrp_chg).^2) + ...
        alpha * sum(max([(cnst_target - spgrp_chg), zeros(num_spgrp,1)], [], 2).^2);
    
end