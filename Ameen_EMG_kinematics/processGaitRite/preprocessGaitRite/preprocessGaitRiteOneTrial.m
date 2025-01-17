function [processed_data] = preprocessGaitRiteOneTrial(gaitRiteConfig, header_row, data)

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

%% Extract the data
left_right = data(:, left_right_idx);
heel_on = data(:, heel_on_idx);
heel_off = data(:, heel_off_idx);
toe_on = data(:, toe_on_idx);
toe_off = data(:, toe_off_idx);
step_len = data(:, step_len_idx);
swing_time = data(:, swing_time_idx);

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

processed_data.stepLengthSymmetries = stepLenSym;

%% Swing time symmetry
for i = 3:length(left_right)-1
    swingTimeSym(i-2) = (2*abs(swing_time(i)-swing_time(i+1)))/(swing_time(i)+swing_time(i+1));
end

processed_data.swingTimeSymmetries = swingTimeSym;

%% Gait events (seconds)
left_events_idx = left_right==1;
right_events_idx = left_right==0;

leftHeelStrikesSeconds = heel_on(left_events_idx);
leftToeOffsSeconds = toe_off(left_events_idx);
leftHeelOffsSeconds = heel_off(left_events_idx);
leftToeOnsSeconds = toe_on(left_events_idx);

rightHeelStrikesSeconds = heel_on(right_events_idx);
rightToeOffsSeconds = toe_off(right_events_idx);
rightHeeloffsSeconds = heel_off(right_events_idx);
rightToeOnsSeconds = toe_on(right_events_idx);

processed_data.gaitEvents.seconds.leftHeelStrikes = leftHeelStrikesSeconds;
processed_data.gaitEvents.seconds.leftToeOffs = leftToeOffsSeconds;
processed_data.gaitEvents.seconds.leftHeelOffs = leftHeelOffsSeconds;
processed_data.gaitEvents.seconds.leftToeOns = leftToeOnsSeconds;

processed_data.gaitEvents.seconds.rightHeelStrikes = rightHeelStrikesSeconds;
processed_data.gaitEvents.seconds.rightToeOffs = rightToeOffsSeconds;
processed_data.gaitEvents.seconds.rightHeeloffs = rightHeeloffsSeconds;
processed_data.gaitEvents.seconds.rightToeOns = rightToeOnsSeconds;

%% Gait events (frames)
leftHeelStrikesFrames = leftHeelStrikesSeconds * Gait_Fs;
leftToeOffsFrames = leftToeOffsSeconds * Gait_Fs;
leftHeelOffsFrames = leftHeelOffsSeconds * Gait_Fs;
leftToeOnsFrames = leftToeOnsSeconds * Gait_Fs;

rightHeelStrikesFrames = rightHeelStrikesSeconds * Gait_Fs;
rightToeOffsFrames = rightToeOffsSeconds * Gait_Fs;
rightHeeloffsFrames = rightHeeloffsSeconds * Gait_Fs;
rightToeOnsFrames = rightToeOnsSeconds * Gait_Fs;

processed_data.gaitEvents.frames.leftHeelStrikes = leftHeelStrikesFrames;
processed_data.gaitEvents.frames.leftToeOffs = leftToeOffsFrames;
processed_data.gaitEvents.frames.leftHeelOffs = leftHeelOffsFrames;
processed_data.gaitEvents.frames.leftToeOns = leftToeOnsFrames;

processed_data.gaitEvents.frames.rightHeelStrikes = rightHeelStrikesFrames;
processed_data.gaitEvents.frames.rightToeOffs = rightToeOffsFrames;
processed_data.gaitEvents.frames.rightHeeloffs = rightHeeloffsFrames;
processed_data.gaitEvents.frames.rightToeOns = rightToeOnsFrames;

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

processed_data.gaitPhases.seconds.leftStanceStartStop = leftStanceStartStopSeconds;
processed_data.gaitPhases.seconds.rightStanceStartStop = rightStanceStartStopSeconds;
processed_data.gaitPhases.seconds.leftSwingStartStop = leftSwingStartStopSeconds;
processed_data.gaitPhases.seconds.rightSwingStartStop = rightSwingStartStopSeconds;

%% Gait phases start & stop (frames)
leftStanceStartStopFrames = leftStanceStartStopSeconds * Gait_Fs;
rightStanceStartStopFrames = rightStanceStartStopSeconds * Gait_Fs;
leftSwingStartStopFrames = leftSwingStartStopSeconds * Gait_Fs;
rightSwingStartStopFrames = rightSwingStartStopSeconds * Gait_Fs;

processed_data.gaitPhases.frames.leftStanceStartStop = leftStanceStartStopFrames;
processed_data.gaitPhases.frames.rightStanceStartStop = rightStanceStartStopFrames;
processed_data.gaitPhases.frames.leftSwingStartStop = leftSwingStartStopFrames;
processed_data.gaitPhases.frames.rightSwingStartStop = rightSwingStartStopFrames;

%% Gait phase durations (seconds)
leftStanceDurationsSeconds = leftStanceStartStopSeconds(:,2)-leftStanceStartStopSeconds(:,1);
rightStanceDurationsSeconds = rightStanceStartStopSeconds(:,2)-rightStanceStartStopSeconds(:,1);
leftSwingDurationsSeconds = leftSwingStartStopSeconds(:,2)-leftSwingStartStopSeconds(:,1);
rightSwingDurationsSeconds = rightSwingStartStopSeconds(:,2)-rightSwingStartStopSeconds(:,1);

processed_data.gaitPhasesDurations.seconds.leftStanceDurations = leftStanceDurationsSeconds;
processed_data.gaitPhasesDurations.seconds.rightStanceDurations = rightStanceDurationsSeconds;
processed_data.gaitPhasesDurations.seconds.leftSwingDurations = leftSwingDurationsSeconds;
processed_data.gaitPhasesDurations.seconds.rightSwingDurations = rightSwingDurationsSeconds;

%% Gait phase durations (frames)
leftStanceDurationsFrames = leftStanceDurationsSeconds * Gait_Fs;
rightStanceDurationsFrames = rightStanceDurationsSeconds * Gait_Fs;
leftSwingDurationsFrames = leftSwingDurationsSeconds * Gait_Fs;
rightSwingDurationsFrames = rightSwingDurationsSeconds * Gait_Fs;

processed_data.gaitPhasesDurations.frames.leftStanceDurations = leftStanceDurationsFrames;
processed_data.gaitPhasesDurations.frames.rightStanceDurations = rightStanceDurationsFrames;
processed_data.gaitPhasesDurations.frames.leftSwingDurations = leftSwingDurationsFrames;
processed_data.gaitPhasesDurations.frames.rightSwingDurations = rightSwingDurationsFrames;

%% Previously exported variables. This is being ported elsewhere.
% 'leftStanceEMG', leftStanceEMG, ...
% 'rightStanceEMG', rightStanceEMG, ...
% 'leftSwingEMG', leftSwingEMG, ...
% 'rightSwingEMG', rightSwingEMG, ...
% 'leftStanceXSENS', leftStanceXSENS, ...
% 'rightStanceXSENS', rightStanceXSENS, ...
% 'leftSwingXSENS', leftSwingXSENS, ...
% 'rightSwingXSENS', rightSwingXSENS, ...

end