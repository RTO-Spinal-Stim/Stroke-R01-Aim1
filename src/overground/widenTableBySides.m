function [tableOut] = widenTableBySides(tableIn, sideColName)

%% PURPOSE: WIDEN THE TABLE SO THAT EACH COLUMN HAS THE SIDE PREPENDED TO IT. RESULTS IN TWICE AS MANY FEATURE COLUMNS, AND REMOVES THE SIDE COLUMN.
% Inputs:
% tableIn: The input data table
% sideColName: The column name with the side information
%
% Outputs:
% tableOut: The output data table