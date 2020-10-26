function [sr_table, stats_table, sr_cell] = biodiversity_metrics(species_prob_cell, taxa_cols, taxa_names)

    % Determine number of cells and species
    [ncells, nspecies] = size(species_prob_cell);
    
    % Determine number of taxonomic groups
    ntaxa = size(taxa_cols, 1);
    if (ntaxa ~= size(taxa_names, 1))
        error('Check taxa')
    end

    % Calculate total species richness in each cell
    % (round to nearest integer)
    total_species_richness_cell = round(sum(species_prob_cell, 2));

    %% Presence/absence in each cell
    species_presence_cell = zeros(ncells, nspecies);
    for i = 1:ncells
        [~, ind] = maxk(species_prob_cell(i,:), total_species_richness_cell(i));
        species_presence_cell(i, ind) = 1; 
    end

    %% Species richness in each cell, for each taxa
    sr_cell = zeros(ntaxa, ncells);
    for taxa = 1:ntaxa
        sr_cell(taxa, :) = sum(species_presence_cell(:, taxa_cols{taxa}), 2);
    end

    %% Species richness in the region, for each taxa

    % Presence in region
    species_presence_region = double(any(species_presence_cell, 1));
    
    sr_region = zeros(ntaxa, 1);
    for taxa = 1:ntaxa
        sr_region(taxa) = sum(species_presence_region(taxa_cols{taxa}));
    end

    %% Species richness summary statistics across cells in region

    % 0. minimum and maximum
    % ---------------------
    % Minimum
    min_sr = min(sr_cell, [], 2);

    % Maximum
    max_sr = max(sr_cell, [], 2);

    % i. Measure of location
    % ----------------------
    % Mean
    mean_sr = mean(sr_cell, 2);

    % Median
    median_sr = median(sr_cell, 2);
   
    % Mode
    % !!! - not great as usually returns smallest value
    mode_sr = mode(sr_cell, 2);

    % 1st quartile
    q1_sr = quantile(sr_cell, 0.25, 2);
    
    % 3rd quartile
    q3_sr = quantile(sr_cell, 0.75, 2);
    
    % ii. Measure of spread
    % ---------------------
    % Standard deviation
    std_sr = std(sr_cell, 0, 2);

    % Variance
    var_sr = var(sr_cell, 0, 2);

    % Range
    range_sr = range(sr_cell, 2);

    % Interquartile range
    iqr_sr = iqr(sr_cell, 2);

    % iii. Measure of shape

    % Skewness
    skewness_sr = skewness(sr_cell, 0, 2);

    % Kurtosis
    kurtosis_sr = kurtosis(sr_cell, 0, 2);

    %% Store results in table

    % Species richness in region
    sr_table = array2table(sr_region);
    sr_table.Properties.RowNames = taxa_names;
    sr_table.Properties.VariableNames = {'SpeciesRichness'};

    % Summary statistics of species richness across cells in region
    stats_table = array2table([min_sr, q1_sr, median_sr, q3_sr, max_sr, mean_sr, mode_sr, std_sr, var_sr, range_sr, iqr_sr, skewness_sr, kurtosis_sr]);
    stats_table.Properties.RowNames = taxa_names;
    stats_table.Properties.VariableNames = {'Min', 'Q1', 'Median', 'Q3', 'Max', 'Mean', 'Mode', 'Std', 'Var', 'Range', 'IQR', 'Skewness', 'Kurtosis'};

end