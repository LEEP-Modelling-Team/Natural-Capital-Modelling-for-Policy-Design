% SetDataPaths
% Author: Frankie Cho
% Loads paths of NEV Model Data to the MATLAB environment

% Modify the parent_dir to location of Model Data in your workstation
function paths = fcn_set_data_paths()
    parent_dir                       = 'D:\Documents\Data\NEV\Model Data\';

    paths.agriculture_data_folder          = [parent_dir, 'Agriculture\'];
    paths.agricultureghg_data_folder       = [parent_dir, 'GHG\'];
    paths.climate_data_folder              = [parent_dir, 'Climate\'];
    paths.biodiversity_data_folder         = [parent_dir, 'Biodiversity\UCL\'];
    paths.biodiversity_data_folder_jncc    = [parent_dir, 'Biodiversity\JNCC\'];
    paths.flooding_data_folder             = [parent_dir, 'Flooding\'];
    paths.flooding_transfer_data_folder    = [parent_dir, 'Flooding Transfer\'];
    paths.forest_data_folder               = [parent_dir, 'Forestry\'];
    paths.forestghg_data_folder            = [parent_dir, 'GHG\'];
    paths.non_use_habitat_data_folder      = [parent_dir, 'NonUseHabitat\'];
    paths.non_use_pollination_data_folder  = [parent_dir, 'NonUsePollination\'];
    paths.non_use_wq_data_folder           = [parent_dir, 'NonUseWQ\'];
    paths.non_use_wq_transfer_data_folder  = [parent_dir, 'NonUseWQ Transfer\'];
    paths.pollination_data_folder          = [parent_dir, 'Pollination\'];
    paths.water_data_folder                = [parent_dir, 'Water\'];
    paths.water_transfer_data_folder       = [parent_dir, 'Water Transfer\'];
    paths.rec_data_folder                  = [parent_dir, 'Recreation\'];
end