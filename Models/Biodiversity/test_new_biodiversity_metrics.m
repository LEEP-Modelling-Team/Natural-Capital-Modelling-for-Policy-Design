clc
clear

%% Inputs
ncells = 50;
nspecies = 100;

% Define some taxa
all_cols = 1:nspecies;
taxa1_cols = 1:10;
taxa2_cols = 11:nspecies;

taxa_cols = {all_cols; taxa1_cols; taxa2_cols};
taxa_names = {'all'; 'taxa1'; 'taxa2'};

%% Generate species probability in cell

% Baseline: random probabilities for each species
species_prob_cell_baseline = rand([ncells nspecies]);

% Scenario: reduce some species probabilities by half
species_prob_cell_scenario = species_prob_cell_baseline;
species_prob_cell_scenario(:,[1:5:100]) = 0.5*species_prob_cell_scenario(:,[1:5:100]);

%% Calculate biodiversity metrics

% Baseline
[sr_table_baseline, stats_table_baseline, sr_cell_baseline] = biodiversity_metrics(species_prob_cell_baseline, taxa_cols, taxa_names);

% Scenario
[sr_table_scenario, stats_table_scenario, sr_cell_scenario] = biodiversity_metrics(species_prob_cell_scenario, taxa_cols, taxa_names);

%% Display results

% Species richness in region
disp(sr_table_baseline)
disp(sr_table_scenario)

% Summary statistics of species richness across cells in region
disp(stats_table_baseline)
disp(stats_table_scenario)

histogram(sr_cell_baseline(3,:))
figure
histogram(sr_cell_scenario(3,:))

