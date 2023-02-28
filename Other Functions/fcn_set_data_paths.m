% SetDataPaths
% Author: Frankie Cho
% Loads paths of NEV Model Data to the MATLAB environment

% Modify the parent_dir to location of Model Data in your workstation
function paths = fcn_set_data_paths()
    
    parent_dir = 'D:\myGitHub\';
    defra_dir  = 'defra-elms\';
    nev_dir    = 'NEV\Model Data\';

    paths.data_out                         = [parent_dir, defra_dir, 'Data\'];
    paths.cplex_out                        = [parent_dir, defra_dir, 'Cplex\'];
    paths.NEV_code_folder                  = [parent_dir, 'NEV\'];
    paths.agriculture_data_folder          = [parent_dir, nev_dir, 'Agriculture\'];
    paths.agricultureghg_data_folder       = [parent_dir, nev_dir, 'GHG\'];
    paths.climate_data_folder              = [parent_dir, nev_dir, 'Climate\'];
    paths.biodiversity_data_folder         = [parent_dir, nev_dir, 'Biodiversity\UCL\'];
    paths.biodiversity_data_folder_jncc    = [parent_dir, nev_dir, 'Biodiversity\JNCC\'];
    paths.flooding_data_folder             = [parent_dir, nev_dir, 'Flooding\'];
    paths.flooding_transfer_data_folder    = [parent_dir, nev_dir, 'Flooding Transfer\'];
    paths.forest_data_folder               = [parent_dir, nev_dir, 'Forestry\'];
    paths.forestghg_data_folder            = [parent_dir, nev_dir, 'GHG\'];
    paths.non_use_habitat_data_folder      = [parent_dir, nev_dir, 'NonUseHabitat\'];
    paths.non_use_pollination_data_folder  = [parent_dir, nev_dir, 'NonUsePollination\'];
    paths.non_use_wq_data_folder           = [parent_dir, nev_dir, 'NonUseWQ\'];
    paths.non_use_wq_transfer_data_folder  = [parent_dir, nev_dir, 'NonUseWQ Transfer\'];
    paths.pollination_data_folder          = [parent_dir, nev_dir, 'Pollination\'];
    paths.water_data_folder                = [parent_dir, nev_dir, 'Water\'];
    paths.water_transfer_data_folder       = [parent_dir, nev_dir, 'Water Transfer\'];
    paths.rec_data_folder                  = [parent_dir, nev_dir, 'Recreation\'];
    paths.water_runs_folder                = [parent_dir, 'water-runs/MAT Files/'];    
end