function benefit_rec_ann = fcn_calc_benefit_recreation(start_year, elm_option, scheme_length, discount_constants, baseline, out)

    % Calculate the year in the 4 decades which relates to the end of the
    % current scheme, if the scheme ends after the fourth decade set to 40
    % and add _ann_extra
    end_year = min(40, start_year + (scheme_length - 1));
       
    % Time series of recreation value for 40 years
    rec_val_scenario = [repmat(out.rec_val_20, 1, 10) ...
        repmat(out.rec_val_30, 1, 10) ...
        repmat(out.rec_val_40, 1, 10) ...
        repmat(out.rec_val_50, 1, 10)];
    
    % For grass options (first two runs) save series
    % For wood  options reload grass weighted sum of grass to wood.    
    switch elm_option
        case {'arable_reversion_sng_access', 'destocking_sng_access', 'arable_reversion_sng_noaccess', 'destocking_sng_noaccess'}
            save(['Recreation Data/rec_val_ts_' elm_option '.mat'], 'rec_val_scenario');
        case {'arable_reversion_wood_access', 'destocking_wood_access', 'arable_reversion_wood_noaccess', 'destocking_wood_noaccess'}
            if strcmp(elm_option, 'arable_reversion_wood_access')
                rec_val_grass = load('Recreation Data/rec_val_ts_arable_reversion_sng_access.mat');
            elseif strcmp(elm_option, 'destocking_wood_access')
                rec_val_grass = load('Recreation Data/rec_val_ts_destocking_sng_access.mat');
            elseif strcmp(elm_option, 'arable_reversion_wood_noaccess')
                rec_val_grass = load('Recreation Data/rec_val_ts_arable_reversion_sng_noaccess.mat');
            elseif strcmp(elm_option, 'destocking_wood_noaccess')
                rec_val_grass = load('Recreation Data/rec_val_ts_destocking_sng_noaccess.mat');
            end
            rec_val_weights = 1 - exp(-0.05 * (0:39));
            rec_val_weights(40) = 1;
            
            rec_val_scenario = rec_val_scenario .* rec_val_weights + rec_val_grass.rec_val_scenario .* (1 - rec_val_weights);
        otherwise
            error('ELM option not found.')
    end

    % Set recreation value equal to the baseline, but overwrite year 
    % start_year:end_year with new recreation value from es_recreation 
    % (need to create this from decadal annuities)
    rec_val = baseline.rec_val;
    rec_val(:, start_year:end_year) = rec_val_scenario(:, start_year:end_year);
    
    % Turn 40 year series of recreation value into decadal annuities
    rec_val_diff_20 = nansum(cat(3, rec_val(:, 1:10), -baseline.rec_val(:, 1:10)), 3);
    rec_val_diff_30 = nansum(cat(3, rec_val(:, 11:20), -baseline.rec_val(:, 11:20)), 3);
    rec_val_diff_40 = nansum(cat(3, rec_val(:, 21:30), -baseline.rec_val(:, 21:30)), 3);
    rec_val_diff_50 = nansum(cat(3, rec_val(:, 31:40), -baseline.rec_val(:, 31:40)), 3);
    
    benefit_rec_ann_20 = (rec_val_diff_20 * discount_constants.delta_10) * discount_constants.gamma_10;
    benefit_rec_ann_30 = (rec_val_diff_30 * discount_constants.delta_10) * discount_constants.gamma_10;
    benefit_rec_ann_40 = (rec_val_diff_40 * discount_constants.delta_10) * discount_constants.gamma_10;
    benefit_rec_ann_50 = (rec_val_diff_50 * discount_constants.delta_10) * discount_constants.gamma_10;
    
    % Combine into a matrix
    if (end_year < 40)
        benefit_rec_ann = [benefit_rec_ann_20, benefit_rec_ann_30, benefit_rec_ann_40, benefit_rec_ann_50];
    else
        benefit_rec_ann_extra = nansum([rec_val(:,40),-baseline.rec_val(:,40)], 2);
        benefit_rec_ann = [benefit_rec_ann_20, benefit_rec_ann_30, benefit_rec_ann_40, benefit_rec_ann_50, benefit_rec_ann_extra];
    end

end