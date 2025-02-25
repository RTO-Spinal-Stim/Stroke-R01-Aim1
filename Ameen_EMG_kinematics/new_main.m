%% Created by MT 02/04/25
% The main pipeline for R01 Stroke Spinal Stim Aim 1 (using tables)
clc;
clearvars;
subject = 'SS13';
% Folder to load the data from.
subjectLoadPath = fullfile('Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data', subject);
% Path to save the data to.
subjectSaveFolder = fullfile('Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\', subject);
saveFileName = 'Overground_EMG_Kinematics.mat';
codeFolderPath = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Ameen_EMG_kinematics';
addpath(genpath(codeFolderPath));

doPlot = false;

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
visitTable = table;

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
if doPlot
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
if doPlot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\Trials_GaitEvents';
    plotTrialWithGaitEvents(trialTable, 'Filtered EMG and Gait Events', baseSavePathEMG, 'Delsys_Filtered', 'Delsys_Frames');
    baseSavePathXSENS = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\Joint Angles\Trials_GaitEvents';
    plotTrialWithGaitEvents(trialTable, 'Filtered Joint Angles and GaitEvents', baseSavePathXSENS, 'XSENS_Filtered', 'XSENS_Frames');
end

%% Split by gait cycle
disp('Splitting XSENS & Delsys by gait cycle');
xsensCyclesTable = splitTrialsByGaitCycle(trialTable, 'XSENS_Filtered', 'XSENS_Frames');
delsysCyclesTable = splitTrialsByGaitCycle(trialTable, 'Delsys_Filtered', 'Delsys_Frames');
cycleTable = addToTable(cycleTable, xsensCyclesTable);
cycleTable = addToTable(cycleTable, delsysCyclesTable);

%% Plot each gait cycle's filtered data, non-time normalized and each gait cycle of one condition plotted on top of each other.
if doPlot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\Filtered_GaitCycles';
    plotAllTrials(delsysCyclesTable, 'Filtered EMG', baseSavePathEMG, 'Delsys_Filtered');
    baseSavePathXSENS = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\Joint Angles\Filtered_GaitCycles';
    plotAllTrials(xsensCyclesTable, 'Filtered Joint Angles', baseSavePathXSENS, 'XSENS_Filtered');
end

%% Downsample each gait cycle's data to 101 points.
n_points = config.NUM_POINTS;
disp(['Downsampling the data within each gait cycle to ' num2str(n_points) ' points']);
xsensDownsampledTable = downsampleAllData(cycleTable, 'XSENS_Filtered', 'XSENS_TimeNormalized', n_points);
delsysDownsampledTable = downsampleAllData(cycleTable, 'Delsys_Filtered', 'Delsys_TimeNormalized', n_points);
cycleTable = addToTable(cycleTable, xsensDownsampledTable);
cycleTable = addToTable(cycleTable, delsysDownsampledTable);

%% Plot each gait cycle's time-normalized data, and each gait cycle of one condition plotted on top of each other.
if doPlot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\TimeNormalized_GaitCycles';
    plotAllTrials(cycleTable, 'Time-Normalized EMG', baseSavePathEMG, 'Delsys_TimeNormalized');
    baseSavePathXSENS = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\Joint Angles\TimeNormalized_GaitCycles';
    plotAllTrials(cycleTable, 'Time-Normalized Joint Angles', baseSavePathXSENS, 'XSENS_TimeNormalized');
end

%% Identify the max EMG data value across one whole visit (all trials & gait cycles)
maxEMGTable = maxEMGValuePerVisit(cycleTable, 'Delsys_TimeNormalized', 'Max_EMG_Value');
visitTable = addToTable(visitTable, maxEMGTable);

%% Normalize the time-normalized EMG data to the max value across one whole visit (all trials & gait cycles)
normalizedEMGTable = normalizeAllDataToVisitValue(cycleTable, 'Delsys_TimeNormalized', visitTable, 'Max_EMG_Value', 'Delsys_Normalized_TimeNormalized');
cycleTable = addToTable(cycleTable, normalizedEMGTable);

%% Plot each gait cycle's scaled to max EMG data, and each gait cycle of one condition plotted on top of each other.
if doPlot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\ScaledToMax_GaitCycles';
    plotAllTrials(cycleTable, 'Scaled To Max EMG', baseSavePathEMG, 'Delsys_Normalized_TimeNormalized');    
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
synergiesTableL = calculateSynergiesAll(cycleTable, 'Delsys_Normalized_TimeNormalized', musclesL, VAFthresh, 'L');
synergiesTableR = calculateSynergiesAll(cycleTable, 'Delsys_Normalized_TimeNormalized', musclesR, VAFthresh, 'R');
cycleTable = addToTable(cycleTable, synergiesTableL);
cycleTable = addToTable(cycleTable, synergiesTableR);

%% Scatterplot the number of muscle synergies & the step lengths
% if doPlot
%     baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\NumSynergies';
%     scatterPlotPerGaitCyclePerIntervention(delsysStruct, 'Num Synergies', baseSavePathEMG, 'NumSynergies');    
% end

%% SPM Analysis for EMG & XSENS
disp('Running SPM analysis');
spmTableXSENS = SPManalysisAll(cycleTable, 'XSENS_TimeNormalized', 'XSENS_SPM', jointsL, jointsR);
spmTableDelsys = SPManalysisAll(cycleTable, 'Delsys_TimeNormalized', 'Delsys_SPM', musclesL, musclesR);
visitTable = addToTable(visitTable, spmTableXSENS);
visitTable = addToTable(visitTable, spmTableDelsys);

%% Average the data within one visit.
disp('Averaging the data within one visit');
avgTableXSENS = avgStructAll(cycleTable, 'XSENS_TimeNormalized', 'XSENS_Averaged', 2);
avgTableDelsys = avgStructAll(cycleTable, 'Delsys_TimeNormalized', 'Delsys_Averaged', 2);
visitTable = addToTable(visitTable, avgTableXSENS);
visitTable = addToTable(visitTable, avgTableDelsys);

%% Calculate the magnitude and duration of L vs. R differences obtained from SPM in one visit.
disp('Calculating magnitude & durations of L vs. R differences from SPM');
magDurTableXSENS = magsDursDiffsLR_All(visitTable, 'XSENS_SPM', 'XSENS_Averaged', 'XSENS_MagsDiffs');
magDurTableDelsys = magsDursDiffsLR_All(visitTable, 'Delsys_SPM', 'Delsys_Averaged', 'Deksys_MagsDiffs');
visitTable = addToTable(visitTable, magDurTableXSENS);
visitTable = addToTable(visitTable, magDurTableDelsys);

%% Calculate area under the curve (AUC)
disp('Calculating area under the curve (AUC)');
aucTableXSENS = calculateAUCAll(cycleTable, 'XSENS_TimeNormalized', 'AUC_JointAngles');
aucTableDelsys = calculateAUCAll(cycleTable, 'Delsys_Normalized_TimeNormalized', 'AUC_EMG');
cycleTable = addToTable(cycleTable, aucTableXSENS);
cycleTable = addToTable(cycleTable, aucTableDelsys);

%% Calculate root mean square (RMS)
disp('Calculating RMS');
rmsTableXSENS = calculateRMSAll(cycleTable, 'XSENS_TimeNormalized', 'RMS_JointAngles');
rmsTableDelsys = calculateRMSAll(cycleTable, 'Delsys_Normalized_TimeNormalized', 'RMS_EMG');
cycleTable = addToTable(cycleTable, rmsTableXSENS);
cycleTable = addToTable(cycleTable, rmsTableDelsys);

%% Calculate root mean squared error (RMSE)
disp('Calculating RMSE');
rmseTableXSENS = calculateLRRMSEAll(cycleTable, 'XSENS_TimeNormalized', 'RMSE_JointAngles');
rmseTableDelsys = calculateLRRMSEAll(cycleTable, 'Delsys_Normalized_TimeNormalized', 'RMSE_EMG');
cycleTable = addToTable(cycleTable, rmseTableXSENS);
cycleTable = addToTable(cycleTable, rmseTableDelsys);

%% Calculate cross-correlations
disp('Calculating cross correlations');
xcorrTableXSENS = calculateLRCrossCorrAll(cycleTable, 'XSENS_TimeNormalized', 'JointAngles_CrossCorr');
xcorrTableDelsys = calculateLRCrossCorrAll(cycleTable, 'Delsys_Normalized_TimeNormalized', 'EMG_CrossCorr');
cycleTable = addToTable(cycleTable, xcorrTableXSENS);
cycleTable = addToTable(cycleTable, xcorrTableDelsys);

%% Calculate range of motion (ROM)
disp('Calculating range of motion');
romTableXSENS = calculateRangeAll(cycleTable, 'XSENS_TimeNormalized', 'JointAngles');
cycleTable = addToTable(cycleTable, romTableXSENS);

%% Calculate symmetries
disp('Calculating symmetry indices');
grColumnsIn = {'stepLengthsAll', 'swingDurationsAll', 'stepWidthsAll'};
grColumnsOut = {'stepLengthSym', 'swingDurationSym', 'stepWidthSym'};
startIdx = [2, 3, 2];
endIdx = repmat(-1,1,length(grColumnsIn));
formulaNum = 3;
spatiotemporalSymTable = calculateSymmetryGRAll(trialTable, grColumnsIn, grColumnsOut, 'leftRightIdxAll', startIdx, endIdx, formulaNum);
trialTable = addToTable(trialTable, spatiotemporalSymTable);
stepLengthsSymTable = calculateSymmetryAll(cycleTable, 'StepLengthsL','StepLengthsR');

%% Save the structs to the participant's save folder.
subjectSavePath = fullfile(subjectSaveFolder, saveFileName);
save(subjectSavePath, 'trialTable', 'visitTable','cycleTable','-v6');
disp(['Saved ' subject ' structs to: ' subjectSavePath]);