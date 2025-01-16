%% Created by MT 01/16/25
% The main pipeline for R01 Stroke Spinal Stim Aim 1

subject = 'SS13';
% Folder to load the data from.
subjectLoadPath = fullfile('Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data', subject);
% Path to save the data to.
subjectSavePath = strcat('Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\Processed Outcomes\', subject, '_Outcomes.mat');
codeFolderPath = 'Y:\Spinal Stim_Stroke R01\AIM 1\GitRepo\Stroke-R01\Ameen_EMG_kinematics';
addpath(genpath(codeFolderPath));

%% Get configuration
config = jsondecode(fileread(fullfile(codeFolderPath,'config.json')));

intervention_folders = config.INTERVENTION_FOLDERS;
mapped_interventions = containers.Map(intervention_folders, config.MAPPED_INTERVENTION_FIELDS);
gaitriteConfig = config.GAITRITE;
delsysConfig = config.DELSYS_EMG;
xsensConfig = config.XSENS;

%% Delsys Processing
subject_delsys_folder = fullfile(subjectLoadPath, delsysConfig.FOLDER_NAME);
% Process each intervention
for i = 1:length(intervention_folders)   
    intervention_folder = intervention_folders{i};        
    intervention_folder_path = fullfile(subject_delsys_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    delsys_processed_intervention.(intervention_field_name) = processDelsysEMGOneIntervention(delsysConfig, intervention_folder_path);
end

%% GaitRite Processing
subject_gaitrite_folder = fullfile(subjectLoadPath, gaitriteConfig.FOLDER_NAME);
% Process each intervention
for i = 1:length(intervention_folders)
    intervention_folder = intervention_folders{i};    
    intervention_folder_path = fullfile(subject_gaitrite_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    gaitrite_processed_intervention.(intervention_field_name) = processGaitRiteOneIntervention(gaitriteConfig, intervention_folder_path);
end

%% XSENS Processing
subject_xsens_folder = fullfile(subjectLoadPath, xsensConfig.FOLDER_NAME);
% Process each intervention
for i = 1:length(intervention_folders)
    intervention_folder = intervention_folders{i};    
    intervention_folder_path = fullfile(subject_xsens_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    xsens_processed_intervention.(intervention_field_name) = processXSENSOneIntervention(xsensConfig, intervention_folder_path);
end

%% Time Synchronization

%% Pre-Post Analysis