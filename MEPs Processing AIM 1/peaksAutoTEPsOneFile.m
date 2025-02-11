function [resultTable] = peaksAutoTEPsOneFile(config, tableIn, columnName)

%% PURPOSE: FIND PEAKS AUTOMATICALLY IN TEPs FOR ONE FILE.
% Inputs:
% config: The configuration struct
% tableIn: The table containing the data from previous steps
% columnName: The column name to find peaks in.
%
% Outputs:
% resultTable: The output

resultTable = table;

muscleNames = fieldnames(tableIn.(columnName));
musclesStruct = struct;
for i = 1:length(muscleNames)
    muscleName = muscleNames{i};
    musclesStruct.(muscleName) = peaksAutoTEPsOneMuscle(tableIn.(columnName)(muscleName));
end