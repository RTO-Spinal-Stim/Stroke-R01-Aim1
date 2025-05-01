function [maxEMGTable] = maxEMGValuePerVisit(dataTable, emgColName, maxEMGColName)

%% PURPOSE: FIND THE MAX EMG PER MUSCLE
% Inputs:
% dataTable: Table where each row is one trial or gait cycle.
% emgColName: The column name for the EMG data.
%
% Outputs:
% maxEMGTable: The table of max EMG values. Each row is one visit.

maxEMGTable = copyCategorical(dataTable);

disp('Getting the max EMG value per muscle per visit');

%% Get the unique visit names.
visitNames = getNamesPrefixes(dataTable.Name, 2);
for visitNum = 1:length(visitNames)
    visitName = visitNames{visitNum};
    % Initialize the max EMG struct.
    maxEMGStruct = struct;
    fieldNames = fieldnames(dataTable.(emgColName)(1));
    for fieldNum = 1:length(fieldNames)
        fieldName = fieldNames{fieldNum};
        maxEMGStruct.(fieldName) = NaN;
    end
    % Iterate over each trial
    for i = 1:height(dataTable)
        if ~contains(dataTable.Name(i), visitName)
            continue; % Ensure that only the current visit is being processed
        end
        emgData = dataTable.(emgColName)(i);
        % For each muscle, check if the max value in this trial is larger
        % than any prior trial.
        for fieldNum = 1:length(fieldNames)
            fieldName = fieldNames{fieldNum};
            maxEMGStruct.(fieldName) = max([ maxEMGStruct.(fieldName),max(emgData.(fieldName)) ], [], 2, 'omitnan');            
        end
    end
    maxEMGTable.(maxEMGColName)(i) = maxEMGStruct;
end