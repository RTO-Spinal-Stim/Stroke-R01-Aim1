configPath = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Ameen_EMG_kinematics\config.json';
config = jsondecode(fileread(configPath));

subjectRegex = [config.REGEXS.SUBJECT_ID '\>']; % \> is for the end of a word, to avoid returning "SS14_" folder

subjectFolder = config.PATHS.ROOT_LOAD;
dirItems = dir(subjectFolder); % Get all items in subject data directory

% Get the directory names
dirNames = {dirItems([dirItems.isdir]).name};
dirNames = dirNames(~ismember(dirNames, {'.', '..'}));

subjects = {};
for i = 1:length(dirNames)
    if regexp(dirNames{i}, subjectRegex)
        subjects = [subjects; dirNames{i}];
    end
end

% Remove unwanted subjects
% 8, 9, 10 are the ones with muscle renamings needed. CHECK THE MUSCLES
% WITH OTHER SUBJECTS!
subjectsToRemove = {'SS27'};
subjects(ismember(subjects, subjectsToRemove)) = [];

% Subjects to redo
subjectsToRedo = {};

%% Iterate over each subject
doPlot = true;
for subNum = 1:length(subjects)
    subject = subjects{subNum};    
    subjectSavePath = fullfile(config.PATHS.ROOT_SAVE, subject, [subject '_' config.PATHS.SAVE_FILE_NAME]);
    if isfile(subjectSavePath) && ~ismember(subject, subjectsToRedo)
        disp(['Skipping subject (' num2str(subNum) '/' num2str(length(subjects)) '): ' subject]);
        continue; % Skip the subjects that have already been done.
    end
    disp(['Now running subject (' num2str(subNum) '/' num2str(length(subjects)) '): ' subject]);
    mainOneSubject; % Run the main pipeline.
end

%% Combine all of the tables for all subjects into one main table
% 1. Scalar values only
% 2. Visit, trial, and gait cycle level
% 3. Split the name column by underscores, one column per part of the name
pathTemplate = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\{subject}\{subject}_Overground_EMG_Kinematics.mat';
splitNameColumns.cycleTableContraRemoved = {'Subject','Intervention','PrePost','Speed', 'Trial', 'Cycle', 'Side'};
splitNameColumns.prePostCycleChangeTable = {'Subject','Intervention','Speed', 'Trial', 'Cycle', 'Side'};
splitNameColumns.matchedCycleTable = splitNameColumns.cycleTableContraRemoved;
splitNameColumns.prePostChangeMatchedCycleTable = splitNameColumns.prePostCycleChangeTable;
splitNameColumns.grDistributedTable = {'Subject','Intervention','PrePost','Speed', 'Trial', 'GaitRiteRow', 'Side'};
splitNameColumns.prePostChangeGRDistributedTable = {'Subject','Intervention','Speed', 'Trial', 'GaitRiteRow', 'Side'};
splitNameColumns.grSymTable = splitNameColumns.grDistributedTable;
splitNameColumns.prePostGRSymTable = splitNameColumns.prePostChangeGRDistributedTable;

% cycleTableContraRemoved
cycleTableContraRemovedTableAll = combineSubjectTables(subjects, pathTemplate, 'cycleTableContraRemoved', splitNameColumns.cycleTableContraRemoved);
% prePostCycleChangeTable
prePostCycleChangeTableAll = combineSubjectTables(subjects, pathTemplate, 'prePostCycleChangeTable', splitNameColumns.prePostCycleChangeTable);
% matchedCycleTable
matchedCycleTableAll = combineSubjectTables(subjects, pathTemplate, 'matchedCycleTable', splitNameColumns.matchedCycleTable);
% prePostChangeMatchedCycleTable
prePostChangeMatchedCycleTableAll = combineSubjectTables(subjects, pathTemplate, 'prePostChangeMatchedCycleTable', splitNameColumns.prePostChangeMatchedCycleTable);
% grDistributedTable
grDistributedTableAll = combineSubjectTables(subjects, pathTemplate, 'grDistributedTable', splitNameColumns.grDistributedTable);
% prePostChangeGRDistributedTable
prePostChangeGRDistributedTableAll = combineSubjectTables(subjects, pathTemplate, 'prePostChangeGRDistributedTable', splitNameColumns.prePostChangeGRDistributedTable);
% grSymTable
grSymTableAll = combineSubjectTables(subjects, pathTemplate, 'grSymTable', splitNameColumns.grSymTable);
% prePostGRSymTable
prePostGRSymTableAll = combineSubjectTables(subjects, pathTemplate, 'prePostGRSymTable', splitNameColumns.prePostGRSymTable);

%% Write the tables to file.
% cycleTableContraRemoved
cycleTableContraRemovedPath = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\cycleTableContraRemoved.csv';
writetable(cycleTableContraRemovedTableAll, cycleTableContraRemovedPath);
% prePostCycleChangeTable
prePostCycleChangeTablePath = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\prePostCycleChangeTable.csv';
writetable(prePostCycleChangeTableAll, prePostCycleChangeTablePath);
% matchedCycleTable
matchedCycleTablePath = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\matchedCycleTable.csv';
writetable(matchedCycleTableAll, matchedCycleTablePath);
% prePostChangeMatchedCycleTable
prePostChangeMatchedCycleTablePath = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\prePostChangeMatchedCycleTable.csv';
writetable(prePostChangeMatchedCycleTableAll, prePostChangeMatchedCycleTablePath);
% grDistributedTable
grDistributedTablePath = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\grDistributedTable.csv';
writetable(grDistributedTableAll, grDistributedTablePath);
% prePostChangeGRDistributedTable
prePostChangeGRDistributedTablePath = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\prePostChangeGRDistributedTable.csv';
writetable(prePostChangeGRDistributedTableAll, prePostChangeGRDistributedTablePath);
% grSymTable
grSymTablePath = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\grSymTable.csv';
writetable(grSymTableAll, grSymTablePath);
% prePostGRSymTable
prePostGRSymTablePath = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\prePostGRSymTable.csv';
writetable(prePostGRSymTableAll, prePostGRSymTablePath);