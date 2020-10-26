function sbsn_em_output = fcn_sbsn_summary_calc(SWATemdata, sbsn_em_data, decade_str, sbsn_order_idx, cnutrient_adjustment_table)

    % Calculate summary statistics of water quantity and quality
    % ----------------------------------------------------------
    q95     = quantile(sbsn_em_data.flow, 0.05);
    q50     = median(sbsn_em_data.flow);
    q5      = quantile(sbsn_em_data.flow, 0.95);
    qmean   = mean(sbsn_em_data.flow);
    v       = qmean * 60 * 60 * 24 * 365 / 1000000;
    orgn	= (mean(sbsn_em_data.orgn) * 1000000) ./ (qmean * 1000 * 86400);
    no3     = (mean(sbsn_em_data.no3) * 1000000) ./ (qmean * 1000 * 86400);
    no2     = (mean(sbsn_em_data.no2) * 1000000) ./ (qmean * 1000 * 86400);
    nh4     = (mean(sbsn_em_data.nh4) * 1000000) ./ (qmean * 1000 * 86400);
    orgp	= (mean(sbsn_em_data.orgp) * 1000000) ./ (qmean * 1000 * 86400);
    pmin	= (mean(sbsn_em_data.minp) * 1000000) ./ (qmean * 1000 * 86400);
    disox	= (mean(sbsn_em_data.disox) * 1000000) ./ (qmean * 1000 * 86400);
    
    % Create total nitrogen and phosphorus
    totn = orgn + no3 + no2 + nh4;
    totp = orgp + pmin;
    
    % Adjust water quality using calibration data
    % -------------------------------------------
    % Extract calibration data for this subbasin
    src_id = [num2str(SWATemdata.basinID), '_', num2str(sbsn_order_idx)];
    src_id_ind = strcmp(src_id, cnutrient_adjustment_table.src_id);
    cnutrient_adjustment_src_id = cnutrient_adjustment_table(src_id_ind, :);
    
    % Proportion of orgp and pmin out of total phosphorus
    prop_orgp = orgp ./ totp;
    prop_pmin = pmin ./ totp;
    prop_orgp(isnan(prop_orgp)) = 0;
    prop_pmin(isnan(prop_pmin)) = 0;
    
    % Add on calibration adjustment (with proportion for orgp and pmin)
    orgn_adj = orgn + cnutrient_adjustment_src_id.adj_orgn;
    no3_adj = no3 + cnutrient_adjustment_src_id.adj_nitrate;
    no2_adj = no2 + cnutrient_adjustment_src_id.adj_nitrite;
    nh4_adj = nh4; % no calibration for nh4
    orgp_adj = orgp + (prop_orgp * cnutrient_adjustment_src_id.adj_phosphorus);
    pmin_adj = pmin + (prop_pmin * cnutrient_adjustment_src_id.adj_phosphorus);
    disox_adj = disox + cnutrient_adjustment_src_id.adj_disox;
    
    % Censor from below zero
    orgn_adj(orgn_adj < 0) = 0;
    no3_adj(no3_adj < 0) = 0;
    no2_adj(no2_adj < 0) = 0;
    nh4_adj(nh4_adj < 0) = 0;
    orgp_adj(orgp_adj < 0) = 0;
    pmin_adj(pmin_adj < 0) = 0;
    disox_adj(disox_adj < 0) = 0;
    
    % Create total nitrogen and phosphorus
    totn_adj = orgn_adj + no3_adj + no2_adj + nh4_adj;
    totp_adj = orgp_adj + pmin_adj;
    
    % Add to sbsn_em_output structure
    % -------------------------------
    % Use decade string
    sbsn_em_output.(strcat('q95', decade_str)) = q95;
    sbsn_em_output.(strcat('q50', decade_str)) = q50;
    sbsn_em_output.(strcat('q5', decade_str)) = q5;
    sbsn_em_output.(strcat('qmean', decade_str)) = qmean;
    sbsn_em_output.(strcat('v', decade_str)) = v;
    sbsn_em_output.(strcat('orgn', decade_str)) = orgn_adj;
    sbsn_em_output.(strcat('no3', decade_str)) = no3_adj;
    sbsn_em_output.(strcat('no2', decade_str)) = no2_adj;
    sbsn_em_output.(strcat('nh4', decade_str)) = nh4_adj;
    sbsn_em_output.(strcat('totn', decade_str)) = totn_adj;
    sbsn_em_output.(strcat('orgp', decade_str)) = orgp_adj;
    sbsn_em_output.(strcat('pmin', decade_str)) = pmin_adj;
    sbsn_em_output.(strcat('totp', decade_str)) = totp_adj;
    sbsn_em_output.(strcat('disox', decade_str)) = disox_adj;
    
    % Convert to table for output
    sbsn_em_output = struct2table(sbsn_em_output);
    
end