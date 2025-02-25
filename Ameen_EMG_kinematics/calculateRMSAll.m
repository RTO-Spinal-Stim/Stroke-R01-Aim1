function [rmsTable] = calculateRMSAll(tableIn, colNameIn, colNamePrefix)

%% PURPOSE: CALCULATE THE RMS OF A TIMESERIES
% Inputs:
% tableIn: The input data table
% colNameIn: The column name to analyze. The data should be a struct.
% colNamePrefix: The prefix of the column name to store the RMS data
%
% Outputs:
% rmsTable: The table with the RMS data

rmsTable = table;
for i = 1:height(tableIn)
    tmpTable = table;
    tmpTable.Name = tableIn.Name(i);
    currData = tableIn.(colNameIn)(i);
    structFieldNames = fieldnames(currData);
    for fieldNum = 1:length(structFieldNames)
        fieldName = structFieldNames{fieldNum};
        colName = [colNamePrefix '_' fieldName];
        tmpTable.(colName) = rms(currData.(fieldName));
    end
    rmsTable = [rmsTable; tmpTable];
end