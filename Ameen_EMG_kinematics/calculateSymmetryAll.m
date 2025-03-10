function [symmetryTable] = calculateSymmetryAll(tableIn, colNameSuffix, formulaNum, levelNum)

%% PURPOSE: CALCULATE THE SYMMETRY VALUES BETWEEN THE TWO COLUMNS.
% Inputs:
% tableIn: The table with the input data
% colNameSuffix: The suffix to append to the column names
% formulaNum: The number of the formula to use
% levelNum: The level to match the name at to parse repetitions
%
% Outputs:
% symmetryTable: The table of computed symmetry values.
%
% NOTE: The fields of the struct must begin with 'L' or 'R',
% and the number of 'L' and 'R' fields should be matching.

disp('Calculating symmetry indices');

if ~exist('formulaNum','var')
    formulaNum = 2;
end

if ~exist('levelNum','var')
    levelNum = 5;
end

colNamesToRemove = {'Name'};

colNames = tableIn.Properties.VariableNames;
colNames(ismember(colNames, colNamesToRemove)) = [];

symmetryTable = table;
for i = 1:height(tableIn)-1
    tmpTable = table;    
    tmpTable.Name = tableIn.Name(i);
    currNameParsed = getNamesPrefixes(tableIn.Name(i), levelNum);
    nextNameParsed = getNamesPrefixes(tableIn.Name(i+1), levelNum);
    % Being sloppy here because I don't want to troubleshoot getNamesPrefixes
    if iscell(currNameParsed)
        currNameParsed = currNameParsed{1};
    end
    if iscell(nextNameParsed)
        nextNameParsed = nextNameParsed{1};
    end
    if ~strcmp(currNameParsed, nextNameParsed)
        continue;
    end
    
    for fieldNum = 1:length(colNames)
        colName = colNames{fieldNum};
        v1 = tableIn.(colName)(i);
        v2 = tableIn.(colName)(i+1);
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
        tmpTable.([colName colNameSuffix]) = {tmpOut};
    end

    symmetryTable = [symmetryTable; tmpTable];
end