function [tableOut] = combineSubjectTables(subjectList, pathTemplate, varName, splitNameColumns)

%% PURPOSE: COMBINE EACH PARTICIPANT'S TABLE OF PROCESSED DATA FROM THEIR .MAT FILE INTO ONE TABLE
% Inputs:
% subjectList: Cell array of the subject names
% pathTemplate: The path where each subject's .mat file is saved, with a
% placeholder for the subject ID '{subject}'
% varName: The variable name in the .mat file to load
% splitNameColumns: The column names to split the Name column into. Must be
% in the proper order!
%
% tableOut: The combined table of all participants.
%
% 1. Scalar values only
% 2. Split the 'Name' column by underscores, one column per part of the name

tableOut = table;
for subNum = 1:length(subjectList)
    subject = subjectList{subNum};
    fullPath = strrep(pathTemplate, '{subject}', subject);

    if ~isfile(fullPath)
        disp(['File missing: ' fullPath]);
        continue;
    end

    disp(['Loading: ' fullPath]);

    dataTable = load(fullPath, varName);
    dataTable = dataTable.(varName);

    % Get the column names that are scalar. Either a scalar numeric/char,
    % or a scalar struct with fields that are scalar numeric/char.
    scalarColumnNames = {};
    allColumnNames = dataTable.Properties.VariableNames;
    for i = 1:length(allColumnNames)
        currData = dataTable.(allColumnNames{i});
        isScalar = true;
        for j = 1:length(currData)
            if ~isscalar(currData(j))
                isScalar = false;                                
            end
            if isstruct(currData(j))
                fldNames = fieldnames(currData(j));
                for fldNum = 1:length(fldNames)
                    if ~(isscalar(currData(j).(fldNames{fldNum})) && ~isstruct(currData(j).(fldNames{fldNum})))
                        isScalar = false;
                        break;
                    end
                end
            end
            if ~isScalar
                break;
            end
        end
        if isScalar
            scalarColumnNames = [scalarColumnNames; allColumnNames(i)];
        end
    end
    scalarColumnNames(ismember(scalarColumnNames, 'Name')) = [];

    % Put the scalar data into the table.
    for rowNum = 1:height(dataTable)
        tmpTable = table;
        % For each row, distribute the 'Name' column to multiple columns
        parsedName = strsplit(dataTable.Name(rowNum), '_');
        for i = 1:length(splitNameColumns)
            tmpTable.(splitNameColumns{i}) = parsedName(i);
        end
        % Store the data to the proper columns
        for colNum = 1:length(scalarColumnNames)
            colNameOrig = scalarColumnNames{colNum};
            currData = dataTable.(colNameOrig)(rowNum);
            if ~isstruct(currData)
                tmpTable.(colNameOrig) = currData;
            else
                fldNames = fieldnames(currData);
                for fldNum = 1:length(fldNames)
                    colName = [colNameOrig '_' fldNames{fldNum}];
                    tmpTable.(colName) = currData.(fldNames{fldNum});
                end
            end
        end
        tableOut = [tableOut; tmpTable];
    end

end

%% Sort the table
tableOut = sortrows(tableOut, splitNameColumns);
