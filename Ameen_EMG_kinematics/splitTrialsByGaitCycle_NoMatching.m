function [tableOut] = splitTrialsByGaitCycle_NoMatching(tableIn, colNameToSplit, gaitEventsColName)

%% PURPOSE: SPLIT THE TRIALS BY GAIT CYCLE
% Inputs:
% tableIn: The input data table
% colNameToSplit: The column name for the data to split
% gaitEventsColName: The column name for the gait events
%
% tableOut: The table of data split by gait cycles

tableOut = table;

for i = 1:height(tableIn)
    
    LHS = tableIn.(gaitEventsColName)(i).gaitEvents.leftHeelStrikes;
    RHS = tableIn.(gaitEventsColName)(i).gaitEvents.rightHeelStrikes;
    allHS = sort([LHS; RHS]); % Get all of the heel strike events together
    num_gait_cycles = length(allHS) - 2; % The number of gait cycles is two less than the total number of footfalls
    currData = tableIn.(colNameToSplit)(i);
    currTrialName = char(tableIn.Name(i));

    for cycleNum = 1:num_gait_cycles
        startHSIdx = allHS(cycleNum);
        fldNames = fieldnames(currData);
        % Get all of the data (L & R) from the current gait cycle
        for fldNum = 1:length(fldNames)
            fldName = fldNames{fldNum};
            cycleData.(fldName) = currData.(fldName)(allHS(cycleNum):allHS(cycleNum+2)-1);
        end
        if ismember(startHSIdx, LHS)
            startFoot = 'L';
        elseif ismember(startHSIdx, RHS)
            startFoot = 'R';
        end
        currCycleName = [currTrialName '_cycle' num2str(cycleNum) startFoot];
        tmpTable = table;
        tmpTable.Name = convertCharsToStrings(currCycleName);
        tmpTable.(colNameToSplit) = cycleData;
        tableOut = [tableOut; tmpTable];
    end

end