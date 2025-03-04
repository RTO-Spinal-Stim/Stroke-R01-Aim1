function [maxEMGTable] = maxEMGValuePerVisit(dataTable, emgColName, maxEMGColName)

%% PURPOSE: FIND THE MAX EMG PER MUSCLE
% Inputs:
% dataTable: Table where each row is one trial or gait cycle.
% emgColName: The column name for the EMG data.
%
% Outputs:
% maxEMGTable: The table of max EMG values. Each row is one visit.

maxEMGTable = table;

disp('Getting the max EMG value per muscle per visit');

%% Get the unique visit names.
visitNames = getNamesPrefixes(dataTable.Name, 2);
for visitNum = 1:length(visitNames)
    visitName = visitNames{visitNum};
    maxEMGStruct = struct;
    tmpTable = table;
    for i = 1:height(dataTable)
        if ~contains(dataTable.Name(i), visitName)
            continue;
        end
        emgData = dataTable.(emgColName)(i);
        fieldNames = fieldnames(emgData);
        % Initialize the max EMG struct.
        if isempty(fieldnames(maxEMGStruct))
            maxEMGStruct = struct;     
            for fieldNum = 1:length(fieldNames)
                fieldName = fieldNames{fieldNum};
                maxEMGStruct.(fieldName) = -inf;
            end
        end
        for fieldNum = 1:length(fieldNames)
            fieldName = fieldNames{fieldNum};
            maxEMGStruct.(fieldName) = max([maxEMGStruct.(fieldName), max(emgData.(fieldName))]);
        end
    end
    tmpTable.Name = convertCharsToStrings(visitName);
    tmpTable.(maxEMGColName) = maxEMGStruct;
    maxEMGTable = [maxEMGTable; tmpTable];
end