function [aucTable] = calculateAUCAll(tableIn, colNameIn, columnNamePrefix)

%% PURPOSE: CALCULATE THE AREA UNDER THE CURVE (AUC) FOR THE SPECIFIED COLUMN.
% Inputs:
% tableIn: The table of data
% colNameIn: The column to compute the AUC for. Data should be a struct.
% columnNamePrefix: The prefix for the column name to store the AUC in.
%
% Outputs:
% aucTable: The table with the computed AUC data

aucTable = table;
for i = 1:height(tableIn)
    tmpTable = table;
    tmpTable.Name = tableIn.Name(i);
    currData = tableIn.(colNameIn)(i);
    structFields = fieldnames(currData);
    for fieldNum = 1:length(structFields)
        fieldName = structFields{fieldNum};
        storeFieldName = [columnNamePrefix '_' fieldName];
        tmpTable.(storeFieldName) = trapz(currData.(fieldName));
    end
    aucTable = [aucTable; tmpTable];
end