function [tableOut] = calculateCGAM(tableIn, indVars)

%% PURPOSE: CALCULATE CGAM FOR ALL ROWS OF THE TABLE
% Inputs:
% tableIn: The input data table
% indVars: Cell array of independent variable names
%
% Outputs:
% tableOut: Output data table with CGAM data

tableOut = copyCategorical(tableIn);
% catTable = copyCategorical(tableIn);
tableInIndep = tableIn(:, indVars);
uniqueTrials = unique(tableOut(:,1:5),'rows','stable');
for i=1:height(uniqueTrials)
    currNameRowsIdx = tableContains(tableIn, uniqueTrials(i,:));
    currRows = tableInIndep(currNameRowsIdx,:);
    currData = table2array(currRows);
    cgam = CGAM(currData);
    tableOut.CGAM(currNameRowsIdx) = cgam;    
end
    