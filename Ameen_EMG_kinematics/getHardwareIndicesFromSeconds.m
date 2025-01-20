function [indicesStruct] = getHardwareIndicesFromSeconds(secondsStruct, fs)

%% PURPOSE: CONVERT A STRUCT OF GAIT EVENTS, GAIT PHASE ONSET & TERMINATION, AND GAIT PHASE DURATIONS FROM SECONDS TO 
% secondsStruct fields: gaitEvents, gaitPhases, gaitPhasesDurations

indicesStruct = struct;
secondsStructFieldNames = fieldnames(secondsStruct);
for i = 1:length(secondsStructFieldNames)
    fieldName = secondsStructFieldNames{i};
    indicesStruct.(fieldName) = struct;

    subFieldNames = fieldnames(secondsStruct.(fieldName));
    for j = 1:length(subFieldNames)
        subFieldName = subFieldNames{j};
        indicesStruct.(fieldName).(subFieldName) = secondsStruct.(fieldName).(subFieldName) .* fs;
    end

end