function quantity_flood = fcn_calc_quantity_flood(start_year, end_year, num_extra_years, flooding_transfer_table)

    % Change in peak flow
    q5_change_ts = [repmat(flooding_transfer_table.chgq5_20, 1, 10) ...
                    repmat(flooding_transfer_table.chgq5_30, 1, 10) ...
                    repmat(flooding_transfer_table.chgq5_40, 1, 10) ...
                    repmat(flooding_transfer_table.chgq5_50, 1, 10)];
    
    q5_change_ts = [q5_change_ts, repmat(q5_change_ts(:, 40), 1, num_extra_years)];

    quantity_flood = sum(q5_change_ts(:, start_year:end_year), 2);
    
end
