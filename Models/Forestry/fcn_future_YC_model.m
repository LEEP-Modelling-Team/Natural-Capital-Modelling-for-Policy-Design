% Function: fcn_future_YC_model
% -----------------------------
%  Uses data on current cell ESC scores to predict future ESC scores for
%  each cell under climate path using Silvia Ferrini's GAM model from the
%  NEAFO project. ESC scores are rounded to nearest Yield Class with data
%  from FC's Carbine model

function [yc_yr] = fcn_future_YC_model(esc_cells, yr, species, spec_code, carbine_ycs)

    % (a) Current ESC score for this species in each cell
    %  --------------------------------------------------
    esc_current = esc_cells.(spec_code);

    % (a) Find Temperature and Rain for this year in each cell
    %  -------------------------------------------------------
    rain_yr = eval(['esc_cells.rain' yr]);
    temp_yr = eval(['esc_cells.temp' yr]);

    % (b) Interaction covariates for prediciton equation
    %  -------------------------------------------------
    temp_rain_yr  = temp_yr.*rain_yr;
    rain1_yr      = (rain_yr>400).*(rain_yr-400);
    temp_rain1_yr = temp_yr.*rain1_yr;

    % (c) Model specific covariates
    %  ----------------------------
    % For Sitka Spruce
    if strcmp(species,'SitkaSpruce'); 
        temp12_yr       = (temp_yr>12).*(temp_yr-12);
        temp12_rain1_yr = temp12_yr.*rain1_yr;
        temp12_rain_yr  = temp12_yr.*rain_yr;
        ESCtmp   = [temp12_yr-esc_cells.Temp12, temp_yr-esc_cells.mt_as_6190, rain1_yr - esc_cells.Rain1, rain_yr - esc_cells.tp_as_6190, temp12_rain1_yr-esc_cells.Temp12Rain1, temp_rain1_yr-esc_cells.TempRain1, temp12_rain_yr-esc_cells.Temp12Rain, temp_rain_yr-esc_cells.TempRain] ;
        ESCCoeff = [4.669 -4.935 0.13583 -0.13703 0.01944 -0.01315 -0.01625 0.01304]';
    end
    %Oak
    if strcmp(species,'PedunculateOak');  
        temp9_yr       = (temp_yr>9).*(temp_yr-9);
        temp9_rain1_yr = temp9_yr.*rain1_yr; 
        temp9_rain_yr  = temp9_yr.*rain_yr;
        ESCtmp   = [temp9_yr-esc_cells.Temp9, temp_yr-esc_cells.mt_as_6190, rain1_yr - esc_cells.Rain1, rain_yr - esc_cells.tp_as_6190, temp9_rain1_yr-esc_cells.Temp9Rain1, temp_rain1_yr-esc_cells.TempRain1, temp9_rain_yr-esc_cells.Temp9Rain, temp_rain_yr-esc_cells.TempRain] ;
        ESCCoeff = [0.633024 0.183587 -0.05424 0.035142 -0.00391 0.005462 0.001311 -0.00329]';
    end

    % (d) Model prediction of future ESC
    %  ----------------------------------
    esc_yr = esc_current + ESCtmp*ESCCoeff;
    
    % (e) Round ESC to YC and constrain to range of YC in Carbine data
    %  ----------------------------------------------------------------   
    yc_yr = 2*round(0.5*esc_yr);% Round to nearest even number, rounding up from the last odd
    yc_yr(yc_yr < carbine_ycs.(species)(1))   = carbine_ycs.(species)(1);   % Drives zero values to the first index, used later when looking up annuity values from importForestModel
    yc_yr(yc_yr > carbine_ycs.(species)(end)) = carbine_ycs.(species)(end); % Restricts to feasible range
    
end
