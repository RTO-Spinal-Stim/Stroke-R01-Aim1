function [xsensTable] = processXSENSAllInterventions(xsensConfig, subject_xsens_folder, intervention_folders, mapped_interventions, regexsConfig)

%% PURPOSE: LOAD AND PREPROCESS THE XSENS DATA.
xsensTable = table;
for i = 1:length(intervention_folders)
    intervention_folder = intervention_folders{i};        
    intervention_folder_path = fullfile(subject_xsens_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    tmpTable = loadAndFilterXSENSOneIntervention(xsensConfig, intervention_folder_path, intervention_field_name, regexsConfig);
    xsensTable = addToTable(xsensTable, tmpTable);
end