function [preprocessed_data] = loadAndFilterDelsysEMGOneIntervention(delsysConfig, intervention_folder_path, regexsConfig)

%% PURPOSE: LOAD AND FILTER ONE ENTIRE INTERVENTION OF DELSYS EMG DURING WALKING TRIALS
% NOTE: Assumes that subject name, intervention name, pre/post, and speed (ssv/fv) are all present in the file name

file_extension = delsysConfig.FILE_EXTENSION;
validCombinations = delsysConfig.VALID_COMBINATIONS;

generic_mat_path = fullfile(intervention_folder_path, file_extension);
mat_files = dir(generic_mat_path);
mat_file_names = {mat_files.name};

mat_file_names = sort(mat_file_names); % Ensure the trials are in order.

%% Rename/number struct fields and preprocess each file
preprocessed_data = struct();
for i = 1:length(mat_file_names)
    mat_file_name_with_ext = mat_file_names{i};
    periodIndex = strfind(mat_file_name_with_ext, '.');
    mat_file_name = mat_file_name_with_ext(1:periodIndex-1);
    mat_file_path = fullfile(intervention_folder_path, mat_file_name_with_ext);    
    [subject_name, intervention_name, pre_post, speed] = parseFileName(regexsConfig, mat_file_name);
    % Initialize the trials part of the structure.
    try
        numExistingTrials = length(fieldnames(preprocessed_data.(speed).(pre_post).Trials));
        trialName = ['trial' num2str(numExistingTrials + 1)];        
    catch
        trialName = 'trial1';
    end
    preprocessed_data.(speed).(pre_post).Trials.(trialName) = struct;
    [preprocessed_data.(speed).(pre_post).Trials.(trialName).Loaded, preprocessed_data.(speed).(pre_post).Trials.(trialName).Filtered] = loadAndFilterDelsysEMGOneFile(mat_file_path, delsysConfig);

    %% Correct EMG muscle mappings for specific subjects & interventions
    % This stays separate from the rest of preprocessing because it
    % requires additional dependency inputs beyond the rest of preprocessing, and is not mandatory if there's no
    % errors or errors were corrected previously.
    if isfield(validCombinations, subject_name) && ...
        any(strcmp(intervention_name, validCombinations.(subject_name)))
        preprocessed_data.(field_name) = fixMuscleMappings(preprocessed_data.(field_name).muscles, subject_name, intervention_name, validCombinations);
    end
end