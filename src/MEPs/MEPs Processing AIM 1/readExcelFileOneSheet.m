function [excelTable] = readExcelFileOneSheet(excelFilePath, columnHeader, sheetName)

%% PURPOSE: LOAD THE TEPs LOG FROM DISK AS A TABLE. REMOVES EXTRA ROWS.
% Inputs:
% excelFilePath: The file path of the Excel file.
% columnHeader: The name of the column header.
% sheetName: The name of the sheet to read from in the Excel file.
%
% Outputs:
% excelTable: The table representation of the Excel file.

if ~exist('sheetName','var')
    sheetName = 'Sheet1';
end

if ~exist('columnHeader','var')
    columnHeader = 'Subject';
end

isEmpty = @(x) isempty(x); % Anonymous function

excelTableRaw = readtable(excelFilePath,'Sheet',sheetName);
emptyIdx = cellfun(isEmpty, excelTableRaw.(columnHeader));
excelTable = excelTableRaw(~emptyIdx,:);