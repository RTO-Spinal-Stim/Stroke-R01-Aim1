function [processed_data] = processGaitRiteOneIntervention(gaitRiteConfig, intervention_folder_path)

%% PURPOSE: PROCESS ONE ENTIRE INTERVENTION OF GAITRITE DATA

file_extension = gaitRiteConfig.FILE_EXTENSION;

generic_xlsx_path = fullfile(intervention_folder_path, file_extension);
xlsx_files = dir(generic_xlsx_path);
xlsx_file_names = {xlsx_files.name};
xlsx_file_field_names = cell(size(xlsx_file_names));

%% Creating valid field names & pre-processing each file
% Output struct format:
% - {intervention}
%     - {subject}_{intervention}_{pre/post}_{fv/ssv}
%         - Trials
%             - trial{num}
%                 - stepLengthSymmetries
%                 - swingTimeSymmetries
%                 - AvgStepLenSym
%                 - AvgSwingTimeSym
%                 - seconds
%                     - gaitEvents
%                     - gaitPhases
%                     - gaitPhasesDurations
%                 - frames
%                     - gaitEvents
%                     - gaitPhases
%                     - gaitPhasesDurations
processed_data_all_trials = struct();
for i = 1:length(xlsx_file_names)    
    xlsx_file_name_with_ext = xlsx_file_names{i};
    period_index = strfind(xlsx_file_name_with_ext, '.');
    xlsx_file_name = xlsx_file_name_with_ext(1:period_index-1);
    xlsx_file_path = fullfile(intervention_folder_path, xlsx_file_name_with_ext);
    underscoreIndices = strfind(xlsx_file_name, '_');
    xlsx_file_field_names{i} = xlsx_file_name(underscoreIndices(end-1)+1:end);   

    [processed_data_all_trials.(xlsx_file_field_names{i}), rawNumericData] = preprocessGaitRiteOneFile(xlsx_file_path, gaitRiteConfig); % Second output is for manual checking/validation
end

%% Numbering the trial fields
% New output struct format:
% - {intervention}
%     - {pre/post}_{fv/ssv}{num}
%         - stepLengthSymmetries
%         - swingTimeSymmetries
%         - seconds
%             - gaitEvents
%             - gaitPhases
%             - gaitPhasesDurations
%         - frames
%             - gaitEvents
%             - gaitPhases
%             - gaitPhasesDurations
processed_data = struct();
numbered_field_names = cell(length(xlsx_file_field_names)*3,1);
count = 0;
for i = 1:length(xlsx_file_field_names)
    xlsx_file_field_name = xlsx_file_field_names{i};
    trialNames = fieldnames(processed_data_all_trials.(xlsx_file_field_name));
    for trialNum = 1:length(trialNames)
        trialName = trialNames{trialNum};
        new_field_name = [xlsx_file_field_name num2str(trialNum)];
        processed_data.(new_field_name) = processed_data_all_trials.(xlsx_file_field_name).(trialName);
        count = count+1;
        numbered_field_names{count} = new_field_name;
    end
end

%% Do analyses on each GaitRite file
for i = 1:length(numbered_field_names)
    numbered_field_name = numbered_field_names{i};
        
    % Mean step length symmetry & swing time symmetry
    processed_data.(numbered_field_name).AvgStepLenSym = mean(processed_data.(numbered_field_name).stepLengthSymmetries);
    processed_data.(numbered_field_name).AvgSwingTimeSym = mean(processed_data.(numbered_field_name).swingTimeSymmetries);
    
end