function rec_all_options = fcn_run_recreation_all_options(dorecmodel, cell_info, MP, conn)

    % NB. Currently combinations of ELM options are not needed here, so
    % they are commented out...

    if dorecmodel
        
        %% (0) Set up
        %  ==========
        % Get total arable and farm grass hectares in each cell
        % -----------------------------------------------------
        % Assume this is 2020-2029 average as predicted by NEV agriculture
        % model
        sqlquery = ['SELECT arable_ha_20, grass_ha_20 ', ...
                    'FROM nevo_explore.explore_2km ', ...
                    'WHERE new2kid IN ', cell_info.new2kid_string , ' ' ...
                    'ORDER BY new2kid'];
        setdbprefs('DataReturnFormat', 'table');
        dataReturn  = fetch(exec(conn, sqlquery));
        arable_ha = dataReturn.Data.arable_ha_20;
        grass_ha = dataReturn.Data.grass_ha_20;
        
        % Combine hectares with 2km cell ids
        % ----------------------------------
        arable_rec = [cell_info.new2kid arable_ha];
        grass_rec  = [cell_info.new2kid grass_ha];
        dummy_rec  = [cell_info.new2kid(1) 0];       % create dummy for running fcn_run_recreation_substitution
        
        % Set up parameters for fcn_run_recreation_substitution
        % -----------------------------------------------------
        visval_type = 'simultaneous';   % simultaneous calculation NOT independent
        minsitesize = 10;               % minimum site size for new recreation area (hectares)
        
        %% (1) Run recreation models under different scenarios
        %  ===================================================
        % Uses fcn_run_recreation_substitution to take account of
        % substitution
        % Run models with duplication of cells and partition results to get
        % individual ELM option results
        
        % (a) Arable to woodland, farm grass to woodland (individual)
        % -----------------------------------------------------------
        [rec_wood, ~] = fcn_run_recreation_substitution(MP.rec_data_folder, [arable_rec; grass_rec], dummy_rec, visval_type, minsitesize);
        rec_arable_to_wood = rec_wood(1:cell_info.ncells, :);
        rec_grass_to_wood  = rec_wood((cell_info.ncells + 1):end, :);
        
        % (b) Arable to semi-natural, farm grass to semi-natural (individual)
        % -------------------------------------------------------------------
        [~, rec_sng] = fcn_run_recreation_substitution(MP.rec_data_folder, dummy_rec, [arable_rec; grass_rec], visval_type, minsitesize);
        rec_arable_to_sng = rec_sng(1:cell_info.ncells, :);
        rec_grass_to_sng  = rec_sng((cell_info.ncells + 1):end, :);
        
%         % (c) Arable to woodland, farm grass to semi-natural (combination)
%         % ----------------------------------------------------------------
%         [rec_wood, rec_sng] = fcn_run_recreation_substitution(MP.rec_data_folder, arable_rec, grass_rec, visval_type, minsitesize);
%         rec_ar_w_d_sng = rec_wood + rec_sng;
%         
%         % (d) Arable to semi-natural, farm grass to woodland (combination)
%         % ----------------------------------------------------------------
%         [rec_wood, rec_sng] = fcn_run_recreation_substitution(MP.rec_data_folder, grass_rec, arable_rec, visval_type, minsitesize);
%         rec_ar_sng_d_w = rec_wood + rec_sng;
%         
%         % (e) Arable to woodland, farm grass to woodland (combination)
%         % ------------------------------------------------------------
%         rec_ar_w_d_w = rec_arable_to_wood + rec_grass_to_wood;
%         
%         % (f) Arable to semi-natural, farm grass to semi-natural (combination)
%         % --------------------------------------------------------------------
%         rec_ar_sng_d_sng = rec_arable_to_sng + rec_grass_to_sng;
        
        %% (2) Store results in tables within rec_all_options structure
        %  ============================================================
        
        % Variable names for table
        % ------------------------
        rec_var_names = {'new2kid', 'rec_val_20','rec_val_30','rec_val_40', 'rec_val_50', 'rec_vis_20', 'rec_vis_30', 'rec_vis_40', 'rec_vis_50'};
        
        % Store results for each individual ELM option in table
        % -----------------------------------------------------
		% Must use correct field names for ELM options
        rec_all_options.arable_reversion_wood_access	= array2table([cell_info.new2kid, rec_arable_to_wood], 'VariableNames', rec_var_names);               % Arable reversion to woodland
        rec_all_options.destocking_wood_access			= array2table([cell_info.new2kid, rec_grass_to_wood], 'VariableNames', rec_var_names);                % Farm grass to woodland
        rec_all_options.arable_reversion_sng_access 	= array2table([cell_info.new2kid, rec_arable_to_sng], 'VariableNames', rec_var_names);                % Arable reversion to semi-natural
        rec_all_options.destocking_sng_access			= array2table([cell_info.new2kid, rec_grass_to_sng], 'VariableNames', rec_var_names);                 % Farm grass to semi-natural
        rec_all_options.no_access						= array2table([cell_info.new2kid, zeros(size(rec_arable_to_wood))], 'VariableNames', rec_var_names);  % No access options - all zeros
        
%         % Combinations
%         rec_all_options.ar_w_d_sng     = array2table([cell_info.new2kid, rec_ar_w_d_sng], 'VariableNames', rec_var_names);
%         rec_all_options.ar_sng_d_w     = array2table([cell_info.new2kid, rec_ar_sng_d_w], 'VariableNames', rec_var_names);
%         rec_all_options.ar_w_d_w       = array2table([cell_info.new2kid, rec_ar_w_d_w], 'VariableNames', rec_var_names);
%         rec_all_options.ar_sng_d_sng   = array2table([cell_info.new2kid, rec_ar_sng_d_sng], 'VariableNames', rec_var_names);
        
        %% (3) Save results to rec_vis_val_save.mat file
        %  =============================================
        save([MP.data_out 'rec_vis_val_save.mat'], 'rec_all_options', '-mat', '-v6');
        
    else
        load([MP.data_out 'rec_vis_val_save.mat'], 'rec_all_options');
    end

end