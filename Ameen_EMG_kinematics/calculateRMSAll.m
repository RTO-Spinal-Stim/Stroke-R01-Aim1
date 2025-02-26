function [rmsTable] = calculateRMSAll(tableIn, colNameIn, colNameSuffix)

%% PURPOSE: CALCULATE THE RMS OF A TIMESERIES
% Inputs:
% tableIn: The input data table
% colNameIn: The column name to analyze. The data should be a struct.
% colNameSuffix: The suffix of the column name to store the RMS data
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
        fieldNameOrig = structFieldNames{fieldNum};
        fieldName = fieldNameOrig;
        if startsWith(fieldNameOrig,{'L','R'})
            firstLetter = fieldNameOrig(1);
            fieldName = fieldNameOrig(2:end);
        end
        colName = [firstLetter '_' fieldName '_' colNameSuffix];
        if isempty(currData.(fieldNameOrig))
            tmpTable.(colName) = NaN;
        else
            tmpTable.(colName) = rms(currData.(fieldNameOrig));
        end
    end
    rmsTable = [rmsTable; tmpTable];
end