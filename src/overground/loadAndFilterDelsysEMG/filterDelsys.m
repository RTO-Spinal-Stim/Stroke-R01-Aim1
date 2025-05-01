function [tableOut] = filterDelsys(tableIn, colNameToFilter, colNameOut, config, Fs)

%% PURPOSE: FILTER THE DELSYS EMG DATA
% Inputs:
% tableIn: The table of Delsys EMG data
% colNameToFilter: The column name of the data to filter
% colNameOut: The column name to store the filtered data to.
% config: The filter configuration struct
% Fs: Delsys sampling frequency
%
% Outputs:
% tableOut: The filtered table

disp('Filtering Delsys');

tableOut = copyCategorical(tableIn);
for i = 1:height(tableIn)
        
    loaded_data = tableIn.(colNameToFilter)(i);
    muscle_names = fieldnames(loaded_data);
    filtered_data = struct;
    for muscleNum = 1:length(muscle_names)
        muscle_name = muscle_names{muscleNum};
        filtered_data.(muscle_name) = filterEMGOneMuscle(loaded_data.(muscle_name), config, Fs);
    end

    tableOut.(colNameOut)(i) = filtered_data;    
end