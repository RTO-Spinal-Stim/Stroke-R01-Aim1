# 1. Initialization
1. Define subject folder to load from and the .mat file path to save to
2. Load the configuration from config.json file

# 2. EMG: Process One Intervention
1. Load the EMG data
2. Preprocess it:
    - Split into muscles
    - Filter each muscle's data
3. Output struct format:
    - {intervention}
        - {pre/post}_{fv/ssv}{num}
            - muscles

# 3. GaitRite: Preprocess One Intervention
1. Load the data
2. Split each spreadsheet into its individual trials
3. For each trial, preprocess by calculating spatiotemporal metrics:
    - Step length symmetry `processed_data.stepLengthSymmetries`
    - Swing time symmetry `processed_data.swingTimeSymmetries`
    - Gait events (seconds) `processed_data.seconds.gaitEvents`
    - Gait events (frames) `processed_data.frames.gaitEvents`
    - Gait phases start & stop (seconds) `processed_data.seconds.gaitPhases`
    - Gait phases start & stop (frames) `processed_data.frames.gaitPhases`
    - Gait phases durations (seconds) `processed_data.seconds.gaitPhasesDurations`
    - Gait phases durations (frames) `processed_data.frames.gaitPhasesDurations`
4. Output struct format:
    - {intervention}
        - {pre/post}_{fv/ssv}{num}
            - stepLengthSymmetries
            - swingTimeSymmetries
            - AvgStepLenSym
            - AvgSwingTimeSym
            - seconds
                - gaitEvents
                - gaitPhases
                - gaitPhasesDurations
            - frames
                - gaitEvents
                - gaitPhases
                - gaitPhasesDurations


# 4. XSENS: Process One Intervention
1. Load and extract the data
2. Filter the data
3. Output struct format:
    - {intervention}
        - {pre/post}_{fv/ssv}{num}
            - joints

# 5. Time Synchronize
1. Get the indices of gait events, phases, and durations in Delsys and XSENS indices

# 6. Split the data by gait cycle
1. Split up the data for each gait cycle based on heel strikes. Left heel strikes mark gait cycle for left sensors, right heel strikes for right sensors?


# 7. Time-normalize each gait cycle of XSENS & Delsys data to 101 points
1. Resample the data using `resample()`.

# 8. Aggregate the timeseries data.
1. 

