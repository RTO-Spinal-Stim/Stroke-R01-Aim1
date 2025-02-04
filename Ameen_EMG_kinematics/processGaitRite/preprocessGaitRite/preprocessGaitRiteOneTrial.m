function [tableOut] = preprocessGaitRiteOneTrial(gaitRiteConfig, header_row, data)

%% PURPOSE: PREPROCESS ONE PARSED OUT GAITRITE TRIAL

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

%% Extract the data
left_right = data(:, left_right_idx);
heel_on = data(:, heel_on_idx);
heel_off = data(:, heel_off_idx);
toe_on = data(:, toe_on_idx);
toe_off = data(:, toe_off_idx);
step_len = data(:, step_len_idx) / 100; % m
swing_times = data(:, swing_time_idx); % sec
stride_lens = data(:, stride_lengths_idx) / 100; % m
stride_times = data(:, stride_times_idx); % sec
stance_times = data(:, stance_times_idx); % sec
step_widths = data(:, step_width_idx) / 100; % m
stride_widths = data(:, stride_width_idx) / 100; % m
step_times = data(:, step_times_idx); % sec

%% Initialize the processed data
num_steps = length(left_right);
leftStanceStartStopSeconds = zeros(num_steps - 2, 2);
rightStanceStartStopSeconds = zeros(num_steps - 2, 2);
leftSwingStartStopSeconds = zeros(num_steps - 2, 2);
rightSwingStartStopSeconds = zeros(num_steps - 2, 2);

stepLenSym = NaN(num_steps - 2, 1);
swingTimeSym = NaN(num_steps - 3, 1);

%% Step length symmetry
for i = 2:length(left_right)-1
    stepLenSym(i-1) = (2*abs(step_len(i)-step_len(i+1)))/(step_len(i)+step_len(i+1));
end

processed_data.stepLengthSymmetries = {stepLenSym};

%% Swing time symmetry
for i = 3:length(left_right)-1
    swingTimeSym(i-2) = (2*abs(swing_times(i)-swing_times(i+1)))/(swing_times(i)+swing_times(i+1));
end

processed_data.swingTimeSymmetries = {swingTimeSym};

%% Isolate L & R
left_events_idx = left_right==1;
right_events_idx = left_right==0;
processed_data.stepLengths.L = step_len(left_events_idx);
processed_data.stepLengths.R = step_len(right_events_idx);
processed_data.stepLengths.All = step_len;
processed_data.swingTimes.L = swing_times(left_events_idx);
processed_data.swingTimes.R = swing_times(right_events_idx);
processed_data.swingTimes.All = swing_times;
processed_data.strideLengths.L = stride_lens(left_events_idx);
processed_data.strideLengths.R = stride_lens(right_events_idx);
processed_data.strideLengths.All = stride_lens;
processed_data.stanceTimes.L = stance_times(left_events_idx);
processed_data.stanceTimes.R = stance_times(right_events_idx);
processed_data.stanceTimes.All = stance_times;
processed_data.stepWidths.L = step_widths(left_events_idx);
processed_data.stepWidths.R = step_widths(right_events_idx);
processed_data.stepWidths.All = step_widths;
processed_data.strideWidths.L = stride_widths(left_events_idx);
processed_data.strideWidths.R = stride_widths(right_events_idx);
processed_data.strideWidths.All = stride_widths;
processed_data.stepTimes.L = step_times(left_events_idx);
processed_data.stepTimes.R = step_times(right_events_idx);
processed_data.stepTimes.All = step_times;
processed_data.strideTimes.L = stride_times(left_events_idx);
processed_data.strideTimes.R = stride_times(right_events_idx);
processed_data.strideTimes.All = stride_times;


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
leftStanceDurationsSeconds = leftStanceStartStopSeconds(:,2)-leftStanceStartStopSeconds(:,1);
rightStanceDurationsSeconds = rightStanceStartStopSeconds(:,2)-rightStanceStartStopSeconds(:,1);
leftSwingDurationsSeconds = leftSwingStartStopSeconds(:,2)-leftSwingStartStopSeconds(:,1);
rightSwingDurationsSeconds = rightSwingStartStopSeconds(:,2)-rightSwingStartStopSeconds(:,1);

processed_data.seconds.gaitPhasesDurations.leftStanceDurations = leftStanceDurationsSeconds;
processed_data.seconds.gaitPhasesDurations.rightStanceDurations = rightStanceDurationsSeconds;
processed_data.seconds.gaitPhasesDurations.leftSwingDurations = leftSwingDurationsSeconds;
processed_data.seconds.gaitPhasesDurations.rightSwingDurations = rightSwingDurationsSeconds;

%% Convert all times from seconds to GaitRite frames.
processed_data.frames = getHardwareIndicesFromSeconds(processed_data.seconds, Gait_Fs);

tableOut = struct2table(processed_data);

end