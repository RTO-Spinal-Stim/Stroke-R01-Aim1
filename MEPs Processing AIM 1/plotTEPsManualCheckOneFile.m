function [resultTable] = plotTEPsManualCheckOneFile(config, tableIn)

%% PURPOSE: PLOT THE TEPs AND MANUALLY CHECK TO ENSURE ACCURACY.
% Inputs:
% tableIn: Table with one row corresponding to one file's TEPs data.
% 
% Outputs:
% resultTable:

plotMethod = config.PLOT_METHOD;
rectifiedMethod = config.RECTIFIED_METHOD;

fileData = tableIn.(rectifiedMethod);
final_muscles_list_fieldNames = fieldnames(fileData);
total_pulses = size(fileData.(final_muscles_list_fieldNames{1}),1);

% interval_mA = config.INTERVAL_MA;
pulses_perIntensity = config.NUM_PULSES_PER_INTENSITY;

for mus_i = 1:length(final_muscles_list_fieldNames)
    muscle_channel = final_muscles_list_fieldNames{mus_i};
    fig = figure('Name', muscle_channel);

    % Defining pulse per muscle iteration variables:
    numNan = 0; % Counting the trials that return nan - after 20 mA - just stop and move on
    autofill = false;

    % There should be multiples of 5 in each intensity
    if mod(total_pulses,pulses_perIntensity) ~= 0
        disp('ERROR, CHECK ME! (placeholder message)');
        % disp([SUBJ + ' ' + muscle_channel + ' ' + INTER + ' ' + TP]);
        % disp(['... (ERR) != ' num2str(pulses_perIntensity)  ' pulses per intensities detected. Please check pulses #s to remove']);
    end

    plotTEPsManualCheckOneMuscle(fileData.(muscle_channel), muscle_channel, fig);

end
    