%% FCN_CALC_ARABLE
%  ===============
%
% Calculate crop hectares, food production and SFP using Carlo's arable
% model.
%
% INPUTS:
%
% arable_ha_cells
%   - hectares of arable in each cell
% data_cells
%   - table of all variables needed for arable models (excluding climate) 
%       in each cell
% climate_cells
%   - structure of rain and temperature variables in each cell
% coefficients
%   - structure containing coefficients for arable models
% irrigation
%   - logical for whether irrigation is on or off
%
% OUTPUT:
%
% arable_info
%   - structure containing crop hectares, food production, profit in each 
%       cell

function arable_info = fcn_calc_arable(arable_ha_cells, data_cells, climate_cells, coefficients, irrigation)

    %% Set up
    % Apply irrigation if requested
    if irrigation
        top_up_rain = (climate_cells.rain < 280) .* (280 - climate_cells.rain);
        climate_cells.rain = climate_cells.rain + top_up_rain;
    end
    
    % Create derived climate variables needed for arable models
    climate_cells.sqrain = climate_cells.rain.*climate_cells.rain;
    climate_cells.sqtemp = climate_cells.temp.*climate_cells.temp;
    climate_cells.raintemp = climate_cells.rain.*climate_cells.temp;

    % Set up model matrix for top level model
    % NB: notice that soil variables are NOT divided by 100 here!
    model_matrix = [data_cells.nprice_wheat data_cells.nprice_osr data_cells.nprice_wbar data_cells.nprice_sbar data_cells.nprice_pot data_cells.nprice_sb data_cells.nprice_pnb data_cells.avelev_cell data_cells.pca_fslpgrt6 data_cells.root_depth data_cells.pca_oc5 data_cells.pca_oc6 data_cells.ph data_cells.sqph data_cells.cuph climate_cells.rain climate_cells.sqrain climate_cells.temp climate_cells.sqtemp climate_cells.raintemp data_cells.pca_stony data_cells.pca_gravelly data_cells.pca_notex data_cells.pca_npoct10 data_cells.pca_esa94 data_cells.pca_ukgre12 data_cells.dist300 data_cells.sb_dist data_cells.sb_dist20 data_cells.sb_dist40 data_cells.sb_dist80 data_cells.sb_dist120 data_cells.island data_cells.trend_ar data_cells.const];
    
    %% Model predictions
    % Multiply model matrix by coefficients to get crop shares (defined on [0,100])
    wheat_share = model_matrix * coefficients.wheat;
    osr_share = model_matrix * coefficients.osr;
    bar_share = model_matrix * coefficients.tbar;
    root_share = model_matrix * coefficients.root;

    % Carlo's "calibration" step, to improve performance in Scotland for wheat
    % and total barley
    wheat_share(data_cells.scotland == 1) = wheat_share(data_cells.scotland == 1) - 25;
    bar_share(data_cells.scotland == 1) = bar_share(data_cells.scotland == 1) + 25;

    % Apply Censoring from below 0 and above 100
    wheat_share(wheat_share < 0) = 0;
    osr_share(osr_share < 0) = 0;
    bar_share(bar_share < 0) = 0;
    root_share(root_share < 0) = 0;

    wheat_share(wheat_share > 100) = 100;
    osr_share(osr_share > 100) = 100;
    bar_share(bar_share > 100) = 100;
    root_share(root_share > 100) = 100;

    % Reweight if total arable share is over 100
    arable_share = wheat_share + osr_share + bar_share + root_share;
    arable_weight = (arable_share > 100) .* (100 ./ arable_share) + (arable_share <= 100);
    arable_weight(isnan(arable_weight)) = 1;

    % Convert shares into hectares, place leftover ha into other, and pass to output
    arable_info.wheat_ha = arable_weight .* wheat_share .* arable_ha_cells ./ 100;
    arable_info.osr_ha = arable_weight .* osr_share .* arable_ha_cells ./ 100;
    arable_info.bar_ha = arable_weight .* bar_share .* arable_ha_cells ./ 100;
    arable_info.root_ha = arable_weight .* root_share .* arable_ha_cells ./ 100;
    arable_info.other_ha = arable_ha_cells - arable_info.wheat_ha - arable_info.osr_ha - arable_info.bar_ha - arable_info.root_ha;
    arable_info.other_ha(arable_info.other_ha < 0) = 0; % some values basically zero but negative

    % Split total barley in winter and spring, and root crops into potatoes and
    % sugarbeet using regional shares
    arable_info.wbar_ha = data_cells.share_wbar .* arable_info.bar_ha;
    arable_info.sbar_ha = (1 - data_cells.share_wbar) .* arable_info.bar_ha;
    arable_info.pot_ha = data_cells.share_pot .* arable_info.root_ha;
    arable_info.sb_ha = (1 - data_cells.share_pot) .* arable_info.root_ha;

    % Apply yields (tonnes per ha) and calculate total food production
    arable_info.wheat_food = arable_info.wheat_ha .* data_cells.yield_wheat;
    arable_info.osr_food = arable_info.osr_ha .* data_cells.yield_osr;
    arable_info.wbar_food = arable_info.wbar_ha .* data_cells.yield_wbar;
    arable_info.sbar_food = arable_info.sbar_ha .* data_cells.yield_sbar;
    arable_info.pot_food = arable_info.pot_ha .* data_cells.yield_pot;
    arable_info.sb_food = arable_info.sb_ha .* data_cells.yield_sb;
    % No yield assumed for other crop category so this does not contribute to
    % total food production
    arable_info.food = arable_info.wheat_food + arable_info.osr_food + arable_info.wbar_food + arable_info.sbar_food + arable_info.pot_food + arable_info.sb_food;

    % Calculate individual crop gross margin (per hectare) using Carlo's new method
    wheat_fgm = 0.45 * data_cells.yield_wheat .* data_cells.price_wheat;
    osr_fgm = 0.45 * data_cells.yield_osr .* data_cells.price_osr;
    wbar_fgm = 0.45 * data_cells.yield_wbar .* data_cells.price_wbar;
    sbar_fgm = 0.45 * data_cells.yield_sbar .* data_cells.price_sbar;
    pot_fgm = 0.45 * data_cells.yield_pot .* data_cells.price_pot;
    sb_fgm = 0.45 * data_cells.yield_sb .* data_cells.price_sb;
    other_fgm = wheat_fgm; % assume other crop fgm is the same as wheat fgm
    
    % Total crop profit
    arable_info.arable_profit = wheat_fgm .* arable_info.wheat_ha + osr_fgm .* arable_info.osr_ha + wbar_fgm .* arable_info.wbar_ha + sbar_fgm .* arable_info.sbar_ha + pot_fgm .* arable_info.pot_ha + sb_fgm .* arable_info.sb_ha + other_fgm .* arable_info.other_ha;

end

