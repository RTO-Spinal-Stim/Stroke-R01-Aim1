function [perGaitCycleStruct, maxNumCycles] = splitTrialByGaitCycleMatchingLR(structData, left_heel_strike_indices, right_heel_strike_indices)

%% PURPOSE: SPLIT A TRIAL OF TIMESERIES DATA BY GAIT CYCLES. MATCHES L & R SIDE DATA FROM L & R GAIT CYCLES TOGETHER INTO ONE GAIT CYCLE.
% Inputs:
% structData: Struct of data for one trial, each field is one signal
% left_heel_strike_indices: Numeric vector of left heel strike indices in the data
% right_heel_strike_indices: Numeric vector of right heel strike indices in the data
% 
% Outputs:
% perGaitCycleStruct: The struct of data split by gait cycle
% maxNumCycles: Scalar double of the maximum number of gait cycles found
%
% NOTE: The data that is split into gait cycles is already staggered by L &
% R gait cycles. Therefore, gait cycle 1's L data is between the first two
% L heel strikes, and gait cycle 1's R data is between the first two R heel
% strikes.

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
