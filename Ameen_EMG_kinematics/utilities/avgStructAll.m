function [avgStructTable] = avgStructAll(dataTable, colNameToAverage, averagedColName, levelNum)

%% PURPOSE: AVERAGE THE DATA IN A STRUCT.
% Inputs:
% dataTable: The table containing all of the data. Each row is one entry.
% colNameToAverage: The column name to use for averaging.
% averagedColName: The column name to store the averages in.
% levelNum: The level to average within (counting backwards from the end)
%
% Output:
% avgStructTable: Each row is one struct, where each field has the averaged
% data

disp('Averaging the data within one visit');

visitNames = getNamesPrefixes(dataTable.Name, levelNum);
avgStructTable = table;
for i = 1:length(visitNames)
    visitName = visitNames{i};
    avgStruct = struct;
    aggStruct = aggStructData(dataTable, colNameToAverage, visitName);
    fieldNames = fieldnames(aggStruct);
    for fieldNum = 1:length(fieldNames)
        fieldName = fieldNames{fieldNum};
        avgStruct.(fieldName) = mean(aggStruct.(fieldName),1);
    end
    tmpTable = table;
    tmpTable.Name = convertCharsToStrings(visitName);
    tmpTable.(averagedColName) = avgStruct;
    avgStructTable = [avgStructTable; tmpTable];
end