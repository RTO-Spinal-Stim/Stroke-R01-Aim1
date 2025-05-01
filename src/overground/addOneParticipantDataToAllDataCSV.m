function [] = addOneParticipantDataToAllDataCSV(participantTable, allDataTablePath)

%% PURPOSE: ADD ONE PARTICIPANT'S DATA TO THE CSV FILE WITH ALL PARTICIPANT'S DATA.
% Inputs:
% participantTable: The table of one participant's data
% allDataTablePath: The path to the CSV file

% Load the table of all the data
if isfile(allDataTablePath)
    allDataTable = readtable(allDataTablePath);
else
    allDataTable = table;
end

% Remove the non-scalar column names
scalarColumnNames = getScalarColumnNames(participantTable);
scalarColumnNames = unique([{'Name'}; scalarColumnNames], 'stable');
participantTableScalar = removevars(participantTable, ~ismember(participantTable.Properties.VariableNames, scalarColumnNames));

% Remove the data that already exists that's being overwritten.
if height(allDataTable) > 0
    existingNameRowsIdx = ismember(allDataTable.Name, participantTableScalar.Name);
    allDataTable(existingNameRowsIdx,:) = [];
end

% Append the participant data to the all data table
allDataTable = addToTable(allDataTable, participantTableScalar);

% Write the table back to the CSV
writetable(allDataTable, allDataTablePath);