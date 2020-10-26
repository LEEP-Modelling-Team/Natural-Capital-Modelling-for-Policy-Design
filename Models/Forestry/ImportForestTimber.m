%% IMPORT FOREST TIMBER 
%  ====================

%  Imports data on yields, revenues and costs of forestry calculated 
%  from FC model for different yield classes (yc) of different species.
%
%  Uses data on current cell ESC scores to predict future ESC scores for
%  each cell under climate path using Silvia Ferrini's GAM model from the
%  NEAFO project. ESC scores are rounded to nearest Yield Class with data
%  from FC's Carbine model

es_forestry.base_discount_rate = base_discount_rate;

%% (1) BRING IN BASE DATA FROM DATABASE
%  ------------------------------------
% (a) List of Species
% -------------------
sqlquery    = ['SELECT * FROM nevo.forestry_species_list WHERE code IN (' forest_species_list ')'];
setdbprefs('DataReturnFormat','table');
dataReturn  = fetch(exec(conn,sqlquery));
ForestTimber.SpeciesCode = dataReturn.Data;

% (b) Timber data
%  --------------
sqlquery    = 'SELECT * FROM nevo.forestry_timber_data ORDER BY code, yield_class, year';
setdbprefs('DataReturnFormat','table');
dataReturn  = fetch(exec(conn,sqlquery));
timber = dataReturn.Data;

% (c) Rotation periods
% --------------------
sqlquery    = 'SELECT * FROM nevo.forestry_rotation_periods ORDER BY code, yield_class';
setdbprefs('DataReturnFormat','table');
dataReturn  = fetch(exec(conn,sqlquery));
rotation    = dataReturn.Data;

% (d) Cost definitions
% --------------------
% Fixed costs (for each woodland):
sqlquery    = 'SELECT cell_costs FROM nevo.forestry_cost_definitions WHERE cell_costs IS NOT NULL';
setdbprefs('DataReturnFormat','cellarray');
dataReturn  = fetch(exec(conn,sqlquery));
CostDefinitions.FixedCosts = dataReturn.Data(:,1)';

% Variable costs (per ha of woodland):
sqlquery    = 'SELECT ha_costs FROM nevo.forestry_cost_definitions WHERE ha_costs IS NOT NULL';
setdbprefs('DataReturnFormat','cellarray');
dataReturn  = fetch(exec(conn,sqlquery));
CostDefinitions.PerHaCosts = dataReturn.Data(:,1)';

% (e) ESC scores & Climate data & GAM Parameters for Silvias ESC future model
% ---------------------------------------------------------------------------
sqlquery = ['SELECT tbl3.*, tbl2.mt_as_6190, tbl2.tp_as_6190, tbl1.ss, tbl1.pok, tbl1.sp, tbl1.be ' ...
            'FROM nevo.forestry_esc_scores AS tbl1 ' ...
            '  INNER JOIN nevo.nevo_variables AS tbl2 ON tbl1.new2kid = tbl2.new2kid ' ...
            '  INNER JOIN nevo.nevo_fclimate_grow_avg AS tbl3 ON tbl1.new2kid = tbl3.new2kid ' ...
            '  ORDER BY tbl1.new2kid'];
setdbprefs('DataReturnFormat','table');
dataReturn = fetch(exec(conn,sqlquery));
esc_cells  = dataReturn.Data;

% Calculate covariates for Silvia's ESC score model
esc_cells.Temp12 = (esc_cells.mt_as_6190>12).*(esc_cells.mt_as_6190-12);
esc_cells.Temp9  = (esc_cells.mt_as_6190>9).*(esc_cells.mt_as_6190-9);
esc_cells.Rain1  = (esc_cells.tp_as_6190>400).*(esc_cells.tp_as_6190-400);

esc_cells.Temp12Rain1 = esc_cells.Temp12.*esc_cells.Rain1;
esc_cells.TempRain1   = esc_cells.mt_as_6190.*esc_cells.Rain1;
esc_cells.Temp12Rain  = esc_cells.Temp12.*esc_cells.tp_as_6190;
esc_cells.TempRain    = esc_cells.mt_as_6190.*esc_cells.tp_as_6190;

esc_cells.Temp9Rain1  = esc_cells.Temp9.*esc_cells.Rain1;
esc_cells.Temp9Rain   = esc_cells.Temp9.*esc_cells.tp_as_6190;

% Save order of new2kid cells used in Forest Model
ForestTimber.new2kid = esc_cells.new2kid;

%% (2) SET UP SPECIES-SPECIFIC DATA FOR YIELDS, COSTS, YIELD CLASSES
%  -----------------------------------------------------------------

% Loop through each species
for i = 1:height(ForestTimber.SpeciesCode)
    species   = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.species(i)));
    spec_code = matlab.lang.makeValidName(cell2mat(ForestTimber.SpeciesCode.code(i)));
  
    % (a) Rotation Data by Yield Class
    % --------------------------------
    timber_spec = timber(string(timber.code)==string(spec_code),:);
    rot_spec    = rotation(string(rotation.code)==string(spec_code),:);
    
    year = timber_spec.year2014 + 1; 
    yc   = timber_spec.yield_class;
    
    ForestTimber.Timber.(species)       = sparse(year,yc,timber_spec.volume);
    Timber_total.(species) = sum(ForestTimber.Timber.(species),1)';
    
    ForestTimber.TimberValue.(species)  = sparse(year,yc,timber_spec.volume.*timber_spec.price);
    
    ForestTimber.TimberCosts.Fixed.(species) = sparse(year,yc,sum(timber_spec{:, CostDefinitions.FixedCosts},2));
    ForestTimber.TimberCosts.PerHa.(species) = sparse(year,yc,sum(timber_spec{:, CostDefinitions.PerHaCosts},2));
    
    ForestTimber.RotPeriod.(species)     = sparse(rot_spec.yield_class, 1, rot_spec.rotation); 
    ForestTimber.RotPeriod_max.(species) = max(ForestTimber.RotPeriod.(species)); 
    
    ForestTimber.Carbine_ycs.(species)     = find(ForestTimber.RotPeriod.(species));
    ForestTimber.Carbine_ycs_max.(species) = max(ForestTimber.Carbine_ycs.(species));
              

    % (c) Predict Future Yield Class for Each NEVO Cell
    % -------------------------------------------------
    yc_future_spec = uint8(zeros(size(esc_cells,1),MP.num_years));
    for yr = 1:MP.num_years   
        % Predicted YC for this species in this cell over climates for future years (for which we havd data out to MP.num_years)
        yc_future_spec(:,yr) = fcn_future_YC_model(esc_cells, num2str(MP.start_year+yr-1), species, spec_code, ForestTimber.Carbine_ycs);        
    end    
        
    % Store YC predictions for NEVO interactive valuation
    es_forestry.YC_prediction_cell.(species) = yc_future_spec;

    
    % (d) Predict Climate-Adjusted Rotation Period for each NEVO Cell (if planting today)
    % -----------------------------------------------------------------------------------
    %    Each year a cell is in yc it contributes 1/F(yc) to the tree's
    %    growth. Where F(yc) is the rotation length for that yc. Simply sum 
    %    until the tree is fully grown.
    %
    %    NB: Past the final year of climate data the tree is assumed to 
    %        grow at the rate of the yc of final year.
    %        No need to account for +1 year preparation as this is    
    %        done in the annuity calculation. We just wish to find an 
    %        adjusted rotation length.

    % Proportion of 'full growth' provided by one year's worth of growth at each yc
    pgrow_yr = 1./ForestTimber.RotPeriod.(species);

    % Climate adjusted rotation using clever index of proportion of growth vector from future yc 
    pgrow_data_yrs = sum(pgrow_yr(yc_future_spec),2); % Proportion grow in data years
    pgrow_final_yr = pgrow_yr(yc_future_spec(:,end)); % Proportion of year of final year of data
    
    es_forestry.RotPeriod_cell.(species) = round(MP.num_years + ((1-pgrow_data_yrs)./pgrow_final_yr));
    
    % (e) Predict Climate-Adjusted Timber yield for each NEVO Cell (if planting today)
    % --------------------------------------------------------------------------------    
    timber_data_yrs  = sum(pgrow_yr(yc_future_spec) .* Timber_total.(species)(yc_future_spec), 2);
    %ForestTimber.timber_data_yrs.(species) = timber_data_yrs;
    timber_final_yrs = (1-pgrow_data_yrs).*Timber_total.(species)(yc_future_spec(:,end));
    
    ForestTimber.QntPerHa.(species) = full((timber_data_yrs + timber_final_yrs) ./ es_forestry.RotPeriod_cell.(species));   
    % Note: this is timber quantity so no discounting & no C permanent
    %       equivalence calculation needed in sum
    
end
    
  
clear sqlquery rotation timber esc_cells CostDefinitions;
clear carbine_yc_max spec_esc_scores_cell;
clear species spec_code timber_spec rot_spec year yc;
clear delta npv npv_benefit npv_cost annuity_npv annuity_npv_cst;
clear yc_future_spec yr yrs pgrow_yr pgrow_data_yrs pgrow_final_yr;
clear timber_data_yrs timber_final_yrs;

