function [processed_data] = preprocessGaitRiteOneTrial(gaitRiteConfig, header_row, data)

%% PURPOSE: PREPROCESS ONE PARSED OUT GAITRITE TRIAL

%% Configuration
num_points = 101;
startPoint = 0;
endPoint = 100;
Gait_Fs = gaitRiteConfig.SAMPLING_FREQUENCY;
leftNormal = linspace(startPoint, endPoint, num_points);
rightNormal = linspace(startPoint, endPoint, num_points);

%% Get column indices
colNames = gaitRiteConfig.COLUMN_NAMES;
left_right_idx = ismember(header_row, colNames.LEFT_RIGHT);
heel_on_idx = ismember(header_row, colNames.HEEL_ON);
% heel_off_idx = ismember(header_row, colNames.HEEL_OFF);
% toe_on_idx = ismember(header_row, colNames.TOE_ON);
toe_off_idx = ismember(header_row, colNames.TOE_OFF);
step_len_idx = ismember(header_row, colNames.STEP_LENGTH);
swing_time_idx = ismember(header_row, colNames.SWING_TIME);

%% Extract the data
left_right = data(:, left_right_idx);
heel_on = data(:, heel_on_idx);
% heel_off = data(:, heel_off_idx);
% toe_on = data(:, toe_on_idx);
toe_off = data(:, toe_off_idx);
step_len = data(:, step_len_idx);
swing_time = data(:, swing_time_idx);

%% Initialize the processed data
num_steps = length(left_right);
leftStance = zeros(num_steps - 2, 2);
rightStance = zeros(num_steps - 2, 2);
leftSwing = zeros(num_steps - 2, 2);
rightSwing = zeros(num_steps - 2, 2);

stepLenSym = NaN(num_steps - 2, 1);
swingTimeSym = NaN(num_steps - 3, 1);

%% Stance and swing
for i = 1:length(left_right)-2
    if left_right(i) == 0
        leftStance(i,:) = [heel_on(i), toe_off(i)];
        leftSwing(i,:) = [toe_off(i), heel_on(i+2)];
    else
        rightStance(i,:) = [heel_on(i), toe_off(i)];
        rightSwing(i,:) = [toe_off(i), heel_on(i+2)];
    end
end

%% Step length symmetry
for i = 2:length(left_right)-1
    stepLenSym(i-1) = (2*abs(step_len(i)-step_len(i+1)))/(step_len(i)+step_len(i+1));
end

%% Swing time symmetry
for i = 3:length(left_right)-1
    swingTimeSym(i-2) = (2*abs(swing_time(i)-swing_time(i+1)))/(swing_time(i)+swing_time(i+1));
end

%% Remove the NaN rows.
leftZeroRows = all(leftStance == 0, 2);
rightZeroRows = all(rightStance == 0,2);

leftStance(leftZeroRows, :) = [];
rightStance(rightZeroRows, :) = [];
leftSwing(leftZeroRows, :) = [];
rightSwing(rightZeroRows, :) = [];

% Convert durations to seconds
leftStance = round(leftStance * Gait_Fs);
rightStance = round(rightStance * Gait_Fs);
leftSwing = round(leftSwing * Gait_Fs);
rightSwing = round(rightSwing * Gait_Fs);

leftStanceTime = leftStance(:,2)-leftStance(:,1);
rightStanceTime = rightStance(:,2)-rightStance(:,1);
leftSwingTime = leftSwing(:,2)-leftSwing(:,1);
rightSwingTime = rightSwing(:,2)-rightSwing(:,1);

leftStanceTime = round(mean(leftStanceTime));
rightStanceTime = round(mean(rightStanceTime));
leftSwingTime = round(mean(leftSwingTime));
rightSwingTime = round(mean(rightSwingTime));

totalLeft = leftStanceTime + leftSwingTime;
totalRight = rightStanceTime + rightSwingTime;

leftStanceProportion = leftStanceTime/totalLeft;
% leftSwingProportion = leftSwingTime/totalLeft;
rightStanceProportion = rightStanceTime/totalRight;
% rightSwingProportion = rightSwingTime/totalRight;        

leftSwingIdx = round(leftStanceProportion * num_points)+1;
rightSwingIdx = round(rightStanceProportion * num_points)+1;

processed_data = struct(...    
    'leftSwingIdx', leftSwingIdx, ...
    'rightSwingIdx', rightSwingIdx, ...
    'leftNormal', leftNormal, ...
    'rightNormal', rightNormal, ...
    'stepLenSym', stepLenSym, ...
    'swingTimeSym', swingTimeSym...
);

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