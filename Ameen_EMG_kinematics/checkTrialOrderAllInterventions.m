function [varargout] = checkTrialOrderAllInterventions(gaitRiteTable, otherTrialTables, colNameSubstr, levelNum)

%% PURPOSE: CHECK THE GAITRITE TRIAL ORDER FOR ONE SUBJECT
% Inputs:
% gaitRiteTable: The table of GaitRite data, where each row is one trial
% otherTrialTables: Cell array of the tables of the other hardwares' data, where each row
% is one trial.
% colNameSubstr: The substring that must be present in exactly one column name in each table
%
% Outputs:
% varargout: The rearranged tables, in the same order as the
% otherTrialTables cell array

if ~exist('levelNum','var')
    levelNum = 4;
end

if ~exist('colNameSubstr','var')
    colNameSubstr = 'DateTimeSaved';
end

% otherTrialTables = varargin;
reorderedGRTable = table;

% Check for the proper column names
grVarNames = gaitRiteTable.Properties.VariableNames;
grDateSavedColLogical = contains(grVarNames, colNameSubstr);
if sum(grDateSavedColLogical) ~=1
    error(['GaitRite trials table must contain exactly one column name matching: ' colNameSubstr]);
end

otherTablesDateSavedColLogical = cell(length(otherTrialTables),1);
reorderedOtherTrialTables = cell(1,length(otherTrialTables));
for i = 1:length(otherTrialTables)
    otherTableVarNames = otherTrialTables{i}.Properties.VariableNames;
    otherTablesDateSavedColLogical{i} = contains(otherTableVarNames, colNameSubstr);
    if sum(otherTablesDateSavedColLogical{i}) ~= 1
        error(['Other trials table #' num2str(i) ' must contain exactly one column name matching: ' colNameSubstr]);
    end
    if height(otherTrialTables{i}) ~= height(gaitRiteTable)
        error(['Other trials table #' num2str(i) ' must match GaitRite table height!']);
    end
    reorderedOtherTrialTables{i} = table; % Initializing
end

uniqueCombs = getNamesPrefixes(gaitRiteTable.Name, levelNum);
for i = 1:length(uniqueCombs)    
    currComb = uniqueCombs{i};
    currRowsIdx = contains(gaitRiteTable.Name, currComb); 
    currGRTable = gaitRiteTable(currRowsIdx, :);
    currGRTableDateTimes = currGRTable(:,grDateSavedColLogical | ismember(grVarNames, 'Name')); % DateSaved & Name columns only
    joinedTable = currGRTableDateTimes;
    % Get the column name
    currGRVarNames = currGRTableDateTimes.Properties.VariableNames;
    grDateTimeColName = currGRVarNames(~ismember(currGRVarNames, 'Name'));
    grDateTimeColName = grDateTimeColName{1};
    
    % Join the tables together with all of the saved dates
    for tableNum = 1:length(otherTrialTables)
        currTable = otherTrialTables{tableNum};
        currRowsIdx = contains(currTable.Name, currComb);
        currColsIdx = otherTablesDateSavedColLogical{tableNum} | ismember(otherTrialTables{tableNum}.Properties.VariableNames, 'Name'); % DateSaved & Name columns only
        currOtherTable = currTable(currRowsIdx,currColsIdx);
        joinedTable = join(joinedTable, currOtherTable, 'Keys', 'Name');
    end

    % Order the saved dates
    joinedTableOrders = joinedTable;
    joinedTableVarNames = joinedTable.Properties.VariableNames;
    joinedTableVarNames(ismember(joinedTableVarNames, 'Name')) = [];
    for colNum = 1:length(joinedTableVarNames)
        [~,orderNums] = sort(joinedTable.(joinedTableVarNames{colNum}));
        joinedTableOrders.(joinedTableVarNames{colNum}) = orderNums;
    end

    [~,grOrder]= sort(joinedTable.(grDateTimeColName));
    % Check that all of the non-gaitrite orders match
    joinedTableOrdersGRRemoved = removevars(joinedTableOrders, {grDateTimeColName, 'Name'});
    ordersGRRemoved = table2array(joinedTableOrdersGRRemoved);
    joinedTableGRRemoved = removevars(joinedTable, {grDateTimeColName, 'Name'});
    datetimesGRRemoved = table2array(joinedTableGRRemoved);
    if ~all(diff(ordersGRRemoved,1,2) == 0) && ~any(isnat(datetimesGRRemoved), 'all')
        error('Not all of the non-GaitRite hardwares agree on trial order!');
    end

    if any(isnat(datetimesGRRemoved), 'all')
        orderToUse = (1:size(ordersGRRemoved,1))'; % No change if unreliable data
    else
        % Get the order to rearrange the rows
        orderToUse = ordersGRRemoved(:,1);
    end
    
    % Perform the rearrangement
    for tableNum = 1:length(otherTrialTables)
        currTable = otherTrialTables{tableNum};
        currRowsIdx = contains(currTable.Name, currComb);
        currTableRows = currTable(currRowsIdx,:);
        currTableRowsReordered = currTableRows(orderToUse,:);
        for rowNum = 1:height(currTableRowsReordered)
            nameParts = strsplit(char(currTableRowsReordered.Name(rowNum)), '_');
            if rowNum < 10
                rowNumStr = num2str(rowNum);
            else
                rowNumStr = ['0' num2str(rowNum)];
            end
            fullName = convertCharsToStrings([strjoin(nameParts(1:end-1), '_') '_trial' num2str(rowNumStr)]);
            currTableRowsReordered.Name(rowNum) = fullName;
        end
        reorderedOtherTrialTables{tableNum} = [reorderedOtherTrialTables{tableNum}; currTableRowsReordered];
    end

end

varargout = reorderedOtherTrialTables;

end

% function [combs] = checkTrialOrderOneSubjectOneIntervention(subjectFolderPath, intervention, prePosts, speeds)
% 
% prePosts = {'PRE','POST'};
% speeds = {'SSV','FV'};
% %% XSENS
% xsensStruct = struct;
% xsensFolderPath = fullfile(subjectFolderPath, 'XSENS', intervention);
% fileList = dir(fullfile(xsensFolderPath, '*.xlsx'));
% fileNames = {fileList.name};
% for prePostNum = 1:length(prePosts)
%     prePost = prePosts{prePostNum};
%     for speedNum = 1:length(speeds)
%         speed = speeds{speedNum};
%         substr = [prePost '_' speed];
%         disp(['Speed: ' speed ' PrePost: ' prePost]);
%         currCombFilesIdx = contains(fileNames, substr);
%         currCombFiles = fileNames(currCombFilesIdx);
%         currCombFiles = sort(currCombFiles); % In numeric order
%         savedTimes = datetime(NaT(length(currCombFiles),1),'TimeZone','America/Chicago');
%         for fileNum = 1:length(currCombFiles)
%             currFile = currCombFiles{fileNum};
%             [raw_data, header_row, cell_data] = xlsread(fullfile(xsensFolderPath, currFile), 'General Information');
%             fullDate = cell_data{4,2};
%             spaceIdx = strfind(fullDate, ' ');
%             timeSaved = fullDate(spaceIdx(1)+1:end);
%             timeSavedDateTime = datetime(timeSaved, 'InputFormat', 'h:mm:ss a', 'TimeZone', 'UTC');
%             timeSavedDateTime.TimeZone = 'America/Chicago';
%             savedTimes(fileNum) = timeSavedDateTime;
%         end
%         [~,sortedOrder] = sort(savedTimes);
%         if ~isequal(sortedOrder', 1:length(sortedOrder))
%             xsensStruct.(substr) = sortedOrder';
%         end
%     end
% end
% 
% %% Delsys
% delsysFolderPath = fullfile(subjectFolderPath, 'Delsys', intervention);
% delsysStruct = struct;
% fileList = dir(fullfile(delsysFolderPath, '*.adicht'));
% fileNames = {fileList.name};
% for prePostNum = 1:length(prePosts)
%     prePost = prePosts{prePostNum};
%     for speedNum = 1:length(speeds)
%         speed = speeds{speedNum};
%         substr = [prePost '_' speed];
%         currCombFilesIdx = contains(fileNames, substr);
%         currCombFiles = fileNames(currCombFilesIdx);
%         currCombFiles = sort(currCombFiles); % In numeric order
%         savedTimes = datetime(NaT(length(currCombFiles),1),'TimeZone','America/Chicago');
%         for fileNum = 1:length(currCombFiles)
%             currFile = currCombFiles{fileNum};
%             currFileIdx = contains(fileNames, currFile);
%             fullDate = fileList(currFileIdx).date;
%             spaceIdx = strfind(fullDate, ' ');
%             timeSaved = fullDate(spaceIdx(1)+1:end);            
%             % Missing AM or PM, so add it here.
%             colonIdx = strfind(timeSaved, ':');
%             hrNum = str2double(timeSaved(1:colonIdx(1)-1));
%             if hrNum >= 12                
%                 timeSaved = [timeSaved ' PM'];
%                 if hrNum >= 13
%                     hrNum = hrNum - 12;
%                     timeSaved = [num2str(hrNum) timeSaved(3:end)];
%                 end
%             else
%                 timeSaved = [timeSaved ' AM'];
%             end
%             timeSavedDateTime = datetime(timeSaved, 'InputFormat', 'h:mm:ss a', 'TimeZone', 'America/Chicago');
%             savedTimes(fileNum) = timeSavedDateTime;
%         end
%         [~,sortedOrder] = sort(savedTimes);
%         if ~isequal(sortedOrder', 1:length(sortedOrder))
%             delsysStruct.(substr) = sortedOrder';
%         end
%     end
% end
% 
% %% GaitRite
% gaitRiteFolderPath = fullfile(subjectFolderPath, 'Gaitrite', intervention);
% gaitRiteStruct = struct;
% fileList = dir(fullfile(gaitRiteFolderPath, '*.xlsx'));
% fileNames = {fileList.name};
% for prePostNum = 1:length(prePosts)
%     prePost = prePosts{prePostNum};
%     for speedNum = 1:length(speeds)
%         speed = speeds{speedNum};
%         substr = [prePost '_' speed];
%         currCombFileIdx = contains(fileNames, substr);
%         currCombFile = fileNames{currCombFileIdx};
%         gaitRitePath = fullfile(gaitRiteFolderPath, currCombFile);
%         [num_data, txt_data, cell_data] = xlsread(gaitRitePath);
%         header_row_num = find(contains(txt_data(:,1), 'ID'),1,'first');
%         header_row = txt_data(header_row_num,:);
%         for i = 1:length(header_row)
%             header_row{i} = strtrim(header_row{i});
%         end
%         timeColIdx = ismember(header_row, 'Time');
% 
%         trial_times = unique(txt_data(header_row_num+1:size(num_data,1)+header_row_num, timeColIdx), 'stable');
%         savedTimes = datetime(NaT(length(trial_times),1),'TimeZone','America/Chicago');
%         for i = 1:length(trial_times)
%             fullDate = trial_times{i};
%             spaceIdx = strfind(fullDate, ' ');
%             savedTime = fullDate(spaceIdx(1)+1:end);
%             savedTimes(i) = datetime(savedTime, 'InputFormat', 'h:mm:ss a', 'TimeZone', 'America/Chicago');
%         end
%         [~,sortedOrder] = sort(savedTimes);
%         if ~isequal(sortedOrder', 1:length(sortedOrder))
%             gaitRiteStruct.(substr) = sortedOrder';
%         end
%     end
% end
% 
% gaitRiteCombs = fieldnames(gaitRiteStruct);
% xsensCombs = fieldnames(xsensStruct);
% delsysCombs = fieldnames(delsysStruct);
% 
% assert(isempty(gaitRiteCombs)); % GaitRite is always "in order", but that order is wrong if it doesn't match XSENS & Delsys
% 
% assert(isequal(delsysCombs, xsensCombs));
% % Check that the orders listed in Delsys and XSENS are identical
% for i = 1:length(delsysCombs)
%     currComb = delsysCombs{i};
%     xsensOrder = xsensStruct.(currComb);
%     delsysOrder = delsysStruct.(currComb);
%     assert(isequal(delsysOrder, xsensOrder));
% end
% 
% combs = xsensStruct;
% 
% end