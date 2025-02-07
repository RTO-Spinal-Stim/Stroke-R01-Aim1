function [tableOut] = addToTable(existingTable, newTable)

%% PURPOSE: ADD THE NEW TABLE IN TO THE EXISTING TABLE.
% FIRST, ATTEMPTS VERTICAL CONCATENATION.
% IF THAT FAILS, ATTEMPTS AN OUTER JOIN.

%% First, try just vertically concatenating the table.
try
    tableOut = [existingTable; newTable];
    return;
catch
end

% tableOut = outerjoin(existingTable, newTable, 'Keys','Name','MergeKeys',true);

%%%%%%% NEW %%%%%%%%

%% Next, perform an outer join.
newTableVarNames = newTable.Properties.VariableNames;
existingTableVarNames = newTable.Properties.VariableNames;

% Find matching columns
matchingCols = intersect(existingTableVarNames, newTableVarNames);
numMatches = length(matchingCols);

% if numMatches == 1
tableOut = outerjoin(existingTable, newTable, 'Keys', 'Name', ...
    'MergeKeys', true);
return;
% end

% Case 3: Multiple but not all columns match
if numMatches > 1
    % Method: Use all matching columns as keys for the join
    tableOut = outerjoin(existingTable, newTable, 'Keys', matchingCols, ...
        'MergeKeys', true);

    % For non-key columns that appear in both tables (causing _existingTable and _newTable suffixes)
    % we need to decide which one to keep or how to merge them
    oldNames = tableOut.Properties.VariableNames;

    % Find pairs of columns that need to be merged
    for colName = setdiff(existingTableVarNames, matchingCols)
        existingColName = [colName '_existingTable'];
        newColName = [colName '_newTable'];

        % Check if both columns exist (meaning this column was in both tables but wasn't a key)
        if ismember(existingColName, oldNames) && ismember(newColName, oldNames)
            % Here you need to decide how to handle duplicate columns
            % Option 1: Keep existing table's values, fill in with new table's values where missing
            tableOut.(colName) = coalesce(tableOut.(existingColName), ...
                tableOut.(newColName));

            % Remove the original columns
            tableOut = removevars(tableOut, {existingColName, newColName});
        elseif ismember(existingColName, oldNames)
            % If only existing column is present, rename it
            tableOut = renamevars(tableOut, existingColName, colName);
        elseif ismember(newColName, oldNames)
            % If only new column is present, rename it
            tableOut = renamevars(tableOut, newColName, colName);
        end
    end
else
    % No matching columns - could throw error or handle differently
    error('No matching columns found between tables');
end

% novelVarNames = newTableVarNames(ismember(newTableVarNames, existingTableVarNames));
% 
% tableOut = outerjoin(existingTable, newTable, 'Keys','Name','MergeKeys',true);

end

% Helper function to coalesce two columns
function result = coalesce(col1, col2)
    result = col1;
    result(ismissing(result)) = col2(ismissing(result));
end