
import numpy as np
import pingouin as pg
import pandas as pd

def compute_cgam(df: pd.DataFrame, groupby_cols: list, feature_cols: list):    
    """
    Compute CGAM using features selected from VIF.

    Parameters:
    df (pd.DataFrame): DataFrame containing symmetry data.
    feature_cols (list): List of feature column names.
    groupby_cols (list): List of columns to group by (e.g., ['Subject', 'Intervention'])

    Returns:
    df: DataFrame with CGAM values for each stride, grouped by specified columns.
    """
    grouped = df.groupby(groupby_cols)

    all_cgam_values = []

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
        numerators = np.diag(S @ K_S_inv @ S.T)
        cgam_values = numerators / denominator
        all_cgam_values.append(cgam_values)
        # for i, stride_S in enumerate(S):
        #     numerator = stride_S @ K_S_inv @ stride_S.T
        #     val = numerator / denominator
        #     if val < 0 or np.isnan(val):
        #         print(f"Warning: Invalid value inside sqrt in group {group_name}. Skipping stride {i}.")
        #         continue
        #     cgam_value = np.sqrt(val)

        #     # Collect metadata columns for this stride
        #     cycle_val = group_df['Cycle'].iloc[i]
        #     trial_val = group_df['Trial'].iloc[i]
        #     prepost_val = group_df['PrePost'].iloc[i]


            # Append all data
            # results.append((*group_name, trial_val, prepost_val, cycle_val, cgam_value))

    return all_cgam_values
    # Create DataFrame with results
    # result_df = pd.DataFrame(results, columns=groupby_cols + ['Trial', 'PrePost', 'Cycle', 'CGAM'])
    # return result_df