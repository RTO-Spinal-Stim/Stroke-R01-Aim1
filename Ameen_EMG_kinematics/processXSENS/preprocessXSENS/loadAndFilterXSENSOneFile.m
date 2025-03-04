function [extracted_data, filtered_data] = loadAndFilterXSENSOneFile(xsensFilePath, xsensConfig)

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
nanIdx = isnan(raw_data(:,indices.(colNameFieldName)));
% nanIdx(1) = true; % Do not include the header row

% Perform the data extraction
extracted_data = struct();
for i = 1:length(colNamesFieldNames)
    colNameFieldName = colNamesFieldNames{i};
    extracted_data.(colNameFieldName) = raw_data(~nanIdx, indices.(colNameFieldName));
end

%% Filter the data
filtered_data = struct();
for i = 1:length(colNamesFieldNames)
    colNameFieldName = colNamesFieldNames{i};
    filtered_data.(colNameFieldName) = filtfilt(b, a, extracted_data.(colNameFieldName));
end