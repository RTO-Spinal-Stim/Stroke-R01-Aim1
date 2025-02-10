%% Created by NV
%% Updated by MT 02/05/25
clc;
clearvars;
subject = 'SS13';
% Folder to load the data from.
subjectLoadPath = fullfile('Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data', subject);
% Path to save the data to.
subjectSavePath = strcat('Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\', subject, '.mat');
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
subj_save_path_prefix = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\MEPs Processing AIM 1';
subj_path_suffix = config.SUBJ_PATH_SUFFIX;
curr_subj_path = fullfile(subjectLoadPath, subj_path_suffix);
curr_subj_save_path = fullfile(subj_save_path_prefix, subject, subj_path_suffix);

%% Read in master TEPs file. Removes extra rows
% Obtains the bad pulses for each MEP trial.
teps_log_filename = fullfile(subj_path, 'TEPs_log.xlsx');
tepsLog = readTEPsLog(teps_log_filename);

%% Run the pipeline.
% A_Smers_processing_dataPrep;
% B_Smers_P2P_AUC;
% C_Smers_RecruitmentCurves;