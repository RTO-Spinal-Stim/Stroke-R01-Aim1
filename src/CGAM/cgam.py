
import numpy as np
import pandas as pd

def compute_cgam(df: pd.DataFrame, groupby_cols: list, feature_cols: list, cgam_column: str = "CGAM") -> pd.DataFrame:    
    """
    Compute CGAM using features selected from VIF.

    Parameters:
    df (pd.DataFrame): DataFrame containing symmetry data.
    feature_cols (list): List of feature column names.
    groupby_cols (list): List of columns to group by (e.g., ['Subject', 'Intervention'])

    Returns:
    df: DataFrame with CGAM values for each stride, grouped by specified columns.
    """
    all_cgam_values = []

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

        # Compute CGAM for each stride
        denominator = np.sum(K_S_inv)
        numerators = np.diag(S @ K_S_inv @ S.T)
        cgam_values = np.sqrt(numerators / denominator)

        # Put the CGAM values into a pd.DataFrame with the groupby_cols
        group_result = group_df[groupby_cols].copy()
        group_result[cgam_column] = cgam_values
        all_cgam_values.append(group_result)

    all_cgam_values = pd.concat(all_cgam_values, ignore_index=False)
    return all_cgam_values