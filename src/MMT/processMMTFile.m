function [figLoaded, figFiltered, loadedData, rawLoadedData] = processMMTFile(filePath, remapping, filter_config, fs, rectify, motion_muscle_mapping)

%% PURPOSE: PROCESS ONE FILE'S MMT EMG
% Inputs:
% filePath: The path to the EMG file
% remapping: Struct of structs indicating which sensors in which files need
% to be remapped
% filter_config: Struct providing the filter configuration
% fs: EMG sampling rate
% rectify: 0 or 1 indicating whether or not to rectify the EMG data
% motion_muscle_mapping: Struct with fieldnames of MMT motion filenames,
% and values are the corresponding muscle names (string or array of strings)
%
% Outputs:
% figLoaded: Handle to the figure containing all muscles' raw data plots
% figFiltered: Handle to the figure containing all muscles' filtered data plots
% loadedData: The loaded EMG data
% rawLoadedData: The raw EMG data with comments

%% Load & remap the EMG channels (if needed)
rawLoadedData = load(filePath);
loadedData = loadDelsysEMGOneFile(rawLoadedData);
% If necessary, remap the EMG sensor names
remappingFiles = fieldnames(remapping);
for remapFileNum = 1:length(remappingFiles)
    remappingFile = remappingFiles{remapFileNum};
    if ~contains(filePath, remappingFile)
        continue;
    end
    sensorsToRemap = fieldnames(remapping.(remappingFile));
    for sensorNum = 1:length(sensorsToRemap)
        sensorNameToRemap = sensorsToRemap{sensorNum};
        remappedSensorName = remapping.(remappingFile).(sensorNameToRemap);
        loadedData.(remappedSensorName) = loadedData.(sensorNameToRemap);
        loadedData = rmfield(loadedData, sensorNameToRemap);
    end
end

%% Plot EMG data and annotate
% Plot all muscles on the same plot.
figLoaded = figure();
figLoaded = plotOneTrialData(loadedData, figLoaded);
motionNames = fieldnames(motion_muscle_mapping);
motionName = false;
muscleNames = {};
for i = 1:length(motionNames)
    motionName = motionNames{i};
    if contains(filePath, motionName)
        break;
    end
end
if motionName
    muscleNames = motion_muscle_mapping.(motionName); % If a motion name from the config was found in an MMT file  path
end
annotateFigure(figLoaded, rawLoadedData.com, rawLoadedData.comtext, muscleNames);
saveIndividualSubplot(figLoaded, muscleNames, '');

% Filter & rectify the muscles
channels = fieldnames(loadedData);
filteredData = struct;
for channelNum = 1:length(channels)
    channel = channels{channelNum};
    filteredData.(channel) = filterEMGOneMuscle(loadedData.(channel), filter_config, fs, rectify);
end
figFiltered = figure();
figFiltered = plotOneTrialData(filteredData, figFiltered);
annotateFigure(figFiltered, rawLoadedData.com, rawLoadedData.comtext, muscleNames);