function [symmetryTable] = calculateSymmetryAll(tableIn, colNamesL, colNamesR, colNameSuffix, formulaNum)

%% PURPOSE: CALCULATE THE SYMMETRY VALUES BETWEEN THE TWO COLUMNS.
% Inputs:
% tableIn: The table with the input data
% colNamesL: The data column names for the left side (start with 'L')
% colNamesR: The data column names for the right side (start with 'R')
% colNameSuffix: The suffix to append to the column names
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

assert(length(colNamesL) == length(colNamesR));

symmetryTable = table;
for i = 1:height(tableIn)
    tmpTable = table;
    tmpTable.Name = tableIn.Name(i);

    for fieldNum = 1:length(colNamesL)
        colNameL = colNamesL{fieldNum};
        colNameR = colNamesR{fieldNum};
        fieldNameNoSide = colNameL(3:end);
        v1 = tableIn.(colNameL)(i);
        v2 = tableIn.(colNameR)(i);
        if iscell(v1)
            v1 = v1{1};
        end
        if iscell(v2)
            v2 = v2{1};
        end
        if isempty(v1) || isempty(v2)
            tmpOut = NaN;
        else
            tmpOut = calculateSymmetryTwoVectors(v1, v2, formulaNum);
        end
        tmpTable.([fieldNameNoSide colNameSuffix]) = {tmpOut};
    end

    symmetryTable = [symmetryTable; tmpTable];
end