function [mergedTable] = mergeTables(grTable, cycleTable, colNamesToMergeBy)

%% PURPOSE: MERGE THE GAITRITE TABLE AND CYCLE TABLE.
% Inputs:
% grTable: Each row is one row of the GaitRite data
% cycleTable: Each row is one gait cycle
% colNamesToMergeBy: Cell array of the columns that are being merged (e.g.
% 'GaitRiteRow' and 'Cycle'). The first element is for the grTable, 
% the second element is the column name in the cycleTable.
% NOTE: All of the other factor columns should
% be to the left of the colNamesToMergeBy columns.
%
% Outputs:
% mergedTable: Each row is one gait cycle
%
% NOTE: Removes the first two gait cycles from each trial in the cycleTable
% to match to the grTable

disp('Merging GaitRite and cycle tables');

if height(grTable) <= height(cycleTable)
    error('GaitRite table must have more rows than the cycle table!');
end

% Check the setup of the two tables.
grVarNames = grTable.Properties.VariableNames;
cycleVarNames = cycleTable.Properties.VariableNames;
grColIdx = ismember(grVarNames, colNamesToMergeBy);
cycleColIdx = ismember(cycleVarNames, colNamesToMergeBy);

if ~any(grColIdx) || ~any(cycleColIdx)
    error('Missing the specified colNamesToMergeBy columns in one or both tables');
end

grColIdxNum = find(grColIdx,1);
cycleColIdxNum = find(cycleColIdx,1);

if grColIdxNum ~= cycleColIdxNum
    error('The colNamesToMergeBy are not at the same column number in both tables');
end

if ~isequal(grVarNames(1:grColIdxNum-1), cycleVarNames(1:cycleColIdxNum-1))
    error('The factor column names are not identical');
end

mergedTable = table;

% Identify any column names to the right of the factors that are shared
% across both tables, so we can remove duplicates.
grVarNames = grVarNames(grColIdxNum+1:end);
cycleVarNames = cycleVarNames(cycleColIdxNum+1:end);
sharedVarNames = cycleVarNames(ismember(cycleVarNames, grVarNames));

% Get all of the unique trials from the table.
% trialColsTable = unique(cycleTable(:, 1:cycleColIdxNum-1), 'rows');
trialNames = unique(getNamesPrefixes(cycleTable.Name, 5));
for i = 1:height(trialNames)

    % Isolate only the rows of the current trial in each table
    currTrialIdxGR = contains(grTable.Name, trialNames{i});
    currTrialIdxCycle = contains(cycleTable.Name, trialNames{i});
    currTrialCycle = cycleTable(currTrialIdxCycle, :);
    currTrialGR = grTable(currTrialIdxGR, grColIdxNum+1:end);    

    % Remove the name variable from the cycle table.
    currTrialGR = removevars(currTrialGR, sharedVarNames);

    assert(height(currTrialGR) == height(currTrialCycle) + 2,'Wrong number of gait cycles relative to the number of GaitRite rows! Failed to merge tables.');

    % Horizontally concatenate the two tables so all of the data is in tmpTable.
    tmpTable = [currTrialCycle, currTrialGR(3:end,:)];

    % Vertically concatenate each trial
    mergedTable = [mergedTable; tmpTable];

end