function [processedRow, logInfo] = processTEPsOneFile(config, rowIn, trialFilePath, correctedChannelsStruct)

%% PURPOSE: PROCESS ONE INDIVIDUAL TRIAL OF TEPs 
% PART A OF NICOLE'S PIPELINE.
% Inputs:
% config: The configuration struct loaded from JSON
% rowIn: A table with one row of data from the TEPs log.
% trialFilePath: Char path to the file for this trial.
% correctedChannelsStruct: Loaded from JSON, identifies which channels need
% to be corrected.

processedRow = table;

%% Config
TEPcolNamesConfig = config.TEPS_LOG_COLUMN_NAMES;
prePostColNameHeader = TEPcolNamesConfig.PRE_POST_COLUMN;
tepFileNameHeader = TEPcolNamesConfig.TEP_FILENAME;
subjectNameHeader = TEPcolNamesConfig.SUBJECT_NAME;
pareticSideHeader = TEPcolNamesConfig.PARETIC_SIDE;
sessionCodeHeader = TEPcolNamesConfig.SESSION_CODE;
pulsesToDeleteHeader = TEPcolNamesConfig.PULSES_TO_DELETE;
timepointHeader = TEPcolNamesConfig.TIMEPOINT;
final_muscles_list = convertCharsToStrings(config.MUSCLES);
number_of_muscles = length(final_muscles_list);
pulses_perIntensity = config.NUM_PULSES_PER_INTENSITY;
sampleRate = config.SAMPLE_RATE;
windowDuration = config.WINDOW_DURATION; % Window duration (seconds)

mapped_interventions = containers.Map(config.INTERVENTION_FOLDERS, config.MAPPED_INTERVENTION_FIELDS);

processedRow.Name{1} = ['SS' rowIn.(subjectNameHeader){1} '_' mapped_interventions(rowIn.(sessionCodeHeader){1}) '_' rowIn.(prePostColNameHeader){1}];

%% Filter
% Don't do highpass filter, it adds low-freq distortion [Inanici, 2018]
% Lowpass filter config
lowpassFilterConfig = config.LOWPASS_FILTER;
low = lowpassFilterConfig.LOWPASS_CUTOFF; % [Inanici, 2018]
lowpassOrder = lowpassFilterConfig.ORDER;
[f,e] = butter(lowpassOrder,low/(sampleRate/2),'low');

% Bandpass filter config
bandpassFilterConfig = config.BANDPASS_FILTER;
%A. Bandpass filter design (20-500 Hz)
low_cutoff = bandpassFilterConfig.LOW_CUTOFF;  % Lower cutoff frequency (Hz)
high_cutoff = bandpassFilterConfig.HIGH_CUTOFF; % Upper cutoff frequency (Hz)
bandpassOrder = bandpassFilterConfig.ORDER;
[b, a] = butter(bandpassOrder, [low_cutoff, high_cutoff]/(sampleRate/2), 'bandpass');

% Get subject - print all details
subject = rowIn.(subjectNameHeader){1};
fileName = rowIn.(tepFileNameHeader){1};
paretic_side = rowIn.(pareticSideHeader){1};
timepoint = rowIn.(prePostColNameHeader){1};
session_code = rowIn.(sessionCodeHeader){1};
pulsesToDelete = rowIn.(pulsesToDeleteHeader){1};

disp([num2str(subject), ' ', timepoint, ' - ', session_code]);

%% Load the file.
% Variables in file:
% blocktimes
% com: Comments metadata
% comtext: The text of the comments
% data: All muscles' data as a 1xN vector, where N = # samples * # muscles
% dataend: M x N double indexing into data vector, where M = # muscles, N = # pulses
% datastart M x N double indexing into data vector, where M = # muscles, N = # pulses
% firstsampleoffset: Always all zeros?
% rangemax: 
% rangemin
% samplerate: M x N double of sample rates, where M = # muscles, N = # pulses. Should always be the same number.
% tickrate: 1xN vector of sample rates (?), where N = # pulses
% titles: The names of the muscles. MxN char array, where M = # channels 
% (# muscles + 1 for trigger), and N = length of longest channel name
% unittext: units, 2x2 array (1: mV, 2: V)
% unittextmap: MxN double indexing the units of each channel (using values from unittext)
load(trialFilePath, 'titles','data', 'datastart', 'dataend', 'com', 'comtext');

% Identify the bad pulses.
delete_in = getBadPulses(pulsesToDelete);

% Find rows that contain RVL, LRV, STIM, and KNEE to delete
emptyrow_title_in = [ find(ismember(titles,'RKne','rows')) find(ismember(titles,'LKne','rows')) find(ismember(titles,'Stim','rows'))];

% Final set of titles
titles(emptyrow_title_in,:) = [];
% Final rows of data
datastart(emptyrow_title_in,:) = [];

% Get the order of channels presented in the mat file
channels = cell(number_of_muscles,1);
for channel_num = 1:size(titles,1)
    currTitle = strtrim(titles(channel_num,:));
    if ismember(currTitle, final_muscles_list)
        channels{channel_num} = currTitle; % gives order of channels in the data
    end
end

%% Correcting the channels namings that were mislabeled
if isfield(session_code, fieldnames(correctedChannelsStruct))
    channels = correctedChannelsStruct.(intervention);
end

%% Creating the structs of raw data
EMG_raw_struct = struct_raw_EMG_trials(channels, data, datastart, dataend, delete_in);
processedRow.Raw_EMG = EMG_raw_struct;

%% Check the pulses
total_pulses=size(EMG_raw_struct.(final_muscles_list{1}),1); % Arbitrary muscle
logInfo = '';
if mod(total_pulses, pulses_perIntensity) ~= 0
    disp([subject, '_', session_code, '_',timepoint]);
    disp(['... (ERR) != ' num2str(pulses_perIntensity)  ' pulses per intensities detected. Please check pulses #s to remove']);
    % ADD TO ERROR LIST:
    disp(['Pulses to remove: ' delete_in]);
    logInfo = [subject, '_', session_code, '_', timepoint, ' Total Pulses: ' num2str(total_pulses)];
end
processedRow.LogInfo = {logInfo};

%% Lowpass filter
processedRow.Lowpass_EMG = EMG_filt(EMG_raw_struct, f, e);

%% Bandpass filter
processedRow.Bandpass_EMG = EMG_filt(EMG_raw_struct, b, a);

%% Shift the bandpassed signal to last reference
[struct_EMG_trials_shift_fromBand, struct_EMG_trials_shiftIDX] = align_signals(processedRow.Bandpass_EMG);
processedRow.AlignedFromBand = struct_EMG_trials_shift_fromBand;
processedRow.AlignedShiftIdxFromBand = struct_EMG_trials_shiftIDX;

%% Rectify the shifted signal
muscleFieldnames = fieldnames(struct_EMG_trials_shift_fromBand);
rectStruct = struct;
for channel_num = 1:numel(muscleFieldnames)
    muscle = muscleFieldnames{channel_num};
    muscles_trials = struct_EMG_trials_shift_fromBand.(muscle);
    rectStruct.(muscle) = abs(muscles_trials);
end
processedRow.Rectified_Shifted = rectStruct;

%% Stimulation onset
struct_stimONSET_INDEX_EMG_trials = getStimOnsetMax(processedRow.Bandpass_EMG);
processedRow.StimOnsetPeaks = struct_stimONSET_INDEX_EMG_trials;

%% Smooth intermediate step before aligning
struct_filtSMOOTH_EMG_trials = Smoothing_wind_Filt(processedRow.Bandpass_EMG, windowDuration, sampleRate);
processedRow.Smoothed = struct_filtSMOOTH_EMG_trials;

%% Shifting signal to last reference
[struct_EMG_trials_shift_fromSmooth, struct_EMG_trials_shiftIDX] = align_signals(struct_filtSMOOTH_EMG_trials);
processedRow.AlignedFromSmoothed = struct_EMG_trials_shift_fromSmooth;
processedRow.AlignedShiftIdxFromSmoothed = struct_EMG_trials_shiftIDX;

%% Rectify the smoothed signal
muscleFieldnames = fieldnames(struct_EMG_trials_shift_fromSmooth);
rectStruct = struct;
for channel_num = 1:numel(muscleFieldnames)
    muscle = muscleFieldnames{channel_num};
    muscles_trials = struct_EMG_trials_shift_fromSmooth.(muscle);
    rectStruct.(muscle) = abs(muscles_trials);
end
processedRow.RectifiedSmoothed_AfterAligned = rectStruct;