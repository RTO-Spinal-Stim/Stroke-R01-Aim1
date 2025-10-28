import pandas as pd
import numpy as np
from statsmodels.stats.outliers_influence import variance_inflation_factor
import pingouin as pg

# ----------------------------------------------------------------------
# Helper functions for CGAM Pipeline: VIF, CGAM, Cohen's
def compute_vif(df, feature_cols, vif_threshold=10):
    """
    Compute VIF and remove features with high collinearity.

    Parameters:
    df (pd.DataFrame): DataFrame containing feature columns.
    feature_cols (list): List of feature column names.
    vif_threshold (float): Threshold for removing features with high VIF.

    Returns:
    list: List of selected features after VIF filtering.
    """
    selected_features = feature_cols.copy()
    
    while len(selected_features) > 1:
        X = df[selected_features].to_numpy()
        vif_values = [variance_inflation_factor(X, i) for i in range(X.shape[1])]
        
        # Create a DataFrame for VIF values
        vif_df = pd.DataFrame({"Feature": selected_features, "VIF": vif_values})
        max_vif = vif_df["VIF"].max()
        
        # Stop if all VIF values are below the threshold
        if max_vif < vif_threshold:
            break
        
        # Drop the feature with the highest VIF
        drop_feature = vif_df.loc[vif_df["VIF"].idxmax(), "Feature"]
        selected_features.remove(drop_feature)
        print(f"Dropping '{drop_feature}' with VIF={max_vif:.2f}")
    
    return selected_features

def calculate_cgam_grouped(df, groupby_cols, feature_cols):
    
    """
    Compute CGAM using features selected from VIF.

    Parameters:
    df (pd.DataFrame): DataFrame containing symmetry data.
    feature_cols (list): List of feature column names.
    groupby_cols (list): List of columns to group by (e.g., ['Subject', 'Intervention'])

    Returns:
    df: DataFrame with CGAM values for each stride, grouped by specified columns.
    """
    results = []
    grouped = df.groupby(groupby_cols)

    for group_name, group_df in grouped:
        if len(group_df) < 3:
            print(f"Skipped group: {group_name} (only {len(group_df)} strides)")
            continue

        # Symmetry matrix S: (strides x features)
        S = group_df[feature_cols].to_numpy()

        # Covariance matrix across all strides (features x features)
        K_S = np.cov(S, rowvar=False, bias=False)
        
        cond_number = np.linalg.cond(K_S)
        if cond_number > 1e10:
            print("Warning: Matrix is ill-conditioned")

        # Inverse covariance matrix
        K_S_inv = np.linalg.inv(K_S)

        denominator = np.sum(K_S_inv)

        # Compute CGAM for each stride
        for i, stride_S in enumerate(S):
            numerator = stride_S @ K_S_inv @ stride_S.T
            val = numerator / denominator
            if val < 0 or np.isnan(val):
                print(f"Warning: Invalid value inside sqrt in group {group_name}. Skipping stride {i}.")
                continue
            cgam_value = np.sqrt(val)

            # Collect metadata columns for this stride
            cycle_val = group_df['Cycle'].iloc[i]
            trial_val = group_df['Trial'].iloc[i]
            prepost_val = group_df['PrePost'].iloc[i]


            # Append all data
            results.append((*group_name, trial_val, prepost_val, cycle_val, cgam_value))

    # Create DataFrame with results
    result_df = pd.DataFrame(results, columns=groupby_cols + ['Trial', 'PrePost', 'Cycle', 'CGAM'])
    return result_df

def cohens_d(pre_df, post_df, features, trial=False):
    """
    Computes Cohen's d (paired or unpaired) for each feature Pre vs Post per Subject + Intervention.

    Parameters:
    pre_df (pd.DataFrame): PRE dataframe with Subject, Intervention, Is_Stim, Trial, and features.
    post_df (pd.DataFrame): POST dataframe with the same columns.
    features (list): List of feature column names.
    trial (bool): If True, matches trials for paired analysis; if False, performs unpaired analysis.

    Returns:
    pd.DataFrame: Rows are Subject, Intervention, Is_Stim, etc., with one column per feature's Cohen's d.
    
    GROUP 1: Pre
    GROUP 2: Post
    """
    group_keys = ['Subject', 'Intervention', 'SessionOrder', 'Is_Stim', 'Frequency', 'Intensity']
    results = []

    # Group both dataframes
    pre_groups = pre_df.groupby(group_keys)
    post_groups = post_df.groupby(group_keys)

    for key in pre_groups.groups.keys():
        if key not in post_groups.groups:
            continue

        pre_group = pre_groups.get_group(key)
        post_group = post_groups.get_group(key)

        row = dict(zip(group_keys, key))

        if trial:
            # Merge on 'Trial' to ensure paired comparison only for matching trials
            merged = pd.merge(pre_group, post_group, on='Trial', suffixes=('_pre', '_post'))

            for feature in features:
                pre_vals = merged[f"{feature}_pre"]
                post_vals = merged[f"{feature}_post"]
                row[feature] = pg.compute_effsize(pre_vals, post_vals, paired=False, eftype='cohen')

        else:
            # Unpaired comparison (no merge)
            for feature in features:
                pre_vals = pre_group[feature].dropna()
                post_vals = post_group[feature].dropna()
                row[feature] = pg.compute_effsize(pre_vals, post_vals, paired=False, eftype='cohen')

        results.append(row)

    return pd.DataFrame(results)


# ----------------------------------------------------------------------
# CGAM Pipeline Class
class CGAMPipeline:
    def __init__(self, data_path):
        self.data_path = data_path
        self.df = None
        self.filtered_df = None
        self.feature_cols = []
        self.vif_features = []
        self.cgam_matrix = None

    def load_and_filter_data(self, speed='FV', include_sham1=False):
        self.df = pd.read_csv(self.data_path)
        
        # Filter by speed
        self.filtered_df = self.df[(self.df['Speed'] == speed)]
        
        # Keep or drop SHAM1 based on parameter
        if not include_sham1:
            self.filtered_df = self.filtered_df[self.filtered_df['Intervention'] != 'SHAM1']
            
        # Relabel Intensity for specific subjects who's TOL < RMT. Interventions do not change, just the Intensity Col.
        # relabel_dict = {'SS06': 'TOL50', 'SS10': 'TOL50', 'SS01': 'TOL30'}
        # for subject, intervention in relabel_dict.items():
        #     mask = (self.filtered_df['Subject'] == subject) & (self.filtered_df['Intervention'] == intervention)
        #     self.filtered_df.loc[mask, 'Intensity'] = 'RMT'

        # Filter out features not going to be used in CGAM (Before VIF)
        drop_cols = [
            'StanceDurations_GR_Sym', 'StrideWidths_GR_Sym',
            'Single_Support_Time_GR_Sym', 'Double_Support_Time_GR_Sym',
            'TenMWT'
        ]
        self.filtered_df.drop(columns=drop_cols, inplace=True, errors='ignore')
        self.filtered_df.dropna(inplace=True)
        
        # Robustness check - confirm that there are no significant missing values in the dataset
        missing_counts = self.filtered_df.isnull().sum()
        filtered_missing = missing_counts[missing_counts > 0]
        if not filtered_missing.empty:
            print("Missing data detected:")
            print(filtered_missing)
        else:
            print("No missing data found.")

        print(f"Data loaded and filtered: Speed={speed}, Include SHAM1={include_sham1}")

    # Filter out EMG and Kinematic features not going to be used in CGAM (Before VIF)
    def extract_feature_cols(self, feature_type: str = 'all'):
        # Base filter
        feature_cols = [
            col for col in self.filtered_df.columns
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

        # Apply conditional filters
        if feature_type == 'gait':
            feature_cols = [c for c in feature_cols if 'JointAngles' not in c and 'EMG' not in c]
            print(f"Gait features selected: {feature_cols}")
        elif feature_type == 'joint':
            feature_cols = [c for c in feature_cols if 'EMG' not in c and 'GR' not in c]
            print(f"Joint features selected: {feature_cols}")
        elif feature_type == 'emg':
            feature_cols = [c for c in feature_cols if 'JointAngles' not in c and 'GR' not in c]
            print(f"EMG features selected: {feature_cols}")
        elif feature_type == 'all':
            pass  # keep as is
        else:
            raise ValueError(f"Invalid feature_type '{feature_type}'. Must be one of: 'all', 'gait', 'joint', 'emg'.")

        # Safety check: if empty, raise descriptive error
        if not feature_cols:
            if feature_type == 'gait':
                raise ValueError("No features found in GaitRite.")
            elif feature_type == 'joint':
                raise ValueError("No features found in JointAngles.")
            elif feature_type == 'emg':
                raise ValueError("No features found in EMG.")
            else:
                raise ValueError("No features found after filtering.")

        # Save to class
        self.feature_cols = feature_cols


    # Extract features no dropped by VIF
    def compute_vif_features(self):
        df_demeaned = self.filtered_df.copy()
        df_demeaned[self.feature_cols] = df_demeaned[self.feature_cols].apply(lambda x: x - x.mean())
        print("Starting VIF computation...")
        self.vif_features = compute_vif(df_demeaned, self.feature_cols, vif_threshold=5)

    # Compute CGAM using features selected from VIF
    def compute_cgam(self, groupby_cols):
        # Keep group keys columns along with VIF features
        group_keys = groupby_cols + ['Trial', 'PrePost', 'Cycle']
        self.filtered_df_vif = self.filtered_df[group_keys + self.vif_features].copy()
        print("Calculating CGAM...")
        self.cgam_matrix = calculate_cgam_grouped(self.filtered_df, groupby_cols, self.vif_features)
        print("CGAM calculation complete.")
        return self.cgam_matrix, self.filtered_df_vif
    # Compute Cohen's d for Pre-Post CGAM values
    def get_cohens_d(self):
        print("Calculating Cohen's d for Pre vs Post...")
        pre_df = self.cgam_matrix[self.cgam_matrix["PrePost"] == 'PRE']
        post_df = self.cgam_matrix[self.cgam_matrix["PrePost"] == 'POST']
        print("Cohen's d calculation complete.")
        return cohens_d(pre_df, post_df, ['CGAM'])
    
    

# ----------------------------------------------------------------------
# Main callable function to run the CGAM pipeline
def run_CGAM_pipeline(data_path, speed='FV', include_sham1=False, feature_type='all'):
    """
    Function to call CGAM Pipeline.

    Parameters:
    data_path (path): Matched cycles symmetry data with 10MWT
    speed (string): 'SSV' or 'FV' for speed of interest.
    include_sham1 (bool): If True, includes SHAM1 intervention in the analysis.

    Returns:
    pd.DataFrame for CGAM values, and Cohen's d for Pre vs Post.
    """
    groupby_cols = ['Subject', 'Intervention', 'SessionOrder', 'Is_Stim', 'Frequency', 'Intensity', 'Speed']

    pipeline = CGAMPipeline(data_path)
    pipeline.load_and_filter_data(speed=speed, include_sham1=include_sham1)
    pipeline.extract_feature_cols(feature_type = feature_type)
    pipeline.compute_vif_features()
    cgam_df, filtered_df = pipeline.compute_cgam(groupby_cols)
    cohens_df = pipeline.get_cohens_d()

    return cgam_df, cohens_df, filtered_df
