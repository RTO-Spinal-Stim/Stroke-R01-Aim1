function [loaded_data] = loadDelsysEMGOneFile(emgFilePath)

%% PURPOSE: LOAD THE DELSYS EMG DATA
% Inputs:
% emgFilePath: The full path to the EMG file
%
% Outputs:
% loaded_data: The loaded EMG data

%% Load the data
from_file_data = load(emgFilePath);

%% Initialize the outcome variable
% filtered_data = struct();

%% Parse each of the muscles from the 1xN vector of EMG data
% Extract muscle names from the loaded data
muscle_names = strrep(cellstr(from_file_data.titles), '''', '');
muscle_names = muscle_names(1:10);

loaded_data = struct();

for i = 1:length(muscle_names)

    muscleName = muscle_names{i};
    startData = from_file_data.datastart(i);
    endData = from_file_data.dataend(i);

    if startData == -1
        continue;
    end

    loaded_data.(muscleName) = from_file_data.data(startData:endData);

    % If all of the data are the same value, convert them to NaN
    if all(diff(loaded_data.(muscleName))==0)
        loaded_data.(muscleName) = NaN(size(loaded_data.(muscleName)));
    end

end