"""Run statistics on the Cohen's d CSV files"""
# %%
import sys
from pathlib import Path

from csvstats.anova import anova1way
from csvstats.ttest import ttest_dep, ttest_ind
import pandas as pd

from select_one_stim import select_best_stim, select_worst_stim

# %%
## Configuration
repeated_measures_column = 'Subject'
group_column_name = 'Intervention'
speeds = ['SSV', 'FV']
table_names = [
    "CGAM",
    "matchedCycles",
    "unmatchedCycles"
]

for speed in speeds:
    for table_name in table_names:
        ##################################################################
        #################### tSCS Parameters ANOVA #######################
        ##################################################################

        # %% CGAM Cohen's d ANOVA
        data_path = f"results/stats/Cohensd_CSVs/cohensd_{table_name}_{speed}.csv"
        df = pd.read_csv(data_path)
        save_path = Path("results/stats/ANOVA results/between_interventions_cohensd_with_sham2/symmetry/{{data_column}}_{speed}_anova1way.pdf".format(speed=speed))
        root_save_folder_no_sham2 = Path("results/stats/ANOVA results/between_interventions_cohensd_without_sham2/symmetry/{{data_column}}_{speed}_anova1way.pdf".format(speed=speed))
        df_nosham2 = df[df['Intervention'] != 'SHAM2']
        # df = df.drop(['SessionOrder', 'Frequency'], axis=1)
        results_sham2 = anova1way(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)    
        results_nosham2 = anova1way(df_nosham2, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=root_save_folder_no_sham2)

        #################################################################################
        #################### Single day effect t-tests (average stim) ###################
        #################################################################################
        # %% Matched cycles
        data_path = f"results/stats/Cohensd_ttest_CSVs/cohensd_{table_name}_{speed}.csv"
        df = pd.read_csv(data_path)
        save_path = Path("results/stats/ttest_results/sham_vs_stim/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed))
        results = ttest_dep(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)
        df_sham = df[df['Intervention'] == 'SHAM']
        save_path_sham = "results/stats/ttest_results/sham_vs_zero/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
        results = ttest_ind(df_sham, group_column_name, "_", filename=save_path_sham)
        df_stim = df[df['Intervention'] == 'STIM']
        save_path_stim = "results/stats/ttest_results/stim_vs_zero/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
        results = ttest_ind(df_stim, group_column_name, "_", filename=save_path_stim)

        ##################################################################
        ############ Best & Worst Stim vs. SHAM t-test ###################
        ##################################################################
        # %% Get the best stim
        data_path = f"results/stats/Cohensd_CSVs/cohensd_{table_name}_{speed}.csv"
        all_df = pd.read_csv(data_path)
        sham_df = all_df[all_df["Intervention"] == "SHAM2"]
        best_stim_df = select_best_stim(all_df)
        worst_stim_df = select_worst_stim(all_df)
        # Perform the best/worst SHAM vs. STIM t-test
        best_stim_and_sham_df = pd.concat([sham_df, best_stim_df])
        best_stim_save_path = "results/stats/ttest_results/best_stim_vs_sham/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
        results = ttest_dep(best_stim_and_sham_df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)
        worst_stim_and_sham_df = pd.concat([sham_df, worst_stim_df])
        worst_stim_save_path = "results/stats/ttest_results/worst_stim_vs_sham/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
        results = ttest_dep(worst_stim_and_sham_df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)
        save_path_best_stim = "results/stats/ttest_results/best_stim_vs_zero/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
        # Perform one sample best and worst STIM t-test
        results = ttest_ind(best_stim_df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)
        save_path_worst_stim = "results/stats/ttest_results/worst_stim_vs_zero/symmetry/{{data_column}}_{speed}_ttest.pdf".format(speed=speed)
        results = ttest_ind(worst_stim_df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)

        ##################################################################
        #################### Session Order ANOVA #########################
        ##################################################################

        # group_column_name = "SessionOrder"
        # data_path = r""
        # df = pd.read_csv(data_path)
        # save_path = anova1way(df, group_column_name, )