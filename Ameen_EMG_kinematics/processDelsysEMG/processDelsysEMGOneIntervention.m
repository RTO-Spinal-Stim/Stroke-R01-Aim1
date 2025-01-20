function [processed_data] = processDelsysEMGOneIntervention(delsysConfig, intervention_folder_path, subject_name)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF DELSYS EMG DURING WALKING TRIALS

file_extension = delsysConfig.FILE_EXTENSION;
intervention_name = fileparts(intervention_folder_path);
validCombinations = delsysConfig.VALID_COMBINATIONS;

generic_mat_path = fullfile(intervention_folder_path, file_extension);
mat_files = dir(generic_mat_path);
mat_file_names = {mat_files.name};
field_names = cell(size(mat_file_names));

%% Rename/number struct fields and preprocess each file
processed_data = struct();
for i = 1:length(mat_file_names)
    mat_file_name_with_ext = mat_file_names{i};
    periodIndex = strfind(mat_file_name_with_ext, '.');
    mat_file_name = mat_file_name_with_ext(1:periodIndex-1);
    mat_file_path = fullfile(intervention_folder_path, mat_file_name_with_ext);
    underscoreIdx = strfind(mat_file_name, '_');
    field_name = mat_file_name(underscoreIdx(end-1)+1:end);
    processed_data.(field_name).muscles = preprocessDelsysEMGOneFile(mat_file_path, delsysConfig);
    field_names{i} = field_name;

    %% Correct EMG muscle mappings for specific subjects & interventions
    % This stays separate from the rest of preprocessing because it
    % requires additional dependency inputs beyond the rest of preprocessing, and is not mandatory if there's no
    % errors or errors were corrected previously.
    if isfield(validCombinations, subject_name) && ...
        any(strcmp(intervention_name, validCombinations.(subject_name)))
        processed_data.(field_name) = fixMuscleMappings(processed_data.(field_name).muscles, subject_name, intervention_name, validCombinations);
    end
end

%% Do analyses on each EMG file
for i = 1:length(field_names)
    mat_file_field_name = field_names{i};
end