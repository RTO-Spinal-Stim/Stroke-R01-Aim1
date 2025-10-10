function [tableOut] = maxEMGValuePerVisit(dataTable, emgColName, maxEMGColName, mvcMuscleMapping)

%% PURPOSE: FIND THE MAX EMG PER MUSCLE
% Inputs:
% dataTable: Table where each row is one trial or gait cycle.
% emgColName: The column name for the EMG data.
% mvcMuscleMapping: Struct, where each field is the tested muscle group in
% the MVC file name, and the values are the relevant muscle names in EMG data.
%
% Outputs:
% maxEMGTable: The table of max EMG values. Each row is one visit.

catTable = copyCategorical(dataTable);

disp('Getting the max EMG value per muscle per visit');

%% Get the unique visit names.
uniqueVisitsTable = unique(catTable(:, 1:2), 'rows', 'stable');
tableOut = uniqueVisitsTable;

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
        motion = char(currDataTable.('Muscle')(i));
        if ~isfield(mvcMuscleMapping, motion)
            continue; % Not all MVC trials are used to define EMG max
        end
        muscleNames = mvcMuscleMapping.(motion);
        if ~iscell(muscleNames)
            muscleNames = {muscleNames};
        end
        % For each muscle, check if the max value in this trial is larger
        % than any prior trial.
        for muscleNum = 1:length(muscleNames)
            muscleName = muscleNames{muscleNum};
            maxEMGStruct.(muscleName) = max([ maxEMGStruct.(muscleName), max(emgData.(muscleName)) ], [], 2, 'omitnan');            
        end
    end
    tableOut.(maxEMGColName)(visitNum) = maxEMGStruct;
end