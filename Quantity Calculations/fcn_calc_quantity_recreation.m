function quantity_rec = fcn_calc_quantity_recreation(start_year, end_year, elm_option, elm_ha)

    % Environmental quantities for recreation is the hectares of
    % semi-natural grassland (sng) or woodland provided with or without
    % access, multiplied by the length of the scheme
    scheme_length = (end_year - start_year + 1);
    quantity_rec = array2table(zeros(size(elm_ha, 1), 4), ...
                               'VariableNames', ...
                               {'rec_ha_sng_access', ...
                                'rec_ha_wood_access', ...
                                'rec_ha_sng_noaccess', ...
                                'rec_ha_wood_noaccess'});
    switch elm_option
        case {'arable_reversion_sng_access', 'destocking_sng_access'}
            quantity_rec.rec_ha_sng_access = scheme_length * elm_ha;
        case {'arable_reversion_wood_access', 'destocking_wood_access'}
            quantity_rec.rec_ha_wood_access = scheme_length * elm_ha;
        case {'arable_reversion_sng_noaccess', 'destocking_sng_noaccess'}
            quantity_rec.rec_ha_sng_noaccess = scheme_length * elm_ha;
        case {'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'}
            quantity_rec.rec_ha_wood_noaccess = scheme_length * elm_ha;
    end

end