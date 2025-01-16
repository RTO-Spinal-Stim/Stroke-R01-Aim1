function [processed_data] = processDelsysEMGOneIntervention(delsysConfig, intervention_folder_path, subject_name)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF DELSYS EMG DURING WALKING TRIALS

file_extension = delsysConfig.FILE_EXTENSION;
intervention_name = fileparts(intervention_folder_path);
validCombinations = delsysConfig.VALID_COMBINATIONS;

generic_mat_path = fullfile(intervention_folder_path, file_extension);
mat_files = dir(generic_mat_path);
mat_file_names = {mat_files.name};
mat_file_field_names = cell(size(mat_file_names));

%% Preprocessing each file
processed_data = struct();
for i = 1:length(mat_file_names)
    mat_file_name = mat_file_names{i};
    mat_file_path = fullfile(intervention_folder_path, mat_file_name);
    mat_file_field_names{i} = matlab.lang.makeValidName(mat_file_name);
    processed_data.(mat_file_field_names{i}) = preprocessDelsysEMGOneFile(mat_file_path, delsysConfig);

    %% Correct EMG muscle mappings for specific subjects & interventions
    % This stays separate from the rest of preprocessing because it
    % requires additional dependency inputs beyond the rest of preprocessing, and is not mandatory if there's no
    % errors or errors were corrected previously.
    if isfield(validCombinations, subject_name) && ...
        any(strcmp(intervention_name, validCombinations.(subject_name)))
        processed_data.(mat_file_field_names{i}) = fixMuscleMappings(processed_data.(mat_file_field_names{i}), subject_name, intervention_name, validCombinations);
    end
end

%% Do analyses on each EMG file
for i = 1:length(mat_file_field_names)
    mat_file_field_name = mat_file_field_names{i};
end