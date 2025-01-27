function [downsampledData] = downsampleData(data, n_points_new)

%% PURPOSE: DOWNSAMPLE THE DATA TO THE SPECIFIED NUMBER OF POINTS.

fieldNames = fieldnames(data);
for i = 1:length(fieldNames)
    fieldName = fieldNames{i};
    n_points_original = length(data.(fieldName));
    downsampledData.(fieldName) = resample(data.(fieldName), n_points_new, n_points_original);
end