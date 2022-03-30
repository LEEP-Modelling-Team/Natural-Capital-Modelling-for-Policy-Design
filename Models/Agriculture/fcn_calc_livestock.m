%% FCN_CALC_LIVESTOCK
%  ==================
%
% Calculate heads of livestock and profit using Carlo's livestock model.
%
% INPUTS:
%
% grass_ha_cells
%   - hectares of grass in each cell
% data_cells (of previous year)
%   - table of all variables needed for livestock models (excluding climate) 
%       in each cell
% climate_cells (of previous year)
%   - structure of rain and temperature variables in each cell
% coefficients
%   - structure containing coefficients for livestock models
%
% OUTPUT:
%
% livestock_info
%   - structure containing heads of livestock and profit in each cell

function livestock_info = fcn_calc_livestock(grass_ha_cells, data_cells, climate_cells, coefficients, MP)

    %% Setup

    % Create derived climate variables needed for livestock models
    climate_cells.sqrain = climate_cells.rain.*climate_cells.rain;
    climate_cells.sqtemp = climate_cells.temp.*climate_cells.temp;
    climate_cells.raintemp = climate_cells.temp.*climate_cells.rain;

    % Set up model matrix for livestock models
    % NB: notice that soil variables are divided by 100 here!
    model_matrix = [data_cells.const climate_cells.rain climate_cells.temp climate_cells.sqrain climate_cells.sqtemp data_cells.avelev_cell data_cells.avelev200_cell data_cells.avslp_cell data_cells.sqavslp_cell data_cells.adjclay./100 data_cells.adjsilt./100 data_cells.pca_saline./100 data_cells.pca_fragipan./100 data_cells.pca_gravelly./100 data_cells.pca_stony./100 data_cells.pca_fine./100 data_cells.pca_med./100 data_cells.pca_peat./100 data_cells.pca_nvz09n data_cells.pca_esa94 data_cells.pca_ukgre12 data_cells.dist300 data_cells.pca_npoct10 data_cells.wales data_cells.scotland data_cells.trend_ls data_cells.bse data_cells.trend_bse data_cells.nprice_milk_ad data_cells.nprice_beef data_cells.nprice_sheep climate_cells.raintemp];

    %% Model prediction
    % Multiply model matrix by coefficients (and take exponential) to get density of livestock
    dairy_density = exp(model_matrix * coefficients.dairy);
    beef_density = exp(model_matrix * coefficients.beef);
    sheep_density = exp(model_matrix * coefficients.sheep);

    % Multiply density of livestock by grassland hectares to get heads of livestock
    livestock_info.dairy = dairy_density .* grass_ha_cells;
    livestock_info.beef = beef_density .* grass_ha_cells;
    livestock_info.sheep = sheep_density .* grass_ha_cells;

    % Total heads of livestock: beef + dairy + sheep
    livestock_info.livestock = livestock_info.beef + livestock_info.dairy + livestock_info.sheep;
    
    % Calculate individual livestock type gross margin (per head) using Carlo's new method
    dairy_fgm = 183 + 20 * data_cells.price_milk;
    if exist("MP", "var") && isfield(MP, "gm_beef") && isfield(MP, "gm_sheep")
        beef_fgm = 70 + MP.gm_beef; 
        sheep_fgm = 9 + MP.gm_sheep;
    else
        % Fallback to default values if the MP structure is not found, for
        % backward compatibility
        beef_fgm = 70;
        sheep_fgm = 9;
        warning("Beef & sheep gross margins not found in parameters struct. Falling back to default gross margins.");
    end
    
    % Calculate individual livestock profits
    livestock_info.dairy_profit = dairy_fgm .* livestock_info.dairy;
    livestock_info.beef_profit = beef_fgm .* livestock_info.beef;
    livestock_info.sheep_profit = sheep_fgm .* livestock_info.sheep;
    
    % Total livestock profit
    livestock_info.livestock_profit = livestock_info.dairy_profit + ...
                                      livestock_info.beef_profit + ...
                                      livestock_info.sheep_profit;

end