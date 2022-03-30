%% fcn_select_years.m
%  ==================
%
%  Author:
%
% -------------------
function [year_string] = fcn_select_years(type, years)
    years_cell = cellstr(string(years));
    year_string = strcat({type}, years_cell);
end