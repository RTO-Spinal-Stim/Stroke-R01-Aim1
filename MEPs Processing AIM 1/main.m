%% Created by NV
%% Updated by MT 02/05/25
clc;
clearvars;
subject = 'SS13';
% Folder to load the data from.
subjectLoadPath = fullfile('Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data', subject);
codeFolderPath = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\MEPs Processing AIM 1';
addpath(genpath(codeFolderPath));

plot = true;

%% Get the configuration.
configFilePath = fullfile(codeFolderPath,'config.json');
config = jsondecode(fileread(configFilePath));
disp(['Loaded configuration from: ' configFilePath]);

intervention_folders = config.INTERVENTION_FOLDERS;
INTER_list = intervention_folders;
intervention_field_names = config.MAPPED_INTERVENTION_FIELDS;
mapped_interventions = containers.Map(intervention_folders, intervention_field_names);

aim1_folder = config.AIM1_FOLDER; 
subj_path = fullfile(aim1_folder, 'Subject Data');
subj_save_path_prefix = config.SAVE_FOLDER;
subj_path_suffix = config.SUBJ_PATH_SUFFIX;
curr_subj_path = fullfile(subjectLoadPath, subj_path_suffix);
xlsxLogFile = fullfile(config.SAVE_FOLDER, subject, config.SAVE_FILENAMES.B.LOG);
correctChannelsJSONPath = 'A_channels.json';

%% Read in master TEPs file. Removes extra rows
% Obtains the bad pulses for each MEP trial.
teps_log_filename = fullfile(subj_path, 'TEPs_log.xlsx');
tepsLog = readTEPsLog(teps_log_filename);

%% Part A
% Process the TEPs log and filter the data for one subject.
disp('Pre-processing TEPs data');
tepsResultTableOneSubject = processTEPsOneSubject(tepsLog, subject, config, curr_subj_path, correctChannelsJSONPath);
disp('Finished pre-processing TEPs data');

%% Part B
tepsResultTableOneSubject = plotTEPsManualCheckOneSubject(config, tepsResultTableOneSubject);
% B_Smers_P2P_AUC;
% C_Smers_RecruitmentCurves;