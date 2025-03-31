function [tableOut] = calculatePrePostChange(tableIn, formulaNum, levelNum)

%% PURPOSE: CALCULATE THE CHANGE IN POST VS. PRE
% Inputs:
% tableIn: The input data
% formulaNum: The number of the pre-post change formula to use
% levelNum: The number for the level to group the data at for PRE averaging
%
% Outputs:
% tableOut: The table of output data

disp('Calculating pre vs. post change');

if ~exist('formulaNum','var')
    formulaNum = 2;
end

switch formulaNum
    case 1
        formula = @(pre, post) post - pre;
        methodSuffix = 'Diff';
    case 2
        formula = @(pre, post) ((post - pre) / pre) * 100;
        methodSuffix = 'PercDiff';
end

tableOut = table;

preStr = '_PRE_';
postStr = '_POST_';

if ~exist('levelNum','var')
    levelNum = 4; % pre/post & SSV/FV combination
end

colNamesToRemove = {'Name'};
colNames = tableIn.Properties.VariableNames;
scalarColNames = getScalarColumnNames(tableIn);
nonScalarColNames = colNames(~ismember(colNames, scalarColNames));
colNamesToRemove = [colNamesToRemove, nonScalarColNames];
colNames(ismember(colNames, colNamesToRemove)) = [];

preRowsIdx = contains(tableIn.Name, preStr);
preTable = tableIn(preRowsIdx,:);
uniquePreNames = getNamesPrefixes(preTable.Name, levelNum);
%% Average the PRE values in each group
meanPreTableWithPostNames = table;
for i = 1:length(uniquePreNames)
    currPreName = uniquePreNames{i};
    currPreIdx = contains(preTable.Name, currPreName);
    tmpTable = table;
    currPostName = strrep(currPreName, preStr, postStr);
    tmpTable.Name = convertCharsToStrings(currPostName);

    for colNum = 1:length(colNames)
        colName = colNames{colNum};
        currPreData = preTable.(colName)(currPreIdx);
        tmpTable.(colName) = mean(currPreData,'omitnan');
    end
    meanPreTableWithPostNames = [meanPreTableWithPostNames; tmpTable];
end

%% Compute the change values in each group
postRowsIdx = contains(tableIn.Name, postStr);
postTable = tableIn(postRowsIdx,:);
for i = 1:height(postTable)
    tmpTable = table;
    namePostRemoved = strrep(postTable.Name(i), postStr, '_');
    tmpTable.Name = convertCharsToStrings(namePostRemoved);
    currNamePrefix = getNamesPrefixes(postTable.Name(i), levelNum);
    if iscell(currNamePrefix)
        currNamePrefix = currNamePrefix{1};
    end
    currMeanPreRowIdx = ismember(meanPreTableWithPostNames.Name, currNamePrefix);
    assert(sum(currMeanPreRowIdx) == 1);

    for colNum = 1:length(colNames)
        colName = colNames{colNum};
        postValue = postTable.(colName)(i);
        preMeanValue = meanPreTableWithPostNames.(colName)(currMeanPreRowIdx);
        tmpTable.([colName '_' methodSuffix]) = formula(preMeanValue, postValue);
    end
    tableOut = [tableOut; tmpTable];
end