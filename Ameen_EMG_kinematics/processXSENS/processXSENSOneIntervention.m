function [processed_data] = processXSENSOneIntervention(xsensConfig, intervention_folder_path)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF XSENS DATA

file_extension = xsensConfig.FILE_EXTENSION;

generic_xlsx_path = fullfile(intervention_folder_path, file_extension);
xlsx_files = dir(generic_xlsx_path);
xlsx_file_names = {xlsx_files.name};
field_names = cell(size(xlsx_file_names));

%% Rename the fields and preprocess each file
processed_data = struct();
numericPattern = '-?\d+';
for i = 1:length(xlsx_file_names)
    xlsx_file_name_with_ext = xlsx_file_names{i};
    periodIndex = strfind(xlsx_file_name_with_ext, '.');
    xlsx_file_name = xlsx_file_name_with_ext(1:periodIndex-1);
    xlsx_file_path = fullfile(intervention_folder_path, xlsx_file_name_with_ext);
    underscoresIdx = strfind(xlsx_file_name, '_');
    xlsx_file_name_shortened = xlsx_file_name(underscoresIdx(end-1)+1:end);
    [tokenStart, ~, token] = regexp(xlsx_file_name_shortened, numericPattern, 'start', 'end', 'match');
    if length(token) ~= 1
        error('Wrong XSENS file name!');
    end
    token = token{1};
    count = num2str(abs(str2double(token)));
    field_name = [xlsx_file_name_shortened(1:tokenStart-1) count];
    field_names{i} = field_name;
    processed_data.(field_name) = preprocessXSENSOneFile(xlsx_file_path, xsensConfig);
end

%% Do analyses on each XSENS file