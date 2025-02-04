function [GaitRiteTable, num_data] = preprocessGaitRiteOneFile(gaitRitePath, gaitRiteConfig)

%% PURPOSE: LOAD AND PREPROCESS THE DATA FROM ONE GAITRITE FILE.

% Configuration
header_row_num = gaitRiteConfig.HEADER_ROW_NUM;
trialsColName = strtrim(gaitRiteConfig.COLUMN_NAMES.GAIT_ID);

[num_data, txt_data, cell_data] = xlsread(gaitRitePath);
header_row = txt_data(header_row_num,:);
for i = 1:length(header_row)
    header_row{i} = strtrim(header_row{i});
end
trialsColIdx = ismember(header_row, trialsColName);

%% Separate each trial
unique_trials = unique(num_data(:, trialsColIdx)); % Find the unique trial numbers

% 1. Loop through each unique trial number to separate and preprocess the data
GaitRiteTable = table;
GaitRite = cell(length(unique_trials),1);
for i = 1:length(unique_trials)
    trial_number = unique_trials(i);
    trialData = num_data(num_data(:,trialsColIdx) == trial_number, :);
    tableOut = preprocessGaitRiteOneTrial(gaitRiteConfig, header_row, trialData);
    GaitRiteTable = [GaitRiteTable; tableOut];
end