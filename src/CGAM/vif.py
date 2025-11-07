
import pandas as pd
from statsmodels.stats.outliers_influence import variance_inflation_factor


def compute_vif_features(df: pd.DataFrame, feature_cols: list, vif_threshold=10):
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

    # De-mean before VIF calculation
    df_copy = df.copy()
    for col in df_copy.columns:
        try:
            df_copy[col] = df_copy[col] - df_copy[col].mean()
        except:
            pass
    
    while len(selected_features) > 1:
        X = df_copy[selected_features].to_numpy()
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