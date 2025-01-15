function [GaitRite] = processGaitRiteOneFile(gaitRitePath, gaitRiteConfig)

%% PURPOSE: LOAD AND PROCESS THE DATA FROM ONE GAITRITE FILE.

% Configuration
header_row_num = 3;
trialsColName = strtrim(gaitRiteConfig.COLUMN_NAMES.GAIT_ID);

GaitRite = struct();

[num_data, txt_data, cell_data] = xlsread(gaitRitePath);
header_row = txt_data(header_row_num,:);
for i = 1:length(header_row)
    header_row{i} = strtrim(header_row{i});
end
trialsColIdx = ismember(header_row, trialsColName);

GaitRite.RawNumeric = num_data; % This is where the data is?
% GaitRite.Raw.txt = txt_data;
% GaitRite.Raw.data = cell_data;

%% Separate each trial
unique_trials = unique(num_data(:, trialsColIdx)); % Find the unique trial numbers
trials_struct = struct(); % Initialize a structure to hold each trial

% 1. Loop through each unique trial number and separate the data
for i = 1:length(unique_trials)
    trial_number = unique_trials(i);
    trial_name = sprintf('trial%d', i);
    trials_struct.(trial_name) = num_data(num_data(:,trialsColIdx) == trial_number, :);
end

%% Process each trial
trial_names = fieldnames(trials_struct);
for i = 1:length(trial_names)
    trial_name = trial_names{i};
    GaitRite.(trial_name) = processGaitRiteOneTrial(gaitRiteConfig, header_row, trials_struct.(trial_name));
end