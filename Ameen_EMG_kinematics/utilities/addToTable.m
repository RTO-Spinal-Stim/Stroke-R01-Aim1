function [tableOut] = addToTable(existingTable, newTable)

%% PURPOSE: ADD THE NEW TABLE IN TO THE EXISTING TABLE.
% FIRST, ATTEMPTS VERTICAL CONCATENATION.
% IF THAT FAILS, ATTEMPTS AN OUTER JOIN.

try
    tableOut = [existingTable; newTable];
catch
    tableOut = outerjoin(existingTable, newTable, 'Keys','Name','MergeKeys',true);
end