
import pandas as pd
import numpy as np

try:
    import pingouin as pg
    USE_PINGOUIN = True
except ImportError:
    print("Note: pingouin not installed. Install with 'pip install pingouin' for easier effect size calculations.")
    USE_PINGOUIN = False

tableName = 'unmatchedCycles'
data_path = f"Y:\\LabMembers\\MTillman\\SavedOutcomes\\StrokeSpinalStim\\Overground_EMG_Kinematics\\MergedTablesAffectedUnaffected\\{tableName}.csv"
save_path = f"Y:\\LabMembers\\MTillman\\GitRepos\\Stroke-R01\\results\\stats\\Cohensd_CSVs\\cohensd_{tableName}.csv"
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
                    d = cohens_d(post_values, pre_values)
                except:
                    print(f"Could not compute Cohen's d for {subject}, {intervention}, {col}")
                    d = np.nan
                
                one_group_dict[col] = d                
        results.append(one_group_dict)

# Create results dataframe
results_df = pd.DataFrame(results)
# Save results to CSV
results_df.to_csv(save_path, index=False)