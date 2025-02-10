function [resultTable] = plotTEPsManualCheckOneSubject(config, tableIn)

%% PURPOSE: MANUALLY CHECK THAT ALL TEPs ARE ACCURATE
% Inputs:
% config: configuration struct
% tableIn: table, or file path to load the table from.
%
% Outputs:
% resultTable: 

if ~istable(tableIn)
    if isfile(tableIn)
        load(tableIn, 'tepsResultTableOneSubject');
        tableIn = tepsResultTableOneSubject;
        clear tepsResultTableOneSubject;
    else
        error(['Could not load the table from: ' tableIn]);
    end
end

resultTable = table;
for i=1:height(tableIn)
    fileTable = plotTEPsManualCheckOneFile(config, tableIn(i,:));
    resultTable = [resultTable; fileTable];
end