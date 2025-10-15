# %%
from pathlib import Path

from csvstats.anova import anova1way
from csvstats.ttest import ttest_dep
import pandas as pd

# %%
## Configuration
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
repeated_measures_column = 'Subject'
group_column_name = 'Intervention'

##################################################################
#################### tSCS Parameters ANOVA #######################
##################################################################

# %%
# CGAM Cohen's d ANOVA
data_path = r"~/mnt/rto/LabMembers/MTillman/SavedOutcomes/StrokeSpinalStim/Overground_EMG_Kinematics/MergedTablesAffectedUnaffected/matchedCyclesCGAMCohens.csv"
df = pd.read_csv(data_path)
column_names = df.columns.tolist()
results = {}
root_save_folder = Path(r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_with_sham2/symmetry")
root_save_folder_no_sham2 = Path(r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_without_sham2/symmetry")
column_names = [col for col in column_names if col not in columns_to_drop]
df_nosham2 = df[df['Intervention'] != 'SHAM2']
for col in column_names:
    save_file_path = root_save_folder / f"{col}_anova1way.pdf"
    results[col] = anova1way(df, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path)
    save_file_path_no_sham2 = root_save_folder_no_sham2 / f"{col}_anova1way.pdf"
    anova1way(df_nosham2, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path_no_sham2)

# %%
## Matched Cycles Cohen's d ANOVA
data_path = r"~/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_CSVs/cohensd_matchedCycles.csv"
df = pd.read_csv(data_path)
column_names = df.columns.tolist()
results = {}
root_save_folder = Path(r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_with_sham2/symmetry")
root_save_folder_no_sham2 = Path(r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_without_sham2/symmetry")
column_names = [col for col in column_names if col not in columns_to_drop]
# Drop rows with "SHAM1" in the Intervention column
df = df[df['Intervention'] != 'SHAM1']
df_nosham2 = df[df['Intervention'] != 'SHAM2']
# Drop rows with NaN values in any of the columns to be analyzed
df = df.dropna(subset=column_names)
for col in column_names:
    save_file_path = root_save_folder / f"{col}_anova1way.pdf"
    results[col] = anova1way(df, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path)
    save_file_path_no_sham2 = root_save_folder_no_sham2 / f"{col}_anova1way.pdf"
    anova1way(df_nosham2, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path_no_sham2)

# %%
## Unmatched Cycles Cohen's d ANOVA
data_path = r"~/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_CSVs/cohensd_unmatchedCycles.csv"
df = pd.read_csv(data_path)
column_names = df.columns.tolist()
results = {}
root_save_folder = Path(r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_with_sham2/raw_values")
root_save_folder_no_sham2 = Path(r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_without_sham2/raw_values")
column_names = [col for col in column_names if col not in columns_to_drop]
# Drop rows with "SHAM1" in the Intervention column
df = df[df['Intervention'] != 'SHAM1']
df_nosham2 = df[df['Intervention'] != 'SHAM2']
# Drop rows with NaN values in any of the columns to be analyzed
df = df.dropna(subset=column_names)
for col in column_names:
    save_file_path = root_save_folder / f"{col}_anova1way.pdf"
    results[col] = anova1way(df, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path)
    save_file_path_no_sham2 = root_save_folder_no_sham2 / f"{col}_anova1way.pdf"
    anova1way(df_nosham2, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path_no_sham2)

##################################################################
#################### Single day effect t-tests ###################
##################################################################
# %% Matched cycles
data_path = r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_ttest_CSVs/cohensd_matchedCycles.csv"
df = pd.read_csv(data_path)
column_names = df.columns.tolist()
results = {}
root_save_folder = Path(r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/symmetry")
column_names = [col for col in column_names if col not in columns_to_drop]
for col in column_names:
    save_file_path = root_save_folder / f"{col}_ttest.pdf"
    results[col] = ttest_dep(df, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path)

# %% Unmatched cycles
data_path = r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_ttest_CSVs/cohensd_unmatchedCycles.csv"
df = pd.read_csv(data_path)
column_names = df.columns.tolist()
results = {}
root_save_folder = Path(r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/raw_values")
column_names = [col for col in column_names if col not in columns_to_drop]
for col in column_names:
    save_file_path = root_save_folder / f"{col}_ttest.pdf"
    results[col] = ttest_dep(df, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path)

# %% CGAM
data_path = r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_ttest_CSVs/cohensd_CGAM.csv"
df = pd.read_csv(data_path)
column_names = df.columns.tolist()
results = {}
root_save_folder = Path(r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/symmetry")
column_names = [col for col in column_names if col not in columns_to_drop]
for col in column_names:
    save_file_path = root_save_folder / f"{col}_ttest.pdf"
    results[col] = ttest_dep(df, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path)
