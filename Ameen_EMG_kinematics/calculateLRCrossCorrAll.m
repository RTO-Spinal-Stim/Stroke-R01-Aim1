function [crossCorrTable] = calculateLRCrossCorrAll(tableIn, colNameIn, colNamePrefix)

%% PURPOSE: CALCULATE THE CROSS-CORRELATIONS BETWEEN CONSECUTIVE GAIT CYCLES
% NOTE: The cross correlation is computed between the i'th gait cycle of one side and
% the i+1'th gait cycle (corresponding to the other side). Therefore, there
% are always N-1 cross correlation values for N gait cycles.
% Inputs:
% tableIn: The input data table
% colNameIn: The column name of the input data. This should be a struct
% colNamePrefix: The prefix of the column name to store the computed data
%
% Outputs:
% crossCorrTable: The table with the computed cross correlation data