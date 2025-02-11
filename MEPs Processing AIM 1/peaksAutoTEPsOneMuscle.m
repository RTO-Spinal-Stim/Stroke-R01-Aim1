function [resultTable] = peaksAutoTEPsOneMuscle(muscleData)

%% PURPOSE: AUTOMATICALLY FIND THE PEAKS IN ONE MUSCLE'S TEPs DATA
% Inputs:
% muscleData: The signal for this muscle's EMG data
%
% Outputs:
% resultTable: 

numPulses = size(muscleData,1);
for i = 1:numPulses
    signal = muscleData(i,:);
    [minIDX, maxIDX, min_mV, max_mV, p2p, latency, End,  STIM_ARTIFACT_PEAK] =...
                peaksAuto(signal, foundLat, minIDX_picked, maxIDX_picked, sitmIDX_picked);
end