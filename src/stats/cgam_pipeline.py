import sys

from pathlib import Path
import pandas as pd
import numpy as np

sys.path.append('src')

from CGAM.vif import compute_vif_features
from CGAM.cgam import compute_cgam

speeds = ["SSV", "FV"]
SYMMETRY_FEATURES_TO_DROP_BEFORE_VIF = [
    'StanceDurations_GR_Sym', 'StrideWidths_GR_Sym',
    'Single_Support_Time_GR_Sym', 'Double_Support_Time_GR_Sym',
    'TenMWT'
]

FEATURE_SETS = [
    "all", "GR", "EMG", "JointAngles"
    # "all"
]

GROUPBY_COLS = [
    "Subject", "Intervention"
]

CATEGORICAL_COLS = [
    "Subject", "Intervention", "SessionOrder", "Is_Stim", "Frequency", "Intensity", "PrePost", "Speed", "Trial", "Cycle", "Side"
]

# Load symmetry data for CGAM
# sym_file_path = '/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/from_matlab/Overground_EMG_Kinematics/MergedTablesAffectedUnaffected/matchedCycles.csv'
sym_file_path = Path("results/from_matlab/Overground_EMG_Kinematics/MergedTablesAffectedUnaffected/matchedCycles.csv")
all_df = pd.read_csv(sym_file_path)
all_df = all_df[all_df["Intervention"] != "SHAM1"].copy()
sym_features_to_drop_before_vif = [col for col in SYMMETRY_FEATURES_TO_DROP_BEFORE_VIF if col in all_df.columns]
all_df_sym_dropped = all_df.drop(sym_features_to_drop_before_vif, axis=1)

# Base condition with all columns
all_feature_cols = [
    col for col in all_df_sym_dropped.columns
    if (
        isinstance(col, str) and 'Sym' in col and
        col != 'NumSynergies_Sym' and
        all(x not in col for x in [
            'RMSE_EMG', 'Lag_EMG', 'Mag_EMG',
            'AUC_EMG', 'RMS_EMG',
            'AUC_JointAngles', 'JointAngles_Max', 'JointAngles_Min'
        ])
    )
]

for feature_set in FEATURE_SETS:
    # Select the features to compute CGAM with    
    if feature_set == "all":        
        feature_cols = all_feature_cols
    else:
        feature_cols = [col for col in all_feature_cols if feature_set in col]

    cgam_column_name = "CGAM_" + feature_set
    all_df[cgam_column_name] = np.nan

    for speed in speeds:
        speed_df = all_df_sym_dropped[all_df_sym_dropped["Speed"] == speed].copy()
        vif_features = compute_vif_features(speed_df, feature_cols, vif_threshold=5)
        columns_to_drop_after_vif = [col for col in speed_df.columns if col not in vif_features + CATEGORICAL_COLS]
        cgam_features_df = speed_df.drop(columns_to_drop_after_vif, axis=1)
        cgam_features = [col for col in cgam_features_df.columns if col not in CATEGORICAL_COLS]

        cgam = compute_cgam(cgam_features_df, GROUPBY_COLS, cgam_features, cgam_column_name)

        all_df.loc[cgam.index, cgam_column_name] = cgam[cgam_column_name]

# Write the CGAM data
# save_path = '/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/from_matlab/Overground_EMG_Kinematics/MergedTablesAffectedUnaffected/matchedCycles_withCGAM.csv'
save_path = Path("results/from_matlab/Overground_EMG_Kinematics/MergedTablesAffectedUnaffected/matchedCycles_withCGAM.csv")
save_path.parent.mkdir(parents=True, exist_ok=True)
all_df.to_csv(save_path)
