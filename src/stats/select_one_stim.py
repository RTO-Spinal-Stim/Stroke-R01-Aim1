import pandas as pd

def select_best_stim(df: pd.DataFrame, column: str) -> pd.DataFrame:
    """Return a data frame with one entry (one intervention) per subject with the intervention with the highest value in the specified column"""

    subject_col = "Subject"
    
    # Find the index of the row with the maximum value in the specified column for each subject
    idx = df.groupby(subject_col)[column].idxmax()
    
    # Return the rows corresponding to those indices
    return df.loc[idx]


def select_worst_stim(df: pd.DataFrame, column: str) -> pd.DataFrame:
    """Return a data frame with one entry (one intervention) per subject with the intervention with the lowest value in the specified column"""

    subject_col = "Subject"

    # Find the index of the row with the minimum value in the specified column for each subject
    idx = df.groupby(subject_col)[column].idxmin()

    return df.loc[idx]