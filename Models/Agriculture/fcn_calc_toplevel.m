%% FCN_CALC_TOPLEVEL
%  =================
%
% Calculate arable hectares using Carlo's top level model.
%
% INPUTS:
%
% farm_ha_cells
%   - hectares of farmland in each cell
% data_cells
%   - table of all variables needed for top level model (excluding climate) in each cell
% climate_cells
%   - structure of rain and temperature variables in each cell
% coefficients
%   - coefficients for top level model
% irrigation
%   - logical for whether irrigation is on or off
%
% OUTPUT:
%
% arable_ha
%   - hectares of arable in each cell

function arable_ha = fcn_calc_toplevel(farm_ha_cells, data_cells, climate_cells, coefficients, irrigation)

    %% Set up
    % Apply irrigation if requested
    if irrigation
        top_up_rain = (climate_cells.rain < 280) .* (280 - climate_cells.rain);
        climate_cells.rain = climate_cells.rain + top_up_rain;
    end

    % Create derived climate variables needed for top level model
    climate_cells.rain260 = (climate_cells.rain > 260) .* (climate_cells.rain - 260);
    climate_cells.rain280 = (climate_cells.rain > 280) .* (climate_cells.rain - 280);
    climate_cells.rain300 = (climate_cells.rain > 300) .* (climate_cells.rain - 300);
    climate_cells.rain400 = (climate_cells.rain > 400) .* (climate_cells.rain - 400);
    climate_cells.rain600 = (climate_cells.rain > 600) .* (climate_cells.rain - 600);
    climate_cells.sqtemp = climate_cells.temp .* climate_cells.temp;
    climate_cells.raintemp = climate_cells.rain .* climate_cells.temp;

    % Set up model matrix for top level model
    % NB: notice that soil variables are divided by 100 here!
    model_matrix = [data_cells.const climate_cells.rain climate_cells.rain260 climate_cells.rain280 climate_cells.rain300 climate_cells.rain400 climate_cells.rain600 climate_cells.temp climate_cells.sqtemp data_cells.avelev_cell data_cells.avslp_cell data_cells.ph data_cells.pca_npoct10 data_cells.pca_esa94 data_cells.pca_ukgre12 data_cells.dist300 data_cells.pca_peat./100 data_cells.pca_gravelly./100 data_cells.pca_stony./100 data_cells.pca_fragipan./100 data_cells.pca_coarse./100 data_cells.pca_fine./100 data_cells.trend_toplevel data_cells.nprice_wheat climate_cells.raintemp];

    %% Model prediction
    % Multiply model matrix by coefficients to get logit of arable share
    arable_share_logit = model_matrix * coefficients;

    % Apply logistic transformation to get arable share
    arable_share = exp(arable_share_logit)./(1 + exp(arable_share_logit));

    % Multiply arable share by farm hectares to get arable hectares
    arable_ha = arable_share .* farm_ha_cells;

end

