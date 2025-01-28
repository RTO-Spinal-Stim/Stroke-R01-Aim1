function [numSynergies] = calculateSynergies(emgData, maxNumSynergies, VAFthresh)

%% PURPOSE: CALCULATE THE MUSCLE SYNERGIES PRESENT IN EMG DATA
% Inputs:
% emgData: struct of filtered EMG data. Each field is one muscle. Each
%   muscle's data is a 1xN vector, which can be one gait cycle, one whole
%   trial, etc.
% maxNumSynergies: scalar double integer. An estimate of the maximum number of synergies.
% VAFthresh: scalar double integer (0-1). The threshold to determine the
% number of synergies
%
% Outputs:
% numSynergies: scalar double. The number of synergies found.

%% If the data is inconsistent in length, get the shortest amount of data to prep for resampling.
min_n_points = inf;
muscle_names = fieldnames(emgData);
for i = 1:length(muscle_names)
    muscle_name = muscle_names{i};
    if length(emgData.(muscle_name)) < min_n_points
        min_n_points = length(emgData.(muscle_name));
    end
end

% When there is an asymmetrical number of gait cycles in L vs. R, the fields for the side
% with fewer gait cycles will be empty in the last gait cycle. In this
% case, return NaN.
if min_n_points == 0
    numSynergies = NaN;
    return;
end

% Turn off the warning
warningName = 'stats:nnmf:LowRank';
warningStruct = warning('query', warningName);
warning('off', warningStruct.identifier);

%% Aggregate the data into a matrix.
aggEMGData = NaN(length(muscle_names), min_n_points);
for i = 1:length(muscle_names)
    muscle_name = muscle_names{i};
    n_points_original = length(emgData.(muscle_name));
    if n_points_original > min_n_points
        dataToStore = resample(emgData.(muscle_name), min_n_points, n_points_original);        
    else
        dataToStore = emgData.(muscle_name);
    end
    aggEMGData(i,:) = dataToStore;
end

%% Calculate Variance Accounted For (VAF)
% Perform non-negative matrix factorization (nnmf) to extract synergies and weights
VAFs = NaN(maxNumSynergies,1);
for i = 1:maxNumSynergies
    [synergies, weights] = nnmf(aggEMGData, maxNumSynergies);
    reconstruction = synergies * weights;
    VAFs(i) = 1 - sum((aggEMGData - reconstruction).^2, 'all') / sum(aggEMGData.^2, 'all');
end

%% Get the number of synergies
numSynergies = find(VAFs >= VAFthresh,1,'first');

% Reset the warning back to its original state.
warning(warningStruct.state, warningStruct.identifier);