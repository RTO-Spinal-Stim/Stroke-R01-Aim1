function filteredEMG = preprocessEMG(allEMGData, EMG_Fs)
    % Parameters for bandpass filter
    fpass = [10 400];
    order = 4;

    % Parameters for low-pass filter (envelope)
    fcut = 5;

    % Filter coefficients computed once
    [b_band, a_band] = butter(order, fpass / (EMG_Fs / 2), 'bandpass');
    [b_low, a_low] = butter(2, fcut / (EMG_Fs / 2), 'low');

    % Initialize struct to store filtered EMG
    filteredEMG = struct();

    % Loop through each trial field in the struct
    trialFields = fieldnames(allEMGData);
    for trialIndex = 1:numel(trialFields)
        trialData = allEMGData.(trialFields{trialIndex});
        filteredTrialEMG = struct();

        % Loop through each muscle field in the trial data
        muscleFields = fieldnames(trialData);
        for muscleIndex = 1:numel(muscleFields)
            emg_signal = trialData.(muscleFields{muscleIndex});

            % Subtract mean
            emg_subtracted_mean = emg_signal - mean(emg_signal);

            % Bandpass filter
            emg_bandpass = filtfilt(b_band, a_band, emg_subtracted_mean);

            % Rectification
            emg_rectified = abs(emg_bandpass);

            % Low-pass filter (envelope)
            emg_envelope = filtfilt(b_low, a_low, emg_rectified);

            % Store filtered EMG in filtered trial EMG struct
            filteredTrialEMG.(muscleFields{muscleIndex}) = emg_envelope;
        end

        % Store filtered trial EMG in filteredEMG struct
        filteredEMG.(trialFields{trialIndex}) = filteredTrialEMG;
    end
end
