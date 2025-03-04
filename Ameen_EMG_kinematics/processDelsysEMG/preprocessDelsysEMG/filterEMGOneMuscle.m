function [filtered_emg] = filterEMGOneMuscle(raw_emg_one_muscle, filterEMGConfig, EMG_Fs)

%% PURPOSE: PARSE CONFIGURATION AND FILTER THE RAW EMG DATA
% Inputs:
% raw_emg_one_muscle: Vector of doubles for one muscle's EMG data
% filterEMGConfig: Config struct for the EMG filter
% EMG_Fs: Sampling rate for the EMG
%
% Outputs:
% filtered_emg: The filtered EMG data
%
% example config JSON format:
% {
%   "EMG_SAMPLING_FREQUENCY": 2000,
%   "FILTER_EMG": {
%       "BANDPASS_ORDER": 4,
%       "BANDPASS_CUTOFF": [
%           4, 
%           100
%       ],
%       "LOWPASS_ORDER": 2,
%       "LOWPASS_CUTOFF": 5,
%       "SAMPLING_FREQUENCY": 2000
%   }
% }

% If the input data is NaN, return NaN
if all(isnan(raw_emg_one_muscle))
    filtered_emg = NaN(size(raw_emg_one_muscle));
    return;
end

% Parameters for bandpass filter
fpass = filterEMGConfig.BANDPASS_CUTOFF;
order = filterEMGConfig.BANDPASS_ORDER;

% Parameters for low-pass filter (envelope)
fcut = filterEMGConfig.LOWPASS_CUTOFF;

% Filter coefficients computed once
[b_band, a_band] = butter(order, fpass / (EMG_Fs / 2), 'bandpass');
[b_low, a_low] = butter(2, fcut / (EMG_Fs / 2), 'low');

% Subtract mean
emg_subtracted_mean = raw_emg_one_muscle - mean(raw_emg_one_muscle);

% Bandpass filter
emg_bandpass = filtfilt(b_band, a_band, emg_subtracted_mean);

% Rectification
emg_rectified = abs(emg_bandpass);

% Low-pass filter (envelope)
filtered_emg = filtfilt(b_low, a_low, emg_rectified);