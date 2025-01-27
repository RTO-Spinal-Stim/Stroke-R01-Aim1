function [loaded_data, filtered_data] = loadAndFilterDelsysEMGOneFile(emgFilePath, delsysEMGConfig)

%% PURPOSE: PREPROCESS THE DELSYS EMG DATA. PROBABLY DOES NOT WORK FOR MEPs

%% Configuration
% validCombinations = config.VALID_COMBINATIONS;
emgFilterConfig = delsysEMGConfig.FILTER;
EMG_Fs = delsysEMGConfig.SAMPLING_FREQUENCY;

%% Load the data
from_file_data = load(emgFilePath);

%% Initialize the outcome variable
filtered_data = struct();

%% Parse each of the muscles from the 1xN vector of EMG data
% Extract muscle names from the loaded data
muscle_names = strrep(cellstr(from_file_data.titles), '''', '');
muscle_names = muscle_names(1:10);

loaded_data = struct();

for i = 1:length(muscle_names)

    startData = from_file_data.datastart(i);
    endData = from_file_data.dataend(i);

    if startData == -1
        continue;
    end

    loaded_data.(muscle_names{i}) = from_file_data.data(startData:endData);

end

%% Filter the data
for i = 1:length(muscle_names)
    muscle_name = muscle_names{i};
    filtered_data.(muscle_name) = filterEMGOneMuscle(loaded_data.(muscle_name), emgFilterConfig, EMG_Fs);
end