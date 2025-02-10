function [fig] = plotTEPsManualCheckOneMuscle(oneMuscleTEPsData, muscleName, fig)

%% PURPOSE: MANUALLY DETERMINE TEPs BY PLOTTING.
% Inputs:
% oneMuscleTEPsData: M x N double, where M = # pulses, N = number of samples per pulse
% muscleName: The name of the current muscle being plotted.
% fig: Figure handle (optional). Creates a new figure if no handle provided.

if ~exist('fig','var')
    fig = figure('Name',muscleName);
end
ax = gca;
hold(ax,'on');

numTotalPulses = size(oneMuscleTEPsData,1);
colors = getColorMap(numTotalPulses);
for pulseNum = numTotalPulses:-1:1
    signal = oneMuscleTEPsData(pulseNum,:);

    currentColor = colors(pulseNum,:);

    % Plot signal
    plot(signal, 'Color', currentColor);    
end

% Get figure position to calculate button placement
figPos = get(fig, 'Position');
buttonWidth = 100;
buttonHeight = 30;
buttonLeft = 20;  % Distance from the left edge of the figure
buttonBottom = (figPos(4) - buttonHeight) / 2;  % Centered vertically

fig.WindowState = 'maximized';
% set(gcf, 'Position', get(0, 'Screensize'));
title([muscleName  ' - Zoom in as neccesary, decide if proceed or no MEP found'])

% Create "Continue" and "Skip" buttons with the same callback function
continueButton = uicontrol('Style', 'pushbutton', 'String', 'Continue',...
    'Position', [buttonLeft, buttonBottom + 40, buttonWidth, buttonHeight],...
    'Callback', @(src, event) pick_Peaks_inPlot_callback(src,muscleName));
% Alternative for continue - press enter:
% Set the KeyPressFcn for the figure
fig.WindowKeyPressFcn = @(src, event) keyPressCallback(src, event, muscleName);

skipButton = uicontrol('Style', 'pushbutton', 'String', 'Skip',...
    'Position',  [buttonLeft, buttonBottom - 40, buttonWidth, buttonHeight],...
    'Callback', @(src, event) pick_Peaks_inPlot_callback(src,muscleName));

% Pause execution and wait for user action
uiwait(gcf);
end

function [cmap] = getColorMap(numColors)

%% PURPOSE: CREATE A COLORMAP BASED ON TURBO WITH A CUSTOM NUMBER OF COLORS.

% Get the default turbo colormap
originalTurbo = turbo;

% Create interpolation points
x = linspace(1, size(originalTurbo,1), numColors);
xi = 1:size(originalTurbo,1);

% Interpolate each RGB channel
cmap = interp1(xi, originalTurbo, x);
end

function keyPressCallback(~, event, muscle_channel)

%% PURPOSE: CALLBACK FUNCTION FOR MEPs

% Mimic a button press based on the key
if strcmp(event.Key, 'return') % 'Enter' key
    % Create a fake src structure for "Continue"
    fakeSrc.String = 'Continue';
    pick_Peaks_inPlot_callback(fakeSrc, muscle_channel);
elseif strcmp(event.Key, 'backspace') % Optional: Handle other keys like 'Escape'
    % Create a fake src structure for "Skip"
    fakeSrc.String = 'Skip';
    pick_Peaks_inPlot_callback(fakeSrc, muscle_channel);
end
end