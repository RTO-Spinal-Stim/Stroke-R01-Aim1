function [xsensData] = loadAndFilterXSENSOneIntervention(xsensConfig, intervention_folder_path, intervention_field_name, regexsConfig)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF XSENS DATA

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
    [loadedData, filteredData] = loadAndFilterXSENSOneFile(xlsx_file_path, xsensConfig);
    tmpTable.Name = convertCharsToStrings(nameWithTrial);
    tmpTable.XSENS_Loaded = loadedData;
    tmpTable.XSENS_Filtered = filteredData;
    xsensData = [xsensData; tmpTable];
end