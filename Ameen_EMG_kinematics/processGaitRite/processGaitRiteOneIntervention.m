function [preprocessed_data] = processGaitRiteOneIntervention(gaitRiteConfig, intervention_folder_path, regexsConfig)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF GAITRITE DATA

file_extension = gaitRiteConfig.FILE_EXTENSION;

generic_xlsx_path = fullfile(intervention_folder_path, file_extension);
xlsx_files = dir(generic_xlsx_path);
xlsx_file_names = {xlsx_files.name};

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
for i = 1:length(xlsx_file_names)    
    xlsx_file_name_with_ext = xlsx_file_names{i};
    period_index = strfind(xlsx_file_name_with_ext, '.');
    xlsx_file_name = xlsx_file_name_with_ext(1:period_index-1);
    xlsx_file_path = fullfile(intervention_folder_path, xlsx_file_name_with_ext);
    [~, ~, pre_post, speed] = parseFileName(regexsConfig, xlsx_file_name);

    [gaitRiteData, rawNumericData] = preprocessGaitRiteOneFile(xlsx_file_path, gaitRiteConfig); % Second output is for manual checking/validation
    for j = 1:length(gaitRiteData)
        trialName = ['trial' num2str(j)];
        preprocessed_data.(speed).(pre_post).Trials.(trialName) = gaitRiteData{j};

        % Get the average symmetry values
        preprocessed_data.(speed).(pre_post).Trials.(trialName).AvgStepLenSym = mean(preprocessed_data.(speed).(pre_post).Trials.(trialName).stepLengthSymmetries);
        preprocessed_data.(speed).(pre_post).Trials.(trialName).AvgSwingTimeSym = mean(preprocessed_data.(speed).(pre_post).Trials.(trialName).swingTimeSymmetries);
    end     
end