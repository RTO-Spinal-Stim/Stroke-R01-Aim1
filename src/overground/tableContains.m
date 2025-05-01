function [matchIdx] = tableContains(tableWithMoreColumns, tableWithFewerColumns)

%% PURPOSE: RETURN THE ROWS WHERE ALL THE VALUES OF THE TABLE WITH FEWER COLUMNS ARE FOUND IN THE TABLE WITH MORE COLUMNS.

% Using innerjoin with specific keys
matchTable = innerjoin(tableWithMoreColumns, tableWithFewerColumns, 'Keys', tableWithFewerColumns.Properties.VariableNames);

matchIdx = ismember(tableWithMoreColumns, matchTable, 'rows');