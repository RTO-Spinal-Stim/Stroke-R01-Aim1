function [cellCyclesData] = splitTrialByGaitCycle(structData, left_heel_strike_indices, right_heel_strike_indices)

%% PURPOSE: SPLIT A TRIAL OF XSENS or DELSYS TRIAL TIMESERIES DATA BY GAIT CYCLES.
% Inputs:
%   structData: Struct of data for one trial, each field is one muscle
%   heel_strike_indices: Numeric vector of heel strike indices in the data

fieldNames = fieldnames(structData);
perGaitCycleStruct = struct();
for fieldNum=1:length(fieldNames)
    fieldName = fieldNames{fieldNum};
    if fieldName(1) == 'L'
        perGaitCycleStruct.(fieldName) = splitDataByGaitCycle(structData.(fieldName), left_heel_strike_indices);
    elseif fieldName(1) == 'R'
        perGaitCycleStruct.(fieldName) = splitDataByGaitCycle(structData.(fieldName), right_heel_strike_indices);
    else
        error('Joint name does not begin with L or R');
    end
end

%% Convert this format to be a cell array, and a struct inside each cell array.
cellCyclesData = cell(size(perGaitCycleStruct.(fieldName)));
for cycleNum = 1:length(cellCyclesData)
    currentCycleData = struct;
    for fieldNum = 1:length(fieldNames)
        jointName = fieldNames{fieldNum};
        currentCycleData.(jointName) = perGaitCycleStruct.(jointName){cycleNum};
    end
    cellCyclesData{cycleNum} = currentCycleData;
end
