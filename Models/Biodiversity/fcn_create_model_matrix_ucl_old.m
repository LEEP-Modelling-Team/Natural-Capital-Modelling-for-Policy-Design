function model_matrix = fcn_create_model_matrix_ucl_old(data_cells, landuses, decade_string)
    % fcn_create_model_matrix_old.m
    % =============================
    % Author: Nathan Owen
    % Last modified: 18/09/2019
    % Function to take land uses for a decade and convert them into a model
    % matrix for use in predicting from the UCL biodiversity models.
    % Inputs:
    % - data_cells: a structure or table containing the fixed land uses (in
    %   hectares) and proportions for a set of 2km grid cells. See below 
    %   for the fixed land use types and how proportions are used. This is 
    %   stored in the Biodiversity structure when importing the data using 
    %   ImportBiodiversityUCL.m.
    % - landuses: a structure or table containing the land uses (in
    %   hectares) for a set of 2km grid cells and decade. See below for the
    %   land use types. These should come from a NEVO run (out structure) 
    %   or be pre-prepared.
    % - decade_string: a string to specify which decade land uses are for.
    %   Can be one of: '' (no decade, i.e. current land use), '_20' 
    %   (2020-2029 land use), '_30' (2030-2039 land use), '_40' 
    %   (2040-2049 land use), '_50' (2050-2059 land use). Relevant land 
    %   uses should have this subscript, e.g. wheat_ha_20. 
    % Outputs:
    % - model_matrix: a matrix containing the variables of the UCL
    %   biodiversity model for a set of 2km grid cells, i.e. the model
    %   matrix of the regression models.
    
    %% (0) Set up
    %  ==========
    % Set up intercept that is correct length
    % ---------------------------------------
    ncells = length(landuses.new2kid);
    intercept = ones(ncells,1);
    
    %% (1) Prepare land uses
    %  =====================
    % Fixed land uses in data_cells
    % -----------------------------
    coast_ha = data_cells.coast_ha;
    fwater_ha = data_cells.fwater_ha;
    marine_ha = data_cells.marine_ha;
    ocean_ha = data_cells.ocean_ha;
    
    % Fixed land uses in landuses
    % ---------------------------
    % In NEVO these may have been altered/optimised from baseline, but they
    % do not vary by decade
    urban_ha = landuses.urban_ha;
    sngrass_ha = landuses.sngrass_ha;
    
    % wood_ha is split into fwood_ha and nfwood_ha
    fwood_ha = data_cells.p_fwood .* landuses.wood_ha;
    nfwood_ha = (1 - data_cells.p_fwood) .* landuses.wood_ha;
    
    % Decade varying land uses in landuses
    % ------------------------------------
    pgrass_ha = eval(['landuses.pgrass_ha', decade_string]);
    tgrass_ha = eval(['landuses.tgrass_ha', decade_string]);
    rgraz_ha = eval(['landuses.rgraz_ha', decade_string]);
    wheat_ha = eval(['landuses.wheat_ha', decade_string]);
    wbar_ha = eval(['landuses.wbar_ha', decade_string]);
    sbar_ha = eval(['landuses.sbar_ha', decade_string]);
    pot_ha = eval(['landuses.pot_ha', decade_string]);
    sb_ha = eval(['landuses.sb_ha', decade_string]);
    
    % osr_ha is split into wosr_ha and sosr_ha
    wosr_ha = eval(['data_cells.p_wosr .* landuses.osr_ha', decade_string]);
    sosr_ha = eval(['data_cells.p_sosr .* landuses.osr_ha', decade_string]);
    
    % other_ha is split into other_ha, maize_ha, hort_ha, othfrm_ha & othcrps_ha
    othcer_ha = eval(['data_cells.p_othcer .* landuses.other_ha', decade_string]);
    maize_ha = eval(['data_cells.p_maize .* landuses.other_ha', decade_string]);
    hort_ha = eval(['data_cells.p_hort .* landuses.other_ha', decade_string]);
    othfrm_ha = eval(['data_cells.p_othfrm .* landuses.other_ha', decade_string]);
    othcrps_ha = eval(['data_cells.p_othcrps .* landuses.other_ha', decade_string]);

    % Masks for wbar, sbar, tbar, wosr, sosr, tosr
    % --------------------------------------------
    tbar_ha = wbar_ha + sbar_ha;
    tosr_ha = wosr_ha + sosr_ha;
    
    wbar_ha_masked = zeros(ncells,1);
    sbar_ha_masked = zeros(ncells,1);
    tbar_ha_masked = zeros(ncells,1);
    wosr_ha_masked = zeros(ncells,1);
    sosr_ha_masked = zeros(ncells,1);
    tosr_ha_masked = zeros(ncells,1);
    
    wbar_ha_masked(~data_cells.mask_tbarley) = wbar_ha(~data_cells.mask_tbarley);
    sbar_ha_masked(~data_cells.mask_tbarley) = sbar_ha(~data_cells.mask_tbarley);
    tbar_ha_masked(data_cells.mask_tbarley) = tbar_ha(data_cells.mask_tbarley);
    wosr_ha_masked(~data_cells.mask_tosr) = wosr_ha(~data_cells.mask_tosr);
    sosr_ha_masked(~data_cells.mask_tosr) = sosr_ha(~data_cells.mask_tosr);
    tosr_ha_masked(data_cells.mask_tosr) = tosr_ha(data_cells.mask_tosr);
    
    % Set up model matrix in correct order
    % ------------------------------------
    model_matrix_ha = [coast_ha, ...
                       fwater_ha, ...
                       marine_ha, ...
                       urban_ha, ...
                       pgrass_ha, ...
                       tgrass_ha, ...
                       rgraz_ha, ...
                       sngrass_ha, ...
                       fwood_ha, ...
                       nfwood_ha, ...
                       wheat_ha, ...
                       wbar_ha_masked, ...
                       sbar_ha_masked, ...
                       othcer_ha, ...
                       pot_ha, ...
                       wosr_ha_masked, ...
                       sosr_ha_masked, ...
                       maize_ha, ...
                       hort_ha, ...
                       tbar_ha_masked, ...
                       tosr_ha_masked, ...
                       othfrm_ha, ...
                       sb_ha, ...
                       othcrps_ha, ...
                       ocean_ha];
    
    % Apply transformation
    % --------------------
    % Convert to [0,1] scale then apply arcsine square root transformation
    model_matrix = asin(sqrt(model_matrix_ha ./ 400));
    
    % Add intercept
    % -------------
    model_matrix = [intercept, model_matrix];
end