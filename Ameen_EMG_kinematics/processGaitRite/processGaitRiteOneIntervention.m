function [processed_data] = processGaitRiteOneIntervention(gaitriteConfig, intervention_folder_path)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF GAITRITE DATA

file_extension = gaitriteConfig.FILE_EXTENSION;

generic_xlsx_path = fullfile(intervention_folder_path, file_extension);
xlsx_files = dir(generic_xlsx_path);
xlsx_file_names = {xlsx_files.name};
xlsx_file_field_names = cell(size(mat_file_names));

%% Preprocessing each file
processed_data = struct();
for i = 1:length(xlsx_file_names)
    xlsx_file_name = xlsx_file_names{i};
    xlsx_file_path = fullfile(intervention_folder_path, xlsx_file_name);
    xlsx_file_field_names{i} = matlab.lang.makeValidName(xlsx_file_path);
    processed_data.(xlsx_file_field_names{i}) = preprocessGaitRiteOneFile(xlsx_file_path);
end

%% Do analyses on each GaitRite file
for i = 1:length(xlsx_file_field_names)
    xlsx_file_field_name = xlsx_file_field_names{i};
    trial_names = fieldnames(processed_data.(xlsx_file_field_name));
    for trial_num = 1:length(trial_names)
        trialName = trial_names{trial_num};
        
        % Mean step length symmetry & swing time symmetry
        processed_data.(xlsx_file_field_name).(trialName).AvgStepLenSym = mean(processed_data.(xlsx_file_field_name).(trialName).stepLenSym);
        processed_data.(xlsx_file_field_name).(trialName).AvgSwingTimeSym = mean(processed_data.(xlsx_file_field_name).(trialName).swingTimeSym);
    end
    
end