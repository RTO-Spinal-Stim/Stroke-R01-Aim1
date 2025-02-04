function [tableOut] = timeSynchronize(tableData, fs, secondsColName, framesColName)

%% PURPOSE: SYNCHRONIZE THE GAIT EVENT INDICES, PHASE DURATIONS, ETC. ACROSS HARDWARE TYPES.

tableOut = table;
for i = 1:height(tableData)
    tmpTable = table;
    currStruct = getHardwareIndicesFromSeconds(tableData.(secondsColName)(i), fs);
    tmpTable.Name = tableData.Name(i);
    tmpTable.(framesColName) = currStruct;
    tableOut = [tableOut; tmpTable];
end