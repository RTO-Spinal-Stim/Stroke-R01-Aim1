function [gaitRiteData] = loadGaitRiteOneIntervention(gaitRiteConfig, intervention_folder_path, intervention_field_name, regexsConfig)

%% PURPOSE: LOAD ONE ENTIRE INTERVENTION OF GAITRITE DATA
% Inputs:
% gaitRiteConfig: Config struct
% intervention_folder_path: Path to the folder containing all files for this intervention
% intervention_field_name: The intervention name
% regexsConfig: The regexs to use to parse the file name.
%
% Outputs:
% gaitRiteData: The loaded GaitRite data

file_extension = gaitRiteConfig.FILE_EXTENSION;

generic_xlsx_path = fullfile(intervention_folder_path, file_extension);
xlsx_files = dir(generic_xlsx_path);
xlsx_file_names = {xlsx_files.name}';

%% Creating valid field names & pre-processing each file
% Output struct format:
% - trial
%     - stepLengthSymmetries
%     - swingTimeSymmetries
%     - AvgStepLenSym
%     - AvgSwingTimeSym
%     - seconds
%         - gaitEvents
%         - gaitPhases
%         - gaitPhasesDurations
%     - frames
%         - gaitEvents
%         - gaitPhases
%         - gaitPhasesDurations
gaitRiteData = table;
for i = 1:length(xlsx_file_names)    
    xlsx_file_name_with_ext = xlsx_file_names{i};
    if startsWith(xlsx_file_name_with_ext, '~$')
        continue; % Cache file, doesn't really exist.
    end
    period_index = strfind(xlsx_file_name_with_ext, '.');
    xlsx_file_name = xlsx_file_name_with_ext(1:period_index-1);
    xlsx_file_path = fullfile(intervention_folder_path, xlsx_file_name_with_ext);
    parsedName = parseFileName(regexsConfig, xlsx_file_name);
    subject_id = parsedName{1};
    pre_post = parsedName{3};
    speed = parsedName{4};
    tableColName = [subject_id '_' intervention_field_name '_' pre_post '_' speed];

    tmpTable = loadGaitRiteOneFile(xlsx_file_path, gaitRiteConfig); % Second output is for manual checking/validation
    for j = 1:height(tmpTable)
        trialName = ['trial' num2str(j)];
        cellName = [tableColName '_' trialName];

        % Add the name.
        tmpTable.Name(j) = convertCharsToStrings(cellName);        
    end     
    gaitRiteData = addToTable(gaitRiteData, tmpTable);
end

% Put the name column first
gaitRiteData = [gaitRiteData(:,end), gaitRiteData(:,1:end-1)];