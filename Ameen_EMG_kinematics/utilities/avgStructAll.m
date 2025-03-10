function [avgStructTable] = avgStructAll(dataTable, colNameToAverage, averagedColName, sideEndRegex, levelNum)

%% PURPOSE: AVERAGE THE DATA IN A STRUCT.
% Inputs:
% dataTable: The table containing all of the data. Each row is one entry.
% colNameToAverage: The column name to use for averaging.
% averagedColName: The column name to store the averages in.
% sideEndRegex: The regex indicating which rows to include in the averaging. 
% levelNum: The level to average within (counting backwards from the end)
%
% Output:
% avgStructTable: Each row is one struct, where each field has the averaged
% data
%
% NOTE: For the sideEndRegex, if the "Name" field ends with 'L' or 'R' to 
% indicate left and right sides, use '.*L$' to select the left side or '.*R$' for the right side

disp('Averaging the data within one visit');

if ~exist('levelNum','var')
    levelNum = 4;
end

visitNames = getNamesPrefixes(dataTable.Name, levelNum);
avgStructTable = table;
for i = 1:length(visitNames)
    visitName = visitNames{i};
    avgStruct = struct;
    aggStruct = aggStructData(dataTable, colNameToAverage, visitName);
    fieldNames = fieldnames(aggStruct);
    for fieldNum = 1:length(fieldNames)
        fieldName = fieldNames{fieldNum};
        avgStruct.(fieldName) = mean(aggStruct.(fieldName),1,'omitnan');
    end
    tmpTable = table;
    tmpTable.Name = convertCharsToStrings(visitName);
    tmpTable.(averagedColName) = avgStruct;
    avgStructTable = [avgStructTable; tmpTable];
end