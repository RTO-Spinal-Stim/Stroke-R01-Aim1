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



%%
clc
clear
close all

%%
SUBJ_list = [ "02", "03", "04", "05"]%, "01","02", "03", "04", "05", "06", "08", "09", "10"];
TP_list = ["PRE","POST"]; 
INTER_list = ["30_RMT", "30_TOL", "50_RMT", "50_TOL", "SHAM1","SHAM2"]; 
% valid field names for struct :

inter_valid_names = containers.Map(INTER_list, ...
                          {'RMT30', 'TOL30', 'RMT50', 'TOL50', 'SHAM1', 'SHAM2'});
                       

%% Read in master TEPs file
% Obtains the bad pulses for each MEP trial. 

aim1_folder = "Y:\Spinal Stim_Stroke R01\AIM 1"; 
subj_path = fullfile(aim1_folder, 'Subject Data');
teps_log_filename = fullfile(subj_path, 'TEPs_log.xlsx'); 
[~,~,teps_log] = xlsread(teps_log_filename,'Sheet1');


%% Selecting folder to process
% disp("Select .mat file that want to process: "); 
% [file, filePath] = uigetfile(fullfile(subj_path, '*.*'), 'Select a mat file');
% 
% 
% % Check if a file was selected
% if isequal(file, 0)
%     disp('No file selected, process aborted.');
% else
%     % Display selected file
%     disp(['Selected file: ', fullfile(filePath, file)]);
%     
%     % Now you can process the selected file
%     % Add your processing code here
% end
%% START ITERATION
for SUBJ_i = 1:length(SUBJ_list)
    missingFiles = {};
    wrongPulses = {};
    SUBJ = SUBJ_list(SUBJ_i);
    subj_path = "Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\SS" + SUBJ +"\TEPs";
    
    % Create folder to save mats if do not exist
    % Define the new folder path
    folderPath = fullfile(subj_path, 'TEPsProcessed');

    % Check if the folder exists, and create it if it doesn't
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
        fprintf('Folder "%s" created successfully.\n', folderPath);
    else
        fprintf('Folder "%s" already exists.\n', folderPath);
    end

    
    for INTER_i = 1: length(INTER_list)
        INTER = INTER_list(INTER_i);
        inter_path = fullfile(subj_path, INTER);
        matFiles = dir(fullfile(inter_path, '*.mat'));

        % Extract the file names and display them
        fileNames = {matFiles.name};  % Create a cell array of file names
        foundPre = false;
        foundPost= false;
        
        
        
        % RESET THE SUBJ STRUCT FOR EACH INTERVENTION AND TIMEPOINT
        subjStruct = struct();
        for k = 1:length(matFiles) % this is pre post
            file = matFiles(k).name;
            if contains(lower(file), 'pre')
                foundPre = true;  % Found pre file
            elseif contains(lower(file), 'post')
                foundPost = true;  % Found post file
            end
            
            

            
            %% Get row from TEPs log to process
            % Identify row of interest - matches clicked name to the name written in
            % the TEPs_log
            %filename_row_num = find(contains(teps_log(:,6),file));
            filename_row_num = find(strcmp(teps_log(:,6), file));
            subj_tepsLog_row = teps_log(filename_row_num, :);

            % Get subject - print all details
            subj = subj_tepsLog_row{1}; 
            paretic_side = subj_tepsLog_row{2};
            timepoint = subj_tepsLog_row{5};
            session_code = subj_tepsLog_row{4};
            pulsestodelete = subj_tepsLog_row{7};

            disp([num2str(subj), ' ', timepoint, ' - ', session_code])
            
            % CHECK IF FILES EXITS AND IF IT DOES SKIP: 
      %  "A_" +SUBJ+ "_" + inter_valid_names(session_code)
            processed_files = dir(fullfile(subj_path,"TEPsProcessed", '*.mat'));
            if sum(contains({processed_files.name}, "A_" +SUBJ  +"_pre_processedTEPs_"))
                disp("*************A_" + SUBJ + "_" + inter_valid_names(session_code) + " already processed");
                
                return 
            end

            %% Processing parameters
            final_muscles_list = ["RRF", "LRF", "RHAM", "LHAM", "RVL", "LVL", "RTA", "LTA", "RMG", "LMG"]; 
            number_of_muscles = size(final_muscles_list,2);

            %% ###############################################
            % Opening file

            load(fullfile(inter_path, file));

            delete_in = getBadPulses(pulsestodelete);


            %% ###############################################
            % Establish channels and processing mat file


            % Find rows that contain RVL, LRV, STIM, and KNEE to delete
            emptyrow_title_in = [ find(ismember(titles,'RKne','rows')) find(ismember(titles,'LKne','rows')) find(ismember(titles,'Stim','rows'))];

            % Final set of titles
            titles(emptyrow_title_in,:) = [];
            % Final rows of data
            datastart(emptyrow_title_in,:) = [];

            % Get the order of channels presented in the mat file 
            for channel_num = 1:number_of_muscles
                channels{channel_num,1} = strtrim(titles(channel_num,:)); % gives order of channels in the data
            end 
            
            %% Correcting the channels namings that were mislabeled:
             if SUBJ == "08" % or 9 or 10
                if INTER == "30_RMT"
                    channels = {'RHAM', 'RRF', 'RMG', 'RVL', 'LHAM', 'LRF', 'LMG', 'LTA', 'LVL', 'RTA'}; 

                end
            end

            if SUBJ == "09" 
                if INTER == "SHAM2"
                    channels = {'RHAM', 'RRF', 'RMG', 'RVL', 'LHAM', 'LRF', 'LMG', 'LTA', 'LVL', 'RTA'}; 

                end
            end

            if SUBJ == "10" 
                if INTER == "SHAM2" || INTER == "30_RMT" || INTER == "50_RMT"
                    channels = {'RHAM', 'RRF', 'RMG', 'RVL', 'LHAM', 'LRF', 'LMG', 'LTA', 'LVL', 'RTA'}; 

                end
            end

                   


            %% Creating the structs of filtered data

            
            % ###############
            EMG_raw_struct = struct_raw_EMG_trials(channels, data, datastart, dataend, delete_in);
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).Raw = EMG_raw_struct;
            
            % CHECK PULSES (RANDOM MUSCLE)
            total_pulses=size(EMG_raw_struct.RHAM,1);
            
            pulses_perIntensity = 5; % 5 trials
            if mod(total_pulses,pulses_perIntensity) ~= 0
                disp(strcat(subj , " ", session_code  , " ",timepoint));
                disp(['... (ERR) != ' num2str(pulses_perIntensity)  ' pulses per intensities detected. Please check pulses #s to remove']);
                % ADD TO ERROR LIST:
                disp(delete_in);
                wrongPulses{end + 1} = strcat(subj , " ", session_code  , " ",timepoint, " tot pulses " , num2str(total_pulses));
            end
            % ###############
            % lOW PASS Filter
            low = 450; % [Inanici, 2018]
            % Don't do highpass filter, it adds low-freq distortion
            % high = 20; % [Inanici, 2018]
            samprate = 2000;
            order = 5;
            [f,e] = butter(order,low/(samprate/2),'low');


            struct_low_filt_EMG_trials = EMG_filt(EMG_raw_struct, f,e); 
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).LowPass = struct_low_filt_EMG_trials;
            
            % ############### BANDPASS
            %A. Bandpass filter design (20-500 Hz)
            low_cutoff = 20;  % Lower cutoff frequency (Hz)
            high_cutoff = 500; % Upper cutoff frequency (Hz)
            [b, a] = butter(4, [low_cutoff, high_cutoff]/(samprate/2), 'bandpass');

            struct_band_filt_EMG_trials = EMG_filt(EMG_raw_struct, b,a); 
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).BandPass = struct_band_filt_EMG_trials;

            % ###############
            %1. Shifting signal to last reference (just the bandpass):
            [struct_EMG_trials_shift_fromBand, struct_EMG_trials_shiftIDX] = align_signals(struct_band_filt_EMG_trials);
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).Aligned_fromBand = struct_EMG_trials_shift_fromBand;
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).AlignedShiftIdx_fromBand = struct_EMG_trials_shiftIDX;
            % if index is negative - have to shift forward 
            % #####
            %2. RECTIFY SIGNAL - Using bandpass to recrified signal

            musc_fieldnames = fieldnames(struct_EMG_trials_shift_fromBand);
            for channel_num = 1:numel(musc_fieldnames)
                 muscle = musc_fieldnames{channel_num};
                 muscles_trials = struct_EMG_trials_shift_fromBand.(muscle); 
                 rect_struct.(muscle) = abs(muscles_trials);
            end
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).Rectified_afterAligBandOnly = rect_struct;
            
            %.4 Stim ONSET
             struct_stimONSET_INDEX_EMG_trials = getStimOnsetMax(struct_band_filt_EMG_trials);
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).StimOnsetPeaks = struct_stimONSET_INDEX_EMG_trials;
            
            % SMOOTH INTERMEDIATE STEP BEFORE ALGIN
            % ###############
            %1. Smoothing signal - Using bandpass to recrified signal
            windowDuration = 3e-3; % Window duration (seconds)
            struct_filtSMOOTH_EMG_trials = Smoothing_wind_Filt(struct_band_filt_EMG_trials, windowDuration, samprate); 
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).Smoothed = struct_filtSMOOTH_EMG_trials;
            
            % ###############
            %2. Shifting signal to last reference:
            [struct_EMG_trials_shift_fromSmooth, struct_EMG_trials_shiftIDX] = align_signals(struct_filtSMOOTH_EMG_trials);
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).Aligned_fromSmooth = struct_EMG_trials_shift_fromSmooth;
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).AlignedShiftIdx_fromSmooth = struct_EMG_trials_shiftIDX;
            
            
            % #####
            %3. RECTIFY SIGNAL - Using bandpass to recrified signal

            musc_fieldnames = fieldnames(struct_EMG_trials_shift_fromSmooth);
            for channel_num = 1:numel(musc_fieldnames)
                 muscle = musc_fieldnames{channel_num};
                 muscles_trials = struct_EMG_trials_shift_fromSmooth.(muscle); 
                 rect_struct.(muscle) = abs(muscles_trials);
            end
            subj_Struct.("SS"+subj).(inter_valid_names(session_code)).(timepoint).Rectified_afterAligSmooth = rect_struct;
            
            
            % #####
            % Want to keep track of the max stim ONSET 
            % Start backwards - identify the stim onset of max pulse:
            
            
           
            
        end
        
        
        % Check which files are missing and update the list
        if ~foundPre
            missingFiles{end + 1} = INTER + "_pre";
        end
        if ~foundPost
            missingFiles{end + 1} = INTER + "_post";
        end
        
        
      
    end
    
    subj_Struct.("SS"+subj).Missing = missingFiles;
    subj_Struct.("SS"+subj).BadPulsesCheck = wrongPulses;
    % Adding method of how the data was clicked:
    subj_Struct.("SS"+subj).ProcessingDetails = "low_cutoff Hz " + low_cutoff + "high_cutoff " + high_cutoff + ". Window duration: "+windowDuration + ". Bandpass then either align and rectify like that, or smooth and then align and rectify";

    
    
    disp("Missing mat files::")
    disp(missingFiles)

    disp("Wrong number of pulses");
    disp(wrongPulses);
    
    SAVEPATH = fullfile(subj_path, "TEPsProcessed", "A_" +SUBJ  +"_pre_processedTEPs_"+datestr(now, 'ddmmmyyyy')+ ".mat");
    save(SAVEPATH, "subj_Struct")   
end
%% 






                        

%% PLOTTING:
% musc_fieldnames = fieldnames(struct_EMG_trials_shift);
%     for channel_num = 1:numel(musc_fieldnames)
%         muscle = musc_fieldnames{channel_num};
%         
%         muscles_trials = EMG_raw_struct.(muscle); 
%         figure;
%         subplot(4,1,1);
%         for pulsenum = 1:size(muscles_trials,1)
%             sig = muscles_trials(pulsenum, :);
%          
%             plot(sig);
%             hold on;
%         end
%         title([muscle '- Raw'])
%         
%         muscles_trials = struct_band_filt_EMG_trials.(muscle); 
%         subplot(4,1,2)
%         for pulsenum = 1:size(muscles_trials,1)
%             sig = muscles_trials(pulsenum, :);
%          
%             plot(sig);
%             hold on;
%         end
%         title('BandPass')
%         
%         
%         muscles_trials = struct_EMG_trials_shift.(muscle); 
%         subplot(4,1,3)
%         for pulsenum = 1:size(muscles_trials,1)
%             sig = muscles_trials(pulsenum, :);
%          
%             plot(sig);
%             hold on;
%         end
%         title('Aligned')
%         
%         
%         muscles_trials = struct_EMG_trials_shift.(muscle); 
%         muscles_trials = abs(muscles_trials);
%         subplot(4,1,4)
%         for pulsenum = 1:size(muscles_trials,1)
%             sig = muscles_trials(pulsenum, :);
%          
%             plot(sig);
%             hold on;
%         end
%         title('Rect')
%         
%     end
% 

%% PLOTTING ALIGNED SIGNALS AND SHIFTED
% sig_idx1 = 34;
% sig_idx2=75;
% muscle = 'RTA';
% first_Sig = subj_Struct.SS05.RMT30.POST.BandPass.(muscle)(sig_idx1,:);
% last_sig = subj_Struct.SS05.RMT30.POST.BandPass.(muscle)(sig_idx2,:);
% 
% 
% % shifts 
% shfit_amount = subj_Struct.SS05.RMT30.POST.AlignedShiftIdx.(muscle)(sig_idx1,1);
% max_corr_idx = subj_Struct.SS05.RMT30.POST.AlignedShiftIdx.(muscle)(sig_idx1,2);
% shifted_Sig = subj_Struct.SS05.RMT30.POST.Aligned.(muscle)(sig_idx1,:);
% 
% figure
% plot(first_Sig )
% hold on
% plot(last_sig)
% hold on
% try
%     xline(shfit_amount + length(first_Sig));
%     
%     % plot the shifted signal
%     hold on;
%     plot(shifted_Sig);
%     legend('signal pre shift', 'reference last signal','max corr', 'shifted sig');
% catch
%     disp('no shift');
% end
% 
% 
% figure()
% plot(first_Sig);hold on; plot(shifted_Sig);
% legend('signal pre shift','shifted sig');
% 
%%
% plot to see differences:
% figure
% p = 2;
% plot(subj_Struct.SS01.RMT30.PRE.BandPass.RVL(p,:))
% hold on
% plot(subj_Struct.SS01.RMT30.PRE.Smoothed.RVL(p,:))
% 
% legend("Bandpass - input", "Smoothed")
% 
% 
% 
% figure
% plot(subj_Struct.SS01.RMT30.PRE.Rectified_afterAligBandOnly.RVL(p,:))
% hold on
% plot(subj_Struct.SS01.RMT30.PRE.Rectified_afterAligSmooth.RVL(p,:))
% 
% legend("Bandpass - input", "Smoothed")

