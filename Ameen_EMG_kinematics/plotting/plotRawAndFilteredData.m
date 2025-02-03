function [] = plotRawAndFilteredData(allDataStruct, figName, baseSavePath, rectify)

%% PURPOSE: PLOT THE RAW AND FILTERED DATA ON TOP OF ONE ANOTHER.
% Inputs:
% allDataStruct: One participant's timeseries data.
% figName: A short descriptive name for the figures. Goes in the window
% name and the prefix of the plot titles.
% baseSavePath: The folder to save all of the plots to.

if ~exist('rectify','var')
    rectify = false;
end

figOneTrial = figure('Name',figName);
figOneTrial.WindowState = 'maximized';
figOneTrialConfig.color = '';
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
            for trialNum = 1:length(trialNames)
                trialName = trialNames{trialNum};
                clf;
                trialDataRaw = allDataStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).Loaded;
                % Rectify the EMG data if specified.
                if rectify
                    trialDataFields = fieldnames(trialDataRaw);
                    for fieldNum = 1:length(trialDataFields)
                        fieldName = trialDataFields{fieldNum};
                        trialDataRaw.(fieldName) = abs(trialDataRaw.(fieldName));
                    end
                end
                trialDataFiltered = allDataStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).Filtered;
                figOneTrialConfig.title = [figName ': ' intervention_field_name ' ' speedName ' ' prePost ' ' trialName];
                figOneTrialConfig = rmfield(figOneTrialConfig, 'color');
                figOneTrial = plotOneTrialData(trialDataRaw, figOneTrial, figOneTrialConfig);
                figOneTrialConfig.color = 'r';
                figOneTrial = plotOneTrialData(trialDataFiltered, figOneTrial, figOneTrialConfig);
                h = legend({'Rectified Raw','Filtered'});
                set(h, 'Position', [0.4825, 0.4903, 0.0562, 0.1391]); % In the middle of the axes.
                % Save the plot.
                saveFolderPath = baseSavePath;
                mkdir(saveFolderPath);
                savePath = fullfile(saveFolderPath, [intervention_field_name '_' prePost '_' speedName '_' trialName]);
                saveas(figOneTrial, [savePath '.fig']);
                saveas(figOneTrial, [savePath '.png']);
                saveas(figOneTrial, [savePath '.svg']);
            end
        end
    end
end
