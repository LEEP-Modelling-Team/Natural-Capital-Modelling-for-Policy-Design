function es_biodiversity_jncc = fcn_run_biodiversity_jncc(biodiversity_data_folder, PV, out)

    %% (1) INITIALISE
    %  ==============
    
    % a. Constants
    % ------------
    ndecades = 4;
    decade_string = {'_20','_30','_40','_50'};
    
    % Save species numbers for taxonomic groups
    % (need for fcn_aggregate_to_region later)
    es_biodiversity_jncc.species_nos.all = 1:100;
    es_biodiversity_jncc.species_nos.bird = [1, 3, 8, 16, 19, 33, 34, 56, 58, 64, 66, 70, 76, 77, 89, 94, 97];
    es_biodiversity_jncc.species_nos.herp = 98;
    es_biodiversity_jncc.species_nos.invert = [2, 4, 14, 15, 24, 26, 27, 28, 29, 30, 32, 35, 37, 43, 45, 48, 50, 54, 55, 57, 61, 63, 85, 99, 100];
    es_biodiversity_jncc.species_nos.lichen = [5, 49, 75, 79, 95];
    es_biodiversity_jncc.species_nos.mammal = [12, 38, 51, 52, 60, 62, 65, 67, 68, 71, 78, 83, 84, 87];
    es_biodiversity_jncc.species_nos.plant = [6, 7, 9, 10, 11, 13, 17, 18, 20, 21, 22, 23, 25, 31, 36, 39, 40, 41, 42, 44, 46, 47, 53, 59, 69, 72, 73, 74, 80, 81, 82, 86, 88, 90, 91, 92, 93, 96];
    
    % b. Data files 
    % -------------
    NEVO_Biodiversity_data_mat = strcat(biodiversity_data_folder, 'NEVO_Biodiversity_data.mat');
    
    % c. NEVO mats from ImportBiodiversityJNCC
    % ----------------------------------------
    load(NEVO_Biodiversity_data_mat);
    
    %% (2) DATA FOR NEVO INPUT CELLS
    %  =============================
    % Extract NEVO Input Cells for relevant tables and arrays in
    % Biodiversity structure
    
    [input_cells_ind, input_cell_idx] = ismember(PV.new2kid, Biodiversity.new2kid);
    input_cell_idx                    = input_cell_idx(input_cells_ind);
        
    Biodiversity.Data_cells = Biodiversity.Data_cells(input_cell_idx,:);
    Biodiversity.Climate_cells = Biodiversity.Climate_cells(input_cell_idx,:);
    
    %% (3) CALCULATE BIODIVERSITY ES
    %  =============================
      
    for decade = 1:ndecades
        
        % a. Create model matrix for this decade
        % --------------------------------------
        model_matrix = fcn_create_model_matrix_jncc(Biodiversity.Data_cells, Biodiversity.Climate_cells, PV, out, decade_string{decade});
        
        % b. Model prediction
        % -------------------
        % Multiply model matrix by coefficients to get logit of probability
        % of occurrence for the 100 species
        species_prob_logit = model_matrix * Biodiversity.Coefficients;
        
        % Apply logistic transformation to get probability of occurrence
        % for the 100 species
        species_prob = 1 ./ (1 + exp(-species_prob_logit));
        
        % Add to output structure as species_prob with decade
        es_biodiversity_jncc.(['species_prob', decade_string{decade}]) = species_prob;
        
        % c. Convert probability to species presence/absence
        % --------------------------------------------------
        
        % Calculate total number of species in each cell
        total_species_richness = round(sum(species_prob, 2));
        
        % Preallocate matrix to store results
        species_presence = zeros(size(species_prob));
        
        % Loop over cells
        for i = 1:size(species_prob, 1)
            if (isnan(total_species_richness(i)))
                % If NaN then skip this cell
                continue
            else
                % Else, set top total_species_richness(i) species to 1 and
                % 0 otherwise in this cell
                
                %[~, ind] = maxk(species_prob(i,:), total_species_richness(i));
                % Fix for Matlab R2017a which does not have maxk
                [~, sortIndex] = sort(species_prob(i,:), 'descend');  % Sort the values in descending order
                ind = sortIndex(1:total_species_richness(i));         % Get index of the largest values
                
                species_presence(i, ind) = 1;
            end
        end
        
        % Fill in NaNs
        species_presence(isnan(species_prob)) = NaN;
        
        % Add to output structure as 'species_presence' with decade
        es_biodiversity_jncc.(['species_presence', decade_string{decade}]) = species_presence;
        
        % d. Calculate metrics for taxonomic groups
        % -----------------------------------------
        % (birds, herptiles, invertebrates, lichen, mammals, vascular plants, all 100)
        
        % i. Species richness: number of species present in different
        % taxonomic groups
        sr_bird = sum(species_presence(:, es_biodiversity_jncc.species_nos.bird), 2);
        sr_herp = sum(species_presence(:, es_biodiversity_jncc.species_nos.herp), 2);
        sr_invert = sum(species_presence(:, es_biodiversity_jncc.species_nos.invert), 2);
        sr_lichen = sum(species_presence(:, es_biodiversity_jncc.species_nos.lichen), 2);
        sr_mammal = sum(species_presence(:, es_biodiversity_jncc.species_nos.mammal), 2);
        sr_plant = sum(species_presence(:, es_biodiversity_jncc.species_nos.plant), 2);
        sr_100 = sum(species_presence(:, es_biodiversity_jncc.species_nos.all), 2);
        
        % Add to output structure as 'sr_taxa' with decade
        es_biodiversity_jncc.(['sr_bird', decade_string{decade}]) = sr_bird;
        es_biodiversity_jncc.(['sr_herp', decade_string{decade}]) = sr_herp;
        es_biodiversity_jncc.(['sr_invert', decade_string{decade}]) = sr_invert;
        es_biodiversity_jncc.(['sr_lichen', decade_string{decade}]) = sr_lichen;
        es_biodiversity_jncc.(['sr_mammal', decade_string{decade}]) = sr_mammal;
        es_biodiversity_jncc.(['sr_plant', decade_string{decade}]) = sr_plant;
        es_biodiversity_jncc.(['sr_100', decade_string{decade}]) = sr_100;
        
%         % ii. Any species from taxa: whether any species is present in a taxonomic
%         % group (1 = any species present, 0 = no species present)
%         % Calculate by taking positive species richness
%         % (makes more sense for a region - see fcn_aggregate_to_region)
%         any_bird = double(sr_bird > 0);
%         any_herp = double(sr_herp > 0);
%         any_invert = double(sr_invert > 0);
%         any_lichen = double(sr_lichen > 0);
%         any_mammal = double(sr_mammal > 0);
%         any_plant = double(sr_plant > 0);
%         any_100 = double(sr_100 > 0);
%         
%         % Fill in nan
%         any_bird(isnan(sr_bird)) = NaN;
%         any_herp(isnan(sr_herp)) = NaN;
%         any_invert(isnan(sr_invert)) = NaN;
%         any_lichen(isnan(sr_lichen)) = NaN;
%         any_mammal(isnan(sr_mammal)) = NaN;
%         any_plant(isnan(sr_plant)) = NaN;
%         any_100(isnan(sr_100)) = NaN;
%         
%         
%         % Add to output structure as 'any_taxa' with decade
%         es_biodiversity_jncc.(['any_bird', decade_string{decade}]) = any_bird;
%         es_biodiversity_jncc.(['any_herp', decade_string{decade}]) = any_herp;
%         es_biodiversity_jncc.(['any_invert', decade_string{decade}]) = any_invert;
%         es_biodiversity_jncc.(['any_lichen', decade_string{decade}]) = any_lichen;
%         es_biodiversity_jncc.(['any_mammal', decade_string{decade}]) = any_mammal;
%         es_biodiversity_jncc.(['any_plant', decade_string{decade}]) = any_plant;
%         es_biodiversity_jncc.(['any_100', decade_string{decade}]) = any_100;
% 		
% 		% iii. Species density: 
% 		% Defined as: (total presences of species in taxa across all cells) / (number of species in taxa x number of cells)
% 		% Here number of cells = 1, reduces to: species richness for taxa / number of species in taxa
% 		% (makes more sense for a region - see fcn_aggregate_to_region)
% 		sd_bird = nanmean(species_presence(:, es_biodiversity_jncc.species_nos.bird), 2);
%         sd_herp = nanmean(species_presence(:, es_biodiversity_jncc.species_nos.herp), 2);
%         sd_invert = nanmean(species_presence(:, es_biodiversity_jncc.species_nos.invert), 2);
%         sd_lichen = nanmean(species_presence(:, es_biodiversity_jncc.species_nos.lichen), 2);
%         sd_mammal = nanmean(species_presence(:, es_biodiversity_jncc.species_nos.mammal), 2);
%         sd_plant = nanmean(species_presence(:, es_biodiversity_jncc.species_nos.plant), 2);
%         sd_100 = nanmean(species_presence(:, es_biodiversity_jncc.species_nos.all), 2);
% 		
% 		% Add to output structure as 'sd_taxa' with decade
%         es_biodiversity_jncc.(['sd_bird', decade_string{decade}]) = sd_bird;
%         es_biodiversity_jncc.(['sd_herp', decade_string{decade}]) = sd_herp;
%         es_biodiversity_jncc.(['sd_invert', decade_string{decade}]) = sd_invert;
%         es_biodiversity_jncc.(['sd_lichen', decade_string{decade}]) = sd_lichen;
%         es_biodiversity_jncc.(['sd_mammal', decade_string{decade}]) = sd_mammal;
%         es_biodiversity_jncc.(['sd_plant', decade_string{decade}]) = sd_plant;
%         es_biodiversity_jncc.(['sd_100', decade_string{decade}]) = sd_100;

    end
    
end

