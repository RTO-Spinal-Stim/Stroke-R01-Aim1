function [normalizedDataTable] = normalizeAllDataToVisitValue(dataTable, dataColName, visitTable, visitColName, normalizedDataColName, levelNum)

%% PURPOSE: NORMALIZE DATA IN A TRIAL OR GAIT CYCLE TO A PER-VISIT VALUE FROM THE VISIT TABLE.
% Inputs:
% dataTable: Each row is one trial or gait cycle
% dataColName: The column of the dataTable to normalize.
% visitTable: The visit table, each row is one visit.
% visitColName: The column name of the visit to use to normalize by.
% normalizedDataColName: The column name to store the normalized data to.
% levelNum: The level of the Name column to segment by.
%
% Outputs:
% normalizedDataTable: The normalized data.

if ~exist('levelNum','var')
    levelNum = 2;
end

disp('Normalizing data to per-visit value');

normalizedDataTable = table;
for i = 1:height(dataTable)
    tmpTable = table;
    name = dataTable.Name(i);
    dataToNormalize = dataTable.(dataColName)(i);
    visitName = getNamesPrefixes(char(name), levelNum);
    visitRowInVisitTable = ismember(visitTable.Name, visitName);
    assert(sum(visitRowInVisitTable)==1);
    visitData = visitTable.(visitColName)(visitRowInVisitTable);
    normalizedStruct = struct;
    fieldNames = fieldnames(dataToNormalize);
    for fieldNum = 1:length(fieldNames)
        fieldName = fieldNames{fieldNum};
        normalizedStruct.(fieldName) = dataToNormalize.(fieldName) ./ visitData.(fieldName);
    end
    tmpTable.Name = dataTable.Name(i);
    tmpTable.(normalizedDataColName) = normalizedStruct;
    normalizedDataTable = [normalizedDataTable; tmpTable];
end