function [rec_wood, rec_sng] = fcn_run_recreation_substitution(rec_data_folder, wood_data, sng_data, visval_type, min_site_size)

    %% 1. Data Preparation
    %  -------------------
    % 1.a Load saved data files
    % -------------------------
    NEVO_ORVal_newsite_data_mat = strcat(rec_data_folder, 'NEVO_ORVal_newsite_xmnl_data.mat');
    load(NEVO_ORVal_newsite_data_mat);
    
    % 1.b Calculate number of wood and sng cells
    % ------------------------------------------
    nwood = size(wood_data, 1);
    nsng = size(sng_data, 1);

    % 1.c Input sites below min site size
    % -----------------------------------
    wood_below_min_area_ind = (wood_data(:,2) < min_site_size);
    sng_below_min_area_ind  = (sng_data(:,2)  < min_site_size);

    % 1.d SNG area to path area
    % -------------------------
    % Calculate path length in m as perimeter of circle with this site area (maximum length 10km)
    pathlen  = min(2*pi*sqrt(sng_data(:,2)*10000/pi), 10000);
    % Assume 1.5 grid cells width and multiply by area of grid cell, ignore distance decay
    patharea = 1.5 * (pathlen/25) * 0.0625;
    sng_data = [sng_data(:,1) patharea];

    %% 2. v1 base for each new site
    %  ----------------------------
    % Find index of input cells in full list of cells
    [~, wood_cell_idx] = ismember(wood_data(:,1), NEVO_cell_v1dg.new2kid);
    [~, sng_cell_idx]  = ismember(sng_data(:,1),  NEVO_cell_v1dg.new2kid);

    wood_v1 = NEVO_cell_v1dg.v1dg_park(wood_cell_idx) + log(wood_data(:,2)) * bLCWOODS  + bCWOODS;
    sng_v1  = NEVO_cell_v1dg.v1dg_path(sng_cell_idx)  + log(sng_data(:,2))  * bPLCNGRAS + bPCNGRASS; 


    %% 3. v1 with tc for each new site to each max lsoa
    %  ------------------------------------------------
    % v1 + tc for each of max lsoa
    wood_v1wlk = wood_v1 + v1tcwlk(wood_cell_idx,:);
    wood_v1car = wood_v1 + v1tccar(wood_cell_idx,:);
    wood_v1wlk = reshape(wood_v1wlk',[nwood*nlsoasave, 1]); 
    wood_v1car = reshape(wood_v1car',[nwood*nlsoasave, 1]); 

    sng_v1wlk = sng_v1 + v1tcwlk(sng_cell_idx,:);
    sng_v1car = sng_v1 + v1tccar(sng_cell_idx,:);
    sng_v1wlk  = reshape(sng_v1wlk',[nsng*nlsoasave, 1]); 
    sng_v1car  = reshape(sng_v1car',[nsng*nlsoasave, 1]); 

    %% 4. Valuation
    %  ------------
    % 4.a alpha*exp(v1*lambda): for each of m nests
    % ---------------------------------------------
    wood_aexpv1wlk = wood_alphas' .* exp(wood_v1wlk.*lambdas');
    wood_aexpv1car = wood_alphas' .* exp(wood_v1car.*lambdas');  
    wood_aexpv1wlk(:,15) = 0;
    wood_aexpv1car(:,14) = 0;

    sng_aexpv1wlk = sng_alphas' .* exp(sng_v1wlk.*lambdas');
    sng_aexpv1car = sng_alphas' .* exp(sng_v1car.*lambdas');  
    sng_aexpv1wlk(:,15) = 0;
    sng_aexpv1car(:,14) = 0;

    % set aexpv1 to zero where too small for new recreation area
    wood_aexpv1wlk(wood_below_min_area_ind,:) = 0;
    wood_aexpv1car(wood_below_min_area_ind,:) = 0;
    sng_aexpv1wlk(sng_below_min_area_ind,:)   = 0;
    sng_aexpv1car(sng_below_min_area_ind,:)   = 0;

    % add sng path sites to wood park sites
    aexpv1wlk  = [wood_aexpv1wlk;   sng_aexpv1wlk];
    aexpv1car  = [wood_aexpv1car;   sng_aexpv1car];

    % 4.c indices of lsoas in set of new sites
    % ----------------------------------------
    wood_lsoa_idx = reshape(max_newsite_Index(wood_cell_idx,:)',[nwood*nlsoasave, 1]);
    sng_lsoa_idx  = reshape(max_newsite_Index(sng_cell_idx,:)', [nsng*nlsoasave,  1]);

    lsoa_idx = [wood_lsoa_idx; sng_lsoa_idx];

    % 4.d v0 and lsoa pops for 'max' lsoas
    % ------------------------------------
    lsoa_id   = lsoa_id(lsoa_idx);
    dog       = lsoa_dog(lsoa_idx);
    n0        = lsoa_pop(lsoa_idx,:);
    expv0     = expv0(lsoa_idx,:);
    sumaexpv1 = sumaexpv1(lsoa_idx,:);
    numlsoas  = size(lsoa_id,1);

    % 4.e Calculate new Sumexpv1 for each LSOA
    % ----------------------------------------
    if strcmp(visval_type, 'independent')            

        % a. sum(aexpv1): Add new site to old sum across sites within nest
        % ----------------------------------------------------------------
        newsumaexpv1 = sumaexpv1 + aexpv1wlk + aexpv1car;

    elseif strcmp(visval_type, 'simultaneous')
        % Each lsoa may be in top N for many new sites. If assume simultaneous provision of new sites
        % need to add on other sites to Sumexpv1 (denominator) for calculation of vis and val for each lsoa       

        % a. Sum aexpv1wlk & aexpv1car for max lsoas impacted by different new sites 
        % --------------------------------------------------------------------------    
        % Unique LSOAa with indices to first instance and order in 'all' list
        [lsoa_unique_ids,lsoa_all2unique_idx,lsoa_unique2all_idx] = unique(lsoa_idx);

        % Sum each nest column of aexpv1 for same lsoa
        for jj=size(aexpv1wlk,2):-1:1   %dynamically preallocate
            aexpv1wlk_unique(:,jj)= accumarray(lsoa_unique2all_idx,aexpv1wlk(:,jj),[],@nansum);
            aexpv1car_unique(:,jj)= accumarray(lsoa_unique2all_idx,aexpv1car(:,jj),[],@nansum);
        end

        % b. sum(aexpv1): Add new site to old sum across sites within nest
        % ----------------------------------------------------------------
        % Base Sumexpv1 is the same for this lsoa for all new sites so use reverse
        % index just to pull out first example of this sum
        sumaexpv1_unique    = sumaexpv1(lsoa_all2unique_idx,:);
        newsumaexpv1_unique = sumaexpv1_unique + aexpv1wlk_unique + aexpv1car_unique;

        % c. Reconstruct newsumaexpv1 for each site lsoa combination
        % ----------------------------------------------------------   
        newsumaexpv1 = newsumaexpv1_unique(lsoa_unique2all_idx,:);

    end

    % 4.f. (sumaexpv1)^1/lambda: Raise sum to power 1/lambda for each nest m
    % ----------------------------------------------------------------------
    sumaexpv1l    = sumaexpv1.^(1./lambdas');
    newsumaexpv1l = newsumaexpv1.^(1./lambdas');


    % 4.f Calculate new Sumexpv1 for each LSOA impacted by new site in cells
    % ----------------------------------------------------------------------
    viscar   = zeros(numlsoas,numsegs);
    viswlk   = zeros(numlsoas,numsegs);
    val      = zeros(numlsoas,numsegs);  

    for s = 1:numsegs

        s1 = 1+numperiods*(s-1);
        s2 = numperiods*s;

        s3 = s1 + numperiods*numsegs;
        s4 = s2 + numperiods*numsegs;

        % f. M: sum of all sumaexpv1l for seg s in each period of expv0
        % -------------------------------------------------------------
        M    = expv0(:,s1:s2) + sum(sumaexpv1l,2);
        newM = expv0(:,s1:s2) + sum(newsumaexpv1l,2);

        M2    = expv0(:,s3:s4) + sum(sumaexpv1l,2);
        newM2 = expv0(:,s3:s4) + sum(newsumaexpv1l,2);

        % g. Pm: prob chosen is in each nest (m) (for each seg s in each period)
        % ----------------------------------------------------------------------
        Pm  = repmat(newsumaexpv1l,1,numperiods)./repelem(newM,1,klb);
        Pm2 = repmat(newsumaexpv1l,1,numperiods)./repelem(newM2,1,klb);

        % h. Pim: prob chosen from each each nest (m)
        % -------------------------------------------
        Pimcar = aexpv1car./newsumaexpv1;
        Pimwlk = aexpv1wlk./newsumaexpv1;

        % i. P: Sum(Pim*Pm) for each segment and period
        % ---------------------------------------------
        Pcar = reshape(sum(reshape(repmat(Pimcar,1,numperiods).*Pm,numlsoas,klb,numperiods),2),numlsoas,numperiods);
        Pwlk = reshape(sum(reshape(repmat(Pimwlk,1,numperiods).*Pm,numlsoas,klb,numperiods),2),numlsoas,numperiods);

        Pcar2 = reshape(sum(reshape(repmat(Pimcar,1,numperiods).*Pm2,numlsoas,klb,numperiods),2),numlsoas,numperiods);
        Pwlk2 = reshape(sum(reshape(repmat(Pimwlk,1,numperiods).*Pm2,numlsoas,klb,numperiods),2),numlsoas,numperiods);

        % j. Visits to site: P = Sum(Pim*Pm)
        % ----------------------------------
        viscar(:,s) = (Pcar*ndays)  .* n0(:,s) .* (1-dog) + ...
                      (Pcar2*ndays) .* n0(:,s) .* dog;
        viswlk(:,s) = (Pwlk*ndays)  .* n0(:,s) .* (1-dog) + ...
                      (Pwlk2*ndays) .* n0(:,s) .* dog;

        if strcmp(visval_type, 'simultaneous')
            % Total visits from each unique lsoa to new sites
            vis_lsoa_unique = accumarray(lsoa_unique2all_idx, viscar(:,s) + viswlk(:,s), [], @nansum);
            % Proportion of lsoa visits going to each newsite
            vis_lsoa_prop = (viscar(:,s) + viswlk(:,s))./vis_lsoa_unique(lsoa_unique2all_idx,:);
            % Cells where no visits for this segment
            vis_lsoa_prop(isinf(vis_lsoa_prop)|isnan(vis_lsoa_prop)) = 0;
        end                            

        % k. Values of site: v = ln(newM) - ln(M)
        % ---------------------------------------
        val(:,s) = (((log(newM) - log(M)) *ndays) .* n0(:,s) .* (1-dog))./-bTCcar + ...
                   (((log(newM2)- log(M2))*ndays) .* n0(:,s) .* dog)./-bTCcar; 

        if strcmp(visval_type, 'simultaneous')
            % When simultaneous valuation, value of set of altered paths is the same for 
            % each lsoa, so allocate that value across sites in proportion to visitation
            val(:,s) = val(:,s) .* vis_lsoa_prop;
        end           

    end


    %% 5. Return Data
    %  --------------

    % a. Aggregate Visits & Values
    % ----------------------------
    val = sum(val, 2);
    vis = sum(viscar + viswlk, 2);
    fprintf(['%s\n  new visits: ' sprintf('%s', num2sepstr(sum(vis),  '%.0f')) ' \n  value:      ' sprintf('%s', num2sepstr(sum(val),  '%.0f')) ' \n'], visval_type);

    % b. Aggregate back to site/cell
    % ------------------------------
    val = reshape(val',[nlsoasave,nwood+nsng])';
    vis = reshape(vis',[nlsoasave,nwood+nsng])';

    val_wood = sum(val(1:nwood,:),2);
    val_sng  = sum(val(nwood+1:nwood+nsng,:),2);

    vis_wood = sum(vis(1:nwood,:),2);
    vis_sng  = sum(vis(nwood+1:nwood+nsng,:),2);
    
    rec_wood = [val_wood, val_wood, val_wood, val_wood, vis_wood, vis_wood, vis_wood, vis_wood];
    rec_sng  = [val_sng,   val_sng,  val_sng,  val_sng,  vis_sng,  vis_sng,  vis_sng, vis_sng];

end