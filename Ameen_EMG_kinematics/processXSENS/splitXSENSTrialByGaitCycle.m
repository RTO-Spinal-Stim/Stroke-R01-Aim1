function [perGaitCycleStruct] = splitXSENSTrialByGaitCycle(structData, left_heel_strike_indices, right_heel_strike_indices)

%% PURPOSE: SPLIT A TRIAL OF XSENS JOINT ANGLE DATA BY GAIT CYCLES.
% Inputs:
%   structData: Struct of data for one trial, each field is one muscle
%   heel_strike_indices: Numeric vector of heel strike indices in the data

jointNames = fieldnames(structData);
perGaitCycleStruct = struct();
for fieldNum=1:length(jointNames)
    joint = jointNames{fieldNum};
    if joint(1) == 'L'
        perGaitCycleStruct.(joint) = splitDataByGaitCycle(structData.(joint), left_heel_strike_indices);
    elseif joint(1) == 'R'
        perGaitCycleStruct.(joint) = splitDataByGaitCycle(structData.(joint), right_heel_strike_indices);
    else
        error('Joint name does not begin with L or R');
    end
end