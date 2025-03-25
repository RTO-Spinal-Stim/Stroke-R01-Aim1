function [mergedTable] = addToTable(existingTable, newTable)

%% PURPOSE: ADD THE NEW TABLE IN TO THE EXISTING TABLE USING A LEFT JOIN
% https://www.mathworks.com/help/matlab/ref/table.join.html
% Inputs:
% existingTable: The table for which columns are being added
% newTable: The table to add the columns from
%
% Outputs:
% mergedTable: The merged table

% %% First, try just vertically concatenating the table.
% try
%     tableOut = [existingTable; newTable];
%     return;
% catch
% end

if height(existingTable) == 0
    mergedTable = newTable;
    return;
end

existingVarNames = existingTable.Properties.VariableNames;
newVarNames = newTable.Properties.VariableNames;

%% If the "Name" entries are different but all column names are the same, vertically concatenate.
if all(ismember(existingVarNames, newVarNames)) && length(existingVarNames) == length(newVarNames)
    if ~any(ismember(newTable.Name, existingTable.Name))
        mergedTable = [existingTable; newTable];
        return;
    end
end

%% Otherwise, perform the horizontal concatenation
assert(height(newTable) == height(existingTable),'Both tables must have the same number of rows!');
mergedTable = join(newTable, existingTable, 'Keys', 'Name', ...
        'LeftVariables', newVarNames, ...
        'RightVariables', setdiff(existingVarNames, 'Name'),...
        'KeepOneCopy', newVarNames);

newVarNamesToAdd = setdiff(newVarNames, 'Name');
finalColumnOrder = [existingVarNames, setdiff(newVarNamesToAdd, existingVarNames)];
mergedTable = mergedTable(:, finalColumnOrder);