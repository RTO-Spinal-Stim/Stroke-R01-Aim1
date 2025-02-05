function [spmTable] = SPManalysisAll(dataTable, dataColName, spmColName, group1Names, group2Names, alphaValue)

%% PURPOSE: RUN SPM ANALYSIS ON ALL CYCLES/TRIALS.
% Inputs:
% dataTable: Each row is one gait cycle/trial.
% dataColName: The name of the column containing the data
% spmColName: The name of the column to store the data to.
% group1Names: Cell array of chars with the first group's field names.
% group2Names: Cell array of chars with the second group's field names.
%
% Outputs:
% spmTable: Each row is one gait cycle/trial.

if ~exist('alphaValue','var')
    alphaValue = 0.05;
end

spmTable = table;
visitNames = getNamesPrefixes(dataTable.Name, 2);
for i = 1:length(visitNames)
    visitName = visitNames{i};    
    tmpTable = table;
    aggStruct = aggStructData(dataTable, dataColName, visitName);
    spmResult = SPM_Analysis(aggStruct, group1Names, group2Names, alphaValue);
    tmpTable.Name = convertCharsToStrings(visitName);
    tmpTable.(spmColName) = spmResult;
    spmTable = [spmTable; tmpTable];
end