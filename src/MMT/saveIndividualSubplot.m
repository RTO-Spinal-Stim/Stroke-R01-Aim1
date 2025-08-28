function saveIndividualSubplot(originalFig, targetTags, fileName)
%% PURPOSE: SAVE A SINGLE SUBPLOT WITH IDENTICAL SIZE AND ASPECT RATIO
% Inputs:
% originalFig: Handle to the original N x 2 figure
% targetTags: The muscle names to copy the plots from the original figure
% fileName: The file name to save the figure to.

originalFig.WindowState = 'maximized';
drawnow;

% Ensure targetTags is a cell array
if ischar(targetTags) || isstring(targetTags)
    targetTags = {targetTags};
end

% Find all target axes
targetAxes = [];
for i = 1:length(targetTags)
    ax = findobj(originalFig, 'Type', 'axes', 'Tag', targetTags{i});
    if ~isempty(ax)
        targetAxes = [targetAxes; ax(1)]; % Take first match if multiple
    else
        warning('No axes found with tag: %s', targetTags{i});
    end
end

if isempty(targetAxes)
    warning('No valid axes found for the specified tags');
    return;
end

numPlots = length(targetAxes);

% Get the position and size of the first target axes in the original figure
originalPos = get(targetAxes(1), 'Position'); % [left bottom width height] in normalized units
originalFigPos = get(originalFig, 'Position'); % [left bottom width height] in pixels

% Calculate the actual pixel dimensions of one subplot
subplotWidth = originalPos(3) * originalFigPos(3);
subplotHeight = originalPos(4) * originalFigPos(4);

% Create new figure with height scaled by number of plots
% Add padding for axes labels and titles
paddingHorizontal = 100; % pixels
paddingVertical = 50; % pixels per subplot
totalPaddingVertical = paddingVertical * (numPlots + 1); % Extra padding between plots

newFigWidth = subplotWidth + paddingHorizontal;
newFigHeight = (subplotHeight * numPlots) + totalPaddingVertical;

newFig = figure('Position', [100, 100, newFigWidth, newFigHeight]);

% Calculate positions for each subplot in the new figure
% We want to stack them vertically with consistent spacing
margin = 0.05; % Small margin from edges
plotSpacing = 0.02; % Spacing between plots

% Available height for plots (excluding margins)
availableHeight = 1 - 2*margin - (numPlots-1)*plotSpacing;
plotHeight = availableHeight / numPlots;
plotWidth = 1 - 2*margin;

% Copy each axes to the new figure and position them
for i = 1:numPlots
    % Calculate vertical position (top to bottom)
    bottomPos = margin + (numPlots - i) * (plotHeight + plotSpacing);

    % Copy the axes to the new figure
    newAx = copyobj(targetAxes(i), newFig);

    % Set the position for this subplot
    set(newAx, 'Position', [margin, bottomPos, plotWidth, plotHeight]);

    % Ensure proper layering
    set(newAx, 'Layer', 'top');
end

% Save the figure
saveas(newFig, fileName);

% Optionally close the new figure
close(newFig);

if numPlots == 1
    fprintf('Individual subplot saved as: %s\n', fileName);
else
    fprintf('%d stacked subplots saved as: %s\n', numPlots, fileName);
end