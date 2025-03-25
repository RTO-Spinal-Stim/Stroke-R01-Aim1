function [tableOut] = addSessionOrder(tableIn, tepsLog, sessionNumberColName, sessionNameColName, tableInColName, colNameToTheLeft)

%% PURPOSE: ADD THE SESSION NUMBER TO THE TABLE.
% Inputs:
% tableIn: The table of input data
% tepsLog: The table listing the subject, session numbers, and session names
% sessionNumberColName: The order in which each session was performed
% sessionNameColName: The name of the session
% tableInColName: The column name of the input data table to get the session name from
% colNameToTheLeft: The column name of the output data table that should be
% the left neighbor of the session order column
%
% Outputs:
% tableOut: The output data table

disp('Adding session order to table');

% Prep the output variable
tableOut = tableIn;
tableOut.(sessionNumberColName) = NaN(height(tableOut),1);

% Remove the unneeded columns from tableIn
allColNames = tableIn.Properties.VariableNames;
removeColNames = allColNames(~ismember(allColNames, {'Subject', tableInColName}));
tableInRemoved = removevars(tableIn, removeColNames);

% Add the session number from each row of the TEPs log.
for i = 1:height(tepsLog)
    tmpTable = table;
    tmpTable.Subject = tepsLog.Subject{i};    
    tmpTable.(tableInColName) = tepsLog.(sessionNameColName){i};

    sessionRowsIdx = ismember(tableInRemoved, tmpTable, 'rows');
    tableOut.(sessionNumberColName)(sessionRowsIdx) = tepsLog.(sessionNumberColName)(i);
end

% Move the sessionNumberColName column to after the specified column
specifiedColIdxNum = find(ismember(allColNames, colNameToTheLeft));

tableOut = [tableOut(:,1:specifiedColIdxNum), tableOut(:,end), tableOut(:,specifiedColIdxNum+1:end-1)];