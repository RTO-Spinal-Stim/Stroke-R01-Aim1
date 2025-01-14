# Initialization
1. Define subject folder to load from and .mat file path to save to
2. Load the configuration from config.json file
3. Load all of the data and place into struct
4. Organize EMG data into separate muscles
5. Extract .num field of GaitRite and XSENS data
6. Fix muscle mappings of EMG sensors

# Preprocess EMG
Filter EMG for each muscle in each trial:
1. Subtract mean
2. Bandpass filter (4Hz, 100Hz)
3. Rectify (abs value)
4. Lowpass filter (5Hz)

# Process GaitRite
1. Split each spreadsheet into its individual trials
2. For each trial, calculate spatiotemporal metrics
    - Step length symmetry (average)
    - Swing time symmetry (average)
    - Swing and stance time
3. Convert time indices to 2000Hz frequency for EMG

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

