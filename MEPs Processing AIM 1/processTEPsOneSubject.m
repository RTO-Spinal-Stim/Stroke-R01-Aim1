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

%% Get the numeric part of the subject name
numericRegex = '\d+';
subjectNum = regexp(subject, numericRegex, 'match');
subjectNum = subjectNum{1};

%% Filter TEPS log for one subject.
tepColNamesConfig = config.TEPS_LOG_COLUMN_NAMES;
subjectNameHeader = tepColNamesConfig.SUBJECT_NAME;
tepsLog = filterTEPsLogForOneSubject(tepsLogAll, subjectNameHeader, subjectNum);
channels_struct_from_json = jsondecode(fileread(correctChannelsJSONPath));
tepsTable = table;
for i = 1:height(tepsLog)



end