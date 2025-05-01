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

existingCategoricalVarNames = existingTable.Properties.VariableNames(vartype('categorical'));
newCategoricalVarNames = newTable.Properties.VariableNames(vartype('categorical'));

%% If the "Name" entries are different but all column names are the same, vertically concatenate.
if all(ismember(existingVarNames, newVarNames)) && length(existingVarNames) == length(newVarNames)
    if isequal(existingCategoricalVarNames, newCategoricalVarNames)
        mergedTable = [existingTable; newTable];
        return;
    end
end

categoricalVars = existingCategoricalVarNames;

%% Otherwise, perform the horizontal concatenation
assert(height(newTable) == height(existingTable),'Both tables must have the same number of rows for horizontal concatenation!');
mergedTable = join(newTable, existingTable, 'Keys', categoricalVars, ...
        'LeftVariables', newVarNames, ...
        'RightVariables', setdiff(existingVarNames, categoricalVars),...
        'KeepOneCopy', newVarNames);

newVarNamesToAdd = setdiff(newVarNames, categoricalVars);
finalColumnOrder = [existingVarNames, setdiff(newVarNamesToAdd, existingVarNames)];
mergedTable = mergedTable(:, finalColumnOrder);

for colNum = 1:length(categoricalVars)
    mergedTable.(categoricalVars{colNum}) = string(mergedTable.(categoricalVars{colNum}));
    mergedTable.(categoricalVars{colNum}) = categorical(mergedTable.(categoricalVars{colNum}));
end