function [normalizedDataTable] = normalizeAllDataToVisitValue(dataTable, dataColName, visitTable, visitColName, normalizedDataColName)

%% PURPOSE: NORMALIZE DATA IN A TRIAL OR GAIT CYCLE TO A PER-VISIT VALUE FROM THE VISIT TABLE.
% Inputs:
% dataTable: Each row is one trial or gait cycle
% dataColName: The column of the dataTable to normalize.
% visitTable: The visit table, each row is one visit.
% visitColName: The column name of the visit to use to normalize by.
% normalizedDataColName: The column name to store the normalized data to.
%
% Outputs:
% normalizedDataTable: The normalized data.

normalizedDataTable = table;
for i = 1:height(dataTable)
    tmpTable = table;
    name = dataTable.Name(i);
    dataToNormalize = dataTable.(dataColName)(i);
    % nameParts = strsplit(name, '_');
    visitName = getNamesPrefixes(char(name), 2);
    % visitName = '';
    % for j = 1:length(nameParts)-2
    %     visitName = [visitName '_' nameParts{j}];
    % end
    % visitName = visitName(2:end);
    visitRowInVisitTable = ismember(visitTable.Name, visitName);
    visitData = visitTable.(visitColName)(visitRowInVisitTable);
    normalizedStruct = struct;
    fieldNames = fieldnames(dataToNormalize);
    for fieldNum = 1:length(fieldNames)
        fieldName = fieldNames{fieldNum};
        normalizedStruct.(fieldName) = dataToNormalize.(fieldName) / visitData.(fieldName);
    end
    tmpTable.Name = dataTable.Name(i);
    tmpTable.(normalizedDataColName) = normalizedStruct;
    normalizedDataTable = [normalizedDataTable; tmpTable];
end