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


% SUBJ_list = { '02', '03', '04', '05' }; %, '01','02', '03', '04', '05', '06', '08', '09', '10'];
% TP_list = { 'PRE', 'POST' }; 
% INTER_list = { '30_RMT', '30_TOL', '50_RMT', '50_TOL', 'SHAM1','SHAM2' }; 

inter_valid_names = containers.Map(intervention_folders, intervention_field_names);

aim1_folder = config.AIM1_FOLDER; 
subj_path = fullfile(aim1_folder, 'Subject Data');
subj_path_prefix = 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data';
subj_save_path_prefix = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\MEPs Processing AIM 1';

%% Run the pipeline.
% A_Smers_processing_dataPrep;
% B_Smers_P2P_AUC;
% C_Smers_RecruitmentCurves;