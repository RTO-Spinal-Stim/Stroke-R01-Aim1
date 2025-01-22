function [data_by_gait_cycle] = splitDataByGaitCycle(data, heel_strike_indices)

%% PURPOSE: SPLIT A SIGNAL BY GAIT CYCLES.
% Inputs:
%   data: Numeric vector of data for one trial
%   heel_strike_indices: Numeric vector of heel strike indices in the data
% Outputs:
%   data_by_gait_cycle: Cell array, where each cell is one gait cycle's
%   data.

num_gait_cycles = length(heel_strike_indices) - 1;
data_by_gait_cycle = cell(num_gait_cycles,1);

for i = 1:num_gait_cycles
    data_by_gait_cycle{i} = data(heel_strike_indices(i):heel_strike_indices(i+1)-1);
end