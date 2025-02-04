function [delsysTable] = processDelsysAllInterventions(delsysConfig, subject_delsys_folder, intervention_folders, mapped_interventions, regexsConfig)

%% PURPOSE: LOAD AND PREPROCESS THE DELSYS DATA.
delsysTable = table;
for i = 1:length(intervention_folders)   
    intervention_folder = intervention_folders{i};        
    intervention_folder_path = fullfile(subject_delsys_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    tmpTable = loadAndFilterDelsysEMGOneIntervention(delsysConfig, intervention_folder_path, intervention_field_name, regexsConfig);
    delsysTable = addToTable(delsysTable, tmpTable);
end