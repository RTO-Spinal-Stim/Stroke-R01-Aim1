function [rmseTable] = calculateLRRMSEAll(tableIn, colNameIn, colNamePrefix)

%% PURPOSE: COMPUTE RMSE BETWEEN L & R FIELDS OF A STRUCT. 
% NOTE: The RMSE is computed between the i'th gait cycle of one side and
% the i+1'th gait cycle (corresponding to the other side). Therefore, there
% are always N-1 RMSE values for N gait cycles.
% Inputs:
% tableIn: The input data table
% colNameIn: The column name of the input data. This should be a struct
% colNamePrefix: The prefix of the column name to store the computed data
%
% Outputs:
% rmseTable: The table with the computed RMSE data

rmseTable = table;
for i = 1:height(tableIn)
    tmpTable = table;
    tmpTable.Name = tableIn.Name(i);

    data = tableIn.(colNameIn)(i);

    if ~isstruct(data)
        error(['Not a struct! ' colNameIn ' ' char(tableIn.Name{i})]);
    end

    % Get all of the field names, removing the L & R prefixes
    structFieldsLR = fieldnames(data);
    structFieldsNoSides = {};
    for fieldNum = 1:length(structFieldsLR)
        fieldName = structFieldsLR{fieldNum}(2:end);
        if ~ismember(fieldName, structFieldsNoSides)
            structFieldsNoSides = [structFieldsNoSides; {fieldName}];
        end
    end

    for fieldNum = 1:length(structFieldsNoSides)
        fieldName = structFieldsNoSides{fieldNum};
        fieldNameL = ['L' fieldName];
        fieldNameR = ['R' fieldName];
        difference = data.(fieldNameL) - data.(fieldNameR);
        squared_diff = difference.^2;
        mean_squared_diff = mean(squared_diff);
        rmseValue = sqrt(mean_squared_diff);
        fieldNameStore = [colNamePrefix '_' fieldName];
        tmpTable.(fieldNameStore) = rmseValue;
    end

    rmseTable = [rmseTable; tmpTable];
end