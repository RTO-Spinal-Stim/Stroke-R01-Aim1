from pathlib import Path
import pandas as pd

from ..CGAM.vif import compute_vif_features
from ..CGAM.cgam import compute_cgam

speeds = ["SSV", "FV"]
SYMMETRY_FEATURES_TO_DROP = [
    'StanceDurations_GR_Sym', 'StrideWidths_GR_Sym',
    'Single_Support_Time_GR_Sym', 'Double_Support_Time_GR_Sym',
    'TenMWT', "NumSynergies_Sym", "RMSE_EMG_Sym", "Lag_EMG_Sym", "Mag_EMG_Sym",
    "AUC_EMG_Sym", "RMS_EMG_Sym", "AUC_JointAngles_Sym", "JointAngles_Max_Sym", "JointAngles_Min_Sym"
]

FEATURE_SETS = [
    "GR", "EMG", "JointAngles"
]

GROUPBY_COLS = [
    "Subject", "Intervention"
]

# Load symmetry data for CGAM
sym_file_path = Path("")
all_df = pd.read_csv(sym_file_path)
all_df_sym_dropped = all_df.drop(SYMMETRY_FEATURES_TO_DROP)

for feature_set in FEATURE_SETS:
    # Select the features to compute CGAM with
    if feature_set == "all":
        feature_cols = all_df_sym_dropped.columns
    else:
        feature_cols = [col for col in all_df_sym_dropped.columns if feature_set in col]

    cgam_column_name = "CGAM_" + feature_set

    for speed in speeds:
        speed_df = all_df_sym_dropped[all_df_sym_dropped["Speed"] == speed]
        vif_features = compute_vif_features(speed_df, feature_cols, vif_threshold=5)
        columns_to_drop_after_vif = [col for col in speed_df.columns if col not in vif_features]
        cgam_features_df = speed_df.drop(columns_to_drop_after_vif)

        cgam = compute_cgam(cgam_features_df, GROUPBY_COLS)
        # Put CGAM values into the proper rows in the designated column
        speed_idx = all_df["Speed"] == speed
        all_df.loc[speed_idx, cgam_column_name] = cgam

# Write the CGAM data
save_path = Path("")
save_path.parent.mkdir(parents=True, exist_ok=True)
all_df.to_csv(save_path)
