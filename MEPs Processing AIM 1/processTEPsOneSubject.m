function [tepsTable] = processTEPsOneSubject(tepsLogAll, subject, config, correctChannelsJSONPath)

%% PURPOSE: PROCESS TEPs FOR ONE SUBJECT. PART A IN NICOLE'S PIPELINE FOR STROKE SPINAL STIM.
% Inputs:
% tepsLog: TEPs log table
% subject: Subject name
% tepColNamesConfig: Struct of column names for TEPs log
% correctChannelsJSONPath: Path to the JSON file for correcting the EMG
% channels
% 
% Outputs:
% tepsTable: Table of processed TEPs results.

%% Config
TEPcolNamesConfig = config.TEPS_LOG_COLUMN_NAMES;
subjectNameHeader = TEPcolNamesConfig.SUBJECT_NAME;

%% Get the numeric part of the subject name
numericRegex = '\d+';
subjectNum = regexp(subject, numericRegex, 'match');
subjectNum = subjectNum{1};

%% Filter TEPS log for one subject.
tepsLog = filterTEPsLogForOneSubject(tepsLogAll, subjectNameHeader, subjectNum);
correctedChannelsStruct = jsondecode(fileread(correctChannelsJSONPath));
correctedChannelsStructSubject = struct;
if isfield(correctedChannelsStruct, subject)
    correctedChannelsStructSubject = correctedChannelsStruct.(subject);
end
tepsTable = table;
for i = 1:height(tepsLog)
    row = processTEPsOneTrial(config, tepsLog(i,:), correctedChannelsStructSubject);  
    tepsTable = [tepsTable; row];
end