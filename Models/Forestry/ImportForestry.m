clear 

server_flag = false;
conn = fcn_connect_database(server_flag);

MP.discount_rate = 0.035;
MP.num_years  = 40;   % Temporal run year length. Fixing this in the tool rather than allowing users to vary
MP.start_year = 2020; % Temporal start year.

forest_data_folder = 'C:\Data\Forestry\';
NEVO_ForestTimber_data_mat = strcat(forest_data_folder, 'NEVO_ForestTimber_data.mat');
forestghg_data_folder = 'C:\Data\GHG\';
NEVO_ForestGHG_data_mat = strcat(forestghg_data_folder, 'NEVO_ForestGHG_data.mat');

base_discount_rate  = 0.035;
forest_species_list = '''ss'', ''pok''';
tic
    ImportForestTimber
    ImportForestGHG
toc

save(NEVO_ForestTimber_data_mat, 'ForestTimber', 'es_forestry', '-mat', '-v6')
save(NEVO_ForestGHG_data_mat, 'ForestGHG', '-mat', '-v6')

clear forest_species_list base_discount_rate;
clear forest_data_folder forestghg_data_folder NEVO_ForestTimber_data_mat NEVO_ForestGHG_data_mat;

%clear ForestTimber ForestGHG es_forestry;

