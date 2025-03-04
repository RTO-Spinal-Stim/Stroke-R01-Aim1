function [crossCorrTable] = calculateLRCrossCorrAll(tableIn, colNameIn, colNameSuffix)

%% PURPOSE: CALCULATE THE CROSS-CORRELATIONS BETWEEN CONSECUTIVE GAIT CYCLES
% NOTE: The cross correlation is computed between the i'th gait cycle of one side and
% the i+1'th gait cycle (corresponding to the other side). Currently, the
% table of input data already matches alternating gait cycles into each row.
%
% Inputs:
% tableIn: The input data table
% colNameIn: The column name of the input data. This should be a struct
% colNameSuffix: The suffix of the column name to store the computed data
%
% Outputs:
% crossCorrTable: The table with the computed cross correlation data

disp('Calculating cross correlations');

crossCorrTable = table;
for i = 1:height(tableIn)
    tmpTable = table;
    tmpTable.Name = tableIn.Name(i);

    data = tableIn.(colNameIn)(i);

    if ~isstruct(data)
        error(['Not a struct! ' colNameIn ' ' char(tableIn.Name{i})]);
    end

    % Get all of the field names, removing the L & R prefixes
    structFieldsLR = fieldnames(data);
    structFieldsNoSides = {};
    for fieldNum = 1:length(structFieldsLR)
        fieldName = structFieldsLR{fieldNum}(2:end);
        if ~ismember(fieldName, structFieldsNoSides)
            structFieldsNoSides = [structFieldsNoSides; {fieldName}];
        end
    end

    for fieldNum = 1:length(structFieldsNoSides)
        fieldName = structFieldsNoSides{fieldNum};
        fieldNameL = ['L' fieldName];
        fieldNameR = ['R' fieldName];
        % There is one more L or R gait cycle vs. the other side.
        if isempty(data.(fieldNameL)) || isempty(data.(fieldNameR))
            tmpTable = table;
            break;
        end
        [C, lags] = xcorr(data.(fieldNameL), data.(fieldNameR),'normalized');
        fieldNameStoreMag = [fieldName '_Mag_' colNameSuffix];
        fieldNameStoreLag = [fieldName '_Lag_' colNameSuffix];
        [maxC, maxCidx] = max(C);
        tmpTable.(fieldNameStoreMag) = maxC;
        tmpTable.(fieldNameStoreLag) = lags(maxCidx);
    end

    crossCorrTable = [crossCorrTable; tmpTable];
end