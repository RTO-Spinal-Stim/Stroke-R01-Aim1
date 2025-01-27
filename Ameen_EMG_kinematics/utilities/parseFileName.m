function [subject_id, intervention_name, speed, pre_post] = parseFileName(regexsConfig, fileName)

%% PURPOSE: PARSE A FILE NAME TO OBTAIN THE CONDITIONS

[~, subject_id] = findPatternIndices(fileName, regexsConfig.SUBJECT_ID);
[~, intervention_name] = findPatternIndices(fileName, regexsConfig.INTERVENTIONS);
[~, speed] = findPatternIndices(fileName, regexsConfig.PRE_POST);
[~, pre_post] = findPatternIndices(fileName, regexsConfig.SPEED);
