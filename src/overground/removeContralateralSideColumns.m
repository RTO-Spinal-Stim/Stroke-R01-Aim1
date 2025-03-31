function [tableOut] = removeContralateralSideColumns(tableIn, columnNamesL, columnNamesR)

%% PURPOSE: MERGE THE L AND R COLUMNS BY REMOVING DATA FROM THE CONTRALATERAL SIDES.
% For example, remove R_HIP_AUC from a L gait cycle, replace the column
% with 'HIP_AUC'
% Inputs:
% tableIn: The table of input data
% columnNamesL: The column names of left data
% columnNamesR: The column names of right data
%
% Outputs:
% tableOut: The table of output data

disp('Removing the contralateral side data and merging L & R columns');

tableOut = table;

%% Remove the non-scalar columns
% scalarColumnNames = getScalarColumnNames(tableIn);
% columnNamesL(~ismember(columnNamesL, scalarColumnNames)) = [];
% columnNamesR(~ismember(columnNamesR, scalarColumnNames)) = [];

%% Initialize the column names with the side removed.
colNamesNoSide = cell(size(columnNamesL));
for i = 1:length(columnNamesL)
    colNamesNoSide{i} = columnNamesL{i}(3:end);
end

%% Remove the 'L_' and 'R_' tables, yielding columns with no side.
for i = 1:height(tableIn)
    rowName = char(tableIn.Name(i));
    tmpTable = table;
    tmpTable.Name = convertCharsToStrings(rowName);
    for colNum = 1:length(colNamesNoSide)
        colNameNoSide = colNamesNoSide{colNum};
        rowSide = rowName(end-1:end);
        if strcmp(rowSide, '_L')
            colNameSide = columnNamesL{colNum};
        elseif strcmp(rowSide, '_R')
            colNameSide = columnNamesR{colNum};
        end
        tmpTable.(colNameNoSide) = tableIn.(colNameSide)(i);
    end
    tableOut = [tableOut; tmpTable];
end