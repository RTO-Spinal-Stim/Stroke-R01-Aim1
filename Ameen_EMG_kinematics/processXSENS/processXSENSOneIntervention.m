function [processed_data] = processXSENSOneIntervention(xsensConfig, intervention_folder_path)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF XSENS DATA

file_extension = xsensConfig.FILE_EXTENSION;

generic_xlsx_path = fullfile(intervention_folder_path, file_extension);
xlsx_files = dir(generic_xlsx_path);
xlsx_file_names = {xlsx_files.name};

%% Preprocessing each file
preprocessed_data = struct();
for i = 1:length(xlsx_file_names)
    xlsx_file_name = xlsx_file_names{i};
    xlsx_file_path = fullfile(intervention_folder_path, xlsx_file_name);
    preprocessed_data.(xlsx_file_name) = preprocessXSENSOneFile(xlsx_file_path);
end

%% Do analyses on each XSENS file