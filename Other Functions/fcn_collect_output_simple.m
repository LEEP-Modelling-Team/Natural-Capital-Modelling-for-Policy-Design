function combined_lcs = fcn_collect_output_simple(high_level_lcs, es_agriculture)
	% fcn_collect_output_simple
	% =========================
	% Author: Nathan Owen
	% Last modified: 09/01/2020
	% Function to take five high level NEV land covers (wood, semi-natural, 
	% urban, water and farm) and output from NEV agriculture model, calculate
	% decadal averages (2020-2029, 2030-2039, 2040-2049, 2050-2059) and combine
	% data in a MATLAB table for output. Used to collect all land uses together 
	% for a run of another NEV model, e.g. biodiversity.
	% Inputs:
	% - high_level_lcs: a MATLAB structure/table with fields/columns for each of
	% 	five NEV high level land cover hectares for a set of 2km grid cells. 
	%	Should contain fields wood_ha, sngrass_ha, urban_ha, water_ha, farm_ha.
	%	Can be obtained from a database call to nevo.nevo_variables table.
	% - es_agriculture: a MATLAB structure obtained from running the NEV 
	%	agriculture model. Should contain multiple fields of agriculture output
	%	annually between 2020-2059 for set of 2km grid cells.
	% Output:
	% - combined_lcs: a MATLAB table containing the five NEV high level land
	% 	covers and output from the NEV agriculture model averaged in the decades
	%	2020-2029, 2030-2039, 2040-2049, 2050-2059. This table can be used to 
	%	run another NEV models, e.g. biodiversity.

    % Cell ids
    % --------
    combined_lcs.new2kid = high_level_lcs.new2kid;

    % Hectares of five high-level land uses + wood_mgmt_ha
    % ----------------------------------------------------
    combined_lcs.wood_ha    = high_level_lcs.wood_ha;
    combined_lcs.sngrass_ha = high_level_lcs.sngrass_ha;
    combined_lcs.urban_ha   = high_level_lcs.urban_ha;
    combined_lcs.water_ha   = high_level_lcs.water_ha;
    combined_lcs.farm_ha    = high_level_lcs.farm_ha;
    
    % Agriculture output averaged in decades
    % --------------------------------------
    % Hectares of arable land
    combined_lcs.arable_ha_20	= mean(es_agriculture.arable_ha(:, 1:10), 2);
    combined_lcs.arable_ha_30	= mean(es_agriculture.arable_ha(:, 11:20), 2);
    combined_lcs.arable_ha_40	= mean(es_agriculture.arable_ha(:, 21:30), 2);
    combined_lcs.arable_ha_50	= mean(es_agriculture.arable_ha(:, 31:40), 2);
    % Hectares of grassland
    combined_lcs.grass_ha_20    = mean(es_agriculture.grass_ha(:, 1:10), 2);
    combined_lcs.grass_ha_30	= mean(es_agriculture.grass_ha(:, 11:20), 2);
    combined_lcs.grass_ha_40	= mean(es_agriculture.grass_ha(:, 21:30), 2);
    combined_lcs.grass_ha_50	= mean(es_agriculture.grass_ha(:, 31:40), 2);
    % Hectares of crop types
    combined_lcs.wheat_ha_20	= mean(es_agriculture.wheat_ha(:, 1:10), 2);
    combined_lcs.wheat_ha_30	= mean(es_agriculture.wheat_ha(:, 11:20), 2);
    combined_lcs.wheat_ha_40	= mean(es_agriculture.wheat_ha(:, 21:30), 2);
    combined_lcs.wheat_ha_50	= mean(es_agriculture.wheat_ha(:, 31:40), 2);
    combined_lcs.osr_ha_20      = mean(es_agriculture.osr_ha(:, 1:10), 2);
    combined_lcs.osr_ha_30      = mean(es_agriculture.osr_ha(:, 11:20), 2);
    combined_lcs.osr_ha_40      = mean(es_agriculture.osr_ha(:, 21:30), 2);
    combined_lcs.osr_ha_50      = mean(es_agriculture.osr_ha(:, 31:40), 2);
    combined_lcs.wbar_ha_20     = mean(es_agriculture.wbar_ha(:, 1:10), 2);
    combined_lcs.wbar_ha_30     = mean(es_agriculture.wbar_ha(:, 11:20), 2);
    combined_lcs.wbar_ha_40     = mean(es_agriculture.wbar_ha(:, 21:30), 2);
    combined_lcs.wbar_ha_50     = mean(es_agriculture.wbar_ha(:, 31:40), 2);
    combined_lcs.sbar_ha_20     = mean(es_agriculture.sbar_ha(:, 1:10), 2);
    combined_lcs.sbar_ha_30     = mean(es_agriculture.sbar_ha(:, 11:20), 2);
    combined_lcs.sbar_ha_40     = mean(es_agriculture.sbar_ha(:, 21:30), 2);
    combined_lcs.sbar_ha_50     = mean(es_agriculture.sbar_ha(:, 31:40), 2);
    combined_lcs.pot_ha_20      = mean(es_agriculture.pot_ha(:, 1:10), 2);
    combined_lcs.pot_ha_30      = mean(es_agriculture.pot_ha(:, 11:20), 2);
    combined_lcs.pot_ha_40      = mean(es_agriculture.pot_ha(:, 21:30), 2);
    combined_lcs.pot_ha_50      = mean(es_agriculture.pot_ha(:, 31:40), 2);
    combined_lcs.sb_ha_20       = mean(es_agriculture.sb_ha(:, 1:10), 2);
    combined_lcs.sb_ha_30       = mean(es_agriculture.sb_ha(:, 11:20), 2);
    combined_lcs.sb_ha_40       = mean(es_agriculture.sb_ha(:, 21:30), 2);
    combined_lcs.sb_ha_50       = mean(es_agriculture.sb_ha(:, 31:40), 2);
    combined_lcs.other_ha_20    = mean(es_agriculture.other_ha(:, 1:10), 2);
    combined_lcs.other_ha_30	= mean(es_agriculture.other_ha(:, 11:20), 2);
    combined_lcs.other_ha_40	= mean(es_agriculture.other_ha(:, 21:30), 2);
    combined_lcs.other_ha_50	= mean(es_agriculture.other_ha(:, 31:40), 2);
    % Hectares of grassland types
    combined_lcs.pgrass_ha_20	= mean(es_agriculture.pgrass_ha(:, 1:10), 2);
    combined_lcs.pgrass_ha_30	= mean(es_agriculture.pgrass_ha(:, 11:20), 2);
    combined_lcs.pgrass_ha_40	= mean(es_agriculture.pgrass_ha(:, 21:30), 2);
    combined_lcs.pgrass_ha_50	= mean(es_agriculture.pgrass_ha(:, 31:40), 2);
    combined_lcs.tgrass_ha_20	= mean(es_agriculture.tgrass_ha(:, 1:10), 2);
    combined_lcs.tgrass_ha_30	= mean(es_agriculture.tgrass_ha(:, 11:20), 2);
    combined_lcs.tgrass_ha_40	= mean(es_agriculture.tgrass_ha(:, 21:30), 2);
    combined_lcs.tgrass_ha_50	= mean(es_agriculture.tgrass_ha(:, 31:40), 2);
    combined_lcs.rgraz_ha_20    = mean(es_agriculture.rgraz_ha(:, 1:10), 2);
    combined_lcs.rgraz_ha_30	= mean(es_agriculture.rgraz_ha(:, 11:20), 2);
    combined_lcs.rgraz_ha_40	= mean(es_agriculture.rgraz_ha(:, 21:30), 2);
    combined_lcs.rgraz_ha_50	= mean(es_agriculture.rgraz_ha(:, 31:40), 2);
    
    % Convert structure to table
    % --------------------------
    combined_lcs = struct2table(combined_lcs);
    
end