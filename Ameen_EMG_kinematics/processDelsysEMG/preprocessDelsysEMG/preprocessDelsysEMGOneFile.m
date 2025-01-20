function [processed_data] = preprocessDelsysEMGOneFile(emgFilePath, delsysEMGConfig)

%% PURPOSE: PREPROCESS THE DELSYS EMG DATA. PROBABLY DOES NOT WORK FOR MEPs

%% Configuration
% validCombinations = config.VALID_COMBINATIONS;
emgFilterConfig = delsysEMGConfig.FILTER;
EMG_Fs = delsysEMGConfig.SAMPLING_FREQUENCY;

%% Load the data
loaded_data = load(emgFilePath);

%% Initialize the outcome variable
processed_data = struct();

%% Parse each of the muscles from the 1xN vector of EMG data
% Extract muscle names from the loaded data
muscle_names = strrep(cellstr(loaded_data.titles), '''', '');
muscle_names = muscle_names(1:10);

data = struct();

for i = 1:length(muscle_names)

    startData = loaded_data.datastart(i);
    endData = loaded_data.dataend(i);

    if startData == -1
        continue;
    end

    data.(muscle_names{i}) = loaded_data.data(startData:endData);

end

%% Filter the data
for i = 1:length(muscle_names)
    muscle_name = muscle_names{i};
    processed_data.(muscle_name) = filterEMGOneMuscle(data.(muscle_name), emgFilterConfig, EMG_Fs);
end