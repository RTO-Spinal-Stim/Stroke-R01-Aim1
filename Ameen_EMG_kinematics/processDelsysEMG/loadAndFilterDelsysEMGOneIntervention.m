function [delsysData] = loadAndFilterDelsysEMGOneIntervention(delsysConfig, intervention_folder_path, intervention_field_name, regexsConfig)

%% PURPOSE: LOAD AND FILTER ONE ENTIRE INTERVENTION OF DELSYS EMG DURING WALKING TRIALS
% NOTE: Assumes that subject name, intervention name, pre/post, and speed (ssv/fv) are all present in the file name

file_extension = delsysConfig.FILE_EXTENSION;
subjects_interventions_to_fix = delsysConfig.SUBJECTS_INTERVENTIONS_TO_FIX;

generic_mat_path = fullfile(intervention_folder_path, file_extension);
mat_files = dir(generic_mat_path);
mat_file_names = {mat_files.name};

mat_file_names = sort(mat_file_names); % Ensure the trials are in order.

%% Rename/number struct fields and preprocess each file
delsysData = table;
priorNamesNoTrial = cell(length(mat_file_names), 1);
for i = 1:length(priorNamesNoTrial)
    priorNamesNoTrial{i} = ''; % Initialize as chars
end
for i = 1:length(mat_file_names)
    mat_file_name_with_ext = mat_file_names{i};
    periodIndex = strfind(mat_file_name_with_ext, '.');
    mat_file_name = mat_file_name_with_ext(1:periodIndex-1);
    mat_file_path = fullfile(intervention_folder_path, mat_file_name_with_ext);    
    [subject_name, ~, pre_post, speed] = parseFileName(regexsConfig, mat_file_name);
    nameNoTrial = [subject_name '_' intervention_field_name '_' pre_post '_' speed];
    priorNamesNoTrial{i} = nameNoTrial;
    trialNum = sum(ismember(priorNamesNoTrial, {nameNoTrial}));
    nameWithTrial = [nameNoTrial '_trial' num2str(trialNum)];    
    [loadedData, filteredData] = loadAndFilterDelsysEMGOneFile(mat_file_path, delsysConfig);    

    %% Hard-coded fix for EMG muscle mappings for specific subjects & interventions
    if isfield(subjects_interventions_to_fix, subject_name) && ...
        any(strcmp(intervention_field_name, subjects_interventions_to_fix.(subject_name)))
        loadedData = fixMuscleMappings(loadedData);
        filteredData = fixMuscleMappings(filteredData);
    end

    tmpTable = table;
    tmpTable.Name = convertCharsToStrings(nameWithTrial);
    tmpTable.Delsys_Loaded = loadedData;
    tmpTable.Delsys_Filtered = filteredData;    
    delsysData = [delsysData; tmpTable];
end