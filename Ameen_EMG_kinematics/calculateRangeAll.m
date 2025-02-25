function [rangeTable] = calculateRangeAll(tableIn, colNameIn, colNameOutPrefix)

%% PURPOSE: COMPUTE THE RANGE, MIN, AND MAX OF DATA OBSERVED.
% Inputs:
% tableIn: The input data table
% colNameIn: The column of data to analyze (struct)
% colNameOutPrefix: The prefix for the column to store the analyzed data
%
% Outputs:
% rangeTable: The table with the computed data

rangeTable = table;
for i = 1:height(tableIn)
    tmpTable = table;
    tmpTable.Name = tableIn.Name(i);

    data = tableIn.(colNameIn)(i);

    structFieldNames = fieldnames(data);
    for fieldNum = 1:length(structFieldNames)
        fieldName = structFieldNames{fieldNum};
        colName = [colNameOutPrefix '_' fieldName];
        minVal = min(data.(fieldName));
        maxVal = max(data.(fieldName));
        rangeVal = maxVal - minVal;
        tmpTable.([colName '_Min']) = minVal;
        tmpTable.([colName '_Max']) = maxVal;
        tmpTable.([colName '_Range']) = rangeVal;
    end
    rangeTable = [rangeTable; tmpTable];
end