function [cycleTable] = splitTrialsByGaitCycle(trialTable, colNameToSplit, gaitEventsColName)

%% PURPOSE: SPLIT ALL TRIALS INTO THEIR CONSTITUENT GAIT CYCLES.

cycleTable = table;
for i = 1:height(trialTable)
    LHS = trialTable.(gaitEventsColName)(i).gaitEvents.leftHeelStrikes;
    RHS = trialTable.(gaitEventsColName)(i).gaitEvents.leftHeelStrikes;
    [perGaitCycleStruct, maxNumCycles] = splitTrialByGaitCycle(trialTable.(colNameToSplit)(i), LHS, RHS);

    %% Convert this format to be a table with one row per gait cycle, and a struct inside each row.
    tmpTable = table;
    fieldNames = fieldnames(perGaitCycleStruct);
    for cycleNum = 1:maxNumCycles
        cycleName = ['cycle' num2str(cycleNum)];
        cycleStruct = struct;
        for fieldNum=1:length(fieldNames)
            fieldName = fieldNames{fieldNum};
            try
                cycleStruct.(fieldName) = perGaitCycleStruct.(fieldName){cycleNum};
            catch
                cycleStruct.(fieldName) = [];
            end
        end
        tmpTable.Name = convertCharsToStrings([char(trialTable.Name(i)) '_' cycleName]);
        tmpTable.(colNameToSplit) = cycleStruct;
        cycleTable = [cycleTable; tmpTable];
    end
end