function [xsensData] = loadXSENSOneIntervention(xsensConfig, intervention_folder_path, intervention_field_name, regexsConfig)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF XSENS DATA
% Inputs:
% xsensConfig: The configuration struct for loading XSENS data
% intervention_folder_path: The folder path for the intervention containing
% all of the XSENS data files
% intervention_field_name: The name of the intervention
% regexsConfig: Config struct containing regexs to parse the file name.

file_extension = xsensConfig.FILE_EXTENSION;

generic_xlsx_path = fullfile(intervention_folder_path, file_extension);
xlsx_files = dir(generic_xlsx_path);
xlsx_file_names = {xlsx_files.name};

xlsx_file_names = sort(xlsx_file_names); % Ensure the trials are in order.

%% Rename the fields and preprocess each file
xsensData = table;
priorNamesNoTrial = cell(length(xlsx_file_names), 1);
for i = 1:length(priorNamesNoTrial)
    priorNamesNoTrial{i} = ''; % Initialize as chars
end
for i = 1:length(xlsx_file_names)
    xlsx_file_name_with_ext = xlsx_file_names{i};
    periodIndex = strfind(xlsx_file_name_with_ext, '.');
    xlsx_file_name = xlsx_file_name_with_ext(1:periodIndex-1);
    xlsx_file_path = fullfile(intervention_folder_path, xlsx_file_name_with_ext);
    parsedName = parseFileName(regexsConfig, xlsx_file_name);
    subject_id = parsedName{1};
    pre_post = parsedName{3};
    speed = parsedName{4};
    nameNoTrial = [subject_id '_' intervention_field_name '_' pre_post '_' speed];
    priorNamesNoTrial{i} = nameNoTrial;
    trialNum = sum(ismember(priorNamesNoTrial, {nameNoTrial}));
    nameWithTrial = [nameNoTrial '_trial' num2str(trialNum)];
    tmpTable = table;
    loadedData = loadXSENSOneFile(xlsx_file_path, xsensConfig.COLUMN_NAMES);
    tmpTable.Name = convertCharsToStrings(nameWithTrial);
    % Get the datetime
    tmpTable.DateTimeSaved_XSENS = getDateTimeSaved(xlsx_file_path);
    tmpTable.XSENS_Loaded = loadedData;
    xsensData = [xsensData; tmpTable];
end

end

function [dateTimeSaved] = getDateTimeSaved(xlsx_file_path)

%% PURPOSE: GET THE DATE THAT THE XSENS XLSX FILE WAS SAVED.
% Created for XSENS 2022 .xlsx files

[raw_data, header_row, cell_data] = xlsread(xlsx_file_path, 'General Information');
fullDate = cell_data{4,2};
spaceIdx = strfind(fullDate, ' ');
timeSaved = fullDate(spaceIdx(1)+1:end);
dateTimeSaved = datetime(timeSaved, 'InputFormat', 'h:mm:ss a', 'TimeZone', 'UTC');
dateTimeSaved.TimeZone = 'America/Chicago';
end