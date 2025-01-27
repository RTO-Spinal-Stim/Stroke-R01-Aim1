function [preprocessed_data] = loadAndFilterXSENSOneIntervention(xsensConfig, intervention_folder_path, regexsConfig)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF XSENS DATA

file_extension = xsensConfig.FILE_EXTENSION;

generic_xlsx_path = fullfile(intervention_folder_path, file_extension);
xlsx_files = dir(generic_xlsx_path);
xlsx_file_names = {xlsx_files.name};

xlsx_file_names = sort(xlsx_file_names); % Ensure the trials are in order.

%% Rename the fields and preprocess each file
preprocessed_data = struct();
for i = 1:length(xlsx_file_names)
    xlsx_file_name_with_ext = xlsx_file_names{i};
    periodIndex = strfind(xlsx_file_name_with_ext, '.');
    xlsx_file_name = xlsx_file_name_with_ext(1:periodIndex-1);
    xlsx_file_path = fullfile(intervention_folder_path, xlsx_file_name_with_ext);
    [~, ~, pre_post, speed] = parseFileName(regexsConfig, xlsx_file_name);
    % Initialize the trials part of the structure.
    try
        numExistingTrials = length(fieldnames(preprocessed_data.(speed).(pre_post).Trials));
        trialName = ['trial' num2str(numExistingTrials + 1)];        
    catch
        trialName = 'trial1';
    end
    [preprocessed_data.(speed).(pre_post).Trials.(trialName).Loaded, preprocessed_data.(speed).(pre_post).Trials.(trialName).Filtered] = loadAndFilterXSENSOneFile(xlsx_file_path, xsensConfig);
end