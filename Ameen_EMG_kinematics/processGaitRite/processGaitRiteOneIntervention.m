function [gaitRiteData] = processGaitRiteOneIntervention(gaitRiteConfig, intervention_folder_path, intervention_field_name, regexsConfig)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF GAITRITE DATA

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
    period_index = strfind(xlsx_file_name_with_ext, '.');
    xlsx_file_name = xlsx_file_name_with_ext(1:period_index-1);
    xlsx_file_path = fullfile(intervention_folder_path, xlsx_file_name_with_ext);
    [subject_id, ~, pre_post, speed] = parseFileName(regexsConfig, xlsx_file_name);
    tableColName = [subject_id '_' intervention_field_name '_' pre_post '_' speed];

    [tmpTable, rawNumericData] = preprocessGaitRiteOneFile(xlsx_file_path, gaitRiteConfig); % Second output is for manual checking/validation
    for j = 1:height(tmpTable)
        trialName = ['trial' num2str(j)];
        cellName = [tableColName '_' trialName];

        % Get the average symmetry values
        % tmpTable.AvgStepLenSym(j) = mean(tmpTable.stepLengthSymmetries{j});
        % tmpTable.AvgSwingTimeSym(j) = mean(tmpTable.swingTimeSymmetries{j});

        % Add the name.
        tmpTable.Name(j) = convertCharsToStrings(cellName);        
    end     
    gaitRiteData = addToTable(gaitRiteData, tmpTable);
end

gaitRiteData = [gaitRiteData(:,end), gaitRiteData(:,1:end-1)];