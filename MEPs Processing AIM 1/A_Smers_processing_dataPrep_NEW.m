% Smers pipeline pre preocessing:
% From Labchart exported .mat file
% FILL IN BAD PULSES IN TEPS_LOG.xlsx
% To struct containing:
% - Raw segmented time signal per trial
% Filtered
% Centered and demeaned (After filtered)
% Aligned/shifted ( sometimes the delsys sends the trigger late ~45
% points, 22 ms)
% Saved to participant

subj_path_suffix = config.SUBJ_PATH_SUFFIX;
TEPcolNames = config.TEPS_LOG_COLUMN_NAMES;
prePostColNameHeader = TEPcolNames.PRE_POST_COLUMN;
tepFileNameHeader = TEPcolNames.TEP_FILENAME;
subjectNameHeader = TEPcolNames.SUBJECT_NAME;
pareticSideHeader = TEPcolNames.PARETIC_SIDE;
sessionCodeHeader = TEPcolNames.SESSION_CODE;
pulsesToDeleteHeader = TEPcolNames.PULSES_TO_DELETE;
timepointHeader = TEPcolNames.TIMEPOINT;
final_muscles_list = convertCharsToStrings(config.MUSCLES);
pulses_perIntensity = config.NUM_PULSES_PER_INTENSITY;

% Lowpass filter config
lowpassFilterConfig = config.LOWPASS_FILTER;
low = lowpassFilterConfig.LOWPASS_CUTOFF; % [Inanici, 2018]
% Don't do highpass filter, it adds low-freq distortion
% high = 20; % [Inanici, 2018]
samprate = config.SAMPLE_RATE;
lowpassOrder = lowpassFilterConfig.ORDER;
[f,e] = butter(lowpassOrder,low/(samprate/2),'low');

% Bandpass filter config
bandpassFilterConfig = config.BANDPASS_FILTER;
%A. Bandpass filter design (20-500 Hz)
low_cutoff = bandpassFilterConfig.LOW_CUTOFF;  % Lower cutoff frequency (Hz)
high_cutoff = bandpassFilterConfig.HIGH_CUTOFF; % Upper cutoff frequency (Hz)
bandpassOrder = bandpassFilterConfig.ORDER;
[b, a] = butter(bandpassOrder, [low_cutoff, high_cutoff]/(samprate/2), 'bandpass');


%% Read in master TEPs file. Removes extra rows
% Obtains the bad pulses for each MEP trial.
teps_log_filename = fullfile(subj_path, 'TEPs_log.xlsx');
% [~,~,teps_log] = xlsread(teps_log_filename,'Sheet1');
teps_log = readtable(teps_log_filename,'Sheet','Sheet1');
isNumericNaN = @(x) isempty(x); % Anonymous function
nanSubjIdx = cellfun(isNumericNaN, teps_log.Subject);
firstNaNSubjIdx = find(nanSubjIdx,1,'first');
teps_log = teps_log(1:firstNaNSubjIdx-1,:);
header_row = teps_log(1,:);
prePostColNameIdx = ismember(header_row, prePostColNameHeader);
tepFileNameIdx = ismember(header_row, tepFileNameHeader);
subjectNameIdx = ismember(header_row, subjectNameHeader);
pareticSideIdx = ismember(header_row, pareticSideHeader);
sessionCodeIdx = ismember(header_row, sessionCodeHeader);
pulsesToDeleteIdx = ismember(header_row, pulsesToDeleteHeader);
timepointIdx = ismember(header_row, timepointHeader);

curr_subj_path = fullfile(subj_path_prefix, SUBJ, subj_path_suffix);
curr_subj_save_path = fullfile(subj_save_path_prefix, SUBJ, subj_path_suffix);

% Create folder to save mats if do not exist
% Define the new folder path
folderPath = fullfile(curr_subj_save_path, 'TEPsProcessed');
mkdir(folderPath);

%% Process each .mat file.
for i = 1:height(teps_log)
    subj_tepsLog_row = teps_log(i,:);
    fileName = subj_tepsLog_row{tepFileNameIdx};

    % Get subject - print all details
    subj = subj_tepsLog_row{subjectNameIdx};
    paretic_side = subj_tepsLog_row{pareticSideIdx};
    timepoint = subj_tepsLog_row{prePostColNameIdx};
    session_code = subj_tepsLog_row{sessionCodeIdx};
    pulsestodelete = subj_tepsLog_row{pulsesToDeleteIdx};

    disp([num2str(subj), ' ', timepoint, ' - ', session_code]);

    processed_files = dir(fullfile(curr_subj_save_path,"TEPsProcessed", '*.mat'));
    if sum(contains({processed_files.name}, "A_" +SUBJ  +"_pre_processedTEPs_"))
        disp("*************A_" + SUBJ + "_" + mapped_interventions(session_code) + " already processed");
        return
    end

    number_of_muscles = length(final_muscles_list);

    % Load the file.
    load(fullfile(inter_path, fileName));

    % Identify the bad pulses.
    delete_in = getBadPulses(pulsestodelete);

    % Find rows that contain RVL, LRV, STIM, and KNEE to delete
    emptyrow_title_in = [ find(ismember(titles,'RKne','rows')) find(ismember(titles,'LKne','rows')) find(ismember(titles,'Stim','rows'))];

    % Final set of titles
    titles(emptyrow_title_in,:) = [];
    % Final rows of data
    datastart(emptyrow_title_in,:) = [];

    % Get the order of channels presented in the mat file
    channels = cell(number_of_muscles,1);
    for channel_num = 1:number_of_muscles
        channels{channel_num} = strtrim(titles(channel_num,:)); % gives order of channels in the data
    end

    %% Correcting the channels namings that were mislabeled:
    channels_struct_from_json = jsondecode(fileread('A_channels.json'));
    if ismember(SUBJ, fieldnames(channels_struct_from_json))
        if ismember(INTER, fieldnames(channels_struct_from_json.(SUBJ)))
            channels = channels_struct_from_json.(SUBJ).(INTER);
        end
    end

    %% Creating the structs of filtered data
    EMG_raw_struct = struct_raw_EMG_trials(channels, data, datastart, dataend, delete_in);
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Raw = EMG_raw_struct;

    % CHECK PULSES (RANDOM MUSCLE)
    total_pulses=size(EMG_raw_struct.RHAM,1);

    if mod(total_pulses,pulses_perIntensity) ~= 0
        disp(strcat(subj , " ", session_code  , " ",timepoint));
        disp(['... (ERR) != ' num2str(pulses_perIntensity)  ' pulses per intensities detected. Please check pulses #s to remove']);
        % ADD TO ERROR LIST:
        disp(delete_in);
        wrongPulses{end + 1} = strcat(subj , " ", session_code  , " ",timepoint, " tot pulses " , num2str(total_pulses));
    end

    % LOWPASS
    struct_low_filt_EMG_trials = EMG_filt(EMG_raw_struct, f,e);
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).LowPass = struct_low_filt_EMG_trials;

    % BANDPASS
    struct_band_filt_EMG_trials = EMG_filt(EMG_raw_struct, b,a);
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).BandPass = struct_band_filt_EMG_trials;

    % ###############
    %1. Shifting signal to last reference (just the bandpass):
    [struct_EMG_trials_shift_fromBand, struct_EMG_trials_shiftIDX] = align_signals(struct_band_filt_EMG_trials);
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Aligned_fromBand = struct_EMG_trials_shift_fromBand;
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).AlignedShiftIdx_fromBand = struct_EMG_trials_shiftIDX;
    % if index is negative - have to shift forward
    % #####
    %2. RECTIFY SIGNAL - Using bandpass to recrified signal

    musc_fieldnames = fieldnames(struct_EMG_trials_shift_fromBand);
    for channel_num = 1:numel(musc_fieldnames)
        muscle = musc_fieldnames{channel_num};
        muscles_trials = struct_EMG_trials_shift_fromBand.(muscle);
        rect_struct.(muscle) = abs(muscles_trials);
    end
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Rectified_afterAligBandOnly = rect_struct;

    %.4 Stim ONSET
    struct_stimONSET_INDEX_EMG_trials = getStimOnsetMax(struct_band_filt_EMG_trials);
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).StimOnsetPeaks = struct_stimONSET_INDEX_EMG_trials;

    % SMOOTH INTERMEDIATE STEP BEFORE ALGIN
    % ###############
    %1. Smoothing signal - Using bandpass to recrified signal
    windowDuration = 3e-3; % Window duration (seconds)
    struct_filtSMOOTH_EMG_trials = Smoothing_wind_Filt(struct_band_filt_EMG_trials, windowDuration, samprate);
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Smoothed = struct_filtSMOOTH_EMG_trials;

    % ###############
    %2. Shifting signal to last reference:
    [struct_EMG_trials_shift_fromSmooth, struct_EMG_trials_shiftIDX] = align_signals(struct_filtSMOOTH_EMG_trials);
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Aligned_fromSmooth = struct_EMG_trials_shift_fromSmooth;
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).AlignedShiftIdx_fromSmooth = struct_EMG_trials_shiftIDX;


    % #####
    %3. RECTIFY SIGNAL - Using bandpass to recrified signal

    musc_fieldnames = fieldnames(struct_EMG_trials_shift_fromSmooth);
    for channel_num = 1:numel(musc_fieldnames)
        muscle = musc_fieldnames{channel_num};
        muscles_trials = struct_EMG_trials_shift_fromSmooth.(muscle);
        rect_struct.(muscle) = abs(muscles_trials);
    end
    subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Rectified_afterAligSmooth = rect_struct;
end