%% Created by MT 01/16/25
% The main pipeline for R01 Stroke Spinal Stim Aim 1
clc;
clearvars;
subject = 'SS13';
% Folder to load the data from.
subjectLoadPath = fullfile('Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data', subject);
% Path to save the data to.
subjectSavePath = strcat('Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\Processed Outcomes\', subject, '_Outcomes.mat');
codeFolderPath = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Ameen_EMG_kinematics';
addpath(genpath(codeFolderPath));

%% Get configuration
configFilePath = fullfile(codeFolderPath,'config.json');
disp(['Loading configuration from: ' configFilePath])
config = jsondecode(fileread(configFilePath));

intervention_folders = config.INTERVENTION_FOLDERS;
intervention_field_names = config.MAPPED_INTERVENTION_FIELDS;
mapped_interventions = containers.Map(intervention_folders, intervention_field_names);
gaitriteConfig = config.GAITRITE;
delsysConfig = config.DELSYS_EMG;
xsensConfig = config.XSENS;
regexsConfig = config.REGEXS;

%% Delsys Processing
disp('Preprocessing Delsys');
subject_delsys_folder = fullfile(subjectLoadPath, delsysConfig.FOLDER_NAME);
% Process each intervention
for i = 1:length(intervention_folders)   
    intervention_folder = intervention_folders{i};        
    intervention_folder_path = fullfile(subject_delsys_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    delsysStruct.(intervention_field_name) = loadAndFilterDelsysEMGOneIntervention(delsysConfig, intervention_folder_path, regexsConfig);
end

%% GaitRite Processing
disp('Preprocessing Gaitrite');
subject_gaitrite_folder = fullfile(subjectLoadPath, gaitriteConfig.FOLDER_NAME);
% Process each intervention
for i = 1:length(intervention_folders)
    intervention_folder = intervention_folders{i};    
    intervention_folder_path = fullfile(subject_gaitrite_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    gaitRiteStruct.(intervention_field_name) = processGaitRiteOneIntervention(gaitriteConfig, intervention_folder_path, regexsConfig);
end

%% XSENS Processing
disp('Preprocessing XSENS');
subject_xsens_folder = fullfile(subjectLoadPath, xsensConfig.FOLDER_NAME);
% Process each intervention
for i = 1:length(intervention_folders)
    intervention_folder = intervention_folders{i};    
    intervention_folder_path = fullfile(subject_xsens_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    xsensStruct.(intervention_field_name) = loadAndFilterXSENSOneIntervention(xsensConfig, intervention_folder_path, regexsConfig);
end

%% Time Synchronization
% Get gait event indices, phase durations, etc. in Delsys & XSENS indices
disp('Time synchronizing XSENS & Delsys');
for i = 1:length(intervention_field_names)
    intervention_field_name = intervention_field_names{i};
    speedNames = fieldnames(gaitRiteStruct.(intervention_field_name));
    for speedNum = 1:length(speedNames)
        speedName = speedNames{speedNum};
        prePosts = fieldnames(gaitRiteStruct.(intervention_field_name).(speedName));
        for prePostNum = 1:length(prePosts)
            prePost = prePosts{prePostNum};
            trialNames = fieldnames(gaitRiteStruct.(intervention_field_name).(speedName).(prePost).Trials);
            for trialNum = 1:length(trialNames)
                trialName = trialNames{trialNum};
                trialData = gaitRiteStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName);
                secondsStruct = trialData.seconds;
                delsysStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).frames = getHardwareIndicesFromSeconds(secondsStruct, delsysConfig.SAMPLING_FREQUENCY);
                xsensStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).frames = getHardwareIndicesFromSeconds(secondsStruct, xsensConfig.SAMPLING_FREQUENCY);
            end
        end
    end
end

%% Split Data by Gait Cycle
% QUESTION: USE L OR R HEEL STRIKES TO DENOTE GAIT CYCLES? MAKE IT SPECIFIC
% TO L/R SENSOR/MEASURE?
disp('Splitting XSENS & Delsys data by gait cycle');
for i = 1:length(intervention_field_names)
    intervention_field_name = intervention_field_names{i};
    speedNames = fieldnames(gaitRiteStruct.(intervention_field_name));
    for speedNum = 1:length(speedNames)
        speedName = speedNames{speedNum};
        prePosts = fieldnames(gaitRiteStruct.(intervention_field_name).(speedName));
        for prePostNum = 1:length(prePosts)
            prePost = prePosts{prePostNum};
            trialNames = fieldnames(gaitRiteStruct.(intervention_field_name).(speedName).(prePost).Trials);
            for trialNum = 1:length(trialNames)
                trialName = trialNames{trialNum};
                delsysTrialStruct = delsysStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName);
                xsensTrialStruct = xsensStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName);
                delsysLHS = delsysTrialStruct.frames.gaitEvents.leftHeelStrikes;
                delsysRHS = delsysTrialStruct.frames.gaitEvents.rightHeelStrikes;
                xsensLHS = xsensTrialStruct.frames.gaitEvents.leftHeelStrikes;
                xsensRHS = xsensTrialStruct.frames.gaitEvents.rightHeelStrikes;
                xsensCyclesData = splitTrialByGaitCycle(xsensTrialStruct.Filtered, xsensLHS, xsensRHS);
                delsysCyclesData = splitTrialByGaitCycle(delsysTrialStruct.Filtered, delsysLHS, delsysRHS); 
                % Put the parsed data into each gait cycle's field in the struct.
                for gaitCycleNum = 1:length(xsensCyclesData)
                    gaitCycleName = ['cycle' num2str(gaitCycleNum)];
                    delsysStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles.(gaitCycleName).Filtered = delsysCyclesData{gaitCycleNum};
                    xsensStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles.(gaitCycleName).Filtered = xsensCyclesData{gaitCycleNum};
                end
            end
        end
    end
end

%% Downsample each gait cycle's data to 101 points and aggregate together, within and across trials.
n_points = 101;
disp(['Downsampling and aggregating the data within each gait cycle to ' num2str(n_points) ' points']);

for i = 1:length(intervention_field_names)
    intervention_field_name = intervention_field_names{i};
    speedNames = fieldnames(gaitRiteStruct.(intervention_field_name));
    for speedNum = 1:length(speedNames)
        speedName = speedNames{speedNum};
        prePosts = fieldnames(gaitRiteStruct.(intervention_field_name).(speedName));
        for prePostNum = 1:length(prePosts)
            prePost = prePosts{prePostNum};
            trialNames = fieldnames(gaitRiteStruct.(intervention_field_name).(speedName).(prePost).Trials);
            xsensAggData = [];
            delsysAggData = [];
            for trialNum = 1:length(trialNames)
                trialName = trialNames{trialNum};
                gaitCycleNames = fieldnames(delsysStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles);
                for cycleNum = 1:length(gaitCycleNames)
                    cycleName = gaitCycleNames{cycleNum};
                    delsysStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles.(cycleName).TimeNormalized = downsampleData(delsysStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles.(cycleName).Filtered, n_points);
                    xsensStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles.(cycleName).TimeNormalized = downsampleData(xsensStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles.(cycleName).Filtered, n_points);
                    xsensAggData = [xsensAggData; xsensStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles.(cycleName).TimeNormalized];
                    delsysAggData = [delsysAggData; delsysStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles.(cycleName).TimeNormalized];
                end
            end
            delsysStruct.(intervention_field_name).(speedName).(prePost).Aggregated = delsysAggData;
            xsensStruct.(intervention_field_name).(speedName).(prePost).Aggregated = xsensAggData;
            delsysStruct.(intervention_field_name).(speedName).(prePost).Averaged = mean(delsysAggData,1);
            xsensStruct.(intervention_field_name).(speedName).(prePost).Averaged = mean(xsensAggData, 1);
        end
    end
end

%% Calculate the number of muscle synergies in each gait cycle of each trial
% NOTE: USE THE NON-TIME NORMALIZED EMG DATA FOR THIS? CHEN RECOMMENDED USING THE TIME-NORMALIZED DATA 
% NEED TO TRY BOTH AND COMPARE
for i = 1:length(intervention_field_names)
    intervention_field_name = intervention_field_names{i};
    trialNames = fieldnames(gaitRiteStruct.(intervention_field_name));  

end