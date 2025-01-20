function [filtered_data] = preprocessXSENSOneFile(xsensFilePath, xsensConfig)

%% PURPOSE: PREPROCESS XSENS DATA

%% Configuration
X_Fs = xsensConfig.SAMPLING_FREQUENCY;
filterConfig = xsensConfig.FILTER;
fc = filterConfig.LOWPASS_CUTOFF;
n = filterConfig.LOWPASS_ORDER;
[b, a] = butter(n,fc/(X_Fs/2),'low');

%% Load the data
[raw_data, header_row, cell_data] = xlsread(xsensFilePath, 'Joint Angles XZY');

%% Get column indices
colNames = xsensConfig.COLUMN_NAMES;
colNamesFieldNames = fieldnames(colNames);
indices = struct();
for i = 1:length(colNamesFieldNames)
    colNameFieldName = colNamesFieldNames{i};
    indices.(colNameFieldName) = ismember(header_row, colNames.(colNameFieldName));
end

%% Extract the data
% Get the start and end rows
start_row = 2; % The row to start at
tmp = raw_data(:,indices.(colNameFieldName)); % Find the index of the first NaN value to get the row to end at.
end_row = find(isnan(tmp), 1, 'first');
if isempty(end_row)
    end_row = length(tmp);
else
    end_row = end_row - 1; % Get the last number before the NaN index
end

% Perform the data extraction
extracted_data = struct();
for i = 1:length(colNamesFieldNames)
    colNameFieldName = colNamesFieldNames{i};
    extracted_data.(colNameFieldName) = raw_data(start_row:end_row, indices.(colNameFieldName));
end

%% Filter the data
filtered_data = struct();
for i = 1:length(colNamesFieldNames)
    colNameFieldName = colNamesFieldNames{i};
    filtered_data.joints.(colNameFieldName) = filtfilt(b, a, extracted_data.(colNameFieldName));
end