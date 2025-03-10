function [tableOut] = preprocessGaitRiteOneTrial(gaitRiteConfig, header_row, data)

%% PURPOSE: PREPROCESS ONE PARSED OUT GAITRITE TRIAL
% Inputs:
% gaitRiteConfig: The config struct for GaitRite
% header_row: The cell array of the header row
% data: The cell array of data, without a header row.
%
% tableOut: The processed table of data
%
% NOTE: GaitRite L = 0, R = 1

%% Configuration
Gait_Fs = gaitRiteConfig.SAMPLING_FREQUENCY;

%% Get column indices
colNames = gaitRiteConfig.COLUMN_NAMES;
left_right_idx = ismember(header_row, colNames.LEFT_RIGHT);
heel_on_idx = ismember(header_row, colNames.HEEL_ON);
heel_off_idx = ismember(header_row, colNames.HEEL_OFF);
toe_on_idx = ismember(header_row, colNames.TOE_ON);
toe_off_idx = ismember(header_row, colNames.TOE_OFF);
step_len_idx = ismember(header_row, colNames.STEP_LENGTH);
swing_time_idx = ismember(header_row, colNames.SWING_TIME);
step_times_idx = ismember(header_row, colNames.STEP_TIME);
stance_times_idx = ismember(header_row, colNames.STANCE_TIME);
stride_times_idx = ismember(header_row, colNames.STRIDE_TIME);
stride_lengths_idx = ismember(header_row, colNames.STRIDE_LENGTH);
step_width_idx = ismember(header_row, colNames.STEP_WIDTH);
stride_width_idx = ismember(header_row, colNames.STRIDE_WIDTH);

columnsToConvertZeroToNaN = step_len_idx | swing_time_idx | step_times_idx | ...
    stance_times_idx | stride_times_idx | stride_lengths_idx | step_width_idx | stride_width_idx;
for i = 1:length(columnsToConvertZeroToNaN)
    if columnsToConvertZeroToNaN(i) == 0
        continue;
    end
    zeroIdx = data(:, i) == 0;
    data(zeroIdx, i) = NaN;
end

%% Extract the data
left_right = data(:, left_right_idx);
heel_on = data(:, heel_on_idx);
heel_off = data(:, heel_off_idx);
toe_on = data(:, toe_on_idx);
toe_off = data(:, toe_off_idx);
step_len = data(:, step_len_idx) / 100; % m
swing_durations = data(:, swing_time_idx); % sec
stride_lens = data(:, stride_lengths_idx) / 100; % m
stride_durations = data(:, stride_times_idx); % sec
stance_durations = data(:, stance_times_idx); % sec
step_widths = data(:, step_width_idx) / 100; % m
stride_widths = data(:, stride_width_idx) / 100; % m
step_durations = data(:, step_times_idx); % sec

if any(diff(left_right)==0)
    error('Left and right GaitRite steps are not alternating!');
end

%% Initialize the processed data
num_heel_strikes = length(left_right);
leftStanceStartStopSeconds = zeros(num_heel_strikes - 2, 2);
rightStanceStartStopSeconds = zeros(num_heel_strikes - 2, 2);
leftSwingStartStopSeconds = zeros(num_heel_strikes - 2, 2);
rightSwingStartStopSeconds = zeros(num_heel_strikes - 2, 2);

%% Isolate L & R
left_events_idx = left_right==0; % L = 0
right_events_idx = left_right==1; % R = 1
processed_data.L_Idx = {left_events_idx}; 
processed_data.R_Idx = {right_events_idx};
processed_data.All_Idx = {logical(left_right)}; % L = 0, R = 1
processed_data.L_StepLengths = {step_len(left_events_idx)};
processed_data.R_StepLengths = {step_len(right_events_idx)};
processed_data.All_StepLengths = {step_len};
processed_data.L_SwingDurations = {swing_durations(left_events_idx)};
processed_data.R_SwingDurations = {swing_durations(right_events_idx)};
processed_data.All_SwingDurations = {swing_durations};
processed_data.L_StrideLengths = {stride_lens(left_events_idx)};
processed_data.R_StrideLengths = {stride_lens(right_events_idx)};
processed_data.All_StrideLengths = {stride_lens};
processed_data.L_StanceDurations = {stance_durations(left_events_idx)};
processed_data.R_StanceDurations = {stance_durations(right_events_idx)};
processed_data.All_StanceDurations = {stance_durations};
processed_data.L_StepWidths = {step_widths(left_events_idx)};
processed_data.R_StepWidths = {step_widths(right_events_idx)};
processed_data.All_StepWidths = {step_widths};
processed_data.L_StrideWidths = {stride_widths(left_events_idx)};
processed_data.R_StrideWidths = {stride_widths(right_events_idx)};
processed_data.All_StrideWidths = {stride_widths};
processed_data.L_StepDurations = {step_durations(left_events_idx)};
processed_data.R_StepDurations = {step_durations(right_events_idx)};
processed_data.All_StepDurations = {step_durations};
processed_data.L_StrideDurations = {stride_durations(left_events_idx)};
processed_data.R_StrideDurations = {stride_durations(right_events_idx)};
processed_data.All_StrideDurations = {stride_durations};
processed_data.L_NumFootfalls = sum(left_events_idx);
processed_data.R_NumFootfalls = sum(right_events_idx);
processed_data.All_NumFootfalls = num_heel_strikes;
% A "step" is the interval between subsequent L & R footfalls
if left_events_idx(1) == 1
    numStepsL = sum(left_events_idx) - 1;
    numStepsR = sum(right_events_idx);
elseif right_events_idx(1) == 1
    numStepsL = sum(left_events_idx);
    numStepsR = sum(right_events_idx) - 1;
end
processed_data.L_NumSteps = numStepsL;
processed_data.R_NumSteps = numStepsR;
processed_data.All_NumSteps = numStepsL + numStepsR;
% A "gait cycle" is the interval between subsequent ipsilateral footfalls (e.g. L to L)
numGaitCyclesL = sum(left_events_idx) - 1;
numGaitCyclesR = sum(right_events_idx) - 1;
processed_data.L_NumGaitCycles = numGaitCyclesL;
processed_data.R_NumGaitCycles = numGaitCyclesR;
processed_data.All_NumGaitCycles = numGaitCyclesL + numGaitCyclesR;


%% Gait events (seconds)
leftHeelStrikesSeconds = heel_on(left_events_idx);
leftToeOffsSeconds = toe_off(left_events_idx);
leftHeelOffsSeconds = heel_off(left_events_idx);
leftToeOnsSeconds = toe_on(left_events_idx);

rightHeelStrikesSeconds = heel_on(right_events_idx);
rightToeOffsSeconds = toe_off(right_events_idx);
rightHeeloffsSeconds = heel_off(right_events_idx);
rightToeOnsSeconds = toe_on(right_events_idx);

processed_data.seconds.gaitEvents.leftHeelStrikes = leftHeelStrikesSeconds;
processed_data.seconds.gaitEvents.leftToeOffs = leftToeOffsSeconds;
processed_data.seconds.gaitEvents.leftHeelOffs = leftHeelOffsSeconds;
processed_data.seconds.gaitEvents.leftToeOns = leftToeOnsSeconds;

processed_data.seconds.gaitEvents.rightHeelStrikes = rightHeelStrikesSeconds;
processed_data.seconds.gaitEvents.rightToeOffs = rightToeOffsSeconds;
processed_data.seconds.gaitEvents.rightHeeloffs = rightHeeloffsSeconds;
processed_data.seconds.gaitEvents.rightToeOns = rightToeOnsSeconds;

%% Gait phases start & stop (seconds)
for i = 1:length(left_right)-2
    if left_right(i) == 0
        leftStanceStartStopSeconds(i,:) = [heel_on(i), toe_off(i)];
        leftSwingStartStopSeconds(i,:) = [toe_off(i), heel_on(i+2)];
    else
        rightStanceStartStopSeconds(i,:) = [heel_on(i), toe_off(i)];
        rightSwingStartStopSeconds(i,:) = [toe_off(i), heel_on(i+2)];
    end
end

% Remove the zero rows.
leftZeroRows = all(leftStanceStartStopSeconds == 0, 2);
rightZeroRows = all(rightStanceStartStopSeconds == 0,2);
leftStanceStartStopSeconds(leftZeroRows, :) = [];
rightStanceStartStopSeconds(rightZeroRows, :) = [];
leftSwingStartStopSeconds(leftZeroRows, :) = [];
rightSwingStartStopSeconds(rightZeroRows, :) = [];

processed_data.seconds.gaitPhases.leftStanceStartStop = leftStanceStartStopSeconds;
processed_data.seconds.gaitPhases.rightStanceStartStop = rightStanceStartStopSeconds;
processed_data.seconds.gaitPhases.leftSwingStartStop = leftSwingStartStopSeconds;
processed_data.seconds.gaitPhases.rightSwingStartStop = rightSwingStartStopSeconds;

%% Gait phase durations (seconds)
% 2/20 MT commented out because this is already computed above.
% QUESTION: Should it continue to be included here so I can get durations in frame numbers?
% leftStanceDurationsSeconds = leftStanceStartStopSeconds(:,2)-leftStanceStartStopSeconds(:,1);
% rightStanceDurationsSeconds = rightStanceStartStopSeconds(:,2)-rightStanceStartStopSeconds(:,1);
% leftSwingDurationsSeconds = leftSwingStartStopSeconds(:,2)-leftSwingStartStopSeconds(:,1);
% rightSwingDurationsSeconds = rightSwingStartStopSeconds(:,2)-rightSwingStartStopSeconds(:,1);
% 
% processed_data.seconds.gaitPhasesDurations.leftStanceDurations = leftStanceDurationsSeconds;
% processed_data.seconds.gaitPhasesDurations.rightStanceDurations = rightStanceDurationsSeconds;
% processed_data.seconds.gaitPhasesDurations.leftSwingDurations = leftSwingDurationsSeconds;
% processed_data.seconds.gaitPhasesDurations.rightSwingDurations = rightSwingDurationsSeconds;

%% Convert all times from seconds to GaitRite frames.
processed_data.frames = getHardwareIndicesFromSeconds(processed_data.seconds, Gait_Fs);

tableOut = struct2table(processed_data);

end