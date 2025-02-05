function [perGaitCycleStruct, maxNumCycles] = splitTrialByGaitCycle(structData, left_heel_strike_indices, right_heel_strike_indices)

%% PURPOSE: SPLIT A TRIAL OF XSENS or DELSYS TRIAL TIMESERIES DATA BY GAIT CYCLES.
% Inputs:
%   structData: Struct of data for one trial, each field is one signal
%   heel_strike_indices: Numeric vector of heel strike indices in the data

fieldNames = fieldnames(structData);
perGaitCycleStruct = struct();
maxNumCycles = 0;
for fieldNum=1:length(fieldNames)
    fieldName = fieldNames{fieldNum};
    if fieldName(1) == 'L'
        perGaitCycleStruct.(fieldName) = splitDataByGaitCycle(structData.(fieldName), left_heel_strike_indices);
    elseif fieldName(1) == 'R'
        perGaitCycleStruct.(fieldName) = splitDataByGaitCycle(structData.(fieldName), right_heel_strike_indices);
    else
        error('Joint name does not begin with L or R');
    end
    maxNumCycles = max([maxNumCycles, length(perGaitCycleStruct.(fieldName))]);
end

% %% Convert this format to be a cell array, and a struct inside each cell array.
% cellCyclesData = cell(maxNumCycles, 1);
% for cycleNum = 1:maxNumCycles
%     currentCycleData = struct;
%     for fieldNum = 1:length(fieldNames)
%         jointName = fieldNames{fieldNum};
%         if length(perGaitCycleStruct.(jointName)) >= cycleNum
%             currentCycleData.(jointName) = perGaitCycleStruct.(jointName){cycleNum};
%         else
%             currentCycleData.(jointName) = []; % For when number of L & R gait cycles are mismatching
%         end
%     end
%     cellCyclesData{cycleNum} = currentCycleData;
% end
