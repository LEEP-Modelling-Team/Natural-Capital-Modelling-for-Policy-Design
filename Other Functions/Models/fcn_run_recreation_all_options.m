function rec_all_options = fcn_run_recreation_all_options(MP, new2kid, arable_ha, grass_ha)

    % ORVAL model with substitution using cross-nested logit
    % ------------------------------------------------------
    % Runs the orval model to value adding new sites to the existing choice
    % set. The additional sites are:
    %   o new woodland in a cell for woodland options
    %   o new path in sng for sng options
    % We make the conservative assumption on substitution adding new 
    % sites in every cell ('simultaneous') at the same time and creating
    % the largest substitution effect.
    
       
    % 1. Set up
    % ---------

    % Combine hectares with 2km cell ids
    % ----------------------------------
    N = length(new2kid);
    arable_rec = [new2kid arable_ha];
    grass_rec  = [new2kid grass_ha];    
    dummy_rec  = [new2kid(1) 0];       % create dummy for running fcn_run_recreation_substitution

    % Set up parameters for fcn_run_recreation_substitution
    % -----------------------------------------------------
    minsitesize = 10;                       % minimum site size for new recreation area (hectares)
    visval_type      = MP.visval_type;      % 'simultaneous' or 'independent' valuation wrt to substituion possibilities 
    site_type_wood   = MP.site_type_wood;   % 'park_new' or 'path_new' type of site created
    site_type_sng    = MP.site_type_sng;    % 'park_new' or 'path_new' type of site created      
    site_area2length = MP.site_area2length; % 'diameter' or 'perimeter' type of site created  
    
    
    % 2.  Run recreation models under different scenarios
    % ---------------------------------------------------
    % Uses fcn_run_recreation_substitution to take account of
    % substitution
    % Run models with duplication of cells and partition results to get
    % individual ELM option results

    % (a) Arable to woodland, farm grass to woodland (individual)
    % -----------------------------------------------------------
    [rec_wood, ~] = fcn_run_recreation_substitution(MP.rec_data_folder, [arable_rec; grass_rec], dummy_rec, site_type_wood, site_type_sng, site_area2length, visval_type, minsitesize);
    rec_arable_to_wood = rec_wood(1:N, :);
    rec_grass_to_wood  = rec_wood((N + 1):end, :);

    % (b) Arable to semi-natural, farm grass to semi-natural (individual)
    % -------------------------------------------------------------------
    [~, rec_sng] = fcn_run_recreation_substitution(MP.rec_data_folder, dummy_rec, [arable_rec; grass_rec], site_type_wood, site_type_sng, site_area2length, visval_type, minsitesize);
    rec_arable_to_sng = rec_sng(1:N, :);
    rec_grass_to_sng  = rec_sng((N + 1):end, :);

    % (2) Store results in tables within rec_all_options structure
    % ============================================================

    % Variable names for table
    % ------------------------
    rec_var_names = {'new2kid', 'rec_val', 'rec_vis', 'rec_viscar'};

    % Store results for each individual ELM option in table
    % -----------------------------------------------------
    % Must use correct field names for ELM options
    rec_all_options.arable_reversion_wood_access	= array2table([new2kid, rec_arable_to_wood], 'VariableNames', rec_var_names);               % Arable reversion to woodland
    rec_all_options.destocking_wood_access			= array2table([new2kid, rec_grass_to_wood], 'VariableNames', rec_var_names);                % Farm grass to woodland
    rec_all_options.arable_reversion_sng_access 	= array2table([new2kid, rec_arable_to_sng], 'VariableNames', rec_var_names);                % Arable reversion to semi-natural
    rec_all_options.destocking_sng_access			= array2table([new2kid, rec_grass_to_sng], 'VariableNames', rec_var_names);                 % Farm grass to semi-natural
    rec_all_options.no_access						= array2table([new2kid, zeros(size(rec_arable_to_wood))], 'VariableNames', rec_var_names);  % No access options - all zeros

end