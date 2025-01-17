# 1. Initialization
1. Define subject folder to load from and the .mat file path to save to
2. Load the configuration from config.json file

# 2. EMG: Process One Intervention
1. Load the EMG data
2. Preprocess it:
    - Split into muscles
    - Filter each muscle's data


# 3. GaitRite: Process One Intervention
1. Load the data
2. Split each spreadsheet into its individual trials
2. For each trial, preprocess by calculating spatiotemporal metrics:
    - Step length symmetry `processed_data.stepLengthSymmetries`
    - Swing time symmetry `processed_data.swingTimeSymmetries`
    - Gait events (seconds) `processed_data.gaitEvents.seconds`
    - Gait events (frames) `processed_data.gaitEvents.frames`
    - Gait phases start & stop (seconds) `processed_data.gaitPhases.seconds`
    - Gait phases start & stop (frames) `processed_data.gaitPhases.frames`
    - Gait phases durations (seconds) `processed_data.gaitPhasesDurations.seconds`
    - Gait phases durations (frames) `processed_data.gaitPhasesDurations.frames`

# 4. XSENS: Process One Intervention
1. Load and extract the data
2. Filter the data

## 5. Downsample EMG & XSENS data (to 101 frames?)
1. 


# Intermediate Processing
1. Put loaded data into “organizedData” struct
2. Rename struct fields for GaitRite, EMG, and XSENS to remove naming redundancies
3. Downsample EMG and XSENS to 101 frames

# Data Analysis
1. Calculate muscle synergies
2. Statistical Parametric Mapping (SPM)
3. Difference in RL calculation (amplitude and duration)
    - EMG
    - XSENS

# Store Outcome Measures Per Intervention, Pre & Post

