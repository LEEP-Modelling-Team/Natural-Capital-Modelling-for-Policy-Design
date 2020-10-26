function Biodiversity = fcn_aggregate_biodiversity_metrics(es_biodiversity_jncc, index2, decade_string)

    % i. Species richness
    % First calculate if a species is present in any cell in index2
	species_presence_cell = es_biodiversity_jncc.(['species_presence', decade_string])(index2, :);
    species_presence_region = double(any(species_presence_cell, 1));
	
	% If all cells in region were NaN, need to set species_presence_region to NaN
	if sum(sum(isnan(species_presence_cell))) == numel(species_presence_cell)
		species_presence_region(:) = NaN;
	end

    % Now add up presences across taxonomic to get species
    % richness
    Biodiversity.(['sr_bird', decade_string]) = sum(species_presence_region(es_biodiversity_jncc.species_nos.bird));
    Biodiversity.(['sr_herp', decade_string]) = sum(species_presence_region(es_biodiversity_jncc.species_nos.herp));
    Biodiversity.(['sr_invert', decade_string]) = sum(species_presence_region(es_biodiversity_jncc.species_nos.invert));
    Biodiversity.(['sr_lichen', decade_string]) = sum(species_presence_region(es_biodiversity_jncc.species_nos.lichen));
    Biodiversity.(['sr_mammal', decade_string]) = sum(species_presence_region(es_biodiversity_jncc.species_nos.mammal));
    Biodiversity.(['sr_plant', decade_string]) = sum(species_presence_region(es_biodiversity_jncc.species_nos.plant));
    Biodiversity.(['sr_100', decade_string]) = sum(species_presence_region(es_biodiversity_jncc.species_nos.all));

%     % ii. Any species in taxa (density)
%     % Average of 'any' taxa metric across cells in index2
% 	% I.e. the proportion of cells in region which have any species from taxa present
%     Biodiversity.(['any_bird', decade_string]) = nanmean(es_biodiversity_jncc.(['any_bird', decade_string])(index2));
%     Biodiversity.(['any_herp', decade_string]) = nanmean(es_biodiversity_jncc.(['any_herp', decade_string])(index2));
%     Biodiversity.(['any_invert', decade_string]) = nanmean(es_biodiversity_jncc.(['any_invert', decade_string])(index2));
%     Biodiversity.(['any_lichen', decade_string]) = nanmean(es_biodiversity_jncc.(['any_lichen', decade_string])(index2));
%     Biodiversity.(['any_mammal', decade_string]) = nanmean(es_biodiversity_jncc.(['any_mammal', decade_string])(index2));
%     Biodiversity.(['any_plant', decade_string]) = nanmean(es_biodiversity_jncc.(['any_plant', decade_string])(index2));
%     Biodiversity.(['any_100', decade_string]) = nanmean(es_biodiversity_jncc.(['any_100', decade_string])(index2));
% 	
% 	% iii. Species density
% 	% Defined as: (total presences of species in taxa across all cells) / (number of species in taxa x number of cells)
% 	% Species density = 1: all species from taxa are present in all cells
% 	% Species density = 0: no species from taxa are present in any cell
% 	Biodiversity.(['sd_bird', decade_string]) = nanmean(reshape(species_presence_cell(:, es_biodiversity_jncc.species_nos.bird), [], 1));
% 	Biodiversity.(['sd_herp', decade_string]) = nanmean(reshape(species_presence_cell(:, es_biodiversity_jncc.species_nos.herp), [], 1));
% 	Biodiversity.(['sd_invert', decade_string]) = nanmean(reshape(species_presence_cell(:, es_biodiversity_jncc.species_nos.invert), [], 1));
% 	Biodiversity.(['sd_lichen', decade_string]) = nanmean(reshape(species_presence_cell(:, es_biodiversity_jncc.species_nos.lichen), [], 1));
% 	Biodiversity.(['sd_mammal', decade_string]) = nanmean(reshape(species_presence_cell(:, es_biodiversity_jncc.species_nos.mammal), [], 1));
% 	Biodiversity.(['sd_plant', decade_string]) = nanmean(reshape(species_presence_cell(:, es_biodiversity_jncc.species_nos.plant), [], 1));
% 	Biodiversity.(['sd_100', decade_string]) = nanmean(reshape(species_presence_cell(:, es_biodiversity_jncc.species_nos.all), [], 1));

end