function [indVarNames, VIFs, VIFsMatrix] = independentVarsFromVIF(tableIn, cutoff)

%% PURPOSE: IDENTIFY WHICH VARIABLES ARE INDEPENDENT FROM ONE ANOTHER.
% Inputs:
% tableIn: The input table of data with numeric columns only.
% cutoff: VIF threshold. Default = 10
%
% Outputs:
% varNames: The unique variable names in the table, where VIF is below the threshold.
% VIFs: The VIF's for each variable. Each column is one regressor variable.

if ~exist('cutoff','var')
    cutoff = 10;
end

collinearVarNames = {};
varNames = tableIn.Properties.VariableNames;
numVars = length(varNames);
VIFsMatrix = NaN(numVars, numVars);
VIFs = NaN(numVars, 1);
foundIndVarNames = false;
for i = 1:numVars

    % Remove the variables that were already labelled as collinear
    varsToRemove = varNames(ismember(varNames, collinearVarNames));
    currTable = removevars(tableIn, varsToRemove);

    % Convert the table to a numeric matrix
    data = table2array(currTable);    
    currVIFs = VIF(data);

    % Place the VIFs in the columns corresponding to the regressor variable
    % When fewer than all variables are in the 'data' variable, then the
    % missing variables' columns will be NaN.
    varsIdx = ~ismember(varNames, varsToRemove);
    VIFsMatrix(varsIdx,i) = currVIFs;

    % Store the max VIF in a vector for easy interpretation.
    [maxVIF, maxVIFidx] = max(currVIFs);
    VIFs(i) = maxVIF;

    % If all VIF < threshold for the first time, this is the set of
    % independent variables.
    if maxVIF < cutoff && ~foundIndVarNames
        foundIndVarNames = true;
        indVarNames = varNames(varsIdx);
    elseif ~foundIndVarNames
        % Otherwise, if not yet found independent set,
        % add to the collinear variable names.
        collinearVarNames = [collinearVarNames; varNames(maxVIFidx)];
    end
end