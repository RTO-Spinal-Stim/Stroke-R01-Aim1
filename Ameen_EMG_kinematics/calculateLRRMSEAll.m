function [rmseTable] = calculateLRRMSEAll(tableIn, colNameIn, colNameSuffix)

%% PURPOSE: COMPUTE RMSE BETWEEN L & R FIELDS OF A STRUCT. 
% NOTE: The RMSE is computed between the i'th gait cycle of one side and
% the i+1'th gait cycle (corresponding to the other side). Currently, the
% table of input data already matches alternating gait cycles into each row.
%
% Inputs:
% tableIn: The input data table
% colNameIn: The column name of the input data. This should be a struct
% which gait events are L vs. R
% colNameSuffix: The suffix of the column name to store the computed data
%
% Outputs:
% rmseTable: The table with the computed RMSE data

disp('Calculating RMSE');

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
        fieldNameStore = [fieldName '_' colNameSuffix];
        % There is one more L or R gait cycle vs. the other side.
        if isempty(data.(fieldNameL)) || isempty(data.(fieldNameR))
            tmpTable.(fieldNameStore) = NaN;
            continue;
        end
        difference = data.(fieldNameL) - data.(fieldNameR);
        squared_diff = difference.^2;
        mean_squared_diff = mean(squared_diff);
        rmseValue = sqrt(mean_squared_diff);        
        tmpTable.(fieldNameStore) = rmseValue;
    end

    rmseTable = [rmseTable; tmpTable];
end