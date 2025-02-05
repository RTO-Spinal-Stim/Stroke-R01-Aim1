function [] = plotAllTrials(allDataTable, figName, baseSavePath, plotFieldName)

%% PURPOSE: PLOT ALL GAIT CYCLES OF ALL TRIALS PER CONDITION ON TOP OF ONE ANOTHER
% Inputs:
% allDataTable: One participant's timeseries data.
% figName: A short descriptive name for the figures. Goes in the window
% name and the prefix of the plot titles.
% baseSavePath: The folder to save all of the plots to.
% plotFieldName: The field that is being plotted.

%% Get the list of unique trial names by removing the cycle name.
uniqueTrialNames = {};
for i = 1:height(allDataTable)
    currFullName = allDataTable.Name(i);
    nameParts = strsplit(currFullName, '_');
    currNameNoTrial = '';
    for j = 1:length(nameParts) - 2
        currNameNoTrial = [currNameNoTrial '_' char(nameParts(j))];
    end
    currNameNoTrial = currNameNoTrial(2:end); % Remove the initial underscore.
    if ~ismember(currNameNoTrial, uniqueTrialNames)
        uniqueTrialNames = [uniqueTrialNames; {currNameNoTrial}];
    end
end

figAllTrials = figure('Name',figName);
figAllTrials.WindowState = 'maximized';
for trialNum = 1:length(uniqueTrialNames)
    trialName = uniqueTrialNames{trialNum};
    legendNames = {};
    clf;
    for i = 1:height(allDataTable)
        if ~contains(allDataTable.Name(i), trialName)
            continue;
        end        
        figAllTrialsConfig.title = [figName ': ' trialName ' All Trials Gait Cycles'];        
        cycleData = allDataTable.(plotFieldName)(i);
        nameParts = strsplit(allDataTable.Name(i), '_');
        legendName = [char(nameParts(end-1)) ' ' char(nameParts(end))];
        figAllTrialsConfig.tooltipLabel = legendName;
        figAllTrials = plotOneTrialData(cycleData, figAllTrials, figAllTrialsConfig);
        legendNames = [legendNames; {legendName}];        
    end
    h = legend(legendNames);
    set(h, 'Position', [0.4825, 0.4903, 0.0562, 0.1391]); % In the middle of the axes.
    % Save the plot.
    saveFolderPath = baseSavePath;
    mkdir(saveFolderPath);
    saveName = '';
    for j = 1:length(nameParts)-2
        saveName = [saveName '_' nameParts{j}];
    end
    saveName = saveName(2:end); % Remove the initial space.
    savePath = fullfile(saveFolderPath, saveName);
    saveas(figAllTrials, [savePath '.fig']);
    saveas(figAllTrials, [savePath '.png']);
    saveas(figAllTrials, [savePath '.svg']);
end

close(figAllTrials);