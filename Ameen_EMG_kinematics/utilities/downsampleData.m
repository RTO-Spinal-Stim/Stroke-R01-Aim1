function [downsampledData] = downsampleData(data, n_points_new)

%% PURPOSE: DOWNSAMPLE THE DATA TO THE SPECIFIED NUMBER OF POINTS.

n_points_original = length(data);
downsampledData = resample(data, n_points_new, n_points_original);