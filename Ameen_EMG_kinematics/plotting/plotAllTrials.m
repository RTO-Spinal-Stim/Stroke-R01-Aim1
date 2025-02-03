function [] = plotAllTrials(allDataStruct, figName, baseSavePath, plotFieldName)

%% PURPOSE: PLOT ALL GAIT CYCLES OF ALL TRIALS PER CONDITION ON TOP OF ONE ANOTHER
% Inputs:
% allDataStruct: One participant's timeseries data.
% figName: A short descriptive name for the figures. Goes in the window
% name and the prefix of the plot titles.
% baseSavePath: The folder to save all of the plots to.
% plotFieldName: The field that is being plotted.

figAllTrials = figure('Name',figName);
figAllTrials.WindowState = 'maximized';
intervention_field_names = fieldnames(allDataStruct);
for i = 1:length(intervention_field_names)
    intervention_field_name = intervention_field_names{i};
    speedNames = fieldnames(allDataStruct.(intervention_field_name));
    for speedNum = 1:length(speedNames)
        speedName = speedNames{speedNum};
        prePosts = fieldnames(allDataStruct.(intervention_field_name).(speedName));
        for prePostNum = 1:length(prePosts)
            prePost = prePosts{prePostNum};
            trialNames = fieldnames(allDataStruct.(intervention_field_name).(speedName).(prePost).Trials);     
            clf;
            figAllTrialsConfig.title = [figName ': ' intervention_field_name ' ' speedName ' ' prePost ' All Trials Gait Cycles'];
            legendNames = {};
            for trialNum = 1:length(trialNames)
                trialName = trialNames{trialNum};
                gaitCycleNames = fieldnames(allDataStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles);
                for cycleNum = 1:length(gaitCycleNames)
                    cycleName = gaitCycleNames{cycleNum};
                    cycleData = allDataStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles.(cycleName).(plotFieldName);
                    legendName = [trialName ' ' cycleName];
                    figAllTrialsConfig.tooltipLabel = legendName;
                    figAllTrials = plotOneTrialData(cycleData, figAllTrials, figAllTrialsConfig);
                    legendNames = [legendNames; {legendName}];
                end
            end
            h = legend(legendNames);
            set(h, 'Position', [0.4825, 0.4903, 0.0562, 0.1391]); % In the middle of the axes.
            % Save the plot.
            saveFolderPath = baseSavePath;
            mkdir(saveFolderPath);
            savePath = fullfile(saveFolderPath, [prePost '_' intervention_field_name '_' speedName]);
            saveas(figAllTrials, [savePath '.fig']);
            saveas(figAllTrials, [savePath '.png']);
            saveas(figAllTrials, [savePath '.svg']);
        end
    end
end