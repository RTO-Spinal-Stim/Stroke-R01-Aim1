function [rangeTable] = calculateRangeAll(tableIn, colNameIn, colNameOutPrefix, sidePrefixes)

%% PURPOSE: COMPUTE THE RANGE, MIN, AND MAX OF DATA OBSERVED.
% Inputs:
% tableIn: The input data table
% colNameIn: The column of data to analyze (struct)
% colNameOutPrefix: The prefix for the column to store the analyzed data
% sidePrefixes: Cell array of the single char prefixes to use in the
% columns. Default: {'L','R'} for left & right. Could also be {'A','U'} for
% affected and unaffected, or other
%
% Outputs:
% rangeTable: The table with the computed data

disp('Calculating range of motion');

if ~exist('sidePrefixes','var')
    sidePrefixes = {'L','R'};
end

rangeTable = table;
for i = 1:height(tableIn)
    tmpTable = table;
    tmpTable.Name = tableIn.Name(i);

    data = tableIn.(colNameIn)(i);

    structFieldNames = fieldnames(data);
    for fieldNum = 1:length(structFieldNames)
        fieldNameOrig = structFieldNames{fieldNum};
        fieldName = fieldNameOrig;
        if startsWith(fieldNameOrig,sidePrefixes)
            firstLetter = fieldNameOrig(1);
            fieldName = fieldNameOrig(2:end);
        end
        colName = [firstLetter '_' fieldName '_' colNameOutPrefix];
        minVal = min(data.(fieldNameOrig));
        maxVal = max(data.(fieldNameOrig));
        rangeVal = maxVal - minVal;
        if isempty(rangeVal)
            minVal = NaN;
            maxVal = NaN;
            rangeVal = NaN;
        end           
        tmpTable.([colName '_Min']) = minVal;
        tmpTable.([colName '_Max']) = maxVal;
        tmpTable.([colName '_Range']) = rangeVal;
    end
    rangeTable = [rangeTable; tmpTable];
end