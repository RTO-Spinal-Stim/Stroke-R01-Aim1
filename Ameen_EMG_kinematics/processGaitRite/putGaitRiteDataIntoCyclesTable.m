function [cycleTable] = putGaitRiteDataIntoCyclesTable(grTable, cycleTable)

%% PURPOSE: PARSE THE GAITRITE DATA INTO THE CYCLES TABLE
% Inputs:
% grTable: The table with GaitRite data (each row is one walk)
% cycleTable: The table with the parsed gait cycle data (each row is one
% gait cycle)
%
% Outputs:
% cycleTable: The output table with one row per gait cycle

%% Remove the scalar columns from the grTable
scalarColumnNames = getScalarColumnNames(grTable);
for i = 1:length(scalarColumnNames)
    grTable.(scalarColumnNames{i}) = [];
end

%% Get the column names that start with "L_" and "R_"
[colNamesL, colNamesR] = getLRColNames(grTable);
% Remove the idx tables
namesToRemove = {'L_Idx','R_Idx'};
colNamesL(ismember(colNamesL, namesToRemove)) = [];
colNamesR(ismember(colNamesR, namesToRemove)) = [];

%% Initialize the columns with all NaN data
tmpData = NaN(height(cycleTable),1);
for i = 1:length(colNamesL)
    cycleTable.(colNamesL{i}) = tmpData;
    cycleTable.(colNamesR{i}) = tmpData;
end

%% Iterate over each trial
for i = 1:height(grTable)
    cycleRowsIdxNums = find(contains(cycleTable.Name, grTable.Name(i)));

    %% Iterate over each L & R column
    for j = 1:length(colNamesL)  
        colNameL = colNamesL{j};
        colNameR = colNamesR{j};
        currDataL = grTable.(colNameL){i};
        currDataR = grTable.(colNameR){i};

        % Remove empty data
        currDataL(currDataL == 0) = [];
        currDataR(currDataR == 0) = [];
        % If too short
        if length(currDataL) < length(cycleRowsIdxNums)
            currDataL(length(currDataL)+1:length(cycleRowsIdxNums)) = NaN;
        end
        if length(currDataR) < length(cycleRowsIdxNums)
            currDataR(length(currDataR)+1:length(cycleRowsIdxNums)) = NaN;
        end
        % If too long
        currDataL = currDataL(1:length(cycleRowsIdxNums));
        currDataR = currDataR(1:length(cycleRowsIdxNums));

        % Check the data sizes
        assert(length(currDataL) == length(currDataR));
        assert(length(currDataL) == length(cycleRowsIdxNums));

        % Assign the data to each cycle
        for cycleRowCount = 1:length(cycleRowsIdxNums)
            cycleTable.(colNameL)(cycleRowsIdxNums(cycleRowCount)) = currDataL(cycleRowCount);
            cycleTable.(colNameR)(cycleRowsIdxNums(cycleRowCount)) = currDataR(cycleRowCount);
        end
    end
end
