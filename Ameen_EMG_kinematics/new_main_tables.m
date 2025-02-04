%% Created by MT 02/04/25
% The main pipeline for R01 Stroke Spinal Stim Aim 1 (using tables)
clc;
clearvars;
subject = 'SS13';
% Folder to load the data from.
subjectLoadPath = fullfile('Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data', subject);
% Path to save the data to.
subjectSavePath = strcat('Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\', subject, '.mat');
codeFolderPath = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Ameen_EMG_kinematics';
addpath(genpath(codeFolderPath));

plot = false;

%% Get configuration
configFilePath = fullfile(codeFolderPath,'config.json');
config = jsondecode(fileread(configFilePath));
disp(['Loaded configuration from: ' configFilePath]);

intervention_folders = config.INTERVENTION_FOLDERS;
intervention_field_names = config.MAPPED_INTERVENTION_FIELDS;
mapped_interventions = containers.Map(intervention_folders, intervention_field_names);
gaitriteConfig = config.GAITRITE;
delsysConfig = config.DELSYS_EMG;
xsensConfig = config.XSENS;
regexsConfig = config.REGEXS;

%% Initialize tables
prePostTable = table;
trialTable = table;
cycleTable = table;

%% GaitRite Processing
disp('Preprocessing Gaitrite');
subject_gaitrite_folder = fullfile(subjectLoadPath, gaitriteConfig.FOLDER_NAME);
gaitRiteTable = processGaitRiteAllInterventions(gaitriteConfig, subject_gaitrite_folder, intervention_folders, mapped_interventions, regexsConfig);
trialTable = addToTable(trialTable, gaitRiteTable);

%% Delsys Processing
disp('Preprocessing Delsys');
subject_delsys_folder = fullfile(subjectLoadPath, delsysConfig.FOLDER_NAME);
delsysTable = processDelsysAllInterventions(delsysConfig, subject_delsys_folder, intervention_folders, mapped_interventions, regexsConfig);
trialTable = addToTable(trialTable, delsysTable);

%% XSENS Processing
disp('Preprocessing XSENS');
subject_xsens_folder = fullfile(subjectLoadPath, xsensConfig.FOLDER_NAME);
xsensTable = processXSENSAllInterventions(xsensConfig, subject_xsens_folder, intervention_folders, mapped_interventions, regexsConfig);
trialTable = addToTable(trialTable, xsensTable);

%% Plot raw and filtered timeseries data
if plot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\Raw_Filtered';
    plotRawAndFilteredData(trialTable, 'Raw and Filtered EMG', baseSavePathEMG, struct('Raw','Delsys_Loaded', 'Filtered', 'Delsys_Filtered'), true);
    baseSavePathXSENS = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\Joint Angles\Raw_Filtered';
    plotRawAndFilteredData(trialTable, 'Raw and Filtered Joint Angles', baseSavePathXSENS, struct('Raw','XSENS_Loaded', 'Filtered', 'XSENS_Filtered'), false);
end

%% Time synchronization
disp('Time synchronizing XSENS & Delsys');
syncedTableDelsys = timeSynchronize(trialTable, delsysConfig.SAMPLING_FREQUENCY, 'seconds', 'Delsys_Frames');
syncedTableXSENS = timeSynchronize(trialTable, xsensConfig.SAMPLING_FREQUENCY, 'seconds', 'XSENS_Frames');
trialTable = addToTable(trialTable, syncedTableDelsys);
trialTable = addToTable(trialTable, syncedTableXSENS);

%% Plot each trial's data individually, along with gait event information.
if plot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\Trials_GaitEvents';
    plotTrialWithGaitEvents(trialTable, 'Filtered EMG and Gait Events', baseSavePathEMG, 'Delsys_Filtered', 'Delsys_Frames');
    baseSavePathXSENS = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\Joint Angles\Trials_GaitEvents';
    plotTrialWithGaitEvents(trialTable, 'Filtered Joint Angles and GaitEvents', baseSavePathXSENS, 'XSENS_Filtered', 'XSENS_Frames');
end

%% Split by gait cycle

%% Plot each gait cycle's filtered data, non-time normalized and each gait cycle of one condition plotted on top of each other.
if plot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\Filtered_GaitCycles';
    plotAllTrials(delsysStruct, 'Filtered EMG', baseSavePathEMG, 'Filtered');
    baseSavePathXSENS = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\Joint Angles\Filtered_GaitCycles';
    plotAllTrials(xsensStruct, 'Filtered Joint Angles', baseSavePathXSENS, 'Filtered');
end

%% Downsample each gait cycle's data to 101 points and aggregate together, within and across trials.

%% Plot each gait cycle's time-normalized data, and each gait cycle of one condition plotted on top of each other.
if plot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\TimeNormalized_GaitCycles';
    plotAllTrials(delsysStruct, 'Time-Normalized EMG', baseSavePathEMG, 'TimeNormalized');
    baseSavePathXSENS = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\Joint Angles\TimeNormalized_GaitCycles';
    plotAllTrials(xsensStruct, 'Time-Normalized Joint Angles', baseSavePathXSENS, 'TimeNormalized');
end

%% Identify the max EMG data value across one whole visit (all trials & gait cycles)

%% Normalize the time-normalized EMG data to the max value across one whole visit (all trials & gait cycles)

%% Plot each gait cycle's scaled to max EMG data, and each gait cycle of one condition plotted on top of each other.
if plot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\ScaledToMax_GaitCycles';
    plotAllTrials(delsysStruct, 'Scaled To Max EMG', baseSavePathEMG, 'ScaledToMax');    
end

%% Set up muscle & joint names for analyses
disp('Defining L & R names');
musclesLR = delsysConfig.MUSCLES;
jointsLR = xsensConfig.JOINTS;
musclesL = cell(size(musclesLR));
musclesR = cell(size(musclesLR));
jointsL = cell(size(jointsLR));
jointsR = cell(size(jointsLR));
for i = 1:length(musclesLR)
    musclesL{i} = ['L' musclesLR{i}];
    musclesR{i} = ['R' musclesLR{i}];
end
for i = 1:length(jointsLR)
    jointsL{i} = ['L' jointsLR{i}];
    jointsR{i} = ['R' jointsLR{i}];
end

%% Calculate the number of muscle synergies in each gait cycle of each trial
disp('Computing the number of muscle synergies');
config = jsondecode(fileread(configFilePath));
VAFthresh = config.DELSYS_EMG.VAF_THRESHOLD;

%% Scatter plot the number of muscle synergies & the step lengths
if plot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\NumSynergies';
    scatterPlotPerGaitCyclePerIntervention(delsysStruct, 'Num Synergies', baseSavePathEMG, 'NumSynergies');    
end

%% SPM Analysis for EMG & XSENS
disp('Running SPM analysis');

%% Calculate the magnitude and duration of L vs. R differences obtained from SPM
disp('Calculating magnitude & durations of L vs. R differences from SPM');

%% Save the structs to the participant's save folder.
save(subjectSavePath, 'delsysStruct','gaitRiteStruct','xsensStruct','-v6');
disp(['Saved ' subject ' structs to: ' subjectSavePath]);