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

% Create folder to save mats if do not exist
% Define the new folder path
folderPath = fullfile(curr_subj_save_path, 'TEPsProcessed');
mkdir(folderPath);

% Process the TEPs log for one subject.
correctChannelsJSONPath = 'A_channels.json';
tepsResultTableOneSubject = processTEPsOneSubject(tepsLog, subject, config, curr_subj_path, correctChannelsJSONPath);

%% Process each .mat file.
% for i = 1:height(tepsLogOneSubject)
%     subj_tepsLog_row = tepsLogOneSubject(i,:);    
% 
%     % Get subject - print all details
%     currentRowSubject = subj_tepsLog_row.(subjectNameHeader){1};
%     fileName = subj_tepsLog_row.(tepFileNameHeader){1};
%     paretic_side = subj_tepsLog_row.(pareticSideHeader){1};
%     timepoint = subj_tepsLog_row.(prePostColNameHeader){1};
%     session_code = subj_tepsLog_row.(sessionCodeHeader){1};
%     pulsesToDelete = subj_tepsLog_row.(pulsesToDeleteHeader){1};
% 
%     disp([num2str(currentRowSubject), ' ', timepoint, ' - ', session_code]);
% 
%     processed_files = dir(fullfile(curr_subj_save_path,"TEPsProcessed", '*.mat'));
%     if sum(contains({processed_files.name}, "A_" +subject  +"_pre_processedTEPs_"))
%         disp("*************A_" + subject + "_" + mapped_interventions(session_code) + " already processed");
%         return
%     end
% 
%     number_of_muscles = length(final_muscles_list);
% 
%     % Load the file.
%     intervention_path = fullfile(curr_subj_path, session_code);
%     load(fullfile(intervention_path, fileName));
% 
%     % Identify the bad pulses.
%     delete_in = getBadPulses(pulsesToDelete);
% 
%     % Find rows that contain RVL, LRV, STIM, and KNEE to delete
%     emptyrow_title_in = [ find(ismember(titles,'RKne','rows')) find(ismember(titles,'LKne','rows')) find(ismember(titles,'Stim','rows'))];
% 
%     % Final set of titles
%     titles(emptyrow_title_in,:) = [];
%     % Final rows of data
%     datastart(emptyrow_title_in,:) = [];
% 
%     % Get the order of channels presented in the mat file
%     channels = cell(number_of_muscles,1);
%     for channel_num = 1:number_of_muscles
%         channels{channel_num} = strtrim(titles(channel_num,:)); % gives order of channels in the data
%     end
% 
%     %% Correcting the channels namings that were mislabeled:
%     channels_struct_from_json = jsondecode(fileread('A_channels.json'));
%     if ismember(subject, fieldnames(channels_struct_from_json))
%         if ismember(INTER, fieldnames(channels_struct_from_json.(subject)))
%             channels = channels_struct_from_json.(subject).(INTER);
%         end
%     end
% 
%     %% Creating the structs of filtered data
%     EMG_raw_struct = struct_raw_EMG_trials(channels, data, datastart, dataend, delete_in);
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).Raw = EMG_raw_struct;
% 
%     % CHECK PULSES (RANDOM MUSCLE)
%     total_pulses=size(EMG_raw_struct.RHAM,1);
% 
%     if mod(total_pulses,pulses_perIntensity) ~= 0
%         disp(strcat(currentRowSubject , " ", session_code  , " ",timepoint));
%         disp(['... (ERR) != ' num2str(pulses_perIntensity)  ' pulses per intensities detected. Please check pulses #s to remove']);
%         % ADD TO ERROR LIST:
%         disp(delete_in);
%         wrongPulses{end + 1} = strcat(currentRowSubject , " ", session_code  , " ",timepoint, " tot pulses " , num2str(total_pulses));
%     end
% 
%     % LOWPASS
%     struct_low_filt_EMG_trials = EMG_filt(EMG_raw_struct, f,e);
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).LowPass = struct_low_filt_EMG_trials;
% 
%     % BANDPASS
%     struct_band_filt_EMG_trials = EMG_filt(EMG_raw_struct, b,a);
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).BandPass = struct_band_filt_EMG_trials;
% 
%     % ###############
%     %1. Shifting signal to last reference (just the bandpass):
%     [struct_EMG_trials_shift_fromBand, struct_EMG_trials_shiftIDX] = align_signals(struct_band_filt_EMG_trials);
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).Aligned_fromBand = struct_EMG_trials_shift_fromBand;
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).AlignedShiftIdx_fromBand = struct_EMG_trials_shiftIDX;
%     % if index is negative - have to shift forward
%     % #####
%     %2. RECTIFY SIGNAL - Using bandpass to recrified signal
% 
%     musc_fieldnames = fieldnames(struct_EMG_trials_shift_fromBand);
%     for channel_num = 1:numel(musc_fieldnames)
%         muscle = musc_fieldnames{channel_num};
%         muscles_trials = struct_EMG_trials_shift_fromBand.(muscle);
%         rect_struct.(muscle) = abs(muscles_trials);
%     end
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).Rectified_afterAligBandOnly = rect_struct;
% 
%     %.4 Stim ONSET
%     struct_stimONSET_INDEX_EMG_trials = getStimOnsetMax(struct_band_filt_EMG_trials);
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).StimOnsetPeaks = struct_stimONSET_INDEX_EMG_trials;
% 
%     % SMOOTH INTERMEDIATE STEP BEFORE ALGIN
%     % ###############
%     %1. Smoothing signal - Using bandpass to recrified signal
%     windowDuration = 3e-3; % Window duration (seconds)
%     struct_filtSMOOTH_EMG_trials = Smoothing_wind_Filt(struct_band_filt_EMG_trials, windowDuration, samprate);
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).Smoothed = struct_filtSMOOTH_EMG_trials;
% 
%     % ###############
%     %2. Shifting signal to last reference:
%     [struct_EMG_trials_shift_fromSmooth, struct_EMG_trials_shiftIDX] = align_signals(struct_filtSMOOTH_EMG_trials);
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).Aligned_fromSmooth = struct_EMG_trials_shift_fromSmooth;
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).AlignedShiftIdx_fromSmooth = struct_EMG_trials_shiftIDX;
% 
% 
%     % #####
%     %3. RECTIFY SIGNAL - Using bandpass to recrified signal
% 
%     musc_fieldnames = fieldnames(struct_EMG_trials_shift_fromSmooth);
%     for channel_num = 1:numel(musc_fieldnames)
%         muscle = musc_fieldnames{channel_num};
%         muscles_trials = struct_EMG_trials_shift_fromSmooth.(muscle);
%         rect_struct.(muscle) = abs(muscles_trials);
%     end
%     subj_Struct.(subject).(mapped_interventions(session_code)).(timepoint).Rectified_afterAligSmooth = rect_struct;
% end