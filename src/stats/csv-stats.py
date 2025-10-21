"""Run statistics on the Cohen's d CSV files"""
# %%
from pathlib import Path

from csvstats.anova import anova1way
from csvstats.ttest import ttest_dep, ttest_ind
import pandas as pd

# %%
## Configuration
repeated_measures_column = 'Subject'
group_column_name = 'Intervention'
speeds = ['SSV', 'FV']

for speed in speeds:
    ##################################################################
    #################### tSCS Parameters ANOVA #######################
    ##################################################################

    # %% CGAM Cohen's d ANOVA
    data_path = f"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_CSVs/cohensd_CGAM_{speed}.csv"
    df = pd.read_csv(data_path)
    save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_with_sham2/symmetry/{{data_column}}_{speed}_anova1way.pdf".format(speed=speed))
    root_save_folder_no_sham2 = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_without_sham2/symmetry/{{data_column}}_{speed}_anova1way.pdf".format(speed=speed))
    df_nosham2 = df[df['Intervention'] != 'SHAM2']
    # df = df.drop(['SessionOrder', 'Frequency'], axis=1)
    results_sham2 = anova1way(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)    
    results_nosham2 = anova1way(df_nosham2, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=root_save_folder_no_sham2)

    # %% Matched Cycles Cohen's d ANOVA
    data_path = f"~/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_CSVs/cohensd_matchedCycles_{speed}.csv"
    df = pd.read_csv(data_path)
    save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_with_sham2/symmetry/{{data_column}}_{speed}_anova1way.pdf".format(speed=speed))
    save_path_no_sham2 = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_without_sham2/symmetry/{{data_column}}_{speed}_anova1way.pdf".format(speed=speed))
    # Drop rows with "SHAM1" in the Intervention column
    df = df[df['Intervention'] != 'SHAM1']
    df_nosham2 = df[df['Intervention'] != 'SHAM2']
    results = anova1way(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)
    results_nosham2 = anova1way(df_nosham2, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path_no_sham2)

    # %% Unmatched Cycles Cohen's d ANOVA
    data_path = f"~/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_CSVs/cohensd_unmatchedCycles_{speed}.csv"
    df = pd.read_csv(data_path)
    save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_with_sham2/raw_values/{{data_column}}_{speed}_anova1way.pdf".format(speed=speed))
    save_path_no_sham2 = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ANOVA results/between_interventions_cohensd_without_sham2/raw_values/{{data_column}}_{speed}_anova1way.pdf".format(speed=speed))
    # Drop rows with "SHAM1" in the Intervention column
    df = df[df['Intervention'] != 'SHAM1']
    df_nosham2 = df[df['Intervention'] != 'SHAM2']
    results = anova1way(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)    
    results_nosham2 = anova1way(df_nosham2, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path_no_sham2)

    ##################################################################
    #################### Single day effect t-tests ###################
    ##################################################################
    # %% Matched cycles
    data_path = f"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_ttest_CSVs/cohensd_matchedCycles_{speed}.csv"
    df = pd.read_csv(data_path)
    save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/sham_vs_stim/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed))
    results = ttest_dep(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)
    df_sham = df[df['Intervention'] == 'SHAM']
    save_path_sham = "/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/sham_vs_zero/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
    results = ttest_ind(df_sham, group_column_name, "_", filename=save_path_sham)
    df_stim = df[df['Intervention'] == 'STIM']
    save_path_stim = "/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/stim_vs_zero/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
    results = ttest_ind(df_stim, group_column_name, "_", filename=save_path_stim)

    # %% Unmatched cycles
    data_path = f"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_ttest_CSVs/cohensd_unmatchedCycles_{speed}.csv"
    df = pd.read_csv(data_path)
    save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/sham_vs_stim/raw_values/{{data_column}}_{speed}_ttest.pdf".format(speed=speed))
    results = ttest_dep(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)
    df_sham = df[df['Intervention'] == 'SHAM']
    save_path_sham = "/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/sham_vs_zero/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
    results = ttest_ind(df_sham, group_column_name, "_", filename=save_path_sham)
    df_stim = df[df['Intervention'] == 'STIM']
    save_path_stim = "/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/stim_vs_zero/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
    results = ttest_ind(df_stim, group_column_name, "_", filename=save_path_stim)

    # %% CGAM
    data_path = f"/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/Cohensd_ttest_CSVs/cohensd_CGAM_{speed}.csv"
    df = pd.read_csv(data_path)
    save_path = Path("/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/sham_vs_stim/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed))
    results = ttest_dep(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)
    df_sham = df[df['Intervention'] == 'SHAM']
    save_path_sham = "/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/sham_vs_zero/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
    results = ttest_ind(df_sham, group_column_name, "_", filename=save_path_sham)
    df_stim = df[df['Intervention'] == 'STIM']
    save_path_stim = "/home/mtillman/mnt/rto/LabMembers/MTillman/GitRepos/Stroke-R01/results/stats/ttest_results/stim_vs_zero/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
    results = ttest_ind(df_stim, group_column_name, "_", filename=save_path_stim)

    ##################################################################
    #################### Session Order ANOVA #########################
    ##################################################################

    # group_column_name = "SessionOrder"
    # data_path = r""
    # df = pd.read_csv(data_path)
    # save_path = anova1way(df, group_column_name, )