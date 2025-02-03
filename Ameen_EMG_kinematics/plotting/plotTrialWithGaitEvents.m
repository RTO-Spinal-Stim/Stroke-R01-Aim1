function [] = plotTrialWithGaitEvents(allDataStruct, figName, baseSavePath, plotFieldName)

%% PURPOSE: PLOT THE ENTIRETY OF EACH TRIAL ALONG WITH THE GAIT EVENTS.
% Inputs:
% allDataStruct: One participant's timeseries data.
% figName: A short descriptive name for the figures. Goes in the window
% name and the prefix of the plot titles.
% baseSavePath: The folder to save all of the plots to.
% plotFieldName: The field that is being plotted.

figOneTrial = figure('Name',figName);
figOneTrial.WindowState = 'maximized';
intervention_field_names = fieldnames(allDataStruct);
figOneTrialConfig.color = 'k';
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
                trialData = allDataStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).(plotFieldName);
                figOneTrialConfig.title = [figName ': ' intervention_field_name ' ' speedName ' ' prePost ' ' trialName];
                figOneTrial = plotOneTrialData(trialData, figOneTrial, figOneTrialConfig);                
                %% Plot the gait phases & events
                axHandles = findobj(figOneTrial, 'Type', 'axes');
                framesStruct = allDataStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).frames;
                for axNum = 1:length(axHandles)
                    ax = axHandles(axNum);
                    plotGaitEvents(framesStruct, ax);
                end
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
close(figOneTrial);