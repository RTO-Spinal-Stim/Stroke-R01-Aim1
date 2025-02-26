function [columnNamesL, columnNamesR] = getLRColNames(tableIn)

%% PURPOSE: GET THE L & R COLUMN NAMES. THE COLUMN NAMES SHOULD START WITH L OR R, AND THE REST OF IT SHOULD BE MATCHING.
% Inputs:
% tableIn: The table to get the column names from. Can also be a cell array
% of column names
%
% Outputs:
% columnNamesL: The column names for the left side
% columnNamesR: The column names for the right side

if istable(tableIn)
    columnNames = tableIn.Properties.VariableNames;
elseif iscell(tableIn)
    columnNames = tableIn;
else
    error('What input is this?');
end

colNamesLongerThan3 = {};
for i = 1:length(columnNames)
    if length(columnNames{i}) > 2
        colNamesLongerThan3 = [colNamesLongerThan3; columnNames(i)];
    end
end


columnNamesL = {};
columnNamesR = {};
doneColNameSuffixes = {};
for i = 1:length(colNamesLongerThan3)
    colNameSuffix = colNamesLongerThan3{i}(3:end);
    if sum(contains(colNamesLongerThan3, colNameSuffix)) == 2 && ~ismember(colNameSuffix, doneColNameSuffixes)
        % Check that both matching column names start with L or R
        matchingColNames = colNamesLongerThan3(contains(colNamesLongerThan3, colNameSuffix));
        if sum(startsWith(matchingColNames,'L_'))==1 && sum(startsWith(matchingColNames,'R_')==1)
            doneColNameSuffixes = [doneColNameSuffixes; {colNameSuffix}];
            tmpL = ['L_' colNameSuffix];
            tmpR = ['R_' colNameSuffix];
            columnNamesL = [columnNamesL; {tmpL}];
            columnNamesR = [columnNamesR; {tmpR}];
        end
    end
end