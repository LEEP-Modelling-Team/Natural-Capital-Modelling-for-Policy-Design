function [quantity_totn, quantity_totp] = fcn_calc_quantity_water_quality(start_year, end_year, num_extra_years, water_quality_table)
   
    % Total nitrogen concentration
    totn_change_ts = [repmat(water_quality_table.chgtotn_20, 1, 10) ...
                      repmat(water_quality_table.chgtotn_30, 1, 10) ...
                      repmat(water_quality_table.chgtotn_40, 1, 10) ...
                      repmat(water_quality_table.chgtotn_50, 1, 10)];
    
    totn_change_ts = [totn_change_ts, repmat(totn_change_ts(:, 40), 1, num_extra_years)];

    quantity_totn = sum(totn_change_ts(:, start_year:end_year), 2);
    
    % Total phosphorus concentration
    totp_change_ts = [repmat(water_quality_table.chgtotp_20, 1, 10) ...
                      repmat(water_quality_table.chgtotp_30, 1, 10) ...
                      repmat(water_quality_table.chgtotp_40, 1, 10) ...
                      repmat(water_quality_table.chgtotp_50, 1, 10)];
    
    totp_change_ts = [totp_change_ts, repmat(totp_change_ts(:, 40), 1, num_extra_years)];

    quantity_totp = sum(totp_change_ts(:, start_year:end_year), 2);

end
