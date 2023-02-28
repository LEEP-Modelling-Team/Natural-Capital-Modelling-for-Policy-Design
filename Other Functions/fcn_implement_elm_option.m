function [option_lcs, elm_ha, scheme_length, site_type] = fcn_implement_elm_option(conn, elm_option_string, cell_info, baseline_lcs, MP, carbon_price)

    % 0. Check input and set constants
    % --------------------------------
    available_elm_options = {'arable_reversion_sng_access', 'destocking_sng_access', 'arable_reversion_wood_access', 'destocking_wood_access', 'arable_reversion_sng_noaccess', 'destocking_sng_noaccess', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'};
    if ~any(strcmp(elm_option_string, available_elm_options))
        error('Please supply valid ELM option.')
    end
    
    % Set length of ELM scheme (scheme_length)
    switch elm_option_string
        case {'arable_reversion_sng_access', 'destocking_sng_access', 'arable_reversion_sng_noaccess', 'destocking_sng_noaccess'}
            scheme_length = inf;            
        case {'arable_reversion_wood_access', 'destocking_wood_access', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'}
            scheme_length = inf;
    end
    
    % Set site type for options with different recreation access
    switch elm_option_string
        case {'arable_reversion_sng_noaccess', 'destocking_sng_noaccess', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'}
            site_type = "path_chg";
        case {'arable_reversion_sng_access', 'destocking_sng_access'}
            site_type = "path_new";
        case {'arable_reversion_wood_access', 'destocking_wood_access'}
            site_type = "park_new";
    end

    % 1. Get hectares available for ELM scheme (elm_ha)
    % -------------------------------------------------
    switch elm_option_string
        case {'arable_reversion_sng_access', 'arable_reversion_wood_access', 'arable_reversion_sng_noaccess', 'arable_reversion_wood_noaccess'}
            % Get total arable hectares in each cell
            elm_ha = mean(baseline_lcs.arable_ha(:,1:10), 2);
        case {'destocking_sng_access', 'destocking_wood_access', 'destocking_sng_noaccess', 'destocking_wood_noaccess'}
            % Get total grass hectares in each cell
            elm_ha = mean(baseline_lcs.grass_ha(:,1:10), 2);
    end
    
    % 2. Implement ELM option
    % -----------------------
    % This depends on ELM option in elm_option_string
    % Set PV_updated to PV_original, then update correct land covers
    option_lcs = baseline_lcs;
    
    switch elm_option_string
        case {'arable_reversion_sng_access', 'destocking_sng_access', 'arable_reversion_sng_noaccess', 'destocking_sng_noaccess'}
            % Subtract elm_ha from agriculture, add to semi-natural grassland
            option_lcs.farm_ha    = option_lcs.farm_ha - elm_ha;
            option_lcs.sngrass_ha = option_lcs.sngrass_ha + elm_ha;
        case {'arable_reversion_wood_access', 'destocking_wood_access', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'}
            % Subtract elm_ha from agriculture, add to woodland
            option_lcs.farm_ha = option_lcs.farm_ha - elm_ha;
            option_lcs.wood_ha = option_lcs.wood_ha + elm_ha;
    end

end