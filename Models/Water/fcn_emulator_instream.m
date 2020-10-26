function sbsn_em_out = fcn_emulator_instream(SWATemdata,sbsn_em_in,sbsn_order_idx)

    % Flow
    X2.flow = [ones(SWATemdata.nday,1) sbsn_em_in.flow' lagmatrix(sbsn_em_in.flow,1)];
    X2.flow(1,3) = X2.flow(1,2);
    sbsn_em_out.flow = X2.flow*SWATemdata.coef_ts.flow(:,sbsn_order_idx);
    sbsn_em_out.flow(sbsn_em_out.flow<0) = 0; % censor from below 0
    
    % Organic nitrogen
    X2.orgn = [ones(SWATemdata.nday,1) sbsn_em_in.orgn' lagmatrix(sbsn_em_in.orgn,1)];
    X2.orgn(1,3) = X2.orgn(1,2);
    sbsn_em_out.orgn = X2.orgn*SWATemdata.coef_ts.orgn(:,sbsn_order_idx);
    sbsn_em_out.orgn(sbsn_em_out.orgn<0) = 0; % censor from below 0
    
    % Organic phosphorus
    X2.orgp = [ones(SWATemdata.nday,1) sbsn_em_in.orgp' lagmatrix(sbsn_em_in.orgp,1)];
    X2.orgp(1,3) = X2.orgp(1,2);
    sbsn_em_out.orgp = X2.orgp*SWATemdata.coef_ts.orgp(:,sbsn_order_idx);
    sbsn_em_out.orgp(sbsn_em_out.orgp<0) = 0; % censor from below 0
    
    % Nitrate (no3)
    X2.no3 = [ones(SWATemdata.nday,1) sbsn_em_in.no3' lagmatrix(sbsn_em_in.no3,1)];
    X2.no3(1,3) = X2.no3(1,2);
    sbsn_em_out.no3 = X2.no3*SWATemdata.coef_ts.no3(:,sbsn_order_idx);
    sbsn_em_out.no3(sbsn_em_out.no3<0) = 0; % censor from below 0
    
    X2.other = [ones(SWATemdata.nday,1) sbsn_em_in.flow' sbsn_em_in.orgn' sbsn_em_in.orgp' sbsn_em_in.no3' sbsn_em_in.minp' sbsn_em_in.disox' lagmatrix(sbsn_em_in.flow,1) lagmatrix(sbsn_em_in.orgn,1) lagmatrix(sbsn_em_in.orgp,1) lagmatrix(sbsn_em_in.no3,1) lagmatrix(sbsn_em_in.minp,1) lagmatrix(sbsn_em_in.disox,1)];
    X2.other(1,8:13) = X2.other(1,2:7);
    
    % Ammonium (nh4)
    sbsn_em_out.nh4 = X2.other*SWATemdata.coef_ts.nh4(:,sbsn_order_idx);
    sbsn_em_out.nh4(sbsn_em_out.nh4<0) = 0; % censor from below 0
    
    % Nitrite (no2)
    sbsn_em_out.no2 = X2.other*SWATemdata.coef_ts.no2(:,sbsn_order_idx);
    sbsn_em_out.no2(sbsn_em_out.no2<0) = 0; % censor from below 0
    
    % Mineral phosphorus
    sbsn_em_out.minp = X2.other*SWATemdata.coef_ts.minp(:,sbsn_order_idx);
    sbsn_em_out.minp(sbsn_em_out.minp<0) = 0; % censor from below 0
    
    % Dissolved oxygen
    sbsn_em_out.disox = X2.other*SWATemdata.coef_ts.disox(:,sbsn_order_idx);
    sbsn_em_out.disox(sbsn_em_out.disox<0) = 0; % censor from below 0

end