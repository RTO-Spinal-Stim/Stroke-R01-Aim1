function [aucTable] = calculateAUCAll(tableIn, colNameIn, columnNameSuffix)

%% PURPOSE: CALCULATE THE AREA UNDER THE CURVE (AUC) FOR THE SPECIFIED COLUMN.
% Inputs:
% tableIn: The table of data
% colNameIn: The column to compute the AUC for. Data should be a struct.
% columnNameSuffix: The suffix for the column name to store the AUC in.
%
% Outputs:
% aucTable: The table with the computed AUC data

disp('Calculating area under the curve (AUC)');

aucTable = table;
for i = 1:height(tableIn)
    tmpTable = table;
    tmpTable.Name = tableIn.Name(i);
    currData = tableIn.(colNameIn)(i);
    structFields = fieldnames(currData);
    for fieldNum = 1:length(structFields)
        fieldNameOrig = structFields{fieldNum};
        fieldName = fieldNameOrig;
        if startsWith(fieldNameOrig,{'L','R'})
            firstLetter = fieldNameOrig(1);
            fieldName = fieldNameOrig(2:end);
        end
        storeFieldName = [firstLetter '_' fieldName '_' columnNameSuffix];
        if isempty(currData.(fieldNameOrig))
            tmpTable.(storeFieldName) = NaN;
        else
            tmpTable.(storeFieldName) = trapz(currData.(fieldNameOrig));
        end
    end
    aucTable = [aucTable; tmpTable];
end