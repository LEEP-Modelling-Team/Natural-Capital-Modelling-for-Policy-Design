%% FCN_CALC_GRASS
%  ==============
%
% Calculate grassland type hectares using Carlo's grassland model.
%
% INPUTS:
%
% grass_ha_cells
%   - hectares of grass in each cell
% data_cells (of previous years)
%   - table of all variables needed for grass models (excluding climate) 
%       in each cell
% climate_cells
%   - structure of rain and temperature variables in each cell
% coefficients
%   - structure containing coefficients for grass models
%
% OUTPUT:
%
% grass_info
%   - structure containing grassland type hectares, food production in each
%       cell

function grass_info = fcn_calc_grass(grass_ha_cells, data_cells, climate_cells, coefficients)

    %% Setup

    % No irrigation here?

    % Create derived climate variables needed for grassland models
    climate_cells.temp9 = (climate_cells.temp > 9) .* (climate_cells.temp - 9);
    climate_cells.temp10 = (climate_cells.temp > 10) .* (climate_cells.temp - 10);
    climate_cells.temp11 = (climate_cells.temp > 11) .* (climate_cells.temp - 11);
    climate_cells.temp12 = (climate_cells.temp > 12) .* (climate_cells.temp - 12);
    climate_cells.temp13 = (climate_cells.temp > 13) .* (climate_cells.temp - 13);
    climate_cells.temp14 = (climate_cells.temp > 14) .* (climate_cells.temp - 14);
    climate_cells.rain300 = (climate_cells.rain > 300) .* (climate_cells.rain - 300);
    climate_cells.rain350 = (climate_cells.rain > 350) .* (climate_cells.rain - 350);
    climate_cells.rain400 = (climate_cells.rain > 400) .* (climate_cells.rain - 400);
    climate_cells.rain500 = (climate_cells.rain > 500) .* (climate_cells.rain - 500);
    climate_cells.rain600 = (climate_cells.rain > 600) .* (climate_cells.rain - 600);
    climate_cells.raintemp = climate_cells.temp .* climate_cells.rain;

    % Set up model matrix for grassland models
    % NB: notice that soil variables are divided by 100 here!
    model_matrix = [data_cells.nprice_milk_ad data_cells.nprice_beef data_cells.nprice_sheep data_cells.avelev_cell data_cells.avelev200_cell data_cells.avslp_cell data_cells.pca_peat./100 climate_cells.temp climate_cells.temp9 climate_cells.temp10 climate_cells.temp11 climate_cells.temp12 climate_cells.temp13 climate_cells.temp14 climate_cells.rain climate_cells.rain300 climate_cells.rain350 climate_cells.rain400 climate_cells.rain500 climate_cells.rain600 climate_cells.raintemp data_cells.pca_med./100 data_cells.pca_fine./100 data_cells.pca_stony./100 data_cells.pca_gravelly./100 data_cells.pca_saline./100 data_cells.pca_fragipan./100 data_cells.adjsilt./100 data_cells.adjclay./100 data_cells.pca_npoct10 data_cells.pca_esa94 data_cells.pca_nvz09n data_cells.pca_ukgre12 data_cells.dist300 data_cells.trend_ls data_cells.wales data_cells.scotland data_cells.const];

    %% Model prediction
    % Multiply model matrix by coefficients to get grassland shares (defined on [0,100])
    pgrass_share = model_matrix * coefficients.pgrass;
    tgrass_share = model_matrix * coefficients.tgrass;

    % Carlo's "calibration" step, to improve performance on 2km cell level (rather than farm level)
    pgrass_share = pgrass_share + 5;
    tgrass_share = tgrass_share + 5;

    % Apply Censoring from below 0 and above 100
    pgrass_share(pgrass_share < 0) = 0;
    tgrass_share(tgrass_share < 0) = 0;
    pgrass_share(pgrass_share > 100) = 100;
    tgrass_share(tgrass_share > 100) = 100;

    % Rescale grassland and define rough grazing as what is leftover
    grass_share = pgrass_share + tgrass_share;
    pgrass_share(grass_share > 100) = 100*pgrass_share(grass_share > 100) ./ grass_share(grass_share > 100);
    tgrass_share(grass_share > 100) = 100*tgrass_share(grass_share > 100) ./ grass_share(grass_share > 100);
    rgraz_share = 100 - pgrass_share - tgrass_share;

    % Multiply by hectares of grassland to get hectares of grassland types
    grass_info.pgrass_ha = pgrass_share .* grass_ha_cells ./ 100;
    grass_info.tgrass_ha = tgrass_share .* grass_ha_cells ./ 100;
    grass_info.rgraz_ha = rgraz_share .* grass_ha_cells ./ 100;
    grass_info.rgraz_ha(grass_info.rgraz_ha < 0) = 0; % some values basically zero but negative

end