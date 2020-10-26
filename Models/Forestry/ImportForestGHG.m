%% IMPORTGHGFOREST
%  ===============

%  Imports data on carbon sequestration from forest planting and timber
%  harvesting calculated by the FC's Carbine model for different yield
%  classes (yc) of different species.
%
%  Carbine Data: Timber
%  --------------------
%  Yearly carbon in tree, deadwood and products for 743 years from year of
%  planting with no prepartion year.
%  
%  Carbine Data: Soil
%  --------------------
%  Yearly carbon when planting on sand, loam, clay or organic soil that
%  was previously arable (distrubed) or non-arable (non-disturbed) for 743
%  years with first year's data a preparation year before planting in
%  second year.
%  
%  Script takes Carbine data and creates structure ForestGHG.FCE for timber
%  carbon and ForestGHG for soil carbon with sequestration data for each
%  species and yield class for a period equal to twice the rotation period
%  for that specie-yc.
%
%  Soil Data: Cells
%  ----------------
%  Cell data on soil types proporions in each cell aggregated to Sand,
%  Loam, Clay and Organic and current arable, non-arable & woodland split
        

%% (1) LOAD DATA FROM DATABASE
%  ===========================

% (a) Forest Timber Carbon
% ------------------------
sqlquery    = 'SELECT * FROM nevo.ghg_forest_carbon_ext ORDER BY species, yield_class, year';
setdbprefs('DataReturnFormat','table');
dataReturn  = fetch(exec(conn,sqlquery));
fc_timber = dataReturn.Data;

% (b) Forest Soil Carbon
% ----------------------
sqlquery    = 'SELECT * FROM nevo.ghg_forest_carbon ORDER BY species, yield_class, year';
setdbprefs('DataReturnFormat','table');
dataReturn  = fetch(exec(conn,sqlquery));
fc_soil  = dataReturn.Data;

% List of soil types for soil carbon data
Carbine_soil_cols = {'non_arable_sand','non_arable_loam','non_arable_clay','non_arable_organic','arable_sand','arable_loam','arable_clay','arable_organic'};

% (c) Soil Types and 2020 Landuses by Cells
% -----------------------------------------
% Carbine identifies four soil types Sand, Loam, Clay & Organic. The cell 
% soil data categories soil by Texture (Sand, Loam & Clay) and separately
% by Organic with the highest organic soils being those in category OC6.
% In Database call, the texture variables are aggregated as follows:
%    Sand = pca_sand + pca_l_sand 
%    Loam = pca_s_loam + pca_clay_loam + pca_loam 
%    Clay = pca_clay
% expressed as percentages (not proportions) of soil area in cell
% Percentage of those same soils which are high organic is:
%    Org  = pca_OC6
% 
% Carbine differentiates between disturbed soils (arable) and those that 
% are long-term undisturbed (non_arable). Those categories are calculated 
% from NEVO 2020 base run of the model as follows:
%    Arable        = Crops + Temporary Grassland
%    Non-Arable    = Permanent Grassland + Rough Grazing + Semi-Natural Grassland 
% Also keep wood so can see if any change in woodland cover

% sqlquery    = ['SELECT tbl1.new2kid, pca_sand + pca_l_sand AS sand, pca_s_loam + pca_clay_loam + pca_loam AS loam, pca_clay AS clay, pca_OC6 AS org, ' ...
%                '       tbl2.wood_ha AS wood_ha, tbl2.arable_ha_20::real + tbl2.tgrass_ha_20::real AS arable_ha_20, tbl2.sngrass_ha::real + tbl2.rgraz_ha_20::real + tbl2.pgrass_ha_20::real AS non_arable_ha_20 ' ...
%                'FROM nevo.nevo_variables AS tbl1 ' ...
%                '   INNER JOIN nevo_explore.explore_2km AS tbl2 ON tbl1.new2kid = tbl2.new2kid ' ...
%                'ORDER BY new2kid'];
% setdbprefs('DataReturnFormat','table');
% dataReturn  = fetch(exec(conn,sqlquery));
% soil_cells = dataReturn.Data;

sqlquery    = ['SELECT new2kid, pca_sand + pca_l_sand AS sand, pca_s_loam + pca_clay_loam + pca_loam AS loam, pca_clay AS clay, pca_OC6 AS org ' ...
               'FROM nevo.nevo_variables ORDER BY new2kid'];
setdbprefs('DataReturnFormat','table');
dataReturn  = fetch(exec(conn,sqlquery));
soil_cells = dataReturn.Data;

% Save order of new2kid cells used in Forest GHG calculations
ForestGHG.new2kid = soil_cells.new2kid;

% Need to reduce YC prediction_cell & RotPeriod_cell in es_forestry to these cells
es_forestry.new2kid = ForestGHG.new2kid;
[input_cells_ind, input_cell_idx] = ismember(es_forestry.new2kid, ForestTimber.new2kid);
input_cell_idx                    = input_cell_idx(input_cells_ind);
es_forestry.YC_prediction_cell.PedunculateOak = es_forestry.YC_prediction_cell.PedunculateOak(input_cell_idx,:);
es_forestry.YC_prediction_cell.SitkaSpruce = es_forestry.YC_prediction_cell.SitkaSpruce(input_cell_idx,:);
es_forestry.RotPeriod_cell.PedunculateOak = es_forestry.RotPeriod_cell.PedunculateOak(input_cell_idx);
es_forestry.RotPeriod_cell.SitkaSpruce = es_forestry.RotPeriod_cell.SitkaSpruce(input_cell_idx);

% Save order of new2kid cells used in Forest GHG calculations
%ForestGHG.landuse_base_cells = [soil_cells.wood_ha soil_cells.arable_ha_20 soil_cells.non_arable_ha_20];


%% (2) CELL SOIL TYPES: CALCULATE PROPORTIONS OF 4 CARBINE CATEGORIES IN EACH CELL
% --------------------------------------------------------------------------------

% !!!! SOIL DATA COULD DO WITH CHECKING ... NOT ALL PERCENTS ADD TO 100 !!!

% Where organic also classifed as clay or loam set these to 0
soil_cells.clay(soil_cells.clay == soil_cells.org) = 0;
soil_cells.loam(soil_cells.loam == soil_cells.org) = 0;
   
% SAND LOAM CLAY should be 100% of soil in cell
SLC = [soil_cells.sand soil_cells.loam soil_cells.clay];   
SLC(sum(SLC,2)>0,:) = SLC(sum(SLC,2)>0,:)./ sum(SLC(sum(SLC,2)>0,:),2);   

% Scale down SLC to be soils other than organic
org = soil_cells.org/100;
SLC = SLC.*(1 - org);

% Store soil cell proportions in order Sand, Loam, Clay, Organic
ForestGHG.SoilC_cells = [SLC org];

% Fix where no soil texture data whatsoever
NoSoilData_ind = (sum(ForestGHG.SoilC_cells,2) == 0);
NoSoilData_idx = find(NoSoilData_ind);
% ... loop through till find next cell with soil data
for i = 1:length(NoSoilData_idx)
    j = NoSoilData_idx(i);    
    while (NoSoilData_ind(j)==1)
        j = j + 1;
    end   
    ForestGHG.SoilC_cells(NoSoilData_idx(i),:) = ForestGHG.SoilC_cells(j,:);
end

% Fix since appears that when clay = org or loam = org can get less than 100% 
ForestGHG.SoilC_cells = ForestGHG.SoilC_cells./sum(ForestGHG.SoilC_cells,2);

nCells = length(ForestGHG.SoilC_cells);

clear soil_cells SLC SLCmean org NoSoilData_ind NoSoilData_idx i j;



%% (3) ROTATION CARBON: WORK THROUGH CARBINE DATA BY SPECIES AND YC
% -----------------------------------------------------------------

% Working vectors for calculation of value annuities under base discount rate
delta_rbase = 1/(1+base_discount_rate);


for i = 1:height(ForestTimber.SpeciesCode)
    
    species   = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.species(i)));
    spec_code = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.code(i)));

    
    % (a) Forest Timber Carbon: Data
    % ------------------------------
    % Data from Carbine provides 742 time series of timber carbon per ha 
    % from one rotation. Each year measues of tree, deadwood and product
    % carbon sequestration and emissions are listed.
    
    % Extract data for this species
    timberC_spec = fc_timber(string(fc_timber.species)==string(species),:);

    % Check all base years are 2013
    % baseyears = grpstats(timberC_spec,'yield_class','min','DataVars',{'year'});
    timberC_spec.year = timberC_spec.year - 2012;

    % Aggregate timber carbon data into sparse matrix: yr rows, yc cols 
    timberC_spec = sparse(timberC_spec.year,timberC_spec.yield_class,(timberC_spec.tree + timberC_spec.deadwood + timberC_spec.products)); 

    % Initialise Timber Carbon Output Matrices:
    % -----------------------------------------
    % Time Series: (restrict to 2x longest rotation for this species)
    ForestGHG.TimberC_TSer.(species)   = timberC_spec(1:2*ForestTimber.RotPeriod_max.(species),:);
    
    % Quantity:
    ForestGHG.TimberC_QntYr.(species)  = zeros(max(ForestTimber.Carbine_ycs.(species)),1);
    ForestGHG.TimberC_QntYr20.(species)  = zeros(max(ForestTimber.Carbine_ycs.(species)),1);
    ForestGHG.TimberC_QntYr30.(species)  = zeros(max(ForestTimber.Carbine_ycs.(species)),1);
    ForestGHG.TimberC_QntYr40.(species)  = zeros(max(ForestTimber.Carbine_ycs.(species)),1);
    ForestGHG.TimberC_QntYr50.(species)  = zeros(max(ForestTimber.Carbine_ycs.(species)),1);
    
    % Value: (base discount rate)
    ForestGHG.TimberC_ValAnn.(species) = zeros(max(ForestTimber.Carbine_ycs.(species)),1);

    % (b) Forest Soil Carbon: Data
    % ----------------------------
    % Data from Carbine provides 742 time series of timber carbon per ha 
    % from one rotation. Each year provides data on carbon sequestration 
    % and emissions for 8 different landuse-soil types. Unlike timber these
    % must be kept separate as a matrix of soil carbon time series for each
    % soil type for each yc in a series.
    %   Soil Carbon Q/yr: Can be calculated in advance from this matrix  
    %                     given current soils in each cell 
    %   Soil Carbon £/yr: Annuity calcualtion requires discount rate that 
    %                     can change in NEVO. Due to dimensionality problem
    %                     of storing N x Yrs time series of cells specific
    %                     soil carbon better to store this matrix for
    %                     calculation in NEVO
    
    % Extract data for this species
    soilC_spec = fc_soil(string(fc_soil.species)==string(species),:);

    % Check all base years are 2013
    % baseyears = grpstats(timberC_spec,'yield_class','min','DataVars',{'year'});
    soilC_spec.year = soilC_spec.year - 2012 - 1; % year 0 is preparation year   
    
    % Initialise Forest Carbon Output Matrices:
    % -----------------------------------------    
    % Time Series: cell array as need matrix for soil types for each yc
    ForestGHG.SoilC_TSer.(species)   = cell(1,ForestTimber.Carbine_ycs_max.(species));
    % Quantity:
    SoilC_QntYr = zeros(8,1);
    SoilC_QntYr20 = zeros(8,1);
    SoilC_QntYr30 = zeros(8,1);
    SoilC_QntYr40 = zeros(8,1);
    SoilC_QntYr50 = zeros(8,1);
    
    SoilC_narable_QntYr_cell = [];
    SoilC_arable_QntYr_cell  = [];
    SoilC_narable_QntYr20_cell = [];
    SoilC_arable_QntYr20_cell  = [];
    SoilC_narable_QntYr30_cell = [];
    SoilC_arable_QntYr30_cell  = [];
    SoilC_narable_QntYr40_cell = [];
    SoilC_arable_QntYr40_cell  = [];
    SoilC_narable_QntYr50_cell = [];
    SoilC_arable_QntYr50_cell  = [];
    
    colidx = ones(nCells,1);   
    rowidx = (1:nCells)';
    
    % Value: (base discount rate)
    ForestGHG.SoilC_ValAnn.(species) = zeros(8,max(ForestTimber.Carbine_ycs.(species)));
       
    % Working vectors for Annualisation calculations
    % ----------------------------------------------
    delta_rbase_rot = delta_rbase.^(0:2*ForestTimber.RotPeriod_max.(species)-1);
    gamma_rbase_rot = base_discount_rate./(1-(1+base_discount_rate).^-(ForestTimber.RotPeriod.(species)-1));    
    
    
    % Loop through each Carbine YC for this Species
    % ---------------------------------------------
    for j = 1:length(ForestTimber.Carbine_ycs.(species))

        yc   = ForestTimber.Carbine_ycs.(species)(j);
        rotp = ForestTimber.RotPeriod.(species)(yc);
               
        % (i) Timber Carbon: Time Series
        % ------------------------------
        % Restrict Carbon time series data to 2 x rotation for this yc
        ForestGHG.TimberC_TSer.(species)(rotp*2:end,yc) = 0;

        % (ii) Timber Carbon: Value (base discount rate)
        % ----------------------------------------------
        % Calculate annuity per ha for this yc using baseline discount rate
        % r = 3.5% and store for use when NEVO ALTER/OPTIMISE uses base
        % rate. Otherwise these calculations must be done by NEVO.
        timberC_npv = (delta_rbase_rot*ForestGHG.TimberC_TSer.(species)(:,yc))';
        ForestGHG.TimberC_ValAnn.(species)(yc) = timberC_npv.*gamma_rbase_rot(yc);
              
        % (iii) Timber Carbon: Quantity
        % -----------------------------
        % Calculate permanent Carbon equivalent from 2 x rotation for the carbon 
        % time series for each yc then average over ONE rotation period
        %    NOTE: Assumes that the timber Carbon of subsequent plantings
        %    has an identical 2 period pattern that overlaps by one rotation
        %    period
        ForestGHG.TimberC_QntYr.(species)(yc) = fcn_Cperm_equiv(ForestGHG.TimberC_TSer.(species)(:,yc))/rotp;
        ForestGHG.TimberC_QntYr20.(species)(yc) = fcn_Cperm_equiv(ForestGHG.TimberC_TSer.(species)(1:10,yc))/10;
        ForestGHG.TimberC_QntYr30.(species)(yc) = fcn_Cperm_equiv(ForestGHG.TimberC_TSer.(species)(11:20,yc))/10;
        ForestGHG.TimberC_QntYr40.(species)(yc) = fcn_Cperm_equiv(ForestGHG.TimberC_TSer.(species)(21:30,yc))/10;
        ForestGHG.TimberC_QntYr50.(species)(yc) = fcn_Cperm_equiv(ForestGHG.TimberC_TSer.(species)(31:40,yc))/10;
        

        % (iv) Soil Carbon: Time Series by Soil Type
        % ------------------------------------------
        % Extract Soil C data series time series for 8 x Soil Types
        soilC_spec_yc      = table2array(soilC_spec(soilC_spec.yield_class == yc,Carbine_soil_cols));
        % In Carbine data 1st year is preparation year & 2nd year is planting. In TIM these are added to have prep & plant in 1st year
        soilC_spec_yc(2,:) = soilC_spec_yc(1,:) + soilC_spec_yc(2,:);
        soilC_spec_yc      = soilC_spec_yc(2:end,:);
        
        % Soil Carbon time series for this yc in a matrix by soil type (2x rotp)
        ForestGHG.SoilC_TSer.(species){yc} = soilC_spec_yc(1:(rotp*2),:);

        % (v) Soil Carbon: Value (base discount rate)
        % -------------------------------------------
        % Calculate annuity per ha for this yc using baseline discount rate
        % r = 3.5% and store for use when NEVO ALTER/OPTIMISE uses base
        % rate. Otherwise these calculations must be done by NEVO.
        soilC_npv = (delta_rbase_rot(1:rotp*2)*ForestGHG.SoilC_TSer.(species){yc})';
        ForestGHG.SoilC_ValAnn.(species)(:,yc) = soilC_npv*gamma_rbase_rot(yc);
        
        % (vi) Soil Carbon: Quantity
        % --------------------------
        % Calculate permanent Carbon equivalent from 2 x rotation for the carbon 
        % time series for eachsoil type for this yc then average OVER one rotation period
        %    NOTE: The assumption that soil carbon pattern repeats itself over
        %    successive rotations (as per timber carbon) is not a particularly 
        %    good one since this is emissions from one-off planting on non-wooded land)        
        for stype = 1:8
            SoilC_QntYr(stype) = fcn_Cperm_equiv(ForestGHG.SoilC_TSer.(species){yc}(:,stype))/rotp;
            SoilC_QntYr20(stype) = fcn_Cperm_equiv(ForestGHG.SoilC_TSer.(species){yc}(1:10,stype))/10;
            SoilC_QntYr30(stype) = fcn_Cperm_equiv(ForestGHG.SoilC_TSer.(species){yc}(11:20,stype))/10;
            SoilC_QntYr40(stype) = fcn_Cperm_equiv(ForestGHG.SoilC_TSer.(species){yc}(21:30,stype))/10;
            SoilC_QntYr50(stype) = fcn_Cperm_equiv(ForestGHG.SoilC_TSer.(species){yc}(31:40,stype))/10;
        end
                     
        % annuity for soil mix in each cell (for this yc when displacing arable and non-arable)
        % (first 4 cols of SoilC_TSer are for non-arable last 4 cols are for arable both in order SLCO)
        SoilC_narable_QntYr_cell = [SoilC_narable_QntYr_cell; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_QntYr(1:4)]];
        SoilC_arable_QntYr_cell  = [SoilC_arable_QntYr_cell;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_QntYr(5:8)]];
        SoilC_narable_QntYr20_cell = [SoilC_narable_QntYr20_cell; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_QntYr20(1:4)]];
        SoilC_arable_QntYr20_cell  = [SoilC_arable_QntYr20_cell;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_QntYr20(5:8)]];
        SoilC_narable_QntYr30_cell = [SoilC_narable_QntYr30_cell; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_QntYr30(1:4)]];
        SoilC_arable_QntYr30_cell  = [SoilC_arable_QntYr30_cell;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_QntYr30(5:8)]];
        SoilC_narable_QntYr40_cell = [SoilC_narable_QntYr40_cell; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_QntYr40(1:4)]];
        SoilC_arable_QntYr40_cell  = [SoilC_arable_QntYr40_cell;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_QntYr40(5:8)]];
        SoilC_narable_QntYr50_cell = [SoilC_narable_QntYr50_cell; [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_QntYr50(1:4)]];
        SoilC_arable_QntYr50_cell  = [SoilC_arable_QntYr50_cell;  [rowidx  colidx*yc  ForestGHG.SoilC_cells * SoilC_QntYr50(5:8)]];
       
    end
    
    % (vi) Soil Carbon: Quantity (CONTINUED)
    % --------------------------------------
    
    % [N x yc] matrices of npvs for each yc for the particular soil combination in each cell
    SoilC_narable_QntYr_cell = sparse(SoilC_narable_QntYr_cell(:,1),SoilC_narable_QntYr_cell(:,2),SoilC_narable_QntYr_cell(:,3));
    SoilC_arable_QntYr_cell  = sparse(SoilC_arable_QntYr_cell(:,1), SoilC_arable_QntYr_cell(:,2), SoilC_arable_QntYr_cell(:,3));
    SoilC_narable_QntYr20_cell = sparse(SoilC_narable_QntYr20_cell(:,1),SoilC_narable_QntYr20_cell(:,2),SoilC_narable_QntYr20_cell(:,3));
    SoilC_arable_QntYr20_cell  = sparse(SoilC_arable_QntYr20_cell(:,1), SoilC_arable_QntYr20_cell(:,2), SoilC_arable_QntYr20_cell(:,3));
    SoilC_narable_QntYr30_cell = sparse(SoilC_narable_QntYr30_cell(:,1),SoilC_narable_QntYr30_cell(:,2),SoilC_narable_QntYr30_cell(:,3));
    SoilC_arable_QntYr30_cell  = sparse(SoilC_arable_QntYr30_cell(:,1), SoilC_arable_QntYr30_cell(:,2), SoilC_arable_QntYr30_cell(:,3));
    SoilC_narable_QntYr40_cell = sparse(SoilC_narable_QntYr40_cell(:,1),SoilC_narable_QntYr40_cell(:,2),SoilC_narable_QntYr40_cell(:,3));
    SoilC_arable_QntYr40_cell  = sparse(SoilC_arable_QntYr40_cell(:,1), SoilC_arable_QntYr40_cell(:,2), SoilC_arable_QntYr40_cell(:,3));
    SoilC_narable_QntYr50_cell = sparse(SoilC_narable_QntYr50_cell(:,1),SoilC_narable_QntYr50_cell(:,2),SoilC_narable_QntYr50_cell(:,3));
    SoilC_arable_QntYr50_cell  = sparse(SoilC_arable_QntYr50_cell(:,1), SoilC_arable_QntYr50_cell(:,2), SoilC_arable_QntYr50_cell(:,3));

    % Increment YC for each of 40yrs to index into the cell annuity matrix
    %%% !!! - error here: need to reduce YC_prediction_cell down to 37861
    %%% cells
    YC_prediction_cell_idx = (double(es_forestry.YC_prediction_cell.(species)) - 1)*nCells + rowidx;                
  
    % Sum of Carbon quantities for years for which have climate data:
    SoilC_narable_Qnt_data_yrs = sum(SoilC_narable_QntYr_cell(YC_prediction_cell_idx),2);
    SoilC_arable_Qnt_data_yrs  = sum(SoilC_arable_QntYr_cell(YC_prediction_cell_idx),2);
    SoilC_narable_Qnt20 = sum(SoilC_narable_QntYr20_cell(YC_prediction_cell_idx(:, 1:10)),2);
    SoilC_arable_Qnt20  = sum(SoilC_arable_QntYr20_cell(YC_prediction_cell_idx(:, 1:10)),2);
    SoilC_narable_Qnt30 = sum(SoilC_narable_QntYr30_cell(YC_prediction_cell_idx(:, 11:20)),2);
    SoilC_arable_Qnt30  = sum(SoilC_arable_QntYr30_cell(YC_prediction_cell_idx(:, 11:20)),2);
    SoilC_narable_Qnt40 = sum(SoilC_narable_QntYr40_cell(YC_prediction_cell_idx(:, 21:30)),2);
    SoilC_arable_Qnt40  = sum(SoilC_arable_QntYr40_cell(YC_prediction_cell_idx(:, 21:30)),2);
    SoilC_narable_Qnt50 = sum(SoilC_narable_QntYr50_cell(YC_prediction_cell_idx(:, 31:40)),2);
    SoilC_arable_Qnt50  = sum(SoilC_arable_QntYr50_cell(YC_prediction_cell_idx(:, 31:40)),2);
    
    % Sum of Carbon quantities for remaining years up to end of rotation:
    yrs_to_end_rot = es_forestry.RotPeriod_cell.(species) - MP.num_years;
    SoilC_narable_Qnt_final_yrs = yrs_to_end_rot .* SoilC_narable_QntYr_cell(YC_prediction_cell_idx(:,end));
    SoilC_arable_Qnt_final_yrs  = yrs_to_end_rot .* SoilC_arable_QntYr_cell(YC_prediction_cell_idx(:,end));

    % Per ha Qnt of Soil Carbon per year
    ForestGHG.SoilC_QntYr.narable.(species) = full((SoilC_narable_Qnt_data_yrs + SoilC_narable_Qnt_final_yrs) ./ es_forestry.RotPeriod_cell.(species));        
	ForestGHG.SoilC_QntYr.arable.(species)  = full((SoilC_arable_Qnt_data_yrs + SoilC_arable_Qnt_final_yrs) ./ es_forestry.RotPeriod_cell.(species));
    ForestGHG.SoilC_QntYr20.narable.(species) = full(SoilC_narable_Qnt20) / 10;
    ForestGHG.SoilC_QntYr20.arable.(species) = full(SoilC_arable_Qnt20) / 10;
    ForestGHG.SoilC_QntYr30.narable.(species) = full(SoilC_narable_Qnt30) / 10;
    ForestGHG.SoilC_QntYr30.arable.(species) = full(SoilC_arable_Qnt30) / 10;
    ForestGHG.SoilC_QntYr40.narable.(species) = full(SoilC_narable_Qnt40) / 10;
    ForestGHG.SoilC_QntYr40.arable.(species) = full(SoilC_arable_Qnt40) / 10;
    ForestGHG.SoilC_QntYr50.narable.(species) = full(SoilC_narable_Qnt50) / 10;
    ForestGHG.SoilC_QntYr50.arable.(species) = full(SoilC_arable_Qnt50) / 10;
end

clear sqlquery soil_cols species spec_code Carbine_soil_cols;
clear fc_timber fc_soil timberC_spec soilC_spec i;
clear j yc rotp soilC_spec_yc soilC_spec_yc_yr0 soilC_spec_yc_yr1;
clear delta_rbase delta_rbase_rot gamma_rbase_rot timberC_npv soilC_npv stype;
clear SoilC_QntYr SoilC_narable_QntYr_cell SoilC_arable_QntYr_cell YC_prediction_cell_idx SoilC_narable_Qnt_data_yrs SoilC_arable_Qnt_data_yrs SoilC_narable_Qnt_final_yrs SoilC_arable_Qnt_final_yrs;
clear yrs_to_end_rot nCells rowidx colidx;
clear SoilC_QntYr20 SoilC_QntYr30 SoilC_QntYr40 SoilC_QntYr50
clear SoilC_arable_Qnt20 SoilC_arable_Qnt30 SoilC_arable_Qnt40 SoilC_arable_Qnt50
clear SoilC_narable_Qnt20 SoilC_narable_Qnt30 SoilC_narable_Qnt40 SoilC_narable_Qnt50
clear SoilC_arable_QntYr20_cell SoilC_arable_QntYr30_cell SoilC_arable_QntYr40_cell SoilC_arable_QntYr50_cell
clear SoilC_narable_QntYr20_cell SoilC_narable_QntYr30_cell SoilC_narable_QntYr40_cell SoilC_narable_QntYr50_cell