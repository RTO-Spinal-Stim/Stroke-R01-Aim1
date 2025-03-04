%% Created by MT 02/04/25
% The main pipeline for R01 Stroke Spinal Stim Aim 1 (using tables)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Comment this part out when running all subjects at once.
% clc;
% clearvars;
% subject = 'SS13';
% configFilePath = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Ameen_EMG_kinematics\config.json';
% config = jsondecode(fileread(configFilePath));
% disp(['Loaded configuration from: ' configFilePath]);
% doPlot = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get configuration
intervention_folders = config.INTERVENTION_FOLDERS;
intervention_field_names = config.MAPPED_INTERVENTION_FIELDS;
mapped_interventions = containers.Map(intervention_folders, intervention_field_names);
gaitriteConfig = config.GAITRITE;
delsysConfig = config.DELSYS_EMG;
xsensConfig = config.XSENS;
regexsConfig = config.REGEXS;

% Folder to load the data from.
pathsConfig = config.PATHS;
subjectLoadPath = fullfile(pathsConfig.ROOT_LOAD, subject);
% Path to save the data to.
subjectSaveFolder = fullfile(pathsConfig.ROOT_SAVE, subject);
saveFileName = pathsConfig.SAVE_FILE_NAME;
codeFolderPath = pathsConfig.CODE_FOLDER_PATH; % Folder where the code lives
addpath(genpath(pathsConfig.CODE_FOLDER_PATH));

%% Initialize tables
prePostTable = table;
trialTable = table;
matchedCycleTable = table;
visitTable = table;

%% GaitRite Processing
subject_gaitrite_folder = fullfile(subjectLoadPath, gaitriteConfig.FOLDER_NAME);
gaitRiteTable = processGaitRiteAllInterventions(gaitriteConfig, subject_gaitrite_folder, intervention_folders, mapped_interventions, regexsConfig);
trialTable = addToTable(trialTable, gaitRiteTable);

%% Delsys Processing
subject_delsys_folder = fullfile(subjectLoadPath, delsysConfig.FOLDER_NAME);
delsysTable = processDelsysAllInterventions(delsysConfig, subject_delsys_folder, intervention_folders, mapped_interventions, regexsConfig);
trialTable = addToTable(trialTable, delsysTable);

%% XSENS Processing
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
xsensCyclesTable = splitTrialsByGaitCycleMatchingLR(trialTable, 'XSENS_Filtered', 'XSENS_Frames');
delsysCyclesTable = splitTrialsByGaitCycleMatchingLR(trialTable, 'Delsys_Filtered', 'Delsys_Frames');
matchedCycleTable = addToTable(matchedCycleTable, xsensCyclesTable);
matchedCycleTable = addToTable(matchedCycleTable, delsysCyclesTable);

%% Plot each gait cycle's filtered data, non-time normalized and each gait cycle of one condition plotted on top of each other.
if doPlot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\Filtered_GaitCycles';
    plotAllTrials(delsysCyclesTable, 'Filtered EMG', baseSavePathEMG, 'Delsys_Filtered');
    baseSavePathXSENS = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\Joint Angles\Filtered_GaitCycles';
    plotAllTrials(xsensCyclesTable, 'Filtered Joint Angles', baseSavePathXSENS, 'XSENS_Filtered');
end

%% Downsample each gait cycle's data to 101 points.
n_points = config.NUM_POINTS;
xsensDownsampledTable = downsampleAllData(matchedCycleTable, 'XSENS_Filtered', 'XSENS_TimeNormalized', n_points);
delsysDownsampledTable = downsampleAllData(matchedCycleTable, 'Delsys_Filtered', 'Delsys_TimeNormalized', n_points);
matchedCycleTable = addToTable(matchedCycleTable, xsensDownsampledTable);
matchedCycleTable = addToTable(matchedCycleTable, delsysDownsampledTable);

%% Plot each gait cycle's time-normalized data, and each gait cycle of one condition plotted on top of each other.
if doPlot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\TimeNormalized_GaitCycles';
    plotAllTrials(matchedCycleTable, 'Time-Normalized EMG', baseSavePathEMG, 'Delsys_TimeNormalized');
    baseSavePathXSENS = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\Joint Angles\TimeNormalized_GaitCycles';
    plotAllTrials(matchedCycleTable, 'Time-Normalized Joint Angles', baseSavePathXSENS, 'XSENS_TimeNormalized');
end

%% Identify the max EMG data value across one whole visit (all trials & gait cycles)
maxEMGTable = maxEMGValuePerVisit(matchedCycleTable, 'Delsys_TimeNormalized', 'Max_EMG_Value');
visitTable = addToTable(visitTable, maxEMGTable);

%% Normalize the time-normalized EMG data to the max value across one whole visit (all trials & gait cycles)
normalizedEMGTable = normalizeAllDataToVisitValue(matchedCycleTable, 'Delsys_TimeNormalized', visitTable, 'Max_EMG_Value', 'Delsys_Normalized_TimeNormalized');
matchedCycleTable = addToTable(matchedCycleTable, normalizedEMGTable);

%% Plot each gait cycle's scaled to max EMG data, and each gait cycle of one condition plotted on top of each other.
if doPlot
    baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\ScaledToMax_GaitCycles';
    plotAllTrials(matchedCycleTable, 'Scaled To Max EMG', baseSavePathEMG, 'Delsys_Normalized_TimeNormalized');    
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
VAFthresh = config.DELSYS_EMG.VAF_THRESHOLD;
synergiesTableL = calculateSynergiesAll(matchedCycleTable, 'Delsys_Normalized_TimeNormalized', musclesL, VAFthresh, 'L');
synergiesTableR = calculateSynergiesAll(matchedCycleTable, 'Delsys_Normalized_TimeNormalized', musclesR, VAFthresh, 'R');
matchedCycleTable = addToTable(matchedCycleTable, synergiesTableL);
matchedCycleTable = addToTable(matchedCycleTable, synergiesTableR);

%% Scatterplot the number of muscle synergies & the step lengths
% if doPlot
%     baseSavePathEMG = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Plots\EMG\NumSynergies';
%     scatterPlotPerGaitCyclePerIntervention(delsysStruct, 'Num Synergies', baseSavePathEMG, 'NumSynergies');    
% end

%% SPM Analysis for EMG & XSENS
spmTableXSENS = SPManalysisAll(matchedCycleTable, 'XSENS_TimeNormalized', 'XSENS_SPM', jointsL, jointsR);
spmTableDelsys = SPManalysisAll(matchedCycleTable, 'Delsys_TimeNormalized', 'Delsys_SPM', musclesL, musclesR);
visitTable = addToTable(visitTable, spmTableXSENS);
visitTable = addToTable(visitTable, spmTableDelsys);

%% Average the data within one visit.
avgTableXSENS = avgStructAll(matchedCycleTable, 'XSENS_TimeNormalized', 'XSENS_Averaged', 2);
avgTableDelsys = avgStructAll(matchedCycleTable, 'Delsys_TimeNormalized', 'Delsys_Averaged', 2);
visitTable = addToTable(visitTable, avgTableXSENS);
visitTable = addToTable(visitTable, avgTableDelsys);

%% Calculate the magnitude and duration of L vs. R differences obtained from SPM in one visit.
magDurTableXSENS = magsDursDiffsLR_All(visitTable, 'XSENS_SPM', 'XSENS_Averaged', 'XSENS_MagsDiffs');
magDurTableDelsys = magsDursDiffsLR_All(visitTable, 'Delsys_SPM', 'Delsys_Averaged', 'Delsys_MagsDiffs');
visitTable = addToTable(visitTable, magDurTableXSENS);
visitTable = addToTable(visitTable, magDurTableDelsys);

%% Calculate area under the curve (AUC)
aucTableXSENS = calculateAUCAll(matchedCycleTable, 'XSENS_TimeNormalized', 'AUC_JointAngles');
aucTableDelsys = calculateAUCAll(matchedCycleTable, 'Delsys_Normalized_TimeNormalized', 'AUC_EMG');
matchedCycleTable = addToTable(matchedCycleTable, aucTableXSENS);
matchedCycleTable = addToTable(matchedCycleTable, aucTableDelsys);

%% Calculate root mean square (RMS)
rmsTableXSENS = calculateRMSAll(matchedCycleTable, 'XSENS_TimeNormalized', 'RMS_JointAngles');
rmsTableDelsys = calculateRMSAll(matchedCycleTable, 'Delsys_Normalized_TimeNormalized', 'RMS_EMG');
matchedCycleTable = addToTable(matchedCycleTable, rmsTableXSENS);
matchedCycleTable = addToTable(matchedCycleTable, rmsTableDelsys);

%% Calculate root mean squared error (RMSE)
rmseTableXSENS = calculateLRRMSEAll(matchedCycleTable, 'XSENS_TimeNormalized', 'RMSE_JointAngles');
rmseTableDelsys = calculateLRRMSEAll(matchedCycleTable, 'Delsys_Normalized_TimeNormalized', 'RMSE_EMG');
matchedCycleTable = addToTable(matchedCycleTable, rmseTableXSENS);
matchedCycleTable = addToTable(matchedCycleTable, rmseTableDelsys);

%% Calculate cross-correlations
xcorrTableXSENS = calculateLRCrossCorrAll(matchedCycleTable, 'XSENS_TimeNormalized', 'JointAngles_CrossCorr');
xcorrTableDelsys = calculateLRCrossCorrAll(matchedCycleTable, 'Delsys_Normalized_TimeNormalized', 'EMG_CrossCorr');
matchedCycleTable = addToTable(matchedCycleTable, xcorrTableXSENS);
matchedCycleTable = addToTable(matchedCycleTable, xcorrTableDelsys);

%% Calculate range of motion (ROM)
romTableXSENS = calculateRangeAll(matchedCycleTable, 'XSENS_TimeNormalized', 'JointAngles');
matchedCycleTable = addToTable(matchedCycleTable, romTableXSENS);

%% Calculate symmetries
grColumnsIn = {'stepLengthsAll', 'swingDurationsAll', 'stepWidthsAll'};
grColumnsOut = {'stepLength_Sym', 'swingDuration_Sym', 'stepWidth_Sym'};
startIdx = [2, 3, 2];
endIdx = repmat(-1,1,length(grColumnsIn));
formulaNum = 3;
spatiotemporalSymTable = calculateSymmetryGRAll(trialTable, grColumnsIn, grColumnsOut, 'leftRightIdxAll', startIdx, endIdx, formulaNum);
trialTable = addToTable(trialTable, spatiotemporalSymTable);
[colNamesL, colNamesR] = getLRColNames(matchedCycleTable);
lrSidesSymTable = calculateSymmetryAll(matchedCycleTable, colNamesL, colNamesR, '_Sym');
matchedCycleTable = addToTable(matchedCycleTable, lrSidesSymTable); 

%% Save the structs to the participant's save folder.
subjectSavePath = fullfile(subjectSaveFolder, [subject '_' saveFileName]);
if ~isfolder(subjectSaveFolder)
    mkdir(subjectSaveFolder);
end
save(subjectSavePath, 'trialTable', 'visitTable','matchedCycleTable','-v6');
disp(['Saved ' subject ' tables to: ' subjectSavePath]);