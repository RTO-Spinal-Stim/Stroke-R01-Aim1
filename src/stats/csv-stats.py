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
    "matchedCycles",
    "unmatchedCycles"
]

# Testing
all_col_names_to_keep = [
    "StepLengths_GR_Sym",
    "SwingDurations_GR_Sym",
    "CGAM_all",
    "CGAM_GR",
    "CGAM_EMG",
    "CGAM_JointAngles"
]

for speed in speeds:
    for table_name in table_names:
        ##################################################################
        #################### tSCS Parameters ANOVA #######################
        ##################################################################

        # %% Cohen's d ANOVA
        data_path = f"results/stats/Cohensd_CSVs/cohensd_{table_name}_{speed}.csv"
        df = pd.read_csv(data_path)
        # col_names_to_keep = [col for col in all_col_names_to_keep if col in df.columns]
        # df = df[[repeated_measures_column, group_column_name] + col_names_to_keep]
        save_path = Path("results/stats/ANOVA results/between_interventions_cohensd_with_sham2/{table_name}/{{data_column}}_{speed}_anova1way.pdf".format(speed=speed, table_name=table_name))        
        root_save_folder_no_sham2 = Path("results/stats/ANOVA results/between_interventions_cohensd_without_sham2/{table_name}/{{data_column}}_{speed}_anova1way.pdf".format(speed=speed, table_name=table_name))
        save_path.parent.mkdir(parents=True, exist_ok=True)
        root_save_folder_no_sham2.parent.mkdir(parents=True, exist_ok=True)
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
        # col_names_to_keep = [col for col in all_col_names_to_keep if col in df.columns]
        # df = df[[repeated_measures_column, group_column_name] + col_names_to_keep]
        save_path = Path("results/stats/ttest_results/avg_stim_vs_sham/{table_name}/{{data_column}}_{speed}_ttest.pdf".format(speed=speed, table_name=table_name))
        save_path.parent.mkdir(parents=True, exist_ok=True)
        results = ttest_dep(df, group_column_name, "_", repeated_measures_column=repeated_measures_column, filename=save_path)
        df_sham = df[df['Intervention'] == 'SHAM']
        save_path_sham = Path("results/stats/ttest_results/sham_vs_zero/{table_name}/{{data_column}}_{speed}_ttest.pdf".format(speed=speed, table_name=table_name))
        save_path_sham.parent.mkdir(parents=True, exist_ok=True)
        results = ttest_ind(df_sham, group_column_name, "_", filename=save_path_sham)
        df_stim = df[df['Intervention'] == 'STIM']
        save_path_stim = Path("results/stats/ttest_results/avg_stim_vs_zero/{table_name}/{{data_column}}_{speed}_ttest.pdf".format(speed=speed, table_name=table_name))
        save_path_stim.parent.mkdir(parents=True, exist_ok=True)
        results = ttest_ind(df_stim, group_column_name, "_", filename=save_path_stim)

        ##################################################################
        ############ Best & Worst Stim vs. SHAM t-test ###################
        ##################################################################
        # %% Get the best stim
        data_path = f"results/stats/Cohensd_CSVs/cohensd_{table_name}_{speed}.csv"
        all_df = pd.read_csv(data_path)
        # col_names_to_keep = [col for col in all_col_names_to_keep if col in all_df.columns]
        # all_df = all_df[[repeated_measures_column, group_column_name] + col_names_to_keep]
        sham_df = all_df[all_df["Intervention"] == "SHAM2"].copy()
        sham_df["Intervention"] = "SHAM"
        all_df_columns = all_df.columns.drop([group_column_name, repeated_measures_column])
        # all_df_columns = ["StepLengths_GR_Sym"]
        for column in all_df_columns:
            # Check for NaN in the column
            if all_df[column].isnull().any():
                print(f"Skipping column {column} due to NaN values.", file=sys.stderr)
                continue
            best_stim_df = select_best_stim(all_df, column).copy()
            best_stim_df["Intervention"] = "BEST_STIM"
            worst_stim_df = select_worst_stim(all_df, column).copy()
            worst_stim_df["Intervention"] = "WORST_STIM"
            # Perform the best/worst SHAM vs. STIM t-test
            best_stim_and_sham_df = pd.concat([sham_df, best_stim_df])
            best_stim_vs_sham_save_path = Path("results/stats/ttest_results/best_stim_vs_sham/{table_name}/{column}_{speed}_ttest.pdf".format(speed=speed, column=column, table_name=table_name))
            best_stim_vs_sham_save_path.parent.mkdir(parents=True, exist_ok=True)
            results_best_stim_vs_sham = ttest_dep(best_stim_and_sham_df, group_column_name, column, repeated_measures_column=repeated_measures_column, filename=best_stim_vs_sham_save_path)
            worst_stim_and_sham_df = pd.concat([sham_df, worst_stim_df])
            worst_stim_vs_sham_save_path = Path("results/stats/ttest_results/worst_stim_vs_sham/{table_name}/{column}_{speed}_ttest.pdf".format(speed=speed, column=column, table_name=table_name))
            worst_stim_vs_sham_save_path.parent.mkdir(parents=True, exist_ok=True)
            results_worst_stim_vs_sham = ttest_dep(worst_stim_and_sham_df, group_column_name, column, repeated_measures_column=repeated_measures_column, filename=worst_stim_vs_sham_save_path)            
            # Perform one sample best and worst STIM t-test
            save_path_best_stim = Path("results/stats/ttest_results/best_stim_vs_zero/{table_name}/{column}_{speed}_ttest.pdf".format(speed=speed, column=column, table_name=table_name))
            save_path_best_stim.parent.mkdir(parents=True, exist_ok=True)
            results_best_stim_vs_zero = ttest_ind(best_stim_df, group_column_name, column, filename=save_path_best_stim)
            save_path_worst_stim = Path("results/stats/ttest_results/worst_stim_vs_zero/{table_name}/{column}_{speed}_ttest.pdf".format(speed=speed, column=column, table_name=table_name))
            save_path_worst_stim.parent.mkdir(parents=True, exist_ok=True)
            results_worst_stim_vs_zero = ttest_ind(worst_stim_df, group_column_name, column, filename=save_path_worst_stim)

        ##################################################################
        #################### Session Order ANOVA #########################
        ##################################################################

        # group_column_name = "SessionOrder"
        # data_path = r""
        # df = pd.read_csv(data_path)
        # save_path = anova1way(df, group_column_name, )