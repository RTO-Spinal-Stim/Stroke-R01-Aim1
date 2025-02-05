function [synergiesTable] = calculateSynergiesAll(dataTable, dataColName, fieldNames, VAFthresh, fieldNameSuffix)

%% PURPOSE: CALCULATE THE NUMBER OF MUSCLE SYNERGIES FOR ALL TRIALS/GAIT CYCLES
% Inputs:
% dataTable: Each row is one gait cycle
% dataColName: The column name to calculate the muscle synergies from.
% fieldNames: The names of the fields from the dataColName to calculate the
% muscle synergies from
% VAFthresh: The threshold for Variance Accounted For (VAF)
% fieldNameSuffix: Char to put on the end of the table field names, i.e. to
% indicate L vs. R, or both together, etc.
%
% Outputs:
% synergiesTable: Each row is one gait cycle.

% Initialize the suffix
if ~exist('fieldNameSuffix','var')
    fieldNameSuffix = '';
end

% Make sure the suffix starts with '_' if it's not empty
if ~isempty(fieldNameSuffix) && ~isequal(fieldNameSuffix(1), '_')
    fieldNameSuffix = ['_' fieldNameSuffix];
end

synergiesTable = table;
for i = 1:height(dataTable)
    currData = dataTable.(dataColName)(i);
    tmpTable = table;
    [nSynergies, VAFs, W, H] = calculateSynergies(currData, fieldNames, VAFthresh);
    tmpTable.Name = dataTable.Name(i);
    tmpTable.(['NumSynergies' fieldNameSuffix]) = nSynergies;
    tmpTable.(['VAFs' fieldNameSuffix]) = {VAFs};
    tmpTable.(['W' fieldNameSuffix]) = {W};
    tmpTable.(['H' fieldNameSuffix]) = {H};
    synergiesTable = [synergiesTable; tmpTable];
end