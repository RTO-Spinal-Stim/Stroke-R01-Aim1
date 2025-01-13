clear
clc

subjectPath = 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\Processed Outcomes\SS13_Outcomes.mat';

% Initialize the waitbar
%h = waitbar(0, 'Please wait...');
%cleanupObj = onCleanup(@() close(h)); % Ensure the waitbar closes if there's an error

% Define the total number of checkpoints
%total_checkpoints = 10;

%try

% Select subject folder
subjectFolder = uigetdir('', 'Select subject folder');
if subjectFolder == 0
    disp('Operation canceled.');
    return;
end

% Extract folder name from the path
[~, folderName, ~] = fileparts(subjectFolder);

% Create a struct with dynamic field names
folderStruct = struct();

% Assign an empty struct to the dynamic field
folderStruct.(folderName) = struct();

% Define subfolder names
subfolders = {'Delsys', 'Gaitrite', 'XSENS'};
interventionFolders = {'30_RMT', '30_TOL', '50_RMT', '50_TOL', 'SHAM1','SHAM2'};
% interventionFolders = {'30_RMT', '30_TOL', '50_RMT', '50_TOL','SHAM2'};
% Define a mapping between folder names and struct field names
folderMap = containers.Map(interventionFolders, ...
    {'RMT30', 'TOL30', 'RMT50', 'TOL50', 'SHAM1', 'SHAM2'});
% {'RMT30', 'TOL30', 'RMT50', 'TOL50', 'SHAM2'});


% Define the file extensions for each subfolder type
fileExtensions = {'*.mat', '*.xlsx', '*.xlsx'};

% Iterate over intervention folders
for i = 1:length(interventionFolders)
    % Use the mapping to get the correct struct field name
    interventionStructName = folderMap(interventionFolders{i});
    
    % Initialize sub-struct for the intervention folder
    folderStruct.(folderName).(interventionStructName) = struct();
    
    % Iterate over subfolders
    for j = 1:length(subfolders)
        subfolder = subfolders{j};
        
        % Initialize a struct for each subfolder
        folderStruct.(folderName).(interventionStructName).(subfolder) = struct();
        
        % Construct the path to the files
        filesPath = fullfile(subjectFolder, subfolder, interventionFolders{i}, fileExtensions{j});
        files = dir(filesPath);
        
        % Load the data based on file type
        for k = 1:length(files)
            % Load .mat files for 'Delsys'
            if strcmp(subfolder, 'Delsys') && ~isempty(files(k).name)
                data = load(fullfile(files(k).folder, files(k).name));
                % Store the data in a struct with the file name as the field
                fieldName = matlab.lang.makeValidName(files(k).name);
                folderStruct.(folderName).(interventionStructName).(subfolder).(fieldName) = data;
                % Load .xlsx files for 'Gaitrite' and 'XSENS'
            elseif any(strcmp(subfolder, {'Gaitrite', 'XSENS'})) && ~isempty(files(k).name)
                
                if strcmp(subfolder, 'XSENS')
                    % For XSENS files, load the 'Joint Angles XZY' sheet
                    [num, txt, raw] = xlsread(fullfile(files(k).folder, files(k).name), 'Joint Angles XZY');
                else
                    % For Gaitrite files, load a different sheet (replace 'SheetNameForGaitrite' with the actual sheet name)
                    [num, txt, raw] = xlsread(fullfile(files(k).folder, files(k).name));
                end
                
                % Store the data in a struct with the file name as the field
                fieldName = matlab.lang.makeValidName(files(k).name);
                folderStruct.(folderName).(interventionStructName).(subfolder).(fieldName).num = num;
                folderStruct.(folderName).(interventionStructName).(subfolder).(fieldName).txt = txt;
                folderStruct.(folderName).(interventionStructName).(subfolder).(fieldName).raw = raw;
            end
        end
    end
end

% Display the final structure
% disp(folderStruct);


%waitbar(1/total_checkpoints, h, 'Loaded Subject Folder Complete');



%%

intervention = fieldnames(folderStruct.(folderName));

for e = 1:length(intervention)
    % Load EMG Data
    EMGStruct = folderStruct.(folderName).(intervention{e}).Delsys;
    folderStruct.(folderName).(intervention{e}).loadedDelsys = loadMatFiles(EMGStruct);
    
end

%waitbar(2/total_checkpoints, h, 'Loaded EMG Complete');


for g = 1:length(intervention)
    % Load EMG Data
    GaitStruct = folderStruct.(folderName).(intervention{g}).Gaitrite;
    folderStruct.(folderName).(intervention{g}).loadedGaitrite = loadExcelFiles(GaitStruct);
    
end

%waitbar(3/total_checkpoints, h, 'Loaded Gaitrite Complete');

for x = 1:length(intervention)
    % Load EMG Data
    XsensStruct = folderStruct.(folderName).(intervention{x}).XSENS;
    folderStruct.(folderName).(intervention{x}).loadedXSENS = loadExcelFiles(XsensStruct);
    
end

%waitbar(4/total_checkpoints, h, 'Loaded XSENS Complete');
%Load XSENS Data
% allXSENS = loadXsens(folderPath);

%%
%Specific mislabeled sensor case
interFields = fieldnames(folderStruct.(folderName));

% Define valid folderName and currentInter mappings
validCombinations = struct(...
    "SS08", "RMT30", ...
    "SS09", "SHAM2", ...
    "SS10", ["SHAM2", "RMT30", "RMT50"]);

for i = 1:length(interFields)
    currentInter = interFields{i};
    
    if isfield(validCombinations, folderName) && ...
            any(strcmp(currentInter, validCombinations.(folderName)))
        % Log original and updated values for validation
        disp(['Processing: ', folderName, ' -> ', currentInter]);
        
        % Apply muscle correction for the valid combination
        fixMuscleMappings(folderStruct, folderName, currentInter);
        
        % Display the updated fields for validation
        disp('Updated fields:');
        disp(folderStruct.(folderName).(currentInter).loadedDelsys);
    end
end


%% Pre-Process DATA

EMG_Fs = 2000; %Delsys sampling freq
GAIT_Fs = 120;
X_Fs = 100;
% Call the function to apply the ACSR filter
% filteredData = applyACSRFilter(allEMGData, Fs);

for f = 1:length(intervention)
    EMGStruct = folderStruct.(folderName).(intervention{f}).loadedDelsys;
    %Pre-Process EMG Data
    folderStruct.(folderName).(intervention{f}).filteredEMG = preprocessEMG(EMGStruct, EMG_Fs);
end

%waitbar(5/total_checkpoints, h, 'Filtered EMG Complete');

for g = 1:length(intervention)
    gaitStruct = folderStruct.(folderName).(intervention{g}).loadedGaitrite;
    %Process GAITRite Data
    folderStruct.(folderName).(intervention{g}).processedGait = processGAITRite(gaitStruct,GAIT_Fs, EMG_Fs, X_Fs);
end

%waitbar(6/total_checkpoints, h, 'Processed Gaitrite Complete');

%%
for x = 1:length(intervention)
    
    organizedData.(folderName).raw.(intervention{x}).Delsys  = folderStruct.(folderName).(intervention{x}).Delsys;
    organizedData.(folderName).raw.(intervention{x}).Gaitrite  = folderStruct.(folderName).(intervention{x}).Gaitrite;
    organizedData.(folderName).raw.(intervention{x}).XSENS  = folderStruct.(folderName).(intervention{x}).XSENS;
    
    organizedData.(folderName).processed.(intervention{x}).loadedDelsys  = folderStruct.(folderName).(intervention{x}).loadedDelsys;
    organizedData.(folderName).processed.(intervention{x}).loadedGaitrite  = folderStruct.(folderName).(intervention{x}).loadedGaitrite;
    organizedData.(folderName).processed.(intervention{x}).loadedXSENS  = folderStruct.(folderName).(intervention{x}).loadedXSENS;
    organizedData.(folderName).processed.(intervention{x}).filteredEMG  = folderStruct.(folderName).(intervention{x}).filteredEMG;
    organizedData.(folderName).processed.(intervention{x}).processedGait  = folderStruct.(folderName).(intervention{x}).processedGait;
    
end

for x = 1:length(intervention)
    
    % Assign 's'  struct
    s = organizedData.(folderName).processed.(intervention{x}).processedGait;
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
    organizedData.(folderName).processed.(intervention{x}).processedGait = s;
    
end

for x = 1:length(intervention)
    % Assign 's'  struct
    s = organizedData.(folderName).processed.(intervention{x}).filteredEMG;
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
    organizedData.(folderName).processed.(intervention{x}).filteredEMG = newStruct;
end

for x = 1:length(intervention)
    % Assign 's'  struct
    s = organizedData.(folderName).processed.(intervention{x}).loadedXSENS;
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
    organizedData.(folderName).processed.(intervention{x}).loadedXSENS = newStruct;
end

%waitbar(7/total_checkpoints, h, 'Organized Data Complete');

%%
for x = 1:length(intervention)
    
    emg = organizedData.(folderName).processed.(intervention{x}).filteredEMG;
    gait = organizedData.(folderName).processed.(intervention{x}).processedGait;
    xsens = organizedData.(folderName).processed.(intervention{x}).loadedXSENS;
    
    f = fieldnames(emg);
    
    for j = 1:length(f)
        
        %Average EMG for all gait cycles and trials
        [averagedEMG, accumulatedEMG] = downSampleAveragedEMG(emg.(f{j}), gait.(f{j}));
        
        %Average XSens for all gait cycles and trials
        [accumulatedJointAngles, averagedXSENS]  = downSampleAveragedXSENS(xsens.(f{j}), gait.(f{j}));
        
        organizedData.(folderName).processed.(intervention{x}).combinedTrials.(f{j}).averagedEMG = averagedEMG;
        organizedData.(folderName).processed.(intervention{x}).combinedTrials.(f{j}).accumulatedEMG = accumulatedEMG;
        organizedData.(folderName).processed.(intervention{x}).combinedTrials.(f{j}).accumulatedJointAngles = accumulatedJointAngles;
        organizedData.(folderName).processed.(intervention{x}).combinedTrials.(f{j}).averagedXSENS = averagedXSENS;
        
        organizedData.(folderName).processed.(intervention{x}).combinedTrials.(f{j}).stepLenSym = mean([gait.(f{j}).trial1.avgStepLenSym,gait.(f{j}).trial2.avgStepLenSym,gait.(f{j}).trial3.avgStepLenSym]);
        organizedData.(folderName).processed.(intervention{x}).combinedTrials.(f{j}).swingTimeSym = mean([gait.(f{j}).trial1.avgSwingTimeSym,gait.(f{j}).trial2.avgSwingTimeSym,gait.(f{j}).trial3.avgSwingTimeSym]);
        
        
        
        
    end
    
    
end


%waitbar(8/total_checkpoints, h, 'Processed EMG/XSENS Complete');


%% Analysis

for x = 1:length(intervention)
    
    s = organizedData.(folderName).processed.(intervention{x}).combinedTrials;
    
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
        
        organizedData.(folderName).processed.(intervention{x}).RLDiff.(f{j}).XSENS = X_RLdifference;
        organizedData.(folderName).processed.(intervention{x}).RLDiff.(f{j}).EMG = EMG_RLdifference;
        organizedData.(folderName).processed.(intervention{x}).synergies.(f{j}) = avgSynergies;
        
    end
    
    
end

%waitbar(9/total_checkpoints, h, 'EMG/XSENS Analysis Complete');

%%
outcomes = struct();

for x = 1:length(intervention)
    %XSENS DATA
    X_SenPostFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postFV.XSENS;
    X_SenPreFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preFV.XSENS;
    
    X_SenPostSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postSSV.XSENS;
    X_SenPreSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preSSV.XSENS;
    
    %EMG DATA
    emgPostFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postFV.EMG;
    emgPreFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preFV.EMG;
    
    emgPostSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postSSV.EMG;
    emgPreSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preSSV.EMG;
    
    %SYNERGY DATA
    synPostFV = organizedData.(folderName).processed.(intervention{x}).synergies.postFV;
    synPreFV = organizedData.(folderName).processed.(intervention{x}).synergies.preFV;
    
    synPostSSV = organizedData.(folderName).processed.(intervention{x}).synergies.postSSV;
    synPreSSV = organizedData.(folderName).processed.(intervention{x}).synergies.preSSV;
    
    %GAITRITE DATA
    %stepLen
    stepLenSymPostFV = organizedData.(folderName).processed.(intervention{x}).combinedTrials.postFV.stepLenSym;
    stepLenSymPreFV = organizedData.(folderName).processed.(intervention{x}).combinedTrials.preFV.stepLenSym;
    
    stepLenSymPostSSV = organizedData.(folderName).processed.(intervention{x}).combinedTrials.postSSV.stepLenSym;
    stepLenSymPreSSV = organizedData.(folderName).processed.(intervention{x}).combinedTrials.preSSV.stepLenSym;
    %swing time
    swingTimeSymPostFV = organizedData.(folderName).processed.(intervention{x}).combinedTrials.postFV.swingTimeSym;
    swingTimeSymPreFV = organizedData.(folderName).processed.(intervention{x}).combinedTrials.preFV.swingTimeSym;
    
    swingTimeSymPostSSV = organizedData.(folderName).processed.(intervention{x}).combinedTrials.postSSV.swingTimeSym;
    swingTimeSymPreSSV = organizedData.(folderName).processed.(intervention{x}).combinedTrials.preSSV.swingTimeSym;
    
    muscles = fieldnames(organizedData.(folderName).processed.(intervention{x}).RLDiff.preSSV.EMG.amplitude);
    joints = fieldnames(organizedData.(folderName).processed.(intervention{x}).RLDiff.preSSV.XSENS.amplitude);
    
    for m = 1:length(muscles)
        
        postAmplitudeSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postSSV.EMG.amplitude.(muscles{m});
        preAmplitudeSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preSSV.EMG.amplitude.(muscles{m});
        postAmplitudeFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postFV.EMG.amplitude.(muscles{m});
        preAmplitudeFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preFV.EMG.amplitude.(muscles{m});
        
        postDurationSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postSSV.EMG.duration.(muscles{m});
        preDurationSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preSSV.EMG.duration.(muscles{m});
        postDurationFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postFV.EMG.duration.(muscles{m});
        preDurationFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preFV.EMG.duration.(muscles{m});
        
        
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
        
        outcomes.(intervention{x}).EMG.(muscles{m}).amplitudeSSV = amplitudeDiffSSV;
        outcomes.(intervention{x}).EMG.(muscles{m}).amplitudeFV = amplitudeDiffFV;
        outcomes.(intervention{x}).EMG.(muscles{m}).durationSSV = durationDiffSSV;
        outcomes.(intervention{x}).EMG.(muscles{m}).durationFV = durationDiffFV;
        
    end
    
    
    for m = 1:length(joints)
        
        postAmplitudeSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postSSV.XSENS.amplitude.(joints{m});
        preAmplitudeSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preSSV.XSENS.amplitude.(joints{m});
        postAmplitudeFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postFV.XSENS.amplitude.(joints{m});
        preAmplitudeFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preFV.XSENS.amplitude.(joints{m});
        
        postDurationSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postSSV.XSENS.duration.(joints{m});
        preDurationSSV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preSSV.XSENS.duration.(joints{m});
        postDurationFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.postFV.XSENS.duration.(joints{m});
        preDurationFV = organizedData.(folderName).processed.(intervention{x}).RLDiff.preFV.XSENS.duration.(joints{m});
        
        
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
        
        outcomes.(intervention{x}).XSENS.(joints{m}).amplitudeSSV = amplitudeDiffSSV;
        outcomes.(intervention{x}).XSENS.(joints{m}).amplitudeFV = amplitudeDiffFV;
        outcomes.(intervention{x}).XSENS.(joints{m}).durationSSV = durationDiffSSV;
        outcomes.(intervention{x}).XSENS.(joints{m}).durationFV = durationDiffFV;
        
    end
    
    
    outcomes.(intervention{x}).synergies.FV = synPostFV - synPreFV;
    outcomes.(intervention{x}).synergies.SSV = synPostSSV - synPreSSV;
    
    % Gaitrite Outcomes spatial/temporal
    
    outcomes.(intervention{x}).stepLenSym.FV = ((stepLenSymPreFV - stepLenSymPostFV)/stepLenSymPreFV)*100;
    outcomes.(intervention{x}).stepLenSym.SSV = ((stepLenSymPreSSV - stepLenSymPostSSV)/stepLenSymPreSSV)*100;
    
    outcomes.(intervention{x}).swingTimeSym.FV = ((swingTimeSymPreFV - swingTimeSymPostFV)/swingTimeSymPreFV)*100;
    outcomes.(intervention{x}).swingTimeSym.SSV = ((swingTimeSymPreSSV - swingTimeSymPostSSV)/swingTimeSymPreSSV)*100;
    
end
% catch ME
%         % If an error occurs, update the waitbar to indicate error
%     waitbar(0, h, 'Error occurred');
%     set(findall(h, 'Type', 'Patch'), 'FaceColor', 'r'); % Change bar color to red
%     rethrow(ME); % Re-throw the error to handle it further if needed
% end
% waitbar(10/total_checkpoints, h, 'Symmetry Outcomes Complete');
% pause(1)
% % Close the waitbar when done
% close(h);

%% Save Outcomes for subject, specify subject
% save(subjectPath, 'outcomes');











