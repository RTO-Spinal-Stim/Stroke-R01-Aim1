# %%
from pathlib import Path

from csv_stats.anova import anova1way
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

# %%
# CGAM Cohen's d ANOVA
data_path = r"Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected\matchedCyclesCGAMCohens.csv"
df = pd.read_csv(data_path)
column_names = df.columns.tolist()
results = {}
root_save_folder = Path(r"Y:\LabMembers\MTillman\GitRepos\Stroke-R01\results\stats\ANOVA results\between_interventions_cohensd_with_sham2")
column_names = [col for col in column_names if col not in columns_to_drop]
for col in column_names:
    save_file_path = root_save_folder / f"{col}_anova1way.pdf"
    results[col] = anova1way(df, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path)

# %%
## Matched Cycles Cohen's d ANOVA
data_path = r"Y:\LabMembers\MTillman\GitRepos\Stroke-R01\results\stats\Cohensd_CSVs\cohensd_matchedCycles.csv"
df = pd.read_csv(data_path)
column_names = df.columns.tolist()
results = {}
root_save_folder = Path(r"Y:\LabMembers\MTillman\GitRepos\Stroke-R01\results\stats\ANOVA results\between_interventions_cohensd_with_sham2")
column_names = [col for col in column_names if col not in columns_to_drop]
# Drop rows with "SHAM1" in the Intervention column
df = df[df['Intervention'] != 'SHAM1']
# Drop rows with NaN values in any of the columns to be analyzed
df = df.dropna(subset=column_names)
for col in column_names:
    save_file_path = root_save_folder / f"{col}_anova1way.pdf"
    results[col] = anova1way(df, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path)

# %%
## Unmatched Cycles Cohen's d ANOVA
data_path = r"Y:\LabMembers\MTillman\GitRepos\Stroke-R01\results\stats\Cohensd_CSVs\cohensd_unmatchedCycles.csv"
df = pd.read_csv(data_path)
column_names = df.columns.tolist()
results = {}
root_save_folder = Path(r"Y:\LabMembers\MTillman\GitRepos\Stroke-R01\results\stats\ANOVA results\between_interventions_cohensd_with_sham2")
column_names = [col for col in column_names if col not in columns_to_drop]
# Drop rows with "SHAM1" in the Intervention column
df = df[df['Intervention'] != 'SHAM1']
# Drop rows with NaN values in any of the columns to be analyzed
df = df.dropna(subset=column_names)
for col in column_names:
    save_file_path = root_save_folder / f"{col}_anova1way.pdf"
    results[col] = anova1way(df, group_column_name, col, repeated_measures_column=repeated_measures_column, filename=save_file_path)
# %%
