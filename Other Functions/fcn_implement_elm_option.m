function [PV_updated, elm_ha, scheme_length, site_type] = fcn_implement_elm_option(conn, elm_option_string, cell_info, PV_original)

    %% 0. Check input and set constants
    %  --------------------------------
    available_elm_options = {'arable_reversion_sng_access', 'destocking_sng_access', 'arable_reversion_wood_access', 'destocking_wood_access', 'arable_reversion_sng_noaccess', 'destocking_sng_noaccess', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'};
    if ~any(strcmp(elm_option_string, available_elm_options))
        error('Please supply valid ELM option.')
    end
    
    % Set length of ELM scheme (scheme_length)
    switch elm_option_string
        case {'arable_reversion_sng_access', 'destocking_sng_access', 'arable_reversion_sng_noaccess', 'destocking_sng_noaccess'}
            scheme_length = 5;
            
        case {'arable_reversion_wood_access', 'destocking_wood_access', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'}
            scheme_length = 50;
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

    %% 1. Get hectares available for ELM scheme (elm_ha)
    %  -------------------------------------------------
    % This depends on ELM option in elm_option_string
    % Requires database call to nevo_explore.explore_2km table using conn
    % Assume hectares available is 2020-2029 average from agriculture model
    switch elm_option_string
        case {'arable_reversion_sng_access', 'arable_reversion_wood_access', 'arable_reversion_sng_noaccess', 'arable_reversion_wood_noaccess'}
            % Get total arable hectares in each cell
            sqlquery = ['SELECT arable_ha_20 FROM nevo_explore.explore_2km WHERE new2kid IN ', cell_info.new2kid_string];
            setdbprefs('DataReturnFormat', 'numeric');
            dataReturn  = fetch(exec(conn, sqlquery));
            elm_ha = dataReturn.Data;
        case {'destocking_sng_access', 'destocking_wood_access', 'destocking_sng_noaccess', 'destocking_wood_noaccess'}
            % Get total grass hectares in each cell
            sqlquery = ['SELECT grass_ha_20 FROM nevo_explore.explore_2km WHERE new2kid IN ', cell_info.new2kid_string];
            setdbprefs('DataReturnFormat', 'numeric');
            dataReturn  = fetch(exec(conn, sqlquery));
            elm_ha = dataReturn.Data;
    end
    
    %% 2. Implement ELM option
    %  -----------------------
    % This depends on ELM option in elm_option_string
    % Set PV_updated to PV_original, then update correct land covers
    PV_updated = PV_original;
    
    switch elm_option_string
        case {'arable_reversion_sng_access', 'destocking_sng_access', 'arable_reversion_sng_noaccess', 'destocking_sng_noaccess'}
            % Subtract elm_ha from agriculture, add to semi-natural grassland
            PV_updated.farm_ha  = PV_updated.farm_ha - elm_ha;
            PV_updated.sngrass_ha = PV_updated.sngrass_ha + elm_ha;
        case {'arable_reversion_wood_access', 'destocking_wood_access', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'}
            % Subtract elm_ha from agriculture, add to woodland
            PV_updated.farm_ha  = PV_updated.farm_ha - elm_ha;
            PV_updated.wood_ha = PV_updated.wood_ha + elm_ha;
    end

end