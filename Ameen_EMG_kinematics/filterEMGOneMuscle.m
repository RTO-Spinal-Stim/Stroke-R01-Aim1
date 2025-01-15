function [filtered_emg] = filterEMGOneMuscle(raw_emg, filterEMGConfig, EMG_Fs)

%% PURPOSE: PARSE CONFIGURATION AND FILTER THE RAW EMG DATA
% config.json format:
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

% Parameters for bandpass filter
fpass = filterEMGConfig.BANDPASS_CUTOFF;
order = filterEMGConfig.BANDPASS_ORDER;

% Parameters for low-pass filter (envelope)
fcut = filterEMGConfig.LOWPASS_CUTOFF;

% Filter coefficients computed once
[b_band, a_band] = butter(order, fpass / (EMG_Fs / 2), 'bandpass');
[b_low, a_low] = butter(2, fcut / (EMG_Fs / 2), 'low');

% Subtract mean
emg_subtracted_mean = raw_emg - mean(raw_emg);

% Bandpass filter
emg_bandpass = filtfilt(b_band, a_band, emg_subtracted_mean);

% Rectification
emg_rectified = abs(emg_bandpass);

% Low-pass filter (envelope)
filtered_emg = filtfilt(b_low, a_low, emg_rectified);