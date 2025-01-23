%% Created by MT 01/16/25
% The main pipeline for R01 Stroke Spinal Stim Aim 1
clc;
clearvars;
subject = 'SS13';
% Folder to load the data from.
subjectLoadPath = fullfile('Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data', subject);
% Path to save the data to.
subjectSavePath = strcat('Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\Processed Outcomes\', subject, '_Outcomes.mat');
codeFolderPath = 'Y:\Spinal Stim_Stroke R01\AIM 1\GitRepo\Stroke-R01\Ameen_EMG_kinematics';
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

%% Delsys Processing
disp('Preprocessing Delsys');
subject_delsys_folder = fullfile(subjectLoadPath, delsysConfig.FOLDER_NAME);
% Process each intervention
for i = 1:length(intervention_folders)   
    intervention_folder = intervention_folders{i};        
    intervention_folder_path = fullfile(subject_delsys_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    delsys_processed_intervention.(intervention_field_name) = processDelsysEMGOneIntervention(delsysConfig, intervention_folder_path, subject);
end

%% GaitRite Processing
disp('Preprocessing Gaitrite');
subject_gaitrite_folder = fullfile(subjectLoadPath, gaitriteConfig.FOLDER_NAME);
% Process each intervention
for i = 1:length(intervention_folders)
    intervention_folder = intervention_folders{i};    
    intervention_folder_path = fullfile(subject_gaitrite_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    gaitrite_processed_intervention.(intervention_field_name) = processGaitRiteOneIntervention(gaitriteConfig, intervention_folder_path);
end

%% XSENS Processing
disp('Preprocessing XSENS');
subject_xsens_folder = fullfile(subjectLoadPath, xsensConfig.FOLDER_NAME);
% Process each intervention
for i = 1:length(intervention_folders)
    intervention_folder = intervention_folders{i};    
    intervention_folder_path = fullfile(subject_xsens_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    xsens_processed_intervention.(intervention_field_name) = processXSENSOneIntervention(xsensConfig, intervention_folder_path);
end

%% Time Synchronization
% Get gait event indices, phase durations, etc. in Delsys & XSENS indices
disp('Time synchronizing XSENS & Delsys');
for i = 1:length(intervention_field_names)
    intervention_field_name = intervention_field_names{i};
    trialNames = fieldnames(gaitrite_processed_intervention.(intervention_field_name));
    for trialNum = 1:length(trialNames)
        trialName = trialNames{trialNum};        
        secondsStruct = gaitrite_processed_intervention.(intervention_field_name).(trialName).seconds;
        delsys_processed_intervention.(intervention_field_name).(trialName).frames = getHardwareIndicesFromSeconds(secondsStruct, delsysConfig.SAMPLING_FREQUENCY);
        xsens_processed_intervention.(intervention_field_name).(trialName).frames = getHardwareIndicesFromSeconds(secondsStruct, xsensConfig.SAMPLING_FREQUENCY);          
    end    
end

%% Split Data by Gait Cycle
% QUESTION: USE L OR R HEEL STRIKES TO DENOTE GAIT CYCLES? MAKE IT SPECIFIC
% TO L/R SENSOR/MEASURE?
disp('Splitting XSENS & Delsys data by gait cycle');
for i = 1:length(intervention_field_names)
    intervention_field_name = intervention_field_names{i};
    trialNames = fieldnames(gaitrite_processed_intervention.(intervention_field_name));
    for trialNum = 1:length(trialNames)
        trialName = trialNames{trialNum};
        delsysDataStruct = delsys_processed_intervention.(intervention_field_name);
        xsensDataStruct = xsens_processed_intervention.(intervention_field_name);
        delsysLHS = delsysDataStruct.(trialName).frames.gaitEvents.leftHeelStrikes;
        delsysRHS = delsysDataStruct.(trialName).frames.gaitEvents.rightHeelStrikes;
        xsensLHS = xsensDataStruct.(trialName).frames.gaitEvents.leftHeelStrikes;
        xsensRHS = xsensDataStruct.(trialName).frames.gaitEvents.rightHeelStrikes;
        delsys_processed_intervention.(intervention_field_name).(trialName).musclesByGaitCycle = splitDelsysTrialByGaitCycle(delsysDataStruct.(trialName).muscles, delsysLHS, delsysRHS);
        xsens_processed_intervention.(intervention_field_name).(trialName).jointsByGaitCycle = splitXSENSTrialByGaitCycle(xsensDataStruct.(trialName).joints, xsensLHS, xsensRHS);
    end
end

%% Downsample each gait cycle's data to 101 points and aggregate together, within and across trials.
n_points = 101;
disp(['Downsampling and aggregating the data within each gait cycle to ' num2str(n_points) ' points']);
aggregatedStruct = struct();
for i = 1:length(intervention_field_names)
    intervention_field_name = intervention_field_names{i};
    trialNames = fieldnames(gaitrite_processed_intervention.(intervention_field_name));    
    aggregatedStruct.(intervention_field_name).EMG.PRE.SSV = struct();
    aggregatedStruct.(intervention_field_name).EMG.PRE.FV = struct();
    aggregatedStruct.(intervention_field_name).EMG.POST.SSV = struct();
    aggregatedStruct.(intervention_field_name).EMG.POST.FV = struct();
    aggregatedStruct.(intervention_field_name).XSENS.PRE.SSV = struct();
    aggregatedStruct.(intervention_field_name).XSENS.PRE.FV = struct();
    aggregatedStruct.(intervention_field_name).XSENS.POST.SSV = struct();
    aggregatedStruct.(intervention_field_name).XSENS.POST.FV = struct();    
    numTrials = length(trialNames);
    for trialNum = 1:numTrials
        trialName = trialNames{trialNum};   
        trialNameParts = strsplit(trialName, '_');
        prePost = upper(trialNameParts{1});
        trialCount = str2double(regexp(trialNameParts{2}, '\d+$', 'match'));
        speed = upper(regexp(trialNameParts{2}, '^[A-Za-z]+', 'match'));
        speed = speed{1};
        muscle_names = fieldnames(delsys_processed_intervention.(intervention_field_name).(trialName).musclesByGaitCycle);
        joint_names = fieldnames(xsens_processed_intervention.(intervention_field_name).(trialName).jointsByGaitCycle);    
        % Delsys EMG
        for muscleNum = 1:length(muscle_names)
            muscle_name = muscle_names{muscleNum};
            muscleByGaitCycle = delsys_processed_intervention.(intervention_field_name).(trialName).musclesByGaitCycle.(muscle_name); 
            num_gait_cycles = length(muscleByGaitCycle);
            if ~isfield(aggregatedStruct.(intervention_field_name).EMG.(prePost).(speed), muscle_name)
                aggregatedStruct.(intervention_field_name).EMG.(prePost).(speed).(muscle_name) = [];
            end
            delsys_processed_intervention.(intervention_field_name).(trialName).musclesDownsampled.(muscle_name) = NaN(num_gait_cycles,n_points);
            for gait_cycle_num = 1:num_gait_cycles
                delsys_processed_intervention.(intervention_field_name).(trialName).musclesDownsampled.(muscle_name)(gait_cycle_num,:) = downsampleData(muscleByGaitCycle{gait_cycle_num}, n_points);
            end
            aggregatedStruct.(intervention_field_name).EMG.(prePost).(speed).(muscle_name) = [aggregatedStruct.(intervention_field_name).EMG.(prePost).(speed).(muscle_name); delsys_processed_intervention.(intervention_field_name).(trialName).musclesDownsampled.(muscle_name)];
        end
        % XSENS
        for jointNum = 1:length(joint_names)
            joint_name = joint_names{jointNum};            
            jointsByGaitCycle = xsens_processed_intervention.(intervention_field_name).(trialName).jointsByGaitCycle.(joint_name);
            num_gait_cycles = length(jointsByGaitCycle);
            if ~isfield(aggregatedStruct.(intervention_field_name).XSENS.(prePost).(speed), joint_name)
                aggregatedStruct.(intervention_field_name).XSENS.(prePost).(speed).(joint_name) = [];
            end
            xsens_processed_intervention.(intervention_field_name).(trialName).jointsDownsampled.(joint_name) = NaN(num_gait_cycles,n_points);
            for gait_cycle_num = 1:num_gait_cycles
                xsens_processed_intervention.(intervention_field_name).(trialName).jointsDownsampled.(joint_name)(gait_cycle_num,:) = downsampleData(jointsByGaitCycle{gait_cycle_num}, n_points);
            end
            aggregatedStruct.(intervention_field_name).XSENS.(prePost).(speed).(joint_name) = [aggregatedStruct.(intervention_field_name).XSENS.(prePost).(speed).(joint_name); xsens_processed_intervention.(intervention_field_name).(trialName).jointsDownsampled.(joint_name)];
        end        
    end
end

%% Calculate the number of muscle synergies in each gait cycle of each trial
% NOTE: USE THE NON-TIME NORMALIZED EMG DATA FOR THIS? CHEN RECOMMENDED USING THE TIME-NORMALIZED DATA 
% NEED TO TRY BOTH AND COMPARE
for i = 1:length(intervention_field_names)
    intervention_field_name = intervention_field_names{i};
    trialNames = fieldnames(gaitrite_processed_intervention.(intervention_field_name));  

end