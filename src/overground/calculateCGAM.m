function [tableOut] = calculateCGAM(tableIn, indVars)

%% PURPOSE: CALCULATE CGAM FOR ALL ROWS OF THE TABLE
% Inputs:
% tableIn: The input data table
% indVars: Cell array of independent variable names
%
% Outputs:
% tableOut: Output data table with CGAM data

tableOut = table;
tableOut.Name = tableIn.Name;
tableInIndep = tableIn(:, indVars);
uniqueTrials = getNamesPrefixes(tableIn.Name, 5);
for i=1:length(uniqueTrials)
    currNameRowsIdx = contains(tableIn.Name, uniqueTrials{i});
    currRows = tableInIndep(currNameRowsIdx,:);
    currData = table2array(currRows);
    cgam = CGAM(currData);
    tableOut.CGAM(currNameRowsIdx) = cgam;    
end
    