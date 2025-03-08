function [matchedTable] = matchCycles(tableIn, startFootColName)

%% PURPOSE: MATCH THE GAIT CYCLES' DATA TOGETHER
% Inputs:
% tableIn: The table of input data. Each row is one gait cycle's data, and
% the "Name" column should end with "L" or "R" to indicate which side gait
% cycle it is.
% startFootColName: The name of the column to store the L/R lead foot info
%
% Outputs:
% matchedTable: The table used for symmetry analysis, where each row is one
% matched gait cycle.

trialLevelNum = length(strsplit(tableIn.Name(1), '_')) - 2;
trialNamesToMatch = getNamesPrefixes(tableIn.Name, trialLevelNum);
cycleLevelNum = trialLevelNum + 1;
colNames = tableIn.Properties.VariableNames;
colNames(ismember(colNames,'Name')) = [];
matchedTable = table;
% Iterate over each trial
for i = 1:length(trialNamesToMatch)
    matchRows = contains(tableIn.Name, trialNamesToMatch{i});
    filteredTable = tableIn(matchRows,:);    

    % Iterate over each cycle in the trial
    for j = 1:height(filteredTable)-1
        currCycleRow = filteredTable(j,:);
        nextCycleRow = filteredTable(j+1,:);
        currCycleSide = char(currCycleRow.Name);
        currCycleSide = currCycleSide(end);
        nextCycleSide = char(nextCycleRow.Name);
        nextCycleSide = nextCycleSide(end);
        tmpTable = table;
        tmpTable.Name = convertCharsToStrings(getNamesPrefixes(currCycleRow.Name, cycleLevelNum));
        tmpTable.(startFootColName) = currCycleSide;

        % Iterate over each column in the cycle
        for colNum = 1:length(colNames)
            colName = colNames{colNum};
            currColData = filteredTable.(colName)(j);
            if ~isstruct(currColData)
                continue;
            end
            tmpTable.(colName) = struct;
            fldNames = fieldnames(currColData);            
            for fldNum = 1:length(fldNames)
                fldName = fldNames{fldNum};
                if startsWith(fldName, currCycleSide)
                    tmpTable.(colName).(fldName) = currCycleRow.(colName).(fldName);
                elseif startsWith(fldName, nextCycleSide)
                    tmpTable.(colName).(fldName) = nextCycleRow.(colName).(fldName);
                end
            end
        end
        matchedTable = [matchedTable; tmpTable];
    end
end