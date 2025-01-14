% MT 01/14/25: Editing to make work with config file, and adding lots of comments.

clear
clc

% Path to save the data to.
subjectSavePath = 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\Processed Outcomes\SS13_Outcomes.mat';
% Folder to load the data from.
subjectLoadPath = 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\SS13';

% Extract folder name from the path
[~, folderName, ~] = fileparts(subjectLoadPath);

% Create a struct with dynamic field names
folderStruct = struct();

% Assign an empty struct to the dynamic field
folderStruct.(folderName) = struct();

%% Get configuration
config = jsondecode(fileread('config.json'));

% One subfolder per data type
dataTypeFolders = config.DATA_TYPE_FOLDERS;

% One subfolder per intervention. Note that intervention folder names are
% not valid MATLAB names, hence the need for a mapping.
interventionFolders = config.INTERVENTION_FOLDERS;
interventionFoldersMap = containers.Map(interventionFolders, ...
    {'RMT30', 'TOL30', 'RMT50', 'TOL50', 'SHAM1', 'SHAM2'});

% Define the file extensions for each subfolder type
fileExtensions = config.FILE_EXTENSIONS;

%% Load all of the data for one subject.
for i = 1:length(interventionFolders)
    interventionFolder = interventionFolders{i};
    % Use the mapping to get the correct struct field name
    interventionStructName = interventionFoldersMap(interventionFolder);
    
    % Initialize sub-struct for the intervention folder
    folderStruct.(folderName).(interventionStructName) = struct();
    
    % Iterate over dataTypeFolders
    for j = 1:length(dataTypeFolders)
        dataTypeFolder = dataTypeFolders{j};
        
        % Initialize a struct for each dataTypeFolder
        folderStruct.(folderName).(interventionStructName).(dataTypeFolder) = struct();
        
        % Construct the path to the files
        filesPath = fullfile(subjectLoadPath, dataTypeFolder, interventionFolder, fileExtensions{j});
        files = dir(filesPath);
        
        % Load the data based on file type
        for k = 1:length(files)
            if isempty(files(k).name)
                continue;
            end
            fileName = files(k).name;
            fullFilePath = fullfile(files(k).folder, fileName); % The full path of the file being loaded.
            fieldName = matlab.lang.makeValidName(files(k).name);
            
            disp(['Now loading: ' fullFilePath]);
            
            % Load .mat files for 'Delsys'
            if strcmp(dataTypeFolder, 'Delsys')
                data = load(fullFilePath);                
            % Load .xlsx files for 'Gaitrite'
            elseif strcmp(dataTypeFolder, 'Gaitrite')
                [num, txt, raw] = xlsread(fullFilePath);
            % Load .xlsx files for 'Gaitrite'
            elseif strcmp(dataTypeFolder, 'XSENS')
                [num, txt, raw] = xlsread(fullFilePath, 'Joint Angles XZY');
            end
            
            % Store data to struct
            if any(strcmp(dataTypeFolder, {'Gaitrite', 'XSENS'}))                
                % Store the data in a struct with the file name as the field
                folderStruct.(folderName).(interventionStructName).(dataTypeFolder).(fieldName).num = num;
                folderStruct.(folderName).(interventionStructName).(dataTypeFolder).(fieldName).txt = txt;
                folderStruct.(folderName).(interventionStructName).(dataTypeFolder).(fieldName).raw = raw;
            elseif strcmp(dataTypeFolder, 'Delsys')
                % Store the data in a struct with the file name as the field                
                folderStruct.(folderName).(interventionStructName).(dataTypeFolder).(fieldName) = data;
            end                
        end
    end
end

%% Organize EMG data into separate muscles
interventions = fieldnames(folderStruct.(folderName));
for i = 1:length(interventions)
    EMGStruct = folderStruct.(folderName).(interventions{i}).Delsys;
    folderStruct.(folderName).(interventions{i}).loadedDelsys = loadMatFiles(EMGStruct);    
end

%% Extract .num field of Gaitrite data
for i = 1:length(interventions)
    GaitStruct = folderStruct.(folderName).(interventions{i}).Gaitrite;
    folderStruct.(folderName).(interventions{i}).loadedGaitrite = loadExcelFiles(GaitStruct);
    
end

%% Extract .num field of XSENS data
for i = 1:length(interventions)
    XsensStruct = folderStruct.(folderName).(interventions{i}).XSENS;
    folderStruct.(folderName).(interventions{i}).loadedXSENS = loadExcelFiles(XsensStruct);
end

%% Fix muscle mappings for specific subject & interventions.

% Define valid folderName and intervention mappings
validCombinations = config.VALID_COMBINATIONS;

for i = 1:length(interventions)
    intervention = interventions{i};
    
    if isfield(validCombinations, folderName) && ...
            any(strcmp(intervention, validCombinations.(folderName)))
        % Log original and updated values for validation
        disp(['Processing: ', folderName, ' -> ', intervention]);
        
        % Apply muscle correction for the valid combination
        fixMuscleMappings(folderStruct, folderName, intervention);
        
        % Display the updated fields for validation
        disp('Updated fields:');
        disp(folderStruct.(folderName).(intervention).loadedDelsys);
    end
end


%% Pre-Process DATA

EMG_Fs = 2000; %Delsys sampling freq
GAIT_Fs = 120;
X_Fs = 100;

for i = 1:length(interventions)
    EMGStruct = folderStruct.(folderName).(interventions{i}).loadedDelsys;
    %Pre-Process EMG Data
    folderStruct.(folderName).(interventions{i}).filteredEMG = preprocessEMG(EMGStruct, EMG_Fs);
end

for i = 1:length(interventions)
    gaitStruct = folderStruct.(folderName).(interventions{i}).loadedGaitrite;
    %Process GAITRite Data
    folderStruct.(folderName).(interventions{i}).processedGait = processGAITRite(gaitStruct,GAIT_Fs, EMG_Fs, X_Fs);
end

%%
for x = 1:length(interventions)
    
    organizedData.(folderName).raw.(interventions{x}).Delsys  = folderStruct.(folderName).(interventions{x}).Delsys;
    organizedData.(folderName).raw.(interventions{x}).Gaitrite  = folderStruct.(folderName).(interventions{x}).Gaitrite;
    organizedData.(folderName).raw.(interventions{x}).XSENS  = folderStruct.(folderName).(interventions{x}).XSENS;
    
    organizedData.(folderName).processed.(interventions{x}).loadedDelsys  = folderStruct.(folderName).(interventions{x}).loadedDelsys;
    organizedData.(folderName).processed.(interventions{x}).loadedGaitrite  = folderStruct.(folderName).(interventions{x}).loadedGaitrite;
    organizedData.(folderName).processed.(interventions{x}).loadedXSENS  = folderStruct.(folderName).(interventions{x}).loadedXSENS;
    organizedData.(folderName).processed.(interventions{x}).filteredEMG  = folderStruct.(folderName).(interventions{x}).filteredEMG;
    organizedData.(folderName).processed.(interventions{x}).processedGait  = folderStruct.(folderName).(interventions{x}).processedGait;
    
end

for x = 1:length(interventions)
    
    % Assign 's'  struct
    s = organizedData.(folderName).processed.(interventions{x}).processedGait;
    fields = fieldnames(s);
    
    for i = 1:numel(fields)
        if contains(fields{i}, 'POST_FV')
            s = renameStructField(s, fields{i}, 'postFV');
        elseif contains(fields{i}, 'POST_SSV')
            s = renameStructField(s, fields{i}, 'postSSV');
        elseif contains(fields{i}, 'PRE_FV')
            s = renameStructField(s, fields{i}, 'preFV');
        elseif contains(fields{i}, 'PRE_SSV')
            s = renameStructField(s, fields{i}, 'preSSV');
        end
    end
    organizedData.(folderName).processed.(interventions{x}).processedGait = s;
    
end

for x = 1:length(interventions)
    % Assign 's'  struct
    s = organizedData.(folderName).processed.(interventions{x}).filteredEMG;
    fields = fieldnames(s);
    newStruct = struct();
    
    for i = 1:numel(fields)
        trialNum = extractBetween(fields{i}, 'V', '_mat'); % Extract trial number
        if contains(fields{i}, 'POST_FV')
            newStruct.postFV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'POST_SSV')
            newStruct.postSSV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'PRE_FV')
            newStruct.preFV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'PRE_SSV')
            newStruct.preSSV.(['trial' trialNum{1}]) = s.(fields{i});
        end
    end
    organizedData.(folderName).processed.(interventions{x}).filteredEMG = newStruct;
end

for x = 1:length(interventions)
    % Assign 's'  struct
    s = organizedData.(folderName).processed.(interventions{x}).loadedXSENS;
    fields = fieldnames(s);
    newStruct = struct();
    
    for i = 1:numel(fields)
        trialNum = extractBetween(fields{i}, 'V_00', '_xlsx'); % Extract trial number
        if contains(fields{i}, 'POST_FV')
            newStruct.postFV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'POST_SSV')
            newStruct.postSSV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'PRE_FV')
            newStruct.preFV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'PRE_SSV')
            newStruct.preSSV.(['trial' trialNum{1}]) = s.(fields{i});
        end
    end
    organizedData.(folderName).processed.(interventions{x}).loadedXSENS = newStruct;
end

%waitbar(7/total_checkpoints, h, 'Organized Data Complete');

%%
for x = 1:length(interventions)
    
    emg = organizedData.(folderName).processed.(interventions{x}).filteredEMG;
    gait = organizedData.(folderName).processed.(interventions{x}).processedGait;
    xsens = organizedData.(folderName).processed.(interventions{x}).loadedXSENS;
    
    f = fieldnames(emg);
    
    for j = 1:length(f)
        
        %Average EMG for all gait cycles and trials
        [averagedEMG, accumulatedEMG] = downSampleAveragedEMG(emg.(f{j}), gait.(f{j}));
        
        %Average XSens for all gait cycles and trials
        [accumulatedJointAngles, averagedXSENS]  = downSampleAveragedXSENS(xsens.(f{j}), gait.(f{j}));
        
        organizedData.(folderName).processed.(interventions{x}).combinedTrials.(f{j}).averagedEMG = averagedEMG;
        organizedData.(folderName).processed.(interventions{x}).combinedTrials.(f{j}).accumulatedEMG = accumulatedEMG;
        organizedData.(folderName).processed.(interventions{x}).combinedTrials.(f{j}).accumulatedJointAngles = accumulatedJointAngles;
        organizedData.(folderName).processed.(interventions{x}).combinedTrials.(f{j}).averagedXSENS = averagedXSENS;
        
        organizedData.(folderName).processed.(interventions{x}).combinedTrials.(f{j}).stepLenSym = mean([gait.(f{j}).trial1.avgStepLenSym,gait.(f{j}).trial2.avgStepLenSym,gait.(f{j}).trial3.avgStepLenSym]);
        organizedData.(folderName).processed.(interventions{x}).combinedTrials.(f{j}).swingTimeSym = mean([gait.(f{j}).trial1.avgSwingTimeSym,gait.(f{j}).trial2.avgSwingTimeSym,gait.(f{j}).trial3.avgSwingTimeSym]);
        
        
        
        
    end
    
    
end


%waitbar(8/total_checkpoints, h, 'Processed EMG/XSENS Complete');


%% Analysis

for x = 1:length(interventions)
    
    s = organizedData.(folderName).processed.(interventions{x}).combinedTrials;
    
    f = fieldnames(s);
    
    for j = 1:length(f)
        
        %Calculate Muslce Synergies
        avgSynergies = calculateSynergies(s.(f{j}).accumulatedEMG);
        
        %SPM Analysis for both XSens and EMG
        X_SPM = SPM_Analysis(s.(f{j}).accumulatedJointAngles);
        EMG_SPM = SPM_Analysis(s.(f{j}).accumulatedEMG);
        
        %Calculate the differences between right and left side for both XSENS and EMG
        X_RLdifference = differenceInRLCalc(X_SPM, s.(f{j}).averagedXSENS);
        EMG_RLdifference = differenceInRLCalc(EMG_SPM, s.(f{j}).averagedEMG);
        
        organizedData.(folderName).processed.(interventions{x}).RLDiff.(f{j}).XSENS = X_RLdifference;
        organizedData.(folderName).processed.(interventions{x}).RLDiff.(f{j}).EMG = EMG_RLdifference;
        organizedData.(folderName).processed.(interventions{x}).synergies.(f{j}) = avgSynergies;
        
    end
    
    
end

%waitbar(9/total_checkpoints, h, 'EMG/XSENS Analysis Complete');

%%
outcomes = struct();

for x = 1:length(interventions)
    %XSENS DATA
    X_SenPostFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postFV.XSENS;
    X_SenPreFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preFV.XSENS;
    
    X_SenPostSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postSSV.XSENS;
    X_SenPreSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preSSV.XSENS;
    
    %EMG DATA
    emgPostFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postFV.EMG;
    emgPreFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preFV.EMG;
    
    emgPostSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postSSV.EMG;
    emgPreSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preSSV.EMG;
    
    %SYNERGY DATA
    synPostFV = organizedData.(folderName).processed.(interventions{x}).synergies.postFV;
    synPreFV = organizedData.(folderName).processed.(interventions{x}).synergies.preFV;
    
    synPostSSV = organizedData.(folderName).processed.(interventions{x}).synergies.postSSV;
    synPreSSV = organizedData.(folderName).processed.(interventions{x}).synergies.preSSV;
    
    %GAITRITE DATA
    %stepLen
    stepLenSymPostFV = organizedData.(folderName).processed.(interventions{x}).combinedTrials.postFV.stepLenSym;
    stepLenSymPreFV = organizedData.(folderName).processed.(interventions{x}).combinedTrials.preFV.stepLenSym;
    
    stepLenSymPostSSV = organizedData.(folderName).processed.(interventions{x}).combinedTrials.postSSV.stepLenSym;
    stepLenSymPreSSV = organizedData.(folderName).processed.(interventions{x}).combinedTrials.preSSV.stepLenSym;
    %swing time
    swingTimeSymPostFV = organizedData.(folderName).processed.(interventions{x}).combinedTrials.postFV.swingTimeSym;
    swingTimeSymPreFV = organizedData.(folderName).processed.(interventions{x}).combinedTrials.preFV.swingTimeSym;
    
    swingTimeSymPostSSV = organizedData.(folderName).processed.(interventions{x}).combinedTrials.postSSV.swingTimeSym;
    swingTimeSymPreSSV = organizedData.(folderName).processed.(interventions{x}).combinedTrials.preSSV.swingTimeSym;
    
    muscles = fieldnames(organizedData.(folderName).processed.(interventions{x}).RLDiff.preSSV.EMG.amplitude);
    joints = fieldnames(organizedData.(folderName).processed.(interventions{x}).RLDiff.preSSV.XSENS.amplitude);
    
    for m = 1:length(muscles)
        
        postAmplitudeSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postSSV.EMG.amplitude.(muscles{m});
        preAmplitudeSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preSSV.EMG.amplitude.(muscles{m});
        postAmplitudeFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postFV.EMG.amplitude.(muscles{m});
        preAmplitudeFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preFV.EMG.amplitude.(muscles{m});
        
        postDurationSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postSSV.EMG.duration.(muscles{m});
        preDurationSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preSSV.EMG.duration.(muscles{m});
        postDurationFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postFV.EMG.duration.(muscles{m});
        preDurationFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preFV.EMG.duration.(muscles{m});
        
        
        amplitudeDiffSSV = preAmplitudeSSV - postAmplitudeSSV;
        amplitudeDiffFV = preAmplitudeFV - postAmplitudeFV;
        durationDiffSSV = preDurationSSV - postDurationSSV;
        durationDiffFV = preDurationFV - postDurationFV;
        
        if isnan(amplitudeDiffSSV)
            
            amplitudeDiffSSV = 0;
            
        end
        
        if isnan(amplitudeDiffFV)
            
            amplitudeDiffFV = 0;
            
        end
        
        if isnan(durationDiffSSV)
            
            durationDiffSSV = 0;
            
        end
        
        if isnan(durationDiffFV)
            
            durationDiffFV = 0;
            
        end
        
        outcomes.(interventions{x}).EMG.(muscles{m}).amplitudeSSV = amplitudeDiffSSV;
        outcomes.(interventions{x}).EMG.(muscles{m}).amplitudeFV = amplitudeDiffFV;
        outcomes.(interventions{x}).EMG.(muscles{m}).durationSSV = durationDiffSSV;
        outcomes.(interventions{x}).EMG.(muscles{m}).durationFV = durationDiffFV;
        
    end
    
    
    for m = 1:length(joints)
        
        postAmplitudeSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postSSV.XSENS.amplitude.(joints{m});
        preAmplitudeSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preSSV.XSENS.amplitude.(joints{m});
        postAmplitudeFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postFV.XSENS.amplitude.(joints{m});
        preAmplitudeFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preFV.XSENS.amplitude.(joints{m});
        
        postDurationSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postSSV.XSENS.duration.(joints{m});
        preDurationSSV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preSSV.XSENS.duration.(joints{m});
        postDurationFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.postFV.XSENS.duration.(joints{m});
        preDurationFV = organizedData.(folderName).processed.(interventions{x}).RLDiff.preFV.XSENS.duration.(joints{m});
        
        
        amplitudeDiffSSV = preAmplitudeSSV - postAmplitudeSSV;
        amplitudeDiffFV = preAmplitudeFV - postAmplitudeFV;
        durationDiffSSV = preDurationSSV - postDurationSSV;
        durationDiffFV = preDurationFV - postDurationFV;
        
        if isnan(amplitudeDiffSSV)
            
            amplitudeDiffSSV = 0;
            
        end
        
        if isnan(amplitudeDiffFV)
            
            amplitudeDiffFV = 0;
            
        end
        
        if isnan(durationDiffSSV)
            
            durationDiffSSV = 0;
            
        end
        
        if isnan(durationDiffFV)
            
            durationDiffFV = 0;
            
        end
        
        outcomes.(interventions{x}).XSENS.(joints{m}).amplitudeSSV = amplitudeDiffSSV;
        outcomes.(interventions{x}).XSENS.(joints{m}).amplitudeFV = amplitudeDiffFV;
        outcomes.(interventions{x}).XSENS.(joints{m}).durationSSV = durationDiffSSV;
        outcomes.(interventions{x}).XSENS.(joints{m}).durationFV = durationDiffFV;
        
    end
    
    
    outcomes.(interventions{x}).synergies.FV = synPostFV - synPreFV;
    outcomes.(interventions{x}).synergies.SSV = synPostSSV - synPreSSV;
    
    % Gaitrite Outcomes spatial/temporal
    
    outcomes.(interventions{x}).stepLenSym.FV = ((stepLenSymPreFV - stepLenSymPostFV)/stepLenSymPreFV)*100;
    outcomes.(interventions{x}).stepLenSym.SSV = ((stepLenSymPreSSV - stepLenSymPostSSV)/stepLenSymPreSSV)*100;
    
    outcomes.(interventions{x}).swingTimeSym.FV = ((swingTimeSymPreFV - swingTimeSymPostFV)/swingTimeSymPreFV)*100;
    outcomes.(interventions{x}).swingTimeSym.SSV = ((swingTimeSymPreSSV - swingTimeSymPostSSV)/swingTimeSymPreSSV)*100;
    
end

%% Save Outcomes for subject, specify subject
% save(subjectSavePath, 'outcomes');











