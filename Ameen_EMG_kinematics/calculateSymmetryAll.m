function [symmetryTable] = calculateSymmetryAll(tableIn, colNameIn, formulaNum)

%% PURPOSE: CALCULATE THE SYMMETRY VALUES BETWEEN THE TWO COLUMNS.
% Inputs:
% tableIn: The table with the input data
% colNameIn: The data column name
% formulaNum: The number of the formula to use
%
% Outputs:
% symmetryTable: The table of computed symmetry values.
%
% NOTE: The fields of the struct must begin with 'L' or 'R',
% and the number of 'L' and 'R' fields should be matching.

if ~exist('formulaNum','var')
    formulaNum = 3;
end

symmetryTable = table;
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

    for fieldNum = 1:length(structFieldsLR)
        fieldName = structFieldsLR{fieldNum};
        fieldNameL = ['L' fieldName];
        fieldNameR = ['R' fieldName];
        tmpTable.(fieldName) = calculateSymmetryTwoVectors(data.(fieldNameL), data.(fieldNameR), formulaNum);
    end
    
    symmetryTable = [symmetryTable; tmpTable];
end