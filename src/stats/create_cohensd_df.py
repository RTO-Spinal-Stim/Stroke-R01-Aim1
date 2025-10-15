
import pandas as pd
import numpy as np

try:
    import pingouin as pg
    USE_PINGOUIN = True
except ImportError:
    print("Note: pingouin not installed. Install with 'pip install pingouin' for easier effect size calculations.")
    USE_PINGOUIN = False

# tableName = 'CGAM'
tableName = 'unmatchedCycles' # Options are 'matchedCycles', 'unmatchedCycles', 'CGAM'
data_path = f"~/mnt/rto/LabMembers/MTillman/SavedOutcomes/StrokeSpinalStim/Overground_EMG_Kinematics/MergedTablesAffectedUnaffected/{tableName}.csv"
save_path = f"~/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_CSVs/cohensd_{tableName}.csv"
save_path_ttest = f"~/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_ttest_CSVs/cohensd_{tableName}.csv"
# For CGAM only. Comment out for other tables
# data_path = f"~/mnt/rto/LabMembers/MTillman/SavedOutcomes/StrokeSpinalStim/Overground_EMG_Kinematics/MergedTablesAffectedUnaffected/matchedCyclesCGAM.csv"
df = pd.read_csv(data_path)
column_names = df.columns.tolist()
columns_to_drop = [
    'Subject',
    'Intervention',
    'SessionOrder',
    'Is_Stim',
    'Frequency',
    'Intensity',
    'PrePost',
    'Speed',
    'Trial',
    'Cycle',
    'Side'
]
numeric_cols = [col for col in column_names if col not in columns_to_drop]

def cohens_d_manual(group1, group2):
    """
    Fallback function to calculate Cohen's d manually if pingouin not available.
    """
    n1, n2 = len(group1), len(group2)
    var1, var2 = np.var(group1, ddof=1), np.var(group2, ddof=1)
    pooled_std = np.sqrt(((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2))
    d = (np.mean(group1) - np.mean(group2)) / pooled_std
    return d

def cohens_d(group1, group2):
    """
    Calculate Cohen's d using pingouin if available, otherwise use manual calculation.
    """
    if USE_PINGOUIN:
        # pingouin's compute_effsize with 'cohen' method
        return pg.compute_effsize(group1, group2, eftype='cohen')
    else:
        return cohens_d_manual(group1, group2)

def make_df_for_anova(df: pd.DataFrame) -> pd.DataFrame:
    """Make a pd.DataFrame with one Cohen's d value per Subject & Intervention"""
    # Initialize results dictionary
    results = []
    # Group by Subject and Intervention
    for (subject, intervention), group in df.groupby(['Subject', 'Intervention']):
        pre_data = group[group['PrePost'] == 'PRE']
        post_data = group[group['PrePost'] == 'POST']
        
        if len(pre_data) > 0 and len(post_data) > 0:
            # Calculate Cohen's d for each numeric variable
            one_group_dict = {}
            one_group_dict['Subject'] = subject
            one_group_dict['Intervention'] = intervention
            for col in numeric_cols:
                pre_values = pre_data[col].dropna()
                post_values = post_data[col].dropna()
                
                if len(pre_values) > 1 and len(post_values) > 1:
                    try:
                        # Pre is first because lower symmetry is better, so positive Cohen's indicates an improvement
                        d = cohens_d(pre_values, post_values)
                    except:
                        print(f"Could not compute Cohen's d for {subject}, {intervention}, {col}")
                        d = np.nan
                    
                    one_group_dict[col] = d                
            results.append(one_group_dict)

    # Create results dataframe
    results_df = pd.DataFrame(results)
    return results_df

# Save results to CSV
results_df_for_anova = make_df_for_anova(df)
results_df_for_anova.to_csv(save_path, index=False)

def make_df_for_ttest(df: pd.DataFrame) -> pd.DataFrame:
    """Make a pd.DataFrame with two Cohen's d values per subject: one for average STIM, one for SHAM"""
    # Initialize results dictionary
    results = []
    # Group by subject
    sham_means = df[df['Intervention'] == 'SHAM2'].groupby('Subject').mean(numeric_only=True).reset_index()
    sham_means['Intervention'] = 'SHAM'
    stim_means = df[df['Intervention'] != 'SHAM2'].groupby('Subject').mean(numeric_only=True).reset_index()
    stim_means['Intervention'] = 'STIM'    

    result_df = pd.concat([sham_means, stim_means])

    cols = result_df.columns.tolist()
    cols.remove('Intervention')
    subject_idx = cols.index('Subject')
    cols.insert(subject_idx + 1, 'Intervention')
    result_df = result_df[cols]

    return result_df
    

results_df_for_ttest = make_df_for_ttest(results_df_for_anova)
results_df_for_ttest.to_csv(save_path_ttest, index=False)