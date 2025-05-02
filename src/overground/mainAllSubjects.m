configPath = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\src\overground\config.json';
config = jsondecode(fileread(configPath));

runConfig = toml.map_to_struct(toml.read('subjects_to_run.toml'));
allSubjects = runConfig.subjects.run;

%% Iterate over each subject
doPlot = false;
for subNum = 1:length(allSubjects)
    subject = allSubjects{subNum};    
    subjectSavePath = fullfile(config.PATHS.ROOT_SAVE, subject, [subject '_' config.PATHS.SAVE_FILE_NAME]);
    disp(['Now running subject (' num2str(subNum) '/' num2str(length(allSubjects)) '): ' subject]);
    mainOneSubject; % Run the main pipeline.
end

%% Plot each subject
allSubjectsPlot = runConfig.subjects.plot;
for subNum = 1:length(allSubjectsPlot)
    subject = allSubjectsPlot{subNum};
    loadPath = fullfile(config.PATHS.ROOT_SAVE, subject, [subject '_Overground_EMG_Kinematics.mat']);
    load(loadPath, 'matchedCycleTable');
    % Plot each gait cycle's filtered data, time normalized (for EMG, scaled to max EMG) and each gait cycle of one condition plotted on top of each other.
    baseSavePath = fullfile(config.PATHS.PLOTS.ROOT, config.PATHS.PLOTS.FILTERED_TIME_NORMALIZED);
    baseSavePathEMG = fullfile(baseSavePath, 'EMG');
    baseSavePathXSENS = fullfile(baseSavePath, 'Joint Angles');
    % plotAllTrials(matchedCycleTable, 'Time-Normalized Non-Normalized EMG', baseSavePathEMG, 'Delsys_TimeNormalized'); 
    plotAllTrials(matchedCycleTable, 'Time-Normalized Scaled EMG', baseSavePathEMG, 'Delsys_Normalized_TimeNormalized'); 
    % plotAllTrials(matchedCycleTable, 'Time-Normalized Joint Angles', baseSavePathXSENS, 'XSENS_TimeNormalized');
end

%% Load the cycleTable and matchedCycleTable from all subjects
categoricalCols = {'Subject','Intervention','PrePost','Speed','Trial','Cycle','StartFoot'};
cycleTable = readtable(config.PATHS.ALL_DATA_CSV.UNMATCHED);
matchedCycleTable = readtable(config.PATHS.ALL_DATA_CSV.MATCHED);
for i = 1:length(categoricalCols)
    cycleTable.(categoricalCols{i}) = categorical(cycleTable.(categoricalCols{i}));
    matchedCycleTable.(categoricalCols{i}) = categorical(matchedCycleTable.(categoricalCols{i}));
end

%% Calculate symmetries
formulaNum = 2; % The modified symmetry formula
levelNumToMatch = 5; % 'trial'
[colNamesL, colNamesR] = getLRColNames(cycleTable);
% Cycle table
cycleTableContraRemoved_NoGR = removeContralateralSideColumns(cycleTable, colNamesL, colNamesR);
grVars = cycleTable.Properties.VariableNames(contains(cycleTable.Properties.VariableNames,'_GR'));
grTable = removevars(cycleTable, ~ismember(cycleTable.Properties.VariableNames, [grVars, categoricalCols]));
cycleTableContraRemoved = addToTable(cycleTableContraRemoved_NoGR, grTable);
scalarColumnNames = getScalarColumnNames(cycleTableContraRemoved);
allColumnNames = cycleTableContraRemoved.Properties.VariableNames;
nonscalarColumnNames = allColumnNames(~ismember(allColumnNames, [scalarColumnNames; categoricalCols']));
cycleTableContraRemovedScalarColumns = removevars(cycleTableContraRemoved, nonscalarColumnNames);
% Compute the symmetry values
lrSidesCycleSymTable = calculateSymmetryAll(cycleTableContraRemovedScalarColumns, '_Sym', formulaNum, levelNumToMatch);
matchedCycleTable = addToTable(matchedCycleTable, lrSidesCycleSymTable); % Can combine the two tables

%% Calculate CGAM from synergies
matchedCyclesPath = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected\matchedCycles.csv";
matchedCycleTable = readtable(matchedCyclesPath);
categoricalCols = {'Subject','Intervention','SessionOrder','Is_Stim','Frequency','Intensity','PrePost','Speed','Trial','Cycle','Side'};
matchedCycleTable.Frequency(ismissing(matchedCycleTable.Frequency)) = 0;
for i = 1:length(categoricalCols)
    matchedCycleTable.(categoricalCols{i}) = categorical(matchedCycleTable.(categoricalCols{i}));
end
vif_cutoff = 10;
% Right off the bat, drop specific columns because bad data.
columnsToDrop = {'StanceDurations_GR_Sym','StrideWidths_GR_Sym','Single_Support_Time_GR_Sym','Double_Support_Time_GR_Sym'};
droppedColsTable = removevars(matchedCycleTable, columnsToDrop);
% Remove the variables that are negative or not symmetries.
varNames = droppedColsTable.Properties.VariableNames;
varsToKeepIdx = contains(varNames, '_Sym') & ~ismember(varNames, 'NumSynergies_Sym') & ~contains(varNames, {'AUC','RMS_EMG','JointAngles_Max','JointAngles_Min'});
symmetryTable = removevars(droppedColsTable, varNames(~varsToKeepIdx));

independentVars = independentVarsFromVIF(symmetryTable, vif_cutoff);
varsToKeepIdxCat = varsToKeepIdx | ismember(varNames, categoricalCols);
symmetryTableWithName = removevars(droppedColsTable, varNames(~varsToKeepIdxCat));
nonGRvarNames = ~contains(symmetryTableWithName.Properties.VariableNames, '_GR') & ~ismember(symmetryTableWithName.Properties.VariableNames, categoricalCols);
grSymTableWithName = removevars(symmetryTableWithName, nonGRvarNames);
grVarNames = symmetryTableWithName.Properties.VariableNames(contains(symmetryTableWithName.Properties.VariableNames, '_GR'));

[cgamTable, matrixStats] = calculateCGAM(symmetryTableWithName, independentVars);
f = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\investigating_cgam';
cgamLevel = 'subject_intervention_prepost_speed';
cgamPath = fullfile(f, [cgamLevel '_CGAM.csv']);
statsPath = fullfile(f, [cgamLevel '_Stats.csv']);
writetable(cgamTable, cgamPath);
writetable(matrixStats, statsPath);
matchedCycleTable = addToTable(matchedCycleTable, cgamTable);

%% cohen's d
catVars = {'Subject', 'Intervention', 'Speed'};
catVarsPrePost = {'Subject', 'Intervention', 'Speed', 'PrePost'};
p = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\investigating_cgam\subject_CGAM.csv";
T = readtable(p);
uniqueRows = unique(T(:, catVars), 'rows','stable');
cohensds = NaN(height(uniqueRows),1);
cohensdTable = uniqueRows;
for i = 1:height(uniqueRows)
    row = uniqueRows(i,:);
    preRow = row;
    preRow.PrePost = categorical({'PRE'});
    postRow = row;
    postRow.PrePost = categorical({'POST'});
    preDataIdx = ismember(T(:, catVarsPrePost), preRow, 'rows');
    postDataIdx = ismember(T(:, catVarsPrePost), postRow, 'rows');
    preData = T(preDataIdx,'CGAM');
    postData = T(postDataIdx,'CGAM');
    cohensd = meanEffectSize(preData.CGAM, postData.CGAM, 'Effect','cohen');
    cohensds(i) = cohensd.Effect;
    cohensdTable.cohensd(i) = cohensd.Effect;
    disp([row.Subject{1} ' ' row.Intervention{1} ' ' row.Speed{1} ' Cohens D: ' num2str(cohensds(i))]);
end
scatter(1:length(cohensds), cohensds);
ylabel('Cohens d of CGAM');

%% Best day
catVars = {'Subject'};
uniqueSubj = unique(cohensdTable(:, catVars),'rows','stable');
bestCohens = NaN(height(uniqueSubj),1);
for i = 1:height(uniqueSubj)
    subjIdx = tableContains(cohensdTable, uniqueSubj(i,:));
    bestCohens(i) = max(cohensdTable(subjIdx,'cohensd'));
end
scatter(1:length(bestCohens), bestCohens);

%% Calculate pre to post change
levelNum = 4; % The level to average the PRE data within
% Percent difference
formulaNum = 2;
prePostCycleChangeTablePercDiff = calculatePrePostChange(cycleTableContraRemovedScalarColumns, formulaNum, levelNum);
prePostChangeMatchedCycleTablePercDiff = calculatePrePostChange(matchedCycleTable, formulaNum, levelNum);
% Difference
formulaNum = 1;
prePostCycleChangeTableDiff = calculatePrePostChange(cycleTableContraRemovedScalarColumns, formulaNum, levelNum);
prePostChangeMatchedCycleTableDiff = calculatePrePostChange(matchedCycleTable, formulaNum, levelNum);
% Combine the two tables 
prePostCycleChangeTable = join(prePostCycleChangeTableDiff, prePostCycleChangeTablePercDiff, 'Keys', 'Name');
prePostChangeMatchedCycleTable = join(prePostChangeMatchedCycleTableDiff, prePostChangeMatchedCycleTablePercDiff, 'Keys', 'Name');

%% Combine all of the tables for all subjects into one main table
% 1. Scalar values only
% 2. Visit, trial, and gait cycle level
% 3. Split the name column by underscores, one column per part of the name
pathTemplate = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\{subject}\{subject}_Overground_EMG_Kinematics.mat';
colsToConvertToNumeric = {'Trial','Cycle'};
grColsToConvertToNumeric = {'Trial','GaitRiteRow'};
trialColToConvertToNumeric = {'Trial'};
splitNameColumns.trialTable = {'Subject','Intervention','PrePost','Speed', 'Trial'};
splitNameColumns.cycleTableContraRemoved = {'Subject','Intervention','PrePost','Speed', 'Trial', 'Cycle', 'Side'};
splitNameColumns.prePostCycleChangeTable = {'Subject','Intervention','Speed', 'Trial', 'Cycle', 'Side'};
splitNameColumns.matchedCycleTable = splitNameColumns.cycleTableContraRemoved;
splitNameColumns.prePostChangeMatchedCycleTable = splitNameColumns.prePostCycleChangeTable;
splitNameColumns.grDistributedTable = {'Subject','Intervention','PrePost','Speed', 'Trial', 'GaitRiteRow', 'Side'};
splitNameColumns.prePostChangeGRDistributedTable = {'Subject','Intervention','Speed', 'Trial', 'GaitRiteRow', 'Side'};
splitNameColumns.grSymTable = splitNameColumns.grDistributedTable;
splitNameColumns.prePostGRSymTable = splitNameColumns.prePostChangeGRDistributedTable;

% trialTable
trialTableAll = combineSubjectTables(allSubjects, pathTemplate, 'trialTable', splitNameColumns.trialTable, trialColToConvertToNumeric);
% cycleTableContraRemoved
cycleTableContraRemovedTableAll = combineSubjectTables(allSubjects, pathTemplate, 'cycleTableContraRemoved', splitNameColumns.cycleTableContraRemoved, colsToConvertToNumeric);
% prePostCycleChangeTable
prePostCycleChangeTableAll = combineSubjectTables(allSubjects, pathTemplate, 'prePostCycleChangeTable', splitNameColumns.prePostCycleChangeTable, colsToConvertToNumeric);
% matchedCycleTable
matchedCycleTableAll = combineSubjectTables(allSubjects, pathTemplate, 'matchedCycleTable', splitNameColumns.matchedCycleTable, colsToConvertToNumeric);
% prePostChangeMatchedCycleTable
prePostChangeMatchedCycleTableAll = combineSubjectTables(allSubjects, pathTemplate, 'prePostChangeMatchedCycleTable', splitNameColumns.prePostChangeMatchedCycleTable, colsToConvertToNumeric);
% grDistributedTable
grDistributedTableAll = combineSubjectTables(allSubjects, pathTemplate, 'grDistributedTable', splitNameColumns.grDistributedTable, grColsToConvertToNumeric);
% prePostChangeGRDistributedTable
prePostChangeGRDistributedTableAll = combineSubjectTables(allSubjects, pathTemplate, 'prePostChangeGRDistributedTable', splitNameColumns.prePostChangeGRDistributedTable, grColsToConvertToNumeric);
% grSymTable
grSymTableAll = combineSubjectTables(allSubjects, pathTemplate, 'grSymTable', splitNameColumns.grSymTable, grColsToConvertToNumeric);
% prePostGRSymTable
prePostGRSymTableAll = combineSubjectTables(allSubjects, pathTemplate, 'prePostGRSymTable', splitNameColumns.prePostGRSymTable, grColsToConvertToNumeric);

%% Add the StimNoStim, Intensity, and Frequency columns
interventionColumnName = 'Intervention';
trialTableAllAddedCols = addStimNoStim_Intensity_FrequencyCols(trialTableAll, interventionColumnName);
cycleTableContraRemovedTableAllAddedCols = addStimNoStim_Intensity_FrequencyCols(cycleTableContraRemovedTableAll, interventionColumnName);
prePostCycleChangeTableAllAddedCols = addStimNoStim_Intensity_FrequencyCols(prePostCycleChangeTableAll, interventionColumnName);
matchedCycleTableAllAddedCols = addStimNoStim_Intensity_FrequencyCols(matchedCycleTableAll, interventionColumnName);
prePostChangeMatchedCycleTableAllAddedCols = addStimNoStim_Intensity_FrequencyCols(prePostChangeMatchedCycleTableAll, interventionColumnName);
grDistributedTableAllAddedCols = addStimNoStim_Intensity_FrequencyCols(grDistributedTableAll, interventionColumnName);
prePostChangeGRDistributedTableAllAddedCols = addStimNoStim_Intensity_FrequencyCols(prePostChangeGRDistributedTableAll, interventionColumnName);
grSymTableAllAddedCols = addStimNoStim_Intensity_FrequencyCols(grSymTableAll, interventionColumnName);
prePostGRSymTableAllAddedCols = addStimNoStim_Intensity_FrequencyCols(prePostGRSymTableAll, interventionColumnName);

%% Write the tables to file.
tablesPathPrefixUnmerged = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\UnmergedTables';
% trialTableAll
writetable(trialTableAllAddedCols, fullfile(tablesPathPrefixUnmerged, 'trialTableAll.csv'));
% cycleTableContraRemoved
writetable(cycleTableContraRemovedTableAllAddedCols, fullfile(tablesPathPrefixUnmerged, 'cycleTableContraRemoved.csv'));
% prePostCycleChangeTable
writetable(prePostCycleChangeTableAllAddedCols, fullfile(tablesPathPrefixUnmerged, 'prePostCycleChangeTable.csv'));
% matchedCycleTable
writetable(matchedCycleTableAllAddedCols, fullfile(tablesPathPrefixUnmerged, 'matchedCycleTable.csv'));
% prePostChangeMatchedCycleTable
writetable(prePostChangeMatchedCycleTableAllAddedCols, fullfile(tablesPathPrefixUnmerged, 'prePostChangeMatchedCycleTable.csv'));
% grDistributedTable
writetable(grDistributedTableAllAddedCols, fullfile(tablesPathPrefixUnmerged, 'grDistributedTable.csv'));
% prePostChangeGRDistributedTable
writetable(prePostChangeGRDistributedTableAllAddedCols, fullfile(tablesPathPrefixUnmerged, 'prePostChangeGRDistributedTable.csv'));
% grSymTable
writetable(grSymTableAllAddedCols, fullfile(tablesPathPrefixUnmerged, 'grSymTable.csv'));
% prePostGRSymTable
writetable(prePostGRSymTableAllAddedCols, fullfile(tablesPathPrefixUnmerged, 'prePostGRSymTable.csv'));

%% Merge the tables that can be merged.
% colNamesToMergeBy = {'GaitRiteRow', 'Cycle'};
% mergedMatchedCycleTable = mergeTables(grSymTableAllAddedCols, matchedCycleTableAllAddedCols, colNamesToMergeBy);
% mergedPrePostMatchedCycleTable = mergeTables(prePostGRSymTableAllAddedCols, prePostChangeMatchedCycleTableAllAddedCols, colNamesToMergeBy);
% mergedUnmatchedCycleTable = mergeTables(grDistributedTableAllAddedCols, cycleTableContraRemovedTableAllAddedCols, colNamesToMergeBy);
% mergedPrePostUnmatchedCycleTable = mergeTables(prePostChangeGRDistributedTableAllAddedCols, prePostCycleChangeTableAllAddedCols, colNamesToMergeBy);

%% Add session number
addpath('Y:\LabMembers\MTillman\GitRepos\Stroke-R01\src\MEPs\MEPs Processing AIM 1');
tepsLogPath = 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\TEPs_log.xlsx';
tepsLog = readExcelFileOneSheet(tepsLogPath, 'Subject','Sheet1');
allColNames = tepsLog.Properties.VariableNames;
colNames = {'Subject', 'SessionOrder', 'SessionCode'};
colNamesIdx = ismember(allColNames, colNames);
reducedTEPsLog = unique(tepsLog(:, colNamesIdx), 'rows');
for i = 1:height(reducedTEPsLog)
    reducedTEPsLog.Subject{i} = ['SS' reducedTEPsLog.Subject{i}];
end
% Map the intervention names
mappedInterventions = containers.Map(config.INTERVENTION_FOLDERS, config.MAPPED_INTERVENTION_FIELDS);
reducedTEPsLog.SessionCode = cellfun(@(x) mappedInterventions(x), reducedTEPsLog.SessionCode, 'UniformOutput', false);
sessionOrderColName = 'SessionOrder';
sessionCodeColName = 'SessionCode';
interventionColName = 'Intervention';
trialTableAllSessionNum = addSessionOrder(trialTableAll, reducedTEPsLog, sessionOrderColName, sessionCodeColName, interventionColName, interventionColName);
mergedMatchedCycleTableSessionNum = addSessionOrder(mergedMatchedCycleTable, reducedTEPsLog, sessionOrderColName, sessionCodeColName, interventionColName, interventionColName);
mergedPrePostMatchedCycleTableSessionNum = addSessionOrder(mergedPrePostMatchedCycleTable, reducedTEPsLog, sessionOrderColName, sessionCodeColName, interventionColName, interventionColName);
mergedUnmatchedCycleTableSessionNum = addSessionOrder(mergedUnmatchedCycleTable, reducedTEPsLog, sessionOrderColName, sessionCodeColName, interventionColName, interventionColName);
mergedPrePostUnmatchedCycleTableSessionNum = addSessionOrder(mergedPrePostUnmatchedCycleTable, reducedTEPsLog, sessionOrderColName, sessionCodeColName, interventionColName, interventionColName);

%% Save the merged tables
tablesPathPrefixMerged = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTables';
writetable(trialTableAllSessionNum, fullfile(tablesPathPrefixMerged, 'trialTableAll.csv'));
writetable(mergedMatchedCycleTableSessionNum, fullfile(tablesPathPrefixMerged, 'matchedCycles.csv'));
writetable(mergedPrePostMatchedCycleTableSessionNum, fullfile(tablesPathPrefixMerged, 'matchedCyclesPrePost.csv'));
writetable(mergedUnmatchedCycleTableSessionNum, fullfile(tablesPathPrefixMerged, 'unmatchedCycles.csv'));
writetable(mergedPrePostUnmatchedCycleTableSessionNum, fullfile(tablesPathPrefixMerged, 'unmatchedCyclesPrePost.csv'));

%% Adjust the L & R sides to "U" and "A" for unaffected and affected sides
tepsLogPath = 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\TEPs_log.xlsx';
tepsLog = readExcelFileOneSheet(tepsLogPath, 'Subject','Sheet1');
colNames = {'Subject','PareticSide'};
inputTableSideCol = 'Side';
tepsLogSideCol = 'PareticSide';
allColNames = tepsLog.Properties.VariableNames;
colNamesIdx = ismember(allColNames, colNames);
reducedTEPsLog = unique(tepsLog(:, colNamesIdx), 'rows');
for i = 1:height(reducedTEPsLog)
    reducedTEPsLog.Subject{i} = ['SS' reducedTEPsLog.Subject{i}];
end
mergedMatchedCycleTableUA = convertLeftRightSideToAffectedUnaffected(mergedMatchedCycleTableSessionNum, reducedTEPsLog, inputTableSideCol, tepsLogSideCol);
mergedPrePostMatchedCycleTableUA = convertLeftRightSideToAffectedUnaffected(mergedPrePostMatchedCycleTableSessionNum, reducedTEPsLog, inputTableSideCol, tepsLogSideCol);
mergedUnmatchedCycleTableUA = convertLeftRightSideToAffectedUnaffected(mergedUnmatchedCycleTableSessionNum, reducedTEPsLog, inputTableSideCol, tepsLogSideCol);
mergedPrePostUnmatchedCycleTableUA = convertLeftRightSideToAffectedUnaffected(mergedPrePostUnmatchedCycleTableSessionNum, reducedTEPsLog, inputTableSideCol, tepsLogSideCol);

%% Save the unaffected and affected side tables
tablesPathPrefixMergedUA = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected';
writetable(trialTableAllSessionNum, fullfile(tablesPathPrefixMergedUA, 'trialTableAll.csv'));
writetable(mergedMatchedCycleTableUA, fullfile(tablesPathPrefixMergedUA, 'matchedCycles.csv'));
writetable(mergedPrePostMatchedCycleTableUA, fullfile(tablesPathPrefixMergedUA, 'matchedCyclesPrePost.csv'));
writetable(mergedUnmatchedCycleTableUA, fullfile(tablesPathPrefixMergedUA, 'unmatchedCycles.csv'));
writetable(mergedPrePostUnmatchedCycleTableUA, fullfile(tablesPathPrefixMergedUA, 'unmatchedCyclesPrePost.csv'));

%% Add the 10MWT data to each table
trialTableAllSessionNum10MWT = join10MWTSpeedToCycleLevelTable(tepsLogPath, fullfile(tablesPathPrefixMergedUA, 'trialTableAll.csv'), configPath);
mergedMatchedCycleTableUA10MWT = join10MWTSpeedToCycleLevelTable(tepsLogPath, fullfile(tablesPathPrefixMergedUA, 'matchedCycles.csv'), configPath);
% mergedPrePostMatchedCycleTableUA10MWT = join10MWTSpeedToCycleLevelTable(tepsLogPath, fullfile(tablesPathPrefixMergedUA, 'matchedCyclesPrePost.csv'), configPath);
mergedUnmatchedCycleTableUA10MWT = join10MWTSpeedToCycleLevelTable(tepsLogPath, fullfile(tablesPathPrefixMergedUA, 'unmatchedCycles.csv'), configPath);
% mergedPrePostUnmatchedCycleTableUA10MWT = join10MWTSpeedToCycleLevelTable(tepsLogPath, fullfile(tablesPathPrefixMergedUA, 'unmatchedCyclesPrePost.csv'), configPath);

%% Save the 10MWT tables
tablesPathPrefixMergedUA10MWT = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected10MWT';
writetable(trialTableAllSessionNum10MWT, fullfile(tablesPathPrefixMergedUA10MWT, 'trialTableAll.csv'));
writetable(mergedMatchedCycleTableUA10MWT, fullfile(tablesPathPrefixMergedUA10MWT, 'matchedCycles.csv'));
writetable(mergedUnmatchedCycleTableUA10MWT, fullfile(tablesPathPrefixMergedUA10MWT, 'unmatchedCycles.csv'));

%% Widen the unaffected and affected side matchedCycle tables
inputTableSideCol = 'Side';
factorColNames = {'Subject','Intervention','Speed','Trial', 'PrePost'};
preStruct.PrePost = 'PRE';
postStruct.PrePost = 'POST';
mergedMatchedCycleTablePath = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected10MWT\matchedCycles.csv';
mergedMatchedCycleTable = readtable(mergedMatchedCycleTablePath);
mergedMatchedCycleTableUAWidePreMean = widenTableBySides(mergedMatchedCycleTable, inputTableSideCol, factorColNames, preStruct, 'mean');
mergedMatchedCycleTableUAWidePreMedian = widenTableBySides(mergedMatchedCycleTable, inputTableSideCol, factorColNames, preStruct, 'median');
mergedMatchedCycleTableUAWidePostMean = widenTableBySides(mergedMatchedCycleTable, inputTableSideCol, factorColNames, postStruct, 'mean');
mergedMatchedCycleTableUAWidePostMedian = widenTableBySides(mergedMatchedCycleTable, inputTableSideCol, factorColNames, postStruct, 'median');

%% Save the widened matchedCycle tables
mergedMatchedCycleTableWidePathPrefix = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffectedWide';
writetable(mergedMatchedCycleTableUAWidePreMean, fullfile(mergedMatchedCycleTableWidePathPrefix, 'matchedCycles_pre_mean.csv'));
writetable(mergedMatchedCycleTableUAWidePreMedian, fullfile(mergedMatchedCycleTableWidePathPrefix, 'matchedCycles_pre_median.csv'));
writetable(mergedMatchedCycleTableUAWidePostMean, fullfile(mergedMatchedCycleTableWidePathPrefix, 'matchedCycles_post_mean.csv'));
writetable(mergedMatchedCycleTableUAWidePostMedian, fullfile(mergedMatchedCycleTableWidePathPrefix, 'matchedCycles_post_median.csv'));

%% Widen the unaffected and affected side unmatchedCycle tables
mergedUnmatchedCycleTablePath = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected10MWT\unmatchedCycles.csv';
mergedUnmatchedCycleTable = readtable(mergedUnmatchedCycleTablePath);
mergedUnmatchedCycleTableUAWidePreMean = widenTableBySides(mergedUnmatchedCycleTable, inputTableSideCol, factorColNames, preStruct, 'mean');
mergedUnmatchedCycleTableUAWidePreMedian = widenTableBySides(mergedUnmatchedCycleTable, inputTableSideCol, factorColNames, preStruct, 'median');
mergedUnmatchedCycleTableUAWidePostMean = widenTableBySides(mergedUnmatchedCycleTable, inputTableSideCol, factorColNames, postStruct, 'mean');
mergedUnmatchedCycleTableUAWidePostMedian = widenTableBySides(mergedUnmatchedCycleTable, inputTableSideCol, factorColNames, postStruct, 'median');

%% Save the widened unmatchedCycle tables
mergedMatchedCycleTableWidePathPrefix = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffectedWide';
writetable(mergedUnmatchedCycleTableUAWidePreMean, fullfile(mergedMatchedCycleTableWidePathPrefix, 'unmatchedCycles_pre_mean.csv'));
writetable(mergedUnmatchedCycleTableUAWidePreMedian, fullfile(mergedMatchedCycleTableWidePathPrefix, 'unmatchedCycles_pre_median.csv'));
writetable(mergedUnmatchedCycleTableUAWidePostMean, fullfile(mergedMatchedCycleTableWidePathPrefix, 'unmatchedCycles_post_mean.csv'));
writetable(mergedUnmatchedCycleTableUAWidePostMedian, fullfile(mergedMatchedCycleTableWidePathPrefix, 'unmatchedCycles_post_median.csv'));