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

%% Aggregate the data into a matrix.
muscle_names = fieldnames(emgData);
n_points = max(size(emgData.(muscle_names{1})));
aggEMGData = NaN(length(muscle_names), n_points);
for i = 1:length(muscle_names)
    muscle_name = muscle_names{i};
    try
        aggEMGData(i, :) = emgData.(muscle_name);
    catch
        disp('test');
    end
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