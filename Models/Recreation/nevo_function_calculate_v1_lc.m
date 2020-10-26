% Calculates new landcover elements of v1 for each site
% -----------------------------------------------------

function v1lc = nevo_function_calculate_v1_lc(sitetype, lcs_pct, area, divxlc, divpct, water_pct, params)
       
    % !!!CHECK PARAMETERS ARE OK AS AVERAGE OF TYPES:
    
    switch sitetype
        
        case 'park_new'
                                        
            v1_lc = (log(area).*lcs_pct) * [cell2mat(params(find(strcmp(params(:,1),'LCWOODS')),2)); ...
                                            cell2mat(params(find(strcmp(params(:,1),'LCNGRASS')),2))];                                                          

            lcs_div_pct = (lcs_pct./sum(lcs_pct,2));
            v1_div = ((1./sum(lcs_div_pct.^2,2)) - 1) * cell2mat(params(find(strcmp(params(:,1),'DIV')),2));

            [~, lcmax] = max(lcs_pct,[],2);

            v1_c = nevo_function_changem(lcmax, [cell2mat(params(find(strcmp(params(:,1),'CWOODS')) ,2)); ...
                                   cell2mat(params(find(strcmp(params(:,1),'CNGRASS')),2))], 1:2);
            
        case 'path_new'
        
            v1_lc = (log(area).*lcs_pct) * [cell2mat(params(find(strcmp(params(:,1),'PLCWOODS')),2)); ...
                                            cell2mat(params(find(strcmp(params(:,1),'PLCNGRAS')),2))];                                                          

            lcs_div_pct = (lcs_pct./sum(lcs_pct,2));
            v1_div = ((1./sum(lcs_div_pct.^2,2)) - 1) * cell2mat(params(find(strcmp(params(:,1),'PDIV')),2));

            [~, lcmax] = max(lcs_pct,[],2);

            v1_c = nevo_function_changem(lcmax, [cell2mat(params(find(strcmp(params(:,1),'PCWOODS')) ,2)); ...
                                   cell2mat(params(find(strcmp(params(:,1),'PCNGRASS')),2))], 1:2);    
                               
        case 'path_chg'
    
            v1_lc = (log(area).*lcs_pct) * [cell2mat(params(find(strcmp(params(:,1),'PLCWOODS')),2)); ...
                                            cell2mat(params(find(strcmp(params(:,1),'PLCAGRIC')),2)); ...
                                            cell2mat(params(find(strcmp(params(:,1),'PLCMGRAS')),2)); ...
                                            cell2mat(params(find(strcmp(params(:,1),'PLCNGRAS')),2))];                                                          


            lcs_div_pct = (lcs_pct./sum(lcs_pct,2)).*divpct; % rescale lc % to fill out non-urban area
            v1_div = ((1./(divxlc + sum(lcs_div_pct.^2,2))) - 1) * cell2mat(params(find(strcmp(params(:,1),'PDIV')),2));
            v1_div(isnan(v1_div)) = 0; % Correction for where NEVO cells all urban

            [~, lcmax] = max([lcs_pct water_pct],[],2);

            v1_c = nevo_function_changem(lcmax, [cell2mat(params(find(strcmp(params(:,1),'PCWOODS')) ,2)); ...
                                   cell2mat(params(find(strcmp(params(:,1),'PCAGRIC')) ,2)); ...
                                   cell2mat(params(find(strcmp(params(:,1),'PCMGRASS')),2));...
                                   cell2mat(params(find(strcmp(params(:,1),'PCNGRASS')),2));...
                                   cell2mat(params(find(strcmp(params(:,1),'PCFWATER')),2));...
                                   cell2mat(params(find(strcmp(params(:,1),'PCSWATER')),2))], 1:6);
        
        otherwise
            warning('Unexpected site type. No v1 landcover calculated.')
    end

    v1lc = v1_lc + v1_div + v1_c;

    
end