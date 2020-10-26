function sbsn_em_fromland = fcn_emulator_fromland(SWATemdata,landuse,sbsn_order_idx)

%% Land use emulators
    % New land use with interactions (but no intercept)
    X1 = x2fx(landuse,'interactions');
    X1 = X1(:,2:end);
    
    % Flow
    sbsn_em_fromland.flow = X1*SWATemdata.coef_lu.flow(:,:,sbsn_order_idx)*SWATemdata.pcrot_lu.flow(:,:,sbsn_order_idx)' + SWATemdata.pcmeans_lu.flow(:,sbsn_order_idx)';
    sbsn_em_fromland.flow(sbsn_em_fromland.flow<0) = 0; % censor from below 0

    % Organic nitrogen
    sbsn_em_fromland.orgn = X1*SWATemdata.coef_lu.orgn(:,:,sbsn_order_idx)*SWATemdata.pcrot_lu.orgn(:,:,sbsn_order_idx)' + SWATemdata.pcmeans_lu.orgn(:,sbsn_order_idx)';
    sbsn_em_fromland.orgn(sbsn_em_fromland.orgn<0) = 0; % censor from below 0

    % Organic phosphorus
    sbsn_em_fromland.orgp = X1*SWATemdata.coef_lu.orgp(:,:,sbsn_order_idx)*SWATemdata.pcrot_lu.orgp(:,:,sbsn_order_idx)' + SWATemdata.pcmeans_lu.orgp(:,sbsn_order_idx)';
    sbsn_em_fromland.orgp(sbsn_em_fromland.orgp<0) = 0; % censor from below 0

    % Nitrate (no3)
    sbsn_em_fromland.no3 = X1*SWATemdata.coef_lu.no3(:,:,sbsn_order_idx)*SWATemdata.pcrot_lu.no3(:,:,sbsn_order_idx)' + SWATemdata.pcmeans_lu.no3(:,sbsn_order_idx)';
    sbsn_em_fromland.no3(sbsn_em_fromland.no3<0) = 0; % censor from below 0
    
    % Ammonium (nh4) - no land use model
    
    % Nitrite (no2) - no land use model
    
    % Mineral phosphorus
    sbsn_em_fromland.minp = X1*SWATemdata.coef_lu.minp(:,:,sbsn_order_idx)*SWATemdata.pcrot_lu.minp(:,:,sbsn_order_idx)' + SWATemdata.pcmeans_lu.minp(:,sbsn_order_idx)';
    sbsn_em_fromland.minp(sbsn_em_fromland.minp<0) = 0; % censor from below 0
    
    % Dissolved oxygen
    sbsn_em_fromland.disox = X1*SWATemdata.coef_lu.disox(:,:,sbsn_order_idx)*SWATemdata.pcrot_lu.disox(:,:,sbsn_order_idx)' + SWATemdata.pcmeans_lu.disox(:,sbsn_order_idx)';
    sbsn_em_fromland.disox(sbsn_em_fromland.disox<0) = 0; % censor from below 0

end