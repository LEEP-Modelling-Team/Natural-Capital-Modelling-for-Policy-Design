function subctch_em_summary = fcn_subctch_summary_calc(subctch_em_out, decade_str)

    % Calculate summary statistics of water quantity and quality
    % ----------------------------------------------------------
    q5      = quantile(subctch_em_out.flow, 0.95);
    qmean   = mean(subctch_em_out.flow);
    orgn	= (mean(subctch_em_out.orgn) * 1000000) ./ (qmean * 1000 * 86400);
    no3     = (mean(subctch_em_out.no3) * 1000000) ./ (qmean * 1000 * 86400);
    no2     = (mean(subctch_em_out.no2) * 1000000) ./ (qmean * 1000 * 86400);
    nh4     = (mean(subctch_em_out.nh4) * 1000000) ./ (qmean * 1000 * 86400);
    orgp	= (mean(subctch_em_out.orgp) * 1000000) ./ (qmean * 1000 * 86400);
    pmin	= (mean(subctch_em_out.minp) * 1000000) ./ (qmean * 1000 * 86400);
    
    % Create total nitrogen and phosphorus
    totn = orgn + no3 + no2 + nh4;
    totp = orgp + pmin;
    
    % Add to subctch_em_output structure
    % -------------------------------
    % Use decade string
    subctch_em_summary.(strcat('q5', decade_str)) = q5;
    subctch_em_summary.(strcat('orgn', decade_str)) = orgn;
    subctch_em_summary.(strcat('no3', decade_str)) = no3;
    subctch_em_summary.(strcat('no2', decade_str)) = no2;
    subctch_em_summary.(strcat('nh4', decade_str)) = nh4;
    subctch_em_summary.(strcat('totn', decade_str)) = totn;
    subctch_em_summary.(strcat('orgp', decade_str)) = orgp;
    subctch_em_summary.(strcat('pmin', decade_str)) = pmin;
    subctch_em_summary.(strcat('totp', decade_str)) = totp;
    % Convert to table for output
    subctch_em_summary = struct2table(subctch_em_summary);
    
end