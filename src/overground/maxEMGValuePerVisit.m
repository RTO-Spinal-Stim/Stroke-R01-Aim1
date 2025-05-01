function [tableOut] = maxEMGValuePerVisit(dataTable, emgColName, maxEMGColName)

%% PURPOSE: FIND THE MAX EMG PER MUSCLE
% Inputs:
% dataTable: Table where each row is one trial or gait cycle.
% emgColName: The column name for the EMG data.
%
% Outputs:
% maxEMGTable: The table of max EMG values. Each row is one visit.

catTable = copyCategorical(dataTable);

disp('Getting the max EMG value per muscle per visit');

%% Get the unique visit names.
uniqueVisitsTable = unique(catTable(:, 1:2), 'rows', 'stable');
tableOut = uniqueVisitsTable;
% visitNames = getNamesPrefixes(dataTable.Name, 2);
for visitNum = 1:height(uniqueVisitsTable)
    visitRow = uniqueVisitsTable(visitNum,:);
    % Initialize the max EMG struct.
    maxEMGStruct = struct;
    fieldNames = fieldnames(dataTable.(emgColName)(visitNum));
    for fieldNum = 1:length(fieldNames)
        fieldName = fieldNames{fieldNum};
        maxEMGStruct.(fieldName) = NaN;
    end
    visitRowsIdx = tableContains(dataTable, visitRow);
    currDataTable = dataTable(visitRowsIdx, :);
    % Iterate over each trial
    for i = 1:height(currDataTable)
        emgData = currDataTable.(emgColName)(i);
        % For each muscle, check if the max value in this trial is larger
        % than any prior trial.
        for fieldNum = 1:length(fieldNames)
            fieldName = fieldNames{fieldNum};
            maxEMGStruct.(fieldName) = max([ maxEMGStruct.(fieldName), max(emgData.(fieldName)) ], [], 2, 'omitnan');            
        end
    end
    tableOut.(maxEMGColName)(visitNum) = maxEMGStruct;
end