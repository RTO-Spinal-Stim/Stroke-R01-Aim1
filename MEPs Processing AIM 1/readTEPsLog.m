function [tepsLog] = readTEPsLog(tepsFilePath)

%% PURPOSE: LOAD THE TEPs LOG FROM DISK AS A TABLE.
% Inputs:
% tepsFilePath: The file path of the TEPs log.

isEmpty = @(x) isempty(x); % Anonymous function

tepsLog = readtable(tepsFilePath,'Sheet','Sheet1');
nanSubjIdx = cellfun(isEmpty, tepsLog.Subject);
firstNaNSubjIdx = find(nanSubjIdx,1,'first');
tepsLog = tepsLog(1:firstNaNSubjIdx-1,:);