# %%
from pathlib import Path

from csvstats.anova import anova1way
from csvstats.ttest import ttest_dep
import pandas as pd

# %%
## Configuration
repeated_measures_column = 'Subject'
group_column_name = 'Intervention'

##################################################################
#################### tSCS Parameters ANOVA #######################
##################################################################

# %% CGAM Cohen's d ANOVA
data_path = r"~/mnt/rto/LabMembers/MTillman/SavedOutcomes/StrokeSpinalStim/Overground_EMG_Kinematics/MergedTablesAffectedUnaffected/matchedCyclesCGAMCohens.csv"
df = pd.read_csv(data_path)
save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_with_sham2/symmetry/{data_column}_anova1way.pdf")
root_save_folder_no_sham2 = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_without_sham2/symmetry/{data_column}_anova1way.pdf")
df_nosham2 = df[df['Intervention'] != 'SHAM2']
df = df.drop(['SessionOrder', 'Frequency'], axis=1)
results_sham2 = anova1way(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)    
results_nosham2 = anova1way(df_nosham2, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=root_save_folder_no_sham2)

# %% Matched Cycles Cohen's d ANOVA
data_path = r"~/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_CSVs/cohensd_matchedCycles.csv"
df = pd.read_csv(data_path)
save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_with_sham2/symmetry/{data_column}_anova1way.pdf")
save_path_no_sham2 = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_without_sham2/symmetry/{data_column}_anova1way.pdf")
# Drop rows with "SHAM1" in the Intervention column
df = df[df['Intervention'] != 'SHAM1']
df_nosham2 = df[df['Intervention'] != 'SHAM2']
results = anova1way(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)
results_nosham2 = anova1way(df_nosham2, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path_no_sham2)

# %% Unmatched Cycles Cohen's d ANOVA
data_path = r"~/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_CSVs/cohensd_unmatchedCycles.csv"
df = pd.read_csv(data_path)
save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_with_sham2/raw_values/{data_column}_anova1way.pdf")
save_path_no_sham2 = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_without_sham2/raw_values/{data_column}_anova1way.pdf")
# Drop rows with "SHAM1" in the Intervention column
df = df[df['Intervention'] != 'SHAM1']
df_nosham2 = df[df['Intervention'] != 'SHAM2']
results = anova1way(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)    
results_nosham2 = anova1way(df_nosham2, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path_no_sham2)

##################################################################
#################### Single day effect t-tests ###################
##################################################################
# %% Matched cycles
data_path = r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_ttest_CSVs/cohensd_matchedCycles.csv"
df = pd.read_csv(data_path)
save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/symmetry/{data_column}_ttest.pdf")
results = ttest_dep(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)

# %% Unmatched cycles
data_path = r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_ttest_CSVs/cohensd_unmatchedCycles.csv"
df = pd.read_csv(data_path)
save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/raw_values/{data_column}_ttest.pdf")
results = ttest_dep(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)

# %% CGAM
data_path = r"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_ttest_CSVs/cohensd_CGAM.csv"
df = pd.read_csv(data_path)
save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/symmetry/{data_column}_ttest.pdf")
results = ttest_dep(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)